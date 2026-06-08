<%--
  staffChatWidget.jsp — Nexus AI Unified Operations Assistant  (v2, pure JSP scriptlet, no JSTL)
  ─────────────────────────────────────────────────────────────────────────────────────────────
  Include at the bottom of userDashboard.jsp:
      <jsp:include page="staffChatWidget.jsp" />

  DOMAINS: Orders · Inventory · Returns · Customer Tickets · HR Attendance · Leave · Logistics
  ALL FIXES:
   1. Zero JSTL — pure JSP scriptlet only
   2. No paid Anthropic API — StaffLocalAIEngine handles all logic
   3. All card action buttons call real servlet endpoints (updateOrder, resolveTicket,
      notifyCustomer, approveLeave, agentMetrics)
   4. lookupOrder   → GET /StaffAIChatServlet?action=lookupOrder&orderId=N (real DB)
   5. lookupTickets → GET /StaffAIChatServlet?action=lookupTickets (real DB)
   6. getAttendance → GET /StaffAIChatServlet?action=getAttendance (real DB)
   7. getLeave      → GET /StaffAIChatServlet?action=getLeave (real DB)
   8. lookupInventory→ GET /StaffAIChatServlet?action=lookupInventory (real DB)
   9. agentMetrics  → GET /StaffAIChatServlet?action=agentMetrics (real DB)
  10. notifyCustomer→ POST — FEEDBACK LOOP: staff message goes into customer chat session
  11. Proactive overload alert: agents with >3 orders shown in alert banner
  12. Light, professional, clean SaaS theme — Inter font, white/slate
  13. Mobile-first responsive layout
  14. Each domain is isolated — completing one action doesn't bleed into another
--%>
<%@ page language="java" contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<%
    Object _roleObj = session != null ? session.getAttribute("role") : null;
    Object _nameObj = session != null ? session.getAttribute("username") : null;
    String _sRole = (_roleObj instanceof String) ? (String) _roleObj : "staff";
    String _sName = (_nameObj instanceof String) ? (String) _nameObj : "Staff";
    boolean _isAdmin = "admin".equalsIgnoreCase(_sRole);
%>

<style>
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');
/* ── reset ─────────────────────────────────────────────────────────────── */
#nx*,#nx *::before,#nx *::after{box-sizing:border-box;margin:0;padding:0}
/* ── tokens ────────────────────────────────────────────────────────────── */
#nx{
  --p:#1e40af;--p2:#2563eb;--p3:#3b82f6;
  --bg:#ffffff;--feed:#f8fafc;--bd:#e2e8f0;--bd2:#cbd5e1;
  --tx:#0f172a;--tx2:#334155;--mu:#64748b;--mu2:#94a3b8;
  --ub:linear-gradient(135deg,#1e40af,#2563eb);
  --ab:#ffffff;
  --hdr:linear-gradient(135deg,#0f172a,#1e293b);
  --gr:#059669;--re:#dc2626;--am:#d97706;--pu:#7c3aed;--or:#ea580c;
  --sh:0 4px 6px rgba(0,0,0,.04),0 20px 60px rgba(0,0,0,.12),0 0 0 1px rgba(30,64,175,.08);
  --fn:'Inter',system-ui,sans-serif;
  font-family:var(--fn);
}
/* ── FAB ──────────────────────────────────────────────────────────────── */
#nx-fab{position:fixed;bottom:26px;right:26px;z-index:10001;width:56px;height:56px;
  border-radius:50%;border:none;cursor:pointer;
  background:linear-gradient(135deg,#0f172a,#1e40af);
  display:flex;align-items:center;justify-content:center;
  box-shadow:0 6px 24px rgba(30,64,175,.5),0 2px 8px rgba(0,0,0,.18);
  transition:transform .3s cubic-bezier(.34,1.56,.64,1),box-shadow .3s;outline:none}
#nx-fab:hover{transform:scale(1.1);box-shadow:0 10px 32px rgba(30,64,175,.6)}
#nx-fab:active{transform:scale(.95)}
#nx-fab svg{width:22px;height:22px;transition:transform .3s}
#nx-fab.open{background:linear-gradient(135deg,#dc2626,#b91c1c)}
#nx-fab.open svg{transform:rotate(90deg)}
#nx-fab-badge{position:absolute;top:-5px;right:-5px;min-width:19px;height:19px;
  border-radius:10px;padding:0 4px;background:#ef4444;color:#fff;font-size:10px;
  font-weight:700;display:none;align-items:center;justify-content:center;
  border:2px solid #fff;font-family:var(--fn)}
/* ── Alert banner ─────────────────────────────────────────────────────── */
#nx-alert{position:fixed;top:72px;right:16px;z-index:10002;
  background:#fff3cd;border:1.5px solid #f59e0b;border-radius:12px;
  padding:9px 14px;display:none;align-items:center;gap:8px;
  box-shadow:0 4px 16px rgba(245,158,11,.2);max-width:320px;
  animation:nxPop .35s cubic-bezier(.34,1.56,.64,1);font-family:var(--fn)}
#nx-alert span{font-size:11.5px;font-weight:600;color:#92400e;flex:1}
#nx-alert button{padding:4px 10px;border-radius:8px;border:none;
  background:#f59e0b;color:#fff;cursor:pointer;font-size:11px;font-weight:700;white-space:nowrap}
#nx-alert-close{background:transparent!important;color:#92400e!important;padding:2px 6px!important;font-size:14px!important}
/* ── Panel ────────────────────────────────────────────────────────────── */
#nx-panel{position:fixed;bottom:94px;right:26px;z-index:10000;
  width:min(500px,calc(100vw - 18px));height:min(700px,calc(100vh - 112px));
  background:var(--bg);border-radius:20px;border:1px solid var(--bd);
  display:flex;flex-direction:column;box-shadow:var(--sh);
  overflow:hidden;transform-origin:bottom right;font-family:var(--fn)}
#nx-panel.nh{display:none}
#nx-panel.nm{height:62px}
#nx-panel.np{animation:nxPop .32s cubic-bezier(.34,1.56,.64,1)}
/* ── Header ───────────────────────────────────────────────────────────── */
#nx-hdr{padding:13px 16px;display:flex;align-items:center;gap:11px;
  background:var(--hdr);border-bottom:2px solid rgba(37,99,235,.6);flex-shrink:0}
.nx-av{width:40px;height:40px;border-radius:12px;flex-shrink:0;
  background:linear-gradient(135deg,#1e40af,#7c3aed);
  border:1.5px solid rgba(255,255,255,.2);
  display:flex;align-items:center;justify-content:center;
  animation:nxFl 4s ease-in-out infinite;position:relative}
.nx-av svg{width:18px;height:18px}
.nx-live{position:absolute;bottom:1px;right:1px;width:9px;height:9px;
  border-radius:50%;background:#22c55e;border:2px solid #0f172a;animation:nxPu 2s infinite}
.nx-hi{flex:1;min-width:0}
.nx-hi h3{font-size:13.5px;font-weight:700;color:#f1f5f9;letter-spacing:.15px;
  display:flex;align-items:center;gap:7px}
.nx-rt{font-size:9px;font-weight:700;letter-spacing:.8px;text-transform:uppercase;
  padding:1px 7px;border-radius:20px;
  background:<%= _isAdmin ? "rgba(167,139,250,.25)" : "rgba(96,165,250,.2)" %>;
  color:<%= _isAdmin ? "#c4b5fd" : "#93c5fd" %>}
.nx-sub{font-size:10.5px;color:#475569;margin-top:2px;display:flex;align-items:center;gap:4px}
.nx-sub .d{width:5px;height:5px;border-radius:50%;background:#22c55e;animation:nxPu 2s infinite}
.nx-hbs{display:flex;gap:2px}
.nx-hb{background:transparent;border:none;cursor:pointer;color:white;width:30px;height:30px;
  padding:8px;border-radius:7px;display:flex;transition:color .15s,background .15s}
.nx-hb:hover{color:blue;background:white;}
.nx-hb svg{align-items: center;width:14px;height:14px;stroke:currentColor;fill:none;stroke-width:2;stroke-linecap:round;stroke-linejoin:round}
/* ── Toast ─────────────────────────────────────────────────────────────── */
#nx-toast{position:absolute;top:66px;left:50%;transform:translateX(-50%);
  border-radius:10px;padding:7px 14px;font-size:12px;font-weight:600;
  display:none;white-space:nowrap;z-index:5;font-family:var(--fn)}
#nx-toast.er{background:#fef2f2;color:#dc2626;border:1px solid #fecaca;box-shadow:0 3px 12px rgba(220,38,38,.1)}
#nx-toast.ok{background:#f0fdf4;color:#16a34a;border:1px solid #bbf7d0;box-shadow:0 3px 12px rgba(5,150,105,.1)}
#nx-toast.in{background:#eef2ff;color:#4338ca;border:1px solid #c7d2fe}
/* ── Feed ──────────────────────────────────────────────────────────────── */
#nx-feed{flex:1;overflow-y:auto;padding:16px 14px;display:flex;flex-direction:column;
  gap:13px;background:var(--feed);scrollbar-width:thin;scrollbar-color:#d1d5db transparent}
#nx-feed::-webkit-scrollbar{width:4px}
#nx-feed::-webkit-scrollbar-thumb{background:#cbd5e1;border-radius:4px}
/* ── Bubbles ───────────────────────────────────────────────────────────── */
.nx-row{display:flex;flex-direction:column;animation:nxFd .2s ease-out}
.nx-row.me{align-items:flex-end}
.nx-row.ai{align-items:flex-start}
.nx-inner{display:flex;align-items:flex-end;gap:8px;max-width:92%}
.nx-bub{padding:10px 14px;font-size:13.5px;line-height:1.68;word-break:break-word}
.nx-bub.me{background:var(--ub);border-radius:18px 18px 4px 18px;color:#fff;
  box-shadow:0 3px 12px rgba(30,64,175,.24)}
.nx-bub.ai{background:var(--ab);border-radius:18px 18px 18px 4px;
  color:var(--tx);border:1px solid var(--bd);box-shadow:0 1px 4px rgba(0,0,0,.05)}
.nx-bub.ai strong{color:#1e40af;font-weight:600}
.nx-bub.me strong{color:#bfdbfe}
.nx-ts{font-size:10px;color:var(--mu2);margin-top:3px;padding:0 3px}
.nx-row.me .nx-ts{text-align:right}
.nx-mav{width:27px;height:27px;border-radius:9px;flex-shrink:0;
  background:linear-gradient(135deg,#1e40af,#7c3aed);
  display:flex;align-items:center;justify-content:center;
  box-shadow:0 2px 6px rgba(30,64,175,.25)}
.nx-mav svg{width:12px;height:12px}
/* ── Typing ─────────────────────────────────────────────────────────────── */
#nx-typing{display:none;align-items:flex-end;gap:8px}
.nx-tb{background:#fff;border:1px solid var(--bd);border-radius:18px 18px 18px 4px;
  padding:11px 16px;display:flex;gap:5px;align-items:center;box-shadow:0 1px 4px rgba(0,0,0,.05)}
.nx-td{width:7px;height:7px;border-radius:50%;background:#94a3b8;
  display:inline-block;animation:nxBn 1.2s infinite}
.nx-td:nth-child(2){animation-delay:.2s}
.nx-td:nth-child(3){animation-delay:.4s}
/* ── Chips ─────────────────────────────────────────────────────────────── */
#nx-chips{padding:8px 13px 4px;display:flex;gap:6px;overflow-x:auto;
  border-top:1px solid var(--bd);flex-shrink:0;background:#fff;scrollbar-width:none}
#nx-chips::-webkit-scrollbar{display:none}
.nx-chip{flex-shrink:0;padding:5px 11px;border-radius:20px;font-size:11.5px;font-weight:500;
  border:1.5px solid var(--bd);background:#fff;color:var(--mu);
  cursor:pointer;white-space:nowrap;font-family:var(--fn);transition:all .15s ease}
.nx-chip:hover{background:#eff6ff;border-color:rgba(37,99,235,.35);color:#1d4ed8;transform:translateY(-1px)}
/* ── Input ─────────────────────────────────────────────────────────────── */
#nx-bar{padding:10px 12px 12px;border-top:1px solid var(--bd);
  display:flex;align-items:flex-end;gap:9px;background:#fff;flex-shrink:0}
#nx-inp{flex:1;background:#f1f5f9;border:1.5px solid #e2e8f0;border-radius:14px;
  padding:10px 14px;color:var(--tx);font-size:13.5px;font-family:var(--fn);
  resize:none;outline:none;min-height:44px;max-height:110px;line-height:1.5;
  transition:border-color .2s,background .2s,box-shadow .2s}
#nx-inp::placeholder{color:var(--mu2)}
#nx-inp:focus{border-color:#93c5fd;background:#fff;box-shadow:0 0 0 3px rgba(37,99,235,.08)}
#nx-snd{width:44px;height:44px;border-radius:12px;border:none;
  background:linear-gradient(135deg,#1e40af,#2563eb);cursor:pointer;
  display:flex;align-items:center;justify-content:center;flex-shrink:0;
  box-shadow:0 3px 12px rgba(30,64,175,.3);transition:transform .2s,box-shadow .2s,opacity .2s}
#nx-snd:hover{transform:scale(1.07);box-shadow:0 5px 18px rgba(30,64,175,.42)}
#nx-snd:active{transform:scale(.94)}
#nx-snd:disabled{opacity:.4;cursor:not-allowed;transform:none}
#nx-snd svg{width:17px;height:17px;stroke:#fff;fill:none;stroke-width:2.2;stroke-linecap:round;stroke-linejoin:round}
/* ── Cards ─────────────────────────────────────────────────────────────── */
.nx-card{margin-top:10px;border-radius:14px;padding:14px;font-size:12.5px;
  font-family:var(--fn);border:1.5px solid var(--bd);background:#fff;
  box-shadow:0 2px 8px rgba(0,0,0,.05)}
.nx-card.order  {border-color:#bfdbfe;background:#f0f7ff}
.nx-card.inv    {border-color:#fde68a;background:#fffbeb}
.nx-card.inv.crit{border-color:#fecaca;background:#fff5f5}
.nx-card.ret    {border-color:#fde68a;background:#fffbeb}
.nx-card.ticket {border-color:#c7d2fe;background:#eef2ff}
.nx-card.hr     {border-color:#bbf7d0;background:#f0fdf4}
.nx-card.agent  {border-color:#fed7aa;background:#fff7ed}
.nx-card.summary{border-color:#bfdbfe;background:linear-gradient(135deg,#eff6ff,#f5f3ff)}
.nx-card.upd    {border-color:#bfdbfe;background:#fff}
.nx-card.notif  {border-color:#bbf7d0;background:#f0fdf4}
.nx-card.leave  {border-color:#ddd6fe;background:#faf5ff}
.nx-card.ok     {border-color:#86efac!important;background:#f0fdf4!important}
.nx-card.err    {border-color:#fecaca!important;background:#fff5f5!important}
.nx-ch{display:flex;justify-content:space-between;align-items:center;margin-bottom:11px}
.nx-ct{font-weight:700;font-size:13px;color:var(--tx)}
.nx-cr{display:flex;justify-content:space-between;align-items:center;margin-bottom:7px}
.nx-cl{color:var(--mu);font-size:11px;font-weight:500}
.nx-cv{color:var(--tx);font-weight:600;font-size:12px}
.nx-div{height:1px;background:var(--bd);margin:9px 0}
/* badges */
.nx-bk{padding:3px 10px;border-radius:20px;font-size:10px;font-weight:700;
  display:inline-flex;align-items:center;letter-spacing:.3px}
.nx-bk.g{background:#dcfce7;color:#16a34a;border:1px solid #bbf7d0}
.nx-bk.b{background:#dbeafe;color:#1d4ed8;border:1px solid #bfdbfe}
.nx-bk.p{background:#ede9fe;color:#7c3aed;border:1px solid #ddd6fe}
.nx-bk.a{background:#fef3c7;color:#b45309;border:1px solid #fde68a}
.nx-bk.r{background:#fee2e2;color:#dc2626;border:1px solid #fecaca}
.nx-bk.i{background:#e0e7ff;color:#4338ca;border:1px solid #c7d2fe}
.nx-bk.or{background:#ffedd5;color:#c2410c;border:1px solid #fed7aa}
.nx-bk.gy{background:#f3f4f6;color:#374151;border:1px solid #d1d5db}
/* buttons */
.nx-br{display:flex;gap:7px;margin-top:11px;flex-wrap:wrap}
.nx-btn{padding:8px 14px;border-radius:10px;border:none;cursor:pointer;
  font-size:12px;font-weight:600;font-family:var(--fn);
  transition:all .15s;display:inline-flex;align-items:center;gap:5px}
.nx-btn.pr{background:linear-gradient(135deg,#1e40af,#2563eb);color:#fff;box-shadow:0 2px 8px rgba(30,64,175,.28)}
.nx-btn.pr:hover{filter:brightness(1.08);transform:translateY(-1px)}
.nx-btn.su{background:linear-gradient(135deg,#059669,#047857);color:#fff}
.nx-btn.da{background:linear-gradient(135deg,#dc2626,#b91c1c);color:#fff}
.nx-btn.am{background:linear-gradient(135deg,#d97706,#b45309);color:#fff}
.nx-btn.pu{background:linear-gradient(135deg,#7c3aed,#6d28d9);color:#fff}
.nx-btn.or{background:linear-gradient(135deg,#ea580c,#c2410c);color:#fff}
.nx-btn.gh{background:#f1f5f9;color:#475569;border:1.5px solid #e2e8f0}
.nx-btn.gh:hover{background:#e2e8f0;color:#1e293b}
.nx-btn:active{transform:translateY(1px)!important}
.nx-btn:disabled{opacity:.45;cursor:not-allowed;transform:none!important;filter:none!important}
/* form fields */
.nx-fi{width:100%;margin-bottom:8px;padding:9px 12px;border-radius:9px;
  background:#f8fafc;border:1.5px solid #e2e8f0;color:var(--tx);
  font-size:12.5px;font-family:var(--fn);outline:none;transition:border-color .2s}
.nx-fi:focus{border-color:#93c5fd;box-shadow:0 0 0 3px rgba(37,99,235,.08);background:#fff}
.nx-fi::placeholder{color:var(--mu2)}
.nx-ta{width:100%;margin-bottom:8px;padding:9px 12px;border-radius:9px;
  background:#f8fafc;border:1.5px solid #e2e8f0;color:var(--tx);
  font-size:12.5px;font-family:var(--fn);outline:none;resize:none;min-height:68px;transition:border-color .2s}
.nx-ta:focus{border-color:#93c5fd;background:#fff}
.nx-ta::placeholder{color:var(--mu2)}
.nx-sel{width:100%;margin-bottom:8px;padding:9px 12px;border-radius:9px;
  background:#f8fafc;border:1.5px solid #e2e8f0;color:var(--tx);
  font-size:12.5px;font-family:var(--fn);outline:none;cursor:pointer}
/* mini row inside cards */
.nx-trow{display:flex;align-items:center;gap:8px;padding:7px 9px;
  background:rgba(255,255,255,.7);border-radius:9px;border:1px solid rgba(0,0,0,.05);margin-bottom:6px}
.nx-tname{flex:1;font-size:12px;font-weight:600;color:var(--tx);min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.nx-tsub{font-size:10.5px;color:var(--mu);white-space:nowrap}
/* progress bar */
.nx-prog{height:5px;background:#e2e8f0;border-radius:3px;overflow:hidden;margin-top:4px}
.nx-progf{height:100%;border-radius:3px;transition:width .5s}
/* empty state */
.nx-empty{flex:1;display:flex;flex-direction:column;align-items:center;justify-content:center;
  gap:11px;text-align:center;padding:24px}
.nx-eico{width:58px;height:58px;border-radius:18px;
  background:linear-gradient(135deg,#eff6ff,#ede9fe);
  border:1.5px solid rgba(30,64,175,.18);
  display:flex;align-items:center;justify-content:center}
.nx-eico svg{width:26px;height:26px}
.nx-empty h4{color:var(--tx);font-size:15px;font-weight:700}
.nx-empty p{font-size:13px;line-height:1.65;max-width:280px;color:var(--tx2)}
/* keyframes */
@keyframes nxPop{from{opacity:0;transform:scale(.88) translateY(12px)}to{opacity:1;transform:scale(1) translateY(0)}}
@keyframes nxFd {from{opacity:0;transform:translateY(5px)}to{opacity:1;transform:translateY(0)}}
@keyframes nxFl {0%,100%{transform:translateY(0)}50%{transform:translateY(-3px)}}
@keyframes nxPu {0%,100%{opacity:1}50%{opacity:.4}}
@keyframes nxBn {0%,80%,100%{transform:translateY(0)}40%{transform:translateY(-6px)}}
/* mobile */
@media(max-width:540px){
  #nx-panel{bottom:0;right:0;left:0;width:100vw;height:100dvh;border-radius:0;border:none}
  #nx-fab{bottom:18px;right:18px}
  #nx-alert{top:auto;bottom:90px;right:8px;left:8px;max-width:unset}
}
</style>

<div id="nx">
  <!-- Proactive overload alert (shown via JS when agents overloaded) -->
  <div id="nx-alert">
    ⚠ <span id="nx-alert-msg">Agent overload detected</span>
    <button onclick="NX.openTickets()">View</button>
    <button id="nx-alert-close" onclick="this.parentElement.style.display='none'">✕</button>
  </div>

  <!-- FAB -->
  <button id="nx-fab" onclick="NX.toggle()" title="Nexus AI">
    <span id="nx-fab-badge"></span>
    <svg id="nx-fi" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" stroke="#fff" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/>
    </svg>
    <svg id="nx-fx" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" stroke="#fff" fill="none" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" style="display:none">
      <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
    </svg>
  </button>

  <!-- Panel -->
  <div id="nx-panel" class="nh">
    <div id="nx-toast"></div>

    <!-- Header -->
    <div id="nx-hdr">
      <div class="nx-av">
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="rgba(255,255,255,.9)" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
          <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/>
        </svg>
        <span class="nx-live"></span>
      </div>
      <div class="nx-hi">
        <h3>Nexus Operations AI <span class="nx-rt"><%= _sRole.toUpperCase() %></span></h3>
        <div class="nx-sub"><span class="d"></span><span>Live · SmartStock Internal</span></div>
      </div>
      <div class="nx-hbs">
        <button class="nx-hb" onclick="NX.minimize()" title="Minimise"><svg viewBox="0 0 24 24"><line x1="5" y1="12" x2="19" y2="12"/></svg></button>
        <button class="nx-hb" onclick="NX.newChat()" title="Clear &amp; start new session"><svg viewBox="0 0 24 24"><path d="M3 6h18M8 6V4h8v2M19 6l-1 14H6L5 6"/><path d="M10 11v6M14 11v6"/></svg></button>
        <button class="nx-hb" onclick="NX.close()" title="Close"><svg viewBox="0 0 24 24"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg></button>
      </div>
    </div>

    <!-- Feed -->
    <div id="nx-feed"></div>

    <!-- Chips -->
    <div id="nx-chips">
      <button class="nx-chip" onclick="NX.chip('Show me today\'s operations summary')">📊 Summary</button>
      <button class="nx-chip" onclick="NX.chip('Show all pending orders')">📦 Pending Orders</button>
      <button class="nx-chip" onclick="NX.chip('Check inventory and stock levels')">📋 Inventory</button>
      <button class="nx-chip" onclick="NX.chip('Show open customer support tickets')">🎫 Tickets</button>
      <button class="nx-chip" onclick="NX.chip('Show return requests pending review')">↩ Returns</button>
      <button class="nx-chip" onclick="NX.chip('Show today\'s attendance')">👥 Attendance</button>
      <button class="nx-chip" onclick="NX.chip('Show pending leave requests')">🏖 Leave</button>
      <button class="nx-chip" onclick="NX.chip('Show delivery agent workload')">🚚 Agents</button>
      <% if (_isAdmin) { %>
      <button class="nx-chip" onclick="NX.chip('Give me a revenue breakdown')">💰 Revenue</button>
      <% } %>
    </div>

    <!-- Input -->
    <div id="nx-bar">
      <textarea id="nx-inp" rows="1" placeholder="Ask about orders, inventory, tickets, staff, agents…"
        onkeydown="if(event.key==='Enter'&&!event.shiftKey){event.preventDefault();NX.send()}"
        oninput="NX.resize(this)"></textarea>
      <button id="nx-snd" onclick="NX.send()">
        <svg viewBox="0 0 24 24"><line x1="22" y1="2" x2="11" y2="13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/></svg>
      </button>
    </div>
  </div>
</div>

<script>
(function(){
'use strict';

var S={
  open:false,mini:false,loading:false,
  token:null,unread:0,ready:false,
  isAdmin:<%= _isAdmin ? "true" : "false" %>,
  staffName:'<%= _sName.replace("\\", "\\\\").replaceAll("'", "\\\\'") %>'
};

var panel=id('nx-panel'),feed=id('nx-feed'),inp=id('nx-inp'),
    snd=id('nx-snd'),badge=id('nx-fab-badge'),
    fab=id('nx-fab'),fi=id('nx-fi'),fx=id('nx-fx'),
    toast=id('nx-toast'),typing=null;

function id(i){return document.getElementById(i)}

/* ══ PUBLIC API ══════════════════════════════════════════════════════════ */
window.NX={
  toggle:function(){S.open?this.close():this.open()},
  open:function(){
    S.open=true;S.mini=false;
    panel.className='np';setTimeout(function(){panel.classList.remove('np')},400);
    fab.classList.add('open');fi.style.display='none';fx.style.display='';
    S.unread=0;badge.style.display='none';
    if(!S.ready){S.ready=true;boot()}
    setTimeout(function(){inp.focus();scrollBot()},80);
  },
  close:function(){
    S.open=false;panel.className='nh';
    fab.classList.remove('open');fi.style.display='';fx.style.display='none';
  },
  minimize:function(){
    S.mini=!S.mini;
    panel.className=S.mini?'nm':'';
    ['nx-feed','nx-chips','nx-bar'].forEach(function(i){id(i).style.display=S.mini?'none':''});
  },
  newChat:function(){
    if(!confirm('Start a new session? Current chat will be saved and closed.'))return;
    // BUG FIX: close session on server so next boot() gets a fresh one
    if(S.token){fetch('StaffAIChatServlet',{method:'POST',body:new URLSearchParams({action:'newSession'})}).catch(function(){});}
    S.token=null;feed.innerHTML='';S.ready=false;
    // Restore chips/bar visibility after clear
    ['nx-chips','nx-bar'].forEach(function(i){var el=id(i);if(el)el.style.display='';});
    boot();
  },
  chip:function(t){inp.value=t;this.send()},
  resize:function(el){el.style.height='auto';el.style.height=Math.min(el.scrollHeight,110)+'px'},
  openTickets:function(){this.chip('Show open customer support tickets')},

  send:function(override){
    var text=typeof override==='string'?override:inp.value.trim();
    if(!text||S.loading)return;
    inp.value='';this.resize(inp);
    addBubble('me',text,null,null,now());
    sendAI(text);
  },

  /* ── Order status update ── */
  _updateOrder:async function(btn,oid,status){
    if(!oid||!status){toast_('Missing order ID or status','er');return}
    disBtns(btn);btn.textContent='Updating…';
    try{
      var r=await post({action:'updateOrder',orderId:oid,status:status});
      var d=await r.json();
      if(!d.success)throw new Error(d.error||'Update failed');
      var card=btn.closest('.nx-card');
      card.className='nx-card ok';
      card.innerHTML=okHtml('Order #'+oid+' → '+status,'Status updated successfully by '+S.staffName+'.');
      toast_('Order updated!','ok');
    }catch(e){enBtn(btn,'✓ Update');toast_(e.message,'er')}
  },

  /* ── Custom status update from select ── */
  _applyStatusCard:async function(btn,oid){
    var sel=btn.closest('.nx-card').querySelector('[data-f="ss"]');
    if(!sel){toast_('Select a status first','er');return}
    await this._updateOrder(btn,oid,sel.value);
  },

  /* ── Resolve a customer support ticket ── */
  _resolveTicket:async function(btn,ticketId){
    if(!confirm('Mark ticket #T'+ticketId+' as resolved?'))return;
    disBtns(btn);btn.textContent='Resolving…';
    try{
      var r=await post({action:'resolveTicket',ticketId:String(ticketId)});
      var d=await r.json();
      if(!d.success)throw new Error(d.error||'Failed');
      var card=btn.closest('.nx-card');
      card.className='nx-card ok';
      card.innerHTML=okHtml('Ticket #T'+ticketId+' Resolved','Marked as resolved by '+S.staffName+'.');
      toast_('Ticket resolved!','ok');
    }catch(e){enBtn(btn,'✓ Resolve');toast_(e.message,'er')}
  },

  /* ── Notify customer (FEEDBACK LOOP) ── */
  _showNotifyForm:function(btn,orderId,customerId){
    var card=btn.closest('.nx-card');
    var existing=card.querySelector('.nx-notif-form');
    if(existing){existing.style.display=existing.style.display==='none'?'block':'none';return}
    var form=document.createElement('div');form.className='nx-notif-form';
    form.style.marginTop='10px';
    form.innerHTML='<textarea class="nx-ta" data-f="nm" placeholder="Message to customer (e.g. Your order has been shipped and will arrive tomorrow)…"></textarea>'
      +'<div class="nx-br">'
      +'<button class="nx-btn su" onclick="NX._sendNotify(this,\''+safe(String(orderId))+'\',\''+safe(String(customerId))+'\')">📢 Send to Customer</button>'
      +'<button class="nx-btn gh" onclick="this.closest(\'.nx-notif-form\').style.display=\'none\'">Cancel</button>'
      +'</div>';
    card.appendChild(form);
  },

  _sendNotify:async function(btn,orderId,customerId){
    var msg=btn.closest('.nx-notif-form').querySelector('[data-f="nm"]').value.trim();
    if(!msg){toast_('Please type a message first','er');return}
    disBtns(btn);btn.textContent='Sending…';
    try{
      var r=await post({action:'notifyCustomer',orderId:orderId,customerId:customerId,message:msg});
      var d=await r.json();
      if(!d.success)throw new Error(d.error||'Failed');
      btn.closest('.nx-notif-form').innerHTML='<div style="color:#16a34a;font-size:12px;font-weight:600;padding:6px 0">✓ Notification sent to customer successfully!</div>';
      toast_('Customer notified!','ok');
    }catch(e){enBtn(btn,'📢 Send');toast_(e.message,'er')}
  },

  /* ── Approve/Reject leave (admin only) ── */
  _processLeave:async function(btn,leaveId,decision){
    if(!S.isAdmin){toast_('Only admins can approve or reject leave.','er');return;}
    var card=btn.closest('.nx-card');
    var remarks=card.querySelector('[data-f="lr"]');
    var rem=remarks?remarks.value.trim():'';
    disBtns(btn);btn.textContent=decision==='approved'?'Approving…':'Rejecting…';
    try{
      var r=await post({action:'approveLeave',leaveId:String(leaveId),decision:decision,remarks:rem});
      var d=await r.json();
      if(!d.success)throw new Error(d.error||'Failed');
      card.className='nx-card ok';
      var col=decision==='approved'?'#16a34a':'#dc2626';
      card.innerHTML='<div style="display:flex;align-items:center;gap:10px;padding:4px 0">'
        +'<div style="width:34px;height:34px;border-radius:50%;background:'+(decision==='approved'?'#dcfce7':'#fee2e2')+';border:1px solid '+(decision==='approved'?'#86efac':'#fecaca')+';display:flex;align-items:center;justify-content:center;flex-shrink:0">'
        +'<svg width="16" height="16" viewBox="0 0 24 24" stroke="'+col+'" fill="none" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg></div>'
        +'<div><div style="color:'+col+';font-weight:700;font-size:13px">Leave '+(decision==='approved'?'Approved':'Rejected')+'</div>'
        +'<div style="color:'+col+';font-size:11.5px;margin-top:2px">Leave #'+leaveId+' processed by '+S.staffName+'</div></div></div>';
      toast_('Leave '+decision+'!','ok');
    }catch(e){enBtn(btn,decision==='approved'?'✓ Approve':'✕ Reject');toast_(e.message,'er')}
  },

  /* ── Load and show live data cards ── */
  _loadTickets:async function(){
    try{
      var r=await fetch('StaffAIChatServlet?action=lookupTickets');
      var d=await r.json();
      if(!d.count){
        addBubble('ai','✅ No open customer support tickets right now.',null,now());
        return;
      }
      addBubble('ai','Found **'+d.count+'** open customer support ticket'+(d.count!==1?'s':'')+':',null,now());
      d.tickets.slice(0,6).forEach(function(t){
        appendToLast(buildTicketCard(t));
      });
    }catch(e){toast_(e.message||'Failed to load tickets','er')}
  },

  _loadInventory:async function(){
    try{
      var r=await fetch('StaffAIChatServlet?action=lookupInventory');
      var d=await r.json();
      addBubble('ai','📦 **Inventory: '+d.outOfStock+' out of stock, '+d.lowStock+' low**',null,now());
      appendToLast(buildInventoryCard(d));
    }catch(e){toast_(e.message||'Failed','er')}
  },

  _loadAttendance:async function(){
    try{
      var r=await fetch('StaffAIChatServlet?action=getAttendance');
      var d=await r.json();
      if(d.isAdmin){
        if(!d.total){
          addBubble('ai','👥 **Today\'s Attendance** — No sessions recorded yet.',null,now());
          return;
        }
        addBubble('ai','👥 **Today\'s Attendance** — '+d.total+' staff session'+(d.total!==1?'s':'')+' · '+d.present+' currently active:',null,now());
      } else {
        if(!d.total){
          addBubble('ai','⏰ You have no attendance session recorded for today. Please punch in via the **Attendance** page.',null,now());
          return;
        }
        addBubble('ai','⏰ **Your attendance for today:**',null,now());
      }
      appendToLast(buildAttendanceCard(d));
    }catch(e){toast_(e.message||'Failed','er')}
  },

  _loadLeave:async function(){
    try{
      var r=await fetch('StaffAIChatServlet?action=getLeave');
      var d=await r.json();
      if(d.isAdmin){
        // Admin: show all pending requests with approve/reject
        if(!d.count){
          addBubble('ai','✅ No pending leave requests right now.',null,now());
          return;
        }
        addBubble('ai','🏖 **'+d.count+' pending leave request'+(d.count!==1?'s':'')+'** awaiting approval:',null,now());
      } else {
        // Staff: show their own full leave history
        if(!d.count){
          addBubble('ai','You have no leave requests yet. Use the **Apply Leave** page to submit one.',null,now());
          return;
        }
        addBubble('ai','🏖 **Your leave requests** ('+d.count+' total):',null,now());
      }
      d.requests.slice(0,8).forEach(function(lr){appendToLast(buildLeaveCard(lr))});
    }catch(e){toast_(e.message||'Failed','er')}
  },

  _loadAgents:async function(){
    try{
      var r=await fetch('StaffAIChatServlet?action=agentMetrics');
      var d=await r.json();
      addBubble('ai','🚚 **Delivery Agent Workload** ('+d.agents.length+' agents):',null,now());
      appendToLast(buildAgentCard(d.agents));
      // Proactive alert for overloaded agents
      var over=d.agents.filter(function(a){return a.overloaded});
      if(over.length>0){
        var alertEl=id('nx-alert');
        id('nx-alert-msg').textContent='⚠ '+over.length+' agent'+(over.length>1?'s are':' is')+' overloaded (>3 orders)';
        alertEl.style.display='flex';
        setTimeout(function(){alertEl.style.display='none'},8000);
      }
    }catch(e){toast_(e.message||'Failed','er')}
  },

  _lookupOrder:async function(btn,oid){
    disBtn(btn);btn.textContent='Loading…';
    try{
      var r=await fetch('StaffAIChatServlet?action=lookupOrder&orderId='+encodeURIComponent(oid));
      var d=await r.json();
      if(!d.found)throw new Error(d.error||'Order not found');
      appendToLast(buildOrderDetailCard(d.order));
      enBtn(btn,'🔍 Refresh');
    }catch(e){enBtn(btn,'🔍 View Detail');toast_(e.message,'er')}
  },

  /* ── Expand order detail INLINE inside the ticket card ── */
  _expandTicketOrder:async function(btn,oid,tid){
    var target=document.getElementById('tkt-orddiv-'+tid);
    if(!target){toast_('Order section not found','er');return}
    // Toggle
    if(target.style.display!=='none'&&target.innerHTML){target.style.display='none';btn.textContent='📋 View Order';return}
    btn.disabled=true;btn.textContent='Loading…';
    try{
      var r=await fetch('StaffAIChatServlet?action=lookupOrder&orderId='+encodeURIComponent(oid));
      var d=await r.json();
      if(!d.found)throw new Error(d.error||'Order not found');
      target.innerHTML='';
      target.appendChild(buildOrderDetailCard(d.order));
      target.style.display='block';
      btn.textContent='📋 Hide Order';
    }catch(e){toast_(e.message,'er');btn.textContent='📋 View Order';}
    btn.disabled=false;
  },

  /* ── Send reply to customer AND resolve the ticket in one step ── */
  _resolveTicketFull:async function(btn,ticketId,orderId,customerId){
    var card=btn.closest('.nx-card');
    var ta=card.querySelector('[data-f="reply"]');
    var msg=ta?ta.value.trim():'';

    // If staff typed a message, send it first
    if(msg&&customerId&&customerId!=='0'){
      disBtn(btn);btn.textContent='Sending…';
      try{
        var nr=await post({action:'notifyCustomer',orderId:orderId,customerId:customerId,message:msg});
        var nd=await nr.json();
        if(!nd.success)throw new Error(nd.error||'Notify failed');
      }catch(e){
        enBtn(btn,'✓ Send & Resolve');
        toast_('Could not send message: '+e.message,'er');
        return;
      }
    }else if(msg&&(!customerId||customerId==='0')){
      // Has message but no customer ID — still try with orderId
      if(orderId&&orderId!=='0'){
        try{
          await post({action:'notifyCustomer',orderId:orderId,customerId:'0',message:msg});
        }catch(e){/* ignore — resolve still proceeds */}
      }
    }

    // Now resolve the ticket
    btn.textContent='Resolving…';
    try{
      var rr=await post({action:'resolveTicket',ticketId:String(ticketId)});
      var rd=await rr.json();
      if(!rd.success)throw new Error(rd.error||'Resolve failed');
      card.className='nx-card ok';
      var sentNote=msg?' Message sent to customer.':'';
      card.innerHTML=okHtml(
        'Ticket #T'+ticketId+' Resolved',
        'Marked as resolved by '+S.staffName+'.'+sentNote
      );
      toast_('Ticket resolved'+(msg?' and customer notified':'')+'!','ok');
    }catch(e){enBtn(btn,'✓ Send & Resolve');toast_(e.message,'er')}
  }
};

/* ══ BOOT ════════════════════════════════════════════════════════════════ */
function boot(){
  fetch('StaffAIChatServlet?action=history')
    .then(function(r){return r.ok?r.json():null})
    .then(function(d){
      if(!d)return showWelcome();
      if(d.sessionToken)S.token=d.sessionToken;
      if(!d.messages||!d.messages.length)return showWelcome();
      d.messages.forEach(function(m){addBubble(m.role==='user'?'me':'ai',m.content,m.cardType,m.cardRefId,m.sentAt)});
      scrollBot();
    }).catch(showWelcome);

  // Proactive: check agent overload silently on open
  setTimeout(function(){
    fetch('StaffAIChatServlet?action=agentMetrics')
      .then(function(r){return r.json()})
      .then(function(d){
        var over=d.agents?d.agents.filter(function(a){return a.overloaded}):[];
        if(over.length>0){
          var alertEl=id('nx-alert');
          id('nx-alert-msg').textContent='⚠ '+over.length+' delivery agent'+(over.length>1?'s are':' is')+' overloaded with >3 active orders';
          alertEl.style.display='flex';
          badge.textContent=over.length;badge.style.display='flex';
          setTimeout(function(){alertEl.style.display='none'},10000);
        }
      }).catch(function(){});
  },1500);
}

/* ══ LIVE TICKET BADGE — polls every 60s even while Nexus is closed ══════ */
(function ticketPoll(){
  function check(){
    fetch('StaffAIChatServlet?action=lookupTickets')
      .then(function(r){return r.json()})
      .then(function(d){
        if(!d||typeof d.count==='undefined')return;
        var n=d.count||0;
        if(n>0&&!S.open){
          badge.textContent=n;badge.style.display='flex';
        }else if(S.open||n===0){
          if(!S.unread){badge.style.display='none';}
        }
        // Update alert banner if new urgent ticket arrived
        var urgent=d.tickets?d.tickets.filter(function(t){
          return t.paymentStatus==='INTERCEPT_REQUESTED'||t.paymentStatus==='ADDRESS_CORRECTION';
        }):[];
        if(urgent.length>0){
          var alertEl=id('nx-alert');
          if(alertEl.style.display==='none'||!alertEl.style.display){
            id('nx-alert-msg').textContent='🔴 '+urgent.length+' urgent ticket'+(urgent.length>1?'s require':'s requires')+' immediate action';
            alertEl.style.display='flex';
            setTimeout(function(){alertEl.style.display='none'},12000);
          }
        }
      }).catch(function(){});
  }
  setTimeout(check,2000);          // first check 2s after page load
  setInterval(check,60000);        // then every 60 seconds
})();

function showWelcome(){
  var w=document.createElement('div');w.className='nx-empty';
  w.innerHTML='<div class="nx-eico"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="26" height="26" stroke="#1e40af" fill="none" stroke-width="1.8"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg></div>'
    +'<h4>Hi '+esc(S.staffName)+'! I\'m Nexus 👋</h4>'
    +'<p>Your unified operations AI. Orders, inventory, customer tickets, HR, and delivery agent management — all in one place.</p>';
  feed.appendChild(w);
  setTimeout(function(){
    addBubble('ai','Hello **'+esc(S.staffName)+'**! 👋 I\'m **Nexus**, your SmartStock operations AI.\n\n'
      +'I have live access to:\n'
      +'• **Orders** — pending, shipped, failed payments\n'
      +'• **Inventory** — stock alerts & restock suggestions\n'
      +'• **Customer Tickets** — resolve & notify customers directly\n'
      +'• **Returns** — review and approve/reject\n'
      +'• **HR** — attendance & leave management\n'
      +'• **Delivery Agents** — workload & assignment\n\n'
      +'Use the chips below or type anything to get started!',null,now());
  },400);
}

/* ══ AI CALL ═════════════════════════════════════════════════════════════ */
function sendAI(text){
  showTyping(true);S.loading=true;snd.disabled=true;
  fetch('StaffAIChatServlet',{method:'POST',body:new URLSearchParams({action:'message',message:text})})
    .then(function(r){return r.ok?r.json():r.json().then(function(e){throw new Error(e.error||'Error '+r.status)})})
    .then(function(d){
      if(d.sessionToken&&!S.token)S.token=d.sessionToken;
      showTyping(false);
      addBubble('ai',d.text,d.cardType,d.cardRefId,now());
      /* auto-load live data for specific card types */
      if(d.cardType==='ticket_list')    NX._loadTickets();
      if(d.cardType==='inventory_alert')NX._loadInventory();
      if(d.cardType==='attendance_summary')NX._loadAttendance();
      if(d.cardType==='leave_list')     NX._loadLeave();
      if(d.cardType==='agent_metrics')  NX._loadAgents();
      if(!S.open){S.unread++;badge.textContent=S.unread;badge.style.display='flex'}
    })
    .catch(function(e){showTyping(false);toast_(e.message,'er');addBubble('ai','⚠ Sorry, I had a hiccup. Please try again.',null,now())})
    .finally(function(){S.loading=false;snd.disabled=false;inp.focus()});
}

/* ══ BUBBLE ══════════════════════════════════════════════════════════════ */
function addBubble(role,text,cardType,refId,ts){
  var empty=feed.querySelector('.nx-empty');if(empty)empty.remove();
  var row=document.createElement('div');row.className='nx-row '+role;
  var inner=document.createElement('div');inner.className='nx-inner';

  if(role==='ai'){
    var av=document.createElement('div');av.className='nx-mav';
    av.innerHTML='<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="12" height="12" stroke="#fff" fill="none" stroke-width="2"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg>';
    inner.appendChild(av);
  }

  var wrap=document.createElement('div');wrap.style.maxWidth='91%';
  var bub=document.createElement('div');bub.className='nx-bub '+role;
  bub.innerHTML=fmt(text);wrap.appendChild(bub);

  /* static card from history */
  if(cardType&&refId){
    var c=buildStaticCard(cardType,refId);if(c)wrap.appendChild(c);
  }

  if(ts){var te=document.createElement('div');te.className='nx-ts';te.textContent=fmtTs(ts);wrap.appendChild(te)}
  inner.appendChild(wrap);row.appendChild(inner);feed.appendChild(row);scrollBot();return row;
}

function appendToLast(el){
  var rows=feed.querySelectorAll('.nx-row.ai');var last=rows[rows.length-1];if(!last)return;
  var wrap=last.querySelector('.nx-inner>div:last-child');
  if(wrap){var ts=wrap.querySelector('.nx-ts');ts?wrap.insertBefore(el,ts):wrap.appendChild(el)}
  scrollBot();
}

function buildStaticCard(type,refId){
  /* For history replay — show minimal static cards */
  if(type==='order_detail'){
    var c=document.createElement('div');c.className='nx-card order';
    c.innerHTML='<div class="nx-ch"><span class="nx-ct" style="color:#1d4ed8">📋 Order #'+esc(refId)+'</span></div>'
      +'<div class="nx-br"><button class="nx-btn pr" onclick="NX._lookupOrder(this,\''+safe(refId)+'\')">🔍 View Detail</button>'
      +'<a href="OrdersDashboard" class="nx-btn gh" style="text-decoration:none">📄 Orders Page</a></div>';
    return c;
  }
  if(type==='order_status_update'){
    var parts=refId.split('|');var oid=parts[0],st=parts[1]||'';
    var c2=document.createElement('div');c2.className='nx-card upd';
    c2.innerHTML='<div class="nx-ch"><span class="nx-ct">Update Order #'+esc(oid)+'</span></div>'
      +'<div style="font-size:11.5px;color:#64748b;margin-bottom:8px">Proposed status: <strong style="color:#1d4ed8">'+esc(st)+'</strong></div>'
      +'<div class="nx-br"><button class="nx-btn pr" onclick="NX._updateOrder(this,\''+safe(oid)+'\',\''+safe(st)+'\')">✓ Confirm Update</button>'
      +'<button class="nx-btn gh" onclick="this.closest(\'.nx-card\').remove()">Cancel</button></div>';
    return c2;
  }
  return null;
}

/* ══ LIVE DATA CARD BUILDERS ═════════════════════════════════════════════ */

function buildTicketCard(t){
  var c=document.createElement('div');c.className='nx-card ticket';
  var sid=safe(String(t.id)),soid=safe(String(t.orderId||0)),scid=safe(String(t.customerId||0));

  // ── Human-readable type label + badge colour ───────────────────────────
  var typeMap={
    'TICKET':       {col:'i', label:'General Support'},
    'CHAT_ACTION':  {col:'b', label:'Chat Request'},
    'INTERCEPT_REQUESTED':{col:'r', label:'⚡ Courier Intercept'},
    'ADDRESS_CORRECTION': {col:'or',label:'⚡ Address Redirect'},
    'REFUND_PENDING':     {col:'a', label:'COD Refund'}
  };
  var typeInfo=typeMap[t.paymentStatus]||{col:'gy',label:t.paymentStatus||'Ticket'};
  var isUrgent=t.paymentStatus==='INTERCEPT_REQUESTED'||t.paymentStatus==='ADDRESS_CORRECTION';

  // Pulse border on urgent tickets
  if(isUrgent){c.style.cssText='border-color:#fca5a5!important;animation:nxPu 2s infinite;'}

  // Time-ago from createdAt
  var timeAgo='';
  if(t.createdAt){
    try{
      var diff=Date.now()-new Date(t.createdAt);
      if(diff<3600000) timeAgo=Math.floor(diff/60000)+'m ago';
      else if(diff<86400000) timeAgo=Math.floor(diff/3600000)+'h ago';
      else timeAgo=Math.floor(diff/86400000)+'d ago';
    }catch(e){}
  }

  c.innerHTML=
    // ── Header ──────────────────────────────────────────────────────────
    '<div class="nx-ch" style="margin-bottom:8px">'
    +'<div style="display:flex;align-items:center;gap:7px">'
    +'<span class="nx-ct" style="color:#4338ca">🎫 Ticket #T'+esc(String(t.id))+'</span>'
    +(timeAgo?'<span style="font-size:10px;color:#94a3b8;font-weight:400">'+timeAgo+'</span>':'')
    +'</div>'
    +'<div style="display:flex;align-items:center;gap:5px">'
    +'<span class="nx-bk '+typeInfo.col+'">'+esc(typeInfo.label)+'</span>'
    +(isUrgent?'<span style="font-size:10px;font-weight:700;color:#dc2626;animation:nxPu 1s infinite">URGENT</span>':'')
    +'</div></div>'

    // ── Customer info ────────────────────────────────────────────────────
    +'<div class="nx-cr"><span class="nx-cl">Customer</span>'
    +'<span class="nx-cv">'+esc(t.customerName||'Unknown')+'</span></div>'
    +'<div class="nx-cr"><span class="nx-cl">Phone</span>'
    +'<span class="nx-cv" style="display:flex;align-items:center;gap:6px">'
    +'<a href="tel:'+esc(t.customerPhone||'')+'" style="color:#1d4ed8;text-decoration:none;font-weight:700">📞 '+esc(t.customerPhone||'—')+'</a>'
    +(t.customerPhone?'<button onclick="navigator.clipboard.writeText(\''+safe(t.customerPhone||'')+'\').then(function(){this.textContent=\'✓\';var b=this;setTimeout(function(){b.textContent=\'Copy\'},1500)}.bind(this))" style="padding:2px 7px;border-radius:6px;border:1px solid #e2e8f0;background:#f8fafc;font-size:10px;font-weight:600;cursor:pointer;color:#475569">Copy</button>':'')
    +'</span></div>'
    +(t.customerEmail?'<div class="nx-cr"><span class="nx-cl">Email</span><span class="nx-cv" style="font-size:11px">'+esc(t.customerEmail)+'</span></div>':'')
    +(t.orderId?'<div class="nx-cr"><span class="nx-cl">Order</span><span class="nx-cv">#'+esc(String(t.orderId))+'</span></div>':'')
    +(t.total?'<div class="nx-cr"><span class="nx-cl">Order Total</span><span class="nx-cv">₹'+parseFloat(t.total).toFixed(2)+'</span></div>':'')

    // ── Issue + action ───────────────────────────────────────────────────
    +'<div class="nx-div"></div>'
    +'<div style="font-size:11px;font-weight:700;color:#374151;margin-bottom:5px">Issue reported by customer:</div>'
    +'<div style="font-size:12px;color:#1e293b;background:rgba(255,255,255,.7);border-radius:8px;padding:8px 10px;border:1px solid rgba(0,0,0,.06);line-height:1.6;margin-bottom:8px">'+esc(t.issue||'—')+'</div>'
    +(t.action&&t.action.trim()&&t.action!=='CHAT_ACTION'?
      '<div style="font-size:11px;font-weight:700;color:#dc2626;margin-bottom:4px">Action required:</div>'
      +'<div style="font-size:12px;color:#dc2626;background:#fff5f5;border-radius:8px;padding:7px 10px;border:1px solid #fecaca;margin-bottom:8px">'+esc(t.action)+'</div>'
      :'')

    // ── Resolution workflow label ─────────────────────────────────────────
    +'<div class="nx-div"></div>'
    +'<div style="font-size:11px;font-weight:700;color:#374151;margin-bottom:8px;display:flex;align-items:center;gap:5px">'
    +'<span style="background:#e0e7ff;color:#4338ca;border-radius:6px;padding:2px 7px;font-size:10px">RESOLVE WORKFLOW</span></div>'

    // Step 1 (conditional): View order
    +(t.orderId?
      '<div style="display:flex;align-items:center;gap:7px;margin-bottom:7px">'
      +'<div style="width:20px;height:20px;border-radius:50%;background:#dbeafe;border:1.5px solid #93c5fd;display:flex;align-items:center;justify-content:center;flex-shrink:0;font-size:10px;font-weight:700;color:#1d4ed8">1</div>'
      +'<span style="font-size:12px;color:#374151;font-weight:500">Review the order before responding</span></div>'
      +'<div id="tkt-orddiv-'+sid+'" style="margin-bottom:8px;display:none"></div>'
      :'')

    // Step 2: Reply
    +'<div style="display:flex;align-items:center;gap:7px;margin-bottom:7px">'
    +'<div style="width:20px;height:20px;border-radius:50%;background:#f0fdf4;border:1.5px solid #86efac;display:flex;align-items:center;justify-content:center;flex-shrink:0;font-size:10px;font-weight:700;color:#15803d">'+(t.orderId?'2':'1')+'</div>'
    +'<span style="font-size:12px;color:#374151;font-weight:500">Send resolution message to customer</span></div>'
    +'<textarea class="nx-ta" data-f="reply" placeholder="e.g. We have looked into your case. Your replacement will be dispatched within 24 hours. Tracking ID will be sent by SMS." style="min-height:78px"></textarea>'
    +'<div style="font-size:11px;color:#64748b;margin-bottom:8px;margin-top:-4px">Customer sees this in their GreenCart chat widget instantly.</div>'

    // Step 3: Resolve
    +'<div style="display:flex;align-items:center;gap:7px;margin-bottom:8px">'
    +'<div style="width:20px;height:20px;border-radius:50%;background:#fef3c7;border:1.5px solid #fde68a;display:flex;align-items:center;justify-content:center;flex-shrink:0;font-size:10px;font-weight:700;color:#b45309">'+(t.orderId?'3':'2')+'</div>'
    +'<span style="font-size:12px;color:#374151;font-weight:500">Mark ticket as resolved</span></div>'

    // ── Buttons ───────────────────────────────────────────────────────────
    +'<div class="nx-br">'
    +(t.orderId?'<button class="nx-btn pr" onclick="NX._expandTicketOrder(this,\''+soid+'\',\''+sid+'\')">📋 View Order</button>':'')
    +'<button class="nx-btn su" onclick="NX._resolveTicketFull(this,\''+sid+'\',\''+soid+'\',\''+scid+'\')">✓ Send &amp; Resolve</button>'
    +'<button class="nx-btn gh" onclick="NX._resolveTicket(this,\''+sid+'\')">Resolve only</button>'
    +'</div>';

  return c;
}

function buildInventoryCard(d){
  var c=document.createElement('div');c.className='nx-card inv'+(d.outOfStock>0?' crit':'');
  var pct=d.total>0?Math.round(d.inStock/d.total*100):0;
  var col=pct>70?'#059669':pct>40?'#d97706':'#dc2626';
  c.innerHTML='<div class="nx-ch"><span class="nx-ct" style="color:'+(d.outOfStock>0?'#dc2626':'#d97706')+'">📦 Inventory Status</span>'
    +'<span class="nx-bk '+(d.outOfStock>0?'r':'a')+'">'+d.outOfStock+' OOS</span></div>'
    +'<div class="nx-cr"><span class="nx-cl">In Stock</span><span class="nx-bk g">'+d.inStock+'</span></div>'
    +'<div class="nx-cr"><span class="nx-cl">Low Stock</span><span class="nx-bk a">'+d.lowStock+'</span></div>'
    +'<div class="nx-cr"><span class="nx-cl">Out of Stock</span><span class="nx-bk r">'+d.outOfStock+'</span></div>'
    +'<div class="nx-prog"><div class="nx-progf" style="width:'+pct+'%;background:'+col+'"></div></div>'
    +'<div style="font-size:10px;color:#64748b;margin-top:3px">'+pct+'% in stock</div>';

  if(d.critical&&d.critical.length){
    c.innerHTML+='<div class="nx-div"></div><div style="font-size:11px;font-weight:700;color:#92400e;margin-bottom:6px">Critical Items:</div>';
    d.critical.slice(0,6).forEach(function(p){
      c.innerHTML+='<div class="nx-trow">'
        +'<span class="nx-tname">'+esc(p.name)+'</span>'
        +'<span class="nx-bk '+(p.urgent?'r':'a')+'">'+p.stock+' left</span>'
        +'<a href="ProductServlet?action=edit&id='+safe(String(p.id))+'" class="nx-btn pr" style="text-decoration:none;padding:4px 8px;font-size:10px;flex-shrink:0">+ Restock</a>'
        +'</div>';
    });
  }
  c.innerHTML+='<div class="nx-br"><a href="ProductServlet?action=stock" class="nx-btn su" style="text-decoration:none">📦 Manage Stock</a>'
    +'<button class="nx-btn gh" onclick="NX.chip(\'Which products need restocking?\')">More</button></div>';
  return c;
}

function buildAttendanceCard(d){
  var c=document.createElement('div');c.className='nx-card hr';
  var today=new Date().toLocaleDateString('en-IN',{day:'numeric',month:'short',year:'numeric'});

  if(S.isAdmin){
    // ── Admin view: summary counts + full staff list ──────────────────────
    c.innerHTML='<div class="nx-ch">'
      +'<span class="nx-ct" style="color:#059669">👥 Attendance — '+today+'</span>'
      +'<span class="nx-bk g">'+d.present+' Active</span></div>'
      +'<div class="nx-cr"><span class="nx-cl">Total Sessions</span><span class="nx-cv">'+d.total+'</span></div>'
      +'<div class="nx-cr"><span class="nx-cl">Completed</span><span class="nx-cv">'+d.completed+'</span></div>'
      +'<div class="nx-cr"><span class="nx-cl">Currently Active</span><span class="nx-bk g">'+d.present+'</span></div>';

    if(d.sessions&&d.sessions.length){
      c.innerHTML+='<div class="nx-div"></div>';
      d.sessions.slice(0,8).forEach(function(s){
        var st=(s.attendanceStatus||s.status||'active').toLowerCase();
        var bk=st.includes('late')?'a':st.includes('absent')?'r':st.includes('overtime')?'pu':'g';
        c.innerHTML+='<div class="nx-trow">'
          +'<span class="nx-tname">'+esc(s.username)+'</span>'
          +'<span class="nx-tsub">In: '+(s.punchIn?s.punchIn.substring(11,16):'—')+(s.punchOut?' · Out: '+s.punchOut.substring(11,16):'')+'</span>'
          +'<span class="nx-bk '+bk+'">'+esc(s.attendanceStatus||s.status||'Active')+'</span>'
          +'</div>';
      });
      if(d.sessions.length>8){
        c.innerHTML+='<div style="font-size:11px;color:#64748b;margin-top:4px;text-align:center">+ '+(d.sessions.length-8)+' more</div>';
      }
    }
    c.innerHTML+='<div class="nx-br">'
      +'<a href="AttendanceServlet" class="nx-btn su" style="text-decoration:none">📋 Full Report</a>'
      +'<button class="nx-btn gh" onclick="NX.chip(\'Show today attendance\')">↻ Refresh</button>'
      +'</div>';

  } else {
    // ── Staff view: their own session detail only ─────────────────────────
    var s=d.sessions&&d.sessions.length?d.sessions[0]:null;
    if(!s){
      c.innerHTML='<div class="nx-ch"><span class="nx-ct" style="color:#059669">⏰ My Attendance — '+today+'</span></div>'
        +'<p style="color:#64748b;font-size:12px;margin:4px 0">No session recorded yet today.</p>'
        +'<div class="nx-br"><a href="AttendanceServlet" class="nx-btn su" style="text-decoration:none">Punch In</a></div>';
      return c;
    }
    var st=(s.attendanceStatus||s.status||'active').toLowerCase();
    var bk=st.includes('late')?'a':st.includes('absent')?'r':st.includes('overtime')?'pu':'g';
    var stLabel=s.attendanceStatus||s.status||'Active';
    // Format time: "2025-05-26T09:03:00" → "09:03"
    var pIn  = s.punchIn  ? s.punchIn.substring(11,16)  : '—';
    var pOut = s.punchOut ? s.punchOut.substring(11,16) : null;
    // Compute hours worked if both punches present
    var hoursWorked='';
    if(s.punchIn&&s.punchOut){
      try{
        var diff=(new Date(s.punchOut)-new Date(s.punchIn))/3600000;
        hoursWorked=(diff>0?diff.toFixed(1)+' hrs':'');
      }catch(e){}
    }

    c.innerHTML='<div class="nx-ch">'
      +'<span class="nx-ct" style="color:#059669">⏰ My Attendance — '+today+'</span>'
      +'<span class="nx-bk '+bk+'">'+esc(stLabel)+'</span></div>'
      +'<div class="nx-cr"><span class="nx-cl">Punch In</span><span class="nx-cv" style="font-size:13px;font-weight:700;color:#059669">'+pIn+'</span></div>'
      +(pOut
        ?'<div class="nx-cr"><span class="nx-cl">Punch Out</span><span class="nx-cv" style="font-size:13px;font-weight:700;color:#dc2626">'+pOut+'</span></div>'
        :'<div class="nx-cr"><span class="nx-cl">Punch Out</span><span class="nx-cv" style="color:#d97706;font-size:11.5px;font-weight:600">Still active</span></div>')
      +(hoursWorked?'<div class="nx-cr"><span class="nx-cl">Hours Worked</span><span class="nx-cv">'+hoursWorked+'</span></div>':'')
      +'<div class="nx-br">'
      +'<a href="AttendanceServlet" class="nx-btn su" style="text-decoration:none">📋 My Attendance</a>'
      +'<button class="nx-btn gh" onclick="NX.chip(\'Show today attendance\')">↻ Refresh</button>'
      +'</div>';
  }
  return c;
}

function buildLeaveCard(lr){
  var c=document.createElement('div');c.className='nx-card leave';
  var sid=safe(String(lr.id));
  // Dynamic status badge
  var stLow=(lr.status||'pending').toLowerCase();
  var stBk=stLow==='approved'?'g':stLow==='rejected'?'r':stLow==='cancelled'?'gy':'a';
  var stLabel=stLow.charAt(0).toUpperCase()+stLow.slice(1);
  // Session type label
  var sesLabel={'full_day':'Full Day','first_half':'First Half','second_half':'Second Half'}[lr.sessionType||'']||lr.sessionType||'Full Day';

  // ── Common header + core details (all users) ──────────────────────────
  c.innerHTML='<div class="nx-ch">'
    +'<span class="nx-ct" style="color:#7c3aed">🏖 Leave Request #'+esc(String(lr.id))+'</span>'
    +'<span class="nx-bk '+stBk+'">'+stLabel+'</span></div>'
    // Show employee name only to admin (staff sees their own requests)
    +(S.isAdmin?'<div class="nx-cr"><span class="nx-cl">Employee</span><span class="nx-cv">'+esc(lr.username)+'</span></div>':'')
    +'<div class="nx-cr"><span class="nx-cl">Leave Type</span>'
    +'<span class="nx-cv">'+esc(lr.leaveType)+'<span class="nx-bk '+(lr.paid?'g':'gy')+'" style="margin-left:5px;font-size:9px">'+(lr.paid?'PAID':'UNPAID')+'</span></span></div>'
    +'<div class="nx-cr"><span class="nx-cl">Period</span><span class="nx-cv">'+esc(fmtD(lr.fromDate))+' → '+esc(fmtD(lr.toDate))+'</span></div>'
    +'<div class="nx-cr"><span class="nx-cl">Duration</span><span class="nx-cv">'+esc(String(lr.days))+' working day'+(lr.days!='1'?'s':'')+' · '+sesLabel+'</span></div>'
    +'<div class="nx-cr"><span class="nx-cl">Reason</span><span class="nx-cv" style="font-size:11px;text-align:right;max-width:60%">'+esc(truncate(lr.reason||'',80))+'</span></div>'
    +(lr.contactDuringLeave?'<div class="nx-cr"><span class="nx-cl">Contact</span><span class="nx-cv">'+esc(lr.contactDuringLeave)+'</span></div>':'')
    +(lr.coveringPerson?'<div class="nx-cr"><span class="nx-cl">Covered By</span><span class="nx-cv">'+esc(lr.coveringPerson)+'</span></div>':'')
    +(lr.workHandover?'<div class="nx-cr"><span class="nx-cl">Handover</span><span class="nx-cv" style="font-size:11px;text-align:right;max-width:60%">'+esc(truncate(lr.workHandover||'',60))+'</span></div>':'')
    +(lr.appliedOn?'<div class="nx-cr"><span class="nx-cl">Applied On</span><span class="nx-cv" style="font-size:11px">'+esc(fmtD(lr.appliedOn))+'</span></div>':'')
    +(lr.documentPath?'<div class="nx-cr"><span class="nx-cl">Document</span><span class="nx-cv"><a href="LeaveDocServlet?file='+encodeURIComponent(lr.documentPath)+'" target="_blank" style="color:#7c3aed;font-size:11px;font-weight:600">📎 View File</a></span></div>':'');

  // ── Reviewer info (shown when already processed) ──────────────────────
  if(lr.reviewedBy && stLow!=='pending'){
    c.innerHTML+='<div class="nx-div"></div>'
      +'<div class="nx-cr"><span class="nx-cl">Reviewed By</span><span class="nx-cv">'+esc(lr.reviewedBy)+'</span></div>'
      +(lr.reviewedOn?'<div class="nx-cr"><span class="nx-cl">Reviewed On</span><span class="nx-cv" style="font-size:11px">'+esc(fmtD(lr.reviewedOn))+'</span></div>':'')
      +(lr.reviewerNote?'<div class="nx-cr"><span class="nx-cl">Remarks</span><span class="nx-cv" style="font-size:11px;text-align:right;max-width:60%">'+esc(lr.reviewerNote)+'</span></div>':'');
  }
  if(lr.cancelReason && stLow==='cancelled'){
    c.innerHTML+=(lr.reviewedBy?'':'<div class="nx-div"></div>')
      +'<div class="nx-cr"><span class="nx-cl">Cancel Reason</span><span class="nx-cv" style="font-size:11px;text-align:right;max-width:60%">'+esc(lr.cancelReason)+'</span></div>';
  }

  // ── Action area ───────────────────────────────────────────────────────
  if(S.isAdmin && stLow==='pending'){
    // Admin: remarks + approve/reject
    c.innerHTML+='<div class="nx-div"></div>'
      +'<input class="nx-fi" data-f="lr" placeholder="Remarks (optional)" style="margin-top:2px"/>'
      +'<div class="nx-br">'
      +'<button class="nx-btn su" onclick="NX._processLeave(this,\''+sid+'\',\'approved\')">✓ Approve</button>'
      +'<button class="nx-btn da" onclick="NX._processLeave(this,\''+sid+'\',\'rejected\')">✕ Reject</button>'
      +'</div>';
  } else if(S.isAdmin){
    // Admin: already-processed, link to full dashboard
    c.innerHTML+='<div class="nx-br"><a href="AdminLeaveServlet" class="nx-btn gh" style="text-decoration:none">📋 Leave Dashboard</a></div>';
  } else {
    // Staff: read-only — show apply button for pending/rejected, track link otherwise
    c.innerHTML+='<div class="nx-br">'
      +(stLow==='pending'?'<span style="font-size:11px;color:#d97706;font-weight:600;display:flex;align-items:center;gap:4px"><svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>Awaiting admin approval</span>':'')
      +(stLow==='approved'?'<span style="font-size:11px;color:#16a34a;font-weight:600;display:flex;align-items:center;gap:4px"><svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>Approved</span>':'')
      +(stLow==='rejected'?'<span style="font-size:11px;color:#dc2626;font-weight:600;display:flex;align-items:center;gap:4px"><svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>Rejected</span>':'')
      +(stLow==='cancelled'?'<span style="font-size:11px;color:#64748b;font-weight:600">Cancelled</span>':'')
      +'<a href="LeaveServlet" class="nx-btn gh" style="text-decoration:none;margin-left:auto">📋 My Leaves</a>'
      +(stLow==='rejected'?'<a href="LeaveServlet" class="nx-btn pr" style="text-decoration:none">+ Apply Again</a>':'')
      +'</div>';
  }
  return c;
}

function buildAgentCard(agents){
  var c=document.createElement('div');c.className='nx-card agent';
  var overloaded=agents.filter(function(a){return a.overloaded});
  c.innerHTML='<div class="nx-ch"><span class="nx-ct" style="color:#c2410c">🚚 Delivery Agent Workload</span>'
    +'<span class="nx-bk '+(overloaded.length>0?'r':'g')+'">'+(overloaded.length>0?overloaded.length+' Overloaded':'All OK')+'</span></div>';

  if(!agents.length){c.innerHTML+='<p style="color:#94a3b8;font-size:12px">No delivery agents found.</p>';return c}

  agents.forEach(function(a){
    var barCol=a.pendingOrders>3?'#dc2626':a.pendingOrders>1?'#d97706':'#059669';
    var pct=Math.min(a.pendingOrders/6*100,100);
    c.innerHTML+='<div class="nx-trow">'
      +'<div style="flex:1;min-width:0">'
      +'<div style="display:flex;justify-content:space-between;align-items:center">'
      +'<span class="nx-tname">'+esc(a.username)+'</span>'
      +'<span class="nx-bk '+(a.status==='Active'?'g':'r')+'" style="flex-shrink:0">'+esc(a.status)+'</span>'
      +'</div>'
      +'<div style="display:flex;justify-content:space-between;align-items:center;margin-top:2px">'
      +'<span style="font-size:10px;color:#64748b">'+a.pendingOrders+' active order'+(a.pendingOrders!==1?'s':'')+(a.overloaded?' ⚠ Overloaded':'')+'</span>'
      +(a.mobile?'<a href="tel:'+esc(a.mobile)+'" style="font-size:10px;color:#1d4ed8;text-decoration:none">📞 Call</a>':'')
      +'</div>'
      +'<div class="nx-prog" style="margin-top:4px"><div class="nx-progf" style="width:'+pct+'%;background:'+barCol+'"></div></div>'
      +'</div>'
      +'</div>';
  });

  c.innerHTML+='<div class="nx-br"><a href="OrdersDashboard" class="nx-btn pr" style="text-decoration:none">View Orders</a>'
    +'<button class="nx-btn gh" onclick="NX._loadAgents()">↻ Refresh</button></div>';
  return c;
}

function buildOrderDetailCard(o){
  var c=document.createElement('div');c.className='nx-card order';
  var stB=orderBadge(o.status),payB=payBadge(o.paymentStatus);
  var sid=safe(String(o.id)),scid=safe(String(o.customerId));
  c.innerHTML='<div class="nx-ch"><span class="nx-ct" style="color:#1d4ed8">📋 Order #'+esc(String(o.id))+'</span>'
    +'<span class="nx-bk '+stB.c+'">'+esc(stB.l)+'</span></div>'
    +'<div class="nx-cr"><span class="nx-cl">Customer</span><span class="nx-cv">'+esc(o.customerName||'—')+'</span></div>'
    +'<div class="nx-cr"><span class="nx-cl">Phone</span><span class="nx-cv"><a href="tel:'+esc(o.customerPhone||'')+'" style="color:#1d4ed8;text-decoration:none">'+esc(o.customerPhone||'—')+'</a></span></div>'
    +'<div class="nx-cr"><span class="nx-cl">Email</span><span class="nx-cv" style="font-size:11px">'+esc(o.customerEmail||'—')+'</span></div>'
    +'<div class="nx-cr"><span class="nx-cl">Total</span><span class="nx-cv">₹'+parseFloat(o.totalAmount||0).toFixed(2)+'</span></div>'
    +'<div class="nx-cr"><span class="nx-cl">Payment</span><span class="nx-cv">'+esc(o.paymentMethod||'')
    +' <span class="nx-bk '+payB.c+'" style="font-size:9px">'+payB.l+'</span></span></div>'
    +(o.transactionId?'<div class="nx-cr"><span class="nx-cl">Txn ID</span><span class="nx-cv" style="font-size:10px;word-break:break-all">'+esc(o.transactionId)+'</span></div>':'')
    +(o.deliveryAgent?'<div class="nx-cr"><span class="nx-cl">Agent</span><span class="nx-cv">'+esc(o.deliveryAgent)+'</span></div>':'')
    +(o.address?'<div class="nx-cr"><span class="nx-cl">Address</span><span class="nx-cv" style="font-size:11px;text-align:right;max-width:55%">'+esc(o.address)+'</span></div>':'')
    +(o.orderDate?'<div class="nx-cr"><span class="nx-cl">Date</span><span class="nx-cv">'+esc(fmtD(o.orderDate))+'</span></div>':'')
    +(o.deliveryDate?'<div class="nx-cr"><span class="nx-cl">Delivery</span><span class="nx-cv">'+esc(fmtD(o.deliveryDate))+'</span></div>':'');

  if(o.items&&o.items.length){
    c.innerHTML+='<div class="nx-div"></div>';
    o.items.slice(0,4).forEach(function(it){
      c.innerHTML+='<div class="nx-cr"><span class="nx-cl">'+esc(it.name)+'</span><span class="nx-cv">×'+it.qty+' ₹'+parseFloat(it.price||0).toFixed(2)+'</span></div>';
    });
  }

  c.innerHTML+='<div class="nx-div"></div>'
    +'<div style="font-size:11px;font-weight:700;color:#64748b;margin-bottom:8px">Quick Actions:</div>'
    +'<select class="nx-sel" data-f="ss">'
    +'<option value="Processing">Processing</option><option value="Packed">Packed</option>'
    +'<option value="Shipped">Shipped</option><option value="Delivered">Delivered</option>'
    +'<option value="Cancelled">Cancelled</option><option value="Return Requested">Return Requested</option>'
    +'</select>'
    +'<div class="nx-br">'
    +'<button class="nx-btn pr" onclick="NX._applyStatusCard(this,\''+sid+'\')">✓ Update Status</button>'
    +(o.customerId?'<button class="nx-btn pu" onclick="NX._showNotifyForm(this,\''+sid+'\',\''+scid+'\')">📢 Notify Customer</button>':'')
    +'<a href="InvoiceServlet?orderId='+sid+'" target="_blank" class="nx-btn gh" style="text-decoration:none">🧾 Invoice</a>'
    +'</div>';
  return c;
}

/* ══ TYPING ══════════════════════════════════════════════════════════════ */
function showTyping(on){
  if(on){
    if(typing)return;
    typing=document.createElement('div');
    typing.style.cssText='display:flex;align-items:flex-end;gap:8px;animation:nxFd .2s ease';
    typing.innerHTML='<div class="nx-mav"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="12" height="12" stroke="#fff" fill="none" stroke-width="2"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg></div>'
      +'<div class="nx-tb"><span class="nx-td"></span><span class="nx-td"></span><span class="nx-td"></span></div>';
    feed.appendChild(typing);scrollBot();
  }else{if(typing){typing.remove();typing=null}}
}

/* ══ HELPERS ═════════════════════════════════════════════════════════════ */
function post(params){return fetch('StaffAIChatServlet',{method:'POST',body:new URLSearchParams(params)})}
function disBtn(btn){btn.disabled=true;btn.style.opacity='.5';btn.style.cursor='not-allowed'}
function enBtn(btn,lbl){btn.disabled=false;btn.style.opacity='';btn.style.cursor='';btn.textContent=lbl}
function disBtns(btn){btn.closest('.nx-card').querySelectorAll('.nx-btn').forEach(function(b){b.disabled=true})}
function okHtml(t,s){return '<div style="display:flex;align-items:center;gap:11px;padding:3px 0">'
  +'<div style="width:34px;height:34px;border-radius:50%;background:#dcfce7;border:1px solid #86efac;display:flex;align-items:center;justify-content:center;flex-shrink:0">'
  +'<svg width="16" height="16" viewBox="0 0 24 24" stroke="#16a34a" fill="none" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg></div>'
  +'<div><div style="color:#15803d;font-weight:700;font-size:13px">'+esc(t)+'</div>'
  +'<div style="color:#16a34a;font-size:11.5px;margin-top:2px">'+esc(s)+'</div></div></div>'}
function fmt(t){if(!t)return '';return t.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/\*\*(.*?)\*\*/g,'<strong>$1</strong>').replace(/\n/g,'<br>')}
function esc(s){return(s||'').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;')}
function safe(s){return(s||'').replace(/['\"<>&\s]/g,'')}
function truncate(s,n){if(!s)return '';return s.length>n?s.substring(0,n)+'…':s}
function now(){return new Date().toISOString()}
function fmtD(ts){try{var d=new Date(ts);if(isNaN(d))return ts||'—';return d.toLocaleDateString('en-IN',{day:'numeric',month:'short',year:'numeric'})}catch(e){return ts||'—'}}
function fmtTs(ts){try{var d=new Date(ts);if(isNaN(d))return '';var df=Date.now()-d;if(df<60000)return 'Just now';if(df<3600000)return Math.floor(df/60000)+'m ago';return d.toLocaleTimeString([],{hour:'2-digit',minute:'2-digit'})}catch(e){return ''}}
function scrollBot(){requestAnimationFrame(function(){feed.scrollTop=feed.scrollHeight})}
var toastT;
function toast_(msg,cls){toast.textContent=msg;toast.className=cls;toast.style.display='block';clearTimeout(toastT);toastT=setTimeout(function(){toast.style.display='none'},4500)}
function orderBadge(s){var m={'delivered':{c:'g',l:'Delivered'},'shipped':{c:'b',l:'Shipped'},'assigned':{c:'b',l:'Assigned'},'out for delivery':{c:'b',l:'Out for Delivery'},'cancelled':{c:'r',l:'Cancelled'},'return requested':{c:'a',l:'Return Req.'},'refunded':{c:'g',l:'Refunded'},'confirmed':{c:'i',l:'Confirmed'},'processing':{c:'i',l:'Processing'},'pending':{c:'gy',l:'Pending'},'ordered':{c:'gy',l:'Ordered'},'packed':{c:'b',l:'Packed'}};return m[(s||'').toLowerCase()]||{c:'gy',l:s||'—'}}
function payBadge(s){var m={'paid':{c:'g',l:'PAID'},'success':{c:'g',l:'PAID'},'completed':{c:'g',l:'PAID'},'pending_cod':{c:'a',l:'COD'},'payment_failed':{c:'r',l:'FAILED'},'failed':{c:'r',l:'FAILED'},'refund_pending':{c:'a',l:'REFUND'},'awaiting_payment':{c:'b',l:'PENDING'},'intercept_requested':{c:'or',l:'INTERCEPT'}};return m[(s||'').toLowerCase()]||{c:'gy',l:s||'—'}}

})();
</script>