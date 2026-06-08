<%@ page contentType="text/html; charset=UTF-8" isELIgnored="true" %>
<%@ page import="com.util.*, com.util.LeaveType, com.util.LeaveRequest, java.util.*, java.text.SimpleDateFormat" %>
<%
    HttpSession s = request.getSession(false);
    if (s == null || s.getAttribute("user") == null) {
        response.sendRedirect("index.jsp"); return;
    }
    User user     = (User) s.getAttribute("user");
    String uname  = user.getUsername();
    String role   = (String) s.getAttribute("role");

    List<LeaveType>    leaveTypes   = (List<LeaveType>)    request.getAttribute("leaveTypes");
    List<LeaveRequest> leaveHistory = (List<LeaveRequest>) request.getAttribute("leaveHistory");
    if (leaveTypes   == null) leaveTypes   = new ArrayList<>();
    if (leaveHistory == null) leaveHistory = new ArrayList<>();

    String formError    = (String) request.getAttribute("formError");
    String flashSuccess = (String) s.getAttribute("leaveSuccess");
    String flashError   = (String) s.getAttribute("leaveError");
    if (flashSuccess != null) s.removeAttribute("leaveSuccess");
    if (flashError   != null) s.removeAttribute("leaveError");

    String initials = (uname != null && uname.length() >= 2) ? uname.substring(0,2).toUpperCase() : "EM";
    String today    = new SimpleDateFormat("yyyy-MM-dd").format(new Date());
    String today90  = new SimpleDateFormat("yyyy-MM-dd").format(
                           new java.util.Date(System.currentTimeMillis() + 90L*86400_000));

    // Pending count
    long pendingCount = leaveHistory.stream()
        .filter(r -> "pending".equalsIgnoreCase(r.getStatus())).count();
    long approvedCount = leaveHistory.stream()
        .filter(r -> "approved".equalsIgnoreCase(r.getStatus())).count();
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
<title>Leave Request — SmartStock</title>
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
<link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
<style>
/* ═══════════════════════════════════════════════════════
   TOKENS
═══════════════════════════════════════════════════════ */
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

/* ─── RESET ─────────────────────────────────────────── */
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
html{font-size:16px;scroll-behavior:smooth}
body{font-family:'Outfit',sans-serif;background:var(--bg);color:var(--text);
     padding-top:var(--nav-h);min-height:100vh;-webkit-font-smoothing:antialiased;
     padding-bottom:80px}
@media(min-width:768px){body{padding-bottom:0}}
a{text-decoration:none;color:inherit}
img{display:block;max-width:100%}
input,select,textarea,button{font-family:inherit}

/* ─── NAVBAR ─────────────────────────────────────────── */
.navbar{position:fixed;top:0;left:0;right:0;height:var(--nav-h);z-index:1000;
        background:linear-gradient(135deg,var(--primary) 0%,var(--primary-mid) 100%);display:flex;align-items:center;padding:0 1.1rem;gap:.75rem;
        box-shadow:0 2px 20px rgba(67,56,202,.25)}
.nav-brand{font-size:1.05rem;font-weight:800;color:#fff;display:flex;align-items:center;gap:.4rem}
.nav-brand .dot{color:#fbbf24}
.nav-right{margin-left:auto;display:flex;align-items:center;gap:.5rem}
.nav-avatar{width:32px;height:32px;border-radius:50%;
            background:linear-gradient(135deg,#fbbf24,#f97316);
            display:flex;align-items:center;justify-content:center;
            font-size:.72rem;font-weight:700;color:#fff;border:2px solid rgba(255,255,255,.35);box-shadow:0 2px 8px rgba(0,0,0,.15)}
.nav-back{display:flex;align-items:center;gap:.4rem;color:rgba(255,255,255,.75);
          font-size:.82rem;font-weight:500;padding:.35rem .75rem;border-radius:var(--r-sm);
          background:rgba(255,255,255,.08);border:1px solid rgba(255,255,255,.12);
          transition:all .2s;cursor:pointer}
.nav-back:hover{background:rgba(255,255,255,.2);border-color:rgba(255,255,255,.4);color:#fbbf24}
.nav-back i{font-size:.9rem}

/* ─── LAYOUT ─────────────────────────────────────────── */
.page{max-width:960px;margin:0 auto;padding:1.25rem 1rem}
@media(min-width:768px){.page{padding:2rem 1.5rem}}

/* ─── PAGE HEADER ─────────────────────────────────────── */
.page-head{margin-bottom:1.5rem}
.page-head h1{font-size:1.5rem;font-weight:800;color:var(--text);letter-spacing:-.3px;line-height:1.2}
@media(min-width:640px){.page-head h1{font-size:1.75rem}}
.page-head p{color:var(--text-m);font-size:.875rem;margin-top:.3rem}

/* ─── FLASH BANNERS ──────────────────────────────────── */
.flash{display:flex;align-items:flex-start;gap:.75rem;padding:.875rem 1rem;
       border-radius:var(--r);margin-bottom:1.25rem;font-size:.875rem;font-weight:500;
       animation:slideDown .3s ease}
@keyframes slideDown{from{opacity:0;transform:translateY(-8px)}to{opacity:1;transform:none}}
.flash.success{background:var(--green-bg);color:#065f46;border:1px solid #6ee7b7}
.flash.error  {background:var(--red-bg);color:#7f1d1d;border:1px solid #fca5a5}
.flash i{font-size:1rem;flex-shrink:0;margin-top:.05rem}
.flash-close{margin-left:auto;cursor:pointer;opacity:.6;font-size:1rem;flex-shrink:0;background:none;border:none;color:inherit}
.flash-close:hover{opacity:1}

/* ─── BALANCE STRIP ──────────────────────────────────── */
.balance-grid{display:grid;grid-template-columns:repeat(2,1fr);gap:.75rem;margin-bottom:1.5rem}
@media(min-width:600px){.balance-grid{grid-template-columns:repeat(3,1fr)}}
@media(min-width:900px){.balance-grid{grid-template-columns:repeat(6,1fr)}}
.bal-card{background:var(--card);box-shadow:var(--shadow);border-radius:var(--r);padding:.85rem .9rem;
          border:1px solid var(--border);box-shadow:var(--shadow);position:relative;overflow:hidden}
.bal-card::before{content:'';position:absolute;top:0;left:0;right:0;height:3px;border-radius:var(--r) var(--r) 0 0;background:var(--c,var(--accent))}
.bal-label{font-size:.65rem;font-weight:700;letter-spacing:.8px;text-transform:uppercase;
           color:var(--text-sm);margin-bottom:.4rem}
.bal-val{font-size:1.5rem;font-weight:800;color:var(--text);line-height:1}
.bal-sub{font-size:.72rem;color:var(--text-muted);margin-top:.2rem}

/* ─── TWO-COL LAYOUT ─────────────────────────────────── */
.two-col{display:grid;gap:1.25rem}
@media(min-width:768px){.two-col{grid-template-columns:1fr 1fr}}

/* ─── CARD ───────────────────────────────────────────── */
.card{background:var(--bg-card,#fff);border-radius:var(--r);border:1px solid var(--border);
      box-shadow:var(--shadow);overflow:hidden}
.card-head{padding:1.1rem 1.25rem .85rem;border-bottom:1px solid var(--border);
           display:flex;align-items:center;gap:.6rem}
.card-head h2{font-size:1rem;font-weight:700;color:var(--text)}
.card-head .icon{width:32px;height:32px;border-radius:var(--r-sm);
                 background:var(--accent-bg);color:var(--accent);
                 display:flex;align-items:center;justify-content:center;font-size:.95rem;flex-shrink:0}
.card-body{padding:1.25rem}

/* ─── FORM ELEMENTS ──────────────────────────────────── */
.form-group{margin-bottom:1.1rem}
.form-label{display:flex;align-items:center;gap:.35rem;font-size:.8rem;font-weight:600;
            color:var(--text-m);margin-bottom:.4rem;letter-spacing:.1px}
.form-label .req{color:var(--red);font-size:.85rem}
.form-label .info-tip{color:var(--text-muted);font-size:.75rem;cursor:help}
.form-control{width:100%;padding:.625rem .875rem;border-radius:var(--r-sm);
              border:1.5px solid var(--border);background:var(--card);color:var(--text);
              font-size:.875rem;font-weight:500;transition:border-color .2s,box-shadow .2s;
              appearance:none;-webkit-appearance:none}
.form-control:focus{outline:none;border-color:var(--accent);
                    box-shadow:0 0 0 3px rgba(99,102,241,.18)}
.form-control:disabled{background:var(--bg);color:var(--text-muted);cursor:not-allowed}
select.form-control{background-image:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 24 24' fill='none' stroke='%2394a3b8' stroke-width='2.5'%3E%3Cpath d='M6 9l6 6 6-6'/%3E%3C/svg%3E");
                    background-repeat:no-repeat;background-position:right .75rem center;padding-right:2rem}
textarea.form-control{resize:vertical;min-height:80px;line-height:1.5}
.form-hint{font-size:.72rem;color:var(--text-muted);margin-top:.3rem;display:flex;gap:.3rem;align-items:flex-start}
.form-hint i{flex-shrink:0;margin-top:.1rem}

/* Date row */
.date-row{display:grid;grid-template-columns:1fr 1fr;gap:.75rem}

/* Session type pills */
.session-pills{display:flex;gap:.5rem;flex-wrap:wrap;margin-top:.1rem}
.session-pill{flex:1;min-width:90px}
.session-pill input[type=radio]{display:none}
.session-pill label{display:flex;flex-direction:column;align-items:center;gap:.2rem;
                    padding:.5rem .4rem;border-radius:var(--r-sm);border:1.5px solid var(--border);
                    cursor:pointer;font-size:.72rem;font-weight:600;color:var(--text-m);
                    transition:all .2s;text-align:center;background:var(--card)}
.session-pill label i{font-size:1.1rem}
.session-pill input:checked + label{border-color:var(--accent);background:var(--accent-light);color:var(--accent);font-weight:700}

/* Doc upload zone */
.upload-zone{border:2px dashed var(--border);border-radius:var(--r-sm);padding:1.25rem;
             text-align:center;cursor:pointer;transition:all .2s;background:var(--bg-off)}
.upload-zone:hover,.upload-zone.drag{border-color:var(--accent);background:var(--accent-bg)}
.upload-zone input{display:none}
.upload-zone .uz-icon{font-size:1.75rem;color:var(--text-muted);margin-bottom:.35rem}
.upload-zone .uz-text{font-size:.8rem;font-weight:500;color:var(--text-m)}
.upload-zone .uz-sub{font-size:.7rem;color:var(--text-muted);margin-top:.15rem}
.upload-preview{display:none;align-items:center;gap:.6rem;padding:.5rem .75rem;
                background:var(--green-bg);border-radius:var(--r-sm);margin-top:.5rem;
                font-size:.8rem;color:#065f46;font-weight:500}
.upload-preview i{font-size:1rem}
.upload-preview .rm-file{margin-left:auto;cursor:pointer;color:var(--red);font-size:1rem}

/* ─── LIVE COUNTER ───────────────────────────────────── */
.days-counter{background:linear-gradient(135deg,#fbbf24,#f97316);
              border-radius:var(--r);padding:1rem 1.25rem;color:#fff;
              display:flex;align-items:center;gap:1rem;margin-bottom:1rem;
              box-shadow:0 4px 20px rgba(99,102,241,.3)}
.dc-num{font-size:2.5rem;font-weight:800;line-height:1;min-width:48px}
.dc-info{flex:1}
.dc-label{font-size:.75rem;font-weight:600;opacity:.85;text-transform:uppercase;letter-spacing:.6px}
.dc-bal{font-size:.82rem;opacity:.75;margin-top:.2rem}
.dc-warn{font-size:.75rem;color:#fde68a;margin-top:.2rem;display:none}

/* ─── SUBMIT BTN ─────────────────────────────────────── */
.btn-submit{width:100%;padding:.875rem;border-radius:var(--r-sm);
            background:linear-gradient(135deg,#fbbf24,#f97316);
            color:#fff;font-size:.95rem;font-weight:700;border:none;cursor:pointer;
            display:flex;align-items:center;justify-content:center;gap:.5rem;
            box-shadow:0 4px 20px rgba(99,102,241,.35);transition:all .2s;letter-spacing:.1px}
.btn-submit:hover{transform:translateY(-1px);box-shadow:0 8px 28px rgba(99,102,241,.45)}
.btn-submit:active{transform:none}
.btn-submit:disabled{opacity:.6;cursor:not-allowed;transform:none}

/* ─── HISTORY TABLE ──────────────────────────────────── */
.history-tabs{display:flex;gap:.5rem;padding:.75rem 1.25rem;border-bottom:1px solid var(--border)}
.htab{padding:.35rem .85rem;border-radius:20px;font-size:.78rem;font-weight:600;
      cursor:pointer;transition:all .18s;border:none;background:transparent;color:var(--text-m)}
.htab.active{background:var(--accent-light);color:var(--accent);font-weight:700}
.history-empty{padding:2.5rem 1rem;text-align:center;color:var(--text-muted)}
.history-empty i{font-size:2.5rem;margin-bottom:.5rem;color:var(--border)}
.history-empty p{font-size:.875rem}

/* Card-style history for mobile */
.leave-cards{display:flex;flex-direction:column;gap:.75rem;padding:1rem 1.25rem}
.leave-card{border:1px solid var(--border);border-radius:var(--r-sm);padding:.875rem 1rem;
            position:relative;overflow:hidden;transition:box-shadow .2s}
.leave-card:hover{box-shadow:var(--shadow-md)}
.leave-card::before{content:'';position:absolute;left:0;top:0;bottom:0;width:4px;
                    background:var(--c,var(--text-muted))}
.lc-top{display:flex;align-items:flex-start;justify-content:space-between;gap:.5rem;margin-bottom:.5rem}
.lc-type{font-size:.82rem;font-weight:700;color:var(--text)}
.lc-dates{font-size:.75rem;color:var(--text-m);margin-top:.1rem}
.lc-days{font-size:.72rem;color:var(--text-muted)}
.lc-reason{font-size:.78rem;color:var(--text-m);margin-top:.4rem;
           display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;overflow:hidden}
.lc-footer{display:flex;align-items:center;gap:.5rem;margin-top:.6rem}
.lc-applied{font-size:.7rem;color:var(--text-muted)}
.btn-cancel-leave{margin-left:auto;padding:.25rem .65rem;border-radius:20px;font-size:.72rem;
                  font-weight:600;border:1.5px solid var(--red);color:var(--red);background:none;
                  cursor:pointer;transition:all .18s}
.btn-cancel-leave:hover{background:var(--red-bg)}

/* ─── BADGES ─────────────────────────────────────────── */
.badge{display:inline-flex;align-items:center;gap:.25rem;padding:.2rem .55rem;
       border-radius:20px;font-size:.68rem;font-weight:700;letter-spacing:.3px;text-transform:capitalize}
.badge-pending  {background:var(--amber-bg);color:#92400e}
.badge-approved {background:var(--green-bg);color:#065f46}
.badge-rejected {background:var(--red-bg);color:#7f1d1d}
.badge-cancelled{background:#f1f5f9;color:var(--text-sm)}
.badge-revoked  {background:var(--purple-bg);color:#4c1d95}

/* ─── CANCEL MODAL ───────────────────────────────────── */
.modal-overlay{position:fixed;inset:0;background:rgba(55,48,163,.3);backdrop-filter:blur(6px);z-index:2000;
               display:none;align-items:flex-end;justify-content:center;
               backdrop-filter:blur(3px);padding:0}
@media(min-width:600px){.modal-overlay{align-items:center;padding:1rem}}
.modal-overlay.open{display:flex;animation:fadeIn .2s ease}
@keyframes fadeIn{from{opacity:0}to{opacity:1}}
.modal{background:var(--card);border-radius:var(--r) var(--r) 0 0;width:100%;max-width:480px;
       padding:1.5rem 1.25rem;animation:slideUp .25s ease}
@media(min-width:600px){.modal{border-radius:var(--r);animation:zoomIn .2s ease}}
@keyframes slideUp{from{transform:translateY(100%)}to{transform:none}}
@keyframes zoomIn{from{transform:scale(.95);opacity:0}to{transform:none;opacity:1}}
.modal h3{font-size:1rem;font-weight:700;color:var(--text);margin-bottom:.75rem}
.modal p{font-size:.85rem;color:var(--text-m);margin-bottom:1rem}
.modal-actions{display:flex;gap:.75rem;margin-top:1.25rem}
.btn-ghost{flex:1;padding:.7rem;border-radius:var(--r-sm);border:1.5px solid var(--border);
           background:var(--card);color:var(--text-m);font-size:.875rem;font-weight:600;cursor:pointer;transition:all .18s}
.btn-ghost:hover{border-color:var(--text-m)}
.btn-danger{flex:1;padding:.7rem;border-radius:var(--r-sm);border:none;
            background:var(--red);color:#fff;font-size:.875rem;font-weight:600;cursor:pointer;transition:all .18s}
.btn-danger:hover{background:#dc2626}

/* ─── REVIEWER NOTE ──────────────────────────────────── */
.reviewer-note{font-size:.75rem;color:var(--text-m);background:var(--bg-off);
               border-radius:var(--r-sm);padding:.4rem .6rem;margin-top:.4rem;
               border-left:3px solid var(--border);font-style:italic}

/* ─── BOTTOM NAV (mobile) ────────────────────────────── */
.bottom-nav{position:fixed;bottom:0;left:0;right:0;height:64px;background:var(--card);
            border-top:1px solid var(--border);display:flex;z-index:900;box-shadow:0 -4px 20px rgba(67,56,202,.1)}
@media(min-width:768px){.bottom-nav{display:none}}
.bn-item{flex:1;display:flex;flex-direction:column;align-items:center;justify-content:center;
         gap:.2rem;color:var(--text-muted);font-size:.62rem;font-weight:600;text-decoration:none;
         border:none;background:none;cursor:pointer;transition:color .18s}
.bn-item i{font-size:1.3rem}
.bn-item.active,.bn-item:hover{color:var(--accent)}

/* ─── UTILITIES ──────────────────────────────────────── */
.mt-1{margin-top:.5rem} .mt-2{margin-top:1rem}
.sr-only{position:absolute;width:1px;height:1px;overflow:hidden;clip:rect(0,0,0,0)}
</style>
</head>
<body>

<!-- ════════ NAVBAR ════════ -->
<nav class="navbar">
  <a href="UserDashboardServlet" class="nav-back">
    <i class="bi bi-arrow-left"></i><span>Dashboard</span>
  </a>
  <div class="nav-brand" style="margin-left:.5rem">
    Smart<span class="dot">·</span>Leave
  </div>
  <div class="nav-right">
    <div class="nav-avatar"><%=initials%></div>
  </div>
</nav>

<!-- ════════ FLASH MESSAGES ════════ -->
<div class="page" style="padding-bottom:0">
<%
  String flashMsg = null; String flashType = null;
  if (flashSuccess != null) { flashMsg = flashSuccess; flashType = "success"; }
  else if (flashError != null) { flashMsg = flashError; flashType = "error"; }
  else if (formError  != null) { flashMsg = formError;  flashType = "error"; }
  if (flashMsg != null) {
%>
<div class="flash <%=flashType%>" id="flashBanner">
  <i class="bi bi-<%="success".equals(flashType)?"check-circle-fill":"exclamation-circle-fill"%>"></i>
  <span><%=flashMsg%></span>
  <button class="flash-close" onclick="document.getElementById('flashBanner').remove()">
    <i class="bi bi-x"></i>
  </button>
</div>
<% } %>
</div>

<!-- ════════ MAIN PAGE ════════ -->
<div class="page">
  <div class="page-head">
    <h1>Leave Request</h1>
    <p>Apply for leave, track history and manage your time-off balance.</p>
  </div>

  <!-- ── BALANCE STRIP ── -->
<%
  /* Build a map: leaveTypeId -> total pending working days for this user.
     Pending leaves are NOT deducted from leave_balances until approved, so
     we subtract them here to show the real effective available balance. */
  java.util.Map<Integer,java.math.BigDecimal> pendingByType = new java.util.HashMap<>();
  for (LeaveRequest _lr : leaveHistory) {
    if ("pending".equalsIgnoreCase(_lr.getStatus()) && _lr.getTotalDays() != null) {
      pendingByType.merge(_lr.getLeaveTypeId(), _lr.getTotalDays(), java.math.BigDecimal::add);
    }
  }
%>
  <div class="balance-grid">
<%
  String[] bcols = {"#6366f1","#7c3aed","#059669","#d97706","#f97316","#dc2626"};
  int bidx = 0;
  for (LeaveType lt : leaveTypes) {
    java.math.BigDecimal avail = lt.getAvailable();
    java.math.BigDecimal pendingDays = pendingByType.getOrDefault(lt.getId(), java.math.BigDecimal.ZERO);
    java.math.BigDecimal effectiveAvail = avail.subtract(pendingDays).max(java.math.BigDecimal.ZERO);
    String col = bcols[bidx % bcols.length]; bidx++;
%>
    <div class="bal-card" style="--c:<%=col%>">
      <div class="bal-label"><%=lt.getTypeName().split(" ")[0]%></div>
      <div class="bal-val"><%=effectiveAvail.stripTrailingZeros().toPlainString()%></div>
      <div class="bal-sub">of <%=lt.getMaxDays()%> days <%=lt.isPaid()?"• Paid":"• Unpaid"%>
        <%=pendingDays.compareTo(java.math.BigDecimal.ZERO)>0
            ? "<br><span style='color:#f59e0b;font-weight:700'>" + pendingDays.stripTrailingZeros().toPlainString() + " day(s) pending approval</span>"
            : ""%>
      </div>
    </div>
<% } %>
  </div>

  <!-- ── TWO COLUMN ── -->
  <div class="two-col">

    <!-- ══ APPLY FORM ══ -->
    <div class="card">
      <div class="card-head">
        <div class="icon"><i class="bi bi-send-plus"></i></div>
        <h2>Apply Leave</h2>
      </div>
      <div class="card-body">
        <form method="post" action="LeaveServlet" enctype="multipart/form-data" id="leaveForm" novalidate>
          <input type="hidden" name="action" value="apply">

          <!-- Leave Type -->
          <div class="form-group">
            <label class="form-label" for="leaveTypeId">
              Leave Type <span class="req">*</span>
            </label>
            <select class="form-control" id="leaveTypeId" name="leaveTypeId" required onchange="onTypeChange(this)">
              <option value="">— Select type —</option>
<%
  for (LeaveType lt : leaveTypes) {
    java.math.BigDecimal avail = lt.getAvailable();
    java.math.BigDecimal pendingDays2 = pendingByType.getOrDefault(lt.getId(), java.math.BigDecimal.ZERO);
    java.math.BigDecimal effectiveAvail2 = avail.subtract(pendingDays2).max(java.math.BigDecimal.ZERO);
    boolean disabled = effectiveAvail2.compareTo(java.math.BigDecimal.ZERO) <= 0 && lt.isPaid() && lt.getMaxDays() > 0;
%>
              <option value="<%=lt.getId()%>"
                      data-avail="<%=effectiveAvail2%>"
                      data-paid="<%=lt.isPaid()%>"
                      data-reqdoc="<%=lt.isRequiresDoc()%>"
                      data-desc="<%=lt.getDescription() != null ? lt.getDescription().replace("\"","&quot;") : ""%>"
                      <%=disabled?"disabled":""%>>
                <%=lt.getTypeName()%> (<%=effectiveAvail2.stripTrailingZeros().toPlainString()%> days left)
              </option>
<% } %>
            </select>
            <div class="form-hint" id="typeHint" style="display:none">
              <i class="bi bi-info-circle"></i><span id="typeHintText"></span>
            </div>
          </div>

          <!-- Date row -->
          <div class="form-group">
            <label class="form-label">Dates <span class="req">*</span></label>
            <div class="date-row">
              <div>
                <label class="form-label" for="fromDate" style="font-size:.72rem">From</label>
                <input class="form-control" type="date" id="fromDate" name="fromDate"
                       min="<%=today%>" max="<%=today90%>" required onchange="calcDays()">
              </div>
              <div>
                <label class="form-label" for="toDate" style="font-size:.72rem">To</label>
                <input class="form-control" type="date" id="toDate" name="toDate"
                       min="<%=today%>" max="<%=today90%>" required onchange="calcDays()">
              </div>
            </div>
          </div>

          <!-- Session Type -->
          <div class="form-group" id="sessionGroup">
            <label class="form-label">Session
              <span class="info-tip" title="Half-day applies only when From = To (single day)">
                <i class="bi bi-question-circle"></i>
              </span>
            </label>
            <div class="session-pills">
              <div class="session-pill">
                <input type="radio" name="sessionType" id="sFull" value="full_day" checked onchange="calcDays()">
                <label for="sFull"><i class="bi bi-sun"></i>Full Day</label>
              </div>
              <div class="session-pill">
                <input type="radio" name="sessionType" id="sFirst" value="first_half" onchange="calcDays()">
                <label for="sFirst"><i class="bi bi-brightness-alt-high"></i>First Half</label>
              </div>
              <div class="session-pill">
                <input type="radio" name="sessionType" id="sSecond" value="second_half" onchange="calcDays()">
                <label for="sSecond"><i class="bi bi-moon-stars"></i>Second Half</label>
              </div>
            </div>
          </div>

          <!-- Live Day Counter -->
          <div class="days-counter" id="daysCounter" style="display:none">
            <div class="dc-num" id="dcNum">0</div>
            <div class="dc-info">
              <div class="dc-label">Working Days Requested</div>
              <div class="dc-bal" id="dcBal">Balance: — days</div>
              <div class="dc-warn" id="dcWarn"><i class="bi bi-exclamation-triangle-fill"></i> Exceeds balance — Loss of Pay may apply</div>
            </div>
          </div>

          <!-- Reason -->
          <div class="form-group">
            <label class="form-label" for="reason">Reason <span class="req">*</span></label>
            <textarea class="form-control" id="reason" name="reason" rows="3"
                      placeholder="Briefly describe the reason for your leave (min 10 characters)…"
                      required minlength="10" oninput="checkReason(this)"></textarea>
            <div class="form-hint"><i class="bi bi-pencil-square"></i><span id="reasonCount">0 / 500 characters</span></div>
          </div>

          <!-- Contact During Leave -->
          <div class="form-group">
            <label class="form-label" for="contactDuringLeave">
              Contact During Leave
              <span class="info-tip" title="Phone number reachable during your absence">
                <i class="bi bi-question-circle"></i>
              </span>
            </label>
            <input class="form-control" type="tel" id="contactDuringLeave" name="contactDuringLeave"
                   placeholder="+91 9876543210" pattern="[0-9+\-\s]{7,15}">
          </div>

          <!-- Covering Person -->
          <div class="form-group">
            <label class="form-label" for="coveringPerson">Covering / Backup Person</label>
            <input class="form-control" type="text" id="coveringPerson" name="coveringPerson"
                   placeholder="Colleague handling your work" maxlength="100">
          </div>

          <!-- Handover Notes -->
          <div class="form-group">
            <label class="form-label" for="workHandover">Work Handover Notes</label>
            <textarea class="form-control" id="workHandover" name="workHandover" rows="2"
                      placeholder="Mention pending tasks, deadlines, or handover details…"></textarea>
          </div>

          <!-- Document Upload -->
          <div class="form-group" id="docGroup">
            <label class="form-label" id="docLabel">
              Supporting Document
            </label>
            <div class="upload-zone" id="uploadZone" onclick="document.getElementById('document').click()"
                 ondragover="event.preventDefault();this.classList.add('drag')"
                 ondragleave="this.classList.remove('drag')"
                 ondrop="handleDrop(event)">
              <input type="file" id="document" name="document" accept=".pdf,.jpg,.jpeg,.png" onchange="previewFile(this)">
              <div class="uz-icon"><i class="bi bi-cloud-arrow-up"></i></div>
              <div class="uz-text">Click or drag file here</div>
              <div class="uz-sub">PDF, JPG, PNG — max 5 MB</div>
            </div>
            <div class="upload-preview" id="uploadPreview">
              <i class="bi bi-file-earmark-check"></i>
              <span id="fileName"></span>
              <i class="bi bi-x-circle rm-file" onclick="removeFile()" title="Remove"></i>
            </div>
          </div>

          <!-- Submit -->
          <button type="submit" class="btn-submit" id="submitBtn">
            <i class="bi bi-send-check"></i> Submit Leave Request
          </button>

        </form>
      </div>
    </div><!-- /apply card -->

    <!-- ══ HISTORY ══ -->
    <div class="card">
      <div class="card-head">
        <div class="icon" style="background:var(--teal-bg);color:var(--teal)">
          <i class="bi bi-clock-history"></i>
        </div>
        <h2>My Leave History</h2>
      </div>
      <!-- Tabs -->
      <div class="history-tabs">
        <button class="htab active" onclick="filterHistory('all',this)">All
          <span style="font-size:.65rem;margin-left:.25rem;opacity:.7">(<%=leaveHistory.size()%>)</span>
        </button>
        <button class="htab" onclick="filterHistory('pending',this)">Pending
          <span style="font-size:.65rem;margin-left:.25rem;opacity:.7">(<%=pendingCount%>)</span>
        </button>
        <button class="htab" onclick="filterHistory('approved',this)">Approved
          <span style="font-size:.65rem;margin-left:.25rem;opacity:.7">(<%=approvedCount%>)</span>
        </button>
      </div>

      <!-- Leave cards -->
      <div class="leave-cards" id="historyContainer">
<%
  if (leaveHistory.isEmpty()) {
%>
        <div class="history-empty">
          <div><i class="bi bi-calendar-x"></i></div>
          <p>No leave requests yet.</p>
        </div>
<%
  } else {
    SimpleDateFormat df = new SimpleDateFormat("dd MMM yyyy");
    SimpleDateFormat dtf = new SimpleDateFormat("dd MMM ''yy, hh:mm a");
    String[] histColors = {"#6366f1","#7c3aed","#059669","#d97706","#f97316","#dc2626"};
    int hidx = 0;
    for (LeaveRequest lr : leaveHistory) {
      String st = lr.getStatus() != null ? lr.getStatus().toLowerCase() : "pending";
      String hcol;
      switch(st) {
        case "approved":  hcol="#10b981"; break;
        case "rejected":  hcol="#ef4444"; break;
        case "cancelled": hcol="#94a3b8"; break;
        case "revoked":   hcol="#8b5cf6"; break;
        default:          hcol="#f59e0b";
      }
      String fromFmt = lr.getFromDate() != null ? df.format(lr.getFromDate()) : "—";
      String toFmt   = lr.getToDate()   != null ? df.format(lr.getToDate())   : "—";
      String applFmt = lr.getAppliedOn()!= null ? dtf.format(lr.getAppliedOn()): "—";
      boolean canCancel = ("pending".equals(st) || "approved".equals(st));
%>
        <div class="leave-card" style="--c:<%=hcol%>" data-status="<%=st%>">
          <div class="lc-top">
            <div>
              <div class="lc-type"><%=lr.getLeaveTypeName()%>
                <% if (!lr.isPaid()) { %><span style="font-size:.65rem;color:var(--red)"> • Unpaid</span><% } %>
              </div>
              <div class="lc-dates"><%=fromFmt%> → <%=toFmt%>
                <span class="lc-days">(<%=lr.getTotalDays()%> day<%=lr.getTotalDays().compareTo(java.math.BigDecimal.ONE)>0?"s":""%>)</span>
              </div>
            </div>
            <span class="badge badge-<%=st%>"><i class="bi bi-circle-fill" style="font-size:.4rem"></i><%=st%></span>
          </div>
          <div class="lc-reason"><%=lr.getReason() != null ? lr.getReason() : ""%></div>
          <%
            if (lr.getReviewerNote() != null && !lr.getReviewerNote().isBlank()) {
          %>
          <div class="reviewer-note">
            <i class="bi bi-chat-left-text"></i> <%=lr.getReviewerNote()%>
            <% if (lr.getReviewedBy() != null) { %> — <strong><%=lr.getReviewedBy()%></strong><% } %>
          </div>
          <% } %>
          <div class="lc-footer">
            <span class="lc-applied">Applied: <%=applFmt%></span>
            <% if (canCancel) { %>
            <button class="btn-cancel-leave" onclick="openCancelModal(<%=lr.getId()%>,'<%=lr.getLeaveTypeName()%>', '<%=fromFmt%> – <%=toFmt%>')">
              Cancel
            </button>
            <% } %>
          </div>
        </div>
<%
    }
  }
%>
      </div><!-- /leave-cards -->
    </div><!-- /history card -->

  </div><!-- /two-col -->
</div><!-- /page -->

<!-- ════════ CANCEL MODAL ════════ -->
<div class="modal-overlay" id="cancelModal">
  <div class="modal">
    <h3><i class="bi bi-x-circle" style="color:var(--red)"></i> Cancel Leave</h3>
    <p id="cancelModalDesc">Are you sure you want to cancel this leave?</p>
    <form method="post" action="LeaveServlet" id="cancelForm">
      <input type="hidden" name="action" value="cancel">
      <input type="hidden" name="requestId" id="cancelRequestId">
      <div class="form-group">
        <label class="form-label" for="cancelReason">Reason for Cancellation <span class="req">*</span></label>
        <textarea class="form-control" id="cancelReason" name="cancelReason" rows="2"
                  placeholder="Briefly explain why you're cancelling…" required></textarea>
      </div>
      <div class="modal-actions">
        <button type="button" class="btn-ghost" onclick="closeCancelModal()">Keep Leave</button>
        <button type="submit" class="btn-danger"><i class="bi bi-trash3"></i> Cancel Leave</button>
      </div>
    </form>
  </div>
</div>

<!-- ════════ BOTTOM NAV ════════ -->
<nav class="bottom-nav">
  <a class="bn-item" href="UserDashboardServlet">
    <i class="bi bi-house"></i>Home
  </a>
  <a class="bn-item active" href="LeaveServlet">
    <i class="bi bi-calendar-plus"></i>Leave
  </a>
  <a class="bn-item" href="AttendanceServlet">
    <i class="bi bi-clock"></i>Attendance
  </a>
  <a class="bn-item" href="ProfileServlet">
    <i class="bi bi-person"></i>Profile
  </a>
</nav>

<!-- ════════ SCRIPTS ════════ -->
<script>
// ── Leave type meta from JSP ──────────────────────────────────
// avail uses the pending-adjusted effective balance so the live day counter
// and over-balance warning are accurate when the user picks a leave type.
const leaveTypes = {};
<%
for (LeaveType lt : leaveTypes) {
    java.math.BigDecimal _pendingJs = pendingByType.getOrDefault(lt.getId(), java.math.BigDecimal.ZERO);
    java.math.BigDecimal _effectiveJs = lt.getAvailable().subtract(_pendingJs).max(java.math.BigDecimal.ZERO);
%>
leaveTypes[<%=lt.getId()%>] = {
  avail:    <%=_effectiveJs%>,
  requiresDoc: <%=lt.isRequiresDoc()%>,
  desc:     "<%=lt.getDescription() != null ? lt.getDescription().replace("\"","\\\"").replace("\n"," ") : ""%>",
  maxConsec: <%="Casual Leave".equals(lt.getTypeName()) ? 3 : 999%>
};
<%
}
%>

let currentAvail = 0;
let calcTimeout  = null;

// ── Type change ───────────────────────────────────────────────
function onTypeChange(sel) {
  const id  = parseInt(sel.value);
  const meta = leaveTypes[id];
  const hint = document.getElementById('typeHint');
  const hintTxt = document.getElementById('typeHintText');
  const docLabel = document.getElementById('docLabel');
  const docGroup = document.getElementById('docGroup');

  if (meta) {
    currentAvail = meta.avail;
    if (meta.desc) {
      hint.style.display = 'flex';
      hintTxt.textContent = meta.desc;
    } else {
      hint.style.display = 'none';
    }
    // Require document badge
    if (meta.requiresDoc) {
      docLabel.innerHTML = 'Supporting Document <span class="req">*</span><span style="font-size:.7rem;color:var(--amber);margin-left:.3rem"><i class="bi bi-exclamation-triangle"></i> Required</span>';
      document.getElementById('document').required = true;
    } else {
      docLabel.innerHTML = 'Supporting Document <span style="font-size:.7rem;color:var(--text-muted);margin-left:.25rem">— optional</span>';
      document.getElementById('document').required = false;
    }
  } else {
    currentAvail = 0;
    hint.style.display = 'none';
  }
  updateDayCounter();
}

// ── Date / session change: debounced AJAX ─────────────────────
function calcDays() {
  const from = document.getElementById('fromDate').value;
  const to   = document.getElementById('toDate').value;

  // Enforce to >= from
  if (from && to && to < from) {
    document.getElementById('toDate').value = from;
  }

  // Disable half-day if multi-day
  const sameDay = from && to && from === to;
  document.getElementById('sFirst').disabled  = !sameDay;
  document.getElementById('sSecond').disabled = !sameDay;
  if (!sameDay) document.getElementById('sFull').checked = true;

  clearTimeout(calcTimeout);
  if (!from || !to) return;

  calcTimeout = setTimeout(() => {
    const session = document.querySelector('input[name=sessionType]:checked').value;
    fetch(`LeaveServlet?action=days&from=${from}&to=${to}&session=${session}`)
      .then(r => r.json())
      .then(d => {
        document.getElementById('dcNum').textContent = d.days;
        updateDayCounter(d.days);
      })
      .catch(() => {});
  }, 400);
}

function updateDayCounter(days) {
  const counter = document.getElementById('daysCounter');
  const dcBal   = document.getElementById('dcBal');
  const dcWarn  = document.getElementById('dcWarn');
  const typeId  = document.getElementById('leaveTypeId').value;
  if (!typeId) { counter.style.display='none'; return; }

  const from = document.getElementById('fromDate').value;
  const to   = document.getElementById('toDate').value;
  if (!from || !to) { counter.style.display='none'; return; }

  counter.style.display = 'flex';

  if (days !== undefined) {
    dcBal.textContent = 'Balance: ' + currentAvail + ' days available';
    if (parseFloat(days) > parseFloat(currentAvail) && currentAvail > 0) {
      dcWarn.style.display = 'flex';
    } else {
      dcWarn.style.display = 'none';
    }
  }
}

// ── Reason char count ─────────────────────────────────────────
function checkReason(el) {
  const len = el.value.length;
  const el2 = document.getElementById('reasonCount');
  el2.textContent = len + ' / 500 characters';
  el2.style.color = len < 10 ? 'var(--red)' : 'var(--text-muted)';
  if (len > 500) el.value = el.value.substring(0, 500);
}

// ── File upload ───────────────────────────────────────────────
function previewFile(input) {
  if (input.files && input.files[0]) {
    const f = input.files[0];
    if (f.size > 5 * 1024 * 1024) {
      alert('File size must be under 5 MB.');
      input.value = '';
      return;
    }
    document.getElementById('fileName').textContent = f.name;
    document.getElementById('uploadPreview').style.display = 'flex';
    document.getElementById('uploadZone').querySelector('.uz-text').textContent = 'File selected';
  }
}
function removeFile() {
  document.getElementById('document').value = '';
  document.getElementById('uploadPreview').style.display = 'none';
  document.getElementById('uploadZone').querySelector('.uz-text').textContent = 'Click or drag file here';
}
function handleDrop(e) {
  e.preventDefault();
  document.getElementById('uploadZone').classList.remove('drag');
  const file = e.dataTransfer.files[0];
  if (file) {
    const dt = new DataTransfer();
    dt.items.add(file);
    const inp = document.getElementById('document');
    inp.files = dt.files;
    previewFile(inp);
  }
}

// ── Cancel modal ──────────────────────────────────────────────
function openCancelModal(id, typeName, dates) {
  document.getElementById('cancelRequestId').value = id;
  document.getElementById('cancelModalDesc').textContent =
    `Cancel your ${typeName} (${dates})?`;
  document.getElementById('cancelReason').value = '';
  document.getElementById('cancelModal').classList.add('open');
}
function closeCancelModal() {
  document.getElementById('cancelModal').classList.remove('open');
}
document.getElementById('cancelModal').addEventListener('click', function(e) {
  if (e.target === this) closeCancelModal();
});

// ── History filter tabs ───────────────────────────────────────
function filterHistory(status, btn) {
  document.querySelectorAll('.htab').forEach(b => b.classList.remove('active'));
  btn.classList.add('active');
  document.querySelectorAll('.leave-card').forEach(card => {
    card.style.display =
      (status === 'all' || card.dataset.status === status) ? '' : 'none';
  });
}

// ── Form validation before submit ─────────────────────────────
document.getElementById('leaveForm').addEventListener('submit', function(e) {
  const type = document.getElementById('leaveTypeId').value;
  const from = document.getElementById('fromDate').value;
  const to   = document.getElementById('toDate').value;
  const reason = document.getElementById('reason').value.trim();

  if (!type) { e.preventDefault(); showInlineErr('Please select a leave type.'); return; }
  if (!from)  { e.preventDefault(); showInlineErr('Please select a From date.'); return; }
  if (!to)    { e.preventDefault(); showInlineErr('Please select a To date.'); return; }
  if (to < from) { e.preventDefault(); showInlineErr('To date cannot be before From date.'); return; }
  if (reason.length < 10) { e.preventDefault(); showInlineErr('Reason must be at least 10 characters.'); return; }

  // Doc required check client-side
  const typeId = parseInt(type);
  if (leaveTypes[typeId] && leaveTypes[typeId].requiresDoc) {
    const docFile = document.getElementById('document').files;
    if (!docFile || docFile.length === 0) {
      e.preventDefault();
      showInlineErr('A supporting document is required for this leave type.');
      return;
    }
  }

  document.getElementById('submitBtn').disabled = true;
  document.getElementById('submitBtn').innerHTML =
    '<span class="bi bi-hourglass-split"></span> Submitting…';
});

function showInlineErr(msg) {
  let existing = document.getElementById('inlineErr');
  if (existing) existing.remove();
  const div = document.createElement('div');
  div.id = 'inlineErr';
  div.className = 'flash error';
  div.style.marginBottom = '.75rem';
  div.innerHTML = `<i class="bi bi-exclamation-circle-fill"></i><span>${msg}</span>`;
  document.getElementById('leaveForm').prepend(div);
  div.scrollIntoView({behavior:'smooth', block:'center'});
}

// Auto-dismiss flash after 6s
setTimeout(() => {
  const f = document.getElementById('flashBanner');
  if (f) f.style.transition='opacity .5s', f.style.opacity='0',
         setTimeout(()=>f.remove(), 500);
}, 6000);
</script>

</body>
</html>
