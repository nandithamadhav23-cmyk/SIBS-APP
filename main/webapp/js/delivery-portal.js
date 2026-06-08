/* ═══════════════════════════════════════════════════════════════════
   DELIVERY PORTAL — COMPLETE SCRIPT
   ═══════════════════════════════════════════════════════════════════

   JS FIXES IN THIS FILE
   ─────────────────────
   FIX-JS-1  toggleOnline() — was ignoring the JSON response body.
             Now chains .then(r => r.json()) so server rejections
             (e.g. "balance too low") show the real message and the
             pill reverts correctly.

   FIX-JS-2  searchHistory() line 155 — mixed TAB+SPACE indent on
             the `const cust` line caused a silent IndentationError
             in some strict JS parsers / linters. Normalised to spaces.

   FIX-JS-3  _statusPoll() — new 30-second poller.
             When OrderServlet._setAgentOffline() flips the DB to
             "inactive", the agent's in-memory session still says
             "active" until they reload. The poller calls the new
             DeliveryPortalServlet?action=getStatus lightweight
             endpoint and silently corrects the pill + isOnline flag
             if the server says "inactive" while the pill is still
             green. Stops polling once the page is hidden.
   ═══════════════════════════════════════════════════════════════════ */

/* ── CONSTANTS ────────────────────────────────────────────────────── */

const WALLET_SERVLET = CTX + '/AgentWalletServlet';
const PAGE_NAMES = ['dashboard','orders','history','earnings','wallet','notifications','profile'];

/* ── PAGE NAVIGATION ─────────────────────────────────────────────── */

function showPage(name) {
  PAGE_NAMES.forEach(p => {
    const el = document.getElementById('page-' + p);
    if (el) el.classList.remove('active');
  });
  document.querySelectorAll('.nav-item').forEach(n  => n.classList.remove('active'));
  document.querySelectorAll('.bnav-item').forEach(n => n.classList.remove('active'));

  const pg = document.getElementById('page-' + name);
  if (pg) pg.classList.add('active');

  const titles = {
    dashboard:     'Dashboard',
    orders:        'Active Orders',
    history:       'Order History',
    earnings:      'Earnings',
    wallet:        'My Wallet',
    notifications: 'Notifications',
    profile:       'My Profile'
  };
  document.getElementById('topbarTitle').textContent = titles[name] || name;

  const navMap   = { dashboard:0, orders:1, history:2, earnings:3, wallet:4, notifications:5, profile:6 };
  const navItems = document.querySelectorAll('.nav-item');
  if (navItems[navMap[name]]) navItems[navMap[name]].classList.add('active');

  const bEl = document.getElementById('bnav-' + name);
  if (bEl) bEl.classList.add('active');

  closeSidebar();
  window.scrollTo(0, 0);

  if (name === 'wallet') {
    loadWalletData();
    if (_walletData) {
      _updateWalletBanner(_walletData);
      _topupWalletData = _walletData;
    }
  }
  if (name === 'earnings') _loadEarningsPage();
  if (name === 'profile')  _loadProfileWalletBal();
  if (name === 'notifications') { if (!_notifState.loaded) _notifLoad(); }

  // Always refresh wallet banner so low-balance warning stays visible on page switch
  if (_walletData) _updateWalletBanner(_walletData);
}

/* ── SIDEBAR ─────────────────────────────────────────────────────── */

function openSidebar() {
  document.getElementById('sidebar').classList.add('open');
  document.getElementById('overlay').classList.add('open');
}
function closeSidebar() {
  document.getElementById('sidebar').classList.remove('open');
  document.getElementById('overlay').classList.remove('open');
}

/* toggleSidebar — desktop collapses sidebar; mobile opens/closes it */
function toggleSidebar() {
  const isMobile = window.innerWidth <= 768;
  if (isMobile) {
    const isOpen = document.getElementById('sidebar').classList.contains('open');
    isOpen ? closeSidebar() : openSidebar();
  } else {
    document.body.classList.toggle('sidebar-collapsed');
  }
}

/* ── ONLINE TOGGLE ───────────────────────────────────────────────── */

// FIX-TOGGLE: Read initial state from the DOM reliably after DOMContentLoaded,
// not at script-parse time when the element may not exist yet.
let isOnline = false;

/* ── Shift state — single source of truth for all shift-related UI ── */
let _shiftState = {
  hasSlot:               false,
  slotId:                -1,
  slotType:              '',
  status:                'NONE',   // NONE | BOOKED | ACTIVE | ON_BREAK | INACTIVE | COMPLETED
  slotStartTime:         '',
  slotEndTime:           '',
  slotStartEpochMs:      0,
  slotEndEpochMs:        0,
  shiftStartedAtEpochMs: 0,
  shiftClockStart:       0,        // set when agent first clicks Start Shift
  totalBreakMin:         0,
  breakStartEpoch:       0
};

let _shiftPollTimer   = null;   // setInterval — polls shift status every 60 s
let _shiftClockTimer  = null;   // setInterval — ticks working-hours display every 1 s
let _autoOfflineTimer = null;   // setTimeout  — fires at slot end time
document.addEventListener('DOMContentLoaded', () => {
  const dot = document.getElementById('statusDot');
  if (dot) isOnline = !dot.classList.contains('off');
});
function isShiftWindowCurrentlyActive(state) {
    if (!state.slotStartEpochMs || !state.slotEndEpochMs) return false;
    const now = Date.now();
    return now >= state.slotStartEpochMs && now < state.slotEndEpochMs;
}
function canStartShiftNow(state) {
    if (!state.slotStartEpochMs || !state.slotEndEpochMs) return false;
    const now         = Date.now();
    const EARLY_MS    = 15 * 60 * 1000;
    const earlyOpenMs = state.slotStartEpochMs - EARLY_MS;
    return now >= earlyOpenMs && now < state.slotEndEpochMs;
}
function toggleOnline() {
	const wantOnline = !isOnline;

	  // ✅ FIX: block going Offline via pill while shift is running
	  // Offline during an active shift must go through End Shift or break overflow
	  if (!wantOnline) {
	    const st = _shiftState.status;
	    if (st === 'ACTIVE' || st === 'ON_BREAK') {
	      _showSlotAlert(
	        '🚴 Shift In Progress',
	        'You have an active shift running. Use "End Shift" to go offline,\nor "Take a Break" for a short break.',
	        null, null
	      );
	      return;  // ← block the toggle, don't call _doStatusUpdate
	    }
	    _doStatusUpdate(false);
	    return;
	  }
  /* ── Guard: going Online ─────────────────────────────────────────── */
  const st  = _shiftState.status;
  const now = Date.now();
 
  if (!_shiftState.hasSlot || st === 'NONE') {
    _showSlotAlert(
      '📅 No Shift Booked',
      'You don\'t have a delivery slot for today.\nPlease book a slot to go online.',
      'Book a Slot',
      () => { window.location.href = CTX + '/DeliverySlotServlet'; }
    );
    return;
  }
 
  if (st === 'COMPLETED') {
    _showSlotAlert(
      '✅ Shift Completed',
      'Your shift for today is already completed.\nBook a slot for tomorrow to work again.',
      'Book Tomorrow\'s Slot',
      () => { window.location.href = CTX + '/DeliverySlotServlet'; }
    );
    return;
  }
 
  if (st === 'INACTIVE') {
    _showSlotAlert(
      '⛔ Account Offline',
      'You were set offline by the system (break exceeded or admin action).\nContact your supervisor to reactivate.',
      null, null
    );
    return;
  }
 
  
 
  /* After slot window ends */
  if (!canStartShiftNow(_shiftState)) {
      // If the window isn't open yet, check if it's because the shift hasn't started
      if (_shiftState.slotStartEpochMs > 0 && now < _shiftState.slotStartEpochMs) {
        const startsAt = _shiftState.slotStartTime || new Date(_shiftState.slotStartEpochMs)
          .toLocaleTimeString('en-IN', { hour: 'numeric', minute: '2-digit', hour12: true });
        _showSlotAlert(
          '⏰ Shift Hasn\'t Started',
          `Your shift starts at ${startsAt}.\nYou can go online 15 minutes before that.`,
          null, null
        );
      } else {
        // Otherwise, the slot duration has fully elapsed (Expired / Ended)
        _showSlotAlert(
          '🔚 Shift Has Ended',
          `Your shift ended at ${_shiftState.slotEndTime || '—'}.\nBook a slot to work again.`,
          'Book a Slot',
          () => { window.location.href = CTX + '/DeliverySlotServlet'; }
        );
      }
      return;
    }
 
  /* All guards passed — proceed */
  _doStatusUpdate(true);
}



/* ── FIX-JS-3: Status poller ─────────────────────────────────────────
   Polls DeliveryPortalServlet?action=getStatus every 30 s.
   If the server says "inactive" while the pill shows Online,
   the pill is quietly corrected without a full reload.
   This catches the case where OrderServlet._setAgentOffline()
   set the DB to "inactive" (low COD balance) while the agent's
   session / UI still shows "active".
   NOTE: Full implementation is in SECTION 6 below.
────────────────────────────────────────────────────────────────────── */
document.addEventListener('DOMContentLoaded', _startStatusPoll);
document.addEventListener('visibilitychange', () => {
  if (!document.hidden) _pollStatus(); // immediate check on tab-focus
});

/* ── FIX: Load wallet data on every page load so the low-balance banner
   is always shown immediately on refresh, not just when visiting Wallet tab ── */
document.addEventListener('DOMContentLoaded', () => {
  // Only on the portal page (not CodDeposit page which has its own call)
  if (document.getElementById('walletBanner') && typeof loadWalletData === 'function') {
    loadWalletData();
  }
});

/* ── FILTER ORDERS ───────────────────────────────────────────────── */

function filterOrders(type, btn) {
  if (btn) {
    document.querySelectorAll('#page-orders .filter-bar .fbtn')
            .forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
  }
  document.querySelectorAll('#orderContainer .order-card').forEach(card => {
    const st  = (card.dataset.status  || '').toLowerCase();
    const pay = (card.dataset.payment || '').toLowerCase();
    let show = false;

    if      (type === 'all')     show = true;
    else if (type === 'pending') show = st === 'pending' || st === 'processing' || st === 'confirmed' || st === 'ready';
    else if (type === 'transit') show = st === 'out for delivery' || st === 'picked up';
    else if (type === 'return')  show = st.includes('return') && st !== 'return requested';
    else if (type === 'cod')     show = pay === 'cod';

    card.style.display = show ? '' : 'none';
  });
}

function searchOrders(val) {
  const q = val.toLowerCase().trim();
  document.querySelectorAll('#orderContainer .order-card').forEach(card => {
    const cust = (card.dataset.customer || '').toLowerCase();
    const id   = (card.dataset.orderid  || '').toLowerCase();
    card.style.display = (!q || cust.includes(q) || id.includes(q)) ? '' : 'none';
  });
}

/* ── FILTER HISTORY ──────────────────────────────────────────────── */

function filterHistory(type, btn) {
  document.querySelectorAll('#page-history .filter-bar .fbtn')
          .forEach(b => b.classList.remove('active'));
  btn.classList.add('active');
  document.querySelectorAll('.hist-row').forEach(row => {
    const st = (row.dataset.hstatus || '').toLowerCase();
    let show = false;
    if      (type === 'all')       show = true;
    else if (type === 'delivered') show = st === 'delivered';
    else if (type === 'cancelled') show = st === 'cancelled';
    else if (type === 'return')    show = st === 'return picked' || st === 'replaced';
    else if (type === 'refunded')  show = st === 'refunded';
    row.style.display = show ? '' : 'none';
  });
}

// FIX-JS-2: normalised indent (was mixed TAB+SPACE on `const cust` line)
function searchHistory(val) {
  const q = val.toLowerCase().trim();
  document.querySelectorAll('.hist-row').forEach(row => {
    const cust = (row.dataset.hcustomer || '').toLowerCase();
    const id   = (row.querySelector('.card-order-id')?.textContent || '').toLowerCase();
    row.style.display = (!q || cust.includes(q) || id.includes(q)) ? '' : 'none';
  });
}

/* ════════════════════════════════════════════════════════════════════
   CONFIRM MODAL
   ════════════════════════════════════════════════════════════════════ */

let _pendingOrderId = null;
let _cancelMode     = null; // null | 'cantDeliver' | 'rejectTask' | 'returnCancel'

function _getCard(orderId) {
  return document.querySelector(`.order-card[data-orderId="${orderId}"]`);
}

function _getCustomerName(orderId) {
  const card = _getCard(orderId);
  return card ? (card.dataset.customer || '') : '';
}

function _resetReasonWrap() {
  const wrap = document.getElementById('cm-cancel-reason-wrap');
  if (wrap) wrap.style.display = 'none';
  ['cantDeliverReasonSelect', 'rejectTaskReasonSelect', 'returnCancelReasonSelect']
    .forEach(id => {
      const el = document.getElementById(id);
      if (el) { el.style.display = 'none'; el.value = ''; }
    });
  const note = document.getElementById('cancelNoteInput');
  if (note) note.value = '';
}

function _showReasonSelectFor(mode) {
  _resetReasonWrap();
  const map = {
    cantDeliver:  'cantDeliverReasonSelect',
    rejectTask:   'rejectTaskReasonSelect',
    returnCancel: 'returnCancelReasonSelect'
  };
  const sel = document.getElementById(map[mode]);
  if (sel) sel.style.display = 'block';
  const wrap = document.getElementById('cm-cancel-reason-wrap');
  if (wrap) wrap.style.display = 'block';
}

function _setModalHead(title, iconClass, iconColor) {
  const titleEl = document.getElementById('cm-title');
  const iconEl  = document.getElementById('cm-head-icon');
  if (titleEl) titleEl.textContent = title;
  if (iconEl)  { iconEl.className = 'bi ' + iconClass; iconEl.style.color = iconColor; }
}

function _setOrderInfo(orderId, line2, line3) {
	const container = document.getElementById('cm-order-info');
	container.innerHTML = ''; // clear safely

	const strong = document.createElement('strong');
	strong.textContent = 'Order # ' + orderId;
	container.appendChild(strong);

	const custSpan = document.createElement('span');
	custSpan.style.cssText = 'color:var(--text3);font-size:12px;';
	custSpan.textContent = ' — ' + (_getCustomerName(orderId) || '—');
	container.appendChild(custSpan);

	if (line2) {
	  container.appendChild(document.createElement('br'));
	  const s = document.createElement('span');
	  s.style.cssText = 'font-size:13px;color:var(--text2);';
	  s.innerHTML = line2; // FIX: was textContent — HTML tags were rendered as plain text
	  container.appendChild(s);
	}
	if (line3) {
	  container.appendChild(document.createElement('br'));
	  const s = document.createElement('span');
	  s.style.cssText = 'font-size:13px;color:var(--text3);';
	  s.innerHTML = line3; // FIX: was textContent — HTML tags were rendered as plain text
	  container.appendChild(s);
	}
}

function _openModal() {
  document.getElementById('confirmOverlay').classList.add('open');
}

function openStatusConfirm(orderId) {
  _pendingOrderId = orderId;
  _cancelMode     = null;
  _resetReasonWrap();

  const nextStatus = (document.getElementById('statusInput_' + orderId) || {}).value || '';
  const card       = _getCard(orderId);
  const totalEl    = card ? card.querySelector('.total-bar span:last-child') : null;
  const amount     = totalEl ? totalEl.textContent.trim() : '—';

  _setModalHead('Confirm Status Update', 'bi-check2-circle', 'var(--brand)');
  _setOrderInfo(orderId,
    `New Status: <strong style="color:var(--brand);">${nextStatus || '(unknown)'}</strong>`,
    `Order Total: <strong>${amount}</strong>`
  );

  const btn = document.getElementById('cm-confirm-btn');
  btn.className   = 'cm-btn cm-confirm';
  btn.textContent = 'Confirm';
  btn.disabled    = false;
  _openModal();
}

function openCantDeliverConfirm(orderId) {
  _pendingOrderId = orderId;
  _cancelMode     = 'cantDeliver';
  _setModalHead("Can't Deliver", 'bi-x-octagon', 'var(--red)');
  _setOrderInfo(orderId,
    'Order will be returned to hub.',
    'Staff will reassign or contact customer.'
  );
  _showReasonSelectFor('cantDeliver');

  const btn = document.getElementById('cm-confirm-btn');
  btn.className   = 'cm-btn cm-confirm danger';
  btn.textContent = "Report Can't Deliver";
  btn.disabled    = false;
  _openModal();
}

function openRejectTaskConfirm(orderId) {
  _pendingOrderId = orderId;
  _cancelMode     = 'rejectTask';
  _setModalHead('Reject Task', 'bi-slash-circle', 'var(--red)');
  _setOrderInfo(orderId,
    'This order will be unassigned from you.',
    'Staff will reassign to another agent. Your rejection will be logged.'
  );
  _showReasonSelectFor('rejectTask');

  const btn = document.getElementById('cm-confirm-btn');
  btn.className   = 'cm-btn cm-confirm danger';
  btn.textContent = 'Confirm Rejection';
  btn.disabled    = false;
  _openModal();
}

function openCancelPickupConfirm(orderId) {
  _pendingOrderId = orderId;
  _cancelMode     = 'returnCancel';
  _setModalHead('Cancel Return Pickup', 'bi-arrow-return-left', 'var(--rose)');
  _setOrderInfo(orderId,
    'Return pickup will be reset to Approved.',
    'Staff will assign a different agent.'
  );
  _showReasonSelectFor('returnCancel');

  const btn = document.getElementById('cm-confirm-btn');
  btn.className   = 'cm-btn cm-confirm danger';
  btn.textContent = 'Cancel Pickup';
  btn.disabled    = false;
  _openModal();
}

/* ── Safe JSON POST helper ── */

function _safePostJson(url, params) {
  return fetch(url, {
    method:  'POST',
    headers: {
      'Content-Type':     'application/x-www-form-urlencoded',
      'X-Requested-With': 'XMLHttpRequest'
    },
    body: params.toString()
  }).then(r => {
    const ct = r.headers.get('content-type') || '';
    if (!r.ok) {
      if (ct.includes('application/json')) {
        return r.json().then(data => {
          throw new Error(data.message || ('Server error ' + r.status));
        });
      }
      throw new Error('Server error ' + r.status + ' — ' + r.statusText);
    }
    if (!ct.includes('application/json')) {
      throw new Error('Unexpected server response (not JSON)');
    }
    return r.json();
  });
}

function executeConfirmedAction() {
  if (_cancelMode) {
    const selMap = {
      cantDeliver:  'cantDeliverReasonSelect',
      rejectTask:   'rejectTaskReasonSelect',
      returnCancel: 'returnCancelReasonSelect'
    };
    const sel = document.getElementById(selMap[_cancelMode]);
    if (!sel || !sel.value) {
      showToast('Please select a reason before confirming.', 'error');
      return;
    }
    const note   = (document.getElementById('cancelNoteInput').value || '').trim();
    const reason = sel.value + (note ? ': ' + note : '');

    const actionMap = {
      cantDeliver:  'agentCantDeliver',
      rejectTask:   'agentRejectTask',
      returnCancel: 'agentCancelPickup'
    };

    const params = new URLSearchParams();
    params.append('action',       actionMap[_cancelMode]);
    params.append('orderId',      _pendingOrderId);
    params.append('cancelReason', reason);

    const btn = document.getElementById('cm-confirm-btn');
    btn.disabled    = true;
    btn.textContent = 'Submitting…';

    _safePostJson(CTX + '/OrdersDashboard', params)
      .then(data => {
        closeConfirm();
        showToast(data.message || 'Done.', data.success ? 'success' : 'error');
        if (data.success) setTimeout(() => location.reload(), 1800);
      })
      .catch(err => {
        closeConfirm();
        showToast(err.message || 'Network error. Please try again.', 'error');
      });

  } else if (_pendingOrderId !== null) {
    const form = document.getElementById('statusForm_' + _pendingOrderId);
    if (form) {
      closeConfirm();

      // Use AJAX so the server can return {success:false, message} for
      // cases like low COD balance — allows showing the top-up modal
      // instead of a full-page redirect with no feedback.
      const btn = document.getElementById('cm-confirm-btn');
      if (btn) { btn.disabled = true; btn.textContent = 'Updating...'; }

      const params = new URLSearchParams(new FormData(form));
      params.set('source', 'delivery');

      _safePostJson(CTX + '/OrdersDashboard', params)
        .then(data => {
          if (data.success) {
            showToast(data.message || 'Status updated.', 'success');
            setTimeout(() => location.reload(), 1500);
          } else {
            showToast(data.message || 'Could not update status.', 'error');
            // Sync the online pill in case the agent was set offline
            _pollStatus();
            // If it's a wallet/balance issue, pop the top-up modal automatically
			const msg = (data.message || '').toLowerCase();

			if (msg.includes('wallet') || msg.includes('balance')) {
			    setTimeout(() => { if (typeof openTopUpModal === 'function') openTopUpModal(); }, 900);
			}
          }
        })
        .catch(err => showToast(err.message || 'Network error. Please try again.', 'error'))
        .finally(() => { if (btn) { btn.disabled = false; btn.textContent = 'Confirm'; } });

    } else {
      closeConfirm();
      showToast('Form not found - please refresh.', 'error');
    }
  }
}

function closeConfirm() {
  document.getElementById('confirmOverlay').classList.remove('open');
  _pendingOrderId = null;
  _cancelMode     = null;
  _resetReasonWrap();
  const btn = document.getElementById('cm-confirm-btn');
  if (btn) { btn.disabled = false; btn.textContent = 'Confirm'; btn.className = 'cm-btn cm-confirm'; }
}

document.addEventListener('keydown', e => { if (e.key === 'Escape') closeConfirm(); });

document.addEventListener('DOMContentLoaded', () => {
  const overlay = document.getElementById('confirmOverlay');
  if (overlay) {
    overlay.addEventListener('click', e => { if (e.target === overlay) closeConfirm(); });
  }
});

/* ── NOTIFICATIONS ───────────────────────────────────────────────── */

function markAllRead() {
  document.querySelectorAll('.notif-item.unread').forEach(n => n.classList.remove('unread'));
  document.querySelectorAll('.bnav-item .badge-dot').forEach(d => d.remove());
  showToast('All notifications marked as read.', 'success');
}

/* ── OTP INPUTS ──────────────────────────────────────────────────── */

document.querySelectorAll('.otp-digits').forEach(group => {
  const digits = group.querySelectorAll('.otp-digit');
  digits.forEach((input, i) => {
    input.addEventListener('input', () => {
      input.value = input.value.replace(/\D/g, '');
      input.classList.toggle('filled', input.value !== '');
      if (input.value && i < digits.length - 1) digits[i + 1].focus();
    });
    input.addEventListener('keydown', e => {
      if (e.key === 'Backspace' && !input.value && i > 0) digits[i - 1].focus();
    });
    input.addEventListener('paste', e => {
      e.preventDefault();
      const pasted = e.clipboardData.getData('text').replace(/\D/g, '').slice(0, 6);
      [...pasted].forEach((ch, idx) => {
        if (digits[idx]) { digits[idx].value = ch; digits[idx].classList.add('filled'); }
      });
      const next = digits[Math.min(pasted.length, digits.length - 1)];
      if (next) next.focus();
    });
  });
});

// delivery-portal.js
function collectOtp(orderId) {
  const group  = document.getElementById('digits-' + orderId);
  const hidden = document.getElementById('otpHidden-' + orderId);
  if (!group || !hidden) return;
  hidden.value = [...group.querySelectorAll('.otp-digit')].map(i => i.value).join('');
  // Submit the form only after the hidden field is populated
  const form = hidden.closest('form');
  if (form) form.submit();
}

function showOtpBox(orderId) {
  const box = document.getElementById('otpbox-' + orderId);
  if (box) {
    box.classList.add('show');
    setTimeout(() => { const f = box.querySelector('.otp-digit'); if (f) f.focus(); }, 150);
  }
}

/* ── EARNINGS BAR ANIMATION ──────────────────────────────────────── */

document.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('.earn-bar-fill').forEach(bar => {
    const w = bar.style.width;
    bar.style.width = '0';
    setTimeout(() => { bar.style.width = w; }, 400);
  });

  // BUG FIX: After GenerateOtpServlet redirects back, the JSP renders the
  // matching order's OTP card with class="otp-card show". We need to:
  // 1. Make it visible (display:block)
  // 2. Scroll it into view so the agent sees it without hunting
  // 3. Re-attach digit listeners (the top-of-file querySelectorAll ran while
  //    the box was still hidden — inputs may not have been wired correctly)
  // 4. Focus the first digit
  document.querySelectorAll('.otp-card.show').forEach(box => {
    box.style.display = 'block';

    setTimeout(() => box.scrollIntoView({ behavior: 'smooth', block: 'center' }), 100);

    // Re-attach digit input listeners fresh
    const digits = Array.from(box.querySelectorAll('.otp-digit'));
    digits.forEach((input, i) => {
      const fresh = input.cloneNode(true);
      input.parentNode.replaceChild(fresh, input);
      fresh.addEventListener('input', () => {
        fresh.value = fresh.value.replace(/\D/g, '');
        fresh.classList.toggle('filled', fresh.value !== '');
        const allDigits = box.querySelectorAll('.otp-digit');
        if (fresh.value && i < allDigits.length - 1) allDigits[i + 1].focus();
      });
      fresh.addEventListener('keydown', e => {
        const allDigits = box.querySelectorAll('.otp-digit');
        if (e.key === 'Backspace' && !fresh.value && i > 0) allDigits[i - 1].focus();
      });
    });

    const firstDigit = box.querySelector('.otp-digit');
    if (firstDigit) setTimeout(() => firstDigit.focus(), 200);
  });
});

/* ── TOAST ───────────────────────────────────────────────────────── */

function showToast(msg, type) {
  let toast = document.getElementById('_toast');
  const iconMap  = { success:'✅', error:'❌', info:'ℹ️', warning:'⚠️' };
    const colorMap = { success:'#166534', error:'#991b1b', info:'#1e40af', warning:'#92400e' };
  if (!toast) {
    toast = document.createElement('div');
    toast.id = '_toast';
    Object.assign(toast.style, {
      position:    'fixed',
      top:      '24px',
      left:       '50%',
	  transform: 'translateX(-50%)',
      zIndex:      '9999',
      background:  '#fff',
      border:      '1px solid #E0E0E0',
      borderRadius:'10px',
      padding:     '12px 18px',
      fontFamily:  'var(--font)',
      fontSize:    '17px',
      display:     'flex',
      alignItems:  'center',
      gap:         '8px',
      boxShadow:   '0 4px 20px rgba(0,0,0,0.12)',
      transition:  'opacity 0.3s',
      minWidth:    '240px',
      maxWidth:    '340px'
    });
    document.body.appendChild(toast);
  }

  toast.innerHTML = '';
   const iconSpan = document.createElement('span');
   iconSpan.style.fontSize = '16px';
   iconSpan.textContent = iconMap[type] || 'ℹ️';
   const msgSpan = document.createElement('span');
   msgSpan.style.color = colorMap[type] || '#1a1a1a';
   msgSpan.textContent = msg;  // textContent — never executes HTML
   toast.appendChild(iconSpan);
   toast.appendChild(msgSpan);
  toast.style.opacity = '1';
  clearTimeout(toast._timeout);
  toast._timeout = setTimeout(() => { toast.style.opacity = '0'; }, 3800);
}

/* ══════════════════════════════════════════════════════════════════
   WALLET — fetch, render, chart, pagination, withdraw modal
   ══════════════════════════════════════════════════════════════════ */

let _walletData  = null;
let _allTxns     = [];
let _txnPage     = 0;
const TXN_PER_PAGE = 10;

function loadWalletData() {
  _fetchJson(WALLET_SERVLET + '?action=getWallet')
    .then(d => {
      _walletData      = d;
      _topupWalletData = d;
      _renderWalletCards(d);
      _renderEarningsStrip(d);
      _updateWalletBanner(d);
    })
    .catch(err => showToast('Wallet load error: ' + err.message, 'error'));

  _fetchJson(WALLET_SERVLET + '?action=getTransactions')
    .then(list => { _allTxns = list; _txnPage = 0; _renderTxnPage(); })
    .catch(err => showToast('Transaction load error: ' + err.message, 'error'));
}

function refreshWalletData() {
  const btn = document.querySelector('.btn-refresh');
  if (btn) btn.style.transform = 'rotate(360deg)';
  loadWalletData();
  setTimeout(() => { if (btn) btn.style.transform = ''; }, 600);
}

function _fetchJson(url) {
  return fetch(url, { headers: { 'X-Requested-With': 'XMLHttpRequest' } })
    .then(r => {
      if (!r.ok) throw new Error('HTTP ' + r.status);
      return r.json();
    });
}

function _renderWalletCards(d) {
  const fmt   = v => '₹' + Number(v || 0).toFixed(2);
  const avail = Math.max(0, (d.balance || 0) - (d.codFloat || 0) - (d.minBalance || 0));

  _setText('wAvailBalance',   fmt(avail));
  _setText('wBalance',        fmt(d.balance));
  _setText('wCodFloat',       fmt(d.codFloat));
  _setText('wMinBalance',     fmt(d.minBalance));
  _setText('wTotalEarned',    fmt(d.totalEarned));
  _setText('wTotalWithdrawn', fmt(d.totalWithdrawn));

  const pct = Math.min(100, Math.max(0, (avail / Math.max(1, (d.minBalance || 500) * 3)) * 100));
  const bar = document.getElementById('wProgressBar');
  if (bar) {
    bar.style.width      = pct + '%';
    bar.style.background = avail <= 0                    ? 'var(--red)'   :
                           avail < (d.minBalance || 500) ? 'var(--amber)' : 'var(--brand)';
  }

  _setText('wModalAvail', fmt(avail));
  _setText('wModalMin',   '₹' + Number(d.minBalance || 500).toFixed(0));
}

function _renderEarningsStrip(d) {
  const fmt = v => '₹' + Number(v || 0).toFixed(0);
  _setText('eToday', fmt(d.earningsToday));
  _setText('eWeek',  fmt(d.earningsWeek));
  _setText('eMonth', fmt(d.earningsMonth));

  const chart    = document.getElementById('wBarChart');
  const daysWrap = document.getElementById('wChartDays');
  if (!chart || !d.weeklyBreakdown) return;

  const labels = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
  const vals   = d.weeklyBreakdown;
  const maxVal = Math.max(...vals, 1);
  chart.innerHTML    = '';
  daysWrap.innerHTML = '';

  vals.forEach((v, i) => {
    const pct  = Math.max(4, Math.round((v / maxVal) * 90));
    const wrap = document.createElement('div');
    wrap.className = 'wchart-bar-wrap';
    const bar  = document.createElement('div');
    bar.className    = 'wchart-bar' + (i === 6 ? ' active' : '');
    bar.style.height = pct + 'px';
    const tip  = document.createElement('div');
    tip.className   = 'wchart-bar-tip';
    tip.textContent = '₹' + v.toFixed(0);
    bar.appendChild(tip);
    wrap.appendChild(bar);
    chart.appendChild(wrap);
    const lbl = document.createElement('div');
    lbl.className   = 'wchart-day-lbl';
    lbl.textContent = labels[i];
    daysWrap.appendChild(lbl);
  });
}

function _renderTxnPage() {
  const tbody = document.getElementById('wTxnBody');
  const label = document.getElementById('wPageLabel');
  const prev  = document.getElementById('wPrevPage');
  const next  = document.getElementById('wNextPage');
  if (!tbody) return;

  const start = _txnPage * TXN_PER_PAGE;
  const slice = _allTxns.slice(start, start + TXN_PER_PAGE);
  const total = Math.ceil(_allTxns.length / TXN_PER_PAGE) || 1;

  if (label) label.textContent = 'Page ' + (_txnPage + 1) + ' of ' + total;
  if (prev)  prev.disabled = _txnPage === 0;
  if (next)  next.disabled = _txnPage >= total - 1;

  if (!slice.length) {
    tbody.innerHTML = '<tr><td colspan="7" class="wtxn-empty">No transactions yet.</td></tr>';
    return;
  }
  const typeLabel = {
    credit:'Credit', cod_hold:'COD Hold', cod_release:'COD Release',
    cod_collected:'COD Collected', cod_remitted:'COD Remitted',
    withdrawal:'Withdrawal', bonus:'Bonus', delivery_fee:'Delivery Fee', adjustment:'Adjustment'
  };
  const isDebit = t => t === 'cod_hold' || t === 'withdrawal' || t === 'cod_remitted';

  tbody.innerHTML = slice.map((t, idx) => {
    const dt   = new Date(t.createdAt).toLocaleString('en-IN',
                   { day:'2-digit', month:'short', year:'numeric', hour:'2-digit', minute:'2-digit' });
    const sign = isDebit(t.type) ? '−' : '+';
    const cls  = isDebit(t.type) ? 'debit' : 'credit';
    const ord  = t.orderId ? '#' + t.orderId : '—';
	const codFloat     = Number(t.codFloat || 0).toFixed(2);

	return `<tr>
	  <td>${start + idx + 1}</td>
	  <td style="font-size:12px;color:var(--text3);">${_escHtml(dt)}</td>
	  <td>${_escHtml(t.description || '—')}</td>
	  <td>${_escHtml(ord)}</td>
	  <td><span class="txn-badge ${_escHtml(t.type)}">${_escHtml(typeLabel[t.type] || t.type)}</span></td>
	  <td class="txn-amt ${isDebit(t.type) ? 'debit' : 'credit'}">${sign}₹${Number(t.amount).toFixed(2)}</td>
	  <td style="color:var(--text2);">₹${Number(t.balanceAfter).toFixed(2)}</td>
	  <td style="color:var(--text2);">₹${codFloat}</td>

	</tr>`;
  }).join('');
}
function _escHtml(s) {
  return String(s || '').replace(/&/g,'&amp;').replace(/</g,'&lt;')
                         .replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}
document.addEventListener('DOMContentLoaded', () => {
  const prev = document.getElementById('wPrevPage');
  const next = document.getElementById('wNextPage');
  if (prev) prev.addEventListener('click', () => { _txnPage--; _renderTxnPage(); });
  if (next) next.addEventListener('click', () => { _txnPage++; _renderTxnPage(); });
});

/* ── Withdraw modal ── */


/* Show/hide the "withdrawal pending" chip and disable the button when agent
 * already has an active request. Requires AgentWalletServlet to return
 * pendingWithdrawal (amount) in the getWallet JSON response — see DAO note. */
function _updateWithdrawalPendingState(d) {
  const chip   = document.getElementById('wPendingChip');
  const btnOpen= document.getElementById('btnWithdraw');
  const hasPending = d && d.pendingWithdrawal && Number(d.pendingWithdrawal) > 0;

  if (chip) {
    chip.style.display = hasPending ? 'inline-flex' : 'none';
  }
  if (btnOpen) {
    if (hasPending) {
      btnOpen.disabled = true;
      btnOpen.innerHTML = '<i class="fas fa-clock"></i>&nbsp; Request Pending';
      btnOpen.title = 'You have a pending withdrawal of ₹' + Number(d.pendingWithdrawal).toFixed(2);
    } else {
      btnOpen.disabled = false;
      btnOpen.innerHTML = '<i class="fas fa-arrow-up"></i>&nbsp; Request Withdrawal';
      btnOpen.title = '';
    }
  }
}
/* ── Withdraw modal ──
 *
 * Two-step flow:
 *   1. Agent submits a REQUEST → POST OrdersDashboard action=createWithdrawalRequest
 *      Balance is NOT touched. A pending row is inserted for staff review.
 *   2. Staff approves on OrdersDashboard → action=approveWithdrawal
 *      Balance deducted atomically, request marked 'approved'.
 *
 * The old action=requestWithdrawal (AgentWalletServlet) deducted immediately
 * — bypassing staff review. That path is NOT used here.
 */

document.addEventListener('DOMContentLoaded', () => {
  const btnOpen    = document.getElementById('btnWithdraw');
  const modal      = document.getElementById('withdrawModal');
  const btnClose   = document.getElementById('wModalClose');
  const btnCancel  = document.getElementById('wModalCancel');
  const btnConfirm = document.getElementById('wModalConfirm');
  const amtInput   = document.getElementById('wWithdrawAmt');
  const reasonInput= document.getElementById('wWithdrawReason');

  function _closeWithdrawModal() {
    if (modal) modal.style.display = 'none';
    if (amtInput)    amtInput.value    = '';
    if (reasonInput) reasonInput.value = '';
  }

  if (btnOpen) {
    btnOpen.addEventListener('click', () => {
      // Populate available amount from live wallet data
      if (_walletData) {
        const avail = Math.max(0,
          (_walletData.balance || 0) - (_walletData.codFloat || 0) - (_walletData.minBalance || 0));
        const el = document.getElementById('wModalAvail');
        if (el) el.textContent = '₹' + avail.toFixed(2);
        const minEl = document.getElementById('wModalMin');
        if (minEl) minEl.textContent = '₹' + Number(_walletData.minBalance || 500).toFixed(0);
      }
      // Block if a request is already pending
      if (_walletData && _walletData.pendingWithdrawal) {
        showToast(
          'You already have a pending withdrawal request of ₹' +
          Number(_walletData.pendingWithdrawal).toFixed(2) +
          '. Please wait for staff review.',
          'warning'
        );
        return;
      }
      if (modal) modal.style.display = 'flex';
    });
  }

  if (btnClose)  btnClose.addEventListener('click',  _closeWithdrawModal);
  if (btnCancel) btnCancel.addEventListener('click',  _closeWithdrawModal);
  if (modal)     modal.addEventListener('click', e => { if (e.target === modal) _closeWithdrawModal(); });

  if (btnConfirm) {
    btnConfirm.addEventListener('click', () => {
      const amt = parseFloat(amtInput ? amtInput.value : 0);
      if (!amt || amt < 100) { showToast('Enter a valid amount (min ₹100).', 'error'); return; }
      const avail = _walletData
        ? Math.max(0, (_walletData.balance||0) - (_walletData.codFloat||0) - (_walletData.minBalance||0))
        : 0;
      if (amt > avail) {
        showToast('Amount exceeds withdrawable balance (₹' + avail.toFixed(2) + ').', 'error');
        return;
      }
      const reason = reasonInput ? reasonInput.value.trim() : '';
      btnConfirm.disabled    = true;
      btnConfirm.textContent = 'Submitting…';
      const params = new URLSearchParams();
      params.append('action', 'createWithdrawalRequest');
      params.append('amount', amt.toFixed(2));
      if (reason) params.append('reason', reason);
      _safePostJson(CTX + '/OrdersDashboard', params)
        .then(d => {
          _closeWithdrawModal();
          showToast(
            d.message || 'Withdrawal request submitted. Staff will review shortly.',
            d.success ? 'success' : 'error'
          );
          if (d.success) {
            loadWalletData();
            if (btnOpen) { btnOpen.disabled = true; btnOpen.innerHTML = '<i class="fas fa-clock"></i>&nbsp; Request Pending'; }
          }
        })
        .catch(err => showToast(err.message || 'Error submitting request.', 'error'))
        .finally(() => { btnConfirm.disabled = false; btnConfirm.textContent = 'Submit Request'; });
    });
  }
});
/* ── Utility ── */

function _setText(id, val) {
  const el = document.getElementById(id);
  if (el) el.textContent = val;
}

/* ══════════════════════════════════════════════════════════════════
   EARNINGS PAGE
   ══════════════════════════════════════════════════════════════════ */

let _earningsLoaded = false;

function _loadEarningsPage() {
  if (_earningsLoaded) return;

  const monthLabel = document.getElementById('earnMonthLabel');
  if (monthLabel) {
    monthLabel.textContent = new Date().toLocaleString('en-IN', { month: 'long', year: 'numeric' });
  }

  let walletOk = false;
  let txnsOk   = false;

  _fetchJson(WALLET_SERVLET + '?action=getWallet')
    .then(d => {
      _renderEarningsBar(d.weeklyBreakdown || []);
      const profileBal = document.getElementById('profileWalletBal');
      if (profileBal) {
        const avail = Math.max(0, (d.balance || 0) - (d.codFloat || 0) - (d.minBalance || 0));
        profileBal.textContent = '₹' + avail.toFixed(2);
      }
      walletOk = true;
      if (walletOk && txnsOk) _earningsLoaded = true;
    })
    .catch(() => {
      const wrap = document.getElementById('earningsBarWrap');
      if (wrap) wrap.innerHTML = '<div style="text-align:center;padding:20px;color:var(--text3);font-size:13px;">Could not load weekly data.</div>';
    });

  _fetchJson(WALLET_SERVLET + '?action=getTransactions')
    .then(list => {
      _renderEarnTxnTable(list);
      txnsOk = true;
      if (walletOk && txnsOk) _earningsLoaded = true;
    })
    .catch(() => {
      const tbody = document.getElementById('earnTxnBody');
      if (tbody) tbody.innerHTML = '<tr><td colspan="7" class="wtxn-empty">Could not load transactions.</td></tr>';
    });
}

function _renderEarningsBar(vals) {
  const wrap = document.getElementById('earningsBarWrap');
  if (!wrap || !vals.length) return;
  const labels   = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
  const maxVal   = Math.max(...vals, 1);
  const today    = new Date().getDay();
  const todayIdx = today === 0 ? 6 : today - 1;

  wrap.innerHTML = vals.map((v, i) => {
    const pct  = Math.max(2, Math.round((v / maxVal) * 100));
    const isTo = (i === todayIdx);
    return `<div class="earn-bar-row">
      <div class="earn-bar-label" style="${isTo ? 'font-weight:700;color:var(--brand);' : ''}">${labels[i]}</div>
      <div class="earn-bar-track"><div class="earn-bar-fill" style="width:${pct}%;${isTo ? 'background:var(--brand);' : ''}"></div></div>
      <div class="earn-bar-amt">₹${v.toFixed(0)}</div>
    </div>`;
  }).join('');
}

function _renderEarnTxnTable(list) {
  const tbody = document.getElementById('earnTxnBody');
  if (!tbody) return;
  const earningTypes = new Set(['credit','delivery_fee','bonus','cod_collected']);
  const recent = list.filter(t => earningTypes.has(t.type)).slice(0, 10);

  if (!recent.length) {
    tbody.innerHTML = '<tr><td colspan="7" class="wtxn-empty">No earnings transactions yet.</td></tr>';
    return;
  }
  const typeLabel = {
    credit:'Credit', cod_hold:'COD Hold', cod_release:'COD Release',
    cod_collected:'COD Collected', cod_remitted:'COD Remitted',
    withdrawal:'Withdrawal', bonus:'Bonus', delivery_fee:'Delivery Fee', adjustment:'Adjustment'
  };
  tbody.innerHTML = recent.map((t, idx) => {
    const dt  = new Date(t.createdAt).toLocaleString('en-IN',
                  { day:'2-digit', month:'short', year:'numeric', hour:'2-digit', minute:'2-digit' });
    const ord = t.orderId ? '#' + t.orderId : '—';
    return `<tr>
      <td>${idx + 1}</td>
      <td style="font-size:12px;color:var(--text3);">${dt}</td>
      <td>${t.description || '—'}</td>
      <td>${ord}</td>
      <td><span class="txn-badge ${t.type}">${typeLabel[t.type] || t.type}</span></td>
      <td class="txn-amt credit">+₹${Number(t.amount).toFixed(2)}</td>
      <td style="color:var(--text2);">₹${Number(t.balanceAfter).toFixed(2)}</td>
    </tr>`;
  }).join('');
}

/* ── Profile wallet balance ── */

let _profileBalLoaded = false;

function _loadProfileWalletBal() {
  if (_profileBalLoaded) return;
  const el = document.getElementById('profileWalletBal');
  if (!el) return;
  _fetchJson(WALLET_SERVLET + '?action=getWallet')
    .then(d => {
      const avail = Math.max(0, (d.balance || 0) - (d.codFloat || 0) - (d.minBalance || 0));
      el.textContent    = '₹' + avail.toFixed(2);
      _profileBalLoaded = true;
    })
    .catch(() => { el.textContent = '—'; });
}

/* ══════════════════════════════════════════════════════════════════
   WALLET TOP-UP (Razorpay)
   ══════════════════════════════════════════════════════════════════ */

let _topupWalletData  = null;
let _topupSelectedAmt = 0;

function openTopUpModal() {
  _topupSelectedAmt = 0;
  document.getElementById('topupAmtInput').value = '';
  document.getElementById('topupBreakdown').classList.remove('visible');
  document.getElementById('topupPayBtn').disabled = true;
  document.querySelectorAll('.topup-quick-btn').forEach(b => b.classList.remove('selected'));

  showTopUpForm();
  document.getElementById('topupModalOverlay').classList.add('open');

  _fetchJson(WALLET_SERVLET + '?action=getWallet')
    .then(d => {
      _topupWalletData = d;
      const bal    = d.balance    || 0;
      const minBal = d.minBalance || 500;
      const needed = Math.max(0, minBal - bal + 100);

      _setText('tuCurrentBal', '₹' + bal.toFixed(2));
      _setText('tuMinBal',     '₹' + minBal.toFixed(0));
      _setText('tuNeeded',     needed > 0 ? '₹' + needed.toFixed(0) : 'OK');
      _setText('tuMinNote',    minBal.toFixed(0));

      if (needed > 0) {
        const suggested = Math.ceil(needed / 500) * 500;
        selectTopUpAmt(suggested);
      }
    })
    .catch(() => { /* modal already open — strip shows dashes */ });
}

function showTopUpForm() {
  document.getElementById('topupFormView').style.display       = 'block';
  document.getElementById('topupProcessingView').style.display = 'none';
  document.getElementById('topupSuccessView').style.display    = 'none';
  document.getElementById('topupFailedView').style.display     = 'none';
}

function closeTopUpModal() {
  document.getElementById('topupModalOverlay').classList.remove('open');
  document.getElementById('topupAmtInput').value = '';
  document.getElementById('topupBreakdown').classList.remove('visible');
  document.getElementById('topupPayBtn').disabled = true;
  _topupSelectedAmt = 0;
  document.querySelectorAll('.topup-quick-btn').forEach(b => b.classList.remove('selected'));
}

function selectTopUpAmt(amt) {
  _topupSelectedAmt = amt;
  document.getElementById('topupAmtInput').value = amt;
  document.querySelectorAll('.topup-quick-btn').forEach(b => {
    const bAmt = parseInt(b.textContent.replace(/[₹,]/g, ''));
    b.classList.toggle('selected', bAmt === amt);
  });
  _updateTopUpBreakdown(amt);
}

function onTopUpAmtChange(val) {
  const amt = parseFloat(val) || 0;
  _topupSelectedAmt = amt;
  document.querySelectorAll('.topup-quick-btn').forEach(b => b.classList.remove('selected'));
  _updateTopUpBreakdown(amt);
}

function _updateTopUpBreakdown(amt) {
  const btn = document.getElementById('topupPayBtn');
  const bd  = document.getElementById('topupBreakdown');

  if (!amt || amt < 100) {
    bd.classList.remove('visible');
    btn.disabled  = true;
    btn.innerHTML = '<i class="bi bi-shield-lock-fill"></i> Pay Securely';
    return;
  }

  const bal        = _topupWalletData ? (_topupWalletData.balance    || 0)   : 0;
  const minBal     = _topupWalletData ? (_topupWalletData.minBalance || 500) : 500;
  const balAfter   = bal + amt;
  const availAfter = Math.max(0, balAfter - minBal);

  _setText('tdTopupAmt',   '₹' + amt.toFixed(2));
  _setText('tdBalAfter',   '₹' + balAfter.toFixed(2));
  _setText('tdAvailAfter', '₹' + availAfter.toFixed(2));
  bd.classList.add('visible');

  btn.disabled  = false;
  btn.innerHTML = `<i class="bi bi-shield-lock-fill"></i> Pay ₹${amt.toFixed(0)} Securely`;
}

function initiateTopUp() {
  const amt = parseFloat(document.getElementById('topupAmtInput').value) || 0;
  if (amt < 100) { showToast('Minimum top-up amount is ₹100.', 'error'); return; }

  document.getElementById('topupFormView').style.display       = 'none';
  document.getElementById('topupProcessingView').style.display = 'block';

  const params = new URLSearchParams();
  params.append('action', 'createTopupOrder');
  params.append('amount', amt);

  _safePostJson(WALLET_SERVLET, params)
    .then(data => {
      if (!data.success) { _showTopUpFailed(data.message || 'Could not initiate payment.'); return; }
      _openRazorpayCheckout(data, amt);
    })
    .catch(err => _showTopUpFailed(err.message || 'Network error. Please try again.'));
}

function _openRazorpayCheckout(serverData, amtRupees) {
  document.getElementById('topupProcessingView').style.display = 'none';

  // FIX-RAZORPAY: Ensure amount is always an integer (paise) — Razorpay's risk
  // detection script calls .trim() on string fields; passing a non-integer or
  // non-string where the SDK doesn't expect it causes the TypeError.
  const options = {
    key:         String(serverData.key      || ''),
    amount:      Math.round(Number(serverData.amount) || 0),   // must be integer paise
    currency:    'INR',
    name:        'DeliveryPro Wallet',
    description: 'Agent Wallet Top-Up',
    order_id:    String(serverData.razorpayOrderId || ''),
    prefill: {
      name:    String(serverData.agentName    || ''),
      contact: String(serverData.agentContact || '')
    },
    theme: { color: '#7C5CBF' },
    modal: {
      ondismiss: function() {
        showTopUpForm();
        document.getElementById('topupModalOverlay').classList.add('open');
      }
    },
    handler: function(rzpResponse) {
      _verifyTopUp(rzpResponse, amtRupees);
    }
  };

  try {
    const rzp = new Razorpay(options);
    rzp.on('payment.failed', resp => {
      _showTopUpFailed('Payment failed: ' + (resp.error.description || 'Please try another method.'));
    });
    rzp.open();
  } catch(e) {
    _showTopUpFailed('Could not load payment gateway. Check your connection.');
  }
}

function _verifyTopUp(rzpResponse, amtRupees) {
  document.getElementById('topupFormView').style.display       = 'none';
  document.getElementById('topupProcessingView').style.display = 'block';

  const params = new URLSearchParams();
  params.append('action',              'topupVerify');
  params.append('razorpay_order_id',    rzpResponse.razorpay_order_id);
  params.append('razorpay_payment_id',  rzpResponse.razorpay_payment_id);
  params.append('razorpay_signature',   rzpResponse.razorpay_signature);
  params.append('amount',               amtRupees);

  _safePostJson(WALLET_SERVLET, params)
    .then(data => {
      document.getElementById('topupProcessingView').style.display = 'none';
      if (data.success) {
        document.getElementById('topupSuccessView').style.display = 'block';
        _setText('topupSuccessMsg',
          '₹' + amtRupees.toFixed(0) + ' added to your wallet.' +
          (data.isNowOnline ? " You're back Online! 🟢" : ''));
        loadWalletData();
        if (data.isNowOnline) _setAgentOnlinePill(true);
        showToast('₹' + amtRupees.toFixed(0) + ' added successfully!', 'success');
      } else {
        _showTopUpFailed(data.message || 'Verification failed. Contact support with payment ID: ' + rzpResponse.razorpay_payment_id);
      }
    })
    .catch(err => {
      _showTopUpFailed('Verification error: ' + err.message + '. Payment ID: ' + rzpResponse.razorpay_payment_id);
    });
}

function _showTopUpFailed(msg) {
  document.getElementById('topupFormView').style.display       = 'none';
  document.getElementById('topupProcessingView').style.display = 'none';
  document.getElementById('topupSuccessView').style.display    = 'none';
  document.getElementById('topupFailedView').style.display     = 'block';
  _setText('topupFailedMsg', msg);
}

function _setAgentOnlinePill(online,locked = false) {
  const dot  = document.getElementById('statusDot');
  const text = document.getElementById('statusText');
   const pill = document.querySelector('.online-pill');

   if (dot)  dot.classList.toggle('off', !online);
   if (text) text.textContent = online ? 'Online' : 'Offline';
   isOnline = online;

   /* BUG-3 FIX: lock the button when shift is completed/inactive */
   if (pill) {
     if (locked) {
       pill.style.opacity      = '0.55';
       pill.style.cursor       = 'not-allowed';
       pill.style.pointerEvents = 'none';
       pill.title = online
         ? ''
         : 'Book a slot to go online. Your shift has ended or has not been booked.';
     } else {
       pill.style.opacity      = '';
       pill.style.cursor       = '';
       pill.style.pointerEvents = '';
       pill.title = '';
     }
   }

}

/* ── Wallet banner ── */

function _updateWalletBanner(walletData) {
  const banner = document.getElementById('walletBanner');
  if (!banner) return;

  const bal    = walletData.balance    || 0;
  const cod    = walletData.codFloat   || 0;
  const minBal = walletData.minBalance || 500;
  const avail  = Math.max(0, bal - cod - minBal);  // true available
  const agentIsOnline = !document.getElementById('statusDot')?.classList.contains('off');

  if (avail <= 0 && !agentIsOnline) {
    // blocked — show hard warning
    banner.className     = 'wallet-banner offline-blocked';
    banner.style.display = 'block';
    banner.innerHTML =
      `<span><i class="bi bi-wifi-off"></i> <strong>You are Offline.</strong> `
      + `Available balance (₹${avail.toFixed(2)}) is below zero after COD float. `
      + `Top up to go back online.</span>`
      + `<button class="banner-action" onclick="openTopUpModal()">Top Up Now</button>`;
  } else if (bal < minBal * 1.2) {
    // low but not blocked
    banner.className     = 'wallet-banner topup-required';
    banner.style.display = 'block';
    banner.innerHTML =
      `<span><i class="bi bi-exclamation-triangle-fill"></i> <strong>Low Balance.</strong> `
      + `Your balance (₹${bal.toFixed(2)}) is close to the minimum ₹${minBal.toFixed(0)}. `
      + `Top up to avoid going Offline.</span>`
      + `<button class="banner-action" onclick="openTopUpModal()">Top Up</button>`;
  } else {
    banner.style.display = 'none';
  }
}

document.addEventListener('DOMContentLoaded', () => {
  const overlay = document.getElementById('topupModalOverlay');
  if (overlay) {
    overlay.addEventListener('click', e => { if (e.target === overlay) closeTopUpModal(); });
  }
});

/* ══════════════════════════════════════════════════════════════════
   COD DEPOSIT — Cash Handover Flow 
   ══════════════════════════════════════════════════════════════════ */

const _depositState = {};

// Option A — Agent physically hands cash at hub
function depositCashAtHub(orderId, expectedAmount) {
  if (_depositState[orderId] === 'processing' ||
      _depositState[orderId] === 'done'        ||
      _depositState[orderId] === 'submitted') return;
 
  _depositState[orderId] = 'processing';
  const cashBtn = document.getElementById('btn-cash-' + orderId);
  if (cashBtn) { 
    cashBtn.disabled = true; 
    cashBtn.innerHTML = '<i class="bi bi-hourglass-split"></i> Recording…'; 
  }
 
  const amtInput   = document.getElementById('amt-'   + orderId);
  const notesInput = document.getElementById('notes-' + orderId);
  const amount     = amtInput ? parseFloat(amtInput.value) || expectedAmount : expectedAmount;
  const notes      = notesInput ? notesInput.value.trim() : '';
 
  const params = new URLSearchParams();
  params.append('action',  'agentDeposit');
  params.append('orderId',  orderId);
  params.append('amount',   amount.toFixed(2));
  if (notes) params.append('notes', notes);
 
  _safePostJson(CTX + '/CodDepositServlet', params)
    .then(data => {
      if (data.success) {
        _depositState[orderId] = 'submitted';
        
        showToast(
          'Cash deposit recorded for Order #' + orderId + '. Awaiting staff confirmation.',
          'success'
        );
        
        // Decrement pending count badge in the header layout wallet strip
        const countEl = document.getElementById('wsPendingCount');
        if (countEl) {
          const cur = parseInt(countEl.textContent) || 0;
          if (cur > 0) countEl.textContent = cur - 1;
        }

        // ✅ REMOVE ORDER DETAILS FROM COD PAGE IMMEDIATELY ON SUBMISSION
        const orderCard = document.getElementById('card-' + orderId);
        if (orderCard) {
          // Smooth fade-out effect before removal
          orderCard.style.transition = 'opacity 0.4s ease, transform 0.4s ease';
          orderCard.style.opacity = '0';
          orderCard.style.transform = 'scale(0.95)';
          
          setTimeout(() => {
            orderCard.remove();
            
            // Check if there are any remaining order cards left on the page
            const remainingCards = document.querySelectorAll('[id^="card-"]');
            if (remainingCards.length === 0) {
              const container = document.querySelector('.container') || document.body;
              // If empty, append a user-friendly completion message
              const emptyMsg = document.createElement('div');
              emptyMsg.className = 'text-center my-5 p-5 bg-white rounded shadow-sm';
              emptyMsg.innerHTML = `
                <i class="bi bi-check-circle text-success" style="font-size: 4rem;"></i>
                <h4 class="mt-3">All Caught Up!</h4>
                <p class="text-muted">No pending COD cash handovers left to report.</p>
                <a href="${CTX}/DeliveryPortalServlet" class="btn btn-primary mt-2">Return to Dashboard</a>
              `;
              container.appendChild(emptyMsg);
            }
          }, 400);
        }

      } else {
        const msg = data.message || '';
        const alreadyDone = msg.toLowerCase().includes('already') ||
                            msg.toLowerCase().includes('confirmed');
 
        if (alreadyDone) {
          _depositState[orderId] = 'done';
          showToast('Order #' + orderId + ' deposit was already confirmed by staff.', 'info');
          
          // Remove from view if it was already updated out-of-band
          const orderCard = document.getElementById('card-' + orderId);
          if (orderCard) orderCard.remove();
        } else {
          _depositState[orderId] = 'idle';
          if (cashBtn) {
            cashBtn.disabled = false;
            cashBtn.innerHTML = '<i class="bi bi-cash-coin"></i> Submit Handover';
          }
          showToast(msg || 'Could not record deposit. Please try again.', 'danger');
        }
      }
    })
    .catch(err => {
      _depositState[orderId] = 'idle';
      if (cashBtn) {
        cashBtn.disabled = false;
        cashBtn.innerHTML = '<i class="bi bi-cash-coin"></i> Submit Handover';
      }
      showToast(err.message || 'Network error. Please try again.', 'danger');
    });
}

function checkCodDepositBalance() {
  _fetchJson(CTX + '/AgentWalletServlet?action=getWallet')
    .then(d => {
      _walletData = d;
      const cashEl = document.getElementById('wsCashHand');
      const earnEl = document.getElementById('wsEarnings');
      if (cashEl) cashEl.textContent = '₹' + Number(d.codFloat || d.cashInHand || 0).toFixed(0);
      if (earnEl) earnEl.textContent = '₹' + Number(d.earningsToday || 0).toFixed(0);
    })
    .catch(() => { /* non-fatal */ });
}

function openCodDepositForOrder(orderId) {
  window.location.href = CTX + '/CodDepositServlet?orderId=' + orderId;
}
/* ══════════════════════════════════════════════════════════════════
   REJECTION COUNT BANNER — shown inside confirm modal
   Tracks locally from server response. Server is authoritative.
   ══════════════════════════════════════════════════════════════════ */


function _showRejectionWarningBanner(count) {
  const body = document.querySelector('.cm-body');
  if (!body) return;
  const old = body.querySelector('.reject-warn-banner');
  if (old) old.remove();

  if (count < 2) return; // no banner needed for first rejection

  const banner = document.createElement('div');
  banner.className = 'reject-warn-banner';

  if (count >= 3) {
    banner.style.cssText =
      'background:#ffebee;border-left:4px solid #c62828;color:#b71c1c;' +
      'border-radius:8px;padding:11px 14px;margin-top:10px;font-size:13px;' +
      'display:flex;align-items:flex-start;gap:8px;';
    banner.innerHTML =
      `<i class="bi bi-slash-circle-fill" style="font-size:16px;flex-shrink:0;margin-top:1px;"></i>` +
      `<span><strong>⛔ Final Warning:</strong> You have already rejected 2 tasks. ` +
      `This rejection will <strong>restrict your account</strong>. ` +
      `Contact your supervisor to reactivate.</span>`;
  } else {
    banner.style.cssText =
      'background:#fff8e1;border-left:4px solid #b45309;color:#7d4e00;' +
      'border-radius:8px;padding:11px 14px;margin-top:10px;font-size:13px;' +
      'display:flex;align-items:flex-start;gap:8px;';
    banner.innerHTML =
      `<i class="bi bi-exclamation-triangle-fill" style="font-size:16px;flex-shrink:0;margin-top:1px;"></i>` +
      `<span><strong>⚠️ Warning:</strong> You have already rejected 1 task. ` +
      `One more rejection will <strong>restrict your account</strong>.</span>`;
  }
  body.appendChild(banner);
}

// Fetch rejection count when opening the reject task modal
const _origOpenRejectTaskConfirm = openRejectTaskConfirm;
// Override openRejectTaskConfirm to fetch current rejection count
function openRejectTaskConfirm(orderId) {
  _pendingOrderId = orderId;
  _cancelMode     = 'rejectTask';
  _setModalHead('Reject Task', 'bi-slash-circle', 'var(--red)');
  _setOrderInfo(orderId,
    'This order will be unassigned from you.',
    'Staff will be notified and will reassign to another agent. Your rejection will be logged.'
  );
  _showReasonSelectFor('rejectTask');

  const btn = document.getElementById('cm-confirm-btn');
  btn.className   = 'cm-btn cm-confirm danger';
  btn.textContent = 'Confirm Rejection';
  btn.disabled    = false;
  _openModal();

  // Fetch current rejection count to show warning
  fetch(CTX + '/OrdersDashboard?action=getAgentRejectionCount', {
    headers: { 'X-Requested-With': 'XMLHttpRequest' }
  })
  .then(r => r.ok ? r.json() : null)
  .then(data => {
    if (data && typeof data.count === 'number') {
      _showRejectionWarningBanner(data.count);
    }
  })
  .catch(() => { /* non-fatal */ });
}
function _doStatusUpdate(wantOnline) {
  /* Optimistic flip */
  _setAgentOnlinePill(wantOnline, false);
 
  const params = new URLSearchParams();
  params.append('action', 'updateStatus');
  params.append('status', wantOnline ? 'active' : 'inactive');
 
  fetch(CTX + '/DeliveryPortalServlet', {
    method:  'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body:    params
  })
  .then(r => {
    if (!r.ok) throw new Error('Server error ' + r.status);
    return r.json();
  })
  .then(data => {
    if (data.success) {
      isOnline = wantOnline;          // confirm the optimistic flip
      showToast(data.message || (wantOnline ? 'You are now online.' : 'You are now offline.'),
                wantOnline ? 'success' : 'info');
    } else {
      _setAgentOnlinePill(!wantOnline, false);    // revert
      showToast(data.message || 'Status not saved.', 'error');
      // If it's a wallet/balance issue, pop the top-up modal automatically
	  if ((data.message && data.message.toLowerCase().includes('wallet'))
	      || (data.message && data.message.toLowerCase().includes('balance'))){
        setTimeout(() => { if (typeof openTopUpModal === 'function') openTopUpModal(); }, 900);
      }
    }
  })
  .catch(err => {
    _setAgentOnlinePill(!wantOnline, false);       // revert
    showToast('Status not saved — ' + err.message, 'error');
  });
}
function _syncOfflineToDb() {
  const params = new URLSearchParams();
  params.append('action', 'updateStatus');
  params.append('status', 'inactive');
  fetch(CTX + '/DeliveryPortalServlet', {
    method:  'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body:    params
  }).catch(() => { /* non-fatal, poller will correct */ });
}
 
/* ════════════════════════════════════════════════════════════════════════════
   SECTION 4 — Beautiful native alert for slot guards
   ════════════════════════════════════════════════════════════════════════════ */
 
function _showSlotAlert(title, message, actionLabel, actionFn) {
  /* Remove any existing */
  const old = document.getElementById('_slotGuardModal');
  if (old) old.remove();
 
  const overlay = document.createElement('div');
  overlay.id = '_slotGuardModal';
  overlay.style.cssText =
    'position:fixed;inset:0;background:rgba(0,0,0,0.45);z-index:9999;' +
    'display:flex;align-items:center;justify-content:center;padding:20px;';
 
  const box = document.createElement('div');
  box.style.cssText =
    'background:#fff;border-radius:16px;padding:28px 24px 20px;max-width:340px;width:100%;' +
    'box-shadow:0 8px 40px rgba(0,0,0,0.18);text-align:center;font-family:inherit;';
 
  const iconEl = document.createElement('div');
  iconEl.style.cssText = 'font-size:42px;margin-bottom:12px;line-height:1;';
  iconEl.textContent   = title.split(' ')[0];  // the emoji
 
  const titleEl = document.createElement('div');
  titleEl.style.cssText = 'font-size:17px;font-weight:700;color:#1a1a2e;margin-bottom:10px;';
  titleEl.textContent   = title.replace(/^[^\s]+\s/, '');  // without emoji
 
  const msgEl = document.createElement('div');
  msgEl.style.cssText = 'font-size:14px;color:#555;line-height:1.6;margin-bottom:20px;white-space:pre-line;';
  msgEl.textContent   = message;
 
  const btnRow = document.createElement('div');
  btnRow.style.cssText = 'display:flex;gap:10px;justify-content:center;';
 
  const dismiss = document.createElement('button');
  dismiss.textContent = 'OK';
  dismiss.style.cssText =
    'flex:1;padding:10px 18px;border-radius:10px;border:1px solid #d0d0d0;' +
    'background:#f5f5f5;color:#333;font-size:14px;font-weight:600;cursor:pointer;';
  dismiss.onclick = () => overlay.remove();
 
  btnRow.appendChild(dismiss);
 
  if (actionLabel && actionFn) {
    const act = document.createElement('button');
    act.textContent = actionLabel;
    act.style.cssText =
      'flex:1;padding:10px 18px;border-radius:10px;border:none;' +
      'background:#7C5CBF;color:#fff;font-size:14px;font-weight:600;cursor:pointer;';
    act.onclick = () => { overlay.remove(); actionFn(); };
    btnRow.appendChild(act);
  }
 
  box.append(iconEl, titleEl, msgEl, btnRow);
  overlay.appendChild(box);
  overlay.addEventListener('click', e => { if (e.target === overlay) overlay.remove(); });
  document.body.appendChild(overlay);
}
 
 
/* ════════════════════════════════════════════════════════════════════════════
   SECTION 5 — Shift lifecycle manager  (BUG-4 + BUG-5 fixes applied)
   ════════════════════════════════════════════════════════════════════════════ */
 
function _fmtDuration(secs) {
  if (secs < 0) secs = 0;
  const h  = Math.floor(secs / 3600);
  const m  = Math.floor((secs % 3600) / 60);
  const s  = secs % 60;
  const mm = String(m).padStart(2, '0');
  const ss = String(s).padStart(2, '0');
  return h > 0 ? `${h}:${mm}:${ss}` : `${m}:${ss}`;
}
 
function _epochToTimeStr(epMs) {
  if (!epMs) return '—';
  return new Date(epMs).toLocaleTimeString('en-IN',
    { hour: 'numeric', minute: '2-digit', hour12: true });
}
 
/* ── 1. Shift poller ────────────────────────────────────────────────── */
 
function _startShiftPoll() {
  if (_shiftPollTimer) return;
  _doShiftPoll();
  _shiftPollTimer = setInterval(_doShiftPoll, 60000);
}
 
function _doShiftPoll() {
  if (document.hidden) return;
  fetch(CTX + '/DeliverySlotServlet?action=getShiftStatus', {
    headers: { 'X-Requested-With': 'XMLHttpRequest' }
  })
  .then(r => r.ok ? r.json() : null)
  .then(data => { if (data) _applyShiftData(data, false); })
  .catch(() => {});
}
 
/* ── Apply server snapshot → update local state + UI ────────────────── */
 
function _applyShiftData(data, fromStartShift) {
  const prev = _shiftState.status;
 
  _shiftState.hasSlot               = !!data.hasSlot;
  _shiftState.slotId                = data.slotId               || -1;
  _shiftState.slotType              = data.slotType              || '';
  _shiftState.status                = data.status               || 'NONE';
  _shiftState.slotStartTime         = data.slotStartTime        || '';
  _shiftState.slotEndTime           = data.slotEndTime          || '';
  _shiftState.slotStartEpochMs      = data.slotStartEpochMs     || 0;
  _shiftState.slotEndEpochMs        = data.slotEndEpochMs       || 0;
  _shiftState.shiftStartedAtEpochMs = data.shiftStartedAtEpochMs || 0;  // BUG-6 field
  _shiftState.totalBreakMin         = data.totalBreakMin        || 0;
  // BUG-4 FIX: breakStartEpoch was never populated from server data, so
  // _tickShiftClock()'s live-break-subtraction branch (st === 'ON_BREAK' &&
  // breakStartEpoch > 0) was never entered — the working-hours clock kept
  // ticking upward during breaks instead of pausing.
  _shiftState.breakStartEpoch       = data.breakStartEpoch      || 0;
 
  const agentStatus = (data.agentStatus || '').toLowerCase();
  const st          = _shiftState.status;
 
  /* ── Sync the online pill with slot-aware locking ───────────────── */
  if (st === 'ACTIVE' || st === 'ON_BREAK') {
    if (!isOnline) _setAgentOnlinePill(true, false);
 
  } else if (st === 'INACTIVE' || st === 'COMPLETED' || st === 'EXPIRED' || agentStatus === 'inactive') {
    // BUG-FIX: EXPIRED must lock the pill just like COMPLETED/INACTIVE.
    // Previously EXPIRED fell through to the default branch and left the pill
    // in an indeterminate state, sometimes showing Online while slot was expired.
    const shouldBeLocked = (st === 'INACTIVE' || st === 'COMPLETED' || st === 'EXPIRED');
    if (isOnline || shouldBeLocked) {
      _setAgentOnlinePill(false, shouldBeLocked);
 
      /* BUG-4 FIX: persist to DB if server forced offline */
      if (isOnline && shouldBeLocked) {
        _syncOfflineToDb();
      }
 
      if (st === 'COMPLETED' && prev !== 'COMPLETED') {
        showToast('Your shift has ended. Earnings credited to wallet.', 'info');
      }
    }
 
  } else if (st === 'BOOKED') {
    /* Before window — lock pill so agent can't go online yet */
    const now = Date.now();
    const tooEarly = _shiftState.slotStartEpochMs > 0 &&
                     now < (_shiftState.slotStartEpochMs - 15 * 60 * 1000);
    _setAgentOnlinePill(false, tooEarly);
  }
 
  /* ── Schedule auto-offline timer ───────────────────────────────── */
  if ((st === 'ACTIVE' || st === 'ON_BREAK') && _shiftState.slotEndEpochMs > 0) {
    _scheduleAutoOffline(_shiftState.slotId, _shiftState.slotEndEpochMs);
  }
 
  /* ── Start the working-hours clock ─────────────────────────────── */
  if (st === 'ACTIVE' || st === 'ON_BREAK') {
    if (fromStartShift) {
      _shiftState.shiftClockStart = Date.now();
      // Persist so the clock survives poll cycles without drifting
      try { sessionStorage.setItem('shiftClockStart_' + _shiftState.slotId, String(_shiftState.shiftClockStart)); } catch(e){}
    } else if (!_shiftState.shiftClockStart) {
      // Try to restore from sessionStorage (same tab session)
      try {
        const saved = sessionStorage.getItem('shiftClockStart_' + _shiftState.slotId);
        if (saved) _shiftState.shiftClockStart = parseInt(saved, 10);
      } catch(e){}
    }
    _startShiftClock();
  } else if (st === 'BOOKED') {
    _renderShiftWaitingClock();
  } else {
    _stopShiftClock();
  }
 
  /* ── Render the working hours panel widget ───────────────────────── */
  _renderWorkingHoursPanel(data);
}
 
/* ── 2. Auto-offline timer ──────────────────────────────────────────── */
 
function _scheduleAutoOffline(slotId, endEpochMs) {
  if (_autoOfflineTimer) { clearTimeout(_autoOfflineTimer); _autoOfflineTimer = null; }
 
  const msUntilEnd = endEpochMs - Date.now();
 
  if (msUntilEnd <= 0) {
    _triggerAutoOffline(slotId);
    return;
  }
 
  const minsLeft = Math.round(msUntilEnd / 60000);
  if (minsLeft > 15) {
    const warnMs = msUntilEnd - 15 * 60 * 1000;
    setTimeout(() => showToast('⚠️ Your shift ends in 15 minutes.', 'warning'), warnMs);
  }
 
  _autoOfflineTimer = setTimeout(() => _triggerAutoOffline(slotId), msUntilEnd);
}
 
function _triggerAutoOffline(slotId) {
  _autoOfflineTimer = null;
 
  const fd = new FormData();
  fd.append('action', 'autoOffline');
  fd.append('slotId', slotId);
 
  fetch(CTX + '/DeliverySlotServlet', { method: 'POST', body: fd })
  .then(r => r.json())
  .then(data => {
    _setAgentOnlinePill(false, true);    /* BUG-3 FIX: lock after auto-offline */
    _stopShiftClock();
    const earned = data.earnedToday ? '₹' + parseFloat(data.earnedToday).toFixed(0) : '';
    showToast('⏰ Shift Ended — ' + (earned ? earned + ' credited.' : 'You are now offline.'), 'warning');
    setTimeout(() => location.reload(), 3000);
  })
  .catch(() => {
    _setAgentOnlinePill(false, true);    /* BUG-3 FIX */
    _stopShiftClock();
    showToast('⏰ Your shift has ended. You have been set offline.', 'warning');
    setTimeout(() => location.reload(), 4000);
  });
}
 
/* ── 3. Working-hours clock  (BUG-5 FIX: use shiftStartedAtEpochMs) ── */
 
function _startShiftClock() {
  if (_shiftClockTimer) return;
  _tickShiftClock();
  _shiftClockTimer = setInterval(_tickShiftClock, 1000);
}
 
function _stopShiftClock() {
  if (_shiftClockTimer) { clearInterval(_shiftClockTimer); _shiftClockTimer = null; }
  const el = document.getElementById('shiftWorkingHours');
  if (el && _shiftState.status === 'COMPLETED') el.textContent = 'Shift Done';
}
function _tickShiftClock() {
  const el = document.getElementById('shiftWorkingHours');
  if (!el) return;

  const st = _shiftState.status;
  if (st !== 'ACTIVE' && st !== 'ON_BREAK') { el.textContent = '—'; return; }

  // 1. Determine start of shift
  const clockOrigin =
    _shiftState.shiftClockStart       > 0 ? _shiftState.shiftClockStart       :
    _shiftState.shiftStartedAtEpochMs > 0 ? _shiftState.shiftStartedAtEpochMs :
    _shiftState.slotStartEpochMs;

  if (!clockOrigin) { el.textContent = '—'; return; }

  // 2. Calculate Total Elapsed Time
  const now = Date.now();
  const elapsedSec = Math.floor((now - clockOrigin) / 1000);

  // 3. Calculate Break Time
  let totalBreakSec = (_shiftState.totalBreakMin || 0) * 60;
  
  // FIX: If currently on break, add the 'live' break seconds to the subtraction
  if (st === 'ON_BREAK' && _shiftState.breakStartEpoch > 0) {
      const liveBreakSec = Math.floor((now - _shiftState.breakStartEpoch) / 1000);
      totalBreakSec += liveBreakSec;
  }

  // 4. Calculate Net Work Time
  const workSec = Math.max(0, elapsedSec - totalBreakSec);
  el.textContent = _fmtDuration(workSec);

  // 5. Time Remaining Logic (This part is perfect as is)
  const remEl = document.getElementById('shiftTimeRemaining');
  if (remEl && _shiftState.slotEndEpochMs) {
    const remSec = Math.max(0, Math.floor((_shiftState.slotEndEpochMs - now) / 1000));
    remEl.textContent = remSec > 0 ? _fmtDuration(remSec) + ' left' : 'Ending…';
    remEl.style.color = remSec < 900 ? 'var(--red)' : 'var(--text3)';
  }
}

 
function _renderShiftWaitingClock() {
  const el = document.getElementById('shiftWorkingHours');
  if (!el || !_shiftState.slotStartEpochMs) return;

  if (_shiftClockTimer) { clearInterval(_shiftClockTimer); _shiftClockTimer = null; }

  // FIX-TIMER-1: The countdown must count from NOW to the EARLY-OPEN window
  // (slotStart - 15 min).  When secsUntil <= 0 the window is open and the
  // agent can start.  Also update the inline #portalShiftCountdown span (if
  // present in SlotBooking.jsp) so the card header shows a live countdown
  // instead of a static "Shift starts at HH:MM" label.
  _shiftClockTimer = setInterval(() => {
    const earlyOpenMs = _shiftState.slotStartEpochMs - 15 * 60 * 1000;
    const secsUntil   = Math.floor((earlyOpenMs - Date.now()) / 1000);

    if (secsUntil <= 0) {
      // Window is now OPEN — show ready state
      el.textContent  = 'Ready — Start Shift!';
      el.style.color  = 'var(--green)';
      clearInterval(_shiftClockTimer);
      _shiftClockTimer = null;
      _setAgentOnlinePill(false, false);

      // Unlock the Start Shift button
      const btn = document.getElementById('portalBtnStart');
      if (btn) {
        btn.disabled = false;
        // FIX-TIMER-2: was btn.textContent = '' which wiped the button label.
        // Use innerHTML so the icon is preserved correctly.
        btn.innerHTML = '<i class="bi bi-play-circle-fill"></i> Start Shift';
      }

      // Swap the blue "waiting" info bar to the green "Ready!" banner
      const countdown = document.getElementById('portalShiftCountdown');
      if (countdown) {
        const bar = countdown.closest('.slot-info-bar') || countdown.parentElement;
        if (bar) {
          bar.style.background      = 'var(--green-bg, #d1fae5)';
          bar.style.borderLeftColor = 'var(--green, #16a34a)';
          bar.style.color           = 'var(--green, #16a34a)';
          bar.innerHTML = '<i class="bi bi-check-circle-fill"></i> <strong>Ready!</strong> Your shift window is now active. Tap Start Shift.';
        }
      }
      return;
    }

    // Still counting down — show "Starts in HH:MM:SS" in working-hours cell
    el.textContent = 'Starts in ' + _fmtDuration(secsUntil);
    el.style.color = 'var(--blue, #2563eb)';

    // FIX-TIMER-3: Also keep the countdown span on the slot card in sync so
    // the "Shift starts at X" label on SlotBooking.jsp updates live.
    const cdSpan = document.getElementById('portalShiftCountdown');
    if (cdSpan) {
      // Only rewrite if it currently contains static text (avoid overwriting
      // the Ready! banner that was just set above on the exact tick).
      if (!cdSpan.textContent.includes('Ready')) {
        cdSpan.textContent = 'Starts in ' + _fmtDuration(secsUntil);
      }
    }
  }, 1000);
}
/* ── 4. Working Hours panel renderer ────────────────────────────────── */
 
function _renderWorkingHoursPanel(data) {

  const panel = document.getElementById('workingHoursPanel');

  if (!panel) return;



  const st        = data.status       || 'NONE';

  const hasSlot   = !!data.hasSlot;

  const startFmt  = data.slotStartTime || '—';

  const endFmt    = data.slotEndTime   || '—';

  const breakMin  = data.totalBreakMin || 0;

  const OVERNIGHT_TYPES = new Set(['NIGHT', 'MIDNIGHT', 'EARLY_MORNING']);
  const overnight = OVERNIGHT_TYPES.has(data.slotType);


  // ── All known slot types with icon + time-range label ─────────────────────

  const slotLabel = {

    AM:            '🌅 6 AM – 12 PM',

    PM:            '☀️ 12 PM – 6 PM',

    EVENING:       '🌆 6 PM – 10 PM',

    NIGHT:         '🌙 10 PM – 2 AM',       // overnight — ends next calendar day

    MIDNIGHT:      '🌑 2 AM – 6 AM',

    EARLY_MORNING: '🌄 4 AM – 8 AM',

    FULL_DAY:      '📅 6 AM – 10 PM'

  };

  const typeLabel = slotLabel[data.slotType] || (data.slotType || '');



  // ── "+1" badge shown next to end time for overnight shifts ────────────────

  const endDisplay = overnight

    ? `${endFmt} <span style="font-size:10px;color:var(--text3);vertical-align:middle;">(+1&nbsp;day)</span>`

    : endFmt;



  // ── No slot at all ─────────────────────────────────────────────────────────

  if (!hasSlot) {

    panel.innerHTML =

      `<div class="wh-row">

         <span class="wh-label"><i class="bi bi-clock"></i> No Shift Today</span>

         <span class="wh-val" style="color:var(--text3);">

           <a href="${CTX}/DeliverySlotServlet" style="color:var(--brand);font-weight:600;">

             <i class="bi bi-calendar-plus"></i> Book a Slot

           </a>

         </span>

       </div>`;

    return;

  }



  // ── Slot is present — compute derived flags ────────────────────────────────

  const now          = Date.now();

  const slotExpired  = data.slotEndEpochMs > 0 && now > data.slotEndEpochMs;

  const isLiveShift  = (st === 'ACTIVE' || st === 'ON_BREAK');



  const statusColor = {

    BOOKED:    'var(--blue)',

    ACTIVE:    'var(--green)',

    ON_BREAK:  'var(--amber)',

    INACTIVE:  'var(--red)',

    COMPLETED: 'var(--text3)',

    // BUG-FIX: EXPIRED/CANCELLED must have explicit entries so they never fall
    // through to `statusLabel[st] || st` and display the raw DB string.
    EXPIRED:   'var(--text3)',

    CANCELLED: 'var(--text3)',

    NONE:      'var(--text3)'

  };

  const statusLabel = {

    BOOKED:    'Booked — Not Started',

    ACTIVE:    'Online · Active',

    ON_BREAK:  'On Break',

    INACTIVE:  'Forced Offline',

    COMPLETED: 'Shift Completed',

    // BUG-FIX: EXPIRED/CANCELLED human-readable labels (defence-in-depth)
    EXPIRED:   'Slot Expired — Book a New Slot',

    CANCELLED: 'Slot Cancelled',

    NONE:      'No Slot'

  };



  // ── Working-hours cell content ─────────────────────────────────────────────

  let workingCell;

  if (isLiveShift) {

    workingCell = `<span id="shiftWorkingHours"

                        style="font-weight:700;font-variant-numeric:tabular-nums;">—</span>`;

  } else if (st === 'BOOKED') {

    workingCell = `<span id="shiftWorkingHours"

                        style="font-weight:700;font-variant-numeric:tabular-nums;color:var(--blue);">

                     Starts at ${startFmt}

                   </span>`;

  } else if (st === 'COMPLETED' || slotExpired) {

    workingCell = `<span id="shiftWorkingHours" style="color:var(--text3);">Shift Done</span>`;

  } else {

    workingCell = `<span id="shiftWorkingHours"

                        style="font-weight:700;font-variant-numeric:tabular-nums;">—</span>`;

  }



  // ── Expired-slot notice row ────────────────────────────────────────────────

  // Shown when the slot has ticked past its end epoch but the server hasn't

  // yet pushed a COMPLETED/INACTIVE status (e.g. poll hasn't fired yet, or the

  // overnight shift ended early morning on the next calendar day).

  const expiredRow = (slotExpired && !isLiveShift) ? `

     <div class="wh-row" style="background:rgba(var(--red-rgb,220,53,69),.08);border-radius:6px;padding:4px 8px;">

       <span class="wh-label" style="color:var(--red);">

         <i class="bi bi-exclamation-circle-fill"></i> Shift Expired

       </span>

       <span class="wh-val" style="color:var(--red);font-size:12px;">

         Ended at ${endFmt}${overnight ? ' (next day)' : ''} — book a new slot

       </span>

     </div>` : '';



  panel.innerHTML =

    `<div class="wh-row">

       <span class="wh-label"><i class="bi bi-calendar-check"></i> Shift</span>

       <span class="wh-val">${typeLabel}&nbsp;

         <span style="color:var(--text3);font-size:11px;">${startFmt} – ${endDisplay}</span>

       </span>

     </div>

     <div class="wh-row">

       <span class="wh-label">

         <i class="bi bi-circle-fill" style="font-size:8px;color:${statusColor[st]||'var(--text3)'};" aria-hidden="true"></i>

         Status

       </span>

       <span class="wh-val" style="color:${statusColor[st]||'var(--text3)'};font-weight:700;">

         ${statusLabel[st] || st}

       </span>

     </div>

     <div class="wh-row">

       <span class="wh-label"><i class="bi bi-hourglass-split"></i> Working</span>

       <span class="wh-val">${workingCell}</span>

     </div>

     ${isLiveShift ? `

     <div class="wh-row">

       <span class="wh-label"><i class="bi bi-alarm"></i> Ends</span>

       <span class="wh-val" id="shiftTimeRemaining" style="font-size:12px;color:var(--text3);">

         ${endFmt}${overnight ? ' <span style="font-size:10px;">(+1 day)</span>' : ''}

       </span>

     </div>` : ''}

     ${breakMin > 0 ? `

     <div class="wh-row">

       <span class="wh-label"><i class="bi bi-cup-hot"></i> Break Used</span>

       <span class="wh-val" style="color:var(--amber);">${breakMin} min</span>

     </div>` : ''}

     ${expiredRow}`;

}

 

document.addEventListener('DOMContentLoaded', _startShiftPoll);

document.addEventListener('visibilitychange', () => {

  if (!document.hidden) _doShiftPoll();

});


 
 
/* ════════════════════════════════════════════════════════════════════════════
   SECTION 6 — Background status poller (30 s)
   Catches server-initiated offline events (COD balance, admin action)
   ════════════════════════════════════════════════════════════════════════════ */
 
let _statusPollTimer = null;
 
function _startStatusPoll() {
  if (_statusPollTimer) return;
  _statusPollTimer = setInterval(_pollStatus, 30000);
}
 
function _stopStatusPoll() {
  if (_statusPollTimer) { clearInterval(_statusPollTimer); _statusPollTimer = null; }
}
 
function _pollStatus() {
  if (document.hidden) return;
  fetch(CTX + '/DeliveryPortalServlet?action=getStatus', {
    headers: { 'X-Requested-With': 'XMLHttpRequest' }
  })
  .then(r => r.ok ? r.json() : null)
  .then(data => {
    if (!data) return;
    const serverOnline = (data.status === 'active');
    if (serverOnline !== isOnline) {
      isOnline = serverOnline;
      /* Use shift state to determine if pill should be locked */
      const st = _shiftState.status;
	  const locked = !serverOnline &&
	                 (st === 'INACTIVE' || st === 'COMPLETED' || st === 'EXPIRED' || st === 'CANCELLED');
					 
      _setAgentOnlinePill(serverOnline, locked);
      if (!serverOnline) {
        showToast(data.reason || 'You have been set Offline.', 'warning');
        if (_walletData) _updateWalletBanner(_walletData);
        else if (typeof loadWalletData === 'function') loadWalletData();
      }
    }
  })
  .catch(() => {});
}
/* ── NOTIFICATION STATE ───────────────────────────────────────────────────── */

let _notifState = {
  items:       [],
  unread:      0,
  filter:      'all',
  loaded:      false,
  loading:     false,
  pollTimer:   null
};

/* ── LOAD FROM SERVER ─────────────────────────────────────────────────────── */

function _notifLoad() {
  if (_notifState.loading) return;
  _notifState.loading = true;

  document.getElementById('notifSkeleton').style.display = '';
  document.getElementById('notifFeed').style.display     = 'none';
  document.getElementById('notifEmpty').style.display    = 'none';

  fetch(CTX + '/DeliveryNotificationServlet?action=list', { credentials: 'same-origin' })
    .then(r => r.json())
    .then(data => {
      _notifState.items   = data.items || [];
      _notifState.unread  = data.unread || 0;
      _notifState.loaded  = true;
      _notifState.loading = false;
      _notifBadge(_notifState.unread);
      _notifRender();
    })
    .catch(() => {
      _notifState.loading = false;
      document.getElementById('notifSkeleton').style.display = 'none';
      document.getElementById('notifEmpty').style.display    = '';
    });
}

function _notifRefresh() { _notifState.loaded = false; _notifLoad(); }

/* ── RENDER ───────────────────────────────────────────────────────────────── */

function _notifRender() {
  const feed     = document.getElementById('notifFeed');
  const empty    = document.getElementById('notifEmpty');
  const skeleton = document.getElementById('notifSkeleton');
  if (!feed) return;

  skeleton.style.display = 'none';

  const f      = _notifState.filter;
  let filtered = _notifState.items.filter(n => {
    if (f === 'unread')   return !n.isRead;
    if (f === 'orders')   return ['ORDER_ASSIGNED','ORDER_DELIVERED','COD_REMINDER'].includes(n.type);
    if (f === 'earnings') return ['EARNINGS_CREDITED','WALLET_LOW','RATING_RECEIVED'].includes(n.type);
    if (f === 'shifts')   return ['SHIFT_STARTING','SHIFT_EXPIRED','SLOT_BOOKED'].includes(n.type);
    return true; // all
  });

  if (filtered.length === 0) {
    feed.style.display  = 'none';
    empty.style.display = '';
    return;
  }

  empty.style.display = 'none';
  feed.style.display  = '';

  // Group by Today / Yesterday / Older
  const now   = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
  const yest  = today - 86400000;

  const groups = { Today: [], Yesterday: [], Older: [] };
  filtered.forEach(n => {
    const d = new Date(n.createdAt.replace(' ','T')).getTime();
    if (d >= today)       groups.Today.push(n);
    else if (d >= yest)   groups.Yesterday.push(n);
    else                  groups.Older.push(n);
  });

  let html = '';
  ['Today','Yesterday','Older'].forEach(label => {
    if (groups[label].length === 0) return;
    html += `<div class="notif-group-label">${label}</div>`;
    groups[label].forEach(n => { html += _notifCard(n); });
  });

  feed.innerHTML = html;
}

function _notifCard(n) {
  const unreadCls = n.isRead ? '' : ' unread';
  const typeBadge = `<span class="notif-type-badge ${n.type}">${_notifTypeLabel(n.type)}</span>`;
  const ago       = _notifTimeAgo(n.createdAt);

  return `
  <div class="ncard${unreadCls}" id="ncard-${n.id}"
       onclick="_notifMarkRead(${n.id})" role="button" tabindex="0"
       onkeydown="if(event.key==='Enter')_notifMarkRead(${n.id})">
    <div class="ncard-ico ${n.color}">${n.icon}</div>
    <div class="ncard-body">
      <div class="ncard-title">${_esc(n.title)}${typeBadge}</div>
      ${n.body ? `<div class="ncard-body-text">${_esc(n.body)}</div>` : ''}
      <div class="ncard-time">
        <i class="bi bi-clock" style="font-size:10px"></i>${ago}
      </div>
    </div>
    <button class="ncard-dismiss" onclick="event.stopPropagation();_notifDismiss(${n.id})"
            title="Dismiss" aria-label="Dismiss notification">×</button>
  </div>`;
}

/* ── FILTER ───────────────────────────────────────────────────────────────── */

function _notifFilter(filter, btn) {
  _notifState.filter = filter;
  document.querySelectorAll('.notif-tab').forEach(t => t.classList.remove('active'));
  if (btn) btn.classList.add('active');
  if (_notifState.loaded) {
    _notifRender();
  } else {
    _notifLoad();
  }
}

/* ── MARK READ ────────────────────────────────────────────────────────────── */

function _notifMarkRead(id) {
  const card = document.getElementById('ncard-' + id);
  const notif = _notifState.items.find(n => n.id === id);
  if (!notif || notif.isRead) return;

  notif.isRead = true;
  _notifState.unread = Math.max(0, _notifState.unread - 1);
  _notifBadge(_notifState.unread);
  if (card) card.classList.remove('unread');

  // Remove the blue dot
  const dot = card ? card.querySelector('::before') : null;

  fetch(CTX + '/DeliveryNotificationServlet', {
    method: 'POST', credentials: 'same-origin',
    body: new URLSearchParams({ action: 'markRead', id })
  }).catch(() => {});
}

function _notifMarkAllRead() {
  _notifState.items.forEach(n => { n.isRead = true; });
  _notifState.unread = 0;
  _notifBadge(0);
  _notifRender();

  fetch(CTX + '/DeliveryNotificationServlet', {
    method: 'POST', credentials: 'same-origin',
    body: new URLSearchParams({ action: 'markAllRead' })
  }).catch(() => {});

  showToast('All notifications marked as read.', 'success');
}

// Keep old function name for backward compat with any existing calls
function markAllRead() { _notifMarkAllRead(); }

/* ── DISMISS ──────────────────────────────────────────────────────────────── */

function _notifDismiss(id) {
  const card = document.getElementById('ncard-' + id);
  const idx  = _notifState.items.findIndex(n => n.id === id);

  if (card) {
    card.style.transition = 'opacity .2s, transform .2s, max-height .3s';
    card.style.opacity    = '0';
    card.style.transform  = 'translateX(60px)';
    card.style.maxHeight  = '0';
    card.style.overflow   = 'hidden';
    card.style.marginBottom = '0';
    setTimeout(() => {
      card.remove();
      const notif = _notifState.items[idx];
      if (notif && !notif.isRead) {
        _notifState.unread = Math.max(0, _notifState.unread - 1);
        _notifBadge(_notifState.unread);
      }
      if (idx > -1) _notifState.items.splice(idx, 1);
    }, 320);
  }

  fetch(CTX + '/DeliveryNotificationServlet', {
    method: 'POST', credentials: 'same-origin',
    body: new URLSearchParams({ action: 'dismiss', id })
  }).catch(() => {});
}

/* ── BADGE ────────────────────────────────────────────────────────────────── */

function _notifBadge(count) {
  var label = count > 99 ? '99+' : (count > 0 ? String(count) : '');
  var show  = count > 0;

  // 1. Topbar bell badge (id="topbarNotifBadge")
  var tb = document.getElementById('topbarNotifBadge');
  if (tb) { tb.textContent = label; tb.style.display = show ? '' : 'none'; }

  // 2. Sidebar bell badge (id="sidebarNotifBadge")
  var sb = document.getElementById('sidebarNotifBadge');
  if (sb) { sb.textContent = label; sb.style.display = show ? '' : 'none'; }

  // 3. Bottom-nav bell badge (id="bnavNotifBadge")
  var bn = document.getElementById('bnavNotifBadge');
  if (bn) { bn.textContent = label; bn.style.display = show ? '' : 'none'; }

  // 4. Legacy notifBadgeCount inside notification page header
  var pg = document.getElementById('notifBadgeCount');
  if (pg) { pg.textContent = label; pg.style.display = show ? '' : 'none'; }
}

/* ── BACKGROUND POLLER ────────────────────────────────────────────────────── */

function _notifStartPoll() {
  if (_notifState.pollTimer) clearInterval(_notifState.pollTimer);
  // Poll unread count every 60s to keep badge fresh across page tabs
  _notifState.pollTimer = setInterval(() => {
    fetch(CTX + '/DeliveryNotificationServlet?action=count', { credentials: 'same-origin' })
      .then(r => r.json())
      .then(d => {
        if (d.unread !== _notifState.unread) {
          _notifState.unread = d.unread;
          _notifBadge(d.unread);
          // If notifications page is visible, reload data too
          const notifPage = document.getElementById('page-notifications');
          if (notifPage && notifPage.classList.contains('active')) {
            _notifState.loaded = false;
            _notifLoad();
          }
        }
      })
      .catch(() => {});
  }, 60000);
}

/* ── HELPERS ──────────────────────────────────────────────────────────────── */

function _notifTypeLabel(type) {
  const map = {
    ORDER_ASSIGNED:       'New Order',
    ORDER_DELIVERED:      'Delivered',
    EARNINGS_CREDITED:    'Earnings',
    SHIFT_STARTING:       'Start Now',
    SHIFT_ACTIVE:         'Online',
    SHIFT_EXPIRED:        'Expired',
    SHIFT_EXPIRY_WARNING: 'Expires Soon',
    SLOT_BOOKED:          'Booked',
    COD_REMINDER:         'COD',
    WALLET_LOW:           'Wallet',
    RATING_RECEIVED:      'Rating',
    SYSTEM:               'System'
  };
  return map[type] || type;
}

function _notifTimeAgo(createdAt) {
  if (!createdAt) return '';
  const ms   = Date.now() - new Date(createdAt.replace(' ','T')).getTime();
  const secs = Math.floor(ms / 1000);
  if (secs < 60)          return 'Just now';
  const mins = Math.floor(secs / 60);
  if (mins < 60)          return mins + ' min ago';
  const hrs = Math.floor(mins / 60);
  if (hrs < 24)           return hrs + ' hr ago';
  const days = Math.floor(hrs / 24);
  if (days === 1)         return 'Yesterday';
  if (days < 7)           return days + ' days ago';
  return new Date(createdAt.replace(' ','T')).toLocaleDateString('en-IN', {day:'numeric',month:'short'});
}

function _esc(s) {
  if (!s) return '';
  return s.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;')
          .replace(/"/g,'&quot;').replace(/'/g,'&#39;');
}


/* -- SESSION KEEPALIVE HEARTBEAT ----------------------------------------
   Ping every 15 min to keep the session alive across a full shift.
   Stops automatically on 401/403 (session gone) or tab close.
------------------------------------------------------------------------- */
let _heartbeatTimer = null;

function _startHeartbeat() {
  if (_heartbeatTimer) return;
  _heartbeatTimer = setInterval(_sendHeartbeat, 15 * 60 * 1000);
  _sendHeartbeat(); // immediate ping on load
}

function _stopHeartbeat() {
  if (_heartbeatTimer) { clearInterval(_heartbeatTimer); _heartbeatTimer = null; }
}

function _sendHeartbeat() {
  fetch(CTX + '/DeliveryPortalServlet?action=ping', {
    method: 'GET', credentials: 'same-origin', cache: 'no-store'
  }).then(r => {
    if (r.status === 401 || r.status === 403) {
      _stopHeartbeat();
      window.location.href = CTX + '/DeliveryLoginServlet';
    }
  }).catch(() => {});
}

// Pause when tab is hidden, resume when visible to save battery
document.addEventListener('visibilitychange', () => {
  if (document.hidden) { _stopHeartbeat(); }
  else { _startHeartbeat(); } // immediately ping on tab restore
});

/* ── BOOT ─────────────────────────────────────────────────────────────────── */

document.addEventListener('DOMContentLoaded', () => {
  _startHeartbeat(); // keep session alive across shift

  // Fetch unread count immediately for badge
  fetch(CTX + '/DeliveryNotificationServlet?action=count', { credentials: 'same-origin' })
    .then(r => r.json())
    .then(d => { _notifState.unread = d.unread || 0; _notifBadge(_notifState.unread); })
    .catch(() => {});

  // Start background poll
  _notifStartPoll();
});