<%@ page contentType="text/html; charset=UTF-8" isELIgnored="false" %>
<%@ page import="com.util.*, java.util.*" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%
    /* ══ Auth guard ══ */
    String _bRole  = (session != null) ? (String) session.getAttribute("role")     : null;
    String _bUname = (session != null) ? (String) session.getAttribute("username") : null;
    if (_bRole == null || !"admin".equalsIgnoreCase(_bRole)) {
        out.print("<p style='color:#ef4444;font-family:Nunito,sans-serif;padding:2rem'>"
                + "<i class='bi bi-lock me-2'></i>Access denied.</p>");
        return;
    }
    /* Stats come from BillsServlet request attributes */
    int    _totalBills   = request.getAttribute("totalBills")   != null ? (Integer) request.getAttribute("totalBills")   : 0;
    long   _paidCount    = request.getAttribute("paidCount")    != null ? (Long)    request.getAttribute("paidCount")    : 0L;
    long   _refundCount  = request.getAttribute("refundedCount")!= null ? (Long)    request.getAttribute("refundedCount"): 0L;

    @SuppressWarnings("unchecked")
    java.util.List<Order> _orders = (java.util.List<Order>) request.getAttribute("orders");
    if (_orders == null) _orders = new java.util.ArrayList<>();

    double _totalRevenue = _orders.stream()
        .filter(o -> "PAID".equalsIgnoreCase(o.getPaymentStatus()))
        .mapToDouble(Order::getTotalAmount).sum();

    long _codCount = _orders.stream()
        .filter(o -> "PENDING_COD".equalsIgnoreCase(o.getPaymentStatus())).count();

    @SuppressWarnings("unchecked")
    java.util.List<java.util.Map<String,Object>> _rejectionSummary =
        (java.util.List<java.util.Map<String,Object>>) request.getAttribute("rejectionSummary");
    if (_rejectionSummary == null) _rejectionSummary = new java.util.ArrayList<>();

    @SuppressWarnings("unchecked")
    java.util.List<java.util.Map<String,Object>> _pendingWithdrawals =
        (java.util.List<java.util.Map<String,Object>>) request.getAttribute("pendingWithdrawals");
    if (_pendingWithdrawals == null) _pendingWithdrawals = new java.util.ArrayList<>();

    String _genDate = new java.text.SimpleDateFormat("dd MMM yyyy, hh:mm a").format(new java.util.Date());
%>

<%-- ═══════════════════════════════════════════════════════════════════════════
     adminBillFragment.jsp
     Loaded as an AJAX fragment into dashboard.jsp#mainContent — NO <html>/<body>.
     Inherits: Nunito font, Bootstrap 5, Bootstrap Icons, CSS vars from dashboard.
═══════════════════════════════════════════════════════════════════════════ --%>

<style>
/* ── Page header ── */
.abf-header{display:flex;align-items:flex-start;justify-content:space-between;flex-wrap:wrap;gap:1rem;margin-bottom:1.75rem;padding-bottom:1.2rem;border-bottom:2px solid var(--border)}
.abf-title{font-family:'Nunito',sans-serif;font-size:1.5rem;font-weight:800;color:var(--text-dark);margin:0 0 .25rem;display:flex;align-items:center;gap:.55rem}
.abf-title i{color:var(--primary)}
.abf-sub{font-family:'Nunito',sans-serif;font-size:.83rem;color:var(--text-muted)}
.abf-header-actions{display:flex;gap:.6rem;flex-wrap:wrap;align-items:center}
.abf-btn{display:inline-flex;align-items:center;gap:.4rem;font-family:'Nunito',sans-serif;font-size:.8rem;font-weight:700;padding:.5rem 1.1rem;border-radius:8px;text-decoration:none;transition:all .18s;cursor:pointer;border:none}
.abf-btn-outline{background:#fff;color:var(--text-mid);border:1.5px solid var(--border)}
.abf-btn-outline:hover{border-color:var(--primary);color:var(--primary);background:var(--accent-light)}
.abf-btn-solid{background:var(--primary);color:#fff;border:1.5px solid var(--primary)}
.abf-btn-solid:hover{background:var(--primary-dark)}

/* ── Stat cards ── */
.abf-stats{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:1rem;margin-bottom:1.5rem}
.abf-stat{background:var(--bg-white);border:1px solid var(--border);border-radius:var(--radius);padding:1.2rem 1.25rem;display:flex;align-items:center;gap:.95rem;box-shadow:var(--shadow-sm);transition:transform .2s,box-shadow .2s}
.abf-stat:hover{transform:translateY(-2px);box-shadow:var(--shadow-md)}
.abf-stat-icon{width:44px;height:44px;border-radius:10px;display:flex;align-items:center;justify-content:center;font-size:1.2rem;flex-shrink:0}
.abf-stat-icon.blue{background:#dbeafe;color:#1d4ed8}
.abf-stat-icon.green{background:#dcfce7;color:#15803d}
.abf-stat-icon.red{background:#fee2e2;color:#b91c1c}
.abf-stat-icon.amber{background:#fef3c7;color:#92400e}
.abf-stat-icon.purple{background:#ede9fe;color:#6d28d9}
.abf-stat-num{font-family:'Nunito',sans-serif;font-size:1.35rem;font-weight:800;color:var(--text-dark);line-height:1}
.abf-stat-lbl{font-size:.7rem;font-weight:600;color:var(--text-muted);text-transform:uppercase;letter-spacing:.5px;margin-top:.2rem}

/* ── Tab nav ── */
.abf-tabs{display:flex;gap:.35rem;background:var(--bg-white);border:1px solid var(--border);border-radius:var(--radius);padding:.4rem;margin-bottom:1.25rem;flex-wrap:wrap;box-shadow:var(--shadow-sm)}
.abf-tab{display:inline-flex;align-items:center;gap:.4rem;font-family:'Nunito',sans-serif;font-size:.81rem;font-weight:700;padding:.5rem 1rem;border-radius:7px;border:none;background:transparent;color:var(--text-muted);cursor:pointer;transition:all .18s;white-space:nowrap}
.abf-tab:hover{background:var(--bg-off);color:var(--text-dark)}
.abf-tab.active{background:var(--primary);color:#fff;box-shadow:0 2px 8px rgba(14,165,233,.3)}
.abf-tab i{font-size:.85rem}

/* ── Tab panels ── */
.abf-panel{display:none}
.abf-panel.active{display:block}

/* ── Toolbar ── */
.abf-toolbar{display:flex;align-items:center;gap:.75rem;flex-wrap:wrap;margin-bottom:1rem}
.abf-search{display:flex;align-items:center;gap:.5rem;background:var(--bg-white);border:1.5px solid var(--border);border-radius:8px;padding:.45rem .9rem;min-width:220px;flex:1;max-width:340px;transition:border-color .18s}
.abf-search:focus-within{border-color:var(--primary)}
.abf-search i{color:var(--text-muted);font-size:.9rem;flex-shrink:0}
.abf-search input{border:none;outline:none;font-family:'Nunito',sans-serif;font-size:.85rem;background:transparent;color:var(--text-dark);width:100%}
.abf-filter{font-family:'Nunito',sans-serif;font-size:.82rem;background:var(--bg-white);border:1.5px solid var(--border);border-radius:8px;padding:.44rem .85rem;color:var(--text-dark);cursor:pointer;outline:none;transition:border-color .18s}
.abf-filter:focus{border-color:var(--primary)}
.abf-toolbar-right{margin-left:auto;display:flex;align-items:center;gap:.6rem}
.abf-count-chip{font-family:'Nunito',sans-serif;font-size:.72rem;font-weight:700;color:var(--text-muted);background:var(--bg-off);border:1px solid var(--border);border-radius:20px;padding:.2rem .75rem}

/* ── Table card ── */
.abf-table-card{background:var(--bg-white);border:1px solid var(--border);border-radius:var(--radius);overflow:hidden;box-shadow:var(--shadow-sm)}
.abf-table-head{display:flex;align-items:center;justify-content:space-between;padding:.85rem 1.25rem;border-bottom:1px solid var(--border);background:var(--bg-off)}
.abf-table-title{font-family:'Nunito',sans-serif;font-size:.82rem;font-weight:700;color:var(--text-mid);display:flex;align-items:center;gap:.4rem}
.abf-table-meta{font-size:.7rem;color:var(--text-muted)}
.abf-table-scroll{overflow-x:auto}
.abf-table{width:100%;border-collapse:collapse;font-family:'Nunito',sans-serif;font-size:.83rem}
.abf-table thead th{background:var(--bg-off);padding:.75rem 1rem;font-size:.7rem;font-weight:700;text-transform:uppercase;letter-spacing:.7px;color:var(--text-muted);border-bottom:1px solid var(--border);white-space:nowrap;text-align:left}
.abf-table tbody tr{border-bottom:1px solid var(--border);transition:background .15s}
.abf-table tbody tr:hover{background:var(--accent-light)}
.abf-table tbody tr:last-child{border-bottom:none}
.abf-table td{padding:.8rem 1rem;color:var(--text-dark);vertical-align:middle}
.abf-no-results{display:none;text-align:center;padding:3rem 1rem;color:var(--text-muted);font-size:.88rem}
.abf-no-results i{font-size:2.5rem;display:block;margin-bottom:.75rem;color:var(--border)}
.abf-empty{text-align:center;padding:3rem 1rem;color:var(--text-muted)}
.abf-empty i{font-size:2.5rem;display:block;margin-bottom:.75rem;color:var(--border)}

/* ── Table cell types ── */
.abf-order-id{font-weight:700;color:var(--primary-dark);font-size:.82rem}
.abf-cust-name{font-weight:700;color:var(--text-dark);font-size:.84rem}
.abf-cust-email{font-size:.72rem;color:var(--text-muted);margin-top:.1rem}
.abf-amount{font-weight:800;color:var(--text-dark)}
.abf-txn{font-family:monospace;font-size:.75rem;color:var(--text-mid);background:var(--bg-off);padding:.15rem .5rem;border-radius:5px;border:1px solid var(--border)}
.abf-date{font-size:.8rem;color:var(--text-muted)}

/* ── Badges ── */
.abf-badge{display:inline-flex;align-items:center;gap:.28rem;font-size:.7rem;font-weight:700;padding:.24rem .65rem;border-radius:20px;letter-spacing:.3px;white-space:nowrap}
.abf-badge i{font-size:.7rem}
.abf-b-pending{background:#fef3c7;color:#92400e;border:1px solid #fde68a}
.abf-b-packed{background:#dbeafe;color:#1d4ed8;border:1px solid #bfdbfe}
.abf-b-shipped{background:#ede9fe;color:#6d28d9;border:1px solid #ddd6fe}
.abf-b-ofd{background:#ffedd5;color:#c2410c;border:1px solid #fed7aa}
.abf-b-delivered{background:#dcfce7;color:#15803d;border:1px solid #bbf7d0}
.abf-b-cancelled{background:#fee2e2;color:#b91c1c;border:1px solid #fecaca}
.abf-b-paid{background:#dcfce7;color:#15803d;border:1px solid #bbf7d0}
.abf-b-refunded{background:#f3e8ff;color:#7e22ce;border:1px solid #e9d5ff}
.abf-b-cod{background:#fef3c7;color:#92400e;border:1px solid #fde68a}
.abf-pay-pill{display:inline-flex;align-items:center;gap:.3rem;font-size:.72rem;font-weight:700;padding:.22rem .65rem;border-radius:12px;white-space:nowrap}
.abf-pp-cod{background:#fff7ed;color:#c2410c;border:1px solid #fed7aa}
.abf-pp-card{background:#eff6ff;color:#1d4ed8;border:1px solid #bfdbfe}
.abf-pp-upi{background:#f0fdf4;color:#15803d;border:1px solid #bbf7d0}
.abf-pp-unknown{background:var(--bg-off);color:var(--text-muted);border:1px solid var(--border)}

/* ── Agent rows ── */
.abf-agent-row{display:flex;align-items:flex-start;gap:1rem;padding:1rem 1.25rem;border-bottom:1px solid var(--border)}
.abf-agent-row:last-child{border-bottom:none}
.abf-av{width:40px;height:40px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-weight:800;font-size:.95rem;color:#fff;flex-shrink:0}
.abf-av-red{background:linear-gradient(135deg,#ef4444,#b91c1c)}
.abf-av-amber{background:linear-gradient(135deg,#f59e0b,#b45309)}
.abf-agent-name{font-size:.88rem;font-weight:700;color:var(--text-dark)}
.abf-agent-meta{font-size:.72rem;color:var(--text-muted);margin-top:.15rem}
.abf-wd-amount{font-size:1.05rem;font-weight:800;color:#15803d;margin-top:.25rem}
.abf-rej-badge{width:32px;height:32px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:.85rem;font-weight:800;color:#fff;flex-shrink:0;margin-left:auto}
.abf-rc-1{background:#f59e0b}
.abf-rc-2{background:#ef4444}
.abf-rc-3{background:#7f1d1d}
.abf-act-btns{display:flex;gap:.5rem;flex-wrap:wrap;margin-top:.6rem}
.abf-act{display:inline-flex;align-items:center;gap:.3rem;font-size:.72rem;font-weight:700;padding:.28rem .75rem;border-radius:6px;border:1px solid var(--border);background:#fff;color:var(--text-mid);cursor:pointer;transition:all .18s;font-family:'Nunito',sans-serif}
.abf-act:hover{border-color:var(--primary);color:var(--primary)}
.abf-act.approve{border-color:rgba(21,128,61,.3);color:#15803d}
.abf-act.approve:hover{background:#dcfce7}
.abf-act.dismiss{border-color:rgba(245,158,11,.3);color:#b45309}
.abf-act.dismiss:hover{background:#fef3c7}
.abf-act.unblock{border-color:rgba(99,102,241,.3);color:#4f46e5}
.abf-act.unblock:hover{background:#ede9fe}
.abf-act.danger{border-color:rgba(220,38,38,.25);color:#dc2626}
.abf-act.danger:hover{background:#fee2e2}
.abf-section-label{font-family:'Nunito',sans-serif;font-size:.7rem;font-weight:700;text-transform:uppercase;letter-spacing:.9px;color:var(--text-muted);margin-bottom:1rem;display:flex;align-items:center;gap:.4rem}
.abf-panel-card{background:var(--bg-white);border:1px solid var(--border);border-radius:var(--radius);overflow:hidden;box-shadow:var(--shadow-sm);margin-bottom:1rem}
.abf-panel-title{display:flex;align-items:center;gap:.5rem;padding:.85rem 1.25rem;font-family:'Nunito',sans-serif;font-size:.82rem;font-weight:700;color:var(--text-mid);border-bottom:1px solid var(--border);background:var(--bg-off)}
.abf-b-restricted{background:#fee2e2;color:#b91c1c;border:1px solid #fecaca;font-size:.62rem;padding:.15rem .55rem;border-radius:10px}
</style>

<div class="abf-header">
  <div>
    <div class="abf-title"><i class="bi bi-receipt"></i> Bills &amp; Invoices</div>
    <div class="abf-sub">Full invoice history · payment status · agent withdrawals · rejection audit</div>
  </div>
  <div class="abf-header-actions">
    <a href="BillsPage?export=csv" class="abf-btn abf-btn-outline"><i class="bi bi-download"></i> Export CSV</a>
  </div>
</div>

<%-- ── Stat cards ── --%>
<div class="abf-stats">
  <div class="abf-stat">
    <div class="abf-stat-icon blue"><i class="bi bi-receipt"></i></div>
    <div>
      <div class="abf-stat-num"><%= _totalBills %></div>
      <div class="abf-stat-lbl">Total Bills</div>
    </div>
  </div>
  <div class="abf-stat">
    <div class="abf-stat-icon green"><i class="bi bi-credit-card-fill"></i></div>
    <div>
      <div class="abf-stat-num"><%= _paidCount %></div>
      <div class="abf-stat-lbl">Paid</div>
    </div>
  </div>
  <div class="abf-stat">
    <div class="abf-stat-icon red"><i class="bi bi-arrow-counterclockwise"></i></div>
    <div>
      <div class="abf-stat-num"><%= _refundCount %></div>
      <div class="abf-stat-lbl">Refunded</div>
    </div>
  </div>
  <div class="abf-stat">
    <div class="abf-stat-icon amber"><i class="bi bi-cash-coin"></i></div>
    <div>
      <div class="abf-stat-num"><%= _codCount %></div>
      <div class="abf-stat-lbl">Pending COD</div>
    </div>
  </div>
  <div class="abf-stat">
    <div class="abf-stat-icon purple"><i class="bi bi-currency-rupee"></i></div>
    <div>
      <div class="abf-stat-num">₹<%= String.format("%,.0f", _totalRevenue) %></div>
      <div class="abf-stat-lbl">Revenue</div>
    </div>
  </div>
</div>

<%-- ── Tab bar ── --%>
<div class="abf-tabs">
  <button class="abf-tab active" onclick="abfTab('bills',this)">
    <i class="bi bi-file-earmark-text"></i> Bills &amp; Audit
  </button>
  <button class="abf-tab" onclick="abfTab('agent-cancel',this)">
    <i class="bi bi-x-circle"></i> Agent Cancels
  </button>
  <button class="abf-tab" onclick="abfTab('reject-task',this)">
    <i class="bi bi-slash-circle"></i> Reject Tasks
  </button>
  <button class="abf-tab" onclick="abfTab('withdrawals',this)">
    <i class="bi bi-cash-stack"></i> Withdrawals
  </button>
</div>

<%-- ══════════════════════════════
     TAB 1 — BILLS & AUDIT
══════════════════════════════ --%>
<div class="abf-panel active" id="abf-panel-bills">
  <div class="abf-toolbar">
    <div class="abf-search">
      <i class="bi bi-search"></i>
      <input type="text" id="abfBillSearch" placeholder="Search order, customer, transaction…" oninput="abfBillFilter()">
    </div>
    <select class="abf-filter" id="abfStatusFilter" onchange="abfBillFilter()">
      <option value="">All Statuses</option>
      <option value="PENDING">Pending</option>
      <option value="PACKED">Packed</option>
      <option value="SHIPPED">Shipped</option>
      <option value="OUT_FOR_DELIVERY">Out for Delivery</option>
      <option value="DELIVERED">Delivered</option>
      <option value="CANCELLED">Cancelled</option>
    </select>
    <select class="abf-filter" id="abfPayFilter" onchange="abfBillFilter()">
      <option value="">All Payments</option>
      <option value="PAID">Paid</option>
      <option value="PENDING_COD">Pending COD</option>
      <option value="REFUNDED">Refunded</option>
    </select>
    <div class="abf-toolbar-right">
      <span class="abf-count-chip" id="abfBillCount">— records</span>
    </div>
  </div>

  <div class="abf-table-card">
    <div class="abf-table-head">
      <span class="abf-table-title"><i class="bi bi-list-columns-reverse"></i> Audit Details</span>
      <span class="abf-table-meta">Generated: <%= _genDate %></span>
    </div>
    <div class="abf-table-scroll">
      <table class="abf-table" id="abfBillsTable">
        <thead>
          <tr>
            <th>Order #</th>
            <th>Customer</th>
            <th>Order Status</th>
            <th>Amount</th>
            <th>Method</th>
            <th>Payment Status</th>
            <th>Transaction ID</th>
            <th>Delivery Date</th>
            <th>Audit Notes</th>
          </tr>
        </thead>
        <tbody id="abfBillsTbody">
          <c:forEach var="order" items="${orders}">
            <tr data-search="${order.id} ${order.customerName} ${order.customerEmail} ${order.transactionId}"
                data-status="${order.status}" data-paystatus="${order.paymentStatus}">
              <td><span class="abf-order-id">#${order.id}</span></td>
              <td>
                <div class="abf-cust-name">${order.customerName}</div>
                <div class="abf-cust-email">${order.customerEmail}</div>
              </td>
              <td>
                <c:choose>
                  <c:when test="${order.status eq 'PENDING'}">    <span class="abf-badge abf-b-pending"><i class="bi bi-hourglass-split"></i>Pending</span></c:when>
                  <c:when test="${order.status eq 'PACKED'}">     <span class="abf-badge abf-b-packed"><i class="bi bi-box-seam"></i>Packed</span></c:when>
                  <c:when test="${order.status eq 'SHIPPED'}">    <span class="abf-badge abf-b-shipped"><i class="bi bi-truck"></i>Shipped</span></c:when>
                  <c:when test="${order.status eq 'OUT_FOR_DELIVERY'}"><span class="abf-badge abf-b-ofd"><i class="bi bi-bicycle"></i>Out for Delivery</span></c:when>
                  <c:when test="${order.status eq 'DELIVERED'}">  <span class="abf-badge abf-b-delivered"><i class="bi bi-check-circle-fill"></i>Delivered</span></c:when>
                  <c:when test="${order.status eq 'CANCELLED'}">  <span class="abf-badge abf-b-cancelled"><i class="bi bi-x-circle-fill"></i>Cancelled</span></c:when>
                  <c:otherwise><span class="abf-badge">${order.status}</span></c:otherwise>
                </c:choose>
              </td>
              <td class="abf-amount">₹${order.totalAmount}</td>
              <td>
                <c:choose>
                  <c:when test="${order.paymentMethod eq 'COD'}">      <span class="abf-pay-pill abf-pp-cod"><i class="bi bi-cash-coin"></i>COD</span></c:when>
                  <c:when test="${order.paymentMethod eq 'Razorpay'}"> <span class="abf-pay-pill abf-pp-card"><i class="bi bi-credit-card-2-back"></i>Razorpay</span></c:when>
                  <c:when test="${order.paymentMethod eq 'UPI'}">      <span class="abf-pay-pill abf-pp-upi"><i class="bi bi-phone"></i>UPI</span></c:when>
                  <c:otherwise><span class="abf-pay-pill abf-pp-unknown">${order.paymentMethod}</span></c:otherwise>
                </c:choose>
              </td>
              <td>
                <c:choose>
                  <c:when test="${order.paymentStatus eq 'PAID'}">       <span class="abf-badge abf-b-paid"><i class="bi bi-check-circle-fill"></i>Paid</span></c:when>
                  <c:when test="${order.paymentStatus eq 'REFUNDED'}">   <span class="abf-badge abf-b-refunded"><i class="bi bi-arrow-counterclockwise"></i>Refunded</span></c:when>
                  <c:when test="${order.paymentStatus eq 'PENDING_COD'}"><span class="abf-badge abf-b-cod"><i class="bi bi-clock"></i>Pending COD</span></c:when>
                  <c:otherwise><span class="abf-badge">${order.paymentStatus}</span></c:otherwise>
                </c:choose>
              </td>
              <td><c:choose><c:when test="${not empty order.transactionId}"><span class="abf-txn">${order.transactionId}</span></c:when><c:otherwise><span style="color:var(--text-muted);font-size:.78rem">—</span></c:otherwise></c:choose></td>
              <td class="abf-date">${order.deliveryDate}</td>
              <td style="font-size:.78rem;color:var(--text-muted);max-width:180px">
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
            <tr><td colspan="9"><div class="abf-empty"><i class="bi bi-inbox"></i><p>No bills found.</p></div></td></tr>
          </c:if>
        </tbody>
      </table>
    </div>
    <div class="abf-no-results" id="abfBillNoResults"><i class="bi bi-search"></i><p>No records match your search / filter.</p></div>
  </div>
</div><%-- /panel-bills --%>

<%-- ══════════════════════════════
     TAB 2 — AGENT CANCELLATIONS
══════════════════════════════ --%>
<div class="abf-panel" id="abf-panel-agent-cancel">
  <div class="abf-section-label"><i class="bi bi-x-circle" style="color:var(--danger,#ef4444)"></i> Agent-Cancelled Orders</div>
  <div class="abf-toolbar">
    <div class="abf-search">
      <i class="bi bi-search"></i>
      <input type="text" id="abfCancelSearch" placeholder="Search order or agent…" oninput="abfCancelFilter()">
    </div>
    <div class="abf-toolbar-right"><span class="abf-count-chip" id="abfCancelCount">— records</span></div>
  </div>
  <div class="abf-table-card">
    <div class="abf-table-head">
      <span class="abf-table-title"><i class="bi bi-x-circle-fill" style="color:#fca5a5"></i> Cancelled by Agent</span>
      <span class="abf-table-meta">Orders where agent triggered cancellation</span>
    </div>
    <div class="abf-table-scroll">
      <table class="abf-table" id="abfCancelTable">
        <thead>
          <tr><th>Order #</th><th>Customer</th><th>Agent</th><th>Amount</th><th>Cancelled At</th><th>Reason</th><th>Payment Status</th></tr>
        </thead>
        <tbody id="abfCancelTbody">
          <c:forEach var="order" items="${orders}">
            <c:if test="${order.status eq 'CANCELLED' and not empty order.deliveryUserId}">
              <tr data-search="${order.id} ${order.customerName} ${order.deliveryUserName}">
                <td><span class="abf-order-id">#${order.id}</span></td>
                <td><div class="abf-cust-name">${order.customerName}</div><div class="abf-cust-email">${order.customerEmail}</div></td>
                <td>${order.deliveryUserName}</td>
                <td class="abf-amount">₹${order.totalAmount}</td>
                <td class="abf-date">${order.date}</td>
                <td style="font-size:.8rem;color:var(--text-muted)">—</td>
                <td>
                  <c:choose>
                    <c:when test="${order.paymentStatus eq 'REFUNDED'}"><span class="abf-badge abf-b-refunded"><i class="bi bi-arrow-counterclockwise"></i>Refunded</span></c:when>
                    <c:otherwise><span class="abf-badge abf-b-pending">${order.paymentStatus}</span></c:otherwise>
                  </c:choose>
                </td>
              </tr>
            </c:if>
          </c:forEach>
          <c:if test="${empty orders}">
            <tr><td colspan="7"><div class="abf-empty"><i class="bi bi-check-circle"></i><p>No agent cancellations found.</p></div></td></tr>
          </c:if>
        </tbody>
      </table>
    </div>
    <div class="abf-no-results" id="abfCancelNoResults"><i class="bi bi-search"></i><p>No records match your search.</p></div>
  </div>
</div>

<%-- ══════════════════════════════
     TAB 3 — REJECT TASKS
══════════════════════════════ --%>
<div class="abf-panel" id="abf-panel-reject-task">
  <div class="abf-section-label"><i class="bi bi-slash-circle" style="color:var(--danger,#ef4444)"></i> Agent Task Rejections</div>
  <% if (_rejectionSummary.isEmpty()) { %>
  <div class="abf-table-card">
    <div class="abf-empty"><i class="bi bi-shield-check"></i><p>No task rejections on record. All agents are performing well!</p></div>
  </div>
  <% } else { %>
  <div class="abf-panel-card">
    <div class="abf-panel-title">
      <i class="bi bi-slash-circle"></i> Agents with Rejections
      <span style="margin-left:auto;background:#fee2e2;color:#b91c1c;border:1px solid rgba(220,38,38,.3);font-size:.65rem;font-weight:700;padding:2px 9px;border-radius:20px">
        <%= _rejectionSummary.size() %> agent<%= _rejectionSummary.size()!=1?"s":"" %>
      </span>
    </div>
    <% for (java.util.Map<String,Object> rs : _rejectionSummary) {
         int    rAgentId    = ((Number) rs.get("agentId")).intValue();
         int    rCount      = ((Number) rs.get("rejectionCount")).intValue();
         String rName       = String.valueOf(rs.get("agentName"));
         String rStatus     = String.valueOf(rs.get("agentStatus"));
         boolean isRestricted = "restricted".equalsIgnoreCase(rStatus);
         String rcCss = rCount >= 3 ? "abf-rc-3" : rCount == 2 ? "abf-rc-2" : "abf-rc-1";
    %>
    <div class="abf-agent-row">
      <div class="abf-av abf-av-red"><%= rName.length()>0 ? String.valueOf(rName.charAt(0)).toUpperCase() : "A" %></div>
      <div style="flex:1;min-width:0">
        <div class="abf-agent-name">
          <%= rName %>
          <% if (isRestricted) { %><span class="abf-badge abf-b-restricted" style="font-size:.6rem"><i class="bi bi-lock-fill"></i> Restricted</span><% } %>
        </div>
        <div class="abf-agent-meta">Total rejections: <strong style="color:#ef4444"><%= rCount %></strong></div>
        <div class="abf-act-btns">
          <button class="abf-act" onclick="abfViewRejLog(<%= rAgentId %>,'<%= rName.replace("'","&#39;") %>')"><i class="bi bi-eye"></i> View Log</button>
          <button class="abf-act approve" onclick="abfReviewRejection(<%= rAgentId %>,'<%= rName.replace("'","&#39;") %>','accept')"><i class="bi bi-check-circle"></i> Accept</button>
          <button class="abf-act dismiss" onclick="abfReviewRejection(<%= rAgentId %>,'<%= rName.replace("'","&#39;") %>','dismiss')"><i class="bi bi-exclamation-triangle"></i> Dismiss</button>
          <% if (isRestricted) { %>
          <button class="abf-act unblock" onclick="abfUnblockAgent(<%= rAgentId %>,'<%= rName.replace("'","&#39;") %>')"><i class="bi bi-unlock"></i> Unblock</button>
          <% } %>
        </div>
      </div>
      <div class="abf-rej-badge <%= rcCss %>"><%= rCount %></div>
    </div>
    <% } %>
  </div>
  <% } %>

  <%-- Rejection log modal (shared) --%>
  <div id="abfRejLogModal" style="display:none;position:fixed;inset:0;background:rgba(0,0,0,.45);z-index:2000;align-items:center;justify-content:center;padding:1rem">
    <div style="background:#fff;border-radius:var(--radius);max-width:540px;width:100%;max-height:80vh;overflow:auto;box-shadow:0 12px 48px rgba(0,0,0,.18)">
      <div style="display:flex;align-items:center;justify-content:space-between;padding:1rem 1.25rem;border-bottom:1px solid var(--border)">
        <span style="font-weight:700;font-size:.95rem;color:var(--text-dark)" id="abfRejLogTitle">Rejection Log</span>
        <button onclick="document.getElementById('abfRejLogModal').style.display='none'" style="background:none;border:none;font-size:1.3rem;cursor:pointer;color:var(--text-muted)">&times;</button>
      </div>
      <div id="abfRejLogContent" style="padding:1.25rem;font-size:.85rem;color:var(--text-mid)">Loading…</div>
    </div>
  </div>
</div>

<%-- ══════════════════════════════
     TAB 4 — WITHDRAWALS
══════════════════════════════ --%>
<div class="abf-panel" id="abf-panel-withdrawals">
  <div class="abf-section-label"><i class="bi bi-cash-stack" style="color:#b45309"></i> Pending Withdrawal Requests</div>
  <% if (_pendingWithdrawals.isEmpty()) { %>
  <div class="abf-table-card">
    <div class="abf-empty"><i class="bi bi-wallet2"></i><p>No pending withdrawal requests at this time.</p></div>
  </div>
  <% } else { %>
  <div class="abf-panel-card">
    <div class="abf-panel-title">
      <i class="bi bi-cash-stack"></i> Withdrawal Requests
      <span style="margin-left:auto;background:#fef3c7;color:#92400e;border:1px solid rgba(245,158,11,.3);font-size:.65rem;font-weight:700;padding:2px 9px;border-radius:20px">
        <%= _pendingWithdrawals.size() %> pending
      </span>
    </div>
    <% for (java.util.Map<String,Object> wd : _pendingWithdrawals) {
         int wdId       = (int) wd.get("id");
         String wdAgent = String.valueOf(wd.get("agentName"));
         double wdAmt   = (double) wd.get("amount");
         String wdReason= wd.get("reason") != null ? String.valueOf(wd.get("reason")) : "";
         java.sql.Timestamp wdAt = (java.sql.Timestamp) wd.get("requestedAt");
    %>
    <div class="abf-agent-row">
      <div class="abf-av abf-av-amber"><%= wdAgent.length()>0 ? String.valueOf(wdAgent.charAt(0)).toUpperCase() : "A" %></div>
      <div style="flex:1;min-width:0">
        <div class="abf-agent-name"><%= wdAgent %></div>
        <div class="abf-wd-amount">₹<%= String.format("%.2f", wdAmt) %></div>
        <% if (!wdReason.isEmpty()) { %>
        <div class="abf-agent-meta"><i class="bi bi-chat-left-quote"></i> <%= wdReason.length()>80 ? wdReason.substring(0,80)+"…" : wdReason %></div>
        <% } %>
        <% if (wdAt != null) { %>
        <div class="abf-agent-meta" style="margin-top:.25rem"><i class="bi bi-clock"></i> <%= new java.text.SimpleDateFormat("dd MMM yyyy, hh:mm a").format(wdAt) %></div>
        <% } %>
        <div class="abf-act-btns">
          <button class="abf-act approve" onclick="abfApproveWd(<%= wdId %>,'<%= wdAgent.replace("'","&#39;") %>')"><i class="bi bi-check-circle"></i> Approve</button>
          <button class="abf-act danger"  onclick="abfRejectWd(<%= wdId %>,'<%= wdAgent.replace("'","&#39;") %>')"><i class="bi bi-x-circle"></i> Reject</button>
        </div>
      </div>
    </div>
    <% } %>
  </div>
  <% } %>
</div>

<script>
/* ── Tab switching ── */
function abfTab(name, btn){
  document.querySelectorAll('.abf-panel').forEach(function(p){ p.classList.remove('active'); });
  document.querySelectorAll('.abf-tab').forEach(function(b){ b.classList.remove('active'); });
  var panel = document.getElementById('abf-panel-'+name);
  if(panel) panel.classList.add('active');
  btn.classList.add('active');
  /* init counts on first switch */
  if(name==='bills')        abfInitBillCount();
  if(name==='agent-cancel') abfInitCancelCount();
}

/* ── Bills filter ── */
function abfBillFilter(){
  var q   = document.getElementById('abfBillSearch').value.toLowerCase();
  var st  = document.getElementById('abfStatusFilter').value.toUpperCase();
  var pay = document.getElementById('abfPayFilter').value.toUpperCase();
  var rows = document.querySelectorAll('#abfBillsTbody tr[data-search]');
  var vis=0;
  rows.forEach(function(tr){
    var ok = (!q  || tr.dataset.search.toLowerCase().includes(q))
          && (!st  || tr.dataset.status.toUpperCase() === st)
          && (!pay || tr.dataset.paystatus.toUpperCase() === pay);
    tr.style.display = ok ? '' : 'none';
    if(ok) vis++;
  });
  document.getElementById('abfBillCount').textContent = vis+' record'+(vis!==1?'s':'');
  document.getElementById('abfBillNoResults').style.display = (vis===0 && rows.length>0) ? 'block' : 'none';
}
function abfInitBillCount(){
  var rows = document.querySelectorAll('#abfBillsTbody tr[data-search]');
  document.getElementById('abfBillCount').textContent = rows.length+' record'+(rows.length!==1?'s':'');
}

/* ── Cancel filter ── */
function abfCancelFilter(){
  var q = document.getElementById('abfCancelSearch').value.toLowerCase();
  var rows = document.querySelectorAll('#abfCancelTbody tr[data-search]');
  var vis=0;
  rows.forEach(function(tr){
    var ok = !q || tr.dataset.search.toLowerCase().includes(q);
    tr.style.display = ok ? '' : 'none';
    if(ok) vis++;
  });
  document.getElementById('abfCancelCount').textContent = vis+' record'+(vis!==1?'s':'');
  document.getElementById('abfCancelNoResults').style.display = (vis===0 && rows.length>0) ? 'block' : 'none';
}
function abfInitCancelCount(){
  var rows = document.querySelectorAll('#abfCancelTbody tr[data-search]');
  document.getElementById('abfCancelCount').textContent = rows.length+' record'+(rows.length!==1?'s':'');
}

/* ── Rejection log modal ── */
function abfViewRejLog(agentId, agentName){
  var modal = document.getElementById('abfRejLogModal');
  document.getElementById('abfRejLogTitle').textContent = 'Rejection Log — '+agentName;
  document.getElementById('abfRejLogContent').textContent = 'Loading…';
  modal.style.display = 'flex';
  fetch('AgentRejectionLog?agentId='+agentId)
    .then(function(r){ return r.text(); })
    .then(function(html){ document.getElementById('abfRejLogContent').innerHTML = html || '<em>No log entries found.</em>'; })
    .catch(function(){ document.getElementById('abfRejLogContent').textContent = 'Could not load log.'; });
}
function abfReviewRejection(agentId, agentName, decision){
  var note = prompt((decision==='accept'?'Accept':'Dismiss')+' rejection reason for '+agentName+'?\nEnter a staff note (optional):');
  if(note===null) return;
  var params = new URLSearchParams({action:'reviewAgentRejection',agentUserId:agentId,decision:decision,staffNote:note||''});
  fetch('AgentRejectionAction',{method:'POST',body:params,headers:{'Content-Type':'application/x-www-form-urlencoded'}})
    .then(function(r){ return r.json(); })
    .then(function(d){ if(d.success) location.reload(); else alert('Action failed: '+(d.message||'Unknown error')); })
    .catch(function(){ alert('Network error — please try again.'); });
}
function abfUnblockAgent(agentId, agentName){
  if(!confirm('Unblock '+agentName+'?')) return;
  var params = new URLSearchParams({action:'unblockAgent',agentUserId:agentId});
  fetch('AgentRejectionAction',{method:'POST',body:params,headers:{'Content-Type':'application/x-www-form-urlencoded'}})
    .then(function(r){ return r.json(); })
    .then(function(d){ if(d.success) location.reload(); else alert('Unblock failed.'); })
    .catch(function(){ alert('Network error — please try again.'); });
}

/* ── Withdrawal actions ── */
function abfApproveWd(wdId, agentName){
  if(!confirm('Approve withdrawal for '+agentName+'?')) return;
  var params = new URLSearchParams({action:'approveWithdrawal',withdrawalId:wdId});
  fetch('AgentWalletAction',{method:'POST',body:params,headers:{'Content-Type':'application/x-www-form-urlencoded'}})
    .then(function(r){ return r.json(); })
    .then(function(d){ if(d.success) location.reload(); else alert('Approval failed: '+(d.message||'')); })
    .catch(function(){ alert('Network error — please try again.'); });
}
function abfRejectWd(wdId, agentName){
  var reason = prompt('Reject withdrawal for '+agentName+'?\nEnter rejection reason:');
  if(reason===null) return;
  var params = new URLSearchParams({action:'rejectWithdrawal',withdrawalId:wdId,reason:reason});
  fetch('AgentWalletAction',{method:'POST',body:params,headers:{'Content-Type':'application/x-www-form-urlencoded'}})
    .then(function(r){ return r.json(); })
    .then(function(d){ if(d.success) location.reload(); else alert('Rejection failed: '+(d.message||'')); })
    .catch(function(){ alert('Network error — please try again.'); });
}

/* ── Init bill count on load ── */
(function(){ abfInitBillCount(); })();
</script>
