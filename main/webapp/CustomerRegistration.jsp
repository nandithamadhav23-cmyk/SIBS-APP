<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Create Account — Smart Inventory</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
  <link href="https://fonts.googleapis.com/css2?family=DM+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;1,400&family=Fraunces:ital,wght@0,300;0,600;1,400;1,600&display=swap" rel="stylesheet">
  <style>
    :root {
      --ink:        #0ea5e9;
      --ink-mid:    #2d2b3f;
      --ink-soft:  #0c1a2e;
      --gold:       #e8a838;
      --gold-light: #fdf3e0;
      --sky:        #f0f4ff;
      --border:     #e4e2ed;
      --white:      #ffffff;
      --green:      #16a34a;
      --red:        #dc2626;
      --shadow-sm:  0 2px 8px rgba(15,14,23,0.08);
      --shadow-md:  0 8px 32px rgba(15,14,23,0.12);
      --shadow-lg:  0 20px 60px rgba(15,14,23,0.18);
      --radius:     16px;
      --radius-sm:  10px;
    }

    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

    body {
      font-family: 'DM Sans', sans-serif;
      background: #f5f4fb;
      min-height: 100vh;
      display: flex;
      align-items: flex-start;
      justify-content: center;
      padding: 2rem 1.5rem;
      position: relative;
    }

    body::before {
      content: '';
      position: fixed; top: -120px; right: -120px;
      width: 500px; height: 500px; border-radius: 50%;
      background: radial-gradient(circle, rgba(232,168,56,0.12) 0%, transparent 70%);
      pointer-events: none;
    }
    body::after {
      content: '';
      position: fixed; bottom: -100px; left: -100px;
      width: 400px; height: 400px; border-radius: 50%;
      background: radial-gradient(circle, rgba(99,102,241,0.1) 0%, transparent 70%);
      pointer-events: none;
    }

    /* ── PAGE HEADER ── */
    .page-header {
      text-align: center;
      margin-bottom: 2rem;
      animation: slideUp 0.5s cubic-bezier(0.16,1,0.3,1) both;
    }
    .brand-badge {
      display: inline-flex; align-items: center; gap: 0.5rem;
      background: var(--ink); color: white;
      padding: 0.4rem 1rem; border-radius: 100px;
      font-size: 0.72rem; font-weight: 700; letter-spacing: 2px; text-transform: uppercase;
      margin-bottom: 1rem;
    }
    .page-title {
      font-family: 'Fraunces', serif;
      font-size: 2.2rem; font-weight: 600; color: var(--ink);
      line-height: 1.2; margin-bottom: 0.4rem;
    }
    .page-sub { font-size: 0.92rem; color: var(--ink-soft); }
    .page-sub a { color: var(--ink); font-weight: 700; text-decoration: none; }
    .page-sub a:hover { text-decoration: underline; }

    /* ── FORM CARD ── */
    .reg-card {
      background: var(--white);
      border-radius: 24px;
      box-shadow: var(--shadow-lg);
      width: 100%;
      max-width: 860px;
      padding: 2.8rem;
      position: relative;
      z-index: 1;
      animation: slideUp 0.6s 0.1s cubic-bezier(0.16,1,0.3,1) both;
    }

    /* ── SECTION HEADINGS ── */
    .section-head {
      display: flex; align-items: center; gap: 0.75rem;
      margin-bottom: 1.4rem; padding-bottom: 0.8rem;
      border-bottom: 1.5px solid var(--border);
    }
    .section-icon {
      width: 36px; height: 36px; border-radius: 10px;
      background: var(--gold-light);
      display: flex; align-items: center; justify-content: center;
      color: var(--gold); font-size: 1rem; flex-shrink: 0;
    }
    .section-title {
      font-family: 'Fraunces', serif;
      font-size: 1rem; font-weight: 600; color: var(--ink);
    }
    .section-sub { font-size: 0.78rem; color: var(--ink-soft); }

    /* ── FORM ELEMENTS ── */
    .field-group { margin-bottom: 1.1rem; }
    .field-label {
      font-size: 0.75rem; font-weight: 600;
      letter-spacing: 0.4px; color: var(--ink-mid);
      display: block; margin-bottom: 0.4rem;
    }
    .field-label .req { color: var(--red); margin-left: 2px; }

    .form-control, .form-select {
      width: 100%; border: 1.5px solid var(--border);
      border-radius: var(--radius-sm); padding: 0.72rem 1rem;
      font-family: 'DM Sans', sans-serif; font-size: 0.92rem;
      color: var(--ink); background: var(--white);
      transition: border-color 0.2s, box-shadow 0.2s;
      outline: none; appearance: none;
    }
    .form-control:focus, .form-select:focus {
      border-color: var(--ink-mid);
      box-shadow: 0 0 0 3px rgba(15,14,23,0.07);
    }
    .form-control::placeholder { color: #b8b5ca; }
    .form-control.has-icon { padding-right: 2.8rem; }

    .field-wrap { position: relative; }
    .field-icon {
      position: absolute; right: 0.9rem; top: 50%;
      transform: translateY(-50%);
      background: none; border: none; cursor: pointer;
      color: var(--ink-soft); font-size: 1.05rem; padding: 0;
      transition: color 0.2s;
    }
    .field-icon:hover { color: var(--ink); }

    /* Phone row */
    .phone-row { display: flex; gap: 0.5rem; }
    .country-select {
      width: 110px; flex-shrink: 0;
      border: 1.5px solid var(--border); border-radius: var(--radius-sm);
      padding: 0.72rem 0.5rem; font-family: 'DM Sans', sans-serif;
      font-size: 0.88rem; color: var(--ink); background: var(--white);
      cursor: pointer; outline: none;
    }
    .country-select:focus { border-color: var(--ink-mid); }

    /* Error text */
    .field-error { font-size: 0.78rem; color: var(--red); margin-top: 0.3rem; display: none; }
    .field-error.show { display: block; }

    /* ── PASSWORD STRENGTH ── */
    .strength-track { height: 4px; background: var(--border); border-radius: 4px; margin-top: 0.5rem; overflow: hidden; }
    .strength-bar   { height: 100%; border-radius: 4px; width: 0; transition: width 0.3s, background 0.3s; }
    .strength-row   { display: flex; justify-content: space-between; align-items: center; margin-top: 0.3rem; }
    .strength-text  { font-size: 0.72rem; color: var(--ink-soft); }
    .strength-hint  { font-size: 0.72rem; color: var(--ink-soft); }

    /* ── ALERTS ── */
    .alert-bar {
      border-radius: var(--radius-sm); padding: 0.8rem 1rem;
      font-size: 0.88rem; display: flex; align-items: center; gap: 0.5rem;
      margin-bottom: 1.5rem; font-weight: 500;
    }
    .alert-bar.err { background: #fff1f1; border: 1px solid #fca5a5; color: var(--red); border-left: 3px solid var(--red); }
    .alert-bar.ok  { background: #f0fdf4; border: 1px solid #86efac; color: var(--green); border-left: 3px solid var(--green); }

    /* ── SUBMIT BUTTON ── */
    .btn-register {
      width: 100%; padding: 0.9rem;
      background: var(--ink); color: #fff; border: none;
      border-radius: var(--radius-sm); cursor: pointer;
      font-family: 'DM Sans', sans-serif; font-size: 0.95rem; font-weight: 600;
      letter-spacing: 0.3px; display: flex; align-items: center; justify-content: center; gap: 0.5rem;
      transition: all 0.2s; margin-top: 0.5rem;
    }
    .btn-register:hover { background: var(--ink-mid); transform: translateY(-1px); box-shadow: var(--shadow-md); }
    .btn-register:active { transform: translateY(0); }

    /* Divider between sections */
    .section-gap { margin-bottom: 2rem; }

    /* ── ANIMATIONS ── */
    @keyframes slideUp {
      from { opacity: 0; transform: translateY(28px); }
      to   { opacity: 1; transform: translateY(0); }
    }

    /* ── RESPONSIVE ── */
    @media (max-width: 600px) {
      .reg-card { padding: 1.8rem 1.2rem; }
      .page-title { font-size: 1.7rem; }
    }
  </style>
</head>
<body>

<div style="width:100%;max-width:860px;position:relative;z-index:1;">

  <!-- Page Header -->
  <div class="page-header">
    <div class="brand-badge"><i class="bi bi-box-seam-fill"></i> Smart Inventory</div>
    <h1 class="page-title">Create Your Account</h1>
    <p class="page-sub">Already have an account? <a href="CustomerLogin.jsp">Sign in →</a></p>
  </div>

  <!-- Form Card -->
  <div class="reg-card">

    <!-- Alerts -->
    <%
      String error   = request.getParameter("error");
      String success = request.getParameter("success");
      if ("exists".equals(error)) {
    %>
      <div class="alert-bar err"><i class="bi bi-exclamation-circle-fill"></i> An account already exists with these details. <a href="CustomerLogin.jsp" style="color:inherit;font-weight:700;">Sign in instead.</a></div>
    <% } else if ("invalidPassword".equals(error)) { %>
      <div class="alert-bar err"><i class="bi bi-x-circle-fill"></i> Passwords do not match or are too weak. Please try again.</div>
    <% } else if ("failed".equals(error)) { %>
      <div class="alert-bar err"><i class="bi bi-x-circle-fill"></i> Registration failed. Please try again.</div>
    <% } else if ("registered".equals(success)) { %>
      <div class="alert-bar ok"><i class="bi bi-check-circle-fill"></i> Registration successful! Please login to continue.</div>
    <% } %>

    <form action="CustRegister" method="post" onsubmit="return validateForm()">

      <!-- ── PERSONAL INFORMATION ── -->
      <div class="section-head">
        <div class="section-icon"><i class="bi bi-person-fill"></i></div>
        <div>
          <div class="section-title">Personal Information</div>
          <div class="section-sub">Your basic details</div>
        </div>
      </div>

      <div class="row g-3 section-gap">
        <div class="col-md-6">
          <div class="field-group">
            <label class="field-label">Full Name <span class="req">*</span></label>
            <input type="text" name="name" class="form-control" placeholder="Enter your full name" required>
          </div>
        </div>
        <div class="col-md-6">
          <div class="field-group">
            <label class="field-label">Email Address <span class="req">*</span></label>
            <input type="email" name="email" class="form-control" placeholder="you@example.com" required>
          </div>
        </div>
        <div class="col-md-6">
          <div class="field-group">
            <label class="field-label">Phone Number <span class="req">*</span></label>
            <div class="phone-row">
              <select name="countryCode" class="country-select" required>
                <option value="+91">🇮🇳 +91</option>
                <option value="+1">🇺🇸  +1</option>
                <option value="+44">🇬🇧 +44</option>
                <option value="+61">🇦🇺 +61</option>
              </select>
              <input type="text" id="phone" name="phone" class="form-control" placeholder="10-digit number" required>
            </div>
            <div class="field-error" id="phoneError">Phone number must be exactly 10 digits.</div>
          </div>
        </div>
        <div class="col-md-6">
          <div class="field-group">
            <label class="field-label">Gender <span class="req">*</span></label>
            <select name="gender" class="form-select" required>
              <option value="">Select gender</option>
              <option value="Female">Female</option>
              <option value="Male">Male</option>
              <option value="Other">Other / Prefer not to say</option>
            </select>
          </div>
        </div>
      </div>

      <!-- ── ADDRESS ── -->
      <div class="section-head">
        <div class="section-icon"><i class="bi bi-geo-alt-fill"></i></div>
        <div>
          <div class="section-title">Delivery Address</div>
          <div class="section-sub">Where should we deliver?</div>
        </div>
      </div>

      <div class="row g-3 section-gap">
        <div class="col-12">
          <div class="field-group">
            <label class="field-label">Street Address <span class="req">*</span></label>
            <input type="text" name="landmark_street" class="form-control" placeholder="House no., street, landmark" required>
          </div>
        </div>
        <div class="col-md-6">
          <div class="field-group">
            <label class="field-label">City <span class="req">*</span></label>
            <input type="text" name="city" class="form-control" placeholder="Enter city" required>
          </div>
        </div>
        <div class="col-md-6">
          <div class="field-group">
            <label class="field-label">District <span class="req">*</span></label>
            <input type="text" name="district" class="form-control" placeholder="Enter district" required>
          </div>
        </div>
        <div class="col-md-4">
          <div class="field-group">
            <label class="field-label">State / Province <span class="req">*</span></label>
            <input type="text" name="state" class="form-control" placeholder="Enter state" required>
          </div>
        </div>
        <div class="col-md-4">
          <div class="field-group">
            <label class="field-label">Country <span class="req">*</span></label>
            <input type="text" name="country" class="form-control" placeholder="Enter country" required>
          </div>
        </div>
        <div class="col-md-4">
          <div class="field-group">
            <label class="field-label">Pincode / ZIP <span class="req">*</span></label>
            <input type="text" name="pincode" class="form-control" placeholder="6-digit pincode" required>
          </div>
        </div>
      </div>

      <!-- ── SECURITY ── -->
      <div class="section-head">
        <div class="section-icon"><i class="bi bi-shield-lock-fill"></i></div>
        <div>
          <div class="section-title">Account Security</div>
          <div class="section-sub">Choose a strong password</div>
        </div>
      </div>

      <div class="row g-3">
        <div class="col-md-6">
          <div class="field-group">
            <label class="field-label">Password <span class="req">*</span></label>
            <div class="field-wrap">
              <input type="password" id="password" name="password" class="form-control has-icon"
                     placeholder="Min 8 chars, number &amp; symbol" oninput="checkStrength()" required>
              <button type="button" class="field-icon" onclick="togglePwd('password',this)"><i class="bi bi-eye"></i></button>
            </div>
            <div class="strength-track"><div class="strength-bar" id="strengthBar"></div></div>
            <div class="strength-row">
              <span class="strength-text" id="strengthLabel"></span>
              <span class="strength-hint">Use uppercase, number &amp; symbol</span>
            </div>
          </div>
        </div>
        <div class="col-md-6">
          <div class="field-group">
            <label class="field-label">Confirm Password <span class="req">*</span></label>
            <div class="field-wrap">
              <input type="password" id="confirmPassword" name="confirmPassword" class="form-control has-icon"
                     placeholder="Re-enter your password" required>
              <button type="button" class="field-icon" onclick="togglePwd('confirmPassword',this)"><i class="bi bi-eye"></i></button>
            </div>
            <div class="field-error" id="confirmError">Passwords do not match.</div>
          </div>
        </div>
      </div>

      <!-- Terms -->
      <div style="margin-top:1.4rem;margin-bottom:1.2rem;display:flex;align-items:flex-start;gap:0.6rem;">
        <input type="checkbox" id="terms" required style="accent-color:var(--ink);width:16px;height:16px;margin-top:2px;flex-shrink:0;cursor:pointer;">
        <label for="terms" style="font-size:0.85rem;color:var(--ink-soft);cursor:pointer;line-height:1.5;">
          I agree to the <a href="#" style="color:var(--ink);font-weight:600;">Terms of Service</a> and
          <a href="#" style="color:var(--ink);font-weight:600;">Privacy Policy</a>. I understand my data will be used to manage my account.
        </label>
      </div>

      <button type="submit" class="btn-register">
        <i class="bi bi-person-check-fill"></i> Create Account
      </button>

    </form>
  </div><!-- end .reg-card -->

  <p style="text-align:center;font-size:0.8rem;color:var(--ink-soft);margin-top:1.5rem;padding-bottom:1rem;">
    Already have an account? <a href="CustomerLogin.jsp" style="color:var(--ink);font-weight:700;">Sign in →</a>
  </p>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
<script>
  /* ── PASSWORD TOGGLE ── */
  function togglePwd(id, btn) {
    const f = document.getElementById(id);
    const show = f.type === 'text';
    f.type = show ? 'password' : 'text';
    btn.querySelector('i').className = show ? 'bi bi-eye' : 'bi bi-eye-slash';
  }

  /* ── PASSWORD STRENGTH ── */
  function checkStrength() {
    const v = document.getElementById('password').value;
    const bar = document.getElementById('strengthBar');
    const lbl = document.getElementById('strengthLabel');
    let s = 0;
    if (v.length >= 8) s++;
    if (/[A-Z]/.test(v)) s++;
    if (/[0-9]/.test(v)) s++;
    if (/[^A-Za-z0-9]/.test(v)) s++;
    const colors = ['#dc2626', '#f97316', '#eab308', '#16a34a'];
    const labels = ['Weak', 'Fair', 'Good', 'Strong'];
    bar.style.width = (s * 25) + '%';
    bar.style.background = colors[s - 1] || '#e4e2ed';
    lbl.textContent = s > 0 ? labels[s - 1] : '';
    lbl.style.color = colors[s - 1] || 'var(--ink-soft)';
  }

  /* ── PHONE FORMAT ── */
  const phoneInput = document.getElementById('phone');
  phoneInput.addEventListener('input', function () {
    let v = this.value.replace(/\D/g, '');
    if (v.startsWith('0')) v = v.substring(1);
    v = v.substring(0, 10);
    if (v.length > 5) v = v.substring(0, 5) + ' ' + v.substring(5);
    this.value = v;
  });

  /* ── FORM VALIDATION ── */
  function validateForm() {
    let ok = true;
    const phone = document.getElementById('phone').value.replace(/\s/g, '');
    const phoneErr = document.getElementById('phoneError');
    if (!/^\d{10}$/.test(phone)) {
      phoneErr.classList.add('show'); ok = false;
    } else { phoneErr.classList.remove('show'); }

    const pwd = document.getElementById('password').value;
    const conf = document.getElementById('confirmPassword').value;
    const confErr = document.getElementById('confirmError');
    if (pwd !== conf) {
      confErr.classList.add('show'); ok = false;
    } else { confErr.classList.remove('show'); }

    if (pwd.length < 8) { alert('Password must be at least 8 characters.'); ok = false; }
    return ok;
  }
</script>
</body>
</html>
