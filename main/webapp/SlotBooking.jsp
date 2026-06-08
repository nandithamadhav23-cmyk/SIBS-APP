<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.time.LocalTime, java.time.LocalDate, java.time.format.DateTimeFormatter" %>
<%@ page import="com.util.DeliverySlot, com.util.DeliveryZone, com.util.AgentWallet, java.util.*" %>
<%@ page import="com.DAO.DeliverySlotDAO" %>
<%
  /* ── Retrieve all attributes set by DeliverySlotServlet ── */
  DeliverySlot  todaySlot     = (DeliverySlot)  request.getAttribute("todaySlot");
  AgentWallet   agentWallet   = (AgentWallet)   request.getAttribute("agentWallet");
  List<DeliveryZone>    zones      = (List<DeliveryZone>)    request.getAttribute("zones");
  List<DeliverySlot>    todaySlots = (List<DeliverySlot>)    request.getAttribute("todaySlots");
  Set<String>   bookedTypes   = (Set<String>)   request.getAttribute("bookedSlotTypesToday");
  Map<Integer,Long>    startEpochMap = (Map<Integer,Long>) request.getAttribute("slotStartEpochMap");
  Map<Integer,Long>    endEpochMap   = (Map<Integer,Long>) request.getAttribute("slotEndEpochMap");
  Map<Integer,Boolean> canStartMap   = (Map<Integer,Boolean>) request.getAttribute("slotCanStartMap");

  if (todaySlots == null) todaySlots = new ArrayList<>();
  if (bookedTypes == null) bookedTypes = new HashSet<>();
  if (startEpochMap == null) startEpochMap = new HashMap<>();
  if (endEpochMap   == null) endEpochMap   = new HashMap<>();
  if (canStartMap   == null) canStartMap   = new HashMap<>();

  String slotStatus  = (todaySlot != null) ? todaySlot.getStatus()   : "NONE";
  String slotType    = (todaySlot != null) ? todaySlot.getSlotType()  : "";
  int    slotId      = (todaySlot != null) ? todaySlot.getSlotId()    : -1;
  boolean hasSlot    = todaySlot != null;

  // Derive boolean flags from the PRIMARY (highest-priority) slot
  boolean isBooked   = "BOOKED".equals(slotStatus);
  boolean isActive   = "ACTIVE".equals(slotStatus);
  boolean isOnBreak  = "ON_BREAK".equals(slotStatus);
  boolean isInactive = "INACTIVE".equals(slotStatus);
  boolean isComplete = "COMPLETED".equals(slotStatus);
  boolean isCancelled= "CANCELLED".equals(slotStatus);
  boolean isExpired  = "EXPIRED".equals(slotStatus);

  // Is there ANY operational slot today (ACTIVE/ON_BREAK/BOOKED)?
  boolean hasActiveOrBooked = false;
  for (DeliverySlot s : todaySlots) {
    String st = s.getStatus();
    if ("ACTIVE".equals(st)||"ON_BREAK".equals(st)||"BOOKED".equals(st)||"INACTIVE".equals(st)) {
      hasActiveOrBooked = true; break;
    }
  }

  Long   endEpochMs       = (Long) request.getAttribute("portalSlotEndEpochMs");
  Long   startEpochMs     = (Long) request.getAttribute("portalSlotStartEpochMs");
  Long   shiftStartedAtMs = (Long) request.getAttribute("portalShiftStartedAtMs");
  boolean canStartNow     = Boolean.TRUE.equals(request.getAttribute("portalCanStartNow"));
  int    breakSecsLeft    = (request.getAttribute("portalBreakSecsLeft") != null)
                             ? (int) request.getAttribute("portalBreakSecsLeft") : -1;
  int    maxBreakMin      = (request.getAttribute("portalMaxBreak") != null)
                             ? (int) request.getAttribute("portalMaxBreak") : 10;

  String walletBal    = "0";
  String walletMin    = "500";
  boolean canGoOnline = true;
  if (agentWallet != null) {
    walletBal   = String.format("%.0f", agentWallet.getBalance());
    walletMin   = String.format("%.0f", agentWallet.getMinBalance());
    canGoOnline = agentWallet.getBalance().compareTo(agentWallet.getMinBalance()) >= 0;
  }

  /*
   * All 7 slot types — cutoff = START time in minutes since midnight.
   * Once the start time has passed, that card is blocked for today.
   */
  String[] slotCodes        = {"MIDNIGHT","EARLY_MORNING","AM","PM","EVENING","FULL_DAY","NIGHT"};
  String[] slotEmoji        = {"🌙","🌄","🌅","☀️","🌆","📅","🌃"};
  String[] slotDisplayNames = {"Midnight","Early Morning","Morning","Afternoon","Evening","Full Day","Night"};
  String[] slotTimeLine     = {"2 AM–6 AM","4 AM–8 AM","6 AM–12 PM","12 PM–6 PM","6 PM–10 PM","6 AM–10 PM","10 PM–2 AM"};
  int[]    slotStartMin     = {120, 240, 360, 720, 1080, 360, 1320};   // start = booking cutoff
  String popularCode = "AM";

  LocalTime nowTime   = LocalTime.now();
  int nowTotalMin     = nowTime.getHour() * 60 + nowTime.getMinute();
  String today = LocalDate.now().format(DateTimeFormatter.ofPattern("dd MMM yyyy"));
  DateTimeFormatter tfmt = DateTimeFormatter.ofPattern("h:mm a");

  // Helper: display name for a slot type
  Map<String,String> slotLabel = new LinkedHashMap<>();
  for (int i=0;i<slotCodes.length;i++) slotLabel.put(slotCodes[i], slotDisplayNames[i]+" ("+slotTimeLine[i]+")");
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no"/>
<title>My Shifts</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet"/>
<style>
/* ═══════════════════════════════════ TOKENS ═══════════════════════════════ */
:root{
  --brand:#6D28D9; --brand-lt:#EDE9FE; --brand-dk:#4C1D95; --brand-mid:#7C3AED;
  --green:#059669; --green-dk:#047857; --green-bg:#D1FAE5; --green-pale:#ECFDF5;
  --amber:#B45309; --amber-bg:#FEF3C7;
  --red:#DC2626;   --red-dk:#B91C1C;   --red-bg:#FEE2E2; --red-pale:#FFF5F5;
  --blue:#1D4ED8;  --blue-bg:#DBEAFE;
  --slate:#64748B; --slate-bg:#F1F5F9;
  --text1:#0F172A; --text2:#475569; --text3:#94A3B8;
  --bg:#F0F2F8; --card:#FFFFFF; --border:#E2E8F0;
  --r:16px; --r-sm:10px;
  --shadow:0 1px 3px rgba(0,0,0,.06),0 4px 16px rgba(0,0,0,.07);
  --shadow-lg:0 8px 32px rgba(109,40,217,.18);
}
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
html{scroll-behavior:smooth;-webkit-tap-highlight-color:transparent}
body{
  font-family:'Segoe UI',system-ui,-apple-system,sans-serif;
  background:var(--bg); color:var(--text1);
  min-height:100vh; padding-bottom:120px;
  -webkit-font-smoothing:antialiased;
}

/* ══ HERO ══════════════════════════════════════════════════════════════════ */
.hero{
  background:linear-gradient(140deg,#4C1D95 0%,#6D28D9 50%,#7C3AED 100%);
  padding:28px 16px 64px; text-align:center; position:relative; overflow:hidden;
}
.hero::before{
  content:''; position:absolute; inset:0;
  background:radial-gradient(ellipse at 75% 15%,rgba(255,255,255,.12) 0%,transparent 55%),
             radial-gradient(ellipse at 20% 85%,rgba(255,255,255,.07) 0%,transparent 45%);
}
.hero::after{
  content:''; position:absolute; bottom:-1px; left:0; right:0;
  height:44px; background:var(--bg);
  clip-path:ellipse(55% 55% at 50% 100%);
}
.hero-date{font-size:11px;font-weight:700;color:rgba(255,255,255,.6);letter-spacing:.1em;text-transform:uppercase;margin-bottom:6px;position:relative;z-index:1}
.hero-title{font-size:26px;font-weight:900;color:#fff;line-height:1.2;margin-bottom:5px;position:relative;z-index:1}
.hero-sub{font-size:14px;color:rgba(255,255,255,.75);position:relative;z-index:1}

/* ══ LAYOUT ════════════════════════════════════════════════════════════════ */
.wrap{max-width:540px;margin:0 auto;padding:0 14px}
.section{margin-top:18px}
.section-label{font-size:11px;font-weight:700;letter-spacing:.09em;text-transform:uppercase;color:var(--text3);margin-bottom:10px}
.card{background:var(--card);border-radius:var(--r);box-shadow:var(--shadow);padding:18px}

/* ══ STATUS FLOAT ══════════════════════════════════════════════════════════ */
.status-float{
  margin:-38px 0 0; border-radius:var(--r);
  background:var(--card); box-shadow:var(--shadow-lg);
  padding:16px 18px; display:flex; align-items:center; gap:14px;
  border-left:5px solid var(--brand); position:relative; z-index:10;
}
.sf-active  {border-left-color:var(--green)}
.sf-booked  {border-left-color:var(--blue)}
.sf-break   {border-left-color:var(--amber)}
.sf-done    {border-left-color:var(--slate)}
.sf-warn    {border-left-color:var(--red)}

.si{width:50px;height:50px;border-radius:13px;display:flex;align-items:center;justify-content:center;font-size:24px;flex-shrink:0}
.si-green{background:var(--green-bg);color:var(--green)}
.si-blue {background:var(--blue-bg); color:var(--blue)}
.si-amber{background:var(--amber-bg);color:var(--amber)}
.si-red  {background:var(--red-bg);  color:var(--red)}
.si-slate{background:var(--slate-bg);color:var(--slate)}
.si-brand{background:var(--brand-lt);color:var(--brand)}

.sb{flex:1;min-width:0}
.sb-big {font-size:16px;font-weight:800;margin-bottom:3px;line-height:1.2}
.sb-desc{font-size:12px;color:var(--text2);line-height:1.4}

/* ══ SLOT TIMELINE (multi-slot) ════════════════════════════════════════════ */
.slot-timeline{display:flex;flex-direction:column;gap:12px}

.slot-item{
  background:var(--card); border-radius:var(--r); box-shadow:var(--shadow);
  border-left:4px solid var(--border); overflow:hidden;
  transition:box-shadow .2s;
}
.slot-item.si-status-ACTIVE   {border-left-color:var(--green)}
.slot-item.si-status-ON_BREAK {border-left-color:var(--amber)}
.slot-item.si-status-BOOKED   {border-left-color:var(--blue)}
.slot-item.si-status-COMPLETED{border-left-color:var(--slate)}
.slot-item.si-status-CANCELLED{border-left-color:var(--red)}
.slot-item.si-status-EXPIRED  {border-left-color:var(--border)}
.slot-item.si-status-INACTIVE {border-left-color:var(--red)}

.slot-item-head{
  display:flex; align-items:center; gap:12px;
  padding:14px 16px 10px;
}
.slot-type-icon{font-size:26px;flex-shrink:0;line-height:1}
.slot-head-info{flex:1;min-width:0}
.slot-head-name{font-size:15px;font-weight:800;color:var(--text1)}
.slot-head-time{font-size:12px;color:var(--text3);margin-top:2px}
.slot-status-pill{
  padding:4px 10px; border-radius:20px; font-size:11px; font-weight:800;
  letter-spacing:.03em; white-space:nowrap; flex-shrink:0;
}
.pill-ACTIVE   {background:var(--green-bg);color:var(--green)}
.pill-ON_BREAK {background:var(--amber-bg);color:var(--amber)}
.pill-BOOKED   {background:var(--blue-bg); color:var(--blue)}
.pill-COMPLETED{background:var(--slate-bg);color:var(--slate)}
.pill-CANCELLED{background:var(--red-bg);  color:var(--red)}
.pill-EXPIRED  {background:var(--slate-bg);color:var(--text3)}
.pill-INACTIVE {background:var(--red-bg);  color:var(--red)}

/* Order count strip */
.order-strip{
  display:flex; gap:0; border-top:1px solid var(--border);
  margin:0 16px; border-radius:8px 8px 0 0; overflow:hidden;
}
.os-block{
  flex:1; text-align:center; padding:8px 4px;
  background:var(--slate-bg); border-right:1px solid var(--border);
}
.os-block:last-child{border-right:none}
.os-num {font-size:18px;font-weight:900;color:var(--text1);line-height:1}
.os-lbl {font-size:10px;color:var(--text3);font-weight:600;text-transform:uppercase;margin-top:2px}
.os-block.os-pending  .os-num{color:var(--blue)}
.os-block.os-active   .os-num{color:var(--amber)}
.os-block.os-delivered.os-num{color:var(--green)}

/* Slot controls */
.slot-controls{padding:10px 14px 14px;display:flex;flex-wrap:wrap;gap:8px}

/* ══ TIMERS ════════════════════════════════════════════════════════════════ */
.timer-row{display:flex;gap:0;border-top:1px solid var(--border);margin:0 16px;padding:12px 0}
.timer-col{flex:1;text-align:center;padding:0 8px}
.timer-col+.timer-col{border-left:1px solid var(--border)}
.timer-lbl{font-size:10px;font-weight:700;color:var(--text3);text-transform:uppercase;letter-spacing:.07em;margin-bottom:6px}
.timer-val{font-size:28px;font-weight:900;font-variant-numeric:tabular-nums;line-height:1;letter-spacing:-1px;color:var(--brand)}
.tv-green{color:var(--green)} .tv-red{color:var(--red)}

/* Break bar */
.break-bar-wrap{padding:0 16px 14px}
.break-bar-head{display:flex;justify-content:space-between;align-items:center;margin-bottom:8px}
.break-bar-lbl{font-size:13px;font-weight:800;color:var(--amber)}
.break-bar-time{font-size:18px;font-weight:900;color:var(--amber);font-variant-numeric:tabular-nums}
.break-track{height:9px;border-radius:5px;background:rgba(180,83,9,.12);overflow:hidden}
.break-fill{height:100%;border-radius:5px;background:linear-gradient(90deg,var(--amber),#F59E0B);transition:width 1s linear}
.break-note{font-size:11px;color:#92400E;margin-top:6px}

/* Countdown blocks (booked countdown) */
.cd-row{display:flex;justify-content:center;gap:10px;margin:8px 0 12px}
.cd-block{text-align:center}
.cd-num{
  width:52px;height:52px;border-radius:11px;
  background:var(--brand);color:#fff;
  font-size:24px;font-weight:900;
  display:flex;align-items:center;justify-content:center;
  font-variant-numeric:tabular-nums;
}
.cd-sep{font-size:28px;font-weight:900;color:var(--text3);padding-top:10px}
.cd-lbl{font-size:9px;font-weight:600;color:var(--text3);margin-top:3px;text-transform:uppercase}

/* ══ BUTTONS ═══════════════════════════════════════════════════════════════ */
.btn{
  display:inline-flex;align-items:center;justify-content:center;gap:7px;
  padding:11px 16px; border-radius:12px; border:none;
  font-size:14px;font-weight:700; cursor:pointer; line-height:1.2;
  transition:transform .15s,box-shadow .15s,background .15s;
  min-height:44px; white-space:nowrap; flex:1;
}
.btn:active{transform:scale(.97)}
.btn:disabled,.btn[disabled]{opacity:.4;cursor:not-allowed;pointer-events:none}
.btn-primary{background:var(--brand);    color:#fff;box-shadow:0 4px 14px rgba(109,40,217,.28)}
.btn-primary:hover{background:var(--brand-dk)}
.btn-success{background:var(--green);    color:#fff;box-shadow:0 4px 12px rgba(5,150,105,.25)}
.btn-success:hover{background:var(--green-dk)}
.btn-danger {background:var(--red);      color:#fff;box-shadow:0 4px 12px rgba(220,38,38,.2)}
.btn-danger:hover{background:var(--red-dk)}
.btn-amber  {background:var(--amber);    color:#fff}
.btn-outline{background:transparent;color:var(--brand);border:2px solid var(--brand-lt)}
.btn-outline:hover{background:var(--brand-lt)}
.btn-ghost  {background:var(--slate-bg);color:var(--text2);border:1px solid var(--border)}
.btn-full   {width:100%;flex:none}
.btn-big    {padding:14px 18px;font-size:16px;border-radius:14px;min-height:52px}
.btn-sm     {padding:8px 14px;font-size:13px;min-height:36px;border-radius:9px;flex:none}

.btn-stack  {display:flex;flex-direction:column;align-items:flex-start}
.btn-main   {font-size:14px;font-weight:700}
.btn-hint   {font-size:11px;font-weight:400;opacity:.8;margin-top:1px}

/* ══ SLOT PICKER ═══════════════════════════════════════════════════════════ */
.slot-grid{display:grid;grid-template-columns:1fr 1fr;gap:10px}
.slot-card{
  background:var(--card);border-radius:var(--r);
  border:2px solid var(--border);padding:14px 10px;
  text-align:center;cursor:pointer;position:relative;
  transition:border-color .2s,transform .15s,box-shadow .2s;
  min-height:105px;
}
.slot-card:hover:not(.slot-disabled):not(.slot-taken){
  border-color:var(--brand);transform:translateY(-2px);box-shadow:var(--shadow);
}
.slot-card.slot-selected{
  border-color:var(--brand);background:var(--brand-lt);
  box-shadow:0 0 0 3px rgba(109,40,217,.15);
}
.slot-card.slot-disabled{
  opacity:1;background:#F8FAFC;border-color:var(--border);
  cursor:not-allowed;pointer-events:none;
}
.slot-card.slot-disabled .slot-emoji,.slot-card.slot-disabled .slot-name{opacity:.3;filter:grayscale(1)}
.slot-card.slot-disabled .slot-time{opacity:.3}

/* Already-booked slot type */
.slot-card.slot-taken{
  background:#F0FDF4;border-color:#6EE7B7;cursor:not-allowed;pointer-events:none;
}
.slot-card.slot-taken .slot-emoji,.slot-card.slot-taken .slot-name,.slot-card.slot-taken .slot-time{opacity:.55}
.slot-taken-lbl{
  font-size:9px;font-weight:800;color:var(--green);
  background:var(--green-bg);border-radius:5px;padding:2px 6px;
  margin-top:5px;display:inline-block;
}
.slot-expired-lbl{
  font-size:9px;font-weight:800;color:var(--slate);
  background:var(--slate-bg);border-radius:5px;padding:2px 6px;
  margin-top:5px;display:inline-block;
}
.slot-badge{
  position:absolute;top:-8px;right:8px;
  background:var(--green);color:#fff;
  font-size:9px;font-weight:800;padding:2px 7px;
  border-radius:20px;letter-spacing:.05em;
}
.slot-badge.nb{background:var(--brand-mid)}
.slot-emoji{font-size:26px;margin-bottom:5px;display:block;line-height:1.2}
.slot-name {font-size:12px;font-weight:800;color:var(--text1);margin-bottom:2px}
.slot-time {font-size:10px;color:var(--text3);line-height:1.3}

/* ══ DATE CHIPS ════════════════════════════════════════════════════════════ */
.date-row{display:flex;gap:8px;overflow-x:auto;padding-bottom:4px;scrollbar-width:none}
.date-row::-webkit-scrollbar{display:none}
.date-chip{
  flex-shrink:0;padding:8px 16px;border-radius:20px;
  background:var(--card);border:2px solid var(--border);
  font-size:13px;font-weight:600;cursor:pointer;white-space:nowrap;transition:all .2s;
}
.date-chip:hover{border-color:var(--brand)}
.date-chip.chip-sel{background:var(--brand);color:#fff;border-color:var(--brand)}

/* ══ ZONE SELECT ═══════════════════════════════════════════════════════════ */
.zone-select{
  width:100%;padding:13px 16px;border:2px solid var(--border);border-radius:var(--r);
  font-size:15px;color:var(--text1);background:var(--card);
  -webkit-appearance:none;appearance:none;
  background-image:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='20' height='20' viewBox='0 0 24 24'%3E%3Cpath fill='%2394A3B8' d='M7 10l5 5 5-5z'/%3E%3C/svg%3E");
  background-repeat:no-repeat;background-position:right 14px center;padding-right:44px;
}
.zone-select:focus{border-color:var(--brand);outline:none;box-shadow:0 0 0 3px rgba(109,40,217,.15)}

/* ══ INFO / WARN ROWS ══════════════════════════════════════════════════════ */
.info-row,.warn-row{
  display:flex;align-items:flex-start;gap:9px;
  border-radius:var(--r-sm);padding:10px 13px;margin-top:10px;font-size:12px;line-height:1.45;
}
.info-row{background:var(--blue-bg);color:#1E40AF}
.warn-row{background:var(--amber-bg);color:#92400E}
.info-row i,.warn-row i{font-size:15px;flex-shrink:0;margin-top:1px}

/* ══ WALLET STRIP ══════════════════════════════════════════════════════════ */
.wallet-strip{display:flex;align-items:center;justify-content:space-between;gap:12px}
.ws-label{font-size:11px;color:var(--text3);margin-bottom:2px;font-weight:600}
.ws-val  {font-size:20px;font-weight:900;color:var(--text1)}
.ws-badge{padding:6px 14px;border-radius:20px;font-size:12px;font-weight:700;display:inline-flex;align-items:center;gap:5px}
.ws-ok   {background:var(--green-bg);color:var(--green)}
.ws-warn {background:var(--red-bg);  color:var(--red)}

/* ══ CANCEL SECTION ════════════════════════════════════════════════════════ */
.cancel-section{
  background:#FAFAFA;border:1px solid var(--border);
  border-radius:var(--r);padding:14px 15px;margin-top:10px;
}
.cancel-section-title{font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:.06em;color:var(--text3);margin-bottom:10px}
.cancel-no-pen{
  display:flex;align-items:center;gap:8px;
  background:var(--green-bg);border-radius:var(--r-sm);
  padding:7px 11px;margin-bottom:10px;font-size:12px;color:var(--green);
}
.cancel-no-pen i{font-size:14px;flex-shrink:0}
.cancel-select,.cancel-textarea{
  width:100%;padding:9px 12px;border:1px solid var(--border);
  border-radius:var(--r-sm);font-size:13px;color:var(--text1);
  background:var(--card);outline:none;transition:border-color .15s;
}
.cancel-select:focus,.cancel-textarea:focus{border-color:var(--brand)}
.cancel-textarea{resize:none;margin-top:8px}
.cancel-btns{display:flex;gap:8px;margin-top:10px}
.cancel-btns .btn{flex:1;font-size:13px;padding:10px 12px;min-height:40px}

/* ══ COMPLETED / OFFLINE PANELS ════════════════════════════════════════════ */
.done-card{
  background:linear-gradient(135deg,var(--green-bg) 0%,#A7F3D0 100%);
  border-radius:var(--r);padding:24px;text-align:center;
}
.done-big   {font-size:48px;margin-bottom:8px}
.done-title {font-size:20px;font-weight:900;color:var(--green);margin-bottom:5px}
.done-sub   {font-size:13px;color:#065F46;line-height:1.55}

.offline-panel{border-radius:var(--r);padding:16px;display:flex;align-items:flex-start;gap:12px}
.op-amber{background:var(--amber-bg)}
.op-red  {background:var(--red-bg)}
.op-blue {background:var(--blue-bg)}
.offline-icon{font-size:26px;flex-shrink:0;line-height:1;margin-top:2px}
.offline-title{font-size:14px;font-weight:800;margin-bottom:4px}
.ot-amber{color:var(--amber)} .ot-red{color:var(--red)} .ot-blue{color:var(--blue)}
.offline-body{font-size:12px;line-height:1.5}
.ob-amber{color:#92400E} .ob-red{color:#7F1D1D} .ob-blue{color:#1E40AF}

/* ══ BOOK FOOTER ═══════════════════════════════════════════════════════════ */
.book-footer{
  position:fixed;bottom:0;left:0;right:0;
  background:rgba(255,255,255,.97);backdrop-filter:blur(14px);
  border-top:1px solid var(--border);
  padding:10px 16px calc(10px + env(safe-area-inset-bottom));
  z-index:100;
}
@media (min-width:540px){
  .book-footer{max-width:540px;left:50%;transform:translateX(-50%)}
}

/* ══ TOAST ══════════════════════════════════════════════════════════════════ */
#toastBox{
  position:fixed;bottom:86px;left:50%;transform:translateX(-50%);
  z-index:9999;display:flex;flex-direction:column-reverse;align-items:center;gap:7px;
  pointer-events:none;width:min(92vw,420px);
}
.toast{
  background:#1E293B;color:#fff;border-radius:12px;
  padding:11px 20px;font-size:13px;font-weight:600;
  box-shadow:0 8px 28px rgba(0,0,0,.22);width:100%;text-align:center;
  animation:tIn .27s cubic-bezier(.34,1.56,.64,1),tOut .3s ease 2.7s forwards;
}
.toast.t-ok {background:#065F46}
.toast.t-err{background:#991B1B}
.toast.t-wrn{background:#92400E}
@keyframes tIn {from{opacity:0;transform:translateY(12px) scale(.96)}to{opacity:1;transform:none}}
@keyframes tOut{to{opacity:0;transform:translateY(8px)}}

/* ══ PULSE ══════════════════════════════════════════════════════════════════ */
@keyframes pulse{
  0%,100%{box-shadow:0 0 0 0 rgba(5,150,105,.4)}
  50%     {box-shadow:0 0 0 10px rgba(5,150,105,0)}
}
.pulse{animation:pulse 2s infinite}

/* ══ RESPONSIVE ════════════════════════════════════════════════════════════ */
@media(min-width:540px){
  .hero{padding:36px 24px 72px}
  .hero-title{font-size:30px}
  .wrap,.status-float{max-width:540px;margin-left:auto;margin-right:auto}
  .status-float{margin-top:-40px}
  #toastBox{bottom:96px}
}
@media(max-width:360px){
  .slot-grid{grid-template-columns:1fr}
  .cancel-btns{flex-direction:column}
  .cd-num{width:46px;height:46px;font-size:20px}
}
</style>
</head>
<body>

<!-- ══ HERO ═══════════════════════════════════════════════════════════════ -->
<div class="hero">
  <div class="hero-date">📅 <%= today %></div>
  <div class="hero-title">
    <% if (isActive)        { %>🟢 You're Working!
    <% } else if (isOnBreak){ %>☕ On Break
    <% } else if (isBooked) { %>📋 Shift Booked
    <% } else if (isComplete){ %>🏁 Shift Done
    <% } else if (isCancelled){ %>❌ Slot Cancelled
    <% } else if (isExpired) { %>⏰ Slot Expired
    <% } else               { %>Pick Your Shift<% } %>
  </div>
  <div class="hero-sub">
    <% if (isActive)        { %>Keep delivering — your earnings are growing!
    <% } else if (isOnBreak){ %>Rest up — break timer is running
    <% } else if (isBooked) { %>Slot confirmed. Start when your shift begins.
    <% } else if (isComplete){ %>Great work! Earnings are in your wallet.
    <% } else if (isCancelled){ %>Slot cancelled. Book a new one below.
    <% } else if (isExpired) { %>Slot expired. Book a new one below.
    <% } else               { %>Choose a shift and start earning<% } %>
  </div>
</div>

<div class="wrap">

<!-- ══ STATUS FLOAT ══════════════════════════════════════════════════════ -->
<div class="status-float
  <%= isActive?"sf-active":isOnBreak?"sf-break":isBooked?"sf-booked":
      (isComplete||isExpired)?"sf-done":(isInactive||isCancelled)?"sf-warn":"" %>">
  <div class="si
    <%= isActive?"si-green":isOnBreak?"si-amber":isBooked?"si-blue":
        isComplete?"si-slate":isInactive?"si-red":isCancelled?"si-red":isExpired?"si-slate":"si-brand" %>">
    <i class="bi <%=
      isActive?"bi-bicycle":isOnBreak?"bi-cup-hot":isBooked?"bi-calendar-check":
      isComplete?"bi-patch-check-fill":isInactive?"bi-slash-circle":
      isCancelled?"bi-x-circle-fill":isExpired?"bi-clock-history":"bi-calendar-plus" %>"></i>
  </div>
  <div class="sb">
    <div class="sb-big"><%=
      isActive?"Delivering Now":isOnBreak?"On Break":isBooked?"Shift Booked":
      isComplete?"Shift Complete!":isInactive?"You're Offline":
      isCancelled?"Slot Cancelled":isExpired?"Slot Expired":"No Shift Today" %></div>
    <div class="sb-desc">
      <% if (isActive||isOnBreak||isBooked) {
           String lbl = slotLabel.containsKey(slotType)?slotLabel.get(slotType):slotType;
           out.print("Slot: "+lbl+" · #"+slotId);
         } else if (isComplete)  { out.print("Earnings credited. Book next slot below."); }
         else if (isInactive)    { out.print("Set offline. Top up wallet or contact supervisor."); }
         else if (isCancelled)   { out.print("Book a new slot below to start earning."); }
         else if (isExpired)     { out.print("Slot expired. Book a new slot below."); }
         else                    { out.print("Book a shift below to go online."); } %>
    </div>
  </div>
  <% if (todaySlots.size() > 1) { %>
  <div style="flex-shrink:0;background:var(--brand-lt);color:var(--brand);padding:5px 10px;border-radius:20px;font-size:12px;font-weight:800;">
    <%= todaySlots.size() %> slots
  </div>
  <% } %>
</div>

<!-- ══ TODAY'S SLOTS TIMELINE ════════════════════════════════════════════ -->
<% if (!todaySlots.isEmpty()) { %>
<div class="section">
  <div class="section-label">📋 Today's Shift<%= todaySlots.size()>1?"s":"" %></div>
  <div class="slot-timeline">

  <% for (DeliverySlot s : todaySlots) {
    String sStatus = s.getStatus();
    String sType   = s.getSlotType();
    int    sId     = s.getSlotId();
    boolean sBooked    = "BOOKED".equals(sStatus);
    boolean sActive    = "ACTIVE".equals(sStatus);
    boolean sOnBreak   = "ON_BREAK".equals(sStatus);
    boolean sCompleted = "COMPLETED".equals(sStatus);
    boolean sCancelled = "CANCELLED".equals(sStatus);
    boolean sExpired   = "EXPIRED".equals(sStatus);
    boolean sInactive  = "INACTIVE".equals(sStatus);

    // Find display info
    String sEmoji="📅", sName=sType, sTime="";
    for (int i=0;i<slotCodes.length;i++) {
      if (slotCodes[i].equals(sType)) { sEmoji=slotEmoji[i]; sName=slotDisplayNames[i]; sTime=slotTimeLine[i]; break; }
    }

    // Pill label
    String pillLabel = sActive?"● Active":sOnBreak?"☕ Break":sBooked?"⏳ Booked":
                       sCompleted?"✓ Done":sCancelled?"✕ Cancelled":sExpired?"⏰ Expired":"Offline";

    int pending   = s.getPendingCount();
    int active    = s.getActiveCount();   // out for delivery / picked up
    int delivered = s.getDeliveredCount();
    int total     = pending + active + delivered;

    Long sStartMs = startEpochMap.get(sId);
    Long sEndMs   = endEpochMap.get(sId);
    Boolean sCanStart = canStartMap.get(sId);

    // Break secs for on-break slot
    int sBreakSecs = (sOnBreak && s.getSlotId() == slotId) ? breakSecsLeft : -1;
  %>
 
<div class="slot-item si-status-<%= sStatus %>" data-slot-id="<%= sId %>">

    <!-- Head row -->
    <div class="slot-item-head">
      <div class="slot-type-icon"><%= sEmoji %></div>
      <div class="slot-head-info">
        <div class="slot-head-name"><%= sName %> Shift</div>
        <div class="slot-head-time"><i class="bi bi-clock" style="font-size:11px"></i> <%= sTime %> &nbsp;·&nbsp; Slot #<%= sId %></div>
      </div>
      <div class="slot-status-pill pill-<%= sStatus %>"><%= pillLabel %></div>
    </div>

    <!-- Order count strip (always show) -->
    <div class="order-strip">
      <div class="os-block os-pending">
        <div class="os-num"><%= pending %></div>
        <div class="os-lbl">Pending</div>
      </div>
      <div class="os-block os-active">
        <div class="os-num"><%= active %></div>
        <div class="os-lbl">In Transit</div>
      </div>
      <div class="os-block os-delivered">
        <div class="os-num"><%= delivered %></div>
        <div class="os-lbl">Delivered</div>
      </div>
      <div class="os-block">
        <div class="os-num"><%= s.getMaxOrders() %></div>
        <div class="os-lbl">Capacity</div>
      </div>
    </div>

    <!-- BOOKED: countdown + start/cancel controls -->
    <% if (sBooked && sStartMs != null) { %>
    <div style="padding:14px 16px 0;text-align:center">
      <div style="font-size:12px;color:var(--text3);margin-bottom:6px">Shift starts at
        <strong id="startTimeFmt-<%= sId %>">—</strong></div>
      <div class="cd-row" id="cdWrap-<%= sId %>">
        <div class="cd-block"><div class="cd-num" id="cdh-<%= sId %>">--</div><div class="cd-lbl">Hrs</div></div>
        <div class="cd-sep">:</div>
        <div class="cd-block"><div class="cd-num" id="cdm-<%= sId %>">--</div><div class="cd-lbl">Min</div></div>
        <div class="cd-sep">:</div>
        <div class="cd-block"><div class="cd-num" id="cds-<%= sId %>">--</div><div class="cd-lbl">Sec</div></div>
      </div>
      <div style="font-size:11px;color:var(--text3);margin-top:6px;">
        Slot expires 1 hr before shift end &nbsp;·&nbsp; <strong id="expireTimeFmt-<%= sId %>">...</strong>
      </div>
    </div>
    <div class="slot-controls">
      <% if (Boolean.TRUE.equals(sCanStart)) { %>
      <button class="btn btn-success pulse" onclick="doStartShift(<%= sId %>)">
        <i class="bi bi-play-circle-fill"></i>
        <span class="btn-stack"><span class="btn-main">Start Shift</span><span class="btn-hint">Go online now</span></span>
      </button>
      <% } else { %>
      <button class="btn btn-ghost" disabled>
        <i class="bi bi-clock"></i>
        <span class="btn-stack"><span class="btn-main">Not Yet</span><span class="btn-hint">15 min before start</span></span>
      </button>
      <% } %>
      <button class="btn btn-ghost btn-sm" style="flex:none" onclick="showCancelSection(<%= sId %>)">
        <i class="bi bi-x-circle"></i> Cancel
      </button>
    </div>
    <!-- Cancel section for this booked slot -->
    <div id="cancelSection-<%= sId %>" style="display:none;padding:0 14px 14px">
      <div class="cancel-section">
        <div class="cancel-section-title">Cancel This Slot</div>
        <div class="cancel-no-pen"><i class="bi bi-shield-check"></i><span><strong>No penalty</strong> will be applied.</span></div>
        <select class="cancel-select" id="cancelReason-<%= sId %>">
          <option value="">— Select a reason —</option>
          <option value="personal_emergency">Personal Emergency</option>
          <option value="vehicle_breakdown">Vehicle Breakdown</option>
          <option value="health_issue">Health Issue</option>
          <option value="family_reason">Family Reason</option>
          <option value="weather">Extreme Weather</option>
          <option value="other">Other</option>
        </select>
        <textarea class="cancel-textarea" id="cancelNote-<%= sId %>" rows="2" placeholder="Additional notes (optional)…"></textarea>
        <div class="cancel-btns">
          <button class="btn btn-ghost" onclick="hideCancelSection(<%= sId %>)"><i class="bi bi-x"></i> Never Mind</button>
          <button class="btn btn-danger" onclick="confirmCancel(<%= sId %>)"><i class="bi bi-trash3"></i> Confirm Cancel</button>
        </div>
      </div>
    </div>
    <% } %>

    <!-- ACTIVE: working timer + break/end controls -->
    <% if (sActive) { %>
    <div class="timer-row">
      <div class="timer-col">
        <div class="timer-lbl">⏰ Working Time</div>
        <div class="timer-val tv-green" id="workTimer-<%= sId %>">0:00</div>
      </div>
      <div class="timer-col">
        <div class="timer-lbl">🏁 Ends In</div>
        <div class="timer-val" id="endTimer-<%= sId %>">—</div>
      </div>
    </div>
    <div class="slot-controls">
      <button class="btn btn-amber" onclick="doStartBreak(<%= sId %>)">
        <span class="btn-icon">☕</span>
        <span class="btn-stack"><span class="btn-main">Take Break</span><span class="btn-hint">Max <%= maxBreakMin %> min</span></span>
      </button>
      <button class="btn btn-danger" onclick="confirmEndShift(<%= sId %>)">
        <span class="btn-icon">🏁</span>
        <span class="btn-stack"><span class="btn-main">End Shift</span><span class="btn-hint">Credits earnings</span></span>
      </button>
    </div>
    <% } %>

    <!-- ON_BREAK: resume + break countdown -->
    <% if (sOnBreak) { %>
    <div class="timer-row">
      <div class="timer-col">
        <div class="timer-lbl">⏰ Working Time</div>
        <div class="timer-val tv-green" id="workTimer-<%= sId %>">—</div>
      </div>
      <div class="timer-col">
        <div class="timer-lbl">🏁 Ends In</div>
        <div class="timer-val" id="endTimer-<%= sId %>">—</div>
      </div>
    </div>
    <% if (sBreakSecs > 0) { %>
    <div class="break-bar-wrap">
      <div class="break-bar-head">
        <span class="break-bar-lbl">☕ Break Remaining</span>
        <span class="break-bar-time" id="breakCountdown-<%= sId %>">
          <%= String.format("%d:%02d", sBreakSecs/60, sBreakSecs%60) %>
        </span>
      </div>
      <div class="break-track">
        <div class="break-fill" id="breakFill-<%= sId %>"
             style="width:<%= Math.min(100,(int)((maxBreakMin*60-sBreakSecs)*100.0/(maxBreakMin*60))) %>%"></div>
      </div>
      <div class="break-note">⚠️ You'll be set OFFLINE after <%= maxBreakMin %> min break</div>
    </div>
    <% } %>
    <div class="slot-controls">
      <button class="btn btn-success pulse" style="width:100%;flex:none" onclick="doEndBreak(<%= sId %>)">
        <i class="bi bi-bicycle"></i>
        <span class="btn-stack"><span class="btn-main">Resume Work</span><span class="btn-hint">End break now</span></span>
      </button>
    </div>
    <% } %>

    <!-- INACTIVE: offline notice -->
    <% if (sInactive) { %>
    <div style="padding:0 16px 14px">
      <div class="warn-row">
        <i class="bi bi-exclamation-triangle-fill"></i>
        <span>You were set offline (break exceeded or low wallet). Top up to resume, or end your shift.</span>
      </div>
      <div class="slot-controls" style="margin-top:8px">
        <button class="btn btn-danger" onclick="confirmEndShift(<%= sId %>)">
          <i class="bi bi-stop-circle"></i> End Shift
        </button>
      </div>
    </div>
    <% } %>

    <!-- COMPLETED -->
    <% if (sCompleted) { %>
    <div style="padding:0 16px 14px">
      <div style="display:flex;align-items:center;gap:10px;background:var(--green-pale);border-radius:10px;padding:10px 14px;font-size:13px;color:#065F46;font-weight:600">
        <i class="bi bi-check-circle-fill" style="font-size:18px;color:var(--green);flex-shrink:0"></i>
        Shift complete! Earnings credited to your wallet.
      </div>
    </div>
    <% } %>

    <!-- CANCELLED -->
    <% if (sCancelled) { %>
    <div style="padding:0 16px 14px">
      <div style="display:flex;align-items:center;gap:10px;background:var(--red-pale);border-radius:10px;padding:10px 14px;font-size:13px;color:#991B1B;font-weight:600">
        <i class="bi bi-x-circle-fill" style="font-size:18px;flex-shrink:0"></i>
        This slot was cancelled. Book a new slot below.
      </div>
    </div>
    <% } %>

    <!-- EXPIRED -->
    <% if (sExpired) { %>
    <div style="padding:0 16px 14px">
      <div style="display:flex;align-items:center;gap:10px;background:var(--slate-bg);border-radius:10px;padding:10px 14px;font-size:13px;color:var(--slate);font-weight:600">
        <i class="bi bi-clock-history" style="font-size:18px;flex-shrink:0"></i>
        Slot expired without being started. Book a new slot below.
      </div>
    </div>
    <% } %>

  </div><%-- end slot-item --%>
  <% } %><%-- end for todaySlots --%>
  </div><%-- end slot-timeline --%>
</div>
<% } %><%-- end if !todaySlots.isEmpty --%>

<!-- ══ PORTAL OFFLINE EXPLANATION ════════════════════════════════════════ -->
<% if (!hasActiveOrBooked && (!hasSlot||isComplete||isCancelled||isExpired)) { %>
<div class="section">
  <div class="offline-panel op-amber">
    <div class="offline-icon">📴</div>
    <div>
      <div class="offline-title ot-amber">Portal Offline</div>
      <div class="offline-body ob-amber">
        <% if (!hasSlot)       { %>No shift booked yet. <strong>Book a slot below</strong> to go online and receive orders.
        <% } else if (isComplete) { %>Your shift is complete. Book another slot below to keep earning!
        <% } else if (isCancelled){ %>Your slot was cancelled. Book a new one below.
        <% } else if (isExpired)  { %>Your slot expired. Book a new slot below to get back online.
        <% } %>
      </div>
    </div>
  </div>
</div>
<% } %>

<!-- ══ WALLET STRIP ════════════════════════════════════════════════════ -->
<div class="section">
  <div class="section-label">💰 Wallet Balance</div>
  <div class="card">
    <div class="wallet-strip">
      <div>
        <div class="ws-label">Available Balance</div>
        <div class="ws-val">₹<%= walletBal %></div>
      </div>
      <% if (canGoOnline) { %>
      <span class="ws-badge ws-ok"><i class="bi bi-check-circle-fill"></i> Ready</span>
      <% } else { %>
      <span class="ws-badge ws-warn"><i class="bi bi-exclamation-triangle-fill"></i> Top Up</span>
      <% } %>
    </div>
    <% if (!canGoOnline) { %>
    <div class="warn-row">
      <i class="bi bi-exclamation-triangle-fill"></i>
      <span>You need ₹<%= walletMin %>+ minimum to go online. Please top up your wallet.</span>
    </div>
    <% } %>
  </div>
</div>

<!-- ══ BOOK A NEW SLOT ════════════════════════════════════════════════ -->
<%-- Show booking UI when there is NO active/booked slot blocking it,
     OR when an expired/cancelled/completed slot allows rebooking. --%>
<% boolean showBooking = !hasActiveOrBooked; %>
<% if (showBooking) { %>
<div class="section">
  <div class="section-label">📅 Book a Shift</div>

  <div class="slot-grid" id="slotGrid">
    <%
    Map<String,Boolean> slotBookableMap =
    (Map<String,Boolean>) request.getAttribute("slotBookableMap");
if (slotBookableMap == null) slotBookableMap = new HashMap<>();
    for (int i = 0; i < slotCodes.length; i++) {
      // BUG-I FIX: NIGHT slot (slotStartMin=1320=22:00). At 1 AM (nowTotalMin=60),
      // 60 >= 1320 is FALSE so the card looked bookable even though the overnight
      // window is live. We add a post-midnight guard: if current time is 00:00–02:00
      // AND the NIGHT type is in bookedTypes (servant of yesterday's active slot),
      // treat it as passed. `alreadyTaken` already covers this via getTodaySlots
      // fix — the fallback below also checks nowTotalMin<120 for safety.
      boolean isNightPostMidnight = "NIGHT".equals(slotCodes[i]) && (nowTotalMin < 120);
      Boolean serverBookable = slotBookableMap.get(slotCodes[i]);
      boolean startPassed  = (serverBookable != null) ? !serverBookable
                             : (nowTotalMin >= slotStartMin[i]);
      boolean alreadyTaken = bookedTypes.contains(slotCodes[i]);
      boolean isPopular    = slotCodes[i].equals(popularCode);
      boolean isNightType  = "NIGHT".equals(slotCodes[i])||"MIDNIGHT".equals(slotCodes[i]);
      String cardClass = startPassed ? "slot-disabled" : alreadyTaken ? "slot-taken" : "";
    %>
    <div class="slot-card <%= cardClass %>"
         id="slot-<%= slotCodes[i] %>"
         data-cutoff-min="<%= slotStartMin[i] %>"
         data-code="<%= slotCodes[i] %>"
         onclick="selectSlot('<%= slotCodes[i] %>',this)">
      <% if (isPopular && !startPassed && !alreadyTaken) { %>
      <div class="slot-badge">POPULAR</div>
      <% } else if (isNightType && !startPassed && !alreadyTaken) { %>
      <div class="slot-badge nb">NIGHT</div>
      <% } %>
      <span class="slot-emoji"><%= slotEmoji[i] %></span>
      <div class="slot-name"><%= slotDisplayNames[i] %></div>
      <div class="slot-time"><%= slotTimeLine[i] %></div>
      <% if (alreadyTaken && !startPassed) { %>
      <span class="slot-taken-lbl"><i class="bi bi-check2"></i> Booked</span>
      <% } else if (startPassed) { %>
      <span class="slot-expired-lbl"><i class="bi bi-clock-history"></i> Started</span>
      <% } %>
    </div>
    <% } %>
  </div>

  <!-- Date picker -->
  <div style="margin-top:18px">
    <div class="section-label" style="margin-bottom:8px">📆 Choose Date</div>
    <div class="date-row" id="dateRow">
      <%
      DateTimeFormatter fmt2 = DateTimeFormatter.ofPattern("dd MMM");
      for (int d = 0; d < 7; d++) {
        LocalDate date  = LocalDate.now().plusDays(d);
        String ds       = date.toString();
        String lbl      = d==0?"Today":d==1?"Tomorrow":date.format(fmt2);
        String selClass = (d==0)?" chip-sel":"";
      %>
      <div class="date-chip<%= selClass %>" data-date="<%= ds %>" onclick="selectDate('<%= ds %>',this)">
        <%= lbl %>
      </div>
      <% } %>
    </div>
  </div>

  <!-- Zone picker -->
  <div style="margin-top:16px">
    <div class="section-label" style="margin-bottom:8px">📍 Delivery Zone</div>
    <select class="zone-select" id="zoneSelect">
      <option value="">— Select delivery area —</option>
      <% if (zones != null) for (DeliveryZone z : zones) { %>
      <option value="<%= z.getZoneId() %>" data-surge="<%= z.isSurge() %>" data-multiplier="<%= z.getSurgeMultiplier() %>">
        <%= z.getZoneName() %><%= z.isSurge()?" ⚡ Surge +"+Math.round((z.getSurgeMultiplier()-1)*100)+"%" : "" %>
      </option>
      <% } %>
    </select>
  </div>

  <div class="info-row">
    <i class="bi bi-shield-check"></i>
    <span>Keep wallet at ₹<%= walletMin %>+ before booking. You can book multiple slots for different shift times on the same day!</span>
  </div>

  <div class="book-footer">
    <button class="btn btn-primary btn-big btn-full" id="bookBtn" onclick="doBookSlot()">
      <i class="bi bi-calendar-check" style="font-size:19px"></i>&nbsp;Book My Shift
    </button>
  </div>
</div>
<% } %>

</div><%-- end .wrap --%>

<!-- ══ TOAST BOX ═════════════════════════════════════════════════════════ -->
<div id="toastBox"></div>

<!-- ══ SCRIPTS ═══════════════════════════════════════════════════════════ -->
<script>
var CTX = "<%= request.getContextPath() %>";
var selectedSlot = '';
var selectedDate = '<%= LocalDate.now().toString() %>';
var maxBreakSeconds = <%= maxBreakMin %> * 60;

/* Slot start-time cutoffs (minutes since midnight) — mirrors slotStartMin[] */
var slotStartCutoffMinutes = {
  'MIDNIGHT':120,'EARLY_MORNING':240,'AM':360,'PM':720,'EVENING':1080,'FULL_DAY':360,'NIGHT':1320
};

/* Per-slot epoch maps injected from server */
var slotStartEpochMap = {
  <% boolean first=true; for(Map.Entry<Integer,Long> e:startEpochMap.entrySet()){
     if(!first)out.print(","); out.print(e.getKey()+":"+e.getValue()); first=false; } %>
};
var slotEndEpochMap = {
  <% first=true; for(Map.Entry<Integer,Long> e:endEpochMap.entrySet()){
     if(!first)out.print(","); out.print(e.getKey()+":"+e.getValue()); first=false; } %>
};

/* ── Toast ──────────────────────────────────────────────────────────── */
function showToast(msg,type){
  var box=document.getElementById('toastBox');
  var t=document.createElement('div');
  t.className='toast'+(type==='success'?' t-ok':type==='error'?' t-err':type==='warning'?' t-wrn':'');
  t.textContent=msg; box.appendChild(t);
  setTimeout(function(){if(t.parentNode)t.parentNode.removeChild(t)},3100);
}
function pad(n){return String(n).padStart(2,'0')}

/* ── Slot card select ───────────────────────────────────────────────── */
function selectSlot(code,el){
  document.querySelectorAll('.slot-card').forEach(c=>c.classList.remove('slot-selected'));
  el.classList.add('slot-selected');
  selectedSlot=code;
}

/* ── Date chip — re-evaluate expired + taken cards ──────────────────── */
function selectDate(dateStr,el){
  document.querySelectorAll('.date-chip').forEach(c=>c.classList.remove('chip-sel'));
  el.classList.add('chip-sel');
  selectedDate=dateStr;
  var isToday=(dateStr==='<%= LocalDate.now().toString() %>');
  var nowMin=new Date().getHours()*60+new Date().getMinutes();
  /* bookedTypes only apply to today; future dates are all fresh */
  var bookedToday=<% out.print("["); boolean bf=true;
    for(String t:bookedTypes){if(!bf)out.print(",");out.print("'"+t+"'");bf=false;} out.print("]"); %>;

  document.querySelectorAll('.slot-card').forEach(function(card){
    var code=card.dataset.code;
    var expLbl=card.querySelector('.slot-expired-lbl');
    var takenLbl=card.querySelector('.slot-taken-lbl');
    // BUG-1 FIX: cutoff declared only once (was duplicated — second var shadowed the first)
    var cutoff=slotStartCutoffMinutes[code]||0;
    var nightPostMidnight = isToday && code==='NIGHT' && nowMin < 120;
    var taken=isToday&&bookedToday.indexOf(code)>=0;

    card.classList.remove('slot-disabled','slot-taken','slot-selected');
    if(expLbl)expLbl.style.display='none';
    if(takenLbl)takenLbl.style.display='none';

    // BUG-1 FIX: expired computed once cleanly (was declared twice, line 964 was dead code)
    var expired;
    if (!isToday) {
        expired = false;
    } else if (code === 'MIDNIGHT' || code === 'EARLY_MORNING') {
        expired = false;
    } else if (code === 'NIGHT') {
        expired = nowMin >= 1320 || nightPostMidnight;
    } else {
        expired = nowMin >= cutoff;
    }

    // BUG-2 FIX: actually apply the computed classes and toggle labels —
    // previously the function computed expired/taken correctly but never
    // re-added slot-disabled / slot-taken, so all cards looked enabled
    // after a date switch regardless of time.
    if (expired) {
      card.classList.add('slot-disabled');
      if(expLbl)expLbl.style.display='';
    } else if (taken) {
      card.classList.add('slot-taken');
      if(takenLbl)takenLbl.style.display='';
    }

    // Clear selection if the selected card just became disabled/taken
    if(selectedSlot===code&&(expired||taken)){
      card.classList.remove('slot-selected');
      selectedSlot='';
    }
  });
}

/* ── Book slot ──────────────────────────────────────────────────────── */
function doBookSlot(){
  if(!selectedSlot){showToast('👆 Pick a shift time first!','error');return}
  var zone=document.getElementById('zoneSelect');
  if(!zone||!zone.value){showToast('📍 Choose a delivery area!','error');return}
  var btn=document.getElementById('bookBtn');
  btn.disabled=true;
  btn.innerHTML='<i class="bi bi-hourglass-split"></i>&nbsp;Booking…';
  var fd=new FormData();
  fd.append('action','book'); fd.append('slotType',selectedSlot);
  fd.append('zoneId',zone.value); fd.append('slotDate',selectedDate);
  fetch(CTX+'/DeliverySlotServlet',{method:'POST',body:fd})
  .then(r=>r.json()).then(function(d){
    if(d.success){showToast('✅ Slot booked! Get ready.','success');setTimeout(()=>location.reload(),1500)}
    else{
      btn.disabled=false;
      btn.innerHTML='<i class="bi bi-calendar-check" style="font-size:19px"></i>&nbsp;Book My Shift';
      showToast('❌ '+(d.message||'Could not book slot'),'error');
    }
  }).catch(function(){
    btn.disabled=false;
    btn.innerHTML='<i class="bi bi-calendar-check" style="font-size:19px"></i>&nbsp;Book My Shift';
    showToast('❌ Network error. Try again.','error');
  });
}

/* ── Start shift ────────────────────────────────────────────────────── */
function doStartShift(slotId){
  var fd=new FormData(); fd.append('action','startShift'); fd.append('slotId',slotId);
  fetch(CTX+'/DeliverySlotServlet',{method:'POST',body:fd})
  .then(r=>r.json()).then(function(d){
    if(d.success){showToast('🚀 Shift started! Go deliver!','success');setTimeout(()=>location.reload(),1500)}
    else showToast('❌ '+(d.message||'Could not start shift'),'error');
  }).catch(()=>showToast('❌ Network error','error'));
}

/* ── Start break ────────────────────────────────────────────────────── */
function doStartBreak(slotId){
  var fd=new FormData(); fd.append('action','startBreak'); fd.append('slotId',slotId);
  fetch(CTX+'/DeliverySlotServlet',{method:'POST',body:fd})
  .then(r=>r.json()).then(function(d){
    if(d.success){showToast('☕ Break started. Max '+Math.floor(maxBreakSeconds/60)+' min!','warning');setTimeout(()=>location.reload(),1500)}
    else showToast('❌ '+(d.message||'Could not start break'),'error');
  }).catch(()=>showToast('❌ Network error','error'));
}

/* ── End break ──────────────────────────────────────────────────────── */
function doEndBreak(slotId){
  var fd=new FormData(); fd.append('action','endBreak'); fd.append('slotId',slotId);
  fetch(CTX+'/DeliverySlotServlet',{method:'POST',body:fd})
  .then(r=>r.json()).then(function(d){
    if(d.success){
      if(d.wentOffline)showToast('⛔ Break exceeded — you are now offline.','error');
      else showToast('💪 Back to work!','success');
      setTimeout(()=>location.reload(),1600);
    } else showToast('❌ '+(d.message||'Could not end break'),'error');
  }).catch(()=>showToast('❌ Network error','error'));
}

/* ── End shift ──────────────────────────────────────────────────────── */
function confirmEndShift(slotId){
  if(!confirm('🏁 End your shift now?\n\nYour earnings will be credited to your wallet.'))return;
  var fd=new FormData(); fd.append('action','endShift'); fd.append('slotId',slotId);
  fetch(CTX+'/DeliverySlotServlet',{method:'POST',body:fd})
  .then(r=>r.json()).then(function(d){
    if(d.success){showToast('🎉 Shift ended! Check your wallet.','success');setTimeout(()=>location.reload(),1800)}
    else showToast('❌ '+(d.message||'Could not end shift'),'error');
  }).catch(()=>showToast('❌ Network error','error'));
}

/* ── Cancel section show/hide ───────────────────────────────────────── */
function showCancelSection(slotId){
  var el=document.getElementById('cancelSection-'+slotId);
  if(el){el.style.display='block';el.scrollIntoView({behavior:'smooth',block:'nearest'})}
}
function hideCancelSection(slotId){
  var el=document.getElementById('cancelSection-'+slotId);
  if(el)el.style.display='none';
}

/* ── Cancel slot ────────────────────────────────────────────────────── */
function confirmCancel(slotId){
  var rs=document.getElementById('cancelReason-'+slotId);
  var nt=document.getElementById('cancelNote-'+slotId);
  var reason=(rs&&rs.value)?rs.value:'';
  var note=(nt&&nt.value.trim())?nt.value.trim():'';
  if(!reason){showToast('⚠️ Select a cancellation reason first.','warning');return}
  if(!confirm('Cancel this slot?\n\nNo penalty will be applied.'))return;
  var fullReason=reason+(note?': '+note:'');
  var fd=new FormData();
  fd.append('action','cancel'); fd.append('slotId',slotId); fd.append('reason',fullReason);
  fetch(CTX+'/DeliverySlotServlet',{method:'POST',body:fd})
  .then(r=>r.json()).then(function(d){
    showToast(d.success?'✅ Slot cancelled. You may book a new one.':'❌ '+d.message,
              d.success?'success':'error');
    if(d.success)setTimeout(()=>location.reload(),1500);
  }).catch(()=>showToast('❌ Network error','error'));
}

/* ══════════════════════════════════════════════════════════════════════
   LIVE TIMERS — one per active/on-break/booked slot
   ══════════════════════════════════════════════════════════════════════ */
<% for (DeliverySlot s : todaySlots) {
  String sStatus = s.getStatus();
  int sId = s.getSlotId();
  Long sStartMs = startEpochMap.get(sId);
  Long sEndMs   = endEpochMap.get(sId);
  Long sSatMs   = (s.getShiftStartedAt()!=null) ?
    s.getShiftStartedAt().atZone(java.time.ZoneId.systemDefault()).toInstant().toEpochMilli() : 0L;
  // BUG-4 FIX: expose break_start epoch so live break seconds can be subtracted
  // from working time — previously only historical breakMin*60 was subtracted,
  // so the working timer kept ticking during an active break.
  long sBreakStartEpoch = s.getBreakStartEpoch(); // 0 if not on break

  if ("ACTIVE".equals(sStatus) || "ON_BREAK".equals(sStatus)) {
%>
(function(){
  var slotId=<%= sId %>;
  var endMs=<%= sEndMs!=null?sEndMs:0 %>;
  var origin=<%= sSatMs %>>0?<%= sSatMs %>:<%= sStartMs!=null?sStartMs:0 %>;
  var breakMin=<%= s.getTotalBreakMin() %>;
  // BUG-4 FIX: breakStartEpoch allows us to add live (in-progress) break seconds
  var breakStartEpoch=<%= sBreakStartEpoch %>;
  var autoOfflineFired = false;
  var workInterval = setInterval(function() {
      var now = Date.now();
      var elapsed = Math.floor((now - origin) / 1000);

      // BUG-4 FIX: if currently on break, add live break seconds to the deduction
      // so working time pauses rather than continuing to tick during a break.
      var liveBreakSec = (breakStartEpoch > 0) ? Math.floor((now - breakStartEpoch) / 1000) : 0;
      var totalBreakSec = breakMin * 60 + liveBreakSec;

    var work=Math.max(0,elapsed-totalBreakSec);
    var h=Math.floor(work/3600),m=Math.floor((work%3600)/60),sec=work%60;
    var wEl=document.getElementById('workTimer-'+slotId);
    if(wEl)wEl.textContent=(h>0?h+':':'')+pad(m)+':'+pad(sec);

    if (endMs > 0) {
        var rem = Math.max(0, Math.floor((endMs - Date.now()) / 1000));
      var rEl=document.getElementById('endTimer-'+slotId);
      if(rEl){
        var rh=Math.floor(rem/3600),rm=Math.floor((rem%3600)/60);
        rEl.textContent=(rh>0?rh+'h ':'')+rm+'m';
        rEl.className='timer-val'+(rem<900?' tv-red':'');
      }
      if (rem === 0 && !autoOfflineFired) {
          autoOfflineFired = true;
          clearInterval(workInterval);   // prevent further ticks
          // BUG FIX: When shift window expires, automatically complete the shift
          // using the same endShift action the agent uses manually.
          // Previously this called autoOffline which set status=INACTIVE but
          // did NOT mark the slot COMPLETED — the agent was then stuck:
          // clicking End Shift failed with "Cannot end shift" because the slot
          // was INACTIVE (not ACTIVE/ON_BREAK), and isSlotSafeToComplete()
          // returned false due to the total==0 bug. Both bugs are now fixed,
          // but using endShift here is the cleaner auto-complete path.
          fetch(CTX + '/DeliverySlotServlet', {
              method: 'POST',
              body: new URLSearchParams({action: 'endShift', slotId: slotId})
          })
          .then(r => r.json())
          .then(function(d) {
              if (d.success) {
                  showToast('⏰ Shift window ended. Earnings credited!', 'success');
              } else if (d.errorCode === 'UNDEPOSITED_COD') {
                  showToast('⚠️ Deposit your COD collections to end shift.', 'warning');
              } else {
                  // Fallback: force offline if endShift fails
                  fetch(CTX + '/DeliverySlotServlet', {
                      method: 'POST',
                      body: new URLSearchParams({action: 'autoOffline', slotId: slotId})
                  }).catch(function(){});
                  showToast('⏰ Shift window closed. You are now offline.', 'warning');
              }
              setTimeout(() => location.reload(), 2500);
          })
          .catch(function() {
              showToast('⏰ Shift window closed.', 'warning');
              setTimeout(() => location.reload(), 2500);
          });
      }
  }
}, 1000);
})();
<% } %>

<% if ("ON_BREAK".equals(sStatus) && s.getSlotId()==slotId && breakSecsLeft>0) { %>
(function(){
  var secs=<%= breakSecsLeft %>;
  var maxSec=maxBreakSeconds;
  var slotId=<%= sId %>;
  var timer=setInterval(function(){
    secs--;
    if(secs<0){clearInterval(timer);return}
    var m=Math.floor(secs/60),s=secs%60;
    var el=document.getElementById('breakCountdown-'+slotId);
    if(el)el.textContent=m+':'+pad(s);
    var bar=document.getElementById('breakFill-'+slotId);
    if(bar)bar.style.width=Math.min(100,(maxSec-secs)*100/maxSec)+'%';
    if(secs===60)showToast('⚠️ 1 minute left in break!','warning');
    if(secs<=0){clearInterval(timer);showToast('⛔ Break over — being set offline.','error');setTimeout(()=>location.reload(),2200)}
  },1000);
})();
<% } %>

<% if ("BOOKED".equals(sStatus) && sStartMs!=null) { %>
(function(){
  var slotId   = <%= sId %>;
  var startMs  = <%= sStartMs %>;
  var endMs    = <%= sEndMs!=null?sEndMs:0 %>;
  var earlyMs  = startMs - 15 * 60 * 1000;            // 15-min early window open
  // Expiry = 1 hr before slot END (matches DAO expireStaleBookedSlots rule)
  var graceMs  = (endMs > startMs) ? endMs - 60*60*1000 : startMs + 3*60*60*1000;

  // Show start time label
  var fmtEl = document.getElementById('startTimeFmt-' + slotId);
  if (fmtEl) fmtEl.textContent = new Date(startMs)
    .toLocaleTimeString('en-IN',{hour:'numeric',minute:'2-digit',hour12:true});

  // Show expiry time label
  var expEl = document.getElementById('expireTimeFmt-' + slotId);
  if (expEl) expEl.textContent = new Date(graceMs)
    .toLocaleTimeString('en-IN',{hour:'numeric',minute:'2-digit',hour12:true});

  var iv = null, reloadScheduled = false;

  function tick() {
    var now = Date.now();
    var hEl=document.getElementById('cdh-'+slotId),
        mEl=document.getElementById('cdm-'+slotId),
        sEl=document.getElementById('cds-'+slotId);
    var wrap  = document.getElementById('cdWrap-'+slotId);
    var container = document.querySelector('.slot-item[data-slot-id="'+slotId+'"]');

    // Phase 1: before 15-min window opens
    if (now < earlyMs) {
      var diff = Math.floor((earlyMs - now) / 1000);
      if(hEl)hEl.textContent=pad(Math.floor(diff/3600));
      if(mEl)mEl.textContent=pad(Math.floor((diff%3600)/60));
      if(sEl)sEl.textContent=pad(diff%60);
      if(wrap){ wrap.style.display=''; wrap.querySelectorAll('.cd-num').forEach(function(e){e.style.color='';e.style.background='';}); }
      return;
    }

    // Phase 2: window open, not yet at start -> activate button
    if (now >= earlyMs && now <= startMs) {
      if(wrap) wrap.style.display='none';
      var ctrl = container ? container.querySelector('.slot-controls .btn-ghost[disabled]') : null;
      if(ctrl) ctrl.outerHTML='<button class="btn btn-success pulse" onclick="doStartShift('+slotId+')"><i class="bi bi-play-circle-fill"></i><span class="btn-stack"><span class="btn-main">Start Shift</span><span class="btn-hint">Window open!</span></span></button>';
      return;
    }

    // Phase 3: after start, within grace -> urgent red countdown
    if (now > startMs && now <= graceMs) {
      var rem = Math.floor((graceMs - now) / 1000);
      var rm  = Math.floor(rem/60), rs = rem%60;
      if(wrap){ wrap.style.display=''; wrap.querySelectorAll('.cd-num').forEach(function(e){e.style.color='var(--red)';e.style.background='var(--red-bg)';}); }
      if(hEl)hEl.textContent='00';
      if(mEl)mEl.textContent=pad(rm);
      if(sEl)sEl.textContent=pad(rs);
      var ctrl = container ? container.querySelector('.slot-controls .btn-ghost[disabled]') : null;
      if(ctrl) ctrl.outerHTML='<button class="btn btn-danger pulse" onclick="doStartShift('+slotId+')"><i class="bi bi-exclamation-triangle-fill"></i><span class="btn-stack"><span class="btn-main">Start Now!</span><span class="btn-hint">Expires '+pad(rm)+':'+pad(rs)+'</span></span></button>';
      if(rem===60 && typeof showToast==='function') showToast('\u26a0\ufe0f Your slot expires in 1 minute!','error',6000);
      return;
    }

    // Phase 4: expired
    if (now > graceMs && !reloadScheduled) {
      reloadScheduled = true;
      clearInterval(iv);
      if(typeof showToast==='function') showToast('Slot expired. Please book a new one.','error',5000);
      setTimeout(function(){location.reload();}, 2800);
    }
  }

  tick();
  iv = setInterval(tick, 1000);
})();
<% } %>

<% } /* end for todaySlots */ %>
</script>
</body>
</html>
