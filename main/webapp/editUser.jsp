<%@ page contentType="text/html; charset=UTF-8" isELIgnored="true"  %>

<%@ page import="com.util.User"  %>
<%
    User user = (User) request.getAttribute("user");
    String role  = (session != null) ? (String) session.getAttribute("role")     : null;
    String uname = (session != null) ? (String) session.getAttribute("username") : null;
    if (role == null || !"admin".equalsIgnoreCase(role)) {
        response.sendRedirect("index.jsp?error=Access denied. Please login as admin.");
        return;
    }
    if (user == null) {
        response.sendRedirect("userList?error=User not found.");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Edit User — SIBS Staff Portal</title>
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
    .top-navbar { position:fixed; top:0; left:0; right:0; height:var(--navbar-height); background:var(--primary); display:flex; align-items:center; padding:0 1.5rem; z-index:1050; gap:1rem; box-shadow:0 2px 16px rgba(14,165,233,.25); }
    .nav-brand { font-family:'Nunito',sans-serif; font-size:1.2rem; font-weight:800; color:#fff; letter-spacing:.5px; text-decoration:none; }
    .nav-brand span { color:#bae6fd; font-weight:300; }
    .nav-right { margin-left:auto; display:flex; align-items:center; gap:1rem; }
    .nav-welcome { font-size:.88rem; color:rgba(255,255,255,.9); }
    .nav-welcome strong { color:#fff; font-weight:700; }
    .badge-role { background:rgba(255,255,255,.18); color:#fff; border:1px solid rgba(255,255,255,.35); font-size:.68rem; letter-spacing:1px; text-transform:uppercase; padding:.2rem .65rem; border-radius:20px; font-weight:600; }
    .btn-nav { font-size:.78rem; font-weight:600; letter-spacing:.5px; padding:.4rem 1rem; border:1.5px solid rgba(255,255,255,.35); border-radius:20px; color:#fff; text-decoration:none; transition:all .2s; }
    .btn-nav:hover { background:rgba(255,255,255,.18); color:#fff; }

    /* ── LAYOUT ── */
    .page-wrapper { max-width:960px; margin:2.5rem auto; padding:0 1.5rem 3rem; }
    .breadcrumb { background:transparent; padding:0; margin-bottom:1.5rem; }
    .breadcrumb-item { font-size:.82rem; font-weight:500; }
    .breadcrumb-item a { color:var(--text-muted); text-decoration:none; }
    .breadcrumb-item a:hover { color:var(--primary); }
    .breadcrumb-item.active { color:var(--text-dark); }
    .breadcrumb-item+.breadcrumb-item::before { color:var(--border); }

    /* ── CARD ── */
    .edit-card { background:var(--bg-white); border:1px solid var(--border); border-top:4px solid var(--primary); border-radius:14px; box-shadow:var(--shadow-lg); animation:fadeUp .45s ease both; overflow:hidden; }
    .edit-card-header { background:linear-gradient(135deg,var(--primary-dark) 0%,var(--primary) 100%); padding:1.25rem 1.75rem; display:flex; align-items:center; gap:1rem; }
    .edit-card-header h2 { font-size:1.05rem; font-weight:800; color:#fff; margin:0; display:flex; align-items:center; gap:.6rem; }
    .user-badge { margin-left:auto; background:rgba(255,255,255,.18); color:#fff; border:1px solid rgba(255,255,255,.3); font-size:.72rem; letter-spacing:.5px; text-transform:uppercase; padding:.28rem .8rem; border-radius:20px; font-weight:600; }
    .edit-card-body { padding:2rem 1.75rem; }

    /* ── SECTIONS ── */
    .section-title { font-size:.68rem; font-weight:700; letter-spacing:2px; text-transform:uppercase; color:var(--primary); margin-bottom:1rem; display:flex; align-items:center; gap:.75rem; }
    .section-title::after { content:''; flex:1; height:1px; background:var(--border); }
    .section-block { background:var(--bg-off); border:1px solid var(--border); border-left:3px solid var(--primary); border-radius:10px; padding:1.4rem; margin-bottom:1.5rem; }
    .section-block-title { font-size:.72rem; font-weight:700; letter-spacing:1.5px; text-transform:uppercase; color:var(--primary); margin-bottom:1rem; display:flex; align-items:center; gap:.5rem; }

    /* ── FORM CONTROLS ── */
    .form-label { font-size:.74rem; font-weight:700; letter-spacing:.5px; text-transform:uppercase; color:var(--text-mid); margin-bottom:.3rem; display:block; }
    .form-control, .form-select { border:1.5px solid var(--border); border-radius:9px; padding:.55rem .85rem; font-family:'Nunito',sans-serif; font-size:.92rem; color:var(--text-dark); background:var(--bg-white); transition:border-color .2s; }
    .form-control:focus, .form-select:focus { border-color:var(--primary); outline:none; box-shadow:0 0 0 3px rgba(14,165,233,.12); }
    .form-control:hover, .form-select:hover { border-color:#94c6f5; }
    .form-control[readonly] { background:var(--bg-off); color:var(--text-muted); cursor:default; }

    /* ── SHIFT INFO ── */
    .shift-info-badge { padding:.55rem .85rem; border:1.5px solid var(--border); border-radius:9px; background:var(--bg-off); font-size:.88rem; color:var(--text-muted); min-height:42px; display:flex; align-items:center; }

    /* ── FORM ACTIONS ── */
    .form-divider { border:none; border-top:1px solid var(--border); margin:1.5rem 0; }
    .form-actions { display:flex; align-items:center; gap:.8rem; flex-wrap:wrap; padding-top:1.5rem; }
    .btn-form { font-size:.82rem; font-weight:600; letter-spacing:.3px; padding:.6rem 1.6rem; border-radius:9px; transition:all .2s; cursor:pointer; display:inline-flex; align-items:center; gap:.4rem; font-family:'Nunito',sans-serif; }
    .btn-form-primary { background:var(--primary); color:#fff; border:2px solid var(--primary); }
    .btn-form-primary:hover { background:var(--primary-dark); border-color:var(--primary-dark); color:#fff; transform:translateY(-1px); box-shadow:0 4px 12px rgba(14,165,233,.3); }
    .btn-form-outline { background:transparent; color:var(--text-mid); border:1.5px solid var(--border); text-decoration:none; }
    .btn-form-outline:hover { border-color:var(--primary); color:var(--primary); background:var(--accent-light); }

    /* ── MODAL ── */
    .modal-content { border:none; border-radius:16px; box-shadow:var(--shadow-lg); font-family:'Nunito',sans-serif; }
    .modal-header { background:linear-gradient(135deg,var(--primary-dark),var(--primary)); border-radius:16px 16px 0 0; padding:1.1rem 1.5rem; }
    .modal-title { font-size:.95rem; font-weight:700; color:#fff; }
    .modal-body { padding:1.5rem; font-size:.95rem; color:var(--text-mid); text-align:center; }
    .modal-footer { border-top:1px solid var(--border); padding:1rem 1.5rem; background:var(--bg-off); border-radius:0 0 16px 16px; }
    .btn-modal-cancel { font-size:.82rem; font-weight:600; padding:.45rem 1.2rem; border:1.5px solid var(--border); border-radius:9px; color:var(--text-mid); background:transparent; cursor:pointer; transition:all .2s; }
    .btn-modal-cancel:hover { border-color:var(--primary); color:var(--primary); }
    .btn-modal-confirm { background:var(--primary); color:#fff; border:none; font-size:.82rem; font-weight:600; padding:.48rem 1.3rem; border-radius:9px; cursor:pointer; transition:all .2s; display:inline-flex; align-items:center; gap:.4rem; }
    .btn-modal-confirm:hover { background:var(--primary-dark); transform:translateY(-1px); }

    footer { background:var(--primary-dark); color:rgba(255,255,255,.65); font-family:'Nunito',sans-serif; font-size:.82rem; font-weight:500; text-align:center; padding:1rem; margin-top:2rem; }
    footer span { color:#bae6fd; font-weight:700; }

    @keyframes fadeUp { from{opacity:0;transform:translateY(14px)} to{opacity:1;transform:translateY(0)} }

    @media(max-width:768px) {
      .page-wrapper { padding:0 .75rem 2rem; }
      .edit-card-body { padding:1.25rem 1rem; }
      .edit-card-header { padding:1rem 1.25rem; }
      .form-actions { flex-direction:column; }
      .form-actions .btn-form { width:100%; justify-content:center; }
      .nav-welcome, .badge-role { display:none; }
    }
  </style>
</head>
<body>

<!-- NAVBAR -->
<div class="top-navbar">
  <a class="nav-brand" href="staffDashboard.jsp">SIBS <span>Staff Portal</span></a>
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
      <li class="breadcrumb-item"><a href="userList">Staff List</a></li>
      <li class="breadcrumb-item active">Edit User</li>
    </ol>
  </nav>

  <div class="edit-card">
    <div class="edit-card-header">
      <h2><i class="bi bi-pencil-square"></i> Edit User</h2>
      <span class="user-badge"><i class="bi bi-person-circle me-1"></i><%= user.getUsername() %></span>
    </div>

    <div class="edit-card-body">
      <form id="editUserForm" action="EditUser" method="post">
        <input type="hidden" name="username" value="<%= user.getUsername() %>">
        <input type="hidden" name="role"     value="<%= user.getRole()     %>">

        <!-- ── BASIC INFO ── -->
        <p class="section-title"><i class="bi bi-person-lines-fill me-1"></i>Basic Information</p>
        <div class="row g-3 mb-3">
          <div class="col-sm-6">
            <label class="form-label">Username</label>
            <input type="text" class="form-control" value="<%= user.getUsername() %>" readonly>
          </div>
          <div class="col-sm-6">
            <label class="form-label">Role</label>
            <input type="text" class="form-control" value="<%= user.getRole() %>" readonly>
          </div>
          <div class="col-sm-6">
            <label class="form-label">Email</label>
            <input type="email" name="email" value="<%= user.getEmail() != null ? user.getEmail() : "" %>" class="form-control">
          </div>
          <div class="col-sm-6">
            <label class="form-label">Mobile</label>
            <div class="d-flex gap-2">
              <select name="countryCode" class="form-select" style="width:120px;flex-shrink:0;">
                <% String savedCC = user.getCountryCode() != null ? user.getCountryCode() : "+91"; %>
                <option value="+91"  <%= "+91" .equals(savedCC) ? "selected" : "" %>>🇮🇳 +91</option>
                <option value="+1"   <%= "+1"  .equals(savedCC) ? "selected" : "" %>>🇺🇸 +1</option>
                <option value="+44"  <%= "+44" .equals(savedCC) ? "selected" : "" %>>🇬🇧 +44</option>
                <option value="+61"  <%= "+61" .equals(savedCC) ? "selected" : "" %>>🇦🇺 +61</option>
                <option value="+971" <%= "+971".equals(savedCC) ? "selected" : "" %>>🇦🇪 +971</option>
                <option value="+65"  <%= "+65" .equals(savedCC) ? "selected" : "" %>>🇸🇬 +65</option>
              </select>
              <input type="text" name="mobile" value="<%= user.getMobileno() != null ? user.getMobileno() : "" %>" class="form-control" maxlength="10">
            </div>
          </div>
          <div class="col-sm-8">
            <label class="form-label">Address</label>
            <input type="text" name="address" value="<%= user.getAddress() != null ? user.getAddress() : "" %>" class="form-control">
          </div>
          <div class="col-sm-2">
            <label class="form-label">Gender</label>
            <select name="gender" class="form-select">
              <option value="Male"   <%= "Male".equalsIgnoreCase(user.getGender())   ? "selected" : "" %>>Male</option>
              <option value="Female" <%= "Female".equalsIgnoreCase(user.getGender()) ? "selected" : "" %>>Female</option>
              <option value="Other"  <%= "Other".equalsIgnoreCase(user.getGender())  ? "selected" : "" %>>Other</option>
            </select>
          </div>
          <div class="col-sm-2">
            <label class="form-label">Status</label>
            <select name="status" class="form-select">
              <option value="Active"   <%= "Active".equalsIgnoreCase(user.getStatus())   ? "selected" : "" %>>Active</option>
              <option value="Inactive" <%= "Inactive".equalsIgnoreCase(user.getStatus()) ? "selected" : "" %>>Inactive</option>
              <option value="pending"  <%= "pending".equalsIgnoreCase(user.getStatus())  ? "selected" : "" %>>Pending</option>
            </select>
          </div>
        </div>

        <!-- ── STAFF SECTION ── -->
        <% if ("staff".equalsIgnoreCase(user.getRole())) { %>
        <p class="section-title"><i class="bi bi-people-fill me-1"></i>Staff Details</p>
        <div class="section-block">
          <p class="section-block-title"><i class="bi bi-person-badge"></i> Shift &amp; Assignment</p>
          <div class="row g-3">
            <div class="col-sm-6">
              <label class="form-label">Employee ID</label>
              <input type="text" name="employeeId"
                     value="<%= user.getEmployeeId() != null ? user.getEmployeeId() : "" %>"
                     class="form-control">
            </div>
            <div class="col-sm-6">
              <label class="form-label">Department</label>
              <input type="text" name="department"
                     value="<%= user.getDepartment() != null ? user.getDepartment() : "" %>"
                     class="form-control">
            </div>

            <div class="col-sm-6">
              <label class="form-label">Assigned Shift</label>
              <select name="shiftId" id="shiftIdSelect" class="form-select">
                <option value="">— Loading shifts… —</option>
              </select>
            </div>
            <div class="col-sm-6">
              <label class="form-label">Shift Schedule</label>
              <div class="shift-info-badge" id="shiftInfoBadge">
                <i class="bi bi-clock me-1" style="color:var(--primary)"></i>
                <span style="color:var(--text-muted)">Select a shift to see the timings</span>
              </div>
            </div>

            <div class="col-sm-6">
              <label class="form-label">Supervisor</label>
              <input type="text" name="supervisor"
                     value="<%= user.getSupervisor() != null ? user.getSupervisor() : "" %>"
                     class="form-control">
            </div>
            <div class="col-sm-6">
              <label class="form-label">Date of Joining</label>
              <input type="date" name="joiningDate"
                     value="<%= user.getJoiningDate() != null ? user.getJoiningDate().toString() : "" %>"
                     class="form-control">
            </div>
          </div>
        </div>
        <% } else if ("admin".equalsIgnoreCase(user.getRole())) { %>

        <!-- ── ADMIN SECTION ── -->
        <p class="section-title"><i class="bi bi-shield-lock me-1"></i>Admin Details</p>
        <div class="section-block">
          <p class="section-block-title"><i class="bi bi-shield-fill"></i> Admin Configuration</p>
          <div class="row g-3">
            <div class="col-sm-6">
              <label class="form-label">Admin Level</label>
              <select name="adminLevel" class="form-select">
                <option value="super"   <%= "super".equalsIgnoreCase(user.getAdminLevel())   ? "selected" : "" %>>Super Admin</option>
                <option value="manager" <%= "manager".equalsIgnoreCase(user.getAdminLevel()) ? "selected" : "" %>>Manager Admin</option>
              </select>
            </div>
            <div class="col-sm-6">
              <label class="form-label">Privileges</label>
              <input type="text" name="privileges"
                     value="<%= user.getPrivileges() != null ? user.getPrivileges() : "" %>"
                     class="form-control" placeholder="e.g. Manage Users, Approve Reports">
            </div>
          </div>
        </div>
        <% } %>

        <hr class="form-divider">
        <div class="form-actions">
          <button type="button" class="btn-form btn-form-primary" id="confirmBtn">
            <i class="bi bi-check-circle"></i> Update User
          </button>
          <a href="userList" class="btn-form btn-form-outline">
            <i class="bi bi-arrow-left"></i> Back to Staff List
          </a>
          <a href="dashboard.jsp?section=staff" class="btn-form btn-form-outline">
            <i class="bi bi-house"></i> Dashboard
          </a>
        </div>
      </form>
    </div>
  </div>
</div>

<!-- CONFIRM MODAL -->
<div class="modal fade" id="confirmModal" tabindex="-1">
  <div class="modal-dialog modal-dialog-centered">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title"><i class="bi bi-question-circle me-2"></i>Confirm Update</h5>
        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body">
        <i class="bi bi-pencil-square" style="font-size:2.2rem;color:var(--primary);display:block;margin-bottom:.75rem;"></i>
        <p class="mb-0">Are you sure you want to update <strong><%= user.getUsername() %></strong>'s details?</p>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn-modal-cancel" data-bs-dismiss="modal">Cancel</button>
        <button type="button" class="btn-modal-confirm" id="confirmUpdateBtn">
          <i class="bi bi-check-circle"></i> Yes, Update
        </button>
      </div>
    </div>
  </div>
</div>

<footer><p class="mb-0">&copy; 2026 <span>SIBS</span> &nbsp;|&nbsp; Staff Administration Portal</p></footer>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
<script>
document.getElementById('confirmBtn').addEventListener('click', function () {
  new bootstrap.Modal(document.getElementById('confirmModal')).show();
});
document.getElementById('confirmUpdateBtn').addEventListener('click', function () {
  document.getElementById('editUserForm').submit();
});

<% if ("staff".equalsIgnoreCase(user.getRole())) { %>
const currentShiftId = '<%= user.getShiftId() > 0 ? user.getShiftId() : "" %>';

function fmtTime(t) {
  if (!t) return '—';
  const [h, m] = t.split(':');
  const hour = parseInt(h, 10);
  return ((hour % 12) || 12) + ':' + m + ' ' + (hour >= 12 ? 'PM' : 'AM');
}

function updateShiftBadge(sel) {
  const opt   = sel.options[sel.selectedIndex];
  const badge = document.getElementById('shiftInfoBadge');
  if (!sel.value) {
    badge.innerHTML = '<i class="bi bi-clock me-1" style="color:var(--primary)"></i><span style="color:var(--text-muted)">No shift selected</span>';
    return;
  }
  const login  = fmtTime(opt.dataset.login);
  const logout = fmtTime(opt.dataset.logout);
  const grace  = opt.dataset.grace;
  badge.innerHTML =
    `<i class="bi bi-clock-fill me-1" style="color:var(--primary)"></i>
     <strong>${login}</strong>&nbsp;→&nbsp;<strong>${logout}</strong>
     &nbsp;<span style="color:var(--text-muted);font-size:.82rem">(${grace} min late allowance)</span>`;
  badge.style.color = 'var(--text-dark)';
}

fetch('AttendanceServlet?action=shifts')
  .then(r => r.json())
  .then(data => {
    const sel = document.getElementById('shiftIdSelect');
    sel.innerHTML = '<option value="">— No Shift Assigned —</option>' +
      data.map(s => `<option value="${s.id}"
        data-login="${s.loginTime}"
        data-logout="${s.logoutTime}"
        data-grace="${s.graceMinutes}"
        ${String(s.id) === currentShiftId ? 'selected' : ''}>${s.shiftName}</option>`).join('');
    updateShiftBadge(sel);
  })
  .catch(() => {
    document.getElementById('shiftIdSelect').innerHTML =
      '<option value="">— Could not load shifts —</option>';
  });

document.getElementById('shiftIdSelect').addEventListener('change', function () {
  updateShiftBadge(this);
});
<% } %>
</script>
</body>
</html>
