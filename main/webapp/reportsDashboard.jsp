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

  <title>Analytics & Reports — Smart Inventory</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css" rel="stylesheet">
  <link href="https://fonts.googleapis.com/css2?family=Nunito:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
  <style>
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
      --navbar-bg:#0ea5e9; --navbar-height:64px;
      --shadow-sm:0 2px 12px rgba(14,165,233,.08);
      --shadow-md:0 4px 24px rgba(14,165,233,.14);
      --radius:14px; --radius-sm:9px;
    }
    *, *::before, *::after { box-sizing:border-box; margin:0; padding:0; }
    body {
      font-family:'Nunito',sans-serif;
      background:var(--bg-off);
      color:var(--text-dark);
      padding-top:var(--navbar-height);
      min-height:100vh;
    }

    /* ── NAVBAR ── */
    .top-navbar {
      position:fixed; top:0; left:0; right:0; height:var(--navbar-height);
      background:var(--navbar-bg);
      box-shadow:0 2px 16px rgba(14,165,233,.28);
      display:flex; align-items:center; padding:0 1.5rem; z-index:1050; gap:1rem;
    }
    .nav-brand { font-size:1.15rem; font-weight:800; color:#fff; text-decoration:none; }
    .nav-brand span { color:#bae6fd; font-weight:300; }
    .nav-back {
      display:flex; align-items:center; gap:.4rem;
      font-size:.82rem; font-weight:600; color:rgba(255,255,255,.85);
      text-decoration:none; background:rgba(255,255,255,.15);
      border:1px solid rgba(255,255,255,.28); border-radius:8px;
      padding:.35rem .85rem; transition:background .2s;
    }
    .nav-back:hover { background:rgba(255,255,255,.28); color:#fff; }
    .nav-right { margin-left:auto; display:flex; align-items:center; gap:.85rem; }
    .nav-user { font-size:.85rem; color:rgba(255,255,255,.9); }
    .nav-user strong { color:#fff; }
    .badge-role {
      background:rgba(255,255,255,.18); color:#fff;
      border:1px solid rgba(255,255,255,.3);
      font-size:.65rem; font-weight:700; letter-spacing:1px;
      text-transform:uppercase; padding:.18rem .6rem; border-radius:20px;
    }
    .btn-logout {
      font-size:.78rem; font-weight:600; padding:.38rem .95rem;
      border:1.5px solid rgba(255,255,255,.35); border-radius:20px;
      color:#fff; text-decoration:none; transition:all .2s;
    }
    .btn-logout:hover { background:rgba(255,255,255,.2); color:#fff; }

    /* ── PAGE WRAP ── */
    .page-wrap { max-width:1400px; margin:0 auto; padding:2rem 1.75rem; }

    /* ── PAGE HEADER ── */
    .rpt-header {
      background:linear-gradient(135deg,#0369a1 0%,#0ea5e9 55%,#38bdf8 100%);
      border-radius:var(--radius); padding:2rem 2.5rem;
      color:#fff; display:flex; align-items:center; justify-content:space-between;
      flex-wrap:wrap; gap:1rem; margin-bottom:2rem;
      position:relative; overflow:hidden;
      box-shadow:0 8px 32px rgba(14,165,233,.28);
    }
    .rpt-header::before {
      content:''; position:absolute; top:-40px; right:-40px;
      width:220px; height:220px; background:rgba(255,255,255,.06); border-radius:50%;
    }
    .rpt-header::after {
      content:''; position:absolute; bottom:-60px; right:100px;
      width:160px; height:160px; background:rgba(255,255,255,.04); border-radius:50%;
    }
    .rpt-header h1 { font-size:1.6rem; font-weight:800; margin-bottom:.25rem; }
    .rpt-header p  { color:rgba(255,255,255,.8); font-size:.88rem; margin:0; }
    .rpt-label {
      display:inline-flex; align-items:center; gap:.4rem;
      background:rgba(255,255,255,.18); border:1px solid rgba(255,255,255,.28);
      color:#fff; font-size:.7rem; font-weight:700; letter-spacing:1px;
      text-transform:uppercase; padding:.22rem .75rem; border-radius:20px;
      margin-bottom:.6rem;
    }
    .rpt-controls { display:flex; gap:.65rem; align-items:center; flex-wrap:wrap; }
    .rpt-select {
      background:rgba(255,255,255,.15); border:1px solid rgba(255,255,255,.28);
      color:#fff; border-radius:9px; padding:.42rem .95rem;
      font-size:.83rem; font-family:'Nunito',sans-serif; cursor:pointer;
    }
    .rpt-select option { background:#0369a1; }
    .btn-refresh {
      background:rgba(255,255,255,.15); border:1px solid rgba(255,255,255,.28);
      color:#fff; border-radius:9px; padding:.42rem 1rem;
      font-size:.83rem; font-family:'Nunito',sans-serif;
      cursor:pointer; display:flex; align-items:center; gap:.4rem; transition:background .2s;
    }
    .btn-refresh:hover { background:rgba(255,255,255,.3); }
    .last-updated {
      display:inline-flex; align-items:center; gap:.35rem;
      font-size:.72rem; color:rgba(255,255,255,.7);
    }

    /* ── TABS ── */
    .rpt-tabs {
      display:flex; gap:.5rem; margin-bottom:1.75rem;
      flex-wrap:wrap; background:#fff;
      border:1px solid var(--border); border-radius:var(--radius);
      padding:.5rem; box-shadow:var(--shadow-sm);
    }
    .rpt-tab {
      flex:1; min-width:100px;
      padding:.5rem .75rem; border-radius:var(--radius-sm);
      font-size:.8rem; font-weight:600; cursor:pointer;
      color:var(--text-muted); background:transparent; border:none;
      transition:all .18s; display:flex; align-items:center; justify-content:center; gap:.35rem;
      user-select:none; text-align:center;
    }
    .rpt-tab:hover { background:var(--accent-light); color:var(--primary); }
    .rpt-tab.active {
      background:var(--primary); color:#fff;
      box-shadow:0 3px 10px rgba(14,165,233,.35);
    }
    .rpt-tab i { font-size:.85rem; }

    /* ── KPI GRID ── */
    .kpi-grid { display:grid; grid-template-columns:repeat(auto-fit,minmax(195px,1fr)); gap:1.1rem; margin-bottom:1.75rem; }
    .kpi-card {
      background:#fff; border:1px solid var(--border); border-radius:var(--radius);
      padding:1.35rem 1.4rem;
      display:flex; align-items:flex-start; gap:1rem;
      box-shadow:var(--shadow-sm); position:relative; overflow:hidden;
      transition:transform .2s,box-shadow .2s;
    }
    .kpi-card:hover { transform:translateY(-3px); box-shadow:var(--shadow-md); }
    .kpi-card::after {
      content:''; position:absolute; top:0; left:0; right:0;
      height:3px; border-radius:var(--radius) var(--radius) 0 0;
    }
    .kpi-card.blue::after   { background:linear-gradient(90deg,#0ea5e9,#38bdf8); }
    .kpi-card.green::after  { background:linear-gradient(90deg,#16a34a,#4ade80); }
    .kpi-card.amber::after  { background:linear-gradient(90deg,#d97706,#fbbf24); }
    .kpi-card.purple::after { background:linear-gradient(90deg,#7c3aed,#a78bfa); }
    .kpi-card.red::after    { background:linear-gradient(90deg,#dc2626,#f87171); }
    .kpi-card.teal::after   { background:linear-gradient(90deg,#0d9488,#2dd4bf); }
    .kpi-icon {
      width:46px; height:46px; border-radius:12px; flex-shrink:0;
      display:flex; align-items:center; justify-content:center; font-size:1.2rem;
    }
    .kpi-card.blue   .kpi-icon { background:var(--primary-light); color:var(--primary); }
    .kpi-card.green  .kpi-icon { background:var(--green-bg);      color:var(--green);   }
    .kpi-card.amber  .kpi-icon { background:var(--amber-bg);      color:var(--amber);   }
    .kpi-card.purple .kpi-icon { background:var(--purple-bg);     color:var(--purple);  }
    .kpi-card.red    .kpi-icon { background:var(--red-bg);        color:var(--red);     }
    .kpi-card.teal   .kpi-icon { background:var(--teal-bg);       color:var(--teal);    }
    .kpi-body { flex:1; min-width:0; }
    .kpi-label { font-size:.68rem; font-weight:700; letter-spacing:.9px; text-transform:uppercase; color:var(--text-muted); margin-bottom:.3rem; }
    .kpi-value { font-size:1.65rem; font-weight:800; color:var(--text-dark); line-height:1.1; word-break:break-all; }
    .kpi-sub   { font-size:.74rem; color:var(--text-muted); margin-top:.25rem; display:flex; align-items:center; gap:.25rem; flex-wrap:wrap; }
    .up   { color:var(--green); font-weight:700; }
    .down { color:var(--red);   font-weight:700; }

    /* ── CHART CARDS ── */
    .chart-row   { display:grid; gap:1.25rem; margin-bottom:1.25rem; }
    .col-2 { grid-template-columns:1fr 1fr; }
    .col-3 { grid-template-columns:2fr 1fr; }
    .col-1 { grid-template-columns:1fr; }
    .chart-card {
      background:#fff; border:1px solid var(--border); border-radius:var(--radius);
      padding:1.4rem; box-shadow:var(--shadow-sm);
    }
    .cc-head { display:flex; align-items:flex-start; justify-content:space-between; margin-bottom:1.1rem; }
    .cc-title { font-size:.92rem; font-weight:800; color:var(--text-dark); display:flex; align-items:center; gap:.45rem; }
    .cc-title i { color:var(--primary); }
    .cc-sub { font-size:.72rem; color:var(--text-muted); margin-top:.15rem; }
    .cc-badge { background:var(--accent-light); color:var(--primary); font-size:.68rem; font-weight:700; padding:.18rem .65rem; border-radius:20px; white-space:nowrap; }
    .chart-wrap { position:relative; width:300px; }

    /* ── TABLE ── */
    .rpt-table { width:100%; border-collapse:collapse; font-size:.83rem; }
    .rpt-table th {
      background:var(--bg-off); color:var(--text-muted);
      font-size:.68rem; font-weight:700; letter-spacing:.9px; text-transform:uppercase;
      padding:.7rem 1rem; text-align:left; border-bottom:2px solid var(--border);
    }
    .rpt-table td { padding:.65rem 1rem; border-bottom:1px solid var(--border); vertical-align:middle; }
    .rpt-table tr:last-child td { border-bottom:none; }
    .rpt-table tbody tr:hover td { background:var(--accent-light); }

    .rank { width:26px; height:26px; border-radius:50%; display:inline-flex; align-items:center; justify-content:center; font-size:.72rem; font-weight:800; }
    .rank.r1 { background:#fef3c7; color:#b45309; }
    .rank.r2 { background:#f1f5f9; color:#64748b; }
    .rank.r3 { background:#fff7ed; color:#c2410c; }
    .rank.rn { background:var(--primary-light); color:var(--primary); }

    .prog-wrap { height:5px; border-radius:3px; background:var(--border); overflow:hidden; margin-top:3px; min-width:60px; }
    .prog-fill  { height:100%; border-radius:3px; background:linear-gradient(90deg,var(--primary),var(--accent)); transition:width .9s ease; }

    /* ── ATTENDANCE STATS ── */
    .att-grid { display:grid; grid-template-columns:repeat(5,1fr); gap:.9rem; margin-bottom:1.25rem; }
    .att-stat { background:#fff; border:1px solid var(--border); border-radius:var(--radius-sm); padding:1.1rem; text-align:center; box-shadow:var(--shadow-sm); }
    .att-num   { font-size:2rem; font-weight:800; line-height:1; }
    .att-lbl   { font-size:.68rem; color:var(--text-muted); font-weight:700; text-transform:uppercase; letter-spacing:.7px; margin-top:.3rem; }
    .att-stat.s-present .att-num { color:var(--green);  }
    .att-stat.s-late    .att-num { color:var(--amber);  }
    .att-stat.s-absent  .att-num { color:var(--red);    }
    .att-stat.s-half    .att-num { color:var(--purple); }
    .att-stat.s-avg     .att-num { color:var(--primary);}

    /* ── DELIVERY RATE ── */
    .rate-big { text-align:center; padding:1rem 0; }
    .rate-num  { font-size:3rem; font-weight:800; color:var(--primary); line-height:1; }
    .rate-lbl  { font-size:.78rem; color:var(--text-muted); font-weight:600; margin-top:.3rem; }

    /* ── SECTIONS ── */
    .rpt-section { display:none; animation:fadeUp .3s ease; }
    .rpt-section.active { display:block; }
    @keyframes fadeUp { from{opacity:0;transform:translateY(10px)} to{opacity:1;transform:translateY(0)} }

    /* ── SKELETON ── */
    .sk { background:linear-gradient(90deg,#e8f4fd 25%,#d1eaf8 50%,#e8f4fd 75%); background-size:400%; animation:shimmer 1.3s infinite; border-radius:var(--radius); }
    .sk-kpi { height:100px; }
    .sk-chart { height:280px; }
    @keyframes shimmer { 0%{background-position:100%} 100%{background-position:-100%} }

    /* ── ERROR TOAST ── */
    .err-banner {
      display:none; background:#fef2f2; border:1px solid #fecaca;
      border-radius:var(--radius-sm); padding:.85rem 1.25rem;
      color:var(--red); font-size:.85rem; font-weight:600;
      margin-bottom:1.25rem; align-items:center; gap:.5rem;
    }
    .err-banner.show { display:flex; }

    /* ── RESPONSIVE ── */
    @media(max-width:900px){
      .col-2,.col-3 { grid-template-columns:1fr; }
      .att-grid { grid-template-columns:repeat(3,1fr); }
      .kpi-grid { grid-template-columns:repeat(2,1fr); }
    }
    @media(max-width:576px){
      .page-wrap { padding:1rem; }
      .rpt-header { padding:1.25rem 1.1rem; }
      .rpt-header h1 { font-size:1.25rem; }
      .rpt-controls { display:none; }
      .kpi-grid { grid-template-columns:1fr 1fr; gap:.7rem; }
      .kpi-value { font-size:1.35rem; }
      .att-grid { grid-template-columns:repeat(2,1fr); }
      .rpt-tab { font-size:.72rem; padding:.42rem .5rem; min-width:70px; }
    }

    /* spin animation */
    @keyframes spin { to{transform:rotate(360deg)} }
    .spinning { animation:spin .8s linear infinite; display:inline-block; }
  </style>


<!-- ── NAVBAR (no sidebar) ── -->
<nav class="top-navbar">
  <a href="<%=ctxPath%>/dashboard" class="nav-back">
    <i class="bi bi-arrow-left"></i> Dashboard
  </a>
  <a href="<%=ctxPath%>/dashboard" class="nav-brand ms-1">Smart<span>Inventory</span></a>
  <div class="nav-right">
    <div class="nav-user d-none d-md-block">
      Welcome, <strong><%=uname%></strong>
      <span class="badge-role ms-1"><%=role%></span>
    </div>
    <a href="<%=ctxPath%>/logout" class="btn-logout">
      <i class="bi bi-box-arrow-right me-1"></i>Logout
    </a>
  </div>
</nav>

<div class="page-wrap">

  <!-- Error banner -->
  <div class="err-banner" id="errBanner">
    <i class="bi bi-exclamation-triangle-fill"></i>
    <span id="errMsg">Failed to load report data. Please check the server logs.</span>
    <button onclick="loadAll(true)" style="margin-left:auto;background:none;border:none;color:var(--red);font-weight:700;cursor:pointer">Retry</button>
  </div>

  <!-- PAGE HEADER -->
  <div class="rpt-header">
    <div>
      <div class="rpt-label"><i class="bi bi-bar-chart-fill"></i> Analytics</div>
      <h1><i class="bi bi-graph-up-arrow me-2"></i>Reports Dashboard</h1>
      <p>Real-time business intelligence — live from your database</p>
    </div>
    <div class="rpt-controls">
      <select class="rpt-select" id="periodSelect" onchange="loadAll(true)">
        <option value="3">Last 3 Months</option>
        <option value="6">Last 6 Months</option>
        <option value="12" selected>Last 12 Months</option>
      </select>
      <button class="btn-refresh" onclick="loadAll(true)">
        <i class="bi bi-arrow-clockwise" id="refreshIco"></i> Refresh
      </button>
      <span class="last-updated" id="lastUp"><i class="bi bi-clock"></i> Loading…</span>
    </div>
  </div>

  <!-- TABS -->
  <div class="rpt-tabs" role="tablist">
    <button class="rpt-tab active" onclick="switchTab('overview')"   id="tab-overview"><i class="bi bi-speedometer2"></i> Overview</button>
    <button class="rpt-tab"       onclick="switchTab('revenue')"    id="tab-revenue"><i class="bi bi-currency-rupee"></i> Revenue</button>
    <button class="rpt-tab"       onclick="switchTab('products')"   id="tab-products"><i class="bi bi-boxes"></i> Products</button>
    <button class="rpt-tab"       onclick="switchTab('attendance')" id="tab-attendance"><i class="bi bi-person-check"></i> Attendance</button>
    <button class="rpt-tab"       onclick="switchTab('leave')"      id="tab-leave"><i class="bi bi-calendar-x"></i> Leave</button>
    <button class="rpt-tab"       onclick="switchTab('delivery')"   id="tab-delivery"><i class="bi bi-truck"></i> Delivery</button>
    <button class="rpt-tab"       onclick="switchTab('customers')"  id="tab-customers"><i class="bi bi-people"></i> Customers</button>
  </div>

  <!-- ══════════ OVERVIEW ══════════ -->
  <div class="rpt-section active" id="section-overview">
    <div class="kpi-grid" id="kpiGrid">
      <div class="kpi-card sk sk-kpi"></div><div class="kpi-card sk sk-kpi"></div>
      <div class="kpi-card sk sk-kpi"></div><div class="kpi-card sk sk-kpi"></div>
      <div class="kpi-card sk sk-kpi"></div><div class="kpi-card sk sk-kpi"></div>
    </div>
    <div class="chart-row col-3 mb-0">
      <div class="chart-card">
        <div class="cc-head">
          <div><div class="cc-title"><i class="bi bi-graph-up-arrow"></i> Revenue Trend</div><div class="cc-sub">Monthly revenue — selected period</div></div>
          <span class="cc-badge" id="revBadge">12 months</span>
        </div>
        <div class="chart-wrap" style="height:260px"><canvas id="revTrendChart"></canvas></div>
      </div>
      <div class="chart-card">
        <div class="cc-head"><div class="cc-title"><i class="bi bi-pie-chart"></i> Order Status</div></div>
        <div class="chart-wrap" style="height:200px"><canvas id="orderStatusChart"></canvas></div>
        <div id="statusLegend" style="margin-top:.65rem;display:flex;flex-wrap:wrap;gap:.4rem;justify-content:center;font-size:.72rem"></div>
      </div>
    </div>
    <div class="chart-row col-2" style="margin-top:1.25rem">
      <div class="chart-card">
        <div class="cc-head"><div class="cc-title"><i class="bi bi-person-plus"></i> Customer Growth</div></div>
        <div class="chart-wrap" style="height:210px"><canvas id="custGrowthOv"></canvas></div>
      </div>
      <div class="chart-card">
        <div class="cc-head"><div class="cc-title"><i class="bi bi-credit-card"></i> Payment Methods</div></div>
        <div class="chart-wrap" style="height:210px"><canvas id="payOv"></canvas></div>
      </div>
    </div>
  </div>

  <!-- ══════════ REVENUE ══════════ -->
  <div class="rpt-section" id="section-revenue">
    <div class="chart-row col-1">
      <div class="chart-card">
        <div class="cc-head"><div class="cc-title"><i class="bi bi-bar-chart"></i> Monthly Revenue</div></div>
        <div class="chart-wrap" style="height:300px"><canvas id="revBar"></canvas></div>
      </div>
    </div>
    <div class="chart-row col-2">
      <div class="chart-card">
        <div class="cc-head"><div class="cc-title"><i class="bi bi-tag"></i> Revenue by Category</div></div>
        <div class="chart-wrap" style="height:270px"><canvas id="catRevBar"></canvas></div>
      </div>
      <div class="chart-card">
        <div class="cc-head"><div class="cc-title"><i class="bi bi-wallet2"></i> COD vs Online</div></div>
        <div class="chart-wrap" style="height:240px"><canvas id="payDonut"></canvas></div>
      </div>
    </div>
  </div>

  <!-- ══════════ PRODUCTS ══════════ -->
  <div class="rpt-section" id="section-products">
    <div class="chart-row col-3">
      <div class="chart-card">
        <div class="cc-head"><div class="cc-title"><i class="bi bi-trophy"></i> Top Products — Units Sold</div></div>
        <div class="chart-wrap" style="height:280px"><canvas id="topProdChart"></canvas></div>
      </div>
      <div class="chart-card">
        <div class="cc-head"><div class="cc-title"><i class="bi bi-pie-chart-fill"></i> Category Split</div></div>
        <div class="chart-wrap" style="height:240px"><canvas id="catPie"></canvas></div>
      </div>
    </div>
    <div class="chart-card">
      <div class="cc-head"><div class="cc-title"><i class="bi bi-list-ol"></i> Product Leaderboard</div></div>
      <div class="table-responsive">
        <table class="rpt-table" id="prodTable">
          <thead><tr><th>#</th><th>Product</th><th>Units Sold</th><th>Revenue</th><th>Revenue Share</th></tr></thead>
          <tbody></tbody>
        </table>
      </div>
    </div>
  </div>

  <!-- ══════════ ATTENDANCE ══════════ -->
  <div class="rpt-section" id="section-attendance">
    <div class="chart-card mb-3" style="padding:1rem 1.4rem">
      <div class="d-flex align-items-center gap-3 flex-wrap">
        <span style="font-size:.75rem;font-weight:700;text-transform:uppercase;letter-spacing:.7px;color:var(--text-muted)">Filter:</span>
        <input type="date" id="attFrom" class="form-control form-control-sm" style="max-width:155px" onchange="loadAttendance()">
        <span style="color:var(--text-muted);font-size:.85rem">to</span>
        <input type="date" id="attTo"   class="form-control form-control-sm" style="max-width:155px" onchange="loadAttendance()">
      </div>
    </div>
    <div class="att-grid" id="attGrid">
      <div class="att-stat sk sk-kpi"></div><div class="att-stat sk sk-kpi"></div>
      <div class="att-stat sk sk-kpi"></div><div class="att-stat sk sk-kpi"></div>
      <div class="att-stat sk sk-kpi"></div>
    </div>
    <div class="chart-card">
      <div class="cc-head"><div class="cc-title"><i class="bi bi-graph-up"></i> Daily Attendance Trend (30 Days)</div></div>
      <div class="chart-wrap" style="height:290px; width:100%; max-width: 900px;"><canvas id="attTrend"></canvas></div>
    </div>
  </div>

  <!-- ══════════ LEAVE ══════════ -->
  <div class="rpt-section" id="section-leave">
    <div class="kpi-grid" id="leaveKpi">
      <div class="kpi-card sk sk-kpi"></div><div class="kpi-card sk sk-kpi"></div>
      <div class="kpi-card sk sk-kpi"></div><div class="kpi-card sk sk-kpi"></div>
    </div>
    <div class="chart-row col-2">
      <div class="chart-card">
        <div class="cc-head"><div class="cc-title"><i class="bi bi-pie-chart"></i> Leave by Type</div></div>
        <div class="chart-wrap" style="height:270px"><canvas id="leaveType"></canvas></div>
      </div>
      <div class="chart-card">
        <div class="cc-head"><div class="cc-title"><i class="bi bi-bar-chart-steps"></i> Approval Breakdown</div></div>
        <div class="chart-wrap" style="height:270px"><canvas id="leaveStatus"></canvas></div>
      </div>
    </div>
  </div>

  <!-- ══════════ DELIVERY ══════════ -->
  <div class="rpt-section" id="section-delivery">
    <div class="kpi-grid" id="delivKpi" style="grid-template-columns:repeat(auto-fit,minmax(195px,1fr))">
      <div class="kpi-card sk sk-kpi"></div><div class="kpi-card sk sk-kpi"></div>
      <div class="kpi-card sk sk-kpi"></div>
    </div>
    <div class="chart-row col-2">
      <div class="chart-card">
        <div class="cc-head"><div class="cc-title"><i class="bi bi-speedometer"></i> Success Rate</div></div>
        <div class="chart-wrap" style="height:200px"><canvas id="delivRate"></canvas></div>
        <div class="rate-big"><div class="rate-num" id="rateNum">—</div><div class="rate-lbl">Delivery Success Rate</div></div>
      </div>
      <div class="chart-card">
        <div class="cc-head"><div class="cc-title"><i class="bi bi-person-badge"></i> Agent Performance</div></div>
        <div class="chart-wrap" style="height:250px"><canvas id="agentBar"></canvas></div>
      </div>
    </div>
    <div class="chart-card">
      <div class="cc-head"><div class="cc-title"><i class="bi bi-table"></i> Agent Details</div></div>
      <div class="table-responsive">
        <table class="rpt-table" id="agentTable">
          <thead><tr><th>#</th><th>Agent</th><th>Assigned</th><th>Delivered</th><th>In Progress</th><th>Cancelled</th><th>Success %</th></tr></thead>
          <tbody></tbody>
        </table>
      </div>
    </div>
  </div>

  <!-- ══════════ CUSTOMERS ══════════ -->
  <div class="rpt-section" id="section-customers">
    <div class="kpi-grid" style="grid-template-columns:repeat(auto-fit,minmax(195px,1fr));margin-bottom:1.25rem">
      <div class="kpi-card blue" id="custKpi">
        <div class="kpi-icon"><i class="bi bi-people-fill"></i></div>
        <div class="kpi-body">
          <div class="kpi-label">Total Customers</div>
          <div class="kpi-value" id="custTotal">—</div>
          <div class="kpi-sub">All-time registrations</div>
        </div>
      </div>
    </div>
    <div class="chart-card">
      <div class="cc-head"><div class="cc-title"><i class="bi bi-graph-up"></i> Monthly New Registrations</div></div>
      <div class="chart-wrap" style="height:310px"><canvas id="custLine"></canvas></div>
    </div>
  </div>

</div><!-- /page-wrap -->

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
<%  %>
<script>
/* ════════════════════════════════════════════════
   GLOBALS
════════════════════════════════════════════════ */
const CTX = '<%=ctxPath%>';
const charts = {};
/* ════════════════════════════════════════════════
   TABS
════════════════════════════════════════════════ */
function switchTab(tab) {
  document.querySelectorAll('.rpt-section').forEach(s => s.classList.remove('active'));
  document.querySelectorAll('.rpt-tab').forEach(t => t.classList.remove('active'));
  document.getElementById('section-' + tab).classList.add('active');
  document.getElementById('tab-' + tab).classList.add('active');
  if (tab === 'attendance' && !document.getElementById('attFrom').value) {
    initAttDates(); loadAttendance();
  }
}

/* ════════════════════════════════════════════════
   LOAD ALL DATA
════════════════════════════════════════════════ */
/* ════════════════════════════════════════════════
   INIT — direct call because this runs inside an
   AJAX-injected fragment; DOMContentLoaded already
   fired on the parent dashboard shell.
════════════════════════════════════════════════ */
(function init() {
  initAttDates();
  loadAll(false);
})();

async function loadAll(spin) {
  hideErr();
  if (spin) startSpin();
  const months = document.getElementById('periodSelect').value;
  try {
    // Fetch the master payload — single call
    const data = await apiFetch(CTX + '/ReportServlet?action=all&months=' + months);

    renderKPIs(data.overview);
    renderRevTrend(data.revenue_trend || []);
    renderOrderStatus(data.order_status || []);
    renderCustGrowthOv(data.customer_growth || []);
    renderPayOv(data.payment_methods || []);
    renderRevBar(data.revenue_trend || []);
    renderCatRevBar(data.category_revenue || []);
    renderPayDonut(data.payment_methods || []);
    renderTopProducts(data.top_products || []);
    renderAttendance(data.attendance || {}, data.att_trend || []);
    renderLeave(data.leave || {}, data.leave_by_type || []);
    renderDelivery(data.agents || [], data.delivery_rate || {}, data.overview || {});
    renderCustomers(data.overview || {}, data.customer_growth || []);

    document.getElementById('revBadge').textContent = months + ' months';
    document.getElementById('lastUp').innerHTML =
      '<i class="bi bi-clock"></i> ' + new Date().toLocaleTimeString();
  } catch (err) {
    showErr('Report load error: ' + err.message +
      '. Ensure ReportServlet is deployed and database is connected.');
    console.error(err);
  } finally {
    stopSpin();
  }
}

/* Safe fetch with good error messages */
async function apiFetch(url) {
  const res = await fetch(url, { headers: { 'X-Requested-With': 'XMLHttpRequest' } });
  const text = await res.text();
  if (!text || text.trim() === '') {
    throw new Error('Server returned empty response. Check server logs for SQL/auth errors.');
  }
  let json;
  try { json = JSON.parse(text); }
  catch (e) {
    // Print first 300 chars of unexpected response (usually HTML error page)
    throw new Error('Invalid JSON from server. Response: ' + text.substring(0, 300));
  }
  if (!res.ok || json.error) throw new Error(json.error || 'HTTP ' + res.status);
  return json;
}

/* ════════════════════════════════════════════════
   KPI CARDS
════════════════════════════════════════════════ */
function renderKPIs(ov) {
  if (!ov) return;
  const chg = ov.revenue_change_pct || 0;
  const chgHtml = chg >= 0
    ? `<span class="up"><i class="bi bi-arrow-up-short"></i>${chg}%</span> vs last month`
    : `<span class="down"><i class="bi bi-arrow-down-short"></i>${Math.abs(chg)}%</span> vs last month`;

  document.getElementById('kpiGrid').innerHTML = [
    kpi('blue',  'currency-rupee',  'Total Revenue',     '₹' + fmt(ov.total_revenue),   chgHtml),
    kpi('green', 'bag-check',       'Total Orders',      fmtN(ov.total_orders),          fmtN(ov.orders_this_month) + ' this month'),
    kpi('purple','people-fill',     'Customers',         fmtN(ov.total_customers),       'Registered users'),
    kpi('amber', 'truck',           'Delivery Rate',     (ov.delivery_rate || 0) + '%',  fmtN(ov.total_agents) + ' active agents'),
    kpi('teal',  'boxes',           'Active Products',   fmtN(ov.total_products),        '<span class="'+(ov.low_stock_count>0?'down':'up')+'">' + ov.low_stock_count + '</span> low stock'),
    kpi('red',   'calendar-x',      'Leave Pending',     fmtN(ov.leave_pending),         'Awaiting approval'),
  ].join('');
}

function kpi(color, icon, label, value, sub) {
  return `<div class="kpi-card ${color}">
    <div class="kpi-icon"><i class="bi bi-${icon}"></i></div>
    <div class="kpi-body">
      <div class="kpi-label">${label}</div>
      <div class="kpi-value">${value}</div>
      <div class="kpi-sub">${sub}</div>
    </div>
  </div>`;
}

/* ════════════════════════════════════════════════
   CHARTS
════════════════════════════════════════════════ */
const PALETTE = ['#0ea5e9','#16a34a','#d97706','#7c3aed','#dc2626','#0d9488','#f59e0b','#6366f1','#ec4899'];

function renderRevTrend(data) {
  mkLine('revTrendChart', data.map(d=>d.month), [
    {label:'Revenue (₹)', data:data.map(d=>d.revenue),
     borderColor:'#0ea5e9', bg:'rgba(14,165,233,.12)'}
  ], v => '₹' + fmtK(v));
}

function renderRevBar(data) {
  mkBar('revBar', data.map(d=>d.month), [
    {label:'Revenue', data:data.map(d=>d.revenue),
     backgroundColor: data.map((_,i)=>`hsl(${200+i*9},65%,52%)`), borderRadius:6}
  ], v => '₹' + fmtK(v));
}

function renderOrderStatus(data) {
  mkDoughnut('orderStatusChart', data.map(d=>capFirst(d.status)), data.map(d=>d.count), PALETTE);
  const leg = document.getElementById('statusLegend');
  leg.innerHTML = data.map((d,i) =>
    `<span style="display:inline-flex;align-items:center;gap:.3rem;padding:.18rem .55rem;background:${PALETTE[i]}18;border-radius:20px;color:${PALETTE[i]};font-weight:700">
      <span style="width:7px;height:7px;border-radius:50%;background:${PALETTE[i]};display:inline-block"></span>${capFirst(d.status)} (${d.count})</span>`
  ).join('');
}

function renderCustGrowthOv(data) {
  mkBar('custGrowthOv', data.map(d=>d.month), [
    {label:'New Customers', data:data.map(d=>d.count), backgroundColor:'rgba(124,58,237,.72)', borderRadius:6}
  ]);
}

function renderPayOv(data) {
  mkDoughnut('payOv', data.map(d=>d.method), data.map(d=>d.revenue), ['#0ea5e9','#16a34a']);
}

function renderCatRevBar(data) {
  mkBar('catRevBar', data.map(d=>d.category),
    [{label:'Revenue', data:data.map(d=>d.revenue), backgroundColor:PALETTE.slice(0,data.length), borderRadius:6}],
    v => '₹' + fmtK(v), true);
}

function renderPayDonut(data) {
  mkDoughnut('payDonut', data.map(d=>d.method), data.map(d=>d.revenue), ['#0ea5e9','#16a34a']);
}

function renderTopProducts(data) {
  mkBar('topProdChart', data.map(d=>shorten(d.name,18)), [
    {label:'Units Sold', data:data.map(d=>d.units_sold), backgroundColor:'rgba(14,165,233,.75)', borderRadius:6}
  ], null, true);

  const totalRev = data.reduce((s,d)=>s+d.revenue,0) || 1;
  document.querySelector('#prodTable tbody').innerHTML = data.map((d,i) => {
    const pct = Math.round(d.revenue / totalRev * 100);
    const rClass = i===0?'r1':i===1?'r2':i===2?'r3':'rn';
    return `<tr>
      <td><span class="rank ${rClass}">${i+1}</span></td>
      <td><strong>${d.name}</strong></td>
      <td>${fmtN(d.units_sold)} units</td>
      <td>₹${fmt(d.revenue)}</td>
      <td>
        <div style="font-size:.8rem;font-weight:800;color:var(--primary)">${pct}%</div>
        <div class="prog-wrap"><div class="prog-fill" style="width:${pct}%"></div></div>
      </td>
    </tr>`;
  }).join('');
  mkDoughnut('catPie', data.map(d=>shorten(d.name,14)), data.map(d=>d.units_sold), PALETTE);
}

/* ── Attendance ── */
function initAttDates() {
  const today = new Date().toISOString().split('T')[0];
  const first = new Date(); first.setDate(1);
  document.getElementById('attFrom').value = first.toISOString().split('T')[0];
  document.getElementById('attTo').value   = today;
}

async function loadAttendance() {
  const from = document.getElementById('attFrom').value;
  const to   = document.getElementById('attTo').value;
  if (!from || !to) return;
  try {
    const data = await apiFetch(CTX + `/ReportServlet?action=attendance&from=${from}&to=${to}`);
    renderAttendance(data.summary || {}, data.trend || []);
  } catch(e) { showErr('Attendance load: ' + e.message); }
}

function renderAttendance(s, trend) {
  document.getElementById('attGrid').innerHTML = `
    <div class="att-stat s-present"><div class="att-num">${s.present||0}</div><div class="att-lbl">Present</div></div>
    <div class="att-stat s-late">   <div class="att-num">${s.late||0}</div>   <div class="att-lbl">Late</div></div>
    <div class="att-stat s-absent"> <div class="att-num">${s.absent||0}</div> <div class="att-lbl">Absent</div></div>
    <div class="att-stat s-half">   <div class="att-num">${s.half_day||0}</div><div class="att-lbl">Half Day</div></div>
    <div class="att-stat s-avg">    <div class="att-num">${s.avg_hours||0}h</div><div class="att-lbl">Avg Hours</div></div>
  `;
  mkLine('attTrend', trend.map(d=>d.date), [
    {label:'Present', data:trend.map(d=>d.present), borderColor:'#16a34a', bg:'rgba(22,163,74,.1)'},
    {label:'Late',    data:trend.map(d=>d.late),    borderColor:'#d97706', bg:'rgba(217,119,6,.08)'},
    {label:'Absent',  data:trend.map(d=>d.absent),  borderColor:'#dc2626', bg:'rgba(220,38,38,.08)'},
  ]);
}

/* ── Leave ── */
function renderLeave(s, byType) {
  document.getElementById('leaveKpi').innerHTML = [
    kpi('blue',  'calendar-check', 'Total Applied', fmtN(s.total),    'This year'),
    kpi('green', 'check-circle',   'Approved',      fmtN(s.approved), fmtN(s.approved_days) + ' days'),
    kpi('amber', 'clock-history',  'Pending',       fmtN(s.pending),  'Awaiting decision'),
    kpi('red',   'x-circle',       'Rejected',      fmtN(s.rejected), 'This year'),
  ].join('');
  mkDoughnut('leaveType', byType.map(d=>d.type_name), byType.map(d=>d.used_days), PALETTE);
  mkBar('leaveStatus', ['Approved','Pending','Rejected'],
    [{label:'Requests', data:[s.approved,s.pending,s.rejected],
      backgroundColor:['#16a34a','#d97706','#dc2626'], borderRadius:8}]);
}

/* ── Delivery ── */
function renderDelivery(agents, rate, ov) {
  document.getElementById('delivKpi').innerHTML = [
    kpi('blue',  'truck',          'Active Agents',   fmtN(ov.total_agents),  'On fleet'),
    kpi('green', 'check2-circle',  'Success Rate',    (rate.rate||0) + '%',    fmtN(rate.delivered) + ' delivered'),
    kpi('amber', 'hourglass-split','In Transit',      fmtN((rate.total||0)-(rate.delivered||0)), 'Remaining'),
  ].join('');

  mkDoughnut('delivRate',
    ['Delivered','Remaining'],
    [rate.delivered||0, Math.max(0,(rate.total||0)-(rate.delivered||0))],
    ['#16a34a','#fee2e2']
  );
  document.getElementById('rateNum').textContent = (rate.rate || 0) + '%';

  const top5 = agents.slice(0, 5);
  mkBar('agentBar', top5.map(a=>a.agent_name), [
    {label:'Delivered',   data:top5.map(a=>a.delivered),   backgroundColor:'#16a34a', borderRadius:4},
    {label:'In Progress', data:top5.map(a=>a.in_progress), backgroundColor:'#d97706', borderRadius:4},
    {label:'Cancelled',   data:top5.map(a=>a.cancelled),   backgroundColor:'#dc2626', borderRadius:4},
  ], null, false, true);

  document.querySelector('#agentTable tbody').innerHTML = agents.map((a,i) => {
    const succ = a.total_deliveries > 0 ? Math.round(a.delivered/a.total_deliveries*100) : 0;
    const col   = succ>=80?'var(--green)':succ>=50?'var(--amber)':'var(--red)';
    const rClass = i===0?'r1':i===1?'r2':i===2?'r3':'rn';
    return `<tr>
      <td><span class="rank ${rClass}">${i+1}</span></td>
      <td><strong>${a.agent_name}</strong></td>
      <td>${fmtN(a.total_deliveries)}</td>
      <td style="color:var(--green);font-weight:700">${fmtN(a.delivered)}</td>
      <td style="color:var(--amber);font-weight:700">${fmtN(a.in_progress)}</td>
      <td style="color:var(--red);font-weight:700">${fmtN(a.cancelled)}</td>
      <td>
        <div style="font-size:.85rem;font-weight:800;color:${col}">${succ}%</div>
        <div class="prog-wrap"><div class="prog-fill" style="width:${succ}%;background:${succ>=80?'#16a34a':succ>=50?'#d97706':'#dc2626'}"></div></div>
      </td>
    </tr>`;
  }).join('');
}

/* ── Customers ── */
function renderCustomers(ov, data) {
  document.getElementById('custTotal').textContent = fmtN(ov.total_customers);
  mkLine('custLine', data.map(d=>d.month), [
    {label:'New Customers', data:data.map(d=>d.count),
     borderColor:'#7c3aed', bg:'rgba(124,58,237,.12)'}
  ]);
}

/* ════════════════════════════════════════════════
   CHART FACTORY — Modern 3D-style
════════════════════════════════════════════════ */

/* Deep merge helper */
function merge(a, b) {
  const out = Object.assign({}, a);
  for (const k in b) {
    if (b[k] && typeof b[k]==='object' && !Array.isArray(b[k]))
      out[k] = merge(a[k]||{}, b[k]);
    else out[k] = b[k];
  }
  return out;
}

/* Base config shared by all chart types */
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
    x:{
      grid:{ color:'rgba(14,165,233,.04)', drawBorder:false },
      ticks:{ color:'#64748b', font:{family:'Nunito',size:10} },
      border:{ display:false }
    },
    y:{
      grid:{ color:'rgba(14,165,233,.07)', drawBorder:false },
      ticks:{ color:'#64748b', font:{family:'Nunito',size:10} },
      border:{ display:false },
      beginAtZero:true
    }
  }
};

/* Vertical gradient fill for area charts / bar tops */
function _vertGrad(ctx, color1, color2) {
  const g = ctx.createLinearGradient(0, 0, 0, ctx.canvas.clientHeight || 300);
  g.addColorStop(0, color1);
  g.addColorStop(1, color2);
  return g;
}

/* Per-bar column gradient (top→bottom hue shift for 3D depth feel) */
function _barGrads(ctx, baseHex, count) {
  const h = ctx.canvas.clientHeight || 280;
  return Array.from({length: count}, (_, i) => {
    const hue = 200 + i * 8;
    const g = ctx.createLinearGradient(0, 0, 0, h);
    g.addColorStop(0,   `hsla(${hue},78%,62%,1)`);
    g.addColorStop(0.5, `hsla(${hue},70%,48%,1)`);
    g.addColorStop(1,   `hsla(${hue},64%,34%,1)`);
    return g;
  });
}

/* Horizontal bar gradient (left→right for product leaderboard) */
function _hBarGrads(ctx, count) {
  const w = ctx.canvas.clientWidth || 400;
  return Array.from({length: count}, (_, i) => {
    const hue = 195 + i * 10;
    const g = ctx.createLinearGradient(0, 0, w, 0);
    g.addColorStop(0, `hsla(${hue},74%,46%,.92)`);
    g.addColorStop(1, `hsla(${hue},58%,64%,.45)`);
    return g;
  });
}

/* ── Line / Area ── */
function mkLine(id, labels, series, yFmt) {
  kill(id);
  const el = document.getElementById(id); if(!el) return;
  const ctx = el.getContext('2d');
  charts[id] = new Chart(ctx, {
    type:'line',
    data:{ labels, datasets: series.map(s => {
      const areaGrad = s.bg
        ? _vertGrad(ctx, s.bg.replace(/[\d.]+\)$/, '.38)'), s.bg.replace(/[\d.]+\)$/, '.01)'))
        : 'transparent';
      return {
        label: s.label, data: s.data,
        borderColor: s.borderColor,
        backgroundColor: areaGrad,
        borderWidth: 2.5,
        fill: !!s.bg,
        tension: .42,
        pointRadius: 3.5,
        pointBackgroundColor: '#fff',
        pointBorderColor: s.borderColor,
        pointBorderWidth: 2,
        pointHoverRadius: 6,
        pointHoverBackgroundColor: s.borderColor,
        pointHoverBorderColor: '#fff',
        pointHoverBorderWidth: 2
      };
    })},
    options: merge(BASE_OPTS, yFmt ? {scales:{y:{ticks:{callback:yFmt}}}} : {})
  });
}

/* ── Bar (vertical, horizontal, stacked) ── */
function mkBar(id, labels, datasets, yFmt, horizontal, stacked) {
  kill(id);
  const el = document.getElementById(id); if(!el) return;
  const ctx = el.getContext('2d');

  /* Apply 3D column gradients to single-color vertical bars */
  const styledDatasets = datasets.map(ds => {
    const out = Object.assign({}, ds);
    /* rounded top corners */
    if (!stacked && !out.borderRadius) out.borderRadius = 8;
    if (!out.borderSkipped) out.borderSkipped = false;
    out.borderWidth = out.borderWidth ?? 0;

    /* gradient columns when a single solid background color is given */
    if (!horizontal && !stacked && typeof out.backgroundColor === 'string') {
      out.backgroundColor = _barGrads(ctx, out.backgroundColor, labels.length);
    }
    /* gradient rows for horizontal bars */
    if (horizontal && typeof out.backgroundColor === 'string') {
      out.backgroundColor = _hBarGrads(ctx, labels.length);
    }
    return out;
  });

  const extra = {};
  if (horizontal) extra.indexAxis = 'y';
  if (stacked) {
    extra.scales = {
      x:{ stacked:true, grid:{display:false} },
      y:{ stacked:true }
    };
  }
  if (yFmt && !stacked) extra.scales = { y:{ ticks:{ callback:yFmt } } };

  charts[id] = new Chart(ctx, {
    type:'bar',
    data:{ labels, datasets: styledDatasets },
    options: merge(BASE_OPTS, extra)
  });
}

/* ── Doughnut ── */
function mkDoughnut(id, labels, data, colors) {
  kill(id);
  const el = document.getElementById(id); if(!el) return;
  charts[id] = new Chart(el, {
    type:'doughnut',
    data:{ labels, datasets:[{
      data,
      backgroundColor: colors,
      borderWidth: 4,
      borderColor: '#fff',
      hoverOffset: 12,
      borderRadius: 6,
      hoverBorderWidth: 0
    }]},
    options: merge(BASE_OPTS, {
      cutout: '68%',
      scales: {},
      plugins:{
        legend:{
          display: true,
          position: 'bottom',
          labels:{
            font:{ family:'Nunito', size:11 },
            color:'#64748b',
            padding:14,
            usePointStyle:true,
            pointStyle:'rectRounded',
            boxWidth:10,
            boxHeight:10
          }
        }
      }
    })
  });
}

function kill(id) { if(charts[id]) { charts[id].destroy(); delete charts[id]; } }

/* ════════════════════════════════════════════════
   UTILITIES
════════════════════════════════════════════════ */
function fmt(n)   { return Number(n||0).toLocaleString('en-IN',{maximumFractionDigits:0}); }
function fmtN(n)  { return Number(n||0).toLocaleString('en-IN'); }
function fmtK(v)  { return v>=100000?Math.round(v/1000)+'K':v>=1000?(Math.round(v/100)/10)+'K':Math.round(v); }
function capFirst(s){ return s?(s.charAt(0).toUpperCase()+s.slice(1).replace(/_/g,' ')):''; }
function shorten(s,n){ return s && s.length>n ? s.slice(0,n)+'…' : s; }

/* ── Error banner ── */
function showErr(msg) { document.getElementById('errMsg').textContent=msg; document.getElementById('errBanner').classList.add('show'); }
function hideErr()    { document.getElementById('errBanner').classList.remove('show'); }

/* ── Refresh spinner ── */
function startSpin() { document.getElementById('refreshIco').classList.add('spinning'); }
function stopSpin()  { document.getElementById('refreshIco').classList.remove('spinning'); }
</script>
