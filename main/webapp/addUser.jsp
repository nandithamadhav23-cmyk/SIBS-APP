<%@ page language="java"%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>

<%
    String role  = (session != null) ? (String) session.getAttribute("role")     : null;
    String uname = (session != null) ? (String) session.getAttribute("username") : null;
    if (role == null || !"admin".equalsIgnoreCase(role)) {
        response.sendRedirect("index.jsp?error=Access denied. Please login as admin.");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Add Staff Member — SIBS</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css" rel="stylesheet">
  <link href="https://fonts.googleapis.com/css2?family=Nunito:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
  <style>
    :root {
      --primary:#0ea5e9; --primary-dark:#0369a1; --accent:#38bdf8; --accent-light:#e0f2fe;
      --text-dark:#0c1a2e; --text-mid:#1e3a5f; --text-muted:#64748b;
      --border:#dbeafe; --bg-white:#ffffff; --bg-off:#f0f9ff;
      --navbar-height:64px;
      --shadow-sm:0 2px 12px rgba(14,165,233,.08);
      --shadow-md:0 4px 24px rgba(14,165,233,.13);
      --shadow-lg:0 12px 40px rgba(14,165,233,.18);
    }
    *, *::before, *::after { box-sizing:border-box; }
    body { font-family:'Nunito',sans-serif; background:var(--bg-off); color:var(--text-dark); padding-top:var(--navbar-height); min-height:100vh; }

    /* ── NAVBAR ── */
    .top-navbar { position:fixed; top:0; left:0; right:0; height:var(--navbar-height); background:var(--primary); border-bottom:none; display:flex; align-items:center; padding:0 1.5rem; z-index:1050; gap:1rem; box-shadow:0 2px 16px rgba(14,165,233,.25); }
    .nav-brand { font-family:'Nunito',sans-serif; font-size:1.2rem; font-weight:800; color:#fff; letter-spacing:.5px; text-decoration:none; }
    .nav-brand span { color:#bae6fd; font-weight:300; }
    .nav-right { margin-left:auto; display:flex; align-items:center; gap:1rem; }
    .nav-welcome { font-size:.88rem; color:rgba(255,255,255,.9); }
    .nav-welcome strong { color:#fff; font-weight:700; }
    .badge-role { background:rgba(255,255,255,.18); color:#fff; border:1px solid rgba(255,255,255,.35); font-size:.68rem; letter-spacing:1px; text-transform:uppercase; padding:.2rem .65rem; border-radius:20px; font-weight:600; }
    .btn-nav { font-size:.78rem; font-weight:600; letter-spacing:.5px; padding:.4rem 1rem; border:1.5px solid rgba(255,255,255,.35); border-radius:20px; color:#fff; text-decoration:none; transition:all .2s; }
    .btn-nav:hover { background:rgba(255,255,255,.18); border-color:#fff; color:#fff; }

    /* ── LAYOUT ── */
    .page-wrapper { max-width:1050px; margin:2.5rem auto; padding:0 1.5rem 3rem; }
    .breadcrumb { background:transparent; padding:0; margin-bottom:1.5rem; }
    .breadcrumb-item { font-size:.82rem; font-weight:500; }
    .breadcrumb-item a { color:var(--text-muted); text-decoration:none; }
    .breadcrumb-item a:hover { color:var(--primary); }
    .breadcrumb-item.active { color:var(--text-dark); }
    .breadcrumb-item+.breadcrumb-item::before { color:var(--border); }

    /* ── SPLIT CARD ── */
    .split-card { display:flex; border-radius:14px; overflow:hidden; box-shadow:var(--shadow-lg); border:1px solid var(--border); animation:fadeUp .5s ease both; }
    .left-panel { width:290px; flex-shrink:0; background:linear-gradient(160deg,var(--primary-dark) 0%,var(--primary) 100%); border-right:none; padding:3rem 2rem; display:flex; flex-direction:column; justify-content:center; }
    .left-icon { width:72px; height:72px; border-radius:50%; background:rgba(255,255,255,.15); border:2px solid rgba(255,255,255,.3); display:flex; align-items:center; justify-content:center; font-size:1.8rem; color:#fff; margin-bottom:1.5rem; }
    .left-title { font-size:1.4rem; font-weight:800; color:#fff; margin-bottom:.8rem; line-height:1.3; }
    .left-quote { font-size:.87rem; color:rgba(255,255,255,.75); line-height:1.7; font-style:italic; margin-bottom:1.5rem; }
    .left-features { list-style:none; padding:0; margin:0; }
    .left-features li { font-size:.84rem; color:rgba(255,255,255,.8); padding:.4rem 0; display:flex; align-items:center; gap:.6rem; border-bottom:1px solid rgba(255,255,255,.1); }
    .left-features li:last-child { border-bottom:none; }
    .left-features li i { color:#bae6fd; }
    .left-footer { margin-top:2rem; font-size:.74rem; color:rgba(255,255,255,.5); letter-spacing:.5px; }
    .left-footer i { color:#bae6fd; }

    .right-panel { flex:1; background:var(--bg-white); padding:2.5rem 2.2rem; overflow-y:auto; }

    /* ── FORM ── */
    .form-section-title { font-size:.68rem; font-weight:700; letter-spacing:2px; text-transform:uppercase; color:var(--primary); margin-bottom:1rem; display:flex; align-items:center; gap:.75rem; }
    .form-section-title::after { content:''; flex:1; height:1px; background:var(--border); }
    .form-label { font-size:.74rem; font-weight:700; letter-spacing:.5px; text-transform:uppercase; color:var(--text-mid); margin-bottom:.3rem; display:block; }
    .mandatory { color:#ef4444; margin-left:2px; }
    .form-control, .form-select { border:1.5px solid var(--border); border-radius:9px; padding:.55rem .85rem; font-family:'Nunito',sans-serif; font-size:.92rem; color:var(--text-dark); background:var(--bg-white); transition:border-color .2s; }
    .form-control:focus, .form-select:focus { border-color:var(--primary); outline:none; box-shadow:0 0 0 3px rgba(14,165,233,.12); }
    .form-control::placeholder { color:var(--text-muted); }
    .field-msg { font-size:.74rem; margin-top:.25rem; min-height:1.1em; }
    .field-msg.error { color:#ef4444; }
    .field-msg.ok    { color:#16a34a; }

    .role-fields-panel { background:var(--bg-off); border:1px solid var(--border); border-left:3px solid var(--primary); border-radius:9px; padding:1.5rem 1.4rem; margin-top:.5rem; }
    .role-fields-label { font-size:.72rem; font-weight:700; letter-spacing:1.5px; text-transform:uppercase; color:var(--primary); margin-bottom:1rem; display:flex; align-items:center; gap:.5rem; }
    .form-divider { border:none; border-top:1px solid var(--border); margin:1.5rem 0; }

    /* ── SHIFT SELECT ── */
    .shift-loading { font-size:.75rem; color:var(--text-muted); font-style:italic; margin-top:.25rem; display:none; }

    /* ── BUTTONS ── */
    .form-actions { display:flex; align-items:center; gap:.8rem; flex-wrap:wrap; margin-top:2rem; padding-top:1.5rem; border-top:1px solid var(--border); }
    .btn-form { font-size:.82rem; font-weight:600; letter-spacing:.5px; padding:.6rem 1.6rem; border-radius:9px; transition:all .2s; cursor:pointer; display:inline-flex; align-items:center; gap:.4rem; }
    .btn-form-primary { background:var(--primary); color:#fff; border:2px solid var(--primary); }
    .btn-form-primary:hover { background:var(--primary-dark); border-color:var(--primary-dark); color:#fff; transform:translateY(-1px); box-shadow:0 4px 12px rgba(14,165,233,.3); }
    .btn-form-outline { background:transparent; color:var(--text-mid); border:1.5px solid var(--border); text-decoration:none; }
    .btn-form-outline:hover { border-color:var(--primary); color:var(--primary); background:var(--accent-light); }
    .btn-form-reset { background:transparent; color:#ef4444; border:1.5px solid #fecaca; }
    .btn-form-reset:hover { background:#fee2e2; color:#b91c1c; border-color:#f87171; }

    /* ── MODALS ── */
    .modal-content { border:none; border-radius:14px; box-shadow:var(--shadow-lg); }
    .modal-header { padding:1.2rem 1.5rem; border-radius:14px 14px 0 0; }
    .mh-success { background:linear-gradient(135deg,#16a34a,#22c55e); } .mh-error { background:linear-gradient(135deg,#b91c1c,#ef4444); }
    .modal-title { font-size:.95rem; font-weight:700; color:#fff; }
    .modal-body { padding:1.5rem; font-size:.95rem; color:var(--text-mid); }
    .modal-footer { border-top:1px solid var(--border); padding:1rem 1.5rem; background:var(--bg-off); }
    .btn-modal { background:var(--primary); color:#fff; border:none; font-size:.82rem; font-weight:600; padding:.5rem 1.4rem; border-radius:9px; cursor:pointer; transition:all .2s; }
    .btn-modal:hover { background:var(--primary-dark); transform:translateY(-1px); }

    footer { background:var(--primary-dark); color:rgba(255,255,255,.65); font-family:'Nunito',sans-serif; font-size:.82rem; font-weight:500; text-align:center; padding:1rem; border-top:none; margin-top:2rem; }
    footer span { color:#bae6fd; font-weight:700; }

    @keyframes fadeUp { from{opacity:0;transform:translateY(16px);}to{opacity:1;transform:translateY(0);} }

    @media(max-width:768px) {
      .split-card { flex-direction:column; }
      .left-panel { width:100%; padding:1.75rem 1.25rem; }
      .left-icon { width:52px; height:52px; font-size:1.3rem; }
      .left-title { font-size:1.1rem; }
      .right-panel { padding:1.5rem 1rem; }
      .form-actions { justify-content:stretch; }
      .form-actions .btn-form { flex:1; justify-content:center; }
      .nav-welcome, .badge-role { display:none; }
    }
    @media(max-width:480px) {
      .page-wrapper { padding:0 .75rem 2rem; }
      .top-navbar { padding:0 1rem; }
    }
  </style>
</head>
<body>

<div class="top-navbar">
  <a class="nav-brand" href="dashboard.jsp?section=staff">SIBS <span>Staff Portal</span></a>
  <div class="nav-right">
    <span class="nav-welcome">Welcome, <strong><%= uname %></strong></span>
    <span class="badge-role"><%= role %></span>
    <a href="logout" class="btn-nav"><i class="bi bi-box-arrow-right me-1"></i>Logout</a>
  </div>
</div>

<div class="page-wrapper">
  <nav aria-label="breadcrumb">
    <ol class="breadcrumb">
      <li class="breadcrumb-item"><a href="dashboard.jsp?section=staff"><i class="bi bi-house me-1"></i>Dashboard</a></li>
      <li class="breadcrumb-item"><a href="dashboard.jsp?section=staff">Staff Dashboard</a></li>
      <li class="breadcrumb-item active">Add Staff Member</li>
    </ol>
  </nav>

  <div class="split-card">

    <!-- LEFT PANEL -->
    <div class="left-panel">
      <div class="left-icon"><i class="bi bi-person-plus-fill"></i></div>
      <h2 class="left-title">Add New Team Member</h2>
      <p class="left-quote">Every new member strengthens our organisation — bringing innovation, growth, and collaboration for a brighter future.</p>
      <ul class="left-features">
        <li><i class="bi bi-lightbulb-fill"></i> Innovation through fresh ideas</li>
        <li><i class="bi bi-graph-up-arrow"></i> Driving business growth</li>
        <li><i class="bi bi-handshake"></i> Stronger collaboration</li>
        <li><i class="bi bi-shield-check"></i> Role-based secure access</li>
        <li><i class="bi bi-clock-fill"></i> Shift-aware attendance engine</li>
      </ul>
      <p class="left-footer"><i class="bi bi-star-fill me-1"></i> Together we build success.</p>
    </div>

    <!-- RIGHT PANEL -->
    <div class="right-panel">
      <form id="userForm" action="AddUser" method="post" novalidate>

        <!-- ── BASIC INFO ── -->
        <p class="form-section-title"><i class="bi bi-person me-1"></i>Basic Information</p>
        <div class="row g-3 mb-3">
          <div class="col-sm-6">
            <label class="form-label">Username <span class="mandatory">*</span></label>
            <input type="text" name="username" class="form-control" placeholder="Enter username" required>
          </div>
          <div class="col-sm-6">
            <label class="form-label">Password <span class="mandatory">*</span></label>
            <div style="position:relative;">
              <input type="password" name="password" id="passwordInput" class="form-control"
                     placeholder="Min 8 characters" required style="padding-right:2.8rem;">
              <button type="button" id="togglePwd"
                      style="position:absolute;right:.7rem;top:50%;transform:translateY(-50%);background:none;border:none;color:var(--text-muted);cursor:pointer;font-size:1rem;padding:0;">
                <i class="bi bi-eye" id="eyeIcon"></i>
              </button>
            </div>
          </div>
          <div class="col-sm-6">
            <label class="form-label">Email <span class="mandatory">*</span></label>
            <input type="email" name="email" class="form-control" id="email"
                   placeholder="email@example.com" required>
            <!-- BUG FIX: inline message replaces disruptive alert; used for email-exists feedback too -->
            <span id="emailMsg" class="field-msg"></span>
          </div>
          <div class="col-sm-6">
            <label class="form-label">Mobile <span class="mandatory">*</span></label>
            <div class="d-flex gap-2">
              <select name="countryCode" class="form-select" style="width:120px;flex-shrink:0;">
                <option value="+91">🇮🇳 +91</option>
                <option value="+1">🇺🇸 +1</option>
                <option value="+44">🇬🇧 +44</option>
                <option value="+61">🇦🇺 +61</option>
                <option value="+971">🇦🇪 +971</option>
                <option value="+65">🇸🇬 +65</option>
              </select>
              <input type="text" name="mobile" id="mobile" class="form-control"
                     maxlength="10" placeholder="10-digit number" required>
            </div>
            <span id="mobileMsg" class="field-msg"></span>
          </div>
          <div class="col-sm-8">
            <label class="form-label">Address</label>
            <input type="text" name="address" class="form-control" placeholder="Full address">
          </div>
          <div class="col-sm-4">
            <label class="form-label">Gender <span class="mandatory">*</span></label>
            <select name="gender" class="form-select" required>
              <option value="">Select</option>
              <option value="Male">Male</option>
              <option value="Female">Female</option>
              <option value="Other">Other</option>
            </select>
          </div>
        </div>

        <hr class="form-divider">

        <!-- ── ROLE & ACCESS ── -->
        <p class="form-section-title"><i class="bi bi-shield-lock me-1"></i>Role &amp; Access</p>
        <div class="row g-3 mb-2">
          <div class="col-sm-6">
            <label class="form-label">Role <span class="mandatory">*</span></label>
            <select name="role" id="roleSelect" class="form-select" required>
              <option value="">— Select Role —</option>
              <option value="user">User</option>
              <option value="staff">Staff</option>
              <option value="admin">Admin</option>
            </select>
          </div>
          <div class="col-sm-6">
            <label class="form-label">Status <span class="mandatory">*</span></label>
            <!-- BUG FIX: status values must match validateLogin check ('active'/'inactive' lowercase).
                 'Active' with capital A was previously used but validateLogin checks status='active' strictly. -->
            <select name="status" class="form-select" required>
              <option value="">— Select Status —</option>
              <option value="active">Active</option>
              <option value="inactive">Inactive</option>
              <option value="pending">Pending</option>
            </select>
          </div>
        </div>

        <!-- ── STAFF FIELDS ── -->
        <div id="staffFields" style="display:none; margin-top:.75rem;">
          <div class="role-fields-panel">
            <p class="role-fields-label"><i class="bi bi-person-badge"></i> Staff Details</p>
            <div class="row g-3">
              <div class="col-sm-6">
                <label class="form-label">Employee ID</label>
                <input type="text" name="employeeId" class="form-control" placeholder="e.g. EMP-001">
              </div>
              <div class="col-sm-6">
                <label class="form-label">Department</label>
                <input type="text" name="department" class="form-control" placeholder="e.g. Sales">
              </div>

              <!-- Shift loaded from office_shifts via AttendanceServlet -->
              <div class="col-sm-6">
                <label class="form-label">Shift <span class="mandatory">*</span></label>
                <select name="shiftId" id="shiftIdSelect" class="form-select">
                  <option value="">— Select Shift —</option>
                </select>
                <span class="shift-loading" id="shiftLoading">
                  <i class="bi bi-hourglass-split"></i> Loading…
                </span>
              </div>

              <!-- Shift info badge (auto-populated on select) -->
              <div class="col-sm-6">
                <label class="form-label">Shift Schedule</label>
                <div id="shiftInfoBadge" style="padding:.58rem .85rem;border:1px solid var(--border);border-radius:3px;background:var(--bg-off);font-size:.85rem;color:var(--text-muted);min-height:38px;">
                  Select a shift to see hours
                </div>
              </div>

              <div class="col-sm-6">
                <label class="form-label">Supervisor</label>
                <input type="text" name="supervisor" class="form-control" placeholder="Supervisor name">
              </div>
              <div class="col-sm-6">
                <label class="form-label">Date of Joining</label>
                <input type="date" name="joiningDate" class="form-control">
              </div>
            </div>
          </div>
        </div>

        <!-- ── ADMIN FIELDS ── -->
        <div id="adminFields" style="display:none; margin-top:.75rem;">
          <div class="role-fields-panel">
            <p class="role-fields-label"><i class="bi bi-shield-fill"></i> Admin Details</p>
            <div class="row g-3">
              <div class="col-sm-6">
                <label class="form-label">Admin Level</label>
                <select name="adminLevel" class="form-select">
                  <option value="super">Super Admin</option>
                  <option value="manager">Manager Admin</option>
                </select>
              </div>
              <div class="col-sm-6">
                <label class="form-label">Privileges
                  <i class="bi bi-info-circle ms-1" style="color:var(--text-muted);cursor:help;"
                     data-bs-toggle="tooltip"
                     title="Define permissions: manage users, approve reports, system settings."></i>
                </label>
                <input type="text" name="privileges" class="form-control"
                       placeholder="e.g. Manage Users, Approve Reports">
              </div>
            </div>
          </div>
        </div>

        <div class="form-actions">
          <button type="submit" class="btn-form btn-form-primary" id="addUserBtn">
            <i class="bi bi-person-plus-fill"></i> Add Member
          </button>
          <a href="dashboard.jsp?section=staff" class="btn-form btn-form-outline">
            <i class="bi bi-arrow-left"></i> Back to Staff
          </a>
          <button type="reset" class="btn-form btn-form-reset" onclick="resetExtras()">
            <i class="bi bi-x-circle"></i> Clear
          </button>
        </div>

      </form>
    </div>
  </div>
</div>

<!-- SUCCESS MODAL -->
<div class="modal fade" id="successModal" tabindex="-1">
  <div class="modal-dialog modal-dialog-centered">
    <div class="modal-content">
      <div class="modal-header mh-success">
        <h5 class="modal-title"><i class="bi bi-check-circle-fill me-2"></i>Member Added</h5>
      </div>
      <div class="modal-body">
        <i class="bi bi-check-circle-fill me-2" style="color:#27ae60;"></i>
        Staff member has been successfully added to the system.
      </div>
      <div class="modal-footer">
        <button class="btn-modal" onclick="window.location.href='StaffDashboard'"><i class="bi bi-arrow-left me-1"></i>Go Back</button>
      </div>
    </div>
  </div>
</div>

<!-- ERROR MODAL -->
<div class="modal fade" id="errorModal" tabindex="-1">
  <div class="modal-dialog modal-dialog-centered">
    <div class="modal-content">
      <div class="modal-header mh-error">
        <h5 class="modal-title"><i class="bi bi-exclamation-triangle-fill me-2"></i>Error Occurred</h5>
      </div>
      <div class="modal-body">
        <i class="bi bi-exclamation-triangle-fill me-2" style="color:#e74c3c;"></i>
        <%
          String errMsg = (String) request.getAttribute("msg");
          if (errMsg == null || errMsg.isEmpty()) errMsg = "Something went wrong. Please try again.";
        %>
        <%= errMsg %>
      </div>
      <div class="modal-footer">
        <button class="btn-modal" data-bs-dismiss="modal"><i class="bi bi-arrow-left me-1"></i>Go Back</button>
      </div>
    </div>
  </div>
</div>

<footer><p class="mb-0">&copy; 2026 <span>SIBS</span> &nbsp;|&nbsp; Administrator Portal</p></footer>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
<script>
/* ── TOOLTIPS ── */
document.addEventListener('DOMContentLoaded', function () {
  [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'))
    .forEach(el => new bootstrap.Tooltip(el));
});

/* ── ROLE TOGGLE ── */
document.getElementById('roleSelect').addEventListener('change', function () {
  const r = this.value;
  document.getElementById('staffFields').style.display = (r === 'staff') ? 'block' : 'none';
  document.getElementById('adminFields').style.display = (r === 'admin') ? 'block' : 'none';
  if (r === 'staff') loadShifts();
});

/* ── PASSWORD TOGGLE ── */
document.getElementById('togglePwd').addEventListener('click', function () {
  const p = document.getElementById('passwordInput'), i = document.getElementById('eyeIcon');
  if (p.type === 'password') { p.type = 'text';     i.className = 'bi bi-eye-slash'; }
  else                       { p.type = 'password'; i.className = 'bi bi-eye'; }
});

/* ── MOBILE INLINE VALIDATION (BUG FIX: replaced alert() with inline msg) ── */
document.getElementById('mobile').addEventListener('input', function (e) {
  let v = e.target.value.replace(/\D/g, '');
  if (v.length > 10) v = v.slice(0, 10);
  e.target.value = v;
  document.getElementById('mobileMsg').textContent = '';
});
document.getElementById('mobile').addEventListener('blur', function () {
  const digits = this.value.replace(/\s/g, '');
  const msg = document.getElementById('mobileMsg');
  if (digits.length > 0 && digits.length !== 10) {
    msg.textContent = 'Mobile number must be exactly 10 digits.';
    msg.className = 'field-msg error';
  } else if (digits.length === 10) {
    msg.textContent = '✓ Valid';
    msg.className = 'field-msg ok';
  }
});

/* ── EMAIL DUPLICATE CHECK ── */
document.getElementById('email').addEventListener('blur', function () {
  const email = this.value.trim();
  const msg   = document.getElementById('emailMsg');
  const btn   = document.getElementById('addUserBtn');
  if (!email) return;
  fetch('checkEmail?email=' + encodeURIComponent(email))
    .then(r => r.json())
    .then(data => {
      if (data.exists) {
        msg.textContent = '✗ Email already registered';
        msg.className = 'field-msg error';
        btn.disabled = true;
      } else {
        msg.textContent = '✓ Available';
        msg.className = 'field-msg ok';
        btn.disabled = false;
      }
    })
    .catch(() => { msg.textContent = ''; btn.disabled = false; });
});

/* ── LOAD SHIFTS ── */
let shiftsLoaded = false;

function loadShifts() {
  if (shiftsLoaded) return;
  const sel  = document.getElementById('shiftIdSelect');
  document.getElementById('shiftLoading').style.display = 'block';

  fetch('AttendanceServlet?action=shifts')
    .then(r => r.json())
    .then(data => {
      shiftsLoaded = true;
      sel.innerHTML = '<option value="">— Select Shift —</option>' +
        data.map(s => `<option value="${s.id}"
          data-login="${s.loginTime}"
          data-logout="${s.logoutTime}"
          data-grace="${s.graceMinutes}">${s.shiftName}</option>`).join('');
      document.getElementById('shiftLoading').style.display = 'none';
    })
    .catch(() => {
      sel.innerHTML = '<option value="">— Failed to load shifts —</option>';
      document.getElementById('shiftLoading').style.display = 'none';
    });
}

/* ── SHIFT INFO BADGE ── */
document.getElementById('shiftIdSelect').addEventListener('change', function () {
  const opt  = this.options[this.selectedIndex];
  const info = document.getElementById('shiftInfoBadge');
  if (!this.value) {
    info.textContent = 'Select a shift to see hours';
    info.style.color = 'var(--text-muted)';
    return;
  }
  info.innerHTML = `<i class="bi bi-clock me-1" style="color:var(--accent)"></i>
    <strong>${fmtTime(opt.dataset.login)}</strong> → <strong>${fmtTime(opt.dataset.logout)}</strong>
    &nbsp;·&nbsp; ${opt.dataset.grace}m grace window`;
  info.style.color = 'var(--text-dark)';
});

function fmtTime(t) {
  if (!t) return '—';
  const [h, m] = t.split(':');
  const hour = parseInt(h, 10);
  return ((hour % 12) || 12) + ':' + m + ' ' + (hour >= 12 ? 'PM' : 'AM');
}

/* ── RESET helper ── */
function resetExtras() {
  document.getElementById('staffFields').style.display = 'none';
  document.getElementById('adminFields').style.display = 'none';
  document.getElementById('shiftInfoBadge').textContent = 'Select a shift to see hours';
  document.getElementById('emailMsg').textContent = '';
  document.getElementById('mobileMsg').textContent = '';
  document.getElementById('addUserBtn').disabled = false;
  shiftsLoaded = false;
}
</script>

<%
  String statusAttr = (String) request.getAttribute("status");
  if ("success".equals(statusAttr)) { %>
    <script>new bootstrap.Modal(document.getElementById('successModal')).show();</script>
<% } else if ("error".equals(statusAttr)) { %>
    <script>new bootstrap.Modal(document.getElementById('errorModal')).show();</script>
<% } %>

</body>
</html>
