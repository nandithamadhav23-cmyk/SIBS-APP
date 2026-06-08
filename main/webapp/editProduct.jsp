<%@ page import="com.util.Product" %>
<%@ page contentType="text/html; charset=UTF-8" %>

<%
    String uname = (session != null) ? (String) session.getAttribute("username") : null;
    String role  = (session != null) ? (String) session.getAttribute("role")     : null;
    if (role == null || !"admin".equalsIgnoreCase(role)) {
        response.sendRedirect("index.jsp?error=Access denied. Please login as admin.");
        return;
    }

    Product product = (Product) request.getAttribute("product");
    if (product == null) {
        response.sendRedirect("ProductServlet");
        return;
    }

    String error = (String) request.getAttribute("error");

    // Format added date for datetime-local input
    String addedDateValue = "";
    if (product.getAddedDate() != null) {
        addedDateValue = new java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm")
                             .format(product.getAddedDate());
    } else {
        addedDateValue = new java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm")
                             .format(new java.util.Date());
    }

    // Helper for category selected
    String cat = product.getCategory() != null ? product.getCategory() : "";
    String unit = product.getUnit() != null ? product.getUnit() : "";
    String status = product.getStatus() != null ? product.getStatus().toLowerCase() : "active";
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Edit Product — Smart Inventory</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
<link href="https://cdn.jsdelivr.net/npm/bootstrap-icons/font/bootstrap-icons.css" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=Nunito:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
<style>
  :root {
    --primary:      #0ea5e9;
    --primary-dark: #0369a1;
    --accent:       #38bdf8;
    --accent-light: #e0f2fe;
    --success:      #16a34a;
    --danger:       #ef4444;
    --warning:      #f59e0b;
    --info:         #0ea5e9;
    --text:         #0c1a2e;
    --text-mid:     #1e3a5f;
    --muted:        #64748b;
    --border:       #dbeafe;
    --bg:           #f0f9ff;
    --white:        #ffffff;
    --nav-h:        64px;
    --radius:       12px;
    --shadow-sm:    0 2px 12px rgba(14,165,233,.08);
    --shadow-md:    0 4px 24px rgba(14,165,233,.13);
    --shadow-lg:    0 12px 40px rgba(14,165,233,.18);
  }

  *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

  body {
    font-family: 'Nunito', sans-serif;
    background: var(--bg);
    color: var(--text);
    min-height: 100vh;
    padding-top: var(--nav-h);
  }

  /* ── NAVBAR ── */
  .top-navbar {
    position: fixed; top: 0; left: 0; right: 0;
    height: var(--nav-h); z-index: 1050;
    background: var(--primary);
    border-bottom: none; box-shadow: 0 2px 16px rgba(14,165,233,.25);
    display: flex; align-items: center;
    padding: 0 1.75rem; gap: 1.25rem;
    box-shadow: 0 2px 20px rgba(0,0,0,0.2);
  }
  .nav-brand {
    font-family: 'Nunito', sans-serif;
    font-size: 1.2rem; font-weight: 700;
    color: #fff; text-decoration: none;
    display: flex; align-items: center; gap: 0.5rem;
  }
  .nav-brand .brand-accent { color: #bae6fd; }
  .nav-divider { width: 1px; height: 24px; background: rgba(255,255,255,0.15); }
  .nav-page-label { font-size: 0.82rem; color: rgba(255,255,255,0.55); }
  .nav-right { margin-left: auto; display: flex; align-items: center; gap: 0.85rem; }
  .nav-avatar {
    width: 32px; height: 32px; border-radius: 50%;
    background: var(--accent);
    display: flex; align-items: center; justify-content: center;
    font-weight: 700; font-size: 0.82rem; color: var(--primary);
  }
  .nav-user { display: flex; align-items: center; gap: 0.5rem; font-size: 0.85rem; color: rgba(255,255,255,0.75); }
  .nav-role {
    background: rgba(255,255,255,0.18); border: 1px solid rgba(255,255,255,0.35);
    color: #fff; font-size: 0.72rem; font-weight: 600;
    padding: 2px 10px; border-radius: 20px; text-transform: capitalize;
  }
  .nav-btn {
    display: inline-flex; align-items: center; gap: 0.35rem;
    padding: 0.4rem 1rem; border-radius: 8px;
    font-size: 0.83rem; font-weight: 500;
    text-decoration: none; cursor: pointer;
    border: 1px solid rgba(255,255,255,0.2);
    color: rgba(255,255,255,0.8);
    background: rgba(255,255,255,0.07);
    transition: all 0.18s; font-family: 'Nunito', sans-serif;
  }
  .nav-btn:hover { background: rgba(255,255,255,0.15); color: #fff; }

  /* ── PAGE WRAPPER ── */
  .page-wrap {
    max-width: 860px; margin: 0 auto;
    padding: 2rem 1.5rem 3rem;
  }

  /* ── BREADCRUMB ── */
  .breadcrumb-bar {
    display: flex; align-items: center; gap: 0.5rem;
    font-size: 0.8rem; color: var(--muted);
    margin-bottom: 1.25rem;
  }
  .breadcrumb-bar a { color: var(--muted); text-decoration: none; transition: color 0.15s; }
  .breadcrumb-bar a:hover { color: var(--primary); }
  .breadcrumb-bar .sep { color: var(--border); }
  .breadcrumb-bar .current { color: var(--text); font-weight: 500; }

  /* ── FORM CARD ── */
  .form-card {
    background: var(--white);
    border: 1px solid var(--border);
    border-radius: 16px;
    box-shadow: var(--shadow-md);
    overflow: hidden;
  }

  .form-card-header {
    background: linear-gradient(135deg, var(--primary) 0%, var(--primary-dark) 100%);
    padding: 1.25rem 1.75rem;
    display: flex; align-items: center; justify-content: space-between;
    border-bottom: 3px solid var(--accent);
  }
  .form-card-title {
    font-family: 'Nunito', sans-serif;
    font-size: 1.2rem; font-weight: 700; color: #fff;
    display: flex; align-items: center; gap: 0.6rem;
  }
  .product-id-badge {
    background: rgba(255,255,255,0.18); border: 1px solid rgba(255,255,255,0.35);
    color: #fff; font-size: 0.75rem; font-weight: 600;
    padding: 3px 12px; border-radius: 20px;
    font-family: 'Nunito', sans-serif;
  }

  .form-card-body { padding: 1.75rem; }

  /* ── SECTION DIVIDERS ── */
  .form-section {
    margin-bottom: 1.5rem;
    padding-bottom: 1.5rem;
    border-bottom: 1px solid var(--border);
  }
  .form-section:last-of-type { border-bottom: none; margin-bottom: 0; }
  .section-label {
    font-size: 0.72rem; font-weight: 700; text-transform: uppercase;
    letter-spacing: 0.1em; color: var(--muted);
    margin-bottom: 1rem;
    display: flex; align-items: center; gap: 0.5rem;
  }
  .section-label::after {
    content: ''; flex: 1; height: 1px; background: var(--border);
  }

  /* ── FORM CONTROLS ── */
  .form-label {
    font-size: 0.82rem; font-weight: 600; color: var(--text-mid);
    margin-bottom: 0.35rem;
    display: flex; align-items: center; gap: 0.3rem;
  }
  .form-label i { color: var(--primary); font-size: 0.85rem; }

  .form-control, .form-select {
    border: 1.5px solid var(--border); border-radius: 9px;
    font-family: 'Nunito', sans-serif; font-size: 0.88rem;
    color: var(--text); background: var(--white);
    padding: 0.52rem 0.85rem; transition: all 0.18s;
    width: 100%;
  }
  .form-control:focus, .form-select:focus {
    border-color: var(--primary);
    box-shadow: 0 0 0 3px rgba(14,165,233,0.15);
    outline: none;
  }
  .form-control::placeholder { color: var(--muted); }
  .form-control.readonly-field {
    background: var(--bg); color: var(--success);
    font-weight: 700; cursor: not-allowed;
  }
  textarea.form-control { resize: vertical; min-height: 90px; }

  /* Status toggle visual */
  .status-toggle-wrap { display: flex; gap: 0.5rem; }
  .status-option {
    flex: 1; display: flex; align-items: center; justify-content: center; gap: 0.4rem;
    padding: 0.55rem 0.75rem; border-radius: 9px;
    border: 1.5px solid var(--border);
    font-size: 0.83rem; font-weight: 600; cursor: pointer;
    transition: all 0.18s;
  }
  .status-option input { display: none; }
  .status-option.active-opt  { border-color: var(--success); background: rgba(16,185,129,0.06); color: var(--success); }
  .status-option.inactive-opt{ border-color: var(--danger);  background: rgba(239,68,68,0.06); color: var(--danger); }
  .status-hint {
    font-size: 0.72rem; color: var(--muted); margin-top: 0.3rem;
  }
  .status-hint.forced { color: var(--warning); }

  /* ── IMAGE SECTION ── */
  .image-row { display: flex; gap: 1.25rem; align-items: flex-start; flex-wrap: wrap; }
  .image-preview-box {
    width: 110px; height: 110px; border-radius: 12px;
    border: 2px solid var(--border); background: var(--bg);
    overflow: hidden; flex-shrink: 0;
    display: flex; align-items: center; justify-content: center;
    position: relative;
  }
  .image-preview-box img {
    width: 100%; height: 100%; object-fit: cover;
    transition: transform 0.3s ease;
  }
  .image-preview-box:hover img { transform: scale(1.06); }
  .image-preview-box .img-overlay {
    position: absolute; inset: 0;
    background: rgba(26,26,46,0.5);
    display: flex; align-items: center; justify-content: center;
    color: #fff; font-size: 1.2rem;
    opacity: 0; transition: opacity 0.2s;
  }
  .image-preview-box:hover .img-overlay { opacity: 1; }
  .image-upload-wrap { flex: 1; min-width: 200px; }
  .image-upload-wrap .form-control { padding: 0.45rem; }
  .img-note { font-size: 0.75rem; color: var(--muted); margin-top: 0.35rem; }

  /* ── FINAL PRICE DISPLAY ── */
  .final-price-display {
    background: rgba(16,185,129,0.06);
    border: 1.5px solid rgba(16,185,129,0.2);
    border-radius: 9px; padding: 0.52rem 0.85rem;
    display: flex; align-items: center; gap: 0.4rem;
    font-weight: 700; font-size: 1rem; color: var(--success);
  }

  /* ── CHANGED INDICATOR ── */
  .field-changed .form-control,
  .field-changed .form-select {
    border-color: var(--warning) !important;
    background: rgba(245,158,11,0.03) !important;
  }
  .changed-badge {
    display: none; font-size: 0.68rem; color: var(--warning);
    font-weight: 600; margin-top: 2px;
  }
  .field-changed .changed-badge { display: block; }

  /* ── ERROR ALERT ── */
  .error-alert {
    background: rgba(239,68,68,0.06); border: 1px solid rgba(239,68,68,0.25);
    border-left: 3px solid var(--danger); border-radius: 10px;
    padding: 0.85rem 1rem; margin-bottom: 1.5rem;
    display: flex; align-items: flex-start; gap: 0.65rem;
    font-size: 0.875rem; color: var(--danger);
    animation: slideDown 0.25s ease;
  }
  @keyframes slideDown { from{opacity:0;transform:translateY(-6px);} to{opacity:1;transform:none;} }

  /* ── ACTION BUTTONS ── */
  .form-actions {
    display: flex; align-items: center; justify-content: space-between;
    flex-wrap: wrap; gap: 0.75rem;
    padding-top: 1.25rem;
    border-top: 1px solid var(--border);
    margin-top: 1.5rem;
  }
  .btn-save {
    display: inline-flex; align-items: center; gap: 0.45rem;
    background: var(--primary); color: #fff; border: none;
    padding: 0.65rem 1.75rem; border-radius: 10px;
    font-family: 'Nunito', sans-serif; font-size: 0.9rem; font-weight: 600;
    cursor: pointer; transition: all 0.2s;
  }
  .btn-save:hover { background: #0d0f1f; transform: translateY(-1px); box-shadow: 0 4px 14px rgba(14,165,233,.25); }
  .btn-back-link {
    display: inline-flex; align-items: center; gap: 0.4rem;
    color: var(--muted); text-decoration: none; font-size: 0.88rem;
    font-weight: 500; transition: color 0.15s;
  }
  .btn-back-link:hover { color: var(--primary); }
  .changes-summary {
    font-size: 0.78rem; color: var(--muted);
    display: flex; align-items: center; gap: 0.35rem;
  }
  .changes-summary #changeCount {
    font-weight: 700; color: var(--warning);
  }

  /* ── FOOTER ── */
  footer {
    background: var(--primary-dark); border-top: none;
    color: rgba(255,255,255,0.65); font-size: 0.8rem;
    text-align: center; padding: 1rem; margin-top: 2rem;
  }
  footer span { color: #bae6fd; }

  @media(max-width:640px) {
    .page-wrap { padding: 1.25rem 1rem 2rem; }
    .form-card-body { padding: 1.25rem; }
    .image-row { flex-direction: column; }
  }
</style>
</head>
<body>

<!-- ══ NAVBAR ══ -->
<div class="top-navbar">
  <a class="nav-brand" href="dashboard.jsp">
    <i class="bi bi-boxes"></i>Smart<span class="brand-accent">Inventory</span>
  </a>
  <div class="nav-divider"></div>
  <span class="nav-page-label">Edit Product</span>
  <div class="nav-right">
    <div class="nav-user">
      <div class="nav-avatar"><%= uname != null ? String.valueOf(uname.charAt(0)).toUpperCase() : "A" %></div>
      <span><%= uname %></span>
    </div>
    <span class="nav-role"><%= role %></span>
    <a href="logout" class="nav-btn"><i class="bi bi-box-arrow-right"></i> Logout</a>
  </div>
</div>

<!-- ══ PAGE ══ -->
<div class="page-wrap">

  <!-- Breadcrumb -->
  <div class="breadcrumb-bar">
    <a href="dashboard.jsp"><i class="bi bi-house"></i> Dashboard</a>
    <span class="sep">/</span>
    <a href="ProductServlet">Products</a>
    <span class="sep">/</span>
    <span class="current">Edit #<%= product.getId() %></span>
  </div>

  <!-- Error alert -->
  <% if (error != null && !error.isEmpty()) { %>
  <div class="error-alert" id="errorAlert">
    <i class="bi bi-exclamation-triangle-fill" style="font-size:1rem;flex-shrink:0;"></i>
    <div><%= error %></div>
  </div>
  <% } %>

  <!-- Form Card -->
  <div class="form-card">
    <div class="form-card-header">
      <div class="form-card-title">
        <i class="bi bi-pencil-square"></i> Edit Product
      </div>
      <span class="product-id-badge">ID #<%= product.getId() %></span>
    </div>

    <div class="form-card-body">
      <form id="editForm" action="ProductServlet" method="post" enctype="multipart/form-data">
        <input type="hidden" name="action" value="update">
        <input type="hidden" name="id" value="<%= product.getId() %>">
        <input type="hidden" name="finalprice" id="finalPriceHidden" value="<%= product.getFinalPrice() %>">

        <!-- ── BASIC INFO ── -->
        <div class="form-section">
          <div class="section-label"><i class="bi bi-info-circle"></i> Basic Information</div>
          <div class="row g-3">

            <!-- Name -->
            <div class="col-md-6" id="wrap-name">
              <label class="form-label"><i class="bi bi-box"></i> Product Name</label>
              <input type="text" name="name" class="form-control"
                     value="<%= product.getName() %>"
                     data-original="<%= product.getName() %>"
                     placeholder="Product name" required>
              <div class="changed-badge"><i class="bi bi-pencil"></i> Modified</div>
            </div>

            <!-- Category -->
            <div class="col-md-6" id="wrap-category">
              <label class="form-label"><i class="bi bi-tags"></i> Category</label>
              <select name="category" class="form-select" data-original="<%= cat %>" required>
                <option value="fruits"         <%= "fruits".equals(cat)         ? "selected" : "" %>>🍎 Fruits</option>
                <option value="vegetables"     <%= "vegetables".equals(cat)     ? "selected" : "" %>>🥦 Vegetables</option>
                <option value="packed_food"    <%= "packed_food".equals(cat)    ? "selected" : "" %>>📦 Packed Food</option>
                <option value="dairy_products" <%= "dairy_products".equals(cat) ? "selected" : "" %>>🥛 Dairy Products</option>
                <option value="fashion"        <%= "fashion".equals(cat)        ? "selected" : "" %>>👗 Fashion</option>
                <option value="books"          <%= "books".equals(cat)          ? "selected" : "" %>>📚 Books</option>
                <option value="electronics"    <%= "electronics".equals(cat)    ? "selected" : "" %>>📱 Electronics</option>
                <option value="home_furniture" <%= "home_furniture".equals(cat) ? "selected" : "" %>>🛋️ Home & Furniture</option>
                <option value="beauty"         <%= "beauty".equals(cat)         ? "selected" : "" %>>💄 Beauty & Personal Care</option>
                <option value="sports"         <%= "sports".equals(cat)         ? "selected" : "" %>>🏀 Sports & Fitness</option>
              </select>
              <div class="changed-badge"><i class="bi bi-pencil"></i> Modified</div>
            </div>

            <!-- Description -->
            <div class="col-12" id="wrap-description">
              <label class="form-label"><i class="bi bi-card-text"></i> Description</label>
              <textarea name="description" class="form-control"
                        data-original="<%= product.getDescription() != null ? product.getDescription().replace("\"", "&quot;") : "" %>"
                        placeholder="Product description…"><%= product.getDescription() != null ? product.getDescription() : "" %></textarea>
              <div class="changed-badge"><i class="bi bi-pencil"></i> Modified</div>
            </div>

          </div>
        </div>

        <!-- ── PRICING ── -->
        <div class="form-section">
          <div class="section-label"><i class="bi bi-currency-rupee"></i> Pricing</div>
          <div class="row g-3">

            <!-- MRP -->
            <div class="col-md-4" id="wrap-mrp">
              <label class="form-label"><i class="bi bi-currency-rupee"></i> MRP (₹)</label>
              <input type="number" step="0.01" name="mrp" id="mrp" class="form-control"
                     value="<%= product.getMrp() %>"
                     data-original="<%= product.getMrp() %>" required>
              <div class="changed-badge"><i class="bi bi-pencil"></i> Modified</div>
            </div>

            <!-- Discount -->
            <div class="col-md-4" id="wrap-discount">
              <label class="form-label"><i class="bi bi-percent"></i> Discount (%)</label>
              <input type="number" step="0.01" min="0" max="100" name="discount" id="discount"
                     class="form-control"
                     value="<%= product.getDiscount() %>"
                     data-original="<%= product.getDiscount() %>">
              <div class="changed-badge"><i class="bi bi-pencil"></i> Modified</div>
            </div>

            <!-- Final Price (display only) -->
            <div class="col-md-4">
              <label class="form-label"><i class="bi bi-cash-stack"></i> Final Price</label>
              <div class="final-price-display">
                <i class="bi bi-currency-rupee"></i>
                <span id="finalPriceDisplay"><%= String.format("%.2f", product.getFinalPrice()) %></span>
              </div>
              <div class="img-note">Auto-calculated · MRP minus Discount</div>
            </div>

            <!-- GST Rate — GST FIX -->
         <!-- GST Rate -->
			<div class="col-md-4" id="wrap-gstRate">
			  <label class="form-label"><i class="bi bi-receipt"></i> GST Rate (%)</label>
			  <select name="gstRate" class="form-select" data-original="<%= product.getGstRate() %>">
			
			    <option value="0"  <%= product.getGstRate()==0  ? "selected":"" %>>
			      0% — Exempt &nbsp;|&nbsp; 🍎 Fruits · 🥦 Vegetables · 📚 Books
			    </option>
			
			    <option value="5"  <%= product.getGstRate()==5  ? "selected":"" %>>
			      5% — Basic Food &nbsp;|&nbsp; 🥛 Dairy Products (milk, curd, paneer)
			    </option>
			
			    <option value="12" <%= product.getGstRate()==12 ? "selected":"" %>>
			      12% — Processed &nbsp;|&nbsp; 📦 Packed Food · 👗 Fashion (under ₹1000)
			    </option>
			
			    <option value="18" <%= product.getGstRate()==18 ? "selected":"" %>>
			      18% — General &nbsp;|&nbsp; 📱 Electronics · 🛋️ Home &amp; Furniture · 💄 Beauty · 🏀 Sports
			    </option>
			
			    <option value="28" <%= product.getGstRate()==28 ? "selected":"" %>>
			      28% — Luxury &nbsp;|&nbsp; Aerated drinks · Premium goods
			    </option>
			
			  </select>
			  <small style="font-size:0.72rem;color:var(--muted);">
			    <i class="bi bi-info-circle"></i>
			    Select the slab matching this product's category. Applied on final price at checkout per Indian GST law.
			  </small>
			</div>

          </div>
        </div>

        <!-- ── INVENTORY ── -->
        <div class="form-section">
          <div class="section-label"><i class="bi bi-layers"></i> Inventory</div>
          <div class="row g-3">

            <!-- Quantity -->
            <div class="col-md-3" id="wrap-quantity">
              <label class="form-label"><i class="bi bi-basket"></i> Quantity</label>
              <input type="number" name="quantity" class="form-control"
                     value="<%= product.getQuantity() %>"
                     data-original="<%= product.getQuantity() %>" required>
              <div class="changed-badge"><i class="bi bi-pencil"></i> Modified</div>
            </div>

            <!-- Unit -->
            <div class="col-md-3" id="wrap-unit">
              <label class="form-label"><i class="bi bi-rulers"></i> Unit</label>
              <select name="unit" class="form-select" data-original="<%= unit %>" required>
                <option value="kg"    <%= "kg".equals(unit)    ? "selected":"" %>>Kilogram (kg)</option>
                <option value="g"     <%= "g".equals(unit)     ? "selected":"" %>>Gram (g)</option>
                <option value="liter" <%= "liter".equals(unit) ? "selected":"" %>>Liter</option>
                <option value="ml"    <%= "ml".equals(unit)    ? "selected":"" %>>Milliliter (ml)</option>
                <option value="dozen" <%= "dozen".equals(unit) ? "selected":"" %>>Dozen</option>
                <option value="piece" <%= "piece".equals(unit) ? "selected":"" %>>Piece</option>
              </select>
              <div class="changed-badge"><i class="bi bi-pencil"></i> Modified</div>
            </div>

            <!-- Stock -->
            <div class="col-md-3" id="wrap-stock">
              <label class="form-label"><i class="bi bi-archive"></i> Stock Units</label>
              <input type="number" name="stock" id="stockInput" class="form-control"
                     value="<%= product.getStock() %>"
                     data-original="<%= product.getStock() %>" required>
              <div class="changed-badge"><i class="bi bi-pencil"></i> Modified</div>
            </div>

            <!-- Added Date -->
            <div class="col-md-3" id="wrap-addedDate">
              <label class="form-label"><i class="bi bi-calendar3"></i> Added Date</label>
              <input type="datetime-local" name="addedDate" class="form-control"
                     value="<%= addedDateValue %>"
                     data-original="<%= addedDateValue %>">
              <div class="changed-badge"><i class="bi bi-pencil"></i> Modified</div>
            </div>

          </div>
        </div>

        <!-- ── STATUS ── -->
        <div class="form-section">
          <div class="section-label"><i class="bi bi-toggle-on"></i> Status</div>
          <div class="row g-3">
            <div class="col-md-5">
              <label class="form-label"><i class="bi bi-circle"></i> Product Status</label>

              <!-- Hidden select — submitted to server -->
              <select name="status" id="statusSelect" class="form-select" style="display:none;">
                <option value="active"   <%= "active".equals(status)   ? "selected":"" %>>Active</option>
                <option value="inactive" <%= "inactive".equals(status) ? "selected":"" %>>Inactive</option>
              </select>

              <!-- Visual toggle -->
              <div class="status-toggle-wrap" id="statusToggle">
                <label class="status-option active-opt  <%= "active".equals(status)   ? "ring":"" %>"
                       id="optActive" onclick="setStatus('active')">
                  <i class="bi bi-check-circle-fill"></i> Active
                </label>
                <label class="status-option inactive-opt <%= "inactive".equals(status) ? "ring":"" %>"
                       id="optInactive" onclick="setStatus('inactive')">
                  <i class="bi bi-x-circle-fill"></i> Inactive
                </label>
              </div>
              <div class="status-hint" id="statusHint">
                <% if (product.getStock() == 0) { %>
                  <span style="color:var(--warning);">
                    <i class="bi bi-exclamation-triangle"></i>
                    Stock is 0 — status will be forced to <strong>Inactive</strong>
                  </span>
                <% } else { %>
                  Set to Inactive to hide from customers without deleting.
                <% } %>
              </div>
            </div>
          </div>
        </div>

        <!-- ── IMAGE ── -->
        <div class="form-section">
          <div class="section-label"><i class="bi bi-image"></i> Product Image</div>
          <div class="image-row">
            <div class="image-preview-box">
              <img id="preview"
                   src="<%= product.getImageUrl() != null ? product.getImageUrl() : "images/default.png" %>"
                   alt="Product Image"
                   onerror="this.src='images/default.png'">
              <div class="img-overlay"><i class="bi bi-eye"></i></div>
            </div>
            <div class="image-upload-wrap">
              <label class="form-label"><i class="bi bi-upload"></i> Upload New Image</label>
              <input type="file" name="imageFile" id="imageFile" class="form-control" accept="image/*">
              <div class="img-note">
                <i class="bi bi-info-circle"></i>
                Leave empty to keep existing image. Max 5MB, JPG/PNG/WEBP.
              </div>
              <% if (product.getImageUrl() != null) { %>
              <div class="img-note" style="margin-top:4px;">
                <i class="bi bi-link-45deg"></i> Current: <%= product.getImageUrl() %>
              </div>
              <% } %>
            </div>
          </div>
        </div>

        <!-- ── ACTIONS ── -->
        <div class="form-actions">
          <a href="ProductServlet?action=add" class="btn-back-link">
            <i class="bi bi-arrow-left"></i> Back
          </a>
          <div class="changes-summary">
            <i class="bi bi-pencil-square" style="color:var(--warning);"></i>
            <span id="changeCount">0</span> field(s) modified
          </div>
          <button type="submit" class="btn-save" id="saveBtn">
            <i class="bi bi-check-circle"></i> Update Product
          </button>
        </div>

      </form>
    </div>
  </div>
</div>

<!-- ── FOOTER ── -->
<footer>
  <p class="mb-0">&copy; 2026 <span>Smart Inventory</span> &nbsp;|&nbsp; Administrator Portal</p>
</footer>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
<script>
/* ── Status toggle ── */
function setStatus(val) {
  document.getElementById('statusSelect').value = val;
  const optA = document.getElementById('optActive');
  const optI = document.getElementById('optInactive');
  if (val === 'active') {
    optA.style.borderColor = 'var(--success)';
    optA.style.background  = 'rgba(16,185,129,0.1)';
    optI.style.borderColor = 'var(--border)';
    optI.style.background  = 'var(--white)';
    optI.style.color       = 'var(--muted)';
    optA.style.color       = 'var(--success)';
  } else {
    optI.style.borderColor = 'var(--danger)';
    optI.style.background  = 'rgba(239,68,68,0.08)';
    optA.style.borderColor = 'var(--border)';
    optA.style.background  = 'var(--white)';
    optA.style.color       = 'var(--muted)';
    optI.style.color       = 'var(--danger)';
  }
}

/* Set initial visual state */
setStatus('<%= status %>');

/* ── Disable status toggle when stock is 0 ── */
const stockInput = document.getElementById('stockInput');
function checkStock() {
  const s = parseInt(stockInput.value) || 0;
  const toggle = document.getElementById('statusToggle');
  const hint   = document.getElementById('statusHint');
  if (s === 0) {
    toggle.style.opacity = '0.5';
    toggle.style.pointerEvents = 'none';
    setStatus('inactive');
    hint.innerHTML = '<span style="color:var(--warning);"><i class="bi bi-exclamation-triangle"></i> Stock is 0 — status forced to <strong>Inactive</strong></span>';
  } else {
    toggle.style.opacity = '1';
    toggle.style.pointerEvents = 'auto';
    hint.innerHTML = 'Set to Inactive to hide from customers without deleting.';
  }
}
stockInput.addEventListener('input', checkStock);
checkStock(); // run on load

/* ── Final price auto-calc ── */
const mrpInput      = document.getElementById('mrp');
const discountInput = document.getElementById('discount');
const finalDisplay  = document.getElementById('finalPriceDisplay');
const finalHidden   = document.getElementById('finalPriceHidden');

function calcFinalPrice() {
  const mrp  = parseFloat(mrpInput.value)      || 0;
  const disc = parseFloat(discountInput.value) || 0;
  const fp   = (mrp - mrp * disc / 100).toFixed(2);
  finalDisplay.textContent = fp;
  finalHidden.value        = fp;
}
mrpInput.addEventListener('input', calcFinalPrice);
discountInput.addEventListener('input', calcFinalPrice);

/* ── Image preview ── */
document.getElementById('imageFile').addEventListener('change', function() {
  const file = this.files[0];
  if (file) {
    const preview = document.getElementById('preview');
    preview.style.opacity = '0';
    preview.src = URL.createObjectURL(file);
    preview.onload = function() {
      preview.style.transition = 'opacity 0.3s';
      preview.style.opacity = '1';
    };
  }
});

/* ── Change detection (highlights modified fields) ── */
let changeCount = 0;
function updateChangeCount() {
  changeCount = document.querySelectorAll('.field-changed').length;
  document.getElementById('changeCount').textContent = changeCount;
}

document.querySelectorAll('[data-original]').forEach(function(el) {
  const wrap = el.closest('[id^="wrap-"]');
  el.addEventListener('input', function() {
    if (!wrap) return;
    const changed = el.value !== el.dataset.original;
    wrap.classList.toggle('field-changed', changed);
    updateChangeCount();
  });
  el.addEventListener('change', function() {
    if (!wrap) return;
    const changed = el.value !== el.dataset.original;
    wrap.classList.toggle('field-changed', changed);
    updateChangeCount();
  });
});

/* ── Error auto-dismiss ── */
const errAlert = document.getElementById('errorAlert');
if (errAlert) {
  setTimeout(function() {
    errAlert.style.transition = 'opacity 0.5s';
    errAlert.style.opacity = '0';
    setTimeout(function() { errAlert.remove(); }, 500);
  }, 5000);
}
</script>
</body>
</html>
