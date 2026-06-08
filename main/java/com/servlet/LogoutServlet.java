
package com.servlet;

import java.io.IOException;
import java.sql.SQLException;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

import com.DAO.AttendanceDAO;
import com.listener.MissedPunchOutListener;
import com.util.AttendanceSession;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

/**
 * LogoutServlet — handles ONLY manual, user-initiated logouts.
 *
 * ── Contract with MissedPunchOutListener ─────────────────────────────────────
 * This servlet MUST stamp the HTTP session with logoutType = "manual" BEFORE
 * calling session.invalidate(). The listener checks this attribute to
 * distinguish a voluntary logout from an idle-timeout expiry so it can skip the
 * 12-hour auto-close logic for explicit logouts.
 *
 * ── Punch-out on logout
 * ─────────────────────────────────────────────────────── If a staff member
 * walks away without punching out first and then explicitly hits "Logout", we
 * punch them out automatically RIGHT HERE so the MissedPunchOutListener does
 * not need to touch their session at all.
 *
 * This keeps the business logic in one clear place: • Explicit logout → this
 * servlet punches out (if needed) + invalidates. • Session timeout →
 * MissedPunchOutListener applies the 12-hour rule. • End-of-day sweep →
 * AttendanceSweepScheduler applies the 12-hour rule.
 */
@WebServlet("/logout")
public class LogoutServlet extends HttpServlet {

	private static final DateTimeFormatter TIME_FMT = DateTimeFormatter.ofPattern("hh:mm a, dd-MMM-yyyy");

	private final AttendanceDAO dao = new AttendanceDAO();

	// Support both GET and POST so existing logout links and AJAX calls both work
	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
		handleLogout(req, resp);
	}

	@Override
	protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
		handleLogout(req, resp);
	}

	// ── Core logout logic ─────────────────────────────────────────────────────

	private void handleLogout(HttpServletRequest req, HttpServletResponse resp) throws IOException {

		HttpSession session = req.getSession(false);

		if (session != null) {
			String username = (String) session.getAttribute("username");
			String role = (String) session.getAttribute("role");

			// ── Auto punch-out for staff who forgot ───────────────────────────
			if (username != null && "staff".equalsIgnoreCase(role)) {
				try {
					AttendanceSession openSession = dao.getTodayOpenSessionForUser(username);
					if (openSession != null) {
						// Punch them out with zero extra break time.
						// additionalBreakMs = 0: if they were on break when they
						// clicked Logout, we don't count unfinished break time.
						dao.punchOut(openSession.getId(), LocalDateTime.now(), 0);

						String autoTime = LocalDateTime.now().format(TIME_FMT);
						String msg = "Staff '" + username + "' logged out without performing Punch Out. "
								+ "System auto-punched them out at " + autoTime + ".";
						dao.createAdminNotification("AUTO_PUNCHOUT_ON_LOGOUT", msg);

						System.out.println(
								"[LogoutServlet] Auto-punched out '" + username + "' on manual logout at " + autoTime);
					}
				} catch (SQLException e) {
					// Log but do not block the logout
					System.err
							.println("[LogoutServlet] Could not auto-punch-out '" + username + "': " + e.getMessage());
					e.printStackTrace();
				}
			}

			// ── CRITICAL: stamp the session BEFORE invalidate() ───────────────
			// MissedPunchOutListener.sessionDestroyed() reads this attribute.
			// If it is "manual" the listener skips all auto-close logic.
			session.setAttribute(MissedPunchOutListener.ATTR_LOGOUT_TYPE, "manual");

			// ── Invalidate the HTTP session ────────────────────────────────────
			session.invalidate();
		}

		// Redirect to the login page (adjust path to match your project structure)
		resp.sendRedirect(req.getContextPath() + "/index.jsp");
	}

	// ── Helper: delegates to DAO (avoids duplicating SQL here) ───────────────

	private AttendanceSession getTodayOpenSessionForUser(String username) throws SQLException {
		return dao.getTodayOpenSessionForUser(username);
	}
}
