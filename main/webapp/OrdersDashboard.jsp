<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true"%>
<%@ page import="com.util.*, java.util.*, java.time.LocalDate" %>
<%
    String role  = (session != null) ? (String) session.getAttribute("role")     : null;
    String uname = (session != null) ? (String) session.getAttribute("username") : null;

    if (role == null || (!("staff".equalsIgnoreCase(role)) && !("admin".equalsIgnoreCase(role)))) {
        response.sendRedirect("index.jsp?error=Access denied.");
        return;
    }

    List<Order>  orders          = (List<Order>)  request.getAttribute("orders");
    List<User>   deliveryPersons = (List<User>)   request.getAttribute("deliveryPersons");
    if (orders          == null) orders          = new ArrayList<>();
    if (deliveryPersons == null) deliveryPersons = new ArrayList<>();

    @SuppressWarnings("unchecked")
    Object agentEarningsToday = request.getAttribute("agentEarningsToday");
    @SuppressWarnings("unchecked")
    Object agentTotalEarned   =  request.getAttribute("agentTotalEarned");
    if (agentEarningsToday == null) agentEarningsToday = new java.util.HashMap<>();
    if (agentTotalEarned   == null) agentTotalEarned   = new java.util.HashMap<>();

    @SuppressWarnings("unchecked")
    java.util.List<java.util.Map<String,Object>> pendingWithdrawals =
        (java.util.List<java.util.Map<String,Object>>) request.getAttribute("pendingWithdrawals");
    if (pendingWithdrawals == null) pendingWithdrawals = new java.util.ArrayList<>();

    @SuppressWarnings("unchecked")
    java.util.List<java.util.Map<String,Object>> rejectionSummary =
        (java.util.List<java.util.Map<String,Object>>) request.getAttribute("rejectionSummary");
    if (rejectionSummary == null) rejectionSummary = new java.util.ArrayList<>();

    boolean hasAgentActivity = !pendingWithdrawals.isEmpty() || !rejectionSummary.isEmpty();

    @SuppressWarnings("unchecked")
    java.util.Map<Integer, java.util.List<java.util.Map<String,Object>>> rejectionDetailMap =
        (java.util.Map<Integer, java.util.List<java.util.Map<String,Object>>>) request.getAttribute("rejectionDetailMap");
    if (rejectionDetailMap == null) rejectionDetailMap = new java.util.HashMap<>();

    int totalRejectionAgents = rejectionSummary.size();
    int restrictedAgents = (int) rejectionSummary.stream()
        .filter(r -> "restricted".equalsIgnoreCase(String.valueOf(r.get("agentStatus"))))
        .count();

    int unreadNotifCount = session.getAttribute("unreadNotifCount") != null
        ? (Integer) session.getAttribute("unreadNotifCount") : 0;

    int totalOrders = orders.size(), pendingCount = 0, confirmedCount = 0,
        assignedCount = 0, packedCount = 0, shippedCount = 0,
        deliveredCount = 0, cancelledCount = 0, paidCount = 0, returnCount = 0,
        processingCount = 0, pickedUpCount = 0, outForDeliveryCount = 0;
    double totalRevenue = 0.0;

    for (Order o : orders) {
        String st  = o.getStatus()        != null ? o.getStatus()        : "";
        String pst = o.getPaymentStatus() != null ? o.getPaymentStatus() : "";
        switch (st) {
            case "Pending":  case "Ordered":        pendingCount++;        break;
            case "Confirmed":                        confirmedCount++;      break;
            case "Assigned":                         assignedCount++;       break;
            case "Picked Up":                        pickedUpCount++;       break;
            case "Packed":                           packedCount++;         break;
            case "Shipped":                          shippedCount++;        break;
            case "Out for Delivery":                 outForDeliveryCount++; break;
            case "Delivered": case "Completed":
                deliveredCount++; totalRevenue += o.getTotalAmount();      break;
            case "Cancelled":                        cancelledCount++;      break;
            case "Processing":                       processingCount++;     break;
        }
        if ("PAID".equalsIgnoreCase(pst)) paidCount++;
        if (st.startsWith("Return") || "Refunded".equals(st) || "Replaced".equals(st)) returnCount++;
    }

    String initials = (uname != null && uname.length() >= 2) ? uname.substring(0,2).toUpperCase() : (uname != null ? uname.toUpperCase() : "ST");
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
<title>Orders Dashboard — SmartStock</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
<link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
<style>
:root {
  --primary: #27d2c2;
  --primary-mid: #63b3f9fc;
  --primary-light: #e0e7ff;
  --accent: #6366f1;
  --accent-h: #4f46e5;
  --accent-light: #eef2ff;
  --coral: #f97316;
  --coral-bg: #fff7ed;
  --success: #059669; --success-bg: #d1fae5;
  --warning: #d97706; --warning-bg: #fef3c7;
  --danger: #dc2626;  --danger-bg: #fee2e2;
  --purple: #7c3aed;  --purple-bg: #ede9fe;
  --teal: #0891b2;    --teal-bg: #cffafe;
  --sky: #0ea5e9;     --sky-bg: #e0f2fe;
  --gold: #d97706;    --gold-bg: #fef3c7;
  --text: #1e1b4b; --text-mid: #4b5563; --text-soft: #6b7280; --text-muted: #9ca3af;
  --border: #e0e7ff; --bg: #f8fafc; --bg-off: #f3f4f6; --card: #ffffff;
  --nav-h: 62px; --sidebar-w: 264px;
  --radius: 14px; --radius-sm: 9px;
  --shadow: 0 1px 4px rgba(67,56,202,.07),0 4px 18px rgba(67,56,202,.08);
  --shadow-md: 0 6px 28px rgba(67,56,202,.14);
  --shadow-glow: 0 0 0 3px rgba(99,102,241,.18);
}
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
html{font-size:16px}
body{font-family:'Outfit',sans-serif;background:var(--bg-off);color:var(--text);padding-top:var(--nav-h);min-height:100vh;-webkit-font-smoothing:antialiased;padding-bottom:64px;
  background-image:radial-gradient(ellipse at 80% 0%,rgba(99,102,241,.06) 0%,transparent 60%),radial-gradient(ellipse at 0% 60%,rgba(249,115,22,.04) 0%,transparent 55%);
}
@media(min-width:768px){body{padding-bottom:0}}
::-webkit-scrollbar{width:5px;height:5px}
::-webkit-scrollbar-track{background:transparent}
::-webkit-scrollbar-thumb{background:#cbd5e1;border-radius:10px}
:focus-visible{outline:2px solid var(--accent);outline-offset:2px}

/* ── NAVBAR ── */
.top-navbar{position:fixed;top:0;left:0;right:0;height:var(--nav-h);z-index:1050;
  background:linear-gradient(135deg,var(--primary) 0%,var(--primary-mid) 100%);
  display:flex;align-items:center;padding:0 1.1rem;gap:.75rem;
  box-shadow:0 2px 20px rgba(67,56,202,.25);}
.hamburger{width:40px;height:40px;border-radius:var(--radius-sm);background:rgba(255,255,255,.1);border:1px solid rgba(255,255,255,.18);color:#fff;display:flex;align-items:center;justify-content:center;cursor:pointer;font-size:1.1rem;flex-shrink:0;transition:all .2s;outline:none}
.hamburger:hover{background:rgba(255,255,255,.2);border-color:rgba(255,255,255,.4);transform:scale(1.05)}
.nav-brand{font-size:1.4rem;font-weight:800;color:#fff;text-decoration:none;display:flex;align-items:center;gap:.4rem;white-space:nowrap;letter-spacing:-.3px}
.nav-brand .dot{color:#fbbf24}
.nav-badge{font-size:.9rem;font-weight:700;background:rgb(129,231,43);color:#fefffe;padding:2px 7px;border-radius:20px;letter-spacing:.9px;text-transform:uppercase;border:1px solid rgba(251,191,36,.07)}
.nav-right{margin-left:auto;display:flex;align-items:center;gap:.5rem}
.nav-icon-btn{width:36px;height:36px;border-radius:var(--radius-sm);background:rgba(255,255,255,.1);border:1px solid rgba(255,255,255,.15);color:#fff;display:flex;align-items:center;justify-content:center;cursor:pointer;font-size:.95rem;text-decoration:none;transition:all .2s;position:relative}
.nav-icon-btn:hover{background:rgba(255,255,255);border-color:rgba(255,255,255,.35);color:#fbbf24}
.bell-badge{position:absolute;top:-4px;right:-4px;background:var(--danger);color:#fff;font-size:.55rem;font-weight:700;min-width:16px;height:16px;border-radius:50%;display:flex;align-items:center;justify-content:center;border:2px solid var(--primary)}
.nav-avatar{width:34px;height:34px;border-radius:50%;background:linear-gradient(135deg,#fbbf24,#f97316);display:flex;align-items:center;justify-content:center;font-size:.72rem;font-weight:800;color:#fff;cursor:pointer;border:2px solid rgba(255,255,255,.35);flex-shrink:0;text-decoration:none;box-shadow:0 2px 8px rgba(0,0,0,.15)}

/* ── SIDEBAR ── */
.sidebar-overlay{position:fixed;inset:0;background:rgba(55,48,163,.25);z-index:990;opacity:0;pointer-events:none;transition:opacity .3s;backdrop-filter:blur(4px)}
.sidebar-overlay.open{opacity:1;pointer-events:all}
.sidebar{position:fixed;top:0;left:0;bottom:0;width:var(--sidebar-w);background:#fff;z-index:995;transform:translateX(-100%);transition:transform .3s cubic-bezier(.4,0,.2,1);display:flex;flex-direction:column;overflow:hidden;
  box-shadow:6px 0 30px rgba(67,56,202,.15);border-right:1px solid var(--border);}
.sidebar.open{transform:translateX(0)}
@media(min-width:768px){
  .sidebar{transform:translateX(0)}
  .sidebar.collapsed{transform:translateX(-100%)}
  .sidebar-overlay{display:none}
  .main-content{margin-left:var(--sidebar-w);transition:margin-left .3s}
  .main-content.expanded{margin-left:0}
}
.sidebar-head{background:linear-gradient(150deg,var(--primary) 0%,var(--primary-mid) 100%);padding:4.2rem 1.2rem 1.1rem;border-bottom:2px solid rgba(251,191,36,.4)}
.sidebar-brand{font-size:1.05rem;font-weight:800;color:#fff;margin-bottom:1rem;letter-spacing:-.3px}
.sidebar-brand .dot{color:#fbbf24}
.sidebar-user{display:flex;align-items:center;gap:.75rem}
.sidebar-avatar{width:44px;height:44px;border-radius:50%;background:linear-gradient(135deg,#fbbf24,#f97316);display:flex;align-items:center;justify-content:center;font-size:1rem;font-weight:800;color:#fff;flex-shrink:0;border:2px solid rgba(255,255,255,.3);box-shadow:0 2px 10px rgba(0,0,0,.2)}
.sidebar-uname{font-size:.9rem;font-weight:700;color:#fff}
.sidebar-role{font-size:.65rem;font-weight:600;letter-spacing:.8px;text-transform:uppercase;color:#fbbf24;margin-top:1px}
.sidebar-body{flex:1;overflow-y:auto;padding:.75rem .75rem 1rem;background:#fff}
.sidebar-section{font-size:.62rem;font-weight:700;letter-spacing:1.5px;text-transform:uppercase;color:var(--text-muted);padding:.8rem .6rem .3rem}
.sidebar-link{display:flex;align-items:center;gap:.7rem;padding:.6rem .75rem;border-radius:var(--radius-sm);color:var(--text-mid);text-decoration:none;font-size:.88rem;font-weight:500;transition:all .18s;margin-bottom:2px;border-left:3px solid transparent}
.sidebar-link i{font-size:.95rem;width:18px;text-align:center;color:var(--text-muted);transition:color .18s}
.sidebar-link:hover{background:var(--accent-light);color:var(--accent);border-left-color:var(--accent)}
.sidebar-link:hover i{color:var(--accent)}
.sidebar-link.active{background:var(--accent-light);color:var(--accent);border-left-color:var(--accent);font-weight:700}
.sidebar-link.active i{color:var(--accent)}
.sidebar-link.danger{color:#dc2626}.sidebar-link.danger i{color:#dc2626}
.sidebar-link.danger:hover{background:var(--danger-bg);border-left-color:#dc2626}
.sidebar-badge{margin-left:auto;background:var(--danger-bg);color:var(--danger);font-size:.65rem;font-weight:700;padding:1px 7px;border-radius:20px;border:1px solid rgba(220,38,38,.2)}
.sidebar-footer{padding:.75rem;border-top:1px solid var(--border);font-size:.72rem;color:var(--text-muted);text-align:center;background:#fafafa}

/* ── MAIN ── */
.main-content{padding:1rem;max-width:100%}
@media(min-width:768px){.main-content{padding:1.5rem 2rem}}

/* ── WELCOME BANNER ── */
.welcome-banner{background:linear-gradient(135deg,var(--primary) 0%,#4f46e5 55%,#7c3aed 100%);border-radius:var(--radius);padding:1.25rem;margin-bottom:1rem;position:relative;overflow:hidden;box-shadow:0 8px 32px rgba(67,56,202,.25)}
.welcome-banner::before{content:'';position:absolute;top:-20px;right:-20px;width:120px;height:120px;border-radius:50%;background:rgba(251,191,36,.12)}
.welcome-banner::after{content:'';position:absolute;bottom:-30px;right:40px;width:80px;height:80px;border-radius:50%;background:rgba(255,255,255,.06)}
.online-badge{display:inline-flex;align-items:center;gap:4px;background:rgba(16,185,129,.2);border:1px solid rgba(16,185,129,.4);color:#6ee7b7;font-size:.65rem;font-weight:700;padding:3px 8px;border-radius:20px;margin-bottom:.6rem}
.pulse-dot{width:6px;height:6px;border-radius:50%;background:#6ee7b7;animation:pulse 1.5s infinite}
@keyframes pulse{0%,100%{opacity:1}50%{opacity:.4}}
.wb-greeting{font-size:.72rem;font-weight:600;color:rgba(255,255,255,.6);text-transform:uppercase;letter-spacing:.8px;margin-bottom:3px}
.wb-name{font-size:1.3rem;font-weight:800;color:#fff;margin-bottom:4px}
.wb-meta{font-size:.74rem;color:rgba(255,255,255,.55);display:flex;flex-wrap:wrap;gap:.3rem .75rem}
.wb-meta span{color:rgba(255,255,255,.85);font-weight:600}

/* ── STATS ── */
.stats-row{display:grid;grid-template-columns:repeat(2,1fr);gap:.65rem;margin-bottom:1rem}
@media(min-width:480px){.stats-row{grid-template-columns:repeat(4,1fr)}}
@media(min-width:768px){.stats-row{grid-template-columns:repeat(4,1fr)}}
@media(min-width:1024px){.stats-row{grid-template-columns:repeat(8,1fr)}}
.stat-card{background:var(--card);border:1px solid var(--border);border-radius:var(--radius);padding:.875rem;display:flex;flex-direction:column;gap:.25rem;box-shadow:var(--shadow);transition:all .2s;cursor:default}
.stat-card:hover{transform:translateY(-3px);box-shadow:var(--shadow-md)}
.stat-icon{width:36px;height:36px;border-radius:9px;display:flex;align-items:center;justify-content:center;font-size:.95rem;margin-bottom:.35rem}
.si-blue{background:var(--sky-bg);color:var(--sky)}
.si-amber{background:var(--gold-bg);color:var(--gold)}
.si-indigo{background:var(--accent-light);color:var(--accent)}
.si-teal{background:var(--teal-bg);color:var(--teal)}
.si-green{background:var(--success-bg);color:var(--success)}
.si-red{background:var(--danger-bg);color:var(--danger)}
.si-purple{background:var(--purple-bg);color:var(--purple)}
.si-return{background:var(--warning-bg);color:var(--warning)}
.stat-num{font-size:1.3rem;font-weight:800;color:var(--text);line-height:1}
.stat-lbl{font-size:.65rem;font-weight:600;text-transform:uppercase;letter-spacing:1px;color:var(--text-soft)}

/* ── SECTION LABEL ── */
.section-label{font-size:.72rem;font-weight:700;letter-spacing:1.2px;text-transform:uppercase;color:var(--accent);margin-bottom:.75rem;display:flex;align-items:center;gap:.5rem}
.section-label::after{content:'';flex:1;height:1px;background:linear-gradient(90deg,var(--border),transparent)}

/* ── TABS ── */
.tabs-nav{display:flex;gap:0;background:var(--card);border:1px solid var(--border);border-radius:var(--radius);overflow:hidden;margin-bottom:1rem;box-shadow:var(--shadow)}
.tab-btn{flex:1;padding:.65rem .75rem;font-family:inherit;font-size:.78rem;font-weight:600;border:none;background:none;cursor:pointer;color:var(--text-muted);transition:all .2s;display:flex;align-items:center;justify-content:center;gap:.35rem;border-bottom:3px solid transparent;white-space:nowrap;position:relative}
.tab-btn:hover{background:var(--accent-light);color:var(--accent)}
.tab-btn.active{background:var(--accent-light);color:var(--accent);border-bottom-color:var(--accent);font-weight:700}
.tab-btn .tab-count{background:var(--danger-bg);color:var(--danger);font-size:.6rem;font-weight:800;padding:1px 6px;border-radius:20px;margin-left:.25rem}
.tab-btn.active .tab-count{background:rgba(99,102,241,.18);color:var(--accent)}
.tab-pane{display:none}
.tab-pane.active{display:block}
@media(max-width:600px){
  .tabs-nav{overflow-x:auto;flex-wrap:nowrap;gap:0}
  .tab-btn{flex:0 0 auto;min-width:120px}
}

/* ── TOOLBAR ── */
.toolbar{background:var(--card);border:1px solid var(--border);border-radius:var(--radius);padding:.75rem 1rem;display:flex;align-items:center;gap:.6rem;flex-wrap:wrap;margin-bottom:1rem;box-shadow:var(--shadow)}
.search-box{display:flex;align-items:center;gap:.4rem;background:var(--bg);border:1px solid var(--border);border-radius:var(--radius-sm);padding:.45rem .85rem;transition:all .2s;flex:1;max-width:300px}
.search-box:focus-within{border-color:var(--accent);box-shadow:0 0 0 3px var(--accent-light)}
.search-box i{color:var(--text-soft);font-size:.85rem}
.search-box input{background:none;border:none;outline:none;font-family:inherit;font-size:.83rem;color:var(--text);width:100%}
.search-box input::placeholder{color:var(--text-soft)}
.filter-select{background:var(--card);border:1px solid var(--border);border-radius:var(--radius-sm);padding:.45rem .75rem;font-family:inherit;font-size:.83rem;color:var(--text);outline:none;cursor:pointer;transition:all .18s}
.filter-select:focus{border-color:var(--accent);box-shadow:0 0 0 3px var(--accent-light)}

/* ── TABLE CARD ── */
.table-card{background:var(--card);border:1px solid var(--border);border-radius:var(--radius);box-shadow:var(--shadow);overflow:hidden}
.table-card-header{background:linear-gradient(135deg,var(--primary) 0%,var(--primary-mid) 100%);padding:.8rem 1.25rem;display:flex;align-items:center;justify-content:space-between;border-bottom:1px solid rgba(255,255,255,.08)}
.table-card-title{font-size:.88rem;font-weight:600;color:#fff;display:flex;align-items:center;gap:.5rem}
.table-card-title i{color:#fbbf24}
.table-count{font-size:.73rem;color:rgba(255,255,255,.6);font-family:monospace}
.table-responsive{overflow-x:auto;-webkit-overflow-scrolling:touch}
table{width:100%;border-collapse:collapse;min-width:1100px}
thead tr{background:rgba(99,102,241,.04);border-bottom:2px solid var(--border)}
thead th{padding:.65rem .85rem;font-size:.63rem;font-weight:700;letter-spacing:1.2px;text-transform:uppercase;color:var(--text-soft);white-space:nowrap}
tbody tr{border-bottom:1px solid rgba(224,231,255,.6);transition:background .14s}
tbody tr:last-child{border-bottom:none}
tbody tr:hover td{background:rgba(99,102,241,.03)}
tbody tr.row-needs-action td{background:rgba(245,158,11,.04)}
tbody tr.row-return td{background:rgba(251,146,60,.03)}
td{padding:.7rem .85rem;vertical-align:middle;color:var(--text);font-size:.83rem}

/* ── BADGES ── */
.pay-pill,.status-badge{font-size:.63rem;letter-spacing:.8px;text-transform:uppercase;padding:3px 9px;border-radius:20px;font-weight:700;display:inline-flex;align-items:center;gap:.3rem;white-space:nowrap;border:1px solid}
.pay-cod{background:var(--gold-bg);color:var(--gold);border-color:rgba(245,158,11,.3)}
.pay-paid{background:var(--success-bg);color:var(--success);border-color:rgba(16,185,129,.3)}
.pay-refunded{background:var(--purple-bg);color:var(--purple);border-color:rgba(167,139,250,.3)}
.pay-unknown{background:var(--bg);color:var(--text-soft);border-color:var(--border)}
.s-ordered{background:var(--sky-bg);color:var(--sky);border-color:rgba(56,189,248,.25)}
.s-pending{background:var(--gold-bg);color:var(--gold);border-color:rgba(245,158,11,.25)}
.s-confirmed{background:var(--accent-light);color:var(--accent);border-color:rgba(99,102,241,.25)}
.s-assigned{background:var(--teal-bg);color:var(--teal);border-color:rgba(45,212,191,.25)}
.s-pickedup{background:var(--purple-bg);color:var(--purple);border-color:rgba(167,139,250,.25)}
.s-packed{background:var(--sky-bg);color:var(--sky);border-color:rgba(56,189,248,.25)}
.s-shipped{background:var(--accent-light);color:var(--accent);border-color:rgba(99,102,241,.25)}
.s-ofd{background:var(--warning-bg);color:var(--warning);border-color:rgba(251,146,60,.25)}
.s-delivered{background:var(--success-bg);color:var(--success);border-color:rgba(16,185,129,.25)}
.s-cancelled{background:var(--danger-bg);color:var(--danger);border-color:rgba(244,63,94,.25)}
.s-return{background:var(--warning-bg);color:var(--warning);border-color:rgba(251,146,60,.25)}
.s-processing{background:var(--accent-light);color:var(--accent);border-color:rgba(99,102,241,.25)}
.s-refunded{background:var(--purple-bg);color:var(--purple);border-color:rgba(167,139,250,.25)}
.s-replaced{background:var(--teal-bg);color:var(--teal);border-color:rgba(45,212,191,.25)}
.restricted-pill{display:inline-flex;align-items:center;gap:4px;font-size:.62rem;font-weight:700;padding:2px 8px;border-radius:20px;background:var(--danger-bg);color:var(--danger);border:1px solid rgba(244,63,94,.3);margin-left:.35rem}
.active-pill{display:inline-flex;align-items:center;gap:4px;font-size:.62rem;font-weight:700;padding:2px 8px;border-radius:20px;background:var(--success-bg);color:var(--success);border:1px solid rgba(16,185,129,.3)}

/* ── PROGRESS ── */
.progress-wrap{margin-top:5px;height:3px;background:var(--border);border-radius:4px;overflow:hidden;width:80px}
.progress-fill{height:100%;border-radius:4px;transition:width .6s ease}

/* ── ACTION BUTTONS ── */
.action-col{display:flex;flex-direction:column;gap:.35rem;min-width:195px}
.btn-tbl{font-family:inherit;font-size:.72rem;font-weight:600;padding:.32rem .75rem;border-radius:7px;cursor:pointer;transition:all .18s;border:1px solid transparent;text-decoration:none;display:inline-flex;align-items:center;gap:.3rem;background:transparent;white-space:nowrap}
.btn-invoice{border-color:var(--border);color:var(--text-mid)}.btn-invoice:hover{background:var(--bg-off);color:var(--text);border-color:#94a3b8}
.btn-refund{border-color:rgba(167,139,250,.3);color:var(--purple)}.btn-refund:hover{background:var(--purple-bg);border-color:var(--purple)}
.btn-assign{border-color:rgba(56,189,248,.3);color:var(--sky)}.btn-assign:hover{background:var(--sky-bg);border-color:var(--sky)}
.btn-update{border-color:rgba(99,102,241,.3);color:var(--accent)}.btn-update:hover{background:var(--accent-light);border-color:var(--accent)}
.btn-cancel{border-color:rgba(244,63,94,.3);color:var(--danger)}.btn-cancel:hover{background:var(--danger-bg);border-color:var(--danger)}
.btn-return{border-color:rgba(251,146,60,.3);color:var(--warning)}.btn-return:hover{background:var(--warning-bg);border-color:var(--warning)}
.btn-success{border-color:rgba(16,185,129,.3);color:var(--success)}.btn-success:hover{background:var(--success-bg);border-color:var(--success)}
.input-row{display:flex;align-items:center;gap:.3rem}
.input-date-sm{background:var(--card);border:1px solid var(--border);border-radius:7px;padding:.28rem .5rem;font-size:.72rem;font-family:inherit;color:var(--text);outline:none;flex:1;min-width:0;transition:all .18s}
.input-date-sm:focus{border-color:var(--accent)}
.btn-cod-deposit{border-color:rgba(245,158,11,.3);color:var(--gold)}.btn-cod-deposit:hover{background:var(--gold-bg);border-color:var(--gold)}
.deposited-badge{display:inline-flex;align-items:center;gap:4px;font-size:.68rem;font-weight:600;padding:2px 8px;border-radius:20px;background:var(--success-bg);color:var(--success);border:1px solid rgba(16,185,129,.25);white-space:nowrap;margin-top:2px}

/* ── AGENT PANEL CARDS ── */
.panel-card{background:var(--card);border:1px solid var(--border);border-radius:var(--radius);padding:1.1rem;margin-bottom:1rem;box-shadow:var(--shadow)}
.panel-card-header{background:linear-gradient(135deg,var(--primary) 0%,var(--primary-mid) 100%);padding:.75rem 1rem;border-radius:var(--radius-sm);margin-bottom:1rem;display:flex;align-items:center;justify-content:space-between}
.panel-card-title{font-size:.85rem;font-weight:700;color:#fff;display:flex;align-items:center;gap:.5rem}
.panel-agent-row{display:flex;align-items:center;gap:.75rem;padding:.6rem .75rem;border-radius:10px;border:1px solid var(--border);margin-bottom:.45rem;background:var(--bg);transition:all .18s}
.panel-agent-row:hover{border-color:rgba(99,102,241,.3);background:var(--accent-light)}
.panel-agent-row:last-child{margin-bottom:0}
.p-av{width:36px;height:36px;border-radius:9px;display:flex;align-items:center;justify-content:center;font-weight:700;font-size:.82rem;color:#fff;flex-shrink:0}
.p-av-blue{background:linear-gradient(135deg,var(--accent),#8b5cf6)}
.p-av-red{background:linear-gradient(135deg,var(--danger),#be123c)}
.p-av-amber{background:linear-gradient(135deg,var(--gold),#b45309)}
.rej-count{display:inline-flex;align-items:center;justify-content:center;min-width:24px;height:24px;border-radius:50%;font-size:.72rem;font-weight:800;flex-shrink:0}
.rej-1{background:var(--gold-bg);color:var(--gold);border:1px solid rgba(245,158,11,.3)}
.rej-2{background:var(--warning-bg);color:var(--warning);border:1px solid rgba(251,146,60,.3)}
.rej-3{background:var(--danger-bg);color:var(--danger);border:1px solid rgba(244,63,94,.3)}
.wd-req-row{display:flex;align-items:flex-start;gap:.75rem;padding:.75rem;border:1px solid var(--border);border-radius:10px;margin-bottom:.5rem;background:var(--bg);transition:all .18s}
.wd-req-row:hover{border-color:var(--gold);background:var(--gold-bg)}
.wd-amount{font-family:monospace;font-size:1rem;font-weight:800;color:var(--success)}
.wd-actions{display:flex;gap:.4rem;margin-top:.4rem;flex-wrap:wrap}

/* ── EMPTY STATE ── */
.empty-state{text-align:center;padding:3.5rem 2rem;color:var(--text-soft)}
.empty-state i{font-size:2.8rem;display:block;margin-bottom:.75rem;opacity:.4}
.empty-state p{font-size:.88rem}

/* ── MODALS ── */
.modal-content{background:var(--card);border:1px solid var(--border);border-radius:var(--radius);color:var(--text);box-shadow:0 24px 64px rgba(67,56,202,.18)}
.modal-header{padding:1rem 1.25rem;border-bottom:1px solid var(--border);display:flex;align-items:center;justify-content:space-between}
.mh-info{background:var(--accent-light);border-bottom-color:#c7d2fe}
.mh-warning{background:#fffbeb;border-bottom-color:#fde68a}
.mh-danger{background:#fef2f2;border-bottom-color:#fecaca}
.mh-success{background:#ecfdf5;border-bottom-color:#a7f3d0}
.mh-purple{background:#f5f3ff;border-bottom-color:#ddd6fe}
.modal-title{font-size:.9rem;font-weight:700;display:flex;align-items:center;gap:.5rem;color:var(--text)}
.modal-body{padding:1.25rem}
.modal-footer{padding:1rem 1.25rem;border-top:1px solid var(--border);display:flex;gap:.5rem;justify-content:flex-end;flex-wrap:wrap}
.btn-close-custom{background:transparent;border:1px solid var(--border);border-radius:8px;color:var(--text-mid);width:30px;height:30px;display:flex;align-items:center;justify-content:center;cursor:pointer;font-size:1rem;transition:all .18s}
.btn-close-custom:hover{border-color:var(--danger);color:var(--danger)}
.btn-modal{font-family:inherit;font-size:.8rem;font-weight:600;padding:.45rem 1.1rem;border-radius:var(--radius-sm);cursor:pointer;transition:all .18s;border:1px solid;display:inline-flex;align-items:center;gap:.35rem}
.btn-modal-primary{background:var(--accent);border-color:var(--accent);color:#fff}.btn-modal-primary:hover{background:#4f46e5}
.btn-modal-success{background:var(--success);border-color:var(--success);color:#fff}.btn-modal-success:hover{background:#059669}
.btn-modal-danger{background:var(--danger);border-color:var(--danger);color:#fff}.btn-modal-danger:hover{background:#dc2626}
.btn-modal-warning{background:var(--gold);border-color:var(--gold);color:#fff}.btn-modal-warning:hover{background:#d97706}
.btn-modal-cancel{background:transparent;border-color:var(--border);color:var(--text-mid)}.btn-modal-cancel:hover{border-color:#94a3b8;color:var(--text)}
button:disabled{opacity:.5;cursor:not-allowed!important;pointer-events:none}
.form-label-sm{display:block;font-size:.75rem;font-weight:600;color:var(--text-mid);margin-bottom:.35rem}
.form-control-sm-custom{width:100%;padding:.5rem .75rem;background:var(--card);border:1px solid var(--border);border-radius:var(--radius-sm);font-family:inherit;font-size:.83rem;color:var(--text);outline:none;transition:all .18s}
.form-control-sm-custom:focus{border-color:var(--accent);box-shadow:0 0 0 3px var(--accent-light)}
.refund-info-row{display:grid;grid-template-columns:repeat(auto-fit,minmax(100px,1fr));gap:.6rem;background:var(--bg);border:1px solid var(--border);border-radius:10px;padding:.85rem 1rem;margin-bottom:1rem}
.ri-label{font-size:.65rem;text-transform:uppercase;letter-spacing:1px;color:var(--text-soft)}
.ri-val{font-size:.88rem;font-weight:700;color:var(--text);margin-top:2px}
.refund-method-card{border:1px solid var(--border);border-radius:10px;padding:.7rem .9rem;cursor:pointer;transition:all .18s;display:flex;align-items:center;gap:.65rem;background:var(--card)}
.refund-method-card:hover{border-color:var(--accent)}
.refund-method-card.selected{border-color:var(--accent);background:var(--accent-light)}
.rm-icon{width:34px;height:34px;border-radius:9px;display:flex;align-items:center;justify-content:center;font-size:1rem}
.dp-chip{display:flex;align-items:center;gap:.75rem;padding:.75rem .9rem;border:1px solid var(--border);border-radius:10px;cursor:pointer;transition:all .18s;background:var(--card)}
.dp-chip:hover{border-color:var(--accent);background:var(--accent-light)}
.dp-chip.selected{border-color:var(--accent);background:var(--accent-light);box-shadow:var(--shadow-glow)}
.dp-chip-busy{border-color:rgba(244,63,94,.2);background:var(--danger-bg)}
.dp-chip-busy:hover{border-color:rgba(244,63,94,.3);background:var(--danger-bg)}
.dp-avatar{width:38px;height:38px;border-radius:10px;background:linear-gradient(135deg,#fbbf24,#f97316);display:flex;align-items:center;justify-content:center;font-weight:700;font-size:.85rem;color:#fff;flex-shrink:0}
.dp-name{font-size:.83rem;font-weight:600;color:var(--text)}
.dp-meta{font-size:.72rem;color:var(--text-soft);margin-top:2px;display:flex;align-items:center;gap:.3rem}
.dp-online{width:8px;height:8px;border-radius:50%;background:var(--success);margin-left:auto;flex-shrink:0}
.return-step{display:flex;gap:.85rem;align-items:flex-start;padding:.85rem 1rem;background:var(--bg);border:1px solid var(--border);border-radius:10px;margin-bottom:.5rem;transition:all .2s}
.return-step.step-active{border-color:rgba(99,102,241,.3);background:var(--accent-light)}
.return-step.step-done{opacity:.6}
.rs-num{width:28px;height:28px;border-radius:50%;flex-shrink:0;background:var(--card);border:1px solid var(--border);display:flex;align-items:center;justify-content:center;font-size:.75rem;font-weight:700;color:var(--text-soft)}
.rs-num.active{background:var(--accent);border-color:var(--accent);color:#fff}
.rs-num.done{background:var(--success);border-color:var(--success);color:#fff}
.rs-title{font-size:.85rem;font-weight:700;color:var(--text)}
.rs-detail{font-size:.78rem;color:var(--text-soft);margin-top:3px}
.cod-info-grid{display:grid;grid-template-columns:1fr 1fr;gap:.6rem;background:var(--bg);border:1px solid var(--border);border-radius:10px;padding:.85rem 1rem;margin-bottom:1rem}
.cod-info-item .ci-label{font-size:.65rem;text-transform:uppercase;letter-spacing:1px;color:var(--text-soft)}
.cod-info-item .ci-val{font-size:.88rem;font-weight:600;color:var(--text);margin-top:2px}
.rej-log-row{display:flex;align-items:flex-start;gap:.75rem;padding:.75rem .85rem;border:1px solid var(--border);border-radius:10px;margin-bottom:.5rem;background:var(--bg)}
.rej-log-row:last-child{margin-bottom:0}
.rej-log-num{width:26px;height:26px;border-radius:50%;background:var(--danger-bg);color:var(--danger);border:1px solid rgba(244,63,94,.3);display:flex;align-items:center;justify-content:center;font-size:.72rem;font-weight:800;flex-shrink:0}
.rej-log-order{font-family:monospace;font-size:.8rem;font-weight:700;color:var(--accent)}
.rej-log-reason{font-size:.82rem;color:var(--text);margin-top:2px}
.rej-log-time{font-size:.68rem;color:var(--text-soft);margin-top:3px}
.cust-info-primary{font-weight:600;color:var(--text);font-size:.83rem}
.cust-info-email{font-size:.73rem;color:var(--text-soft);margin-top:1px}
.order-id-chip{font-family:monospace;font-weight:700;font-size:.8rem;color:var(--accent)}
.photo-thumb{width:60px;height:60px;border-radius:8px;object-fit:cover;border:1px solid var(--border);cursor:pointer;transition:all .18s}
.photo-thumb:hover{transform:scale(1.06);border-color:var(--accent)}

/* ── TOAST ── */
#mainToast{font-family:inherit;font-size:.83rem;font-weight:500;border-radius:10px;min-width:260px}

/* ── BOTTOM NAV ── */
.bottom-nav{position:fixed;bottom:0;left:0;right:0;z-index:980;background:rgba(255,255,255,.95);border-top:1px solid var(--border);display:flex;justify-content:space-around;align-items:center;padding:.4rem 0 .6rem;box-shadow:0 -4px 20px rgba(67,56,202,.1);backdrop-filter:blur(10px)}
@media(min-width:768px){.bottom-nav{display:none}}
.bnav-item{flex:1;display:flex;flex-direction:column;align-items:center;gap:2px;text-decoration:none;color:var(--text-muted);font-size:.6rem;font-weight:600;transition:color .15s;position:relative}
.bnav-item i{font-size:1.2rem}
.bnav-item.active{color:var(--accent)}
.bnav-item.active::before{content:'';position:absolute;top:-4px;left:50%;transform:translateX(-50%);width:24px;height:3px;background:var(--accent);border-radius:2px}
.bnav-badge{position:absolute;top:-2px;right:calc(50% - 18px);background:var(--danger);color:#fff;font-size:.5rem;font-weight:700;min-width:14px;height:14px;border-radius:50%;display:flex;align-items:center;justify-content:center;border:1.5px solid #fff}

/* ── ANIMATIONS ── */
@keyframes fadeUp{from{opacity:0;transform:translateY(10px)}to{opacity:1;transform:none}}
.fade-up{animation:fadeUp .35s ease both}

/* ── AGENT PERFORMANCE MINI BARS ── */
.perf-bar-track{height:4px;background:var(--border);border-radius:4px;overflow:hidden;width:60px;margin-top:3px}
.perf-bar-fill{height:100%;border-radius:4px;background:linear-gradient(90deg,var(--success),#34d399)}

@media(max-width:768px){
  .stats-row{grid-template-columns:repeat(2,1fr)}
  .cust-info-email{display:none}
}
</style>
</head>
<body>

<!-- ══ NAVBAR ══ -->
<nav class="top-navbar">
  <button class="hamburger" id="hamburger-btn" aria-label="Toggle navigation">
    <i class="bi bi-list"></i>
  </button>
  <a href="OrdersDashboard" class="nav-brand">Smart<span class="dot">Stock</span>
    <span class="nav-badge"><%= role %></span>
  </a>
  <div class="nav-right">
    <a href="StaffNotifications" class="nav-icon-btn" style="position:relative">
      <i class="bi bi-bell"></i>
      <% if (unreadNotifCount > 0) { %><span class="bell-badge" id="bellBadge"><%= unreadNotifCount %></span><% } %>
    </a>
    <a href="faq.jsp" class="nav-icon-btn"><i class="bi bi-question-circle"></i></a>
    <a href="profile" class="nav-avatar" title="<%= uname %>"><%= initials %></a>
  </div>
</nav>

<!-- ══ SIDEBAR OVERLAY ══ -->
<div class="sidebar-overlay" id="sidebar-overlay"></div>

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
    <a href="OrdersDashboard" class="sidebar-link active"><i class="bi bi-bag-check"></i> Manage Orders <span class="sidebar-badge"><%= totalOrders %></span></a>
    <a href="ProductServlet" class="sidebar-link"><i class="bi bi-boxes"></i> Products</a>
    <a href="BillsPage" class="sidebar-link"><i class="bi bi-receipt"></i> Bills &amp; Invoices</a>

    <div class="sidebar-section">Attendance</div>
    <a href="UserDashboardServlet#attendance-panel" class="sidebar-link"><i class="bi bi-clock-history"></i> My Attendance</a>
    <a href="LeaveServlet?action=apply" class="sidebar-link"><i class="bi bi-calendar-heart"></i> Apply Leave</a>

    <div class="sidebar-section">Support</div>
    <a href="StaffNotifications" class="sidebar-link">
      <i class="bi bi-bell"></i> Notifications
      <% if (unreadNotifCount > 0) { %><span class="sidebar-badge"><%= unreadNotifCount %></span><% } %>
    </a>
    <a href="feedback.jsp" class="sidebar-link"><i class="bi bi-chat-dots"></i> Customer Feedback</a>
    <a href="ticketDashboard.jsp" class="sidebar-link" id="nav-tickets-link">
      <i class="bi bi-ticket-perforated"></i>
      <span>Customer Tickets</span>
      <span id="nav-ticket-badge" style="display:none;background:#ef4444;color:#fff;border-radius:10px;padding:1px 7px;font-size:10px;font-weight:700;margin-left:auto;"></span>
    </a>
    <a href="faq.jsp" class="sidebar-link"><i class="bi bi-question-circle"></i> Help &amp; FAQs</a>

    <% if ("admin".equalsIgnoreCase(role)) { %>
    <div class="sidebar-section">Admin</div>
    <a href="adminDashboard" class="sidebar-link"><i class="bi bi-shield-check"></i> Admin Panel</a>
    <a href="reports.jsp" class="sidebar-link"><i class="bi bi-graph-up"></i> Analytics</a>
    <% } %>

    <div class="sidebar-section">Account</div>
    <a href="logout" class="sidebar-link danger"><i class="bi bi-box-arrow-right"></i> Logout</a>
  </div>
  <div class="sidebar-footer">© 2026 SmartStock Inventory</div>
</aside>

<!-- ══ MAIN ══ -->
<main class="main-content" id="mainContent">

  <!-- Welcome Banner -->
  <div class="welcome-banner fade-up">
    <div class="online-badge"><span class="pulse-dot"></span> Live &amp; Active</div>
    <div class="wb-greeting"><%= (java.util.Calendar.getInstance().get(java.util.Calendar.HOUR_OF_DAY) < 12) ? "Good Morning" : (java.util.Calendar.getInstance().get(java.util.Calendar.HOUR_OF_DAY) < 17) ? "Good Afternoon" : "Good Evening" %>,</div>
    <div class="wb-name"><%= uname %> 👋</div>
    <div class="wb-meta">
      <div><i class="bi bi-person-badge"></i> Role: <span><%= role != null ? role.substring(0,1).toUpperCase()+role.substring(1).toLowerCase() : "Staff" %></span></div>
      <div><i class="bi bi-calendar3"></i> <span><%= new java.text.SimpleDateFormat("dd MMM yyyy · hh:mm a").format(new java.util.Date()) %></span></div>
      <% if (unreadNotifCount > 0) { %><div><i class="bi bi-bell-fill" style="color:#fbbf24;"></i> <span><%= unreadNotifCount %> unread alert<%= unreadNotifCount != 1 ? "s" : "" %></span></div><% } %>
      <% if (!pendingWithdrawals.isEmpty()) { %><div><i class="bi bi-cash-stack" style="color:#6ee7b7;"></i> <span><%= pendingWithdrawals.size() %> withdrawal request<%= pendingWithdrawals.size() != 1 ? "s" : "" %></span></div><% } %>
    </div>
  </div>

  <!-- Stats Row -->
  <div class="stats-row fade-up">
    <div class="stat-card"><div class="stat-icon si-blue"><i class="bi bi-bag-check"></i></div><div class="stat-num"><%= totalOrders %></div><div class="stat-lbl">Total Orders</div></div>
    <div class="stat-card"><div class="stat-icon si-amber"><i class="bi bi-hourglass-split"></i></div><div class="stat-num"><%= pendingCount %></div><div class="stat-lbl">Pending</div></div>
    <div class="stat-card"><div class="stat-icon si-indigo"><i class="bi bi-shield-check"></i></div><div class="stat-num"><%= confirmedCount %></div><div class="stat-lbl">Confirmed</div></div>
    <div class="stat-card"><div class="stat-icon si-teal"><i class="bi bi-person-badge"></i></div><div class="stat-num"><%= assignedCount %></div><div class="stat-lbl">In Transit</div></div>
    <div class="stat-card"><div class="stat-icon si-blue"><i class="bi bi-box-seam"></i></div><div class="stat-num"><%= packedCount %></div><div class="stat-lbl">Packed</div></div>
    <div class="stat-card"><div class="stat-icon si-green"><i class="bi bi-check-circle"></i></div><div class="stat-num"><%= deliveredCount %></div><div class="stat-lbl">Delivered</div></div>
    <div class="stat-card"><div class="stat-icon si-red"><i class="bi bi-x-circle"></i></div><div class="stat-num"><%= cancelledCount %></div><div class="stat-lbl">Cancelled</div></div>
    <div class="stat-card"><div class="stat-icon si-return"><i class="bi bi-arrow-return-left"></i></div><div class="stat-num"><%= returnCount %></div><div class="stat-lbl">Returns</div></div>
  </div>

  <!-- ══ TABS NAVIGATION ══ -->
  <div class="tabs-nav fade-up" id="mainTabs">
    <button class="tab-btn active" onclick="switchTab('orders', this)">
      <i class="bi bi-list-columns-reverse"></i> All Orders
      <span class="tab-count"><%= totalOrders %></span>
    </button>
    <button class="tab-btn" onclick="switchTab('performance', this)">
      <i class="bi bi-trophy"></i> Agent Performance
    </button>
    <% if (!pendingWithdrawals.isEmpty()) { %>
    <button class="tab-btn" onclick="switchTab('withdrawals', this)">
      <i class="bi bi-cash-stack"></i> Withdraw Requests
      <span class="tab-count"><%= pendingWithdrawals.size() %></span>
    </button>
    <% } %>
    <% if (!rejectionSummary.isEmpty()) { %>
    <button class="tab-btn" onclick="switchTab('rejections', this)">
      <i class="bi bi-slash-circle"></i> Rejected Tasks
      <span class="tab-count"><%= rejectionSummary.size() %></span>
    </button>
    <% } %>
    <% if (cancelledCount > 0) { %>
    <button class="tab-btn" onclick="switchTab('cancellations', this)">
      <i class="bi bi-x-octagon"></i> Cancellations
      <span class="tab-count"><%= cancelledCount %></span>
    </button>
    <% } %>
    <% if (returnCount > 0) { %>
    <button class="tab-btn" onclick="switchTab('returns', this)">
      <i class="bi bi-arrow-return-left"></i> Returns
      <span class="tab-count"><%= returnCount %></span>
    </button>
    <% } %>
  </div>

  <!-- ══ TAB: ALL ORDERS ══ -->
  <div class="tab-pane active fade-up" id="tab-orders">
    <!-- Toolbar -->
    <div class="toolbar">
      <div class="search-box">
        <i class="bi bi-search"></i>
        <input type="text" id="searchInput" placeholder="Search customer, order ID, email…">
      </div>
      <select id="statusFilter" class="filter-select">
        <option value="all">All Status</option>
        <option value="ordered">Ordered</option>
        <option value="pending">Pending</option>
        <option value="confirmed">Confirmed</option>
        <option value="assigned">Assigned</option>
        <option value="picked up">Picked Up</option>
        <option value="packed">Packed</option>
        <option value="shipped">Shipped</option>
        <option value="out for delivery">Out for Delivery</option>
        <option value="delivered">Delivered</option>
        <option value="cancelled">Cancelled</option>
        <option value="return">Returns</option>
        <option value="processing">Processing</option>
        <option value="refunded">Refunded</option>
        <option value="replaced">Replaced</option>
      </select>
      <select id="payFilter" class="filter-select">
        <option value="all">All Payments</option>
        <option value="paid">Paid (Online)</option>
        <option value="cod">COD</option>
        <option value="refunded">Refunded</option>
      </select>
      <div style="margin-left:auto;font-size:.78rem;color:var(--text-soft);">
        <span id="visibleCount"><%= totalOrders %></span>/<strong><%= totalOrders %></strong> orders
      </div>
    </div>

    <!-- Orders Table -->
    <div class="table-card">
      <div class="table-card-header">
        <span class="table-card-title"><i class="bi bi-list-columns-reverse"></i> All Customer Orders</span>
        <span class="table-count">Updated <%= new java.text.SimpleDateFormat("hh:mm a").format(new java.util.Date()) %></span>
      </div>
      <div class="table-responsive">
        <table id="ordersTable">
          <thead>
            <tr>
              <th>Order #</th><th>Customer</th><th>Payment</th><th>Order Date</th>
              <th>Delivery Date</th><th>Status</th><th>Total</th>
              <th>Delivery Agent</th><th>Action Required</th><th>Manage</th>
            </tr>
          </thead>
          <tbody>
          <%
          for (Order order : orders) {
              String status = order.getStatus() != null ? order.getStatus() : "Ordered";
              int progress = 0; String progressCss = "background:#4b5563;";
              switch (status) {
                case "Ordered": progress=5; progressCss="background:#38bdf8;"; break;
                case "Pending": progress=12; progressCss="background:#f59e0b;"; break;
                case "Confirmed": progress=25; progressCss="background:#6366f1;"; break;
                case "Assigned": progress=38; progressCss="background:#2dd4bf;"; break;
                case "Picked Up": progress=50; progressCss="background:#a78bfa;"; break;
                case "Packed": progress=60; progressCss="background:#38bdf8;"; break;
                case "Shipped": progress=73; progressCss="background:#6366f1;"; break;
                case "Out for Delivery": progress=87; progressCss="background:#fb923c;"; break;
                case "Delivered": case "Completed": progress=100; progressCss="background:#10b981;"; break;
                case "Cancelled": progress=100; progressCss="background:#f43f5e;"; break;
                case "Return Requested": progress=20; progressCss="background:#fb923c;"; break;
                case "Return Approved": progress=40; progressCss="background:#38bdf8;"; break;
                case "Return Agent Assigned": progress=55; progressCss="background:#2dd4bf;"; break;
                case "Return Out for Pickup": progress=70; progressCss="background:#a78bfa;"; break;
                case "Return Picked": progress=85; progressCss="background:#a78bfa;"; break;
                case "Processing": progress=92; progressCss="background:#6366f1;"; break;
                case "Refunded": case "Replaced": progress=100; progressCss="background:#10b981;"; break;
                default: progress=5; progressCss="background:#f59e0b;"; break;
              }
              boolean isCod=("PENDING_COD".equalsIgnoreCase(order.getPaymentStatus()));
              boolean isPaid=("PAID".equalsIgnoreCase(order.getPaymentStatus()));
              boolean isRefunded=("REFUNDED".equalsIgnoreCase(order.getPaymentStatus()));
              boolean needsAct=("Pending".equalsIgnoreCase(status)||"Ordered".equalsIgnoreCase(status))&&(isCod||isPaid);
              boolean isReturn=status.startsWith("Return")||"Refunded".equals(status)||"Replaced".equals(status)||"Processing".equals(status);
              String statusCss;
              switch (status) {
                case "Ordered": statusCss="s-ordered"; break; case "Pending": statusCss="s-pending"; break;
                case "Confirmed": statusCss="s-confirmed"; break; case "Assigned": statusCss="s-assigned"; break;
                case "Picked Up": statusCss="s-pickedup"; break; case "Packed": statusCss="s-packed"; break;
                case "Shipped": statusCss="s-shipped"; break; case "Out for Delivery": statusCss="s-ofd"; break;
                case "Delivered": case "Completed": statusCss="s-delivered"; break;
                case "Cancelled": statusCss="s-cancelled"; break;
                case "Return Requested": case "Return Approved": case "Return Agent Assigned":
                case "Return Out for Pickup": case "Return Picked": statusCss="s-return"; break;
                case "Processing": statusCss="s-processing"; break;
                case "Refunded": statusCss="s-refunded"; break; case "Replaced": statusCss="s-replaced"; break;
                default: statusCss="s-pending"; break;
              }
              String safeName=(order.getCustomerName()!=null)?order.getCustomerName().replace("'","&#39;"):"Unknown";
              String safeEmail=(order.getCustomerEmail()!=null)?order.getCustomerEmail():"";
              String safeTxn=(order.getTransactionId()!=null)?order.getTransactionId():"";
              com.util.OrderReturn rr=order.getReturnRequest();
              boolean isReturnExists=(rr!=null);
              String rrStatus=isReturnExists?(rr.getStatus()!=null?rr.getStatus():""):"";
              String rrType=isReturnExists?(rr.getType()!=null?rr.getType():"Return"):"Return";
              String rrReason=isReturnExists&&rr.getReason()!=null?rr.getReason().replace("'","&#39;"):"N/A";
              String rrPhotos=(isReturnExists&&rr.getPhotos()!=null)?rr.getPhotos().replace("\\",""):"";
              String bName=(isReturnExists&&rr.getBankName()!=null)?rr.getBankName():"";
              String bAcc=(isReturnExists&&rr.getBankAccount()!=null)?rr.getBankAccount():"";
              String bIfsc=(isReturnExists&&rr.getBankIfsc()!=null)?rr.getBankIfsc():"";
              String nextStatus=null,btnLabel=null,btnIcon=null,btnCssClass="btn-tbl btn-update";
              String os=order.getStatus()!=null?order.getStatus():"";
              switch(os){
                case "Ordered": case "Pending": nextStatus="Confirmed"; btnLabel="Confirm"; btnIcon="bi-shield-check"; break;
                case "Confirmed": nextStatus="Assigned"; btnLabel="Mark Assigned"; btnIcon="bi-person-badge"; break;
                case "Assigned": nextStatus="Picked Up"; btnLabel="Mark Picked Up"; btnIcon="bi-bag-check"; btnCssClass="btn-tbl btn-success"; break;
                case "Picked Up": nextStatus="Packed"; btnLabel="Mark Packed"; btnIcon="bi-box-seam"; break;
                case "Packed": nextStatus="Shipped"; btnLabel="Mark Shipped"; btnIcon="bi-send"; break;
                case "Shipped": nextStatus="Out for Delivery"; btnLabel="Out for Del."; btnIcon="bi-bicycle"; break;
                case "Out for Delivery": nextStatus="Delivered"; btnLabel="Mark Delivered"; btnIcon="bi-house-check"; btnCssClass="btn-tbl btn-success"; break;
                case "Return Requested": nextStatus=null; btnLabel=isReturnExists?"View "+rrType:"Handle Return"; btnIcon="bi-arrow-return-left"; btnCssClass="btn-tbl btn-return"; break;
                case "Return Approved": nextStatus=null; btnLabel="Assign Pickup Agent"; btnIcon="bi-person-badge"; btnCssClass="btn-tbl btn-assign"; break;
                case "Return Agent Assigned": nextStatus=null; btnLabel="Agent Out for Pickup"; btnIcon="bi-bicycle"; btnCssClass="btn-tbl btn-update"; break;
                case "Return Out for Pickup": nextStatus=null; btnLabel="Confirm Item Picked"; btnIcon="bi-box-arrow-in-down"; btnCssClass="btn-tbl btn-success"; break;
                case "Return Picked": nextStatus=null; btnLabel="Process Refund"; btnIcon="bi-arrow-counterclockwise"; btnCssClass="btn-tbl btn-refund"; break;
                default: nextStatus=null; btnLabel=null; break;
              }
          %>
          <tr class="<%= needsAct?"row-needs-action":isReturn?"row-return":"" %>"
              data-customer="<%= order.getCustomerName()!=null?order.getCustomerName().toLowerCase():"" %>"
              data-email="<%= safeEmail.toLowerCase() %>"
              data-orderid="<%= order.getId() %>"
              data-status="<%= status.toLowerCase() %>"
              data-pay="<%= isRefunded?"refunded":isPaid?"paid":isCod?"cod":"other" %>">
            <td><span class="order-id-chip">#<%= order.getId() %></span></td>
            <td><div class="cust-info-primary"><%= order.getCustomerName()!=null?order.getCustomerName():"—" %></div><div class="cust-info-email"><%= safeEmail %></div></td>
            <td>
              <% if(isCod){%><span class="pay-pill pay-cod"><i class="bi bi-cash-coin"></i> COD</span><%}else if(isPaid){%><span class="pay-pill pay-paid"><i class="bi bi-credit-card-2-back"></i> Online</span><%}else if(isRefunded){%><span class="pay-pill pay-refunded"><i class="bi bi-arrow-counterclockwise"></i> Refunded</span><%}else{%><span class="pay-pill pay-unknown"><%= order.getPaymentStatus()!=null?order.getPaymentStatus():"—" %></span><%}%>
            </td>
            <td style="font-size:.78rem;color:var(--text-mid);"><%= order.getDate()!=null?new java.text.SimpleDateFormat("dd MMM yy").format(order.getDate()):"—" %></td>
            <td style="font-size:.78rem;color:var(--text-mid);">
              <% if(order.getDeliveryDate()!=null){%><%= new java.text.SimpleDateFormat("dd MMM yy").format(order.getDeliveryDate()) %><%if("Delivered".equals(status)||"Completed".equals(status)){%><div style="font-size:.65rem;color:var(--success);margin-top:2px;"><i class="bi bi-check-circle"></i> Delivered</div><%}%><%}else{%><span style="color:var(--text-soft);">Not set</span><%}%>
            </td>
            <td>
              <span class="status-badge <%= statusCss %>"><i class="bi bi-dot"></i> <%= status %></span>
              <div class="progress-wrap"><div class="progress-fill" style="width:0%;" data-width="<%= progress %>" style="<%= progressCss %>"></div></div>
            </td>
            <td style="font-weight:700;color:var(--success);font-family:monospace;font-size:.82rem;">₹<%= String.format("%.2f",order.getTotalAmount()) %></td>
            <td>
              <% if(order.getDeliveryUserName()!=null&&!order.getDeliveryUserName().isEmpty()){%>
              <div style="display:flex;align-items:center;gap:.5rem;">
                <div style="width:30px;height:30px;border-radius:9px;background:var(--sky-bg);color:var(--sky);display:flex;align-items:center;justify-content:center;font-size:.75rem;font-weight:700;flex-shrink:0;border:1px solid rgba(56,189,248,.2);"><%= String.valueOf(order.getDeliveryUserName().charAt(0)).toUpperCase() %></div>
                <div><div style="font-size:.8rem;font-weight:600;color:var(--text);"><%= order.getDeliveryUserName() %></div><div style="font-size:.68rem;color:var(--success);">● Assigned</div></div>
              </div>
              <%}else{%><span style="font-size:.75rem;color:var(--text-soft);">Not assigned</span><%}%>
            </td>
            <td style="min-width:160px;font-size:.78rem;">
              <%if(("Ordered".equalsIgnoreCase(status)||"Pending".equalsIgnoreCase(status))&&isCod){%><span style="color:var(--gold);font-weight:600;"><i class="bi bi-box-seam"></i> Confirm &amp; prepare<br><i class="bi bi-cash-coin"></i> Collect ₹<%= String.format("%.2f",order.getTotalAmount()) %> on delivery</span>
              <%}else if(("Ordered".equalsIgnoreCase(status)||"Pending".equalsIgnoreCase(status))&&isPaid){%><span style="color:var(--success);font-weight:600;"><i class="bi bi-shield-check"></i> Payment confirmed<br><i class="bi bi-arrow-right-circle"></i> Confirm order</span>
              <%}else if("Confirmed".equalsIgnoreCase(status)){%><span style="color:var(--accent);"><i class="bi bi-person-badge"></i> Assign delivery agent</span>
              <%}else if("Assigned".equalsIgnoreCase(status)){%><span style="color:var(--teal);"><i class="bi bi-bag-check"></i> Agent picking from warehouse</span>
              <%}else if("Picked Up".equalsIgnoreCase(status)){%><span style="color:var(--purple);"><i class="bi bi-box-seam"></i> Pack the order</span>
              <%}else if("Packed".equalsIgnoreCase(status)){%><span style="color:var(--sky);"><i class="bi bi-send"></i> Dispatch for shipping</span>
              <%}else if("Shipped".equalsIgnoreCase(status)){%><span style="color:var(--accent);"><i class="bi bi-truck"></i> In transit to customer</span>
              <%}else if("Out for Delivery".equalsIgnoreCase(status)){%><span style="color:var(--warning);font-weight:600;"><i class="bi bi-geo-alt"></i> Agent delivering now<br><i class="bi bi-shield-lock"></i> OTP: <%= order.getOtp()%></span>
              <%}else if("Delivered".equalsIgnoreCase(status)||"Completed".equalsIgnoreCase(status)){%><span style="color:var(--success);"><i class="bi bi-check2-all"></i> Completed</span>
              <%}else if("Return Requested".equalsIgnoreCase(status)){%><span style="color:var(--warning);font-weight:600;"><i class="bi bi-arrow-return-left"></i> Verify &amp; approve return<br><small style="color:var(--text-soft);"><%= rrType %> request</small></span>
              <%}else if("Return Approved".equalsIgnoreCase(status)){%><span style="color:var(--sky);font-weight:600;"><i class="bi bi-person-plus"></i> Assign pickup agent</span>
              <%}else if("Return Agent Assigned".equalsIgnoreCase(status)){%><span style="color:var(--teal);font-weight:600;"><i class="bi bi-bicycle"></i> Agent assigned<br><small>Waiting for pickup</small></span>
              <%}else if("Return Out for Pickup".equalsIgnoreCase(status)){%><span style="color:var(--purple);font-weight:600;"><i class="bi bi-truck"></i> Agent out for pickup<br><small>Confirm when collected</small></span>
              <%}else if("Return Picked".equalsIgnoreCase(status)){%><span style="color:var(--purple);font-weight:600;"><i class="bi bi-box-arrow-in-down"></i> Item collected<br><small>Process refund/replace</small></span>
              <%}else if("Processing".equalsIgnoreCase(status)){%><span style="color:var(--accent);font-weight:600;"><i class="bi bi-gear"></i> Processing return</span>
              <%}else if("Refunded".equalsIgnoreCase(status)){%><span style="color:var(--success);font-weight:600;"><i class="bi bi-check-circle"></i> Refunded</span>
              <%}else if("Replaced".equalsIgnoreCase(status)){%><span style="color:var(--teal);font-weight:600;"><i class="bi bi-arrow-repeat"></i> Replaced</span>
              <%}else if("Cancelled".equalsIgnoreCase(status)){%><span style="color:var(--danger);"><i class="bi bi-x-circle"></i> Cancelled<% if(isRefunded){%><br><span style="color:var(--purple);"><i class="bi bi-check-circle"></i> Refunded</span><%}%></span>
              <%}else{%><span style="color:var(--text-soft);">—</span><%}%>
            </td>
            <td>
              <div class="action-col">
                <a href="OrdersDashboard?action=view&orderId=<%= order.getId() %>" class="btn-tbl btn-invoice"><i class="bi bi-file-earmark-text"></i> Invoice</a>
                <% if(!("Delivered".equalsIgnoreCase(status))&&!("Cancelled".equalsIgnoreCase(status))&&!isReturn&&!("Refunded".equals(status))&&!("Replaced".equals(status))){%>
                  <button class="btn-tbl btn-assign" type="button" onclick="openAssignModal('<%= order.getId() %>','<%= safeName %>')"><i class="bi bi-person-badge"></i> Assign Agent</button>
                <%}%>
                <%if(btnLabel!=null){%>
                  <%if(nextStatus!=null){%>
                  <form action="OrdersDashboard" method="post" style="margin:0;" onsubmit="return confirm('Mark order #<%= order.getId() %> as <%= nextStatus %>?')">
                    <input type="hidden" name="source" value="staff"><input type="hidden" name="action" value="updateStatus"><input type="hidden" name="orderId" value="<%= order.getId() %>"><input type="hidden" name="status" value="<%= nextStatus %>">
                    <button type="submit" class="<%= btnCssClass %>"><i class="bi <%= btnIcon %>"></i> <%= btnLabel %></button>
                  </form>
                  <%}else{%>
                    <%if("Return Agent Assigned".equalsIgnoreCase(os)){%>
                    <button class="<%= btnCssClass %>" type="button" onclick="postAction('agentOutForPickup','<%= order.getId() %>','Mark agent as out for pickup for order #<%= order.getId() %>?')"><i class="bi <%= btnIcon %>"></i> <%= btnLabel %></button>
                    <%}else if("Return Out for Pickup".equalsIgnoreCase(os)){%>
                    <button class="<%= btnCssClass %>" type="button" onclick="postAction('confirmPickup','<%= order.getId() %>','Confirm item has been picked up for order #<%= order.getId() %>?')"><i class="bi <%= btnIcon %>"></i> <%= btnLabel %></button>
                    <%}else{%>
                    <button class="<%= btnCssClass %>" type="button" onclick="openReturnModal('<%= order.getId() %>','<%= safeName %>','<%= safeEmail %>','<%= String.format("%.2f",order.getTotalAmount()) %>','<%= os %>','<%= safeTxn %>','<%= rrType %>','<%= rrReason %>','<%= rrPhotos %>','<%= bName %>','<%= bAcc %>','<%= bIfsc %>','<%= rrStatus %>')"><i class="bi <%= btnIcon %>"></i> <%= btnLabel %></button>
                    <%}%>
                  <%}%>
                <%}%>
                <%
                  boolean canRefund=isPaid&&"Cancelled".equalsIgnoreCase(status)&&isReturnExists&&"Pending Refund".equals(rrStatus);
                  double refundableAmount=(isReturnExists&&rr.getRefundAmount()>0)?rr.getRefundAmount():order.getTotalAmount();
                  boolean hasPaymentId=safeTxn!=null&&!safeTxn.isEmpty();
                  String existingRefundMethod=isReturnExists&&rr.getRefundMethod()!=null?rr.getRefundMethod():"wallet";
                %>
                <%if(canRefund&&!isRefunded){%>
                  <button class="btn-tbl btn-refund" type="button" onclick="openRefundModal('<%= order.getId() %>','<%= safeTxn %>','<%= String.format("%.2f",refundableAmount) %>','<%= String.format("%.2f",order.getTotalAmount()) %>','<%= existingRefundMethod %>','<%= hasPaymentId %>')"><i class="bi bi-arrow-counterclockwise"></i> Refund ₹<%= String.format("%.0f",refundableAmount) %></button>
                <%}%>
                <form action="OrdersDashboard" method="post" style="margin:0;">
                  <input type="hidden" name="source" value="staff"><input type="hidden" name="action" value="updateDeliveryDate"><input type="hidden" name="orderId" value="<%= order.getId() %>">
                  <div class="input-row">
                    <input type="date" name="deliveryDate" class="input-date-sm" title="Set/update delivery date" value="<%= order.getDeliveryDate()!=null?order.getDeliveryDate().toString():"" %>">
                    <button type="submit" class="btn-tbl btn-invoice" style="padding:.3rem .6rem;" title="Save date"><i class="bi bi-calendar-check"></i></button>
                  </div>
                </form>
                <% boolean canCancelFromDash=!("Delivered".equalsIgnoreCase(status))&&!("Cancelled".equalsIgnoreCase(status))&&!isReturn&&!("Refunded".equals(status))&&!("Replaced".equals(status));%>
                <%if(canCancelFromDash){%>
                  <button class="btn-tbl btn-cancel" type="button" onclick="openCancelOrderModal('<%= order.getId() %>','<%= safeName %>','<%= os %>')"><i class="bi bi-x-circle"></i> Cancel</button>
                <%}%>
                <%
                  // FIX: Only show the "Confirm Deposit" button after the agent has submitted
                  // a deposit request (payment_status = 'DEPOSIT_PENDING').
                  // Previously this was shown for ANY delivered COD order, regardless of
                  // whether the agent had initiated the deposit — showing it by default was wrong.
                  boolean needsCodDeposit=("COD".equalsIgnoreCase(order.getPaymentMethod()))
                      && "DEPOSIT_PENDING".equalsIgnoreCase(order.getPaymentStatus());
                %>
                <%if(needsCodDeposit&&order.getDeliveryUserId()>0){%>
                  <button class="btn-tbl btn-cod-deposit" type="button" onclick="openCodDepositModal('<%= order.getId() %>','<%= order.getDeliveryUserId() %>','<%= order.getDeliveryUserName()!=null?order.getDeliveryUserName():"Agent" %>','<%= String.format("%.2f",order.getTotalAmount()) %>')"><i class="bi bi-cash-coin"></i> Confirm Deposit</button>
                <%}else if("DEPOSITED".equalsIgnoreCase(order.getPaymentStatus())){%>
                  <span class="deposited-badge"><i class="bi bi-check-circle-fill"></i> Cash Deposited</span>
                <%}%>
              </div>
            </td>
          </tr>
          <% } %>
          <% if(orders.isEmpty()){%>
          <tr><td colspan="10"><div class="empty-state"><i class="bi bi-inbox"></i><p>No orders found. Orders will appear here once customers place them.</p></div></td></tr>
          <%}%>
          </tbody>
        </table>
      </div>
    </div>
  </div><!-- /#tab-orders -->

  <!-- ══ TAB: AGENT PERFORMANCE ══ -->
  <div class="tab-pane fade-up" id="tab-performance">
    <div class="panel-card">
      <div class="panel-card-header">
        <span class="panel-card-title"><i class="bi bi-trophy" style="color:#fbbf24;"></i> Agent Performance Today</span>
        <span style="font-size:.72rem;color:rgba(255,255,255,.6);">Delivered orders &amp; earnings</span>
      </div>
      <% if (deliveryPersons.isEmpty()) { %>
      <div class="empty-state"><i class="bi bi-people"></i><p>No delivery agents found.</p></div>
      <% } else {
         for (User dp : deliveryPersons) {
           java.math.BigDecimal earnToday=(agentEarningsToday instanceof java.math.BigDecimal)?(java.math.BigDecimal)agentEarningsToday:java.math.BigDecimal.ZERO;
           java.math.BigDecimal earnTotal=(agentTotalEarned instanceof java.math.BigDecimal)?(java.math.BigDecimal)agentTotalEarned:java.math.BigDecimal.ZERO;
           long agentOrders=orders.stream().filter(o->o.getDeliveryUserId()==dp.getUid()&&("Delivered".equalsIgnoreCase(o.getStatus())||"Completed".equalsIgnoreCase(o.getStatus()))).count();
      %>
      <div class="panel-agent-row">
        <div class="p-av p-av-blue"><%= String.valueOf(dp.getUsername().charAt(0)).toUpperCase() %></div>
        <div style="flex:1;min-width:0;">
          <div style="font-size:.85rem;font-weight:700;color:var(--text);"><%= dp.getUsername() %></div>
          <div style="font-size:.72rem;color:var(--text-soft);margin-top:2px;"><i class="bi bi-check2-circle"></i> <%= agentOrders %> delivered &nbsp;·&nbsp; <i class="bi bi-telephone"></i> <%= dp.getMobileno()!=null?dp.getMobileno():"—" %></div>
          <div class="perf-bar-track"><div class="perf-bar-fill" style="width:<%= Math.min(100,(int)(agentOrders*10)) %>%;"></div></div>
        </div>
        <div style="text-align:right;flex-shrink:0;">
          <div style="font-size:.92rem;font-weight:700;color:var(--success);">&#8377;<%= String.format("%.0f",earnToday) %></div>
          <div style="font-size:.63rem;color:var(--text-soft);">Today</div>
        </div>
        <div style="text-align:right;min-width:80px;margin-left:.75rem;flex-shrink:0;">
          <div style="font-size:.85rem;font-weight:600;color:var(--accent);">&#8377;<%= String.format("%.0f",earnTotal) %></div>
          <div style="font-size:.63rem;color:var(--text-soft);">All Time</div>
        </div>
      </div>
      <% }} %>
    </div>
  </div><!-- /#tab-performance -->

  <!-- ══ TAB: WITHDRAW REQUESTS ══ -->
  <% if (!pendingWithdrawals.isEmpty()) { %>
  <div class="tab-pane fade-up" id="tab-withdrawals">
    <div class="panel-card">
      <div class="panel-card-header">
        <span class="panel-card-title"><i class="bi bi-cash-stack" style="color:#fbbf24;"></i> Pending Withdrawal Requests</span>
        <span style="background:rgba(251,191,36,.25);color:#fbbf24;border:1px solid rgba(251,191,36,.4);font-size:.65rem;font-weight:700;padding:2px 9px;border-radius:20px;"><%= pendingWithdrawals.size() %> pending</span>
      </div>
      <% for (java.util.Map<String,Object> wd : pendingWithdrawals) {
           int wdId=(int)wd.get("id");
           String wdAgent=String.valueOf(wd.get("agentName"));
           double wdAmt=(double)wd.get("amount");
           String wdReason=wd.get("reason")!=null?String.valueOf(wd.get("reason")):"";
           java.sql.Timestamp wdAt=(java.sql.Timestamp)wd.get("requestedAt");
      %>
      <div class="wd-req-row">
        <div class="p-av p-av-amber" style="width:36px;height:36px;font-size:.8rem;"><%= wdAgent.length()>0?String.valueOf(wdAgent.charAt(0)).toUpperCase():"A" %></div>
        <div style="flex:1;min-width:0;">
          <div style="font-size:.85rem;font-weight:700;color:var(--text);"><%= wdAgent %></div>
          <div class="wd-amount">&#8377;<%= String.format("%.2f",wdAmt) %></div>
          <%if(!wdReason.isEmpty()){%><div style="font-size:.72rem;color:var(--text-soft);margin-top:2px;"><i class="bi bi-chat-left-quote"></i> <%= wdReason.length()>60?wdReason.substring(0,60)+"…":wdReason %></div><%}%>
          <div style="font-size:.65rem;color:var(--text-soft);margin-top:2px;"><%= wdAt!=null?new java.text.SimpleDateFormat("dd MMM · hh:mm a").format(wdAt):"" %></div>
          <div class="wd-actions">
            <button class="btn-tbl btn-success" onclick="handleWithdrawal('<%= wdId %>','approve','<%= wdAgent.replace("'","&#39;") %>','<%= String.format("%.2f",wdAmt) %>')"><i class="bi bi-check-circle"></i> Approve</button>
            <button class="btn-tbl btn-cancel" onclick="handleWithdrawal('<%= wdId %>','reject','<%= wdAgent.replace("'","&#39;") %>','<%= String.format("%.2f",wdAmt) %>')"><i class="bi bi-x-circle"></i> Reject</button>
          </div>
        </div>
      </div>
      <% } %>
    </div>
  </div><!-- /#tab-withdrawals -->
  <% } %>

  <!-- ══ TAB: REJECTED TASKS ══ -->
  <% if (!rejectionSummary.isEmpty()) { %>
  <div class="tab-pane fade-up" id="tab-rejections">
    <div class="panel-card">
      <div class="panel-card-header">
        <span class="panel-card-title"><i class="bi bi-slash-circle" style="color:#f87171;"></i> Task Rejections by Agent</span>
        <span style="background:rgba(220,38,38,.2);color:#f87171;border:1px solid rgba(244,63,94,.3);font-size:.65rem;font-weight:700;padding:2px 9px;border-radius:20px;"><%= rejectionSummary.size() %> agent<%= rejectionSummary.size()!=1?"s":"" %> &nbsp;·&nbsp; <%= restrictedAgents %> restricted</span>
      </div>
      <% for (java.util.Map<String,Object> rs : rejectionSummary) {
           int rAgentId=((Number)rs.get("agentId")).intValue();
           int rCount=((Number)rs.get("rejectionCount")).intValue();
           String rName=String.valueOf(rs.get("agentName"));
           String rStatus=String.valueOf(rs.get("agentStatus"));
           boolean isRestricted="restricted".equalsIgnoreCase(rStatus);
           String rejCss=rCount>=3?"rej-3":rCount==2?"rej-2":"rej-1";
      %>
      <div class="panel-agent-row">
        <div class="p-av p-av-red"><%= rName.length()>0?String.valueOf(rName.charAt(0)).toUpperCase():"A" %></div>
        <div style="flex:1;min-width:0;">
          <div style="font-size:.85rem;font-weight:700;color:var(--text);">
            <%= rName %>
            <%if(isRestricted){%><span class="restricted-pill"><i class="bi bi-slash-circle"></i> Restricted</span><%}else{%><span class="active-pill"><i class="bi bi-dot"></i> Active</span><%}%>
          </div>
          <div style="font-size:.72rem;color:var(--text-soft);margin-top:2px;"><i class="bi bi-exclamation-circle"></i> <%= rCount %> rejection<%= rCount!=1?"s":"" %></div>
        </div>
        <span class="rej-count <%= rejCss %>"><%= rCount %></span>
        <div style="display:flex;flex-direction:column;gap:.3rem;margin-left:.5rem;">
          <button class="btn-tbl btn-update" onclick="viewRejectionLog(<%= rAgentId %>,'<%= rName.replace("'","&#39;") %>')"><i class="bi bi-eye"></i> Details</button>
          <%if(isRestricted){%><button class="btn-tbl btn-success" onclick="unblockAgent(<%= rAgentId %>,'<%= rName.replace("'","&#39;") %>')"><i class="bi bi-unlock"></i> Unblock</button><%}%>
        </div>
      </div>
      <% } %>
    </div>
  </div><!-- /#tab-rejections -->
  <% } %>

  <!-- ══ TAB: CANCELLATIONS ══ -->
  <% if (cancelledCount > 0) { %>
  <div class="tab-pane fade-up" id="tab-cancellations">
    <div class="toolbar">
      <div class="search-box"><i class="bi bi-search"></i><input type="text" id="cancelSearchInput" placeholder="Search cancelled orders…"></div>
    </div>
    <div class="table-card">
      <div class="table-card-header">
        <span class="table-card-title"><i class="bi bi-x-octagon"></i> Cancelled Orders</span>
        <span class="table-count"><%= cancelledCount %> cancelled</span>
      </div>
      <div class="table-responsive">
        <table id="cancelTable">
          <thead><tr><th>Order #</th><th>Customer</th><th>Payment</th><th>Order Date</th><th>Amount</th><th>Status</th><th>Manage</th></tr></thead>
          <tbody>
          <% for (Order order : orders) {
               if (!"Cancelled".equalsIgnoreCase(order.getStatus())) continue;
               boolean isCod=("PENDING_COD".equalsIgnoreCase(order.getPaymentStatus()));
               boolean isPaid=("PAID".equalsIgnoreCase(order.getPaymentStatus()));
               boolean isRefunded=("REFUNDED".equalsIgnoreCase(order.getPaymentStatus()));
               com.util.OrderReturn rr=order.getReturnRequest();
               boolean isReturnExists=(rr!=null);
               String rrStatus=isReturnExists?(rr.getStatus()!=null?rr.getStatus():""):"";
               String safeTxn=(order.getTransactionId()!=null)?order.getTransactionId():"";
               boolean canRefund=isPaid&&isReturnExists&&"Pending Refund".equals(rrStatus);
               double refundableAmount=(isReturnExists&&rr.getRefundAmount()>0)?rr.getRefundAmount():order.getTotalAmount();
               boolean hasPaymentId=safeTxn!=null&&!safeTxn.isEmpty();
               String existingRefundMethod=isReturnExists&&rr.getRefundMethod()!=null?rr.getRefundMethod():"wallet";
               String safeEmail=(order.getCustomerEmail()!=null)?order.getCustomerEmail():"";
          %>
          <tr data-customer="<%= order.getCustomerName()!=null?order.getCustomerName().toLowerCase():"" %>" data-orderid="<%= order.getId() %>">
            <td><span class="order-id-chip">#<%= order.getId() %></span></td>
            <td><div class="cust-info-primary"><%= order.getCustomerName()!=null?order.getCustomerName():"—" %></div><div class="cust-info-email"><%= safeEmail %></div></td>
            <td><%if(isCod){%><span class="pay-pill pay-cod"><i class="bi bi-cash-coin"></i> COD</span><%}else if(isPaid){%><span class="pay-pill pay-paid"><i class="bi bi-credit-card-2-back"></i> Online</span><%}else if(isRefunded){%><span class="pay-pill pay-refunded"><i class="bi bi-arrow-counterclockwise"></i> Refunded</span><%}else{%><span class="pay-pill pay-unknown"><%= order.getPaymentStatus()!=null?order.getPaymentStatus():"—" %></span><%}%></td>
            <td style="font-size:.78rem;color:var(--text-mid);"><%= order.getDate()!=null?new java.text.SimpleDateFormat("dd MMM yy").format(order.getDate()):"—" %></td>
            <td style="font-weight:700;color:var(--danger);font-family:monospace;">₹<%= String.format("%.2f",order.getTotalAmount()) %></td>
            <td>
              <span class="status-badge s-cancelled"><i class="bi bi-dot"></i> Cancelled</span>
              <%if(isRefunded){%><br><span class="status-badge s-refunded" style="margin-top:3px;"><i class="bi bi-check-circle"></i> Refunded</span><%}%>
            </td>
            <td>
              <div class="action-col">
                <a href="OrdersDashboard?action=view&orderId=<%= order.getId() %>" class="btn-tbl btn-invoice"><i class="bi bi-file-earmark-text"></i> Invoice</a>
                <%if(canRefund&&!isRefunded){%><button class="btn-tbl btn-refund" type="button" onclick="openRefundModal('<%= order.getId() %>','<%= safeTxn %>','<%= String.format("%.2f",refundableAmount) %>','<%= String.format("%.2f",order.getTotalAmount()) %>','<%= existingRefundMethod %>','<%= hasPaymentId %>')"><i class="bi bi-arrow-counterclockwise"></i> Refund ₹<%= String.format("%.0f",refundableAmount) %></button><%}%>
                <%if("DEPOSITED".equalsIgnoreCase(order.getPaymentStatus())){%><span class="deposited-badge"><i class="bi bi-check-circle-fill"></i> Cash Deposited</span><%}%>
              </div>
            </td>
          </tr>
          <% } %>
          </tbody>
        </table>
      </div>
    </div>
  </div><!-- /#tab-cancellations -->
  <% } %>

  <!-- ══ TAB: RETURNS ══ -->
  <% if (returnCount > 0) { %>
  <div class="tab-pane fade-up" id="tab-returns">
    <div class="table-card">
      <div class="table-card-header">
        <span class="table-card-title"><i class="bi bi-arrow-return-left"></i> Return &amp; Refund Orders</span>
        <span class="table-count"><%= returnCount %> returns</span>
      </div>
      <div class="table-responsive">
        <table>
          <thead><tr><th>Order #</th><th>Customer</th><th>Return Status</th><th>Type</th><th>Amount</th><th>Agent</th><th>Manage</th></tr></thead>
          <tbody>
          <% for (Order order : orders) {
               String st=order.getStatus()!=null?order.getStatus():"";
               if (!st.startsWith("Return")&&!"Refunded".equals(st)&&!"Replaced".equals(st)&&!"Processing".equals(st)) continue;
               com.util.OrderReturn rr=order.getReturnRequest();
               boolean isReturnExists=(rr!=null);
               String rrType=isReturnExists?(rr.getType()!=null?rr.getType():"Return"):"Return";
               String rrReason=isReturnExists&&rr.getReason()!=null?rr.getReason().replace("'","&#39;"):"N/A";
               String rrPhotos=(isReturnExists&&rr.getPhotos()!=null)?rr.getPhotos().replace("\\",""):"";
               String rrStatus=isReturnExists?(rr.getStatus()!=null?rr.getStatus():""):"";
               String bName=(isReturnExists&&rr.getBankName()!=null)?rr.getBankName():"";
               String bAcc=(isReturnExists&&rr.getBankAccount()!=null)?rr.getBankAccount():"";
               String bIfsc=(isReturnExists&&rr.getBankIfsc()!=null)?rr.getBankIfsc():"";
               String safeTxn=(order.getTransactionId()!=null)?order.getTransactionId():"";
               String safeName=(order.getCustomerName()!=null)?order.getCustomerName().replace("'","&#39;"):"Unknown";
               String safeEmail=(order.getCustomerEmail()!=null)?order.getCustomerEmail():"";
               String statusCss;
               switch(st){
                 case "Return Requested":case "Return Approved":case "Return Agent Assigned":case "Return Out for Pickup":case "Return Picked":statusCss="s-return";break;
                 case "Processing":statusCss="s-processing";break;
                 case "Refunded":statusCss="s-refunded";break;case "Replaced":statusCss="s-replaced";break;
                 default:statusCss="s-return";break;
               }
               String btnLabel=null,btnIcon=null,btnCssClass="btn-tbl btn-update";
               switch(st){
                 case "Return Requested":btnLabel=isReturnExists?"View "+rrType:"Handle Return";btnIcon="bi-arrow-return-left";btnCssClass="btn-tbl btn-return";break;
                 case "Return Approved":btnLabel="Assign Pickup Agent";btnIcon="bi-person-badge";btnCssClass="btn-tbl btn-assign";break;
                 case "Return Agent Assigned":btnLabel="Agent Out for Pickup";btnIcon="bi-bicycle";break;
                 case "Return Out for Pickup":btnLabel="Confirm Item Picked";btnIcon="bi-box-arrow-in-down";btnCssClass="btn-tbl btn-success";break;
                 case "Return Picked":btnLabel="Process Refund";btnIcon="bi-arrow-counterclockwise";btnCssClass="btn-tbl btn-refund";break;
                 default:btnLabel=null;break;
               }
          %>
          <tr class="row-return">
            <td><span class="order-id-chip">#<%= order.getId() %></span></td>
            <td><div class="cust-info-primary"><%= order.getCustomerName()!=null?order.getCustomerName():"—" %></div><div class="cust-info-email"><%= safeEmail %></div></td>
            <td><span class="status-badge <%= statusCss %>"><i class="bi bi-dot"></i> <%= st %></span></td>
            <td><span style="font-size:.78rem;font-weight:600;color:var(--purple);"><%= rrType %></span></td>
            <td style="font-weight:700;color:var(--text);font-family:monospace;">₹<%= String.format("%.2f",order.getTotalAmount()) %></td>
            <td><%if(order.getDeliveryUserName()!=null&&!order.getDeliveryUserName().isEmpty()){%><span style="font-size:.8rem;font-weight:600;"><%= order.getDeliveryUserName() %></span><%}else{%><span style="color:var(--text-soft);font-size:.75rem;">None</span><%}%></td>
            <td>
              <div class="action-col">
                <a href="OrdersDashboard?action=view&orderId=<%= order.getId() %>" class="btn-tbl btn-invoice"><i class="bi bi-file-earmark-text"></i> Invoice</a>
                <%if(btnLabel!=null){%>
                  <%if("Return Agent Assigned".equalsIgnoreCase(st)){%>
                  <button class="<%= btnCssClass %>" onclick="postAction('agentOutForPickup','<%= order.getId() %>','Mark agent out for pickup?')"><i class="bi <%= btnIcon %>"></i> <%= btnLabel %></button>
                  <%}else if("Return Out for Pickup".equalsIgnoreCase(st)){%>
                  <button class="<%= btnCssClass %>" onclick="postAction('confirmPickup','<%= order.getId() %>','Confirm item picked?')"><i class="bi <%= btnIcon %>"></i> <%= btnLabel %></button>
                  <%}else{%>
                  <button class="<%= btnCssClass %>" onclick="openReturnModal('<%= order.getId() %>','<%= safeName %>','<%= safeEmail %>','<%= String.format("%.2f",order.getTotalAmount()) %>','<%= st %>','<%= safeTxn %>','<%= rrType %>','<%= rrReason %>','<%= rrPhotos %>','<%= bName %>','<%= bAcc %>','<%= bIfsc %>','<%= rrStatus %>')"><i class="bi <%= btnIcon %>"></i> <%= btnLabel %></button>
                  <%}%>
                <%}%>
              </div>
            </td>
          </tr>
          <% } %>
          </tbody>
        </table>
      </div>
    </div>
  </div><!-- /#tab-returns -->
  <% } %>

</main>

<!-- ══ ASSIGN DELIVERY MODAL ══ -->
<div class="modal fade" id="assignModal" tabindex="-1" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered modal-lg">
    <div class="modal-content">
      <div class="modal-header mh-info">
        <div class="modal-title"><i class="bi bi-person-badge"></i> Assign Delivery Agent</div>
        <button type="button" class="btn-close-custom" data-bs-dismiss="modal"><i class="bi bi-x"></i></button>
      </div>
      <div class="modal-body">
        <p style="font-size:.82rem;color:var(--text-soft);margin-bottom:1rem;">Order <strong id="assign-order-id" style="color:var(--accent);font-family:monospace;"></strong> — Customer: <strong id="assign-customer-name" style="color:var(--text);"></strong></p>
        <div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(220px,1fr));gap:.75rem;" id="dpList">
          <% for (User dp : deliveryPersons) {
               int activeOrders=dp.getPendingOrdersCount();
               boolean isBusy=activeOrders>0;
          %>
          <label class="dp-chip <%= isBusy?"dp-chip-busy":"" %>" for="dp_<%= dp.getUid() %>" style="<%= isBusy?"opacity:.5;cursor:not-allowed;":"" %>">
            <input type="radio" name="selectedDp" id="dp_<%= dp.getUid() %>" value="<%= dp.getUid() %>" <%= isBusy?"disabled":"" %> style="display:none;" onchange="document.querySelectorAll('.dp-chip').forEach(c=>c.classList.remove('selected'));this.closest('.dp-chip').classList.add('selected');">
            <div class="dp-avatar"><%= String.valueOf(dp.getUsername().charAt(0)).toUpperCase() %></div>
            <div>
              <div class="dp-name"><%= dp.getUsername() %></div>
              <div class="dp-meta"><i class="bi bi-telephone"></i> <%= dp.getMobileno()!=null?dp.getMobileno():"—" %></div>
              <div class="dp-meta"><i class="bi bi-box-seam"></i> <%= dp.getPendingOrdersCount() %> tasks &nbsp;
                <%if(isBusy){%><span style="color:var(--danger);font-weight:700;"><i class="bi bi-lock"></i> Busy</span><%}else{%><span style="color:var(--success);font-weight:700;"><i class="bi bi-check-circle"></i> Available</span><%}%>
                <div style="width:8px;height:8px;border-radius:50%;margin-left:auto;background:<%= isBusy?"var(--danger)":"var(--success)" %>;"></div>
              </div>
            </div>
          </label>
          <% } %>
          <%if(deliveryPersons.isEmpty()){%><p style="font-size:.83rem;color:var(--text-soft);padding:1rem;"><i class="bi bi-person-x"></i> No delivery agents available.</p><%}%>
        </div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn-modal btn-modal-cancel" data-bs-dismiss="modal">Cancel</button>
        <button type="button" class="btn-modal btn-modal-primary" id="confirmAssignBtn"><i class="bi bi-check-circle"></i> Confirm Assignment</button>
      </div>
    </div>
  </div>
</div>

<!-- ══ RETURN & REFUND WORKFLOW MODAL ══ -->
<div class="modal fade" id="returnModal" tabindex="-1" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered modal-lg">
    <div class="modal-content">
      <div class="modal-header mh-warning">
        <div class="modal-title"><i class="bi bi-arrow-return-left"></i> Return &amp; Refund Workflow</div>
        <button type="button" class="btn-close-custom" data-bs-dismiss="modal"><i class="bi bi-x"></i></button>
      </div>
      <div class="modal-body">
        <div class="refund-info-row" style="margin-bottom:1.25rem;">
          <div><div class="ri-label">Order</div><div class="ri-val" id="ret-order-id" style="color:var(--accent);font-family:monospace;"></div></div>
          <div><div class="ri-label">Customer</div><div class="ri-val" id="ret-customer"></div></div>
          <div><div class="ri-label">Email</div><div class="ri-val" id="ret-email" style="font-size:.78rem;color:var(--text-mid);"></div></div>
          <div><div class="ri-label">Amount</div><div class="ri-val" id="ret-amount" style="color:var(--success);"></div></div>
          <div><div class="ri-label">Type</div><div class="ri-val" id="ret-type" style="color:var(--purple);"></div></div>
          <div><div class="ri-label">Status</div><div id="ret-status-badge"></div></div>
        </div>
        <div id="ret-customer-proof" style="margin-bottom:1.25rem;display:none;">
          <label class="form-label-sm">Customer Proof &amp; Photos</label>
          <div id="ret-photo-gallery" style="display:flex;gap:10px;margin-top:6px;flex-wrap:wrap;"></div>
          <div style="background:var(--gold-bg);border:1px solid rgba(245,158,11,.25);padding:8px 12px;border-radius:8px;margin-top:8px;font-size:.82rem;color:var(--gold);">
            <strong style="display:block;margin-bottom:2px;"><i class="bi bi-chat-left-quote"></i> Customer Note</strong>
            <span id="ret-cust-note" style="color:var(--text-mid);"></span>
          </div>
        </div>
        <div style="display:flex;flex-direction:column;gap:.5rem;">
          <!-- Step 1 -->
          <div class="return-step" id="ret-step-1"><div class="rs-num" id="rs-num-1">1</div>
            <div style="flex:1;"><div class="rs-title">Verify Return Request</div><div class="rs-detail">Review the customer's reason and proof. Approve or reject.</div>
              <div id="ret-step1-controls" style="margin-top:.75rem;display:none;">
                <label class="form-label-sm">Return Reason</label>
                <select class="form-control-sm-custom" id="returnReasonSelect" style="margin-bottom:.6rem;">
                  <option value="">— Select Reason —</option>
                  <option value="damaged">Item Damaged in Transit</option><option value="wrong_item">Wrong Item Delivered</option>
                  <option value="not_as_described">Not as Described</option><option value="defective">Item Defective</option>
                  <option value="customer_change">Customer Changed Mind</option><option value="other">Other</option>
                </select>
                <label class="form-label-sm">Staff Notes</label>
                <textarea class="form-control-sm-custom" id="returnNotes" rows="2" placeholder="Verification notes…" style="margin-bottom:.75rem;"></textarea>
                <div style="display:flex;gap:.5rem;">
                  <button class="btn-modal btn-modal-success" onclick="approveReturn()"><i class="bi bi-check-circle"></i> Approve Return</button>
                  <button class="btn-modal btn-modal-danger" onclick="rejectReturn()"><i class="bi bi-x-circle"></i> Reject</button>
                </div>
              </div>
            </div>
          </div>
          <!-- Step 2 -->
          <div class="return-step" id="ret-step-2"><div class="rs-num" id="rs-num-2">2</div>
            <div style="flex:1;"><div class="rs-title">Assign Pickup Agent</div><div class="rs-detail">Select an agent to collect the item from the customer.</div>
              <div id="ret-step2-controls" style="margin-top:.75rem;display:none;">
                <select class="form-control-sm-custom" id="pickupAgentSelect" style="margin-bottom:.75rem;">
                  <option value="">— Select Agent —</option>
                  <% for (User dp : deliveryPersons) { %><option value="<%= dp.getUid() %>"><%= dp.getUsername() %><%= dp.getMobileno()!=null?" — "+dp.getMobileno():"" %> (<%= dp.getPendingOrdersCount() %> tasks)</option><% } %>
                </select>
                <button class="btn-modal btn-modal-primary" onclick="assignPickupAgent()"><i class="bi bi-person-badge"></i> Assign Pickup Agent</button>
              </div>
            </div>
          </div>
          <!-- Step 3 -->
          <div class="return-step" id="ret-step-3"><div class="rs-num" id="rs-num-3">3</div>
            <div style="flex:1;"><div class="rs-title">Process Refund / Replacement</div><div class="rs-detail">Item received. Choose refund method or confirm replacement.</div>
              <div id="ret-step3-controls" style="margin-top:.75rem;display:none;">
                <label class="form-label-sm">Restock Qty</label>
                <input type="number" class="form-control-sm-custom" id="restockQtyInput" min="0" value="1" style="margin-bottom:.6rem;width:120px;">
                <label class="form-label-sm">Refund Amount (₹)</label>
                <input type="number" class="form-control-sm-custom" id="refundAmountInput" min="0" step="0.01" style="margin-bottom:.6rem;width:160px;">
                <label class="form-label-sm">Refund Method</label>
                <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:.5rem;margin-bottom:.75rem;">
                  <div class="refund-method-card" onclick="selectRefundMethod('wallet',this)"><div class="rm-icon" style="background:var(--success-bg);color:var(--success);"><i class="bi bi-wallet2"></i></div><div><div style="font-size:.8rem;font-weight:700;">Wallet</div><div style="font-size:.68rem;color:var(--text-soft);">Instant</div></div><input type="radio" name="refundMethodPick" value="wallet" style="display:none;"></div>
                  <div class="refund-method-card" onclick="selectRefundMethod('original',this)"><div class="rm-icon" style="background:var(--accent-light);color:var(--accent);"><i class="bi bi-credit-card"></i></div><div><div style="font-size:.8rem;font-weight:700;">Original</div><div style="font-size:.68rem;color:var(--text-soft);">Razorpay</div></div><input type="radio" name="refundMethodPick" value="original" style="display:none;"></div>
                  <div class="refund-method-card" onclick="selectRefundMethod('bank',this)"><div class="rm-icon" style="background:var(--sky-bg);color:var(--sky);"><i class="bi bi-bank"></i></div><div><div style="font-size:.8rem;font-weight:700;">Bank</div><div style="font-size:.68rem;color:var(--text-soft);">Manual</div></div><input type="radio" name="refundMethodPick" value="bank" style="display:none;"></div>
                </div>
                <div id="bankDetailsSection" style="display:none;background:var(--bg);border:1px solid var(--border);border-radius:10px;padding:.85rem;margin-bottom:.75rem;">
                  <div style="font-size:.73rem;font-weight:700;color:var(--text-soft);text-transform:uppercase;letter-spacing:1px;margin-bottom:.6rem;"><i class="bi bi-bank"></i> Bank Details from Customer</div>
                  <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:.5rem;font-size:.8rem;">
                    <div><span style="color:var(--text-soft);">Name</span><br><strong id="bd-name">—</strong></div>
                    <div><span style="color:var(--text-soft);">Account</span><br><strong id="bd-acc">—</strong></div>
                    <div><span style="color:var(--text-soft);">IFSC</span><br><strong id="bd-ifsc">—</strong></div>
                  </div>
                </div>
                <div style="display:flex;gap:.5rem;">
                  <button class="btn-modal btn-modal-success" onclick="processReturnRefundAction()"><i class="bi bi-check2-circle"></i> Confirm Refund</button>
                  <button class="btn-modal btn-modal-warning" onclick="processReplacementAction()"><i class="bi bi-arrow-repeat"></i> Confirm Replacement</button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>

<!-- ══ DIRECT REFUND MODAL ══ -->
<div class="modal fade" id="refundModal" tabindex="-1" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered">
    <div class="modal-content">
      <div class="modal-header mh-purple">
        <div class="modal-title"><i class="bi bi-arrow-counterclockwise"></i> Process Refund</div>
        <button type="button" class="btn-close-custom" data-bs-dismiss="modal"><i class="bi bi-x"></i></button>
      </div>
      <div class="modal-body">
        <div class="refund-info-row" style="margin-bottom:1rem;">
          <div><div class="ri-label">Order</div><div class="ri-val" id="rm-order-id" style="color:var(--accent);font-family:monospace;"></div></div>
          <div><div class="ri-label">Order Total</div><div class="ri-val" id="rm-total" style="color:var(--text-mid);text-decoration:line-through;"></div></div>
          <div><div class="ri-label">Refund Amount</div><div class="ri-val" id="rm-amount" style="color:var(--success);font-weight:700;"></div></div>
        </div>
        <div id="rm-deduction-notice" style="display:none;background:rgba(245,158,11,.08);border:1px solid rgba(245,158,11,.25);border-radius:8px;padding:.6rem .85rem;margin-bottom:.9rem;font-size:.8rem;color:#d97706;"><i class="bi bi-info-circle"></i> <span id="rm-deduction-text"></span></div>
        <label class="form-label-sm" style="margin-bottom:.4rem;">Refund Destination</label>
        <div style="display:grid;grid-template-columns:1fr 1fr;gap:.5rem;margin-bottom:.9rem;">
          <div class="refund-method-card selected" id="rm-wallet-card" onclick="selectDirectRefundMethod('wallet')"><div class="rm-icon" style="background:var(--success-bg);color:var(--success);"><i class="bi bi-wallet2"></i></div><div><div style="font-weight:600;font-size:.82rem;">Customer Wallet</div><div style="font-size:.73rem;color:var(--text-soft);">Instant credit</div></div><input type="radio" name="directRefundMethod" value="wallet" checked style="display:none;"></div>
          <div class="refund-method-card" id="rm-original-card" onclick="selectDirectRefundMethod('original')"><div class="rm-icon" style="background:var(--accent-light);color:var(--accent);"><i class="bi bi-credit-card-2-back"></i></div><div><div style="font-weight:600;font-size:.82rem;">Original Payment</div><div style="font-size:.73rem;color:var(--text-soft);">3–5 business days</div></div><input type="radio" name="directRefundMethod" value="original" style="display:none;"></div>
        </div>
        <div id="rm-no-payment-id-warn" style="display:none;font-size:.77rem;color:var(--text-soft);margin-bottom:.7rem;"><i class="bi bi-exclamation-triangle" style="color:#d97706;"></i> No payment ID on record — wallet is recommended.</div>
        <label class="form-label-sm">Reason for Refund</label>
        <select class="form-control-sm-custom" id="refundReason" style="margin-bottom:.75rem;">
          <option value="">— Select reason —</option>
          <option value="customer_cancelled">Customer Cancelled</option><option value="item_unavailable">Item Unavailable</option>
          <option value="order_error">Order Error</option><option value="duplicate_order">Duplicate Order</option><option value="other">Other</option>
        </select>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn-modal btn-modal-cancel" data-bs-dismiss="modal">Close</button>
        <button type="button" class="btn-modal btn-modal-primary" id="confirmRefundBtn"><i class="bi bi-arrow-counterclockwise"></i> Confirm Refund</button>
      </div>
    </div>
  </div>
</div>

<!-- ══ REFUND SUCCESS MODAL ══ -->
<div class="modal fade" id="refundSuccessModal" tabindex="-1" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered"><div class="modal-content">
    <div class="modal-header mh-success"><div class="modal-title"><i class="bi bi-check-circle"></i> Refund Initiated</div><button type="button" class="btn-close-custom" data-bs-dismiss="modal"><i class="bi bi-x"></i></button></div>
    <div class="modal-body" style="text-align:center;padding:2rem;">
      <div style="width:64px;height:64px;border-radius:50%;background:var(--success-bg);border:2px solid rgba(16,185,129,.3);display:flex;align-items:center;justify-content:center;font-size:1.8rem;margin:0 auto 1rem;color:var(--success);"><i class="bi bi-check-circle-fill"></i></div>
      <h5 style="font-size:1rem;font-weight:700;margin-bottom:.4rem;">Refund Successful</h5>
      <p style="font-size:.83rem;color:var(--text-mid);"><span id="success-refund-amount" style="font-weight:700;color:var(--success);font-family:monospace;"></span> has been queued for refund to the customer's account.</p>
    </div>
    <div class="modal-footer" style="justify-content:center;"><button type="button" class="btn-modal btn-modal-success" data-bs-dismiss="modal" onclick="location.reload()"><i class="bi bi-arrow-clockwise"></i> Refresh Page</button></div>
  </div></div>
</div>

<!-- ══ CANCEL ORDER MODAL ══ -->
<div class="modal fade" id="cancelOrderModal" tabindex="-1" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered"><div class="modal-content">
    <div class="modal-header mh-danger"><div class="modal-title"><i class="bi bi-x-circle"></i> Cancel Order</div><button type="button" class="btn-close-custom" data-bs-dismiss="modal"><i class="bi bi-x"></i></button></div>
    <div class="modal-body">
      <p style="font-size:.82rem;color:var(--text-soft);margin-bottom:1rem;">Order <strong id="cancel-order-id" style="color:var(--danger);font-family:monospace;"></strong> — <strong id="cancel-customer-name"></strong><span style="display:block;font-size:.75rem;margin-top:3px;color:var(--text-soft);">Stage: <strong id="cancel-order-stage" style="color:var(--text);"></strong></span></p>
      <label class="form-label-sm">Cancellation Reason <span style="color:var(--danger);">*</span></label>
      <select class="form-control-sm-custom" id="cancelReason" style="margin-bottom:.75rem;">
        <option value="">— Select Reason —</option>
        <option value="customer_request">Customer Requested</option><option value="item_unavailable">Item Out of Stock</option>
        <option value="payment_issue">Payment Not Cleared</option><option value="fraud_suspicion">Suspected Fraud</option>
        <option value="duplicate_order">Duplicate Order</option><option value="other">Other</option>
      </select>
      <label class="form-label-sm">Staff Note</label>
      <textarea class="form-control-sm-custom" id="cancelNote" rows="2" placeholder="Additional note…" style="margin-bottom:.75rem;"></textarea>
      <div style="background:var(--warning-bg);border:1px solid rgba(251,146,60,.25);border-radius:8px;padding:.65rem .9rem;font-size:.78rem;color:var(--warning);"><i class="bi bi-exclamation-triangle-fill"></i> Paid orders will receive an automatic wallet refund (minus applicable deductions).</div>
    </div>
    <div class="modal-footer">
      <button type="button" class="btn-modal btn-modal-cancel" data-bs-dismiss="modal">Keep Order</button>
      <button type="button" class="btn-modal btn-modal-danger" id="confirmCancelBtn"><i class="bi bi-x-circle"></i> Cancel Order</button>
    </div>
  </div></div>
</div>

<!-- ══ COD DEPOSIT MODAL ══ -->
<div class="modal fade" id="codDepositModal" tabindex="-1" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered"><div class="modal-content">
    <div class="modal-header mh-warning"><div class="modal-title"><i class="bi bi-cash-coin"></i> Confirm Cash Deposit</div><button type="button" class="btn-close-custom" data-bs-dismiss="modal"><i class="bi bi-x"></i></button></div>
    <div class="modal-body">
      <div class="cod-info-grid">
        <div class="cod-info-item"><div class="ci-label">Order #</div><div class="ci-val" id="cdOrderId">&#8212;</div></div>
        <div class="cod-info-item"><div class="ci-label">Agent</div><div class="ci-val" id="cdAgentName">&#8212;</div></div>
        <div class="cod-info-item"><div class="ci-label">COD Amount</div><div class="ci-val" id="cdOrderAmount" style="color:var(--success);font-family:monospace;">&#8212;</div></div>
        <div class="cod-info-item"><div class="ci-label">Status</div><div class="ci-val" style="color:var(--gold);">Pending deposit</div></div>
      </div>
      <div style="margin-bottom:.75rem;"><label class="form-label-sm">Confirm Amount Received (&#8377;)</label><input type="number" id="cdAmountInput" class="form-control-sm-custom" step="0.01" min="0.01" placeholder="Enter amount received"></div>
      <div><label class="form-label-sm">Notes (optional)</label><input type="text" id="cdNotesInput" class="form-control-sm-custom" placeholder="Any remarks about this deposit"></div>
      <div id="cdError" style="display:none;margin-top:.75rem;padding:.6rem .85rem;background:var(--danger-bg);border:1px solid rgba(244,63,94,.3);border-radius:8px;font-size:.8rem;color:var(--danger);"></div>
    </div>
    <div class="modal-footer">
      <button type="button" class="btn-modal btn-modal-cancel" data-bs-dismiss="modal">Cancel</button>
      <button type="button" class="btn-modal btn-modal-success" id="confirmDepositBtn" onclick="submitCodDeposit()"><i class="bi bi-check-circle"></i> Confirm Receipt</button>
    </div>
  </div></div>
</div>

<!-- ══ REJECTION DETAIL MODAL ══ -->
<div class="modal fade" id="rejectionDetailModal" tabindex="-1" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered modal-lg"><div class="modal-content">
    <div class="modal-header mh-danger"><div class="modal-title"><i class="bi bi-slash-circle"></i> Rejection Log — <span id="rej-modal-agent-name"></span></div><button type="button" class="btn-close-custom" data-bs-dismiss="modal"><i class="bi bi-x"></i></button></div>
    <div class="modal-body"><div id="rej-modal-log-body" style="max-height:60vh;overflow-y:auto;"></div></div>
    <div class="modal-footer">
      <div id="rej-modal-agent-id" data-agentid=""></div>
      <button type="button" class="btn-modal btn-modal-cancel" data-bs-dismiss="modal">Close</button>
      <button type="button" class="btn-modal btn-modal-success" onclick="reviewRejection(document.getElementById('rej-modal-agent-id').dataset.agentid,document.getElementById('rej-modal-agent-name').textContent,'accept')"><i class="bi bi-check-circle"></i> Accept Reason &amp; Clear Log</button>
      <button type="button" class="btn-modal btn-modal-warning" onclick="reviewRejection(document.getElementById('rej-modal-agent-id').dataset.agentid,document.getElementById('rej-modal-agent-name').textContent,'dismiss')"><i class="bi bi-exclamation-triangle"></i> Dismiss</button>
      <button type="button" class="btn-modal" style="background:transparent;border-color:rgba(16,185,129,.3);color:var(--success);" onclick="bootstrap.Modal.getInstance(document.getElementById('rejectionDetailModal')).hide();unblockAgent(document.getElementById('rej-modal-agent-id').dataset.agentid,document.getElementById('rej-modal-agent-name').textContent)"><i class="bi bi-unlock"></i> Unblock Agent</button>
    </div>
  </div></div>
</div>

<!-- ══ TOAST ══ -->
<div class="toast-container position-fixed bottom-0 end-0 p-3">
  <div id="mainToast" class="toast align-items-center text-white border-0" role="alert">
    <div class="d-flex"><div class="toast-body" id="mainToastMsg"></div><button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button></div>
  </div>
</div>

<!-- Bottom Nav -->
<nav class="bottom-nav">
  <a href="UserDashboardServlet" class="bnav-item"><i class="bi bi-grid-fill"></i>Home</a>
  <a href="OrdersDashboard" class="bnav-item active"><i class="bi bi-bag-check"></i>Orders</a>
  <a href="ProductServlet?action=stock" class="bnav-item"><i class="bi bi-box-seam"></i>Stock</a>
  <a href="StaffNotifications" class="bnav-item">
    <i class="bi bi-bell"></i>
    <% if (unreadNotifCount > 0) { %><span class="bnav-badge"><%= unreadNotifCount %></span><% } %>
    Alerts
  </a>
  <a href="profile" class="bnav-item"><i class="bi bi-person-circle"></i>Profile</a>
</nav>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
<script>
/* ── SIDEBAR TOGGLE (fixed) ── */
const sidebar        = document.getElementById('sidebar');
const sidebarOverlay = document.getElementById('sidebar-overlay');
const mainContent    = document.getElementById('mainContent');
const hamburgerBtn   = document.getElementById('hamburger-btn');

function toggleSidebar() {
  const isMobile = window.innerWidth < 768;
  if (isMobile) {
    sidebar.classList.toggle('open');
    sidebarOverlay.classList.toggle('open');
  } else {
    sidebar.classList.toggle('collapsed');
    mainContent.classList.toggle('expanded');
    localStorage.setItem('sidebar-state', sidebar.classList.contains('collapsed') ? 'closed' : 'open');
  }
}

hamburgerBtn.addEventListener('click', toggleSidebar);
sidebarOverlay.addEventListener('click', function() {
  sidebar.classList.remove('open');
  sidebarOverlay.classList.remove('open');
});

window.addEventListener('DOMContentLoaded', function() {
  // Restore sidebar state on desktop
  if (window.innerWidth >= 768 && localStorage.getItem('sidebar-state') === 'closed') {
    sidebar.classList.add('collapsed');
    mainContent.classList.add('expanded');
  }
  // Animate progress bars
  document.querySelectorAll('.progress-fill').forEach(function(bar) {
    const w = bar.getAttribute('data-width') || '0';
    setTimeout(function() { bar.style.width = w + '%'; }, 300);
  });
});

/* ── TAB SWITCHING ── */
function switchTab(tabId, btn) {
  // Hide all panes
  document.querySelectorAll('.tab-pane').forEach(function(p) { p.classList.remove('active'); });
  // Deactivate all buttons
  document.querySelectorAll('.tab-btn').forEach(function(b) { b.classList.remove('active'); });
  // Show target
  var pane = document.getElementById('tab-' + tabId);
  if (pane) pane.classList.add('active');
  if (btn) btn.classList.add('active');
}

/* ── SEARCH & FILTER ── */
const searchInput  = document.getElementById('searchInput');
const statusFilter = document.getElementById('statusFilter');
const payFilter    = document.getElementById('payFilter');
const visibleCount = document.getElementById('visibleCount');

function filterTable() {
  if (!searchInput) return;
  const q      = searchInput.value.toLowerCase().trim();
  const status = statusFilter.value.toLowerCase();
  const pay    = payFilter.value;
  const rows   = document.querySelectorAll('#ordersTable tbody tr[data-orderid]');
  let visible  = 0;
  rows.forEach(function(row) {
    const customer = (row.dataset.customer || '').toLowerCase();
    const email    = (row.dataset.email    || '').toLowerCase();
    const orderId  = (row.dataset.orderid  || '').toLowerCase();
    const rowStat  = (row.dataset.status   || '').toLowerCase();
    const rowPay   = (row.dataset.pay      || '').toLowerCase();
    const matchQ   = !q || customer.includes(q) || email.includes(q) || orderId.includes(q);
    let matchStat;
    if      (status === 'all')    matchStat = true;
    else if (status === 'return') matchStat = rowStat.startsWith('return') || rowStat === 'refunded' || rowStat === 'replaced' || rowStat === 'processing';
    else                          matchStat = rowStat.includes(status);
    const matchPay = pay === 'all' || rowPay === pay;
    const show = matchQ && matchStat && matchPay;
    row.style.display = show ? '' : 'none';
    if (show) visible++;
  });
  if (visibleCount) visibleCount.textContent = visible;
}

if (searchInput) {
  searchInput.addEventListener('input', filterTable);
  statusFilter.addEventListener('change', filterTable);
  payFilter.addEventListener('change', filterTable);
}

// Cancel tab search
var cancelSearchInput = document.getElementById('cancelSearchInput');
if (cancelSearchInput) {
  cancelSearchInput.addEventListener('input', function() {
    var q = this.value.toLowerCase().trim();
    document.querySelectorAll('#cancelTable tbody tr').forEach(function(row) {
      var customer = (row.dataset.customer || '').toLowerCase();
      var orderId  = (row.dataset.orderid  || '').toLowerCase();
      row.style.display = (!q || customer.includes(q) || orderId.includes(q)) ? '' : 'none';
    });
  });
}

/* ── ASSIGN MODAL ── */
let assignOrderId = null;
function openAssignModal(orderId, customerName) {
  assignOrderId = orderId;
  document.getElementById('assign-order-id').textContent      = '#' + orderId;
  document.getElementById('assign-customer-name').textContent = customerName;
  document.querySelectorAll('.dp-chip').forEach(function(c) { c.classList.remove('selected'); });
  document.querySelectorAll('[name="selectedDp"]').forEach(function(r) { r.checked = false; });
  new bootstrap.Modal(document.getElementById('assignModal')).show();
}

document.getElementById('confirmAssignBtn').addEventListener('click', function() {
  var selected = document.querySelector('[name="selectedDp"]:checked');
  if (!selected) { showToast('Please select a delivery agent.', 'warning'); return; }
  var btn = this; btn.disabled = true; btn.innerHTML = '<i class="bi bi-hourglass-split"></i> Assigning…';
  var params = new URLSearchParams();
  params.append('orderId', assignOrderId);
  params.append('deliveryPersonId', selected.value);
  fetch('AssignDeliveryServlet', { method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded','X-Requested-With':'XMLHttpRequest'}, body:params.toString() })
    .then(function(res){return res.json();})
    .then(function(data){
      if(data.success){bootstrap.Modal.getInstance(document.getElementById('assignModal')).hide();showToast('Delivery agent assigned. Order status → Assigned.','success');setTimeout(function(){location.reload();},1500);}
      else{showToast('Error: '+(data.message||'Assignment failed.'),'danger');}
    }).catch(function(){showToast('Network error.','danger');})
    .finally(function(){btn.disabled=false;btn.innerHTML='<i class="bi bi-check-circle"></i> Confirm Assignment';});
});

/* ── QUICK ACTION ── */
function postAction(action, orderId, confirmMsg) {
  if (!confirm(confirmMsg)) return;
  var params = new URLSearchParams();
  params.append('action', action); params.append('orderId', orderId);
  fetch('OrdersDashboard', {method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded','X-Requested-With':'XMLHttpRequest'},body:params.toString()})
    .then(function(r){return r.json();})
    .then(function(data){
      if(data.success){showToast(data.message||'Updated successfully.','success');setTimeout(function(){location.reload();},1500);}
      else{showToast('Error: '+(data.message||'Action failed.'),'danger');}
    }).catch(function(){showToast('Network error.','danger');});
}

/* ── RETURN MODAL ── */
var returnOrderId=null,returnOrderAmt=null,returnTxnId=null,returnCurrStatus=null,selectedRefundMethod=null;

function openReturnModal(orderId,customer,email,amount,currentStatus,txnId,rrType,rrReason,rrPhotos,bName,bAcc,bIfsc,rrStatus){
  returnOrderId=orderId; returnOrderAmt=amount; returnTxnId=txnId; returnCurrStatus=currentStatus;
  document.getElementById('ret-order-id').textContent='#'+orderId;
  document.getElementById('ret-customer').textContent=customer;
  document.getElementById('ret-email').textContent=email;
  document.getElementById('ret-amount').textContent='₹'+amount;
  document.getElementById('ret-type').textContent=rrType||'Return';
  var sb=document.getElementById('ret-status-badge');
  var statusMap={'Return Requested':['s-return',rrStatus||currentStatus],'Return Approved':['s-assigned','Approved'],'Return Agent Assigned':['s-assigned','Agent Assigned'],'Return Out for Pickup':['s-ofd','Out for Pickup'],'Return Picked':['s-shipped','Picked'],'Refunded':['s-refunded','Refunded']};
  var arr=statusMap[currentStatus]||['s-pending',currentStatus];
  sb.innerHTML='<span class="status-badge '+arr[0]+'"><i class="bi bi-dot"></i> '+arr[1]+'</span>';
  var proofDiv=document.getElementById('ret-customer-proof');
  if(rrReason&&rrReason!=='N/A'){document.getElementById('ret-cust-note').textContent=rrReason;proofDiv.style.display='block';}else{proofDiv.style.display='none';}
  var gallery=document.getElementById('ret-photo-gallery');gallery.innerHTML='';
  if(rrPhotos){rrPhotos.split(',').filter(function(p){return p.trim();}).forEach(function(p){var img=document.createElement('img');img.src=p.trim();img.className='photo-thumb';img.onclick=function(){window.open(p.trim(),'_blank');};gallery.appendChild(img);});}
  document.getElementById('bd-name').textContent=bName||'—';
  document.getElementById('bd-acc').textContent=bAcc||'—';
  document.getElementById('bd-ifsc').textContent=bIfsc||'—';
  document.getElementById('refundAmountInput').value=amount;
  resetReturnSteps();
  if(currentStatus==='Return Requested'){activateStep(1);}
  else if(currentStatus==='Return Approved'){doneStep(1);activateStep(2);}
  else if(currentStatus==='Return Picked'){doneStep(1);doneStep(2);activateStep(3);}
  new bootstrap.Modal(document.getElementById('returnModal')).show();
}

function resetReturnSteps(){[1,2,3].forEach(function(i){var step=document.getElementById('ret-step-'+i);var num=document.getElementById('rs-num-'+i);if(step){step.classList.remove('step-active','step-done');}if(num){num.classList.remove('active','done');num.textContent=i;}var ctrl=document.getElementById('ret-step'+i+'-controls');if(ctrl)ctrl.style.display='none';});}
function activateStep(i){var step=document.getElementById('ret-step-'+i);var num=document.getElementById('rs-num-'+i);var ctrl=document.getElementById('ret-step'+i+'-controls');if(step)step.classList.add('step-active');if(num)num.classList.add('active');if(ctrl)ctrl.style.display='block';}
function doneStep(i){var step=document.getElementById('ret-step-'+i);var num=document.getElementById('rs-num-'+i);if(step)step.classList.add('step-done');if(num){num.classList.add('done');num.innerHTML='<i class="bi bi-check"></i>';}}

function approveReturn(){var reason=document.getElementById('returnReasonSelect').value;var notes=document.getElementById('returnNotes').value;if(!reason){showToast('Please select a return reason.','warning');return;}postReturnAction({action:'approveReturn',orderId:returnOrderId,reason:reason,notes:notes},'Return approved.');}
function rejectReturn(){if(!confirm('Reject this return request?'))return;postReturnAction({action:'rejectReturn',orderId:returnOrderId},'Return rejected.');}
function assignPickupAgent(){
	var agentId=document.getElementById('pickupAgentSelect').value;
	if(!agentId){showToast('Please select an agent.','warning');
	return;
	}
	postReturnAction({action:'assignPickupAgent',
		orderId:returnOrderId,deliveryUserId:agentId},'Pickup agent assigned!');}
function selectRefundMethod(method,card){selectedRefundMethod=method;document.querySelectorAll('.refund-method-card').forEach(function(c){c.classList.remove('selected');});card.classList.add('selected');document.getElementById('bankDetailsSection').style.display=(method==='bank')?'block':'none';}
function processReturnRefundAction(){if(!selectedRefundMethod){showToast('Please select a refund method.','warning');return;}var restockQty=document.getElementById('restockQtyInput').value||'0';var refundAmount=document.getElementById('refundAmountInput').value||returnOrderAmt;postReturnAction({action:'processReturnRefund',orderId:returnOrderId,restockQty:restockQty,refundAmount:refundAmount,refundMethod:selectedRefundMethod,paymentId:returnTxnId||''},'Refund processed successfully!');}
function processReplacementAction(){if(!confirm('Confirm replacement for order #'+returnOrderId+'?'))return;var params=new URLSearchParams();params.append('action','processReturnRefund');params.append('orderId',returnOrderId);params.append('restockQty','0');params.append('refundAmount','0.00');params.append('refundMethod','replacement');fetch('OrdersDashboard',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded','X-Requested-With':'XMLHttpRequest'},body:params.toString()}).then(function(r){return r.json();}).then(function(data){if(data.success){bootstrap.Modal.getInstance(document.getElementById('returnModal')).hide();showToast('Replacement confirmed!','success');setTimeout(function(){location.reload();},1800);}else{showToast(data.message||'Failed.','danger');}}).catch(function(){showToast('Network error.','danger');});}
function postReturnAction(paramsObj,successMsg){var params=new URLSearchParams();Object.keys(paramsObj).forEach(function(k){params.append(k,paramsObj[k]);});fetch('OrdersDashboard',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded','X-Requested-With':'XMLHttpRequest'},body:params.toString()}).then(function(r){return r.json();}).then(function(data){if(data.success){bootstrap.Modal.getInstance(document.getElementById('returnModal')).hide();showToast(successMsg,'success');setTimeout(function(){location.reload();},1600);}else{showToast('Error: '+(data.message||'Action failed.'),'danger');}}).catch(function(){showToast('Network error.','danger');});}

/* ── DIRECT REFUND MODAL ── */
var currentOrderId,currentPaymentId,currentAmount,currentTotal,currentDirectRefundMethod;
var currentHasPaymentId=false;

function selectDirectRefundMethod(method){currentDirectRefundMethod=method;['wallet','original'].forEach(function(m){var card=document.getElementById('rm-'+m+'-card');if(card)card.classList.toggle('selected',m===method);});var warn=document.getElementById('rm-no-payment-id-warn');if(warn)warn.style.display=(method==='original'&&!currentHasPaymentId)?'block':'none';}

function openRefundModal(orderId,paymentId,refundAmt,totalAmt,defaultMethod,hasPaymentId){
  currentOrderId=orderId;currentPaymentId=paymentId;currentAmount=refundAmt;currentTotal=totalAmt;
  currentDirectRefundMethod=defaultMethod||'wallet';currentHasPaymentId=(hasPaymentId==='true'||hasPaymentId===true);
  document.getElementById('rm-order-id').textContent='#'+orderId;
  document.getElementById('rm-amount').textContent='₹'+refundAmt;
  document.getElementById('rm-total').textContent='₹'+totalAmt;
  document.getElementById('refundReason').value='';
  var deductNotice=document.getElementById('rm-deduction-notice'),deductText=document.getElementById('rm-deduction-text');
  if(parseFloat(refundAmt)<parseFloat(totalAmt)){var deducted=(parseFloat(totalAmt)-parseFloat(refundAmt)).toFixed(2);var pct=Math.round((deducted/parseFloat(totalAmt))*100);deductText.textContent='A '+pct+'% handling/shipping charge of ₹'+deducted+' was deducted. This is the net refundable amount.';deductNotice.style.display='block';}else{deductNotice.style.display='none';}
  selectDirectRefundMethod(currentDirectRefundMethod);
  var warn=document.getElementById('rm-no-payment-id-warn');if(warn)warn.style.display='none';
  new bootstrap.Modal(document.getElementById('refundModal')).show();
}

document.getElementById('confirmRefundBtn').addEventListener('click',function(){
  var reason=document.getElementById('refundReason').value;
  if(!reason){showToast('Please select a reason.','warning');return;}
  var method=currentDirectRefundMethod||'wallet';
  var btn=this;btn.disabled=true;btn.innerHTML='<i class="bi bi-hourglass-split"></i> Processing…';
  var params=new URLSearchParams();params.append('action','processRefund');params.append('orderId',currentOrderId);params.append('paymentId',currentPaymentId||'');params.append('refundAmount',currentAmount);params.append('refundMethod',method);params.append('reason',reason);
  fetch('OrdersDashboard',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded','X-Requested-With':'XMLHttpRequest'},body:params.toString()})
    .then(function(res){return res.json();})
    .then(function(data){
      if(data.success){bootstrap.Modal.getInstance(document.getElementById('refundModal')).hide();document.getElementById('success-refund-amount').textContent='₹'+currentAmount;new bootstrap.Modal(document.getElementById('refundSuccessModal')).show();}
      else{showToast('Error: '+(data.message||'Failed'),'danger');}
    }).catch(function(){showToast('Network error.','danger');})
    .finally(function(){btn.disabled=false;btn.innerHTML='<i class="bi bi-arrow-counterclockwise"></i> Confirm Refund';});
});

/* ── CANCEL ORDER MODAL ── */
var cancelStaffOrderId=null;
function openCancelOrderModal(orderId,customerName,stage){
  cancelStaffOrderId=orderId;
  document.getElementById('cancel-order-id').textContent='#'+orderId;
  document.getElementById('cancel-customer-name').textContent=customerName;
  document.getElementById('cancel-order-stage').textContent=stage;
  document.getElementById('cancelReason').value='';document.getElementById('cancelNote').value='';
  new bootstrap.Modal(document.getElementById('cancelOrderModal')).show();
}
document.getElementById('confirmCancelBtn').addEventListener('click',function(){
  var reason=document.getElementById('cancelReason').value;
  if(!reason){showToast('Please select a cancellation reason.','warning');return;}
  var note=document.getElementById('cancelNote').value;
  var btn=this;btn.disabled=true;btn.innerHTML='<i class="bi bi-hourglass-split"></i> Cancelling…';
  var params=new URLSearchParams();params.append('action','cancelOrder');params.append('orderId',cancelStaffOrderId);params.append('cancelReason',reason+(note?': '+note:''));params.append('cancelledBy','staff');params.append('refundMethod','wallet');
  fetch('OrdersDashboard',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded','X-Requested-With':'XMLHttpRequest'},body:params.toString()})
    .then(function(r){return r.json();})
    .then(function(data){
      if(data.success){bootstrap.Modal.getInstance(document.getElementById('cancelOrderModal')).hide();showToast(data.message||'Order cancelled.','success');setTimeout(function(){location.reload();},1600);}
      else{showToast('Error: '+(data.message||'Cancellation failed.'),'danger');}
    }).catch(function(){showToast('Network error.','danger');})
    .finally(function(){btn.disabled=false;btn.innerHTML='<i class="bi bi-x-circle"></i> Cancel Order';});
});

/* ── TOAST ── */
function showToast(msg,type){
  var t=document.getElementById('mainToast');var m=document.getElementById('mainToastMsg');
  var colors={success:'#059669',warning:'#d97706',danger:'#e11d48',info:'#2563eb'};
  t.style.background=colors[type]||'#111827';m.textContent=msg;
  new bootstrap.Toast(t,{delay:3500}).show();
}

/* ── COD DEPOSIT ── */
var _cdOrderId=null,_cdAgentId=null;
function openCodDepositModal(orderId,agentId,agentName,amount){
  _cdOrderId=orderId;_cdAgentId=agentId;
  document.getElementById('cdOrderId').textContent='#'+orderId;
  document.getElementById('cdAgentName').textContent=agentName;
  document.getElementById('cdOrderAmount').textContent='\u20b9'+amount;
  document.getElementById('cdAmountInput').value=amount;
  document.getElementById('cdNotesInput').value='';
  var err=document.getElementById('cdError');err.style.display='none';err.textContent='';
  var btn=document.getElementById('confirmDepositBtn');btn.disabled=false;btn.innerHTML='<i class="bi bi-check-circle"></i> Confirm Receipt';
  new bootstrap.Modal(document.getElementById('codDepositModal')).show();
}
function submitCodDeposit(){
  var amount=document.getElementById('cdAmountInput').value.trim();var notes=document.getElementById('cdNotesInput').value.trim();
  var err=document.getElementById('cdError');
  if(!amount||parseFloat(amount)<=0){err.textContent='Please enter a valid amount.';err.style.display='block';return;}
  var btn=document.getElementById('confirmDepositBtn');btn.disabled=true;btn.innerHTML='<i class="bi bi-hourglass-split"></i> Processing\u2026';
  // FIX: Use CodDepositServlet with action=staffConfirm (not OrdersDashboard / confirmCodDeposit).
  // OrderServlet's confirmCodDeposit() bypassed the proper audit-trail logic in
  // AgentWalletDAO.recordCodDeposit() and skipped the idempotency guard.
  var params=new URLSearchParams({action:'staffConfirm',orderId:_cdOrderId,agentId:_cdAgentId,amount:amount,notes:notes});
  fetch('CodDepositServlet',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded','X-Requested-With':'XMLHttpRequest'},body:params.toString()})
    .then(function(r){return r.json();})
    .then(function(data){bootstrap.Modal.getInstance(document.getElementById('codDepositModal')).hide();if(data.success){showToast(data.message||'Cash deposit confirmed!','success');setTimeout(function(){location.reload();},1800);}else{showToast(data.message||'Could not confirm deposit.','danger');btn.disabled=false;btn.innerHTML='<i class="bi bi-check-circle"></i> Confirm Receipt';}})
    .catch(function(){showToast('Network error.','danger');btn.disabled=false;btn.innerHTML='<i class="bi bi-check-circle"></i> Confirm Receipt';});
}

/* ── HANDLE WITHDRAWAL ── */
function handleWithdrawal(requestId,decision,agentName,amount){
  var isApproval=decision==='approve';
  var action=isApproval?'approveWithdrawal':'rejectWithdrawal';
  var statusPastTense=isApproval?'Approved':'Rejected';
  var confirmMsg=isApproval?'Approve withdrawal of ₹'+amount+' for '+agentName+'?\nThis will deduct from their wallet balance.':'Reject withdrawal of ₹'+amount+' for '+agentName+'?';
  if(!confirm(confirmMsg))return;
  var note=!isApproval?(prompt('Enter rejection reason (optional):')||'Rejected by staff.'):'';
  var params=new URLSearchParams({action:action,requestId:requestId,staffNote:note});
  fetch('OrdersDashboard',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded','X-Requested-With':'XMLHttpRequest'},body:params.toString()})
    .then(function(r){return r.json();})
    .then(function(data){if(data.success){showToast('Withdrawal '+statusPastTense+' for '+agentName+'.',isApproval?'success':'warning');setTimeout(function(){location.reload();},1600);}else{showToast('Error: '+(data.message||'Action failed.'),'danger');}})
    .catch(function(){showToast('Network error.','danger');});
}

/* ── REJECTION LOG ── */
function viewRejectionLog(agentId,agentName){
  var modal=document.getElementById('rejectionDetailModal');
  document.getElementById('rej-modal-agent-name').textContent=agentName;
  document.getElementById('rej-modal-agent-id').dataset.agentid=agentId;
  var body=document.getElementById('rej-modal-log-body');
  body.innerHTML='<div style="text-align:center;padding:2rem;color:var(--text-soft);"><i class="bi bi-hourglass-split" style="font-size:2rem;display:block;margin-bottom:.5rem;opacity:.4"></i>Loading...</div>';
  new bootstrap.Modal(modal).show();
  fetch('OrdersDashboard?action=getAgentRejectionLog&agentId='+agentId)
    .then(function(r){return r.json();})
    .then(function(data){
      if(!data||data.length===0){body.innerHTML='<div style="text-align:center;padding:2rem;color:var(--text-soft);font-size:.85rem;"><i class="bi bi-check-circle" style="font-size:2rem;display:block;margin-bottom:.5rem;opacity:.4"></i>No rejection log entries found.</div>';}
      else{body.innerHTML=data.map(function(row,i){return'<div class="rej-log-row"><div class="rej-log-num">'+(i+1)+'</div><div style="flex:1;min-width:0;"><div style="display:flex;align-items:center;gap:.5rem;flex-wrap:wrap;"><span class="rej-log-order">#'+(row.orderId||'—')+'</span><span style="font-size:.72rem;color:var(--text-soft);">'+(row.time||'')+'</span><button onclick="deleteSingleRejection('+row.logId+', this)" style="margin-left:auto;font-size:.65rem;padding:2px 8px;border-radius:6px;border:1px solid rgba(244,63,94,.3);color:var(--danger);background:transparent;cursor:pointer;"><i class="bi bi-trash"></i> Remove</button></div><div class="rej-log-reason">'+(row.reason||'—')+'</div></div></div>';}).join('');}
    }).catch(function(){body.innerHTML='<div style="text-align:center;padding:2rem;color:var(--danger);font-size:.85rem;"><i class="bi bi-exclamation-triangle" style="font-size:2rem;display:block;margin-bottom:.5rem;"></i>Failed to load rejection log.</div>';});
}

function unblockAgent(agentUserId,agentName){
  if(!confirm('Unblock '+agentName+'?'))return;
  var params=new URLSearchParams({action:'unblockAgent',agentUserId:agentUserId});
  fetch('OrdersDashboard',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded','X-Requested-With':'XMLHttpRequest'},body:params.toString()})
    .then(function(r){return r.json();})
    .then(function(data){if(data.success){showToast(agentName+' has been unblocked.','success');setTimeout(function(){location.reload();},1600);}else{showToast('Error: '+(data.message||'Could not unblock.'),'danger');}})
    .catch(function(){showToast('Network error.','danger');});
}

function reviewRejection(agentId,agentName,decision){
  var label=decision==='accept'?'Accept':'Dismiss';
  var note=prompt(label+' rejection reason for '+agentName+'?\nEnter a staff note (optional):');
  if(note===null)return;
  var params=new URLSearchParams({action:'reviewAgentRejection',agentUserId:agentId,decision:decision,staffNote:note||''});
  fetch('OrdersDashboard',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded','X-Requested-With':'XMLHttpRequest'},body:params.toString()})
    .then(function(r){return r.json();})
    .then(function(data){if(data.success){showToast(data.message||'Reviewed.',decision==='accept'?'success':'warning');setTimeout(function(){location.reload();},1600);}else{showToast('Error: '+(data.message||'Action failed.'),'danger');}})
    .catch(function(){showToast('Network error.','danger');});
}

function deleteSingleRejection(logId,btn){
  if(!confirm('Remove this single rejection entry?'))return;
  btn.disabled=true;
  fetch('OrdersDashboard',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded','X-Requested-With':'XMLHttpRequest'},body:'action=deleteSingleRejection&logId='+logId})
    .then(function(r){return r.json();})
    .then(function(data){if(data.success){btn.closest('.rej-log-row').remove();showToast('Rejection entry removed.','success');}else{showToast(data.message||'Failed.','danger');btn.disabled=false;}})
    .catch(function(){showToast('Network error.','danger');btn.disabled=false;});
}

/* ── BELL POLLING ── */
function pollBell(){
  fetch('StaffNotifications?count=true').then(function(r){return r.text();}).then(function(count){
    var n=parseInt(count,10);var badge=document.querySelector('.bell-badge');var bell=document.querySelector('.nav-icon-btn');
    if(n>0){if(badge)badge.textContent=n;else if(bell){badge=document.createElement('span');badge.className='bell-badge';badge.textContent=n;bell.appendChild(badge);}document.title='('+n+') Orders Dashboard';}
    else{if(badge)badge.remove();document.title='Orders Dashboard — SmartStock';}
  }).catch(function(){});
}
setInterval(pollBell,60000);

/* ── TICKET BADGE ── */
(function(){
  var badge=document.getElementById('nav-ticket-badge');
  if(!badge)return;
  function checkTickets(){
    fetch('StaffAIChatServlet?action=lookupTickets').then(function(r){return r.json();}).then(function(d){
      var n=d.count||0;if(n>0){badge.textContent=n;badge.style.display='inline-block';}else{badge.style.display='none';}
    }).catch(function(){});
  }
  checkTickets();setInterval(checkTickets,60000);
})();
</script>
</body>
</html>
