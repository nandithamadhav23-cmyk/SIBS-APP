<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    String uri = (String) request.getAttribute("jakarta.servlet.error.request_uri");
    if (uri == null) uri = "";
    String lowerUri = uri.toLowerCase();

    // Determine smart redirect target based on URI and session
    String redirectUrl;
    String redirectLabel;
    String contextPath = request.getContextPath();

    // Check if customer is logged in
    Boolean customerLoggedIn = (Boolean) session.getAttribute("loggedIn");
    Object customer = session.getAttribute("customer");
    boolean isCustomer = Boolean.TRUE.equals(customerLoggedIn) && customer != null;

    // Check if staff is logged in
    Object staffUser = session.getAttribute("user");
    String role = (String) session.getAttribute("role");
    boolean isStaff = staffUser != null && role != null && !"customer".equalsIgnoreCase(role);

    if (lowerUri.contains("customer") || lowerUri.contains("cart") || lowerUri.contains("wishlist")
        || lowerUri.contains("checkout") || lowerUri.contains("payment") || lowerUri.contains("order")
        || isCustomer) {
        redirectUrl = contextPath + "/Customer";
        redirectLabel = "Customer Dashboard";
    } else if (lowerUri.contains("delivery")) {
        redirectUrl = contextPath + "/deliveryLogin.jsp";
        redirectLabel = "Delivery Portal";
    } else if (lowerUri.contains("admin") || lowerUri.contains("dashboard") || isStaff) {
        redirectUrl = contextPath + "/dashboard.jsp";
        redirectLabel = "Admin Dashboard";
    } else {
        // Fallback: if customer is logged in, never drop them at index
        if (isCustomer) {
            redirectUrl = contextPath + "/Customer";
            redirectLabel = "Customer Dashboard";
        } else {
            redirectUrl = contextPath + "/index.jsp";
            redirectLabel = "Home Page";
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>404 — Page Not Found · SIBS Store</title>
<meta http-equiv="refresh" content="5;url=<%= redirectUrl %>">
<link href="https://cdn.jsdelivr.net/npm/bootstrap-icons/font/bootstrap-icons.css" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;600;700&display=swap" rel="stylesheet">
<style>
*{box-sizing:border-box;margin:0;padding:0;}
body{font-family:'DM Sans',sans-serif;background:#f4f6fb;min-height:100vh;display:flex;align-items:center;justify-content:center;padding:1rem;}
.card{background:#fff;border-radius:18px;box-shadow:0 8px 40px rgba(15,52,96,.12);padding:3rem 2.5rem;text-align:center;max-width:460px;width:100%;}
.err-code{font-size:5rem;font-weight:800;color:#0f3460;line-height:1;letter-spacing:-3px;}
.err-code span{color:#e94560;}
.err-title{font-size:1.2rem;font-weight:700;color:#1a1a2e;margin:.75rem 0 .5rem;}
.err-msg{color:#6b7280;font-size:.9rem;line-height:1.6;margin-bottom:1.75rem;}
.redirect-info{background:#f0f9ff;border:1px solid #bae6fd;border-radius:10px;padding:.65rem 1rem;font-size:.82rem;color:#0369a1;margin-bottom:1.75rem;display:flex;align-items:center;gap:.5rem;}
.btn-go{display:inline-flex;align-items:center;gap:.5rem;background:#0f3460;color:#fff;border:none;border-radius:10px;padding:.65rem 1.5rem;font-size:.9rem;font-weight:600;text-decoration:none;transition:all .2s;}
.btn-go:hover{background:#0a2a50;color:#fff;transform:translateY(-1px);}
.btn-back{display:inline-flex;align-items:center;gap:.5rem;background:transparent;color:#0f3460;border:1.5px solid #0f3460;border-radius:10px;padding:.65rem 1.5rem;font-size:.9rem;font-weight:600;text-decoration:none;transition:all .2s;margin-left:.75rem;}
.btn-back:hover{background:#0f3460;color:#fff;}
.progress-bar{height:4px;background:#e5e7eb;border-radius:4px;overflow:hidden;margin-bottom:1.5rem;}
.progress-fill{height:100%;background:#0f3460;border-radius:4px;width:0%;animation:fillBar 5s linear forwards;}
@keyframes fillBar{from{width:0%;}to{width:100%;}}
@media(max-width:480px){.card{padding:2rem 1.25rem;}.err-code{font-size:3.5rem;}}
</style>
</head>
<body>
<div class="card">
  <div class="err-code">4<span>0</span>4</div>
  <h1 class="err-title">Hmm, that page doesn't exist</h1>
  <p class="err-msg">The page you're looking for may have moved, been renamed, or never existed. Don't worry — we've got you covered.</p>

  <div class="redirect-info">
    <i class="bi bi-arrow-right-circle-fill"></i>
    Redirecting you to <strong>&nbsp;<%= redirectLabel %></strong>&nbsp; in 5 seconds…
  </div>

  <div class="progress-bar"><div class="progress-fill"></div></div>

  <div>
    <a href="<%= redirectUrl %>" class="btn-go"><i class="bi bi-house-fill"></i> Go Now</a>
    <a href="javascript:history.back()" class="btn-back"><i class="bi bi-arrow-left"></i> Go Back</a>
  </div>
</div>
</body>
</html>
