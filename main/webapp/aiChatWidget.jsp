<%@ page language="java" contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<%
    /* ── Auth: detect logged-in customer ── */
    boolean _loggedIn  = false;
    String  _custName  = "there";
    Object  _custObj   = session != null ? session.getAttribute("customer") : null;
    Object  _custIdObj = session != null ? session.getAttribute("customerId") : null;
    if (_custObj instanceof com.util.Customer) {
        com.util.Customer _c = (com.util.Customer) _custObj;
        _loggedIn = true;
        if (_c.getName() != null && !_c.getName().isEmpty())
            _custName = _c.getName().split(" ")[0];
    }
    boolean _isGuest = !_loggedIn;
%>
<style>
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');
#kw*,#kw *::before,#kw *::after{box-sizing:border-box;margin:0;padding:0}
#kw{
  --p:#2563eb;--p2:#4f46e5;
  --bg:#fff;--feed:#f1f5f9;--bd:#e2e8f0;--bd2:#cbd5e1;
  --tx:#0f172a;--tx2:#334155;--mu:#64748b;--mu2:#94a3b8;
  --ub:linear-gradient(135deg,#2563eb,#4f46e5);
  --hdr:linear-gradient(135deg,#1e3a8a,#1e40af);
  --gr:#059669;--re:#dc2626;--am:#d97706;--in:#4338ca;
  --sh:0 4px 6px rgba(0,0,0,.04),0 20px 60px rgba(0,0,0,.10),0 0 0 1px rgba(37,99,235,.08);
  --fn:'Inter',system-ui,sans-serif;
  font-family:var(--fn);
}
/* FAB */
#kw-fab{position:fixed;bottom:26px;right:26px;z-index:10001;width:56px;height:56px;
  border-radius:50%;border:none;cursor:pointer;
  background:linear-gradient(135deg,#1e3a8a,#2563eb);
  display:flex;align-items:center;justify-content:center;
  box-shadow:0 6px 24px rgba(37,99,235,.44);
  transition:transform .3s cubic-bezier(.34,1.56,.64,1),box-shadow .3s;outline:none}
#kw-fab:hover{transform:scale(1.1);box-shadow:0 10px 32px rgba(37,99,235,.55)}
#kw-fab:active{transform:scale(.95)}
#kw-fab svg{width:22px;height:22px;transition:transform .3s}
#kw-fab.open{background:linear-gradient(135deg,#dc2626,#b91c1c)}
#kw-fab.open svg{transform:rotate(90deg)}
#kw-fab-badge{position:absolute;top:-5px;right:-5px;min-width:19px;height:19px;
  border-radius:10px;padding:0 4px;background:#ef4444;color:#fff;font-size:10px;
  font-weight:700;display:none;align-items:center;justify-content:center;
  border:2px solid #fff;font-family:var(--fn)}
/* Banner */
#kw-banner{position:fixed;bottom:92px;right:26px;z-index:10000;
  background:#fff;border:1px solid rgba(37,99,235,.18);border-radius:14px;
  padding:10px 14px;display:none;align-items:center;gap:8px;cursor:pointer;
  box-shadow:0 4px 20px rgba(0,0,0,.09);animation:kwPop .4s cubic-bezier(.34,1.56,.64,1);
  font-family:var(--fn)}
#kw-banner:hover{background:#f0f7ff;border-color:rgba(37,99,235,.3)}
#kw-banner span{font-size:12.5px;font-weight:600;color:#1e293b;white-space:nowrap}
#kw-bx{width:16px;height:16px;border-radius:50%;border:none;background:#f1f5f9;
  color:#94a3b8;cursor:pointer;display:flex;align-items:center;justify-content:center;font-size:10px}
/* Panel */
#kw-panel{position:fixed;bottom:92px;right:26px;z-index:10000;
  width:min(480px,calc(100vw - 16px));height:min(680px,calc(100vh - 108px));
  background:#fff;border-radius:20px;border:1px solid var(--bd);
  display:flex;flex-direction:column;box-shadow:var(--sh);
  overflow:hidden;transform-origin:bottom right;font-family:var(--fn)}
#kw-panel.kh{display:none}
#kw-panel.km{height:62px}
#kw-panel.kp{animation:kwPop .32s cubic-bezier(.34,1.56,.64,1)}
/* Header */
#kw-hdr{padding:12px 15px;display:flex;align-items:center;gap:11px;
  background:var(--hdr);flex-shrink:0}
.kw-av{width:40px;height:40px;border-radius:12px;flex-shrink:0;
  background:rgba(255,255,255,.15);border:1.5px solid rgba(255,255,255,.25);
  display:flex;align-items:center;justify-content:center;
  animation:kwFl 4s ease-in-out infinite;position:relative}
.kw-av svg{width:20px;height:20px}
.kw-live{position:absolute;bottom:1px;right:1px;width:9px;height:9px;
  border-radius:50%;background:#22c55e;border:2px solid #1e3a8a;animation:kwPu 2s infinite}
.kw-hi{flex:1;min-width:0}
.kw-hi h3{font-size:13.5px;font-weight:700;color:#fff;letter-spacing:.15px}
.kw-hsub{display:flex;align-items:center;gap:5px;margin-top:2px}
.kw-hsub .d{width:5px;height:5px;border-radius:50%;background:#22c55e;animation:kwPu 2s infinite}
.kw-hsub span{font-size:11px;color:rgba(255,255,255,.65);font-weight:500}
.kw-hbs{display:flex;gap:2px}
.kw-hb{background:transparent;border:none;cursor:pointer;color:rgba(255,255,255,.55);
  padding:5px;border-radius:7px;display:flex;transition:color .15s,background .15s}
.kw-hb:hover{color: #260dd2fa;
  background: rgba(255, 255, 255, 0.92);}
.kw-hb svg{width:14px;height:14px;stroke:currentColor;fill:none;stroke-width:2;stroke-linecap:round;stroke-linejoin:round}
/* Toast */
#kw-toast{position:absolute;top:66px;left:50%;transform:translateX(-50%);
  border-radius:10px;padding:7px 14px;font-size:12px;font-weight:600;
  display:none;white-space:nowrap;z-index:5;font-family:var(--fn)}
#kw-toast.er{background:#fef2f2;color:#dc2626;border:1px solid #fecaca;box-shadow:0 3px 12px rgba(220,38,38,.1)}
#kw-toast.ok{background:#f0fdf4;color:#16a34a;border:1px solid #bbf7d0;box-shadow:0 3px 12px rgba(5,150,105,.1)}
#kw-toast.wa{background:#fffbeb;color:#b45309;border:1px solid #fde68a;box-shadow:0 3px 12px rgba(212,159,0,.1)}
/* Escalation banner */
#kw-esc{position:absolute;top:66px;left:12px;right:12px;z-index:4;
  background:#fff3cd;border:1.5px solid #f59e0b;border-radius:10px;
  padding:8px 12px;display:none;align-items:center;gap:9px;font-size:12px;font-weight:600;color:#92400e}
#kw-esc button{margin-left:auto;padding:4px 10px;border-radius:8px;border:none;
  background:#f59e0b;color:#fff;cursor:pointer;font-size:11px;font-weight:700;white-space:nowrap}
/* Guest login wall */
#kw-guest{flex:1;display:flex;flex-direction:column;align-items:center;justify-content:center;
  gap:14px;text-align:center;padding:30px 24px;background:var(--feed)}
#kw-guest .kw-gico{width:64px;height:64px;border-radius:20px;background:linear-gradient(135deg,#eff6ff,#e0e7ff);
  border:1.5px solid rgba(37,99,235,.18);display:flex;align-items:center;justify-content:center}
#kw-guest h4{color:var(--tx);font-size:15px;font-weight:700}
#kw-guest p{font-size:13px;line-height:1.65;max-width:270px;color:var(--tx2)}
#kw-guest .kw-login-btn{padding:11px 28px;border-radius:12px;border:none;cursor:pointer;
  background:linear-gradient(135deg,#2563eb,#4f46e5);color:#fff;font-size:13px;font-weight:700;
  font-family:var(--fn);box-shadow:0 4px 14px rgba(37,99,235,.35);transition:all .2s;text-decoration:none;
  display:inline-flex;align-items:center;gap:7px}
#kw-guest .kw-login-btn:hover{filter:brightness(1.1);transform:translateY(-1px)}
#kw-guest .kw-reg-link{font-size:12px;color:var(--mu);margin-top:4px}
#kw-guest .kw-reg-link a{color:var(--p);text-decoration:none;font-weight:600}
/* Feed */
#kw-feed{flex:1;overflow-y:auto;padding:16px 14px;display:flex;flex-direction:column;
  gap:13px;background:var(--feed);scrollbar-width:thin;scrollbar-color:#d1d5db transparent}
#kw-feed::-webkit-scrollbar{width:4px}
#kw-feed::-webkit-scrollbar-thumb{background:#cbd5e1;border-radius:4px}
/* Bubbles */
.kw-row{display:flex;flex-direction:column;animation:kwFd .2s ease-out}
.kw-row.me{align-items:flex-end}
.kw-row.ai{align-items:flex-start}
.kw-inner{display:flex;align-items:flex-end;gap:8px;max-width:91%}
.kw-bub{padding:10px 14px;font-size:13.5px;line-height:1.68;word-break:break-word}
.kw-bub.me{background:var(--ub);border-radius:18px 18px 4px 18px;color:#fff;box-shadow:0 3px 12px rgba(37,99,235,.24)}
.kw-bub.ai{background:#fff;border-radius:18px 18px 18px 4px;color:var(--tx);border:1px solid var(--bd);box-shadow:0 1px 4px rgba(0,0,0,.05)}
.kw-bub.ai strong{color:#1e40af;font-weight:600}
.kw-bub.me strong{color:#bfdbfe}
.kw-ts{font-size:10px;color:var(--mu2);margin-top:3px;padding:0 3px}
.kw-row.me .kw-ts{text-align:right}
.kw-mav{width:27px;height:27px;border-radius:9px;flex-shrink:0;
  background:linear-gradient(135deg,#1e40af,#4f46e5);
  display:flex;align-items:center;justify-content:center;box-shadow:0 2px 6px rgba(37,99,235,.22)}
.kw-mav svg{width:13px;height:13px}
/* Typing */
.kw-tb{background:#fff;border:1px solid var(--bd);border-radius:18px 18px 18px 4px;
  padding:11px 16px;display:flex;gap:5px;align-items:center;box-shadow:0 1px 4px rgba(0,0,0,.05)}
.kw-td{width:7px;height:7px;border-radius:50%;background:#94a3b8;display:inline-block;animation:kwBn 1.2s infinite}
.kw-td:nth-child(2){animation-delay:.2s}.kw-td:nth-child(3){animation-delay:.4s}
/* Chips */
#kw-chips{padding:8px 13px 5px;display:flex;gap:7px;flex-wrap:wrap;
  border-top:1px solid var(--bd);flex-shrink:0;background:#fff}
.kw-chip{padding:5px 12px;border-radius:20px;font-size:11.5px;font-weight:600;
  border:1.5px solid rgba(37,99,235,.2);background:#eff6ff;color:#2563eb;
  cursor:pointer;white-space:nowrap;font-family:var(--fn);transition:all .15s}
.kw-chip:hover{background:#dbeafe;border-color:rgba(37,99,235,.4);color:#1d4ed8;transform:translateY(-1px)}
/* Input */
#kw-bar{padding:10px 12px 12px;border-top:1px solid var(--bd);
  display:flex;align-items:flex-end;gap:9px;background:#fff;flex-shrink:0}
#kw-inp{flex:1;background:#f1f5f9;border:1.5px solid #e2e8f0;border-radius:14px;
  padding:10px 14px;color:var(--tx);font-size:13.5px;font-family:var(--fn);
  resize:none;outline:none;min-height:44px;max-height:110px;line-height:1.5;
  transition:border-color .2s,background .2s,box-shadow .2s}
#kw-inp::placeholder{color:var(--mu2)}
#kw-inp:focus{border-color:#93c5fd;background:#fff;box-shadow:0 0 0 3px rgba(37,99,235,.08)}
#kw-snd{width:44px;height:44px;border-radius:12px;border:none;
  background:linear-gradient(135deg,#2563eb,#4f46e5);cursor:pointer;
  display:flex;align-items:center;justify-content:center;flex-shrink:0;
  box-shadow:0 3px 12px rgba(37,99,235,.3);transition:transform .2s,box-shadow .2s,opacity .2s}
#kw-snd:hover{transform:scale(1.07);box-shadow:0 5px 18px rgba(37,99,235,.42)}
#kw-snd:active{transform:scale(.94)}
#kw-snd:disabled{opacity:.4;cursor:not-allowed;transform:none}
#kw-snd svg{width:17px;height:17px;stroke:#fff;fill:none;stroke-width:2.2;stroke-linecap:round;stroke-linejoin:round}
/* Cards */
.kw-card{margin-top:10px;border-radius:14px;padding:14px;font-size:12.5px;
  font-family:var(--fn);border:1.5px solid var(--bd);background:#fff;box-shadow:0 2px 8px rgba(0,0,0,.05)}
.kw-card.order  {border-color:#bfdbfe;background:#f0f7ff}
.kw-card.cancel {border-color:#ddd6fe;background:#faf5ff}
.kw-card.ship   {border-color:#fed7aa;background:#fff7ed}
.kw-card.deliver{border-color:#bfdbfe;background:#eff6ff}
.kw-card.pay    {border-color:#fecaca;background:#fff5f5}
.kw-card.addr   {border-color:#bbf7d0;background:#f0fdf4}
.kw-card.inv    {border-color:#bfdbfe;background:#f0f7ff}
.kw-card.ret    {border-color:#fde68a;background:#fffbeb}
.kw-card.ticket {border-color:#c7d2fe;background:#eef2ff}
.kw-card.ok     {border-color:#86efac!important;background:#f0fdf4!important}
.kw-card.err    {border-color:#fecaca!important;background:#fff5f5!important}
.kw-ch{display:flex;justify-content:space-between;align-items:center;margin-bottom:11px}
.kw-ct{font-weight:700;font-size:13px;color:var(--tx)}
.kw-cr{display:flex;justify-content:space-between;align-items:center;margin-bottom:7px}
.kw-cl{color:var(--mu);font-size:11px;font-weight:500}
.kw-cv{color:var(--tx);font-weight:600;font-size:12px}
.kw-div{height:1px;background:var(--bd);margin:9px 0}
/* Refund breakdown (new) */
.kw-refund-box{background:#f0fdf4;border:1px solid #86efac;border-radius:10px;padding:10px 12px;margin:8px 0;font-size:12px}
.kw-refund-row{display:flex;justify-content:space-between;align-items:center;padding:2px 0}
.kw-refund-total{border-top:1px solid #86efac;margin-top:6px;padding-top:6px;font-weight:700;color:#15803d;font-size:13px;display:flex;justify-content:space-between}
.kw-deduct-note{background:#fff7ed;border:1px solid #fed7aa;border-radius:8px;padding:8px 10px;font-size:11.5px;color:#9a3412;margin-top:6px;line-height:1.5}
/* Stage pipeline (new) */
.kw-pipeline{display:flex;align-items:center;gap:2px;margin:10px 0;flex-wrap:wrap}
.kw-ps{padding:3px 8px;border-radius:20px;font-size:10px;font-weight:600;white-space:nowrap}
.kw-ps.done{background:#dcfce7;color:#15803d;border:1px solid #86efac}
.kw-ps.curr{background:#2563eb;color:#fff;border:1px solid #1d4ed8}
.kw-ps.future{background:#f3f4f6;color:#6b7280;border:1px solid #e5e7eb}
.kw-ps-arr{color:#cbd5e1;font-size:9px;font-weight:700}
/* Badges */
.kw-bk{padding:3px 10px;border-radius:20px;font-size:10px;font-weight:700;display:inline-flex;align-items:center;letter-spacing:.3px}
.kw-bk.g{background:#dcfce7;color:#16a34a;border:1px solid #bbf7d0}
.kw-bk.b{background:#dbeafe;color:#1d4ed8;border:1px solid #bfdbfe}
.kw-bk.p{background:#ede9fe;color:#7c3aed;border:1px solid #ddd6fe}
.kw-bk.a{background:#fef3c7;color:#b45309;border:1px solid #fde68a}
.kw-bk.r{background:#fee2e2;color:#dc2626;border:1px solid #fecaca}
.kw-bk.i{background:#e0e7ff;color:#4338ca;border:1px solid #c7d2fe}
.kw-bk.or{background:#ffedd5;color:#c2410c;border:1px solid #fed7aa}
.kw-bk.gy{background:#f3f4f6;color:#374151;border:1px solid #d1d5db}
/* Buttons */
.kw-br{display:flex;gap:7px;margin-top:11px;flex-wrap:wrap}
.kw-btn{padding:8px 15px;border-radius:10px;border:none;cursor:pointer;
  font-size:12px;font-weight:600;font-family:var(--fn);transition:all .15s;display:inline-flex;align-items:center;gap:5px}
.kw-btn.pr{background:linear-gradient(135deg,#2563eb,#4f46e5);color:#fff;box-shadow:0 2px 8px rgba(37,99,235,.28)}
.kw-btn.pr:hover{filter:brightness(1.08);transform:translateY(-1px)}
.kw-btn.da{background:linear-gradient(135deg,#dc2626,#b91c1c);color:#fff;box-shadow:0 2px 8px rgba(220,38,38,.25)}
.kw-btn.da:hover{filter:brightness(1.08);transform:translateY(-1px)}
.kw-btn.su{background:linear-gradient(135deg,#059669,#047857);color:#fff}
.kw-btn.am{background:linear-gradient(135deg,#d97706,#b45309);color:#fff}
.kw-btn.in{background:linear-gradient(135deg,#4338ca,#3730a3);color:#fff}
.kw-btn.or{background:linear-gradient(135deg,#ea580c,#c2410c);color:#fff}
.kw-btn.gh{background:#f1f5f9;color:#475569;border:1.5px solid #e2e8f0}
.kw-btn.gh:hover{background:#e2e8f0;color:#1e293b}
.kw-btn:active{transform:translateY(1px)!important}
.kw-btn:disabled{opacity:.45;cursor:not-allowed;transform:none!important;filter:none!important}
/* Form */
.kw-fi{width:100%;margin-bottom:8px;padding:9px 12px;border-radius:9px;
  background:#f8fafc;border:1.5px solid #e2e8f0;color:var(--tx);
  font-size:12.5px;font-family:var(--fn);outline:none;transition:border-color .2s,box-shadow .2s}
.kw-fi:focus{border-color:#93c5fd;box-shadow:0 0 0 3px rgba(37,99,235,.08);background:#fff}
.kw-fi::placeholder{color:var(--mu2)}
.kw-ta{width:100%;margin-bottom:8px;padding:9px 12px;border-radius:9px;
  background:#f8fafc;border:1.5px solid #e2e8f0;color:var(--tx);
  font-size:12.5px;font-family:var(--fn);outline:none;resize:none;min-height:68px;transition:border-color .2s}
.kw-ta:focus{border-color:#93c5fd;background:#fff}
.kw-ta::placeholder{color:var(--mu2)}
.kw-sel{width:100%;margin-bottom:8px;padding:9px 12px;border-radius:9px;
  background:#f8fafc;border:1.5px solid #e2e8f0;color:var(--tx);
  font-size:12.5px;font-family:var(--fn);outline:none;cursor:pointer}
/* Tracker */
.kw-track{margin:10px 0;display:flex;align-items:center}
.kw-step{flex:1;display:flex;flex-direction:column;align-items:center;gap:4px}
.kw-dot{width:12px;height:12px;border-radius:50%;border:2px solid #e2e8f0;background:#f8faff;transition:all .3s}
.kw-dot.dn{background:#059669;border-color:#059669;box-shadow:0 0 6px rgba(5,150,105,.3)}
.kw-dot.ac{background:#2563eb;border-color:#2563eb;box-shadow:0 0 6px rgba(37,99,235,.4);animation:kwPu 1.5s infinite}
.kw-line{flex:1;height:2px;background:#e2e8f0;margin:0 -2px}.kw-line.dn{background:#059669}
.kw-lbl{font-size:9px;color:var(--mu);text-align:center;font-weight:500}
/* Items */
.kw-items{margin:8px 0;display:flex;flex-direction:column;gap:5px}
.kw-item{display:flex;align-items:center;gap:8px;padding:5px 8px;background:rgba(255,255,255,.7);border-radius:9px;border:1px solid rgba(0,0,0,.05)}
.kw-iimg{width:30px;height:30px;border-radius:7px;object-fit:cover;background:#e5e7eb;flex-shrink:0}
.kw-iname{font-size:11.5px;font-weight:600;color:var(--tx);flex:1}
.kw-iqty{font-size:10.5px;color:var(--mu);white-space:nowrap}
/* Action chips */
.kw-achips{display:flex;flex-wrap:wrap;gap:7px;margin-top:11px}
.kw-achip{padding:6px 12px;border-radius:20px;font-size:11.5px;font-weight:600;border:none;cursor:pointer;font-family:var(--fn);transition:all .15s}
.kw-achip.b{background:#dbeafe;color:#1d4ed8}.kw-achip.r{background:#fee2e2;color:#dc2626}
.kw-achip.a{background:#fef3c7;color:#92400e}.kw-achip.g{background:#dcfce7;color:#166534}
.kw-achip.i{background:#e0e7ff;color:#3730a3}.kw-achip.gy{background:#f3f4f6;color:#374151}
.kw-achip.or{background:#ffedd5;color:#c2410c}
.kw-achip:hover{filter:brightness(.93);transform:translateY(-1px)}
/* Empty state */
.kw-empty{flex:1;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:11px;text-align:center;padding:24px}
.kw-eico{width:58px;height:58px;border-radius:18px;background:linear-gradient(135deg,#eff6ff,#e0e7ff);border:1.5px solid rgba(37,99,235,.18);display:flex;align-items:center;justify-content:center}
.kw-empty h4{color:var(--tx);font-size:15px;font-weight:700}
.kw-empty p{font-size:13px;line-height:1.65;max-width:270px;color:var(--tx2)}
/* Keyframes */
@keyframes kwPop{from{opacity:0;transform:scale(.88) translateY(12px)}to{opacity:1;transform:scale(1) translateY(0)}}
@keyframes kwFd {from{opacity:0;transform:translateY(5px)}to{opacity:1;transform:translateY(0)}}
@keyframes kwFl {0%,100%{transform:translateY(0)}50%{transform:translateY(-3px)}}
@keyframes kwPu {0%,100%{opacity:1}50%{opacity:.4}}
@keyframes kwBn {0%,80%,100%{transform:translateY(0)}40%{transform:translateY(-6px)}}

/* ─── Address-change indicators ─────────────────── */
.kw-addr-snap{background:#f0fdf4;border:1.5px solid #86efac;border-radius:10px;padding:9px 12px;margin-bottom:8px}
.kw-addr-snap-lbl{font-size:10.5px;font-weight:700;color:#6b7280;text-transform:uppercase;letter-spacing:.4px;margin-bottom:3px}
.kw-addr-snap-changed{border-color:#fde68a!important;background:#fffbeb!important}
.kw-addr-changed-note{font-size:10.5px;color:#b45309;margin-top:5px;padding-top:5px;border-top:1px solid #fde68a}
.kw-addr-ok-note{font-size:10.5px;color:#16a34a;margin-top:5px}

@media(max-width:500px){
  #kw-panel{bottom:0;right:0;left:0;width:100vw;height:100dvh;border-radius:0;border:none}
  #kw-fab{bottom:18px;right:18px}
  #kw-banner{display:none!important}
}
</style>

<div id="kw">
  <button id="kw-fab" onclick="KW.toggle()" title="Support Chat">
    <span id="kw-fab-badge"></span>
    <svg id="kw-fi" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" stroke="#fff" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>
    <svg id="kw-fx" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" stroke="#fff" fill="none" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" style="display:none"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
  </button>

  <div id="kw-banner" onclick="KW.open()">
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="14" height="14" stroke="#2563eb" fill="none" stroke-width="2"><circle cx="12" cy="12" r="10"/><path d="M12 16v-4M12 8h.01"/></svg>
    <span>Hi <%= _custName %>! Need help with an order?</span>
    <button id="kw-bx" onclick="event.stopPropagation();this.parentElement.style.display='none'">✕</button>
  </div>

  <div id="kw-panel" class="kh">
    <div id="kw-toast"></div>
    <div id="kw-esc">
      ⚠ It looks like you're frustrated — we want to help!
      <button onclick="KW._escalateNow()">Connect Agent</button>
    </div>

    <div id="kw-hdr">
      <div class="kw-av">
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="rgba(255,255,255,.9)" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
          <rect x="3" y="11" width="18" height="10" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/>
          <circle cx="12" cy="16" r="1" fill="rgba(255,255,255,.9)"/>
        </svg>
        <span class="kw-live"></span>
      </div>
      <div class="kw-hi">
        <h3>GreenCart Support</h3>
        <div class="kw-hsub"><span class="d"></span><span>Kira AI · Online</span></div>
      </div>
      <div class="kw-hbs">
        <button class="kw-hb" onclick="KW.minimize()" title="Minimise"><svg viewBox="0 0 24 24"><line x1="5" y1="12" x2="19" y2="12"/></svg></button>
        <button class="kw-hb" onclick="KW.newChat()" title="Clear &amp; start new chat" style="position:relative"><svg viewBox="0 0 24 24"><path d="M3 6h18M8 6V4h8v2M19 6l-1 14H6L5 6"/><path d="M10 11v6M14 11v6"/></svg></button>
        <button class="kw-hb" onclick="KW.close()" title="Close"><svg viewBox="0 0 24 24"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg></button>
      </div>
    </div>

    <%-- Guest wall: shown only if NOT logged in --%>
    <div id="kw-guest" style="display:<%= _isGuest ? "flex" : "none" %>; flex-direction:column;">
      <div class="kw-gico">
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="28" height="28" stroke="#2563eb" fill="none" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
      </div>
      <h4>Login to get support</h4>
      <p>I'm Kira, GreenCart's AI support assistant. To help you with your orders, cancellations, and returns — please log in first.</p>
      <a href="CustomerLogin.jsp" class="kw-login-btn">
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="15" height="15" stroke="#fff" fill="none" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4"/><polyline points="10 17 15 12 10 7"/><line x1="15" y1="12" x2="3" y2="12"/></svg>
        Log In
      </a>
      <div class="kw-reg-link">New customer? <a href="CustomerRegistration.jsp">Create account</a></div>
    </div>

    <div id="kw-feed" style="<%= _isGuest ? "display:none" : "" %>"></div>

    <div id="kw-chips" style="<%= _isGuest ? "display:none" : "" %>">
      <button class="kw-chip" onclick="KW.intent('track')">📦 Track</button>
      <button class="kw-chip" onclick="KW.intent('cancel')">✕ Cancel</button>
      <button class="kw-chip" onclick="KW.intent('return')">↩ Return</button>
      <button class="kw-chip" onclick="KW.intent('address')">📍 Address</button>
      <button class="kw-chip" onclick="KW.intent('payment')">💳 Payment</button>
      <button class="kw-chip" onclick="KW.intent('invoice')">🧾 Invoice</button>
      <button class="kw-chip" onclick="KW.intent('ticket')">🎫 Ticket</button>
    </div>

    <div id="kw-bar" style="<%= _isGuest ? "display:none" : "" %>">
      <textarea id="kw-inp" rows="1" placeholder="Type your message or Order ID…"
        onkeydown="if(event.key==='Enter'&&!event.shiftKey){event.preventDefault();KW.send()}"
        oninput="KW.resize(this)"></textarea>
      <button id="kw-snd" onclick="KW.send()">
        <svg viewBox="0 0 24 24"><line x1="22" y1="2" x2="11" y2="13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/></svg>
      </button>
    </div>
  </div>
</div>

<script>
(function(){
'use strict';

var IS_GUEST = <%= _isGuest ? "true" : "false" %>;

/* ══ STATE ══════════════════════════════════════════════════════════════ */
var S={
  open:false,mini:false,loading:false,
  token:null,unread:0,ready:false,
  phase:'IDLE',          // IDLE | AWAIT_ID | ORDER_LOADED | ACTION_PENDING
  pendingIntent:null,
  currentOrder:null,
  frustScore:0,escalated:false,msgCount:0
};

/* ══ DOM ═════════════════════════════════════════════════════════════════ */
var panel=id('kw-panel'),feed=id('kw-feed'),inp=id('kw-inp'),
    snd=id('kw-snd'),badge=id('kw-fab-badge'),
    fab=id('kw-fab'),fi=id('kw-fi'),fx=id('kw-fx'),
    toast=id('kw-toast'),escBanner=id('kw-esc'),typing=null;
function id(i){return document.getElementById(i)}

/* ══ PUBLIC API ═══════════════════════════════════════════════════════════ */
window.KW={

  toggle:function(){S.open?this.close():this.open()},

  open:function(){
    S.open=true;S.mini=false;
    panel.className='kp';setTimeout(function(){panel.classList.remove('kp')},400);
    fab.classList.add('open');fi.style.display='none';fx.style.display='';
    id('kw-banner').style.display='none';
    S.unread=0;badge.style.display='none';
    if(!IS_GUEST && !S.ready){S.ready=true;boot()}
    setTimeout(function(){if(!IS_GUEST&&inp)inp.focus();scrollBot()},80);
  },

  close:function(){S.open=false;panel.className='kh';fab.classList.remove('open');fi.style.display='';fx.style.display='none';escBanner.style.display='none'},

  minimize:function(){
    S.mini=!S.mini;panel.className=S.mini?'km':'';
    ['kw-feed','kw-chips','kw-bar','kw-guest'].forEach(function(i){var el=id(i);if(el)el.style.display=S.mini?'none':''});
    if(!S.mini && IS_GUEST){['kw-feed','kw-chips','kw-bar'].forEach(function(i){var el=id(i);if(el)el.style.display='none'});id('kw-guest').style.display='flex'}
  },

  newChat:function(){
    if(!confirm('Start a new chat? Your current session will be saved and closed.'))return;
    // BUG FIX: close session on server so next boot() creates a fresh one
    if(S.token){fetch('AIChatServlet',{method:'POST',body:new URLSearchParams({action:'newSession'})}).catch(function(){});}
    S.token=null;S.phase='IDLE';S.pendingIntent=null;S.currentOrder=null;
    S.frustScore=0;S.escalated=false;S.msgCount=0;S.ready=false;
    escBanner.style.display='none';
    feed.innerHTML='';
    // BUG FIX: restore chips and bar for logged-in users after clearing
    if(!IS_GUEST){
      var chips=id('kw-chips'),bar=id('kw-bar');
      if(chips)chips.style.display='';
      if(bar)bar.style.display='';
    }
    boot();
  },

  resize:function(el){el.style.height='auto';el.style.height=Math.min(el.scrollHeight,110)+'px'},

  intent:function(i){
    /* If guest: show login toast and stop */
    if(IS_GUEST){showLoginToast();return}
    if(i==='ticket'){addBubble('me','I need help with a support ticket',null,nowTs());showTicketCard(null);return}
    S.pendingIntent=i;S.phase='AWAIT_ID';
    var labels={'track':'Track Order','cancel':'Cancel Order','return':'Return / Refund',
                'address':'Change Delivery Address','invoice':'Download Invoice','payment':'Payment Issue'};
    addBubble('me',labels[i]||i,null,nowTs());
    showOrderIdPrompt(i);
  },

  send:function(override){
    if(IS_GUEST){showLoginToast();return}
    var text=typeof override==='string'?override:inp.value.trim();
    if(!text||S.loading)return;
    inp.value='';this.resize(inp);
    S.msgCount++;

    /* frustration detection */
    if(!S.escalated){
      var frSigs=[
        /\b(furious|outraged|livid|scam|fraud|sue|lawyer|useless|pathetic|worst|horrible)\b/i,
        /\b(speak to (a )?manager|supervisor|human agent|escalate|enough of this)\b/i,
        /!!+|[A-Z]{5,}/,
        /\b(not acceptable|unacceptable|i give up|last time|stop ignoring)\b/i
      ];
      var matched=frSigs.filter(function(r){return r.test(text)}).length;
      if(matched>0){S.frustScore+=matched;if(S.frustScore>=1)escBanner.style.display='flex'}
      if(S.frustScore>=3||/speak to (a )?manager|supervisor/i.test(text)){
        addBubble('me',text,null,nowTs());
        addBubble('ai','I truly hear you and I sincerely apologise for the frustration. You deserve better. I\'m escalating your case to a **senior agent** immediately.',null,nowTs());
        this._escalateNow();return;
      }
    }

    /* AWAIT_ID phase */
    if(S.phase==='AWAIT_ID'){
      var match=text.match(/\b(\d{1,10})\b/);
      if(!match){
        addBubble('me',text,null,nowTs());
        addBubble('ai','Please provide a valid **Order ID** (e.g. **56** or **ORD-56**). You can find it in **My Orders** or your confirmation email.',null,nowTs());
        return;
      }
      addBubble('me',text,null,nowTs());
      lookupOrder(parseInt(match[1]),S.pendingIntent);return;
    }

    var lower=text.toLowerCase();
    var det=detectIntent(lower);
    if(det){
      if(det==='ticket'){addBubble('me',text,null,nowTs());showTicketCard(null);return}
      S.pendingIntent=det;S.phase='AWAIT_ID';
      addBubble('me',text,null,nowTs());showOrderIdPrompt(det);return;
    }

    addBubble('me',text,null,nowTs());
    sendAI(text);
  },

  _escalateNow:async function(){
    S.escalated=true;escBanner.style.border='2px solid #dc2626';
    try{
      var r=await post({action:'raiseTicket',issue:'Customer escalation — senior agent required',category:'Escalation'});
      var d=await r.json();
      if(d.success){
        addBubble('ai','Your case has been escalated — Ticket **#T'+d.ticketId+'** created. A senior support agent will call you within **30–60 minutes**. Thank you for your patience.',null,nowTs());
        toast_('Escalated — Ticket #T'+d.ticketId,'ok');
      }
    }catch(e){addBubble('ai','Your case has been logged for escalation. Our team will contact you shortly.',null,nowTs())}
  },

  /* ── CARD ACTIONS ── */

  _confirmCancel:async function(btn,oid){
    if(!confirm('Cancel order #'+oid+'? This cannot be undone.'))return;
    disBtn(btn);btn.textContent='Cancelling…';
    try{
      var r=await post({action:'cancelOrder',orderId:oid});var d=await r.json();
      if(!d.success){
        if(d.canIntercept){_handleIntercept(btn,oid);return}
        if(d.suggestReturn){_handleDeliveredCancel(btn,oid);return}
        throw new Error(d.error||'Cancellation failed');
      }
      var card=btn.closest('.kw-card');
      card.className='kw-card ok';
      var refundHtml='';
      if(d.isCOD){
        refundHtml='<div style="background:#fffbeb;border:1px solid #fde68a;border-radius:8px;padding:8px 10px;font-size:11.5px;color:#713f12;margin-top:8px">'
          +'💡 <strong>COD Order:</strong> No payment was collected — nothing to refund. Order voided.</div>';
      } else if(parseFloat(d.refundAmount)>0){
        var deductMsg=parseFloat(d.deductionPct)>0
          ?'A <strong>'+d.deductionPct+'% deduction</strong> applies (order was '+esc(d.stage||'in progress')+').'
          :'<strong>Full refund</strong> — order was not yet processed.';
        refundHtml='<div class="kw-refund-box">'
          +'<div class="kw-refund-row"><span style="color:#374151">Refund Amount</span><span style="color:#15803d;font-weight:700">₹'+d.refundAmount+'</span></div>'
          +'<div style="font-size:11px;color:#6b7280;margin-top:4px">'+deductMsg+'</div>'
          +'<div style="font-size:11px;color:#6b7280;margin-top:3px">Pending Staff Approval → Wallet/Source within <strong>3–5 business days</strong></div>'
          +'</div>';
      }
      card.innerHTML=okHtml('Order #'+oid+' Cancelled ✓','Your request is logged. Staff will process the refund.')
        +refundHtml;
      toast_('Order cancelled!','ok');
      S.phase='IDLE';S.currentOrder=null;
    }catch(e){enBtn(btn,'✕ Confirm Cancellation');toast_(e.message,'er')}
  },

  _requestIntercept:async function(btn,oid){
    if(!confirm('Request courier intercept for order #'+oid+'? A 10% charge may apply.'))return;
    disBtn(btn);btn.textContent='Requesting…';
    try{
      var r=await post({action:'interceptRequest',orderId:oid});var d=await r.json();
      if(!d.success)throw new Error(d.error||'Could not raise intercept');
      var card=btn.closest('.kw-card');card.className='kw-card ok';
      card.innerHTML=okHtml('Intercept Ticket #T'+d.ticketId+' Raised ✓',
        'Our team is contacting the courier. Update within 2 hours. If intercept fails, you can Return after delivery.');
      toast_('Intercept ticket raised!','ok');
    }catch(e){enBtn(btn,'🚚 Confirm Intercept');toast_(e.message,'er')}
  },

  _submitReturn:async function(btn,oid,isCOD){
    var c=btn.closest('.kw-card');
    var type=c.querySelector('[data-f="rt"]').value;
    var reason=c.querySelector('[data-f="rr"]').value.trim();
    if(!reason){toast_('Please describe the issue','er');return}
    var params={action:'submitReturn',orderId:oid,type:type,reason:reason};
    if(isCOD){
      var bn=c.querySelector('[data-f="bn"]'),ba=c.querySelector('[data-f="ba"]'),bi=c.querySelector('[data-f="bi"]');
      if(bn&&ba&&bi){
        if(!ba.value.trim()){toast_('Please enter bank account number','er');return}
        params.bankName=bn.value.trim();params.bankAccount=ba.value.trim();params.bankIfsc=bi.value.trim();
      }
    }
    disBtn(btn);btn.textContent='Submitting…';
    try{
      var r=await post(params);var d=await r.json();
      if(!d.success)throw new Error(d.message||d.error||'Submission failed');
      c.className='kw-card ok';
      c.innerHTML=okHtml((type==='Replace'?'Replacement':'Return')+' Submitted ✓',
        'Pickup within 48 hrs of approval. '+(type==='Replace'?'Replacement dispatched':'Refund processed')+' after item collected.');
      toast_('Request submitted!','ok');
      S.phase='IDLE';S.currentOrder=null;
    }catch(e){enBtn(btn,'↩ Submit');toast_(e.message,'er')}
  },

  _editAddr:function(btn){
    var c=btn.closest('.kw-card');
    c.querySelector('[data-show]').style.display='none';
    c.querySelector('[data-form]').style.display='block';
    btn.style.display='none';
  },
  _cancelAddr:function(btn){
    var c=btn.closest('.kw-card');
    c.querySelector('[data-show]').style.display='';
    c.querySelector('[data-form]').style.display='none';
    var eb=c.querySelector('[data-edit]');if(eb)eb.style.display='';
  },
  _saveAddr:async function(btn,oid){
    var c=btn.closest('.kw-card');
    var st=c.querySelector('[data-f="st"]').value.trim(),
        ci=c.querySelector('[data-f="ci"]').value.trim(),
        sl=c.querySelector('[data-f="sl"]').value.trim(),
        pi=c.querySelector('[data-f="pi"]').value.trim();
    // FIX: read district + country so servlet receives all expected fields
    var diEl=c.querySelector('[data-f="di"]'), coEl=c.querySelector('[data-f="co"]');
    var di=diEl?diEl.value.trim():'', co=coEl?coEl.value.trim():'';
    if(!st||!ci){toast_('Street and City are required','er');return}
    disBtn(btn);btn.textContent='Saving…';
    try{
      var r=await post({action:'updateAddress',orderId:oid,
                        street:st,city:ci,state:sl,pincode:pi,district:di,country:co});
      var d=await r.json();
      if(!d.success)throw new Error(d.error||'Update failed');

      // Update in-memory snap fields so detail card reflects change immediately
      if(S.currentOrder && String(S.currentOrder.id)===String(oid)){
        S.currentOrder.snapStreet  = st;
        S.currentOrder.snapCity    = ci;
        S.currentOrder.snapState   = sl;
        S.currentOrder.snapPincode = pi;
        S.currentOrder.address     = st+', '+ci+(sl?', '+sl:'')+(pi?' — '+pi:'');
        S.currentOrder.addressChangedAt = new Date().toISOString();
      }

      c.className='kw-card ok';
      if(d.urgent){
        c.innerHTML=okHtml('Urgent Ticket #T'+d.ticketId+' Raised',
          'Our team is contacting the delivery agent with the new address immediately. '          +'New address: '+esc(st)+', '+esc(ci)+(pi?' — '+esc(pi):''));
        toast_('Urgent address ticket raised!','ok');
      } else {
        c.innerHTML=okHtml('Address Updated for Order #'+oid+' ✓',
          esc(st)+', '+esc(ci)+(pi?' — '+esc(pi):'')+' • This applies only to this order.');
        toast_('Delivery address updated for this order!','ok');
      }
    }catch(e){enBtn(btn,'✓ Save Address');toast_(e.message,'er')}
  },

  _verifyPayment:async function(btn,oid){
    disBtn(btn);btn.textContent='Checking…';
    try{
      var r=await fetch('AIChatServlet?action=verifyPayment&orderId='+encodeURIComponent(oid));
      var d=await r.json();
      if(!d.success)throw new Error(d.error||'Could not verify');
      var card=btn.closest('.kw-card');
      card.innerHTML+='<div class="kw-div"></div>'
        +'<div class="kw-cr"><span class="kw-cl">Status</span><span class="kw-bk '+(d.isPaid?'g':'r')+'">'+(d.isPaid?'CONFIRMED':'FAILED')+'</span></div>'
        +'<div class="kw-cr"><span class="kw-cl">Method</span><span class="kw-cv">'+esc(d.paymentMethod)+'</span></div>'
        +(d.transactionId?'<div class="kw-cr"><span class="kw-cl">Txn ID</span><span class="kw-cv" style="font-size:10.5px;word-break:break-all">'+esc(d.transactionId)+'</span></div>':'')
        +(d.isCOD?'<div class="kw-cr"><span class="kw-cl">Note</span><span class="kw-cv">COD — no online txn</span></div>':'');
      btn.remove();
    }catch(e){enBtn(btn,'💳 Verify');toast_(e.message,'er')}
  },

  _raiseTicket:async function(btn,oid){
    var c=btn.closest('.kw-card');
    var issue=c.querySelector('[data-f="ti"]').value.trim();
    if(!issue){toast_('Please describe your issue','er');return}
    disBtn(btn);btn.textContent='Raising…';
    try{
      var params={action:'raiseTicket',issue:issue};
      if(oid&&oid!=='null')params.orderId=oid;
      var r=await post(params);var d=await r.json();
      if(!d.success)throw new Error(d.error||'Could not raise ticket');
      c.className='kw-card ok';
      c.innerHTML=okHtml('Ticket #T'+d.ticketId+' Raised ✓','Our team will call you within 2–4 business hours.');
      toast_('Ticket #T'+d.ticketId+' raised!','ok');
      S.phase='IDLE';S.currentOrder=null;
    }catch(e){enBtn(btn,'🎫 Raise Ticket');toast_(e.message,'er')}
  }
};

/* ══ INTERNAL HELPERS ═════════════════════════════════════════════════════ */
/* FIX: was missing — called when cancelOrder returns canIntercept:true */
function _handleIntercept(btn,oid){
  var card=btn.closest('.kw-card');card.className='kw-card ship';
  var sid=safe(oid);
  card.innerHTML='<div class="kw-ch"><span class="kw-ct" style="color:#c2410c">🚚 Shipment Intercept</span>'
    +'<span class="kw-bk or">In Transit</span></div>'
    +'<p style="color:#4b5563;font-size:12px;line-height:1.6;margin-bottom:10px">'
    +'Your order is already <strong>in transit</strong>. We can attempt a courier intercept. '
    +'A <strong>10% shipping charge</strong> will be deducted if successful. '
    +'If the courier cannot recall the package, you can <strong>Return</strong> it after delivery.</p>'
    +'<div class="kw-br"><button class="kw-btn or" onclick="KW._requestIntercept(this,\''+sid+'\')">🚚 Confirm Intercept Request</button>'
    +'<button class="kw-btn gh" onclick="KW.intent(\'ticket\')">🎫 Raise Ticket</button></div>';
}

function _handleDeliveredCancel(btn,oid){
  var card=btn.closest('.kw-card');card.className='kw-card ret';
  card.innerHTML='<div class="kw-ch"><span class="kw-ct" style="color:#b45309">↩ Order Already Delivered</span><span class="kw-bk a">Order #'+esc(oid)+'</span></div>'
    +'<p style="color:#4b5563;font-size:12px;line-height:1.6;margin-bottom:10px">'
    +'Your order has already been <strong>delivered</strong> — cancellation is no longer possible. '
    +'However, you can initiate a <strong>Return or Replace</strong> within the 10-day return window.</p>'
    +'<div class="kw-br">'
    +'<button class="kw-btn am" onclick="KW.doReturnFlow(\''+safe(oid)+'\',false)">↩ Initiate Return</button>'
    +'<button class="kw-btn gh" onclick="showTicketCard(\''+safe(oid)+'\')">🎫 Talk to Agent</button></div>';
}

function showLoginToast(){
  /* show a prominent toast with login link — guest trying to use a feature */
  var wrap=document.getElementById('kw-toast');
  wrap.innerHTML='🔒 Please <a href="CustomerLogin.jsp" style="color:#2563eb;font-weight:700;text-decoration:underline">log in</a> to use GreenCart Support.';
  wrap.className='wa';wrap.style.display='block';
  clearTimeout(window._kwLT);
  window._kwLT=setTimeout(function(){wrap.style.display='none';wrap.textContent='';wrap.className=''},5000);
}

KW.doReturnFlow=function(oid,isCOD){addBubble('ai','Here are the return options for order #'+oid+':',null,nowTs());appendToLast(buildReturnCard(oid,isCOD,null))};

/* ══ LOOKUP ORDER ═════════════════════════════════════════════════════════ */
async function lookupOrder(orderId,intent){
  showTyping(true);S.loading=true;if(snd)snd.disabled=true;
  try{
    var r=await fetch('AIChatServlet',{method:'POST',body:new URLSearchParams({action:'lookupOrder',orderId:orderId})});
    var d=await r.json();
    /* auth check */
    if(r.status===401||d.error==='NOT_LOGGED_IN'){
      showTyping(false);S.loading=false;if(snd)snd.disabled=false;
      showLoginToast();
      addBubble('ai','🔒 You need to **log in** to look up orders. [Log in here →](CustomerLogin.jsp)',null,nowTs());
      return;
    }
    showTyping(false);S.loading=false;if(snd)snd.disabled=false;
    if(!d.found){
      addBubble('ai','I couldn\'t find **Order #'+orderId+'** on your account. '
        +'Please check the Order ID — you can find it in **My Orders** or your confirmation email.\n\nWould you like to try another Order ID?',null,nowTs());
      S.phase='AWAIT_ID';return;
    }
    /* Merge top-level refund/snap fields into order object for card rendering */
d.order.refundPreview = d.refundPreview;
d.order.deductPct     = d.deductPct;
d.order.isCOD         = d.isCOD;
d.order.isPaid        = d.isPaid;
/* snap_* fields come from orderToJson — already in d.order */
S.currentOrder=d.order;S.phase='ORDER_LOADED';
    var row=addBubble('ai','I found your order! Here\'s the full summary 👇',null,nowTs());
    var wrap=row.querySelector('.kw-inner>div:last-child');
    var detCard=buildDetailCard(d.order,intent);
    var ts=wrap.querySelector('.kw-ts');
    ts?wrap.insertBefore(detCard,ts):wrap.appendChild(detCard);
    if(intent&&intent!=='track'){setTimeout(function(){dispatchIntent(intent,d.order)},400)}
    scrollBot();
  }catch(e){
    showTyping(false);S.loading=false;if(snd)snd.disabled=false;
    toast_(e.message||'Could not fetch order','er');
    addBubble('ai','⚠ Sorry, I had trouble fetching that order. Please try again.',null,nowTs());
    S.phase='AWAIT_ID';
  }
}

function dispatchIntent(intent,order){
  switch(intent){
    case 'cancel':  showCancelFlow(order);break;
    case 'return':  showReturnFlow(order);break;
    case 'address': showAddressCard(order);break;
    case 'invoice': showInvoiceCard(order);break;
    case 'payment': showPaymentCard(order);break;
    case 'ticket':  showTicketCard(order.id);break;
  }
}

KW.doAction=function(intent,oid){
  if(intent==='ticket'){showTicketCard(oid);return}
  var order=S.currentOrder;
  if(order&&String(order.id)===String(oid)){dispatchIntent(intent,order)}
  else{S.pendingIntent=intent;S.phase='AWAIT_ID';showOrderIdPrompt(intent)}
};

/* ══ ORDER ID PROMPT ══════════════════════════════════════════════════════ */
function showOrderIdPrompt(intent){
  var labels={track:'track',cancel:'cancel',return:'return',address:'update the address for',invoice:'download the invoice for',payment:'check the payment for'};
  addBubble('ai','Sure! Please provide the **Order ID** you\'d like to '+(labels[intent]||intent)+'.\n\nYou can find it in **My Orders** or your confirmation email.',null,nowTs());
  var el=document.createElement('div');el.style.cssText='display:flex;gap:7px;margin-top:9px';
  el.innerHTML='<input id="kw-oid" class="kw-fi" style="flex:1;margin:0" placeholder="e.g. 56 or ORD-56" onkeydown="if(event.key===\'Enter\'){KW._oiSubmit(this)}">'
    +'<button class="kw-btn pr" style="flex-shrink:0" onclick="KW._oiSubmit(this.previousElementSibling)">Go →</button>';
  appendToLast(el);
  setTimeout(function(){var oi=id('kw-oid');if(oi)oi.focus()},100);
}
KW._oiSubmit=function(input){
  var val=(input.value||'').trim();var m=val.match(/\b(\d{1,10})\b/);
  if(!m){toast_('Please enter a valid Order ID','er');return}
  input.disabled=true;var btn=input.nextElementSibling;if(btn)btn.disabled=true;
  addBubble('me','Order ID: '+m[1],null,nowTs());S.phase='IDLE';lookupOrder(parseInt(m[1]),S.pendingIntent);
};

/* ══ CANCEL FLOW — real-world tiered policy ══════════════════════════════ */
function showCancelFlow(order){
  var st=(order.status||'').toLowerCase();

  /* Delivered → can only return */
  if(st==='delivered'){
    addBubble('ai','**Order #'+order.id+'** has already been **delivered** — cancellation is no longer possible.\n\nHowever, I can start a **Return or Replace** — you have a 10-day return window.',null,nowTs());
    var card=document.createElement('div');card.className='kw-card ret';
    card.innerHTML='<div class="kw-ch"><span class="kw-ct" style="color:#b45309">↩ Return instead?</span><span class="kw-bk a">Order #'+esc(String(order.id))+'</span></div>'
      +'<p style="color:#4b5563;font-size:12px;margin-bottom:10px;line-height:1.5">Since delivered, your option is a <strong>Return &amp; Refund</strong> or <strong>Exchange</strong>.</p>'
      +'<div class="kw-br"><button class="kw-btn am" onclick="KW.doReturnFlow(\''+safe(String(order.id))+'\','+isCOD(order)+')">↩ Initiate Return</button>'
      +'<button class="kw-btn gh" onclick="showTicketCard(\''+safe(String(order.id))+'\')">🎫 Talk to Agent</button></div>';
    appendToLast(card);return;
  }

  /* Shipped / OFD → intercept flow with 10% warning */
  if(st==='shipped'||st==='out for delivery'){    var deductAmt=(order.totalAmount*0.10).toFixed(2);
    var refundAmt=(order.totalAmount*0.90).toFixed(2);
    addBubble('ai','**Order #'+order.id+'** is currently **'+order.status+'**.\n\n'
      +'⚠ A **10% shipping charge** (₹'+deductAmt+') will be deducted if the intercept succeeds. '
      +'Your refund would be **₹'+refundAmt+'**.\n\n'
      +'If the courier cannot stop delivery, you can **Return** the item after it arrives.',null,nowTs());
    var card2=document.createElement('div');card2.className='kw-card ship';var sid=safe(String(order.id));
    card2.innerHTML='<div class="kw-ch"><span class="kw-ct" style="color:#c2410c">🚚 Courier Intercept</span><span class="kw-bk or">'+esc(order.status)+'</span></div>'
      +'<div class="kw-refund-box">'
      +'<div class="kw-refund-row"><span style="color:#374151">Order Amount</span><span>₹'+parseFloat(order.totalAmount).toFixed(2)+'</span></div>'
      +'<div class="kw-refund-row"><span style="color:#c2410c">Shipping charge (10%)</span><span style="color:#c2410c">-₹'+deductAmt+'</span></div>'
      +'<div class="kw-refund-total"><span>Your Refund</span><span>₹'+refundAmt+'</span></div>'
      +'</div>'
      +'<div class="kw-deduct-note">🚚 A courier intercept will be attempted. If the package cannot be recalled, you can <strong>Return it after delivery</strong> within the 10-day window.</div>'
      +'<div class="kw-br"><button class="kw-btn or" onclick="KW._requestIntercept(this,\''+sid+'\')">🚚 Confirm Intercept Request</button>'
      +'<button class="kw-btn gh" onclick="KW.intent(\'ticket\')">🎫 Raise Ticket</button></div>';
    appendToLast(card2);return;
  }

  /* Assigned / Picked Up / Packed → 5% handling warning */
  if(st==='assigned'||st==='picked up'||st==='packed'){
    var d5=(order.totalAmount*0.05).toFixed(2);var r95=(order.totalAmount*0.95).toFixed(2);
    var stageLabel=st==='packed'?'packing charge':'handling fee';
    addBubble('ai','**Order #'+order.id+'** is **'+order.status+'**.\n\n'
      +'A **5% '+stageLabel+'** (₹'+d5+') will be deducted — your refund will be **₹'+r95+'**.',null,nowTs());
    var card3=document.createElement('div');card3.className='kw-card cancel';var sid2=safe(String(order.id));
    card3.innerHTML='<div class="kw-ch"><span class="kw-ct" style="color:#7c3aed">✕ Cancel — '+esc(order.status)+'</span><span class="kw-bk p">'+esc(order.paymentMethod||'')+'</span></div>'
      +(isCOD(order)?'<div style="background:#fefce8;border:1px solid #fef08a;color:#713f12;border-radius:9px;padding:8px 10px;font-size:11.5px;margin-bottom:10px">💡 <strong>COD Order:</strong> No amount was collected — nothing to refund. Order voided.</div>':'')
      +'<div class="kw-refund-box">'
      +(isCOD(order)?'<div class="kw-refund-row"><span>Order Amount</span><span>₹'+parseFloat(order.totalAmount).toFixed(2)+'</span></div><div style="font-size:11px;color:#6b7280">COD — nothing charged. No refund needed.</div>'
        :'<div class="kw-refund-row"><span>Order Amount</span><span>₹'+parseFloat(order.totalAmount).toFixed(2)+'</span></div>'
        +'<div class="kw-refund-row"><span style="color:#c2410c">'+stageLabel.charAt(0).toUpperCase()+stageLabel.slice(1)+' (5%)</span><span style="color:#c2410c">-₹'+d5+'</span></div>'
        +'<div class="kw-refund-total"><span>Your Refund</span><span>₹'+r95+'</span></div>')
      +'</div>'
      +'<div class="kw-br"><button class="kw-btn da" onclick="KW._confirmCancel(this,\''+sid2+'\')">✕ Confirm Cancel</button>'
      +'<button class="kw-btn gh" onclick="KW.send(\'I changed my mind, keep my order\')">Keep Order</button></div>';
    appendToLast(card3);return;
  }

  /* Pre-processing — full refund */
  var cod=isCOD(order);var sid3=safe(String(order.id));
  addBubble('ai','Good news — **Order #'+order.id+'** can be cancelled with a **full refund**!\n\nPlease confirm below:',null,nowTs());
  var card4=document.createElement('div');card4.className='kw-card cancel';
  card4.innerHTML='<div class="kw-ch"><span class="kw-ct" style="color:#7c3aed">✕ Cancel Order #'+esc(String(order.id))+'</span><span class="kw-bk p">'+esc(order.paymentMethod||'')+'</span></div>'
    +(cod?'<div style="background:#fefce8;border:1px solid #fef08a;color:#713f12;border-radius:9px;padding:8px 10px;font-size:11.5px;margin-bottom:10px">💡 <strong>COD Order:</strong> No payment collected — nothing to refund. Your order will be voided.</div>':'')
    +'<div class="kw-refund-box">'
    +(cod?'<div class="kw-refund-row"><span>Order Amount</span><span>₹'+parseFloat(order.totalAmount).toFixed(2)+'</span></div><div style="font-size:11px;color:#6b7280">COD — no online payment made. No refund processing needed.</div>'
      :'<div class="kw-refund-row"><span>Order Amount</span><span>₹'+parseFloat(order.totalAmount).toFixed(2)+'</span></div>'
      +'<div class="kw-refund-row"><span style="color:#059669">Deduction</span><span style="color:#059669">₹0.00</span></div>'
      +'<div class="kw-refund-total"><span>Full Refund</span><span>₹'+parseFloat(order.totalAmount).toFixed(2)+'</span></div>')
    +'</div>'
    +'<div class="kw-cr"><span class="kw-cl">Refund timeline</span><span class="kw-cv">3–5 business days</span></div>'
    +'<div class="kw-br"><button class="kw-btn da" onclick="KW._confirmCancel(this,\''+sid3+'\')">✕ Confirm Cancellation</button>'
    +'<button class="kw-btn gh" onclick="KW.send(\'I changed my mind, keep my order\')">Keep Order</button></div>';
  appendToLast(card4);
}

/* ══ RETURN FLOW ══════════════════════════════════════════════════════════ */
function showReturnFlow(order){
  if((order.status||'').toLowerCase()!=='delivered'){
    addBubble('ai','Returns are only available for **delivered** orders. Order #'+order.id+' is **'+order.status+'**.\n\nOnce delivered you\'ll have a 10-day return window.',null,nowTs());return;
  }
  var daysLeft=null;
  if(order.deliveryDate){var diff=Math.floor((Date.now()-new Date(order.deliveryDate).getTime())/86400000);daysLeft=10-diff}
  if(daysLeft!==null&&daysLeft<0){
    addBubble('ai','The **10-day return window** for Order #'+order.id+' has expired. If there are exceptional circumstances, raise a support ticket and our team will review personally.',null,nowTs());
    showTicketCard(order.id);return;
  }
  var cod=isCOD(order);
  addBubble('ai','Here are the return options for order #'+order.id+':',null,nowTs());
  appendToLast(buildReturnCard(String(order.id),cod,daysLeft));
}

function buildReturnCard(oid,cod,daysLeft){
  var sid=safe(oid);var c=document.createElement('div');c.className='kw-card ret';
  c.innerHTML='<div class="kw-ch"><span class="kw-ct" style="color:#b45309">↩ Return / Replace</span><span class="kw-bk a">Order #'+esc(oid)+'</span></div>'
    +'<div class="kw-ret-sum">'
    +(daysLeft!==null?'<div class="kw-cr"><span class="kw-cl">Return window</span><span class="kw-cv" style="color:'+(daysLeft<=3?'#dc2626':'#b45309')+'">'+daysLeft+' day'+(daysLeft!==1?'s':'')+' remaining</span></div>':'')
    +'<div class="kw-cr"><span class="kw-cl">Pickup</span><span class="kw-cv">Within 48 hours</span></div>'
    +'<div class="kw-cr"><span class="kw-cl">Refund</span><span class="kw-cv">'+(cod?'🏦 Bank Transfer (COD)':'Original payment method')+'</span></div>'
    +(cod?'<div class="kw-deduct-note">💡 <strong>COD Order:</strong> Refund via bank transfer — please have account details ready.</div>':'')
    +'</div>'
    +'<div class="kw-ret-form" style="display:none;margin-top:8px">'
    +'<select class="kw-sel" data-f="rt"><option value="Return">Return &amp; Refund</option><option value="Replace">Replace (Exchange)</option></select>'
    +'<textarea class="kw-ta" data-f="rr" placeholder="Describe the issue (damaged packaging, wrong item, expired product…)"></textarea>'
    +(cod?'<div style="font-size:11px;font-weight:700;color:#92400e;margin:5px 0 3px">🏦 Bank Details for Refund</div>'
         +'<input class="kw-fi" data-f="bn" placeholder="Bank Name"/>'
         +'<input class="kw-fi" data-f="ba" placeholder="Account Number" type="tel"/>'
         +'<input class="kw-fi" data-f="bi" placeholder="IFSC Code" style="text-transform:uppercase"/>':'')
    +'<div class="kw-br">'
    +'<button class="kw-btn am" onclick="KW._submitReturn(this,\''+sid+'\','+(cod?'true':'false')+')">↩ Submit</button>'
    +'<button class="kw-btn gh" onclick="this.closest(\'.kw-card\').querySelector(\'.kw-ret-sum\').style.display=\'\';this.closest(\'.kw-card\').querySelector(\'.kw-ret-form\').style.display=\'none\';">Cancel</button>'
    +'</div></div>'
    +'<div class="kw-br" style="margin-top:10px">'
    +'<button class="kw-btn su" style="flex:1;justify-content:center" onclick="this.closest(\'.kw-card\').querySelector(\'.kw-ret-sum\').style.display=\'none\';this.closest(\'.kw-card\').querySelector(\'.kw-ret-form\').style.display=\'block\';this.closest(\'.kw-br\').style.display=\'none\'">↩ Initiate Return / Replace</button>'
    +'</div>';
  return c;
}

/* ══ ADDRESS CARD ══════════════════════════════════════════════════════════ */
function showAddressCard(order){
  var st=(order.status||'').toLowerCase();
  var sid=safe(String(order.id));

  /* Build snap address parts — frozen at placement, updated only by per-order change */
  var snapLine1 = order.snapStreet  || '';
  var snapLine2parts = [order.snapCity, order.snapState, order.snapPincode].filter(Boolean);
  var snapLine2 = snapLine2parts.join(', ');
  var snapFull  = [snapLine1, snapLine2].filter(Boolean).join(', ');
  if (!snapFull && order.address) snapFull = order.address;
  var wasChanged = order.addressChangedAt ? true : false;

  if(st==='shipped'||st==='assigned'||st==='out for delivery'){
    addBubble('ai','**Order #'+order.id+'** is already **'+order.status+'**.\n\n'
      +'Current frozen address: **'+(snapFull||'Not recorded')+'**\n\n'
      +'I can send a correction to the delivery agent — enter the new address below.',null,nowTs());
    var card=document.createElement('div');card.className='kw-card addr';
    card.innerHTML='<div class="kw-ch"><span class="kw-ct" style="color:#c2410c">📍 Urgent Address Correction</span><span class="kw-bk or">'+esc(order.status)+'</span></div>'
      +'<div style="background:#fff7ed;border:1px solid #fed7aa;border-radius:8px;padding:8px 10px;font-size:11.5px;color:#9a3412;margin-bottom:10px">'
      +'⚠ Order is in transit. An urgent correction ticket will be raised for the delivery agent.'
      +(snapFull ? '<br>Current address on record: <strong>'+esc(snapFull)+'</strong>' : '')+'</div>'
      +'<div style="font-size:11px;color:#6b7280;margin-bottom:6px">New address (applies only to Order #'+esc(String(order.id))+'):</div>'
      +'<input class="kw-fi" data-f="st" placeholder="Street / Landmark"'+(snapLine1?' value="'+esc(snapLine1)+'"':'')+'/>'
      +'<input class="kw-fi" data-f="ci" placeholder="City"'+(order.snapCity?' value="'+esc(order.snapCity)+'"':'')+'/>'
      +'<input class="kw-fi" data-f="sl" placeholder="State"'+(order.snapState?' value="'+esc(order.snapState)+'"':'')+'/>'
      +'<input class="kw-fi" data-f="pi" placeholder="Pincode"'+(order.snapPincode?' value="'+esc(order.snapPincode)+'"':'')+'/>'
      +'<input class="kw-fi" data-f="di" placeholder="District (optional)"/>'
      +'<input class="kw-fi" data-f="co" placeholder="Country (optional, default India)"/>'
      +'<div class="kw-br"><button class="kw-btn or" style="flex:1;justify-content:center" onclick="KW._saveAddr(this,\''+sid+'\')">📍 Send Correction to Agent</button></div>';
    appendToLast(card);return;
  }

  addBubble('ai','**Order #'+order.id+'** hasn\'t shipped yet — I can update the delivery address.\n\n'
    +'Current address: **'+(snapFull||'Not set')+'**',null,nowTs());
  var card2=document.createElement('div');card2.className='kw-card addr';
  card2.innerHTML='<div class="kw-ch"><span class="kw-ct" style="color:#059669">📍 Delivery Address</span>'
    +'<button class="kw-btn gh" style="padding:4px 10px;font-size:11px" data-edit onclick="KW._editAddr(this)">✏ Edit</button></div>'
    /* Frozen snap address preview */
    +'<div data-show>'
    +(snapFull
      ? '<div style="background:#f0fdf4;border:1.5px solid #86efac;border-radius:10px;padding:10px 12px;margin-bottom:8px">'
        +'<div style="font-size:10.5px;font-weight:700;color:#6b7280;text-transform:uppercase;letter-spacing:.4px;margin-bottom:4px">'
        +(wasChanged ? '✏ Updated (order-specific)' : '📍 Frozen delivery address')+'</div>'
        +'<div style="font-weight:700;font-size:13px;color:#1e293b">'+esc(snapLine1)+'</div>'
        +(snapLine2 ? '<div style="font-size:12px;color:#64748b;margin-top:2px">'+esc(snapLine2)+'</div>' : '')
        +(wasChanged ? '<div style="font-size:10.5px;color:#b45309;margin-top:5px;padding-top:5px;border-top:1px solid #fde68a">⚠ This address was changed after order placement and applies to this order only.</div>' : '<div style="font-size:10.5px;color:#16a34a;margin-top:5px">✓ Set at order placement — frozen to this order.</div>')
        +'</div>'
      : '<div style="background:#fff5f5;border:1px solid #fecaca;border-radius:9px;padding:9px 12px;margin-bottom:8px;font-size:12px;color:#dc2626">No address recorded. Please add one below.</div>'
    )
    +'</div>'
    +'<div data-form style="display:none;margin-top:6px">'
    +'<div style="background:#fffbeb;border:1px solid #fde68a;border-radius:8px;padding:7px 10px;font-size:11px;color:#92400e;margin-bottom:8px">'
    +'📍 This address update applies <strong>only to Order #'+esc(String(order.id))+'</strong> — your profile default address will not change.'
    +'</div>'
    +'<input class="kw-fi" data-f="st" placeholder="Street / Landmark"'+(snapLine1?' value="'+esc(snapLine1)+'"':'')+'/>'
    +'<input class="kw-fi" data-f="ci" placeholder="City"'+(order.snapCity?' value="'+esc(order.snapCity)+'"':'')+'/>'
    +'<input class="kw-fi" data-f="sl" placeholder="State"'+(order.snapState?' value="'+esc(order.snapState)+'"':'')+'/>'
    +'<input class="kw-fi" data-f="pi" placeholder="Pincode"'+(order.snapPincode?' value="'+esc(order.snapPincode)+'"':'')+'/>'
    +'<input class="kw-fi" data-f="di" placeholder="District (optional)"/>'
    +'<input class="kw-fi" data-f="co" placeholder="Country (optional, default India)"/>'
    +'<div class="kw-br"><button class="kw-btn su" onclick="KW._saveAddr(this,\''+sid+'\')">✓ Save Address</button>'
    +'<button class="kw-btn gh" onclick="KW._cancelAddr(this)">Cancel</button></div></div>';
  appendToLast(card2);
}

/* ══ PAYMENT CARD ══════════════════════════════════════════════════════════ */
function showPaymentCard(order){
  var sid=safe(String(order.id));
  addBubble('ai','Let me check the payment for Order #'+order.id+':',null,nowTs());
  var c=document.createElement('div');c.className='kw-card pay';
  c.innerHTML='<div class="kw-ch"><span class="kw-ct" style="color:#dc2626">💳 Payment Details</span><span class="kw-bk r">Order #'+esc(String(order.id))+'</span></div>'
    +'<div class="kw-cr"><span class="kw-cl">Status</span><span class="kw-bk '+payBadge(order.paymentStatus).c+'">'+esc(payBadge(order.paymentStatus).l)+'</span></div>'
    +'<div class="kw-cr"><span class="kw-cl">Method</span><span class="kw-cv">'+esc(order.paymentMethod||'N/A')+'</span></div>'
    +'<div class="kw-div"></div>'
    +'<div class="kw-br">'
    +'<button class="kw-btn pr" onclick="KW._verifyPayment(this,\''+sid+'\')">💳 Verify Payment</button>'
    +(order.paymentMethod&&order.paymentMethod.toUpperCase()!=='COD'?'<button class="kw-btn gh" onclick="KW.send(\'retry payment for order '+sid+'\')">↻ Retry</button>':'')
    +'<button class="kw-btn gh" onclick="KW.intent(\'ticket\')">🎫 Raise Ticket</button></div>';
  appendToLast(c);
}

/* ══ INVOICE CARD ══════════════════════════════════════════════════════════ */
function showInvoiceCard(order){
  var num=String(order.id).replace(/[^0-9]/g,'');
  addBubble('ai','Your invoice for Order #'+order.id+' is ready:',null,nowTs());
  var c=document.createElement('div');c.className='kw-card inv';
  c.innerHTML='<div class="kw-ch"><span class="kw-ct" style="color:#1d4ed8">🧾 Invoice Ready</span><span class="kw-bk '+payBadge(order.paymentStatus).c+'">'+esc(payBadge(order.paymentStatus).l)+'</span></div>'
    +'<div class="kw-cr"><span class="kw-cl">Order</span><span class="kw-cv">#'+esc(String(order.id))+'</span></div>'
    +'<div class="kw-cr"><span class="kw-cl">Amount</span><span class="kw-cv">₹'+parseFloat(order.totalAmount||0).toFixed(2)+'</span></div>'
    +'<div class="kw-div"></div>'
    +'<button class="kw-btn pr" style="width:100%;justify-content:center" onclick="window.open(\'InvoiceServlet?orderId='+num+'\',\'_blank\')">⬇ Download PDF Invoice</button>';
  appendToLast(c);
}

/* ══ TICKET CARD ═══════════════════════════════════════════════════════════ */
function showTicketCard(oid){
  addBubble('ai','I\'ll raise a support ticket — our team will call you back within **2–4 business hours**.',null,nowTs());
  var c=document.createElement('div');c.className='kw-card ticket';
  var sidStr=oid?'\''+safe(String(oid))+'\'':'null';
  c.innerHTML='<div class="kw-ch"><span class="kw-ct" style="color:#4338ca">🎫 Support Ticket</span><span class="kw-bk i">Support</span></div>'
    +'<textarea class="kw-ta" data-f="ti" placeholder="Describe your issue (e.g. order delayed, wrong item, refund not received…)"></textarea>'
    +'<div class="kw-br"><button class="kw-btn in" onclick="KW._raiseTicket(this,'+sidStr+')">🎫 Raise Ticket</button>'
    +'<button class="kw-btn gh" onclick="KW.send(\'hi\')">Cancel</button></div>';
  appendToLast(c);
}

/* ══ SNAP ADDRESS DISPLAY HELPER ═══════════════════════════════════════════ */
function snapAddrDisplay(order){
  var line1=order.snapStreet||'';
  var line2=[order.snapCity,order.snapState,order.snapPincode].filter(Boolean).join(', ');
  var full=order.address||([line1,line2].filter(Boolean).join(', '));
  if(!full)return '';
  var changed=order.addressChangedAt?true:false;
  return '<div style="margin:4px 0">'
    +'<div class="kw-cr">'
    +'<span class="kw-cl">Delivery To</span>'
    +'<span style="font-size:11px;text-align:right;max-width:58%;font-weight:600;color:#1e293b">'
    +esc(full)
    +(changed?'<br><span style="font-size:9.5px;color:#b45309;font-weight:500">✏ Updated (order-specific)</span>':'<br><span style="font-size:9.5px;color:#16a34a;font-weight:500">✓ Frozen at placement</span>')
    +'</span></div></div>';
}

/* ══ ORDER DETAIL CARD ═════════════════════════════════════════════════════ */
function buildDetailCard(order,intent){
  var c=document.createElement('div');c.className='kw-card order';
  var statusBadge=orderBadge(order.status),payB=payBadge(order.paymentStatus);
  var steps=['Ordered','Packed','Shipped','OFD','Delivered'];
  var si=trackIdx(order.status);
  var trackHtml='<div class="kw-track">'+steps.map(function(s,i){
    var dc=i<si?'dn':i===si?'ac':'';
    var lc=i<si?'dn':'';
    return '<div class="kw-step"><div class="kw-dot '+dc+'"></div><div class="kw-lbl">'+s+'</div></div>'
      +(i<steps.length-1?'<div class="kw-line '+lc+'"></div>':'');
  }).join('')+'</div>';

  var itemsHtml='';
  if(order.items&&order.items.length){
    itemsHtml='<div class="kw-items">'+order.items.slice(0,3).map(function(it){
      return '<div class="kw-item"><img class="kw-iimg" src="'+esc(it.imageUrl||'')+'" alt="" onerror="this.style.display=\'none\'"/>'
        +'<span class="kw-iname">'+esc(it.name)+'</span>'
        +'<span class="kw-iqty">×'+it.quantity+' ₹'+parseFloat(it.finalPrice||0).toFixed(2)+'</span></div>';
    }).join('')+(order.items.length>3?'<div style="font-size:10.5px;color:#6b7280;padding:4px 8px">+'+( order.items.length-3)+' more items</div>':'')+'</div>';
  }

  var actions=getActions(order);
  var achips='<div class="kw-achips">'+actions.map(function(a){
    return '<button class="kw-achip '+a.c+'" onclick="KW.doAction(\''+a.k+'\',\''+safe(String(order.id))+'\')">'+a.label+'</button>';
  }).join('')+'<button class="kw-achip gy" onclick="KW.intent(\'track\')">🔍 Other Order</button></div>';

  c.innerHTML='<div class="kw-ch"><span class="kw-ct" style="color:#1d4ed8">📋 Order #'+esc(String(order.id))+'</span>'
    +'<span class="kw-bk '+statusBadge.c+'">'+esc(statusBadge.l)+'</span></div>'
    +trackHtml
    +'<div class="kw-div"></div>'
    +'<div class="kw-cr"><span class="kw-cl">Order Date</span><span class="kw-cv">'+fmtD(order.orderDate)+'</span></div>'
    +'<div class="kw-cr"><span class="kw-cl">Est. Delivery</span><span class="kw-cv" style="color:#059669">'+fmtD(order.deliveryDate)+'</span></div>'
    +'<div class="kw-cr"><span class="kw-cl">Total</span><span class="kw-cv">₹'+parseFloat(order.totalAmount||0).toFixed(2)+'</span></div>'
    +'<div class="kw-cr"><span class="kw-cl">Payment</span><span class="kw-cv">'+esc(order.paymentMethod||'')
    +' &nbsp;<span class="kw-bk '+payB.c+'" style="font-size:9px">'+payB.l+'</span></span></div>'
    /* Snap address row — reads frozen snap_* columns, never live default */
+(snapAddrDisplay(order))
    +itemsHtml
    +'<div class="kw-div"></div>'
    +'<div style="font-size:11px;color:#6b7280;margin-bottom:6px;font-weight:600">What would you like to do?</div>'
    +achips;
  return c;
}

/* ══ AI FALLBACK ══════════════════════════════════════════════════════════ */
function sendAI(text){
  showTyping(true);S.loading=true;if(snd)snd.disabled=true;
  fetch('AIChatServlet',{method:'POST',body:new URLSearchParams({action:'message',message:text})})
    .then(function(r){
      if(r.status===401)return r.json().then(function(d){throw new Error('NOT_LOGGED_IN')});
      return r.ok?r.json():r.json().then(function(e){throw new Error(e.error||'Error '+r.status)});
    })
    .then(function(d){
      if(d.sessionToken&&!S.token)S.token=d.sessionToken;
      showTyping(false);addBubble('ai',d.text,null,nowTs());
      if(!S.open){S.unread++;badge.textContent=S.unread;badge.style.display='flex'}
    })
    .catch(function(e){
      showTyping(false);
      if(e.message==='NOT_LOGGED_IN'){showLoginToast();addBubble('ai','🔒 Please **log in** to use GreenCart Support. [Log in →](CustomerLogin.jsp)',null,nowTs());return}
      toast_(e.message||'Could not reach server','er');addBubble('ai','Sorry, I had a hiccup. Please try again.',null,nowTs());
    })
    .finally(function(){S.loading=false;if(snd)snd.disabled=false;if(inp)inp.focus()});
}

/* ══ BOOT / HISTORY ═══════════════════════════════════════════════════════ */
function boot(){
  if(IS_GUEST){showWelcome();return}  // show static welcome to guests
  // FIX: bare GET returns 400 — must pass action=history
  fetch('AIChatServlet?action=history')
    .then(function(r){
      if(r.status===401)return null;
      return r.ok?r.json():null;
    })
    .then(function(d){
      if(!d)return showWelcome();
      if(d.sessionToken)S.token=d.sessionToken;
      if(!d.messages||!d.messages.length)return showWelcome();
      d.messages.forEach(function(m){addBubble(m.role==='user'?'me':'ai',m.content,null,m.sentAt)});
      scrollBot();
    }).catch(showWelcome);
}

function showWelcome(){
  var w=document.createElement('div');w.className='kw-empty';
  w.innerHTML='<div class="kw-eico"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="26" height="26" stroke="#2563eb" fill="none" stroke-width="1.8"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg></div>'
    +'<h4>Hi! I\'m Kira 👋</h4>'
    +'<p>Your GreenCart support assistant. Ask me about orders, cancellations, returns, payments or anything else!</p>';
  feed.appendChild(w);
  setTimeout(function(){
    addBubble('ai','Hey <%= _custName %>! 👋 Welcome to **GreenCart Support**.\n\n'
      +'I can help you:\n'
      +'• **📦 Track** your orders in real time\n'
      +'• **✕ Cancel** an order — with transparent refund breakdown\n'
      +'• **↩ Return or Replace** a delivered item (10-day window)\n'
      +'• **📍 Change delivery address** before dispatch\n'
      +'• **💳 Payment issues** & invoice downloads\n'
      +'• **🎫 Raise a support ticket** — our team calls you back in 2–4 hrs\n\n'
      +'Just tap a button below or type your **Order ID** to get started!',null,nowTs());
  },400);
}

/* ══ BUBBLE / UI HELPERS ══════════════════════════════════════════════════ */
function addBubble(role,text,_ct,ts){
  var empty=feed.querySelector('.kw-empty');if(empty)empty.remove();
  var row=document.createElement('div');row.className='kw-row '+role;
  var inner=document.createElement('div');inner.className='kw-inner';
  if(role==='ai'){var av=document.createElement('div');av.className='kw-mav';av.innerHTML='<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="13" height="13" stroke="#fff" fill="none" stroke-width="2"><rect x="3" y="11" width="18" height="10" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>';inner.appendChild(av)}
  var wrap=document.createElement('div');wrap.style.maxWidth='90%';
  var bub=document.createElement('div');bub.className='kw-bub '+role;bub.innerHTML=fmt(text);wrap.appendChild(bub);
  if(ts){var te=document.createElement('div');te.className='kw-ts';te.textContent=fmtTs(ts);wrap.appendChild(te)}
  inner.appendChild(wrap);row.appendChild(inner);feed.appendChild(row);scrollBot();return row;
}

function appendToLast(el){
  var rows=feed.querySelectorAll('.kw-row.ai');var last=rows[rows.length-1];if(!last)return;
  var wrap=last.querySelector('.kw-inner>div:last-child');
  if(wrap){var ts=wrap.querySelector('.kw-ts');ts?wrap.insertBefore(el,ts):wrap.appendChild(el)}
  scrollBot();
}

function showTyping(on){
  if(on){
    if(typing)return;
    typing=document.createElement('div');
    typing.style.cssText='display:flex;align-items:flex-end;gap:8px;animation:kwFd .2s ease';
    typing.innerHTML='<div class="kw-mav"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="13" height="13" stroke="#fff" fill="none" stroke-width="2"><rect x="3" y="11" width="18" height="10" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg></div>'
      +'<div class="kw-tb"><span class="kw-td"></span><span class="kw-td"></span><span class="kw-td"></span></div>';
    feed.appendChild(typing);scrollBot();
  }else{if(typing){typing.remove();typing=null}}
}

function detectIntent(m){
  if(/\b(cancel|cancell)\b/.test(m))return 'cancel';
  if(/\b(track|where is my|order status|when will|eta)\b/.test(m))return 'track';
  if(/\b(return|exchange|replace|damaged|wrong item|defective)\b/.test(m))return 'return';
  if(/\b(address|change address|wrong address)\b/.test(m))return 'address';
  if(/\b(invoice|receipt|bill|pdf)\b/.test(m))return 'invoice';
  if(/\b(payment|paid|charged|transaction)\b/.test(m))return 'payment';
  if(/\b(ticket|agent|human|manager|supervisor|escalate)\b/.test(m))return 'ticket';
  return null;
}

/* helpers */
function post(params){return fetch('AIChatServlet',{method:'POST',body:new URLSearchParams(params)})}
function logAct(at,oid,pl){if(!S.token)return;var p={action:'action',actionType:at,sessionToken:S.token};if(oid)p.orderId=oid;if(pl)p.payload=pl;fetch('AIChatServlet',{method:'POST',body:new URLSearchParams(p)}).catch(function(){})}
function disBtn(btn){btn.closest('.kw-card').querySelectorAll('.kw-btn').forEach(function(b){b.disabled=true})}
function enBtn(btn,lbl){btn.closest('.kw-card').querySelectorAll('.kw-btn').forEach(function(b){b.disabled=false});btn.textContent=lbl}
function isCOD(order){return (order.paymentMethod||'').toUpperCase()==='COD'}
function okHtml(t,s){return '<div style="display:flex;align-items:center;gap:11px;padding:3px 0">'
  +'<div style="width:36px;height:36px;border-radius:50%;background:#dcfce7;border:1px solid #86efac;display:flex;align-items:center;justify-content:center;flex-shrink:0">'
  +'<svg width="18" height="18" viewBox="0 0 24 24" stroke="#16a34a" fill="none" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg></div>'
  +'<div><div style="color:#15803d;font-weight:700;font-size:13px">'+esc(t)+'</div>'
  +'<div style="color:#16a34a;font-size:11.5px;margin-top:3px">'+esc(s)+'</div></div></div>'}
function fmt(t){if(!t)return '';return t.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/\*\*(.*?)\*\*/g,'<strong>$1</strong>').replace(/\[([^\]]+)\]\(([^)]+)\)/g,'<a href="$2" style="color:#2563eb;font-weight:600">$1</a>').replace(/\n/g,'<br>')}
function esc(s){return(s||'').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;')}
function safe(s){return(s||'').replace(/['\"<>&\s]/g,'')}
function nowTs(){return new Date().toISOString()}
function fmtD(ts){try{var d=new Date(ts);if(isNaN(d))return ts||'—';return d.toLocaleDateString('en-IN',{day:'numeric',month:'short',year:'numeric'})}catch(e){return ts||'—'}}
function fmtTs(ts){try{var d=new Date(ts);if(isNaN(d))return '';var df=Date.now()-d;if(df<60000)return 'Just now';if(df<3600000)return Math.floor(df/60000)+'m ago';return d.toLocaleTimeString([],{hour:'2-digit',minute:'2-digit'})}catch(e){return ''}}
function scrollBot(){requestAnimationFrame(function(){feed.scrollTop=feed.scrollHeight})}
var toastT;
function toast_(msg,cls){toast.innerHTML=msg;toast.className=cls;toast.style.display='block';clearTimeout(toastT);toastT=setTimeout(function(){toast.style.display='none'},4500)}
function orderBadge(s){var m={'delivered':{c:'g',l:'Delivered'},'shipped':{c:'b',l:'Shipped'},'assigned':{c:'b',l:'Assigned'},'out for delivery':{c:'b',l:'Out for Delivery'},'cancelled':{c:'r',l:'Cancelled'},'return requested':{c:'a',l:'Return Requested'},'refunded':{c:'g',l:'Refunded'},'replaced':{c:'g',l:'Replaced'},'confirmed':{c:'i',l:'Confirmed'},'processing':{c:'i',l:'Processing'},'pending':{c:'gy',l:'Pending'},'ordered':{c:'gy',l:'Ordered'},'picked up':{c:'p',l:'Picked Up'},'packed':{c:'b',l:'Packed'}};return m[(s||'').toLowerCase()]||{c:'gy',l:s||'—'}}
function payBadge(s){var m={'paid':{c:'g',l:'PAID'},'success':{c:'g',l:'PAID'},'completed':{c:'g',l:'PAID'},'pending_cod':{c:'a',l:'COD'},'cod_cancelled':{c:'r',l:'COD CANCELLED'},'payment_failed':{c:'r',l:'FAILED'},'failed':{c:'r',l:'FAILED'},'refunded':{c:'g',l:'REFUNDED'},'refund_pending':{c:'a',l:'REFUND PENDING'}};return m[(s||'').toLowerCase()]||{c:'gy',l:s||'—'}}
function trackIdx(s){var m={'ordered':0,'pending':0,'confirmed':0,'processing':0,'packed':1,'shipped':2,'assigned':2,'out for delivery':3,'delivered':4,'cancelled':4,'refunded':4,'replaced':4};return m[(s||'').toLowerCase()]??0}
function getActions(order){
  var st=(order.status||'').toLowerCase(),ps=(order.paymentStatus||'').toLowerCase(),acts=[];
  acts.push({k:'track',label:'📦 Track',c:'b'});
  if(['ordered','pending','confirmed'].includes(st))acts.push({k:'cancel',label:'✕ Cancel (Full Refund)',c:'r'});
  else if(['assigned','picked up','packed'].includes(st))acts.push({k:'cancel',label:'✕ Cancel (5% fee)',c:'r'});
  else if(['shipped','out for delivery'].includes(st))acts.push({k:'cancel',label:'🚚 Intercept (10% fee)',c:'or'});
  if(['ordered','pending','confirmed'].includes(st))acts.push({k:'address',label:'📍 Change Address',c:'g'});
  else if(['shipped','assigned','out for delivery'].includes(st))acts.push({k:'address',label:'📍 Urgent Address',c:'or'});
  if(st==='delivered')acts.push({k:'return',label:'↩ Return / Replace',c:'a'});
  if(['payment_failed','failed'].includes(ps))acts.push({k:'payment',label:'💳 Fix Payment',c:'r'});
  if(['paid','success','completed','pending_cod'].includes(ps)||st==='delivered')acts.push({k:'invoice',label:'🧾 Invoice',c:'b'});
  acts.push({k:'ticket',label:'🎫 Ticket',c:'i'});
  return acts;
}

/* auto banner */
setTimeout(function(){if(!S.open)id('kw-banner').style.display='flex'},3000);

})();
</script>
