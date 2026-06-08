<%@ page contentType="text/html; charset=UTF-8" %>
<%@ page import="com.util.Product" %>
<%
    Product product  = (Product) request.getAttribute("product");
    Boolean loggedIn = (Boolean) session.getAttribute("loggedIn");

    if (product == null) {
%>
<div style="text-align:center;padding:3rem 1.5rem;">
  <div style="font-size:3rem;margin-bottom:.75rem;">😕</div>
  <div style="font-family:'Syne',sans-serif;font-size:1rem;font-weight:800;color:#0d0d14;margin-bottom:.35rem;">Product not found</div>
  <div style="font-size:.84rem;color:#868699;">Please try again or browse other products.</div>
</div>
<% return; }

    int    stock     = product.getStock();
    double mrp       = product.getMrp();
    double fp        = product.getFinalPrice();
    double disc      = product.getDiscount();
    double saved     = mrp - fp;
    boolean oos      = (stock == 0);
    boolean low      = (stock > 0 && stock <= 10);
    int    maxQty    = Math.min(stock, 10);
    double rating    = 3.5 + (product.getId() % 15) * 0.1;
    if (rating > 5.0) rating = 5.0;
    int   ratingCnt  = 40 + (product.getId() % 960);
    int   fullStars  = (int) rating;
    boolean half     = (rating - fullStars) >= 0.3;
    String cat       = product.getCategory() != null
                       ? product.getCategory().replace("_"," ").toUpperCase() : "PRODUCT";
    String desc      = (product.getDescription() != null && !product.getDescription().isEmpty())
                       ? product.getDescription()
                       : "Fresh and quality assured. Sourced directly for the best experience.";
    String img       = (product.getImageUrl() != null && !product.getImageUrl().isEmpty())
                       ? product.getImageUrl() : "images/default.png";
%>
<style>
/* Quick-view sheet — inherits Syne + Nunito from parent page */
.qv{display:grid;grid-template-columns:1fr 1fr;min-height:320px;}
@media(max-width:560px){
  .qv{ grid-template-columns:1fr; }
  .qv-detail { padding: 1rem 1rem .9rem; }
  .qv-name { font-size: 1.1rem !important; }
  .qv-price { font-size: 1.5rem !important; }
  /* Full width action buttons */
  .qv-actions { grid-template-columns: 1fr 1fr !important; }
  .qv-btn { height: 40px; font-size: .8rem; }
}

/* ── Image panel ── */
.qv-img-panel{background:#f8f8fb;display:flex;align-items:center;justify-content:center;
  padding:1.25rem;position:relative;overflow:hidden;border-right:1px solid #e8e8f0;min-height:260px;}
@media(max-width:560px){.qv-img-panel{min-height:190px;border-right:none;border-bottom:1px solid #e8e8f0;padding:.75rem;}}
.qv-img-panel img{max-width:100%;max-height:230px;object-fit:contain;transition:transform .4s;}
.qv-img-panel:hover img{transform:scale(1.06);}

.qv-disc-tag{position:absolute;top:.75rem;left:.75rem;background:#ff4757;color:#fff;
  font-family:'Syne',sans-serif;font-size:.68rem;font-weight:800;padding:3px 9px;border-radius:6px;}
.qv-badge-new{position:absolute;top:.75rem;right:.75rem;background:#1e90ff;color:#fff;
  font-size:.68rem;font-weight:800;padding:3px 9px;border-radius:6px;}
.qv-oos-veil{position:absolute;inset:0;background:rgba(245,245,248,.72);backdrop-filter:blur(2px);
  display:flex;align-items:center;justify-content:center;}
.qv-oos-label{background:#868699;color:#fff;font-family:'Syne',sans-serif;
  font-size:.8rem;font-weight:800;padding:.35rem 1rem;border-radius:8px;}

/* ── Detail panel ── */
.qv-detail{padding:1.25rem 1.35rem 1.1rem;display:flex;flex-direction:column;
  gap:.7rem;overflow-y:auto;max-height:72vh;}

.qv-cat{font-size:.67rem;text-transform:uppercase;letter-spacing:.6px;color:#868699;font-weight:700;}
.qv-name{font-family:'Syne',sans-serif;font-size:1.15rem;font-weight:800;color:#0d0d14;line-height:1.3;}

/* Rating */
.qv-rating{display:flex;align-items:center;gap:.35rem;}
.qv-stars{display:flex;gap:1px;}
.qv-star{font-size:.85rem;color:#ffa502;}
.qv-star.e{color:#e8e8f0;}
.qv-star.h{color:#ffa502;opacity:.5;}
.qv-rating-meta{font-size:.76rem;color:#868699;}
.qv-rating-meta b{color:#0d0d14;}

/* Price block */
.qv-price-block{background:linear-gradient(135deg,#f5f5f8,#eff0f8);border-radius:12px;
  padding:.85rem 1rem;border:1px solid #e8e8f0;}
.qv-price{font-family:'Syne',sans-serif;font-size:1.75rem;font-weight:800;color:#0d0d14;line-height:1;}
.qv-price-sub{display:flex;align-items:center;gap:.5rem;margin-top:.3rem;flex-wrap:wrap;}
.qv-mrp{font-size:.83rem;text-decoration:line-through;color:#868699;}
.qv-off{background:rgba(46,213,115,.12);color:#18a057;border:1px solid rgba(46,213,115,.25);
  font-size:.7rem;font-weight:800;padding:2px 8px;border-radius:6px;}
.qv-saving{font-size:.73rem;color:#868699;margin-top:.2rem;}

/* Pills row */
.qv-pills{display:flex;gap:.45rem;flex-wrap:wrap;}
.qv-pill{display:inline-flex;align-items:center;gap:.3rem;background:#f5f5f8;border:1px solid #e8e8f0;
  border-radius:8px;padding:.33rem .75rem;font-size:.77rem;color:#3a3a4e;font-weight:600;}
.qv-pill i{font-size:.8rem;color:#0d0d14;}
.stock-ok {background:rgba(46,213,115,.08);color:#18a057;border:1px solid rgba(46,213,115,.22);}
.stock-low{background:rgba(255,165,2,.08);color:#b07000;border:1px solid rgba(255,165,2,.22);}
.stock-out{background:#f5f5f8;color:#868699;border:1px solid #e8e8f0;}

/* Description */
.qv-desc{font-size:.83rem;color:#868699;line-height:1.7;background:#f5f5f8;border-radius:10px;
  padding:.7rem .9rem;border-left:3px solid #0d0d14;}

/* Delivery */
.qv-delivery{background:rgba(46,213,115,.05);border:1px solid rgba(46,213,115,.2);border-radius:10px;
  padding:.7rem .9rem;display:flex;flex-direction:column;gap:.35rem;}
.qv-del-row{display:flex;align-items:center;gap:.4rem;font-size:.79rem;color:#3a3a4e;}
.qv-del-row i{color:#2ed573;font-size:.85rem;}
.qv-del-row b{color:#18a057;}

/* Quantity selector */
.qv-qty-wrap{display:flex;align-items:center;gap:.8rem;flex-wrap:wrap;}
.qv-qty-label{font-size:.82rem;font-weight:700;color:#3a3a4e;}
.qv-qty-ctrl{display:flex;align-items:center;border:1.5px solid #e8e8f0;border-radius:10px;overflow:hidden;background:#f5f5f8;}
.qv-qbtn{width:34px;height:34px;border:none;background:transparent;color:#0d0d14;font-size:1.1rem;font-weight:700;cursor:pointer;display:flex;align-items:center;justify-content:center;transition:.15s;}
.qv-qbtn:hover{background:#0d0d14;color:#fff;}
.qv-qval{width:40px;height:34px;border:none;border-left:1px solid #e8e8f0;border-right:1px solid #e8e8f0;text-align:center;background:#fff;font-family:'Syne',sans-serif;font-size:.9rem;font-weight:800;color:#0d0d14;outline:none;}
.qv-qty-max{font-size:.71rem;color:#868699;}

/* Action grid */
.qv-actions{display:grid;grid-template-columns:1fr 1fr;gap:.5rem;}
.qv-actions.solo{grid-template-columns:1fr;}
.qv-btn{height:44px;border-radius:12px;border:none;cursor:pointer;font-family:'Nunito',sans-serif;
  font-size:.88rem;font-weight:800;display:flex;align-items:center;justify-content:center;
  gap:.4rem;text-decoration:none;transition:all .2s;}
.qv-btn.cart{background:#0d0d14;color:#fff;}
.qv-btn.cart:hover{background:#ff4757;color:#fff;transform:translateY(-1px);}
.qv-btn.buy{background:#ff4757;color:#fff;}
.qv-btn.buy:hover{background:#e8384a;color:#fff;transform:translateY(-1px);}
.qv-btn.ghost{background:transparent;color:#3a3a4e;border:1.5px solid #e8e8f0;}
.qv-btn.ghost:hover{border-color:#0d0d14;background:#f5f5f8;}
.qv-btn.disabled{opacity:.45;pointer-events:none;}

/* Secondary icon row */
.qv-icon-row{display:flex;gap:.45rem;}
.qv-icon-btn{width:40px;height:40px;border-radius:10px;border:1.5px solid #e8e8f0;background:transparent;
  color:#3a3a4e;cursor:pointer;display:flex;align-items:center;justify-content:center;
  font-size:.95rem;transition:.2s;text-decoration:none;}
.qv-icon-btn:hover{background:#0d0d14;color:#fff;border-color:#0d0d14;}
.qv-icon-btn.wished{color:#ff4757;border-color:rgba(255,71,87,.3);background:rgba(255,71,87,.06);}
</style>

<div class="qv">
  <!-- ── Image Panel ── -->
  <div class="qv-img-panel">
    <% if (disc > 0)  { %><div class="qv-disc-tag"><%= (int)disc %>% OFF</div><% } %>
    <% if (oos)       { %><div class="qv-oos-veil"><div class="qv-oos-label">Out of Stock</div></div><% } %>
    <img src="<%= img %>" alt="<%= product.getName() %>" onerror="this.src='images/default.png'">
  </div>

  <!-- ── Detail Panel ── -->
  <div class="qv-detail">
    <div class="qv-cat"><%= cat %></div>
    <h3 class="qv-name"><%= product.getName() %></h3>

    <!-- Rating -->
    <div class="qv-rating">
      <div class="qv-stars">
        <% for (int i = 1; i <= 5; i++) { %>
          <% if (i <= fullStars) { %><span class="qv-star">★</span>
          <% } else if (i == fullStars + 1 && half) { %><span class="qv-star h">★</span>
          <% } else { %><span class="qv-star e">★</span><% } %>
        <% } %>
      </div>
      <span class="qv-rating-meta"><b><%= String.format("%.1f", rating) %></b> · <%= ratingCnt %> reviews</span>
    </div>

    <!-- Price -->
    <div class="qv-price-block">
      <div class="qv-price">₹<%= String.format("%.0f", fp) %></div>
      <% if (disc > 0) 
      { %>
      <div class="qv-price-sub">
        <span class="qv-mrp">MRP ₹<%= String.format("%.0f", mrp) %></span>
        <span class="qv-off"><%= (int)disc %>% OFF</span>
      </div>
      <div class="qv-saving">You save ₹<%= String.format("%.0f", saved) %> on this item</div>
      <% } %>
    </div>

    <!-- Info pills -->
    <div class="qv-pills">
      <span class="qv-pill"><i class="bi bi-basket2"></i> <%= product.getQuantity() %> <%= product.getUnit() %></span>
      <% if (oos) { %><span class="qv-pill stock-out"><i class="bi bi-x-circle"></i> Out of Stock</span>
      <% } else if (low) { %><span class="qv-pill stock-low"><i class="bi bi-exclamation-triangle"></i> Only <%= stock %> left!</span>
      <% } else { %><span class="qv-pill stock-ok"><i class="bi bi-check-circle"></i> In Stock</span><% } %>
    </div>

    <!-- Description -->
    <div class="qv-desc"><%= desc %></div>

    <!-- Delivery -->
    <div class="qv-delivery">
      <div class="qv-del-row"><i class="bi bi-truck-front-fill"></i> <b>Free Delivery</b> on orders above ₹499</div>
      <div class="qv-del-row"><i class="bi bi-lightning-fill"></i> Express delivery — order before <b>2 PM</b></div>
      <div class="qv-del-row"><i class="bi bi-arrow-return-left"></i> <b>7-day hassle-free</b> returns</div>
    </div>

    <!-- Qty selector -->
    <% if (!oos) { %>
    <div class="qv-qty-wrap">
      <span class="qv-qty-label">Qty:</span>
      <div class="qv-qty-ctrl">
        <button class="qv-qbtn" id="qvMinus">−</button>
        <input class="qv-qval" id="qvQty" type="number" value="1" min="1" max="<%= maxQty %>" readonly>
        <button class="qv-qbtn" id="qvPlus">+</button>
      </div>
      <span class="qv-qty-max">Max <%= maxQty %></span>
    </div>
    <% } %>

    <!-- Action buttons -->
    <% if (Boolean.TRUE.equals(loggedIn)) { %>
      <% if (!oos) { %>
      <div class="qv-actions">
        <a href="CartServlet?action=add&id=<%= product.getId() %>"
           class="qv-btn cart" id="qvCartBtn">
          <i class="bi bi-cart-plus"></i> Add to Cart
        </a>
        <button class="qv-btn buy" onclick="qvBuyNow()">
          <i class="bi bi-bag-check-fill"></i> Buy Now
        </button>
      </div>
      <div class="qv-icon-row">
        <button class="qv-icon-btn" id="qvWishBtn"
                onclick="qvToggleWish(<%= product.getId() %>)"
                title="Add to Wishlist">
          <i class="bi bi-heart" id="qvWishIcon"></i>
        </button>
        <button class="qv-icon-btn" onclick="qvShare('<%= product.getName().replace("'","").replace("\"","") %>')"
                title="Share">
          <i class="bi bi-share"></i>
        </button>
        <a href="ProductServlet?action=filter&category=<%= product.getCategory() != null ? product.getCategory() : "" %>"
           class="qv-icon-btn" title="View similar">
          <i class="bi bi-grid-3x3-gap"></i>
        </a>
      </div>
      <% } else { %>
      <!-- OOS -->
      <div class="qv-actions">
        <button class="qv-btn cart disabled" disabled>
          <i class="bi bi-x-circle"></i> Out of Stock
        </button>
        <button class="qv-icon-btn" onclick="qvToggleWish(<%= product.getId() %>)"
                title="Add to wishlist — get notified" id="qvWishBtn" style="width:auto;padding:0 1rem;border-radius:12px;">
          <i class="bi bi-bell" id="qvWishIcon"></i>&nbsp; Notify Me
        </button>
      </div>
      <% } %>
    <% } else { %>
      <div class="qv-actions solo">
        <a href="CustomerLogin.jsp" class="qv-btn cart">
          <i class="bi bi-box-arrow-in-right"></i> Login to Buy
        </a>
      </div>
    <% } %>
  </div><!-- /qv-detail -->
</div><!-- /qv -->

<!-- Hidden buy-now form -->
<form id="qvBuyForm" action="BuyNow" method="post" style="display:none;">
  <input type="hidden" name="productId" value="<%= product.getId() %>">
  <input type="hidden" name="quantity"  id="qvBuyQty" value="1">
</form>

<script>
(function() {
  const minus = document.getElementById('qvMinus');
  const plus  = document.getElementById('qvPlus');
  const inp   = document.getElementById('qvQty');
  if (!minus || !plus || !inp) return;
  const maxQ = parseInt(inp.max) || 10;

  function syncLinks() {
    const v = parseInt(inp.value);
    const cartBtn = document.getElementById('qvCartBtn');
    const buyQ    = document.getElementById('qvBuyQty');
    if (cartBtn) cartBtn.href = 'CartServlet?action=add&id=<%= product.getId() %>&qty=' + v;
    if (buyQ)    buyQ.value   = v;
  }

  minus.addEventListener('click', () => {
    let v = parseInt(inp.value);
    if (v > 1) { inp.value = v - 1; syncLinks(); }
  });
  plus.addEventListener('click', () => {
    let v = parseInt(inp.value);
    if (v < maxQ) { inp.value = v + 1; syncLinks(); }
    else {
      // Flash max indicator
      inp.style.borderColor = '#ff4757';
      setTimeout(() => inp.style.borderColor = '', 800);
    }
  });
})();

function qvBuyNow() {
  const buyQ = document.getElementById('qvBuyQty');
  const qtyI = document.getElementById('qvQty');
  if (buyQ && qtyI) buyQ.value = qtyI.value;
  document.getElementById('qvBuyForm').submit();
}
// Explicitly attach to window so inline onclick="qvBuyNow()" always resolves,
// even when this script runs inside a re-executed fragment (innerHTML injection).
window.qvBuyNow = qvBuyNow;

function qvToggleWish(productId) {
  const btn  = document.getElementById('qvWishBtn');
  const icon = document.getElementById('qvWishIcon');
  if (!btn || !icon) return;

  fetch('WishlistServlet?action=toggle&id=' + productId, {
    headers: { 'X-Requested-With': 'XMLHttpRequest' }
  })
  .then(r => r.json())
  .then(data => {
    if (data.wished) {
      icon.className = 'bi bi-heart-fill';
      btn.classList.add('wished');
      btn.title = 'Remove from Wishlist';
      if (typeof toast === 'function') toast('<i class="bi bi-heart-fill"></i> Added to Wishlist!', '#ff4757');
    } else {
      icon.className = 'bi bi-heart';
      btn.classList.remove('wished');
      btn.title = 'Add to Wishlist';
      if (typeof toast === 'function') toast('<i class="bi bi-heart"></i> Removed from Wishlist', '#868699');
    }
  })
  .catch(() => {
    if (typeof toast === 'function') toast('<i class="bi bi-exclamation-circle"></i> Action failed', '#ff4757');
  });
}
window.qvToggleWish = qvToggleWish;

function qvShare(name) {
  if (navigator.share) {
    navigator.share({ title: name, text: 'Check out ' + name + ' on SIBS Store!', url: window.location.href });
  } else {
    navigator.clipboard.writeText(window.location.href)
      .then(() => { if (typeof toast === 'function') toast('<i class="bi bi-check-circle"></i> Link copied!', '#2ed573'); });
  }
}
window.qvShare = qvShare;
</script>
