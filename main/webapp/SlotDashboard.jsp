<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*,com.util.*,java.time.LocalDate,java.time.format.DateTimeFormatter" %>
<%
    List<DeliverySlot> slots = (List<DeliverySlot>) request.getAttribute("slots");
    List<DeliveryZone> zones = (List<DeliveryZone>) request.getAttribute("zones");
    LocalDate viewDate       = (LocalDate)           request.getAttribute("viewDate");
    String ctx               = request.getContextPath();

    if (slots == null) slots = new ArrayList<>();

    /*
     * BUG-09 FIX: Use computeIfAbsent() so every slot is retained.
     * All 7 slot types pre-registered in chronological order.
     */
    Map<String, List<DeliverySlot>> byType = new LinkedHashMap<>();
    byType.put("MIDNIGHT",      new ArrayList<>());
    byType.put("EARLY_MORNING", new ArrayList<>());
    byType.put("AM",            new ArrayList<>());
    byType.put("PM",            new ArrayList<>());
    byType.put("EVENING",       new ArrayList<>());
    byType.put("FULL_DAY",      new ArrayList<>());
    byType.put("NIGHT",         new ArrayList<>());

    for (DeliverySlot s : slots) {
        byType.computeIfAbsent(s.getSlotType(), k -> new ArrayList<>()).add(s);
    }

    int totalAgents    = slots.size();
    int totalOrders    = slots.stream().mapToInt(DeliverySlot::getTotalOrders).sum();
    int totalDelivered = slots.stream().mapToInt(DeliverySlot::getDeliveredCount).sum();
    int totalPending   = slots.stream().mapToInt(DeliverySlot::getPendingCount).sum();
    int completionRate = totalOrders > 0 ? (int) Math.round(totalDelivered * 100.0 / totalOrders) : 0;

    /* Tab meta-data: code, icon class, display label, time range */
    String[] tabCodes  = {"ALL","MIDNIGHT","EARLY_MORNING","AM","PM","EVENING","FULL_DAY","NIGHT"};
    String[] tabIcons  = {"bi-calendar2-check","bi-moon-stars","bi-sunrise","bi-sun","bi-sun-fill","bi-moon","bi-calendar2-week","bi-moon-fill"};
    String[] tabLabels = {"All Slots","Midnight","Early Morn","Morning","Afternoon","Evening","Full Day","Night"};
    String[] tabTimes  = {"All shifts","02–06","04–08","06–12","12–18","18–22","06–22","22–02"};
%>

<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width,initial-scale=1"/>
<title>Slot Monitor Dashboard</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet"/>
<link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Nunito:wght@300;400;500;600;700;800&display=swap" rel="stylesheet"/>
<style>
/* ═══════════════════════════════════════════════════════════════════
   DESIGN TOKENS — aligned with Admin Dashboard (dashboard.jsp)
   ═══════════════════════════════════════════════════════════════════ */
:root {
  --primary:       #0ea5e9;
  --primary-dark:  #0369a1;
  --primary-light: #e0f2fe;
  --accent:        #38bdf8;
  --accent-light:  #f0f9ff;
  --green:         #16a34a;
  --green-bg:      #dcfce7;
  --amber:         #b45309;
  --amber-bg:      #fef3c7;
  --blue:          #1d4ed8;
  --blue-bg:       #dbeafe;
  --red:           #dc2626;
  --red-bg:        #fee2e2;
  --slate:         #64748b;
  --slate-bg:      #f1f5f9;
  --text1:         #0c1a2e;
  --text2:         #1e3a5f;
  --text3:         #64748b;
  --bg:            #f0f9ff;
  --card:          #ffffff;
  --border:        #dbeafe;
  --r:             10px;
  --shadow:        0 2px 12px rgba(14,165,233,.08);
  --shadow-md:     0 4px 24px rgba(14,165,233,.13);
  --font-sans:     'Nunito', sans-serif;
  --font-mono:     'SF Mono', 'Fira Code', ui-monospace, monospace;
}

*, *::before, *::after { box-sizing: border-box; }

body {
  font-family: var(--font-sans);
  background: var(--bg);
  color: var(--text1);
  min-height: 100vh;
  -webkit-font-smoothing: antialiased;
}

/* ═══════════════════════════════════════════════════════════════════
   TOP HEADER BAR — sky-blue matching dashboard navbar
   ═══════════════════════════════════════════════════════════════════ */
.dash-header {
  background: var(--primary);
  box-shadow: 0 2px 16px rgba(14,165,233,.25);
  padding: 20px 24px;
  display: flex; align-items: center; justify-content: space-between;
  gap: 16px; flex-wrap: wrap;
  border-bottom: none;
}
.dash-title {
  font-size: 20px; font-weight: 800; color: #fff; margin-bottom: 2px;
  display: flex; align-items: center; gap: 10px; letter-spacing: .3px;
}
.dash-subtitle { font-size: 13px; color: rgba(255,255,255,.8); font-weight: 500; }
.dash-controls { display: flex; gap: 10px; align-items: center; flex-wrap: wrap; }

/* Date input styled to match dashboard */
.dash-controls .form-control {
  border: 1.5px solid rgba(255,255,255,.35);
  background: rgba(255,255,255,.15);
  color: #fff;
  border-radius: 20px;
  font-family: var(--font-sans);
  font-size: .82rem;
  font-weight: 600;
}
.dash-controls .form-control:focus {
  background: rgba(255,255,255,.25);
  border-color: #fff;
  color: #fff;
  box-shadow: none;
}
.dash-controls .form-control::placeholder { color: rgba(255,255,255,.6); }
/* Make date picker calendar icon white */
.dash-controls input[type="date"]::-webkit-calendar-picker-indicator { filter: invert(1); }

/* Header action buttons — ghost style matching dashboard logout/bell */
.btn-hdr {
  font-family: var(--font-sans);
  font-size: .78rem;
  font-weight: 700;
  letter-spacing: .4px;
  padding: .4rem 1rem;
  border-radius: 20px;
  border: 1.5px solid rgba(255,255,255,.35);
  color: #fff;
  background: rgba(255,255,255,.12);
  cursor: pointer;
  transition: all .2s;
  display: inline-flex; align-items: center; gap: 5px;
  text-decoration: none;
}
.btn-hdr:hover { background: rgba(255,255,255,.25); border-color: #fff; color: #fff; }
.btn-hdr-amber  { background: rgba(251,191,36,.18); border-color: rgba(251,191,36,.5); }
.btn-hdr-amber:hover { background: rgba(251,191,36,.3); border-color: #fbbf24; }
.btn-hdr-green  { background: rgba(34,197,94,.15); border-color: rgba(34,197,94,.45); }
.btn-hdr-green:hover { background: rgba(34,197,94,.28); border-color: #22c55e; }

/* ═══════════════════════════════════════════════════════════════════
   KPI ROW — matches dashboard card style
   ═══════════════════════════════════════════════════════════════════ */
.kpi-row {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
  gap: 14px;
  padding: 20px 24px 0;
}
.kpi-card {
  background: var(--card);
  border-radius: var(--r);
  box-shadow: var(--shadow);
  padding: 18px 16px;
  text-align: center;
  border-top: 3px solid transparent;
  border: 1px solid var(--border);
  border-top: 3px solid transparent;
  transition: transform .15s, box-shadow .15s;
}
.kpi-card:hover { transform: translateY(-2px); box-shadow: var(--shadow-md); }
.kpi-card.kc-primary { border-top-color: var(--primary); }
.kpi-card.kc-blue    { border-top-color: var(--blue); }
.kpi-card.kc-green   { border-top-color: var(--green); }
.kpi-card.kc-amber   { border-top-color: var(--amber); }
.kpi-card.kc-slate   { border-top-color: var(--slate); }
.kpi-val {
  font-size: 32px; font-weight: 900; line-height: 1;
  font-variant-numeric: tabular-nums;
  font-family: var(--font-mono);
}
.kpi-lbl {
  font-size: 11px; font-weight: 700; color: var(--text3);
  margin-top: 5px; text-transform: uppercase; letter-spacing: .07em;
  font-family: var(--font-sans);
}

/* ═══════════════════════════════════════════════════════════════════
   TAB NAVIGATION — primary blue active state
   ═══════════════════════════════════════════════════════════════════ */
.tab-nav {
  display: flex; gap: 0; overflow-x: auto;
  padding: 20px 24px 0; margin-bottom: 0;
  border-bottom: 2px solid var(--border);
  scrollbar-width: none;
}
.tab-nav::-webkit-scrollbar { display: none; }
.tab-btn {
  flex-shrink: 0; background: none; border: none;
  padding: 10px 16px; font-size: 13px; font-weight: 600;
  color: var(--text3); cursor: pointer;
  border-bottom: 3px solid transparent; margin-bottom: -2px;
  transition: color .2s, border-color .2s;
  display: flex; align-items: center; gap: 6px;
  white-space: nowrap; font-family: var(--font-sans);
}
.tab-btn:hover   { color: var(--primary); }
.tab-btn.active  { color: var(--primary-dark); border-bottom-color: var(--primary); }

/* Special "All Slots" tab styling */
.tab-btn.tab-all { font-weight: 800; }
.tab-btn.tab-all.active { color: var(--primary-dark); }

.tab-count {
  background: var(--slate-bg); color: var(--slate);
  font-size: 10px; font-weight: 800;
  padding: 2px 7px; border-radius: 10px;
  font-family: var(--font-mono);
}
.tab-btn.active .tab-count { background: var(--primary-light); color: var(--primary-dark); }

/* ═══════════════════════════════════════════════════════════════════
   TAB CONTENT WRAPPER
   ═══════════════════════════════════════════════════════════════════ */
.tab-body { padding: 16px 24px 40px; }
.tab-pane  { display: none; }
.tab-pane.active { display: block; }

/* ═══════════════════════════════════════════════════════════════════
   ALL-SLOTS TAB — shift group header
   ═══════════════════════════════════════════════════════════════════ */
.shift-group-header {
  display: flex; align-items: center; gap: 10px;
  background: var(--primary-light);
  border: 1px solid var(--border);
  border-left: 4px solid var(--primary);
  border-radius: var(--r);
  padding: 10px 16px;
  margin: 20px 0 12px;
  font-weight: 800;
  font-size: 13px;
  color: var(--primary-dark);
  letter-spacing: .3px;
}
.shift-group-header:first-child { margin-top: 4px; }
.shift-group-header i { color: var(--primary); font-size: 15px; }
.shift-group-badge {
  margin-left: auto;
  background: var(--primary);
  color: #fff;
  font-size: 10px; font-weight: 800;
  padding: 2px 9px; border-radius: 10px;
  font-family: var(--font-mono);
}
.shift-time-range {
  font-weight: 500; color: var(--text3); font-size: 12px; margin-left: 2px;
}

/* ═══════════════════════════════════════════════════════════════════
   AGENT ROW CARDS
   ═══════════════════════════════════════════════════════════════════ */
.agent-card {
  background: var(--card);
  border-radius: var(--r);
  box-shadow: var(--shadow);
  padding: 16px 20px;
  margin-bottom: 10px;
  border: 1px solid var(--border);
  border-left: 5px solid var(--border);
  transition: box-shadow .2s, transform .15s;
}
.agent-card:hover { box-shadow: var(--shadow-md); transform: translateY(-1px); }
.agent-card.ac-active   { border-left-color: var(--green); }
.agent-card.ac-booked   { border-left-color: var(--primary); }
.agent-card.ac-complete { border-left-color: var(--slate); }
.agent-card.ac-cancel   { border-left-color: var(--red); }

.agent-row-inner {
  display: flex; align-items: flex-start;
  justify-content: space-between; gap: 16px; flex-wrap: wrap;
}
.agent-left  { display: flex; gap: 14px; align-items: flex-start; flex: 1; min-width: 200px; }
.agent-right { display: flex; gap: 20px; text-align: center; flex-shrink: 0; }

/* Status dot */
.status-dot {
  width: 12px; height: 12px; border-radius: 50%;
  flex-shrink: 0; margin-top: 5px;
}
.sd-active   { background: var(--green);   box-shadow: 0 0 0 3px rgba(22,163,74,.2); }
.sd-booked   { background: var(--primary); box-shadow: 0 0 0 3px rgba(14,165,233,.2); }
.sd-complete { background: var(--slate); }
.sd-cancel   { background: var(--red); }
.sd-break    { background: var(--amber);   box-shadow: 0 0 0 3px rgba(180,83,9,.2); }

.agent-name  { font-size: 15px; font-weight: 800; margin-bottom: 3px; color: var(--text1); }
.agent-meta  { font-size: 12px; color: var(--text2); display: flex; gap: 10px; flex-wrap: wrap; }
.agent-meta i { color: var(--text3); }

/* Delivery progress bar */
.prog-wrap  { display: flex; align-items: center; gap: 10px; margin-top: 10px; }
.prog-track { flex: 1; height: 7px; border-radius: 4px; background: var(--border); overflow: hidden; min-width: 120px; }
.prog-fill  { height: 100%; border-radius: 4px; background: linear-gradient(90deg, var(--primary), var(--accent)); transition: width .4s; }
.prog-pct   { font-size: 11px; font-weight: 700; color: var(--text2); white-space: nowrap; font-family: var(--font-mono); }

/* Order stat chips */
.stat-chip  { display: flex; flex-direction: column; align-items: center; min-width: 52px; }
.stat-val   { font-size: 18px; font-weight: 900; line-height: 1; font-family: var(--font-mono); }
.stat-lbl   { font-size: 10px; color: var(--text3); margin-top: 3px; text-transform: uppercase; font-weight: 700; letter-spacing: .04em; font-family: var(--font-sans); }

/* Surge pill — amber accent */
.surge-pill {
  display: inline-flex; align-items: center; gap: 4px;
  background: var(--amber-bg); color: var(--amber);
  font-size: 10px; font-weight: 800;
  padding: 2px 8px; border-radius: 8px;
  border: 1px solid #fde68a; vertical-align: middle;
}

/* Status badge */
.status-badge {
  display: inline-block; font-size: 10px; font-weight: 800;
  padding: 3px 10px; border-radius: 20px; vertical-align: middle;
  font-family: var(--font-sans);
}
.sb-active   { background: var(--green-bg);        color: var(--green); }
.sb-booked   { background: var(--primary-light);   color: var(--primary-dark); }
.sb-complete { background: var(--slate-bg);         color: var(--slate); }
.sb-break    { background: var(--amber-bg);         color: var(--amber); }
.sb-cancel   { background: var(--red-bg);           color: var(--red); }

/* Shift type pill shown in All Slots tab */
.shift-pill {
  display: inline-flex; align-items: center; gap: 4px;
  background: var(--accent-light); color: var(--primary-dark);
  font-size: 10px; font-weight: 800;
  padding: 2px 8px; border-radius: 8px;
  border: 1px solid var(--border); vertical-align: middle;
  text-transform: uppercase; letter-spacing: .05em;
  font-family: var(--font-sans);
}

/* ═══════════════════════════════════════════════════════════════════
   SHIFT CONTEXT STRIP (per-shift-tab)
   ═══════════════════════════════════════════════════════════════════ */
.shift-strip {
  font-size: 12px; color: var(--text3); font-weight: 600;
  margin-bottom: 14px;
  display: flex; align-items: center; gap: 6px;
  font-family: var(--font-sans);
}

/* ═══════════════════════════════════════════════════════════════════
   EMPTY STATE
   ═══════════════════════════════════════════════════════════════════ */
.empty-state {
  text-align: center; padding: 48px 24px;
  background: var(--card); border-radius: var(--r);
  box-shadow: var(--shadow); border: 1px solid var(--border);
}
.empty-icon  { font-size: 48px; color: var(--text3); margin-bottom: 14px; }
.empty-title { font-size: 16px; font-weight: 700; color: var(--text2); margin-bottom: 6px; }
.empty-sub   { font-size: 13px; color: var(--text3); }

/* ═══════════════════════════════════════════════════════════════════
   MODAL
   ═══════════════════════════════════════════════════════════════════ */
.modal-overlay {
  display: none; position: fixed; inset: 0;
  background: rgba(14,165,233,.18);
  backdrop-filter: blur(3px);
  z-index: 9999;
  align-items: center; justify-content: center;
  padding: 20px;
}
.modal-overlay.open { display: flex; }
.modal-box {
  background: var(--card); border-radius: 18px;
  padding: 28px; width: 100%; max-width: 420px;
  box-shadow: 0 20px 60px rgba(14,165,233,.2);
  animation: modalIn .25s cubic-bezier(.34,1.56,.64,1);
  border-top: 4px solid var(--primary);
}
@keyframes modalIn { from { opacity:0; transform:scale(.94) translateY(10px); } to { opacity:1; transform:none; } }
.modal-title {
  font-size: 17px; font-weight: 800; margin-bottom: 20px;
  display: flex; align-items: center; gap: 8px;
  color: var(--text1); font-family: var(--font-sans);
}

/* ═══════════════════════════════════════════════════════════════════
   TOAST — matches dashboard .big-toast shadow/radius
   ═══════════════════════════════════════════════════════════════════ */
#toastBox {
  position: fixed; bottom: 24px; left: 50%; transform: translateX(-50%);
  z-index: 99999; display: flex; flex-direction: column-reverse;
  align-items: center; gap: 8px; pointer-events: none;
  width: min(92vw, 420px);
}
.toast {
  background: var(--text1); color: #fff; border-radius: var(--r);
  padding: 12px 22px; font-size: 14px; font-weight: 700;
  box-shadow: var(--shadow-md); width: 100%; text-align: center;
  animation: tIn .28s ease, tOut .3s ease 2.7s forwards;
  font-family: var(--font-sans);
}
.toast.t-success { background: #065f46; }
.toast.t-error   { background: #991b1b; }
@keyframes tIn  { from { opacity:0; transform:translateY(12px); } to { opacity:1; transform:none; } }
@keyframes tOut { to   { opacity:0; } }

/* ═══════════════════════════════════════════════════════════════════
   MOBILE
   ═══════════════════════════════════════════════════════════════════ */
@media (max-width: 640px) {
  .dash-header     { padding: 16px; }
  .kpi-row         { grid-template-columns: 1fr 1fr; padding: 14px 16px 0; }
  .tab-nav         { padding: 14px 16px 0; }
  .tab-body        { padding: 14px 16px 32px; }
  .agent-right     { gap: 12px; }
  .kpi-val         { font-size: 26px; }
  .agent-row-inner { flex-direction: column; }
  .agent-right     { justify-content: space-around; width: 100%; border-top: 1px solid var(--border); padding-top: 12px; margin-top: 4px; }
}
</style>


<!-- ══ HEADER ════════════════════════════════════════════════════════════ -->
<div class="dash-header">
  <div>
    <div class="dash-title">
      <i class="bi bi-grid-3x3-gap-fill" style="font-size:22px;color:rgba(255,255,255,.85);"></i>
      Slot Monitor Dashboard
    </div>
    <div class="dash-subtitle">
      <%= viewDate.format(DateTimeFormatter.ofPattern("EEEE, dd MMMM yyyy")) %>
      &nbsp;·&nbsp; <%= totalAgents %> agent<%= totalAgents != 1 ? "s" : "" %> on duty
    </div>
  </div>
  <div class="dash-controls">
    <input type="date" id="datePicker"
           class="form-control form-control-sm"
           style="max-width:160px;"
           value="<%= viewDate %>"
           onchange="changeDate(this.value)"/>
    <button class="btn-hdr" onclick="location.reload()">
      <i class="bi bi-arrow-clockwise"></i> Refresh
    </button>
    <button class="btn-hdr btn-hdr-amber"
            onclick="document.getElementById('surgeModal').classList.add('open')">
      <i class="bi bi-lightning-fill"></i> Surge
    </button>
    <button class="btn-hdr btn-hdr-green"
            onclick="document.getElementById('addZoneModal').classList.add('open')">
      <i class="bi bi-plus-circle-fill"></i> Add Zone
    </button>
  </div>
</div>

<!-- ══ KPI ROW ════════════════════════════════════════════════════════════ -->
<div class="kpi-row">
  <div class="kpi-card kc-primary">
    <div class="kpi-val" style="color:var(--primary);"><%= totalAgents %></div>
    <div class="kpi-lbl">Agents on Duty</div>
  </div>
  <div class="kpi-card kc-blue">
    <div class="kpi-val" style="color:var(--blue);"><%= totalOrders %></div>
    <div class="kpi-lbl">Orders Assigned</div>
  </div>
  <div class="kpi-card kc-green">
    <div class="kpi-val" style="color:var(--green);"><%= totalDelivered %></div>
    <div class="kpi-lbl">Delivered</div>
  </div>
  <div class="kpi-card kc-amber">
    <div class="kpi-val" style="color:var(--amber);"><%= totalPending %></div>
    <div class="kpi-lbl">Pending / In Transit</div>
  </div>
  <div class="kpi-card kc-slate">
    <div class="kpi-val" style="color:<%= completionRate >= 80 ? "var(--green)" : completionRate >= 50 ? "var(--amber)" : "var(--red)" %>;">
      <%= completionRate %>%
    </div>
    <div class="kpi-lbl">Completion Rate</div>
  </div>
</div>

<!-- ══ TAB NAVIGATION ═════════════════════════════════════════════════════ -->
<nav class="tab-nav" id="tabNav">

  <%-- "All Slots" tab — always first, shows total booked slots count --%>
  <button class="tab-btn tab-all active"
          data-tab="ALL"
          onclick="showTab('ALL', this)">
    <i class="bi bi-calendar2-check"></i>
    All Slots
    <span class="tab-count"><%= totalAgents %></span>
  </button>

  <%-- Individual shift tabs --%>
  <%
  String[]   shiftCodes  = {"MIDNIGHT","EARLY_MORNING","AM","PM","EVENING","FULL_DAY","NIGHT"};
  String[]   shiftIcons  = {"bi-moon-stars","bi-sunrise","bi-sun","bi-sun-fill","bi-moon","bi-calendar2-week","bi-moon-fill"};
  String[]   shiftLabels = {"Midnight","Early Morn","Morning","Afternoon","Evening","Full Day","Night"};
  String[]   shiftTimes  = {"02–06","04–08","06–12","12–18","18–22","06–22","22–02"};

  for (int ti = 0; ti < shiftCodes.length; ti++) {
    String tc  = shiftCodes[ti];
    int    cnt = byType.get(tc).size();
  %>
  <button class="tab-btn"
          data-tab="<%= tc %>"
          onclick="showTab('<%= tc %>', this)">
    <i class="bi <%= shiftIcons[ti] %>"></i>
    <%= shiftLabels[ti] %>
    <span class="tab-count"><%= cnt %></span>
  </button>
  <% } %>

</nav>

<!-- ══ TAB CONTENT ════════════════════════════════════════════════════════ -->
<div class="tab-body">

  <%-- ── ALL SLOTS TAB ─────────────────────────────────────────────────── --%>
  <div id="tab-ALL" class="tab-pane active">

    <% if (slots.isEmpty()) { %>
    <div class="empty-state">
      <div class="empty-icon"><i class="bi bi-calendar2-x"></i></div>
      <div class="empty-title">No bookings for this day</div>
      <div class="empty-sub">No agents have booked any delivery slot for <%= viewDate.format(DateTimeFormatter.ofPattern("dd MMM yyyy")) %></div>
    </div>

    <% } else {
         boolean anyShiftHasSlots = false;
         for (int ti = 0; ti < shiftCodes.length; ti++) {
           String tc        = shiftCodes[ti];
           List<DeliverySlot> tabSlots = byType.get(tc);
           if (tabSlots.isEmpty()) continue;
           anyShiftHasSlots = true;
    %>

    <!-- Shift group header -->
    <div class="shift-group-header">
      <i class="bi <%= shiftIcons[ti] %>"></i>
      <%= shiftLabels[ti] %> Shift
      <span class="shift-time-range">· <%= shiftTimes[ti] %> hrs</span>
      <span class="shift-group-badge"><%= tabSlots.size() %> agent<%= tabSlots.size()!=1?"s":"" %></span>
    </div>

    <%   for (DeliverySlot s : tabSlots) {
           int pct = s.getCompletionPct();
           String cardClass, dotClass, badgeClass;
           if      ("ACTIVE".equals(s.getStatus()))    { cardClass="ac-active";   dotClass="sd-active";   badgeClass="sb-active"; }
           else if ("ON_BREAK".equals(s.getStatus()))  { cardClass="ac-booked";   dotClass="sd-break";    badgeClass="sb-break"; }
           else if ("BOOKED".equals(s.getStatus()))    { cardClass="ac-booked";   dotClass="sd-booked";   badgeClass="sb-booked"; }
           else if ("COMPLETED".equals(s.getStatus())) { cardClass="ac-complete"; dotClass="sd-complete"; badgeClass="sb-complete"; }
           else if ("CANCELLED".equals(s.getStatus())) { cardClass="ac-cancel";   dotClass="sd-cancel";   badgeClass="sb-cancel"; }
           else                                        { cardClass="";            dotClass="sd-booked";   badgeClass="sb-booked"; }
    %>
    <div class="agent-card <%= cardClass %>">
      <div class="agent-row-inner">
        <div class="agent-left">
          <div class="status-dot <%= dotClass %>"></div>
          <div style="flex:1;min-width:0;">
            <div class="agent-name">
              <%= s.getAgentName() %>
              <span class="status-badge <%= badgeClass %>" style="margin-left:6px;"><%= s.getStatus() %></span>
              <span class="shift-pill ms-1"><i class="bi <%= shiftIcons[ti] %>"></i> <%= shiftLabels[ti] %></span>
              <% if (s.isSurge()) { %>
              <span class="surge-pill ms-1"><i class="bi bi-lightning-fill"></i> Surge</span>
              <% } %>
            </div>
            <div class="agent-meta">
              <span><i class="bi bi-geo-alt"></i> <%= s.getZoneName() %></span>
              <% if (s.getAgentPhone() != null && !s.getAgentPhone().isEmpty()) { %>
              <span><i class="bi bi-telephone"></i> <%= s.getAgentPhone() %></span>
              <% } %>
              <span><i class="bi bi-hash"></i> Slot #<%= s.getSlotId() %></span>
            </div>
            <div class="prog-wrap">
              <div class="prog-track">
                <div class="prog-fill" style="width:<%= pct %>%;"></div>
              </div>
              <span class="prog-pct"><%= pct %>% done</span>
            </div>
          </div>
        </div>
        <div class="agent-right">
          <div class="stat-chip">
            <span class="stat-val" style="color:var(--blue);"><%= s.getTotalOrders() %></span>
            <span class="stat-lbl">Assigned</span>
          </div>
          <div class="stat-chip">
            <span class="stat-val" style="color:var(--green);"><%= s.getDeliveredCount() %></span>
            <span class="stat-lbl">Delivered</span>
          </div>
          <div class="stat-chip">
            <span class="stat-val" style="color:var(--primary);"><%= s.getOutForDeliveryCount() %></span>
            <span class="stat-lbl">Out</span>
          </div>
          <div class="stat-chip">
            <span class="stat-val" style="color:var(--slate);"><%= s.getPendingCount() %></span>
            <span class="stat-lbl">Pending</span>
          </div>
        </div>
      </div>
    </div>
    <%   } /* end for each slot in shift */
         } /* end for each shift type */
       } /* end if not empty */ %>

  </div><!-- /tab-ALL -->

  <%-- ── INDIVIDUAL SHIFT TABS ──────────────────────────────────────────── --%>
  <%
  for (int ti = 0; ti < shiftCodes.length; ti++) {
    String tc        = shiftCodes[ti];
    String timeRange = shiftTimes[ti];
    List<DeliverySlot> tabSlots = byType.get(tc);
  %>
  <div id="tab-<%= tc %>" class="tab-pane">

    <div class="shift-strip">
      <i class="bi bi-clock"></i>
      <%= shiftLabels[ti] %> shift &nbsp;·&nbsp; <%= timeRange %> hrs
      &nbsp;·&nbsp; <%= tabSlots.size() %> agent<%= tabSlots.size() != 1 ? "s" : "" %>
    </div>

    <% if (tabSlots.isEmpty()) { %>
    <div class="empty-state">
      <div class="empty-icon"><i class="bi bi-person-lines-fill"></i></div>
      <div class="empty-title">No agents booked for this slot</div>
      <div class="empty-sub">No one has booked a <%= shiftLabels[ti] %> slot for <%= viewDate.format(DateTimeFormatter.ofPattern("dd MMM yyyy")) %></div>
    </div>

    <% } else {
         for (DeliverySlot s : tabSlots) {
           int pct = s.getCompletionPct();
           String cardClass, dotClass, badgeClass;
           if      ("ACTIVE".equals(s.getStatus()))    { cardClass="ac-active";   dotClass="sd-active";   badgeClass="sb-active"; }
           else if ("ON_BREAK".equals(s.getStatus()))  { cardClass="ac-booked";   dotClass="sd-break";    badgeClass="sb-break"; }
           else if ("BOOKED".equals(s.getStatus()))    { cardClass="ac-booked";   dotClass="sd-booked";   badgeClass="sb-booked"; }
           else if ("COMPLETED".equals(s.getStatus())) { cardClass="ac-complete"; dotClass="sd-complete"; badgeClass="sb-complete"; }
           else if ("CANCELLED".equals(s.getStatus())) { cardClass="ac-cancel";   dotClass="sd-cancel";   badgeClass="sb-cancel"; }
           else                                        { cardClass="";            dotClass="sd-booked";   badgeClass="sb-booked"; }
    %>
    <div class="agent-card <%= cardClass %>">
      <div class="agent-row-inner">
        <div class="agent-left">
          <div class="status-dot <%= dotClass %>"></div>
          <div style="flex:1;min-width:0;">
            <div class="agent-name">
              <%= s.getAgentName() %>
              <span class="status-badge <%= badgeClass %>" style="margin-left:6px;">
                <%= s.getStatus() %>
              </span>
              <% if (s.isSurge()) { %>
              <span class="surge-pill ms-1"><i class="bi bi-lightning-fill"></i> Surge</span>
              <% } %>
            </div>
            <div class="agent-meta">
              <span><i class="bi bi-geo-alt"></i> <%= s.getZoneName() %></span>
              <% if (s.getAgentPhone() != null && !s.getAgentPhone().isEmpty()) { %>
              <span><i class="bi bi-telephone"></i> <%= s.getAgentPhone() %></span>
              <% } %>
              <span><i class="bi bi-hash"></i> Slot #<%= s.getSlotId() %></span>
            </div>
            <div class="prog-wrap">
              <div class="prog-track">
                <div class="prog-fill" style="width:<%= pct %>%;"></div>
              </div>
              <span class="prog-pct"><%= pct %>% done</span>
            </div>
          </div>
        </div>
        <div class="agent-right">
          <div class="stat-chip">
            <span class="stat-val" style="color:var(--blue);"><%= s.getTotalOrders() %></span>
            <span class="stat-lbl">Assigned</span>
          </div>
          <div class="stat-chip">
            <span class="stat-val" style="color:var(--green);"><%= s.getDeliveredCount() %></span>
            <span class="stat-lbl">Delivered</span>
          </div>
          <div class="stat-chip">
            <span class="stat-val" style="color:var(--primary);"><%= s.getOutForDeliveryCount() %></span>
            <span class="stat-lbl">Out</span>
          </div>
          <div class="stat-chip">
            <span class="stat-val" style="color:var(--slate);"><%= s.getPendingCount() %></span>
            <span class="stat-lbl">Pending</span>
          </div>
        </div>
      </div>
    </div>
    <%  } /* end for each slot */
       } /* end if not empty */ %>

  </div><!-- /tab-<%= tc %> -->
  <% } /* end for each shift tab */ %>

</div><!-- /tab-body -->


<!-- ══ SURGE MODAL ═════════════════════════════════════════════════════════ -->
<div id="surgeModal" class="modal-overlay"
     onclick="if(event.target===this)this.classList.remove('open')">
  <div class="modal-box">
    <div class="modal-title">
      <i class="bi bi-lightning-fill" style="color:var(--amber);"></i>
      Surge Zone Control
    </div>
    <div class="mb-3">
      <label class="form-label fw-semibold" style="font-size:13px;font-family:var(--font-sans);">Zone</label>
      <select id="surgeZoneId" class="form-select form-select-sm">
        <% if (zones != null) for (DeliveryZone z : zones) { %>
        <option value="<%= z.getZoneId() %>"><%= z.getZoneName() %></option>
        <% } %>
      </select>
    </div>
    <div class="mb-3">
      <label class="form-label fw-semibold" style="font-size:13px;font-family:var(--font-sans);">
        Surge Multiplier <span style="color:var(--text3);font-weight:400;">(e.g. 1.30 = 30% extra)</span>
      </label>
      <input type="number" id="surgeMultiplier" class="form-control form-control-sm"
             value="1.30" min="1.00" max="3.00" step="0.05"/>
    </div>
    <div class="d-flex gap-2 mb-3">
      <button class="btn btn-warning flex-fill fw-bold" onclick="setSurge(true)">
        <i class="bi bi-lightning-fill me-1"></i>Enable Surge
      </button>
      <button class="btn btn-outline-secondary flex-fill" onclick="setSurge(false)">
        Disable Surge
      </button>
    </div>
    <button class="btn btn-sm btn-link p-0" style="color:var(--text3);"
            onclick="document.getElementById('surgeModal').classList.remove('open')">
      Close
    </button>
  </div>
</div>

<!-- ══ ADD ZONE MODAL ═════════════════════════════════════════════════════ -->
<div id="addZoneModal" class="modal-overlay"
     onclick="if(event.target===this)this.classList.remove('open')">
  <div class="modal-box">
    <div class="modal-title">
      <i class="bi bi-geo-alt-fill" style="color:var(--green);"></i>
      Add Delivery Zone
    </div>
    <div class="mb-3">
      <label class="form-label fw-semibold" style="font-size:13px;font-family:var(--font-sans);">Zone Name <span style="color:#ef4444">*</span></label>
      <input type="text" id="newZoneName" class="form-control form-control-sm"
             placeholder="e.g. North Zone, Sector 12…" maxlength="80"/>
    </div>
    <div class="mb-3">
      <label class="form-label fw-semibold" style="font-size:13px;font-family:var(--font-sans);">
        Pincodes <span style="color:var(--text3);font-weight:400;">(comma-separated, optional)</span>
      </label>
      <input type="text" id="newZonePincodes" class="form-control form-control-sm"
             placeholder="e.g. 560001, 560002, 560003"/>
    </div>
    <div class="d-flex gap-2 mb-3">
      <button class="btn btn-success flex-fill fw-bold" onclick="submitAddZone()">
        <i class="bi bi-plus-circle-fill me-1"></i>Add Zone
      </button>
      <button class="btn btn-outline-secondary" onclick="document.getElementById('addZoneModal').classList.remove('open')">
        Cancel
      </button>
    </div>

    <!-- Existing zones list with delete -->
    <div style="border-top:1px solid var(--border);padding-top:12px;margin-top:4px;">
      <div class="fw-bold mb-2" style="font-size:12px;color:var(--text3);text-transform:uppercase;letter-spacing:.07em;font-family:var(--font-sans);">Existing Zones</div>
      <div id="zoneListInModal" style="max-height:200px;overflow-y:auto;">
        <% if (zones != null) for (DeliveryZone z : zones) { %>
        <div class="d-flex align-items-center justify-content-between py-1 px-2 rounded mb-1"
             style="background:var(--slate-bg);font-size:13px;" id="zone-row-<%= z.getZoneId() %>">
          <div>
            <span class="fw-semibold"><%= z.getZoneName() %></span>
            <% if (z.getPincodes() != null && !z.getPincodes().isBlank()) { %>
            <span style="color:var(--text3);font-size:11px;margin-left:6px;"><%= z.getPincodes() %></span>
            <% } %>
          </div>
          <button class="btn btn-sm btn-outline-danger py-0 px-2" style="font-size:11px;"
                  onclick="deleteZone(<%= z.getZoneId() %>, '<%= z.getZoneName().replace("'","\'") %>')">
            <i class="bi bi-trash3"></i>
          </button>
        </div>
        <% } %>
      </div>
    </div>
  </div>
</div>

<!-- ══ TOAST ══════════════════════════════════════════════════════════════ -->
<div id="toastBox"></div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script>
/* ── Context root ─────────────────────────────────────────────────── */
const CTX = '<%= ctx %>';

/* ── Tab switching (handles ALL + shift tabs) ─────────────────────── */
function showTab(type, btn) {
  document.querySelectorAll('.tab-pane').forEach(function(p) { p.classList.remove('active'); });
  document.querySelectorAll('.tab-btn').forEach(function(b)  { b.classList.remove('active'); });
  var pane = document.getElementById('tab-' + type);
  if (pane) pane.classList.add('active');
  if (btn)  btn.classList.add('active');
}

/* ── Date navigation ──────────────────────────────────────────────── */
function changeDate(val) {
  var url = CTX + '/DeliverySlotServlet?action=adminSlots&date=' + val;
  var loader = (typeof window.dashboardLoadFragment === 'function')
    ? window.dashboardLoadFragment
    : (window.parent && typeof window.parent.dashboardLoadFragment === 'function')
      ? window.parent.dashboardLoadFragment
      : null;
  if (loader) {
    loader(url, 'Slot Monitor', null);
  } else {
    location.href = url;
  }
}

/* ── Surge control ────────────────────────────────────────────────── */
function setSurge(enable) {
  var zoneId     = document.getElementById('surgeZoneId').value;
  var multiplier = document.getElementById('surgeMultiplier').value;
  fetch(CTX + '/DeliverySlotServlet', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({ action: 'setSurge', zoneId: zoneId,
                                isSurge: enable, multiplier: multiplier })
  })
  .then(function(r) { return r.json(); })
  .then(function(data) {
    document.getElementById('surgeModal').classList.remove('open');
    showToast(data.success ? data.message : (data.message || 'Operation failed'),
              data.success ? 'success' : 'error');
    if (data.success) setTimeout(function() { location.reload(); }, 1400);
  })
  .catch(function() { showToast('Network error. Please try again.', 'error'); });
}

/* ── Toast ────────────────────────────────────────────────────────── */
function showToast(msg, type) {
  var box = document.getElementById('toastBox');
  var t   = document.createElement('div');
  t.className = 'toast' + (type === 'success' ? ' t-success' : type === 'error' ? ' t-error' : '');
  t.textContent = msg;
  box.appendChild(t);
  setTimeout(function() { if (t.parentNode) t.parentNode.removeChild(t); }, 3200);
}

/* ── Add Zone ─────────────────────────────────────────────────────── */
function submitAddZone() {
  var name = document.getElementById('newZoneName').value.trim();
  var pins = document.getElementById('newZonePincodes').value.trim();
  if (!name) { showToast('Zone name is required.', 'error'); return; }
  fetch(CTX + '/DeliverySlotServlet', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({ action: 'addZone', zoneName: name, pincodes: pins })
  })
  .then(function(r) { return r.json(); })
  .then(function(data) {
    if (data.success) {
      showToast(data.message, 'success');
      document.getElementById('newZoneName').value = '';
      document.getElementById('newZonePincodes').value = '';
      var row = document.createElement('div');
      row.className = 'd-flex align-items-center justify-content-between py-1 px-2 rounded mb-1';
      row.style.cssText = 'background:var(--slate-bg);font-size:13px;';
      row.id = 'zone-row-' + data.id;
      var zName = name.replace(/'/g, "\'");
      row.innerHTML = '<div><span class="fw-semibold">' + name + '</span>'
        + (pins ? '<span style="color:var(--text3);font-size:11px;margin-left:6px;">' + pins + '</span>' : '')
        + '</div>'
        + '<button class="btn btn-sm btn-outline-danger py-0 px-2" style="font-size:11px;" '
        + 'onclick="deleteZone(' + data.id + ',\'' + zName + '\')">'
        + '<i class="bi bi-trash3"></i></button>';
      document.getElementById('zoneListInModal').appendChild(row);
      var opt = document.createElement('option');
      opt.value = data.id;
      opt.textContent = name;
      document.getElementById('surgeZoneId').appendChild(opt);
    } else {
      showToast(data.message || 'Failed to add zone.', 'error');
    }
  })
  .catch(function() { showToast('Network error. Please try again.', 'error'); });
}

function deleteZone(zoneId, zoneName) {
  if (!confirm('Delete zone "' + zoneName + '"? This cannot be undone.')) return;
  fetch(CTX + '/DeliverySlotServlet', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({ action: 'deleteZone', zoneId: zoneId })
  })
  .then(function(r) { return r.json(); })
  .then(function(data) {
    if (data.success) {
      showToast(data.message, 'success');
      var row = document.getElementById('zone-row-' + zoneId);
      if (row) row.remove();
      var opt = document.querySelector('#surgeZoneId option[value="' + zoneId + '"]');
      if (opt) opt.remove();
    } else {
      showToast(data.message || 'Could not delete zone.', 'error');
    }
  })
  .catch(function() { showToast('Network error. Please try again.', 'error'); });
}

</script>
