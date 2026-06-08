<%@ page contentType="text/html; charset=UTF-8" %>
<%@ page import="java.util.*" %>
<%@ page import="com.util.Product" %>
<%
    List<Product> products   = (List<Product>) request.getAttribute("products");
    Boolean loggedIn         = (Boolean)       session.getAttribute("loggedIn");
    Integer currentPage      = (Integer)       request.getAttribute("currentPage");
    Integer totalPages       = (Integer)       request.getAttribute("totalPages");
    boolean isLoggedIn       = Boolean.TRUE.equals(loggedIn);
%>
<%
/* ── Group by category ── */
Map<String, List<Product>> byCategory = new LinkedHashMap<>();
if (products != null) {
    for (Product p : products) {
        String cat = p.getCategory() != null ? p.getCategory() : "other";
        byCategory.computeIfAbsent(cat, k -> new ArrayList<>()).add(p);
    }
}

/* ── Category display map (key = DB value, value = label + emoji) ── */
Map<String, String> catDisplay = new LinkedHashMap<>();
catDisplay.put("fruits",          "🍎 Fruits");
catDisplay.put("vegetables",      "🥦 Vegetables");
catDisplay.put("dairy_products",  "🥛 Dairy & Eggs");
catDisplay.put("packed_food",     "📦 Packed Food");
catDisplay.put("beverages",       "🥤 Beverages");
catDisplay.put("snacks",          "🍿 Snacks");
catDisplay.put("bakery",          "🥐 Bakery");
catDisplay.put("frozen",          "❄️ Frozen");
catDisplay.put("personal_care",   "🧴 Personal Care");
catDisplay.put("household",       "🏠 Household");
catDisplay.put("fashion",         "👗 Fashion");
catDisplay.put("electronics",     "📱 Electronics");
catDisplay.put("home_furniture",  "🛋️ Home & Furniture");
catDisplay.put("beauty",          "💄 Beauty");
catDisplay.put("sports",          "🏀 Sports");
catDisplay.put("books",           "📚 Books");
catDisplay.put("other",           "🛍️ Other");
%>

<style>
/* ── Theme tokens (Midnight Purple) ── */
:root {
  --primary: #2d1b69;
  --accent:  #6c63ff;
  --accent2: #00d4ff;
  --green:   #10b981;
  --gold:    #6c63ff;
  --bg:      #f5f3ff;
  --surface: #ffffff;
  --text:    #1a1035;
  --muted:   #7c748e;
  --border:  rgba(45,27,105,0.10);
}
/* ── Category section ── */
.category-section { margin-bottom: 2.5rem; }
.cat-header {
  display: flex; align-items: center; justify-content: space-between;
  margin-bottom: 1.1rem; padding-bottom: .65rem;
  border-bottom: 1px solid rgba(0,0,0,.07);
}
.cat-title {
  font-family: 'Space Grotesk', sans-serif;
  font-size: 1.2rem; font-weight: 700; color: #2d1b69;
  display: flex; align-items: center; gap: .5rem;
}
.cat-title::before {
  content: ''; display: inline-block; width: 4px; height: 1.1em;
  background: #6c63ff; border-radius: 2px;
}
.cat-count {
  background: rgba(45,27,105,.07); color: #2d1b69;
  font-size: .73rem; font-weight: 600; padding: 2px 10px; border-radius: 20px;
}

/* ── Card grid inside category ── */
.product-grid-inner {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(190px, 1fr));
  gap: 1rem;
}
@media (max-width: 480px) {
  .product-grid-inner { grid-template-columns: repeat(2, 1fr); gap: .6rem; }
  /* On very small screens collapse card actions to stacked layout */
  .card-actions { grid-template-columns: 1fr; }
  .card-actions .icon-btn { display: none; } /* hide wishlist/quickview on tiny phones */
}

/* ── Product card ── */
.product-card {
  background: #fff; border-radius: 14px;
  box-shadow: 0 2px 16px rgba(15,52,96,.07); overflow: hidden;
  transition: all .28s ease; position: relative;
  display: flex; flex-direction: column; border: 1px solid transparent;
}
.product-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 10px 36px rgba(15,52,96,.16);
  border-color: rgba(15,52,96,.08);
}

/* Badges */
.card-badges { position: absolute; top: 9px; left: 9px; z-index: 2; display: flex; flex-direction: column; gap: 4px; }
.badge-tag { font-size: .68rem; font-weight: 700; padding: 3px 9px; border-radius: 20px; display: inline-block; line-height: 1.2; }
.badge-tag.off  { background: #6c63ff; color: #fff; }
.badge-tag.low  { background: #f5a623; color: #fff; }
.badge-tag.sold { background: #6b7280; color: #fff; }
.badge-tag.new  { background: #2d1b69; color: #fff; }

/* Wish */
.card-wish {
  position: absolute; top: 9px; right: 9px; z-index: 2;
  background: rgba(255,255,255,.92); border: 1px solid rgba(0,0,0,.08);
  border-radius: 50%; width: 32px; height: 32px;
  display: flex; align-items: center; justify-content: center;
  cursor: pointer; color: #9ca3af; font-size: .9rem;
  transition: all .2s; text-decoration: none; backdrop-filter: blur(4px);
}
.card-wish:hover { color: #6c63ff; border-color: #6c63ff; transform: scale(1.1); }
.card-wish.wished { color: #6c63ff; border-color: #6c63ff; background: #ede9fe; }

/* Image */
.card-img-wrap {
  background: #f8f9fc; height: 170px;
  display: flex; align-items: center; justify-content: center;
  overflow: hidden; padding: .6rem;
}
.card-img-wrap img { width: 100%; height: 100%; object-fit: contain; transition: transform .35s ease; }
.product-card:hover .card-img-wrap img { transform: scale(1.07); }

/* OOS veil */
.oos-veil {
  position: absolute; top: 0; left: 0; right: 0; bottom: 0;
  background: rgba(255,255,255,.55); backdrop-filter: blur(1.5px);
  display: flex; align-items: center; justify-content: center; z-index: 1;
  pointer-events: none;
}
.oos-label {
  background: #6b7280; color: #fff;
  font-size: .78rem; font-weight: 800;
  padding: .3rem .85rem; border-radius: 8px;
}

/* Body */
.card-body { padding: .9rem; flex: 1; display: flex; flex-direction: column; }
.card-cat  { font-size: .69rem; text-transform: uppercase; letter-spacing: .07em; color: #9ca3af; margin-bottom: .22rem; }
.card-name {
  font-weight: 600; font-size: .9rem; color: #1a1035;
  margin-bottom: .35rem; line-height: 1.35;
  display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden;
}
.card-pkg { font-size: .72rem; color: #6b7280; margin-bottom: .35rem; }

/* Rating */
.card-rating { display: flex; align-items: center; gap: .3rem; margin-bottom: .4rem; }
.stars-full  { color: #f5a623; font-size: .75rem; }
.stars-empty { color: #e5e7eb; font-size: .75rem; }
.rating-count { font-size: .72rem; color: #9ca3af; }

/* Price */
.card-price-row { display: flex; align-items: baseline; gap: .4rem; flex-wrap: wrap; margin-bottom: .35rem; }
.price-final { font-size: 1.1rem; font-weight: 700; color: #2d1b69; }
.price-mrp   { font-size: .78rem; text-decoration: line-through; color: #9ca3af; }
.price-off   { font-size: .72rem; color: #10b981; font-weight: 600; }

/* Stock */
.stock-indicator { margin-bottom: .55rem; }
.stock-text { font-size: .7rem; display: flex; justify-content: space-between; margin-bottom: 3px; }
.sl { color: #6b7280; }
.sv { font-weight: 600; }
.sv.green { color: #10b981; }
.sv.amber { color: #f5a623; }
.sv.red   { color: #6c63ff; }
.sv.gray  { color: #6b7280; }
.stock-bar  { height: 4px; border-radius: 4px; background: #e5e7eb; overflow: hidden; }
.stock-fill { height: 100%; border-radius: 4px; transition: width .5s; }
.stock-fill.high { background: #10b981; }
.stock-fill.mid  { background: #f5a623; }
.stock-fill.lo   { background: #6c63ff; }

/* Actions */
.card-actions { margin-top: auto; padding-top: .6rem; display: grid; grid-template-columns: 1fr auto auto; gap: .4rem; }
.btn-cart {
  padding: .55rem .5rem; background: #2d1b69; color: #fff;
  border: none; border-radius: 10px; font-size: .82rem; font-weight: 600;
  cursor: pointer; text-align: center; text-decoration: none;
  display: flex; align-items: center; justify-content: center; gap: .3rem; transition: all .2s;
}
.btn-cart:hover { background: #1e1145; color: #fff; }
.btn-cart.out     { background: #f3f4f6; color: #6b7280; cursor: default; pointer-events: none; }
.btn-cart.login   { background: #6c63ff; color: #fff; cursor: pointer; }
.btn-cart.login:hover { background: #5a52e0; color: #fff; }
/* Buy Now */
.btn-buy {
  width: 36px; height: 36px; flex-shrink: 0;
  background: #f5a623; border: none; border-radius: 10px; color: #fff;
  cursor: pointer; display: flex; align-items: center; justify-content: center;
  font-size: .88rem; transition: all .2s;
}
.btn-buy:hover { background: #d9911a; }
.btn-buy.login-buy { background: rgba(108,99,255,.12); color: #6c63ff; border: 1.5px solid rgba(108,99,255,.3); }
.btn-buy.login-buy:hover { background: #6c63ff; color: #fff; }
/* Quick View */
.btn-qv {
  width: 36px; height: 36px; flex-shrink: 0;
  background: #f4f6fb; border: 1.5px solid rgba(0,0,0,.07);
  border-radius: 10px; color: #6b7280;
  cursor: pointer; display: flex; align-items: center; justify-content: center;
  font-size: .9rem; transition: all .2s;
}
.btn-qv:hover { background: #2d1b69; color: #fff; border-color: #2d1b69; }

/* ── Pagination ── */
.pagination-wrap { padding: 1.5rem 0 .5rem; }
.pagination .page-link {
  border-radius: 8px !important; border: 1.5px solid rgba(0,0,0,.1);
  color: #2d1b69; font-weight: 500; margin: 0 2px; transition: all .18s;
}
.pagination .page-item.active .page-link { background: #2d1b69; border-color: #2d1b69; color: #fff; }
.pagination .page-link:hover { background: rgba(45,27,105,.07); }

/* ── Empty state ── */
.empty-state { text-align: center; padding: 4rem 2rem; color: #9ca3af; }
.empty-state-icon { font-size: 3.5rem; margin-bottom: 1rem; opacity: .4; }
.empty-state h4 { color: #2d1b69; font-size: 1.1rem; margin-bottom: .5rem; }
.empty-state p  { font-size: .88rem; }
</style>

<%
if (products == null || products.isEmpty()) {
%>
<div class="empty-state col-12">
  <div class="empty-state-icon"><i class="bi bi-bag-x"></i></div>
  <h4>No products found</h4>
  <p>Try a different category or clear your search.</p>
</div>
<%
} else {
    for (Map.Entry<String, List<Product>> entry : byCategory.entrySet()) {
        String catKey   = entry.getKey() != null ? entry.getKey() : "other";
        String catLabel = catDisplay.getOrDefault(catKey.toLowerCase(),
                          "🛍️ " + catKey.replace("_"," ").substring(0,1).toUpperCase()
                          + catKey.replace("_"," ").substring(1));
        List<Product> catProds = entry.getValue();
%>
<div class="category-section col-12">
  <div class="cat-header">
    <h2 class="cat-title"><%= catLabel %></h2>
    <span class="cat-count"><%= catProds.size() %> item<%= catProds.size() != 1 ? "s" : "" %></span>
  </div>
  <div class="product-grid-inner">
  <%
    for (Product p : catProds) {
        int    stock      = p.getStock();
        double mrp        = p.getMrp();
        double fp         = p.getFinalPrice();
        double disc       = p.getDiscount();
        double stockPct   = Math.min(100.0, (stock / 200.0) * 100.0); // 200 = assumed max stock for % bar
        String fillCls    = stock == 0 ? "none" : stock <= 10 ? "lo" : stock <= 40 ? "mid" : "high";
        String svCls      = stock == 0 ? "gray" : stock <= 10 ? "red"  : stock <= 40 ? "amber" : "green";
        String stockLbl   = stock == 0 ? "Out of Stock" : stock <= 10 ? "Only " + stock + " left!" : "In Stock";
        boolean oos       = (stock == 0);

        /* Simulated rating — replace with real DB column when available */
        double rating     = 3.5 + (p.getId() % 15) * 0.1;
        if (rating > 5.0) rating = 5.0;
        int    ratingCnt  = 40 + (p.getId() % 960);
        int    fullStars  = (int) rating;
        String fStr = "★★★★★".substring(0, Math.min(5, fullStars));
        String eStr = "★★★★★".substring(Math.min(5, fullStars));
  %>
    <div class="product-card">

      <!-- Badges -->
      <div class="card-badges">
        <% if (disc > 0)            { %><span class="badge-tag off"><%= (int)disc %>% OFF</span><% } %>
        <% if (!oos && stock <= 10) { %><span class="badge-tag low">Low Stock</span><% } %>
        <% if (oos)                  { %><span class="badge-tag sold">Sold Out</span><% } %>
      </div>

      <!-- Wishlist button — data-id for JS toggle; login redirect if guest -->
      <button class="card-wish wish-btn"
              data-id="<%= p.getId() %>"
              data-login="<%= !isLoggedIn %>"
              title="<%= isLoggedIn ? "Add to Wishlist" : "Login to save" %>">
        <i class="bi bi-heart"></i>
      </button>

      <!-- OOS overlay -->
      <% if (oos) { %>
      <div class="oos-veil"><div class="oos-label">Out of Stock</div></div>
      <% } %>

      <!-- Image -->
      <div class="card-img-wrap">
        <img src="<%= p.getImageUrl() != null && !p.getImageUrl().isEmpty()
                       ? p.getImageUrl() : "images/default.png" %>"
             alt="<%= p.getName() %>"
             loading="lazy"
             onerror="this.src='images/default.png'">
      </div>

      <!-- Body -->
      <div class="card-body">
        <div class="card-cat"><%= catLabel.replaceAll("^[^a-zA-Z]*","") %></div>
        <div class="card-name" title="<%= p.getName() %>"><%= p.getName() %></div>
        <div class="card-pkg"><i class="bi bi-basket2"></i> <%= p.getQuantity() %> <%= p.getUnit() %></div>

        <!-- Rating -->
        <div class="card-rating">
          <span class="stars-full"><%= fStr %></span>
          <span class="stars-empty"><%= eStr %></span>
          <span class="rating-count">(<%= ratingCnt %>)</span>
        </div>

        <!-- Price -->
        <div class="card-price-row">
          <span class="price-final">₹<%= String.format("%.0f", fp) %></span>
          <% if (disc > 0) { %>
          <span class="price-mrp">₹<%= String.format("%.0f", mrp) %></span>
          <span class="price-off">Save ₹<%= String.format("%.0f", mrp - fp) %></span>
          <% } %>
        </div>

        <!-- Stock bar -->
        <div class="stock-indicator">
          <div class="stock-text">
            <span class="sl">Availability</span>
            <span class="sv <%= svCls %>"><%= stockLbl %></span>
          </div>
          <% if (!oos) { %>
          <div class="stock-bar">
            <div class="stock-fill <%= fillCls %>"
                 style="width:<%= String.format("%.1f", Math.max(6.0, stockPct)) %>%;"></div>
          </div>
          <% } %>
        </div>

        <!-- Actions -->
        <div class="card-actions">
          <%-- Add to Cart --%>
          <% if (oos) { %>
            <button class="btn-cart out" disabled><i class="bi bi-x-circle"></i> Sold Out</button>
          <% } else if (isLoggedIn) { %>
            <button class="btn-cart add-to-cart-btn" data-id="<%= p.getId() %>">
              <i class="bi bi-cart-plus"></i> Add to Cart
            </button>
          <% } else { %>
            <%-- Guest: same visual as cart btn but routes to login --%>
            <button class="btn-cart login login-redirect" title="Login to add to cart">
              <i class="bi bi-lock"></i> Login to Add
            </button>
          <% } %>

          <%-- Buy Now --%>
          <% if (!oos) { %>
            <% if (isLoggedIn) { %>
              <%-- POST form submit via JS --%>
              <button class="btn-buy"
                      data-product-id="<%= p.getId() %>"
                      data-qty="1"
                      title="Buy Now">
                <i class="bi bi-lightning-fill"></i>
              </button>
            <% } else { %>
              <button class="btn-buy login-buy login-redirect"
                      title="Login to buy">
                <i class="bi bi-lightning-fill"></i>
              </button>
            <% } %>
          <% } else { %>
            <button class="btn-buy" style="opacity:.35;pointer-events:none;" disabled>
              <i class="bi bi-lightning-fill"></i>
            </button>
          <% } %>

          <%-- Quick View --%>
          <button class="btn-qv quick-view-btn"
                  data-id="<%= p.getId() %>"
                  title="Quick View">
            <i class="bi bi-eye"></i>
          </button>
        </div>

      </div><%-- /card-body --%>
    </div><%-- /product-card --%>
  <% } %>
  </div><%-- /product-grid-inner --%>
</div><%-- /category-section --%>
<% } } %>

<!-- ── Pagination ── -->
<% if (currentPage != null && totalPages != null && totalPages > 1) { %>
<div class="col-12 pagination-wrap">
  <nav aria-label="Products pagination">
    <ul class="pagination justify-content-center flex-wrap">
      <li class="page-item <%= currentPage == 1 ? "disabled" : "" %>">
        <button class="page-link page-btn" data-page="<%= currentPage - 1 %>">
          <i class="bi bi-chevron-left"></i> Prev
        </button>
      </li>
      <% for (int i = 1; i <= totalPages; i++) { %>
      <li class="page-item <%= i == currentPage ? "active" : "" %>">
        <button class="page-link page-btn" data-page="<%= i %>"><%= i %></button>
      </li>
      <% } %>
      <li class="page-item <%= currentPage.equals(totalPages) ? "disabled" : "" %>">
        <button class="page-link page-btn" data-page="<%= currentPage + 1 %>">
          Next <i class="bi bi-chevron-right"></i>
        </button>
      </li>
    </ul>
  </nav>
</div>
<% } %>

<%--
  NOTE: buyNow(), add-to-cart, wishlist, login-redirect listeners and
  quick-view wiring are all registered by attachListeners() in
  customerDashboard.jsp after every AJAX reload.  No JS needed here —
  putting JS inside an AJAX fragment causes "X is not defined" errors
  because innerHTML-injected <script> tags are NOT executed by the browser.
--%>
