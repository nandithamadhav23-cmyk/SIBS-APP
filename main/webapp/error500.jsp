<%@ page isErrorPage="true" contentType="text/html;charset=UTF-8" language="java" %>
<%
    String uri = (String) request.getAttribute("jakarta.servlet.error.request_uri");
    if (uri == null) uri = "";
    String lowerUri = uri.toLowerCase();

    String contextPath = request.getContextPath();
    String redirectUrl;
    String redirectLabel;

    Boolean customerLoggedIn = (Boolean) session.getAttribute("loggedIn");
    Object customer = session.getAttribute("customer");
    boolean isCustomer = Boolean.TRUE.equals(customerLoggedIn) && customer != null;
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
        if (isCustomer) {
            redirectUrl = contextPath + "/Customer";
            redirectLabel = "Customer Dashboard";
        } else {
            redirectUrl = contextPath + "/index.jsp";
            redirectLabel = "Home Page";
        }
    }

    String errMsg = (exception != null && exception.getMessage() != null) ? exception.getMessage() : "An unexpected internal error occurred.";
    // Don't expose stack to users but log it
    if (exception != null) {
        application.log("500 Error at: " + uri, exception);
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>500 — Something Went Wrong · SIBS Store</title>
<meta http-equiv="refresh" content="6;url=<%= redirectUrl %>">
<link href="https://cdn.jsdelivr.net/npm/bootstrap-icons/font/bootstrap-icons.css" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;600;700&display=swap" rel="stylesheet">
<style>
*{box-sizing:border-box;margin:0;padding:0;}
body{font-family:'DM Sans',sans-serif;background:#f4f6fb;min-height:100vh;display:flex;align-items:center;justify-content:center;padding:1rem;}
.card{background:#fff;border-radius:18px;box-shadow:0 8px 40px rgba(15,52,96,.12);padding:3rem 2.5rem;text-align:center;max-width:480px;width:100%;}
.err-icon{width:72px;height:72px;border-radius:50%;background:rgba(233,69,96,.08);border:2px solid rgba(233,69,96,.2);display:flex;align-items:center;justify-content:center;margin:0 auto 1.25rem;font-size:2rem;color:#e94560;}
.err-code{font-size:4rem;font-weight:800;color:#0f3460;line-height:1;letter-spacing:-2px;}
.err-code span{color:#e94560;}
.err-title{font-size:1.2rem;font-weight:700;color:#1a1a2e;margin:.75rem 0 .5rem;}
.err-msg{color:#6b7280;font-size:.88rem;line-height:1.6;margin-bottom:1.5rem;}
.redirect-info{background:#f0fdf4;border:1px solid #bbf7d0;border-radius:10px;padding:.65rem 1rem;font-size:.82rem;color:#15803d;margin-bottom:1.5rem;display:flex;align-items:center;gap:.5rem;}
.btn-go{display:inline-flex;align-items:center;gap:.5rem;background:#0f3460;color:#fff;border:none;border-radius:10px;padding:.65rem 1.5rem;font-size:.9rem;font-weight:600;text-decoration:none;transition:all .2s;}
.btn-go:hover{background:#0a2a50;color:#fff;}
.btn-back{display:inline-flex;align-items:center;gap:.5rem;background:transparent;color:#0f3460;border:1.5px solid #0f3460;border-radius:10px;padding:.65rem 1.5rem;font-size:.9rem;font-weight:600;text-decoration:none;margin-left:.75rem;transition:all .2s;}
.btn-back:hover{background:#0f3460;color:#fff;}
.err-detail{background:#fef2f2;border:1px solid #fecaca;border-radius:8px;padding:.65rem .9rem;font-size:.75rem;color:#991b1b;margin-top:1.25rem;text-align:left;word-break:break-all;}
.progress-bar{height:4px;background:#e5e7eb;border-radius:4px;overflow:hidden;margin-bottom:1.5rem;}
.progress-fill{height:100%;background:#0f3460;border-radius:4px;width:0%;animation:fillBar 6s linear forwards;}
@keyframes fillBar{from{width:0%;}to{width:100%;}}
@media(max-width:480px){.card{padding:2rem 1.25rem;}}
</style>
</head>
<body>
<div class="card">
  <div class="err-icon"><i class="bi bi-exclamation-triangle-fill"></i></div>
  <div class="err-code">5<span>0</span>0</div>
  <h1 class="err-title">Oops — something broke on our end</h1>
  <p class="err-msg">Our servers hit a bump. This isn't your fault. Our team has been notified and we're fixing it right away.</p>

  <div class="redirect-info">
    <i class="bi bi-arrow-right-circle-fill"></i>
    Taking you back to <strong>&nbsp;<%= redirectLabel %></strong>&nbsp; in 6 seconds…
  </div>

  <div class="progress-bar"><div class="progress-fill"></div></div>

  <div>
    <a href="<%= redirectUrl %>" class="btn-go"><i class="bi bi-house-fill"></i> Go Now</a>
    <a href="javascript:history.back()" class="btn-back"><i class="bi bi-arrow-left"></i> Try Back</a>
  </div>

  <details style="margin-top:1.25rem;text-align:left;">
    <summary style="font-size:.75rem;color:#9ca3af;cursor:pointer;font-weight:600;">Technical Info</summary>
    <div class="err-detail"><%= errMsg %></div>
  </details>
</div>
</body>
</html>
