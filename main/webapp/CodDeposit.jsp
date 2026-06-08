  <%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*" %>
<%@ page import="com.util.*" %>
<%!
  private static String esc(String s) {
    if (s == null) return "";
    return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;");
  }
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>COD Cash Deposit</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet"/>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css" rel="stylesheet"/>
  <style>
    :root {
      --brand:      #7C5CBF;
      --brand-lt:   #EDE7F6;
      --brand-dk:   #5B3EA6;
      --green:      #2E7D32;
      --green-bg:   #E8F5E9;
      --amber:      #B45309;
      --amber-bg:   #FFF8E1;
      --red:        #C62828;
      --red-bg:     #FFEBEE;
      --blue:       #1565C0;
      --blue-bg:    #E3F2FD;
      --surface:    #F4F6FA;
      --card:       #FFFFFF;
      --border:     #E0E0E0;
      --text1:      #1A1A2E;
      --text2:      #4A4A6A;
      --text3:      #7A7A9A;
      --shadow:     0 2px 12px rgba(0,0,0,0.07);
      --radius:     12px;
      --font:       'Times New Roman', Times, serif;
    }
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: var(--font); background: var(--surface); color: var(--text1); min-height: 100vh; }

    /* ── TOP BAR ── */
    .topbar {
      background: #fff; border-bottom: 1px solid var(--border);
      padding: 14px 24px; display: flex; align-items: center;
      justify-content: space-between; box-shadow: var(--shadow);
      position: sticky; top: 0; z-index: 100;
    }
    .topbar-left { display: flex; align-items: center; gap: 14px; }
    .back-btn {
      display: flex; align-items: center; gap: 6px; text-decoration: none;
      color: var(--brand); font-size: 14px; font-weight: 600;
      border: 1px solid var(--brand); border-radius: 8px; padding: 6px 14px;
      transition: background 0.18s;
    }
    .back-btn:hover { background: var(--brand-lt); text-decoration: none; }
    .page-title { font-size: 20px; font-weight: 700; color: var(--text1); }

    /* ── CONTENT ── */
    .content { max-width: 860px; margin: 0 auto; padding: 28px 20px 60px; }

    /* ── HOW IT WORKS BANNER ── */
    .how-banner {
      background: linear-gradient(135deg, var(--brand-lt) 0%, #fff 100%);
      border: 1px solid #c9b8f0; border-radius: var(--radius);
      padding: 18px 22px; margin-bottom: 28px;
      display: flex; align-items: flex-start; gap: 14px;
    }
    .how-icon { font-size: 28px; flex-shrink: 0; }
    .how-title { font-size: 15px; font-weight: 700; color: var(--brand-dk); margin-bottom: 4px; }
    .how-steps { display: flex; flex-direction: column; gap: 4px; }
    .how-step { font-size: 13px; color: var(--text2); display: flex; align-items: flex-start; gap: 8px; }
    .step-num {
      background: var(--brand); color: #fff; border-radius: 50%;
      width: 18px; height: 18px; font-size: 10px; font-weight: 700;
      display: flex; align-items: center; justify-content: center; flex-shrink: 0; margin-top: 1px;
    }

    /* ── ALERT ── */
    .alert-ok  { background: var(--green-bg); border-left: 4px solid var(--green); color: var(--green); padding: 12px 16px; border-radius: 8px; margin-bottom: 20px; font-size: 14px; }
    .alert-err { background: var(--red-bg);   border-left: 4px solid var(--red);   color: var(--red);   padding: 12px 16px; border-radius: 8px; margin-bottom: 20px; font-size: 14px; }
    .alert-warn{ background: var(--amber-bg); border-left: 4px solid var(--amber); color: var(--amber); padding: 12px 16px; border-radius: 8px; margin-bottom: 20px; font-size: 14px; }

    /* ── SECTION HEADING ── */
    .sec-head { display: flex; align-items: center; gap: 10px; margin-bottom: 16px; }
    .sec-head h2 { font-size: 17px; font-weight: 700; color: var(--text1); }
    .sec-count {
      background: var(--amber-bg); color: var(--amber); border-radius: 12px;
      padding: 2px 10px; font-size: 12px; font-weight: 700;
    }

    /* ── ORDER CARD ── */
    .order-card {
      background: var(--card); border: 1px solid var(--border);
      border-radius: var(--radius); box-shadow: var(--shadow);
      margin-bottom: 16px; overflow: hidden;
    }
    .order-card.deposited { border-left: 4px solid var(--green); opacity: 0.7; }
    .order-card.pending   { border-left: 4px solid var(--amber); }

    .card-top {
      padding: 14px 18px; display: flex; align-items: center;
      justify-content: space-between; background: #FAFAFA;
      border-bottom: 1px solid var(--border);
    }
    .order-id { font-size: 16px; font-weight: 700; color: var(--brand-dk); font-family: 'Courier New', monospace; }
    .order-meta { font-size: 12px; color: var(--text3); margin-top: 2px; }

    .badge {
      padding: 4px 12px; border-radius: 20px; font-size: 12px; font-weight: 700;
    }
    .badge-pending   { background: var(--amber-bg); color: var(--amber); }
    .badge-deposited { background: var(--green-bg); color: var(--green); }
    .badge-cod       { background: #FFF3E0; color: #E65100; }

    .card-body { padding: 16px 18px; }
    .info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; margin-bottom: 14px; }
    .info-item { display: flex; flex-direction: column; gap: 2px; }
    .info-label { font-size: 11px; color: var(--text3); text-transform: uppercase; letter-spacing: 0.05em; }
    .info-value { font-size: 15px; font-weight: 600; color: var(--text1); }
    .info-value.amount { font-size: 20px; color: var(--amber); }
    .info-value.green  { color: var(--green); }

    /* ── DEPOSIT FORM inside each card ── */
    .deposit-form-wrap {
      background: var(--brand-lt); border-radius: 8px;
      padding: 14px 16px; margin-top: 4px;
    }
    .deposit-form-title { font-size: 13px; font-weight: 700; color: var(--brand-dk); margin-bottom: 10px; }
    .form-row { display: flex; gap: 10px; align-items: flex-end; flex-wrap: wrap; }
    .form-group { display: flex; flex-direction: column; gap: 4px; flex: 1; min-width: 120px; }
    .form-group label { font-size: 12px; font-weight: 600; color: var(--text2); }
    .form-group input, .form-group textarea {
      border: 1px solid var(--border); border-radius: 7px;
      padding: 9px 12px; font-family: var(--font); font-size: 14px;
      color: var(--text1); outline: none; background: #fff;
      transition: border-color 0.18s;
    }
    .form-group input:focus, .form-group textarea:focus { border-color: var(--brand); }
    .form-group textarea { resize: vertical; min-height: 56px; }

    .btn-deposit {
      background: var(--amber); color: #fff; border: none;
      border-radius: 8px; padding: 10px 22px; font-size: 14px;
      font-weight: 700; font-family: var(--font); cursor: pointer;
      white-space: nowrap; transition: background 0.18s;
      display: flex; align-items: center; gap: 7px;
    }
    .btn-deposit:hover { background: #9a4500; }
    .btn-deposit:disabled { background: #c8a882; cursor: not-allowed; }

    /* ── EMPTY STATE ── */
    .empty-state {
      background: var(--card); border: 1px solid var(--border);
      border-radius: var(--radius); padding: 48px 24px;
      text-align: center; box-shadow: var(--shadow);
    }
    .empty-icon { font-size: 48px; margin-bottom: 12px; }
    .empty-title { font-size: 18px; font-weight: 700; color: var(--text1); margin-bottom: 6px; }
    .empty-sub { font-size: 14px; color: var(--text3); }

    /* ── WALLET SUMMARY STRIP ── */
    .wallet-strip {
      background: linear-gradient(135deg, var(--brand) 0%, var(--brand-dk) 100%);
      border-radius: var(--radius); padding: 20px 24px; margin-bottom: 28px;
      display: flex; align-items: center; gap: 0; box-shadow: 0 4px 16px rgba(124,92,191,0.25);
    }
    .ws-item { flex: 1; text-align: center; }
    .ws-val  { font-size: 22px; font-weight: 700; color: #fff; }
    .ws-lbl  { font-size: 11px; color: rgba(255,255,255,0.7); margin-top: 3px; text-transform: uppercase; letter-spacing: 0.06em; }
    .ws-sep  { width: 1px; height: 44px; background: rgba(255,255,255,0.2); }

    /* ── DEPOSIT TIMELINE ── */
    .timeline { margin-top: 8px; }
    .tl-step { display: flex; gap: 12px; align-items: flex-start; margin-bottom: 10px; }
    .tl-dot {
      width: 28px; height: 28px; border-radius: 50%; flex-shrink: 0;
      display: flex; align-items: center; justify-content: center;
      font-size: 12px; font-weight: 700; margin-top: 1px;
    }
    .tl-dot.done    { background: var(--green-bg); color: var(--green); }
    .tl-dot.active  { background: var(--amber-bg); color: var(--amber); }
    .tl-dot.waiting { background: #f0f0f0; color: var(--text3); }
    .tl-text { flex: 1; }
    .tl-title { font-size: 13px; font-weight: 700; color: var(--text1); }
    .tl-sub   { font-size: 12px; color: var(--text3); }

    /* ── TOAST ── */
    #_toast {
      position: fixed; bottom: 24px; right: 24px; z-index: 9999;
      background: #fff; border: 1px solid var(--border); border-radius: 10px;
      padding: 13px 20px; font-family: var(--font); font-size: 14px;
      display: flex; align-items: center; gap: 10px;
      box-shadow: 0 4px 20px rgba(0,0,0,0.12); transition: opacity 0.3s;
      min-width: 260px; max-width: 360px; opacity: 0; pointer-events: none;
    }
    #_toast.show { opacity: 1; pointer-events: auto; }

    @media (max-width: 600px) {
      .info-grid { grid-template-columns: 1fr; }
      .form-row  { flex-direction: column; }
      .wallet-strip { flex-direction: column; gap: 14px; }
      .ws-sep { width: 100%; height: 1px; }
    }
  </style>
</head>
<body>
<%
String viewMode = (String) request.getAttribute("viewMode");
if (viewMode == null) viewMode = "agent"; // safe default

User deliveryUser = null;
User staffUser    = null;

if ("staff".equals(viewMode)) {
  staffUser = (User) session.getAttribute("user");
  if (staffUser == null) {
    response.sendRedirect(request.getContextPath() + "/index.jsp");
    return;
  }
} else {
  deliveryUser = (User) session.getAttribute("deliveryUser");
  if (deliveryUser == null) {
    response.sendRedirect(request.getContextPath() + "/deliveryLogin.jsp");
    return;
  }
}
  // FIX: agent view uses "pendingOrders" attribute (set by CodDepositServlet agent path);
  //      staff view uses "allPendingDeposits" (all agents). Previously both always read
  //      allPendingDeposits, so the agent list was always empty.
  List<Order> pendingOrders;
  if ("staff".equals(viewMode)) {
    pendingOrders = (List<Order>) request.getAttribute("allPendingDeposits");
  } else {
    pendingOrders = (List<Order>) request.getAttribute("pendingOrders");
  }
  if (pendingOrders == null) pendingOrders = new ArrayList<>();

  String msgAttr = (String) request.getAttribute("msg");
  String errAttr = (String) request.getAttribute("err");

  // Count totals
  double totalPendingCash = 0.0;
  for (Order o : pendingOrders) totalPendingCash += o.getTotalAmount();
%>

<!-- TOPBAR -->
<div class="topbar">
  <div class="topbar-left">
    <a class="back-btn" href="DeliveryPortalServlet"><i class="bi bi-arrow-left"></i> Portal</a>
    <div class="page-title"><i class="bi bi-cash-coin" style="color:var(--amber);"></i> COD Cash Deposit</div>
  </div>
  <div style="font-size:13px;color:var(--text3);">
    Welcome, <strong style="color:var(--text1);"><%= deliveryUser.getUsername() %></strong>
  </div>
</div>

<div class="content">

  <!-- ALERTS -->
 <% if (msgAttr != null) { %>
  <div class="alert-ok"><i class="bi bi-check-circle-fill"></i> <%= esc(msgAttr) %></div>
<% } %>
<% if (errAttr != null) { %>
  <div class="alert-err"><i class="bi bi-x-circle-fill"></i> <%= esc(errAttr) %></div>
<% } %>
  <!-- HOW IT WORKS -->
  <div class="how-banner">
    <div class="how-icon">💡</div>
    <div>
      <div class="how-title">How COD Cash Deposit Works</div>
      <div class="how-steps">
        <div class="how-step">
          <span class="step-num">1</span>
          <span><strong>You delivered a COD order</strong> and collected cash from the customer.</span>
        </div>
        <div class="how-step">
          <span class="step-num">2</span>
          <span><strong>Hand the cash to the hub supervisor</strong> — click "Deposit" below for each order.</span>
        </div>
        <div class="how-step">
          <span class="step-num">3</span>
          <span><strong>Staff confirms receipt</strong> → order marked PAID, your COD hold is cleared.</span>
        </div>
        <div class="how-step">
          <span class="step-num">4</span>
          <span><strong>Your delivery fee (₹60) is credited</strong> automatically. You can withdraw earnings anytime.</span>
        </div>
      </div>
    </div>
  </div>

  <!-- WALLET SUMMARY STRIP -->
  <div class="wallet-strip" id="walletStrip">
    <div class="ws-item">
      <div class="ws-val" id="wsCashHand">₹—</div>
      <div class="ws-lbl">Cash in Hand</div>
    </div>
    <div class="ws-sep"></div>
    <div class="ws-item">
      <div class="ws-val" id="wsPendingCount"><%= pendingOrders.size() %></div>
      <div class="ws-lbl">Orders Pending</div>
    </div>
    <div class="ws-sep"></div>
    <div class="ws-item">
      <div class="ws-val">₹<%= String.format("%.0f", totalPendingCash) %></div>
      <div class="ws-lbl">Total to Deposit</div>
    </div>
    <div class="ws-sep"></div>
    <div class="ws-item">
      <div class="ws-val" id="wsEarnings">₹—</div>
      <div class="ws-lbl">Today's Earnings</div>
    </div>
  </div>
<% if ("staff".equals(viewMode)) { 
   List<com.util.Order> allDeposits = 
       (List<com.util.Order>) request.getAttribute("allPendingDeposits");
   List<java.util.Map<String, Object>> slotLiability = 
       (List<java.util.Map<String, Object>>) request.getAttribute("openSlotLiability");
   if (allDeposits == null) allDeposits = new java.util.ArrayList<>();
%>
<div class="content">
  <div class="sec-head">
    <i class="bi bi-people-fill" style="color:var(--brand);font-size:20px;"></i>
    <h2>All Pending COD Deposits</h2>
    <span class="sec-count"><%= allDeposits.size() %> order(s)</span>
  </div>

  <% if (allDeposits.isEmpty()) { %>
  <div class="empty-state">
    <div class="empty-icon">✅</div>
    <div class="empty-title">No Pending Deposits</div>
    <div class="empty-sub">All agents have cleared their COD cash.</div>
  </div>
  <% } else { for (com.util.Order o : allDeposits) { %>
  <div class="order-card pending">
    <div class="card-top">
      <div>
        <div class="order-id">#<%= o.getId() %></div>
        <div class="order-meta">Agent #<%= o.getDeliveryUserId() %>
            · Delivered <%= o.getDeliveryDate() != null ? o.getDeliveryDate() : "—" %></div>
      </div>
      <span class="badge badge-cod"><i class="bi bi-cash"></i> COD</span>
    </div>
    <div class="card-body">
      <div class="info-grid">
        <div class="info-item">
          <div class="info-label">Customer</div>
          <div class="info-value"><%= esc(o.getCustomerName() != null ? o.getCustomerName() : "—") %></div>
        </div>
        <div class="info-item">
          <div class="info-label">Amount</div>
          <div class="info-value amount">₹<%= String.format("%.2f", o.getTotalAmount()) %></div>
        </div>
      </div>
      <div style="display:flex;gap:10px;margin-top:12px;flex-wrap:wrap;">
        <button class="btn-deposit" style="background:var(--green);"
                onclick="staffConfirmDeposit(<%= o.getId() %>, <%= o.getDeliveryUserId() %>, <%= o.getTotalAmount() %>)">
          <i class="bi bi-check-circle"></i> Confirm Receipt
        </button>
        <button class="btn-deposit" style="background:var(--red-bg);color:var(--red);border:1px solid var(--red);"
                onclick="staffRejectDeposit(<%= o.getId() %>, <%= o.getDeliveryUserId() %>)">
          <i class="bi bi-x-circle"></i> Flag Dispute
        </button>
      </div>
    </div>
  </div>
  <% } } %>
</div>

<script>
function staffConfirmDeposit(orderId, agentId, amount) {
  if (!confirm('Confirm cash receipt of ₹' + amount.toFixed(2) + ' for Order #' + orderId + '?')) return;
  const params = new URLSearchParams();
  params.append('action',  'staffConfirm');
  params.append('orderId',  orderId);
  params.append('agentId',  agentId);
  params.append('amount',   amount.toFixed(2));
  fetch('<%= request.getContextPath() %>/CodDepositServlet',
    { method:'POST', body: params,
      headers:{'Content-Type':'application/x-www-form-urlencoded'} })
    .then(r => r.json())
    .then(d => { alert(d.message); if (d.success) location.reload(); })
    .catch(() => alert('Network error.'));
}
function staffRejectDeposit(orderId, agentId) {
  const reason = prompt('Reason for flagging Order #' + orderId + '?');
  if (!reason) return;
  const params = new URLSearchParams();
  params.append('action',  'staffReject');
  params.append('orderId',  orderId);
  params.append('agentId',  agentId);
  params.append('reason',   reason);
  fetch('<%= request.getContextPath() %>/CodDepositServlet',
    { method:'POST', body: params,
      headers:{'Content-Type':'application/x-www-form-urlencoded'} })
    .then(r => r.json())
    .then(d => { alert(d.message); if (d.success) location.reload(); })
    .catch(() => alert('Network error.'));
}
</script>

<% } /* end staff view */ %>
  <!-- PENDING ORDERS LIST -->
  <div class="sec-head">
    <i class="bi bi-clock-history" style="color:var(--amber);font-size:20px;"></i>
    <h2>Cash to Deposit</h2>
    <% if (!pendingOrders.isEmpty()) { %>
      <span class="sec-count"><%= pendingOrders.size() %> order<%= pendingOrders.size()>1?"s":"" %></span>
    <% } %>
  </div>

  <% if (pendingOrders.isEmpty()) { %>
    <div class="empty-state">
      <div class="empty-icon">✅</div>
      <div class="empty-title">All Caught Up!</div>
      <div class="empty-sub">You have no pending COD cash deposits.<br>
        All your delivered COD orders have been settled.</div>
      <div style="margin-top:20px;">
        <a href="DeliveryPortalServlet" class="btn-deposit" style="display:inline-flex;background:var(--brand);">
          <i class="bi bi-grid-1x2"></i> Back to Dashboard
        </a>
      </div>
    </div>

  <% } else {
       for (Order order : pendingOrders) {
         String custName = order.getCustomerName() != null ? order.getCustomerName() : "Customer";
         String addr     = order.getAddress()      != null ? order.getAddress()      : "—";
         String delivDate= order.getDeliveryDate() != null ? order.getDeliveryDate().toString() : "Today";
  %>

  <div class="order-card pending" id="card-<%= order.getId() %>">
    <!-- Card Top -->
    <div class="card-top">
      <div>
        <div class="order-id">#<%= order.getId() %></div>
        <div class="order-meta">Delivered <%= delivDate %></div>
      </div>
      <div style="display:flex;gap:6px;align-items:center;">
        <span class="badge badge-cod"><i class="bi bi-cash"></i> COD</span>
        <span class="badge badge-pending" id="badge-<%= order.getId() %>">
          <i class="bi bi-hourglass-split"></i> Deposit Pending
        </span>
      </div>
    </div>

    <div class="card-body">
      <!-- Order Info Grid -->
      <div class="info-grid">
        <div class="info-item">
          <div class="info-label">Customer</div>
          <div class="info-value"><%= esc(custName) %></div>
        </div>
        <div class="info-item">
          <div class="info-label">Cash to Deposit</div>
          <div class="info-value amount">₹<%= String.format("%.2f", order.getTotalAmount()) %></div>
        </div>
        <% if (!addr.equals("—")) { %>
        <div class="info-item" style="grid-column:1/-1;">
          <div class="info-label">Delivery Address</div>
          <div class="info-value" style="font-size:13px;font-weight:400;color:var(--text2);"><%= esc(addr) %></div>
        </div>
        <% } %>
      </div>

      <!-- HOW THE DEPOSIT WORKS for this order -->
      <div class="timeline">
        <div class="tl-step">
          <div class="tl-dot done"><i class="bi bi-check"></i></div>
          <div class="tl-text">
            <div class="tl-title">Order Delivered</div>
            <div class="tl-sub">You collected ₹<%= String.format("%.2f", order.getTotalAmount()) %> cash from customer</div>
          </div>
        </div>
        <div class="tl-step">
          <div class="tl-dot active">2</div>
          <div class="tl-text">
            <div class="tl-title">Deposit Cash at Hub</div>
            <div class="tl-sub">Hand cash to supervisor and click "Deposit" below</div>
          </div>
        </div>
        <div class="tl-step">
          <div class="tl-dot waiting">3</div>
          <div class="tl-text">
            <div class="tl-title">Staff Confirms Receipt</div>
            <div class="tl-sub">Supervisor verifies amount → order marked PAID</div>
          </div>
        </div>
        <div class="tl-step">
          <div class="tl-dot waiting">4</div>
          <div class="tl-text">
            <div class="tl-title">Fee Credited & COD Hold Cleared</div>
            <div class="tl-sub">Your ₹60 delivery fee is credited. Balance updated.</div>
          </div>
        </div>
      </div>

      <!-- DEPOSIT FORM -->
      <div class="deposit-form-wrap" id="form-<%= order.getId() %>">
        <div class="deposit-form-title">
          <i class="bi bi-cash-stack"></i> Deposit ₹<%= String.format("%.2f", order.getTotalAmount()) %> for Order #<%= order.getId() %>
        </div>
        <div class="form-row">
          <div class="form-group">
            <label>Amount Depositing (₹)</label>
            <input type="number" id="amt-<%= order.getId() %>"
                   value="<%= String.format("%.2f", order.getTotalAmount()) %>"
                   step="0.01" min="0.01"
                   placeholder="Enter exact cash amount"/>
          </div>
          <div class="form-group" style="flex:2;">
            <label>Notes (optional)</label>
            <input type="text" id="notes-<%= order.getId() %>"
                   placeholder="e.g. Gave to Raju sir at counter 3"/>
          </div>
          <div class="form-group"  style="display:flex;;">
            <label>&nbsp;</label>  
            
            <!-- Cash at hub (Option A — simple record) -->
		    <button class="btn-deposit" style="background:var(--amber);"
		            id="btn-cash-<%= order.getId() %>"
		            onclick="confirmCashAtHub(<%= order.getId() %>, <%= order.getTotalAmount() %>)">
		      <i class="bi bi-cash-stack"></i> Cash at Hub
		    </button>
          </div>
          
        </div>
        <div style="font-size:12px;color:var(--text2);margin-top:8px;">
          <i class="bi bi-info-circle"></i>
          Make sure you're handing cash to the hub supervisor before clicking Deposit.
          This action cannot be undone.
        </div>
      </div>

    </div><!-- /card-body -->
  </div><!-- /order-card -->

  <% } } // end for / else %>

  <!-- BACK LINK -->
  <% if (!pendingOrders.isEmpty()) { %>
  <div style="margin-top:24px;text-align:center;">
    <a href="DeliveryPortalServlet" style="color:var(--text3);font-size:14px;text-decoration:none;">
      <i class="bi bi-arrow-left"></i> Back to Dashboard
    </a>
  </div>
  <% } %>

</div><!-- /content -->

<!-- ── CASH AT HUB CONFIRM MODAL ──────────────────────────────────── -->
<div id="cashConfirmModal" style="
  display:none; position:fixed; inset:0; z-index:10000;
  background:rgba(0,0,0,0.45); align-items:center; justify-content:center;">
  <div style="
    background:#fff; border-radius:14px; padding:28px 28px 24px;
    max-width:420px; width:calc(100% - 40px); box-shadow:0 8px 32px rgba(0,0,0,0.2);
    font-family:var(--font);">

    <div style="display:flex;align-items:center;gap:12px;margin-bottom:18px;">
      <div style="
        width:42px;height:42px;border-radius:50%;background:var(--amber-bg);
        display:flex;align-items:center;justify-content:center;flex-shrink:0;">
        <i class="bi bi-cash-stack" style="font-size:20px;color:var(--amber);"></i>
      </div>
      <div>
        <div style="font-size:16px;font-weight:700;color:var(--text1);">Confirm Cash Handover</div>
        <div style="font-size:12px;color:var(--text3);" id="modal-order-label">Order #&mdash;</div>
      </div>
    </div>

    <div style="
      background:var(--amber-bg);border-radius:9px;padding:14px 16px;
      margin-bottom:18px;display:flex;flex-direction:column;gap:9px;">
      <label style="display:flex;align-items:center;gap:10px;cursor:pointer;font-size:13px;color:var(--text2);">
        <input type="checkbox" id="chk1" onchange="updateModalBtn()" style="width:16px;height:16px;accent-color:var(--amber);">
        I have physically handed <strong id="modal-amount-label" style="color:var(--amber);margin:0 4px;">&#8377;&mdash;</strong> cash to the hub supervisor.
      </label>
      <label style="display:flex;align-items:center;gap:10px;cursor:pointer;font-size:13px;color:var(--text2);">
        <input type="checkbox" id="chk2" onchange="updateModalBtn()" style="width:16px;height:16px;accent-color:var(--amber);">
        The supervisor has acknowledged receipt.
      </label>
      <label style="display:flex;align-items:center;gap:10px;cursor:pointer;font-size:13px;color:var(--text2);">
        <input type="checkbox" id="chk3" onchange="updateModalBtn()" style="width:16px;height:16px;accent-color:var(--amber);">
        The amount in the form matches the exact cash I handed over.
      </label>
    </div>

    <div style="
      border:1px solid var(--border);border-radius:8px;padding:11px 14px;
      margin-bottom:18px;display:flex;justify-content:space-between;align-items:center;">
      <span style="font-size:13px;color:var(--text3);">Amount being recorded</span>
      <span id="modal-amount-big" style="font-size:20px;font-weight:700;color:var(--amber);">&#8377;&mdash;</span>
    </div>

    <div style="font-size:12px;color:var(--text3);margin-bottom:18px;display:flex;gap:6px;align-items:flex-start;">
      <i class="bi bi-exclamation-triangle-fill" style="color:var(--amber);flex-shrink:0;margin-top:1px;"></i>
      This records the cash handover. Hub staff must still confirm before the order is marked DEPOSITED.
    </div>

    <div style="display:flex;gap:10px;justify-content:flex-end;">
      <button onclick="closeCashModal()" style="
        border:1px solid var(--border);background:#fff;color:var(--text2);
        border-radius:8px;padding:9px 20px;font-size:14px;font-weight:600;
        font-family:var(--font);cursor:pointer;">
        Cancel
      </button>
      <button id="modal-confirm-btn" onclick="submitCashAtHub()" disabled style="
        background:var(--amber);color:#fff;border:none;
        border-radius:8px;padding:9px 22px;font-size:14px;font-weight:700;
        font-family:var(--font);cursor:not-allowed;opacity:0.5;
        display:flex;align-items:center;gap:7px;">
        <i class="bi bi-check-circle"></i> Yes, I Handed the Cash
      </button>
    </div>
  </div>
</div>

<!-- TOAST -->
<div id="_toast"></div>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>

<script>
const CTX = '<%= request.getContextPath() %>';
window.CTX = CTX;

/* ── CASH AT HUB CONFIRM MODAL ──────────────────────────────────────
   State kept here so submitCashAtHub() knows which order to act on.
   ─────────────────────────────────────────────────────────────────── */
let _modalOrderId      = null;
let _modalExpectedAmt  = null;

function confirmCashAtHub(orderId, expectedAmount) {
  if (_depositState && (_depositState[orderId] === 'processing' || _depositState[orderId] === 'done' || _depositState[orderId] === 'submitted')) return;

  // Read the current amount from the input (agent may have edited it)
  const amtInput = document.getElementById('amt-' + orderId);
  const amount   = amtInput ? parseFloat(amtInput.value) || expectedAmount : expectedAmount;

  _modalOrderId     = orderId;
  _modalExpectedAmt = amount;

  // Populate modal labels
  document.getElementById('modal-order-label').textContent  = 'Order #' + orderId;
  document.getElementById('modal-amount-label').textContent = '\u20b9' + amount.toFixed(2);
  document.getElementById('modal-amount-big').textContent   = '\u20b9' + amount.toFixed(2);

  // Reset checkboxes + button
  ['chk1','chk2','chk3'].forEach(id => { document.getElementById(id).checked = false; });
  const confirmBtn = document.getElementById('modal-confirm-btn');
  confirmBtn.disabled   = true;
  confirmBtn.style.opacity    = '0.5';
  confirmBtn.style.cursor     = 'not-allowed';

  // Show modal
  const modal = document.getElementById('cashConfirmModal');
  modal.style.display = 'flex';
}

function updateModalBtn() {
  const allChecked = ['chk1','chk2','chk3'].every(id => document.getElementById(id).checked);
  const btn = document.getElementById('modal-confirm-btn');
  btn.disabled         = !allChecked;
  btn.style.opacity    = allChecked ? '1' : '0.5';
  btn.style.cursor     = allChecked ? 'pointer' : 'not-allowed';
}

function closeCashModal() {
  document.getElementById('cashConfirmModal').style.display = 'none';
  _modalOrderId = _modalExpectedAmt = null;
}

// Close modal if backdrop clicked
document.getElementById('cashConfirmModal').addEventListener('click', function(e) {
  if (e.target === this) closeCashModal();
});

function submitCashAtHub() {
  const orderId = _modalOrderId;
  const amount  = _modalExpectedAmt;
  if (!orderId || !amount) return;

  closeCashModal();

  // Delegate to the existing depositCashAtHub in delivery-portal.js
  depositCashAtHub(orderId, amount);
}
</script>




<script src="<%=request.getContextPath()%>/js/delivery-portal.js"></script>
<script>
/* ── On DOM-ready: populate wallet strip and show low-balance advisory ── */
document.addEventListener('DOMContentLoaded', () => {
  if (typeof checkCodDepositBalance === 'function') {
    checkCodDepositBalance();
  }
});
</script>

</body>
</html>
