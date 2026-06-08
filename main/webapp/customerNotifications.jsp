<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true"%>
<%@ page import="java.util.List" %>
<%@ page import="com.util.CustomerNotification" %>
<%@ page import="com.util.Customer" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.util.Date" %>
<%
    Customer customer = (Customer) session.getAttribute("customer");
    if (customer == null) { response.sendRedirect("CustomerLogin.jsp"); return; }

    List<CustomerNotification> notifications = (List<CustomerNotification>) request.getAttribute("notifications");
    Long unreadCount = (Long) request.getAttribute("unreadCount");
    if (notifications == null) notifications = new java.util.ArrayList<>();
    if (unreadCount == null) unreadCount = 0L;

    SimpleDateFormat sdf = new SimpleDateFormat("dd MMM yyyy, hh:mm a");
    String firstName = customer.getName() != null ? customer.getName().split(" ")[0] : "User";
    String avatarChar = customer.getName() != null && !customer.getName().isEmpty()
        ? String.valueOf(customer.getName().charAt(0)).toUpperCase() : "U";
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Notifications — SIBS Store</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=Space+Grotesk:wght@600;700&display=swap" rel="stylesheet">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons/font/bootstrap-icons.css" rel="stylesheet">
  <style>
    :root {
      --primary:    #1e3a5f;
      --primary-lt: #2a5298;
      --accent:     #e94560;
      --accent-lt:  #ff6b81;
      --bg:         #f0f4f8;
      --surface:    #ffffff;
      --surface2:   #f8fafd;
      --text:       #0f172a;
      --text-2:     #334155;
      --muted:      #64748b;
      --border:     #e2e8f0;
      --nav-h:      64px;
      --radius-lg:  18px;
      --radius-md:  12px;
      --radius-sm:  8px;
      --shadow-sm:  0 1px 4px rgba(0,0,0,0.07);
      --shadow-md:  0 4px 20px rgba(30,58,95,0.10);
      --shadow-lg:  0 8px 40px rgba(30,58,95,0.15);
      --green:  #059669; --green-bg:  #d1fae5; --green-bdr: #a7f3d0;
      --blue:   #2563eb; --blue-bg:   #dbeafe; --blue-bdr:  #bfdbfe;
      --orange: #d97706; --orange-bg: #fef3c7; --orange-bdr:#fde68a;
      --red:    #dc2626; --red-bg:    #fee2e2; --red-bdr:   #fecaca;
      --purple: #7c3aed; --purple-bg: #ede9fe; --purple-bdr:#ddd6fe;
      --teal:   #0d9488; --teal-bg:   #ccfbf1; --teal-bdr:  #99f6e4;
    }
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    html { scroll-behavior: smooth; }
    body { font-family: 'Inter', sans-serif; background: var(--bg); color: var(--text); -webkit-font-smoothing: antialiased; }

    /* ── TOP NAV ── */
    .top-nav {
      position: fixed; top: 0; left: 0; right: 0; z-index: 1000;
      height: var(--nav-h);
      background: linear-gradient(135deg, var(--primary) 0%, var(--primary-lt) 100%);
      display: flex; align-items: center; justify-content: space-between;
      padding: 0 1.5rem;
      box-shadow: 0 2px 24px rgba(30,58,95,0.28);
      backdrop-filter: blur(12px);
    }
    .nav-left { display: flex; align-items: center; gap: .85rem; }
    .nav-back {
      background: rgba(255,255,255,0.14); border: 1.5px solid rgba(255,255,255,0.22);
      border-radius: 10px; color: #fff; width: 38px; height: 38px;
      display: flex; align-items: center; justify-content: center;
      text-decoration: none; font-size: 1.05rem; transition: all .2s;
      flex-shrink: 0;
    }
    .nav-back:hover { background: rgba(255,255,255,0.25); color: #fff; transform: translateX(-2px); }
    .nav-brand {
      font-family: 'Space Grotesk', sans-serif;
      font-size: 1.22rem; font-weight: 700; color: #fff;
      text-decoration: none; letter-spacing: -.02em;
    }
    .nav-brand .dot { color: var(--accent-lt); }
    .nav-right { display: flex; align-items: center; gap: .6rem; }
    .nav-profile-pill {
      display: flex; align-items: center; gap: .55rem;
      background: rgba(255,255,255,0.12); border: 1.5px solid rgba(255,255,255,0.20);
      border-radius: 40px; padding: .3rem .9rem .3rem .35rem;
      color: #fff; text-decoration: none; font-size: .84rem; font-weight: 500;
      transition: background .2s;
    }
    .nav-profile-pill:hover { background: rgba(255,255,255,0.22); color: #fff; }
    .nav-avatar {
      width: 30px; height: 30px; border-radius: 50%;
      background: var(--accent); display: flex; align-items: center; justify-content: center;
      font-weight: 700; font-size: .78rem; color: #fff; flex-shrink: 0;
    }

    /* ── HERO BAND ── */
    .hero-band {
      background: linear-gradient(135deg, var(--primary) 0%, var(--primary-lt) 100%);
      padding: calc(var(--nav-h) + 1.75rem) 1.5rem 2rem;
      color: #fff; position: relative; overflow: hidden;
    }
    .hero-band::before {
      content: ''; position: absolute; top: -60px; right: -60px;
      width: 260px; height: 260px; border-radius: 50%;
      background: rgba(255,255,255,0.06);
    }
    .hero-band::after {
      content: ''; position: absolute; bottom: -80px; left: -40px;
      width: 200px; height: 200px; border-radius: 50%;
      background: rgba(255,255,255,0.04);
    }
    .hero-inner { max-width: 780px; margin: 0 auto; position: relative; z-index: 1; }
    .hero-title {
      font-family: 'Space Grotesk', sans-serif;
      font-size: 1.75rem; font-weight: 700; line-height: 1.2; margin-bottom: .4rem;
    }
    .hero-sub { font-size: .9rem; opacity: .72; margin-bottom: 1.25rem; }
    .hero-stats { display: flex; gap: 1rem; flex-wrap: wrap; }
    .hero-stat {
      background: rgba(255,255,255,0.14); border: 1px solid rgba(255,255,255,0.22);
      border-radius: 12px; padding: .7rem 1.2rem; min-width: 110px; text-align: center;
      backdrop-filter: blur(4px);
    }
    .hero-stat-num { font-size: 1.4rem; font-weight: 700; line-height: 1; }
    .hero-stat-lbl { font-size: .72rem; opacity: .75; margin-top: .2rem; text-transform: uppercase; letter-spacing: .06em; }
    .hero-actions { display: flex; gap: .6rem; flex-wrap: wrap; margin-top: 1.25rem; }
    .btn-hero {
      display: inline-flex; align-items: center; gap: .4rem;
      padding: .55rem 1.1rem; border-radius: 10px; font-size: .84rem; font-weight: 600;
      border: none; cursor: pointer; text-decoration: none; transition: all .2s;
    }
    .btn-hero.solid { background: var(--accent); color: #fff; }
    .btn-hero.solid:hover { background: #c93c54; color: #fff; transform: translateY(-1px); }
    .btn-hero.outline { background: rgba(255,255,255,0.14); color: #fff; border: 1.5px solid rgba(255,255,255,0.3); }
    .btn-hero.outline:hover { background: rgba(255,255,255,0.25); color: #fff; }

    /* ── FILTER STRIP ── */
    .filter-strip {
      background: var(--surface); border-bottom: 1px solid var(--border);
      position: sticky; top: var(--nav-h); z-index: 900;
      box-shadow: var(--shadow-sm);
    }
    .filter-inner {
      max-width: 780px; margin: 0 auto;
      display: flex; gap: .4rem; padding: .85rem 1.25rem;
      overflow-x: auto; -webkit-overflow-scrolling: touch; scrollbar-width: none;
    }
    .filter-inner::-webkit-scrollbar { display: none; }
    .tab-pill {
      flex-shrink: 0; display: inline-flex; align-items: center; gap: .35rem;
      padding: .4rem 1rem; border: 1.5px solid var(--border); border-radius: 30px;
      background: transparent; font-size: .8rem; font-weight: 500; color: var(--muted);
      cursor: pointer; transition: all .2s; white-space: nowrap;
    }
    .tab-pill .pill-count {
      background: var(--bg); color: var(--muted);
      font-size: .68rem; font-weight: 700; padding: 1px 6px; border-radius: 20px;
    }
    .tab-pill.active {
      background: var(--primary); color: #fff; border-color: var(--primary);
    }
    .tab-pill.active .pill-count { background: rgba(255,255,255,0.22); color: #fff; }
    .tab-pill:hover:not(.active) { border-color: var(--primary); color: var(--primary); background: #f0f4ff; }

    /* ── MAIN CONTENT ── */
    .main-content {
      max-width: 780px; margin: 0 auto;
      padding: 1.5rem 1.25rem 8rem;
    }

    /* ── NOTIFICATION CARD ── */
    .notif-card {
      background: var(--surface); border-radius: var(--radius-lg);
      border: 1.5px solid var(--border);
      margin-bottom: 1rem; overflow: hidden; position: relative;
      transition: box-shadow .25s, border-color .25s, transform .25s;
      animation: fadeSlideIn .35s ease both;
    }
    @keyframes fadeSlideIn {
      from { opacity: 0; transform: translateY(10px); }
      to   { opacity: 1; transform: translateY(0); }
    }
    .notif-card:hover { box-shadow: var(--shadow-md); border-color: #c7d7f0; transform: translateY(-2px); }
    .notif-card.unread { border-left: 4px solid var(--primary-lt); background: #f7faff; }

    /* Unread dot */
    .unread-dot {
      position: absolute; top: 1rem; right: 1rem;
      width: 10px; height: 10px; border-radius: 50%;
      background: var(--accent); box-shadow: 0 0 0 3px rgba(233,69,96,0.18);
      animation: pulse 2s infinite;
    }
    @keyframes pulse {
      0%,100% { box-shadow: 0 0 0 3px rgba(233,69,96,0.18); }
      50%      { box-shadow: 0 0 0 6px rgba(233,69,96,0.08); }
    }

    /* Color stripe */
    .notif-card.cc-green  { border-left-color: var(--green); }
    .notif-card.cc-blue   { border-left-color: var(--blue); }
    .notif-card.cc-orange { border-left-color: var(--orange); }
    .notif-card.cc-red    { border-left-color: var(--red); }
    .notif-card.cc-purple { border-left-color: var(--purple); }
    .notif-card.cc-teal   { border-left-color: var(--teal); }

    .notif-inner {
      display: flex; gap: 1rem; padding: 1.1rem 1.25rem; align-items: flex-start;
      cursor: pointer;
    }

    /* Icon bubble */
    .notif-icon {
      width: 50px; height: 50px; border-radius: 14px; flex-shrink: 0;
      display: flex; align-items: center; justify-content: center;
      font-size: 1.4rem;
    }
    .notif-icon.ic-green  { background: var(--green-bg);  border: 1px solid var(--green-bdr); }
    .notif-icon.ic-blue   { background: var(--blue-bg);   border: 1px solid var(--blue-bdr); }
    .notif-icon.ic-orange { background: var(--orange-bg); border: 1px solid var(--orange-bdr); }
    .notif-icon.ic-red    { background: var(--red-bg);    border: 1px solid var(--red-bdr); }
    .notif-icon.ic-purple { background: var(--purple-bg); border: 1px solid var(--purple-bdr); }
    .notif-icon.ic-teal   { background: var(--teal-bg);   border: 1px solid var(--teal-bdr); }

    .notif-body { flex: 1; min-width: 0; }
    .notif-title {
      font-size: .96rem; font-weight: 600; color: var(--text);
      margin-bottom: .28rem; line-height: 1.35; padding-right: 1.25rem;
    }
    .notif-text {
      font-size: .85rem; color: var(--muted); line-height: 1.6;
      display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden;
    }
    .notif-card.expanded .notif-text { -webkit-line-clamp: unset; }
    .read-more-hint { font-size: .75rem; color: var(--primary-lt); font-weight: 500; margin-top: .2rem; }
    .notif-card.expanded .read-more-hint { display: none; }

    .notif-meta {
      display: flex; align-items: center; gap: .65rem; margin-top: .65rem;
      flex-wrap: wrap;
    }
    .notif-time {
      font-size: .74rem; color: #94a3b8;
      display: flex; align-items: center; gap: .3rem;
    }
    .notif-badge {
      font-size: .68rem; font-weight: 700; padding: .18rem .65rem;
      border-radius: 20px; text-transform: uppercase; letter-spacing: .05em;
    }
    .nb-green  { background: var(--green-bg);  color: var(--green); }
    .nb-blue   { background: var(--blue-bg);   color: var(--blue); }
    .nb-orange { background: var(--orange-bg); color: var(--orange); }
    .nb-red    { background: var(--red-bg);    color: var(--red); }
    .nb-purple { background: var(--purple-bg); color: var(--purple); }
    .nb-teal   { background: var(--teal-bg);   color: var(--teal); }

    /* ── AGENT CARD ── */
    .agent-card {
      background: linear-gradient(135deg, #f0f4ff 0%, #f0fdf4 100%);
      border: 1.5px solid #c7d2fe;
      border-radius: 12px; padding: .9rem 1rem;
      margin-top: .85rem; display: flex; gap: .85rem; align-items: flex-start;
    }
    .agent-avatar-lg {
      width: 44px; height: 44px; border-radius: 50%;
      background: var(--primary); color: #fff; flex-shrink: 0;
      display: flex; align-items: center; justify-content: center;
      font-weight: 700; font-size: 1.1rem; border: 2.5px solid #fff;
      box-shadow: 0 2px 8px rgba(30,58,95,0.18);
    }
    .agent-info { flex: 1; min-width: 0; }
    .agent-name-row { font-size: .93rem; font-weight: 700; color: var(--primary); margin-bottom: .3rem; }
    .agent-detail {
      display: flex; align-items: center; gap: .35rem;
      font-size: .8rem; color: var(--muted); margin-bottom: .18rem;
    }
    .agent-detail i { font-size: .78rem; flex-shrink: 0; }
    .btn-call {
      display: inline-flex; align-items: center; gap: .4rem;
      background: #16a34a; color: #fff; border: none; border-radius: 22px;
      padding: .38rem 1rem; font-size: .78rem; font-weight: 600;
      text-decoration: none; margin-top: .55rem; transition: background .2s;
    }
    .btn-call:hover { background: #15803d; color: #fff; }

    /* ── REFUND CHIP ── */
    .refund-chip {
      display: inline-flex; align-items: center; gap: .45rem;
      background: var(--green-bg); border: 1.5px solid var(--green-bdr);
      color: var(--green); border-radius: 10px;
      padding: .45rem 1rem; font-size: .9rem; font-weight: 700;
      margin-top: .75rem;
    }
    .refund-chip .amount { font-size: 1.1rem; }
    .refund-chip .label { font-size: .75rem; color: #065f46; font-weight: 400; }

    /* ── CARD ACTION ROW ── */
    .notif-actions {
      display: flex; gap: .45rem; padding: .7rem 1.1rem;
      border-top: 1px solid var(--border); background: var(--surface2);
    }
    .act-btn {
      flex: 1; display: flex; align-items: center; justify-content: center; gap: .35rem;
      padding: .48rem .6rem; border: 1.5px solid var(--border); border-radius: 9px;
      background: transparent; font-size: .78rem; font-weight: 500; color: var(--muted);
      cursor: pointer; text-decoration: none; transition: all .2s;
    }
    .act-btn:hover { background: #f1f5f9; color: var(--text); border-color: #c0cfe0; }
    .act-btn.primary { background: var(--primary); color: #fff; border-color: var(--primary); }
    .act-btn.primary:hover { background: #162e4d; color: #fff; }
    .act-btn.danger { color: var(--red); border-color: #fecaca; }
    .act-btn.danger:hover { background: var(--red-bg); }

    /* ── DATE DIVIDERS ── */
    .date-divider {
      display: flex; align-items: center; gap: .7rem;
      margin: 1.5rem 0 .75rem;
    }
    .date-divider::before, .date-divider::after {
      content: ''; flex: 1; height: 1px; background: var(--border);
    }
    .date-label {
      font-size: .72rem; font-weight: 600; color: var(--muted);
      text-transform: uppercase; letter-spacing: .07em;
      white-space: nowrap;
    }

    /* ── EMPTY STATE ── */
    .empty-state {
      text-align: center; padding: 4rem 2rem;
    }
    .empty-icon-wrap {
      width: 96px; height: 96px; border-radius: 50%;
      background: linear-gradient(135deg, #e0e7ff, #f0fdf4);
      border: 2px solid #c7d2fe;
      display: flex; align-items: center; justify-content: center;
      font-size: 2.6rem; margin: 0 auto 1.4rem;
    }
    .empty-title { font-size: 1.1rem; font-weight: 700; color: var(--text); margin-bottom: .5rem; }
    .empty-sub { font-size: .88rem; color: var(--muted); max-width: 300px; margin: 0 auto; }

    /* ── TOAST ── */
    #toastContainer {
      position: fixed; bottom: 5rem; right: 1.25rem; z-index: 9999;
      display: flex; flex-direction: column-reverse; gap: .45rem;
      pointer-events: none;
    }
    .toast-pill {
      background: #0f172a; color: #fff;
      padding: .65rem 1.1rem; border-radius: 12px;
      font-size: .84rem; font-weight: 500;
      box-shadow: 0 6px 24px rgba(0,0,0,0.28);
      pointer-events: all;
      display: flex; align-items: center; gap: .5rem;
      animation: toastIn .3s cubic-bezier(.34,1.56,.64,1);
    }
    @keyframes toastIn { from { opacity:0; transform:translateY(12px) scale(.95); } to { opacity:1; transform:translateY(0) scale(1); } }

    /* ── MOBILE BOTTOM NAV ── */
    .bottom-nav {
      display: none; position: fixed; bottom: 0; left: 0; right: 0; z-index: 800;
      background: var(--surface); border-top: 1px solid var(--border);
      padding: .5rem 0 calc(.5rem + env(safe-area-inset-bottom));
      box-shadow: 0 -4px 24px rgba(30,58,95,0.10);
    }
    .bn-items { display: flex; justify-content: space-around; align-items: center; }
    .bn-item {
      flex: 1; display: flex; flex-direction: column; align-items: center; gap: .12rem;
      text-decoration: none; color: var(--muted);
      font-size: .63rem; font-weight: 500; padding: .3rem 0;
      transition: color .2s;
    }
    .bn-item i { font-size: 1.25rem; line-height: 1; }
    .bn-item.active, .bn-item:hover { color: var(--primary); }
    .bn-rel { position: relative; display: inline-block; }
    .bn-badge {
      position: absolute; top: -5px; right: -8px;
      background: var(--accent); color: #fff;
      font-size: .58rem; font-weight: 700;
      min-width: 16px; height: 16px; border-radius: 8px;
      display: flex; align-items: center; justify-content: center; padding: 0 3px;
    }

    /* ── RESPONSIVE ── */
    @media (max-width: 600px) {
      .bottom-nav { display: block; }
      .hero-title { font-size: 1.35rem; }
      .hero-stats { gap: .6rem; }
      .hero-stat { min-width: 85px; padding: .55rem .8rem; }
      .main-content { padding: 1rem .75rem 7.5rem; }
      .notif-inner { padding: .9rem 1rem; gap: .75rem; }
      .notif-icon { width: 42px; height: 42px; font-size: 1.2rem; }
      .notif-title { font-size: .88rem; }
      .notif-text { font-size: .81rem; }
      .filter-inner { padding: .6rem .85rem; }
      .hero-band { padding-bottom: 1.5rem; }
      .top-nav { padding: 0 1rem; }
    }
  </style>
</head>
<body>

<%-- ── TOP NAV ── --%>
<nav class="top-nav">
  <div class="nav-left">
    <%-- BUG FIX: back button goes to /Customer servlet, not customerDashboard.jsp --%>
    <a href="Customer" class="nav-back" title="Back to Shop"><i class="bi bi-arrow-left"></i></a>
    <a href="Customer" class="nav-brand">SIBS<span class="dot">.</span>Store</a>
  </div>
  <div class="nav-right">
    <a href="CustomerProfile" class="nav-profile-pill text-decoration-none">
      <div class="nav-avatar"><%= avatarChar %></div>
      <span class="d-none d-sm-inline"><%= firstName %></span>
    </a>
  </div>
</nav>

<%-- ── HERO BAND ── --%>
<div class="hero-band">
  <div class="hero-inner">
    <div class="hero-title">🔔 Notifications</div>
    <div class="hero-sub">Stay updated on your orders, deliveries, and offers</div>
    <div class="hero-stats">
      <div class="hero-stat">
        <div class="hero-stat-num"><%= notifications.size() %></div>
        <div class="hero-stat-lbl">Total</div>
      </div>
      <div class="hero-stat">
        <div class="hero-stat-num"><%= unreadCount %></div>
        <div class="hero-stat-lbl">Unread</div>
      </div>
      <div class="hero-stat">
        <div class="hero-stat-num"><%= notifications.size() - unreadCount %></div>
        <div class="hero-stat-lbl">Read</div>
      </div>
    </div>
    <div class="hero-actions">
      <% if (unreadCount > 0) { %>
      <form method="post" action="CustomerNotifications" style="display:inline;">
        <input type="hidden" name="action" value="markAllRead">
        <button type="submit" class="btn-hero solid">
          <i class="bi bi-check2-all"></i> Mark All Read
        </button>
      </form>
      <% } %>
      <a href="Customer" class="btn-hero outline">
        <i class="bi bi-shop"></i> Back to Shop
      </a>
    </div>
  </div>
</div>

<%-- ── FILTER STRIP ── --%>
<div class="filter-strip">
  <div class="filter-inner" id="filterTabs">
    <button class="tab-pill active" onclick="filterNotifs('all',this)">
      All <span class="pill-count"><%= notifications.size() %></span>
    </button>
    <button class="tab-pill" onclick="filterNotifs('unread',this)">
      Unread <span class="pill-count"><%= unreadCount %></span>
    </button>
    <button class="tab-pill" onclick="filterNotifs('ORDER',this)"><i class="bi bi-bag"></i> Orders</button>
    <button class="tab-pill" onclick="filterNotifs('DELIVERY',this)"><i class="bi bi-truck"></i> Delivery</button>
    <button class="tab-pill" onclick="filterNotifs('RETURN',this)"><i class="bi bi-arrow-return-left"></i> Returns</button>
    <button class="tab-pill" onclick="filterNotifs('REFUND',this)"><i class="bi bi-arrow-counterclockwise"></i> Refunds</button>
    <button class="tab-pill" onclick="filterNotifs('PAYMENT',this)"><i class="bi bi-credit-card"></i> Payments</button>
    <button class="tab-pill" onclick="filterNotifs('WALLET',this)"><i class="bi bi-wallet2"></i> Wallet</button>
    <button class="tab-pill" onclick="filterNotifs('PRODUCT',this)"><i class="bi bi-box-seam"></i> Products</button>
    <button class="tab-pill" onclick="filterNotifs('OFFER',this)"><i class="bi bi-percent"></i> Offers</button>
  </div>
</div>

<%-- ── NOTIFICATION LIST ── --%>
<div class="main-content" id="notifList">

  <% if (notifications.isEmpty()) { %>
  <div class="empty-state" id="emptyState">
    <div class="empty-icon-wrap">🔕</div>
    <div class="empty-title">All caught up!</div>
    <div class="empty-sub">No notifications yet. We'll let you know about orders, deliveries, and special offers.</div>
  </div>
  <% } %>

  <%
    String lastDateGroup = null;
    java.util.Calendar cal = java.util.Calendar.getInstance();
    java.util.Calendar today = java.util.Calendar.getInstance();
    for (CustomerNotification n : notifications) {
      String cc = n.getColorClass() != null ? n.getColorClass() : "blue";
      String time = n.getCreatedAt() != null ? sdf.format(n.getCreatedAt()) : "";
      String typeGroup = n.getType() != null ? n.getType().split("_")[0] : "SYSTEM";
      boolean hasAgent = n.hasAgentDetails();
      boolean hasRefund = n.hasRefundAmount();

      // Date grouping
      String dateGroup = "Older";
      if (n.getCreatedAt() != null) {
        cal.setTime(n.getCreatedAt());
        if (cal.get(java.util.Calendar.YEAR) == today.get(java.util.Calendar.YEAR)
         && cal.get(java.util.Calendar.DAY_OF_YEAR) == today.get(java.util.Calendar.DAY_OF_YEAR)) {
          dateGroup = "Today";
        } else {
          cal.add(java.util.Calendar.DAY_OF_YEAR, 1);
          if (cal.get(java.util.Calendar.YEAR) == today.get(java.util.Calendar.YEAR)
           && cal.get(java.util.Calendar.DAY_OF_YEAR) == today.get(java.util.Calendar.DAY_OF_YEAR)) {
            dateGroup = "Yesterday";
          } else {
            dateGroup = new SimpleDateFormat("MMMM yyyy").format(n.getCreatedAt());
          }
        }
      }
  %>

  <% if (!dateGroup.equals(lastDateGroup)) {
       lastDateGroup = dateGroup; %>
  <div class="date-divider"><span class="date-label"><%= dateGroup %></span></div>
  <% } %>

  <div class="notif-card cc-<%= cc %> <%= !n.isRead() ? "unread" : "" %>"
       data-id="<%= n.getId() %>"
       data-type="<%= n.getType() %>"
       data-group="<%= typeGroup %>"
       data-read="<%= n.isRead() %>"
       id="notif-<%= n.getId() %>">

    <% if (!n.isRead()) { %><div class="unread-dot"></div><% } %>

    <div class="notif-inner" onclick="toggleExpand(<%= n.getId() %>)">
      <div class="notif-icon ic-<%= cc %>">
        <%= n.getIcon() != null ? n.getIcon() : "🔔" %>
      </div>
      <div class="notif-body">
        <div class="notif-title"><%= n.getTitle() %></div>
        <div class="notif-text" id="notif-text-<%= n.getId() %>"><%= n.getBody() %></div>
        <div class="read-more-hint"><i class="bi bi-chevron-down" style="font-size:.7rem;"></i> Tap to read more</div>

        <%-- Agent Details Card --%>
        <% if (hasAgent) { %>
        <div class="agent-card">
          <div class="agent-avatar-lg"><%= n.getAgentName().substring(0,1).toUpperCase() %></div>
          <div class="agent-info">
            <div class="agent-name-row">
              <i class="bi bi-person-badge-fill text-primary" style="font-size:.85rem;margin-right:.25rem;"></i>
              <%= n.getAgentName() %>
            </div>
            <% if (n.getAgentPhone() != null) { %>
            <div class="agent-detail"><i class="bi bi-telephone-fill text-success"></i><%= n.getAgentPhone() %></div>
            <% } %>
            <% if (n.getAgentVehicle() != null && !n.getAgentVehicle().isBlank()) { %>
            <div class="agent-detail"><i class="bi bi-bicycle text-muted"></i><%= n.getAgentVehicle() %></div>
            <% } %>
            <% if (n.getAgentPhone() != null) { %>
            <a href="tel:<%= n.getAgentPhone() %>" class="btn-call"><i class="bi bi-telephone-fill"></i> Call Agent</a>
            <% } %>
          </div>
        </div>
        <% } %>

        <%-- Refund Chip --%>
        <% if (hasRefund) { %>
        <div class="refund-chip">
          <i class="bi bi-currency-rupee"></i>
          <span class="amount">₹<%= String.format("%.2f", n.getRefundAmount()) %></span>
          <span class="label"><%= n.getType() != null && n.getType().contains("CREDITED") ? "credited to wallet" : "refund amount" %></span>
        </div>
        <% } %>

        <div class="notif-meta">
          <span class="notif-time"><i class="bi bi-clock"></i><%= time %></span>
          <span class="notif-badge nb-<%= cc %>"><%= n.getType() != null ? n.getType().replace("_"," ") : "SYSTEM" %></span>
        </div>
      </div>
    </div><%-- /.notif-inner --%>

    <%-- Actions Row --%>
    <div class="notif-actions">
      <% if (!n.isRead()) { %>
      <form method="post" action="CustomerNotifications" style="flex:1;display:contents;">
        <input type="hidden" name="action" value="markRead">
        <input type="hidden" name="id" value="<%= n.getId() %>">
        <button type="submit" class="act-btn primary">
          <i class="bi bi-check2-circle"></i> Mark Read
        </button>
      </form>
      <% } else if (n.getActionUrl() != null && !n.getActionUrl().isBlank()) { %>
      <a href="<%= n.getActionUrl() %>" class="act-btn primary">
        <i class="bi bi-box-arrow-up-right"></i> View Details
      </a>
      <% } else { %>
      <span class="act-btn" style="cursor:default;color:#94a3b8;">
        <i class="bi bi-check2-all text-success"></i> Read
      </span>
      <% } %>

      <form method="post" action="CustomerNotifications" style="display:contents;">
        <input type="hidden" name="action" value="dismiss">
        <input type="hidden" name="id" value="<%= n.getId() %>">
        <button type="submit" class="act-btn danger" title="Dismiss"
                onclick="return confirm('Dismiss this notification?')">
          <i class="bi bi-trash3"></i>
        </button>
      </form>
    </div>

  </div><%-- /.notif-card --%>
  <% } %>

  <div class="empty-state" id="noFilterResults" style="display:none;">
    <div class="empty-icon-wrap">🔍</div>
    <div class="empty-title">No matches</div>
    <div class="empty-sub">No notifications in this category. Try another filter.</div>
  </div>

</div><%-- /.main-content --%>

<%-- ── MOBILE BOTTOM NAV ── --%>
<nav class="bottom-nav">
  <div class="bn-items">
    <a href="Customer" class="bn-item"><i class="bi bi-house-fill"></i><span>Home</span></a>
    <a href="CustomerOrdersServlet" class="bn-item"><i class="bi bi-bag-fill"></i><span>Orders</span></a>
    <a href="CustomerNotifications" class="bn-item active">
      <div class="bn-rel">
        <i class="bi bi-bell-fill"></i>
        <% if (unreadCount > 0) { %><span class="bn-badge"><%= unreadCount %></span><% } %>
      </div>
      <span>Alerts</span>
    </a>
    <a href="CustomerWallet" class="bn-item"><i class="bi bi-wallet2"></i><span>Wallet</span></a>
    <a href="CustomerProfile" class="bn-item"><i class="bi bi-person-circle"></i><span>Profile</span></a>
  </div>
</nav>

<div id="toastContainer"></div>

<script>
// ── Filter ─────────────────────────────────────────────────────────────────
function filterNotifs(filter, btn) {
  document.querySelectorAll('.tab-pill').forEach(b => b.classList.remove('active'));
  btn.classList.add('active');

  const cards = document.querySelectorAll('.notif-card');
  let shown = 0;

  cards.forEach(card => {
    const type  = card.dataset.type  || '';
    const group = card.dataset.group || '';
    const read  = card.dataset.read === 'true';
    let show = false;
    if (filter === 'all')        show = true;
    else if (filter === 'unread') show = !read;
    else show = type.startsWith(filter) || group === filter;
    card.style.display = show ? '' : 'none';
    if (show) shown++;
  });

  // Show/hide date dividers: hide if all cards in section are hidden
  document.querySelectorAll('.date-divider').forEach(div => {
    let sibling = div.nextElementSibling;
    let hasVisible = false;
    while (sibling && !sibling.classList.contains('date-divider')) {
      if (sibling.classList.contains('notif-card') && sibling.style.display !== 'none') {
        hasVisible = true; break;
      }
      sibling = sibling.nextElementSibling;
    }
    div.style.display = hasVisible ? '' : 'none';
  });

  const noRes = document.getElementById('noFilterResults');
  const emptyState = document.getElementById('emptyState');
  if (noRes) noRes.style.display = (shown === 0 && cards.length > 0) ? 'block' : 'none';
  if (emptyState) emptyState.style.display = (cards.length === 0) ? 'block' : 'none';
}

// ── Expand / collapse ──────────────────────────────────────────────────────
function toggleExpand(id) {
  const card = document.getElementById('notif-' + id);
  if (card) card.classList.toggle('expanded');
}

// ── Toast ──────────────────────────────────────────────────────────────────
function showToast(msg, icon) {
  const cont = document.getElementById('toastContainer');
  const el = document.createElement('div');
  el.className = 'toast-pill';
  el.innerHTML = (icon ? '<i class="bi ' + icon + '"></i> ' : '') + msg;
  cont.appendChild(el);
  setTimeout(() => { el.style.opacity='0'; el.style.transition='opacity .3s'; setTimeout(() => el.remove(), 350); }, 3000);
}

// ── Badge polling ──────────────────────────────────────────────────────────
function pollBadge() {
  fetch('CustomerNotifications?action=count')
    .then(r => r.text())
    .then(count => {
      const n = parseInt(count, 10) || 0;
      document.querySelectorAll('.bn-badge').forEach(el => {
        el.textContent = n;
        el.style.display = n > 0 ? 'flex' : 'none';
      });
    }).catch(() => {});
}
setInterval(pollBadge, 30000);
</script>
</body>
</html>
