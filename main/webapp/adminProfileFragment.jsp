<%@ page contentType="text/html; charset=UTF-8" isELIgnored="true" %>
<%@ page import="com.util.User, com.DAO.UserDAO" %>
<%
    /* ══ Auth guard — return an inline error, never redirect (fragment context) ══ */
    String _role  = (session != null) ? (String) session.getAttribute("role")     : null;
    String _uname = (session != null) ? (String) session.getAttribute("username") : null;
    if (_role == null || !"admin".equalsIgnoreCase(_role)) {
        out.print("<p style='color:#ef4444;font-family:Nunito,sans-serif;padding:2rem'>"
                + "<i class='bi bi-lock me-2'></i>Access denied.</p>");
        return;
    }

    /* ── Load user from DB ── */
    UserDAO _dao  = new UserDAO();
    User    _user = _dao.getUserByUsername(_uname);

    String _email    = (_user != null && _user.getEmail()    != null) ? _user.getEmail()    : "";
    String _mobile   = (_user != null && _user.getMobileno() != null) ? _user.getMobileno() : "";
    String _address  = (_user != null && _user.getAddress()  != null) ? _user.getAddress()  : "";
    String _status   = (_user != null && _user.getStatus()   != null) ? _user.getStatus()   : "";
    String _gender   = (_user != null && _user.getGender()   != null) ? _user.getGender()   : "";
    String _level    = (_user != null && _user.getAdminLevel()!= null) ? _user.getAdminLevel() : "";
    String _privs    = (_user != null && _user.getPrivileges()!= null) ? _user.getPrivileges()  : "";
    String _joined   = (_user != null && _user.getJoiningDate()!= null)
                       ? _user.getJoiningDate().toString() : "";
    String _lastLogin= (_user != null && _user.getLastLogin()!= null)
                       ? new java.text.SimpleDateFormat("dd MMM yyyy, hh:mm a")
                             .format(_user.getLastLogin()) : "—";
    String _initials = (_uname != null && _uname.length() >= 2)
                       ? _uname.substring(0,2).toUpperCase()
                       : (_uname != null ? _uname.toUpperCase() : "AD");

    /* ── Message from redirect params ── */
    String _msg       = request.getParameter("message");
    String _pwdMsg    = request.getParameter("pwdMessage");
    boolean _msgOk    = _msg    != null && _msg.toLowerCase().contains("success");
    boolean _pwdMsgOk = _pwdMsg != null && _pwdMsg.toLowerCase().contains("success");
%>

<%-- ═══════════════════════════════════════════════════════════════════════════
     adminProfileFragment.jsp
     Loaded as an AJAX fragment into dashboard.jsp#mainContent — NO <html>/<body>.
     Inherits: Nunito font, Bootstrap 5, Bootstrap Icons, CSS vars from dashboard.
═══════════════════════════════════════════════════════════════════════════ --%>

<style>
/* ── Scoped to this fragment ── */
.apf-wrap{max-width:860px;margin:0 auto}

/* ── Page header ── */
.apf-header{display:flex;align-items:flex-start;justify-content:space-between;flex-wrap:wrap;gap:1rem;margin-bottom:1.75rem;padding-bottom:1.2rem;border-bottom:2px solid var(--border)}
.apf-title{font-family:'Nunito',sans-serif;font-size:1.5rem;font-weight:800;color:var(--text-dark);margin:0 0 .25rem;display:flex;align-items:center;gap:.55rem}
.apf-title i{color:var(--primary)}
.apf-sub{font-family:'Nunito',sans-serif;font-size:.83rem;color:var(--text-muted)}

/* ── Hero card ── */
.apf-hero{background:linear-gradient(135deg,var(--primary-dark) 0%,var(--primary) 60%,#38bdf8 100%);border-radius:var(--radius);padding:2.5rem 2rem;text-align:center;position:relative;overflow:hidden;margin-bottom:1.5rem;box-shadow:0 6px 28px rgba(14,165,233,.22)}
.apf-hero::before{content:'';position:absolute;inset:0;background:url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23fff' fill-opacity='0.04'%3E%3Cpath d='M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E")}
.apf-avatar{width:88px;height:88px;border-radius:50%;background:rgba(255,255,255,.22);border:3px solid rgba(255,255,255,.5);display:flex;align-items:center;justify-content:center;font-size:2rem;font-weight:800;color:#fff;margin:0 auto 1rem;position:relative;z-index:1;backdrop-filter:blur(4px)}
.apf-name{font-size:1.35rem;font-weight:800;color:#fff;margin:0 0 .3rem;position:relative;z-index:1}
.apf-role-pill{display:inline-flex;align-items:center;gap:.4rem;background:rgba(255,255,255,.18);border:1px solid rgba(255,255,255,.35);color:#fff;font-size:.72rem;font-weight:700;padding:.3rem .9rem;border-radius:20px;letter-spacing:.7px;text-transform:uppercase;margin-bottom:.75rem;position:relative;z-index:1}
.apf-last-login{font-size:.75rem;color:rgba(255,255,255,.75);position:relative;z-index:1}
.apf-last-login i{margin-right:.3rem}
.apf-status-dot{display:inline-block;width:8px;height:8px;border-radius:50%;background:#4ade80;margin-right:.4rem;box-shadow:0 0 0 2px rgba(74,222,128,.35);animation:pulse-dot 2s infinite}
@keyframes pulse-dot{0%,100%{box-shadow:0 0 0 2px rgba(74,222,128,.35)}50%{box-shadow:0 0 0 5px rgba(74,222,128,.15)}}

/* ── Stat strip inside hero ── */
.apf-hero-stats{display:flex;justify-content:center;gap:2.5rem;margin-top:1.25rem;position:relative;z-index:1}
.apf-hstat{text-align:center}
.apf-hstat-val{font-size:1rem;font-weight:800;color:#fff}
.apf-hstat-lbl{font-size:.65rem;color:rgba(255,255,255,.7);text-transform:uppercase;letter-spacing:.8px;margin-top:.1rem}

/* ── Two-column grid ── */
.apf-grid{display:grid;grid-template-columns:1fr 1fr;gap:1.25rem;margin-bottom:1.25rem}
@media(max-width:680px){.apf-grid{grid-template-columns:1fr}}

/* ── Card ── */
.apf-card{background:var(--bg-white);border:1px solid var(--border);border-radius:var(--radius);overflow:hidden;box-shadow:var(--shadow-sm)}
.apf-card-full{grid-column:1/-1}
.apf-card-head{display:flex;align-items:center;justify-content:space-between;padding:.95rem 1.25rem;border-bottom:1px solid var(--border);background:var(--bg-off)}
.apf-card-title{font-family:'Nunito',sans-serif;font-size:.82rem;font-weight:700;text-transform:uppercase;letter-spacing:.9px;color:var(--primary-dark);display:flex;align-items:center;gap:.45rem}
.apf-card-title i{font-size:.95rem;color:var(--primary)}
.apf-card-body{padding:1.1rem 1.25rem}

/* ── Info rows ── */
.apf-row{display:flex;align-items:flex-start;gap:.85rem;padding:.72rem 0;border-bottom:1px solid var(--border)}
.apf-row:last-child{border-bottom:none;padding-bottom:0}
.apf-row-icon{width:32px;height:32px;border-radius:8px;background:var(--primary-light);display:flex;align-items:center;justify-content:center;flex-shrink:0;font-size:.85rem;color:var(--primary)}
.apf-lbl{font-size:.7rem;font-weight:700;text-transform:uppercase;letter-spacing:.7px;color:var(--text-muted);margin-bottom:.2rem}
.apf-val{font-size:.9rem;font-weight:600;color:var(--text-dark)}
.apf-val.empty{color:var(--text-muted);font-style:italic;font-weight:400}

/* ── Status badges ── */
.apf-badge{display:inline-flex;align-items:center;gap:.3rem;font-size:.72rem;font-weight:700;padding:.25rem .75rem;border-radius:20px;letter-spacing:.4px}
.apf-badge.active{background:#dcfce7;color:#15803d;border:1px solid #bbf7d0}
.apf-badge.inactive{background:#fee2e2;color:#b91c1c;border:1px solid #fecaca}

/* ── Edit form ── */
.apf-edit-form{display:none}
.apf-edit-form.open{display:block}
.apf-form-label{font-size:.75rem;font-weight:700;color:var(--text-mid);text-transform:uppercase;letter-spacing:.6px;margin-bottom:.35rem;display:block}
.apf-input{width:100%;padding:.55rem .85rem;border:1.5px solid var(--border);border-radius:8px;font-family:'Nunito',sans-serif;font-size:.88rem;color:var(--text-dark);background:#fff;transition:border-color .18s,box-shadow .18s;outline:none}
.apf-input:focus{border-color:var(--primary);box-shadow:0 0 0 3px rgba(14,165,233,.12)}
.apf-select{appearance:none;background-image:url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%236b7280' stroke-linecap='round' stroke-linejoin='round' stroke-width='1.5' d='M6 8l4 4 4-4'/%3e%3c/svg%3e");background-repeat:no-repeat;background-position:right .65rem center;background-size:16px;padding-right:2.2rem}
.apf-btn-save{display:inline-flex;align-items:center;gap:.45rem;background:var(--primary);color:#fff;border:none;border-radius:8px;padding:.6rem 1.4rem;font-family:'Nunito',sans-serif;font-size:.85rem;font-weight:700;cursor:pointer;transition:background .18s,transform .15s}
.apf-btn-save:hover{background:var(--primary-dark);transform:translateY(-1px)}
.apf-btn-cancel{display:inline-flex;align-items:center;gap:.4rem;background:transparent;color:var(--text-muted);border:1.5px solid var(--border);border-radius:8px;padding:.58rem 1.2rem;font-family:'Nunito',sans-serif;font-size:.85rem;font-weight:600;cursor:pointer;margin-left:.5rem;transition:all .18s}
.apf-btn-cancel:hover{border-color:var(--text-muted);color:var(--text-dark)}
.apf-edit-toggle{display:inline-flex;align-items:center;gap:.35rem;font-size:.78rem;font-weight:700;color:var(--primary);background:var(--primary-light);border:1px solid rgba(14,165,233,.25);border-radius:7px;padding:.32rem .85rem;cursor:pointer;transition:all .18s;font-family:'Nunito',sans-serif}
.apf-edit-toggle:hover{background:rgba(14,165,233,.15)}

/* ── Password section ── */
.apf-pwd-strength{height:4px;border-radius:4px;background:var(--border);margin-top:.5rem;overflow:hidden}
.apf-pwd-fill{height:100%;border-radius:4px;width:0;transition:width .3s,background .3s}
.apf-pwd-label{font-size:.7rem;color:var(--text-muted);margin-top:.3rem}
.apf-pwd-match{font-size:.72rem;margin-top:.3rem}
.apf-pwd-match.ok{color:#16a34a}
.apf-pwd-match.fail{color:#dc2626}
.apf-eye-btn{position:absolute;right:10px;top:50%;transform:translateY(-50%);background:none;border:none;color:var(--text-muted);cursor:pointer;padding:0;font-size:.95rem}
.apf-input-wrap{position:relative}

/* ── Alert ── */
.apf-alert{display:flex;align-items:center;gap:.6rem;padding:.75rem 1rem;border-radius:8px;font-size:.83rem;font-weight:600;margin-bottom:1.25rem;animation:fadeUp .3s ease}
.apf-alert.ok{background:#dcfce7;color:#15803d;border:1px solid #bbf7d0}
.apf-alert.err{background:#fee2e2;color:#b91c1c;border:1px solid #fecaca}
@keyframes fadeUp{from{opacity:0;transform:translateY(6px)}to{opacity:1;transform:translateY(0)}}

/* ── Quick actions ── */
.apf-actions-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:.75rem}
@media(max-width:540px){.apf-actions-grid{grid-template-columns:repeat(2,1fr)}}
.apf-action-btn{display:flex;align-items:center;gap:.6rem;padding:.75rem 1rem;border:1.5px solid var(--border);border-radius:8px;text-decoration:none;font-family:'Nunito',sans-serif;font-size:.82rem;font-weight:600;color:var(--text-mid);background:#fff;transition:all .18s;cursor:pointer}
.apf-action-btn:hover{border-color:var(--primary);color:var(--primary-dark);background:var(--accent-light);transform:translateY(-1px)}
.apf-action-btn.danger{border-color:rgba(220,38,38,.25);color:#dc2626;background:#fff0f0}
.apf-action-btn.danger:hover{border-color:#dc2626;background:#fee2e2}
.apf-action-btn i{font-size:1rem}
</style>

<div class="apf-wrap">

  <%-- ── Alert messages ── --%>
  <% if (_msg != null && !_msg.isEmpty()) { %>
  <div class="apf-alert <%= _msgOk ? "ok" : "err" %>">
    <i class="bi bi-<%= _msgOk ? "check-circle-fill" : "exclamation-triangle-fill" %>"></i>
    <%= _msg %>
  </div>
  <% } %>
  <% if (_pwdMsg != null && !_pwdMsg.isEmpty()) { %>
  <div class="apf-alert <%= _pwdMsgOk ? "ok" : "err" %>">
    <i class="bi bi-<%= _pwdMsgOk ? "shield-check" : "x-circle-fill" %>"></i>
    <%= _pwdMsg %>
  </div>
  <% } %>

  <%-- ── Page header ── --%>
  <div class="apf-header">
    <div>
      <div class="apf-title"><i class="bi bi-person-circle"></i> My Profile</div>
      <div class="apf-sub">Manage your account details, security and quick access settings.</div>
    </div>
  </div>

  <%-- ── Hero banner ── --%>
  <div class="apf-hero">
    <div class="apf-avatar"><%= _initials %></div>
    <div class="apf-name"><%= _uname != null ? _uname : "Admin" %></div>
    <div class="apf-role-pill"><i class="bi bi-shield-fill"></i> Administrator</div>
    <div class="apf-last-login">
      <span class="apf-status-dot"></span>
      Last login: <%= _lastLogin %>
    </div>
    <div class="apf-hero-stats">
      <div class="apf-hstat">
        <div class="apf-hstat-val"><%= _status.isEmpty() ? "—" : _status.substring(0,1).toUpperCase() + _status.substring(1).toLowerCase() %></div>
        <div class="apf-hstat-lbl">Status</div>
      </div>
      <div class="apf-hstat">
        <div class="apf-hstat-val"><%= _level.isEmpty() ? "—" : _level %></div>
        <div class="apf-hstat-lbl">Level</div>
      </div>
      <div class="apf-hstat">
        <div class="apf-hstat-val"><%= _joined.isEmpty() ? "—" : _joined %></div>
        <div class="apf-hstat-lbl">Since</div>
      </div>
    </div>
  </div>

  <%-- ── Two-column grid ── --%>
  <div class="apf-grid">

    <%-- ── Contact info card ── --%>
    <div class="apf-card">
      <div class="apf-card-head">
        <span class="apf-card-title"><i class="bi bi-person-lines-fill"></i> Contact Details</span>
        <button class="apf-edit-toggle" onclick="apfToggleEdit('contact')">
          <i class="bi bi-pencil" id="apf-edit-icon-contact"></i>
          <span id="apf-edit-lbl-contact">Edit</span>
        </button>
      </div>
      <div class="apf-card-body">

        <%-- View mode --%>
        <div id="apf-view-contact">
          <div class="apf-row">
            <div class="apf-row-icon"><i class="bi bi-envelope"></i></div>
            <div>
              <div class="apf-lbl">Email Address</div>
              <div class="apf-val <%= _email.isEmpty() ? "empty" : "" %>"><%= _email.isEmpty() ? "Not set" : _email %></div>
            </div>
          </div>
          <div class="apf-row">
            <div class="apf-row-icon"><i class="bi bi-telephone"></i></div>
            <div>
              <div class="apf-lbl">Mobile Number</div>
              <div class="apf-val <%= _mobile.isEmpty() ? "empty" : "" %>"><%= _mobile.isEmpty() ? "Not set" : _mobile %></div>
            </div>
          </div>
          <div class="apf-row">
            <div class="apf-row-icon"><i class="bi bi-geo-alt"></i></div>
            <div>
              <div class="apf-lbl">Address</div>
              <div class="apf-val <%= _address.isEmpty() ? "empty" : "" %>"><%= _address.isEmpty() ? "Not set" : _address %></div>
            </div>
          </div>
          <div class="apf-row">
            <div class="apf-row-icon"><i class="bi bi-person-badge"></i></div>
            <div>
              <div class="apf-lbl">Gender</div>
              <div class="apf-val <%= _gender.isEmpty() ? "empty" : "" %>"><%= _gender.isEmpty() ? "Not set" : _gender %></div>
            </div>
          </div>
        </div>

        <%-- Edit mode --%>
        <form class="apf-edit-form" id="apf-form-contact" action="AdminProfile" method="post">
          <input type="hidden" name="action" value="updateProfile">
          <div class="mb-3">
            <label class="apf-form-label">Email Address</label>
            <input class="apf-input" type="email" name="email" value="<%= _email %>" placeholder="admin@example.com">
          </div>
          <div class="mb-3">
            <label class="apf-form-label">Mobile Number</label>
            <input class="apf-input" type="text" name="mobile" value="<%= _mobile %>" placeholder="10-digit number">
          </div>
          <div class="mb-3">
            <label class="apf-form-label">Address</label>
            <input class="apf-input" type="text" name="address" value="<%= _address %>" placeholder="Full address">
          </div>
          <div class="mb-3">
            <label class="apf-form-label">Account Status</label>
            <select class="apf-input apf-select" name="status">
              <option value="active"   <%= "active".equalsIgnoreCase(_status)   ? "selected" : "" %>>Active</option>
              <option value="inactive" <%= "inactive".equalsIgnoreCase(_status) ? "selected" : "" %>>Inactive</option>
            </select>
          </div>
          <button type="submit" class="apf-btn-save"><i class="bi bi-check-circle"></i> Save Changes</button>
          <button type="button" class="apf-btn-cancel" onclick="apfToggleEdit('contact')">Cancel</button>
        </form>
      </div>
    </div>

    <%-- ── Admin info card ── --%>
    <div class="apf-card">
      <div class="apf-card-head">
        <span class="apf-card-title"><i class="bi bi-shield-fill"></i> Admin Details</span>
      </div>
      <div class="apf-card-body">
        <div class="apf-row">
          <div class="apf-row-icon"><i class="bi bi-person"></i></div>
          <div>
            <div class="apf-lbl">Username</div>
            <div class="apf-val"><%= _uname != null ? _uname : "—" %></div>
          </div>
        </div>
        <div class="apf-row">
          <div class="apf-row-icon"><i class="bi bi-layers"></i></div>
          <div>
            <div class="apf-lbl">Admin Level</div>
            <div class="apf-val <%= _level.isEmpty() ? "empty" : "" %>"><%= _level.isEmpty() ? "Not assigned" : _level %></div>
          </div>
        </div>
        <div class="apf-row">
          <div class="apf-row-icon"><i class="bi bi-key"></i></div>
          <div>
            <div class="apf-lbl">Privileges</div>
            <div class="apf-val <%= _privs.isEmpty() ? "empty" : "" %>" style="word-break:break-word;font-size:.82rem"><%= _privs.isEmpty() ? "Not configured" : _privs %></div>
          </div>
        </div>
        <div class="apf-row">
          <div class="apf-row-icon"><i class="bi bi-calendar3"></i></div>
          <div>
            <div class="apf-lbl">Joined On</div>
            <div class="apf-val <%= _joined.isEmpty() ? "empty" : "" %>"><%= _joined.isEmpty() ? "Not recorded" : _joined %></div>
          </div>
        </div>
        <div class="apf-row">
          <div class="apf-row-icon"><i class="bi bi-circle-fill" style="font-size:.65rem"></i></div>
          <div>
            <div class="apf-lbl">Account Status</div>
            <div>
              <span class="apf-badge <%= "active".equalsIgnoreCase(_status) ? "active" : "inactive" %>">
                <i class="bi bi-<%= "active".equalsIgnoreCase(_status) ? "check-circle-fill" : "x-circle-fill" %>"></i>
                <%= _status.isEmpty() ? "Unknown" : _status.substring(0,1).toUpperCase() + _status.substring(1).toLowerCase() %>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <%-- ── Change password card (full width) ── --%>
    <div class="apf-card apf-card-full">
      <div class="apf-card-head">
        <span class="apf-card-title"><i class="bi bi-shield-lock-fill"></i> Change Password</span>
        <button class="apf-edit-toggle" onclick="apfTogglePwd()">
          <i class="bi bi-key" id="apf-pwd-icon"></i>
          <span id="apf-pwd-lbl">Change</span>
        </button>
      </div>
      <div id="apf-pwd-section" class="apf-edit-form" style="padding:1.1rem 1.25rem">
        <form action="AdminProfile" method="post" id="apf-pwd-form" onsubmit="return apfValidatePwd()">
          <input type="hidden" name="action" value="changePassword">
          <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:1rem">
            <div>
              <label class="apf-form-label">Current Password</label>
              <div class="apf-input-wrap">
                <input class="apf-input" type="password" name="currentPassword" id="apfCurPwd" placeholder="Your current password" required>
                <button type="button" class="apf-eye-btn" onclick="apfToggleVis('apfCurPwd','apfEye0')"><i class="bi bi-eye" id="apfEye0"></i></button>
              </div>
            </div>
            <div>
              <label class="apf-form-label">New Password</label>
              <div class="apf-input-wrap">
                <input class="apf-input" type="password" name="newPassword" id="apfNewPwd" placeholder="Minimum 8 characters" required minlength="8" oninput="apfStrength(this.value)">
                <button type="button" class="apf-eye-btn" onclick="apfToggleVis('apfNewPwd','apfEye1')"><i class="bi bi-eye" id="apfEye1"></i></button>
              </div>
              <div class="apf-pwd-strength"><div class="apf-pwd-fill" id="apfStrFill"></div></div>
              <div class="apf-pwd-label" id="apfStrLbl"></div>
            </div>
            <div>
              <label class="apf-form-label">Confirm New Password</label>
              <div class="apf-input-wrap">
                <input class="apf-input" type="password" name="confirmPassword" id="apfConfPwd" placeholder="Repeat new password" required oninput="apfCheckMatch()">
                <button type="button" class="apf-eye-btn" onclick="apfToggleVis('apfConfPwd','apfEye2')"><i class="bi bi-eye" id="apfEye2"></i></button>
              </div>
              <div class="apf-pwd-match" id="apfMatchMsg"></div>
            </div>
          </div>
          <div style="margin-top:1.25rem">
            <button type="submit" class="apf-btn-save"><i class="bi bi-shield-check"></i> Update Password</button>
            <button type="button" class="apf-btn-cancel" onclick="apfTogglePwd()">Cancel</button>
          </div>
        </form>
      </div>
    </div>

    <%-- ── Quick actions card (full width) ── --%>
    <div class="apf-card apf-card-full">
      <div class="apf-card-head">
        <span class="apf-card-title"><i class="bi bi-lightning-fill"></i> Quick Actions</span>
      </div>
      <div class="apf-card-body">
        <div class="apf-actions-grid">
          <a href="userList.jsp" class="apf-action-btn"><i class="bi bi-people" style="color:var(--primary)"></i> Manage Users</a>
          <a href="addUser.jsp" class="apf-action-btn"><i class="bi bi-person-plus" style="color:#16a34a"></i> Add Staff</a>
          <a href="StaffDashboard" class="apf-action-btn ajax-link"><i class="bi bi-grid" style="color:#7c3aed"></i> Staff Dashboard</a>
          <a href="ReportsDashboard" class="apf-action-btn ajax-link"><i class="bi bi-bar-chart-line" style="color:#ea580c"></i> Reports</a>
          <a href="BillsPage" class="apf-action-btn ajax-link"><i class="bi bi-receipt" style="color:#0369a1"></i> Billing</a>
          <a href="logout" class="apf-action-btn danger"><i class="bi bi-box-arrow-right"></i> Logout</a>
        </div>
      </div>
    </div>

  </div><%-- /apf-grid --%>
</div><%-- /apf-wrap --%>

<script>
/* ── Toggle edit form ── */
function apfToggleEdit(section){
  var view = document.getElementById('apf-view-'+section);
  var form = document.getElementById('apf-form-'+section);
  var lbl  = document.getElementById('apf-edit-lbl-'+section);
  var icon = document.getElementById('apf-edit-icon-'+section);
  var open = form.classList.toggle('open');
  view.style.display = open ? 'none' : '';
  lbl.textContent    = open ? 'Cancel' : 'Edit';
  icon.className     = open ? 'bi bi-x' : 'bi bi-pencil';
}

/* ── Toggle password panel ── */
function apfTogglePwd(){
  var sec  = document.getElementById('apf-pwd-section');
  var lbl  = document.getElementById('apf-pwd-lbl');
  var icon = document.getElementById('apf-pwd-icon');
  var open = sec.classList.toggle('open');
  lbl.textContent = open ? 'Cancel' : 'Change';
  icon.className  = open ? 'bi bi-x' : 'bi bi-key';
}

/* ── Password strength meter ── */
function apfStrength(pw){
  var score = 0;
  if(pw.length >= 8)  score++;
  if(/[A-Z]/.test(pw))score++;
  if(/[0-9]/.test(pw))score++;
  if(/[^A-Za-z0-9]/.test(pw))score++;
  var fill = document.getElementById('apfStrFill');
  var lbl  = document.getElementById('apfStrLbl');
  var colors = ['#ef4444','#f59e0b','#3b82f6','#22c55e'];
  var labels = ['Weak','Fair','Good','Strong'];
  fill.style.width      = ((score/4)*100)+'%';
  fill.style.background = colors[score-1]||'#e2e8f0';
  lbl.textContent       = score > 0 ? labels[score-1] : '';
  lbl.style.color       = colors[score-1]||'var(--text-muted)';
}

/* ── Confirm match ── */
function apfCheckMatch(){
  var np = document.getElementById('apfNewPwd').value;
  var cp = document.getElementById('apfConfPwd').value;
  var el = document.getElementById('apfMatchMsg');
  if(!cp){ el.textContent=''; return; }
  el.textContent = np===cp ? '✓ Passwords match' : '✗ Passwords do not match';
  el.className   = 'apf-pwd-match '+(np===cp?'ok':'fail');
}

/* ── Validate before submit ── */
function apfValidatePwd(){
  var np = document.getElementById('apfNewPwd').value;
  var cp = document.getElementById('apfConfPwd').value;
  if(np !== cp){ alert('New passwords do not match.'); return false; }
  if(np.length < 8){ alert('Password must be at least 8 characters.'); return false; }
  return true;
}

/* ── Show/hide password ── */
function apfToggleVis(fieldId, iconId){
  var f = document.getElementById(fieldId);
  var i = document.getElementById(iconId);
  if(f.type==='password'){ f.type='text';  i.className='bi bi-eye-slash'; }
  else                   { f.type='password'; i.className='bi bi-eye';   }
}
</script>
