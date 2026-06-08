<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.util.Order, com.util.CustomerAddress, java.util.List, com.util.CartItem, com.util.Customer" %>
<%
    Order order = (Order) request.getAttribute("order");
    CustomerAddress address = (CustomerAddress) request.getAttribute("address");
    List<CartItem> items = (List<CartItem>) request.getAttribute("items");
    Customer customer = (Customer) session.getAttribute("customer");
    Boolean loggedIn = (Boolean) session.getAttribute("loggedIn");

    if (!Boolean.TRUE.equals(loggedIn) || customer == null) {
        response.sendRedirect("CustomerLogin.jsp?redirect=TrackOrderServlet");
        return;
    }

    String custName    = customer.getName() != null ? customer.getName() : "Guest";
    String custInitial = custName.length() > 0 ? String.valueOf(custName.charAt(0)).toUpperCase() : "G";
    Object cartCountObj = session.getAttribute("cartCount");
    int cartCount = (cartCountObj instanceof Integer) ? (Integer) cartCountObj : 0;
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Track Order — SIBS Store</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
<link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet">
<style>
:root{--primary:#0f3460;--accent:#e94560;--gold:#f5a623;--success:#10b981;--warning:#f59e0b;--bg:#f4f6fb;--surface:#fff;--text:#1a1a2e;--muted:#6b7280;--border:rgba(0,0,0,.08);--nav-h:62px;--bot-h:62px;--radius:14px;--shadow:0 2px 20px rgba(15,52,96,.09);}
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0;}
body{font-family:'DM Sans',sans-serif;background:var(--bg);color:var(--text);padding-top:var(--nav-h);}
@media(max-width:768px){body{padding-bottom:var(--bot-h);}}

/* NAV */
.top-nav{position:fixed;top:0;left:0;right:0;z-index:1000;height:var(--nav-h);background:var(--primary);display:flex;align-items:center;padding:0 1.25rem;gap:.75rem;box-shadow:0 2px 16px rgba(0,0,0,.2);}
.nav-brand{font-size:1.1rem;font-weight:700;color:#fff;text-decoration:none;}
.nav-brand em{color:var(--accent);font-style:normal;}
.nav-spacer{flex:1;}
.nav-icon-btn{background:rgba(255,255,255,.1);border:1px solid rgba(255,255,255,.15);border-radius:10px;color:#fff;width:38px;height:38px;display:flex;align-items:center;justify-content:center;text-decoration:none;font-size:1rem;transition:all .2s;position:relative;}
.nav-icon-btn:hover{background:rgba(255,255,255,.2);color:#fff;}
.nav-badge{position:absolute;top:-4px;right:-4px;background:var(--accent);color:#fff;font-size:.6rem;font-weight:700;min-width:16px;height:16px;border-radius:50%;display:flex;align-items:center;justify-content:center;border:2px solid var(--primary);}

/* PAGE */
.page-wrap{max-width:760px;margin:0 auto;padding:1.5rem 1rem;}
.page-header{margin-bottom:1.25rem;}
.page-title{font-size:1.3rem;font-weight:700;color:var(--primary);display:flex;align-items:center;gap:.5rem;}
.back-link{display:inline-flex;align-items:center;gap:.35rem;color:var(--muted);font-size:.82rem;text-decoration:none;margin-bottom:.75rem;font-weight:500;}
.back-link:hover{color:var(--primary);}

/* CARD */
.card{background:var(--surface);border-radius:var(--radius);box-shadow:var(--shadow);border:1px solid var(--border);overflow:hidden;margin-bottom:1rem;}
.card-header{padding:.9rem 1.25rem;border-bottom:1px solid var(--border);background:#f9fafb;display:flex;align-items:center;justify-content:space-between;}
.card-title{font-size:.9rem;font-weight:700;color:var(--primary);display:flex;align-items:center;gap:.4rem;}
.card-body{padding:1.25rem;}

/* STATUS BADGE */
.status-badge{display:inline-flex;align-items:center;gap:.35rem;border-radius:20px;padding:.28rem .9rem;font-size:.75rem;font-weight:700;}
.status-pending{background:rgba(245,158,11,.12);color:#d97706;border:1px solid rgba(245,158,11,.3);}
.status-packed{background:rgba(59,130,246,.12);color:#2563eb;border:1px solid rgba(59,130,246,.3);}
.status-shipped{background:rgba(139,92,246,.12);color:#7c3aed;border:1px solid rgba(139,92,246,.3);}
.status-completed{background:rgba(16,185,129,.12);color:#059669;border:1px solid rgba(16,185,129,.3);}
.status-cancelled{background:rgba(239,68,68,.12);color:#dc2626;border:1px solid rgba(239,68,68,.3);}

/* ORDER META GRID */
.meta-grid{display:grid;grid-template-columns:1fr 1fr;gap:.75rem;}
@media(max-width:480px){.meta-grid{grid-template-columns:1fr;}}
.meta-item{background:var(--bg);border-radius:10px;padding:.65rem .9rem;}
.meta-label{font-size:.65rem;text-transform:uppercase;letter-spacing:.07em;color:var(--muted);font-weight:700;margin-bottom:3px;}
.meta-val{font-size:.88rem;font-weight:700;color:var(--text);}

/* PROGRESS STEPPER */
.stepper{display:flex;align-items:flex-start;justify-content:space-between;margin:1.25rem 0;position:relative;padding:0 .5rem;}
.stepper::before{content:'';position:absolute;top:18px;left:calc(.5rem + 18px);right:calc(.5rem + 18px);height:3px;background:var(--border);z-index:0;}
.stepper-progress{position:absolute;top:18px;left:calc(.5rem + 18px);height:3px;background:var(--success);z-index:1;transition:width .6s ease;}
.step{display:flex;flex-direction:column;align-items:center;gap:.4rem;flex:1;position:relative;z-index:2;}
.step-circle{width:36px;height:36px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:1rem;border:2.5px solid var(--border);background:var(--surface);transition:all .3s;}
.step.done .step-circle{background:var(--success);border-color:var(--success);color:#fff;}
.step.active .step-circle{background:var(--primary);border-color:var(--primary);color:#fff;box-shadow:0 0 0 4px rgba(15,52,96,.15);}
.step-label{font-size:.65rem;font-weight:700;text-align:center;color:var(--muted);text-transform:uppercase;letter-spacing:.04em;max-width:60px;}
.step.done .step-label,.step.active .step-label{color:var(--primary);}

/* ITEMS TABLE */
.items-table{width:100%;border-collapse:collapse;font-size:.85rem;}
.items-table thead th{background:var(--primary);color:rgba(255,255,255,.85);padding:.6rem .75rem;font-size:.7rem;text-transform:uppercase;letter-spacing:.06em;font-weight:700;text-align:left;}
.items-table thead th:last-child{text-align:right;}
.items-table tbody td{padding:.65rem .75rem;border-bottom:1px solid var(--border);vertical-align:middle;}
.items-table tbody tr:last-child td{border-bottom:none;}
.items-table tbody td:last-child{text-align:right;font-weight:700;}
.item-name{font-weight:600;color:var(--text);}
.item-unit{font-size:.72rem;color:var(--muted);}
.total-row td{background:#f9fafb;font-weight:700;font-size:.9rem;}

/* NO ORDER */
.no-order{text-align:center;padding:3rem 1rem;}
.no-order-icon{font-size:3rem;color:var(--muted);opacity:.4;margin-bottom:1rem;}

/* TOAST */
.toast-wrap{position:fixed;bottom:calc(var(--bot-h) + .75rem);right:1rem;z-index:9999;display:flex;flex-direction:column;gap:.5rem;}
.toast-item{background:var(--primary);color:#fff;padding:.7rem 1.1rem;border-radius:10px;font-size:.83rem;font-weight:500;display:flex;align-items:center;gap:.5rem;box-shadow:0 4px 20px rgba(0,0,0,.2);animation:slideIn .3s ease;}
@keyframes slideIn{from{transform:translateX(100%);opacity:0;}to{transform:translateX(0);opacity:1;}}
@media(min-width:769px){.toast-wrap{bottom:1.5rem;}}
</style>
</head>
<body>

<nav class="top-nav">
  <a href="Customer" class="nav-brand">SIBS<em>.</em></a>
  <span class="nav-spacer"></span>
  <a href="CartServlet?action=view" class="nav-icon-btn" title="Cart">
    <i class="bi bi-bag"></i>
    <% if (cartCount > 0) { %><span class="nav-badge"><%= cartCount %></span><% } %>
  </a>
  <a href="CustomerProfile" class="nav-icon-btn" title="Profile">
    <i class="bi bi-person-circle"></i>
  </a>
</nav>

<div class="page-wrap">
  <a href="CustomerOrdersServlet" class="back-link"><i class="bi bi-arrow-left"></i> Back to My Orders</a>
  <div class="page-header">
    <h1 class="page-title"><i class="bi bi-truck"></i> Track Your Order</h1>
  </div>

<% if (order == null) { %>
  <div class="card">
    <div class="card-body" style="padding:2rem;">
      <div style="text-align:center;margin-bottom:1.5rem;">
        <div class="no-order-icon"><i class="bi bi-search"></i></div>
        <h5 style="font-weight:700;margin-bottom:.4rem;">Track Your Order</h5>
        <p style="color:var(--muted);font-size:.88rem;">Enter your order ID to see real-time delivery status.</p>
      </div>
      <form action="TrackOrderServlet" method="get" style="max-width:360px;margin:0 auto 1.5rem;">
        <div style="display:flex;gap:.5rem;">
          <input type="number" name="orderId" min="1" placeholder="Enter Order ID (e.g. 1042)"
            style="flex:1;padding:.6rem .9rem;border:1.5px solid var(--border);border-radius:10px;font-size:.9rem;font-family:'DM Sans',sans-serif;outline:none;"
            required>
          <button type="submit"
            style="background:var(--primary);color:#fff;border:none;border-radius:10px;padding:.6rem 1.2rem;font-weight:700;cursor:pointer;font-size:.88rem;white-space:nowrap;">
            <i class="bi bi-search"></i> Track
          </button>
        </div>
      </form>
      <div style="text-align:center;">
        <a href="CustomerOrdersServlet" style="color:var(--primary);font-size:.85rem;font-weight:600;text-decoration:none;">
          <i class="bi bi-box-seam"></i> View All My Orders
        </a>
      </div>
    </div>
  </div>
<% } else {
    String status = order.getStatus() != null ? order.getStatus() : "Pending";
    int stepIndex = status.equals("Pending") ? 0 : status.equals("Packed") ? 1 : status.equals("Shipped") ? 2 : status.equals("Completed") ? 3 : 0;
    double progressPct = stepIndex == 0 ? 0 : stepIndex == 1 ? 33 : stepIndex == 2 ? 66 : 100;
%>

  <!-- Order Summary -->
  <div class="card">
    <div class="card-header">
      <span class="card-title"><i class="bi bi-receipt"></i> Order #<%= order.getId() %></span>
      <span class="status-badge status-<%= status.toLowerCase() %>">
        <i class="bi bi-circle-fill" style="font-size:.5rem;"></i> <%= status %>
      </span>
    </div>
    <div class="card-body">
      <div class="meta-grid">
        <div class="meta-item">
          <div class="meta-label">Order Date</div>
          <div class="meta-val"><%= order.getDate() != null ? new java.text.SimpleDateFormat("dd MMM yyyy").format(order.getDate()) : "—" %></div>
        </div>
        <div class="meta-item">
          <div class="meta-label">Expected Delivery</div>
          <div class="meta-val"><%= order.getDeliveryDate() != null ? new java.text.SimpleDateFormat("dd MMM yyyy").format(order.getDeliveryDate()) : "To be confirmed" %></div>
        </div>
        <div class="meta-item">
          <div class="meta-label">Payment Mode</div>
          <div class="meta-val"><%= order.getPaymentMethod() != null ? order.getPaymentMethod() : "—" %></div>
        </div>
        <div class="meta-item">
          <div class="meta-label">Order Total</div>
          <div class="meta-val" style="color:var(--success);">₹ <%= String.format("%.2f", order.getTotalAmount()) %></div>
        </div>
      </div>
    </div>
  </div>

  <!-- Progress Stepper -->
  <div class="card">
    <div class="card-header">
      <span class="card-title"><i class="bi bi-clock-history"></i> Delivery Status</span>
    </div>
    <div class="card-body">
      <div class="stepper">
        <div class="stepper-progress" style="width:<%= progressPct %>%;"></div>
        <div class="step <%= stepIndex >= 0 ? (stepIndex == 0 ? "active" : "done") : "" %>">
          <div class="step-circle"><i class="bi bi-<%= stepIndex > 0 ? "check-lg" : "clock" %>"></i></div>
          <div class="step-label">Order Placed</div>
        </div>
        <div class="step <%= stepIndex >= 2 ? "done" : stepIndex == 1 ? "active" : "" %>">
          <div class="step-circle"><i class="bi bi-<%= stepIndex > 1 ? "check-lg" : "box-seam" %>"></i></div>
          <div class="step-label">Packed</div>
        </div>
        <div class="step <%= stepIndex >= 3 ? "done" : stepIndex == 2 ? "active" : "" %>">
          <div class="step-circle"><i class="bi bi-<%= stepIndex > 2 ? "check-lg" : "truck" %>"></i></div>
          <div class="step-label">Shipped</div>
        </div>
        <div class="step <%= stepIndex == 3 ? "done active" : "" %>">
          <div class="step-circle"><i class="bi bi-house-check<%= stepIndex == 3 ? "" : "" %>"></i></div>
          <div class="step-label">Delivered</div>
        </div>
      </div>
      <% if ("Cancelled".equalsIgnoreCase(status)) { %>
      <div class="alert" style="background:rgba(239,68,68,.08);border:1px solid rgba(239,68,68,.2);border-radius:10px;padding:.75rem 1rem;font-size:.83rem;color:#dc2626;display:flex;align-items:center;gap:.5rem;margin-top:1rem;">
        <i class="bi bi-x-circle-fill"></i> This order was cancelled. Any payment will be refunded to your wallet within 2–3 business days.
      </div>
      <% } %>
    </div>
  </div>

  <!-- Delivery Address -->
  <% if (address != null) { %>
  <div class="card">
    <div class="card-header">
      <span class="card-title"><i class="bi bi-geo-alt-fill"></i> Shipping Address</span>
    </div>
    <div class="card-body">
      <p style="font-weight:600;margin-bottom:.2rem;"><%= address.getLandmarkStreet() %></p>
      <p style="color:var(--muted);font-size:.87rem;"><%= address.getCity() %>, <%= address.getState() %> — <%= address.getPincode() %></p>
    </div>
  </div>
  <% } %>

  <!-- Items -->
  <% if (items != null && !items.isEmpty()) { %>
  <div class="card">
    <div class="card-header">
      <span class="card-title"><i class="bi bi-bag-check"></i> Items in This Order</span>
    </div>
    <div class="card-body" style="padding:0;">
      <div style="overflow-x:auto;">
      <table class="items-table">
        <thead>
          <tr>
            <th>Product</th>
            <th>Qty</th>
            <th>Price</th>
            <th>Total</th>
          </tr>
        </thead>
        <tbody>
          <% double grandTotal = 0;
             for (CartItem item : items) {
               double lineTotal = item.getFinalPrice() * item.getQuantity();
               grandTotal += lineTotal;
          %>
          <tr>
            <td>
              <div class="item-name"><%= item.getName() %></div>
              <% if (item.getUnit() != null && !item.getUnit().isEmpty()) { %>
              <div class="item-unit"><%= item.getUnit() %></div>
              <% } %>
            </td>
            <td><%= item.getQuantity() %></td>
            <td>₹ <%= String.format("%.2f", item.getFinalPrice()) %></td>
            <td>₹ <%= String.format("%.2f", lineTotal) %></td>
          </tr>
          <% } %>
          <tr class="total-row">
            <td colspan="3" style="text-align:right;padding-right:1rem;">Order Total</td>
            <td style="color:var(--success);">₹ <%= String.format("%.2f", grandTotal) %></td>
          </tr>
        </tbody>
      </table>
      </div>
    </div>
  </div>
  <% } %>

  <div style="display:flex;gap:.75rem;flex-wrap:wrap;margin-top:.5rem;">
    <a href="CustomerOrdersServlet" class="btn" style="background:var(--primary);color:#fff;border-radius:10px;padding:.6rem 1.4rem;font-weight:600;font-size:.88rem;">
      <i class="bi bi-arrow-left"></i> All Orders
    </a>
    <a href="HelpDesk" class="btn" style="background:transparent;color:var(--primary);border:1.5px solid var(--primary);border-radius:10px;padding:.6rem 1.4rem;font-weight:600;font-size:.88rem;">
      <i class="bi bi-headset"></i> Need Help?
    </a>
  </div>

<% } %>
</div>

<jsp:include page="customerBottomNav.jsp"><jsp:param name="activePage" value="orders"/></jsp:include>

<div class="toast-wrap" id="toastWrap"></div>
</body>
</html>
