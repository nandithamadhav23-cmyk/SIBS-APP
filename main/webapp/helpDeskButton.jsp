<%--
  helpDeskButton.jsp — Help Desk quick-access section for customerDashboard.jsp
  ─────────────────────────────────────────────────────────────────────────────
  Include anywhere in customerDashboard.jsp:
      <jsp:include page="helpDeskButton.jsp" />

  Shows:
  • "Help & Support" card with "My Requests" badge (open ticket count)
  • Quick category links → goes to helpDesk.jsp?tab=contact&cat=xxx
  • "Chat with Kira" button (triggers existing aiChatWidget FAB)
  • Zero JSTL — pure JSP scriptlet
--%>
<%@ page language="java" contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<%@ page import="com.DAO.TicketDAO, com.util.Customer" %>
<%
    int _hbOpenCount = 0;
    try {
        Object _hbCustId = session != null ? session.getAttribute("customerId") : null;
        if (_hbCustId instanceof Integer) {
            TicketDAO _hbDao = new TicketDAO();
            _hbOpenCount = _hbDao.getOpenTicketCount((Integer) _hbCustId);
        }
    } catch (Exception _hbEx) { /* silent — badge is non-critical */ }
%>
<style>
#hdb-section{margin:28px 0}
#hdb-section h2{font-size:16px;font-weight:600;color:#0f172a;margin-bottom:14px;
  display:flex;align-items:center;gap:8px}
#hdb-section h2 span{font-size:11px;font-weight:700;background:#ef4444;color:#fff;
  padding:2px 8px;border-radius:20px;display:<%= _hbOpenCount > 0 ? "inline-block" : "none" %>}

.hdb-grid{display:grid;grid-template-columns:2fr 1fr;gap:12px}
@media(max-width:640px){.hdb-grid{grid-template-columns:1fr}}

/* Main help card */
.hdb-card{background:#fff;border:1px solid #e2e8f0;border-radius:14px;padding:20px;
  box-shadow:0 1px 3px rgba(0,0,0,.04),0 8px 24px rgba(0,0,0,.04)}

/* Quick category buttons */
.hdb-cats{display:grid;grid-template-columns:1fr 1fr;gap:8px;margin-top:14px}
.hdb-cat{display:flex;align-items:center;gap:8px;padding:9px 12px;border-radius:10px;
  border:1px solid #e2e8f0;background:#f8fafc;text-decoration:none;
  color:#334155;font-size:12.5px;font-weight:500;transition:all .2s}
.hdb-cat:hover{border-color:#16a34a;background:#f0fdf4;color:#15803d}
.hdb-cat-icon{width:28px;height:28px;border-radius:8px;background:#f1f5f9;
  display:flex;align-items:center;justify-content:center;font-size:14px;flex-shrink:0}
.hdb-cat:hover .hdb-cat-icon{background:#dcfce7}

/* CTA row */
.hdb-cta-row{display:flex;gap:8px;margin-top:14px;flex-wrap:wrap}
.hdb-btn{display:inline-flex;align-items:center;gap:6px;padding:9px 16px;border-radius:10px;
  font-size:13px;font-weight:600;cursor:pointer;border:none;font-family:inherit;transition:all .2s;text-decoration:none}
.hdb-btn-primary{background:#16a34a;color:#fff}
.hdb-btn-primary:hover{background:#15803d}
.hdb-btn-secondary{background:#f1f5f9;color:#334155;border:1px solid #e2e8f0}
.hdb-btn-secondary:hover{background:#e2e8f0}

/* Right column: info card */
.hdb-info{background:#f0fdf4;border:1px solid #bbf7d0;border-radius:14px;padding:18px;
  display:flex;flex-direction:column;gap:10px}
.hdb-info-head{font-size:13px;font-weight:600;color:#15803d;display:flex;align-items:center;gap:8px}
.hdb-info-row{display:flex;align-items:center;gap:9px;font-size:12.5px;color:#166534}
.hdb-info-row svg{width:14px;height:14px;flex-shrink:0;stroke:#16a34a;fill:none}
.hdb-status-dot{width:8px;height:8px;border-radius:50%;background:#22c55e;
  box-shadow:0 0 0 2px #dcfce7;animation:hdPulse 2s infinite;flex-shrink:0}
@keyframes hdPulse{0%,100%{box-shadow:0 0 0 2px #dcfce7}50%{box-shadow:0 0 0 5px #dcfce7}}

.hdb-open-badge{display:flex;align-items:center;justify-content:space-between;
  background:#fff;border:1px solid #bbf7d0;border-radius:8px;padding:8px 11px;
  margin-top:4px;text-decoration:none}
.hdb-open-badge span{font-size:12px;font-weight:600;color:#15803d}
.hdb-open-badge small{font-size:11px;color:#64748b}
</style>

<section id="hdb-section">
  <h2>
    Help &amp; Support
    <span><%= _hbOpenCount %> open</span>
  </h2>

  <div class="hdb-grid">
    <!-- Main card -->
    <div class="hdb-card">
      <div style="font-size:13px;color:#64748b;margin-bottom:2px">Having an issue?</div>
      <div style="font-size:15px;font-weight:600;color:#0f172a">We're here to help, usually within 2–4 hours.</div>

      <div class="hdb-cats">
        <a href="HelpDesk?tab=contact&cat=order" class="hdb-cat">
          <div class="hdb-cat-icon">📦</div><span>Order issue</span>
        </a>
        <a href="HelpDesk?tab=contact&cat=cancellation" class="hdb-cat">
          <div class="hdb-cat-icon">✕</div><span>Cancel / Refund</span>
        </a>
        <a href="HelpDesk?tab=contact&cat=return" class="hdb-cat">
          <div class="hdb-cat-icon">↩</div><span>Return / Replace</span>
        </a>
        <a href="HelpDesk?tab=contact&cat=payment" class="hdb-cat">
          <div class="hdb-cat-icon">💳</div><span>Payment</span>
        </a>
        <a href="HelpDesk?tab=contact&cat=delivery" class="hdb-cat">
          <div class="hdb-cat-icon">🚚</div><span>Delivery</span>
        </a>
        <a href="HelpDesk?tab=contact&cat=other" class="hdb-cat">
          <div class="hdb-cat-icon">💬</div><span>Something else</span>
        </a>
      </div>

      <div class="hdb-cta-row">
        <a href="HelpDesk" class="hdb-btn hdb-btn-primary">View My Requests</a>
        <button class="hdb-btn hdb-btn-secondary" onclick="var fab=document.getElementById('kw-fab');if(fab)fab.click()">
          💬 Chat with Kira
        </button>
      </div>
    </div>

    <!-- Right info card -->
    <div class="hdb-info">
      <div class="hdb-info-head">
        <div class="hdb-status-dot"></div>
        Support status
      </div>
      <div class="hdb-info-row">
        <svg stroke-width="2" stroke-linecap="round" stroke-linejoin="round" viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
        Kira: 24/7 instant help
      </div>
      <div class="hdb-info-row">
        <svg stroke-width="2" stroke-linecap="round" stroke-linejoin="round" viewBox="0 0 24 24"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 00-3-3.87"/><path d="M16 3.13a4 4 0 010 7.75"/></svg>
        Team: Mon–Sat, 9am–6pm
      </div>
      <div class="hdb-info-row">
        <svg stroke-width="2" stroke-linecap="round" stroke-linejoin="round" viewBox="0 0 24 24"><path d="M22 11.08V12a10 10 0 11-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>
        Ticket response: 2–4 hrs
      </div>
      <% if (_hbOpenCount > 0) { %>
      <a href="HelpDesk" class="hdb-open-badge">
        <span>🎫 <%= _hbOpenCount %> open request<%= _hbOpenCount > 1 ? "s" : "" %></span>
        <small>View →</small>
      </a>
      <% } %>
    </div>
  </div>
</section>
