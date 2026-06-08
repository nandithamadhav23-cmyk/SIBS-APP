<%@ page contentType="text/html; charset=UTF-8" %>
<%@ page import="com.util.User" %>
<%
    String role = (session != null) ? (String) session.getAttribute("role") : null;
    String uname = (session != null) ? (String) session.getAttribute("username") : null;
    String loginTime = (session != null) ? (String) session.getAttribute("loginTime") : null;
    if (role == null || !("staff".equalsIgnoreCase(role) || "admin".equalsIgnoreCase(role))) {
        request.setAttribute("error", "Access denied. Please login as staff or admin.");
        request.getRequestDispatcher("index.jsp").forward(request, response);
        return;
    }
    User user = (User) request.getAttribute("user");
    String email   = (user != null && user.getEmail()    != null) ? user.getEmail()    : "";
    String mobile  = (user != null && user.getMobileno() != null) ? user.getMobileno() : "";
    String address = (user != null && user.getAddress()  != null) ? user.getAddress()  : "";
    String status  = (user != null && user.getStatus()   != null) ? user.getStatus()   : "";
    String initials = (uname != null && uname.length() >= 2) ? uname.substring(0,2).toUpperCase() : (uname != null ? uname.toUpperCase() : "ST");

    String message = request.getParameter("message");
    boolean isSuccess = message != null && message.toLowerCase().contains("success");

    // Password change message
    String pwdMessage = request.getParameter("pwdMessage");
    boolean pwdSuccess = pwdMessage != null && pwdMessage.toLowerCase().contains("success");

    // Profile image path (public folder)
    String profileImageSrc;
    String profileImageFile = (user != null) ? user.getProfileImage() : null;
    if (profileImageFile != null && !profileImageFile.isEmpty()) {
        profileImageSrc = request.getContextPath() + "/images/users/" + profileImageFile;
    } else {
        profileImageSrc = request.getContextPath() + "/images/defaultAvatar.png";
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
  <title>My Profile — SmartStock</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
  <style>
    :root{
      --primary:#0f172a;--accent:#3b82f6;--accent-light:#eff6ff;
      --success:#10b981;--success-bg:#ecfdf5;--warning:#f59e0b;--warning-bg:#fffbeb;
      --danger:#ef4444;--danger-bg:#fef2f2;--purple:#8b5cf6;--purple-bg:#f5f3ff;
      --text:#0f172a;--text-mid:#475569;--text-muted:#94a3b8;
      --border:#e2e8f0;--bg:#fff;--bg-off:#f8fafc;
      --nav-h:60px;--sidebar-w:260px;--radius:12px;--radius-sm:8px;
      --shadow:0 1px 3px rgba(0,0,0,.08),0 4px 16px rgba(0,0,0,.06);
      --shadow-md:0 4px 24px rgba(0,0,0,.10);
    }
    *,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
    html{font-size:15px}
    body{font-family:'Plus Jakarta Sans',sans-serif;background:var(--bg-off);color:var(--text);padding-top:var(--nav-h);min-height:100vh;-webkit-font-smoothing:antialiased;padding-bottom:64px}
    @media(min-width:768px){body{padding-bottom:0}}

    /* NAVBAR */
    .top-navbar{position:fixed;top:0;left:0;right:0;height:var(--nav-h);z-index:1000;background:var(--primary);display:flex;align-items:center;padding:0 1rem;gap:.75rem;box-shadow:0 2px 12px rgba(0,0,0,.2)}
    .hamburger{width:40px;height:40px;border-radius:var(--radius-sm);background:rgba(255,255,255,.08);border:1px solid rgba(255,255,255,.12);color:#fff;display:flex;align-items:center;justify-content:center;cursor:pointer;font-size:1.1rem;flex-shrink:0;position:relative;transition:all .2s;background:none;border:1px solid rgba(255,255,255,.12);outline:none}
    .hamburger:hover{background:rgba(59,130,246,.25)!important;border-color:var(--accent)}
    .nav-brand{font-size:1.05rem;font-weight:800;color:#fff;text-decoration:none;display:flex;align-items:center;gap:.4rem}
    .nav-brand .dot{color:var(--accent)}
    .nav-right{margin-left:auto;display:flex;align-items:center;gap:.5rem}
    .nav-icon-btn{width:36px;height:36px;border-radius:var(--radius-sm);background:rgba(255,255,255,.08);border:1px solid rgba(255,255,255,.12);color:#fff;display:flex;align-items:center;justify-content:center;cursor:pointer;font-size:.95rem;text-decoration:none;transition:all .2s;position:relative}
    .nav-icon-btn:hover{background:rgba(59,130,246,.25);border-color:var(--accent);color:var(--accent)}
    .nav-avatar{width:32px;height:32px;border-radius:50%;background:linear-gradient(135deg,var(--accent),var(--purple));display:flex;align-items:center;justify-content:center;font-size:.72rem;font-weight:700;color:#fff;border:2px solid rgba(255,255,255,.2);flex-shrink:0;text-decoration:none}

    /* SIDEBAR */
    .sidebar-overlay{position:fixed;inset:0;background:rgba(0,0,0,.4);z-index:990;opacity:0;pointer-events:none;transition:opacity .3s;backdrop-filter:blur(2px)}
    .sidebar-overlay.open{opacity:1;pointer-events:all}
    .sidebar{position:fixed;top:0;left:0;bottom:0;width:var(--sidebar-w);background:#fff;z-index:995;transform:translateX(-100%);transition:transform .3s cubic-bezier(.4,0,.2,1);display:flex;flex-direction:column;overflow:hidden;box-shadow:4px 0 24px rgba(0,0,0,.12)}
    .sidebar.open{transform:translateX(0)}
    .sidebar-head{background:var(--primary);padding:1.2rem 1.2rem 1rem;border-bottom:2px solid var(--accent)}
    .sidebar-brand{font-size:1rem;font-weight:800;color:#fff;margin-bottom:1rem}
    .sidebar-brand .dot{color:var(--accent)}
    .sidebar-user{display:flex;align-items:center;gap:.75rem}
    .sidebar-avatar{width:44px;height:44px;border-radius:50%;background:linear-gradient(135deg,var(--accent),var(--purple));display:flex;align-items:center;justify-content:center;font-size:1rem;font-weight:700;color:#fff;flex-shrink:0;border:2px solid rgba(255,255,255,.25)}
    .sidebar-uname{font-size:.9rem;font-weight:700;color:#fff}
    .sidebar-role{font-size:.65rem;font-weight:600;letter-spacing:.8px;text-transform:uppercase;color:var(--accent);margin-top:1px}
    .sidebar-body{flex:1;overflow-y:auto;padding:.75rem .75rem 1rem}
    .sidebar-section{font-size:.62rem;font-weight:700;letter-spacing:1.5px;text-transform:uppercase;color:var(--text-muted);padding:.8rem .6rem .3rem}
    .sidebar-link{display:flex;align-items:center;gap:.7rem;padding:.6rem .75rem;border-radius:var(--radius-sm);color:var(--text-mid);text-decoration:none;font-size:.88rem;font-weight:500;transition:all .18s;margin-bottom:2px;border-left:3px solid transparent}
    .sidebar-link i{font-size:.95rem;width:18px;text-align:center;color:var(--text-muted)}
    .sidebar-link:hover,.sidebar-link.active{background:var(--accent-light);color:var(--accent);border-left-color:var(--accent)}
    .sidebar-link:hover i,.sidebar-link.active i{color:var(--accent)}
    .sidebar-link.active{font-weight:700}
    .sidebar-link.danger{color:#ef4444}.sidebar-link.danger i{color:#ef4444}
    .sidebar-link.danger:hover{background:var(--danger-bg);border-left-color:#ef4444}
    .sidebar-footer{padding:.75rem;border-top:1px solid var(--border);font-size:.72rem;color:var(--text-muted);text-align:center}
    @media(min-width:768px){
      .sidebar{transform:translateX(0);box-shadow:none;border-right:1px solid var(--border)}
      .sidebar-overlay{display:none}
      .main-content{margin-left:var(--sidebar-w);padding:1.5rem 2rem}
      .hamburger{display:none}
    }

    /* MAIN */
    .main-content{padding:1rem;max-width:100%}

    /* Profile Hero */
    .profile-hero{background:linear-gradient(135deg,var(--primary) 0%,#1e3a5f 100%);border-radius:var(--radius);padding:1.5rem 1.25rem;margin-bottom:1rem;text-align:center;position:relative;overflow:hidden}
    .profile-hero::before{content:'';position:absolute;top:-30px;right:-30px;width:100px;height:100px;border-radius:50%;background:rgba(59,130,246,.15)}
    .profile-hero::after{content:'';position:absolute;bottom:-20px;left:10px;width:70px;height:70px;border-radius:50%;background:rgba(139,92,246,.12)}
    .profile-pic-wrap{position:relative;display:inline-block;margin-bottom:.875rem}
    .profile-pic{width:90px;height:90px;object-fit:cover;border-radius:50%;border:3px solid rgba(255,255,255,.3);background:var(--bg-off);display:block}
    .profile-name{font-size:1.2rem;font-weight:800;color:#fff;margin-bottom:.3rem}
    .role-badge{display:inline-flex;align-items:center;gap:.35rem;background:rgba(59,130,246,.2);border:1px solid rgba(59,130,246,.4);color:#93c5fd;font-size:.7rem;font-weight:700;padding:3px 10px;border-radius:20px;letter-spacing:.5px;text-transform:uppercase;margin-bottom:.5rem}
    .status-online{display:inline-flex;align-items:center;gap:.3rem;background:rgba(16,185,129,.2);border:1px solid rgba(16,185,129,.35);color:#6ee7b7;font-size:.65rem;font-weight:700;padding:2px 8px;border-radius:20px;margin-top:.5rem}
    .pulse-dot{width:6px;height:6px;border-radius:50%;background:#6ee7b7;animation:pulse 1.5s infinite}
    @keyframes pulse{0%,100%{opacity:1}50%{opacity:.4}}
    .pic-actions{display:flex;justify-content:center;gap:.5rem;margin-top:1rem;flex-wrap:wrap}
    .btn-pic{font-size:.72rem;font-weight:600;padding:.35rem .875rem;border-radius:var(--radius-sm);cursor:pointer;transition:all .2s;border:1px solid rgba(255,255,255,.25);color:rgba(255,255,255,.85);background:rgba(255,255,255,.1);font-family:inherit}
    .btn-pic:hover{background:rgba(255,255,255,.2);border-color:rgba(255,255,255,.4)}
    .btn-pic-danger{border-color:rgba(239,68,68,.5);color:rgba(239,68,68,.9)}
    .btn-pic-danger:hover{background:rgba(239,68,68,.15);border-color:var(--danger);color:#fff}

    /* Alert Messages */
    .msg-alert{border-radius:var(--radius);padding:.75rem 1rem;margin-bottom:1rem;font-size:.85rem;display:flex;align-items:center;gap:.5rem}
    .msg-success{background:var(--success-bg);border:1px solid var(--success);color:#065f46}
    .msg-danger{background:var(--danger-bg);border:1px solid var(--danger);color:#991b1b}

    /* Info Card */
    .info-card{background:#fff;border-radius:var(--radius);border:1px solid var(--border);box-shadow:var(--shadow);overflow:hidden;margin-bottom:1rem}
    .info-card-head{padding:.875rem 1.1rem;border-bottom:1px solid var(--border);display:flex;align-items:center;justify-content:space-between}
    .info-card-title{font-size:.9rem;font-weight:700;color:var(--text);display:flex;align-items:center;gap:.4rem}
    .info-card-title i{color:var(--accent)}
    .btn-edit-toggle{padding:.35rem .75rem;border-radius:var(--radius-sm);border:1px solid var(--border);background:#fff;color:var(--text-mid);font-size:.75rem;font-weight:600;cursor:pointer;display:flex;align-items:center;gap:.3rem;transition:all .18s;font-family:inherit}
    .btn-edit-toggle:hover{border-color:var(--accent);color:var(--accent);background:var(--accent-light)}
    .info-card-body{padding:.75rem 1.1rem}
    .info-row{display:flex;align-items:flex-start;padding:.6rem 0;border-bottom:1px solid var(--border)}
    .info-row:last-child{border-bottom:none}
    .info-icon{width:34px;height:34px;border-radius:50%;background:var(--accent-light);display:flex;align-items:center;justify-content:center;font-size:.88rem;color:var(--accent);flex-shrink:0;margin-right:.875rem}
    .info-label{font-size:.7rem;letter-spacing:.8px;text-transform:uppercase;color:var(--text-muted);margin-bottom:2px;font-weight:600}
    .info-value{font-size:.9rem;color:var(--text);font-weight:600}
    .info-value.not-set{color:var(--text-muted);font-style:italic;font-weight:400}
    .status-active{color:var(--success);display:flex;align-items:center;gap:.3rem}
    .status-inactive{color:var(--danger);display:flex;align-items:center;gap:.3rem}

    /* Form */
    .form-label{font-size:.72rem;font-weight:700;letter-spacing:.5px;text-transform:uppercase;color:var(--text-mid);margin-bottom:.3rem;display:block}
    .form-control,.form-select{width:100%;padding:.6rem .875rem;border:1px solid var(--border);border-radius:var(--radius-sm);font-family:inherit;font-size:.85rem;color:var(--text);outline:none;transition:border-color .2s;background:#fff}
    .form-control:focus,.form-select:focus{border-color:var(--accent);box-shadow:0 0 0 3px rgba(59,130,246,.1)}
    .mb-3{margin-bottom:.875rem}
    .btn-save{width:100%;padding:.7rem;background:var(--accent);color:#fff;border:none;border-radius:var(--radius-sm);font-size:.88rem;font-weight:700;cursor:pointer;transition:background .2s;margin-top:.25rem;font-family:inherit}
    .btn-save:hover{background:#2563eb}

    /* Card Footer */
    .card-footer{padding:1rem 1.1rem;border-top:1px solid var(--border);background:var(--bg-off);text-align:center}
    .btn-edit-profile{display:inline-flex;align-items:center;gap:.4rem;padding:.55rem 1.5rem;border:2px solid var(--accent);border-radius:var(--radius-sm);color:var(--accent);background:transparent;font-size:.82rem;font-weight:700;cursor:pointer;transition:all .2s;font-family:inherit}
    .btn-edit-profile:hover{background:var(--accent);color:#fff}

    /* Modal */
    .modal-content{border:none;border-radius:16px;font-family:'Plus Jakarta Sans',sans-serif;box-shadow:0 12px 48px rgba(0,0,0,.15);overflow:hidden}
    .modal-header{background:var(--primary);border:none;padding:1.1rem 1.5rem;border-radius:16px 16px 0 0}
    .modal-title{font-size:.95rem;font-weight:700;color:#fff;display:flex;align-items:center;gap:.5rem}
    .modal-title i{color:var(--accent)}
    .modal-body{padding:1.5rem}
    .modal-footer{padding:1rem 1.5rem;border-top:1px solid var(--border);background:var(--bg-off)}
    .btn-modal-submit{display:inline-flex;align-items:center;gap:.4rem;padding:.55rem 1.4rem;background:var(--accent);color:#fff;border:none;border-radius:var(--radius-sm);font-size:.82rem;font-weight:700;cursor:pointer;transition:background .2s;font-family:inherit}
    .btn-modal-submit:hover{background:#2563eb}
    .btn-modal-cancel{display:inline-flex;align-items:center;gap:.4rem;padding:.55rem 1rem;background:transparent;color:var(--text-mid);border:1px solid var(--border);border-radius:var(--radius-sm);font-size:.82rem;font-weight:600;cursor:pointer;font-family:inherit}
    .btn-modal-cancel:hover{border-color:var(--primary);color:var(--primary)}

    /* Footer */
    .site-footer{background:var(--primary);color:rgba(255,255,255,.5);font-size:.78rem;text-align:center;padding:.875rem;border-top:2px solid var(--accent);margin-top:1rem}
    .site-footer a{color:var(--accent);text-decoration:none}.site-footer a:hover{text-decoration:underline}

    /* Bottom Nav */
    .bottom-nav{position:fixed;bottom:0;left:0;right:0;z-index:980;background:#fff;border-top:1px solid var(--border);display:flex;justify-content:space-around;align-items:center;padding:.4rem 0 .6rem;box-shadow:0 -4px 16px rgba(0,0,0,.08)}
    @media(min-width:768px){.bottom-nav{display:none}}
    .bnav-item{flex:1;display:flex;flex-direction:column;align-items:center;gap:2px;text-decoration:none;color:var(--text-muted);font-size:.6rem;font-weight:600;transition:color .15s;position:relative}
    .bnav-item i{font-size:1.2rem}
    .bnav-item.active{color:var(--accent)}
    .bnav-item.active::before{content:'';position:absolute;top:-4px;left:50%;transform:translateX(-50%);width:24px;height:3px;background:var(--accent);border-radius:2px}

    @keyframes fadeUp{from{opacity:0;transform:translateY(14px)}to{opacity:1;transform:none}}
    .fade-up{animation:fadeUp .4s ease both}
    .hidden{display:none!important}
  </style>
</head>
<body>

<!-- NAVBAR -->
<nav class="top-navbar">
  <button class="hamburger" onclick="toggleSidebar()"><i class="bi bi-list"></i></button>
  <a href="userDashboard" class="nav-brand">Smart<span class="dot">Stock</span></a>
  <div class="nav-right">
    <a href="StaffNotifications" class="nav-icon-btn"><i class="bi bi-bell"></i></a>
    <a href="userDashboard" class="nav-icon-btn"><i class="bi bi-house"></i></a>
    <a href="profile" class="nav-avatar"><%= initials %></a>
  </div>
</nav>

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
    <a href="userDashboard" class="sidebar-link"><i class="bi bi-grid-fill"></i> Dashboard</a>
    <a href="profile" class="sidebar-link active"><i class="bi bi-person-circle"></i> My Profile</a>
    <div class="sidebar-section">Work</div>
    <a href="ProductServlet?action=stock" class="sidebar-link"><i class="bi bi-box-seam"></i> Stock Management</a>
    <a href="OrdersDashboard" class="sidebar-link"><i class="bi bi-bag-check"></i> Manage Orders</a>
    <a href="BillsPage" class="sidebar-link"><i class="bi bi-receipt"></i> Bills &amp; Invoices</a>
    <a href="viewProducts.jsp" class="sidebar-link"><i class="bi bi-boxes"></i> Products</a>
    <div class="sidebar-section">Support</div>
    <a href="StaffNotifications" class="sidebar-link"><i class="bi bi-bell"></i> Notifications</a>
    <a href="feedback.jsp" class="sidebar-link"><i class="bi bi-chat-dots"></i> Customer Feedback</a>
    <a href="faq.jsp" class="sidebar-link"><i class="bi bi-question-circle"></i> Help &amp; FAQs</a>
    <div class="sidebar-section">Account</div>
    <a href="logout" class="sidebar-link danger"><i class="bi bi-box-arrow-right"></i> Logout</a>
  </div>
  <div class="sidebar-footer">© 2026 SmartStock Inventory</div>
</aside>

<div class="main-content" id="main-content">

  <!-- Only show navbar if staff role -->
  <% if ("staff".equalsIgnoreCase(role)) { %>

  <!-- Server alert message -->
  <% if (message != null && !message.isEmpty()) { %>
  <div class="msg-alert <%= isSuccess ? "msg-success" : "msg-danger" %> fade-up" id="msgAlert">
    <i class="bi bi-<%= isSuccess ? "check-circle-fill" : "exclamation-triangle-fill" %>"></i>
    <%= message %>
  </div>
  <% } %>

  <!-- Profile Hero -->
  <div class="profile-hero fade-up">
    <div class="profile-pic-wrap">
      <img src="<%= profileImageSrc %>"
           onerror="this.onerror=null;this.src='<%= request.getContextPath() %>/images/defaultAvatar.png'"
           class="profile-pic" alt="<%= uname %>">
    </div>
    <div class="profile-name"><%= uname %></div>
    <div class="role-badge"><i class="bi bi-person-badge-fill"></i> <%= role.substring(0,1).toUpperCase() + role.substring(1).toLowerCase() %></div>
    <% if (loginTime != null && !loginTime.isEmpty()) { %>
    <div class="status-online" style="display:flex;justify-content:center;margin:0 auto">
      <span class="pulse-dot"></span> Active · Last login <%= loginTime %>
    </div>
    <% } %>
    <div class="pic-actions">
      <button class="btn-pic" data-bs-toggle="modal" data-bs-target="#editPicModal">
        <i class="bi bi-camera me-1"></i> Change Photo
      </button>
      <% if (profileImageFile != null && !profileImageFile.isEmpty()) { %>
      <form action="profile" method="post" style="display:inline">
        <input type="hidden" name="action" value="deleteImage">
        <button type="submit" class="btn-pic btn-pic-danger"
                onclick="return confirm('Remove profile photo?')">
          <i class="bi bi-trash me-1"></i> Remove Photo
        </button>
      </form>
      <% } %>
    </div>
  </div>

  <!-- Profile Info Card -->
  <div class="info-card fade-up">
    <div class="info-card-head">
      <div class="info-card-title"><i class="bi bi-person-fill"></i> Personal Information</div>
      <button class="btn-edit-toggle" onclick="toggleEdit()">
        <i class="bi bi-pencil"></i> <span id="editBtnText">Edit</span>
      </button>
    </div>

    <!-- View Mode -->
    <div class="info-card-body" id="view-mode">
      <div class="info-row">
        <div class="info-icon"><i class="bi bi-person"></i></div>
        <div>
          <div class="info-label">Username</div>
          <div class="info-value"><%= uname %></div>
        </div>
      </div>
      <div class="info-row">
        <div class="info-icon"><i class="bi bi-envelope"></i></div>
        <div>
          <div class="info-label">Email Address</div>
          <div class="info-value <%= email.isEmpty() ? "not-set" : "" %>">
            <%= email.isEmpty() ? "Not configured" : email %>
          </div>
        </div>
      </div>
      <div class="info-row">
        <div class="info-icon"><i class="bi bi-telephone"></i></div>
        <div>
          <div class="info-label">Mobile Number</div>
          <div class="info-value <%= mobile.isEmpty() ? "not-set" : "" %>">
            <%= mobile.isEmpty() ? "Not configured" : mobile %>
          </div>
        </div>
      </div>
      <div class="info-row">
        <div class="info-icon"><i class="bi bi-geo-alt"></i></div>
        <div>
          <div class="info-label">Address</div>
          <div class="info-value <%= address.isEmpty() ? "not-set" : "" %>">
            <%= address.isEmpty() ? "Not configured" : address %>
          </div>
        </div>
      </div>
      <div class="info-row">
        <div class="info-icon"><i class="bi bi-circle-fill" style="font-size:.7rem"></i></div>
        <div>
          <div class="info-label">Account Status</div>
          <div class="info-value">
            <% if (!status.isEmpty()) { %>
              <span class="<%= "active".equalsIgnoreCase(status) ? "status-active" : "status-inactive" %>">
                <i class="bi bi-<%= "active".equalsIgnoreCase(status) ? "check-circle-fill" : "x-circle-fill" %>"></i>
                <%= status.substring(0,1).toUpperCase() + status.substring(1).toLowerCase() %>
              </span>
            <% } else { %><span class="not-set">Not configured</span><% } %>
          </div>
        </div>
      </div>
    </div>

    <!-- Edit Mode (inline) -->
    <div class="info-card-body hidden" id="edit-mode">
      <form action="profile" method="post">
        <input type="hidden" name="username" value="<%= uname %>">
        <div class="mb-3">
          <label class="form-label">Email Address</label>
          <input type="email" name="email" value="<%= email %>" class="form-control" placeholder="your@email.com">
        </div>
        <div class="mb-3">
          <label class="form-label">Mobile Number</label>
          <input type="text" name="mobile" value="<%= mobile %>" class="form-control" placeholder="10-digit mobile">
        </div>
        <div class="mb-3">
          <label class="form-label">Address</label>
          <input type="text" name="address" value="<%= address %>" class="form-control" placeholder="Full address">
        </div>
        <div class="mb-3">
          <label class="form-label">Account Status</label>
          <select name="status" class="form-select">
            <option value="active" <%= "active".equalsIgnoreCase(status) ? "selected" : "" %>>Active</option>
            <option value="inactive" <%= "inactive".equalsIgnoreCase(status) ? "selected" : "" %>>Inactive</option>
          </select>
        </div>
        <button type="submit" class="btn-save"><i class="bi bi-check-circle me-1"></i> Save Changes</button>
      </form>
    </div>
  </div>

  <!-- Quick Action Card -->
  <div class="info-card fade-up">
    <div class="info-card-head">
      <div class="info-card-title"><i class="bi bi-lightning-fill"></i> Quick Actions</div>
    </div>
    <div style="display:grid;grid-template-columns:repeat(2,1fr);gap:.75rem;padding:.875rem 1.1rem">
      <a href="userDashboard" style="display:flex;align-items:center;gap:.5rem;padding:.65rem .875rem;border-radius:var(--radius-sm);border:1px solid var(--border);color:var(--text-mid);text-decoration:none;font-size:.82rem;font-weight:600;transition:all .18s">
        <i class="bi bi-grid-fill" style="color:var(--accent)"></i> Dashboard
      </a>
      <a href="ProductServlet?action=stock" style="display:flex;align-items:center;gap:.5rem;padding:.65rem .875rem;border-radius:var(--radius-sm);border:1px solid var(--border);color:var(--text-mid);text-decoration:none;font-size:.82rem;font-weight:600;transition:all .18s">
        <i class="bi bi-box-seam" style="color:var(--success)"></i> Stock
      </a>
      <a href="OrdersDashboard" style="display:flex;align-items:center;gap:.5rem;padding:.65rem .875rem;border-radius:var(--radius-sm);border:1px solid var(--border);color:var(--text-mid);text-decoration:none;font-size:.82rem;font-weight:600;transition:all .18s">
        <i class="bi bi-bag-check" style="color:var(--purple)"></i> Orders
      </a>
      <a href="logout" style="display:flex;align-items:center;gap:.5rem;padding:.65rem .875rem;border-radius:var(--radius-sm);border:1px solid var(--danger-bg);color:var(--danger);text-decoration:none;font-size:.82rem;font-weight:600;transition:all .18s;background:var(--danger-bg)">
        <i class="bi bi-box-arrow-right"></i> Logout
      </a>
    </div>
  </div>

  <!-- Change Password Card -->
  <div class="info-card fade-up">
    <div class="info-card-head">
      <div class="info-card-title"><i class="bi bi-shield-lock-fill"></i> Change Password</div>
    </div>
    <div class="info-card-body">
      <% if (pwdMessage != null && !pwdMessage.isEmpty()) { %>
      <div class="msg-alert <%= pwdSuccess ? "msg-success" : "msg-danger" %>" id="pwdAlert">
        <i class="bi bi-<%= pwdSuccess ? "check-circle-fill" : "exclamation-triangle-fill" %>"></i>
        <%= pwdMessage %>
      </div>
      <% } %>
      <form action="profile" method="post">
        <input type="hidden" name="action" value="changePassword">
        <div class="mb-3">
          <label class="form-label">Current Password</label>
          <input type="password" name="currentPassword" class="form-control" placeholder="Enter current password" required>
        </div>
        <div class="mb-3">
          <label class="form-label">New Password</label>
          <input type="password" name="newPassword" id="newPwd" class="form-control" placeholder="Minimum 8 characters" required minlength="8">
        </div>
        <div class="mb-3">
          <label class="form-label">Confirm New Password</label>
          <input type="password" name="confirmPassword" id="confirmPwd" class="form-control" placeholder="Re-enter new password" required minlength="8">
          <div id="pwdMismatch" style="display:none;font-size:.75rem;color:var(--danger);margin-top:.25rem">
            <i class="bi bi-exclamation-circle"></i> Passwords do not match
          </div>
        </div>
        <button type="submit" class="btn-save" id="pwdSubmitBtn">
          <i class="bi bi-shield-check me-1"></i> Update Password
        </button>
      </form>
    </div>
  </div>

  <% } %><!-- end staff check -->

  <!-- Footer -->
  <footer class="site-footer">
    &copy; 2026 <strong style="color:var(--accent)">SmartStock</strong> &nbsp;|&nbsp;
    <a href="faq.jsp">FAQs</a> &nbsp;·&nbsp; <a href="feedback.jsp">Feedback</a>
  </footer>
</div>

<!-- Bottom Nav -->
<nav class="bottom-nav">
  <a href="userDashboard" class="bnav-item"><i class="bi bi-grid-fill"></i>Home</a>
  <a href="OrdersDashboard" class="bnav-item"><i class="bi bi-bag-check"></i>Orders</a>
  <a href="ProductServlet?action=stock" class="bnav-item"><i class="bi bi-box-seam"></i>Stock</a>
  <a href="StaffNotifications" class="bnav-item"><i class="bi bi-bell"></i>Alerts</a>
  <a href="profile" class="bnav-item active"><i class="bi bi-person-circle"></i>Profile</a>
</nav>

<!-- Change Photo Modal -->
<div class="modal fade" id="editPicModal" tabindex="-1">
  <div class="modal-dialog modal-dialog-centered" style="max-width:420px">
    <form class="modal-content" action="profile" method="post" enctype="multipart/form-data">
      <div class="modal-header">
        <div class="modal-title"><i class="bi bi-camera-fill"></i> Change Profile Photo</div>
        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body">
        <p style="font-size:.82rem;color:var(--text-muted);margin-bottom:.875rem">Choose a clear, professional photo. Accepted formats: JPG, PNG, WEBP.</p>
        <label class="form-label">Select Image</label>
        <input type="file" name="profileImage" accept="image/*" class="form-control" required>
      </div>
      <div class="modal-footer" style="display:flex;gap:.5rem;justify-content:flex-end">
        <button type="button" class="btn-modal-cancel" data-bs-dismiss="modal"><i class="bi bi-x"></i> Cancel</button>
        <button type="submit" class="btn-modal-submit"><i class="bi bi-upload"></i> Upload Photo</button>
      </div>
    </form>
  </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
<script>
function toggleSidebar(){
  document.getElementById('sidebar').classList.toggle('open');
  document.getElementById('sidebar-overlay').classList.toggle('open');
}
function toggleEdit(){
  const vm=document.getElementById('view-mode');
  const em=document.getElementById('edit-mode');
  const btn=document.getElementById('editBtnText');
  vm.classList.toggle('hidden');
  em.classList.toggle('hidden');
  btn.textContent=em.classList.contains('hidden')?'Edit':'Cancel';
}
// Auto-hide server message
<% if (message != null && !message.isEmpty()) { %>
setTimeout(function(){
  const el=document.getElementById('msgAlert');
  if(el) el.style.display='none';
}, 6000);
<% } %>
// Auto-hide password message
<% if (pwdMessage != null && !pwdMessage.isEmpty()) { %>
setTimeout(function(){
  const el=document.getElementById('pwdAlert');
  if(el) el.style.display='none';
}, 6000);
<% } %>
// Password confirm mismatch live check
const newPwd = document.getElementById('newPwd');
const confirmPwd = document.getElementById('confirmPwd');
const pwdMismatch = document.getElementById('pwdMismatch');
const pwdSubmitBtn = document.getElementById('pwdSubmitBtn');
function checkPwdMatch() {
  if (confirmPwd.value && newPwd.value !== confirmPwd.value) {
    pwdMismatch.style.display = 'block';
    confirmPwd.style.borderColor = 'var(--danger)';
    if (pwdSubmitBtn) pwdSubmitBtn.disabled = true;
  } else {
    pwdMismatch.style.display = 'none';
    confirmPwd.style.borderColor = '';
    if (pwdSubmitBtn) pwdSubmitBtn.disabled = false;
  }
}
if (newPwd) newPwd.addEventListener('input', checkPwdMatch);
if (confirmPwd) confirmPwd.addEventListener('input', checkPwdMatch);
</script>
</body>
</html>
