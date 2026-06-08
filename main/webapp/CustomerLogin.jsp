<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Sign In — SIBS Store</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
  <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@300;400;500;600;700&family=Plus+Jakarta+Sans:wght@600;700;800&display=swap" rel="stylesheet">
  <style>
    :root {
      --primary:    #0ea5e9;
      --primary-dk: #0369a1;
      --primary-lt: #e0f2fe;
      --accent:     #8b5cf6;
      --accent-lt:  #ede9fe;
      --success:    #10b981;
      --danger:     #ef4444;
      --warning:    #f59e0b;
      --bg:         #f0f9ff;
      --surface:    #ffffff;
      --text:       #0c1a2e;
      --muted:      #64748b;
      --border:     #e2e8f0;
      --shadow-sm:  0 2px 8px rgba(14,165,233,.08);
      --shadow-md:  0 4px 24px rgba(14,165,233,.14);
      --shadow-lg:  0 12px 48px rgba(14,165,233,.18);
      --radius:     14px;
      --radius-sm:  10px;
    }
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

    body {
      font-family: 'DM Sans', sans-serif;
      background: var(--bg);
      min-height: 100vh;
      display: flex; align-items: center; justify-content: center;
      padding: 1.5rem;
      position: relative; overflow-x: hidden;
    }

    /* Ambient blobs */
    body::before {
      content: ''; position: fixed; top: -140px; right: -140px;
      width: 520px; height: 520px; border-radius: 50%;
      background: radial-gradient(circle, rgba(14,165,233,.13) 0%, transparent 70%);
      pointer-events: none;
    }
    body::after {
      content: ''; position: fixed; bottom: -120px; left: -120px;
      width: 440px; height: 440px; border-radius: 50%;
      background: radial-gradient(circle, rgba(139,92,246,.1) 0%, transparent 70%);
      pointer-events: none;
    }

    /* ── CARD ── */
    .login-card {
      display: flex; width: 960px; max-width: 100%;
      border-radius: 24px; overflow: hidden;
      box-shadow: var(--shadow-lg);
      background: var(--surface);
      animation: slideUp .65s cubic-bezier(.16,1,.3,1) both;
      position: relative; z-index: 1;
    }

    /* ── LEFT PANEL ── */
    .left-panel {
      width: 380px; flex-shrink: 0;
      background: linear-gradient(155deg, var(--primary-dk) 0%, var(--primary) 50%, #38bdf8 100%);
      padding: 3rem 2.5rem;
      display: flex; flex-direction: column; justify-content: space-between;
      position: relative; overflow: hidden;
    }
    .left-panel::before {
      content: ''; position: absolute; inset: 0;
      background: url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Ccircle cx='30' cy='30' r='1' fill='%23fff' fill-opacity='0.08'/%3E%3C/svg%3E");
      pointer-events: none;
    }
    .left-panel .blob1 {
      position: absolute; top: -80px; right: -80px;
      width: 260px; height: 260px; border-radius: 50%;
      background: radial-gradient(circle, rgba(255,255,255,.12) 0%, transparent 70%);
    }
    .left-panel .blob2 {
      position: absolute; bottom: -60px; left: -60px;
      width: 200px; height: 200px; border-radius: 50%;
      background: radial-gradient(circle, rgba(139,92,246,.25) 0%, transparent 70%);
    }

    .brand-mark {
      font-family: 'Plus Jakarta Sans', sans-serif;
      font-size: .75rem; font-weight: 700; letter-spacing: 3px;
      text-transform: uppercase; color: rgba(255,255,255,.6);
      position: relative; z-index: 1; display: flex; align-items: center; gap: .5rem;
    }
    .brand-mark .dot { color: #bae6fd; }

    .left-main { position: relative; z-index: 1; }

    .left-icon {
      width: 68px; height: 68px; border-radius: 18px;
      background: rgba(255,255,255,.15); border: 1.5px solid rgba(255,255,255,.3);
      display: flex; align-items: center; justify-content: center;
      font-size: 1.75rem; margin-bottom: 1.8rem;
      backdrop-filter: blur(6px);
    }

    .left-title {
      font-family: 'Plus Jakarta Sans', sans-serif;
      font-size: 2rem; font-weight: 800;
      color: #fff; line-height: 1.2; margin-bottom: .6rem;
    }
    .left-title .hl { color: #bae6fd; }

    .left-sub { font-size: .88rem; color: rgba(255,255,255,.65); line-height: 1.75; margin-bottom: 2rem; }

    .feature-list { list-style: none; position: relative; z-index: 1; }
    .feature-list li {
      display: flex; align-items: center; gap: .75rem;
      padding: .55rem 0; font-size: .84rem; color: rgba(255,255,255,.7);
      border-bottom: 1px solid rgba(255,255,255,.08);
    }
    .feature-list li:last-child { border-bottom: none; }
    .feature-list .fi {
      width: 30px; height: 30px; border-radius: 9px;
      background: rgba(255,255,255,.12); border: 1px solid rgba(255,255,255,.18);
      display: flex; align-items: center; justify-content: center;
      color: #bae6fd; font-size: .85rem; flex-shrink: 0;
    }

    /* ── RIGHT PANEL ── */
    .right-panel {
      flex: 1; padding: 3rem 2.8rem;
      display: flex; flex-direction: column; justify-content: center;
    }

    .panel-eyebrow {
      font-size: .7rem; font-weight: 700; letter-spacing: 2.5px;
      text-transform: uppercase; color: var(--primary); margin-bottom: .4rem;
      display: flex; align-items: center; gap: .4rem;
    }
    .panel-title {
      font-family: 'Plus Jakarta Sans', sans-serif;
      font-size: 1.85rem; font-weight: 800; color: var(--text); margin-bottom: .25rem;
    }
    .panel-sub { font-size: .88rem; color: var(--muted); margin-bottom: 1.75rem; }

    /* ── ALERTS ── */
    .alert-bar {
      border-radius: var(--radius-sm); padding: .75rem 1rem;
      font-size: .87rem; display: flex; align-items: center; gap: .5rem;
      margin-bottom: 1.2rem; font-weight: 500; border-left: 3px solid;
    }
    .alert-bar.err { background: #fff1f1; border-color: var(--danger); color: #b91c1c; }
    .alert-bar.ok  { background: #f0fdf4; border-color: var(--success); color: #15803d; }

    /* ── TAB SWITCHER ── */
    .tab-row {
      display: flex; background: var(--bg);
      border-radius: var(--radius-sm); padding: 4px; gap: 4px;
      margin-bottom: 1.75rem; border: 1.5px solid var(--border);
    }
    .tab-btn {
      flex: 1; padding: .55rem 0; border: none; background: transparent;
      border-radius: 7px; cursor: pointer;
      font-family: 'DM Sans', sans-serif; font-size: .82rem; font-weight: 600;
      color: var(--muted); transition: all .2s;
      display: flex; align-items: center; justify-content: center; gap: .4rem;
    }
    .tab-btn.active {
      background: var(--surface); color: var(--primary);
      box-shadow: var(--shadow-sm);
    }
    .tab-btn.active i { color: var(--primary); }

    /* ── FORM ── */
    .field-group { margin-bottom: 1.1rem; }
    .field-label {
      font-size: .75rem; font-weight: 700; letter-spacing: .4px;
      color: var(--text); display: block; margin-bottom: .4rem;
      text-transform: uppercase;
    }
    .field-label .req { color: var(--danger); margin-left: 2px; }

    .field-wrap { position: relative; }
    .form-control {
      width: 100%; border: 1.5px solid var(--border);
      border-radius: var(--radius-sm); padding: .72rem 1rem;
      font-family: 'DM Sans', sans-serif; font-size: .93rem;
      color: var(--text); background: var(--surface);
      transition: border-color .2s, box-shadow .2s; outline: none;
    }
    .form-control:focus {
      border-color: var(--primary);
      box-shadow: 0 0 0 3px rgba(14,165,233,.1);
    }
    .form-control::placeholder { color: #b0c4d8; }
    .form-control.has-icon { padding-right: 2.8rem; }

    .field-icon {
      position: absolute; right: .9rem; top: 50%; transform: translateY(-50%);
      background: none; border: none; cursor: pointer;
      color: var(--muted); font-size: 1.05rem; padding: 0; transition: color .2s;
    }
    .field-icon:hover { color: var(--primary); }

    .phone-row { display: flex; gap: .5rem; }
    .country-select {
      width: 110px; flex-shrink: 0;
      border: 1.5px solid var(--border); border-radius: var(--radius-sm);
      padding: .72rem .5rem; font-family: 'DM Sans', sans-serif;
      font-size: .88rem; color: var(--text); background: var(--surface);
      cursor: pointer; outline: none;
    }
    .country-select:focus { border-color: var(--primary); }

    .split-row { display: flex; justify-content: space-between; align-items: center; margin-bottom: .35rem; }
    .forgot-btn {
      background: none; border: none; cursor: pointer;
      font-family: 'DM Sans', sans-serif; font-size: .8rem;
      color: var(--primary); font-weight: 600; padding: 0;
    }
    .forgot-btn:hover { text-decoration: underline; }

    .remember-row { display: flex; align-items: center; gap: .5rem; margin-bottom: 1rem; }
    .remember-row input[type=checkbox] { accent-color: var(--primary); width: 15px; height: 15px; cursor: pointer; }
    .remember-row label { font-size: .83rem; color: var(--muted); cursor: pointer; }

    /* ── BUTTONS ── */
    .btn-primary-full {
      width: 100%; padding: .85rem;
      background: linear-gradient(135deg, var(--primary-dk), var(--primary));
      color: #fff; border: none; border-radius: var(--radius-sm);
      cursor: pointer; font-family: 'DM Sans', sans-serif;
      font-size: .9rem; font-weight: 700; letter-spacing: .3px;
      display: flex; align-items: center; justify-content: center; gap: .5rem;
      transition: all .2s; margin-bottom: .8rem;
      box-shadow: 0 4px 14px rgba(14,165,233,.3);
    }
    .btn-primary-full:hover { transform: translateY(-1px); box-shadow: 0 6px 20px rgba(14,165,233,.4); }
    .btn-primary-full:active { transform: translateY(0); }

    /* ── DIVIDER ── */
    .or-row {
      display: flex; align-items: center; gap: .75rem;
      margin: .75rem 0; color: var(--muted); font-size: .78rem;
    }
    .or-row::before, .or-row::after { content: ''; flex: 1; height: 1px; background: var(--border); }

    /* ── GOOGLE BTN ── */
    .btn-google {
      width: 100%; padding: .76rem;
      background: var(--surface); color: var(--text);
      border: 1.5px solid var(--border); border-radius: var(--radius-sm);
      cursor: pointer; font-family: 'DM Sans', sans-serif;
      font-size: .88rem; font-weight: 600;
      display: flex; align-items: center; justify-content: center; gap: .6rem;
      text-decoration: none; transition: all .2s;
    }
    .btn-google:hover { border-color: var(--primary); box-shadow: var(--shadow-sm); color: var(--text); }
    .google-icon { width: 18px; height: 18px; flex-shrink: 0; }

    /* ── REGISTER LINK ── */
    .register-row {
      text-align: center; margin-top: 1.4rem;
      font-size: .88rem; color: var(--muted);
    }
    .register-row a { color: var(--primary); font-weight: 700; text-decoration: none; }
    .register-row a:hover { text-decoration: underline; }

    /* ── OTP BOXES ── */
    .otp-row { display: flex; gap: .5rem; justify-content: center; margin: 1.2rem 0; }
    .otp-box {
      width: 48px; height: 54px; text-align: center;
      border: 1.5px solid var(--border); border-radius: var(--radius-sm);
      font-family: 'Plus Jakarta Sans', sans-serif; font-size: 1.3rem; font-weight: 800;
      color: var(--text); background: var(--surface);
      outline: none; transition: border-color .2s, box-shadow .2s;
    }
    .otp-box:focus { border-color: var(--primary); box-shadow: 0 0 0 3px rgba(14,165,233,.1); }
    .otp-note { text-align: center; font-size: .88rem; color: var(--text); margin-bottom: .35rem; }
    .resend-row { text-align: center; font-size: .82rem; color: var(--muted); margin-top: .5rem; }
    .resend-row a { color: var(--primary); font-weight: 600; text-decoration: none; }
    .resend-row a:hover { text-decoration: underline; }

    /* ── MODAL ── */
    .modal-content {
      border: none; border-radius: 20px;
      box-shadow: var(--shadow-lg); font-family: 'DM Sans', sans-serif; overflow: hidden;
    }
    .modal-header {
      background: linear-gradient(135deg, var(--primary-dk), var(--primary));
      padding: 1.4rem 1.8rem; border: none;
    }
    .modal-title { font-family: 'Plus Jakarta Sans', sans-serif; font-size: 1.05rem; font-weight: 800; color: #fff; }
    .modal-title i { color: #bae6fd; }
    .modal-body { padding: 1.8rem; }

    /* Step indicator */
    .step-track { display: flex; align-items: center; justify-content: center; margin-bottom: 1.75rem; }
    .step-dot {
      width: 34px; height: 34px; border-radius: 50%;
      background: var(--border); color: var(--muted);
      display: flex; align-items: center; justify-content: center;
      font-size: .8rem; font-weight: 700; transition: all .3s;
    }
    .step-dot.active { background: var(--primary); color: #fff; box-shadow: 0 0 0 4px rgba(14,165,233,.15); }
    .step-dot.done   { background: var(--success); color: #fff; }
    .step-line { flex: 1; height: 2px; background: var(--border); max-width: 60px; transition: background .3s; }
    .step-line.done { background: var(--success); }
    .step-label {
      display: flex; justify-content: space-around;
      font-size: .7rem; color: var(--muted);
      margin-bottom: 1.5rem; margin-top: -1.2rem; padding: 0 .5rem;
    }
    .fp-step { display: none; }
    .fp-step.active { display: block; animation: fadeIn .25s ease both; }
    .fp-hint { font-size: .88rem; color: var(--muted); margin-bottom: 1.2rem; line-height: 1.6; }

    /* Modal buttons */
    .modal-actions { display: flex; justify-content: space-between; align-items: center; margin-top: 1.2rem; }
    .btn-modal-sec {
      background: none; border: 1.5px solid var(--border); border-radius: 8px;
      padding: .52rem 1.1rem; font-family: 'DM Sans', sans-serif;
      font-size: .82rem; font-weight: 600; color: var(--muted);
      cursor: pointer; transition: all .2s; display: flex; align-items: center; gap: .35rem;
    }
    .btn-modal-sec:hover { border-color: var(--primary); color: var(--primary); }
    .btn-modal-pri {
      background: var(--primary); border: 1.5px solid var(--primary); border-radius: 8px;
      padding: .52rem 1.3rem; font-family: 'DM Sans', sans-serif;
      font-size: .82rem; font-weight: 700; color: #fff;
      cursor: pointer; transition: all .2s; display: flex; align-items: center; gap: .35rem;
    }
    .btn-modal-pri:hover { background: var(--primary-dk); border-color: var(--primary-dk); }

    /* Password strength */
    .strength-track { height: 4px; background: var(--border); border-radius: 4px; margin-top: .5rem; overflow: hidden; }
    .strength-bar   { height: 100%; border-radius: 4px; width: 0; transition: width .3s, background .3s; }
    .strength-text  { font-size: .72rem; color: var(--muted); margin-top: .25rem; }

    /* ── ANIMATIONS ── */
    @keyframes slideUp { from{opacity:0;transform:translateY(28px);}to{opacity:1;transform:translateY(0);} }
    @keyframes fadeIn  { from{opacity:0;}to{opacity:1;} }

    /* ── TOAST ── */
    #sToast {
      position: fixed; bottom: 1.5rem; right: 1.5rem; z-index: 9999;
      padding: .8rem 1.2rem; border-radius: 12px;
      font-family: 'DM Sans', sans-serif; font-size: .88rem; font-weight: 600;
      box-shadow: var(--shadow-md); transition: all .3s;
      opacity: 0; transform: translateY(20px); pointer-events: none;
    }
    #sToast.show { opacity: 1; transform: translateY(0); }

    /* ── RESPONSIVE ── */
    @media(max-width: 768px) {
      .login-card { flex-direction: column; border-radius: 18px; }
      .left-panel { width: 100%; padding: 2rem 1.5rem; }
      .right-panel { padding: 2rem 1.5rem; }
      .feature-list { display: none; }
      body { padding: 1rem; }
    }
  </style>
</head>
<body>

<%
  String error   = request.getParameter("error");
  String success = request.getParameter("success");
%>

<div class="login-card">

  <!-- ── LEFT PANEL ── -->
  <div class="left-panel">
    <div class="blob1"></div><div class="blob2"></div>

    <div class="brand-mark">
      <i class="bi bi-bag-heart-fill"></i>
      SIBS<span class="dot">•</span>STORE
    </div>

    <div class="left-main">
      <div class="left-icon"><i class="bi bi-person-check-fill" style="color:#bae6fd;"></i></div>
      <h2 class="left-title">Welcome <span class="hl">Back</span></h2>
      <p class="left-sub">Sign in to shop thousands of products, track your orders, and enjoy a seamless experience.</p>
      <ul class="feature-list">
        <li><span class="fi"><i class="bi bi-bag-check-fill"></i></span> Real-time order tracking</li>
        <li><span class="fi"><i class="bi bi-wallet2"></i></span> Wallet &amp; refund history</li>
        <li><span class="fi"><i class="bi bi-shield-lock-fill"></i></span> Secured payments</li>
        <li><span class="fi"><i class="bi bi-bell-fill"></i></span> Personalised offers &amp; alerts</li>
        <li><span class="fi"><i class="bi bi-headset"></i></span> 24/7 customer support</li>
      </ul>
    </div>

    <div style="font-size:.72rem;color:rgba(255,255,255,.3);position:relative;z-index:1;">© 2026 SIBS Store. All rights reserved.</div>
  </div>

  <!-- ── RIGHT PANEL ── -->
  <div class="right-panel">
    <div class="panel-eyebrow"><i class="bi bi-person-circle"></i> Customer Portal</div>
    <h1 class="panel-title">Sign In</h1>
    <p class="panel-sub">Choose your preferred login method below</p>

    <!-- Alerts -->
    <% if ("invalid".equals(error)) { %>
      <div class="alert-bar err"><i class="bi bi-exclamation-circle-fill"></i> Invalid credentials. Please try again.</div>
    <% } else if ("registered".equals(success)) { %>
      <div class="alert-bar ok"><i class="bi bi-check-circle-fill"></i> Registration successful! Please sign in.</div>
    <% } else if ("reset".equals(success)) { %>
      <div class="alert-bar ok"><i class="bi bi-check-circle-fill"></i> Password reset successful! Login with your new password.</div>
    <% } %>

    <!-- Tab Switcher -->
    <div class="tab-row">
      <button class="tab-btn active" id="tabEmail" onclick="switchTab('email')">
        <i class="bi bi-envelope-fill"></i> Email &amp; Password
      </button>
      <button class="tab-btn" id="tabMobile" onclick="switchTab('mobile')">
        <i class="bi bi-phone-fill"></i> Mobile OTP
      </button>
    </div>

    <!-- ── EMAIL LOGIN ── -->
    <div id="emailLoginForm">
      <form action="CustLogin" method="post" novalidate>
        <input type="hidden" name="loginType" value="email">
        <div class="field-group">
          <label class="field-label">Email Address <span class="req">*</span></label>
          <input type="email" name="email" class="form-control" placeholder="you@example.com" required
                 value="<%= request.getParameter("email") != null ? request.getParameter("email") : "" %>">
        </div>
        <div class="field-group">
          <div class="split-row">
            <label class="field-label" style="margin-bottom:0;">Password <span class="req">*</span></label>
            <button type="button" class="forgot-btn" data-bs-toggle="modal" data-bs-target="#fpModal">Forgot password?</button>
          </div>
          <div class="field-wrap" style="margin-top:.4rem;">
            <input type="password" id="emailPwd" name="password" class="form-control has-icon" placeholder="Enter your password" required>
            <button type="button" class="field-icon" onclick="togglePwd('emailPwd',this)"><i class="bi bi-eye"></i></button>
          </div>
        </div>
        <div class="remember-row">
          <input type="checkbox" id="rememberMe" name="rememberMe">
          <label for="rememberMe">Remember me for 30 days</label>
        </div>
        <button type="submit" class="btn-primary-full">
          <i class="bi bi-box-arrow-in-right"></i> Sign In
        </button>
      </form>

      <div class="or-row">or continue with</div>

      <a href="GoogleLoginServlet" class="btn-google">
        <svg class="google-icon" viewBox="0 0 24 24">
          <path fill="#4285F4" d="M23.745 12.27c0-.79-.07-1.54-.19-2.27h-11.3v4.51h6.47c-.29 1.48-1.14 2.73-2.4 3.58v3h3.86c2.26-2.09 3.56-5.17 3.56-8.82z"/>
          <path fill="#34A853" d="M12.255 24c3.24 0 5.95-1.08 7.93-2.91l-3.86-3c-1.08.72-2.45 1.16-4.07 1.16-3.13 0-5.78-2.11-6.73-4.96h-3.98v3.09C3.515 21.3 7.615 24 12.255 24z"/>
          <path fill="#FBBC05" d="M5.525 14.29c-.25-.72-.38-1.49-.38-2.29s.14-1.57.38-2.29V6.62h-3.98a11.86 11.86 0 000 10.76l3.98-3.09z"/>
          <path fill="#EA4335" d="M12.255 4.75c1.77 0 3.35.61 4.6 1.8l3.42-3.42C18.205 1.19 15.495 0 12.255 0c-4.64 0-8.74 2.7-10.71 6.62l3.98 3.09c.95-2.85 3.6-4.96 6.73-4.96z"/>
        </svg>
        Continue with Google
      </a>
    </div>

    <!-- ── MOBILE OTP LOGIN ── -->
    <div id="mobileLoginForm" style="display:none;">
      <div id="mobStep1">
        <div class="field-group">
          <label class="field-label">Mobile Number <span class="req">*</span></label>
          <div class="phone-row">
            <select class="country-select" id="mobileCode">
              <option value="+91">🇮🇳 +91</option>
              <option value="+1">🇺🇸 +1</option>
              <option value="+44">🇬🇧 +44</option>
              <option value="+61">🇦🇺 +61</option>
            </select>
            <input type="text" id="mobileNumber" class="form-control" placeholder="10-digit number" maxlength="12">
          </div>
        </div>
        <button type="button" class="btn-primary-full" onclick="sendOTP()">
          <i class="bi bi-send-fill"></i> Send OTP
        </button>
      </div>
      <div id="mobStep2" style="display:none;">
        <p class="otp-note">Enter the 6-digit OTP sent to <strong id="displayMobile"></strong></p>
        <div class="otp-row">
          <input class="otp-box" type="text" maxlength="1" id="otp1" oninput="otpNext(this,'otp2')" inputmode="numeric">
          <input class="otp-box" type="text" maxlength="1" id="otp2" oninput="otpNext(this,'otp3')" onkeydown="otpBack(this,'otp1')" inputmode="numeric">
          <input class="otp-box" type="text" maxlength="1" id="otp3" oninput="otpNext(this,'otp4')" onkeydown="otpBack(this,'otp2')" inputmode="numeric">
          <input class="otp-box" type="text" maxlength="1" id="otp4" oninput="otpNext(this,'otp5')" onkeydown="otpBack(this,'otp3')" inputmode="numeric">
          <input class="otp-box" type="text" maxlength="1" id="otp5" oninput="otpNext(this,'otp6')" onkeydown="otpBack(this,'otp4')" inputmode="numeric">
          <input class="otp-box" type="text" maxlength="1" id="otp6" onkeydown="otpBack(this,'otp5')" inputmode="numeric">
        </div>
        <form action="CustOTPVerify" method="post" id="otpForm">
          <input type="hidden" name="loginType" value="mobile">
          <input type="hidden" name="mobile" id="hiddenMobile">
          <input type="hidden" name="otp" id="hiddenOTP">
          <button type="button" class="btn-primary-full" onclick="verifyOTP()">
            <i class="bi bi-shield-check"></i> Verify &amp; Sign In
          </button>
        </form>
        <div class="resend-row">
          Didn't receive it? <a href="#" onclick="resendOTP()">Resend OTP</a>
          &nbsp;·&nbsp; <a href="#" onclick="backToMobile()">Change number</a>
        </div>
      </div>
    </div>

    <div class="register-row">
      New customer? <a href="CustomerRegistration.jsp">Create an account →</a>
    </div>
  </div><!-- /right-panel -->

</div><!-- /login-card -->

<!-- ════ FORGOT PASSWORD MODAL ════ -->
<div class="modal fade" id="fpModal" tabindex="-1" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered" style="max-width:460px;">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title"><i class="bi bi-key-fill me-2"></i>Reset Your Password</h5>
        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body">

        <div class="step-track">
          <div class="step-dot active" id="fpDot1">1</div>
          <div class="step-line" id="fpLine1"></div>
          <div class="step-dot" id="fpDot2">2</div>
          <div class="step-line" id="fpLine2"></div>
          <div class="step-dot" id="fpDot3">3</div>
        </div>
        <div class="step-label"><span>Identify</span><span>Verify OTP</span><span>New Password</span></div>

        <!-- Step 1 -->
        <div class="fp-step active" id="fpStep1">
          <p class="fp-hint">Enter your registered email or mobile number to receive a reset OTP.</p>
          <div class="tab-row" style="margin-bottom:1rem;">
            <button class="tab-btn active" id="fpTabEmail" onclick="fpSwitchMethod('email')"><i class="bi bi-envelope-fill"></i> Email</button>
            <button class="tab-btn" id="fpTabMobile" onclick="fpSwitchMethod('mobile')"><i class="bi bi-phone-fill"></i> Mobile</button>
          </div>
          <div id="fpEmailInput">
            <div class="field-group">
              <label class="field-label">Email Address <span class="req">*</span></label>
              <input type="email" id="fpEmail" class="form-control" placeholder="your@email.com">
            </div>
          </div>
          <div id="fpMobileInput" style="display:none;">
            <div class="field-group">
              <label class="field-label">Mobile Number <span class="req">*</span></label>
              <div class="phone-row">
                <select class="country-select" id="fpMobileCode">
                  <option value="+91">🇮🇳 +91</option>
                  <option value="+1">🇺🇸 +1</option>
                  <option value="+44">🇬🇧 +44</option>
                </select>
                <input type="text" id="fpMobile" class="form-control" placeholder="10-digit number" maxlength="12">
              </div>
            </div>
          </div>
          <div class="modal-actions" style="justify-content:flex-end;">
            <button class="btn-modal-pri" onclick="fpSendOTP()"><i class="bi bi-send-fill"></i> Send OTP</button>
          </div>
        </div>

        <!-- Step 2 -->
        <div class="fp-step" id="fpStep2">
          <p class="fp-hint" style="text-align:center;" id="fpOtpHint">Enter the 6-digit OTP sent to your contact.</p>
          <div class="otp-row">
            <input class="otp-box" type="text" maxlength="1" id="fo1" oninput="otpNext(this,'fo2')" inputmode="numeric">
            <input class="otp-box" type="text" maxlength="1" id="fo2" oninput="otpNext(this,'fo3')" onkeydown="otpBack(this,'fo1')" inputmode="numeric">
            <input class="otp-box" type="text" maxlength="1" id="fo3" oninput="otpNext(this,'fo4')" onkeydown="otpBack(this,'fo2')" inputmode="numeric">
            <input class="otp-box" type="text" maxlength="1" id="fo4" oninput="otpNext(this,'fo5')" onkeydown="otpBack(this,'fo3')" inputmode="numeric">
            <input class="otp-box" type="text" maxlength="1" id="fo5" oninput="otpNext(this,'fo6')" onkeydown="otpBack(this,'fo4')" inputmode="numeric">
            <input class="otp-box" type="text" maxlength="1" id="fo6" onkeydown="otpBack(this,'fo5')" inputmode="numeric">
          </div>
          <div class="modal-actions">
            <button class="btn-modal-sec" onclick="fpGoStep(1)"><i class="bi bi-arrow-left"></i> Back</button>
            <button class="btn-modal-pri" onclick="fpVerifyOTP()"><i class="bi bi-shield-check"></i> Verify OTP</button>
          </div>
        </div>

        <!-- Step 3 -->
        <div class="fp-step" id="fpStep3">
          <form action="ForgotPasswordServlet" method="post" id="fpForm">
            <input type="hidden" name="contact" id="fpHiddenContact">
            <input type="hidden" name="method"  id="fpHiddenMethod">
            <input type="hidden" name="otp"     id="fpHiddenOTP">
            <div class="field-group">
              <label class="field-label">New Password <span class="req">*</span></label>
              <div class="field-wrap">
                <input type="password" id="fpNewPwd" name="newPassword" class="form-control has-icon" placeholder="Min 8 chars, number &amp; symbol" required>
                <button type="button" class="field-icon" onclick="togglePwd('fpNewPwd',this)"><i class="bi bi-eye"></i></button>
              </div>
              <div class="strength-track"><div class="strength-bar" id="fpStrBar"></div></div>
              <div class="strength-text" id="fpStrLabel"></div>
            </div>
            <div class="field-group">
              <label class="field-label">Confirm Password <span class="req">*</span></label>
              <div class="field-wrap">
                <input type="password" id="fpConfPwd" name="confirmPassword" class="form-control has-icon" placeholder="Re-enter new password" required>
                <button type="button" class="field-icon" onclick="togglePwd('fpConfPwd',this)"><i class="bi bi-eye"></i></button>
              </div>
            </div>
            <div class="modal-actions">
              <button type="button" class="btn-modal-sec" onclick="fpGoStep(2)"><i class="bi bi-arrow-left"></i> Back</button>
              <button type="submit" class="btn-modal-pri" onclick="return fpCheckPwd()"><i class="bi bi-check-circle-fill"></i> Reset Password</button>
            </div>
          </form>
        </div>

      </div>
    </div>
  </div>
</div>

<div id="sToast"></div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
<script>
  function switchTab(t){
    document.getElementById('emailLoginForm').style.display  = t==='email'  ? 'block':'none';
    document.getElementById('mobileLoginForm').style.display = t==='mobile' ? 'block':'none';
    document.getElementById('tabEmail').classList.toggle('active',  t==='email');
    document.getElementById('tabMobile').classList.toggle('active', t==='mobile');
  }
  function togglePwd(id,btn){
    const f=document.getElementById(id); const show=f.type==='text';
    f.type=show?'password':'text';
    btn.querySelector('i').className=show?'bi bi-eye':'bi bi-eye-slash';
  }
  function otpNext(el,nid){ el.value=el.value.replace(/\D/,''); if(el.value.length===1){const n=document.getElementById(nid);if(n)n.focus();} }
  function otpBack(el,pid){ if(event.key==='Backspace'&&el.value===''){const p=document.getElementById(pid);if(p){p.value='';p.focus();}} }

  function sendOTP(){
    const mobile=document.getElementById('mobileNumber').value.replace(/\s/g,'');
    if(!/^\d{10}$/.test(mobile)){showToast('Enter a valid 10-digit number.','err');return;}
    const code=document.getElementById('mobileCode').value;
    document.getElementById('displayMobile').textContent=code+' '+mobile;
    document.getElementById('hiddenMobile').value=code+mobile;
    fetch('SendOTPServlet',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:'mobile='+encodeURIComponent(code+mobile)})
      .then(()=>{ document.getElementById('mobStep1').style.display='none'; document.getElementById('mobStep2').style.display='block'; document.getElementById('otp1').focus(); })
      .catch(()=>showToast('Failed to send OTP. Try again.','err'));
  }
  function verifyOTP(){
    const otp=['otp1','otp2','otp3','otp4','otp5','otp6'].map(id=>document.getElementById(id).value).join('');
    if(otp.length<6){showToast('Enter the complete 6-digit OTP.','err');return;}
    document.getElementById('hiddenOTP').value=otp;
    document.getElementById('otpForm').submit();
  }
  function resendOTP(){ sendOTP(); }
  function backToMobile(){ document.getElementById('mobStep1').style.display='block'; document.getElementById('mobStep2').style.display='none'; }

  var fpMethod='email';
  function fpSwitchMethod(m){
    fpMethod=m;
    document.getElementById('fpEmailInput').style.display  = m==='email'  ? 'block':'none';
    document.getElementById('fpMobileInput').style.display = m==='mobile' ? 'block':'none';
    document.getElementById('fpTabEmail').classList.toggle('active',m==='email');
    document.getElementById('fpTabMobile').classList.toggle('active',m==='mobile');
  }
  function fpGoStep(n){
    [1,2,3].forEach(i=>{
      document.getElementById('fpStep'+i).classList.toggle('active',i===n);
      const d=document.getElementById('fpDot'+i);
      d.className='step-dot'+(i<n?' done':i===n?' active':'');
    });
    const l1=document.getElementById('fpLine1'),l2=document.getElementById('fpLine2');
    if(l1)l1.className='step-line'+(n>1?' done':'');
    if(l2)l2.className='step-line'+(n>2?' done':'');
  }
  function fpSendOTP(){
    let contact,body;
    if(fpMethod==='email'){
      contact=document.getElementById('fpEmail').value.trim();
      if(!contact||!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(contact)){showToast('Enter a valid email address.','err');return;}
      body='action=sendOTP&method=email&contact='+encodeURIComponent(contact);
    } else {
      const mob=document.getElementById('fpMobile').value.replace(/\s/g,'');
      if(!/^\d{10}$/.test(mob)){showToast('Enter a valid 10-digit number.','err');return;}
      contact=document.getElementById('fpMobileCode').value+mob;
      body='action=sendOTP&method=mobile&contact='+encodeURIComponent(contact);
    }
    document.getElementById('fpHiddenContact').value=contact;
    document.getElementById('fpHiddenMethod').value=fpMethod;
    document.getElementById('fpOtpHint').textContent='Enter the 6-digit OTP sent to '+contact;
    fetch('ForgotPasswordServlet',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:body})
      .then(r=>r.text())
      .then(res=>{ if(res.trim()==='ok') fpGoStep(2); else showToast('No account found.','err'); })
      .catch(()=>showToast('Failed. Please try again.','err'));
  }
  function fpVerifyOTP(){
    const otp=['fo1','fo2','fo3','fo4','fo5','fo6'].map(id=>document.getElementById(id).value).join('');
    if(otp.length<6){showToast('Enter the complete 6-digit OTP.','err');return;}
    const contact=document.getElementById('fpHiddenContact').value;
    const method=document.getElementById('fpHiddenMethod').value;
    fetch('ForgotPasswordServlet',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},
      body:'action=verifyOTP&contact='+encodeURIComponent(contact)+'&method='+method+'&otp='+encodeURIComponent(otp)})
      .then(r=>r.text())
      .then(res=>{ if(res.trim()==='ok'){document.getElementById('fpHiddenOTP').value=otp;fpGoStep(3);}
                   else showToast('Invalid OTP. Try again.','err'); })
      .catch(()=>showToast('Verification failed. Retry.','err'));
  }
  function fpCheckPwd(){
    const p=document.getElementById('fpNewPwd').value, c=document.getElementById('fpConfPwd').value;
    if(p.length<8){showToast('Password must be at least 8 characters.','err');return false;}
    if(p!==c){showToast('Passwords do not match.','err');return false;}
    return true;
  }
  document.addEventListener('DOMContentLoaded',()=>{
    const pwdIn=document.getElementById('fpNewPwd');
    if(pwdIn) pwdIn.addEventListener('input',function(){
      const v=this.value; let s=0;
      if(v.length>=8)s++; if(/[A-Z]/.test(v))s++; if(/[0-9]/.test(v))s++; if(/[^A-Za-z0-9]/.test(v))s++;
      const bar=document.getElementById('fpStrBar'),lbl=document.getElementById('fpStrLabel');
      const c=['#ef4444','#f97316','#eab308','#10b981'],l=['Weak','Fair','Good','Strong'];
      bar.style.width=(s*25)+'%'; bar.style.background=c[s-1]||'#e2e8f0';
      lbl.textContent=s>0?l[s-1]:''; lbl.style.color=c[s-1]||'var(--muted)';
    });
  });
  function showToast(msg,type){
    const t=document.getElementById('sToast');
    t.textContent=msg;
    t.style.background=type==='err'?'#fef2f2':'#f0fdf4';
    t.style.color=type==='err'?'#b91c1c':'#15803d';
    t.style.border=type==='err'?'1px solid #fca5a5':'1px solid #86efac';
    t.classList.add('show');
    setTimeout(()=>t.classList.remove('show'),3200);
  }
</script>
</body>
</html>