<%@ page import="java.util.List" %>
<%@ page import="com.util.Product" %>
<%@ page import="com.util.Customer" %>
<%@ page contentType="text/html; charset=UTF-8" %>
<%
    Customer customer = (Customer) session.getAttribute("customer");
    if (customer == null) { response.sendRedirect("CustomerLogin.jsp?error=Please login first."); return; }
    List<Product> wishlist = (List<Product>) request.getAttribute("wishlist");
    boolean hasItems = wishlist != null && !wishlist.isEmpty();
    String initials = customer.getName() != null && !customer.getName().isEmpty()
        ? String.valueOf(customer.getName().charAt(0)).toUpperCase() : "U";
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>My Wishlist — SIBS Store</title>
  <link href="https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,400;0,600;0,700;1,400;1,600&family=Inter:wght@300;400;500;600;700&family=JetBrains+Mono:wght@400;600;700&display=swap" rel="stylesheet">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
  <style>
    :root {
      --ink:#1a3c34; --ink2:#3d5a52; --muted:#78716c;
      --bg:#faf7f2; --surface:#fff; --border:#e8e2d9;
      --accent:#f59e0b; --red:#e11d48; --green:#16a34a; --gold:#f59e0b;
      --nav-h:64px; --r:16px;
      --sh:0 2px 16px rgba(26,60,52,.07); --sh2:0 8px 32px rgba(26,60,52,.14);
    }
    *,*::before,*::after{box-sizing:border-box;margin:0;padding:0;}
    body{font-family:'Inter',sans-serif;background:var(--bg);color:var(--ink);padding-top:var(--nav-h);min-height:100vh;}

    /* ── NAV ── */
    .nav{position:fixed;top:0;left:0;right:0;z-index:900;height:var(--nav-h);background:var(--ink);display:flex;align-items:center;padding:0 1.25rem;gap:.75rem;box-shadow:0 2px 20px rgba(0,0,0,.3);}
    .nav-brand{font-family:'Cormorant Garamond',serif;font-size:1.65rem;font-weight:700;color:#fff;text-decoration:none;letter-spacing:.5px;font-style:italic;}
    .nav-brand em{color:var(--accent);font-style:normal;}
    .nav-back{display:flex;align-items:center;gap:.4rem;background:rgba(255,255,255,.09);border:1px solid rgba(255,255,255,.12);border-radius:10px;color:rgba(255,255,255,.8);font-size:.82rem;font-weight:500;font-family:'Inter',sans-serif;padding:.4rem .85rem;text-decoration:none;transition:.2s;}
    .nav-back:hover{background:rgba(255,255,255,.18);color:#fff;}
    .nav-right{margin-left:auto;display:flex;align-items:center;gap:.5rem;}
    .nav-icon{width:38px;height:38px;border-radius:10px;background:rgba(255,255,255,.09);border:1px solid rgba(255,255,255,.12);color:rgba(255,255,255,.8);font-size:1.1rem;display:flex;align-items:center;justify-content:center;text-decoration:none;transition:.2s;}
    .nav-icon:hover{background:rgba(255,255,255,.18);color:#fff;}
    .nav-avatar{width:36px;height:36px;border-radius:50%;background:linear-gradient(135deg,var(--accent),#d97706);font-family:'Cormorant Garamond',serif;font-weight:700;font-size:1.05rem;color:#fff;display:flex;align-items:center;justify-content:center;}

    /* ── PAGE ── */
    .page{max-width:1120px;margin:0 auto;padding:2rem 1rem 5rem;}

    /* ── HEADER ── */
    .page-head{display:flex;align-items:center;justify-content:space-between;margin-bottom:.75rem;flex-wrap:wrap;gap:.75rem;}
    .page-head-left{display:flex;align-items:center;gap:.75rem;}
    .page-title{font-family:'Cormorant Garamond',serif;font-size:1.85rem;font-weight:700;letter-spacing:.3px;}
    .wish-count{background:var(--red);color:#fff;font-family:'Inter',sans-serif;font-size:.7rem;font-weight:700;padding:2px 10px;border-radius:30px;letter-spacing:.5px;}
    .clear-btn{display:inline-flex;align-items:center;gap:.4rem;background:transparent;border:1.5px solid rgba(225,29,72,.3);color:var(--red);border-radius:10px;padding:.4rem .9rem;font-size:.8rem;font-weight:600;font-family:'Inter',sans-serif;cursor:pointer;text-decoration:none;transition:.2s;}
    .clear-btn:hover{background:rgba(225,29,72,.07);}

    /* ── TOOLBAR ── */
    .toolbar{display:flex;align-items:center;gap:.75rem;margin-bottom:1.5rem;flex-wrap:wrap;}
    .filter-select{height:38px;border-radius:10px;border:1.5px solid var(--border);background:var(--surface);color:var(--ink);padding:0 .85rem;font-family:'Inter',sans-serif;font-size:.83rem;font-weight:500;cursor:pointer;outline:none;transition:.2s;}
    .filter-select:focus{border-color:var(--ink);}
    .search-input{height:38px;border-radius:10px;border:1.5px solid var(--border);background:var(--surface);color:var(--ink);padding:0 .85rem;font-family:'Inter',sans-serif;font-size:.83rem;outline:none;width:200px;transition:.2s;}
    .search-input:focus{border-color:var(--ink);}
    .results-count{font-size:.8rem;color:var(--muted);margin-left:auto;font-family:'Inter',sans-serif;}

    /* ── GRID ── */
    .wish-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(240px,1fr));gap:1.1rem;}
    @media(max-width:520px){.wish-grid{grid-template-columns:repeat(2,1fr);gap:.65rem;}}

    /* ── PRODUCT CARD ── */
    .prod-card{background:var(--surface);border-radius:var(--r);border:1px solid var(--border);box-shadow:var(--sh);overflow:hidden;display:flex;flex-direction:column;transition:transform .22s,box-shadow .22s;position:relative;}
    .prod-card:hover{transform:translateY(-4px);box-shadow:var(--sh2);}

    /* badges */
    .disc-badge{position:absolute;top:.65rem;left:.65rem;z-index:6;background:var(--red);color:#fff;font-family:'Inter',sans-serif;font-size:.62rem;font-weight:700;padding:2px 8px;border-radius:6px;letter-spacing:.5px;}
    .remove-wish{position:absolute;top:.65rem;right:.65rem;z-index:10;width:32px;height:32px;border-radius:50%;border:none;background:rgba(255,255,255,.92);color:var(--red);display:flex;align-items:center;justify-content:center;cursor:pointer;font-size:1rem;transition:.2s;backdrop-filter:blur(4px);box-shadow:0 1px 6px rgba(0,0,0,.1);}
    .remove-wish:hover{background:var(--red);color:#fff;transform:scale(1.1);}

    /* OOS veil */
    .oos-veil{position:absolute;inset:0;background:rgba(250,247,242,.75);display:flex;align-items:center;justify-content:center;z-index:5;backdrop-filter:blur(3px);}
    .oos-label{background:var(--muted);color:#fff;font-family:'Inter',sans-serif;font-weight:700;font-size:.78rem;padding:.35rem 1rem;border-radius:8px;letter-spacing:.5px;}

    /* image */
    .prod-img{height:190px;background:#f8f4ee;display:flex;align-items:center;justify-content:center;overflow:hidden;border-bottom:1px solid var(--border);}
    .prod-img img{width:100%;height:100%;object-fit:contain;padding:.9rem;transition:transform .35s;}
    .prod-card:hover .prod-img img{transform:scale(1.07);}

    /* body */
    .prod-body{padding:.9rem .95rem .6rem;flex:1;display:flex;flex-direction:column;gap:.22rem;}
    .prod-cat{font-size:.62rem;color:var(--muted);text-transform:uppercase;letter-spacing:1.5px;font-weight:600;font-family:'Inter',sans-serif;}
    .prod-name{font-family:'Cormorant Garamond',serif;font-size:1.05rem;font-weight:700;color:var(--ink);line-height:1.3;display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;overflow:hidden;}
    .prod-pkg{font-size:.72rem;color:var(--muted);font-family:'Inter',sans-serif;}
    .price-row{display:flex;align-items:baseline;gap:.4rem;margin-top:.3rem;flex-wrap:wrap;}
    .price-final{font-family:'Cormorant Garamond',serif;font-size:1.25rem;font-weight:700;color:var(--ink);}
    .price-mrp{font-size:.78rem;color:var(--muted);text-decoration:line-through;font-family:'Inter',sans-serif;}
    .price-save{font-size:.7rem;font-weight:700;color:var(--green);font-family:'Inter',sans-serif;}

    /* actions */
    .prod-actions{padding:.7rem .95rem .85rem;border-top:1px solid var(--border);display:grid;grid-template-columns:1fr 1fr;gap:.45rem;}
    .act-btn{height:38px;border-radius:10px;border:none;cursor:pointer;font-family:'Inter',sans-serif;font-size:.77rem;font-weight:600;display:flex;align-items:center;justify-content:center;gap:.35rem;text-decoration:none;transition:.2s;letter-spacing:.2px;}
    .act-btn.cart{background:var(--ink);color:#fff;}
    .act-btn.cart:hover{background:var(--accent);color:#fff;}
    .act-btn.buy{background:var(--accent);color:#fff;}
    .act-btn.buy:hover{background:#d97706;color:#fff;}
    .act-btn[disabled]{opacity:.4;pointer-events:none;}

    /* ── EMPTY STATE ── */
    .empty-state{grid-column:1/-1;background:var(--surface);border-radius:var(--r);border:1px solid var(--border);padding:5rem 2rem;text-align:center;box-shadow:var(--sh);}
    .empty-icon{font-size:4rem;display:block;margin-bottom:1rem;}
    .empty-title{font-family:'Cormorant Garamond',serif;font-size:1.75rem;font-weight:700;margin-bottom:.5rem;}
    .empty-sub{color:var(--muted);font-size:.88rem;font-family:'Inter',sans-serif;margin-bottom:1.75rem;line-height:1.7;max-width:380px;margin-left:auto;margin-right:auto;}
    .btn-shop{display:inline-flex;align-items:center;gap:.5rem;background:var(--ink);color:#fff;padding:.75rem 1.75rem;border-radius:12px;font-family:'Inter',sans-serif;font-weight:600;letter-spacing:.3px;text-decoration:none;transition:.2s;}
    .btn-shop:hover{background:var(--accent);color:#fff;}

    /* ── TOAST ── */
    .toast-hub{position:fixed;bottom:1.5rem;right:1rem;z-index:2000;display:flex;flex-direction:column;gap:.5rem;}
    .toast-msg{background:var(--ink);color:#fff;border-radius:12px;padding:.7rem 1rem;font-size:.82rem;font-weight:500;font-family:'Inter',sans-serif;box-shadow:var(--sh2);display:flex;align-items:center;gap:.45rem;animation:slideUp .3s ease;max-width:290px;}
    @keyframes slideUp{from{opacity:0;transform:translateY(12px);}to{opacity:1;transform:translateY(0);}}

    @media(max-width:520px){
      .prod-img{height:150px;}
      .page-title{font-size:1.5rem;}
    }
  @media(max-width:768px){body{padding-bottom:70px;}}
</style>
</head>
<body>

<!-- NAV -->
<nav class="nav">
  <a href="Customer" class="nav-brand">SIBS<em>.</em></a>
  <a href="Customer" class="nav-back"><i class="bi bi-arrow-left"></i> Shop</a>
  <div class="nav-right">
    <a href="CartServlet?action=view" class="nav-icon" title="Cart"><i class="bi bi-bag"></i></a>
    <div class="nav-avatar"><%= initials %></div>
  </div>
</nav>

<div class="page">

  <!-- Header -->
  <div class="page-head">
    <div class="page-head-left">
      <div class="page-title"><i class="bi bi-heart-fill" style="color:var(--red);font-size:1.4rem;vertical-align:middle;margin-right:.35rem;"></i>My Wishlist</div>
      <% if (hasItems) { %>
      <span class="wish-count"><%= wishlist.size() %> item<%= wishlist.size() != 1 ? "s" : "" %></span>
      <% } %>
    </div>
    <% if (hasItems) { %>
    <a href="WishlistServlet?action=clearAll" class="clear-btn"
       onclick="return confirm('Clear your entire wishlist?')">
      <i class="bi bi-trash3"></i> Clear All
    </a>
    <% } %>
  </div>

  <!-- Toolbar -->
  <% if (hasItems) { %>
  <div class="toolbar">
    <input type="text" class="search-input" id="wishSearch" placeholder="Search saved items…">
    <select class="filter-select" onchange="sortWishlist(this.value)">
      <option value="">Sort: Default</option>
      <option value="price-low">Price: Low → High</option>
      <option value="price-high">Price: High → Low</option>
      <option value="discount">Best Discount</option>
    </select>
    <div class="results-count" id="resultsCount"><%= wishlist.size() %> saved items</div>
  </div>
  <% } %>

  <!-- Grid -->
  <div class="wish-grid" id="wishGrid">
    <% if (!hasItems) { %>
    <div class="empty-state">
      <span class="empty-icon">💝</span>
      <div class="empty-title">Your wishlist is empty</div>
      <div class="empty-sub">Tap the heart on any product to save it here. Build your dream list and buy when you're ready.</div>
      <a href="Customer" class="btn-shop"><i class="bi bi-bag-heart"></i> Discover Products</a>
    </div>

    <% } else {
        for (Product p : wishlist) {
            boolean oos = p.getStock() <= 0;
            String pName = p.getName() != null ? p.getName() : "";
            String pCat  = p.getCategory() != null ? p.getCategory().replace("_"," ") : "General";
            String pImg  = (p.getImageUrl() != null && !p.getImageUrl().isEmpty()) ? p.getImageUrl() : "images/default.png";
            String pDesc = (p.getDescription() != null && !p.getDescription().isEmpty()) ? p.getDescription() : "";
            double fp    = p.getFinalPrice();
            double mrp   = p.getMrp();
            double disc  = p.getDiscount();
            double saved = mrp - fp;
    %>
    <div class="prod-card"
         data-price="<%= fp %>"
         data-mrp="<%= mrp %>"
         data-discount="<%= disc %>"
         data-name="<%= pName.toLowerCase().replace("\"","") %>">

      <% if (disc > 0) { %><div class="disc-badge"><%= (int)disc %>% OFF</div><% } %>

      <button class="remove-wish"
              onclick="removeWishItem(<%= p.getId() %>, this)"
              title="Remove from wishlist">
        <i class="bi bi-heart-fill"></i>
      </button>

      <% if (oos) { %>
      <div class="oos-veil"><div class="oos-label">Out of Stock</div></div>
      <% } %>

      <div class="prod-img">
        <img src="<%= pImg %>" alt="<%= pName %>" onerror="this.src='images/default.png'">
      </div>

      <div class="prod-body">
        <div class="prod-cat"><%= pCat %></div>
        <div class="prod-name" title="<%= pName %>"><%= pName %></div>
        <div class="prod-pkg">
          <i class="bi bi-basket2" style="font-size:.65rem;"></i>
          <%= p.getQuantity() %> <%= p.getUnit() %>
        </div>
        <div class="price-row">
          <span class="price-final">₹<%= String.format("%.0f", fp) %></span>
          <% if (disc > 0) { %>
          <span class="price-mrp">₹<%= String.format("%.0f", mrp) %></span>
          <span class="price-save">Save ₹<%= String.format("%.0f", saved) %></span>
          <% } %>
        </div>
      </div>

      <div class="prod-actions">
        <a href="CartServlet?action=add&id=<%= p.getId() %>"
           class="act-btn cart" <%= oos ? "onclick=\"return false;\" style=\"opacity:.4;pointer-events:none;\"" : "" %>>
          <i class="bi bi-cart-plus"></i> Add to Cart
        </a>
        <form action="BuyNow" method="post" style="display:contents;">
          <input type="hidden" name="productId" value="<%= p.getId() %>">
          <input type="hidden" name="quantity" value="1">
          <button type="submit" class="act-btn buy" <%= oos ? "disabled" : "" %>>
            <i class="bi bi-lightning-fill"></i> Buy Now
          </button>
        </form>
      </div>
    </div>
    <% } } %>
  </div>
</div>

<div class="toast-hub" id="toastHub"></div>

<script>
function toast(msg, bg) {
  const hub = document.getElementById('toastHub');
  const el = document.createElement('div');
  el.className = 'toast-msg';
  if (bg) el.style.background = bg;
  el.innerHTML = msg;
  hub.appendChild(el);
  setTimeout(() => { el.style.opacity='0'; el.style.transition='opacity .3s'; }, 2700);
  setTimeout(() => el.remove(), 3100);
}

function removeWishItem(productId, btn) {
  const card = btn.closest('.prod-card');
  fetch('WishlistServlet?action=remove&id=' + productId, {
    headers: { 'X-Requested-With': 'XMLHttpRequest' }
  })
  .then(r => r.json())
  .then(data => {
    if (data.success) {
      card.style.transition = 'opacity .3s, transform .3s';
      card.style.opacity = '0';
      card.style.transform = 'scale(0.92)';
      setTimeout(() => {
        card.remove();
        updateCount();
        toast('<i class="bi bi-heart"></i> Removed from wishlist', '#78716c');
      }, 300);
    }
  })
  .catch(() => {
    // Fallback: hard navigate
    window.location.href = 'WishlistServlet?action=remove&id=' + productId;
  });
}

function updateCount() {
  const cards = document.querySelectorAll('#wishGrid .prod-card');
  const badge = document.querySelector('.wish-count');
  const rc    = document.getElementById('resultsCount');
  if (badge) badge.textContent = cards.length + ' item' + (cards.length !== 1 ? 's' : '');
  if (rc)    rc.textContent    = cards.length + ' saved items';
  if (cards.length === 0) {
    document.getElementById('wishGrid').innerHTML =
      '<div class="empty-state" style="grid-column:1/-1">' +
      '<span class="empty-icon">💝</span>' +
      '<div class="empty-title">Wishlist cleared</div>' +
      '<div class="empty-sub">Start saving products you love.</div>' +
      '<a href="Customer" class="btn-shop"><i class="bi bi-bag-heart"></i> Shop Now</a>' +
      '</div>';
  }
}

function sortWishlist(by) {
  const grid  = document.getElementById('wishGrid');
  const cards = Array.from(grid.querySelectorAll('.prod-card'));
  cards.sort((a, b) => {
    if (by === 'price-low')  return +a.dataset.price    - +b.dataset.price;
    if (by === 'price-high') return +b.dataset.price    - +a.dataset.price;
    if (by === 'discount')   return +b.dataset.discount - +a.dataset.discount;
    return 0;
  });
  cards.forEach(c => grid.appendChild(c));
}

/* Client-side search */
document.addEventListener('DOMContentLoaded', function() {
  const inp = document.getElementById('wishSearch');
  if (!inp) return;
  inp.addEventListener('input', function() {
    const q = this.value.toLowerCase().trim();
    let visible = 0;
    document.querySelectorAll('#wishGrid .prod-card').forEach(card => {
      const match = !q || card.dataset.name.includes(q);
      card.style.display = match ? '' : 'none';
      if (match) visible++;
    });
    const rc = document.getElementById('resultsCount');
    if (rc) rc.textContent = visible + ' saved items';
  });
});
</script>

<jsp:include page="customerBottomNav.jsp"><jsp:param name="activePage" value=""/></jsp:include>
</body>
</html>
