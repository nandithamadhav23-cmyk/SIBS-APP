<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    String errorMessage = (String) request.getAttribute("errorMessage");
    if (errorMessage == null) errorMessage = "An unexpected error occurred.";

    Boolean customerLoggedIn = (Boolean) session.getAttribute("loggedIn");
    Object customer = session.getAttribute("customer");
    boolean isCustomer = Boolean.TRUE.equals(customerLoggedIn) && customer != null;
    String contextPath = request.getContextPath();
    String backUrl = isCustomer ? contextPath + "/Customer" : contextPath + "/index.jsp";
    String backLabel = isCustomer ? "Customer Dashboard" : "Home";
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Error — SIBS Store</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap-icons/font/bootstrap-icons.css" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;600;700&display=swap" rel="stylesheet">
<style>
*{box-sizing:border-box;margin:0;padding:0;}
body{font-family:'DM Sans',sans-serif;background:#f4f6fb;min-height:100vh;display:flex;align-items:center;justify-content:center;padding:1rem;}
.card{background:#fff;border-radius:18px;box-shadow:0 8px 40px rgba(15,52,96,.12);padding:2.5rem 2rem;text-align:center;max-width:440px;width:100%;}
.err-icon{width:64px;height:64px;border-radius:50%;background:rgba(233,69,96,.08);border:2px solid rgba(233,69,96,.2);display:flex;align-items:center;justify-content:center;margin:0 auto 1.25rem;font-size:1.8rem;color:#e94560;}
.err-title{font-size:1.15rem;font-weight:700;color:#1a1a2e;margin-bottom:.5rem;}
.err-body{background:#fef2f2;border:1px solid #fecaca;border-radius:10px;padding:.75rem 1rem;font-size:.84rem;color:#991b1b;margin:.75rem 0 1.5rem;text-align:left;word-break:break-word;}
.btn-go{display:inline-flex;align-items:center;gap:.5rem;background:#0f3460;color:#fff;border:none;border-radius:10px;padding:.6rem 1.4rem;font-size:.88rem;font-weight:600;text-decoration:none;}
.btn-go:hover{background:#0a2a50;color:#fff;}
.btn-back{display:inline-flex;align-items:center;gap:.5rem;background:transparent;color:#0f3460;border:1.5px solid #0f3460;border-radius:10px;padding:.6rem 1.4rem;font-size:.88rem;font-weight:600;text-decoration:none;margin-left:.75rem;}
</style>
</head>
<body>
<div class="card">
  <div class="err-icon"><i class="bi bi-exclamation-triangle-fill"></i></div>
  <h1 class="err-title">Something Went Wrong</h1>
  <div class="err-body"><%= errorMessage %></div>
  <div>
    <a href="<%= backUrl %>" class="btn-go"><i class="bi bi-house-fill"></i> <%= backLabel %></a>
    <a href="javascript:history.back()" class="btn-back"><i class="bi bi-arrow-left"></i> Go Back</a>
  </div>
</div>
</body>
</html>
