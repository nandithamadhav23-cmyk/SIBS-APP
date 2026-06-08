<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Join as Delivery Agent — Smart Inventory</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
  <link href="https://fonts.googleapis.com/css2?family=DM+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700&family=Fraunces:ital,wght@0,300;0,600;1,400;1,600&display=swap" rel="stylesheet">

  <style>
    :root {
      --ocean:       #0ea5e9;
      --ocean-dark:  #0369a1;
      --ocean-deep:  #082f49;
      --ocean-mid:   #0c4a6e;
      --ocean-glow:  rgba(14,165,233,0.18);
      --amber:       #f59e0b;
      --amber-dark:  #d97706;
      --emerald:     #10b981;
      --ink:         #0c1117;
      --ink-muted:   #475569;
      --ink-soft:    #94a3b8;
      --border:      rgba(255,255,255,0.12);
      --border-light: #e2e8f0;
      --glass:       rgba(255,255,255,0.06);
      --glass-solid: rgba(255,255,255,0.97);
      --red:         #ef4444;
      --radius:      20px;
      --radius-sm:   12px;
      --radius-xs:   8px;
    }

    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

    html { scroll-behavior: smooth; }

    body {
      font-family: 'DM Sans', sans-serif;
      min-height: 100vh;
      background: var(--ocean-deep);
      overflow-x: hidden;
    }

    /* ═══════════════════════ BACKGROUND ═══════════════════════ */
    .scene {
      position: fixed; inset: 0; z-index: 0; overflow: hidden;
      background: linear-gradient(160deg, #040d14 0%, #082f49 35%, #0c4a6e 65%, #0a3a59 100%);
    }

    /* Road animation */
    .road {
      position: absolute; bottom: 0; left: 0; right: 0; height: 160px;
      background: linear-gradient(180deg, transparent 0%, rgba(8,47,73,0.6) 20%, #020e1a 100%);
    }
    .road-line {
      position: absolute; bottom: 60px; height: 4px; border-radius: 2px;
      background: rgba(245,158,11,0.7);
      animation: roadMove 3s linear infinite;
    }
    .road-line:nth-child(1) { width: 80px; left: 10%; animation-delay: 0s; }
    .road-line:nth-child(2) { width: 80px; left: 35%; animation-delay: 1s; }
    .road-line:nth-child(3) { width: 80px; left: 60%; animation-delay: 2s; }
    .road-line:nth-child(4) { width: 80px; left: 80%; animation-delay: 0.5s; }

    @keyframes roadMove {
      0%   { transform: translateX(0); opacity: 1; }
      100% { transform: translateX(-200px); opacity: 0; }
    }

    /* Truck silhouette */
    .truck-silhouette {
      position: absolute; bottom: 60px; right: -200px;
      font-size: 5rem; color: rgba(14,165,233,0.12);
      animation: truckDrive 18s linear infinite;
      filter: drop-shadow(0 0 20px rgba(14,165,233,0.2));
    }
    @keyframes truckDrive {
      0%   { right: -200px; }
      100% { right: 110%; }
    }

    /* Stars/particles */
    .stars { position: absolute; inset: 0; }
    .star {
      position: absolute; border-radius: 50%;
      background: rgba(255,255,255,0.7);
      animation: twinkle var(--dur) ease-in-out infinite var(--delay);
    }
    @keyframes twinkle {
      0%,100% { opacity: 0.1; transform: scale(1); }
      50%      { opacity: 0.8; transform: scale(1.3); }
    }

    /* Mesh glows */
    .glow {
      position: absolute; border-radius: 50%; pointer-events: none;
      filter: blur(80px); animation: drift var(--dur2, 12s) ease-in-out infinite alternate;
    }
    .glow-1 { width: 600px; height: 600px; top: -200px; right: -150px; background: radial-gradient(circle, rgba(14,165,233,0.12) 0%, transparent 70%); }
    .glow-2 { width: 400px; height: 400px; bottom: 100px; left: -100px; background: radial-gradient(circle, rgba(245,158,11,0.08) 0%, transparent 70%); --dur2:8s; }
    .glow-3 { width: 300px; height: 300px; top: 40%; left: 40%; background: radial-gradient(circle, rgba(16,185,129,0.06) 0%, transparent 70%); --dur2:15s; }

    @keyframes drift {
      0%   { transform: translate(0,0) scale(1); }
      100% { transform: translate(30px,-30px) scale(1.05); }
    }

    /* Grid */
    .grid-overlay {
      position: absolute; inset: 0;
      background-image: linear-gradient(rgba(14,165,233,0.03) 1px, transparent 1px),
                        linear-gradient(90deg, rgba(14,165,233,0.03) 1px, transparent 1px);
      background-size: 60px 60px;
    }

    /* ═══════════════════════ LAYOUT ═══════════════════════ */
    .page-wrap {
      position: relative; z-index: 1;
      min-height: 100vh;
      display: flex; flex-direction: column; align-items: center;
      padding: 2rem 1rem 4rem;
    }

    /* Brand bar */
    .brand-bar {
      width: 100%; max-width: 860px;
      display: flex; align-items: center; justify-content: space-between;
      margin-bottom: 2.5rem;
      animation: fadeDown 0.6s ease both;
    }
    .brand-logo {
      display: flex; align-items: center; gap: 0.6rem;
      font-family: 'Fraunces', serif; font-size: 1.2rem; font-weight: 600; color: #fff;
    }
    .brand-logo-icon {
      width: 38px; height: 38px; border-radius: 10px;
      background: linear-gradient(135deg, var(--ocean) 0%, var(--ocean-dark) 100%);
      display: flex; align-items: center; justify-content: center;
      font-size: 1.1rem; color: #fff;
    }
    .brand-login-link {
      font-size: 0.83rem; color: rgba(255,255,255,0.55);
      text-decoration: none; display: flex; align-items: center; gap: 0.35rem;
      transition: color 0.2s;
    }
    .brand-login-link:hover { color: var(--ocean); }

    @keyframes fadeDown {
      from { opacity: 0; transform: translateY(-16px); }
      to   { opacity: 1; transform: translateY(0); }
    }

    /* ═══════════════════════ STEPPER ═══════════════════════ */
    .stepper-wrap {
      width: 100%; max-width: 860px;
      margin-bottom: 2rem;
      animation: fadeUp 0.6s 0.1s ease both;
    }
    .stepper {
      display: flex; align-items: center; justify-content: center;
      gap: 0; position: relative;
    }
    .step-item {
      display: flex; flex-direction: column; align-items: center;
      flex: 1; position: relative; cursor: default;
    }
    .step-item:not(:last-child)::after {
      content: '';
      position: absolute; top: 18px; left: 50%; width: 100%; height: 2px;
      background: rgba(255,255,255,0.12);
      transition: background 0.4s;
      z-index: 0;
    }
    .step-item.done:not(:last-child)::after { background: var(--ocean); }

    .step-circle {
      width: 36px; height: 36px; border-radius: 50%;
      border: 2px solid rgba(255,255,255,0.2);
      background: rgba(255,255,255,0.05);
      display: flex; align-items: center; justify-content: center;
      font-size: 0.8rem; font-weight: 700; color: rgba(255,255,255,0.35);
      position: relative; z-index: 1;
      transition: all 0.35s;
    }
    .step-item.active .step-circle {
      border-color: var(--ocean);
      background: var(--ocean);
      color: #fff;
      box-shadow: 0 0 0 4px rgba(14,165,233,0.2);
    }
    .step-item.done .step-circle {
      border-color: var(--emerald);
      background: var(--emerald);
      color: #fff;
    }
    .step-label {
      font-size: 0.7rem; font-weight: 600; margin-top: 0.4rem;
      color: rgba(255,255,255,0.3); letter-spacing: 0.4px;
      text-align: center; white-space: nowrap;
      transition: color 0.3s;
    }
    .step-item.active .step-label { color: var(--ocean); }
    .step-item.done .step-label { color: var(--emerald); }

    @keyframes fadeUp {
      from { opacity: 0; transform: translateY(20px); }
      to   { opacity: 1; transform: translateY(0); }
    }

    /* ═══════════════════════ CARD ═══════════════════════ */
    .reg-card {
      width: 100%; max-width: 860px;
      background: var(--glass-solid);
      border-radius: 24px;
      box-shadow: 0 32px 80px rgba(4,13,20,0.6), 0 0 0 1px rgba(255,255,255,0.08);
      overflow: hidden;
      animation: fadeUp 0.7s 0.2s ease both;
    }

    .card-top-bar {
      background: linear-gradient(135deg, var(--ocean-deep) 0%, var(--ocean-mid) 100%);
      padding: 1.8rem 2.5rem;
      display: flex; align-items: center; gap: 1.2rem;
      position: relative; overflow: hidden;
    }
    .card-top-bar::before {
      content: '';
      position: absolute; top: -40px; right: -40px;
      width: 180px; height: 180px; border-radius: 50%;
      background: rgba(14,165,233,0.1);
    }
    .card-top-icon {
      width: 56px; height: 56px; border-radius: 14px;
      background: rgba(14,165,233,0.15);
      border: 1px solid rgba(14,165,233,0.3);
      display: flex; align-items: center; justify-content: center;
      font-size: 1.5rem; color: var(--ocean);
      flex-shrink: 0; position: relative; z-index: 1;
    }
    .card-top-text { position: relative; z-index: 1; }
    .card-top-title {
      font-family: 'Fraunces', serif; font-size: 1.35rem; font-weight: 600;
      color: #fff; line-height: 1.2;
    }
    .card-top-sub { font-size: 0.83rem; color: rgba(255,255,255,0.5); margin-top: 0.15rem; }

    /* Steps badge */
    .step-badge {
      margin-left: auto; position: relative; z-index: 1;
      background: rgba(14,165,233,0.15); border: 1px solid rgba(14,165,233,0.3);
      border-radius: 20px; padding: 0.3rem 0.75rem;
      font-size: 0.75rem; font-weight: 700; color: var(--ocean); letter-spacing: 0.5px;
    }

    /* ═══════════════════════ FORM BODY ═══════════════════════ */
    .form-body { padding: 2.2rem 2.5rem; }

    /* Alert */
    .alert-msg {
      border-radius: var(--radius-sm); padding: 0.8rem 1rem;
      font-size: 0.86rem; display: flex; align-items: flex-start; gap: 0.5rem;
      margin-bottom: 1.6rem; font-weight: 500; line-height: 1.4;
    }
    .alert-msg.err { background: #fff1f1; border: 1px solid #fca5a5; color: #dc2626; border-left: 3px solid #dc2626; }
    .alert-msg.ok  { background: #f0fdf4; border: 1px solid #86efac; color: #16a34a; border-left: 3px solid #16a34a; }

    /* Section heading */
    .section-head {
      display: flex; align-items: center; gap: 0.6rem;
      margin-bottom: 1.4rem; padding-bottom: 0.75rem;
      border-bottom: 2px solid var(--border-light);
    }
    .section-head-icon {
      width: 32px; height: 32px; border-radius: 8px;
      display: flex; align-items: center; justify-content: center;
      font-size: 0.95rem;
    }
    .section-head-icon.blue  { background: rgba(14,165,233,0.12); color: var(--ocean); }
    .section-head-icon.amber { background: rgba(245,158,11,0.12); color: var(--amber); }
    .section-head-icon.green { background: rgba(16,185,129,0.12); color: var(--emerald); }
    .section-head-icon.purple{ background: rgba(139,92,246,0.12); color: #8b5cf6; }

    .section-head-text h3 { font-size: 0.95rem; font-weight: 700; color: var(--ink); }
    .section-head-text p  { font-size: 0.78rem; color: var(--ink-soft); margin-top: 0.1rem; }

    /* Fields */
    .field-row { display: grid; gap: 1rem; margin-bottom: 1rem; }
    .field-row.cols-2 { grid-template-columns: 1fr 1fr; }
    .field-row.cols-3 { grid-template-columns: 1fr 1fr 1fr; }
    .field-row.cols-1 { grid-template-columns: 1fr; }

    .field-group { display: flex; flex-direction: column; }
    .field-label {
      font-size: 0.72rem; font-weight: 700; color: var(--ink);
      margin-bottom: 0.4rem; letter-spacing: 0.3px;
      display: flex; align-items: center; gap: 0.3rem;
    }
    .field-label .req { color: var(--red); }

    .field-wrap { position: relative; }
    .field-icon {
      position: absolute; left: 0.85rem; top: 50%;
      transform: translateY(-50%);
      color: var(--ink-soft); font-size: 0.95rem; pointer-events: none;
      z-index: 1;
    }
    .field-icon-r {
      position: absolute; right: 0.85rem; top: 50%;
      transform: translateY(-50%);
      background: none; border: none; cursor: pointer;
      color: var(--ink-soft); font-size: 0.95rem;
      transition: color 0.2s; padding: 0;
    }
    .field-icon-r:hover { color: var(--ink); }

    .form-control, .form-select {
      width: 100%;
      border: 1.5px solid var(--border-light);
      border-radius: var(--radius-xs);
      padding: 0.7rem 1rem 0.7rem 2.55rem;
      font-family: 'DM Sans', sans-serif; font-size: 0.88rem;
      color: var(--ink); background: #f8fafc;
      transition: border-color 0.2s, box-shadow 0.2s, background 0.2s;
      outline: none; line-height: 1.4;
    }
    .form-control:focus, .form-select:focus {
      border-color: var(--ocean);
      box-shadow: 0 0 0 3px rgba(14,165,233,0.1);
      background: #fff;
    }
    .form-control.no-icon { padding-left: 1rem; }
    .form-control.has-r   { padding-right: 2.6rem; }
    .form-control::placeholder { color: #b0bec5; }

    /* Upload zone */
    .upload-zone {
      border: 2px dashed var(--border-light);
      border-radius: var(--radius-xs);
      padding: 1.4rem 1rem;
      text-align: center; cursor: pointer;
      transition: all 0.25s; background: #f8fafc;
      position: relative; overflow: hidden;
    }
    .upload-zone:hover, .upload-zone.dragover {
      border-color: var(--ocean);
      background: rgba(14,165,233,0.04);
    }
    .upload-zone input[type=file] {
      position: absolute; inset: 0; opacity: 0; cursor: pointer; width: 100%; height: 100%;
    }
    .upload-icon { font-size: 1.6rem; color: var(--ocean-dark); margin-bottom: 0.4rem; }
    .upload-label { font-size: 0.82rem; font-weight: 600; color: var(--ink); display: block; }
    .upload-hint  { font-size: 0.72rem; color: var(--ink-soft); margin-top: 0.15rem; }
    .upload-preview {
      margin-top: 0.5rem; font-size: 0.78rem; color: var(--emerald);
      font-weight: 600; display: none; align-items: center; gap: 0.35rem; justify-content: center;
    }

    /* Photo preview */
    .photo-preview-ring {
      width: 90px; height: 90px; border-radius: 50%;
      border: 3px dashed var(--border-light);
      display: flex; align-items: center; justify-content: center;
      margin: 0 auto 0.6rem; overflow: hidden;
      background: #f1f5f9;
      transition: border-color 0.2s;
    }
    .photo-preview-ring img { width: 100%; height: 100%; object-fit: cover; display: none; }
    .photo-preview-ring i { font-size: 2rem; color: var(--ink-soft); }

    /* Divider */
    .section-divider { height: 1px; background: var(--border-light); margin: 1.8rem 0; }

    /* Checkbox */
    .check-group {
      display: flex; align-items: flex-start; gap: 0.65rem;
      margin-top: 0.4rem;
    }
    .check-group input[type=checkbox] { accent-color: var(--ocean); width: 16px; height: 16px; flex-shrink: 0; margin-top: 2px; }
    .check-group label { font-size: 0.82rem; color: var(--ink-muted); line-height: 1.4; }
    .check-group label a { color: var(--ocean); text-decoration: none; font-weight: 600; }
    .check-group label a:hover { text-decoration: underline; }

    /* Info chips */
    .info-chips { display: flex; flex-wrap: wrap; gap: 0.5rem; margin-bottom: 1.4rem; }
    .info-chip {
      display: flex; align-items: center; gap: 0.35rem;
      font-size: 0.73rem; font-weight: 600; padding: 0.3rem 0.7rem;
      border-radius: 20px; letter-spacing: 0.2px;
    }
    .info-chip.blue   { background: rgba(14,165,233,0.1);  color: var(--ocean-dark); }
    .info-chip.amber  { background: rgba(245,158,11,0.1);  color: var(--amber-dark); }
    .info-chip.green  { background: rgba(16,185,129,0.1);  color: #059669; }

    /* ═══════════════════════ BUTTONS ═══════════════════════ */
    .form-actions {
      display: flex; align-items: center; justify-content: space-between;
      padding: 1.5rem 2.5rem;
      background: #f8fafc;
      border-top: 1px solid var(--border-light);
      gap: 1rem;
    }
    .btn-back {
      display: flex; align-items: center; gap: 0.4rem;
      padding: 0.7rem 1.3rem;
      border: 1.5px solid var(--border-light);
      border-radius: var(--radius-xs);
      background: #fff; color: var(--ink-muted);
      font-family: 'DM Sans', sans-serif; font-size: 0.88rem; font-weight: 600;
      cursor: pointer; transition: all 0.2s;
    }
    .btn-back:hover { border-color: var(--ocean); color: var(--ocean); }

    .btn-next {
      display: flex; align-items: center; gap: 0.45rem;
      padding: 0.75rem 1.8rem;
      border: none; border-radius: var(--radius-xs);
      background: linear-gradient(135deg, var(--ocean) 0%, var(--ocean-dark) 100%);
      color: #fff;
      font-family: 'DM Sans', sans-serif; font-size: 0.9rem; font-weight: 700;
      cursor: pointer; transition: all 0.2s;
      box-shadow: 0 4px 14px rgba(14,165,233,0.35);
      letter-spacing: 0.2px;
    }
    .btn-next:hover { opacity: 0.92; transform: translateY(-1px); box-shadow: 0 6px 20px rgba(14,165,233,0.45); }
    .btn-next:active { transform: translateY(0); }
    .btn-next.amber { background: linear-gradient(135deg, var(--amber) 0%, var(--amber-dark) 100%); box-shadow: 0 4px 14px rgba(245,158,11,0.35); }
    .btn-next.green { background: linear-gradient(135deg, var(--emerald) 0%, #059669 100%); box-shadow: 0 4px 14px rgba(16,185,129,0.35); }

    /* ═══════════════════════ STEP PANELS ═══════════════════════ */
    .step-panel { display: none; }
    .step-panel.active { display: block; }

    /* ═══════════════════════ SUCCESS ═══════════════════════ */
    .success-wrap {
      text-align: center; padding: 3rem 2rem;
    }
    .success-icon-ring {
      width: 90px; height: 90px; border-radius: 50%;
      background: rgba(16,185,129,0.1);
      border: 2px solid rgba(16,185,129,0.3);
      display: flex; align-items: center; justify-content: center;
      margin: 0 auto 1.5rem; font-size: 2.5rem; color: var(--emerald);
      animation: popIn 0.5s cubic-bezier(0.34,1.56,0.64,1) both;
    }
    @keyframes popIn {
      from { transform: scale(0); opacity: 0; }
      to   { transform: scale(1); opacity: 1; }
    }
    .success-title {
      font-family: 'Fraunces', serif; font-size: 1.6rem; font-weight: 600;
      color: var(--ink); margin-bottom: 0.5rem;
    }
    .success-sub { font-size: 0.9rem; color: var(--ink-muted); line-height: 1.6; max-width: 420px; margin: 0 auto; }
    .success-steps {
      display: flex; gap: 0.6rem; flex-wrap: wrap; justify-content: center;
      margin: 1.8rem 0;
    }
    .success-step {
      display: flex; align-items: center; gap: 0.4rem;
      background: #f1f5f9; border-radius: 20px;
      padding: 0.4rem 0.9rem; font-size: 0.8rem; font-weight: 600; color: var(--ink-muted);
    }
    .success-step i { color: var(--emerald); }

    /* ═══════════════════════ STRENGTH METER ═══════════════════════ */
    .strength-bar-wrap { margin-top: 0.4rem; }
    .strength-bar { height: 4px; border-radius: 2px; background: var(--border-light); overflow: hidden; }
    .strength-fill { height: 100%; width: 0; border-radius: 2px; transition: all 0.35s; }
    .strength-label { font-size: 0.68rem; font-weight: 600; margin-top: 0.2rem; }

    /* ═══════════════════════ RESPONSIVE ═══════════════════════ */
    @media (max-width: 640px) {
      .form-body { padding: 1.5rem; }
      .form-actions { padding: 1.2rem 1.5rem; }
      .card-top-bar { padding: 1.3rem 1.5rem; }
      .field-row.cols-2, .field-row.cols-3 { grid-template-columns: 1fr; }
      .step-label { font-size: 0.6rem; }
    }
@keyframes shake {
  0%,100%{transform:translateX(0)}
  20%{transform:translateX(-8px)}
  40%{transform:translateX(8px)}
  60%{transform:translateX(-5px)}
  80%{transform:translateX(5px)}
}
    /* Progress animation */
    @keyframes slideIn {
      from { opacity: 0; transform: translateX(30px); }
      to   { opacity: 1; transform: translateX(0); }
    }
    .step-panel.active { animation: slideIn 0.35s ease both; }

    /* Tooltip-style hint */
    .field-hint { font-size: 0.7rem; color: var(--ink-soft); margin-top: 0.3rem; }

    /* Form select icon fix */
    .sel-wrap { position: relative; }
    .sel-wrap .field-icon { z-index: 0; pointer-events: none; }
    .form-select { padding-left: 2.55rem; }
  </style>
</head>
<body>
 <%@ page import="java.sql.Connection" %>
<%@ page import="com.util.DBConnection" %>
<%@ page import="com.DAO.DeliveryRegistrationDAO" %>
<%@ page import="com.util.DeliveryRegistration" %>

<%
    /* ── Read URL parameters set by the portal profile page ──────────────── */
    String prefillUsername = request.getParameter("prefillUsername");
    String regMode         = request.getParameter("mode"); // "new" | "resubmit"

    DeliveryRegistration prefill = null;

    /* ── Fetch existing record only when a username was passed ───────────── */
    if (prefillUsername != null && !prefillUsername.isBlank()) {

        Connection _con = null;
        try {
            _con = DBConnection.getConnection();                     // same as servlet
            DeliveryRegistrationDAO _dao = new DeliveryRegistrationDAO(_con);  // same constructor
            prefill = _dao.getByUsername(prefillUsername);          // method added to DAO
        } catch (Exception _ex) {
            /* Non-fatal: if the DB lookup fails the form just opens blank.
               Log it so it isn't silently swallowed in production. */
            _ex.printStackTrace();
            prefill = null;
        } finally {
            if (_con != null) {
                try { _con.close(); } catch (Exception ignored) {}
            }
        }
    }

    /* ── Convenience booleans ─────────────────────────────────────────────── */
    boolean isResubmit     = "resubmit".equals(regMode) && prefill != null;
    boolean isNewFromPortal = "new".equals(regMode);  // arrived from portal but no record yet

    /* ── Page title tweak (optional — use in <title> / card header) ──────── */
    String pageTitle = isResubmit ? "Re-submit KYC Application" : "Join as Delivery Agent";
%>
<% if (isResubmit) { %>
<div style="background:#fff3cd;border:1px solid #ffc107;border-left:4px solid #f59e0b;
            border-radius:10px;padding:14px 18px;margin-bottom:20px;
            font-size:13px;color:#92400e;display:flex;gap:12px;align-items:flex-start;">
  <i class="bi bi-info-circle-fill" style="font-size:18px;flex-shrink:0;margin-top:1px;"></i>
  <div>
    <strong style="display:block;margin-bottom:3px;">Re-submitting KYC Application</strong>
    Your previously saved details have been pre-filled. Fix the flagged sections,
    re-upload any rejected documents, then submit.
    <strong>Password and file fields must be filled in again.</strong>
  </div>
</div>
<% } %>
<!-- ════ SCENE ════ -->
<div class="scene">
  <div class="glow glow-1"></div>
  <div class="glow glow-2"></div>
  <div class="glow glow-3"></div>
  <div class="grid-overlay"></div>
  <div class="stars" id="stars"></div>
  <div class="road">
    <div class="road-line"></div>
    <div class="road-line"></div>
    <div class="road-line"></div>
    <div class="road-line"></div>
  </div>
  <div class="truck-silhouette"><i class="bi bi-truck-front-fill"></i></div>
</div>

<!-- ════ PAGE ════ -->
<div class="page-wrap">

  <!-- Brand bar -->
  <div class="brand-bar">
    <div class="brand-logo">
      <div class="brand-logo-icon"><i class="bi bi-truck-front-fill"></i></div>
      Smart Inventory
    </div>
    <a href="DeliveryLoginServlet" class="brand-login-link">
      <i class="bi bi-arrow-left-circle"></i> Already registered? Sign in
    </a>
  </div>

  <!-- Stepper -->
  <div class="stepper-wrap">
    <div class="stepper">
      <div class="step-item active" id="si-1">
        <div class="step-circle">1</div>
        <div class="step-label">Personal</div>
      </div>
      <div class="step-item" id="si-2">
        <div class="step-circle">2</div>
        <div class="step-label">KYC Docs</div>
      </div>
      <div class="step-item" id="si-3">
        <div class="step-circle">3</div>
        <div class="step-label">Vehicle</div>
      </div>
      <div class="step-item" id="si-4">
        <div class="step-circle">4</div>
        <div class="step-label">Bank</div>
      </div>
      <div class="step-item" id="si-5">
        <div class="step-circle"><i class="bi bi-check2" style="font-size:0.9rem;"></i></div>
        <div class="step-label">Review</div>
      </div>
    </div>
  </div>

  <!-- Card -->
  <div class="reg-card">

    <!-- Flash messages -->
    <% if (request.getAttribute("errorMsg") != null) { %>
      <div style="padding:1rem 2.5rem 0;">
        <div class="alert-msg err">
          <i class="bi bi-exclamation-circle-fill" style="flex-shrink:0;margin-top:1px;"></i>
          <span>${errorMsg}</span>
        </div>
      </div>
    <% } %>
    <% if (request.getAttribute("successMsg") != null) { %>
      <div style="padding:1rem 2.5rem 0;">
        <div class="alert-msg ok">
          <i class="bi bi-check-circle-fill" style="flex-shrink:0;margin-top:1px;"></i>
          <span>${successMsg}</span>
        </div>
      </div>
    <% } %>

    <form id="registrationForm" action="DeliveryRegisterServlet" method="post" novalidate>

    <!-- ══ TOP BAR (dynamic) ══ -->
    <div class="card-top-bar" id="topBar">
      <div class="card-top-icon"><i class="bi bi-person-vcard-fill" id="topIcon"></i></div>
      <div class="card-top-text">
        <div class="card-top-title" id="topTitle">Personal Information</div>
        <div class="card-top-sub" id="topSub">Tell us about yourself — name, contact & address details</div>
      </div>
      <div class="step-badge" id="topBadge">STEP 1 OF 4</div>
    </div>

    <!-- ══════════════════════════════════════════════
         STEP 1 — PERSONAL INFO
    ══════════════════════════════════════════════ -->
    <div class="step-panel active" id="step1">
      <div class="form-body">

        <div class="info-chips">
          <div class="info-chip blue"><i class="bi bi-shield-lock-fill"></i> Data encrypted at rest</div>
          <div class="info-chip amber"><i class="bi bi-clock-fill"></i> Approval in 24–48 hrs</div>
          <div class="info-chip green"><i class="bi bi-patch-check-fill"></i> KYC verified by admin</div>
        </div>

        <!-- Photo upload -->
        <div style="margin-bottom:1.4rem;">
          <div class="section-head">
            <div class="section-head-icon blue"><i class="bi bi-camera-fill"></i></div>
            <div class="section-head-text">
              <h3>Profile Photo</h3>
              <p>Clear, recent passport-size photograph</p>
            </div>
          </div>
          <div style="text-align:center;">
            <div class="photo-preview-ring" id="photoRing">
              <img id="photoPreviewImg" src="" alt="">
              <i class="bi bi-person-fill" id="photoIcon"></i>
            </div>
            <div class="upload-zone" style="max-width:320px;margin:0 auto;" onclick="document.getElementById('profilePhoto').click()">
              <input type="file" id="profilePhoto" name="profilePhoto" accept="image/jpeg,image/png,image/webp" onchange="previewPhoto(this)" style="display:none;">
              <div class="upload-icon"><i class="bi bi-camera-fill"></i></div>
              <span class="upload-label">Upload Profile Photo</span>
              <span class="upload-hint">JPG, PNG or WEBP · Max 2 MB</span>
              <div class="upload-preview" id="photoPreviewLabel">
                <i class="bi bi-check-circle-fill"></i> <span id="photoFileName"></span>
              </div>
            </div>
          </div>
        </div>

        <div class="section-divider"></div>

        <!-- Basic details -->
        <div class="section-head">
          <div class="section-head-icon blue"><i class="bi bi-person-fill"></i></div>
          <div class="section-head-text">
            <h3>Basic Details</h3>
            <p>Legal name as it appears on your government ID</p>
          </div>
        </div>

        <div class="field-row cols-3">
          <div class="field-group">
            <label class="field-label">First Name <span class="req">*</span></label>
            <div class="field-wrap">
              <span class="field-icon"><i class="bi bi-person"></i></span>
              <input type="text" name="firstName" class="form-control" value="<%= prefill != null && prefill.getFirstName()  != null ? prefill.getFirstName()  : "" %>"placeholder="Rajesh" required>
            </div>
          </div>
          <div class="field-group">
            <label class="field-label">Middle Name</label>
            <div class="field-wrap">
              <span class="field-icon"><i class="bi bi-person"></i></span>
              <input type="text" name="middleName" class="form-control"value="<%= prefill != null && prefill.getMiddleName() != null ? prefill.getMiddleName() : "" %>" placeholder="(optional)">
            </div>
          </div>
          <div class="field-group">
            <label class="field-label">Last Name <span class="req">*</span></label>
            <div class="field-wrap">
              <span class="field-icon"><i class="bi bi-person"></i></span>
              <input type="text" name="lastName" class="form-control"  value="<%= prefill != null && prefill.getLastName()   != null ? prefill.getLastName()   : "" %>" placeholder="Kumar" required>
            </div>
          </div>
        </div>

        <div class="field-row cols-3">
          <div class="field-group">
            <label class="field-label">Date of Birth <span class="req">*</span></label>
            <div class="field-wrap">
              <span class="field-icon"><i class="bi bi-calendar3"></i></span>
              <input type="date" name="dob" class="form-control" required max="">
            </div>
          </div>
          <div class="field-group">
            <label class="field-label">Gender <span class="req">*</span></label>
            <div class="sel-wrap">
              <span class="field-icon"><i class="bi bi-gender-ambiguous"></i></span>
              <select name="gender" class="form-select" required>
              <option value="">Select gender</option>
               <option value="Male"              <%= prefill != null && "Male".equals(prefill.getGender())             ? "selected" : "" %>>Male</option>
                <option value="Female"            <%= prefill != null && "Female".equals(prefill.getGender())           ? "selected" : "" %>>Female</option>
               <option value="Other"             <%= prefill != null && "Other".equals(prefill.getGender())            ? "selected" : "" %>>Other</option>
                <option value="Prefer not to say" <%= prefill != null && "Prefer not to say".equals(prefill.getGender()) ? "selected" : "" %>>Prefer not to say</option>
              </select>
            </div>
          </div>
          <div class="field-group">
            <label class="field-label">Blood Group</label>
            <div class="sel-wrap">
              <span class="field-icon"><i class="bi bi-droplet-fill"></i></span>
              <select name="bloodGroup" class="form-select">
               <option value="">Select (optional)</option>
				<option value="A+"  <%= prefill != null && "A+".equals(prefill.getBloodGroup())  ? "selected" : "" %>>A+</option>
				<option value="A−"  <%= prefill != null && "A−".equals(prefill.getBloodGroup())  ? "selected" : "" %>>A−</option>
				<option value="B+"  <%= prefill != null && "B+".equals(prefill.getBloodGroup())  ? "selected" : "" %>>B+</option>
				<option value="B−"  <%= prefill != null && "B−".equals(prefill.getBloodGroup())  ? "selected" : "" %>>B−</option>
				<option value="O+"  <%= prefill != null && "O+".equals(prefill.getBloodGroup())  ? "selected" : "" %>>O+</option>
				<option value="O−"  <%= prefill != null && "O−".equals(prefill.getBloodGroup())  ? "selected" : "" %>>O−</option>
				<option value="AB+" <%= prefill != null && "AB+".equals(prefill.getBloodGroup()) ? "selected" : "" %>>AB+</option>
				<option value="AB−" <%= prefill != null && "AB−".equals(prefill.getBloodGroup()) ? "selected" : "" %>>AB−</option>
              </select>
            </div>
          </div>
        </div>

        <div class="section-divider"></div>

        <!-- Contact -->
        <div class="section-head">
          <div class="section-head-icon blue"><i class="bi bi-telephone-fill"></i></div>
          <div class="section-head-text">
            <h3>Contact Information</h3>
            <p>Used for OTP alerts, order notifications and payouts</p>
          </div>
        </div>

        <div class="field-row cols-2">
          <div class="field-group">
            <label class="field-label">Username <span class="req">*</span></label>
            <div class="field-wrap">
              <span class="field-icon"><i class="bi bi-person-badge"></i></span>
              <input type="text" name="username" class="form-control"
       value="<%= prefill != null && prefill.getUsername() != null ? prefill.getUsername() : "" %>"
       <%= isResubmit ? "readonly" : "" %>placeholder="rajesh_kumar99" required pattern="[a-zA-Z0-9_]{4,30}">
            </div>
            <div class="field-hint">4–30 chars, letters/numbers/underscore only</div>
          </div>
          <div class="field-group">
            <label class="field-label">Mobile Number <span class="req">*</span></label>
            <div class="field-wrap">
              <span class="field-icon"><i class="bi bi-phone-fill"></i></span>
              <input type="tel" name="mobile" class="form-control" placeholder="9876543210" required pattern="[6-9][0-9]{9}" maxlength="10"
               value="<%= prefill != null && prefill.getMobile()   != null ? prefill.getMobile()   : "" %>">
            </div>
          </div>
        </div>

        <div class="field-row cols-2">
          <div class="field-group">
            <label class="field-label">Email Address <span class="req">*</span></label>
            <div class="field-wrap">
              <span class="field-icon"><i class="bi bi-envelope-fill"></i></span>
              <input type="email" name="email" class="form-control" placeholder="rajesh@example.com" required
              value="<%= prefill != null && prefill.getEmail()    != null ? prefill.getEmail()    : "" %>">
            </div>
          </div>
          <div class="field-group">
            <label class="field-label">Alternate / Emergency Contact</label>
            <div class="field-wrap">
              <span class="field-icon"><i class="bi bi-phone"></i></span>
              <input type="tel" name="altMobile" class="form-control" placeholder="9876543211" maxlength="10"
               value="<%= prefill != null && prefill.getAltMobile()!= null ? prefill.getAltMobile(): "" %>" >
            </div>
          </div>
        </div>

        <div class="field-row cols-2">
          <div class="field-group">
            <label class="field-label">Password <span class="req">*</span></label>
            <div class="field-wrap">
              <span class="field-icon"><i class="bi bi-lock-fill"></i></span>
              <input type="password" id="pwdField" name="password" class="form-control has-r" placeholder="Min 8 characters" required minlength="8" oninput="checkStrength(this.value)">
              <button type="button" class="field-icon-r" onclick="togglePwd('pwdField','eyeA')"><i class="bi bi-eye" id="eyeA"></i></button>
            </div>
            <div class="strength-bar-wrap">
              <div class="strength-bar"><div class="strength-fill" id="sfill"></div></div>
              <div class="strength-label" id="slabel"></div>
            </div>
          </div>
          <div class="field-group">
            <label class="field-label">Confirm Password <span class="req">*</span></label>
            <div class="field-wrap">
              <span class="field-icon"><i class="bi bi-lock-fill"></i></span>
              <input type="password" id="cpwdField" name="confirmPassword" class="form-control has-r" placeholder="Re-enter password" required>
              <button type="button" class="field-icon-r" onclick="togglePwd('cpwdField','eyeB')"><i class="bi bi-eye" id="eyeB"></i></button>
            </div>
          </div>
        </div>

        <div class="section-divider"></div>

        <!-- Address -->
        <div class="section-head">
          <div class="section-head-icon blue"><i class="bi bi-geo-alt-fill"></i></div>
          <div class="section-head-text">
            <h3>Current Residential Address</h3>
            <p>Must match your address proof document</p>
          </div>
        </div>

        <div class="field-row cols-1">
          <div class="field-group">
            <label class="field-label">Door No. / Flat / House Name <span class="req">*</span></label>
            <div class="field-wrap">
              <span class="field-icon"><i class="bi bi-house-fill"></i></span>
              <input type="text" name="addressLine1" class="form-control" placeholder="12-3-456, Lakshmi Niwas" required
              value="<%= prefill != null && prefill.getAddressLine1() != null ? prefill.getAddressLine1() : "" %>">
            </div>
          </div>
        </div>
        <div class="field-row cols-2">
          <div class="field-group">
            <label class="field-label">Street / Area / Locality <span class="req">*</span></label>
            <div class="field-wrap">
              <span class="field-icon"><i class="bi bi-signpost-fill"></i></span>
              <input type="text" name="addressLine2" class="form-control" placeholder="Hanamkonda Main Road" required
              value="<%= prefill != null && prefill.getAddressLine2() != null ? prefill.getAddressLine2() : "" %>">
            </div>
          </div>
          <div class="field-group">
            <label class="field-label">Landmark</label>
            <div class="field-wrap">
              <span class="field-icon"><i class="bi bi-pin-map-fill"></i></span>
              <input type="text" name="landmark" class="form-control" placeholder="Near SBI ATM"
               value="<%= prefill != null && prefill.getLandmark()     != null ? prefill.getLandmark()     : "" %>">
            </div>
          </div>
        </div>
        <div class="field-row cols-3">
          <div class="field-group">
            <label class="field-label">City <span class="req">*</span></label>
            <div class="field-wrap">
              <span class="field-icon"><i class="bi bi-building"></i></span>
              <input type="text" name="city" class="form-control" placeholder="Warangal" required
              value="<%= prefill != null && prefill.getCity()         != null ? prefill.getCity()         : "" %>">
            </div>
          </div>
          <div class="field-group">
            <label class="field-label">State <span class="req">*</span></label>
            <div class="sel-wrap">
              <span class="field-icon"><i class="bi bi-map-fill"></i></span>
              <select name="state" class="form-select" required>
                <option value="<%= prefill != null && prefill.getState()        != null ? prefill.getState()        : "" %>">Select state</option>
                <option>Andhra Pradesh</option><option>Arunachal Pradesh</option>
                <option>Assam</option><option>Bihar</option><option>Chhattisgarh</option>
                <option>Goa</option><option>Gujarat</option><option>Haryana</option>
                <option>Himachal Pradesh</option><option>Jharkhand</option>
                <option>Karnataka</option><option>Kerala</option>
                <option>Madhya Pradesh</option><option>Maharashtra</option>
                <option>Manipur</option><option>Meghalaya</option><option>Mizoram</option>
                <option>Nagaland</option><option>Odisha</option><option>Punjab</option>
                <option>Rajasthan</option><option>Sikkim</option><option>Tamil Nadu</option>
                <option selected>Telangana</option><option>Tripura</option>
                <option>Uttar Pradesh</option><option>Uttarakhand</option>
                <option>West Bengal</option>
                <option>Delhi</option><option>Jammu &amp; Kashmir</option>
              </select>
            </div>
          </div>
          <div class="field-group">
            <label class="field-label">Pincode <span class="req">*</span></label>
            <div class="field-wrap">
              <span class="field-icon"><i class="bi bi-mailbox2-flag"></i></span>
              <input type="text" name="pincode" class="form-control" placeholder="506001" required pattern="[1-9][0-9]{5}" maxlength="6"
              value="<%= prefill != null && prefill.getPincode()      != null ? prefill.getPincode()      : "" %>">
            </div>
          </div>
        </div>

      </div><!-- /form-body -->
    </div><!-- /step1 -->


    <!-- ══════════════════════════════════════════════
         STEP 2 — KYC DOCUMENTS
    ══════════════════════════════════════════════ -->
    <div class="step-panel" id="step2">
      <div class="form-body">

        <div class="info-chips">
          <div class="info-chip blue"><i class="bi bi-file-earmark-lock2-fill"></i> Documents stored securely, never deleted</div>
          <div class="info-chip amber"><i class="bi bi-eye-fill"></i> Reviewed only by authorised admin</div>
        </div>

        <!-- Aadhaar -->
        <div class="section-head">
          <div class="section-head-icon amber"><i class="bi bi-credit-card-2-front-fill"></i></div>
          <div class="section-head-text">
            <h3>Aadhaar Card</h3>
            <p>12-digit Aadhaar number &amp; both sides of card image</p>
          </div>
        </div>

        <div class="field-row cols-2">
          <div class="field-group">
            <label class="field-label">Aadhaar Number <span class="req">*</span></label>
            <div class="field-wrap">
              <span class="field-icon"><i class="bi bi-upc-scan"></i></span>
              <input type="text" name="aadhaarNumber" class="form-control" placeholder="XXXX XXXX XXXX" required pattern="[0-9]{12}" maxlength="12"
              value="<%= prefill != null && prefill.getAadhaarNumber() != null ? prefill.getAadhaarNumber() : "" %>">
            </div>
          </div>
          <div class="field-group">
            <label class="field-label">Name on Aadhaar <span class="req">*</span></label>
            <div class="field-wrap">
              <span class="field-icon"><i class="bi bi-person-lines-fill"></i></span>
              <input type="text" name="aadhaarName" class="form-control" placeholder="As printed on Aadhaar" required
              value="<%= prefill != null && prefill.getAadhaarName() != null ? prefill.getAadhaarName() : "" %>">
            </div>
          </div>
        </div>

        <div class="field-row cols-2">
          <div class="field-group">
            <label class="field-label">Aadhaar Front Side <span class="req">*</span></label>
            <div class="upload-zone" id="uz-aadFront">
              <input type="file" name="aadhaarFront" accept="image/jpeg,image/png,application/pdf" onchange="fileChosen(this,'pv-aadFront')"  <%= !isResubmit ? "required" : "" %>>
              <div class="upload-icon"><i class="bi bi-card-image"></i></div>
              <span class="upload-label">Upload Front</span>
              <span class="upload-hint">JPG, PNG or PDF · Max 5 MB</span>
              <div class="upload-preview" id="pv-aadFront"><i class="bi bi-check-circle-fill"></i> <span></span></div>
            </div>
          </div>
          <div class="field-group">
            <label class="field-label">Aadhaar Back Side <span class="req">*</span></label>
            <div class="upload-zone" id="uz-aadBack">
              <input type="file" name="aadhaarBack" accept="image/jpeg,image/png,application/pdf" onchange="fileChosen(this,'pv-aadBack')"  <%= !isResubmit ? "required" : "" %>>
              <div class="upload-icon"><i class="bi bi-card-image"></i></div>
              <span class="upload-label">Upload Back</span>
              <span class="upload-hint">JPG, PNG or PDF · Max 5 MB</span>
              <div class="upload-preview" id="pv-aadBack"><i class="bi bi-check-circle-fill"></i> <span></span></div>
            </div>
          </div>
        </div>

        <div class="section-divider"></div>

        <!-- PAN -->
        <div class="section-head">
          <div class="section-head-icon amber"><i class="bi bi-file-earmark-text-fill"></i></div>
          <div class="section-head-text">
            <h3>PAN Card</h3>
            <p>Mandatory for tax purposes and wallet payouts</p>
          </div>
        </div>

        <div class="field-row cols-2">
          <div class="field-group">
            <label class="field-label">PAN Number <span class="req">*</span></label>
            <div class="field-wrap">
              <span class="field-icon"><i class="bi bi-upc"></i></span>
              <input type="text" name="panNumber" class="form-control" placeholder="ABCDE1234F" required pattern="[A-Z]{5}[0-9]{4}[A-Z]" maxlength="10" style="text-transform:uppercase;"
             value="<%= prefill != null && prefill.getPanNumber() != null ? prefill.getPanNumber() : "" %>" >
            </div>
          </div>
          <div class="field-group">
            <label class="field-label">PAN Card Image <span class="req">*</span></label>
            <div class="upload-zone">
              <input type="file" name="panImage" accept="image/jpeg,image/png,application/pdf" onchange="fileChosen(this,'pv-pan')"  <%= !isResubmit ? "required" : "" %>>
              <div class="upload-icon"><i class="bi bi-file-earmark-image"></i></div>
              <span class="upload-label">Upload PAN Card</span>
              <span class="upload-hint">JPG, PNG or PDF · Max 5 MB</span>
              <div class="upload-preview" id="pv-pan"><i class="bi bi-check-circle-fill"></i> <span></span></div>
            </div>
          </div>
        </div>

        <div class="section-divider"></div>

        <!-- Driving Licence -->
        <div class="section-head">
          <div class="section-head-icon amber"><i class="bi bi-card-checklist"></i></div>
          <div class="section-head-text">
            <h3>Driving Licence</h3>
            <p>Valid DL — must not be expired</p>
          </div>
        </div>

        <div class="field-row cols-3">
          <div class="field-group">
            <label class="field-label">DL Number <span class="req">*</span></label>
            <div class="field-wrap">
              <span class="field-icon"><i class="bi bi-card-heading"></i></span>
              <input type="text" name="dlNumber" class="form-control" placeholder="TS0920190012345" required style="text-transform:uppercase;"
              value="<%= prefill != null && prefill.getDlNumber()     != null ? prefill.getDlNumber()     : "" %>">
            </div>
          </div>
          <div class="field-group">
            <label class="field-label">DL Issue Date <span class="req">*</span></label>
            <div class="field-wrap">
              <span class="field-icon"><i class="bi bi-calendar-check"></i></span>
              <input type="date" name="dlIssueDate" class="form-control" required
              value="<%= prefill != null && prefill.getDlIssueDate()     != null ? prefill.getDlIssueDate()     : "" %>">
            </div>
          </div>
          <div class="field-group">
            <label class="field-label">DL Expiry Date <span class="req">*</span></label>
            <div class="field-wrap">
              <span class="field-icon"><i class="bi bi-calendar-x"></i></span>
              <input type="date" name="dlExpiryDate" class="form-control" required id="dlExpiry"
              value="<%= prefill != null && prefill.getDlExpiryDate()     != null ? prefill.getDlExpiryDate()     : "" %>">
            </div>
          </div>
        </div>

        <div class="field-row cols-2">
          <div class="field-group">
            <label class="field-label">DL Front Side <span class="req">*</span></label>
            <div class="upload-zone">
              <input type="file" name="dlFront" accept="image/jpeg,image/png,application/pdf" onchange="fileChosen(this,'pv-dlFront')"  <%= !isResubmit ? "required" : "" %>>
              <div class="upload-icon"><i class="bi bi-card-image"></i></div>
              <span class="upload-label">Upload Front</span>
              <span class="upload-hint">JPG, PNG or PDF · Max 5 MB</span>
              <div class="upload-preview" id="pv-dlFront"><i class="bi bi-check-circle-fill"></i> <span></span></div>
            </div>
          </div>
          <div class="field-group">
            <label class="field-label">DL Back Side <span class="req">*</span></label>
            <div class="upload-zone">
              <input type="file" name="dlBack" accept="image/jpeg,image/png,application/pdf" onchange="fileChosen(this,'pv-dlBack')"  <%= !isResubmit ? "required" : "" %>>
              <div class="upload-icon"><i class="bi bi-card-image"></i></div>
              <span class="upload-label">Upload Back</span>
              <span class="upload-hint">JPG, PNG or PDF · Max 5 MB</span>
              <div class="upload-preview" id="pv-dlBack"><i class="bi bi-check-circle-fill"></i> <span></span></div>
            </div>
          </div>
        </div>

        <div class="section-divider"></div>

        <!-- Address Proof -->
        <div class="section-head">
          <div class="section-head-icon amber"><i class="bi bi-geo-alt-fill"></i></div>
          <div class="section-head-text">
            <h3>Address Proof</h3>
            <p>Any one — utility bill / bank passbook / voter ID / passport (not older than 3 months)</p>
          </div>
        </div>

        <div class="field-row cols-2">
          <div class="field-group">
            <label class="field-label">Document Type <span class="req">*</span></label>
            <div class="sel-wrap">
              <span class="field-icon"><i class="bi bi-file-earmark-fill"></i></span>
              <select name="addressProofType" class="form-select" required>
                <option value="">Select…</option>
				<option value="Aadhaar"         <%= prefill != null && "Aadhaar".equals(prefill.getAddressProofType())         ? "selected" : "" %>>Aadhaar</option>
				<option value="Passport"        <%= prefill != null && "Passport".equals(prefill.getAddressProofType())        ? "selected" : "" %>>Passport</option>
				<option value="Voter ID"        <%= prefill != null && "Voter ID".equals(prefill.getAddressProofType())        ? "selected" : "" %>>Voter ID</option>
				<option value="Utility Bill"    <%= prefill != null && "Utility Bill".equals(prefill.getAddressProofType())    ? "selected" : "" %>>Utility Bill</option>
				<option value="Rent Agreement"  <%= prefill != null && "Rent Agreement".equals(prefill.getAddressProofType())  ? "selected" : "" %>>Rent Agreement</option>
				<option value="Bank Statement"  <%= prefill != null && "Bank Statement".equals(prefill.getAddressProofType())  ? "selected" : "" %>>Bank Statement</option>
              </select>
            </div>
          </div>
          <div class="field-group">
            <label class="field-label">Upload Document <span class="req">*</span></label>
            <div class="upload-zone">
              <input type="file" name="addressProof" accept="image/jpeg,image/png,application/pdf" onchange="fileChosen(this,'pv-addr')"  <%= !isResubmit ? "required" : "" %>>
              <div class="upload-icon"><i class="bi bi-file-earmark-arrow-up-fill"></i></div>
              <span class="upload-label">Upload Address Proof</span>
              <span class="upload-hint">JPG, PNG or PDF · Max 5 MB</span>
              <div class="upload-preview" id="pv-addr"><i class="bi bi-check-circle-fill"></i> <span></span></div>
            </div>
          </div>
        </div>

      </div>
    </div><!-- /step2 -->


    <!-- ══════════════════════════════════════════════
         STEP 3 — VEHICLE DETAILS
    ══════════════════════════════════════════════ -->
    <div class="step-panel" id="step3">
      <div class="form-body">

        <div class="info-chips">
          <div class="info-chip blue"><i class="bi bi-truck"></i> Vehicle details verified before activation</div>
          <div class="info-chip amber"><i class="bi bi-shield-check-fill"></i> Insurance mandatory</div>
        </div>

        <div class="section-head">
          <div class="section-head-icon green"><i class="bi bi-truck-front-fill"></i></div>
          <div class="section-head-text">
            <h3>Vehicle Information</h3>
            <p>The vehicle you'll use for deliveries</p>
          </div>
        </div>

        <div class="field-row cols-3">
          <div class="field-group">
            <label class="field-label">Vehicle Type <span class="req">*</span></label>
            <div class="sel-wrap">
              <span class="field-icon"><i class="bi bi-car-front-fill"></i></span>
              <select name="vehicleType" class="form-select" required id="vehicleTypeSelect">
                <option value="">Select type</option>
                <option value="Motorcycle"      <%= prefill != null && "Motorcycle".equals(prefill.getVehicleType())      ? "selected" : "" %>>Motorcycle</option>
				<option value="Scooter"         <%= prefill != null && "Scooter".equals(prefill.getVehicleType())         ? "selected" : "" %>>Scooter</option>
				<option value="Bicycle"         <%= prefill != null && "Bicycle".equals(prefill.getVehicleType())         ? "selected" : "" %>>Bicycle</option>
				<option value="Electric Scooter"<%= prefill != null && "Electric Scooter".equals(prefill.getVehicleType()) ? "selected" : "" %>>Electric Scooter</option>
				<option value="Three-Wheeler"   <%= prefill != null && "Three-Wheeler".equals(prefill.getVehicleType())   ? "selected" : "" %>>Three-Wheeler</option>
				<option value="Van"             <%= prefill != null && "Van".equals(prefill.getVehicleType())             ? "selected" : "" %>>Van</option>
               
              </select>
            </div>
          </div>
          <div class="field-group">
            <label class="field-label">Ownership <span class="req">*</span></label>
            <div class="sel-wrap">
              <span class="field-icon"><i class="bi bi-person-check-fill"></i></span>
              <select name="vehicleOwnership" class="form-select" required>
                <option value="">Select</option>
                <option value="Own"    <%= prefill != null && "Own".equals(prefill.getVehicleOwnership())    ? "selected" : "" %>>Own</option>
				<option value="Rented" <%= prefill != null && "Rented".equals(prefill.getVehicleOwnership()) ? "selected" : "" %>>Rented</option>
				<option value="Leased" <%= prefill != null && "Leased".equals(prefill.getVehicleOwnership()) ? "selected" : "" %>>Leased</option>
              </select>
            </div>
          </div>
          <div class="field-group">
            <label class="field-label">Fuel Type <span class="req">*</span></label>
            <div class="sel-wrap">
              <span class="field-icon"><i class="bi bi-fuel-pump-fill"></i></span>
              <select name="fuelType" class="form-select" required id="fuelTypeSelect">
                <option value="">Select</option>
               <option value="Petrol"   <%= prefill != null && "Petrol".equals(prefill.getFuelType())   ? "selected" : "" %>>Petrol</option>
				<option value="Diesel"   <%= prefill != null && "Diesel".equals(prefill.getFuelType())   ? "selected" : "" %>>Diesel</option>
				<option value="Electric" <%= prefill != null && "Electric".equals(prefill.getFuelType()) ? "selected" : "" %>>Electric</option>
				<option value="CNG"      <%= prefill != null && "CNG".equals(prefill.getFuelType())      ? "selected" : "" %>>CNG</option>
				<option value="Hybrid"   <%= prefill != null && "Hybrid".equals(prefill.getFuelType())   ? "selected" : "" %>>Hybrid</option>
                <option>N/A (Non-motorised)</option>
              </select>
            </div>
          </div>
        </div>

        <div class="field-row cols-3">
          <div class="field-group">
            <label class="field-label">Vehicle Brand / Make <span class="req">*</span></label>
            <div class="field-wrap">
              <span class="field-icon"><i class="bi bi-building-gear"></i></span>
              <input type="text" name="vehicleBrand" class="form-control" placeholder="Honda / TVS / Bajaj…" required
              value="<%= prefill != null && prefill.getVehicleBrand()  != null ? prefill.getVehicleBrand()   : "" %>">
            </div>
          </div>
          <div class="field-group">
            <label class="field-label">Model Name <span class="req">*</span></label>
            <div class="field-wrap">
              <span class="field-icon"><i class="bi bi-tag-fill"></i></span>
              <input type="text" name="vehicleModel" class="form-control" placeholder="Activa 6G" required
              value="<%= prefill != null && prefill.getVehicleModel()   != null ? prefill.getVehicleModel()   : "" %>">
            </div>
          </div>
          <div class="field-group">
            <label class="field-label">Year of Manufacture <span class="req">*</span></label>
            <div class="field-wrap">
              <span class="field-icon"><i class="bi bi-calendar3"></i></span>
              <input type="number" name="vehicleYear" class="form-control" placeholder="2022" min="2000" max="2026" required
              value="<%= prefill != null && prefill.getVehicleYear()   != null ? prefill.getVehicleYear()   : "" %>">
            </div>
          </div>
        </div>

        <div class="field-row cols-2" id="regPlateRow">
          <div class="field-group">
            <label class="field-label">Registration / Plate Number <span class="req">*</span></label>
            <div class="field-wrap">
              <span class="field-icon"><i class="bi bi-123"></i></span>
              <input type="text" name="vehicleRegNumber" id="vehicleRegNum" class="form-control" placeholder="TS09EA1234" required style="text-transform:uppercase;"
              value="<%= prefill != null && prefill.getVehicleRegNumber()   != null ? prefill.getVehicleRegNumber()   : "" %>">
            </div>
          </div>
          <div class="field-group">
            <label class="field-label">Vehicle Colour</label>
            <div class="field-wrap">
              <span class="field-icon"><i class="bi bi-palette-fill"></i></span>
              <input type="text" name="vehicleColour" class="form-control" placeholder="Red / Black / White…"
              value="<%= prefill != null && prefill.getVehicleColour()   != null ? prefill.getVehicleColour()   : "" %>">
            </div>
          </div>
        </div>

        <div class="section-divider"></div>

        <div class="section-head">
          <div class="section-head-icon green"><i class="bi bi-file-earmark-medical-fill"></i></div>
          <div class="section-head-text">
            <h3>Vehicle Documents</h3>
            <p>RC Book, Insurance and Pollution Certificate</p>
          </div>
        </div>

        <div class="field-row cols-2">
          <div class="field-group">
            <label class="field-label">RC Book (Registration Certificate) <span class="req">*</span></label>
            <div class="upload-zone">
              <input type="file" name="rcBook" accept="image/jpeg,image/png,application/pdf" onchange="fileChosen(this,'pv-rc')"  <%= !isResubmit ? "required" : "" %>
              >
              <div class="upload-icon"><i class="bi bi-file-earmark-text-fill"></i></div>
              <span class="upload-label">Upload RC Book</span>
              <span class="upload-hint">JPG, PNG or PDF · Max 5 MB</span>
              <div class="upload-preview" id="pv-rc"><i class="bi bi-check-circle-fill"></i> <span></span></div>
            </div>
          </div>
          <div class="field-group">
            <label class="field-label">Vehicle Photo (Side View) <span class="req">*</span></label>
            <div class="upload-zone">
              <input type="file" name="vehiclePhoto" accept="image/jpeg,image/png,image/webp" onchange="fileChosen(this,'pv-vphoto')"  <%= !isResubmit ? "required" : "" %>>
              <div class="upload-icon"><i class="bi bi-camera-fill"></i></div>
              <span class="upload-label">Upload Vehicle Photo</span>
              <span class="upload-hint">JPG, PNG or WEBP · Max 5 MB</span>
              <div class="upload-preview" id="pv-vphoto"><i class="bi bi-check-circle-fill"></i> <span></span></div>
            </div>
          </div>
        </div>

        <div class="field-row cols-3">
          <div class="field-group">
            <label class="field-label">Insurance Policy No. <span class="req">*</span></label>
            <div class="field-wrap">
              <span class="field-icon"><i class="bi bi-shield-fill-check"></i></span>
              <input type="text" name="insuranceNumber" class="form-control" placeholder="HDFC/123/2024" required
              value="<%= prefill != null && prefill.getInsuranceNumber()   != null ? prefill.getInsuranceNumber()  : "" %>">
            </div>
          </div>
          <div class="field-group">
            <label class="field-label">Insurance Expiry <span class="req">*</span></label>
            <div class="field-wrap">
              <span class="field-icon"><i class="bi bi-calendar-x-fill"></i></span>
              <input type="date" name="insuranceExpiry" class="form-control" required id="insuranceExpiry"
              value="<%= prefill != null && prefill.getInsuranceExpiry()   != null ? prefill.getInsuranceExpiry()   : "" %>">
            </div>
          </div>
          <div class="field-group">
            <label class="field-label">Insurance Certificate <span class="req">*</span></label>
            <div class="upload-zone" style="padding:0.7rem;">
              <input type="file" name="insuranceCert" accept="image/jpeg,image/png,application/pdf" onchange="fileChosen(this,'pv-ins')" 
             <%= !isResubmit ? "required" : "" %>>
              <div class="upload-icon" style="font-size:1.1rem;margin-bottom:0.1rem;"><i class="bi bi-file-earmark-medical-fill"></i></div>
              <span class="upload-label" style="font-size:0.75rem;">Upload Insurance</span>
              <div class="upload-preview" id="pv-ins"><i class="bi bi-check-circle-fill"></i> <span></span></div>
            </div>
          </div>
        </div>

        <div class="field-row cols-3">
          <div class="field-group">
            <label class="field-label">PUC Certificate No.</label>
            <div class="field-wrap">
              <span class="field-icon"><i class="bi bi-cloud-fill"></i></span>
              <input type="text" name="pucNumber" class="form-control" placeholder="PUC Number"
             value="<%= prefill != null && prefill.getPucNumber()   != null ? prefill.getPucNumber()   : "" %>" >
            </div>
          </div>
          <div class="field-group">
            <label class="field-label">PUC Expiry Date</label>
            <div class="field-wrap">
              <span class="field-icon"><i class="bi bi-calendar-x"></i></span>
              <input type="date" name="pucExpiry" class="form-control"
              value="<%= prefill != null && prefill.getPucExpiry()   != null ? prefill.getPucExpiry()   : "" %>">
            </div>
          </div>
          <div class="field-group">
            <label class="field-label">PUC Certificate Image</label>
            <div class="upload-zone" style="padding:0.7rem;">
              <input type="file" name="pucCert" accept="image/jpeg,image/png,application/pdf" onchange="fileChosen(this,'pv-puc')">
              <div class="upload-icon" style="font-size:1.1rem;margin-bottom:0.1rem;"><i class="bi bi-file-earmark-check-fill"></i></div>
              <span class="upload-label" style="font-size:0.75rem;">Upload PUC</span>
              <div class="upload-preview" id="pv-puc"><i class="bi bi-check-circle-fill"></i> <span></span></div>
            </div>
          </div>
        </div>

        <!-- Payload capacity -->
        <div class="field-row cols-2">
          <div class="field-group">
            <label class="field-label">Max Payload Capacity (kg)</label>
            <div class="field-wrap">
              <span class="field-icon"><i class="bi bi-box-seam-fill"></i></span>
              <input type="number" name="payloadKg" class="form-control" placeholder="e.g. 100" min="1"
              value="<%= prefill != null && prefill.getPayloadKg()   != null ? prefill.getPayloadKg()  : "" %>">
            </div>
          </div>
          <div class="field-group">
            <label class="field-label">Preferred Delivery Zone / Area <span class="req">*</span></label>
            <div class="field-wrap">
              <span class="field-icon"><i class="bi bi-geo-fill"></i></span>
              <input type="text" name="deliveryZone" class="form-control" placeholder="Warangal, Hanamkonda, Kazipet" required
               value="<%= prefill != null && prefill.getDeliveryZone() != null ? prefill.getDeliveryZone() : "" %>">
            </div>
          </div>
        </div>

      </div>
    </div><!-- /step3 -->


    <!-- ══════════════════════════════════════════════
         STEP 4 — BANK DETAILS
    ══════════════════════════════════════════════ -->
    <div class="step-panel" id="step4">
      <div class="form-body">

        <div class="info-chips">
          <div class="info-chip blue"><i class="bi bi-bank2"></i> Used for payout transfers only</div>
          <div class="info-chip green"><i class="bi bi-lock-fill"></i> AES-256 encrypted storage</div>
        </div>

        <div class="section-head">
          <div class="section-head-icon purple"><i class="bi bi-bank2"></i></div>
          <div class="section-head-text">
            <h3>Bank Account Details</h3>
            <p>Your weekly earnings will be credited to this account</p>
          </div>
        </div>

        <div class="field-row cols-2">
          <div class="field-group">
            <label class="field-label">Account Holder Name <span class="req">*</span></label>
            <div class="field-wrap">
              <span class="field-icon"><i class="bi bi-person-fill"></i></span>
              <input type="text" name="bankAccName" class="form-control" placeholder="As per bank records" required>
            </div>
          </div>
          <div class="field-group">
            <label class="field-label">Bank Name <span class="req">*</span></label>
            <div class="sel-wrap">
              <span class="field-icon"><i class="bi bi-building-fill"></i></span>
              <select name="bankName" class="form-select" required>
                <option value="<%= prefill != null && prefill.getBankName()   != null ? prefill.getBankName()   : "" %>">Select bank</option>
                <option>State Bank of India (SBI)</option>
                <option>HDFC Bank</option>
                <option>ICICI Bank</option>
                <option>Axis Bank</option>
                <option>Kotak Mahindra Bank</option>
                <option>Punjab National Bank (PNB)</option>
                <option>Bank of Baroda (BOB)</option>
                <option>Canara Bank</option>
                <option>Union Bank of India</option>
                <option>Indian Bank</option>
                <option>Central Bank of India</option>
                <option>Bank of India</option>
                <option>IndusInd Bank</option>
                <option>Yes Bank</option>
                <option>IDFC FIRST Bank</option>
                <option>Federal Bank</option>
                <option>UCO Bank</option>
                <option>Other</option>
              </select>
            </div>
          </div>
        </div>

        <div class="field-row cols-2">
          <div class="field-group">
            <label class="field-label">Account Number <span class="req">*</span></label>
            <div class="field-wrap">
              <span class="field-icon"><i class="bi bi-credit-card-fill"></i></span>
              <input type="text" name="bankAccNumber" id="bankAcc" class="form-control has-r" placeholder="Enter account number" required pattern="[0-9]{9,18}" maxlength="18"
              value="<%= prefill != null && prefill.getBankAccName()   != null ? prefill.getBankAccName()   : "" %>">
              <button type="button" class="field-icon-r" onclick="togglePwd('bankAcc','eyeC')"><i class="bi bi-eye" id="eyeC"></i></button>
            </div>
          </div>
          <div class="field-group">
            <label class="field-label">Confirm Account Number <span class="req">*</span></label>
            <div class="field-wrap">
              <span class="field-icon"><i class="bi bi-credit-card-fill"></i></span>
              <input type="text" name="bankAccNumberConfirm" class="form-control" placeholder="Re-enter account number" required maxlength="18"
              value="<%= prefill != null && prefill.getBankAccNumber()    != null ? prefill.getBankAccNumber()    : "" %>">
            </div>
          </div>
        </div>

        <div class="field-row cols-2">
          <div class="field-group">
            <label class="field-label">IFSC Code <span class="req">*</span></label>
            <div class="field-wrap">
              <span class="field-icon"><i class="bi bi-hash"></i></span>
              <input type="text" name="ifscCode" class="form-control" placeholder="SBIN0001234" required pattern="[A-Z]{4}0[A-Z0-9]{6}" maxlength="11" style="text-transform:uppercase;"
              value="<%= prefill != null && prefill.getIfscCode()    != null ? prefill.getIfscCode()   : "" %>">
            </div>
            <div class="field-hint">First 4 letters = bank, 5th = 0, last 6 = branch code</div>
          </div>
          <div class="field-group">
            <label class="field-label">Branch Name <span class="req">*</span></label>
            <div class="field-wrap">
              <span class="field-icon"><i class="bi bi-geo-alt-fill"></i></span>
              <input type="text" name="branchName" class="form-control" placeholder="Hanamkonda Branch" required
              value="<%= prefill != null && prefill.getBranchName()    != null ? prefill.getBranchName()    : "" %>">
            </div>
          </div>
        </div>

        <div class="field-row cols-2">
          <div class="field-group">
            <label class="field-label">Account Type <span class="req">*</span></label>
            <div class="sel-wrap">
              <span class="field-icon"><i class="bi bi-wallet2"></i></span>
              <select name="accountType" class="form-select" required>
                <option value="">Select type</option>
                <option value="Savings Account" <%= prefill != null && "Savings".equals(prefill.getAccountType()) ? "selected" : "" %>>Savings</option>
				<option value="Current Account" <%= prefill != null && "Current".equals(prefill.getAccountType()) ? "selected" : "" %>>Current</option>
              </select>
            </div>
          </div>
          <div class="field-group">
            <label class="field-label">UPI ID (Optional)</label>
            <div class="field-wrap">
              <span class="field-icon"><i class="bi bi-phone-fill"></i></span>
              <input type="text" name="upiId" class="form-control" placeholder="mobile@upi"
              value="<%= prefill != null && prefill.getUpiId()     != null ? prefill.getUpiId()     : "" %>">
            </div>
          </div>
        </div>

        <div class="field-row cols-2">
          <div class="field-group">
            <label class="field-label">Passbook / Cancelled Cheque <span class="req">*</span></label>
            <div class="upload-zone">
              <input type="file" name="bankProof" accept="image/jpeg,image/png,application/pdf" onchange="fileChosen(this,'pv-bank')"  <%= !isResubmit ? "required" : "" %>>
              <div class="upload-icon"><i class="bi bi-journal-bookmark-fill"></i></div>
              <span class="upload-label">Upload Passbook / Cheque</span>
              <span class="upload-hint">Shows account no. &amp; IFSC · Max 5 MB</span>
              <div class="upload-preview" id="pv-bank"><i class="bi bi-check-circle-fill"></i> <span></span></div>
            </div>
          </div>
          <div class="field-group" style="align-self:flex-end;">
            <div style="background:rgba(245,158,11,0.08);border:1px solid rgba(245,158,11,0.2);border-radius:var(--radius-xs);padding:1rem 1.1rem;">
              <div style="font-size:0.8rem;font-weight:700;color:var(--amber-dark);margin-bottom:0.4rem;display:flex;align-items:center;gap:0.4rem;">
                <i class="bi bi-exclamation-triangle-fill"></i> Important
              </div>
              <div style="font-size:0.77rem;color:var(--ink-muted);line-height:1.5;">
                Ensure your bank account is linked to your mobile number for UPI transfers.
                Earnings are credited every <strong>Monday</strong> for the previous week's deliveries.
              </div>
            </div>
          </div>
        </div>

        <div class="section-divider"></div>

        <!-- Emergency Contact -->
        <div class="section-head">
          <div class="section-head-icon purple"><i class="bi bi-telephone-plus-fill"></i></div>
          <div class="section-head-text">
            <h3>Emergency Contact</h3>
            <p>Person to notify in case of an on-field emergency</p>
          </div>
        </div>

        <div class="field-row cols-3">
          <div class="field-group">
            <label class="field-label">Full Name <span class="req">*</span></label>
            <div class="field-wrap">
              <span class="field-icon"><i class="bi bi-person-heart-fill"></i></span>
              <input type="text" name="emergencyName" class="form-control" placeholder="Contact name" required
              value="<%= prefill != null && prefill.getEmergencyName()     != null ? prefill.getEmergencyName()     : "" %>">
            </div>
          </div>
          <div class="field-group">
            <label class="field-label">Relationship <span class="req">*</span></label>
            <div class="sel-wrap">
              <span class="field-icon"><i class="bi bi-people-fill"></i></span>
              <select name="emergencyRelation" class="form-select" required>
		      <option value="">Select…</option>
				<option value="Father"  <%= prefill != null && "Father".equals(prefill.getEmergencyRelation())  ? "selected" : "" %>>Father</option>
				<option value="Mother"  <%= prefill != null && "Mother".equals(prefill.getEmergencyRelation())  ? "selected" : "" %>>Mother</option>
				<option value="Spouse"  <%= prefill != null && "Spouse".equals(prefill.getEmergencyRelation())  ? "selected" : "" %>>Spouse</option>
				<option value="Sibling" <%= prefill != null && "Sibling".equals(prefill.getEmergencyRelation()) ? "selected" : "" %>>Sibling</option>
				<option value="Friend"  <%= prefill != null && "Friend".equals(prefill.getEmergencyRelation())  ? "selected" : "" %>>Friend</option>
				<option value="Other"   <%= prefill != null && "Other".equals(prefill.getEmergencyRelation())   ? "selected" : "" %>>Other</option>
              </select>
            </div>
          </div>
          <div class="field-group">
            <label class="field-label">Mobile Number <span class="req">*</span></label>
            <div class="field-wrap">
              <span class="field-icon"><i class="bi bi-telephone-fill"></i></span>
              <input type="tel" name="emergencyMobile" class="form-control" placeholder="9876543210" required pattern="[6-9][0-9]{9}" maxlength="10"
              value="<%= prefill != null && prefill.getEmergencyMobile()     != null ? prefill.getEmergencyMobile()     : "" %>">
            </div>
          </div>
        </div>

        <div class="section-divider"></div>

        <!-- Terms -->
        <div>
          <div class="check-group">
            <input type="checkbox" id="terms" name="terms" required>
            <label for="terms">
              I have read and agree to the <a href="#">Terms &amp; Conditions</a>,
              <a href="#">Privacy Policy</a>, and <a href="#">Delivery Partner Agreement</a>.
              I confirm all the information provided is accurate and authentic.
            </label>
          </div>
          <div class="check-group" style="margin-top:0.6rem;">
            <input type="checkbox" id="consent" name="consent" required>
            <label for="consent">
              I consent to Smart Inventory verifying my documents with government authorities
              and storing my KYC data securely for the duration of my partnership.
            </label>
          </div>
        </div>

      </div>
    </div><!-- /step4 -->

    <!-- Actions -->
    <div class="form-actions" id="formActions">
      <button type="button" class="btn-back" id="btnBack" onclick="prevStep()" style="visibility:hidden;">
        <i class="bi bi-arrow-left"></i> Back
      </button>
      <div style="display:flex;flex-direction:column;align-items:flex-end;gap:0.5rem;flex:1;">
        <!-- Error banner — shown by two-step submit JS on validation / server failure -->
        <div id="formError" style="display:none;width:100%;background:#fff1f1;border:1px solid #fca5a5;
             color:#dc2626;border-left:3px solid #dc2626;border-radius:8px;
             padding:0.7rem 1rem;font-size:0.84rem;font-weight:500;
             display:none;align-items:flex-start;gap:0.5rem;">
          <i class="bi bi-exclamation-circle-fill" style="flex-shrink:0;margin-top:1px;"></i>
          <span id="formErrorText"></span>
        </div>
        <!-- Progress indicator -->
        <div id="formProgress" style="display:none;font-size:0.83rem;color:var(--ink-muted);
             display:none;align-items:center;gap:0.5rem;">
          <span class="spinner-border spinner-border-sm" style="color:var(--ocean);"></span>
          <span id="formProgressText">Submitting…</span>
        </div>
        <button type="button" class="btn-next" id="btnNext" onclick="nextStep()">
          Next <i class="bi bi-arrow-right"></i>
        </button>
      </div>
    </div>

    </form><!-- /regForm -->
  </div><!-- /reg-card -->

</div><!-- /page-wrap -->

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script>
/* ══════════ STAR GENERATOR ══════════ */
(function(){
  const s=document.getElementById('stars');
  for(let i=0;i<80;i++){
    const d=document.createElement('div');
    const sz=Math.random()*2+1;
    d.className='star';
    d.style.cssText=`width:${sz}px;height:${sz}px;top:${Math.random()*85}%;left:${Math.random()*100}%;--dur:${Math.random()*4+3}s;--delay:${Math.random()*4}s;`;
    s.appendChild(d);
  }
})();

/* ══════════ STEPPER ══════════ */
let currentStep = 1;
const totalSteps = 4;

const stepMeta = [
  null,
  { icon:'bi-person-vcard-fill', title:'Personal Information', sub:'Tell us about yourself — name, contact & address details', badge:'STEP 1 OF 4' },
  { icon:'bi-file-earmark-lock2-fill', title:'KYC Documents', sub:'Aadhaar, PAN, Driving Licence and Address Proof', badge:'STEP 2 OF 4' },
  { icon:'bi-truck-front-fill', title:'Vehicle Details', sub:'Vehicle registration, insurance and delivery zone', badge:'STEP 3 OF 4' },
  { icon:'bi-bank2', title:'Bank & Emergency Contact', sub:'Payout bank account and emergency contact information', badge:'STEP 4 OF 4' },
];

function updateUI(step) {
  // Panels
  document.querySelectorAll('.step-panel').forEach((p,i)=>{
    p.classList.toggle('active', i+1===step);
  });
  // Step indicators
  for(let i=1;i<=5;i++){
    const el=document.getElementById('si-'+i);
    el.classList.remove('active','done');
    if(i<step) el.classList.add('done');
    else if(i===step) el.classList.add('active');
    // tick icon
    const circle=el.querySelector('.step-circle');
    if(i<step) circle.innerHTML='<i class="bi bi-check2" style="font-size:0.9rem;"></i>';
    else if(i<5) circle.textContent=i;
  }
  // Top bar
  const m=stepMeta[step];
  document.querySelector('#topBar .card-top-icon i').className='bi '+m.icon;
  document.getElementById('topTitle').textContent=m.title;
  document.getElementById('topSub').textContent=m.sub;
  document.getElementById('topBadge').textContent=m.badge;
  // Buttons
  document.getElementById('btnBack').style.visibility = step===1 ? 'hidden' : 'visible';
  const btnN=document.getElementById('btnNext');
  if(step===totalSteps){
    btnN.innerHTML='<i class="bi bi-send-fill"></i> Submit Application';
    btnN.className='btn-next green';
    btnN.onclick=submitForm;
  } else {
    btnN.innerHTML='Next <i class="bi bi-arrow-right"></i>';
    btnN.className='btn-next';
    btnN.onclick=nextStep;
    btnN.disabled=false;
  }
}

function nextStep(){
  if(!validateStep(currentStep)) return;
  if(currentStep<totalSteps){ currentStep++; updateUI(currentStep); window.scrollTo({top:0,behavior:'smooth'}); }
}
function prevStep(){
  if(currentStep>1){ currentStep--; updateUI(currentStep); window.scrollTo({top:0,behavior:'smooth'}); }
}

/* ══════════ VALIDATION ══════════ */
function validateStep(step){
  const panel=document.getElementById('step'+step);
  const inputs=panel.querySelectorAll('[required]');
  let ok=true;
  inputs.forEach(inp=>{
    inp.style.borderColor='';
    if(!inp.checkValidity()||(inp.value.trim()===''&&inp.type!=='file')||(inp.type==='file'&&inp.required&&inp.files.length===0)){
      inp.style.borderColor='var(--red)';
      if(ok){ inp.scrollIntoView({behavior:'smooth',block:'center'}); inp.focus(); }
      ok=false;
    }
  });
  // Extra: password match on step 1
  if(step===1){
    const p=document.getElementById('pwdField').value;
    const c=document.getElementById('cpwdField').value;
    if(p!==c){
      document.getElementById('cpwdField').style.borderColor='var(--red)';
      alert('Passwords do not match.'); ok=false;
    }
  }
  // DL expiry must be future
  if(step===2){
    const exp=document.getElementById('dlExpiry').value;
    if(exp && new Date(exp)<new Date()){
      document.getElementById('dlExpiry').style.borderColor='var(--red)';
      alert('Driving Licence appears to be expired. Please check the expiry date.'); ok=false;
    }
  }
  // Insurance must be future
  if(step===3){
    const ie=document.getElementById('insuranceExpiry').value;
    if(ie && new Date(ie)<new Date()){
      document.getElementById('insuranceExpiry').style.borderColor='var(--red)';
      alert('Insurance certificate appears to be expired. Please upload a valid certificate.'); ok=false;
    }
  }
  if(!ok) shakeCard();
  return ok;
}

function shakeCard(){
  const c=document.querySelector('.reg-card');
  c.style.animation='none';
  setTimeout(()=>{ c.style.animation='shake 0.4s ease'; },10);
}

/* ══════════ SUBMIT — TWO-STEP (fixes FileCountLimitExceededException) ══════════
 *
 * WHY: Tomcat 9 counts ALL multipart parts (text + files) against its limit.
 * ~48 text fields + 12 files = ~60 parts → crashes before getParameter() runs.
 *
 * FIX: Split into two separate fetches:
 *   Step A — text fields only, sent as application/x-www-form-urlencoded
 *             (not multipart at all — limit never applies)
 *   Step B — files only, sent as multipart/form-data with 13 parts total (12 files + action)
 *             well within Tomcat's limit
 */
const TEXT_FIELDS = [
  'firstName','middleName','lastName','dob','gender','bloodGroup',
  'username','mobile','email','altMobile','password','confirmPassword',
  'addressLine1','addressLine2','landmark','city','state','pincode',
  'aadhaarNumber','aadhaarName','panNumber','dlNumber','dlIssueDate',
  'dlExpiryDate','addressProofType',
  'vehicleType','vehicleOwnership','fuelType','vehicleBrand','vehicleModel',
  'vehicleYear','vehicleRegNumber','vehicleColour','insuranceNumber',
  'insuranceExpiry','pucNumber','pucExpiry','payloadKg','deliveryZone',
  'bankAccName','bankName','bankAccNumber','bankAccNumberConfirm',
  'ifscCode','branchName','accountType','upiId',
  'emergencyName','emergencyRelation','emergencyMobile'
];

const FILE_FIELDS = [
  'profilePhoto','aadhaarFront','aadhaarBack','panImage',
  'dlFront','dlBack','addressProof','rcBook',
  'vehiclePhoto','insuranceCert','pucCert','bankProof'
];

function showFormError(msg) {
  const wrap = document.getElementById('formError');
  const text = document.getElementById('formErrorText');
  if (!wrap || !text) return;
  text.textContent = msg;
  wrap.style.display = msg ? 'flex' : 'none';
  if (msg) wrap.scrollIntoView({ behavior: 'smooth', block: 'center' });
}

function showFormProgress(active, msg) {
  const prog = document.getElementById('formProgress');
  const btn  = document.getElementById('btnNext');
  if (prog) {
    prog.style.display = active ? 'flex' : 'none';
    if (msg) document.getElementById('formProgressText').textContent = msg;
  }
  if (btn) btn.disabled = active;
}

async function submitForm() {
  if (!validateStep(4)) return;

  showFormError('');
  showFormProgress(true, 'Step 1 of 2: Validating your details…');

  const form = document.getElementById('registrationForm');

  // ── STEP A: send all text fields as url-encoded (NOT multipart) ──────────
  const params = new URLSearchParams();
  params.append('action', 'saveDetails');
  TEXT_FIELDS.forEach(name => {
    const el = form.elements[name];
    if (el) params.append(name, el.value);
  });

  let r1;
  try {
    const res1 = await fetch(form.action, {
      method:  'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body:    params.toString()
    });
    r1 = await res1.json();
  } catch (e) {
    showFormProgress(false);
    showFormError('Network error: ' + e.message + '. Please try again.');
    return;
  }

  if (!r1.success) {
    showFormProgress(false);
    showFormError(r1.message || 'Validation failed. Please check your details.');
    return;
  }

  // ── STEP B: send only the 12 file inputs as multipart (13 parts total) ───
  showFormProgress(true, 'Step 2 of 2: Uploading your documents…');

  const fd = new FormData();
  fd.append('action', 'uploadDocs');
  FILE_FIELDS.forEach(name => {
    const el = form.elements[name];
    if (el && el.files && el.files[0]) fd.append(name, el.files[0]);
  });

  let r2;
  try {
    const res2 = await fetch(form.action, { method: 'POST', body: fd });
    r2 = await res2.json();
  } catch (e) {
    showFormProgress(false);
    showFormError('Upload error: ' + e.message + '. Please try again.');
    return;
  }

  showFormProgress(false);

  if (r2.success && r2.redirect) {
    window.location.href = r2.redirect;
  } else {
    showFormError(r2.message || 'Document upload failed. Please try again.');
  }
}

/* ══════════ HELPERS ══════════ */
function togglePwd(id,eyeId){
  const f=document.getElementById(id);
  const ic=document.getElementById(eyeId);
  f.type=f.type==='password'?'text':'password';
  ic.className=f.type==='password'?'bi bi-eye':'bi bi-eye-slash';
}

function fileChosen(input,previewId){
  const pv=document.getElementById(previewId);
  if(input.files&&input.files[0]){
    pv.querySelector('span').textContent=input.files[0].name.substring(0,28)+'…';
    pv.style.display='flex';
    input.closest('.upload-zone').style.borderColor='var(--emerald)';
    input.closest('.upload-zone').style.background='rgba(16,185,129,0.04)';
  }
}

function previewPhoto(input){
  if(input.files&&input.files[0]){
    const reader=new FileReader();
    reader.onload=e=>{
      document.getElementById('photoPreviewImg').src=e.target.result;
      document.getElementById('photoPreviewImg').style.display='block';
      document.getElementById('photoIcon').style.display='none';
      document.getElementById('photoRing').style.borderColor='var(--emerald)';
    };
    reader.readAsDataURL(input.files[0]);
    document.getElementById('photoFileName').textContent=input.files[0].name;
    document.getElementById('photoPreviewLabel').style.display='flex';
  }
}

/* ══════════ PASSWORD STRENGTH ══════════ */
function checkStrength(v){
  let score=0;
  if(v.length>=8)score++;
  if(/[A-Z]/.test(v))score++;
  if(/[0-9]/.test(v))score++;
  if(/[^a-zA-Z0-9]/.test(v))score++;
  const fill=document.getElementById('sfill');
  const lbl=document.getElementById('slabel');
  const configs=[
    {w:'0%',color:'',text:''},
    {w:'25%',color:'#ef4444',text:'Weak'},
    {w:'50%',color:'#f59e0b',text:'Fair'},
    {w:'75%',color:'#3b82f6',text:'Good'},
    {w:'100%',color:'#10b981',text:'Strong'},
  ];
  const cfg=configs[score]||configs[0];
  fill.style.width=cfg.w;
  fill.style.background=cfg.color;
  lbl.textContent=cfg.text;
  lbl.style.color=cfg.color;
}

/* ══════════ MAX DOB ══════════ */
(function(){
  const d=document.querySelector('input[name=dob]');
  const today=new Date(); today.setFullYear(today.getFullYear()-18);
  d.max=today.toISOString().split('T')[0];
})();

/* Bicycle => hide reg plate requirement */
document.getElementById('vehicleTypeSelect').addEventListener('change',function(){
  const row=document.getElementById('regPlateRow');
  const input=document.getElementById('vehicleRegNum');
  const fuelSel=document.getElementById('fuelTypeSelect');
  if(this.value==='Bicycle'){
    row.style.opacity='0.4';
    input.removeAttribute('required');
    fuelSel.value='N/A (Non-motorised)';
  } else {
    row.style.opacity='1';
    input.setAttribute('required','');
  }
});

/* dragover styling */
document.querySelectorAll('.upload-zone').forEach(z=>{
  z.addEventListener('dragover',e=>{e.preventDefault();z.classList.add('dragover');});
  z.addEventListener('dragleave',()=>z.classList.remove('dragover'));
  z.addEventListener('drop',e=>{
    e.preventDefault(); z.classList.remove('dragover');
    const inp=z.querySelector('input[type=file]');
    if(inp&&e.dataTransfer.files.length){ inp.files=e.dataTransfer.files; inp.dispatchEvent(new Event('change')); }
  });
});
</script>

</body>
</html>
