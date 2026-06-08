<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.util.Customer" %>
<%
    Customer customer = (Customer) session.getAttribute("customer");
    Boolean loggedIn  = (Boolean)  session.getAttribute("loggedIn");
    if (!Boolean.TRUE.equals(loggedIn) || customer == null) {
        response.sendRedirect("CustomerLogin.jsp?redirect=AddressBook.jsp");
        return;
    }
    String custName    = customer.getName() != null ? customer.getName() : "Guest";
    String custInitial = custName.length() > 0 ? String.valueOf(custName.charAt(0)).toUpperCase() : "G";
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Address Book — SIBS Store</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
<link href="https://cdn.jsdelivr.net/npm/bootstrap-icons/font/bootstrap-icons.css" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet">
<style>
:root{--primary:#0f3460;--accent:#e94560;--bg:#f4f6fb;--surface:#fff;--text:#1a1a2e;--muted:#6b7280;--border:rgba(0,0,0,.08);--nav-h:62px;--bot-h:62px;--radius:14px;}
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0;}
body{font-family:'DM Sans',sans-serif;background:var(--bg);color:var(--text);padding-top:var(--nav-h);}
@media(max-width:768px){body{padding-bottom:var(--bot-h);}}
.top-nav{position:fixed;top:0;left:0;right:0;z-index:1000;height:var(--nav-h);background:var(--primary);display:flex;align-items:center;padding:0 1.25rem;gap:1rem;box-shadow:0 2px 16px rgba(0,0,0,.2);}
.nav-back{color:rgba(255,255,255,.8);text-decoration:none;font-size:.9rem;font-weight:500;display:flex;align-items:center;gap:.4rem;}
.nav-back:hover{color:#fff;}
.nav-brand{font-size:1.1rem;font-weight:700;color:#fff;text-decoration:none;margin-left:.5rem;}
.nav-brand em{color:var(--accent);font-style:normal;}
.nav-spacer{flex:1;}
.nav-icon-btn{background:rgba(255,255,255,.1);border:1px solid rgba(255,255,255,.15);border-radius:10px;color:#fff;width:38px;height:38px;display:flex;align-items:center;justify-content:center;text-decoration:none;font-size:1rem;transition:all .2s;}
.nav-icon-btn:hover{background:rgba(255,255,255,.2);color:#fff;}

.page-wrap{max-width:700px;margin:0 auto;padding:2rem 1rem;}

/* Coming Soon Card */
.cs-card{background:var(--surface);border-radius:var(--radius);box-shadow:0 4px 30px rgba(15,52,96,.1);padding:3rem 2rem;text-align:center;}
.cs-icon{width:80px;height:80px;border-radius:50%;background:linear-gradient(135deg,rgba(15,52,96,.08),rgba(233,69,96,.08));display:flex;align-items:center;justify-content:center;margin:0 auto 1.5rem;font-size:2.2rem;color:var(--primary);}
.cs-title{font-size:1.4rem;font-weight:700;color:var(--primary);margin-bottom:.5rem;}
.cs-subtitle{color:var(--muted);font-size:.92rem;line-height:1.6;max-width:380px;margin:0 auto 2rem;}
.cs-badge{display:inline-flex;align-items:center;gap:.4rem;background:rgba(233,69,96,.08);border:1px solid rgba(233,69,96,.2);color:var(--accent);border-radius:20px;padding:.35rem 1rem;font-size:.78rem;font-weight:700;margin-bottom:2rem;}
.btn-primary-cs{display:inline-flex;align-items:center;gap:.5rem;background:var(--primary);color:#fff;border:none;border-radius:10px;padding:.65rem 1.5rem;font-size:.9rem;font-weight:600;text-decoration:none;cursor:pointer;transition:all .2s;}
.btn-primary-cs:hover{background:#0a2a50;color:#fff;transform:translateY(-1px);}
.btn-outline-cs{display:inline-flex;align-items:center;gap:.5rem;background:transparent;color:var(--primary);border:1.5px solid var(--primary);border-radius:10px;padding:.65rem 1.5rem;font-size:.9rem;font-weight:600;text-decoration:none;transition:all .2s;margin-left:.75rem;}
.btn-outline-cs:hover{background:var(--primary);color:#fff;}

/* While you wait - links to AddressSnippet workflow */
.quick-links{display:grid;grid-template-columns:1fr 1fr;gap:.75rem;margin-top:2rem;}
@media(max-width:480px){.quick-links{grid-template-columns:1fr;}}
.ql-item{background:var(--bg);border:1.5px solid var(--border);border-radius:10px;padding:1rem;display:flex;align-items:center;gap:.75rem;text-decoration:none;color:var(--text);transition:all .2s;}
.ql-item:hover{border-color:var(--primary);background:rgba(15,52,96,.03);color:var(--primary);}
.ql-icon{width:36px;height:36px;border-radius:8px;background:rgba(15,52,96,.08);display:flex;align-items:center;justify-content:center;color:var(--primary);font-size:1rem;flex-shrink:0;}
.ql-text{font-size:.82rem;font-weight:600;}

/* Toast */
.toast-wrap{position:fixed;bottom:calc(var(--bot-h) + .75rem);right:1rem;z-index:9999;display:flex;flex-direction:column;gap:.5rem;}
.toast-item{background:var(--primary);color:#fff;padding:.7rem 1.1rem;border-radius:10px;font-size:.83rem;font-weight:500;display:flex;align-items:center;gap:.5rem;box-shadow:0 4px 20px rgba(0,0,0,.2);animation:slideIn .3s ease;}
@keyframes slideIn{from{transform:translateX(100%);opacity:0;}to{transform:translateX(0);opacity:1;}}
@media(min-width:769px){.toast-wrap{bottom:1.5rem;}}
</style>
</head>
<body>

<nav class="top-nav">
  <a href="CustomerProfile" class="nav-back"><i class="bi bi-arrow-left"></i></a>
  <a href="Customer" class="nav-brand">SIBS<em>.</em></a>
  <span class="nav-spacer"></span>
  <a href="CartServlet?action=view" class="nav-icon-btn"><i class="bi bi-bag"></i></a>
</nav>

<div class="page-wrap">
  <div class="cs-card">
    <div class="cs-icon"><i class="bi bi-geo-alt-fill"></i></div>
    <div class="cs-badge"><i class="bi bi-stars"></i> Coming in the Next Update</div>
    <h1 class="cs-title">Address Book is Almost Here</h1>
    <p class="cs-subtitle">We're building a slick, intelligent address manager — save multiple addresses, set a default, and enjoy one-tap checkout. It'll be worth the wait.</p>

    <div style="display:flex;justify-content:center;flex-wrap:wrap;gap:.5rem;">
      <a href="Checkout" class="btn-primary-cs"><i class="bi bi-credit-card-fill"></i> Checkout Now</a>
      <a href="Customer" class="btn-outline-cs"><i class="bi bi-house"></i> Back to Shop</a>
    </div>

    <div class="quick-links">
      <a href="CustomerOrdersServlet" class="ql-item">
        <span class="ql-icon"><i class="bi bi-box-seam"></i></span>
        <span class="ql-text">View My Orders</span>
      </a>
      <a href="CustomerProfile" class="ql-item">
        <span class="ql-icon"><i class="bi bi-person-circle"></i></span>
        <span class="ql-text">My Profile</span>
      </a>
      <a href="CustomerWallet" class="ql-item">
        <span class="ql-icon"><i class="bi bi-wallet2"></i></span>
        <span class="ql-text">My Wallet</span>
      </a>
      <a href="HelpDesk" class="ql-item">
        <span class="ql-icon"><i class="bi bi-headset"></i></span>
        <span class="ql-text">Help & Support</span>
      </a>
    </div>
  </div>
</div>

<jsp:include page="customerBottomNav.jsp"><jsp:param name="activePage" value="profile"/></jsp:include>

<div class="toast-wrap" id="toastWrap"></div>
<script>
window.addEventListener('load', function() {
  const wrap = document.getElementById('toastWrap');
  const div = document.createElement('div');
  div.className = 'toast-item';
  div.innerHTML = '<i class="bi bi-info-circle-fill" style="color:#f5a623;"></i> Address Book is launching soon — stay tuned!';
  wrap.appendChild(div);
  setTimeout(() => { div.style.opacity='0'; div.style.transition='opacity .4s'; setTimeout(()=>div.remove(),400); }, 4500);
});
</script>
</body>
</html>
