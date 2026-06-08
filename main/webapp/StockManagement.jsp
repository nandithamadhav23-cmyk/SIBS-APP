<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.*, com.util.*" %>
<%
    String role  = (session != null) ? (String) session.getAttribute("role")     : null;
    String uname = (session != null) ? (String) session.getAttribute("username") : null;
    if (role == null || (!("staff".equalsIgnoreCase(role)) && !("admin".equalsIgnoreCase(role)))) {
        response.sendRedirect("index.jsp?error=Access denied.");
        return;
    }
    List<Product> products = (List<Product>) request.getAttribute("products");
    String message = (String) request.getAttribute("message");
    int totalProducts = 0, lowStock = 0, outOfStock = 0, inStock = 0;
    if (products != null) {
        totalProducts = products.size();
        for (Product p : products) {
            if (p.getStock() == 0)      outOfStock++;
            else if (p.getStock() < 10) lowStock++;
            else                         inStock++;
        }
    }
    String initials = (uname != null && uname.length() >= 2) ? uname.substring(0,2).toUpperCase() : (uname != null ? uname.toUpperCase() : "ST");
    String nowStr = new java.text.SimpleDateFormat("dd MMM yyyy, hh:mm a").format(new java.util.Date());
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
  <title>Stock Management — SmartStock</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
  <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
  <style>
    :root {
 --primary: #27d2c2;
  --primary-mid: #63b3f9fc;
  --primary-light: #e0e7ff;
  --accent:        #6366f1;
  --accent-h:      #4f46e5;
  --accent-light:  #eef2ff;
  --accent-bg:     #eef2ff;
  --coral:         #f97316;
  --coral-bg:      #fff7ed;
  --success:       #059669;  --success-bg: #d1fae5;
  --green:         #059669;  --green-bg:   #d1fae5;
  --warning:       #d97706;  --warning-bg: #fef3c7;
  --amber:         #d97706;  --amber-bg:   #fef3c7;
  --danger:        #dc2626;  --danger-bg:  #fee2e2;
  --red:           #dc2626;  --red-bg:     #fee2e2;
  --purple:        #7c3aed;  --purple-bg:  #ede9fe;
  --teal:          #0891b2;  --teal-bg:    #cffafe;
  --text:          #1e1b4b;
  --text-m:        #4b5563;
  --text-mid:      #4b5563;
  --text-sm:       #6b7280;
  --text-soft:     #6b7280;
  --text-muted:    #9ca3af;
  --border:        #e0e7ff;
  --bg:            #f8fafc;
  --bg-off:        #f3f4f6;
  --bg-card:       #ffffff;
  --card:          #ffffff;
  --nav-h:         62px;
  --sidebar-w:     264px;
  --r:             14px;
  --r-sm:          9px;
  --radius:        14px;
  --radius-sm:     9px;
  --shadow:        0 1px 4px rgba(67,56,202,.07),0 4px 18px rgba(67,56,202,.08);
  --shadow-sm:     0 1px 4px rgba(67,56,202,.07),0 4px 18px rgba(67,56,202,.08);
  --shadow-md:     0 6px 28px rgba(67,56,202,.14);
  --shadow-card:   0 1px 4px rgba(67,56,202,.07),0 4px 18px rgba(67,56,202,.08);
  --shadow-glow:   0 0 0 3px rgba(99,102,241,.18);
}
    *,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
    html{font-size:16px}
    body{font-family:'Outfit',sans-serif;background:var(--bg-off);color:var(--text);padding-top:var(--nav-h);min-height:100vh;-webkit-font-smoothing:antialiased;padding-bottom:64px;background-image:radial-gradient(ellipse at 80% 0%,rgba(99,102,241,.06) 0%,transparent 60%),radial-gradient(ellipse at 0% 60%,rgba(249,115,22,.04) 0%,transparent 55%);}
    @media(min-width:768px){body{padding-bottom:0}}

    /* NAVBAR */
    .top-navbar{position:fixed;top:0;left:0;right:0;height:var(--nav-h);z-index:1000;background:linear-gradient(135deg,var(--primary) 0%,var(--primary-mid) 100%);display:flex;align-items:center;padding:0 1.1rem;gap:.75rem;box-shadow:0 2px 20px rgba(67,56,202,.25)}
    .hamburger{width:40px;height:40px;border-radius:var(--radius-sm);background:rgba(255,255,255,.08);border:1px solid rgba(255,255,255,.12);color:#fff;display:flex;align-items:center;justify-content:center;cursor:pointer;font-size:1.1rem;flex-shrink:0;position:relative;transition:all .2s;background:none;outline:none}
    .hamburger:hover{background:rgba(255,255,255,.2)!important;border-color:rgba(255,255,255,.4)}
    .tt{position:absolute;bottom:-36px;left:50%;transform:translateX(-50%);background:#312e81;color:#fff;font-size:.7rem;font-weight:500;padding:4px 8px;border-radius:6px;white-space:nowrap;pointer-events:none;opacity:0;transition:opacity .2s;z-index:9999}
    .hamburger:hover .tt,.nav-icon-btn:hover .tt{opacity:1}
    .nav-icon-btn .tt{left:auto;right:0;transform:none}
    .nav-brand{font-size:1.05rem;font-weight:800;color:#fff;text-decoration:none;display:flex;align-items:center;gap:.4rem}
    .nav-brand .dot{color:#fbbf24}
    .nav-right{margin-left:auto;display:flex;align-items:center;gap:.5rem}
    .nav-icon-btn{width:36px;height:36px;border-radius:var(--radius-sm);background:rgba(255,255,255,.08);border:1px solid rgba(255,255,255,.12);color:#fff;display:flex;align-items:center;justify-content:center;cursor:pointer;font-size:.95rem;text-decoration:none;transition:all .2s;position:relative}
    .nav-icon-btn:hover{background:rgba(255,255,255,.2);border-color:rgba(255,255,255,.4);color:#fbbf24}
    .notif-dot{position:absolute;top:-2px;right:-2px;width:8px;height:8px;background:var(--danger);border-radius:50%;border:2px solid var(--primary)}
    .nav-avatar{width:32px;height:32px;border-radius:50%;background:linear-gradient(135deg,#fbbf24,#f97316);display:flex;align-items:center;justify-content:center;font-size:.72rem;font-weight:700;color:#fff;cursor:pointer;border:2px solid rgba(255,255,255,.2);flex-shrink:0;text-decoration:none}

    /* SIDEBAR */
    .sidebar-overlay{position:fixed;inset:0;background:rgba(55,48,163,.25);z-index:990;opacity:0;pointer-events:none;transition:opacity .3s;backdrop-filter:blur(4px)}
    .sidebar-overlay.open{opacity:1;pointer-events:all}
    .sidebar{position:fixed;top:0;left:0;bottom:0;width:var(--sidebar-w);background:#fff;z-index:995;transform:translateX(-100%);transition:transform .3s cubic-bezier(.4,0,.2,1);display:flex;flex-direction:column;overflow:hidden;box-shadow:6px 0 30px rgba(67,56,202,.15)}
    .sidebar.open{transform:translateX(0)}
    .sidebar-head{background:linear-gradient(150deg,var(--primary) 0%,var(--primary-mid) 100%);padding:4.2rem 1.2rem 1.1rem;border-bottom:2px solid rgba(251,191,36,.4)}
    .sidebar-brand{font-size:1rem;font-weight:800;color:#fff;margin-bottom:1rem}
    .sidebar-brand .dot{color:#fbbf24}
    .sidebar-user{display:flex;align-items:center;gap:.75rem}
    .sidebar-avatar{width:44px;height:44px;border-radius:50%;background:linear-gradient(135deg,#fbbf24,#f97316);display:flex;align-items:center;justify-content:center;font-size:1rem;font-weight:700;color:#fff;flex-shrink:0;border:2px solid rgba(255,255,255,.25)}
    .sidebar-uname{font-size:.9rem;font-weight:700;color:#fff}
    .sidebar-role{font-size:.65rem;font-weight:600;letter-spacing:.8px;text-transform:uppercase;color:#fbbf24;margin-top:1px}
    .sidebar-body{flex:1;overflow-y:auto;padding:.75rem .75rem 1rem}
    .sidebar-section{font-size:.62rem;font-weight:700;letter-spacing:1.5px;text-transform:uppercase;color:var(--text-muted);padding:.8rem .6rem .3rem}
    .sidebar-link{display:flex;align-items:center;gap:.7rem;padding:.6rem .75rem;border-radius:var(--radius-sm);color:var(--text-mid);text-decoration:none;font-size:.88rem;font-weight:500;transition:all .18s;margin-bottom:2px;border-left:3px solid transparent}
    .sidebar-link i{font-size:.95rem;width:18px;text-align:center;color:var(--text-muted)}
    .sidebar-link:hover,.sidebar-link.active{background:var(--accent-light);color:var(--accent);border-left-color:var(--accent)}
    .sidebar-link:hover i,.sidebar-link.active i{color:var(--accent)}
    .sidebar-link:hover i,.sidebar-link.active i{color:var(--accent)}
    .sidebar-link.active{font-weight:700}
    .sidebar-link.danger{color:#ef4444}.sidebar-link.danger i{color:#ef4444}
    .sidebar-link.danger:hover{background:var(--danger-bg);border-left-color:#ef4444}
    .sidebar-footer{padding:.75rem;border-top:1px solid var(--border);font-size:.72rem;color:var(--text-muted);text-align:center}
    @media(min-width:768px){
      .sidebar{transform:translateX(0);box-shadow:none;border-right:1px solid var(--border)}
      .sidebar-overlay{display:none}
      .main-content{margin-left:var(--sidebar-w);padding:1.5rem 2rem}
      /* Keep hamburger visible so desktop collapse is possible */
      .hamburger{display:flex}
    }
    /* Desktop collapsible sidebar */
    @media(min-width:768px){
      .sidebar.collapsed{transform:translateX(-100%)}
      .main-content.sidebar-collapsed{margin-left:0}
    }

    /* MAIN */
    .main-content{padding:1rem;max-width:100%}

    /* Page Header */
    .page-header{background:var(--card);border-radius:var(--radius);padding:1rem 1.25rem;margin-bottom:1rem;border:1px solid var(--border);box-shadow:var(--shadow);display:flex;align-items:flex-start;justify-content:space-between;gap:1rem;flex-wrap:wrap}
    .page-title{font-size:1.15rem;font-weight:800;color:var(--text)}
    .page-title i{color:var(--accent);margin-right:.3rem}
    .page-subtitle{font-size:.78rem;color:var(--text-muted);margin-top:2px}
    .btn-back{display:inline-flex;align-items:center;gap:.35rem;padding:.45rem .875rem;border:1px solid var(--border);border-radius:var(--radius-sm);background:var(--card);color:var(--text-mid);font-size:.78rem;font-weight:600;text-decoration:none;transition:all .18s;white-space:nowrap}
    .btn-back:hover{border-color:var(--accent);color:var(--accent);background:var(--accent-light)}

    /* Stats */
    .stats-grid{display:grid;grid-template-columns:repeat(2,1fr);gap:.65rem;margin-bottom:1rem}
    @media(min-width:480px){.stats-grid{grid-template-columns:repeat(4,1fr)}}
    .stat-card{background:var(--card);border-radius:var(--radius);padding:.875rem;border:1px solid var(--border);box-shadow:var(--shadow);transition:transform .2s}
    .stat-card:hover{transform:translateY(-2px)}
    .stat-icon{width:36px;height:36px;border-radius:9px;display:flex;align-items:center;justify-content:center;font-size:.95rem;margin-bottom:.5rem}
    .si-blue{background:var(--accent-light);color:var(--accent)}.si-green{background:var(--success-bg);color:var(--success)}
    .si-amber{background:var(--warning-bg);color:var(--warning)}.si-red{background:var(--danger-bg);color:var(--danger)}
    .stat-num{font-size:1.3rem;font-weight:800;line-height:1;margin-bottom:2px;letter-spacing:-.5px}
    .stat-lbl{font-size:.68rem;font-weight:600;color:var(--text-muted)}

    /* Alert Banner */
    .alert-banner{background:linear-gradient(135deg,var(--primary),#4f46e5);border-radius:var(--radius);padding:.875rem 1.1rem;margin-bottom:1rem;display:flex;align-items:center;gap:.75rem;box-shadow:0 4px 16px rgba(99,102,241,.25)}
    .alert-banner-icon{width:40px;height:40px;border-radius:50%;background:rgba(255,255,255,.15);display:flex;align-items:center;justify-content:center;font-size:1.1rem;color:#fff;flex-shrink:0}
    .alert-banner-text{flex:1}
    .alert-banner-title{font-size:.85rem;font-weight:700;color:#fff;margin-bottom:2px}
    .alert-banner-sub{font-size:.72rem;color:rgba(255,255,255,.7)}
    .btn-notify-all{padding:.4rem .875rem;background:rgba(255,255,255,.18);border:1px solid rgba(255,255,255,.3);border-radius:var(--radius-sm);color:#fff;font-size:.75rem;font-weight:700;cursor:pointer;flex-shrink:0;transition:all .2s;text-decoration:none}
    .btn-notify-all:hover{background:rgba(255,255,255,.28)}

    /* Toolbar */
    .toolbar{background:var(--card);border-radius:var(--radius);padding:.75rem 1rem;margin-bottom:1rem;border:1px solid var(--border);display:flex;flex-wrap:wrap;gap:.5rem;align-items:center;box-shadow:var(--shadow)}
    .search-wrap{flex:1;min-width:160px;position:relative}
    .search-wrap i{position:absolute;left:.75rem;top:50%;transform:translateY(-50%);color:var(--text-muted);font-size:.875rem}
    .search-wrap input{width:100%;padding:.55rem .75rem .55rem 2.2rem;border:1px solid var(--border);border-radius:var(--radius-sm);font-family:inherit;font-size:.82rem;color:var(--text);background:var(--bg-off);outline:none;transition:border-color .2s}
    .search-wrap input:focus{border-color:var(--accent);background:var(--card);box-shadow:0 0 0 3px rgba(99,102,241,.15)}
    .filter-sel{padding:.5rem .75rem;border:1px solid var(--border);border-radius:var(--radius-sm);font-family:inherit;font-size:.8rem;color:var(--text-mid);background:var(--card);outline:none;cursor:pointer;transition:border-color .2s}
    .filter-sel:focus{border-color:var(--accent)}
    .result-count{font-size:.75rem;color:var(--text-muted);margin-left:auto;white-space:nowrap}

    /* Table Card */
    .table-card{background:var(--card);border-radius:var(--radius);border:1px solid var(--border);box-shadow:var(--shadow);overflow:hidden;margin-bottom:1rem}
    .table-card-header{background:linear-gradient(135deg,var(--primary) 0%,var(--primary-mid) 100%);padding:.875rem 1.25rem;display:flex;align-items:center;justify-content:space-between}
    .table-card-title{font-size:.88rem;font-weight:700;color:#fff;display:flex;align-items:center;gap:.5rem}
    .table-card-title i{color:#fbbf24}
    .table-card-timestamp{font-size:.72rem;color:rgba(255,255,255)}
    .table-scroll{overflow-x:auto;-webkit-overflow-scrolling:touch}
    table{width:100%;border-collapse:collapse;font-family:'Outfit',sans-serif;min-width:700px}
    thead tr{background:rgba(99,102,241,.04);border-bottom:2px solid var(--border)}
    thead th{padding:.65rem 1rem;font-size:.68rem;font-weight:700;letter-spacing:1.2px;text-transform:uppercase;color:var(--text-muted);text-align:left;white-space:nowrap}
    thead th:last-child{text-align:center}
    tbody tr{border-bottom:1px solid var(--border);transition:background .15s}
    tbody tr:last-child{border-bottom:none}
    tbody tr:hover{background:var(--accent-light)}
    tbody tr.row-low{background:#fffbeb}
    tbody tr.row-low:hover{background:#fef3c7}
    tbody tr.row-out{background:#fef2f2}
    tbody tr.row-out:hover{background:#fecaca}
    td{padding:.65rem 1rem;font-size:.85rem;color:var(--text);vertical-align:middle}
    td:last-child{text-align:center}

    .product-img{width:48px;height:48px;object-fit:cover;border-radius:var(--radius-sm);border:1px solid var(--border);background:var(--bg-off)}
    .product-name{font-weight:700;color:var(--text);display:block;font-size:.85rem}
    .product-id{font-size:.72rem;color:var(--text-muted)}

    /* Stock bar */
    .stock-bar-wrap{display:flex;align-items:center;gap:.5rem}
    .stock-bar-bg{flex:1;height:6px;background:var(--border);border-radius:3px;overflow:hidden;min-width:60px}
    .stock-bar-fill{height:100%;border-radius:3px;transition:width .4s ease}
    .bar-green{background:var(--success)}.bar-amber{background:var(--warning)}.bar-red{background:var(--danger)}
    .stock-num{font-size:.82rem;font-weight:700;white-space:nowrap}

    /* Status badges */
    .badge-custom{font-size:.65rem;letter-spacing:.8px;text-transform:uppercase;padding:.2rem .6rem;border-radius:20px;font-weight:700;display:inline-flex;align-items:center;gap:.3rem}
    .badge-in-stock{background:var(--success-bg);color:#065f46}
    .badge-low-stock{background:var(--warning-bg);color:#92400e}
    .badge-out-stock{background:var(--danger-bg);color:#991b1b}

    /* Notify button */
    .btn-notify{font-size:.72rem;letter-spacing:.5px;text-transform:uppercase;padding:.35rem .8rem;border-radius:var(--radius-sm);border:1.5px solid var(--warning);color:var(--warning);background:transparent;cursor:pointer;transition:all .2s;display:inline-flex;align-items:center;gap:.3rem;font-family:inherit;position:relative}
    .btn-notify:hover{background:var(--warning);color:#fff}
    .btn-notify:disabled{opacity:.5;cursor:not-allowed}
    .btn-notify .tt{bottom:-36px;font-size:.68rem}
    .btn-notify:hover .tt{opacity:1}
    .sufficient-tag{font-size:.75rem;color:var(--success);display:flex;align-items:center;gap:.3rem;justify-content:center}

    /* Alert message */
    .msg-banner{background:var(--accent-light);border:1px solid var(--accent);border-radius:var(--radius);padding:.75rem 1rem;margin-bottom:1rem;font-size:.85rem;color:var(--accent);display:flex;align-items:center;gap:.5rem}

    /* Empty state */
    .empty-state{text-align:center;padding:4rem 2rem;color:var(--text-muted)}
    .empty-state i{font-size:2.5rem;display:block;margin-bottom:.75rem;opacity:.3}

    /* Toast */
    .toast-wrap{position:fixed;bottom:80px;right:1rem;z-index:2000}
    @media(min-width:768px){.toast-wrap{bottom:1.5rem}}
    .toast-msg{background:linear-gradient(135deg,var(--primary),var(--primary-mid));color:#fff;padding:.75rem 1.1rem;border-radius:var(--radius);font-size:.82rem;font-weight:500;display:flex;align-items:center;gap:.5rem;box-shadow:var(--shadow-md);min-width:240px;border-left:4px solid #fbbf24;transform:translateX(calc(100% + 1.5rem));transition:transform .3s;margin-bottom:.5rem}
    .toast-msg.show{transform:translateX(0)}

    /* Footer */
    .site-footer{background:var(--primary);color:rgba(255,255,255,.5);font-size:.78rem;text-align:center;padding:.875rem;border-top:2px solid rgba(251,191,36,.3);margin-top:1rem}

    /* Bottom Nav */
    .bottom-nav{position:fixed;bottom:0;left:0;right:0;z-index:980;background:#fff;border-top:1px solid var(--border);display:flex;justify-content:space-around;align-items:center;padding:.4rem 0 .6rem;box-shadow:0 -4px 20px rgba(67,56,202,.1)}
    @media(min-width:768px){.bottom-nav{display:none}}
    .bnav-item{flex:1;display:flex;flex-direction:column;align-items:center;gap:2px;text-decoration:none;color:var(--text-muted);font-size:.6rem;font-weight:600;transition:color .15s;position:relative}
    .bnav-item i{font-size:1.2rem}
    .bnav-item.active{color:var(--accent)}
    .bnav-item.active::before{content:'';position:absolute;top:-4px;left:50%;transform:translateX(-50%);width:24px;height:3px;background:var(--accent);border-radius:2px}

    @keyframes fadeUp{from{opacity:0;transform:translateY(14px)}to{opacity:1;transform:none}}
    .fade-up{animation:fadeUp .4s ease both}
  </style>
</head>
<body>

<!-- NAVBAR -->
<nav class="top-navbar">
  <button class="hamburger" id="toggle-btn" onclick="toggleSidebar()">
    <i class="bi bi-list"></i>
    <span class="tt">Open Menu</span>
  </button>
  <a href="UserDashboardServlet" class="nav-brand">Smart<span class="dot">Stock</span></a>
  <div class="nav-right">
    <a href="StaffNotifications" class="nav-icon-btn">
      <i class="bi bi-bell"></i><span class="notif-dot"></span>
      <span class="tt">Notifications</span>
    </a>
    <a href="UserDashboardServlet" class="nav-icon-btn">
      <i class="bi bi-house"></i>
      <span class="tt">Back to Dashboard</span>
    </a>
    <a href="profile" class="nav-avatar"><%= initials %></a>
  </div>
</nav>

<!-- Sidebar -->
<div class="sidebar-overlay" id="sidebar-overlay" onclick="toggleSidebar()"></div>
<aside class="sidebar" id="sidebar">
  <div class="sidebar-head">
    <div class="sidebar-brand">Smart<span class="dot">Stock</span></div>
    <div class="sidebar-user">
      <div class="sidebar-avatar"><%= initials %></div>
      <div><div class="sidebar-uname"><%= uname %></div><div class="sidebar-role"><%= role %></div></div>
    </div>
  </div>
  <div class="sidebar-body">
    <div class="sidebar-section">Navigation</div>
    <a href="UserDashboardServlet" class="sidebar-link"><i class="bi bi-grid-fill"></i> Dashboard</a>
    <a href="profile" class="sidebar-link"><i class="bi bi-person-circle"></i> My Profile</a>

    <div class="sidebar-section">Work</div>
    <a href="ProductServlet?action=stock" class="sidebar-link active"><i class="bi bi-box-seam"></i> Stock Management</a>
    <a href="OrdersDashboard" class="sidebar-link"><i class="bi bi-bag-check"></i> Manage Orders &amp; DeliveryAgents</a>
    <a href="ProductServlet" class="sidebar-link"><i class="bi bi-boxes"></i> Products</a>

    <div class="sidebar-section">Finance</div>
    <a href="BillsPage" class="sidebar-link"><i class="bi bi-receipt"></i> Bills &amp; Invoices</a>
    <a href="BillsPage?export=csv" class="sidebar-link"><i class="bi bi-file-earmark-arrow-down"></i> Export CSV</a>

    <div class="sidebar-section">Attendance</div>
    <a href="UserDashboardServlet#attendance-panel" class="sidebar-link"><i class="bi bi-clock-history"></i> My Attendance</a>
    <a href="LeaveServlet?action=apply" class="sidebar-link"><i class="bi bi-calendar-heart"></i> Apply Leave</a>

    <div class="sidebar-section">Support</div>
    <a href="StaffNotifications" class="sidebar-link"><i class="bi bi-bell"></i> Notifications</a>
    <a href="feedback.jsp" class="sidebar-link"><i class="bi bi-chat-dots"></i> Customer Feedback</a>
    <a href="ticketDashboard.jsp" class="sidebar-link"><i class="bi bi-ticket-perforated"></i> Customer Tickets</a>
    <a href="faq.jsp" class="sidebar-link"><i class="bi bi-question-circle"></i> Help &amp; FAQs</a>

    <div class="sidebar-section">Account</div>
    <a href="logout" class="sidebar-link danger"><i class="bi bi-box-arrow-right"></i> Logout</a>
  </div>
  <div class="sidebar-footer">© 2026 SmartStock Inventory</div>
</aside>

<!-- MAIN -->
<div class="main-content" id="main-content">

  <!-- Page Header -->
  <div class="page-header fade-up">
    <div>
      <div class="page-title"><i class="bi bi-box-seam-fill"></i>Stock Management</div>
      <div class="page-subtitle">Monitor inventory levels · identify low-stock · notify admin</div>
    </div>
    <a href="UserDashboardServlet" class="btn-back"><i class="bi bi-arrow-left"></i> Back</a>
  </div>

  <!-- Server message -->
  <% if (message != null && !message.isEmpty()) { %>
  <div class="msg-banner fade-up"><i class="bi bi-info-circle-fill"></i> <%= message %></div>
  <% } %>

  <!-- Stats -->
  <div class="stats-grid fade-up">
    <div class="stat-card">
      <div class="stat-icon si-blue"><i class="bi bi-boxes"></i></div>
      <div class="stat-num"><%= totalProducts %></div>
      <div class="stat-lbl">Total Products</div>
    </div>
    <div class="stat-card">
      <div class="stat-icon si-green"><i class="bi bi-check-circle-fill"></i></div>
      <div class="stat-num"><%= inStock %></div>
      <div class="stat-lbl">In Stock</div>
    </div>
    <div class="stat-card">
      <div class="stat-icon si-amber"><i class="bi bi-exclamation-triangle-fill"></i></div>
      <div class="stat-num"><%= lowStock %></div>
      <div class="stat-lbl">Low Stock</div>
    </div>
    <div class="stat-card">
      <div class="stat-icon si-red"><i class="bi bi-x-circle-fill"></i></div>
      <div class="stat-num"><%= outOfStock %></div>
      <div class="stat-lbl">Out of Stock</div>
    </div>
  </div>

  <!-- Alert Banner (only if low/out stock) -->
  <% if (lowStock > 0 || outOfStock > 0) { %>
  <div class="alert-banner fade-up">
    <div class="alert-banner-icon"><i class="bi bi-exclamation-triangle-fill"></i></div>
    <div class="alert-banner-text">
      <div class="alert-banner-title">⚠️ <%= outOfStock %> out of stock · <%= lowStock %> running low</div>
      <div class="alert-banner-sub">Review highlighted products below and notify admin for restocking.</div>
    </div>
    <a href="ProductServlet?action=notifyAllLow" class="btn-notify-all">
      <i class="bi bi-send"></i> Notify All
    </a>
  </div>
  <% } %>

  <!-- Toolbar -->
  <div class="toolbar fade-up">
    <div class="search-wrap">
      <i class="bi bi-search"></i>
      <input type="text" id="searchInput" placeholder="Search product name or category…">
    </div>
    <select id="statusFilter" class="filter-sel">
      <option value="all">All Status</option>
      <option value="in">In Stock</option>
      <option value="low">Low Stock</option>
      <option value="out">Out of Stock</option>
    </select>
    <select id="categoryFilter" class="filter-sel">
      <option value="all">All Categories</option>
      <option value="fruits">Fruits</option>
      <option value="vegetables">Vegetables</option>
      <option value="packed_food">Packed Food</option>
      <option value="dairy_products">Dairy</option>
      <option value="electronics">Electronics</option>
    </select>
    <span class="result-count">Showing <strong id="visibleCount"><%= totalProducts %></strong> of <strong><%= totalProducts %></strong></span>
  </div>

  <!-- Table -->
  <div class="table-card fade-up">
    <div class="table-card-header">
      <div class="table-card-title"><i class="bi bi-clipboard2-data-fill"></i> Product Inventory</div>
      <div class="table-card-timestamp"><%= nowStr %></div>
    </div>
    <div class="table-scroll">
      <table id="stockTable">
        <thead>
          <tr>
            <th style="width:44px">#</th>
            <th>Product</th>
            <th>Category</th>
            <th>Price</th>
            <th>Stock Level</th>
            <th>Status</th>
            <th>Action</th>
          </tr>
        </thead>
        <tbody>
          <%
            if (products != null && !products.isEmpty()) {
              int srNo = 1;
              for (Product p : products) {
                String rowClass  = (p.getStock() == 0) ? "row-out" : (p.getStock() < 10 ? "row-low" : "");
                String badgeCls  = (p.getStock() == 0) ? "badge-out-stock" : (p.getStock() < 10 ? "badge-low-stock" : "badge-in-stock");
                String statusTxt = (p.getStock() == 0) ? "Out of Stock" : (p.getStock() < 10 ? "Low Stock" : "In Stock");
                String barCls    = (p.getStock() == 0) ? "bar-red" : (p.getStock() < 10 ? "bar-amber" : "bar-green");
                int maxStock     = 100;
                int barPct       = Math.min((p.getStock() * 100) / maxStock, 100);
                String stockColor = (p.getStock() == 0) ? "var(--danger)" : (p.getStock() < 10 ? "var(--warning)" : "var(--success)");
                String stockIcon = (p.getStock() == 0) ? "x-circle-fill" : (p.getStock() < 10 ? "exclamation-triangle-fill" : "check-circle-fill");
          %>
          <tr class="<%= rowClass %>"
              data-name="<%= p.getName().toLowerCase() %>"
              data-category="<%= p.getCategory() != null ? p.getCategory().toLowerCase() : "" %>"
              data-status="<%= p.getStock() == 0 ? "out" : (p.getStock() < 10 ? "low" : "in") %>">
            <td style="color:var(--text-muted);font-size:.78rem;font-weight:600"><%= srNo++ %></td>
            <td>
              <div style="display:flex;align-items:center;gap:.75rem">
                <img src="<%= p.getImageUrl() != null ? p.getImageUrl() : "images/default.png" %>"
                     onerror="this.src='images/default.png'"
                     class="product-img" alt="<%= p.getName() %>">
                <div>
                  <span class="product-name"><%= p.getName() %></span>
                  <span class="product-id">ID #<%= p.getId() %></span>
                </div>
              </div>
            </td>
            <td>
              <span style="background:var(--bg-off);border:1px solid var(--border);padding:2px 10px;border-radius:20px;font-size:.73rem;font-weight:600;color:var(--text-mid)">
                <%= p.getCategory() != null ? p.getCategory().replace("_"," ") : "—" %>
              </span>
            </td>
            <td style="font-weight:700;color:var(--success)">₹<%= p.getFinalPrice() %></td>
            <td>
              <div class="stock-bar-wrap">
                <div class="stock-bar-bg">
                  <div class="stock-bar-fill <%= barCls %>" style="width:<%= barPct %>%"></div>
                </div>
                <span class="stock-num" style="color:<%= stockColor %>"><%= p.getStock() %></span>
              </div>
            </td>
            <td>
              <span class="badge-custom <%= badgeCls %>">
                <i class="bi bi-<%= stockIcon %>"></i> <%= statusTxt %>
              </span>
            </td>
            <td>
              <% if (p.getStock() < 10) { %>
                <form action="ProductServlet?action=notifyAdmin" method="post" style="display:inline" class="notify-form">
                  <input type="hidden" name="id" value="<%= p.getId() %>">
                  <input type="hidden" name="name" value="<%= p.getName() %>">
                  <input type="hidden" name="stock" value="<%= p.getStock() %>">
                  <button type="submit" class="btn-notify">
                    <i class="bi bi-bell-fill"></i> Notify Admin
                    <span class="tt">Send restock alert to admin</span>
                  </button>
                </form>
              <% } else { %>
                <span class="sufficient-tag">
                  <i class="bi bi-check-circle-fill"></i> Sufficient
                </span>
              <% } %>
            </td>
          </tr>
          <%
              }
            } else {
          %>
          <tr>
            <td colspan="7">
              <div class="empty-state">
                <i class="bi bi-inbox"></i>
                <p style="font-size:.95rem;font-weight:600;color:var(--text-mid)">No products in inventory.</p>
                <p style="font-size:.8rem">Products will appear here once added by admin.</p>
              </div>
            </td>
          </tr>
          <% } %>
        </tbody>
      </table>
    </div>
  </div>

  <!-- Footer -->
  <footer class="site-footer">
    &copy; 2026 <strong style="color:var(--accent)">SmartStock</strong> &nbsp;|&nbsp; Staff Portal
  </footer>
</div>

<!-- Bottom Nav -->
<nav class="bottom-nav">
  <a href="UserDashboardServlet" class="bnav-item"><i class="bi bi-grid-fill"></i>Home</a>
  <a href="OrdersDashboard" class="bnav-item"><i class="bi bi-bag-check"></i>Orders</a>
  <a href="ProductServlet?action=stock" class="bnav-item active"><i class="bi bi-box-seam"></i>Stock</a>
  <a href="StaffNotifications" class="bnav-item"><i class="bi bi-bell"></i>Alerts</a>
  <a href="profile" class="bnav-item"><i class="bi bi-person-circle"></i>Profile</a>
</nav>

<!-- Toast Container -->
<div class="toast-wrap" id="toastWrap"></div>

<!-- Low Stock Warning Modal (auto-shown) -->
<% if (lowStock > 0 || outOfStock > 0) { %>
<div id="stockAlertModal" style="position:fixed;inset:0;z-index:2000;display:flex;align-items:center;justify-content:center;background:rgba(0,0,0,.45);backdrop-filter:blur(3px)">
  <div style="background:#fff;border-radius:var(--radius);padding:1.5rem;max-width:380px;width:90%;box-shadow:var(--shadow-md)">
    <div style="display:flex;align-items:center;gap:.75rem;margin-bottom:1rem">
      <div style="width:44px;height:44px;border-radius:50%;background:var(--warning-bg);display:flex;align-items:center;justify-content:center;font-size:1.2rem;color:var(--warning);flex-shrink:0"><i class="bi bi-exclamation-triangle-fill"></i></div>
      <div>
        <div style="font-size:1rem;font-weight:800;color:var(--text)">Stock Alert</div>
        <div style="font-size:.75rem;color:var(--text-muted)">Immediate attention required</div>
      </div>
    </div>
    <div style="background:var(--bg-off);border-radius:var(--radius-sm);padding:.875rem;margin-bottom:1rem">
      <div style="display:flex;justify-content:space-between;padding:.4rem 0;border-bottom:1px solid var(--border);font-size:.85rem">
        <span style="color:var(--text-muted);font-weight:500">Low Stock Items</span>
        <span style="font-weight:700;color:var(--warning)"><%= lowStock %> product(s)</span>
      </div>
      <div style="display:flex;justify-content:space-between;padding:.4rem 0;font-size:.85rem">
        <span style="color:var(--text-muted);font-weight:500">Out of Stock</span>
        <span style="font-weight:700;color:var(--danger)"><%= outOfStock %> product(s)</span>
      </div>
    </div>
    <p style="font-size:.8rem;color:var(--text-muted);margin-bottom:1rem">Please review highlighted rows and notify admin for restocking.</p>
    <div style="display:flex;gap:.5rem">
      <button onclick="document.getElementById('stockAlertModal').remove()" style="flex:1;padding:.6rem;border:1px solid var(--border);border-radius:var(--radius-sm);background:var(--card);color:var(--text-mid);font-size:.82rem;font-weight:600;cursor:pointer;font-family:inherit">Dismiss</button>
      <a href="ProductServlet?action=notifyAllLow" style="flex:1;padding:.6rem;border:none;border-radius:var(--radius-sm);background:var(--warning);color:#fff;font-size:.82rem;font-weight:700;cursor:pointer;font-family:inherit;text-decoration:none;display:flex;align-items:center;justify-content:center;gap:.35rem">
        <i class="bi bi-send"></i> Notify Admin
      </a>
    </div>
  </div>
</div>
<% } %>

<script>
function toggleSidebar(){
  var s=document.getElementById('sidebar');
  var o=document.getElementById('sidebar-overlay');
  var m=document.getElementById('main-content');
  if(window.innerWidth>=768){
    // Desktop: collapse/expand
    s.classList.toggle('collapsed');
    m.classList.toggle('sidebar-collapsed');
  } else {
    // Mobile: overlay drawer
    s.classList.toggle('open');
    o.classList.toggle('open');
  }
}
// Restore sidebar state
window.addEventListener('DOMContentLoaded',function(){
  var state=localStorage.getItem('sidebar-state');
  if(state==='collapsed' && window.innerWidth>=768){
    document.getElementById('sidebar').classList.add('collapsed');
    document.getElementById('main-content').classList.add('sidebar-collapsed');
  }
});
document.getElementById('toggle-btn').addEventListener('click',function(){
  var isCollapsed=document.getElementById('sidebar').classList.contains('collapsed');
  localStorage.setItem('sidebar-state',isCollapsed?'open':'collapsed');
});

// Search + Filter
function filterTable(){
  const q=document.getElementById('searchInput').value.toLowerCase();
  const st=document.getElementById('statusFilter').value;
  const cat=document.getElementById('categoryFilter').value;
  const rows=document.querySelectorAll('#stockTable tbody tr[data-name]');
  let visible=0;
  rows.forEach(function(row){
    const name=row.dataset.name||'';
    const c=row.dataset.category||'';
    const s=row.dataset.status||'';
    const ms=!q||(name.includes(q)||c.includes(q));
    const mst=st==='all'||s===st;
    const mcat=cat==='all'||c.includes(cat);
    if(ms&&mst&&mcat){row.style.display='';visible++;}else{row.style.display='none';}
  });
  const vc=document.getElementById('visibleCount');
  if(vc) vc.textContent=visible;
}
document.getElementById('searchInput').addEventListener('input',filterTable);
document.getElementById('statusFilter').addEventListener('change',filterTable);
document.getElementById('categoryFilter').addEventListener('change',filterTable);

// Notify Admin button feedback
function showToast(msg,type){
  const wrap=document.getElementById('toastWrap');
  const colors={success:'var(--success)',danger:'var(--danger)',warning:'var(--warning)'};
  const icons={success:'bi-check-circle-fill',danger:'bi-x-circle-fill',warning:'bi-exclamation-triangle-fill'};
  const el=document.createElement('div');
  el.className='toast-msg';
  el.style.borderLeftColor=colors[type]||colors.success;
  el.innerHTML='<i class="bi '+icons[type]+'" style="color:'+colors[type]+';flex-shrink:0"></i> '+msg;
  wrap.appendChild(el);
  setTimeout(()=>el.classList.add('show'),10);
  setTimeout(()=>{el.classList.remove('show');setTimeout(()=>el.remove(),300);},3500);
}
document.querySelectorAll('.notify-form').forEach(function(form){
  form.addEventListener('submit',function(e){
    const btn=form.querySelector('button');
    btn.disabled=true;
    btn.innerHTML='<i class="bi bi-hourglass-split"></i> Sending…';
    setTimeout(function(){
      showToast('Admin notified successfully!','success');
    },400);
  });
});
</script>
</body>
</html>
