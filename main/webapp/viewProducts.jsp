<%@ page import="java.util.*" %>
<%@ page import="com.util.Product" %>
<%@ page contentType="text/html; charset=UTF-8" %>

<%
    String role  = (session != null) ? (String) session.getAttribute("role") : null;
    String uname = (session != null) ? (String) session.getAttribute("username") : null;

    if (role == null || (!"admin".equalsIgnoreCase(role) && !"staff".equalsIgnoreCase(role))) {
        response.sendRedirect("index.jsp?error=Access denied. Please login.");
        return;
    }

    boolean isAdmin = "admin".equalsIgnoreCase(role);

    List<Product> products = (List<Product>) request.getAttribute("products");
    String success         = request.getParameter("success");
    String updatedId       = request.getParameter("id");

    int totalC = 0, activeC = 0, deletedC = 0, lowC = 0;
    if (products != null) {
        totalC = products.size();
        for (Product p : products) {
            boolean isDel = p.getDeletedAt() != null;
            if (!isDel && "active".equalsIgnoreCase(p.getStatus())) activeC++;
            if (isDel) deletedC++;
            if (!isDel && p.getStock() >= 0 && p.getStock() <= 10) lowC++;
        }
    }

    String initials = (uname != null && uname.length() > 0)
        ? String.valueOf(uname.charAt(0)).toUpperCase() : "U";
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Products — Smart Inventory</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
<link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=Nunito:wght@300;400;500;600;700;800&family=Outfit:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">

<style>
/* ══════════════════════════════════════════════════════════════
   DUAL-THEME VARIABLES
   admin  → dashboard (sky-blue, #0ea5e9)
   staff  → userDashboard (teal/indigo, #27d2c2 / #6366f1)
══════════════════════════════════════════════════════════════ */
<% if (isAdmin) { %>
:root {
  --font: 'Nunito', sans-serif;
  --primary:        #0ea5e9;
  --primary-dark:   #0369a1;
  --primary-light:  #e0f2fe;
  --accent:         #38bdf8;
  --accent-light:   #f0f9ff;
  --navbar-bg:      #0ea5e9;
  --navbar-shadow:  rgba(14,165,233,.28);
  --nav-text:       #ffffff;
  --card-hover-border: #38bdf8;
  --stat-bg:        #f0f9ff;
  --stat-border:    #bae6fd;
  --badge-bg:       #e0f2fe;
  --badge-color:    #0369a1;
  --chip-active-bg: #0ea5e9;
  --chip-active-text:#ffffff;
  --footer-bg:      #0369a1;
  --footer-text:    rgba(255,255,255,.65);
  --footer-accent:  #bae6fd;
  --text-dark:      #0c1a2e;
  --text-mid:       #1e3a5f;
  --text-muted:     #64748b;
  --border:         #dbeafe;
  --bg:             #f0f9ff;
  --bg-card:        #ffffff;
  --success:        #10b981;
  --warning:        #f59e0b;
  --danger:         #ef4444;
  --info:           #3b82f6;
  --radius:         12px;
  --shadow:         0 2px 12px rgba(14,165,233,.09);
  --shadow-hover:   0 8px 32px rgba(14,165,233,.2);
  --nav-h:          64px;
}
<% } else { %>
:root {
  --font: 'Outfit', sans-serif;
  --primary:        #27d2c2;
  --primary-dark:   #0e9488;
  --primary-light:  #ccfbf1;
  --accent:         #6366f1;
  --accent-light:   #eef2ff;
  --navbar-bg:      linear-gradient(135deg, #27d2c2 0%, #6366f1 100%);
  --navbar-shadow:  rgba(99,102,241,.28);
  --nav-text:       #ffffff;
  --card-hover-border: #6366f1;
  --stat-bg:        #f8faff;
  --stat-border:    #e0e7ff;
  --badge-bg:       #eef2ff;
  --badge-color:    #4338ca;
  --chip-active-bg: #6366f1;
  --chip-active-text:#ffffff;
  --footer-bg:      #1e1b4b;
  --footer-text:    rgba(255,255,255,.6);
  --footer-accent:  #a5b4fc;
  --text-dark:      #1e1b4b;
  --text-mid:       #4b5563;
  --text-muted:     #9ca3af;
  --border:         #e0e7ff;
  --bg:             #f3f4f6;
  --bg-card:        #ffffff;
  --success:        #059669;
  --warning:        #d97706;
  --danger:         #dc2626;
  --info:           #2563eb;
  --radius:         14px;
  --shadow:         0 1px 4px rgba(67,56,202,.07), 0 4px 18px rgba(67,56,202,.08);
  --shadow-hover:   0 8px 32px rgba(67,56,202,.2);
  --nav-h:          62px;
}
<% } %>

/* ── BASE ── */
*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
html { font-size: 16px; }
body {
  font-family: var(--font);
  background: var(--bg);
  color: var(--text-dark);
  padding-top: var(--nav-h);
  min-height: 100vh;
  -webkit-font-smoothing: antialiased;
}

/* ── NAVBAR ── */
.top-navbar {
  position: fixed; top: 0; left: 0; right: 0;
  height: var(--nav-h); z-index: 1050;
  background: var(--navbar-bg);
  box-shadow: 0 2px 20px var(--navbar-shadow);
  display: flex; align-items: center;
  padding: 0 1.5rem; gap: 1rem;
}
.nav-brand {
  font-size: 1.2rem; font-weight: 800;
  color: #fff; text-decoration: none;
  display: flex; align-items: center; gap: .4rem;
  white-space: nowrap; letter-spacing: -.2px;
}
.nav-brand .dot { color: #fbbf24; }
.nav-divider { width: 1px; height: 22px; background: rgba(255,255,255,.2); }
.nav-page-label { font-size: .82rem; color: rgba(255,255,255,.6); font-weight: 500; }
.nav-right { margin-left: auto; display: flex; align-items: center; gap: .75rem; }
.nav-user {
  display: flex; align-items: center; gap: .45rem;
  font-size: .85rem; color: rgba(255,255,255,.85);
}
.nav-avatar {
  width: 34px; height: 34px; border-radius: 50%;
  background: linear-gradient(135deg,#fbbf24,#f97316);
  display: flex; align-items: center; justify-content: center;
  font-size: .72rem; font-weight: 800; color: #fff;
  border: 2px solid rgba(255,255,255,.3); flex-shrink: 0;
}
.nav-role {
  font-size: .68rem; font-weight: 700; letter-spacing: .8px;
  text-transform: uppercase; padding: 2px 10px; border-radius: 20px;
  background: rgba(255,255,255,.18); color: #fff;
  border: 1px solid rgba(255,255,255,.3);
}
.nav-btn {
  display: inline-flex; align-items: center; gap: .35rem;
  padding: .38rem .9rem; border-radius: 20px;
  font-size: .78rem; font-weight: 600;
  border: 1.5px solid rgba(255,255,255,.35);
  color: #fff; text-decoration: none;
  background: rgba(255,255,255,.1);
  transition: all .2s; font-family: var(--font);
}
.nav-btn:hover { background: rgba(255,255,255,.22); color: #fff; border-color: #fff; }

/* ── PAGE HEADER ── */
.page-header {
  background: var(--bg-card);
  border-bottom: 1px solid var(--border);
  padding: .9rem 1.75rem;
  display: flex; align-items: center; justify-content: space-between;
  flex-wrap: wrap; gap: .75rem;
  position: sticky; top: var(--nav-h); z-index: 100;
  box-shadow: 0 1px 6px rgba(0,0,0,.05);
}
.page-title {
  font-size: 1.2rem; font-weight: 800; color: var(--text-dark);
  display: flex; align-items: center; gap: .55rem;
}
.page-title-bar {
  width: 4px; height: 1.1em;
  background: var(--primary); border-radius: 2px;
}
.header-controls { display: flex; align-items: center; gap: .6rem; flex-wrap: wrap; }

.search-wrap {
  display: flex; align-items: center; gap: .35rem;
  background: var(--bg); border: 1.5px solid var(--border);
  border-radius: 10px; padding: .38rem .8rem;
  transition: border-color .2s;
}
.search-wrap:focus-within { border-color: var(--primary); }
.search-wrap i { color: var(--text-muted); font-size: .88rem; }
.search-wrap input {
  border: none; background: transparent; outline: none;
  font-family: var(--font); font-size: .85rem;
  color: var(--text-dark); width: 200px;
}
.search-wrap input::placeholder { color: var(--text-muted); }

.sort-select {
  background: var(--bg); border: 1.5px solid var(--border);
  border-radius: 10px; padding: .38rem .8rem;
  font-family: var(--font); font-size: .85rem;
  color: var(--text-dark); outline: none; cursor: pointer;
  transition: border-color .2s;
}
.sort-select:focus { border-color: var(--primary); }

.btn-back {
  display: inline-flex; align-items: center; gap: .35rem;
  background: var(--bg); color: var(--text-mid);
  border: 1.5px solid var(--border); border-radius: 10px;
  padding: .4rem 1rem; font-size: .83rem; font-weight: 600;
  cursor: pointer; text-decoration: none; font-family: var(--font);
  transition: all .18s;
}
.btn-back:hover { background: var(--primary-light); color: var(--primary-dark); border-color: var(--primary); }

/* ── STATS ROW ── */
.stats-row {
  display: flex; gap: .85rem; flex-wrap: wrap;
  padding: .9rem 1.75rem;
  background: var(--bg-card);
  border-bottom: 1px solid var(--border);
}
.stat-card {
  display: flex; align-items: center; gap: .6rem;
  background: var(--stat-bg); border: 1.5px solid var(--stat-border);
  border-radius: 12px; padding: .65rem 1rem;
  flex: 1; min-width: 130px;
  transition: transform .2s, box-shadow .2s;
}
.stat-card:hover { transform: translateY(-2px); box-shadow: var(--shadow); }
.stat-icon {
  width: 38px; height: 38px; border-radius: 10px;
  display: flex; align-items: center; justify-content: center;
  font-size: 1rem; flex-shrink: 0;
}
.stat-icon.total   { background: rgba(14,165,233,.12); color: var(--primary); }
.stat-icon.active  { background: rgba(16,185,129,.12); color: var(--success); }
.stat-icon.deleted { background: rgba(239,68,68,.1);   color: var(--danger); }
.stat-icon.low     { background: rgba(245,158,11,.12); color: var(--warning); }
.stat-val   { font-size: 1.25rem; font-weight: 800; color: var(--text-dark); line-height: 1; }
.stat-label { font-size: .7rem; color: var(--text-muted); margin-top: 2px; font-weight: 600; letter-spacing: .3px; }

/* ── GRID SECTION ── */
.grid-section { padding: 1.25rem 1.75rem; }

.grid-toolbar {
  display: flex; align-items: center; justify-content: space-between;
  flex-wrap: wrap; gap: .6rem;
  margin-bottom: 1rem;
}
.grid-count { font-size: .82rem; color: var(--text-muted); font-weight: 600; }
.grid-count strong { color: var(--text-dark); }

/* Filter chips */
.filter-chips { display: flex; gap: .35rem; flex-wrap: wrap; }
.fchip {
  padding: 4px 14px; border-radius: 20px;
  font-size: .72rem; font-weight: 700; letter-spacing: .3px;
  border: 1.5px solid var(--border);
  background: var(--bg-card); color: var(--text-muted);
  cursor: pointer; transition: all .15s;
}
.fchip:hover { background: var(--primary-light); color: var(--primary-dark); border-color: var(--primary); }
.fchip.active { background: var(--chip-active-bg); color: var(--chip-active-text); border-color: var(--chip-active-bg); }
.fchip.deleted-chip.active { background: var(--danger); border-color: var(--danger); }

/* ── PRODUCT GRID ── */
.products-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(270px, 1fr));
  gap: 1.1rem;
}

.product-card {
  background: var(--bg-card);
  border: 1.5px solid var(--border);
  border-radius: var(--radius);
  box-shadow: var(--shadow);
  overflow: hidden;
  transition: transform .22s, box-shadow .22s, border-color .22s;
  display: flex; flex-direction: column;
  position: relative;
    margin-bottom: 2.3rem;
}
.product-card:hover {
  transform: translateY(-4px);
  box-shadow: var(--shadow-hover);
  border-color: var(--card-hover-border);
}
.product-card.card-deleted {
  opacity: .7;
  background: #fafafa;
}
.product-card.card-deleted:hover { opacity: .9; }

/* Card image area */
.card-img-wrap {
  position: relative;
  width: 100%; padding-top: 62%;
  background: var(--bg);
  overflow: hidden;
}
.card-img-wrap img {
  position: absolute; inset: 0;
  width: 100%; height: 100%;
  object-fit: contain;
  transition: transform .35s;
}
.product-card:hover .card-img-wrap img { transform: scale(1.05); }

/* Overlay badges on image */
.card-badge-overlay {
  position: absolute; top: .6rem; left: .6rem;
  display: flex; flex-direction: column; gap: .3rem; z-index: 2;
}
.badge-cat {
  display: inline-flex; align-items: center;
  background: rgba(255,255,255,.92);
  border: 1px solid rgba(255,255,255,.6);
  backdrop-filter: blur(6px);
  border-radius: 20px; padding: 2px 10px;
  font-size: .65rem; font-weight: 800;
  color: var(--badge-color);
  letter-spacing: .4px; text-transform: capitalize;
  box-shadow: 0 1px 6px rgba(0,0,0,.08);
}
.badge-disc {
  display: inline-flex; align-items: center;
  background: rgba(16,185,129,.9);
  border-radius: 20px; padding: 2px 9px;
  font-size: .65rem; font-weight: 800; color: #fff;
  box-shadow: 0 1px 6px rgba(0,0,0,.1);
}
.badge-deleted {
  display: inline-flex; align-items: center; gap: .2rem;
  background: rgba(239,68,68,.9);
  border-radius: 20px; padding: 2px 9px;
  font-size: .65rem; font-weight: 800; color: #fff;
}
.status-dot-wrap {
  position: absolute; top: .6rem; right: .6rem; z-index: 2;
}
.status-dot {
  width: 10px; height: 10px; border-radius: 50%;
  border: 2px solid #fff;
  box-shadow: 0 1px 5px rgba(0,0,0,.18);
}
.status-dot.active   { background: var(--success); }
.status-dot.inactive { background: var(--danger); }
.status-dot.deleted  { background: var(--text-muted); }

/* Card body */
.card-body-inner {
  padding: 1rem 1.1rem .9rem;
  display: flex; flex-direction: column; gap: .55rem;
  flex: 1;
}
.product-name {
  font-size: .97rem; font-weight: 800;
  color: var(--text-dark); line-height: 1.3;
}
.product-desc {
  font-size: .78rem; color: var(--text-muted);
  line-height: 1.5; display: -webkit-box;
  -webkit-line-clamp: 2; -webkit-box-orient: vertical;
  overflow: hidden;
}

/* Pricing row */
.pricing-row {
  display: flex; align-items: center; gap: .55rem;
  flex-wrap: wrap;
}
.price-final {
  font-size: 1.15rem; font-weight: 800; color: var(--text-dark);
}
.price-mrp {
  font-size: .78rem; color: var(--text-muted);
  text-decoration: line-through;
}
.price-savings {
  font-size: .68rem; font-weight: 700;
  background: rgba(16,185,129,.1); color: var(--success);
  border: 1px solid rgba(16,185,129,.2);
  border-radius: 6px; padding: 1px 7px;
}

/* Details grid inside card */
.details-grid {
  display: grid; grid-template-columns: 1fr 1fr;
  gap: .4rem .6rem;
}
.detail-item { display: flex; flex-direction: column; gap: 1px; }
.detail-label {
  font-size: .62rem; color: var(--text-muted);
  font-weight: 700; letter-spacing: .5px; text-transform: uppercase;
}
.detail-val {
  font-size: .8rem; font-weight: 700; color: var(--text-mid);
}

/* Stock bar */
.stock-row { display: flex; flex-direction: column; gap: 4px; }
.stock-top { display: flex; align-items: center; justify-content: space-between; }
.stock-label { font-size: .62rem; color: var(--text-muted); font-weight: 700; letter-spacing: .5px; text-transform: uppercase; }
.stock-num { font-size: .8rem; font-weight: 800; }
.stock-num.green { color: var(--success); }
.stock-num.amber { color: var(--warning); }
.stock-num.red   { color: var(--danger); }
.stock-bar { height: 5px; border-radius: 5px; background: var(--border); overflow: hidden; }
.stock-fill { height: 100%; border-radius: 5px; transition: width .5s ease; }
.stock-fill.green { background: var(--success); }
.stock-fill.amber { background: var(--warning); }
.stock-fill.red   { background: var(--danger); }

/* Card footer */
.card-footer-inner {
  padding: .65rem 1.1rem;
  border-top: 1px solid var(--border);
  display: flex; align-items: center; justify-content: space-between;
  background: var(--stat-bg);
}
.status-pill {
  display: inline-flex; align-items: center; gap: .3rem;
  border-radius: 20px; padding: 3px 10px;
  font-size: .68rem; font-weight: 800; letter-spacing: .3px;
}
.status-pill .sdot { width: 6px; height: 6px; border-radius: 50%; }
.status-pill.active   { background: rgba(16,185,129,.1); color: var(--success); border: 1px solid rgba(16,185,129,.25); }
.status-pill.active .sdot { background: var(--success); }
.status-pill.inactive { background: rgba(239,68,68,.08); color: var(--danger); border: 1px solid rgba(239,68,68,.2); }
.status-pill.inactive .sdot { background: var(--danger); }
.status-pill.deleted  { background: rgba(107,114,128,.08); color: var(--text-muted); border: 1px solid rgba(107,114,128,.2); }
.status-pill.deleted .sdot { background: var(--text-muted); }

.added-date { font-size: .68rem; color: var(--text-muted); font-weight: 500; }

/* ── EMPTY STATE ── */
.empty-state {
  text-align: center; padding: 5rem 2rem;
  color: var(--text-muted);
}
.empty-state i { font-size: 3.5rem; opacity: .25; display: block; margin-bottom: 1rem; }
.empty-state h5 { color: var(--text-mid); margin-bottom: .4rem; font-weight: 700; }

/* ── TOAST ── */
.toast-container { position: fixed; bottom: 1.5rem; right: 1.5rem; z-index: 9999; display: flex; flex-direction: column; gap: .5rem; }
.toast-item {
  background: var(--bg-card); border: 1px solid var(--border);
  border-radius: 12px; padding: .85rem 1.1rem;
  display: flex; align-items: center; gap: .6rem;
  font-size: .88rem; font-weight: 600; color: var(--text-dark);
  box-shadow: 0 8px 30px rgba(0,0,0,.12); min-width: 260px;
  animation: toastIn .3s ease;
}
@keyframes toastIn { from{opacity:0;transform:translateX(24px);} to{opacity:1;transform:none;} }
.toast-item.success { border-left: 3px solid var(--success); }
.toast-item.error   { border-left: 3px solid var(--danger); }
.ti-icon.success { color: var(--success); font-size: 1.1rem; }
.ti-icon.error   { color: var(--danger); font-size: 1.1rem; }

/* ── FOOTER ── */
footer {
  background: var(--footer-bg);
  color: var(--footer-text);
  font-size: .8rem; font-weight: 500;
  text-align: center; padding: 1rem; margin-top: 2rem;
}
footer span { color: var(--footer-accent); font-weight: 700; }

/* ── RESPONSIVE ── */
@media(max-width: 768px) {
  .page-header { padding: .75rem 1rem; }
  .stats-row { padding: .75rem 1rem; gap: .5rem; }
  .stat-card { min-width: 110px; }
  .grid-section { padding: 1rem; }
  .search-wrap input { width: 140px; }
  .products-grid { grid-template-columns: repeat(auto-fill, minmax(220px, 1fr)); gap: .85rem; }
}
@media(max-width: 480px) {
  .products-grid { grid-template-columns: 1fr 1fr; gap: .65rem; }
}
</style>
</head>
<body>

<!-- ══ NAVBAR ══ -->
<div class="top-navbar">
  <a class="nav-brand" href="<%= isAdmin ? "dashboard.jsp" : "userDashboard" %>">
    <i class="bi bi-boxes"></i>
    Smart<span class="dot">Stock</span>
  </a>
  <div class="nav-divider"></div>
  <span class="nav-page-label">Product Catalogue</span>
  <div class="nav-right">
    <div class="nav-user">
      <div class="nav-avatar"><%= initials %></div>
      <span><%= uname %></span>
    </div>
    <span class="nav-role"><%= role %></span>
    <a href="logout" class="nav-btn"><i class="bi bi-box-arrow-right"></i> Logout</a>
  </div>
</div>

<!-- ══ PAGE HEADER ══ -->
<div class="page-header">
  <div class="page-title">
    <div class="page-title-bar"></div>
    <i class="bi bi-grid-3x3-gap" style="color:var(--primary);"></i>
    All Products
  </div>
  <div class="header-controls">
    <div class="search-wrap">
      <i class="bi bi-search"></i>
      <input type="text" id="searchQuery" placeholder="Search products…">
    </div>
    <select class="sort-select" id="sortBy">
      <option value="">Sort by…</option>
      <option value="name">Name</option>
      <option value="category">Category</option>
      <option value="mrp">MRP</option>
      <option value="discount">Discount</option>
      <option value="stock">Stock</option>
    </select>
    <a href="<%= isAdmin ? "dashboard.jsp?section=products" : "userDashboard" %>" class="btn-back">
      <i class="bi bi-arrow-left"></i> Back to Products
    </a>
  </div>
</div>

<!-- ══ STATS ══ -->
<div class="stats-row">
  <div class="stat-card">
    <div class="stat-icon total"><i class="bi bi-box-seam"></i></div>
    <div>
      <div class="stat-val"><%= totalC %></div>
      <div class="stat-label">Total Products</div>
    </div>
  </div>
  <div class="stat-card">
    <div class="stat-icon active"><i class="bi bi-check-circle-fill"></i></div>
    <div>
      <div class="stat-val" style="color:var(--success);"><%= activeC %></div>
      <div class="stat-label">Active</div>
    </div>
  </div>
  <div class="stat-card">
    <div class="stat-icon deleted"><i class="bi bi-archive-fill"></i></div>
    <div>
      <div class="stat-val" style="color:var(--danger);"><%= deletedC %></div>
      <div class="stat-label">Soft Deleted</div>
    </div>
  </div>
  <div class="stat-card">
    <div class="stat-icon low"><i class="bi bi-exclamation-triangle-fill"></i></div>
    <div>
      <div class="stat-val" style="color:var(--warning);"><%= lowC %></div>
      <div class="stat-label">Low Stock</div>
    </div>
  </div>
</div>

<!-- ══ GRID SECTION ══ -->
<div class="grid-section">

  <!-- Toolbar -->
  <div class="grid-toolbar">
    <div class="grid-count">
      Showing <strong id="visibleCount"><%= products != null ? products.size() : 0 %></strong> products
    </div>
    <div class="filter-chips">
      <span class="fchip active" data-filter="all">All</span>
      <span class="fchip" data-filter="active">Active</span>
      <span class="fchip" data-filter="inactive">Inactive</span>
      <span class="fchip" data-filter="lowstock">Low Stock</span>
      <span class="fchip deleted-chip" data-filter="deleted">Show Deleted</span>
    </div>
  </div>

  <% if (products == null || products.isEmpty()) { %>
  <div class="empty-state">
    <i class="bi bi-box-seam"></i>
    <h5>No products yet</h5>
    <p>Products will appear here once they are added.</p>
  </div>
  <% } else { %>
  <div class="products-grid" id="productsGrid">
    <%
      for (Product p : products) {
        boolean isDeleted   = p.getDeletedAt() != null;
        int     stock       = p.getStock();
        String  stockClass  = (stock == 0) ? "red" : (stock <= 10) ? "amber" : "green";
        double  stockPct    = Math.min(100.0, (stock / 200.0) * 100);
        String  statusKey   = isDeleted ? "deleted" : p.getStatus().toLowerCase();
        double  savings     = p.getMrp() - p.getFinalPrice();
        String  addedFmt    = new java.text.SimpleDateFormat("dd MMM yyyy").format(p.getAddedDate());
        String  catDisplay  = p.getCategory().replace("_"," ");
    %>
    <div class="product-card <%= isDeleted ? "card-deleted" : "" %>"
         id="pcard-<%= p.getId() %>"
         data-status="<%= statusKey %>"
         data-name="<%= p.getName().toLowerCase() %>"
         data-category="<%= p.getCategory().toLowerCase() %>"
         data-stock="<%= stock %>">

      <!-- Image area -->
      <div class="card-img-wrap">
        <img src="<%= p.getImageUrl() != null ? p.getImageUrl() : "images/default.png" %>"
             alt="<%= p.getName() %>"
             onerror="this.src='images/default.png'">

        <!-- Overlay badges -->
        <div class="card-badge-overlay">
          <span class="badge-cat"><%= catDisplay %></span>
          <% if (p.getDiscount() > 0) { %>
          <span class="badge-disc"><i class="bi bi-lightning-fill" style="font-size:.6rem;"></i> <%= (int)p.getDiscount() %>% OFF</span>
          <% } %>
          <% if (isDeleted) { %>
          <span class="badge-deleted"><i class="bi bi-archive-fill" style="font-size:.6rem;"></i> Archived</span>
          <% } %>
        </div>

        <!-- Status dot -->
        <div class="status-dot-wrap">
          <div class="status-dot <%= statusKey %>"></div>
        </div>
      </div>

      <!-- Card body -->
      <div class="card-body-inner">

        <div class="product-name"><%= p.getName() %></div>

        <% if (p.getDescription() != null && !p.getDescription().isEmpty()) { %>
        <div class="product-desc"><%= p.getDescription() %></div>
        <% } %>

        <!-- Pricing -->
        <div class="pricing-row">
          <span class="price-final">₹<%= String.format("%.0f", p.getFinalPrice()) %></span>
          <% if (p.getMrp() > p.getFinalPrice()) { %>
          <span class="price-mrp">₹<%= String.format("%.0f", p.getMrp()) %></span>
          <span class="price-savings">Save ₹<%= String.format("%.0f", savings) %></span>
          <% } %>
        </div>

        <!-- Detail grid -->
        <div class="details-grid">
          <div class="detail-item">
            <span class="detail-label">Package</span>
            <span class="detail-val"><%= p.getQuantity() %> <%= p.getUnit() %></span>
          </div>
          <div class="detail-item">
            <span class="detail-label">MRP</span>
            <span class="detail-val">₹<%= String.format("%.0f", p.getMrp()) %></span>
          </div>
          <div class="detail-item">
            <span class="detail-label">Discount</span>
            <span class="detail-val" style="color:var(--success);">
              <%= p.getDiscount() > 0 ? (int)p.getDiscount() + "%" : "—" %>
            </span>
          </div>
          <div class="detail-item">
            <span class="detail-label">ID</span>
            <span class="detail-val">#<%= p.getId() %></span>
          </div>
        </div>

        <!-- Stock bar -->
        <div class="stock-row">
          <div class="stock-top">
            <span class="stock-label">Stock</span>
            <span class="stock-num <%= stockClass %>"><%= stock %> units</span>
          </div>
          <div class="stock-bar">
            <div class="stock-fill <%= stockClass %>"
                 style="width:<%= (stock == 0 ? 100 : Math.max(4, stockPct)) %>%;"></div>
          </div>
        </div>

      </div><!-- /card-body-inner -->

      <!-- Card footer -->
      <div class="card-footer-inner">
        <span class="status-pill <%= statusKey %>">
          <span class="sdot"></span>
          <%= isDeleted ? "Archived" : p.getStatus().substring(0,1).toUpperCase() + p.getStatus().substring(1) %>
        </span>
        <span class="added-date"><i class="bi bi-calendar3" style="margin-right:3px;"></i><%= addedFmt %></span>
      </div>

    </div><!-- /product-card -->
    <%
      } // end for
    %>
  </div><!-- /products-grid -->
  <% } %>

</div><!-- /grid-section -->

<!-- ══ TOAST CONTAINER ══ -->
<div class="toast-container" id="toastContainer"></div>

<!-- ══ FOOTER ══ -->
<footer>
  <p>&copy; 2026 <span>Smart Inventory</span> &nbsp;|&nbsp;
  <%= isAdmin ? "Administrator Portal" : "Staff Portal" %></p>
</footer>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
<script>
/* ── Toast ── */
function showToast(msg, type) {
  const c = document.getElementById('toastContainer');
  const icon = type === 'success' ? 'bi-check-circle-fill' : 'bi-exclamation-circle-fill';
  const el = document.createElement('div');
  el.className = 'toast-item ' + type;
  el.innerHTML = '<i class="bi ' + icon + ' ti-icon ' + type + '"></i> ' + msg;
  c.appendChild(el);
  setTimeout(function() { el.remove(); }, 4000);
}

/* Auto-show server messages */
(function() {
  <% if (success != null && !success.isEmpty()) { %>
    showToast('<%= success.replace("'","&#39;") %>', 'success');
  <% } %>
  <% if (request.getParameter("error") != null) { %>
    showToast('<%= request.getParameter("error").replace("'","&#39;") %>', 'error');
  <% } %>
  <% if (request.getParameter("msg") != null) { %>
    showToast('<%= request.getParameter("msg").replace("'","&#39;") %>', 'success');
  <% } %>
})();

/* ── Sort (server-side) ── */
document.getElementById('sortBy').addEventListener('change', function() {
  if (!this.value) return;
  window.location.href = 'ProductServlet?action=sort&sortBy=' + encodeURIComponent(this.value);
});

/* ── Search + Filter logic ── */
let activeFilter = 'all';

document.getElementById('searchQuery').addEventListener('input', applyFilters);

document.querySelectorAll('.fchip').forEach(function(chip) {
  chip.addEventListener('click', function() {
    document.querySelectorAll('.fchip').forEach(function(c) { c.classList.remove('active'); });
    this.classList.add('active');
    activeFilter = this.dataset.filter;
    applyFilters();
  });
});

function applyFilters() {
  const q = document.getElementById('searchQuery').value.toLowerCase().trim();
  const cards = document.querySelectorAll('#productsGrid .product-card');
  let visible = 0;

  cards.forEach(function(card) {
    const status    = card.dataset.status;
    const name      = card.dataset.name;
    const category  = card.dataset.category;
    const stock     = parseInt(card.dataset.stock, 10);
    const isDeleted = status === 'deleted';

    const nameMatch = !q || name.includes(q) || category.includes(q);

    let filterMatch = false;
    if (activeFilter === 'all')         filterMatch = !isDeleted;
    else if (activeFilter === 'deleted') filterMatch = isDeleted;
    else if (activeFilter === 'lowstock') filterMatch = stock <= 10 && !isDeleted;
    else                                 filterMatch = status === activeFilter && !isDeleted;

    const show = nameMatch && filterMatch;
    card.style.display = show ? '' : 'none';
    if (show) visible++;
  });

  document.getElementById('visibleCount').textContent = visible;
}

document.addEventListener('DOMContentLoaded', applyFilters);
</script>
</body>
</html>
