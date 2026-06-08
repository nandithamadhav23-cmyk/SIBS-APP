<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List, java.util.ArrayList, com.util.*" %>
<%
    Order order            = (Order) request.getAttribute("order");
    Customer customer      = (Customer) request.getAttribute("customer");
    List<CartItem> cartItems = (List<CartItem>) request.getAttribute("cartItems");
    CustomerAddress address  = (CustomerAddress) request.getAttribute("address");
    String paymentMethod   = (String) request.getAttribute("paymentMethod");
    Object orderIdAttr     = request.getAttribute("orderId");

    if(cartItems == null) cartItems = new ArrayList<>();
    boolean isCOD  = "COD".equalsIgnoreCase(paymentMethod);
    boolean isCard = "Card".equalsIgnoreCase(paymentMethod);
    boolean isUPI  = "UPI".equalsIgnoreCase(paymentMethod);
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Order Confirmed — Bazaar</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
  <style>
    :root {
      --gold: #b8960c;
      --gold-light: #d4af37;
      --gold-pale: #f5edd6;
      --ink: #1a1209;
      --cream: #faf6ef;
      --parchment: #f0e9d6;
      --warm-gray: #8b7d6b;
      --border: #d4c4a0;
      --danger-red: #8b1a1a;
      --success-green: #1a5c2e;
    }

    * { box-sizing: border-box; }

    body {
    font-family: 'DM Sans', sans-serif;
      background: var(--cream);
      color: var(--ink);
      min-height: 100vh;
    }

    /* ─── NAV ────────────────────────────────── */
    .top-nav {
      background: var(--ink);
      border-bottom: 3px solid var(--gold);
      padding: 0 2rem;
      height: 64px;
      display: flex; align-items: center; justify-content: space-between;
    }
    .nav-brand { font-size: 1.35rem; font-weight: bold; color: var(--gold-light); letter-spacing: 0.08em; text-decoration: none; }
    .nav-brand span { color: #fff; }

    /* ─── SUCCESS BANNER ─────────────────────── */
    .success-banner {
      background: linear-gradient(135deg, #1a3015 0%, #1a5c2e 60%, #2d7a3a 100%);
      color: #fff;
      padding: 2.5rem 1.5rem;
      text-align: center;
      position: relative;
      overflow: hidden;
    }
    .success-banner::before {
      content: "✦ ✦ ✦";
      position: absolute;
      top: 12px; left: 50%; transform: translateX(-50%);
      color: rgba(212,175,55,0.3);
      font-size: 1.2rem;
      letter-spacing: 1rem;
    }
    .banner-icon {
      width: 80px; height: 80px;
      background: rgba(255,255,255,0.12);
      border: 3px solid rgba(212,175,55,0.6);
      border-radius: 50%;
      display: flex; align-items: center; justify-content: center;
      margin: 0 auto 1rem;
      font-size: 2.2rem;
      animation: checkPop 0.5s cubic-bezier(0.34,1.56,0.64,1) 0.3s both;
    }
    @keyframes checkPop {
      from { transform: scale(0); opacity:0; }
      to   { transform: scale(1); opacity:1; }
    }
    .banner-title { font-size: 2rem; font-weight: bold; letter-spacing: 0.06em; margin: 0 0 0.3rem; }
    .banner-sub   { font-size: 1rem; color: rgba(255,255,255,0.8); font-style: italic; }
    .banner-order-id {
      display: inline-block;
      margin-top: 0.75rem;
      background: rgba(212,175,55,0.2);
      border: 1px solid rgba(212,175,55,0.5);
      border-radius: 20px;
      padding: 4px 20px;
      font-size: 1rem;
      letter-spacing: 0.08em;
      color: var(--gold-light);
    }

    /* ─── LAYOUT ──────────────────────────────── */
    .page-wrapper { max-width: 860px; margin: 2rem auto 4rem; padding: 0 1.5rem; }

    /* ─── SECTION CARD ────────────────────────── */
    .info-card {
      background: #fff;
      border: 1px solid var(--border);
      border-radius: 10px;
      margin-bottom: 1.5rem;
      overflow: hidden;
      box-shadow: 0 2px 10px rgba(184,150,12,0.08);
      animation: fadeUp 0.5s ease both;
    }
    @keyframes fadeUp {
      from { opacity:0; transform:translateY(14px); }
      to   { opacity:1; transform:translateY(0); }
    }
    .info-card:nth-child(2) { animation-delay: 0.1s; }
    .info-card:nth-child(3) { animation-delay: 0.2s; }
    .info-card:nth-child(4) { animation-delay: 0.3s; }
    .info-card:nth-child(5) { animation-delay: 0.4s; }

    .card-header-strip {
      background: var(--parchment);
      border-bottom: 1px solid var(--border);
      padding: 10px 20px;
      font-size: 0.85rem;
      font-weight: bold;
      letter-spacing: 0.1em;
      text-transform: uppercase;
      color: var(--warm-gray);
      display: flex; align-items: center; gap: 8px;
    }
    .card-header-strip i { color: var(--gold); font-size: 1rem; }
    .card-body-inner { padding: 18px 20px; }

    /* ─── DELIVERY TIMELINE ───────────────────── */
    .timeline {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      position: relative;
      padding: 0 0 1rem;
    }
    .timeline::before {
      content: "";
      position: absolute;
      top: 16px; left: 8%; right: 8%;
      height: 3px;
      background: var(--parchment);
    }
    .timeline-fill {
      position: absolute;
      top: 16px; left: 8%;
      height: 3px;
      background: linear-gradient(90deg, var(--gold), #d4af37);
      width: 5%;
      transition: width 1.2s ease;
    }
    .tl-step { width: 20%; display: flex; flex-direction: column; align-items: center; position: relative; z-index: 1; }
    .tl-dot {
      width: 34px; height: 34px;
      border-radius: 50%;
      border: 3px solid var(--border);
      background: #fff;
      display: flex; align-items: center; justify-content: center;
      color: var(--border); font-size: 0.95rem;
      margin-bottom: 8px;
    }
    .tl-dot.active {
      background: var(--gold); border-color: var(--gold); color: #fff;
      box-shadow: 0 0 0 6px rgba(184,150,12,0.15);
    }
    .tl-label { font-size: 0.7rem; text-align: center; color: var(--warm-gray); line-height: 1.3; }
    .tl-label.active { color: var(--gold); font-weight: bold; }

    /* ─── PAYMENT METHOD DISPLAY ──────────────── */
    .payment-box {
      display: flex;
      align-items: center;
      gap: 16px;
      background: var(--parchment);
      border-radius: 8px;
      padding: 14px 16px;
    }
    .payment-icon-big {
      width: 52px; height: 52px;
      border-radius: 8px;
      display: flex; align-items: center; justify-content: center;
      font-size: 1.7rem;
      flex-shrink: 0;
    }
    .pm-cod   { background: #fff8e1; color: #7a4f00; }
    .pm-card  { background: #e3f2fd; color: #1a3f6b; }
    .pm-upi   { background: #e8f5e9; color: #1a5c2e; }
    .pm-title { font-size: 1.05rem; font-weight: bold; }
    .pm-desc  { font-size: 0.84rem; color: var(--warm-gray); margin-top: 2px; }

    /* ─── ITEMS TABLE ─────────────────────────── */
    .items-table { width: 100%; border-collapse: collapse; font-size: 0.88rem; }
    .items-table thead { background: var(--parchment); }
    .items-table th { padding: 8px 12px; text-align: left; font-size: 0.78rem; letter-spacing: 0.08em; text-transform: uppercase; color: var(--warm-gray); }
    .items-table td { padding: 10px 12px; border-bottom: 1px solid var(--parchment); vertical-align: middle; }
    .items-table tr:last-child td { border-bottom: none; }
    .item-img { width: 46px; height: 46px; object-fit: cover; border-radius: 5px; border: 1px solid var(--border); }
    .item-name { font-weight: bold; }
    .item-meta { font-size: 0.76rem; color: var(--warm-gray); }
    .item-total { font-weight: bold; color: var(--success-green); text-align: right; }

    /* ─── PRICE SUMMARY ───────────────────────── */
    .price-summary { font-size: 0.9rem; }
    .price-row { display: flex; justify-content: space-between; padding: 4px 0; color: var(--warm-gray); }
    .price-row.total-row {
      font-size: 1.2rem; font-weight: bold;
      color: var(--ink);
      border-top: 2px solid var(--border);
      margin-top: 10px; padding-top: 10px;
    }
    .price-row.total-row span:last-child { color: var(--success-green); }

    /* ─── ADDRESS BLOCK ───────────────────────── */
    .address-block { font-size: 0.9rem; line-height: 1.8; }
    .address-block .label { font-size: 0.75rem; letter-spacing: 0.1em; text-transform: uppercase; color: var(--warm-gray); font-weight: bold; }

    /* ─── COD NOTICE ──────────────────────────── */
    .cod-notice {
      background: #fff8e1;
      border: 1px solid #ffe08a;
      border-left: 4px solid #c97a00;
      border-radius: 6px;
      padding: 12px 16px;
      font-size: 0.88rem;
      color: #7a4f00;
      display: flex; gap: 10px; align-items: flex-start;
    }

    /* ─── ACTION BUTTONS ──────────────────────── */
    .action-row {
      display: flex; flex-wrap: wrap; gap: 12px; justify-content: center;
      margin-top: 2rem;
      animation: fadeUp 0.6s ease 0.5s both;
    }
    .btn-main {
      font-family: 'Times New Roman', serif;
      font-size: 0.95rem;
      letter-spacing: 0.06em;
      padding: 10px 26px;
      border-radius: 5px;
      border: 2px solid;
      cursor: pointer;
      text-decoration: none;
      display: inline-flex; align-items: center; gap: 8px;
      transition: all 0.2s;
    }
    .btn-primary-gold { background: var(--ink); color: var(--gold-light); border-color: var(--gold); }
    .btn-primary-gold:hover { background: var(--gold); color: var(--ink); }
    .btn-outline-dark-gold { background: transparent; color: var(--ink); border-color: var(--border); }
    .btn-outline-dark-gold:hover { background: var(--ink); color: var(--gold-light); border-color: var(--gold); }
    .btn-outline-green { background: transparent; color: var(--success-green); border-color: var(--success-green); }
    .btn-outline-green:hover { background: var(--success-green); color: #fff; }

    /* ─── CONFETTI HEADER ORNAMENT ────────────── */
    .ornament { color: var(--gold); font-size: 1.1rem; letter-spacing: 0.5rem; text-align: center; margin-bottom: 0.5rem; }

    @media(max-width:600px) {
      .timeline { flex-wrap: wrap; }
      .tl-step { width: 33%; margin-bottom: 12px; }
      .timeline::before, .timeline-fill { display: none; }
      .action-row { flex-direction: column; align-items: stretch; gap: .6rem; }
      .action-row a, .action-row button { width: 100%; text-align: center; justify-content: center; }
      .page-wrapper { padding: 0 .75rem; margin: 1rem auto 3rem; }
      .banner-title { font-size: 1.5rem; }
      /* Order items table horizontal scroll */
      .items-section { overflow-x: auto; -webkit-overflow-scrolling: touch; }
      /* Info grid single column */
      .info-grid, .order-info-grid { grid-template-columns: 1fr !important; }
    }
  @media(max-width:768px){body{padding-bottom:70px;}}
</style>
</head>
<body>

<!-- ══════════ NAV ══════════ -->
<nav class="top-nav">
  <a class="nav-brand" href="Customer">&#9670; <span>Bazaar</span></a>
  <div style="font-size:0.85rem; color:#aaa; font-style:italic;">Order Confirmation</div>
</nav>

<!-- ══════════ SUCCESS BANNER ══════════ -->
<div class="success-banner">
  <div class="banner-icon">&#10003;</div>
  <div class="banner-title">Order Confirmed!</div>
  <div class="banner-sub">
    Thank you, <strong><%= customer != null ? customer.getName() : "Customer" %></strong>.
    Your order has been placed successfully.
  </div>
  <div class="banner-order-id">
    Order # <%= order != null ? order.getId() : "—" %>
  </div>
</div>

<!-- ══════════ CONTENT ══════════ -->
<div class="page-wrapper">

  <!-- ─── DELIVERY TIMELINE ─── -->
  <div class="info-card" style="animation-delay:0s;">
    <div class="card-header-strip"><i class="bi bi-clock-history"></i> Delivery Progress</div>
    <div class="card-body-inner">
      <div class="timeline" id="confirmTimeline">
        <div class="timeline-fill" id="timelineFill" data-progress="5"></div>

        <div class="tl-step">
          <div class="tl-dot active"><i class="bi bi-receipt-cutoff"></i></div>
          <div class="tl-label active">Order<br>Placed</div>
        </div>
        <div class="tl-step">
          <div class="tl-dot"><i class="bi bi-box-seam"></i></div>
          <div class="tl-label">Packed</div>
        </div>
        <div class="tl-step">
          <div class="tl-dot"><i class="bi bi-truck"></i></div>
          <div class="tl-label">Shipped</div>
        </div>
        <div class="tl-step">
          <div class="tl-dot"><i class="bi bi-bicycle"></i></div>
          <div class="tl-label">Out for<br>Delivery</div>
        </div>
        <div class="tl-step">
          <div class="tl-dot"><i class="bi bi-house-check"></i></div>
          <div class="tl-label">Delivered</div>
        </div>
      </div>

      <% if(order != null && order.getDeliveryDate() != null) { %>
      <p style="text-align:center; margin:0; font-size:0.9rem; color:var(--warm-gray);">
        <i class="bi bi-calendar-check" style="color:var(--gold);"></i>
        Estimated delivery:
        <strong style="color:var(--ink);">
          <%= new java.text.SimpleDateFormat("EEEE, dd MMMM yyyy").format(order.getDeliveryDate()) %>
        </strong>
      </p>
      <% } %>
    </div>
  </div>

  <!-- ─── TWO-COL: CUSTOMER & ADDRESS ─── -->
  <div class="row g-4 mb-0">
    <div class="col-md-6">
      <div class="info-card" style="margin-bottom:0; height:100%;">
        <div class="card-header-strip"><i class="bi bi-person-circle"></i> Customer Details</div>
        <div class="card-body-inner address-block">
          <div class="label">Name</div>
          <div><%= customer != null ? customer.getName() : "—" %></div>
          <div class="label" style="margin-top:10px;">Email</div>
          <div><%= customer != null ? customer.getEmail() : "—" %></div>
          <div class="label" style="margin-top:10px;">Phone</div>
          <div><%= customer != null ? customer.getPhone() : "—" %></div>
        </div>
      </div>
    </div>
    <div class="col-md-6">
      <div class="info-card" style="margin-bottom:0; height:100%;">
        <div class="card-header-strip"><i class="bi bi-geo-alt-fill"></i> Shipping Address</div>
        <div class="card-body-inner address-block">
          <% if(address != null) { %>
            <div><%= address.getLandmarkStreet() %></div>
            <div><%= address.getCity() %>, <%= address.getState() %></div>
            <div>PIN: <%= address.getPincode() %></div>
          <% } else { %>
            <div style="color:var(--warm-gray); font-style:italic;">Address not available</div>
          <% } %>
        </div>
      </div>
    </div>
  </div>

  <div style="margin-bottom:1.5rem;"></div>

  <!-- ─── PAYMENT METHOD ─── -->
  <div class="info-card">
    <div class="card-header-strip"><i class="bi bi-credit-card-2-front"></i> Payment Details</div>
    <div class="card-body-inner">
      <div class="payment-box">
        <% if(isCOD) { %>
          <div class="payment-icon-big pm-cod"><i class="bi bi-cash-coin"></i></div>
          <div>
            <div class="pm-title">Cash on Delivery (COD)</div>
            <div class="pm-desc">Please keep exact cash ready at the time of delivery.<br>
              COD charge of ₹<%= order != null ? String.format("%.2f", order.getCodCharge()) : "50.00" %> is included in your total.</div>
          </div>
        <% } else if(isCard) { %>
          <div class="payment-icon-big pm-card"><i class="bi bi-credit-card-fill"></i></div>
          <div>
            <div class="pm-title">Credit / Debit Card</div>
            <div class="pm-desc">Payment received. Your card has been charged ₹<%= order != null ? String.format("%.2f", order.getTotalAmount()) : "—" %> successfully.<br>
              Payment ID will appear in your bank statement within 1–2 business days.</div>
          </div>
        <% } else if(isUPI) { %>
          <div class="payment-icon-big pm-upi"><i class="bi bi-phone-vibrate"></i></div>
          <div>
            <div class="pm-title">UPI Payment</div>
            <div class="pm-desc">₹<%= order != null ? String.format("%.2f", order.getTotalAmount()) : "—" %> deducted from your UPI-linked account.<br>
              Transaction reference will appear in your UPI app.</div>
          </div>
        <% } else { %>
          <div class="payment-icon-big pm-card"><i class="bi bi-wallet2"></i></div>
          <div>
            <div class="pm-title"><%= paymentMethod != null ? paymentMethod : "Online" %></div>
            <div class="pm-desc">Payment processed successfully.</div>
          </div>
        <% } %>
      </div>

      <!-- COD notice -->
      <% if(isCOD) { %>
      <div class="cod-notice" style="margin-top:14px;">
        <i class="bi bi-info-circle-fill fs-5 flex-shrink-0"></i>
        <div>
          <strong>Important:</strong> For COD orders, please do not pay online again. Our delivery executive will collect
          ₹<%= order != null ? String.format("%.2f", order.getTotalAmount()) : "—" %> in cash at your doorstep. No card readers are available at delivery.
        </div>
      </div>
      <% } %>

      <!-- Online payment confirmation note -->
      <% if(isCard || isUPI) { %>
      <div style="margin-top:14px; font-size:0.83rem; color:var(--warm-gray);">
        <i class="bi bi-shield-check" style="color:var(--success-green);"></i>
        Payment secured via Razorpay. Your financial information is encrypted and never stored on our servers.
      </div>
      <% } %>
    </div>
  </div>

  <!-- ─── ITEMS ORDERED ─── -->
  <div class="info-card">
    <div class="card-header-strip"><i class="bi bi-box-seam"></i> Items Ordered (<%= cartItems.size() %>)</div>
    <div class="card-body-inner" style="padding:0;">
      <table class="items-table">
        <thead>
          <tr>
            <th style="padding-left:16px;">Product</th>
            <th>Pack Size</th>
            <th style="text-align:center;">Qty</th>
            <th style="text-align:right;">Unit Price</th>
            <th style="text-align:right; padding-right:16px;">Total</th>
          </tr>
        </thead>
        <tbody>
          <% for(CartItem item : cartItems) { %>
          <tr>
            <td style="padding-left:16px;">
              <div style="display:flex; align-items:center; gap:10px;">
                <% if(item.getImageUrl() != null && !item.getImageUrl().isEmpty()) { %>
                  <img src="${pageContext.request.contextPath}/<%= item.getImageUrl() %>" class="item-img" alt="">
                <% } %>
                <div>
                  <div class="item-name"><%= item.getName() %></div>
                  <% if(item.getDiscount() > 0) { %>
                    <div class="item-meta" style="color:var(--success-green);"><%= (int)item.getDiscount() %>% off applied</div>
                  <% } %>
                </div>
              </div>
            </td>
            <td class="item-meta"><%= item.getProductQuantity() %> <%= item.getUnit() %></td>
            <td style="text-align:center;"><%= item.getQuantity() %></td>
            <td style="text-align:right;">₹ <%= String.format("%.2f", item.getFinalPrice()) %></td>
            <td class="item-total" style="padding-right:16px;">₹ <%= String.format("%.2f", item.getFinalPrice() * item.getQuantity()) %></td>
          </tr>
          <% } %>
        </tbody>
      </table>
    </div>
  </div>

  <!-- ─── PRICE SUMMARY ─── -->
  <div class="info-card">
    <div class="card-header-strip"><i class="bi bi-receipt"></i> Order Summary</div>
    <div class="card-body-inner">
      <div class="price-summary">
        <% if(order != null) { %>
        <div class="price-row"><span>Subtotal</span><span>₹ <%= String.format("%.2f", order.getSubtotal()) %></span></div>
        <div class="price-row"><span>GST (18%)</span><span>₹ <%= String.format("%.2f", order.getGst()) %></span></div>
        <div class="price-row"><span>Tax (5%)</span><span>₹ <%= String.format("%.2f", order.getTax()) %></span></div>
        <div class="price-row">
          <span>Delivery Charges
            <% if(order.getDeliveryCharge() == 0) { %><span style="font-size:0.75rem; color:var(--success-green);"> (Free above ₹700)</span><% } %>
          </span>
          <span>
            <% if(order.getDeliveryCharge() == 0) { %>
              <span style="color:var(--success-green);">FREE</span>
            <% } else { %>
              ₹ <%= String.format("%.2f", order.getDeliveryCharge()) %>
            <% } %>
          </span>
        </div>
        <% if(isCOD && order.getCodCharge() > 0) { %>
        <div class="price-row"><span>COD Handling Charge</span><span>₹ <%= String.format("%.2f", order.getCodCharge()) %></span></div>
        <% } %>
        <div class="price-row total-row">
          <span>Grand Total</span>
          <span>₹ <%= String.format("%.2f", order.getTotalAmount()) %></span>
        </div>
        <% } %>
      </div>
    </div>
  </div>

  <!-- ─── ACTION BUTTONS ─── -->
  <div class="action-row">
    <a href="TrackOrderServlet?orderId=<%= order != null ? order.getId() : 0 %>" class="btn-main btn-primary-gold">
      <i class="bi bi-truck"></i> Track Order
    </a>
    <a href="BillServlet?orderId=<%= orderIdAttr != null ? orderIdAttr : (order != null ? order.getId() : 0) %>" class="btn-main btn-outline-dark-gold">
      <i class="bi bi-file-earmark-pdf"></i> Download Invoice
    </a>
    <a href="CustomerOrdersServlet" class="btn-main btn-outline-dark-gold">
      <i class="bi bi-list-check"></i> My Orders
    </a>
    <a href="Customer" class="btn-main btn-outline-green">
      <i class="bi bi-shop"></i> Continue Shopping
    </a>
  </div>

  <p style="text-align:center; font-size:0.82rem; color:var(--warm-gray); margin-top:1.5rem; font-style:italic;">
    A confirmation has been sent to <strong><%= customer != null ? customer.getEmail() : "your email" %></strong>.
    For support, contact us within 48 hours of order placement.
  </p>

</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
<script>
/* Animate timeline fill on load */
document.addEventListener("DOMContentLoaded", function() {
  const fill = document.getElementById("timelineFill");
  if(fill) setTimeout(() => { fill.style.width = "5%"; }, 400);
});
</script>

<jsp:include page="customerBottomNav.jsp"><jsp:param name="activePage" value="orders"/></jsp:include>
</body>
</html>
