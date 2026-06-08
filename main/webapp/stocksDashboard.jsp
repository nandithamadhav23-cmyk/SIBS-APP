<%@ page contentType="text/html; charset=UTF-8" isELIgnored="true" %>
<%@ page import="java.util.*, com.util.*" %>
<%
    String role  = (session != null) ? (String) session.getAttribute("role")     : null;
    String uname = (session != null) ? (String) session.getAttribute("username") : null;
    if (role == null || !("admin".equalsIgnoreCase(role) || "staff".equalsIgnoreCase(role))) {
        response.sendRedirect(request.getContextPath() + "/index.jsp?error=Access+denied.");
        return;
    }
    String ctxPath = request.getContextPath();
%>

<title>Stock Dashboard — Smart Inventory</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
<link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=Nunito:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">

<style>
/* ── ROOT TOKENS (match reportsDashboard) ── */
:root {
  --primary:#0ea5e9; --primary-dark:#0369a1; --primary-light:#e0f2fe;
  --accent:#38bdf8;  --accent-light:#f0f9ff;
  --green:#16a34a;   --green-bg:#dcfce7;
  --amber:#d97706;   --amber-bg:#fef3c7;
  --red:#dc2626;     --red-bg:#fee2e2;
  --purple:#7c3aed;  --purple-bg:#ede9fe;
  --teal:#0d9488;    --teal-bg:#ccfbf1;
  --text-dark:#0c1a2e; --text-mid:#1e3a5f; --text-muted:#64748b;
  --border:#dbeafe;  --bg-white:#fff; --bg-off:#f0f9ff;
  --shadow-sm:0 2px 12px rgba(14,165,233,.08);
  --shadow-md:0 4px 24px rgba(14,165,233,.14);
  --radius:14px; --radius-sm:9px;
}
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
body{font-family:'Nunito',sans-serif;background:var(--bg-off);color:var(--text-dark)}

/* ── HERO BANNER ── */
.stock-hero{
  background:linear-gradient(135deg,#0369a1 0%,#0ea5e9 55%,#38bdf8 100%);
  border-radius:var(--radius);padding:1.6rem 2rem;
  display:flex;align-items:center;justify-content:space-between;
  flex-wrap:wrap;gap:1rem;margin-bottom:1.5rem;
  box-shadow:0 8px 32px rgba(14,165,233,.28);
  position:relative;overflow:hidden;
}
.stock-hero::before{
  content:'';position:absolute;inset:0;
  background:radial-gradient(ellipse at 80% 20%,rgba(255,255,255,.12) 0%,transparent 65%);
  pointer-events:none;
}
.hero-left h1{font-size:1.5rem;font-weight:800;color:#fff;margin-bottom:.2rem;display:flex;align-items:center;gap:.6rem}
.hero-left p{font-size:.82rem;color:rgba(255,255,255,.78);font-weight:500}
.hero-badge{background:rgba(255,255,255,.18);border:1px solid rgba(255,255,255,.3);
  border-radius:20px;padding:.2rem .85rem;font-size:.72rem;font-weight:700;
  color:#fff;letter-spacing:.5px;text-transform:uppercase;backdrop-filter:blur(6px)}
.hero-actions{display:flex;gap:.6rem;align-items:center;flex-wrap:wrap}
.btn-hero{display:flex;align-items:center;gap:.4rem;padding:.5rem 1.1rem;
  border-radius:9px;font-size:.82rem;font-weight:700;cursor:pointer;
  transition:all .2s;border:none;text-decoration:none}
.btn-hero-white{background:#fff;color:#0369a1}
.btn-hero-white:hover{background:#e0f2fe;color:#0369a1}
.btn-hero-ghost{background:rgba(255,255,255,.18);color:#fff;border:1px solid rgba(255,255,255,.35)}
.btn-hero-ghost:hover{background:rgba(255,255,255,.28);color:#fff}
#lastUpdated{font-size:.72rem;color:rgba(255,255,255,.7);margin-left:.4rem}

/* ── ERROR BANNER ── */
.err-banner{display:none;background:#fef2f2;border:1px solid #fecaca;border-radius:var(--radius-sm);
  padding:.75rem 1.1rem;margin-bottom:1rem;color:var(--red);font-size:.85rem;font-weight:600;
  align-items:center;gap:.6rem}
.err-banner.show{display:flex}

/* ── KPI CARDS ── */
.kpi-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(148px,1fr));gap:1rem;margin-bottom:1.5rem}
.kpi-card{
  background:var(--bg-white);border-radius:var(--radius);
  padding:1.1rem 1.2rem;border:1px solid var(--border);
  box-shadow:var(--shadow-sm);position:relative;overflow:hidden;
  transition:transform .2s,box-shadow .2s;cursor:default;
}
.kpi-card:hover{transform:translateY(-3px);box-shadow:var(--shadow-md)}
.kpi-card::after{content:'';position:absolute;top:0;left:0;right:0;height:3px;border-radius:var(--radius) var(--radius) 0 0}
.kpi-card.blue::after  {background:linear-gradient(90deg,#0ea5e9,#38bdf8)}
.kpi-card.green::after {background:linear-gradient(90deg,#16a34a,#4ade80)}
.kpi-card.amber::after {background:linear-gradient(90deg,#d97706,#fbbf24)}
.kpi-card.red::after   {background:linear-gradient(90deg,#dc2626,#f87171)}
.kpi-card.purple::after{background:linear-gradient(90deg,#7c3aed,#a78bfa)}
.kpi-card.teal::after  {background:linear-gradient(90deg,#0d9488,#2dd4bf)}
.kpi-icon{width:40px;height:40px;border-radius:10px;display:flex;align-items:center;
  justify-content:center;font-size:1.15rem;margin-bottom:.75rem}
.kpi-icon.blue  {background:var(--primary-light);color:var(--primary)}
.kpi-icon.green {background:var(--green-bg);color:var(--green)}
.kpi-icon.amber {background:var(--amber-bg);color:var(--amber)}
.kpi-icon.red   {background:var(--red-bg);color:var(--red)}
.kpi-icon.purple{background:var(--purple-bg);color:var(--purple)}
.kpi-icon.teal  {background:var(--teal-bg);color:var(--teal)}
.kpi-val{font-size:1.75rem;font-weight:800;color:var(--text-dark);line-height:1;margin-bottom:.2rem}
.kpi-lbl{font-size:.72rem;font-weight:600;color:var(--text-muted);text-transform:uppercase;letter-spacing:.6px}
.kpi-sub{font-size:.72rem;color:var(--text-muted);margin-top:.3rem}
.kpi-skeleton{background:linear-gradient(90deg,#e0f2fe 25%,#bae6fd 50%,#e0f2fe 75%);
  background-size:200% 100%;animation:shimmer 1.4s infinite;border-radius:6px;height:20px}
@keyframes shimmer{0%{background-position:200% 0}100%{background-position:-200% 0}}

/* ── TAB BAR ── */
.tab-bar{display:flex;gap:.4rem;padding:.35rem;background:var(--bg-white);
  border-radius:var(--radius);border:1px solid var(--border);
  box-shadow:var(--shadow-sm);margin-bottom:1.25rem;flex-wrap:wrap}
.tab-btn{padding:.45rem 1.1rem;border-radius:9px;font-size:.82rem;font-weight:700;
  border:none;background:transparent;color:var(--text-muted);cursor:pointer;
  transition:all .18s;display:flex;align-items:center;gap:.4rem;white-space:nowrap}
.tab-btn:hover{background:var(--accent-light);color:var(--primary)}
.tab-btn.active{background:var(--primary);color:#fff;box-shadow:0 4px 14px rgba(14,165,233,.35)}
.tab-btn .badge{font-size:.68rem;font-weight:700;padding:.15rem .45rem;
  border-radius:10px;line-height:1}
.tab-btn.active .badge{background:rgba(255,255,255,.25);color:#fff}
.tab-btn:not(.active) .badge{background:var(--red-bg);color:var(--red)}

/* ── FILTER BAR ── */
.filter-bar{display:flex;gap:.6rem;align-items:center;flex-wrap:wrap;
  background:var(--bg-white);border:1px solid var(--border);
  border-radius:var(--radius-sm);padding:.6rem .9rem;margin-bottom:1rem;box-shadow:var(--shadow-sm)}
.filter-bar input,.filter-bar select{
  border:1px solid var(--border);border-radius:8px;padding:.38rem .75rem;
  font-size:.82rem;font-family:'Nunito',sans-serif;color:var(--text-dark);
  background:var(--bg-off);outline:none;transition:border-color .18s}
.filter-bar input:focus,.filter-bar select:focus{border-color:var(--primary);background:#fff}
.filter-bar input{flex:1;min-width:160px}
.filter-lbl{font-size:.78rem;font-weight:700;color:var(--text-muted);white-space:nowrap}
#stockCount{font-size:.78rem;font-weight:600;color:var(--text-muted);margin-left:auto;white-space:nowrap}

/* ── CHART GRID ── */
.chart-grid-2{display:grid;grid-template-columns:1fr 1fr;gap:1.1rem;margin-bottom:1.25rem}
.chart-grid-3{display:grid;grid-template-columns:2fr 1fr;gap:1.1rem;margin-bottom:1.25rem}
@media(max-width:768px){.chart-grid-2,.chart-grid-3{grid-template-columns:1fr}}

.chart-card{background:var(--bg-white);border-radius:var(--radius);
  border:1px solid var(--border);box-shadow:var(--shadow-sm);
  padding:1.2rem;position:relative;overflow:hidden}
.chart-card::before{content:'';position:absolute;top:0;left:0;right:0;height:3px;border-radius:var(--radius) var(--radius) 0 0}
.chart-card.blue::before  {background:linear-gradient(90deg,#0ea5e9,#38bdf8)}
.chart-card.green::before {background:linear-gradient(90deg,#16a34a,#4ade80)}
.chart-card.amber::before {background:linear-gradient(90deg,#d97706,#fbbf24)}
.chart-card.red::before   {background:linear-gradient(90deg,#dc2626,#f87171)}
.chart-card.purple::before{background:linear-gradient(90deg,#7c3aed,#a78bfa)}
.chart-card.multi::before {background:linear-gradient(90deg,#0ea5e9,#7c3aed,#16a34a,#d97706)}
.chart-title{font-size:.78rem;font-weight:700;color:var(--text-muted);
  text-transform:uppercase;letter-spacing:.7px;margin-bottom:1rem;
  display:flex;align-items:center;gap:.5rem}
.chart-title i{color:var(--primary);font-size:.9rem}
.chart-wrap{position:relative}

/* ── PRODUCT TABLE ── */
.tbl-wrap{background:var(--bg-white);border-radius:var(--radius);
  border:1px solid var(--border);box-shadow:var(--shadow-sm);overflow:hidden;margin-bottom:1.25rem}
.tbl-head{display:flex;align-items:center;justify-content:space-between;
  padding:.9rem 1.2rem;border-bottom:1px solid var(--border);flex-wrap:wrap;gap:.5rem}
.tbl-head-title{font-size:.92rem;font-weight:800;color:var(--text-dark);display:flex;align-items:center;gap:.5rem}
.tbl-head-title i{color:var(--primary)}
.tbl-scroll{overflow-x:auto}
table{width:100%;border-collapse:collapse;font-size:.82rem}
thead tr{background:var(--accent-light)}
thead th{padding:.65rem 1rem;text-align:left;font-size:.7rem;font-weight:700;
  color:var(--text-muted);text-transform:uppercase;letter-spacing:.7px;
  border-bottom:1px solid var(--border);white-space:nowrap}
tbody tr{border-bottom:1px solid var(--border);transition:background .15s}
tbody tr:last-child{border-bottom:none}
tbody tr:hover{background:var(--accent-light)}
tbody td{padding:.65rem 1rem;color:var(--text-dark);vertical-align:middle}
.prod-img{width:38px;height:38px;border-radius:8px;object-fit:cover;
  border:1px solid var(--border);background:var(--bg-off)}
.prod-img-placeholder{width:38px;height:38px;border-radius:8px;
  background:var(--primary-light);display:flex;align-items:center;
  justify-content:center;font-size:.9rem;color:var(--primary);flex-shrink:0}
.prod-name{font-weight:700;color:var(--text-dark);max-width:160px;
  overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.prod-cat{font-size:.7rem;color:var(--text-muted);margin-top:1px}

/* Stock badge */
.stock-badge{display:inline-flex;align-items:center;gap:.3rem;
  font-size:.72rem;font-weight:700;padding:.2rem .6rem;border-radius:20px}
.stock-badge.out  {background:var(--red-bg);color:var(--red)}
.stock-badge.low  {background:var(--amber-bg);color:var(--amber)}
.stock-badge.ok   {background:var(--green-bg);color:var(--green)}
.stock-badge.high {background:var(--purple-bg);color:var(--purple)}

/* Stock bar */
.stock-bar-wrap{min-width:90px}
.stock-bar-bg{height:6px;border-radius:3px;background:var(--border);overflow:hidden}
.stock-bar-fill{height:100%;border-radius:3px;transition:width .6s ease}

/* Inline stock editor */
.stock-editor{display:flex;align-items:center;gap:.4rem}
.stock-input{width:70px;border:1px solid var(--border);border-radius:7px;
  padding:.28rem .5rem;font-size:.82rem;font-family:'Nunito',sans-serif;
  text-align:center;outline:none;background:var(--bg-off);transition:border-color .18s}
.stock-input:focus{border-color:var(--primary);background:#fff}
.btn-save-stock{background:var(--primary);color:#fff;border:none;border-radius:7px;
  padding:.3rem .6rem;font-size:.72rem;font-weight:700;cursor:pointer;transition:background .18s}
.btn-save-stock:hover{background:var(--primary-dark)}
.btn-save-stock.saving{background:var(--text-muted);pointer-events:none}
.btn-save-stock.saved{background:var(--green)}

/* ── PAGINATION ── */
.pagination-wrap{display:flex;align-items:center;justify-content:space-between;
  padding:.75rem 1.2rem;border-top:1px solid var(--border);font-size:.78rem;
  color:var(--text-muted);flex-wrap:wrap;gap:.5rem}
.page-btns{display:flex;gap:.3rem}
.page-btn{width:30px;height:30px;border-radius:7px;border:1px solid var(--border);
  background:var(--bg-white);font-size:.78rem;font-weight:600;cursor:pointer;
  display:flex;align-items:center;justify-content:center;transition:all .15s;color:var(--text-mid)}
.page-btn:hover{background:var(--accent-light);border-color:var(--primary);color:var(--primary)}
.page-btn.active{background:var(--primary);border-color:var(--primary);color:#fff}
.page-btn:disabled{opacity:.4;cursor:not-allowed}

/* ── DETAIL MODAL ── */
.modal-overlay{position:fixed;inset:0;background:rgba(12,26,46,.55);
  z-index:2000;display:none;align-items:center;justify-content:center;
  padding:1rem;backdrop-filter:blur(4px)}
.modal-overlay.open{display:flex}
.modal-box{background:var(--bg-white);border-radius:var(--radius);
  width:100%;max-width:520px;box-shadow:0 20px 60px rgba(0,0,0,.22);
  overflow:hidden;animation:slideUp .25s ease}
@keyframes slideUp{from{opacity:0;transform:translateY(24px)}to{opacity:1;transform:translateY(0)}}
.modal-header{background:linear-gradient(135deg,#0369a1,#0ea5e9);
  padding:1.1rem 1.4rem;display:flex;align-items:center;justify-content:space-between}
.modal-header h3{font-size:1rem;font-weight:800;color:#fff;margin:0}
.modal-close{background:rgba(255,255,255,.2);border:none;color:#fff;
  width:30px;height:30px;border-radius:50%;font-size:1rem;cursor:pointer;
  display:flex;align-items:center;justify-content:center;transition:background .18s}
.modal-close:hover{background:rgba(255,255,255,.35)}
.modal-body{padding:1.4rem}
.modal-img{width:100%;height:180px;object-fit:contain;border-radius:10px;
  border:1px solid var(--border);background:var(--bg-off);margin-bottom:1rem}
.modal-img-placeholder{width:100%;height:120px;border-radius:10px;
  background:var(--primary-light);display:flex;align-items:center;
  justify-content:center;font-size:2.5rem;color:var(--primary);margin-bottom:1rem}
.detail-grid{display:grid;grid-template-columns:1fr 1fr;gap:.6rem}
.detail-row{background:var(--bg-off);border-radius:8px;padding:.55rem .8rem}
.detail-row.full{grid-column:1/-1}
.detail-lbl{font-size:.68rem;font-weight:700;color:var(--text-muted);text-transform:uppercase;letter-spacing:.5px;margin-bottom:.15rem}
.detail-val{font-size:.9rem;font-weight:700;color:var(--text-dark)}
.modal-footer{padding:.9rem 1.4rem;border-top:1px solid var(--border);
  display:flex;justify-content:flex-end;gap:.6rem}
.btn-modal{padding:.45rem 1rem;border-radius:8px;font-size:.82rem;
  font-weight:700;border:none;cursor:pointer;transition:all .18s}
.btn-modal-ghost{background:var(--bg-off);color:var(--text-muted);border:1px solid var(--border)}
.btn-modal-ghost:hover{background:var(--border)}
.btn-modal-primary{background:var(--primary);color:#fff}
.btn-modal-primary:hover{background:var(--primary-dark)}

/* ── SECTION VISIBILITY ── */
.dash-section{display:none}.dash-section.active{display:block}

/* ── LOADING OVERLAY ── */
.loading-overlay{position:absolute;inset:0;background:rgba(255,255,255,.75);
  border-radius:var(--radius);display:none;align-items:center;
  justify-content:center;z-index:10;backdrop-filter:blur(2px)}
.loading-overlay.show{display:flex}
.spinner{width:28px;height:28px;border:3px solid var(--primary-light);
  border-top-color:var(--primary);border-radius:50%;animation:spin .7s linear infinite}
@keyframes spin{to{transform:rotate(360deg)}}

/* ── EMPTY STATE ── */
.empty-state{padding:3rem 1rem;text-align:center;color:var(--text-muted)}
.empty-state i{font-size:3rem;margin-bottom:.75rem;display:block;color:var(--border)}
.empty-state p{font-size:.9rem;font-weight:600}

/* ── RESPONSIVE ── */
@media(max-width:576px){
  .kpi-grid{grid-template-columns:repeat(2,1fr)}
  .stock-editor{flex-direction:column;align-items:flex-start}
  .detail-grid{grid-template-columns:1fr}
}
</style>

<!-- ═══════════════════════════════════════════════════════════
     HTML
═══════════════════════════════════════════════════════════ -->

<!-- Hero Banner -->
<div class="stock-hero">
  <div class="hero-left">
    <h1><i class="bi bi-boxes"></i> Stock Dashboard <span class="hero-badge">Live</span></h1>
    <p>Real-time inventory health — low stock alerts &amp; product details</p>
  </div>
  <div class="hero-actions">
    <span id="lastUpdated"></span>
    <button class="btn-hero btn-hero-ghost" onclick="loadAll()">
      <i class="bi bi-arrow-clockwise"></i> Refresh
    </button>
    <button class="btn-hero btn-hero-white" onclick="exportCsv()">
      <i class="bi bi-download"></i> Export CSV
    </button>
  </div>
</div>

<!-- Error banner -->
<div class="err-banner" id="errBanner"><i class="bi bi-exclamation-triangle-fill"></i><span id="errMsg"></span></div>

<!-- KPI Cards -->
<div class="kpi-grid" id="kpiGrid">
  <div class="kpi-card blue">
    <div class="kpi-icon blue"><i class="bi bi-box-seam"></i></div>
    <div class="kpi-val" id="kTotal"><div class="kpi-skeleton" style="width:60px"></div></div>
    <div class="kpi-lbl">Total Products</div>
    <div class="kpi-sub" id="kCategories">—</div>
  </div>
  <div class="kpi-card green">
    <div class="kpi-icon green"><i class="bi bi-check-circle"></i></div>
    <div class="kpi-val" id="kInStock"><div class="kpi-skeleton" style="width:60px"></div></div>
    <div class="kpi-lbl">In Stock</div>
    <div class="kpi-sub" id="kUnits">—</div>
  </div>
  <div class="kpi-card amber">
    <div class="kpi-icon amber"><i class="bi bi-exclamation-triangle"></i></div>
    <div class="kpi-val" id="kLow"><div class="kpi-skeleton" style="width:60px"></div></div>
    <div class="kpi-lbl">Low Stock</div>
    <div class="kpi-sub">≤ <span id="kThreshold">10</span> units</div>
  </div>
  <div class="kpi-card red">
    <div class="kpi-icon red"><i class="bi bi-x-circle"></i></div>
    <div class="kpi-val" id="kOut"><div class="kpi-skeleton" style="width:60px"></div></div>
    <div class="kpi-lbl">Out of Stock</div>
    <div class="kpi-sub">Needs restock</div>
  </div>
  <div class="kpi-card teal">
    <div class="kpi-icon teal"><i class="bi bi-stack"></i></div>
    <div class="kpi-val" id="kTotalUnits"><div class="kpi-skeleton" style="width:60px"></div></div>
    <div class="kpi-lbl">Total Units</div>
    <div class="kpi-sub">Across all products</div>
  </div>
  <div class="kpi-card purple">
    <div class="kpi-icon purple"><i class="bi bi-tag"></i></div>
    <div class="kpi-val" id="kCat"><div class="kpi-skeleton" style="width:60px"></div></div>
    <div class="kpi-lbl">Categories</div>
    <div class="kpi-sub">Product groups</div>
  </div>
</div>

<!-- Tab Bar -->
<div class="tab-bar">
  <button class="tab-btn active" id="tab-all"      onclick="switchTab('all')">
    <i class="bi bi-grid-3x3-gap"></i> All Products
  </button>
  <button class="tab-btn" id="tab-out"             onclick="switchTab('out')">
    <i class="bi bi-x-circle"></i> Out of Stock
    <span class="badge" id="badgeOut">0</span>
  </button>
  <button class="tab-btn" id="tab-low"             onclick="switchTab('low')">
    <i class="bi bi-exclamation-triangle"></i> Low Stock
    <span class="badge" id="badgeLow">0</span>
  </button>
  <button class="tab-btn" id="tab-charts"          onclick="switchTab('charts')">
    <i class="bi bi-bar-chart-line"></i> Analytics
  </button>
</div>

<!-- ── SECTION: All / Out / Low (shared table) ── -->
<div class="dash-section active" id="section-all">

  <!-- Filter bar -->
  <div class="filter-bar">
    <i class="bi bi-search" style="color:var(--text-muted);font-size:.9rem"></i>
    <input type="text" id="searchInput" placeholder="Search product name or category…" oninput="applyFilters()">
    <span class="filter-lbl">Category:</span>
    <select id="catFilter" onchange="applyFilters()">
      <option value="">All</option>
    </select>
    <span class="filter-lbl">Status:</span>
    <select id="statusFilter" onchange="applyFilters()">
      <option value="">All</option>
      <option value="out">Out of Stock</option>
      <option value="low">Low Stock</option>
      <option value="ok">Healthy</option>
    </select>
    <span id="stockCount">— products</span>
  </div>

  <!-- Table -->
  <div class="tbl-wrap">
    <div class="tbl-head">
      <div class="tbl-head-title"><i class="bi bi-table"></i> Product Inventory</div>
      <div style="display:flex;gap:.5rem;align-items:center">
        <span style="font-size:.75rem;color:var(--text-muted)">Rows per page:</span>
        <select id="pageSize" onchange="goPage(1)" style="border:1px solid var(--border);border-radius:7px;padding:.25rem .5rem;font-size:.78rem;background:var(--bg-off);font-family:'Nunito',sans-serif">
          <option value="15">15</option>
          <option value="30" selected>30</option>
          <option value="50">50</option>
          <option value="100">100</option>
        </select>
      </div>
    </div>
    <div class="tbl-scroll" style="position:relative">
      <div class="loading-overlay show" id="tblLoader"><div class="spinner"></div></div>
      <table>
        <thead>
          <tr>
            <th style="width:44px">#</th>
            <th>Product</th>
            <th>Category</th>
            <th style="cursor:pointer" onclick="sortTable('mrp')">MRP <i class="bi bi-arrow-down-up" style="font-size:.6rem"></i></th>
            <th>Discount</th>
            <th>Final Price</th>
            <th style="cursor:pointer" onclick="sortTable('stock')">Stock <i class="bi bi-arrow-down-up" style="font-size:.6rem"></i></th>
            <th>Status</th>
            <th style="min-width:160px">Update Stock</th>
            <th>Details</th>
          </tr>
        </thead>
        <tbody id="productTbody">
          <tr><td colspan="10"><div class="empty-state"><i class="bi bi-hourglass-split"></i><p>Loading products…</p></div></td></tr>
        </tbody>
      </table>
    </div>
    <div class="pagination-wrap">
      <span id="pageInfo">—</span>
      <div class="page-btns" id="pageBtns"></div>
    </div>
  </div>
</div>

<!-- ── SECTION: Charts / Analytics ── -->
<div class="dash-section" id="section-charts">

  <!-- Row 1: Distribution donut + Category bar -->
  <div class="chart-grid-3">
    <div class="chart-card multi">
      <div class="chart-title"><i class="bi bi-bar-chart-line"></i>Stock by Category — Units Available</div>
      <div class="chart-wrap" style="height:250px">
        <div class="loading-overlay show" id="ldr-catBar"><div class="spinner"></div></div>
        <canvas id="chartCatBar" aria-label="Stock by category bar chart"></canvas>
      </div>
    </div>
    <div class="chart-card purple">
      <div class="chart-title"><i class="bi bi-pie-chart"></i>Stock Health Distribution</div>
      <div class="chart-wrap" style="height:200px">
        <div class="loading-overlay show" id="ldr-dist"><div class="spinner"></div></div>
        <canvas id="chartDist" aria-label="Stock distribution doughnut"></canvas>
      </div>
      <div id="distLegend" style="display:flex;flex-wrap:wrap;gap:8px;margin-top:.75rem;font-size:.72rem;justify-content:center"></div>
    </div>
  </div>

  <!-- Row 2: Out-of-stock list + Low stock horizontal bar -->
  <div class="chart-grid-2">
    <div class="chart-card red">
      <div class="chart-title"><i class="bi bi-x-circle"></i>Out of Stock Products</div>
      <div id="outListWrap" style="max-height:280px;overflow-y:auto">
        <div class="loading-overlay show" id="ldr-outList" style="position:relative;height:100px"><div class="spinner"></div></div>
      </div>
    </div>
    <div class="chart-card amber">
      <div class="chart-title"><i class="bi bi-exclamation-triangle"></i>Low Stock — Units Remaining</div>
      <div class="chart-wrap" style="height:250px">
        <div class="loading-overlay show" id="ldr-lowBar"><div class="spinner"></div></div>
        <canvas id="chartLowBar" aria-label="Low stock horizontal bar chart"></canvas>
      </div>
    </div>
  </div>

  <!-- Row 3: Category health stacked -->
  <div class="chart-card green" style="margin-bottom:1.25rem">
    <div class="chart-title"><i class="bi bi-layers"></i>Category Health — Stacked (Out / Low / Healthy)</div>
    <div class="chart-wrap" style="height:240px">
      <div class="loading-overlay show" id="ldr-catHealth"><div class="spinner"></div></div>
      <canvas id="chartCatHealth" aria-label="Category health stacked bar chart"></canvas>
    </div>
    <div style="display:flex;gap:1rem;margin-top:.75rem;font-size:.72rem;flex-wrap:wrap">
      <span><span style="display:inline-block;width:10px;height:10px;border-radius:2px;background:#dc2626;margin-right:4px"></span>Out of Stock</span>
      <span><span style="display:inline-block;width:10px;height:10px;border-radius:2px;background:#d97706;margin-right:4px"></span>Low Stock</span>
      <span><span style="display:inline-block;width:10px;height:10px;border-radius:2px;background:#16a34a;margin-right:4px"></span>Healthy</span>
    </div>
  </div>

</div>

<!-- ── PRODUCT DETAIL MODAL ── -->
<div class="modal-overlay" id="detailModal" onclick="if(event.target===this)closeModal()">
  <div class="modal-box">
    <div class="modal-header">
      <h3 id="modalTitle">Product Details</h3>
      <button class="modal-close" onclick="closeModal()"><i class="bi bi-x"></i></button>
    </div>
    <div class="modal-body">
      <div id="modalImgWrap"></div>
      <div class="detail-grid" id="modalDetails"></div>
    </div>
    <div class="modal-footer">
      <button class="btn-modal btn-modal-ghost" onclick="closeModal()">Close</button>
      <a class="btn-modal btn-modal-primary" id="modalEditLink" href="#">
        <i class="bi bi-pencil"></i> Edit Product
      </a>
    </div>
  </div>
</div>

<!-- ═══════════════════════════════════════════════════════════
     SCRIPTS
═══════════════════════════════════════════════════════════ -->
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
<script>
/* ── GLOBALS ── */
const CTX = '<%=ctxPath%>';
const API = CTX + '/StockApiServlet';
const charts = {};
let allProducts = [], filteredProducts = [], currentPage = 1, sortKey = 'stock', sortAsc = true;
let currentTab = 'all';

/* ════════════════════════════════════════════════
   CHART FACTORY (3D-style, matches reportsDashboard)
════════════════════════════════════════════════ */
function merge(a, b) {
  const out = Object.assign({}, a);
  for (const k in b) {
    if (b[k] && typeof b[k]==='object' && !Array.isArray(b[k])) out[k] = merge(a[k]||{}, b[k]);
    else out[k] = b[k];
  }
  return out;
}
const BASE_OPTS = {
  responsive:true, maintainAspectRatio:false,
  animation:{ duration:900, easing:'easeOutQuart' },
  plugins:{
    legend:{ display:false },
    tooltip:{
      backgroundColor:'rgba(8,15,35,.93)',
      titleColor:'#e0f2fe', bodyColor:'rgba(255,255,255,.82)',
      padding:12, cornerRadius:10,
      borderColor:'rgba(14,165,233,.25)', borderWidth:1,
      titleFont:{family:'Nunito',weight:'700',size:12},
      bodyFont:{family:'Nunito',size:11},
      displayColors:true, boxWidth:8, boxHeight:8, boxPadding:4
    }
  },
  scales:{
    x:{ grid:{color:'rgba(14,165,233,.04)',drawBorder:false}, ticks:{color:'#64748b',font:{family:'Nunito',size:10}}, border:{display:false} },
    y:{ grid:{color:'rgba(14,165,233,.07)',drawBorder:false}, ticks:{color:'#64748b',font:{family:'Nunito',size:10}}, border:{display:false}, beginAtZero:true }
  }
};
function _vertGrad(ctx, c1, c2) {
  const g = ctx.createLinearGradient(0, 0, 0, ctx.canvas.clientHeight||300);
  g.addColorStop(0, c1); g.addColorStop(1, c2); return g;
}
function _hBarGrads(ctx, colors) {
  const w = ctx.canvas.clientWidth||400;
  return colors.map(c => {
    const g = ctx.createLinearGradient(0,0,w,0);
    g.addColorStop(0, c); g.addColorStop(1, c.replace(/[\d.]+\)$/,'.3)')); return g;
  });
}
function _colGrads(ctx, count, hueStart) {
  const h = ctx.canvas.clientHeight||280;
  return Array.from({length:count},(_,i)=>{
    const hue = hueStart + i*9;
    const g = ctx.createLinearGradient(0,0,0,h);
    g.addColorStop(0,`hsla(${hue},76%,60%,1)`);
    g.addColorStop(.5,`hsla(${hue},68%,46%,1)`);
    g.addColorStop(1,`hsla(${hue},62%,33%,1)`);
    return g;
  });
}
function killChart(id){ if(charts[id]){charts[id].destroy();delete charts[id];} }

function mkBar(id, labels, datasets, opts={}) {
  killChart(id);
  const el = document.getElementById(id); if(!el) return;
  const ctx = el.getContext('2d');
  const styled = datasets.map(ds => {
    const out = Object.assign({},ds);
    if(!opts.stacked && !opts.horizontal && typeof out.backgroundColor==='string')
      out.backgroundColor = _colGrads(ctx, labels.length, opts.hueStart||195);
    if(opts.horizontal && Array.isArray(out.backgroundColor))
      out.backgroundColor = _hBarGrads(ctx, out.backgroundColor);
    if(!out.borderRadius && !opts.stacked) out.borderRadius = 8;
    if(!out.borderSkipped) out.borderSkipped = false;
    out.borderWidth = out.borderWidth??0;
    return out;
  });
  const extra = {};
  if(opts.horizontal) extra.indexAxis = 'y';
  if(opts.stacked) extra.scales = {x:{stacked:true,grid:{display:false}},y:{stacked:true}};
  if(opts.yFmt) extra.scales = merge(extra.scales||{},{y:{ticks:{callback:opts.yFmt}}});
  if(opts.xFmt) extra.scales = merge(extra.scales||{},{x:{ticks:{callback:opts.xFmt}}});
  charts[id] = new Chart(ctx, {type:'bar', data:{labels,datasets:styled}, options:merge(BASE_OPTS,extra)});
}

function mkDoughnut(id, labels, data, colors) {
  killChart(id);
  const el = document.getElementById(id); if(!el) return;
  charts[id] = new Chart(el, {
    type:'doughnut',
    data:{ labels, datasets:[{data, backgroundColor:colors, borderWidth:4,
      borderColor:'#fff', hoverOffset:12, borderRadius:6}]},
    options:merge(BASE_OPTS, {cutout:'68%', scales:{},
      plugins:{ legend:{display:false} }
    })
  });
}

function hideLdr(id){ const el=document.getElementById(id); if(el) el.classList.remove('show'); }

/* ════════════════════════════════════════════════
   DATA LOADING
════════════════════════════════════════════════ */
async function api(action, params='') {
  const r = await fetch(`${API}?action=${action}${params}`);
  if(!r.ok) throw new Error(`HTTP ${r.status}`);
  return r.json();
}

function showErr(msg) {
  const b = document.getElementById('errBanner');
  document.getElementById('errMsg').textContent = msg;
  b.classList.add('show');
  setTimeout(()=>b.classList.remove('show'), 6000);
}

async function loadAll() {
  document.getElementById('tblLoader').classList.add('show');
  try {
    const [ov, prods, cats, dist] = await Promise.all([
      api('overview'),
      api('all_products'),
      api('category_stock'),
      api('stock_trend')
    ]);
    renderKPIs(ov);
    allProducts = prods;
    applyFilters();
    populateCatFilter(cats);
    renderCharts(cats, dist);
    updateBadges(ov);
    document.getElementById('lastUpdated').textContent =
      'Updated ' + new Date().toLocaleTimeString('en-IN',{hour:'2-digit',minute:'2-digit'});
  } catch(e) {
    showErr('Failed to load stock data: ' + e.message);
  } finally {
    document.getElementById('tblLoader').classList.remove('show');
  }
}

/* ── KPIs ── */
function renderKPIs(d) {
  document.getElementById('kTotal').textContent    = d.total     ?? '—';
  document.getElementById('kInStock').textContent  = d.in_stock  ?? '—';
  document.getElementById('kLow').textContent      = d.low_stock ?? '—';
  document.getElementById('kOut').textContent      = d.out_of_stock ?? '—';
  document.getElementById('kTotalUnits').textContent = (d.total_units??0).toLocaleString('en-IN');
  document.getElementById('kCat').textContent      = d.categories ?? '—';
  document.getElementById('kCategories').textContent = (d.categories??0) + ' categories';
  document.getElementById('kUnits').textContent    = (d.total_units??0).toLocaleString('en-IN') + ' total units';
  document.getElementById('kThreshold').textContent = d.threshold ?? 10;
}

function updateBadges(d) {
  document.getElementById('badgeOut').textContent = d.out_of_stock ?? 0;
  document.getElementById('badgeLow').textContent = d.low_stock ?? 0;
}

/* ── Category filter dropdown ── */
function populateCatFilter(cats) {
  const sel = document.getElementById('catFilter');
  const cur = sel.value;
  sel.innerHTML = '<option value="">All</option>' +
    cats.map(c=>`<option value="${esc(c.category)}">${esc(c.category)} (${c.product_count})</option>`).join('');
  sel.value = cur;
}

/* ════════════════════════════════════════════════
   TABLE RENDERING
════════════════════════════════════════════════ */
function getStockLabel(stock) {
  if(stock===0)   return {cls:'out',  icon:'bi-x-circle',              label:'Out of Stock'};
  if(stock<=10)   return {cls:'low',  icon:'bi-exclamation-triangle',  label:'Low ('+stock+')'};
  if(stock<=50)   return {cls:'ok',   icon:'bi-check-circle',          label:'Healthy'};
  return             {cls:'high', icon:'bi-arrow-up-circle',           label:'Overstocked'};
}
function getBarColor(stock) {
  if(stock===0)  return '#dc2626';
  if(stock<=10)  return '#d97706';
  if(stock<=50)  return '#16a34a';
  return '#7c3aed';
}
function getBarWidth(stock) {
  if(stock===0) return 0;
  const pct = Math.min(100, (stock/100)*100);
  return Math.max(4, pct);
}

function applyFilters() {
  const q       = document.getElementById('searchInput').value.toLowerCase().trim();
  const cat     = document.getElementById('catFilter').value;
  const status  = document.getElementById('statusFilter').value;

  filteredProducts = allProducts.filter(p => {
    const matchQ   = !q || p.name.toLowerCase().includes(q) || (p.category||'').toLowerCase().includes(q);
    const matchCat = !cat || p.category === cat;
    let matchSt = true;
    if(status==='out') matchSt = p.stock===0;
    else if(status==='low') matchSt = p.stock>0 && p.stock<=10;
    else if(status==='ok') matchSt = p.stock>10;
    return matchQ && matchCat && matchSt;
  });

  sortFiltered();
  currentPage = 1;
  renderTable();
}

function sortTable(key) {
  if(sortKey===key) sortAsc = !sortAsc;
  else { sortKey=key; sortAsc=true; }
  sortFiltered();
  renderTable();
}

function sortFiltered() {
  filteredProducts.sort((a,b) => {
    let av=a[sortKey], bv=b[sortKey];
    if(typeof av==='string') av=av.toLowerCase();
    if(typeof bv==='string') bv=bv.toLowerCase();
    return sortAsc ? (av<bv?-1:av>bv?1:0) : (av>bv?-1:av<bv?1:0);
  });
}

function renderTable() {
  const size  = parseInt(document.getElementById('pageSize').value)||30;
  const total = filteredProducts.length;
  const pages = Math.max(1, Math.ceil(total/size));
  currentPage = Math.min(currentPage, pages);
  const start = (currentPage-1)*size;
  const slice = filteredProducts.slice(start, start+size);

  document.getElementById('stockCount').textContent = total + ' product' + (total===1?'':'s');

  const tbody = document.getElementById('productTbody');
  if(slice.length===0) {
    tbody.innerHTML = '<tr><td colspan="10"><div class="empty-state"><i class="bi bi-inbox"></i><p>No products match the current filter.</p></div></td></tr>';
  } else {
    tbody.innerHTML = slice.map((p, idx) => {
      const sl  = getStockLabel(p.stock);
      const bar = getBarColor(p.stock);
      const img = p.image
        ? `<img src="${esc(p.image)}" class="prod-img" onerror="this.style.display='none';this.nextElementSibling.style.display='flex'">`
        : '';
      const ph  = `<div class="prod-img-placeholder" ${p.image?'style="display:none"':''}><i class="bi bi-image"></i></div>`;
      return `<tr>
        <td style="color:var(--text-muted);font-size:.75rem">${start+idx+1}</td>
        <td>
          <div style="display:flex;align-items:center;gap:.6rem">
            ${img}${ph}
            <div>
              <div class="prod-name" title="${esc(p.name)}">${esc(p.name)}</div>
              <div class="prod-cat">${esc(p.unit||'')} &bull; ID #${p.id}</div>
            </div>
          </div>
        </td>
        <td><span style="font-size:.75rem;background:var(--accent-light);color:var(--primary);padding:.15rem .55rem;border-radius:20px;font-weight:700">${esc(p.category)}</span></td>
        <td style="font-weight:700">₹${p.mrp.toFixed(2)}</td>
        <td style="color:var(--green);font-weight:700">${p.discount>0?p.discount+'%':'—'}</td>
        <td style="font-weight:800;color:var(--text-dark)">₹${p.final_price.toFixed(2)}</td>
        <td>
          <div style="display:flex;flex-direction:column;gap:.3rem">
            <span class="stock-badge ${sl.cls}"><i class="bi ${sl.icon}"></i>${sl.label}</span>
            <div class="stock-bar-wrap">
              <div class="stock-bar-bg">
                <div class="stock-bar-fill" style="width:${getBarWidth(p.stock)}%;background:${bar}"></div>
              </div>
            </div>
          </div>
        </td>
        <td><span style="font-size:.72rem;padding:.2rem .55rem;border-radius:20px;font-weight:700;background:${p.status==='active'?'var(--green-bg)':'var(--red-bg)'};color:${p.status==='active'?'var(--green)':'var(--red)'}">
          ${p.status==='active'?'Active':'Inactive'}
        </span></td>
        <td>
          <div class="stock-editor">
            <input class="stock-input" type="number" id="si_${p.id}" value="${p.stock}" min="0" max="99999"
              onkeydown="if(event.key==='Enter')saveStock(${p.id})">
            <button class="btn-save-stock" id="sb_${p.id}" onclick="saveStock(${p.id})">
              <i class="bi bi-check-lg"></i>
            </button>
          </div>
        </td>
        <td>
          <button onclick='openModal(${JSON.stringify(p)})' style="background:var(--primary-light);color:var(--primary);border:none;border-radius:8px;padding:.3rem .65rem;font-size:.78rem;font-weight:700;cursor:pointer">
            <i class="bi bi-eye"></i>
          </button>
        </td>
      </tr>`;
    }).join('');
  }

  renderPagination(total, size, pages);
}

function renderPagination(total, size, pages) {
  const start = (currentPage-1)*size+1;
  const end   = Math.min(currentPage*size, total);
  document.getElementById('pageInfo').textContent =
    total===0 ? 'No results' : `Showing ${start}–${end} of ${total}`;

  const wrap = document.getElementById('pageBtns');
  let btns = `<button class="page-btn" onclick="goPage(${currentPage-1})" ${currentPage===1?'disabled':''}>‹</button>`;
  const range = pageRange(currentPage, pages);
  range.forEach(p => {
    if(p==='…') btns += `<button class="page-btn" disabled>…</button>`;
    else btns += `<button class="page-btn ${p===currentPage?'active':''}" onclick="goPage(${p})">${p}</button>`;
  });
  btns += `<button class="page-btn" onclick="goPage(${currentPage+1})" ${currentPage===pages?'disabled':''}>›</button>`;
  wrap.innerHTML = btns;
}

function pageRange(cur, total) {
  if(total<=7) return Array.from({length:total},(_,i)=>i+1);
  if(cur<=4)   return [1,2,3,4,5,'…',total];
  if(cur>=total-3) return [1,'…',total-4,total-3,total-2,total-1,total];
  return [1,'…',cur-1,cur,cur+1,'…',total];
}

function goPage(p) {
  const size  = parseInt(document.getElementById('pageSize').value)||30;
  const pages = Math.max(1,Math.ceil(filteredProducts.length/size));
  if(p<1||p>pages) return;
  currentPage = p;
  renderTable();
}

/* ── Stock update ── */
async function saveStock(id) {
  const inp = document.getElementById('si_'+id);
  const btn = document.getElementById('sb_'+id);
  const val = parseInt(inp.value);
  if(isNaN(val)||val<0){ inp.style.borderColor='var(--red)'; return; }
  inp.style.borderColor='';
  btn.classList.add('saving');
  btn.innerHTML='<i class="bi bi-hourglass-split"></i>';
  try {
    const form = new FormData();
    form.append('action','update_stock'); form.append('id',id); form.append('stock',val);
    const r = await fetch(API, {method:'POST', body:form});
    const d = await r.json();
    if(d.ok) {
      btn.classList.remove('saving'); btn.classList.add('saved');
      btn.innerHTML='<i class="bi bi-check-lg"></i>';
      // update local data
      const p = allProducts.find(x=>x.id===id);
      if(p){ p.stock=val; p.status=val===0?'inactive':'active'; }
      const fp = filteredProducts.find(x=>x.id===id);
      if(fp){ fp.stock=val; fp.status=val===0?'inactive':'active'; }
      setTimeout(()=>{ btn.classList.remove('saved'); btn.innerHTML='<i class="bi bi-check-lg"></i>'; renderTable(); }, 1200);
    } else {
      throw new Error(d.error||'Unknown error');
    }
  } catch(e) {
    btn.classList.remove('saving');
    btn.innerHTML='<i class="bi bi-x-lg"></i>';
    showErr('Stock update failed: '+e.message);
    setTimeout(()=>{ btn.innerHTML='<i class="bi bi-check-lg"></i>'; },1500);
  }
}

/* ════════════════════════════════════════════════
   CHARTS
════════════════════════════════════════════════ */
function renderCharts(cats, dist) {
  // 1. Category stock bar (total units per category)
  const catLabels = cats.map(c=>c.category);
  const catUnits  = cats.map(c=>c.total_stock);
  mkBar('chartCatBar', catLabels, [{
    label:'Units', data:catUnits, backgroundColor:'#0ea5e9'
  }], {hueStart:195, yFmt:v=>v>=1000?Math.round(v/1000)+'K':v});
  hideLdr('ldr-catBar');

  // 2. Stock distribution doughnut
  const distColors = dist.map(d=>d.color);
  const distData   = dist.map(d=>d.count);
  const distLabels = dist.map(d=>d.label);
  mkDoughnut('chartDist', distLabels, distData, distColors);
  hideLdr('ldr-dist');
  const leg = document.getElementById('distLegend');
  leg.innerHTML = dist.map((d,i)=>
    `<span style="display:flex;align-items:center;gap:4px;font-size:.72rem;color:var(--text-muted)">
      <span style="width:10px;height:10px;border-radius:2px;background:${distColors[i]};display:inline-block"></span>
      ${d.label} (${d.count})
    </span>`
  ).join('');

  // 3. Low-stock horizontal bar (top 12 products with lowest non-zero stock)
  const lowProds = allProducts.filter(p=>p.stock>0&&p.stock<=10)
    .sort((a,b)=>a.stock-b.stock).slice(0,12);
  if(lowProds.length>0) {
    const colors = lowProds.map(p=>p.stock<=3?'#dc2626':p.stock<=7?'#d97706':'#f59e0b');
    mkBar('chartLowBar',
      lowProds.map(p=>p.name.length>18?p.name.slice(0,18)+'…':p.name),
      [{ label:'Stock', data:lowProds.map(p=>p.stock), backgroundColor:colors }],
      {horizontal:true, xFmt:v=>v+' units'}
    );
  }
  hideLdr('ldr-lowBar');

  // 4. Category health stacked bar
  const topCats = cats.slice(0,10);
  mkBar('chartCatHealth', topCats.map(c=>c.category), [
    { label:'Out of Stock', data:topCats.map(c=>c.out_of_stock), backgroundColor:'#dc2626', borderRadius:0 },
    { label:'Low Stock',    data:topCats.map(c=>c.low_stock),    backgroundColor:'#d97706', borderRadius:0 },
    { label:'Healthy',      data:topCats.map(c=>c.healthy),      backgroundColor:'#16a34a', borderRadius:0 }
  ], {stacked:true});
  hideLdr('ldr-catHealth');

  // 5. Out-of-stock list
  renderOutList();
  hideLdr('ldr-outList');
}

function renderOutList() {
  const out = allProducts.filter(p=>p.stock===0).sort((a,b)=>a.name.localeCompare(b.name));
  const wrap = document.getElementById('outListWrap');
  if(out.length===0) {
    wrap.innerHTML='<div class="empty-state" style="padding:1.5rem"><i class="bi bi-check-circle-fill" style="color:var(--green)"></i><p>No out-of-stock products!</p></div>';
    return;
  }
  wrap.innerHTML = out.map(p=>`
    <div style="display:flex;align-items:center;justify-content:space-between;
      padding:.55rem .9rem;border-bottom:1px solid var(--border);gap:.5rem">
      <div style="display:flex;align-items:center;gap:.5rem;min-width:0">
        <i class="bi bi-x-circle-fill" style="color:var(--red);flex-shrink:0"></i>
        <div style="min-width:0">
          <div style="font-size:.82rem;font-weight:700;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">${esc(p.name)}</div>
          <div style="font-size:.7rem;color:var(--text-muted)">${esc(p.category)} &bull; ₹${p.final_price.toFixed(2)}</div>
        </div>
      </div>
      <input class="stock-input" type="number" id="osi_${p.id}" value="0" min="0" style="width:60px"
        onkeydown="if(event.key==='Enter')saveStock(${p.id})">
    </div>
  `).join('');
}

/* ════════════════════════════════════════════════
   TABS
════════════════════════════════════════════════ */
function switchTab(tab) {
  currentTab = tab;
  document.querySelectorAll('.tab-btn').forEach(b=>b.classList.remove('active'));
  document.getElementById('tab-'+tab).classList.add('active');

  // All sections use the same table section; charts is separate
  document.getElementById('section-all').classList.toggle('active', tab!=='charts');
  document.getElementById('section-charts').classList.toggle('active', tab==='charts');

  if(tab==='out') {
    document.getElementById('statusFilter').value='out';
  } else if(tab==='low') {
    document.getElementById('statusFilter').value='low';
  } else if(tab==='all') {
    document.getElementById('statusFilter').value='';
  }
  if(tab!=='charts') applyFilters();
}

/* ════════════════════════════════════════════════
   MODAL
════════════════════════════════════════════════ */
function openModal(p) {
  document.getElementById('modalTitle').textContent = p.name;
  const imgWrap = document.getElementById('modalImgWrap');
  imgWrap.innerHTML = p.image
    ? `<img src="${esc(p.image)}" class="modal-img" onerror="this.style.display='none'">`
    : `<div class="modal-img-placeholder"><i class="bi bi-image"></i></div>`;

  const sl = getStockLabel(p.stock);
  document.getElementById('modalDetails').innerHTML = `
    <div class="detail-row"><div class="detail-lbl">Product ID</div><div class="detail-val">#${p.id}</div></div>
    <div class="detail-row"><div class="detail-lbl">Category</div><div class="detail-val">${esc(p.category)}</div></div>
    <div class="detail-row"><div class="detail-lbl">MRP</div><div class="detail-val">₹${p.mrp.toFixed(2)}</div></div>
    <div class="detail-row"><div class="detail-lbl">Final Price</div><div class="detail-val">₹${p.final_price.toFixed(2)}</div></div>
    <div class="detail-row"><div class="detail-lbl">Discount</div><div class="detail-val">${p.discount>0?p.discount+'%':'No discount'}</div></div>
    <div class="detail-row"><div class="detail-lbl">Unit</div><div class="detail-val">${esc(p.unit)||'—'}</div></div>
    <div class="detail-row"><div class="detail-lbl">Pack Qty</div><div class="detail-val">${p.quantity}</div></div>
    <div class="detail-row"><div class="detail-lbl">Stock Level</div>
      <div class="detail-val"><span class="stock-badge ${sl.cls}"><i class="bi ${sl.icon}"></i>${sl.label}</span></div></div>
    <div class="detail-row"><div class="detail-lbl">Status</div>
      <div class="detail-val" style="color:${p.status==='active'?'var(--green)':'var(--red)'};font-weight:800">${p.status}</div></div>
    <div class="detail-row"><div class="detail-lbl">Added Date</div><div class="detail-val">${p.added||'—'}</div></div>
    <div class="detail-row full">
      <div class="detail-lbl">Stock Bar</div>
      <div style="margin-top:.35rem">
        <div class="stock-bar-bg" style="height:10px">
          <div class="stock-bar-fill" style="width:${getBarWidth(p.stock)}%;background:${getBarColor(p.stock)}"></div>
        </div>
        <div style="font-size:.72rem;color:var(--text-muted);margin-top:.3rem">${p.stock} units remaining</div>
      </div>
    </div>
  `;
  document.getElementById('modalEditLink').href = CTX + '/ProductServlet?action=edit&id=' + p.id;
  document.getElementById('detailModal').classList.add('open');
}
function closeModal() { document.getElementById('detailModal').classList.remove('open'); }

/* ════════════════════════════════════════════════
   EXPORT CSV
════════════════════════════════════════════════ */
function exportCsv() {
  const rows = [['ID','Name','Category','MRP','Final Price','Discount%','Stock','Unit','Status','Added']];
  filteredProducts.forEach(p=>{
    rows.push([p.id, p.name, p.category, p.mrp.toFixed(2), p.final_price.toFixed(2),
      p.discount, p.stock, p.unit, p.status, p.added]);
  });
  const csv = rows.map(r=>r.map(v=>'"'+String(v).replace(/"/g,'""')+'"').join(',')).join('\n');
  const a   = document.createElement('a');
  a.href    = 'data:text/csv;charset=utf-8,\uFEFF'+encodeURIComponent(csv);
  a.download= 'stock_report_'+new Date().toISOString().slice(0,10)+'.csv';
  a.click();
}

/* ── util ── */
function esc(s){ return String(s||'').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;'); }

/* ════════════════════════════════════════════════
   INIT — direct call (AJAX fragment, no DOMContentLoaded)
════════════════════════════════════════════════ */
(function init(){ loadAll(); })();
</script>
