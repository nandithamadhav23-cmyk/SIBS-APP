<%@ page import="java.util.List" %>
<%@ page import="com.util.Customer" %>
<%@ page import="com.util.CustomerAddress" %>
<%@ page import="com.util.CartItem" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    Customer customer             = (Customer) request.getAttribute("customer");
    Boolean  loggedIn             = (Boolean)  session.getAttribute("loggedIn");
    List<CustomerAddress> addresses = (List<CustomerAddress>) request.getAttribute("addresses");
    List<CartItem> cartItems        = (List<CartItem>)  request.getAttribute("cartItems");
    Integer totalProducts           = (Integer) request.getAttribute("totalProducts");
    String custName    = (customer != null && customer.getName()  != null) ? customer.getName()  : "Guest";
    String custEmail   = (customer != null && customer.getEmail() != null) ? customer.getEmail() : "";
    String custInitial = custName.length() > 0 ? String.valueOf(custName.charAt(0)).toUpperCase() : "G";
    int cartCount      = totalProducts != null ? totalProducts : 0;

    // Profile image
    String custImageFile = (customer != null) ? customer.getProfileImage() : null;
    String custImageSrc;
    if (custImageFile != null && !custImageFile.isEmpty()) {
        custImageSrc = request.getContextPath() + "/images/customers/" + custImageFile;
    } else {
        custImageSrc = request.getContextPath() + "/images/default.png";
    }

    // Password / general messages (from session after redirect)
    String pwdMessage = (String) session.getAttribute("pwdMessage");
    Boolean pwdSuccess = (Boolean) session.getAttribute("pwdSuccess");
    if (pwdMessage != null) { session.removeAttribute("pwdMessage"); session.removeAttribute("pwdSuccess"); }
    String profileMessage = request.getParameter("message");
    String profileError   = (String) request.getAttribute("error");
    String activeSectionParam = request.getParameter("section"); // e.g. "settings"
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>My Profile — SIBS STORE</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
<link href="https://cdn.jsdelivr.net/npm/bootstrap-icons/font/bootstrap-icons.css" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=Nunito:wght@400;500;600;700;800&display=swap" rel="stylesheet">
<script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
<style>
/* ══ TOKENS ══════════════════════════════════════════════════════ */
:root {
      --primary: #0ea5e9;
      --accent: #8b5cf6;
  --gold:     #f5a623;
  --success:  #10b981;
  --danger:   #ef4444;
  --bg:       #f0f4fa;
  --white:    #ffffff;
      --text: #0c1a2e;
  --muted:    #6b7280;
  --border:   #e5e7eb;
  --nav-h:    60px;
  --bot-h:    64px;    /* bottom nav height */
  --radius:   14px;
  --shadow:   0 2px 16px rgba(15,52,96,.09);
}
*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
body {
  font-family: 'Nunito', sans-serif;
  background: var(--bg);
  color: var(--text);
  padding-top: var(--nav-h);
  padding-bottom: var(--bot-h);   /* leave room for bottom nav */
  min-height: 100vh;
}

/* ══ TOP NAV ════════════════════════════════════════════════════ */
.top-nav {
  position: fixed; top: 0; left: 0; right: 0; z-index: 1000;
  height: var(--nav-h);
  background: var(--primary);
  display: flex; align-items: center; justify-content: space-between;
  padding: 0 1rem;
  box-shadow: 0 2px 20px rgba(0,0,0,.2);
}
.nav-brand {
  font-size: 1.15rem; font-weight: 800;
  color: #fff; text-decoration: none;
  display: flex; align-items: center; gap: .4rem;
}
.nav-brand .dot { color: var(--accent); }
.nav-right { display: flex; align-items: center; gap: .5rem; }
.nav-icon-btn {
  background: rgba(255,255,255,.1); border: 1px solid rgba(255,255,255,.15);
  border-radius: 10px; color: #fff; width: 38px; height: 38px;
  display: flex; align-items: center; justify-content: center;
  cursor: pointer; text-decoration: none; font-size: 1rem;
  position: relative; transition: all .2s;
}
.nav-icon-btn:hover { background: rgba(255,255,255,.2); color: #fff; }
.nav-badge {
  position: absolute; top: -4px; right: -4px;
  background: var(--accent); color: #fff; font-size: .6rem; font-weight: 700;
  min-width: 17px; height: 17px; border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
  border: 2px solid var(--primary);
}
/* Desktop-only nav links */
.nav-desktop { display: flex; align-items: center; gap: .5rem; }
@media(max-width:768px) { .nav-desktop { display: none !important; } }

/* ══ BOTTOM NAV (mobile) ════════════════════════════════════════ */
.bottom-nav {
  display: none;
  position: fixed; bottom: 0; left: 0; right: 0; z-index: 900;
  background: var(--primary); border-top: 2px solid rgba(255,255,255,.1);
  height: var(--bot-h); padding: 0 .5rem;
  box-shadow: 0 -4px 20px rgba(0,0,0,.25);
}
.bottom-nav-inner {
  display: grid; grid-template-columns: repeat(5,1fr);
  height: 100%; align-items: stretch;
}
.bn-item {
  display: flex; flex-direction: column; align-items: center; justify-content: center;
  gap: 2px; text-decoration: none; color: rgba(255,255,255,.6);
  font-size: .58rem; font-weight: 700; letter-spacing: .3px; text-transform: uppercase;
  border: none; background: none; cursor: pointer; padding: .3rem 0;
  transition: color .2s; position: relative;
}
.bn-item i { font-size: 1.2rem; }
.bn-item.active { color: #fff; }
.bn-item.active i { color: var(--accent); }
.bn-badge {
  position: absolute; top: 4px; right: 50%; transform: translateX(80%);
  background: var(--accent); color: #fff; font-size: .55rem; font-weight: 700;
  width: 15px; height: 15px; border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
}
@media(max-width:768px) { .bottom-nav { display: block; } }

/* ══ PAGE LAYOUT ════════════════════════════════════════════════ */
.page-wrap { max-width: 1100px; margin: 0 auto; padding: 1.5rem 1rem; }

/* ── HERO (mobile top card) ─────────────────────────────────── */
.profile-hero {
  background: linear-gradient(135deg, var(--primary) 0%, #1a1a2e 60%, #2d1b4e 100%);
  border-radius: var(--radius);
  padding: 1.5rem 1.25rem 1rem;
  display: flex; align-items: center; gap: 1rem;
  margin-bottom: 1rem;
  box-shadow: var(--shadow);
}
.hero-avatar {
  width: 68px; height: 68px; border-radius: 50%; flex-shrink: 0;
  background: var(--accent);
  display: flex; align-items: center; justify-content: center;
  font-size: 1.75rem; font-weight: 800; color: #fff;
  border: 3px solid rgba(255,255,255,.25);
}
.hero-info { flex: 1; min-width: 0; }
.hero-name { font-size: 1.1rem; font-weight: 800; color: #fff; }
.hero-email { font-size: .78rem; color: rgba(255,255,255,.6); margin-top: 2px; word-break: break-all; }
.hero-badges { display: flex; gap: .5rem; margin-top: .6rem; flex-wrap: wrap; }
.hero-badge {
  background: rgba(255,255,255,.12); border: 1px solid rgba(255,255,255,.2);
  border-radius: 20px; padding: .2rem .7rem;
  font-size: .7rem; font-weight: 700; color: rgba(255,255,255,.85);
  display: flex; align-items: center; gap: .3rem;
}

/* ── TAB STRIP ──────────────────────────────────────────────── */
.tab-strip {
  display: flex; gap: .4rem; overflow-x: auto;
  -webkit-overflow-scrolling: touch;
  padding: .15rem .1rem .5rem; margin-bottom: 1rem;
  scrollbar-width: none;
}
.tab-strip::-webkit-scrollbar { display: none; }
.tab-btn {
  display: inline-flex; align-items: center; gap: .4rem;
  padding: .45rem 1rem; border-radius: 20px; white-space: nowrap;
  font-size: .78rem; font-weight: 700; border: 1.5px solid var(--border);
  background: var(--white); color: var(--muted); cursor: pointer;
  transition: all .18s; flex-shrink: 0;
}
.tab-btn i { font-size: .85rem; }
.tab-btn:hover { border-color: var(--primary); color: var(--primary); }
.tab-btn.active { background: var(--primary); border-color: var(--primary); color: #fff; }
.tab-btn.active i { color: rgba(255,255,255,.85); }

/* ── SECTION PANELS ─────────────────────────────────────────── */
.section-card {
  background: var(--white); border: 1px solid var(--border);
  border-radius: var(--radius); box-shadow: var(--shadow); overflow: hidden;
  display: none; margin-bottom: 1rem;
}
.section-card.active-section { display: block; }

.section-header {
  padding: .9rem 1.1rem; border-bottom: 1px solid var(--border);
  display: flex; align-items: center; justify-content: space-between;
  background: #f9fafb;
}
.section-title {
  font-size: .95rem; font-weight: 800; color: var(--primary);
  display: flex; align-items: center; gap: .45rem;
}
.section-body { padding: 1.1rem; }

/* ── DESKTOP SIDEBAR LAYOUT ─────────────────────────────────── */
@media(min-width:860px) {
  .profile-layout { display: grid; grid-template-columns: 240px 1fr; gap: 1.5rem; align-items: start; }
  .profile-hero { display: none; }    /* desktop uses sidebar head */
  .tab-strip    { display: none; }    /* desktop uses sidebar nav */
  .sidebar-card {
    background: var(--white); border: 1px solid var(--border);
    border-radius: var(--radius); box-shadow: var(--shadow);
    overflow: hidden; position: sticky; top: calc(var(--nav-h) + 1rem);
    display: block;
  }
  .sidebar-head {
    background: linear-gradient(135deg, var(--primary), #1a1a2e);
    padding: 1.5rem 1.1rem; text-align: center;
  }
  .sidebar-avatar {
    width: 72px; height: 72px; border-radius: 50%; margin: 0 auto .75rem;
    background: var(--accent);
    display: flex; align-items: center; justify-content: center;
    font-size: 1.75rem; font-weight: 800; color: #fff;
    border: 3px solid rgba(255,255,255,.25);
  }
  .sidebar-name  { color: #fff; font-size: .95rem; font-weight: 700; }
  .sidebar-email { color: rgba(255,255,255,.55); font-size: .75rem; margin-top: 2px; }
  .sidebar-nav   { padding: .6rem 0; }
  .snav-item {
    display: flex; align-items: center; gap: .65rem;
    padding: .65rem 1.1rem; cursor: pointer;
    color: var(--text); font-size: .84rem; font-weight: 600;
    transition: all .15s; border-left: 3px solid transparent;
    text-decoration: none;
  }
  .snav-item:hover { background: var(--bg); color: var(--primary); }
  .snav-item.active { background: rgba(233,69,96,.06); color: var(--accent); border-left-color: var(--accent); }
  .snav-icon {
    width: 30px; height: 30px; border-radius: 8px;
    display: flex; align-items: center; justify-content: center;
    font-size: .85rem; flex-shrink: 0;
    background: rgba(15,52,96,.06);
  }
  .snav-item.active .snav-icon { background: rgba(233,69,96,.1); }
  .snav-divider { height: 1px; background: var(--border); margin: .4rem 1.1rem; }
  .snav-item.logout { color: var(--danger); }
  .snav-item.logout:hover { background: #fef2f2; }
  .section-card.active-section { display: block; }
  /* all sections visible in main-content on desktop */
  .main-content { display: flex; flex-direction: column; gap: 1rem; }
  body { padding-bottom: 0; }
  .bottom-nav { display: none !important; }
}
@media(max-width:859px) {
  .sidebar-card { display: none; }
  .profile-layout { display: block; }
}

/* ── INFO GRID ──────────────────────────────────────────────── */
.info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: .75rem; }
@media(max-width:560px) { .info-grid { grid-template-columns: 1fr; } }
.info-item { background: var(--bg); border-radius: 10px; padding: .7rem .9rem; }
.info-label { font-size: .65rem; text-transform: uppercase; letter-spacing: .07em; color: var(--muted); font-weight: 700; margin-bottom: 3px; }
.info-val   { font-size: .88rem; font-weight: 700; color: var(--text); }
.info-item.full { grid-column: 1 / -1; }

/* ── FORM ───────────────────────────────────────────────────── */
.form-label { font-size: .78rem; font-weight: 700; color: var(--muted); margin-bottom: .3rem; }
.form-control, .form-select {
  border: 1.5px solid var(--border); border-radius: 9px;
  font-family: 'Nunito', sans-serif; font-size: .85rem;
  color: var(--text); padding: .5rem .85rem; transition: all .18s;
}
.form-control:focus, .form-select:focus {
  border-color: var(--accent); box-shadow: 0 0 0 3px rgba(233,69,96,.12); outline: none;
}
.btn-save {
  display: inline-flex; align-items: center; gap: .4rem;
  background: var(--primary); color: #fff; border: none;
  padding: .55rem 1.4rem; border-radius: 10px;
  font-family: 'Nunito', sans-serif; font-size: .85rem; font-weight: 700;
  cursor: pointer; transition: all .2s;
}
.btn-save:hover { background: #0a2a50; transform: translateY(-1px); }
.btn-warn {
  display: inline-flex; align-items: center; gap: .4rem;
  background: var(--gold); color: #fff; border: none;
  padding: .55rem 1.4rem; border-radius: 10px;
  font-family: 'Nunito', sans-serif; font-size: .85rem; font-weight: 700;
  cursor: pointer; transition: all .2s;
}
.btn-warn:hover { background: #d97706; }

/* ── CART TABLE ─────────────────────────────────────────────── */
.cart-table-wrap { overflow-x: auto; -webkit-overflow-scrolling: touch; }
.cart-table { width: 100%; border-collapse: collapse; font-size: .82rem; min-width: 480px; }
.cart-table thead th {
  background: var(--primary); color: rgba(255,255,255,.85);
  padding: .65rem .75rem; font-size: .68rem; text-transform: uppercase;
  letter-spacing: .06em; font-weight: 700; text-align: left;
}
.cart-table tbody td {
  padding: .65rem .75rem; border-bottom: 1px solid var(--border); vertical-align: middle;
}
.cart-table tbody tr:hover td { background: #fafbff; }
.cart-table tbody tr:last-child td { border-bottom: none; }
.cart-thumb { width: 44px; height: 44px; border-radius: 8px; object-fit: cover; border: 1px solid var(--border); }
.stock-ok  { background: rgba(16,185,129,.1); color: var(--success); border: 1px solid rgba(16,185,129,.2); border-radius: 6px; padding: 2px 7px; font-size: .68rem; font-weight: 700; }
.stock-low { background: rgba(239,68,68,.1);  color: var(--danger);  border: 1px solid rgba(239,68,68,.2);  border-radius: 6px; padding: 2px 7px; font-size: .68rem; font-weight: 700; }

/* ── TOAST ──────────────────────────────────────────────────── */
.toast-wrap { position: fixed; bottom: calc(var(--bot-h) + .75rem); right: 1rem; z-index: 9999; }
@media(min-width:769px) { .toast-wrap { bottom: 1.5rem; right: 1.5rem; } }
.toast-item {
  background: var(--primary); color: #fff;
  padding: .75rem 1rem; border-radius: 12px;
  display: flex; align-items: center; gap: .5rem;
  font-size: .84rem; font-weight: 600;
  box-shadow: 0 4px 20px rgba(0,0,0,.2);
  animation: toastIn .3s ease; margin-top: .5rem;
}
@keyframes toastIn { from{opacity:0;transform:translateY(10px);}to{opacity:1;transform:none;} }

/* ── ADDRESS MODAL ──────────────────────────────────────────── */
#addressModal .modal-content { border-radius: 16px; border: none; box-shadow: 0 20px 60px rgba(0,0,0,.2); overflow: hidden; }
#addressModal .modal-header  { background: var(--primary); color: #fff; border: none; }
#addressModal .modal-title   { font-size: .95rem; font-weight: 800; }
#addressModal .btn-close      { filter: brightness(0) invert(1); }

/* ── EMPTY STATE ────────────────────────────────────────────── */
.empty-state { text-align: center; padding: 2.5rem 1rem; color: var(--muted); }
.empty-state i { font-size: 2.5rem; display: block; margin-bottom: .75rem; opacity: .35; }
</style>
</head>
<body>

<!-- ══ TOP NAV ══════════════════════════════════════════════════ -->
<nav class="top-nav">
  <a class="nav-brand" href="Customer">
    <i class="bi bi-bag-heart-fill"></i>SIBS<span class="dot">•</span>STORE
  </a>
  <div class="nav-right">
    <!-- Desktop links -->
    <div class="nav-desktop">
      <a href="Customer"           class="nav-icon-btn" title="Home"><i class="bi bi-house"></i></a>
      <a href="CustomerOrdersServlet" class="nav-icon-btn" title="Orders"><i class="bi bi-box-seam"></i></a>
      <a href="CustomerWallet"     class="nav-icon-btn" title="Wallet"><i class="bi bi-wallet2"></i></a>
    </div>
    <!-- Cart — always visible -->
    <a href="CartServlet?action=view" class="nav-icon-btn" title="Cart">
      <i class="bi bi-bag"></i>
      <span class="nav-badge"><%= cartCount %></span>
    </a>
    <!-- Logout / Login -->
    <% if (Boolean.TRUE.equals(loggedIn)) { %>
    <a href="CustomerLogout" class="nav-icon-btn" title="Logout" style="font-size:.85rem;width:auto;padding:0 .75rem;gap:.35rem;">
      <i class="bi bi-box-arrow-right"></i><span class="nav-desktop" style="display:inline;font-size:.78rem;font-weight:700;">Logout</span>
    </a>
    <% } else { %>
    <a href="CustomerLogin.jsp" class="nav-icon-btn" style="width:auto;padding:0 .75rem;font-size:.78rem;gap:.35rem;font-weight:700;">
      <i class="bi bi-person"></i><span>Login</span>
    </a>
    <% } %>
  </div>
</nav>

<!-- ══ BOTTOM NAV (mobile) ══════════════════════════════════════ -->
<nav class="bottom-nav">
  <div class="bottom-nav-inner">
    <a href="Customer"                class="bn-item"><i class="bi bi-house-fill"></i>Home</a>
    <a href="CartServlet?action=view" class="bn-item">
      <i class="bi bi-bag"></i>Cart
      <span class="bn-badge"><%= cartCount %></span>
    </a>
    <a href="CustomerOrdersServlet"   class="bn-item"><i class="bi bi-box-seam"></i>Orders</a>
    <a href="CustomerNotifications"   class="bn-item"><i class="bi bi-bell"></i>Alerts</a>
    <a href="CustomerProfile"         class="bn-item active"><i class="bi bi-person-circle"></i>Profile</a>
  </div>
</nav>

<!-- ══ PAGE ═════════════════════════════════════════════════════ -->
<div class="page-wrap">
<div class="profile-layout">

  <!-- ── MOBILE HERO ── -->
  <div class="profile-hero">
    <div class="hero-avatar-wrap" style="position:relative;display:inline-block;">
      <img src="<%= custImageSrc %>"
           onerror="this.onerror=null;this.src='<%= request.getContextPath() %>/images/default.png'"
           class="hero-avatar-img"
           style="width:64px;height:64px;border-radius:50%;object-fit:cover;border:3px solid rgba(255,255,255,.3);background:#e5e7eb;"
           alt="<%= custName %>">
    </div>
    <div class="hero-info">
      <div class="hero-name"><%= custName %></div>
      <div class="hero-email"><%= custEmail %></div>
      <div class="hero-badges">
        <span class="hero-badge"><i class="bi bi-shield-check"></i> Verified</span>
        <% if (cartCount > 0) { %>
        <span class="hero-badge"><i class="bi bi-bag"></i> <%= cartCount %> in cart</span>
        <% } %>
      </div>
    </div>
  </div>

  <!-- ── MOBILE TAB STRIP ── -->
  <div class="tab-strip" id="tabStrip">
    <button class="tab-btn active" onclick="showSection('profile',this)" data-sec="profile">
      <i class="bi bi-person-circle"></i>Profile
    </button>
    <button class="tab-btn" onclick="showSection('addresses',this)" data-sec="addresses">
      <i class="bi bi-geo-alt"></i>Addresses
    </button>
    <button class="tab-btn" onclick="showSection('cart',this)" data-sec="cart">
      <i class="bi bi-cart3"></i>Cart
    </button>
    <button class="tab-btn" onclick="showSection('settings',this)" data-sec="settings">
      <i class="bi bi-gear"></i>Settings
    </button>
    <% if (Boolean.TRUE.equals(loggedIn)) { %>
    <a href="CustomerLogout" class="tab-btn" style="color:var(--danger);border-color:rgba(239,68,68,.3);">
      <i class="bi bi-box-arrow-right"></i>Logout
    </a>
    <% } %>
  </div>

  <!-- ── DESKTOP SIDEBAR ── -->
  <div class="sidebar-card">
    <div class="sidebar-head">
      <img src="<%= custImageSrc %>"
           onerror="this.onerror=null;this.src='<%= request.getContextPath() %>/images/default.png'"
           class="sidebar-avatar"
           style="object-fit:cover;border:2px solid rgba(255,255,255,.3);"
           alt="<%= custName %>">
      <div class="sidebar-name"><%= custName %></div>
      <div class="sidebar-email"><%= custEmail %></div>
    </div>
    <div class="sidebar-nav">
      <a class="snav-item active" onclick="showSection('profile',this)" href="#">
        <span class="snav-icon"><i class="bi bi-person-circle"></i></span>My Profile
      </a>
      <a class="snav-item" onclick="showSection('addresses',this)" href="#">
        <span class="snav-icon"><i class="bi bi-geo-alt"></i></span>Addresses
      </a>
      <a class="snav-item" onclick="showSection('cart',this)" href="#">
        <span class="snav-icon"><i class="bi bi-cart3"></i></span>My Cart
      </a>
      <a class="snav-item" href="CustomerOrdersServlet">
        <span class="snav-icon"><i class="bi bi-box-seam"></i></span>My Orders
      </a>
      <a class="snav-item" onclick="showSection('settings',this)" href="#">
        <span class="snav-icon"><i class="bi bi-gear"></i></span>Settings
      </a>
      <div class="snav-divider"></div>
      <a class="snav-item logout" href="CustomerLogout">
        <span class="snav-icon" style="background:rgba(239,68,68,.08);color:var(--danger);">
          <i class="bi bi-box-arrow-right"></i>
        </span>Logout
      </a>
    </div>
  </div>

  <!-- ── MAIN CONTENT ── -->
  <div class="main-content">

    <!-- ▸ PROFILE INFO -->
    <div class="section-card active-section" id="sec-profile">
      <div class="section-header">
        <div class="section-title"><i class="bi bi-person-circle"></i>Personal Information</div>
      </div>
      <div class="section-body">
        <% if (customer != null) { %>
        <div class="info-grid">
          <div class="info-item">
            <div class="info-label">Full Name</div>
            <div class="info-val"><%= customer.getName() %></div>
          </div>
          <div class="info-item">
            <div class="info-label">Email</div>
            <div class="info-val" style="word-break:break-all"><%= customer.getEmail() %></div>
          </div>
          <div class="info-item">
            <div class="info-label">Phone</div>
            <div class="info-val"><%= customer.getPhone() != null ? customer.getPhone() : "—" %></div>
          </div>
          <div class="info-item">
            <div class="info-label">City</div>
            <div class="info-val"><%= customer.getCity() != null ? customer.getCity() : "—" %></div>
          </div>
          <div class="info-item full">
            <div class="info-label">Street / Landmark</div>
            <div class="info-val"><%= customer.getLandmark_street() != null ? customer.getLandmark_street() : "—" %></div>
          </div>
          <div class="info-item">
            <div class="info-label">District / State</div>
            <div class="info-val"><%= customer.getDistrict() %>, <%= customer.getState() %></div>
          </div>
          <div class="info-item">
            <div class="info-label">Country / Pincode</div>
            <div class="info-val"><%= customer.getCountry() %> — <%= customer.getPincode() %></div>
          </div>
        </div>
        <% } else { %>
        <div class="empty-state">
          <i class="bi bi-person-x"></i>
          <p>Please <a href="CustomerLogin.jsp" style="color:var(--accent);font-weight:700;">login</a> to view your profile.</p>
        </div>
        <% } %>
      </div>
    </div>

    <!-- ▸ ADDRESSES -->
    <div class="section-card" id="sec-addresses">
      <div class="section-header">
        <div class="section-title"><i class="bi bi-geo-alt"></i>Saved Addresses</div>
        <button class="btn-save" onclick="openAddressModal('new',null)" style="padding:.38rem .85rem;font-size:.78rem;">
          <i class="bi bi-plus-lg"></i>Add
        </button>
      </div>
      <div class="section-body">
        <div id="addressSection">
          <jsp:include page="AddressSnippet.jsp" />
        </div>
      </div>
    </div>

    <!-- ▸ CART -->
    <div class="section-card" id="sec-cart">
      <div class="section-header">
        <div class="section-title"><i class="bi bi-cart3"></i>Items in Cart</div>
        <% if (cartItems != null && !cartItems.isEmpty()) { %>
        <a href="Checkout" style="display:inline-flex;align-items:center;gap:.35rem;
           background:var(--accent);color:#fff;padding:.38rem .9rem;border-radius:9px;
           text-decoration:none;font-size:.78rem;font-weight:700;">
          <i class="bi bi-credit-card"></i>Checkout
        </a>
        <% } %>
      </div>
      <div class="section-body">
        <% if (cartItems != null && !cartItems.isEmpty()) { %>
        <div class="cart-table-wrap">
          <table class="cart-table">
            <thead>
              <tr>
                <th>Img</th><th>Product</th><th>Pack</th>
                <th>Off</th><th>Price</th><th>Qty</th><th>Total</th><th>Stock</th>
              </tr>
            </thead>
            <tbody>
              <% for (CartItem item : cartItems) { %>
              <tr>
                <td><img src="<%= item.getImageUrl() %>" class="cart-thumb" onerror="this.src='images/default.png'"></td>
                <td style="font-weight:700;"><%= item.getName() %></td>
                <td><%= item.getProductQuantity() %> <%= item.getUnit() %></td>
                <td><% if(item.getDiscount()>0){ %><span style="color:var(--accent);font-weight:700;"><%= (int)item.getDiscount() %>%</span><% }else{ %>—<% } %></td>
                <td>₹<%= String.format("%.2f",item.getFinalPrice()) %></td>
                <td><%= item.getQuantity() %></td>
                <td style="font-weight:800;color:var(--primary);">₹<%= String.format("%.2f",item.getFinalPrice()*item.getQuantity()) %></td>
                <td>
                  <% if(item.getStock()<10){ %><span class="stock-low"><i class="bi bi-exclamation-triangle"></i> Low</span>
                  <% }else{ %><span class="stock-ok"><i class="bi bi-check-circle"></i> OK</span><% } %>
                </td>
              </tr>
              <% } %>
            </tbody>
          </table>
        </div>
        <% } else { %>
        <div class="empty-state">
          <i class="bi bi-cart-x"></i>
          <p>Your cart is empty.</p>
          <a href="Customer" class="btn-save" style="margin-top:.75rem;text-decoration:none;">
            <i class="bi bi-shop"></i>Shop Now
          </a>
        </div>
        <% } %>
      </div>
    </div>

    <!-- ▸ SETTINGS -->
    <div class="section-card" id="sec-settings">
      <div class="section-header">
        <div class="section-title"><i class="bi bi-gear"></i>Account Settings</div>
      </div>
      <div class="section-body">
        <% if (customer != null) { %>

        <%-- Profile / password messages --%>
        <% if (pwdMessage != null && !pwdMessage.isEmpty()) { %>
        <div class="alert <%= Boolean.TRUE.equals(pwdSuccess) ? "alert-success" : "alert-danger" %> d-flex align-items-center gap-2 mb-3" id="custPwdAlert"
             style="font-size:.85rem;border-radius:10px;padding:.7rem 1rem;">
          <i class="bi bi-<%= Boolean.TRUE.equals(pwdSuccess) ? "check-circle-fill" : "exclamation-triangle-fill" %>"></i>
          <%= pwdMessage %>
        </div>
        <% } %>
        <% if (profileMessage != null && !profileMessage.isEmpty()) { %>
        <div class="alert alert-success d-flex align-items-center gap-2 mb-3" id="custProfileAlert"
             style="font-size:.85rem;border-radius:10px;padding:.7rem 1rem;">
          <i class="bi bi-check-circle-fill"></i> <%= profileMessage %>
        </div>
        <% } %>

        <!-- ── Profile Photo ─────────────────────────────────────── -->
        <p style="font-size:.72rem;font-weight:800;text-transform:uppercase;letter-spacing:.08em;color:var(--muted);margin-bottom:.75rem;">
          <i class="bi bi-camera-fill"></i> Profile Photo
        </p>
        <div style="display:flex;align-items:center;gap:1rem;margin-bottom:1rem;flex-wrap:wrap;">
          <img src="<%= custImageSrc %>"
               onerror="this.onerror=null;this.src='<%= request.getContextPath() %>/images/default.png'"
               id="profilePreview"
               style="width:72px;height:72px;border-radius:50%;object-fit:cover;border:3px solid var(--border);"
               alt="Profile Photo">
          <div style="flex:1;min-width:200px;">
            <form action="CustomerProfile" method="post" enctype="multipart/form-data" id="photoUploadForm">
              <div class="d-flex gap-2 flex-wrap">
                <label for="custPhotoInput" class="btn-save" style="cursor:pointer;padding:.45rem 1rem;font-size:.8rem;margin-top:0;">
                  <i class="bi bi-upload"></i> Upload Photo
                </label>
                <input type="file" id="custPhotoInput" name="profileImage" accept="image/*"
                       style="display:none" onchange="previewAndSubmit(this)">
                <% if (custImageFile != null && !custImageFile.isEmpty()) { %>
                <form action="CustomerProfile" method="post" style="display:inline">
                  <input type="hidden" name="action" value="deleteImage">
                  <button type="submit" class="btn-warn" style="padding:.45rem 1rem;font-size:.8rem;"
                          onclick="return confirm('Remove your profile photo?')">
                    <i class="bi bi-trash"></i> Remove
                  </button>
                </form>
                <% } %>
              </div>
              <p style="font-size:.7rem;color:var(--muted);margin-top:.4rem;">JPG, PNG or WEBP · max 5 MB</p>
            </form>
          </div>
        </div>

        <hr style="border-color:var(--border);margin:1.25rem 0;">

        <!-- ── Update Profile ───────────────────────────────────── -->
        <p style="font-size:.72rem;font-weight:800;text-transform:uppercase;letter-spacing:.08em;color:var(--muted);margin-bottom:.75rem;">
          <i class="bi bi-person-fill-gear"></i> Update Profile
        </p>
        <form action="CustomerProfile" method="post">
          <div class="row g-3">
            <div class="col-sm-6">
              <label class="form-label">Full Name</label>
              <input type="text" name="name" class="form-control" value="<%= customer.getName() %>" required>
            </div>
            <div class="col-sm-6">
              <label class="form-label">Phone</label>
              <input type="text" name="phone" class="form-control"
                     value="<%= customer.getPhone() != null ? customer.getPhone() : "" %>">
            </div>
            <div class="col-12">
              <button type="submit" class="btn-save"><i class="bi bi-check-circle"></i>Update Profile</button>
            </div>
          </div>
        </form>

        <hr style="border-color:var(--border);margin:1.25rem 0;">

        <!-- ── Change Password ───────────────────────────────────── -->
        <p style="font-size:.72rem;font-weight:800;text-transform:uppercase;letter-spacing:.08em;color:var(--muted);margin-bottom:.75rem;">
          <i class="bi bi-shield-lock"></i> Change Password
        </p>
        <form action="ChangePasswordServlet" method="post" id="custPwdForm">
          <input type="hidden" name="customerId" value="<%= customer.getId() %>">
          <div class="row g-3">
            <div class="col-12">
              <label class="form-label">Current Password</label>
              <input type="password" name="oldPassword" class="form-control"
                     placeholder="Enter your current password" required>
            </div>
            <div class="col-sm-6">
              <label class="form-label">New Password</label>
              <input type="password" name="newPassword" id="custNewPwd" class="form-control"
                     placeholder="Minimum 8 characters" required minlength="8">
            </div>
            <div class="col-sm-6">
              <label class="form-label">Confirm New Password</label>
              <input type="password" name="confirmPassword" id="custConfirmPwd" class="form-control"
                     placeholder="Re-enter new password" required minlength="8">
              <div id="custPwdMismatch" style="display:none;font-size:.74rem;color:var(--danger);margin-top:.3rem;">
                <i class="bi bi-exclamation-circle"></i> Passwords do not match
              </div>
            </div>
            <div class="col-12">
              <button type="submit" id="custPwdBtn" class="btn-warn">
                <i class="bi bi-shield-lock"></i>Change Password
              </button>
            </div>
          </div>
        </form>

        <% } else { %>
        <div class="empty-state">
          <i class="bi bi-lock"></i>
          <p>Please <a href="CustomerLogin.jsp" style="color:var(--accent);font-weight:700;">login</a> to manage settings.</p>
        </div>
        <% } %>
      </div>
    </div>

  </div><!-- /main-content -->
</div><!-- /profile-layout -->
</div><!-- /page-wrap -->

<!-- ══ ADDRESS MODAL ════════════════════════════════════════════ -->
<div class="modal fade" id="addressModal" tabindex="-1">
  <div class="modal-dialog modal-dialog-centered">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title"><i class="bi bi-geo-alt"></i> Manage Address</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body" id="addressModalContent"></div>
      <div class="modal-footer" style="border-top:1px solid var(--border);">
        <button type="button" class="btn-save" style="background:var(--muted);" data-bs-dismiss="modal">
          <i class="bi bi-arrow-left"></i>Back
        </button>
        <button type="button" id="clearFormBtn" class="btn-save" style="background:var(--danger);">
          <i class="bi bi-x-circle"></i>Clear
        </button>
      </div>
    </div>
  </div>
</div>

<!-- ══ TOAST ════════════════════════════════════════════════════ -->
<div class="toast-wrap" id="toastWrap"></div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
<script>
/* ── Tab switching ─────────────────────────────────────────── */
function showSection(id, el) {
  // Hide all panels
  document.querySelectorAll('.section-card').forEach(s => s.classList.remove('active-section'));
  // Deactivate all triggers
  document.querySelectorAll('.tab-btn, .snav-item').forEach(b => b.classList.remove('active'));
  // Show target
  const sec = document.getElementById('sec-' + id);
  if (sec) sec.classList.add('active-section');
  if (el) el.classList.add('active');
  // Scroll section into view on mobile
  if (window.innerWidth < 860 && sec) {
    setTimeout(() => sec.scrollIntoView({ behavior: 'smooth', block: 'start' }), 80);
  }
}

/* ── Toast ─────────────────────────────────────────────────── */
function showToast(message, type) {
  const colors = { success:'#10b981', danger:'#ef4444', warning:'#f59e0b', info:'#3b82f6' };
  const el = document.createElement('div');
  el.className = 'toast-item';
  el.style.background = colors[type] || 'var(--primary)';
  el.innerHTML = message;
  document.getElementById('toastWrap').appendChild(el);
  setTimeout(() => el.remove(), 3500);
}

/* ── Address helpers ────────────────────────────────────────── */
function openAddressModal(action, addressId) {
  let url = 'Address?action=' + action;
  if (addressId) url += '&addressId=' + addressId;
  $('#addressModalContent').load(url, function() {
    new bootstrap.Modal(document.getElementById('addressModal')).show();
  });
}

$(document).on('submit', '#addAddressForm', function(e) {
  e.preventDefault(); submitAddressForm($(this), '✅ Address added!');
});
$(document).on('submit', '#editAddressForm', function(e) {
  e.preventDefault(); submitAddressForm($(this), '✏️ Address updated!');
});

function submitAddressForm($form, successMsg) {
  $.ajax({
    url: 'Address', type: 'POST', data: $form.serialize(),
    success: function(r) {
      $('#addressSection').html(r);
      bootstrap.Modal.getInstance(document.getElementById('addressModal')).hide();
      showToast(successMsg, 'success');
    },
    error: function() { showToast('❌ Failed to save address.', 'danger'); }
  });
}

function deleteAddress(addressId, customerId) {
  $.ajax({
    url: 'Address', type: 'POST',
    data: { action:'delete', addressId, customerId },
    success: function(r) {
      if (r.includes('Please choose a new default address')) {
        $('#addressModalContent').html(r);
        new bootstrap.Modal(document.getElementById('addressModal')).show();
      } else {
        $('#addressSection').html(r);
        showToast('🗑️ Address deleted!', 'success');
      }
    },
    error: function() { showToast('❌ Cannot delete address.', 'danger'); }
  });
}

function setDefaultAddress(addressId, customerId) {
  $.ajax({
    url: 'Address', type: 'POST',
    data: { action:'setDefault', addressId, customerId },
    success: function(r) { $('#addressSection').html(r); showToast('⭐ Default updated!', 'success'); },
    error: function()    { showToast('❌ Failed to set default.', 'danger'); }
  });
}

$(document).on('click', '#clearFormBtn', function() {
  const form = $('#addressModalContent').find('form')[0];
  if (form) form.reset();
});

/* ── Open correct section if URL has ?tab= or ?section= ──── */
(function() {
  const params = new URLSearchParams(window.location.search);
  const tab = params.get('tab') || params.get('section');
  if (tab) {
    const btn = document.querySelector('[data-sec="' + tab + '"]');
    if (btn) showSection(tab, btn);
  }
})();

/* ── Auto-dismiss alert banners ─────────────────────────── */
['custPwdAlert','custProfileAlert'].forEach(function(id) {
  const el = document.getElementById(id);
  if (el) setTimeout(function() {
    el.style.transition = 'opacity .5s';
    el.style.opacity = '0';
    setTimeout(function() { el.remove(); }, 500);
  }, 5000);
});

/* ── Password confirm mismatch live check ───────────────── */
(function() {
  const newPwd     = document.getElementById('custNewPwd');
  const confirmPwd = document.getElementById('custConfirmPwd');
  const mismatch   = document.getElementById('custPwdMismatch');
  const btn        = document.getElementById('custPwdBtn');
  if (!newPwd || !confirmPwd) return;

  function check() {
    const bad = confirmPwd.value.length > 0 && newPwd.value !== confirmPwd.value;
    mismatch.style.display  = bad ? 'block' : 'none';
    confirmPwd.style.borderColor = bad ? 'var(--danger,#ef4444)' : '';
    if (btn) btn.disabled = bad;
  }
  newPwd.addEventListener('input', check);
  confirmPwd.addEventListener('input', check);
})();

/* ── Profile photo: preview then auto-submit ─────────────── */
function previewAndSubmit(input) {
  if (!input.files || !input.files[0]) return;
  const file = input.files[0];
  const maxMB = 5;
  if (file.size > maxMB * 1024 * 1024) {
    alert('Image must be smaller than ' + maxMB + ' MB.');
    input.value = '';
    return;
  }
  const reader = new FileReader();
  reader.onload = function(e) {
    const preview = document.getElementById('profilePreview');
    // Update every profile image on page for instant feedback
    document.querySelectorAll('img[alt="<%= custName %>"]').forEach(function(img) {
      img.src = e.target.result;
    });
    if (preview) preview.src = e.target.result;
  };
  reader.readAsDataURL(file);
  // Submit the form automatically
  const form = document.getElementById('photoUploadForm');
  if (form) form.submit();
}
</script>
</body>
</html>
