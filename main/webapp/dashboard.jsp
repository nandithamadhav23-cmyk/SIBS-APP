<%@ page contentType="text/html; charset=UTF-8" isELIgnored="true" %>
<%@ page import="java.util.*, com.util.*" %>

<%
    String role  = (session != null) ? (String) session.getAttribute("role")     : null;
    String uname = (session != null) ? (String) session.getAttribute("username") : null;
    User   user  = (session != null) ? (User)   session.getAttribute("user")     : null;

    if (role == null || !"admin".equalsIgnoreCase(role)) {
        response.sendRedirect(request.getContextPath() + "/index.jsp?error=Access+denied.+Please+login+as+admin.");
        return;
    }
    String successMsg = (String) session.getAttribute("success");
    if (successMsg != null) session.removeAttribute("success");
    String Msg = (String) session.getAttribute("msg");
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Admin Dashboard — Smart Inventory</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css" rel="stylesheet">
  <link href="https://fonts.googleapis.com/css2?family=Nunito:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
  <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
  
  <style>
    :root {
      --primary:#0ea5e9; --primary-dark:#0369a1; --primary-light:#e0f2fe;
      --accent:#38bdf8; --accent-light:#f0f9ff;
      --text-dark:#0c1a2e; --text-mid:#1e3a5f; --text-muted:#64748b;
      --border:#dbeafe; --bg-white:#ffffff; --bg-off:#f0f9ff;
      --sidebar-bg:#ffffff; --navbar-bg:#0ea5e9;
      --sidebar-width:250px; --navbar-height:64px;
      --shadow-sm:0 2px 12px rgba(14,165,233,.08);
      --shadow-md:0 4px 24px rgba(14,165,233,.13);
      --radius:10px;
    }
    *{box-sizing:border-box}
    body{font-family:'Nunito',sans-serif;background:var(--bg-off);color:var(--text-dark);margin:0;padding-top:var(--navbar-height);display:flex;flex-direction:column;min-height:100vh}

    /* ── NAVBAR ── */
    .top-navbar{position:fixed;top:0;left:0;right:0;height:var(--navbar-height);background:var(--navbar-bg);border-bottom:none;box-shadow:0 2px 16px rgba(14,165,233,.25);display:flex;align-items:center;padding:0 1.5rem;z-index:1050;gap:1rem}
    .nav-brand{font-family:'Nunito',sans-serif;font-size:1.2rem;font-weight:800;color:#fff;letter-spacing:.5px;text-decoration:none;white-space:nowrap}
    .nav-brand span{color:#bae6fd;font-weight:300}
    .nav-right{margin-left:auto;display:flex;align-items:center;gap:1rem}
    .nav-user-info{font-family:'Nunito',sans-serif;font-size:.9rem;color:rgba(255,255,255,.9)}
    .nav-user-info strong{color:#fff;font-weight:700}
    .badge-role{background:rgba(255,255,255,.18);color:#fff;border:1px solid rgba(255,255,255,.35);font-size:.68rem;letter-spacing:1px;text-transform:uppercase;padding:.2rem .65rem;border-radius:20px;font-weight:600}
    .btn-bell{position:relative;width:38px;height:38px;background:rgba(255,255,255,.15);border:1px solid rgba(255,255,255,.2);border-radius:50%;display:flex;align-items:center;justify-content:center;color:#fff;font-size:1rem;text-decoration:none;transition:background .2s}
    .btn-bell:hover{background:rgba(255,255,255,.28);color:#fff}
    .bell-badge{position:absolute;top:-3px;right:-3px;background:#ef4444;color:#fff;font-size:.55rem;font-weight:700;min-width:16px;height:16px;border-radius:50%;display:flex;align-items:center;justify-content:center;border:2px solid var(--navbar-bg)}
    .btn-logout{font-family:'Nunito',sans-serif;font-size:.78rem;font-weight:600;letter-spacing:.5px;padding:.4rem 1rem;border:1.5px solid rgba(255,255,255,.35);border-radius:20px;color:#fff;text-decoration:none;transition:all .2s}
    .btn-logout:hover{background:rgba(255,255,255,.18);border-color:#fff;color:#fff}
    .btn-sidebar-toggle{display:flex;align-items:center;justify-content:center;width:36px;height:36px;background:rgba(255,255,255,.15);border:1.5px solid rgba(255,255,255,.25);border-radius:8px;color:#fff;padding:0;cursor:pointer;transition:background .2s,border-color .2s;flex-shrink:0}
    .btn-sidebar-toggle:hover{background:rgba(255,255,255,.28);border-color:rgba(255,255,255,.5)}
    .btn-sidebar-toggle i{font-size:1.15rem;transition:transform .25s}

    /* ── SIDEBAR ── */
    .sidebar{position:fixed;top:var(--navbar-height);left:0;bottom:0;width:var(--sidebar-width);background:var(--sidebar-bg);border-right:1px solid var(--border);padding:1.25rem .75rem;overflow-y:auto;z-index:900;transition:transform .3s ease,width .3s ease;box-shadow:2px 0 16px rgba(14,165,233,.06)}
    .sidebar.collapsed{transform:translateX(-100%)}
    .sidebar-overlay{display:none;position:fixed;inset:0;top:var(--navbar-height);background:rgba(14,165,233,.18);backdrop-filter:blur(2px);z-index:850;opacity:0;transition:opacity .3s ease}
    .sidebar-overlay.visible{opacity:1}
    .sidebar-section-label{font-family:'Nunito',sans-serif;font-size:.63rem;font-weight:700;letter-spacing:2px;text-transform:uppercase;color:var(--accent);padding:.6rem .8rem .25rem;margin-top:.75rem}
    .sidebar-nav-link{display:flex;align-items:center;gap:.7rem;padding:.6rem .85rem;margin-bottom:2px;border-radius:var(--radius);font-family:'Nunito',sans-serif;font-size:.88rem;font-weight:500;color:var(--text-mid);text-decoration:none;transition:all .18s;border-left:none}
    .sidebar-nav-link:hover{background:var(--accent-light);color:var(--primary-dark)}
    .sidebar-nav-link.active{background:var(--primary-light);color:var(--primary-dark);font-weight:700;box-shadow:inset 3px 0 0 var(--primary)}
    .sidebar-nav-link i{font-size:.95rem;width:20px;text-align:center;color:var(--text-muted)}
    .sidebar-nav-link:hover i,.sidebar-nav-link.active i{color:var(--primary)}

    /* ── MAIN ── */
    .main-content{margin-left:var(--sidebar-width);padding:1.8rem 2rem;flex-grow:1;min-height:calc(100vh - var(--navbar-height));transition:margin-left .3s ease}
    .sidebar-collapsed .main-content{margin-left:0}

    /* ── BREADCRUMB ── */
    .breadcrumb{background:transparent;padding:0;margin-bottom:1.5rem}
    .breadcrumb-item{font-family:'Nunito',sans-serif;font-size:.82rem;font-weight:500}
    .breadcrumb-item a{color:var(--text-muted);text-decoration:none}
    .breadcrumb-item a:hover{color:var(--primary)}
    .breadcrumb-item.active{color:var(--text-dark)}
    .breadcrumb-item+.breadcrumb-item::before{color:var(--border)}

    /* ── WELCOME PANEL ── */
    .welcome-panel{background:var(--bg-white);border:1px solid var(--border);border-top:4px solid var(--accent);border-radius:var(--radius);padding:2.5rem 2rem;text-align:center;box-shadow:var(--shadow-sm)}
    .welcome-title{font-family:'Nunito',sans-serif;font-size:1.75rem;font-weight:800;color:var(--text-dark);margin-bottom:.5rem}
    .welcome-sub{color:var(--text-muted);font-size:.95rem;font-weight:500}
    .quick-stat-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(140px,1fr));gap:1rem;margin-top:2rem}
    .quick-stat{background:var(--bg-off);border:1.5px solid var(--border);border-radius:var(--radius);padding:1.2rem 1rem;text-align:center;cursor:pointer;transition:all .2s}
    .quick-stat:hover{border-color:var(--accent);background:var(--accent-light);transform:translateY(-2px);box-shadow:var(--shadow-sm)}
    .quick-stat i{font-size:1.6rem;color:var(--primary);display:block;margin-bottom:.5rem}
    .quick-stat span{font-family:'Nunito',sans-serif;font-size:.75rem;font-weight:700;letter-spacing:.5px;text-transform:uppercase;color:var(--text-muted)}

    /* ── SPINNER ── */
    .spinner{display:none;text-align:center;padding:3rem}
    .spinner-border{color:var(--accent)!important}

    /* ── TOAST ── */
    .big-toast{font-family:'Nunito',sans-serif;font-size:.95rem;font-weight:600;border-radius:var(--radius);box-shadow:var(--shadow-md)}

    /* ── FOOTER ── */
    footer{background:var(--primary-dark);color:rgba(255,255,255,.65);font-family:'Nunito',sans-serif;font-size:.82rem;font-weight:500;text-align:center;padding:1rem;border-top:none;margin-left:var(--sidebar-width);transition:margin-left .3s ease}
    footer span{color:#bae6fd;font-weight:700}
    .sidebar-collapsed footer{margin-left:0}

    @media(max-width:992px){
      .main-content{margin-left:0}
      footer{margin-left:0}
      .sidebar-collapsed .main-content{margin-left:0}
      .sidebar-collapsed footer{margin-left:0}
    }

    /* ══════════════════════════════════════════════════════════════
       ADMIN ATTENDANCE MONITOR  (updated — mirrors dashboard_5_ style)
    ══════════════════════════════════════════════════════════════ */

    /* Google font for the monitor sub-section */
    @import url('https://fonts.googleapis.com/css2?family=Nunito:wght@300;400;500;600;700;800&display=swap');

    /* Scoped tokens (don't override the outer dashboard) */
    .att-monitor-panel {
      --am-brand:    #0ea5e9;
      --am-brand-lt: #e0f2fe;
      --am-brand-dk: #0369a1;
      --am-green:    #16a34a; --am-green-bg: #dcfce7; --am-green-dot: #22c55e;
      --am-amber:    #b45309; --am-amber-bg: #fef3c7; --am-amber-dot: #f59e0b;
      --am-red:      #b91c1c; --am-red-bg:   #fee2e2; --am-red-dot:   #ef4444;
      --am-blue:     #0369a1; --am-blue-bg:  #e0f2fe;
      --am-slate:    #64748b; --am-slate-lt: #f0f9ff;
      --am-text1:    #0c1a2e; --am-text2: #1e3a5f; --am-text3: #64748b;
      --am-border:   #dbeafe;
      --am-card:     #ffffff;
      --am-card-sh:  0 4px 24px rgba(14,165,233,.10);
      --am-radius:   14px; --am-radius-sm: 10px;
      --am-font:     'Nunito', sans-serif;
      --am-font-d:   'Nunito', sans-serif;
    }

    .att-monitor-panel {
      background: #f0f9ff;
      background-image:
        radial-gradient(ellipse 80% 60% at 20% -10%, rgba(14,165,233,.07) 0%, transparent 70%),
        radial-gradient(ellipse 60% 50% at 80% 110%, rgba(22,163,74,.04) 0%, transparent 60%);
      border: 1px solid var(--border);
      border-top: 3px solid #0ea5e9;
      border-radius: 4px;
      box-shadow: var(--shadow-sm);
      margin-bottom: 1.5rem;
      overflow: hidden;
      font-family: 'Nunito', sans-serif;
    }

    /* ── Panel header ── */
    .att-monitor-header {
      background: rgba(255,255,255,0.72);
      backdrop-filter: blur(14px);
      -webkit-backdrop-filter: blur(14px);
      border-bottom: 1px solid rgba(255,255,255,.9);
      padding: .9rem 1.5rem;
      display: flex; align-items: center; justify-content: space-between;
      flex-wrap: wrap; gap: .75rem;
      box-shadow: 0 1px 8px rgba(99,107,157,.08);
    }
    .att-monitor-title {
      font-family: 'Nunito', sans-serif;
      font-size: 1.1rem; color: var(--am-text1, #0f172a);
      display: flex; align-items: center; gap: .55rem;
    }
    .att-monitor-title i { color: #0ea5e9; }
    .att-monitor-sub { font-size: .72rem; color: var(--am-text3, #64748b); margin-top: 2px; }
    .att-monitor-live {
      display: flex; align-items: center; gap: .5rem;
      font-size: .75rem; font-weight: 600; color: #0369a1;
      background: #e0f2fe; border: 1px solid rgba(91,94,244,.18);
      border-radius: 20px; padding: 4px 12px;
    }
    .att-live-dot {
      width: 8px; height: 8px; border-radius: 50%;
      background: #22c55e; position: relative; flex-shrink: 0;
    }
    .att-live-dot::after {
      content: ''; position: absolute; inset: -3px; border-radius: 50%;
      background: rgba(34,197,94,.35); animation: am-pulse 1.8s ease infinite;
    }
    @keyframes am-pulse {
      0%   { opacity:.8; transform: scale(1); }
      70%  { opacity:0;  transform: scale(1.9); }
      100% { opacity:0;  transform: scale(1.9); }
    }

    /* ── Office rules strip ── */
    .att-rules-strip {
      display: flex; align-items: center; gap: 1.25rem; flex-wrap: wrap;
      padding: .55rem 1.5rem;
      background: rgba(255,255,255,.55);
      border-bottom: 1px solid #e2e8f0;
    }
    .att-rule-chip {
      display: inline-flex; align-items: center; gap: .3rem;
      font-size: .68rem; font-weight: 600; color: #334155;
      background: #f1f5f9; border: 1px solid #e2e8f0;
      border-radius: 20px; padding: 2px 10px;
    }
    .att-rule-chip i { color: #0ea5e9; font-size: .72rem; }
    .att-rule-chip b { color: #0f172a; }

    /* ── KPI cards (compact) ── */
    .att-kpi-row {
      display: grid;
      grid-template-columns: repeat(7, 1fr);
      gap: 8px; padding: .75rem 1rem;
      background: #f0f9ff;
      border-bottom: 1px solid #dbeafe;
    }
    @media(max-width:900px){ .att-kpi-row{ grid-template-columns: repeat(4,1fr); } }
    @media(max-width:540px){ .att-kpi-row{ grid-template-columns: repeat(2,1fr); } }
    .att-kpi {
      background: #fff; border-radius: 10px;
      border: 1px solid #dbeafe;
      box-shadow: 0 2px 8px rgba(14,165,233,.07);
      padding: 10px 12px; display: flex; flex-direction: column; gap: 6px;
      position: relative; overflow: hidden;
      transition: box-shadow .2s, transform .15s;
    }
    .att-kpi:hover { box-shadow: 0 4px 16px rgba(14,165,233,.14); transform: translateY(-2px); }
    .att-kpi::before {
      content: ''; position: absolute; top: 0; left: 0; right: 0;
      height: 3px; border-radius: 14px 14px 0 0;
    }
    .att-kpi.kpi-in::before    { background: linear-gradient(90deg,#22c55e,#4ade80); }
    .att-kpi.kpi-brk::before   { background: linear-gradient(90deg,#f59e0b,#fcd34d); }
    .att-kpi.kpi-abs::before   { background: linear-gradient(90deg,#ef4444,#f87171); }
    .att-kpi.kpi-out::before   { background: linear-gradient(90deg,#0ea5e9,#38bdf8); }
    .att-kpi.kpi-full::before  { background: linear-gradient(90deg,#22c55e,#4ade80); }
    .att-kpi.kpi-half::before  { background: linear-gradient(90deg,#0891b2,#06b6d4); }
    .att-kpi.kpi-late::before  { background: linear-gradient(90deg,#f59e0b,#fcd34d); }
    .att-kpi.kpi-ot::before    { background: linear-gradient(90deg,#7c3aed,#a78bfa); }
    .att-kpi.kpi-ac::before    { background: linear-gradient(90deg,#b45309,#fbbf24); }

    .att-kpi-top { display: flex; align-items: flex-start; justify-content: space-between; }
    .att-kpi-icon {
      width: 30px; height: 30px; border-radius: 8px;
      display: flex; align-items: center; justify-content: center;
      font-size: 14px; flex-shrink: 0;
    }
    .kpi-in  .att-kpi-icon { background: #dcfce7; color: #16a34a; }
    .kpi-brk .att-kpi-icon { background: #fef3c7; color: #b45309; }
    .kpi-abs .att-kpi-icon { background: #fee2e2; color: #b91c1c; }
    .kpi-out .att-kpi-icon { background: #e0f2fe; color: #0369a1; }
    .kpi-full .att-kpi-icon { background: #dcfce7; color: #16a34a; }
    .kpi-half .att-kpi-icon { background: #dbeafe; color: #0369a1; }
    .kpi-late .att-kpi-icon { background: #fef3c7; color: #b45309; }
    .kpi-ot  .att-kpi-icon  { background: #ede9fe; color: #7c3aed; }
    .kpi-ac  .att-kpi-icon  { background: #fef3c7; color: #92400e; }

    .att-kpi-val {
      font-size: 1.5rem; font-weight: 800; color: #0c1a2e;
      line-height: 1; font-variant-numeric: tabular-nums;
    }
    .att-kpi-lbl {
      font-size: .58rem; font-weight: 700; letter-spacing: .06em;
      text-transform: uppercase; color: #64748b;
    }

    /* ── Date bar ── */
    .att-date-bar {
      display: flex; align-items: center; justify-content: space-between;
      padding: .45rem 1.25rem;
      background: rgba(255,255,255,.65);
      border-bottom: 1px solid #e2e8f0;
      font-size: .76rem; color: #334155;
    }
    .att-date-bar strong { color: #0f172a; }

    /* ── Filter / toolbar ── */
    .att-filter-bar {
      display: flex; align-items: center; gap: .65rem; padding: .7rem 1.25rem;
      border-bottom: 1px solid #e2e8f0;
      background: rgba(255,255,255,.55); flex-wrap: wrap;
    }
    /* search wrapper */
    .am-search-wrap {
      display: flex; align-items: center; gap: 6px;
      background: #fff; border: 1px solid #e2e8f0;
      border-radius: 10px; padding: 6px 11px; transition: border-color .2s;
    }
    .am-search-wrap:focus-within { border-color: #0ea5e9; box-shadow: 0 0 0 3px rgba(14,165,233,.1); }
    .am-search-wrap i { color: #64748b; font-size: 13px; }
    .am-search-wrap input {
      border: none; outline: none; font-family: 'Nunito', sans-serif;
      font-size: .82rem; color: #0f172a; width: 150px; background: transparent;
    }
    /* pill filters */
    .am-filter-pill {
      padding: 5px 13px; border-radius: 20px; font-size: .73rem; font-weight: 600;
      border: 1px solid #e2e8f0; background: #fff; color: #64748b;
      cursor: pointer; transition: all .18s;
    }
    .am-filter-pill.active, .am-filter-pill:hover {
      background: #0ea5e9; border-color: #0ea5e9; color: #fff;
    }
    .am-filter-pill.pill-brk.active  { background: #f59e0b; border-color: #f59e0b; }
    .am-filter-pill.pill-alert.active { background: #ef4444; border-color: #ef4444; }
    /* date input */
    .am-date-input {
      border: 1px solid #e2e8f0; border-radius: 10px;
      padding: 6px 11px; font-family: 'Nunito', sans-serif;
      font-size: .82rem; color: #0f172a; background: #fff;
      outline: none; transition: border-color .2s; cursor: pointer;
    }
    .am-date-input:focus { border-color: #0ea5e9; box-shadow: 0 0 0 3px rgba(14,165,233,.1); }
    /* refresh btn */
    .att-refresh-btn {
      margin-left: auto;
      width: 34px; height: 34px; border-radius: 9px;
      border: 1px solid #e2e8f0; background: #fff; color: #64748b;
      font-size: 15px; cursor: pointer;
      display: flex; align-items: center; justify-content: center;
      transition: all .2s; flex-shrink: 0;
    }
    .att-refresh-btn:hover { background: #e0f2fe; color: #0ea5e9; border-color: rgba(91,94,244,.3); }
    .att-refresh-btn.spinning i { animation: am-spin .6s linear; }
    @keyframes am-spin { to { transform: rotate(360deg); } }

    /* ── Table card ── */
    .att-table-wrap {
      overflow-x: auto; max-height: 62vh; overflow-y: auto;
      background: #fff;
    }
    .att-table { width: 100%; border-collapse: collapse; font-size: .88rem; }
    .att-table thead th {
      position: sticky; top: 0; z-index: 2;
      background: #f8fafc; padding: 11px 15px;
      font-size: .63rem; font-weight: 700; letter-spacing: .06em;
      text-transform: uppercase; color: #64748b;
      border-bottom: 1px solid #e2e8f0; white-space: nowrap;
    }
    .att-table thead th:first-child { padding-left: 20px; }
    .att-table tbody tr { border-bottom: 1px solid #f1f5f9; transition: background .15s; }
    .att-table tbody tr:last-child { border-bottom: none; }
    .att-table tbody tr:hover { background: #f8faff; }
    .att-table td { padding: 12px 15px; vertical-align: middle; color: #334155; }
    .att-table td:first-child { padding-left: 20px; }
    .att-table td.mono { font-variant-numeric: tabular-nums; font-size: .82rem; }

    /* Staff cell */
    .att-staff-name { display: flex; align-items: center; gap: .55rem; }
    .att-staff-avatar {
      width: 34px; height: 34px; border-radius: 50%;
      background: #0ea5e9; color: #fff;
      display: flex; align-items: center; justify-content: center;
      font-size: .68rem; font-weight: 700; flex-shrink: 0; letter-spacing: .02em;
    }
    .am-late-badge {
      display: inline-flex; align-items: center; gap: 3px;
      background: #fee2e2; color: #b91c1c;
      border-radius: 20px; padding: 1px 7px; font-size: .62rem; font-weight: 700;
      margin-left: 4px; vertical-align: middle;
    }

    /* Punch-state pills */
    .att-status-pill {
      display: inline-flex; align-items: center; gap: 6px;
      border-radius: 20px; padding: 4px 10px;
      font-size: .68rem; font-weight: 700; white-space: nowrap;
    }
    .pill-working   { background: #dcfce7; color: #16a34a; }
    .pill-break     { background: #fef3c7; color: #b45309; }
    .pill-out       { background: #dbeafe; color: #0369a1; }
    .pill-absent    { background: #f1f5f9; color: #64748b; }
    .pill-missed    { background: #fee2e2; color: #b91c1c; }

    /* Pulse dot inside pill */
    .pill-dot {
      width: 7px; height: 7px; border-radius: 50%; flex-shrink: 0; position: relative;
    }
    .pill-dot::after {
      content: ''; position: absolute; inset: -3px; border-radius: 50%;
      animation: am-pulse 1.8s ease infinite;
    }
    .dot-green            { background: #22c55e; }
    .dot-green::after     { background: rgba(34,197,94,.35); }
    .dot-amber            { background: #f59e0b; }
    .dot-amber::after     { background: rgba(245,158,11,.35); animation-duration: 2.4s; }
    .dot-red              { background: #ef4444; }
    .dot-red::after       { background: rgba(239,68,68,.35); animation-duration: 1.4s; }
    .dot-static           { background: #64748b; }
    .dot-static::after    { display: none; }

    /* Attendance day-status badge */
    .att-day-pill { display: inline-flex; align-items: center; gap: 4px; padding: 3px 9px; border-radius: 20px; font-size: .68rem; font-weight: 700; white-space: nowrap; }
    /* v5: unified with AttendanceStatusUtil.cssClass() vocabulary */
    .adp-full       { background: #dcfce7; color: #16a34a; }
    .adp-half       { background: #dbeafe; color: #0369a1; }
    .adp-absent     { background: #fee2e2; color: #b91c1c; }
    .adp-late       { background: #fef3c7; color: #b45309; }
    .adp-latehalf   { background: #ffedd5; color: #c2410c; }
    .adp-pending    { background: #f1f5f9; color: #64748b; }
    /* NEW v5 */
    .adp-overtime   { background: #ede9fe; color: #7c3aed; }
    .adp-late-ot    { background: #f3e8ff; color: #9333ea; }
    .adp-auto-close { background: #fef3c7; color: #92400e; border: 1px solid rgba(180,83,9,.2); }
    .adp-auto-close-sub { font-size:.6rem; font-weight:700; padding:1px 5px; border-radius:3px;
      background:rgba(180,83,9,.1); color:#b45309; border:1px dashed rgba(180,83,9,.35);
      margin-left:4px; vertical-align:middle; white-space:nowrap; }
    .adp-no-checkin { background: #f1f5f9; color: #94a3b8; }
    .adp-late-badge { font-size: .58rem; font-weight: 700; padding: 1px 5px; border-radius: 4px; background: #fef3c7; color: #b45309; margin-left: 3px; vertical-align: middle; }
    /* Shift-end freeze indicator — shown on live clock when past shift end */
    .clock-frozen   { color: #f59e0b !important; }
    .clock-overdue  { color: #ef4444 !important; animation: ov-blink 1.4s ease infinite; }
    @keyframes ov-blink { 0%,100%{opacity:1} 50%{opacity:.4} }

    /* Hours bar */
    .att-hours-bar { display: flex; align-items: center; gap: .45rem; }
    .att-hours-track { flex: 1; height: 5px; background: #e2e8f0; border-radius: 99px; overflow: hidden; min-width: 55px; }
    .att-hours-fill  { height: 100%; border-radius: 99px; background: linear-gradient(90deg,#0ea5e9,#38bdf8); }
    .att-hours-fill.half-fill     { background: linear-gradient(90deg,#0891b2,#06b6d4); }
    .att-hours-fill.late-fill     { background: linear-gradient(90deg,#f59e0b,#fcd34d); }
    .att-hours-fill.absent-fill   { background: linear-gradient(90deg,#ef4444,#f87171); }
    .att-hours-fill.overtime-fill { background: linear-gradient(90deg,#7c3aed,#a78bfa); }
    .att-hours-fill.auto-fill     { background: linear-gradient(90deg,#b45309,#fbbf24); }
    .att-hours-label { font-size: .75rem; font-weight: 700; color: #0f172a; min-width: 42px; text-align: right; }
    .att-break-count { display: inline-flex; align-items: center; gap: 3px; font-size: .76rem; color: #b45309; }

    /* Empty state */
    .att-empty-row td { padding: 3rem; text-align: center; color: #64748b; }
    .am-empty-illustration {
      width: 90px; height: 90px; border-radius: 50%;
      background: linear-gradient(135deg, #e0f2fe, #c7d2fe);
      display: flex; align-items: center; justify-content: center;
      font-size: 40px; margin: 0 auto 1rem; color: #0ea5e9;
    }

    /* Expand / timeline */
    .att-detail-row { display: none; background: #fafbff; }
    .att-detail-row.open { display: table-row; }
    .att-detail-inner { padding: .7rem 1rem .7rem 2.5rem; border-top: 1px solid #f1f5f9; }
    .att-tl-mini { display: flex; flex-wrap: wrap; gap: .4rem; align-items: center; list-style: none; padding: 0; margin: 0; }
    .att-tl-chip {
      display: inline-flex; align-items: center; gap: .3rem;
      padding: 4px 10px; border-radius: 8px; font-size: .72rem; font-weight: 600;
      background: #fff; border: 1px solid #e2e8f0; color: #334155;
    }
    .att-tl-chip.chip-in  { background: rgba(34,197,94,.08);  color: #16a34a; border-color: rgba(34,197,94,.2); }
    .att-tl-chip.chip-brk { background: rgba(245,158,11,.08); color: #b45309; border-color: rgba(245,158,11,.2); }
    .att-tl-chip.chip-rsm { background: rgba(14,165,233,.08); color: #0369a1; border-color: rgba(14,165,233,.2); }
    .att-tl-chip.chip-out { background: rgba(239,68,68,.08);  color: #b91c1c; border-color: rgba(239,68,68,.2); }
    .tl-arrow { color: #94a3b8; font-size: 11px; }
    .att-expand-btn { background: none; border: none; cursor: pointer; color: #94a3b8; font-size: .85rem; padding: .1rem .4rem; border-radius: 6px; transition: all .15s; }
    .att-expand-btn:hover { background: #e0f2fe; color: #0ea5e9; }

    /* Quick-action menu */
    .am-qa-wrap { position: relative; }
    .am-qa-btn {
      width: 30px; height: 30px; border-radius: 8px;
      border: 1px solid transparent; background: transparent;
      color: #94a3b8; font-size: 15px; cursor: pointer;
      display: flex; align-items: center; justify-content: center;
      transition: all .18s; opacity: 0;
    }
    .att-table tbody tr:hover .am-qa-btn { opacity: 1; }
    .am-qa-btn:hover { background: #e0f2fe; color: #0ea5e9; border-color: rgba(91,94,244,.2); }
    .am-qa-menu {
      display: none; position: absolute; right: 0; top: 34px;
      background: #fff; border: 1px solid #e2e8f0;
      border-radius: 10px; box-shadow: 0 8px 30px rgba(0,0,0,.13);
      min-width: 190px; z-index: 50; overflow: hidden;
      animation: am-menu-in .15s ease;
    }
    .am-qa-menu.open { display: block; }
    @keyframes am-menu-in { from { opacity:0; transform:translateY(-6px); } to { opacity:1; transform:translateY(0); } }
    .am-qa-item { display: flex; align-items: center; gap: 8px; padding: 9px 13px; font-size: .82rem; color: #334155; cursor: pointer; transition: background .15s; }
    .am-qa-item i { font-size: 14px; color: #64748b; }
    .am-qa-item:hover { background: #f1f5f9; color: #0f172a; }
    .am-qa-item:hover i { color: #0ea5e9; }
    .am-qa-divider { height: 1px; background: #e2e8f0; margin: 3px 0; }

    /* Adjust-session modal */
    .am-modal-overlay {
      display: none; position: fixed; inset: 0;
      background: rgba(0,0,0,.4); backdrop-filter: blur(4px);
      z-index: 2000; align-items: center; justify-content: center; padding: 16px;
    }
    .am-modal-overlay.open { display: flex; }
    .am-modal-box {
      background: #fff; border-radius: 16px;
      box-shadow: 0 24px 64px rgba(0,0,0,.2);
      width: 100%; max-width: 430px; overflow: hidden;
      animation: am-modal-in .2s ease;
    }
    @keyframes am-modal-in { from { opacity:0; transform:scale(.95); } to { opacity:1; transform:scale(1); } }
    .am-modal-head { padding: 16px 18px; border-bottom: 1px solid #e2e8f0; display: flex; align-items: center; justify-content: space-between; }
    .am-modal-head h5 { font-family: 'Nunito', sans-serif; font-size: 16px; color: #0f172a; margin: 0; }
    .am-modal-close { width: 28px; height: 28px; border-radius: 7px; border: none; background: #f1f5f9; color: #64748b; font-size: 15px; cursor: pointer; display: flex; align-items: center; justify-content: center; transition: all .15s; }
    .am-modal-close:hover { background: #fee2e2; color: #b91c1c; }
    .am-modal-body { padding: 18px; }
    .am-form-label { font-size: .7rem; font-weight: 700; color: #64748b; text-transform: uppercase; letter-spacing: .05em; margin-bottom: 4px; }
    .am-form-ctrl { width: 100%; border: 1px solid #e2e8f0; border-radius: 9px; padding: 8px 11px; font-family: 'Nunito', sans-serif; font-size: .82rem; color: #0f172a; outline: none; transition: border-color .2s; }
    .am-form-ctrl:focus { border-color: #0ea5e9; box-shadow: 0 0 0 3px rgba(14,165,233,.1); }
    .am-modal-footer { padding: 12px 18px; border-top: 1px solid #e2e8f0; display: flex; gap: 8px; justify-content: flex-end; }
    .am-btn-cancel { padding: 7px 16px; border-radius: 9px; border: 1px solid #e2e8f0; background: #fff; color: #334155; font-family: 'Nunito', sans-serif; font-size: .82rem; font-weight: 500; cursor: pointer; transition: all .15s; }
    .am-btn-cancel:hover { background: #f1f5f9; }
    .am-btn-save { padding: 7px 18px; border-radius: 9px; border: none; background: #0ea5e9; color: #fff; font-family: 'Nunito', sans-serif; font-size: .82rem; font-weight: 600; cursor: pointer; transition: all .15s; display: flex; align-items: center; gap: 5px; }
    .am-btn-save:hover { background: #0369a1; }

    /* Legend */
    .att-legend { display: flex; flex-wrap: wrap; gap: .5rem; padding: .65rem 1.25rem; border-top: 1px solid #e2e8f0; background: #f8fafc; align-items: center; }
    .att-legend-item { display: inline-flex; align-items: center; gap: .35rem; font-size: .68rem; color: #64748b; }
    .att-legend-dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; }

    /* Export bar */
    .att-export-bar { display: flex; align-items: center; gap: .65rem; padding: .55rem 1.25rem; border-top: 1px solid #e2e8f0; background: #f8fafc; flex-wrap: wrap; }
    .att-export-bar span { font-size: .73rem; color: #64748b; }
    .att-export-btn { font-size: .7rem; font-weight: 600; letter-spacing: .04em; text-transform: uppercase; padding: .3rem .85rem; border: 1px solid #e2e8f0; border-radius: 8px; background: #fff; color: #334155; cursor: pointer; transition: all .2s; display: inline-flex; align-items: center; gap: .35rem; }
    .att-export-btn:hover { border-color: #0ea5e9; color: #0ea5e9; }

    /* Skeleton loading */
    .am-skeleton { border-radius: 8px; animation: am-shimmer 1.4s infinite linear; }
    @keyframes am-shimmer {
      0%   { background-position: -600px 0; }
      100% { background-position:  600px 0; }
    }
    .am-skeleton { background: linear-gradient(90deg,#e2e8f0 25%,#f1f5f9 50%,#e2e8f0 75%); background-size: 600px 100%; }

    /* ── Refresh button spinning (dashboard_5_ pattern) ── */
    .att-refresh-btn.spinning i { animation: am-spin .6s linear infinite; }
    @keyframes am-spin { to { transform: rotate(360deg); } }

    /* ── QA three-dot menu (dashboard_5_ pattern) ── */
    .qa-btn {
      width: 30px; height: 30px; border-radius: 8px;
      border: 1px solid transparent; background: transparent;
      color: #64748b; font-size: 15px; cursor: pointer;
      display: flex; align-items: center; justify-content: center;
      transition: all .18s; opacity: 0;
    }
    .att-monitor-panel tbody tr:hover .qa-btn { opacity: 1; }
    .qa-btn:hover { background: #e0f2fe; color: #0ea5e9; border-color: rgba(91,94,244,.2); }
    .qa-wrap { position: relative; }
    .qa-menu {
      display: none; position: absolute; right: 0; top: 36px;
      background: #fff; border: 1px solid #e2e8f0;
      border-radius: 10px; box-shadow: 0 8px 30px rgba(0,0,0,.13);
      min-width: 190px; z-index: 50; overflow: hidden;
      animation: am-menuIn .15s ease;
    }
    .qa-menu.open { display: block; }
    @keyframes am-menuIn { from { opacity:0; transform:translateY(-6px); } to { opacity:1; transform:translateY(0); } }
    .qa-item {
      display: flex; align-items: center; gap: 9px;
      padding: 10px 14px; font-size: 13px; color: #334155;
      cursor: pointer; transition: background .15s;
    }
    .qa-item i { font-size: 15px; color: #64748b; }
    .qa-item:hover { background: #f1f5f9; color: #0f172a; }
    .qa-item:hover i { color: #0ea5e9; }
    .qa-divider { height: 1px; background: #e2e8f0; margin: 4px 0; }

    /* ── Late badge inside staff cell (dashboard_5_ style) ── */
    .late-badge {
      display: inline-flex; align-items: center; gap: 3px;
      background: #fee2e2; color: #b91c1c;
      border-radius: 20px; padding: 1px 7px; font-size: 10px; font-weight: 700;
      margin-left: 5px; vertical-align: middle;
    }

    /* ── Pulse dots for status pills (dashboard_5_ pattern) ── */
    .pill-dot {
      width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; position: relative;
    }
    .pill-dot::after {
      content: ''; position: absolute; inset: -3px; border-radius: 50%;
      animation: am-pulse-ring 1.8s ease infinite;
    }
    @keyframes am-pulse-ring {
      0%   { opacity:.8; transform:scale(1);   }
      70%  { opacity:0;  transform:scale(1.9); }
      100% { opacity:0;  transform:scale(1.9); }
    }
    .dot-green  { background: #22c55e; }
    .dot-green::after  { background: rgba(34,197,94,.35); }
    .dot-amber  { background: #f59e0b; }
    .dot-amber::after  { background: rgba(245,158,11,.35); animation-duration: 2.4s; }
    .dot-red    { background: #ef4444; }
    .dot-red::after    { background: rgba(239,68,68,.35);  animation-duration: 1.4s; }
    .dot-static { background: #64748b; }
    .dot-static::after { display: none; }

    /* ── Timeline (dashboard_5_ format used by _buildTimeline) ── */
    .att-detail-row .timeline { display: flex; flex-wrap: wrap; gap: 8px; align-items: center; }
    .att-detail-row .tl-step {
      display: flex; align-items: center; gap: 6px;
      background: #fff; border: 1px solid #e2e8f0;
      border-radius: 8px; padding: 5px 10px; font-size: 12px; color: #334155;
    }
    .att-detail-row .tl-dot { width: 7px; height: 7px; border-radius: 50%; flex-shrink: 0; }
    .att-detail-row .tl-dot.in  { background: #22c55e; }
    .att-detail-row .tl-dot.brk { background: #f59e0b; }
    .att-detail-row .tl-dot.out { background: #ef4444; }
    .att-detail-row .tl-arrow { color: #94a3b8; font-size: 11px; }

    /* ── Live clock in work-time cell ── */
    .live-clock { font-variant-numeric: tabular-nums; }

    /* ══════════════════════════════════════════════════
       ADMIN ATTENDANCE — ENHANCED TABS (adminDashboard)
    ══════════════════════════════════════════════════ */
    .adm-tab-bar {
      display: flex;
      gap: 0;
      border-bottom: 2px solid #e2e8f0;
      margin-bottom: 1.25rem;
      flex-wrap: wrap;
    }
    .adm-tab {
      padding: .55rem 1.15rem;
      font-size: .8rem;
      font-weight: 600;
      color: #64748b;
      cursor: pointer;
      border: none;
      background: none;
      border-bottom: 2px solid transparent;
      margin-bottom: -2px;
      display: flex;
      align-items: center;
      gap: .4rem;
      transition: color .15s, border-color .15s;
      white-space: nowrap;
    }
    .adm-tab:hover { color: #0ea5e9; }
    .adm-tab.adm-active {
      color: #0ea5e9;
      border-bottom-color: #0ea5e9;
    }
    .adm-tab-pane { display: none; }
    .adm-tab-pane.adm-visible { display: block; }

    /* ── Shift config cards ── */
    .adm-shift-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
      gap: .85rem;
      margin-bottom: 1.25rem;
    }
    .adm-shift-card {
      background: #f8faff;
      border: 1.5px solid #e2e8f0;
      border-radius: 12px;
      padding: 1rem 1.15rem;
      cursor: pointer;
      transition: border-color .18s, box-shadow .18s;
    }
    .adm-shift-card:hover { border-color: #0ea5e9; box-shadow: 0 4px 18px rgba(14,165,233,.1); }
    .adm-shift-card.adm-selected { border-color: #0ea5e9; background: #e0f2fe; }
    .adm-shift-card .sc-name {
      font-weight: 700;
      font-size: .95rem;
      color: #0f172a;
      margin-bottom: .4rem;
    }
    .adm-shift-card .sc-row {
      display: flex;
      gap: .75rem;
      font-size: .75rem;
      color: #64748b;
      flex-wrap: wrap;
    }
    .adm-shift-card .sc-row span { display: flex; align-items: center; gap: .25rem; }
    .adm-shift-card .sc-row i { color: #0ea5e9; }

    /* ── Admin form ── */
    .adm-form-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
      gap: .85rem;
      margin-bottom: 1rem;
    }
    .adm-form-group { display: flex; flex-direction: column; gap: .3rem; }
    .adm-form-label { font-size: .7rem; font-weight: 600; color: #64748b; text-transform: uppercase; letter-spacing: .06em; }
    .adm-form-ctrl {
      background: #f8faff;
      border: 1.5px solid #e2e8f0;
      border-radius: 9px;
      color: #0f172a;
      font-size: .85rem;
      padding: .5rem .75rem;
      outline: none;
      width: 100%;
      transition: border-color .15s;
      font-family: inherit;
    }
    .adm-form-ctrl:focus { border-color: #0ea5e9; box-shadow: 0 0 0 3px rgba(14,165,233,.1); }
    .adm-form-ctrl option { background: #fff; }

    /* ── Buttons ── */
    .adm-btn {
      display: inline-flex;
      align-items: center;
      gap: .35rem;
      padding: .5rem .95rem;
      border-radius: 9px;
      font-size: .8rem;
      font-weight: 600;
      cursor: pointer;
      border: none;
      transition: all .15s;
      font-family: inherit;
    }
    .adm-btn-primary { background: #0ea5e9; color: #fff; }
    .adm-btn-primary:hover { background: #0284c7; }
    .adm-btn-outline {
      background: #fff;
      color: #334155;
      border: 1.5px solid #e2e8f0;
    }
    .adm-btn-outline:hover { border-color: #0ea5e9; color: #0ea5e9; background: #e0f2fe; }
    .adm-btn-danger { background: #fff; color: #b91c1c; border: 1.5px solid #fecaca; }
    .adm-btn-danger:hover { background: #fee2e2; border-color: #f87171; }
    .adm-btn-sm { padding: .35rem .7rem; font-size: .75rem; }

    /* ── Staff assignment table ── */
    .adm-table { width: 100%; border-collapse: collapse; font-size: .86rem; }
    .adm-table thead th {
      text-align: left;
      font-size: .68rem;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: .07em;
      color: #64748b;
      padding: .55rem 1rem;
      border-bottom: 2px solid #e2e8f0;
      white-space: nowrap;
      background: #f8faff;
    }
    .adm-table tbody tr { border-bottom: 1px solid #f1f5f9; transition: background .12s; }
    .adm-table tbody tr:hover { background: #f8faff; }
    .adm-table td { padding: .7rem 1rem; color: #334155; vertical-align: middle; }
    .adm-shift-pill {
      display: inline-flex;
      align-items: center;
      gap: .3rem;
      padding: .2rem .65rem;
      border-radius: 100px;
      font-size: .72rem;
      font-weight: 600;
      background: #e0f2fe;
      color: #0369a1;
      border: 1px solid rgba(14,165,233,.25);
    }
    .adm-shift-pill.unassigned {
      background: #f1f5f9;
      color: #94a3b8;
      border-color: #e2e8f0;
    }

    /* ── Notification feed ── */
    .adm-notif-feed { display: flex; flex-direction: column; gap: .65rem; }
    .adm-notif-item {
      display: grid;
      grid-template-columns: auto 1fr auto;
      gap: .85rem;
      align-items: start;
      padding: .9rem 1rem;
      background: #fff;
      border: 1px solid #e2e8f0;
      border-left: 3px solid #f59e0b;
      border-radius: 10px;
      animation: adm-slide-in .25s ease;
    }
    @keyframes adm-slide-in {
      from { opacity: 0; transform: translateY(-4px); }
      to   { opacity: 1; transform: translateY(0); }
    }
    .adm-notif-icon {
      width: 30px; height: 30px;
      border-radius: 50%;
      background: #fef3c7;
      display: flex;
      align-items: center;
      justify-content: center;
      color: #b45309;
      font-size: .85rem;
      flex-shrink: 0;
    }
    .adm-notif-title { font-weight: 700; font-size: .84rem; color: #0f172a; margin-bottom: .15rem; }
    .adm-notif-msg { font-size: .77rem; color: #64748b; line-height: 1.45; }
    .adm-notif-time { font-size: .69rem; color: #94a3b8; margin-top: .25rem; }
    .adm-notif-actions { display: flex; flex-direction: column; gap: .35rem; flex-shrink: 0; }

    /* ── Overview stat row inside monitor panel ── */
    .adm-stat-row {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(150px, 1fr));
      gap: .75rem;
      margin-bottom: 1.25rem;
    }
    .adm-stat-card {
      background: #fff;
      border: 1.5px solid #e2e8f0;
      border-radius: 12px;
      padding: .85rem 1rem;
      position: relative;
      overflow: hidden;
    }
    .adm-stat-card::before {
      content: '';
      position: absolute;
      top: 0; left: 0;
      width: 100%; height: 3px;
      background: var(--sc-accent, #0ea5e9);
    }
    .adm-stat-label { font-size: .67rem; color: #64748b; text-transform: uppercase; letter-spacing: .07em; margin-bottom: .25rem; }
    .adm-stat-value { font-size: 1.6rem; font-weight: 800; color: var(--sc-accent, #0ea5e9); line-height: 1; }
    .adm-stat-sub { font-size: .67rem; color: #94a3b8; margin-top: .2rem; }

    /* ── Panel header in sub-sections ── */
    .adm-panel {
      background: #fff;
      border: 1.5px solid #e2e8f0;
      border-radius: 12px;
      margin-bottom: 1.25rem;
      overflow: hidden;
    }
    .adm-panel-head {
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: .8rem 1.1rem;
      border-bottom: 1px solid #e2e8f0;
      background: #f8faff;
    }
    .adm-panel-head h3 {
      font-size: .88rem;
      font-weight: 700;
      color: #0f172a;
      display: flex;
      align-items: center;
      gap: .4rem;
    }
    .adm-panel-head h3 i { color: #0ea5e9; }
    .adm-panel-body { padding: 1.1rem; }
  </style>
</head>
<body>

<!-- NAVBAR -->
<div class="top-navbar">
  <button class="btn-sidebar-toggle" id="sidebarToggle"><i class="bi bi-list"></i></button>
  <a class="nav-brand" href="#">Smart <span>Inventory</span></a>
  <div class="nav-right">
    <span class="nav-user-info">Welcome, <strong><%= uname %></strong></span>
    <span class="badge-role"><%= role %></span>
    <a href="AdminNotificationServlet" class="btn-bell">
      <i class="bi bi-bell-fill"></i>
      <span class="bell-badge">
        <%= (request.getAttribute("unreadCount")!=null&&(int)request.getAttribute("unreadCount")>0)?request.getAttribute("unreadCount"):"" %>
      </span>
    </a>
    <a href="logout" class="btn-logout"><i class="bi bi-power me-1"></i>Logout</a>
  </div>
</div>

<!-- SIDEBAR -->
<div class="sidebar" id="sidebar">
  <p class="sidebar-section-label">Main Menu</p>
  <a href="StaffDashboard"    class="sidebar-nav-link ajax-link"><i class="bi bi-people"></i> Staff Dashboard</a>
  <a href="ProductDashboard"  class="sidebar-nav-link ajax-link"><i class="bi bi-boxes"></i> Product Dashboard</a>
  <a href="<%=request.getContextPath()%>/AdminBills"         class="sidebar-nav-link ajax-link"><i class="bi bi-receipt"></i> Billing</a>
  <p class="sidebar-section-label">Delivery</p>
   <a href="<%=request.getContextPath()%>/DeliverySlotServlet?action=adminSlots" class="sidebar-nav-link ajax-link"><i class="bi bi-grid-3x3-gap me-2"></i>Slot Monitor
    </a>
  <a href="DeliveryAgentReview?filter=PENDING" class="sidebar-nav-link ajax-link"><i class="bi bi-person-badge"></i> Agent Applications</a>
  <p class="sidebar-section-label">Attendance</p>
  
  <a href="#" class="sidebar-nav-link" id="sidebarAttLink" onclick="showAttendanceMonitor();return false;">
    <i class="bi bi-clock-history"></i> Staff Attendance
  </a>
  <a href="#" class="sidebar-nav-link" id="sidebarLeaveLink"
   onclick="dashboardLoadFragment('StaffDashboard','Staff','');lvScrollToLeavePanel();return false;">
  <i class="bi bi-calendar2-heart"></i> Leave Management
  <!-- Pending badge — updated by polling -->
  <span id="sidebarLeaveBadge"
        style="display:none;margin-left:auto;background:#ef4444;color:#fff;
               font-size:.6rem;padding:1px 6px;border-radius:10px;font-weight:700"></span>
</a>
  <p class="sidebar-section-label">Analytics</p>
  <a href="<%=request.getContextPath()%>/ReportsDashboard"  class="sidebar-nav-link ajax-link"><i class="bi bi-bar-chart-line"></i> Reports</a>
  <a href="stocksDashboard.jsp"   class="sidebar-nav-link ajax-link"><i class="bi bi-graph-up"></i> Stocks</a>
  <p class="sidebar-section-label">Account</p>
  <a href="<%=request.getContextPath()%>/AdminProfile"           class="sidebar-nav-link ajax-link"><i class="bi bi-person-circle"></i> Profile</a>
  <a href="settings.jsp"      class="sidebar-nav-link ajax-link"><i class="bi bi-gear"></i> Settings</a>
</div>

<!-- SIDEBAR OVERLAY (mobile) -->
<div class="sidebar-overlay" id="sidebarOverlay"></div>

<!-- MAIN CONTENT -->
<div class="main-content" id="mainContent-wrapper">
  <nav aria-label="breadcrumb">
    <ol class="breadcrumb" id="breadcrumb">
      <li class="breadcrumb-item active">Home</li>
    </ol>
  </nav>

  <div id="mainContent">
    <!-- Welcome panel -->
    <div class="welcome-panel" id="welcomePanel">
      <h2 class="welcome-title">Administrator Dashboard</h2>
      <p class="welcome-sub">Select a section from the sidebar to get started.</p>
      <div class="quick-stat-grid">
        <div class="quick-stat" onclick="window.dashboardLoadFragment('StaffDashboard','Staff','')">
          <i class="bi bi-people"></i><span>Staff</span></div>
        <div class="quick-stat" onclick="window.dashboardLoadFragment('ProductDashboard','Products','')">
          <i class="bi bi-boxes"></i><span>Products</span></div>
        <div class="quick-stat" onclick="window.dashboardLoadFragment('adminBills','Billing','')">
          <i class="bi bi-receipt"></i><span>Billing</span></div>
        <div class="quick-stat" onclick="window.dashboardLoadFragment('ReportsDashboard','Reports','')">
          <i class="bi bi-bar-chart-line"></i><span>Reports</span></div>
        <div class="quick-stat" onclick="window.dashboardLoadFragment('StocksDashboard','Stocks','')">
          <i class="bi bi-graph-up"></i><span>Stocks</span></div>
        <div class="quick-stat" onclick="showAttendanceMonitor()">
          <i class="bi bi-clock-history"></i><span>Attendance</span></div>
      </div>
    </div>
  </div><!-- /#mainContent -->

  <!-- ══════════════════════════════════════════════════════════════
       ADMIN ATTENDANCE MONITOR  (updated — mirrors dashboard_5_ style)
  ══════════════════════════════════════════════════════════════ -->
  <div class="att-monitor-panel" id="attMonitorPanel" style="display:none">

    <!-- Panel header -->
    <div class="att-monitor-header">
      <div>
        <div class="att-monitor-title"><i class="bi bi-clock-history"></i> Staff Attendance Control Centre</div>
        <div class="att-monitor-sub">Monitor · Configure · Assign — full admin control over attendance, shifts &amp; alerts</div>
      </div>
      <div class="att-monitor-live">
        <span class="att-live-dot"></span>
        <span id="adminLiveClock">--:--:--</span>
      </div>
    </div>

    <!-- ── Admin Tab Bar ── -->
    <div class="adm-tab-bar" style="margin:0 1.25rem">
      <button class="adm-tab adm-active" data-adm-tab="monitor" onclick="admSwitchTab('monitor',this)">
        <i class="bi bi-activity"></i> Live Monitor
      </button>
      <button class="adm-tab" data-adm-tab="overview" onclick="admSwitchTab('overview',this)">
        <i class="bi bi-speedometer2"></i> Overview
      </button>
      <button class="adm-tab" data-adm-tab="shifts" onclick="admSwitchTab('shifts',this)">
        <i class="bi bi-clock-fill"></i> Shift Config
      </button>
      <button class="adm-tab" data-adm-tab="assign" onclick="admSwitchTab('assign',this)">
        <i class="bi bi-person-badge-fill"></i> Staff Shifts
      </button>
      <button class="adm-tab" data-adm-tab="notifications" onclick="admSwitchTab('notifications',this)">
        <i class="bi bi-bell-fill"></i> Alerts
        <span id="admNotifBadge" style="display:none;background:#ef4444;color:#fff;font-size:.6rem;padding:1px 5px;border-radius:10px;font-weight:700">0</span>
      </button>
    </div>

    <!-- ══════════════════ TAB: LIVE MONITOR ══════════════════ -->
    <div class="adm-tab-pane adm-visible" id="adm-tab-monitor">

      <!-- Office rules reminder — updated dynamically by _updateRulesStrip() -->
      <div class="att-rules-strip" id="attRulesStrip">
        <span class="att-rule-chip"><i class="bi bi-building"></i> Office Start: <b id="ruleStart">10:00 AM</b></span>
        <span class="att-rule-chip"><i class="bi bi-clock-history"></i> Late After: <b id="ruleLate">11:00 AM</b></span>
        <span class="att-rule-chip"><i class="bi bi-check2-circle"></i> Full Day: <b id="ruleFull">≥ 8 hrs</b></span>
        <span class="att-rule-chip"><i class="bi bi-adjust"></i> Half Day: <b id="ruleHalf">4 – 8 hrs</b></span>
        <span class="att-rule-chip"><i class="bi bi-x-circle"></i> Absent: <b id="ruleAbsent">&lt; 4 hrs or No Check-In</b></span>
        <span class="att-rule-chip"><i class="bi bi-star-fill" style="color:#7c3aed"></i> Overtime: <b id="ruleOT">Beyond full shift + 15 min</b></span>
        <span class="att-rule-chip" id="ruleShiftChip" style="display:none"><i class="bi bi-moon-stars-fill" style="color:#0ea5e9"></i> Active Shift: <b id="ruleShiftName">—</b></span>
      </div>

      <!-- KPI cards — v5: 9 cards including overtime + auto-closed -->
      <div class="att-kpi-row" id="attKpiGrid" style="grid-template-columns:repeat(9,1fr)">
        <div class="att-kpi kpi-in">
          <div class="att-kpi-top">
            <div><div class="att-kpi-lbl">Clocked In</div></div>
            <div class="att-kpi-icon"><i class="bi bi-play-circle-fill"></i></div>
          </div>
          <div class="att-kpi-val" id="kpiWorking">0</div>
        </div>
        <div class="att-kpi kpi-brk">
          <div class="att-kpi-top">
            <div><div class="att-kpi-lbl">On Break</div></div>
            <div class="att-kpi-icon"><i class="bi bi-cup-hot-fill"></i></div>
          </div>
          <div class="att-kpi-val" id="kpiBreak">0</div>
        </div>
        <div class="att-kpi kpi-out">
          <div class="att-kpi-top">
            <div><div class="att-kpi-lbl">Punched Out</div></div>
            <div class="att-kpi-icon"><i class="bi bi-box-arrow-right"></i></div>
          </div>
          <div class="att-kpi-val" id="kpiOut">0</div>
        </div>
        <div class="att-kpi kpi-abs">
          <div class="att-kpi-top">
            <div><div class="att-kpi-lbl">No Check-In</div></div>
            <div class="att-kpi-icon"><i class="bi bi-person-x-fill"></i></div>
          </div>
          <div class="att-kpi-val" id="kpiAbsent">0</div>
        </div>
        <div class="att-kpi kpi-full">
          <div class="att-kpi-top">
            <div><div class="att-kpi-lbl">Full Day</div></div>
            <div class="att-kpi-icon"><i class="bi bi-check-circle-fill"></i></div>
          </div>
          <div class="att-kpi-val" id="kpiFull">0</div>
        </div>
        <div class="att-kpi kpi-half">
          <div class="att-kpi-top">
            <div><div class="att-kpi-lbl">Half Day</div></div>
            <div class="att-kpi-icon"><i class="bi bi-adjust"></i></div>
          </div>
          <div class="att-kpi-val" id="kpiHalf">0</div>
        </div>
        <div class="att-kpi kpi-late">
          <div class="att-kpi-top">
            <div><div class="att-kpi-lbl">Late Mark</div></div>
            <div class="att-kpi-icon"><i class="bi bi-clock-history"></i></div>
          </div>
          <div class="att-kpi-val" id="kpiLate">0</div>
        </div>
        <!-- NEW v5 -->
        <div class="att-kpi kpi-ot">
          <div class="att-kpi-top">
            <div><div class="att-kpi-lbl">Overtime</div></div>
            <div class="att-kpi-icon"><i class="bi bi-star-fill"></i></div>
          </div>
          <div class="att-kpi-val" id="kpiOT">0</div>
        </div>
        <div class="att-kpi kpi-ac">
          <div class="att-kpi-top">
            <div><div class="att-kpi-lbl">Auto-Closed</div></div>
            <div class="att-kpi-icon"><i class="bi bi-shield-exclamation"></i></div>
          </div>
          <div class="att-kpi-val" id="kpiAC">0</div>
        </div>
      </div>

      <!-- Date info bar -->
      <div class="att-date-bar">
        <span>Viewing: <strong id="attDateLabel">Today</strong></span>
        <span style="color:#64748b" id="attShiftLabel">Auto-refreshes every 30 s &nbsp;|&nbsp; Data from staff devices</span>
      </div>

      <!-- Filter toolbar -->
      <div class="att-filter-bar">
        <div class="am-search-wrap">
          <i class="bi bi-search"></i>
          <input type="text" id="attSearch" placeholder="Search staff…" oninput="filterTable()">
        </div>
        <input type="date" class="am-date-input" id="attDateFilter" onchange="changeDateFilter()">
        <button class="am-filter-pill active" data-filter="all"        onclick="setAttFilter('all',this)">All</button>
        <button class="am-filter-pill pill-brk" data-filter="onBreak"  onclick="setAttFilter('onBreak',this)">On Break</button>
        <button class="am-filter-pill pill-alert" data-filter="absent" onclick="setAttFilter('absent',this)">Absent</button>
        <select id="attDayFilter" onchange="filterTable()" style="border:1px solid #e2e8f0;border-radius:9px;padding:5px 10px;font-size:.78rem;color:#334155;background:#fff;outline:none;cursor:pointer;">
          <option value="all">All Attendance</option>
          <option value="full_day">Full Day</option>
          <option value="half_day">Half Day</option>
          <option value="late">Late Mark</option>
          <option value="late_half">Late (Half Day)</option>
          <option value="overtime">Overtime</option>
          <option value="late_overtime">Late + Overtime</option>
          <option value="absent">Absent</option>
          <option value="auto_close">Auto-Closed</option>
          <option value="pending">In Progress</option>
        </select>
        <button class="att-refresh-btn" id="attRefreshBtn" onclick="refreshAttendance()" title="Refresh">
          <i class="bi bi-arrow-clockwise"></i>
        </button>
        <span style="font-size:.72rem;color:#64748b;margin-left:.25rem" id="attRowCount"></span>
      </div>

      <!-- Table -->
      <div class="att-table-wrap">
        <table class="att-table" id="attTable">
          <thead>
            <tr>
              <th>#</th>
              <th>Staff Member</th>
              <th>Punch Status</th>
              <th>Attendance Status</th>
              <th>Punch In</th>
              <th>Punch Out</th>
              <th>Work Time</th>
              <th>Break Time</th>
              <th>Net Hours</th>
              <th style="width:40px"></th>
            </tr>
          </thead>
          <tbody id="attTableBody">
            <tr>
              <td colspan="10" style="text-align:center;padding:3rem">
                <div class="am-empty-illustration"><i class="bi bi-clock-history"></i></div>
                <div style="font-size:.9rem;color:#64748b">Loading attendance data…</div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Legend v5 -->
      <div class="att-legend">
        <span style="font-size:.68rem;font-weight:700;color:#64748b;text-transform:uppercase;letter-spacing:.08em;margin-right:.4rem">Legend:</span>
        <span class="att-legend-item"><span class="att-legend-dot" style="background:#22c55e"></span> Full Day (on-time, ≥ shift hrs)</span>
        <span class="att-legend-item"><span class="att-legend-dot" style="background:#7c3aed"></span> Overtime (beyond shift + 15m)</span>
        <span class="att-legend-item"><span class="att-legend-dot" style="background:#0891b2"></span> Half Day (≥ half shift, on-time)</span>
        <span class="att-legend-item"><span class="att-legend-dot" style="background:#f59e0b"></span> Late Mark (after grace, ≥ shift hrs)</span>
        <span class="att-legend-item"><span class="att-legend-dot" style="background:#c2410c"></span> Late + Half Day</span>
        <span class="att-legend-item"><span class="att-legend-dot" style="background:#ef4444"></span> Absent (&lt; half shift or no check-in)</span>
        <span class="att-legend-item"><span class="att-legend-dot" style="background:#b45309"></span> Auto-Closed (system)</span>
        <span class="att-legend-item"><span class="att-legend-dot" style="background:#64748b"></span> In Progress (open session)</span>
        <span class="att-legend-item"><span class="att-legend-dot" style="background:#f59e0b;border:1px solid #ef4444"></span> ⚡ Clock amber = past shift end</span>
      </div>

      <!-- Export bar -->
      <div class="att-export-bar">
        <span>Export:</span>
        <button class="att-export-btn" onclick="exportCSV()"><i class="bi bi-filetype-csv"></i> CSV</button>
        <button class="att-export-btn" onclick="window.print()"><i class="bi bi-printer"></i> Print</button>
      </div>

    </div><!-- /.adm-tab-pane#monitor -->

    <!-- ══════════════════ TAB: OVERVIEW SNAPSHOT ══════════════════ -->
    <div class="adm-tab-pane" id="adm-tab-overview" style="padding:1.25rem">
      <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:1rem;flex-wrap:wrap;gap:.5rem">
        <div>
          <div style="font-size:1rem;font-weight:700;color:#0f172a">Today's Snapshot</div>
          <div style="font-size:.75rem;color:#64748b" id="admOverviewDateLabel">—</div>
        </div>
        <button class="adm-btn adm-btn-outline adm-btn-sm" onclick="admRefreshOverview()">
          <i class="bi bi-arrow-clockwise"></i> Refresh
        </button>
      </div>

      <div class="adm-stat-row">
        <div class="adm-stat-card" style="--sc-accent:#22c55e">
          <div class="adm-stat-label">Present (On-time)</div>
          <div class="adm-stat-value" id="admStatPresent">—</div>
          <div class="adm-stat-sub">clocked-in, on-time arrivals</div>
        </div>
        <div class="adm-stat-card" style="--sc-accent:#7c3aed">
          <div class="adm-stat-label">Overtime</div>
          <div class="adm-stat-value" id="admStatOT">—</div>
          <div class="adm-stat-sub">worked beyond shift</div>
        </div>
        <div class="adm-stat-card" style="--sc-accent:#f59e0b">
          <div class="adm-stat-label">Late</div>
          <div class="adm-stat-value" id="admStatLate">—</div>
          <div class="adm-stat-sub">past grace window</div>
        </div>
        <div class="adm-stat-card" style="--sc-accent:#ef4444">
          <div class="adm-stat-label">Absent</div>
          <div class="adm-stat-value" id="admStatAbsent">—</div>
          <div class="adm-stat-sub">no check-in today</div>
        </div>
        <div class="adm-stat-card" style="--sc-accent:#a855f7">
          <div class="adm-stat-label">On Break</div>
          <div class="adm-stat-value" id="admStatBreak">—</div>
          <div class="adm-stat-sub">active break session</div>
        </div>
        <div class="adm-stat-card" style="--sc-accent:#0891b2">
          <div class="adm-stat-label">Punched Out</div>
          <div class="adm-stat-value" id="admStatOut">—</div>
          <div class="adm-stat-sub">completed sessions</div>
        </div>
        <div class="adm-stat-card" style="--sc-accent:#b45309">
          <div class="adm-stat-label">Auto-Closed</div>
          <div class="adm-stat-value" id="admStatAC">—</div>
          <div class="adm-stat-sub">missed punch-out</div>
        </div>
        <div class="adm-stat-card" style="--sc-accent:#0ea5e9">
          <div class="adm-stat-label">Unread Alerts</div>
          <div class="adm-stat-value" id="admStatNotifs">—</div>
          <div class="adm-stat-sub">pending notifications</div>
        </div>
      </div>

      <div class="adm-panel">
        <div class="adm-panel-head">
          <h3><i class="bi bi-activity"></i> Live Session Summary</h3>
        </div>
        <div class="adm-panel-body" style="overflow-x:auto">
          <table class="adm-table" id="admOverviewTable">
            <thead>
              <tr>
                <th>Staff</th>
                <th>Punch In</th>
                <th>Punch Out</th>
                <th>Net Hours</th>
                <th>Status</th>
                <th>Attendance</th>
              </tr>
            </thead>
            <tbody id="admOverviewTbody">
              <tr><td colspan="6" style="text-align:center;padding:2rem;color:#94a3b8">
                <i class="bi bi-arrow-clockwise"></i> Loading…
              </td></tr>
            </tbody>
          </table>
        </div>
      </div>
    </div><!-- /.adm-tab-pane#overview -->

    <!-- ══════════════════ TAB: SHIFT CONFIG ══════════════════ -->
    <div class="adm-tab-pane" id="adm-tab-shifts" style="padding:1.25rem">
      <div class="adm-panel">
        <div class="adm-panel-head">
          <h3><i class="bi bi-grid-3x2-gap-fill"></i> Defined Shifts</h3>
          <button class="adm-btn adm-btn-outline adm-btn-sm" onclick="admLoadShifts()">
            <i class="bi bi-arrow-clockwise"></i> Refresh
          </button>
        </div>
        <div class="adm-panel-body">
          <div class="adm-shift-grid" id="admShiftGrid">
            <div style="color:#94a3b8;font-size:.8rem"><i class="bi bi-hourglass-split"></i> Loading shifts…</div>
          </div>
        </div>
      </div>

      <div class="adm-panel">
        <div class="adm-panel-head">
          <h3><i class="bi bi-pencil-square"></i> <span id="admShiftFormTitle">Create New Shift</span></h3>
          <button class="adm-btn adm-btn-outline adm-btn-sm" id="admShiftClearBtn" onclick="admClearShiftForm()" style="display:none">
            <i class="bi bi-x-circle"></i> Clear
          </button>
        </div>
        <div class="adm-panel-body">
          <input type="hidden" id="admSfId">
          <div class="adm-form-grid">
            <div class="adm-form-group">
              <label class="adm-form-label">Shift Name</label>
              <input class="adm-form-ctrl" type="text" id="admSfName" placeholder="e.g. Morning">
            </div>
            <div class="adm-form-group">
              <label class="adm-form-label">Expected Login</label>
              <input class="adm-form-ctrl" type="time" id="admSfLogin" value="09:00">
            </div>
            <div class="adm-form-group">
              <label class="adm-form-label">Expected Logout</label>
              <input class="adm-form-ctrl" type="time" id="admSfLogout" value="18:00">
            </div>
            <div class="adm-form-group">
              <label class="adm-form-label">Grace Period (min)</label>
              <input class="adm-form-ctrl" type="number" id="admSfGrace" value="60" min="0" max="480">
            </div>
          </div>
          <div style="display:flex;gap:.6rem;flex-wrap:wrap">
            <button class="adm-btn adm-btn-primary" onclick="admSaveShift()">
              <i class="bi bi-floppy-fill"></i>
              <span id="admSfBtnLabel">Save Shift</span>
            </button>
          </div>
        </div>
      </div>
    </div><!-- /.adm-tab-pane#shifts -->

    <!-- ══════════════════ TAB: STAFF ASSIGNMENT ══════════════════ -->
    <div class="adm-tab-pane" id="adm-tab-assign" style="padding:1.25rem">
      <div class="adm-panel">
        <div class="adm-panel-head">
          <h3><i class="bi bi-diagram-3-fill"></i> Current Shift Assignments</h3>
          <button class="adm-btn adm-btn-outline adm-btn-sm" onclick="admLoadAssignments()">
            <i class="bi bi-arrow-clockwise"></i> Refresh
          </button>
        </div>
        <div class="adm-panel-body" style="overflow-x:auto">
          <table class="adm-table">
            <thead>
              <tr>
                <th>Staff Member</th>
                <th>Department</th>
                <th>Current Shift</th>
                <th>Assign Shift</th>
              </tr>
            </thead>
            <tbody id="admAssignTbody">
              <tr><td colspan="4" style="text-align:center;padding:2rem;color:#94a3b8">
                <i class="bi bi-hourglass-split"></i> Loading staff…
              </td></tr>
            </tbody>
          </table>
        </div>
      </div>
    </div><!-- /.adm-tab-pane#assign -->

    <!-- ══════════════════ TAB: NOTIFICATIONS ══════════════════ -->
    <div class="adm-tab-pane" id="adm-tab-notifications" style="padding:1.25rem">
      <div class="adm-panel">
        <div class="adm-panel-head">
          <h3><i class="bi bi-bell-fill"></i> Unread Alerts</h3>
          <div style="display:flex;gap:.5rem;flex-wrap:wrap">
            <button class="adm-btn adm-btn-outline adm-btn-sm" onclick="admLoadNotifications()">
              <i class="bi bi-arrow-clockwise"></i> Refresh
            </button>
            <button class="adm-btn adm-btn-outline adm-btn-sm" onclick="admDismissAll()">
              <i class="bi bi-check2-all"></i> Dismiss All
            </button>
          </div>
        </div>
        <div class="adm-panel-body">
          <div class="adm-notif-feed" id="admNotifFeed">
            <div style="text-align:center;padding:2rem;color:#94a3b8">
              <i class="bi bi-bell-slash" style="font-size:2rem;display:block;margin-bottom:.5rem"></i>
              Loading notifications…
            </div>
          </div>
        </div>
      </div>
    </div><!-- /.adm-tab-pane#notifications -->

  </div><!-- /.att-monitor-panel -->

  <!-- Adjust-session modal (new from dashboard_5_) -->
  <div class="am-modal-overlay" id="amAdjustModal">
    <div class="am-modal-box">
      <div class="am-modal-head">
        <h5><i class="bi bi-pencil-square me-2" style="color:#0ea5e9"></i>Adjust Session</h5>
        <button class="am-modal-close" onclick="amCloseModal()"><i class="bi bi-x"></i></button>
      </div>
      <div class="am-modal-body">
        <input type="hidden" id="amModalUsername">
        <div class="mb-3">
          <div class="am-form-label">Staff Member</div>
          <div id="amModalStaffName" style="font-weight:700;font-size:15px;color:#0f172a"></div>
        </div>
        <!-- BUG FIX: show the date being adjusted so admin knows which session -->
        <div class="mb-3">
          <div class="am-form-label">Session Date</div>
          <div id="amModalSessionDate" style="font-size:13px;color:#64748b;font-weight:600"></div>
        </div>
        <div class="row g-3">
          <div class="col-6">
            <div class="am-form-label">Punch-in Time</div>
            <input type="time" class="am-form-ctrl" id="amModalPunchIn" oninput="amValidateTimes()">
          </div>
          <div class="col-6">
            <div class="am-form-label">Punch-out Time</div>
            <input type="time" class="am-form-ctrl" id="amModalPunchOut" oninput="amValidateTimes()">
          </div>
        </div>
        <!-- BUG FIX: inline validation message for time errors -->
        <div id="amTimeError" style="display:none;margin-top:6px;font-size:12px;color:#dc2626;font-weight:500"></div>
        <div class="mt-3">
          <div class="am-form-label">Admin Note (reason) <span style="color:#dc2626">*</span></div>
          <textarea class="am-form-ctrl" id="amModalNote" rows="2" placeholder="e.g. Clock skew corrected by admin…"></textarea>
        </div>
      </div>
      <div class="am-modal-footer">
        <button class="am-btn-cancel" onclick="amCloseModal()">Cancel</button>
        <button class="am-btn-save" onclick="amSaveAdjustment()"><i class="bi bi-check2"></i> Save Changes</button>
      </div>
    </div>
  </div>

  <div class="spinner" id="spinner">
    <div class="spinner-border" role="status"><span class="visually-hidden">Loading…</span></div>
    <p class="mt-2" style="font-family:'Nunito',sans-serif;color:var(--text-muted);font-size:.9rem">Loading content…</p>
  </div>
</div><!-- /.main-content -->

<!-- Toast -->
<% if (successMsg != null && !successMsg.isBlank()) { %>
<div class="position-fixed top-0 start-50 translate-middle-x p-3" style="z-index:1100;width:100%;max-width:500px">
  <div id="successToast" class="toast align-items-center text-bg-success border-0 big-toast" role="alert" aria-live="assertive" aria-atomic="true">
    <div class="d-flex">
      <div class="toast-body text-center"><i class="bi bi-check-circle me-2"></i><%= successMsg %></div>
      <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button>
    </div>
  </div>
</div>
<% } %>

<!-- Footer -->
<footer><p class="mb-0">&copy; 2026 <span>Smart Inventory</span> &nbsp;|&nbsp; Administrator Portal</p></footer>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
    <jsp:include page="staffChatWidget.jsp" />

<script>
/* ══════════════════════════════════════════════════════════════
   SIDEBAR TOGGLE — desktop shrinks content, mobile uses overlay
══════════════════════════════════════════════════════════════ */
(function(){
  var btn      = document.getElementById('sidebarToggle');
  var sidebar  = document.getElementById('sidebar');
  var overlay  = document.getElementById('sidebarOverlay');
  var body     = document.body;
  var MOBILE   = 992; // breakpoint px

  function isMobile(){ return window.innerWidth < MOBILE; }

  function openSidebar(){
    sidebar.classList.remove('collapsed');
    btn.querySelector('i').className = 'bi bi-x-lg';
    if(isMobile()){
      overlay.style.display = 'block';
      requestAnimationFrame(function(){ overlay.classList.add('visible'); });
      body.style.overflow = 'hidden'; // prevent scroll-through
    } else {
      body.classList.remove('sidebar-collapsed');
    }
  }

  function closeSidebar(){
    sidebar.classList.add('collapsed');
    btn.querySelector('i').className = 'bi bi-list';
    if(isMobile()){
      overlay.classList.remove('visible');
      setTimeout(function(){ overlay.style.display='none'; },300);
      body.style.overflow = '';
    } else {
      body.classList.add('sidebar-collapsed');
    }
  }

  function toggleSidebar(){
    if(sidebar.classList.contains('collapsed')) openSidebar();
    else closeSidebar();
  }

  /* On resize: sync state cleanly */
  function onResize(){
    if(!isMobile()){
      /* Desktop — remove overlay artefacts */
      overlay.classList.remove('visible');
      overlay.style.display = 'none';
      body.style.overflow = '';
      /* Keep current open/closed state but apply body class for margin */
      if(sidebar.classList.contains('collapsed')) body.classList.add('sidebar-collapsed');
      else body.classList.remove('sidebar-collapsed');
    } else {
      /* Mobile — remove body class so content always fills full width */
      body.classList.remove('sidebar-collapsed');
    }
  }

  /* Default: open on desktop, closed on mobile */
  if(isMobile()){
    sidebar.classList.add('collapsed');
    btn.querySelector('i').className = 'bi bi-list';
  } else {
    body.classList.remove('sidebar-collapsed');
    btn.querySelector('i').className = 'bi bi-x-lg';
  }

  btn.addEventListener('click', toggleSidebar);
  overlay.addEventListener('click', closeSidebar);
  window.addEventListener('resize', onResize);

  /* Close sidebar on mobile when a nav link is clicked */
  sidebar.querySelectorAll('.sidebar-nav-link').forEach(function(link){
    link.addEventListener('click', function(){
      if(isMobile()) closeSidebar();
    });
  });
})();

/* ── AJAX NAVIGATION ── */
function extractBody(html){
  var m=html.match(/<body[^>]*>([\s\S]*?)<\/body>/i);
  if(m) return m[1];
  return html.replace(/<html[^>]*>/gi,'').replace(/<\/html>/gi,'')
             .replace(/<head[^>]*>[\s\S]*?<\/head>/gi,'').trim();
}
window.dashboardLoadFragment=function(url,title,activeLink){
  document.querySelectorAll('.sidebar-nav-link').forEach(l=>l.classList.remove('active'));
  if(activeLink) activeLink.classList.add('active');
  document.getElementById('spinner').style.display='block';
  document.getElementById('mainContent').innerHTML='';
  const att=document.getElementById('attMonitorPanel');
  if(att) att.style.display='none';
  fetch(url)
    .then(r=>{if(!r.ok)throw new Error('HTTP '+r.status);return r.text();})
    .then(html=>{
      const c=document.getElementById('mainContent');
      c.innerHTML=extractBody(html);
      document.getElementById('spinner').style.display='none';
      if(title) updateBreadcrumb(title);
      c.querySelectorAll('script').forEach(old=>{const s=document.createElement('script');s.textContent=old.textContent;old.replaceWith(s);});
      c.querySelectorAll('.ajax-link:not([data-ajax-bound])').forEach(link=>{
        link.dataset.ajaxBound='1';
        link.addEventListener('click',function(e){e.preventDefault();window.dashboardLoadFragment(this.getAttribute('href'),this.textContent.trim(),null);});
      });
    })
    .catch(err=>{
      document.getElementById('mainContent').innerHTML="<p style='color:#e74c3c;font-family:'Nunito',sans-serif;padding:2rem'><i class='bi bi-exclamation-triangle me-2'></i>Error: "+err.message+"</p>";
      document.getElementById('spinner').style.display='none';
    });
};
document.querySelectorAll('.ajax-link').forEach(link=>{
  link.addEventListener('click',function(e){e.preventDefault();window.dashboardLoadFragment(this.getAttribute('href'),this.textContent.trim(),this);});
});

/* ── TOAST ── */
document.addEventListener('DOMContentLoaded',function(){
  var toastEl=document.getElementById('successToast');
  if(toastEl) new bootstrap.Toast(toastEl,{delay:3500,autohide:true}).show();

  const d=new Date(), iso=d.toISOString().slice(0,10);
  document.getElementById('attDateFilter').value=iso;
  document.getElementById('attDateLabel').textContent=
    d.toLocaleDateString('en-IN',{weekday:'long',day:'numeric',month:'long',year:'numeric'});

  startAdminClock();
  _startAutoRefresh();

  // Auto-activate a sidebar section when returning from an inner page.
  // Back buttons append ?section=staff or ?section=products to dashboard.jsp.
  const sectionParam = new URLSearchParams(window.location.search).get('section');
  if (sectionParam) {
    const sectionMap = {
      'staff':    { url: 'StaffDashboard',   title: 'Staff Dashboard' },
      'products': { url: 'ProductDashboard', title: 'Product Dashboard' },    
      'agentapplications': { url: 'Agent Applications', title: 'Agent Applications' },
      'adduser':  { url: 'AddUser',          title: 'Add User' },
      'profile':  { url: 'AdminProfile',     title: 'Profile' },
      'slotmonitor': { url: 'DeliverySlotServlet?action=adminSlots', title: 'Slot Monitor' }
    };
    const target = sectionMap[sectionParam.toLowerCase()];
    if (target) {
      // Find and highlight the matching sidebar link
      const sidebarLink = Array.from(document.querySelectorAll('.sidebar-nav-link'))
        .find(l => l.getAttribute('href') === target.url);
      window.dashboardLoadFragment(target.url, target.title, sidebarLink || null);
      // Clean the URL so the param doesn't persist on manual refresh
      history.replaceState(null, '', window.location.pathname);
    }
  }
});

function updateBreadcrumb(title){
  document.getElementById('breadcrumb').innerHTML=
    '<li class="breadcrumb-item"><a href="#">Home</a></li>'+
    '<li class="breadcrumb-item active">'+title+'</li>';
}

/* ── NOTIFICATION BADGE POLLING ── */
function refreshNotifications(){
  fetch('UnreadCountServlet').then(r=>r.text()).then(count=>{
    const b=document.querySelector('.bell-badge');
    if(b) b.textContent=parseInt(count)>0?count:'';
  }).catch(()=>{});
}
setInterval(refreshNotifications,30000);

/* ══════════════════════════════════════════════════════════════
   ATTENDANCE MONITOR ENGINE v5
   FIXES vs original:
   1. _normaliseStatus() → unified lowercase_snake vocabulary
   2. _computeAttStatus() → shift-aware FULL_MS/HALF_MS, not hardcoded 8h/4h
   3. _renderKpi() → counts overtime + auto_close separately
   4. _dayStatusPill() → covers all 9 v5 statuses with correct CSS classes
   5. _hoursBar() → overtime fill colour + capped bar at 100%
   6. _startLiveClocks() → FREEZES at shift end (shiftEndMs), shows ⚡ warning
   7. Post-shift-end clock turns amber; overdue by 1h turns red + blinks
   8. _computeWorkMs() → caps elapsed at shift end for live display (doesn't
      inflate net hours while staff hasn't punched out yet)
   9. _updateRulesStrip() → writes shift-aware thresholds to rules strip
  10. Row net-hours colour correct for overtime (purple) and auto_close (amber)
  11. Break count label shows /MAX not hardcoded /2
  12. Absent staff in allStaff response use 'no_checkin' label (not "Absent")
══════════════════════════════════════════════════════════════ */

/* ── State ── */
let _allRows    = [];
let _filter     = 'all';
let _clockTimer = null;
let _autoTimer  = null;
let _openMenuId = null;

/* ── Default thresholds (overridden by _updateRulesStrip when shift data arrives) ── */
let FULL_MS        = 8  * 3600000;   // updated per shift
let HALF_MS        = 4  * 3600000;   // = FULL_MS / 2
let OT_GRACE_MS    = 15 * 60000;     // 15-min overtime grace
let LATE_H         = 11, LATE_M = 0; // updated per shift
let MAX_BREAKS     = 2;              // mirrors AttendanceDAO.MAX_BREAKS_PER_SHIFT
let _cachedShiftMs = {};             // shiftId → {endMs, durationMs, lateMins, loginH, loginM}

/* ── Admin live clock ── */
function startAdminClock(){
  function tick(){
    const el=document.getElementById('adminLiveClock');
    if(el) el.textContent=new Date().toLocaleTimeString('en-IN',{hour:'2-digit',minute:'2-digit',second:'2-digit',hour12:false});
  }
  tick(); setInterval(tick,1000);
}

/* ── Show the attendance panel ── */
function showAttendanceMonitor(){
  document.getElementById('mainContent').innerHTML='';
  document.getElementById('spinner').style.display='none';
  const wp=document.getElementById('welcomePanel');
  if(wp) wp.style.display='none';
  const att=document.getElementById('attMonitorPanel');
  if(att) att.style.display='block';
  document.querySelectorAll('.sidebar-nav-link').forEach(l=>l.classList.remove('active'));
  const lk=document.getElementById('sidebarAttLink');
  if(lk) lk.classList.add('active');
  updateBreadcrumb('Staff Attendance');
  loadData(false);
}

/* ══════════════════════════════════════════════════════════════
   DATA FETCH
══════════════════════════════════════════════════════════════ */
function loadData(showSpinner){
  const dateVal=document.getElementById('attDateFilter').value;
  if(showSpinner) _spinRefreshBtn(true);

  fetch('AttendanceServlet?action=allStaff&date='+encodeURIComponent(dateVal),{
    headers:{'X-Requested-With':'XMLHttpRequest'}
  })
  .then(r=>{if(!r.ok)throw new Error('HTTP '+r.status);return r.json();})
  .then(data=>{
    _allRows=data;

    /* ── CRITICAL FIX: seed _cachedShiftMs from inline shiftDetails ────────
       The server now embeds full shift details per row (loginTime, logoutTime,
       graceMinutes, shiftDurationMs) so the JS never needs a second async
       fetch.  _getShiftEndMs() works on first render, not after a round-trip.
    ────────────────────────────────────────────────────────────────────────── */
    data.forEach(row=>{
      if(row.shiftId && row.shiftDetails && !_cachedShiftMs[row.shiftId]){
        const s=row.shiftDetails;
        const lp=s.loginTime.split(':').map(Number);
        const op=s.logoutTime.split(':').map(Number);
        const lMins=lp[0]*60+lp[1], oMins=op[0]*60+op[1];
        let diff=oMins-lMins; if(diff<=0) diff+=1440;
        _cachedShiftMs[row.shiftId]={
          durationMs: s.shiftDurationMs || diff*60000,
          lateMins:   lMins+(s.graceMinutes||60),
          loginH:lp[0], loginM:lp[1],
          logoutH:op[0], logoutM:op[1],
          graceMin:s.graceMinutes||60,
          name:s.shiftName||'',
          overnight: oMins < lMins
        };
      }
    });
    /* Apply thresholds from the first available shift */
    const withShift=data.find(r=>r.shiftId && _cachedShiftMs[r.shiftId]);
    if(withShift) _applyShiftThresholds(_cachedShiftMs[withShift.shiftId]);

    _renderKpi(data);
    _renderTable(data);
    if(showSpinner) _spinRefreshBtn(false);
  })
  .catch(err=>{
    console.warn('AttendanceServlet error:',err.message);
    if(showSpinner) _spinRefreshBtn(false);
    if(_allRows.length) _renderTable(_allRows);
  });
}

function refreshAttendance(){ loadData(false); }

function _startAutoRefresh(){
  _autoTimer=setInterval(()=>{ if(!document.hidden) loadData(false); },30000);
}

function changeDateFilter(){
  const val=document.getElementById('attDateFilter').value;
  const d=new Date(val+'T00:00:00');
  document.getElementById('attDateLabel').textContent=
    d.toLocaleDateString('en-IN',{weekday:'long',day:'numeric',month:'long',year:'numeric'});
  loadData(true);
}

function _spinRefreshBtn(on){
  const btn=document.getElementById('attRefreshBtn');
  if(!btn) return;
  if(on) btn.classList.add('spinning');
  else   btn.classList.remove('spinning');
}

/* ══════════════════════════════════════════════════════════════
   SHIFT THRESHOLD SEEDING
   Fetches shift details and updates FULL_MS, HALF_MS, LATE_H/M
   so all status computations use the real shift duration.
══════════════════════════════════════════════════════════════ */
function _seedShiftThresholds(shiftId){
  if(_cachedShiftMs[shiftId]){ _applyShiftThresholds(_cachedShiftMs[shiftId]); return; }
  fetch('AttendanceServlet?action=shifts')
    .then(r=>r.json())
    .then(shifts=>{
      shifts.forEach(s=>{
        const loginParts  = s.loginTime.split(':').map(Number);
        const logoutParts = s.logoutTime.split(':').map(Number);
        const loginMins   = loginParts[0]*60+loginParts[1];
        const logoutMins  = logoutParts[0]*60+logoutParts[1];
        let diffMins      = logoutMins-loginMins;
        if(diffMins<=0) diffMins+=1440; // overnight
        const graceMins   = s.graceMinutes||60;
        _cachedShiftMs[s.id]={
          durationMs: diffMins*60000,
          lateMins:   loginMins+graceMins,
          loginH:     loginParts[0],
          loginM:     loginParts[1],
          logoutH:    logoutParts[0],
          logoutM:    logoutParts[1],
          graceMin:   graceMins,
          name:       s.shiftName,
          overnight:  logoutMins < loginMins
        };
      });
      if(_cachedShiftMs[shiftId]) _applyShiftThresholds(_cachedShiftMs[shiftId]);
    }).catch(()=>{});
}

function _applyShiftThresholds(sc){
  FULL_MS = sc.durationMs;
  HALF_MS = Math.round(sc.durationMs/2);
  LATE_H  = Math.floor(sc.lateMins/60);
  LATE_M  = sc.lateMins%60;
  _updateRulesStrip(sc);
}

/* FIX-9: Update rules strip with real shift thresholds */
function _updateRulesStrip(sc){
  const fmtM = m=>{
    const h=Math.floor(m/60),mn=m%60;
    return ((h%12)||12)+':'+(String(mn).padStart(2,'0'))+' '+(h>=12?'PM':'AM');
  };
  const fmtH = ms=>{ const h=ms/3600000; return h===Math.floor(h)?h+'h':h.toFixed(1)+'h'; };
  _setTxt('ruleStart', fmtM(sc.loginH*60+sc.loginM));
  _setTxt('ruleLate',  fmtM(sc.lateMins));
  _setTxt('ruleFull',  '≥ '+fmtH(sc.durationMs));
  _setTxt('ruleHalf',  fmtH(sc.durationMs/2)+' – '+fmtH(sc.durationMs));
  _setTxt('ruleAbsent','< '+fmtH(sc.durationMs/2)+' or No Check-In');
  _setTxt('ruleOT',    'Beyond full shift + 15 min ('+(sc.overnight?'overnight':'day')+')');
  _setTxt('ruleShiftName', sc.name+(sc.overnight?' (overnight)':''));
  const chip=document.getElementById('ruleShiftChip');
  if(chip) chip.style.display='';
}
function _setTxt(id,v){ const e=document.getElementById(id); if(e) e.textContent=v; }

/* ══════════════════════════════════════════════════════════════
   STATUS NORMALISER  (single source of truth)
   Maps any server status → unified lowercase_snake v5 vocabulary
══════════════════════════════════════════════════════════════ */
function _normaliseStatus(s){
  if(!s) return 'pending';
  switch(s.toLowerCase()){
    case 'present':        return 'full_day';
    case 'full_day':       return 'full_day';
    case 'late':           return 'late';
    case 'absent':         return 'absent';
    case 'overtime':       return 'overtime';
    case 'late_overtime':  return 'late_overtime';
    case 'half_day':       return 'half_day';
    case 'late_half':      return 'late_half';
    case 'auto_close':
    case 'system_closed':  return 'auto_close';
    case 'no_checkin':     return 'no_checkin';
    case 'pending':        return 'pending';
    default:               return s.toLowerCase();
  }
}

/* ══════════════════════════════════════════════════════════════
   KPI RENDER  v5: counts overtime + auto_close buckets
══════════════════════════════════════════════════════════════ */
function _renderKpi(data){
  let working=0,onBreak=0,punchedOut=0,absent=0,full=0,half=0,late=0,ot=0,ac=0;
  data.forEach(r=>{
    const st=r.status||'absent';
    if     (st==='working')                           working++;
    else if(st==='onBreak')                           onBreak++;
    else if(st==='punchedOut'||st==='missed_punchout')punchedOut++;
    else                                              absent++;

    const workMs=_computeWorkMs(r);
    const as=_normaliseStatus(r.attendanceStatus)||_computeAttStatus(r.punchInTime,r.punchOutTime,workMs,r.shiftId);
    if(as==='full_day')                      full++;
    else if(as==='half_day')                 half++;
    else if(as==='late'||as==='late_half')   late++;
    else if(as==='overtime'||as==='late_overtime') ot++;
    else if(as==='auto_close')               ac++;
  });
  _setTxt('kpiWorking', working);
  _setTxt('kpiBreak',   onBreak);
  _setTxt('kpiOut',     punchedOut);
  _setTxt('kpiAbsent',  absent);
  _setTxt('kpiFull',    full);
  _setTxt('kpiHalf',    half);
  _setTxt('kpiLate',    late);
  _setTxt('kpiOT',      ot);
  _setTxt('kpiAC',      ac);
}

/* ══════════════════════════════════════════════════════════════
   TABLE RENDER  v5
══════════════════════════════════════════════════════════════ */
function _renderTable(data){
  if(_clockTimer){ clearInterval(_clockTimer); _clockTimer=null; }

  const q  =(document.getElementById('attSearch').value||'').toLowerCase().trim();
  const dayF=document.getElementById('attDayFilter').value;

  const filtered=data.filter(d=>{
    if(q && !d.username.toLowerCase().includes(q)) return false;
    if(_filter==='onBreak') return d.status==='onBreak';
    if(_filter==='alert')   return d.status==='missed_punchout';
    if(_filter==='absent')  return d.status==='absent';
    if(_filter!=='all')     return d.status===_filter;
    if(dayF!=='all'){
      const wMs=_computeWorkMs(d);
      const as=_normaliseStatus(d.attendanceStatus)||_computeAttStatus(d.punchInTime,d.punchOutTime,wMs,d.shiftId);
      if(as!==dayF) return false;
    }
    return true;
  });

  const countEl=document.getElementById('attRowCount');
  if(countEl) countEl.textContent=filtered.length+' of '+data.length+' staff';

  const tbody=document.getElementById('attTableBody');

  if(!filtered.length){
    tbody.innerHTML=`<tr><td colspan="10">
      <div style="text-align:center;padding:60px 20px">
        <div class="am-empty-illustration"><i class="bi bi-moon-stars"></i></div>
        <div style="font-size:.95rem;font-weight:600;color:#0f172a;margin-bottom:.3rem">
          ${_filter!=='all'?'No matching sessions':'Office is quiet today'}
        </div>
        <div style="font-size:.82rem;color:#64748b">
          ${_filter!=='all'?'No staff match the current filter.':'No attendance sessions recorded yet.'}
        </div>
      </div></td></tr>`;
    return;
  }

  let rows='';
  filtered.forEach((d,idx)=>{
    const initials    = _initials(d.username);
    const avatarColor = _avatarColor(d.username);
    const workMs      = _computeWorkMs(d);          // live-capped for display
    const breakMs     = _computeBreakMs(d);
    const breakCount  = _countBreaks(d);

    /* FIX-1: use server status (already computed by Java, shift-aware).
       Only fall back to client _computeAttStatus if server didn't send one.
       For auto-close rows: use workQualityStatus (the computed payroll quality)
       as the primary status for colour/bar — isAutoClose flag still drives the combined badge. */
    let attStatus = _normaliseStatus(d.attendanceStatus)
                      || _computeAttStatus(d.punchInTime, d.punchOutTime, workMs, d.shiftId);
    if(d.isAutoClose && d.workQualityStatus){
      const wqNorm = _normaliseStatus(d.workQualityStatus);
      if(wqNorm && wqNorm !== 'auto_close') attStatus = wqNorm;
    }

    /* Late flag: derive from normalised status (already computed server-side) */
    const isLate = attStatus==='late'||attStatus==='late_half'
                || attStatus==='late_overtime'
                ||(d.isLate===true);

    /* Shift end boundary for this row (for clock freeze) */
    const shiftEndMs = _getShiftEndMs(d);

    const lateHtml   = isLate
      ? `<span class="late-badge"><i class="bi bi-clock"></i> Late</span>` : '';
    const breakHtml  = (d.status==='onBreak'||d.status==='working')
      ? `<span class="att-break-count" title="Breaks taken (max ${MAX_BREAKS})"><i class="bi bi-cup-hot"></i> ${breakCount}/${MAX_BREAKS}</span>` : '';
    /* autoHtml in name cell — use d.isAutoClose since attStatus is now the quality status */
    const autoHtml   = (d.isAutoClose || attStatus==='auto_close')
      ? `<span style="font-size:.65rem;background:#fef3c7;color:#92400e;border-radius:4px;padding:1px 5px;margin-left:4px;font-weight:700"><i class="bi bi-shield-exclamation"></i> Auto-Closed</span>` : '';

    const punchInStr  = d.punchInTime  ? _fmtTime(d.punchInTime)  : '—';
    const punchOutStr = d.punchOutTime ? _fmtTime(d.punchOutTime) : null;
    const clockId     = 'clock-'+idx;
    const expandId    = 'expand-'+idx;

    /* Net hours text colour — v5: purple for OT, amber for auto_close */
    let netColor='#334155';
    if(attStatus==='absent')                              netColor='#dc2626';
    else if(attStatus==='full_day'||attStatus==='late')   netColor='#059669';
    else if(attStatus==='overtime'||attStatus==='late_overtime') netColor='#7c3aed';
    /* auto_close rows: attStatus is now the quality status, colour comes from that */
    else if(attStatus==='half_day'||attStatus==='late_half')     netColor='#0891b2';

    /* FIX-7: Past-shift-end indicator in punch-out cell */
    const now         = Date.now();
    const isPastShift = shiftEndMs>0 && !d.punchOutTime && d.status!=='absent' && now>shiftEndMs;
    const isOverdue   = isPastShift && (now-shiftEndMs)>3600000; // >1h past
    const punchOutCell= punchOutStr
      ? `<div>${punchOutStr}</div>`
      : d.status==='absent'
        ? `<span style="color:#94a3b8">—</span>`
        : isPastShift
          ? `<span class="${isOverdue?'clock-overdue':'clock-frozen'}" title="Shift ended at ${_fmtTime(shiftEndMs)}, no punch-out yet">
               <i class="bi bi-exclamation-triangle-fill" style="font-size:.7rem"></i>
               Expected ${_fmtTime(shiftEndMs)}
             </span>`
          : `<span style="color:#94a3b8;font-size:.8rem">active</span>`;

    rows+=`
      <tr data-username="${_esc(d.username)}" data-status="${d.status}" class="att-row" id="row-${idx}"
          onclick="_toggleExpand('${expandId}',event)" style="cursor:pointer">
        <td class="mono" style="color:#94a3b8;font-size:.75rem;padding-left:1.25rem">${idx+1}</td>
        <td>
          <div class="att-staff-name">
            <div class="att-staff-avatar" style="background:${avatarColor}">${initials}</div>
            <div>
              <div class="staff-name">${_esc(d.username)}${lateHtml}${autoHtml}</div>
              ${breakHtml}
            </div>
          </div>
        </td>
        <td>${_statusPill(d.status)}</td>
        <td>${_dayStatusPill(attStatus, isLate, d)}</td>
        <td class="mono">${d.punchInTime ? `<div>${punchInStr}</div>` : `<span style="color:#94a3b8">—</span>`}</td>
        <td class="mono">${punchOutCell}</td>
        <td style="min-width:130px">
          ${d.punchInTime ? _hoursBar(workMs, attStatus, d) : '<span style="color:#94a3b8">—</span>'}
          ${d.punchInTime&&!d.punchOutTime&&d.status!=='absent'
            ? `<span class="live-clock${isPastShift?(isOverdue?' clock-overdue':' clock-frozen'):''}"
                   id="${clockId}"
                   data-start="${d.punchInTime}"
                   data-break="${d.totalBreakMs||0}"
                   data-shiftend="${shiftEndMs||0}"
                   style="font-size:.7rem;font-weight:600;display:block;margin-top:2px">—</span>`
            : ''}
        </td>
        <td>
          <span class="att-break-count">
            <i class="bi bi-cup-hot" style="color:#f59e0b"></i>
            ${_fmtMs(breakMs)} (${breakCount}x)
          </span>
        </td>
        <td class="mono" style="font-weight:700;color:${netColor}">
          ${workMs>0 ? _fmtMs(workMs) : '—'}
        </td>
        <td>
          <div class="qa-wrap" id="qa-wrap-${idx}" onclick="event.stopPropagation()">
            <button class="att-expand-btn qa-btn" title="Actions" onclick="toggleMenu(event,${idx})">
              <i class="bi bi-three-dots-vertical"></i>
            </button>
            <div class="qa-menu" id="qa-menu-${idx}">
              <div class="qa-item" onclick="amOpenModal('${_esc(d.username)}',${d.punchInTime||0},${d.punchOutTime||0})">
                <i class="bi bi-pencil-square"></i> Adjust Session
              </div>
              <div class="qa-item" onclick="_copyUsername('${_esc(d.username)}')">
                <i class="bi bi-clipboard"></i> Copy Username
              </div>
              <div class="qa-divider"></div>
              <div class="qa-item" onclick="_viewTimeline('${expandId}')">
                <i class="bi bi-diagram-3"></i> View Timeline
              </div>
              ${(d.status==='missed_punchout'||isPastShift)?`
              <div class="qa-divider"></div>
              <div class="qa-item" style="color:#b91c1c" onclick="_forcePunchOut('${_esc(d.username)}')">
                <i class="bi bi-clock-history"></i> Force Punch-out
              </div>`:''}
            </div>
          </div>
        </td>
      </tr>
      <tr class="att-detail-row" id="${expandId}">
        <td colspan="10">
          <div class="att-detail-inner">
            <div style="display:flex;align-items:center;gap:1rem;margin-bottom:.5rem;flex-wrap:wrap">
              <strong style="font-size:.72rem;color:#64748b;text-transform:uppercase;letter-spacing:.8px">Activity Timeline</strong>
              ${shiftEndMs>0?`<span style="font-size:.72rem;background:#f0f9ff;border:1px solid #bfdbfe;border-radius:6px;padding:2px 8px;color:#0369a1">
                <i class="bi bi-clock"></i> Shift ends: ${_fmtTime(shiftEndMs)}
              </span>`:''}
              <div style="margin-left:auto;display:flex;gap:.5rem;flex-wrap:wrap">
                <span style="font-size:.72rem;color:#64748b">
                  <i class="bi bi-clock"></i> In: <b>${punchInStr}</b>
                  &nbsp;|&nbsp; <i class="bi bi-door-open"></i> Out: <b>${punchOutStr||'—'}</b>
                  &nbsp;|&nbsp; <i class="bi bi-cup-hot"></i> Break: <b>${_fmtMs(breakMs)}</b>
                  &nbsp;|&nbsp; <i class="bi bi-lightning-charge"></i> Net: <b>${_fmtMs(workMs)}</b>
                </span>
              </div>
            </div>
            ${_buildTimeline(d)}
            ${_buildStatusExplanation(attStatus, d)}
          </div>
        </td>
      </tr>`;
  });

  tbody.innerHTML=rows;
  _startLiveClocks(filtered);
}

function filterTable(){ _renderTable(_allRows); }

function setAttFilter(f,btn){
  _filter=f;
  document.querySelectorAll('.am-filter-pill').forEach(b=>b.classList.remove('active'));
  if(btn) btn.classList.add('active');
  _renderTable(_allRows);
}

/* ══════════════════════════════════════════════════════════════
   LIVE CLOCKS  v5 — FREEZES AT SHIFT END
   Real-world behaviour: if a staff member hasn't punched out after
   their shift ended, the clock shows how long they've been working
   UP TO the shift end time (not live-counting indefinitely).
   This prevents net_work_ms from inflating beyond the shift.
   Clock turns AMBER past shift end, RED if overdue by 1h+.
══════════════════════════════════════════════════════════════ */
function _startLiveClocks(rows){
  _clockTimer=setInterval(()=>{
    rows.forEach((d,idx)=>{
      const el=document.getElementById('clock-'+idx);
      if(!el) return;
      const start    = parseInt(el.dataset.start)||0;
      const brk      = parseInt(el.dataset.break)||0;
      const shiftEnd = parseInt(el.dataset.shiftend)||0;
      if(!start) return;

      const now   = Date.now();
      /* FIX-6: cap elapsed at shift end if past it */
      const capAt = (shiftEnd>0 && now>shiftEnd) ? shiftEnd : now;
      const workMs= Math.max(0, (capAt-start)-brk);

      el.textContent=_fmtMs(workMs);

      /* Visual cue: amber = past shift end, red+blink = >1h overdue */
      if(shiftEnd>0 && now>shiftEnd+3600000){
        el.classList.add('clock-overdue');
        el.classList.remove('clock-frozen');
      } else if(shiftEnd>0 && now>shiftEnd){
        el.classList.add('clock-frozen');
        el.classList.remove('clock-overdue');
      } else {
        el.classList.remove('clock-frozen','clock-overdue');
        el.style.color='#0ea5e9';
      }
    });
  },1000);
}

/* ══════════════════════════════════════════════════════════════
   SHIFT END BOUNDARY
   Returns the epoch-ms of when a session's shift is expected to end.
   Mirrors AttendanceDAO.computeShiftEndBoundary() logic in JS.
══════════════════════════════════════════════════════════════ */
function _getShiftEndMs(d){
  const shiftId = d.shiftId;
  if(!shiftId || !_cachedShiftMs[shiftId]) return 0;
  const sc = _cachedShiftMs[shiftId];
  if(!d.punchInTime) return 0;
  const sessionDate = new Date(d.punchInTime);
  // Set to same calendar date as session
  const base = new Date(sessionDate.getFullYear(), sessionDate.getMonth(), sessionDate.getDate(),
                        sc.logoutH, sc.logoutM, 0, 0);
  if(sc.overnight) base.setDate(base.getDate()+1); // next day
  return base.getTime();
}

/* ══════════════════════════════════════════════════════════════
   COMPUTE HELPERS  v5
══════════════════════════════════════════════════════════════ */

/* FIX-2: shift-aware status computation (uses actual shift duration) */
function _computeAttStatus(punchInMs, punchOutMs, netMs, shiftId){
  if(!punchInMs) return 'absent';
  if(!punchOutMs) return 'pending';

  /* Resolve shift-specific thresholds */
  let fullMs=FULL_MS, halfMs=HALF_MS, lateMins=LATE_H*60+LATE_M;
  if(shiftId && _cachedShiftMs[shiftId]){
    const sc=_cachedShiftMs[shiftId];
    fullMs=sc.durationMs; halfMs=Math.round(sc.durationMs/2); lateMins=sc.lateMins;
  }

  const d=new Date(punchInMs);
  const punchMins=d.getHours()*60+d.getMinutes();

  /* Night-shift post-midnight check: always on-time */
  let late=false;
  if(shiftId && _cachedShiftMs[shiftId] && _cachedShiftMs[shiftId].overnight){
    const sc=_cachedShiftMs[shiftId];
    const logoutMins=sc.logoutH*60+sc.logoutM;
    const isPostMidnight=punchMins<logoutMins;
    late=isPostMidnight ? false : punchMins>lateMins;
  } else {
    late=punchMins>lateMins;
  }

  /* FIX-3: absent if < halfMs (not just < 4h hardcoded) */
  if(netMs<halfMs)                       return 'absent';
  if(netMs>=halfMs && netMs<fullMs)      return late?'late_half':'half_day';
  if(netMs<=fullMs+OT_GRACE_MS)          return late?'late':'full_day';
  /* overtime */                         return late?'late_overtime':'overtime';
}

/* FIX-6: live workMs capped at shift end */
function _computeWorkMs(rec){
  if(!rec.punchInTime) return 0;
  const shiftEnd = _getShiftEndMs(rec);
  const rawEnd   = rec.punchOutTime ? rec.punchOutTime : Date.now();
  const capEnd   = (shiftEnd>0 && rawEnd>shiftEnd && !rec.punchOutTime) ? shiftEnd : rawEnd;
  let b=rec.totalBreakMs||0;
  if(rec.status==='onBreak'&&rec.breakStart) b+=(Date.now()-rec.breakStart);
  return Math.max(0,(capEnd-rec.punchInTime)-b);
}

function _computeBreakMs(rec){
  let b=rec.totalBreakMs||0;
  if(rec.status==='onBreak'&&rec.breakStart) b+=(Date.now()-rec.breakStart);
  return b;
}

/* ══════════════════════════════════════════════════════════════
   STATUS PILLS  v5
══════════════════════════════════════════════════════════════ */
function _statusPill(status){
  const map={
    working:         ['pill-working','dot-green', 'Clocked In'],
    onBreak:         ['pill-break',  'dot-amber', 'On Break'],
    missed_punchout: ['pill-alert',  'dot-red',   '<i class="bi bi-exclamation-circle-fill me-1"></i>Missed Punch-out'],
    punchedOut:      ['pill-out',    'dot-static','Punched Out'],
    absent:          ['pill-absent', 'dot-static','Not Checked In'],
  };
  const [pillCls,dotCls,label]=map[status]||['pill-absent','dot-static',status];
  return `<span class="att-status-pill ${pillCls}"><span class="pill-dot ${dotCls}"></span>${label}</span>`;
}

/* FIX-4: DAY_STATUS_CFG covering all 9 v5 statuses */
const DAY_STATUS_CFG={
  full_day:      {cls:'adp-full',       icon:'check-circle-fill',        label:'Full Day'},
  half_day:      {cls:'adp-half',       icon:'adjust',                   label:'Half Day'},
  absent:        {cls:'adp-absent',     icon:'x-circle-fill',            label:'Absent'},
  late:          {cls:'adp-late',       icon:'clock-history',            label:'Late Mark'},
  late_half:     {cls:'adp-latehalf',   icon:'exclamation-circle-fill',  label:'Late (Half Day)'},
  overtime:      {cls:'adp-overtime',   icon:'star-fill',                label:'Overtime'},
  late_overtime: {cls:'adp-late-ot',    icon:'exclamation-diamond-fill', label:'Late (Overtime)'},
  auto_close:    {cls:'adp-auto-close', icon:'shield-exclamation',       label:'Auto-Closed'},
  no_checkin:    {cls:'adp-no-checkin', icon:'dash-circle',              label:'No Check-In'},
  pending:       {cls:'adp-pending',    icon:'hourglass-split',          label:'In Progress'},
};

function _dayStatusPill(statusKey, isLate, d){
  /* d = row data object — needed to get workQualityStatus for auto-close rows */
  const cfg=DAY_STATUS_CFG[statusKey]||DAY_STATUS_CFG['pending'];
  /* Don't double-label late when status already encodes it */
  const alreadyLate=statusKey==='late'||statusKey==='late_half'||statusKey==='late_overtime';
  const lateBadge=(isLate && !alreadyLate && statusKey!=='absent' && statusKey!=='pending' && statusKey!=='no_checkin')
    ? '<span class="adp-late-badge">LATE</span>' : '';

  /* Combined badge: "Auto-Closed (Half Day)" — show work quality inside the pill */
  if(statusKey==='auto_close' || (d && d.isAutoClose)){
    const wqKey   = (d && d.workQualityStatus) ? _normaliseStatus(d.workQualityStatus) : null;
    const wqLabel = wqKey && wqKey!=='auto_close' && DAY_STATUS_CFG[wqKey]
                  ? DAY_STATUS_CFG[wqKey].label : null;
    const wqIcon  = wqKey && wqKey!=='auto_close' && DAY_STATUS_CFG[wqKey]
                  ? DAY_STATUS_CFG[wqKey].icon : null;
    const wqCls   = wqKey && wqKey!=='auto_close' && DAY_STATUS_CFG[wqKey]
                  ? DAY_STATUS_CFG[wqKey].cls : 'adp-auto-close';
    if(wqLabel){
      /* Main pill = work quality colour, secondary pill = auto-closed indicator */
      return `<span class="att-day-pill ${wqCls}"><i class="bi bi-${wqIcon}"></i> ${wqLabel}<span class="adp-auto-close-sub"><i class="bi bi-shield-exclamation"></i> Auto-Closed</span></span>`;
    }
    /* No work quality info — fallback to plain auto-closed */
    return `<span class="att-day-pill adp-auto-close"><i class="bi bi-shield-exclamation"></i> Auto-Closed</span>`;
  }

  return `<span class="att-day-pill ${cfg.cls}"><i class="bi bi-${cfg.icon}"></i> ${cfg.label}${lateBadge}</span>`;
}

/* FIX-5: hours bar — overtime fill + cap bar visually at 110% for overtime */
function _hoursBar(workMs, statusKey, rec){
  const refMs   = FULL_MS;
  const otMs    = workMs - refMs;
  const isOT    = statusKey==='overtime'||statusKey==='late_overtime';
  const pct     = isOT
    ? 100 + Math.min(20, Math.round((otMs/refMs)*100))  // 100–120% for OT
    : Math.min(100, Math.round((workMs/refMs)*100));

  let fillCls='';
  if(statusKey==='half_day'||statusKey==='late_half') fillCls=' half-fill';
  else if(statusKey==='late')                          fillCls=' late-fill';
  else if(statusKey==='absent')                        fillCls=' absent-fill';
  else if(isOT)                                        fillCls=' overtime-fill';
  else if(statusKey==='auto_close')                    fillCls=' auto-fill';

  /* Shift end marker — a tick at 100% on the track */
  const shiftEnd=_getShiftEndMs(rec||{});
  const shiftTick= (shiftEnd>0 && rec && rec.punchInTime && !rec.punchOutTime)
    ? `<div style="position:absolute;top:-2px;left:calc(${Math.min(98,Math.round((refMs/Math.max(refMs,workMs+OT_GRACE_MS))*100))}% - 1px);
                   width:2px;height:9px;background:#7c3aed;border-radius:1px" title="Shift end"></div>` : '';

  return `<div class="att-hours-bar">
    <div class="att-hours-track" style="position:relative">
      <div class="att-hours-fill${fillCls}" style="width:${Math.min(100,pct)}%"></div>
      ${shiftTick}
    </div>
    <div class="att-hours-label">${_fmtMs(workMs)}</div>
  </div>`;
}

/* Status explanation chip shown in the expanded timeline row */
function _buildStatusExplanation(attStatus, d){
  if(!attStatus || attStatus==='pending' || attStatus==='no_checkin') return '';
  const cfg=DAY_STATUS_CFG[attStatus]||DAY_STATUS_CFG['pending'];
  const workH=(d?_computeWorkMs(d):0)/3600000;
  const fullH=FULL_MS/3600000;
  const halfH=HALF_MS/3600000;
  let reason='';
  switch(attStatus){
    case 'full_day':      reason=`Checked in on time and completed ≥${fullH.toFixed(1)}h of work.`; break;
    case 'overtime':      reason=`Completed full shift and worked beyond ${fullH.toFixed(1)}h (${workH.toFixed(1)}h total). Overtime recorded.`; break;
    case 'half_day':      reason=`Checked in on time but only completed ${workH.toFixed(1)}h (between ${halfH.toFixed(1)}h and ${fullH.toFixed(1)}h).`; break;
    case 'absent':        reason=`Less than ${halfH.toFixed(1)}h worked (${workH.toFixed(1)}h) — marked Absent.`; break;
    case 'late':          reason=`Checked in after the grace deadline. Completed ≥${fullH.toFixed(1)}h so full-day credit — but Late Mark applied.`; break;
    case 'late_half':     reason=`Late check-in AND only ${workH.toFixed(1)}h worked (< ${fullH.toFixed(1)}h).`; break;
    case 'late_overtime': reason=`Late check-in but worked ${workH.toFixed(1)}h — beyond the full shift.`; break;
    case 'auto_close': {
      const wqKey = (d&&d.workQualityStatus) ? _normaliseStatus(d.workQualityStatus) : null;
      const wqLabel = wqKey && wqKey!=='auto_close' && DAY_STATUS_CFG[wqKey] ? DAY_STATUS_CFG[wqKey].label : null;
      const workH=(d?_computeWorkMs(d):0)/3600000;
      reason = wqLabel
        ? `Session auto-closed by system — staff worked ${workH.toFixed(1)}h (${wqLabel}). Contact admin to adjust if needed.`
        : `Session was automatically closed by the system (staff did not punch out). Admin review recommended.`;
      break;
    }
    default: reason=''; break;
  }
  if(!reason) return '';
  return `<div style="margin-top:.55rem;font-size:.72rem;background:#f8faff;border:1px solid #e2e8f0;
                      border-left:3px solid #0ea5e9;border-radius:8px;padding:6px 10px;color:#334155">
    <i class="bi bi-info-circle" style="color:#0ea5e9"></i> ${reason}
  </div>`;
}

/* ══════════════════════════════════════════════════════════════
   TIMELINE EXPAND
══════════════════════════════════════════════════════════════ */
function _toggleExpand(expandId,e){
  if(e&&e.target.closest&&e.target.closest('.qa-wrap')) return;
  const row=document.getElementById(expandId);
  if(!row) return;
  row.classList.toggle('open');
}
function _viewTimeline(expandId){
  _closeAllMenus();
  const row=document.getElementById(expandId);
  if(row){ row.classList.add('open'); row.scrollIntoView({behavior:'smooth',block:'nearest'}); }
}
function _buildTimeline(d){
  if(!d.log||!d.log.length) return '<div style="color:#64748b;font-size:12px">No log entries.</div>';
  return '<div class="timeline">'+
    d.log.map((e,i)=>{
      const raw=e.dotClass||'';
      const dotCls=raw.includes('in')?'in':raw.includes('break')||raw.includes('brk')?'brk':'out';
      const extra=e.extraHtml?`<span style="font-size:.65rem;color:#0369a1;margin-left:4px">${e.extraHtml}</span>`:'';
      return `<div class="tl-step"><div class="tl-dot ${dotCls}"></div>${e.event||e.eventLabel||''} <span style="color:#64748b">${e.timeStr||''}</span>${extra}</div>`+
             (i<d.log.length-1?'<span class="tl-arrow"><i class="bi bi-chevron-right"></i></span>':'');
    }).join('')+
  '</div>';
}

/* ══════════════════════════════════════════════════════════════
   QUICK ACTION MENU
══════════════════════════════════════════════════════════════ */
function toggleMenu(e,idx){
  e.stopPropagation();
  const menuId='qa-menu-'+idx;
  const isOpen=document.getElementById(menuId).classList.contains('open');
  _closeAllMenus();
  if(!isOpen){ document.getElementById(menuId).classList.add('open'); _openMenuId=idx; }
}
function _closeAllMenus(){
  document.querySelectorAll('.qa-menu.open').forEach(m=>m.classList.remove('open'));
  _openMenuId=null;
}
function _copyUsername(name){
  navigator.clipboard.writeText(name).then(()=>_amToast('Copied: '+name,'info'));
  _closeAllMenus();
}
/* ── Force Punch-Out with reason modal ── */
function _forcePunchOut(username){
  _closeAllMenus();
  /* Build a lightweight inline modal for the reason */
  const existing = document.getElementById('forcePunchOutModal');
  if(existing) existing.remove();

  const modal = document.createElement('div');
  modal.id = 'forcePunchOutModal';
  modal.style.cssText = 'position:fixed;inset:0;z-index:10000;background:rgba(0,0,0,.5);'
    + 'display:flex;align-items:center;justify-content:center;padding:1rem';
  modal.innerHTML = `
    <div style="background:#1e2d3d;border-radius:14px;padding:1.5rem;width:100%;max-width:440px;
                box-shadow:0 20px 60px rgba(0,0,0,.4);border:1px solid #2d4a6b">
      <div style="display:flex;align-items:center;gap:.7rem;margin-bottom:1rem">
        <div style="width:36px;height:36px;border-radius:50%;background:rgba(239,68,68,.15);
                    display:flex;align-items:center;justify-content:center;flex-shrink:0">
          <i class="bi bi-clock-history" style="color:#ef4444;font-size:1rem"></i>
        </div>
        <div>
          <div style="font-weight:700;color:#f1f5f9;font-size:.95rem">Force Punch-Out</div>
          <div style="font-size:.75rem;color:#64748b">Staff: <b style="color:#93c5fd">${username}</b></div>
        </div>
        <button onclick="document.getElementById('forcePunchOutModal').remove()"
                style="margin-left:auto;background:none;border:none;color:#64748b;cursor:pointer;font-size:1.1rem">
          <i class="bi bi-x-lg"></i>
        </button>
      </div>
      <div style="background:rgba(239,68,68,.08);border:1px solid rgba(239,68,68,.2);border-radius:8px;
                  padding:.65rem .85rem;font-size:.76rem;color:#fca5a5;margin-bottom:1rem">
        <i class="bi bi-info-circle-fill"></i>
        Punch-out will be normalised to the <strong>scheduled shift-end time</strong> if the shift has
        already ended, or set to <strong>now</strong> if still in progress.
        This action is logged and visible to the staff member.
      </div>
      <label style="display:block;font-size:.75rem;font-weight:600;color:#94a3b8;margin-bottom:.4rem">
        Reason <span style="color:#ef4444">*</span>
      </label>
      <textarea id="forcePunchOutNote" rows="3" placeholder="Enter reason for force punch-out..."
        style="width:100%;background:#0c1a2e;border:1px solid #2d4a6b;border-radius:8px;
               color:#e2e8f0;font-size:.82rem;padding:.5rem .7rem;resize:vertical;
               outline:none;box-sizing:border-box"></textarea>
      <div style="display:flex;gap:.6rem;margin-top:1rem;justify-content:flex-end">
        <button onclick="document.getElementById('forcePunchOutModal').remove()"
          style="padding:.5rem 1rem;border:1px solid #2d4a6b;border-radius:8px;background:none;
                 color:#94a3b8;cursor:pointer;font-size:.8rem">Cancel</button>
        <button onclick="_submitForcePunchOut('${username}')"
          style="padding:.5rem 1.2rem;border:none;border-radius:8px;background:#ef4444;
                 color:#fff;cursor:pointer;font-size:.8rem;font-weight:600">
          <i class="bi bi-box-arrow-right"></i> Confirm Force Punch-Out
        </button>
      </div>
    </div>`;
  document.body.appendChild(modal);
  setTimeout(()=>{ const el=document.getElementById('forcePunchOutNote'); if(el) el.focus(); },100);
}

function _submitForcePunchOut(username){
  const note = (document.getElementById('forcePunchOutNote').value||'').trim();
  if(!note){ _amToast('Please enter a reason for the force punch-out.','warning'); return; }
  document.getElementById('forcePunchOutModal').remove();

  fetch('AttendanceServlet',{method:'POST',
    body:new URLSearchParams({action:'adminForcePunchOut', username, note})})
    .then(r=>r.json())
    .then(d=>{
      if(d.ok){
        _amToast(d.toastMsg||('✅ Force punch-out applied for '+username),'success');
        setTimeout(()=>loadData(false), 600);
      } else if(d.noSession){
        /* Session already closed or beyond 7-day window — show info, refresh */
        _amToast('ℹ No open session found for "'+username+'". '
          +'The session may have already been closed by the system or manually. '
          +'Refreshing the monitor…','warning');
        setTimeout(()=>loadData(false), 1500);
      } else {
        _amToast(d.error||'Force punch-out failed.','error');
      }
    })
    .catch(()=>_amToast('Network error — force punch-out not saved.','error'));
}
document.addEventListener('click',e=>{ if(!e.target.closest('.qa-wrap')) _closeAllMenus(); });

/* ══════════════════════════════════════════════════════════════
   ADJUST SESSION MODAL
══════════════════════════════════════════════════════════════ */
function amOpenModal(username,punchInMs,punchOutMs){
  _closeAllMenus();
  const dateVal = document.getElementById('attDateFilter').value;
  const displayDate = dateVal
    ? new Date(dateVal + 'T00:00:00').toLocaleDateString('en-GB',{day:'2-digit',month:'short',year:'numeric'})
    : 'Today';
  document.getElementById('amModalUsername').value        = username;
  document.getElementById('amModalStaffName').textContent = username;
  document.getElementById('amModalSessionDate').textContent = displayDate; /* BUG FIX: show date */
  document.getElementById('amModalPunchIn').value         = punchInMs  ? _msToTime(punchInMs)  : '';
  document.getElementById('amModalPunchOut').value        = punchOutMs ? _msToTime(punchOutMs) : '';
  document.getElementById('amModalNote').value            = '';
  document.getElementById('amTimeError').style.display    = 'none'; /* BUG FIX: clear stale error */
  document.getElementById('amAdjustModal').classList.add('open');
}
function amCloseModal(){
  document.getElementById('amAdjustModal').classList.remove('open');
}
/* BUG FIX: real-time time validation */
function amValidateTimes(){
  const pi = document.getElementById('amModalPunchIn').value;
  const po = document.getElementById('amModalPunchOut').value;
  const errEl = document.getElementById('amTimeError');
  if(pi && po && po <= pi){
    errEl.textContent = '⚠ Punch-out is before punch-in — will be treated as overnight (next calendar day).';
    errEl.style.display = 'block';
  } else {
    errEl.style.display = 'none';
  }
}
function amSaveAdjustment(){
  const note     = document.getElementById('amModalNote').value.trim();
  const user     = document.getElementById('amModalUsername').value;
  const punchIn  = document.getElementById('amModalPunchIn').value;
  const punchOut = document.getElementById('amModalPunchOut').value;
  const dateVal  = document.getElementById('attDateFilter').value;

  if(!note){ _amToast('Please enter a reason for the adjustment.','warning'); return; }
  /* BUG FIX: both blank = nothing to save */
  if(!punchIn && !punchOut){ _amToast('Please provide at least one corrected time.','warning'); return; }

  const btn = document.querySelector('#amAdjustModal .am-btn-save');
  if(btn){ btn.disabled=true; btn.textContent='Saving...'; }

  fetch('AttendanceServlet',{method:'POST',body:new URLSearchParams({
    action:      'adminAdjustSession',
    username:     user,
    sessionDate:  dateVal,
    punchIn,
    punchOut,
    note
  })})
    .then(r=>r.json())
    .then(d=>{
      if(d.ok){
        _amToast(d.toastMsg||'Session adjusted for '+user+'.','success');
        amCloseModal();
        setTimeout(()=>loadData(false), 500);
      } else {
        _amToast(d.error||'Adjustment failed.','error');
      }
    })
    .catch(()=>_amToast('Network error — adjustment not saved.','error'))
    .finally(()=>{ if(btn){ btn.disabled=false; btn.textContent='Save Changes'; } });
}
document.getElementById('amAdjustModal').addEventListener('click',e=>{
  if(e.target===document.getElementById('amAdjustModal')) amCloseModal();
});
function _msToTime(ms){
  const d=new Date(ms);
  return String(d.getHours()).padStart(2,'0')+':'+String(d.getMinutes()).padStart(2,'0');
}

/* ── Inline toast ── */
function _amToast(msg,type){
  const icons={success:'check-circle-fill',error:'x-circle-fill',info:'info-circle-fill',warning:'exclamation-triangle-fill'};
  const colors={success:'#166534',error:'#991b1b',info:'#0369a1',warning:'#b45309'};
  const t=document.createElement('div');
  t.style.cssText='position:fixed;bottom:24px;right:24px;z-index:9999;display:flex;align-items:center;gap:10px;'
    +'background:'+(colors[type]||colors.info)+';color:#fff;border-radius:10px;padding:12px 18px;'
    +'font-size:13px;font-weight:500;box-shadow:0 8px 24px rgba(0,0,0,.2);min-width:220px;max-width:380px;line-height:1.4;'
    +'animation:toastIn .2s ease';
  t.innerHTML=`<i class="bi bi-${icons[type]||'info-circle-fill'}" style="flex-shrink:0"></i><span>${msg}</span>`;
  document.body.appendChild(t);
  const dur=type==='warning'||type==='error'?6000:3500;
  setTimeout(()=>{ t.style.transition='all .3s'; t.style.opacity='0'; t.style.transform='translateX(20px)'; setTimeout(()=>t.remove(),300); },dur);
}

/* ══════════════════════════════════════════════════════════════
   FORMATTERS & HELPERS
══════════════════════════════════════════════════════════════ */
function _fmtTime(ms){
  return new Date(ms).toLocaleTimeString('en-IN',{hour:'2-digit',minute:'2-digit',hour12:true});
}
function _fmtMs(ms){
  if(!ms||ms<=0) return '0m';
  const h=Math.floor(ms/3600000), m=Math.floor((ms%3600000)/60000);
  return h>0?`${h}h ${m}m`:`${m}m`;
}
function _initials(name){
  if(!name) return '??';
  const parts=name.trim().split(/[\s._]+/);
  return parts.length>=2?(parts[0][0]+parts[1][0]).toUpperCase():name.substring(0,2).toUpperCase();
}
function _avatarColor(name){
  const colors=['#0ea5e9','#7c3aed','#0891b2','#059669','#d97706','#dc2626','#db2777'];
  let h=0; for(const c of name) h=(h*31+c.charCodeAt(0))&0xffffffff;
  return colors[Math.abs(h)%colors.length];
}
function _countBreaks(d){
  if(!d.log) return 0;
  return d.log.filter(e=>(e.event&&e.event.toLowerCase().includes('break start'))||e.eventType==='BREAK_START').length;
}
function _esc(s){ return String(s||'').replace(/&/g,'&amp;').replace(/"/g,'&quot;').replace(/</g,'&lt;'); }

/* legacy aliases used by export & other callers */
function fmtMs(ms){ return _fmtMs(ms); }
function fmtTimestamp(ts){ if(!ts) return '—'; return _fmtTime(ts); }
function getInitials(name){ return _initials(name); }
function computeWorkMs(rec){ return _computeWorkMs(rec); }
function computeBreakMs(rec){ return _computeBreakMs(rec); }
function computeAttStatus(a,b,c){ return _computeAttStatus(a,b,c,null); }

/* ══════════════════════════════════════════════════════════════
   ADMIN TAB ENGINE  (mirrors adminDashboard.jsp features)
══════════════════════════════════════════════════════════════ */

let _admCachedShifts = [];

/* ── Tab routing ── */
function admSwitchTab(tab, btn) {
  document.querySelectorAll('.adm-tab-pane').forEach(p => p.classList.remove('adm-visible'));
  document.querySelectorAll('.adm-tab').forEach(b => b.classList.remove('adm-active'));
  const pane = document.getElementById('adm-tab-' + tab);
  if (pane) pane.classList.add('adm-visible');
  if (btn) btn.classList.add('adm-active');

  if (tab === 'overview')       admRefreshOverview();
  if (tab === 'shifts')         admLoadShifts();
  if (tab === 'assign')         admLoadAssignments();
  if (tab === 'notifications')  admLoadNotifications();
}

/* ── Overview / snapshot ── */
function admRefreshOverview() {
  const d = new Date();
  const el = document.getElementById('admOverviewDateLabel');
  if (el) el.textContent = d.toLocaleDateString('en-IN', {weekday:'long',day:'numeric',month:'long',year:'numeric'});

  const iso = d.toISOString().slice(0, 10);
  fetch('AttendanceServlet?action=allStaff&date=' + iso, {headers:{'X-Requested-With':'XMLHttpRequest'}})
    .then(r => r.json())
    .then(data => {
      /* Seed cache from inline shiftDetails (same fix as loadData) */
      data.forEach(row=>{
        if(row.shiftId && row.shiftDetails && !_cachedShiftMs[row.shiftId]){
          const s=row.shiftDetails;
          const lp=s.loginTime.split(':').map(Number);
          const op=s.logoutTime.split(':').map(Number);
          const lMins=lp[0]*60+lp[1], oMins=op[0]*60+op[1];
          let diff=oMins-lMins; if(diff<=0) diff+=1440;
          _cachedShiftMs[row.shiftId]={
            durationMs:s.shiftDurationMs||diff*60000,
            lateMins:lMins+(s.graceMinutes||60),
            loginH:lp[0],loginM:lp[1],logoutH:op[0],logoutM:op[1],
            graceMin:s.graceMinutes||60,name:s.shiftName||'',overnight:oMins<lMins
          };
        }
      });

      let present=0, late=0, absent=0, onBreak=0, out=0, ot=0, ac=0;
      data.forEach(s => {
        if (s.status === 'working')   present++;
        if (s.status === 'onBreak')   onBreak++;
        if (s.status === 'punchedOut' || s.status === 'missed_punchout') out++;
        if (s.status === 'absent')    absent++;
        const wMs = _computeWorkMs(s);
        const as  = _normaliseStatus(s.attendanceStatus)
                  || _computeAttStatus(s.punchInTime, s.punchOutTime, wMs, s.shiftId);
        if (as === 'late' || as === 'late_half' || as === 'late_overtime') late++;
        if (as === 'overtime' || as === 'late_overtime')                   ot++;
        if (as === 'auto_close')                                           ac++;
      });
      _setVal('admStatPresent', present);
      _setVal('admStatLate',    late);
      _setVal('admStatAbsent',  absent);
      _setVal('admStatBreak',   onBreak);
      _setVal('admStatOut',     out);
      _setVal('admStatOT',      ot);
      _setVal('admStatAC',      ac);

      // Summary table with status explanation tooltip
      const rows = data.map(s => {
        const wMs    = _computeWorkMs(s);
        const sEnd   = _getShiftEndMs(s);
        const isPast = sEnd>0 && !s.punchOutTime && Date.now()>sEnd;
        const as     = _normaliseStatus(s.attendanceStatus)
                     || _computeAttStatus(s.punchInTime, s.punchOutTime, wMs, s.shiftId);
        const cfg    = DAY_STATUS_CFG[as] || DAY_STATUS_CFG['pending'];
        /* Net hours colour */
        let netColor='#334155';
        if(as==='absent')                              netColor='#dc2626';
        else if(as==='full_day'||as==='late')          netColor='#059669';
        else if(as==='overtime'||as==='late_overtime') netColor='#7c3aed';
        /* auto_close rows use quality status for colour */
        else if(as==='half_day'||as==='late_half')     netColor='#0891b2';

        const punchOutDisplay = s.punchOutTime
          ? `<span class="mono">${_fmtTime(s.punchOutTime)}</span>`
          : isPast
            ? `<span style="color:#f59e0b;font-size:.75rem"><i class="bi bi-alarm-fill"></i> ${_fmtTime(sEnd)}</span>`
            : `<span style="color:#94a3b8;font-size:.75rem">active</span>`;

        return `<tr>
          <td><strong>${_esc(s.username)}</strong></td>
          <td class="mono">${s.punchInTime ? _fmtTime(s.punchInTime) : '—'}</td>
          <td>${punchOutDisplay}</td>
          <td style="font-weight:700;color:${netColor}">${wMs > 0 ? _fmtMs(wMs) : '—'}</td>
          <td>${_statusPill(s.status)}</td>
          <td title="${cfg.cls}">${_dayStatusPill(as, s.isLate||false)}</td>
        </tr>`;
      }).join('');
      const tb = document.getElementById('admOverviewTbody');
      if (tb) tb.innerHTML = rows ||
        '<tr><td colspan="6" style="text-align:center;padding:2rem;color:#94a3b8">No sessions found</td></tr>';
    })
    .catch(() => {});

  // Pull notification count
  fetch('AttendanceServlet?action=notifications', {headers:{'X-Requested-With':'XMLHttpRequest'}})
    .then(r => r.json())
    .then(data => { _setVal('admStatNotifs', data.count || 0); })
    .catch(() => {});
}

function _setVal(id, v) { const el = document.getElementById(id); if (el) el.textContent = v; }

/* ── Shifts ── */
async function admLoadShifts() {
  try {
    const res  = await fetch('AttendanceServlet?action=shifts');
    const data = await res.json();
    _admCachedShifts = data;
    _admRenderShiftCards(data);
  } catch(e) { _amToast('Failed to load shifts', 'error'); }
}

function _admRenderShiftCards(shifts) {
  const grid = document.getElementById('admShiftGrid');
  if (!grid) return;
  if (!shifts.length) {
    grid.innerHTML = '<p style="color:#94a3b8;font-size:.8rem">No shifts defined yet.</p>';
    return;
  }
  grid.innerHTML = shifts.map(s => `
    <div class="adm-shift-card" onclick="admEditShift(${s.id})">
      <div class="sc-name">${s.shiftName}</div>
      <div class="sc-row">
        <span><i class="bi bi-box-arrow-in-right"></i> ${_admFmtTime(s.loginTime)}</span>
        <span><i class="bi bi-box-arrow-left"></i> ${_admFmtTime(s.logoutTime)}</span>
        <span><i class="bi bi-hourglass-split"></i> ${s.graceMinutes}m grace</span>
      </div>
    </div>`).join('');
}

function _admFmtTime(t) {
  if (!t) return '—';
  const [h, m] = t.split(':');
  const hour = parseInt(h, 10);
  return ((hour % 12) || 12) + ':' + m + ' ' + (hour >= 12 ? 'PM' : 'AM');
}

function admEditShift(id) {
  const s = _admCachedShifts.find(x => x.id === id);
  if (!s) return;
  document.getElementById('admSfId').value    = s.id;
  document.getElementById('admSfName').value  = s.shiftName;
  document.getElementById('admSfLogin').value = s.loginTime;
  document.getElementById('admSfLogout').value= s.logoutTime;
  document.getElementById('admSfGrace').value = s.graceMinutes;
  document.getElementById('admShiftFormTitle').textContent = 'Edit Shift — ' + s.shiftName;
  document.getElementById('admSfBtnLabel').textContent     = 'Update Shift';
  document.getElementById('admShiftClearBtn').style.display = '';
  document.querySelector('.adm-panel:last-child')?.scrollIntoView({behavior:'smooth'});
}

function admClearShiftForm() {
  document.getElementById('admSfId').value     = '';
  document.getElementById('admSfName').value   = '';
  document.getElementById('admSfLogin').value  = '09:00';
  document.getElementById('admSfLogout').value = '18:00';
  document.getElementById('admSfGrace').value  = '60';
  document.getElementById('admShiftFormTitle').textContent = 'Create New Shift';
  document.getElementById('admSfBtnLabel').textContent     = 'Save Shift';
  document.getElementById('admShiftClearBtn').style.display = 'none';
}

async function admSaveShift() {
  const name  = document.getElementById('admSfName').value.trim();
  const login = document.getElementById('admSfLogin').value;
  const logout= document.getElementById('admSfLogout').value;
  const grace = document.getElementById('admSfGrace').value;
  if (!name) { _amToast('Shift name is required', 'error'); return; }

  const payload = new URLSearchParams({
    action:       'saveShift',
    shiftId:      document.getElementById('admSfId').value,
    shiftName:    name,
    loginTime:    login,
    logoutTime:   logout,
    graceMinutes: grace,
  });

  try {
    const res  = await fetch('AttendanceServlet', {method:'POST', body: payload});
    const data = await res.json();
    if (data.ok) {
      _amToast('Shift saved successfully', 'success');
      admClearShiftForm();
      admLoadShifts();
      admLoadAssignments();
    } else {
      _amToast(data.error || 'Save failed', 'error');
    }
  } catch(e) { _amToast('Request failed', 'error'); }
}

/* ── Staff Shift Assignment ── */
async function admLoadAssignments() {
  if (!_admCachedShifts.length) {
    try {
      const r = await fetch('AttendanceServlet?action=shifts');
      _admCachedShifts = await r.json();
    } catch(e) {}
  }

  try {
    const res  = await fetch('AttendanceServlet?action=staffList');
    const data = await res.json();

    const opts = _admCachedShifts.map(s =>
      `<option value="${s.id}">${s.shiftName}</option>`
    ).join('');

    const rows = data.map(u => {
      const pill = u.shiftId
        ? `<span class="adm-shift-pill">${u.shiftName || 'ID ' + u.shiftId}</span>`
        : `<span class="adm-shift-pill unassigned">Unassigned</span>`;
      return `<tr>
        <td><strong>${_esc(u.username)}</strong></td>
        <td style="color:#64748b">${u.department || '—'}</td>
        <td>${pill}</td>
        <td>
          <div style="display:flex;gap:.5rem;align-items:center">
            <select id="admSel-${_esc(u.username)}" class="adm-form-ctrl" style="max-width:160px;padding:.3rem .6rem;font-size:.78rem">
              <option value="">— Remove —</option>
              ${opts}
            </select>
            <button class="adm-btn adm-btn-primary adm-btn-sm" onclick="admAssignShift('${_esc(u.username)}')">
              <i class="bi bi-check2"></i> Apply
            </button>
          </div>
        </td>
      </tr>`;
    }).join('');

    const tb = document.getElementById('admAssignTbody');
    if (tb) tb.innerHTML = rows || '<tr><td colspan="4" style="text-align:center;padding:2rem;color:#94a3b8">No staff found</td></tr>';

    data.forEach(u => {
      const sel = document.getElementById(`admSel-${u.username}`);
      if (sel && u.shiftId) sel.value = u.shiftId;
    });
  } catch(e) { _amToast('Failed to load staff list', 'error'); }
}

async function admAssignShift(username) {
  const sel     = document.getElementById(`admSel-${username}`);
  const shiftId = sel ? sel.value : '';
  const payload = new URLSearchParams({action:'assignShift', username, shiftId});

  try {
    const res  = await fetch('AttendanceServlet', {method:'POST', body: payload});
    const data = await res.json();
    if (data.ok) {
      _amToast(username + ' → shift updated', 'success');
      admLoadAssignments();
    } else {
      _amToast(data.error || 'Assignment failed', 'error');
    }
  } catch(e) { _amToast('Request failed', 'error'); }
}

/* ── Notifications ── */
async function admLoadNotifications() {
  try {
    const res  = await fetch('AttendanceServlet?action=notifications');
    const data = await res.json();
    const count = data.count || 0;

    // update badge on tab
    const badge = document.getElementById('admNotifBadge');
    if (badge) {
      badge.textContent   = count > 99 ? '99+' : count;
      badge.style.display = count > 0 ? '' : 'none';
    }

    const feed = document.getElementById('admNotifFeed');
    if (!feed) return;

    if (!data.items || !data.items.length) {
      feed.innerHTML = `<div style="text-align:center;padding:2.5rem;color:#94a3b8">
        <i class="bi bi-check-circle-fill" style="font-size:2rem;color:#22c55e;display:block;margin-bottom:.5rem"></i>
        All clear — no unread notifications</div>`;
      return;
    }

    feed.innerHTML = data.items.map(n => `
      <div class="adm-notif-item" id="admNotif-${n.id}">
        <div class="adm-notif-icon"><i class="bi bi-exclamation-triangle-fill"></i></div>
        <div>
          <div class="adm-notif-title">${n.title || n.type}</div>
          <div class="adm-notif-msg">${n.message}</div>
          <div class="adm-notif-time"><i class="bi bi-clock"></i> ${n.createdAt}</div>
        </div>
        <div class="adm-notif-actions">
          <button class="adm-btn adm-btn-outline adm-btn-sm" onclick="admMarkRead(${n.id})">
            <i class="bi bi-eye"></i> Read
          </button>
          <button class="adm-btn adm-btn-danger adm-btn-sm" onclick="admDismissNotif(${n.id})">
            <i class="bi bi-x-lg"></i>
          </button>
        </div>
      </div>`).join('');

  } catch(e) { _amToast('Failed to load notifications', 'error'); }
}

async function admMarkRead(id) {
  await fetch('AttendanceServlet', {method:'POST', body: new URLSearchParams({action:'markNotifRead', id})});
  document.getElementById(`admNotif-${id}`)?.remove();
  admLoadNotifications();
}

async function admDismissNotif(id) {
  await fetch('AttendanceServlet', {method:'POST', body: new URLSearchParams({action:'dismissNotif', id})});
  document.getElementById(`admNotif-${id}`)?.remove();
  admLoadNotifications();
}

async function admDismissAll() {
  const items = document.querySelectorAll('.adm-notif-item');
  for (const item of items) {
    const id = item.id.replace('admNotif-', '');
    await fetch('AttendanceServlet', {method:'POST', body: new URLSearchParams({action:'dismissNotif', id})});
  }
  admLoadNotifications();
  _amToast('All notifications dismissed', 'success');
}

/* Auto-poll notifications every 60 s for badge updates */
setInterval(() => {
  if (document.getElementById('attMonitorPanel')?.style.display !== 'none') {
    admLoadNotifications();
  }
}, 60000);

/* ══════════════════════════════════════════════════════════════
   CSV EXPORT
══════════════════════════════════════════════════════════════ */
function exportCSV(){
  const filtered=_allRows; /* export whatever is currently loaded */
  const rows=[['#','Staff','Punch Status','Attendance Status','Punch In','Punch Out','Work Time','Break Time','Net Hours']];
  filtered.forEach((rec,i)=>{
    const wMs=_computeWorkMs(rec),bMs=_computeBreakMs(rec);
    const as=rec.attendanceStatus||_computeAttStatus(rec.punchInTime,rec.punchOutTime,wMs);
    rows.push([
      i+1, rec.username,
      rec.status, (DAY_STATUS_CFG[as]||{label:as}).label,
      fmtTimestamp(rec.punchInTime), fmtTimestamp(rec.punchOutTime),
      _fmtMs(wMs), _fmtMs(bMs), _fmtMs(wMs)
    ]);
  });
  const csv=rows.map(r=>r.map(c=>'"'+String(c).replace(/"/g,'""')+'"').join(',')).join('\n');
  const a=document.createElement('a');
  a.href='data:text/csv;charset=utf-8,'+encodeURIComponent(csv);
  a.download='attendance_'+document.getElementById('attDateFilter').value+'.csv';
  a.click();
}
function refreshLeaveBadge(){
	  fetch('AdminLeaveServlet?action=stats')
	    .then(r=>r.json())
	    .then(d=>{
	      const b=document.getElementById('sidebarLeaveBadge');
	      if(b){
	        b.textContent=d.pending;
	        b.style.display=d.pending>0?'':'none';
	      }
	    }).catch(()=>{});
	}
	refreshLeaveBadge();
	setInterval(refreshLeaveBadge, 60000);

	/* helper called by sidebar link to auto-scroll to leave panel after fragment loads */
	function lvScrollToLeavePanel(){
	  setTimeout(()=>{
	    const p=document.getElementById('lvPanel');
	    if(p) p.scrollIntoView({behavior:'smooth',block:'start'});
	  }, 600); // wait for AJAX fragment to render
	}
</script>
</body>
</html>
