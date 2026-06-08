<%@ page import="java.util.*" %>
<%@ page import="com.util.Product" %>
<%@ page contentType="text/html; charset=UTF-8" %>

<%
    String role  = (session != null) ? (String) session.getAttribute("role") : null;
    String uname = (session != null) ? (String) session.getAttribute("username") : null;
    if (role == null || !"admin".equalsIgnoreCase(role)) {
        response.sendRedirect("index.jsp?error=Access denied. Please login as admin.");
        return;
    }

    List<Product> products    = (List<Product>) request.getAttribute("products");
    String success            = request.getParameter("success");
    String updatedId          = request.getParameter("id");
    String updatedFields      = request.getParameter("fields");
    Set<String> fieldSet      = new HashSet<>();
    if (updatedFields != null) {
        fieldSet.addAll(Arrays.asList(updatedFields.split(",")));
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Product Management — Smart Inventory</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
<link href="https://cdn.jsdelivr.net/npm/bootstrap-icons/font/bootstrap-icons.css" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=Nunito:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
<style>
  :root {
    --primary:      #0ea5e9;
    --primary-dark: #0369a1;
    --primary-mid:  #0284c7;
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
    border-bottom: none;
    display: flex; align-items: center;
    padding: 0 1.75rem; gap: 1.25rem;
    box-shadow: 0 2px 16px rgba(14,165,233,.25);
  }
  .nav-brand {
    font-family: 'Nunito', sans-serif;
    font-size: 1.2rem; font-weight: 800;
    color: #fff; text-decoration: none;
    letter-spacing: 0.5px;
    display: flex; align-items: center; gap: 0.5rem;
  }
  .nav-brand .brand-accent { color: #bae6fd; }
  .nav-divider { width: 1px; height: 24px; background: rgba(255,255,255,0.15); }
  .nav-page-label {
    font-size: 0.82rem; color: rgba(255,255,255,0.55);
    font-weight: 400;
  }
  .nav-right { margin-left: auto; display: flex; align-items: center; gap: 0.85rem; }
  .nav-user {
    display: flex; align-items: center; gap: 0.5rem;
    font-size: 0.85rem; color: rgba(255,255,255,0.75);
  }
  .nav-avatar {
    width: 32px; height: 32px; border-radius: 50%;
    background: var(--accent);
    display: flex; align-items: center; justify-content: center;
    font-weight: 700; font-size: 0.82rem; color: var(--primary);
    flex-shrink: 0;
  }
  .nav-role {
    background: rgba(255,255,255,0.18);
    border: 1px solid rgba(255,255,255,0.35);
    color: #fff; font-size: 0.72rem; font-weight: 600;
    padding: 2px 10px; border-radius: 20px;
    text-transform: capitalize;
  }
  .nav-btn {
    display: inline-flex; align-items: center; gap: 0.35rem;
    padding: 0.4rem 1rem; border-radius: 8px;
    font-size: 0.83rem; font-weight: 500;
    text-decoration: none; cursor: pointer;
    border: 1px solid rgba(255,255,255,0.2);
    color: rgba(255,255,255,0.8);
    background: rgba(255,255,255,0.07);
    transition: all 0.18s;
    font-family: 'Nunito', sans-serif;
  }
  .nav-btn:hover { background: rgba(255,255,255,0.15); color: #fff; }

  /* ── PAGE HEADER ── */
  .page-header {
    background: var(--white);
    border-bottom: 1px solid var(--border);
    padding: 1rem 1.75rem;
    display: flex; align-items: center; justify-content: space-between;
    flex-wrap: wrap; gap: 0.75rem;
    position: sticky; top: var(--nav-h); z-index: 100;
    box-shadow: var(--shadow-sm);
  }
  .page-title {
    font-family: 'Playfair Display', serif;
    font-size: 1.25rem; font-weight: 700; color: var(--primary);
    display: flex; align-items: center; gap: 0.6rem;
  }
  .page-title-bar {
    width: 4px; height: 1.2em;
    background: var(--accent); border-radius: 2px;
  }
  .header-controls { display: flex; align-items: center; gap: 0.65rem; flex-wrap: wrap; }

  .search-wrap {
    display: flex; align-items: center; gap: 0.4rem;
    background: var(--bg); border: 1.5px solid var(--border);
    border-radius: 9px; padding: 0.38rem 0.8rem;
    transition: border-color 0.2s;
  }
  .search-wrap:focus-within { border-color: var(--primary); }
  .search-wrap i { color: var(--muted); font-size: 0.88rem; }
  .search-wrap input {
    border: none; background: transparent; outline: none;
    font-family: 'Nunito', sans-serif; font-size: 0.85rem;
    color: var(--text); width: 200px;
  }
  .search-wrap input::placeholder { color: var(--muted); }

  .sort-select {
    background: var(--bg); border: 1.5px solid var(--border);
    border-radius: 9px; padding: 0.38rem 0.8rem;
    font-family: 'Nunito', sans-serif; font-size: 0.85rem;
    color: var(--text); outline: none; cursor: pointer;
    transition: border-color 0.2s;
  }
  .sort-select:focus { border-color: var(--primary); }

  .btn-primary-accent {
    display: inline-flex; align-items: center; gap: 0.4rem;
    background: var(--primary); color: #fff;
    border: none; border-radius: 9px;
    padding: 0.42rem 1.1rem; font-size: 0.85rem; font-weight: 600;
    cursor: pointer; text-decoration: none; font-family: 'Nunito', sans-serif;
    transition: all 0.2s;
  }
  .btn-primary-accent:hover { background: #0d0f1f; color: #fff; transform: translateY(-1px); box-shadow: 0 4px 12px rgba(26,26,46,0.2); }

  .btn-back {
    display: inline-flex; align-items: center; gap: 0.4rem;
    background: var(--white); color: var(--text-mid);
    border: 1.5px solid var(--border); border-radius: 9px;
    padding: 0.42rem 1rem; font-size: 0.85rem; font-weight: 500;
    cursor: pointer; text-decoration: none; font-family: 'Nunito', sans-serif;
    transition: all 0.18s;
  }
  .btn-back:hover { background: var(--bg); color: var(--text); }

  /* ── STATS ── */
  .stats-row {
    display: flex; gap: 1rem; flex-wrap: wrap;
    padding: 1rem 1.75rem;
    background: var(--white);
    border-bottom: 1px solid var(--border);
  }
  .stat-card {
    display: flex; align-items: center; gap: 0.65rem;
    background: var(--bg); border: 1px solid var(--border);
    border-radius: 10px; padding: 0.6rem 1rem;
    flex: 1; min-width: 140px;
  }
  .stat-icon {
    width: 36px; height: 36px; border-radius: 9px;
    display: flex; align-items: center; justify-content: center;
    font-size: 1rem; flex-shrink: 0;
  }
  .stat-icon.total   { background: rgba(26,26,46,0.08);  color: var(--primary); }
  .stat-icon.active  { background: rgba(16,185,129,0.1); color: var(--success); }
  .stat-icon.deleted { background: rgba(239,68,68,0.1);  color: var(--danger); }
  .stat-icon.low     { background: rgba(245,158,11,0.1); color: var(--warning); }
  .stat-val { font-size: 1.3rem; font-weight: 700; color: var(--primary); line-height: 1; }
  .stat-label { font-size: 0.72rem; color: var(--muted); margin-top: 2px; }

  /* ── TABLE SECTION ── */
  .table-section { padding: 1.25rem 1.75rem; }

  .table-card {
    background: var(--white);
    border: 1px solid var(--border);
    border-radius: var(--radius);
    box-shadow: var(--shadow-sm);
    overflow: hidden;
  }
  .table-toolbar {
    padding: 0.9rem 1.25rem;
    border-bottom: 1px solid var(--border);
    display: flex; align-items: center; justify-content: space-between;
    flex-wrap: wrap; gap: 0.5rem;
    background: var(--bg);
  }
  .table-toolbar-title { font-size: 0.8rem; color: var(--muted); }
  .table-toolbar-title strong { color: var(--text); }

  /* Filter chips */
  .filter-chips { display: flex; gap: 0.4rem; flex-wrap: wrap; }
  .fchip {
    padding: 3px 12px; border-radius: 20px;
    font-size: 0.73rem; font-weight: 500;
    border: 1.5px solid var(--border);
    background: var(--white); color: var(--muted);
    cursor: pointer; transition: all 0.15s;
  }
  .fchip.active, .fchip:hover { background: var(--primary); color: #fff; border-color: var(--primary); box-shadow: 0 2px 8px rgba(14,165,233,.2); }
  .fchip.deleted-chip.active { background: var(--danger); border-color: var(--danger); }

  .table-responsive { overflow-x: auto; }

  table {
    width: 100%; border-collapse: collapse;
    font-size: 0.875rem;
  }
  thead th {
    background: var(--primary-dark);
    color: rgba(255,255,255,0.9);
    font-size: 0.72rem; font-weight: 600;
    text-transform: uppercase; letter-spacing: 0.08em;
    padding: 0.85rem 0.9rem; white-space: nowrap;
    text-align: left;
  }
  thead th:first-child { padding-left: 1.25rem; }
  thead th:last-child  { text-align: center; }

  tbody tr {
    border-bottom: 1px solid var(--border);
    transition: background 0.15s;
    animation: rowFade 0.25s ease both;
  }
  @keyframes rowFade { from{opacity:0; transform:translateY(4px);} to{opacity:1; transform:none;} }
  tbody tr:last-child { border-bottom: none; }
  tbody tr:hover td { background: var(--bg); }
  tbody tr.row-deleted td { background: rgba(239,68,68,0.03); }
  tbody tr.row-deleted:hover td { background: rgba(239,68,68,0.06); }

  td {
    padding: 0.8rem 0.9rem; color: var(--text);
    vertical-align: middle;
  }
  td:first-child { padding-left: 1.25rem; }
  td:last-child  { text-align: center; }

  /* ── BLINK ANIMATIONS ── */
  .blink-field { animation: blinkCell 3s linear 2; }
  @keyframes blinkCell {
    0%   { background-color: #d1fae5; }
    50%  { background-color: transparent; }
    75%  { background-color: #d1fae5; }
    100% { background-color: transparent; }
  }
  .blink-row { animation: blinkRow 1s ease-in-out 2; }
  @keyframes blinkRow {
    0%,100% { background-color: #fef3c7; }
    50%     { background-color: transparent; }
  }

  /* ── CELL STYLES ── */
  .product-cell { display: flex; align-items: center; gap: 0.65rem; }
  .product-thumb {
    width: 44px; height: 44px; border-radius: 8px;
    object-fit: cover; border: 1px solid var(--border);
    background: var(--bg); flex-shrink: 0;
  }
  .product-name { font-weight: 600; font-size: 0.88rem; color: var(--primary); }
  .product-deleted-tag {
    display: inline-flex; align-items: center; gap: 0.25rem;
    font-size: 0.65rem; color: var(--danger);
    background: rgba(239,68,68,0.08); border: 1px solid rgba(239,68,68,0.2);
    border-radius: 4px; padding: 1px 5px; margin-left: 0.35rem;
    vertical-align: middle;
  }

  .badge-cat {
    background: rgba(26,26,46,0.07); color: var(--primary);
    border: 1px solid rgba(26,26,46,0.1);
    border-radius: 6px; padding: 3px 9px;
    font-size: 0.72rem; font-weight: 600; white-space: nowrap;
  }

  .price-mrp { color: var(--muted); text-decoration: line-through; font-size: 0.8rem; }
  .price-final { font-weight: 700; color: var(--primary); }

  .disc-badge {
    background: rgba(16,185,129,0.1); color: var(--success);
    border: 1px solid rgba(16,185,129,0.2);
    border-radius: 5px; padding: 2px 8px;
    font-size: 0.73rem; font-weight: 700;
  }

  .stock-wrap { display: flex; flex-direction: column; gap: 3px; }
  .stock-num { font-weight: 700; font-size: 0.88rem; }
  .stock-num.green { color: var(--success); }
  .stock-num.amber { color: var(--warning); }
  .stock-num.red   { color: var(--danger); }
  .stock-bar { height: 4px; border-radius: 4px; background: #e5e7eb; width: 60px; overflow: hidden; }
  .stock-fill { height: 100%; border-radius: 4px; }
  .stock-fill.green { background: var(--success); }
  .stock-fill.amber { background: var(--warning); }
  .stock-fill.red   { background: var(--danger); width: 100% !important; }

  .status-pill {
    display: inline-flex; align-items: center; gap: 0.3rem;
    border-radius: 20px; padding: 3px 10px;
    font-size: 0.72rem; font-weight: 700;
  }
  .status-pill .dot { width: 6px; height: 6px; border-radius: 50%; }
  .status-pill.active   { background: rgba(16,185,129,0.1); color: var(--success); border: 1px solid rgba(16,185,129,0.25); }
  .status-pill.active .dot { background: var(--success); }
  .status-pill.inactive { background: rgba(239,68,68,0.08); color: var(--danger);  border: 1px solid rgba(239,68,68,0.2); }
  .status-pill.inactive .dot { background: var(--danger); }
  .status-pill.deleted  { background: rgba(107,114,128,0.08); color: var(--muted); border: 1px solid rgba(107,114,128,0.2); }
  .status-pill.deleted .dot { background: var(--muted); }

  .desc-cell {
    max-width: 180px; overflow: hidden;
    white-space: nowrap; text-overflow: ellipsis;
    font-size: 0.8rem; color: var(--muted);
  }
  .date-cell { font-size: 0.78rem; color: var(--muted); white-space: nowrap; }

  /* ── ACTION BUTTONS ── */
  .actions-cell { display: flex; align-items: center; justify-content: center; gap: 0.35rem; flex-wrap: nowrap; }
  .act-btn {
    display: inline-flex; align-items: center; gap: 0.28rem;
    padding: 0.38rem 0.7rem; border-radius: 7px;
    font-size: 0.76rem; font-weight: 600;
    cursor: pointer; border: 1.5px solid transparent;
    text-decoration: none; white-space: nowrap;
    transition: all 0.18s; font-family: 'Nunito', sans-serif;
  }
  .act-btn i { font-size: 0.8rem; }
  .act-edit    { background: rgba(59,130,246,0.08); color: var(--info);    border-color: rgba(59,130,246,0.2); }
  .act-edit:hover    { background: var(--info); color: #fff; }
  .act-soft    { background: rgba(245,158,11,0.08); color: var(--warning); border-color: rgba(245,158,11,0.2); }
  .act-soft:hover    { background: var(--warning); color: #fff; }
  .act-hard    { background: rgba(239,68,68,0.08);  color: var(--danger);  border-color: rgba(239,68,68,0.2); }
  .act-hard:hover    { background: var(--danger); color: #fff; }
  .act-restore { background: rgba(16,185,129,0.08); color: var(--success); border-color: rgba(16,185,129,0.2); }
  .act-restore:hover { background: var(--success); color: #fff; }

  /* ── EMPTY STATE ── */
  .empty-state { text-align: center; padding: 4rem 2rem; color: var(--muted); }
  .empty-state i { font-size: 3rem; opacity: 0.3; display: block; margin-bottom: 0.75rem; }
  .empty-state h5 { color: var(--text-mid); margin-bottom: 0.4rem; }

  /* ── MODALS ── */
  .modal-content {
    border: none; border-radius: 16px;
    box-shadow: var(--shadow-lg);
    overflow: hidden;
  }
  .modal-header {
    background: linear-gradient(135deg, var(--primary) 0%, var(--primary-dark) 100%);
    color: #fff; border: none;
    padding: 1.1rem 1.5rem;
  }
  .modal-header .modal-title {
    font-family: 'Playfair Display', serif;
    font-size: 1.05rem; font-weight: 700;
    display: flex; align-items: center; gap: 0.5rem;
  }
  .modal-header .btn-close { filter: brightness(0) invert(1); }
  .modal-body { padding: 1.5rem; }
  .modal-footer { padding: 1rem 1.5rem; border-top: 1px solid var(--border); }

  /* Add Product Form */
  .form-label {
    font-size: 0.82rem; font-weight: 600; color: var(--text-mid);
    margin-bottom: 0.35rem; display: flex; align-items: center; gap: 0.3rem;
  }
  .form-control, .form-select {
    border: 1.5px solid var(--border); border-radius: 9px;
    font-family: 'Nunito', sans-serif; font-size: 0.88rem;
    color: var(--text); background: var(--white);
    padding: 0.5rem 0.85rem; transition: border-color 0.18s;
  }
  .form-control:focus, .form-select:focus {
    border-color: var(--primary); box-shadow: 0 0 0 3px rgba(14,165,233,0.15);
  }
  .form-control.readonly-field { background: var(--bg); color: var(--primary); font-weight: 700; }
  .form-control::placeholder { color: var(--muted); }

  .img-preview-box {
    width: 100px; height: 100px; border-radius: 10px;
    border: 2px dashed var(--border); background: var(--bg);
    display: flex; align-items: center; justify-content: center;
    overflow: hidden; margin-top: 0.5rem;
  }
  .img-preview-box img { width: 100%; height: 100%; object-fit: cover; display: none; }
  .img-preview-placeholder { font-size: 0.72rem; color: var(--muted); text-align: center; padding: 0.5rem; }

  .final-price-badge {
    background: rgba(16,185,129,0.1); border: 1.5px solid rgba(16,185,129,0.25);
    border-radius: 9px; padding: 0.5rem 0.85rem;
    font-weight: 700; font-size: 1rem; color: var(--success);
    display: flex; align-items: center; gap: 0.3rem;
  }

  .btn-save {
    background: var(--primary); color: #fff; border: none;
    padding: 0.6rem 1.5rem; border-radius: 9px;
    font-family: 'Nunito', sans-serif; font-size: 0.88rem; font-weight: 600;
    cursor: pointer; display: inline-flex; align-items: center; gap: 0.4rem;
    transition: all 0.2s;
  }
  .btn-save:hover { background: #0d0f1f; transform: translateY(-1px); box-shadow: 0 4px 12px rgba(26,26,46,0.2); }

  /* Delete choice modal */
  .delete-choice-box {
    display: flex; gap: 1rem; flex-direction: column;
  }
  .delete-option {
    border: 1.5px solid var(--border); border-radius: 12px;
    padding: 1rem 1.25rem;
    display: flex; align-items: flex-start; gap: 0.85rem;
    cursor: pointer; transition: all 0.18s;
    text-decoration: none;
  }
  .delete-option:hover { border-color: currentColor; }
  .delete-option.soft:hover { border-color: var(--warning); background: rgba(245,158,11,0.04); }
  .delete-option.hard:hover { border-color: var(--danger);  background: rgba(239,68,68,0.04); }
  .del-opt-icon {
    width: 40px; height: 40px; border-radius: 10px;
    display: flex; align-items: center; justify-content: center;
    font-size: 1.15rem; flex-shrink: 0;
  }
  .del-opt-icon.soft { background: rgba(245,158,11,0.12); color: var(--warning); }
  .del-opt-icon.hard { background: rgba(239,68,68,0.1);   color: var(--danger); }
  .del-opt-title { font-weight: 700; font-size: 0.9rem; margin-bottom: 0.2rem; }
  .del-opt-title.soft { color: var(--warning); }
  .del-opt-title.hard { color: var(--danger); }
  .del-opt-desc { font-size: 0.8rem; color: var(--muted); line-height: 1.5; }

  /* ── TOAST ── */
  .toast-container { position: fixed; bottom: 1.5rem; right: 1.5rem; z-index: 9999; }
  .toast-item {
    background: var(--white); border: 1px solid var(--border);
    border-radius: 12px; padding: 0.85rem 1.1rem;
    display: flex; align-items: center; gap: 0.6rem;
    font-size: 0.88rem; font-weight: 500; color: var(--text);
    box-shadow: var(--shadow-lg); min-width: 260px;
    animation: toastIn 0.3s ease;
  }
  @keyframes toastIn { from{opacity:0;transform:translateX(20px);} to{opacity:1;transform:none;} }
  .toast-item.success { border-left: 3px solid var(--success); }
  .toast-item.error   { border-left: 3px solid var(--danger); }
  .ti-icon { font-size: 1.1rem; }
  .ti-icon.success { color: var(--success); }
  .ti-icon.error   { color: var(--danger); }

  /* ── FOOTER ── */
  footer {
    background: var(--primary-dark);
    border-top: none;
    color: rgba(255,255,255,0.65);
    font-size: 0.8rem; text-align: center;
    padding: 1rem; margin-top: 2rem;
  }
  footer span { color: #bae6fd; }

  @media(max-width: 768px) {
    .stats-row { gap: 0.5rem; }
    .stat-card  { min-width: 120px; }
    .search-wrap input { width: 140px; }
    .table-section { padding: 1rem; }
  }
</style>
</head>
<body>

<!-- ══ NAVBAR ══ -->
<div class="top-navbar">
  <a class="nav-brand" href="dashboard.jsp">
    <i class="bi bi-boxes"></i>
    Smart<span class="brand-accent">Inventory</span>
  </a>
  <div class="nav-divider"></div>
  <span class="nav-page-label">Product Management</span>
  <div class="nav-right">
    <div class="nav-user">
      <div class="nav-avatar"><%= uname != null ? String.valueOf(uname.charAt(0)).toUpperCase() : "A" %></div>
      <span><%= uname %></span>
    </div>
    <span class="nav-role"><%= role %></span>
    <a href="logout" class="nav-btn"><i class="bi bi-box-arrow-right"></i> Logout</a>
  </div>
</div>

<!-- ══ PAGE HEADER ══ -->
<div class="page-header">
  <div class="page-title">
    <div class="page-title-bar"></div>
    All Products
  </div>
  <div class="header-controls">
    <!-- Search -->
    <div class="search-wrap">
      <i class="bi bi-search"></i>
      <input type="text" id="searchQuery" placeholder="Search products…">
    </div>
    <!-- Sort -->
    <select class="sort-select" id="sortBy">
      <option value="">Sort by…</option>
      <option value="name">Name</option>
      <option value="category">Category</option>
      <option value="mrp">MRP</option>
      <option value="discount">Discount</option>
      <option value="stock">Stock</option>
    </select>
    <!-- Add -->
    <button class="btn-primary-accent" data-bs-toggle="modal" data-bs-target="#addProductModal">
      <i class="bi bi-plus-lg"></i> Add Product
    </button>
    <a href="dashboard.jsp?section=products" class="btn-back">
      <i class="bi bi-arrow-left"></i> Back to Products
    </a>
  </div>
</div>

<!-- ══ STATS ══ -->
<%
  int totalC = 0, activeC = 0, deletedC = 0, lowC = 0;
  if (products != null) {
    totalC = products.size();
    for (Product p : products) {
      boolean isDel = p.getDeletedAt() != null;
      if (!isDel && "active".equalsIgnoreCase(p.getStatus())) activeC++;
      if (isDel) deletedC++;
      if (!isDel && p.getStock() >= 0 && p.getStock() <= 10) lowC++;
    }
  }
%>
<div class="stats-row">
  <div class="stat-card">
    <div class="stat-icon total"><i class="bi bi-box-seam"></i></div>
    <div><div class="stat-val"><%= totalC %></div><div class="stat-label">Total Products</div></div>
  </div>
  <div class="stat-card">
    <div class="stat-icon active"><i class="bi bi-check-circle"></i></div>
    <div><div class="stat-val" style="color:var(--success);"><%= activeC %></div><div class="stat-label">Active</div></div>
  </div>
  <div class="stat-card">
    <div class="stat-icon deleted"><i class="bi bi-trash"></i></div>
    <div><div class="stat-val" style="color:var(--danger);"><%= deletedC %></div><div class="stat-label">Soft Deleted</div></div>
  </div>
  <div class="stat-card">
    <div class="stat-icon low"><i class="bi bi-exclamation-triangle"></i></div>
    <div><div class="stat-val" style="color:var(--warning);"><%= lowC %></div><div class="stat-label">Low Stock</div></div>
  </div>
</div>

<!-- ══ TABLE ══ -->
<div class="table-section">
  <div class="table-card">

    <!-- Toolbar -->
    <div class="table-toolbar">
      <div class="table-toolbar-title">
        Showing <strong id="visibleCount"><%= products != null ? products.size() : 0 %></strong> products
      </div>
      <div class="filter-chips">
        <span class="fchip active" data-filter="all">All</span>
        <span class="fchip" data-filter="active">Active</span>
        <span class="fchip" data-filter="inactive">Inactive</span>
          <span class="fchip lowstock-chip" data-filter="lowstock">Low Stock</span>
        <span class="fchip deleted-chip" data-filter="deleted">Show Deleted</span>
      </div>
    </div>

    <% if (products == null || products.isEmpty()) { %>
    <div class="empty-state">
      <i class="bi bi-box-seam"></i>
      <h5>No products yet</h5>
      <p>Click "Add Product" to get started.</p>
    </div>
    <% } else { %>
    <div class="table-responsive">
    <table id="productsTable">
      <thead>
        <tr>
          <th>#</th>
          <th><i class="bi bi-box-seam me-1"></i>Product</th>
          <th><i class="bi bi-tags me-1"></i>Category</th>
          <th><i class="bi bi-currency-rupee me-1"></i>MRP</th>
          <th><i class="bi bi-cash-stack me-1"></i>Price</th>
          <th><i class="bi bi-percent me-1"></i>Disc.</th>
          <th><i class="bi bi-receipt me-1"></i>GST%</th>
          <th><i class="bi bi-basket me-1"></i>Package</th>
          <th><i class="bi bi-layers me-1"></i>Stock</th>
          <th><i class="bi bi-calendar3 me-1"></i>Added</th>
          <th><i class="bi bi-circle me-1"></i>Status</th>
          <th><i class="bi bi-gear me-1"></i>Actions</th>
        </tr>
      </thead>
      <tbody id="productsTbody">
      <%
        int rowNum = 0;
        for (Product p : products) {
          rowNum++;
          boolean isDeleted = p.getDeletedAt()!=null;          int stock = p.getStock();
          String stockClass = stock == 0 ? "red" : stock <= 10 ? "amber" : "green";
          double stockPct   = Math.min(100.0, (stock / 100.0) * 100);
          String statusKey  = isDeleted ? "deleted" : p.getStatus().toLowerCase();
          boolean isUpdated = String.valueOf(p.getId()).equals(updatedId);
          String safeName   = p.getName().replace("'", "&#39;");
      %>
        <tr class="product-row <%= isDeleted ? "row-deleted" : "" %> <%= isUpdated && !isDeleted ? "blink-row" : "" %>"
            id="row-<%= p.getId() %>"
            data-status="<%= statusKey %>"
            data-name="<%= p.getName().toLowerCase() %>"
            data-category="<%= p.getCategory().toLowerCase() %>"
          data-stock="<%= p.getStock() %>">
          <td style="color:var(--muted);font-size:0.78rem;"><%= rowNum %></td>

          <!-- Product -->
          <td class="<%= (fieldSet.contains("name") && isUpdated) ? "blink-field" : "" %>">
            <div class="product-cell">
              <img src="<%= p.getImageUrl() != null ? p.getImageUrl() : "images/default.png" %>"
                   class="product-thumb" alt="<%= p.getName() %>"
                   onerror="this.src='images/default.png'">
              <div>
                <div class="product-name">
                  <%= p.getName() %>
                  <% if (isDeleted) { %>
                    <span class="product-deleted-tag"><i class="bi bi-trash3"></i> deleted</span>
                  <% } %>
                </div>
              </div>
            </div>
          </td>

          <!-- Category -->
          <td class="<%= (fieldSet.contains("category") && isUpdated) ? "blink-field" : "" %>">
            <span class="badge-cat"><%= p.getCategory().replace("_"," ") %></span>
          </td>

          <!-- MRP -->
          <td class="<%= (fieldSet.contains("mrp") && isUpdated) ? "blink-field" : "" %>">
            <span class="price-mrp">₹<%= String.format("%.0f", p.getMrp()) %></span>
          </td>

          <!-- Final Price -->
          <td><span class="price-final">₹<%= String.format("%.0f", p.getFinalPrice()) %></span></td>

          <!-- Discount -->
          <td class="<%= (fieldSet.contains("discount") && isUpdated) ? "blink-field" : "" %>">
            <% if (p.getDiscount() > 0) { %>
              <span class="disc-badge"><%= (int)p.getDiscount() %>%</span>
            <% } else { %><span style="color:var(--muted);">—</span><% } %>
          </td>

          <!-- GST Rate Badge -->
          <td style="white-space:nowrap;">
            <span style="background:rgba(59,130,246,0.08);color:#3b82f6;border:1px solid rgba(59,130,246,0.2);border-radius:5px;padding:2px 8px;font-size:0.73rem;font-weight:700;">
              <%= (int)p.getGstRate() %>%
            </span>
          </td>

          <!-- Package -->
          <td class="<%= (fieldSet.contains("quantity") && isUpdated) ? "blink-field" : "" %>"
              style="font-size:0.82rem;color:var(--muted);">
            <%= p.getQuantity() %> <%= p.getUnit() %>
          </td>

          <!-- Stock -->
          <td class="<%= (fieldSet.contains("stock") && isUpdated) ? "blink-field" : "" %>">
            <div class="stock-wrap">
              <span class="stock-num <%= stockClass %>"><%= stock %> units</span>
              <div class="stock-bar">
                <div class="stock-fill <%= stockClass %>"
                     style="width:<%= stock==0 ? "100" : Math.max(6, stockPct) %>%;"></div>
              </div>
            </div>
          </td>

          <!-- Added Date -->
          <td class="date-cell <%= (fieldSet.contains("addedDate") && isUpdated) ? "blink-field" : "" %>">
            <%= new java.text.SimpleDateFormat("dd MMM yyyy").format(p.getAddedDate()) %><br>
            <span style="font-size:0.7rem;color:var(--muted);">
              <%= new java.text.SimpleDateFormat("hh:mm a").format(p.getAddedDate()) %>
            </span>
          </td>

          <!-- Status -->
 <td class="<%= (fieldSet.contains("status") && isUpdated) ? "blink-field" : "" %>">
            <span class="status-pill <%= statusKey %>">
              <span class="dot"></span>
              <%= isDeleted ? "Deleted" : p.getStatus() %>
            </span>
          </td>

           <!-- Actions -->
          <td>
            <div class="actions-cell">
              <% if (p.getDeletedAt()==null) { %>
                <a href="ProductServlet?action=edit&id=<%= p.getId() %>" class="act-btn act-edit">
                  <i class="bi bi-pencil-square"></i> 
                </a>
                <button class="act-btn act-soft"
                        data-id="<%= p.getId() %>"
                        data-name="<%= safeName %>"
                        onclick="openDeleteModal(<%= p.getId() %>, '<%= safeName %>')">
                  <i class="bi bi-archive"></i> 
                </button>
                <button class="act-btn act-hard"
                        onclick="confirmHardDelete(<%= p.getId() %>, '<%= safeName %>')">
                  <i class="bi bi-trash3"></i> 
                </button>
              <% } else { %>
                <a href="ProductServlet?action=restore&id=<%= p.getId() %>" class="act-btn act-restore">
                  <i class="bi bi-arrow-counterclockwise"></i> Restore
                </a>
                <button class="act-btn act-hard"
                        onclick="confirmHardDelete(<%= p.getId() %>, '<%= safeName %>')">
                  <i class="bi bi-trash3-fill"></i> Purge
                </button>
              <% } %>
            </div>
          </td>
        </tr>
      <%
        }
      %>
      </tbody>
    </table>
    </div>
    <% } %>
  </div>
</div>

<!-- ══ DELETE CHOICE MODAL ══ -->
<div class="modal fade" id="deleteModal" tabindex="-1">
  <div class="modal-dialog modal-dialog-centered" style="max-width:440px;">
    <div class="modal-content">
      <div class="modal-header">
        <div class="modal-title"><i class="bi bi-shield-exclamation"></i> Delete Product</div>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body">
        <p style="font-size:0.88rem;color:var(--muted);margin-bottom:1rem;">
          Choose how to delete <strong id="deleteProductName" style="color:var(--text);"></strong>:
        </p>
        <div class="delete-choice-box">
          <a id="softDeleteBtn" href="#" class="delete-option soft">
            <div class="del-opt-icon soft"><i class="bi bi-archive"></i></div>
            <div>
              <div class="del-opt-title soft">Archive (Soft Delete)</div>
              <div class="del-opt-desc">Hides the product from customers. Product data is kept and can be fully restored at any time.</div>
            </div>
          </a>
          <a id="hardDeleteBtn" href="#" class="delete-option hard">
            <div class="del-opt-icon hard"><i class="bi bi-trash3-fill"></i></div>
            <div>
              <div class="del-opt-title hard">Permanently Delete</div>
              <div class="del-opt-desc">Removes the product forever from the database. <strong>This cannot be undone.</strong></div>
            </div>
          </a>
        </div>
      </div>
      <div class="modal-footer">
        <button class="btn-back" data-bs-dismiss="modal">Cancel</button>
      </div>
    </div>
  </div>
</div>

<!-- ══ ADD PRODUCT MODAL ══ -->
<div class="modal fade" id="addProductModal" tabindex="-1">
  <div class="modal-dialog modal-lg modal-dialog-centered modal-dialog-scrollable">
    <div class="modal-content">
      <div class="modal-header">
        <div class="modal-title"><i class="bi bi-plus-circle"></i> Add New Product</div>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body">
        <form action="ProductServlet" method="post" enctype="multipart/form-data" id="addProductForm">
          <input type="hidden" name="action" value="add">
          <div class="row g-3">

            <!-- Image upload -->
            <div class="col-12">
              <label class="form-label"><i class="bi bi-image"></i> Product Image</label>
              <input type="file" id="imageFile" name="imageFile" class="form-control" accept="image/*" required>
              <div class="img-preview-box" id="previewBox">
                <img id="preview" alt="Preview">
                <span class="img-preview-placeholder" id="previewPlaceholder">
                  <i class="bi bi-image" style="font-size:1.5rem;display:block;margin-bottom:4px;"></i>
                  Preview
                </span>
              </div>
            </div>

            <!-- Name -->
            <div class="col-md-6">
              <label class="form-label"><i class="bi bi-box"></i> Product Name</label>
              <input type="text" name="name" class="form-control" placeholder="e.g. Organic Apples" required>
            </div>

            <!-- Category -->
            <div class="col-md-6">
              <label class="form-label"><i class="bi bi-tags"></i> Category</label>
              <select name="category" class="form-select" required>
                <option value="">Select Category</option>
                <option value="fruits">🍎 Fruits</option>
                <option value="vegetables">🥦 Vegetables</option>
                <option value="packed_food">📦 Packed Food</option>
                <option value="dairy_products">🥛 Dairy Products</option>
                <option value="fashion">👗 Fashion</option>
                <option value="books">📚 Books</option>
                <option value="electronics">📱 Electronics</option>
                <option value="home_furniture">🛋️ Home & Furniture</option>
                <option value="beauty">💄 Beauty & Personal Care</option>
                <option value="sports">🏀 Sports & Fitness</option>
              </select>
            </div>

            <!-- MRP -->
            <div class="col-md-4">
              <label class="form-label"><i class="bi bi-currency-rupee"></i> MRP (₹)</label>
              <input type="number" step="0.01" name="mrp" id="mrp" class="form-control" placeholder="0.00" required>
            </div>

            <!-- Discount -->
            <div class="col-md-4">
              <label class="form-label"><i class="bi bi-percent"></i> Discount (%)</label>
              <input type="number" step="0.01" min="0" max="100" name="discount" id="discount" class="form-control" placeholder="0">
            </div>

            <!-- Final Price (readonly, auto-calc) -->
            <div class="col-md-4">
              <label class="form-label"><i class="bi bi-cash-stack"></i> Final Price</label>
              <input type="text" name="finalprice" id="finalPrice" class="form-control readonly-field" readonly placeholder="Auto-calculated">
              <small style="font-size:0.72rem;color:var(--muted);">Auto-calculated from MRP & Discount</small>
            </div>

            <!-- Quantity -->
            <div class="col-md-4">
              <label class="form-label"><i class="bi bi-basket"></i> Quantity</label>
              <input type="number" name="quantity" class="form-control" placeholder="e.g. 500" required>
            </div>

            <!-- Unit -->
            <div class="col-md-4">
              <label class="form-label"><i class="bi bi-rulers"></i> Unit</label>
              <select name="unit" class="form-select" required>
                <option value="kg">Kilogram (kg)</option>
                <option value="g">Gram (g)</option>
                <option value="liter">Liter</option>
                <option value="ml">Milliliter (ml)</option>
                <option value="dozen">Dozen</option>
                <option value="piece">Piece</option>
              </select>
            </div>

            <!-- Stock -->
            <div class="col-md-4">
              <label class="form-label"><i class="bi bi-layers"></i> Stock</label>
              <input type="number" name="stock" class="form-control" placeholder="e.g. 100" required>
              <%-- Add this below the stock input field --%>
				<div id="stockHint" style="font-size:0.72rem;color:var(--muted);margin-top:3px;">
				  <i class="bi bi-info-circle"></i> Stock = 0 will auto-set status to <strong>Inactive</strong>
				</div>
            </div>

          <!-- GST Rate -->
			<div class="col-md-6">
			  <label class="form-label"><i class="bi bi-receipt"></i> GST Rate (%)</label>
			  <select name="gstRate" class="form-select" required>
			
			    <option value="0">
			      0% — Exempt &nbsp;|&nbsp; 🍎 Fruits · 🥦 Vegetables · 📚 Books
			    </option>
			
			    <option value="5" selected>
			      5% — Basic Food &nbsp;|&nbsp; 🥛 Dairy Products (milk, curd, paneer)
			    </option>
			
			    <option value="12">
			      12% — Processed &nbsp;|&nbsp; 📦 Packed Food · 👗 Fashion (under ₹1000)
			    </option>
			
			    <option value="18">
			      18% — General &nbsp;|&nbsp; 📱 Electronics · 🛋️ Home &amp; Furniture · 💄 Beauty · 🏀 Sports
			    </option>
			
			    <option value="28">
			      28% — Luxury &nbsp;|&nbsp; Aerated drinks · Premium goods
			    </option>
			
			  </select>
			  <small style="font-size:0.72rem;color:var(--muted);">
			    <i class="bi bi-info-circle"></i>
			    Select the slab matching this product's category. Applied on final price at checkout per Indian GST law.
			  </small>
			</div>

            <!-- Description -->
            <div class="col-12">
              <label class="form-label"><i class="bi bi-card-text"></i> Description</label>
              <textarea name="description" class="form-control" rows="3" placeholder="Short product description…"></textarea>
            </div>

            <div class="col-12 d-flex justify-content-end gap-2 mt-2">
              <button type="button" class="btn-back" data-bs-dismiss="modal">Cancel</button>
              <button type="submit" class="btn-save">
                <i class="bi bi-check-circle"></i> Save Product
              </button>
            </div>
          </div>
        </form>
      </div>
    </div>
  </div>
</div>

<!-- ══ TOAST CONTAINER ══ -->
<div class="toast-container" id="toastContainer"></div>

<!-- ══ FOOTER ══ -->
<footer>
  <p class="mb-0">&copy; 2026 <span>Smart Inventory</span> &nbsp;|&nbsp; Administrator Portal</p>
</footer>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
<script>
/* ── Toast ── */
function showToast(msg, type) {
  const c = document.getElementById('toastContainer');
  const icon = type === 'success' ? 'bi-check-circle-fill' : 'bi-exclamation-circle-fill';
  const el = document.createElement('div');
  el.className = 'toast-item ' + type;
  el.innerHTML = '<i class="bi ' + icon + ' ti-icon ' + type + '"></i> ' + msg;
  c.appendChild(el);
  setTimeout(() => el.remove(), 4000);
}
//Add this after your existing DOMContentLoaded logic
document.querySelector('[name="stock"]').addEventListener('input', function() {
  const hint = document.getElementById('stockHint');
  if (!hint) return;
  if (parseInt(this.value) === 0) {
    hint.style.color = 'var(--warning)';
    hint.innerHTML   = '<i class="bi bi-exclamation-triangle"></i> Stock is 0 — product will be set <strong>Inactive</strong> automatically';
  } else {
    hint.style.color = 'var(--muted)';
    hint.innerHTML   = '<i class="bi bi-info-circle"></i> Stock = 0 will auto-set status to <strong>Inactive</strong>';
  }
});
/* Auto-show server messages */
(function() {
  <% if (success != null && !success.isEmpty()) { %>
    showToast('<%= success.replace("'","&#39;") %>', 'success');
  <% } %>
  <% if (request.getParameter("error") != null) { %>
    showToast('<%= request.getParameter("error").replace("'","&#39;") %>', 'error');
  <% } %>
  <% if (request.getParameter("msg") != null) { %>
    showToast('<%= request.getParameter("msg").replace("'","&#39;") %>', 'success');
  <% } %>
})();

/* ── Image preview ── */
document.getElementById('imageFile').addEventListener('change', function() {
  const file = this.files[0];
  const preview = document.getElementById('preview');
  const placeholder = document.getElementById('previewPlaceholder');
  if (file) {
    preview.src = URL.createObjectURL(file);
    preview.style.display = 'block';
    placeholder.style.display = 'none';
  }
});

/* ── Auto final price ── */
document.addEventListener('DOMContentLoaded', function() {
  const mrpInput      = document.getElementById('mrp');
  const discountInput = document.getElementById('discount');
  const finalInput    = document.getElementById('finalPrice');
  function calc() {
    const mrp = parseFloat(mrpInput.value) || 0;
    const disc = parseFloat(discountInput.value) || 0;
    finalInput.value = mrp > 0 ? (mrp - mrp * disc / 100).toFixed(2) : '';
  }
  mrpInput.addEventListener('input', calc);
  discountInput.addEventListener('input', calc);
});

/* ── Delete Modal ── */
function openDeleteModal(id, name) {
  document.getElementById('deleteProductName').textContent = name;
  document.getElementById('softDeleteBtn').href = 'ProductServlet?action=delete&id=' + id + '&type=soft';
  document.getElementById('hardDeleteBtn').href  = 'ProductServlet?action=delete&id=' + id + '&type=hard';
  new bootstrap.Modal(document.getElementById('deleteModal')).show();
}

/* ── Hard delete confirm (inline from Purge button) ── */
function confirmHardDelete(id, name) {
  if (confirm('Permanently delete "' + name + '"? This cannot be undone.')) {
    window.location.href = 'ProductServlet?action=delete&id=' + id + '&type=hard';
  }
}

/* ── Blink cleanup ── */
setTimeout(function() {
  document.querySelectorAll('.blink-row, .blink-field').forEach(function(el) {
    el.classList.remove('blink-row', 'blink-field');
  });
}, 10000);

/* ── Search (client-side instant) ── */
document.getElementById('searchQuery').addEventListener('input', function() {
  applyFilters();
});

/* ── Sort (server-side) ── */
document.getElementById('sortBy').addEventListener('change', function() {
  if (!this.value) return;
  window.location.href = 'ProductServlet?action=sort&sortBy=' + encodeURIComponent(this.value);
});

/* ── Filter chips ── */
let activeFilter = 'all';
document.querySelectorAll('.fchip').forEach(function(chip) {
  chip.addEventListener('click', function() {
    document.querySelectorAll('.fchip').forEach(function(c) { c.classList.remove('active'); });
    this.classList.add('active');
    activeFilter = this.dataset.filter;
    applyFilters();
  });
});

/* ── Combined filter function ── */
function applyFilters() {
  const q = document.getElementById('searchQuery').value.toLowerCase().trim();
  const rows = document.querySelectorAll('#productsTbody .product-row');
  let visible = 0;

  rows.forEach(function(row) {
    const status   = row.dataset.status;
    
    const name     = row.dataset.name;
    const category = row.dataset.category;
    const isDeleted = status === 'deleted';
    const stock    = parseInt(row.dataset.stock, 10);
    const nameMatch = !q || name.includes(q) || category.includes(q);

    let filterMatch = false;
    if (activeFilter === 'all')      filterMatch = !isDeleted;
    else if (activeFilter === 'deleted') filterMatch = isDeleted;
    else if (activeFilter === 'lowstock') {
        filterMatch = stock <= 10 && !isDeleted;   // threshold for low stock
      }
    else filterMatch = status === activeFilter && !isDeleted;

    const show = nameMatch && filterMatch;
    row.style.display = show ? '' : 'none';
    if (show) visible++;
  });

  document.getElementById('visibleCount').textContent = visible;
}

/* init */
document.addEventListener('DOMContentLoaded', applyFilters);
</script>
</body>
</html>
