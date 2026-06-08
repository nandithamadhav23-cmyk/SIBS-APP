<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true"%>
<%@ page import="java.util.List" %>
<%@ page import="com.util.Product" %>
<%@ page import="com.util.*" %>
<%@ page import="com.util.CustomerWallet" %>
<%
    Customer customer = (Customer) session.getAttribute("customer");
    List<Product> products = (List<Product>) request.getAttribute("products");
    Boolean loggedIn = (Boolean) session.getAttribute("loggedIn");
    // Wallet balance — set by CustomerWalletServlet or default 0
    Double walletBalance = request.getAttribute("walletBalance") != null ? (Double) request.getAttribute("walletBalance") : (Double) session.getAttribute("walletBalance");
    if (walletBalance == null) walletBalance = 0.0;
    Integer cartCount = (Integer) session.getAttribute("cartCount");
    if (cartCount == null) cartCount = 0;

    // Notification badge — set by CustomerDashboardServlet
    Integer unreadNotifCount = (Integer) request.getAttribute("unreadNotifCount");
    if (unreadNotifCount == null) unreadNotifCount = (Integer) session.getAttribute("unreadNotifCount");
    if (unreadNotifCount == null) unreadNotifCount = 0;
%>

<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>SIBS Store — Customer Portal</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons/font/bootstrap-icons.css" rel="stylesheet">
  <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@600;700&family=DM+Sans:wght@300;400;500;600&display=swap" rel="stylesheet">
  <style>
    :root {
      --primary: #0ea5e9;
      --primary-dark: #0369a1;
      --accent: #8b5cf6;
      --accent2: #06b6d4;
      --surface: #ffffff;
      --bg: #f0f9ff;
      --text: #0c1a2e;
      --muted: #64748b;
      --border: rgba(14,165,233,0.15);
      --card-shadow: 0 2px 20px rgba(14,165,233,0.08);
      --card-hover: 0 8px 40px rgba(14,165,233,0.18);
      --nav-h: 68px;
      --sidebar-w: 280px;
      --radius: 14px;
      --gold: #f59e0b;
    }

    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

    body {
      font-family: 'DM Sans', sans-serif;
      background: var(--bg);
      color: var(--text);
      overflow-x: hidden;
    }

    /* ── TOPNAV ── */
    .top-nav {
      position: fixed; top: 0; left: 0; right: 0; z-index: 1000;
      height: var(--nav-h);
      background: linear-gradient(135deg, var(--primary-dark) 0%, var(--primary) 100%);
      display: flex; align-items: center; justify-content: space-between;
      padding: 0 1.5rem;
      box-shadow: 0 2px 20px rgba(14,165,233,0.25);
    }

    .nav-left { display: flex; align-items: center; gap: 1rem; }

    .hamburger-btn {
      background: rgba(255,255,255,0.1);
      border: 1px solid rgba(255,255,255,0.2);
      border-radius: 8px;
      color: #fff;
      width: 40px; height: 40px;
      display: flex; align-items: center; justify-content: center;
      cursor: pointer;
      transition: background 0.2s;
    }
    .hamburger-btn:hover { background: rgba(255,255,255,0.2); }

    .nav-brand {
      font-family: 'Nunito', sans-serif;
      font-size: 1.4rem; font-weight: 800;
      color: #fff; text-decoration: none;
      display: flex; align-items: center; gap: 0.5rem;
      letter-spacing: -0.3px;
    }
    .nav-brand .brand-dot { color: #bae6fd; }

    .nav-search {
      flex: 1; max-width: 420px; margin: 0 2rem;
      position: relative;
    }
    .nav-search input {
      width: 100%;
      background: rgba(255,255,255,0.12);
      border: 1px solid rgba(255,255,255,0.25);
      border-radius: 30px;
      color: #fff;
      padding: 0.5rem 1rem 0.5rem 2.8rem;
      font-size: 0.9rem;
      outline: none;
      transition: all 0.2s;
    }
    .nav-search input::placeholder { color: rgba(255,255,255,0.55); }
    .nav-search input:focus { background: rgba(255,255,255,0.2); border-color: var(--accent); }
    .nav-search .search-icon {
      position: absolute; left: 1rem; top: 50%; transform: translateY(-50%);
      color: rgba(255,255,255,0.6); font-size: 1rem;
    }

    .nav-right { display: flex; align-items: center; gap: 0.75rem; }

    .nav-icon-btn {
      background: rgba(255,255,255,0.1);
      border: 1px solid rgba(255,255,255,0.15);
      border-radius: 10px;
      color: #fff;
      width: 42px; height: 42px;
      display: flex; align-items: center; justify-content: center;
      cursor: pointer; text-decoration: none;
      font-size: 1.1rem;
      position: relative;
      transition: all 0.2s;
    }
    .nav-icon-btn:hover { background: rgba(255,255,255,0.2); color: #fff; }
    .nav-badge {
      position: absolute; top: -4px; right: -4px;
      background: #ef4444;
      color: #fff; font-size: 0.65rem; font-weight: 600;
      width: 18px; height: 18px;
      border-radius: 50%; display: flex; align-items: center; justify-content: center;
      border: 2px solid var(--primary);
    }

    .nav-profile-btn {
      display: flex; align-items: center; gap: 0.6rem;
      background: rgba(255,255,255,0.1);
      border: 1px solid rgba(255,255,255,0.2);
      border-radius: 30px;
      padding: 0.35rem 1rem 0.35rem 0.35rem;
      cursor: pointer; color: #fff;
      transition: all 0.2s;
    }
    .nav-profile-btn:hover { background: rgba(255,255,255,0.2); }
    .nav-avatar {
      width: 32px; height: 32px; border-radius: 50%;
      background: linear-gradient(90deg, var(--primary-dark), var(--primary));
      display: flex; align-items: center; justify-content: center;
      font-weight: 700; font-size: 0.85rem; color: #fff;
    }
    .nav-profile-name { font-size: 0.88rem; font-weight: 500; }

    /* ── SIDEBAR ── */
    .sidebar-overlay {
      position: fixed; inset: 0; z-index: 1100;
      background: rgba(0,0,0,0.5);
      opacity: 0; pointer-events: none;
      transition: opacity 0.3s;
      backdrop-filter: blur(2px);
    }
    .sidebar-overlay.open { opacity: 1; pointer-events: all; }

    .sidebar {
      position: fixed; left: 0; top: 0; bottom: 0; z-index: 1200;
      width: var(--sidebar-w);
      background: var(--surface);
      transform: translateX(-100%);
      transition: transform 0.32s cubic-bezier(0.4,0,0.2,1);
      display: flex; flex-direction: column;
      overflow-y: auto;
      box-shadow: 4px 0 30px rgba(0,0,0,0.15);
    }
    .sidebar.open { transform: translateX(0); }

    .sidebar-head {
      background: linear-gradient(135deg, var(--primary-dark) 0%, var(--primary) 100%);
      padding: 1.5rem;
      display: flex; align-items: center; gap: 1rem;
    }
    .sidebar-avatar {
      width: 56px; height: 56px; border-radius: 50%;
      background: linear-gradient(90deg, var(--primary-dark), var(--primary));
      display: flex; align-items: center; justify-content: center;
      font-size: 1.4rem; font-weight: 700; color: #fff;
      border: 3px solid rgba(255,255,255,0.3);
    }
    .sidebar-user-name { color: #fff; font-weight: 600; font-size: 1rem; }
    .sidebar-user-email { color: rgba(255,255,255,0.65); font-size: 0.8rem; margin-top: 2px; }

    .sidebar-close {
      position: absolute; top: 1rem; right: 1rem;
      background: rgba(255,255,255,0.15); border: none; border-radius: 8px;
      color: #fff; width: 32px; height: 32px;
      display: flex; align-items: center; justify-content: center;
      cursor: pointer; font-size: 1rem;
    }

    .sidebar-section { padding: 1rem 0; }
    .sidebar-section-title {
      font-size: 0.7rem; font-weight: 600; text-transform: uppercase;
      letter-spacing: 0.12em; color: var(--muted);
      padding: 0.5rem 1.5rem;
    }
    .sidebar-link {
      display: flex; align-items: center; gap: 0.85rem;
      padding: 0.75rem 1.5rem;
      color: var(--text); text-decoration: none;
      font-size: 0.92rem; font-weight: 500;
      border-radius: 0;
      transition: all 0.15s;
      position: relative;
    }
    .sidebar-link:hover { background: rgba(15,52,96,0.06); color: var(--primary); }
    .sidebar-link.active {
      background: rgba(139,92,246,0.08);
      color: var(--accent);
      border-right: 3px solid var(--accent);
    }
    .sidebar-link .icon {
      width: 36px; height: 36px; border-radius: 10px;
      background: rgba(15,52,96,0.06);
      display: flex; align-items: center; justify-content: center;
      font-size: 1rem; flex-shrink: 0;
      transition: background 0.15s;
    }
    .sidebar-link:hover .icon { background: rgba(15,52,96,0.12); }
    .sidebar-link.active .icon { background: rgba(139,92,246,0.12); }
    .sidebar-link .badge-count {
      margin-left: auto;
      background: var(--primary); color: #fff;
      font-size: 0.7rem; font-weight: 700;
      border-radius: 20px; padding: 1px 8px;
    }
    .sidebar-divider { height: 1px; background: var(--border); margin: 0.5rem 1.5rem; }

    /* ── MAIN ── */
    .main-content {
      margin-top: var(--nav-h);
      min-height: calc(100vh - var(--nav-h));
      padding: 0;
    }

    /* ── HERO BANNER ── */
   .hero-banner {
  background: linear-gradient(135deg, #0369a1 0%, #0ea5e9 45%, #8b5cf6 100%);
  padding: 2.5rem 2rem 2rem;
  position: relative;
  overflow: hidden;
}

.hero-banner::before {
  content: '';
  position: absolute; inset: 0;
  background:
    radial-gradient(ellipse at 15% 50%, rgba(255,255,255,0.14) 0%, transparent 55%),
    radial-gradient(ellipse at 85% 20%, rgba(186,230,253,0.2) 0%, transparent 50%),
    radial-gradient(ellipse at 55% 90%, rgba(196,181,253,0.18) 0%, transparent 50%);
  pointer-events: none;
}

.hero-banner::after {
  content: '';
  position: absolute; inset: 0;
  background: url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Ccircle cx='30' cy='30' r='1.2' fill='%23ffffff' fill-opacity='0.1'/%3E%3C/svg%3E");
  pointer-events: none;
}
    .hero-inner {
      max-width: 1200px; margin: 0 auto;
      display: flex; align-items: center; justify-content: space-between;
      gap: 2rem;
    }
    .hero-text h1 {
      font-family: 'Playfair Display', serif;
      font-size: clamp(1.6rem, 3vw, 2.4rem);
      color: #fff; line-height: 1.25; margin-bottom: 0.5rem;
    }
    .hero-text h1 span { color: #bae6fd; }
    .hero-text p { color: rgba(255,255,255,0.9); font-size: 0.95rem; margin-bottom: 1.25rem; }
    .hero-cta-row { display: flex; gap: 0.75rem; flex-wrap: wrap; }
    .btn-accent {
      background: var(--accent);
      color: #fff; border: none;
      padding: 0.6rem 1.5rem;
      border-radius: 30px;
      font-weight: 600; font-size: 0.88rem;
      cursor: pointer; text-decoration: none;
      transition: all 0.2s;
      display: inline-flex; align-items: center; gap: 0.4rem;
    }
    .btn-accent:hover { background: #7c3aed; color: #fff; transform: translateY(-1px); box-shadow: 0 4px 15px rgba(139,92,246,.4); }
    .btn-outline-white {
      background: transparent; color: #fff;
      border: 1.5px solid rgba(255,255,255,0.4);
      padding: 0.6rem 1.5rem; border-radius: 30px;
      font-weight: 500; font-size: 0.88rem;
      cursor: pointer; text-decoration: none;
      transition: all 0.2s;
      display: inline-flex; align-items: center; gap: 0.4rem;
    }
    .btn-outline-white:hover { background: rgba(255,255,255,0.1); color: #fff; }

    .hero-stats {
      display: flex; gap: 2rem; align-items: center;
    }
    .hero-stat { text-align: center; }
    .hero-stat-num {
      font-family: 'Playfair Display', serif;
      font-size: 1.8rem; font-weight: 700; color: #fbf8f8;
    }
    .hero-stat-label { font-size: 0.75rem; color: #fbf8f8; margin-top: 2px; }

    /* ── PROMO STRIP ── */
    .promo-strip {
      background:linear-gradient(135deg, #0369a1 0%, #0ea5e9 45%, #8b5cf6 100%);
      display: flex; align-items: center; justify-content: center;
      gap: 0.5rem; padding: 0.55rem 1rem;
      font-size: 0.85rem; color: #fff; font-weight: 500;
      overflow: hidden;
    }
    .promo-ticker { display: flex; gap: 3rem; animation: ticker 18s linear infinite; white-space: nowrap; }
    @keyframes ticker { from { transform: translateX(0); } to { transform: translateX(-50%); } }
    .promo-item { display: flex; align-items: center; gap: 0.4rem; }

    /* ── TOOLBAR ── */
    .toolbar {
      background: var(--surface);
      border-bottom: 1px solid var(--border);
      padding: 0.85rem 2rem;
      display: flex; align-items: center; gap: 1rem;
      flex-wrap: wrap;
      position: sticky; top: var(--nav-h); z-index: 90;
    }
    .category-chips { display: flex; gap: 0.5rem; flex-wrap: wrap; flex: 1; }
    .chip {
      display: flex; align-items: center; gap: 0.35rem;
      padding: 0.4rem 1rem;
      border-radius: 30px;
      border: 1.5px solid var(--border);
      background: var(--surface);
      color: var(--muted); font-size: 0.83rem; font-weight: 500;
      cursor: pointer; text-decoration: none;
      transition: all 0.18s;
    }
    .chip:hover, .chip.active {
      border-color: var(--primary);
      background: linear-gradient(135deg, var(--primary-dark), var(--primary)); color: #fff;
      box-shadow: 0 2px 10px rgba(14,165,233,.25);
    }

    .toolbar-right { display: flex; align-items: center; gap: 0.75rem; }
    .sort-select {
      border: 1.5px solid var(--border); border-radius: 10px;
      padding: 0.4rem 0.85rem; font-size: 0.85rem;
      color: var(--text); background: var(--surface);
      outline: none; cursor: pointer;
    }
    .view-toggle { display: flex; border: 1.5px solid var(--border); border-radius: 10px; overflow: hidden; }
    .view-btn {
      background: var(--surface); border: none;
      padding: 0.4rem 0.6rem; cursor: pointer; color: var(--muted);
      transition: all 0.18s;
    }
    .view-btn.active { background: var(--primary); color: #fff; }

    /* ── PRODUCT GRID ── */
    .products-wrapper {
      padding: 1.5rem 2rem;
      max-width: 1400px; margin: 0 auto;
    }

    .section-header {
      display: flex; align-items: center; justify-content: space-between;
      margin-bottom: 1.25rem;
    }
    .section-title {
      font-family: 'Playfair Display', serif;
      font-size: 1.35rem; font-weight: 700; color: var(--primary);
      display: flex; align-items: center; gap: 0.6rem;
    }
    .section-title::before {
      content: '';
      display: inline-block;
      width: 4px; height: 1.2em;
      background: var(--accent);
      border-radius: 2px;
    }
    .see-all {
      font-size: 0.85rem; color: var(--accent); text-decoration: none; font-weight: 600;
      display: flex; align-items: center; gap: 0.25rem;
    }
    .see-all:hover { color: var(--primary); }

    /* Product Card */
    .product-card {
      background: var(--surface);
      border-radius: var(--radius);
      box-shadow: var(--card-shadow);
      overflow: hidden;
      transition: all 0.28s ease;
      position: relative;
      display: flex; flex-direction: column;
      border: 1px solid transparent;
    }
    .product-card:hover {
      transform: translateY(-6px);
      box-shadow: var(--card-hover);
      border-color: rgba(15,52,96,0.1);
    }

    .card-badges {
      position: absolute; top: 10px; left: 10px;
      display: flex; flex-direction: column; gap: 4px; z-index: 2;
    }
    .badge-tag {
      font-size: 0.7rem; font-weight: 700;
      padding: 3px 10px; border-radius: 30px;
      display: inline-block;
    }
    .badge-tag.off { background: var(--primary); color: #fff; }
    .badge-tag.low { background: var(--gold); color: #fff; }
    .badge-tag.new { background: var(--primary); color: #fff; }
    .badge-tag.sold-out { background: #6b7280; color: #fff; }

    .card-wish {
      position: absolute; top: 10px; right: 10px; z-index: 2;
      background: var(--surface); border: 1px solid var(--border);
      border-radius: 50%;
      width: 34px; height: 34px;
      display: flex; align-items: center; justify-content: center;
      cursor: pointer; color: var(--muted); font-size: 0.95rem;
      transition: all 0.2s;
      text-decoration: none;
    }
    .card-wish:hover { color: var(--accent); border-color: var(--accent); transform: scale(1.1); }
    .card-wish.wished { color: var(--accent); border-color: var(--accent); }

    .card-img-wrap {
      background: #f8f9fc;
      display: flex; align-items: center; justify-content: center;
      height: 180px; overflow: hidden;
      padding: 0.75rem;
    }
    .card-img-wrap img {
      width: 100%; height: 100%; object-fit: contain;
      transition: transform 0.35s ease;
    }
    .product-card:hover .card-img-wrap img { transform: scale(1.06); }

    .card-body {
      padding: 1rem; flex: 1;
      display: flex; flex-direction: column;
    }
    .card-cat {
      font-size: 0.72rem; text-transform: uppercase; letter-spacing: 0.06em;
      color: var(--muted); margin-bottom: 0.3rem;
    }
    .card-name {
      font-weight: 600; font-size: 0.95rem; color: var(--text);
      margin-bottom: 0.5rem;
      display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical;
      overflow: hidden;
    }
    .card-price-row { display: flex; align-items: baseline; gap: 0.5rem; margin-bottom: 0.4rem; }
    .price-final { font-size: 1.2rem; font-weight: 700; color: var(--primary); }
    .price-mrp { font-size: 0.8rem; text-decoration: line-through; color: var(--muted); }
    .price-save { font-size: 0.75rem; color: #16a34a; font-weight: 600; }

    .card-rating { display: flex; align-items: center; gap: 0.35rem; margin-bottom: 0.5rem; }
    .stars { color: var(--gold); font-size: 0.8rem; }
    .rating-val { font-size: 0.8rem; color: var(--muted); }

    .stock-bar-wrap { margin-bottom: 0.6rem; }
    .stock-text { font-size: 0.72rem; color: var(--muted); margin-bottom: 3px; }
    .stock-bar {
      height: 4px; border-radius: 4px; background: #e5e7eb;
      overflow: hidden;
    }
    .stock-fill {
      height: 100%; border-radius: 4px;
      transition: width 0.4s;
    }
    .stock-fill.high { background: #16a34a; }
    .stock-fill.mid { background: var(--gold); }
    .stock-fill.low-c { background: var(--accent); }

    .card-actions { margin-top: auto; display: flex; gap: 0.5rem; }
    .btn-cart {
      flex: 1; padding: 0.6rem;
      background: var(--primary); color: #fff;
      border: none; border-radius: 10px;
      font-size: 0.85rem; font-weight: 600;
      cursor: pointer; text-align: center; text-decoration: none;
      display: flex; align-items: center; justify-content: center; gap: 0.35rem;
      transition: all 0.2s;
    }
    .btn-cart:hover { background: #0a2a50; color: #fff; }
    .btn-cart.disabled { background: #e5e7eb; color: var(--muted); cursor: not-allowed; pointer-events: none; }
    .btn-quick-view {
      width: 40px; height: 40px;
      background: var(--bg); border: 1.5px solid var(--border);
      border-radius: 10px; color: var(--muted);
      cursor: pointer; display: flex; align-items: center; justify-content: center;
      font-size: 1rem; transition: all 0.2s; flex-shrink: 0;
    }
    .btn-quick-view:hover { background: var(--primary); color: #fff; border-color: var(--primary); }

    /* ── FEATURE CARDS (Trust) ── */
    .trust-bar {
      background: var(--surface);
      border-top: 1px solid var(--border);
      border-bottom: 1px solid var(--border);
      padding: 1.25rem 2rem;
      margin-top:2rem;
      display: flex; gap: 1.5rem; flex-wrap: wrap;
      justify-content: center;
    }
    .trust-item {
      display: flex; align-items: center; gap: 0.7rem;
      font-size: 0.88rem; color: var(--text);
    }
    .trust-icon {
      width: 40px; height: 40px; border-radius: 12px;
      background: rgba(15,52,96,0.07);
      display: flex; align-items: center; justify-content: center;
      color: var(--primary); font-size: 1.15rem; flex-shrink: 0;
    }
    .trust-label { font-weight: 600; font-size: 0.82rem; }
    .trust-sub { font-size: 0.72rem; color: var(--muted); }

    /* ── QUICK VIEW MODAL ── */
    #quickViewModal .modal-content {
      border-radius: 20px;
      border: none;
      box-shadow: 0 20px 60px rgba(0,0,0,0.2);
      overflow: hidden;
    }
    #quickViewModal .modal-header {
      background: var(--primary);
      color: #fff; border: none; padding: 1.1rem 1.5rem;
    }
    #quickViewModal .modal-title { font-family: 'Playfair Display', serif; font-size: 1.15rem; }
    #quickViewModal .btn-close { filter: brightness(0) invert(1); }
    #quickViewModal .modal-body { padding: 1.5rem; }

    /* ── PROFILE MODAL ── */
    .profile-modal .modal-content {
      border-radius: 20px; border: none;
      box-shadow: 0 20px 60px rgba(0,0,0,0.2);
      overflow: hidden;
    }
    .profile-modal-head {
      background: linear-gradient(135deg, var(--primary), #1a1a2e);
      padding: 2rem 1.5rem 1.5rem;
      text-align: center; position: relative;
    }
    .profile-modal-avatar {
      width: 80px; height: 80px; border-radius: 50%;
      background: var(--accent);
      margin: 0 auto 0.75rem;
      display: flex; align-items: center; justify-content: center;
      font-size: 2rem; font-weight: 700; color: #fff;
      border: 4px solid rgba(255,255,255,0.3);
    }
    .profile-modal-name { color: #fff; font-size: 1.15rem; font-weight: 600; }
    .profile-modal-email { color: rgba(255,255,255,0.65); font-size: 0.85rem; }
    .profile-modal-body { padding: 1.25rem; }
    .profile-action {
      display: flex; align-items: center; gap: 0.85rem;
      padding: 0.85rem 1rem;
      border-radius: 12px;
      text-decoration: none;
      color: var(--text);
      font-weight: 500;
      font-size: 0.9rem;
      transition: all 0.18s;
      margin-bottom: 0.35rem;
    }
    .profile-action:hover { background: var(--bg); color: var(--primary); }
    .profile-action .pa-icon {
      width: 38px; height: 38px; border-radius: 10px;
      display: flex; align-items: center; justify-content: center;
      font-size: 1rem;
    }
    .profile-action.danger { color: #dc2626; }
    .profile-action.danger:hover { background: #fef2f2; }

    /* ── FOOTER ── */
    footer {
      background: #0f3460;
      color: rgba(255,255,255,0.75);
      padding: 3rem 2rem 1.5rem;
      margin-top: 0.2rem;
    }
    .footer-grid {
      max-width: 1200px; margin: 0 auto;
      display: grid; grid-template-columns: 2fr 1fr 1fr 1.5fr;
      gap: 2rem; margin-bottom: 2rem;
    }
    .footer-brand { font-family: 'Playfair Display', serif; font-size: 1.4rem; color: #fff; margin-bottom: 0.75rem; }
    .footer-desc { font-size: 0.85rem; line-height: 1.7; color: rgba(255,255,255,0.55); }
    .footer-col-title { color: #fff; font-weight: 600; font-size: 0.9rem; margin-bottom: 1rem; }
    .footer-link { display: block; color: rgba(255,255,255,0.55); font-size: 0.85rem; text-decoration: none; margin-bottom: 0.5rem; transition: color 0.15s; }
    .footer-link:hover { color: var(--accent); }
    .footer-bottom {
      max-width: 1200px; margin: 0 auto;
      border-top: 1px solid rgba(255,255,255,0.1);
      padding-top: 1.25rem;
      display: flex; align-items: center; justify-content: space-between;
      font-size: 0.82rem; color: rgba(255,255,255,0.45);
      flex-wrap: wrap; gap: 0.5rem;
    }
    .footer-social { display: flex; gap: 0.6rem; }
    .social-icon {
      width: 34px; height: 34px; border-radius: 50%;
      background: rgba(255,255,255,0.08);
      display: flex; align-items: center; justify-content: center;
      color: rgba(255,255,255,0.6); font-size: 0.9rem;
      text-decoration: none; transition: all 0.18s;
    }
    .social-icon:hover { background: var(--primary); color: #fff; }

    /* ── TOAST ── */
    .toast-container { position: fixed; bottom: 1.5rem; right: 1.5rem; z-index: 9999; }
    .toast-msg {
      background: var(--primary); color: #fff;
      padding: 0.85rem 1.25rem; border-radius: 12px;
      display: flex; align-items: center; gap: 0.7rem;
      box-shadow: 0 4px 20px rgba(0,0,0,0.2);
      font-size: 0.9rem; font-weight: 500;
      animation: slideUp 0.3s ease;
      margin-top: 0.5rem;
    }
    @keyframes slideUp { from { opacity: 0; transform: translateY(20px); } to { opacity: 1; transform: translateY(0); } }

    /* ── RECENTLY VIEWED ── */
    .recently-bar {
      background: var(--surface);
      border-top: 1px solid var(--border);
      padding: 1.25rem 2rem;
    }
    .recently-title { font-size: 0.9rem; font-weight: 600; color: var(--primary); margin-bottom: 0.75rem; }
    .recently-items { display: flex; gap: 0.75rem; overflow-x: auto; padding-bottom: 0.25rem; }
    .recently-item {
      flex-shrink: 0; width: 64px;
      background: var(--bg); border: 1px solid var(--border);
      border-radius: 10px; overflow: hidden; cursor: pointer;
      transition: all 0.18s;
    }
    .recently-item:hover { box-shadow: 0 2px 8px rgba(0,0,0,0.12); }
    .recently-item img { width: 64px; height: 64px; object-fit: contain; padding: 4px; }

    /* ── Responsive ── */
    @media (max-width: 768px) {
      .hero-stats { display: none; }
      .nav-search { display: none; }
      .footer-grid { grid-template-columns: 1fr 1fr; }
      .trust-bar { gap: 0.75rem; }
      .products-wrapper { padding: 0.75rem 0.6rem; }
      .toolbar { padding: 0.65rem 0.75rem; gap: 0.5rem; }
      /* Sidebar becomes full-screen overlay on mobile */
      .sidebar { width: 85vw !important; max-width: 340px; }
      /* Body padding-bottom for bottom nav */
      body { padding-bottom: 72px; }
      /* Wallet widget compact on mobile */
      .wallet-widget { padding: 0.85rem 1rem; }
      .ww-balance { font-size: 1.25rem; }
      /* Category chips scrollable on mobile */
      .category-chips { flex-wrap: nowrap; overflow-x: auto; -webkit-overflow-scrolling: touch; padding-bottom: 2px; scrollbar-width: none; }
      .category-chips::-webkit-scrollbar { display: none; }
      /* toolbar right stays on same row */
      .toolbar-right { flex-shrink: 0; }
      .sort-select { font-size: 0.78rem; padding: 0.35rem 0.6rem; }
    }
    @media (max-width: 480px) {
      .footer-grid { grid-template-columns: 1fr; }
      .hero-banner { padding: 1.25rem 1rem 1.25rem; }
      .toolbar { flex-wrap: nowrap; gap: 0.4rem; }
      .products-wrapper { padding: 0.6rem 0.5rem; }
    }
    /* Fix: product grid container should be block, not a Bootstrap row with cols */
    #productGrid { display: block !important; width: 100%; }
    /* List view override — stacks product-grid-inner to single column */
    #productGrid.list-view .product-grid-inner {
      grid-template-columns: 1fr !important;
    }
    #productGrid.list-view .card-img-wrap { height: 100px; width: 120px; flex-shrink: 0; }
    #productGrid.list-view .product-card { flex-direction: row; align-items: stretch; }
    #productGrid.list-view .card-body { padding: 0.75rem; }
    @media (max-width: 480px) {
      #productGrid.list-view .card-img-wrap { height: 80px; width: 90px; }
    }

    /* ── MOBILE SEARCH DRAWER ── */
    .mobile-search-overlay{
      display:none;position:fixed;inset:0;z-index:1100;
      background:rgba(0,0,0,0.5);backdrop-filter:blur(4px);
      align-items:flex-start;justify-content:center;padding-top:1rem;
    }
    .mobile-search-overlay.open{display:flex;}
    .mobile-search-box{
      background:#fff;border-radius:14px;width:calc(100% - 2rem);max-width:520px;
      padding:.85rem 1rem;box-shadow:0 8px 32px rgba(0,0,0,.2);
      display:flex;align-items:center;gap:.65rem;
    }
    .mobile-search-box input{
      flex:1;border:none;outline:none;font-size:1rem;
      font-family:'DM Sans',sans-serif;color:var(--text);background:transparent;
    }
    .mobile-search-close{
      background:none;border:none;font-size:1.4rem;color:var(--muted);cursor:pointer;
      flex-shrink:0;padding:0;line-height:1;
    }

    /* ── MOBILE SEARCH ICON IN NAV ── */
    .nav-search-icon{
      display:none;width:40px;height:40px;border-radius:10px;
      background:rgba(255,255,255,.1);border:1px solid rgba(255,255,255,.15);
      color:#fff;align-items:center;justify-content:center;
      cursor:pointer;font-size:1.1rem;
    }
    @media(max-width:768px){ .nav-search-icon{display:flex;} }

    /* ── BOTTOM NAV BAR ── */
    .bottom-nav{
      display:none;
      position:fixed;bottom:0;left:0;right:0;z-index:900;
      background:var(--primary);border-top:2px solid rgba(255,255,255,.1);
      height:64px;
      padding:0 .5rem;
      box-shadow:0 -4px 20px rgba(0,0,0,.25);
    }
    .bottom-nav-inner{
      display:grid;grid-template-columns:repeat(5,1fr);
      height:100%;align-items:stretch;
    }
    .bn-item{
      display:flex;flex-direction:column;align-items:center;justify-content:center;
      gap:2px;text-decoration:none;color:rgba(255,255,255,.6);
      font-size:.6rem;font-weight:600;letter-spacing:.3px;text-transform:uppercase;
      border:none;background:none;cursor:pointer;padding:.3rem 0;
      transition:color .2s;position:relative;
    }
    .bn-item i{font-size:1.25rem;}
    .bn-item.active{color:#fff;}
    .bn-item.active i{color:var(--accent);}
    .bn-badge{
      position:absolute;top:4px;right:50%;transform:translateX(80%);
      background:var(--accent);color:#fff;font-size:.55rem;font-weight:700;
      width:16px;height:16px;border-radius:50%;
      display:flex;align-items:center;justify-content:center;
    }
    @media(max-width:768px){ .bottom-nav{display:block;} }

    /* ── WALLET WIDGET ── */
    .wallet-widget {
      background: linear-gradient(135deg, #0f3460 0%, #1a1a2e 60%, #2d1b4e 100%);
      border-radius: var(--radius);
      padding: 1.1rem 1.5rem;
      display: flex; align-items: center; justify-content: space-between;
      gap: 1rem; flex-wrap: wrap;
      box-shadow: var(--card-shadow);
      margin-bottom: 1.25rem;
      position: relative; overflow: hidden;
      text-decoration: none;
      transition: transform .2s, box-shadow .2s;
    }
    .wallet-widget:hover { transform: translateY(-2px); box-shadow: var(--card-hover); }
    .wallet-widget::before {
      content: ''; position: absolute; top: -40%; right: -5%;
      width: 200px; height: 200px; border-radius: 50%;
      background: radial-gradient(circle, rgba(233,69,96,.25) 0%, transparent 70%);
      pointer-events: none;
    }
    .ww-left { display: flex; align-items: center; gap: .9rem; }
    .ww-icon {
      width: 46px; height: 46px; border-radius: 14px;
      background: rgba(255,255,255,.12); border: 1px solid rgba(255,255,255,.18);
      display: flex; align-items: center; justify-content: center;
      font-size: 1.25rem; color: #fff; flex-shrink: 0;
    }
    .ww-label { font-size: .72rem; color: rgba(255,255,255,.5); text-transform: uppercase; letter-spacing: .08em; font-weight: 600; }
    .ww-balance { font-family:  serif; font-size: 1.55rem; font-weight: 700; color: #fff; line-height: 1.1; margin-top: .1rem; }
    .ww-right { display: flex; gap: .5rem; }
    .ww-btn {
      display: inline-flex; align-items: center; gap: .35rem;
      padding: .45rem 1rem; border-radius: 8px;
      font-size: .78rem; font-weight: 600;
      text-decoration: none; transition: .2s; border: none; cursor: pointer;
    }
    .ww-btn.primary { background: var(--primary); color: #fff; }
    .ww-btn.primary:hover { background: #d63a52; }
    .ww-btn.outline { background: rgba(255,255,255,.1); border: 1px solid rgba(255,255,255,.2); color: #fff; }
    .ww-btn.outline:hover { background: rgba(255,255,255,.2); color: #fff; }

    /* ── RESPONSIVE NAV: hide/show helpers ── */
    .nav-desktop-only { display: flex; }
    .nav-mobile-only  { display: none; }
    @media (max-width: 768px) {
      .nav-desktop-only { display: none !important; }
      .nav-mobile-only  { display: flex !important; }
      /* On mobile: nav-right only shows cart + avatar */
      .nav-right { gap: 0.5rem; }
    }

    /* ── AI CHAT WIDGET: draggable support + visual connector ── */
    .ai-chat-widget-wrap {
      position: fixed !important;
      touch-action: none;
      user-select: none;
      -webkit-user-select: none;
    }

    /* MOBILE FIX: lift chat FAB above the 64px bottom nav so it's always visible */
    @media (max-width: 768px) {
      #kw-fab {
        bottom: 76px !important;   /* 64px bottom-nav + 12px gap */
        right:  16px !important;
        z-index: 1050 !important;  /* above bottom-nav (900) and modals (1000) */
      }
      #kw-panel {
        z-index: 1040 !important;
        /* Full-screen on mobile — override any inline top/left from drag code */
      }
      /* On mobile panel goes full-screen — disable drag positioning */
      #kw-panel:not(.kh):not(.km) {
        bottom: 0  !important;
        right:  0  !important;
        left:   0  !important;
        top:    0  !important;
        width:  100vw  !important;
        height: 100dvh !important;
        border-radius: 0 !important;
        border-bottom-right-radius: 0 !important;
      }
      /* Hide the connector arrow on mobile (full-screen panel) */
      #kw-panel:not(.kh):not(.km)::after,
      #kw-panel:not(.kh):not(.km)::before { display: none !important; }
    }

    /* Connector arrow: a pseudo-element on #kw-panel that points down toward the FAB */
    #kw-panel:not(.kh):not(.km)::after {
      content: '';
      position: absolute;
      bottom: -10px;
      right: 20px;          /* aligns roughly over FAB; JS will nudge if needed */
      width: 0;
      height: 0;
      border-left:  11px solid transparent;
      border-right: 11px solid transparent;
      border-top:   11px solid #fff;          /* matches panel bg */
      filter: drop-shadow(0 3px 4px rgba(14,165,233,.13));
      pointer-events: none;
      z-index: 10001;
    }
    /* Outer border for the arrow */
    #kw-panel:not(.kh):not(.km)::before {
      content: '';
      position: absolute;
      bottom: -12px;
      right: 19px;
      width: 0;
      height: 0;
      border-left:  12px solid transparent;
      border-right: 12px solid transparent;
      border-top:   12px solid rgba(226,232,240,.9);  /* matches panel border colour */
      pointer-events: none;
      z-index: 10000;
    }
    /* Remove rounded corner on the side closest to FAB for seamless look */
    #kw-panel:not(.kh):not(.km) {
      border-bottom-right-radius: 6px !important;
    }
  </style>
</head>
<body>

<!-- ══ TOP NAV ══ -->
<nav class="top-nav">
  <div class="nav-left">
    <button class="hamburger-btn" id="hamburgerBtn" aria-label="Open menu">
      <i class="bi bi-list" style="font-size:1.3rem;"></i>
    </button>
    <a class="nav-brand" href="customerDashboard.jsp">
      <i class="bi bi-bag-heart-fill"></i>SIBS<span class="brand-dot">•</span>STORE
    </a>
  </div>

  <div class="nav-search">
    <i class="bi bi-search search-icon"></i>
    <input type="text" id="searchField" placeholder="Search products, brands, categories…">
  </div>

  <div class="nav-right">
    <%-- Desktop-only icons --%>
    <a href="WishlistServlet" class="nav-icon-btn nav-desktop-only" title="Wishlist">
      <i class="bi bi-heart"></i>
    </a>
    <a href="CartServlet?action=view" class="nav-icon-btn" title="Cart">
      <i class="bi bi-bag"></i>
      
      <span class="nav-badge" id="cartBadge"><%= cartCount >0 ? cartCount : 0 %></span>
    </a>
    <a href="CustomerOrdersServlet" class="nav-icon-btn nav-desktop-only" title="Orders">
      <i class="bi bi-box-seam"></i>
    </a>
    <a href="CustomerNotifications" class="nav-icon-btn nav-desktop-only" title="Notifications" id="navBellBtn">
      <i class="bi bi-bell"></i>
      <% if (unreadNotifCount > 0) { %>
      <span class="nav-badge" id="navNotifBadge"><%= unreadNotifCount %></span>
      <% } else { %>
      <span class="nav-badge" id="navNotifBadge" style="display:none;">0</span>
      <% } %>
    </a>
    <a href="CustomerWallet" class="nav-icon-btn nav-desktop-only" title="My Wallet">
      <i class="bi bi-wallet2"></i>
    </a>
    <% if (!Boolean.TRUE.equals(loggedIn)) { %>
    <a href="CustomerLogin.jsp" class="nav-icon-btn nav-desktop-only" title="Login">
      <i class="bi bi-box-arrow-in-right"></i>
    </a>
    <% } %>
    <%-- Desktop: full profile pill --%>
    <button class="nav-profile-btn nav-desktop-only" data-bs-toggle="modal" data-bs-target="#profileModal">
      <div class="nav-avatar">
        <%= (customer != null && customer.getName() != null && !customer.getName().isEmpty())
            ? String.valueOf(customer.getName().charAt(0)).toUpperCase()
            : "G" %>
      </div>
      <span class="nav-profile-name">
        <%= (customer != null) ? customer.getName().split(" ")[0] : "Guest" %>
      </span>
      <i class="bi bi-chevron-down" style="font-size:0.7rem;opacity:0.6;"></i>
    </button>
    <%-- Mobile: avatar navigates directly to profile page --%>
    <a href="CustomerProfile" class="nav-avatar nav-mobile-only"
       style="border:2px solid rgba(255,255,255,.35);cursor:pointer;background:var(--accent);
              flex-shrink:0;border-radius:50%;text-decoration:none;color:#fff;
              display:flex;align-items:center;justify-content:center;font-weight:700;">
      <%= (customer != null && customer.getName() != null && !customer.getName().isEmpty())
          ? String.valueOf(customer.getName().charAt(0)).toUpperCase()
          : "G" %>
    </a>
  </div>
</nav>

<!-- ══ SIDEBAR ══ -->
<div class="sidebar-overlay" id="sidebarOverlay"></div>
<aside class="sidebar" id="sidebar">
  <div class="sidebar-head">
    <div class="sidebar-avatar">
      <%= (customer != null && customer.getName() != null && !customer.getName().isEmpty())
          ? String.valueOf(customer.getName().charAt(0)).toUpperCase()
          : "G" %>
    </div>
    <div>
      <div class="sidebar-user-name"><%= (customer != null) ? customer.getName() : "Guest User" %></div>
      <div class="sidebar-user-email"><%= (customer != null) ? customer.getEmail() : "Not signed in" %></div>
    </div>
    <button class="sidebar-close" id="sidebarClose"><i class="bi bi-x-lg"></i></button>
  </div>

  <div class="sidebar-section">
    <div class="sidebar-section-title">Main</div>
    <a href="customerDashboard.jsp" class="sidebar-link active">
      <span class="icon"><i class="bi bi-shop"></i></span> Shop
    </a>
    <a href="CustomerOrdersServlet" class="sidebar-link">
      <span class="icon"><i class="bi bi-box-seam"></i></span> My Orders
      <span class="badge-count">3</span>
    </a>
    <a href="CartServlet?action=view" class="sidebar-link">
      <span class="icon"><i class="bi bi-cart3"></i></span> My Cart
    </a>
    <a href="WishlistServlet" class="sidebar-link">
      <span class="icon"><i class="bi bi-heart"></i></span> Wishlist
    </a>
    
  </div>

  <div class="sidebar-divider"></div>

  <div class="sidebar-section">
    <div class="sidebar-section-title">Account</div>
    <a href="CustomerWallet" class="sidebar-link">
      <span class="icon"><i class="bi bi-wallet2"></i></span> My Wallet
    </a>
    <a href="CustomerProfile" class="sidebar-link">
      <span class="icon"><i class="bi bi-person-circle"></i></span> My Profile
    </a>
    <a href="AddressBook.jsp" class="sidebar-link">
      <span class="icon"><i class="bi bi-geo-alt"></i></span> Address Book
    </a>
    <a href="PaymentMethods.jsp" class="sidebar-link">
      <span class="icon"><i class="bi bi-credit-card"></i></span> Payment Methods
    </a>
    <a href="CustomerNotifications" class="sidebar-link">
      <span class="icon"><i class="bi bi-bell"></i></span> Notifications
      <% if (unreadNotifCount > 0) { %><span class="badge-count"><%= unreadNotifCount %></span><% } %>
    </a>
  </div>

  <div class="sidebar-divider"></div>

  <div class="sidebar-section">
    <div class="sidebar-section-title">Support</div>
    <a href="TrackOrderServlet" class="sidebar-link">
      <span class="icon"><i class="bi bi-truck"></i></span> Track Order
    </a>
    <a href="Returns.jsp" class="sidebar-link">
      <span class="icon"><i class="bi bi-arrow-return-left"></i></span> Returns & Refunds
    </a>
    <a href="HelpDesk" class="sidebar-link">
      <span class="icon"><i class="bi bi-question-circle"></i></span> Help &amp; Support
    </a>
    <a href="ContactUs.jsp" class="sidebar-link">
      <span class="icon"><i class="bi bi-chat-dots"></i></span> Contact Us
    </a>
  </div>

  <div class="sidebar-divider"></div>

  <div class="sidebar-section">
    <div class="sidebar-section-title">Offers & More</div>
    <a href="Coupons.jsp" class="sidebar-link">
      <span class="icon"><i class="bi bi-ticket-perforated"></i></span> Coupons & Offers
    </a>
    <a href="LoyaltyPoints.jsp" class="sidebar-link">
      <span class="icon"><i class="bi bi-star"></i></span> Loyalty Points
    </a>
    <a href="ReferAndEarn.jsp" class="sidebar-link">
      <span class="icon"><i class="bi bi-gift"></i></span> Refer & Earn
    </a>
  </div>

  <div class="sidebar-divider"></div>

  <div class="sidebar-section">
    <% if (Boolean.TRUE.equals(loggedIn)) { %>
    <a href="CustomerLogout" class="sidebar-link" style="color:#dc2626;">
      <span class="icon" style="background:rgba(220,38,38,0.08);color:#dc2626;"><i class="bi bi-box-arrow-right"></i></span> Logout
    </a>
    <% } else { %>
    <a href="CustomerLogin.jsp" class="sidebar-link">
      <span class="icon"><i class="bi bi-box-arrow-in-right"></i></span> Login
    </a>
    <a href="CustomerRegistration.jsp" class="sidebar-link">
      <span class="icon"><i class="bi bi-person-plus"></i></span> Register
    </a>
    <% } %>
  </div>
</aside>

<!-- ══ MAIN ══ -->
<main class="main-content">

  <!-- Promo Ticker -->
  <div class="promo-strip">
    <div class="promo-ticker" id="promoTicker">
      <span class="promo-item"><i class="bi bi-tag-fill"></i> FLAT 20% OFF on Electronics — Code: ELEC20</span>
      <span class="promo-item"><i class="bi bi-truck"></i> FREE Delivery on orders above ₹499</span>
      <span class="promo-item"><i class="bi bi-gift-fill"></i> Buy 2 Get 1 FREE on Fashion items</span>
      <span class="promo-item"><i class="bi bi-clock-fill"></i> Flash Sale ends in: <strong id="flashCountdown">02:45:30</strong></span>
      <span class="promo-item"><i class="bi bi-tag-fill"></i> FLAT 20% OFF on Electronics — Code: ELEC20</span>
      <span class="promo-item"><i class="bi bi-truck"></i> FREE Delivery on orders above ₹499</span>
      <span class="promo-item"><i class="bi bi-gift-fill"></i> Buy 2 Get 1 FREE on Fashion items</span>
      <span class="promo-item"><i class="bi bi-clock-fill"></i> Flash Sale ends in: <strong>02:45:30</strong></span>
    </div>
  </div>

  <!-- Hero Banner -->
  <div class="hero-banner">
    <div class="hero-inner">
      <div class="hero-text">
        <h1>
          <%= (customer != null) ? "Welcome back, " + customer.getName().split(" ")[0] + "!" : "Welcome to SIBS Store" %><br>
          <span>Shop Smarter, Save More</span>
        </h1>
        <p>Discover fresh deals on groceries, electronics, fashion & more — all in one place.</p>
        <div class="hero-cta-row">
          <a href="#products" class="btn-accent"><i class="bi bi-lightning-fill"></i> Shop Flash Deals</a>
          <a href="Coupons.jsp" class="btn-outline-white"><i class="bi bi-ticket-perforated"></i> View Coupons</a>
        </div>
      </div>
      <div class="hero-stats">
        <div class="hero-stat">
          <div class="hero-stat-num">5K+</div>
          <div class="hero-stat-label">Products</div>
        </div>
        <div class="hero-stat">
          <div class="hero-stat-num">24h</div>
          <div class="hero-stat-label">Delivery</div>
        </div>
        <div class="hero-stat">
          <div class="hero-stat-num">₹0</div>
          <div class="hero-stat-label">Hidden Fees</div>
        </div>
      </div>
    </div>
  </div>

 

  <!-- Wallet Widget -->
  <% if (Boolean.TRUE.equals(loggedIn)) { %>
  <div class="products-wrapper" style="padding-bottom:0; padding-top:1.25rem;">
    <a href="CustomerWallet" class="wallet-widget">
      <div class="ww-left">
        <div class="ww-icon"><i class="bi bi-wallet2"></i></div>
        <div>
          <div class="ww-label">My Wallet Balance</div>
          <div class="ww-balance">₹<%= String.format("%.2f", walletBalance) %></div>
        </div>
      </div>
      <div class="ww-right">
        <span class="ww-btn outline"><i class="bi bi-clock-history"></i> History</span>
        <span class="ww-btn primary"><i class="bi bi-plus-circle"></i> Add Money</span>
      </div>
    </a>
  </div>
  <% } %>

  <!-- Toolbar -->
  <div class="toolbar">
    <div class="category-chips">
      <a class="chip active" data-category="all">🏠 All</a>
      <a class="chip" data-category="fruits">🍎 Fruits</a>
      <a class="chip" data-category="vegetables">🥦 Veggies</a>
      <a class="chip" data-category="packed_food">📦 Packed Food</a>
      <a class="chip" data-category="dairy_products">🥛 Dairy</a>
      <a class="chip" data-category="fashion">👗 Fashion</a>
      <a class="chip" data-category="books">📚 Books</a>
      <a class="chip" data-category="electronics">📱 Electronics</a>
      <a class="chip" data-category="home_furniture">🛋️ Home</a>
      <a class="chip" data-category="beauty">💄 Beauty</a>
      <a class="chip" data-category="sports">🏀 Sports</a>
    </div>
    <div class="toolbar-right">
      <select class="sort-select" id="sortFilter">
        <option value="">Sort: Featured</option>
        <option value="price_asc">Price: Low to High</option>
        <option value="price_desc">Price: High to Low</option>
        <option value="discount">Best Discount</option>
        <option value="newest">Newest First</option>
      </select>
      <div class="view-toggle">
        <button class="view-btn active" id="gridViewBtn" title="Grid view"><i class="bi bi-grid-3x3-gap"></i></button>
        <button class="view-btn" id="listViewBtn" title="List view"><i class="bi bi-list-ul"></i></button>
      </div>
    </div>
  </div>

  <!-- Products -->
  <div class="products-wrapper" id="products">
    <div class="section-header">
      <div class="section-title">All Products</div>
      <a href="#" class="see-all">See all <i class="bi bi-arrow-right"></i></a>
    </div>
    <div id="productGrid" style="min-height:200px;">
      <div class="text-center py-5"><div class="spinner-border text-primary" style="width:2.5rem;height:2.5rem;"></div><p class="mt-3 text-muted" style="font-size:.88rem;">Loading products…</p></div>
    </div>
  </div>

  <!-- Recently Viewed -->
  <div class="recently-bar" id="recentlyViewed" style="display:none;">
    <div class="recently-title"><i class="bi bi-clock-history"></i> Recently Viewed</div>
    <div class="recently-items" id="recentlyItems"></div>
  </div>
</main>

<!-- ══ QUICK VIEW MODAL ══ -->
<div class="modal fade" id="quickViewModal" tabindex="-1">
  <div class="modal-dialog modal-lg modal-dialog-centered">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title"><i class="bi bi-eye"></i> Quick View</h5>
        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body" id="quickViewContent">
        <div class="text-center py-4"><div class="spinner-border text-primary"></div></div>
      </div>
    </div>
  </div>
</div>

<!-- ══ PROFILE MODAL ══ -->
<div class="modal fade profile-modal" id="profileModal" tabindex="-1">
  <div class="modal-dialog modal-dialog-centered" style="max-width:360px;">
    <div class="modal-content">
      <div class="profile-modal-head">
        <button type="button" class="btn-close btn-close-white position-absolute top-0 end-0 m-3" data-bs-dismiss="modal"></button>
        <div class="profile-modal-avatar">
          <%= (customer != null && customer.getName() != null && !customer.getName().isEmpty())
              ? String.valueOf(customer.getName().charAt(0)).toUpperCase()
              : "G" %>
        </div>
        <div class="profile-modal-name"><%= (customer != null) ? customer.getName() : "Guest User" %></div>
        <div class="profile-modal-email"><%= (customer != null) ? customer.getEmail() : "Please login to continue" %></div>
      </div>
      <div class="profile-modal-body">
        <a href="CustomerProfile" class="profile-action">
          <span class="pa-icon" style="background:#eff6ff;color:#1d4ed8;"><i class="bi bi-person-circle"></i></span>
          My Account
        </a>
        <a href="CustomerOrdersServlet" class="profile-action">
          <span class="pa-icon" style="background:#f0fdf4;color:#15803d;"><i class="bi bi-box-seam"></i></span>
          My Orders
        </a>
        <a href="WishlistServlet" class="profile-action">
          <span class="pa-icon" style="background:#fff1f2;color:#e11d48;"><i class="bi bi-heart"></i></span>
          Wishlist
        </a>
        <a href="CustomerWallet" class="profile-action">
          <span class="pa-icon" style="background:#f0f4ff;color:#3b5bdb;"><i class="bi bi-wallet2"></i></span>
          My Wallet
        </a>
        
        <a href="LoyaltyPoints.jsp" class="profile-action">
          <span class="pa-icon" style="background:#fdf4ff;color:#7e22ce;"><i class="bi bi-star"></i></span>
          Loyalty Points
        </a>
        <hr style="margin:0.75rem 0; opacity:0.1;">
        <a href="CustomerLogout" class="profile-action danger">
          <span class="pa-icon" style="background:#fef2f2;color:#dc2626;"><i class="bi bi-box-arrow-right"></i></span>
          Logout
        </a>
      </div>
    </div>
  </div>
</div>
 <!-- Trust Bar -->
  <div class="trust-bar">
    <div class="trust-item">
      <div class="trust-icon"><i class="bi bi-truck"></i></div>
      <div><div class="trust-label">Free Delivery</div><div class="trust-sub">On orders above ₹499</div></div>
    </div>
    <div class="trust-item">
      <div class="trust-icon"><i class="bi bi-arrow-return-left"></i></div>
      <div><div class="trust-label">Easy Returns</div><div class="trust-sub">7-day hassle-free return</div></div>
    </div>
    <div class="trust-item">
      <div class="trust-icon"><i class="bi bi-shield-check"></i></div>
      <div><div class="trust-label">Secure Payments</div><div class="trust-sub">100% encrypted checkout</div></div>
    </div>
    <div class="trust-item">
      <div class="trust-icon"><i class="bi bi-headset"></i></div>
      <div><div class="trust-label">24/7 Support</div><div class="trust-sub">Always here to help</div></div>
    </div>
    <div class="trust-item">
      <div class="trust-icon"><i class="bi bi-star"></i></div>
      <div><div class="trust-label">Loyalty Points</div><div class="trust-sub">Earn on every order</div></div>
    </div>
  </div>
<!-- ══ FOOTER ══ -->
<footer>
  <div class="footer-grid">
    <div>
      <div class="footer-brand"><i class="bi bi-bag-heart-fill"></i> SIBS STORE</div>
      <p class="footer-desc">Your trusted one-stop destination for fresh groceries, electronics, fashion, and everything in between — delivered to your doorstep.</p>
    </div>
    <div>
      <div class="footer-col-title">Quick Links</div>
      <a href="customerDashboard.jsp" class="footer-link">Shop</a>
      <a href="CustomerOrdersServlet" class="footer-link">My Orders</a>
      <a href="WishlistServlet" class="footer-link">Wishlist</a>
      <a href="Coupons.jsp" class="footer-link">Offers & Coupons</a>
    </div>
    <div>
      <div class="footer-col-title">Support</div>
      <a href="HelpCenter.jsp" class="footer-link">Help Center</a>
      <a href="TrackOrderServlet" class="footer-link">Track Order</a>
      <a href="Returns.jsp" class="footer-link">Returns & Refunds</a>
      <a href="ContactUs.jsp" class="footer-link">Contact Us</a>
    </div>
    <div>
      <div class="footer-col-title">Stay Connected</div>
      <p style="font-size:0.82rem;color:rgba(255,255,255,0.5);margin-bottom:0.75rem;">Subscribe for exclusive deals and updates.</p>
      <div style="display:flex;gap:0.5rem;margin-bottom:1rem;">
        <input type="email" placeholder="Your email" style="flex:1;padding:0.5rem 0.75rem;border-radius:8px;border:1px solid rgba(255,255,255,0.2);background:rgba(255,255,255,0.08);color:#fff;font-size:0.83rem;outline:none;">
        <button class="btn-accent" style="padding:0.5rem 0.85rem;border-radius:8px;font-size:0.83rem;">Go</button>
      </div>
      <div class="footer-social">
        <a href="#" class="social-icon"><i class="bi bi-facebook"></i></a>
        <a href="#" class="social-icon"><i class="bi bi-instagram"></i></a>
        <a href="#" class="social-icon"><i class="bi bi-twitter-x"></i></a>
        <a href="#" class="social-icon"><i class="bi bi-whatsapp"></i></a>
      </div>
    </div>
  </div>
  <div class="footer-bottom">
    <span>&copy; 2026 SIBS Store — Smart Inventory & Billing System. All rights reserved.</span>
    <span>Made with <i class="bi bi-heart-fill" style="color:var(--accent);"></i> for our customers</span>
  </div>
</footer>

<!-- Toast Container -->
<div class="toast-container" id="toastContainer"></div>
      <jsp:include page="aiChatWidget.jsp" />

<!-- ══ MOBILE SEARCH OVERLAY ══ -->
<div class="mobile-search-overlay" id="mobileSearchOverlay" onclick="closeMobileSearch(event)">
  <div class="mobile-search-box">
    <i class="bi bi-search" style="color:var(--muted);font-size:1.1rem;flex-shrink:0;"></i>
    <input type="search" id="mobileSearchInput" placeholder="Search products, brands, categories…"
           autocomplete="off" autocorrect="off" spellcheck="false" enterkeyhint="search">
    <button class="mobile-search-close" onclick="document.getElementById('mobileSearchOverlay').classList.remove('open');document.getElementById('mobileSearchInput').value='';">×</button>
  </div>
</div>

<!-- ══ BOTTOM NAV ══ -->
<nav class="bottom-nav">
  <div class="bottom-nav-inner">
    <%-- BUG FIX: was linking to customerDashboard.jsp (direct JSP, breaks session checks).
         Must link to the /Customer servlet which sets all required request attributes. --%>
    <a href="Customer" class="bn-item active">
      <i class="bi bi-house-fill"></i>Home
    </a>
    <button class="bn-item" onclick="openMobileSearch()">
      <i class="bi bi-search"></i>Search
    </button>
    <a href="CartServlet?action=view" class="bn-item">
      <i class="bi bi-bag"></i>Cart
      <span class="bn-badge"><%= session.getAttribute("cartCount") != null ? session.getAttribute("cartCount") : 0 %></span>
    </a>
    <a href="CustomerNotifications" class="bn-item">
      <div style="position:relative;display:inline-flex;">
        <i class="bi bi-bell"></i>
        <% if (unreadNotifCount > 0) { %>
        <span class="bn-badge" id="bnNotifBadge"><%= unreadNotifCount %></span>
        <% } else { %>
        <span class="bn-badge" id="bnNotifBadge" style="display:none;"></span>
        <% } %>
      </div>
      Alerts
    </a>
    <%-- BUG FIX: mobile nav had no profile or login link --%>
    <% if (Boolean.TRUE.equals(loggedIn)) { %>
    <a href="CustomerProfile" class="bn-item">
      <i class="bi bi-person-circle"></i>Profile
    </a>
    <% } else { %>
    <a href="CustomerLogin.jsp" class="bn-item">
      <i class="bi bi-box-arrow-in-right"></i>Login
    </a>
    <% } %>
  </div>
</nav>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
<script>
/* ── Sidebar ── */
const sidebar = document.getElementById('sidebar');
const overlay = document.getElementById('sidebarOverlay');
function openSidebar() { sidebar.classList.add('open'); overlay.classList.add('open'); document.body.style.overflow='hidden'; }
function closeSidebar() { sidebar.classList.remove('open'); overlay.classList.remove('open'); document.body.style.overflow=''; }
document.getElementById('hamburgerBtn').addEventListener('click', openSidebar);
document.getElementById('sidebarClose').addEventListener('click', closeSidebar);
overlay.addEventListener('click', closeSidebar);

/* ── Flash Countdown ── */
(function() {
  let secs = 2*3600 + 45*60 + 30;
  function fmt(s) { const h=String(Math.floor(s/3600)).padStart(2,'0'); const m=String(Math.floor((s%3600)/60)).padStart(2,'0'); const sec=String(s%60).padStart(2,'0'); return h+':'+m+':'+sec; }
  const el = document.getElementById('flashCountdown');
  if (el) setInterval(() => { secs--; if(secs<0)secs=0; el.textContent=fmt(secs); }, 1000);
})();

/* ── Toast ── */
function showToast(msg, icon='bi-check-circle-fill', color='var(--primary)') {
  const c = document.getElementById('toastContainer');
  const t = document.createElement('div');
  t.className = 'toast-msg';
  t.style.background = color;
  t.innerHTML = `<i class="bi ${icon}" style="font-size:1.1rem;"></i> ${msg}`;
  c.appendChild(t);
  setTimeout(() => t.remove(), 3000);
}

/* ── Category Chips ── */
document.querySelectorAll("[data-category]").forEach(btn => {
  btn.addEventListener("click", function(e) {
    e.preventDefault();
    document.querySelectorAll("[data-category]").forEach(b => b.classList.remove('active'));
    this.classList.add('active');
    const category = this.getAttribute("data-category");
    const url = category === 'all'
      ? "ProductServlet?action=listCustomer&page=1"
      : "ProductServlet?action=filter&category=" + encodeURIComponent(category);
    fetch(url, { headers: { "X-Requested-With": "XMLHttpRequest" } })
      .then(res => res.text())
      .then(html => { document.getElementById("productGrid").innerHTML = html; attachListeners(); });
  });
});

/* ── On Load ── */
document.addEventListener("DOMContentLoaded", function() {
  const searchField = document.getElementById("searchField");
  const sortFilter = document.getElementById("sortFilter");

  loadProducts(1);

  // Desktop search
  if (searchField) {
    let searchTimer;
    searchField.addEventListener("input", () => {
      clearTimeout(searchTimer);
      searchTimer = setTimeout(() => {
        const query = searchField.value.trim();
        const url = query
          ? "ProductServlet?action=search&query=" + encodeURIComponent(query)
          : "ProductServlet?action=listCustomer&page=1";
        fetch(url, { headers: { "X-Requested-With": "XMLHttpRequest" } })
          .then(res => res.text())
          .then(html => { document.getElementById("productGrid").innerHTML = html; attachListeners(); })
          .catch(() => {});
      }, 350);
    });
    // Also keep keyup for Enter key
    searchField.addEventListener("keyup", (e) => {
      if (e.key === "Enter") searchField.dispatchEvent(new Event("input"));
    });
  }

  if (sortFilter) {
    sortFilter.addEventListener("change", () => {
      fetch("ProductServlet?action=sort&sortBy=" + encodeURIComponent(sortFilter.value), { headers: { "X-Requested-With": "XMLHttpRequest" } })
        .then(res => res.text())
        .then(html => { document.getElementById("productGrid").innerHTML = html; attachListeners(); })
        .catch(() => {});
    });
  }

  /* View toggle */
  document.getElementById('gridViewBtn').addEventListener('click', function() {
    const grid = document.getElementById('productGrid');
    grid.classList.remove('list-view');
    this.classList.add('active'); document.getElementById('listViewBtn').classList.remove('active');
  });
  document.getElementById('listViewBtn').addEventListener('click', function() {
    const grid = document.getElementById('productGrid');
    grid.classList.add('list-view');
    this.classList.add('active'); document.getElementById('gridViewBtn').classList.remove('active');
  });
});

function loadProducts(page) {
  const grid = document.getElementById("productGrid");
  grid.innerHTML = '<div class="text-center py-5"><div class="spinner-border text-primary" style="width:2rem;height:2rem;"></div><p class="mt-2 text-muted" style="font-size:.85rem;">Loading…</p></div>';
  fetch("ProductServlet?action=listCustomer&page=" + page, { headers: { "X-Requested-With": "XMLHttpRequest" } })
    .then(res => {
      if (!res.ok) throw new Error("Network error " + res.status);
      return res.text();
    })
    .then(html => { grid.innerHTML = html; attachListeners(); })
    .catch(err => {
      grid.innerHTML = '<div class="text-center py-5 text-muted"><i class="bi bi-wifi-off" style="font-size:2rem;opacity:.4;"></i><p class="mt-2" style="font-size:.88rem;">Could not load products. <a href="#" onclick="loadProducts(1);return false;">Retry</a></p></div>';
      console.error("loadProducts failed:", err);
    });
}

function attachListeners() {
  document.querySelectorAll(".page-btn").forEach(btn => {
    btn.addEventListener("click", function() {
      const page = this.getAttribute("data-page");
      if (!page || this.parentElement.classList.contains("disabled")) return;
      loadProducts(page);
      window.scrollTo({ top: 0, behavior: 'smooth' });
    });
  });
  document.querySelectorAll(".quick-view-btn").forEach(btn => {
    btn.addEventListener("click", function() { quickView(this.getAttribute("data-id")); });
  });
  document.querySelectorAll(".wish-btn").forEach(btn => {
    btn.addEventListener("click", function(e) {
      e.preventDefault();
      if (this.dataset.login === 'true') { window.location.href = 'CustomerLogin.jsp'; return; }
      const productId = this.getAttribute('data-id');
      const self = this;
      fetch('WishlistServlet?action=toggle&id=' + productId, {
        headers: { 'X-Requested-With': 'XMLHttpRequest' }
      })
      .then(r => r.json())
      .then(data => {
        if (data.success) {
          if (data.wished) {
            self.classList.add('wished');
            self.querySelector('i').className = 'bi bi-heart-fill';
            showToast('Added to Wishlist!', 'bi-heart-fill', '#e94560');
          } else {
            self.classList.remove('wished');
            self.querySelector('i').className = 'bi bi-heart';
            showToast('Removed from Wishlist', 'bi-heart', '#78716c');
          }
        }
      })
      .catch(() => {});
    });
  });

  // ── FIX: wire Buy Now buttons (needed because productGrid loads via AJAX
  // and its own <script> is never executed by the browser after innerHTML inject)
  document.querySelectorAll(".btn-buy:not(.login-buy)").forEach(btn => {
    btn.addEventListener("click", function() {
      const pid = this.getAttribute("data-product-id");
      const qty = this.getAttribute("data-qty") || 1;
      if (pid) buyNow(parseInt(pid, 10), parseInt(qty, 10));
    });
  });
  document.querySelectorAll(".btn-buy.login-buy, .login-redirect").forEach(btn => {
    btn.addEventListener("click", function() {
      window.location.href = 'CustomerLogin.jsp';
    });
  });

  // AJAX Add to Cart — update badge without redirecting
  document.querySelectorAll(".add-to-cart-btn").forEach(btn => {
    btn.addEventListener("click", function() {
      const productId = this.getAttribute('data-id');
      const self = this;
      self.disabled = true;
      self.innerHTML = '<i class="bi bi-hourglass-split"></i> Adding…';
      fetch('CartServlet?action=add&id=' + productId, {
        headers: { 'X-Requested-With': 'XMLHttpRequest' }
      })
      .then(r => r.json())
      .then(data => {
        if (data.success) {
          const badge = document.getElementById('cartBadge');
          if (badge) badge.textContent = data.cartCount;
          const bnBadge = document.querySelector('.bn-badge');
          if (bnBadge) bnBadge.textContent = data.cartCount;
          self.innerHTML = '<i class="bi bi-check-circle-fill"></i> Added!';
          self.style.background = '#10b981';
          showToast('Added to cart!', 'bi-cart-check-fill', '#10b981');
          setTimeout(() => {
            self.innerHTML = '<i class="bi bi-cart-plus"></i> Add to Cart';
            self.style.background = '';
            self.disabled = false;
          }, 1800);
        } else {
          self.innerHTML = '<i class="bi bi-cart-plus"></i> Add to Cart';
          self.disabled = false;
        }
      })
      .catch(() => {
        self.innerHTML = '<i class="bi bi-cart-plus"></i> Add to Cart';
        self.disabled = false;
      });
    });
  });
}

function openMobileSearch() {
  const overlay = document.getElementById('mobileSearchOverlay');
  overlay.classList.add('open');
  // Small delay lets the overlay render before focusing (avoids iOS keyboard jump)
  setTimeout(function() {
    const inp = document.getElementById('mobileSearchInput');
    if (inp) inp.focus();
  }, 120);
}

function closeMobileSearch(e) {
  if (e.target === document.getElementById('mobileSearchOverlay')) {
    document.getElementById('mobileSearchOverlay').classList.remove('open');
  }
}
// Mobile search — independent debounced handler (does NOT mirror desktop)
(function() {
  var mobileInp = document.getElementById('mobileSearchInput');
  if (!mobileInp) return;
  var mobileTimer;
  mobileInp.addEventListener('input', function() {
    clearTimeout(mobileTimer);
    var query = this.value.trim();
    mobileTimer = setTimeout(function() {
      var url = query
        ? 'ProductServlet?action=search&query=' + encodeURIComponent(query)
        : 'ProductServlet?action=listCustomer&page=1';
      fetch(url, { headers: { 'X-Requested-With': 'XMLHttpRequest' } })
        .then(function(r) { return r.text(); })
        .then(function(html) {
          document.getElementById('productGrid').innerHTML = html;
          attachListeners();
          // Sync desktop search field value for visual consistency
          var desktopField = document.getElementById('searchField');
          if (desktopField) desktopField.value = query;
        })
        .catch(function() {});
    }, 350);
  });
  // Close overlay on Enter key
  mobileInp.addEventListener('keydown', function(e) {
    if (e.key === 'Enter') {
      document.getElementById('mobileSearchOverlay').classList.remove('open');
      this.blur();
    }
  });
})();

function quickView(productId) {
  document.getElementById("quickViewContent").innerHTML = '<div class="text-center py-4"><div class="spinner-border text-primary"></div></div>';
  new bootstrap.Modal(document.getElementById("quickViewModal")).show();
  fetch("ProductServlet?action=view&id=" + productId, { headers: { "X-Requested-With": "XMLHttpRequest" } })
    .then(r => r.text())
    .then(html => { setHtmlAndExecScripts(document.getElementById("quickViewContent"), html); });
}

/**
 * Sets innerHTML and re-executes any <script> blocks in the fragment.
 * Browser drops scripts when assigning innerHTML — this restores them.
 */
function setHtmlAndExecScripts(container, html) {
  container.innerHTML = html;
  // Find every script tag in the injected HTML and re-run it
  container.querySelectorAll('script').forEach(function(oldScript) {
    const newScript = document.createElement('script');
    // Copy all attributes (type, src, etc.)
    Array.from(oldScript.attributes).forEach(function(attr) {
      newScript.setAttribute(attr.name, attr.value);
    });
    // Copy inline code
    newScript.textContent = oldScript.textContent;
    // Replace old (inert) script node with live one — this triggers execution
    oldScript.parentNode.replaceChild(newScript, oldScript);
  });
}

/* ── Notification badge polling (every 30 s) ── */
(function pollNotifBadge() {
  function updateBadge(count) {
    var n = parseInt(count, 10) || 0;
    var navBadge = document.getElementById('navNotifBadge');
    var bnBadge  = document.getElementById('bnNotifBadge');
    if (navBadge) { navBadge.textContent = n > 0 ? n : ''; navBadge.style.display = n > 0 ? 'flex' : 'none'; }
    if (bnBadge)  { bnBadge.textContent  = n > 0 ? n : ''; bnBadge.style.display  = n > 0 ? 'flex' : 'none'; }
  }
  function poll() {
    fetch('CustomerNotifications?action=count', { credentials: 'same-origin' })
      .then(function(r) { return r.text(); })
      .then(function(t) { updateBadge(t); })
      .catch(function() {});
  }
  poll();
  setInterval(poll, 30000);
})();

/* ══════════════════════════════════════════════════════════════════
   BUG FIX: buyNow() must live in the PARENT page, not in productGrid.jsp.
   productGrid is injected via innerHTML (AJAX), which means its <script>
   blocks are never executed by the browser — so any function defined there
   is undefined when the Buy Now onclick fires.  Defining buyNow() here,
   in the persistent parent document, guarantees it is always available.
═══════════════════════════════════════════════════════════════════ */
function buyNow(productId, qty) {
  var form = document.getElementById('buyNowForm');
  if (!form) {
    form = document.createElement('form');
    form.id     = 'buyNowForm';
    form.method = 'post';
    form.action = 'BuyNow';
    form.style.display = 'none';

    var pidInput = document.createElement('input');
    pidInput.type = 'hidden'; pidInput.name = 'productId'; pidInput.id = 'buyNowProductId';

    var qtyInput = document.createElement('input');
    qtyInput.type = 'hidden'; qtyInput.name = 'quantity'; qtyInput.id = 'buyNowQty';

    form.appendChild(pidInput);
    form.appendChild(qtyInput);
    document.body.appendChild(form);
  }
  document.getElementById('buyNowProductId').value = productId;
  document.getElementById('buyNowQty').value = qty || 1;
  form.submit();
}

/* ══════════════════════════════════════════════════════════════════
   DRAGGABLE AI CHAT WIDGET  (rewritten — targets #kw-fab + #kw-panel)
   ──────────────────────────────────────────────────────────────────
   aiChatWidget.jsp uses two separate fixed elements:
     #kw-fab   — the round FAB button (drag handle)
     #kw-panel — the chat panel (moved in sync)
   They have no shared wrapper, so we move both elements together.

   Tap-vs-drag distinction:
     • Movement < DRAG_THRESHOLD px  → treated as a normal click (opens chat)
     • Movement >= DRAG_THRESHOLD px → drag; click event is suppressed
   This keeps the toggle working perfectly while still allowing drag.
═══════════════════════════════════════════════════════════════════ */
(function initDraggableChat() {

  var DRAG_THRESHOLD = 6;   // px — move less than this == tap, not drag
  var LONG_PRESS_MS  = 120; // ms — how long before we commit to a drag

  function setupDrag() {
    var fab   = document.getElementById('kw-fab');
    var panel = document.getElementById('kw-panel');
    if (!fab) { setTimeout(setupDrag, 200); return; } // retry until widget loads

    /* ── helpers ── */
    function getFabPos() {
      var r = fab.getBoundingClientRect();
      return { left: r.left, top: r.top, w: r.width, h: r.height };
    }

    function getPanelOffset() {
      // panel sits above the FAB; capture offset at drag-start so it moves in sync
      if (!panel || panel.classList.contains('kh')) return null;
      var pr = panel.getBoundingClientRect();
      var fr = fab.getBoundingClientRect();
      return { dx: pr.left - fr.left, dy: pr.top - fr.top };
    }

    function applyPos(fabLeft, fabTop, panelOff) {
      fab.style.left   = fabLeft + 'px';
      fab.style.top    = fabTop  + 'px';
      fab.style.right  = 'auto';
      fab.style.bottom = 'auto';
      if (panel && panelOff) {
        panel.style.left   = (fabLeft + panelOff.dx) + 'px';
        panel.style.top    = (fabTop  + panelOff.dy) + 'px';
        panel.style.right  = 'auto';
        panel.style.bottom = 'auto';
      }
    }

    function clamp(val, min, max) {
      return Math.max(min, Math.min(max, val));
    }

    /* ── state ── */
    var dragging    = false;
    var didDrag     = false;    // true once threshold exceeded
    var startX, startY, origFabLeft, origFabTop, panelOff;
    var pressTimer;

    /* ── suppress click after a real drag ── */
    fab.addEventListener('click', function(e) {
      if (didDrag) { e.stopImmediatePropagation(); e.preventDefault(); }
    }, true);

    /* ── disable CSS transform transition during drag so there's no lag ── */
    function freezeTransition() {
      fab.style.transition = 'box-shadow .3s, opacity .3s'; // keep shadow, kill transform
    }
    function restoreTransition() {
      fab.style.transition = '';
    }

    function onStart(clientX, clientY) {
      var pos = getFabPos();
      origFabLeft = pos.left;
      origFabTop  = pos.top;
      startX = clientX;
      startY = clientY;
      panelOff = getPanelOffset();
      didDrag  = false;

      // Switch to top/left coord system immediately so dragging isn't fighting bottom/right
      fab.style.right  = 'auto';
      fab.style.bottom = 'auto';
      fab.style.left   = origFabLeft + 'px';
      fab.style.top    = origFabTop  + 'px';

      if (panel) {
        panel.style.right  = 'auto';
        panel.style.bottom = 'auto';
      }

      pressTimer = setTimeout(function() {
        dragging = true;
        freezeTransition();
        fab.style.cursor = 'grabbing';
        document.body.style.userSelect = 'none';
      }, LONG_PRESS_MS);
    }

    function onMove(clientX, clientY) {
      var dx = clientX - startX;
      var dy = clientY - startY;

      if (!dragging) {
        // Start drag immediately once threshold exceeded
        if (Math.abs(dx) > DRAG_THRESHOLD || Math.abs(dy) > DRAG_THRESHOLD) {
          clearTimeout(pressTimer);
          dragging = true;
          didDrag  = true;
          freezeTransition();
          fab.style.cursor = 'grabbing';
          document.body.style.userSelect = 'none';
        } else {
          return;
        }
      }

      didDrag = true;

      var vw = window.innerWidth;
      var vh = window.innerHeight;
      var fw = fab.offsetWidth  || 56;
      var fh = fab.offsetHeight || 56;

      var newLeft = clamp(origFabLeft + dx, 8, vw - fw - 8);
      var newTop  = clamp(origFabTop  + dy, 8, vh - fh - 8);

      applyPos(newLeft, newTop, panelOff);
    }

    function onEnd() {
      clearTimeout(pressTimer);
      if (dragging) {
        dragging = false;
        restoreTransition();
        fab.style.cursor = '';
        document.body.style.userSelect = '';

        // Snap panel back relative to FAB if it's open
        if (panel && !panel.classList.contains('kh') && !panel.classList.contains('km')) {
          var fr = fab.getBoundingClientRect();
          var vw = window.innerWidth;
          var vh = window.innerHeight;
          var pw = panel.offsetWidth  || 360;
          var ph = panel.offsetHeight || 480;
          // Panel appears above-left of FAB; clamp within viewport
          var pLeft = clamp(fr.left + panelOff.dx, 8, vw - pw - 8);
          var pTop  = clamp(fr.top  + panelOff.dy, 8, vh - ph - 8);
          panel.style.left = pLeft + 'px';
          panel.style.top  = pTop  + 'px';
        }

        // Persist to sessionStorage
        try {
          sessionStorage.setItem('kwFabPos', JSON.stringify({
            left: fab.style.left, top: fab.style.top
          }));
        } catch(e) {}
      }
      // reset didDrag after a short delay so the suppressed click fires cleanly
      setTimeout(function() { didDrag = false; }, 50);
    }

    // ── Mouse ──
    fab.addEventListener('mousedown', function(e) {
      if (e.button !== 0) return;
      onStart(e.clientX, e.clientY);
      // Don't preventDefault — let click fire normally for taps
    });
    document.addEventListener('mousemove', function(e) {
      if (!startX && startX !== 0) return;
      onMove(e.clientX, e.clientY);
    });
    document.addEventListener('mouseup', function() {
      if (startX !== undefined) { onEnd(); startX = undefined; }
    });

    // ── Touch ──
    fab.addEventListener('touchstart', function(e) {
      var t = e.touches[0];
      onStart(t.clientX, t.clientY);
    }, { passive: true });

    document.addEventListener('touchmove', function(e) {
      if (startX === undefined) return;
      var t = e.touches[0];
      onMove(t.clientX, t.clientY);
      if (dragging) e.preventDefault(); // only block scroll once drag confirmed
    }, { passive: false });

    document.addEventListener('touchend', function() {
      if (startX !== undefined) { onEnd(); startX = undefined; }
    });

    // ── Restore saved position on page load ──
    try {
      var saved = JSON.parse(sessionStorage.getItem('kwFabPos') || 'null');
      if (saved && saved.left && saved.top) {
        fab.style.right  = 'auto';
        fab.style.bottom = 'auto';
        fab.style.left   = saved.left;
        fab.style.top    = saved.top;
      }
    } catch(e) {}

    fab.style.cursor = 'grab';
  }

  // Run after DOM ready — widget is included synchronously via jsp:include
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function() { setTimeout(setupDrag, 150); });
  } else {
    setTimeout(setupDrag, 150);
  }
})();

/* ══════════════════════════════════════════════════════════════════
   PATCH KW.open() and KW.close() so the panel always anchors to
   the FAB's CURRENT position after dragging.

   Root cause of the visual disconnect:
     #kw-panel has "bottom:92px; right:26px" in CSS.
     KW.open() just removes class="kh" (display:none) — no inline coords.
     So after dragging the FAB to a new spot, the panel still pops up
     at the original bottom-right corner, visually disconnected.

   Fix: wrap KW.open/close to set panel inline left/top relative to
   the FAB rect before showing, and clear them on close so CSS rules
   cleanly take over again on a fresh page load.
═══════════════════════════════════════════════════════════════════ */
(function patchKWPosition() {

  // Gap in px between FAB top edge and panel bottom edge
  var PANEL_GAP = 12;

  function positionPanelNearFab() {
    var fab   = document.getElementById('kw-fab');
    var panel = document.getElementById('kw-panel');
    if (!fab || !panel) return;

    var fabRect = fab.getBoundingClientRect();
    var vw = window.innerWidth;
    var vh = window.innerHeight;

    // Panel dimensions (may be 0 while hidden — use known defaults)
    var pw = panel.offsetWidth  || Math.min(480, vw - 16);
    var ph = panel.offsetHeight || Math.min(680, vh - 108);

    // Preferred position: panel sits directly above the FAB, right-aligned with it
    var preferredLeft = fabRect.right - pw;
    var preferredTop  = fabRect.top   - ph - PANEL_GAP;

    // Clamp so panel stays fully inside the viewport
    var left = Math.max(8, Math.min(vw - pw - 8, preferredLeft));
    var top  = Math.max(8, Math.min(vh - ph - 8, preferredTop));

    panel.style.left   = left + 'px';
    panel.style.top    = top  + 'px';
    panel.style.right  = 'auto';
    panel.style.bottom = 'auto';

    // Align the CSS ::after arrow so it always points at the FAB center
    // The arrow's `right` offset is: panel right edge  minus FAB center  minus half arrow width
    var panelRight  = left + pw;
    var fabCenterX  = fabRect.left + fabRect.width / 2;
    var arrowRight  = panelRight - fabCenterX - 11;  // 11 = half arrow width
    arrowRight      = Math.max(12, Math.min(pw - 34, arrowRight));
    // Inject a tiny <style> scoped override (cleanest cross-browser way to set ::after right)
    var styleId = 'kw-arrow-style';
    var styleEl = document.getElementById(styleId);
    if (!styleEl) {
      styleEl = document.createElement('style');
      styleEl.id = styleId;
      document.head.appendChild(styleEl);
    }
    styleEl.textContent =
      '#kw-panel:not(.kh):not(.km)::after  { right: ' + arrowRight + 'px !important; }' +
      '#kw-panel:not(.kh):not(.km)::before { right: ' + (arrowRight - 1) + 'px !important; }';
  }

  function waitForKW(cb) {
    if (window.KW && window.KW.open) { cb(); return; }
    setTimeout(function() { waitForKW(cb); }, 80);
  }

  waitForKW(function() {
    var _origOpen  = KW.open.bind(KW);
    var _origClose = KW.close.bind(KW);

    KW.open = function() {
      // On mobile the panel goes full-screen — skip FAB-relative positioning
      if (window.innerWidth > 768) {
        positionPanelNearFab();
        setTimeout(positionPanelNearFab, 50);
      } else {
        // Clear any inline drag coords so CSS full-screen rules take over
        var p = document.getElementById('kw-panel');
        if (p) { p.style.left = p.style.top = p.style.right = p.style.bottom = ''; }
      }
      _origOpen();
    };

    KW.close = function() {
      _origClose();
      // Clear inline coords so CSS defaults work cleanly on next fresh load
      var panel = document.getElementById('kw-panel');
      if (panel) {
        panel.style.left   = '';
        panel.style.top    = '';
        panel.style.right  = '';
        panel.style.bottom = '';
      }
    };

    // Also patch toggle() since it calls open/close directly
    var _origToggle = KW.toggle.bind(KW);
    KW.toggle = function() {
      // Re-use patched open/close — just call based on current state
      var panel = document.getElementById('kw-panel');
      var isOpen = panel && !panel.classList.contains('kh');
      if (isOpen) { KW.close(); } else { KW.open(); }
    };

    // Handle the banner "Need help?" click which calls KW.open() too
    var banner = document.getElementById('kw-banner');
    if (banner) {
      banner.onclick = function() { KW.open(); };
    }

    // If FAB is already in a saved position on page load, pre-position panel
    try {
      var saved = JSON.parse(sessionStorage.getItem('kwFabPos') || 'null');
      if (saved && saved.left) {
        // Panel starts hidden (kh class) so just ensure inline coords are clean
        var panel2 = document.getElementById('kw-panel');
        if (panel2) {
          panel2.style.left = panel2.style.top = panel2.style.right = panel2.style.bottom = '';
        }
      }
    } catch(e) {}
  });
})();

</script>
</body>
</html>
