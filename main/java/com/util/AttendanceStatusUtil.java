package com.util;

import java.time.LocalDateTime;
import java.time.LocalTime;

public final class AttendanceStatusUtil {

	// ── Timing constants ────────────────────────────────────────────────────

	/** Default "full day" threshold used when no shift is provided (legacy). */
	public static final long DEFAULT_FULL_DAY_MS = 8L * 3_600_000;
	/** Default "half day" threshold used when no shift is provided (legacy). */
	public static final long DEFAULT_HALF_DAY_MS = 4L * 3_600_000;
	/**
	 * Minutes of grace after shift end before a session is considered overtime.
	 * Prevents 1-2 minutes of rounding noise from triggering an OT flag.
	 */
	public static final long OVERTIME_GRACE_MS = 15L * 60_000;

	/** Punch-in after this time = Late (1 h grace from 10:00 office start). */
	public static final LocalTime LATE_THRESHOLD = LocalTime.of(11, 0);
	/** Official office start time. */
	public static final LocalTime OFFICE_START = LocalTime.of(10, 0);

	// ── Status string constants — SINGLE vocabulary, lowercase_snake ────────
	/** Session still open, punch-out not yet performed. */
	public static final String STATUS_PENDING = "pending";
	/** On time, full shift hours completed. */
	public static final String STATUS_FULL_DAY = "full_day";
	/** Legacy alias — kept for backward compat with old DB rows. */
	public static final String STATUS_PRESENT = "full_day";
	/** On time, between half-day and full-day hours. */
	public static final String STATUS_HALF_DAY = "half_day";
	/** Less than half-day hours worked (or no check-in). */
	public static final String STATUS_ABSENT = "absent";
	/** Late punch-in, full shift hours completed. */
	public static final String STATUS_LATE = "late";
	/** Late punch-in, half-day hours. */
	public static final String STATUS_LATE_HALF = "late_half";
	/** On time, worked beyond shift end + grace. */
	public static final String STATUS_OVERTIME = "overtime";
	/** Late punch-in AND worked beyond shift end + grace. */
	public static final String STATUS_LATE_OVERTIME = "late_overtime";
	/** Session was auto-closed by the system (sentinel). */
	public static final String STATUS_AUTO_CLOSE = "auto_close";

	private AttendanceStatusUtil() {
	}

	// ── Core computation ─────────────────────────────────────────────────────

	/**
	 * Shift-aware attendance status computation.
	 *
	 * <p>
	 * <b>Use this overload whenever a shift is available.</b> It derives the
	 * full-day and half-day thresholds from the shift's scheduled duration rather
	 * than the hardcoded 8-hour constant.
	 *
	 * @param punchIn         exact punch-in timestamp
	 * @param punchOut        null while session is open
	 * @param netWorkMs       net working milliseconds (elapsed − breaks)
	 * @param shiftDurationMs scheduled shift length in ms (0 = unknown → fallback)
	 * @param isLateOverride  pre-computed late flag from the DAO punch-in check
	 *                        (pass {@code null} to auto-detect from punchIn time)
	 * @return one of the STATUS_* constants
	 */
	public static String compute(LocalDateTime punchIn, LocalDateTime punchOut, long netWorkMs, long shiftDurationMs,
			Boolean isLateOverride) {
		if (punchOut == null) {
			return STATUS_PENDING;
		}

		long fullDayMs = shiftDurationMs > 0 ? shiftDurationMs : DEFAULT_FULL_DAY_MS;
		long halfDayMs = fullDayMs / 2;

		boolean late = (isLateOverride != null) ? isLateOverride
				: (punchIn != null && punchIn.toLocalTime().isAfter(LATE_THRESHOLD));

		if (netWorkMs < halfDayMs) {
			return STATUS_ABSENT;
		}
		if (netWorkMs >= halfDayMs && netWorkMs < fullDayMs) {
			return late ? STATUS_LATE_HALF : STATUS_HALF_DAY;
		}
		if (netWorkMs <= fullDayMs + OVERTIME_GRACE_MS) {
			return late ? STATUS_LATE : STATUS_FULL_DAY;
		}
		// Beyond full day + grace → overtime
		return late ? STATUS_LATE_OVERTIME : STATUS_OVERTIME;
	}

	/**
	 * Legacy / fallback overload — uses hardcoded 8h/4h thresholds. Prefer the
	 * 4-argument overload when shift duration is known.
	 */
	public static String compute(LocalDateTime punchIn, LocalDateTime punchOut, long netWorkMs) {
		return compute(punchIn, punchOut, netWorkMs, DEFAULT_FULL_DAY_MS, null);
	}

	// ── Convenience helper for punch-out (computes netWorkMs internally) ─────

	/**
	 * Computes status directly from raw timestamps.
	 *
	 * @param totalBreakMs    all confirmed break durations in ms
	 * @param shiftDurationMs scheduled duration; 0 → use default 8h
	 * @param isLate          pre-computed late flag
	 */
	public static String computeFromTimes(LocalDateTime punchIn, LocalDateTime punchOut, long totalBreakMs,
			long shiftDurationMs, boolean isLate) {
		if (punchOut == null) {
			return STATUS_PENDING;
		}
		long elapsedMs = java.time.Duration.between(punchIn, punchOut).toMillis();
		long netWorkMs = Math.max(0, elapsedMs - totalBreakMs);
		return compute(punchIn, punchOut, netWorkMs, shiftDurationMs, isLate);
	}

	// ── Display helpers ──────────────────────────────────────────────────────

	/** Human-readable label for UI display. */
	public static String label(String status) {
		if (status == null) {
			return "N/A";
		}
		switch (status.toLowerCase()) {
		case "full_day":
			return "Present (Full Day)";
		case "present":
			return "Present (Full Day)"; // legacy alias
		case "half_day":
			return "Half Day";
		case "absent":
			return "Absent";
		case "late":
			return "Late Mark";
		case "late_half":
			return "Late Mark (Half Day)";
		case "overtime":
			return "Present (Overtime)";
		case "late_overtime":
			return "Late Mark (Overtime)";
		case "pending":
			return "In Progress";
		case "auto_close":
		case "system_closed":
			return "Auto-Closed";
		default:
			return status;
		}
	}

	/**
	 * CSS class suffix — used as {@code att-badge--<suffix>} in JSP templates.
	 */
	public static String cssClass(String status) {
		if (status == null) {
			return "unknown";
		}
		switch (status.toLowerCase()) {
		case "full_day":
		case "present":
			return "full";
		case "half_day":
			return "half";
		case "absent":
			return "absent";
		case "late":
			return "late";
		case "late_half":
			return "late-half";
		case "overtime":
			return "overtime";
		case "late_overtime":
			return "late-overtime";
		case "pending":
			return "pending";
		case "auto_close":
		case "system_closed":
			return "auto-close";
		default:
			return "unknown";
		}
	}

	/** Bootstrap Icons icon name for each status (used with {@code bi-<name>}). */
	public static String icon(String status) {
		if (status == null) {
			return "dash-circle";
		}
		switch (status.toLowerCase()) {
		case "full_day":
		case "present":
			return "check-circle-fill";
		case "half_day":
			return "adjust";
		case "absent":
			return "x-circle-fill";
		case "late":
			return "clock-history";
		case "late_half":
			return "exclamation-circle-fill";
		case "overtime":
			return "star-fill";
		case "late_overtime":
			return "exclamation-diamond-fill";
		case "pending":
			return "hourglass-split";
		case "auto_close":
		case "system_closed":
			return "shield-exclamation";
		default:
			return "dash-circle";
		}
	}

	/**
	 * Returns {@code true} when the punch-in time qualifies as a Late Mark.
	 * Convenience method for JSP / report layers.
	 * <p>
	 * Does NOT handle night-shift post-midnight punch-in — use the shift-aware
	 * overload in AttendanceDAO for that case.
	 */
	public static boolean isLate(LocalDateTime punchIn) {
		return punchIn != null && punchIn.toLocalTime().isAfter(LATE_THRESHOLD);
	}

	/** Formats a millisecond duration as {@code "Xh Ym"} for display. */
	public static String formatMs(long ms) {
		if (ms < 0) {
			ms = 0;
		}
		long totalSecs = ms / 1000;
		long h = totalSecs / 3600;
		long m = (totalSecs % 3600) / 60;
		return h + "h " + String.format("%02d", m) + "m";
	}

	/**
	 * Builds a human-readable toast / notification reason explaining WHY a
	 * particular status was assigned. Used by AttendanceServlet to populate the
	 * contextual toast messages requested in v5.
	 *
	 * @param status       the computed attendance status string
	 * @param shiftName    shift name for context (may be null)
	 * @param lateDeadline formatted late-deadline string e.g. "11:00 AM"
	 * @param punchInStr   formatted punch-in time string e.g. "11:14 AM"
	 * @param netHours     net work hours as a double
	 * @param fullDayHours expected full-day hours
	 * @return a sentence explaining the status (shown in toast + notifications)
	 */
	public static String buildStatusReason(String status, String shiftName, String lateDeadline, String punchInStr,
			double netHours, double fullDayHours) {
		String shift = (shiftName != null && !shiftName.isBlank()) ? " (" + shiftName + ")" : "";
		switch (status.toLowerCase()) {
		case "full_day":
		case "present":
			return "✅ Present — checked in on time" + shift + " and completed " + formatHours(netHours)
					+ " of work (full shift = " + formatHours(fullDayHours) + ").";
		case "half_day":
			return "⚠ Half Day — checked in on time" + shift + " but only completed " + formatHours(netHours)
					+ ". Full shift requires " + formatHours(fullDayHours) + ".";
		case "absent":
			return "❌ Absent — less than half a shift worked (" + formatHours(netHours) + " < "
					+ formatHours(fullDayHours / 2) + " minimum required).";
		case "late":
			return "⏰ Late Mark — checked in at " + punchInStr + " (after " + lateDeadline + " grace deadline)" + shift
					+ " but completed full shift hours (" + formatHours(netHours) + ").";
		case "late_half":
			return "⏰ Late Mark (Half Day) — checked in at " + punchInStr + " (after " + lateDeadline + " deadline)"
					+ shift + " and only completed " + formatHours(netHours) + ".";
		case "overtime":
			return "⭐ Overtime — completed full shift and worked an extra " + formatHours(netHours - fullDayHours)
					+ " beyond scheduled hours" + shift + ".";
		case "late_overtime":
			return "⏰⭐ Late + Overtime — checked in after " + lateDeadline + " but completed " + formatHours(netHours)
					+ " (overtime)" + shift + ".";
		case "auto_close":
			return "🔒 Auto-Closed — the system automatically closed this session. "
					+ "Please contact your administrator if an adjustment is needed.";
		default:
			return "Session status: " + label(status) + ".";
		}
	}

	private static String formatHours(double h) {
		return (h == Math.floor(h)) ? (int) h + "h" : String.format("%.1fh", h);
	}
}
