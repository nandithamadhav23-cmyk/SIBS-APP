package com.servlet;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Types;
import java.time.format.DateTimeFormatter;

import com.DAO.AttendanceDAO;
import com.DAO.UserDAO;
import com.util.DBConnection;
import com.util.EmailUtil;
import com.util.OfficeShift;
import com.util.User;

import jakarta.servlet.ServletContext;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@WebServlet("/EditUser")
public class EditUserServlet extends HttpServlet {

	private static final long serialVersionUID = 7053014663571786053L;

	private static final String PORTAL_URL = "http://localhost:8085/SampleApp/";
	private static final String HR_EMAIL = "hr@sibs.in";
	private static final DateTimeFormatter TIME_FMT = DateTimeFormatter.ofPattern("hh:mm a");

	// ── GET: load user into editUser.jsp ──────────────────────────────────────
	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		String username = request.getParameter("username");
		User user = new User();

		try (Connection con = DBConnection.getConnection();
				PreparedStatement ps = con.prepareStatement("SELECT * FROM users WHERE username=?")) {
			ps.setString(1, username);
			try (ResultSet rs = ps.executeQuery()) {
				if (rs.next()) {
					user.setUsername(rs.getString("username"));
					user.setEmail(rs.getString("email"));
					user.setMobileno(rs.getString("mobile"));
					user.setCountryCode(rs.getString("country_code"));
					user.setRole(rs.getString("role"));
					user.setStatus(rs.getString("status"));
					user.setAddress(rs.getString("address"));
					user.setGender(rs.getString("gender"));

					// Staff-specific
					user.setEmployeeId(rs.getString("employee_id"));
					user.setDepartment(rs.getString("department"));
					int shiftId = rs.getInt("shift_id");
					if (!rs.wasNull()) {
						user.setShiftId(shiftId);
					}
					user.setSupervisor(rs.getString("supervisor"));
					user.setJoiningDate(rs.getDate("joining_date"));

					// Admin-specific
					user.setAdminLevel(rs.getString("admin_level"));
					user.setPrivileges(rs.getString("privileges"));
				}
			}
		} catch (Exception e) {
			e.printStackTrace();
		}

		request.setAttribute("user", user);
		request.getRequestDispatcher("editUser.jsp").forward(request, response);
	}

	// ── POST: persist changes and email staff ─────────────────────────────────
	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		String username = request.getParameter("username");
		String email = request.getParameter("email");
		String mobile = request.getParameter("mobile");
		String countryCode = request.getParameter("countryCode");
		String role = request.getParameter("role");
		String status = request.getParameter("status");
		String address = request.getParameter("address");
		String gender = request.getParameter("gender");

		// ── 1. Fetch old values BEFORE the UPDATE (for change-diff email) ────
		User oldUser = new UserDAO().getUserByUsername(username);

		// ── 2. Build and execute the UPDATE ──────────────────────────────────
		String sql;
		if ("staff".equalsIgnoreCase(role)) {
			sql = "UPDATE users SET email=?, mobile=?, country_code=?, role=?, status=?, address=?, gender=?, "
					+ "employee_id=?, department=?, shift_id=?, supervisor=?, joining_date=? WHERE username=?";
		} else if ("admin".equalsIgnoreCase(role)) {
			sql = "UPDATE users SET email=?, mobile=?, country_code=?, role=?, status=?, address=?, gender=?, "
					+ "admin_level=?, privileges=? WHERE username=?";
		} else {
			sql = "UPDATE users SET email=?, mobile=?, country_code=?, role=?, status=?, address=?, gender=? WHERE username=?";
		}

		try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {

			// Common fields (all branches): 1=email 2=mobile 3=country_code 4=role 5=status
			// 6=address 7=gender
			ps.setString(1, email);
			ps.setString(2, mobile);
			ps.setString(3, countryCode);
			ps.setString(4, role);
			ps.setString(5, status);
			ps.setString(6, address);
			ps.setString(7, gender);

			if ("staff".equalsIgnoreCase(role)) {
				ps.setString(8, request.getParameter("employeeId"));
				ps.setString(9, request.getParameter("department"));

				String shiftIdStr = request.getParameter("shiftId");
				if (shiftIdStr != null && !shiftIdStr.isBlank()) {
					try {
						ps.setInt(10, Integer.parseInt(shiftIdStr));
					} catch (NumberFormatException e) {
						ps.setNull(10, Types.INTEGER);
					}
				} else {
					ps.setNull(10, Types.INTEGER);
				}

				ps.setString(11, request.getParameter("supervisor"));

				String joiningDate = request.getParameter("joiningDate");
				if (joiningDate != null && !joiningDate.isEmpty()) {
					ps.setDate(12, java.sql.Date.valueOf(joiningDate));
				} else {
					ps.setDate(12, null);
				}
				ps.setString(13, username);

			} else if ("admin".equalsIgnoreCase(role)) {
				ps.setString(8, request.getParameter("adminLevel"));
				ps.setString(9, request.getParameter("privileges"));
				ps.setString(10, username);

			} else {
				ps.setString(8, username);
			}

			int updated = ps.executeUpdate();

			if (updated > 0) {
				// ── 3. Send profile-update email to staff/admin ──────────────
				// Use the new email address if it changed (so the mail reaches them),
				// falling back to the old one if the new one is blank.
				String sendToEmail = (email != null && !email.isBlank()) ? email
						: (oldUser != null ? oldUser.getEmail() : null);

				if (sendToEmail != null && !sendToEmail.isBlank()) {
					try {
						// Resolve new shift name for staff (if shift changed)
						OfficeShift newShift = null;
						String shiftIdStr2 = request.getParameter("shiftId");
						if ("staff".equalsIgnoreCase(role) && shiftIdStr2 != null && !shiftIdStr2.isBlank()) {
							try {
								newShift = new AttendanceDAO().getShiftById(Integer.parseInt(shiftIdStr2));
							} catch (Exception ignored) {
							}
						}

						OfficeShift oldShift = null;
						if (oldUser != null && oldUser.getShiftId() > 0) {
							try {
								oldShift = new AttendanceDAO().getShiftById(oldUser.getShiftId());
							} catch (Exception ignored) {
							}
						}

						// Build the change-summary rows
						String newShiftName = (newShift != null) ? newShift.getShiftName() : null;
						String oldShiftName = (oldShift != null) ? oldShift.getShiftName() : null;

						// Reconstruct "new" user object from form params for the email builder
						User newUser = new User();
						newUser.setUsername(username);
						newUser.setEmail(email);
						newUser.setMobileno(mobile);
						newUser.setCountryCode(countryCode);
						newUser.setRole(role);
						newUser.setStatus(status);
						newUser.setAddress(address);
						newUser.setGender(gender);
						newUser.setEmployeeId(request.getParameter("employeeId"));
						newUser.setDepartment(request.getParameter("department"));
						newUser.setSupervisor(request.getParameter("supervisor"));
						String jd = request.getParameter("joiningDate");
						if (jd != null && !jd.isEmpty()) {
							newUser.setJoiningDate(java.sql.Date.valueOf(jd));
						}
						newUser.setAdminLevel(request.getParameter("adminLevel"));
						newUser.setPrivileges(request.getParameter("privileges"));

						String html = buildProfileUpdateEmail(oldUser, newUser, oldShiftName, newShiftName);
						ServletContext ctx = getServletContext();
						EmailUtil.sendEmail(ctx.getInitParameter("mail.smtp.host"),
								ctx.getInitParameter("mail.smtp.port"), ctx.getInitParameter("mail.smtp.user"),
								ctx.getInitParameter("mail.smtp.password"), sendToEmail,
								"Your SIBS profile has been updated", html);

					} catch (Exception mailEx) {
						log("EditUserServlet: email failed for " + username + ": " + mailEx.getMessage());
					}
				}

				response.sendRedirect("userList?msg=User updated successfully");
			} else {
				response.sendRedirect("userList?error=Update failed — user not found");
			}

		} catch (Exception e) {
			e.printStackTrace();
			response.sendRedirect("userList?error=Database error: " + e.getMessage());
		}
	}

	// ═════════════════════════════════════════════════════════════════════════
	// Email builder — profile update notification
	// ═════════════════════════════════════════════════════════════════════════

	private String buildProfileUpdateEmail(User old, User nw, String oldShiftName, String newShiftName) {

		// ── Build the change rows ──────────────────────────────────────────────
		StringBuilder rows = new StringBuilder();
		int changeCount = 0;

		// Common fields
		changeCount += diffRow(rows, "Email Address", v(old != null ? old.getEmail() : null), v(nw.getEmail()));
		changeCount += diffRow(rows, "Mobile Number", fullMobile(old), fullMobile(nw));
		changeCount += diffRow(rows, "Status", v(old != null ? old.getStatus() : null), v(nw.getStatus()));
		changeCount += diffRow(rows, "Address", v(old != null ? old.getAddress() : null), v(nw.getAddress()));
		changeCount += diffRow(rows, "Gender", v(old != null ? old.getGender() : null), v(nw.getGender()));
		changeCount += diffRow(rows, "Role", v(old != null ? old.getRole() : null), v(nw.getRole()));

		// Staff-specific fields
		if ("staff".equalsIgnoreCase(nw.getRole()) || (old != null && "staff".equalsIgnoreCase(old.getRole()))) {
			changeCount += diffRow(rows, "Employee ID", v(old != null ? old.getEmployeeId() : null),
					v(nw.getEmployeeId()));
			changeCount += diffRow(rows, "Department", v(old != null ? old.getDepartment() : null),
					v(nw.getDepartment()));
			changeCount += diffRow(rows, "Supervisor", v(old != null ? old.getSupervisor() : null),
					v(nw.getSupervisor()));
			changeCount += diffRow(rows, "Joining Date",
					old != null && old.getJoiningDate() != null ? old.getJoiningDate().toString() : "—",
					nw.getJoiningDate() != null ? nw.getJoiningDate().toString() : "—");
			changeCount += diffRow(rows, "Work Shift", v(oldShiftName), v(newShiftName));
		}

		// Admin-specific fields
		if ("admin".equalsIgnoreCase(nw.getRole()) || (old != null && "admin".equalsIgnoreCase(old.getRole()))) {
			changeCount += diffRow(rows, "Admin Level", v(old != null ? old.getAdminLevel() : null),
					v(nw.getAdminLevel()));
			changeCount += diffRow(rows, "Privileges", v(old != null ? old.getPrivileges() : null),
					v(nw.getPrivileges()));
		}

		// If nothing actually changed, show a generic confirmation row
		if (changeCount == 0) {
			rows.append(unchangedRow("No field values were changed in this update."));
		}

		String changesSection = "<p style='margin:0 0 10px;font-size:13px;font-weight:700;letter-spacing:1px;"
				+ "text-transform:uppercase;color:#0369a1;'>\uD83D\uDCDD What Was Updated</p>"
				+ "<table width='100%' cellpadding='0' cellspacing='0' border='0' "
				+ "style='border-collapse:collapse;margin-bottom:24px;"
				+ "border:1px solid #dbeafe;border-radius:10px;overflow:hidden;'>" + "<tr style='background:#eff6ff;'>"
				+ "<th style='padding:9px 14px;font-size:11px;color:#64748b;text-align:left;font-weight:700;"
				+ "border-bottom:2px solid #bae6fd;'>Field</th>"
				+ "<th style='padding:9px 14px;font-size:11px;color:#64748b;text-align:left;font-weight:700;"
				+ "border-bottom:2px solid #bae6fd;'>Old Value</th>"
				+ "<th style='padding:9px 14px;font-size:11px;color:#0369a1;text-align:left;font-weight:700;"
				+ "border-bottom:2px solid #bae6fd;'>New Value</th>" + "</tr>" + rows + "</table>";

		String noteBox = "<div style='background:#fffbeb;border-left:4px solid #f59e0b;border-radius:0 8px 8px 0;"
				+ "padding:14px 18px;margin-bottom:20px;font-size:13px;color:#78350f;line-height:1.7;'>"
				+ "<strong>\u26A0\uFE0F Note:</strong> These changes were made by an administrator. "
				+ "If you believe this is a mistake or you did not expect this update, "
				+ "please contact your supervisor or HR at " + "<a href='mailto:" + HR_EMAIL
				+ "' style='color:#b45309;'>" + HR_EMAIL + "</a> right away.</div>";

		String loginBtn = "<div style='text-align:center;margin:20px 0 8px;'>" + "<a href='" + PORTAL_URL
				+ "' style='display:inline-block;background:#0ea5e9;color:#fff;"
				+ "padding:12px 32px;border-radius:25px;text-decoration:none;font-weight:700;font-size:14px;"
				+ "box-shadow:0 4px 14px rgba(14,165,233,.35);'>Log In to Portal \u2192</a></div>";

		return emailShell(nw.getUsername(), "\uD83D\uDEE1\uFE0F", "Your SIBS Profile Has Been Updated",
				"An administrator has made changes to your account. Here is a summary of what changed.",
				changesSection + noteBox + loginBtn);
	}

	// ── Diff row: only renders if old != new ─────────────────────────────────
	private static int diffRow(StringBuilder sb, String label, String oldVal, String newVal) {
		String o = oldVal == null ? "\u2014" : oldVal.trim();
		String n = newVal == null ? "\u2014" : newVal.trim();
		if (o.equals(n)) {
			return 0; // no change — skip row
		}
		sb.append("<tr style='border-bottom:1px solid #f0f9ff;'>")
				.append("<td style='padding:9px 14px;font-size:12px;font-weight:700;color:#64748b;"
						+ "text-transform:uppercase;white-space:nowrap;vertical-align:top;'>")
				.append(esc(label)).append("</td>")
				.append("<td style='padding:9px 14px;font-size:13px;color:#94a3b8;text-decoration:line-through;"
						+ "vertical-align:top;'>")
				.append(esc(o)).append("</td>")
				.append("<td style='padding:9px 14px;font-size:13px;color:#0369a1;font-weight:700;"
						+ "vertical-align:top;'>")
				.append(esc(n)).append("</td>").append("</tr>");
		return 1;
	}

	private static String unchangedRow(String msg) {
		return "<tr><td colspan='3' style='padding:12px 14px;font-size:13px;color:#94a3b8;" + "font-style:italic;'>"
				+ esc(msg) + "</td></tr>";
	}

	// ── Shared email shell (responsive, table-based layout) ──────────────────
	private static String emailShell(String username, String emoji, String headline, String subText,
			String bodyContent) {
		return "<!DOCTYPE html><html lang='en'><head><meta charset='UTF-8'>"
				+ "<meta name='viewport' content='width=device-width,initial-scale=1'>" + "<style>"
				+ "body{margin:0;padding:0;background:#f0f4f8;font-family:Arial,Helvetica,sans-serif;}"
				+ "@media(max-width:600px){" + ".ew{width:100%!important;border-radius:0!important;}"
				+ ".ep{padding:20px!important;}" + ".eh{padding:28px 20px!important;}"
				+ ".ef{padding:14px 20px!important;}"
				+ "table.diff td,table.diff th{display:block;width:100%!important;"
				+ "text-align:left!important;padding:4px 10px!important;}"
				+ "table.diff tr{display:block;margin-bottom:8px;background:#f8fafc;"
				+ "border-radius:6px;overflow:hidden;}" + "}" + "</style></head>"
				+ "<body style='margin:0;padding:24px 0;background:#f0f4f8;'>"
				+ "<table width='100%' cellpadding='0' cellspacing='0' border='0'>" + "<tr><td align='center'>"
				+ "<table class='ew' width='600' cellpadding='0' cellspacing='0' border='0' "
				+ "style='border-radius:16px;overflow:hidden;"
				+ "box-shadow:0 8px 40px rgba(0,0,0,.12);border:1px solid #dbeafe;'>"

				// Header
				+ "<tr><td class='eh' "
				+ "style='background:linear-gradient(135deg,#1e40af,#0ea5e9);padding:36px 40px;text-align:center;'>"
				+ "<div style='font-size:42px;margin-bottom:12px;'>" + emoji + "</div>"
				+ "<h1 style='margin:0 0 8px;color:#fff;font-size:22px;font-weight:800;letter-spacing:-0.3px;'>"
				+ esc(headline) + "</h1>"
				+ "<p style='margin:0;color:rgba(255,255,255,.85);font-size:14px;line-height:1.5;'>" + esc(subText)
				+ "</p>" + "</td></tr>"

				// Body
				+ "<tr><td class='ep' style='background:#fff;padding:36px 40px;'>"
				+ "<p style='margin:0 0 24px;font-size:16px;color:#0f172a;font-weight:600;'>" + "Hi " + esc(username)
				+ ",</p>" + bodyContent + "<p style='margin:24px 0 0;font-size:13px;color:#94a3b8;line-height:1.6;'>"
				+ "If you have any questions, please contact HR at " + "<a href='mailto:" + HR_EMAIL
				+ "' style='color:#0ea5e9;'>" + HR_EMAIL + "</a>.</p>" + "</td></tr>"

				// Footer
				+ "<tr><td class='ef' " + "style='background:#1e3a5f;padding:18px 40px;text-align:center;'>"
				+ "<p style='margin:0;color:rgba(255,255,255,.7);font-size:12px;line-height:1.6;'>"
				+ "This email was sent automatically by the SIBS system. " + "Please do not reply to this email.</p>"
				+ "<p style='margin:8px 0 0;color:rgba(255,255,255,.35);font-size:11px;'>"
				+ "\u00A9 2026 SIBS Organisation. All rights reserved.</p>" + "</td></tr>"

				+ "</table></td></tr></table></body></html>";
	}

	// ── Helpers ──────────────────────────────────────────────────────────────

	private static String fullMobile(User u) {
		if (u == null) {
			return "\u2014";
		}
		String cc = u.getCountryCode() != null ? u.getCountryCode() : "";
		String mb = u.getMobileno() != null ? u.getMobileno() : "";
		String combined = (cc + " " + mb).trim();
		return combined.isEmpty() ? "\u2014" : combined;
	}

	private static String v(String s) {
		return (s != null && !s.isBlank()) ? s : "\u2014";
	}

	private static String esc(String s) {
		if (s == null) {
			return "";
		}
		return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;");
	}
}
