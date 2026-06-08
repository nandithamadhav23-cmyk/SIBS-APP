<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true"%>
<%
    String _role  = (session != null) ? (String) session.getAttribute("role")     : null;
    String _uname = (session != null) ? (String) session.getAttribute("username") : null;
    if (_role == null || !"admin".equalsIgnoreCase(_role)) {
        out.print("<p style='color:#e74c3c;font-family:Times New Roman;padding:2rem;'>"
                + "<i class='bi bi-lock me-2'></i>Access denied.</p>");
        return;
    }
%>
<%-- ═══════════════════════════════════════════════════════════════════════════
     staffDashboard.jsp  (updated — includes full Leave Management panel)
     Loaded as an AJAX fragment into dashboard.jsp#mainContent — NO <html>/<body>.
     Inherits CSS vars: --primary #0ea5e9, --primary-dark #0369a1,
     --text-dark, --text-mid, --text-muted, --border, --bg-white, --bg-off,
     --shadow-sm, --shadow-md, --radius  from dashboard.jsp :root.
     Fonts: Nunito (loaded by parent).
═══════════════════════════════════════════════════════════════════════════ --%>

<style>
/* ─────────────────────────────────────────────────────────────────────
   SECTION 1 — ORIGINAL STAFF CARDS  (unchanged)
───────────────────────────────────────────────────────────────────── */
.sd-header{display:flex;align-items:flex-start;justify-content:space-between;flex-wrap:wrap;gap:1rem;margin-bottom:2rem;padding-bottom:1.2rem;border-bottom:2px solid var(--border)}
.sd-title{font-family:'Nunito',sans-serif;font-size:1.5rem;font-weight:800;color:var(--text-dark);margin:0 0 .25rem;display:flex;align-items:center;gap:.55rem}
.sd-title i{color:var(--primary)}
.sd-subtitle{font-family:'Nunito',sans-serif;font-size:.83rem;color:var(--text-muted);letter-spacing:.4px}
.sd-grid{display:grid;grid-template-columns:repeat(4,1fr);gap:1.4rem}
.sd-card{background:var(--bg-white);border:1px solid var(--border);border-radius:6px;padding:2rem 1.4rem 1.6rem;text-align:center;position:relative;overflow:hidden;transition:transform .25s,box-shadow .25s;display:flex;flex-direction:column;align-items:center}
.sd-card::before{content:'';position:absolute;top:0;left:0;right:0;height:4px;transform:scaleX(0);transform-origin:left;transition:transform .3s}
.sd-card:hover{transform:translateY(-6px);box-shadow:0 8px 28px rgba(26,26,46,.13)}
.sd-card:hover::before{transform:scaleX(1)}
.sd-card.c-green::before{background:#27ae60}.sd-card.c-blue::before{background:#2980b9}
.sd-card.c-amber::before{background:#e67e22}.sd-card.c-teal::before{background:#16a085}
.sd-card.c-sky::before{background:var(--primary)}
.sd-icon{width:68px;height:68px;border-radius:50%;display:flex;align-items:center;justify-content:center;margin:0 auto 1.3rem;font-size:1.7rem;flex-shrink:0;transition:transform .2s}
.sd-card:hover .sd-icon{transform:scale(1.08)}
.sd-icon.g{background:#e8f8f0;color:#27ae60}.sd-icon.b{background:#e8f0fb;color:#2980b9}
.sd-icon.a{background:#fdf3e3;color:#e67e22}.sd-icon.t{background:#e8f8f8;color:#16a085}
.sd-icon.s{background:#e0f2fe;color:var(--primary)}
.sd-card-title{font-family:'Nunito',sans-serif;font-size:1.05rem;font-weight:700;color:var(--text-dark);margin-bottom:.55rem}
.sd-card-desc{font-family:'Nunito',sans-serif;font-size:.86rem;color:var(--text-muted);line-height:1.65;margin-bottom:1.4rem;flex-grow:1}
.sd-btn{font-family:'Nunito',sans-serif;font-size:.77rem;letter-spacing:1.1px;text-transform:uppercase;padding:.52rem 1.4rem;border-radius:3px;text-decoration:none;display:inline-flex;align-items:center;gap:.4rem;transition:background .2s,color .2s,transform .15s;border:2px solid transparent;cursor:pointer;white-space:nowrap;position:relative}
.sd-btn:hover{transform:translateY(-1px)}.sd-btn:active{transform:none}
.sd-btn.g{background:#27ae60;color:#fff;border-color:#27ae60}.sd-btn.g:hover{background:transparent;color:#27ae60}
.sd-btn.b{background:#2980b9;color:#fff;border-color:#2980b9}.sd-btn.b:hover{background:transparent;color:#2980b9}
.sd-btn.a{background:#e67e22;color:#fff;border-color:#e67e22}.sd-btn.a:hover{background:transparent;color:#e67e22}
.sd-btn.t{background:#16a085;color:#fff;border-color:#16a085}.sd-btn.t:hover{background:transparent;color:#16a085}
.sd-btn.s{background:var(--primary);color:#fff;border-color:var(--primary)}.sd-btn.s:hover{background:var(--primary-dark);border-color:var(--primary-dark)}

/* Tooltip */
.sd-btn[data-tip]{position:relative}
.sd-btn[data-tip]::after{content:attr(data-tip);position:absolute;bottom:calc(100% + 8px);left:50%;transform:translateX(-50%) scale(.9);background:var(--primary);color:#fff;font-family:'Nunito',sans-serif;font-size:.72rem;letter-spacing:.4px;white-space:nowrap;padding:.35rem .7rem;border-radius:3px;pointer-events:none;opacity:0;transition:opacity .18s,transform .18s;z-index:99;text-transform:none}
.sd-btn[data-tip]::before{content:'';position:absolute;bottom:calc(100% + 2px);left:50%;transform:translateX(-50%) scale(.9);border:5px solid transparent;border-top-color:var(--primary);pointer-events:none;opacity:0;transition:opacity .18s,transform .18s;z-index:99}
.sd-btn[data-tip]:hover::after,.sd-btn[data-tip]:hover::before{opacity:1;transform:translateX(-50%) scale(1)}

/* Modal */
.sd-modal-backdrop{position:fixed;inset:0;background:rgba(10,10,24,.55);z-index:1060;display:none;align-items:center;justify-content:center;padding:1rem;backdrop-filter:blur(2px)}
.sd-modal-backdrop.open{display:flex}
.sd-modal{background:var(--bg-white);border-radius:6px;box-shadow:0 16px 56px rgba(26,26,46,.22);width:100%;max-width:640px;max-height:90vh;overflow-y:auto;animation:sdModalIn .22s ease}
@keyframes sdModalIn{from{opacity:0;transform:translateY(-18px) scale(.97)}to{opacity:1;transform:none}}
.sd-modal-head{background:var(--primary);padding:1.15rem 1.6rem;display:flex;align-items:center;justify-content:space-between;border-radius:6px 6px 0 0;border-bottom:3px solid #bae6fd}
.sd-modal-head-title{font-family:'Nunito',sans-serif;font-size:1rem;font-weight:700;color:#fff;display:flex;align-items:center;gap:.45rem}
.sd-modal-close{background:rgba(255,255,255,.12);border:none;color:rgba(255,255,255,.8);width:30px;height:30px;border-radius:50%;display:flex;align-items:center;justify-content:center;cursor:pointer;font-size:.95rem;transition:background .2s}
.sd-modal-close:hover{background:rgba(255,255,255,.22);color:#fff}
.sd-modal-body{padding:1.8rem 1.6rem}
.sd-modal-footer{padding:1rem 1.6rem;border-top:1px solid var(--border);display:flex;gap:.75rem;justify-content:flex-end;background:var(--bg-off);border-radius:0 0 6px 6px}
.sd-form-row{display:grid;grid-template-columns:1fr 1fr;gap:1rem;margin-bottom:1rem}
.sd-form-row.full{grid-template-columns:1fr}
.sd-form-group{display:flex;flex-direction:column;gap:.28rem}
.sd-label{font-family:'Nunito',sans-serif;font-size:.72rem;font-weight:700;letter-spacing:1.1px;text-transform:uppercase;color:var(--text-mid)}
.sd-input,.sd-select{border:1px solid var(--border);border-radius:3px;padding:.52rem .85rem;font-family:'Nunito',sans-serif;font-size:.9rem;color:var(--text-dark);background:var(--bg-white);transition:border-color .2s,box-shadow .2s;width:100%}
.sd-input:focus,.sd-select:focus{border-color:var(--primary);outline:none;box-shadow:0 0 0 3px rgba(14,165,233,.1)}
.sd-hint{font-family:'Nunito',sans-serif;font-size:.74rem;color:var(--text-muted)}
.sd-input-err{border-color:#e74c3c!important}
.sd-field-error{font-family:'Nunito',sans-serif;font-size:.74rem;color:#e74c3c;display:none}
.sd-alert{padding:.8rem 1.1rem;border-radius:4px;font-family:'Nunito',sans-serif;font-size:.88rem;display:flex;align-items:center;gap:.55rem;margin-bottom:1.4rem}
.sd-alert.success{background:#e8f8ee;border:1px solid #a9dfbf;color:#1e8449}
.sd-alert.danger{background:#fdecea;border:1px solid #f5b7b1;color:#c0392b}

/* ─────────────────────────────────────────────────────────────────────
   SECTION 2 — LEAVE MANAGEMENT PANEL  (new)
───────────────────────────────────────────────────────────────────── */

/* Panel wrapper — mirrors att-monitor-panel */
.lv-panel{
  background:#f0f9ff;
  background-image:radial-gradient(ellipse 80% 60% at 20% -10%,rgba(14,165,233,.07) 0%,transparent 70%),
                   radial-gradient(ellipse 60% 50% at 80% 110%,rgba(99,102,241,.04) 0%,transparent 60%);
  border:1px solid var(--border);
  border-top:3px solid var(--primary);
  border-radius:var(--radius);
  box-shadow:var(--shadow-sm);
  margin-top:2rem;
  overflow:hidden;
  font-family:'Nunito',sans-serif;
}

/* Panel header */
.lv-header{
  background:rgba(255,255,255,.72);backdrop-filter:blur(14px);
  border-bottom:1px solid rgba(255,255,255,.9);
  padding:.9rem 1.5rem;
  display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:.75rem;
  box-shadow:0 1px 8px rgba(14,165,233,.07);
}
.lv-header-left .lv-title{font-size:1.1rem;font-weight:800;color:#0c1a2e;display:flex;align-items:center;gap:.5rem}
.lv-header-left .lv-title i{color:var(--primary)}
.lv-header-left .lv-sub{font-size:.72rem;color:var(--text-muted);margin-top:2px}
.lv-live-badge{display:flex;align-items:center;gap:.5rem;font-size:.75rem;font-weight:700;color:#0369a1;background:#e0f2fe;border:1px solid rgba(14,165,233,.25);border-radius:20px;padding:4px 12px}
.lv-live-dot{width:8px;height:8px;border-radius:50%;background:#22c55e;position:relative;flex-shrink:0}
.lv-live-dot::after{content:'';position:absolute;inset:-3px;border-radius:50%;background:rgba(34,197,94,.35);animation:lv-pulse 1.8s ease infinite}
@keyframes lv-pulse{0%{opacity:.8;transform:scale(1)}70%{opacity:0;transform:scale(1.9)}100%{opacity:0;transform:scale(1.9)}}

/* KPI row */
.lv-kpi-row{display:grid;grid-template-columns:repeat(8,1fr);gap:8px;padding:.75rem 1rem;background:#f0f9ff;border-bottom:1px solid var(--border)}
@media(max-width:1100px){.lv-kpi-row{grid-template-columns:repeat(4,1fr)}}
@media(max-width:600px){.lv-kpi-row{grid-template-columns:repeat(2,1fr)}}
.lv-kpi{background:#fff;border-radius:10px;border:1px solid var(--border);box-shadow:0 2px 8px rgba(14,165,233,.07);padding:10px 12px;display:flex;flex-direction:column;gap:6px;position:relative;overflow:hidden;transition:box-shadow .2s,transform .15s;cursor:pointer}
.lv-kpi:hover{box-shadow:0 4px 16px rgba(14,165,233,.14);transform:translateY(-2px)}
.lv-kpi::before{content:'';position:absolute;top:0;left:0;right:0;height:3px;border-radius:10px 10px 0 0}
.lv-kpi.kp-all::before  {background:linear-gradient(90deg,#0ea5e9,#38bdf8)}
.lv-kpi.kp-pend::before {background:linear-gradient(90deg,#f59e0b,#fcd34d)}
.lv-kpi.kp-appr::before {background:linear-gradient(90deg,#22c55e,#4ade80)}
.lv-kpi.kp-rej::before  {background:linear-gradient(90deg,#ef4444,#f87171)}
.lv-kpi.kp-canc::before {background:linear-gradient(90deg,#94a3b8,#cbd5e1)}
.lv-kpi.kp-rev::before  {background:linear-gradient(90deg,#8b5cf6,#a78bfa)}
.lv-kpi.kp-urg::before  {background:linear-gradient(90deg,#f97316,#fb923c)}
.lv-kpi.kp-now::before  {background:linear-gradient(90deg,#0891b2,#06b6d4)}
.lv-kpi-top{display:flex;align-items:flex-start;justify-content:space-between}
.lv-kpi-icon{width:30px;height:30px;border-radius:8px;display:flex;align-items:center;justify-content:center;font-size:14px;flex-shrink:0}
.kp-all  .lv-kpi-icon{background:#e0f2fe;color:#0369a1}
.kp-pend .lv-kpi-icon{background:#fef3c7;color:#b45309}
.kp-appr .lv-kpi-icon{background:#dcfce7;color:#16a34a}
.kp-rej  .lv-kpi-icon{background:#fee2e2;color:#b91c1c}
.kp-canc .lv-kpi-icon{background:#f1f5f9;color:#64748b}
.kp-rev  .lv-kpi-icon{background:#ede9fe;color:#6d28d9}
.kp-urg  .lv-kpi-icon{background:#ffedd5;color:#c2410c}
.kp-now  .lv-kpi-icon{background:#cffafe;color:#0e7490}
.lv-kpi-val{font-size:1.5rem;font-weight:800;color:#0c1a2e;line-height:1;font-variant-numeric:tabular-nums}
.lv-kpi-lbl{font-size:.58rem;font-weight:700;letter-spacing:.06em;text-transform:uppercase;color:#64748b}

/* Tab bar — exact same pattern as adm-tab-bar */
.lv-tab-bar{display:flex;gap:0;border-bottom:2px solid #e2e8f0;margin:0 1.25rem;flex-wrap:wrap}
.lv-tab{padding:.55rem 1.1rem;font-size:.8rem;font-weight:600;color:#64748b;cursor:pointer;border:none;background:none;border-bottom:2px solid transparent;margin-bottom:-2px;display:flex;align-items:center;gap:.4rem;transition:color .15s,border-color .15s;white-space:nowrap;font-family:'Nunito',sans-serif}
.lv-tab:hover{color:var(--primary)}
.lv-tab.lv-active{color:var(--primary);border-bottom-color:var(--primary)}
.lv-tab-pane{display:none;padding:1.25rem}
.lv-tab-pane.lv-visible{display:block}

/* Filter bar */
.lv-filter-bar{display:flex;align-items:center;gap:.65rem;flex-wrap:wrap;margin-bottom:1rem}
.lv-search-wrap{display:flex;align-items:center;gap:6px;background:#fff;border:1px solid #e2e8f0;border-radius:10px;padding:6px 11px;transition:border-color .2s}
.lv-search-wrap:focus-within{border-color:var(--primary);box-shadow:0 0 0 3px rgba(14,165,233,.1)}
.lv-search-wrap i{color:#64748b;font-size:13px}
.lv-search-wrap input{border:none;outline:none;font-family:'Nunito',sans-serif;font-size:.82rem;color:#0f172a;width:160px;background:transparent}
.lv-form-ctrl{background:#f8faff;border:1.5px solid #e2e8f0;border-radius:9px;color:#0f172a;font-size:.82rem;padding:.4rem .65rem;outline:none;transition:border-color .15s;font-family:'Nunito',sans-serif}
.lv-form-ctrl:focus{border-color:var(--primary);box-shadow:0 0 0 3px rgba(14,165,233,.1)}

/* Bulk bar */
.lv-bulk-bar{display:none;align-items:center;gap:.6rem;padding:.55rem .75rem;background:linear-gradient(135deg,#e0f2fe,#dbeafe);border:1px solid rgba(14,165,233,.2);border-radius:9px;margin-bottom:.75rem;flex-wrap:wrap}
.lv-bulk-bar.visible{display:flex}
.lv-bulk-count{font-size:.8rem;font-weight:700;color:#0369a1}
.lv-btn{display:inline-flex;align-items:center;gap:.35rem;padding:.45rem .85rem;border-radius:9px;font-size:.78rem;font-weight:600;cursor:pointer;border:none;transition:all .15s;font-family:'Nunito',sans-serif}
.lv-btn-primary{background:var(--primary);color:#fff}.lv-btn-primary:hover{background:var(--primary-dark)}
.lv-btn-success{background:#16a34a;color:#fff}.lv-btn-success:hover{background:#15803d}
.lv-btn-danger{background:#fff;color:#b91c1c;border:1.5px solid #fecaca}.lv-btn-danger:hover{background:#fee2e2;border-color:#f87171}
.lv-btn-warning{background:#f59e0b;color:#fff}.lv-btn-warning:hover{background:#d97706}
.lv-btn-outline{background:#fff;color:#334155;border:1.5px solid #e2e8f0}.lv-btn-outline:hover{border-color:var(--primary);color:var(--primary);background:#e0f2fe}
.lv-btn-sm{padding:.3rem .65rem;font-size:.72rem}

/* Request table */
.lv-table-wrap{overflow-x:auto}
.lv-table{width:100%;border-collapse:collapse;font-size:.83rem}
.lv-table thead th{text-align:left;font-size:.67rem;font-weight:700;text-transform:uppercase;letter-spacing:.07em;color:#64748b;padding:.55rem .85rem;border-bottom:2px solid #e2e8f0;white-space:nowrap;background:#f8faff}
.lv-table thead th.check-col{width:40px}
.lv-table tbody tr{border-bottom:1px solid #f1f5f9;transition:background .12s}
.lv-table tbody tr:hover{background:#f8faff}
.lv-table tbody tr.lv-selected{background:#e0f2fe}
.lv-table td{padding:.65rem .85rem;color:#334155;vertical-align:middle}
.lv-table td .staff-name{font-weight:700;color:#0c1a2e;font-size:.84rem}
.lv-table td .staff-meta{font-size:.7rem;color:#64748b;margin-top:1px}
.lv-table .date-range{font-size:.78rem;color:#0f172a;font-weight:600}
.lv-table .date-days{font-size:.7rem;color:#64748b}
.lv-table .reason-cell{max-width:180px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;font-size:.78rem;color:#475569;cursor:help}
.lv-actions{display:flex;gap:.35rem;align-items:center}

/* Status badges */
.lv-badge{display:inline-flex;align-items:center;gap:.25rem;padding:.2rem .6rem;border-radius:20px;font-size:.68rem;font-weight:700;letter-spacing:.03em;white-space:nowrap}
.lv-badge-pending  {background:#fef3c7;color:#92400e;border:1px solid #fde68a}
.lv-badge-approved {background:#dcfce7;color:#065f46;border:1px solid #86efac}
.lv-badge-rejected {background:#fee2e2;color:#7f1d1d;border:1px solid #fca5a5}
.lv-badge-cancelled{background:#f1f5f9;color:#475569;border:1px solid #e2e8f0}
.lv-badge-revoked  {background:#ede9fe;color:#4c1d95;border:1px solid #c4b5fd}

/* Leave type chip */
.lv-type-chip{display:inline-flex;align-items:center;gap:.25rem;padding:.15rem .55rem;border-radius:20px;font-size:.68rem;font-weight:600;background:#e0f2fe;color:#0369a1;border:1px solid rgba(14,165,233,.2)}
.lv-type-chip.unpaid{background:#ede9fe;color:#5b21b6;border-color:rgba(139,92,246,.2)}

/* Urgency badge */
.lv-urgent{display:inline-flex;align-items:center;gap:3px;background:#fee2e2;color:#b91c1c;border-radius:20px;padding:1px 7px;font-size:.65rem;font-weight:700;margin-left:4px;vertical-align:middle}

/* Empty state */
.lv-empty{padding:3rem;text-align:center;color:#64748b}
.lv-empty-circle{width:80px;height:80px;border-radius:50%;background:linear-gradient(135deg,#e0f2fe,#c7d2fe);display:flex;align-items:center;justify-content:center;font-size:2rem;margin:0 auto .75rem;color:var(--primary)}

/* Review modal */
.lv-modal-overlay{position:fixed;inset:0;background:rgba(0,0,0,.45);backdrop-filter:blur(4px);z-index:2100;display:none;align-items:flex-end;justify-content:center;padding:0}
@media(min-width:600px){.lv-modal-overlay{align-items:center;padding:1rem}}
.lv-modal-overlay.open{display:flex;animation:lvFadeIn .2s ease}
@keyframes lvFadeIn{from{opacity:0}to{opacity:1}}
.lv-modal-box{background:#fff;width:100%;max-width:520px;height:100%;max-height:620px;border-radius:16px 16px 0 0;box-shadow:0 24px 64px rgba(0,0,0,.2);overflow:auto;animation:lvSlideUp .25s ease}
@media(min-width:600px){.lv-modal-box{border-radius:16px;animation:lvZoomIn .2s ease}}
@keyframes lvSlideUp{from{transform:translateY(100%)}to{transform:none}}
@keyframes lvZoomIn{from{opacity:0;transform:scale(.95)}to{opacity:1;transform:none}}
.lv-modal-head{background:var(--primary);padding:1rem 1.25rem;display:flex;align-items:center;justify-content:space-between}
.lv-modal-head h4{font-family:'Nunito',sans-serif;font-size:.95rem;font-weight:800;color:#fff;margin:0;display:flex;align-items:center;gap:.4rem}
.lv-modal-close-btn{width:28px;height:28px;border-radius:8px;border:none;background:rgba(255,255,255,.15);color:#fff;cursor:pointer;display:flex;align-items:center;justify-content:center;font-size:15px;transition:background .15s}
.lv-modal-close-btn:hover{background:rgba(255,255,255,.28)}
.lv-modal-body{padding:1.25rem}
.lv-detail-grid{display:grid;grid-template-columns:1fr 1fr;gap:.65rem;margin-bottom:1rem}
.lv-detail-item{background:#f8faff;border:1px solid #e2e8f0;border-radius:9px;padding:.6rem .85rem}
.lv-detail-label{font-size:.63rem;font-weight:700;text-transform:uppercase;letter-spacing:.06em;color:#64748b;margin-bottom:.2rem}
.lv-detail-value{font-size:.82rem;font-weight:600;color:#0c1a2e}
.lv-note-area{width:100%;border:1.5px solid #e2e8f0;border-radius:9px;padding:.6rem .85rem;font-family:'Nunito',sans-serif;font-size:.83rem;color:#0f172a;resize:vertical;min-height:72px;outline:none;transition:border-color .15s}
.lv-note-area:focus{border-color:var(--primary);box-shadow:0 0 0 3px rgba(14,165,233,.1)}
.lv-modal-foot{padding:.85rem 1.25rem;border-top:1px solid #e2e8f0;display:flex;gap:.65rem;justify-content:flex-end;background:#f8faff;flex-wrap:wrap}

/* Balance viewer */
.lv-bal-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(140px,1fr));gap:.6rem;margin-top:.75rem}
.lv-bal-card{background:#fff;border:1.5px solid #e2e8f0;border-radius:10px;padding:.7rem .85rem;position:relative;overflow:hidden}
.lv-bal-card::before{content:'';position:absolute;top:0;left:0;right:0;height:3px;background:var(--bc,var(--primary))}
.lv-bal-card .bc-label{font-size:.62rem;font-weight:700;text-transform:uppercase;letter-spacing:.07em;color:#64748b;margin-bottom:.25rem;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.lv-bal-card .bc-avail{font-size:1.4rem;font-weight:800;color:#0c1a2e;line-height:1}
.lv-bal-card .bc-sub{font-size:.65rem;color:#94a3b8;margin-top:.15rem}
.lv-bal-progress{height:4px;background:#e2e8f0;border-radius:99px;margin-top:.35rem;overflow:hidden}
.lv-bal-fill{height:100%;border-radius:99px;background:var(--bc,var(--primary));transition:width .5s}

/* Calendar tab */
.lv-cal-grid{display:grid;grid-template-columns:repeat(7,1fr);gap:2px;font-size:.72rem;margin-top:.5rem}
.lv-cal-head{text-align:center;padding:.35rem 0;font-weight:700;color:#64748b;text-transform:uppercase;letter-spacing:.05em;font-size:.62rem}
.lv-cal-day{min-height:48px;background:#fff;border:1px solid #f1f5f9;border-radius:6px;padding:4px 5px;position:relative;cursor:default;transition:background .15s}
.lv-cal-day:hover{background:#f0f9ff}
.lv-cal-day.lv-today{border-color:var(--primary);background:#e0f2fe}
.lv-cal-day.lv-other-month{background:#f8fafc;opacity:.5}
.lv-cal-num{font-size:.7rem;font-weight:700;color:#334155}
.lv-cal-event{font-size:.58rem;background:#0ea5e9;color:#fff;border-radius:3px;padding:1px 4px;margin-top:2px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.lv-cal-event.ev-casual{background:#f59e0b}.lv-cal-event.ev-sick{background:#ef4444}
.lv-cal-event.ev-earned{background:#22c55e}.lv-cal-event.ev-matern{background:#8b5cf6}
.lv-cal-event.ev-berev{background:#0891b2}

/* Toast (scoped) */
.lv-toast{position:fixed;top:1rem;right:1rem;z-index:3000;display:flex;flex-direction:column;gap:.5rem;pointer-events:none}
.lv-toast-item{background:#fff;border:1px solid #e2e8f0;border-left:4px solid var(--tc,var(--primary));border-radius:10px;padding:.7rem 1rem;box-shadow:0 8px 24px rgba(0,0,0,.12);font-family:'Nunito',sans-serif;font-size:.82rem;font-weight:600;color:#0f172a;display:flex;align-items:center;gap:.5rem;min-width:220px;animation:lvToastIn .25s ease;pointer-events:auto}
.lv-toast-item.lv-tc-success{--tc:#22c55e;color:#065f46}
.lv-toast-item.lv-tc-error  {--tc:#ef4444;color:#7f1d1d}
.lv-toast-item.lv-tc-info   {--tc:var(--primary);color:#0369a1}
@keyframes lvToastIn{from{opacity:0;transform:translateX(20px)}to{opacity:1;transform:none}}

/* Export bar (mirrors att-export-bar) */
.lv-export-bar{display:flex;align-items:center;gap:.65rem;padding:.55rem 1.25rem;border-top:1px solid #e2e8f0;background:#f8fafc;flex-wrap:wrap}
.lv-export-bar span{font-size:.73rem;color:#64748b}
.lv-export-btn{font-size:.7rem;font-weight:600;letter-spacing:.04em;text-transform:uppercase;padding:.3rem .85rem;border:1px solid #e2e8f0;border-radius:8px;background:#fff;color:#334155;cursor:pointer;transition:all .2s;display:inline-flex;align-items:center;gap:.35rem;font-family:'Nunito',sans-serif}
.lv-export-btn:hover{border-color:var(--primary);color:var(--primary)}

/* Spinner */
.lv-spin i{animation:lv-rot .6s linear infinite}
@keyframes lv-rot{to{transform:rotate(360deg)}}

/* ─── RESPONSIVE ─────────────────────────────────────────────────────── */
@media(max-width:1100px){.sd-grid{grid-template-columns:repeat(2,1fr)}}
@media(max-width:600px){
  .sd-grid{grid-template-columns:1fr}
  .sd-header{flex-direction:column;gap:.5rem}
  .sd-form-row{grid-template-columns:1fr}
  .sd-modal-footer{flex-direction:column-reverse}
  .sd-btn{font-size:.72rem;padding:.5rem 1rem}
  .lv-kpi-row{grid-template-columns:repeat(2,1fr)}
  .lv-detail-grid{grid-template-columns:1fr}
  .lv-table thead{display:none}
  .lv-table tbody tr{display:block;border:1px solid #e2e8f0;border-radius:10px;margin-bottom:.6rem;padding:.6rem}
  .lv-table td{display:flex;justify-content:space-between;align-items:center;border:none;padding:.3rem .4rem;font-size:.78rem}
  .lv-table td::before{content:attr(data-label);font-size:.65rem;font-weight:700;color:#64748b;text-transform:uppercase;letter-spacing:.06em;flex-shrink:0;margin-right:.5rem}
  .lv-table td.check-col{justify-content:flex-start}
  .lv-table td.check-col::before{display:none}
}
</style>

<!-- ════════════════════════════════════════════════════════════════════
     ORIGINAL STAFF PANEL
════════════════════════════════════════════════════════════════════ -->
<div class="sd-header">
  <div>
    <h1 class="sd-title"><i class="bi bi-people-fill"></i> Staff Dashboard</h1>
    <p class="sd-subtitle">Manage your team, roles, delivery personnel and leave requests from one place.</p>
  </div>
</div>

<div class="sd-grid">
  <div class="sd-card c-green">
    <div class="sd-icon g"><i class="bi bi-person-plus-fill"></i></div>
    <h5 class="sd-card-title">Add Staff</h5>
    <p class="sd-card-desc">Register new staff members with role-based access and system permissions.</p>
    <a href="addUser" class="sd-btn g" data-tip="Open the new-staff registration form"><i class="bi bi-plus-circle"></i> Add Staff</a>
  </div>
  <div class="sd-card c-blue">
    <div class="sd-icon b"><i class="bi bi-people-fill"></i></div>
    <h5 class="sd-card-title">View Staff</h5>
    <p class="sd-card-desc">Browse, search, and manage existing staff accounts, roles, and status.</p>
    <a href="userList" class="sd-btn b" data-tip="Browse the full staff directory"><i class="bi bi-list-ul"></i> View Staff</a>
  </div>
  <div class="sd-card c-amber">
    <div class="sd-icon a"><i class="bi bi-person-badge-fill"></i></div>
    <h5 class="sd-card-title">User Dashboard</h5>
    <p class="sd-card-desc">Switch to the user-facing view — orders, stock, and billing at a glance.</p>
    <a href="userDashboard" class="sd-btn a" data-tip="Open the staff / user dashboard"><i class="bi bi-arrow-right-circle"></i> User Dashboard</a>
  </div>
  <div class="sd-card c-teal">
    <div class="sd-icon t"><i class="bi bi-truck"></i></div>
    <h5 class="sd-card-title">Add Delivery Person</h5>
    <p class="sd-card-desc">Register a new delivery staff member and send them login credentials by email.</p>
    <button class="sd-btn t" onclick="sdOpenModal()" data-tip="Fill in the quick-add form for a delivery person">
      <i class="bi bi-plus-circle"></i> Add Delivery
    </button>
  </div>
  <!-- NEW CARD — opens leave panel -->
  <div class="sd-card c-sky" style="border-color:#bae6fd">
    <div class="sd-icon s"><i class="bi bi-calendar-check-fill"></i></div>
    <h5 class="sd-card-title">Leave Management</h5>
    <p class="sd-card-desc">Review, approve or reject staff leave requests. Monitor balances &amp; calendar.</p>
    <button class="sd-btn s" onclick="lvScrollToPanel()" data-tip="Open the leave management console">
      <i class="bi bi-arrow-down-circle"></i> Manage Leaves
    </button>
  </div>
</div>

<!-- ════════════════════════════════════════════════════════════════════
     LEAVE MANAGEMENT PANEL
════════════════════════════════════════════════════════════════════ -->
<div class="lv-panel" id="lvPanel">

  <!-- Panel header -->
  <div class="lv-header">
    <div class="lv-header-left">
      <div class="lv-title"><i class="bi bi-calendar2-heart-fill"></i> Leave Management Control Centre</div>
      <div class="lv-sub">Review · Approve · Monitor — full admin control over staff leave requests &amp; balances</div>
    </div>
    <div style="display:flex;gap:.6rem;align-items:center;flex-wrap:wrap">
      <div class="lv-live-badge"><span class="lv-live-dot"></span><span id="lvLastRefresh">Loading…</span></div>
      <button class="lv-btn lv-btn-outline lv-btn-sm" id="lvRefreshBtn" onclick="lvRefreshAll()">
        <i class="bi bi-arrow-clockwise"></i> Refresh
      </button>
    </div>
  </div>

  <!-- KPI row -->
  <div class="lv-kpi-row">
    <div class="lv-kpi kp-all"  onclick="lvSetTabFilter('all','all')">
      <div class="lv-kpi-top"><div><div class="lv-kpi-lbl">Total</div></div><div class="lv-kpi-icon"><i class="bi bi-collection-fill"></i></div></div>
      <div class="lv-kpi-val" id="lvKpiTotal">—</div>
    </div>
    <div class="lv-kpi kp-pend" onclick="lvSetTabFilter('pending','pending')">
      <div class="lv-kpi-top"><div><div class="lv-kpi-lbl">Pending</div></div><div class="lv-kpi-icon"><i class="bi bi-hourglass-split"></i></div></div>
      <div class="lv-kpi-val" id="lvKpiPending">—</div>
    </div>
    <div class="lv-kpi kp-appr" onclick="lvSetTabFilter('all','approved')">
      <div class="lv-kpi-top"><div><div class="lv-kpi-lbl">Approved</div></div><div class="lv-kpi-icon"><i class="bi bi-check-circle-fill"></i></div></div>
      <div class="lv-kpi-val" id="lvKpiApproved">—</div>
    </div>
    <div class="lv-kpi kp-rej" onclick="lvSetTabFilter('all','rejected')">
      <div class="lv-kpi-top"><div><div class="lv-kpi-lbl">Rejected</div></div><div class="lv-kpi-icon"><i class="bi bi-x-circle-fill"></i></div></div>
      <div class="lv-kpi-val" id="lvKpiRejected">—</div>
    </div>
    <div class="lv-kpi kp-canc" onclick="lvSetTabFilter('all','cancelled')">
      <div class="lv-kpi-top"><div><div class="lv-kpi-lbl">Cancelled</div></div><div class="lv-kpi-icon"><i class="bi bi-slash-circle-fill"></i></div></div>
      <div class="lv-kpi-val" id="lvKpiCancelled">—</div>
    </div>
    <div class="lv-kpi kp-rev" onclick="lvSetTabFilter('all','revoked')">
      <div class="lv-kpi-top"><div><div class="lv-kpi-lbl">Revoked</div></div><div class="lv-kpi-icon"><i class="bi bi-arrow-counterclockwise"></i></div></div>
      <div class="lv-kpi-val" id="lvKpiRevoked">—</div>
    </div>
    <div class="lv-kpi kp-urg">
      <div class="lv-kpi-top"><div><div class="lv-kpi-lbl">Urgent Today</div></div><div class="lv-kpi-icon"><i class="bi bi-exclamation-triangle-fill"></i></div></div>
      <div class="lv-kpi-val" id="lvKpiUrgent">—</div>
    </div>
    <div class="lv-kpi kp-now">
      <div class="lv-kpi-top"><div><div class="lv-kpi-lbl">On Leave Now</div></div><div class="lv-kpi-icon"><i class="bi bi-person-walking"></i></div></div>
      <div class="lv-kpi-val" id="lvKpiOnLeave">—</div>
    </div>
  </div>

  <!-- Tab bar -->
  <div class="lv-tab-bar">
    <button class="lv-tab lv-active" id="lvTabPending"  onclick="lvSwitchTab('pending',this)">
      <i class="bi bi-hourglass-split"></i> Pending
      <span id="lvPendingBadge" style="display:none;background:#ef4444;color:#fff;font-size:.6rem;padding:1px 5px;border-radius:10px;font-weight:700;margin-left:2px">0</span>
    </button>
    <button class="lv-tab" id="lvTabAll"     onclick="lvSwitchTab('all',this)"><i class="bi bi-list-ul"></i> All Requests</button>
    <button class="lv-tab" id="lvTabBalance" onclick="lvSwitchTab('balance',this)"><i class="bi bi-wallet2"></i> Staff Balances</button>
    <button class="lv-tab" id="lvTabCal"     onclick="lvSwitchTab('calendar',this)"><i class="bi bi-calendar3"></i> Calendar</button>
  </div>

  <!-- ══ TAB: PENDING ══ -->
  <div class="lv-tab-pane lv-visible" id="lvPane-pending">
    <div class="lv-filter-bar">
      <div class="lv-search-wrap"><i class="bi bi-search"></i><input type="text" id="lvPendSearch" placeholder="Search staff…" oninput="lvFilterTable('pending')"></div>
      <select class="lv-form-ctrl" id="lvPendTypeFilter" onchange="lvFilterTable('pending')">
        <option value="">All Types</option>
        <option>Casual Leave</option><option>Sick Leave</option><option>Earned Leave</option>
        <option>Maternity Leave</option><option>Paternity Leave</option>
        <option>Bereavement Leave</option><option>Compensatory Off</option><option>Loss of Pay</option>
      </select>
      <button class="lv-btn lv-btn-outline lv-btn-sm" onclick="lvRefreshPending()"><i class="bi bi-arrow-clockwise"></i></button>
    </div>
    <!-- Bulk actions bar -->
    <div class="lv-bulk-bar" id="lvBulkBar">
      <span class="lv-bulk-count" id="lvBulkCount">0 selected</span>
      <button class="lv-btn lv-btn-success lv-btn-sm" onclick="lvBulkAction('approve')"><i class="bi bi-check2-all"></i> Bulk Approve</button>
      <button class="lv-btn lv-btn-danger  lv-btn-sm" onclick="lvBulkAction('reject')"><i class="bi bi-x-lg"></i> Bulk Reject</button>
      <button class="lv-btn lv-btn-outline lv-btn-sm" onclick="lvClearSelection()"><i class="bi bi-x"></i> Clear</button>
    </div>
    <div class="lv-table-wrap">
      <table class="lv-table" id="lvPendTable">
        <thead>
          <tr>
            <th class="check-col"><input type="checkbox" id="lvSelectAll" onchange="lvToggleAll(this)"></th>
            <th>Staff Member</th>
            <th>Leave Type</th>
            <th>Dates &amp; Duration</th>
            <th>Session</th>
            <th>Reason</th>
            <th>Applied On</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody id="lvPendTbody">
          <tr><td colspan="8" class="lv-empty"><div class="lv-empty-circle"><i class="bi bi-hourglass-split"></i></div><p>Loading pending requests…</p></td></tr>
        </tbody>
      </table>
    </div>
    <div class="lv-export-bar">
      <span>Export:</span>
      <button class="lv-export-btn" onclick="lvExportCSV('pending')"><i class="bi bi-filetype-csv"></i> CSV</button>
    </div>
  </div>

  <!-- ══ TAB: ALL REQUESTS ══ -->
  <div class="lv-tab-pane" id="lvPane-all">
    <div class="lv-filter-bar">
      <div class="lv-search-wrap"><i class="bi bi-search"></i><input type="text" id="lvAllSearch" placeholder="Search staff…" oninput="lvFilterTable('all')"></div>
      <select class="lv-form-ctrl" id="lvAllStatusFilter" onchange="lvFilterTable('all')">
        <option value="">All Statuses</option>
        <option value="pending">Pending</option><option value="approved">Approved</option>
        <option value="rejected">Rejected</option><option value="cancelled">Cancelled</option>
        <option value="revoked">Revoked</option>
      </select>
      <select class="lv-form-ctrl" id="lvAllTypeFilter" onchange="lvFilterTable('all')">
        <option value="">All Types</option>
        <option>Casual Leave</option><option>Sick Leave</option><option>Earned Leave</option>
        <option>Maternity Leave</option><option>Paternity Leave</option>
        <option>Bereavement Leave</option><option>Compensatory Off</option><option>Loss of Pay</option>
      </select>
      <input type="date" class="lv-form-ctrl" id="lvAllFrom" onchange="lvLoadAll()">
      <input type="date" class="lv-form-ctrl" id="lvAllTo"   onchange="lvLoadAll()">
      <button class="lv-btn lv-btn-primary lv-btn-sm" onclick="lvLoadAll()"><i class="bi bi-funnel-fill"></i> Filter</button>
      <button class="lv-btn lv-btn-outline lv-btn-sm" onclick="lvClearAllFilters()"><i class="bi bi-x-circle"></i> Clear</button>
    </div>
    <div class="lv-table-wrap">
      <table class="lv-table" id="lvAllTable">
        <thead>
          <tr>
            <th>Staff Member</th>
            <th>Leave Type</th>
            <th>Dates &amp; Duration</th>
            <th>Reason</th>
            <th>Status</th>
            <th>Applied On</th>
            <th>Reviewed By</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody id="lvAllTbody">
          <tr><td colspan="8" class="lv-empty"><div class="lv-empty-circle"><i class="bi bi-list-ul"></i></div><p>Loading all requests…</p></td></tr>
        </tbody>
      </table>
    </div>
    <div class="lv-export-bar">
      <span>Export:</span>
      <button class="lv-export-btn" onclick="lvExportCSV('all')"><i class="bi bi-filetype-csv"></i> CSV</button>
      <button class="lv-export-btn" onclick="window.print()"><i class="bi bi-printer"></i> Print</button>
    </div>
  </div>

  <!-- ══ TAB: STAFF BALANCES ══ -->
  <div class="lv-tab-pane" id="lvPane-balance">
    <div class="lv-filter-bar">
      <div class="lv-search-wrap"><i class="bi bi-search"></i><input type="text" id="lvBalSearch" placeholder="Type username…" oninput="lvSearchBalance()"></div>
      <button class="lv-btn lv-btn-primary lv-btn-sm" onclick="lvLoadBalance(document.getElementById('lvBalSearch').value)"><i class="bi bi-search"></i> Look Up</button>
    </div>
    <div id="lvBalanceResult">
      <div class="lv-empty" style="padding:2rem">
        <div class="lv-empty-circle"><i class="bi bi-wallet2"></i></div>
        <p>Enter a staff username above to view their leave balance summary.</p>
      </div>
    </div>
  </div>

  <!-- ══ TAB: CALENDAR ══ -->
  <div class="lv-tab-pane" id="lvPane-calendar">
    <div class="lv-filter-bar">
      <button class="lv-btn lv-btn-outline lv-btn-sm" onclick="lvCalNav(-1)"><i class="bi bi-chevron-left"></i></button>
      <strong id="lvCalMonthLabel" style="font-size:.9rem;color:#0c1a2e;min-width:120px;text-align:center"></strong>
      <button class="lv-btn lv-btn-outline lv-btn-sm" onclick="lvCalNav(1)"><i class="bi bi-chevron-right"></i></button>
      <button class="lv-btn lv-btn-outline lv-btn-sm" onclick="lvCalGoToday()"><i class="bi bi-calendar-today"></i> Today</button>
    </div>
    <!-- Day-of-week headers -->
    <div class="lv-cal-grid" id="lvCalGrid">
      <div class="lv-cal-head">Sun</div><div class="lv-cal-head">Mon</div><div class="lv-cal-head">Tue</div>
      <div class="lv-cal-head">Wed</div><div class="lv-cal-head">Thu</div><div class="lv-cal-head">Fri</div><div class="lv-cal-head">Sat</div>
    </div>
    <div class="lv-cal-grid" id="lvCalDays" style="margin-top:4px"></div>
    <div style="padding:.75rem 0;display:flex;gap:1rem;flex-wrap:wrap;font-size:.72rem;color:#64748b;align-items:center">
      <strong style="color:#0c1a2e">Legend:</strong>
      <span><span style="display:inline-block;width:10px;height:10px;border-radius:2px;background:#0ea5e9;margin-right:4px"></span>Casual</span>
      <span><span style="display:inline-block;width:10px;height:10px;border-radius:2px;background:#ef4444;margin-right:4px"></span>Sick</span>
      <span><span style="display:inline-block;width:10px;height:10px;border-radius:2px;background:#22c55e;margin-right:4px"></span>Earned</span>
      <span><span style="display:inline-block;width:10px;height:10px;border-radius:2px;background:#8b5cf6;margin-right:4px"></span>Maternity</span>
      <span><span style="display:inline-block;width:10px;height:10px;border-radius:2px;background:#0891b2;margin-right:4px"></span>Bereavement</span>
      <span><span style="display:inline-block;width:10px;height:10px;border-radius:2px;background:#f59e0b;margin-right:4px"></span>Other</span>
    </div>
  </div>

</div><!-- /.lv-panel -->

<!-- ════════════════════════════════════════════════════════════════════
     REVIEW MODAL (approve / reject / revoke)
════════════════════════════════════════════════════════════════════ -->
<div class="lv-modal-overlay" id="lvReviewModal">
  <div class="lv-modal-box">
    <div class="lv-modal-head" id="lvModalHead">
      <h4><i class="bi bi-pencil-square" id="lvModalIcon"></i> <span id="lvModalTitle">Review Leave</span></h4>
      <button class="lv-modal-close-btn" onclick="lvCloseModal()"><i class="bi bi-x"></i></button>
    </div>
    <div class="lv-modal-body">
      <input type="hidden" id="lvModalReqId">
      <input type="hidden" id="lvModalAction">

      <!-- Detail grid -->
      <div class="lv-detail-grid" id="lvModalDetails">
        <div class="lv-detail-item"><div class="lv-detail-label">Staff</div><div class="lv-detail-value" id="lvMdStaff">—</div></div>
        <div class="lv-detail-item"><div class="lv-detail-label">Leave Type</div><div class="lv-detail-value" id="lvMdType">—</div></div>
        <div class="lv-detail-item"><div class="lv-detail-label">From Date</div><div class="lv-detail-value" id="lvMdFrom">—</div></div>
        <div class="lv-detail-item"><div class="lv-detail-label">To Date</div><div class="lv-detail-value" id="lvMdTo">—</div></div>
        <div class="lv-detail-item"><div class="lv-detail-label">Duration</div><div class="lv-detail-value" id="lvMdDays">—</div></div>
        <div class="lv-detail-item"><div class="lv-detail-label">Session</div><div class="lv-detail-value" id="lvMdSession">—</div></div>
        <div class="lv-detail-item"><div class="lv-detail-label">Applied On</div><div class="lv-detail-value" id="lvMdApplied">—</div></div>
        <div class="lv-detail-item"><div class="lv-detail-label">Contact</div><div class="lv-detail-value" id="lvMdContact">—</div></div>
      </div>

      <!-- Reason & handover (full-width) -->
      <div style="background:#f8faff;border:1px solid #e2e8f0;border-radius:9px;padding:.65rem .85rem;margin-bottom:.75rem">
        <div style="font-size:.63rem;font-weight:700;text-transform:uppercase;letter-spacing:.06em;color:#64748b;margin-bottom:.2rem">Reason</div>
        <div id="lvMdReason" style="font-size:.83rem;color:#0c1a2e;line-height:1.5"></div>
      </div>
      <div id="lvMdHandoverBox" style="background:#f8faff;border:1px solid #e2e8f0;border-radius:9px;padding:.65rem .85rem;margin-bottom:.75rem;display:none">
        <div style="font-size:.63rem;font-weight:700;text-transform:uppercase;letter-spacing:.06em;color:#64748b;margin-bottom:.2rem">Handover / Covering Person</div>
        <div id="lvMdHandover" style="font-size:.83rem;color:#0c1a2e;line-height:1.5"></div>
      </div>

      <!-- ── Supporting Document ─────────────────────────────────────── -->
      <div id="lvMdDocBox" style="display:none;margin-bottom:.75rem">
        <div style="font-size:.63rem;font-weight:700;text-transform:uppercase;letter-spacing:.06em;
                    color:#64748b;margin-bottom:.45rem;display:flex;align-items:center;gap:.4rem">
          <i class="bi bi-paperclip" style="color:var(--primary)"></i> Supporting Document
          <span id="lvMdDocRequired" style="display:none;background:#fef3c7;color:#92400e;
                font-size:.6rem;padding:1px 6px;border-radius:20px;border:1px solid #fde68a;font-weight:700">
            REQUIRED FOR THIS TYPE
          </span>
        </div>

        <!-- Image preview -->
        <div id="lvMdDocImageWrap"
             style="display:none;border:1px solid #e2e8f0;border-radius:10px;overflow:hidden;
                    background:#f8faff;position:relative;margin-bottom:.5rem">
          <div style="background:linear-gradient(135deg,#e0f2fe,#dbeafe);padding:.40rem .80rem;
                      font-size:.7rem;font-weight:700;color:#0369a1;display:flex;
                      align-items:center;justify-content:space-between">
            <span><i class="bi bi-image"></i> Image Preview</span>
            <a id="lvMdDocImageLink" href="#" target="_blank"
               style="font-size:.7rem;color:#0369a1;font-weight:600;
                      display:flex;align-items:center;gap:.25rem;text-decoration:none">
              <i class="bi bi-box-arrow-up-right"></i> Open Full
            </a>
          </div>
          <div style="padding:.6rem;text-align:center;background:#fff">
            <img id="lvMdDocImage" src="" alt="Supporting document"
                 style="max-width:100%;max-height:250px;height: auto; border-radius:6px;
                        object-fit:contain;cursor:zoom-in"
                 onclick="lvMdZoomImg(this.src)">
          </div>
        </div>

        <!-- PDF card -->
        <div id="lvMdDocPdfWrap"
             style="display:none;border:1px solid #e2e8f0;border-radius:10px;overflow:hidden;
                    background:#fff;margin-bottom:.5rem">
          <div style="background:linear-gradient(135deg,#fee2e2,#fecaca);padding:.45rem .85rem;
                      font-size:.7rem;font-weight:700;color:#b91c1c;display:flex;
                      align-items:center;justify-content:space-between">
            <span><i class="bi bi-file-earmark-pdf-fill"></i> PDF Document</span>
          </div>
          <div style="padding:.85rem;display:flex;align-items:center;gap:.85rem">
            <div style="width:48px;height:56px;background:#fee2e2;border-radius:8px;
                        display:flex;align-items:center;justify-content:center;flex-shrink:0">
              <i class="bi bi-file-earmark-pdf-fill" style="font-size:1.6rem;color:#b91c1c"></i>
            </div>
            <div style="flex:1;min-width:0">
              <div id="lvMdDocPdfName"
                   style="font-size:.82rem;font-weight:700;color:#0c1a2e;
                          white-space:nowrap;overflow:hidden;text-overflow:ellipsis"></div>
              <div style="font-size:.72rem;color:#64748b;margin-top:.15rem">
                PDF — click below to open in a new tab
              </div>
            </div>
            <a id="lvMdDocPdfLink" href="#" target="_blank"
               style="flex-shrink:0;background:#b91c1c;color:#fff;border-radius:8px;
                      padding:.4rem .85rem;font-size:.75rem;font-weight:700;text-decoration:none;
                      display:flex;align-items:center;gap:.3rem;white-space:nowrap">
              <i class="bi bi-box-arrow-up-right"></i> Open PDF
            </a>
          </div>
          <!-- Inline PDF embed (browsers that support it) -->
          <div style="border-top:1px solid #fee2e2;background:#f8faff">
            <iframe id="lvMdDocPdfFrame" src="" style="width:100%;height:340px;border:none"
                    title="PDF preview"></iframe>
          </div>
        </div>

        <!-- No-doc state (when doc required but not uploaded) -->
        <div id="lvMdDocMissingWrap"
             style="display:none;border:1.5px dashed #fca5a5;border-radius:10px;
                    padding:.85rem;text-align:center;background:#fff5f5">
          <i class="bi bi-exclamation-triangle-fill" style="color:#ef4444;font-size:1.25rem"></i>
          <div style="font-size:.8rem;font-weight:600;color:#7f1d1d;margin-top:.35rem">
            No document uploaded
          </div>
          <div style="font-size:.72rem;color:#b91c1c;margin-top:.15rem">
            This leave type requires a supporting document. Consider this before approving.
          </div>
        </div>
      </div>

      <!-- Image zoom overlay (lightbox) -->
      <div id="lvDocZoomOverlay"
           style="display:none;position:fixed;inset:0;background:rgba(0,0,0,.82);
                  z-index:9999;align-items:center;justify-content:center;cursor:zoom-out"
           onclick="this.style.display='none'">
        <img id="lvDocZoomImg" src="" alt="Document full view"
             style="max-width:94vw;max-height:92vh;border-radius:10px;
                    box-shadow:0 24px 64px rgba(0,0,0,.5);object-fit:contain">
        <button onclick="document.getElementById('lvDocZoomOverlay').style.display='none'"
                style="position:absolute;top:1rem;right:1rem;background:rgba(255,255,255,.15);
                       border:none;color:#fff;width:36px;height:36px;border-radius:50%;
                       font-size:1.1rem;cursor:pointer;display:flex;align-items:center;justify-content:center">
          <i class="bi bi-x-lg"></i>
        </button>
      </div>

      <!-- Admin note -->
      <div>
        <div class="lv-detail-label" style="margin-bottom:.35rem" id="lvModalNoteLabel">Admin Note / Reason</div>
        <textarea class="lv-note-area" id="lvModalNote" placeholder="Add a note for the employee (optional for approval, required for rejection)…"></textarea>
      </div>
    </div>
    <div class="lv-modal-foot" id="lvModalFoot">
      <button class="lv-btn lv-btn-outline" onclick="lvCloseModal()">Cancel</button>
      <button class="lv-btn lv-btn-success" id="lvModalApproveBtn" onclick="lvSubmitReview('approve')">
        <i class="bi bi-check2-circle"></i> Approve
      </button>
      <button class="lv-btn lv-btn-danger" id="lvModalRejectBtn" onclick="lvSubmitReview('reject')">
        <i class="bi bi-x-circle"></i> Reject
      </button>
      <button class="lv-btn lv-btn-warning" id="lvModalRevokeBtn" onclick="lvSubmitReview('revoke')" style="display:none">
        <i class="bi bi-arrow-counterclockwise"></i> Revoke
      </button>
    </div>
  </div>
</div>

<!-- Toast container -->
<div class="lv-toast" id="lvToastStack"></div>


<!-- ════════════════════════════════════════════════════════════════════
     ORIGINAL ADD-DELIVERY MODAL  (unchanged)
════════════════════════════════════════════════════════════════════ -->
<div class="sd-modal-backdrop" id="sdModalBackdrop" onclick="sdBackdropClose(event)">
  <div class="sd-modal" role="dialog" aria-modal="true" aria-labelledby="sdModalTitle">
    <div class="sd-modal-head">
      <span class="sd-modal-head-title" id="sdModalTitle">
        <i class="bi bi-truck"></i> Register Delivery Person
      </span>
      <button class="sd-modal-close" onclick="sdCloseModal()" aria-label="Close"><i class="bi bi-x-lg"></i></button>
    </div>
    <div class="sd-modal-body">
      <div id="sdFormAlert" style="display:none"></div>
      <form id="sdDeliveryForm" action="addDelivery" method="post" novalidate>
        <div class="sd-form-row">
          <div class="sd-form-group">
            <label class="sd-label" for="sd_username">Username <span style="color:#e74c3c">*</span></label>
            <input type="text" id="sd_username" name="username" class="sd-input" placeholder="e.g. ravi_kumar99" autocomplete="username">
            <span class="sd-hint">4–30 characters, letters / numbers / underscore only</span>
            <span class="sd-field-error" id="err_username"></span>
          </div>
          <div class="sd-form-group">
            <label class="sd-label" for="sd_password">Password <span style="color:#e74c3c">*</span></label>
            <div style="position:relative">
              <input type="password" id="sd_password" name="password" class="sd-input" placeholder="Min 8 chars" autocomplete="new-password" style="padding-right:2.6rem">
              <button type="button" onclick="sdTogglePwd()" style="position:absolute;right:.7rem;top:50%;transform:translateY(-50%);background:none;border:none;cursor:pointer;color:var(--text-muted);font-size:1rem" aria-label="Toggle password"><i class="bi bi-eye" id="sdPwdEye"></i></button>
            </div>
            <span class="sd-hint">At least 8 chars, include a number &amp; symbol</span>
            <span class="sd-field-error" id="err_password"></span>
          </div>
        </div>
        <div class="sd-form-row">
          <div class="sd-form-group">
            <label class="sd-label" for="sd_email">Email <span style="color:#e74c3c">*</span></label>
            <input type="email" id="sd_email" name="email" class="sd-input" placeholder="ravi@example.com" autocomplete="email">
            <span class="sd-field-error" id="err_email"></span>
          </div>
          <div class="sd-form-group">
            <label class="sd-label" for="sd_mobile">Mobile <span style="color:#e74c3c">*</span></label>
            <input type="text" id="sd_mobile" name="mobile" class="sd-input" placeholder="9876543210" maxlength="10" inputmode="numeric">
            <span class="sd-hint">10-digit Indian number</span>
            <span class="sd-field-error" id="err_mobile"></span>
          </div>
        </div>
        <div class="sd-form-row full">
          <div class="sd-form-group">
            <label class="sd-label" for="sd_address">Address <span style="color:#e74c3c">*</span></label>
            <input type="text" id="sd_address" name="address" class="sd-input" placeholder="Door No., Street, City">
            <span class="sd-field-error" id="err_address"></span>
          </div>
        </div>
        <div class="sd-form-row">
          <div class="sd-form-group">
            <label class="sd-label" for="sd_gender">Gender <span style="color:#e74c3c">*</span></label>
            <select id="sd_gender" name="gender" class="sd-select">
              <option value="">— Select —</option><option value="Male">Male</option><option value="Female">Female</option><option value="Other">Other</option>
            </select>
            <span class="sd-field-error" id="err_gender"></span>
          </div>
          <div class="sd-form-group">
            <label class="sd-label" for="sd_joining">Joining Date <span style="color:#e74c3c">*</span></label>
            <input type="date" id="sd_joining" name="joining_date" class="sd-input">
            <span class="sd-field-error" id="err_joining"></span>
          </div>
        </div>
      </form>
    </div>
    <div class="sd-modal-footer">
      <button type="button" class="sd-btn" onclick="sdCloseModal()" style="background:transparent;color:var(--text-mid);border:2px solid var(--border)" data-tip="Close without saving"><i class="bi bi-x"></i> Cancel</button>
      <button type="button" class="sd-btn t" onclick="sdSubmit()" data-tip="Validate and save — sends login credentials by email"><i class="bi bi-send"></i> Save &amp; Send Credentials</button>
    </div>
  </div>
</div>


<script>
/* ═══════════════════════════════════════════════════════════════════════
   ORIGINAL: Delivery modal scripts
═══════════════════════════════════════════════════════════════════════ */
function sdOpenModal(){document.getElementById('sdModalBackdrop').classList.add('open');document.getElementById('sd_username').focus();}
function sdCloseModal(){document.getElementById('sdModalBackdrop').classList.remove('open');sdClearErrors();document.getElementById('sdDeliveryForm').reset();document.getElementById('sdFormAlert').style.display='none';}
function sdBackdropClose(e){if(e.target===document.getElementById('sdModalBackdrop'))sdCloseModal();}
document.addEventListener('keydown',function(e){if(e.key==='Escape'){sdCloseModal();lvCloseModal();document.getElementById('lvDocZoomOverlay').style.display='none';}});
function sdTogglePwd(){var f=document.getElementById('sd_password');var eye=document.getElementById('sdPwdEye');f.type=f.type==='password'?'text':'password';eye.className=f.type==='password'?'bi bi-eye':'bi bi-eye-slash';}
function sdClearErrors(){document.querySelectorAll('.sd-field-error').forEach(function(el){el.textContent='';el.style.display='none';});document.querySelectorAll('.sd-input-err').forEach(function(el){el.classList.remove('sd-input-err');});}
function sdFieldErr(id,errId,msg){var input=document.getElementById(id);var err=document.getElementById(errId);input.classList.add('sd-input-err');err.textContent=msg;err.style.display='block';if(!window._sdFirstErr)window._sdFirstErr=input;}
function sdShowAlert(type,msg){var box=document.getElementById('sdFormAlert');box.className='sd-alert '+type;box.innerHTML='<i class="bi bi-'+(type==='success'?'check-circle':'exclamation-triangle')+'-fill"></i> '+msg;box.style.display='flex';box.scrollIntoView({behavior:'smooth',block:'nearest'});}
function sdSubmit(){sdClearErrors();window._sdFirstErr=null;var username=document.getElementById('sd_username').value.trim();var password=document.getElementById('sd_password').value;var email=document.getElementById('sd_email').value.trim();var mobile=document.getElementById('sd_mobile').value.trim();var address=document.getElementById('sd_address').value.trim();var gender=document.getElementById('sd_gender').value;var joining=document.getElementById('sd_joining').value;var ok=true;if(!username||username.length<4||!/^[a-zA-Z0-9_]{4,30}$/.test(username)){sdFieldErr('sd_username','err_username','4–30 chars, letters/numbers/underscore only');ok=false;}if(password.length<8||!/[0-9]/.test(password)||!/[!@#$%^&*]/.test(password)){sdFieldErr('sd_password','err_password','Min 8 chars — must include a number and a symbol');ok=false;}if(!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)){sdFieldErr('sd_email','err_email','Enter a valid email address');ok=false;}if(!/^[6-9][0-9]{9}$/.test(mobile)){sdFieldErr('sd_mobile','err_mobile','Enter a valid 10-digit Indian mobile number');ok=false;}if(address.length<5){sdFieldErr('sd_address','err_address','Address must be at least 5 characters');ok=false;}if(!gender){sdFieldErr('sd_gender','err_gender','Please select a gender');ok=false;}if(!joining){sdFieldErr('sd_joining','err_joining','Please select a joining date');}else if(joining>new Date().toISOString().split('T')[0]){sdFieldErr('sd_joining','err_joining','Joining date cannot be in the future');ok=false;}if(!ok){if(window._sdFirstErr)window._sdFirstErr.focus();sdShowAlert('danger','Please fix the errors highlighted above.');return;}document.getElementById('sdDeliveryForm').submit();}

/* ═══════════════════════════════════════════════════════════════════════
   LEAVE MANAGEMENT ENGINE
═══════════════════════════════════════════════════════════════════════ */

/* Context path from JSP — used by LeaveDocServlet URL builder */
window._appContextPath = '<%=request.getContextPath()%>';

/* ── State ─────────────────────────────────────────────────────────── */
let _lvPendData = [];
let _lvAllData  = [];
let _lvSelIds   = new Set();
let _lvCalMonth = new Date();  // JS Date object, 1st of displayed month

/* ── Init: load pending on panel render ─────────────────────────────── */
(function lvInit(){
  lvRefreshAll();
})();

function lvScrollToPanel(){
  const p=document.getElementById('lvPanel');
  if(p) p.scrollIntoView({behavior:'smooth',block:'start'});
}

/* ── Tab switching ─────────────────────────────────────────────────── */
function lvSwitchTab(name, btn){
  document.querySelectorAll('.lv-tab').forEach(t=>t.classList.remove('lv-active'));
  if(btn) btn.classList.add('lv-active');
  document.querySelectorAll('.lv-tab-pane').forEach(p=>p.classList.remove('lv-visible'));
  const pane=document.getElementById('lvPane-'+name);
  if(pane) pane.classList.add('lv-visible');

  // lazy-load data on first visit to a tab
  if(name==='all' && _lvAllData.length===0) lvLoadAll();
  if(name==='calendar') lvRenderCalendar();
}

/* Set a tab active and optionally set its status filter */
function lvSetTabFilter(tab, status){
  const btn=document.getElementById(tab==='pending'?'lvTabPending':'lvTabAll');
  lvSwitchTab(tab, btn);
  if(tab==='all'){
    const sf=document.getElementById('lvAllStatusFilter');
    if(sf) sf.value=status||'';
    lvLoadAll();
  }
}

/* ── Refresh all ────────────────────────────────────────────────────── */
async function lvRefreshAll(){
  lvRefreshStats();
  lvRefreshPending();
}

/* ── KPI stats ─────────────────────────────────────────────────────── */
async function lvRefreshStats(){
  try{
    const r=await fetch('AdminLeaveServlet?action=stats');
    const d=await r.json();
    _setKpi('lvKpiTotal',   d.total);
    _setKpi('lvKpiPending', d.pending);
    _setKpi('lvKpiApproved',d.approved);
    _setKpi('lvKpiRejected',d.rejected);
    _setKpi('lvKpiCancelled',d.cancelled);
    _setKpi('lvKpiRevoked', d.revoked);
    _setKpi('lvKpiUrgent',  d.urgentToday);
    _setKpi('lvKpiOnLeave', d.onLeaveNow);

    const badge=document.getElementById('lvPendingBadge');
    if(badge){ badge.textContent=d.pending; badge.style.display=d.pending>0?'':'none'; }
    document.getElementById('lvLastRefresh').textContent=
      new Date().toLocaleTimeString('en-IN',{hour:'2-digit',minute:'2-digit',hour12:true});
  }catch(e){ console.warn('Leave stats error',e); }
}

function _setKpi(id, val){
  const el=document.getElementById(id);
  if(el) el.textContent=(val!=null?val:'—');
}

/* ── Pending tab ────────────────────────────────────────────────────── */
async function lvRefreshPending(){
  try{
    const r=await fetch('AdminLeaveServlet?action=pending');
    _lvPendData=await r.json();
    lvRenderPending(_lvPendData);
  }catch(e){ _lvPendToast('Failed to load pending requests','error'); }
}

function lvFilterTable(tab){
  if(tab==='pending'){
    const q=(document.getElementById('lvPendSearch').value||'').toLowerCase();
    const t=(document.getElementById('lvPendTypeFilter').value||'');
    const filtered=_lvPendData.filter(r=>
      (!q || r.username.toLowerCase().includes(q)) &&
      (!t || r.leaveType===t)
    );
    lvRenderPending(filtered);
  } else {
    const q=(document.getElementById('lvAllSearch').value||'').toLowerCase();
    const s=(document.getElementById('lvAllStatusFilter').value||'');
    const t=(document.getElementById('lvAllTypeFilter').value||'');
    const filtered=_lvAllData.filter(r=>
      (!q || r.username.toLowerCase().includes(q)) &&
      (!s || r.status===s) &&
      (!t || r.leaveType===t)
    );
    lvRenderAll(filtered);
  }
}

function lvRenderPending(data){
  lvClearSelection();
  const tb=document.getElementById('lvPendTbody');
  if(!data.length){
    tb.innerHTML=`<tr><td colspan="8" class="lv-empty">
      <div class="lv-empty-circle"><i class="bi bi-check-circle-fill" style="color:#22c55e"></i></div>
      <p style="color:#16a34a;font-weight:600">All clear — no pending leave requests.</p></td></tr>`;
    return;
  }
  tb.innerHTML=data.map(r=>`
    <tr id="lvRow-${r.id}" data-id="${r.id}">
      <td class="check-col" data-label=""><input type="checkbox" class="lv-check" value="${r.id}" onchange="lvToggleCheck(this)"></td>
      <td data-label="Staff">
        <div class="staff-name">${_esc(r.username)}</div>
        ${r.contact?`<div class="staff-meta"><i class="bi bi-telephone-fill"></i> ${_esc(r.contact)}</div>`:''}
        ${r.documentPath?`<div class="staff-meta" style="color:#0369a1;margin-top:2px"><i class="bi bi-paperclip"></i> Doc attached</div>`:''}
      </td>
      <td data-label="Leave Type">
        <span class="lv-type-chip ${r.isPaid?'':'unpaid'}">${_esc(r.leaveType)}</span>
        ${!r.isPaid?'<span class="lv-urgent">Unpaid</span>':''}
      </td>
      <td data-label="Dates">
        <div class="date-range">${_fmtDate(r.from)} → ${_fmtDate(r.to)}</div>
        <div class="date-days">${r.days} day${parseFloat(r.days)!==1?'s':''} · ${_fmtSession(r.session)}</div>
      </td>
      <td data-label="Session">${_fmtSession(r.session)}</td>
      <td data-label="Reason"><span class="reason-cell" title="${_esc(r.reason)}">${_esc(r.reason)}</span></td>
      <td data-label="Applied">${_fmtTs(r.appliedOn)}</td>
      <td data-label="Actions">
        <div class="lv-actions">
          <button class="lv-btn lv-btn-success lv-btn-sm" onclick="lvOpenReview(${r.id},'approve')" title="Approve">
            <i class="bi bi-check2"></i>
          </button>
          <button class="lv-btn lv-btn-danger lv-btn-sm" onclick="lvOpenReview(${r.id},'reject')" title="Reject">
            <i class="bi bi-x-lg"></i>
          </button>
          <button class="lv-btn lv-btn-outline lv-btn-sm" onclick="lvOpenReview(${r.id},'view')" title="View Details">
            <i class="bi bi-eye"></i>
          </button>
        </div>
      </td>
    </tr>`).join('');
}

/* ── All-requests tab ───────────────────────────────────────────────── */
async function lvLoadAll(){
  const status=document.getElementById('lvAllStatusFilter').value;
  const type  =document.getElementById('lvAllTypeFilter').value;
  const from  =document.getElementById('lvAllFrom').value;
  const to    =document.getElementById('lvAllTo').value;
  let url=`AdminLeaveServlet?action=all`;
  if(status) url+=`&status=${encodeURIComponent(status)}`;
  if(type)   url+=`&leaveType=${encodeURIComponent(type)}`;
  if(from)   url+=`&from=${from}`;
  if(to)     url+=`&to=${to}`;
  try{
    const r=await fetch(url);
    _lvAllData=await r.json();
    lvRenderAll(_lvAllData);
  }catch(e){ _lvPendToast('Failed to load requests','error'); }
}

function lvClearAllFilters(){
  ['lvAllStatusFilter','lvAllTypeFilter','lvAllFrom','lvAllTo'].forEach(id=>{
    const el=document.getElementById(id);
    if(el) el.value='';
  });
  document.getElementById('lvAllSearch').value='';
  lvLoadAll();
}

function lvRenderAll(data){
  const tb=document.getElementById('lvAllTbody');
  if(!data.length){
    tb.innerHTML=`<tr><td colspan="8" class="lv-empty"><div class="lv-empty-circle"><i class="bi bi-inbox"></i></div><p>No requests match the current filters.</p></td></tr>`;
    return;
  }
  tb.innerHTML=data.map(r=>`
    <tr id="lvAllRow-${r.id}">
      <td data-label="Staff">
        <div class="staff-name">${_esc(r.username)}</div>
        ${r.documentPath?`<div style="font-size:.7rem;color:#0369a1;margin-top:2px;display:flex;align-items:center;gap:2px"><i class="bi bi-paperclip"></i> Doc attached</div>`:''}
      </td>
      <td data-label="Type"><span class="lv-type-chip ${r.isPaid?'':'unpaid'}">${_esc(r.leaveType)}</span></td>
      <td data-label="Dates">
        <div class="date-range">${_fmtDate(r.from)} → ${_fmtDate(r.to)}</div>
        <div class="date-days">${r.days} day${parseFloat(r.days)!==1?'s':''}</div>
      </td>
      <td data-label="Reason"><span class="reason-cell" title="${_esc(r.reason)}">${_esc(r.reason)}</span></td>
      <td data-label="Status"><span class="lv-badge lv-badge-${r.status}">${r.status}</span></td>
      <td data-label="Applied">${_fmtTs(r.appliedOn)}</td>
      <td data-label="Reviewed By">${r.reviewedBy?`<span style="font-size:.78rem;color:#0369a1;font-weight:600">${_esc(r.reviewedBy)}</span>`:'<span style="color:#94a3b8;font-size:.75rem">—</span>'}</td>
      <td data-label="Actions">
        <div class="lv-actions">
          ${r.status==='pending'?`
            <button class="lv-btn lv-btn-success lv-btn-sm" onclick="lvOpenReview(${r.id},'approve')" title="Approve"><i class="bi bi-check2"></i></button>
            <button class="lv-btn lv-btn-danger  lv-btn-sm" onclick="lvOpenReview(${r.id},'reject')"  title="Reject"><i class="bi bi-x-lg"></i></button>
          `:''}
          ${r.status==='approved'?`
            <button class="lv-btn lv-btn-warning lv-btn-sm" onclick="lvOpenReview(${r.id},'revoke')" title="Revoke Approval"><i class="bi bi-arrow-counterclockwise"></i></button>
          `:''}
          <button class="lv-btn lv-btn-outline lv-btn-sm" onclick="lvOpenReview(${r.id},'view')" title="View Details"><i class="bi bi-eye"></i></button>
        </div>
      </td>
    </tr>`).join('');
}

/* ── Review modal ───────────────────────────────────────────────────── */
function lvOpenReview(id, action){
  // find from either dataset
  const r = _lvPendData.find(x=>x.id===id) || _lvAllData.find(x=>x.id===id);
  if(!r){ _lvPendToast('Request data not found. Refresh and try again.','error'); return; }

  document.getElementById('lvModalReqId').value  = id;
  document.getElementById('lvModalAction').value = action;

  // detail fields
  document.getElementById('lvMdStaff').textContent   = r.username;
  document.getElementById('lvMdType').textContent    = r.leaveType + (r.isPaid?'':' (Unpaid)');
  document.getElementById('lvMdFrom').textContent    = _fmtDate(r.from);
  document.getElementById('lvMdTo').textContent      = _fmtDate(r.to);
  document.getElementById('lvMdDays').textContent    = r.days + ' working day' + (parseFloat(r.days)!==1?'s':'');
  document.getElementById('lvMdSession').textContent = _fmtSession(r.session);
  document.getElementById('lvMdApplied').textContent = _fmtTs(r.appliedOn);
  document.getElementById('lvMdContact').textContent = r.contact || '—';
  document.getElementById('lvMdReason').textContent  = r.reason  || '—';

  const hBox=document.getElementById('lvMdHandoverBox');
  const hVal=document.getElementById('lvMdHandover');
  const handoverText=(r.handover?r.handover+' ':'')+( r.covering?'Covered by: '+r.covering:'');
  if(handoverText.trim()){ hBox.style.display='block'; hVal.textContent=handoverText; }
  else hBox.style.display='none';

  // ── Document section ───────────────────────────────────────────────
  lvRenderModalDoc(r.documentPath, r.leaveType);

  // configure buttons per action
  const head=document.getElementById('lvModalHead');
  const approveBtn=document.getElementById('lvModalApproveBtn');
  const rejectBtn=document.getElementById('lvModalRejectBtn');
  const revokeBtn=document.getElementById('lvModalRevokeBtn');
  document.getElementById('lvModalNote').value='';

  if(action==='approve'){
    document.getElementById('lvModalTitle').textContent='Approve Leave';
    document.getElementById('lvModalIcon').className='bi bi-check2-circle';
    head.style.background='#16a34a';
    approveBtn.style.display=''; rejectBtn.style.display='none'; revokeBtn.style.display='none';
    document.getElementById('lvModalNoteLabel').textContent='Admin Note (optional)';
  } else if(action==='reject'){
    document.getElementById('lvModalTitle').textContent='Reject Leave';
    document.getElementById('lvModalIcon').className='bi bi-x-circle';
    head.style.background='#b91c1c';
    approveBtn.style.display='none'; rejectBtn.style.display=''; revokeBtn.style.display='none';
    document.getElementById('lvModalNoteLabel').textContent='Reason for Rejection (required)';
  } else if(action==='revoke'){
    document.getElementById('lvModalTitle').textContent='Revoke Approved Leave';
    document.getElementById('lvModalIcon').className='bi bi-arrow-counterclockwise';
    head.style.background='#d97706';
    approveBtn.style.display='none'; rejectBtn.style.display='none'; revokeBtn.style.display='';
    document.getElementById('lvModalNoteLabel').textContent='Reason for Revocation (required)';
  } else { // view-only
    document.getElementById('lvModalTitle').textContent='Leave Request Details';
    document.getElementById('lvModalIcon').className='bi bi-info-circle';
    head.style.background='var(--primary)';
    approveBtn.style.display='none'; rejectBtn.style.display='none'; revokeBtn.style.display='none';
    document.getElementById('lvModalNoteLabel').textContent='Previous Admin Note';
    document.getElementById('lvModalNote').value=r.reviewerNote||'';
    document.getElementById('lvModalNote').readOnly=true;
  }
  if(action!=='view') document.getElementById('lvModalNote').readOnly=false;

  document.getElementById('lvReviewModal').classList.add('open');
}

/* ── Document viewer in modal ────────────────────────────────────────── */
const DOC_REQUIRED_TYPES = ['Sick Leave','Maternity Leave','Paternity Leave'];

function lvRenderModalDoc(docPath, leaveType) {
  const box        = document.getElementById('lvMdDocBox');
  const imgWrap    = document.getElementById('lvMdDocImageWrap');
  const pdfWrap    = document.getElementById('lvMdDocPdfWrap');
  const missWrap   = document.getElementById('lvMdDocMissingWrap');
  const reqBadge   = document.getElementById('lvMdDocRequired');

  // Always show the doc section
  box.style.display = 'block';

  // Show "required" badge for relevant leave types
  const isRequired = DOC_REQUIRED_TYPES.some(
    t => (leaveType||'').toLowerCase().includes(t.toLowerCase().split(' ')[0])
  );
  reqBadge.style.display = isRequired ? 'inline-flex' : 'none';

  // Reset all sub-sections
  imgWrap.style.display  = 'none';
  pdfWrap.style.display  = 'none';
  missWrap.style.display = 'none';

  if (!docPath) {
    missWrap.style.display = isRequired ? 'block' : 'none';
    if (!isRequired) box.style.display = 'none';
    return;
  }

  // ── Build the URL via LeaveDocServlet (file is outside webroot) ──
  // docPath stored in DB is: "leave-docs/<filename>"
  // LeaveDocServlet endpoint: GET /LeaveDocServlet?file=leave-docs/<filename>
  const ctxPath = window._appContextPath || '';   // set by JSP below
  const url = ctxPath + '/LeaveDocServlet?file=' + encodeURIComponent(docPath);

  const ext      = docPath.split('.').pop().toLowerCase();
  const isImage  = ['jpg','jpeg','png','gif','webp'].includes(ext);
  const isPdf    = ext === 'pdf';
  const fileName = docPath.split('/').pop();

  if (isImage) {
    imgWrap.style.display = 'block';
    const imgEl = document.getElementById('lvMdDocImage');
    imgEl.src = url;
    imgEl.onerror = () => {
      imgWrap.style.display = 'none';
      missWrap.innerHTML = `<i class="bi bi-exclamation-triangle-fill" style="color:#ef4444;font-size:1.25rem"></i>
        <div style="font-size:.8rem;font-weight:600;color:#7f1d1d;margin-top:.35rem">Could not load image</div>
        <a href="${url}" target="_blank" style="font-size:.75rem;color:#0369a1;margin-top:.25rem;display:inline-block">
          <i class="bi bi-box-arrow-up-right"></i> Open directly
        </a>`;
      missWrap.style.display = 'block';
    };
    document.getElementById('lvMdDocImageLink').href = url;

  } else if (isPdf) {
    pdfWrap.style.display = 'block';
    document.getElementById('lvMdDocPdfName').textContent = fileName;
    document.getElementById('lvMdDocPdfLink').href        = url;
    document.getElementById('lvMdDocPdfFrame').src        = url;

  } else {
    // Unknown extension — generic download card, no iframe
    pdfWrap.style.display = 'block';
    document.getElementById('lvMdDocPdfName').textContent     = fileName;
    document.getElementById('lvMdDocPdfLink').href            = url;
    document.getElementById('lvMdDocPdfLink').innerHTML       =
      '<i class="bi bi-download"></i> Download File';
    document.getElementById('lvMdDocPdfFrame').src            = '';
  }
}

function lvMdZoomImg(src) {
  const overlay = document.getElementById('lvDocZoomOverlay');
  document.getElementById('lvDocZoomImg').src = src;
  overlay.style.display = 'flex';
}

function lvCloseModal(){
  document.getElementById('lvReviewModal').classList.remove('open');
  // Reset iframe to stop any background PDF load
  const frame = document.getElementById('lvMdDocPdfFrame');
  if (frame) frame.src = '';
  // Reset image
  const img = document.getElementById('lvMdDocImage');
  if (img) img.src = '';
}
document.getElementById('lvReviewModal').addEventListener('click',function(e){
  if(e.target===this) lvCloseModal();
});

async function lvSubmitReview(action){
  const id   = document.getElementById('lvModalReqId').value;
  const note = document.getElementById('lvModalNote').value.trim();

  if((action==='reject'||action==='revoke') && !note){
    _lvPendToast('A reason is required for '+action+'.','error');
    document.getElementById('lvModalNote').focus();
    return;
  }

  const body=new URLSearchParams({action, requestId:id, note});
  try{
    const r=await fetch('AdminLeaveServlet',{method:'POST',body});
    const d=await r.json();
    if(d.ok){
      lvCloseModal();
      _lvPendToast(action.charAt(0).toUpperCase()+action.slice(1)+'d successfully','success');
      lvRefreshAll();
      // reload all-tab data if visible
      if(document.getElementById('lvPane-all').classList.contains('lv-visible')) lvLoadAll();
    } else {
      _lvPendToast(d.error||'Action failed','error');
    }
  }catch(e){ _lvPendToast('Network error. Please try again.','error'); }
}

/* ── Bulk actions ───────────────────────────────────────────────────── */
function lvToggleAll(masterCb){
  document.querySelectorAll('.lv-check').forEach(cb=>{
    cb.checked=masterCb.checked;
    const row=cb.closest('tr');
    if(row) row.classList.toggle('lv-selected',masterCb.checked);
    if(masterCb.checked) _lvSelIds.add(parseInt(cb.value));
    else _lvSelIds.delete(parseInt(cb.value));
  });
  _lvUpdateBulkBar();
}

function lvToggleCheck(cb){
  const id=parseInt(cb.value);
  if(cb.checked){ _lvSelIds.add(id); cb.closest('tr')?.classList.add('lv-selected'); }
  else           { _lvSelIds.delete(id); cb.closest('tr')?.classList.remove('lv-selected'); }
  _lvUpdateBulkBar();
}

function _lvUpdateBulkBar(){
  const bar=document.getElementById('lvBulkBar');
  const cnt=document.getElementById('lvBulkCount');
  if(_lvSelIds.size>0){ bar.classList.add('visible'); cnt.textContent=_lvSelIds.size+' selected'; }
  else bar.classList.remove('visible');
}

function lvClearSelection(){
  _lvSelIds.clear();
  document.querySelectorAll('.lv-check').forEach(cb=>cb.checked=false);
  document.querySelectorAll('.lv-selected').forEach(r=>r.classList.remove('lv-selected'));
  const master=document.getElementById('lvSelectAll');
  if(master) master.checked=false;
  _lvUpdateBulkBar();
}

async function lvBulkAction(action){
  if(_lvSelIds.size===0){ _lvPendToast('Select at least one request first.','info'); return; }
  const ids=[..._lvSelIds].join(',');
  let note='';
  if(action==='reject'){
    note=prompt('Enter a rejection reason for all selected requests:');
    if(note===null) return; // cancelled
    if(!note.trim()){ _lvPendToast('A rejection reason is required.','error'); return; }
  }
  const body=new URLSearchParams({action:'bulk'+action.charAt(0).toUpperCase()+action.slice(1), ids, note});
  try{
    const r=await fetch('AdminLeaveServlet',{method:'POST',body});
    const d=await r.json();
    _lvPendToast(`Bulk ${action}: ${d[action==='approve'?'approved':'rejected']} done, ${d.failed} failed`,'success');
    lvClearSelection();
    lvRefreshAll();
  }catch(e){ _lvPendToast('Bulk action failed','error'); }
}

/* ── Balance lookup ─────────────────────────────────────────────────── */
let _lvBalTimeout=null;
function lvSearchBalance(){
  clearTimeout(_lvBalTimeout);
  _lvBalTimeout=setTimeout(()=>{
    const v=document.getElementById('lvBalSearch').value.trim();
    if(v.length>=2) lvLoadBalance(v);
  },500);
}

async function lvLoadBalance(username){
  if(!username||username.trim().length<2) return;
  const box=document.getElementById('lvBalanceResult');
  box.innerHTML='<div style="padding:1rem;color:#64748b"><i class="bi bi-hourglass-split"></i> Loading…</div>';
  try{
    const r=await fetch(`AdminLeaveServlet?action=staffBalance&username=${encodeURIComponent(username)}`);
    const data=await r.json();
    if(!Array.isArray(data)||!data.length){
      box.innerHTML='<div class="lv-empty"><p>No balance data found for <strong>'+_esc(username)+'</strong>.</p></div>';
      return;
    }
    const colors=['#0ea5e9','#22c55e','#f59e0b','#8b5cf6','#ef4444','#0891b2','#e67e22','#64748b'];
    box.innerHTML=`
      <div style="font-size:.88rem;font-weight:700;color:#0c1a2e;margin-bottom:.5rem">
        <i class="bi bi-person-circle" style="color:var(--primary)"></i> Balance for <strong>${_esc(username)}</strong> — ${new Date().getFullYear()}
      </div>
      <div class="lv-bal-grid">
        ${data.map((b,i)=>{
          const pct=b.allotted>0?Math.min(100,Math.round((b.used/b.allotted)*100)):0;
          const col=colors[i%colors.length];
          return `<div class="lv-bal-card" style="--bc:${col}">
            <div class="bc-label" title="${_esc(b.type)}">${_esc(b.type)}</div>
            <div class="bc-avail" style="color:${col}">${b.available}</div>
            <div class="bc-sub">of ${b.allotted} ${b.paid?'paid':'unpaid'} · used ${b.used}</div>
            <div class="lv-bal-progress"><div class="lv-bal-fill" style="width:${pct}%"></div></div>
          </div>`;
        }).join('')}
      </div>`;
  }catch(e){ box.innerHTML='<div class="lv-empty"><p>Failed to load balance data.</p></div>'; }
}

/* ── Calendar ───────────────────────────────────────────────────────── */
function lvCalNav(dir){
  _lvCalMonth=new Date(_lvCalMonth.getFullYear(), _lvCalMonth.getMonth()+dir, 1);
  lvRenderCalendar();
}
function lvCalGoToday(){
  _lvCalMonth=new Date();
  _lvCalMonth.setDate(1);
  lvRenderCalendar();
}

async function lvRenderCalendar(){
  const year=_lvCalMonth.getFullYear();
  const month=_lvCalMonth.getMonth(); // 0-indexed
  const monthStr=year+'-'+(month+1<10?'0':'')+(month+1);

  document.getElementById('lvCalMonthLabel').textContent=
    _lvCalMonth.toLocaleString('en-IN',{month:'long',year:'numeric'});

  // fetch approved leaves for this month
  let events=[];
  try{
    const r=await fetch(`AdminLeaveServlet?action=calendar&month=${monthStr}`);
    events=await r.json();
  }catch(e){}

  // build event map keyed by ISO date
  const evMap={};
  events.forEach(ev=>{
    let d=new Date(ev.from);
    const end=new Date(ev.to);
    while(d<=end){
      const key=d.toISOString().slice(0,10);
      if(!evMap[key]) evMap[key]=[];
      evMap[key].push(ev);
      d=new Date(d.getTime()+86400000);
    }
  });

  const today=new Date().toISOString().slice(0,10);
  const firstDay=new Date(year,month,1).getDay(); // 0=Sun
  const daysInMonth=new Date(year,month+1,0).getDate();

  let html='';
  for(let i=0;i<firstDay;i++){
    html+=`<div class="lv-cal-day lv-other-month"></div>`;
  }
  for(let d=1;d<=daysInMonth;d++){
    const iso=year+'-'+(month+1<10?'0':'')+(month+1)+'-'+(d<10?'0':'')+d;
    const isToday=iso===today;
    const dayEvs=evMap[iso]||[];
    const evHtml=dayEvs.slice(0,3).map(ev=>{
      const cls=_lvCalEvClass(ev.type);
      return `<div class="lv-cal-event ${cls}" title="${_esc(ev.username+': '+ev.type)}">${_esc(ev.username)}</div>`;
    }).join('');
    const moreCount=dayEvs.length-3;
    html+=`<div class="lv-cal-day${isToday?' lv-today':''}">
      <div class="lv-cal-num">${d}${dayEvs.length?`<span style="font-size:.55rem;background:var(--primary);color:#fff;border-radius:4px;padding:0 3px;margin-left:3px">${dayEvs.length}</span>`:''}
      </div>
      ${evHtml}
      ${moreCount>0?`<div style="font-size:.55rem;color:var(--primary);font-weight:700">+${moreCount} more</div>`:''}
    </div>`;
  }
  document.getElementById('lvCalDays').innerHTML=html;
}

function _lvCalEvClass(type){
  if(!type) return '';
  const t=type.toLowerCase();
  if(t.includes('casual'))     return 'ev-casual';
  if(t.includes('sick'))       return 'ev-sick';
  if(t.includes('earned'))     return 'ev-earned';
  if(t.includes('matern'))     return 'ev-matern';
  if(t.includes('bereave')||t.includes('berev')) return 'ev-berev';
  return '';
}

/* ── CSV Export ─────────────────────────────────────────────────────── */
function lvExportCSV(tab){
  const data=tab==='pending'?_lvPendData:_lvAllData;
  const rows=[['#','Username','Leave Type','From','To','Days','Session','Reason','Status','Applied On','Reviewed By']];
  data.forEach((r,i)=>rows.push([i+1,r.username,r.leaveType,r.from,r.to,r.days,r.session,r.reason,r.status,r.appliedOn||'',r.reviewedBy||'']));
  const csv=rows.map(r=>r.map(c=>'"'+String(c).replace(/"/g,'""')+'"').join(',')).join('\n');
  const a=document.createElement('a');
  a.href='data:text/csv;charset=utf-8,'+encodeURIComponent(csv);
  a.download='leave_requests_'+new Date().toISOString().slice(0,10)+'.csv';
  a.click();
}

/* ── Toast ──────────────────────────────────────────────────────────── */
function _lvPendToast(msg, type='info'){
  const stack=document.getElementById('lvToastStack');
  const item=document.createElement('div');
  const icons={'success':'check-circle-fill','error':'exclamation-circle-fill','info':'info-circle-fill'};
  item.className=`lv-toast-item lv-tc-${type}`;
  item.innerHTML=`<i class="bi bi-${icons[type]||'info-circle-fill'}"></i>${_esc(msg)}`;
  stack.appendChild(item);
  setTimeout(()=>{ item.style.opacity='0'; item.style.transform='translateX(20px)'; item.style.transition='all .4s'; setTimeout(()=>item.remove(),400); },3500);
}

/* ── Utils ──────────────────────────────────────────────────────────── */
function _esc(s){
  if(s==null) return '';
  return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}
function _fmtDate(d){
  if(!d) return '—';
  const dt=new Date(d+'T00:00:00');
  return dt.toLocaleDateString('en-IN',{day:'2-digit',month:'short',year:'numeric'});
}
function _fmtTs(ts){
  if(!ts) return '—';
  const d=new Date(ts);
  return d.toLocaleDateString('en-IN',{day:'2-digit',month:'short',year:'numeric'})+' '+d.toLocaleTimeString('en-IN',{hour:'2-digit',minute:'2-digit',hour12:true});
}
function _fmtSession(s){
  if(!s) return 'Full Day';
  return s.replace(/_/g,' ').replace(/\b\w/g,c=>c.toUpperCase());
}

/* Auto-refresh stats every 60s */
setInterval(()=>{ lvRefreshStats(); }, 60000);
</script>
