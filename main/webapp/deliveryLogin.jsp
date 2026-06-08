<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%!
    /* BUG FIX: Escape HTML special characters to prevent XSS.
       errorMsg and registrationMsg were previously output raw with,
       allowing injected HTML/JS from server-side error messages or query params. */
    private static String esc(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#x27;");
    }
%>
<%
    /* ── Read server-set attributes ──────────────────────────────────────── */
    String errorMsg      = (String) request.getAttribute("errorMsg");
    String errorType     = (String) request.getAttribute("errorType");   // PENDING | REJECTED | NOT_FOUND | WRONG_PASSWORD | SERVER_ERROR | EMPTY
    String registrationMsg = (String) request.getAttribute("registrationMsg"); // after successful register redirect (servlet flow)

    // BUG FIX: DeliveryRegisterServlet redirects to deliveryLogin.jsp?registered=1 directly
    // (bypasses the servlet), so the servlet never sets the registrationMsg attribute.
    // Read the query param here so the success banner always shows.
    if (registrationMsg == null || registrationMsg.isBlank()) {
        if ("1".equals(request.getParameter("registered"))) {
            registrationMsg = "Registration submitted successfully! Your application is now pending admin review. "
                    + "You will be able to log in once your account is approved.";
        }
    }

    // Also accept ?error= query param (from other redirects)
    if (errorMsg == null && request.getParameter("error") != null) {
        errorMsg  = request.getParameter("error");
        errorType = "GENERIC";
    }

    boolean isPending      = "PENDING".equals(errorType);
    boolean isRejected     = "REJECTED".equals(errorType);
    boolean isNotFound     = "NOT_FOUND".equals(errorType);
    boolean isWrongPwd     = "WRONG_PASSWORD".equals(errorType);
    boolean isServerError  = "SERVER_ERROR".equals(errorType);
    boolean hasError       = errorMsg != null && !errorMsg.isBlank();
    boolean hasRegMsg      = registrationMsg != null && !registrationMsg.isBlank();
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Delivery Portal — Smart Inventory</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
  <link href="https://fonts.googleapis.com/css2?family=DM+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700&family=Fraunces:ital,wght@0,300;0,600;1,400;1,600&display=swap" rel="stylesheet">

  <style>
    /* ══════════════════════════════════════════════
       ROOT TOKENS
    ══════════════════════════════════════════════ */
    :root {
      --teal:        #0ea5e9;
      --teal-dark:   #0369a1;
      --teal-deep:   #082f49;
      --teal-glow:   rgba(14,165,233,0.18);
      --ink:         #0c1117;
      --ink-soft:    #64748b;
      --border:      #e2e8f0;
      --white:       #ffffff;
      --red:         #dc2626;
      --amber:       #d97706;
      --green:       #16a34a;
      --shadow-lg:   0 20px 60px rgba(8,47,73,0.25);
      --radius:      20px;
      --radius-sm:   12px;
    }

    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

    /* ══════════════════════════════════════════════
       BODY / BACKGROUND
    ══════════════════════════════════════════════ */
    body {
      font-family: 'DM Sans', sans-serif;
      background: linear-gradient(145deg, #082f49 0%, #0c4a6e 40%, #0369a1 100%);
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 1rem;
      position: relative;
      overflow-x: hidden;
    }

    .bg-circle {
      position: fixed; border-radius: 50%; pointer-events: none;
      animation: pulse 6s ease-in-out infinite;
    }
    .bg-circle-1 {
      width: 400px; height: 400px;
      top: -150px; right: -100px;
      background: radial-gradient(circle, rgba(14,165,233,0.15) 0%, transparent 70%);
    }
    .bg-circle-2 {
      width: 300px; height: 300px;
      bottom: -80px; left: -80px;
      background: radial-gradient(circle, rgba(255,255,255,0.05) 0%, transparent 70%);
      animation-delay: 3s;
    }
    .bg-dots {
      position: fixed; top: 0; left: 0; width: 100%; height: 100%;
      background-image: radial-gradient(circle, rgba(255,255,255,0.04) 1px, transparent 1px);
      background-size: 36px 36px;
      pointer-events: none;
    }

    @keyframes pulse {
      0%, 100% { transform: scale(1); opacity: 1; }
      50%       { transform: scale(1.1); opacity: 0.7; }
    }
    @keyframes slideUp {
      from { opacity: 0; transform: translateY(32px); }
      to   { opacity: 1; transform: translateY(0); }
    }
    @keyframes float {
      0%, 100% { transform: translateY(0); }
      50%       { transform: translateY(-6px); }
    }
    @keyframes blink {
      0%, 100% { opacity: 1; } 50% { opacity: 0.3; }
    }

    /* ══════════════════════════════════════════════
       CARD
    ══════════════════════════════════════════════ */
    .login-card {
      width: 100%;
      max-width: 440px;
      background: var(--white);
      border-radius: var(--radius);
      box-shadow: var(--shadow-lg);
      overflow: hidden;
      position: relative; z-index: 1;
      animation: slideUp 0.7s cubic-bezier(0.16,1,0.3,1) both;
    }

    /* ── HEADER ── */
    .card-header-panel {
      background: linear-gradient(135deg, #082f49 0%, #0c4a6e 100%);
      padding: 2.2rem 2rem 1.8rem;
      text-align: center;
      position: relative; overflow: hidden;
    }
    .card-header-panel::before {
      content: '';
      position: absolute; top: -40px; right: -40px;
      width: 150px; height: 150px; border-radius: 50%;
      background: rgba(14,165,233,0.15);
    }

    .portal-icon-ring {
      width: 72px; height: 72px; border-radius: 50%;
      background: rgba(14,165,233,0.15);
      border: 2px solid rgba(14,165,233,0.35);
      display: flex; align-items: center; justify-content: center;
      margin: 0 auto 1rem;
      position: relative; z-index: 1;
      animation: float 3s ease-in-out infinite;
    }
    .portal-icon-ring i { font-size: 1.8rem; color: var(--teal); }

    .portal-title {
      font-family: 'Fraunces', serif;
      font-size: 1.4rem; font-weight: 600; color: #fff;
      margin-bottom: 0.25rem; position: relative; z-index: 1;
    }
    .portal-sub {
      font-size: 0.82rem; color: rgba(255,255,255,0.55);
      position: relative; z-index: 1;
    }
    .status-bar {
      display: flex; align-items: center; justify-content: center; gap: 0.4rem;
      margin-top: 0.9rem; position: relative; z-index: 1;
    }
    .status-dot {
      width: 7px; height: 7px; border-radius: 50%;
      background: #22c55e; animation: blink 2s ease-in-out infinite;
    }
    .status-text { font-size: 0.72rem; color: rgba(255,255,255,0.45); }

    /* ── BODY ── */
    .card-body-panel { padding: 1.8rem 2rem 2rem; }

    /* ══════════════════════════════════════════════
       ALERT BANNERS — each type has distinct styling
    ══════════════════════════════════════════════ */
    .alert-bar {
      border-radius: var(--radius-sm);
      padding: 0.8rem 1rem;
      font-size: 0.84rem;
      margin-bottom: 1.2rem;
      font-weight: 500;
      line-height: 1.5;
    }
    .alert-bar .alert-icon {
      font-size: 1.1rem;
      flex-shrink: 0;
      margin-top: 1px;
    }
    .alert-bar .alert-body { flex: 1; }
    .alert-bar .alert-title {
      font-weight: 700;
      display: block;
      margin-bottom: 0.2rem;
    }
    .alert-bar .alert-detail {
      font-size: 0.8rem;
      opacity: 0.85;
      display: block;
      line-height: 1.45;
    }

    /* Generic error (wrong password / empty fields) */
    .alert-err {
      background: #fff1f1;
      border: 1px solid #fca5a5;
      color: var(--red);
      border-left: 3px solid var(--red);
      display: flex; align-items: flex-start; gap: 0.6rem;
    }

    /* Pending review */
    .alert-pending {
      background: #fffbeb;
      border: 1px solid #fcd34d;
      color: #92400e;
      border-left: 3px solid var(--amber);
      display: flex; align-items: flex-start; gap: 0.6rem;
    }

    /* Rejected */
    .alert-rejected {
      background: #fff1f1;
      border: 1px solid #fca5a5;
      color: #7f1d1d;
      border-left: 3px solid #dc2626;
      display: flex; align-items: flex-start; gap: 0.6rem;
    }

    /* Not found / unregistered */
    .alert-notfound {
      background: #f0f9ff;
      border: 1px solid #bae6fd;
      color: #0c4a6e;
      border-left: 3px solid var(--teal);
      display: flex; align-items: flex-start; gap: 0.6rem;
    }

    /* Registration success */
    .alert-success {
      background: #f0fdf4;
      border: 1px solid #86efac;
      color: #14532d;
      border-left: 3px solid var(--green);
      display: flex; align-items: flex-start; gap: 0.6rem;
    }

    /* ── CTA Button inside alert (Register Now / Contact Support) ── */
    .alert-cta {
      display: inline-flex; align-items: center; gap: 0.35rem;
      margin-top: 0.55rem;
      padding: 0.38rem 0.9rem;
      border-radius: 8px;
      font-size: 0.78rem; font-weight: 700;
      text-decoration: none;
      transition: all 0.2s;
      border: none; cursor: pointer;
    }
    .alert-cta.cta-teal {
      background: var(--teal); color: #fff;
    }
    .alert-cta.cta-teal:hover { background: var(--teal-dark); color: #fff; }
    .alert-cta.cta-outline {
      background: transparent;
      border: 1.5px solid currentColor;
      color: inherit;
    }
    .alert-cta.cta-outline:hover { background: rgba(0,0,0,0.05); }

    /* ══════════════════════════════════════════════
       FORM FIELDS
    ══════════════════════════════════════════════ */
    .field-group { margin-bottom: 1rem; }
    .field-label {
      font-size: 0.75rem; font-weight: 600;
      color: var(--ink); display: block; margin-bottom: 0.4rem;
    }
    .field-wrap { position: relative; }

    .field-icon-left {
      position: absolute; left: 0.9rem; top: 50%;
      transform: translateY(-50%);
      color: var(--ink-soft); font-size: 1rem; pointer-events: none;
    }
    .field-icon-right {
      position: absolute; right: 0.9rem; top: 50%;
      transform: translateY(-50%);
      background: none; border: none; cursor: pointer;
      color: var(--ink-soft); font-size: 1rem; padding: 0;
      transition: color 0.2s;
    }
    .field-icon-right:hover { color: var(--ink); }

    .form-control {
      width: 100%;
      border: 1.5px solid var(--border);
      border-radius: var(--radius-sm);
      padding: 0.72rem 1rem 0.72rem 2.6rem;
      font-family: 'DM Sans', sans-serif; font-size: 0.92rem;
      color: var(--ink); background: #f8fafc;
      transition: border-color 0.2s, box-shadow 0.2s, background 0.2s;
      outline: none;
    }
    .form-control:focus {
      border-color: var(--teal);
      box-shadow: 0 0 0 3px rgba(14,165,233,0.12);
      background: var(--white);
    }
    .form-control::placeholder { color: #b0bec5; }
    .form-control.has-right    { padding-right: 2.8rem; }

    /* ── SUBMIT BUTTON ── */
    .btn-signin {
      width: 100%; padding: 0.85rem;
      background: linear-gradient(135deg, var(--teal) 0%, var(--teal-dark) 100%);
      color: #fff; border: none;
      border-radius: var(--radius-sm); cursor: pointer;
      font-family: 'DM Sans', sans-serif; font-size: 0.92rem; font-weight: 700;
      letter-spacing: 0.3px;
      display: flex; align-items: center; justify-content: center; gap: 0.5rem;
      transition: all 0.2s; margin-top: 0.5rem;
      box-shadow: 0 4px 16px rgba(14,165,233,0.3);
      -webkit-tap-highlight-color: transparent;
    }
    .btn-signin:hover    { opacity: 0.92; transform: translateY(-1px); box-shadow: 0 8px 24px rgba(14,165,233,0.4); }
    .btn-signin:active   { transform: translateY(0); }
    .btn-signin:disabled { opacity: 0.6; cursor: not-allowed; transform: none; }

    /* ── REGISTER LINK ROW ── */
    .register-row {
      text-align: center;
      margin-top: 1.2rem;
      font-size: 0.82rem;
      color: var(--ink-soft);
    }
    .register-row a {
      color: var(--teal);
      font-weight: 600;
      text-decoration: none;
    }
    .register-row a:hover { text-decoration: underline; }

    /* ── FOOTER ── */
    .card-footer-panel {
      padding: 0.9rem 2rem;
      background: #f8fafc;
      border-top: 1px solid var(--border);
      display: flex; align-items: center; justify-content: center;
      gap: 0.5rem; flex-wrap: wrap;
    }
    .footer-badge {
      display: flex; align-items: center; gap: 0.3rem;
      font-size: 0.71rem; color: var(--ink-soft);
    }
    .footer-badge i { color: var(--teal); }

    /* ══════════════════════════════════════════════
       MOBILE RESPONSIVE
    ══════════════════════════════════════════════ */
    @media (max-width: 480px) {
      body { padding: 0; align-items: flex-end; }

      .bg-circle-1 { width: 250px; height: 250px; top: -80px; right: -60px; }
      .bg-circle-2 { width: 180px; height: 180px; }

      /* Full-screen card on mobile — slides up from bottom */
      .login-card {
        max-width: 100%;
        border-radius: var(--radius) var(--radius) 0 0;
        box-shadow: 0 -8px 40px rgba(8,47,73,0.3);
        min-height: 92vh;
        display: flex; flex-direction: column;
      }

      /* Compact header on mobile */
      .card-header-panel { padding: 1.6rem 1.4rem 1.4rem; }
      .portal-icon-ring  { width: 60px; height: 60px; margin-bottom: 0.75rem; }
      .portal-icon-ring i { font-size: 1.5rem; }
      .portal-title       { font-size: 1.2rem; }
      .portal-sub         { font-size: 0.79rem; }
      .status-bar         { margin-top: 0.7rem; }

      /* Body fills remaining space */
      .card-body-panel {
        padding: 1.4rem 1.4rem 1.6rem;
        flex: 1;
        display: flex; flex-direction: column; justify-content: flex-start;
      }

      .alert-bar { font-size: 0.81rem; padding: 0.7rem 0.85rem; }
      .alert-cta { font-size: 0.75rem; }

      .form-control { font-size: 1rem; padding: 0.8rem 1rem 0.8rem 2.5rem; }
      .btn-signin   { font-size: 1rem; padding: 0.9rem; }

      .register-row { font-size: 0.85rem; margin-top: 1rem; }

      .card-footer-panel { padding: 0.75rem 1.4rem; }
      .footer-badge       { font-size: 0.68rem; }
    }

    /* Extra-small phones (SE, Galaxy A series) */
    @media (max-width: 360px) {
      .card-header-panel  { padding: 1.2rem 1.2rem 1rem; }
      .portal-icon-ring   { width: 52px; height: 52px; }
      .portal-icon-ring i { font-size: 1.3rem; }
      .portal-title        { font-size: 1.1rem; }
      .card-body-panel     { padding: 1.1rem 1.2rem 1.4rem; }
      .form-control        { font-size: 0.96rem; }
    }

    /* Landscape mobile */
    @media (max-width: 768px) and (orientation: landscape) {
      body { align-items: center; padding: 0.75rem; }
      .login-card {
        max-width: 560px;
        border-radius: var(--radius);
        min-height: unset;
        flex-direction: row;
        align-items: stretch;
      }
      .card-header-panel {
        width: 220px; flex-shrink: 0;
        display: flex; flex-direction: column; justify-content: center;
        padding: 1.4rem 1.2rem;
        border-radius: var(--radius) 0 0 var(--radius);
      }
      .card-body-panel   { flex: 1; padding: 1.2rem 1.4rem; overflow-y: auto; }
      .card-footer-panel { display: none; } /* hide footer in landscape to save space */
    }
  </style>
</head>
<body>

  <div class="bg-dots"></div>
  <div class="bg-circle bg-circle-1"></div>
  <div class="bg-circle bg-circle-2"></div>

  <div class="login-card">

    <!-- ── HEADER ─────────────────────────────────────── -->
    <div class="card-header-panel">
      <div class="portal-icon-ring">
        <i class="bi bi-truck-front-fill"></i>
      </div>
      <h1 class="portal-title">Delivery Portal</h1>
      <p class="portal-sub">Smart Inventory Partner Access</p>
      <div class="status-bar">
        <div class="status-dot"></div>
        <span class="status-text">Secure encrypted connection</span>
      </div>
    </div>

    <!-- ── BODY ──────────────────────────────────────── -->
    <div class="card-body-panel">

      <%-- ══════════════════════════════════════════════
           BANNERS — only one shows at a time
      ══════════════════════════════════════════════ --%>

      <%-- Registration submitted successfully --%>
      <% if (hasRegMsg) { %>
      <div class="alert-bar alert-success">
        <i class="bi bi-check-circle-fill alert-icon"></i>
        <div class="alert-body">
          <span class="alert-title">Registration Submitted!</span>
          <span class="alert-detail"><%= esc(registrationMsg) %></span>
        </div>
      </div>
      <% } %>

      <%-- Account PENDING admin review --%>
      <% if (isPending) { %>
      <div class="alert-bar alert-pending">
        <i class="bi bi-hourglass-split alert-icon"></i>
        <div class="alert-body">
          <span class="alert-title">Application Under Review</span>
          <span class="alert-detail"><%= esc(errorMsg) %></span>
          <a href="mailto:support@smartinventory.com" class="alert-cta cta-outline">
            <i class="bi bi-envelope"></i> Contact Support
          </a>
        </div>
      </div>
      <% } %>

      <%-- Account REJECTED by admin --%>
      <% if (isRejected) { %>
      <div class="alert-bar alert-rejected">
        <i class="bi bi-x-circle-fill alert-icon"></i>
        <div class="alert-body">
          <span class="alert-title">Application Rejected</span>
          <span class="alert-detail"><%= esc(errorMsg) %></span>
          <a href="<%= request.getContextPath() %>/deliveryRegister.jsp" class="alert-cta cta-teal" style="margin-top:0.55rem; display:inline-flex;">
            <i class="bi bi-person-plus-fill"></i> Apply Again
          </a>
        </div>
      </div>
      <% } %>

      <%-- Username NOT FOUND — prompt to register --%>
      <% if (isNotFound) { %>
      <div class="alert-bar alert-notfound">
        <i class="bi bi-person-x-fill alert-icon"></i>
        <div class="alert-body">
          <span class="alert-title">Account Not Found</span>
          <span class="alert-detail"><%= esc(errorMsg) %></span>
          <a href="<%= request.getContextPath() %>/deliveryRegister.jsp" class="alert-cta cta-teal" style="margin-top:0.55rem; display:inline-flex;">
            <i class="bi bi-person-plus-fill"></i> Register as Delivery Agent
          </a>
        </div>
      </div>
      <% } %>

      <%-- Wrong password or empty fields --%>
      <% if (isWrongPwd || "EMPTY".equals(errorType) || isServerError || ("GENERIC".equals(errorType) && hasError)) { %>
      <div class="alert-bar alert-err">
        <i class="bi bi-exclamation-circle-fill alert-icon"></i>
        <div class="alert-body">
          <span class="alert-title"><%= isServerError ? "Server Error" : "Login Failed" %></span>
          <span class="alert-detail"><%= esc(errorMsg) %></span>
        </div>
      </div>
      <% } %>

      <!-- ── FORM ── -->
      <form action="<%= request.getContextPath() %>/DeliveryLoginServlet" method="post" id="loginForm" novalidate>

        <div class="field-group">
          <label class="field-label" for="usernameField">Username / Employee ID</label>
          <div class="field-wrap">
            <span class="field-icon-left"><i class="bi bi-person-badge-fill"></i></span>
            <input type="text" id="usernameField" name="username" class="form-control"
                   placeholder="Enter your username"
                   autocomplete="username" autocapitalize="none"
                   value="<%= esc(request.getParameter("username")) %>"
                   required>
          </div>
        </div>

        <div class="field-group">
          <label class="field-label" for="delPwd">Password</label>
          <div class="field-wrap">
            <span class="field-icon-left"><i class="bi bi-lock-fill"></i></span>
            <input type="password" id="delPwd" name="password" class="form-control has-right"
                   placeholder="Enter your password"
                   autocomplete="current-password"
                   required>
            <button type="button" class="field-icon-right" onclick="togglePwd()" aria-label="Toggle password visibility">
              <i class="bi bi-eye" id="eyeIcon"></i>
            </button>
          </div>
        </div>

        <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:1.2rem;flex-wrap:wrap;gap:0.4rem;">
          <label style="display:flex;align-items:center;gap:0.4rem;font-size:0.82rem;color:var(--ink-soft);cursor:pointer;">
            <input type="checkbox" name="rememberMe" style="accent-color:var(--teal);width:15px;height:15px;"> Remember me
          </label>
          <a href="mailto:support@smartinventory.com" style="font-size:0.82rem;color:var(--teal);font-weight:600;text-decoration:none;">Need help?</a>
        </div>

        <button type="submit" class="btn-signin" id="signinBtn">
          <i class="bi bi-box-arrow-in-right"></i> Sign In to Portal
        </button>

      </form>

      <!-- Register link — always visible -->
      <div class="register-row">
        New delivery agent? &nbsp;
        <a href="<%= request.getContextPath() %>/deliveryRegister.jsp">
          <i class="bi bi-person-plus-fill"></i> Register here
        </a>
      </div>

    </div>

    <!-- ── FOOTER ─────────────────────────────────────── -->
    <div class="card-footer-panel">
      <span class="footer-badge"><i class="bi bi-shield-check-fill"></i> Secured access</span>
      <span style="color:var(--border);">·</span>
      <span class="footer-badge"><i class="bi bi-building"></i> Smart Inventory © 2025</span>
    </div>

  </div><%-- .login-card --%>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script>
  /* ── Toggle password visibility ────────────────────────────────────── */
  function togglePwd() {
    const f    = document.getElementById('delPwd');
    const icon = document.getElementById('eyeIcon');
    const show = f.type === 'text';
    f.type = show ? 'password' : 'text';
    icon.className = show ? 'bi bi-eye' : 'bi bi-eye-slash';
  }

  /* ── Show spinner on submit ────────────────────────────────────────── */
  document.getElementById('loginForm').addEventListener('submit', function () {
    const btn = document.getElementById('signinBtn');
    btn.disabled = true;
    btn.innerHTML = '<span class="spinner-border spinner-border-sm me-2" role="status"></span>Signing in…';
  });
</script>
</body>
</html>
