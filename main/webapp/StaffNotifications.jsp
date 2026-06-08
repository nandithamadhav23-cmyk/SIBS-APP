
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true"%>
<%@ page import="com.util.StaffNotification, java.util.*, java.text.SimpleDateFormat" %>

<%
    List<StaffNotification> notifications =
        (List<StaffNotification>) request.getAttribute("notifications");
    if (notifications == null) notifications = new ArrayList<>();

    long unreadCount = request.getAttribute("unreadCount") != null
        ? (Long) request.getAttribute("unreadCount") : 0L;

    SimpleDateFormat sdf = new SimpleDateFormat("dd MMM yyyy, hh:mm a");
%>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>SIBS | Staff Notifications</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
<link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
<style>
  :root {
--primary: #27d2c2;
  --primary-mid: #63b3f9fc;
  --primary-light: #e0e7ff;
  --accent:        #6366f1;
  --accent-h:      #4f46e5;
  --accent-light:  #eef2ff;
  --accent-bg:     #eef2ff;
  --coral:         #f97316;
  --coral-bg:      #fff7ed;
  --success:       #059669;  --success-bg: #d1fae5;
  --green:         #059669;  --green-bg:   #d1fae5;
  --warning:       #d97706;  --warning-bg: #fef3c7;
  --amber:         #d97706;  --amber-bg:   #fef3c7;
  --danger:        #dc2626;  --danger-bg:  #fee2e2;
  --red:           #dc2626;  --red-bg:     #fee2e2;
  --purple:        #7c3aed;  --purple-bg:  #ede9fe;
  --teal:          #0891b2;  --teal-bg:    #cffafe;
  --text:          #1e1b4b;
  --text-m:        #4b5563;
  --text-mid:      #4b5563;
  --text-sm:       #6b7280;
  --text-soft:     #6b7280;
  --text-muted:    #9ca3af;
  --border:        #e0e7ff;
  --bg:            #f8fafc;
  --bg-off:        #f3f4f6;
  --bg-card:       #ffffff;
  --card:          #ffffff;
  --nav-h:         62px;
  --sidebar-w:     264px;
  --r:             14px;
  --r-sm:          9px;
  --radius:        14px;
  --radius-sm:     9px;
  --shadow:        0 1px 4px rgba(67,56,202,.07),0 4px 18px rgba(67,56,202,.08);
  --shadow-sm:     0 1px 4px rgba(67,56,202,.07),0 4px 18px rgba(67,56,202,.08);
  --shadow-md:     0 6px 28px rgba(67,56,202,.14);
  --shadow-card:   0 1px 4px rgba(67,56,202,.07),0 4px 18px rgba(67,56,202,.08);
  --shadow-glow:   0 0 0 3px rgba(99,102,241,.18);
}

  * { box-sizing: border-box; }
  body {
    font-family: 'Outfit', sans-serif;
    background: var(--bg-off);
    color: var(--text);
    margin: 0;
  }

  /* ── TOP BAR ── */
  .topbar {
    background:linear-gradient(135deg,var(--primary) 0%,var(--primary-mid) 100%);color:#fff;padding:0 1.75rem;
    height: 64px;
    display: flex;
    align-items: center;
    justify-content: space-between;
    box-shadow: 0 4px 20px rgba(67,56,202,.25);
    position: sticky;
    top: 0;
    z-index: 100;
  }
  .topbar-brand {
    display: flex; align-items: center; gap: .6rem;
    font-size: 1.15rem; font-weight: 800; letter-spacing: .3px;
  }
  .topbar-brand i { font-size: 1.3rem; }
  .badge-unread {
    background: #fbbf24; color: #1c1917;
    font-size: .78rem; padding: .3em .75em;
    border-radius: 20px; font-weight: 800;
    animation: pulse-badge 2s ease infinite;
  }
  .notif-card.withdrawal { border-left: 3px solid #f59e0b; background: #fffbeb; }
  .pill-withdrawal { background:#fef3c7;color:#92400e;border:1px solid #fcd34d; }
  .pill-coddeposit { background:#d1fae5;color:#065f46;border:1px solid #6ee7b7; }
  @keyframes pulse-badge {
    0%, 100% { transform: scale(1); }
    50% { transform: scale(1.08); }
  }
  .btn-nav {
    display: inline-flex; align-items: center; gap: .4rem;
    font-family: 'Outfit', sans-serif; font-size: .82rem; font-weight: 700;
    padding: .45rem 1.1rem; border-radius: 20px;
    border: 1.5px solid rgba(255,255,255,.35); color: #fff;
    background: rgba(255,255,255,.12); text-decoration: none;
    transition: all .2s;
  }
  .btn-nav:hover { background: rgba(255,255,255,.25); border-color: #fff; color: #fff; }

  /* ── SEARCH PANEL ── */
  .search-panel {
    background: var(--card);
    border-bottom: 1px solid var(--border);
    padding: 1.1rem 1.75rem;
    box-shadow: 0 2px 10px rgba(14,165,233,.06);
  }
  .search-wrap {
    display: flex;
    align-items: center;
    gap: .75rem;
    flex-wrap: wrap;
  }
  .search-box {
    position: relative;
    flex: 1;
    min-width: 240px;
    max-width: 480px;
  }
  .search-box i.search-icon {
    position: absolute; left: 1rem; top: 50%; transform: translateY(-50%);
    color: var(--text-muted); font-size: 1rem; pointer-events: none;
  }
  .search-box input {
    width: 100%;
    padding: .6rem 2.8rem .6rem 2.8rem;
    border: 1.5px solid var(--border);
    border-radius: 30px;
    font-family: 'Outfit', sans-serif;
    font-size: .9rem;
    font-weight: 500;
    color: var(--text);
    background: var(--bg-off);
    outline: none;
    transition: border-color .2s, box-shadow .2s;
  }
  .search-box input:focus {
    border-color: var(--primary);
    box-shadow: 0 0 0 3px rgba(99,102,241,.15);
    background: #fff;
  }
  .search-box input::placeholder { color: #94a3b8; }
  .search-clear {
    position: absolute; right: .8rem; top: 50%; transform: translateY(-50%);
    background: none; border: none; color: #94a3b8; font-size: 1rem;
    cursor: pointer; display: none; padding: 0; line-height: 1;
    transition: color .15s;
  }
  .search-clear:hover { color: var(--accent); }

  /* filter chips */
  .filter-group {
    display: flex; align-items: center; gap: .4rem; flex-wrap: wrap;
  }
  .filter-label {
    font-size: .72rem; font-weight: 700; color: var(--text-muted);
    text-transform: uppercase; letter-spacing: .8px; margin-right: .15rem;
  }
  .chip {
    display: inline-flex; align-items: center; gap: .3rem;
    padding: .38rem .85rem; border-radius: 20px; font-size: .78rem;
    font-weight: 700; border: 1.5px solid var(--border);
    background: var(--bg-off); color: var(--text-muted);
    cursor: pointer; transition: all .18s; user-select: none;
  }
  .chip:hover { border-color: var(--accent); color: var(--accent); background: var(--accent-light); }
  .chip.active { background: var(--accent); border-color: var(--accent); color: #fff; }
  .chip.chip-cod.active { background: #f59e0b; border-color: #f59e0b; color: #fff; }
  .chip.chip-unread.active { background: #8b5cf6; border-color: #8b5cf6; color: #fff; }

  /* search result counter */
  .search-result-info {
    font-size: .78rem; font-weight: 600; color: var(--text-muted);
    white-space: nowrap;
  }
  .search-result-info strong { color: var(--accent); }

  /* ── TOOLBAR ── */
  .toolbar {
    display: flex; align-items: center; justify-content: space-between;
    flex-wrap: wrap; gap: .75rem;
    padding: .9rem 1.75rem;
  }
  .refresh-hint {
    display: flex; align-items: center; gap: .4rem;
    font-size: .78rem; color: var(--text-muted); font-weight: 500;
  }
  .live-dot {
    width: 8px; height: 8px; border-radius: 50%;
    background: #22c55e; position: relative; flex-shrink: 0;
  }
  .live-dot::after {
    content: ''; position: absolute; inset: -3px; border-radius: 50%;
    background: rgba(34,197,94,.35); animation: live-pulse 1.8s ease infinite;
  }
  @keyframes live-pulse {
    0% { opacity:.8; transform:scale(1); }
    70% { opacity:0; transform:scale(1.9); }
    100% { opacity:0; transform:scale(1.9); }
  }
  .toolbar-actions { display: flex; gap: .5rem; flex-wrap: wrap; }

  /* ── REFRESH BAR ── */
  .refresh-bar {
    margin: 1rem;
    height: 3px; background: var(--border);
    overflow: hidden;
  }
  .refresh-bar-inner {
    height: 100%; background: var(--accent); width: 0%;
    transition: width linear;
  }

  /* ── NOTIFICATION CARDS ── */
  .notif-list { padding: 0 1.75rem 2rem; }

  .notif-card {
    background: var(--card);
    border-radius: var(--radius);
    padding: 1.25rem 1.5rem;
    margin-bottom: .85rem;
    box-shadow: var(--shadow-sm);
    border-left: 5px solid #e2e8f0;
    transition: box-shadow .2s, transform .15s;
    position: relative;
  }
  .notif-card:hover { box-shadow: var(--shadow-md); transform: translateY(-1px); }
  .notif-card.unread { border-left-color: var(--accent); background: #eef2ff; }
  .notif-card.cod    { border-left-color: #f59e0b; }
  .notif-card.cod.unread { background: #fffbeb; }

  /* highlight on search match */
  .notif-card.search-match { outline: 2px solid rgba(99,102,241,.35); }
  .notif-card.search-hidden { display: none !important; }

  mark.highlight {
    background: #fef3c7; color: #92400e;
    border-radius: 3px; padding: 0 2px;
    font-weight: 700;
  }

  /* unread dot */
  .unread-dot {
    width: 10px; height: 10px; background: var(--accent);
    border-radius: 50%; display: inline-block; margin-right: .4rem; flex-shrink: 0;
  }
  .notif-card.cod .unread-dot { background: #f59e0b; }

  /* pay pill */
  .pay-pill {
    font-size: .72rem; font-weight: 800;
    padding: .22rem .65rem; border-radius: 20px;
  }
  .pill-cod  { background: #fef3c7; color: #92400e; border: 1px solid #f59e0b; }
  .pill-paid { background: #dcfce7; color: #166534; border: 1px solid #22c55e; }

  /* items block */
  .items-block {
   background: linear-gradient(135deg,var(--primary) 0%,var(--primary-mid) 100%);
    border-radius: 8px;
    padding: .6rem .85rem;
    font-size: .92rem;
    font-family: 'Courier New', monospace;
    white-space: pre-wrap;
    font-weight: 600;
    color:white;
    margin: .5rem 0;
  }

  /* action badge */
  .action-badge {
    font-size: 0.9rem; font-weight: 700;
     border-radius: 20px;
    padding-top: 1rem;
    padding-bottom:0;
    padding-left: 0.3rem;
    padding-right: 0.3rem;
    display: inline-flex; align-items: center; gap: .35rem;
  }
  .action-cod  { background: #fef3c7; color: #92400e; }
  .action-paid { background: #dcfce7; color: #166534; }

  /* timestamp */
  .notif-time { font-size: .72rem; color: var(--text-muted); }

  /* ── EMPTY STATE ── */
  .empty-state {
    text-align: center; padding: 4rem 1rem;
    color: var(--text-muted);
  }
  .empty-state i { font-size: 3.5rem; display: block; margin-bottom: 1rem; color: var(--accent); }

  /* no-results state (search) */
  #noSearchResults {
    display: none;
    text-align: center; padding: 3rem 1rem;
    color: var(--text-muted);
  }
  #noSearchResults i { font-size: 2.5rem; display: block; margin-bottom: .75rem; color: #94a3b8; }

  /* btn overrides */
  .btn { font-family: 'Outfit', sans-serif; font-weight: 700; }
  .btn-sm { font-size: .78rem; }
</style>
</head>
<body>

<!-- ── TOP BAR ── -->
<div class="topbar">
  <a href="UserDashboardServlet" style="display:inline-flex;align-items:center;gap:.4rem;color:rgba(255,255,255,.8);font-size:.82rem;font-weight:600;padding:.35rem .75rem;border-radius:9px;background:rgba(255,255,255,.1);border:1px solid rgba(255,255,255,.18);text-decoration:none;transition:all .2s;margin-right:.5rem;" onmouseover="this.style.background='rgba(255,255,255,.2)'" onmouseout="this.style.background='rgba(255,255,255,.1)'"><i class="bi bi-arrow-left"></i><span>Dashboard</span></a><div class="topbar-brand">
    <i class="bi bi-bell-fill"></i>
    Staff Notifications
    <% if (unreadCount > 0) { %>
      <span class="badge-unread"><%= unreadCount %> unread</span>
    <% } %>
  </div>
  <div class="d-flex align-items-center gap-2">
    <a href="OrdersDashboard" class="btn-nav">
      <i class="bi bi-bag-check"></i> Orders Dashboard
    </a>
  </div>
</div>

<!-- ── SEARCH PANEL ── -->
<div class="search-panel">
  <div class="search-wrap">

    <!-- Search box -->
    <div class="search-box">
      <i class="bi bi-search search-icon"></i>
      <input type="text" id="searchInput"
             placeholder="Search by order #, customer name, email, phone, or items…"
             autocomplete="off">
      <button class="search-clear" id="searchClear" title="Clear search">
        <i class="bi bi-x-circle-fill"></i>
      </button>
    </div>

    <!-- Filter chips -->
    <div class="filter-group">
      <span class="filter-label">Filter:</span>
      <span class="chip active" data-filter="all">
        <i class="bi bi-grid-3x3-gap-fill"></i> All
      </span>
      <span class="chip chip-unread" data-filter="unread">
        <i class="bi bi-circle-fill" style="font-size:.55rem"></i> Unread
      </span>
      <span class="chip chip-cod" data-filter="cod">
        <i class="bi bi-cash-coin"></i> COD
      </span>
      <span class="chip" data-filter="paid">
        <i class="bi bi-check-circle"></i> Paid
      </span>
    </div>

    <!-- Result counter -->
    <div class="search-result-info" id="resultInfo" style="display:none;">
      Showing <strong id="resultCount">0</strong> result(s)
    </div>
  </div>
</div>

<!-- ── TOOLBAR ── -->
<div class="toolbar">
  <div class="refresh-hint">
    <span class="live-dot"></span>
    Auto-refreshes every <strong class="ms-1 me-1">10 s</strong>
    <span id="nextRefresh" class="text-muted"></span>
  </div>
  <div class="toolbar-actions">
    <% if (unreadCount > 0) { %>
    <form action="StaffNotifications" method="post" class="m-0">
      <input type="hidden" name="action" value="markAllRead">
      <button class="btn btn-sm btn-outline-primary">
        <i class="bi bi-check2-all"></i> Mark All Read
      </button>
    </form>
    <% } %>
    <button onclick="location.reload()" class="btn btn-sm btn-outline-secondary">
      <i class="bi bi-arrow-clockwise"></i> Refresh
    </button>
  </div>
</div>

<!-- auto-refresh progress bar -->
<div class="refresh-bar">
  <div class="refresh-bar-inner" id="progressBar"></div>
</div>

<!-- ── NOTIFICATION LIST ── -->
<div class="notif-list" id="notifList">

  <% if (notifications.isEmpty()) { %>
  <div class="empty-state">
    <i class="bi bi-bell-slash"></i>
    <h5>All caught up!</h5>
    <p>No notifications yet. New orders will appear here automatically.</p>
    <a href="OrdersDashboard" class="btn btn-primary mt-2">
      <i class="bi bi-bag-check"></i> Go to Orders
    </a>
  </div>
  <% } %>

  <%
    for (StaffNotification n : notifications) {
       boolean isCod        = n.isCod();
       boolean isWithdrawal = "WITHDRAWAL".equalsIgnoreCase(n.getPaymentMethod());
       boolean isCodDeposit = "COD_DEPOSIT".equalsIgnoreCase(n.getPaymentMethod());
       boolean isSupport    = "SUPPORT".equalsIgnoreCase(n.getPaymentMethod());
       boolean isUnread = !n.isRead();
       String cardClass = (isUnread ? "unread " : "") + (isCod || isCodDeposit ? "cod" : isWithdrawal ? "withdrawal" : "");
  %>
  <div class="notif-card <%= cardClass %>"
       id="notif-<%= n.getId() %>"
       data-order="<%= n.getOrderId() %>"
       data-customer="<%= n.getCustomerName().toLowerCase() %>"
       data-email="<%= n.getCustomerEmail().toLowerCase() %>"
       data-phone="<%= n.getCustomerPhone() %>"
       data-items="<%= n.getItemsSummary().toLowerCase() %>"
       data-type="<%= isCod ? "cod" : "paid" %>"
       data-read="<%= isUnread ? "unread" : "read" %>">

    <!-- Header row -->
    <div class="d-flex align-items-start justify-content-between gap-2 mb-2">
      <div class="d-flex align-items-center gap-2 flex-wrap">
        <% if (isUnread) { %><span class="unread-dot"></span><% } %>
        <strong class="searchable-order"><%= isWithdrawal ? "Withdrawal Req #" : isCodDeposit ? "COD Deposit — Order #" : "Order #" %><%= n.getOrderId() %></strong>
        <span class="pay-pill <%= isCod ? "pill-cod" : isWithdrawal ? "pill-withdrawal" : isCodDeposit ? "pill-coddeposit" : "pill-paid" %>">
          <%= isCod ? "💵 COD" : isWithdrawal ? "💸 Withdrawal" : isCodDeposit ? "💵 COD Deposit" : "✅ Paid" %>
        </span>
        <span class="notif-time">
          <i class="bi bi-clock me-1"></i><%= sdf.format(n.getCreatedAt()) %>
        </span>
      </div>

      <!-- Action buttons -->
      <div class="d-flex gap-1 flex-shrink-0">
        <% if (isUnread) { %>
        <form action="StaffNotifications" method="post" class="m-0">
          <input type="hidden" name="action" value="markRead">
          <input type="hidden" name="id"     value="<%= n.getId() %>">
          <button class="btn btn-sm btn-outline-primary" title="Mark read & view order">
            <i class="bi bi-eye"></i>
          </button>
        </form>
        <% } else { %>
        <a href="OrdersDashboard?action=view&orderId=<%= n.getOrderId() %>"
           class="btn btn-sm btn-outline-secondary" title="View order invoice">
          <i class="bi bi-file-earmark-text"></i>
        </a>
        <% } %>

        <form action="StaffNotifications" method="post" class="m-0">
          <input type="hidden" name="action" value="dismiss">
          <input type="hidden" name="id"     value="<%= n.getId() %>">
          <button class="btn btn-sm btn-outline-warning" title="Dismiss">
            <i class="bi bi-x-lg"></i>
          </button>
        </form>

        <form action="StaffNotifications" method="post" class="m-0"
              onsubmit="return confirm('Delete this notification permanently?')">
          <input type="hidden" name="action" value="delete">
          <input type="hidden" name="id"     value="<%= n.getId() %>">
          <button class="btn btn-sm btn-outline-danger" title="Delete permanently">
            <i class="bi bi-trash3"></i>
          </button>
        </form>
      </div>
    </div>

    <!-- Customer info -->
    <div class="row g-2 mb-2 small">
      <div class="col-sm-4">
        <i class="bi bi-person-fill text-secondary me-1"></i>
        <strong class="searchable-name"><%= n.getCustomerName() %></strong>
      </div>
      <div class="col-sm-4">
        <i class="bi bi-envelope-fill text-secondary me-1"></i>
        <span class="searchable-email"><%= n.getCustomerEmail() %></span>
      </div>
      <div class="col-sm-4">
        <i class="bi bi-telephone-fill text-secondary me-1"></i>
        <span class="searchable-phone"><%= n.getCustomerPhone() %></span>
      </div>
    </div>

    <!-- Items summary -->
    <div class="items-block searchable-items">  <span class="action-badge <%= isCod ? "action-cod" : "action-paid" %>">
        <i class="bi bi-<%= isCod ? "truck" : "box-seam" %>"></i> <%= n.getActionRequired() %>
      </span> <hr> <%= n.getItemsSummary() %></div>

    <!-- Grand total + action required -->
    <div class="d-flex align-items-center justify-content-between flex-wrap gap-2 mt-2">
      <div class="fw-bold fs-6">
        Grand Total: ₹<%= String.format("%.2f", n.getGrandTotal()) %>
      </div>
    
    </div>

  </div><!-- /notif-card -->
  <% } %>

  <!-- No search results placeholder -->
  <div id="noSearchResults">
    <i class="bi bi-search"></i>
    <h6>No notifications match your search</h6>
    <p class="small">Try a different keyword or clear the filters.</p>
    <button class="btn btn-sm btn-outline-primary" onclick="clearSearch()">
      <i class="bi bi-x-circle"></i> Clear Search
    </button>
  </div>

</div><!-- /notif-list -->

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
<script>
// ── Auto-refresh every 10 seconds ──────────────────────────────────────────
const INTERVAL_MS = 100000;
const bar = document.getElementById('progressBar');
const nextRefreshEl = document.getElementById('nextRefresh');
let elapsed = 0;
const TICK = 1000;

const timer = setInterval(() => {
    elapsed += TICK;
    const pct = (elapsed / INTERVAL_MS) * 100;
    bar.style.width = pct + '%';
    const remaining = Math.ceil((INTERVAL_MS - elapsed) / 1000);
    if (nextRefreshEl) nextRefreshEl.textContent = '(next in ' + remaining + 's)';
    if (elapsed >= INTERVAL_MS) {
        clearInterval(timer);
        location.reload();
    }
}, TICK);

// ── Live unread count polling ───────────────────────────────────────────────
function pollBadge() {
    fetch('StaffNotifications?count=true')
        .then(r => r.text())
        .then(count => {
            const n = parseInt(count, 10);
            document.title = n > 0
                ? '(' + n + ') SIBS | Staff Notifications'
                : 'SIBS | Staff Notifications';
        })
        .catch(() => {});
}
setInterval(pollBadge, 5000);
pollBadge();

// ── Search & Filter Logic ───────────────────────────────────────────────────
const searchInput  = document.getElementById('searchInput');
const searchClear  = document.getElementById('searchClear');
const resultInfo   = document.getElementById('resultInfo');
const resultCount  = document.getElementById('resultCount');
const noResults    = document.getElementById('noSearchResults');
const chips        = document.querySelectorAll('.chip[data-filter]');
const cards        = document.querySelectorAll('.notif-card');

let activeFilter = 'all';
let searchQuery  = '';

function normalise(str) {
    return str.toLowerCase().trim();
}

function escapeRegex(str) {
    return str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function highlightText(el, query) {
    // reset inner text first (remove previous marks)
    el.querySelectorAll('mark.highlight').forEach(m => {
        const parent = m.parentNode;
        parent.replaceChild(document.createTextNode(m.textContent), m);
        parent.normalize();
    });

    if (!query) return;

    const walker = document.createTreeWalker(el, NodeFilter.SHOW_TEXT, null, false);
    const regex = new RegExp('(' + escapeRegex(query) + ')', 'gi');
    const nodes = [];
    let node;
    while ((node = walker.nextNode())) nodes.push(node);

    nodes.forEach(textNode => {
        if (!regex.test(textNode.nodeValue)) return;
        regex.lastIndex = 0;
        const frag = document.createDocumentFragment();
        let lastIndex = 0;
        let match;
        while ((match = regex.exec(textNode.nodeValue)) !== null) {
            if (match.index > lastIndex) {
                frag.appendChild(document.createTextNode(textNode.nodeValue.slice(lastIndex, match.index)));
            }
            const mark = document.createElement('mark');
            mark.className = 'highlight';
            mark.textContent = match[0];
            frag.appendChild(mark);
            lastIndex = regex.lastIndex;
        }
        if (lastIndex < textNode.nodeValue.length) {
            frag.appendChild(document.createTextNode(textNode.nodeValue.slice(lastIndex)));
        }
        textNode.parentNode.replaceChild(frag, textNode);
    });
}

function applySearch() {
    const q = normalise(searchInput.value);
    searchQuery = q;

    // show/hide clear button
    searchClear.style.display = q ? 'block' : 'none';

    let visible = 0;

    cards.forEach(card => {
        const type   = card.dataset.type;   // 'cod' | 'paid'
        const read   = card.dataset.read;   // 'unread' | 'read'
        const order  = card.dataset.order;
        const cust   = card.dataset.customer;
        const email  = card.dataset.email;
        const phone  = card.dataset.phone;
        const items  = card.dataset.items;

        // Filter match
        let filterMatch = false;
        if (activeFilter === 'all')    filterMatch = true;
        else if (activeFilter === 'unread') filterMatch = (read === 'unread');
        else if (activeFilter === 'cod')    filterMatch = (type === 'cod');
        else if (activeFilter === 'paid')   filterMatch = (type === 'paid');

        // Search match
        let searchMatch = true;
        if (q) {
            searchMatch = order.includes(q) || cust.includes(q) ||
                          email.includes(q) || phone.includes(q) || items.includes(q);
        }

        const show = filterMatch && searchMatch;
        card.classList.toggle('search-hidden', !show);

        if (show) {
            visible++;
            // highlight only visible cards
            const searchableEls = card.querySelectorAll(
                '.searchable-order, .searchable-name, .searchable-email, .searchable-phone, .searchable-items'
            );
            searchableEls.forEach(el => highlightText(el, q));
        } else {
            // remove highlights from hidden cards
            card.querySelectorAll('mark.highlight').forEach(m => {
                m.parentNode.replaceChild(document.createTextNode(m.textContent), m);
                m.parentNode.normalize();
            });
        }
    });

    // Show result info only when searching or filtering
    const isFiltering = (activeFilter !== 'all') || q;
    resultInfo.style.display = isFiltering ? 'flex' : 'none';
    resultCount.textContent = visible;
    noResults.style.display = (visible === 0 && cards.length > 0) ? 'block' : 'none';
}

function clearSearch() {
    searchInput.value = '';
    applySearch();
    searchInput.focus();
}

// chip click
chips.forEach(chip => {
    chip.addEventListener('click', () => {
        chips.forEach(c => c.classList.remove('active'));
        chip.classList.add('active');
        activeFilter = chip.dataset.filter;
        applySearch();
    });
});

// search input
searchInput.addEventListener('input', () => applySearch());
searchClear.addEventListener('click', () => clearSearch());

// keyboard shortcut: Ctrl/Cmd + K to focus search
document.addEventListener('keydown', e => {
    if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
        e.preventDefault();
        searchInput.focus();
        searchInput.select();
    }
    if (e.key === 'Escape' && document.activeElement === searchInput) {
        clearSearch();
        searchInput.blur();
    }
});
</script>
</body>
</html>
