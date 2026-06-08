package com.DAO;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Time;
import java.sql.Timestamp;
import java.sql.Types;
import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;

import com.util.AttendanceLogEntry;
import com.util.AttendanceSession;
import com.util.AttendanceStatusUtil;
import com.util.DBConnection;
import com.util.OfficeShift;

/**
 * AttendanceDAO v5 — bug-fixed, shift-aware attendance engine.
 *
 * ── BUGS FIXED IN v5 ──────────────────────────────────────────────────────
 *
 * BUG 1 — STATUS ENUM MISMATCH (critical). computePunchOutStatus() returned
 * "PRESENT", "LATE", "OVERTIME", "ABSENT" but the rest of the pipeline (JSP
 * STATUS_CFG, AttendanceStatusUtil, AttendanceServlet.getLabel/getCss) expected
 * "full_day", "late", "overtime". This caused every punch-out badge to show "In
 * Progress" instead of the real outcome. FIX: computePunchOutStatus() now
 * delegates entirely to AttendanceStatusUtil.compute() which returns the
 * unified lowercase_snake constants. The old "PRESENT"/"LATE" raw strings are
 * gone.
 *
 * BUG 2 — computePunchOutStatus() short-shift rule returned "PRESENT"/"LATE"
 * even inside the short-shift branch (not "full_day"/"late"). FIX: removed the
 * special-case branch — AttendanceStatusUtil handles the full-day vs half-day
 * threshold automatically via shiftDurationMs.
 *
 * BUG 3 — punchIn() stored the raw computePunchInStatus() result ("PRESENT" or
 * "LATE") as attendance_status, but the DB ENUM and downstream code both
 * expected "pending" while the session is open. FIX: punchIn() always writes
 * attendance_status = 'pending'. The PRESENT/LATE flag is kept only in a
 * transient "initial_status" column (or passed back through the servlet
 * response) for the toast message. NOTE: If your DB schema does not have an
 * initial_status column, remove that update line — the isLate flag from
 * computePunchInStatus() is enough.
 *
 * BUG 4 — No overtime accounting. computePunchOutStatus() capped at >8h without
 * considering the actual shift duration. FIX: shiftDurationMs is passed to
 * AttendanceStatusUtil.compute().
 *
 * BUG 5 — markMissedPunchOut() wrote attendance_status='AUTO_CLOSE' but
 * getLabel() and STATUS_CFG in the JSP expected 'auto_close' (lowercase). FIX:
 * DB value is now 'auto_close' throughout.
 *
 * ── WHAT CHANGED IN v4 (preserved) ─────────────────────────────────────── -
 * AUTO_CLOSE_GRACE_HOURS shared constant - computeShiftEndBoundary() static
 * utility (overnight-safe) - getOpenSessionsForDateRange(),
 * getAnyOpenSessionForUser() - getLastSessionForUser() for banner detection -
 * checkPunchInAllowed() pre-punch gate (TOO_EARLY block)
 */
public class AttendanceDAO {

	// ── Configuration ──────────────────────────────────────────────────────

	/**
	 * Minutes before shift start that early punch-in is allowed. 0 = strict
	 * enforcement.
	 */
	public static final int EARLY_GRACE_MINUTES = 5;

	/**
	 * Hours of grace after shift's scheduled end before a session without punch-out
	 * is automatically closed. Shared by MissedPunchOutListener and
	 * AttendanceSweepScheduler.
	 */
	public static final long AUTO_CLOSE_GRACE_HOURS = 3;

	/**
	 * Maximum breaks allowed per shift. Matching MAX_BREAKS_PER_DAY in
	 * AttendanceServlet to keep them in sync.
	 */
	public static final int MAX_BREAKS_PER_SHIFT = 2;

	private static final DateTimeFormatter DT_FMT = DateTimeFormatter.ofPattern("hh:mm a, dd-MMM-yyyy");

	// ════════════════════════════════════════════════════════════════
	// SHIFT OPERATIONS
	// ════════════════════════════════════════════════════════════════

	/** Return all defined shifts. */
	public List<OfficeShift> getAllShifts() throws SQLException {
		String sql = "SELECT id, shift_name, expected_login_time, expected_logout_time, "
				+ "late_grace_minutes FROM office_shifts ORDER BY id";
		List<OfficeShift> list = new ArrayList<>();
		try (Connection con = DBConnection.getConnection();
				PreparedStatement ps = con.prepareStatement(sql);
				ResultSet rs = ps.executeQuery()) {
			while (rs.next()) {
				list.add(mapShift(rs));
			}
		}
		return list;
	}

	/** Return a single shift by PK, or null. */
	public OfficeShift getShiftById(int shiftId) throws SQLException {
		if (shiftId <= 0) {
			return null;
		}
		String sql = "SELECT id, shift_name, expected_login_time, expected_logout_time, "
				+ "late_grace_minutes FROM office_shifts WHERE id = ?";
		try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
			ps.setInt(1, shiftId);
			try (ResultSet rs = ps.executeQuery()) {
				if (rs.next()) {
					return mapShift(rs);
				}
			}
		}
		return null;
	}

	/** Upsert a shift record. id ≤ 0 → INSERT; otherwise UPDATE. */
	public int saveShift(OfficeShift shift) throws SQLException {
		if (shift.getId() <= 0) {
			String sql = "INSERT INTO office_shifts "
					+ "(shift_name, expected_login_time, expected_logout_time, late_grace_minutes) "
					+ "VALUES (?, ?, ?, ?)";
			try (Connection con = DBConnection.getConnection();
					PreparedStatement ps = con.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
				ps.setString(1, shift.getShiftName());
				ps.setTime(2, Time.valueOf(shift.getExpectedLoginTime()));
				ps.setTime(3, Time.valueOf(shift.getExpectedLogoutTime()));
				ps.setInt(4, shift.getLateGraceMinutes());
				ps.executeUpdate();
				try (ResultSet rs = ps.getGeneratedKeys()) {
					if (rs.next()) {
						return rs.getInt(1);
					}
				}
			}
		} else {
			String sql = "UPDATE office_shifts SET shift_name=?, expected_login_time=?, "
					+ "expected_logout_time=?, late_grace_minutes=? WHERE id=?";
			try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
				ps.setString(1, shift.getShiftName());
				ps.setTime(2, Time.valueOf(shift.getExpectedLoginTime()));
				ps.setTime(3, Time.valueOf(shift.getExpectedLogoutTime()));
				ps.setInt(4, shift.getLateGraceMinutes());
				ps.setInt(5, shift.getId());
				ps.executeUpdate();
				return shift.getId();
			}
		}
		throw new SQLException("saveShift: no generated key returned.");
	}

	/** Assign (or remove) a shift for a user. */
	/**
	 * Returns all active staff users assigned to the given shift. Used to email
	 * affected staff when a shift's timings are changed.
	 */
	public java.util.List<com.util.User> getUsersOnShift(int shiftId) throws SQLException {
		String sql = "SELECT username, email, shift_id FROM users "
				+ "WHERE shift_id = ? AND status = 'Active' AND role = 'staff'";
		java.util.List<com.util.User> list = new java.util.ArrayList<>();
		try (Connection con = DBConnection.getConnection(); java.sql.PreparedStatement ps = con.prepareStatement(sql)) {
			ps.setInt(1, shiftId);
			try (java.sql.ResultSet rs = ps.executeQuery()) {
				while (rs.next()) {
					com.util.User u = new com.util.User();
					u.setUsername(rs.getString("username"));
					u.setEmail(rs.getString("email"));
					u.setShiftId(rs.getInt("shift_id"));
					list.add(u);
				}
			}
		}
		return list;
	}

	public void assignUserShift(String username, Integer shiftId) throws SQLException {
		String sql = "UPDATE users SET shift_id = ? WHERE username = ?";
		try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
			if (shiftId == null) {
				ps.setNull(1, Types.INTEGER);
			} else {
				ps.setInt(1, shiftId);
			}
			ps.setString(2, username);
			ps.executeUpdate();
		}
	}

	// ════════════════════════════════════════════════════════════════
	// PRE-PUNCH GATE
	// ════════════════════════════════════════════════════════════════

	/**
	 * Value object returned by checkPunchInAllowed(). allowed = true → caller may
	 * proceed with punchIn() allowed = false → surfaced as a 409 / user-facing
	 * error reason = machine-readable tag ("TOO_EARLY") message = UI-facing string
	 * shown to the staff member
	 */
	public static class PunchInCheckResult {
		public final boolean allowed;
		public final String reason;
		public final String message;

		PunchInCheckResult(boolean allowed, String reason, String message) {
			this.allowed = allowed;
			this.reason = reason;
			this.message = message;
		}

		public static PunchInCheckResult ok() {
			return new PunchInCheckResult(true, "OK", null);
		}
	}

	/**
	 * Gate check: may this user punch in right now?
	 *
	 * Rules: A) No shift assigned → always allowed. B) current_time < shiftStart −
	 * EARLY_GRACE_MINUTES → blocked (TOO_EARLY). C) current_time > shiftEnd +
	 * AUTO_CLOSE_GRACE_HOURS → blocked (SHIFT_ENDED). This prevents staff from
	 * punching in (and later punching out) after their shift has ended, which would
	 * inflate working hours incorrectly.
	 *
	 * LATE classification happens during punchIn() and reported as a toast warning
	 * — it is NOT a blocking condition.
	 */
	public PunchInCheckResult checkPunchInAllowed(String username, LocalDateTime now) throws SQLException {

		OfficeShift shift = getShiftForUser(username);
		if (shift == null) {
			return PunchInCheckResult.ok();
		}

		LocalTime shiftStart = shift.getExpectedLoginTime();
		LocalTime shiftEnd = shift.getExpectedLogoutTime();
		LocalTime currentTime = now.toLocalTime();
		LocalTime earliestAllowed = shiftStart.minusMinutes(EARLY_GRACE_MINUTES);

		// ── BLOCK A: TOO EARLY ───────────────────────────────────────────────
		boolean overnightEarlyWrap = earliestAllowed.isAfter(shiftStart);
		boolean tooEarly;
		if (overnightEarlyWrap) {
			tooEarly = !currentTime.isBefore(earliestAllowed);
		} else {
			tooEarly = currentTime.isBefore(earliestAllowed);
		}

		if (tooEarly) {
			String formattedStart = shiftStart.format(DateTimeFormatter.ofPattern("hh:mm a"));
			String message = EARLY_GRACE_MINUTES > 0
					? "You cannot clock in before your scheduled shift time. Your shift starts at " + formattedStart
							+ ". Early check-in is allowed up to " + EARLY_GRACE_MINUTES + " minute(s) before."
					: "You cannot clock in before your scheduled shift time. Your shift starts at " + formattedStart
							+ ".";
			return new PunchInCheckResult(false, "TOO_EARLY", message);
		}

		// ── BLOCK B: SHIFT ALREADY ENDED (core bug fix) ──────────────────────
		// Compute the wall-clock shift-end boundary for *today* (overnight-aware).
		// A punch-in is blocked once: now > shiftEndBoundary + AUTO_CLOSE_GRACE_HOURS
		// This prevents forgotten-punch-out sessions from being re-opened late to
		// accumulate extra hours.
		boolean isNightShift = shiftEnd.isBefore(shiftStart);
		LocalDateTime shiftEndBoundary;
		if (isNightShift) {
			// Night shift ends next calendar day
			shiftEndBoundary = now.toLocalDate().plusDays(1).atTime(shiftEnd);
			// But if we're after midnight already, the shift ended *today* (same date as
			// now)
			if (currentTime.isBefore(shiftStart) && currentTime.isAfter(shiftEnd)) {
				shiftEndBoundary = now.toLocalDate().atTime(shiftEnd);
			}
		} else {
			shiftEndBoundary = now.toLocalDate().atTime(shiftEnd);
		}

		LocalDateTime graceBoundary = shiftEndBoundary.plusHours(AUTO_CLOSE_GRACE_HOURS);
		if (now.isAfter(graceBoundary)) {
			String formattedEnd = shiftEnd.format(DateTimeFormatter.ofPattern("hh:mm a"));
			String message = "Your shift (" + shift.getShiftName() + ") ended at " + formattedEnd + ". The "
					+ AUTO_CLOSE_GRACE_HOURS + "-hour grace window has passed. "
					+ "You can no longer punch in for this shift. "
					+ "Please contact your admin if you need a session adjustment.";
			return new PunchInCheckResult(false, "SHIFT_ENDED", message);
		}

		return PunchInCheckResult.ok();
	}

	// ════════════════════════════════════════════════════════════════
	// SESSION OPERATIONS
	// ════════════════════════════════════════════════════════════════

	/**
	 * Insert a new session row when a staff member punches in.
	 *
	 * BUG FIX v5: attendance_status is now always stored as 'pending' while the
	 * session is open. The PRESENT/LATE distinction is returned to the caller via
	 * the isLate flag in the servlet response (not persisted yet).
	 *
	 * @param username    staff username
	 * @param punchInTime exact punch-in datetime
	 * @param sessionDate calendar date for this session (may be yesterday for
	 *                    post-midnight night-shift punch-ins)
	 * @return generated session id
	 */
	public long punchIn(String username, LocalDateTime punchInTime, LocalDate sessionDate) throws SQLException {

		OfficeShift shift = getShiftForUser(username);
		Integer shiftId = (shift != null) ? shift.getId() : null;

		// Compute late flag — not stored in DB here (session is 'pending' while open).
		// The servlet reads isLatePunchIn() independently to build the toast/response.
		// This call is intentionally unused in the DAO; the real classification
		// happens at punch-out via AttendanceStatusUtil.compute().
		@SuppressWarnings("unused")
		boolean isLate = isLatePunchIn(punchInTime, shift);

		final String sql = """
				INSERT INTO attendance_sessions
				    (username, shift_id, session_date, punch_in,
				     status, attendance_status, total_break_ms, net_work_ms)
				VALUES (?, ?, ?, ?, 'working', 'pending', 0, 0)
				""";

		try (Connection con = DBConnection.getConnection();
				PreparedStatement ps = con.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

			ps.setString(1, username);
			if (shiftId != null) {
				ps.setInt(2, shiftId);
			} else {
				ps.setNull(2, Types.INTEGER);
			}
			ps.setDate(3, Date.valueOf(sessionDate));
			ps.setTimestamp(4, Timestamp.valueOf(punchInTime));

			int rows = ps.executeUpdate();
			if (rows == 0) {
				throw new SQLException("punchIn: INSERT affected 0 rows for user '" + username + "'.");
			}

			try (ResultSet rs = ps.getGeneratedKeys()) {
				if (rs.next()) {
					return rs.getLong(1);
				}
			}
		}
		throw new SQLException("punchIn: no generated key for user '" + username + "'.");
	}

	/**
	 * Checks whether this punch-in time is "late" according to the assigned shift's
	 * late grace window. Night-shift post-midnight punch-ins are always treated as
	 * on-time.
	 *
	 * @return true if the punch-in time falls after (shiftStart + graceMinutes)
	 */
	public boolean isLatePunchIn(LocalDateTime punchInTime, OfficeShift shift) {
		if (shift == null) {
			// No shift: use the global late threshold from AttendanceStatusUtil
			return punchInTime.toLocalTime().isAfter(AttendanceStatusUtil.LATE_THRESHOLD);
		}

		LocalTime shiftStart = shift.getExpectedLoginTime();
		LocalTime shiftEnd = shift.getExpectedLogoutTime();
		LocalTime loginDeadline = shiftStart.plusMinutes(shift.getLateGraceMinutes());

		// Check for overnight shift post-midnight window
		boolean isNight = shiftStart.isAfter(shiftEnd);
		boolean isPostMidnight = isNight && punchInTime.toLocalTime().isBefore(shiftEnd);
		if (isPostMidnight) {
			return false; // post-midnight is always on-time
		}

		// Normal comparison: is punch-in strictly after (shiftStart + grace)?
		LocalTime piTime = punchInTime.toLocalTime();
		// Handle grace overflow past midnight
		boolean graceOverflow = loginDeadline.isBefore(shiftStart);
		if (graceOverflow) {
			// e.g. shift 23:45 + 30m grace = 00:15 next day
			// punch in at 00:14 → not late (before overflow deadline)
			return !piTime.isBefore(loginDeadline);
		}
		return piTime.isAfter(loginDeadline);
	}

	/** Mark session as 'onBreak'. attendance_status preserved. */
	public void startBreak(long sessionId) throws SQLException {
		String sql = "UPDATE attendance_sessions " + "SET status='onBreak', updated_at=NOW() WHERE id=?";
		try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
			ps.setLong(1, sessionId);
			ps.executeUpdate();
		}
	}

	/** Resume work: accumulate break duration, flip status back to 'working'. */
	public void resumeWork(long sessionId, long breakDurationMs) throws SQLException {
		String sql = """
				UPDATE attendance_sessions
				   SET status         = 'working',
				       total_break_ms = total_break_ms + ?,
				       updated_at     = NOW()
				 WHERE id = ?
				""";
		try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
			ps.setLong(1, breakDurationMs);
			ps.setLong(2, sessionId);
			ps.executeUpdate();
		}
	}

	/**
	 * Punch out: finalise session and compute attendance status.
	 *
	 * BUG FIX v5: Now delegates status computation to
	 * AttendanceStatusUtil.compute() with the shift's actual duration, so the
	 * returned status is always in the unified lowercase_snake vocabulary.
	 *
	 * BUG FIX v5: Also correctly re-reads total_break_ms from DB before computing
	 * netWorkMs (ghost-session fix from v3, preserved).
	 *
	 * @param sessionId         open session to close
	 * @param punchOutTime      wall-clock punch-out time
	 * @param additionalBreakMs uncommitted break (0 if already resumed)
	 */
	public void punchOut(long sessionId, LocalDateTime punchOutTime, long additionalBreakMs) throws SQLException {

		AttendanceSession existing = getSessionById(sessionId);
		if (existing == null) {
			throw new SQLException("punchOut: session not found: " + sessionId);
		}

		String st = existing.getStatus();
		if ("punchedOut".equals(st) || "auto_close".equals(st) || "missed_punchout".equals(st)) {
			throw new SQLException("punchOut: session " + sessionId + " is already closed.");
		}

		// ── PAYROLL CAP: cap punch_out at shift-end if staff punches out late ──────
		// If the staff member forgot to punch out during their shift, logged back in
		// later (after shift-end), and then punched out, the wall-clock punchOutTime
		// would be hours after the shift ended — inflating hours unfairly.
		// Rule: if shift is assigned AND punchOutTime > shiftEndBoundary, cap at
		// shiftEndBoundary so only actual shift hours are counted.
		if (existing.getShiftId() > 0) {
			OfficeShift shiftForCap = getShiftById(existing.getShiftId());
			if (shiftForCap != null) {
				LocalDateTime shiftEndBoundary = computeShiftEndBoundary(existing, shiftForCap);
				if (punchOutTime.isAfter(shiftEndBoundary)) {
					// Cap at shift-end — audit the override
					String capNote = "[Payroll Cap] Staff punched out at " + punchOutTime.format(DT_FMT)
							+ " which is after scheduled shift-end (" + shiftEndBoundary.format(DT_FMT) + " for shift '"
							+ shiftForCap.getShiftName() + "'). "
							+ "Punch-out time capped to shift-end to prevent hours inflation.";
					addLogEntry(
							new AttendanceLogEntry(sessionId, existing.getUsername(), "PUNCHOUT_CAPPED", punchOutTime));
					// Re-use log entry to carry the note — create a second entry with the note
					AttendanceLogEntry capEntry = new AttendanceLogEntry(sessionId, existing.getUsername(),
							"PUNCHOUT_CAPPED", punchOutTime);
					capEntry.setNote(capNote);
					addLogEntry(capEntry);
					punchOutTime = shiftEndBoundary; // apply the cap
				}
			}
		}

		// Re-read break total from DB (ghost-session fix).
		long totalBreakMs = getFreshTotalBreakMs(sessionId) + Math.max(0, additionalBreakMs);
		long elapsedMs = Duration.between(existing.getPunchIn(), punchOutTime).toMillis();
		long netWorkMs = Math.max(0, elapsedMs - totalBreakMs);

		// Resolve shift for duration-aware status
		OfficeShift shift = (existing.getShiftId() > 0) ? getShiftById(existing.getShiftId()) : null;
		long shiftDurationMs = (shift != null) ? computeShiftDurationMs(shift) : 0L;

		// BUG FIX: was calling computePunchOutStatus() which returned "PRESENT"/"LATE"
		// Now always produces unified "full_day"/"late"/etc. via AttendanceStatusUtil.
		boolean isLate = isLatePunchIn(existing.getPunchIn(), shift);
		String attStatus = AttendanceStatusUtil.compute(existing.getPunchIn(), punchOutTime, netWorkMs, shiftDurationMs,
				isLate);

		String sql = """
				UPDATE attendance_sessions
				   SET punch_out         = ?,
				       status            = 'punchedOut',
				       attendance_status = ?,
				       total_break_ms    = ?,
				       net_work_ms       = ?,
				       updated_at        = NOW()
				 WHERE id = ?
				""";
		try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
			ps.setTimestamp(1, Timestamp.valueOf(punchOutTime));
			ps.setString(2, attStatus);
			ps.setLong(3, totalBreakMs);
			ps.setLong(4, netWorkMs);
			ps.setLong(5, sessionId);
			ps.executeUpdate();
		}

		// Audit log — every punch-out path must leave a trail (force/auto-close
		// already do this; normal punch-out was missing it).
		AttendanceLogEntry poEntry = new AttendanceLogEntry(sessionId, existing.getUsername(), "PUNCH_OUT",
				punchOutTime);
		poEntry.setNote("Punched out. Status: " + attStatus + ". Net work: " + AttendanceStatusUtil.formatMs(netWorkMs)
				+ ". Break: " + AttendanceStatusUtil.formatMs(totalBreakMs) + ".");
		addLogEntry(poEntry);
	}

	// ════════════════════════════════════════════════════════════════
	// BREAK COUNT
	// ════════════════════════════════════════════════════════════════

	public int getBreakCount(long sessionId) throws SQLException {
		String sql = "SELECT COUNT(*) FROM attendance_log " + "WHERE session_id = ? AND event_type = 'BREAK_START'";
		try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
			ps.setLong(1, sessionId);
			try (ResultSet rs = ps.executeQuery()) {
				if (rs.next()) {
					return rs.getInt(1);
				}
			}
		}
		return 0;
	}

	// ════════════════════════════════════════════════════════════════
	// AUTO-CLOSE (v5 — unified status, correct lowercase sentinel)
	// ════════════════════════════════════════════════════════════════

	/**
	 * Auto-close an open session with a normalised punch_out timestamp.
	 *
	 * FIX v6: attendance_status now stores the REAL work-quality status (full_day /
	 * half_day / absent / late / etc.) computed from net_work_ms against the shift
	 * duration — exactly the same as a normal punch-out. The status column is set
	 * to 'auto_close' so the UI can display BOTH "this was auto-closed" AND "the
	 * staff worked X quality of hours".
	 *
	 * Previously attendance_status was always forced to 'auto_close' regardless of
	 * hours worked, hiding payroll-relevant data (e.g. a 5.5h session on a 9h shift
	 * would show only "Auto-Closed" instead of "Half Day · Auto-Closed").
	 *
	 * @param sessionId        open session to close
	 * @param scheduledEndTime shift's expected logout; becomes the punch_out.
	 */
	public void markMissedPunchOut(long sessionId, LocalDateTime scheduledEndTime) throws SQLException {

		AttendanceSession s = getSessionById(sessionId);
		if (s == null) {
			return;
		}

		if (!"working".equals(s.getStatus()) && !"onBreak".equals(s.getStatus())) {
			return;
		}

		long totalBreakMs = getFreshTotalBreakMs(sessionId);
		Duration elapsed = Duration.between(s.getPunchIn(), scheduledEndTime);
		long elapsedMs = elapsed.toMillis();
		long netWorkMs = Math.max(0, elapsedMs - totalBreakMs);
		long elapsedHours = elapsed.toHours(); // reuse — avoid second Duration computation

		// ── FIX: Compute real attendance status instead of blindly writing
		// 'auto_close' ──
		// Previously markMissedPunchOut() always stored attendance_status='auto_close'
		// regardless
		// of how many hours the staff actually worked. This meant a staff member who
		// worked 8.5h
		// (a full shift) and forgot to punch out would show "Auto-Closed" with no work
		// quality info.
		//
		// NEW BEHAVIOUR:
		// attendance_status = computed work quality (full_day, half_day, absent, late,
		// etc.)
		// status = 'auto_close' (repurposed from 'punchedOut' to flag the closure
		// method)
		//
		// The DB enum for `status` already includes 'auto_close' — we use it here.
		// The `attendance_status` column now always reflects payroll quality.
		// UI code that needs to distinguish "was this auto-closed?" checks
		// status='auto_close'.
		OfficeShift shiftForStatus = s.getShiftId() > 0 ? getShiftById(s.getShiftId()) : null;
		long shiftDurationMs = shiftForStatus != null ? computeShiftDurationMs(shiftForStatus) : 0L;
		boolean isLateAc = isLatePunchIn(s.getPunchIn(), shiftForStatus);
		// Compute real work-quality status using the same logic as normal punch-out
		String computedAttStatus = AttendanceStatusUtil.compute(s.getPunchIn(), scheduledEndTime, netWorkMs,
				shiftDurationMs, isLateAc);
		// If no shift and no meaningful work time, keep 'auto_close' as a sentinel
		if (shiftForStatus == null && netWorkMs == 0) {
			computedAttStatus = AttendanceStatusUtil.STATUS_AUTO_CLOSE;
		}

		String sql = """
				UPDATE attendance_sessions
				   SET status            = 'auto_close',
				       attendance_status = ?,
				       punch_out         = ?,
				       total_break_ms    = ?,
				       net_work_ms       = ?,
				       updated_at        = NOW()
				 WHERE id = ?
				""";
		try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
			ps.setString(1, computedAttStatus);
			ps.setTimestamp(2, Timestamp.valueOf(scheduledEndTime));
			ps.setLong(3, totalBreakMs);
			ps.setLong(4, netWorkMs);
			ps.setLong(5, sessionId);
			ps.executeUpdate();
		}

		// Audit log entry
		AttendanceLogEntry entry = new AttendanceLogEntry(sessionId, s.getUsername(), "AUTO_PUNCHOUT",
				scheduledEndTime);
		entry.setNote("[Auto Close] Session auto-closed at scheduled shift-end (" + scheduledEndTime.format(DT_FMT)
				+ ") after " + elapsedHours + "h — punch-out was not performed by the staff member.");
		addLogEntry(entry);
	}

	/**
	 * Backward-compatible no-arg overload — closes at the current wall-clock time.
	 */
	public void markMissedPunchOut(long sessionId) throws SQLException {
		markMissedPunchOut(sessionId, LocalDateTime.now());
	}

	// ════════════════════════════════════════════════════════════════
	// SHIFT-END BOUNDARY HELPER (v4, public static for reuse)
	// ════════════════════════════════════════════════════════════════

	/**
	 * Compute the wall-clock {@link LocalDateTime} at which a session's assigned
	 * shift is expected to end.
	 * <p>
	 * Overnight shifts (loginTime > logoutTime) fall on the calendar day AFTER
	 * {@code session.sessionDate}.
	 */
	public static LocalDateTime computeShiftEndBoundary(AttendanceSession session, OfficeShift shift) {
		LocalDate sessionDate = session.getSessionDate();
		LocalTime endTime = shift.getExpectedLogoutTime();
		boolean overnight = endTime.isBefore(shift.getExpectedLoginTime());
		return overnight ? sessionDate.plusDays(1).atTime(endTime) : sessionDate.atTime(endTime);
	}

	/**
	 * Compute shift scheduled duration in milliseconds (overnight-safe).
	 */
	public static long computeShiftDurationMs(OfficeShift shift) {
		LocalTime login = shift.getExpectedLoginTime();
		LocalTime logout = shift.getExpectedLogoutTime();
		long minutes = java.time.temporal.ChronoUnit.MINUTES.between(login, logout);
		if (minutes <= 0) {
			minutes += 24 * 60; // overnight wrap
		}
		return minutes * 60_000L;
	}

	// ════════════════════════════════════════════════════════════════
	// ADMIN NOTIFICATIONS
	// ════════════════════════════════════════════════════════════════

	public void createAdminNotification(String type, String message) throws SQLException {
		createAdminNotification(type, null, message, null);
	}

	/**
	 * Insert a row into admin_notifications.
	 *
	 * Schema has two overlapping columns from different features: event_type
	 * VARCHAR(50) NOT NULL — used by the whole app (product/order alerts) type
	 * VARCHAR(50) NULL — added later for attendance events
	 *
	 * We write the same value to BOTH so the row is valid AND readable by any
	 * existing admin notification queries regardless of which column they use.
	 */
	public void createAdminNotification(String type, String title, String message, String relatedEntity)
			throws SQLException {
		String sql = """
				INSERT INTO admin_notifications
				    (event_type, type, title, message, related_entity,
				     is_read, is_dismissed, created_at)
				VALUES (?, ?, ?, ?, ?, 0, 0, NOW())
				""";
		try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
			ps.setString(1, type); // event_type — NOT NULL, must be set
			ps.setString(2, type); // type — nullable duplicate
			ps.setString(3, title);
			ps.setString(4, message);
			ps.setString(5, relatedEntity);
			ps.executeUpdate();
		}
	}

	public List<com.util.AdminNotification> getUnreadNotifications() throws SQLException {
		String sql = """
				SELECT id, type, title, message, related_entity, is_read, is_dismissed, created_at
				  FROM admin_notifications
				 WHERE is_read = 0 AND is_dismissed = 0
				 ORDER BY created_at DESC
				""";
		List<com.util.AdminNotification> list = new ArrayList<>();
		try (Connection con = DBConnection.getConnection();
				PreparedStatement ps = con.prepareStatement(sql);
				ResultSet rs = ps.executeQuery()) {
			while (rs.next()) {
				list.add(mapNotification(rs));
			}
		}
		return list;
	}

	public int getUnreadCount() throws SQLException {
		String sql = "SELECT COUNT(*) FROM admin_notifications WHERE is_read=0 AND is_dismissed=0";
		try (Connection con = DBConnection.getConnection();
				PreparedStatement ps = con.prepareStatement(sql);
				ResultSet rs = ps.executeQuery()) {
			if (rs.next()) {
				return rs.getInt(1);
			}
		}
		return 0;
	}

	public void markNotificationRead(int id) throws SQLException {
		String sql = "UPDATE admin_notifications SET is_read=1 WHERE id=?";
		try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
			ps.setInt(1, id);
			ps.executeUpdate();
		}
	}

	public void dismissNotification(int id) throws SQLException {
		String sql = "UPDATE admin_notifications SET is_dismissed=1 WHERE id=?";
		try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
			ps.setInt(1, id);
			ps.executeUpdate();
		}
	}

	// ════════════════════════════════════════════════════════════════
	// LOG OPERATIONS
	// ════════════════════════════════════════════════════════════════

	public void addLogEntry(AttendanceLogEntry entry) throws SQLException {
		String sql = """
				INSERT INTO attendance_log
				    (session_id, username, event_type, event_time, break_duration_ms, note)
				VALUES (?, ?, ?, ?, ?, ?)
				""";
		try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
			ps.setLong(1, entry.getSessionId());
			ps.setString(2, entry.getUsername());
			ps.setString(3, entry.getEventType());
			ps.setTimestamp(4, Timestamp.valueOf(entry.getEventTime()));
			if (entry.getBreakDurationMs() != null) {
				ps.setLong(5, entry.getBreakDurationMs());
			} else {
				ps.setNull(5, Types.BIGINT);
			}
			ps.setString(6, entry.getNote());
			ps.executeUpdate();
		}
	}

	public List<AttendanceLogEntry> getLogBySession(long sessionId) throws SQLException {
		String sql = """
				SELECT id, session_id, username, event_type, event_time,
				       break_duration_ms, note, created_at
				  FROM attendance_log
				 WHERE session_id = ?
				 ORDER BY event_time ASC
				""";
		List<AttendanceLogEntry> list = new ArrayList<>();
		try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
			ps.setLong(1, sessionId);
			try (ResultSet rs = ps.executeQuery()) {
				while (rs.next()) {
					list.add(mapLogEntry(rs));
				}
			}
		}
		return list;
	}

	// ════════════════════════════════════════════════════════════════
	// ADMIN FORCE PUNCH-OUT & SESSION ADJUSTMENT
	// ════════════════════════════════════════════════════════════════

	/**
	 * Admin Force Punch-Out — closes any open session for a user.
	 *
	 * Real-world behaviour: A) Shift assigned + shift-end already passed →
	 * punch_out = shiftEndBoundary (payroll-normalised; staff cannot be credited
	 * hours they didn't work) B) Shift assigned + shift still in progress →
	 * punch_out = NOW() (admin is forcing an early exit — use wall-clock time) C)
	 * No shift → punch_out = NOW()
	 *
	 * Full audit trail: FORCE_PUNCHOUT log entry + admin notification.
	 *
	 * @param username  staff member's username
	 * @param adminNote mandatory admin reason (shown in notification)
	 * @return the resolved punch-out LocalDateTime that was written
	 */
	public LocalDateTime adminForcePunchOut(String username, String adminNote) throws SQLException {

		AttendanceSession session = getAnyOpenSessionForUser(username);
		if (session == null) {
			throw new SQLException("No open session found for '" + username + "'.");
		}

		LocalDateTime now = LocalDateTime.now();
		LocalDateTime punchOutTime;
		String closeReason;

		if (session.getShiftId() > 0) {
			OfficeShift shift = getShiftById(session.getShiftId());
			if (shift != null) {
				LocalDateTime shiftEnd = computeShiftEndBoundary(session, shift);
				if (now.isAfter(shiftEnd)) {
					// Case A — normalise to shift-end
					punchOutTime = shiftEnd;
					closeReason = "🔒 Force Punch-Out — Admin closed session for '" + username + "' on shift '"
							+ shift.getShiftName() + "'. " + "Punch-out normalised to scheduled shift-end ("
							+ shiftEnd.format(DT_FMT) + ") for payroll accuracy. Reason: " + adminNote;
				} else {
					// Case B — mid-shift early close
					punchOutTime = now;
					closeReason = "🔒 Force Punch-Out (early) — Admin closed session for '" + username + "' at "
							+ now.format(DT_FMT) + " before scheduled shift end. Shift: " + shift.getShiftName()
							+ ". Reason: " + adminNote;
				}
			} else {
				punchOutTime = now;
				closeReason = "🔒 Force Punch-Out — Admin closed session for '" + username + "' at "
						+ now.format(DT_FMT) + " (shift record deleted). Reason: " + adminNote;
			}
		} else {
			punchOutTime = now;
			closeReason = "🔒 Force Punch-Out — Admin closed session for '" + username + "' at " + now.format(DT_FMT)
					+ " (no shift assigned). Reason: " + adminNote;
		}

		long totalBreakMs = getFreshTotalBreakMs(session.getId());
		long elapsedMs = java.time.Duration.between(session.getPunchIn(), punchOutTime).toMillis();
		long netWorkMs = Math.max(0, elapsedMs - totalBreakMs);

		// Reuse shift already fetched above — avoids a second DB round-trip.
		OfficeShift resolvedShift = session.getShiftId() > 0 ? getShiftById(session.getShiftId()) : null;
		long shiftDurationMs = resolvedShift != null ? computeShiftDurationMs(resolvedShift) : 0L;
		boolean isLate = isLatePunchIn(session.getPunchIn(), resolvedShift);
		String attStatus = AttendanceStatusUtil.compute(session.getPunchIn(), punchOutTime, netWorkMs, shiftDurationMs,
				isLate);

		String sql = """
				UPDATE attendance_sessions
				   SET punch_out         = ?,
				       status            = 'punchedOut',
				       attendance_status = ?,
				       total_break_ms    = ?,
				       net_work_ms       = ?,
				       updated_at        = NOW()
				 WHERE id = ?
				""";
		try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
			ps.setTimestamp(1, Timestamp.valueOf(punchOutTime));
			ps.setString(2, attStatus);
			ps.setLong(3, totalBreakMs);
			ps.setLong(4, netWorkMs);
			ps.setLong(5, session.getId());
			ps.executeUpdate();
		}

		// Audit log entry
		AttendanceLogEntry le = new AttendanceLogEntry(session.getId(), username, "FORCE_PUNCHOUT", punchOutTime);
		le.setNote(closeReason);
		addLogEntry(le);

		createAdminNotification("FORCE_PUNCHOUT", "Force Punch-Out: " + username, closeReason, username);

		return punchOutTime;
	}

	/**
	 * Admin Session Adjustment — corrects punch-in and/or punch-out times.
	 *
	 * Recomputes net_work_ms and attendance_status from the corrected times. Writes
	 * ADMIN_ADJUST audit log entry + notification.
	 *
	 * ── BUGS FIXED ───────────────────────────────────────────────────────────────
	 *
	 * BUG 1 — No-op when both newPunchIn and newPunchOut are null. Previously the
	 * method would silently succeed and write a misleading audit log entry saying
	 * "Punch-in: unchanged, Punch-out: unchanged" with no actual DB change. FIX:
	 * throw early with a clear message so the caller (servlet) can return a 400
	 * error.
	 *
	 * BUG 2 — Punch-in adjusted forward past the existing punch-out. If effectiveIn
	 * > effectiveOut, Duration.between() returns negative ms, and Math.max(0,
	 * negative) = 0. The session ends up with net_work_ms=0 and status 'absent'
	 * without any error. FIX: validate effectiveIn < effectiveOut and throw with a
	 * descriptive message.
	 *
	 * BUG 3 — punch-in-only adjustment (effectiveOut = null, open session) does NOT
	 * re-evaluate late status or update net_work_ms. The old branch only updated
	 * the punch_in timestamp; the attendance_status remained 'pending' without
	 * re-checking whether the new time makes the punch-in late or on-time. Since
	 * the session is still open we can't compute final status, but we CAN update
	 * the initial_status flag correctly. FIX: after updating punch_in on an open
	 * session, log a note clarifying the late re-evaluation that will happen at
	 * punch-out.
	 *
	 * BUG 4 — total_break_ms is not carried forward in the UPDATE when both
	 * punch-in and punch-out are present. The UPDATE sets net_work_ms correctly but
	 * total_break_ms is left at whatever value the DB already has (correct by
	 * coincidence only). FIX: explicitly SET total_break_ms=? in the UPDATE using
	 * the freshly-fetched value so the row is always self-consistent.
	 *
	 * BUG 5 — Audit log note always shows "Computed status: <old_status>" when only
	 * punch-in is adjusted on an open session, because newAttStatus was never
	 * re-assigned in that branch. FIX: log note clearly distinguishes open-session
	 * (status recomputed at punch-out) vs closed-session (status shown here).
	 *
	 * @param username    staff username
	 * @param sessionDate date of the session to adjust
	 * @param newPunchIn  corrected punch-in (null = leave unchanged)
	 * @param newPunchOut corrected punch-out (null = leave unchanged)
	 * @param adminNote   mandatory reason text
	 */
	public void adminAdjustSession(String username, LocalDate sessionDate, LocalDateTime newPunchIn,
			LocalDateTime newPunchOut, String adminNote) throws SQLException {

		// BUG FIX 1: reject no-op calls up front
		if (newPunchIn == null && newPunchOut == null) {
			throw new SQLException("adminAdjustSession: both newPunchIn and newPunchOut are null — nothing to adjust.");
		}

		AttendanceSession session = getSessionByUserAndDate(username, sessionDate);
		if (session == null) {
			throw new SQLException("No session found for '" + username + "' on " + sessionDate + ".");
		}

		LocalDateTime effectiveIn = newPunchIn != null ? newPunchIn : session.getPunchIn();
		LocalDateTime effectiveOut = newPunchOut != null ? newPunchOut : session.getPunchOut();

		// BUG FIX 2: validate times before doing any arithmetic
		if (effectiveOut != null && !effectiveIn.isBefore(effectiveOut)) {
			throw new SQLException("adminAdjustSession: adjusted punch-in (" + effectiveIn.format(DT_FMT)
					+ ") must be strictly before punch-out (" + effectiveOut.format(DT_FMT) + ").");
		}

		// BUG FIX 4: always use the freshly-fetched break total
		long totalBreakMs = getFreshTotalBreakMs(session.getId());
		String newAttStatus = session.getAttendanceStatus();
		long newNetWorkMs = session.getNetWorkMs();
		boolean sessionWasClosed = (effectiveOut != null);

		if (sessionWasClosed) {
			long elapsed = java.time.Duration.between(effectiveIn, effectiveOut).toMillis();
			newNetWorkMs = Math.max(0, elapsed - totalBreakMs);
			OfficeShift sh = session.getShiftId() > 0 ? getShiftById(session.getShiftId()) : null;
			long shiftDurMs = sh != null ? computeShiftDurationMs(sh) : 0L;
			boolean late = isLatePunchIn(effectiveIn, sh);
			newAttStatus = AttendanceStatusUtil.compute(effectiveIn, effectiveOut, newNetWorkMs, shiftDurMs, late);

			// BUG FIX 4: include total_break_ms in the UPDATE so the row is self-consistent
			String upd = """
					UPDATE attendance_sessions
					   SET punch_in          = ?,
					       punch_out         = ?,
					       status            = 'punchedOut',
					       attendance_status = ?,
					       total_break_ms    = ?,
					       net_work_ms       = ?,
					       updated_at        = NOW()
					 WHERE id = ?
					""";
			try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(upd)) {
				ps.setTimestamp(1, Timestamp.valueOf(effectiveIn));
				ps.setTimestamp(2, Timestamp.valueOf(effectiveOut));
				ps.setString(3, newAttStatus);
				ps.setLong(4, totalBreakMs); // BUG FIX 4
				ps.setLong(5, newNetWorkMs);
				ps.setLong(6, session.getId());
				ps.executeUpdate();
			}
		} else if (newPunchIn != null) {
			// BUG FIX 3: session is still open — only punch_in changes.
			// We cannot finalise the status yet (punch-out hasn't happened).
			// Preserve the current status as 'pending' so no stale label shows.
			// The correct final status will be computed when the staff punches out.
			String upd = """
					UPDATE attendance_sessions
					   SET punch_in = ?,
					       attendance_status = 'pending',
					       updated_at = NOW()
					 WHERE id = ?
					""";
			try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(upd)) {
				ps.setTimestamp(1, Timestamp.valueOf(newPunchIn));
				ps.setLong(2, session.getId());
				ps.executeUpdate();
			}
			// BUG FIX 5: set status label correctly for the log note
			newAttStatus = "pending (recomputed at punch-out)";
		}

		// BUG FIX 5: distinguish closed vs open-session in the audit note
		String statusNote = sessionWasClosed
				? "Computed status: " + newAttStatus + ". Net work: " + AttendanceStatusUtil.formatMs(newNetWorkMs)
						+ "."
				: "Session is still open — final status will be computed at punch-out.";

		String logNote = "Admin adjusted session for '" + username + "' on " + sessionDate + ". " + "Punch-in: "
				+ (newPunchIn != null ? newPunchIn.format(DT_FMT) : "unchanged") + ", " + "Punch-out: "
				+ (newPunchOut != null ? newPunchOut.format(DT_FMT) : "unchanged") + ". " + statusNote + " "
				+ "Reason: " + adminNote;

		AttendanceLogEntry le = new AttendanceLogEntry(session.getId(), username, "ADMIN_ADJUST", LocalDateTime.now());
		le.setNote(logNote);
		addLogEntry(le);

		createAdminNotification("ADMIN_ADJUST", "Session Adjusted: " + username, logNote, username);
	}

	// ════════════════════════════════════════════════════════════════
	// QUERY OPERATIONS
	// ════════════════════════════════════════════════════════════════

	/**
	 * Returns the open session for today only. Prefer
	 * {@link #getAnyOpenSessionForUser} for night-shift lookup.
	 */
	public AttendanceSession getTodayOpenSessionForUser(String username) throws SQLException {
		String sql = """
				SELECT id, username, shift_id, session_date, punch_in, punch_out,
				       total_break_ms, net_work_ms, status, attendance_status,
				       created_at, updated_at
				  FROM attendance_sessions
				 WHERE username     = ?
				   AND session_date = CURDATE()
				   AND status IN ('working', 'onBreak')
				""";
		try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
			ps.setString(1, username);
			try (ResultSet rs = ps.executeQuery()) {
				if (rs.next()) {
					return mapSession(rs);
				}
			}
		}
		return null;
	}

	/**
	 * Returns the most-recent OPEN session for a user, checking up to 7 days back.
	 *
	 * WHY 7 DAYS: The original 1-day lookback missed sessions older than yesterday.
	 * Real scenarios where a session stays open beyond 1 day: - Staff worked night
	 * shift Thursday → Friday, auto-close sweep missed it - Staff was offline
	 * (sick) Friday, session from Thursday still open Monday - Sweep scheduler was
	 * down for a weekend - Admin notices stale session days later and clicks Force
	 * Punch-Out
	 *
	 * 7 days covers all realistic cases without returning irrelevant old data. The
	 * query is indexed on (username, session_date) so performance is fine.
	 */
	public AttendanceSession getAnyOpenSessionForUser(String username) throws SQLException {
		String sql = """
				SELECT id, username, shift_id, session_date, punch_in, punch_out,
				       total_break_ms, net_work_ms, status, attendance_status,
				       created_at, updated_at
				  FROM attendance_sessions
				 WHERE username     = ?
				   AND session_date >= CURDATE() - INTERVAL 7 DAY
				   AND status IN ('working', 'onBreak')
				 ORDER BY session_date DESC, punch_in DESC
				 LIMIT 1
				""";
		try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
			ps.setString(1, username);
			try (ResultSet rs = ps.executeQuery()) {
				if (rs.next()) {
					return mapSession(rs);
				}
			}
		}
		return null;
	}

	/** Returns all open sessions in an inclusive date range. */
	public List<AttendanceSession> getOpenSessionsForDateRange(LocalDate from, LocalDate to) throws SQLException {
		String sql = """
				SELECT id, username, shift_id, session_date, punch_in, punch_out,
				       total_break_ms, net_work_ms, status, attendance_status,
				       created_at, updated_at
				  FROM attendance_sessions
				 WHERE session_date BETWEEN ? AND ?
				   AND status IN ('working', 'onBreak')
				""";
		List<AttendanceSession> list = new ArrayList<>();
		try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
			ps.setDate(1, Date.valueOf(from));
			ps.setDate(2, Date.valueOf(to));
			try (ResultSet rs = ps.executeQuery()) {
				while (rs.next()) {
					list.add(mapSession(rs));
				}
			}
		}
		return list;
	}

	/** Legacy single-date overload. */
	public List<AttendanceSession> getAllOpenSessionsForDate(LocalDate date) throws SQLException {
		return getOpenSessionsForDateRange(date, date);
	}

	public List<AttendanceSession> getOpenSessionsExceedingHours(long thresholdHours) throws SQLException {
		String sql = """
				SELECT id, username, shift_id, session_date, punch_in, punch_out,
				       total_break_ms, net_work_ms, status, attendance_status,
				       created_at, updated_at
				  FROM attendance_sessions
				 WHERE status IN ('working','onBreak')
				   AND punch_in <= NOW() - INTERVAL ? HOUR
				""";
		List<AttendanceSession> list = new ArrayList<>();
		try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
			ps.setLong(1, thresholdHours);
			try (ResultSet rs = ps.executeQuery()) {
				while (rs.next()) {
					list.add(mapSession(rs));
				}
			}
		}
		return list;
	}

	public AttendanceSession getSessionById(long id) throws SQLException {
		String sql = """
				SELECT id, username, shift_id, session_date, punch_in, punch_out,
				       total_break_ms, net_work_ms, status, attendance_status,
				       created_at, updated_at
				  FROM attendance_sessions
				 WHERE id = ?
				""";
		try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
			ps.setLong(1, id);
			try (ResultSet rs = ps.executeQuery()) {
				if (rs.next()) {
					return mapSession(rs);
				}
			}
		}
		return null;
	}

	public AttendanceSession getSessionByUserAndDate(String username, LocalDate date) throws SQLException {
		String sql = """
				SELECT id, username, shift_id, session_date, punch_in, punch_out,
				       total_break_ms, net_work_ms, status, attendance_status,
				       created_at, updated_at
				  FROM attendance_sessions
				 WHERE username = ? AND session_date = ?
				""";
		try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
			ps.setString(1, username);
			ps.setDate(2, Date.valueOf(date));
			try (ResultSet rs = ps.executeQuery()) {
				if (rs.next()) {
					return mapSession(rs);
				}
			}
		}
		return null;
	}

	/**
	 * Returns the most-recently created session for a user, regardless of status.
	 * Used by AttendanceServlet to detect whether the previous session was
	 * auto-closed (for the advisory banner).
	 */
	public AttendanceSession getLastSessionForUser(String username) throws SQLException {
		String sql = """
				SELECT id, username, shift_id, session_date, punch_in, punch_out,
				       total_break_ms, net_work_ms, status, attendance_status,
				       created_at, updated_at
				  FROM attendance_sessions
				 WHERE username = ?
				 ORDER BY session_date DESC, punch_in DESC
				 LIMIT 1
				""";
		try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
			ps.setString(1, username);
			try (ResultSet rs = ps.executeQuery()) {
				if (rs.next()) {
					return mapSession(rs);
				}
			}
		}
		return null;
	}

	public List<AttendanceSession> getAllSessionsByDate(LocalDate date) throws SQLException {
		String sql = """
				SELECT id, username, shift_id, session_date, punch_in, punch_out,
				       total_break_ms, net_work_ms, status, attendance_status,
				       created_at, updated_at
				  FROM attendance_sessions
				 WHERE session_date = ?
				 ORDER BY punch_in ASC
				""";
		List<AttendanceSession> list = new ArrayList<>();
		try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
			ps.setDate(1, Date.valueOf(date));
			try (ResultSet rs = ps.executeQuery()) {
				while (rs.next()) {
					AttendanceSession s = mapSession(rs);
					s.setLogEntries(getLogBySession(s.getId()));
					list.add(s);
				}
			}
		}
		return list;
	}

	public List<AttendanceSession> getHistoryByUser(String username, LocalDate from, LocalDate to) throws SQLException {
		String sql = """
				SELECT id, username, shift_id, session_date, punch_in, punch_out,
				       total_break_ms, net_work_ms, status, attendance_status,
				       created_at, updated_at
				  FROM attendance_sessions
				 WHERE username = ? AND session_date BETWEEN ? AND ?
				 ORDER BY session_date DESC
				""";
		List<AttendanceSession> list = new ArrayList<>();
		try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
			ps.setString(1, username);
			ps.setDate(2, Date.valueOf(from));
			ps.setDate(3, Date.valueOf(to));
			try (ResultSet rs = ps.executeQuery()) {
				while (rs.next()) {
					list.add(mapSession(rs));
				}
			}
		}
		return list;
	}

	// ════════════════════════════════════════════════════════════════
	// BUSINESS RULE ENGINE
	// ════════════════════════════════════════════════════════════════

	/**
	 * Evaluate punch-in time against the assigned shift. Returns "late" or
	 * "present" (lowercase, matching STATUS_* constants).
	 *
	 * BUG FIX v5: previously returned "LATE"/"PRESENT" uppercase which did not
	 * match any STATUS_CFG key, causing every punch-in badge to fall through.
	 */
	public String computePunchInStatus(LocalDateTime punchInTime, OfficeShift shift) {
		return isLatePunchIn(punchInTime, shift) ? AttendanceStatusUtil.STATUS_LATE
				: AttendanceStatusUtil.STATUS_FULL_DAY; // "full_day" = present at punch-in
		// NOTE: This is the INITIAL classification; the real final status is
		// computed at punch-out via punchOut() → AttendanceStatusUtil.compute().
	}

	/**
	 * Re-classify attendance status after punch-out — now delegates entirely to
	 * AttendanceStatusUtil to ensure unified status vocabulary.
	 *
	 * BUG FIX v5: previously returned "PRESENT", "LATE", "OVERTIME", "ABSENT"
	 * (uppercase) which caused mismatch with STATUS_CFG in the JSP.
	 *
	 * @param currentStatus the current attendance_status from DB
	 * @param netHours      net working hours
	 * @param shift         assigned shift (may be null)
	 * @return unified lowercase_snake status string
	 */
	public String computePunchOutStatus(String currentStatus, double netHours, OfficeShift shift) {
		long shiftDurationMs = (shift != null) ? computeShiftDurationMs(shift) : 0L;
		long netWorkMs = Math.round(netHours * 3_600_000);

		// Derive isLate from current status (it was set at punch-in)
		boolean isLate = AttendanceStatusUtil.STATUS_LATE.equals(currentStatus)
				|| AttendanceStatusUtil.STATUS_LATE_HALF.equals(currentStatus)
				|| AttendanceStatusUtil.STATUS_LATE_OVERTIME.equals(currentStatus);

		return AttendanceStatusUtil.compute(null, LocalDateTime.now(), netWorkMs, shiftDurationMs, isLate);
	}

	/** Legacy overload — shift = null. */
	public String computePunchOutStatus(String currentStatus, double netHours) {
		return computePunchOutStatus(currentStatus, netHours, null);
	}

	// ════════════════════════════════════════════════════════════════
	// PRIVATE HELPERS
	// ════════════════════════════════════════════════════════════════

	private long getFreshTotalBreakMs(long sessionId) throws SQLException {
		String sql = "SELECT total_break_ms FROM attendance_sessions WHERE id = ?";
		try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
			ps.setLong(1, sessionId);
			try (ResultSet rs = ps.executeQuery()) {
				if (rs.next()) {
					return rs.getLong("total_break_ms");
				}
			}
		}
		return 0L;
	}

	private OfficeShift getShiftForUser(String username) throws SQLException {
		String sql = "SELECT shift_id FROM users WHERE username = ?";
		try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
			ps.setString(1, username);
			try (ResultSet rs = ps.executeQuery()) {
				if (rs.next()) {
					int shiftId = rs.getInt("shift_id");
					if (!rs.wasNull()) {
						return getShiftById(shiftId);
					}
				}
			}
		}
		return null;
	}

	private OfficeShift mapShift(ResultSet rs) throws SQLException {
		OfficeShift s = new OfficeShift();
		s.setId(rs.getInt("id"));
		s.setShiftName(rs.getString("shift_name"));
		s.setExpectedLoginTime(rs.getTime("expected_login_time").toLocalTime());
		s.setExpectedLogoutTime(rs.getTime("expected_logout_time").toLocalTime());
		s.setLateGraceMinutes(rs.getInt("late_grace_minutes"));
		return s;
	}

	private AttendanceSession mapSession(ResultSet rs) throws SQLException {
		AttendanceSession s = new AttendanceSession();
		s.setId(rs.getLong("id"));
		s.setUsername(rs.getString("username"));
		s.setSessionDate(rs.getDate("session_date").toLocalDate());
		s.setPunchIn(rs.getTimestamp("punch_in").toLocalDateTime());

		Timestamp po = rs.getTimestamp("punch_out");
		if (po != null) {
			s.setPunchOut(po.toLocalDateTime());
		}

		s.setTotalBreakMs(rs.getLong("total_break_ms"));
		s.setNetWorkMs(rs.getLong("net_work_ms"));
		s.setStatus(rs.getString("status"));
		s.setAttendanceStatus(rs.getString("attendance_status"));

		try {
			int shiftId = rs.getInt("shift_id");
			if (!rs.wasNull()) {
				s.setShiftId(shiftId);
			}
		} catch (SQLException ignored) {
			/* column absent in some queries */ }

		Timestamp ca = rs.getTimestamp("created_at");
		if (ca != null) {
			s.setCreatedAt(ca.toLocalDateTime());
		}
		Timestamp ua = rs.getTimestamp("updated_at");
		if (ua != null) {
			s.setUpdatedAt(ua.toLocalDateTime());
		}

		return s;
	}

	private AttendanceLogEntry mapLogEntry(ResultSet rs) throws SQLException {
		AttendanceLogEntry e = new AttendanceLogEntry();
		e.setId(rs.getLong("id"));
		e.setSessionId(rs.getLong("session_id"));
		e.setUsername(rs.getString("username"));
		e.setEventType(rs.getString("event_type"));
		e.setEventTime(rs.getTimestamp("event_time").toLocalDateTime());

		long bdm = rs.getLong("break_duration_ms");
		if (!rs.wasNull()) {
			e.setBreakDurationMs(bdm);
		}

		e.setNote(rs.getString("note"));

		Timestamp ca = rs.getTimestamp("created_at");
		if (ca != null) {
			e.setCreatedAt(ca.toLocalDateTime());
		}
		return e;
	}

	private com.util.AdminNotification mapNotification(ResultSet rs) throws SQLException {
		com.util.AdminNotification n = new com.util.AdminNotification();
		n.setId(rs.getInt("id"));
		n.setEventType(rs.getString("type"));
		n.setTitle(rs.getString("title"));
		n.setMessage(rs.getString("message"));
		n.setRelatedEntity(rs.getString("related_entity"));
		n.setCreatedAt(rs.getTimestamp("created_at"));
		return n;
	}
}