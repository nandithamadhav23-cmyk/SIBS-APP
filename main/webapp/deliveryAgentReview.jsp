<%@ page contentType="text/html; charset=UTF-8" %>
<%@ page import="java.util.*, com.util.DeliveryRegistration, com.DAO.DeliveryRegistrationDAO, com.util.DBConnection, java.sql.Connection" %>
<%--
  deliveryAgentReview.jsp
  Loaded AJAX-style into dashboard.jsp#mainContent — NO html/body tags.
  Uses CSS vars from dashboard.jsp :root block.

  TOAST FIX: The servlet does resp.sendRedirect() after POST.
  deliveryAgentDetail.jsp uses fetch() (AJAX) for the POST, which follows
  the redirect silently — by that point the session attributes are already
  consumed by the redirect response, so this JSP never sees them.

  Fix: deliveryAgentDetail.js passes toast data as URL query params
  (?toastMsg=...&toastType=...) so this page renders the toast from
  request params. Session attrs are still read as fallback for non-AJAX flows.
--%>
<%
    String _role = (session != null) ? (String) session.getAttribute("role") : null;
    if (_role == null || !"admin".equalsIgnoreCase(_role)) {
        out.print("<p style='color:#e74c3c;font-family:Times New Roman;padding:2rem;'>"
                + "<i class='bi bi-lock me-2'></i>Access denied.</p>");
        return;
    }

    String filterParam = request.getParameter("filter");
    if (filterParam == null || filterParam.isBlank()) filterParam = "ALL";
    filterParam = filterParam.toUpperCase();

    List<DeliveryRegistration> registrations = new ArrayList<>();
    int cntPending = 0, cntApproved = 0, cntRejected = 0;
    String dbError = null;

    try (Connection conn = DBConnection.getConnection()) {
        DeliveryRegistrationDAO dao = new DeliveryRegistrationDAO(conn);
        cntPending  = dao.countByStatus("PENDING");
        cntApproved = dao.countByStatus("APPROVED");
        cntRejected = dao.countByStatus("REJECTED");
        registrations = "ALL".equals(filterParam)
            ? dao.getAllRegistrations() : dao.getByStatus(filterParam);
    } catch (Exception ex) {
        dbError = ex.getMessage();
    }

    int cntAll = cntPending + cntApproved + cntRejected;

    /* ── Toast: URL params (AJAX flow) or session (full-page flow) ── */
    String actionMsg  = request.getParameter("toastMsg");
    String actionType = request.getParameter("toastType");
    if (actionMsg == null || actionMsg.isBlank()) {
        actionMsg  = (String) session.getAttribute("drActionMsg");
        actionType = (String) session.getAttribute("drActionType");
        if (actionMsg != null) {
            session.removeAttribute("drActionMsg");
            session.removeAttribute("drActionType");
        }
    }
    if (actionType == null || actionType.isBlank()) actionType = "success";
%>

<style>
/* ═══════════════════════════════════════════════════════════════════════
   deliveryAgentReview.jsp — uses dashboard.jsp :root vars
   --primary:#1a1a2e  --accent:#c8a96e  --accent-light:#f5ecd7
   --bg-white:#fff  --bg-off:#f8f8fc  --border:#e0e0f0
   --text-dark:#1a1a2e  --text-muted:#6b6b8a
   --shadow-sm  --shadow-md
═══════════════════════════════════════════════════════════════════════ */

.dr-page-header {
    display:flex; align-items:center; justify-content:space-between;
    flex-wrap:wrap; gap:1rem; margin-bottom:1.6rem;
}
.dr-page-title {
    font-family:'Times New Roman',Times,serif;
    font-size:1.45rem; font-weight:700; color:var(--text-dark);
    margin:0; display:flex; align-items:center; gap:0.6rem;
}
.dr-page-title i { color:var(--accent); }
.dr-page-title small {
    display:block; font-size:0.8rem; font-weight:400;
    color:var(--text-muted); letter-spacing:0.4px; margin-top:3px;
}

/* ── Toast ── */
@keyframes drToastIn {
    from { opacity:0; transform:translateY(-10px) scale(.98); }
    to   { opacity:1; transform:translateY(0) scale(1); }
}
@keyframes drShrink { from{width:100%} to{width:0%} }

.dr-toast-wrap {
    margin-bottom:1.5rem;
    animation:drToastIn .4s cubic-bezier(.22,1,.36,1) both;
}
.dr-toast {
    background:var(--bg-white);
    border:1px solid var(--border); border-radius:8px; overflow:hidden;
    box-shadow:0 4px 20px rgba(26,26,46,.10), 0 1px 4px rgba(26,26,46,.06);
}
.dr-toast-accent { height:3px; }
.dr-toast-accent.success { background:#27ae60; }
.dr-toast-accent.danger  { background:#e74c3c; }

.dr-toast-body {
    display:flex; align-items:flex-start; gap:14px; padding:16px 18px 12px;
}
.dr-toast-icon {
    width:40px; height:40px; border-radius:8px;
    display:flex; align-items:center; justify-content:center;
    flex-shrink:0; font-size:1.15rem;
}
.dr-toast-icon.success { background:#eaf8f0; color:#27ae60; }
.dr-toast-icon.danger  { background:#fdecea; color:#e74c3c; }
.dr-toast-content { flex:1; min-width:0; }
.dr-toast-header  { display:flex; align-items:center; gap:8px; margin-bottom:4px; }
.dr-toast-title   { font-family:'Times New Roman',Times,serif; font-size:0.95rem; font-weight:700; flex:1; }
.dr-toast-title.success { color:#1e8449; }
.dr-toast-title.danger  { color:#c0392b; }
.dr-toast-badge {
    font-size:0.62rem; font-weight:700; letter-spacing:.08em; text-transform:uppercase;
    padding:2px 8px; border-radius:20px; border:1px solid; white-space:nowrap;
}
.dr-toast-badge.success { background:#eaf8f0; color:#27ae60; border-color:#a9dfbf; }
.dr-toast-badge.danger  { background:#fdecea; color:#e74c3c; border-color:#f5b7b1; }
.dr-toast-close {
    background:none; border:none; cursor:pointer;
    padding:2px 6px; border-radius:4px; font-size:0.9rem;
    color:var(--text-muted); transition:background .12s, color .12s;
}
.dr-toast-close:hover { background:var(--bg-off); color:var(--text-dark); }
.dr-toast-msg {
    font-family:'Times New Roman',Times,serif; font-size:0.88rem;
    color:var(--text-muted); line-height:1.6; margin:0;
}
.dr-toast-msg strong { color:var(--text-dark); font-weight:700; }
.dr-toast-footer {
    display:flex; align-items:center; gap:12px;
    padding:8px 18px 12px 72px; border-top:1px solid var(--border); flex-wrap:wrap;
}
.dr-toast-meta {
    display:flex; align-items:center; gap:4px;
    font-size:0.74rem; color:var(--text-muted); font-family:'Times New Roman',Times,serif;
}
.dr-toast-meta i { font-size:0.78rem; }
.dr-toast-actions { display:flex; gap:7px; margin-left:auto; }
.dr-toast-btn {
    font-family:'Times New Roman',Times,serif;
    font-size:0.74rem; font-weight:600; padding:4px 12px;
    border-radius:4px; border:1px solid var(--border); background:transparent;
    cursor:pointer; color:var(--text-muted); text-decoration:none;
    display:inline-flex; align-items:center; gap:4px; transition:all .12s;
}
.dr-toast-btn:hover { background:var(--bg-off); color:var(--text-dark); }
.dr-toast-btn.primary.success { color:#1e8449; border-color:#a9dfbf; background:#eaf8f0; }
.dr-toast-btn.primary.danger  { color:#c0392b; border-color:#f5b7b1; background:#fdecea; }
.dr-progress-wrap { height:3px; background:var(--border); }
.dr-progress-bar  { height:3px; animation:drShrink 5s linear forwards; }
.dr-progress-bar.success { background:#27ae60; }
.dr-progress-bar.danger  { background:#e74c3c; }

/* ── Stats row ── */
.dr-stats {
    display:grid; grid-template-columns:repeat(4,1fr);
    gap:1rem; margin-bottom:1.6rem;
}
.dr-stat-card {
    background:var(--bg-white); border:1px solid var(--border); border-radius:6px;
    padding:1.2rem 1rem 1rem; text-align:center;
    box-shadow:var(--shadow-sm); position:relative; overflow:hidden;
    transition:box-shadow .2s;
}
.dr-stat-card:hover { box-shadow:var(--shadow-md); }
.dr-stat-card::before {
    content:''; position:absolute; top:0; left:0; right:0; height:3px;
}
.dr-stat-card.all::before      { background:var(--accent); }
.dr-stat-card.pending::before  { background:#e67e22; }
.dr-stat-card.approved::before { background:#27ae60; }
.dr-stat-card.rejected::before { background:#e74c3c; }
.dr-stat-icon { font-size:1.3rem; display:block; margin-bottom:0.5rem; }
.dr-stat-card.all      .dr-stat-icon { color:var(--accent); }
.dr-stat-card.pending  .dr-stat-icon { color:#e67e22; }
.dr-stat-card.approved .dr-stat-icon { color:#27ae60; }
.dr-stat-card.rejected .dr-stat-icon { color:#e74c3c; }
.dr-stat-number {
    font-family:'Times New Roman',Times,serif; font-size:2.2rem;
    font-weight:700; line-height:1;
}
.dr-stat-card.all      .dr-stat-number { color:var(--text-dark); }
.dr-stat-card.pending  .dr-stat-number { color:#e67e22; }
.dr-stat-card.approved .dr-stat-number { color:#27ae60; }
.dr-stat-card.rejected .dr-stat-number { color:#e74c3c; }
.dr-stat-label {
    font-size:0.68rem; letter-spacing:1.8px; text-transform:uppercase;
    color:var(--text-muted); margin-top:5px; font-family:'Times New Roman',Times,serif;
}

/* ── Filter tabs ── */
.dr-tabs {
    display:flex; gap:2px; margin-bottom:1.4rem; border-bottom:2px solid var(--border);
}
.dr-tab {
    font-family:'Times New Roman',Times,serif; font-size:0.87rem;
    padding:0.55rem 1.2rem; border:none; background:none; color:var(--text-muted);
    cursor:pointer; border-bottom:3px solid transparent; margin-bottom:-2px;
    transition:all 0.2s; text-decoration:none; display:inline-flex;
    align-items:center; gap:0.4rem; border-radius:4px 4px 0 0;
}
.dr-tab:hover { color:var(--text-dark); background:var(--accent-light); }
.dr-tab.active { color:var(--primary); font-weight:700; border-bottom-color:var(--accent); background:var(--accent-light); }
.tab-badge {
    font-size:0.65rem; padding:1px 7px; border-radius:10px;
    font-weight:700; min-width:22px; text-align:center; display:inline-block;
}
.dr-tab.all      .tab-badge { background:var(--accent-light); color:var(--primary); }
.dr-tab.pending  .tab-badge { background:#fff3e0; color:#e67e22; }
.dr-tab.approved .tab-badge { background:#e8f8ee; color:#27ae60; }
.dr-tab.rejected .tab-badge { background:#fdecea; color:#e74c3c; }

/* ── Toolbar ── */
.dr-toolbar {
    display:flex; align-items:center; gap:0.75rem; margin-bottom:1.2rem; flex-wrap:wrap;
}
.dr-search-wrap { position:relative; flex:1; min-width:220px; max-width:340px; }
.dr-search-wrap i {
    position:absolute; left:10px; top:50%; transform:translateY(-50%);
    color:var(--text-muted); font-size:0.9rem; pointer-events:none;
}
.dr-search-input {
    font-family:'Times New Roman',Times,serif; border:1px solid var(--border);
    border-radius:5px; padding:0.5rem 1rem 0.5rem 2rem; font-size:0.87rem;
    color:var(--text-dark); background:var(--bg-white); width:100%; outline:none;
    transition:border-color 0.2s, box-shadow 0.2s;
}
.dr-search-input:focus { border-color:var(--accent); box-shadow:0 0 0 3px rgba(200,169,110,0.12); }
.dr-row-count {
    font-family:'Times New Roman',Times,serif; font-size:0.8rem;
    color:var(--text-muted); margin-left:auto; white-space:nowrap;
}
.dr-row-count strong { color:var(--text-dark); }

/* ── Table ── */
.dr-table-wrap {
    background:var(--bg-white); border:1px solid var(--border);
    border-radius:6px; overflow:hidden; box-shadow:var(--shadow-sm);
}
.dr-table { width:100%; border-collapse:collapse; font-family:'Times New Roman',Times,serif; font-size:0.9rem; }
.dr-table thead th {
    background:var(--primary); color:rgba(255,255,255,0.82);
    font-size:0.67rem; letter-spacing:1.8px; text-transform:uppercase;
    padding:0.9rem 1rem; text-align:left; font-weight:600; white-space:nowrap; border:none;
}
.dr-table thead th i { color:var(--accent); margin-right:4px; font-size:0.85rem; }
.dr-table tbody tr { border-bottom:1px solid var(--border); transition:background 0.15s; }
.dr-table tbody tr:last-child { border-bottom:none; }
.dr-table tbody tr:hover { background:var(--bg-off); }
.dr-table tbody td { padding:0.85rem 1rem; vertical-align:middle; color:var(--text-dark); }

.dr-agent-cell { display:flex; align-items:center; gap:0.75rem; }
.dr-avatar {
    width:38px; height:38px; border-radius:50%;
    background:var(--accent-light); border:2px solid var(--accent);
    display:flex; align-items:center; justify-content:center;
    font-size:0.95rem; color:var(--primary); font-weight:700;
    font-family:'Times New Roman',Times,serif; flex-shrink:0;
}
.dr-agent-name { font-weight:700; color:var(--text-dark); font-size:0.9rem; line-height:1.3; }
.dr-agent-sub  { font-size:0.76rem; color:var(--text-muted); }

.status-badge {
    display:inline-flex; align-items:center; gap:0.3rem;
    padding:0.22rem 0.7rem; border-radius:20px; font-size:0.68rem;
    font-weight:700; letter-spacing:1.2px; text-transform:uppercase; white-space:nowrap;
}
.status-badge.PENDING  { background:#fff3e0; color:#e67e22; border:1px solid #f5cba7; }
.status-badge.APPROVED { background:#eaf8f0; color:#27ae60; border:1px solid #a9dfbf; }
.status-badge.REJECTED { background:#fdecea; color:#e74c3c; border:1px solid #f5b7b1; }

.btn-view {
    font-family:'Times New Roman',Times,serif; font-size:0.76rem; letter-spacing:0.5px;
    padding:0.32rem 0.85rem; border:1px solid var(--primary); border-radius:4px;
    color:var(--primary); background:transparent; text-decoration:none;
    white-space:nowrap; transition:all 0.18s; display:inline-flex; align-items:center; gap:0.3rem;
}
.btn-view:hover { background:var(--primary); color:#fff; }

.dr-error-alert {
    display:flex; align-items:center; gap:0.6rem;
    padding:0.85rem 1.2rem; background:#fdecea; border:1px solid #f5b7b1;
    border-radius:6px; color:#c0392b; font-family:'Times New Roman',Times,serif;
    font-size:0.88rem; margin-bottom:1.2rem;
}
.dr-empty {
    text-align:center; padding:4rem 2rem; color:var(--text-muted);
    font-family:'Times New Roman',Times,serif;
}
.dr-empty i { font-size:2.8rem; display:block; margin-bottom:1rem; color:var(--border); }
.dr-empty p { font-size:0.95rem; }

@media(max-width:900px){
    .dr-stats { grid-template-columns:repeat(2,1fr); }
    .dr-table-wrap { overflow-x:auto; -webkit-overflow-scrolling:touch; }
    .dr-table { min-width:680px; }
}
@media(max-width:600px){
    .dr-page-title { font-size:1.15rem; }
    .dr-stats { gap:0.6rem; }
    .dr-stat-number { font-size:1.7rem; }
    .dr-tabs { overflow-x:auto; flex-wrap:nowrap; scrollbar-width:none; }
    .dr-tabs::-webkit-scrollbar { display:none; }
    .dr-tab { white-space:nowrap; }
    .dr-toolbar { flex-direction:column; align-items:flex-start; }
    .dr-search-wrap { max-width:100%; }
    .dr-table thead th:nth-child(3),
    .dr-table thead th:nth-child(6),
    .dr-table thead th:nth-child(7),
    .dr-table tbody td:nth-child(3),
    .dr-table tbody td:nth-child(6),
    .dr-table tbody td:nth-child(7) { display:none; }
}
</style>

<!-- Page Header -->
<div class="dr-page-header">
    <h1 class="dr-page-title">
        <i class="bi bi-person-badge"></i>
        Delivery Agent Applications
        <small>KYC review &amp; onboarding approval</small>
    </h1>
</div>

<!-- Toast -->
<% if (actionMsg != null && !actionMsg.isBlank()) {
   String _tt     = actionType;
   // BUG FIX: "danger" can be a rejection OR a system error — distinguish by message content.
   boolean _isReject = "danger".equals(_tt) && actionMsg.contains("REJECTED");
   String _tTitle = "success".equals(_tt) ? "Application Approved"
                  : (_isReject        ? "Application Rejected"
                                      : "Action Failed");
   String _tIcon  = "success".equals(_tt) ? "bi-check-circle-fill"
                  : (_isReject        ? "bi-x-circle-fill"
                                      : "bi-exclamation-triangle-fill");
   String _tBadge = "success".equals(_tt) ? "Approved"
                  : (_isReject        ? "Rejected"
                                      : "Error");
   String _tFilt  = "success".equals(_tt) ? "APPROVED"
                  : (_isReject        ? "REJECTED"
                                      : "ALL");
   // BUG FIX: escape message to prevent XSS
   String _tMsg   = actionMsg.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;");
%>
<div class="dr-toast-wrap" id="drToastWrap">
    <div class="dr-toast" role="alert" aria-live="polite">
        <div class="dr-toast-accent <%= _tt %>"></div>
        <div class="dr-toast-body">
            <div class="dr-toast-icon <%= _tt %>"><i class="bi <%= _tIcon %>"></i></div>
            <div class="dr-toast-content">
                <div class="dr-toast-header">
                    <span class="dr-toast-title <%= _tt %>"><%= _tTitle %></span>
                    <span class="dr-toast-badge <%= _tt %>"><%= _tBadge %></span>
                    <button class="dr-toast-close" onclick="drDismissToast()" aria-label="Dismiss">&#x2715;</button>
                </div>
                <p class="dr-toast-msg"><%= _tMsg %></p>
            </div>
        </div>
        <div class="dr-toast-footer">
            <span class="dr-toast-meta"><i class="bi bi-clock"></i>&nbsp;Just now</span>
            <span class="dr-toast-meta"><i class="bi bi-person-badge"></i>&nbsp;KYC review</span>
            <div class="dr-toast-actions">
                <button class="dr-toast-btn" onclick="drDismissToast()">Dismiss</button>
                <a href="DeliveryAgentReview?filter=<%= _tFilt %>"
                   class="dr-toast-btn primary <%= _tt %> ajax-link">
                    <i class="bi bi-funnel"></i> View <%= _tBadge %>
                </a>
            </div>
        </div>
        <div class="dr-progress-wrap">
            <div class="dr-progress-bar <%= _tt %>"></div>
        </div>
    </div>
</div>
<script>
(function(){
    var wrap = document.getElementById('drToastWrap');
    var timer = setTimeout(function(){ drDismissToast(); }, 5000);
    window.drDismissToast = function(){
        clearTimeout(timer);
        if (!wrap) return;
        wrap.style.transition = 'opacity .3s ease, transform .3s ease, max-height .4s ease, margin .4s ease';
        wrap.style.opacity = '0'; wrap.style.transform = 'translateY(-8px)';
        wrap.style.maxHeight = '0'; wrap.style.overflow = 'hidden'; wrap.style.marginBottom = '0';
        setTimeout(function(){ if(wrap && wrap.parentNode) wrap.parentNode.removeChild(wrap); }, 420);
    };
})();
</script>
<% } %>

<!-- DB Error -->
<% if (dbError != null) { %>
<div class="dr-error-alert"><i class="bi bi-database-exclamation"></i> Database error: <%= dbError %></div>
<% } %>

<!-- Stats Row -->
<div class="dr-stats">
    <div class="dr-stat-card all">
        <i class="bi bi-grid-3x3-gap dr-stat-icon"></i>
        <div class="dr-stat-number"><%= cntAll %></div>
        <div class="dr-stat-label">Total</div>
    </div>
    <div class="dr-stat-card pending">
        <i class="bi bi-hourglass-split dr-stat-icon"></i>
        <div class="dr-stat-number"><%= cntPending %></div>
        <div class="dr-stat-label">Pending</div>
    </div>
    <div class="dr-stat-card approved">
        <i class="bi bi-check-circle dr-stat-icon"></i>
        <div class="dr-stat-number"><%= cntApproved %></div>
        <div class="dr-stat-label">Approved</div>
    </div>
    <div class="dr-stat-card rejected">
        <i class="bi bi-x-circle dr-stat-icon"></i>
        <div class="dr-stat-number"><%= cntRejected %></div>
        <div class="dr-stat-label">Rejected</div>
    </div>
</div>

<!-- Filter Tabs -->
<div class="dr-tabs">
    <a href="DeliveryAgentReview?filter=ALL"      class="dr-tab all      ajax-link <%= "ALL".equals(filterParam)      ? "active" : "" %>"><i class="bi bi-grid-3x3-gap"></i>   All      <span class="tab-badge"><%= cntAll %></span></a>
    <a href="DeliveryAgentReview?filter=PENDING"  class="dr-tab pending  ajax-link <%= "PENDING".equals(filterParam)  ? "active" : "" %>"><i class="bi bi-hourglass-split"></i> Pending  <span class="tab-badge"><%= cntPending %></span></a>
    <a href="DeliveryAgentReview?filter=APPROVED" class="dr-tab approved ajax-link <%= "APPROVED".equals(filterParam) ? "active" : "" %>"><i class="bi bi-check-circle"></i>    Approved <span class="tab-badge"><%= cntApproved %></span></a>
    <a href="DeliveryAgentReview?filter=REJECTED" class="dr-tab rejected ajax-link <%= "REJECTED".equals(filterParam) ? "active" : "" %>"><i class="bi bi-x-circle"></i>        Rejected <span class="tab-badge"><%= cntRejected %></span></a>
</div>

<!-- Toolbar -->
<div class="dr-toolbar">
    <div class="dr-search-wrap">
        <i class="bi bi-search"></i>
        <input type="text" id="drSearchInput" class="dr-search-input"
               placeholder="Search name, mobile, username, vehicle…"
               oninput="drFilterTable(this.value)">
    </div>
    <span class="dr-row-count">Showing <strong id="drRowCount"><%= registrations.size() %></strong> record(s)</span>
</div>

<!-- Table -->
<div class="dr-table-wrap">
<% if (registrations.isEmpty()) { %>
    <div class="dr-empty">
        <i class="bi bi-inbox"></i>
        <p>No applications found for the selected filter.</p>
    </div>
<% } else { %>
    <table class="dr-table" id="drTable">
        <thead>
            <tr>
                <th>#</th>
                <th><i class="bi bi-person"></i>Agent</th>
                <th><i class="bi bi-at"></i>Username</th>
                <th><i class="bi bi-phone"></i>Mobile</th>
                <th><i class="bi bi-truck"></i>Vehicle</th>
                <th><i class="bi bi-geo-alt"></i>Zone</th>
                <th><i class="bi bi-calendar3"></i>Submitted</th>
                <th><i class="bi bi-circle-half"></i>Status</th>
                <th style="text-align:center;">Action</th>
            </tr>
        </thead>
        <tbody>
        <%
            int rowNum = 0;
            for (DeliveryRegistration reg : registrations) {
                rowNum++;
                String initials = "";
                if (reg.getFirstName() != null && !reg.getFirstName().isEmpty()) initials += reg.getFirstName().charAt(0);
                if (reg.getLastName()  != null && !reg.getLastName().isEmpty())  initials += reg.getLastName().charAt(0);
                String submittedDisplay = reg.getSubmittedAt() != null
                    ? reg.getSubmittedAt().substring(0, 16).replace("T"," ") : "—";
                String vehicleDisplay = ((reg.getVehicleBrand() != null ? reg.getVehicleBrand() : "")
                    + " " + (reg.getVehicleModel() != null ? reg.getVehicleModel() : "")).trim();
                if (vehicleDisplay.isEmpty()) vehicleDisplay = "—";
                String zoneDisplay = reg.getDeliveryZone() != null
                    ? (reg.getDeliveryZone().length() > 30 ? reg.getDeliveryZone().substring(0,27)+"…" : reg.getDeliveryZone()) : "—";
        %>
            <tr data-search="<%= (reg.getFullName()+" "+reg.getMobile()+" "+reg.getUsername()+" "+vehicleDisplay+" "+reg.getDeliveryZone()).toLowerCase() %>">
                <td style="color:var(--text-muted);font-size:0.82rem;"><%= rowNum %></td>
                <td>
                    <div class="dr-agent-cell">
                        <div class="dr-avatar"><%= initials.toUpperCase() %></div>
                        <div>
                            <div class="dr-agent-name"><%= reg.getFullName() %></div>
                            <div class="dr-agent-sub"><%= reg.getEmail() != null ? reg.getEmail() : "" %></div>
                        </div>
                    </div>
                </td>
                <td style="font-family:monospace;font-size:0.83rem;color:var(--text-mid);"><%= reg.getUsername() %></td>
                <td style="font-size:0.88rem;"><%= reg.getMobile() %></td>
                <td>
                    <div style="font-size:0.87rem;"><%= vehicleDisplay %></div>
                    <div style="font-size:0.75rem;color:var(--text-muted);">
                        <%= reg.getVehicleType() != null ? reg.getVehicleType() : "" %>
                        <% if (reg.getVehicleRegNumber() != null && !reg.getVehicleRegNumber().isBlank()) { %>&nbsp;·&nbsp;<%= reg.getVehicleRegNumber() %><% } %>
                    </div>
                </td>
                <td style="font-size:0.85rem;"><%= zoneDisplay %></td>
                <td style="font-size:0.8rem;color:var(--text-muted);white-space:nowrap;"><%= submittedDisplay %></td>
                <td>
                    <span class="status-badge <%= reg.getStatus() %>">
                        <% if ("PENDING".equals(reg.getStatus())) { %><i class="bi bi-hourglass-split"></i>
                        <% } else if ("APPROVED".equals(reg.getStatus())) { %><i class="bi bi-check-circle-fill"></i>
                        <% } else { %><i class="bi bi-x-circle-fill"></i><% } %>
                        <%= reg.getStatus() %>
                    </span>
                </td>
                <td style="text-align:center;">
                    <a href="DeliveryAgentDetail?id=<%= reg.getId() %>" class="btn-view ajax-link">
                        <i class="bi bi-eye"></i> Review
                    </a>
                </td>
            </tr>
        <% } %>
        </tbody>
    </table>
<% } %>
</div>

<script>
function drFilterTable(q) {
    q = q.toLowerCase().trim();
    const rows = document.querySelectorAll('#drTable tbody tr');
    let visible = 0;
    rows.forEach(function(r){
        const match = !q || r.dataset.search.includes(q);
        r.style.display = match ? '' : 'none';
        if (match) visible++;
    });
    const cnt = document.getElementById('drRowCount');
    if (cnt) cnt.textContent = visible;
}

(function reBindAjaxLinks(){
    if (typeof window.dashboardLoadFragment !== 'function') return;
    document.querySelectorAll('.ajax-link').forEach(function(link){
        if (link.dataset.ajaxBound) return;
        link.dataset.ajaxBound = '1';
        link.addEventListener('click', function(e){
            e.preventDefault();
            window.dashboardLoadFragment(this.getAttribute('href'), this.textContent.trim(), this);
        });
    });
})();
</script>
