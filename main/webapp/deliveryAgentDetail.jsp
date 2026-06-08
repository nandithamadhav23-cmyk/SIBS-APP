<%@ page contentType="text/html; charset=UTF-8" %>
<%@ page import="com.util.DeliveryRegistration, com.DAO.DeliveryRegistrationDAO, com.util.DBConnection, java.sql.Connection" %>
<%--
  deliveryAgentDetail.jsp
  ─────────────────────────────────────────────────────────────────────────────
  Full KYC detail view for a single delivery-agent application.
  • Shows every field from delivery_agent_registrations
  • Renders uploaded documents / images (served via AdminDocServlet)
  • Approve / Reject actions post to AdminDeliveryReviewServlet
  • Loaded AJAX-style into dashboard.jsp#mainContent — NO <html>/<body> tags.

  URL param:  id  (INT, required)
  SERVLET:    AdminDeliveryReviewServlet   → handles action=approve / reject
  DOC SERVE:  AdminDocServlet             → serves files from uploadRootDir
--%>
<%
    /* ── Auth guard ────────────────────────────────────────────────────────── */
    String _role = (session != null) ? (String) session.getAttribute("role") : null;
    if (_role == null || !"admin".equalsIgnoreCase(_role)) {
        out.print("<p style='color:#e74c3c;font-family:Times New Roman;padding:2rem;'>"
                + "<i class='bi bi-lock me-2'></i>Access denied.</p>");
        return;
    }

    /* ── Load registration ──────────────────────────────────────────────────── */
    DeliveryRegistration reg = null;
    String loadError = null;
    int regId = -1;

    try {
        regId = Integer.parseInt(request.getParameter("id"));
    } catch (Exception ignored) {}

    if (regId <= 0) {
        loadError = "Invalid or missing application ID.";
    } else {
        try (Connection conn = DBConnection.getConnection()) {
            reg = new DeliveryRegistrationDAO(conn).getById(regId);
            if (reg == null) loadError = "Application #" + regId + " not found.";
        } catch (Exception ex) {
            loadError = "Database error: " + ex.getMessage();
        }
    }
%>

<style>
/* ── Scoped styles — uses dashboard.jsp CSS vars ──────────────────────────── */
.dd-back {
    display: inline-flex;
    align-items: center;
    gap: 0.4rem;
    font-family: 'Times New Roman', Times, serif;
    font-size: 0.85rem;
    color: var(--text-muted);
    text-decoration: none;
    margin-bottom: 1.2rem;
    transition: color 0.2s;
    cursor: pointer;
    border: none;
    background: none;
    padding: 0;
}
.dd-back:hover { color: var(--primary); }

.dd-header {
    background: var(--bg-white);
    border: 1px solid var(--border);
    border-top: 5px solid var(--accent);
    border-radius: 4px;
    padding: 1.8rem 2rem;
    display: flex;
    align-items: flex-start;
    gap: 1.5rem;
    margin-bottom: 1.5rem;
    box-shadow: var(--shadow-sm);
    flex-wrap: wrap;
}
.dd-profile-photo {
    width: 90px; height: 90px;
    border-radius: 50%;
    object-fit: cover;
    border: 3px solid var(--accent);
    flex-shrink: 0;
    cursor: pointer;
    transition: box-shadow 0.2s;
}
.dd-profile-photo:hover { box-shadow: 0 0 0 4px rgba(200,169,110,0.3); }
.dd-profile-initials {
    width: 90px; height: 90px;
    border-radius: 50%;
    background: var(--accent-light);
    border: 3px solid var(--accent);
    display: flex;
    align-items: center;
    justify-content: center;
    font-family: 'Times New Roman', Times, serif;
    font-size: 2rem;
    font-weight: 700;
    color: var(--primary);
    flex-shrink: 0;
}
.dd-header-info { flex: 1; min-width: 200px; }
.dd-agent-name {
    font-family: 'Times New Roman', Times, serif;
    font-size: 1.6rem;
    font-weight: 700;
    color: var(--text-dark);
    margin-bottom: 0.25rem;
}
.dd-meta {
    font-size: 0.85rem;
    color: var(--text-muted);
    display: flex;
    flex-wrap: wrap;
    gap: 0.4rem 1.2rem;
    margin-bottom: 0.5rem;
}
.dd-meta span { display: flex; align-items: center; gap: 0.3rem; }
.dd-header-actions {
    display: flex;
    flex-direction: column;
    gap: 0.6rem;
    min-width: 180px;
    align-self: center;
}

/* ── Status badges ──────────────────────────────────────────────────────────── */
.status-badge {
    display: inline-flex;
    align-items: center;
    gap: 0.35rem;
    padding: 0.3rem 0.9rem;
    border-radius: 20px;
    font-size: 0.73rem;
    font-weight: 700;
    letter-spacing: 1.2px;
    text-transform: uppercase;
}
.status-badge.PENDING  { background:#fff3e0; color:#e67e22; border:1px solid #f5cba7; }
.status-badge.APPROVED { background:#e8f8ee; color:#27ae60; border:1px solid #a9dfbf; }
.status-badge.REJECTED { background:#fdecea; color:#e74c3c; border:1px solid #f5b7b1; }

/* ── Section cards ──────────────────────────────────────────────────────────── */
.dd-section {
    background: var(--bg-white);
    border: 1px solid var(--border);
    border-radius: 4px;
    margin-bottom: 1.4rem;
    box-shadow: var(--shadow-sm);
    overflow: hidden;
}
.dd-section-head {
    background: var(--primary);
    padding: 0.75rem 1.4rem;
    display: flex;
    align-items: center;
    gap: 0.6rem;
    color: rgba(255,255,255,0.9);
    font-family: 'Times New Roman', Times, serif;
    font-size: 0.78rem;
    letter-spacing: 2px;
    text-transform: uppercase;
    font-weight: 600;
}
.dd-section-head i { color: var(--accent); font-size: 1rem; }
.dd-section-body { padding: 1.4rem 1.6rem; }

/* ── Field grid ─────────────────────────────────────────────────────────────── */
.dd-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
    gap: 1.2rem 2rem;
}
.dd-field label {
    display: block;
    font-family: 'Times New Roman', Times, serif;
    font-size: 0.7rem;
    letter-spacing: 1.5px;
    text-transform: uppercase;
    color: var(--text-muted);
    margin-bottom: 3px;
}
.dd-field span {
    font-family: 'Times New Roman', Times, serif;
    font-size: 0.92rem;
    color: var(--text-dark);
    word-break: break-word;
}
.dd-field span.empty { color: var(--text-muted); font-style: italic; }

/* ── Document gallery ───────────────────────────────────────────────────────── */
.dd-doc-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
    gap: 1rem;
}
.dd-doc-card {
    border: 1px solid var(--border);
    border-radius: 4px;
    overflow: hidden;
    background: var(--bg-off);
    transition: box-shadow 0.2s;
}
.dd-doc-card:hover { box-shadow: var(--shadow-md); }
.dd-doc-thumb {
    width: 100%;
    height: 140px;
    object-fit: cover;
    cursor: pointer;
    display: block;
    background: var(--bg-white);
}
.dd-doc-thumb-placeholder {
    width: 100%;
    height: 140px;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    background: var(--accent-light);
    color: var(--primary);
    cursor: pointer;
    text-decoration: none;
    transition: background 0.2s;
}
.dd-doc-thumb-placeholder:hover { background: #f0e0c0; }
.dd-doc-thumb-placeholder i { font-size: 2.5rem; color: var(--accent); }
.dd-doc-thumb-placeholder span { font-size: 0.72rem; color: var(--text-muted); margin-top: 4px; font-family:'Times New Roman',serif; }
.dd-doc-footer {
    padding: 0.5rem 0.75rem;
    display: flex;
    align-items: center;
    justify-content: space-between;
    border-top: 1px solid var(--border);
}
.dd-doc-label {
    font-family: 'Times New Roman', Times, serif;
    font-size: 0.73rem;
    color: var(--text-muted);
    letter-spacing: 0.5px;
}
.dd-doc-open {
    font-size: 0.72rem;
    color: var(--primary);
    text-decoration: none;
    font-family:'Times New Roman',serif;
    display: flex;
    align-items: center;
    gap: 0.25rem;
    border: 1px solid var(--border);
    padding: 2px 8px;
    border-radius: 2px;
    transition: all 0.2s;
}
.dd-doc-open:hover { background: var(--primary); color: #fff; }
.dd-doc-missing {
    width: 100%;
    height: 140px;
    display: flex;
    align-items: center;
    justify-content: center;
    background: var(--bg-off);
    color: var(--border);
    font-size: 2rem;
}

/* ── Action panel ───────────────────────────────────────────────────────────── */
.dd-action-panel {
    background: var(--bg-white);
    border: 1px solid var(--border);
    border-radius: 4px;
    padding: 1.8rem 2rem;
    box-shadow: var(--shadow-sm);
    margin-bottom: 1.4rem;
}
.dd-action-title {
    font-family: 'Times New Roman', Times, serif;
    font-size: 1rem;
    font-weight: 700;
    color: var(--text-dark);
    margin-bottom: 1rem;
    display: flex;
    align-items: center;
    gap: 0.5rem;
}
.dd-remarks-input {
    width: 100%;
    font-family: 'Times New Roman', Times, serif;
    font-size: 0.9rem;
    border: 1px solid var(--border);
    border-radius: 3px;
    padding: 0.65rem 1rem;
    min-height: 80px;
    resize: vertical;
    outline: none;
    color: var(--text-dark);
    background: var(--bg-white);
    transition: border-color 0.2s;
    margin-bottom: 1rem;
}
.dd-remarks-input:focus { border-color: var(--accent); }
.dd-btn-approve {
    font-family: 'Times New Roman', Times, serif;
    font-size: 0.85rem;
    letter-spacing: 1px;
    padding: 0.6rem 1.8rem;
    background: #27ae60;
    color: #fff;
    border: none;
    border-radius: 3px;
    cursor: pointer;
    transition: background 0.2s;
    display: inline-flex;
    align-items: center;
    gap: 0.5rem;
    margin-right: 0.8rem;
}
.dd-btn-approve:hover { background: #1e8449; }
.dd-btn-approve:disabled { background: #aaa; cursor: not-allowed; }
.dd-btn-reject {
    font-family: 'Times New Roman', Times, serif;
    font-size: 0.85rem;
    letter-spacing: 1px;
    padding: 0.6rem 1.8rem;
    background: #e74c3c;
    color: #fff;
    border: none;
    border-radius: 3px;
    cursor: pointer;
    transition: background 0.2s;
    display: inline-flex;
    align-items: center;
    gap: 0.5rem;
}
.dd-btn-reject:hover { background: #c0392b; }
.dd-btn-reject:disabled { background: #aaa; cursor: not-allowed; }

/* ── Reviewed banner ────────────────────────────────────────────────────────── */
.dd-reviewed-banner {
    border-radius: 4px;
    padding: 1rem 1.4rem;
    margin-bottom: 1rem;
    font-family: 'Times New Roman', Times, serif;
    font-size: 0.88rem;
    display: flex;
    align-items: flex-start;
    gap: 0.6rem;
}
.dd-reviewed-banner.approved { background:#e8f8ee; border:1px solid #a9dfbf; color:#1e8449; }
.dd-reviewed-banner.rejected { background:#fdecea; border:1px solid #f5b7b1; color:#c0392b; }

/* ── Lightbox ───────────────────────────────────────────────────────────────── */
.dd-lightbox {
    display: none;
    position: fixed;
    inset: 0;
    background: rgba(10,10,20,0.88);
    z-index: 9999;
    align-items: center;
    justify-content: center;
    flex-direction: column;
}
.dd-lightbox.open { display: flex; }
.dd-lightbox img {
    max-width: 90vw;
    max-height: 82vh;
    border-radius: 4px;
    box-shadow: 0 8px 40px rgba(0,0,0,0.6);
    object-fit: contain;
}
.dd-lightbox-label {
    color: rgba(255,255,255,0.7);
    font-family: 'Times New Roman', Times, serif;
    font-size: 0.85rem;
    margin-top: 0.75rem;
    letter-spacing: 0.5px;
}
.dd-lightbox-close {
    position: absolute;
    top: 1.5rem; right: 2rem;
    color: rgba(255,255,255,0.8);
    font-size: 1.8rem;
    cursor: pointer;
    background: none;
    border: none;
    line-height: 1;
    transition: color 0.2s;
}
.dd-lightbox-close:hover { color: var(--accent); }

/* ── Confirm modal ──────────────────────────────────────────────────────────── */
.dd-confirm-overlay {
    display: none;
    position: fixed;
    inset: 0;
    background: rgba(10,10,20,0.55);
    z-index: 8888;
    align-items: center;
    justify-content: center;
}
.dd-confirm-overlay.open { display: flex; }
.dd-confirm-box {
    background: var(--bg-white);
    border-radius: 6px;
    padding: 2rem 2.2rem;
    max-width: 440px;
    width: 90%;
    box-shadow: 0 10px 40px rgba(0,0,0,0.25);
    font-family: 'Times New Roman', Times, serif;
    text-align: center;
}
.dd-confirm-icon { font-size: 2.8rem; margin-bottom: 0.75rem; }
.dd-confirm-title { font-size: 1.15rem; font-weight: 700; color: var(--text-dark); margin-bottom: 0.5rem; }
.dd-confirm-msg   { font-size: 0.88rem; color: var(--text-muted); margin-bottom: 1.5rem; }
.dd-confirm-btns  { display: flex; gap: 1rem; justify-content: center; }

/* ── MOBILE PATCH ─────────────────────────────────────────────────────────── */
@media (max-width: 900px) {
    .dd-header { flex-direction: column; align-items: flex-start; gap: 1rem; }
    .dd-header-actions {
        flex-direction: row;
        flex-wrap: wrap;
        min-width: unset;
        width: 100%;
    }
    .dd-btn-approve, .dd-btn-reject { flex: 1; justify-content: center; }
    .dd-grid { grid-template-columns: repeat(2, 1fr); }
    .dd-doc-grid { grid-template-columns: repeat(3, 1fr); }
}

@media (max-width: 600px) {
    /* Header */
    .dd-header { padding: 1.2rem; gap: 0.9rem; }
    .dd-profile-photo,
    .dd-profile-initials { width: 72px; height: 72px; font-size: 1.6rem; }
    .dd-agent-name { font-size: 1.25rem; }
    .dd-meta { gap: 0.3rem 0.8rem; font-size: 0.8rem; }
    .dd-header-actions { flex-direction: column; }
    .dd-btn-approve, .dd-btn-reject { width: 100%; margin-right: 0; font-size: 0.82rem; }

    /* Sections */
    .dd-section-body { padding: 1rem; }
    .dd-section-head { font-size: 0.72rem; padding: 0.65rem 1rem; }
    .dd-grid { grid-template-columns: 1fr; gap: 0.9rem 0; }

    /* Doc gallery: 2 columns on small phones */
    .dd-doc-grid { grid-template-columns: repeat(2, 1fr); }
    .dd-doc-thumb,
    .dd-doc-thumb-placeholder,
    .dd-doc-missing { height: 110px; }

    /* Action panel */
    .dd-action-panel { padding: 1.2rem 1rem; }
    .dd-btn-approve { margin-right: 0; margin-bottom: 0.6rem; width: 100%; }
    .dd-btn-reject  { width: 100%; }

    /* Back link */
    .dd-back { font-size: 0.8rem; }

    /* Confirmation modal */
    .dd-confirm-box { padding: 1.4rem 1.2rem; }
    .dd-confirm-btns { flex-direction: column; }
    .dd-confirm-btns button { width: 100%; }

    /* Lightbox image */
    .dd-lightbox img { max-width: 95vw; max-height: 70vh; }
    .dd-lightbox-close { top: 0.75rem; right: 1rem; font-size: 1.5rem; }

    /* Reviewed banner */
    .dd-reviewed-banner { font-size: 0.82rem; padding: 0.75rem 1rem; }

    /* Fields */
    .dd-field label { font-size: 0.65rem; }
    .dd-field span  { font-size: 0.87rem; }
}
</style>

<%-- ── Error state ──────────────────────────────────────────────────────────── --%>
<% if (loadError != null) { %>
<div style="background:#fdecea; border:1px solid #f5b7b1; border-radius:4px; padding:1.4rem 1.8rem; font-family:'Times New Roman',serif; color:#c0392b; display:flex; align-items:center; gap:0.6rem;">
    <i class="bi bi-exclamation-triangle-fill" style="font-size:1.3rem;"></i>
    <%= loadError %>
</div>
<% } else { %>

<%-- ── Helpers ───────────────────────────────────────────────────────────────── --%>
<%!
    private static String safe(String v) {
        return (v != null && !v.isBlank()) ? v : null;
    }
    private static String safeDisplay(String v) {
        return (v != null && !v.isBlank()) ? v : "—";
    }
%>

<!-- Back button -->

<button class="dd-back" onclick="(function(){
    var link = document.querySelector('.sidebar-nav-link[href*=\'DeliveryAgentReview\']');
    if (typeof window.dashboardLoadFragment === 'function') {
        window.dashboardLoadFragment('DeliveryAgentReview?filter=PENDING', 'Agent Applications', link);
    } else {
        window.location.href = 'DeliveryAgentReview?filter=PENDING';
    }
})()">
    <i class="bi bi-arrow-left"></i> Back to Applications
</button>
<!-- ── Header card ──────────────────────────────────────────────────────────── -->
<%
    String initials = "";
    if (reg.getFirstName() != null && !reg.getFirstName().isEmpty()) initials += reg.getFirstName().charAt(0);
    if (reg.getLastName()  != null && !reg.getLastName().isEmpty())  initials += reg.getLastName().charAt(0);
    boolean hasPhoto = safe(reg.getProfilePhotoPath()) != null;
    boolean isApproved = "APPROVED".equals(reg.getStatus());
    boolean isRejected = "REJECTED".equals(reg.getStatus());
    boolean isPending  = "PENDING".equals(reg.getStatus());
%>
<div class="dd-header">
    <% if (hasPhoto) { %>
        <img src="<%= docUrl(reg.getProfilePhotoPath()) %>"
             class="dd-profile-photo"
             onclick="ddOpenLightbox('<%= docUrl(reg.getProfilePhotoPath()) %>','Profile Photo')"
             onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';"
             alt="Profile Photo">
        <div class="dd-profile-initials" style="display:none;"><%= initials.toUpperCase() %></div>
    <% } else { %>
        <div class="dd-profile-initials"><%= initials.toUpperCase() %></div>
    <% } %>

    <div class="dd-header-info">
        <div class="dd-agent-name"><%= reg.getFullName() %></div>
        <div class="dd-meta">
            <span><i class="bi bi-at"></i> <%= safeDisplay(reg.getUsername()) %></span>
            <span><i class="bi bi-telephone"></i> <%= safeDisplay(reg.getMobile()) %></span>
            <span><i class="bi bi-envelope"></i> <%= safeDisplay(reg.getEmail()) %></span>
        </div>
        <div>
            <span class="status-badge <%= reg.getStatus() %>">
                <% if (isPending) { %><i class="bi bi-hourglass-split"></i>
                <% } else if (isApproved) { %><i class="bi bi-check-circle-fill"></i>
                <% } else { %><i class="bi bi-x-circle-fill"></i><% } %>
                <%= reg.getStatus() %>
            </span>
            <span style="font-family:'Times New Roman',serif; font-size:0.8rem; color:var(--text-muted); margin-left:1rem;">
                Applied: <%= safeDisplay(reg.getSubmittedAt() != null ? reg.getSubmittedAt().substring(0,16).replace("T"," ") : null) %>
            </span>
            <% if (reg.getReviewedAt() != null) { %>
            <span style="font-family:'Times New Roman',serif; font-size:0.8rem; color:var(--text-muted); margin-left:1rem;">
                Reviewed: <%= reg.getReviewedAt().substring(0,16).replace("T"," ") %>
            </span>
            <% } %>
        </div>
    </div>

    <div class="dd-header-actions">
        <span style="font-family:'Times New Roman',serif; font-size:0.78rem; color:var(--text-muted); letter-spacing:1px; text-transform:uppercase;">Application #<%= reg.getId() %></span>
        <% if (isPending) { %>
            <button class="dd-btn-approve" onclick="ddConfirm('approve')">
                <i class="bi bi-check-circle"></i> Approve
            </button>
            <button class="dd-btn-reject" onclick="ddConfirm('reject')">
                <i class="bi bi-x-circle"></i> Reject
            </button>
        <% } else { %>
            <button class="dd-btn-approve" onclick="ddConfirm('approve')" <%= isApproved ? "disabled" : "" %>>
                <i class="bi bi-check-circle"></i> Approve
            </button>
            <button class="dd-btn-reject" onclick="ddConfirm('reject')" <%= isRejected ? "disabled" : "" %>>
                <i class="bi bi-x-circle"></i> Reject
            </button>
        <% } %>
    </div>
</div>

<!-- ── Already-reviewed remarks ─────────────────────────────────────────────── -->
<% if ((isApproved || isRejected) && safe(reg.getAdminRemarks()) != null) { %>
<div class="dd-reviewed-banner <%= isApproved ? "approved" : "rejected" %>">
    <i class="bi bi-chat-square-text-fill" style="margin-top:2px; flex-shrink:0;"></i>
    <div>
        <strong>Admin Remarks:</strong> <%= reg.getAdminRemarks() %>
    </div>
</div>
<% } %>

<!-- ════════════════════════════════════════════════════════════════════════════
     SECTION 1 — Personal Information
══════════════════════════════════════════════════════════════════════════════ -->
<div class="dd-section">
    <div class="dd-section-head"><i class="bi bi-person-vcard"></i> Personal Information</div>
    <div class="dd-section-body">
        <div class="dd-grid">
            <div class="dd-field"><label>First Name</label><span><%= safeDisplay(reg.getFirstName()) %></span></div>
            <div class="dd-field"><label>Middle Name</label><span class="<%= safe(reg.getMiddleName())==null?"empty":"" %>"><%= safeDisplay(reg.getMiddleName()) %></span></div>
            <div class="dd-field"><label>Last Name</label><span><%= safeDisplay(reg.getLastName()) %></span></div>
            <div class="dd-field"><label>Date of Birth</label><span><%= safeDisplay(reg.getDob()) %></span></div>
            <div class="dd-field"><label>Gender</label><span><%= safeDisplay(reg.getGender()) %></span></div>
            <div class="dd-field"><label>Blood Group</label><span class="<%= safe(reg.getBloodGroup())==null?"empty":"" %>"><%= safeDisplay(reg.getBloodGroup()) %></span></div>
            <div class="dd-field"><label>Username</label><span style="font-family:monospace;"><%= safeDisplay(reg.getUsername()) %></span></div>
            <div class="dd-field"><label>Mobile</label><span><%= safeDisplay(reg.getMobile()) %></span></div>
            <div class="dd-field"><label>Email</label><span><%= safeDisplay(reg.getEmail()) %></span></div>
            <div class="dd-field"><label>Alternate Mobile</label><span class="<%= safe(reg.getAltMobile())==null?"empty":"" %>"><%= safeDisplay(reg.getAltMobile()) %></span></div>
        </div>
    </div>
</div>

<!-- ════════════════════════════════════════════════════════════════════════════
     SECTION 2 — Address
══════════════════════════════════════════════════════════════════════════════ -->
<div class="dd-section">
    <div class="dd-section-head"><i class="bi bi-geo-alt"></i> Address</div>
    <div class="dd-section-body">
        <div class="dd-grid">
            <div class="dd-field"><label>Address Line 1</label><span><%= safeDisplay(reg.getAddressLine1()) %></span></div>
            <div class="dd-field"><label>Address Line 2</label><span><%= safeDisplay(reg.getAddressLine2()) %></span></div>
            <div class="dd-field"><label>Landmark</label><span class="<%= safe(reg.getLandmark())==null?"empty":"" %>"><%= safeDisplay(reg.getLandmark()) %></span></div>
            <div class="dd-field"><label>City</label><span><%= safeDisplay(reg.getCity()) %></span></div>
            <div class="dd-field"><label>State</label><span><%= safeDisplay(reg.getState()) %></span></div>
            <div class="dd-field"><label>Pincode</label><span><%= safeDisplay(reg.getPincode()) %></span></div>
        </div>
    </div>
</div>

<!-- ════════════════════════════════════════════════════════════════════════════
     SECTION 3 — KYC Identity Documents
══════════════════════════════════════════════════════════════════════════════ -->
<div class="dd-section">
    <div class="dd-section-head"><i class="bi bi-shield-check"></i> KYC — Identity Details</div>
    <div class="dd-section-body">
        <div class="dd-grid" style="margin-bottom:1.4rem;">
            <div class="dd-field"><label>Aadhaar Number</label><span style="font-family:monospace; letter-spacing:2px;"><%= safeDisplay(reg.getAadhaarNumber()) %></span></div>
            <div class="dd-field"><label>Name on Aadhaar</label><span><%= safeDisplay(reg.getAadhaarName()) %></span></div>
            <div class="dd-field"><label>PAN Number</label><span style="font-family:monospace; text-transform:uppercase;"><%= safeDisplay(reg.getPanNumber()) %></span></div>
            <div class="dd-field"><label>DL Number</label><span style="font-family:monospace;"><%= safeDisplay(reg.getDlNumber()) %></span></div>
            <div class="dd-field"><label>DL Issue Date</label><span class="<%= safe(reg.getDlIssueDate())==null?"empty":"" %>"><%= safeDisplay(reg.getDlIssueDate()) %></span></div>
            <div class="dd-field"><label>DL Expiry Date</label><span><%= safeDisplay(reg.getDlExpiryDate()) %></span></div>
            <div class="dd-field"><label>Address Proof Type</label><span><%= safeDisplay(reg.getAddressProofType()) %></span></div>
        </div>

        <!-- KYC Document Gallery -->
        <%!
            // Upload root — must match AdminDeliveryReviewServlet.uploadRootDir and
            // DeliveryRegisterServlet. We strip this prefix from any absolute path
            // stored in the DB so AdminDocServlet always receives a relative path.
            private static final String UPLOAD_ROOT_WIN  = "C:\\delivery_uploads\\KYC_docs";
            private static final String UPLOAD_ROOT_LIN  = "/var/app/delivery_uploads/KYC_docs";

            private static String toRelativePath(String path) {
                if (path == null) return null;
                // Normalise separators to forward-slash for consistent stripping
                String normalised = path.replace("\\", "/");
                // Strip either known root prefix (Windows or Linux)
                for (String root : new String[]{
                        UPLOAD_ROOT_WIN.replace("\\","/"),
                        UPLOAD_ROOT_LIN }) {
                    if (normalised.startsWith(root)) {
                        normalised = normalised.substring(root.length());
                        break;
                    }
                }
                // Remove any leading slash/backslash left after stripping
                while (normalised.startsWith("/") || normalised.startsWith("\\")) {
                    normalised = normalised.substring(1);
                }
                return normalised;
            }

            private static String docUrl(String path) throws java.io.UnsupportedEncodingException {
                // Always pass a relative path to AdminDocServlet — never the full
                // absolute path, which would expose the server filesystem layout and
                // can cause path-resolution edge cases on Windows.
                String rel = toRelativePath(path);
                return "AdminDocServlet?path=" + java.net.URLEncoder.encode(rel, "UTF-8");
            }

            private static boolean isImage(String path) {
                if (path == null) return false;
                String p = path.toLowerCase();
                return p.endsWith(".jpg")||p.endsWith(".jpeg")||p.endsWith(".png")
                    || p.endsWith(".webp")||p.endsWith(".gif");
            }
        %>
        <%
            String[][] kycDocs = {
                { reg.getAadhaarFrontPath(), "Aadhaar Front" },
                { reg.getAadhaarBackPath(),  "Aadhaar Back"  },
                { reg.getPanImagePath(),      "PAN Card"      },
                { reg.getDlFrontPath(),       "DL Front"      },
                { reg.getDlBackPath(),        "DL Back"       },
                { reg.getAddressProofPath(),  "Address Proof" }
            };
        %>
        <div style="font-family:'Times New Roman',serif; font-size:0.72rem; letter-spacing:1.5px; text-transform:uppercase; color:var(--text-muted); margin-bottom:0.8rem;">Uploaded Documents</div>
        <div class="dd-doc-grid">
        <% for (String[] doc : kycDocs) {
               String docPath = doc[0]; String docLabel = doc[1];
               boolean hasDo = safe(docPath) != null;
        %>
            <div class="dd-doc-card">
                <% if (hasDo && isImage(docPath)) { %>
                    <img src="<%= docUrl(docPath) %>"
                         class="dd-doc-thumb"
                         onclick="ddOpenLightbox('<%= docUrl(docPath) %>','<%= docLabel %>')"
                         onerror="this.style.display='none';"
                         alt="<%= docLabel %>">
                <% } else if (hasDo) { %>
                    <a href="<%= docUrl(docPath) %>" target="_blank" class="dd-doc-thumb-placeholder">
                        <i class="bi bi-file-earmark-text"></i>
                        <span>Open File</span>
                    </a>
                <% } else { %>
                    <div class="dd-doc-missing"><i class="bi bi-image" style="opacity:0.3;"></i></div>
                <% } %>
                <div class="dd-doc-footer">
                    <span class="dd-doc-label"><%= docLabel %></span>
                    <% if (hasDo) { %>
                        <a href="<%= docUrl(docPath) %>" target="_blank" class="dd-doc-open">
                            <i class="bi bi-box-arrow-up-right"></i> Open
                        </a>
                    <% } else { %>
                        <span style="font-size:0.7rem; color:#ccc; font-family:'Times New Roman',serif;">Not uploaded</span>
                    <% } %>
                </div>
            </div>
        <% } %>
        </div>
    </div>
</div>

<!-- ════════════════════════════════════════════════════════════════════════════
     SECTION 4 — Vehicle Details
══════════════════════════════════════════════════════════════════════════════ -->
<div class="dd-section">
    <div class="dd-section-head"><i class="bi bi-truck"></i> Vehicle Details</div>
    <div class="dd-section-body">
        <div class="dd-grid" style="margin-bottom:1.4rem;">
            <div class="dd-field"><label>Vehicle Type</label><span><%= safeDisplay(reg.getVehicleType()) %></span></div>
            <div class="dd-field"><label>Ownership</label><span><%= safeDisplay(reg.getVehicleOwnership()) %></span></div>
            <div class="dd-field"><label>Fuel Type</label><span><%= safeDisplay(reg.getFuelType()) %></span></div>
            <div class="dd-field"><label>Brand</label><span><%= safeDisplay(reg.getVehicleBrand()) %></span></div>
            <div class="dd-field"><label>Model</label><span><%= safeDisplay(reg.getVehicleModel()) %></span></div>
            <div class="dd-field"><label>Year</label><span class="<%= safe(reg.getVehicleYear())==null?"empty":"" %>"><%= safeDisplay(reg.getVehicleYear()) %></span></div>
            <div class="dd-field"><label>Registration No.</label><span class="<%= safe(reg.getVehicleRegNumber())==null?"empty":"" %>" style="font-family:monospace; text-transform:uppercase;"><%= safeDisplay(reg.getVehicleRegNumber()) %></span></div>
            <div class="dd-field"><label>Colour</label><span class="<%= safe(reg.getVehicleColour())==null?"empty":"" %>"><%= safeDisplay(reg.getVehicleColour()) %></span></div>
            <div class="dd-field"><label>Payload Capacity (kg)</label><span class="<%= safe(reg.getPayloadKg())==null?"empty":"" %>"><%= safeDisplay(reg.getPayloadKg()) %></span></div>
            <div class="dd-field" style="grid-column: 1 / -1;"><label>Preferred Delivery Zone</label><span><%= safeDisplay(reg.getDeliveryZone()) %></span></div>
        </div>

        <!-- Vehicle Documents -->
        <%
            String[][] vehDocs = {
                { reg.getRcBookPath(),      "RC Book"      },
                { reg.getVehiclePhotoPath(),"Vehicle Photo"}
            };
        %>
        <div style="font-family:'Times New Roman',serif; font-size:0.72rem; letter-spacing:1.5px; text-transform:uppercase; color:var(--text-muted); margin-bottom:0.8rem;">Vehicle Documents</div>
        <div class="dd-doc-grid" style="grid-template-columns: repeat(auto-fill, minmax(180px,1fr)); max-width:420px;">
        <% for (String[] doc : vehDocs) {
               String docPath = doc[0]; String docLabel = doc[1];
               boolean hasDo = safe(docPath) != null;
        %>
            <div class="dd-doc-card">
                <% if (hasDo && isImage(docPath)) { %>
                    <img src="<%= docUrl(docPath) %>"
                         class="dd-doc-thumb"
                         onclick="ddOpenLightbox('<%= docUrl(docPath) %>','<%= docLabel %>')"
                         onerror="this.style.display='none';"
                         alt="<%= docLabel %>">
                <% } else if (hasDo) { %>
                    <a href="<%= docUrl(docPath) %>" target="_blank" class="dd-doc-thumb-placeholder">
                        <i class="bi bi-file-earmark-text"></i><span>Open File</span>
                    </a>
                <% } else { %>
                    <div class="dd-doc-missing"><i class="bi bi-image" style="opacity:0.3;"></i></div>
                <% } %>
                <div class="dd-doc-footer">
                    <span class="dd-doc-label"><%= docLabel %></span>
                    <% if (hasDo) { %>
                        <a href="<%= docUrl(docPath) %>" target="_blank" class="dd-doc-open"><i class="bi bi-box-arrow-up-right"></i> Open</a>
                    <% } else { %>
                        <span style="font-size:0.7rem; color:#ccc; font-family:'Times New Roman',serif;">Not uploaded</span>
                    <% } %>
                </div>
            </div>
        <% } %>
        </div>
    </div>
</div>

<!-- ════════════════════════════════════════════════════════════════════════════
     SECTION 5 — Insurance & PUC
══════════════════════════════════════════════════════════════════════════════ -->
<div class="dd-section">
    <div class="dd-section-head"><i class="bi bi-file-earmark-medical"></i> Insurance &amp; PUC</div>
    <div class="dd-section-body">
        <div class="dd-grid" style="margin-bottom:1.4rem;">
            <div class="dd-field"><label>Insurance Policy No.</label><span><%= safeDisplay(reg.getInsuranceNumber()) %></span></div>
            <div class="dd-field"><label>Insurance Expiry</label><span><%= safeDisplay(reg.getInsuranceExpiry()) %></span></div>
            <div class="dd-field"><label>PUC Certificate No.</label><span class="<%= safe(reg.getPucNumber())==null?"empty":"" %>"><%= safeDisplay(reg.getPucNumber()) %></span></div>
            <div class="dd-field"><label>PUC Expiry</label><span class="<%= safe(reg.getPucExpiry())==null?"empty":"" %>"><%= safeDisplay(reg.getPucExpiry()) %></span></div>
        </div>
        <%
            String[][] insPucDocs = {
                { reg.getInsuranceCertPath(), "Insurance Certificate" },
                { reg.getPucCertPath(),        "PUC Certificate"      }
            };
        %>
        <div class="dd-doc-grid" style="grid-template-columns: repeat(auto-fill, minmax(180px,1fr)); max-width:420px;">
        <% for (String[] doc : insPucDocs) {
               String docPath = doc[0]; String docLabel = doc[1];
               boolean hasDo = safe(docPath) != null;
        %>
            <div class="dd-doc-card">
                <% if (hasDo && isImage(docPath)) { %>
                    <img src="<%= docUrl(docPath) %>"
                         class="dd-doc-thumb"
                         onclick="ddOpenLightbox('<%= docUrl(docPath) %>','<%= docLabel %>')"
                         onerror="this.style.display='none';"
                         alt="<%= docLabel %>">
                <% } else if (hasDo) { %>
                    <a href="<%= docUrl(docPath) %>" target="_blank" class="dd-doc-thumb-placeholder">
                        <i class="bi bi-file-earmark-text"></i><span>Open File</span>
                    </a>
                <% } else { %>
                    <div class="dd-doc-missing"><i class="bi bi-image" style="opacity:0.3;"></i></div>
                <% } %>
                <div class="dd-doc-footer">
                    <span class="dd-doc-label"><%= docLabel %></span>
                    <% if (hasDo) { %>
                        <a href="<%= docUrl(docPath) %>" target="_blank" class="dd-doc-open"><i class="bi bi-box-arrow-up-right"></i> Open</a>
                    <% } else { %>
                        <span style="font-size:0.7rem; color:#ccc; font-family:'Times New Roman',serif;">Not uploaded</span>
                    <% } %>
                </div>
            </div>
        <% } %>
        </div>
    </div>
</div>

<!-- ════════════════════════════════════════════════════════════════════════════
     SECTION 6 — Bank Details
══════════════════════════════════════════════════════════════════════════════ -->
<div class="dd-section">
    <div class="dd-section-head"><i class="bi bi-bank"></i> Bank Details</div>
    <div class="dd-section-body">
        <div class="dd-grid" style="margin-bottom:1.4rem;">
            <div class="dd-field"><label>Account Holder Name</label><span><%= safeDisplay(reg.getBankAccName()) %></span></div>
            <div class="dd-field"><label>Bank Name</label><span><%= safeDisplay(reg.getBankName()) %></span></div>
            <div class="dd-field"><label>Account Number</label><span style="font-family:monospace; letter-spacing:1.5px;"><%= safeDisplay(reg.getBankAccNumber()) %></span></div>
            <div class="dd-field"><label>IFSC Code</label><span style="font-family:monospace; text-transform:uppercase;"><%= safeDisplay(reg.getIfscCode()) %></span></div>
            <div class="dd-field"><label>Branch Name</label><span><%= safeDisplay(reg.getBranchName()) %></span></div>
            <div class="dd-field"><label>Account Type</label><span><%= safeDisplay(reg.getAccountType()) %></span></div>
            <div class="dd-field"><label>UPI ID</label><span class="<%= safe(reg.getUpiId())==null?"empty":"" %>"><%= safeDisplay(reg.getUpiId()) %></span></div>
        </div>
        <% if (safe(reg.getBankProofPath()) != null) { %>
        <div style="font-family:'Times New Roman',serif; font-size:0.72rem; letter-spacing:1.5px; text-transform:uppercase; color:var(--text-muted); margin-bottom:0.8rem;">Bank Proof</div>
        <div class="dd-doc-grid" style="grid-template-columns:200px; max-width:220px;">
            <div class="dd-doc-card">
                <% if (isImage(reg.getBankProofPath())) { %>
                    <img src="<%= docUrl(reg.getBankProofPath()) %>"
                         class="dd-doc-thumb"
                         onclick="ddOpenLightbox('<%= docUrl(reg.getBankProofPath()) %>','Bank Proof')"
                         onerror="this.style.display='none';"
                         alt="Bank Proof">
                <% } else { %>
                    <a href="<%= docUrl(reg.getBankProofPath()) %>" target="_blank" class="dd-doc-thumb-placeholder">
                        <i class="bi bi-file-earmark-text"></i><span>Open File</span>
                    </a>
                <% } %>
                <div class="dd-doc-footer">
                    <span class="dd-doc-label">Bank Proof</span>
                    <a href="<%= docUrl(reg.getBankProofPath()) %>" target="_blank" class="dd-doc-open"><i class="bi bi-box-arrow-up-right"></i> Open</a>
                </div>
            </div>
        </div>
        <% } %>
    </div>
</div>

<!-- ════════════════════════════════════════════════════════════════════════════
     SECTION 7 — Emergency Contact
══════════════════════════════════════════════════════════════════════════════ -->
<div class="dd-section">
    <div class="dd-section-head"><i class="bi bi-heart-pulse"></i> Emergency Contact</div>
    <div class="dd-section-body">
        <div class="dd-grid">
            <div class="dd-field"><label>Name</label><span><%= safeDisplay(reg.getEmergencyName()) %></span></div>
            <div class="dd-field"><label>Relation</label><span><%= safeDisplay(reg.getEmergencyRelation()) %></span></div>
            <div class="dd-field"><label>Mobile</label><span><%= safeDisplay(reg.getEmergencyMobile()) %></span></div>
        </div>
    </div>
</div>

<!-- ════════════════════════════════════════════════════════════════════════════
     SECTION 8 — Admin Action Panel
══════════════════════════════════════════════════════════════════════════════ -->
<div class="dd-action-panel">
    <div class="dd-action-title">
        <i class="bi bi-clipboard-check" style="color:var(--accent);"></i>
        Admin Decision
    </div>
    <label style="font-family:'Times New Roman',serif; font-size:0.78rem; letter-spacing:1px; text-transform:uppercase; color:var(--text-muted); display:block; margin-bottom:0.4rem;">
        Remarks / Reason (optional)
    </label>
    <textarea id="ddRemarksInput" class="dd-remarks-input"
              placeholder="Add notes, reason for approval or rejection, missing docs, etc…"><%= safe(reg.getAdminRemarks()) != null ? reg.getAdminRemarks() : "" %></textarea>
    <div>
        <button class="dd-btn-approve" onclick="ddConfirm('approve')" <%= isApproved ? "disabled" : "" %>>
            <i class="bi bi-check-circle-fill"></i>
            <%= isApproved ? "Already Approved" : "Approve Application" %>
        </button>
        <button class="dd-btn-reject" onclick="ddConfirm('reject')" <%= isRejected ? "disabled" : "" %>>
            <i class="bi bi-x-circle-fill"></i>
            <%= isRejected ? "Already Rejected" : "Reject Application" %>
        </button>
    </div>
    <% if (isApproved) { %>
        <p style="margin-top:0.8rem; font-size:0.82rem; color:#27ae60; font-family:'Times New Roman',serif;">
            <i class="bi bi-info-circle me-1"></i>
            This application is approved. A user account has been created with role <strong>delivery</strong>. You may still update remarks or change the decision.
        </p>
    <% } %>
</div>

<!-- Hidden form for POST submission -->
<form id="ddActionForm" method="POST" action="AdminDeliveryReviewServlet" style="display:none;">
    <input type="hidden" name="registrationId" value="<%= reg.getId() %>">
    <input type="hidden" name="action" id="ddActionInput" value="">
    <input type="hidden" name="adminRemarks" id="ddRemarksHidden" value="">
    <input type="hidden" name="redirectFilter" value="PENDING">
</form>

<!-- ════════════════════════════════════════════════════════════════════════════
     LIGHTBOX
══════════════════════════════════════════════════════════════════════════════ -->
<div class="dd-lightbox" id="ddLightbox" onclick="ddCloseLightbox()">
    <button class="dd-lightbox-close" onclick="ddCloseLightbox()">
        <i class="bi bi-x-lg"></i>
    </button>
    <img id="ddLightboxImg" src="" alt="Document">
    <div class="dd-lightbox-label" id="ddLightboxLabel"></div>
</div>

<!-- ════════════════════════════════════════════════════════════════════════════
     CONFIRM MODAL
══════════════════════════════════════════════════════════════════════════════ -->
<div class="dd-confirm-overlay" id="ddConfirmOverlay">
    <div class="dd-confirm-box">
        <div class="dd-confirm-icon" id="ddConfirmIcon"></div>
        <div class="dd-confirm-title" id="ddConfirmTitle"></div>
        <div class="dd-confirm-msg"   id="ddConfirmMsg"></div>
        <div class="dd-confirm-btns">
            <button id="ddConfirmOk"
                    style="font-family:'Times New Roman',serif; font-size:0.85rem; padding:0.55rem 1.8rem; border:none; border-radius:3px; cursor:pointer; color:#fff; transition:background 0.2s;"
                    onclick="ddSubmitAction()">Confirm</button>
            <button onclick="ddCloseConfirm()"
                    style="font-family:'Times New Roman',serif; font-size:0.85rem; padding:0.55rem 1.8rem; background:var(--bg-off); border:1px solid var(--border); border-radius:3px; cursor:pointer; color:var(--text-dark);">Cancel</button>
        </div>
    </div>
</div>

<script>
var _ddPendingAction = '';

function ddConfirm(action) {
    _ddPendingAction = action;
    const isApprove = action === 'approve';
    document.getElementById('ddConfirmIcon').innerHTML =
        isApprove ? '<i class="bi bi-check-circle-fill" style="color:#27ae60;"></i>'
                  : '<i class="bi bi-x-circle-fill" style="color:#e74c3c;"></i>';
    document.getElementById('ddConfirmTitle').textContent =
        isApprove ? 'Approve this application?' : 'Reject this application?';
    document.getElementById('ddConfirmMsg').textContent =
        isApprove
            ? 'This will mark the application as APPROVED and create a delivery user account. The agent will be able to log in.'
            : 'This will mark the application as REJECTED. The agent will not be able to log in. You can reverse this later.';
    const okBtn = document.getElementById('ddConfirmOk');
    okBtn.style.background = isApprove ? '#27ae60' : '#e74c3c';
    okBtn.textContent = isApprove ? 'Yes, Approve' : 'Yes, Reject';
    document.getElementById('ddConfirmOverlay').classList.add('open');
}
function ddCloseConfirm() {
    document.getElementById('ddConfirmOverlay').classList.remove('open');
}

function ddSubmitAction() {
    ddCloseConfirm();
    document.getElementById('ddActionInput').value = _ddPendingAction;
    document.getElementById('ddRemarksHidden').value =
        document.getElementById('ddRemarksInput').value;
       const form = document.getElementById('ddActionForm');
    const data = new URLSearchParams(new FormData(form));

    fetch(form.getAttribute('action'), { method: 'POST', body: data })
      .then(function(r) {
       
        const filter = document.querySelector('[name=redirectFilter]').value || 'PENDING';
        if (typeof window.dashboardLoadFragment === 'function') {
          window.dashboardLoadFragment(
            'DeliveryAgentReview?filter=' + filter,
            'Agent Applications',
            document.querySelector('.sidebar-nav-link[href*="DeliveryAgentReview"]')
          );
        } else {
          // Fallback: full page reload (acceptable if dashboard loader not available)
          window.location.href = 'DeliveryAgentReview?filter=' + filter;
        }
      })
      .catch(function(err) {
        alert('Error submitting action: ' + err.message);
      });
}

function ddOpenLightbox(src, label) {
    document.getElementById('ddLightboxImg').src = src;
    document.getElementById('ddLightboxLabel').textContent = label;
    document.getElementById('ddLightbox').classList.add('open');
}
function ddCloseLightbox() {
    document.getElementById('ddLightbox').classList.remove('open');
}
document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') { ddCloseLightbox(); ddCloseConfirm(); }
});
</script>

<% } /* end else (no error) */ %>
