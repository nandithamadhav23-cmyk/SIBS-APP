<%@ page import="java.sql.*,com.util.*,java.util.*" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<%
    /* ── AUTH CHECK first — before any output ── */
    String role  = (session != null) ? (String) session.getAttribute("role")     : null;
    String uname = (session != null) ? (String) session.getAttribute("username") : null;
    if (role == null || !"admin".equalsIgnoreCase(role)) {
        response.sendRedirect("index.jsp?error=Access denied. Please login as admin.");
        return;
    }

    /* ── PAGINATION & SEARCH params ── */
    int pageSize    = 10;
    int currentPage = 1;
    if (request.getParameter("page") != null) {
        try { currentPage = Integer.parseInt(request.getParameter("page")); }
        catch (NumberFormatException ignored) {}
    }
    if (currentPage < 1) currentPage = 1;

    int    offset = (currentPage - 1) * pageSize;
    String search = request.getParameter("search");
    if (search == null) search = "";

    /* ── DB QUERY (BUG FIX: use try-with-resources so connections are always closed) ── */
    int    totalUsers = 0;
    int    totalPages = 1;
    List<User> pageUsers = new ArrayList<>();

    try (Connection con = DBConnection.getConnection()) {

        // Count query
        try (PreparedStatement psCount = con.prepareStatement(
                "SELECT COUNT(*) FROM users WHERE username LIKE ? OR email LIKE ?")) {
            psCount.setString(1, "%" + search + "%");
            psCount.setString(2, "%" + search + "%");
            try (ResultSet rsCount = psCount.executeQuery()) {
                if (rsCount.next()) totalUsers = rsCount.getInt(1);
            }
        }
        totalPages = (int) Math.ceil(totalUsers / (double) pageSize);
        if (totalPages < 1) totalPages = 1;

        // Data query — fetch all needed columns including shift_id
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT username, email, mobile, country_code, role, status, address, gender, " +
                "employee_id, department, shift_id, supervisor, joining_date, " +
                "admin_level, privileges " +
                "FROM users WHERE username LIKE ? OR email LIKE ? LIMIT ? OFFSET ?")) {
            ps.setString(1, "%" + search + "%");
            ps.setString(2, "%" + search + "%");
            ps.setInt(3, pageSize);
            ps.setInt(4, offset);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    User u = new User();
                    u.setUsername(rs.getString("username"));
                    u.setEmail(rs.getString("email"));
                    u.setMobileno(rs.getString("mobile"));
                    u.setCountryCode(rs.getString("country_code"));
                    u.setRole(rs.getString("role"));
                    u.setStatus(rs.getString("status"));
                    u.setAddress(rs.getString("address"));
                    u.setGender(rs.getString("gender"));
                    u.setEmployeeId(rs.getString("employee_id"));
                    u.setDepartment(rs.getString("department"));
                    int sid = rs.getInt("shift_id");
                    if (!rs.wasNull()) u.setShiftId(sid);
                    u.setSupervisor(rs.getString("supervisor"));
                    u.setJoiningDate(rs.getDate("joining_date"));
                    u.setAdminLevel(rs.getString("admin_level"));
                    u.setPrivileges(rs.getString("privileges"));
                    pageUsers.add(u);
                }
            }
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>User Management — SIBS Admin</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
  <link href="https://fonts.googleapis.com/css2?family=Nunito:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
  <style>
    :root {
      --primary:#0ea5e9; --primary-dark:#0369a1; --accent:#38bdf8; --accent-light:#e0f2fe;
      --text-dark:#0c1a2e; --text-mid:#1e3a5f; --text-muted:#64748b;
      --border:#dbeafe; --bg-white:#ffffff; --bg-off:#f0f9ff;
      --shadow-sm:0 2px 12px rgba(14,165,233,.08);
      --shadow-md:0 4px 24px rgba(14,165,233,.13);
      --shadow-lg:0 12px 40px rgba(14,165,233,.18);
      --navbar-height:64px;
    }
    *, *::before, *::after { box-sizing:border-box; }
    body {
      font-family:'Nunito',sans-serif;
      background:var(--bg-off); color:var(--text-dark);
      min-height:100vh; padding-top:var(--navbar-height);
    }

    /* ── NAVBAR ── */
    .top-navbar {
      position:fixed; top:0; left:0; right:0; height:var(--navbar-height);
      background:var(--primary); border-bottom:none;
      display:flex; align-items:center; padding:0 1.5rem; z-index:1050; gap:1rem;
      box-shadow:0 2px 16px rgba(14,165,233,.25);
    }
    .nav-brand { font-family:'Nunito',sans-serif; font-size:1.2rem; font-weight:800; color:#fff; letter-spacing:.5px; text-decoration:none; }
    .nav-brand span { color:#bae6fd; font-weight:300; }
    .nav-right { margin-left:auto; display:flex; align-items:center; gap:1rem; }
    .nav-welcome { font-size:.88rem; color:rgba(255,255,255,.9); }
    .nav-welcome strong { color:#fff; font-weight:700; }
    .badge-role {
      background:rgba(255,255,255,.18); color:#fff;
      border:1px solid rgba(255,255,255,.35); font-size:.68rem;
      letter-spacing:1px; text-transform:uppercase; padding:.2rem .65rem; border-radius:20px; font-weight:600;
    }
    .btn-nav {
      font-size:.78rem; font-weight:600; letter-spacing:.5px;
      padding:.4rem 1rem; border:1.5px solid rgba(255,255,255,.35);
      border-radius:20px; color:#fff; text-decoration:none; transition:all .2s;
    }
    .btn-nav:hover { background:rgba(255,255,255,.18); border-color:#fff; color:#fff; }

    /* ── PAGE ── */
    .page-container { padding:2rem 1.5rem; }
    .page-header {
      background:var(--bg-white); border:1px solid var(--border); border-top:4px solid var(--primary);
      border-radius:12px; padding:1.4rem 1.6rem; display:flex; align-items:center;
      justify-content:space-between; flex-wrap:wrap; gap:1rem; margin-bottom:1.5rem;
      box-shadow:var(--shadow-sm);
    }
    .page-title { font-size:1.3rem; font-weight:800; color:var(--text-dark); margin:0; }
    .page-title i { color:var(--primary); margin-right:.5rem; }

    /* ── SEARCH ── */
    .search-group { display:flex; align-items:center; gap:.5rem; }
    .search-input {
      border:1.5px solid var(--border); border-radius:9px; padding:.48rem .85rem;
      font-family:'Nunito',sans-serif; font-size:.9rem;
      color:var(--text-dark); width:220px; transition:border-color .2s;
    }
    .search-input:focus { border-color:var(--primary); outline:none; box-shadow:0 0 0 3px rgba(14,165,233,.12); }
    .btn-search {
      background:var(--primary); color:#fff; border:none;
      font-family:'Nunito',sans-serif; font-size:.82rem; font-weight:600;
      letter-spacing:.5px; padding:.48rem 1.1rem; border-radius:9px;
      text-decoration:none; display:inline-flex; align-items:center; gap:.35rem; transition:all .2s;
    }
    .btn-search:hover { background:var(--primary-dark); color:#fff; transform:translateY(-1px); }

    /* ── TABLE CARD ── */
    .table-card {
      background:var(--bg-white); border:1px solid var(--border);
      border-radius:12px; box-shadow:var(--shadow-sm); overflow:hidden;
    }
    .table-stats {
      padding:.8rem 1.4rem; border-bottom:1px solid var(--border);
      font-size:.82rem; font-weight:500; color:var(--text-muted); display:flex; align-items:center; gap:.5rem;
    }
    .table-stats strong { color:var(--text-dark); font-weight:700; }
    .table-responsive { overflow-x:auto; }

    table { width:100%; border-collapse:collapse; font-family:'Nunito',sans-serif; }
    thead tr { background:var(--primary-dark); }
    thead th {
      padding:.85rem 1rem; font-size:.68rem; font-weight:700;
      letter-spacing:1px; text-transform:uppercase; color:rgba(255,255,255,.9);
      text-align:left; white-space:nowrap;
    }
    thead th:first-child { padding-left:1.4rem; }
    thead th:last-child { text-align:center; }
    tbody tr { border-bottom:1px solid var(--border); transition:background .15s; }
    tbody tr:last-child { border-bottom:none; }
    tbody tr:hover { background:var(--accent-light); }
    tbody tr:nth-child(even) { background:#f8faff; }
    tbody tr:nth-child(even):hover { background:var(--accent-light); }
    td { padding:.75rem 1rem; font-size:.9rem; color:var(--text-dark); vertical-align:middle; }
    td:first-child { padding-left:1.4rem; font-weight:600; }
    td:last-child { text-align:center; }

    /* ── BADGES ── */
    .badge-custom {
      font-size:.68rem; font-weight:700; letter-spacing:.5px; text-transform:uppercase;
      padding:.28rem .75rem; border-radius:20px;
    }
    .badge-admin    { background:#dbeafe; color:#0369a1; }
    .badge-staff    { background:#e0f2fe; color:#0ea5e9; }
    .badge-delivery { background:#fef3c7; color:#b45309; }
    .badge-user     { background:#f1f5f9; color:#64748b; }
    .badge-active   { background:#dcfce7; color:#16a34a; }
    .badge-inactive { background:#fee2e2; color:#b91c1c; }
    .badge-pending  { background:#fef3c7; color:#b45309; }

    /* ── ACTION BTNS ── */
    .action-btns { display:flex; align-items:center; justify-content:center; gap:.4rem; }
    .btn-tbl {
      font-size:.72rem; font-weight:600; letter-spacing:.3px;
      padding:.32rem .75rem; border-radius:7px; cursor:pointer; transition:all .2s;
      border:1.5px solid transparent; text-decoration:none;
      display:inline-flex; align-items:center; gap:.3rem;
    }
    .btn-tbl-view   { border-color:var(--primary); color:var(--primary); background:var(--accent-light); }
    .btn-tbl-view:hover { background:var(--primary); color:#fff; }
    .btn-tbl-edit   { border-color:#f59e0b; color:#b45309; background:#fef3c7; }
    .btn-tbl-edit:hover { background:#f59e0b; color:#fff; }
    .btn-tbl-delete { border-color:#fca5a5; color:#b91c1c; background:#fee2e2; }
    .btn-tbl-delete:hover { background:#ef4444; color:#fff; border-color:#ef4444; }

    /* ── PAGINATION ── */
    .pagination { margin-top:1.5rem; justify-content:center; }
    .page-link {
      font-family:'Nunito',sans-serif; font-size:.85rem; font-weight:600; color:var(--text-dark);
      border:1.5px solid var(--border); padding:.4rem .9rem; border-radius:8px; transition:all .2s;
    }
    .page-link:hover { background:var(--accent-light); border-color:var(--primary); color:var(--primary); }
    .page-item.active .page-link { background:var(--primary); border-color:var(--primary); color:#fff; }
    .page-item.disabled .page-link { color:var(--text-muted); pointer-events:none; }

    /* ── MODAL ── */
    .modal-content { border:none; border-radius:16px; font-family:'Nunito',sans-serif; box-shadow:var(--shadow-lg); }
    .modal-header  { background:linear-gradient(135deg,var(--primary-dark),var(--primary)); border-top:none; border-radius:16px 16px 0 0; padding:1.1rem 1.5rem; }
    .modal-title   { font-size:.95rem; font-weight:700; color:#fff; letter-spacing:.5px; }
    .modal-body    { padding:1.5rem; }
    .modal-footer  { padding:1rem 1.5rem; border-top:1px solid var(--border); background:var(--bg-off); }
    .modal-info-row {
      display:flex; padding:.65rem 0; border-bottom:1px solid var(--border); font-size:.88rem;
    }
    .modal-info-row:last-child { border-bottom:none; }
    .modal-info-label { width:140px; flex-shrink:0; font-size:.72rem; font-weight:700; letter-spacing:.5px; text-transform:uppercase; color:var(--text-muted); }
    .modal-info-value { color:var(--text-dark); font-weight:600; }

    .btn-modal-close {
      font-size:.78rem; font-weight:600; letter-spacing:.3px;
      padding:.45rem 1.2rem; border:1.5px solid var(--border); border-radius:9px;
      color:var(--text-mid); background:transparent; cursor:pointer; transition:all .2s;
    }
    .btn-modal-close:hover { border-color:var(--primary); color:var(--primary); background:var(--accent-light); }

    /* ── TOAST ── */
    .toast-custom { font-family:'Nunito',sans-serif; font-size:.9rem; font-weight:500; border-radius:10px; box-shadow:var(--shadow-md); }

    /* ── FOOTER ── */
    footer { background:var(--primary-dark); color:rgba(255,255,255,.65); font-family:'Nunito',sans-serif; font-size:.82rem; font-weight:500; text-align:center; padding:1rem; margin-top:2rem; }
    footer span { color:#bae6fd; font-weight:700; }

    /* ── RESPONSIVE ── */
    @media(max-width:768px) {
      .nav-welcome, .badge-role { display:none; }
      .page-header { flex-direction:column; align-items:flex-start; }
      .search-group { width:100%; flex-wrap:wrap; }
      .search-input { width:100%; }
    }
  </style>
</head>
<body>

<!-- NAVBAR -->
<div class="top-navbar">
  <a class="nav-brand" href="dashboard.jsp?section=staff">SIBS <span>Staff Portal</span></a>
  <div class="nav-right">
    <span class="nav-welcome">Welcome, <strong><%= uname %></strong></span>
    <span class="badge-role"><%= role %></span>
    <a href="dashboard.jsp?section=staff" class="btn-nav"><i class="bi bi-people me-1"></i>Staff Dashboard</a>
    <a href="logout" class="btn-nav"><i class="bi bi-box-arrow-right me-1"></i>Logout</a>
  </div>
</div>

<div class="page-container">

  <!-- Page Header -->
  <div class="page-header">
    <h3 class="page-title"><i class="bi bi-people"></i>User Management</h3>
    <div style="display:flex; gap:.75rem; align-items:center; flex-wrap:wrap;">
      <a href="dashboard.jsp?section=staff" class="btn-search" style="background:transparent;color:var(--primary);border-color:var(--primary);"><i class="bi bi-arrow-left"></i> Dashboard</a>
          <a href="addUser.jsp" class="btn-search" style="background:var(--accent);border-color:var(--accent);color:var(--primary);">
        <i class="bi bi-person-plus-fill"></i> Add User
      </a>
      <form class="search-group" action="userList" method="get">
        <input type="text" name="search" class="search-input"
               placeholder="Search by name or email…" value="<%= search %>">
        <button type="submit" class="btn-search"><i class="bi bi-search"></i> Search</button>
        <% if (!search.isEmpty()) { %>
          <a href="userList" class="btn-search" style="background:transparent;color:var(--text-muted);border-color:var(--border);">
            <i class="bi bi-x-circle"></i> Clear
          </a>
        <% } %>
      </form>
    </div>
  </div>

  <!-- Table Card -->
  <div class="table-card">
    <div class="table-stats">
      Showing <strong><%= Math.min(offset + pageSize, totalUsers) - offset %></strong>
      of <strong><%= totalUsers %></strong> user<%= totalUsers != 1 ? "s" : "" %>
      <% if (!search.isEmpty()) { %>&nbsp;&mdash;&nbsp; filtered by "<strong><%= search %></strong>"<% } %>
    </div>
    <div class="table-responsive">
      <table>
        <thead>
          <tr>
            <th>#</th>
            <th>Username</th>
            <th>Email</th>
            <th>Mobile</th>
            <th>Role</th>
            <th>Gender</th>
            <th>Status</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          <%
            int srNo = offset + 1;
            for (User us : pageUsers) {
              String u_username  = us.getUsername()   != null ? us.getUsername()   : "";
              String u_email     = us.getEmail()      != null ? us.getEmail()      : "";
              String u_mobile    = us.getMobileno()   != null ? us.getMobileno()   : "";
              String u_cc       = us.getCountryCode() != null ? us.getCountryCode() : "";
              String u_role      = us.getRole()       != null ? us.getRole()       : "user";
              String u_status    = us.getStatus()     != null ? us.getStatus()     : "";
              String u_address   = us.getAddress()    != null ? us.getAddress()    : "";
              String u_gender    = us.getGender()     != null ? us.getGender()     : "";
              String u_eid       = us.getEmployeeId() != null ? us.getEmployeeId() : "";
              String u_dept      = us.getDepartment() != null ? us.getDepartment() : "";
              String u_shiftId   = us.getShiftId() > 0 ? String.valueOf(us.getShiftId()) : "";
              String u_supervisor= us.getSupervisor()  != null ? us.getSupervisor()  : "";
              String u_joining   = us.getJoiningDate() != null ? us.getJoiningDate().toString() : "";
              String u_adminlvl  = us.getAdminLevel()  != null ? us.getAdminLevel()  : "";
              String u_privs     = us.getPrivileges()  != null ? us.getPrivileges()  : "";
          %>
          <tr>
            <td style="color:var(--text-muted);"><%= srNo++ %></td>
            <td><i class="bi bi-person-circle me-1" style="color:var(--accent);"></i><%= u_username %></td>
            <td style="color:var(--text-mid);"><%= !u_email.isEmpty() ? u_email : "—" %></td>
            <td style="color:var(--text-mid);"><%= !u_mobile.isEmpty() ? u_cc + " " + u_mobile : "—" %></td>
            <td>
              <span class="badge-custom badge-<%= u_role.toLowerCase() %>"><%= u_role %></span>
            </td>
            <td style="color:var(--text-mid);"><%= !u_gender.isEmpty() ? u_gender : "—" %></td>
            <td>
              <%
                String statusClass = "active".equalsIgnoreCase(u_status) ? "active"
                                   : "inactive".equalsIgnoreCase(u_status) ? "inactive" : "pending";
              %>
              <span class="badge-custom badge-<%= statusClass %>"><%= !u_status.isEmpty() ? u_status : "Unknown" %></span>
            </td>
            <td>
              <div class="action-btns">
                <!-- View: BUG FIX — removed duplicate data-shift, added data-privileges properly -->
                <button class="btn-tbl btn-tbl-view"
                        data-bs-toggle="modal" data-bs-target="#userModal"
                        data-username="<%= u_username %>"
                        data-email="<%= u_email %>"
                        data-mobile="<%= u_cc + (u_mobile.isEmpty() ? "" : " " + u_mobile) %>"
                        data-role="<%= u_role %>"
                        data-status="<%= u_status %>"
                        data-address="<%= u_address %>"
                        data-gender="<%= u_gender %>"
                        data-eid="<%= u_eid %>"
                        data-dept="<%= u_dept %>"
                        data-shift-id="<%= u_shiftId %>"
                        data-supervisor="<%= u_supervisor %>"
                        data-joining-date="<%= u_joining %>"
                        data-admin-level="<%= u_adminlvl %>"
                        data-privileges="<%= u_privs %>">
                  <i class="bi bi-eye"></i> View
                </button>
                <!-- Edit -->
                <a href="EditUser?username=<%= u_username %>" class="btn-tbl btn-tbl-edit">
                  <i class="bi bi-pencil"></i> Edit
                </a>
                <!-- Delete -->
                <form action="DeleteUserServlet" method="post"
                      onsubmit="return confirm('Delete user «<%= u_username %>»? This cannot be undone.');"
                      style="display:inline;">
                  <input type="hidden" name="username" value="<%= u_username %>">
                  <button type="submit" class="btn-tbl btn-tbl-delete">
                    <i class="bi bi-trash"></i>
                  </button>
                </form>
              </div>
            </td>
          </tr>
          <% } %>
          <% if (pageUsers.isEmpty()) { %>
          <tr>
            <td colspan="8" style="text-align:center;padding:2rem;color:var(--text-muted);">
              <i class="bi bi-inbox" style="font-size:1.5rem;display:block;margin-bottom:.5rem;"></i>
              No users found<% if (!search.isEmpty()) { %> matching "<strong><%= search %></strong>"<% } %>.
            </td>
          </tr>
          <% } %>
        </tbody>
      </table>
    </div>
  </div>

  <!-- Pagination — BUG FIX: next-page URL had a JSP expression inside a string literal -->
  <nav>
    <ul class="pagination">
      <li class="page-item <%= (currentPage == 1) ? "disabled" : "" %>">
        <a class="page-link" href="userList?page=<%= currentPage - 1 %>&search=<%= search %>">
          <i class="bi bi-chevron-left"></i>
        </a>
      </li>
      <% for (int i = 1; i <= totalPages; i++) { %>
        <li class="page-item <%= (i == currentPage) ? "active" : "" %>">
          <a class="page-link" href="userList?page=<%= i %>&search=<%= search %>"><%= i %></a>
        </li>
      <% } %>
      <!-- BUG FIX: was href="userList?page: <%=(currentPage+1) %> & search=<%= search %>"
           (colon instead of equals, space before &) — corrected below -->
      <li class="page-item <%= (currentPage >= totalPages) ? "disabled" : "" %>">
        <a class="page-link" href="userList?page=<%= currentPage + 1 %>&search=<%= search %>">
          <i class="bi bi-chevron-right"></i>
        </a>
      </li>
    </ul>
  </nav>

</div>

<!-- Footer -->
<footer>
  <p class="mb-0">&copy; 2026 <span>SIBS</span> &nbsp;|&nbsp; Administrator Portal</p>
</footer>

<!-- User Detail Modal -->
<div class="modal fade" id="userModal" tabindex="-1">
  <div class="modal-dialog modal-dialog-centered" style="max-width:540px;">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title"><i class="bi bi-person-lines-fill me-2" style="color:var(--accent);"></i>User Details</h5>
        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body" id="modalBody">
        <div class="modal-info-row"><span class="modal-info-label">Username</span><span class="modal-info-value" id="modalUsername"></span></div>
        <div class="modal-info-row"><span class="modal-info-label">Email</span><span class="modal-info-value" id="modalEmail"></span></div>
        <div class="modal-info-row"><span class="modal-info-label">Mobile</span><span class="modal-info-value" id="modalMobile"></span></div>
        <div class="modal-info-row"><span class="modal-info-label">Role</span><span class="modal-info-value" id="modalRole"></span></div>
        <div class="modal-info-row"><span class="modal-info-label">Status</span><span class="modal-info-value" id="modalStatus"></span></div>
        <div class="modal-info-row"><span class="modal-info-label">Gender</span><span class="modal-info-value" id="modalGender"></span></div>
        <div class="modal-info-row"><span class="modal-info-label">Address</span><span class="modal-info-value" id="modalAddress"></span></div>
        <!-- Staff fields -->
        <div class="modal-info-row" id="rowEid"><span class="modal-info-label">Employee ID</span><span class="modal-info-value" id="modalEmployeeId"></span></div>
        <div class="modal-info-row" id="rowDept"><span class="modal-info-label">Department</span><span class="modal-info-value" id="modalDepartment"></span></div>
        <div class="modal-info-row" id="rowShift"><span class="modal-info-label">Shift ID</span><span class="modal-info-value" id="modalShiftId"></span></div>
        <div class="modal-info-row" id="rowSupervisor"><span class="modal-info-label">Supervisor</span><span class="modal-info-value" id="modalSupervisor"></span></div>
        <div class="modal-info-row" id="rowJoining"><span class="modal-info-label">Joining Date</span><span class="modal-info-value" id="modalJoiningDate"></span></div>
        <!-- Admin fields -->
        <div class="modal-info-row" id="rowAdminLevel"><span class="modal-info-label">Admin Level</span><span class="modal-info-value" id="modalAdminLevel"></span></div>
        <div class="modal-info-row" id="rowPrivileges"><span class="modal-info-label">Privileges</span><span class="modal-info-value" id="modalPrivileges"></span></div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn-modal-close" data-bs-dismiss="modal"><i class="bi bi-x me-1"></i>Close</button>
      </div>
    </div>
  </div>
</div>

<!-- Toasts -->
<div class="position-fixed bottom-0 end-0 p-3" style="z-index:1100;">
  <% if (request.getParameter("msg") != null) { %>
    <div class="toast align-items-center border-0 toast-custom bg-success text-white" role="alert">
      <div class="d-flex">
        <div class="toast-body"><i class="bi bi-check-circle-fill me-2"></i><%= request.getParameter("msg") %></div>
        <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button>
      </div>
    </div>
  <% } %>
  <% if (request.getParameter("error") != null) { %>
    <div class="toast align-items-center border-0 toast-custom bg-danger text-white" role="alert">
      <div class="d-flex">
        <div class="toast-body"><i class="bi bi-exclamation-triangle-fill me-2"></i><%= request.getParameter("error") %></div>
        <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button>
      </div>
    </div>
  <% } %>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
<script>
  // Auto-show toasts
  document.addEventListener('DOMContentLoaded', function () {
    document.querySelectorAll('.toast').forEach(el => new bootstrap.Toast(el, { delay: 4000 }).show());
  });

  // Populate modal
  document.getElementById('userModal').addEventListener('show.bs.modal', function (event) {
    const btn = event.relatedTarget;

    document.getElementById('modalUsername').textContent   = btn.dataset.username  || '—';
    document.getElementById('modalEmail').textContent      = btn.dataset.email     || '—';
    document.getElementById('modalMobile').textContent     = btn.dataset.mobile    || '—';
    document.getElementById('modalRole').textContent       = btn.dataset.role      || '—';
    document.getElementById('modalStatus').textContent     = btn.dataset.status    || '—';
    document.getElementById('modalGender').textContent     = btn.dataset.gender    || '—';
    document.getElementById('modalAddress').textContent    = btn.dataset.address   || '—';

    // Staff
    document.getElementById('modalEmployeeId').textContent = btn.dataset.eid         || '—';
    document.getElementById('modalDepartment').textContent = btn.dataset.dept        || '—';
    document.getElementById('modalShiftId').textContent    = btn.dataset.shiftId     || '—';
    document.getElementById('modalSupervisor').textContent = btn.dataset.supervisor  || '—';
    document.getElementById('modalJoiningDate').textContent= btn.dataset.joiningDate || '—';

    // Admin — BUG FIX: was reading data-privileges from wrong attribute (was data-shift)
    document.getElementById('modalAdminLevel').textContent = btn.dataset.adminLevel  || '—';
    document.getElementById('modalPrivileges').textContent = btn.dataset.privileges  || '—';

    const r = (btn.dataset.role || '').toLowerCase();
    const staffIds = ['rowEid','rowDept','rowShift','rowSupervisor','rowJoining'];
    const adminIds = ['rowAdminLevel','rowPrivileges'];
    staffIds.forEach(id => document.getElementById(id).style.display = r === 'staff'   ? 'flex' : 'none');
    adminIds.forEach(id => document.getElementById(id).style.display = r === 'admin'   ? 'flex' : 'none');
  });
</script>
</body>
</html>
