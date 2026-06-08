package com.util;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Represents one work session (punch-in → punch-out) for a staff member.
 *
 * ── CHANGES IN v5 ───────────────────────────────────────────────────────── -
 * attendanceStatus default changed from "pending" to "pending" (unchanged), but
 * getAttendanceLabel/CssClass/Icon now delegate to AttendanceStatusUtil which
 * has the complete v5 vocabulary (overtime, late_overtime, auto_close). -
 * getAttendanceStatusDescription() added — returns a one-line explanation
 * suitable for tooltips and notification messages. - isAutoClose() convenience
 * helper added for JSP conditional rendering. - getShiftDurationHours() helper
 * for UI display of expected shift length.
 *
 * ── Status fields ──────────────────────────────────────────────────────────
 * status → live punch state: working | onBreak | punchedOut attendanceStatus →
 * day-end result: pending → session still open full_day → on time, ≥ shift
 * hours worked half_day → on time, ≥ half shift worked absent → < half shift
 * worked (or no check-in) late → late punch-in, full shift worked late_half →
 * late punch-in, half-day hours overtime → on time, worked beyond shift + grace
 * late_overtime → late punch-in AND worked overtime auto_close → system
 * auto-closed session (sentinel)
 */
public class AttendanceSession {

	private long id;
	private int shiftId;

	private String username;
	private LocalDate sessionDate;
	private LocalDateTime punchIn;
	private LocalDateTime punchOut;
	private long totalBreakMs;
	private long netWorkMs;

	/** Live punch state: working | onBreak | punchedOut */
	private String status;

	/**
	 * Attendance status computed by AttendanceStatusUtil at punch-out. Stored as a
	 * lowercase_snake string matching the STATUS_* constants.
	 */
	private String attendanceStatus = AttendanceStatusUtil.STATUS_PENDING;

	private LocalDateTime createdAt;
	private LocalDateTime updatedAt;

	private List<AttendanceLogEntry> logEntries = new ArrayList<>();

	// ── Constructors ─────────────────────────────────────────────────
	public AttendanceSession() {
	}

	public AttendanceSession(String username, LocalDate sessionDate, LocalDateTime punchIn) {
		this.username = username;
		this.sessionDate = sessionDate;
		this.punchIn = punchIn;
		this.status = "working";
		this.attendanceStatus = AttendanceStatusUtil.STATUS_PENDING;
		this.totalBreakMs = 0;
		this.netWorkMs = 0;
	}

	// ── Getters & Setters ─────────────────────────────────────────────
	public long getId() {
		return id;
	}

	public void setId(long id) {
		this.id = id;
	}

	public int getShiftId() {
		return shiftId;
	}

	public void setShiftId(int shiftId) {
		this.shiftId = shiftId;
	}

	public String getUsername() {
		return username;
	}

	public void setUsername(String u) {
		this.username = u;
	}

	public LocalDate getSessionDate() {
		return sessionDate;
	}

	public void setSessionDate(LocalDate d) {
		this.sessionDate = d;
	}

	public LocalDateTime getPunchIn() {
		return punchIn;
	}

	public void setPunchIn(LocalDateTime t) {
		this.punchIn = t;
	}

	public LocalDateTime getPunchOut() {
		return punchOut;
	}

	public void setPunchOut(LocalDateTime t) {
		this.punchOut = t;
	}

	public long getTotalBreakMs() {
		return totalBreakMs;
	}

	public void setTotalBreakMs(long ms) {
		this.totalBreakMs = ms;
	}

	public long getNetWorkMs() {
		return netWorkMs;
	}

	public void setNetWorkMs(long ms) {
		this.netWorkMs = ms;
	}

	public String getStatus() {
		return status;
	}

	public void setStatus(String s) {
		this.status = s;
	}

	public String getAttendanceStatus() {
		return attendanceStatus;
	}

	public void setAttendanceStatus(String s) {
		this.attendanceStatus = s;
	}

	public LocalDateTime getCreatedAt() {
		return createdAt;
	}

	public void setCreatedAt(LocalDateTime t) {
		this.createdAt = t;
	}

	public LocalDateTime getUpdatedAt() {
		return updatedAt;
	}

	public void setUpdatedAt(LocalDateTime t) {
		this.updatedAt = t;
	}

	public List<AttendanceLogEntry> getLogEntries() {
		return logEntries;
	}

	public void setLogEntries(List<AttendanceLogEntry> list) {
		this.logEntries = list;
	}

	// ── Convenience helpers ───────────────────────────────────────────

	/** Net working hours as a double (e.g. 8.5). */
	public double getNetWorkHours() {
		return netWorkMs / 3_600_000.0;
	}

	/** Total break time in whole minutes. */
	public long getBreakMinutes() {
		return totalBreakMs / 60_000;
	}

	/** Number of break events in the log. */
	public long getBreakCount() {
		return logEntries.stream().filter(e -> "BREAK_START".equals(e.getEventType())).count();
	}

	// ── AttendanceStatusUtil delegation ──────────────────────────────

	/**
	 * Human-readable attendance label (e.g. "Present (Full Day)", "Late Mark").
	 * Delegates to AttendanceStatusUtil.label() — single source of truth.
	 */
	public String getAttendanceLabel() {
		return AttendanceStatusUtil.label(attendanceStatus);
	}

	/**
	 * CSS class suffix for badge styling (e.g. {@code att-badge--full},
	 * {@code att-badge--late}).
	 */
	public String getAttendanceCssClass() {
		return AttendanceStatusUtil.cssClass(attendanceStatus);
	}

	/**
	 * Bootstrap Icons icon name (e.g. "check-circle-fill", "clock-history").
	 */
	public String getAttendanceIcon() {
		return AttendanceStatusUtil.icon(attendanceStatus);
	}

	/**
	 * Short one-line description of the attendance status for tooltips and
	 * notification messages. Uses buildStatusReason() from AttendanceStatusUtil.
	 */
	public String getAttendanceStatusDescription() {
		if (punchIn == null) {
			return "No check-in recorded.";
		}
		String shiftName = null; // caller can enrich if needed
		String lateDeadline = AttendanceStatusUtil.LATE_THRESHOLD
				.format(java.time.format.DateTimeFormatter.ofPattern("hh:mm a"));
		String punchInStr = punchIn.format(java.time.format.DateTimeFormatter.ofPattern("hh:mm a"));
		double netH = netWorkMs / 3_600_000.0;
		double fullH = AttendanceStatusUtil.DEFAULT_FULL_DAY_MS / 3_600_000.0;
		return AttendanceStatusUtil.buildStatusReason(attendanceStatus, shiftName, lateDeadline, punchInStr, netH,
				fullH);
	}

	/** Returns true when this session was auto-closed by the system. */
	public boolean isAutoClose() {
		return "auto_close".equalsIgnoreCase(attendanceStatus) || "system_closed".equalsIgnoreCase(attendanceStatus);
	}

	/** Returns true when the session is still open (not punched out). */
	public boolean isOpen() {
		return "working".equals(status) || "onBreak".equals(status);
	}

	/** Returns true if the session was punched out (manually or auto). */
	public boolean isClosed() {
		return "punchedOut".equals(status);
	}

	/** Format milliseconds as "Xh Ym" string — delegates to util. */
	public static String formatMs(long ms) {
		return AttendanceStatusUtil.formatMs(ms);
	}

	@Override
	public String toString() {
		return "AttendanceSession{id=" + id + ", username='" + username + "'" + ", date=" + sessionDate + ", status='"
				+ status + "'" + ", attendanceStatus='" + attendanceStatus + "'}";
	}
}
