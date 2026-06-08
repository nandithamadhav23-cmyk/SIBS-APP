package com.listener;

import java.sql.SQLException;
import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

import com.DAO.AttendanceDAO;
import com.util.AttendanceSession;
import com.util.OfficeShift;

import jakarta.servlet.ServletContextEvent;
import jakarta.servlet.ServletContextListener;
import jakarta.servlet.annotation.WebListener;

/**
 * AttendanceSweepScheduler v5 — dual-sweep, shift-aware, unified-status.
 *
 * ── BUGS FIXED IN v5 ──────────────────────────────────────────────────────
 *
 * BUG 1 — SINGLE 8 PM SWEEP MISSES NIGHT SHIFTS. The original scheduler ran
 * once at 20:00. Night shifts (e.g. 21:00–06:00) have sessions that are still
 * legitimately open at 20:00 and should only close around 09:00 the next
 * morning (06:00 shift-end + 3h grace = 09:00). A single 20:00 sweep would
 * either: (a) skip them (grace not yet reached) — sessions stay open forever,
 * OR (b) if grace was shorter — wrongly auto-close an in-progress night shift.
 * FIX: Added a SECOND sweep at 06:00 AM (SWEEP_HOUR_2) specifically to catch
 * overnight sessions. Both sweeps run against yesterday+today range.
 *
 * BUG 2 — attendance_status = 'AUTO_CLOSE' (uppercase). JSP STATUS_CFG and
 * AttendanceStatusUtil expect 'auto_close' (lowercase). FIX:
 * markMissedPunchOut() in AttendanceDAO now writes 'auto_close'. This class
 * itself does not write the status — it just calls the DAO.
 *
 * BUG 3 — Auto-close admin notification message referred to the old uppercase
 * sentinel in user-facing strings. FIX: Updated notification messages to use
 * consistent casing.
 *
 * ── Sweep schedule ────────────────────────────────────────────────────────
 * Sweep 1: 06:00 AM daily — catches night-shift sessions (close ~06:00+3h)
 * Sweep 2: 20:00 PM daily — catches morning/afternoon sessions Both sweeps
 * query yesterday+today so no session is missed.
 *
 * ── Shift-aware close logic ───────────────────────────────────────────────
 * For each open session: A. Shift assigned and on file: close if sweepTime >=
 * shiftEndBoundary + AUTO_CLOSE_GRACE_HOURS. punch_out pinned to
 * shiftEndBoundary (payroll-normalised). B. Shift assigned but record deleted —
 * elapsed-time fallback. C. No shift — elapsed-time fallback
 * (AUTO_CLOSE_GRACE_HOURS).
 */
@WebListener
public class AttendanceSweepScheduler implements ServletContextListener {

	// ── First sweep: morning (catches overnight/night-shift sessions) ──────
	private static final int SWEEP_HOUR_1 = 6;
	private static final int SWEEP_MINUTE_1 = 0;

	// ── Second sweep: evening (catches morning/afternoon sessions) ─────────
	private static final int SWEEP_HOUR_2 = 20;
	private static final int SWEEP_MINUTE_2 = 0;

	// ── Third sweep: mid-afternoon (sends alerts right after typical shift ends) ─
	// Runs every 30 minutes so missed-punch-out alerts reach admin promptly.
	private static final int ALERT_SWEEP_INTERVAL_MINUTES = 30;

	private static final DateTimeFormatter DT_FMT = DateTimeFormatter.ofPattern("hh:mm a, dd-MMM-yyyy");

	private ScheduledExecutorService scheduler;

	// ── ServletContextListener ────────────────────────────────────────────

	@Override
	public void contextInitialized(ServletContextEvent sce) {
		scheduler = Executors.newSingleThreadScheduledExecutor(r -> {
			Thread t = new Thread(r, "AttendanceSweep-Thread");
			t.setDaemon(true);
			return t;
		});

		long periodSec = TimeUnit.DAYS.toSeconds(1);

		// Sweep 1 — morning
		long delay1 = secondsUntil(SWEEP_HOUR_1, SWEEP_MINUTE_1);
		scheduler.scheduleAtFixedRate(() -> runSweep("Morning"), delay1, periodSec, TimeUnit.SECONDS);

		// Sweep 2 — evening (scheduled on the same single-thread executor;
		// it will queue behind sweep1 if they overlap, which they won't
		// because they're 14 hours apart.)
		long delay2 = secondsUntil(SWEEP_HOUR_2, SWEEP_MINUTE_2);
		scheduler.scheduleAtFixedRate(() -> runSweep("Evening"), delay2, periodSec, TimeUnit.SECONDS);

		// Alert sweep — runs every 30 minutes throughout the day to send
		// MISSED_PUNCHOUT_ALERT notifications as soon as a shift ends without
		// punch-out.
		// This powers real-time admin visibility without waiting for the daily sweeps.
		long alertIntervalSec = TimeUnit.MINUTES.toSeconds(ALERT_SWEEP_INTERVAL_MINUTES);
		scheduler.scheduleAtFixedRate(() -> runSweep("Alert"), 60, alertIntervalSec, TimeUnit.SECONDS);

		System.out.printf(
				"[AttendanceSweepScheduler] Three sweeps scheduled:%n"
						+ "  Morning sweep at %02d:%02d (first run in %d min)%n"
						+ "  Evening sweep at %02d:%02d (first run in %d min)%n"
						+ "  Alert sweep every %d min (first run in 1 min)%n",
				SWEEP_HOUR_1, SWEEP_MINUTE_1, delay1 / 60, SWEEP_HOUR_2, SWEEP_MINUTE_2, delay2 / 60,
				ALERT_SWEEP_INTERVAL_MINUTES);
	}

	@Override
	public void contextDestroyed(ServletContextEvent sce) {
		if (scheduler != null && !scheduler.isShutdown()) {
			scheduler.shutdownNow();
			System.out.println("[AttendanceSweepScheduler] Scheduler shut down.");
		}
	}

	// ── Core sweep logic ──────────────────────────────────────────────────

	private void runSweep(String label) {
		LocalDateTime sweepTime = LocalDateTime.now();
		System.out.printf("[AttendanceSweepScheduler] Running %s Auto-Close sweep at %s%n", label,
				sweepTime.format(DT_FMT));

		AttendanceDAO dao = new AttendanceDAO();

		try {
			// Search up to 7 days back so sessions that survived across weekends,
			// missed sweeps, or multi-day night-shift overruns are always caught.
			// Matches getAnyOpenSessionForUser's 7-day window.
			LocalDate today = LocalDate.now();
			LocalDate weekAgo = today.minusDays(7);

			List<AttendanceSession> openSessions = dao.getOpenSessionsForDateRange(weekAgo, today);

			if (openSessions.isEmpty()) {
				System.out.printf("[AttendanceSweepScheduler] %s sweep: no open sessions.%n", label);
				return;
			}

			System.out.printf("[AttendanceSweepScheduler] %s sweep: %d open session(s) to evaluate.%n", label,
					openSessions.size());

			for (AttendanceSession s : openSessions) {
				try {
					processOpenSession(dao, s, sweepTime);
				} catch (SQLException e) {
					System.err.printf("[AttendanceSweepScheduler] Error processing session %d ('%s'): %s%n", s.getId(),
							s.getUsername(), e.getMessage());
				}
			}

		} catch (SQLException e) {
			System.err.println("[AttendanceSweepScheduler] Failed to query open sessions: " + e.getMessage());
		}
	}

	/**
	 * Decide whether to auto-close a single open session.
	 *
	 * Path A — shift assigned and on file: close if sweepTime >= shiftEndBoundary +
	 * AUTO_CLOSE_GRACE_HOURS. punch_out pinned to shiftEndBoundary
	 * (payroll-normalised). If sweepTime >= shiftEndBoundary but still within grace
	 * → send ALERT to admin.
	 *
	 * Path B — shift deleted or no shift: elapsed-time fallback.
	 */
	private void processOpenSession(AttendanceDAO dao, AttendanceSession s, LocalDateTime sweepTime)
			throws SQLException {

		if (s.getShiftId() > 0) {
			// ── Path A: shift-aware boundary ──────────────────────────────
			OfficeShift shift = dao.getShiftById(s.getShiftId());

			if (shift != null) {
				LocalDateTime shiftEndBoundary = AttendanceDAO.computeShiftEndBoundary(s, shift);
				LocalDateTime graceBoundary = shiftEndBoundary.plusHours(AttendanceDAO.AUTO_CLOSE_GRACE_HOURS);

				if (sweepTime.isBefore(shiftEndBoundary)) {
					// Shift still in progress — nothing to do
					return;
				}

				if (sweepTime.isBefore(graceBoundary)) {
					// Shift has ended but within grace window — send ALERT to admin
					// so admin can track the missed punch-out in real time.
					String alertMsg = "⚠ Missed Punch-Out ALERT — Staff '" + s.getUsername()
							+ "' did not punch out for shift '" + shift.getShiftName() + "'. Scheduled shift ended at "
							+ shiftEndBoundary.format(DT_FMT) + ". Session will be auto-closed at grace boundary "
							+ graceBoundary.format(DT_FMT)
							+ " if staff does not punch out. Admin can force punch-out now from the dashboard.";
					// Only create alert if one doesn't already exist for this session today
					// (avoid spamming — we do this by using related_entity = sessionId)
					dao.createAdminNotification("MISSED_PUNCHOUT_ALERT", "Missed Punch-Out: " + s.getUsername(),
							alertMsg, "session:" + s.getId());
					System.out.printf(
							"[AttendanceSweepScheduler] ALERT sent for session %d ('%s', shift '%s') "
									+ "— shift ended %s, within grace until %s.%n",
							s.getId(), s.getUsername(), shift.getShiftName(), shiftEndBoundary.format(DT_FMT),
							graceBoundary.format(DT_FMT));
					return;
				}

				// Past grace boundary — auto-close with payroll-normalised punch_out.
				dao.markMissedPunchOut(s.getId(), shiftEndBoundary);

				String reason = "🔒 Auto Close (sweep) — Staff '" + s.getUsername() + "' missed punch-out for shift '"
						+ shift.getShiftName() + "' (expected logout " + shiftEndBoundary.format(DT_FMT) + "). "
						+ "Grace boundary " + graceBoundary.format(DT_FMT) + " exceeded. "
						+ "Punch-out normalised to shift-end for payroll accuracy. " + "Swept at "
						+ sweepTime.format(DT_FMT) + ".";

				dao.createAdminNotification("AUTO_CLOSE", "Auto Close: " + s.getUsername(), reason, s.getUsername());

				System.out.printf(
						"[AttendanceSweepScheduler] Auto-closed session %d for '%s' "
								+ "(shift '%s', normalised punch_out = %s).%n",
						s.getId(), s.getUsername(), shift.getShiftName(), shiftEndBoundary.format(DT_FMT));
				return;
			}

			// Shift record deleted — fall through to elapsed-time fallback.
			System.out.printf("[AttendanceSweepScheduler] Shift id=%d for '%s' no longer exists. "
					+ "Falling back to elapsed-time rule.%n", s.getShiftId(), s.getUsername());
		}

		// ── Path B: no shift (or deleted) — elapsed-time fallback ──────────
		long elapsedHours = Duration.between(s.getPunchIn(), sweepTime).toHours();

		if (elapsedHours < AttendanceDAO.AUTO_CLOSE_GRACE_HOURS) {
			System.out.printf(
					"[AttendanceSweepScheduler] Session %d ('%s', no shift) "
							+ "— only %dh elapsed (below %dh threshold). Skipping.%n",
					s.getId(), s.getUsername(), elapsedHours, AttendanceDAO.AUTO_CLOSE_GRACE_HOURS);
			return;
		}

		// Elapsed threshold met — close at NOW() (no normalisation possible).
		dao.markMissedPunchOut(s.getId()); // closes at LocalDateTime.now()

		String reason = "🔒 Auto Close (end-of-day sweep) — Staff '" + s.getUsername() + "' had no punch-out for "
				+ s.getSessionDate() + ". Session open for " + elapsedHours + " hour(s)" + " (≥ "
				+ AttendanceDAO.AUTO_CLOSE_GRACE_HOURS + "h threshold)." + " Auto-closed at " + sweepTime.format(DT_FMT)
				+ ".";

		dao.createAdminNotification("AUTO_CLOSE", "Auto Close: " + s.getUsername(), reason, s.getUsername());

		System.out.printf(
				"[AttendanceSweepScheduler] Auto-closed session %d for '%s' at %s "
						+ "(elapsed: %dh ≥ %dh fallback threshold).%n",
				s.getId(), s.getUsername(), sweepTime.format(DT_FMT), elapsedHours,
				AttendanceDAO.AUTO_CLOSE_GRACE_HOURS);
	}

	// ── Timing helper ─────────────────────────────────────────────────────

	private long secondsUntil(int hour, int minute) {
		ZoneId zone = ZoneId.systemDefault();
		ZonedDateTime now = ZonedDateTime.now(zone);
		ZonedDateTime target = now.toLocalDate().atTime(LocalTime.of(hour, minute)).atZone(zone);
		if (!now.isBefore(target)) {
			target = target.plusDays(1);
		}
		return target.toEpochSecond() - now.toEpochSecond();
	}
}
