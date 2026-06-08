<%--
  ticketDashboard.jsp — Staff Ticket Resolution Dashboard
  ────────────────────────────────────────────────────────
  Standalone page: served by UserDashboardServlet or directly via
  <a href="ticketDashboard.jsp"> from the nav sidebar.

  Add to userDashboard.jsp sidebar nav:
      <a href="ticketDashboard.jsp">
        <i class="bi bi-ticket-perforated"></i> Tickets
        <span id="nav-ticket-badge" class="badge rounded-pill bg-danger" style="display:none"></span>
      </a>

  Features:
  • Live fetch from GET /StaffAIChatServlet?action=lookupTickets
  • Filter by type: All / Urgent / Chat / COD Refund / Resolved
  • Sort by: Newest / Oldest / Order value
  • Inline resolution panel per ticket — no page reload
  • Sends reply to customer chat session + marks resolved
  • Zero JSTL — pure JSP scriptlet auth only
--%>
<%@ page language="java" contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<%
    Object _roleObj = session != null ? session.getAttribute("role") : null;
    Object _nameObj = session != null ? session.getAttribute("username") : null;
    String _tdRole = (_roleObj instanceof String) ? (String)_roleObj : null;
    String _tdName = (_nameObj instanceof String) ? (String)_nameObj : "Staff";
    if(_tdRole==null||(!_tdRole.equalsIgnoreCase("staff")&&!_tdRole.equalsIgnoreCase("admin"))){
        response.sendRedirect("index.jsp");return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Ticket Queue — SmartStock</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
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
body{font-family:'Outfit',sans-serif;background:var(--bg-off);color:var(--text);min-height:100vh;font-size:14px;padding-top:var(--nav-h);padding-bottom:80px;background-image:radial-gradient(ellipse at 80% 0%,rgba(99,102,241,.06) 0%,transparent 60%);}
.td-wrap{max-width:960px;margin:0 auto;padding:1.5rem 1rem 80px}

/* ── Header ── */
.td-hdr{display:flex;align-items:center;justify-content:space-between;margin-bottom:24px;flex-wrap:wrap;gap:12px}
.td-hdr h1{font-size:20px;font-weight:700;display:flex;align-items:center;gap:10px}
.td-hdr-badge{display:inline-flex;align-items:center;justify-content:center;min-width:24px;height:24px;
  border-radius:12px;padding:0 7px;background:#ef4444;color:#fff;font-size:12px;font-weight:700}
.td-hdr-sub{font-size:13px;color:var(--mu);font-weight:400}
.td-refresh{padding:8px 16px;border-radius:var(--rad-sm);border:1px solid var(--border);background:var(--card);
  color:var(--text-mid);font-size:13px;font-weight:500;cursor:pointer;display:flex;align-items:center;gap:6px;
  font-family:'Outfit',sans-serif;transition:all .15s}
.td-refresh:hover{background:var(--bg-off);border-color:var(--accent);color:var(--accent)}
.td-refresh.spin i{animation:tdSpin .6s linear infinite}
@keyframes tdSpin{to{transform:rotate(360deg)}}

/* ── Stats row ── */
.td-stats{display:grid;grid-template-columns:repeat(auto-fit,minmax(130px,1fr));gap:10px;margin-bottom:20px}
.td-stat{background:var(--card);border:1px solid var(--border);border-radius:var(--radius);padding:14px 16px;box-shadow:var(--shadow);}
.td-stat-label{font-size:11px;font-weight:600;color:var(--text-muted);text-transform:uppercase;letter-spacing:.06em;margin-bottom:4px}
.td-stat-val{font-size:22px;font-weight:700;color:var(--text);letter-spacing:-.5px}
.td-stat-val.red{color:var(--red)}.td-stat-val.amber{color:var(--amber)}.td-stat-val.green{color:var(--green)}

/* ── Filters ── */
.td-filters{display:flex;gap:6px;flex-wrap:wrap;margin-bottom:16px}
.td-filter{padding:6px 14px;border-radius:20px;border:1.5px solid var(--border);background:var(--card);
  color:var(--text-muted);font-size:12.5px;font-weight:500;cursor:pointer;transition:all .15s;white-space:nowrap}
.td-filter:hover{border-color:var(--accent-h);color:var(--accent)}
.td-filter.on{border-color:var(--accent);background:var(--accent-light);color:var(--accent);font-weight:600}
.td-filter.red.on{border-color:var(--red);background:var(--red-bg);color:var(--red)}

/* ── Sort ── */
.td-sort{font-size:12px;color:var(--text-muted);display:flex;align-items:center;gap:6px;margin-bottom:16px}
.td-sort select{border:1px solid var(--border);border-radius:6px;padding:4px 8px;font-size:12px;
  font-family:'Outfit',sans-serif;color:var(--text);background:var(--card);cursor:pointer;outline:none}

/* ── Ticket list ── */
.td-list{display:flex;flex-direction:column;gap:10px}
.td-empty{text-align:center;padding:60px 24px;color:var(--text-muted)}
.td-empty i{font-size:40px;opacity:.3;display:block;margin-bottom:12px}
.td-empty h3{font-size:16px;font-weight:600;color:var(--text-mid);margin-bottom:6px}

/* ── Ticket card ── */
.td-card{background:var(--card);border:1px solid var(--border);border-radius:var(--radius);
  box-shadow:var(--shadow);
  transition:box-shadow .2s;overflow:hidden}
.td-card:hover{box-shadow:var(--shadow-md)}
.td-card.urgent{border-color:#fca5a5;border-left:3px solid var(--red);}
.td-card.resolved-card{opacity:.6}

.td-card-head{display:flex;align-items:flex-start;gap:14px;padding:14px 16px;cursor:pointer;
  user-select:none}
.td-card-head:hover{background:var(--bg-off)}

.td-type-dot{width:10px;height:10px;border-radius:50%;flex-shrink:0;margin-top:5px}
.td-type-dot.urgent{background:var(--re);animation:tdPulse 1.5s infinite}
.td-type-dot.chat{background:var(--accent)}
.td-type-dot.refund{background:var(--amber)}
.td-type-dot.intercept{background:var(--red)}
.td-type-dot.address{background:var(--coral)}
.td-type-dot.general{background:var(--text-muted)}
@keyframes tdPulse{0%,100%{opacity:1}50%{opacity:.3}}

.td-card-meta{flex:1;min-width:0}
.td-card-title{font-size:14px;font-weight:600;color:var(--text);margin-bottom:3px;
  white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.td-card-sub{font-size:12px;color:var(--text-muted);display:flex;align-items:center;gap:8px;flex-wrap:wrap}
.td-card-sub span{display:flex;align-items:center;gap:3px}

.td-card-right{display:flex;flex-direction:column;align-items:flex-end;gap:5px;flex-shrink:0}
.td-badge{padding:2px 9px;border-radius:20px;font-size:10px;font-weight:700;letter-spacing:.02em}
.td-badge.urgent{background:#fee2e2;color:var(--re);border:1px solid #fecaca}
.td-badge.chat{background:var(--accent-light);color:var(--accent);border:1px solid #c7d2fe}
.td-badge.refund{background:var(--amber-bg);color:var(--amber);border:1px solid #fde68a}
.td-badge.intercept{background:var(--coral-bg);color:var(--coral);border:1px solid #fed7aa}
.td-badge.address{background:var(--coral-bg);color:var(--coral);border:1px solid #fed7aa}
.td-badge.general{background:var(--bg-off);color:var(--text-mid);border:1px solid var(--border)}
.td-badge.resolved{background:var(--green-bg);color:var(--green);border:1px solid #6ee7b7}
.td-time{font-size:11px;color:var(--text-muted)}
.td-chevron{font-size:16px;color:var(--text-muted);transition:transform .2s;margin-top:3px}
.td-card.open .td-chevron{transform:rotate(180deg)}

/* ── Expanded body ── */
.td-card-body{border-top:1px solid var(--border);padding:0;max-height:0;overflow:hidden;
  transition:max-height .3s ease}
.td-card.open .td-card-body{max-height:900px}
.td-body-inner{padding:16px}

.td-row{display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:8px;gap:8px}
.td-label{font-size:11px;font-weight:600;color:var(--text-muted);white-space:nowrap;padding-top:1px}
.td-val{font-size:12.5px;font-weight:500;color:var(--text);text-align:right;word-break:break-word;max-width:60%}
.td-divider{height:1px;background:var(--border);margin:12px 0}
.td-section-label{font-size:11px;font-weight:700;color:var(--text-mid);text-transform:uppercase;
  letter-spacing:.06em;margin-bottom:8px}

.td-issue-box{background:var(--accent-light);border:1px solid var(--border);border-radius:8px;
  padding:10px 12px;font-size:13px;color:var(--tx);line-height:1.65;margin-bottom:10px}
.td-action-box{background:#fff5f5;border:1px solid #fecaca;border-radius:8px;
  padding:9px 12px;font-size:12px;color:var(--re);line-height:1.65;margin-bottom:10px}

/* Order expand */
.td-order-toggle{display:flex;align-items:center;gap:6px;cursor:pointer;
  font-size:12px;font-weight:600;color:var(--accent);margin-bottom:10px;user-select:none}
.td-order-toggle:hover{color:var(--accent-h)}
.td-order-detail{background:var(--accent-light);border:1px solid #c7d2fe;border-radius:8px;
  padding:10px 12px;margin-bottom:10px;display:none;font-size:12px}
.td-order-detail.open{display:block}
.td-od-row{display:flex;justify-content:space-between;margin-bottom:5px}
.td-od-label{color:var(--text-muted);font-size:11px}
.td-od-val{font-weight:600;color:var(--text);font-size:12px}

/* Resolution area */
.td-resolve-wrap{background:var(--green-bg);border:1px solid #bbf7d0;border-radius:var(--rad-sm);padding:13px}
.td-resolve-steps{display:flex;flex-direction:column;gap:8px;margin-bottom:12px}
.td-resolve-step{display:flex;align-items:center;gap:9px;font-size:12.5px;color:var(--tx2)}
.td-step-num{width:22px;height:22px;border-radius:50%;display:flex;align-items:center;
  justify-content:center;font-size:10px;font-weight:700;flex-shrink:0}
.td-step-num.blue{background:#dbeafe;color:#1d4ed8;border:1px solid #93c5fd}
.td-step-num.green{background:#dcfce7;color:var(--gr);border:1px solid #86efac}
.td-step-num.amber{background:#fef3c7;color:var(--am);border:1px solid #fde68a}
.td-textarea{width:100%;border:1px solid var(--border);border-radius:8px;padding:9px 12px;
  font-family:'Outfit',sans-serif;font-size:13px;color:var(--tx);resize:vertical;min-height:80px;
  background:#fff;outline:none;margin:8px 0;transition:border-color .2s}
.td-textarea:focus{border-color:var(--accent);box-shadow:0 0 0 3px rgba(99,102,241,.15)}
.td-textarea::placeholder{color:var(--mu2)}
.td-hint{font-size:11px;color:var(--text-muted);margin-bottom:10px}
.td-btn-row{display:flex;gap:8px;flex-wrap:wrap}
.td-btn{padding:9px 18px;border-radius:var(--rad-sm);border:none;cursor:pointer;
  font-size:13px;font-weight:600;font-family:'Outfit',sans-serif;transition:all .15s;
  display:inline-flex;align-items:center;gap:5px}
.td-btn.green{background:linear-gradient(135deg,#059669,#047857);color:#fff}
.td-btn.green:hover{filter:brightness(1.07)}
.td-btn.blue{background:linear-gradient(135deg,var(--primary),var(--accent));color:#fff}
.td-btn.gray{background:var(--bg-off);color:var(--text-mid);border:1px solid var(--border)}
.td-btn.gray:hover{background:#e2e8f0}
.td-btn:disabled{opacity:.45;cursor:not-allowed;filter:none}
.td-btn:active{transform:scale(.97)}

.td-ok{background:var(--green-bg);border:1px solid #6ee7b7;border-radius:8px;
  padding:11px 14px;display:flex;align-items:center;gap:10px;font-size:13px;color:var(--green);font-weight:600}
.td-ok i{font-size:18px}

/* Loading shimmer */
.td-shimmer{background:linear-gradient(90deg,var(--bg-off) 25%,var(--border) 50%,var(--bg-off) 75%);
  background-size:400% 100%;animation:tdShim 1.4s infinite;border-radius:var(--rad);height:80px;
  margin-bottom:10px}
@keyframes tdShim{0%{background-position:100% 0}100%{background-position:-100% 0}}

/* ── NAVBAR ── */
.top-navbar{position:fixed;top:0;left:0;right:0;height:var(--nav-h);z-index:1000;
  background:linear-gradient(135deg,var(--primary) 0%,var(--primary-mid) 100%);
  display:flex;align-items:center;padding:0 1.1rem;gap:.75rem;
  box-shadow:0 2px 20px rgba(67,56,202,.25);}
.nav-brand{font-size:1.05rem;font-weight:800;color:#fff;display:flex;align-items:center;gap:.4rem;white-space:nowrap;letter-spacing:-.3px}
.nav-brand .dot{color:#fbbf24}
.nav-right{margin-left:auto;display:flex;align-items:center;gap:.5rem}
.nav-back{display:flex;align-items:center;gap:.4rem;color:rgba(255,255,255,.8);font-size:.82rem;font-weight:600;
  padding:.35rem .75rem;border-radius:9px;background:rgba(255,255,255,.1);border:1px solid rgba(255,255,255,.18);
  text-decoration:none;transition:all .2s;}
.nav-back:hover{background:rgba(255,255,255,.2);border-color:rgba(255,255,255,.4);color:#fbbf24}
.nav-avatar{width:34px;height:34px;border-radius:50%;background:linear-gradient(135deg,#fbbf24,#f97316);
  display:flex;align-items:center;justify-content:center;font-size:.72rem;font-weight:800;color:#fff;
  border:2px solid rgba(255,255,255,.35);flex-shrink:0;}
</style>
</head>
<body>

<!-- ── NAVBAR ── -->
<nav class="top-navbar">
  <a href="UserDashboardServlet" class="nav-back"><i class="bi bi-arrow-left"></i><span>Dashboard</span></a>
  <div class="nav-brand">Smart<span class="dot">·</span>Tickets</div>
  <div class="nav-right">
    <div class="nav-avatar"><%= _tdName.substring(0, Math.min(2,_tdName.length())).toUpperCase() %></div>
  </div>
</nav>

<div class="td-wrap">

  <!-- Header -->
  <div class="td-hdr">
    <div>
      <h1>
        <i class="bi bi-ticket-perforated" style="color:#4338ca"></i>
        Customer Ticket Queue
        <span class="td-hdr-badge" id="td-total-badge" style="display:none"></span>
      </h1>
      <div class="td-hdr-sub">Welcome, <strong><%= _tdName %></strong> · Tickets requiring your action</div>
    </div>
    <div style="display:flex;gap:8px;align-items:center">
      <button class="td-refresh" id="td-refresh-btn" onclick="loadTickets()">
        <i class="bi bi-arrow-clockwise"></i> Refresh
      </button>

    </div>
  </div>

  <!-- Stats -->
  <div class="td-stats" id="td-stats">
    <div class="td-stat"><div class="td-stat-label">Total Open</div><div class="td-stat-val" id="st-total">—</div></div>
    <div class="td-stat"><div class="td-stat-label">Urgent</div><div class="td-stat-val red" id="st-urgent">—</div></div>
    <div class="td-stat"><div class="td-stat-label">Chat Requests</div><div class="td-stat-val" id="st-chat">—</div></div>
    <div class="td-stat"><div class="td-stat-label">COD Refunds</div><div class="td-stat-val amber" id="st-refund">—</div></div>
  </div>

  <!-- Filters + Sort -->
  <div class="td-filters" id="td-filters">
    <button class="td-filter on" data-filter="all" onclick="applyFilter(this)">All</button>
    <button class="td-filter red" data-filter="urgent" onclick="applyFilter(this)">🔴 Urgent</button>
    <button class="td-filter" data-filter="chat" onclick="applyFilter(this)">💬 Chat Requests</button>
    <button class="td-filter" data-filter="refund" onclick="applyFilter(this)">💳 COD Refunds</button>
  </div>
  <div class="td-sort">
    Sort by:
    <select id="td-sort-sel" onchange="renderTickets()">
      <option value="newest">Newest first</option>
      <option value="oldest">Oldest first</option>
      <option value="value">Highest value</option>
      <option value="urgent">Urgent first</option>
    </select>
  </div>

  <!-- Ticket list -->
  <div class="td-list" id="td-list">
    <div class="td-shimmer"></div>
    <div class="td-shimmer" style="opacity:.7"></div>
    <div class="td-shimmer" style="opacity:.4"></div>
  </div>

</div>

<script>
var ALL_TICKETS = [];
var FILTER = 'all';
var EXPANDED = {};  // ticketId → order detail object

/* ── Load ──────────────────────────────────────────────────────────────── */
function loadTickets() {
  var btn = document.getElementById('td-refresh-btn');
  btn.classList.add('spin');
  fetch('StaffAIChatServlet?action=lookupTickets')
    .then(function(r) { return r.json(); })
    .then(function(d) {
      btn.classList.remove('spin');
      ALL_TICKETS = d.tickets || [];
      updateStats();
      renderTickets();
    })
    .catch(function(e) {
      btn.classList.remove('spin');
      document.getElementById('td-list').innerHTML =
        '<div class="td-empty"><i class="bi bi-exclamation-triangle"></i><h3>Could not load tickets</h3><p>'+e.message+'</p></div>';
    });
}

function isUrgent(t){
  // INTERCEPT_REQUESTED = urgent/high priority tickets (mapped in servlet)
  // ADDRESS_CORRECTION  = legacy token (kept for backward compat)
  return t.paymentStatus==='INTERCEPT_REQUESTED'||t.paymentStatus==='ADDRESS_CORRECTION';
}

function updateStats() {
  var urgent = ALL_TICKETS.filter(function(t){return isUrgent(t);}).length;
  // CHAT_ACTION = ticket linked to a chat session (chatSessionId > 0)
  var chat   = ALL_TICKETS.filter(function(t){
    return t.paymentStatus==='CHAT_ACTION'||t.paymentStatus==='TICKET';
  }).length;
  var refund = ALL_TICKETS.filter(function(t){return t.paymentStatus==='REFUND_PENDING';}).length;
  var total  = ALL_TICKETS.length;

  set('st-total',  total);
  set('st-urgent', urgent);
  set('st-chat',   chat);
  set('st-refund', refund);

  var badge = document.getElementById('td-total-badge');
  if(total > 0){ badge.textContent = total; badge.style.display = 'inline-flex'; }
  else badge.style.display = 'none';
}

/* ── Filter + Sort + Render ────────────────────────────────────────────── */
function applyFilter(btn) {
  document.querySelectorAll('.td-filter').forEach(function(b){b.classList.remove('on')});
  btn.classList.add('on');
  FILTER = btn.dataset.filter;
  renderTickets();
}

function renderTickets() {
  var tickets = ALL_TICKETS.slice();

  // Filter
  if(FILTER !== 'all') {
    tickets = tickets.filter(function(t) {
      if(FILTER==='urgent')  return isUrgent(t);
      if(FILTER==='chat')    return t.paymentStatus==='CHAT_ACTION'||t.paymentStatus==='TICKET';
      if(FILTER==='refund')  return t.paymentStatus==='REFUND_PENDING';
      return true;
    });
  }

  // Sort
  var sort = document.getElementById('td-sort-sel').value;
  tickets.sort(function(a,b){
    if(sort==='oldest')  return ts(a)-ts(b);
    if(sort==='value')   return (b.total||0)-(a.total||0);
    if(sort==='urgent')  return (isUrgent(b)?1:0)-(isUrgent(a)?1:0);
    return ts(b)-ts(a); // newest
  });

  var list = document.getElementById('td-list');
  if(!tickets.length) {
    list.innerHTML = '<div class="td-empty"><i class="bi bi-check-circle"></i><h3>No open tickets</h3><p>All customer issues are resolved.</p></div>';
    return;
  }
  list.innerHTML = '';
  tickets.forEach(function(t){ list.appendChild(buildCard(t)); });
}

/* ── Build individual ticket card ──────────────────────────────────────── */
function buildCard(t) {
  var wrap = document.createElement('div');
  var urg = isUrgent(t);
  wrap.className = 'td-card' + (urg?' urgent':'');
  wrap.id = 'tdcard-'+t.id;

  var typeInfo = typeLabel(t.paymentStatus);
  var ago = timeAgo(t.createdAt);

  wrap.innerHTML =
    '<div class="td-card-head" onclick="toggleCard('+t.id+')">'
      +'<div class="td-type-dot '+typeInfo.dot+'"></div>'
      +'<div class="td-card-meta">'
        +'<div class="td-card-title">'+esc(t.action||t.customerName||'Support Ticket')
          +(t.orderId&&t.orderId>0?' &nbsp;·&nbsp; Order #'+t.orderId:'')+'</div>'
        +'<div class="td-card-sub">'
          +'<span style="font-weight:600;color:#374151">'+esc(t.customerName||'Unknown')+'</span>'
          +'<span><i class="bi bi-telephone" style="font-size:11px"></i>'+esc(t.customerPhone||'No phone')+'</span>'
          +(t.total&&t.total>0?'<span><i class="bi bi-currency-rupee" style="font-size:11px"></i>'+parseFloat(t.total).toFixed(2)+'</span>':'')
          +'<span>Ticket #TKT-'+t.id+'</span>'
        +'</div>'
      +'</div>'
      +'<div class="td-card-right">'
        +'<span class="td-badge '+typeInfo.cls+'">'+typeInfo.label+'</span>'
        +'<span class="td-time">'+ago+'</span>'
      +'</div>'
      +'<i class="bi bi-chevron-down td-chevron"></i>'
    +'</div>'
    +'<div class="td-card-body">'
      +'<div class="td-body-inner" id="tdbody-'+t.id+'">'
        // Customer section
        +'<div class="td-section-label">Customer</div>'
        +'<div class="td-row"><span class="td-label">Name</span><span class="td-val">'+esc(t.customerName||'—')+'</span></div>'
        +'<div class="td-row"><span class="td-label">Phone</span>'
          +'<span class="td-val" style="display:flex;align-items:center;gap:7px">'
            +'<a href="tel:'+esc(t.customerPhone||'')+'" style="color:#1d4ed8;font-weight:600;text-decoration:none"><i class="bi bi-telephone-fill"></i> '+esc(t.customerPhone||'—')+'</a>'
            +(t.customerPhone?'<button onclick="copyPhone(\''+safe(t.customerPhone||'')+'\',this)" style="padding:2px 8px;border-radius:5px;border:1px solid #e2e8f0;background:#f8fafc;font-size:10px;cursor:pointer;font-family:inherit">Copy</button>':'')
          +'</span>'
        +'</div>'
        +(t.customerEmail?'<div class="td-row"><span class="td-label">Email</span><span class="td-val" style="font-size:11.5px">'+esc(t.customerEmail)+'</span></div>':'')
        +(t.orderId?'<div class="td-row"><span class="td-label">Order</span><span class="td-val">#'+t.orderId+'</span></div>':'')
        +(t.total?'<div class="td-row"><span class="td-label">Order value</span><span class="td-val">₹'+parseFloat(t.total).toFixed(2)+'</span></div>':'')

        +'<div class="td-divider"></div>'

        // Issue
        +'<div class="td-section-label">Issue description</div>'
        +'<div class="td-issue-box">'+esc(t.issue||'—')+'</div>'
        +(t.action&&t.action.trim()?
          '<div class="td-section-label">Subject</div>'
          +'<div class="td-action-box" style="background:#f0f7ff;border-color:#bfdbfe;color:#1e40af">'+esc(t.action)+'</div>'
          :'')

        // Order expand
        +(t.orderId?
          '<div class="td-order-toggle" onclick="toggleOrder(this,'+t.orderId+')">'
            +'<i class="bi bi-box-seam"></i> View Order #'+t.orderId+' details'
            +'<i class="bi bi-chevron-right" style="font-size:11px;transition:transform .2s" id="tdo-chev-'+t.orderId+'"></i>'
          +'</div>'
          +'<div class="td-order-detail" id="tdo-'+t.orderId+'">'
            +'<div style="font-size:12px;color:#64748b">Loading order details…</div>'
          +'</div>'
          :'')

        +'<div class="td-divider"></div>'

        // Resolution area
        +'<div id="tdres-'+t.id+'">'
          +'<div class="td-resolve-wrap">'
            +'<div class="td-resolve-steps">'
              +(t.orderId?
                '<div class="td-resolve-step"><span class="td-step-num blue">1</span>Click "View Order" above to review before responding</div>'
                :'')
              +'<div class="td-resolve-step"><span class="td-step-num green">'+(t.orderId?'2':'1')+'</span>Type your resolution message for the customer</div>'
              +'<div class="td-resolve-step"><span class="td-step-num amber">'+(t.orderId?'3':'2')+'</span>Click Send &amp; Resolve — done!</div>'
            +'</div>'
            +'<textarea class="td-textarea" id="tdmsg-'+t.id+'" '
              +'placeholder="e.g. We have investigated your case. Your replacement will be dispatched within 24 hours. You will receive an SMS with the tracking ID."></textarea>'
            +'<div class="td-hint">This message will appear in the customer\'s GreenCart chat widget immediately.</div>'
            +'<div class="td-btn-row">'
              +'<button class="td-btn green" onclick="resolveTicket(this,'+t.id+','+t.orderId+','+t.customerId+',true)">✓ Send &amp; Resolve</button>'
              +'<button class="td-btn gray" onclick="resolveTicket(this,'+t.id+','+t.orderId+','+t.customerId+',false)">Resolve only</button>'
            +'</div>'
          +'</div>'
        +'</div>'

      +'</div>'
    +'</div>';

  return wrap;
}

/* ── Card toggle ── */
function toggleCard(id) {
  var card = document.getElementById('tdcard-'+id);
  card.classList.toggle('open');
}

/* ── Order detail expand ── */
function toggleOrder(btn, orderId) {
  var box = document.getElementById('tdo-'+orderId);
  var chev = document.getElementById('tdo-chev-'+orderId);
  if(box.classList.contains('open')){
    box.classList.remove('open');
    chev.style.transform='';
    return;
  }
  chev.style.transform='rotate(90deg)';
  box.classList.add('open');
  if(EXPANDED[orderId]){renderOrderDetail(box,EXPANDED[orderId]);return;}
  box.innerHTML='<div style="font-size:12px;color:#64748b">Loading…</div>';
  fetch('StaffAIChatServlet?action=lookupOrder&orderId='+orderId)
    .then(function(r){return r.json()})
    .then(function(d){
      if(!d.found){box.innerHTML='<div style="font-size:12px;color:#dc2626">Order not found</div>';return;}
      EXPANDED[orderId]=d.order;
      renderOrderDetail(box,d.order);
    })
    .catch(function(){box.innerHTML='<div style="font-size:12px;color:#dc2626">Could not load order</div>';});
}

function renderOrderDetail(box, o) {
  var rows=[
    ['Status', o.status],
    ['Payment', (o.paymentMethod||'')+ ' — '+(o.paymentStatus||'')],
    ['Address', o.address],
    ['Delivery Agent', o.deliveryAgent],
    ['Order Date', fmtD(o.orderDate)],
    ['Est. Delivery', fmtD(o.deliveryDate)]
  ];
  var html='';
  rows.forEach(function(r){
    if(r[1]){html+='<div class="td-od-row"><span class="td-od-label">'+r[0]+'</span><span class="td-od-val">'+esc(String(r[1]))+'</span></div>';}
  });
  if(o.items&&o.items.length){
    html+='<div class="td-od-row" style="margin-top:6px;padding-top:6px;border-top:1px solid #bfdbfe"><span class="td-od-label" style="font-weight:700">Items</span></div>';
    o.items.slice(0,4).forEach(function(it){
      html+='<div class="td-od-row"><span class="td-od-label">'+esc(it.name)+'</span><span class="td-od-val">×'+it.qty+' — ₹'+parseFloat(it.price||0).toFixed(2)+'</span></div>';
    });
  }
  box.innerHTML=html||'<div style="font-size:12px;color:#64748b">No details available</div>';
}

/* ── Resolve ── */
function resolveTicket(btn, ticketId, orderId, customerId, sendMsg) {
  var msg = sendMsg ? (document.getElementById('tdmsg-'+ticketId)||{}).value||'' : '';
  msg = msg.trim();

  if(sendMsg && !msg){
    alert('Please type a resolution message before sending, or use "Resolve only" to close without a message.');
    return;
  }

  btn.disabled=true;
  var allBtns=btn.parentElement.querySelectorAll('.td-btn');
  allBtns.forEach(function(b){b.disabled=true;});

  var doResolve = function(){
    btn.textContent='Resolving…';
    fetch('StaffAIChatServlet',{method:'POST',body:new URLSearchParams({action:'resolveTicket',ticketId:String(ticketId)})})
      .then(function(r){return r.json()})
      .then(function(d){
        if(!d.success)throw new Error(d.error||'Resolve failed');
        var resArea=document.getElementById('tdres-'+ticketId);
        resArea.innerHTML='<div class="td-ok"><i class="bi bi-check-circle-fill"></i>'
          +'Ticket #T'+ticketId+' resolved'+(msg?' — message sent to customer.':' — no message sent.')+'</div>';
        // Fade the card
        var card=document.getElementById('tdcard-'+ticketId);
        if(card){card.classList.add('resolved-card');}
        // Remove from live list after 3s
        setTimeout(function(){
          ALL_TICKETS=ALL_TICKETS.filter(function(t){return t.id!==ticketId;});
          updateStats();
        },3000);
      })
      .catch(function(e){
        allBtns.forEach(function(b){b.disabled=false;});
        alert('Could not resolve ticket: '+e.message);
      });
  };

  if(sendMsg && msg){
    btn.textContent='Sending…';
    // BUG FIX: must FIRST call TicketQueue?action=reply to persist the message
    // in support_tickets.staff_reply column so helpDesk.jsp can display it.
    // Then call notifyCustomer to push message into customer's chat widget.
    fetch('TicketQueue',{method:'POST',body:new URLSearchParams({
      action:'reply',
      ticketId:String(ticketId),
      message:msg
    })})
      .then(function(r){return r.json()})
      .then(function(d){
        if(!d.ok)throw new Error(d.error||'Reply persist failed');
        // Now push to customer chat session via notifyCustomer
        return fetch('StaffAIChatServlet',{method:'POST',body:new URLSearchParams({
          action:'notifyCustomer',
          ticketId:String(ticketId),
          orderId:String(orderId||0),
          customerId:String(customerId||0),
          message:msg
        })});
      })
      .then(function(r){return r.json()})
      .then(function(d){
        if(!d.success)throw new Error(d.error||'Notify failed');
        doResolve();
      })
      .catch(function(e){
        allBtns.forEach(function(b){b.disabled=false;});
        alert('Could not send message to customer: '+e.message+'\n\nPlease try again or use "Resolve only".');
      });
  } else {
    doResolve();
  }
}

/* ── Copy phone ── */
function copyPhone(phone, btn){
  navigator.clipboard.writeText(phone).then(function(){
    btn.textContent='Copied!';
    setTimeout(function(){btn.textContent='Copy';},1800);
  }).catch(function(){btn.textContent='N/A';});
}

/* ── Helpers ── */
function typeLabel(ps){
  var m={
    'TICKET':        {dot:'general',  cls:'general',   label:'General'},
    'CHAT_ACTION':   {dot:'chat',     cls:'chat',      label:'Chat Request'},
    'INTERCEPT_REQUESTED':{dot:'intercept',cls:'intercept',label:'Courier Intercept'},
    'ADDRESS_CORRECTION': {dot:'address',  cls:'address',   label:'Address Redirect'},
    'REFUND_PENDING':{dot:'refund',   cls:'refund',    label:'COD Refund'}
  };
  return m[ps]||{dot:'general',cls:'general',label:ps||'Ticket'};
}
function timeAgo(iso){
  if(!iso)return '';
  try{
    var d=Date.now()-new Date(iso);
    if(d<3600000)return Math.max(1,Math.floor(d/60000))+'m ago';
    if(d<86400000)return Math.floor(d/3600000)+'h ago';
    return Math.floor(d/86400000)+'d ago';
  }catch(e){return '';}
}
function ts(t){try{return t.createdAt?new Date(t.createdAt).getTime():0;}catch(e){return 0;}}
function fmtD(s){try{if(!s)return '—';var d=new Date(s);return d.toLocaleDateString('en-IN',{day:'numeric',month:'short',year:'numeric'});}catch(e){return s||'—';}}
function esc(s){return(s||'').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');}
function safe(s){return(s||'').replace(/['<>&\s]/g,'');}
function set(id,v){var el=document.getElementById(id);if(el)el.textContent=v;}

/* ── Boot ── */
loadTickets();
// Auto-refresh every 90 seconds
setInterval(function(){
  fetch('StaffAIChatServlet?action=lookupTickets')
    .then(function(r){return r.json()})
    .then(function(d){
      ALL_TICKETS=d.tickets||[];
      updateStats();
      renderTickets();
    }).catch(function(){});
},90000);
</script>
</body>
</html>
