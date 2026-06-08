<%@ page contentType="text/html; charset=UTF-8" isELIgnored="true"  %>
<%@ page import="com.util.*, java.util.*, java.time.LocalDate" %>

<%
    String role = (session != null) ? (String) session.getAttribute("role") : null;
    String uname = (session != null) ? (String) session.getAttribute("username") : null;
    User user = (User) session.getAttribute("user");
    java.sql.Timestamp lastLogin = user.getLastLogin();
    String loginTime = (lastLogin != null)
            ? new java.text.SimpleDateFormat("dd-MMM-yyyy hh:mm a").format(lastLogin)
            : "Not available";
    if (role == null || !("staff".equalsIgnoreCase(role) || "admin".equalsIgnoreCase(role))) {
        request.setAttribute("error", "Access denied. Please login as staff or admin.");
        request.getRequestDispatcher("index.jsp").forward(request, response);
        return;
    }
    int unreadNotifCount = session.getAttribute("unreadNotifCount") != null
            ? (Integer)session.getAttribute("unreadNotifCount") : 0;
    List<Order> orders = (List<Order>) session.getAttribute("orders");
    List<Product> products = (List<Product>) session.getAttribute("products");
    OfficeShift userShift= (OfficeShift) session.getAttribute("userShift");
    if (userShift == null) {
        // Fallback safety baseline if attribute missing
        userShift = new com.util.OfficeShift(); 
    }

    java.time.format.DateTimeFormatter amPmFormatter = java.time.format.DateTimeFormatter.ofPattern("hh:mm a");

    java.time.LocalTime expectedLogin = userShift.getExpectedLoginTime();
    java.time.LocalTime expectedLogout = userShift.getExpectedLogoutTime();
    
    String formattedLogin = (expectedLogin != null) ? expectedLogin.format(amPmFormatter).toUpperCase() : "09:00 AM";
    String formattedLogout = (expectedLogout != null) ? expectedLogout.format(amPmFormatter).toUpperCase() : "06:00 PM";

    String formattedLateDeadline = formattedLogin; // Fallback default
    if (expectedLogin != null) {
        int graceMinutes = userShift.getLateGraceMinutes();
        java.time.LocalTime lateDeadlineTime = expectedLogin.plusMinutes(graceMinutes);
        formattedLateDeadline = lateDeadlineTime.format(amPmFormatter).toUpperCase();
    }
    if (orders == null) orders = new ArrayList<>();
    int totalOrders = orders.size();
    int totalProducts = 0, lowStock = 0, outOfStock = 0, inStock = 0;
    if (products != null) {
        totalProducts = products.size();
        for (Product p : products) {
            if (p.getStock() == 0)      outOfStock++;
            else if (p.getStock() < 10) lowStock++;
            else                         inStock++;
        }
    }
    String today = new java.text.SimpleDateFormat("dd MMM yyyy").format(new java.util.Date());
    String initials = (uname != null && uname.length() >= 2) ? uname.substring(0,2).toUpperCase() : (uname != null ? uname.toUpperCase() : "ST");
    long  leavePending   = session.getAttribute("leavePendingCount") != null
            ? (Long) session.getAttribute("leavePendingCount") : 0L;
double leaveAvailDbl = session.getAttribute("leaveTotalAvail") != null
            ? (Double) session.getAttribute("leaveTotalAvail") : 0.0;
String leaveAvail    = String.format("%.0f", leaveAvailDbl);
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
  <title>Dashboard — SmartStock</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
  <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800&family=Lora:ital,wght@0,400;0,600;1,400&display=swap" rel="stylesheet">
  <style>
    :root {
      /* Brand palette — warm indigo + coral + cream */
   --primary: #27d2c2;
  --primary-mid: #63b3f9fc;
      --primary-light:#e0e7ff;
      --accent:#6366f1;        /* indigo accent */
      --accent-light:#eef2ff;
      --accent-hover:#4f46e5;
      --coral:#f97316;         /* coral highlight */
      --coral-bg:#fff7ed;
      --success:#059669; --success-bg:#d1fae5;
      --warning:#d97706; --warning-bg:#fef3c7;
      --danger:#dc2626;  --danger-bg:#fee2e2;
      --purple:#7c3aed;  --purple-bg:#ede9fe;
      --teal:#0891b2;    --teal-bg:#cffafe;
      --text:#1e1b4b; --text-mid:#4b5563; --text-muted:#9ca3af;
      --border:#e0e7ff; --bg:#fafafa; --bg-off:#f3f4f6;
      /* Creamy card background */
      --card-bg:#ffffff;
      --nav-h:62px; --sidebar-w:264px;
      --radius:14px; --radius-sm:9px;
      --shadow:0 1px 4px rgba(67,56,202,.07),0 4px 18px rgba(67,56,202,.08);
      --shadow-md:0 6px 28px rgba(67,56,202,.14);
      --shadow-glow:0 0 0 3px rgba(99,102,241,.18);
    }
    *,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
    html{font-size:16px}
    body{font-family:'Outfit',sans-serif;background:var(--bg-off);color:var(--text);padding-top:var(--nav-h);min-height:100vh;-webkit-font-smoothing:antialiased;padding-bottom:64px;
      background-image:radial-gradient(ellipse at 80% 0%,rgba(99,102,241,.07) 0%,transparent 60%),
                        radial-gradient(ellipse at 0% 60%,rgba(249,115,22,.05) 0%,transparent 55%);
    }
    @media(min-width:768px){body{padding-bottom:0}}

    /* ── NAVBAR ── */
    .top-navbar{position:fixed;top:0;left:0;right:0;height:var(--nav-h);z-index:1000;
      background:linear-gradient(135deg,var(--primary) 0%,var(--primary-mid) 100%);
      display:flex;align-items:center;padding:0 1.1rem;gap:.75rem;
      box-shadow:0 2px 20px rgba(67,56,202,.25);
    }
    .hamburger{width:40px;height:40px;border-radius:var(--radius-sm);background:rgba(255,255,255,.1);border:1px solid rgba(255,255,255,.18);color:#fff;display:flex;align-items:center;justify-content:center;cursor:pointer;font-size:1.1rem;flex-shrink:0;position:relative;transition:all .2s;outline:none}
    .hamburger:hover{background:rgba(255,255,255,.2);border-color:rgba(255,255,255,.4);transform:scale(1.05)}
    .tt{position:absolute;bottom:-36px;left:50%;transform:translateX(-50%);background:#312e81;color:#fff;font-size:.7rem;font-weight:500;padding:4px 8px;border-radius:6px;white-space:nowrap;pointer-events:none;opacity:0;transition:opacity .2s;z-index:9999;font-family:'Outfit',sans-serif}
    .hamburger:hover .tt,.nav-icon-btn:hover .tt{opacity:1}
    .nav-icon-btn .tt{left:auto;right:0;transform:none}
    .nav-brand{font-size:1.4rem;font-weight:800;color:#fff;text-decoration:none;display:flex;align-items:center;gap:.4rem;white-space:nowrap;letter-spacing:-.3px}
    .nav-brand .dot{color:#fbbf24}
.nav-badge {
  font-size: .9rem;
  font-weight: 700;
  background: rgb(129, 231, 43);
rgb(128, 128, 255)  color: #fefffe;
  padding: 2px 7px;
  border-radius: 20px;
  letter-spacing: .9px;
  text-transform: uppercase;
  border: 1px solid rgba(251, 191, 36, 0.07);
}    .nav-right{margin-left:auto;display:flex;align-items:center;gap:.5rem}
    .nav-icon-btn{width:36px;height:36px;border-radius:var(--radius-sm);background:rgba(255,255,255,.1);border:1px solid rgba(255,255,255,.15);color:#fff;display:flex;align-items:center;justify-content:center;cursor:pointer;font-size:.95rem;text-decoration:none;transition:all .2s;position:relative}
    .nav-icon-btn:hover{background:rgba(255,255,255);border-color:rgba(255,255,255);color:#fbbf24}
    .notif-dot{position:absolute;top:-2px;right:-2px;width:8px;height:8px;background:#f97316;border-radius:50%;border:2px solid var(--primary)}
    .nav-avatar{width:34px;height:34px;border-radius:50%;background:linear-gradient(135deg,#fbbf24,#f97316);display:flex;align-items:center;justify-content:center;font-size:.72rem;font-weight:800;color:#fff;cursor:pointer;border:2px solid rgba(255,255,255,.35);flex-shrink:0;text-decoration:none;box-shadow:0 2px 8px rgba(0,0,0,.15)}
    .bell-badge{position:absolute;top:-5px;right:-5px;background:#f97316;color:#fff;font-size:.55rem;font-weight:700;min-width:16px;height:16px;border-radius:50%;display:flex;align-items:center;justify-content:center;border:2px solid var(--primary)}

    /* ── SIDEBAR ── */
    .sidebar-overlay{position:fixed;inset:0;background:rgba(55,48,163,.25);z-index:990;opacity:0;pointer-events:none;transition:opacity .3s;backdrop-filter:blur(4px)}
    .sidebar-overlay.open{opacity:1;pointer-events:all}
    .sidebar{position:fixed;top:0;left:0;bottom:0;width:var(--sidebar-w);background:#fff;z-index:995;transform:translateX(-100%);transition:transform .3s cubic-bezier(.4,0,.2,1);display:flex;flex-direction:column;overflow:hidden;
      box-shadow:6px 0 30px rgba(67,56,202,.15);
      border-right:1px solid var(--border);
    }
    .sidebar.open{transform:translateX(0)}
    .sidebar-head{background:linear-gradient(150deg,var(--primary) 0%,var(--primary-mid) 100%);padding:4.2rem 1.2rem 1.1rem;border-bottom:2px solid rgba(251,191,36,.4)}
    .sidebar-brand{font-size:1.05rem;font-weight:800;color:#fff;margin-bottom:1rem;letter-spacing:-.3px}
    .sidebar-brand .dot{color:#fbbf24}
    .sidebar-user{display:flex;align-items:center;gap:.75rem}
    .sidebar-avatar{width:44px;height:44px;border-radius:50%;background:linear-gradient(135deg,#fbbf24,#f97316);display:flex;align-items:center;justify-content:center;font-size:1rem;font-weight:800;color:#fff;flex-shrink:0;border:2px solid rgba(255,255,255,.3);box-shadow:0 2px 10px rgba(0,0,0,.2)}
    .sidebar-uname{font-size:.9rem;font-weight:700;color:#fff}
    .sidebar-role{font-size:.65rem;font-weight:600;letter-spacing:.8px;text-transform:uppercase;color:#fbbf24;margin-top:1px}
    .sidebar-body{flex:1;overflow-y:auto;padding:.75rem .75rem 1rem;background:#fff}
    .sidebar-section{font-size:.62rem;font-weight:700;letter-spacing:1.5px;text-transform:uppercase;color:var(--text-muted);padding:.8rem .6rem .3rem}
    .sidebar-link{display:flex;align-items:center;gap:.7rem;padding:.6rem .75rem;border-radius:var(--radius-sm);color:var(--text-mid);text-decoration:none;font-size:.88rem;font-weight:500;transition:all .18s;margin-bottom:2px;border-left:3px solid transparent}
    .sidebar-link i{font-size:.95rem;width:18px;text-align:center;color:var(--text-muted);transition:color .18s}
    .sidebar-link:hover{background:var(--accent-light);color:var(--accent);border-left-color:var(--accent)}
    .sidebar-link:hover i{color:var(--accent)}
    .sidebar-link.active{background:var(--accent-light);color:var(--accent);border-left-color:var(--accent);font-weight:700}
    .sidebar-link.active i{color:var(--accent)}
    .sidebar-link.danger{color:#dc2626}.sidebar-link.danger i{color:#dc2626}
    .sidebar-link.danger:hover{background:var(--danger-bg);border-left-color:#dc2626}
    .sidebar-footer{padding:.75rem;border-top:1px solid var(--border);font-size:.72rem;color:var(--text-muted);text-align:center;background:#fafafa}
    .sidebar-badge{margin-left:auto;background:var(--danger-bg);color:var(--danger);font-size:.65rem;font-weight:700;padding:1px 7px;border-radius:20px;border:1px solid rgba(220,38,38,.2)}
   @media(min-width:768px){
  .sidebar.collapsed {
    width: 0;
    overflow: hidden;
    border-right: none;
  }
  .main-content.sidebar-collapsed {
    margin-left: 0;
  }
  /* show hamburger on desktop too */
  .hamburger { display: flex; }   /* remove the display:none */
}

    /* ── MAIN ── */
    .main-content{padding:1rem;max-width:100%}

    /* Welcome Banner */
    .welcome-banner{
background: linear-gradient(135deg,#3d5ddabf 0%,#468ce59e 55%,#3aedbba3 100%);
      border-radius:var(--radius);padding:1.4rem 1.5rem;margin-bottom:1rem;position:relative;overflow:hidden;
      box-shadow:0 8px 32px rgba(67,56,202,.25);
    }
    .welcome-banner::before{content:'';position:absolute;top:-30px;right:-30px;width:160px;height:160px;border-radius:50%;background:rgba(251,191,36,.12);pointer-events:none}
    .welcome-banner::after{content:'';position:absolute;bottom:-40px;right:60px;width:100px;height:100px;border-radius:50%;background:rgba(255,255,255,.06);pointer-events:none}
    .welcome-greeting{font-size:.72rem;font-weight:600;color:rgba(255,255,255,.65);text-transform:uppercase;letter-spacing:.8px;margin-bottom:3px}
    .welcome-name{font-size:1.4rem;font-weight:800;color:#fff;margin-bottom:5px;letter-spacing:-.3px}
    .welcome-meta{font-size:.74rem;color:rgba(255,255,255,.6);display:flex;flex-wrap:wrap;gap:.3rem .75rem}
    .welcome-meta span{color:rgba(255,255,255,.9);font-weight:600}
    .online-badge{display:inline-flex;align-items:center;gap:4px;background:rgba(16,185,129,.22);border:1px solid rgba(16,185,129,.4);color:#6ee7b7;font-size:.65rem;font-weight:700;padding:3px 9px;border-radius:20px;margin-bottom:.6rem}
    .pulse-dot{width:6px;height:6px;border-radius:50%;background:#6ee7b7;animation:pulse 1.5s infinite}
    @keyframes pulse{0%,100%{opacity:1}50%{opacity:.4}}
    .admin-back-btn{display:inline-flex;align-items:center;gap:.4rem;padding:.4rem .875rem;border:1px solid rgba(255,255,255,.3);border-radius:var(--radius-sm);color:rgba(255,255,255,.9);font-size:.75rem;font-weight:600;text-decoration:none;transition:all .2s;background:rgba(255,255,255,.1);margin-top:.75rem}
    .admin-back-btn:hover{background:rgba(255,255,255,.2);border-color:#fbbf24;color:#fbbf24}
    .leave-btn{display:inline-flex;align-items:center;gap:.4rem;padding:.4rem .875rem;border-radius:var(--radius-sm);color:white;font-size:.75rem;font-weight:600;transition:all .2s;  background: rgba(80, 242, 181, 0.84);margin-top:.75rem;text-decoration:none}
    .leave-btn:hover{background:rgba(255,255,255);color:#fbbf24;}

    /* Stats */
    .stats-grid{display:grid;grid-template-columns:repeat(2,1fr);gap:.65rem;margin-bottom:1rem}
    @media(min-width:480px){.stats-grid{grid-template-columns:repeat(3,1fr)}}
    @media(min-width:768px){.stats-grid{grid-template-columns:repeat(6,1fr)}}
    .stat-card{background:var(--card-bg);border-radius:var(--radius);padding:.875rem;border:1px solid var(--border);box-shadow:var(--shadow);transition:transform .22s,box-shadow .22s;cursor:default;position:relative;overflow:hidden}
    .stat-card::after{content:'';position:absolute;inset:0;border-radius:var(--radius);background:linear-gradient(135deg,rgba(99,102,241,.03),transparent);pointer-events:none}
    .stat-card:hover{transform:translateY(-3px);box-shadow:var(--shadow-md)}
    .stat-icon{width:38px;height:38px;border-radius:10px;display:flex;align-items:center;justify-content:center;font-size:.95rem;margin-bottom:.55rem}
    .si-green{background:#d1fae5;color:#059669}.si-amber{background:#fef3c7;color:#d97706}
    .si-red{background:#fee2e2;color:#dc2626}.si-blue{background:#e0e7ff;color:var(--accent)}
    .si-purple{background:#ede9fe;color:var(--purple)}.si-teal{background:#cffafe;color:var(--teal)}
    .stat-num{font-size:1.35rem;font-weight:800;line-height:1;margin-bottom:2px;letter-spacing:-.5px}
    .stat-lbl{font-size:.68rem;font-weight:600;color:var(--text-muted)}

    /* Section Label */
    .section-label{font-size:.72rem;font-weight:700;letter-spacing:1.2px;text-transform:uppercase;color:var(--accent);margin-bottom:.75rem;display:flex;align-items:center;gap:.5rem}
    .section-label::after{content:'';flex:1;height:1px;background:linear-gradient(90deg,var(--border),transparent)}

    /* Alert Banner */
    .alert-banner{background: linear-gradient(135deg,#3d5ddabf 0%,#468ce59e 55%,#3aedbba3 100%);
border-radius:var(--radius);padding:.875rem 1.1rem;margin-bottom:1rem;display:flex;align-items:center;gap:.75rem;box-shadow:0 4px 20px rgba(99,102,241,.22)}
    .alert-banner-icon{width:40px;height:40px;border-radius:50%;background:rgba(255,255,255,.15);display:flex;align-items:center;justify-content:center;font-size:1.1rem;color:#fff;flex-shrink:0}
    .alert-banner-text{flex:1}
    .alert-banner-title{font-size:.85rem;font-weight:700;color:#fff;margin-bottom:2px}
    .alert-banner-sub{font-size:.72rem;color:rgba(255,255,255,.75)}
    .btn-alert-action{padding:.4rem .875rem;background:rgba(255,255,255,.2);border:1px solid rgba(255,255,255,.35);border-radius:var(--radius-sm);color:#fff;font-size:.75rem;font-weight:700;cursor:pointer;flex-shrink:0;transition:all .2s;text-decoration:none;white-space:nowrap}
    .btn-alert-action:hover{background:rgba(255,255,255,.32);color:#fff}

    /* Module Cards */
    .modules-grid{display:grid;grid-template-columns:repeat(2,1fr);gap:.75rem;margin-bottom:1rem}
    @media(min-width:480px){.modules-grid{grid-template-columns:repeat(3,1fr)}}
    .module-card{background:var(--card-bg);border-radius:var(--radius);padding:1.1rem 1rem;border:1px solid var(--border);box-shadow:var(--shadow);text-decoration:none;color:var(--text);transition:all .25s;display:flex;flex-direction:column;gap:.5rem;position:relative;overflow:hidden}
    .module-card::before{content:'';position:absolute;top:0;left:0;right:0;height:3px;background:var(--c,var(--accent));transform:scaleX(0);transition:transform .25s;transform-origin:left}
    .module-card:hover{transform:translateY(-4px);box-shadow:var(--shadow-md);color:var(--text);border-color:rgba(99,102,241,.2)}
    .module-card:hover::before{transform:scaleX(1)}
    .module-icon{width:40px;height:40px;border-radius:10px;display:flex;align-items:center;justify-content:center;font-size:1.1rem}
    .module-name{font-size:.82rem;font-weight:700;color:var(--text)}
    .module-desc{font-size:.72rem;color:var(--text-muted);line-height:1.45}
    .module-arrow{font-size:.8rem;color:var(--text-muted);transition:transform .2s,color .2s;align-self:flex-end;margin-top:auto}
    .module-card:hover .module-arrow{transform:translateX(5px);color:var(--accent)}

    /* Tasks Panel */
    .tasks-panel{background: linear-gradient(135deg,var(--primary)0%,var(--primary-mid) 55%,#3aedbba3 100%);
border-radius:var(--radius);overflow:hidden;margin-bottom:1rem;box-shadow:var(--shadow-md)}
    .tasks-head{padding:.9rem 1.15rem;display:flex;align-items:center;justify-content:space-between;border-bottom:1px solid rgba(255,255,255,.08)}
    .tasks-title{font-size:.88rem;font-weight:700;color:#fff;display:flex;align-items:center;gap:.5rem}
    .tasks-title i{color:#fbbf24}
    .tasks-date{font-size:.68rem;color:rgba(255,255,255);font-weight:500}
    .task-item{padding:.7rem 1.15rem;border-bottom:1px solid rgba(255,255,255,.05);display:flex;align-items:center;gap:.65rem;transition:background .15s;cursor:default}
    .task-item:last-child{border-bottom:none}
    .task-item:hover{background:rgba(255,255,255,.74)}
    .task-dot{width:8px;height:8px;border-radius:50%;flex-shrink:0}
    .dot-amber{background:#fbbf24}.dot-green{background:#34d399}.dot-blue{background:#a5b4fc}.dot-red{background:#f87171}
    .task-text{flex:1;font-size:.8rem;color:rgba(255,255,255);line-height:1.4}
    .task-badge{font-size:.63rem;font-weight:700;padding:2px 8px;border-radius:20px;white-space:nowrap;flex-shrink:0}
    .badge-pending{background:rgba(251,191,36,.18);color:#fbbf24}
    .badge-done{background:rgba(52,211,153,.18);color:#34d399}
    .badge-progress{background:rgba(165,180,252,.18);color:#a5b4fc}
    .task-time{font-size:.65rem;color:rgba(255,255,255);flex-shrink:0}

    /* Footer */
    .site-footer{background:var(--primary);color:rgba(255,255,255,.45);font-size:.78rem;text-align:center;padding:.875rem;border-top:2px solid rgba(251,191,36,.3);margin-top:1rem}
    .site-footer a{color:#fbbf24;text-decoration:none}.site-footer a:hover{text-decoration:underline}

    /* Bottom Nav */
    .bottom-nav{position:fixed;bottom:0;left:0;right:0;z-index:980;background:#fff;border-top:1px solid var(--border);display:flex;justify-content:space-around;align-items:center;padding:.4rem 0 .6rem;box-shadow:0 -4px 20px rgba(67,56,202,.1)}
    @media(min-width:768px){.bottom-nav{display:none}}
    .bnav-item{flex:1;display:flex;flex-direction:column;align-items:center;gap:2px;text-decoration:none;color:var(--text-muted);font-size:.6rem;font-weight:600;transition:color .15s;position:relative}
    .bnav-item i{font-size:1.2rem}
    .bnav-item.active{color:var(--accent)}
    .bnav-item.active::before{content:'';position:absolute;top:-4px;left:50%;transform:translateX(-50%);width:24px;height:3px;background:var(--accent);border-radius:2px}

    /* Toast */
    #toast{position:fixed;top:calc(var(--nav-h) + 12px);left:50%;transform:translateX(-50%) translateY(-8px);z-index:3000;min-width:260px;max-width:90vw;opacity:0;transition:all .3s;pointer-events:none}
    #toast-inner{background:linear-gradient(135deg,var(--primary),var(--primary-mid));color:#fff;padding:.75rem 1.1rem;border-radius:var(--radius);font-size:1.1rem;font-weight:500;display:flex;align-items:center;gap:.5rem;box-shadow:0 8px 30px rgba(67,56,202,.3);border-left:4px solid #fbbf24}
    #toast.show{opacity:1;transform:translateX(-50%) translateY(0);pointer-events:all}
    @keyframes fadeUp{from{opacity:0;transform:translateY(14px)}to{opacity:1;transform:none}}
    .fade-up{animation:fadeUp .45s ease both}

    /* ══════════════════════════════════════════
       ATTENDANCE PANEL
    ══════════════════════════════════════════ */
    .attendance-panel{background:var(--card-bg);border-radius:var(--radius);border:1px solid var(--border);box-shadow:var(--shadow);margin-bottom:1rem;overflow:hidden}

    /* Header */
    .att-header{background: linear-gradient(135deg,#3d5ddabf 0%,#468ce59e 55%,#3aedbba3 100%);
padding:1rem 1.25rem;display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:.5rem}
    .att-header-left{display:flex;align-items:center;gap:.6rem}
    .att-header-icon{width:38px;height:38px;border-radius:10px;background:rgba(251,191,36,.2);display:flex;align-items:center;justify-content:center;font-size:1.1rem;color:#fbbf24}
    .att-header-title{font-size:.95rem;font-weight:700;color:#fff}
    .att-header-sub{font-size:.7rem;color:rgba(255,255,255,.6);margin-top:1px}
    .att-live-clock{font-size:1.45rem;font-weight:800;color:#fff;font-variant-numeric:tabular-nums;letter-spacing:1.5px}
    .att-live-date{font-size:.68rem;color:rgba(255,255,255,.5);text-align:right}

    /* Office timing info row */
    .att-office-info{display:flex;align-items:center;gap:1.25rem;padding:.55rem 1.25rem;background:rgba(99,102,241,.04);border-bottom:1px solid var(--border);flex-wrap:wrap}
    .att-office-chip{display:inline-flex;align-items:center;gap:.35rem;font-size:.7rem;font-weight:600;color:var(--text-mid)}
    .att-office-chip i{font-size:.8rem;color:var(--accent)}
    .att-office-chip b{color:var(--text)}

    /* Status bar */
    .att-status-bar{display:flex;align-items:center;gap:.5rem;padding:.7rem 1.25rem;border-bottom:1px solid var(--border);background:rgba(99,102,241,.02);flex-wrap:wrap}
    .att-status-chip{display:inline-flex;align-items:center;gap:5px;padding:4px 12px;border-radius:20px;font-size:.72rem;font-weight:700;letter-spacing:.3px}
    .chip-idle   {background:#f3f4f6;color:var(--text-muted);border:1px solid var(--border)}
    .chip-working{background:rgba(5,150,105,.1);color:#059669;border:1px solid rgba(5,150,105,.25)}
    .chip-break  {background:rgba(217,119,6,.1);color:#d97706;border:1px solid rgba(217,119,6,.25)}
    .chip-done   {background:rgba(99,102,241,.1);color:var(--accent);border:1px solid rgba(99,102,241,.2)}
    .chip-dot{width:7px;height:7px;border-radius:50%}
    .chip-working .chip-dot{background:var(--success);animation:pulse 1.5s infinite}
    .chip-break   .chip-dot{background:var(--warning);animation:pulse 1.5s infinite}
    .chip-idle    .chip-dot{background:var(--text-muted)}
    .chip-done    .chip-dot{background:var(--accent)}
    .att-status-msg{font-size:.78rem;color:var(--text-muted);margin-left:auto}

    /* ── ATTENDANCE STATUS BADGE (the new feature) ── */
    .att-day-status{display:inline-flex;align-items:center;gap:.35rem;padding:4px 12px;border-radius:20px;font-size:.72rem;font-weight:700;letter-spacing:.2px;margin-left:.5rem}
    .day-full    {background:rgba(16,185,129,.12);color:#059669;border:1px solid rgba(16,185,129,.3)}
    .day-overtime{background:rgba(124,58,237,.12);color:#7c3aed;border:1px solid rgba(124,58,237,.3)}
    .day-half    {background:rgba(6,182,212,.1);color:#0891b2;border:1px solid rgba(6,182,212,.25)}
    .day-absent  {background:rgba(239,68,68,.1);color:#dc2626;border:1px solid rgba(239,68,68,.25)}
    .day-late    {background:rgba(245,158,11,.12);color:#d97706;border:1px solid rgba(245,158,11,.3)}
    .day-late-half{background:rgba(249,115,22,.1);color:#c2410c;border:1px solid rgba(249,115,22,.25)}
    .day-pending   {background:rgba(148,163,184,.1);color:var(--text-muted);border:1px solid var(--border)}
    .day-auto-close{background:rgba(239,68,68,.08);color:#b45309;border:1px dashed rgba(239,68,68,.4)}

    /* Late warning banner */
    .att-late-warn{display:none;align-items:center;gap:.6rem;padding:.6rem 1.25rem;background:rgba(245,158,11,.08);border-bottom:1px solid rgba(245,158,11,.25)}
    .att-late-warn.visible{display:flex}
    .att-late-warn i{color:var(--warning);font-size:1rem;flex-shrink:0}
    .att-late-warn span{font-size:.78rem;font-weight:600;color:#92400e}

    /* Time meters */
    .att-meters{display:grid;grid-template-columns:repeat(3,1fr);gap:0;border-bottom:1px solid var(--border)}
    .att-meter{padding:.875rem 1rem;text-align:center;border-right:1px solid var(--border)}
    .att-meter:last-child{border-right:none}
    .att-meter-icon{font-size:1.1rem;margin-bottom:.3rem}
    .att-meter-val{font-size:1.25rem;font-weight:800;line-height:1;font-variant-numeric:tabular-nums;margin-bottom:3px}
    .att-meter-lbl{font-size:.65rem;font-weight:600;color:var(--text-muted);text-transform:uppercase;letter-spacing:.5px}
    .meter-working .att-meter-icon{color:var(--success)}.meter-working .att-meter-val{color:var(--success)}
    .meter-break   .att-meter-icon{color:var(--warning)}.meter-break   .att-meter-val{color:var(--warning)}
    .meter-net     .att-meter-icon{color:var(--accent)} .meter-net     .att-meter-val{color:var(--accent)}

    /* Progress bar */
    .att-progress-wrap{padding:.75rem 1.25rem;border-bottom:1px solid var(--border)}
    .att-progress-top{display:flex;justify-content:space-between;align-items:center;margin-bottom:.4rem}
    .att-progress-label{font-size:.72rem;font-weight:600;color:var(--text-muted)}
    .att-progress-pct{font-size:.75rem;font-weight:700;color:var(--accent)}
    .att-progress-track{height:8px;background:var(--bg-off);border-radius:99px;overflow:hidden;border:1px solid var(--border)}
    .att-progress-fill{height:100%;border-radius:99px;background:linear-gradient(90deg,var(--accent),#818cf8);transition:width .5s ease;width:0%}
    .att-progress-fill.warn-fill{background:linear-gradient(90deg,var(--warning),#fb923c)}
    .att-progress-fill.success-fill{background:linear-gradient(90deg,var(--success),#34d399)}
    .att-progress-fill.danger-fill{background:linear-gradient(90deg,var(--warning),var(--danger))}

    /* Milestones bar */
    .att-milestones{display:flex;gap:.5rem;padding:.4rem 1.25rem;border-bottom:1px solid var(--border);background:rgba(99,102,241,.025);flex-wrap:wrap}
    .att-milestone{display:inline-flex;align-items:center;gap:.3rem;font-size:.68rem;font-weight:600;padding:3px 9px;border-radius:20px;border:1px solid var(--border);color:var(--text-muted);background:#fff;transition:all .3s}
    .att-milestone.reached{color:#059669;background:rgba(16,185,129,.08);border-color:rgba(16,185,129,.25)}
    .att-milestone.reached i{color:#059669}
    .att-milestone i{font-size:.7rem}

    /* Action buttons */
    .att-actions{display:grid;grid-template-columns:1fr 1fr 1fr;gap:.75rem;padding:1rem 1.25rem}
    @media(max-width:480px){.att-actions{grid-template-columns:1fr 1fr}.att-actions .btn-punch-out{grid-column:span 2}}
    .btn-att{display:flex;flex-direction:column;align-items:center;justify-content:center;gap:4px;padding:.875rem .5rem;border-radius:var(--radius-sm);font-family:inherit;font-size:.78rem;font-weight:700;cursor:pointer;border:none;transition:all .22s;line-height:1.2;position:relative;overflow:hidden;letter-spacing:.2px}
    .btn-att::after{content:'';position:absolute;inset:0;opacity:0;transition:opacity .2s;background:rgba(255,255,255,.18)}
    .btn-att:hover::after{opacity:1}
    .btn-att:hover{transform:translateY(-2px)}
    .btn-att:active{transform:scale(.97)}
    .btn-att i{font-size:1.3rem}
    .btn-att:disabled{opacity:.35;cursor:not-allowed;transform:none}
    .btn-att:disabled::after{display:none}
    .btn-punch-in {background:linear-gradient(135deg,#059669,#10b981);color:#fff;box-shadow:0 4px 16px rgba(5,150,105,.35)}
    .btn-break    {background:linear-gradient(135deg,#d97706,#f59e0b);color:#fff;box-shadow:0 4px 16px rgba(217,119,6,.3)}
    .btn-resume   {background:linear-gradient(135deg,var(--primary),var(--accent));color:#fff;box-shadow:0 4px 16px rgba(99,102,241,.3)}
    .btn-punch-out{background:linear-gradient(135deg,#dc2626,#ef4444);color:#fff;box-shadow:0 4px 16px rgba(220,38,38,.3)}
     #breakLimitWarn{
      display:none;
      align-items:center;gap:.6rem;
      margin:.75rem 1.25rem 0;
      padding:.65rem .9rem;
      background:rgba(245,158,11,.1);
      border:1px solid rgba(245,158,11,.4);
      border-radius:var(--radius-sm);
      font-size:.78rem;color:#92400e;
    }
    #breakLimitWarn.visible{display:flex}
    #breakLimitWarn i{font-size:1rem;color:#d97706;flex-shrink:0}
    /* End-of-day Summary */
    .att-summary{display:none;margin:0 1.25rem 1rem;background:linear-gradient(102deg,var(--primary),#748cecd4);border-radius:var(--radius-sm);padding:1rem;color:#fff}
    .att-summary.visible{display:block}
    .att-summary-title{font-size:.8rem;font-weight:700;color:rgba(255,255,255,.7);margin-bottom:.75rem;text-transform:uppercase;letter-spacing:.5px;display:flex;align-items:center;gap:.5rem}
    .att-summary-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:.5rem;text-align:center;margin-bottom:.75rem}
    .att-sum-val{font-size:1.1rem;font-weight:800;color:#fff}
    .att-sum-lbl{font-size:.62rem;color:rgba(255,255,255,.5);text-transform:uppercase;letter-spacing:.3px}
    .att-sum-divider{height:1px;background:rgba(255,255,255,.1);margin:.75rem 0}

    /* ── FINAL ATTENDANCE STATUS (end of day) ── */
    .att-final-status{display:flex;align-items:center;gap:.75rem;padding:.875rem;background:rgba(255,255,255,.07);border-radius:var(--radius-sm);margin-top:.5rem;border:1px solid rgba(255,255,255,.1)}
    .att-final-icon{width:40px;height:40px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:1.1rem;flex-shrink:0}
    .att-final-label{font-size:.72rem;color:rgba(255,255,255,.55);text-transform:uppercase;letter-spacing:.5px;margin-bottom:2px}
    .att-final-val{font-size:.95rem;font-weight:800;color:#fff}
    .att-final-sub{font-size:.7rem;color:rgba(255,255,255,.5);margin-top:2px}
    .icon-full    {background:rgba(16,185,129,.25);color:#6ee7b7}
    .icon-overtime{background:rgba(124,58,237,.25);color:#c4b5fd}
    .icon-half    {background:rgba(6,182,212,.2);color:#67e8f9}
    .icon-absent  {background:rgba(239,68,68,.2);color:#fca5a5}
    .icon-late    {background:rgba(245,158,11,.2);color:#fde68a}
    .icon-late-half{background:rgba(249,115,22,.2);color:#fdba74}
    .icon-pending    {background:rgba(148,163,184,.15);color:rgba(255,255,255,.5)}
    .icon-auto-close {background:rgba(239,68,68,.18);color:#fca5a5}

    /* Overtime/early badge */
    .att-overtime-badge{display:inline-flex;align-items:center;gap:4px;padding:3px 10px;border-radius:20px;font-size:.7rem;font-weight:700;background:rgba(245,158,11,.18);color:#d97706;border:1px solid rgba(245,158,11,.3);margin-top:.5rem}
    .att-overtime-badge.ot-good{background:rgba(16,185,129,.15);color:#059669;border-color:rgba(16,185,129,.3)}

    /* ══ ATTENDANCE HISTORY PANEL ══ */
    .att-history-panel{background:var(--card-bg);border-radius:var(--radius);border:1px solid var(--border);box-shadow:var(--shadow);margin-bottom:1rem;overflow:hidden}
    .att-hist-header{background: linear-gradient(135deg,#3d5ddabf 0%,#468ce59e 55%,#3aedbba3 100%);
padding:.875rem 1.25rem;display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:.5rem}
    .att-hist-title{font-size:.9rem;font-weight:700;color:#fff;display:flex;align-items:center;gap:.5rem}
    .att-hist-title i{color:#fbbf24}
    .att-hist-sub{font-size:.68rem;color:rgba(255,255,255,.55);margin-top:1px}
    .att-hist-tabs{display:flex;border-bottom:1px solid var(--border)}
    .att-hist-tab{flex:1;padding:.6rem;font-size:.75rem;font-weight:600;text-align:center;cursor:pointer;border:none;background:none;color:var(--text-muted);border-bottom:2px solid transparent;transition:all .2s;font-family:inherit}
    .att-hist-tab.active{color:var(--accent);border-bottom-color:var(--accent);background:var(--accent-light)}

    /* Summary cards row */
    .att-hist-summary{display:grid;grid-template-columns:repeat(5,1fr);border-bottom:1px solid var(--border)}
    @media(max-width:600px){.att-hist-summary{grid-template-columns:repeat(3,1fr)}}
    .att-hist-sum-card{padding:.75rem .875rem;text-align:center;border-right:1px solid var(--border)}
    .att-hist-sum-card:last-child{border-right:none}
    .att-hist-sum-val{font-size:1.35rem;font-weight:800;line-height:1;margin-bottom:3px;letter-spacing:-.5px}
    .att-hist-sum-lbl{font-size:.62rem;font-weight:600;color:var(--text-muted);text-transform:uppercase;letter-spacing:.5px}
    .hsc-full  {color:#059669} .hsc-half{color:#0891b2}
    .hsc-absent{color:#dc2626} .hsc-late{color:#d97706} .hsc-hrs{color:var(--accent)}

    /* History table */
    .att-hist-table-wrap{overflow-x:auto}
    .att-hist-table{width:100%;border-collapse:collapse;font-size:.84rem}
    .att-hist-table thead th{background:rgba(99,102,241,.04);color:var(--text-muted);font-size:.65rem;letter-spacing:1px;text-transform:uppercase;padding:.55rem .875rem;border-bottom:2px solid var(--border);font-weight:700;white-space:nowrap}
    .att-hist-table tbody tr{border-bottom:1px solid var(--border);transition:background .12s;text-align:center;}
    .att-hist-table tbody tr:hover{background:rgba(99,102,241,.03)}
    .att-hist-table tbody tr:last-child{border-bottom:none}
    .att-hist-table td{padding:.6rem .875rem;vertical-align:middle}
    .att-hist-table td.mono{font-size:.8rem;color:var(--text-mid);font-variant-numeric:tabular-nums}

    /* Day status pill for history table */
    .hist-day-pill{display:inline-flex;align-items:center;gap:4px;padding:3px 9px;border-radius:20px;font-size:.68rem;font-weight:700;white-space:nowrap}
    .hdp-full    {background:rgba(16,185,129,.1); color:#059669;border:1px solid rgba(16,185,129,.2)}
    .hdp-overtime{background:rgba(124,58,237,.1); color:#7c3aed;border:1px solid rgba(124,58,237,.2)}
    .hdp-half    {background:rgba(6,182,212,.1);  color:#0891b2;border:1px solid rgba(6,182,212,.2)}
    .hdp-absent  {background:rgba(239,68,68,.1);  color:#dc2626;border:1px solid rgba(239,68,68,.2)}
    .hdp-late    {background:rgba(245,158,11,.12);color:#d97706;border:1px solid rgba(245,158,11,.25)}
    .hdp-latehalf{background:rgba(249,115,22,.1); color:#c2410c;border:1px solid rgba(249,115,22,.22)}
    .hdp-pending {background:rgba(148,163,184,.1);color:var(--text-muted);border:1px solid var(--border)}

    /* Hours mini-bar in history */
    .hist-bar-wrap{display:flex;align-items:center;gap:.4rem}
    .hist-bar-track{width:60px;height:5px;background:var(--border);border-radius:99px;overflow:hidden}
    .hist-bar-fill{height:100%;border-radius:99px;background:linear-gradient(90deg,var(--accent),var(--success))}
    .hist-bar-lbl{font-size:.78rem;font-weight:700;color:var(--text);min-width:36px;}

    /* Calendar mini view */
    .att-hist-calendar{padding:.875rem 1.25rem}
    .att-cal-grid{display:grid;grid-template-columns:repeat(7,1fr);gap:3px;margin-top:.5rem}
    .att-cal-header{font-size:.62rem;font-weight:700;text-align:center;color:var(--text-muted);padding:3px 0}
    .att-cal-day{aspect-ratio:1;border-radius:6px;display:flex;align-items:center;justify-content:center;font-size:.68rem;font-weight:600;cursor:default;position:relative;transition:transform .15s;  border: 1px inset #86f0dc8c;}
    .att-cal-day:hover{transform:scale(1.1);z-index:1;  background: #e9e6f2f0;  border: 3px outset #5de2f0;}
    .cal-full    {background:rgba(16,185,129,.15);color:#059669;border:1px solid rgba(16,185,129,.2)}
    .cal-overtime{background:rgba(124,58,237,.15);color:#7c3aed;border:1px solid rgba(124,58,237,.2)}
    .cal-half    {background:rgba(6,182,212,.12); color:#0891b2;border:1px solid rgba(6,182,212,.2)}
    .cal-absent {background:rgba(239,68,68,.1);  color:#dc2626;border:1px solid rgba(239,68,68,.15)}
    .cal-late   {background:rgba(245,158,11,.15);color:#d97706;border:1px solid rgba(245,158,11,.2)}
    .cal-empty  {background: white;color:black}
    .cal-today  {border:1px outset green;backgournd: peach;outline-offset:1px}
    .att-cal-legend{display:flex;gap:.75rem;flex-wrap:wrap;margin-top:.5rem}
    .att-cal-leg-item{display:inline-flex;align-items:center;gap:.3rem;font-size:.68rem;color:var(--text-muted)}
    .att-cal-leg-dot{width:8px;height:8px;border-radius:3px;flex-shrink:0}

    /* Empty history state */
    .att-hist-empty{text-align:center;padding:2.5rem 1rem;color:var(--text-muted);font-size:.85rem}
    .att-hist-empty i{display:block;font-size:2rem;margin-bottom:.5rem;color:var(--border)}

    /* Timeline / Log */
    .att-log{padding:0 1.25rem 1rem}
    .att-log-title{font-size:.7rem;font-weight:700;letter-spacing:1px;text-transform:uppercase;color:var(--text-muted);margin-bottom:.75rem;padding-top:.875rem;border-top:1px solid var(--border);display:flex;align-items:center;justify-content:space-between}
    .att-timeline{list-style:none;position:relative;padding:0}
    .att-timeline::before{content:'';position:absolute;left:10px;top:4px;bottom:4px;width:2px;background:var(--border)}
    .att-tl-item{position:relative;padding:0 0 .75rem 2rem;display:flex;align-items:flex-start;gap:.5rem}
    .att-tl-item:last-child{padding-bottom:0}
    .att-tl-dot{position:absolute;left:5px;top:3px;width:12px;height:12px;border-radius:50%;border:2px solid #fff;flex-shrink:0}
    .tl-dot-in    {background:var(--success);box-shadow:0 0 0 2px rgba(16,185,129,.3)}
    .tl-dot-break {background:var(--warning);box-shadow:0 0 0 2px rgba(245,158,11,.3)}
    .tl-dot-resume{background:var(--accent); box-shadow:0 0 0 2px rgba(59,130,246,.3)}
    .tl-dot-out   {background:var(--danger); box-shadow:0 0 0 2px rgba(239,68,68,.3)}
    .att-tl-body{flex:1}
    .att-tl-event{font-size:.8rem;font-weight:600;color:var(--text)}
    .att-tl-time {font-size:.68rem;color:var(--text-muted);margin-top:1px}
    .att-tl-dur  {font-size:.68rem;font-weight:600;color:var(--accent);margin-top:1px}
    .att-empty-log{text-align:center;padding:1.5rem;font-size:.8rem;color:var(--text-muted)}
    .att-empty-log i{display:block;font-size:1.5rem;margin-bottom:.4rem;color:var(--border)}
    /* v5: progress fill colours */
    .att-progress-fill.overtime-fill{background:linear-gradient(90deg,#7c3aed,#a78bfa)!important}
    /* v5: day-status badge variants */
    .day-late-overtime{background:rgba(147,51,234,.12);color:#9333ea;border:1px solid rgba(147,51,234,.2)}
    .day-auto-close   {background:rgba(180,83,9,.12);  color:#b45309;border:1px solid rgba(180,83,9,.2)}
    .icon-auto-close  {background:rgba(180,83,9,.15);  color:#b45309}
    .icon-late-half   {background:rgba(194,65,12,.15); color:#c2410c}
    /* v5: history pill */
    .hdp-latehalf   {background:rgba(194,65,12,.1);   color:#c2410c}
    .hdp-overtime   {background:rgba(124,58,237,.1);  color:#7c3aed}
    /* v5: calendar dot */
    .cal-overtime   {background:rgba(124,58,237,.25); color:#7c3aed;font-weight:700}
    .leave-card
    {
    text-decoration:none;cursor:pointer;
   background:linear-gradient(135deg,#eef2ff 0%,#ede9fe 100%);
   border:1px solid #c7d2fe;display:block;border-radius:var(--radius);padding:1rem 1.1rem;
   box-shadow:var(--shadow);transition:all .25s;
    }
    .leave-card:hover{transform:translateY(-3px);box-shadow:0 8px 24px rgba(99,102,241,.18);border-color:var(--accent)};</style>
</head>
<body>

<!-- NAVBAR -->
<nav class="top-navbar">
  <button class="hamburger" id="hamburger-btn" onclick="toggleSidebar()" aria-label="Toggle navigation">
    <i class="bi bi-list"></i><span class="tt">Menu</span>
  </button>
  <a href="userDashboard" class="nav-brand">Smart<span class="dot">Stock</span>
    <span class="nav-badge"><%= role %></span>
  </a>
  <div class="nav-right">
    <a href="StaffNotifications" class="nav-icon-btn" style="position:relative">
      <i class="bi bi-bell"></i>
      <% if (unreadNotifCount > 0) { %><span class="bell-badge" id="bellBadge"><%= unreadNotifCount %></span><% } %>
      <span class="tt">Notifications</span>
    </a>
    <a href="faq.jsp" class="nav-icon-btn"><i class="bi bi-question-circle"></i><span class="tt">Help &amp; FAQs</span></a>
    <a href="profile" class="nav-avatar" title="<%= uname %>"><%= initials %></a>
  </div>
</nav>

<!-- SIDEBAR OVERLAY -->
<div class="sidebar-overlay" id="sidebar-overlay" onclick="toggleSidebar()"></div>

<!-- SIDEBAR -->
<aside class="sidebar" id="sidebar">
  <div class="sidebar-head">
    <div class="sidebar-brand">Smart<span class="dot">Stock</span></div>
    <div class="sidebar-user">
      <div class="sidebar-avatar"><%= initials %></div>
      <div>
        <div class="sidebar-uname"><%= uname %></div>
        <div class="sidebar-role"><%= role %></div>
      </div>
    </div>
  </div>
  <div class="sidebar-body">
    <div class="sidebar-section">Navigation</div>
    <a href="UserDashboardServlet" class="sidebar-link active"><i class="bi bi-grid-fill"></i> Dashboard</a>
    <a href="profile" class="sidebar-link"><i class="bi bi-person-circle"></i> My Profile</a>
    <div class="sidebar-section">Work</div>
    <a href="ProductServlet?action=stock" class="sidebar-link"><i class="bi bi-box-seam"></i> Stock Management</a>
    <a href="OrdersDashboard" class="sidebar-link"><i class="bi bi-bag-check"></i> Manage Orders &amp; DeliveryAgents</a>
    <a href="ProductServlet" class="sidebar-link"><i class="bi bi-boxes"></i> Products</a>
        <a href="BillsPage" class="sidebar-link"><i class="bi bi-receipt"></i> Bills &amp; Invoices</a>
    
    <div class="sidebar-section">Attendance</div>
    <a href="#attendance-panel" class="sidebar-link" onclick="document.getElementById('attendance-panel').scrollIntoView({behavior:'smooth'});toggleSidebar();">
      <i class="bi bi-clock-history"></i> My Attendance
    </a>
    <a href="LeaveServlet?action=apply" class="sidebar-link"> <i class="bi bi-calendar-heart" style="  color: #c9c6c6;font-size:1.05rem"></i> ApplyLeave</a>

    <div class="sidebar-section">Support</div>
    <a href="StaffNotifications" class="sidebar-link">
      <i class="bi bi-bell"></i> Notifications
      <% if (unreadNotifCount > 0) { %><span class="sidebar-badge"><%= unreadNotifCount %></span><% } %>
    </a>
    <a href="feedback.jsp" class="sidebar-link"><i class="bi bi-chat-dots"></i> Customer Feedback</a>
   <a href="ticketDashboard.jsp" class="sidebar-link" id="nav-tickets-link">
      <i class="bi bi-ticket-perforated"></i>
      <span>Customer Tickets</span>
      <span id="nav-ticket-badge" style="
        display:none;
        background:#ef4444;
        color:#fff;
        border-radius:10px;
        padding:1px 7px;
        font-size:10px;
        font-weight:700;
        margin-left:auto;
      "></span>
    </a>
    <script>
    (function() {
      var badge = document.getElementById('nav-ticket-badge');
      if (!badge) return;
 
      function checkTickets() {
        fetch('StaffAIChatServlet?action=lookupTickets')
          .then(function(r) { return r.json(); })
          .then(function(d) {
            var n = d.count || 0;
            if (n > 0) {
              badge.textContent = n;
              badge.style.display = 'inline-block';
            } else {
              badge.style.display = 'none';
            }
          })
          .catch(function() {});
      }
 
      checkTickets();
      setInterval(checkTickets, 60000); // refresh every 60s
    })();
    </script>
    <a href="faq.jsp" class="sidebar-link"><i class="bi bi-question-circle"></i> Help &amp; FAQs</a>
    <div class="sidebar-section">Account</div>
    <a href="logout" class="sidebar-link danger"><i class="bi bi-box-arrow-right"></i> Logout</a>
  </div>
  <div class="sidebar-footer">© 2026 SmartStock Inventory</div>
</aside>

<!-- MAIN -->
<div class="main-content" id="main-content">

  <!-- Welcome Banner -->
  <div class="welcome-banner fade-up">
    <div class="online-badge"><span class="pulse-dot"></span> Online &amp; Active</div>
    <div class="welcome-greeting">Good <%= getGreeting() %>,</div>
    <div class="welcome-name"><%= uname %> 👋</div>
    <div class="welcome-meta">
      <div><i class="bi bi-person-badge"></i> Role: <span><%= role.substring(0,1).toUpperCase() + role.substring(1).toLowerCase() %></span></div>
      <div><i class="bi bi-clock"></i> Last Login: <span><%= loginTime %></span></div>
    </div>
        <a href="LeaveServlet?action=apply" class="leave-btn"> <i class="bi bi-calendar-heart" ></i> ApplyLeave</a>
    
    <% if ("admin".equalsIgnoreCase(role)) { %>
    <a href="adminDashboard" class="admin-back-btn"><i class="bi bi-arrow-left"></i> Back to Admin Dashboard</a>
    <% } %>
  </div>

  <!-- AUTO_CLOSE Advisory Banner — shown dynamically when prior shift was auto-closed -->
  <div id="autoCloseBanner" style="display:none;background:linear-gradient(135deg,#92400e,#b45309)"
       class="alert-banner fade-up">
    <div class="alert-banner-icon" style="background:rgba(255,255,255,.15)">
      <i class="bi bi-shield-exclamation"></i>
    </div>
    <div class="alert-banner-text">
      <div class="alert-banner-title">⚠️ Previous Shift Auto-Closed</div>
      <div class="alert-banner-sub">
        Your previous shift was automatically closed due to a missing punch-out.
        Please contact your administrator if an adjustment is required.
      </div>
    </div>
    <button onclick="document.getElementById('autoCloseBanner').style.display='none'"
            class="btn-alert-action">
      <i class="bi bi-x-lg"></i> Dismiss
    </button>
  </div>

  <!-- POST-SHIFT FREEZE BANNER — shown when session is still open past shift-end+grace -->
  <div id="shiftEndBanner" style="display:none;background:linear-gradient(135deg,#0c4a6e,#0369a1)"
       class="alert-banner fade-up">
    <div class="alert-banner-icon" style="background:rgba(255,255,255,.15)">
      <i class="bi bi-alarm-fill"></i>
    </div>
    <div class="alert-banner-text">
      <div class="alert-banner-title" id="shiftEndBannerTitle">⏰ Shift Has Ended — Timer Frozen</div>
      <div class="alert-banner-sub" id="shiftEndBannerSub">
        Your shift ended but you haven't punched out. Working hours are frozen at
        your scheduled shift end. Please punch out to finalise your session.
      </div>
    </div>
    <button onclick="attAction('punchOut');document.getElementById('shiftEndBanner').style.display='none'"
            class="btn-alert-action" style="background:rgba(255,255,255,.2);white-space:nowrap">
      <i class="bi bi-box-arrow-right"></i> Punch Out Now
    </button>
  </div>

  <!-- NEW-DAY STALE SESSION BANNER — previous session still open from yesterday -->
  <div id="staleSessBanner" style="display:none;background:linear-gradient(135deg,#4c1d95,#7c3aed)"
       class="alert-banner fade-up">
    <div class="alert-banner-icon" style="background:rgba(255,255,255,.15)">
      <i class="bi bi-calendar-x-fill"></i>
    </div>
    <div class="alert-banner-text">
      <div class="alert-banner-title">📅 Open Session from Previous Day Detected</div>
      <div class="alert-banner-sub" id="staleSessBannerSub">
        A session from a previous shift is still open. The system will auto-close it.
        You may start a new session for today once the old one is finalised.
      </div>
    </div>
    <button onclick="document.getElementById('staleSessBanner').style.display='none'"
            class="btn-alert-action">
      <i class="bi bi-x-lg"></i> Dismiss
    </button>
  </div>

  <!-- Stock Alert -->
  <% if (lowStock > 0 || outOfStock > 0) { %>
  <div class="alert-banner fade-up">
    <div class="alert-banner-icon"><i class="bi bi-exclamation-triangle-fill"></i></div>
    <div class="alert-banner-text">
      <div class="alert-banner-title">⚠️ Stock Alert: <%= outOfStock %> out of stock, <%= lowStock %> running low</div>
      <div class="alert-banner-sub">Review and notify admin for urgent restocking.</div>
    </div>
    <a href="ProductServlet?action=stock" class="btn-alert-action"><i class="bi bi-box-seam"></i> Review Stock</a>
  </div>
  <% } %>



  <!-- Stats -->
  <div class="stats-grid fade-up">
    <div class="stat-card"><div class="stat-icon si-blue"><i class="bi bi-box-seam-fill"></i></div><div class="stat-num"><%= totalProducts %></div><div class="stat-lbl">Products</div></div>
    <div class="stat-card"><div class="stat-icon si-green"><i class="bi bi-check-circle-fill"></i></div><div class="stat-num"><%= inStock %></div><div class="stat-lbl">In Stock</div></div>
    <div class="stat-card"><div class="stat-icon si-amber"><i class="bi bi-exclamation-triangle-fill"></i></div><div class="stat-num"><%= lowStock %></div><div class="stat-lbl">Low Stock</div></div>
    <div class="stat-card"><div class="stat-icon si-red"><i class="bi bi-x-circle-fill"></i></div><div class="stat-num"><%= outOfStock %></div><div class="stat-lbl">Out of Stock</div></div>
    <div class="stat-card"><div class="stat-icon si-purple"><i class="bi bi-receipt-cutoff"></i></div><div class="stat-num"><%= totalOrders %></div><div class="stat-lbl">Today's Orders</div></div>
    <div class="stat-card" id="stat-workhours"><div class="stat-icon si-teal"><i class="bi bi-clock-fill"></i></div><div class="stat-num" id="stat-workhours-val">—</div><div class="stat-lbl">Hrs Worked</div></div>
  
  </div>

  <!-- ══ ATTENDANCE PANEL ══ -->
  <div class="section-label">Today's Attendance</div>
  <div class="attendance-panel fade-up" id="attendance-panel">

    <!-- Header with live clock -->
    <div class="att-header">
      <div class="att-header-left">
        <div class="att-header-icon"><i class="bi bi-fingerprint"></i></div>
        <div>
          <div class="att-header-title">Attendance Tracker</div>
          <div class="att-header-sub" id="attHeaderSub">Office:<%=formattedLogin %> &nbsp;|&nbsp; Late after:<%=formattedLateDeadline %> &nbsp;|&nbsp; Full day: 8 hrs</div>        </div>
      </div>
      <div style="text-align:right">
        <div class="att-live-clock" id="liveClock">--:--:--</div>
        <div class="att-live-date" id="liveDate"></div>
      </div>
    </div>

    <!-- Office timing reference row — values filled dynamically from shift data -->
  <div class="att-office-info" id="attOfficeInfo">
  <span class="att-office-chip"><i class="bi bi-building"></i> Shift: <b id="chipShiftName"><%=userShift.getShiftName() %></b></span>
  <span class="att-office-chip"><i class="bi bi-box-arrow-in-right"></i> Start: <b id="chipLogin"><%=formattedLogin %></b></span>
  
  <span class="att-office-chip"><i class="bi bi-clock-history"></i> Late After: <b id="chipLate"><%=formattedLateDeadline %></b></span>
  
  <span class="att-office-chip"><i class="bi bi-check2-circle"></i> Full Day: <b id="chipFullDay">&ge; 8 hrs</b></span>
  <span class="att-office-chip"><i class="bi bi-adjust"></i> Half Day: <b id="chipHalfDay">4 &ndash; 8 hrs</b></span>
  <span class="att-office-chip"><i class="bi bi-box-arrow-right"></i> Expected Out: <b id="chipLogout"><%=formattedLogout %></b></span>
</div>

    <!-- Late check-in warning (shown dynamically) -->
    <div class="att-late-warn" id="attLateWarn">
      <i class="bi bi-exclamation-triangle-fill"></i>
      <span id="attLateWarnText">You have checked in after <%=formattedLateDeadline %>— this will be recorded as a Late Mark.</span>
    </div>

    <!-- Status bar: punch state + attendance status badge -->
    <div class="att-status-bar">
      <span class="att-status-chip chip-idle" id="attStatusChip">
        <span class="chip-dot"></span>
        <span id="attStatusText">Not Punched In</span>
      </span>
      <!-- Attendance Status Badge -->
      <span class="att-day-status day-pending" id="attDayStatusBadge">
        <i class="bi bi-hourglass-split" id="attDayStatusIcon"></i>
        <span id="attDayStatusText">No Check-In</span>
      </span>
      <span class="att-status-msg" id="attStatusMsg">Start your work day by punching in.</span>
    </div>

    <!-- Time meters -->
    <div class="att-meters">
      <div class="att-meter meter-working">
        <div class="att-meter-icon"><i class="bi bi-play-circle-fill"></i></div>
        <div class="att-meter-val" id="meterWorking">00:00:00</div>
        <div class="att-meter-lbl">Work Time</div>
      </div>
      <div class="att-meter meter-break">
        <div class="att-meter-icon"><i class="bi bi-cup-hot-fill"></i></div>
        <div class="att-meter-val" id="meterBreak">00:00:00</div>
        <div class="att-meter-lbl">Break Time</div>
      </div>
      <div class="att-meter meter-net">
        <div class="att-meter-icon"><i class="bi bi-lightning-charge-fill"></i></div>
        <div class="att-meter-val" id="meterNet">00:00:00</div>
        <div class="att-meter-lbl">Net Hours</div>
      </div>
    </div>

    <!-- Progress bar with milestone markers -->
    <div class="att-progress-wrap">
      <div class="att-progress-top">
        <span class="att-progress-label"><i class="bi bi-bullseye"></i> <span id="progressLabel">Shift Target: 8 hrs</span> &nbsp;
          <span id="progressSubLabel" style="font-size:.65rem;color:var(--text-muted)">(4h = Half Day | 8h = Full Day)</span>
        </span>
        <span class="att-progress-pct" id="progressPct">0%</span>
      </div>
      <div class="att-progress-track"><div class="att-progress-fill" id="progressFill"></div></div>
    </div>

    <!-- Milestone chips -->
    <div class="att-milestones">
      <span class="att-milestone" id="ms4h"><i class="bi bi-circle"></i><span> 4h — Half Day</span></span>
      <span class="att-milestone" id="ms6h"><i class="bi bi-circle"></i><span> 6h — Good Progress</span></span>
      <span class="att-milestone" id="ms8h"><i class="bi bi-circle"></i><span> 8h — Full Day ✓</span></span>
    </div>
   <div id="breakLimitWarn">
      <i class="bi bi-slash-circle-fill"></i>
      <span>You've used all <strong id="breakLimitNumUsed">2</strong> breaks allowed this shift. No more breaks permitted.</span>
    </div>

    <!-- Shift-end freeze notice (shown inside panel when timer is frozen) -->
    <div id="attShiftEndNotice" style="display:none;margin:.75rem 0;padding:.65rem 1rem;
         background:rgba(251,191,36,.1);border:1px solid rgba(251,191,36,.3);
         border-left:3px solid #f59e0b;border-radius:8px;font-size:.8rem;color:#92400e;
         display:flex;align-items:center;gap:.5rem">
      <i class="bi bi-alarm-fill" style="color:#f59e0b;flex-shrink:0"></i>
      <span id="attShiftEndNoticeText">Your shift has ended. Timer is frozen at scheduled shift-end time.
        Working hours beyond shift end are NOT counted. Please punch out to finalise your session.</span>
    </div>
    <!-- Action Buttons -->
    <div class="att-actions">
      <button class="btn-att btn-punch-in"  id="btnPunchIn"  onclick="attAction('punchIn')">
        <i class="bi bi-box-arrow-in-right"></i>Punch In
      </button>
      <button class="btn-att btn-break"     id="btnBreak"    onclick="attAction('startBreak')" disabled>
        <i class="bi bi-cup-hot"></i>Take Break
      </button>
      <button class="btn-att btn-resume"    id="btnResume"   onclick="attAction('resumeWork')" disabled>
        <i class="bi bi-play-fill"></i>Resume Work
      </button>
      <button class="btn-att btn-punch-out" id="btnPunchOut" onclick="confirmPunchOut()" disabled>
        <i class="bi bi-box-arrow-right"></i>Punch Out
      </button>
      
    </div>

    <!-- End-of-day Summary (shown after punch-out) -->
    <div class="att-summary" id="attSummary">
      <div class="att-summary-title"><i class="bi bi-clipboard-data"></i> Today's Work Summary</div>
      <div class="att-summary-grid">
        <div><div class="att-sum-val" id="sumTotal">—</div><div class="att-sum-lbl">Total Shift</div></div>
        <div><div class="att-sum-val" id="sumWork">—</div><div class="att-sum-lbl">Work Time</div></div>
        <div><div class="att-sum-val" id="sumBreak">—</div><div class="att-sum-lbl">Break Time</div></div>
      </div>
      <div class="att-sum-divider"></div>
      <!-- Final Attendance Status Card -->
      <div class="att-final-status" id="attFinalStatus">
        <div class="att-final-icon icon-pending" id="attFinalIcon"><i class="bi bi-hourglass-split"></i></div>
        <div>
          <div class="att-final-label">Attendance Status</div>
          <div class="att-final-val" id="attFinalVal">—</div>
          <div class="att-final-sub" id="attFinalSub"></div>
        </div>
      </div>
      <div id="sumOtBadge" style="margin-top:.5rem"></div>
    </div>

    <!-- Activity Timeline -->
    <div class="att-log">
      <div class="att-log-title">
        <span><i class="bi bi-clock-history"></i> &nbsp;Activity Log</span>
        <span id="logCount" style="font-size:.68rem;font-weight:600;color:var(--accent)"></span>
      </div>
      <ul class="att-timeline" id="attTimeline">
        <li class="att-empty-log" id="attEmptyLog">
          <i class="bi bi-calendar-x"></i>No activity recorded yet. Punch in to start tracking.
        </li>
      </ul>
    </div>

  </div><!-- /.attendance-panel -->

  <!-- Work Modules -->
  <div class="section-label">Work Modules</div>
     
  <div class="modules-grid fade-up">
     <a href="<%=request.getContextPath()%>/LeaveServlet" class="module-card" style="text-decoration:none;cursor:pointer;
   background:linear-gradient(135deg,#eef2ff 0%,#ede9fe 100%);
   border:1px solid #c7d2fe;display:block;border-radius:12px;padding:1rem 1.1rem;
   box-shadow:0 1px 3px rgba(0,0,0,.06),0 4px 16px rgba(0,0,0,.06);transition:all .2s"
   onmouseover="this.style.transform='translateY(-2px)';this.style.boxShadow='0 8px 24px rgba(99,102,241,.18)'"
   onmouseout="this.style.transform='';this.style.boxShadow='0 1px 3px rgba(0,0,0,.06),0 4px 16px rgba(0,0,0,.06)'">

  <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:.6rem">
    <div style="width:36px;height:36px;border-radius:8px;background:#6366f1;
                display:flex;align-items:center;justify-content:center">
      <i class="bi bi-calendar-heart" style="color:#fff;font-size:1.05rem"></i>
    </div>
    <% if (leavePending > 0) { %>
    <span style="background:#fef3c7;color:#92400e;font-size:.68rem;font-weight:700;
                 padding:.2rem .55rem;border-radius:20px;border:1px solid #fde68a">
      <%=leavePending%> pending
    </span>
    <% } else { %>
    <span style="background:#d1fae5;color:#065f46;font-size:.68rem;font-weight:700;
                 padding:.2rem .55rem;border-radius:20px;border:1px solid #6ee7b7">
      No pending
    </span>
    <% } %>
  </div>

  <div style="font-size:1.6rem;font-weight:800;color:#0f172a;line-height:1"><%=leaveAvail%></div>
  <div style="font-size:.72rem;font-weight:600;color:#6366f1;margin-top:.15rem">days available</div>
  <div style="font-size:.75rem;color:#64748b;margin-top:.5rem;font-weight:500">
    Leave Management <i class="bi bi-arrow-right" style="font-size:.7rem"></i>
  </div>
</a>
    <a href="ProductServlet?action=stock" class="module-card" style="--c:#10b981">
      <div class="module-icon" style="background:var(--success-bg);color:var(--success)"><i class="bi bi-box-seam"></i></div>
      <div class="module-name">Stock Management</div>
      <div class="module-desc">Check inventory, flag low-stock, notify admin</div>
      <div class="module-arrow"><i class="bi bi-arrow-right"></i></div>
    </a>
    <a href="OrdersDashboard" class="module-card" style="--c:#3b82f6">
      <div class="module-icon" style="background:var(--accent-light);color:var(--accent)"><i class="bi bi-bag-check"></i></div>
      <div class="module-name">Manage Orders</div>
      <div class="module-desc">Process orders, assign delivery, invoices</div>
      <div class="module-arrow"><i class="bi bi-arrow-right"></i></div>
    </a>
    <a href="ProductServlet" class="module-card" style="--c:#06b6d4">
      <div class="module-icon" style="background:var(--teal-bg);color:var(--teal)"><i class="bi bi-boxes"></i></div>
      <div class="module-name">Products</div>
      <div class="module-desc">Browse catalogue, check pricing</div>
      <div class="module-arrow"><i class="bi bi-arrow-right"></i></div>
    </a>
    <a href="BillsPage" class="module-card" style="--c:#f59e0b">
      <div class="module-icon" style="background:var(--warning-bg);color:var(--warning)"><i class="bi bi-receipt"></i></div>
      <div class="module-name">Bills &amp; Invoices</div>
      <div class="module-desc">View billing summaries &amp; audit trail</div>
      <div class="module-arrow"><i class="bi bi-arrow-right"></i></div>
    </a>
    <a href="feedback.jsp" class="module-card" style="--c:#8b5cf6">
      <div class="module-icon" style="background:var(--purple-bg);color:var(--purple)"><i class="bi bi-chat-dots-fill"></i></div>
      <div class="module-name">Customer Feedback</div>
      <div class="module-desc">Review comments, respond to queries</div>
      <div class="module-arrow"><i class="bi bi-arrow-right"></i></div>
    </a>
     <!-- Open Tickets stat card -->
   <a href="ticketDashboard.jsp" style="font-size:11px;color:#4338ca;font-weight:600;text-decoration:none">
    <div class="stat-card" style="border-left:4px solid #4338ca;" id="dash-ticket-stat">
      <div class="stat-icon" style="background:#eef2ff;color:#4338ca">
        <i class="bi bi-ticket-perforated"></i>
      </div>
      <div class="stat-body">
        <div class="stat-label">Open Tickets</div>
        <div class="stat-value" id="dash-ticket-count">—</div>
          View Queue →
      </div>
    </div>        </a>
    

    <!-- Add this script near the bottom of the page (after the stat cards HTML): -->
    <script>
    fetch('StaffAIChatServlet?action=lookupTickets')
    .then(function(r) { return r.json(); })
    .then(function(d) {
      var el = document.getElementById('dash-ticket-count');
      if (el) el.textContent = d.count || 0;
      // Highlight card red if urgent tickets exist
      var urgent = (d.tickets||[]).filter(function(t){
        return t.paymentStatus==='INTERCEPT_REQUESTED'||t.paymentStatus==='ADDRESS_CORRECTION';
      }).length;
      if (urgent > 0) {
        var card = document.getElementById('dash-ticket-stat');
        if (card) card.style.borderLeftColor = '#dc2626';
      }
    })
    .catch(function() {});
    </script>
    <a href="profile" class="module-card" style="--c:#ef4444">
      <div class="module-icon" style="background:var(--danger-bg);color:var(--danger)"><i class="bi bi-person-circle"></i></div>
      <div class="module-name">My Profile</div>
      <div class="module-desc">Update details &amp; account settings</div>
      <div class="module-arrow"><i class="bi bi-arrow-right"></i></div>
    </a>
  </div>

  <!-- ══ ATTENDANCE HISTORY PANEL ══ -->
  <div class="section-label">My Attendance History</div>
  <div class="att-history-panel fade-up" id="attHistoryPanel">

    <!-- Header -->
    <div class="att-hist-header">
      <div>
        <div class="att-hist-title"><i class="bi bi-calendar3-week"></i> Attendance Record</div>
        <div class="att-hist-sub" id="attHistSub">Your daily attendance status for the last 30 days — Office: <%=formattedLogin %> | Late after: <%= formattedLateDeadline %></div>
      </div>
      <button onclick="loadHistory()" style="background:rgba(255,255,255,.12);border:1px solid rgba(255,255,255,.25);border-radius:6px;color:#fff;padding:.3rem .75rem;font-size:.75rem;font-weight:600;cursor:pointer;font-family:inherit;display:flex;align-items:center;gap:.35rem">
        <i class="bi bi-arrow-clockwise"></i> Refresh
      </button>
    </div>

    <!-- Tabs: Table | Calendar -->
    <div class="att-hist-tabs">
      <button class="att-hist-tab active" id="tabTable"    onclick="switchHistTab('table')">   <i class="bi bi-table"></i>       &nbsp;Daily Log</button>
      <button class="att-hist-tab"        id="tabCalendar" onclick="switchHistTab('calendar')"><i class="bi bi-calendar3"></i>   &nbsp;Calendar View</button>
    </div>

    <!-- Summary cards -->
    <div class="att-hist-summary" id="histSummaryRow">
      <div class="att-hist-sum-card"><div class="att-hist-sum-val hsc-full"   id="hsFull">—</div><div class="att-hist-sum-lbl">Full Days</div></div>
      <div class="att-hist-sum-card"><div class="att-hist-sum-val hsc-half"   id="hsHalf">—</div><div class="att-hist-sum-lbl">Half Days</div></div>
      <div class="att-hist-sum-card"><div class="att-hist-sum-val hsc-late"   id="hsLate">—</div><div class="att-hist-sum-lbl">Late Marks</div></div>
      <div class="att-hist-sum-card"><div class="att-hist-sum-val hsc-absent" id="hsAbsent">—</div><div class="att-hist-sum-lbl">Absent</div></div>
      <div class="att-hist-sum-card"><div class="att-hist-sum-val hsc-hrs"    id="hsHours">—</div><div class="att-hist-sum-lbl">Total Hours</div></div>
    </div>

    <!-- TABLE VIEW -->
    <div id="histTableView">
      <div class="att-hist-table-wrap">
        <table class="att-hist-table">
          <thead>
            <tr>
              <th>Date</th>
              <th>Day</th>
              <th>Attendance Status</th>
              <th>Punch In</th>
              <th>Punch Out</th>
              <th>Work Time</th>
              <th>Break</th>
              <th>Net Hours</th>
            </tr>
          </thead>
          <tbody id="histTableBody">
            <tr><td colspan="8">
              <div class="att-hist-empty"><i class="bi bi-hourglass-split"></i>Loading your attendance history…</div>
            </td></tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- CALENDAR VIEW (hidden by default) -->
    <div id="histCalendarView" style="display:none">
      <div class="att-hist-calendar">
        <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:.5rem ;">
          <button onclick="calPrev()" style="background:none;border:1px solid var(--border);border-radius:6px;padding:.2rem .6rem;cursor:pointer;font-size:.8rem;color:var(--text-muted)"><i class="bi bi-chevron-left"></i></button>
          <span id="calMonthLabel" style="font-size:.85rem;font-weight:700;color:var(--text)"></span>
          <button onclick="calNext()" style="background:none;border:1px solid var(--border);border-radius:6px;padding:.2rem .6rem;cursor:pointer;font-size:.8rem;color:var(--text-muted)"><i class="bi bi-chevron-right"></i></button>
        </div>
        <div class="att-cal-grid" id="calGrid"></div>
        <div class="att-cal-legend">
          <span class="att-cal-leg-item"><span class="att-cal-leg-dot" style="background:rgba(16,185,129,.3)"></span>Full Day</span>
          <span class="att-cal-leg-item"><span class="att-cal-leg-dot" style="background:rgba(6,182,212,.25)"></span>Half Day</span>
          <span class="att-cal-leg-item"><span class="att-cal-leg-dot" style="background:rgba(245,158,11,.3)"></span>Late Mark</span>
          <span class="att-cal-leg-item"><span class="att-cal-leg-dot" style="background:rgba(239,68,68,.2)"></span>Absent</span>
          <span class="att-cal-leg-item"><span class="att-cal-leg-dot" style="background:#3882cb;border:1px solid var(--border)"></span>No Data</span>
        </div>
      </div>
    </div>

  </div><!-- /.att-history-panel -->

  <!-- Today's Tasks -->
  <div class="section-label">Today's Tasks</div>
  <div class="tasks-panel fade-up">
    <div class="tasks-head">
      <div class="tasks-title"><i class="bi bi-clipboard-check-fill"></i> Task Checklist</div>
      <div class="tasks-date"><%= today %></div>
    </div>
    <div class="task-item"><div class="task-dot dot-amber"></div><span class="task-text">Check low-stock products and send restock notification to admin</span><span class="task-badge badge-pending">Pending</span><span class="task-time">09:00 AM</span></div>
    <div class="task-item"><div class="task-dot dot-green"></div><span class="task-text">Process pending customer orders and generate invoices</span><span class="task-badge badge-done">Done</span><span class="task-time">10:30 AM</span></div>
    <div class="task-item"><div class="task-dot dot-blue"></div><span class="task-text">Review and respond to new customer feedback entries</span><span class="task-badge badge-progress">In Progress</span><span class="task-time">12:00 PM</span></div>
    <div class="task-item"><div class="task-dot dot-amber"></div><span class="task-text">Update product stock counts after incoming delivery</span><span class="task-badge badge-pending">Pending</span><span class="task-time">03:00 PM</span></div>
    <div class="task-item"><div class="task-dot dot-red"></div><span class="task-text">End-of-day billing summary report to admin</span><span class="task-badge badge-pending">Pending</span><span class="task-time">06:00 PM</span></div>
  </div>

  <footer class="site-footer">&copy; 2026 <strong style="color:var(--accent)">SmartStock</strong> &nbsp;|&nbsp; <a href="faq.jsp">FAQs</a> &nbsp;·&nbsp; <a href="feedback.jsp">Feedback</a></footer>
</div>

<!-- Bottom Nav -->
<nav class="bottom-nav">
  <a href="userDashboard" class="bnav-item active"><i class="bi bi-grid-fill"></i>Home</a>
  <a href="OrdersDashboard" class="bnav-item"><i class="bi bi-bag-check"></i>Orders</a>
  <a href="ProductServlet?action=stock" class="bnav-item"><i class="bi bi-box-seam"></i>Stock</a>
  <a href="StaffNotifications" class="bnav-item"><i class="bi bi-bell"></i>Alerts</a>
  <a href="profile" class="bnav-item"><i class="bi bi-person-circle"></i>Profile</a>
</nav>

<!-- Toast -->
<div id="toast"><div id="toast-inner"><i class="bi bi-check-circle-fill" style="color:white;flex-shrink:0"></i>
  <span>Welcome back, <strong><%= uname %></strong>!</span>
  <button onclick="document.getElementById('toast').classList.remove('show')" style="margin-left:auto;background:none;border:none;color:rgba(255,255,255,.5);cursor:pointer;font-size:1rem"><i class="bi bi-x"></i></button>
</div></div>

<!-- Punch-Out Confirmation Modal -->
<div id="punchOutModal" style="display:none;position:fixed;inset:0;z-index:4000;background:rgba(15,23,42,.6);backdrop-filter:blur(4px);align-items:center;justify-content:center;">
  <div style="background:#fff;border-radius:16px;padding:2rem;max-width:380px;width:90%;box-shadow:0 20px 60px rgba(0,0,0,.25);text-align:center">
    <div style="width:56px;height:56px;border-radius:50%;background:var(--danger-bg);display:flex;align-items:center;justify-content:center;margin:0 auto 1rem;font-size:1.6rem;color:var(--danger)"><i class="bi bi-box-arrow-right"></i></div>
    <div style="font-size:1rem;font-weight:700;color:var(--text);margin-bottom:.4rem">Confirm Punch Out</div>
    <div style="font-size:.82rem;color:var(--text-muted);margin-bottom:.75rem">Your working hours will be saved and reported to admin.</div>
    <!-- Live preview of attendance status at punch-out -->
    <div id="punchOutPreview" style="background:var(--bg-off);border:1px solid var(--border);border-radius:var(--radius-sm);padding:.75rem;margin-bottom:1.25rem;font-size:.8rem;color:var(--text-mid)">
      <div style="font-size:.68rem;font-weight:600;color:var(--text-muted);text-transform:uppercase;letter-spacing:.5px;margin-bottom:.4rem">Expected Attendance Status</div>
      <div id="punchOutStatusPreview" style="font-size:.92rem;font-weight:700;color:var(--text)">Calculating…</div>
    </div>
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:.75rem">
      <button onclick="closePunchOutModal()" style="padding:.7rem;border-radius:var(--radius-sm);border:1px solid var(--border);background:#fff;font-size:.85rem;font-weight:600;cursor:pointer;font-family:inherit;color:var(--text-mid)">Cancel</button>
      <button onclick="attAction('punchOut')" style="padding:.7rem;border-radius:var(--radius-sm);border:none;background:var(--danger);color:#fff;font-size:.85rem;font-weight:700;cursor:pointer;font-family:inherit">Punch Out</button>
    </div>
  </div>
</div>
 <jsp:include page="staffChatWidget.jsp" />
<script>
/* ── SIDEBAR ── */
function toggleSidebar(){
  document.getElementById('sidebar').classList.toggle('open');
  document.getElementById('sidebar-overlay').classList.toggle('open');
}
window.addEventListener('DOMContentLoaded', function(){
  const t = document.getElementById('toast');
  t.classList.add('show');
  setTimeout(()=>t.classList.remove('show'), 5000);
  initAttendance();
  startLiveClock();
  loadTodaySession();
});
document.getElementById('hamburger-btn').addEventListener('click',function(){
  const isOpen = document.getElementById('sidebar').classList.contains('open');
  localStorage.setItem('sidebar-state', isOpen ? 'closed' : 'open');
});

/* ── LIVE CLOCK ── */
function startLiveClock(){
  function tick(){
    const now = new Date();
    document.getElementById('liveClock').textContent =
      now.toLocaleTimeString('en-IN',{hour:'2-digit',minute:'2-digit',second:'2-digit',hour12:false});
    document.getElementById('liveDate').textContent =
      now.toLocaleDateString('en-IN',{weekday:'long',day:'numeric',month:'long',year:'numeric'});
  }
  tick(); setInterval(tick, 1000);
}





/* ── 1. Global threshold vars — declared FIRST so _seedShift can write them ── */
let FULL_DAY_MS  = 8 * 3600 * 1000;   // ms, updated by _seedShift()
let HALF_DAY_MS  = 4 * 3600 * 1000;   // always = FULL_DAY_MS / 2
let SHIFT_HOURS  = 8;                  // float hours, e.g. 9.0 for a 9-hour shift

/* Active shift config — written by _seedShift(), never hardcoded after boot */
let shiftState = {
  loginH: 9,  loginM: 0,
  lateH:  10, lateM:  0,
  logoutH: 18, logoutM: 0,
  nightShift: false,
  graceMinutes: 60,
  shiftName: 'General',
  scheduledHours: 8   // used by computeAttendanceStatus short-shift rule
};

/* Attendance session state */
let attState = {
  status: 'idle',           // idle | working | onBreak | punchedOut
  sessionId: null,
  punchInTime: null,        // epoch ms — set from server response
  punchOutTime: null,       // epoch ms — set from server response, NEVER Date.now()
  breakStart: null,         // epoch ms — local only, measures current break
  totalBreakMs: 0,          // confirmed by server on every resumeWork / punchOut
  netWorkMs: 0,             // authoritative from server after punchOut (DB value)
  attendanceStatus: 'absent',
  breakCount: 0,
  log: []
};
let attTimer = null;

/* ── Night-shift aware localStorage keys ── */
const _todayStr     = new Date().toISOString().slice(0, 10);
const _yesterdayStr = (() => {
  const d = new Date(); d.setDate(d.getDate() - 1); return d.toISOString().slice(0, 10);
})();
const ATT_KEY_TODAY = 'att_<%= uname %>_' + _todayStr;
const ATT_KEY_YEST  = 'att_<%= uname %>_' + _yesterdayStr;
let   ATT_KEY       = ATT_KEY_TODAY;

/* ── 2. _seedShift — computes all shift-duration globals from raw H/M values ──
   Called at boot from JSP values and again from applyShiftToUI (server data).
   Night shift: loginMins > logoutMins (crosses midnight, e.g. 21:00→06:00)
────────────────────────────────────────────────────────────────────────────── */
function _seedShift(lh, lm, loh, lom, grace, shiftName) {
  const loginMins  = lh  * 60 + lm;
  const logoutMins = loh * 60 + lom;
  const isNight    = loginMins > logoutMins;

  /* Duration:  night shift adds 1440 to cross midnight correctly.
     e.g. 21:00→06:00 = (360+1440)−1260 = 540 min = 9 h
          09:00→18:00 = 1080−540         = 540 min = 9 h  */
  const durationMins = isNight
    ? (logoutMins + 1440) - loginMins
    : logoutMins - loginMins;

  /* Late threshold = shift start + grace (wraps past midnight if needed) */
  const lateTotalMins = loginMins + grace;
  const lateH = Math.floor(lateTotalMins / 60) % 24;
  const lateM = lateTotalMins % 60;

  SHIFT_HOURS  = durationMins / 60;
  FULL_DAY_MS  = durationMins * 60 * 1000;
  HALF_DAY_MS  = Math.round(durationMins / 2) * 60 * 1000;

  shiftState = {
    loginH: lh,  loginM: lm,
    lateH,       lateM,
    logoutH: loh, logoutM: lom,
    nightShift: isNight,
    graceMinutes: grace,
    shiftName: shiftName || '—',
    scheduledHours: durationMins / 60   // used by short-shift rule in computeAttendanceStatus
  };
}

/* ── 3. Boot seed — JSP renders userShift values synchronously at page load ──
   Format from amPmFormatter: "09:00 AM" / "09:00 PM"
   _parse12 converts back to 24-hour H and M.
────────────────────────────────────────────────────────────────────────────── */
(function () {
  function _parse12(str) {
    if (!str) return [0, 0];
    const m = str.match(/^(\d{1,2}):(\d{2})\s*(AM|PM)$/i);
    if (!m) return [0, 0];
    let h = parseInt(m[1], 10), mn = parseInt(m[2], 10);
    if (m[3].toUpperCase() === 'PM' && h !== 12) h += 12;
    if (m[3].toUpperCase() === 'AM' && h === 12) h = 0;
    return [h, mn];
  }
  const [lh,  lm]  = _parse12('<%= expectedLogin  != null ? expectedLogin.format(amPmFormatter).toUpperCase()  : "09:00 AM" %>');
  const [loh, lom] = _parse12('<%= expectedLogout != null ? expectedLogout.format(amPmFormatter).toUpperCase() : "06:00 PM" %>');
  const grace      = <%= userShift.getLateGraceMinutes() %>;
  const shiftName  = '<%= userShift.getShiftName() != null ? userShift.getShiftName().replace("'","\\'") : "General" %>';
  _seedShift(lh, lm, loh, lom, grace, shiftName);
})();

/* ══════════════════════════════════════════════════════════════
   STATUS COMPUTATION  v5
   Mirrors AttendanceStatusUtil.compute() in Java exactly.
   Uses FULL_DAY_MS / HALF_DAY_MS (shift-aware, set by _seedShift).
   OT_GRACE_MS = 15 min — prevents 1 min over shift counting as OT.
══════════════════════════════════════════════════════════════ */
const OT_GRACE_MS = 15 * 60 * 1000;   // 15 minutes

function computeAttendanceStatus(punchInMs, punchOutMs, netWorkMs) {
  if (!punchInMs)   return 'no_checkin';
  if (!punchOutMs)  return 'pending';

  /* ── Is this punch-in late? ── */
  const piDate     = new Date(punchInMs);
  const piMins     = piDate.getHours() * 60 + piDate.getMinutes();
  const lateThresh = shiftState.lateH * 60 + shiftState.lateM;
  let isLate = false;

  if (shiftState.nightShift) {
    const logoutMins     = shiftState.logoutH * 60 + shiftState.logoutM;
    /* Post-midnight punch-in (e.g. 02:00 on a 21:00→06:00 shift) → always on-time */
    const isPostMidnight = logoutMins > 0 ? piMins < logoutMins : false;
    isLate = isPostMidnight ? false : piMins > lateThresh;
  } else {
    isLate = piMins > lateThresh;
  }

  /* ── Classify by netWorkMs against shift-aware thresholds ──
     FULL_DAY_MS = actual shift duration (set by _seedShift)
     HALF_DAY_MS = FULL_DAY_MS / 2
     OT_GRACE_MS = 15-min window to avoid 1-minute-overtime false positives
  ── */
  if (netWorkMs < HALF_DAY_MS)                               return 'absent';
  if (netWorkMs >= HALF_DAY_MS && netWorkMs < FULL_DAY_MS)   return isLate ? 'late_half'     : 'half_day';
  if (netWorkMs <= FULL_DAY_MS + OT_GRACE_MS)                return isLate ? 'late'           : 'full_day';
  /* Beyond full shift + grace → overtime */                  return isLate ? 'late_overtime'  : 'overtime';
}

/* Map server attendance_status strings → JS status keys */
function _normaliseAttStatus(s) {
  if (!s) return 'pending';
  switch (s.toLowerCase()) {
    /* server v5 canonical (lowercase_snake) */
    case 'full_day':       return 'full_day';
    case 'half_day':       return 'half_day';
    case 'late':           return 'late';
    case 'late_half':      return 'late_half';
    case 'overtime':       return 'overtime';
    case 'late_overtime':  return 'late_overtime';
    case 'absent':         return 'absent';
    case 'pending':        return 'pending';
    case 'auto_close':
    case 'system_closed':  return 'auto_close';
    case 'no_checkin':     return 'no_checkin';
    /* legacy uppercase that old DB rows may still contain */
    case 'present':        return 'full_day';
    case 'auto_close_uc':  return 'auto_close';
    default:               return s.toLowerCase();
  }
}

/* ── Status display config (badge label / icon / colour per status key) ── */
const STATUS_CFG = {
  full_day:      { label:'Present (Full Day)',       css:'day-full',        icon:'check-circle-fill',       iconCls:'icon-full',         sub:'Checked in on time and completed full shift hours.',              color:'#059669' },
  overtime:      { label:'Present (Overtime)',       css:'day-overtime',    icon:'star-fill',               iconCls:'icon-overtime',     sub:'Checked in on time and worked beyond full shift hours.',          color:'#7c3aed' },
  half_day:      { label:'Present (Half Day)',       css:'day-half',        icon:'adjust',                  iconCls:'icon-half',         sub:'Checked in on time. Completed at least half your shift hours.',   color:'#0891b2' },
  absent:        { label:'Absent',                   css:'day-absent',      icon:'x-circle-fill',           iconCls:'icon-absent',       sub:'Less than half your shift hours were worked.',                    color:'#dc2626' },
  late:          { label:'Late Mark',                css:'day-late',        icon:'clock-history',           iconCls:'icon-late',         sub:'Checked in after the grace deadline. Full shift hours completed.', color:'#d97706' },
  late_half:     { label:'Late Mark (Half Day)',     css:'day-late-half',   icon:'exclamation-circle-fill', iconCls:'icon-late-half',    sub:'Late check-in and less than full shift hours worked.',             color:'#c2410c' },
  late_overtime: { label:'Late Mark (Overtime)',     css:'day-late-half',   icon:'exclamation-diamond-fill',iconCls:'icon-late-half',    sub:'Late check-in but worked beyond the full shift. Overtime noted.',  color:'#9333ea' },
  pending:       { label:'In Progress',              css:'day-pending',     icon:'hourglass-split',         iconCls:'icon-pending',      sub:'Session still open — punch out to finalise your attendance.',      color:'#94a3b8' },
  no_checkin:    { label:'No Check-In',              css:'day-absent',      icon:'dash-circle',             iconCls:'icon-absent',       sub:'No attendance recorded yet today.',                                color:'#94a3b8' },
  absent_nc:     { label:'No Check-In',              css:'day-absent',      icon:'dash-circle',             iconCls:'icon-absent',       sub:'No attendance recorded yet today.',                                color:'#94a3b8' },
  auto_close:    { label:'Auto-Closed',              css:'day-auto-close',  icon:'shield-exclamation',      iconCls:'icon-auto-close',   sub:'Session auto-closed by system. Contact admin for correction.',     color:'#b45309' }
};

/* ── localStorage helpers ── */
function saveAtt() { localStorage.setItem(ATT_KEY, JSON.stringify(attState)); }
function loadAtt() {
  try {
    const r = localStorage.getItem(ATT_KEY_TODAY);
    if (r) { attState = JSON.parse(r); ATT_KEY = ATT_KEY_TODAY; return; }
    /* Night-shift: session was started yesterday — restore only if still open */
    const yr = localStorage.getItem(ATT_KEY_YEST);
    if (yr) {
      const ys = JSON.parse(yr);
      if (ys && (ys.status === 'working' || ys.status === 'onBreak')) {
        attState = ys; ATT_KEY = ATT_KEY_YEST;
      }
    }
  } catch (e) {}
}

function initAttendance() {
  loadAtt();
  renderAttUI();
  /* BUG FIX 1 — Timer running on auto-closed/punchedOut session:
     initAttendance() fires BEFORE loadTodaySession() gets a server response.
     Stale localStorage may say status='working' even though the session was
     auto-closed overnight. This starts a timer that is never stopped because
     restoreSession() (called ~100ms later) didn't call stopTimer().
     FIX A: Don't start the timer if localStorage shows an already-closed status.
     FIX B: restoreSession() now always calls stopTimer() for closed sessions. */
  if (attState.status === 'working' || attState.status === 'onBreak') {
    /* Only start if today's session — stale sessions will be corrected by server */
    const sessionDateStr = attState.punchInTime
      ? new Date(attState.punchInTime).toISOString().slice(0, 10)
      : null;
    const isStaleDate = sessionDateStr && sessionDateStr < _todayStr;
    if (!isStaleDate) startTimer();
    } else if (attState.status === 'punchedOut' || attState.status === 'auto_close') {
      /* FIX v6: closed sessions — ensure timer is never started from stale localStorage */
      stopTimer();
    }
}

/* ── Time formatters ── */
function fmtMs(ms) {
  if (ms < 0) ms = 0;
  const s = Math.floor(ms / 1000);
  return String(Math.floor(s / 3600)).padStart(2, '0') + ':' +
         String(Math.floor((s % 3600) / 60)).padStart(2, '0') + ':' +
         String(s % 60).padStart(2, '0');
}
function fmtMsShort(ms) {
  if (ms < 0) ms = 0;
  const m = Math.floor(ms / 60000), h = Math.floor(m / 60);
  return h > 0 ? h + 'h ' + (m % 60) + 'm' : (m % 60) + 'm';
}
function fmtTime(ts) {
  return new Date(ts).toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: true });
}
function _fmt12(h, m) {
  return ((h % 12) || 12) + ':' + (m < 10 ? '0' : '') + m + ' ' + (h >= 12 ? 'PM' : 'AM');
}
function _fmtH(h) {
  const n = parseFloat(h);
  return Number.isInteger(n) ? n + 'h' : n.toFixed(1).replace(/\.0$/, '') + 'h';
}

/* ── Live elapsed work time ──────────────────────────────────────────────────
   REAL-WORLD RULE: If a staff member forgets to punch out, their timer is
   frozen at the scheduled shift-end time once (shiftEnd + AUTO_CLOSE_GRACE)
   has passed.  This mirrors what the server will do on auto-close:
   punch_out = shiftEndBoundary (normalised, NOT wall-clock).

   3 cases:
   A) Session punched out → use server netWorkMs (most accurate)
   B) Session open, wall-clock < shiftEnd → count live elapsed (normal)
   C) Session open, wall-clock ≥ shiftEnd → freeze elapsed at shiftEnd
      (staff forgot to punch out — don't keep inflating the counter)
────────────────────────────────────────────────────────────────────────────── */
function _getShiftEndMs() {
  /* Returns epoch-ms of today's (or yesterday's for night shift) scheduled logout */
  if (!attState.punchInTime) return 0;
  const sessionDate = new Date(attState.punchInTime);
  const base = new Date(
    sessionDate.getFullYear(), sessionDate.getMonth(), sessionDate.getDate(),
    shiftState.logoutH, shiftState.logoutM, 0, 0
  );
  if (shiftState.nightShift) base.setDate(base.getDate() + 1);
  return base.getTime();
}

function getWorkMs() {
  /* A) Already punched out (includes auto_close) — use DB value.
     BUG FIX 5: was only checking attState.netWorkMs > 0 after punchedOut.
     Auto-closed sessions restore with status='punchedOut' and netWorkMs from DB.
     If for any reason netWorkMs=0 but punchOutTime exists, fall through to calc. */
  if (attState.status === 'punchedOut' || attState.status === 'auto_close') {
    /* FIX v6: auto_close sessions are closed — return DB value directly */
    if (attState.netWorkMs > 0) return attState.netWorkMs;
    /* netWorkMs missing — compute from timestamps if available */
    if (attState.punchOutTime && attState.punchInTime) {
      return Math.max(0, (attState.punchOutTime - attState.punchInTime) - (attState.totalBreakMs || 0));
    }
    return 0;
  }
  if (!attState.punchInTime) return 0;

  const shiftEndMs  = _getShiftEndMs();
  const now         = Date.now();
  /* B/C) Cap the "now" at shift end when shift has ended and session is still open */
  const capAt       = (shiftEndMs > 0 && now > shiftEndMs && attState.status !== 'punchedOut')
                      ? shiftEndMs : now;
  const end         = attState.punchOutTime || capAt;

  let b = attState.totalBreakMs;
  if (attState.status === 'onBreak' && attState.breakStart) b += (now - attState.breakStart);
  return Math.max(0, (end - attState.punchInTime) - b);
}

function getBreakMs() {
  let b = attState.totalBreakMs;
  if (attState.status === 'onBreak' && attState.breakStart) b += (Date.now() - attState.breakStart);
  return b;
}

/* Returns true when the shift has ended and session is still open */
function _isShiftEnded() {
  /* FIX v6: auto_close is also a closed state */
  if (attState.status === 'punchedOut' || attState.status === 'auto_close' || attState.status === 'idle') return false;
  const shiftEndMs = _getShiftEndMs();
  return shiftEndMs > 0 && Date.now() > shiftEndMs;
}

/* Returns true when past shiftEnd + AUTO_CLOSE_GRACE_HOURS (3h) */
function _isPastGrace() {
  const shiftEndMs = _getShiftEndMs();
  return shiftEndMs > 0 && Date.now() > shiftEndMs + 3 * 3600000;
}

function startTimer() { if (attTimer) clearInterval(attTimer); attTimer = setInterval(updateMeters, 1000); }
function stopTimer()  { if (attTimer) { clearInterval(attTimer); attTimer = null; } }

/* ── Progress bar + milestones (tick every second while working) ── */
function updateMeters() {
  /* BUG FIX 6 — Safety net: if the timer is somehow still running for a
     closed session (punchedOut / auto_close), stop it immediately.
     This catches the race condition where initAttendance() started the timer
     from stale localStorage before loadTodaySession() returned from the server. */
  if (attState.status === 'punchedOut' || attState.status === 'auto_close' || attState.status === 'idle') {
    /* FIX v6: auto_close is also a closed state */
    stopTimer();
    /* Still render once to show the final frozen values */
  }

  const workMs  = getWorkMs();
  const breakMs = getBreakMs();

  /* Detect shift-end freeze state */
  const shiftEnded = _isShiftEnded();
  const pastGrace  = _isPastGrace();

  /* Frozen indicator on Work Time meter */
  const mwEl = document.getElementById('meterWorking');
  const mnEl = document.getElementById('meterNet');
  if (shiftEnded && attState.status !== 'punchedOut') {
    mwEl.style.color = pastGrace ? '#ef4444' : '#f59e0b';
    mnEl.style.color = pastGrace ? '#ef4444' : '#f59e0b';
  } else {
    mwEl.style.color = '';
    mnEl.style.color = '';
  }
  mwEl.textContent = fmtMs(workMs);
  document.getElementById('meterBreak').textContent = fmtMs(breakMs);
  mnEl.textContent = fmtMs(workMs);

  /* Shift-end notice inside panel */
  const noticeEl = document.getElementById('attShiftEndNotice');
  if (noticeEl) {
    const show = shiftEnded && attState.status !== 'punchedOut' && attState.status !== 'idle';
    noticeEl.style.display = show ? 'flex' : 'none';
    if (show) {
      const shiftEndMs = _getShiftEndMs();
      const shiftEndStr = new Date(shiftEndMs).toLocaleTimeString('en-IN',
        { hour:'2-digit', minute:'2-digit', hour12:true });
      document.getElementById('attShiftEndNoticeText').textContent =
        pastGrace
          ? `⚠ Your shift ended at ${shiftEndStr} and the auto-close grace period has passed. ` +
            `The system will close this session shortly. Please punch out now.`
          : `Your shift ended at ${shiftEndStr}. Timer is frozen — working hours are capped at ` +
            `your scheduled shift-end. Please punch out to finalise your attendance record.`;
    }
  }

  const shiftMs = SHIFT_HOURS * 3_600_000;
  const pct = Math.min(100, Math.round((workMs / shiftMs) * 100));
  const fill = document.getElementById('progressFill');
  fill.style.width = pct + '%';
  /* Color: blue → amber (75%) → green (full day) → purple (overtime) */
  if      (workMs > FULL_DAY_MS + OT_GRACE_MS) fill.className = 'att-progress-fill overtime-fill';
  else if (workMs >= FULL_DAY_MS)               fill.className = 'att-progress-fill success-fill';
  else if (pct >= 75)                           fill.className = 'att-progress-fill warn-fill';
  else                                          fill.className = 'att-progress-fill';

  document.getElementById('progressPct').textContent = pct + '%';
  document.getElementById('stat-workhours-val').textContent = (workMs / 3_600_000).toFixed(1);

  /* Milestones: half-day | 75% of shift | full-day */
  const ms6ms = FULL_DAY_MS * 0.75;
  const _ms = (id, reached) => {
    const el = document.getElementById(id);
    if (!el) return;
    el.className = 'att-milestone' + (reached ? ' reached' : '');
    el.querySelector('i').className = 'bi bi-' + (reached ? 'check-circle-fill' : 'circle');
  };
  _ms('ms4h', workMs >= HALF_DAY_MS);
  _ms('ms6h', workMs >= ms6ms);
  _ms('ms8h', workMs >= FULL_DAY_MS);

  /* Live badge projection while session open */
  if (attState.status === 'working' || attState.status === 'onBreak') {
    updateDayStatusBadge(computeAttendanceStatus(attState.punchInTime, Date.now() + 1, workMs));
  }
}

/* ── UI helpers ── */
function updateDayStatusBadge(statusKey) {
  /* v6: for auto-close sessions, show the real work-quality status styling
     plus "Auto-Closed" sub-text so staff can see both facts. */
  const isAC = attState.status === 'auto_close'
             || (statusKey === 'auto_close');
  const wqKey = isAC && attState.workQualityStatus
              ? _normaliseAttStatus(attState.workQualityStatus)
              : null;
  const displayKey = (wqKey && wqKey !== 'auto_close') ? wqKey : statusKey;
  const cfg = STATUS_CFG[displayKey] || STATUS_CFG['auto_close'] || STATUS_CFG['pending'];
  const badge = document.getElementById('attDayStatusBadge');
  badge.className = 'att-day-status ' + cfg.css;
  document.getElementById('attDayStatusIcon').className = 'bi bi-' + cfg.icon;
  /* Combined label: "Half Day · Auto-Closed" */
  const baseLabel = cfg.label;
  const acSuffix  = isAC && wqKey && wqKey !== 'auto_close' ? ' · Auto-Closed' : '';
  document.getElementById('attDayStatusText').textContent = baseLabel + acSuffix;
}

function updateFinalStatus(statusKey) {
  /* v6: auto-close sessions show work quality label + auto-close explanation */
  const isAC = attState.status === 'auto_close' || statusKey === 'auto_close';
  const wqKey = isAC && attState.workQualityStatus
              ? _normaliseAttStatus(attState.workQualityStatus)
              : null;
  const displayKey = (wqKey && wqKey !== 'auto_close') ? wqKey : statusKey;
  const cfg = STATUS_CFG[displayKey] || STATUS_CFG['auto_close'] || STATUS_CFG['pending'];
  document.getElementById('attFinalIcon').className = 'att-final-icon ' + cfg.iconCls;
  document.getElementById('attFinalIcon').innerHTML = '<i class="bi bi-' + cfg.icon + '"></i>';
  /* Combined label in the final value element */
  const wqLabel = (wqKey && wqKey !== 'auto_close' && STATUS_CFG[wqKey]) ? STATUS_CFG[wqKey].label : null;
  document.getElementById('attFinalVal').textContent = isAC && wqLabel
    ? wqLabel + ' (Auto-Closed)'
    : cfg.label;
  document.getElementById('attFinalSub').textContent = isAC
    ? 'Session auto-closed — hours counted up to shift end. Contact admin if a correction is needed.'
    : cfg.sub;
}

function setStatus(status) {
  const chip = document.getElementById('attStatusChip');
  const text = document.getElementById('attStatusText');
  const msg  = document.getElementById('attStatusMsg');
  chip.className = 'att-status-chip';
  if (status === 'working') {
    chip.classList.add('chip-working'); text.textContent = 'Working';
    msg.textContent = 'You are currently clocked in. Keep it up!';
  } else if (status === 'onBreak') {
    chip.classList.add('chip-break'); text.textContent = 'On Break';
    msg.textContent = 'Break is being tracked. Resume when ready.';
  } else if (status === 'auto_close' || (status === 'punchedOut' && _normaliseAttStatus(attState.attendanceStatus) === 'auto_close')) {
    /* FIX v6: status column is now 'auto_close' for auto-closed sessions (was 'punchedOut') */
    chip.classList.add('chip-done'); text.textContent = 'Auto Closed';
    msg.textContent = 'This session was automatically closed. Contact your admin if a correction is needed.';
  } else if (status === 'punchedOut') {
    chip.classList.add('chip-done'); text.textContent = 'Shift Complete';
    msg.textContent = 'Great work today! Hours have been recorded.';
  } else {
    chip.classList.add('chip-idle'); text.textContent = 'Not Punched In';
    msg.textContent = 'Start your work day by punching in.';
  }
}

/* ── Late-warning banner ─────────────────────────────────────────────────────
   Night shift: post-midnight punch (00:00 – logoutTime) is ALWAYS on-time.
   Day shift  : punch at or before lateThreshold = on-time.
   Message always shows the live shiftState threshold (never hardcoded).
────────────────────────────────────────────────────────────────────────────── */
function checkLateWarning() {
  if (!attState.punchInTime) return;
  const d       = new Date(attState.punchInTime);
  const piMins  = d.getHours() * 60 + d.getMinutes();
  const lateMin = shiftState.lateH * 60 + shiftState.lateM;
  const warn    = document.getElementById('attLateWarn');
  let isOnTime;

  if (shiftState.nightShift) {
    const logoutMins     = shiftState.logoutH * 60 + shiftState.logoutM;
    const isPostMidnight = logoutMins > 0 ? piMins < logoutMins : false;
    /* Post-midnight = always on-time; pre-midnight = compare vs threshold */
    isOnTime = isPostMidnight ? true : piMins <= lateMin;
  } else {
    isOnTime = piMins <= lateMin;
  }

  if (!isOnTime) {
    warn.classList.add('visible');
    document.getElementById('attLateWarnText').textContent =
      'You checked in at ' +
      d.toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit', hour12: true }) +
      ' — after the ' + _fmt12(shiftState.lateH, shiftState.lateM) +
      ' grace deadline. This session will be marked as a Late Mark.';
  } else {
    warn.classList.remove('visible');
  }
}

/* ── Full UI re-render ── */
function renderAttUI() {
  setStatus(attState.status);
  updateMeters();
  checkLateWarning();

  /* ── Day-status badge ── */
  if (attState.status === 'idle') {
    /* FIX: was 'absent_nc' — correct key is 'no_checkin' */
    updateDayStatusBadge('no_checkin');
  } else if (attState.status === 'punchedOut' || attState.status === 'auto_close') {
    /* FIX v6: handle both 'punchedOut' (normal) and 'auto_close' (auto-closed) */
    const ns = _normaliseAttStatus(attState.attendanceStatus) || 'absent';
    updateDayStatusBadge(ns);
    updateFinalStatus(ns);
    /* BUG FIX 4: show summary for ALL punchedOut sessions (not just auto_close).
       Previously only auto_close triggered showSummary() here, meaning that a
       normal session restored from the server on page refresh never showed the
       work summary panel until another action was taken. */
    showSummary();
  }

  /* ── Button states ── */
  const btnIn  = document.getElementById('btnPunchIn');
  const btnBrk = document.getElementById('btnBreak');
  const btnRes = document.getElementById('btnResume');
  const btnOut = document.getElementById('btnPunchOut');

  /* FIX: was hardcoded >= 2 — use MAX_BREAKS constant */
  const MAX_BREAKS = 2; // mirrors AttendanceDAO.MAX_BREAKS_PER_SHIFT
  const limitHit   = attState.breakCount >= MAX_BREAKS;

  btnIn.disabled  = attState.status !== 'idle';
  /* FIX: break button disabled when shift ended (no more breaks after shift end) */
  btnBrk.disabled = attState.status !== 'working' || limitHit || _isShiftEnded();
  btnRes.disabled = attState.status !== 'onBreak';
  btnOut.disabled = attState.status === 'idle' || attState.status === 'punchedOut' || attState.status === 'auto_close';

  /* Break limit warning */
  const warnEl = document.getElementById('breakLimitWarn');
  if (limitHit && attState.status === 'working') warnEl.classList.add('visible');
  else warnEl.classList.remove('visible');

  /* Update break limit number display */
  const bnEl = document.getElementById('breakLimitNumUsed');
  if (bnEl) bnEl.textContent = MAX_BREAKS;

  /* ── Shift-end top banner (outside panel) ── */
  const shiftEndBanner = document.getElementById('shiftEndBanner');
  if (shiftEndBanner) {
    const showBanner = _isShiftEnded() &&
      (attState.status === 'working' || attState.status === 'onBreak');
    shiftEndBanner.style.display = showBanner ? 'flex' : 'none';
    if (showBanner) {
      const shiftEndMs  = _getShiftEndMs();
      const shiftEndStr = new Date(shiftEndMs).toLocaleTimeString('en-IN',
        { hour:'2-digit', minute:'2-digit', hour12:true });
      const el = document.getElementById('shiftEndBannerTitle');
      if (el) el.textContent = '⏰ Shift Ended at ' + shiftEndStr + ' — Timer Frozen';
    }
  }

  /* ── Activity timeline ── */
  const ul = document.getElementById('attTimeline');
  ul.innerHTML = '';
  if (attState.log.length === 0) {
    ul.innerHTML = '<li class="att-empty-log" id="attEmptyLog"><i class="bi bi-calendar-x"></i>No activity recorded yet. Punch in to start tracking.</li>';
    document.getElementById('logCount').textContent = '';
  } else {
    attState.log.forEach(entry => {
      const li = document.createElement('li');
      li.className = 'att-tl-item';
      li.innerHTML = `<span class="att-tl-dot ${entry.dotClass}"></span>
        <div class="att-tl-body">
          <div class="att-tl-event">${entry.event}</div>
          <div class="att-tl-time">${entry.timeStr}</div>
          ${entry.extraHtml || ''}
        </div>`;
      ul.appendChild(li);
    });
    const cnt = attState.log.length;
    document.getElementById('logCount').textContent = cnt + ' event' + (cnt > 1 ? 's' : '');
  }
}

/* ── Toast notification ── */
function showToast(msg, type) {
  const toast = document.getElementById('toast');
  const inner = document.getElementById('toast-inner');
  const warn  = type === 'warn' || type === 'error';
  const info  = type === 'info';
  let borderColor, iconCls, iconColor;
  if (warn)      { borderColor='var(--danger)';  iconCls='bi-exclamation-triangle-fill'; iconColor='#f87171'; }
  else if (info) { borderColor='var(--accent)';  iconCls='bi-info-circle-fill';          iconColor='#60a5fa'; }
  else           { borderColor='var(--success)'; iconCls='bi-check-circle-fill';         iconColor='#34d399'; }

  inner.style.borderLeftColor = borderColor;
  inner.innerHTML = `<i class="bi ${iconCls}" style="color:${iconColor};flex-shrink:0"></i>
    <span style="flex:1;line-height:1.45">${msg}</span>
    <button onclick="document.getElementById('toast').classList.remove('show')"
            style="margin-left:auto;background:none;border:none;color:rgba(255,255,255,.5);cursor:pointer;font-size:1rem;flex-shrink:0"><i class="bi bi-x"></i></button>`;
  toast.classList.add('show');
  clearTimeout(toast._t);
  /* Longer display for contextual messages (warn/info) */
  toast._t = setTimeout(() => toast.classList.remove('show'), warn ? 6000 : info ? 5000 : 3500);
}

/* ══════════════════════════════════════════════════════════════
   ATTENDANCE ACTIONS
   Every action POSTs to AttendanceServlet.
   Server timestamps and status are ALWAYS authoritative.
══════════════════════════════════════════════════════════════ */
function attAction(action) {

  /* ── PUNCH IN ─────────────────────────────────────────────── */
  if (action === 'punchIn') {
    if (attState.status !== 'idle') return;
    document.getElementById('btnPunchIn').disabled = true;

    fetch('AttendanceServlet?action=punchIn', { method: 'POST' })
      .then(r => r.json())
      .then(data => {
        if (!data.ok && data.session) { restoreSession(data.session); return; }
        if (!data.ok) { showToast('⚠ ' + (data.error || 'Punch-in failed'), 'warn'); return; }

        /* Apply shift FIRST so FULL_DAY_MS / HALF_DAY_MS are correct for
           the very first updateMeters() call inside renderAttUI() */
        if (data.shift) applyShiftToUI(data.shift);

        attState.status           = 'working';
        attState.sessionId        = data.sessionId;
        attState.punchInTime      = data.punchInTime;  // epoch ms from server
        attState.punchOutTime     = null;
        attState.totalBreakMs     = 0;
        attState.netWorkMs        = 0;
        attState.attendanceStatus = 'pending';
        attState.breakCount       = data.breakCount || 0;
        attState.log.push({ event: '🟢 Punched In', dotClass: 'tl-dot-in', timeStr: data.timeStr });

        /* Use server-built contextual toast — explains WHY it's late with shift name */
        const toastMsg = data.toastMsg
          || (data.isLate
              ? '⏰ Late check-in — this session will be marked as a Late Mark.'
              : '✅ Punched in successfully. Have a great shift!');
        showToast(toastMsg, data.isLate ? 'warn' : 'success');
        startTimer();
        saveAtt(); renderAttUI();
      })
      .catch(() => showToast('⚠ Network error — punch-in not saved', 'warn'))
      .finally(() => { document.getElementById('btnPunchIn').disabled = false; });

  /* ── START BREAK ──────────────────────────────────────────── */
  } else if (action === 'startBreak') {
    if (attState.status !== 'working') return;
    fetch('AttendanceServlet?action=startBreak', {
      method: 'POST',
      body: new URLSearchParams({ sessionId: attState.sessionId })
    })
      .then(r => r.json())
      .then(data => {
        if (!data.ok) {
          if (data.breakLimitReached) { attState.breakCount = data.breakCount || 2; saveAtt(); renderAttUI(); }
          showToast('⚠ ' + (data.error || 'Error'), 'warn'); return;
        }
        attState.status     = 'onBreak';
        attState.breakStart = Date.now();   // local: measures this break's duration only
        attState.breakCount = data.breakCount;
        attState.log.push({ event: '☕ Break Started', dotClass: 'tl-dot-break', timeStr: data.timeStr });
        /* Server tells us how many breaks remain */
        showToast(data.toastMsg || '☕ Break started.', 'info');
        saveAtt(); renderAttUI();
      })
      .catch(() => showToast('⚠ Network error — break not saved', 'warn'));

  /* ── RESUME WORK ──────────────────────────────────────────── */
  } else if (action === 'resumeWork') {
    if (attState.status !== 'onBreak') return;
    const breakDurationMs = Date.now() - attState.breakStart;
    fetch('AttendanceServlet?action=resumeWork', {
      method: 'POST',
      body: new URLSearchParams({ sessionId: attState.sessionId, breakDurationMs })
    })
      .then(r => r.json())
      .then(data => {
        if (!data.ok) { showToast('⚠ ' + (data.error || 'Error'), 'warn'); return; }
        /* Server confirmed break — add to local total and clear local breakStart */
        attState.totalBreakMs += breakDurationMs;
        attState.breakStart    = null;
        attState.status        = 'working';
        attState.breakCount    = data.breakCount;
        attState.log.push({
          event: '▶️ Resumed Work', dotClass: 'tl-dot-resume', timeStr: data.timeStr,
          extraHtml: `<div class="att-tl-dur">Break lasted ${fmtMsShort(breakDurationMs)}</div>`
        });
        saveAtt(); renderAttUI();
      })
      .catch(() => showToast('⚠ Network error — resume not saved', 'warn'));

  /* ── PUNCH OUT ────────────────────────────────────────────── */
  } else if (action === 'punchOut') {
    closePunchOutModal();
    if (attState.status === 'idle' || attState.status === 'punchedOut') return;

    /* Commit any in-flight break locally before sending to server */
    let additionalBreakMs = 0;
    if (attState.status === 'onBreak' && attState.breakStart) {
      additionalBreakMs      = Date.now() - attState.breakStart;
      attState.totalBreakMs += additionalBreakMs;
      attState.breakStart    = null;
    }

    fetch('AttendanceServlet?action=punchOut', {
      method: 'POST',
      body: new URLSearchParams({ sessionId: attState.sessionId, additionalBreakMs })
    })
      .then(r => r.json())
      .then(data => {
        if (!data.ok) { showToast('⚠ ' + (data.error || 'Punch-out failed'), 'warn'); return; }

        attState.punchOutTime     = data.punchOutTime;   // epoch ms from server
        attState.status           = 'punchedOut';
        attState.netWorkMs        = data.netWorkMs || 0; // DB-computed value
        attState.totalBreakMs     = (data.totalBreakMs != null) ? data.totalBreakMs : attState.totalBreakMs;
        /* Server attendance_status is canonical (v5 lowercase_snake); client-compute only as fallback */
        const srvStatus = _normaliseAttStatus(data.attendanceStatus);
        attState.attendanceStatus = srvStatus && srvStatus !== 'pending'
          ? srvStatus
          : computeAttendanceStatus(attState.punchInTime, attState.punchOutTime, attState.netWorkMs);
        attState.log.push({
          event: '🔴 Punched Out', dotClass: 'tl-dot-out', timeStr: data.timeStr,
          extraHtml: `<div class="att-tl-dur">Net work: ${fmtMsShort(attState.netWorkMs)}</div>`
        });
        stopTimer();
        /* Hide shift-end banners — session is now closed */
        const seb = document.getElementById('shiftEndBanner');
        if (seb) seb.style.display = 'none';
        saveAtt(); renderAttUI(); updateMeters(); showSummary();
        /* Use server-built contextual status explanation */
        const punchOutMsg = data.toastMsg
          || ('Shift complete! Status: ' + ((STATUS_CFG[_normaliseAttStatus(attState.attendanceStatus)] || {}).label || ''));
        showToast(punchOutMsg, attState.attendanceStatus === 'absent' ? 'warn' : 'success');
      })
      .catch(() => showToast('⚠ Network error — punch-out not saved', 'warn'));
  }
}

/* ── Load today's session from server on page load ───────────────────────────
   NEW-DAY LOGIC:
   1. Server returns status='none'  → today = no session. Show idle. Check if
      yesterday's session is still open (stale) → show staleSessBanner.
   2. Server returns a live session from yesterday (night shift still open) →
      show the session as active with shift-end freeze if applicable.
   3. Server returns status from attendanceStatus='auto_close' → show banner.
   4. Server returns attendanceStatus='no_checkin' → idle state.
────────────────────────────────────────────────────────────────────────────── */
function loadTodaySession() {
  fetch('AttendanceServlet?action=todaySession')
    .then(r => r.json())
    .then(data => {
      /* Apply shift from server FIRST so all thresholds are ready */
      if (data.shift) applyShiftToUI(data.shift);

      /* Show auto-close advisory if previous session was system-closed */
      if (data.prevAutoClose) showAutoCloseBanner();

      /* No session at all */
      if (data.status === 'none' || data.attendanceStatus === 'no_checkin') {
        attState.status = 'idle';
        attState.attendanceStatus = 'no_checkin';

        /* Check for stale open session from yesterday (server sends prevOpenSession) */
        if (data.prevOpenSession) {
          const sub = document.getElementById('staleSessBannerSub');
          if (sub) sub.textContent =
            'A session started on ' + (data.prevOpenSession.sessionDate || 'a previous date') +
            ' is still open. The system will auto-close it within 3 hours of your shift end. ' +
            'Contact your administrator if an immediate correction is needed.';
          const banner = document.getElementById('staleSessBanner');
          if (banner) banner.style.display = 'flex';
        }

        saveAtt();
        renderAttUI();
        return;
      }

      restoreSession(data);
    })
    .catch(() => {
      /* Network error — restore from localStorage if available */
      loadAtt();
      renderAttUI();
      if (attState.status === 'working' || attState.status === 'onBreak') startTimer();
    });
}

function showAutoCloseBanner() {
  const banner = document.getElementById('autoCloseBanner');
  if (banner) banner.style.display = 'flex';
}

/* ── Restore all attState fields from a server session object ────────────────
   Called by loadTodaySession and by punchIn (when "already punched in").
   Applies shift FIRST so all thresholds are correct before any render.
────────────────────────────────────────────────────────────────────────────── */
function restoreSession(data) {
  /* Shift must be applied before anything else writes to FULL_DAY_MS */
  if (data.shift) applyShiftToUI(data.shift);

  attState.sessionId        = data.sessionId;
  attState.status           = data.status;
  attState.punchInTime      = data.punchInTime  || null;
  /* Server sends 0 when no punch-out yet — normalise to null */
  attState.punchOutTime     = (data.punchOutTime && data.punchOutTime > 0) ? data.punchOutTime : null;
  attState.totalBreakMs     = data.totalBreakMs || 0;
  attState.netWorkMs        = data.netWorkMs    || 0;
  attState.attendanceStatus = _normaliseAttStatus(data.attendanceStatus) || 'pending';
  attState.breakCount       = data.breakCount   || 0;
  /* v6: store work quality fields for combined "Auto-Closed (Half Day)" display */
  if(data.workQualityStatus) attState.workQualityStatus = data.workQualityStatus;
  if(data.workQualityLabel)  attState.workQualityLabel  = data.workQualityLabel;
  attState.isAutoClose = !!data.isAutoClose;
  attState.log = (data.log || []).map(e => ({
    event: e.event, dotClass: e.dotClass, timeStr: e.timeStr, extraHtml: e.extraHtml || ''
  }));

  /* BUG FIX 1B: always stop the timer when restoring a closed session.
     This corrects the race condition where initAttendance() started the timer
     from stale localStorage before the server response arrived. */
  if (attState.status === 'working' || attState.status === 'onBreak') {
    startTimer();
  } else {
    stopTimer();   // covers punchedOut, auto_close, idle
  }
  saveAtt(); renderAttUI();
  if (attState.status === 'punchedOut') showSummary();
}

/* ── applyShiftToUI ──────────────────────────────────────────────────────────
   Accepts the shift JSON object returned by the servlet:
     { loginTime:"HH:mm", logoutTime:"HH:mm",
       graceMinutes:N, shiftName:"...", earlyGraceMinutes:N }
   Calls _seedShift() to update all globals, then updates every DOM element
   that shows shift-specific values (chips, labels, milestones).
────────────────────────────────────────────────────────────────────────────── */
function applyShiftToUI(shift) {
  if (!shift) return;

  const [lh, lm]   = (shift.loginTime  || '09:00').split(':').map(Number);
  const [loh, lom] = (shift.logoutTime || '18:00').split(':').map(Number);
  const grace      = shift.graceMinutes || 60;

  /* Re-seed globals with real server values */
  _seedShift(lh, lm, loh, lom, grace, shift.shiftName || '—');

  const loginFmt  = _fmt12(lh, lm);
  const logoutFmt = _fmt12(loh, lom);
  const lateFmt   = _fmt12(shiftState.lateH, shiftState.lateM);
  const fullH     = _fmtH(SHIFT_HOURS);
  const halfH     = _fmtH(HALF_DAY_MS / 3_600_000);
  const threeQH   = _fmtH((FULL_DAY_MS * 0.75) / 3_600_000);

  const safe = (id, v) => { const el = document.getElementById(id); if (el) el.textContent = v; };
  safe('chipShiftName', shift.shiftName || '—');
  safe('chipLogin',     loginFmt);
  safe('chipLate',      lateFmt);
  safe('chipLogout',    logoutFmt);
  safe('chipFullDay',   '≥ ' + fullH);
  safe('chipHalfDay',   halfH + ' – ' + fullH);
  safe('attHeaderSub',
    'Office: ' + loginFmt + ' | Late after: ' + lateFmt +
    ' | Full day: ' + fullH + ' | Out: ' + logoutFmt);
  safe('attHistSub',
    'Your daily attendance — Shift: ' + (shift.shiftName || '') +
    ' (' + loginFmt + '–' + logoutFmt + ')');
  safe('progressLabel', 'Shift Target: ' + fullH);

  const progSub = document.getElementById('progressSubLabel');
  if (progSub) progSub.textContent = '(' + halfH + ' = Half Day | ' + fullH + ' = Full Day)';

  /* Milestone chip labels */
  const _mlabel = (id, text) => {
    const el = document.getElementById(id);
    if (!el) return;
    const sp = el.querySelector('span');
    if (sp) sp.textContent = ' ' + text;
  };
  _mlabel('ms4h', halfH   + ' — Half Day');
  _mlabel('ms6h', threeQH + ' — Good Progress');
  _mlabel('ms8h', fullH   + ' — Full Day ✓');
}

function showSummary() {
  /* BUG FIX 3 — Auto-close sessions: show working hours in summary.
     Auto-closed sessions have netWorkMs set by the server but punchOutTime
     may be 0 if the servlet sends punchOutTime:0 for some edge cases.
     FIX: allow showSummary() to proceed if either punchOutTime OR netWorkMs
     is available, so auto-closed sessions always show their hours. */
  const hasPunchOut = attState.punchOutTime && attState.punchOutTime > 0;
  const hasNetWork  = attState.netWorkMs > 0;
  if (!hasPunchOut && !hasNetWork) return;

  /* Use DB-computed netWorkMs; fall back only if it's genuinely missing */
  const workMs  = attState.netWorkMs > 0
    ? attState.netWorkMs
    : Math.max(0, (attState.punchOutTime - attState.punchInTime) - attState.totalBreakMs);
  const totalMs = hasPunchOut
    ? (attState.punchOutTime - attState.punchInTime)
    : workMs + (attState.totalBreakMs || 0);
  const breakMs = attState.totalBreakMs;

  document.getElementById('sumTotal').textContent  = fmtMsShort(totalMs);
  document.getElementById('sumWork').textContent   = fmtMsShort(workMs);
  document.getElementById('sumBreak').textContent  = fmtMsShort(breakMs);

  /* v6: for auto-close sessions prefer workQualityStatus for the summary display */
  let finalStatus = _normaliseAttStatus(attState.attendanceStatus) ||
    computeAttendanceStatus(attState.punchInTime, attState.punchOutTime, workMs);
  if((attState.status === 'auto_close' || finalStatus === 'auto_close') && attState.workQualityStatus){
    const wqn = _normaliseAttStatus(attState.workQualityStatus);
    if(wqn && wqn !== 'auto_close') finalStatus = wqn;
  }
  updateDayStatusBadge(finalStatus);
  updateFinalStatus(finalStatus);

  /* Overtime / short-fall badge */
  const diff = workMs - FULL_DAY_MS;
  if (finalStatus === 'overtime' || finalStatus === 'late_overtime') {
    document.getElementById('sumOtBadge').innerHTML =
      `<span class="att-overtime-badge ot-good"><i class="bi bi-star-fill"></i> Overtime: +${fmtMsShort(diff)}</span>`;
  } else if (diff >= 0) {
    document.getElementById('sumOtBadge').innerHTML =
      `<span class="att-overtime-badge ot-good"><i class="bi bi-check-circle-fill"></i> Exactly ${_fmtH(SHIFT_HOURS)} — Full Day</span>`;
  } else if (finalStatus === 'half_day' || finalStatus === 'late_half') {
    document.getElementById('sumOtBadge').innerHTML =
      `<span class="att-overtime-badge"><i class="bi bi-adjust"></i> Half-day recorded. Short by ${fmtMsShort(Math.abs(diff))} for full day.</span>`;
  } else if (finalStatus === 'absent') {
    document.getElementById('sumOtBadge').innerHTML =
      `<span class="att-overtime-badge" style="background:rgba(239,68,68,.1);color:#dc2626"><i class="bi bi-x-circle-fill"></i> Less than half-day worked. Marked Absent.</span>`;
  } else {
    document.getElementById('sumOtBadge').innerHTML =
      `<span class="att-overtime-badge"><i class="bi bi-exclamation-circle-fill"></i> Short by: ${fmtMsShort(Math.abs(diff))}</span>`;
  }

  document.getElementById('attSummary').classList.add('visible');
}

/* ══════════════════════════════════════════════════════════════
   ATTENDANCE HISTORY — loads past 30 days from server
   Status rules mirror Java AttendanceStatusUtil exactly.
══════════════════════════════════════════════════════════════ */
let historyData = [];       // raw records from server / demo
let calViewDate = new Date(); // the month currently shown in calendar

const HIST_STATUS_CFG = {
  full_day:      {cls:'hdp-full',       calCls:'cal-full',     icon:'check-circle-fill',        label:'Present (Full Day)',    color:'#059669'},
  overtime:      {cls:'hdp-overtime',   calCls:'cal-overtime', icon:'star-fill',                label:'Present (Overtime)',    color:'#7c3aed'},
  half_day:      {cls:'hdp-half',       calCls:'cal-half',     icon:'adjust',                   label:'Half Day',              color:'#0891b2'},
  absent:        {cls:'hdp-absent',     calCls:'cal-absent',   icon:'x-circle-fill',            label:'Absent',                color:'#dc2626'},
  late:          {cls:'hdp-late',       calCls:'cal-late',     icon:'clock-history',            label:'Late Mark',             color:'#d97706'},
  late_half:     {cls:'hdp-latehalf',   calCls:'cal-late',     icon:'exclamation-circle-fill',  label:'Late (Half Day)',       color:'#c2410c'},
  late_overtime: {cls:'hdp-latehalf',   calCls:'cal-overtime', icon:'exclamation-diamond-fill', label:'Late (Overtime)',       color:'#9333ea'},
  pending:       {cls:'hdp-pending',    calCls:'cal-empty',    icon:'hourglass-split',          label:'In Progress',           color:'#94a3b8'},
  auto_close:    {cls:'hdp-absent',     calCls:'cal-absent',   icon:'shield-exclamation',       label:'Auto-Closed',           color:'#b45309'}
};

function fmtMsHist(ms){
  if(!ms||ms<0) return '—';
  const h=Math.floor(ms/3600000), m=Math.floor((ms%3600000)/60000);
  return h+'h '+String(m).padStart(2,'0')+'m';
}

/**
 * BUG FIX — normalise any date string to ISO yyyy-MM-dd.
 *
 * The servlet's historyToJson() formats sessionDate with DATE_FMT = "dd-MMM-yyyy"
 * (e.g. "13-May-2026"), but renderCalendar() and isToday checks expect "2026-05-13".
 * This function converts both formats safely so all comparisons work.
 *
 * Supported input formats:
 *   "2026-05-13"   → already ISO, returned as-is
 *   "13-May-2026"  → converted to "2026-05-13"
 *   "13-May-26"    → converted to "2026-05-13"
 */
const MONTH_MAP = {
  jan:'01',feb:'02',mar:'03',apr:'04',may:'05',jun:'06',
  jul:'07',aug:'08',sep:'09',oct:'10',nov:'11',dec:'12'
};
function toIsoDate(dateStr){
  if(!dateStr) return null;
  dateStr = String(dateStr).trim();
  // Already ISO: yyyy-MM-dd
  if(/^\d{4}-\d{2}-\d{2}$/.test(dateStr)) return dateStr;
  // dd-MMM-yyyy  or  dd-MMM-yy
  const parts = dateStr.split('-');
  if(parts.length === 3){
    const day   = parts[0].padStart(2,'0');
    const mon   = MONTH_MAP[parts[1].toLowerCase().slice(0,3)] || '01';
    let   year  = parts[2].length === 2 ? '20' + parts[2] : parts[2];
    return `${year}-${mon}-${day}`;
  }
  // Fallback — let the browser try
  const d = new Date(dateStr);
  if(!isNaN(d)) return d.toISOString().slice(0,10);
  return null;
}

function fmtDateStr(rawDate){
  const iso = toIsoDate(rawDate);
  if(!iso) return 'N/A';
  const d = new Date(iso + 'T00:00:00');
  if(isNaN(d)) return rawDate; // last resort: show as-is
  return d.toLocaleDateString('en-IN',{day:'2-digit',month:'short',year:'numeric'});
}
function fmtDayStr(rawDate){
  const iso = toIsoDate(rawDate);
  if(!iso) return '';
  const d = new Date(iso + 'T00:00:00');
  if(isNaN(d)) return '';
  return d.toLocaleDateString('en-IN',{weekday:'long'});
}

/* Compute status client-side if server didn't supply it.
   Uses shift-aware FULL_DAY_MS / HALF_DAY_MS — not hardcoded 8h/4h. */
function computeHistStatus(rec){
  /* v6: workQualityStatus is the authoritative payroll quality sent from server.
     Use it first — it's pre-computed server-side with full shift-awareness. */
  if(rec.workQualityStatus){
    const wqNorm = _normaliseAttStatus(rec.workQualityStatus);
    if(wqNorm && wqNorm !== 'auto_close' && wqNorm !== 'pending') return wqNorm;
  }
  const raw = rec.attendanceStatus;
  if(raw){
    const norm = _normaliseAttStatus(raw);
    if(norm !== 'pending' && norm !== 'auto_close') return norm;
    /* Old DB row: attendanceStatus='auto_close' — compute from hours */
    if(norm === 'auto_close' && rec.netWorkMs > 0) {
      const piMs = typeof rec.punchInTime  === 'number' ? rec.punchInTime  : null;
      const poMs = typeof rec.punchOutTime === 'number' ? rec.punchOutTime : null;
      if(piMs && poMs) return computeAttendanceStatus(piMs, poMs, rec.netWorkMs);
    }
    if(norm === 'auto_close') return 'absent';
  }
  const piMs = typeof rec.punchInTime  === 'number' ? rec.punchInTime  : null;
  const poMs = typeof rec.punchOutTime === 'number' ? rec.punchOutTime : null;
  if(!piMs) return 'absent';
  if(!poMs) return 'pending';
  const net=rec.netWorkMs||Math.max(0,(poMs-piMs)-(rec.totalBreakMs||0));
  return computeAttendanceStatus(piMs, poMs, net);
}

/* ── Load from server (falls back to demo data) ── */
function loadHistory(){
  fetch('AttendanceServlet?action=history&days=30')
    .then(r=>r.json())
    .then(data=>{ historyData=data; renderHistory(); })
    .catch(()=>{ historyData=buildDemoHistory(); renderHistory(); });
}

/* ── Render history table ── */
function renderHistory(){
  const tbody=document.getElementById('histTableBody');
  if(!historyData||historyData.length===0){
    tbody.innerHTML=`<tr><td colspan="8"><div class="att-hist-empty"><i class="bi bi-calendar-x"></i>No attendance records found for the last 30 days.</div></td></tr>`;
    renderHistSummary([]);
    return;
  }

  const today=new Date().toISOString().slice(0,10);
  let html='';
  historyData.forEach(function(rec){
    // ── BUG FIX: normalise sessionDate to ISO so comparisons work ──
    const isoDate = toIsoDate(rec.sessionDate);
    const status=computeHistStatus(rec);
    const cfg=HIST_STATUS_CFG[status]||HIST_STATUS_CFG['pending'];
    const netMs=rec.netWorkMs||0, breakMs=rec.totalBreakMs||0;
    const pct=Math.min(100,Math.round((netMs/FULL_DAY_MS)*100));
    const isToday=(isoDate===today);  // ← fixed: compare ISO to ISO
    const lateBadge=(rec.isLate&&status!=='absent'&&status!=='pending')
      ? '<span style="font-size:.58rem;font-weight:700;padding:1px 5px;border-radius:3px;background:rgba(245,158,11,.15);color:#d97706;border:1px solid rgba(245,158,11,.3);margin-left:3px">LATE</span>' : '';
    /* FIX v6: auto-close secondary pill — shows both work quality + closure reason */
    /* v6 combined label: "Auto-Closed (Half Day)" / "Auto-Closed (Full Day)" etc. */
    const wqStatus = rec.workQualityStatus ? _normaliseAttStatus(rec.workQualityStatus) : null;
    const wqLabel  = rec.workQualityLabel
                   || (wqStatus && HIST_STATUS_CFG[wqStatus] ? HIST_STATUS_CFG[wqStatus].label : null);
    const autoCloseBadge = rec.isAutoClose
      ? (wqLabel && wqStatus !== 'auto_close'
          ? `<span style="font-size:.6rem;font-weight:700;padding:2px 7px;border-radius:3px;background:rgba(180,83,9,.1);color:#b45309;border:1px dashed rgba(180,83,9,.35);margin-left:4px;white-space:nowrap"><i class="bi bi-shield-exclamation" style="font-size:.55rem"></i> Auto-Closed (${wqLabel})</span>`
          : '<span style="font-size:.6rem;font-weight:700;padding:2px 7px;border-radius:3px;background:rgba(180,83,9,.1);color:#b45309;border:1px dashed rgba(180,83,9,.35);margin-left:4px"><i class="bi bi-shield-exclamation" style="font-size:.55rem"></i> Auto-Closed</span>')
      : '';
    html+=`<tr${isToday?' style="background:rgba(59,130,246,.04);font-weight:600"':''}>
      <td class="mono" style="font-weight:${isToday?700:400};color:${isToday?'var(--accent)':'var(--text-mid)'}">
        ${fmtDateStr(rec.sessionDate)}${isToday?' <span style="font-size:.6rem;background:var(--accent);color:#fff;border-radius:4px;padding:1px 5px;margin-left:3px">TODAY</span>':''}
      </td>
      <td style="font-size:.8rem;color:var(--text-muted)">${fmtDayStr(rec.sessionDate)}</td>
      <td>
        <span class="hist-day-pill ${cfg.cls}">
          <i class="bi bi-${cfg.icon}"></i> ${cfg.label}
        </span>${lateBadge}${autoCloseBadge}
      </td>
      <td class="mono">${rec.punchInStr||'—'}</td>
      <td class="mono">${rec.punchOutStr||'—'}</td>
      <td>
        <div class="hist-bar-wrap">
          <div class="hist-bar-track"><div class="hist-bar-fill" style="width:${pct}%;background:${cfg.color}"></div></div>
          <div class="hist-bar-lbl">${fmtMsHist(netMs)}</div>
        </div>
      </td>
      <td class="mono" style="color:var(--warning)">${fmtMsHist(breakMs)}</td>
      <td class="mono" style="font-weight:700;color:${cfg.color}">${netMs>0?(netMs/3600000).toFixed(1)+' hrs':'—'}</td>
    </tr>`;
  });
  tbody.innerHTML=html;
  renderHistSummary(historyData);
  renderCalendar();
}

/* ── Summary card counts ── */
function renderHistSummary(records){
  let full=0,half=0,late=0,absent=0,ot=0,totalMs=0;
  records.forEach(r=>{
    const s=computeHistStatus(r);
    /* overtime and late_overtime both count as full-day present */
    if(s==='full_day')                         full++;
    else if(s==='overtime'||s==='late_overtime'){ full++; ot++; }
    else if(s==='half_day')                    half++;
    else if(s==='late'||s==='late_half')       late++;
    else if(s==='absent'||s==='auto_close')    absent++;
    const ms = Number(r.netWorkMs)||0;
    totalMs += isNaN(ms) ? 0 : ms;
  });
  document.getElementById('hsFull').textContent   = full;
  document.getElementById('hsHalf').textContent   = half;
  document.getElementById('hsLate').textContent   = late;
  document.getElementById('hsAbsent').textContent = absent;
  document.getElementById('hsHours').textContent  = (totalMs/3600000).toFixed(1)+'h';
}

/* ── Calendar view ── */
function renderCalendar(){
  const grid=document.getElementById('calGrid');
  const y=calViewDate.getFullYear(), m=calViewDate.getMonth();
  document.getElementById('calMonthLabel').textContent=
    calViewDate.toLocaleDateString('en-IN',{month:'long',year:'numeric'});

  /* Build a lookup: ISO date-string → status
     BUG FIX: servlet returns sessionDate as "dd-MMM-yyyy"; we must normalise
     every key to "yyyy-MM-dd" so it matches the dateStr built in the loop below. */
  const map={};
  (historyData||[]).forEach(r=>{
    const iso = toIsoDate(r.sessionDate);
    if(iso) map[iso] = computeHistStatus(r);
  });

  const today=new Date().toISOString().slice(0,10);
  const firstDay=new Date(y,m,1).getDay(); // 0=Sun
  const daysInMonth=new Date(y,m+1,0).getDate();

  const DAY_HEADERS=['Su','Mo','Tu','We','Th','Fr','Sa'];
  let html=DAY_HEADERS.map(d=>`<div class="att-cal-header">${d}</div>`).join('');

  /* Empty cells before first day */
  for(let i=0;i<firstDay;i++) html+=`<div></div>`;

  for(let d=1;d<=daysInMonth;d++){
    const dateStr=`${y}-${String(m+1).padStart(2,'0')}-${String(d).padStart(2,'0')}`;
    const status=map[dateStr];
    const cfg=status?HIST_STATUS_CFG[status]:null;
    const calCls=cfg?cfg.calCls:'cal-empty';
    const isToday=(dateStr===today);
    const ttip=cfg?cfg.label:'No data';
    html+=`<div class="att-cal-day ${calCls}${isToday?' cal-today':''}" title="${dateStr}: ${ttip}">${d}</div>`;
  }
  grid.innerHTML=html;
}

function calPrev(){
  calViewDate=new Date(calViewDate.getFullYear(),calViewDate.getMonth()-1,1);
  renderCalendar();
}
function calNext(){
  calViewDate=new Date(calViewDate.getFullYear(),calViewDate.getMonth()+1,1);
  renderCalendar();
}

/* ── Tab switch ── */
function switchHistTab(tab){
  document.getElementById('histTableView').style.display   = tab==='table'    ? '' : 'none';
  document.getElementById('histCalendarView').style.display= tab==='calendar' ? '' : 'none';
  document.getElementById('tabTable').classList.toggle('active',    tab==='table');
  document.getElementById('tabCalendar').classList.toggle('active', tab==='calendar');
  if(tab==='calendar') renderCalendar();
}

/* ── Demo history (fallback while servlet is wired up) ── */
function buildDemoHistory(){
  const records=[];
  const today=new Date();
  const statusPool=['full_day','full_day','full_day','half_day','late','late_half','absent','full_day','full_day'];
  for(let i=29;i>=0;i--){
    const d=new Date(today);
    d.setDate(d.getDate()-i);
    const dow=d.getDay();
    if(dow===0||dow===6) continue; // skip weekends
    const dateStr=d.toISOString().slice(0,10);
    const status=statusPool[Math.floor(Math.random()*statusPool.length)];
    const isLate=(status==='late'||status==='late_half');
    const punchInH=isLate?11:9, punchInM=isLate?30+Math.floor(Math.random()*30):Math.floor(Math.random()*30);
    const netHrs=(status==='full_day'||status==='late')?8+(Math.random()*0.5):(status==='half_day'||status==='late_half')?4+(Math.random()):(Math.random()*3.5);
    const netMs=Math.floor(netHrs*3600000);
    const breakMs=Math.floor((Math.random()*30+15)*60000);
    const punchInDate=new Date(d);
    punchInDate.setHours(punchInH,punchInM,0,0);
    const punchOutDate=new Date(punchInDate.getTime()+netMs+breakMs);
    records.push({
      sessionDate:dateStr,
      attendanceStatus:status,
      isLate:isLate,
      punchInTime:punchInDate.getTime(),
      punchOutTime:status==='absent'?null:punchOutDate.getTime(),
      punchInStr:status==='absent'?null:punchInDate.toLocaleTimeString('en-IN',{hour:'2-digit',minute:'2-digit',hour12:true}),
      punchOutStr:status==='absent'?null:punchOutDate.toLocaleTimeString('en-IN',{hour:'2-digit',minute:'2-digit',hour12:true}),
      netWorkMs:status==='absent'?0:netMs,
      totalBreakMs:status==='absent'?0:breakMs
    });
  }
  return records;
}

/* Load history on page start */
window.addEventListener('DOMContentLoaded',function(){
  setTimeout(loadHistory, 300); // slight delay so today's session loads first
});

function confirmPunchOut(){
  // Show live status preview in modal
  const workMs=getWorkMs();
  const preview=computeAttendanceStatus(attState.punchInTime,Date.now()+1,workMs);
  const cfg=STATUS_CFG[preview]||STATUS_CFG['pending'];
  document.getElementById('punchOutStatusPreview').innerHTML=
    `<span style="color:${cfg.color}"><i class="bi bi-${cfg.icon}" style="margin-right:4px"></i>${cfg.label}</span>
     <div style="font-size:.72rem;color:var(--text-muted);margin-top:3px">${cfg.sub}</div>`;
  document.getElementById('punchOutModal').style.display='flex';
}
function closePunchOutModal(){ document.getElementById('punchOutModal').style.display='none'; }
</script>
<%!
  private String getGreeting() {
    int hour = java.util.Calendar.getInstance().get(java.util.Calendar.HOUR_OF_DAY);
    if (hour < 12) return "Morning";
    else if (hour < 17) return "Afternoon";
    else return "Evening";
  }
%>
</body>
</html>
