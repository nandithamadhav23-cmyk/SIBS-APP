<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true"%>
<%@ page import="java.util.*, com.util.*,java.text.SimpleDateFormat" %>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Delivery Portal</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet"/>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css" rel="stylesheet"/>
  <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet"/>
 <script src="https://checkout.razorpay.com/v1/checkout.js"></script>
 
 <script>
  var CTX = "<%=request.getContextPath()%>";
</script>
<%-- delivery-portal.js must load AFTER CTX is defined --%>
  <style>
    /* ═══════════════════════════════════════════════
       BASE — Pastel / White theme, Times New Romana
    ═══════════════════════════════════════════════ */
    :root {
  --brand-light:  #9b7fd4;
  --brand-pale:   #ede8f9;
  --green:        #27ae60;
  --red:          #e74c3c;
  --orange:       #f39c12;
  --text:         #2c2c3e;
  --muted:        #777;
  --border:       #e2ddf5;
  --radius:       12px;
      --brand:       #7C5CBF;
      --brand-lt:    #EDE7F6;
      --brand-dk:    #5B3EA6;
      --green:       #2E7D32;
      --green-bg:    #E8F5E9;
      --amber:       #B45309;
      --amber-bg:    #FFF8E1;
      --blue:        #1565C0;
      --blue-bg:     #E3F2FD;
      --red:         #C62828;
      --red-bg:      #FFEBEE;
      --rose:        #C2185B;
      --rose-bg:     #FCE4EC;
      --teal:        #00695C;
      --teal-bg:     #E0F2F1;
      --surface:     #FAFAFA;
      --card:        #FFFFFF;
      --border:      #E0E0E0;
      --border2:     #BDBDBD;
      --text1:       #1A1A2E;
      --text2:       #4A4A6A;
      --text3:       #7A7A9A;
      --shadow:      0 2px 12px rgba(0,0,0,0.07);
      --shadow-md:   0 4px 20px rgba(0,0,0,0.10);
      --radius:      12px;
      --radius-sm:   8px;
      --sidebar-w:   220px;
      --topbar-h:    62px;
      --font:        'Times New Roman', Times, serif;
      /* ── Wallet aliases (used by wallet CSS) ── */
      --brand-pale:  #EDE7F6;
      --brand-light: #9B7FD4;
      --orange:      #B45309;
      --muted:       #7A7A9A;
      --text:        #1A1A2E;
    }

    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

    body {
      font-family: var(--font);
      background: var(--surface);
      color: var(--text1);
      min-height: 100vh;
      font-size: 15px;
    }

    a { color: var(--blue); text-decoration: none; }
    a:hover { text-decoration: underline; }

    /* ── SIDEBAR ─────────────────────────────────── */
    .sidebar {
      position: fixed; top: 0; left: 0;
      width: var(--sidebar-w); height: 100vh;
      background: #FFFFFF;
      border-right: 1px solid var(--border);
      display: flex; flex-direction: column;
      z-index: 200; overflow-y: auto;
      box-shadow: 2px 0 8px rgba(0,0,0,0.06);
      transition: transform 0.3s ease;
    }

    .logo-wrap {
      display: flex; align-items: center; gap: 10px;
      padding: 18px 20px 16px;
      border-bottom: 1px solid var(--border);
      background: var(--brand-lt);
    }
    .logo-icon {
      width: 38px; height: 38px; border-radius: 10px;
      background: var(--brand); color: #fff;
      display: flex; align-items: center; justify-content: center;
      font-size: 18px; flex-shrink: 0;
    }
    .logo-text { font-weight: 700; font-size: 16px; color: var(--brand-dk); letter-spacing: 0.02em; }

    .nav-section-label {
      font-size: 11px; font-weight: 700; letter-spacing: 0.08em;
      color: var(--text3); padding: 16px 20px 6px;
      text-transform: uppercase;
    }

    .nav-item {
      display: flex; align-items: center; gap: 12px;
      width: 100%; padding: 11px 20px;
      border: none; background: none;
      color: var(--text2); font-family: var(--font);
      font-size: 14px; text-align: left; cursor: pointer;
      transition: background 0.18s, color 0.18s;
      border-left: 3px solid transparent;
    }
    .nav-item i { font-size: 17px; flex-shrink: 0; }
    .nav-item:hover { background: var(--brand-lt); color: var(--brand-dk); }
    .nav-item.active {
      background: var(--brand-lt); color: var(--brand-dk);
      border-left-color: var(--brand); font-weight: 600;
    }

    .nav-divider { height: 1px; background: var(--border); margin: 8px 16px; }

    .sidebar-bottom {
      margin-top: auto;
      padding: 14px 16px;
      border-top: 1px solid var(--border);
    }
    .rider-chip {
      display: flex; align-items: center; gap: 10px;
      background: var(--brand-lt); border-radius: var(--radius-sm);
      padding: 10px 12px; cursor: pointer;
    }
    .rider-avatar {
      width: 34px; height: 34px; border-radius: 50%;
      background: var(--brand); color: #fff;
      display: flex; align-items: center; justify-content: center;
      font-weight: 700; font-size: 13px; flex-shrink: 0;
    }
    .rider-info { flex: 1; overflow: hidden; }
    .rider-name { font-size: 13px; font-weight: 600; color: var(--text1); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
    .rider-role { font-size: 11px; color: var(--text3); }

    /* ── MOBILE BOTTOM NAV ───────────────────────── */
    .bottom-nav {
      display: none;
      position: fixed; bottom: 0; left: 0; right: 0;
      background: #fff; border-top: 1px solid var(--border);
      z-index: 200; height: 60px;
    }
    .bottom-nav-inner { display: flex; height: 100%; align-items: stretch; }
    .bnav-item {
      flex: 1; display: flex; flex-direction: column;
      align-items: center; justify-content: center; gap: 2px;
      border: none; background: none; cursor: pointer;
      font-family: var(--font); color: var(--text3);
      font-size: 10px; padding: 0; transition: color 0.2s; position: relative;
    }
    .bnav-item i { font-size: 20px; }
    .bnav-item.active { color: var(--brand); }
    .bnav-item .badge-dot {
      position: absolute; top: 8px; right: calc(50% - 14px);
      width: 7px; height: 7px; border-radius: 50%;
      background: var(--red); border: 1px solid #fff;
    }

    /* ── TOPBAR ──────────────────────────────────── */
    .topbar {
      position: fixed; top: 0;
      left: var(--sidebar-w); right: 0; height: var(--topbar-h);
      background: #fff; border-bottom: 1px solid var(--border);
      display: flex; align-items: center; justify-content: space-between;
      padding: 0 24px; z-index: 99;
      box-shadow: 0 1px 4px rgba(0,0,0,0.05);
      transition: left 0.3s ease;
    }
    .topbar-left { display: flex; align-items: center; gap: 12px; }
    .topbar-title { font-size: 19px; font-weight: 700; color: var(--text1); }
    .topbar-right { display: flex; align-items: center; gap: 10px; }

    .online-pill {
      display: flex; align-items: center; gap: 7px;
      border: 1px solid var(--border); border-radius: 20px;
      padding: 5px 14px; font-size: 13px; cursor: pointer;
      background: #fff; font-family: var(--font);
      transition: border-color 0.2s;
    }
    .online-pill:hover { border-color: var(--brand); }
    .pulse-dot {
      width: 8px; height: 8px; border-radius: 50%;
      background: var(--green); animation: blink 2s infinite;
    }
    .pulse-dot.off { background: var(--text3); animation: none; }
    @keyframes blink { 0%,100%{opacity:1;} 50%{opacity:0.35;} }

    .zone-tag {
      display: flex; align-items: center; gap: 5px;
      font-size: 13px; color: var(--text2);
      background: var(--brand-lt); border-radius: 20px;
      padding: 4px 12px;
    }

    /* ── MAIN ────────────────────────────────────── */
    .main {
      margin-left: var(--sidebar-w);
      padding-top: var(--topbar-h);
      min-height: 100vh;
      transition: margin-left 0.3s ease;
    }
    .page { display: none; padding: 26px 24px 40px; }
    .page.active { display: block; }

    /* ── PAGE HEADING ── */
    .pg-head { margin-bottom: 22px; }
    .pg-head h1 { font-size: 22px; font-weight: 700; color: var(--text1); }
    .pg-head p  { font-size: 14px; color: var(--text2); margin-top: 3px; }

    /* ── STAT CARDS ───────────────────────────────── */
    .stats-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
      gap: 14px; margin-bottom: 26px;
    }
    .stat-card {
      background: var(--card); border: 1px solid var(--border);
      border-radius: var(--radius); padding: 18px 20px;
      box-shadow: var(--shadow);
      display: flex; flex-direction: column; gap: 4px;
      transition: box-shadow 0.2s, transform 0.15s; cursor: default;
    }
    .stat-card:hover { box-shadow: var(--shadow-md); transform: translateY(-1px); }
    .stat-icon-wrap {
      width: 38px; height: 38px; border-radius: 10px;
      display: flex; align-items: center; justify-content: center;
      font-size: 18px; margin-bottom: 8px;
    }
    .stat-label { font-size: 12px; color: var(--text3); letter-spacing: 0.04em; text-transform: uppercase; }
    .stat-value { font-size: 28px; font-weight: 700; color: var(--text1); line-height: 1; }
    .stat-sub   { font-size: 12px; color: var(--text3); }

    /* ── SECTION HEADER ── */
    .sec-head {
      display: flex; align-items: center; justify-content: space-between;
      margin-bottom: 14px;
    }
    .sec-title { font-size: 16px; font-weight: 700; color: var(--text1); }

    /* ── MAP PLACEHOLDER ── */
    .map-placeholder {
      background: var(--brand-lt); border: 1px dashed var(--brand);
      border-radius: var(--radius); height: 160px;
      display: flex; align-items: center; justify-content: center;
      flex-direction: column; gap: 8px; color: var(--brand);
      margin-bottom: 22px; font-size: 14px;
    }
    .map-placeholder i { font-size: 30px; }

    /* ── FILTER BAR ── */
    .filter-bar {
      display: flex; gap: 8px; flex-wrap: wrap; margin-bottom: 18px; align-items: center;
    }
    .fbtn {
      padding: 6px 15px; border-radius: 20px; font-size: 13px;
      border: 1px solid var(--border); background: #fff;
      color: var(--text2); cursor: pointer; font-family: var(--font);
      transition: all 0.18s;
    }
    .fbtn:hover, .fbtn.active {
      background: var(--brand); border-color: var(--brand); color: #fff;
    }
    .search-box {
      margin-left: auto;
      display: flex; align-items: center; gap: 6px;
      background: #fff; border: 1px solid var(--border);
      border-radius: var(--radius-sm); padding: 6px 12px;
    }
    .search-box input {
      border: none; outline: none; font-family: var(--font);
      font-size: 13px; color: var(--text1); width: 160px; background: transparent;
    }
    .search-box i { color: var(--text3); }

    /* ── ORDER GRID ── */
    .orders-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(330px, 1fr));
      gap: 18px;
    }

    /* ── ORDER CARD ── */
    .order-card {
      background: var(--card); border: 1px solid var(--border);
      border-radius: var(--radius); overflow: hidden;
      box-shadow: var(--shadow);
      transition: box-shadow 0.2s, transform 0.15s;
    }
    .order-card:hover { box-shadow: var(--shadow-md); transform: translateY(-2px); }
    .order-card.cod-urgent { border-top: 3px solid var(--amber); }
    .order-card.cod-deposit-due {
      border-top: 3px solid var(--amber);
      border-left: 3px solid var(--amber);
      background: linear-gradient(135deg, #FFFDF0 0%, #fff 60%);
    }
    .return-order { border-top: 3px solid var(--rose) !important; }

    .card-head {
      padding: 13px 16px;
      display: flex; align-items: flex-start; justify-content: space-between;
      border-bottom: 1px solid var(--border);
      background: #FAFAFA;
    }
    .card-order-id { font-size: 15px; font-weight: 700; color: var(--brand-dk); font-family: 'Courier New', monospace; }
    .card-date { font-size: 11px; color: var(--text3); margin-top: 2px; }

    .sbadge {
      padding: 3px 10px; border-radius: 20px; font-size: 11px; font-weight: 700;
      letter-spacing: 0.02em; white-space: nowrap;
    }
    .sb-pending   { background: var(--amber-bg);  color: var(--amber); }
    .sb-picked    { background: var(--blue-bg);   color: var(--blue); }
    .sb-transit   { background: var(--teal-bg);   color: var(--teal); }
    .sb-delivered { background: var(--green-bg);  color: var(--green); }
    .sb-assigned  { background: var(--rose-bg);   color: var(--rose); }
    .sb-rose      { background: var(--rose-bg);   color: var(--rose); }
    .sb-paid      { background: var(--green-bg);  color: var(--green); }
    .sb-unpaid    { background: var(--amber-bg);  color: var(--amber); }

    .card-body-pad { padding: 14px 16px; }

    .info-row {
      display: flex; align-items: flex-start; gap: 9px;
      margin-bottom: 9px; font-size: 13.5px; color: var(--text1);
    }
    .info-row i { color: var(--text3); font-size: 14px; margin-top: 2px; flex-shrink: 0; }

    /* product table */
    .prod-table { width: 100%; border-collapse: collapse; font-size: 13px; margin: 10px 0; }
    .prod-table td { padding: 5px 0; border-bottom: 1px solid var(--border); color: var(--text2); }
    .prod-table tr:last-child td { border-bottom: none; }
    .prod-table td:last-child { text-align: right; font-weight: 600; color: var(--text1); }
    .total-bar {
      display: flex; justify-content: space-between; align-items: center;
      padding: 8px 0 0; border-top: 1.5px solid var(--border);
      font-size: 14px; font-weight: 700; color: var(--text1); margin-top: 2px;
    }
    .total-bar span:last-child { color: var(--brand-dk); }

    /* payment row */
    .pay-row { display: flex; align-items: center; gap: 8px; margin: 10px 0 4px; flex-wrap: wrap; }

    /* ── PROGRESS STEPS ── */
    .prog-track {
      display: flex; align-items: flex-start;
      margin: 14px 0 4px; position: relative;
    }
    .prog-step { flex: 1; text-align: center; position: relative; }
    .prog-step::after {
      content: ''; position: absolute;
      top: 10px; left: 50%; right: -50%;
      height: 2px; background: var(--border);
    }
    .prog-step:last-child::after { display: none; }
    .prog-step.done::after  { background: var(--green); }
    .prog-step.active::after { background: linear-gradient(to right, var(--green), var(--border)); }
    .step-circle {
      width: 20px; height: 20px; border-radius: 50%;
      background: var(--border); border: 2px solid var(--border);
      margin: 0 auto 4px; position: relative; z-index: 1;
      display: flex; align-items: center; justify-content: center; font-size: 9px;
    }
    .prog-step.done  .step-circle { background: var(--green); border-color: var(--green); color: #fff; }
    .prog-step.active .step-circle {
      background: var(--brand); border-color: var(--brand); color: #fff;
      animation: blink 1.5s infinite;
    }
    .step-lbl { font-size: 10px; color: var(--text3); }
    .prog-step.done  .step-lbl  { color: var(--green); font-weight: 600; }
    .prog-step.active .step-lbl { color: var(--brand); font-weight: 600; }

    /* ── OTP SECTION ── */
    .otp-card {
      display: none;
      background: #fff;
      border: 1.5px solid #e2e8f0;
      border-radius: 16px;
      padding: 20px;
      margin-top: 12px;
      box-shadow: 0 4px 24px rgba(0,0,0,0.08);
      animation: slideDown 0.3s ease;
    }
    .otp-card.show { display: block; }
    @keyframes slideDown {
      from { opacity: 0; transform: translateY(-10px); }
      to   { opacity: 1; transform: translateY(0); }
    }
    .otp-header { display: flex; align-items: center; gap: 12px; margin-bottom: 16px; }
    .otp-shield {
      font-size: 28px; color: #6366f1; background: #eef2ff;
      border-radius: 50%; width: 48px; height: 48px;
      display: flex; align-items: center; justify-content: center;
    }
    .otp-title { font-weight: 700; font-size: 15px; color: #1e293b; }
    .otp-sub   { font-size: 12px; color: #94a3b8; margin-top: 2px; }
    .otp-banner {
      display: flex; align-items: center; gap: 8px;
      padding: 10px 14px; border-radius: 10px; font-size: 13px;
      font-weight: 500; margin-bottom: 14px;
    }
    .otp-banner.success { background: #f0fdf4; color: #16a34a; border: 1px solid #bbf7d0; }
    .otp-banner.error   { background: #fef2f2; color: #dc2626; border: 1px solid #fecaca; }
    .otp-banner.info    { background: #eff6ff; color: #2563eb; border: 1px solid #bfdbfe; }
    .otp-digits { display: flex; gap: 8px; justify-content: center; margin-bottom: 16px; }
    .otp-digit {
      width: 42px; height: 50px; text-align: center;
      font-size: 20px; font-weight: 700;
      border: 2px solid #e2e8f0; border-radius: 10px; outline: none;
      transition: border-color 0.2s, box-shadow 0.2s; color: #1e293b;
    }
    .otp-digit:focus { border-color: #6366f1; box-shadow: 0 0 0 3px rgba(99,102,241,0.15); }
    .otp-digit.filled { border-color: #6366f1; background: #eef2ff; }
    .otp-verify-btn {
      width: 100%; padding: 11px;
      background: linear-gradient(135deg, #6366f1, #4f46e5);
      color: #fff; border: none; border-radius: 10px;
      font-size: 14px; font-weight: 600; cursor: pointer;
      display: flex; align-items: center; justify-content: center; gap: 6px;
      transition: opacity 0.2s, transform 0.1s;
    }
    .otp-verify-btn:hover  { opacity: 0.92; }
    .otp-verify-btn:active { transform: scale(0.98); }

    /* alert strips */
    .alert-ok  { background: var(--green-bg); color: var(--green); border-radius: var(--radius-sm); padding: 8px 12px; font-size: 13px; margin-top: 8px; display:flex; align-items:center; gap:6px; }
    .alert-err { background: var(--red-bg);   color: var(--red);   border-radius: var(--radius-sm); padding: 8px 12px; font-size: 13px; margin-top: 8px; display:flex; align-items:center; gap:6px; }
    .alert-info{ background: var(--blue-bg);  color: var(--blue);  border-radius: var(--radius-sm); padding: 8px 12px; font-size: 13px; margin-top: 8px; display:flex; align-items:center; gap:6px; }

    /* ── ACTION BUTTONS BAR ── */
    .action-bar {
      display: flex; gap: 6px; flex-wrap: wrap;
      margin-top: 12px; padding-top: 12px;
      border-top: 1px solid var(--border);
    }
    .act-btn {
      flex: 1; min-width: 70px; padding: 8px 6px;
      border-radius: var(--radius-sm); font-size: 12px; font-weight: 600;
      border: 1px solid transparent; cursor: pointer;
      font-family: var(--font);
      display: flex; align-items: center; justify-content: center; gap: 4px;
      transition: opacity 0.18s, transform 0.12s; text-decoration: none;
    }
    .act-btn:hover { opacity: 0.85; transform: translateY(-1px); text-decoration: none; }
    .act-btn:active { transform: scale(0.97); }
    .btn-pickup  { background: var(--amber-bg);  color: var(--amber);  border-color: #F6D860; }
    .btn-transit { background: var(--teal-bg);   color: var(--teal);   border-color: #80CBC4; }
    .btn-genotp  { background: var(--blue-bg);   color: var(--blue);   border-color: #90CAF9; }
    .btn-deliver { background: var(--green-bg);  color: var(--green);  border-color: #A5D6A7; }
    .btn-upi     { background: var(--brand);     color: #fff;          border-color: var(--brand); }
    .btn-pickup-return { background: #FFF3E0; color: #E65100; border: 1px solid #FFE0B2; }
    .btn-pickup-return:hover { background: #FFE0B2; }
    .btn-danger  { background: var(--red-bg);    color: var(--red);    border-color: #EF9A9A; }

    /* ── DELIVERED — disable all action buttons ── */
    .action-bar.delivered .act-btn {
      opacity: 0.32; cursor: not-allowed; pointer-events: none;
    }
    .action-bar.delivered .btn-deliver {
      opacity: 1; pointer-events: none; cursor: default;
      background: var(--green-bg); color: var(--green); border-color: #A5D6A7;
    }

    /* UPI row */
    .upi-row { display: flex; gap: 8px; margin-top: 8px; flex-wrap: wrap; }

    /* ── EMPTY STATE ── */
    .empty { text-align: center; padding: 60px 20px; color: var(--text3); }
    .empty i { font-size: 44px; display: block; margin-bottom: 12px; }
    .empty p { font-size: 15px; }

    /* ── PROFILE ─────────────────────────────────── */
    .profile-grid {
      display: grid; grid-template-columns: 260px 1fr; gap: 20px; align-items: start;
    }
    .profile-card {
      background: var(--card); border: 1px solid var(--border);
      border-radius: var(--radius); padding: 28px 20px; text-align: center;
      box-shadow: var(--shadow);
    }
    .p-avatar {
      width: 76px; height: 76px; border-radius: 50%;
      background: var(--brand); color: #fff;
      font-size: 28px; font-weight: 700;
      display: flex; align-items: center; justify-content: center;
      margin: 0 auto 12px; border: 3px solid var(--brand-lt);
    }
    .p-name { font-size: 17px; font-weight: 700; color: var(--text1); }
    .p-role { font-size: 13px; color: var(--text3); margin-top: 2px; }
    .online-chip {
      display: inline-flex; align-items: center; gap: 6px;
      background: var(--green-bg); color: var(--green);
      border-radius: 20px; padding: 3px 12px; font-size: 12px; margin-top: 8px; font-weight: 600;
    }
    .p-stats { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; margin-top: 18px; }
    .pstat { background: var(--brand-lt); border-radius: var(--radius-sm); padding: 10px 6px; text-align: center; }
    .pstat-val   { font-size: 20px; font-weight: 700; color: var(--brand-dk); }
    .pstat-label { font-size: 11px; color: var(--text3); margin-top: 2px; }

    .info-panel {
      background: var(--card); border: 1px solid var(--border);
      border-radius: var(--radius); padding: 20px 22px;
      box-shadow: var(--shadow); margin-bottom: 16px;
    }
    .ip-head { font-size: 13px; font-weight: 700; letter-spacing: 0.04em; color: var(--text3); text-transform: uppercase; margin-bottom: 14px; }
    .ip-row {
      display: flex; justify-content: space-between; align-items: center;
      padding: 10px 0; border-bottom: 1px solid var(--border); font-size: 14px;
    }
    .ip-row:last-child { border-bottom: none; }
    .ip-key { color: var(--text2); display: flex; align-items: center; gap: 6px; }
    .ip-val { font-weight: 600; color: var(--text1); }
    .star-row { color: #F59E0B; }

    /* ── EARNINGS ─────────────────────────────────── */
    .earn-grid { display: grid; grid-template-columns: repeat(3,1fr); gap: 14px; margin-bottom: 22px; }
    .earn-card {
      background: var(--card); border: 1px solid var(--border);
      border-radius: var(--radius); padding: 18px 20px; box-shadow: var(--shadow);
    }
    .earn-label { font-size: 12px; color: var(--text3); text-transform: uppercase; letter-spacing: 0.04em; margin-bottom: 6px; }
    .earn-val   { font-size: 26px; font-weight: 700; color: var(--text1); }
    .earn-sub   { font-size: 12px; color: var(--text3); margin-top: 4px; }

    .hist-table { width: 100%; border-collapse: collapse; font-size: 13.5px; }
    .hist-table th { text-align: left; padding: 10px 14px; background: #F5F5F5; font-weight: 700; font-size: 12px; color: var(--text3); letter-spacing: 0.04em; border-bottom: 1px solid var(--border); }
    .hist-table td { padding: 11px 14px; border-bottom: 1px solid var(--border); color: var(--text1); }
    .hist-table tr:hover td { background: var(--brand-lt); }

    /* ── NOTIFICATIONS ────────────────────────────── */
   .notif-page-header{display:flex;align-items:center;justify-content:space-between;margin-bottom:20px;gap:12px}
.notif-page-title{font-size:22px;font-weight:800;color:var(--text1);letter-spacing:-.4px}
.notif-page-sub{font-size:13px;color:var(--text3);margin-top:2px}
.notif-actions{display:flex;gap:8px;flex-shrink:0}
.notif-tabs{display:flex;gap:6px;margin-bottom:16px;padding:3px;background:var(--surface);border-radius:10px;border:1px solid var(--border)}
.notif-tab{flex:1;text-align:center;padding:7px 10px;border-radius:8px;font-size:12px;font-weight:700;cursor:pointer;transition:.15s;color:var(--text3);border:none;background:transparent}
.notif-tab.active{background:var(--brand);color:#fff;box-shadow:0 2px 8px rgba(124,92,191,.3)}
.notif-feed{display:flex;flex-direction:column;gap:0}
.notif-group-label{font-size:10px;font-weight:800;text-transform:uppercase;letter-spacing:.08em;color:var(--text3);padding:12px 4px 6px;border-bottom:1px solid var(--border);margin-bottom:2px}
.ncard{display:flex;align-items:flex-start;gap:12px;padding:14px 16px;background:var(--card);border-radius:12px;border:1px solid var(--border);margin-bottom:8px;transition:.15s;position:relative;cursor:pointer}
.ncard:hover{background:var(--brand-lt);border-color:var(--brand);transform:translateX(2px)}
.ncard.unread{border-left:3px solid var(--brand);background:#FAFAFE}
.ncard.unread::before{content:'';position:absolute;top:14px;right:14px;width:8px;height:8px;border-radius:50%;background:var(--brand)}
.ncard-ico{width:42px;height:42px;border-radius:12px;display:flex;align-items:center;justify-content:center;font-size:20px;flex-shrink:0}
.ncard-ico.amber{background:var(--amber-bg)}
.ncard-ico.green{background:var(--green-bg)}
.ncard-ico.blue{background:var(--blue-bg)}
.ncard-ico.red{background:var(--red-bg)}
.ncard-ico.purple{background:var(--brand-lt)}
.ncard-ico.teal{background:var(--teal-bg)}
.ncard-body{flex:1;min-width:0}
.ncard-title{font-size:13.5px;font-weight:700;color:var(--text1);line-height:1.3;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.ncard-body-text{font-size:12px;color:var(--text2);margin-top:3px;line-height:1.4}
.ncard-time{font-size:11px;color:var(--text3);margin-top:5px;display:flex;align-items:center;gap:4px}
.ncard-dismiss{position:absolute;top:8px;right:20px;font-size:16px;color:var(--text3);background:none;border:none;cursor:pointer;opacity:0;transition:.15s;padding:4px}
.ncard:hover .ncard-dismiss{opacity:1}
.ncard.unread .ncard-dismiss{right:30px}
.notif-empty{text-align:center;padding:48px 24px;color:var(--text3)}
.notif-empty-ico{font-size:48px;margin-bottom:12px;opacity:.4}
.notif-empty-txt{font-size:14px;font-weight:600}
.notif-empty-sub{font-size:12px;margin-top:4px}
.notif-badge{display:inline-flex;align-items:center;justify-content:center;background:var(--brand);color:#fff;border-radius:10px;font-size:10px;font-weight:800;padding:1px 6px;min-width:18px;margin-left:6px}
.notif-load{text-align:center;padding:16px;color:var(--text3);font-size:13px}
.notif-type-badge{display:inline-block;font-size:9px;font-weight:800;text-transform:uppercase;letter-spacing:.06em;padding:2px 6px;border-radius:4px;margin-left:6px;vertical-align:middle}
.notif-type-badge.ORDER_ASSIGNED{background:var(--amber-bg);color:var(--amber)}
.notif-type-badge.ORDER_DELIVERED{background:var(--green-bg);color:var(--green)}
.notif-type-badge.EARNINGS_CREDITED{background:var(--green-bg);color:var(--green)}
.notif-type-badge.SHIFT_STARTING{background:var(--blue-bg);color:var(--blue)}
.notif-type-badge.SHIFT_EXPIRED{background:var(--red-bg);color:var(--red)}
.notif-type-badge.COD_REMINDER{background:var(--amber-bg);color:var(--amber)}
.notif-type-badge.WALLET_LOW{background:var(--red-bg);color:var(--red)}
.notif-type-badge.SLOT_BOOKED{background:var(--brand-lt);color:var(--brand)}
.notif-type-badge.RATING_RECEIVED{background:var(--teal-bg);color:var(--teal)}
.notif-type-badge.SHIFT_ACTIVE{background:var(--green-bg);color:var(--green)}
.notif-type-badge.SHIFT_EXPIRY_WARNING{background:var(--amber-bg);color:var(--amber)}
.notif-shimmer{animation:shimmer 1.4s infinite linear;background:linear-gradient(90deg,var(--surface) 25%,var(--border) 50%,var(--surface) 75%);background-size:200% 100%;border-radius:8px}
@keyframes shimmer{0%{background-position:200% 0}100%{background-position:-200% 0}}
.ncard-skeleton{height:72px;margin-bottom:8px;border-radius:12px}

    /* ── CONFIRM MODAL ── */
    .confirm-overlay {
      display: none; position: fixed; inset: 0;
      background: rgba(0,0,0,0.45); z-index: 9000;
      align-items: center; justify-content: center; padding: 1rem;
    }
    .confirm-overlay.open { display: flex; }
    .confirm-modal {
      background: #fff; border-radius: var(--radius);
      box-shadow: 0 12px 40px rgba(0,0,0,0.18);
      width: 100%; max-width: 380px;
      animation: slideDown 0.22s ease; overflow: hidden;
    }
    .cm-head {
      padding: 18px 20px 14px;
      border-bottom: 1px solid var(--border);
      font-size: 15px; font-weight: 700; color: var(--text1);
      display: flex; align-items: center; gap: 10px;
    }
    .cm-body  { padding: 16px 20px; font-size: 14px; color: var(--text2); line-height: 1.6; }
    .cm-order-info {
      background: var(--surface); border: 1px solid var(--border);
      border-radius: var(--radius-sm); padding: 10px 14px; margin: 10px 0;
      font-size: 13px; display: flex; flex-direction: column; gap: 4px;
    }
    .cm-footer {
      padding: 12px 20px; border-top: 1px solid var(--border);
      display: flex; gap: 8px; justify-content: flex-end;
    }
    .cm-btn {
      padding: 8px 20px; border-radius: var(--radius-sm);
      font-size: 13px; font-weight: 600; cursor: pointer;
      font-family: var(--font); border: 1px solid; transition: all 0.18s;
    }
    .cm-cancel { background: #fff; color: var(--text2); border-color: var(--border); }
    .cm-cancel:hover { background: var(--surface); }
    .cm-confirm { background: var(--brand); color: #fff; border-color: var(--brand); }
    .cm-confirm:hover { background: var(--brand-dk); }
    .cm-confirm.danger { background: var(--red); border-color: var(--red); }
    .cm-confirm.danger:hover { background: #b71c1c; }

    /* ── CANCEL REASON PANEL ── */
    .cancel-reason-box {
      background: var(--red-bg); border: 1px solid #EF9A9A;
      border-radius: var(--radius-sm); padding: 12px 14px; margin-top: 8px;
    }
    .cancel-reason-label { font-size: 12px; font-weight: 700; color: var(--red); margin-bottom: 6px; text-transform: uppercase; letter-spacing: 0.04em; }
    .cancel-reason-select {
      width: 100%; border: 1px solid #EF9A9A; border-radius: var(--radius-sm);
      padding: 7px 10px; font-family: var(--font); font-size: 13px;
      color: var(--text1); background: #fff; outline: none;
      margin-bottom: 6px;
    }
    .cancel-reason-select:focus { border-color: var(--red); }
    .cancel-note-input {
      width: 100%; border: 1px solid #EF9A9A; border-radius: var(--radius-sm);
      padding: 7px 10px; font-family: var(--font); font-size: 13px;
      color: var(--text1); background: #fff; outline: none; resize: none;
    }

    /* ── COD COLLECTED BADGE ── */
    .cod-collected-badge {
      display: inline-flex; align-items: center; gap: 5px;
      background: var(--green-bg); color: var(--green);
      border: 1px solid #A5D6A7; border-radius: 20px;
      padding: 3px 10px; font-size: 11px; font-weight: 700;
    }

    /* ── CUSTOMER QUICK CONTACT ── */
    .quick-contact {
      display: flex; gap: 6px; margin: 8px 0 4px; flex-wrap: wrap;
    }
    .qc-btn {
      display: inline-flex; align-items: center; gap: 5px;
      padding: 5px 12px; border-radius: 20px; font-size: 12px;
      font-weight: 600; border: 1px solid; text-decoration: none;
      font-family: var(--font); transition: all 0.18s; cursor: pointer;
    }
    .qc-call { background: var(--green-bg); color: var(--green); border-color: #A5D6A7; }
    .qc-call:hover { background: #c8e6c9; text-decoration: none; }
    .qc-map  { background: var(--blue-bg); color: var(--blue); border-color: #90CAF9; }
    .qc-map:hover  { background: #bbdefb; text-decoration: none; }
    .qc-whatsapp { background: #E8F5E9; color: #1B5E20; border-color: #A5D6A7; }
    .qc-whatsapp:hover { background: #c8e6c9; text-decoration: none; }

    /* ── TODAY SUMMARY BAR ── */
    .today-bar {
      background: linear-gradient(135deg, var(--brand-lt) 0%, #fff 100%);
      border: 1px solid var(--border); border-radius: var(--radius);
      padding: 14px 20px; margin-bottom: 20px;
      display: flex; align-items: center; gap: 20px; flex-wrap: wrap;
      box-shadow: var(--shadow);
    }
    .today-bar-item { display: flex; flex-direction: column; gap: 2px; }
    .tbi-label { font-size: 11px; color: var(--text3); text-transform: uppercase; letter-spacing: 0.06em; }
    .tbi-val   { font-size: 16px; font-weight: 700; color: var(--text1); }
    .today-bar-divider { width: 1px; height: 32px; background: var(--border); }

    /* ── PRIORITY TAG ── */
    .priority-urgent {
      display: inline-flex; align-items: center; gap: 4px;
      background: #FFEBEE; color: var(--red); border: 1px solid #EF9A9A;
      border-radius: 20px; padding: 2px 8px; font-size: 10px; font-weight: 700;
    }
    .priority-normal {
      display: inline-flex; align-items: center; gap: 4px;
      background: var(--green-bg); color: var(--green); border: 1px solid #A5D6A7;
      border-radius: 20px; padding: 2px 8px; font-size: 10px; font-weight: 700;
    }

    /* ── EARNINGS CHART BAR ── */
    .earn-bar-wrap { margin-top: 8px; }
    .earn-bar-row  { display: flex; align-items: center; gap: 10px; margin-bottom: 8px; font-size: 12px; }
    .earn-bar-label { width: 28px; color: var(--text3); }
    .earn-bar-track { flex: 1; height: 7px; background: var(--border); border-radius: 4px; overflow: hidden; }
    .earn-bar-fill  { height: 100%; border-radius: 4px; background: var(--brand); transition: width 0.8s ease; }
    .earn-bar-amt   { width: 52px; text-align: right; color: var(--text1); font-weight: 600; }
	/* ── View toggle ────────────────────────────────────────────────────────── */
	.history-view-toggle {
	  display: flex; gap: 8px; margin: 0 0 20px;
	}
	.hvt-btn {
	  display: flex; align-items: center; gap: 6px;
	  padding: 8px 18px; border-radius: 8px; border: 1.5px solid var(--border);
	  background: var(--card-bg); color: var(--text2);
	  font-size: 13px; font-weight: 600; cursor: pointer; transition: all .2s;
	}
	.hvt-btn.active {
	  background: var(--brand); color: #fff; border-color: var(--brand);
	}
	.hvt-btn:hover:not(.active) { border-color: var(--brand); color: var(--brand); }
	
	/* ── Section wrapper ────────────────────────────────────────────────────── */
	.slot-section { margin-bottom: 28px; }
	
	.slot-section-header {
	  display: flex; align-items: center; gap: 10px;
	  padding: 10px 16px; border-radius: 10px; margin-bottom: 14px;
	  font-size: 14px;
	}
	.sa-header { background: rgba(59,130,246,.08); border: 1px solid rgba(59,130,246,.2); }
	.sb-header { background: rgba(16,185,129,.08); border: 1px solid rgba(16,185,129,.2); }
	.sc-header { background: rgba(239,68,68,.08);  border: 1px solid rgba(239,68,68,.2);  }
	
	.slot-section-dot {
	  width: 10px; height: 10px; border-radius: 50%; flex-shrink: 0;
	}
	.dot-booked    { background: #3B82F6; }
	.dot-active    { background: #10B981; }
	.dot-cancelled { background: #EF4444; }
	
	.slot-section-title { font-weight: 700; color: var(--text1); }
	.slot-section-count {
	  background: var(--border); color: var(--text2);
	  font-size: 12px; font-weight: 700; padding: 2px 8px; border-radius: 20px;
	}
	.slot-section-sub { font-size: 12px; color: var(--text3); margin-left: auto; }
	
	/* ── Slot card grid ─────────────────────────────────────────────────────── */
	.slot-grid {
	  display: grid;
	  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
	  gap: 14px;
	}
	
	.slot-card {
	  border-radius: 12px; border: 1.5px solid var(--border);
	  background: var(--card-bg); padding: 16px;
	  transition: box-shadow .2s, transform .15s;
	}
	.slot-card:hover { box-shadow: 0 4px 20px rgba(0,0,0,.1); transform: translateY(-1px); }
	
	.sc-booked    { border-left: 4px solid #3B82F6; }
	.sc-completed { border-left: 4px solid #10B981; }
	.sc-cancelled { border-left: 4px solid #EF4444; }
	
	/* ── Card inner elements ────────────────────────────────────────────────── */
	.sc-top { display: flex; flex-wrap: wrap; align-items: center; gap: 8px; margin-bottom: 12px; }
	
	.sc-slot-badge {
	  display: inline-flex; align-items: center; gap: 5px;
	  font-size: 11px; font-weight: 700; padding: 3px 10px; border-radius: 20px;
	}
	.badge-booked    { background: rgba(59,130,246,.12); color: #3B82F6; }
	.badge-completed { background: rgba(16,185,129,.12); color: #10B981; }
	.badge-cancelled { background: rgba(239,68,68,.12);  color: #EF4444; }
	.badge-expired   { background: rgba(245,158,11,.12); color: #F59E0B; }
	
	.sc-slot-meta { font-size: 13px; font-weight: 600; color: var(--text1); }
	.sc-zone { font-size: 12px; color: var(--text3); display: flex; align-items: center; gap: 4px; }
	
	.sc-counters {
	  display: flex; gap: 12px; margin: 10px 0;
	  padding: 10px 0; border-top: 1px solid var(--border); border-bottom: 1px solid var(--border);
	}
	.sc-counter-item { display: flex; flex-direction: column; align-items: center; flex: 1; }
	.sc-counter-val  { font-size: 20px; font-weight: 800; color: var(--text1); line-height: 1; }
	.sc-counter-lbl  { font-size: 10px; color: var(--text3); margin-top: 2px; text-transform: uppercase; letter-spacing: .5px; }
	.sc-val-green { color: #10B981; }
	.sc-val-amber { color: #F59E0B; }
	.sc-val-blue  { color: #3B82F6; }
	
	.sc-completed-at,
	.sc-cancelled-reason {
	  font-size: 12px; color: var(--text3);
	  display: flex; align-items: center; gap: 6px; margin: 8px 0;
	}
	
	/* ── Expand button ──────────────────────────────────────────────────────── */
	.sc-expand-btn {
	  width: 100%; margin-top: 10px; padding: 7px;
	  background: var(--bg2); border: 1px solid var(--border);
	  border-radius: 8px; color: var(--text2); font-size: 12px; font-weight: 600;
	  cursor: pointer; display: flex; align-items: center; justify-content: center; gap: 6px;
	  transition: background .15s;
	}
	.sc-expand-btn:hover { background: var(--border); }
	.sc-expand-btn.open .bi-chevron-down { transform: rotate(180deg); }
	.sc-expand-btn .bi { transition: transform .2s; }
	
	/* ── Sub-grid ───────────────────────────────────────────────────────────── */
	.slot-subgrid { margin-top: 10px; overflow-x: auto; }
	.subgrid-table {
	  width: 100%; border-collapse: collapse; font-size: 12px;
	}
	.subgrid-table th {
	  background: var(--bg2); color: var(--text3); font-weight: 600;
	  text-transform: uppercase; letter-spacing: .4px; font-size: 10px;
	  padding: 6px 10px; text-align: left; white-space: nowrap;
	}
	.subgrid-table td {
	  padding: 8px 10px; border-bottom: 1px solid var(--border);
	  color: var(--text1); vertical-align: middle;
	}
	.subgrid-table tr:last-child td { border-bottom: none; }
	.subgrid-table tr:hover td { background: var(--bg2); }
	
	/* COD warning row highlight */
	.sg-row-cod-warn td { background: rgba(245,158,11,.05); }
	.sg-row-cod-warn:hover td { background: rgba(245,158,11,.1); }
	
	.sg-order-id { font-weight: 700; color: var(--brand); }
	.sg-address  { max-width: 180px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
	.sg-amount   { white-space: nowrap; }
	
	.sg-status-badge {
	  display: inline-block; padding: 2px 8px; border-radius: 20px;
	  font-size: 10px; font-weight: 700; text-transform: capitalize; white-space: nowrap;
	}
	.sg-status-delivered       { background: rgba(16,185,129,.12); color: #10B981; }
	.sg-status-cancelled       { background: rgba(239,68,68,.12);  color: #EF4444; }
	.sg-status-assigned        { background: rgba(59,130,246,.12); color: #3B82F6; }
	.sg-status-out-for-delivery { background: rgba(139,92,246,.12); color: #8B5CF6; }
	.sg-status-picked-up       { background: rgba(245,158,11,.12); color: #F59E0B; }
	.sg-status-pending         { background: rgba(107,114,128,.12);color: #6B7280; }
	
	.sg-pay-badge {
	  display: inline-block; padding: 2px 8px; border-radius: 20px;
	  font-size: 10px; font-weight: 700; white-space: nowrap;
	}
	.sg-badge-prepaid   { background: rgba(16,185,129,.12);  color: #10B981; }
	.sg-badge-cod       { background: rgba(245,158,11,.18);  color: #D97706; }
	.sg-badge-deposited { background: rgba(16,185,129,.12);  color: #10B981; }
	
	/* ── Empty state ────────────────────────────────────────────────────────── */
	.slot-empty-state {
	  display: flex; flex-direction: column; align-items: center;
	  padding: 32px; color: var(--text3); font-size: 13px; gap: 8px;
	  border: 1.5px dashed var(--border); border-radius: 12px;
	}
	
	/* ── Responsive ─────────────────────────────────────────────────────────── */
	@media (max-width: 520px) {
	  .slot-grid { grid-template-columns: 1fr; }
	  .slot-section-sub { display: none; }
	  .hvt-btn span { display: none; }
	}
    /* ── MISC ── */
    .section-panel { background: var(--card); border: 1px solid var(--border); border-radius: var(--radius); overflow: hidden; box-shadow: var(--shadow); }
    .panel-head { padding: 14px 18px; border-bottom: 1px solid var(--border); font-size: 14px; font-weight: 700; color: var(--text1); }
    .overlay { display: none; position: fixed; inset: 0; background: rgba(0,0,0,0.3); z-index: 190; }
    .overlay.open { display: block; }

    .logout-btn {
      display: flex; align-items: center; gap: 8px;
      width: 100%; padding: 9px 20px; border: none; background: none;
      color: var(--red); font-family: var(--font); font-size: 14px;
      cursor: pointer; text-align: left; transition: background 0.15s;
    }
    .logout-btn:hover { background: var(--red-bg); }
    .wallet-header {
  display: flex; align-items: center; justify-content: space-between;
  margin-bottom: 20px;
}
.wallet-header h2 { margin: 0; font-size: 1.35rem; color: var(--brand); }
.btn-refresh {
  background: var(--brand-pale); border: none; border-radius: 50%;
  width: 36px; height: 36px; cursor: pointer; color: var(--brand);
  font-size: .9rem; transition: transform .3s;
}
.btn-refresh:hover { transform: rotate(180deg); }

/* ── status banner ── */
.wallet-banner {
  padding: 12px 18px; border-radius: var(--radius); margin-bottom: 18px;
  font-weight: 600; font-size: .95rem;
}
.wallet-banner.danger  { background: #fdecea; color: var(--red); border-left: 4px solid var(--red); }
.wallet-banner.warning { background: #fef9ec; color: var(--orange); border-left: 4px solid var(--orange); }

/* ── cards row ── */
.wallet-cards-row {
  display: grid; grid-template-columns: 2fr 1fr 1fr; gap: 16px;
  margin-bottom: 20px;
}
@media(max-width:720px) { .wallet-cards-row { grid-template-columns: 1fr; } }

.wcard {
  background: #fff; border: 1px solid var(--border); border-radius: var(--radius);
  padding: 20px 22px; box-shadow: var(--shadow);
}
.wcard-main { border-left: 4px solid var(--brand); }
.wcard-earned { border-left: 4px solid var(--green); }
.wcard-withdrawn { border-left: 4px solid var(--orange); }

.wcard-label { font-size: .78rem; text-transform: uppercase; letter-spacing: .06em; color: var(--muted); margin-bottom: 6px; }
.wcard-value { font-size: 1.9rem; font-weight: 700; color: var(--text); margin-bottom: 4px; }
.wcard-sub   { font-size: .8rem; color: var(--muted); }

.wcard-progress-wrap { margin-top: 14px; }
.wcard-progress-track {
  height: 7px; background: #ece8f8; border-radius: 4px; overflow: hidden; margin-bottom: 4px;
}
.wcard-progress-bar {
  height: 100%; border-radius: 4px; background: var(--brand);
  transition: width .5s ease;
}
.wcard-progress-label { font-size: .75rem; color: var(--muted); }

/* ── earnings strip ── */
.earnings-strip {
  display: flex; align-items: center; background: var(--brand);
  border-radius: var(--radius); padding: 18px 28px; margin-bottom: 20px;
  box-shadow: var(--shadow); gap: 0;
}
.estrip-item { flex: 1; text-align: center; }
.estrip-val  { font-size: 1.4rem; font-weight: 700; color: #fff; }
.estrip-lbl  { font-size: .78rem; color: rgba(255,255,255,.75); margin-top: 2px; }
.estrip-sep  { width: 1px; height: 40px; background: rgba(255,255,255,.25); }

/* ── bar chart ── */
.wchart-wrap {
  background: #fff; border: 1px solid var(--border); border-radius: var(--radius);
  padding: 20px 22px; box-shadow: var(--shadow); margin-bottom: 20px;
}
.wchart-title { font-size: .85rem; font-weight: 600; color: var(--brand); margin-bottom: 14px; }
.wchart {
  display: flex; align-items: flex-end; gap: 8px; height: 90px;
}
.wchart-bar-wrap { flex: 1; display: flex; flex-direction: column; align-items: center; gap: 4px; }
.wchart-bar {
  width: 100%; border-radius: 4px 4px 0 0; background: var(--brand-pale);
  transition: height .5s ease; position: relative; min-height: 4px;
}
.wchart-bar.active { background: var(--brand); }
.wchart-bar-tip {
  position: absolute; top: -22px; left: 50%; transform: translateX(-50%);
  background: var(--text); color: #fff; font-size: .65rem; padding: 2px 5px;
  border-radius: 4px; white-space: nowrap; opacity: 0; pointer-events: none;
  transition: opacity .2s;
}
.wchart-bar:hover .wchart-bar-tip { opacity: 1; }
.wchart-days {
  display: flex; gap: 8px; margin-top: 6px;
}
.wchart-day-lbl { flex: 1; text-align: center; font-size: .68rem; color: var(--muted); }

/* ── actions row ── */
.wallet-actions { margin-bottom: 24px; }
.btn-withdraw {
  background: var(--brand); color: #fff; border: none; border-radius: 8px;
  padding: 11px 28px; font-size: .95rem; font-weight: 600; cursor: pointer;
  transition: background .2s;
}
.btn-withdraw:hover { background: var(--brand-light); }
.btn-withdraw:disabled { background: #b9a8e0; cursor: not-allowed; }

/* ── transactions ── */
.wtxn-section h3 { font-size: 1rem; color: var(--brand); margin-bottom: 12px; }
.wtxn-table-wrap { overflow-x: auto; border-radius: var(--radius); box-shadow: var(--shadow); }
.wtxn-table {
  width: 100%; border-collapse: collapse; background: #fff;
  font-size: .85rem;
}
.wtxn-table th {
  background: var(--brand); color: #fff; padding: 11px 14px;
  text-align: left; font-weight: 600; white-space: nowrap;
}
.wtxn-table td {
  padding: 10px 14px; border-bottom: 1px solid #f0edf9; color: var(--text);
}
.wtxn-table tr:last-child td { border-bottom: none; }
.wtxn-table tr:hover td { background: var(--brand-pale); }
.wtxn-empty { text-align: center; color: var(--muted); padding: 28px !important; }

.txn-badge {
  display: inline-block; padding: 3px 9px; border-radius: 12px;
  font-size: .75rem; font-weight: 600;
}
.txn-badge.credit      { background: #e9f7ef; color: var(--green); }
.txn-badge.debit       { background: #fdecea; color: var(--red); }
.txn-badge.cod_hold    { background: #fef9ec; color: var(--orange); }
.txn-badge.cod_release { background: #e9f7ef; color: var(--green); }
.txn-badge.withdrawal  { background: #eaf3fb; color: #2980b9; }
.txn-badge.bonus       { background: #f0ebff; color: var(--brand); }

.txn-amt.credit  { color: var(--green); font-weight: 700; }
.txn-amt.debit   { color: var(--red);   font-weight: 700; }

.wtxn-pagination {
  display: flex; align-items: center; gap: 14px; margin-top: 14px; justify-content: center;
}
.btn-page {
  background: var(--brand-pale); color: var(--brand); border: 1px solid var(--border);
  border-radius: 6px; padding: 7px 18px; cursor: pointer; font-size: .85rem;
}
.btn-page:disabled { opacity: .4; cursor: not-allowed; }
#wPageLabel { font-size: .85rem; color: var(--muted); }

/* ── modal ── */
.wmodal-overlay {
  position: fixed; inset: 0; background: rgba(0,0,0,.45);
  display: none; align-items: center; justify-content: center; z-index: 9999;
}
.wmodal {
  background: #fff; border-radius: var(--radius); width: 400px; max-width: 94vw;margin:1px;
  box-shadow: 0 8px 40px rgba(0,0,0,.2); overflow: hidden;
}
.wmodal-header {
  display: flex; align-items: center; justify-content: space-between;
  background: var(--brand); color: #fff; padding: 16px 20px;
}
.wmodal-header h3 { margin: 0; font-size: 1rem; }
.wmodal-close { background: none; border: none; color: #fff; font-size: 1.4rem; cursor: pointer; }
.wmodal-body { padding: 22px 20px; }
.wmodal-body label { display: block; font-size: .85rem; font-weight: 600; color: var(--text); margin-bottom: 6px; }
.wmodal-body input {
  width: 100%; box-sizing: border-box; padding: 10px 14px; border: 1px solid var(--border);
  border-radius: 8px; font-size: 1rem; color: var(--text); outline: none;
}
.wmodal-body input:focus { border-color: var(--brand); }
.wmodal-hint { font-size: .9rem; color: var(--muted); margin: 0 0 16px; }
.wmodal-note { font-size: .78rem; color: var(--muted); margin-top: 10px; }
.wmodal-footer {
  display: flex; gap: 12px; padding: 14px 20px; background: #faf9ff;
  border-top: 1px solid var(--border); justify-content: flex-end;
}
.btn-topup {
  display: inline-flex; align-items: center; gap: 8px;
  background: linear-gradient(135deg, #27ae60 0%, #1e8449 100%);
  color: #fff; border: none; border-radius: 8px;
  padding: 11px 28px; font-size: .95rem; font-weight: 600;
  cursor: pointer; font-family: var(--font);
  box-shadow: 0 2px 8px rgba(39,174,96,0.25);
  transition: all 0.2s;
}
.btn-topup:hover {
  background: linear-gradient(135deg, #1e8449 0%, #196f3d 100%);
  box-shadow: 0 4px 14px rgba(39,174,96,0.35);
  transform: translateY(-1px);
}

/* ── LOW BALANCE BANNER ───────────────────────────────────────── */
.wallet-banner.topup-required {
  background: linear-gradient(135deg, #fff8e1 0%, #fff3cd 100%);
  color: #7d4e00;
  border-left: 4px solid #f39c12;
  display: flex; align-items: center; justify-content: space-between;
  flex-wrap: wrap; gap: 10px;
}
.wallet-banner.topup-required .banner-action {
  background: #f39c12; color: #fff;
  border: none; border-radius: 6px;
  padding: 6px 16px; font-size: .82rem; font-weight: 700;
  cursor: pointer; font-family: var(--font);
  white-space: nowrap; transition: background .2s;
}
.wallet-banner.topup-required .banner-action:hover { background: #d68910; }

/* ── OFFLINE BANNER ───────────────────────────────────────────── */
.wallet-banner.offline-blocked {
  background: linear-gradient(135deg, #fdecea 0%, #ffebee 100%);
  color: #b71c1c;
  border-left: 4px solid var(--red);
  display: flex; align-items: center; justify-content: space-between;
  flex-wrap: wrap; gap: 10px;
}
.wallet-banner.offline-blocked .banner-action {
  background: var(--red); color: #fff;
  border: none; border-radius: 6px;
  padding: 6px 16px; font-size: .82rem; font-weight: 700;
  cursor: pointer; font-family: var(--font); white-space: nowrap;
  transition: background .2s;
}
.wallet-banner.offline-blocked .banner-action:hover { background: #8b0000; }

/* ── TOP-UP MODAL ─────────────────────────────────────────────── */
.topup-modal-overlay {
  position: fixed; inset: 0; background: rgba(0,0,0,.5);
  display: none; align-items: center; justify-content: center;
  z-index: 9999; padding: 1rem;
}
.topup-modal-overlay.open { display: flex; }

.topup-modal {
  background: #fff; border-radius: 16px;
  width: 100%; max-width: 450px;
  box-shadow: 0 20px 60px rgba(0,0,0,.2);
  overflow: hidden;
  animation: slideUp 0.25s cubic-bezier(0.34,1.56,0.64,1);
  
}
@keyframes slideUp {
  from { opacity:0; transform: translateY(24px) scale(.97); }
  to   { opacity:1; transform: translateY(0)   scale(1); }
}

.topup-modal-head {
  background: linear-gradient(135deg, #1e8449 0%, #27ae60 100%);
  padding: 22px 24px 18px; color: #fff;
}
.topup-modal-head h3 {
  margin: 0 0 4px; font-size: 1.15rem; font-weight: 700;
  display: flex; align-items: center; gap: 10px;
}
.topup-modal-head p {
  margin: 0; font-size: .82rem; opacity: .85;
}

/* Balance strip inside modal */
.topup-balance-strip {
  display: flex; gap: 0; margin-top: 14px;
  background: rgba(255,255,255,.15); border-radius: 10px; overflow: hidden;
}
.topup-bal-item {
  flex: 1; padding: 9px 12px; text-align: center;
  border-right: 1px solid rgba(255,255,255,.2);
}
.topup-bal-item:last-child { border-right: none; }
.topup-bal-val { font-size: 1.1rem; font-weight: 700; color: #fff; }
.topup-bal-lbl { font-size: .68rem; opacity: .8; margin-top: 1px; }

.topup-modal-body { padding: 22px 24px; }

/* Quick amount buttons */
.topup-quick-label {
  font-size: .78rem; font-weight: 700; color: var(--text3);
  text-transform: uppercase; letter-spacing: .06em; margin-bottom: 10px;
}
.topup-quick-grid {
  display: grid; grid-template-columns: repeat(4, 1fr); gap: 8px;
  margin-bottom: 18px;
}
.topup-quick-btn {
  padding: 9px 4px; border-radius: 8px; font-size: .82rem; font-weight: 600;
  border: 1.5px solid var(--border); background: #fff; color: var(--text2);
  cursor: pointer; font-family: var(--font); text-align: center;
  transition: all .18s;
}
.topup-quick-btn:hover,
.topup-quick-btn.selected {
  border-color: #27ae60; background: #e8f5e9; color: #1e8449;
}

/* Custom amount input */
.topup-input-wrap {
  position: relative; margin-bottom: 16px;
}
.topup-input-prefix {
  position: absolute; left: 14px; top: 50%; transform: translateY(-50%);
  font-size: 1rem; font-weight: 700; color: var(--text3);
  pointer-events: none;
}
.topup-amount-input {
  width: 100%; box-sizing: border-box;
  padding: 12px 14px 12px 30px;
  border: 1.5px solid var(--border); border-radius: 10px;
  font-size: 1.1rem; font-weight: 600; color: var(--text1);
  outline: none; font-family: var(--font);
  transition: border-color .2s;
}
.topup-amount-input:focus { border-color: #27ae60; }

/* Breakdown hint */
.topup-breakdown {
  background: #f0faf4; border: 1px solid #a9dfbf;
  border-radius: 8px; padding: 11px 14px; margin-bottom: 16px;
  font-size: .82rem; color: #1e8449; display: none;
}
.topup-breakdown.visible { display: block; }
.topup-breakdown table { width: 100%; border-collapse: collapse; }
.topup-breakdown td { padding: 2px 0; }
.topup-breakdown td:last-child { text-align: right; font-weight: 600; }
.topup-breakdown tr.highlight td { font-size: .88rem; color: #145a32; font-weight: 700; border-top: 1px solid #a9dfbf; padding-top: 5px; }

/* Purpose info */
.topup-purpose-info {
  background: #fff8e1; border: 1px solid #ffe082;
  border-radius: 8px; padding: 10px 13px; margin-bottom: 18px;
  font-size: .8rem; color: #7d4e00;
  display: flex; align-items: flex-start; gap: 8px;
}
.topup-purpose-info i { margin-top: 1px; flex-shrink: 0; }

.topup-modal-footer {
  display: flex; gap: 10px; padding: 14px 24px 20px;
  border-top: 1px solid var(--border);
}
.topup-cancel-btn {
  flex: 1; padding: 11px; border-radius: 8px; font-size: .92rem; font-weight: 600;
  background: #f0edf9; color: var(--brand); border: none; cursor: pointer;
  font-family: var(--font); transition: background .18s;
}
.topup-cancel-btn:hover { background: #e2dcf7; }
.topup-pay-btn {
  flex: 2; padding: 11px; border-radius: 8px; font-size: .92rem; font-weight: 700;
  background: linear-gradient(135deg, #1e8449 0%, #27ae60 100%);
  color: #fff; border: none; cursor: pointer;
  font-family: var(--font); transition: all .2s;
  display: flex; align-items: center; justify-content: center; gap: 8px;
  box-shadow: 0 2px 8px rgba(39,174,96,.25);
}
.topup-pay-btn:hover:not(:disabled) {
  background: linear-gradient(135deg, #196f3d 0%, #1e8449 100%);
  box-shadow: 0 4px 14px rgba(39,174,96,.35);
}
.topup-pay-btn:disabled { opacity: .55; cursor: not-allowed; }

/* Processing state */
.topup-processing {
  text-align: center; padding: 32px 24px;
}
.topup-spinner {
  width: 48px; height: 48px; border-radius: 50%;
  border: 4px solid #e8f5e9;
  border-top-color: #27ae60;
  animation: spin 0.8s linear infinite;
  margin: 0 auto 16px;
}
@keyframes spin { to { transform: rotate(360deg); } }
.topup-processing p { font-size: .92rem; color: var(--text2); margin: 0; }

/* Success state */
.topup-success {
  text-align: center; padding: 32px 24px; display: none;
}
.topup-success-icon {
  width: 64px; height: 64px; border-radius: 50%;
  background: linear-gradient(135deg, #27ae60, #1e8449);
  display: flex; align-items: center; justify-content: center;
  margin: 0 auto 16px; font-size: 28px; color: #fff;
  animation: popIn .4s cubic-bezier(0.34,1.56,0.64,1);
}
@keyframes popIn {
  from { transform: scale(0); opacity: 0; }
  to   { transform: scale(1); opacity: 1; }
}
.topup-success h4 { font-size: 1.1rem; color: var(--text1); margin: 0 0 6px; }
.topup-success p  { font-size: .85rem; color: var(--text3); margin: 0; }

/* Failed state */
.topup-failed {
  text-align: center; padding: 28px 24px; display: none;
}
.topup-failed-icon {
  width: 56px; height: 56px; border-radius: 50%;
  background: #fdecea; display: flex; align-items: center; justify-content: center;
  margin: 0 auto 12px; font-size: 24px; color: var(--red);
}
.topup-failed p { font-size: .85rem; color: var(--text2); margin: 0 0 14px; }
.topup-retry-btn {
  background: var(--brand); color: #fff; border: none; border-radius: 7px;
  padding: 9px 24px; font-size: .88rem; font-weight: 600;
  cursor: pointer; font-family: var(--font);
}

/* Razorpay badge */
.razorpay-badge {
  display: flex; align-items: center; justify-content: center; gap: 6px;
  font-size: .72rem; color: var(--text3); margin-top: 10px; padding-bottom: 2px;
}
.razorpay-badge img { height: 16px; opacity: .7; }
.btn-cancel  { background: #f0edf9; color: var(--brand); border: none; border-radius: 7px; padding: 9px 22px; cursor: pointer; }
.btn-confirm { background: var(--brand); color: #fff; border: none; border-radius: 7px; padding: 9px 22px; cursor: pointer; font-weight: 600; }
.btn-confirm:hover { background: var(--brand-light); }

    /* ── SIDEBAR TOGGLE (desktop) ─────────────────── */
    .sidebar-toggle-btn:hover { background: var(--brand-lt) !important; color: var(--brand) !important; }

    body.sidebar-collapsed .sidebar { transform: translateX(-220px); }
    body.sidebar-collapsed .topbar  { left: 0; }
    body.sidebar-collapsed .main    { margin-left: 0; }

    /* ── TOOLTIP ─────────────────────────────────── */
    [title] { position: relative; }
    .has-tooltip { position: relative; }
    .has-tooltip::after {
      content: attr(data-tooltip);
      position: absolute; bottom: calc(100% + 6px); left: 50%;
      transform: translateX(-50%);
      background: var(--text1); color: #fff; font-size: 11px;
      padding: 4px 8px; border-radius: 5px; white-space: nowrap;
      pointer-events: none; opacity: 0; transition: opacity 0.18s;
      z-index: 9999;
    }
    .has-tooltip:hover::after { opacity: 1; }
.kyc-banner {
  display: flex; align-items: flex-start; gap: 14px;
  padding: 16px 20px; border-radius: var(--radius);
  margin-bottom: 20px; font-size: 14px;
}
.kyc-banner.pending  { background: var(--amber-bg); color: var(--amber);  border: 1px solid #ffe0b2; }
.kyc-banner.approved { background: var(--green-bg); color: var(--green);  border: 1px solid #c8e6c9; }
.kyc-banner.rejected { background: var(--red-bg);   color: var(--red);    border: 1px solid #ffcdd2; }
.kyc-banner.missing  { background: var(--blue-bg);  color: var(--blue);   border: 1px solid #bbdefb; }
.kyc-banner-ico { font-size: 24px; flex-shrink: 0; margin-top: 1px; }
.kyc-banner-body strong { display: block; font-size: 15px; font-weight: 700; margin-bottom: 3px; }
.kyc-banner-body span   { font-size: 13px; opacity: 0.9; }

/* ── PROFILE AVATAR (bigger) ─────────────────────────────────────────── */
.p-avatar-lg {
  width: 88px; height: 88px; border-radius: 50%;
  background: var(--brand); color: #fff;
  font-size: 32px; font-weight: 700;
  display: flex; align-items: center; justify-content: center;
  margin: 0 auto 14px; border: 4px solid var(--brand-lt);
  box-shadow: 0 4px 16px rgba(124,92,191,0.2);
}

/* ── KYC SECTION TABS ────────────────────────────────────────────────── */
.kyc-tabs {
  display: flex; gap: 4px; flex-wrap: wrap;
  border-bottom: 2px solid var(--border); margin-bottom: 20px;
}
.kyc-tab {
  padding: 8px 18px; font-size: 13px; font-weight: 600;
  border: none; background: none; cursor: pointer;
  font-family: var(--font); color: var(--text3);
  border-bottom: 3px solid transparent; margin-bottom: -2px;
  border-radius: 4px 4px 0 0; transition: all 0.18s;
  display: flex; align-items: center; gap: 6px;
}
.kyc-tab:hover { color: var(--text1); background: var(--brand-lt); }
.kyc-tab.active { color: var(--brand); border-bottom-color: var(--brand); }
.kyc-tab-panel { display: none; }
.kyc-tab-panel.active { display: block; }

/* ── DOCUMENT STATUS CHIPS ───────────────────────────────────────────── */
.doc-chip {
  display: inline-flex; align-items: center; gap: 5px;
  padding: 3px 10px; border-radius: 20px; font-size: 11px; font-weight: 700;
}
.doc-chip.verified { background: var(--green-bg); color: var(--green); }
.doc-chip.pending  { background: var(--amber-bg); color: var(--amber); }
.doc-chip.rejected { background: var(--red-bg);   color: var(--red);   }
.doc-chip.missing  { background: #f5f5f5;          color: var(--text3); }

/* ── KYC CTA CARD (redirect to register page) ────────────────────────── */
.kyc-cta-card {
  background: var(--card); border: 1px solid var(--border);
  border-radius: var(--radius); box-shadow: var(--shadow);
  overflow: hidden; margin-top: 8px;
}
.kyc-cta-header {
  padding: 28px 32px 24px;
  display: flex; align-items: flex-start; gap: 20px;
}
.kyc-cta-icon-wrap {
  width: 60px; height: 60px; border-radius: 16px; flex-shrink: 0;
  display: flex; align-items: center; justify-content: center; font-size: 26px;
}
.kyc-cta-icon-wrap.blue    { background: var(--blue-bg);  color: var(--blue);  }
.kyc-cta-icon-wrap.amber   { background: var(--amber-bg); color: var(--amber); }
.kyc-cta-icon-wrap.red     { background: var(--red-bg);   color: var(--red);   }
.kyc-cta-body { flex: 1; }
.kyc-cta-body h3 { font-size: 17px; font-weight: 700; color: var(--text1); margin: 0 0 6px; }
.kyc-cta-body p  { font-size: 13px; color: var(--text2); line-height: 1.6; margin: 0; }

.kyc-cta-steps {
  display: flex; gap: 0; padding: 0 32px 28px;
  flex-wrap: wrap;
}
.kyc-cta-step {
  display: flex; align-items: flex-start; gap: 12px;
  flex: 1; min-width: 180px; padding: 16px 14px;
  border-radius: var(--radius-sm);
  border: 1px solid var(--border);
  margin: 4px;
  background: #fafafa;
}
.kyc-cta-step-num {
  width: 28px; height: 28px; border-radius: 50%; flex-shrink: 0;
  display: flex; align-items: center; justify-content: center;
  font-size: 12px; font-weight: 800; color: #fff;
  background: var(--brand);
}
.kyc-cta-step-text strong { display: block; font-size: 13px; font-weight: 700; color: var(--text1); margin-bottom: 2px; }
.kyc-cta-step-text span   { font-size: 12px; color: var(--text3); }

.kyc-cta-footer {
  padding: 20px 32px; border-top: 1px solid var(--border);
  background: #f7f7fb;
  display: flex; align-items: center; justify-content: space-between;
  flex-wrap: wrap; gap: 14px;
}
.kyc-cta-footer-note { font-size: 12px; color: var(--text3); display: flex; align-items: center; gap: 6px; }
.btn-goto-register {
  display: inline-flex; align-items: center; gap: 10px;
  background: var(--brand); color: #fff;
  border: none; border-radius: var(--radius-sm);
  padding: 12px 28px; font-size: 14px; font-weight: 700;
  font-family: var(--font); cursor: pointer; text-decoration: none;
  transition: background 0.2s, transform 0.12s, box-shadow 0.2s;
  box-shadow: 0 4px 14px rgba(124,92,191,0.3);
  letter-spacing: 0.01em;
}
.btn-goto-register:hover  { background: var(--brand-dk); box-shadow: 0 6px 20px rgba(124,92,191,0.4); transform: translateY(-1px); color: #fff; text-decoration: none; }
.btn-goto-register:active { transform: scale(0.98); }
.btn-goto-register.amber  { background: var(--amber); box-shadow: 0 4px 14px rgba(245,158,11,0.3); }
.btn-goto-register.amber:hover { background: var(--amber-dk, #d97706); }
.btn-goto-register.red    { background: var(--red); box-shadow: 0 4px 14px rgba(239,68,68,0.3); }
.btn-goto-register.red:hover { background: #c53030; }

/* Rejection reason box */
.rejection-reason-box {
  margin: 0 32px 20px;
  padding: 14px 18px;
  background: #fff5f5; border: 1px solid #feb2b2;
  border-left: 4px solid var(--red);
  border-radius: var(--radius-sm);
  font-size: 13px; color: #c53030;
  line-height: 1.6;
}
.rejection-reason-box strong { display: block; margin-bottom: 4px; font-size: 12px; text-transform: uppercase; letter-spacing: 0.06em; }

    /* ── MOBILE TOP-LEFT MENU BTN ─────────────────── */
    .mob-menu-btn {
      display: none;
      align-items: center; justify-content: center;
      width: 38px; height: 38px; border-radius: 8px;
      border: 1px solid var(--border); background: #fff;
      cursor: pointer; color: var(--text2); font-size: 18px;
      transition: background 0.15s, color 0.15s;
    }
    .mob-menu-btn:hover { background: var(--brand-lt); color: var(--brand); }

    /* ── RESPONSIVE ───────────────────────────────── */
    @media (max-width: 768px) {
      :root { --sidebar-w: 0px; }
      .sidebar { transform: translateX(-220px); width: 220px; }
      .sidebar.open { transform: translateX(0); }
      .topbar { left: 0; padding: 0 14px; }
      .main { margin-left: 0; padding-bottom: 70px; }
      .page { padding: 16px 14px 30px; }
      .bottom-nav { display: block; }
      .mob-menu-btn { display: flex; }
      .profile-grid { grid-template-columns: 1fr; }
      .earn-grid { grid-template-columns: 1fr; }
      .orders-grid { grid-template-columns: 1fr; }
      .search-box { margin-left: 0; width: 100%; }
      .search-box input { width: 100%; }
      .filter-bar { gap: 6px; }
      .topbar-title { font-size: 16px; }
      .today-bar { gap: 12px; }
      /* mobile: hide sidebar toggle, use mob-menu-btn */
      .sidebar-toggle-btn { display: none !important; }
    }
    @media (max-width: 480px) {
      .stats-grid { grid-template-columns: 1fr 1fr; }
      .action-bar { gap: 5px; }
      .act-btn { font-size: 11px; padding: 7px 4px; }
    }
    .shift-ctrl-card {
	  background: #fff; border: 1px solid var(--border);
	  border-radius: var(--radius); padding: 16px 18px;
	  box-shadow: var(--shadow); margin-bottom: 22px;
	}
	.shift-ctrl-head {
	  display: flex; align-items: center; justify-content: space-between;
	  margin-bottom: 14px; gap: 10px; flex-wrap: wrap;
	}
	.shift-ctrl-title {
	  font-size: 15px; font-weight: 700; color: var(--text1);
	  display: flex; align-items: center; gap: 8px;
	}
	.shift-ctrl-title i { color: var(--brand); }
	.sctrl-pill {
	  display: inline-flex; align-items: center; gap: 6px;
	  border-radius: 20px; padding: 4px 12px;
	  font-size: 12px; font-weight: 700;
	}
	.sctrl-pill.booked    { background: var(--blue-bg);   color: var(--blue); }
	.sctrl-pill.active    { background: var(--green-bg);  color: var(--green); }
	.sctrl-pill.onbreak   { background: var(--amber-bg);  color: var(--amber); }
	.sctrl-pill.inactive  { background: var(--red-bg);    color: var(--red); }
	.sctrl-pill.none      { background: var(--brand-lt);  color: var(--brand-dk); }
	.sctrl-pill.completed { background: var(--green-bg);  color: var(--green); }
	.sctrl-pill.expired   { background: #fff3cd;          color: #856404; }
	.sctrl-pill.cancelled { background: var(--red-bg);    color: var(--red); }
	.sctrl-break-strip {
	  background: var(--amber-bg); border: 1px solid #FDE68A;
	  border-left: 4px solid var(--amber); border-radius: 8px;
	  padding: 10px 14px; margin-bottom: 12px;
	  display: flex; align-items: center; gap: 10px;
	}
	.sctrl-break-timer {
	  font-size: 22px; font-weight: 900; color: var(--amber);
	  font-variant-numeric: tabular-nums; min-width: 62px; text-align: right;
	}
	.sctrl-break-timer.danger { color: var(--red); animation: blink .6s infinite; }
	.sctrl-break-bar-wrap { margin-top: 6px; height: 4px; background: #FDE68A; border-radius: 4px; overflow: hidden; }
	.sctrl-break-bar { height: 100%; background: var(--amber); border-radius: 4px; transition: width .8s linear; }
	.sctrl-break-bar.danger { background: var(--red); }
	.sctrl-info-row {
	  display: flex; align-items: center; gap: 8px;
	  font-size: 13px; color: var(--text2); margin-bottom: 12px; flex-wrap: wrap;
	}
	.sctrl-info-row span { display: flex; align-items: center; gap: 4px; }
	.sctrl-btns { display: flex; flex-wrap: wrap; gap: 8px; }
	.sctrl-btn {
	  display: inline-flex; align-items: center; gap: 7px;
	  padding: 10px 18px; border-radius: var(--radius-sm);
	  font-size: 13px; font-weight: 700; border: none; cursor: pointer;
	  font-family: var(--font); transition: all .18s;
	  text-decoration: none; white-space: nowrap;
	  -webkit-tap-highlight-color: transparent;
	}
	.sctrl-btn:disabled { opacity: .45; cursor: not-allowed; }
	.sctrl-btn i { font-size: 15px; }
	.sctrl-btn-start   { background: var(--green); color: #fff; }
	.sctrl-btn-start:hover:not(:disabled) { background: #166b30; transform: translateY(-1px); }
	.sctrl-btn-break   { background: var(--amber-bg); color: var(--amber); border: 1.5px solid #FDE68A; }
	.sctrl-btn-break:hover:not(:disabled) { background: var(--amber); color: #fff; }
	.sctrl-btn-endbrk  { background: var(--blue); color: #fff; }
	.sctrl-btn-endbrk:hover:not(:disabled) { background: #0D47A1; }
	.sctrl-btn-endshft { background: var(--brand); color: #fff; }
	.sctrl-btn-endshft:hover:not(:disabled) { background: var(--brand-dk); }
	.sctrl-btn-book    { background: var(--brand-lt); color: var(--brand-dk); border: 1px solid var(--brand); }
	.sctrl-btn-book:hover { background: var(--brand-lt); text-decoration: none; }
	@media (max-width: 480px) {
	  .sctrl-btns { gap: 6px; }
	  .sctrl-btn  { font-size: 12px; padding: 9px 12px; }
	}
	.wh-card {
	  background: #fff;
	  border: 1px solid var(--border);
	  border-radius: var(--radius);
	  padding: 14px 18px;
	  box-shadow: var(--shadow);
	  margin-bottom: 22px;
	}
	.wh-card-head {
	  display: flex;
	  align-items: center;
	  justify-content: space-between;
	  margin-bottom: 12px;
	  gap: 8px;
	}
	.wh-card-title {
	  font-size: 14px;
	  font-weight: 700;
	  color: var(--text1);
	  display: flex;
	  align-items: center;
	  gap: 7px;
	}
	.wh-card-title i { color: var(--brand); }
	
	/* Rows inside the panel — rendered by JS */
	.wh-row {
	  display: flex;
	  align-items: center;
	  justify-content: space-between;
	  padding: 8px 0;
	  border-bottom: 1px solid var(--border);
	  font-size: 13px;
	  gap: 8px;
	}
	.wh-row:last-child { border-bottom: none; }
	.wh-label {
	  display: flex;
	  align-items: center;
	  gap: 6px;
	  color: var(--text2);
	  flex-shrink: 0;
	}
	.wh-label i { color: var(--text3); font-size: 13px; }
	.wh-val {
	  font-weight: 600;
	  color: var(--text1);
	  text-align: right;
	}.
	
  </style>
</head>
<body>

<%
  /* ─── Data setup ─── */
  User deliveryUser = (User) session.getAttribute("deliveryUser");
  if (deliveryUser == null) {
      response.sendRedirect(request.getContextPath() + "/DeliveryLoginServlet");
      return;
  }
  List<Order> orders = (List<Order>) request.getAttribute("orders");
  if (orders == null) orders = new ArrayList<>();
  String agentName   = deliveryUser != null ? deliveryUser.getUsername() : "Agent";
  int    agentId     = deliveryUser != null ? deliveryUser.getUid()      : 0;
  String agentStatus = deliveryUser != null && deliveryUser.getStatus() != null ? deliveryUser.getStatus() : "inactive";
  boolean isActive   = "active".equalsIgnoreCase(agentStatus);

  // Separate orders by broad status groups
  List<Order> activeOrders   = new java.util.ArrayList<>();
  List<Order> historyOrders  = new java.util.ArrayList<>();
  int pendingCodCount = 0;
  for (Order o : orders) {
      String s = o.getStatus() != null ? o.getStatus().toLowerCase() : "";
      if (s.equals("delivered") || s.equals("cancelled") || s.equals("returned") || s.equals("replaced") || s.equals("refunded")) {
          historyOrders.add(o);
          if ("delivered".equals(s) && "COD".equalsIgnoreCase(o.getPaymentMethod())
              && (o.getPaymentStatus() == null || !o.getPaymentStatus().equalsIgnoreCase("PAID"))) {
              pendingCodCount++;
          }
      } else {
          activeOrders.add(o);
      }
  }
  String dbName  = deliveryUser.getUsername() != null ? deliveryUser.getUsername() : "Rider";
  String dbEmail = deliveryUser.getEmail()    != null ? deliveryUser.getEmail()    : "";
  String dbPhone = deliveryUser.getMobileno() != null ? deliveryUser.getMobileno() : "";
  String initials = dbName.length() >= 2
      ? (dbName.substring(0,1) +
         dbName.substring(dbName.contains(" ") ? dbName.indexOf(" ")+1 : 1,
                          dbName.contains(" ") ? dbName.indexOf(" ")+2 : 2)).toUpperCase()
      : dbName.substring(0,1).toUpperCase();
  boolean isCurrentlyActive = "active".equalsIgnoreCase(deliveryUser.getStatus());

  /* ── Static/demo fields (replace with DB when available) ── */
  String dbVehicle    = "Bajaj Pulsar · TS09 AB 1234";
  String dbZone       = "Warangal Central";
  int    dbDeliveries = 847;
  double dbRating     = 4.8;

  /* ── BUG FIX: Read real earnings from request attributes (set by DeliveryPortalServlet).
     Previously hardcoded as 540/3240/14600 — now reflects actual DB wallet transactions. */
     Object _earnTodayAttr = request.getAttribute("dbEarnToday");
     Object _earnWeekAttr  = request.getAttribute("dbEarnWeek");
     Object _earnMonthAttr = request.getAttribute("dbEarnMonth");

     // FIX: Cast safely to BigDecimal, falling back to BigDecimal.ZERO if null or incorrect type
     java.math.BigDecimal dbEarnToday = (_earnTodayAttr instanceof java.math.BigDecimal) 
                                         ? (java.math.BigDecimal)_earnTodayAttr : java.math.BigDecimal.ZERO;
                                         
     java.math.BigDecimal dbEarnWeek  = (_earnWeekAttr instanceof java.math.BigDecimal) 
                                         ? (java.math.BigDecimal)_earnWeekAttr : java.math.BigDecimal.ZERO;
                                         
     java.math.BigDecimal dbEarnMonth = (_earnMonthAttr instanceof java.math.BigDecimal) 
                                         ? (java.math.BigDecimal)_earnMonthAttr : java.math.BigDecimal.ZERO;
  // ── Shift / Slot data — loaded by DeliveryPortalServlet, not by DAO here ────
  DeliverySlot portalSlot    = (DeliverySlot) request.getAttribute("portalSlot");
  String  portalSlotStatus            = request.getAttribute("portalSlotStatus")      != null ? (String)  request.getAttribute("portalSlotStatus")      : "NONE";
  int     portalSlotId                = request.getAttribute("portalSlotId")          != null ? (Integer) request.getAttribute("portalSlotId")          : -1;
  String  portalSlotType              = request.getAttribute("portalSlotType")        != null ? (String)  request.getAttribute("portalSlotType")        : "";
  boolean portalIsBooked              = request.getAttribute("portalIsBooked")        != null ? (Boolean) request.getAttribute("portalIsBooked")        : false;
  boolean portalIsActive              = request.getAttribute("portalIsActive")        != null ? (Boolean) request.getAttribute("portalIsActive")        : false;
  boolean portalIsOnBreak             = request.getAttribute("portalIsOnBreak")       != null ? (Boolean) request.getAttribute("portalIsOnBreak")       : false;
  boolean portalIsInactive            = request.getAttribute("portalIsInactive")      != null ? (Boolean) request.getAttribute("portalIsInactive")      : false;
  boolean portalIsCompleted           = request.getAttribute("portalIsCompleted")     != null ? (Boolean) request.getAttribute("portalIsCompleted")     : false;
  boolean portalIsExpired             = request.getAttribute("portalIsExpired")       != null ? (Boolean) request.getAttribute("portalIsExpired")       : false;
  boolean portalIsCancelled           = request.getAttribute("portalIsCancelled")     != null ? (Boolean) request.getAttribute("portalIsCancelled")     : false;
  boolean portalCanStartNow           = request.getAttribute("portalCanStartNow")     != null ? (Boolean) request.getAttribute("portalCanStartNow")     : false;
  String  portalSlotStartFmt          = request.getAttribute("portalSlotStartFmt")    != null ? (String)  request.getAttribute("portalSlotStartFmt")    : "";
  int     portalBreakSecsLeft         = request.getAttribute("portalBreakSecsLeft")   != null ? (Integer) request.getAttribute("portalBreakSecsLeft")   : -1;
  int     portalMaxBreak              = request.getAttribute("portalMaxBreak")        != null ? (Integer) request.getAttribute("portalMaxBreak")        : 10;
  boolean portalCanGoOnline           = request.getAttribute("portalCanGoOnline")     != null ? (Boolean) request.getAttribute("portalCanGoOnline")     : true;
 
 
  long portalSlotStartEpochMs = request.getAttribute("portalSlotStartEpochMs") != null ? (Long) request.getAttribute("portalSlotStartEpochMs") : 0L;
  long portalSlotEndEpochMs = request.getAttribute("portalSlotEndEpochMs") != null ? (Long) request.getAttribute("portalSlotEndEpochMs") : 0L;
  long portalShiftStartedAtMs = request.getAttribute("portalShiftStartedAtMs") != null ? (Long) request.getAttribute("portalShiftStartedAtMs") : 0L;
  int totalOrders = orders.size();
  int cntPending = 0, cntTransit = 0, cntDelivered = 0, cntHistory = 0,
      cntActive = 0, cntCod = 0, cntReturn = 0;
  double codAmountPending = 0.0;

  for (Order o : orders) {
    String s = o.getStatus() == null ? "" : o.getStatus().toLowerCase();
    boolean isCodOrder = "COD".equalsIgnoreCase(o.getPaymentMethod());
    // A Delivered COD order where cash hasn't been deposited yet is NOT done — it
    // needs the agent to hand cash to the hub. Keep it out of history and in cntCod.
    boolean isCodAwaitingDeposit = s.equals("delivered") && isCodOrder
        && !"PAID".equalsIgnoreCase(o.getPaymentStatus())
        && !"DEPOSITED".equalsIgnoreCase(o.getPaymentStatus());
    boolean isHistory = (s.equals("delivered") && !isCodAwaitingDeposit)
                     || s.equals("cancelled")
                     || s.equals("refunded")  || s.equals("replaced")
                     || s.equals("return picked") || s.equals("replacement dispatch");
    boolean isRet = s.contains("return");
    if (isHistory) {
      cntHistory++;
      if (s.equals("delivered")) cntDelivered++;
    } else {
      cntActive++;
      if (isRet) cntReturn++;
      if (s.contains("out") || s.contains("transit") || (s.contains("picked") && !s.contains("return"))) cntTransit++;
      else cntPending++;
      if (isCodOrder && !"PAID".equalsIgnoreCase(o.getPaymentStatus())
          && !"DEPOSITED".equalsIgnoreCase(o.getPaymentStatus())) {
        cntCod++;
        codAmountPending += o.getTotalAmount();
      }
    }
  }

  String activeOtpOrderId = (String) request.getAttribute("activeOrderId");
  String otpGeneratedFlag = (String) request.getAttribute("otpGeneratedFlag");
  String otpSuccessFlag   = (String) request.getAttribute("otpSuccessFlag");
  String otpFailedFlag    = (String) request.getAttribute("otpFailedFlag");
  String msgOtpGen  = (String) request.getAttribute("otpgeneratemsg");
  String msgGeneral = (String) request.getAttribute("msg");
%>

<!-- Overlay for mobile sidebar -->
<div class="overlay" id="overlay" onclick="closeSidebar()"></div>

<!-- Confirm Modal -->

    <div class="confirm-overlay" id="confirmOverlay">
  <div class="confirm-modal">

    <!-- Header -->
    <div class="cm-head" id="cm-head">
      <i class="bi bi-question-circle" id="cm-head-icon" style="color:var(--brand);"></i>
      <span id="cm-title">Confirm Action</span>
    </div>

    <!-- Body -->
    <div class="cm-body">
      <!-- Order summary strip -->
      <div class="cm-order-info" id="cm-order-info"></div>

      <%-- BUG 4 FIX: all three selects live here; only ONE is shown at a time.
           closeConfirm() always hides this whole wrapper. --%>
      <div id="cm-cancel-reason-wrap" style="display:none;">
        <div class="cancel-reason-box">
          <div class="cancel-reason-label">
            <i class="bi bi-exclamation-triangle"></i>
            <span id="cm-reason-label-text">Reason Required</span>
          </div>

          <%-- Can't Deliver reasons (Out for Delivery stage) --%>
          <select class="cancel-reason-select" id="cantDeliverReasonSelect" style="display:none;">
            <option value="">— Why couldn't you deliver? —</option>
            <option value="customer_not_home">Customer not home / not answering</option>
            <option value="wrong_address">Wrong or incomplete address</option>
            <option value="customer_refused">Customer refused to accept delivery</option>
            <option value="customer_requested_reschedule">Customer requested reschedule</option>
            <option value="unsafe_location">Unsafe delivery location</option>
            <option value="vehicle_breakdown">Vehicle breakdown</option>
            <option value="other">Other reason</option>
          </select>

          <%-- Reject Task reasons (Assigned / Picked Up stage — agent refuses order) --%>
          <select class="cancel-reason-select" id="rejectTaskReasonSelect" style="display:none;">
            <option value="">— Why are you rejecting this task? —</option>
            <option value="out_of_zone">Delivery location out of my zone</option>
            <option value="overloaded">Already at maximum order capacity</option>
            <option value="vehicle_issue">Vehicle issue / not roadworthy</option>
            <option value="emergency">Personal emergency</option>
            <option value="order_too_heavy">Order too heavy / oversized</option>
            <option value="other">Other reason</option>
          </select>

          <%-- Return Pickup cancel reasons --%>
          <select class="cancel-reason-select" id="returnCancelReasonSelect" style="display:none;">
            <option value="">— Why can't you do this pickup? —</option>
            <option value="customer_not_home">Customer not home</option>
            <option value="customer_changed_mind">Customer changed mind about return</option>
            <option value="item_not_ready">Item not packed / not ready</option>
            <option value="wrong_address">Address not found</option>
            <option value="vehicle_breakdown">Vehicle breakdown</option>
            <option value="other">Other reason</option>
          </select>

          <textarea class="cancel-note-input" id="cancelNoteInput" rows="2"
                    placeholder="Additional note (optional)…"></textarea>
        </div>
      </div>
    </div><!-- /cm-body -->

    <!-- Footer -->
    <div class="cm-footer">
      <button class="cm-btn cm-cancel" onclick="closeConfirm()">Cancel</button>
      <button class="cm-btn cm-confirm" id="cm-confirm-btn"
              onclick="executeConfirmedAction()">Confirm</button>
    </div>

  </div>
</div>

<!-- ══ SIDEBAR ══ -->
<nav class="sidebar" id="sidebar">
  <div class="logo-wrap">
    <div class="logo-icon"><i class="bi bi-truck"></i></div>
    <span class="logo-text">DeliveryPro</span>
  </div>

  <div class="nav-section-label">Main</div>
  <button class="nav-item active" onclick="showPage('dashboard')"><i class="bi bi-grid-1x2"></i> Dashboard</button>
  <button class="nav-item" onclick="showPage('orders')">
    <i class="bi bi-box-seam"></i> Active Orders
    <% if (cntActive > 0) { %>
      <span class="ms-auto badge rounded-pill" style="background:var(--amber-bg);color:var(--amber);font-size:10px;"><%= cntActive %></span>
    <% } %>
  </button>
  <button class="nav-item" onclick="showPage('history')">
    <i class="bi bi-clock-history"></i> History
    <% if (cntHistory > 0) { %>
      <span class="ms-auto badge rounded-pill" style="background:var(--brand-lt);color:var(--brand-dk);font-size:10px;"><%= cntHistory %></span>
    <% } %>
  </button>
  <div class="nav-divider"></div>
  <div class="nav-section-label">Account</div>
  
  <button class="nav-item" onclick="showPage('earnings')"><i class="bi bi-wallet2"></i> Earnings</button>
  <button class="nav-item" onclick="showPage('wallet')"><i class="bi bi-credit-card-2-front"></i> Wallet</button>
  <button class="nav-item" onclick="showPage('notifications')">
    <i class="bi bi-bell"></i> Notifications
    <span class="notif-badge ms-auto badge rounded-pill"  id="notifBadgeCount"  style="background:var(--brand-lt);color:var(--brand-dk);font-size:10px;"></span>
  </button>
  <button class="nav-item" onclick="showPage('profile')"><i class="bi bi-person-circle"></i> My Profile</button>

  <div class="sidebar-bottom">
    <div class="rider-chip" onclick="showPage('profile')">
      <div class="rider-avatar"><%= initials %></div>
      <div class="rider-info">
        <div class="rider-name"><%= dbName %></div>
        <div class="rider-role">Delivery Rider</div>
      </div>
    </div>
    <form action="<%= request.getContextPath() %>/DeliveryLogoutServlet" method="post" style="margin-top:8px;">
      <button type="submit" class="logout-btn"><i class="bi bi-box-arrow-left"></i> Sign Out</button>
    </form>
  </div>
</nav>

<!-- ══ TOPBAR ══ -->
<header class="topbar">
  <div class="topbar-left">
    <button class="mob-menu-btn" id="mobMenuBtn" title="Open Menu" aria-label="Open navigation menu" onclick="openSidebar()"><i class="bi bi-list"></i></button>
    <button class="sidebar-toggle-btn" title="Toggle Sidebar" aria-label="Toggle sidebar" style="border:none;background:none;font-size:22px;color:var(--text2);cursor:pointer;padding:4px 6px;border-radius:6px;transition:background 0.15s;" onclick="toggleSidebar()"><i class="bi bi-list"></i></button>
    <span class="topbar-title" id="topbarTitle">Dashboard</span>
  </div>
  <div class="topbar-right">
  <a href="DeliverySlotServlet" class="nav-link">
  <i class="bi bi-calendar-check me-2"></i>Book My Slot
</a>
    <div class="zone-tag d-none d-sm-flex"><i class="bi bi-geo-alt-fill" style="color:var(--brand);"></i> <%= dbZone %></div>
    <div class="online-pill" onclick="toggleOnline()" title="Click to toggle Online/Offline status" aria-label="Toggle online status">
      <div class="pulse-dot <%= isCurrentlyActive ? "" : "off" %>" id="statusDot"></div>
      <span id="statusText"><%= isCurrentlyActive ? "Online" : "Offline" %></span>
    </div>
     <button onclick="showPage('notifications')" title="Notifications"
            style="background:none;border:none;cursor:pointer;position:relative;
                   padding:6px;border-radius:8px;color:var(--text2);
                   transition:background .15s;" id="topbarBellBtn"
            onmouseover="this.style.background='var(--brand-lt)'"
            onmouseout="this.style.background='none'">
      <i class="bi bi-bell-fill" style="font-size:18px;"></i>
      <span id="topbarNotifBadge"
            style="display:none;position:absolute;top:2px;right:2px;
                   background:var(--red);color:#fff;border-radius:10px;
                   font-size:9px;font-weight:800;padding:1px 5px;
                   min-width:16px;text-align:center;line-height:1.5;
                   border:2px solid #fff;pointer-events:none;"></span>
    </button>
    <div class="rider-avatar" onclick="showPage('profile')" style="cursor:pointer;" title="View My Profile" aria-label="Profile"><%= initials %></div>
  </div>
  
</header>

<!-- ══ MAIN ══ -->
<main class="main">
  <div id="walletBanner" class="wallet-banner danger" style="display:none; margin:5px;"></div>

  <!-- global alerts -->
  <% if (msgOtpGen != null) { %>
  <div style="padding:10px 24px 0;">
    <div class="alert-info"><i class="bi bi-info-circle"></i> <%= msgOtpGen %></div>
  </div>
  <% } %>
  <% if (msgGeneral != null) { %>
  <div style="padding:10px 24px 0;">
    <div class="<%= msgGeneral.contains("verified") ? "alert-ok" : "alert-err" %>">
      <i class="bi bi-<%= msgGeneral.contains("verified") ? "check-circle" : "x-circle" %>"></i> <%= msgGeneral %>
    </div>
  </div>
  <% } %>
 <!-- ════ DASHBOARD ════ -->
  <div class="page active" id="page-dashboard">
    <div class="pg-head">
      <h1>Good day, <%= dbName.split(" ")[0] %>! 👋</h1>
      <p>Here's your delivery overview for today.</p>
    </div>

    <!-- Today summary bar -->
    <div class="today-bar">
      <div class="today-bar-item"><div class="tbi-label">Active</div><div class="tbi-val"><%= cntActive %></div></div>
      <div class="today-bar-divider"></div>
      <div class="today-bar-item"><div class="tbi-label">In Transit</div><div class="tbi-val"><%= cntTransit %></div></div>
      <div class="today-bar-divider"></div>
      <div class="today-bar-item"><div class="tbi-label">Completed</div><div class="tbi-val" style="color:var(--green);"><%= cntDelivered %></div></div>
      <div class="today-bar-divider"></div>
      <div class="today-bar-item"><div class="tbi-label">Returns</div><div class="tbi-val" style="color:var(--rose);"><%= cntReturn %></div></div>
      <div class="today-bar-divider"></div>
      <div class="today-bar-item"><div class="tbi-label">COD Pending</div><div class="tbi-val" style="color:var(--amber);">₹<%= String.format("%.0f", codAmountPending) %></div></div>
      <div class="today-bar-divider d-none d-sm-block"></div>
      <div class="today-bar-item d-none d-sm-block"><div class="tbi-label">Earned Today</div><div class="tbi-val" style="color:var(--brand-dk);">₹<%= dbEarnToday.toPlainString() %></div></div>
    </div>

    <%-- ══════════════════════════════════════════════════════════════════
         SHIFT CONTROL CARD — data loaded by DeliveryPortalServlet,
         passed via request attributes, read into scriptlet variables above.
         No DAO calls here.
    ═══════════════════════════════════════════════════════════════════════ --%>

<%
  /* ── Determine overnight badge for slot end-time display ── */
  boolean portalIsOvernight = "NIGHT".equals(portalSlotType)
                           || "MIDNIGHT".equals(portalSlotType)
                           || "EARLY_MORNING".equals(portalSlotType);

  /* ── End-time friendly string (with +1 day indicator for overnight) ── */
  String portalSlotEndFmt = "";
  if (!"".equals(portalSlotType)) {
    java.time.LocalTime pe = com.DAO.DeliverySlotDAO.getSlotEndTime(portalSlotType);
    portalSlotEndFmt = pe.format(java.time.format.DateTimeFormatter.ofPattern("h:mm a"))
                     + (portalIsOvernight ? " <span class='overnight-badge'>(+1 day)</span>" : "");
  }
%>

<div class="shift-ctrl-card" id="portalShiftCard">
  <div class="shift-ctrl-head">
    <div class="shift-ctrl-title">
      <i class="bi bi-person-check-fill"></i> Shift Control
    </div>
    <%
      String pPill  = portalIsActive    ? "active"
                    : portalIsBooked    ? "booked"
                    : portalIsOnBreak   ? "onbreak"
                    : portalIsInactive  ? "inactive"
                    : portalIsExpired   ? "expired"
                    : portalIsCancelled ? "cancelled"
                    : portalIsCompleted ? "completed"
                    : "none";
      String pLabel = portalIsActive    ? "Online · Active"
                    : portalIsBooked    ? "Slot Booked — Not Started"
                    : portalIsOnBreak   ? "On Break"
                    : portalIsInactive  ? "Offline"
                    : portalIsExpired   ? "Slot Expired — Not Started"
                    : portalIsCancelled ? "Slot Cancelled"
                    : portalIsCompleted ? "Shift Completed"
                    : "No Slot Today";
      String pPulseStyle = portalIsActive    ? "background:var(--green);animation:blink 2s infinite;"
                         : portalIsOnBreak   ? "background:var(--amber);animation:blink 1.2s infinite;"
                         : portalIsBooked    ? "background:var(--blue);"
                         : portalIsInactive  ? "background:var(--red);"
                         : portalIsExpired   ? "background:#856404;"
                         : portalIsCancelled ? "background:var(--red);"
                         : portalIsCompleted ? "background:var(--green);"
                         : "background:var(--text3);";
    %>
    <span class="sctrl-pill <%=pPill%>">
      <span style="width:7px;height:7px;border-radius:50%;display:inline-block;<%=pPulseStyle%>"></span>
      <%=pLabel%>
    </span>
  </div>

  <%-- ── Slot info row (show for all states that have a slot) ── --%>
  <% if (portalSlot != null) { %>
  <div class="sctrl-info-row">
    <span><i class="bi bi-clock" style="color:var(--brand);"></i>
      <% if ("AM".equals(portalSlotType))           { %>🌅 6am–12pm
      <% } else if ("PM".equals(portalSlotType))    { %>☀️ 12pm–6pm
      <% } else if ("EVENING".equals(portalSlotType)) { %>🌆 6pm–10pm
      <% } else if ("FULL_DAY".equals(portalSlotType)) { %>📅 6am–10pm
      <% } else if ("NIGHT".equals(portalSlotType))         { %>🌙 10pm – 2am <span class="overnight-badge">(+1 day)</span>
      <% } else if ("MIDNIGHT".equals(portalSlotType))      { %>🌑 2am – 6am
      <% } else if ("EARLY_MORNING".equals(portalSlotType)) { %>🌄 4am – 8am
      <% } %>
    </span>
    <span style="color:var(--border);">|</span>
    <span><i class="bi bi-geo-alt-fill" style="color:var(--brand);"></i>
      <%=portalSlot.getZoneName() != null ? portalSlot.getZoneName() : "—"%>
    </span>
    <% if (portalSlot.isSurge()) { %>
    <span style="background:var(--amber-bg);color:var(--amber);border-radius:8px;padding:2px 8px;font-size:11px;font-weight:700;">
      ⚡ Surge ×<%=String.format("%.1f", portalSlot.getSurgeMultiplier())%>
    </span>
    <% } %>
  </div>
  <% } %>

  <%-- ── Break banner ── --%>
  <% if (portalIsOnBreak) { %>
  <div class="sctrl-break-strip">
    <i class="bi bi-cup-hot-fill" style="font-size:18px;color:var(--amber);flex-shrink:0;"></i>
    <div style="flex:1;">
      <div style="font-size:13px;font-weight:700;color:var(--amber);">On Break</div>
      <div style="font-size:12px;color:var(--text2);">Max <%=portalMaxBreak%> min — exceeding takes you offline</div>
      <div class="sctrl-break-bar-wrap">
        <div class="sctrl-break-bar" id="portalBreakBar" style="width:0%"></div>
      </div>
    </div>
    <div class="sctrl-break-timer" id="portalBreakTimer">
      <%=String.format("%d:%02d", portalBreakSecsLeft>=0 ? portalBreakSecsLeft/60 : portalMaxBreak,
                                   portalBreakSecsLeft>=0 ? portalBreakSecsLeft%60 : 0)%>
    </div>
  </div>
  <% } %>

  <%-- ── Inactive warning ── --%>
  <% if (portalIsInactive) { %>
  <div style="background:var(--red-bg);border-left:4px solid var(--red);border-radius:8px;
              padding:10px 12px;margin-bottom:12px;font-size:13px;color:var(--red);">
    <strong>Offline — extended break.</strong> End your shift to receive earned payments.
  </div>
  <% } %>

 <%-- ══════════════════════════════════════════════════
       STATE BANNERS — one branch per slot state.
       BOOKED has two sub-states: waiting vs window-open.
       FIX: was `if (portalIsBooked)` ... `else if (portalIsBooked && portalCanStartNow)`
            — the else-if was permanently unreachable. Now split into correct branches.
  ══════════════════════════════════════════════════ --%>

  <%-- ── BOOKED · waiting (>15 min before start) ── --%>
  <% if (portalIsBooked && !portalCanStartNow) { %>
  <div style="background:var(--blue-bg);border-left:4px solid var(--blue);border-radius:8px;
              padding:12px 14px;margin-bottom:12px;text-align:center;">
    <div style="font-size:12px;color:var(--text2);margin-bottom:10px;">
      <i class="bi bi-calendar-check-fill" style="color:var(--blue);"></i>
      <strong style="color:var(--blue);">Slot Confirmed</strong>
      &nbsp;·&nbsp; Shift starts at <strong style="color:var(--text1);"><%=portalSlotStartFmt%></strong>
      &nbsp;·&nbsp; Start button activates 15 min before
    </div>
    <%-- HH : MM : SS countdown boxes --%>
    <div style="display:flex;justify-content:center;align-items:center;gap:8px;" id="portalCdWrap">
      <div style="background:var(--brand);color:#fff;border-radius:8px;padding:8px 14px;min-width:54px;text-align:center;">
        <div style="font-size:26px;font-weight:900;font-variant-numeric:tabular-nums;line-height:1;" id="portalCdH">--</div>
        <div style="font-size:10px;font-weight:700;text-transform:uppercase;letter-spacing:.07em;margin-top:3px;opacity:.85;">HRS</div>
      </div>
      <div style="font-size:24px;font-weight:900;color:var(--brand);">:</div>
      <div style="background:var(--brand);color:#fff;border-radius:8px;padding:8px 14px;min-width:54px;text-align:center;">
        <div style="font-size:26px;font-weight:900;font-variant-numeric:tabular-nums;line-height:1;" id="portalCdM">--</div>
        <div style="font-size:10px;font-weight:700;text-transform:uppercase;letter-spacing:.07em;margin-top:3px;opacity:.85;">MIN</div>
      </div>
      <div style="font-size:24px;font-weight:900;color:var(--brand);">:</div>
      <div style="background:var(--brand);color:#fff;border-radius:8px;padding:8px 14px;min-width:54px;text-align:center;">
        <div style="font-size:26px;font-weight:900;font-variant-numeric:tabular-nums;line-height:1;" id="portalCdS">--</div>
        <div style="font-size:10px;font-weight:700;text-transform:uppercase;letter-spacing:.07em;margin-top:3px;opacity:.85;">SEC</div>
      </div>
    </div>
     <div id="portalCdLabel"
         style="font-size:12px;color:var(--text3);margin-top:8px;font-weight:600;">
      until shift window opens
    </div>
    <div style="font-size:11px;color:var(--text3);margin-top:4px;">
      Slot expires 1 hr before shift end &nbsp;·&nbsp;
      <strong id="portalExpireTimeFmt">—</strong>
    </div>
  </div>

  <%-- ── BOOKED · window open (within 15 min of start, button enabled) ── --%>
  <% } else if (portalIsBooked && portalCanStartNow) { %>
  <div style="background:var(--green-bg);border-left:4px solid var(--green);border-radius:8px;
              padding:10px 12px;margin-bottom:12px;font-size:13px;color:var(--green);">
    <i class="bi bi-check-circle-fill"></i>
    <strong>Ready!</strong> Your shift window is now active. Tap <strong>Start Shift</strong>.
    <% if (portalIsOvernight) { %>
    <br><small style="color:var(--text3);font-size:11px;">Night shift ends at <%=portalSlotEndFmt%></small>
    <% } %>
  </div>

  <%-- ── EXPIRED — booked but never started, window passed ── --%>
  <% } else if (portalIsExpired) { %>
  <div style="background:#fff3cd;border-left:4px solid #f59e0b;border-radius:8px;
              padding:12px 14px;margin-bottom:12px;">
    <div style="font-size:13px;font-weight:700;color:#856404;margin-bottom:4px;">
      <i class="bi bi-exclamation-triangle-fill"></i> Slot Expired — Shift Not Started
    </div>
    <div style="font-size:12px;color:#78610a;">
      Your <strong><%=portalSlotStartFmt%></strong> slot expired because the shift was not started within the allowed window.
      Book a new slot to go online again.
    </div>
  </div>

  <%-- ── CANCELLED ── --%>
  <% } else if (portalIsCancelled) { %>
  <div style="background:var(--red-bg);border-left:4px solid var(--red);border-radius:8px;
              padding:12px 14px;margin-bottom:12px;">
    <div style="font-size:13px;font-weight:700;color:var(--red);margin-bottom:4px;">
      <i class="bi bi-x-circle-fill"></i> Slot Cancelled
    </div>
    <div style="font-size:12px;color:var(--red);">
      Your <strong><%=portalSlotStartFmt%></strong> slot was cancelled.
      You can book a new slot below.
    </div>
  </div>

  <%-- ── COMPLETED ── --%>
  <% } else if (portalIsCompleted) { %>
  <div style="background:var(--green-bg);border-left:4px solid var(--green);border-radius:8px;
              padding:10px 12px;margin-bottom:12px;font-size:13px;color:var(--green);">
    <i class="bi bi-trophy-fill"></i>
    <strong>Shift Completed!</strong> Great work today. Earnings have been credited to your wallet.
  </div>
  <% } %>

  <%-- ── Action Buttons ── --%>
  <div class="sctrl-btns">
    <% if (portalIsBooked && portalSlotId > 0) { %>
    <button class="sctrl-btn sctrl-btn-start"
            id="portalBtnStart"
            onclick="portalDoStartShift(<%=portalSlotId%>)"
            <%=portalCanStartNow && portalCanGoOnline ? "" : "disabled"%>>
      <i class="bi bi-play-circle-fill"></i>
      <% if (!portalCanGoOnline) { %>Top Up to Start
      <% } else if (!portalCanStartNow) { %>Shift Starts at <%=portalSlotStartFmt%>
      <% } else { %>Start Shift<% } %>
    </button>
    <% } %>

    <% if (portalIsActive && portalSlotId > 0) { %>
    <button class="sctrl-btn sctrl-btn-break" onclick="portalDoStartBreak(<%=portalSlotId%>)">
      <i class="bi bi-cup-hot"></i> Take a Break
    </button>
    <button class="sctrl-btn sctrl-btn-endshft" onclick="portalDoEndShift(<%=portalSlotId%>)">
      <i class="bi bi-stop-circle-fill"></i> End Shift
    </button>
    <% } %>

    <% if (portalIsOnBreak && portalSlotId > 0) { %>
    <button class="sctrl-btn sctrl-btn-endbrk" onclick="portalDoEndBreak(<%=portalSlotId%>)">
      <i class="bi bi-arrow-right-circle-fill"></i> End Break &amp; Go Online
    </button>
    <% } %>

    <% if (portalIsInactive && portalSlotId > 0) { %>
    <button class="sctrl-btn sctrl-btn-endshft" onclick="portalDoEndShift(<%=portalSlotId%>)">
      <i class="bi bi-stop-circle-fill"></i> End Shift &amp; Get Earnings
    </button>
    <% } %>

    <a class="sctrl-btn sctrl-btn-book" href="<%=request.getContextPath()%>/DeliverySlotServlet">
      <i class="bi bi-calendar-check"></i>
      <% if (portalSlot == null || portalIsCompleted || portalIsExpired || portalIsCancelled) { %>Book a Slot<% } else { %>Manage Slot<% } %>
    </a>
  </div>
</div>

<script>
(function() {
	  /* Server-computed values injected at page-render time with safe primitive fallbacks */
	  var CTX              = "<%=request.getContextPath()%>";
	  var P_SLOT_ID        = <%= (request.getAttribute("portalSlotId") != null) ? request.getAttribute("portalSlotId") : -1 %>;
	  var P_MAX_BREAK      = <%= (request.getAttribute("portalMaxBreak") != null) ? request.getAttribute("portalMaxBreak") : 10 %>;
	  var P_BREAK_SECS     = <%= (request.getAttribute("portalBreakSecsLeft") != null) ? request.getAttribute("portalBreakSecsLeft") : -1 %>;
	  var P_ON_BREAK       = <%= (request.getAttribute("portalIsOnBreak") != null) ? request.getAttribute("portalIsOnBreak") : false %>;
	  var P_BOOKED         = <%= (request.getAttribute("portalIsBooked") != null) ? request.getAttribute("portalIsBooked") : false %>;
	  var P_IS_ACTIVE      = <%= (request.getAttribute("portalIsActive") != null) ? request.getAttribute("portalIsActive") : false %>;
	  var P_IS_ON_BREAK    = <%= (request.getAttribute("portalIsOnBreak") != null) ? request.getAttribute("portalIsOnBreak") : false %>;
	  var P_CAN_START      = <%= (request.getAttribute("portalCanStartNow") != null) ? request.getAttribute("portalCanStartNow") : false %>;
	
	  // Guaranteed fallback defaults to 0 if context values are unpopulated
	  var P_END_EPOCH_MS         = <%= (request.getAttribute("portalSlotEndEpochMs") != null) ? request.getAttribute("portalSlotEndEpochMs") : 0L %>;
	  var P_START_EPOCH_MS       = <%= (request.getAttribute("portalSlotStartEpochMs") != null) ? request.getAttribute("portalSlotStartEpochMs") : 0L %>;
	  // BUG-1 FIX: inject the actual shift-started timestamp so the Working Hours
	  // clock shows true elapsed time, not time-since-slot-opened.
	  var P_SHIFT_STARTED_AT_MS  = <%= (request.getAttribute("portalShiftStartedAtMs") != null) ? request.getAttribute("portalShiftStartedAtMs") : 0L %>;
	  // BUG-4 FIX: inject break_start epoch so _shiftState.breakStartEpoch is
	  // populated on page load — required for live break subtraction in _tickShiftClock().
	  var P_BREAK_START_EPOCH_MS = <%= (request.getAttribute("portalBreakStartEpochMs") != null) ? request.getAttribute("portalBreakStartEpochMs") : 0L %>;

	  document.addEventListener('DOMContentLoaded', function() {
	    // Verify core dependencies exist globally before attempting execution
	    if (typeof _shiftState === 'undefined') {
	        window._shiftState = { slotId: -1, hasSlot: false, status: 'NONE' };
	    }

	    if (P_SLOT_ID > 0) {
	      _shiftState.slotId                = P_SLOT_ID;
	      _shiftState.slotEndEpochMs        = P_END_EPOCH_MS;
	      _shiftState.slotStartEpochMs      = P_START_EPOCH_MS;
	      _shiftState.hasSlot               = true;
	      _shiftState.status                = P_IS_ACTIVE   ? 'ACTIVE'
	                                        : P_IS_ON_BREAK ? 'ON_BREAK'
	                                        : P_BOOKED      ? 'BOOKED'
	                                        : 'NONE';

	      if (P_SHIFT_STARTED_AT_MS > 0) {
	        _shiftState.shiftStartedAtEpochMs = P_SHIFT_STARTED_AT_MS;
	        // Restore persisted clock origin for this slot (survives F5)
	        try {
	          var saved = sessionStorage.getItem('shiftClockStart_' + P_SLOT_ID);
	          _shiftState.shiftClockStart = saved ? parseInt(saved, 10) : P_SHIFT_STARTED_AT_MS;
	        } catch(e) {
	          _shiftState.shiftClockStart = P_SHIFT_STARTED_AT_MS;
	        }
	      }
	      // BUG-4 FIX: seed breakStartEpoch so _tickShiftClock()'s live-break
	      // subtraction branch fires correctly on page load when ON_BREAK.
	      if (P_BREAK_START_EPOCH_MS > 0) {
	        _shiftState.breakStartEpoch = P_BREAK_START_EPOCH_MS;
	      }
	    }

	    // Safely verify function existence before scheduling workflows
	    if ((P_IS_ACTIVE || P_IS_ON_BREAK) && P_END_EPOCH_MS > 0 && P_SLOT_ID > 0) {
	      if (typeof _scheduleAutoOffline === 'function') {
	          _scheduleAutoOffline(P_SLOT_ID, P_END_EPOCH_MS);
	      }
	      if (typeof _startShiftClock === 'function') {
	          _startShiftClock();
	      }
	    }
	  });

	  /* Action handles */
	  window.portalDoStartShift = function(slotId) {
	    var btn = document.getElementById('portalBtnStart');
	    if (btn) { btn.disabled=true; btn.innerHTML='<i class="bi bi-hourglass-split"></i> Starting…'; }
	    var fd = new FormData(); fd.append('action','startShift'); fd.append('slotId',slotId);
	    fetch(CTX+'/DeliverySlotServlet',{method:'POST',body:fd})
	      .then(function(r){return r.json();})
	      .then(function(data){
	        if (data.success) {
	          if (data.shiftStartedAtEpochMs && typeof _shiftState !== 'undefined') {
	            _shiftState.shiftStartedAtEpochMs = data.shiftStartedAtEpochMs;
	          }
	          if (typeof showToast === 'function') showToast('🟢 Shift started! You are now online.','success',3000);
	          setTimeout(function(){ location.reload(); },1500);
	        } else {
	          if (typeof showToast === 'function') showToast('❌ '+data.message,'error',6000);
	          if(btn){btn.disabled=false;btn.innerHTML='<i class="bi bi-play-circle-fill"></i> Start Shift';}
	        }
	      }).catch(function(){
	        if (typeof showToast === 'function') showToast('Network error.','error');
	        if(btn){btn.disabled=false;}
	      });
	  };

	  window.portalDoStartBreak = function(slotId) {
	    if (!confirm('Take a break?\nMax '+P_MAX_BREAK+' minutes — exceeding takes you offline.')) return;
	    var fd = new FormData(); fd.append('action','startBreak'); fd.append('slotId',slotId);
	    fetch(CTX+'/DeliverySlotServlet',{method:'POST',body:fd})
	      .then(function(r){return r.json();})
	      .then(function(data){
	        if (data.success) {
	          if (typeof showToast === 'function') showToast('☕ Break started. '+P_MAX_BREAK+' min timer running.','warning',3000);
	          setTimeout(function(){ location.reload(); },1200);
	        } else {
	          if (typeof showToast === 'function') showToast('❌ '+data.message,'error',5000);
	        }
	      }).catch(function(){ if (typeof showToast === 'function') showToast('Network error.','error'); });
	  };

	  window.portalDoEndBreak = function(slotId) {
	    var fd = new FormData(); fd.append('action','endBreak'); fd.append('slotId',slotId);
	    fetch(CTX+'/DeliverySlotServlet',{method:'POST',body:fd})
	      .then(function(r){return r.json();})
	      .then(function(data){
	        if (data.success) {
	          if (data.wentOffline) {
	            if (typeof showToast === 'function') showToast('⚠️ Break exceeded limit — taken offline.','error',6000);
	          } else {
	            if (typeof showToast === 'function') showToast('✅ Break ended. Back online!','success',3000);
	          }
	          setTimeout(function(){ location.reload(); },1800);
	        } else {
	          if (typeof showToast === 'function') showToast('❌ '+data.message,'error',5000);
	        }
	      }).catch(function(){ if (typeof showToast === 'function') showToast('Network error.','error'); });
	  };

	  window.portalDoEndShift = function(slotId) {
	    if (!confirm('End your shift?\nEarnings will be credited to your wallet.')) return;
	    var fd = new FormData(); fd.append('action','endShift'); fd.append('slotId',slotId);
	    fetch(CTX+'/DeliverySlotServlet',{method:'POST',body:fd})
	      .then(function(r){return r.json();})
	      .then(function(data){
	        if (data.success) {
	          var earned = parseFloat(data.earnedToday||0).toFixed(0);
	          if (typeof showToast === 'function') showToast('🎉 Shift ended! ₹'+earned+' credited to wallet.','success',5000);
	          setTimeout(function(){ location.reload(); },2500);
	        } else {
	          if (typeof showToast === 'function') showToast('❌ '+data.message,'error',5000);
	        }
	      }).catch(function(){ if (typeof showToast === 'function') showToast('Network error.','error'); });
	  };

	  /* Break countdown timer metrics execution */
	  (function initPortalBreakTimer() {
	    if (!P_ON_BREAK) return;
	    var secsLeft  = P_BREAK_SECS >= 0 ? P_BREAK_SECS : P_MAX_BREAK * 60;
	    var totalSecs = P_MAX_BREAK * 60;
	    var timerEl   = document.getElementById('portalBreakTimer');
	    var barEl     = document.getElementById('portalBreakBar');
	    function upd(s) {
	      var m = Math.floor(s/60), sec = s%60;
	      if (timerEl) {
	        timerEl.textContent = m+':'+(sec<10?'0':'')+sec;
	        if (s<=60) timerEl.classList.add('danger'); else timerEl.classList.remove('danger');
	      }
	      var pct = Math.min(100, ((totalSecs-s)/totalSecs)*100);
	      if (barEl) { barEl.style.width=pct+'%'; if(pct>75) barEl.classList.add('danger'); else barEl.classList.remove('danger'); }
	    }
	    upd(secsLeft);
	    var iv = setInterval(function(){
	      secsLeft = Math.max(0, secsLeft-1);
	      upd(secsLeft);
	      if (secsLeft <= 0) {
	        clearInterval(iv);
	        if (typeof showToast === 'function') showToast('⏰ Break exceeded! Going offline…','error',5000);
	        var fd = new FormData(); fd.append('action','endBreak'); fd.append('slotId',P_SLOT_ID);
	        fetch(CTX+'/DeliverySlotServlet',{method:'POST',body:fd})
	          .then(function(){ setTimeout(function(){ location.reload(); },2000); })
	          .catch(function(){ setTimeout(function(){ location.reload(); },2500); });
	      }
	    }, 1000);
	  })();

	
	  (function initPortalShiftCountdown() {
		    if (!P_BOOKED) return;
		    // P_CAN_START = true means server says window is open right now;
		    // we still need to run Phase 2/3 guard in that case, so DON'T return early.
		    if (!P_START_EPOCH_MS || P_START_EPOCH_MS <= 0) return;

		    var hEl      = document.getElementById('portalCdH');
		    var mEl      = document.getElementById('portalCdM');
		    var sEl      = document.getElementById('portalCdS');
		    var wrapEl   = document.getElementById('portalCdWrap');
		    var labelEl  = document.getElementById('portalCdLabel');
		    var expEl    = document.getElementById('portalExpireTimeFmt');
		    var btnStart = document.getElementById('portalBtnStart');

		    var startMs  = P_START_EPOCH_MS;
		    var earlyMs  = startMs - 15 * 60 * 1000;   // 15 min before start
		    // Expiry = 1 hour before slot END (matches DAO expireStaleBookedSlots rule).
		    // P_END_EPOCH_MS = window_end_at epoch. Fallback: startMs+3hr if endMs missing.
		    var graceMs  = (P_END_EPOCH_MS && P_END_EPOCH_MS > startMs)
			             ? P_END_EPOCH_MS - (60 * 60 * 1000)
			             : startMs + (3 * 60 * 60 * 1000);

		    // Show human-readable expiry time
		    if (expEl) {
		      expEl.textContent = new Date(graceMs)
		        .toLocaleTimeString('en-IN', { hour: 'numeric', minute: '2-digit', hour12: true });
		    }

		    function pad(n) { return n < 10 ? '0' + n : '' + n; }

		    var iv = null;
		    var reloadScheduled = false;

		    function tick() {
		      var now = Date.now();

		      /* ── Phase 1: before 15-min window opens ── */
		      if (now < earlyMs) {
		        var diff = Math.floor((earlyMs - now) / 1000);
		        if (hEl) hEl.textContent = pad(Math.floor(diff / 3600));
		        if (mEl) mEl.textContent = pad(Math.floor((diff % 3600) / 60));
		        if (sEl) sEl.textContent = pad(diff % 60);
		        if (wrapEl) wrapEl.style.display = '';

		        // Update label
		        if (labelEl) {
		          labelEl.textContent = 'until shift window opens';
		          labelEl.style.color = 'var(--text3)';
		        }
		        return;
		      }

		      /* ── Phase 2: window open, shift not yet started (earlyMs → startMs) ── */
		      if (now >= earlyMs && now <= startMs) {
		        // Hide countdown boxes, show pulsing green banner
		        if (wrapEl) wrapEl.style.display = 'none';
		        if (labelEl) {
		          labelEl.textContent = '✅ Window open — tap Start Shift now!';
		          labelEl.style.color = 'var(--green)';
		          labelEl.style.fontWeight = '700';
		        }

		        // Activate the Start Shift button if it's still disabled
		        if (btnStart && btnStart.disabled) {
		          btnStart.disabled = false;
		          btnStart.innerHTML = '<i class="bi bi-play-circle-fill"></i> Start Shift';
		          btnStart.classList.add('pulse');
		        }
		        return;
		      }

		      /* ── Phase 3: after start, within 30-min grace → urgent red countdown ── */
		      if (now > startMs && now <= graceMs) {
		        var remaining = Math.floor((graceMs - now) / 1000);
		        var remM = Math.floor(remaining / 60), remS = remaining % 60;

		        if (wrapEl) {
		          wrapEl.style.display = '';
		          // Turn boxes red
		          [wrapEl.querySelectorAll('[id^="portalCd"]')].forEach(function(){});
		          var boxes = wrapEl.querySelectorAll('div[style*="background:var(--brand)"]');
		          boxes.forEach(function(b) {
		            b.style.background = 'var(--red)';
		            b.style.animation  = 'blink .6s step-start infinite';
		          });
		        }

		        // Update the three digit elements with remaining MM:SS (hours = 00)
		        if (hEl) { hEl.textContent = '00'; hEl.style.color = '#fff'; }
		        if (mEl) { mEl.textContent = pad(remM); }
		        if (sEl) { sEl.textContent = pad(remS); }

		        if (labelEl) {
		          labelEl.textContent = '⚠️ Start before slot expires!';
		          labelEl.style.color = 'var(--red)';
		          labelEl.style.fontWeight = '800';
		        }

		        // Swap button to urgent danger style
		        if (btnStart) {
		          btnStart.disabled = false;
		          btnStart.style.background = 'var(--red)';
		          btnStart.style.borderColor = 'var(--red)';
		          btnStart.innerHTML =
		            '<i class="bi bi-exclamation-triangle-fill"></i> Start Now! (' +
		            remM + ':' + pad(remS) + ')';
		          if (!btnStart.classList.contains('pulse')) btnStart.classList.add('pulse');
		        }

		        // 60-second warning toast (fire once)
		        if (remaining === 60) {
		          if (typeof showToast === 'function')
		            showToast('⚠️ Your slot expires in 1 minute! Start your shift now.', 'error', 6000);
		        }
		        return;
		      }

		      /* ── Phase 4: grace expired ── */
		      if (now > graceMs && !reloadScheduled) {
		        reloadScheduled = true;
		        clearInterval(iv);
		        if (typeof showToast === 'function')
		          showToast('❌ Slot expired — not started within 30 minutes of shift start.', 'error', 5000);
		        // Give the DAO's expiry scheduler a moment to run (it fires on the next
		        // portal load via expireStaleBookedSlots()), then reload.
		        setTimeout(function() { location.reload(); }, 2800);
		      }
		    }

		    tick();                          // run immediately on page load
		    iv = setInterval(tick, 1000);    // then every second
		  })();

	 
})();
</script>

<div class="wh-card">
  <div class="wh-card-head">
    <div class="wh-card-title">
      <i class="bi bi-stopwatch-fill"></i> Working Hours
    </div>
    <span id="whCardRefreshHint"
          style="font-size:11px;color:var(--text3);cursor:pointer;"
          onclick="_doShiftPoll()"
          title="Refresh">
      <i class="bi bi-arrow-clockwise"></i>
    </span>
  </div>

  <div id="workingHoursPanel">
    <% if (portalSlot == null) { %>
      <div class="wh-row">
        <span class="wh-label"><i class="bi bi-clock"></i> No Shift Today</span>
        <span class="wh-val" style="color:var(--text3);">
          <a href="<%=request.getContextPath()%>/DeliverySlotServlet"
             style="color:var(--brand);font-weight:600;">
            <i class="bi bi-calendar-plus"></i> Book a Slot
          </a>
        </span>
      </div>
    <% } else {
         // BUG-3 FIX: hoist whEndFmt here so it is in scope for BOTH
         // the shift-time span AND the "Ends" row rendered further below.
         // Previously it was declared inside an inner scriptlet block and
         // went out of scope before the second <%=whEndFmt%reference,
         // causing a JSP compile error / blank "Ends" cell.
         String whEndFmt = "";
         if      ("AM".equals(portalSlotType))           whEndFmt = "12:00 PM";
         else if ("PM".equals(portalSlotType))           whEndFmt = "6:00 PM";
         else if ("EVENING".equals(portalSlotType))      whEndFmt = "10:00 PM";
         else if ("FULL_DAY".equals(portalSlotType))     whEndFmt = "10:00 PM";
         else if ("NIGHT".equals(portalSlotType))        whEndFmt = "2:00 AM (+1 day)";
         else if ("MIDNIGHT".equals(portalSlotType))     whEndFmt = "6:00 AM";
         else if ("EARLY_MORNING".equals(portalSlotType)) whEndFmt = "8:00 AM";
       %>
      <div class="wh-row">
        <span class="wh-label"><i class="bi bi-calendar-check"></i> Shift</span>
        <span class="wh-val">
        <% if      ("AM".equals(portalSlotType))            { %>🌅 6 AM – 12 PM
		<% } else if ("PM".equals(portalSlotType))           { %>☀️ 12 PM – 6 PM
		<% } else if ("EVENING".equals(portalSlotType))      { %>🌆 6 PM – 10 PM
		<% } else if ("FULL_DAY".equals(portalSlotType))     { %>📅 6 AM – 10 PM
		<% } else if ("NIGHT".equals(portalSlotType))        { %>🌙 10 PM – 2 AM
		<% } else if ("MIDNIGHT".equals(portalSlotType))     { %>🌑 2 AM – 6 AM
		<% } else if ("EARLY_MORNING".equals(portalSlotType)){ %>🌄 4 AM – 8 AM
		<% } else { %>—<% } %>
          &nbsp;<span style="color:var(--text3);font-size:11px;">
            <%=portalSlotStartFmt%>
            – <%=whEndFmt%>
          </span>
        </span>
      </div>
      <div class="wh-row">
        <span class="wh-label">
          <i class="bi bi-circle-fill"
             style="font-size:8px;color:<%=portalIsActive?"var(--green)":portalIsOnBreak?"var(--amber)":portalIsBooked?"var(--blue)":portalIsInactive?"var(--red)":portalIsExpired?"#856404":portalIsCancelled?"var(--red)":portalIsCompleted?"var(--green)":"var(--text3)"%>;"></i>
          Status
        </span>
        <span class="wh-val"
              style="color:<%=portalIsActive?"var(--green)":portalIsOnBreak?"var(--amber)":portalIsBooked?"var(--blue)":portalIsInactive?"var(--red)":portalIsExpired?"#856404":portalIsCancelled?"var(--red)":portalIsCompleted?"var(--green)":"var(--text3)"%>;font-weight:700;">
          <%=portalIsActive    ? "Online · Active"
            : portalIsOnBreak  ? "On Break"
            : portalIsBooked   ? "Booked — Not Started"
            : portalIsInactive ? "Forced Offline"
            : portalIsExpired  ? "Slot Expired"
            : portalIsCancelled? "Cancelled"
            : portalIsCompleted? "Shift Completed"
            : "—"%>
        </span>
      </div>
      <div class="wh-row">
        <span class="wh-label"><i class="bi bi-hourglass-split"></i> Working</span>
        <span class="wh-val" id="shiftWorkingHours"
              style="font-weight:700;font-variant-numeric:tabular-nums;">
          <%=portalIsBooked    ? "Starts at " + portalSlotStartFmt
            : portalIsExpired  ? "Expired at " + portalSlotStartFmt
            : portalIsCancelled? "Cancelled"
            : "—"%>
        </span>
      </div>
      <%-- Ends row: show for active/on-break (live timer), completed (end time), expired/cancelled (slot end) --%>
      <% if (portalIsActive || portalIsOnBreak) { %>
      <div class="wh-row">
        <span class="wh-label"><i class="bi bi-alarm"></i> Ends</span>
        <span class="wh-val" id="shiftTimeRemaining"
              style="font-size:12px;color:var(--text3);">
          <%=whEndFmt%>
        </span>
      </div>
      <% } else if (portalIsCompleted || portalIsExpired || portalIsCancelled) { %>
      <div class="wh-row">
        <span class="wh-label"><i class="bi bi-calendar-x"></i>
          <%=portalIsCancelled ? "Cancelled" : portalIsExpired ? "Expired" : "Ended"%>
        </span>
        <span class="wh-val" style="font-size:12px;color:var(--text3);">
          <%=whEndFmt%> &nbsp;·&nbsp;
          <a href="<%=request.getContextPath()%>/DeliverySlotServlet"
             style="color:var(--brand);font-weight:600;font-size:12px;">
            <i class="bi bi-calendar-plus"></i> Book New Slot
          </a>
        </span>
      </div>
      <% } %>
    <% } %>
  </div>
</div>





    <div class="stats-grid">
      <div class="stat-card">
        <div class="stat-icon-wrap" style="background:var(--brand-lt);color:var(--brand);">📦</div>
        <div class="stat-label">Assigned</div>
        <div class="stat-value"><%= totalOrders %></div>
        <div class="stat-sub">total orders</div>
      </div>
      <div class="stat-card">
        <div class="stat-icon-wrap" style="background:var(--amber-bg);color:var(--amber);">⏳</div>
        <div class="stat-label">Active</div>
        <div class="stat-value"><%= cntActive %></div>
        <div class="stat-sub">in progress</div>
      </div>
      <div class="stat-card">
        <div class="stat-icon-wrap" style="background:var(--teal-bg);color:var(--teal);">🚚</div>
        <div class="stat-label">In Transit</div>
        <div class="stat-value"><%= cntTransit %></div>
        <div class="stat-sub">out for delivery</div>
      </div>
      <div class="stat-card">
        <div class="stat-icon-wrap" style="background:var(--green-bg);color:var(--green);">✅</div>
        <div class="stat-label">Completed</div>
        <div class="stat-value"><%= cntDelivered %></div>
        <div class="stat-sub">delivered today</div>
      </div>
      <div class="stat-card">
        <div class="stat-icon-wrap" style="background:var(--rose-bg);color:var(--rose);">↩️</div>
        <div class="stat-label">Returns</div>
        <div class="stat-value"><%= cntReturn %></div>
        <div class="stat-sub">pickup tasks</div>
      </div>
      <div class="stat-card">
        <div class="stat-icon-wrap" style="background:#E3F2FD;color:#1565C0;">💰</div>
        <div class="stat-label">Earned Today</div>
        <div class="stat-value">₹<%= dbEarnToday.toPlainString() %></div>
        <div class="stat-sub">+ delivery charges</div>
      </div>
    </div>

    <% if (cntCod > 0) { %>
    <div style="background:var(--amber-bg);border:1px solid #F6D860;border-radius:var(--radius);padding:12px 18px;margin-bottom:18px;display:flex;align-items:center;gap:10px;">
      <i class="bi bi-cash-coin" style="font-size:20px;color:var(--amber);"></i>
      <div style="flex:1;">
        <strong style="color:var(--amber);">COD Alert</strong>
        <div style="font-size:13px;color:var(--text2);">You have <strong><%= cntCod %> COD order<%= cntCod > 1 ? "s" : "" %></strong> with ₹<%= String.format("%.2f", codAmountPending) %> to collect.</div>
      </div>
      <button class="fbtn" onclick="showPage('orders');filterOrders('cod',document.querySelector('#page-orders .fbtn[data-filter=cod]'))">View COD</button>
    </div>
    <% } %>

    <div class="map-placeholder">
      <i class="bi bi-map"></i>
      <span>Live Route Map — integrate Google Maps SDK here</span>
    </div>

    <div class="sec-head">
      <span class="sec-title">Active Orders <span style="font-size:13px;font-weight:400;color:var(--text3);">(showing first 3)</span></span>
      <button class="fbtn" onclick="showPage('orders')">View All →</button>
    </div>
    <div class="orders-grid">
      <%
        if (!orders.isEmpty()) {
          int shown = 0;
          for (Order order : orders) {
            if (shown >= 3) break;
            String st = order.getStatus() == null ? "Pending" : order.getStatus();
            String stl = st.toLowerCase();
            if (stl.equals("delivered") || stl.equals("cancelled") || stl.equals("refunded") || stl.equals("replaced") || stl.equals("return picked") || stl.equals("replacement dispatch")) continue;
            shown++;
            boolean dCOD = "COD".equalsIgnoreCase(order.getPaymentMethod());
            boolean dReturn = stl.contains("return");
            String dBadge = stl.contains("out") || stl.contains("transit") ? "sb-transit"
                          : stl.contains("picked") ? "sb-picked" : "sb-assigned";
      %>
      <div class="order-card <%= dCOD ? "cod-urgent" : "" %> <%= dReturn ? "return-order" : "" %>"
       data-orderId="<%= order.getId() %>" 
     data-customer="<%= order.getCustomerName() %>" 
           data-payment="<%= order.getPaymentMethod() == null ? "" : order.getPaymentMethod().toLowerCase() %>">
        <div class="card-head">
          <div>
            <div class="card-order-id">#<%= order.getId() %></div>
            <div class="card-date"><i class="bi bi-calendar3"></i> <%= order.getDeliveryDate() != null ? order.getDeliveryDate() : "Today" %></div>
          </div>
          <div style="display:flex;flex-direction:column;align-items:flex-end;gap:4px;">
            <% if (dCOD) { %><span class="sbadge" style="background:#FFF3E0;color:#E65100;font-size:10px;">COD</span><% } %>
            <% if (dReturn) { %><span class="sbadge sb-rose" style="font-size:10px;">Return</span><% } %>
            <span class="sbadge <%= dBadge %>"><%= st %></span>
          </div>
        </div>
        <div class="card-body-pad">
          <div class="info-row"><i class="bi bi-person-fill"></i><strong><%= order.getCustomerName() %></strong></div>
          <% String dPhone = order.getPhone() != null ? order.getPhone() : ""; %>
          <% if (!dPhone.isEmpty()) { %>
          <div class="info-row">
            <i class="bi bi-telephone-fill" style="color:var(--green);"></i>
            <a href="tel:<%= dPhone %>" style="font-size:13px;color:var(--green);font-weight:600;"><%= dPhone %></a>
          </div>
          <% } %>
          <div class="info-row">
            <i class="bi bi-geo-alt-fill"></i>
            <% String da = order.getAddress(); %>
            <% if (da != null && !da.trim().isEmpty()) { %>
              <a href="https://maps.google.com/?q=<%= java.net.URLEncoder.encode(da,"UTF-8") %>" target="_blank"><%= da %></a>
            <% } else { %><span style="color:var(--red);">No address on file</span><% } %>
          </div>
          <% if (!dPhone.isEmpty()) { %>
          <div class="quick-contact">
            <a class="qc-btn qc-call" href="tel:<%= dPhone %>"><i class="bi bi-telephone-fill"></i> Call Customer</a>
            <% if (da != null && !da.trim().isEmpty()) { %>
            <a class="qc-btn qc-map" href="https://maps.google.com/?q=<%= java.net.URLEncoder.encode(da,"UTF-8") %>" target="_blank"><i class="bi bi-map"></i> Navigate</a>
            <% } %>
          </div>
          <% } %>
          <div class="total-bar" style="padding-top:6px;">
            <span style="color:var(--text2);font-size:13px;">Total</span>
            <span>₹<%= String.format("%.2f", order.getTotalAmount()) %></span>
          </div>
          <div class="action-bar">
            <button class="act-btn btn-transit" onclick="showPage('orders')" style="width:100%;">
              <i class="bi bi-arrow-right-circle"></i> Manage Order
            </button>
          </div>
        </div>
      </div>
      <% } } else { %>
      <div class="empty" style="grid-column:1/-1;"><i class="bi bi-inbox"></i><p>No active orders right now.</p></div>
      <% } %>
    </div>
  </div>

  <!-- ════ ORDERS (ACTIVE) ════ -->
  <div class="page" id="page-orders">
    <div class="pg-head">
      <h1>Active Orders</h1>
      <p>Manage and update your in-progress deliveries &amp; return pickups.</p>
    </div>

    <div class="filter-bar">
      <button class="fbtn active" data-filter="all"     onclick="filterOrders('all',this)">All (<%= cntActive %>)</button>
      <button class="fbtn" data-filter="pending"        onclick="filterOrders('pending',this)">Pending (<%= cntPending %>)</button>
      <button class="fbtn" data-filter="transit"        onclick="filterOrders('transit',this)">In Transit (<%= cntTransit %>)</button>
      <button class="fbtn" data-filter="return"         onclick="filterOrders('return',this)">Returns (<%= cntReturn %>)</button>
      <button class="fbtn" data-filter="cod"            onclick="filterOrders('cod',this)">COD (<%= cntCod %>)</button>
      <div class="search-box">
        <i class="bi bi-search"></i>
        <input type="text" placeholder="Search order / customer…" oninput="searchOrders(this.value)"/>
      </div>
    </div>

    <div class="orders-grid" id="orderContainer">
      <%
        if (!orders.isEmpty()) {
          for (Order order : orders) {
            String status  = order.getStatus() == null ? "Pending" : order.getStatus();
            String statusL = status.toLowerCase();
            boolean isCOD     = "COD".equalsIgnoreCase(order.getPaymentMethod());
            boolean isCodPaid = "PAID".equalsIgnoreCase(order.getPaymentStatus())
                             || "DEPOSITED".equalsIgnoreCase(order.getPaymentStatus());
            // A Delivered COD order whose cash hasn't been deposited yet still needs
            // action — don't skip it. All other terminal statuses go to history.
            boolean isCodAwaitingDeposit = statusL.equals("delivered") && isCOD && !isCodPaid;
            if (!isCodAwaitingDeposit && (
                 statusL.equals("delivered") || statusL.equals("cancelled")
              || statusL.equals("refunded")  || statusL.equals("replaced")
              || statusL.equals("return picked") || statusL.equals("replacement dispatch")
              || statusL.equals("return requested")
            )) continue;

            boolean isReturn = statusL.contains("return");

            /* ── REAL-WORLD PIPELINE URGENCY ── */
            boolean isUrgent = (statusL.equals("out for delivery") || isCodAwaitingDeposit) && isCOD && !isCodPaid;

            String badgeCls;
            if      (statusL.equals("out for delivery"))             badgeCls = "sb-transit";
            else if (statusL.equals("picked up"))                    badgeCls = "sb-picked";
            else if (statusL.equals("assigned"))                     badgeCls = "sb-assigned";
            else if (statusL.equals("shipped") || statusL.equals("packed")) badgeCls = "sb-picked";
            else if (statusL.equals("confirmed"))                    badgeCls = "sb-assigned";
            else if (statusL.equals("processing"))                   badgeCls = "sb-transit";
            else if (statusL.contains("return"))                     badgeCls = "sb-rose";
            else                                                     badgeCls = "sb-pending";

            /* ── Progress step flags ── */
            boolean s1 = true, s2, s3, s4;
            if (isReturn) {
              s2 = statusL.contains("agent assigned") || statusL.contains("out for pickup") || statusL.equals("processing");
              s3 = statusL.contains("out for pickup") || statusL.equals("processing");
              s4 = false;
            } else {
              s2 = statusL.equals("picked up") || statusL.equals("out for delivery");
              s3 = statusL.equals("out for delivery");
              s4 = false;
            }

            boolean isThisOtpOrder = activeOtpOrderId != null
                                  && activeOtpOrderId.equals(String.valueOf(order.getId()));
            boolean otpGenerated = isThisOtpOrder && "true".equals(otpGeneratedFlag);
            boolean otpSuccess   = isThisOtpOrder && "true".equals(otpSuccessFlag);
            boolean otpFailed    = isThisOtpOrder && "true".equals(otpFailedFlag);
            boolean showOtpBox   = otpGenerated || otpSuccess || otpFailed;

            /* ── Next-action button logic ── */
            String nextStatus       = "";
            String btnLabel         = "";
            String btnClass         = "";
            String btnIcon          = "";
            String nextReturnStatus = "";
            boolean showCancelBtn   = false;

            if (statusL.equals("return requested")) {
                btnLabel = ""; // awaiting admin
            } else if (statusL.equals("return approved")) {
                nextStatus       = "Return Agent Assigned";
                nextReturnStatus = "Approved";
                btnLabel         = "Accept Return Task";
                btnClass         = "btn-transit";
                btnIcon          = "bi-clipboard-check";
                showCancelBtn    = true;
            } else if (statusL.equals("return agent assigned")) {
                nextStatus       = "Return Out for Pickup";
                nextReturnStatus = "Approved";
                btnLabel         = "Head to Customer";
                btnClass         = "btn-transit";
                btnIcon          = "bi-bicycle";
                showCancelBtn    = true;
            } else if (statusL.equals("return out for pickup")) {
                nextStatus       = "Processing";
                nextReturnStatus = "Processing";
                btnLabel         = "Confirm Item Collected";
                btnClass         = "btn-pickup-return";
                btnIcon          = "bi-box-arrow-in-down";
            } else if (statusL.equals("processing")) {
                nextStatus       = "Return Picked";
                nextReturnStatus = "Picked";
                btnLabel         = "Handover to Hub";
                btnClass         = "btn-deliver";
                btnIcon          = "bi-building-check";
            } else if (statusL.equals("ordered") || statusL.equals("pending") || statusL.equals("confirmed")) {
            	 nextStatus    = "Picked Up"; 
            	 btnLabel      = "Accept Order";
                btnClass      = "btn-pickup";
                btnIcon       = "bi-hand-thumbs-up";
                showCancelBtn = true;
            } else if (statusL.equals("assigned")) {
                nextStatus    = "Picked Up";
                btnLabel      = "Accept Task";
                btnClass      = "btn-pickup";
                btnIcon       = "bi-bag-check";
                showCancelBtn = true;
            } else if (statusL.equals("packed") || statusL.equals("shipped")) {
                nextStatus    = "Picked Up";
                btnLabel      = "Mark Picked Up";
                btnClass      = "btn-pickup";
                btnIcon       = "bi-bag-check";
                showCancelBtn = true;
            } else if (statusL.equals("picked up")) {
                nextStatus    = "Out for Delivery";
                btnLabel      = "Set Out for Delivery";
                btnClass      = "btn-transit";
                btnIcon       = "bi-truck";
                showCancelBtn = true;
            } else if (statusL.equals("out for delivery")) {
                // btnLabel stays empty — OTP flow handles delivery action
                showCancelBtn = true; // rider must still be able to report can't deliver
            }
      %>
      <div class="order-card <%= isCodAwaitingDeposit ? "cod-deposit-due" : isCOD ? "cod-urgent" : "" %> <%= isReturn ? "return-order" : "" %>"
           data-status="<%= statusL %>"
           data-payment="<%= order.getPaymentMethod() == null ? "" : order.getPaymentMethod().toLowerCase() %>"
           data-customer="<%= order.getCustomerName() == null ? "" : order.getCustomerName().toLowerCase() %>"
           data-orderId="<%= order.getId() %>">

        <!-- Card Head -->
        <div class="card-head">
          <div>
            <div class="card-order-id">#<%= order.getId() %></div>
            <div class="card-date"><i class="bi bi-calendar3"></i> <%= order.getDeliveryDate() != null ? order.getDeliveryDate() : "Today" %></div>
          </div>
          <div style="display:flex;flex-direction:column;align-items:flex-end;gap:4px;">
            <% if (isCOD) { %><span class="sbadge" style="background:#FFF3E0;color:#E65100;font-size:10px;"><i class="bi bi-cash-coin"></i> COD</span><% } %>
            <% if (isReturn) { %><span class="sbadge sb-rose" style="font-size:10px;"><i class="bi bi-arrow-return-left"></i> Return</span><% } %>
            <span class="sbadge <%= badgeCls %>"><%= status %></span>
            <% if (isUrgent) { %><span class="priority-urgent"><i class="bi bi-lightning-fill"></i> URGENT</span><% } %>
          </div>
        </div>

        <!-- Card Body -->
        <div class="card-body-pad">

          <%-- ── COD DEPOSIT DUE BANNER (shown after OTP verified, before deposit) ── --%>
          <% if (isCodAwaitingDeposit) { %>
          <div style="background:var(--amber-bg);border:1px solid #F6D860;border-radius:9px;
                      padding:11px 14px;margin-bottom:12px;display:flex;align-items:flex-start;gap:10px;">
            <i class="bi bi-exclamation-triangle-fill" style="color:var(--amber);font-size:20px;flex-shrink:0;margin-top:1px;"></i>
            <div>
              <div style="font-weight:700;font-size:14px;color:var(--amber);">Cash Pending Deposit</div>
              <div style="font-size:12px;color:var(--text2);margin-top:3px;line-height:1.5;">
                OTP verified. You are carrying <strong>₹<%= String.format("%.2f", order.getTotalAmount()) %></strong>
                from this order. Hand it to the hub supervisor and click <strong>Deposit Cash</strong> below.
              </div>
            </div>
          </div>
          <% } %>

          <!-- Customer info -->
          <div class="info-row"><i class="bi bi-person-fill"></i><strong><%= order.getCustomerName() %></strong></div>
          <% String custPhone = order.getPhone() != null ? order.getPhone() : ""; %>
          <% if (!custPhone.isEmpty()) { %>
          <div class="info-row">
            <i class="bi bi-telephone-fill" style="color:var(--green);"></i>
            <a href="tel:<%= custPhone %>" style="font-size:13px;color:var(--green);font-weight:600;"><%= custPhone %></a>
          </div>
          <% } %>
          <div class="info-row"><i class="bi bi-envelope-fill"></i><span style="font-size:13px;"><%= order.getCustomerEmail() != null ? order.getCustomerEmail() : "—" %></span></div>

          <!-- Address + quick contact -->
          <div class="info-row">
            <i class="bi bi-geo-alt-fill"></i>
            <% String addr = order.getAddress(); %>
            <% if (addr != null && !addr.trim().isEmpty()) { %>
              <span><%= addr %></span>
            <% } else { %><span style="color:var(--red);">No address on file</span><% } %>
          </div>
          <div class="quick-contact">
            <% if (!custPhone.isEmpty()) { %>
            <a class="qc-btn qc-call"
               href="tel:<%= custPhone %>">
              <i class="bi bi-telephone-fill"></i> Call Customer</a>
            <% } %>
            <% if (addr != null && !addr.trim().isEmpty()) { %>
            <a class="qc-btn qc-map"
               href="https://maps.google.com/?q=<%= java.net.URLEncoder.encode(addr,"UTF-8") %>"
               target="_blank"><i class="bi bi-map"></i> Navigate</a>
            <% } %>
            <% if (!custPhone.isEmpty()) { %>
            <a class="qc-btn qc-whatsapp"
               href="https://wa.me/<%= custPhone.replaceAll("[^0-9]","") %>?text=Hi,+I+am+your+delivery+agent+for+order+%23<%= order.getId() %>.+Please+be+available+for+delivery."
               target="_blank"><i class="bi bi-whatsapp"></i> WhatsApp</a>
            <% } %>
          </div>

          <!-- Products -->
          <table class="prod-table">
            <% if (order.getItems() != null) { for (CartItem item : order.getItems()) { %>
            <tr>
              <td><%= item.getName() %> <span style="color:var(--text3);">×<%= item.getQuantity() %></span></td>
              <td>₹<%= String.format("%.2f", item.getFinalPrice() * item.getQuantity()) %></td>
            </tr>
            <% } } %>
          </table>
          <div class="total-bar">
            <span>Order Total</span>
            <span>₹<%= String.format("%.2f", order.getTotalAmount()) %></span>
          </div>

          <!-- Payment -->
        <div class="pay-row">
            <span style="font-size:13px;color:var(--text2);">Payment:</span>
            <% if (isCodPaid) { %>
              <span class="cod-collected-badge"><i class="bi bi-check-circle-fill"></i> COD Collected</span>
            <% } else { %>
              <span class="sbadge sb-unpaid">
                <i class="bi bi-exclamation-circle"></i>
                <%= order.getPaymentMethod() %> — <%= order.getPaymentStatus() != null ? order.getPaymentStatus() : "Pending" %>
              </span>
            <% } %>
          </div>
           

          <!-- Progress steps -->
          <div class="prog-track">
            <% if (!isReturn) { %>
            <div class="prog-step <%= (s2||s3) ? "done" : "active" %>">
              <div class="step-circle"><% if(s2||s3){ %><i class="bi bi-check" style="font-size:9px;"></i><% } %></div>
              <div class="step-lbl"><% if(statusL.equals("confirmed")||statusL.equals("ordered")||statusL.equals("pending")){ %>Confirmed<% } else { %>Picked Up <% } %></div>
            </div>
            <div class="prog-step <%= s2 ? (s3 ? "done" : "active") : "" %>">
              <div class="step-circle"><% if(s3){ %><i class="bi bi-check" style="font-size:9px;"></i><% } %></div>
              <div class="step-lbl">Picked Up</div>
            </div>
            <div class="prog-step <%= s3 ? "active" : "" %>">
              <div class="step-circle"></div>
              <div class="step-lbl">Out for Del.</div>
            </div>
            <div class="prog-step">
              <div class="step-circle"></div>
              <div class="step-lbl">Delivered</div>
            </div>
            <% } else { %>
            <div class="prog-step <%= statusL.contains("approved")||statusL.contains("agent")||statusL.contains("out for pickup")||statusL.equals("processing") ? "done" : "active" %>">
              <div class="step-circle"><% if(statusL.contains("approved")||statusL.contains("agent")||statusL.contains("out for pickup")||statusL.equals("processing")){ %><i class="bi bi-check" style="font-size:9px;"></i><% } %></div>
              <div class="step-lbl">Approved</div>
            </div>
            <div class="prog-step <%= statusL.contains("agent assigned") ? (statusL.contains("out for pickup")||statusL.equals("processing") ? "done":"active") : (statusL.contains("approved")?"active":"") %>">
              <div class="step-circle"><% if(statusL.contains("out for pickup")||statusL.equals("processing")){ %><i class="bi bi-check" style="font-size:9px;"></i><% } %></div>
              <div class="step-lbl">Agent Assigned</div>
            </div>
            <div class="prog-step <%= statusL.equals("processing") || statusL.contains("out for pickup") ? "active" : "" %>">
              <div class="step-circle"></div>
              <div class="step-lbl">Out for Pickup</div>
            </div>
            <div class="prog-step">
              <div class="step-circle"></div>
              <div class="step-lbl">Picked &amp; Hub</div>
            </div>
            <% } %>
          </div>

          <!-- OTP Box -->
			<div class="otp-card <%= (showOtpBox && String.valueOf(order.getId()).equals(activeOtpOrderId)) ? "show" : "" %>"
			     id="otpbox-<%= order.getId() %>">
			  <div class="otp-header">
			    <span class="otp-shield"><i class="bi bi-shield-lock-fill"></i></span>
			    <div>
			      <div class="otp-title">OTP Verification</div>
			      <div class="otp-sub">Enter the 6-digit code from customer</div>
			    </div>
			  </div>
			
			  <% if (otpSuccess) { %>
			    <div class="otp-banner success">
			      <i class="bi bi-patch-check-fill"></i> Order <strong>#<%= order.getId() %></strong> marked as Delivered!
			    </div>
			    <script>setTimeout(function(){ window.location.href='<%= request.getContextPath() %>/DeliveryPortalServlet'; }, 3500);</script>
			  <% } else if (otpFailed) { %>
			    <div class="otp-banner error">
			      <i class="bi bi-x-octagon-fill"></i> Incorrect OTP — please try again.
			    </div>
			  <% } else if (otpGenerated) { %>
			    <div class="otp-banner info">
			      <i class="bi bi-send-check-fill"></i> OTP sent to customer successfully.
			    </div>
			  <% } %>
			
			  <% if (showOtpBox && String.valueOf(order.getId()).equals(activeOtpOrderId)) { %>
			    <script>
			      document.addEventListener('DOMContentLoaded', function() {
			        const b = document.getElementById('otpbox-<%= order.getId() %>');
			        if (b) {
			          b.style.display = 'block';
			          b.classList.add('show');
			          b.scrollIntoView({ behavior: 'smooth', block: 'center' });
			          const f = b.querySelector('.otp-digit');
			          if (f) f.focus();
			        }
			      });
			    </script>
			  <% } %>
			
			  <% if (!otpSuccess) { %>
             <form action="OtpVerificationServlet" method="post"  id="otpForm-<%= order.getId() %>">
      			    <input type="hidden" name="orderId" value="<%= order.getId() %>"/>
			    <div class="otp-digits" id="digits-<%= order.getId() %>">
			      <input class="otp-digit" type="text" maxlength="1" inputmode="numeric" pattern="[0-9]"/>
			      <input class="otp-digit" type="text" maxlength="1" inputmode="numeric" pattern="[0-9]"/>
			      <input class="otp-digit" type="text" maxlength="1" inputmode="numeric" pattern="[0-9]"/>
			      <input class="otp-digit" type="text" maxlength="1" inputmode="numeric" pattern="[0-9]"/>
			      <input class="otp-digit" type="text" maxlength="1" inputmode="numeric" pattern="[0-9]"/>
			      <input class="otp-digit" type="text" maxlength="1" inputmode="numeric" pattern="[0-9]"/>
			    </div>
			    <input type="hidden" name="otp" id="otpHidden-<%= order.getId() %>"/>
			   <button type="button" class="otp-verify-btn"
				        onclick="collectOtp('<%= order.getId() %>')">
				  <i class="bi bi-check2-circle"></i> Verify &amp; Complete Delivery
				</button>
							  </form>
			  <% } %>
			</div>
			          <!-- Action buttons -->
          <div class="action-bar" id="actionBar_<%= order.getId() %>">

            <%-- Hidden status field — filled by JSP, never empty (BUG 2 fix) --%>
            <input type="hidden" id="statusInput_<%= order.getId() %>"
                   value="<%= nextStatus %>"/>

            <% if (!btnLabel.isEmpty()) { %>
              <form action="OrdersDashboard" method="post" style="flex:1;"
                    id="statusForm_<%= order.getId() %>">
                <input type="hidden" name="source"  value="delivery"/>
                <input type="hidden" name="action"  value="updateStatus"/>
                <input type="hidden" name="orderId" value="<%= order.getId() %>"/>
                <input type="hidden" name="status"  id="formStatus_<%= order.getId() %>"
                       value="<%= nextStatus %>"/>
                <%-- BUG 2 FIX: type="button" so pressing it never submits with empty value --%>
                <%-- BUG 5 FIX: no customerName in onclick — read from data-customer attr --%>
                <button type="button"
                        class="act-btn <%= btnClass %>" style="width:100%;"
                        onclick="openStatusConfirm('<%= order.getId() %>')">
                  <i class="bi <%= btnIcon %>"></i> <%= btnLabel %>
                </button>
              </form>

            <% } else if (statusL.equals("out for delivery")) { %>
             <form action="GenerateOtpServlet" method="post" style="flex:1;"
				      id="statusForm_<%= order.getId() %>">
				  <input type="hidden" name="orderId" value="<%= order.getId() %>"/>
				  <button type="submit" class="act-btn btn-genotp" style="width:100%;">
				    <i class="bi bi-key"></i> Send OTP &amp; Deliver
				  </button>
				</form>

            <% } else if (btnLabel.isEmpty()
                          && !statusL.equals("out for delivery")
                          && !statusL.equals("return requested")) { %>
              <div style="flex:1;text-align:center;color:var(--text3);font-size:13px;padding:8px 0;">
                <i class="bi bi-hourglass-split"></i> Awaiting next step
              </div>
            <% } %>

            <%-- Reject / Can't Deliver / Cancel Pickup buttons --%>
            <% if (showCancelBtn && !isReturn) { %>
              <% if (statusL.equals("out for delivery")) { %>
                <button class="act-btn btn-danger"
                        onclick="openCantDeliverConfirm('<%= order.getId() %>')"
                        title="Report failed delivery attempt" aria-label="Can't Deliver">
                  <i class="bi bi-x-circle"></i> Can't Deliver
                </button>
              <% } else { %>
                <button class="act-btn btn-danger"
                        onclick="openRejectTaskConfirm('<%= order.getId() %>')"
                        title="Reject this task assignment" aria-label="Reject Task">
                  <i class="bi bi-slash-circle"></i> Reject Task
                </button>
              <% } %>
            <% } else if (showCancelBtn && isReturn) { %>
              <button class="act-btn btn-danger"
                      onclick="openCancelPickupConfirm('<%= order.getId() %>')"
                      title="Cancel this return pickup" aria-label="Cancel Pickup">
                <i class="bi bi-x-circle"></i> Cancel Pickup
              </button>
            <% } %>
            <%-- COD Deposit button: shown when agent is carrying cash (out for delivery / picked up)
                 AND after OTP verified (delivered but not yet deposited) --%>
            <% if (isCOD && !isCodPaid && (statusL.equals("out for delivery") || statusL.equals("picked up") || isCodAwaitingDeposit)) { %>
            <a href="<%= request.getContextPath() %>/CodDepositServlet?orderId=<%= order.getId() %>"
               class="act-btn"
               style="background:var(--amber-bg);color:var(--amber);border-color:#F6D860;font-weight:700;"
               title="Deposit ₹<%= String.format("%.0f", order.getTotalAmount()) %> COD cash at hub"
               aria-label="Deposit COD Cash">
              <i class="bi bi-cash-stack"></i> Deposit ₹<%= String.format("%.0f", order.getTotalAmount()) %> Cash
            </a>
            <% } %>
            <% if (isCOD && !isCodPaid) { %>
            <div class="upi-row" style="width:100%;">
              <form action="<%= request.getContextPath() %>/CreateRazorpayQrServlet"
                    method="post" style="flex:1;">
                <input type="hidden" name="orderId" value="<%= order.getId() %>"/>
                <input type="hidden" name="amount"  value="<%= order.getTotalAmount() %>"/>
                <button type="submit" class="act-btn btn-upi" style="width:100%;padding:9px;font-size:13px;">
                  <i class="bi bi-upc-scan"></i> Collect via UPI QR
                </button>
              </form>
            </div>
            <% } %>
          </div>

        </div><!-- /card-body-pad -->
      </div><!-- /order-card -->
      <% } } else { %>
      <div class="empty" style="grid-column:1/-1;"><i class="bi bi-inbox"></i><p>No active orders right now.</p></div>
      <% } %>
    </div>
  </div><!-- /page-orders -->

  <!-- ════ HISTORY ════ -->
  <%
  // ── Pull backend data ──────────────────────────────────────────────────────
  @SuppressWarnings("unchecked")
  List<Map<String,Object>> slotBookings =
      (List<Map<String,Object>>) request.getAttribute("slotBookings");
  if (slotBookings == null) slotBookings = new java.util.ArrayList<>();

  @SuppressWarnings("unchecked")
  Map<Integer, List<Map<String,Object>>> slotOrdersMap =
      (Map<Integer, List<Map<String,Object>>>) request.getAttribute("slotOrdersMap");
  if (slotOrdersMap == null) slotOrdersMap = new java.util.HashMap<>();

  // Segment into three groups
  List<Map<String,Object>> bookedSlots    = new java.util.ArrayList<>();
  List<Map<String,Object>> activeSlots    = new java.util.ArrayList<>();
  List<Map<String,Object>> cancelledSlots = new java.util.ArrayList<>();

  for (Map<String,Object> b : slotBookings) {
    String bs = String.valueOf(b.get("bookingStatus"));
    if ("BOOKED".equalsIgnoreCase(bs))                                                                    bookedSlots.add(b);
    else if ("ACTIVE".equalsIgnoreCase(bs) || "ON_BREAK".equalsIgnoreCase(bs)
          || "COMPLETED".equalsIgnoreCase(bs) || "INACTIVE".equalsIgnoreCase(bs))                        activeSlots.add(b);
    else if ("CANCELLED".equalsIgnoreCase(bs) || "EXPIRED".equalsIgnoreCase(bs))                         cancelledSlots.add(b);
  }

  SimpleDateFormat dfDate = new SimpleDateFormat("dd MMM yyyy");
  SimpleDateFormat dfTime = new SimpleDateFormat("hh:mm a, dd MMM");
%>

<!-- ════ HISTORY ════ -->
<div class="page" id="page-history">
  <div class="pg-head">
    <h1>Delivery History</h1>
    <p>Your slot timeline, assignments, and completed deliveries.</p>
  </div>

  <!-- ── View Toggle ──────────────────────────────────────────────────────── -->
  <div class="history-view-toggle">
    <button class="hvt-btn active" onclick="switchHistoryView('slots', this)">
      <i class="bi bi-grid-3x2-gap"></i> Slot View
    </button>
    <button class="hvt-btn" onclick="switchHistoryView('orders', this)">
      <i class="bi bi-list-ul"></i> Order View
    </button>
  </div>

  <!-- ══════════════════════════════════════════════════════════════════════ -->
  <!-- SLOT GRID VIEW (primary)                                              -->
  <!-- ══════════════════════════════════════════════════════════════════════ -->
  <div id="history-slot-view">

    <!-- ── SECTION A: Booked Slots ──────────────────────────────────────── -->
    <div class="slot-section">
      <div class="slot-section-header sa-header">
        <span class="slot-section-dot dot-booked"></span>
        <span class="slot-section-title">Booked Slots</span>
        <span class="slot-section-count"><%= bookedSlots.size() %></span>
        <span class="slot-section-sub">Upcoming · Pending · Locked</span>
      </div>
      <% if (bookedSlots.isEmpty()) { %>
        <div class="slot-empty-state">
          <i class="bi bi-calendar2-check" style="font-size:28px;color:var(--text3);"></i>
          <p>No upcoming booked slots.</p>
        </div>
      <% } else { %>
        <div class="slot-grid">
          <% for (Map<String,Object> b : bookedSlots) {
               int slotId  = (Integer) b.get("slotId");
               String sType = String.valueOf(b.get("slotType"));
               Object sdObj = b.get("slotDate");
               String sDate = sdObj != null ? dfDate.format(sdObj) : "—";
               String zone  = String.valueOf(b.get("zoneName"));
               int maxO     = b.get("maxOrders") != null ? (Integer)b.get("maxOrders") : 0;
               List<Map<String,Object>> slotOrders = slotOrdersMap.getOrDefault(slotId, java.util.Collections.emptyList());
          %>
          <div class="slot-card sc-booked" data-slotid="<%= slotId %>">
            <div class="sc-top">
              <div class="sc-slot-badge badge-booked"><i class="bi bi-clock"></i> BOOKED</div>
              <div class="sc-slot-meta">
                <strong><%= sType %></strong> &nbsp;·&nbsp; <%= sDate %>
              </div>
              <div class="sc-zone"><i class="bi bi-geo-alt"></i> <%= zone %></div>
            </div>
            <div class="sc-counters">
              <div class="sc-counter-item">
                <span class="sc-counter-val"><%= maxO %></span>
                <span class="sc-counter-lbl">Max Orders</span>
              </div>
              <div class="sc-counter-item">
                <span class="sc-counter-val"><%= slotOrders.size() %></span>
                <span class="sc-counter-lbl">Assigned</span>
              </div>
            </div>
            <% if (!slotOrders.isEmpty()) { %>
              <button class="sc-expand-btn" onclick="toggleSubgrid(this, 'sg-<%= slotId %>')">
                <i class="bi bi-chevron-down"></i> View <%= slotOrders.size() %> order(s)
              </button>
              <div class="slot-subgrid" id="sg-<%= slotId %>" style="display:none;">
                <table class="subgrid-table">
                  <thead>
                    <tr>
                      <th>Order ID</th>
                      <th>Customer</th>
                      <th>Address</th>
                      <th>Status</th>
                      <th>Payment</th>
                      <th>Value</th>
                    </tr>
                  </thead>
                  <tbody>
                    <% for (Map<String,Object> ord : slotOrders) {
                         String pMethod = String.valueOf(ord.get("paymentMethod"));
                         String pStatus = String.valueOf(ord.get("paymentStatus"));
                         boolean isCod  = "COD".equalsIgnoreCase(pMethod);
                         boolean isDep  = "DEPOSITED".equalsIgnoreCase(pStatus) || Boolean.TRUE.equals(ord.get("codDeposited"));
                         String payBadgeClass = isCod ? (isDep ? "sg-badge-deposited" : "sg-badge-cod") : "sg-badge-prepaid";
                         String payLabel      = isCod ? (isDep ? "COD ✓ Dep" : "COD") : pMethod;
                         Object amt = ord.get("totalAmount");
                         String amtStr = amt != null ? String.format("₹%.2f", ((java.math.BigDecimal)amt).doubleValue()) : "—";
                    %>
                    <tr>
                      <td><span class="sg-order-id">#<%= ord.get("orderId") %></span></td>
                      <td><%= ord.get("customerName") %></td>
                      <td class="sg-address"><%= ord.get("deliveryAddress") %></td>
                      <td><span class="sg-status-badge sg-status-<%= String.valueOf(ord.get("status")).toLowerCase().replace(" ","-") %>">
                            <%= ord.get("status") %>
                          </span></td>
                      <td><span class="sg-pay-badge <%= payBadgeClass %>"><%= payLabel %></span></td>
                      <td class="sg-amount"><strong><%= amtStr %></strong></td>
                    </tr>
                    <% } %>
                  </tbody>
                </table>
              </div>
            <% } %>
          </div>
          <% } %>
        </div>
      <% } %>
    </div><!-- /Section A -->

    <!-- ── SECTION B: Active / Completed Slots ──────────────────────────── -->
    <div class="slot-section">
      <div class="slot-section-header sb-header">
        <span class="slot-section-dot dot-active"></span>
        <span class="slot-section-title">Active &amp; Completed Slots</span>
        <span class="slot-section-count"><%= activeSlots.size() %></span>
        <span class="slot-section-sub">Current active or successfully finished</span>
      </div>
      <% if (activeSlots.isEmpty()) { %>
        <div class="slot-empty-state">
          <i class="bi bi-check2-all" style="font-size:28px;color:var(--text3);"></i>
          <p>No completed slots yet. Finish your first shift to see it here.</p>
        </div>
      <% } else { %>
        <div class="slot-grid">
          <% for (Map<String,Object> b : activeSlots) {
               int slotId  = (Integer) b.get("slotId");
               String sType = String.valueOf(b.get("slotType"));
               Object sdObj = b.get("slotDate");
               String sDate = sdObj != null ? dfDate.format(sdObj) : "—";
               String zone  = String.valueOf(b.get("zoneName"));
               int pendC    = b.get("pendingCount")   != null ? (Integer)b.get("pendingCount")   : 0;
               int actC     = b.get("activeCount")    != null ? (Integer)b.get("activeCount")    : 0;
               int delC     = b.get("deliveredCount") != null ? (Integer)b.get("deliveredCount") : 0;
               Object chAt  = b.get("statusChangedAt");
               String completedAt = chAt != null ? dfTime.format(chAt) : "—";
               List<Map<String,Object>> slotOrders = slotOrdersMap.getOrDefault(slotId, java.util.Collections.emptyList());
          %>
          <div class="slot-card sc-completed" data-slotid="<%= slotId %>">
            <div class="sc-top">
              <div class="sc-slot-badge badge-completed"><i class="bi bi-check-circle"></i> COMPLETED</div>
              <div class="sc-slot-meta">
                <strong><%= sType %></strong> &nbsp;·&nbsp; <%= sDate %>
              </div>
              <div class="sc-zone"><i class="bi bi-geo-alt"></i> <%= zone %></div>
            </div>
            <div class="sc-counters">
              <div class="sc-counter-item">
                <span class="sc-counter-val sc-val-green"><%= delC %></span>
                <span class="sc-counter-lbl">Delivered</span>
              </div>
              <div class="sc-counter-item">
                <span class="sc-counter-val sc-val-amber"><%= pendC %></span>
                <span class="sc-counter-lbl">Pending</span>
              </div>
              <div class="sc-counter-item">
                <span class="sc-counter-val sc-val-blue"><%= actC %></span>
                <span class="sc-counter-lbl">In Transit</span>
              </div>
            </div>
            <div class="sc-completed-at">
              <i class="bi bi-calendar-check"></i> Completed <%= completedAt %>
            </div>
            <% if (!slotOrders.isEmpty()) { %>
              <button class="sc-expand-btn" onclick="toggleSubgrid(this, 'sg-<%= slotId %>')">
                <i class="bi bi-chevron-down"></i> View <%= slotOrders.size() %> order(s)
              </button>
              <div class="slot-subgrid" id="sg-<%= slotId %>" style="display:none;">
                <table class="subgrid-table">
                  <thead>
                    <tr>
                      <th>Order ID</th><th>Customer</th><th>Address</th>
                      <th>Status</th><th>Payment</th><th>Value</th>
                    </tr>
                  </thead>
                  <tbody>
                    <% for (Map<String,Object> ord : slotOrders) {
                         String pMethod = String.valueOf(ord.get("paymentMethod"));
                         String pStatus = String.valueOf(ord.get("paymentStatus"));
                         boolean isCod  = "COD".equalsIgnoreCase(pMethod);
                         boolean isDep  = "DEPOSITED".equalsIgnoreCase(pStatus) || Boolean.TRUE.equals(ord.get("codDeposited"));
                         String payBadgeClass = isCod ? (isDep ? "sg-badge-deposited" : "sg-badge-cod") : "sg-badge-prepaid";
                         String payLabel      = isCod ? (isDep ? "COD ✓ Dep" : "COD ⚠ Pending") : pMethod;
                         Object amt = ord.get("totalAmount");
                         String amtStr = amt != null ? String.format("₹%.2f", ((java.math.BigDecimal)amt).doubleValue()) : "—";
                    %>
                    <tr<%= (isCod && !isDep) ? " class=\"sg-row-cod-warn\"" : "" %>>
                      <td><span class="sg-order-id">#<%= ord.get("orderId") %></span></td>
                      <td><%= ord.get("customerName") %></td>
                      <td class="sg-address"><%= ord.get("deliveryAddress") %></td>
                      <td><span class="sg-status-badge sg-status-<%= String.valueOf(ord.get("status")).toLowerCase().replace(" ","-") %>">
                            <%= ord.get("status") %></span></td>
                      <td><span class="sg-pay-badge <%= payBadgeClass %>"><%= payLabel %></span></td>
                      <td class="sg-amount"><strong><%= amtStr %></strong></td>
                    </tr>
                    <% } %>
                  </tbody>
                </table>
              </div>
            <% } %>
          </div>
          <% } %>
        </div>
      <% } %>
    </div><!-- /Section B -->

    <!-- ── SECTION C: Cancelled & Expired Slots ──────────────────────────── -->
    <div class="slot-section">
      <div class="slot-section-header sc-header">
        <span class="slot-section-dot dot-cancelled"></span>
        <span class="slot-section-title">Cancelled &amp; Expired Slots</span>
        <span class="slot-section-count"><%= cancelledSlots.size() %></span>
        <span class="slot-section-sub">Manually aborted or time-expired bookings</span>
      </div>
      <% if (cancelledSlots.isEmpty()) { %>
        <div class="slot-empty-state">
          <i class="bi bi-slash-circle" style="font-size:28px;color:var(--text3);"></i>
          <p>No cancelled or expired slots.</p>
        </div>
      <% } else { %>
        <div class="slot-grid">
          <% for (Map<String,Object> b : cancelledSlots) {
               int slotId  = (Integer) b.get("slotId");
               String sType = String.valueOf(b.get("slotType"));
               Object sdObj = b.get("slotDate");
               String sDate = sdObj != null ? dfDate.format(sdObj) : "—";
               String zone  = String.valueOf(b.get("zoneName"));
               String bs    = String.valueOf(b.get("bookingStatus"));
               boolean isExp = "Expired".equalsIgnoreCase(bs);
               Object chAt  = b.get("statusChangedAt");
               String changedAt = chAt != null ? dfTime.format(chAt) : "—";
               List<Map<String,Object>> slotOrders = slotOrdersMap.getOrDefault(slotId, java.util.Collections.emptyList());
          %>
          <div class="slot-card sc-cancelled" data-slotid="<%= slotId %>">
            <div class="sc-top">
              <div class="sc-slot-badge <%= isExp ? "badge-expired" : "badge-cancelled" %>">
                <i class="bi bi-<%= isExp ? "alarm" : "x-circle" %>"></i>
                <%= isExp ? "EXPIRED" : "CANCELLED" %>
              </div>
              <div class="sc-slot-meta">
                <strong><%= sType %></strong> &nbsp;·&nbsp; <%= sDate %>
              </div>
              <div class="sc-zone"><i class="bi bi-geo-alt"></i> <%= zone %></div>
            </div>
            <div class="sc-cancelled-reason">
              <% if (isExp) { %>
                <i class="bi bi-hourglass-bottom" style="color:var(--amber);"></i>
                Slot start time passed without activation
              <% } else { %>
                <i class="bi bi-x-circle" style="color:var(--red);"></i>
                Cancelled on <%= changedAt %>
              <% } %>
            </div>
            <% if (!slotOrders.isEmpty()) { %>
              <button class="sc-expand-btn" onclick="toggleSubgrid(this, 'sg-<%= slotId %>')">
                <i class="bi bi-chevron-down"></i> View <%= slotOrders.size() %> reassigned order(s)
              </button>
              <div class="slot-subgrid" id="sg-<%= slotId %>" style="display:none;">
                <table class="subgrid-table">
                  <thead>
                    <tr>
                      <th>Order ID</th><th>Customer</th><th>Address</th>
                      <th>Status</th><th>Payment</th><th>Value</th>
                    </tr>
                  </thead>
                  <tbody>
                    <% for (Map<String,Object> ord : slotOrders) {
                         String pMethod = String.valueOf(ord.get("paymentMethod"));
                         boolean isCod  = "COD".equalsIgnoreCase(pMethod);
                         Object amt = ord.get("totalAmount");
                         String amtStr = amt != null ? String.format("₹%.2f", ((java.math.BigDecimal)amt).doubleValue()) : "—";
                    %>
                    <tr>
                      <td><span class="sg-order-id">#<%= ord.get("orderId") %></span></td>
                      <td><%= ord.get("customerName") %></td>
                      <td class="sg-address"><%= ord.get("deliveryAddress") %></td>
                      <td><span class="sg-status-badge sg-status-<%= String.valueOf(ord.get("status")).toLowerCase().replace(" ","-") %>">
                            <%= ord.get("status") %></span></td>
                      <td><span class="sg-pay-badge <%= isCod ? "sg-badge-cod" : "sg-badge-prepaid" %>"><%= pMethod %></span></td>
                      <td class="sg-amount"><strong><%= amtStr %></strong></td>
                    </tr>
                    <% } %>
                  </tbody>
                </table>
              </div>
            <% } %>
          </div>
          <% } %>
        </div>
      <% } %>
    </div><!-- /Section C -->

  </div><!-- /history-slot-view -->
<script>
/**
 * Toggle between "Slot View" and "Order View" tabs on the History page.
 */
function switchHistoryView(view, btn) {
  document.querySelectorAll('.hvt-btn').forEach(b => b.classList.remove('active'));
  btn.classList.add('active');
  document.getElementById('history-slot-view').style.display  = view === 'slots'  ? '' : 'none';
  document.getElementById('history-order-view').style.display = view === 'orders' ? '' : 'none';
}

/**
 * Toggle the sub-grid expansion for a slot card.
 * Animates chevron icon and smoothly expands the sub-grid.
 */
function toggleSubgrid(btn, subgridId) {
  const sg = document.getElementById(subgridId);
  if (!sg) return;
  const isOpen = sg.style.display !== 'none';
  sg.style.display = isOpen ? 'none' : '';
  btn.classList.toggle('open', !isOpen);
}
</script>

  <!-- ══════════════════════════════════════════════════════════════════════ -->
  <!-- ORDER LIST VIEW (secondary tab — existing table, preserved as-is)    -->
  <!-- ══════════════════════════════════════════════════════════════════════ -->
  <div id="history-order-view" style="display:none;">
    <div class="filter-bar">
      <button class="fbtn active" onclick="filterHistory('all',this)">All (<%= cntHistory %>)</button>
      <button class="fbtn" onclick="filterHistory('delivered',this)">Delivered (<%= cntDelivered %>)</button>
      <button class="fbtn" onclick="filterHistory('cancelled',this)">Cancelled</button>
      <button class="fbtn" onclick="filterHistory('return',this)">Returns</button>
      <button class="fbtn" onclick="filterHistory('refunded',this)">Refunded</button>
      <div class="search-box">
        <i class="bi bi-search"></i>
        <input type="text" placeholder="Search order / customer…" oninput="searchHistory(this.value)"/>
      </div>
    </div>
    <%-- Original hist-table kept intact below --%>
    <div class="section-panel" style="overflow-x:auto;">
      <table class="hist-table" id="historyTable">
        <thead>
          <tr>
            <th>Order ID</th><th>Customer</th><th>Delivery Date</th>
            <th>Amount</th><th>Payment</th><th>Status</th><th>Details</th>
          </tr>
        </thead>
        <tbody>
 <tbody>
        <%
          boolean anyHistory = false;
          for (Order hOrder : orders) {
            String hStatus  = hOrder.getStatus() == null ? "" : hOrder.getStatus();
            String hStatusL = hStatus.toLowerCase();
            boolean hIsCod  = "COD".equalsIgnoreCase(hOrder.getPaymentMethod());
            boolean hCodDue = hStatusL.equals("delivered") && hIsCod
                           && !"PAID".equalsIgnoreCase(hOrder.getPaymentStatus())
                           && !"DEPOSITED".equalsIgnoreCase(hOrder.getPaymentStatus());
            // Skip orders that are still pending deposit — they're in the active section
            boolean isHist  = (hStatusL.equals("delivered") && !hCodDue) || hStatusL.equals("cancelled")
                           || hStatusL.equals("refunded")  || hStatusL.equals("replaced")
                           || hStatusL.equals("return picked") || hStatusL.equals("replacement dispatch");
            if (!isHist) continue;
            anyHistory = true;
            String hBadge;
            if      (hStatusL.equals("delivered"))    hBadge = "sb-delivered";
            else if (hStatusL.equals("cancelled"))    hBadge = "sb-pending";
            else if (hStatusL.equals("refunded"))     hBadge = "sb-picked";
            else if (hStatusL.equals("replaced"))     hBadge = "sb-transit";
            else                                      hBadge = "sb-assigned";
            boolean hCodPaid = "PAID".equalsIgnoreCase(hOrder.getPaymentStatus());
        %>
          <tr class="hist-row" data-hstatus="<%= hStatusL %>"
              data-hcustomer="<%= hOrder.getCustomerName() == null ? "" : hOrder.getCustomerName().toLowerCase() %>">
            <td><span class="card-order-id">#<%= hOrder.getId() %></span></td>
            <td><strong><%= hOrder.getCustomerName() %></strong>
              <div style="font-size:11px;color:var(--text3);"><%= hOrder.getCustomerEmail() != null ? hOrder.getCustomerEmail() : "" %></div>
            </td>
            <td style="color:var(--text3);font-size:13px;"><%= hOrder.getDeliveryDate() != null ? hOrder.getDeliveryDate() : "—" %></td>
            <td style="font-weight:700;">₹<%= String.format("%.2f", hOrder.getTotalAmount()) %></td>
            <td><span class="sbadge <%= hCodPaid || "PAID".equalsIgnoreCase(hOrder.getPaymentStatus()) ? "sb-paid":"sb-unpaid" %>"><%= hOrder.getPaymentMethod() %></span></td>
            <td><span class="sbadge <%= hBadge %>"><%= hStatus %></span>
              <% if (hStatusL.equals("return picked")) { %>
                <div style="font-size:11px;color:var(--amber);margin-top:3px;"><i class="bi bi-hourglass-split"></i> Refund Pending</div>
              <% } else if (hStatusL.equals("cancelled") && !"REFUNDED".equalsIgnoreCase(hOrder.getPaymentStatus()) && !"COD".equalsIgnoreCase(hOrder.getPaymentMethod())) { %>
                <div style="font-size:11px;color:var(--amber);margin-top:3px;"><i class="bi bi-clock"></i> Refund Processing</div>
              <% } else if (hStatusL.equals("replaced")) { %>
                <div style="font-size:11px;color:var(--teal);margin-top:3px;"><i class="bi bi-arrow-repeat"></i> Replacement Dispatched</div>
              <% } else if (hStatusL.equals("delivered") && "COD".equalsIgnoreCase(hOrder.getPaymentMethod()) && !"PAID".equalsIgnoreCase(hOrder.getPaymentStatus()) && !"DEPOSITED".equalsIgnoreCase(hOrder.getPaymentStatus())) { %>
                <div style="margin-top:6px;">
                  <a href="<%= request.getContextPath() %>/CodDepositServlet?orderId=<%= hOrder.getId() %>"
                     style="display:inline-flex;align-items:center;gap:5px;background:var(--amber-bg);color:var(--amber);
                            border:1px solid #F6D860;border-radius:6px;padding:4px 10px;
                            font-size:12px;font-weight:700;text-decoration:none;">
                    <i class="bi bi-cash-stack"></i> Deposit ₹<%= String.format("%.0f", hOrder.getTotalAmount()) %>
                  </a>
                </div>
              <% } %>
            </td>
            <td style="font-size:12px;">
              <a href="<%= request.getContextPath() %>/OrdersDashboard?action=view&orderId=<%= hOrder.getId() %>"
                 target="_blank" style="color:var(--brand);font-weight:600;">
                <i class="bi bi-eye"></i> View
              </a>
            </td>
          </tr>
        <% } if (!anyHistory) { %>
          <tr><td colspan="7" style="text-align:center;padding:40px;color:var(--text3);">
            <i class="bi bi-clock-history" style="font-size:30px;display:block;margin-bottom:8px;"></i>No completed orders yet.
          </td></tr>
        <% } %>
        </tbody>        </tbody>
      </table>
    </div>
  </div>

</div><!-- /page-history -->
  <!-- ── WALLET ──────────────────────────────────────────────────── -->
<div class="page" id="page-wallet">
  <div class="wallet-header">
    <h2><i class="fas fa-wallet"></i>&nbsp; My Wallet &amp; Earnings</h2>
    <button class="btn-refresh" onclick="refreshWalletData()" title="Refresh">
      <i class="fas fa-sync-alt"></i>
    </button>
  </div>

  <!-- Status banner (shown when balance below minimum) -->
  <div id="walletBanner" class="wallet-banner danger" style="display:none;"></div>

  <!-- Balance cards -->
  <div class="wallet-cards-row">
    <div class="wcard wcard-main">
      <div class="wcard-label">Available Balance</div>
      <div class="wcard-value" id="wAvailBalance">₹—</div>
      <div class="wcard-sub">
        Total: <span id="wBalance">—</span> &nbsp;|&nbsp;
        COD held: <span id="wCodFloat">—</span>
      </div>
      <div class="wcard-progress-wrap">
        <div class="wcard-progress-track">
          <div class="wcard-progress-bar" id="wProgressBar" style="width:0%;"></div>
        </div>
        <div class="wcard-progress-label">Min required: <span id="wMinBalance">—</span></div>
      </div>
    </div>
    <div class="wcard wcard-earned">
      <div class="wcard-label">Total Earned</div>
      <div class="wcard-value" id="wTotalEarned">₹—</div>
      <div class="wcard-sub">Since account creation</div>
    </div>
    <div class="wcard wcard-withdrawn">
      <div class="wcard-label">Total Withdrawn</div>
      <div class="wcard-value" id="wTotalWithdrawn">₹—</div>
      <div class="wcard-sub">Lifetime payouts</div>
    </div>
  </div>

  <!-- Earnings strip -->
  <div class="earnings-strip">
    <div class="estrip-item"><div class="estrip-val" id="eToday">₹—</div><div class="estrip-lbl">Today</div></div>
    <div class="estrip-sep"></div>
    <div class="estrip-item"><div class="estrip-val" id="eWeek">₹—</div><div class="estrip-lbl">This Week</div></div>
    <div class="estrip-sep"></div>
    <div class="estrip-item"><div class="estrip-val" id="eMonth">₹—</div><div class="estrip-lbl">This Month</div></div>
  </div>

  <!-- Weekly bar chart -->
  <div class="wchart-wrap">
    <div class="wchart-title">Last 7 Days Earnings</div>
    <div class="wchart" id="wBarChart"></div>
    <div class="wchart-days" id="wChartDays"></div>
  </div>

  <!-- Actions -->
	  <div class="wallet-actions" style="display:flex;gap:12px;flex-wrap:wrap;align-items:center;">
	<!-- Withdraw button -->
	  <button class="btn-withdraw" id="btnWithdraw">
	    <i class="fas fa-arrow-up"></i>&nbsp; Request Withdrawal
	  </button>
	  <!-- Pending withdrawal chip — hidden by default, shown by JS if a request is pending -->
	  <span id="wPendingChip" style="display:none;align-items:center;gap:6px;
	       background:#fff8e1;border:1px solid #f59e0b;color:#92400e;border-radius:20px;
	       padding:5px 13px;font-size:.78rem;font-weight:600;">
	    <i class="fas fa-clock"></i> Withdrawal Pending Review
	  </span>
	
	 
	
	  <!-- NEW: Top-Up button -->
	  <button class="btn-topup" id="btnTopUp" onclick="openTopUpModal()">
	    <i class="bi bi-plus-circle-fill"></i> Top Up Wallet
	  </button>
	 <% if (cntCod > 0) { %>
	    <button onclick="showPage('orders');filterOrders('cod',document.querySelector('#page-orders .fbtn[data-filter=cod]'))"
	       style="display:inline-flex;align-items:center;gap:7px;background:var(--amber);color:#fff;
	              border-radius:8px;padding:11px 22px;font-size:.95rem;font-weight:600;
	              border:none;font-family:var(--font);cursor:pointer;transition:background .2s;"
	       onmouseover="this.style.background='#9a4500'" onmouseout="this.style.background='var(--amber)'">
	      <i class="bi bi-cash-stack"></i> View COD Orders (<%= cntCod %>)
	    </button>
	    <% } %>
	
	</div>
   

  <!-- Transaction table -->
  <div class="wtxn-section">
    <h3>Transaction History</h3>
    <div class="wtxn-table-wrap">
      <table class="wtxn-table">
        <thead>
          <tr>
            <th>#</th><th>Date &amp; Time</th><th>Description</th>
            <th>Order</th><th>Type</th><th>Amount</th><th>Balance After</th><th>cod-held After</th>
          </tr>
        </thead>
        <tbody id="wTxnBody">
          <tr><td colspan="7" class="wtxn-empty">Loading…</td></tr>
        </tbody>
      </table>
    </div>
    <div class="wtxn-pagination">
      <button class="btn-page" id="wPrevPage" disabled>&#8592; Prev</button>
      <span id="wPageLabel">Page 1</span>
      <button class="btn-page" id="wNextPage">Next &#8594;</button>
    </div>
  </div>
</div><!-- /#page-wallet -->


<!-- ══════════════════════════════════════════════════════════════════
     WITHDRAW MODAL
     ══════════════════════════════════════════════════════════════════ -->
<div id="withdrawModal" class="wmodal-overlay" style="display:none;">
  <div class="wmodal">
    <div class="wmodal-header">
      <h3><i class="fas fa-arrow-up"></i> Request Withdrawal</h3>
      <button class="wmodal-close" id="wModalClose">&times;</button>
    </div>
    <div class="wmodal-body">
      <!-- Pending withdrawal notice — shown by JS if _walletData.pendingWithdrawal is set -->
      <div id="wPendingNotice" style="display:none;background:#fff8e1;border-left:3px solid #f59e0b;
           border-radius:6px;padding:10px 13px;margin-bottom:14px;font-size:.83rem;color:#92400e;">
        <i class="fas fa-clock"></i>
        <span id="wPendingNoticeText">You already have a pending withdrawal request.</span>
      </div>
      <p class="wmodal-hint">Available for withdrawal: <strong id="wModalAvail">₹—</strong></p>
      <label>Amount (₹)</label>
      <input type="number" id="wWithdrawAmt" min="100" step="50" placeholder="Enter amount" />
      <label style="margin-top:10px;">Reason <span style="font-weight:400;color:var(--muted);">(optional)</span></label>
      <textarea id="wWithdrawReason" rows="2" placeholder="e.g. Monthly expenses, petrol, etc."
        style="width:100%;border:1px solid #ddd;border-radius:7px;padding:8px 10px;
               font-size:.85rem;resize:vertical;font-family:inherit;"></textarea>
      <p class="wmodal-note">
        <i class="fas fa-info-circle"></i>
        Minimum balance of <span id="wModalMin">₹500</span> must be maintained.
        Your request will be reviewed by a supervisor within 24 hours.
      </p>
    </div>
    <div class="wmodal-footer">
      <button class="btn-cancel" id="wModalCancel">Cancel</button>
      <button class="btn-confirm" id="wModalConfirm">Submit Request</button>
    </div>
  </div>
</div>
<div id="topupModalOverlay" class="topup-modal-overlay">
  <div class="topup-modal" id="topupModal">

    <!-- Default view: amount selection -->
    <div id="topupFormView">
      <div class="topup-modal-head">
        <h3><i class="bi bi-lightning-charge-fill"></i> Top Up Wallet</h3>
        <p>Add funds to stay active & accept COD orders</p>
        <div class="topup-balance-strip">
          <div class="topup-bal-item">
            <div class="topup-bal-val" id="tuCurrentBal">₹—</div>
            <div class="topup-bal-lbl">Current Balance</div>
          </div>
          <div class="topup-bal-item">
            <div class="topup-bal-val" id="tuMinBal">₹500</div>
            <div class="topup-bal-lbl">Min Required</div>
          </div>
          <div class="topup-bal-item">
            <div class="topup-bal-val" id="tuNeeded" style="color:#ffe082;">₹—</div>
            <div class="topup-bal-lbl">Top-Up Needed</div>
          </div>
        </div>
      </div>

      <div class="topup-modal-body">
        <div class="topup-quick-label">Quick Amounts</div>
        <div class="topup-quick-grid">
          <button class="topup-quick-btn" onclick="selectTopUpAmt(500)">₹500</button>
          <button class="topup-quick-btn" onclick="selectTopUpAmt(1000)">₹1,000</button>
          <button class="topup-quick-btn" onclick="selectTopUpAmt(2000)">₹2,000</button>
          <button class="topup-quick-btn" onclick="selectTopUpAmt(5000)">₹5,000</button>
        </div>

        <div class="topup-input-wrap">
          <span class="topup-input-prefix">₹</span>
          <input type="number" id="topupAmtInput" class="topup-amount-input"
                 placeholder="Enter amount" min="100" step="50"
                 oninput="onTopUpAmtChange(this.value)" />
        </div>

        <div class="topup-breakdown" id="topupBreakdown">
          <table>
            <tr><td>Top-up amount</td>         <td id="tdTopupAmt">—</td></tr>
            <tr><td>Balance after top-up</td>  <td id="tdBalAfter">—</td></tr>
            <tr class="highlight"><td>Available to withdraw</td><td id="tdAvailAfter">—</td></tr>
          </table>
        </div>

        <div class="topup-purpose-info">
          <i class="bi bi-info-circle-fill"></i>
          <span>Funds are used as security for COD deliveries.
          If your balance drops below ₹<span id="tuMinNote">500</span>,
          you'll be set <strong>Offline</strong> and won't receive new orders
          until you top up.</span>
        </div>
      </div>

      <div class="topup-modal-footer">
        <button class="topup-cancel-btn" onclick="closeTopUpModal()">Cancel</button>
        <button class="topup-pay-btn" id="topupPayBtn" onclick="initiateTopUp()" disabled>
          <i class="bi bi-shield-lock-fill"></i>
          Pay Securely
        </button>
      </div>
      <div class="razorpay-badge">
        <i class="bi bi-lock-fill"></i> Secured by Razorpay
      </div>
    </div>

    <!-- Processing view -->
    <div id="topupProcessingView" style="display:none;">
      <div class="topup-processing">
        <div class="topup-spinner"></div>
        <p>Processing your payment…<br>
           <span style="font-size:.78rem;color:var(--text3);">Please do not close this window</span>
        </p>
      </div>
    </div>

    <!-- Success view -->
    <div id="topupSuccessView" class="topup-success">
      <div class="topup-success-icon"><i class="bi bi-check-lg"></i></div>
      <h4>Top-Up Successful!</h4>
      <p id="topupSuccessMsg">₹1,000 has been added to your wallet.</p>
      <div style="margin-top:18px;">
        <button class="topup-pay-btn" style="width:100%;justify-content:center;"
                onclick="closeTopUpModal();loadWalletData();">
          <i class="bi bi-wallet2"></i> View Wallet
        </button>
      </div>
    </div>

    <!-- Failed view -->
    <div id="topupFailedView" class="topup-failed">
      <div class="topup-failed-icon"><i class="bi bi-x-lg"></i></div>
      <p id="topupFailedMsg">Payment could not be completed. Please try again.</p>
      <button class="topup-retry-btn" onclick="showTopUpForm()">
        <i class="bi bi-arrow-counterclockwise"></i> Try Again
      </button>
    </div>

  </div>
</div>

  <!-- ════ EARNINGS ════ -->
  <div class="page" id="page-earnings">
    <div class="pg-head"><h1>My Earnings</h1><p>Track your delivery income and payouts.</p></div>
    <div class="earn-grid">
      <div class="earn-card">
        <div class="earn-label">Today</div>
        <div class="earn-val">₹<%= dbEarnToday.toPlainString() %></div>
        <div class="earn-sub"><%= cntDelivered %> deliveries</div>
      </div>
      <div class="earn-card">
        <div class="earn-label">This Week</div>
        <div class="earn-val">₹<%= dbEarnWeek.toPlainString() %></div>
        <div class="earn-sub">Last 7 days</div>
      </div>
      <div class="earn-card">
        <div class="earn-label">This Month</div>
        <div class="earn-val">₹<%= dbEarnMonth.toPlainString() %></div>
        <div class="earn-sub" id="earnMonthLabel">This Month</div>
      </div>
    </div>
    <div class="section-panel" style="margin-bottom:20px;">
      <div class="panel-head">Weekly Breakdown — Last 7 Days</div>
      <div style="padding:16px 20px;">
        <%-- BUG FIX: Previously a hardcoded mock bar chart {420,510,380,640,570,820,540}.
             Now dynamically populated from real wallet data via JS (_renderEarningsPage). --%>
        <div class="earn-bar-wrap" id="earningsBarWrap">
          <div style="text-align:center;padding:24px 0;color:var(--text3);font-size:13px;">
            <i class="bi bi-bar-chart-line" style="font-size:24px;display:block;margin-bottom:6px;"></i>
            Loading weekly breakdown…
          </div>
        </div>
      </div>
    </div>
    <div class="section-panel">
      <div class="panel-head">Recent Transactions</div>
      <%-- BUG FIX: Replaced 5 hardcoded fake rows (May 4 / #1042 etc.) with live data
           fetched from AgentWalletServlet — same endpoint as the Wallet tab. --%>
      <div class="wtxn-table-wrap">
        <table class="wtxn-table">
          <thead>
            <tr>
              <th>#</th><th>Date &amp; Time</th><th>Description</th>
              <th>Order</th><th>Type</th><th>Amount</th><th>Balance After</th>
            </tr>
          </thead>
          <tbody id="earnTxnBody">
            <tr><td colspan="7" class="wtxn-empty">Loading transactions…</td></tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>

  <!-- ════ NOTIFICATIONS ════ -->
  <div class="page" id="page-notifications">

    <%-- Header --%>
    <div class="notif-page-header">
      <div>
        <div class="notif-page-title">
          Notifications
          <span class="notif-badge" id="notifBadgeCount" style="display:none"></span>
        </div>
        <div class="notif-page-sub">Stay updated on orders, earnings &amp; shift alerts</div>
      </div>
      <div class="notif-actions">
        <button class="fbtn" id="notifMarkAllBtn" onclick="_notifMarkAllRead()" style="font-size:12px">
          <i class="bi bi-check2-all"></i> Mark all read
        </button>
        <button class="fbtn" onclick="_notifRefresh()" style="font-size:12px">
          <i class="bi bi-arrow-clockwise"></i>
        </button>
      </div>
    </div>

    <%-- Filter tabs --%>
    <div class="notif-tabs" id="notifTabs">
      <button class="notif-tab active" data-filter="all"      onclick="_notifFilter('all',this)">All</button>
      <button class="notif-tab"        data-filter="unread"   onclick="_notifFilter('unread',this)">Unread</button>
      <button class="notif-tab"        data-filter="orders"   onclick="_notifFilter('orders',this)">Orders</button>
      <button class="notif-tab"        data-filter="earnings" onclick="_notifFilter('earnings',this)">Earnings</button>
      <button class="notif-tab"        data-filter="shifts"   onclick="_notifFilter('shifts',this)">Shifts</button>
    </div>

    <%-- Skeleton shown while loading --%>
    <div id="notifSkeleton">
      <div class="ncard-skeleton notif-shimmer"></div>
      <div class="ncard-skeleton notif-shimmer" style="opacity:.7"></div>
      <div class="ncard-skeleton notif-shimmer" style="opacity:.4"></div>
    </div>

    <%-- Live feed — populated by JS --%>
    <div id="notifFeed" style="display:none"></div>

    <%-- Empty state --%>
    <div id="notifEmpty" style="display:none">
      <div class="notif-empty">
        <div class="notif-empty-ico">🔔</div>
        <div class="notif-empty-txt">All caught up!</div>
        <div class="notif-empty-sub">No notifications to show for this filter.</div>
      </div>
    </div>

  </div><%-- end page-notifications --%>
<%
  // ── KYC Registration record ───────────────────────────────────────────────
  com.util.DeliveryRegistration kycReg =
      (com.util.DeliveryRegistration) request.getAttribute("kycReg");
  boolean hasKyc      = (kycReg != null);
  boolean kycPending  = hasKyc && "PENDING".equalsIgnoreCase(kycReg.getStatus());
  boolean kycApproved = hasKyc && "APPROVED".equalsIgnoreCase(kycReg.getStatus());
  boolean kycRejected = hasKyc && "REJECTED".equalsIgnoreCase(kycReg.getStatus());

  // Pull real values from KYC record; fall back to session data
  String kycFullName = hasKyc
      ? ((kycReg.getFirstName()  != null ? kycReg.getFirstName()  : "") + " "
       + (kycReg.getMiddleName() != null ? kycReg.getMiddleName() + " " : "")
       + (kycReg.getLastName()   != null ? kycReg.getLastName()   : "")).trim()
      : dbName;
  String kycPhone   = hasKyc && kycReg.getMobile()       != null ? kycReg.getMobile()       : dbPhone;
  String kycEmail   = hasKyc && kycReg.getEmail()        != null ? kycReg.getEmail()        : dbEmail;
  String kycZone    = hasKyc && kycReg.getDeliveryZone() != null ? kycReg.getDeliveryZone() : dbZone;
  String kycVehicle = hasKyc
      ? ((kycReg.getVehicleBrand() != null ? kycReg.getVehicleBrand() : "")
       + " " + (kycReg.getVehicleModel() != null ? kycReg.getVehicleModel() : "")
       + (kycReg.getVehicleRegNumber() != null ? " · " + kycReg.getVehicleRegNumber() : "")).trim()
      : dbVehicle;

  // Initials — prefer KYC full name
  String kycInitials;
  if (!kycFullName.isEmpty()) {
      String[] kycParts = kycFullName.trim().split("\\s+");
      kycInitials = kycParts.length >= 2
          ? ("" + kycParts[0].charAt(0) + kycParts[kycParts.length-1].charAt(0)).toUpperCase()
          : kycFullName.substring(0,1).toUpperCase();
  } else {
      kycInitials = initials;
  }

  // Build register-page URL with username pre-filled (for redirect CTA)
  // DeliveryRegisterServlet reads "prefillUsername" to load existing data
  String registerUrl = request.getContextPath()
      + "/deliveryRegister.jsp?prefillUsername="
      + java.net.URLEncoder.encode(deliveryUser.getUsername(), "UTF-8");
%>



 <!-- ════ PROFILE ════ -->
  <div class="page" id="page-profile">
    <div class="pg-head">
      <h1>My Profile</h1>
      <p>Your personal details, KYC documents, vehicle info, and performance.</p>
    </div>

    <%-- ── KYC Status Banner ───────────────────────────────────────────── --%>
    <% if (kycApproved) { %>
    <div class="kyc-banner approved">
      <div class="kyc-banner-ico"><i class="bi bi-patch-check-fill"></i></div>
      <div class="kyc-banner-body">
        <strong>KYC Verified &amp; Approved</strong>
        <span>Your identity and documents have been verified. You are cleared to deliver.</span>
      </div>
    </div>

    <% } else if (kycPending) { %>
    <div class="kyc-banner pending">
      <div class="kyc-banner-ico"><i class="bi bi-hourglass-split"></i></div>
      <div class="kyc-banner-body">
        <strong>KYC Under Review</strong>
        <span>Your application was submitted on <%= kycReg.getSubmittedAt() != null ? kycReg.getSubmittedAt().substring(0,10) : "—" %>. Admin review is in progress — usually within 1–2 business days.</span>
      </div>
    </div>

    <% } else if (kycRejected) { %>
    <div class="kyc-banner rejected">
      <div class="kyc-banner-ico"><i class="bi bi-x-circle-fill"></i></div>
      <div class="kyc-banner-body">
        <strong>KYC Rejected — Action Required</strong>
        <span>Your application was rejected. Please review the reason below and re-submit with corrected documents.</span>
      </div>
    </div>

    <% } else { %>
    <div class="kyc-banner missing">
      <div class="kyc-banner-ico"><i class="bi bi-person-badge"></i></div>
      <div class="kyc-banner-body">
        <strong>KYC Not Submitted</strong>
        <span>Complete your KYC registration to go online and start accepting deliveries.</span>
      </div>
    </div>
    <% } %>


    <%-- ══════════════════════════════════════════════════════════════════
         CASE 1: Agent HAS a KYC record — show profile detail cards
    ═══════════════════════════════════════════════════════════════════════ --%>
    <% if (hasKyc) { %>
    <div class="profile-grid">

      <%-- ── Left column: avatar card ──────────────────────────────────── --%>
      <div>
        <div class="profile-card">
          <div class="p-avatar-lg"><%= kycInitials %></div>
          <div class="p-name"><%= kycFullName.isEmpty() ? dbName : kycFullName %></div>
          <div class="p-role">Delivery Rider · <%= kycZone %></div>
          <div class="online-chip" style="margin:10px auto 0; width:fit-content;">
            <div class="pulse-dot <%= isCurrentlyActive ? "" : "off" %>"></div>
            <%= isCurrentlyActive ? "Active" : "Offline" %>
          </div>
          <div class="p-stats" style="margin-top:18px;">
            <div class="pstat"><div class="pstat-val"><%= dbDeliveries %></div><div class="pstat-label">Deliveries</div></div>
            <div class="pstat"><div class="pstat-val"><%= dbRating %>★</div><div class="pstat-label">Rating</div></div>
            <div class="pstat">
              <div class="pstat-val">
                <span class="doc-chip <%= kycApproved ? "verified" : kycPending ? "pending" : "rejected" %>">
                  <%= kycApproved ? "✓ KYC" : kycPending ? "⏳ KYC" : "✗ KYC" %>
                </span>
              </div>
              <div class="pstat-label">Status</div>
            </div>
          </div>
        </div>
      </div>

      <%-- ── Right column: tabbed detail panels ─────────────────────────── --%>
      <div>
        <div class="kyc-tabs">
          <button class="kyc-tab active" onclick="switchKycTab(this,'ktab-personal')"><i class="bi bi-person"></i> Personal</button>
          <button class="kyc-tab" onclick="switchKycTab(this,'ktab-kycdocs')"><i class="bi bi-file-earmark-text"></i> KYC Docs</button>
          <button class="kyc-tab" onclick="switchKycTab(this,'ktab-vehicle')"><i class="bi bi-truck"></i> Vehicle</button>
          <button class="kyc-tab" onclick="switchKycTab(this,'ktab-bank')"><i class="bi bi-bank"></i> Bank</button>
          <button class="kyc-tab" onclick="switchKycTab(this,'ktab-performance')"><i class="bi bi-bar-chart"></i> Performance</button>
        </div>

        <%-- Tab: Personal ─────────────────────────────────────────────── --%>
        <div class="kyc-tab-panel active" id="ktab-personal">
          <div class="info-panel">
            <div class="ip-head">Personal Details</div>
            <div class="ip-row"><span class="ip-key"><i class="bi bi-person"></i> Full Name</span><span class="ip-val"><%= kycFullName.isEmpty() ? "—" : kycFullName %></span></div>
            <div class="ip-row"><span class="ip-key"><i class="bi bi-calendar3"></i> Date of Birth</span><span class="ip-val"><%= kycReg.getDob() != null ? kycReg.getDob() : "—" %></span></div>
            <div class="ip-row"><span class="ip-key"><i class="bi bi-gender-ambiguous"></i> Gender</span><span class="ip-val"><%= kycReg.getGender() != null ? kycReg.getGender() : "—" %></span></div>
            <div class="ip-row"><span class="ip-key"><i class="bi bi-heart-pulse"></i> Blood Group</span><span class="ip-val"><%= kycReg.getBloodGroup() != null ? kycReg.getBloodGroup() : "—" %></span></div>
            <div class="ip-row"><span class="ip-key"><i class="bi bi-telephone"></i> Mobile</span><span class="ip-val"><a href="tel:<%= kycPhone %>"><%= kycPhone.isEmpty() ? "—" : kycPhone %></a></span></div>
            <div class="ip-row"><span class="ip-key"><i class="bi bi-telephone-plus"></i> Alt Mobile</span><span class="ip-val"><%= kycReg.getAltMobile() != null ? kycReg.getAltMobile() : "—" %></span></div>
            <div class="ip-row"><span class="ip-key"><i class="bi bi-envelope"></i> Email</span><span class="ip-val"><%= kycEmail.isEmpty() ? "—" : kycEmail %></span></div>
          </div>
          <div class="info-panel" style="margin-top:14px;">
            <div class="ip-head">Address</div>
            <div class="ip-row"><span class="ip-key"><i class="bi bi-house"></i> Address</span>
              <span class="ip-val">
                <%= kycReg.getAddressLine1() != null ? kycReg.getAddressLine1() : "" %>
                <% if (kycReg.getAddressLine2() != null && !kycReg.getAddressLine2().isBlank()) { %>, <%= kycReg.getAddressLine2() %><% } %>
                <% if (kycReg.getLandmark()    != null && !kycReg.getLandmark().isBlank())    { %>, Near <%= kycReg.getLandmark() %><% } %>
              </span>
            </div>
            <div class="ip-row"><span class="ip-key"><i class="bi bi-geo-alt"></i> City / State</span><span class="ip-val"><%= kycReg.getCity() != null ? kycReg.getCity() : "—" %>, <%= kycReg.getState() != null ? kycReg.getState() : "—" %> — <%= kycReg.getPincode() != null ? kycReg.getPincode() : "" %></span></div>
            <div class="ip-row"><span class="ip-key"><i class="bi bi-pin-map"></i> Delivery Zone</span><span class="ip-val"><%= kycZone %></span></div>
          </div>
          <div class="info-panel" style="margin-top:14px;">
            <div class="ip-head">Emergency Contact</div>
            <div class="ip-row"><span class="ip-key"><i class="bi bi-person-heart"></i> Name</span><span class="ip-val"><%= kycReg.getEmergencyName() != null ? kycReg.getEmergencyName() : "—" %></span></div>
            <div class="ip-row"><span class="ip-key"><i class="bi bi-people"></i> Relation</span><span class="ip-val"><%= kycReg.getEmergencyRelation() != null ? kycReg.getEmergencyRelation() : "—" %></span></div>
            <div class="ip-row"><span class="ip-key"><i class="bi bi-telephone-fill"></i> Mobile</span><span class="ip-val"><%= kycReg.getEmergencyMobile() != null ? kycReg.getEmergencyMobile() : "—" %></span></div>
          </div>
        </div>

        <%-- Tab: KYC Docs ─────────────────────────────────────────────── --%>
        <div class="kyc-tab-panel" id="ktab-kycdocs">
          <div class="info-panel">
            <div class="ip-head">Identity Documents</div>
            <div class="ip-row">
              <span class="ip-key"><i class="bi bi-credit-card-2-front"></i> Aadhaar No.</span>
              <span class="ip-val">
                <%= kycReg.getAadhaarNumber() != null
                    ? "XXXX XXXX " + kycReg.getAadhaarNumber().replaceAll("\\s","")
                        .substring(Math.max(0, kycReg.getAadhaarNumber().replaceAll("\\s","").length()-4))
                    : "—" %>
                &nbsp;<span class="doc-chip <%= kycApproved ? "verified" : kycPending ? "pending" : "missing" %>"><%= kycApproved ? "✓ Verified" : kycPending ? "Under Review" : "Pending" %></span>
              </span>
            </div>
            <div class="ip-row"><span class="ip-key">Name on Aadhaar</span><span class="ip-val"><%= kycReg.getAadhaarName() != null ? kycReg.getAadhaarName() : "—" %></span></div>
            <div class="ip-row">
              <span class="ip-key"><i class="bi bi-file-person"></i> PAN No.</span>
              <span class="ip-val">
                <%= kycReg.getPanNumber() != null ? kycReg.getPanNumber().substring(0, Math.min(3, kycReg.getPanNumber().length())) + "XXXXXXX" : "—" %>
                &nbsp;<span class="doc-chip <%= kycApproved ? "verified" : kycPending ? "pending" : "missing" %>"><%= kycApproved ? "✓ Verified" : kycPending ? "Under Review" : "Pending" %></span>
              </span>
            </div>
          </div>
          <div class="info-panel" style="margin-top:14px;">
            <div class="ip-head">Driving Licence</div>
            <div class="ip-row"><span class="ip-key"><i class="bi bi-card-text"></i> DL Number</span><span class="ip-val"><%= kycReg.getDlNumber() != null ? kycReg.getDlNumber() : "—" %></span></div>
            <div class="ip-row"><span class="ip-key">Issue Date</span><span class="ip-val"><%= kycReg.getDlIssueDate() != null ? kycReg.getDlIssueDate() : "—" %></span></div>
            <div class="ip-row"><span class="ip-key">Expiry Date</span><span class="ip-val"><%= kycReg.getDlExpiryDate() != null ? kycReg.getDlExpiryDate() : "—" %></span></div>
            <div class="ip-row"><span class="ip-key"><i class="bi bi-file-earmark-image"></i> DL Docs</span>
              <span class="ip-val">
                <span class="doc-chip <%= kycReg.getDlFrontPath() != null ? (kycApproved ? "verified" : "pending") : "missing" %>">
                  <%= kycReg.getDlFrontPath() != null ? (kycApproved ? "✓ Uploaded" : "Uploaded") : "Not uploaded" %>
                </span>
              </span>
            </div>
          </div>
          <div class="info-panel" style="margin-top:14px;">
            <div class="ip-head">Address Proof</div>
            <div class="ip-row"><span class="ip-key"><i class="bi bi-file-earmark-text"></i> Proof Type</span><span class="ip-val"><%= kycReg.getAddressProofType() != null ? kycReg.getAddressProofType() : "—" %></span></div>
            <div class="ip-row"><span class="ip-key">Document</span>
              <span class="ip-val">
                <span class="doc-chip <%= kycReg.getAddressProofPath() != null ? (kycApproved ? "verified" : "pending") : "missing" %>">
                  <%= kycReg.getAddressProofPath() != null ? (kycApproved ? "✓ Uploaded" : "Uploaded") : "Not uploaded" %>
                </span>
              </span>
            </div>
          </div>
        </div>

        <%-- Tab: Vehicle ──────────────────────────────────────────────── --%>
        <div class="kyc-tab-panel" id="ktab-vehicle">
          <div class="info-panel">
            <div class="ip-head">Vehicle Details</div>
            <div class="ip-row"><span class="ip-key"><i class="bi bi-truck"></i> Vehicle</span><span class="ip-val"><%= kycVehicle.isEmpty() ? "—" : kycVehicle %></span></div>
            <div class="ip-row"><span class="ip-key">Type</span><span class="ip-val"><%= kycReg.getVehicleType() != null ? kycReg.getVehicleType() : "—" %></span></div>
            <div class="ip-row"><span class="ip-key">Fuel</span><span class="ip-val"><%= kycReg.getFuelType() != null ? kycReg.getFuelType() : "—" %></span></div>
            <div class="ip-row"><span class="ip-key">Ownership</span><span class="ip-val"><%= kycReg.getVehicleOwnership() != null ? kycReg.getVehicleOwnership() : "—" %></span></div>
            <div class="ip-row"><span class="ip-key">Year</span><span class="ip-val"><%= kycReg.getVehicleYear() != null ? kycReg.getVehicleYear() : "—" %></span></div>
            <div class="ip-row"><span class="ip-key">Colour</span><span class="ip-val"><%= kycReg.getVehicleColour() != null ? kycReg.getVehicleColour() : "—" %></span></div>
            <div class="ip-row"><span class="ip-key">Payload (kg)</span><span class="ip-val"><%= kycReg.getPayloadKg() != null ? kycReg.getPayloadKg() + " kg" : "—" %></span></div>
          </div>
          <div class="info-panel" style="margin-top:14px;">
            <div class="ip-head">Insurance &amp; PUC</div>
            <div class="ip-row"><span class="ip-key"><i class="bi bi-shield-check"></i> Insurance No.</span><span class="ip-val"><%= kycReg.getInsuranceNumber() != null ? kycReg.getInsuranceNumber() : "—" %></span></div>
            <div class="ip-row"><span class="ip-key">Insurance Expiry</span>
              <span class="ip-val">
                <%= kycReg.getInsuranceExpiry() != null ? kycReg.getInsuranceExpiry() : "—" %>
                <% if (kycReg.getInsuranceExpiry() != null) { %>
                  <span class="doc-chip pending">Check Expiry</span>
                <% } %>
              </span>
            </div>
            <div class="ip-row"><span class="ip-key"><i class="bi bi-file-earmark-check"></i> PUC Number</span><span class="ip-val"><%= kycReg.getPucNumber() != null ? kycReg.getPucNumber() : "—" %></span></div>
            <div class="ip-row"><span class="ip-key">PUC Expiry</span><span class="ip-val"><%= kycReg.getPucExpiry() != null ? kycReg.getPucExpiry() : "—" %></span></div>
          </div>
        </div>

        <%-- Tab: Bank ─────────────────────────────────────────────────── --%>
        <div class="kyc-tab-panel" id="ktab-bank">
          <div class="info-panel">
            <div class="ip-head">Bank Account</div>
            <div class="ip-row"><span class="ip-key"><i class="bi bi-bank"></i> Bank Name</span><span class="ip-val"><%= kycReg.getBankName() != null ? kycReg.getBankName() : "—" %></span></div>
            <div class="ip-row"><span class="ip-key">Account Holder</span><span class="ip-val"><%= kycReg.getBankAccName() != null ? kycReg.getBankAccName() : "—" %></span></div>
            <div class="ip-row"><span class="ip-key">Account No.</span>
              <span class="ip-val" style="font-family:monospace;">
                <% if (kycReg.getBankAccNumber() != null && kycReg.getBankAccNumber().length() > 4) { %>
                  XXXXXXXXXX<%= kycReg.getBankAccNumber().substring(kycReg.getBankAccNumber().length()-4) %>
                <% } else { %>—<% } %>
              </span>
            </div>
            <div class="ip-row"><span class="ip-key">IFSC Code</span><span class="ip-val" style="font-family:monospace;text-transform:uppercase;"><%= kycReg.getIfscCode() != null ? kycReg.getIfscCode() : "—" %></span></div>
            <div class="ip-row"><span class="ip-key">Branch</span><span class="ip-val"><%= kycReg.getBranchName() != null ? kycReg.getBranchName() : "—" %></span></div>
            <div class="ip-row"><span class="ip-key">Account Type</span><span class="ip-val"><%= kycReg.getAccountType() != null ? kycReg.getAccountType() : "—" %></span></div>
            <div class="ip-row"><span class="ip-key"><i class="bi bi-phone"></i> UPI ID</span><span class="ip-val"><%= kycReg.getUpiId() != null && !kycReg.getUpiId().isBlank() ? kycReg.getUpiId() : "—" %></span></div>
          </div>
          <div class="info-panel" style="margin-top:14px;">
            <div class="ip-head">Wallet &amp; Earnings</div>
            <div class="ip-row"><span class="ip-key"><i class="bi bi-wallet2"></i> Current Balance</span><span class="ip-val" id="profileWalletBal" style="color:var(--green);font-weight:700;">Loading…</span></div>
            <div class="ip-row"><span class="ip-key">Today's Earnings</span><span class="ip-val" style="color:var(--green);">₹<%= dbEarnToday.toPlainString() %></span></div>
            <div class="ip-row"><span class="ip-key">This Week</span><span class="ip-val">₹<%= dbEarnWeek.toPlainString() %></span></div>
            <div class="ip-row"><span class="ip-key">This Month</span><span class="ip-val">₹<%= dbEarnMonth.toPlainString() %></span></div>
          </div>
        </div>

        <%-- Tab: Performance ──────────────────────────────────────────── --%>
        <div class="kyc-tab-panel" id="ktab-performance">
          <div class="info-panel">
            <div class="ip-head">Delivery Performance</div>
            <div class="ip-row"><span class="ip-key">Customer Rating</span><span class="ip-val">★★★★½ <%= dbRating %>/5</span></div>
            <div class="ip-row"><span class="ip-key">Total Deliveries</span><span class="ip-val"><%= dbDeliveries %></span></div>
            <div class="ip-row"><span class="ip-key">On-time Rate</span><span class="ip-val" style="color:var(--green);">98%</span></div>
            <div class="ip-row"><span class="ip-key">Cancellation Rate</span><span class="ip-val" style="color:var(--amber);">1.2%</span></div>
            <div class="ip-row"><span class="ip-key">Active Orders</span><span class="ip-val"><%= cntActive %></span></div>
            <div class="ip-row"><span class="ip-key">Orders This Session</span><span class="ip-val"><%= orders.size() %></span></div>
            <div class="ip-row"><span class="ip-key">Delivered</span><span class="ip-val" style="color:var(--green);"><%= cntDelivered %></span></div>
          </div>
        </div>

      </div><%-- end right column --%>
    </div><%-- end .profile-grid --%>


    <%-- ══════════════════════════════════════════════════════════════════
         KYC REJECTED — Redirect to register page (cleaner than inline form)
         Shows the rejection reason prominently, then a single CTA button
         that opens deliveryRegister.jsp with the agent's data pre-filled.
    ═══════════════════════════════════════════════════════════════════════ --%>
    <% if (kycRejected) { %>
    <div style="margin-top:24px;">
      <div class="kyc-cta-card">
        <div class="kyc-cta-header">
          <div class="kyc-cta-icon-wrap red">
            <i class="bi bi-arrow-repeat"></i>
          </div>
          <div class="kyc-cta-body">
            <h3>Re-submit Your KYC Application</h3>
            <p>Your previous application was rejected. Click the button below to open the registration form — your saved details will be pre-filled so you only need to fix what was flagged and re-upload the relevant documents.</p>
          </div>
        </div>

        <%-- Show admin rejection reason if present --%>
        <% if (kycReg.getAdminRemarks() != null && !kycReg.getAdminRemarks().isBlank()) { %>
        <div class="rejection-reason-box">
          <strong><i class="bi bi-exclamation-triangle-fill me-1"></i>Rejection Reason from Admin</strong>
          <%= kycReg.getAdminRemarks() %>
        </div>
        <% } %>

        <div class="kyc-cta-steps">
          <div class="kyc-cta-step">
            <div class="kyc-cta-step-num">1</div>
            <div class="kyc-cta-step-text">
              <strong>Review Reason</strong>
              <span>Read the admin's rejection note above carefully</span>
            </div>
          </div>
          <div class="kyc-cta-step">
            <div class="kyc-cta-step-num">2</div>
            <div class="kyc-cta-step-text">
              <strong>Open Form</strong>
              <span>Click below — your old details are pre-filled</span>
            </div>
          </div>
          <div class="kyc-cta-step">
            <div class="kyc-cta-step-num">3</div>
            <div class="kyc-cta-step-text">
              <strong>Fix &amp; Re-upload</strong>
              <span>Correct the flagged fields and upload fresh documents</span>
            </div>
          </div>
          <div class="kyc-cta-step">
            <div class="kyc-cta-step-num">4</div>
            <div class="kyc-cta-step-text">
              <strong>Submit</strong>
              <span>Admin re-reviews within 1–2 business days</span>
            </div>
          </div>
        </div>

        <div class="kyc-cta-footer">
          <div class="kyc-cta-footer-note">
            <i class="bi bi-shield-lock"></i>
            Your existing data is saved. Only the rejected sections need updating.
          </div>
          <a href="<%= registerUrl %>&mode=resubmit" class="btn-goto-register red">
            <i class="bi bi-pencil-square"></i>
            Re-submit KYC Application
            <i class="bi bi-arrow-right"></i>
          </a>
        </div>
      </div>
    </div>
    <% } %>

    <% } %><%-- end hasKyc --%>


    <%-- ══════════════════════════════════════════════════════════════════
         CASE 2: No KYC record at all — redirect CTA to register page
         No inline form. Agent completes registration in deliveryRegister.jsp
         (the same page new agents use — single source of truth).
    ═══════════════════════════════════════════════════════════════════════ --%>
    <% if (!hasKyc) { %>
    <div class="kyc-cta-card" style="margin-top:8px;">
      <div class="kyc-cta-header">
        <div class="kyc-cta-icon-wrap blue">
          <i class="bi bi-person-vcard-fill"></i>
        </div>
        <div class="kyc-cta-body">
          <h3>Complete Your KYC Registration</h3>
          <p>
            You haven't submitted your KYC details yet. Fill in the registration form to get verified
            by the admin — it takes about 5–10 minutes and approval usually comes within 1–2 business days.
            Until then you won't be able to go online or accept orders.
          </p>
        </div>
      </div>

      <div class="kyc-cta-steps">
        <div class="kyc-cta-step">
          <div class="kyc-cta-step-num">1</div>
          <div class="kyc-cta-step-text">
            <strong>Personal Info</strong>
            <span>Name, DOB, contact &amp; address</span>
          </div>
        </div>
        <div class="kyc-cta-step">
          <div class="kyc-cta-step-num">2</div>
          <div class="kyc-cta-step-text">
            <strong>KYC Documents</strong>
            <span>Aadhaar, PAN, Driving Licence</span>
          </div>
        </div>
        <div class="kyc-cta-step">
          <div class="kyc-cta-step-num">3</div>
          <div class="kyc-cta-step-text">
            <strong>Vehicle Details</strong>
            <span>Registration, insurance &amp; PUC</span>
          </div>
        </div>
        <div class="kyc-cta-step">
          <div class="kyc-cta-step-num">4</div>
          <div class="kyc-cta-step-text">
            <strong>Bank Details</strong>
            <span>Account &amp; UPI for earnings</span>
          </div>
        </div>
      </div>

      <div class="kyc-cta-footer">
        <div class="kyc-cta-footer-note">
          <i class="bi bi-clock"></i>
          Estimated time: 5–10 minutes &nbsp;|&nbsp;
          <i class="bi bi-patch-check"></i>
          Admin approval: 1–2 business days
        </div>
        <a href="<%= registerUrl %>&mode=new" class="btn-goto-register">
          <i class="bi bi-person-vcard-fill"></i>
          Start KYC Registration
          <i class="bi bi-arrow-right"></i>
        </a>
      </div>
    </div>
    <% } %>

  </div><%-- end #page-profile --%>




</main>

<!-- ══ MOBILE BOTTOM NAV ══ -->
<nav class="bottom-nav">
  <div class="bottom-nav-inner">
    <button class="bnav-item active" onclick="showPage('dashboard')" id="bnav-dashboard" title="Dashboard" aria-label="Dashboard"><i class="bi bi-grid-1x2"></i><span>Home</span></button>
    <button class="bnav-item" onclick="showPage('orders')" id="bnav-orders" style="position:relative;" title="Active Orders" aria-label="Active Orders">
      <i class="bi bi-box-seam"></i><span>Orders</span>
      <% if (cntActive > 0) { %><div class="badge-dot"></div><% } %>
    </button>
    <button class="bnav-item" onclick="showPage('history')" id="bnav-history" title="Order History" aria-label="Order History"><i class="bi bi-clock-history"></i><span>History</span></button>
    <button class="bnav-item" onclick="showPage('wallet')" id="bnav-wallet" title="My Wallet" aria-label="My Wallet"><i class="bi bi-credit-card-2-front"></i><span>Wallet</span></button>
    <button class="bnav-item" onclick="showPage('earnings')" id="bnav-earnings" title="My Earnings" aria-label="My Earnings"><i class="bi bi-wallet2"></i><span>Earn</span></button>
    <button class="bnav-item" onclick="showPage('profile')" id="bnav-profile" title="My Profile" aria-label="My Profile"><i class="bi bi-person-circle"></i><span>Profile</span></button>
  </div>
</nav>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script src="<%=request.getContextPath()%>/js/delivery-portal.js"></script>
   <script>
  function switchKycTab(btn, panelId) {
    document.querySelectorAll('#page-profile .kyc-tab').forEach(t => t.classList.remove('active'));
    document.querySelectorAll('#page-profile .kyc-tab-panel').forEach(p => p.classList.remove('active'));
    btn.classList.add('active');
    var panel = document.getElementById(panelId);
    if (panel) panel.classList.add('active');
  }
  </script>

</body>
</html>
