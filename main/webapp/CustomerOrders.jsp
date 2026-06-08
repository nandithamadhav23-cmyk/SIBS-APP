<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List, java.util.ArrayList, com.util.*" %>
<%
    List<Order> orders = (List<Order>) request.getAttribute("orders");
    if (orders == null) orders = new ArrayList<>();
    Customer customer = (Customer) session.getAttribute("customer");
    Boolean loggedIn  = (Boolean)  session.getAttribute("loggedIn");
    Integer totalProducts = (Integer) session.getAttribute("cartCount");

    String custName    = (customer != null && customer.getName()  != null) ? customer.getName()  : "Guest";
    String custEmail   = (customer != null && customer.getEmail() != null) ? customer.getEmail() : "";
    String custInitial = custName.length() > 0 ? String.valueOf(custName.charAt(0)).toUpperCase() : "G";
%>
<%!
    private long daysSinceDelivery(java.util.Date deliveryDate) {
        if (deliveryDate == null) return -1;
        long diff = System.currentTimeMillis() - deliveryDate.getTime();
        return diff / (1000L * 60 * 60 * 24);
    }
    private boolean isReturnEligible(java.util.Date deliveryDate) {
        long days = daysSinceDelivery(deliveryDate);
        return days >= 0 && days <= 10;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>My Orders — SIBS Store</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
<link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=Sora:wght@300;400;500;600;700;800&family=Space+Mono:wght@400;700&display=swap" rel="stylesheet">
      <jsp:include page="aiChatWidget.jsp" />

<style>
  :root {
    --navy:        #ffffff;
    --navy-mid:    #f8f6f1;
    --navy-card:   #f2ede4;
      --accent: #8b5cf6;
    --accent-glow: rgba(139,26,26,0.10);
    --accent-soft: #fff5f5;
    --indigo:      #2c3e7a;
    --gold:        #7a5c00;
    --gold-bg:     rgba(122,92,0,0.08);
    --success:     #1a6b3a;
    --success-bg:  rgba(26,107,58,0.08);
    --danger:      #9b1c1c;
    --danger-bg:   rgba(155,28,28,0.08);
    --warning:     #8c4a00;
    --warning-bg:  rgba(140,74,0,0.08);
    --purple:      #4c2d8a;
    --purple-bg:   rgba(76,45,138,0.08);
    --sky:         #0e5a8a;
    --sky-bg:      rgba(14,90,138,0.08);
    --teal:        #0e6b5e;
    --teal-bg:     rgba(14,107,94,0.08);
    --text:        #1a1410;
    --text-mid:    #4a3f35;
    --text-soft:   #7a6d62;
    --border:      rgba(0,0,0,0.10);
    --border-soft: rgba(0,0,0,0.05);
      --bg: #f0f9ff;
    --bg-card:     #faf8f4;
    --bg-card2:    #f2ede4;
    --nav-h:       62px;
    --radius:      6px;
    --radius-sm:   4px;
    --shadow:      0 1px 3px rgba(0,0,0,0.08), 0 4px 12px rgba(0,0,0,0.06);
    --shadow-h:    0 6px 24px rgba(0,0,0,0.12);
  }

  *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
  body {
 font-family: 'DM Sans', sans-serif;
     background: var(--bg);
    color: var(--text);
    padding-top: var(--nav-h);
    min-height: 100vh;
    font-size: 18px;
  }
  @media(max-width:768px){ body { padding-bottom: 70px; } }
  ::-webkit-scrollbar { width: 5px; height: 5px; }
  ::-webkit-scrollbar-track { background: transparent; }
  ::-webkit-scrollbar-thumb { background: #c8bfb5; border-radius: 10px; }

  /* ── NAVBAR ── */
  .top-nav {
    position: fixed; top: 0; left: 0; right: 0; z-index: 1000;
    height: var(--nav-h);
    background: rgba(255,255,255,0.97);
    backdrop-filter: blur(8px);
    border-bottom: 1px solid var(--border);
    display: flex; align-items: center;
    padding: 0 1.5rem; gap: 1rem;
    box-shadow: 0 1px 6px rgba(0,0,0,0.06);
  }
  .nav-brand {
    font-family:'DM Sans', sans-serif;
    font-size: 1.1rem; font-weight: 700; color: var(--text);
    text-decoration: none; display: flex; align-items: center; gap: 0.5rem;
    letter-spacing: 0.02em;
  }
  .nav-brand .dot { color: var(--accent); }
  .nav-right { margin-left: auto; display: flex; align-items: center; gap: 0.6rem; }
  .nav-icon {
    background: transparent; border: 1px solid var(--border);
    border-radius: var(--radius-sm); color: var(--text-mid);
    width: 38px; height: 38px; display: flex; align-items: center;
    justify-content: center; cursor: pointer; text-decoration: none; font-size: 1rem;
    position: relative; transition: all 0.2s;
  }
  .nav-icon:hover { border-color: var(--accent); color: var(--accent); }
  .nav-icon.active-nav { border-color: var(--accent); color: var(--accent); background: var(--accent-glow); }
  .nav-badge {
    position: absolute; top: -5px; right: -5px;
    background: var(--accent); color: #fff; font-size: 0.6rem; font-weight: 700;
    width: 17px; height: 17px; border-radius: 50%;
    display: flex; align-items: center; justify-content: center;
    border: 2px solid var(--bg);
  }
  .nav-profile-btn {
    display: flex; align-items: center; gap: 0.6rem;
    background: var(--bg-card); border: 1px solid var(--border);
    border-radius: 30px; padding: 4px 12px 4px 4px;
    cursor: pointer; color: var(--text); transition: all 0.2s;
  }
  .nav-profile-btn:hover { border-color: var(--accent); }
  .nav-avatar {
    width: 30px; height: 30px; border-radius: 50%;
    background: linear-gradient(135deg, var(--accent), #4c2d8a);
    display: flex; align-items: center; justify-content: center;
    font-weight: 700; font-size: 0.8rem; color: #fff;
  }
  .nav-name { font-size: 0.82rem; font-weight: 500; color: var(--text-mid); }
  .nav-text-btn {
    background: transparent; border: 1px solid var(--border);
    border-radius: var(--radius-sm); color: var(--text-mid);
    padding: 0.4rem 0.9rem; font-size: 0.8rem; font-weight: 500;
    text-decoration: none; transition: all 0.2s;
    font-family: 'DM Sans', sans-serif;
  }
  .nav-text-btn:hover { border-color: var(--accent); color: var(--accent); }

  /* ── PAGE WRAP ── */
  .page-wrap { max-width: 1200px; margin: 0 auto; padding: 2rem 1.25rem 5rem; }

  /* ── PAGE HEADER ── */
  .page-header {
    display: flex; align-items: center; justify-content: space-between;
    flex-wrap: wrap; gap: 0.75rem; margin-bottom: 1.5rem;
  }
  .page-title {
    font-family:'DM Sans', sans-serif;
    font-size: 1.5rem; font-weight: 700; color: var(--text);
    display: flex; align-items: center; gap: 0.6rem;
    letter-spacing: 0.01em;
  }
  .page-title::before {
    content: ''; display: inline-block; width: 3px; height: 1em;
    background: var(--accent); border-radius: 1px;
  }
  .order-count-badge {
    background: var(--accent-glow); border: 1px solid rgba(139,26,26,0.25);
    color: var(--accent); font-size: 0.73rem; font-weight: 700;
    padding: 3px 12px; border-radius: 3px;
  }
  .btn-shop {
    display: inline-flex; align-items: center; gap: 0.4rem;
    background: transparent; color: var(--text-mid);
    border: 1px solid var(--border); border-radius: var(--radius-sm);
    padding: 0.45rem 1rem; font-size: 0.85rem; font-weight: 500;
    text-decoration: none; transition: all 0.18s;
    font-family: 'DM Sans', sans-serif;
  }
  .btn-shop:hover { border-color: var(--accent); color: var(--accent); }

  /* ── FILTER CHIPS ── */
  .filter-bar {
    display: flex; gap: 0.4rem; flex-wrap: wrap;
    background: var(--bg-card); border: 1px solid var(--border);
    border-radius: var(--radius); padding: 0.7rem 0.9rem;
    margin-bottom: 1.25rem; box-shadow: var(--shadow);
  }
  .filter-btn {
    font-family: 'DM Sans', sans-serif;
    border: 1px solid var(--border); background: transparent;
    color: var(--text-soft); padding: 0.3rem 0.9rem;
    border-radius: 3px; font-size: 0.82rem; font-weight: 500;
    cursor: pointer; transition: all 0.18s;
  }
  .filter-btn:hover { border-color: var(--accent); color: var(--accent); }
  .filter-btn.active { background: var(--accent); color: #fff; border-color: var(--accent); }

  /* ── ORDER CARD ── */
  .order-card {
    background: var(--bg-card); border: 1px solid var(--border);
    border-radius: var(--radius); margin-bottom: 1.1rem;
    overflow: hidden; box-shadow: var(--shadow);
    transition: box-shadow 0.22s, transform 0.22s, border-color 0.22s;
    animation: fadeUp 0.3s ease both;
  }
  .order-card:hover { box-shadow: var(--shadow-h); transform: translateY(-1px); border-color: rgba(0,0,0,0.18); }
  @keyframes fadeUp { from{opacity:0;transform:translateY(10px);}to{opacity:1;transform:translateY(0);} }

  /* ── CARD STRIP ── */
  .order-strip {
    background: var(--navy-card); padding: 0.85rem 1.25rem;
    display: flex; align-items: center; justify-content: space-between;
    flex-wrap: wrap; gap: 0.6rem;
    border-bottom: 1px solid var(--border);
  }
  .order-id {
    font-family: 'Courier New', Courier, monospace;
    font-size: 0.9rem; font-weight: 700; color: var(--text);
    display: flex; align-items: center; gap: 0.4rem;
  }
  .order-date { font-size: 0.73rem; color: var(--text-soft); margin-top: 3px; display: flex; align-items: center; gap: 0.3rem; }
  .strip-right { display: flex; align-items: center; gap: 0.45rem; flex-wrap: wrap; }

  .otp-box {
    background: var(--gold-bg); border: 1px solid rgba(122,92,0,0.28);
    border-radius: var(--radius-sm); padding: 3px 10px;
    font-size: 0.75rem; color: var(--gold); font-weight: 700;
    display: flex; align-items: center; gap: 0.35rem; font-family: 'Courier New', Courier, monospace;
  }

  /* ── STATUS BADGES ── */
  .status-badge {
    font-size: 0.65rem; font-weight: 700; letter-spacing: 0.06em;
    text-transform: uppercase; padding: 3px 10px; border-radius: 3px;
    border: 1px solid; display: inline-flex; align-items: center; gap: 0.3rem;
    font-family:'DM Sans', sans-serif;
  }
  .badge-ordered      { background:var(--sky-bg);         color:var(--sky);     border-color:rgba(14,90,138,0.25); }
  .badge-pending      { background:var(--gold-bg);        color:var(--gold);    border-color:rgba(122,92,0,0.25); }
  .badge-confirmed    { background:rgba(44,62,122,0.08);  color:var(--indigo);  border-color:rgba(44,62,122,0.25); }
  .badge-assigned     { background:var(--teal-bg);        color:var(--teal);    border-color:rgba(14,107,94,0.25); }
  .badge-pickedup     { background:rgba(76,45,138,0.08);  color:var(--purple);  border-color:rgba(76,45,138,0.25); }
  .badge-packed       { background:var(--sky-bg);         color:var(--sky);     border-color:rgba(14,90,138,0.25); }
  .badge-shipped      { background:var(--success-bg);     color:var(--success); border-color:rgba(26,107,58,0.25); }
  .badge-ofd          { background:var(--warning-bg);     color:var(--warning); border-color:rgba(140,74,0,0.25); }
  .badge-delivered    { background:var(--success-bg);     color:var(--success); border-color:rgba(26,107,58,0.25); }
  .badge-cancelled    { background:var(--danger-bg);      color:var(--danger);  border-color:rgba(155,28,28,0.25); }
  .badge-paid         { background:var(--success-bg);     color:var(--success); border-color:rgba(26,107,58,0.25); }
  .badge-failed       { background:var(--danger-bg);      color:var(--danger);  border-color:rgba(155,28,28,0.25); }
  .badge-pending-cod  { background:var(--gold-bg);        color:var(--gold);    border-color:rgba(122,92,0,0.25); }
  .badge-processing   { background:rgba(44,62,122,0.08);  color:var(--indigo);  border-color:rgba(44,62,122,0.25); }
  .badge-refunded     { background:var(--success-bg);     color:var(--success); border-color:rgba(26,107,58,0.25); }
  .badge-replaced     { background:var(--teal-bg);        color:var(--teal);    border-color:rgba(14,107,94,0.25); }

  /* ── CARD BODY ── */
  .order-body { padding: 1rem 1.25rem 0; }

  /* ── PAYMENT ALERTS ── */
  .payment-alert {
    border-radius: var(--radius-sm); padding: 0.7rem 0.9rem;
    margin-bottom: 0.85rem; font-size: 0.82rem;
    display: flex; align-items: flex-start; gap: 0.6rem; border-left: 3px solid;
  }
  .payment-alert i { font-size: 1rem; flex-shrink: 0; margin-top: 1px; }
  .payment-alert strong { display: block; margin-bottom: 1px; }
  .payment-success     { background:rgba(26,107,58,0.06);  border-color:var(--success); color:#1a6b3a; }
  .payment-failed      { background:rgba(155,28,28,0.06);  border-color:var(--danger);  color:#9b1c1c; }
  .payment-pending     { background:var(--gold-bg);        border-color:var(--gold);    color:#7a5c00; }
  .payment-interrupted { background:rgba(140,74,0,0.06);   border-color:var(--warning); color:#8c4a00; }

  .alert-otp {
    background: var(--gold-bg); border: 1px solid rgba(122,92,0,0.2);
    border-radius: var(--radius-sm); padding: 0.55rem 0.85rem; margin-bottom: 0.75rem;
    font-size: 0.8rem; color: var(--gold); display: flex; align-items: center; gap: 0.5rem;
  }
  .alert-delivered {
    background: var(--success-bg); border: 1px solid rgba(26,107,58,0.2);
    border-radius: var(--radius-sm); padding: 0.55rem 0.85rem; margin-bottom: 0.75rem;
    font-size: 0.8rem; color: var(--success); display: flex; align-items: center; gap: 0.5rem;
  }

  /* ── DELIVERY TRACKER ── */
  /*
   * TRACKER FIX:
   * Steps: Ordered(1) → Confirmed(2) → Assigned(3) → Picked Up(4) → Packed(5) → Shipped(6) → Out for Delivery(7) → Delivered(8)
   * Progress bar width uses step index correctly so it STOPS at the active step, never runs past Delivered.
   * Cancelled/return orders never render this tracker.
   */
  .tracker {
    display: flex; align-items: flex-start; justify-content: space-between;
    position: relative; margin: 0.75rem 0 0.75rem; padding-bottom: 0.5rem;
    overflow-x: auto;
  }
  .tracker::before {
    content: ''; position: absolute; top: 14px; left: 2%; right: 2%;
    height: 1px; background: var(--border); z-index: 0;
  }
  /* BUG FIX: progress bar must never exceed width of (step-1)/(total-1) * 88% so it stops AT the last step dot */
  .tracker-progress {
    position: absolute; top: 14px; left: 2%; height: 1px;
    background: var(--accent);
    z-index: 1; transition: width 1s ease; width: 0;
  }
  .tracker-step { display: flex; flex-direction: column; align-items: center; flex: 1; position: relative; z-index: 2; min-width: 52px; }
  .step-circle {
    width: 28px; height: 28px; border-radius: 50%;
    border: 1.5px solid var(--border); background: var(--bg);
    display: flex; align-items: center; justify-content: center;
    font-size: 0.75rem; color: var(--text-soft); transition: all 0.35s; margin-bottom: 5px;
  }
  .step-circle.done   { background: var(--success); border-color: var(--success); color: #fff; }
  .step-circle.active { background: var(--accent);  border-color: var(--accent);  color: #fff; box-shadow: 0 0 0 3px var(--accent-glow); }
  .step-circle.fail   { background: var(--danger);  border-color: var(--danger);  color: #fff; }
  .step-label { font-size: 0.58rem; color: var(--text-soft); text-align: center; line-height: 1.3; }
  .step-label.done   { color: var(--success); font-weight: 700; }
  .step-label.active { color: var(--accent);  font-weight: 700; }

  /* ── STATUS STAGE INFO BAR ── */
  .stage-info-bar {
    display: flex; align-items: center; gap: 0.5rem;
    padding: 0.5rem 0.75rem; border-radius: var(--radius-sm);
    font-size: 0.78rem; margin-bottom: 0.65rem;
    border-left: 3px solid;
  }
  .stage-bar-ordered    { background:var(--sky-bg);      border-color:var(--sky);     color:var(--sky); }
  .stage-bar-confirmed  { background:rgba(44,62,122,0.07); border-color:var(--indigo); color:var(--indigo); }
  .stage-bar-assigned   { background:var(--teal-bg);     border-color:var(--teal);    color:var(--teal); }
  .stage-bar-pickedup   { background:var(--purple-bg);   border-color:var(--purple);  color:var(--purple); }
  .stage-bar-packed     { background:var(--sky-bg);      border-color:var(--sky);     color:var(--sky); }
  .stage-bar-shipped    { background:var(--success-bg);  border-color:var(--success); color:var(--success); }
  .stage-bar-ofd        { background:var(--warning-bg);  border-color:var(--warning); color:var(--warning); }
  .stage-bar-delivered  { background:var(--success-bg);  border-color:var(--success); color:var(--success); }

  /* ── DELIVERY INFO ROW ── */
  .delivery-info {
    display: flex; gap: 1.25rem; flex-wrap: wrap;
    font-size: 0.78rem; color: var(--text-soft);
    padding: 0.5rem 0 0.75rem; border-bottom: 1px solid var(--border-soft);
    margin-bottom: 0.75rem;
  }
  .delivery-info span { display: flex; align-items: center; gap: 0.35rem; }
  .delivery-info strong { color: var(--text); }

  /* ── PRODUCT PREVIEW ── */
  .product-row {
    display: flex; align-items: center; gap: 0.85rem;
    padding: 0.75rem 0; border-bottom: 1px solid var(--border-soft);
  }
  .product-row:last-child { border-bottom: none; }
  .product-thumb {
    width: 68px; height: 68px; border-radius: var(--radius-sm); object-fit: contain;
    background: var(--bg); border: 1px solid var(--border); padding: 4px; flex-shrink: 0;
  }
  .product-thumb-placeholder {
    width: 68px; height: 68px; border-radius: var(--radius-sm); background: var(--bg-card2);
    border: 1px solid var(--border); display: flex; align-items: center;
    justify-content: center; color: var(--text-soft); font-size: 1.4rem; flex-shrink: 0;
  }
  .product-info { flex: 1; min-width: 0; }
  .product-name { font-weight: 700; font-size: 0.9rem; color: var(--text); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
  .product-meta { font-size: 0.75rem; color: var(--text-soft); margin-top: 3px; }
  .product-price { text-align: right; white-space: nowrap; }
  .product-price .total { font-weight: 700; font-size: 0.95rem; color: var(--success); font-family: 'Courier New', Courier, monospace; }
  .product-price .unit-price { font-size: 0.68rem; color: var(--text-soft); margin-top: 2px; }
  .disc-pill {
    background: var(--accent-glow); color: var(--accent); border: 1px solid rgba(139,26,26,0.2);
    border-radius: 3px; padding: 1px 6px; font-size: 0.65rem; font-weight: 700;
  }
  .more-items-link { font-size: 0.75rem; color: var(--text-soft); padding: 4px 0; display: flex; align-items: center; gap: 0.3rem; }
  .more-items-link a { color: var(--accent); text-decoration: none; font-weight: 600; }
  .more-items-link a:hover { color: var(--text); }

  /* ── ITEMS TABLE (expanded) ── */
  .items-collapse { padding: 0 1.25rem 1rem; }
  .items-table { width: 100%; border-collapse: collapse; font-size: 0.8rem; }
  .items-table thead th {
    background: var(--bg-card2); color: var(--text-soft); padding: 0.55rem 0.75rem;
    font-size: 0.65rem; text-transform: uppercase; letter-spacing: 0.08em;
    font-weight: 700; text-align: left; border-bottom: 1px solid var(--border);
  }
  .items-table tbody td {
    padding: 0.6rem 0.75rem; border-bottom: 1px solid var(--border-soft); vertical-align: middle; color: var(--text);
  }
  .items-table tbody tr:last-child td { border-bottom: none; }
  .items-table tbody tr:hover td { background: rgba(0,0,0,0.02); }

  /* ── ORDER SUMMARY ── */
  .order-summary {
    background: var(--bg-card2); border: 1px solid var(--border);
    border-radius: var(--radius-sm); padding: 0.85rem 1rem; margin-top: 0.85rem; font-size: 0.83rem;
  }
  .summary-row { display: flex; justify-content: space-between; padding: 3px 0; color: var(--text-soft); }
  .summary-row span:last-child { font-weight: 600; color: var(--text); }
  .summary-total {
    font-weight: 700; font-size: 0.95rem; color: var(--text);
    border-top: 1px solid var(--border); margin-top: 6px; padding-top: 7px;
    display: flex; justify-content: space-between;
  }
  .summary-total span:last-child { color: var(--success); font-family: 'Courier New', Courier, monospace; }

  /* ── FOOTER ACTIONS ── */
  .order-footer {
    padding: 0.7rem 1.25rem; border-top: 1px solid var(--border);
    display: flex; align-items: center; gap: 0.45rem; flex-wrap: wrap;
    background: #f5f0e8;
  }
  .btn-action {
    font-family:'DM Sans', sans-serif; font-size: 0.8rem; font-weight: 600;
    padding: 0.35rem 0.85rem; border-radius: var(--radius-sm); text-decoration: none; border: 1px solid;
    cursor: pointer; transition: all 0.18s; display: inline-flex; align-items: center; gap: 0.3rem;
    background: transparent;
  }
  .btn-track         { border-color:rgba(14,90,138,0.3);   color:var(--sky); }
  .btn-track:hover   { background:var(--sky-bg); border-color:var(--sky); }
  .btn-invoice       { border-color:var(--border); color:var(--text-mid); }
  .btn-invoice:hover { background:var(--bg-card2); color:var(--text); }
  .btn-retry         { border-color:rgba(122,92,0,0.3);    color:var(--gold); }
  .btn-retry:hover   { background:var(--gold-bg); border-color:var(--gold); }
  .btn-toggle        { border-color:var(--border); color:var(--text-soft); }
  .btn-toggle:hover  { border-color:var(--accent); color:var(--accent); }
  .btn-cancel-act         { border-color:rgba(155,28,28,0.3);  color:var(--danger); }
  .btn-cancel-act:hover   { background:var(--danger-bg); border-color:var(--danger); }
  .btn-return-act         { border-color:rgba(76,45,138,0.3);  color:var(--purple); background:transparent; }
  .btn-return-act:hover   { background:var(--purple-bg); border-color:var(--purple); }
  .footer-customer { margin-left: auto; font-size: 0.72rem; color: var(--text-soft); display: flex; align-items: center; gap: 0.3rem; }

  /* ── EMPTY STATE ── */
  .empty-state {
    text-align: center; padding: 5rem 2rem; color: var(--text-soft);
    background: var(--bg-card); border: 1px solid var(--border);
    border-radius: var(--radius); box-shadow: var(--shadow);
  }
  .empty-icon { font-size: 3.5rem; display: block; margin-bottom: 1rem; opacity: 0.2; }
  .empty-state h3 { color: var(--text); font-size: 1.2rem; font-weight: 700; margin-bottom: 0.4rem; }

  /* ── RETURN ELIGIBILITY ── */
  .rr-eligibility {
    display: flex; align-items: center; gap: 0.5rem;
    padding: 0.5rem 0.85rem; border-radius: var(--radius-sm);
    font-size: 0.77rem; font-weight: 500; margin: 0.5rem 0 0;
  }
  .rr-window   { background:var(--gold-bg);    color:var(--gold);    border:1px solid rgba(122,92,0,0.22); }
  .rr-expired  { background:var(--danger-bg);  color:var(--danger);  border:1px solid rgba(155,28,28,0.22); }
  .rr-pending  { background:var(--sky-bg);     color:var(--sky);     border:1px solid rgba(14,90,138,0.22); }
  .rr-approved { background:var(--success-bg); color:var(--success); border:1px solid rgba(26,107,58,0.22); }
  .rr-rejected { background:var(--danger-bg);  color:var(--danger);  border:1px solid rgba(155,28,28,0.22); }
  .rr-refunded { background:var(--success-bg); color:var(--success); border:1px solid rgba(26,107,58,0.22); }
  .rr-picked   { background:var(--purple-bg);  color:var(--purple);  border:1px solid rgba(76,45,138,0.22); }
  .rr-processing { background:rgba(44,62,122,0.07); color:var(--indigo); border:1px solid rgba(44,62,122,0.22); }
  .rr-replaced { background:var(--teal-bg);    color:var(--teal);    border:1px solid rgba(14,107,94,0.22); }

  .rr-days-left {
    display: inline-flex; align-items: center; gap: 0.3rem;
    font-size: 0.72rem; padding: 1px 8px; border-radius: 20px; font-weight: 700;
  }
  .rr-days-urgent { background:var(--danger-bg); color:var(--danger); }
  .rr-days-ok     { background:var(--success-bg); color:var(--success); }

  /* ── RETURN TRACKER BLOCK ── */
  .rr-tracker-block {
    margin: 0.75rem 0 0; border: 1px solid rgba(76,45,138,0.18);
    border-radius: var(--radius-sm); background: var(--bg); overflow: hidden;
  }
  .rr-tracker-header {
    display: flex; align-items: center; justify-content: space-between;
    padding: 0.65rem 1rem; background: var(--purple-bg);
    border-bottom: 1px solid rgba(76,45,138,0.15); flex-wrap: wrap; gap: 0.5rem;
  }
  .rr-tracker-title {
    font-size: 0.8rem; font-weight: 700; color: var(--purple);
    display: flex; align-items: center; gap: 0.4rem;
  }
  .rr-type-pill {
    font-size: 0.65rem; font-weight: 700; padding: 2px 8px;
    border-radius: 3px; background: rgba(76,45,138,0.10); color: var(--purple);
    border: 1px solid rgba(76,45,138,0.25);
  }
  .rr-req-id { font-size: 0.68rem; color: var(--text-soft); font-family: 'Courier New', Courier, monospace; }
  .rr-tracker-body { padding: 0.85rem; }

  /* Return steps tracker */
  .rr-steps {
    display: flex; align-items: flex-start; position: relative; margin-bottom: 1rem;
  }
  .rr-step { flex: 1; display: flex; flex-direction: column; align-items: center; position: relative; z-index: 1; }
  .rr-step-line {
    position: absolute; top: 13px; left: 50%; right: -50%;
    height: 1px; background: var(--border); z-index: 0;
  }
  .rr-step-line.done { background: var(--purple); }
  .rr-step:last-child .rr-step-line { display: none; }
  .rr-step-dot {
    width: 26px; height: 26px; border-radius: 50%;
    display: flex; align-items: center; justify-content: center; font-size: 0.65rem; font-weight: 700;
    border: 1.5px solid var(--border); background: var(--bg); color: var(--text-soft);
    position: relative; z-index: 2; transition: all 0.3s;
  }
  .rr-step-dot.done   { background: var(--purple); border-color: var(--purple); color: #fff; }
  .rr-step-dot.active { background: var(--bg);     border-color: var(--purple); color: var(--purple); box-shadow: 0 0 0 3px var(--purple-bg); }
  .rr-step-dot.fail   { background: var(--danger);  border-color: var(--danger); color: #fff; }
  .rr-step-lbl { font-size: 0.62rem; color: var(--text-soft); text-align: center; margin-top: 4px; line-height: 1.3; }
  .rr-step-lbl.active { color: var(--purple); font-weight: 600; }
  .rr-step-lbl.done   { color: var(--success); font-weight: 600; }

  .rr-detail-grid {
    display: grid; grid-template-columns: 1fr 1fr; gap: 0.5rem 1rem;
    font-size: 0.78rem; padding-top: 0.75rem; border-top: 1px solid var(--border);
  }
  .rr-detail-label  { color: var(--text-soft); font-size: 0.68rem; text-transform: uppercase; letter-spacing: 1px; }
  .rr-detail-value  { font-weight: 600; color: var(--text); }
  .rr-detail-full   { grid-column: 1 / -1; }
  .rr-reason-text {
    background: var(--bg-card2); border-radius: var(--radius-sm);
    padding: 0.45rem 0.75rem; font-size: 0.78rem; color: var(--text-mid);
    border: 1px solid var(--border); margin-top: 0.25rem;
  }
  .rr-staff-note {
    background: var(--success-bg); border-radius: var(--radius-sm);
    padding: 0.45rem 0.75rem; font-size: 0.78rem; color: var(--success);
    border: 1px solid rgba(26,107,58,0.2); margin-top: 0.25rem;
    display: flex; align-items: center; gap: 0.4rem;
  }
  .rr-reject-note {
    background: var(--danger-bg); border-radius: var(--radius-sm);
    padding: 0.45rem 0.75rem; font-size: 0.78rem; color: var(--danger);
    border: 1px solid rgba(155,28,28,0.2); margin-top: 0.25rem;
    display: flex; align-items: center; gap: 0.4rem;
  }
  .rr-refund-info {
    display: flex; align-items: center; gap: 0.5rem;
    background: var(--success-bg); border: 1px solid rgba(26,107,58,0.2);
    border-radius: var(--radius-sm); padding: 0.55rem 0.85rem;
    font-size: 0.78rem; color: var(--success); font-weight: 600; margin-top: 0.75rem;
  }

  /* Pickup agent info card */
  .pickup-agent-card {
    background: var(--teal-bg); border: 1px solid rgba(14,107,94,0.22);
    border-radius: var(--radius-sm); padding: 0.55rem 0.85rem;
    font-size: 0.78rem; color: var(--teal); margin-top: 0.5rem;
    display: flex; align-items: center; gap: 0.5rem;
  }

  /* ── RETURN/REPLACE MODAL OVERLAY ── */
  .rr-modal-overlay {
    display: none; position: fixed; inset: 0; z-index: 9000;
    background: rgba(0,0,0,0.45); backdrop-filter: blur(4px);
    align-items: center; justify-content: center; padding: 1rem;
  }
  .rr-modal-overlay.open { display: flex; }
  .rr-modal {
    background: var(--bg-card); border: 1px solid var(--border);
    border-radius: var(--radius); box-shadow: 0 24px 80px rgba(0,0,0,0.18);
    width: 100%; max-width: 520px; max-height: 92vh; overflow-y: auto;
    animation: rrSlideUp 0.22s ease; color: var(--text);
  }
  @keyframes rrSlideUp { from{opacity:0;transform:translateY(20px);}to{opacity:1;transform:translateY(0);} }

  .rr-modal-head {
    display: flex; align-items: center; justify-content: space-between;
    padding: 1rem 1.25rem 0.85rem; border-bottom: 1px solid var(--border);
    background: var(--bg-card2);
  }
  .rr-modal-title { font-size: 0.95rem; font-weight: 700; display: flex; align-items: center; gap: 0.5rem; }
  .rr-close-btn {
    width: 30px; height: 30px; border-radius: 50%; border: 1px solid var(--border);
    background: transparent; cursor: pointer; display: flex; align-items: center;
    justify-content: center; font-size: 0.9rem; color: var(--text-soft); transition: all 0.18s;
  }
  .rr-close-btn:hover { border-color: var(--danger); color: var(--danger); }
  .rr-modal-body { padding: 1.15rem 1.25rem; }

  .rr-policy-box {
    background: var(--gold-bg); border: 1px solid rgba(122,92,0,0.18);
    border-radius: var(--radius-sm); padding: 0.7rem 0.9rem;
    font-size: 0.75rem; color: var(--gold); margin-bottom: 1rem; line-height: 1.6;
  }
  .rr-policy-box strong { display: block; margin-bottom: 3px; color: var(--gold); }

  .rr-type-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 0.65rem; margin-bottom: 1.1rem; }
  .rr-type-card {
    border: 1.5px solid var(--border); border-radius: var(--radius-sm);
    padding: 0.85rem; cursor: pointer; transition: all 0.18s; text-align: center;
    background: var(--bg);
  }
  .rr-type-card:hover { border-color: var(--purple); background: var(--purple-bg); }
  .rr-type-card.selected { border-color: var(--purple); background: var(--purple-bg); }
  .rr-tc-icon  { font-size: 1.5rem; margin-bottom: 0.35rem; }
  .rr-tc-title { font-size: 0.85rem; font-weight: 700; color: var(--text); }
  .rr-tc-desc  { font-size: 0.7rem; color: var(--text-soft); margin-top: 0.2rem; line-height: 1.4; }

  .rr-field { margin-bottom: 0.9rem; }
  .rr-label { display: block; font-size: 0.75rem; font-weight: 600; color: var(--text-mid); margin-bottom: 0.35rem; }
  .rr-label span { color: var(--danger); }
  .rr-select, .rr-textarea {
    width: 100%; padding: 0.5rem 0.75rem;
    border: 1px solid var(--border); border-radius: var(--radius-sm);
    font-size: 0.83rem; color: var(--text); background: var(--bg);
    transition: border-color 0.15s; font-family: 'DM Sans', sans-serif;
  }
  .rr-select:focus, .rr-textarea:focus { outline: none; border-color: var(--purple); box-shadow: 0 0 0 3px var(--purple-bg); }
  .rr-select option { background: var(--bg-card); }
  .rr-textarea { min-height: 85px; resize: vertical; }

  .rr-items-list { display: flex; flex-direction: column; gap: 0.45rem; }
  .rr-item-check {
    display: flex; align-items: center; gap: 0.75rem;
    padding: 0.55rem 0.85rem; border: 1px solid var(--border);
    border-radius: var(--radius-sm); cursor: pointer; transition: all 0.15s; background: var(--bg);
  }
  .rr-item-check:hover { border-color: var(--purple); background: var(--purple-bg); }
  .rr-item-check input[type=checkbox] { accent-color: var(--purple); width: 15px; height: 15px; }
  .rr-item-name  { font-size: 0.8rem; font-weight: 600; color: var(--text); }
  .rr-item-meta  { font-size: 0.68rem; color: var(--text-soft); }
  .rr-item-price { font-size: 0.8rem; font-weight: 700; color: var(--purple); margin-left: auto; font-family: 'Courier New', Courier, monospace; }

  .rr-photo-zone {
    border: 1.5px dashed var(--border); border-radius: var(--radius-sm);
    padding: 1rem; text-align: center; cursor: pointer; transition: all 0.15s; background: var(--bg);
  }
  .rr-photo-zone:hover { border-color: var(--purple); background: var(--purple-bg); }
  .rr-photo-zone p { font-size: 0.75rem; color: var(--text-soft); margin: 0.3rem 0 0; }
  .rr-photo-previews { display: flex; flex-wrap: wrap; gap: 0.5rem; margin-top: 0.65rem; }
  .rr-photo-thumb { width: 60px; height: 60px; object-fit: cover; border-radius: var(--radius-sm); border: 1px solid var(--border); }
  .rr-photo-item { position: relative; display: inline-block; }
  .rr-photo-rm {
    position: absolute; top: -5px; right: -5px; width: 17px; height: 17px;
    border-radius: 50%; background: var(--danger); color: #fff; font-size: 0.6rem;
    border: none; cursor: pointer; display: flex; align-items: center; justify-content: center;
  }

  .rr-reason-chips { display: flex; flex-wrap: wrap; gap: 0.4rem; margin-bottom: 0.65rem; }
  .rr-chip {
    padding: 0.28rem 0.7rem; border-radius: 3px; border: 1px solid var(--border);
    font-size: 0.72rem; cursor: pointer; background: var(--bg); color: var(--text-soft);
    transition: all 0.15s; font-family: 'DM Sans', sans-serif;
  }
  .rr-chip:hover  { border-color: var(--purple); color: var(--purple); }
  .rr-chip.active { background: var(--purple); color: #fff; border-color: var(--purple); }

  .rr-modal-footer {
    display: flex; gap: 0.65rem; justify-content: flex-end;
    padding: 0.85rem 1.25rem; border-top: 1px solid var(--border); background: var(--bg-card2);
  }
  .rr-btn-cancel-modal {
    padding: 0.5rem 1rem; border-radius: var(--radius-sm);
    background: transparent; color: var(--text-soft); border: 1px solid var(--border);
    font-size: 0.82rem; font-weight: 600; cursor: pointer; font-family: 'DM Sans', sans-serif;
    transition: all 0.18s;
  }
  .rr-btn-cancel-modal:hover { border-color: var(--text-soft); color: var(--text); }
  .rr-btn-submit {
    padding: 0.5rem 1.35rem; border-radius: var(--radius-sm);
    background: var(--purple); color: #fff; border: none;
    font-size: 0.82rem; font-weight: 700; cursor: pointer;
    display: flex; align-items: center; gap: 0.4rem; font-family: 'DM Sans', sans-serif;
    transition: all 0.18s;
  }
  .rr-btn-submit:hover { background: #3a1f72; transform: translateY(-1px); }
  .rr-btn-submit:disabled { background: rgba(76,45,138,0.35); cursor: not-allowed; transform: none; }

  .rr-success {
    text-align: center; padding: 2rem 1.5rem;
    display: none; flex-direction: column; align-items: center;
  }
  .rr-success.show { display: flex; }
  .rr-success-icon {
    width: 60px; height: 60px; border-radius: 50%; background: var(--success-bg);
    display: flex; align-items: center; justify-content: center;
    font-size: 1.6rem; margin-bottom: 1rem; border: 1.5px solid rgba(26,107,58,0.22); color: var(--success);
  }
  .rr-success h3 { font-size: 1rem; font-weight: 700; color: var(--text); margin-bottom: 0.4rem; }
  .rr-success p  { font-size: 0.8rem; color: var(--text-soft); line-height: 1.6; }
  .rr-req-number {
    background: var(--purple-bg); color: var(--purple); font-weight: 700;
    padding: 0.3rem 0.9rem; border-radius: 3px; font-size: 0.82rem;
    margin: 0.65rem 0; font-family: 'Courier New', Courier, monospace;
    border: 1px solid rgba(76,45,138,0.25);
  }

  /* ── CANCEL MODAL ── */
  .modal-content {
    background: var(--bg-card); border: 1px solid var(--border);
    border-radius: var(--radius); color: var(--text);
    box-shadow: 0 24px 64px rgba(0,0,0,0.18);
  }
  .cancel-modal-header {
    background: var(--danger-bg); border-bottom: 1px solid rgba(155,28,28,0.18);
    padding: 1rem 1.25rem; display: flex; align-items: center; justify-content: space-between;
  }
  .cancel-modal-title { font-size: 0.9rem; font-weight: 700; display: flex; align-items: center; gap: 0.5rem; color: var(--danger); }
  .cancel-info-row {
    display: flex; gap: 1.5rem; flex-wrap: wrap;
    background: var(--bg); border: 1px solid var(--border);
    border-radius: var(--radius-sm); padding: 0.75rem 1rem; margin-bottom: 1rem;
  }
  .ci-label { font-size: 0.63rem; text-transform: uppercase; letter-spacing: 1px; color: var(--text-soft); }
  .ci-val   { font-size: 0.85rem; font-weight: 700; color: var(--text); margin-top: 2px; }
  .modal-field-label {
    font-size: 0.68rem; font-weight: 700; letter-spacing: 1px;
    text-transform: uppercase; color: var(--text-soft); display: block; margin-bottom: 0.35rem;
  }
  .modal-select, .modal-textarea {
    width: 100%; border: 1px solid var(--border); border-radius: var(--radius-sm);
    padding: 0.5rem 0.75rem; font-family: 'DM Sans', sans-serif;
    font-size: 0.83rem; color: var(--text); background: var(--bg); outline: none; transition: all 0.18s;
  }
  .modal-select:focus, .modal-textarea:focus { border-color: var(--accent); box-shadow: 0 0 0 3px var(--accent-glow); }
  .modal-select option { background: var(--bg-card); }
  .modal-textarea { resize: none; }
  .modal-footer-custom {
    padding: 0.85rem 1.25rem; border-top: 1px solid var(--border);
    display: flex; gap: 0.6rem; justify-content: flex-end; background: var(--bg-card2);
  }
  .btn-keep {
    padding: 0.48rem 1.1rem; border-radius: var(--radius-sm);
    background: transparent; color: var(--text-mid); border: 1px solid var(--border);
    font-size: 0.82rem; font-weight: 600; cursor: pointer; font-family:'DM Sans', sans-serif;
    transition: all 0.18s;
  }
  .btn-keep:hover { border-color: var(--text-soft); color: var(--text); }
  .btn-confirm-cancel {
    padding: 0.48rem 1.25rem; border-radius: var(--radius-sm);
    background: var(--danger); color: #fff; border: none;
    font-size: 0.82rem; font-weight: 700; cursor: pointer; font-family: 'DM Sans', sans-serif;
    display: inline-flex; align-items: center; gap: 0.4rem; transition: all 0.18s;
  }
  .btn-confirm-cancel:hover { background: #7a1414; }
  .late-warning {
    background: var(--warning-bg); border: 1px solid rgba(140,74,0,0.22);
    border-radius: var(--radius-sm); padding: 0.6rem 0.85rem;
    font-size: 0.78rem; color: var(--warning); margin-top: 0.5rem;
    display: flex; align-items: center; gap: 0.5rem;
  }
  .refund-note-box {
    background: var(--success-bg); border: 1px solid rgba(26,107,58,0.18);
    border-left: 3px solid var(--success); border-radius: 0 var(--radius-sm) var(--radius-sm) 0;
    padding: 0.6rem 0.9rem; font-size: 0.8rem; color: var(--success); margin-bottom: 1rem;
  }

  /* ── PROFILE MODAL ── */
  .profile-modal .modal-content { border-radius: 12px; }
  .profile-modal-head {
    background: var(--bg-card2);
    padding: 1.5rem; text-align: center; border-bottom: 1px solid var(--border);
  }
  .profile-modal-avatar {
    width: 68px; height: 68px; border-radius: 50%;
    background: linear-gradient(135deg, var(--accent), #4c2d8a);
    margin: 0 auto 0.7rem; display: flex; align-items: center; justify-content: center;
    font-size: 1.7rem; font-weight: 700; color: #fff; border: 3px solid rgba(0,0,0,0.08);
  }
  .profile-modal-name  { color: var(--text); font-size: 1rem; font-weight: 700; }
  .profile-modal-email { color: var(--text-soft); font-size: 0.78rem; margin-top: 3px; }
  .profile-modal-body  { padding: 0.75rem; }
  .profile-action {
    display: flex; align-items: center; gap: 0.7rem;
    padding: 0.65rem 0.9rem; border-radius: var(--radius-sm); text-decoration: none;
    color: var(--text-mid); font-size: 0.85rem; font-weight: 500; transition: all 0.15s;
  }
  .profile-action:hover { background: rgba(0,0,0,0.04); color: var(--text); }
  .pa-icon { width: 32px; height: 32px; border-radius: var(--radius-sm); display: flex; align-items: center; justify-content: center; font-size: 0.9rem; }
  .profile-action.danger { color: var(--danger); }
  .profile-action.danger:hover { background: var(--danger-bg); }

  /* ── TOAST ── */
  .toast-wrap { position: fixed; bottom: 1.5rem; right: 1.5rem; z-index: 9999; }
  .toast-item {
    background: var(--bg-card); border: 1px solid var(--border); color: var(--text);
    padding: 0.75rem 1rem; border-radius: var(--radius-sm); display: flex; align-items: center;
    gap: 0.6rem; font-size: 0.83rem; font-weight: 500;
    box-shadow: 0 4px 20px rgba(0,0,0,0.10); margin-top: 0.5rem; min-width: 250px;
    animation: toastIn 0.25s ease;
  }
  @keyframes toastIn { from{opacity:0;transform:translateY(10px);}to{opacity:1;transform:none;} }

  /* ── FOOTER ── */
  footer {
    background: var(--bg-card2); color: var(--text-soft); font-size: 0.78rem;
    text-align: center; padding: 1rem; margin-top: 3rem; border-top: 1px solid var(--border);
    font-family: 'DM Sans', sans-serif;
  }
  footer span { color: var(--accent); }

  /* ── RESPONSIVE ── */
  @media(max-width:600px) {
    .tracker { overflow-x: auto; -webkit-overflow-scrolling: touch; }
    .order-footer { justify-content: flex-start; flex-wrap: wrap; gap: .5rem; }
    .page-wrap { padding: 1.25rem 0.75rem 5rem; }
    .nav-name { display: none; }
    .rr-type-grid { grid-template-columns: 1fr; }
    .rr-detail-grid { grid-template-columns: 1fr; }
    /* Order card header stack */
    .order-head { flex-direction: column; align-items: flex-start; gap: .5rem; }
    /* Items list inside order — switch to compact card rows */
    .order-items-table { display: none; }
    .order-items-mobile { display: block !important; }
    .order-meta-row { flex-direction: column; gap: .35rem; }
    /* Action buttons full width */
    .order-footer .btn, .order-footer a { flex: 1 1 calc(50% - .25rem); text-align: center; }
    /* Modal dialogs full width */
    .modal-dialog { margin: .5rem; max-width: calc(100vw - 1rem) !important; }
  }
  /* Mobile items card style */
  .order-items-mobile {
    display: none;
    padding: .5rem .85rem .85rem;
  }
  .oim-item {
    display: flex; align-items: center; gap: .75rem;
    padding: .65rem 0; border-bottom: 1px solid var(--border);
  }
  .oim-item:last-child { border-bottom: none; }
  .oim-img { width: 46px; height: 46px; border-radius: 8px; object-fit: contain;
              background: var(--navy-mid); border: 1px solid var(--border); flex-shrink: 0; padding: 3px; }
  .oim-name { font-size: .82rem; font-weight: 600; color: var(--text); flex: 1; line-height: 1.3; }
  .oim-price { font-size: .85rem; font-weight: 700; color: var(--text); white-space: nowrap; }
  .oim-qty { font-size: .72rem; color: var(--text-soft); }
</style>
</head>
<body>

<!-- ══ NAVBAR ══ -->
<nav class="top-nav">
  <a class="nav-brand" href="Customer">
    <i class="bi bi-bag-heart-fill" style="color:var(--accent);"></i>
    SIBS<span class="dot">•</span>STORE
  </a>
  <div class="nav-right">
    <a href="Customer" class="nav-text-btn"><i class="bi bi-house"></i> Home</a>
    <a href="CartServlet?action=view" class="nav-icon" title="Cart">
      <i class="bi bi-bag"></i>
      <span class="nav-badge"><%= totalProducts != null ? totalProducts : 0 %></span>
    </a>
    <a href="CustomerOrdersServlet" class="nav-icon active-nav" title="My Orders">
      <i class="bi bi-box-seam"></i>
    </a>
    <button class="nav-profile-btn" data-bs-toggle="modal" data-bs-target="#profileModal" style="border:none;">
      <div class="nav-avatar"><%= custInitial %></div>
      <span class="nav-name"><%= custName.split(" ")[0] %></span>
      <i class="bi bi-chevron-down" style="font-size:0.65rem;opacity:0.5;color:var(--text-soft);"></i>
    </button>
  </div>
</nav>

<!-- ══ PROFILE MODAL ══ -->
<div class="modal fade profile-modal" id="profileModal" tabindex="-1">
  <div class="modal-dialog modal-dialog-centered" style="max-width:320px;">
    <div class="modal-content">
      <div class="profile-modal-head">
        <button type="button" class="btn-close btn-close-white position-absolute top-0 end-0 m-3" data-bs-dismiss="modal"></button>
        <div class="profile-modal-avatar"><%= custInitial %></div>
        <div class="profile-modal-name"><%= custName %></div>
        <div class="profile-modal-email"><%= custEmail %></div>
      </div>
      <div class="profile-modal-body">
        <a href="CustomerProfile" class="profile-action">
          <span class="pa-icon" style="background:var(--sky-bg);color:var(--sky);"><i class="bi bi-person-circle"></i></span> My Account
        </a>
        <a href="CustomerOrdersServlet" class="profile-action" style="color:var(--accent);">
          <span class="pa-icon" style="background:var(--accent-glow);color:var(--accent);"><i class="bi bi-box-seam"></i></span> My Orders
        </a>
        <a href="CartServlet?action=view" class="profile-action">
          <span class="pa-icon" style="background:var(--success-bg);color:var(--success);"><i class="bi bi-cart3"></i></span> My Cart
        </a>
        <a href="CustomerWallet" class="profile-action">
          <span class="pa-icon" style="background:rgba(245,166,35,.1);color:#f5a623;"><i class="bi bi-wallet2"></i></span> My Wallet
        </a>
        <a href="WishlistServlet" class="profile-action">
          <span class="pa-icon" style="background:var(--danger-bg);color:var(--danger);"><i class="bi bi-heart"></i></span> Wishlist
        </a>
        <hr style="margin:0.4rem 0;opacity:0.08;">
        <a href="CustomerLogout" class="profile-action danger">
          <span class="pa-icon" style="background:var(--danger-bg);color:var(--danger);"><i class="bi bi-box-arrow-right"></i></span> Logout
        </a>
      </div>
    </div>
  </div>
</div>

<!-- ══ PAGE ══ -->
<div class="page-wrap">

  <!-- Header -->
  <div class="page-header">
    <div style="display:flex;align-items:center;gap:0.75rem;flex-wrap:wrap;">
      <h1 class="page-title">My Orders</h1>
      <span class="order-count-badge"><%= orders.size() %> order<%= orders.size() != 1 ? "s" : "" %></span>
    </div>
    <a href="Customer" class="btn-shop"><i class="bi bi-shop"></i> Continue Shopping</a>
  </div>

  <!-- Filter bar -->
  <div class="filter-bar">
    <button class="filter-btn active" onclick="filterOrders('all', this)">All</button>
    <button class="filter-btn" onclick="filterOrders('Pending', this)">Pending</button>
    <button class="filter-btn" onclick="filterOrders('Confirmed', this)">Confirmed</button>
    <button class="filter-btn" onclick="filterOrders('Shipped', this)">Shipped</button>
    <button class="filter-btn" onclick="filterOrders('Delivered', this)">Delivered</button>
    <button class="filter-btn" onclick="filterOrders('Cancelled', this)">Cancelled</button>
    <button class="filter-btn" onclick="filterOrders('return', this)">Returns</button>
    <button class="filter-btn" onclick="filterOrders('PAYMENT_FAILED', this)">Payment Issues</button>
  </div>

  <!-- Empty state -->
  <% if (orders.isEmpty()) { %>
  <div class="empty-state">
    <i class="bi bi-bag-x empty-icon"></i>
    <h3>No orders yet</h3>
    <p style="font-size:0.83rem;margin-bottom:1.25rem;">When you place an order, it will appear here.</p>
    <a href="customerDashboard.jsp" class="btn-action btn-track"><i class="bi bi-shop"></i> Start Shopping</a>
  </div>
  <% } %>

  <!-- ── ORDER CARDS ── -->
  <%
  /*
   * REAL-WORLD E-COMMERCE ORDER STAGES (orders.status ENUM):
   *
   * 1. Ordered        – Order placed, awaiting staff confirmation
   * 2. Pending        – Payment pending / being verified
   * 3. Confirmed      – Staff confirmed, warehouse notified
   * 4. Assigned       – Delivery agent assigned to pick from warehouse
   * 5. Picked Up      – Agent collected from warehouse
   * 6. Packed         – Item packed and ready for dispatch
   * 7. Shipped        – Dispatched from warehouse / in transit
   * 8. Out for Delivery – Agent on the way to customer
   * 9. Delivered      – Successfully delivered
   * 10. Cancelled     – Order cancelled at any stage
   *
   * RETURN STAGES (order_returns.status ENUM):
   * Requested → Approved → [Agent Assigned → Out for Pickup →] Picked → Processing → Refunded/Replaced
   * OR: Rejected
   *
   * TRACKER FIX: The tracker progress bar spans from step 1 to step 8 (Delivered).
   * We compute bar width as: (activeStep - 1) / (totalSteps - 1) * 88%
   * (88% because 6% padding on each side = left:6%, so usable = 88%)
   * This ensures the bar STOPS exactly at the active step dot and never overshoots.
   */
  for (Order order : orders) {
      String status    = order.getStatus()        != null ? order.getStatus()        : "Ordered";
      String payStatus = order.getPaymentStatus() != null ? order.getPaymentStatus() : "";
      String payMethod = order.getPaymentMethod() != null ? order.getPaymentMethod() : "";
      List<CartItem> items = order.getItems() != null ? order.getItems() : new ArrayList<>();

      // ── Map status → tracker step (1-8) ──────────────────────────────
      // Only forward-delivery statuses use the tracker.
      // Return/Cancel/Refund states are shown in the return tracker block instead.
      int step = 0;
      if      ("Ordered".equals(status))            step = 1;
      else if ("Pending".equals(status))             step = 2;
      else if ("Confirmed".equals(status))           step = 3;
      else if ("Assigned".equals(status))            step = 4;
      else if ("Picked Up".equals(status))           step = 5;
      else if ("Packed".equals(status))              step = 6;
      else if ("Shipped".equals(status))             step = 7;
      else if ("Out for Delivery".equals(status))    step = 8;
      else if ("Delivered".equals(status))           step = 9; // 9 = final (all done)

      // Total forward steps in tracker = 9 (Ordered through Delivered)
      final int TOTAL_STEPS = 9;

      /*
       * BUG FIX: Progress bar width formula.
       * Left edge of tracker starts at 6%, right edge at 94% (width=88% usable).
       * Each step occupies: 88/(TOTAL_STEPS-1) = 11% per step.
       * For step N: bar_width_pct = (N-1) * 11%
       * Step 1 (Ordered) → 0%, Step 9 (Delivered) → 88% = exactly reaching right dot.
       * Cap at 88% so bar never exceeds the last dot position.
       */
      double stepPct = (step > 0 && step <= TOTAL_STEPS)
          ? Math.min(((double)(step - 1) / (TOTAL_STEPS - 1)) * 88.0, 88.0)
          : 0.0;

      boolean isCancelled  = "Cancelled".equals(status);
      boolean isPayFailed  = "PAYMENT_FAILED".equals(payStatus);
      boolean isPaid       = "PAID".equals(payStatus);
      boolean isPendingCOD = "PENDING_COD".equals(payStatus);
      boolean isOnline     = "Card".equalsIgnoreCase(payMethod) || "UPI".equalsIgnoreCase(payMethod) || "Razorpay".equalsIgnoreCase(payMethod);
      boolean isReturnStatus = status.startsWith("Return") || "Refunded".equals(status) || "Replaced".equals(status) || "Processing".equals(status);

      // Badge class mapping – covers all new statuses
      String badgeClass =
          "Ordered".equals(status)             ? "badge-ordered"   :
          "Pending".equals(status)             ? "badge-pending"   :
          "Confirmed".equals(status)           ? "badge-confirmed" :
          "Assigned".equals(status)            ? "badge-assigned"  :
          "Picked Up".equals(status)           ? "badge-pickedup"  :
          "Packed".equals(status)              ? "badge-packed"    :
          "Shipped".equals(status)             ? "badge-shipped"   :
          "Out for Delivery".equals(status)    ? "badge-ofd"       :
          "Delivered".equals(status)           ? "badge-delivered" :
          "Cancelled".equals(status)           ? "badge-cancelled" :
          "Processing".equals(status)          ? "badge-processing":
          "Refunded".equals(status)            ? "badge-refunded"  :
          "Replaced".equals(status)            ? "badge-replaced"  : "badge-pending";

      // ── Return request data ──────────────────────────────────────────
      com.util.OrderReturn rr = order.getReturnRequest();
      boolean isDelivered      = "Delivered".equals(status);
      long daysAgo             = (isDelivered && order.getDeliveryDate() != null) ? daysSinceDelivery(order.getDeliveryDate()) : -1;
      boolean canRequestReturn = isDelivered && daysAgo >= 0 && daysAgo <= 10 && (rr == null);
      boolean windowExpired    = isDelivered && daysAgo > 10 && (rr == null);
      boolean hasReturn        = (rr != null);
      String  rrStatus         = hasReturn ? rr.getStatus()   : "";
      String  rrReason         = hasReturn ? (rr.getReason() != null ? rr.getReason() : "") : "";
      double  refundAmt        = hasReturn ? rr.getRefundAmount() : 0.0;
      String  refMethod        = hasReturn ? (rr.getRefundMethod() != null ? rr.getRefundMethod() : "") : "";
      String  rrType           = hasReturn ? rr.getType() : "Return";
      String  rrId             = hasReturn ? String.valueOf(rr.getId()) : "";
      String  staffNote        = (hasReturn && rr.getStaffNotes() != null) ? rr.getStaffNotes() : "";

      // Cancel logic
      boolean canCancel  = false;
      String  refundNote = "";
      String os2         = order.getStatus() != null ? order.getStatus() : "";
      boolean orderIsPaid = "PAID".equalsIgnoreCase(order.getPaymentStatus());
      boolean orderIsCod  = "PENDING_COD".equalsIgnoreCase(order.getPaymentStatus());
      switch (os2) {
        case "Ordered": case "Pending": case "Confirmed":
          canCancel  = true;
          refundNote = orderIsPaid ? "Full refund will be credited to your wallet instantly." : "No payment was made.";
          break;
        case "Assigned": case "Picked Up":
          canCancel  = true;
          refundNote = orderIsPaid ? "₹" + String.format("%.2f", order.getTotalAmount() * 0.95) + " refunded (5% handling fee deducted)." : "No payment was made.";
          break;
        case "Packed":
          canCancel  = true;
          refundNote = orderIsPaid ? "₹" + String.format("%.2f", order.getTotalAmount() * 0.95) + " refunded (5% packing charge deducted)." : "No payment was made.";
          break;
        case "Shipped":
          canCancel  = true;
          refundNote = orderIsPaid ? "₹" + String.format("%.2f", order.getTotalAmount() * 0.90) + " refunded (10% shipping charge deducted)." : "No payment was made.";
          break;
        case "Out for Delivery":
          canCancel  = true;
          refundNote = orderIsPaid ? "₹" + String.format("%.2f", order.getTotalAmount() * 0.90) + " refunded (10% deducted). Refuse delivery at door." : "Refuse delivery at door.";
          break;
        default:
          if (os2.startsWith("Return") || "Cancelled".equals(os2) || "Refunded".equals(os2) || "Replaced".equals(os2) || "Delivered".equals(os2)) canCancel = false;
          break;
      }
  %>
  <div class="order-card"
       data-status="<%= status %>"
       data-paystatus="<%= payStatus %>"
       data-orderid="<%= order.getId() %>"
       data-isreturn="<%= isReturnStatus ? "true" : "false" %>">

    <!-- Strip -->
    <div class="order-strip">
      <div class="strip-left">
        <div class="order-id"><i class="bi bi-receipt" style="opacity:0.6;"></i> Order #<%= order.getId() %></div>
        <div class="order-date">
          <i class="bi bi-calendar3"></i>
          <%= order.getDate() != null ? new java.text.SimpleDateFormat("dd MMM yyyy, hh:mm a").format(order.getDate()) : "—" %>
        </div>
      </div>
      <div class="strip-right">
        <% if (order.getOtp() != 0 && !isCancelled && "Out for Delivery".equals(status)) { %>
          <div class="otp-box"><i class="bi bi-shield-lock"></i> OTP: <%= order.getOtp() %></div>
        <% } %>
        <span class="status-badge <%= badgeClass %>">
          <% if ("Delivered".equals(status)) { %><i class="bi bi-check-circle"></i>
          <% } else if (isCancelled) { %><i class="bi bi-x-circle"></i>
          <% } else if ("Refunded".equals(status) || "Replaced".equals(status)) { %><i class="bi bi-arrow-repeat"></i>
          <% } else { %><i class="bi bi-circle-fill" style="font-size:0.45rem;"></i><% } %>
          <%= status %>
        </span>
        <% if (isPaid) { %>
          <span class="status-badge badge-paid"><i class="bi bi-check2"></i> Paid</span>
        <% } else if (isPayFailed) { %>
          <span class="status-badge badge-failed"><i class="bi bi-x-circle"></i> Payment Failed</span>
        <% } else if (isPendingCOD) { %>
          <span class="status-badge badge-pending-cod"><i class="bi bi-cash"></i> COD</span>
        <% } else if ("PENDING_PAYMENT".equals(payStatus)) { %>
          <span class="status-badge badge-failed"><i class="bi bi-hourglass-split"></i> Interrupted</span>
        <% } %>
      </div>
    </div>

    <!-- Body -->
    <div class="order-body">

      <!-- OTP Alert — only show when Out for Delivery -->
      <% if ("Out for Delivery".equals(status) && !isCancelled) { %>
      <div class="alert-otp"><i class="bi bi-shield-lock-fill"></i>
        Share OTP <strong style="font-family:'Space Mono',monospace;"><%= order.getOtp() %></strong> with delivery partner on arrival.
      </div>
      <% } else if ("Delivered".equals(status)) { %>
      <div class="alert-delivered"><i class="bi bi-check-circle-fill"></i>
        Your order has been delivered. Thank you for shopping with us!
      </div>
      <% } %>

      <!-- Payment Alerts -->
      <% if (isPayFailed && isOnline) { %>
        <div class="payment-alert payment-failed">
          <i class="bi bi-x-octagon-fill"></i>
          <div><strong>Payment Failed</strong>
            Your <%= payMethod %> payment did not go through.<% if (!isCancelled) { %> Retry payment or cancel.<% } %></div>
        </div>
      <% } else if ("PENDING_PAYMENT".equals(payStatus) && isOnline) { %>
        <div class="payment-alert payment-interrupted">
          <i class="bi bi-exclamation-triangle-fill"></i>
          <div><strong>Payment Interrupted</strong>
            If amount was debited, refund will process within 5–7 business days.</div>
        </div>
      <% } else if (isPaid && isOnline) { %>
        <div class="payment-alert payment-success">
          <i class="bi bi-shield-check"></i>
          <div><strong>Payment Confirmed</strong>
            ₹<%= String.format("%.2f", order.getTotalAmount()) %> via <%= payMethod %></div>
        </div>
      <% } else if (isPendingCOD) { %>
        <div class="payment-alert payment-pending">
          <i class="bi bi-cash-stack"></i>
          <div><strong>Cash on Delivery</strong>
            Keep ₹<%= String.format("%.2f", order.getTotalAmount()) %> ready at delivery.</div>
        </div>
      <% } %>

      <!--
        ══ DELIVERY TRACKER ══
        BUG FIX: Only shown for active forward-delivery orders (not cancelled, not failed payment, not return statuses).
        Progress bar is computed using stepPct which correctly stops at the active dot.
        Steps: Ordered → Pending → Confirmed → Assigned → Picked Up → Packed → Shipped → Out for Delivery → Delivered
      -->
      <% if (!isCancelled && !isPayFailed && !"PENDING_PAYMENT".equals(payStatus) && !isReturnStatus && step > 0) { %>
      <div class="tracker" id="tracker_<%= order.getId() %>">
        <!-- BUG FIX: data-progress now stores the computed percentage (not the step index) -->
        <div class="tracker-progress"
             data-progress="<%= String.format("%.1f", stepPct) %>"
             style="width:0%;"></div>
        <%
          String[] stepLabels = {"Ordered","Pending","Confirmed","Assigned","Picked Up","Packed","Shipped","Out for\nDelivery","Delivered"};
          String[] stepIcons  = {"bi-receipt","bi-hourglass-split","bi-shield-check","bi-person-badge","bi-bag-check","bi-box-seam","bi-send","bi-bicycle","bi-house-check"};
          for (int s = 1; s <= TOTAL_STEPS; s++) {
            String cc = s < step ? "done" : s == step ? "active" : "";
        %>
        <div class="tracker-step">
          <div class="step-circle <%= cc %>"><i class="bi <%= stepIcons[s-1] %>"></i></div>
          <div class="step-label <%= cc %>"><%= stepLabels[s-1].replace("\n","<br>") %></div>
        </div>
        <% } %>
      </div>

      <!-- Stage info bar — describes what's happening now -->
      <%
        String stageBarClass = "", stageBarIcon = "", stageBarText = "";
        switch (status) {
          case "Ordered":          stageBarClass = "stage-bar-ordered";   stageBarIcon = "bi-receipt";        stageBarText = "Order placed — awaiting staff confirmation"; break;
          case "Pending":          stageBarClass = "stage-bar-ordered";   stageBarIcon = "bi-hourglass-split"; stageBarText = "Verifying payment and processing your order"; break;
          case "Confirmed":        stageBarClass = "stage-bar-confirmed"; stageBarIcon = "bi-shield-check";   stageBarText = "Order confirmed — warehouse has been notified"; break;
          case "Assigned":         stageBarClass = "stage-bar-assigned";  stageBarIcon = "bi-person-badge";   stageBarText = "Delivery agent assigned — picking up from warehouse"; break;
          case "Picked Up":        stageBarClass = "stage-bar-pickedup";  stageBarIcon = "bi-bag-check";      stageBarText = "Agent collected your order from warehouse"; break;
          case "Packed":           stageBarClass = "stage-bar-packed";    stageBarIcon = "bi-box-seam";       stageBarText = "Order packed and ready for dispatch"; break;
          case "Shipped":          stageBarClass = "stage-bar-shipped";   stageBarIcon = "bi-send";           stageBarText = "Order shipped — in transit to your location"; break;
          case "Out for Delivery": stageBarClass = "stage-bar-ofd";       stageBarIcon = "bi-bicycle";        stageBarText = "Agent is on the way — delivery expected today"; break;
          case "Delivered":        stageBarClass = "stage-bar-delivered"; stageBarIcon = "bi-house-check";    stageBarText = "Successfully delivered"; break;
        }
        if (!stageBarClass.isEmpty()) {
      %>
      <div class="stage-info-bar <%= stageBarClass %>">
        <i class="bi <%= stageBarIcon %>"></i>
        <span><%= stageBarText %></span>
      </div>
      <% } %>

      <% } else if (isCancelled) { %>
        <div class="payment-alert payment-failed" style="margin:0.5rem 0 0.75rem;">
          <i class="bi bi-slash-circle"></i>
          <div><strong>Order Cancelled</strong>
            <% if (isPaid || isOnline) { %> Refund will be processed within 5–7 business days if applicable.<% } %>
          </div>
        </div>
      <% } %>

      <!-- Delivery info row -->
      <div class="delivery-info">
        <span><i class="bi bi-credit-card"></i> <strong><%= payMethod.isEmpty() ? "—" : payMethod %></strong></span>
        <% if (order.getDeliveryDate() != null && !isCancelled && !isPayFailed) { %>
        <span>
          <i class="bi bi-calendar-check"></i>
          <% if ("Delivered".equals(status)) { %>
            Delivered: <strong><%= new java.text.SimpleDateFormat("dd MMM yyyy").format(order.getDeliveryDate()) %></strong>
          <% } else { %>
            Est: <strong><%= new java.text.SimpleDateFormat("dd MMM yyyy").format(order.getDeliveryDate()) %></strong>
          <% } %>
        </span>
        <% } %>
        <span><i class="bi bi-box-seam"></i> <strong><%= items.size() %></strong> item<%= items.size() != 1 ? "s" : "" %></span>
        <span><i class="bi bi-currency-rupee"></i> <strong style="font-family:'Space Mono',monospace;">₹<%= String.format("%.2f", order.getTotalAmount()) %></strong></span>
      </div>

      <!-- Return eligibility -->
      <% if (isDelivered) { %>
        <% if (hasReturn) { %>
          <%
            String rrEligClass = "rr-" + rrStatus.toLowerCase().replace(" ", "");
            if (rrEligClass.equals("rr-requested") || rrEligClass.equals("rr-pending")) rrEligClass = "rr-pending";
          %>
          <div class="rr-eligibility <%= rrEligClass %>">
            <i class="bi bi-arrow-return-left"></i>
            <% if ("Requested".equals(rrStatus) || "Pending".equals(rrStatus)) { %>
              <strong><%= rrType %> request submitted</strong> — awaiting staff review (Req #<%= rrId %>)
            <% } else if ("Approved".equals(rrStatus)) { %>
              <strong><%= rrType %> approved</strong> — pickup agent being assigned
            <% } else if ("Rejected".equals(rrStatus)) { %>
              <strong><%= rrType %> rejected</strong> — <%= !staffNote.isEmpty() ? staffNote : "see details below" %>
            <% } else if ("Processing".equals(rrStatus)) { %>
              <strong>Agent out for pickup</strong> — collecting your item
            <% } else if ("Picked".equals(rrStatus)) { %>
              <strong>Item picked up</strong> — refund/replacement being processed
            <% } else if ("Refunded".equals(rrStatus)) { %>
              <strong>Refund processed</strong> — ₹<%= String.format("%.2f", refundAmt) %> sent to your <%= refMethod.isEmpty() ? "source" : refMethod %>
            <% } else if ("Replaced".equals(rrStatus)) { %>
              <strong>Replacement confirmed</strong> — new item will be shipped shortly
            <% } else { %>
              <strong><%= rrType %> — <%= rrStatus %></strong>
            <% } %>
          </div>
        <% } else if (canRequestReturn) { %>
          <div class="rr-eligibility rr-window">
            <i class="bi bi-shield-check"></i>
            Return/Replace window open —
            <span class="rr-days-left <%= (10-daysAgo) <= 2 ? "rr-days-urgent" : "rr-days-ok" %>">
              <%= (10 - daysAgo) %> day<%= (10 - daysAgo) != 1 ? "s" : "" %> left
            </span>
          </div>
        <% } else if (windowExpired) { %>
          <div class="rr-eligibility rr-expired">
            <i class="bi bi-x-circle"></i>
            Return window closed — only within 10 days of delivery
          </div>
        <% } %>
      <% } %>

      <!-- Return tracker block -->
      <% if (hasReturn) {
          /*
           * RETURN STAGES VISUAL MAPPING:
           * Requested   → step 1 (submitted)
           * Approved    → step 2 (staff reviewed)
           * Processing  → step 3 (agent out for pickup)
           * Picked      → step 4 (item collected)
           * Refunded    → step 5 (complete)
           * Replaced    → step 5 (complete, replacement)
           * Rejected    → step -1 (failed state)
           */
          int rrStep = 0;
          if ("Requested".equalsIgnoreCase(rrStatus) || "Pending".equalsIgnoreCase(rrStatus)) rrStep = 1;
          else if ("Approved".equalsIgnoreCase(rrStatus))   rrStep = 2;
          else if ("Processing".equalsIgnoreCase(rrStatus)) rrStep = 3;
          else if ("Picked".equalsIgnoreCase(rrStatus))     rrStep = 4;
          else if ("Refunded".equalsIgnoreCase(rrStatus) || "Replaced".equalsIgnoreCase(rrStatus)) rrStep = 5;
          boolean rrRejected = "Rejected".equalsIgnoreCase(rrStatus);
      %>
      <div class="rr-tracker-block">
        <div class="rr-tracker-header">
          <div class="rr-tracker-title">
            <i class="bi bi-arrow-repeat"></i> <%= rrType %> Request
            <span class="rr-type-pill"><%= rrStatus %></span>
          </div>
          <span class="rr-req-id">REQ#<%= rrId %></span>
        </div>
        <div class="rr-tracker-body">
          <% if (!rrRejected) { %>
          <div class="rr-steps">
            <%
               String lastLabel = "Replace".equals(rrType) ? "Replaced" : "Refunded";
               String[] rrLabels = {"Submitted","Approved","Out for Pickup","Item Collected", lastLabel};
               String[] rrIcons  = {"bi-send","bi-person-check","bi-truck","bi-box-arrow-in-down","bi-check-circle"};
               for (int rs = 1; rs <= 5; rs++) {
                 String rsDotClass  = rs < rrStep ? "done" : rs == rrStep ? "active" : "";
                 String rsLineClass = rs < rrStep ? "done" : "";
            %>
            <div class="rr-step">
              <div class="rr-step-line <%= rsLineClass %>"></div>
              <div class="rr-step-dot <%= rsDotClass %>"><i class="bi <%= rrIcons[rs-1] %>"></i></div>
              <div class="rr-step-lbl <%= rsDotClass %>"><%= rrLabels[rs-1] %></div>
            </div>
            <% } %>
          </div>
          <% } else { %>
          <div style="display:flex;align-items:center;gap:0.5rem;padding:0.4rem 0;">
            <div class="rr-step-dot fail"><i class="bi bi-x-lg"></i></div>
            <span style="font-size:0.82rem;font-weight:600;color:var(--danger);">Request Rejected</span>
          </div>
          <% } %>

          <div class="rr-detail-grid">
            <div><div class="rr-detail-label">Type</div><div class="rr-detail-value"><%= rrType %></div></div>
            <div><div class="rr-detail-label">Status</div><div class="rr-detail-value"><%= rrStatus %></div></div>
            <% if (refundAmt > 0) { %>
            <div><div class="rr-detail-label">Refund Amount</div><div class="rr-detail-value" style="font-family:'Space Mono',monospace;color:var(--success);">₹<%= String.format("%.2f", refundAmt) %></div></div>
            <div><div class="rr-detail-label">Refund To</div><div class="rr-detail-value"><%= refMethod.isEmpty() ? payMethod : refMethod %></div></div>
            <% } %>
            <div class="rr-detail-full">
              <div class="rr-detail-label">Reason</div>
              <div class="rr-reason-text"><%= rrReason.isEmpty() ? "—" : rrReason %></div>
            </div>
            <% if (!staffNote.isEmpty()) { %>
            <div class="rr-detail-full">
              <div class="rr-detail-label">Staff Note</div>
              <div class="<%= rrRejected ? "rr-reject-note" : "rr-staff-note" %>">
                <i class="bi bi-<%= rrRejected ? "x-circle" : "check-circle" %>"></i> <%= staffNote %>
              </div>
            </div>
            <% } %>
          </div>

          <% if ("Refunded".equals(rrStatus)) { %>
          <div class="rr-refund-info"><i class="bi bi-check-circle-fill"></i>
            Refund of ₹<%= String.format("%.2f", refundAmt) %> processed — allow 5–7 business days</div>
          <% } else if ("Replaced".equals(rrStatus)) { %>
          <div class="rr-refund-info" style="background:var(--teal-bg);border-color:rgba(14,107,94,0.2);color:var(--teal);">
            <i class="bi bi-arrow-repeat"></i> Replacement confirmed — new item will be shipped to you</div>
          <% } else if ("Approved".equals(rrStatus) && "Return".equals(rrType)) { %>
          <div class="rr-refund-info" style="background:var(--gold-bg);border-color:rgba(122,92,0,0.2);color:var(--gold);">
            <i class="bi bi-clock-history"></i>
            ₹<%= String.format("%.2f", refundAmt) %> refund will be processed after item pickup</div>
          <% } else if ("Approved".equals(rrStatus) && "Replace".equals(rrType)) { %>
          <div class="rr-refund-info" style="background:var(--sky-bg);border-color:rgba(14,90,138,0.2);color:var(--sky);">
            <i class="bi bi-box-seam"></i> Replacement will be shipped after original item is collected</div>
          <% } else if ("Processing".equals(rrStatus)) { %>
          <div class="pickup-agent-card">
            <i class="bi bi-bicycle"></i>
            Pickup agent is on the way to collect your item
          </div>
          <% } else if ("Picked".equals(rrStatus)) { %>
          <div class="rr-refund-info" style="background:var(--purple-bg);border-color:rgba(76,45,138,0.2);color:var(--purple);">
            <i class="bi bi-box-arrow-in-down"></i> Item collected — refund/replacement being processed</div>
          <% } %>
        </div>
      </div>
      <% } %>

      <!-- First item preview -->
      <% if (!items.isEmpty()) { CartItem first = items.get(0); %>
      <div class="product-row">
        <% if (first.getImageUrl() != null && !first.getImageUrl().isEmpty()) { %>
          <img src="${pageContext.request.contextPath}/<%= first.getImageUrl() %>"
               class="product-thumb" alt="<%= first.getName() %>"
               onerror="this.src='images/default.png'">
        <% } else { %>
          <div class="product-thumb-placeholder"><i class="bi bi-image"></i></div>
        <% } %>
        <div class="product-info">
          <div class="product-name"><%= first.getName() %></div>
          <div class="product-meta">
            Qty: <strong><%= first.getQuantity() %></strong>
            &nbsp;·&nbsp; <%= first.getProductQuantity() %> <%= first.getUnit() %>
            <% if (first.getDiscount() > 0) { %>
              &nbsp;·&nbsp; <span class="disc-pill"><%= (int)first.getDiscount() %>% off</span>
            <% } %>
          </div>
        </div>
        <div class="product-price">
          <div class="total">₹<%= String.format("%.2f", first.getFinalPrice() * first.getQuantity()) %></div>
          <div class="unit-price">@ ₹<%= String.format("%.2f", first.getFinalPrice()) %></div>
        </div>
      </div>
      <% if (items.size() > 1) { %>
        <div class="more-items-link">
          <i class="bi bi-plus-circle"></i>
          +<%= items.size()-1 %> more item<%= items.size()-1 > 1 ? "s" : "" %> —
          <a href="#" onclick="toggleItems('<%= order.getId() %>'); return false;">show all</a>
        </div>
      <% } %>
      <% } %>

    </div><!-- /order-body -->

    <!-- All items (collapsed) -->
    <div id="items_<%= order.getId() %>" style="display:none;" class="items-collapse">
      <% if (items.size() > 1) { %>
      <div style="overflow-x:auto;">
      <table class="items-table order-items-table">
        <thead><tr><th>Product</th><th>Pack</th><th>Qty</th><th>Unit Price</th><th>Total</th></tr></thead>
        <tbody>
          <% for (CartItem item : items) { %>
          <tr>
            <td>
              <strong><%= item.getName() %></strong>
              <% if (item.getDescription() != null && !item.getDescription().isEmpty()) { %>
              <div style="font-size:0.7rem;color:var(--text-soft);">
                <%= item.getDescription().substring(0, Math.min(55, item.getDescription().length())) %>…
              </div>
              <% } %>
            </td>
            <td style="color:var(--text-soft);white-space:nowrap;"><%= item.getProductQuantity() %> <%= item.getUnit() %></td>
            <td style="text-align:center;font-weight:600;"><%= item.getQuantity() %></td>
            <td style="font-family:'Space Mono',monospace;">₹<%= String.format("%.2f", item.getFinalPrice()) %></td>
            <td style="font-weight:700;color:var(--success);font-family:'Space Mono',monospace;">₹<%= String.format("%.2f", item.getFinalPrice() * item.getQuantity()) %></td>
          </tr>
          <% } %>
        </tbody>
      </table>

      <!-- Mobile item cards (shown only on small screens via CSS) -->
      <div class="order-items-mobile">
        <% for (CartItem item : items) { %>
        <div class="oim-item">
          <img class="oim-img"
               src="<%= item.getImageUrl() != null && !item.getImageUrl().isEmpty() ? item.getImageUrl() : "images/default.png" %>"
               alt="<%= item.getName() %>"
               onerror="this.src='images/default.png'">
          <div style="flex:1;min-width:0;">
            <div class="oim-name"><%= item.getName() %></div>
            <div class="oim-qty">× <%= item.getQuantity() %> &nbsp;·&nbsp; <%= item.getProductQuantity() %> <%= item.getUnit() %></div>
          </div>
          <div class="oim-price">₹<%= String.format("%.0f", item.getFinalPrice() * item.getQuantity()) %></div>
        </div>
        <% } %>
      </div>
      </div>
      <% } %>

      <!-- Order Summary -->
      <div class="order-summary">
        <div class="summary-row"><span>Subtotal</span><span>₹<%= String.format("%.2f", order.getSubtotal()) %></span></div>
        <div class="summary-row"><span>GST (18%)</span><span>₹<%= String.format("%.2f", order.getGst()) %></span></div>
        <div class="summary-row"><span>Tax (5%)</span><span>₹<%= String.format("%.2f", order.getTax()) %></span></div>
        <div class="summary-row"><span>Delivery Charge</span><span>₹<%= String.format("%.2f", order.getDeliveryCharge()) %></span></div>
        <% if ("COD".equalsIgnoreCase(payMethod) && order.getCodCharge() > 0) { %>
        <div class="summary-row"><span>COD Charge</span><span>₹<%= String.format("%.2f", order.getCodCharge()) %></span></div>
        <% } %>
        <div class="summary-total">
          <span>Grand Total</span>
          <span>₹<%= String.format("%.2f", order.getTotalAmount()) %></span>
        </div>
      </div>
    </div>

    <!-- Footer actions -->
    <div class="order-footer">
      <% if (!isCancelled && !isPayFailed) { %>
        <a href="TrackOrderServlet?orderId=<%= order.getId() %>" class="btn-action btn-track">
          <i class="bi bi-truck"></i> Track
        </a>
      <% } %>
      <a href="InvoiceServlet?orderId=<%= order.getId() %>" class="btn-action btn-invoice">
        <i class="bi bi-receipt"></i> Invoice
      </a>
      <% if (items.size() > 1) { %>
        <button class="btn-action btn-toggle" onclick="toggleItems('<%= order.getId() %>')">
          <i class="bi bi-box-seam" id="toggleIcon_<%= order.getId() %>"></i>
          <span id="toggleLabel_<%= order.getId() %>">All Items</span>
        </button>
      <% } %>
      <% if (isPayFailed && isOnline && !isCancelled) { %>
        <a href="Checkout.jsp?retryOrderId=<%= order.getId() %>" class="btn-action btn-retry">
          <i class="bi bi-arrow-clockwise"></i> Retry Payment
        </a>
      <% } %>
      <!-- Return / Replace button -->
      <% if (canRequestReturn && !hasReturn) { %>
        <button class="btn-action btn-return-act"
          onclick="openReturnModal('<%= order.getId() %>','<%= order.getCustomerName() != null ? order.getCustomerName().replace("'","&#39;") : custName %>','<%= payMethod %>','<%= String.format("%.2f", order.getTotalAmount()) %>')">
          <i class="bi bi-arrow-return-left"></i> Return / Replace
        </button>
      <% } %>
      <!-- Cancel button -->
      <% if (canCancel) { %>
        <button class="btn-action btn-cancel-act"
          onclick="openCancelModal(
            '<%= order.getId() %>',
            '<%= order.getCustomerName() != null ? order.getCustomerName().replace("'","&#39;") : "" %>',
            '<%= os2 %>',
            '<%= String.format("%.2f", order.getTotalAmount()) %>',
            '<%= orderIsPaid ? "paid" : orderIsCod ? "cod" : "free" %>',
            '<%= refundNote.replace("'","&#39;") %>'
          )">
          <i class="bi bi-x-circle"></i> Cancel Order
        </button>
      <% } %>
      <span class="footer-customer">
        <i class="bi bi-person-circle"></i>
        <%= order.getCustomerName() != null ? order.getCustomerName() : custName %>
      </span>
    </div>

  </div><!-- /order-card -->
  <% } %>

</div><!-- /page-wrap -->

<!-- ══ RETURN / REPLACE MODAL ══ -->
<div class="rr-modal-overlay" id="rrModalOverlay" onclick="handleOverlayClick(event)">
  <div class="rr-modal" role="dialog" aria-modal="true" aria-labelledby="rrModalTitle">
    <div class="rr-modal-head">
      <div class="rr-modal-title" id="rrModalTitle">
        <i class="bi bi-arrow-repeat" style="color:var(--purple);"></i>
        Return / Replace Request
      </div>
      <button class="rr-close-btn" onclick="closeReturnModal()" aria-label="Close">✕</button>
    </div>

    <!-- Success screen -->
    <div class="rr-success" id="rrSuccess">
      <div class="rr-success-icon"><i class="bi bi-check-circle-fill"></i></div>
      <h3>Request Submitted!</h3>
      <p>Our team will review within 24–48 hours.</p>
      <div class="rr-req-number" id="rrSuccessId">REQ#—</div>
      <p style="font-size:0.75rem;color:var(--text-soft);margin-top:0.5rem;">
        Track your request status in the order card above.<br>
        Refunds process within 7 business days after approval.
      </p>
    </div>

    <!-- Form -->
    <div id="rrForm">
      <div class="rr-modal-body">

        <div class="rr-policy-box">
          <strong>📋 Return &amp; Replace Policy</strong>
          • Returns within <strong>10 days</strong> of delivery only &nbsp;•&nbsp; Unused, original packaging &nbsp;•&nbsp;
          Perishables &amp; opened personal care: non-returnable &nbsp;•&nbsp; Refund within 7 business days
        </div>

        <!-- Order info -->
        <div style="background:var(--bg);border:1px solid var(--border);border-radius:var(--radius-sm);padding:0.55rem 0.85rem;margin-bottom:1rem;font-size:0.8rem;display:flex;gap:1rem;flex-wrap:wrap;">
          <span style="color:var(--text-soft);">Order <strong id="rrOrderLabel" style="color:var(--text);margin-left:0.3rem;font-family:'Space Mono',monospace;"></strong></span>
          <span style="color:var(--text-soft);">Total <strong id="rrAmtLabel" style="color:var(--purple);margin-left:0.3rem;font-family:'Space Mono',monospace;"></strong></span>
          <span id="rrPayLabel" style="color:var(--text-soft);"></span>
        </div>

        <!-- Type selection -->
        <div class="rr-type-grid">
          <label class="rr-type-card" id="rrTypeReturn" onclick="selectType('Return')">
            <input type="radio" name="rrType" value="Return" class="rr-type-radio">
            <div class="rr-tc-icon">↩️</div>
            <div class="rr-tc-title">Return</div>
            <div class="rr-tc-desc">Send item back &amp; get a refund to your payment method</div>
          </label>
          <label class="rr-type-card" id="rrTypeReplace" onclick="selectType('Replace')">
            <input type="radio" name="rrType" value="Replace" class="rr-type-radio">
            <div class="rr-tc-icon">🔄</div>
            <div class="rr-tc-title">Replace</div>
            <div class="rr-tc-desc">Exchange for the same item — defective, wrong, or damaged</div>
          </label>
        </div>

        <!-- Items -->
        <div class="rr-field">
          <label class="rr-label">Select items <span>*</span></label>
          <div class="rr-items-list" id="rrItemsList"></div>
        </div>

        <!-- Reason chips -->
        <div class="rr-field">
          <label class="rr-label">Reason category <span>*</span></label>
          <div class="rr-reason-chips" id="rrReasonChips"></div>
        </div>

        <!-- Description -->
        <div class="rr-field">
          <label class="rr-label" for="rrDesc">Describe the issue <span>*</span></label>
          <textarea class="rr-textarea" id="rrDesc" placeholder="e.g. Item arrived with broken seal, content was half-used…"></textarea>
        </div>

        <!-- Photo upload -->
        <div class="rr-field">
          <label class="rr-label">Photo evidence <span style="color:var(--text-soft);font-weight:400;">(recommended)</span></label>
          <div class="rr-photo-zone" onclick="document.getElementById('rrPhotoInput').click()">
            <i class="bi bi-camera" style="font-size:1.3rem;color:var(--text-soft);"></i>
            <p>Click to upload photos of the issue<br>
              <span style="font-size:0.68rem;">JPG, PNG, WEBP — max 3 photos, 5MB each</span></p>
          </div>
          <input type="file" id="rrPhotoInput" accept="image/*" multiple style="display:none" onchange="previewPhotos(event)">
          <div class="rr-photo-previews" id="rrPhotoPreviews"></div>
        </div>

        <!-- Bank details (COD refund) -->
        <div id="rrBankSection" style="display:none;" class="rr-bank-section">
          <div style="font-size:0.72rem;font-weight:700;color:var(--text-soft);text-transform:uppercase;letter-spacing:1px;margin-bottom:0.6rem;">
            <i class="bi bi-bank"></i> Refund Bank Details (COD orders)
          </div>
          <div style="display:grid;grid-template-columns:1fr 1fr;gap:0.6rem;">
            <div class="rr-field" style="margin-bottom:0;">
              <label class="rr-label" for="rrAccNum">Account Number</label>
              <input type="text" class="rr-select" id="rrAccNum" placeholder="123456789012">
            </div>
            <div class="rr-field" style="margin-bottom:0;">
              <label class="rr-label" for="rrIfsc">IFSC Code</label>
              <input type="text" class="rr-select" id="rrIfsc" placeholder="SBIN0001234">
            </div>
            <div class="rr-field" style="margin-bottom:0;grid-column:1/-1;">
              <label class="rr-label" for="rrAccName">Account Holder Name</label>
              <input type="text" class="rr-select" id="rrAccName" placeholder="As per bank records">
            </div>
          </div>
        </div>

      </div><!-- /modal-body -->

      <div class="rr-modal-footer">
        <button class="rr-btn-cancel-modal" onclick="closeReturnModal()">Cancel</button>
        <button class="rr-btn-submit" id="rrSubmitBtn" onclick="submitReturnRequest()">
          <i class="bi bi-send"></i> Submit Request
        </button>
      </div>
    </div><!-- /rrForm -->
  </div>
</div>

<!-- ══ CANCEL ORDER MODAL ══ -->
<div class="modal fade" id="cancelOrderModal" tabindex="-1" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered" style="max-width:460px;">
    <div class="modal-content">
      <div class="cancel-modal-header">
        <div class="cancel-modal-title"><i class="bi bi-x-circle-fill"></i> Cancel Order</div>
        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body" style="padding:1.25rem;">
        <div class="cancel-info-row">
          <div><div class="ci-label">Order</div><div class="ci-val" id="co-order-id"></div></div>
          <div><div class="ci-label">Stage</div><div class="ci-val" id="co-stage"></div></div>
          <div><div class="ci-label">Amount</div><div class="ci-val" id="co-amount" style="color:var(--success);font-family:'Space Mono',monospace;"></div></div>
        </div>
        <div class="refund-note-box" id="co-refund-note"></div>
        <div style="margin-bottom:0.85rem;">
          <label class="modal-field-label">Reason <span style="color:var(--danger);">*</span></label>
          <select id="co-reason" class="modal-select">
            <option value="">— Select Reason —</option>
            <option value="changed_mind">Changed my mind</option>
            <option value="found_cheaper">Found cheaper elsewhere</option>
            <option value="wrong_item_ordered">Ordered wrong item</option>
            <option value="delivery_too_slow">Delivery taking too long</option>
            <option value="duplicate_order">Duplicate order placed</option>
            <option value="address_issue">Wrong delivery address</option>
            <option value="other">Other reason</option>
          </select>
        </div>
        <div style="margin-bottom:0.85rem;">
          <label class="modal-field-label">Additional Note</label>
          <textarea id="co-note" rows="2" class="modal-textarea" placeholder="Any additional details…"></textarea>
        </div>
        <div id="co-refund-method-wrap" style="display:none;margin-bottom:0.5rem;">
          <label class="modal-field-label">Refund To</label>
          <select id="co-refund-method" class="modal-select">
            <option value="wallet">💳 Store Wallet (Instant)</option>
            <option value="original">🏦 Original Payment Method (5–7 days)</option>
          </select>
        </div>
        <div class="late-warning" id="co-late-warning" style="display:none;">
          <i class="bi bi-exclamation-triangle-fill"></i>
          Cancellation at this stage may incur a deduction. Review refund amount above.
        </div>
      </div>
      <div class="modal-footer-custom">
        <button type="button" class="btn-keep" data-bs-dismiss="modal">Keep Order</button>
        <button type="button" id="co-confirm-btn" onclick="submitCancelOrder()" class="btn-confirm-cancel">
          <i class="bi bi-x-circle"></i> Confirm Cancellation
        </button>
      </div>
    </div>
  </div>
</div>

<!-- ══ TOAST ══ -->
<div class="toast-wrap" id="toastWrap"></div>

<!-- ══ FOOTER ══ -->
<footer>
  <p>&copy; 2026 <span>SIBS Store</span> — Smart Inventory &amp; Billing System</p>
</footer>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
<script>
/*
 * ── TRACKER PROGRESS BAR ANIMATION (BUG FIX) ──
 *
 * Each .tracker-progress bar stores its target width percentage in data-progress.
 * We read that value and animate to it after a short delay.
 * This ensures the bar STOPS exactly at the active step dot.
 * The width is pre-computed in Java as: (step-1)/(totalSteps-1)*88%
 * so it never overshoots the Delivered dot.
 */
document.addEventListener("DOMContentLoaded", function() {
  document.querySelectorAll(".tracker-progress").forEach(function(bar) {
    const pct = parseFloat(bar.getAttribute("data-progress")) || 0;
    setTimeout(function() {
      bar.style.width = pct + "%";
    }, 400);
  });
});

/* ── Toggle all items ── */
function toggleItems(orderId) {
  const el    = document.getElementById("items_" + orderId);
  const icon  = document.getElementById("toggleIcon_" + orderId);
  const label = document.getElementById("toggleLabel_" + orderId);
  const isOpen = el.style.display !== "none";
  el.style.display = isOpen ? "none" : "block";
  if (label) label.textContent = isOpen ? "All Items" : "Hide Items";
  if (icon)  icon.className   = isOpen ? "bi bi-box-seam" : "bi bi-chevron-up";
}

/* ── Filter orders ── */
function filterOrders(filter, btn) {
  document.querySelectorAll(".filter-btn").forEach(function(b) { b.classList.remove("active"); });
  btn.classList.add("active");
  document.querySelectorAll(".order-card").forEach(function(card) {
    if (filter === "all") { card.style.display = ""; return; }
    const st     = (card.dataset.status    || "").toLowerCase();
    const pst    = (card.dataset.paystatus || "").toLowerCase();
    const isRet  = card.dataset.isreturn === "true";
    let show = false;
    if (filter === "return")           show = isRet || st.startsWith("return") || st === "refunded" || st === "replaced";
    else if (filter === "Delivered")   show = st === "delivered";
    else if (filter === "PAYMENT_FAILED") show = pst === "payment_failed" || pst === "pending_payment";
    else if (filter === "Cancelled")   show = st === "cancelled";
    else                               show = st === filter.toLowerCase();
    card.style.display = show ? "" : "none";
  });
}

/* ── RETURN/REPLACE MODAL ── */
let _rrOrderId = null, _rrPayMethod = null, _rrAmount = null, _rrType = null, _rrChip = null, _rrPhotos = [];

const RR_REASONS = {
  Return:  ["Damaged / broken on arrival","Wrong item received","Item not as described","Missing parts / accessories","Expired product","Changed my mind","Duplicate order","Quality not satisfactory"],
  Replace: ["Damaged / broken on arrival","Wrong item / size / variant","Defective product","Missing parts inside package","Expired product","Item stopped working","Packaging damaged but item ok"]
};

function openReturnModal(orderId, custName, payMethod, amount) {
  _rrOrderId = orderId; _rrPayMethod = payMethod; _rrAmount = amount;
  _rrType = null; _rrChip = null; _rrPhotos = [];
  document.getElementById('rrSuccess').classList.remove('show');
  document.getElementById('rrForm').style.display = '';
  ['rrTypeReturn','rrTypeReplace'].forEach(id => document.getElementById(id).classList.remove('selected'));
  document.getElementById('rrDesc').value = '';
  document.getElementById('rrPhotoPreviews').innerHTML = '';
  document.getElementById('rrPhotoInput').value = '';
  document.getElementById('rrReasonChips').innerHTML = '';
  document.getElementById('rrBankSection').style.display = (payMethod === 'COD') ? 'block' : 'none';
  document.getElementById('rrOrderLabel').textContent = '#' + orderId;
  document.getElementById('rrAmtLabel').textContent   = '₹' + amount;
  document.getElementById('rrPayLabel').textContent   = payMethod;
  populateItemsList(orderId);
  document.getElementById('rrModalOverlay').classList.add('open');
  document.body.style.overflow = 'hidden';
}

function populateItemsList(orderId) {
  const list = document.getElementById('rrItemsList');
  list.innerHTML = '';
  const tbl = document.querySelector('#items_' + orderId + ' .items-table tbody');
  if (!tbl) {
    list.innerHTML = `<label class="rr-item-check">
      <input type="checkbox" name="rrItem" value="item_1" checked>
      <div><div class="rr-item-name">Order item(s)</div><div class="rr-item-meta">All items in this order</div></div>
      <span class="rr-item-price">₹${_rrAmount}</span></label>`;
    return;
  }
  const rows = tbl.querySelectorAll('tr');
  rows.forEach(function(row, i) {
    const cells = row.querySelectorAll('td');
    if (cells.length < 5) return;
    const name  = cells[0].querySelector('strong') ? cells[0].querySelector('strong').textContent.trim() : cells[0].textContent.trim();
    const pack  = cells[1].textContent.trim();
    const qty   = cells[2].textContent.trim();
    const price = cells[4].textContent.trim();
    const div = document.createElement('label');
    div.className = 'rr-item-check';
    div.innerHTML = `<input type="checkbox" name="rrItem" value="item_${i+1}">
      <div><div class="rr-item-name">${name}</div><div class="rr-item-meta">Pack: ${pack} &nbsp;·&nbsp; Qty: ${qty}</div></div>
      <span class="rr-item-price">${price}</span>`;
    list.appendChild(div);
  });
}

function selectType(type) {
  _rrType = type;
  document.getElementById('rrTypeReturn').classList.toggle('selected',  type === 'Return');
  document.getElementById('rrTypeReplace').classList.toggle('selected', type === 'Replace');
  const chips = document.getElementById('rrReasonChips');
  chips.innerHTML = '';
  (RR_REASONS[type] || []).forEach(function(r) {
    const btn = document.createElement('button');
    btn.type = 'button'; btn.className = 'rr-chip'; btn.textContent = r;
    btn.onclick = function() {
      document.querySelectorAll('.rr-chip').forEach(c => c.classList.remove('active'));
      btn.classList.add('active'); _rrChip = r;
    };
    chips.appendChild(btn);
  });
}

function previewPhotos(e) {
  const files = Array.from(e.target.files).slice(0, 3);
  const wrap  = document.getElementById('rrPhotoPreviews');
  wrap.innerHTML = ''; _rrPhotos = files;
  files.forEach(function(file, i) {
    const reader = new FileReader();
    reader.onload = function(ev) {
      const item = document.createElement('div'); item.className = 'rr-photo-item';
      item.innerHTML = `<img src="${ev.target.result}" class="rr-photo-thumb" alt="proof">
        <button class="rr-photo-rm" onclick="removePhoto(${i})">✕</button>`;
      wrap.appendChild(item);
    };
    reader.readAsDataURL(file);
  });
}

function removePhoto(i) {
  _rrPhotos.splice(i, 1);
  document.getElementById('rrPhotoInput').value = '';
  const dt = new DataTransfer();
  _rrPhotos.forEach(f => dt.items.add(f));
  document.getElementById('rrPhotoInput').files = dt.files;
  previewPhotos({ target: { files: dt.files } });
}

function submitReturnRequest() {
  if (!_rrType) { showToast('Please select Return or Replace.', 'warning'); return; }
  const checkedItems = document.querySelectorAll('input[name="rrItem"]:checked');
  if (!checkedItems.length) { showToast('Please select at least one item.', 'warning'); return; }
  if (!_rrChip) { showToast('Please select a reason category.', 'warning'); return; }
  const desc = document.getElementById('rrDesc').value.trim();
  if (desc.length < 10) { showToast('Please describe the issue (min 10 chars).', 'warning'); return; }

  if (_rrPayMethod === 'COD' && _rrType === 'Return') {
    const accNum  = document.getElementById('rrAccNum').value.trim();
    const ifsc    = document.getElementById('rrIfsc').value.trim();
    const accName = document.getElementById('rrAccName').value.trim();
    if (!accNum || !ifsc || !accName) { showToast('Please fill in bank details for COD refund.', 'warning'); return; }
    if (!/^[A-Z]{4}0[A-Z0-9]{6}$/.test(ifsc.toUpperCase())) { showToast('Invalid IFSC code. Format: SBIN0001234', 'warning'); return; }
  }

  const btn = document.getElementById('rrSubmitBtn');
  btn.disabled = true;
  btn.innerHTML = '<i class="bi bi-hourglass-split"></i> Submitting…';

  const fd = new FormData();
  fd.append('action',    'submitReturn');
  fd.append('orderId',   _rrOrderId);
  fd.append('type',      _rrType);
  fd.append('reason',    _rrChip + ': ' + desc);
  fd.append('payMethod', _rrPayMethod);
  checkedItems.forEach(cb => fd.append('items[]', cb.value));
  if (_rrPayMethod === 'COD' && _rrType === 'Return') {
    fd.append('bankAccount', document.getElementById('rrAccNum').value.trim());
    fd.append('bankIfsc',    document.getElementById('rrIfsc').value.trim().toUpperCase());
    fd.append('bankName',    document.getElementById('rrAccName').value.trim());
  }
  _rrPhotos.forEach((f, i) => fd.append('photo_' + i, f));

  fetch('ReturnRequestServlet', { method: 'POST', body: fd })
    .then(r => r.json())
    .then(data => {
      if (data.success) {
        document.getElementById('rrForm').style.display = 'none';
        document.getElementById('rrSuccessId').textContent = 'REQ#' + (data.requestId || '—');
        document.getElementById('rrSuccess').classList.add('show');
        setTimeout(() => location.reload(), 3500);
      } else {
        showToast(data.message || 'Submission failed. Please try again.', 'danger');
        btn.disabled = false;
        btn.innerHTML = '<i class="bi bi-send"></i> Submit Request';
      }
    })
    .catch(function() {
      showToast('Network error. Check your connection.', 'danger');
      btn.disabled = false;
      btn.innerHTML = '<i class="bi bi-send"></i> Submit Request';
    });
}

function closeReturnModal() {
  document.getElementById('rrModalOverlay').classList.remove('open');
  document.body.style.overflow = '';
}
function handleOverlayClick(e) {
  if (e.target === document.getElementById('rrModalOverlay')) closeReturnModal();
}
document.addEventListener('keydown', function(e) { if (e.key === 'Escape') closeReturnModal(); });

/* ── CANCEL ORDER MODAL ── */
let cancelOrderId = null, cancelPayType = null;

function openCancelModal(orderId, customerName, stage, amount, payType, refundNote) {
  cancelOrderId = orderId; cancelPayType = payType;
  document.getElementById('co-order-id').textContent = '#' + orderId;
  document.getElementById('co-stage').textContent    = stage;
  document.getElementById('co-amount').textContent   = '₹' + amount;
  document.getElementById('co-reason').value         = '';
  document.getElementById('co-note').value           = '';
  document.getElementById('co-refund-note').innerHTML = '<i class="bi bi-info-circle"></i> ' + refundNote;
  document.getElementById('co-refund-method-wrap').style.display = payType === 'paid' ? 'block' : 'none';
  const lateStages = ['Packed','Assigned','Picked Up','Shipped','Out for Delivery'];
  document.getElementById('co-late-warning').style.display = lateStages.includes(stage) ? 'flex' : 'none';
  new bootstrap.Modal(document.getElementById('cancelOrderModal')).show();
}

function submitCancelOrder() {
  const reason = document.getElementById('co-reason').value;
  if (!reason) {
    const sel = document.getElementById('co-reason');
    sel.style.borderColor = 'var(--danger)';
    setTimeout(() => { sel.style.borderColor = ''; }, 1000);
    return;
  }
  const note         = document.getElementById('co-note').value;
  const refundMethod = document.getElementById('co-refund-method').value;
  const btn = document.getElementById('co-confirm-btn');
  btn.disabled = true;
  btn.innerHTML = '<span class="spinner-border spinner-border-sm"></span> Cancelling…';

  const params = new URLSearchParams();
  params.append('action',       'cancelOrder');
  params.append('orderId',      cancelOrderId);
  params.append('cancelReason', reason + (note ? ': ' + note : ''));
  params.append('cancelledBy',  'customer');
  params.append('refundMethod', cancelPayType === 'paid' ? refundMethod : 'none');

  fetch('OrdersDashboard', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'X-Requested-With': 'XMLHttpRequest' },
    body: params.toString()
  })
  .then(res => res.json())
  .then(data => {
    if (data.success) {
      bootstrap.Modal.getInstance(document.getElementById('cancelOrderModal')).hide();
      showToast(data.message || 'Order cancelled successfully.', 'success');
      setTimeout(() => location.reload(), 2000);
    } else {
      showToast('Error: ' + (data.message || 'Cancellation failed.'), 'danger');
      btn.disabled = false;
      btn.innerHTML = '<i class="bi bi-x-circle"></i> Confirm Cancellation';
    }
  })
  .catch(() => {
    showToast('Network error. Please try again.', 'danger');
    btn.disabled = false;
    btn.innerHTML = '<i class="bi bi-x-circle"></i> Confirm Cancellation';
  });

}

/* ── TOAST ── */
function showToast(msg, type) {
  const wrap = document.getElementById('toastWrap');
  const colors = { success: 'var(--success)', warning: 'var(--gold)', danger: 'var(--danger)', info: 'var(--sky)' };
  const icons  = { success: 'bi-check-circle-fill', warning: 'bi-exclamation-triangle-fill', danger: 'bi-x-circle-fill', info: 'bi-info-circle-fill' };
  const div = document.createElement('div');
  div.className = 'toast-item';
  div.innerHTML = `<i class="bi ${icons[type] || 'bi-info-circle'}" style="color:${colors[type] || 'var(--sky)'}; font-size:1rem; flex-shrink:0;"></i> ${msg}`;
  wrap.appendChild(div);
  setTimeout(() => { div.style.opacity = '0'; div.style.transition = 'opacity 0.4s'; setTimeout(() => div.remove(), 400); }, 3500);
}
</script>

<jsp:include page="customerBottomNav.jsp"><jsp:param name="activePage" value="orders"/></jsp:include>
</body>
</html>
