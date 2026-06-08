<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.*, com.util.AdminNotification, java.text.SimpleDateFormat" %>

<%
    List<AdminNotification> notifications = (List<AdminNotification>) request.getAttribute("notifications");
    if (notifications == null) notifications = new ArrayList<>();
    int unreadCount = request.getAttribute("unreadCount") != null
        ? (Integer) request.getAttribute("unreadCount") : notifications.size();

    SimpleDateFormat sdf = new SimpleDateFormat("dd MMM yyyy, hh:mm a");

    // counts by type
    long lowStockCount  = notifications.stream().filter(n -> "LOW_STOCK".equals(n.getEventType())).count();
    long newOrderCount  = notifications.stream().filter(n -> "NEW_ORDER".equals(n.getEventType())).count();
    long systemCount    = notifications.stream().filter(n -> "SYSTEM_ALERT".equals(n.getEventType())).count();
%>

<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Admin Notifications — SIBS</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
  <link href="https://fonts.googleapis.com/css2?family=Nunito:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">

  <style>
    /* ── Design tokens (mirrors dashboard.jsp) ── */
    :root {
      --primary:       #0ea5e9;
      --primary-dark:  #0369a1;
      --primary-light: #e0f2fe;
      --accent:        #38bdf8;
      --accent-light:  #f0f9ff;
      --text-dark:     #0c1a2e;
      --text-mid:      #1e3a5f;
      --text-muted:    #64748b;
      --border:        #dbeafe;
      --bg-white:      #ffffff;
      --bg-off:        #f0f9ff;
      --navbar-bg:     #0ea5e9;
      --navbar-height: 64px;
      --sidebar-width: 250px;
      --shadow-sm:     0 2px 12px rgba(14,165,233,.08);
      --shadow-md:     0 4px 24px rgba(14,165,233,.13);
      --radius:        10px;
    }

    * { box-sizing: border-box; }
    body {
      font-family: 'Nunito', sans-serif;
      background: var(--bg-off);
      color: var(--text-dark);
      margin: 0;
      padding-top: var(--navbar-height);
      min-height: 100vh;
    }

    /* ── NAVBAR (matches dashboard) ── */
    .top-navbar {
      position: fixed; top: 0; left: 0; right: 0;
      height: var(--navbar-height);
      background: var(--navbar-bg);
      box-shadow: 0 2px 16px rgba(14,165,233,.25);
      display: flex; align-items: center;
      padding: 0 1.5rem; z-index: 1050; gap: 1rem;
    }
    .nav-brand {
      font-size: 1.2rem; font-weight: 800; color: #fff;
      letter-spacing: .5px; text-decoration: none; white-space: nowrap;
    }
    .nav-brand span { color: #bae6fd; font-weight: 300; }
    .nav-right { margin-left: auto; display: flex; align-items: center; gap: 1rem; }
    .btn-nav-back {
      display: inline-flex; align-items: center; gap: .4rem;
      font-size: .82rem; font-weight: 700; padding: .4rem 1.1rem;
      border-radius: 20px; border: 1.5px solid rgba(255,255,255,.35);
      color: #fff; text-decoration: none; background: rgba(255,255,255,.12);
      transition: all .2s;
    }
    .btn-nav-back:hover { background: rgba(255,255,255,.25); border-color: #fff; color: #fff; }
    .badge-role {
      background: rgba(255,255,255,.18); color: #fff;
      border: 1px solid rgba(255,255,255,.35);
      font-size: .68rem; letter-spacing: 1px; text-transform: uppercase;
      padding: .2rem .65rem; border-radius: 20px; font-weight: 600;
    }
    .bell-indicator {
      display: inline-flex; align-items: center; justify-content: center;
      width: 36px; height: 36px; border-radius: 50%;
      background: rgba(255,255,255,.15); border: 1px solid rgba(255,255,255,.25);
      color: #fff; font-size: 1rem; position: relative;
    }
    .bell-badge {
      position: absolute; top: -3px; right: -3px;
      background: #ef4444; color: #fff; font-size: .55rem; font-weight: 700;
      min-width: 16px; height: 16px; border-radius: 50%;
      display: flex; align-items: center; justify-content: center;
      border: 2px solid var(--navbar-bg);
    }

    /* ── PAGE WRAPPER ── */
    .page-wrapper { max-width: 960px; margin: 0 auto; padding: 2rem 1.5rem; }

    /* ── PAGE HEADER ── */
    .page-header {
      display: flex; align-items: flex-start; justify-content: space-between;
      flex-wrap: wrap; gap: 1rem; margin-bottom: 1.75rem;
    }
    .page-title {
      font-size: 1.6rem; font-weight: 800; color: var(--text-dark); margin: 0;
      display: flex; align-items: center; gap: .5rem;
    }
    .page-title i { color: var(--primary); }
    .page-subtitle { font-size: .85rem; color: var(--text-muted); font-weight: 500; margin-top: .2rem; }

    /* ── STAT STRIP ── */
    .stat-strip {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
      gap: .85rem;
      margin-bottom: 1.75rem;
    }
    .stat-card {
      background: var(--bg-white);
      border: 1px solid var(--border);
      border-top: 3px solid transparent;
      border-radius: var(--radius);
      padding: 1rem 1.1rem;
      box-shadow: var(--shadow-sm);
      cursor: pointer;
      transition: all .2s;
      text-align: center;
    }
    .stat-card:hover { transform: translateY(-2px); box-shadow: var(--shadow-md); }
    .stat-card.active { border-top-color: var(--primary); background: var(--primary-light); }
    .stat-card.stat-low-stock   { border-top-color: #f59e0b; }
    .stat-card.stat-low-stock.active { background: #fef3c7; }
    .stat-card.stat-new-order   { border-top-color: #22c55e; }
    .stat-card.stat-new-order.active { background: #dcfce7; }
    .stat-card.stat-system      { border-top-color: #8b5cf6; }
    .stat-card.stat-system.active { background: #ede9fe; }
    .stat-card.stat-all.active  { border-top-color: var(--primary); }
    .stat-num {
      font-size: 1.75rem; font-weight: 800; line-height: 1;
      margin-bottom: .25rem;
    }
    .stat-card.stat-all .stat-num   { color: var(--primary); }
    .stat-card.stat-low-stock .stat-num { color: #d97706; }
    .stat-card.stat-new-order .stat-num { color: #16a34a; }
    .stat-card.stat-system .stat-num    { color: #7c3aed; }
    .stat-label {
      font-size: .7rem; font-weight: 700; color: var(--text-muted);
      text-transform: uppercase; letter-spacing: .8px;
    }
    .stat-icon {
      font-size: 1.3rem; display: block; margin-bottom: .4rem;
    }
    .stat-card.stat-all .stat-icon       { color: var(--primary); }
    .stat-card.stat-low-stock .stat-icon { color: #d97706; }
    .stat-card.stat-new-order .stat-icon { color: #16a34a; }
    .stat-card.stat-system .stat-icon    { color: #7c3aed; }

    /* ── TOOLBAR ── */
    .notif-toolbar {
      background: var(--bg-white);
      border: 1px solid var(--border);
      border-radius: var(--radius);
      padding: .85rem 1.25rem;
      display: flex; align-items: center; justify-content: space-between;
      flex-wrap: wrap; gap: .75rem;
      margin-bottom: 1.1rem;
      box-shadow: var(--shadow-sm);
    }
    .filter-chips { display: flex; gap: .4rem; flex-wrap: wrap; }
    .chip {
      display: inline-flex; align-items: center; gap: .3rem;
      padding: .35rem .85rem; border-radius: 20px; font-size: .78rem;
      font-weight: 700; border: 1.5px solid var(--border);
      background: var(--bg-off); color: var(--text-muted);
      cursor: pointer; transition: all .18s; user-select: none;
    }
    .chip:hover { border-color: var(--primary); color: var(--primary); background: var(--primary-light); }
    .chip.active { background: var(--primary); border-color: var(--primary); color: #fff; }
    .chip.chip-low.active  { background: #d97706; border-color: #d97706; }
    .chip.chip-order.active { background: #16a34a; border-color: #16a34a; }
    .chip.chip-sys.active  { background: #7c3aed; border-color: #7c3aed; }
    .visible-count {
      font-size: .78rem; color: var(--text-muted); font-weight: 600;
    }
    .visible-count strong { color: var(--primary); }

    /* ── NOTIFICATION CARDS ── */
    .notif-card {
      background: var(--bg-white);
      border: 1px solid var(--border);
      border-left: 5px solid #e2e8f0;
      border-radius: var(--radius);
      padding: 1.2rem 1.4rem;
      margin-bottom: .8rem;
      box-shadow: var(--shadow-sm);
      transition: box-shadow .2s, transform .15s;
      position: relative;
    }
    .notif-card:hover { box-shadow: var(--shadow-md); transform: translateY(-1px); }
    .notif-card.unread { border-left-color: var(--primary); background: var(--accent-light); }
    .notif-card.type-LOW_STOCK.unread   { border-left-color: #f59e0b; background: #fffbeb; }
    .notif-card.type-NEW_ORDER.unread   { border-left-color: #22c55e; background: #f0fdf4; }
    .notif-card.type-SYSTEM_ALERT.unread { border-left-color: #8b5cf6; background: #faf5ff; }
    .notif-card.type-LOW_STOCK   { border-left-color: #f59e0b; }
    .notif-card.type-NEW_ORDER   { border-left-color: #22c55e; }
    .notif-card.type-SYSTEM_ALERT { border-left-color: #8b5cf6; }
    .notif-card.hidden-card { display: none !important; }

    /* unread dot */
    .unread-dot {
      width: 9px; height: 9px; border-radius: 50%;
      display: inline-block; flex-shrink: 0;
      background: var(--primary);
    }
    .type-LOW_STOCK   .unread-dot { background: #f59e0b; }
    .type-NEW_ORDER   .unread-dot { background: #22c55e; }
    .type-SYSTEM_ALERT .unread-dot { background: #8b5cf6; }

    /* event-type pill */
    .event-pill {
      font-size: .7rem; font-weight: 800; padding: .22rem .7rem;
      border-radius: 20px; display: inline-flex; align-items: center; gap: .3rem;
      text-transform: uppercase; letter-spacing: .5px;
    }
    .pill-LOW_STOCK   { background: #fef3c7; color: #92400e; border: 1px solid #f59e0b; }
    .pill-NEW_ORDER   { background: #dcfce7; color: #166534; border: 1px solid #22c55e; }
    .pill-SYSTEM_ALERT { background: #ede9fe; color: #5b21b6; border: 1px solid #8b5cf6; }

    .notif-title { font-size: .95rem; font-weight: 800; color: var(--text-dark); }
    .notif-message { font-size: .87rem; color: var(--text-mid); margin: .35rem 0; }
    .notif-entity {
      display: inline-flex; align-items: center; gap: .3rem;
      font-size: .78rem; font-weight: 600; color: var(--text-muted);
      background: var(--bg-off); border: 1px solid var(--border);
      border-radius: 6px; padding: .15rem .55rem;
    }
    .notif-time { font-size: .72rem; color: var(--text-muted); }

    .btn-mark-read {
      display: inline-flex; align-items: center; gap: .3rem;
      font-size: .78rem; font-weight: 700; padding: .3rem .85rem;
      border-radius: 20px; border: 1.5px solid var(--border);
      background: var(--bg-off); color: var(--text-muted);
      cursor: pointer; transition: all .18s; white-space: nowrap;
    }
    .btn-mark-read:hover {
      background: var(--primary-light); border-color: var(--primary);
      color: var(--primary);
    }

    /* ── EMPTY STATE ── */
    .empty-state {
      text-align: center; padding: 4.5rem 1rem; color: var(--text-muted);
    }
    .empty-icon {
      width: 80px; height: 80px; border-radius: 50%;
      background: var(--primary-light); color: var(--primary);
      display: flex; align-items: center; justify-content: center;
      font-size: 2rem; margin: 0 auto 1.25rem;
    }
    .empty-state h5 { font-weight: 800; color: var(--text-dark); margin-bottom: .4rem; }

    /* ── READ notification dim ── */
    .notif-card:not(.unread) { opacity: .82; }
    .notif-card:not(.unread):hover { opacity: 1; }

    /* ── MARK ALL READ banner ── */
    .mark-all-bar {
      background: var(--primary-light);
      border: 1px solid var(--border);
      border-radius: var(--radius);
      padding: .65rem 1.25rem;
      display: flex; align-items: center; justify-content: space-between;
      margin-bottom: 1rem; gap: .75rem; flex-wrap: wrap;
    }
    .mark-all-bar span { font-size: .85rem; font-weight: 600; color: var(--primary-dark); }

    .btn { font-family: 'Nunito', sans-serif; font-weight: 700; }

    /* footer */
    .page-footer {
      text-align: center; padding: 1.5rem;
      font-size: .78rem; color: var(--text-muted); font-weight: 500;
    }
  </style>
</head>
<body>

<!-- ── NAVBAR ── -->
<nav class="top-navbar">
  <a href="dashboard" class="nav-brand">SIBS <span>Admin</span></a>
  <div class="nav-right">
    <span class="badge-role">Admin</span>
    <div class="bell-indicator">
      <i class="bi bi-bell-fill"></i>
      <% if (unreadCount > 0) { %>
        <span class="bell-badge"><%= unreadCount %></span>
      <% } %>
    </div>
    <a href="dashboard" class="btn-nav-back">
      <i class="bi bi-arrow-left"></i> Dashboard
    </a>
  </div>
</nav>

<!-- ── PAGE CONTENT ── -->
<div class="page-wrapper">

  <!-- Page header -->
  <div class="page-header">
    <div>
      <h1 class="page-title">
        <i class="bi bi-bell-fill"></i> Admin Notifications
      </h1>
      <p class="page-subtitle">
        System alerts, low-stock warnings, and new order notifications
      </p>
    </div>
    <% if (unreadCount > 0) { %>
    <span class="badge bg-danger fs-6 px-3 py-2 rounded-pill align-self-start">
      <%= unreadCount %> Unread
    </span>
    <% } %>
  </div>

  <!-- Stat strip -->
  <div class="stat-strip">
    <div class="stat-card stat-all active" data-filter="all" onclick="setFilter('all', this)">
      <i class="bi bi-grid-3x3-gap-fill stat-icon"></i>
      <div class="stat-num"><%= notifications.size() %></div>
      <div class="stat-label">Total</div>
    </div>
    <div class="stat-card stat-low-stock" data-filter="LOW_STOCK" onclick="setFilter('LOW_STOCK', this)">
      <i class="bi bi-exclamation-triangle-fill stat-icon"></i>
      <div class="stat-num"><%= lowStockCount %></div>
      <div class="stat-label">Low Stock</div>
    </div>
    <div class="stat-card stat-new-order" data-filter="NEW_ORDER" onclick="setFilter('NEW_ORDER', this)">
      <i class="bi bi-bag-plus-fill stat-icon"></i>
      <div class="stat-num"><%= newOrderCount %></div>
      <div class="stat-label">New Orders</div>
    </div>
    <div class="stat-card stat-system" data-filter="SYSTEM_ALERT" onclick="setFilter('SYSTEM_ALERT', this)">
      <i class="bi bi-shield-exclamation stat-icon"></i>
      <div class="stat-num"><%= systemCount %></div>
      <div class="stat-label">System Alerts</div>
    </div>
  </div>

  <!-- Mark all read banner -->
  <% if (unreadCount > 0) { %>
  <div class="mark-all-bar">
    <span><i class="bi bi-info-circle me-1"></i> You have <strong><%= unreadCount %></strong> unread notification<%= unreadCount != 1 ? "s" : "" %>.</span>
    <a href="AdminNotificationServlet?action=markAllRead" class="btn btn-sm btn-primary">
      <i class="bi bi-check2-all"></i> Mark All as Read
    </a>
  </div>
  <% } %>

  <!-- Toolbar -->
  <div class="notif-toolbar">
    <div class="filter-chips">
      <span class="chip active" data-filter="all" onclick="setChipFilter('all', this)">
        <i class="bi bi-funnel-fill"></i> All
      </span>
      <span class="chip chip-low" data-filter="LOW_STOCK" onclick="setChipFilter('LOW_STOCK', this)">
        <i class="bi bi-exclamation-triangle"></i> Low Stock
      </span>
      <span class="chip chip-order" data-filter="NEW_ORDER" onclick="setChipFilter('NEW_ORDER', this)">
        <i class="bi bi-bag-plus"></i> New Orders
      </span>
      <span class="chip chip-sys" data-filter="SYSTEM_ALERT" onclick="setChipFilter('SYSTEM_ALERT', this)">
        <i class="bi bi-shield-exclamation"></i> System
      </span>
      <span class="chip chip-unread" id="chipUnread" onclick="toggleUnreadOnly(this)">
        <i class="bi bi-circle-fill" style="font-size:.5rem"></i> Unread only
      </span>
    </div>
    <div class="visible-count">
      Showing <strong id="visibleCount"><%= notifications.size() %></strong> notification<%= notifications.size() != 1 ? "s" : "" %>
    </div>
  </div>

  <!-- Notification cards -->
  <% if (notifications.isEmpty()) { %>
  <div class="empty-state">
    <div class="empty-icon"><i class="bi bi-bell-slash"></i></div>
    <h5>No Notifications</h5>
    <p>You're all clear! No system alerts at this time.</p>
    <a href="dashboard" class="btn btn-primary mt-1">
      <i class="bi bi-house"></i> Back to Dashboard
    </a>
  </div>
  <% } else {
      for (AdminNotification n : notifications) {
          String evt    = n.getEventType() != null ? n.getEventType() : "SYSTEM_ALERT";
          boolean unread = !n.isRead();
          String cardCls = "notif-card type-" + evt + (unread ? " unread" : "");

          String pillIcon = "LOW_STOCK".equals(evt)    ? "bi-exclamation-triangle-fill" :
                            "NEW_ORDER".equals(evt)    ? "bi-bag-plus-fill"             :
                                                         "bi-shield-exclamation";
          String pillLabel = "LOW_STOCK".equals(evt) ? "Low Stock" :
                             "NEW_ORDER".equals(evt) ? "New Order"  : "System Alert";
  %>
  <div class="<%= cardCls %>" data-type="<%= evt %>" data-read="<%= unread ? "unread" : "read" %>">
    <div class="d-flex align-items-start justify-content-between gap-2 mb-2">
      <!-- Left: type pill + title -->
      <div class="d-flex align-items-start gap-2 flex-wrap">
        <% if (unread) { %><span class="unread-dot mt-1 flex-shrink-0"></span><% } %>
        <div>
          <div class="d-flex align-items-center gap-2 flex-wrap mb-1">
            <span class="event-pill pill-<%= evt %>">
              <i class="bi <%= pillIcon %>"></i> <%= pillLabel %>
            </span>
            <span class="notif-time">
              <i class="bi bi-clock me-1"></i><%= sdf.format(n.getCreatedAt()) %>
            </span>
          </div>
          <div class="notif-title"><%= n.getTitle() %></div>
          <div class="notif-message"><%= n.getMessage() %></div>
          <% if (n.getRelatedEntity() != null && !n.getRelatedEntity().isEmpty()) { %>
          <span class="notif-entity">
            <i class="bi bi-link-45deg"></i><%= n.getRelatedEntity() %>
          </span>
          <% } %>
        </div>
      </div>

      <!-- Right: action -->
      <% if (unread) { %>
      <form action="MarkNotificationReadServlet" method="post" class="m-0 flex-shrink-0">
        <input type="hidden" name="id" value="<%= n.getId() %>">
        <button type="submit" class="btn-mark-read">
          <i class="bi bi-check-circle"></i> Mark Read
        </button>
      </form>
      <% } else { %>
      <span style="font-size:.72rem; color:var(--text-muted); font-weight:600; white-space:nowrap;">
        <i class="bi bi-check-circle-fill text-success me-1"></i>Read
      </span>
      <% } %>
    </div>
  </div>
  <%
      }
  } %>

  <div class="page-footer">
    SIBS &mdash; Smart Inventory & Billing System &nbsp;|&nbsp;
    Admin Notifications &nbsp;&bull;&nbsp; Auto-managed alerts
  </div>
</div><!-- /page-wrapper -->

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
<script>
  const cards    = document.querySelectorAll('.notif-card');
  const statCards = document.querySelectorAll('.stat-card');
  const chips    = document.querySelectorAll('.filter-chips .chip[data-filter]');
  const countEl  = document.getElementById('visibleCount');
  const chipUnread = document.getElementById('chipUnread');

  let activeType    = 'all';
  let unreadOnly    = false;

  function updateCount() {
    const visible = [...cards].filter(c => !c.classList.contains('hidden-card')).length;
    countEl.textContent = visible;
  }

  function applyFilters() {
    cards.forEach(card => {
      const type   = card.dataset.type;
      const isRead = card.dataset.read === 'read';

      const typeMatch   = (activeType === 'all') || (type === activeType);
      const unreadMatch = !unreadOnly || !isRead;
      card.classList.toggle('hidden-card', !(typeMatch && unreadMatch));
    });
    updateCount();
  }

  function setFilter(type, el) {
    activeType = type;
    statCards.forEach(s => s.classList.remove('active'));
    el.classList.add('active');
    // sync chips
    chips.forEach(c => {
      c.classList.toggle('active', c.dataset.filter === type);
    });
    applyFilters();
  }

  function setChipFilter(type, el) {
    activeType = type;
    chips.forEach(c => { if (c.dataset.filter) c.classList.remove('active'); });
    el.classList.add('active');
    // sync stat cards
    statCards.forEach(s => s.classList.toggle('active', s.dataset.filter === type));
    applyFilters();
  }

  function toggleUnreadOnly(el) {
    unreadOnly = !unreadOnly;
    el.classList.toggle('active', unreadOnly);
    applyFilters();
  }

  // init count
  updateCount();
</script>
</body>
</html>
