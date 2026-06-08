package com.listener;

import java.sql.SQLException;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

import com.DAO.AttendanceDAO;
import com.util.AttendanceSession;
import com.util.OfficeShift;

import jakarta.servlet.annotation.WebListener;
import jakarta.servlet.http.HttpSession;
import jakarta.servlet.http.HttpSessionEvent;
import jakarta.servlet.http.HttpSessionListener;

/**
 * MissedPunchOutListener v5 — shift-aware, grace-window auto-close.
 *
 * ── BUGS FIXED IN v5 ──────────────────────────────────────────────────────
 *
 * BUG 1 — attendance_status sentinel mismatch. The DAO previously wrote
 * 'AUTO_CLOSE' (uppercase) but the JSP STATUS_CFG and AttendanceStatusUtil look
 * for 'auto_close' (lowercase). Any session closed by this listener showed "In
 * Progress" on the dashboard instead of the "Auto-Closed" badge. FIX:
 * AttendanceDAO.markMissedPunchOut() now writes 'auto_close' (v5 DAO). This
 * listener has no change needed — it just calls the DAO.
 *
 * BUG 2 — Admin notification message referred to uppercase AUTO_CLOSE string.
 * FIX: Messages updated for clarity and consistency with v5 vocabulary.
 *
 * BUG 3 — FALLBACK_THRESHOLD_HOURS (12) was inconsistent with
 * AUTO_CLOSE_GRACE_HOURS (3) in the DAO. The listener waited 12h before closing
 * no-shift sessions while the scheduler used 3h — creating a gap where sessions
 * were neither closed by the listener nor the scheduler. FIX:
 * FALLBACK_THRESHOLD_HOURS now reads AUTO_CLOSE_GRACE_HOURS from the DAO so all
 * three code paths (DAO, Listener, Scheduler) are consistent. Real-world logic:
 * a session idle for more than (grace) hours after shift end should be
 * auto-closed regardless of how it is detected.
 *
 * ── HOW IT WORKS ──────────────────────────────────────────────────────────
 * Jakarta EE fires sessionDestroyed() when an HTTP session ends: 1. MANUAL
 * LOGOUT → LogoutServlet sets "logoutType"="manual" before invalidating. This
 * listener detects the flag and skips processing. 2. SESSION TIMEOUT → the
 * attribute is absent; this listener evaluates whether the attendance session
 * should be auto-closed.
 *
 * ── Auto-close evaluation for timed-out sessions ────────────────────────── A)
 * Session has a shift assigned: - Compute shiftEndBoundary (overnight-aware)
 * via AttendanceDAO. - now < shiftEndBoundary + grace → shift still in
 * progress; skip. - now ≥ shiftEndBoundary + grace → auto-close; punch_out =
 * shiftEnd (payroll-normalised so net_work_ms is not inflated by idle time).
 *
 * B) Session has no shift assigned (fallback): - elapsed <
 * AUTO_CLOSE_GRACE_HOURS → still in progress; skip. - elapsed ≥
 * AUTO_CLOSE_GRACE_HOURS → auto-close with punch_out = NOW().
 *
 * ── Thread safety ─────────────────────────────────────────────────────────
 * Each DAO call obtains its own pooled connection. The static DAO instance is
 * safe because AttendanceDAO is stateless.
 *
 * ── web.xml recommendation ────────────────────────────────────────────────
 * Keep a 30-minute idle timeout so timed-out HTTP sessions are detected fast:
 * <session-config><session-timeout>30</session-timeout></session-config>
 *
 * ── LogoutServlet contract ────────────────────────────────────────────────
 * Your logout servlet MUST set the marker attribute before invalidating:
 * session.setAttribute("logoutType", "manual"); session.invalidate();
 */
@WebListener
public class MissedPunchOutListener implements HttpSessionListener {

	/** Set to {@code "manual"} by LogoutServlet before calling invalidate(). */
	public static final String ATTR_LOGOUT_TYPE = "logoutType";

	/**
	 * Fallback elapsed-time threshold used when the session has no shift.
	 *
	 * BUG FIX v5: was hardcoded to 12h which was inconsistent with
	 * AUTO_CLOSE_GRACE_HOURS=3 in AttendanceDAO. Now uses the same constant so all
	 * three auto-close paths (DAO, Listener, Scheduler) agree.
	 */
	private static final long FALLBACK_THRESHOLD_HOURS = AttendanceDAO.AUTO_CLOSE_GRACE_HOURS;

	private static final AttendanceDAO dao = new AttendanceDAO();
	private static final DateTimeFormatter TIME_FMT = DateTimeFormatter.ofPattern("hh:mm a, dd-MMM-yyyy");

	// ── sessionCreated: no-op ─────────────────────────────────────────────
	@Override
	public void sessionCreated(HttpSessionEvent se) {
		/* no-op */ }

	// ── sessionDestroyed: shift-aware auto-close evaluation ───────────────
	@Override
	public void sessionDestroyed(HttpSessionEvent se) {

		HttpSession session = se.getSession();

		// 1. Identify who this session belongs to
		String username = (String) session.getAttribute("username");
		String role = (String) session.getAttribute("role");

		// Only staff punch in/out; admins and unauthenticated sessions ignored.
		if (username == null || !"staff".equalsIgnoreCase(role)) {
			return;
		}

		// 2. Detect manual logout vs timeout
		String logoutType = (String) session.getAttribute(ATTR_LOGOUT_TYPE);
		if ("manual".equalsIgnoreCase(logoutType)) {
			System.out.printf("[MissedPunchOutListener] Manual logout for '%s' — skipping auto-close.%n", username);
			return;
		}

		// 3. SESSION TIMEOUT path — shift-aware evaluation
		try {
			// getAnyOpenSessionForUser checks today AND yesterday so
			// night-shift sessions (session_date = yesterday) are found
			// correctly when the HTTP session times out after midnight.
			AttendanceSession openSession = dao.getAnyOpenSessionForUser(username);

			if (openSession == null) {
				return; // already punched out or no session
			}

			LocalDateTime now = LocalDateTime.now();

			if (openSession.getShiftId() > 0) {
				evaluateShiftAwareClose(openSession, now, username);
			} else {
				evaluateFallbackClose(openSession, now, username);
			}

		} catch (SQLException e) {
			// Never let a listener exception propagate — just log it.
			System.err.printf("[MissedPunchOutListener] DB error for user '%s': %s%n", username, e.getMessage());
			e.printStackTrace();
		}
	}

	// ── Private evaluation helpers ─────────────────────────────────────────

	/**
	 * Shift-assigned path: auto-close if now ≥ shiftEndBoundary +
	 * AUTO_CLOSE_GRACE_HOURS. punch_out is pinned to scheduled shift-end
	 * (payroll-normalised).
	 */
	private void evaluateShiftAwareClose(AttendanceSession openSession, LocalDateTime now, String username)
			throws SQLException {

		OfficeShift shift = dao.getShiftById(openSession.getShiftId());

		if (shift == null) {
			// Shift record deleted — fall back to elapsed-time rule
			System.out.printf("[MissedPunchOutListener] Shift id=%d for '%s' no longer exists; "
					+ "falling back to elapsed-time rule.%n", openSession.getShiftId(), username);
			evaluateFallbackClose(openSession, now, username);
			return;
		}

		LocalDateTime shiftEndBoundary = AttendanceDAO.computeShiftEndBoundary(openSession, shift);
		LocalDateTime graceBoundary = shiftEndBoundary.plusHours(AttendanceDAO.AUTO_CLOSE_GRACE_HOURS);

		if (now.isBefore(graceBoundary)) {
			// Shift is still in progress or within grace — keep open.
			// AttendanceSweepScheduler will catch it later.
			System.out.printf(
					"[MissedPunchOutListener] Session timeout for '%s' (shift '%s') "
							+ "but within grace window (shift-end %s + %dh). Keeping open.%n",
					username, shift.getShiftName(), shiftEndBoundary.format(TIME_FMT),
					AttendanceDAO.AUTO_CLOSE_GRACE_HOURS);
			return;
		}

		// Past grace boundary — auto-close with normalised punch_out.
		// Note: markMissedPunchOut now writes 'auto_close' (lowercase) per v5 DAO.
		dao.markMissedPunchOut(openSession.getId(), shiftEndBoundary);

		String msg = "🔒 Auto Close — Staff '" + username + "' did not punch out for shift '" + shift.getShiftName()
				+ "' (expected out: " + shiftEndBoundary.format(TIME_FMT) + "). "
				+ "Session auto-closed at grace boundary " + graceBoundary.format(TIME_FMT)
				+ " via HTTP session timeout. "
				+ "Punch-out was normalised to scheduled shift-end for payroll accuracy. "
				+ "Please review and adjust if required.";

		dao.createAdminNotification("AUTO_CLOSE", "Auto Close: " + username, msg, username);

		System.out.printf(
				"[MissedPunchOutListener] Auto-closed session %d for '%s' "
						+ "(shift '%s', normalised punch_out = %s).%n",
				openSession.getId(), username, shift.getShiftName(), shiftEndBoundary.format(TIME_FMT));
	}

	/**
	 * No-shift fallback: auto-close if elapsed ≥ FALLBACK_THRESHOLD_HOURS.
	 * punch_out = NOW() since there is no scheduled end to normalise to.
	 */
	private void evaluateFallbackClose(AttendanceSession openSession, LocalDateTime now, String username)
			throws SQLException {

		long elapsedHours = java.time.Duration.between(openSession.getPunchIn(), now).toHours();

		if (elapsedHours < FALLBACK_THRESHOLD_HOURS) {
			System.out.printf(
					"[MissedPunchOutListener] Session timeout for '%s' (no shift) — "
							+ "only %dh elapsed (threshold %dh). Keeping open.%n",
					username, elapsedHours, FALLBACK_THRESHOLD_HOURS);
			return;
		}

		dao.markMissedPunchOut(openSession.getId()); // closes at NOW()

		String autoCloseTime = now.format(TIME_FMT);
		String msg = "🔒 Auto Close (no shift) — Staff '" + username + "' did not perform Punch Out. "
				+ "Session had been open for " + elapsedHours + " hour(s) " + "(≥ " + FALLBACK_THRESHOLD_HOURS
				+ "h threshold). " + "Auto-closed at " + autoCloseTime + " via HTTP session timeout. "
				+ "Please review and adjust if required.";

		dao.createAdminNotification("AUTO_CLOSE", "Auto Close: " + username, msg, username);

		System.out.printf(
				"[MissedPunchOutListener] Auto-closed session %d for '%s' " + "at %s (elapsed: %dh ≥ %dh threshold).%n",
				openSession.getId(), username, autoCloseTime, elapsedHours, FALLBACK_THRESHOLD_HOURS);
	}
}
