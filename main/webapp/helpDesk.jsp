<%--
  helpDesk.jsp — GreenCart Help Desk: My Requests + Contact Us
  ─────────────────────────────────────────────────────────────
  Mapped to: /HelpDesk  (served by HelpDeskServlet)

  Features:
  • "My Requests" tab — customer's full ticket history with live status badges
  • "Contact Us" tab  — structured form to raise a new support ticket
  • "FAQ" tab         — instant answers to common questions
  • Staff-reply preview shown inline under each ticket
  • Submitted confirmation toast
  • Zero JSTL — pure JSP scriptlet
  • Mobile-first, fully responsive
--%>
<%@ page language="java" contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<%@ page import="com.util.SupportTicket, com.util.Customer, java.util.List, java.text.SimpleDateFormat" %>
<%
    /* ── Auth ── */
    Customer _cust = null;
    Object _cObj = session != null ? session.getAttribute("customer") : null;
    if (_cObj instanceof Customer) _cust = (Customer) _cObj;
    if (_cust == null) { response.sendRedirect("CustomerLogin.jsp"); return; }
    String _custName = _cust.getName() != null ? _cust.getName().split(" ")[0] : "there";

    /* ── Data ── */
    @SuppressWarnings("unchecked")
    List<SupportTicket> _tickets = (List<SupportTicket>) request.getAttribute("tickets");
    int _openCount = _tickets == null ? 0 :
        (int) _tickets.stream().filter(t -> !t.isResolved()).count();

    /* ── Toast params ── */
    String _submitted = request.getParameter("submitted");
    String _replied   = request.getParameter("replied");
    SimpleDateFormat _sdf = new SimpleDateFormat("d MMM yyyy, h:mm a");
    String _errMsg = (String) request.getAttribute("error");
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Help &amp; Support — GreenCart</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600&family=DM+Mono:wght@400;500&display=swap" rel="stylesheet">
<style>
/* ══════════════════════════════════════════════════════════════════════
   TOKENS & RESET
══════════════════════════════════════════════════════════════════════ */
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --brand:#16a34a; --brand2:#15803d; --brand-bg:#f0fdf4; --brand-bd:#bbf7d0;
  --bg:#f8fafc; --surface:#fff; --surface2:#f1f5f9;
  --bd:#e2e8f0; --bd2:#cbd5e1;
  --tx:#0f172a; --tx2:#334155; --mu:#64748b; --mu2:#94a3b8;
  --in:#2563eb; --in-bg:#eff6ff; --in-bd:#bfdbfe;
  --am:#b45309; --am-bg:#fffbeb; --am-bd:#fde68a;
  --re:#dc2626; --re-bg:#fef2f2; --re-bd:#fecaca;
  --gr:#15803d; --gr-bg:#f0fdf4; --gr-bd:#bbf7d0;
  --pu:#6d28d9; --pu-bg:#f5f3ff; --pu-bd:#ddd6fe;
  --rad:14px; --rad-sm:10px; --rad-xs:7px;
  --fn:'DM Sans',system-ui,sans-serif;
  --fn-mono:'DM Mono',monospace;
  --sh:0 1px 3px rgba(0,0,0,.06),0 8px 32px rgba(0,0,0,.06);
}
html{scroll-behavior:smooth}
body{font-family:var(--fn);background:var(--bg);color:var(--tx);min-height:100vh;font-size:14px;line-height:1.6}

/* ══════════════════════════════════════════════════════════════════════
   LAYOUT
══════════════════════════════════════════════════════════════════════ */
.hd-wrap{max-width:900px;margin:0 auto;padding:32px 16px 80px}

/* ── Hero header ── */
.hd-hero{background:linear-gradient(135deg,#052e16,#166534);border-radius:20px;
  padding:36px 40px;margin-bottom:28px;position:relative;overflow:hidden}
.hd-hero::before{content:'';position:absolute;inset:0;
  background:url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23ffffff' fill-opacity='0.03'%3E%3Cpath d='M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E");
  pointer-events:none}
.hd-hero h1{font-size:26px;font-weight:600;color:#fff;margin-bottom:6px;position:relative}
.hd-hero p{font-size:14px;color:rgba(255,255,255,.65);position:relative;max-width:460px}
.hd-hero-badge{position:absolute;top:28px;right:36px;background:rgba(255,255,255,.1);
  border:1px solid rgba(255,255,255,.15);border-radius:50px;padding:6px 16px;
  font-size:12px;font-weight:600;color:#86efac}
@media(max-width:560px){
  .hd-hero{padding:24px 20px}
  .hd-hero-badge{display:none}
}

/* ── Tabs ── */
.hd-tabs{display:flex;gap:4px;background:var(--surface);border:1px solid var(--bd);
  border-radius:var(--rad);padding:5px;margin-bottom:24px;overflow-x:auto;
  box-shadow:var(--sh)}
.hd-tab{flex:1;min-width:90px;padding:9px 16px;border-radius:var(--rad-sm);border:none;
  cursor:pointer;font-family:var(--fn);font-size:13px;font-weight:500;
  color:var(--mu);background:transparent;transition:all .2s;white-space:nowrap;position:relative}
.hd-tab:hover{color:var(--tx);background:var(--surface2)}
.hd-tab.active{background:var(--brand-bg);color:var(--brand2);font-weight:600}
.hd-tab-badge{position:absolute;top:5px;right:10px;background:var(--re);
  color:#fff;border-radius:20px;padding:1px 6px;font-size:10px;font-weight:700}
.hd-panel{display:none}.hd-panel.active{display:block}

/* ══════════════════════════════════════════════════════════════════════
   MY REQUESTS TAB
══════════════════════════════════════════════════════════════════════ */
.hd-empty{text-align:center;padding:60px 24px;color:var(--mu)}
.hd-empty svg{width:56px;height:56px;margin-bottom:12px;opacity:.35}
.hd-empty h3{font-size:16px;font-weight:500;margin-bottom:6px;color:var(--tx2)}
.hd-empty p{font-size:13px;line-height:1.5}
.hd-empty-btn{display:inline-block;margin-top:16px;padding:9px 22px;border-radius:var(--rad-sm);
  background:var(--brand);color:#fff;text-decoration:none;font-weight:600;font-size:13px;
  transition:background .2s}
.hd-empty-btn:hover{background:var(--brand2)}

.tkt-card{background:var(--surface);border:1px solid var(--bd);border-radius:var(--rad);
  margin-bottom:12px;overflow:hidden;transition:box-shadow .2s;box-shadow:var(--sh)}
.tkt-card:hover{box-shadow:0 4px 20px rgba(0,0,0,.1)}
.tkt-head{display:flex;align-items:flex-start;gap:14px;padding:16px 18px 14px;cursor:pointer}
.tkt-icon{width:40px;height:40px;border-radius:10px;display:flex;align-items:center;
  justify-content:center;font-size:17px;flex-shrink:0;background:var(--surface2)}
.tkt-meta{flex:1;min-width:0}
.tkt-id{font-size:11px;font-weight:600;color:var(--mu);font-family:var(--fn-mono);margin-bottom:3px}
.tkt-subject{font-size:14px;font-weight:600;color:var(--tx);line-height:1.3;margin-bottom:4px;
  white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.tkt-cat{font-size:12px;color:var(--mu)}
.tkt-status-col{display:flex;flex-direction:column;align-items:flex-end;gap:6px;flex-shrink:0}
.tkt-badge{display:inline-block;padding:3px 10px;border-radius:20px;font-size:11px;font-weight:700;letter-spacing:.02em}
.tkt-badge.open     {background:var(--am-bg);color:var(--am);border:1px solid var(--am-bd)}
.tkt-badge.inprogress{background:var(--in-bg);color:var(--in);border:1px solid var(--in-bd)}
.tkt-badge.replied  {background:var(--pu-bg);color:var(--pu);border:1px solid var(--pu-bd)}
.tkt-badge.resolved {background:var(--gr-bg);color:var(--gr);border:1px solid var(--gr-bd)}
.tkt-date{font-size:11px;color:var(--mu)}
.tkt-chevron{font-size:18px;color:var(--mu2);transition:transform .2s;margin-top:4px}
.tkt-card.expanded .tkt-chevron{transform:rotate(180deg)}

.tkt-body{border-top:1px solid var(--bd);padding:0 18px;max-height:0;overflow:hidden;
  transition:max-height .3s ease,padding .3s ease}
.tkt-card.expanded .tkt-body{max-height:1000px;padding:16px 18px;overflow-y:auto}

.tkt-desc-label{font-size:11px;font-weight:600;color:var(--mu);text-transform:uppercase;
  letter-spacing:.06em;margin-bottom:6px}
.tkt-desc{font-size:13px;color:var(--tx2);line-height:1.6;background:var(--surface2);
  border-radius:var(--rad-xs);padding:10px 12px;margin-bottom:14px}

.tkt-reply-box{background:var(--pu-bg);border:1px solid var(--pu-bd);border-radius:var(--rad-sm);
  padding:12px 14px;margin-bottom:14px}
.tkt-reply-box-label{font-size:11px;font-weight:700;color:var(--pu);margin-bottom:6px;
  display:flex;align-items:center;gap:6px}
.tkt-reply-box-label::before{content:'';width:6px;height:6px;border-radius:50%;background:var(--pu);display:block}
.tkt-reply-box p{font-size:13px;color:#3b0764;line-height:1.6}

.tkt-reply-form{display:flex;flex-direction:column;gap:10px}
.tkt-reply-form textarea{width:100%;border:1px solid var(--bd2);border-radius:var(--rad-xs);
  padding:9px 12px;font-family:var(--fn);font-size:13px;color:var(--tx);resize:vertical;
  min-height:80px;background:var(--surface);outline:none}
.tkt-reply-form textarea:focus{border-color:var(--brand);box-shadow:0 0 0 3px rgba(22,163,74,.1)}
.tkt-reply-form button{align-self:flex-start;padding:8px 18px;background:var(--brand);
  color:#fff;border:none;border-radius:var(--rad-xs);font-family:var(--fn);font-weight:600;
  font-size:13px;cursor:pointer;transition:background .2s}
.tkt-reply-form button:hover{background:var(--brand2)}

/* ══════════════════════════════════════════════════════════════════════
   CONTACT US TAB
══════════════════════════════════════════════════════════════════════ */
.cu-card{background:var(--surface);border:1px solid var(--bd);border-radius:var(--rad);
  padding:28px;box-shadow:var(--sh)}
.cu-card h2{font-size:17px;font-weight:600;margin-bottom:4px}
.cu-card .cu-sub{font-size:13px;color:var(--mu);margin-bottom:24px;border-bottom:1px solid var(--bd);padding-bottom:16px}

/* Category pills */
.cu-cats{display:flex;flex-wrap:wrap;gap:8px;margin-bottom:20px}
.cu-cat{display:flex;align-items:center;gap:6px;padding:7px 14px;border-radius:20px;
  border:1.5px solid var(--bd);background:var(--surface2);cursor:pointer;
  font-size:13px;font-weight:500;color:var(--tx2);transition:all .2s;user-select:none}
.cu-cat:hover{border-color:var(--brand);color:var(--brand)}
.cu-cat.selected{border-color:var(--brand);background:var(--brand-bg);color:var(--brand2);font-weight:600}
.cu-cat input[type=radio]{display:none}

/* Form fields */
.cu-field{margin-bottom:16px}
.cu-label{display:block;font-size:13px;font-weight:600;color:var(--tx2);margin-bottom:6px}
.cu-label span{font-weight:400;color:var(--mu)}
.cu-input,.cu-select,.cu-textarea{width:100%;border:1px solid var(--bd2);border-radius:var(--rad-xs);
  padding:9px 12px;font-family:var(--fn);font-size:14px;color:var(--tx);background:var(--surface);
  outline:none;transition:border-color .2s,box-shadow .2s}
.cu-input:focus,.cu-select:focus,.cu-textarea:focus{border-color:var(--brand);
  box-shadow:0 0 0 3px rgba(22,163,74,.1)}
.cu-textarea{resize:vertical;min-height:110px}
.cu-select{appearance:none;background-image:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='8' viewBox='0 0 12 8'%3E%3Cpath d='M1 1l5 5 5-5' stroke='%2394a3b8' stroke-width='1.5' fill='none' stroke-linecap='round'/%3E%3C/svg%3E");
  background-repeat:no-repeat;background-position:right 12px center}

.cu-tip{background:var(--in-bg);border:1px solid var(--in-bd);border-radius:var(--rad-xs);
  padding:10px 13px;font-size:12px;color:#1e40af;margin-bottom:16px;display:flex;gap:8px}
.cu-tip::before{content:'💡';flex-shrink:0}

.cu-submit{width:100%;padding:12px;background:var(--brand);color:#fff;border:none;
  border-radius:var(--rad-sm);font-family:var(--fn);font-size:14px;font-weight:600;
  cursor:pointer;transition:background .2s;display:flex;align-items:center;justify-content:center;gap:8px}
.cu-submit:hover{background:var(--brand2)}
.cu-submit:active{transform:scale(.98)}
.cu-submit svg{width:16px;height:16px}

.cu-err{background:var(--re-bg);border:1px solid var(--re-bd);border-radius:var(--rad-xs);
  padding:10px 13px;font-size:13px;color:var(--re);margin-bottom:16px}

/* ══════════════════════════════════════════════════════════════════════
   FAQ TAB
══════════════════════════════════════════════════════════════════════ */
.faq-item{border:1px solid var(--bd);border-radius:var(--rad-sm);margin-bottom:10px;
  background:var(--surface);box-shadow:var(--sh);overflow:hidden}
.faq-q{display:flex;justify-content:space-between;align-items:center;padding:14px 18px;
  cursor:pointer;font-size:14px;font-weight:500;color:var(--tx);gap:12px}
.faq-q:hover{background:var(--surface2)}
.faq-q svg{width:16px;height:16px;flex-shrink:0;stroke:var(--mu);transition:transform .2s}
.faq-item.open .faq-q svg{transform:rotate(180deg)}
.faq-a{padding:0 18px;max-height:0;overflow:hidden;transition:max-height .3s ease,padding .3s ease;
  font-size:13px;color:var(--tx2);line-height:1.7}
.faq-item.open .faq-a{max-height:400px;padding:0 18px 16px}
.faq-a strong{color:var(--tx)}
.faq-chat-btn{display:inline-flex;align-items:center;gap:6px;margin-top:10px;padding:7px 14px;
  background:var(--brand-bg);border:1px solid var(--brand-bd);border-radius:var(--rad-xs);
  color:var(--brand2);font-size:12px;font-weight:600;cursor:pointer;text-decoration:none;transition:all .2s}
.faq-chat-btn:hover{background:var(--brand);color:#fff}

/* ══════════════════════════════════════════════════════════════════════
   TOAST
══════════════════════════════════════════════════════════════════════ */
.hd-toast{position:fixed;top:20px;right:20px;z-index:9999;
  border-radius:var(--rad-sm);padding:13px 18px;font-size:13px;font-weight:600;
  display:none;align-items:center;gap:10px;max-width:340px;
  box-shadow:0 8px 32px rgba(0,0,0,.15);animation:toastIn .35s cubic-bezier(.34,1.56,.64,1)}
.hd-toast.ok{background:#fff;border:1px solid var(--gr-bd);color:var(--gr)}
.hd-toast.er{background:#fff;border:1px solid var(--re-bd);color:var(--re)}
@keyframes toastIn{from{opacity:0;transform:translateY(-16px)}to{opacity:1;transform:translateY(0)}}

/* ══════════════════════════════════════════════════════════════════════
   BACK LINK
══════════════════════════════════════════════════════════════════════ */
.hd-back{display:inline-flex;align-items:center;gap:6px;margin-bottom:20px;
  color:var(--mu);font-size:13px;font-weight:500;text-decoration:none;transition:color .15s}
.hd-back:hover{color:var(--tx)}
.hd-back svg{width:14px;height:14px}
@media(max-width:768px){body{padding-bottom:70px;}}
</style>
</head>
<body>

<!-- ── Toast ─────────────────────────────────────────────────────── -->
<div class="hd-toast ok" id="hd-toast-ok">
  ✓ <span id="hd-toast-msg">Ticket submitted</span>
</div>

<!-- ── Main ──────────────────────────────────────────────────────── -->
<div class="hd-wrap">

  <a href="Customer" class="hd-back">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="15 18 9 12 15 6"/></svg>
    Back to Dashboard
  </a>

  <!-- Hero -->
  <div class="hd-hero">
    <h1>Help &amp; Support</h1>
    <p>Hi <%= _custName %>! How can we help you today? Track your requests or raise a new issue.</p>
    <% if (_openCount > 0) { %>
      <div class="hd-hero-badge"><%= _openCount %> open request<%= _openCount > 1 ? "s" : "" %></div>
    <% } %>
  </div>

  <!-- Tabs -->
  <div class="hd-tabs" role="tablist">
    <button class="hd-tab active" id="tab-requests" role="tab" onclick="switchTab('requests', this)">
      My Requests
      <% if (_openCount > 0) { %><span class="hd-tab-badge"><%= _openCount %></span><% } %>
    </button>
    <button class="hd-tab" id="tab-contact" role="tab" onclick="switchTab('contact', this)">Contact Us</button>
    <button class="hd-tab" id="tab-faq" role="tab" onclick="switchTab('faq', this)">FAQ</button>
  </div>

  <!-- ═══════════════════════════════════════════════
       PANEL: MY REQUESTS
  ═══════════════════════════════════════════════ -->
  <div class="hd-panel active" id="panel-requests">
    <% if (_tickets == null || _tickets.isEmpty()) { %>
      <div class="hd-empty">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.2">
          <path d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2"/>
          <rect x="9" y="3" width="6" height="4" rx="1"/>
          <line x1="9" y1="12" x2="15" y2="12"/><line x1="9" y1="16" x2="12" y2="16"/>
        </svg>
        <h3>No support requests yet</h3>
        <p>If you have any questions or issues, raise a request below and our team will respond within 2–4 hours.</p>
        <a href="#" class="hd-empty-btn" onclick="switchTab('contact',document.getElementById('tab-contact'));return false">Raise a Request</a>
      </div>
    <% } else { %>
      <% for (SupportTicket t : _tickets) {
          String _catMap = t.getCategoryLabel();
          String _catIcon = _catMap != null && _catMap.length() > 1 ? _catMap.substring(0, 2) : "📋";
          String _catText = _catMap != null && _catMap.length() > 2 ? _catMap.substring(2).trim() : "Other";
          String _statusLabel = t.getStatusLabel();
          String _statusCss   = t.getStatusCss();
          String _createdStr  = t.getCreatedAt() != null ? _sdf.format(t.getCreatedAt()) : "";
          String _refOrderStr = t.getRefOrderId() > 0 ? "Order #" + t.getRefOrderId() : "";
      %>
      <div class="tkt-card" id="tkt-<%= t.getTicketId() %>">
        <!-- Card head (click to expand) -->
        <div class="tkt-head" onclick="toggleTicket(<%= t.getTicketId() %>)">
          <div class="tkt-icon"><%= _catIcon %></div>
          <div class="tkt-meta">
            <div class="tkt-id">#TKT-<%= t.getTicketId() %><%= !_refOrderStr.isEmpty() ? " · " + _refOrderStr : "" %></div>
            <div class="tkt-subject"><%= t.getSubject() != null ? t.getSubject() : "Support request" %></div>
            <div class="tkt-cat"><%= _catText %></div>
          </div>
          <div class="tkt-status-col">
            <span class="tkt-badge <%= _statusCss %>"><%= _statusLabel %></span>
            <span class="tkt-date"><%= _createdStr %></span>
          </div>
          <span class="tkt-chevron">⌄</span>
        </div>

        <!-- Collapsible body -->
        <div class="tkt-body">
          <div class="tkt-desc-label">Your message</div>
          <div class="tkt-desc"><%= t.getDescription() != null ? t.getDescription().replace("\n","<br>") : "" %></div>

          <% if (t.getStaffReply() != null && !t.getStaffReply().isBlank()) { %>
          <div class="tkt-reply-box">
            <div class="tkt-reply-box-label">GreenCart Team replied</div>
            <p><%= t.getStaffReply().replace("\n","<br>") %></p>
          </div>
          <% } %>

          <% if (!t.isResolved()) { %>
          <div class="tkt-desc-label">Add more details</div>
          <form method="POST" action="HelpDesk" class="tkt-reply-form">
            <input type="hidden" name="action" value="reply">
            <input type="hidden" name="ticketId" value="<%= t.getTicketId() %>">
            <textarea name="message" placeholder="Anything to add? We'll update your case..."></textarea>
            <button type="submit">Send update →</button>
          </form>
          <% } else { %>
          <div style="display:flex;align-items:center;gap:8px;padding:10px 12px;background:var(--gr-bg);border:1px solid var(--gr-bd);border-radius:var(--rad-xs);font-size:12px;color:var(--gr);font-weight:600;margin-top:8px">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
            Ticket resolved &mdash; if you need further help, please open a new request.
          </div>
          <% } %>
        </div>
      </div>
      <% } /* end for */ %>
    <% } %>
  </div>

  <!-- ═══════════════════════════════════════════════
       PANEL: CONTACT US
  ═══════════════════════════════════════════════ -->
  <div class="hd-panel" id="panel-contact">
    <div class="cu-card">
      <h2>Raise a Support Request</h2>
      <p class="cu-sub">Fill in the details below and our team will get back to you within <strong>2–4 hours</strong>.</p>

      <% if (_errMsg != null) { %>
        <div class="cu-err">⚠ <%= _errMsg %></div>
      <% } %>

      <form method="POST" action="HelpDesk" id="cu-form">
        <input type="hidden" name="action" value="submit">
        <input type="hidden" name="category" id="cu-cat-val" value="other">

        <!-- Category pills -->
        <div class="cu-field">
          <label class="cu-label">What's this about? <span>(choose one)</span></label>
          <div class="cu-cats" id="cu-cats">
            <div class="cu-cat selected" data-val="order"        onclick="selectCat(this)">📦 Order issue</div>
            <div class="cu-cat" data-val="cancellation"          onclick="selectCat(this)">✕ Cancel / Refund</div>
            <div class="cu-cat" data-val="return"                onclick="selectCat(this)">↩ Return / Replace</div>
            <div class="cu-cat" data-val="payment"               onclick="selectCat(this)">💳 Payment</div>
            <div class="cu-cat" data-val="delivery"              onclick="selectCat(this)">🚚 Delivery</div>
            <div class="cu-cat" data-val="product"               onclick="selectCat(this)">🛍 Product quality</div>
            <div class="cu-cat" data-val="account"               onclick="selectCat(this)">👤 My account</div>
            <div class="cu-cat" data-val="other"                 onclick="selectCat(this)">💬 Other</div>
          </div>
        </div>

        <!-- Order ID (optional) -->
        <div class="cu-field" id="cu-order-field">
          <label class="cu-label" for="cu-orderid">Order ID <span>(optional — helps us find your order faster)</span></label>
          <input class="cu-input" type="text" id="cu-orderid" name="orderId" placeholder="e.g. 1042">
        </div>

        <!-- Subject -->
        <div class="cu-field">
          <label class="cu-label" for="cu-subject">Subject</label>
          <input class="cu-input" type="text" id="cu-subject" name="subject"
            placeholder="One-line summary of your issue" maxlength="200" required>
        </div>

        <!-- Description -->
        <div class="cu-field">
          <label class="cu-label" for="cu-desc">Describe your issue <span>(the more detail, the faster we can help)</span></label>
          <textarea class="cu-textarea" id="cu-desc" name="description" maxlength="2000" required
            placeholder="What happened? Which order or product? What did you expect?"></textarea>
        </div>

        <div class="cu-tip">
          You can also chat with <strong>Kira</strong> (the chat button at the bottom right) for instant help — she can track orders, cancel, and handle returns automatically.
        </div>

        <button type="submit" class="cu-submit">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="22" y1="2" x2="11" y2="13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/></svg>
          Submit Request
        </button>
      </form>
    </div>
  </div>

  <!-- ═══════════════════════════════════════════════
       PANEL: FAQ
  ═══════════════════════════════════════════════ -->
  <div class="hd-panel" id="panel-faq">
    <%
      String[][] _faqs = {
        {"📦 How do I track my order?",
         "Open the chat widget (bottom right) and type your Order ID, or say <strong>\"track my order\"</strong>. Kira will show you real-time status with a full progress timeline. You can also view orders from your dashboard."},
        {"✕ Can I cancel my order?",
         "Yes — as long as it hasn't been delivered. The refund depends on the stage:<br><br>"
         + "<strong>Ordered / Confirmed</strong> → 100% refund<br>"
         + "<strong>Assigned / Picked Up / Packed</strong> → 95% refund (5% handling)<br>"
         + "<strong>Shipped / Out for Delivery</strong> → 90% refund (courier intercept attempted)<br>"
         + "<strong>Delivered</strong> → No cancellation — return or replace within 10 days.<br><br>"
         + "Say <strong>\"cancel my order\"</strong> to Kira to start the process."},
        {"↩ How do I return or replace a product?",
         "You can return or replace any delivered item within <strong>10 days</strong> of delivery. Go to the chat widget and say <strong>\"return my order\"</strong> or tap the Return / Replace button on your order card. Kira will guide you through the steps."},
        {"💳 My payment failed but money was deducted — what do I do?",
         "First, say <strong>\"payment issue\"</strong> to Kira — she'll look up the transaction status in real time. If a genuine double-charge or failed-payment issue is confirmed, a refund is processed within 5–7 business days to your original payment method."},
        {"📍 Can I change my delivery address?",
         "Yes — <strong>only before the order is shipped</strong>. Say <strong>\"change my address\"</strong> to Kira with the Order ID. If the order is already shipped, we'll raise an urgent delivery note with the courier — but we cannot guarantee the change."},
        {"🧾 How do I get my invoice / receipt?",
         "Open the chat widget, type your Order ID and click the <strong>Invoice</strong> button that appears on the order card. The PDF invoice opens in a new tab and can be downloaded."},
        {"⏱ How long does it take to get a response on a ticket?",
         "Our team reviews tickets within <strong>2–4 hours</strong> during business hours (9 AM – 6 PM, Mon–Sat). You'll see the staff reply appear under your request in the <em>My Requests</em> tab. For instant help, the Kira chat bot is available 24/7."},
        {"🔄 My order says 'Delivered' but I haven't received it — what now?",
         "This sometimes happens when a delivery agent marks an order early. Raise a support ticket with category <strong>Delivery</strong> and mention the Order ID. Our logistics team will investigate and escalate to the delivery partner within 24 hours."}
      };
      for (int fi = 0; fi < _faqs.length; fi++) {
    %>
    <div class="faq-item" id="faq-<%= fi %>">
      <div class="faq-q" onclick="toggleFaq(<%= fi %>)">
        <span><%= _faqs[fi][0] %></span>
        <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <polyline points="6 9 12 15 18 9"/>
        </svg>
      </div>
      <div class="faq-a"><%= _faqs[fi][1] %><br>
        <a class="faq-chat-btn" href="#" onclick="openKiraChat();return false">
          💬 Chat with Kira instead
        </a>
      </div>
    </div>
    <% } %>
  </div>

</div><!-- end hd-wrap -->

<!-- ── Script ──────────────────────────────────────────────────────── -->
<script>
/* ── Tab switching ── */
function switchTab(id, btn) {
  document.querySelectorAll('.hd-panel').forEach(function(p) { p.classList.remove('active') });
  document.querySelectorAll('.hd-tab').forEach(function(t) { t.classList.remove('active') });
  document.getElementById('panel-' + id).classList.add('active');
  btn.classList.add('active');
}

/* ── Ticket accordion ── */
function toggleTicket(id) {
  var card = document.getElementById('tkt-' + id);
  card.classList.toggle('expanded');
}

/* ── FAQ accordion ── */
function toggleFaq(id) {
  var el = document.getElementById('faq-' + id);
  var wasOpen = el.classList.contains('open');
  document.querySelectorAll('.faq-item').forEach(function(f) { f.classList.remove('open') });
  if (!wasOpen) el.classList.add('open');
}

/* ── Category pill selection ── */
function selectCat(el) {
  document.querySelectorAll('.cu-cat').forEach(function(c) { c.classList.remove('selected') });
  el.classList.add('selected');
  document.getElementById('cu-cat-val').value = el.dataset.val;
  // Show/hide order ID field based on relevance
  var show = ['order','cancellation','return','delivery','payment'].includes(el.dataset.val);
  document.getElementById('cu-order-field').style.display = show ? 'block' : 'none';
}

/* ── Open Kira chat widget ── */
function openKiraChat() {
  var fab = document.getElementById('kw-fab');
  if (fab) fab.click();
  else window.location.href = 'Customer';
}

/* ── Toast on submission ── */
(function() {
  var submitted = '<%= _submitted != null ? _submitted : "" %>';
  var replied   = '<%= _replied   != null ? _replied   : "" %>';
  if (submitted) {
    showToast('✓ Ticket #TKT-' + submitted + ' raised. We\'ll reply within 2–4 hours.');
    // Auto-switch to My Requests
    switchTab('requests', document.getElementById('tab-requests'));
    // Auto-expand the new ticket
    var card = document.getElementById('tkt-' + submitted);
    if (card) { card.classList.add('expanded'); card.scrollIntoView({ behavior:'smooth', block:'center' }) }
  }
  if (replied) {
    showToast('✓ Your reply has been sent. We\'ll get back to you soon.');
    var card = document.getElementById('tkt-' + replied);
    if (card) { card.classList.add('expanded'); card.scrollIntoView({ behavior:'smooth', block:'center' }) }
  }
})();

function showToast(msg) {
  var el = document.getElementById('hd-toast-ok');
  document.getElementById('hd-toast-msg').textContent = msg;
  el.style.display = 'flex';
  setTimeout(function() { el.style.display = 'none' }, 5000);
}

/* ── Handle URL tab param (e.g. helpDesk.jsp?tab=contact) ── */
(function() {
  var p = new URLSearchParams(window.location.search);
  if (p.get('tab') === 'contact') {
    switchTab('contact', document.getElementById('tab-contact'));
    // BUG FIX: also pre-select category pill when ?cat= is present
    // (deep-links from helpDeskButton.jsp were opening the tab but
    //  leaving the category pill on the default "order issue" selection)
    var cat = p.get('cat');
    if (cat) {
      var pill = document.querySelector('.cu-cat[data-val="' + cat + '"]');
      if (pill) selectCat(pill);
    }
  }
})();
</script>

<jsp:include page="customerBottomNav.jsp"><jsp:param name="activePage" value=""/></jsp:include>
</body>
</html>
