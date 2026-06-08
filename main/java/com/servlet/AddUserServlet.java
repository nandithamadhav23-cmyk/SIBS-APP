package com.servlet;

import java.io.IOException;
import java.sql.Connection;
import java.sql.Date;
import java.time.LocalTime;
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

/**
 * AddUserServlet — registers a new staff / admin account and sends a
 * plain-English welcome email with login credentials and, for staff, their
 * assigned shift timings pulled directly from the database.
 */
@WebServlet("/AddUser")
public class AddUserServlet extends HttpServlet {

	private static final String PORTAL_URL = "http://localhost:8085/SampleApp/";
	private static final String HR_EMAIL = "hr@sibs.in";
	private static final DateTimeFormatter TIME_FMT = DateTimeFormatter.ofPattern("hh:mm a");

	@Override
	protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {

		User user = new User();
		user.setUsername(req.getParameter("username"));
		user.setPassword(req.getParameter("password")); // raw — DAO hashes
		user.setEmail(req.getParameter("email"));
		user.setMobileno(req.getParameter("mobile"));
		user.setCountryCode(req.getParameter("countryCode"));
		user.setAddress(req.getParameter("address"));
		user.setGender(req.getParameter("gender"));
		user.setRole(req.getParameter("role"));
		user.setStatus(req.getParameter("status"));

		String joiningDate = req.getParameter("joiningDate");
		if (joiningDate != null && !joiningDate.isEmpty()) {
			user.setJoiningDate(Date.valueOf(joiningDate));
		}

		if ("staff".equalsIgnoreCase(user.getRole())) {
			user.setEmployeeId(req.getParameter("employeeId"));
			user.setDepartment(req.getParameter("department"));
			user.setSupervisor(req.getParameter("supervisor"));

			String shiftIdParam = req.getParameter("shiftId");
			if (shiftIdParam != null && !shiftIdParam.isBlank()) {
				try {
					user.setShiftId(Integer.parseInt(shiftIdParam));
				} catch (NumberFormatException ignored) {
				}
			}

		} else if ("admin".equalsIgnoreCase(user.getRole())) {
			user.setAdminLevel(req.getParameter("adminLevel"));
			user.setPrivileges(req.getParameter("privileges"));
		}

		try (Connection conn = DBConnection.getConnection()) {
			UserDAO dao = new UserDAO();
			boolean success;

			// Email duplicate check applies to ALL roles, not just non-admin
			if (dao.emailExists(user.getEmail())) {
				req.setAttribute("status", "error");
				req.setAttribute("msg", "Email already registered.");
				req.getRequestDispatcher("addUser.jsp").forward(req, resp);
				return;
			}

			if ("admin".equalsIgnoreCase(user.getRole())) {
				success = dao.registerAdmin(user);
			} else {
				success = dao.registerUser(user);
			}

			if (success) {
				// Fetch the assigned shift from the database (if one was set)
				OfficeShift shift = null;
				if ("staff".equalsIgnoreCase(user.getRole()) && user.getShiftId() > 0) {
					try {
						shift = new AttendanceDAO().getShiftById(user.getShiftId());
					} catch (Exception e) {
						log("AddUserServlet: could not load shift #" + user.getShiftId() + " — " + e.getMessage());
					}
				}

				ServletContext ctx = getServletContext();
				try {
					EmailUtil.sendEmail(ctx.getInitParameter("mail.smtp.host"), ctx.getInitParameter("mail.smtp.port"),
							ctx.getInitParameter("mail.smtp.user"), ctx.getInitParameter("mail.smtp.password"),
							user.getEmail(), "Welcome to SIBS — Your Account is Ready", buildEmail(user, shift));
				} catch (Exception mailEx) {
					log("AddUserServlet: email failed for " + user.getEmail() + " — " + mailEx.getMessage());
				}

				req.setAttribute("status", "success");
			} else {
				req.setAttribute("status", "error");
				req.setAttribute("msg", "Registration failed. Please try again.");
			}

			req.getRequestDispatcher("addUser.jsp").forward(req, resp);

		} catch (Exception e) {
			throw new ServletException(e);
		}
	}

	// ─────────────────────────────────────────────────────────────────────────
	// Email builder — plain English, no technical jargon
	// ─────────────────────────────────────────────────────────────────────────

	private String buildEmail(User user, OfficeShift shift) {
		boolean isStaff = "staff".equalsIgnoreCase(user.getRole());
		String displayName = esc(user.getUsername());
		String roleLabel = isStaff ? "Staff Member" : "Administrator";
		String roleBg = isStaff ? "#0ea5e9" : "#7c3aed";

		// ── Shift block (staff only) ──────────────────────────────────────────────
		StringBuilder shiftHtml = new StringBuilder();
		if (isStaff) {
			shiftHtml.append(sectionHeader("&#128336;", "Your Work Schedule"));
			if (shift != null) {
				String start = fmt(shift.getExpectedLoginTime());
				String end = fmt(shift.getExpectedLogoutTime());
				int grace = shift.getLateGraceMinutes();
				long hrs = java.time.Duration.between(shift.getExpectedLoginTime(), shift.getExpectedLogoutTime())
						.toHours();
				shiftHtml.append("<p style='margin:0 0 14px;font-size:14px;color:#334155;line-height:1.75;'>"
						+ "You've been assigned to the <strong style='color:#0c1a2e;'>" + esc(shift.getShiftName())
						+ "</strong> shift. Here are your details:</p>"
						+ "<table role='presentation' style='width:100%;border-collapse:collapse;"
						+ "border-radius:10px;overflow:hidden;border:1px solid #e2e8f0;margin-bottom:16px;'>"
						+ shiftRow("&#127775;", "Shift", esc(shift.getShiftName()), true)
						+ shiftRow("&#9200;", "Start Time", start, false) + shiftRow("&#9201;", "End Time", end, true)
						+ shiftRow("&#8987;", "Daily Hours", hrs + " hours", false)
						+ shiftRow("&#9203;", "Late Grace", grace + "-minute window after " + start, true) + "</table>"
						+ "<div style='background:#f0f9ff;border-left:4px solid #38bdf8;border-radius:0 10px 10px 0;"
						+ "padding:14px 18px;margin-bottom:28px;font-size:13px;color:#1e40af;line-height:1.8;'>"
						+ "<strong>How attendance works:</strong> Log in to the portal and click "
						+ "<strong>Punch&nbsp;In</strong> when your shift starts, and <strong>Punch&nbsp;Out</strong> "
						+ "when you leave. Use the <strong>Break</strong> button for any breaks in between. "
						+ "Always punch out manually — do not rely on the automatic close.</div>");
			} else {
				shiftHtml.append("<p style='margin:0 0 28px;font-size:14px;color:#64748b;line-height:1.75;'>"
						+ "Your shift hasn't been assigned yet. Your manager will confirm your working hours "
						+ "before your first day. You can also check the portal after logging in.</p>");
			}
		}

		// ── Profile details block (staff only) ────────────────────────────────────
		StringBuilder profileHtml = new StringBuilder();
		if (isStaff) {
			StringBuilder pRows = new StringBuilder();
			if (str(user.getEmployeeId())) {
				pRows.append(detailPill("Employee ID", esc(user.getEmployeeId())));
			}
			if (str(user.getDepartment())) {
				pRows.append(detailPill("Department", esc(user.getDepartment())));
			}
			if (str(user.getSupervisor())) {
				pRows.append(detailPill("Reports To", esc(user.getSupervisor())));
			}
			if (user.getJoiningDate() != null) {
				pRows.append(detailPill("Start Date", user.getJoiningDate().toString()));
			}
			if (pRows.length() > 0) {
				profileHtml.append(sectionHeader("&#128100;", "Your Details"));
				profileHtml.append("<table role='presentation' style='width:100%;border-collapse:collapse;"
						+ "border-radius:10px;overflow:hidden;border:1px solid #e2e8f0;margin-bottom:28px;'>" + pRows
						+ "</table>");
			}
		}

		// ── Credentials block ─────────────────────────────────────────────────────
		String credBlock = sectionHeader("&#128273;", "Your Login Details")
				+ "<table role='presentation' style='width:100%;border-collapse:collapse;"
				+ "border-radius:10px;overflow:hidden;border:1px solid #e2e8f0;margin-bottom:14px;'>"
				+ credRow("Portal URL",
						"<a href='" + PORTAL_URL + "' style='color:#0ea5e9;font-weight:600;" + "text-decoration:none;'>"
								+ PORTAL_URL + "</a>",
						true)
				+ credRow("Username / Email", esc(user.getEmail()), false)
				+ credRow("Password",
						"<span style='display:inline-block;background:#f0f9ff;padding:5px 14px;"
								+ "border-radius:7px;font-family:\"Courier New\",monospace;font-size:14px;"
								+ "font-weight:700;color:#0369a1;border:1px solid #bae6fd;letter-spacing:.5px;'>"
								+ esc(user.getPassword()) + "</span>",
						true)
				+ "</table>" + "<div style='display:flex;align-items:flex-start;gap:10px;background:#fff7ed;"
				+ "border:1px solid #fed7aa;border-radius:10px;padding:13px 16px;margin-bottom:28px;'>"
				+ "<span style='font-size:18px;line-height:1;'>&#9888;&#65039;</span>"
				+ "<p style='margin:0;font-size:13px;color:#9a3412;font-weight:600;line-height:1.6;'>"
				+ "For your security, please change your password the first time you log in.</p></div>";

		// ── Tips block ────────────────────────────────────────────────────────────
		String tipsBlock = sectionHeader("&#128161;", "Quick Tips")
				+ "<table role='presentation' cellpadding='0' cellspacing='0' "
				+ "style='width:100%;margin-bottom:28px;'>"
				+ tipRow("Log in daily and <strong>Punch In</strong> at the start of your shift.")
				+ tipRow("Always <strong>Punch Out</strong> before leaving — don't skip this.")
				+ tipRow("Use the <strong>Break</strong> button on the portal for any mid-shift breaks.")
				+ tipRow("Apply for leave via the <strong>Leave</strong> section in the portal.")
				+ tipRow("Questions? Email HR at <a href='mailto:" + HR_EMAIL
						+ "' style='color:#0ea5e9;font-weight:600;'>" + HR_EMAIL + "</a>.")
				+ "</table>";

		// ── CTA button ────────────────────────────────────────────────────────────
		String ctaBlock = "<div style='text-align:center;padding:8px 0 28px;'>" + "<a href='" + PORTAL_URL
				+ "' style='display:inline-block;background:linear-gradient(135deg,#0369a1,#0ea5e9);"
				+ "color:#fff;padding:15px 44px;border-radius:50px;text-decoration:none;"
				+ "font-size:15px;font-weight:700;letter-spacing:.3px;"
				+ "box-shadow:0 6px 20px rgba(14,165,233,.40);'>Log In to the Portal &#8594;</a></div>";

		// ── Assemble full email ───────────────────────────────────────────────────
		return "<!DOCTYPE html>" + "<html lang='en' xmlns='http://www.w3.org/1999/xhtml'>" + "<head>"
				+ "<meta charset='UTF-8'>" + "<meta name='viewport' content='width=device-width,initial-scale=1'>"
				+ "<meta http-equiv='X-UA-Compatible' content='IE=edge'>" + "<title>Welcome to SIBS</title>" + "<style>"
				+ "body{margin:0;padding:0;background:#f0f9ff;}" + "@media only screen and (max-width:600px){"
				+ ".em-wrap{border-radius:0!important;margin:0!important;}" + ".em-body{padding:24px 18px!important;}"
				+ ".em-header{padding:32px 20px!important;}"
				+ ".em-cta a{width:100%!important;box-sizing:border-box!important;"
				+ "display:block!important;text-align:center!important;}"
				+ ".em-pill-row{flex-direction:column!important;}" + "}" + "</style>" + "</head>"
				+ "<body style='margin:0;padding:0;background:#f0f9ff;"
				+ "font-family:-apple-system,BlinkMacSystemFont,\"Segoe UI\",Roboto,Arial,sans-serif;'>"

				// Outer wrapper
				+ "<table role='presentation' width='100%' cellpadding='0' cellspacing='0'>"
				+ "<tr><td align='center' style='padding:32px 16px;'>"

				// Card
				+ "<table role='presentation' class='em-wrap' style='max-width:600px;width:100%;"
				+ "border-radius:18px;overflow:hidden;box-shadow:0 8px 40px rgba(14,165,233,.16);"
				+ "border:1px solid #dbeafe;background:#fff;'>"

				// ── Header ─────────────────────────────────────────────────────────────
				+ "<tr><td class='em-header' style='background:linear-gradient(135deg,#0369a1 0%,#0ea5e9 55%,#38bdf8 100%);"
				+ "padding:44px 40px;text-align:center;'>"
				+ "<div style='width:64px;height:64px;background:rgba(255,255,255,.18);border-radius:50%;"
				+ "margin:0 auto 16px;display:flex;align-items:center;justify-content:center;"
				+ "font-size:28px;border:2px solid rgba(255,255,255,.35);line-height:64px;'>&#127881;</div>"
				+ "<h1 style='margin:0 0 8px;color:#fff;font-size:24px;font-weight:800;"
				+ "letter-spacing:-.3px;line-height:1.2;'>Welcome to SIBS!</h1>"
				+ "<p style='margin:0 0 16px;color:rgba(255,255,255,.88);font-size:15px;line-height:1.6;'>"
				+ "Your account is ready. Here's everything you need to get started.</p>"
				+ "<span style='display:inline-block;background:rgba(255,255,255,.2);color:#fff;"
				+ "border:1.5px solid rgba(255,255,255,.4);font-size:11px;font-weight:700;"
				+ "letter-spacing:1.2px;text-transform:uppercase;padding:5px 16px;border-radius:20px;'>" + roleLabel
				+ "</span>" + "</td></tr>"

				// ── Body ───────────────────────────────────────────────────────────────
				+ "<tr><td class='em-body' style='background:#fff;padding:36px 40px;'>"
				+ "<p style='margin:0 0 8px;font-size:20px;font-weight:800;color:#0c1a2e;'>Hi " + displayName
				+ "! &#128075;</p>" + "<p style='margin:0 0 32px;font-size:15px;color:#475569;line-height:1.75;'>"
				+ "We're thrilled to have you on board. Your SIBS portal account is now live and ready to use. "
				+ "Everything you need is below.</p>"
				+ "<hr style='border:none;border-top:1px solid #e2e8f0;margin:0 0 28px;'>" + credBlock + profileHtml
				+ shiftHtml + tipsBlock + ctaBlock
				+ "<hr style='border:none;border-top:1px solid #e2e8f0;margin:0 0 24px;'>"
				+ "<p style='margin:0;font-size:13px;color:#94a3b8;text-align:center;line-height:1.7;'>"
				+ "This email was sent automatically. Please do not reply directly.<br>"
				+ "Need help? Contact HR at <a href='mailto:" + HR_EMAIL
				+ "' style='color:#0ea5e9;font-weight:600;text-decoration:none;'>" + HR_EMAIL + "</a>." + "</p>"
				+ "</td></tr>"

				// ── Footer ─────────────────────────────────────────────────────────────
				+ "<tr><td style='background:#0c1a2e;padding:22px 40px;text-align:center;'>"
				+ "<p style='margin:0 0 4px;color:rgba(255,255,255,.55);font-size:12px;line-height:1.6;'>"
				+ "&#169; 2026 SIBS Organisation. All rights reserved.</p>"
				+ "<p style='margin:0;font-size:11px;color:rgba(255,255,255,.3);'>"
				+ "Inventory &amp; Staff Management Portal</p>" + "</td></tr>"

				+ "</table>" // end card
				+ "</td></tr></table>" // end outer
				+ "</body></html>";
	}

	// ─────────────────────────────────────────────────────────────────────────
	// Component helpers
	// ─────────────────────────────────────────────────────────────────────────

	private static String sectionHeader(String icon, String title) {
		return "<div style='display:flex;align-items:center;gap:10px;margin:0 0 14px;'>"
				+ "<span style='font-size:17px;line-height:1;'>" + icon + "</span>"
				+ "<span style='font-size:11px;font-weight:800;letter-spacing:1.2px;text-transform:uppercase;"
				+ "color:#0369a1;'>" + title + "</span>"
				+ "<div style='flex:1;height:1px;background:#e2e8f0;'></div></div>";
	}

	/** Table row for credentials — alternating background */
	private static String credRow(String label, String value, boolean alt) {
		String bg = alt ? "#f8fafc" : "#fff";
		return "<tr style='background:" + bg + ";'>"
				+ "<td style='padding:11px 14px;font-size:12px;font-weight:700;text-transform:uppercase;"
				+ "color:#64748b;white-space:nowrap;width:140px;vertical-align:middle;"
				+ "border-bottom:1px solid #e2e8f0;'>" + label + "</td>"
				+ "<td style='padding:11px 14px;font-size:14px;color:#0c1a2e;font-weight:500;"
				+ "border-bottom:1px solid #e2e8f0;'>" + value + "</td>" + "</tr>";
	}

	/** Table row for shift details */
	private static String shiftRow(String icon, String label, String value, boolean alt) {
		String bg = alt ? "#f8fafc" : "#fff";
		return "<tr style='background:" + bg + ";'>"
				+ "<td style='padding:11px 14px;width:32px;text-align:center;vertical-align:middle;"
				+ "border-bottom:1px solid #e2e8f0;font-size:15px;'>" + icon + "</td>"
				+ "<td style='padding:11px 6px;font-size:12px;font-weight:700;text-transform:uppercase;"
				+ "color:#64748b;white-space:nowrap;width:110px;vertical-align:middle;"
				+ "border-bottom:1px solid #e2e8f0;'>" + label + "</td>"
				+ "<td style='padding:11px 14px;font-size:14px;color:#0c1a2e;font-weight:600;"
				+ "border-bottom:1px solid #e2e8f0;'>" + value + "</td>" + "</tr>";
	}

	/** Profile detail pill table row */
	private static String detailPill(String label, String value) {
		return "<tr>" + "<td style='padding:11px 14px;font-size:12px;font-weight:700;text-transform:uppercase;"
				+ "color:#64748b;width:140px;border-bottom:1px solid #e2e8f0;'>" + label + "</td>"
				+ "<td style='padding:11px 14px;font-size:14px;color:#0c1a2e;font-weight:600;"
				+ "border-bottom:1px solid #e2e8f0;'>" + value + "</td>" + "</tr>";
	}

	/** Bullet tip row */
	private static String tipRow(String text) {
		return "<tr><td style='padding:7px 0;vertical-align:top;width:28px;'>"
				+ "<div style='width:22px;height:22px;background:#e0f2fe;border-radius:50%;"
				+ "display:flex;align-items:center;justify-content:center;font-size:11px;color:#0369a1;"
				+ "font-weight:800;line-height:22px;text-align:center;'>&#10003;</div>"
				+ "</td><td style='padding:7px 0 7px 8px;font-size:14px;color:#334155;line-height:1.6;'>" + text
				+ "</td></tr>";
	}

	private static String fmt(LocalTime t) {
		return t != null ? t.format(TIME_FMT) : "—";
	}

	private static String esc(String s) {
		if (s == null) {
			return "";
		}
		return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;");
	}

	private static boolean str(String s) {
		return s != null && !s.isBlank();
	}
}