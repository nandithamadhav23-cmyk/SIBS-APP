<%@ page contentType="text/html; charset=UTF-8" %>
<%@ page import="java.util.List" %>
<%@ page import="com.util.*" %>
<%
    List<CartItem> cartItems  = (List<CartItem>) request.getAttribute("cartItems");
    List<CartItem> savedItems = (List<CartItem>) request.getAttribute("savedItems");
    Customer customer         = (Customer) session.getAttribute("customer");
    Integer totalProducts     = (Integer)  request.getAttribute("totalProducts");
    String subtotal           = (String)   request.getAttribute("subtotal");
    String gst                = (String)   request.getAttribute("gst");
    String tax                = (String)   request.getAttribute("tax");
    String grandTotal         = (String)   request.getAttribute("grandTotal");

    boolean hasItems  = cartItems  != null && !cartItems.isEmpty();
    boolean hasSaved  = savedItems != null && !savedItems.isEmpty();
    String initials   = (customer != null && customer.getName() != null && !customer.getName().isEmpty())
                        ? String.valueOf(customer.getName().charAt(0)).toUpperCase() : "U";
    String firstName  = (customer != null && customer.getName() != null)
                        ? customer.getName().split(" ")[0] : "there";
    double subD = 0;
    try { if (subtotal != null) subD = Double.parseDouble(subtotal); } catch (Exception ignored) {}
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>My Cart — SIBS Store</title>
  <link href="https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,400;0,600;0,700;1,400;1,600&family=Inter:wght@300;400;500;600;700&family=JetBrains+Mono:wght@400;600;700&display=swap" rel="stylesheet">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
  <style>
    :root {
      --ink:#1a3c34; --ink2:#3d5a52; --muted:#78716c;
      --bg:#faf7f2; --surface:#fff; --border:#e8e2d9;
      --accent:#f59e0b; --green:#16a34a; --gold:#f59e0b; --blue:#0891b2;
      --nav-h:64px; --r:16px;
      --sh:0 2px 16px rgba(26,60,52,.07); --sh2:0 8px 32px rgba(26,60,52,.13);
    }
    *,*::before,*::after{box-sizing:border-box;margin:0;padding:0;}
    @media(max-width:768px){body{padding-bottom:70px;}}
    body{font-family:'Inter',sans-serif;background:var(--bg);color:var(--ink);padding-top:var(--nav-h);min-height:100vh;}

    /* ── NAV ── */
    .nav{position:fixed;top:0;left:0;right:0;z-index:900;height:var(--nav-h);background:var(--ink);display:flex;align-items:center;padding:0 1.25rem;gap:.75rem;box-shadow:0 2px 20px rgba(0,0,0,.3);}
    .nav-brand{font-family:'Cormorant Garamond',serif;font-size:1.65rem;font-weight:700;color:#fff;text-decoration:none;letter-spacing:.5px;font-style:italic;}
    .nav-brand em{color:var(--accent);font-style:normal;}
    .nav-back{display:flex;align-items:center;gap:.4rem;background:rgba(255,255,255,.09);border:1px solid rgba(255,255,255,.12);border-radius:10px;color:rgba(255,255,255,.8);font-size:.82rem;font-weight:500;font-family:'Inter',sans-serif;padding:.4rem .85rem;text-decoration:none;transition:.2s;letter-spacing:.2px;}
    .nav-back:hover{background:rgba(255,255,255,.18);color:#fff;}
    .nav-right{margin-left:auto;display:flex;align-items:center;gap:.5rem;}
    .nav-icon{width:38px;height:38px;border-radius:10px;background:rgba(255,255,255,.09);border:1px solid rgba(255,255,255,.12);color:rgba(255,255,255,.8);font-size:1.1rem;display:flex;align-items:center;justify-content:center;text-decoration:none;transition:.2s;}
    .nav-icon:hover{background:rgba(255,255,255,.18);color:#fff;}
    .nav-avatar{width:36px;height:36px;border-radius:50%;background:linear-gradient(135deg,var(--accent),#d97706);font-family:'Cormorant Garamond',serif;font-weight:700;font-size:1.05rem;color:#fff;display:flex;align-items:center;justify-content:center;}

    /* ── PAGE ── */
    .page{max-width:1100px;margin:0 auto;padding:1.75rem 1rem 5rem;}

    /* ── PAGE HEADER ── */
    .page-head{display:flex;align-items:center;gap:.75rem;margin-bottom:1.5rem;flex-wrap:wrap;}
    .page-title{font-family:'Cormorant Garamond',serif;font-size:1.75rem;font-weight:700;letter-spacing:.3px;}
    .cart-badge{background:var(--accent);color:#fff;font-family:'Inter',sans-serif;font-size:.7rem;font-weight:700;padding:2px 10px;border-radius:30px;letter-spacing:.5px;}

    /* ── PROGRESS BAR ── */
    .del-progress{background:var(--surface);border-radius:var(--r);border:1px solid var(--border);padding:1rem 1.25rem;margin-bottom:1.25rem;box-shadow:var(--sh);}
    .del-progress-label{font-size:.8rem;font-weight:600;font-family:'Inter',sans-serif;color:var(--ink2);margin-bottom:.6rem;display:flex;justify-content:space-between;}
    .del-bar{height:6px;border-radius:6px;background:var(--border);overflow:hidden;}
    .del-bar-fill{height:100%;border-radius:6px;background:linear-gradient(90deg,var(--green),#15803d);transition:width .4s;}
    .del-tip{font-size:.75rem;color:var(--muted);margin-top:.4rem;}
    .del-tip strong{color:var(--green);}

    /* ── LAYOUT ── */
    .cart-layout{display:grid;grid-template-columns:1fr 356px;gap:1.5rem;align-items:start;}
    @media(max-width:860px){.cart-layout{grid-template-columns:1fr;}}

    /* ── CART ITEM CARD ── */
    .ci-card{background:var(--surface);border-radius:var(--r);border:1px solid var(--border);box-shadow:var(--sh);overflow:hidden;margin-bottom:.85rem;transition:box-shadow .2s,transform .2s;}
    .ci-card:hover{box-shadow:var(--sh2);transform:translateY(-2px);}
    .ci-inner{display:flex;}
    .ci-img{width:148px;flex-shrink:0;background:#f8f8fb;display:flex;align-items:center;justify-content:center;padding:.75rem;border-right:1px solid var(--border);}
    @media(max-width:500px){.ci-img{width:105px;}}
    .ci-img img{width:100%;height:115px;object-fit:contain;transition:transform .3s;}
    .ci-card:hover .ci-img img{transform:scale(1.06);}
    .ci-body{flex:1;padding:1rem;display:flex;flex-direction:column;gap:.3rem;min-width:0;}
    .ci-cat{font-size:.65rem;text-transform:uppercase;letter-spacing:1.5px;color:var(--muted);font-weight:600;font-family:'Inter',sans-serif;}
    .ci-name{font-family:'Cormorant Garamond',serif;font-size:1.1rem;font-weight:600;line-height:1.3;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;}
    .ci-pkg{font-size:.73rem;color:var(--muted);font-family:'Inter',sans-serif;}
    .ci-price-row{display:flex;align-items:center;gap:.45rem;flex-wrap:wrap;margin-top:.1rem;}
    .ci-price{font-family:'Cormorant Garamond',serif;font-size:1.3rem;font-weight:700;}
    .ci-disc{background:rgba(245,158,11,.1);color:var(--accent);border:1px solid rgba(245,158,11,.2);font-size:.65rem;font-weight:700;font-family:'Inter',sans-serif;padding:2px 7px;border-radius:5px;letter-spacing:.5px;}

    /* Qty controls */
    .ci-qty-row{display:flex;align-items:center;gap:.75rem;flex-wrap:wrap;margin-top:.35rem;}
    .qty-ctrl{display:flex;align-items:center;border:1.5px solid var(--border);border-radius:10px;overflow:hidden;background:var(--bg);}
    .qty-btn{width:32px;height:32px;border:none;background:transparent;color:var(--ink);font-size:1.05rem;font-weight:700;cursor:pointer;display:flex;align-items:center;justify-content:center;transition:.15s;}
    .qty-btn:hover{background:var(--ink);color:#fff;}
    .qty-val{width:38px;height:32px;border:none;border-left:1px solid var(--border);border-right:1px solid var(--border);text-align:center;background:#fff;font-family:'JetBrains Mono',monospace;font-size:.9rem;font-weight:600;outline:none;}
    .ci-line-total{font-size:.78rem;color:var(--muted);}
    .ci-line-total strong{color:var(--ink);font-weight:700;}
    .stock-err{display:none;font-size:.73rem;color:var(--accent);font-weight:600;align-items:center;gap:.2rem;}
    .stock-err.show{display:flex;}

    /* Item actions */
    .ci-actions{display:flex;gap:.45rem;margin-top:.5rem;flex-wrap:wrap;}
    .ci-btn{display:inline-flex;align-items:center;gap:.3rem;padding:.38rem .8rem;border-radius:8px;font-size:.76rem;font-weight:600;font-family:'Inter',sans-serif;border:none;cursor:pointer;text-decoration:none;transition:.2s;white-space:nowrap;letter-spacing:.2px;}
    .ci-btn.buy{background:var(--ink);color:#fff;}
    .ci-btn.buy:hover{background:var(--accent);color:#fff;}
    .ci-btn.save{background:var(--bg);color:var(--ink2);border:1.5px solid var(--border);}
    .ci-btn.save:hover{border-color:var(--ink);color:var(--ink);}
    .ci-btn.remove{background:transparent;color:var(--accent);border:1.5px solid rgba(245,158,11,.25);}
    .ci-btn.remove:hover{background:rgba(245,158,11,.07);}

    /* ── SAVED FOR LATER ── */
    .saved-section{margin-top:1.75rem;}
    .saved-section-head{display:flex;align-items:center;gap:.65rem;margin-bottom:1rem;padding-bottom:.6rem;border-bottom:1px solid var(--border);}
    .saved-section-title{font-family:'Cormorant Garamond',serif;font-size:1.2rem;font-weight:600;color:var(--ink);}
    .saved-badge{background:var(--gold);color:#fff;font-size:.67rem;font-weight:700;font-family:'Inter',sans-serif;padding:2px 8px;border-radius:20px;letter-spacing:.5px;}
    .saved-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(170px,1fr));gap:.75rem;}
    @media(max-width:500px){.saved-grid{grid-template-columns:repeat(2,1fr);}}

    .saved-card{background:var(--surface);border-radius:12px;border:1px solid var(--border);overflow:hidden;box-shadow:var(--sh);display:flex;flex-direction:column;transition:box-shadow .2s;}
    .saved-card:hover{box-shadow:var(--sh2);}
    .saved-img{height:110px;background:#f8f8fb;display:flex;align-items:center;justify-content:center;padding:.5rem;}
    .saved-img img{max-width:100%;max-height:100%;object-fit:contain;}
    .saved-body{padding:.7rem;flex:1;}
    .saved-name{font-family:'Cormorant Garamond',serif;font-size:.95rem;font-weight:600;line-height:1.3;margin-bottom:.25rem;display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;overflow:hidden;}
    .saved-price{font-family:'Cormorant Garamond',serif;font-size:1.1rem;font-weight:700;color:var(--ink);}
    .saved-foot{padding:.55rem .7rem;border-top:1px solid var(--border);display:flex;gap:.4rem;}
    .saved-btn{flex:1;height:30px;border-radius:7px;border:none;font-family:'Inter',sans-serif;font-size:.71rem;font-weight:600;cursor:pointer;display:flex;align-items:center;justify-content:center;gap:.25rem;transition:.2s;text-decoration:none;letter-spacing:.2px;}
    .saved-btn.move{background:var(--ink);color:#fff;}
    .saved-btn.move:hover{background:var(--accent);color:#fff;}
    .saved-btn.del{background:transparent;border:1.5px solid rgba(245,158,11,.25);color:var(--accent);}
    .saved-btn.del:hover{background:rgba(245,158,11,.07);}

    /* ── ORDER SUMMARY ── */
    .summary-card{background:var(--surface);border-radius:var(--r);border:1px solid var(--border);box-shadow:var(--sh);overflow:hidden;position:sticky;top:calc(var(--nav-h) + 1rem);}
    .sum-head{background:var(--ink);padding:1.25rem 1.5rem;}
    .sum-head-title{font-family:'Cormorant Garamond',serif;font-size:1.2rem;font-weight:700;color:#fff;letter-spacing:.3px;}
    .sum-head-sub{font-size:.73rem;font-family:'Inter',sans-serif;color:rgba(255,255,255,.45);margin-top:2px;}
    .sum-body{padding:1.25rem 1.5rem;}

    .free-del-banner{background:rgba(22,163,74,.08);border:1px solid rgba(22,163,74,.25);border-radius:10px;padding:.55rem .85rem;margin-bottom:1rem;font-size:.8rem;color:var(--green);font-weight:700;display:flex;align-items:center;gap:.4rem;}
    .upgrade-banner{background:rgba(255,165,2,.07);border:1px solid rgba(255,165,2,.2);border-radius:10px;padding:.55rem .85rem;margin-bottom:1rem;font-size:.78rem;color:#b07000;font-weight:600;display:flex;align-items:center;gap:.4rem;}

    /* coupon */
    .coupon-row{display:flex;gap:.5rem;margin-bottom:.85rem;}
    .coupon-input{flex:1;height:38px;border-radius:9px;border:1.5px solid var(--border);padding:0 .85rem;font-family:'Inter',sans-serif;font-size:.82rem;outline:none;transition:.2s;}
    .coupon-input:focus{border-color:var(--ink);}
    .coupon-btn{height:38px;padding:0 1rem;border-radius:9px;border:none;background:var(--ink);color:#fff;font-family:'Inter',sans-serif;font-size:.82rem;font-weight:600;letter-spacing:.3px;cursor:pointer;transition:.2s;}
    .coupon-btn:hover{background:var(--accent);}

    /* rows */
    .sum-row{display:flex;justify-content:space-between;align-items:center;padding:.5rem 0;border-bottom:1px dashed var(--border);}
    .sum-row:last-of-type{border-bottom:none;}
    .sum-label{font-size:.84rem;font-family:'Inter',sans-serif;color:var(--muted);}
    .sum-val{font-size:.86rem;font-weight:600;font-family:'Inter',sans-serif;color:var(--ink);}
    .sum-total{display:flex;justify-content:space-between;align-items:center;padding:.9rem 0 .4rem;border-top:2px solid var(--ink);margin-top:.5rem;}
    .sum-total .sum-label{font-family:'Cormorant Garamond',serif;font-size:1.15rem;font-weight:600;color:var(--ink);}
    .sum-total .sum-val{font-family:'Cormorant Garamond',serif;font-size:1.5rem;font-weight:700;color:var(--ink);}

    .btn-checkout{display:flex;align-items:center;justify-content:center;gap:.5rem;width:100%;height:48px;border-radius:12px;border:none;background:var(--accent);color:#fff;font-family:'Inter',sans-serif;font-size:.9rem;font-weight:700;letter-spacing:.5px;cursor:pointer;text-decoration:none;margin-top:1rem;transition:.2s;}
    .btn-checkout:hover{background:#d97706;color:#fff;transform:translateY(-1px);}
    .btn-checkout.disabled{opacity:.45;pointer-events:none;}
    .btn-continue{display:flex;align-items:center;justify-content:center;gap:.4rem;width:100%;height:40px;border-radius:10px;background:transparent;color:var(--ink2);border:1.5px solid var(--border);font-family:'Inter',sans-serif;font-size:.85rem;font-weight:500;text-decoration:none;margin-top:.55rem;transition:.2s;}
    .btn-continue:hover{border-color:var(--ink);color:var(--ink);}
    .secure-note{text-align:center;font-size:.71rem;font-family:'Inter',sans-serif;color:var(--muted);margin-top:.8rem;display:flex;align-items:center;justify-content:center;gap:.3rem;letter-spacing:.3px;}

    /* ── EMPTY STATE ── */
    .empty-state{grid-column:1/-1;background:var(--surface);border-radius:var(--r);border:1px solid var(--border);padding:4.5rem 2rem;text-align:center;}
    .empty-icon{font-size:4.5rem;margin-bottom:1rem;}
    .empty-title{font-family:'Cormorant Garamond',serif;font-size:1.6rem;font-weight:700;margin-bottom:.45rem;}
    .empty-sub{color:var(--muted);font-size:.86rem;font-family:'Inter',sans-serif;margin-bottom:1.5rem;}
    .btn-shop{display:inline-flex;align-items:center;gap:.5rem;background:var(--ink);color:#fff;padding:.75rem 1.75rem;border-radius:12px;font-family:'Inter',sans-serif;font-weight:600;letter-spacing:.3px;text-decoration:none;transition:.2s;}
    .btn-shop:hover{background:var(--accent);color:#fff;}

    /* ── TOAST ── */
    .toast-hub{position:fixed;bottom:1.5rem;right:1rem;z-index:2000;display:flex;flex-direction:column;gap:.5rem;}
    .toast-msg{background:var(--ink);color:#fff;border-radius:12px;padding:.7rem 1rem;font-size:.82rem;font-weight:500;font-family:'Inter',sans-serif;box-shadow:var(--sh2);display:flex;align-items:center;gap:.45rem;animation:slideUp .3s ease;max-width:280px;}
    @keyframes slideUp{from{opacity:0;transform:translateY(12px);}to{opacity:1;transform:translateY(0);}}

    @media(max-width:500px){
      .ci-inner{flex-direction:column;}
      .ci-img{width:100%;height:150px;border-right:none;border-bottom:1px solid var(--border);}
      .ci-img img{height:130px;}
    }

    /* ── MOBILE STICKY CHECKOUT BAR ── */
    .mobile-checkout-bar{
      display:none;
      position:fixed;bottom:0;left:0;right:0;z-index:800;
      background:var(--surface);border-top:1px solid var(--border);
      padding:.75rem 1rem;
      box-shadow:0 -4px 20px rgba(26,60,52,.12);
    }
    .mobile-checkout-bar .mcb-total{font-family:'Cormorant Garamond',serif;font-size:1.1rem;font-weight:700;color:var(--ink);}
    .mobile-checkout-bar .mcb-items{font-size:.72rem;color:var(--muted);}
    .mobile-checkout-bar .mcb-btn{
      display:flex;align-items:center;justify-content:center;gap:.4rem;
      background:var(--accent);color:#fff;border:none;border-radius:10px;
      font-family:'Inter',sans-serif;font-size:.9rem;font-weight:700;
      padding:.65rem 1.25rem;white-space:nowrap;text-decoration:none;cursor:pointer;
    }

    @media(max-width:860px){
      /* On mobile the summary card moves to below the items — no sticky needed there */
      .summary-card{position:static;}
      /* Give bottom padding so sticky bar doesn't cover content */
      .page{padding-bottom:6rem;}
      .mobile-checkout-bar{display:flex;align-items:center;justify-content:space-between;gap:.75rem;}
    }
    @media(max-width:560px){
      .page{padding:1rem .75rem 6rem;}
      .page-title{font-size:1.45rem;}
      .ci-name{font-size:1rem;}
      .ci-price{font-size:1.1rem;}
      .ci-actions{gap:.3rem;}
      .ci-btn{padding:.3rem .6rem;font-size:.7rem;}
      /* Hide save-for-later on very small screens to reduce clutter */
      .ci-btn.save{display:none;}
      .del-progress{padding:.75rem 1rem;}
    }
  </style>
</head>
<body>

<!-- NAV -->
<nav class="nav">
  <a href="Customer" class="nav-brand">SIBS<em>.</em></a>
  <a href="Customer" class="nav-back"><i class="bi bi-arrow-left"></i> Continue Shopping</a>
  <div class="nav-right">
    <a href="WishlistServlet" class="nav-icon" title="Wishlist"><i class="bi bi-heart"></i></a>
    <div class="nav-avatar"><%= initials %></div>
  </div>
</nav>

<div class="page">

  <!-- PAGE HEADER -->
  <div class="page-head">
    <div class="page-title">My Cart</div>
    <% if (hasItems && totalProducts != null && totalProducts > 0) { %>
    <div class="cart-badge"><%= totalProducts %> item<%= totalProducts != 1 ? "s" : "" %></div>
    <% } %>
  </div>

  <!-- FREE DELIVERY PROGRESS -->
  <% if (hasItems) {
      double freeAt = 499.0;
      double needed = Math.max(0, freeAt - subD);
      double pct    = Math.min(100.0, (subD / freeAt) * 100.0);
  %>
  <div class="del-progress">
    <div class="del-progress-label">
      <span><i class="bi bi-truck"></i> Free Delivery Progress</span>
      <span style="color:var(--green);font-size:.78rem;">₹<%= String.format("%.0f", subD) %> / ₹<%= String.format("%.0f", freeAt) %></span>
    </div>
    <div class="del-bar"><div class="del-bar-fill" style="width:<%= String.format("%.1f", pct) %>%;"></div></div>
    <div class="del-tip">
      <% if (needed > 0) { %>Add <strong>₹<%= String.format("%.0f", needed) %></strong> more to unlock free delivery!
      <% } else { %>🎉 <strong>You've unlocked FREE delivery!</strong><% } %>
    </div>
  </div>
  <% } %>

  <div class="cart-layout">

    <% if (!hasItems) { %>
    <!-- EMPTY STATE -->
    <div class="empty-state">
      <div class="empty-icon">🛒</div>
      <div class="empty-title">Your cart is empty</div>
      <div class="empty-sub">Looks like you haven't added anything yet.<br>Explore fresh products and great deals!</div>
      <a href="Customer" class="btn-shop"><i class="bi bi-bag-heart-fill"></i> Start Shopping</a>
    </div>

    <% } else { %>

    <!-- LEFT: CART ITEMS -->
    <div>
      <% for (CartItem item : cartItems) {
          double lineTotal = item.getFinalPrice() * item.getQuantity();
      %>
      <div class="ci-card">
        <div class="ci-inner">
          <!-- Image -->
          <div class="ci-img">
            <img src="<%= item.getImageUrl() != null && !item.getImageUrl().isEmpty()
                          ? item.getImageUrl() : "images/default.png" %>"
                 alt="<%= item.getName() %>"
                 onerror="this.src='images/default.png'">
          </div>
          <!-- Body -->
          <div class="ci-body">
            <div class="ci-cat"><%= item.getCategory() != null && !item.getCategory().isEmpty() ? item.getCategory().replace("_"," ").toUpperCase() : "PRODUCT" %></div>
            <div class="ci-name" title="<%= item.getName() %>"><%= item.getName() %></div>
            <div class="ci-pkg"><i class="bi bi-basket2"></i> <%= item.getProductQuantity() %> <%= item.getUnit() %></div>

            <div class="ci-price-row">
              <span class="ci-price">₹<%= String.format("%.2f", item.getFinalPrice()) %></span>
              <% if (item.getDiscount() > 0) { %>
              <span class="ci-disc"><%= (int)item.getDiscount() %>% OFF</span>
              <% } %>
              <%-- GST FIX: per-product GST slab badge --%>
              <span style="background:rgba(8,145,178,.08);color:#0891b2;border:1px solid rgba(8,145,178,.2);font-size:.63rem;font-weight:700;font-family:'Inter',sans-serif;padding:2px 7px;border-radius:5px;letter-spacing:.4px;" title="GST slab for this product">GST <%= (int)item.getGstRate() %>%</span>
            </div>

            <!-- Quantity controls -->
            <div class="ci-qty-row">
              <div class="qty-ctrl">
                <button class="qty-btn" onclick="changeQty(<%= item.getCartId() %>, -1, <%= item.getStock() %>, <%= item.getFinalPrice() %>)">−</button>
                <input class="qty-val" id="qty-<%= item.getCartId() %>" type="text"
                       value="<%= item.getQuantity() %>" readonly>
                <button class="qty-btn" onclick="changeQty(<%= item.getCartId() %>, +1, <%= item.getStock() %>, <%= item.getFinalPrice() %>)">+</button>
              </div>
              <%-- GST FIX: per-line GST amount --%>
              <% double lineGst = item.getFinalPrice() * item.getQuantity() * (item.getGstRate() / 100.0); %>
              <span class="ci-line-total" id="lineTotal-<%= item.getCartId() %>" data-gst-rate="<%= item.getGstRate() %>">
                Total: <strong>₹<%= String.format("%.2f", lineTotal) %></strong>
                &nbsp;<span style="font-size:.68rem;color:#0891b2;" title="GST for this item">
                  +₹<span id="lineGst-<%= item.getCartId() %>"><%= String.format("%.2f", lineGst) %></span> GST
                </span>
              </span>
              <span class="stock-err" id="stockErr-<%= item.getCartId() %>">
                <i class="bi bi-exclamation-circle"></i> Max <%= item.getStock() %>
              </span>
            </div>

            <!-- Actions -->
            <div class="ci-actions">
              <!-- Buy Now -->
              <form action="BuyNow" method="post" style="display:contents;">
                <input type="hidden" name="productId" value="<%= item.getProductId() %>">
                <input type="hidden" name="quantity" id="buyQty-<%= item.getCartId() %>" value="<%= item.getQuantity() %>">
                <button type="submit" class="ci-btn buy"><i class="bi bi-lightning-fill"></i> Buy Now</button>
              </form>
              <!-- Save for Later -->
              <a href="CartServlet?action=saveForLater&cartId=<%= item.getCartId() %>" class="ci-btn save">
                <i class="bi bi-bookmark-plus"></i> Save for Later
              </a>
              <!-- Remove -->
              <a href="CartServlet?action=remove&cartId=<%= item.getCartId() %>" class="ci-btn remove"
                 onclick="return confirm('Remove this item from cart?')">
                <i class="bi bi-trash3"></i> Remove
              </a>
            </div>
          </div>
        </div>
      </div>
      <% } %>

      <!-- SAVED FOR LATER SECTION -->
      <% if (hasSaved) { %>
      <div class="saved-section">
        <div class="saved-section-head">
          <div class="saved-section-title">Saved for Later</div>
          <div class="saved-badge"><%= savedItems.size() %> item<%= savedItems.size() != 1 ? "s" : "" %></div>
        </div>
        <div class="saved-grid">
          <% for (CartItem s : savedItems) { %>
          <div class="saved-card">
            <div class="saved-img">
              <img src="<%= s.getImageUrl() != null && !s.getImageUrl().isEmpty()
                            ? s.getImageUrl() : "images/default.png" %>"
                   alt="<%= s.getName() %>"
                   onerror="this.src='images/default.png'">
            </div>
            <div class="saved-body">
              <div class="saved-name"><%= s.getName() %></div>
              <div style="font-size:.72rem;color:var(--muted);margin-bottom:.2rem;"><%= s.getProductQuantity() %> <%= s.getUnit() %></div>
              <div class="saved-price">₹<%= String.format("%.2f", s.getFinalPrice()) %></div>
            </div>
            <div class="saved-foot">
              <a href="CartServlet?action=moveToCart&cartId=<%= s.getCartId() %>"
                 class="saved-btn move" title="Move to Cart">
                <i class="bi bi-cart-plus"></i> Add to Cart
              </a>
              <a href="CartServlet?action=remove&cartId=<%= s.getCartId() %>"
                 class="saved-btn del" title="Remove"
                 onclick="return confirm('Remove from saved items?')">
                <i class="bi bi-trash3"></i>
              </a>
            </div>
          </div>
          <% } %>
        </div>
      </div>
      <% } %>
    </div>

    <!-- RIGHT: ORDER SUMMARY -->
    <div>
      <div class="summary-card">
        <div class="sum-head">
          <div class="sum-head-title">Order Summary</div>
          <div class="sum-head-sub"><%= totalProducts != null ? totalProducts : 0 %> item<%= (totalProducts != null && totalProducts != 1) ? "s" : "" %> · Ready to checkout</div>
        </div>
        <div class="sum-body">

          <!-- Free delivery banner -->
          <% if (subD >= 499) { %>
          <div class="free-del-banner"><i class="bi bi-truck-front-fill"></i> Free delivery unlocked!</div>
          <% } else { %>
          <div class="upgrade-banner"><i class="bi bi-info-circle"></i> Add ₹<%= String.format("%.0f", 499 - subD) %> more for free delivery</div>
          <% } %>

          <!-- Coupon -->
          <div class="coupon-row">
            <input class="coupon-input" id="couponCode" type="text" placeholder="Promo / Coupon code">
            <button class="coupon-btn" onclick="applyCoupon()">Apply</button>
          </div>

          <!-- Price breakdown -->
          <div class="sum-row">
            <span class="sum-label">Subtotal (<%= totalProducts %> items)</span>
            <span class="sum-val" id="sumSubtotal">₹<%= subtotal %></span>
          </div>
          <%-- GST FIX: label corrected; phantom Platform Tax row removed --%>
          <div class="sum-row">
            <span class="sum-label">GST
              <span style="font-size:.70rem;color:var(--muted);" title="Each product has its own GST slab (0%,5%,12%,18%,28%). This is the sum of all per-product GST amounts.">
                (per product) <i class="bi bi-info-circle" style="cursor:help;font-size:.68rem;"></i>
              </span>
            </span>
            <span class="sum-val" id="sumGst">₹<%= gst %></span>
          </div>
          <%-- GST FIX: Platform Tax (5%) removed — no such charge exists in India --%>
          <div class="sum-row">
            <span class="sum-label">Delivery</span>
            <span class="sum-val" style="color:var(--green);">
              <%= subD >= 499 ? "FREE" : "₹40" %>
            </span>
          </div>

          <div class="sum-total">
            <span class="sum-label">Grand Total</span>
            <%-- GST FIX: grandTotal from CartServlet already includes delivery charge --%>
          <% double displayTotal = 0;
             try { if (grandTotal != null) displayTotal = Double.parseDouble(grandTotal); } catch(Exception ignored){}
          %>
          <span class="sum-val" id="sumGrandTotal">₹<%= String.format("%.2f", displayTotal) %></span>
          </div>

          <a href="Checkout" class="btn-checkout"><i class="bi bi-credit-card-fill"></i> Proceed to Checkout</a>
          <a href="Customer" class="btn-continue"><i class="bi bi-arrow-left"></i> Continue Shopping</a>
          <div class="secure-note"><i class="bi bi-shield-lock-fill" style="color:var(--green);"></i> 100% Secure & Encrypted</div>
        </div>
      </div>
    </div>

    <% } /* end hasItems */ %>
  </div><!-- /cart-layout -->
</div><!-- /page -->

<% if (hasItems) { %>
<div class="mobile-checkout-bar">
  <div>
    <div class="mcb-total">₹<span id="mcbTotal"><%= grandTotal %></span></div>
    <div class="mcb-items"><%= totalProducts != null ? totalProducts : 0 %> item<%= (totalProducts != null && totalProducts != 1) ? "s" : "" %> · incl. taxes</div>
  </div>
  <a href="Checkout" class="mcb-btn"><i class="bi bi-credit-card-fill"></i> Checkout</a>
</div>
<% } %>

<div class="toast-hub" id="toastHub"></div>

<script>
function toast(msg, bg) {
  const hub = document.getElementById('toastHub');
  const el = document.createElement('div');
  el.className = 'toast-msg';
  if (bg) el.style.background = bg;
  el.innerHTML = msg;
  hub.appendChild(el);
  setTimeout(() => { el.style.opacity = '0'; el.style.transition = 'opacity .3s'; }, 2800);
  setTimeout(() => el.remove(), 3200);
}

function changeQty(cartId, delta, maxStock, unitPrice) {
  const qtyEl   = document.getElementById('qty-' + cartId);
  const errEl   = document.getElementById('stockErr-' + cartId);
  const totalEl = document.getElementById('lineTotal-' + cartId);
  const buyEl   = document.getElementById('buyQty-' + cartId);
  let qty = parseInt(qtyEl.value) + delta;
  if (qty < 1) return;
  if (qty > maxStock) { errEl.classList.add('show'); return; }
  errEl.classList.remove('show');

  fetch('CartServlet?action=update&cartId=' + cartId + '&quantity=' + qty)
    .then(r => r.json())
    .then(data => {
      qtyEl.value = qty;
      if (buyEl) buyEl.value = qty;
      const lt = (unitPrice * qty).toFixed(2);
      // GST FIX: live-update per-line GST amount shown next to line total
      if (totalEl) {
        const gstRate = parseFloat(totalEl.getAttribute('data-gst-rate') || 0);
        const lineGst = (unitPrice * qty * gstRate / 100).toFixed(2);
        totalEl.innerHTML = 'Total: <strong>₹' + lt + '</strong>'
          + '&nbsp;<span style="font-size:.68rem;color:#0891b2;" title="GST for this item">'
          + '+₹<span id="lineGst-' + cartId + '">' + lineGst + '</span> GST</span>';
      }
      if (document.getElementById('sumSubtotal'))  document.getElementById('sumSubtotal').textContent  = '₹' + data.subtotal;
      if (document.getElementById('sumGst'))       document.getElementById('sumGst').textContent       = '₹' + data.gst;
      if (document.getElementById('sumTax'))       document.getElementById('sumTax').textContent       = '₹' + data.tax;
      if (document.getElementById('sumGrandTotal'))document.getElementById('sumGrandTotal').textContent= '₹' + data.grandTotal;
      if (document.getElementById('mcbTotal'))     document.getElementById('mcbTotal').textContent     = data.grandTotal;
      toast('<i class="bi bi-check-circle-fill"></i> Quantity updated', '#16a34a');
    })
    .catch(() => toast('<i class="bi bi-x-circle-fill"></i> Update failed', '#f59e0b'));
}

function applyCoupon() {
  const code = document.getElementById('couponCode').value.trim();
  if (!code) { toast('<i class="bi bi-info-circle"></i> Please enter a coupon code', '#f59e0b'); return; }
  toast('<i class="bi bi-x-circle"></i> "' + code + '" is invalid or expired', '#f59e0b');
}
</script>

<jsp:include page="customerBottomNav.jsp"><jsp:param name="activePage" value="cart"/></jsp:include>
</body>
</html>
