<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true"%>
<%@ page import="com.util.*, java.util.*, java.text.SimpleDateFormat" %>
<%
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("customerId") == null) {
        response.sendRedirect("CustomerLogin.jsp"); return;
    }
    Customer customer     = (Customer) request.getAttribute("customer");
    String customerName   = (String)  request.getAttribute("customerName");
    String customerEmail  = (String)  request.getAttribute("customerEmail");
    double walletBalance  = request.getAttribute("walletBalance")      != null ? (Double)  request.getAttribute("walletBalance")      : 0.0;
    double totalSpent     = request.getAttribute("totalSpent")         != null ? (Double)  request.getAttribute("totalSpent")         : 0.0;
    double totalRefunds   = request.getAttribute("totalRefunds")       != null ? (Double)  request.getAttribute("totalRefunds")       : 0.0;
    double totalCashback  = request.getAttribute("totalCashback")      != null ? (Double)  request.getAttribute("totalCashback")      : 0.0;
    double totalCredited  = request.getAttribute("totalCredited")      != null ? (Double)  request.getAttribute("totalCredited")      : 0.0;
    double totalWithdrawn = request.getAttribute("totalWithdrawn")     != null ? (Double)  request.getAttribute("totalWithdrawn")     : 0.0;
    double spentThisMonth = request.getAttribute("spentThisMonth")     != null ? (Double)  request.getAttribute("spentThisMonth")     : 0.0;
    int    totalTxns      = request.getAttribute("totalTxns")          != null ? (Integer) request.getAttribute("totalTxns")          : 0;
    int    ordersWallet   = request.getAttribute("ordersPaidByWallet") != null ? (Integer) request.getAttribute("ordersPaidByWallet") : 0;

    @SuppressWarnings("unchecked")
    List<WalletTransaction> transactions = (List<WalletTransaction>) request.getAttribute("transactions");
    if (transactions == null) transactions = new ArrayList<>();

    @SuppressWarnings("unchecked")
    List<Map<String,Object>> monthlySpending = (List<Map<String,Object>>) request.getAttribute("monthlySpending");
    if (monthlySpending == null) monthlySpending = new ArrayList<>();

    String filterTxnType  = (String) request.getAttribute("filterTxnType");  if (filterTxnType  == null) filterTxnType  = "";
    String filterStatus   = (String) request.getAttribute("filterStatus");   if (filterStatus   == null) filterStatus   = "";
    String filterDateFrom = (String) request.getAttribute("filterDateFrom"); if (filterDateFrom == null) filterDateFrom = "";

    /* Pagination */
    int pageSize = 10, currentPage = 1;
    if (request.getParameter("page") != null) {
        try { currentPage = Integer.parseInt(request.getParameter("page")); } catch (Exception e) { currentPage = 1; }
    }
    int totalPages = (int) Math.ceil(transactions.size() / (double) pageSize);
    if (totalPages < 1) totalPages = 1;
    int fromIdx  = (currentPage - 1) * pageSize;
    int toIdx    = Math.min(fromIdx + pageSize, transactions.size());
    List<WalletTransaction> pageTxns = transactions.subList(fromIdx, toIdx);

    /* Chart JSON */
    StringBuilder chartLabels  = new StringBuilder("[");
    StringBuilder chartAmounts = new StringBuilder("[");
    for (int mi = 0; mi < monthlySpending.size(); mi++) {
        Map<String,Object> m = monthlySpending.get(mi);
        if (mi > 0) { chartLabels.append(","); chartAmounts.append(","); }
        chartLabels.append("\"").append(m.get("label")).append("\"");
        chartAmounts.append(m.get("amount"));
    }
    chartLabels.append("]"); chartAmounts.append("]");

    String displayName = customerName != null ? customerName : (customer != null && customer.getName() != null ? customer.getName() : "User");
    String initials    = displayName.length() > 0 ? String.valueOf(displayName.charAt(0)).toUpperCase() : "U";
    SimpleDateFormat dtFmt = new SimpleDateFormat("dd MMM yyyy, hh:mm a");
    SimpleDateFormat dFmt  = new SimpleDateFormat("dd MMM yyyy");
    SimpleDateFormat tFmt  = new SimpleDateFormat("hh:mm a");
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>My Wallet — SIBS Store</title>
  <link href="https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,400;0,600;0,700;1,400;1,600&family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
  <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
  <script src="https://checkout.razorpay.com/v1/checkout.js"></script>
  <style>
    :root {
      --ink:#0d0d14; --ink2:#3a3a4e; --muted:#868699;
      --bg:#f5f5f8; --surface:#fff; --border:#e8e8f0;
      --accent:#ff4757; --green:#2ed573; --gold:#ffa502; --blue:#1e90ff; --purple:#8e44ad;
      --orange:#ff6b35;
      --nav-h:64px; --r:16px;
      --sh:0 2px 16px rgba(13,13,20,.07); --sh2:0 8px 32px rgba(13,13,20,.13);
    }
    *,*::before,*::after{box-sizing:border-box;margin:0;padding:0;}
    body{font-family:'Inter',sans-serif;background:var(--bg);color:var(--ink);padding-top:var(--nav-h);min-height:100vh;}

    /* NAV */
    .nav{position:fixed;top:0;left:0;right:0;z-index:900;height:var(--nav-h);background:var(--ink);display:flex;align-items:center;padding:0 1rem;gap:.75rem;box-shadow:0 2px 20px rgba(0,0,0,.3);}
    .nav-brand{font-family:'Cormorant Garamond',serif;font-size:1.65rem;font-weight:700;color:#fff;text-decoration:none;letter-spacing:.5px;font-style:italic;}
    .nav-brand em{color:var(--accent);font-style:normal;}
    .nav-back{display:flex;align-items:center;gap:.4rem;background:rgba(255,255,255,.09);border:1px solid rgba(255,255,255,.12);border-radius:10px;color:rgba(255,255,255,.8);font-size:.85rem;font-weight:600;padding:.4rem .85rem;text-decoration:none;transition:.2s;}
    .nav-back:hover{background:rgba(255,255,255,.18);color:#fff;}
    /* Hide "Dashboard" text on very small screens */
    .nav-back-text{display:inline;}
    @media(max-width:400px){.nav-back-text{display:none;}}
    .nav-right{margin-left:auto;display:flex;align-items:center;gap:.5rem;}
    .nav-btn{width:38px;height:38px;border-radius:10px;background:rgba(255,255,255,.09);border:1px solid rgba(255,255,255,.12);color:rgba(255,255,255,.8);font-size:1.1rem;display:flex;align-items:center;justify-content:center;text-decoration:none;transition:.2s;}
    .nav-btn:hover{background:rgba(255,255,255,.18);color:#fff;}
    .nav-avatar{width:36px;height:36px;border-radius:50%;background:linear-gradient(135deg,var(--accent),#ff6b6b);font-family:'Cormorant Garamond',serif;font-weight:700;font-size:1.05rem;color:#fff;display:flex;align-items:center;justify-content:center;}

    /* PAGE */
    .page{max-width:1000px;margin:0 auto;padding:1.75rem 1rem 5rem;}
    .page-title{font-family:'Cormorant Garamond',serif;font-size:1.75rem;font-weight:700;margin-bottom:1.5rem;letter-spacing:.3px;}

    /* WALLET HERO */
    .wallet-hero{background:linear-gradient(135deg,var(--ink) 0%,#1a1a2e 60%,#2d1b4e 100%);border-radius:var(--r);overflow:hidden;box-shadow:var(--sh2);margin-bottom:1.25rem;position:relative;}
    .wallet-hero::before{content:'';position:absolute;top:-40%;right:-10%;width:320px;height:320px;border-radius:50%;background:radial-gradient(circle,rgba(255,71,87,.2) 0%,transparent 70%);}
    .wallet-hero::after{content:'';position:absolute;bottom:-30%;left:15%;width:240px;height:240px;border-radius:50%;background:radial-gradient(circle,rgba(30,144,255,.13) 0%,transparent 70%);}
    .wh-inner{position:relative;z-index:1;padding:2rem 1.5rem 1.5rem;display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:1.5rem;}
    .wh-label{font-size:.78rem;color:rgba(255,255,255,.5);text-transform:uppercase;letter-spacing:1px;font-weight:700;margin-bottom:.3rem;}
    .wh-balance{font-family:'Inter',sans-serif;font-variant-numeric:tabular-nums;font-feature-settings:"tnum";font-size:clamp(2rem,6vw,3rem);font-weight:800;color:#fff;letter-spacing:-1px;line-height:1;}
    .wh-sub{font-size:.8rem;color:rgba(255,255,255,.4);margin-top:.25rem;}
    .wh-actions{display:flex;flex-direction:column;gap:.5rem;}
    @media(max-width:500px){.wh-actions{flex-direction:row;flex-wrap:wrap;}}
    .wh-btn{display:flex;align-items:center;gap:.45rem;padding:.6rem 1.1rem;border-radius:10px;font-family:'Inter',sans-serif;font-size:.85rem;font-weight:700;cursor:pointer;border:none;transition:.2s;text-decoration:none;white-space:nowrap;}
    .wh-btn.primary{background:var(--accent);color:#fff;}
    .wh-btn.primary:hover{background:#e8384a;}
    .wh-btn.success{background:#16a34a;color:#fff;}
    .wh-btn.success:hover{background:#15803d;}
    .wh-btn.outline{background:rgba(255,255,255,.1);border:1px solid rgba(255,255,255,.2);color:#fff;}
    .wh-btn.outline:hover{background:rgba(255,255,255,.18);color:#fff;}
    .wh-strip{position:relative;z-index:1;background:rgba(255,255,255,.05);border-top:1px solid rgba(255,255,255,.08);padding:1rem 1.5rem;display:flex;gap:1.5rem;flex-wrap:wrap;}
    .ws-val{font-family:'Inter',sans-serif;font-variant-numeric:tabular-nums;font-feature-settings:"tnum";font-size:1rem;font-weight:700;color:#fff;}
    .ws-lbl{font-size:.68rem;color:rgba(255,255,255,.45);margin-top:1px;}

    /* CHART CARD */
    .chart-card{background:var(--surface);border-radius:var(--r);border:1px solid var(--border);box-shadow:var(--sh);padding:1.25rem;margin-bottom:1.25rem;}
    .chart-head{display:flex;align-items:center;justify-content:space-between;margin-bottom:1rem;}
    .chart-title{font-family:'Cormorant Garamond',serif;font-size:.95rem;font-weight:700;}
    .chart-sub{font-size:.75rem;color:var(--muted);}
    .chart-wrap{height:160px;position:relative;}

    /* STATS ROW */
    .stats-row{display:grid;grid-template-columns:repeat(3,1fr);gap:.85rem;margin-bottom:1.25rem;}
    @media(max-width:520px){.stats-row{grid-template-columns:1fr 1fr;}}
    .stat-card{background:var(--surface);border-radius:var(--r);border:1px solid var(--border);padding:1rem 1.1rem;box-shadow:var(--sh);display:flex;align-items:center;gap:.85rem;}
    .stat-icon{width:42px;height:42px;border-radius:12px;display:flex;align-items:center;justify-content:center;font-size:1.15rem;flex-shrink:0;}
    .stat-val{font-family:'Inter',sans-serif;font-variant-numeric:tabular-nums;font-feature-settings:"tnum";font-size:1.1rem;font-weight:800;color:var(--ink);}
    .stat-lbl{font-size:.72rem;color:var(--muted);}

    /* FILTER BAR */
    .filter-bar{background:var(--surface);border-radius:var(--r);border:1px solid var(--border);padding:1rem 1.25rem;margin-bottom:1rem;display:flex;gap:.6rem;flex-wrap:wrap;align-items:center;box-shadow:var(--sh);}
    .fi{height:36px;border-radius:8px;border:1.5px solid var(--border);padding:0 .75rem;font-family:'Inter',sans-serif;font-size:.82rem;outline:none;background:var(--bg);color:var(--ink);transition:.2s;}
    .fi:focus{border-color:var(--ink);background:#fff;}
    .fi-sel{cursor:pointer;}
    .fi-date{min-width:140px;}
    .fi-search{flex:1;min-width:160px;}
    .filter-reset{height:36px;padding:0 1rem;border-radius:8px;border:1.5px solid var(--border);background:transparent;color:var(--ink2);font-family:'Inter',sans-serif;font-size:.82rem;font-weight:700;cursor:pointer;transition:.2s;display:flex;align-items:center;gap:.35rem;}
    .filter-reset:hover{border-color:var(--ink);color:var(--ink);}
    .export-btn{height:36px;padding:0 1rem;border-radius:8px;border:none;background:var(--ink);color:#fff;font-family:'Inter',sans-serif;font-size:.82rem;font-weight:700;cursor:pointer;transition:.2s;display:flex;align-items:center;gap:.35rem;text-decoration:none;margin-left:auto;}
    .export-btn:hover{background:var(--accent);color:#fff;}

    /* TXN TABLE */
    .txn-section{background:var(--surface);border-radius:var(--r);border:1px solid var(--border);box-shadow:var(--sh);overflow:hidden;}
    .txn-section-head{padding:1.1rem 1.5rem;display:flex;align-items:center;justify-content:space-between;border-bottom:1px solid var(--border);}
    .txn-section-title{font-family:'Cormorant Garamond',serif;font-size:1rem;font-weight:700;}
    .txn-count{font-size:.75rem;color:var(--muted);}

    /* Desktop table */
    .txn-table-wrap{overflow-x:auto;}
    @media(max-width:640px){.txn-table-wrap{display:none;}}
    .txn-table{width:100%;border-collapse:collapse;}
    .txn-table th{background:var(--bg);padding:.7rem 1.1rem;text-align:left;font-size:.7rem;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.5px;border-bottom:1px solid var(--border);white-space:nowrap;}
    .txn-table td{padding:.9rem 1.1rem;border-bottom:1px solid var(--border);vertical-align:middle;font-size:.86rem;}
    .txn-table tbody tr:last-child td{border-bottom:none;}
    .txn-table tbody tr:hover{background:var(--bg);}

    /* Type pills */
    .txn-pill{display:inline-flex;align-items:center;gap:.25rem;padding:2px 8px;border-radius:20px;font-size:.68rem;font-weight:700;text-transform:capitalize;}
    .txn-refund  {background:rgba(30,144,255,.1);color:#1e90ff;border:1px solid rgba(30,144,255,.25);}
    .txn-credit  {background:rgba(46,213,115,.1);color:#18a057;border:1px solid rgba(46,213,115,.25);}
    .txn-topup   {background:rgba(142,68,173,.1);color:#8e44ad;border:1px solid rgba(142,68,173,.25);}
    .txn-cashback{background:rgba(255,165,2,.1);color:#b07000;border:1px solid rgba(255,165,2,.25);}
    .txn-debit   {background:rgba(255,71,87,.1);color:#ff4757;border:1px solid rgba(255,71,87,.25);}
    .txn-withdraw{background:rgba(255,107,53,.1);color:#ff6b35;border:1px solid rgba(255,107,53,.25);}

    /* Status chip */
    .chip{display:inline-flex;align-items:center;gap:.2rem;padding:2px 7px;border-radius:6px;font-size:.68rem;font-weight:700;}
    .chip-success{background:rgba(46,213,115,.1);color:#18a057;}
    .chip-pending{background:rgba(255,165,2,.1);color:#b07000;}
    .chip-failed {background:rgba(255,71,87,.1);color:#ff4757;}

    /* Amount */
    .txn-amount{font-family:'Inter',sans-serif;font-variant-numeric:tabular-nums;font-feature-settings:"tnum";font-size:.9rem;font-weight:700;}
    .txn-amount.cr{color:var(--green);}
    .txn-amount.db{color:var(--accent);}
    .txn-amount.wd{color:var(--orange);}

    /* Balance after — BUG FIX: show dash when 0 (unfilled legacy rows) */
    .bal-after-zero{color:var(--muted);font-style:italic;font-size:.78rem;}

    /* View btn */
    .txn-eye{width:28px;height:28px;border-radius:7px;border:1.5px solid var(--border);background:transparent;color:var(--ink2);cursor:pointer;display:flex;align-items:center;justify-content:center;font-size:.82rem;transition:.15s;}
    .txn-eye:hover{background:var(--ink);color:#fff;border-color:var(--ink);}

    /* Mobile cards */
    .txn-cards{display:none;padding:.5rem;}
    @media(max-width:640px){.txn-cards{display:block;}}
    .txn-mc{background:var(--bg);border-radius:12px;padding:.8rem 1rem;margin-bottom:.5rem;display:flex;align-items:center;gap:.8rem;border:1px solid var(--border);}
    .txn-mc-icon{width:38px;height:38px;border-radius:11px;display:flex;align-items:center;justify-content:center;font-size:1rem;flex-shrink:0;}
    .txn-mc-body{flex:1;min-width:0;}
    .txn-mc-desc{font-weight:700;font-size:.86rem;color:var(--ink);white-space:nowrap;overflow:hidden;text-overflow:ellipsis;}
    .txn-mc-meta{font-size:.72rem;color:var(--muted);margin-top:2px;}
    .txn-mc-right{text-align:right;flex-shrink:0;}
    .txn-mc-amount{font-family:'Inter',sans-serif;font-variant-numeric:tabular-nums;font-feature-settings:"tnum";font-size:.9rem;font-weight:700;}
    .txn-mc-bal{font-size:.7rem;color:var(--muted);margin-top:1px;}

    /* Empty */
    .txn-empty{text-align:center;padding:3rem 1rem;}
    .txn-empty-icon{font-size:3rem;margin-bottom:.65rem;}
    .txn-empty-title{font-family:'Cormorant Garamond',serif;font-size:1rem;font-weight:700;margin-bottom:.25rem;}
    .txn-empty-sub{font-size:.84rem;color:var(--muted);}

    /* Pagination */
    .pg{display:flex;justify-content:center;gap:.4rem;padding:1.1rem;border-top:1px solid var(--border);flex-wrap:wrap;}
    .pg-btn{min-width:34px;height:34px;border-radius:9px;border:1.5px solid var(--border);background:var(--surface);color:var(--ink2);font-size:.84rem;font-weight:600;cursor:pointer;display:flex;align-items:center;justify-content:center;padding:0 .45rem;text-decoration:none;transition:.15s;}
    .pg-btn:hover{border-color:var(--ink);background:var(--ink);color:#fff;}
    .pg-btn.active{background:var(--accent);border-color:var(--accent);color:#fff;}
    .pg-btn.disabled{opacity:.35;pointer-events:none;}

    /* MODAL */
    .modal-overlay{position:fixed;inset:0;z-index:1100;background:rgba(0,0,0,.5);backdrop-filter:blur(4px);display:flex;align-items:center;justify-content:center;opacity:0;pointer-events:none;transition:opacity .25s;padding:1rem;}
    .modal-overlay.open{opacity:1;pointer-events:all;}
    .modal-box{background:var(--surface);border-radius:var(--r);width:100%;max-width:460px;box-shadow:0 20px 60px rgba(0,0,0,.25);transform:scale(.95);transition:transform .25s;max-height:90vh;overflow-y:auto;}
    .modal-overlay.open .modal-box{transform:scale(1);}
    .modal-head{background:linear-gradient(135deg,var(--ink),#1a1a2e);border-radius:var(--r) var(--r) 0 0;padding:1.5rem;text-align:center;}
    .modal-logo{font-family:'Cormorant Garamond',serif;font-size:1rem;font-weight:700;color:rgba(255,255,255,.45);margin-bottom:.5rem;}
    .modal-logo em{color:var(--accent);font-style:normal;}
    .modal-title-text{font-family:'Cormorant Garamond',serif;font-size:1.4rem;font-weight:700;color:#fff;}
    .modal-body-inner{padding:1.25rem 1.5rem;}
    .modal-footer{padding:.9rem 1.5rem;border-top:1px solid var(--border);display:flex;gap:.5rem;justify-content:flex-end;}
    .modal-btn{height:38px;padding:0 1.1rem;border-radius:9px;font-family:'Inter',sans-serif;font-size:.86rem;font-weight:700;cursor:pointer;border:none;transition:.2s;display:flex;align-items:center;gap:.35rem;}
    .modal-btn.primary{background:var(--ink);color:#fff;}
    .modal-btn.primary:hover{background:var(--accent);}
    .modal-btn.success{background:#16a34a;color:#fff;}
    .modal-btn.success:hover{background:#15803d;}
    .modal-btn.outline{background:transparent;border:1.5px solid var(--border);color:var(--ink2);}
    .modal-btn.outline:hover{border-color:var(--ink);}

    /* Quick amount buttons */
    .quick-amt-btn{flex:1;min-width:60px;height:36px;border-radius:8px;border:1.5px solid var(--border);background:var(--bg);color:var(--ink);font-family:'Inter',sans-serif;font-size:.82rem;font-weight:600;cursor:pointer;transition:.2s;}
    .quick-amt-btn:hover{border-color:var(--ink);background:var(--ink);color:#fff;}

    /* Field label */
    .field-label{font-size:.8rem;font-weight:600;color:var(--muted);display:block;margin-bottom:.4rem;}
    .field-input{width:100%;height:42px;border-radius:10px;border:1.5px solid var(--border);padding:0 1rem;font-family:'Inter',sans-serif;font-size:.95rem;font-weight:600;outline:none;transition:.2s;background:var(--bg);}
    .field-input:focus{border-color:var(--ink);background:#fff;}
    .field-hint{font-size:.73rem;color:var(--muted);margin-top:.3rem;}
    .error-msg{color:var(--accent);font-size:.78rem;margin-top:.35rem;display:none;}

    /* Withdrawal tabs */
    .withdraw-tabs{display:flex;gap:.4rem;margin-bottom:1rem;}
    .wtab{flex:1;height:36px;border-radius:8px;border:1.5px solid var(--border);background:var(--bg);color:var(--ink2);font-family:'Inter',sans-serif;font-size:.82rem;font-weight:600;cursor:pointer;transition:.2s;}
    .wtab.active{border-color:var(--ink);background:var(--ink);color:#fff;}

    /* RECEIPT MODAL */
    .receipt-head{background:linear-gradient(135deg,var(--ink),#1a1a2e);border-radius:var(--r) var(--r) 0 0;padding:1.75rem;text-align:center;}
    .receipt-logo{font-family:'Cormorant Garamond',serif;font-size:1rem;font-weight:700;color:rgba(255,255,255,.45);margin-bottom:.85rem;}
    .receipt-logo em{color:var(--accent);font-style:normal;}
    .receipt-amount-val{font-family:'Inter',sans-serif;font-variant-numeric:tabular-nums;font-feature-settings:"tnum";font-size:2.4rem;font-weight:800;color:#fff;line-height:1;}
    .receipt-status-row{margin-top:.5rem;}
    .receipt-body{padding:1.1rem 1.5rem;}
    .r-row{display:flex;justify-content:space-between;align-items:flex-start;padding:.55rem 0;border-bottom:1px dashed var(--border);}
    .r-row:last-child{border-bottom:none;}
    .r-label{font-size:.8rem;color:var(--muted);font-weight:600;flex-shrink:0;margin-right:.5rem;}
    .r-val{font-size:.85rem;font-weight:700;color:var(--ink);text-align:right;word-break:break-all;font-family:monospace;}
    .r-val.normal{font-family:'Inter',sans-serif;}

    /* TOAST */
    .toast-hub{position:fixed;bottom:1.5rem;right:1rem;z-index:2000;display:flex;flex-direction:column;gap:.5rem;}
    .toast-msg{background:var(--ink);color:#fff;border-radius:12px;padding:.7rem 1rem;font-size:.84rem;font-weight:600;box-shadow:var(--sh2);display:flex;align-items:center;gap:.45rem;animation:slideUp .3s ease;max-width:300px;}
    @keyframes slideUp{from{opacity:0;transform:translateY(12px);}to{opacity:1;transform:translateY(0);}}

    /* Mobile full-width filter bar */
    @media(max-width:600px){
      .wh-inner{flex-direction:column;align-items:flex-start;}
      .stats-row{grid-template-columns:1fr 1fr;}
      .filter-bar{flex-direction:column;}
      .fi-search,.fi,.fi-sel,.fi-date{width:100%;}
      .export-btn{margin-left:0;width:100%;justify-content:center;}
      .page{padding:1.25rem .75rem 5rem;}
      .page-title{font-size:1.4rem;}
    }
    @media print{
      .nav,.filter-bar,.export-btn,.modal-footer,.toast-hub,.pg{display:none!important;}
      .txn-section{box-shadow:none;border:1px solid #ccc;}
    }
  @media(max-width:768px){body{padding-bottom:70px;}}
</style>
</head>
<body>

<nav class="nav">
  <a href="Customer" class="nav-brand">SIBS<em>.</em></a>
  <a href="Customer" class="nav-back">
    <i class="bi bi-arrow-left"></i>
    <span class="nav-back-text"> Dashboard</span>
  </a>
  <div class="nav-right">
    <a href="CustomerOrdersServlet" class="nav-btn" title="My Orders"><i class="bi bi-box-seam"></i></a>
    <a href="CartServlet?action=view" class="nav-btn" title="Cart"><i class="bi bi-bag"></i></a>
    <div class="nav-avatar"><%= initials %></div>
  </div>
</nav>

<div class="page">
  <div class="page-title">My Wallet</div>

  <!-- WALLET HERO -->
  <div class="wallet-hero">
    <div class="wh-inner">
      <div>
        <div class="wh-label">Available Balance</div>
        <div class="wh-balance" id="heroBalance">&#8377;<%= String.format("%.2f", walletBalance) %></div>
        <div class="wh-sub">Wallet &middot; <%= displayName %></div>
      </div>
      <div class="wh-actions">
        <button class="wh-btn primary" onclick="openAddMoneyModal()">
          <i class="bi bi-plus-circle-fill"></i> Add Money
        </button>
        <button class="wh-btn success" onclick="openWithdrawModal()">
          <i class="bi bi-bank"></i> Withdraw
        </button>
        <a href="CustomerWallet?export=csv" class="wh-btn outline">
          <i class="bi bi-download"></i> Export
        </a>
      </div>
    </div>
    <div class="wh-strip">
      <div><div class="ws-val">&#8377;<%= String.format("%.0f", totalSpent) %></div><div class="ws-lbl">Total Debited</div></div>
      <div><div class="ws-val">&#8377;<%= String.format("%.0f", totalCredited) %></div><div class="ws-lbl">Topped Up</div></div>
      <div><div class="ws-val">&#8377;<%= String.format("%.0f", totalRefunds) %></div><div class="ws-lbl">Refunds</div></div>
      <div><div class="ws-val">&#8377;<%= String.format("%.0f", totalCashback) %></div><div class="ws-lbl">Cashback</div></div>
      <div><div class="ws-val">&#8377;<%= String.format("%.0f", totalWithdrawn) %></div><div class="ws-lbl">Withdrawn</div></div>
      <div><div class="ws-val"><%= ordersWallet %></div><div class="ws-lbl">Orders via Wallet</div></div>
    </div>
  </div>

  <!-- STATS -->
  <div class="stats-row">
    <div class="stat-card">
      <div class="stat-icon" style="background:rgba(46,213,115,.1);color:var(--green);"><i class="bi bi-arrow-down-circle-fill"></i></div>
      <div><div class="stat-val">&#8377;<%= String.format("%.0f", totalCredited) %></div><div class="stat-lbl">Lifetime Top-ups</div></div>
    </div>
    <div class="stat-card">
      <div class="stat-icon" style="background:rgba(255,71,87,.1);color:var(--accent);"><i class="bi bi-arrow-up-circle-fill"></i></div>
      <div><div class="stat-val">&#8377;<%= String.format("%.0f", spentThisMonth) %></div><div class="stat-lbl">This Month</div></div>
    </div>
    <div class="stat-card">
      <div class="stat-icon" style="background:rgba(30,144,255,.1);color:var(--blue);"><i class="bi bi-receipt"></i></div>
      <div><div class="stat-val"><%= totalTxns %></div><div class="stat-lbl">Transactions</div></div>
    </div>
  </div>

  <!-- SPENDING CHART -->
  <% if (!monthlySpending.isEmpty()) { %>
  <div class="chart-card">
    <div class="chart-head">
      <div>
        <div class="chart-title">Monthly Spending</div>
        <div class="chart-sub">Last 6 months debit breakdown</div>
      </div>
    </div>
    <div class="chart-wrap">
      <canvas id="spendingChart"></canvas>
    </div>
  </div>
  <% } %>

  <!-- FILTER BAR -->
  <div class="filter-bar">
    <input class="fi fi-search" id="txnSearch" type="text" placeholder="Search description or txn ID&hellip;" value="">
    <select class="fi fi-sel" id="txnTypeFilter">
      <option value="all" <%= "".equals(filterTxnType) ? "selected" : "" %>>All Types</option>
      <option value="refund"   <%= "refund".equals(filterTxnType)   ? "selected" : "" %>>Refund</option>
      <option value="credit"   <%= "credit".equals(filterTxnType)   ? "selected" : "" %>>Credit</option>
      <option value="topup"    <%= "topup".equals(filterTxnType)    ? "selected" : "" %>>Top-up</option>
      <option value="cashback" <%= "cashback".equals(filterTxnType) ? "selected" : "" %>>Cashback</option>
      <option value="debit"    <%= "debit".equals(filterTxnType)    ? "selected" : "" %>>Debit</option>
      <option value="withdraw" <%= "withdraw".equals(filterTxnType) ? "selected" : "" %>>Withdraw</option>
    </select>
    <select class="fi fi-sel" id="txnStatusFilter">
      <option value="all" <%= "".equals(filterStatus) ? "selected" : "" %>>All Status</option>
      <option value="success" <%= "success".equals(filterStatus) ? "selected" : "" %>>Success</option>
      <option value="pending" <%= "pending".equals(filterStatus) ? "selected" : "" %>>Pending</option>
      <option value="failed"  <%= "failed".equals(filterStatus)  ? "selected" : "" %>>Failed</option>
    </select>
    <input class="fi fi-date" id="txnDate" type="date" value="<%= filterDateFrom %>"
           title="From date" onchange="applyServerFilter()">
    <button class="filter-reset" onclick="resetFilters()"><i class="bi bi-x-circle"></i> Reset</button>
    <a href="CustomerWallet?export=csv" class="export-btn"><i class="bi bi-download"></i> Export CSV</a>
  </div>

  <!-- TXN TABLE -->
  <div class="txn-section">
    <div class="txn-section-head">
      <div class="txn-section-title">Transaction History</div>
      <div class="txn-count" id="txnCount"><%= transactions.size() %> records</div>
    </div>

    <% if (pageTxns.isEmpty()) { %>
    <div class="txn-empty">
      <div class="txn-empty-icon">&#128219;</div>
      <div class="txn-empty-title">No transactions yet</div>
      <div class="txn-empty-sub">Your wallet activity will appear here.</div>
    </div>
    <% } else { %>

    <!-- Desktop Table -->
    <div class="txn-table-wrap">
      <table class="txn-table">
        <thead>
          <tr>
            <th>Date</th><th>Description</th><th>Type</th><th>Order</th>
            <th>Method</th><th>Balance After</th><th>Amount</th><th>Status</th><th></th>
          </tr>
        </thead>
        <tbody id="txnTableBody">
        <% for (WalletTransaction txn : pageTxns) {
            String type = txn.getTxnType() != null ? txn.getTxnType().toLowerCase() : "";
            boolean isCr = "refund".equals(type)||"credit".equals(type)||"topup".equals(type)||"cashback".equals(type);
            boolean isWd = "withdraw".equals(type);
            String typeCss = "txn-debit";
            if      ("refund".equals(type))   typeCss = "txn-refund";
            else if ("credit".equals(type))   typeCss = "txn-credit";
            else if ("topup".equals(type))    typeCss = "txn-topup";
            else if ("cashback".equals(type)) typeCss = "txn-cashback";
            else if ("withdraw".equals(type)) typeCss = "txn-withdraw";
            String chipCss   = "chip-success";
            if ("pending".equalsIgnoreCase(txn.getStatus())) chipCss = "chip-pending";
            if ("failed".equalsIgnoreCase(txn.getStatus()))  chipCss = "chip-failed";
            // BUG FIX: withdraw & debit are minus, credit types are plus
            String amtSign   = isCr ? "+" : "&#8722;";
            String amtClass  = isCr ? "cr" : (isWd ? "wd" : "db");
            String txnIdSafe = txn.getTransactionId() != null ? txn.getTransactionId() : "";
            String descSafe  = txn.getDescription()   != null ? txn.getDescription().replace("'","\\'").replace("\"","&quot;") : "";
            String dateSafe  = txn.getDate()           != null ? dtFmt.format(txn.getDate()) : "";
            String methSafe  = txn.getPaymentMethod()  != null ? txn.getPaymentMethod() : "&#8212;";
            String statusSafe= txn.getStatus()         != null ? txn.getStatus()        : "&#8212;";
            // BUG FIX: balance_after = 0.00 on old rows — show dash instead of ₹0.00
            boolean hasBal   = txn.getBalanceAfter() > 0.0;
            String balStr    = hasBal ? "&#8377;" + String.format("%.2f", txn.getBalanceAfter()) : "&#8212;";
            String balReceiptStr = hasBal ? "&#8377;" + String.format("%.2f", txn.getBalanceAfter()) : "N/A";
        %>
        <tr data-type="<%= type %>"
            data-status="<%= txn.getStatus() != null ? txn.getStatus().toLowerCase() : "" %>"
            data-desc="<%= txn.getDescription() != null ? txn.getDescription().toLowerCase() : "" %>"
            data-txnid="<%= txnIdSafe.toLowerCase() %>">
          <td>
            <div style="font-weight:600;font-size:.82rem;"><%= txn.getDate() != null ? dFmt.format(txn.getDate()) : "&#8212;" %></div>
            <div style="color:var(--muted);font-size:.72rem;"><%= txn.getDate() != null ? tFmt.format(txn.getDate()) : "" %></div>
          </td>
          <td>
            <div style="font-weight:600;max-width:200px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;"><%= txn.getDescription() != null ? txn.getDescription() : "&#8212;" %></div>
            <div style="font-size:.72rem;color:var(--muted);font-family:monospace;"><%= txnIdSafe.isEmpty() ? "" : txnIdSafe %></div>
          </td>
          <td><span class="txn-pill <%= typeCss %>"><%= type %></span></td>
          <td style="font-size:.82rem;color:var(--muted);"><%= txn.getOrderId() > 0 ? "#" + txn.getOrderId() : "&#8212;" %></td>
          <td style="font-size:.82rem;color:var(--muted);"><%= methSafe %></td>
          <td style="font-family:'Inter',sans-serif;font-variant-numeric:tabular-nums;font-size:.88rem;font-weight:700;">
            <% if (hasBal) { %>&#8377;<%= String.format("%.2f", txn.getBalanceAfter()) %><% } else { %><span class="bal-after-zero">&#8212;</span><% } %>
          </td>
          <td class="txn-amount <%= amtClass %>"><%= amtSign %>&#8377;<%= String.format("%.2f", txn.getAmount()) %></td>
          <td><span class="chip <%= chipCss %>"><%= statusSafe %></span></td>
          <td>
            <button class="txn-eye" title="Receipt"
              onclick="openReceipt('<%= txnIdSafe %>','<%= txn.getOrderId() > 0 ? "#"+txn.getOrderId() : "N/A" %>','<%= type %>','<%= descSafe %>','<%= amtSign %>&#8377;<%= String.format("%.2f", txn.getAmount()) %>','<%= statusSafe %>','<%= dateSafe %>','<%= methSafe %>','<%= balReceiptStr %>')">
              <i class="bi bi-eye"></i>
            </button>
          </td>
        </tr>
        <% } %>
        </tbody>
      </table>
    </div>

    <!-- Mobile Cards -->
    <div class="txn-cards">
      <% for (WalletTransaction txn : pageTxns) {
          String type = txn.getTxnType() != null ? txn.getTxnType().toLowerCase() : "";
          boolean isCr = "refund".equals(type)||"credit".equals(type)||"topup".equals(type)||"cashback".equals(type);
          boolean isWd = "withdraw".equals(type);
          String mcSign    = isCr ? "+" : "&#8722;";
          String mcAmtCol  = isCr ? "var(--green)" : (isWd ? "var(--orange)" : "var(--accent)");
          String mcIconBg  = isCr ? "rgba(46,213,115,.1)"  : (isWd ? "rgba(255,107,53,.1)" : "rgba(255,71,87,.1)");
          String mcIconCol = isCr ? "var(--green)"          : (isWd ? "var(--orange)"        : "var(--accent)");
          String mcIcon    = isCr ? "down"                  : "up";
          String mcTypeCss = "txn-debit";
          if      ("refund".equals(type))   mcTypeCss = "txn-refund";
          else if ("credit".equals(type))   mcTypeCss = "txn-credit";
          else if ("topup".equals(type))    mcTypeCss = "txn-topup";
          else if ("cashback".equals(type)) mcTypeCss = "txn-cashback";
          else if ("withdraw".equals(type)) mcTypeCss = "txn-withdraw";
          String mcTxnId  = txn.getTransactionId() != null ? txn.getTransactionId() : "";
          String mcDesc   = txn.getDescription()   != null ? txn.getDescription().replace("'","\\'").replace("\"","&quot;") : "";
          String mcDate   = txn.getDate()           != null ? dtFmt.format(txn.getDate()) : "";
          String mcMeth   = txn.getPaymentMethod()  != null ? txn.getPaymentMethod() : "&#8212;";
          String mcStatus = txn.getStatus()         != null ? txn.getStatus()        : "&#8212;";
          String mcChipCss = "chip-success";
          if ("pending".equalsIgnoreCase(txn.getStatus())) mcChipCss = "chip-pending";
          if ("failed".equalsIgnoreCase(txn.getStatus()))  mcChipCss = "chip-failed";
          boolean mcHasBal = txn.getBalanceAfter() > 0.0;
          String mcBalStr  = mcHasBal ? "&#8377;" + String.format("%.2f", txn.getBalanceAfter()) : "N/A";
      %>
      <div class="txn-mc" onclick="openReceipt('<%= mcTxnId %>','<%= txn.getOrderId() > 0 ? "#"+txn.getOrderId() : "N/A" %>','<%= type %>','<%= mcDesc %>','<%= mcSign %>&#8377;<%= String.format("%.2f", txn.getAmount()) %>','<%= mcStatus %>','<%= mcDate %>','<%= mcMeth %>','<%= mcBalStr %>')" style="cursor:pointer;">
        <div class="txn-mc-icon" style="background:<%= mcIconBg %>;color:<%= mcIconCol %>;">
          <i class="bi bi-arrow-<%= mcIcon %>-circle-fill"></i>
        </div>
        <div class="txn-mc-body">
          <div class="txn-mc-desc"><%= txn.getDescription() != null ? txn.getDescription() : "Transaction" %></div>
          <div class="txn-mc-meta">
            <span class="txn-pill <%= mcTypeCss %>" style="font-size:.6rem;"><%= type %></span>
            &nbsp;<span class="chip <%= mcChipCss %>"><%= mcStatus %></span>
            &nbsp;<span><%= txn.getDate() != null ? dFmt.format(txn.getDate()) : "" %></span>
          </div>
        </div>
        <div class="txn-mc-right">
          <div class="txn-mc-amount" style="color:<%= mcAmtCol %>;"><%= mcSign %>&#8377;<%= String.format("%.2f", txn.getAmount()) %></div>
          <div class="txn-mc-bal"><%= mcHasBal ? "Bal: &#8377;" + String.format("%.2f", txn.getBalanceAfter()) : "" %></div>
        </div>
      </div>
      <% } %>
    </div>
    <% } %>

    <!-- Pagination -->
    <% if (totalPages > 1) { %>
    <div class="pg">
      <a class="pg-btn <%= currentPage == 1 ? "disabled" : "" %>"
         href="CustomerWallet?page=<%= currentPage-1 %>&txnType=<%= filterTxnType %>&status=<%= filterStatus %>&dateFrom=<%= filterDateFrom %>">
        <i class="bi bi-chevron-left"></i>
      </a>
      <% for (int i = 1; i <= totalPages; i++) { %>
      <a class="pg-btn <%= i == currentPage ? "active" : "" %>"
         href="CustomerWallet?page=<%= i %>&txnType=<%= filterTxnType %>&status=<%= filterStatus %>&dateFrom=<%= filterDateFrom %>">
        <%= i %>
      </a>
      <% } %>
      <a class="pg-btn <%= currentPage == totalPages ? "disabled" : "" %>"
         href="CustomerWallet?page=<%= currentPage+1 %>&txnType=<%= filterTxnType %>&status=<%= filterStatus %>&dateFrom=<%= filterDateFrom %>">
        <i class="bi bi-chevron-right"></i>
      </a>
    </div>
    <% } %>
  </div><!-- /txn-section -->
</div><!-- /page -->

<!-- ══ RECEIPT MODAL ══ -->
<div class="modal-overlay" id="receiptOverlay">
  <div class="modal-box">
    <div class="receipt-head">
      <div class="receipt-logo">SIBS<em>.</em> Store</div>
      <div class="receipt-amount-val" id="r-amount"></div>
      <div class="receipt-status-row"><span class="chip" id="r-chip"></span></div>
    </div>
    <div class="receipt-body">
      <div class="r-row"><span class="r-label">Transaction ID</span><span class="r-val" id="r-txnid"></span></div>
      <div class="r-row"><span class="r-label">Order</span><span class="r-val normal" id="r-order"></span></div>
      <div class="r-row"><span class="r-label">Type</span><span class="r-val normal" id="r-type"></span></div>
      <div class="r-row"><span class="r-label">Description</span><span class="r-val normal" id="r-desc" style="font-size:.78rem;"></span></div>
      <div class="r-row"><span class="r-label">Payment Via</span><span class="r-val normal" id="r-method"></span></div>
      <div class="r-row"><span class="r-label">Date &amp; Time</span><span class="r-val normal" id="r-date"></span></div>
      <div class="r-row"><span class="r-label">Balance After</span><span class="r-val normal" id="r-bal" style="color:var(--green);font-family:'Inter',sans-serif;font-size:1rem;font-weight:800;"></span></div>
    </div>
    <div class="modal-footer">
      <button class="modal-btn outline" onclick="closeReceipt()"><i class="bi bi-x"></i> Close</button>
      <button class="modal-btn primary" onclick="window.print()"><i class="bi bi-printer"></i> Print</button>
    </div>
  </div>
</div>

<!-- ══ ADD MONEY MODAL ══ -->
<div class="modal-overlay" id="addMoneyOverlay">
  <div class="modal-box" style="max-width:400px;">
    <div class="modal-head">
      <div class="modal-logo">SIBS<em>.</em> Wallet</div>
      <div class="modal-title-text">Add Money</div>
    </div>
    <div class="modal-body-inner">
      <div style="display:flex;gap:.5rem;flex-wrap:wrap;margin-bottom:1rem;">
        <button class="quick-amt-btn" onclick="setTopupAmount(100)">&#8377;100</button>
        <button class="quick-amt-btn" onclick="setTopupAmount(250)">&#8377;250</button>
        <button class="quick-amt-btn" onclick="setTopupAmount(500)">&#8377;500</button>
        <button class="quick-amt-btn" onclick="setTopupAmount(1000)">&#8377;1000</button>
      </div>
      <div style="margin-bottom:.75rem;">
        <label class="field-label">Enter Amount (&#8377;)</label>
        <input type="number" id="addMoneyAmount" class="field-input" min="10" max="50000" placeholder="e.g. 500"
          oninput="updatePayBtn()">
        <div id="addMoneyError" class="error-msg"></div>
      </div>
      <div class="field-hint"><i class="bi bi-shield-lock-fill" style="color:var(--green);"></i> Secure via Razorpay &middot; Min &#8377;10 &middot; Max &#8377;50,000</div>
    </div>
    <div class="modal-footer">
      <button class="modal-btn outline" onclick="closeAddMoneyModal()"><i class="bi bi-x"></i> Cancel</button>
      <button class="modal-btn primary" id="proceedPayBtn" onclick="startWalletTopup()" disabled style="opacity:.45;">
        <i class="bi bi-credit-card-fill"></i> Pay &amp; Add
      </button>
    </div>
  </div>
</div>

<!-- ══ WITHDRAW MODAL ══ -->
<div class="modal-overlay" id="withdrawOverlay">
  <div class="modal-box" style="max-width:420px;">
    <div class="modal-head" style="background:linear-gradient(135deg,#0d3b1e,#1a1a2e);">
      <div class="modal-logo">SIBS<em>.</em> Wallet</div>
      <div class="modal-title-text">Withdraw Money</div>
      <div style="font-size:.78rem;color:rgba(255,255,255,.5);margin-top:.3rem;">Available: <span id="wdAvail">&#8377;<%= String.format("%.2f", walletBalance) %></span></div>
    </div>
    <div class="modal-body-inner">
      <!-- Amount -->
      <div style="margin-bottom:.85rem;">
        <label class="field-label">Withdrawal Amount (&#8377;)</label>
        <input type="number" id="wdAmount" class="field-input" min="10" max="200000" placeholder="e.g. 500"
          oninput="updateWdBtn()">
        <div id="wdAmountError" class="error-msg"></div>
      </div>
      <!-- Destination tabs -->
      <div class="withdraw-tabs">
        <button class="wtab active" id="tabUpi"  onclick="switchWdTab('upi')"><i class="bi bi-phone"></i> UPI</button>
        <button class="wtab"        id="tabBank" onclick="switchWdTab('bank')"><i class="bi bi-bank"></i> Bank Transfer</button>
      </div>
      <!-- UPI Panel -->
      <div id="panelUpi">
        <label class="field-label">UPI ID</label>
        <input type="text" id="wdUpiId" class="field-input" placeholder="yourname@upi" oninput="updateWdBtn()">
        <div id="wdUpiError" class="error-msg"></div>
      </div>
      <!-- Bank Panel -->
      <div id="panelBank" style="display:none;">
        <div style="margin-bottom:.6rem;">
          <label class="field-label">Account Holder Name</label>
          <input type="text" id="wdAccName" class="field-input" style="height:38px;" placeholder="Full name" oninput="updateWdBtn()">
        </div>
        <div style="margin-bottom:.6rem;">
          <label class="field-label">Account Number</label>
          <input type="text" id="wdAccNo" class="field-input" style="height:38px;" placeholder="1234567890" oninput="updateWdBtn()">
        </div>
        <div>
          <label class="field-label">IFSC Code</label>
          <input type="text" id="wdIfsc" class="field-input" style="height:38px;" placeholder="ABCD0001234" oninput="updateWdBtn()" style="text-transform:uppercase;">
        </div>
        <div id="wdBankError" class="error-msg"></div>
      </div>
      <!-- Note -->
      <div style="margin-top:.75rem;">
        <label class="field-label" style="margin-bottom:.3rem;">Note (optional)</label>
        <input type="text" id="wdNote" class="field-input" style="height:36px;" placeholder="e.g. Withdrawal to savings account" maxlength="100">
      </div>
      <div class="field-hint" style="margin-top:.75rem;">
        <i class="bi bi-info-circle-fill" style="color:var(--blue);"></i>
        Processed within 1–3 business days. Min &#8377;10.
      </div>
    </div>
    <div class="modal-footer">
      <button class="modal-btn outline" onclick="closeWithdrawModal()"><i class="bi bi-x"></i> Cancel</button>
      <button class="modal-btn success" id="wdSubmitBtn" onclick="submitWithdraw()" disabled style="opacity:.45;">
        <i class="bi bi-bank"></i> Withdraw
      </button>
    </div>
  </div>
</div>

<div class="toast-hub" id="toastHub"></div>

<script>
const contextPath = '<%= request.getContextPath() %>';
const currentBalance = <%= walletBalance %>;

/* ── Chart ── */
<% if (!monthlySpending.isEmpty()) { %>
(function() {
  var ctx = document.getElementById('spendingChart');
  if (!ctx) return;
  new Chart(ctx, {
    type: 'bar',
    data: {
      labels: <%= chartLabels %>,
      datasets: [{
        label: 'Spending (\u20b9)',
        data: <%= chartAmounts %>,
        backgroundColor: 'rgba(255,71,87,.18)',
        borderColor: '#ff4757',
        borderWidth: 2,
        borderRadius: 8,
        borderSkipped: false
      }]
    },
    options: {
      responsive: true, maintainAspectRatio: false,
      plugins: { legend: { display: false } },
      scales: {
        x: { grid: { display: false }, ticks: { font: { family: 'Inter', size: 11 } } },
        y: {
          grid: { color: 'rgba(0,0,0,.05)' },
          ticks: {
            font: { family: 'Inter', size: 11 },
            callback: function(v) { return '\u20b9' + v.toLocaleString('en-IN'); }
          }
        }
      }
    }
  });
})();
<% } %>

/* ── Toast ── */
function toast(msg, color) {
  var hub = document.getElementById('toastHub');
  var el  = document.createElement('div');
  el.className = 'toast-msg';
  if (color) el.style.background = color;
  el.innerHTML = msg;
  hub.appendChild(el);
  setTimeout(function() { el.remove(); }, 3400);
}

/* ── Update hero balance display ── */
function updateHeroBalance(newBal) {
  var el = document.getElementById('heroBalance');
  if (el) el.textContent = '\u20b9' + parseFloat(newBal).toFixed(2);
  /* Also update withdraw modal available amount */
  var avail = document.getElementById('wdAvail');
  if (avail) avail.textContent = '\u20b9' + parseFloat(newBal).toFixed(2);
}

/* ── Client-side filter ── */
function filterTxn() {
  var q      = (document.getElementById('txnSearch').value || '').toLowerCase();
  var type   = document.getElementById('txnTypeFilter').value;
  var status = document.getElementById('txnStatusFilter').value;
  var visible = 0;
  document.querySelectorAll('#txnTableBody tr[data-type]').forEach(function(row) {
    var matchQ    = (row.dataset.desc  || '').includes(q) || (row.dataset.txnid || '').includes(q);
    var matchType = type   === 'all' || row.dataset.type   === type;
    var matchStat = status === 'all' || row.dataset.status === status;
    var show = matchQ && matchType && matchStat;
    row.style.display = show ? '' : 'none';
    if (show) visible++;
  });
  var el = document.getElementById('txnCount');
  if (el) el.textContent = visible + ' records';
}
function applyServerFilter() {
  var type   = document.getElementById('txnTypeFilter').value;
  var status = document.getElementById('txnStatusFilter').value;
  var date   = document.getElementById('txnDate').value;
  var url = 'CustomerWallet?page=1';
  if (type   && type   !== 'all') url += '&txnType=' + type;
  if (status && status !== 'all') url += '&status='  + status;
  if (date)                       url += '&dateFrom=' + date;
  window.location.href = url;
}
function resetFilters() { window.location.href = 'CustomerWallet'; }
document.getElementById('txnSearch').addEventListener('input', filterTxn);
document.getElementById('txnTypeFilter').addEventListener('change', applyServerFilter);
document.getElementById('txnStatusFilter').addEventListener('change', applyServerFilter);

/* ── Receipt modal ── */
function openReceipt(txnId, orderId, type, desc, amount, status, date, method, balance) {
  document.getElementById('r-txnid').textContent  = txnId || '\u2014';
  document.getElementById('r-order').textContent  = orderId;
  document.getElementById('r-type').textContent   = type ? type.charAt(0).toUpperCase() + type.slice(1) : '\u2014';
  document.getElementById('r-desc').textContent   = desc || '\u2014';
  document.getElementById('r-amount').innerHTML   = amount;
  document.getElementById('r-method').textContent = method;
  document.getElementById('r-date').textContent   = date;
  document.getElementById('r-bal').innerHTML      = balance;
  var chip = document.getElementById('r-chip');
  chip.textContent = status;
  chip.className = 'chip ' + (status === 'success' ? 'chip-success' : status === 'pending' ? 'chip-pending' : 'chip-failed');
  document.getElementById('receiptOverlay').classList.add('open');
  document.body.style.overflow = 'hidden';
}
function closeReceipt() {
  document.getElementById('receiptOverlay').classList.remove('open');
  document.body.style.overflow = '';
}
document.getElementById('receiptOverlay').addEventListener('click', function(e) {
  if (e.target === this) closeReceipt();
});

/* ══════════════════════════════════════════════════════════
   ADD MONEY / WALLET TOP-UP
═══════════════════════════════════════════════════════════ */
function openAddMoneyModal() {
  document.getElementById('addMoneyAmount').value = '';
  document.getElementById('addMoneyError').style.display = 'none';
  var btn = document.getElementById('proceedPayBtn');
  btn.disabled = true; btn.style.opacity = '.45';
  document.getElementById('addMoneyOverlay').classList.add('open');
  document.body.style.overflow = 'hidden';
}
function closeAddMoneyModal() {
  document.getElementById('addMoneyOverlay').classList.remove('open');
  document.body.style.overflow = '';
}
document.getElementById('addMoneyOverlay').addEventListener('click', function(e) {
  if (e.target === this) closeAddMoneyModal();
});
function setTopupAmount(amt) {
  document.getElementById('addMoneyAmount').value = amt;
  updatePayBtn();
}
function updatePayBtn() {
  var val = parseFloat(document.getElementById('addMoneyAmount').value);
  var btn = document.getElementById('proceedPayBtn');
  var err = document.getElementById('addMoneyError');
  if (val >= 10 && val <= 50000) {
    btn.disabled = false; btn.style.opacity = '1'; err.style.display = 'none';
  } else {
    btn.disabled = true; btn.style.opacity = '.45';
    if (document.getElementById('addMoneyAmount').value !== '') {
      err.textContent = val < 10 ? 'Minimum amount is \u20b910' : 'Maximum amount is \u20b950,000';
      err.style.display = 'block';
    }
  }
}
function startWalletTopup() {
  var amount = parseFloat(document.getElementById('addMoneyAmount').value);
  if (!amount || amount < 10 || amount > 50000) return;
  var btn = document.getElementById('proceedPayBtn');
  btn.disabled = true;
  btn.innerHTML = '<i class="bi bi-hourglass-split"></i> Creating order\u2026';
  fetch(contextPath + '/WalletTopupServlet', {
    method: 'POST',
    headers: { 'X-Requested-With': 'XMLHttpRequest', 'Content-Type': 'application/x-www-form-urlencoded' },
    body: 'amount=' + Math.round(amount * 100)
  })
  .then(function(r) {
    if (!r.ok) throw new Error('HTTP ' + r.status);
    return r.json();
  })
  .then(function(order) {
    if (!order.razorpayOrderId) throw new Error(order.message || 'Order creation failed');
    var options = {
      key: order.razorpayKey,
      amount: order.amount,
      currency: 'INR',
      name: 'SIBS Store',
      description: 'Wallet Top-up',
      order_id: order.razorpayOrderId,
      theme: { color: '#0d0d14' },
      handler: function(response) {
        fetch(contextPath + '/WalletTopupServlet', {
          method: 'POST',
          headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'X-Requested-With': 'XMLHttpRequest' },
          body: 'action=verify'
               + '&razorpay_payment_id=' + encodeURIComponent(response.razorpay_payment_id)
               + '&razorpay_order_id='   + encodeURIComponent(response.razorpay_order_id)
               + '&razorpay_signature='  + encodeURIComponent(response.razorpay_signature)
               + '&amount=' + Math.round(amount * 100)
        })
        .then(function(r) { if (!r.ok) throw new Error('HTTP ' + r.status); return r.json(); })
        .then(function(result) {
          document.getElementById('addMoneyOverlay').classList.remove('open');
          document.body.style.overflow = '';
          if (result.success) {
            /* BUG FIX: update hero balance immediately from server response */
            updateHeroBalance(result.newBalance);
            toast('<i class="bi bi-check-circle-fill"></i> \u20b9' + amount.toFixed(2) + ' added to wallet!', '#16a34a');
            setTimeout(function() { window.location.reload(); }, 1800);
          } else {
            toast('<i class="bi bi-x-circle-fill"></i> ' + (result.message || 'Verification failed'), '#ff4757');
          }
        })
        .catch(function() {
          document.getElementById('addMoneyOverlay').classList.remove('open');
          document.body.style.overflow = '';
          toast('<i class="bi bi-x-circle-fill"></i> Payment verification failed. Contact support.', '#ff4757');
        });
      },
      modal: {
        ondismiss: function() {
          btn.disabled = false;
          btn.innerHTML = '<i class="bi bi-credit-card-fill"></i> Pay &amp; Add';
          document.getElementById('addMoneyOverlay').classList.add('open');
          document.body.style.overflow = 'hidden';
          toast('<i class="bi bi-info-circle"></i> Payment cancelled', '#f59e0b');
        }
      }
    };
    document.getElementById('addMoneyOverlay').classList.remove('open');
    document.body.style.overflow = '';
    new Razorpay(options).open();
  })
  .catch(function(err) {
    btn.disabled = false;
    btn.innerHTML = '<i class="bi bi-credit-card-fill"></i> Pay &amp; Add';
    toast('<i class="bi bi-x-circle-fill"></i> ' + (err.message || 'Could not initiate payment'), '#ff4757');
  });
}

/* ══════════════════════════════════════════════════════════
   WITHDRAWAL
═══════════════════════════════════════════════════════════ */
var wdMode = 'upi'; // 'upi' | 'bank'

function openWithdrawModal() {
  document.getElementById('wdAmount').value  = '';
  document.getElementById('wdUpiId').value   = '';
  document.getElementById('wdAccName').value = '';
  document.getElementById('wdAccNo').value   = '';
  document.getElementById('wdIfsc').value    = '';
  document.getElementById('wdNote').value    = '';
  ['wdAmountError','wdUpiError','wdBankError'].forEach(function(id) {
    document.getElementById(id).style.display = 'none';
  });
  var btn = document.getElementById('wdSubmitBtn');
  btn.disabled = true; btn.style.opacity = '.45';
  switchWdTab('upi');
  document.getElementById('withdrawOverlay').classList.add('open');
  document.body.style.overflow = 'hidden';
}
function closeWithdrawModal() {
  document.getElementById('withdrawOverlay').classList.remove('open');
  document.body.style.overflow = '';
}
document.getElementById('withdrawOverlay').addEventListener('click', function(e) {
  if (e.target === this) closeWithdrawModal();
});

function switchWdTab(mode) {
  wdMode = mode;
  document.getElementById('tabUpi').classList.toggle('active',  mode === 'upi');
  document.getElementById('tabBank').classList.toggle('active', mode === 'bank');
  document.getElementById('panelUpi').style.display  = mode === 'upi'  ? '' : 'none';
  document.getElementById('panelBank').style.display = mode === 'bank' ? '' : 'none';
  updateWdBtn();
}

function updateWdBtn() {
  var amount = parseFloat(document.getElementById('wdAmount').value);
  var btn = document.getElementById('wdSubmitBtn');
  var amtErr = document.getElementById('wdAmountError');

  /* Validate amount */
  var amtOk = false;
  if (!isNaN(amount) && document.getElementById('wdAmount').value !== '') {
    if (amount < 10) {
      amtErr.textContent = 'Minimum withdrawal is \u20b910'; amtErr.style.display = 'block';
    } else if (amount > 200000) {
      amtErr.textContent = 'Maximum withdrawal is \u20b92,00,000'; amtErr.style.display = 'block';
    } else if (amount > currentBalance) {
      amtErr.textContent = 'Insufficient balance (available: \u20b9' + currentBalance.toFixed(2) + ')';
      amtErr.style.display = 'block';
    } else {
      amtErr.style.display = 'none'; amtOk = true;
    }
  } else {
    amtErr.style.display = 'none';
  }

  /* Validate destination */
  var destOk = false;
  if (wdMode === 'upi') {
    var upi = document.getElementById('wdUpiId').value.trim();
    /* Basic UPI format: something@something */
    destOk = /^[a-zA-Z0-9.\-_]+@[a-zA-Z0-9]+$/.test(upi);
  } else {
    var acc  = document.getElementById('wdAccNo').value.trim();
    var ifsc = document.getElementById('wdIfsc').value.trim();
    destOk = acc.length >= 9 && /^[A-Z]{4}0[A-Z0-9]{6}$/i.test(ifsc);
  }

  var ok = amtOk && destOk;
  btn.disabled = !ok;
  btn.style.opacity = ok ? '1' : '.45';
}

function submitWithdraw() {
  var amount  = parseFloat(document.getElementById('wdAmount').value);
  var note    = document.getElementById('wdNote').value.trim();
  var btn     = document.getElementById('wdSubmitBtn');
  if (!amount || amount < 10) return;

  btn.disabled = true;
  btn.innerHTML = '<i class="bi bi-hourglass-split"></i> Processing\u2026';

  var body = 'amount=' + amount;
  if (wdMode === 'upi') {
    body += '&upiId=' + encodeURIComponent(document.getElementById('wdUpiId').value.trim());
  } else {
    body += '&accountNo='   + encodeURIComponent(document.getElementById('wdAccNo').value.trim());
    body += '&ifsc='        + encodeURIComponent(document.getElementById('wdIfsc').value.trim().toUpperCase());
    body += '&accountName=' + encodeURIComponent(document.getElementById('wdAccName').value.trim());
  }
  if (note) body += '&note=' + encodeURIComponent(note);

  fetch(contextPath + '/WalletWithdrawServlet', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'X-Requested-With': 'XMLHttpRequest' },
    body: body
  })
  .then(function(r) { if (!r.ok) throw new Error('HTTP ' + r.status); return r.json(); })
  .then(function(result) {
    closeWithdrawModal();
    if (result.success) {
      updateHeroBalance(result.newBalance);
      toast('<i class="bi bi-check-circle-fill"></i> ' + (result.message || 'Withdrawal requested!'), '#16a34a');
      setTimeout(function() { window.location.reload(); }, 2200);
    } else {
      toast('<i class="bi bi-x-circle-fill"></i> ' + (result.message || 'Withdrawal failed'), '#ff4757');
      btn.disabled = false;
      btn.innerHTML = '<i class="bi bi-bank"></i> Withdraw';
    }
  })
  .catch(function(err) {
    closeWithdrawModal();
    toast('<i class="bi bi-x-circle-fill"></i> ' + (err.message || 'Server error'), '#ff4757');
    btn.disabled = false;
    btn.innerHTML = '<i class="bi bi-bank"></i> Withdraw';
  });
}
</script>

<jsp:include page="customerBottomNav.jsp"><jsp:param name="activePage" value=""/></jsp:include>
</body>
</html>
