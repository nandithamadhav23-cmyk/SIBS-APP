a<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    String orderId = request.getParameter("orderId");
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Payment Failed — SIBS STORE</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css" rel="stylesheet">
  <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;700&display=swap" rel="stylesheet">
  <style>
    @media(max-width:768px){body{padding-bottom:70px;}}
    body { font-family: 'DM Sans', sans-serif; background: #fff5f5; }
    .fail-card { max-width: 480px; margin: 80px auto; background:#fff;
                 border-radius:16px; box-shadow:0 8px 32px rgba(0,0,0,.08); padding:48px 40px; text-align:center; }
    .icon-circle { width:80px; height:80px; border-radius:50%; background:#ffe0e0;
                   display:flex; align-items:center; justify-content:center; margin:0 auto 24px; }
  </style>
</head>
<body>
<div class="fail-card">
  <div class="icon-circle">
    <i class="bi bi-x-circle-fill text-danger" style="font-size:2.5rem;"></i>
  </div>
  <h3 class="fw-bold text-danger mb-2">Payment Failed</h3>
  <p class="text-muted mb-1">Your order <strong>#<%= orderId != null ? orderId : "—" %></strong> was not completed.</p>
  <p class="text-muted mb-4">No money has been deducted. You can safely retry.</p>

  <div class="d-grid gap-3">
    <% if (orderId != null) { %>
    <a href="RetryPaymentServlet?orderId=<%= orderId %>" class="btn btn-success btn-lg rounded-pill">
      <i class="bi bi-arrow-clockwise me-2"></i>Retry Payment
    </a>
    <% } %>
    <a href="CartServlet?action=view" class="btn btn-outline-secondary rounded-pill">
      <i class="bi bi-cart me-2"></i>Return to Cart
    </a>
    <a href="Customer" class="btn btn-link text-muted">
      <i class="bi bi-house-door me-1"></i>Go to Home
    </a>
  </div>

  <p class="mt-4 text-muted" style="font-size:.8rem;">
    Need help? Contact us at <a href="mailto:support@sibsstore.com">support@sibsstore.com</a>
  </p>
</div>

<jsp:include page="customerBottomNav.jsp"><jsp:param name="activePage" value="cart"/></jsp:include>
</body>
</html>
