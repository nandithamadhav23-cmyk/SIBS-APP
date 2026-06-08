<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List, java.util.UUID" %>
<%@ page import="com.util.*" %>
<%
    List<CartItem>        cartItems    = (List<CartItem>)        request.getAttribute("cartItems");
    Customer              customer     = (Customer)               request.getAttribute("customer");
    List<CustomerAddress> addresses    = (List<CustomerAddress>) request.getAttribute("addresses");
    CustomerAddress       defaultAddr  = (CustomerAddress)       request.getAttribute("defaultAddress");

    if (cartItems == null || customer == null) {
        response.sendRedirect("CartServlet?action=view");
        return;
    }

    /* ── SHARED FORMULA (mirrors PlaceOrderServlet exactly) ──────────────────
       This is the critical fix — Checkout.jsp previously computed a different
       total than PlaceOrderServlet (missing deliveryCharge + codCharge).
       Now we show the exact same breakdown the server will bill.
    ─────────────────────────────────────────────────────────────────────────*/
    double subtotal       = cartItems.stream().mapToDouble(i -> i.getFinalPrice() * i.getQuantity()).sum();
    // GST FIX: compute per-item GST using each product's own gst_rate
    // Old code: gst = subtotal * 0.18 + separate tax = subtotal * 0.05 (wrong — 23% flat on everything)
    // New code: sum of (finalPrice × qty × gstRate%) per item — correct Indian GST calculation
    double gst            = cartItems.stream().mapToDouble(i -> i.getFinalPrice() * i.getQuantity() * (i.getGstRate() / 100.0)).sum();
    // GST FIX: removed "double tax = subtotal * 0.05" — GST IS the tax in India; there is no additional tax
    double deliveryCharge = subtotal > 700 ? 0 : 40;   // same threshold as PlaceOrderServlet
    double codCharge      = 0;                          // added dynamically via JS when COD selected
    double grandTotalBase = subtotal + gst + deliveryCharge; // GST FIX: no phantom tax

    java.time.LocalDate deliveryDateCOD = java.time.LocalDate.now().plusDays(5);
    java.time.LocalDate deliveryDatePre = java.time.LocalDate.now().plusDays(3);
    java.time.format.DateTimeFormatter dtf = java.time.format.DateTimeFormatter.ofPattern("dd MMM yyyy");

    /* Token is generated in CheckoutServlet and stored in session.
       We read it back from the request attribute set by CheckoutServlet. */
    String formToken = (String) request.getAttribute("formToken");
    if (formToken == null) {
        // Fallback: generate here if accessed directly (not via CheckoutServlet)
        formToken = UUID.randomUUID().toString();
        session.setAttribute("checkoutToken", formToken);
    }

    String custInitial = (customer.getName() != null && !customer.getName().isEmpty())
        ? String.valueOf(customer.getName().charAt(0)).toUpperCase() : "C";

    // Address to show initially — default or first
    String addrLine1 = "", addrLine2 = "";
    if (defaultAddr != null) {
        addrLine1 = defaultAddr.getLandmarkStreet() != null ? defaultAddr.getLandmarkStreet() : "";
        addrLine2 = (defaultAddr.getCity() != null ? defaultAddr.getCity() : "")
                  + (defaultAddr.getState() != null ? ", " + defaultAddr.getState() : "")
                  + (defaultAddr.getPincode() != null ? " — " + defaultAddr.getPincode() : "");
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Checkout — SIBS STORE</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
<link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@600;700&family=DM+Sans:wght@300;400;500;600&display=swap" rel="stylesheet">
<script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
<style>
:root {
  --primary:#0f3460; --accent:#e94560; --gold:#f5a623;
  --success:#10b981; --danger:#ef4444; --bg:#f4f6fb;
  --white:#ffffff; --text:#1a1a2e; --muted:#6b7280;
  --border:#e5e7eb; --nav-h:68px; --radius:14px;
  --shadow:0 2px 20px rgba(15,52,96,0.08);
}
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
body{font-family:'DM Sans',sans-serif;background:var(--bg);color:var(--text);
     padding-top:var(--nav-h);min-height:100vh}

/* NAV */
.top-nav{position:fixed;top:0;left:0;right:0;z-index:1000;height:var(--nav-h);
  background:var(--primary);display:flex;align-items:center;justify-content:space-between;
  padding:0 1.5rem;box-shadow:0 2px 20px rgba(0,0,0,0.2)}
.nav-brand{font-family:'Playfair Display',serif;font-size:1.4rem;font-weight:700;
  color:#fff;text-decoration:none;display:flex;align-items:center;gap:.5rem}
.nav-brand .brand-dot{color:var(--accent)}
.nav-right{display:flex;align-items:center;gap:.75rem}
.nav-text-btn{background:rgba(255,255,255,.1);border:1px solid rgba(255,255,255,.2);
  border-radius:10px;color:#fff;padding:.4rem .9rem;font-size:.84rem;font-weight:500;
  text-decoration:none;transition:all .2s}
.nav-text-btn:hover{background:rgba(255,255,255,.2);color:#fff}
.nav-user-chip{display:flex;align-items:center;gap:.5rem;background:rgba(255,255,255,.1);
  border:1px solid rgba(255,255,255,.2);border-radius:30px;
  padding:.3rem .9rem .3rem .3rem;color:#fff;font-size:.84rem}
.nav-avatar{width:30px;height:30px;border-radius:50%;background:var(--accent);
  display:flex;align-items:center;justify-content:center;font-weight:700;font-size:.8rem;color:#fff}

/* STEPS */
.steps-bar{background:var(--white);border-bottom:1px solid var(--border);
  padding:1rem 1.5rem;display:flex;align-items:center;justify-content:center}
.step{display:flex;align-items:center;gap:.5rem;font-size:.82rem;font-weight:500;color:var(--muted)}
.step-num{width:28px;height:28px;border-radius:50%;background:var(--border);color:var(--muted);
  display:flex;align-items:center;justify-content:center;font-size:.78rem;font-weight:700;flex-shrink:0}
.step.done .step-num{background:var(--success);color:#fff}
.step.active .step-num{background:var(--primary);color:#fff}
.step.active{color:var(--primary);font-weight:700}
.step-line{width:60px;height:2px;background:var(--border);margin:0 .5rem;flex-shrink:0}
.step-line.done{background:var(--success)}

/* LAYOUT */
.page-wrap{max-width:1150px;margin:0 auto;padding:1.75rem 1.5rem 3rem}
.checkout-layout{display:grid;grid-template-columns:1fr 360px;gap:1.5rem;align-items:start}
@media(max-width:900px){.checkout-layout{grid-template-columns:1fr}}

/* SECTION CARD */
.section-card{background:var(--white);border:1px solid var(--border);width: 800px;
  border-radius:var(--radius);box-shadow:var(--shadow);overflow:hidden;margin-bottom:1.1rem}
.section-header{background:var(--primary);padding:.85rem 1.25rem;
  display:flex;align-items:center;gap:.5rem}
.section-title{font-family:'Playfair Display',serif;font-size:.95rem;font-weight:700;color:#fff}
.section-body{padding:1.25rem}

/* CUSTOMER CHIP */
.customer-chip{display:flex;align-items:center;gap:.85rem;
  background:var(--bg);border-radius:12px;padding:.85rem 1rem}
.customer-big-avatar{width:52px;height:52px;border-radius:50%;background:var(--accent);
  display:flex;align-items:center;justify-content:center;
  font-size:1.3rem;font-weight:700;color:#fff;flex-shrink:0}
.customer-name{font-weight:700;font-size:1rem;color:var(--primary)}
.customer-sub{font-size:.8rem;color:var(--muted)}

/* ADDRESS BLOCK */
.addr-current{background:var(--bg);border:1.5px solid var(--border);border-radius:12px;
  padding:12px 14px;margin-bottom:12px;display:flex;align-items:flex-start;gap:10px}
.addr-current.has-addr{border-color:rgba(16,185,129,.35);background:#f0fdf4}
.addr-ico{font-size:22px;line-height:1;flex-shrink:0;margin-top:1px}
.addr-info .addr-street{font-weight:700;font-size:13.5px;color:#1e293b}
.addr-info .addr-line2{font-size:12px;color:#64748b;margin-top:2px}
.addr-changed-note{background:#fffbeb;border:1px solid #fde68a;border-radius:8px;
  padding:6px 10px;font-size:11.5px;color:#92400e;margin-top:6px;
  display:none;align-items:center;gap:5px}
.addr-changed-note.show{display:flex}
.addr-no-address{background:#fff5f5;border:1.5px solid #fecaca;border-radius:12px;
  padding:12px 14px;color:#dc2626;font-size:13px;font-weight:600;
  display:flex;align-items:center;gap:8px;margin-bottom:12px}

/* ITEMS TABLE */
.items-table{width:100%;border-collapse:collapse;font-size:.84rem}
.items-table thead th{background:var(--primary);color:rgba(255,255,255,.85);
  padding:.7rem .8rem;font-size:.72rem;text-transform:uppercase;
  letter-spacing:.06em;font-weight:600;text-align:left}
.items-table tbody td{padding:.75rem .8rem;border-bottom:1px solid var(--border);vertical-align:middle}
.items-table tbody tr:last-child td{border-bottom:none}
.items-table tbody tr:hover td{background:#fafbff}
.item-thumb{width:52px;height:52px;border-radius:8px;object-fit:contain;
  background:var(--bg);border:1px solid var(--border);padding:3px}
.disc-pill{background:rgba(233,69,96,.1);color:var(--accent);border:1px solid rgba(233,69,96,.2);
  border-radius:6px;padding:2px 7px;font-size:.72rem;font-weight:700}
.stock-ok{background:rgba(16,185,129,.1);color:var(--success);border:1px solid rgba(16,185,129,.2);
  border-radius:6px;padding:2px 7px;font-size:.72rem;font-weight:600}
.stock-low{background:rgba(239,68,68,.1);color:var(--danger);border:1px solid rgba(239,68,68,.2);
  border-radius:6px;padding:2px 7px;font-size:.72rem;font-weight:600}

/* PAYMENT */
.payment-options{display:grid;grid-template-columns:repeat(3,1fr);gap:.75rem}
@media(max-width:560px){.payment-options{grid-template-columns:1fr}}
.pay-option{border:2px solid var(--border);border-radius:12px;padding:.85rem 1rem;
  cursor:pointer;display:flex;align-items:center;gap:.6rem;
  transition:all .18s;position:relative}
.pay-option input{position:absolute;opacity:0;width:0}
.pay-option:hover{border-color:var(--primary);background:rgba(15,52,96,.03)}
.pay-option.selected{border-color:var(--accent);background:rgba(233,69,96,.05)}
.pay-icon{width:38px;height:38px;border-radius:10px;display:flex;
  align-items:center;justify-content:center;font-size:1.15rem;flex-shrink:0}
.pay-label{font-weight:600;font-size:.88rem;color:var(--text)}
.pay-sublabel{font-size:.72rem;color:var(--muted)}

/* SUMMARY CARD */
.summary-card{background:var(--white);border:1px solid var(--border);
  border-radius:var(--radius);box-shadow:var(--shadow);
  overflow:hidden;position:sticky;top:calc(var(--nav-h) + 1rem)}
.summary-head{background:var(--primary);padding:.9rem 1.25rem;
  display:flex;align-items:center;gap:.5rem}
.summary-head-title{font-family:'Playfair Display',serif;font-size:.95rem;font-weight:700;color:#fff}
.summary-body{padding:1.1rem}
.sum-row{display:flex;justify-content:space-between;align-items:center;
  padding:.5rem 0;border-bottom:1px solid var(--border);font-size:.88rem}
.sum-row:last-of-type{border-bottom:none}
.sum-row .sl{color:var(--muted)}.sum-row .sv{font-weight:600}
.sum-total{display:flex;justify-content:space-between;align-items:center;
  padding:.85rem 0 .5rem;border-top:2px solid var(--border);margin-top:.25rem}
.sum-total .sl{font-size:1rem;font-weight:700;color:var(--primary)}
.sum-total .sv{font-size:1.25rem;font-weight:800;color:var(--success)}
.delivery-estimate{background:rgba(15,52,96,.05);border:1px solid rgba(15,52,96,.1);
  border-radius:9px;padding:.6rem .85rem;font-size:.8rem;color:var(--muted);
  display:none;align-items:center;gap:.4rem;margin-top:.75rem}
.delivery-estimate strong{color:var(--primary)}

/* ── BILL PREVIEW (new) ── */
.bill-preview{background:#f8fafc;border:1px solid #e2e8f0;border-radius:10px;
  padding:10px 12px;margin-bottom:10px;font-size:12px}
.bill-preview-row{display:flex;justify-content:space-between;padding:2px 0;color:#64748b}
.bill-preview-row.total{border-top:1px solid #e2e8f0;margin-top:5px;padding-top:5px;
  font-weight:700;color:#0f3460;font-size:13px}
.bill-savings{background:#f0fdf4;border:1px solid #bbf7d0;border-radius:8px;
  padding:6px 10px;font-size:11.5px;color:#16a34a;font-weight:600;
  display:flex;align-items:center;gap:5px;margin-top:6px}

.btn-place{display:flex;align-items:center;justify-content:center;gap:.5rem;
  width:100%;padding:.8rem;background:var(--accent);color:#fff;border:none;
  border-radius:12px;font-family:'DM Sans',sans-serif;
  font-size:.95rem;font-weight:700;cursor:pointer;transition:all .2s;margin-top:1rem}
.btn-place:hover:not(:disabled){background:#d63a52;transform:translateY(-1px);
  box-shadow:0 4px 14px rgba(233,69,96,.35)}
.btn-place:disabled{background:var(--muted);cursor:not-allowed}
.btn-cancel-link{display:flex;align-items:center;justify-content:center;gap:.4rem;
  width:100%;padding:.6rem;margin-top:.5rem;background:transparent;
  color:var(--muted);border:1.5px solid var(--border);border-radius:12px;
  text-decoration:none;font-size:.85rem;font-weight:500;transition:all .18s}
.btn-cancel-link:hover{background:var(--bg);color:var(--text)}
.secure-note{display:flex;align-items:center;justify-content:center;
  gap:.3rem;font-size:.72rem;color:var(--muted);margin-top:.85rem}

/* TOAST */
.toast-wrap{position:fixed;bottom:1.5rem;right:1.5rem;z-index:9999}
.toast-item{background:var(--primary);color:#fff;padding:.8rem 1.1rem;
  border-radius:12px;display:flex;align-items:center;gap:.6rem;
  font-size:.88rem;font-weight:500;box-shadow:0 4px 20px rgba(0,0,0,.2);
  animation:toastIn .3s ease;margin-top:.5rem}
@keyframes toastIn{from{opacity:0;transform:translateY(12px)}to{opacity:1;transform:none}}

/* ADDRESS MODAL */
#addressModal .modal-content{border-radius:16px;border:none;
  box-shadow:0 20px 60px rgba(0,0,0,.2);overflow:hidden}
#addressModal .modal-header{background:var(--primary);color:#fff;border:none}
#addressModal .modal-title{font-family:'Playfair Display',serif;font-size:1rem}
#addressModal .btn-close{filter:brightness(0) invert(1)}
#addressModal .modal-footer{border-top:1px solid var(--border)}

footer{background:var(--primary);color:rgba(255,255,255,.5);
  font-size:.8rem;text-align:center;padding:1.1rem;
  margin-top:3rem;border-top:3px solid var(--accent)}
footer span{color:var(--accent)}
@media(max-width:768px){body{padding-bottom:70px;}}
</style>
</head>
<body>

<!-- ══ NAV ══ -->
<nav class="top-nav">
  <a class="nav-brand" href="Customer">
    <i class="bi bi-bag-heart-fill"></i>SIBS<span class="brand-dot">•</span>STORE
  </a>
  <div class="nav-right">
    <a href="Customer" class="nav-text-btn"><i class="bi bi-house"></i> Home</a>
    <div class="nav-user-chip">
      <div class="nav-avatar"><%= custInitial %></div>
      <span><%= customer.getName().split(" ")[0] %></span>
    </div>
    <a href="CustomerLogout" class="nav-text-btn"><i class="bi bi-box-arrow-right"></i> Logout</a>
  </div>
</nav>

<!-- ══ STEPS ══ -->
<div class="steps-bar">
  <div class="step done"><div class="step-num"><i class="bi bi-check"></i></div><span>Cart</span></div>
  <div class="step-line done"></div>
  <div class="step active"><div class="step-num">2</div><span>Checkout</span></div>
  <div class="step-line"></div>
  <div class="step"><div class="step-num">3</div><span>Confirmation</span></div>
</div>

<div class="page-wrap">
<div class="checkout-layout">

<!-- ── LEFT COL ── -->
<div>

  <!-- Customer -->
  <div class="section-card">
    <div class="section-header">
      <i class="bi bi-person-circle" style="color:rgba(255,255,255,.7)"></i>
      <span class="section-title">Customer Details</span>
    </div>
    <div class="section-body">
      <div class="customer-chip">
        <div class="customer-big-avatar"><%= custInitial %></div>
        <div>
          <div class="customer-name"><%= customer.getName() %></div>
          <div class="customer-sub"><i class="bi bi-envelope"></i> <%= customer.getEmail() %></div>
          <div class="customer-sub"><i class="bi bi-telephone"></i> <%= customer.getPhone() %></div>
        </div>
      </div>
    </div>
  </div>

  <!-- Address — enhanced block -->
  <div class="section-card">
    <div class="section-header">
      <i class="bi bi-geo-alt" style="color:rgba(255,255,255,.7)"></i>
      <span class="section-title">Delivery Address</span>
      <span style="margin-left:auto;font-size:.75rem;color:rgba(255,255,255,.6)">
        This address will be saved on your order and won't change automatically
      </span>
    </div>
    <div class="section-body">

      <!-- Current address preview — updated in JS when customer picks a different one -->
      <div id="addrPreview">
        <% if (defaultAddr != null) { %>
        <div class="addr-current has-addr" id="addrCurrent">
          <span class="addr-ico">🏠</span>
          <div class="addr-info">
            <div class="addr-street" id="addrStreet"><%= addrLine1 %></div>
            <div class="addr-line2" id="addrLine2"><%= addrLine2 %></div>
            <div class="addr-changed-note" id="addrChangedNote">
              ✏️ You've selected a different address. This will only apply to this order.
            </div>
          </div>
        </div>
        <% } else { %>
        <div class="addr-no-address" id="addrNoAddress">
          <i class="bi bi-exclamation-triangle-fill"></i>
          No address on file — please add one below before placing your order.
        </div>
        <% } %>
      </div>

      <div id="addressSection">
        <jsp:include page="AddressSnippet.jsp" />
      </div>
    </div>
  </div>

  <!-- Items -->
  <div class="section-card">
    <div class="section-header">
      <i class="bi bi-box-seam" style="color:rgba(255,255,255,.7)"></i>
      <span class="section-title">Items Ordered (<%= cartItems.size() %>)</span>
    </div>
    <div class="section-body" style="padding:0">
      <div style="overflow-x:auto">
        <table class="items-table">
          <thead>
            <tr><th>Image</th><th>Product</th><th>Pack</th>
                <th>Disc.</th><th>Price</th><th>Qty</th><th>Total</th><th>Stock</th></tr>
          </thead>
          <tbody>
            <% for (CartItem item : cartItems) { %>
            <tr>
              <td><img src="<%= item.getImageUrl() %>" class="item-thumb" onerror="this.src='images/default.png'"></td>
              <td style="font-weight:600;min-width:120px"><%= item.getName() %></td>
              <td style="white-space:nowrap;color:var(--muted);font-size:.8rem"><%= item.getProductQuantity() %> <%= item.getUnit() %></td>
              <td><% if(item.getDiscount()>0){%><span class="disc-pill"><%= (int)item.getDiscount() %>%</span><%}else{%>—<%}%></td>
              <td style="font-weight:700">₹<%= String.format("%.2f", item.getFinalPrice()) %></td>
              <td style="text-align:center"><%= item.getQuantity() %></td>
              <td style="font-weight:700;color:var(--primary)">₹<%= String.format("%.2f", item.getFinalPrice() * item.getQuantity()) %></td>
              <td>
                <% if (item.getStock() < 10) { %>
                  <span class="stock-low"><i class="bi bi-exclamation-triangle"></i> Low</span>
                <% } else { %>
                  <span class="stock-ok"><i class="bi bi-check-circle"></i> OK</span>
                <% } %>
              </td>
            </tr>
            <% } %>
          </tbody>
        </table>
      </div>
    </div>
  </div>

  <!-- Payment -->
  <div class="section-card">
    <div class="section-header">
      <i class="bi bi-credit-card" style="color:rgba(255,255,255,.7)"></i>
      <span class="section-title">Payment Method</span>
    </div>
    <div class="section-body">
      <div class="payment-options">
        <label class="pay-option" id="pay-COD">
          <input type="radio" name="paymentChoice" value="COD" onchange="selectPayment('COD')">
          <div class="pay-icon" style="background:rgba(245,158,11,.1);color:var(--gold)"><i class="bi bi-cash-coin"></i></div>
          <div><div class="pay-label">Cash on Delivery</div><div class="pay-sublabel">+₹50 COD charge</div></div>
        </label>
        <label class="pay-option" id="pay-Card">
          <input type="radio" name="paymentChoice" value="Card" onchange="selectPayment('Card')">
          <div class="pay-icon" style="background:rgba(59,130,246,.1);color:#3b82f6"><i class="bi bi-credit-card-2-front"></i></div>
          <div><div class="pay-label">Card</div><div class="pay-sublabel">Credit / Debit</div></div>
        </label>
        <label class="pay-option" id="pay-UPI">
          <input type="radio" name="paymentChoice" value="UPI" onchange="selectPayment('UPI')">
          <div class="pay-icon" style="background:rgba(16,185,129,.1);color:var(--success)"><i class="bi bi-phone"></i></div>
          <div><div class="pay-label">UPI</div><div class="pay-sublabel">GPay, PhonePe…</div></div>
        </label>
      </div>
    </div>
  </div>

</div><!-- /left col -->

<!-- ── RIGHT COL — SUMMARY ── -->
<div>
  <div class="summary-card">
    <div class="summary-head">
      <i class="bi bi-receipt" style="color:rgba(255,255,255,.7)"></i>
      <span class="summary-head-title">Order Summary</span>
    </div>
    <div class="summary-body">

      <!-- Live bill preview — updates as customer picks payment method -->
      <div class="bill-preview">
        <div class="bill-preview-row"><span>Subtotal</span><span>₹<span id="bpSub"><%= String.format("%.2f", subtotal) %></span></span></div>
        <div class="bill-preview-row"><span>GST (18%)</span><span>₹<span id="bpGst"><%= String.format("%.2f", gst) %></span></span></div>
        <!-- GST FIX: Tax (5%) row removed — GST is the only indirect tax -->
        <div class="bill-preview-row">
          <span>Delivery</span>
          <span id="bpDel" style="color:var(--success)"><% if(deliveryCharge==0){%>FREE<%}else{%>₹<%= String.format("%.2f", deliveryCharge) %><%}%></span>
        </div>
        <div class="bill-preview-row" id="bpCodRow" style="display:none">
          <span style="color:#b45309">COD Charge</span>
          <span style="color:#b45309">₹<span id="bpCod">0.00</span></span>
        </div>
        <div class="bill-preview-row total"><span>Grand Total</span><span>₹<span id="bpTotal">—</span></span></div>
      </div>

      <div class="bill-savings" id="billSavings" style="display:none">
        🎉 You save ₹<span id="savingsAmt">0</span> on this order!
      </div>

      <div class="delivery-estimate" id="deliveryEst">
        <i class="bi bi-truck"></i> Expected by <strong id="deliveryDate"></strong>
      </div>

      <!-- Checkout form -->
      <form action="PlaceOrderServlet" method="post" id="checkoutForm">
        <input type="hidden" name="formToken"      value="<%= formToken %>">
        <input type="hidden" name="paymentMethod"  id="paymentMethodHidden" value="">
        <input type="hidden" name="buyNow"         value="<%= request.getAttribute("buyNow")    != null ? request.getAttribute("buyNow")    : "false" %>">
        <input type="hidden" name="productId"      value="<%= request.getAttribute("productId") != null ? request.getAttribute("productId") : "" %>">
        <input type="hidden" name="quantity"       value="<%= request.getAttribute("quantity")  != null ? request.getAttribute("quantity")  : "" %>">

        <button type="submit" id="placeOrderBtn" class="btn-place" disabled>
          <i class="bi bi-bag-check-fill"></i> Place Order
        </button>
      </form>

      <a href="CartServlet?action=view" class="btn-cancel-link">
        <i class="bi bi-arrow-left"></i> Back to Cart
      </a>
      <div class="secure-note"><i class="bi bi-shield-check"></i> 100% Secure & Encrypted</div>
    </div>
  </div>
</div><!-- /right col -->

</div><!-- /checkout-layout -->
</div><!-- /page-wrap -->

<!-- ══ ADDRESS MODAL ══ -->
<div class="modal fade" id="addressModal" tabindex="-1">
  <div class="modal-dialog modal-dialog-centered">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title"><i class="bi bi-geo-alt"></i> Manage Address</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body" id="addressModalContent"></div>
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Back</button>
        <button type="button" id="clearFormBtn" class="btn btn-danger">Clear</button>
      </div>
    </div>
  </div>
</div>

<div class="toast-wrap" id="toastWrap"></div>

<footer>
  <p class="mb-0">&copy; 2026 <span>SIBS Store</span> — Smart Inventory & Billing System</p>
</footer>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
<script>
/* ── Server values — identical constants used by PlaceOrderServlet ────────*/
const _sub  = <%= subtotal %>;
const _gst  = <%= gst %>;
// GST FIX: _tax removed — no separate tax on top of GST
// const _tax  = 0;
const _del  = <%= deliveryCharge %>;   // same formula as PlaceOrderServlet
const _dtCOD = "<%= deliveryDateCOD.format(dtf) %>";
const _dtPre = "<%= deliveryDatePre.format(dtf) %>";
const _hasAddr = <%= defaultAddr != null ? "true" : "false" %>;

/* ── Payment selection — updates bill preview live ─────────────────────── */
function selectPayment(method) {
  document.querySelectorAll('.pay-option').forEach(el => el.classList.remove('selected'));
  document.getElementById('pay-' + method).classList.add('selected');
  document.getElementById('paymentMethodHidden').value = method;

  const cod   = method === 'COD' ? 50 : 0;
  const grand = _sub + _gst + _del + cod; // GST FIX: _tax removed
  const date  = method === 'COD' ? _dtCOD : _dtPre;

  // Update live bill preview
  document.getElementById('bpSub').textContent   = _sub.toFixed(2);
  document.getElementById('bpGst').textContent   = _gst.toFixed(2);
  // GST FIX: bpTax element removed from HTML, no update needed
  // document.getElementById('bpTax').textContent = 0;
  document.getElementById('bpDel').textContent   = _del === 0 ? 'FREE' : '₹' + _del.toFixed(2);
  document.getElementById('bpCod').textContent   = cod.toFixed(2);
  document.getElementById('bpTotal').textContent = grand.toFixed(2);
  document.getElementById('bpCodRow').style.display = method === 'COD' ? 'flex' : 'none';

  // Savings badge (only if delivery is free)
  const savings = _del === 0 ? 40 : 0; // saved vs normal delivery charge
  if (savings > 0) {
    document.getElementById('savingsAmt').textContent = savings.toFixed(2);
    document.getElementById('billSavings').style.display = 'flex';
  }

  // Delivery estimate
  document.getElementById('deliveryDate').textContent = date;
  document.getElementById('deliveryEst').style.display = 'flex';

  // Enable Place Order only if address is set
  document.getElementById('placeOrderBtn').disabled = !_hasAddr;
}

/* ── updateCheckoutAddressPreview — called by AddressSnippet.jsp ──────────
   When customer clicks "Deliver to This Address" in the snippet, we update
   the address preview strip without reloading the page.
─────────────────────────────────────────────────────────────────────────── */
function updateCheckoutAddressPreview(street, city, state, pincode) {
  var el = document.getElementById('addrCurrent');
  if (!el) {
    // Was "no address" — swap to has-addr card
    var noAddr = document.getElementById('addrNoAddress');
    if (noAddr) {
      var newEl = document.createElement('div');
      newEl.className = 'addr-current has-addr';
      newEl.id = 'addrCurrent';
      newEl.innerHTML =
        '<span class="addr-ico">📍</span>' +
        '<div class="addr-info">' +
          '<div class="addr-street" id="addrStreet"></div>' +
          '<div class="addr-line2"  id="addrLine2"></div>' +
          '<div class="addr-changed-note show" id="addrChangedNote">' +
            '✏️ Selected for this order only.' +
          '</div>' +
        '</div>';
      noAddr.replaceWith(newEl);
    }
  }
  var s = document.getElementById('addrStreet');
  var l = document.getElementById('addrLine2');
  var n = document.getElementById('addrChangedNote');
  if (s) s.textContent = street;
  if (l) l.textContent = city + (state ? ', ' + state : '') + (pincode ? ' — ' + pincode : '');
  if (n) n.classList.add('show');

  // Allow placing order now that address is confirmed
  if (document.getElementById('paymentMethodHidden').value !== '') {
    document.getElementById('placeOrderBtn').disabled = false;
  }
  showToast('📍 Delivery address updated for this order!', 'success');
}

/* ── Prevent double-submit ───────────────────────────────────────────────*/
document.getElementById('checkoutForm').addEventListener('submit', function() {
  if (!document.getElementById('paymentMethodHidden').value) {
    alert('Please select a payment method.');
    return false;
  }
  const btn = document.getElementById('placeOrderBtn');
  btn.disabled = true;
  btn.innerHTML = '<i class="bi bi-hourglass-split"></i> Placing order…';
});

/* ── Toast ───────────────────────────────────────────────────────────────*/
function showToast(message, type) {
  const colors = { success:'#10b981', danger:'#ef4444', warning:'#f59e0b' };
  const el = document.createElement('div');
  el.className = 'toast-item';
  el.style.background = colors[type] || '#0f3460';
  el.innerHTML = message;
  document.getElementById('toastWrap').appendChild(el);
  setTimeout(() => el.remove(), 3500);
}

/* ── Address modal helpers ───────────────────────────────────────────────*/
function openAddressModal(action, addressId) {
  var url = 'Address?action=' + action;
  if (addressId) url += '&addressId=' + addressId;
  $('#addressModalContent').load(url, function() {
    new bootstrap.Modal(document.getElementById('addressModal')).show();
  });
}

$(document).on('submit', '#addAddressForm',  function(e) { e.preventDefault(); submitAddressForm($(this), '✅ Address added!'); });
$(document).on('submit', '#editAddressForm', function(e) { e.preventDefault(); submitAddressForm($(this), '✏️ Address updated!'); });

function submitAddressForm($form, msg) {
  $.ajax({
    url: 'Address', type: 'POST', data: $form.serialize(),
    success: function(res) {
      $('#addressSection').html(res);
      bootstrap.Modal.getInstance(document.getElementById('addressModal')).hide();
      showToast(msg, 'success');
    },
    error: function() { showToast('❌ Failed to save address.', 'danger'); }
  });
}

function deleteAddress(addressId, customerId) {
  $.ajax({
    url: 'Address', type: 'POST',
    data: { action: 'delete', addressId: addressId, customerId: customerId },
    success: function(res) {
      if (res.includes('Please choose a new default address')) {
        $('#addressModalContent').html(res);
        new bootstrap.Modal(document.getElementById('addressModal')).show();
      } else {
        $('#addressSection').html(res);
        showToast('🗑️ Address deleted!', 'success');
      }
    },
    error: function() { showToast('❌ Cannot delete only address.', 'danger'); }
  });
}

function setDefaultAddress(addressId, customerId) {
  $.ajax({
    url: 'Address', type: 'POST',
    data: { action: 'setDefault', addressId: addressId, customerId: customerId },
    success: function(res) {
      $('#addressSection').html(res);
      showToast('⭐ Default address set!', 'success');
    },
    error: function() { showToast('❌ Failed.', 'danger'); }
  });
}

$(document).on('click', '#clearFormBtn', function() {
  var form = $('#addressModalContent').find('form')[0];
  if (form) form.reset();
});
</script>

<jsp:include page="customerBottomNav.jsp"><jsp:param name="activePage" value="cart"/></jsp:include>
</body>
</html>
