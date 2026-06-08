<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="false"%>
<%@ page import="com.util.*, java.util.*" %>
<%
    String role  = (session != null) ? (String) session.getAttribute("role")     : null;
    String uname = (session != null) ? (String) session.getAttribute("username") : null;

    if (role == null || (!("staff".equalsIgnoreCase(role)) && !("admin".equalsIgnoreCase(role)))) {
        response.sendRedirect("index.jsp?error=Access+denied.");
        return;
    }

    int unreadNotifCount = session.getAttribute("unreadNotifCount") != null
        ? (Integer) session.getAttribute("unreadNotifCount") : 0;

    String initials = (uname != null && uname.length() >= 2)
        ? uname.substring(0,2).toUpperCase()
        : (uname != null ? uname.toUpperCase() : "ST");
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
  <title>Bills &amp; Invoices — SmartStock</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
  <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
  <style>
    /* ══════════════════════════════════════════════════════════════
       ROOT VARIABLES — matches userDashboard / OrdersDashboard theme
    ══════════════════════════════════════════════════════════════ */
    :root {
      --primary:      #27d2c2;
      --primary-mid:  #63b3f9fc;
      --primary-light:#e0e7ff;
      --accent:       #6366f1;
      --accent-h:     #4f46e5;
      --accent-light: #eef2ff;
      --coral:        #f97316;
      --coral-bg:     #fff7ed;
      --success:      #059669; --success-bg: #d1fae5;
      --warning:      #d97706; --warning-bg: #fef3c7;
      --danger:       #dc2626; --danger-bg:  #fee2e2;
      --purple:       #7c3aed; --purple-bg:  #ede9fe;
      --teal:         #0891b2; --teal-bg:    #cffafe;
      --gold:         #d97706; --gold-bg:    #fffbeb;
      --text:         #1e1b4b;
      --text-mid:     #4b5563;
      --text-soft:    #6b7280;
      --text-muted:   #9ca3af;
      --border:       #e0e7ff;
      --bg:           #f8fafc;
      --bg-off:       #f3f4f6;
      --card:         #ffffff;
      --nav-h:        62px;
      --sidebar-w:    264px;
      --radius:       14px;
      --radius-sm:    9px;
      --shadow:       0 1px 4px rgba(67,56,202,.07),0 4px 18px rgba(67,56,202,.08);
      --shadow-md:    0 6px 28px rgba(67,56,202,.14);
      --shadow-glow:  0 0 0 3px rgba(99,102,241,.18);
    }

    *,*::before,*::after { box-sizing:border-box; margin:0; padding:0 }
    html { font-size:16px }
    body {
      font-family:'Outfit',sans-serif;
      background:var(--bg-off);
      color:var(--text);
      padding-top:var(--nav-h);
      min-height:100vh;
      -webkit-font-smoothing:antialiased;
      padding-bottom:64px;
      background-image:
        radial-gradient(ellipse at 80% 0%,rgba(99,102,241,.07) 0%,transparent 60%),
        radial-gradient(ellipse at 0% 60%,rgba(249,115,22,.05) 0%,transparent 55%);
    }
    @media(min-width:768px){ body { padding-bottom:0 } }

    /* ── Scrollbar ── */
    ::-webkit-scrollbar{width:5px;height:5px}
    ::-webkit-scrollbar-track{background:transparent}
    ::-webkit-scrollbar-thumb{background:#cbd5e1;border-radius:10px}

    /* ══ NAVBAR ══ */
    .top-navbar {
      position:fixed;top:0;left:0;right:0;height:var(--nav-h);z-index:1050;
      background:linear-gradient(135deg,var(--primary) 0%,var(--primary-mid) 100%);
      display:flex;align-items:center;padding:0 1.1rem;gap:.75rem;
      box-shadow:0 2px 20px rgba(67,56,202,.25);
    }
    .hamburger {
      width:40px;height:40px;border-radius:var(--radius-sm);
      background:rgba(255,255,255,.1);border:1px solid rgba(255,255,255,.18);
      color:#fff;display:flex;align-items:center;justify-content:center;
      cursor:pointer;font-size:1.1rem;flex-shrink:0;position:relative;
      transition:all .2s;outline:none;
    }
    .hamburger:hover { background:rgba(255,255,255,.2);border-color:rgba(255,255,255,.4);transform:scale(1.05) }
    .nav-brand {
      font-size:1.1rem;font-weight:800;color:#fff;text-decoration:none;
      display:flex;align-items:center;gap:.4rem;white-space:nowrap;letter-spacing:-.3px;
    }
    .nav-brand .dot { color:#fbbf24 }
    .nav-chip {
      font-size:.6rem;font-weight:700;background:rgba(251,191,36,.2);color:#fbbf24;
      padding:2px 8px;border-radius:20px;letter-spacing:.5px;text-transform:uppercase;
      border:1px solid rgba(251,191,36,.3);
    }
    .nav-right { margin-left:auto;display:flex;align-items:center;gap:.5rem }
    .nav-icon-btn {
      width:36px;height:36px;border-radius:var(--radius-sm);
      background:rgba(255,255,255,.1);border:1px solid rgba(255,255,255,.15);
      color:#fff;display:flex;align-items:center;justify-content:center;
      cursor:pointer;font-size:.95rem;text-decoration:none;transition:all .2s;position:relative;
    }
    .nav-icon-btn:hover { background:rgba(255,255,255,.2);border-color:rgba(255,255,255,.35);color:#fbbf24 }
    .bell-badge {
      position:absolute;top:-4px;right:-4px;background:var(--danger);color:#fff;
      font-size:.55rem;font-weight:700;min-width:16px;height:16px;border-radius:50%;
      display:flex;align-items:center;justify-content:center;border:2px solid var(--primary);
    }
    .nav-avatar {
      width:34px;height:34px;border-radius:50%;
      background:linear-gradient(135deg,#fbbf24,#f97316);
      display:flex;align-items:center;justify-content:center;
      font-size:.72rem;font-weight:800;color:#fff;cursor:pointer;
      border:2px solid rgba(255,255,255,.35);flex-shrink:0;text-decoration:none;
      box-shadow:0 2px 8px rgba(0,0,0,.15);
    }

    /* ══ SIDEBAR ══ */
    .sidebar-overlay {
      position:fixed;inset:0;background:rgba(55,48,163,.25);z-index:990;
      opacity:0;pointer-events:none;transition:opacity .3s;backdrop-filter:blur(4px);
    }
    .sidebar-overlay.open { opacity:1;pointer-events:all }
    .sidebar {
      position:fixed;top:0;left:0;bottom:0;width:var(--sidebar-w);background:#fff;
      z-index:995;transform:translateX(-100%);
      transition:transform .3s cubic-bezier(.4,0,.2,1);
      display:flex;flex-direction:column;overflow:hidden;
      box-shadow:6px 0 30px rgba(67,56,202,.15);border-right:1px solid var(--border);
    }
    .sidebar.open { transform:translateX(0) }
    @media(min-width:768px) {
      .sidebar { transform:translateX(0);box-shadow:none }
      .sidebar-overlay { display:none }
      .main-content { margin-left:var(--sidebar-w);padding:1.5rem 2rem }
      .hamburger { display:flex }
    }
    .sidebar-head {
      background:linear-gradient(150deg,var(--primary) 0%,var(--primary-mid) 100%);
      padding:4.2rem 1.2rem 1.1rem;border-bottom:2px solid rgba(251,191,36,.4);
    }
    .sidebar-brand { font-size:1.05rem;font-weight:800;color:#fff;margin-bottom:1rem;letter-spacing:-.3px }
    .sidebar-brand .dot { color:#fbbf24 }
    .sidebar-user { display:flex;align-items:center;gap:.75rem }
    .sidebar-avatar {
      width:44px;height:44px;border-radius:50%;
      background:linear-gradient(135deg,#fbbf24,#f97316);
      display:flex;align-items:center;justify-content:center;
      font-size:1rem;font-weight:800;color:#fff;flex-shrink:0;
      border:2px solid rgba(255,255,255,.3);box-shadow:0 2px 10px rgba(0,0,0,.2);
    }
    .sidebar-uname { font-size:.9rem;font-weight:700;color:#fff }
    .sidebar-role { font-size:.65rem;font-weight:600;letter-spacing:.8px;text-transform:uppercase;color:#fbbf24;margin-top:1px }
    .sidebar-body { flex:1;overflow-y:auto;padding:.75rem .75rem 1rem;background:#fff }
    .sidebar-section {
      font-size:.62rem;font-weight:700;letter-spacing:1.5px;text-transform:uppercase;
      color:var(--text-muted);padding:.8rem .6rem .3rem;
    }
    .sidebar-link {
      display:flex;align-items:center;gap:.7rem;padding:.6rem .75rem;
      border-radius:var(--radius-sm);color:var(--text-mid);text-decoration:none;
      font-size:.88rem;font-weight:500;transition:all .18s;margin-bottom:2px;
      border-left:3px solid transparent;
    }
    .sidebar-link i { font-size:.95rem;width:18px;text-align:center;color:var(--text-muted);transition:color .18s }
    .sidebar-link:hover,
    .sidebar-link.active { background:var(--accent-light);color:var(--accent);border-left-color:var(--accent) }
    .sidebar-link:hover i,
    .sidebar-link.active i { color:var(--accent) }
    .sidebar-link.active { font-weight:700 }
    .sidebar-link.danger { color:#dc2626 }
    .sidebar-link.danger i { color:#dc2626 }
    .sidebar-link.danger:hover { background:var(--danger-bg);border-left-color:#dc2626 }
    .sidebar-badge {
      margin-left:auto;background:var(--danger-bg);color:var(--danger);
      font-size:.65rem;font-weight:700;padding:1px 7px;border-radius:20px;
      border:1px solid rgba(220,38,38,.2);
    }
    .sidebar-footer {
      padding:.75rem;border-top:1px solid var(--border);
      font-size:.72rem;color:var(--text-muted);text-align:center;background:#fafafa;
    }

     @media(min-width:768px){
      .sidebar{transform:translateX(0);box-shadow:none;border-right:1px solid var(--border)}
      .sidebar-overlay{display:none}
      .main-content{margin-left:var(--sidebar-w);padding:1.5rem 2rem}
      /* Keep hamburger visible so desktop collapse is possible */
      .hamburger{display:flex}
    }
    /* Desktop collapsible sidebar */
    @media(min-width:768px){
      .sidebar.collapsed{transform:translateX(-100%)}
      .main-content.sidebar-collapsed{margin-left:0}
    }

    /* MAIN */
    .main-content{padding:1rem;max-width:100%}

    /* ══ PAGE HEADER ══ */
    .page-header {
      background:linear-gradient(135deg,var(--primary) 0%,var(--primary-mid) 55%,#3aedbba3 100%);
      border-radius:var(--radius);padding:1.4rem 1.5rem;margin-bottom:1.2rem;
      position:relative;overflow:hidden;box-shadow:0 8px 32px rgba(67,56,202,.2);
    }
    .page-header::before {
      content:'';position:absolute;top:-30px;right:-30px;
      width:160px;height:160px;border-radius:50%;background:rgba(251,191,36,.12);pointer-events:none;
    }
    .ph-eyebrow { font-size:.68rem;font-weight:700;color:rgba(255,255,255,.6);text-transform:uppercase;letter-spacing:1px;margin-bottom:4px }
    .ph-title { font-size:1.35rem;font-weight:800;color:#fff;letter-spacing:-.3px;margin-bottom:4px }
    .ph-sub { font-size:.78rem;color:rgba(255,255,255,.65) }
    .ph-actions { display:flex;gap:.5rem;margin-top:.9rem;flex-wrap:wrap }
    .ph-btn {
      display:inline-flex;align-items:center;gap:.4rem;
      padding:.42rem .95rem;border-radius:var(--radius-sm);
      font-size:.78rem;font-weight:600;text-decoration:none;cursor:pointer;
      transition:all .2s;border:1px solid rgba(255,255,255,.3);
      background:rgba(255,255,255,.15);color:#fff;
    }
    .ph-btn:hover { background:rgba(255,255,255,.25);border-color:rgba(255,255,255,.5);color:#fff }
    .ph-btn-solid {
      background:#fff;color:var(--primary);border-color:#fff;
    }
    .ph-btn-solid:hover { background:rgba(255,255,255,.9);color:var(--accent) }

    /* ══ STAT CARDS ══ */
    .stats-row {
      display:grid;grid-template-columns:repeat(2,1fr);gap:.75rem;margin-bottom:1.2rem;
    }
    @media(min-width:480px){ .stats-row { grid-template-columns:repeat(4,1fr) } }
    .stat-card {
      background:var(--card);border:1px solid var(--border);border-radius:var(--radius);
      padding:.875rem 1rem;display:flex;align-items:center;gap:.85rem;
      box-shadow:var(--shadow);transition:all .22s;cursor:default;
      position:relative;overflow:hidden;
    }
    .stat-card::after {
      content:'';position:absolute;bottom:0;left:0;right:0;height:3px;
      background:var(--c,var(--accent));opacity:0;transition:opacity .2s;
    }
    .stat-card:hover { transform:translateY(-3px);box-shadow:var(--shadow-md) }
    .stat-card:hover::after { opacity:1 }
    .stat-icon {
      width:42px;height:42px;border-radius:11px;
      display:flex;align-items:center;justify-content:center;font-size:1.05rem;flex-shrink:0;
    }
    .si-blue   { background:#e8f0fb;color:#2980b9; }
    .si-green  { background:var(--success-bg);color:var(--success); }
    .si-red    { background:var(--danger-bg);color:var(--danger); }
    .si-gold   { background:var(--gold-bg);color:var(--gold); }
    .si-purple { background:var(--purple-bg);color:var(--purple); }
    .si-teal   { background:var(--teal-bg);color:var(--teal); }
    .stat-num { font-size:1.45rem;font-weight:800;line-height:1;letter-spacing:-.5px }
    .stat-lbl { font-size:.66rem;font-weight:600;color:var(--text-muted);text-transform:uppercase;letter-spacing:.8px;margin-top:3px }

    /* ══ TAB NAVIGATION ══ */
    .tab-nav-card {
      background:var(--card);border:1px solid var(--border);border-radius:var(--radius);
      padding:.5rem;margin-bottom:1.2rem;box-shadow:var(--shadow);
      display:flex;gap:.25rem;flex-wrap:wrap;
    }
    .tab-btn {
      flex:1;min-width:130px;display:flex;align-items:center;justify-content:center;gap:.5rem;
      padding:.65rem 1rem;border-radius:var(--radius-sm);border:none;
      font-family:inherit;font-size:.83rem;font-weight:600;cursor:pointer;
      color:var(--text-mid);background:transparent;transition:all .2s;position:relative;
    }
    .tab-btn:hover { background:var(--bg-off);color:var(--text) }
    .tab-btn.active {
      background:var(--accent);color:#fff;
      box-shadow:0 4px 14px rgba(99,102,241,.3);
    }
    .tab-btn i { font-size:1rem }
    .tab-badge {
      font-size:.6rem;font-weight:700;padding:1px 6px;border-radius:12px;
      background:rgba(255,255,255,.25);color:inherit;line-height:1.4;
    }
    .tab-btn:not(.active) .tab-badge { background:var(--danger-bg);color:var(--danger) }

    /* ══ TAB PANELS ══ */
    .tab-panel { display:none }
    .tab-panel.active { display:block }

    /* ══ TOOLBAR ══ */
    .toolbar {
      background:var(--card);border:1px solid var(--border);border-radius:var(--radius);
      padding:.75rem 1rem;display:flex;align-items:center;gap:.6rem;flex-wrap:wrap;
      margin-bottom:1rem;box-shadow:var(--shadow);
    }
    .search-box {
      display:flex;align-items:center;gap:.4rem;background:var(--bg-off);
      border:1px solid var(--border);border-radius:var(--radius-sm);padding:.42rem .85rem;
      transition:all .2s;flex:1;max-width:280px;
    }
    .search-box:focus-within { border-color:var(--accent);box-shadow:0 0 0 3px var(--accent-light) }
    .search-box i { color:var(--text-muted);font-size:.85rem }
    .search-box input { background:none;border:none;outline:none;font-family:inherit;font-size:.83rem;color:var(--text);width:100% }
    .search-box input::placeholder { color:var(--text-muted) }
    .filter-select {
      background:var(--card);border:1px solid var(--border);border-radius:var(--radius-sm);
      padding:.42rem .75rem;font-family:inherit;font-size:.83rem;color:var(--text);
      outline:none;cursor:pointer;transition:all .18s;
    }
    .filter-select:focus { border-color:var(--accent);box-shadow:0 0 0 3px var(--accent-light) }
    .toolbar-right { margin-left:auto;display:flex;align-items:center;gap:.5rem }
    .count-chip {
      font-size:.75rem;color:var(--text-muted);background:var(--bg-off);
      border:1px solid var(--border);border-radius:20px;padding:.2rem .75rem;white-space:nowrap;
    }
    .export-btn {
      display:inline-flex;align-items:center;gap:.35rem;
      padding:.42rem 1rem;border:1.5px solid var(--success);border-radius:var(--radius-sm);
      color:var(--success);background:transparent;font-size:.78rem;font-weight:600;
      text-decoration:none;cursor:pointer;transition:all .2s;
    }
    .export-btn:hover { background:var(--success);color:#fff }

    /* ══ TABLE CARD ══ */
    .table-card {
      background:var(--card);border:1px solid var(--border);border-radius:var(--radius);
      box-shadow:var(--shadow);overflow:hidden;margin-bottom:1.25rem;
    }
    .table-card-header {
      background:linear-gradient(135deg,var(--primary) 0%,var(--primary-mid) 100%);
      padding:.875rem 1.25rem;display:flex;align-items:center;justify-content:space-between;
    }
    .table-card-title { font-size:.9rem;font-weight:700;color:#fff;display:flex;align-items:center;gap:.5rem }
    .table-card-title i { color:#fbbf24 }
    .table-card-meta { font-size:.72rem;color:rgba(255,255,255,.55) }
    .table-scroll { overflow-x:auto;-webkit-overflow-scrolling:touch }
    .data-table { width:100%;border-collapse:collapse;min-width:880px }
    .data-table thead tr { background:rgba(99,102,241,.04);border-bottom:2px solid var(--border) }
    .data-table thead th {
      padding:.75rem 1rem;font-size:.66rem;font-weight:700;
      letter-spacing:1.2px;text-transform:uppercase;color:var(--text-muted);white-space:nowrap;
    }
    .data-table tbody tr { border-bottom:1px solid var(--border);transition:background .15s }
    .data-table tbody tr:last-child { border-bottom:none }
    .data-table tbody tr:hover { background:var(--accent-light) }
    .data-table td { padding:.72rem 1rem;font-size:.86rem;color:var(--text);vertical-align:middle }

    /* ══ CELL TYPES ══ */
    .order-id { font-weight:700;color:var(--accent);font-size:.88rem }
    .cust-name { font-weight:600;color:var(--text) }
    .cust-email { font-size:.72rem;color:var(--text-muted);margin-top:1px }
    .amount-val { font-weight:700;color:var(--success);font-size:.9rem }
    .txn-id { font-size:.76rem;color:var(--text-muted);font-family:monospace }
    .date-val { font-size:.8rem;color:var(--text-mid) }
    .audit-note { font-size:.78rem;color:var(--text-soft);max-width:190px }

    /* ══ STATUS BADGES ══ */
    .badge {
      font-size:.66rem;letter-spacing:.8px;text-transform:uppercase;
      padding:.22rem .65rem;border-radius:20px;font-weight:700;
      display:inline-flex;align-items:center;gap:.3rem;white-space:nowrap;
    }
    .b-pending   { background:#fef3c7;color:#b45309 }
    .b-packed    { background:#e8f0fb;color:#2980b9 }
    .b-shipped   { background:#d6eaf8;color:#154360 }
    .b-ofd       { background:#fff7ed;color:#c2410c }
    .b-delivered { background:var(--success-bg);color:#065f46 }
    .b-cancelled { background:var(--danger-bg);color:#991b1b }
    .b-paid      { background:var(--success-bg);color:#065f46 }
    .b-refunded  { background:var(--purple-bg);color:var(--purple) }
    .b-cod       { background:#fef3c7;color:#b45309 }
    .b-active    { background:var(--success-bg);color:#065f46 }
    .b-restricted{ background:var(--danger-bg);color:#991b1b }

    .pay-pill {
      font-size:.68rem;letter-spacing:.8px;text-transform:uppercase;
      padding:.22rem .65rem;border-radius:20px;font-weight:700;
      display:inline-flex;align-items:center;gap:.3rem;border:1px solid;
    }
    .pp-cod     { background:#fef3c7;color:#b45309;border-color:#fcd34d }
    .pp-card    { background:var(--success-bg);color:#065f46;border-color:#6ee7b7 }
    .pp-unknown { background:var(--bg-off);color:var(--text-muted);border-color:var(--border) }

    /* ══ AGENT / WITHDRAWAL PANEL ══ */
    .panel-card {
      background:var(--card);border:1px solid var(--border);border-radius:var(--radius);
      padding:1.1rem;margin-bottom:1rem;box-shadow:var(--shadow);
    }
    .panel-title {
      font-size:.78rem;font-weight:700;text-transform:uppercase;letter-spacing:1.2px;
      margin-bottom:1rem;display:flex;align-items:center;gap:.5rem;
    }
    .panel-title.amber { color:var(--gold) }
    .panel-title.danger { color:var(--danger) }
    .panel-title.indigo { color:var(--accent) }

    .agent-row {
      display:flex;align-items:center;gap:.75rem;padding:.7rem .85rem;
      border:1px solid var(--border);border-radius:11px;margin-bottom:.5rem;
      background:var(--bg-off);transition:all .18s;
    }
    .agent-row:hover { border-color:rgba(99,102,241,.3);background:var(--accent-light) }
    .agent-row:last-child { margin-bottom:0 }
    .av {
      width:40px;height:40px;border-radius:11px;
      display:flex;align-items:center;justify-content:center;
      font-size:.88rem;font-weight:700;color:#fff;flex-shrink:0;
    }
    .av-blue   { background:linear-gradient(135deg,#3b82f6,#1d4ed8) }
    .av-amber  { background:linear-gradient(135deg,#f59e0b,#d97706) }
    .av-red    { background:linear-gradient(135deg,#f43f5e,#be123c) }
    .av-green  { background:linear-gradient(135deg,#10b981,#059669) }

    .wd-amount { font-family:monospace;font-size:1rem;font-weight:800;color:var(--success) }
    .wd-actions { display:flex;gap:.4rem;margin-top:.5rem;flex-wrap:wrap }

    .btn-act {
      font-family:inherit;font-size:.75rem;font-weight:600;
      padding:.38rem .85rem;border-radius:var(--radius-sm);cursor:pointer;
      transition:all .18s;border:1px solid;display:inline-flex;align-items:center;gap:.3rem;
    }
    .btn-approve { background:var(--success);border-color:var(--success);color:#fff }
    .btn-approve:hover { background:#047857 }
    .btn-reject  { background:transparent;border-color:var(--danger);color:var(--danger) }
    .btn-reject:hover { background:var(--danger);color:#fff }
    .btn-review  { background:transparent;border-color:var(--accent);color:var(--accent) }
    .btn-review:hover { background:var(--accent);color:#fff }
    .btn-unblock { background:transparent;border-color:var(--success);color:var(--success) }
    .btn-unblock:hover { background:var(--success);color:#fff }

    .rej-count-badge {
      display:inline-flex;align-items:center;justify-content:center;
      min-width:26px;height:26px;border-radius:50%;font-size:.75rem;font-weight:800;flex-shrink:0;
    }
    .rc-1 { background:var(--gold-bg);color:var(--gold);border:1px solid rgba(245,158,11,.3) }
    .rc-2 { background:var(--warning-bg);color:var(--warning);border:1px solid rgba(251,146,60,.3) }
    .rc-3 { background:var(--danger-bg);color:var(--danger);border:1px solid rgba(244,63,94,.3) }

    /* ══ EMPTY STATE ══ */
    .empty-state { text-align:center;padding:4rem 2rem;color:var(--text-muted) }
    .empty-state i { font-size:2.8rem;display:block;margin-bottom:.75rem;opacity:.35 }
    .empty-state p { font-size:.9rem }
    .no-results { display:none;text-align:center;padding:3rem 2rem }
    .no-results i { font-size:2rem;color:var(--border);display:block;margin-bottom:.75rem }
    .no-results p { font-size:.88rem;color:var(--text-muted) }

    /* ══ SECTION LABEL ══ */
    .section-label {
      font-size:.72rem;font-weight:700;letter-spacing:1.2px;text-transform:uppercase;
      color:var(--accent);margin-bottom:.75rem;display:flex;align-items:center;gap:.5rem;
    }
    .section-label::after { content:'';flex:1;height:1px;background:linear-gradient(90deg,var(--border),transparent) }

    /* ══ BOTTOM NAV (mobile) ══ */
    .bottom-nav {
      position:fixed;bottom:0;left:0;right:0;z-index:980;
      background:rgba(255,255,255,.95);backdrop-filter:blur(10px);
      border-top:1px solid var(--border);display:flex;justify-content:space-around;
      align-items:center;padding:.4rem 0 .6rem;box-shadow:0 -4px 20px rgba(67,56,202,.1);
    }
    @media(min-width:768px){ .bottom-nav { display:none } }
    .bnav-item {
      flex:1;display:flex;flex-direction:column;align-items:center;gap:2px;
      text-decoration:none;color:#94a3b8;font-size:.6rem;font-weight:600;
      transition:color .15s;position:relative;
    }
    .bnav-item i { font-size:1.2rem }
    .bnav-item.active { color:var(--accent) }
    .bnav-item.active::before {
      content:'';position:absolute;top:-4px;left:50%;transform:translateX(-50%);
      width:24px;height:3px;background:var(--accent);border-radius:2px;
    }

    /* ══ TOAST ══ */
    .toast-wrap { position:fixed;bottom:80px;right:1rem;z-index:2000 }
    @media(min-width:768px){ .toast-wrap { bottom:1.5rem } }
    .toast-msg {
      background:linear-gradient(135deg,var(--primary),var(--primary-mid));color:#fff;
      padding:.75rem 1.1rem;border-radius:var(--radius);font-size:.82rem;font-weight:500;
      display:flex;align-items:center;gap:.5rem;box-shadow:var(--shadow-md);min-width:240px;
      border-left:4px solid #fbbf24;transform:translateX(calc(100% + 1.5rem));
      transition:transform .3s;margin-bottom:.5rem;
    }
    .toast-msg.show { transform:translateX(0) }

    /* ══ ANIMATIONS ══ */
    @keyframes fadeUp { from{opacity:0;transform:translateY(12px)} to{opacity:1;transform:none} }
    .fade-up { animation:fadeUp .38s ease both }
    .fade-up-1 { animation:fadeUp .38s .06s ease both }
    .fade-up-2 { animation:fadeUp .38s .12s ease both }
    .fade-up-3 { animation:fadeUp .38s .18s ease both }
  </style>
</head>
<body>

<!-- ══ NAVBAR ══ -->
<nav class="top-navbar">
  <button class="hamburger" id="toggle-btn" onclick="toggleSidebar()" aria-label="Menu">
    <i class="bi bi-list"></i>
  </button>
  <a href="userDashboard" class="nav-brand">Smart<span class="dot">Stock</span></a>
  <span class="nav-chip">Bills</span>
  <div class="nav-right">
    <a href="StaffNotifications" class="nav-icon-btn" title="Notifications" style="position:relative;">
      <i class="bi bi-bell"></i>
      <% if (unreadNotifCount > 0) { %><span class="bell-badge"><%= unreadNotifCount %></span><% } %>
    </a>
    <a href="reports.jsp" class="nav-icon-btn" title="Analytics"><i class="bi bi-bar-chart-line"></i></a>
    <a href="profile" class="nav-avatar" title="<%= uname %>"><%= initials %></a>
    <a href="logout" class="nav-icon-btn" title="Logout"><i class="bi bi-box-arrow-right"></i></a>
  </div>
</nav>

<!-- ══ SIDEBAR OVERLAY ══ -->
<div class="sidebar-overlay" id="sidebar-overlay" onclick="toggleSidebar()"></div>

<!-- ══ SIDEBAR ══ -->
<aside class="sidebar" id="sidebar">
  <div class="sidebar-head">
    <div class="sidebar-brand">Smart<span class="dot">Stock</span></div>
    <div class="sidebar-user">
      <div class="sidebar-avatar"><%= initials %></div>
      <div>
        <div class="sidebar-uname"><%= uname != null ? uname : "Staff" %></div>
        <div class="sidebar-role"><%= role != null ? role : "staff" %></div>
      </div>
    </div>
  </div>
  <div class="sidebar-body">
    <div class="sidebar-section">Navigation</div>
    <a href="UserDashboardServlet" class="sidebar-link"><i class="bi bi-grid-fill"></i> Dashboard</a>
    <a href="profile" class="sidebar-link"><i class="bi bi-person-circle"></i> My Profile</a>

    <div class="sidebar-section">Work</div>
    <a href="ProductServlet?action=stock" class="sidebar-link"><i class="bi bi-box-seam"></i> Stock Management</a>
    <a href="OrdersDashboard" class="sidebar-link"><i class="bi bi-bag-check"></i> Manage Orders &amp; DeliveryAgents</a>
    <a href="ProductServlet" class="sidebar-link"><i class="bi bi-boxes"></i> Products</a>

    <div class="sidebar-section">Finance</div>
    <a href="BillsPage" class="sidebar-link active"><i class="bi bi-receipt"></i> Bills &amp; Invoices</a>
    <a href="BillsPage?export=csv" class="sidebar-link"><i class="bi bi-file-earmark-arrow-down"></i> Export CSV</a>

    <div class="sidebar-section">Attendance</div>
    <a href="UserDashboardServlet#attendance-panel" class="sidebar-link"><i class="bi bi-clock-history"></i> My Attendance</a>
    <a href="LeaveServlet?action=apply" class="sidebar-link"><i class="bi bi-calendar-heart"></i> Apply Leave</a>

    <div class="sidebar-section">Support</div>
    <a href="StaffNotifications" class="sidebar-link">
      <i class="bi bi-bell"></i> Notifications
      <% if (unreadNotifCount > 0) { %><span class="sidebar-badge"><%= unreadNotifCount %></span><% } %>
    </a>
    <a href="feedback.jsp" class="sidebar-link"><i class="bi bi-chat-dots"></i> Customer Feedback</a>
    <a href="ticketDashboard.jsp" class="sidebar-link"><i class="bi bi-ticket-perforated"></i> Customer Tickets</a>
    <a href="faq.jsp" class="sidebar-link"><i class="bi bi-question-circle"></i> Help &amp; FAQs</a>

    <div class="sidebar-section">Account</div>
    <a href="logout" class="sidebar-link danger"><i class="bi bi-box-arrow-right"></i> Logout</a>
  </div>
  <div class="sidebar-footer">© 2026 SmartStock Inventory</div>
</aside>

<!-- ══ MAIN CONTENT ══ -->
<div class="main-content" id="main-content">

  <!-- Page Header -->
  <div class="page-header fade-up">
    <div class="ph-eyebrow"><i class="bi bi-receipt"></i> Finance</div>
    <div class="ph-title">Bills &amp; Invoices</div>
    <div class="ph-sub">Full invoice history · payment status · agent withdrawals · rejection audit</div>
    <div class="ph-actions">
      <a href="OrdersDashboard" class="ph-btn"><i class="bi bi-arrow-left"></i> Back to Orders</a>
      <a href="BillsPage?export=csv" class="ph-btn ph-btn-solid"><i class="bi bi-download"></i> Export CSV</a>
    </div>
  </div>

  <!-- ══ STAT CARDS ══ -->
  <div class="stats-row fade-up-1">
    <div class="stat-card" style="--c:#2980b9">
      <div class="stat-icon si-blue"><i class="bi bi-receipt"></i></div>
      <div>
        <div class="stat-num">${totalBills}</div>
        <div class="stat-lbl">Total Bills</div>
      </div>
    </div>
    <div class="stat-card" style="--c:var(--success)">
      <div class="stat-icon si-green"><i class="bi bi-credit-card-fill"></i></div>
      <div>
        <div class="stat-num">${paidCount}</div>
        <div class="stat-lbl">Paid</div>
      </div>
    </div>
    <div class="stat-card" style="--c:var(--danger)">
      <div class="stat-icon si-red"><i class="bi bi-arrow-counterclockwise"></i></div>
      <div>
        <div class="stat-num">${refundedCount}</div>
        <div class="stat-lbl">Refunded</div>
      </div>
    </div>
    <div class="stat-card" style="--c:var(--gold)">
      <div class="stat-icon si-gold"><i class="bi bi-cash-coin"></i></div>
      <div>
        <div class="stat-num">${codCount}</div>
        <div class="stat-lbl">Pending COD</div>
      </div>
    </div>
  </div>

  <!-- ══ TAB NAVIGATION ══ -->
  <div class="tab-nav-card fade-up-2">
    <button class="tab-btn active" onclick="switchTab('bills',this)" id="tab-bills">
      <i class="bi bi-file-earmark-text"></i> Bills &amp; Audit
    </button>
    <button class="tab-btn" onclick="switchTab('agent-cancel',this)" id="tab-agent-cancel">
      <i class="bi bi-x-circle"></i> Agent Cancels
    </button>
    <button class="tab-btn" onclick="switchTab('reject-task',this)" id="tab-reject-task">
      <i class="bi bi-slash-circle"></i> Reject Tasks
    </button>
    <button class="tab-btn" onclick="switchTab('withdrawable',this)" id="tab-withdrawable">
      <i class="bi bi-cash-stack"></i> Withdrawals
    </button>
  </div>

  <!-- ══════════════════════════════════
       TAB 1 — BILLS & AUDIT
  ══════════════════════════════════ -->
  <div class="tab-panel active fade-up-3" id="panel-bills">
    <div class="toolbar">
      <div class="search-box">
        <i class="bi bi-search"></i>
        <input type="text" id="billSearch" placeholder="Search order, customer, txn…"
               oninput="billFilter()">
      </div>
      <select id="billStatusFilter" class="filter-select" onchange="billFilter()">
        <option value="">All Statuses</option>
        <option value="PENDING">Pending</option>
        <option value="PACKED">Packed</option>
        <option value="SHIPPED">Shipped</option>
        <option value="OUT_FOR_DELIVERY">Out for Delivery</option>
        <option value="DELIVERED">Delivered</option>
        <option value="CANCELLED">Cancelled</option>
      </select>
      <select id="billPayFilter" class="filter-select" onchange="billFilter()">
        <option value="">All Payment</option>
        <option value="PAID">Paid</option>
        <option value="PENDING_COD">Pending COD</option>
        <option value="REFUNDED">Refunded</option>
      </select>
      <div class="toolbar-right">
        <a href="BillsPage?export=csv" class="export-btn">
          <i class="bi bi-download"></i> Export CSV
        </a>
        <span class="count-chip" id="billCount">— records</span>
      </div>
    </div>

    <div class="table-card">
      <div class="table-card-header">
        <span class="table-card-title">
          <i class="bi bi-list-columns-reverse"></i> Audit Details
        </span>
        <span class="table-card-meta">
          Generated: <%= new java.text.SimpleDateFormat("dd MMM yyyy, hh:mm a").format(new java.util.Date()) %>
        </span>
      </div>
      <div class="table-scroll">
        <table class="data-table" id="billsTable">
          <thead>
            <tr>
              <th>Order #</th>
              <th>Customer</th>
              <th>Order Status</th>
              <th>Amount</th>
              <th>Payment Method</th>
              <th>Payment Status</th>
              <th>Transaction ID</th>
              <th>Delivery Date</th>
              <th>Audit Notes</th>
            </tr>
          </thead>
          <tbody id="billsTbody">

            <c:forEach var="order" items="${orders}">
              <tr data-search="${order.id} ${order.customerName} ${order.customerEmail} ${order.transactionId}"
                  data-status="${order.status}"
                  data-paystatus="${order.paymentStatus}">

                <td><span class="order-id">#${order.id}</span></td>

                <td>
                  <div class="cust-name">${order.customerName}</div>
                  <div class="cust-email">${order.customerEmail}</div>
                </td>

                <td>
                  <c:choose>
                    <c:when test="${order.status eq 'PENDING'}">
                      <span class="badge b-pending"><i class="bi bi-hourglass-split"></i>Pending</span>
                    </c:when>
                    <c:when test="${order.status eq 'PACKED'}">
                      <span class="badge b-packed"><i class="bi bi-box-seam"></i>Packed</span>
                    </c:when>
                    <c:when test="${order.status eq 'SHIPPED'}">
                      <span class="badge b-shipped"><i class="bi bi-truck"></i>Shipped</span>
                    </c:when>
                    <c:when test="${order.status eq 'OUT_FOR_DELIVERY'}">
                      <span class="badge b-ofd"><i class="bi bi-bicycle"></i>Out for Delivery</span>
                    </c:when>
                    <c:when test="${order.status eq 'DELIVERED'}">
                      <span class="badge b-delivered"><i class="bi bi-check-circle-fill"></i>Delivered</span>
                    </c:when>
                    <c:when test="${order.status eq 'CANCELLED'}">
                      <span class="badge b-cancelled"><i class="bi bi-x-circle-fill"></i>Cancelled</span>
                    </c:when>
                    <c:otherwise>
                      <span class="badge">${order.status}</span>
                    </c:otherwise>
                  </c:choose>
                </td>

                <td class="amount-val">₹${order.totalAmount}</td>

                <td>
                  <c:choose>
                    <c:when test="${order.paymentMethod eq 'COD'}">
                      <span class="pay-pill pp-cod"><i class="bi bi-cash-coin"></i>COD</span>
                    </c:when>
                    <c:when test="${order.paymentMethod eq 'Razorpay'}">
                      <span class="pay-pill pp-card"><i class="bi bi-credit-card-2-back"></i>Razorpay</span>
                    </c:when>
                    <c:otherwise>
                      <span class="pay-pill pp-unknown">${order.paymentMethod}</span>
                    </c:otherwise>
                  </c:choose>
                </td>

                <td>
                  <c:choose>
                    <c:when test="${order.paymentStatus eq 'PAID'}">
                      <span class="badge b-paid"><i class="bi bi-check-circle-fill"></i>Paid</span>
                    </c:when>
                    <c:when test="${order.paymentStatus eq 'REFUNDED'}">
                      <span class="badge b-refunded"><i class="bi bi-arrow-counterclockwise"></i>Refunded</span>
                    </c:when>
                    <c:when test="${order.paymentStatus eq 'PENDING_COD'}">
                      <span class="badge b-cod"><i class="bi bi-clock"></i>Pending COD</span>
                    </c:when>
                    <c:otherwise>
                      <span class="badge">${order.paymentStatus}</span>
                    </c:otherwise>
                  </c:choose>
                </td>

                <td class="txn-id">${order.transactionId}</td>
                <td class="date-val">${order.deliveryDate}</td>

                <td class="audit-note">
                  <c:choose>
                    <c:when test="${order.paymentMethod eq 'COD'}">COD — collect on delivery</c:when>
                    <c:when test="${order.paymentStatus eq 'PAID'}">Paid via Razorpay · Txn: ${order.transactionId}</c:when>
                    <c:when test="${order.paymentStatus eq 'REFUNDED'}">Refund processed · ${order.paymentMethod}</c:when>
                    <c:otherwise>${order.status}</c:otherwise>
                  </c:choose>
                </td>

              </tr>
            </c:forEach>

            <c:if test="${empty orders}">
              <tr>
                <td colspan="9">
                  <div class="empty-state">
                    <i class="bi bi-inbox"></i>
                    <p>No bills found.</p>
                  </div>
                </td>
              </tr>
            </c:if>
          </tbody>
        </table>
      </div>
      <div class="no-results" id="billNoResults">
        <i class="bi bi-search"></i>
        <p>No records match your search / filter.</p>
      </div>
    </div>
  </div><!-- /panel-bills -->

  <!-- ══════════════════════════════════
       TAB 2 — AGENT CANCELLATIONS
  ══════════════════════════════════ -->
  <div class="tab-panel" id="panel-agent-cancel">
    <div class="section-label"><i class="bi bi-x-circle" style="color:var(--danger)"></i> Agent-Cancelled Orders</div>

    <div class="toolbar">
      <div class="search-box">
        <i class="bi bi-search"></i>
        <input type="text" id="cancelSearch" placeholder="Search order or agent…"
               oninput="cancelFilter()">
      </div>
      <div class="toolbar-right">
        <span class="count-chip" id="cancelCount">— records</span>
      </div>
    </div>

    <div class="table-card">
      <div class="table-card-header">
        <span class="table-card-title">
          <i class="bi bi-x-circle-fill" style="color:#fca5a5"></i> Cancelled by Agent
        </span>
        <span class="table-card-meta">Orders where agent triggered cancellation</span>
      </div>
      <div class="table-scroll">
        <table class="data-table" id="cancelTable">
          <thead>
            <tr>
              <th>Order #</th>
              <th>Customer</th>
              <th>Agent</th>
              <th>Amount</th>
              <th>Cancelled At</th>
              <th>Reason</th>
              <th>Payment Status</th>
            </tr>
          </thead>
          <tbody id="cancelTbody">
            <%-- Filtered from orders where status = Cancelled and assigned to an agent --%>
            <c:forEach var="order" items="${orders}">
              <c:if test="${order.status eq 'CANCELLED' and not empty order.deliveryUserId}">
                <tr data-search="${order.id} ${order.customerName} ${order.deliveryPersonName}">
                  <td><span class="order-id">#${order.id}</span></td>
                  <td>
                    <div class="cust-name">${order.customerName}</div>
                    <div class="cust-email">${order.customerEmail}</div>
                  </td>
                  <td>${order.deliveryPersonName}</td>
                  <td class="amount-val">₹${order.totalAmount}</td>
                  <td class="date-val">${order.updatedAt}</td>
                  <td class="audit-note">${order.cancelReason}</td>
                  <td>
                    <c:choose>
                      <c:when test="${order.paymentStatus eq 'REFUNDED'}">
                        <span class="badge b-refunded"><i class="bi bi-arrow-counterclockwise"></i>Refunded</span>
                      </c:when>
                      <c:otherwise>
                        <span class="badge b-pending">${order.paymentStatus}</span>
                      </c:otherwise>
                    </c:choose>
                  </td>
                </tr>
              </c:if>
            </c:forEach>
            <c:if test="${empty orders}">
              <tr><td colspan="7"><div class="empty-state"><i class="bi bi-check-circle"></i><p>No agent cancellations found.</p></div></td></tr>
            </c:if>
          </tbody>
        </table>
      </div>
    </div>
  </div><!-- /panel-agent-cancel -->

  <!-- ══════════════════════════════════
       TAB 3 — REJECT TASKS
  ══════════════════════════════════ -->
  <div class="tab-panel" id="panel-reject-task">
    <div class="section-label"><i class="bi bi-slash-circle" style="color:var(--danger)"></i> Agent Task Rejections</div>

    <%-- Rejection summary loaded from request attribute --%>
    <% @SuppressWarnings("unchecked")
       java.util.List<java.util.Map<String,Object>> rejectionSummary =
           (java.util.List<java.util.Map<String,Object>>) request.getAttribute("rejectionSummary");
       if (rejectionSummary == null) rejectionSummary = new java.util.ArrayList<>();
    %>

    <% if (rejectionSummary.isEmpty()) { %>
    <div class="table-card">
      <div class="empty-state">
        <i class="bi bi-shield-check"></i>
        <p>No task rejections on record. All agents are performing well!</p>
      </div>
    </div>
    <% } else { %>

    <div class="panel-card">
      <div class="panel-title danger">
        <i class="bi bi-slash-circle"></i> Agents with Rejections
        <span style="margin-left:auto;background:var(--danger-bg);color:var(--danger);border:1px solid rgba(220,38,38,.3);font-size:.65rem;font-weight:700;padding:2px 9px;border-radius:20px;">
          <%= rejectionSummary.size() %> agent<%= rejectionSummary.size()!=1?"s":"" %>
        </span>
      </div>

      <% for (java.util.Map<String,Object> rs : rejectionSummary) {
           int rAgentId = ((Number) rs.get("agentId")).intValue();
           int rCount   = ((Number) rs.get("rejectionCount")).intValue();
           String rName  = String.valueOf(rs.get("agentName"));
           String rStatus= String.valueOf(rs.get("agentStatus"));
           boolean isRestricted = "restricted".equalsIgnoreCase(rStatus);
           String rcCss = rCount >= 3 ? "rc-3" : rCount == 2 ? "rc-2" : "rc-1";
      %>
      <div class="agent-row">
        <div class="av av-red"><%= rName.length()>0 ? String.valueOf(rName.charAt(0)).toUpperCase() : "A" %></div>
        <div style="flex:1;min-width:0;">
          <div style="font-size:.85rem;font-weight:700;color:var(--text);display:flex;align-items:center;gap:.5rem;flex-wrap:wrap;">
            <%= rName %>
            <% if (isRestricted) { %>
            <span class="badge b-restricted" style="font-size:.6rem;"><i class="bi bi-lock-fill"></i> Restricted</span>
            <% } %>
          </div>
          <div style="font-size:.72rem;color:var(--text-soft);margin-top:2px;">
            Total rejections: <strong style="color:var(--danger);"><%= rCount %></strong>
          </div>
          <div class="wd-actions">
            <button class="btn-act btn-review"
              onclick="openRejLog(<%= rAgentId %>,'<%= rName.replace("'","&#39;") %>')">
              <i class="bi bi-eye"></i> View Log
            </button>
            <button class="btn-act"
              style="border-color:rgba(16,185,129,.3);color:var(--success);"
              onclick="reviewRejection(<%= rAgentId %>,'<%= rName.replace("'","&#39;") %>','accept')">
              <i class="bi bi-check-circle"></i> Accept Reason
            </button>
            <button class="btn-act"
              style="border-color:rgba(245,158,11,.3);color:var(--warning);"
              onclick="reviewRejection(<%= rAgentId %>,'<%= rName.replace("'","&#39;") %>','dismiss')">
              <i class="bi bi-exclamation-triangle"></i> Dismiss
            </button>
            <% if (isRestricted) { %>
            <button class="btn-act btn-unblock"
              onclick="unblockAgent(<%= rAgentId %>,'<%= rName.replace("'","&#39;") %>')">
              <i class="bi bi-unlock"></i> Unblock
            </button>
            <% } %>
          </div>
        </div>
        <div class="rej-count-badge <%= rcCss %>"><%= rCount %></div>
      </div>
      <% } %>
    </div>
    <% } %>
  </div><!-- /panel-reject-task -->

  <!-- ══════════════════════════════════
       TAB 4 — WITHDRAWALS
  ══════════════════════════════════ -->
  <div class="tab-panel" id="panel-withdrawable">
    <div class="section-label"><i class="bi bi-cash-stack" style="color:var(--gold)"></i> Pending Withdrawal Requests</div>

    <%-- Withdrawal requests from request attribute --%>
    <% @SuppressWarnings("unchecked")
       java.util.List<java.util.Map<String,Object>> pendingWithdrawals =
           (java.util.List<java.util.Map<String,Object>>) request.getAttribute("pendingWithdrawals");
       if (pendingWithdrawals == null) pendingWithdrawals = new java.util.ArrayList<>();
    %>

    <% if (pendingWithdrawals.isEmpty()) { %>
    <div class="table-card">
      <div class="empty-state">
        <i class="bi bi-wallet2"></i>
        <p>No pending withdrawal requests at this time.</p>
      </div>
    </div>
    <% } else { %>

    <div class="panel-card">
      <div class="panel-title amber">
        <i class="bi bi-cash-stack"></i> Withdrawal Requests
        <span style="margin-left:auto;background:var(--gold-bg);color:var(--gold);border:1px solid rgba(245,158,11,.3);font-size:.65rem;font-weight:700;padding:2px 9px;border-radius:20px;">
          <%= pendingWithdrawals.size() %> pending
        </span>
      </div>

      <% for (java.util.Map<String,Object> wd : pendingWithdrawals) {
           int wdId      = (int) wd.get("id");
           String wdAgent = String.valueOf(wd.get("agentName"));
           double wdAmt   = (double) wd.get("amount");
           String wdReason = wd.get("reason") != null ? String.valueOf(wd.get("reason")) : "";
           java.sql.Timestamp wdAt = (java.sql.Timestamp) wd.get("requestedAt");
      %>
      <div class="agent-row">
        <div class="av av-amber"><%= wdAgent.length()>0 ? String.valueOf(wdAgent.charAt(0)).toUpperCase() : "A" %></div>
        <div style="flex:1;min-width:0;">
          <div style="font-size:.85rem;font-weight:700;color:var(--text);"><%= wdAgent %></div>
          <div class="wd-amount">₹<%= String.format("%.2f", wdAmt) %></div>
          <% if (!wdReason.isEmpty()) { %>
          <div style="font-size:.72rem;color:var(--text-soft);margin-top:2px;">
            <i class="bi bi-chat-left-quote"></i>
            <%= wdReason.length() > 80 ? wdReason.substring(0,80)+"…" : wdReason %>
          </div>
          <% } %>
          <div style="font-size:.68rem;color:var(--text-muted);margin-top:3px;">
            <%= wdAt != null ? new java.text.SimpleDateFormat("dd MMM yyyy · hh:mm a").format(wdAt) : "" %>
          </div>
          <div class="wd-actions">
            <button class="btn-act btn-approve"
              onclick="handleWithdrawal('<%= wdId %>','approve','<%= wdAgent.replace("'","&#39;") %>','<%= String.format("%.2f",wdAmt) %>')">
              <i class="bi bi-check-circle"></i> Approve
            </button>
            <button class="btn-act btn-reject"
              onclick="handleWithdrawal('<%= wdId %>','reject','<%= wdAgent.replace("'","&#39;") %>','<%= String.format("%.2f",wdAmt) %>')">
              <i class="bi bi-x-circle"></i> Reject
            </button>
          </div>
        </div>
      </div>
      <% } %>
    </div>
    <% } %>
  </div><!-- /panel-withdrawable -->

</div><!-- /main-content -->

<!-- Bottom Nav (mobile) -->
<nav class="bottom-nav">
  <a href="UserDashboardServlet" class="bnav-item"><i class="bi bi-grid-fill"></i>Home</a>
  <a href="OrdersDashboard" class="bnav-item"><i class="bi bi-bag-check"></i>Orders</a>
  <a href="BillsPage" class="bnav-item active"><i class="bi bi-receipt"></i>Bills</a>
  <a href="StaffNotifications" class="bnav-item">
    <i class="bi bi-bell"></i>
    <% if (unreadNotifCount > 0) { %><span style="position:absolute;top:-2px;right:calc(50% - 18px);background:var(--danger);color:#fff;font-size:.5rem;font-weight:700;min-width:14px;height:14px;border-radius:50%;display:flex;align-items:center;justify-content:center;border:1.5px solid #fff;"><%= unreadNotifCount %></span><% } %>
    Alerts
  </a>
  <a href="profile" class="bnav-item"><i class="bi bi-person-circle"></i>Profile</a>
</nav>

<!-- Toast Container -->
<div class="toast-wrap" id="toastWrap"></div>

<!-- Rejection Log Modal -->
<div class="modal fade" id="rejLogModal" tabindex="-1" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered modal-lg">
    <div class="modal-content" style="border-radius:var(--radius);border:1px solid var(--border);">
      <div class="modal-header" style="background:#fef2f2;border-bottom:1px solid #fecaca;padding:.9rem 1.25rem;display:flex;align-items:center;justify-content:space-between;">
        <div style="font-size:.9rem;font-weight:700;display:flex;align-items:center;gap:.5rem;color:var(--text);">
          <i class="bi bi-slash-circle" style="color:var(--danger)"></i>
          Rejection Log — <span id="rej-modal-agent-name"></span>
        </div>
        <button class="btn-act" style="border-color:var(--border);color:var(--text-mid);" data-bs-dismiss="modal">
          <i class="bi bi-x"></i>
        </button>
      </div>
      <div class="modal-body" style="padding:1.25rem;">
        <div id="rej-modal-log-body" style="max-height:60vh;overflow-y:auto;"></div>
      </div>
      <div class="modal-footer" style="padding:.9rem 1.25rem;border-top:1px solid var(--border);display:flex;gap:.5rem;justify-content:flex-end;flex-wrap:wrap;">
        <div id="rej-modal-agent-id" data-agentid=""></div>
        <button class="btn-act" style="border-color:var(--border);color:var(--text-mid);" data-bs-dismiss="modal">Close</button>
        <button class="btn-act btn-approve"
          onclick="reviewRejection(document.getElementById('rej-modal-agent-id').dataset.agentid,document.getElementById('rej-modal-agent-name').textContent,'accept')">
          <i class="bi bi-check-circle"></i> Accept &amp; Clear
        </button>
        <button class="btn-act" style="border-color:rgba(245,158,11,.4);color:var(--warning);"
          onclick="reviewRejection(document.getElementById('rej-modal-agent-id').dataset.agentid,document.getElementById('rej-modal-agent-name').textContent,'dismiss')">
          <i class="bi bi-exclamation-triangle"></i> Dismiss
        </button>
        <button class="btn-act btn-unblock"
          onclick="bootstrap.Modal.getInstance(document.getElementById('rejLogModal')).hide();unblockAgent(document.getElementById('rej-modal-agent-id').dataset.agentid,document.getElementById('rej-modal-agent-name').textContent)">
          <i class="bi bi-unlock"></i> Unblock Agent
        </button>
      </div>
    </div>
  </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
<script>
/* ══ SIDEBAR TOGGLE ══ */
function toggleSidebar(){
	  var s=document.getElementById('sidebar');
	  var o=document.getElementById('sidebar-overlay');
	  var m=document.getElementById('main-content');
	  if(window.innerWidth>=768){
	    // Desktop: collapse/expand
	    s.classList.toggle('collapsed');
	    m.classList.toggle('sidebar-collapsed');
	  } else {
	    // Mobile: overlay drawer
	    s.classList.toggle('open');
	    o.classList.toggle('open');
	  }
	}
	// Restore sidebar state
	window.addEventListener('DOMContentLoaded',function(){
	  var state=localStorage.getItem('sidebar-state');
	  if(state==='collapsed' && window.innerWidth>=768){
	    document.getElementById('sidebar').classList.add('collapsed');
	    document.getElementById('main-content').classList.add('sidebar-collapsed');
	  }
	});
	document.getElementById('toggle-btn').addEventListener('click',function(){
	  var isCollapsed=document.getElementById('sidebar').classList.contains('collapsed');
	  localStorage.setItem('sidebar-state',isCollapsed?'open':'collapsed');
	});
/* ══ TAB SWITCHING ══ */
function switchTab(name, btn) {
  document.querySelectorAll('.tab-panel').forEach(p => p.classList.remove('active'));
  document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
  document.getElementById('panel-' + name).classList.add('active');
  btn.classList.add('active');
}

/* ══ BILLS FILTER ══ */
function billFilter() {
  var q    = (document.getElementById('billSearch').value||'').toLowerCase().trim();
  var stat = (document.getElementById('billStatusFilter').value||'').toUpperCase();
  var pay  = (document.getElementById('billPayFilter').value||'').toUpperCase();
  var rows = document.querySelectorAll('#billsTbody tr[data-search]');
  var vis  = 0;
  rows.forEach(function(row){
    var mq  = !q   || row.dataset.search.toLowerCase().includes(q);
    var mst = !stat|| row.dataset.status.toUpperCase()===stat;
    var mpy = !pay || row.dataset.paystatus.toUpperCase()===pay;
    var ok  = mq && mst && mpy;
    row.style.display = ok?'':'none';
    if(ok) vis++;
  });
  var ce = document.getElementById('billCount');
  if(ce) ce.textContent = vis+' record'+(vis!==1?'s':'');
  var nr = document.getElementById('billNoResults');
  if(nr) nr.style.display = (vis===0 && rows.length>0)?'block':'none';
}

/* ══ CANCEL FILTER ══ */
function cancelFilter(){
  var q   = (document.getElementById('cancelSearch').value||'').toLowerCase().trim();
  var rows= document.querySelectorAll('#cancelTbody tr[data-search]');
  var vis =0;
  rows.forEach(r=>{
    var ok=!q||r.dataset.search.toLowerCase().includes(q);
    r.style.display=ok?'':'none';if(ok)vis++;
  });
  var c=document.getElementById('cancelCount');
  if(c) c.textContent=vis+' record'+(vis!==1?'s':'');
}

/* ══ TOAST ══ */
function showToast(msg,type){
  var wrap=document.getElementById('toastWrap');
  var colors={success:'var(--success)',danger:'var(--danger)',warning:'var(--warning)'};
  var icons={success:'bi-check-circle-fill',danger:'bi-x-circle-fill',warning:'bi-exclamation-triangle-fill'};
  var el=document.createElement('div');
  el.className='toast-msg';
  el.style.borderLeftColor=colors[type]||colors.success;
  el.innerHTML='<i class="bi '+icons[type]+'" style="color:'+colors[type]+';flex-shrink:0"></i> '+msg;
  wrap.appendChild(el);
  setTimeout(()=>el.classList.add('show'),10);
  setTimeout(()=>{el.classList.remove('show');setTimeout(()=>el.remove(),300);},3500);
}

/* ══ WITHDRAWAL ══ */
function handleWithdrawal(wdId, action, agentName, amount){
  var label = action==='approve'?'Approve':'Reject';
  if(!confirm(label+' ₹'+amount+' withdrawal request for '+agentName+'?')) return;
  var params=new URLSearchParams({action:'handleWithdrawal',withdrawalId:wdId,decision:action});
  fetch('OrdersDashboard',{
    method:'POST',
    headers:{'Content-Type':'application/x-www-form-urlencoded','X-Requested-With':'XMLHttpRequest'},
    body:params.toString()
  }).then(r=>r.json()).then(data=>{
    if(data.success){
      showToast(agentName+(action==='approve'?' withdrawal approved.':' withdrawal rejected.'), action==='approve'?'success':'warning');
      setTimeout(()=>location.reload(),1600);
    } else {
      showToast('Error: '+(data.message||'Action failed.'),'danger');
    }
  }).catch(()=>showToast('Network error.','danger'));
}

/* ══ REJECTION LOG ══ */
function openRejLog(agentId, agentName){
  document.getElementById('rej-modal-agent-name').textContent = agentName;
  document.getElementById('rej-modal-agent-id').dataset.agentid = agentId;
  var body = document.getElementById('rej-modal-log-body');
  body.innerHTML = '<div style="text-align:center;padding:2rem;color:var(--text-muted);"><i class="bi bi-hourglass-split" style="font-size:2rem;display:block;margin-bottom:.5rem;opacity:.4"></i>Loading...</div>';
  new bootstrap.Modal(document.getElementById('rejLogModal')).show();
  fetch('OrdersDashboard?action=getAgentRejectionLog&agentId='+agentId)
    .then(r=>r.json())
    .then(data=>{
      if(!data||data.length===0){
        body.innerHTML='<div style="text-align:center;padding:2rem;color:var(--text-muted);font-size:.85rem;"><i class="bi bi-check-circle" style="font-size:2rem;display:block;margin-bottom:.5rem;opacity:.4"></i>No rejection log entries found.</div>';
      } else {
        body.innerHTML=data.map((row,i)=>
          '<div style="display:flex;align-items:flex-start;gap:.75rem;padding:.75rem .85rem;border:1px solid var(--border);border-radius:10px;margin-bottom:.5rem;background:var(--bg-off);">'
          +'<div style="width:26px;height:26px;border-radius:50%;background:var(--danger-bg);color:var(--danger);border:1px solid rgba(220,38,38,.3);display:flex;align-items:center;justify-content:center;font-size:.72rem;font-weight:800;flex-shrink:0;">'+(i+1)+'</div>'
          +'<div style="flex:1;min-width:0;">'
          +'<div style="display:flex;align-items:center;gap:.5rem;flex-wrap:wrap;">'
          +'<span style="font-family:monospace;font-size:.8rem;font-weight:700;color:var(--accent);">#'+(row.orderId||'—')+'</span>'
          +'<span style="font-size:.72rem;color:var(--text-muted);">'+(row.time||'')+'</span>'
          +'<button onclick="deleteSingleRejection('+row.logId+',this)" style="margin-left:auto;font-size:.65rem;padding:2px 8px;border-radius:6px;border:1px solid rgba(244,63,94,.3);color:var(--danger);background:transparent;cursor:pointer;"><i class="bi bi-trash"></i> Remove</button>'
          +'</div>'
          +'<div style="font-size:.82rem;color:var(--text);margin-top:2px;">'+(row.reason||'—')+'</div>'
          +'</div></div>'
        ).join('');
      }
    })
    .catch(()=>{ body.innerHTML='<div style="text-align:center;padding:2rem;color:var(--danger);font-size:.85rem;"><i class="bi bi-exclamation-triangle" style="font-size:2rem;display:block;margin-bottom:.5rem;"></i>Failed to load rejection log.</div>'; });
}

function deleteSingleRejection(logId,btn){
  if(!confirm('Remove this single rejection entry?')) return;
  btn.disabled=true;
  fetch('OrdersDashboard',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded','X-Requested-With':'XMLHttpRequest'},body:'action=deleteSingleRejection&logId='+logId})
  .then(r=>r.json()).then(data=>{
    if(data.success){btn.closest('div[style]').remove();showToast('Rejection entry removed.','success');}
    else{showToast(data.message||'Failed.','danger');btn.disabled=false;}
  }).catch(()=>{showToast('Network error.','danger');btn.disabled=false;});
}

/* ══ REVIEW REJECTION ══ */
function reviewRejection(agentId,agentName,decision){
  var label=decision==='accept'?'Accept':'Dismiss';
  var note=prompt(label+' rejection reason for '+agentName+'?\nEnter a staff note (optional):');
  if(note===null) return;
  var params=new URLSearchParams({action:'reviewAgentRejection',agentUserId:agentId,decision,staffNote:note||''});
  fetch('OrdersDashboard',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded','X-Requested-With':'XMLHttpRequest'},body:params.toString()})
  .then(r=>r.json()).then(data=>{
    if(data.success){showToast(data.message||'Reviewed.',decision==='accept'?'success':'warning');setTimeout(()=>location.reload(),1600);}
    else{showToast('Error: '+(data.message||'Action failed.'),'danger');}
  }).catch(()=>showToast('Network error.','danger'));
}

/* ══ UNBLOCK AGENT ══ */
function unblockAgent(agentUserId,agentName){
  if(!confirm('Unblock '+agentName+'? This will set their account to Active.')) return;
  var params=new URLSearchParams({action:'unblockAgent',agentUserId});
  fetch('OrdersDashboard',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded','X-Requested-With':'XMLHttpRequest'},body:params.toString()})
  .then(r=>r.json()).then(data=>{
    if(data.success){showToast(agentName+' has been unblocked.','success');setTimeout(()=>location.reload(),1600);}
    else{showToast('Error: '+(data.message||'Could not unblock.'),'danger');}
  }).catch(()=>showToast('Network error.','danger'));
}

/* ══ INIT ══ */
window.addEventListener('DOMContentLoaded',function(){
  billFilter();
  cancelFilter();
});
</script>
</body>
</html>
