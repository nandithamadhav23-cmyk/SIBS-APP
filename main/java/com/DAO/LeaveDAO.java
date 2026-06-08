package com.DAO;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

import com.util.DBConnection;
import com.util.LeaveRequest;
import com.util.LeaveType;

/**
 * Data-Access Object for the Leave Management feature.
 *
 * Covers: - Fetching leave types + employee balances - Applying / cancelling a
 * leave request - Fetching leave history for an employee - Admin: list pending,
 * approve / reject - Working-day calculation (skips Sat/Sun + holidays) -
 * Business-rule validation (notice period, consecutive-day cap, etc.)
 */
public class LeaveDAO {

	// ════════════════════════════════════════════════════════════
	// LEAVE TYPE & BALANCE
	// ════════════════════════════════════════════════════════════

	/**
	 * All active leave types joined with this employee's balance for the current
	 * year.
	 */
	public List<LeaveType> getLeaveTypesWithBalance(String username) throws SQLException {
		List<LeaveType> list = new ArrayList<>();
		String sql = """
				SELECT lt.id, lt.type_name, lt.max_days, lt.is_paid,
				       lt.requires_doc, lt.carry_forward, lt.description,
				       COALESCE(lb.total_days,  lt.max_days) AS total_allotted,
				       COALESCE(lb.used_days,   0)           AS used_days,
				       COALESCE(lb.carried_days,0)           AS carried_days
				FROM   leave_types lt
				LEFT   JOIN leave_balances lb
				       ON  lb.leave_type_id = lt.id
				       AND lb.username      = ?
				       AND lb.leave_year    = YEAR(CURDATE())
				ORDER  BY lt.id
				""";
		try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
			ps.setString(1, username);
			try (ResultSet rs = ps.executeQuery()) {
				while (rs.next()) {
					LeaveType lt = new LeaveType();
					lt.setId(rs.getInt("id"));
					lt.setTypeName(rs.getString("type_name"));
					lt.setMaxDays(rs.getInt("max_days"));
					lt.setPaid(rs.getBoolean("is_paid"));
					lt.setRequiresDoc(rs.getBoolean("requires_doc"));
					lt.setCarryForward(rs.getBoolean("carry_forward"));
					lt.setDescription(rs.getString("description"));
					lt.setTotalAllotted(rs.getBigDecimal("total_allotted"));
					lt.setUsedDays(rs.getBigDecimal("used_days"));
					lt.setCarriedDays(rs.getBigDecimal("carried_days"));
					list.add(lt);
				}
			}
		}
		return list;
	}

	/** Single leave type row (used for server-side validation). */
	public LeaveType getLeaveTypeById(int id) throws SQLException {
		String sql = "SELECT * FROM leave_types WHERE id = ?";
		try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
			ps.setInt(1, id);
			try (ResultSet rs = ps.executeQuery()) {
				if (rs.next()) {
					LeaveType lt = new LeaveType();
					lt.setId(rs.getInt("id"));
					lt.setTypeName(rs.getString("type_name"));
					lt.setMaxDays(rs.getInt("max_days"));
					lt.setPaid(rs.getBoolean("is_paid"));
					lt.setRequiresDoc(rs.getBoolean("requires_doc"));
					lt.setCarryForward(rs.getBoolean("carry_forward"));
					lt.setDescription(rs.getString("description"));
					return lt;
				}
			}
		}
		return null;
	}

	// ════════════════════════════════════════════════════════════
	// APPLY LEAVE
	// ════════════════════════════════════════════════════════════

	/**
	 * Validates all business rules and inserts a leave request. Returns null on
	 * success; returns a human-readable error string on failure.
	 */
	public String applyLeave(LeaveRequest req) throws SQLException {

		LocalDate from = req.getFromDate().toLocalDate();
		LocalDate to = req.getToDate().toLocalDate();
		LocalDate today = LocalDate.now();

		// ── Rule 1: dates sane ────────────────────────────────
		if (from.isAfter(to)) {
			return "From date cannot be after To date.";
		}

		// ── Rule 2: not in the past ───────────────────────────
		if (from.isBefore(today)) {
			return "Leave cannot be applied for a past date.";
		}

		// ── Rule 3: minimum notice period ─────────────────────
		int minNotice = getPolicyInt("min_notice_days", 1);
		if (from.isBefore(today.plusDays(minNotice))) {
			return "Leave must be applied at least " + minNotice + " working day(s) in advance.";
		}

		// ── Rule 4: max advance booking ───────────────────────
		int maxAdvance = getPolicyInt("max_advance_days", 90);
		if (from.isAfter(today.plusDays(maxAdvance))) {
			return "Leave cannot be applied more than " + maxAdvance + " days in advance.";
		}

		// ── Rule 5: working days calc ─────────────────────────
		BigDecimal workingDays = calculateWorkingDays(from, to, req.getSessionType());
		if (workingDays.compareTo(BigDecimal.ZERO) <= 0) {
			return "Selected date range has no working days (only weekends/holidays).";
		}
		req.setTotalDays(workingDays);

		// ── Rule 6: fetch leave type ──────────────────────────
		LeaveType lt = getLeaveTypeById(req.getLeaveTypeId());
		if (lt == null) {
			return "Invalid leave type selected.";
		}

		// ── Rule 7: consecutive-day cap for Casual Leave ──────
		if ("Casual Leave".equalsIgnoreCase(lt.getTypeName())) {
			int maxConsec = getPolicyInt("max_consecutive_casual", 3);
			long calDays = to.toEpochDay() - from.toEpochDay() + 1;
			if (calDays > maxConsec) {
				return "Casual Leave cannot exceed " + maxConsec + " consecutive calendar days.";
			}
		}

		// ── Rule 8: document required? ────────────────────────
		if (lt.isRequiresDoc() && (req.getDocumentPath() == null || req.getDocumentPath().isBlank())) {
			return lt.getTypeName() + " requires a supporting document (medical certificate / proof).";
		}

		// ── Rule 9: balance check ─────────────────────────────
		BigDecimal available = getAvailableBalance(req.getUsername(), req.getLeaveTypeId());
		boolean autoLop = getPolicyInt("auto_deduct_lop", 1) == 1;
		if (available.compareTo(workingDays) < 0 && !autoLop) {
			return "Insufficient leave balance. Available: " + available + " day(s), Requested: " + workingDays
					+ " day(s).";
		}

		// ── Rule 10: overlapping pending/approved leave ────────
		if (hasOverlap(req.getUsername(), from, to, -1)) {
			return "You already have a pending or approved leave overlapping the selected dates.";
		}

		// ── Insert ─────────────────────────────────────────────
		String sql = """
				INSERT INTO leave_requests
				  (username, leave_type_id, from_date, to_date, total_days, session_type,
				   reason, contact_during_leave, work_handover, covering_person, document_path, status)
				VALUES (?,?,?,?,?,?,?,?,?,?,?,'pending')
				""";
		try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
			ps.setString(1, req.getUsername());
			ps.setInt(2, req.getLeaveTypeId());
			ps.setDate(3, req.getFromDate());
			ps.setDate(4, req.getToDate());
			ps.setBigDecimal(5, workingDays);
			ps.setString(6, req.getSessionType());
			ps.setString(7, req.getReason());
			ps.setString(8, req.getContactDuringLeave());
			ps.setString(9, req.getWorkHandover());
			ps.setString(10, req.getCoveringPerson());
			ps.setString(11, req.getDocumentPath());
			ps.executeUpdate();
		}
		return null; // success
	}

	// ════════════════════════════════════════════════════════════
	// CANCEL LEAVE (employee-initiated, only if status=pending)
	// ════════════════════════════════════════════════════════════

	/**
	 * Returns null on success or an error string. Employees may cancel only their
	 * own pending requests. Approved leaves may only be cancelled ≥1 day before
	 * leave starts.
	 */
	public String cancelLeave(int requestId, String username, String cancelReason) throws SQLException {
		LeaveRequest existing = getRequestById(requestId);
		if (existing == null) {
			return "Leave request not found.";
		}
		if (!existing.getUsername().equals(username)) {
			return "Unauthorised.";
		}

		String status = existing.getStatus();
		if ("cancelled".equalsIgnoreCase(status) || "rejected".equalsIgnoreCase(status)) {
			return "This leave is already " + status + ".";
		}
		if ("approved".equalsIgnoreCase(status)) {
			// Can cancel approved leave only if leave hasn't started yet
			LocalDate from = existing.getFromDate().toLocalDate();
			if (!from.isAfter(LocalDate.now())) {
				return "Cannot cancel an approved leave that has already started or passed.";
			}
		}

		String sql = """
				UPDATE leave_requests
				SET    status       = 'cancelled',
				       cancelled_on = NOW(),
				       cancel_reason = ?
				WHERE  id = ? AND username = ?
				""";
		try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
			ps.setString(1, cancelReason);
			ps.setInt(2, requestId);
			ps.setString(3, username);
			ps.executeUpdate();
		}

		// If it was approved, refund balance
		if ("approved".equalsIgnoreCase(status)) {
			deductBalance(username, existing.getLeaveTypeId(), existing.getTotalDays().negate());
		}
		return null;
	}

	// ════════════════════════════════════════════════════════════
	// ADMIN — approve / reject
	// ════════════════════════════════════════════════════════════

	public String approveLeave(int requestId, String reviewerUsername, String note) throws SQLException {
		LeaveRequest req = getRequestById(requestId);
		if (req == null) {
			return "Request not found.";
		}
		if (!"pending".equalsIgnoreCase(req.getStatus())) {
			return "Only pending requests can be approved.";
		}

		// Check balance again at approval time
		BigDecimal available = getAvailableBalance(req.getUsername(), req.getLeaveTypeId());
		if (available.compareTo(req.getTotalDays()) < 0) {
			// Auto-LOP: still approve but note the shortfall — balance goes negative
		}

		String sql = """
				UPDATE leave_requests
				SET status='approved', reviewed_by=?, reviewed_on=NOW(), reviewer_note=?
				WHERE id=?
				""";
		try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
			ps.setString(1, reviewerUsername);
			ps.setString(2, note);
			ps.setInt(3, requestId);
			ps.executeUpdate();
		}
		// Deduct balance
		deductBalance(req.getUsername(), req.getLeaveTypeId(), req.getTotalDays());
		return null;
	}

	public String rejectLeave(int requestId, String reviewerUsername, String note) throws SQLException {
		LeaveRequest req = getRequestById(requestId);
		if (req == null) {
			return "Request not found.";
		}
		if (!"pending".equalsIgnoreCase(req.getStatus())) {
			return "Only pending requests can be rejected.";
		}

		String sql = """
				UPDATE leave_requests
				SET status='rejected', reviewed_by=?, reviewed_on=NOW(), reviewer_note=?
				WHERE id=?
				""";
		try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
			ps.setString(1, reviewerUsername);
			ps.setString(2, note);
			ps.setInt(3, requestId);
			ps.executeUpdate();
		}
		return null;
	}

	/**
	 * Process a leave request decision from an admin UI.
	 * Delegates to approveLeave or rejectLeave based on `decision`.
	 * Returns null on success or an error message on failure.
	 */
	public String processLeaveRequest(int requestId, String decision, String reviewerUsername, String note)
			throws SQLException {
		if (decision == null) {
			return "Missing decision";
		}
		if (decision.equalsIgnoreCase("approved") || decision.equalsIgnoreCase("approve")) {
			return approveLeave(requestId, reviewerUsername, note);
		} else if (decision.equalsIgnoreCase("rejected") || decision.equalsIgnoreCase("reject")) {
			return rejectLeave(requestId, reviewerUsername, note);
		} else {
			return "Decision must be 'approved' or 'rejected'";
		}
	}

	// ════════════════════════════════════════════════════════════
	// FETCH METHODS
	// ════════════════════════════════════════════════════════════

	/** Leave history for one employee, newest first. */
	public List<LeaveRequest> getLeaveHistory(String username) throws SQLException {
		String sql = """
				SELECT lr.*, lt.type_name, lt.is_paid
				FROM   leave_requests lr
				JOIN   leave_types    lt ON lt.id = lr.leave_type_id
				WHERE  lr.username = ?
				ORDER  BY lr.applied_on DESC
				""";
		return fetchRequests(sql, username);
	}

	/** Pending requests for admin view. */
	public List<LeaveRequest> getPendingRequests() throws SQLException {
		String sql = """
				SELECT lr.*, lt.type_name, lt.is_paid
				FROM   leave_requests lr
				JOIN   leave_types    lt ON lt.id = lr.leave_type_id
				WHERE  lr.status = 'pending'
				ORDER  BY lr.applied_on ASC
				""";
		return fetchRequests(sql, null);
	}

	/** All requests for admin dashboard. */
	public List<LeaveRequest> getAllRequests() throws SQLException {
		String sql = """
				SELECT lr.*, lt.type_name, lt.is_paid
				FROM   leave_requests lr
				JOIN   leave_types    lt ON lt.id = lr.leave_type_id
				ORDER  BY lr.applied_on DESC
				""";
		return fetchRequests(sql, null);
	}

	public LeaveRequest getRequestById(int id) throws SQLException {
		String sql = """
				SELECT lr.*, lt.type_name, lt.is_paid
				FROM   leave_requests lr
				JOIN   leave_types    lt ON lt.id = lr.leave_type_id
				WHERE  lr.id = ?
				""";
		try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
			ps.setInt(1, id);
			try (ResultSet rs = ps.executeQuery()) {
				List<LeaveRequest> list = mapRows(rs);
				return list.isEmpty() ? null : list.get(0);
			}
		}
	}

	// ════════════════════════════════════════════════════════════
	// BALANCE HELPERS
	// ════════════════════════════════════════════════════════════

	public BigDecimal getAvailableBalance(String username, int leaveTypeId) throws SQLException {
		String sql = """
				SELECT COALESCE(lb.total_days + COALESCE(lb.carried_days,0) - lb.used_days,
				                lt.max_days) AS available
				FROM   leave_types lt
				LEFT   JOIN leave_balances lb
				            ON lb.leave_type_id = lt.id
				            AND lb.username     = ?
				            AND lb.leave_year   = YEAR(CURDATE())
				WHERE  lt.id = ?
				""";
		try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
			ps.setString(1, username);
			ps.setInt(2, leaveTypeId);
			try (ResultSet rs = ps.executeQuery()) {
				if (rs.next()) {
					return rs.getBigDecimal("available");
				}
			}
		}
		return BigDecimal.ZERO;
	}

	/**
	 * Upsert balance row and increment used_days by delta. Pass negative delta to
	 * refund (on cancellation).
	 */
	private void deductBalance(String username, int leaveTypeId, BigDecimal delta) throws SQLException {
		String upsert = """
				INSERT INTO leave_balances (username, leave_type_id, leave_year, total_days, used_days)
				SELECT ?, ?, YEAR(CURDATE()), max_days, 0
				FROM   leave_types WHERE id = ?
				ON DUPLICATE KEY UPDATE used_days = used_days + ?
				""";
		try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(upsert)) {
			ps.setString(1, username);
			ps.setInt(2, leaveTypeId);
			ps.setInt(3, leaveTypeId);
			ps.setBigDecimal(4, delta);
			ps.executeUpdate();
		}
	}

	// ════════════════════════════════════════════════════════════
	// UTILITY
	// ════════════════════════════════════════════════════════════

	/**
	 * Calculates working days between from and to (inclusive). - Skips Saturday &
	 * Sunday - Skips public holidays in leave_holidays table - Half-day = 0.5
	 */
	public BigDecimal calculateWorkingDays(LocalDate from, LocalDate to, String sessionType) throws SQLException {
		// Fetch holiday set once
		java.util.Set<LocalDate> holidays = getHolidaySet(from, to);
		int count = 0;
		LocalDate cursor = from;
		while (!cursor.isAfter(to)) {
			DayOfWeek dow = cursor.getDayOfWeek();
			if (dow != DayOfWeek.SATURDAY && dow != DayOfWeek.SUNDAY && !holidays.contains(cursor)) {
				count++;
			}
			cursor = cursor.plusDays(1);
		}
		// Adjust for half-day
		if (("first_half".equals(sessionType) || "second_half".equals(sessionType)) && count == 1) {
			return new BigDecimal("0.5");
		}
		return new BigDecimal(count);
	}

	private java.util.Set<LocalDate> getHolidaySet(LocalDate from, LocalDate to) throws SQLException {
		java.util.Set<LocalDate> set = new java.util.HashSet<>();
		String sql = "SELECT holiday_date FROM leave_holidays WHERE holiday_date BETWEEN ? AND ?";
		try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
			ps.setDate(1, Date.valueOf(from));
			ps.setDate(2, Date.valueOf(to));
			try (ResultSet rs = ps.executeQuery()) {
				while (rs.next()) {
					set.add(rs.getDate(1).toLocalDate());
				}
			}
		}
		return set;
	}

	/**
	 * Returns true if any pending/approved leave overlaps [from, to] for the user.
	 */
	private boolean hasOverlap(String username, LocalDate from, LocalDate to, int excludeId) throws SQLException {
		String sql = """
				SELECT COUNT(*) FROM leave_requests
				WHERE username = ?
				  AND status IN ('pending','approved')
				  AND id != ?
				  AND from_date <= ? AND to_date >= ?
				""";
		try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
			ps.setString(1, username);
			ps.setInt(2, excludeId);
			ps.setDate(3, Date.valueOf(to));
			ps.setDate(4, Date.valueOf(from));
			try (ResultSet rs = ps.executeQuery()) {
				return rs.next() && rs.getInt(1) > 0;
			}
		}
	}

	private int getPolicyInt(String key, int defaultVal) {
		String sql = "SELECT policy_value FROM leave_policy WHERE policy_key = ?";
		try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
			ps.setString(1, key);
			try (ResultSet rs = ps.executeQuery()) {
				if (rs.next()) {
					return Integer.parseInt(rs.getString(1));
				}
			}
		} catch (Exception ignored) {
		}
		return defaultVal;
	}

	// ════════════════════════════════════════════════════════════
	// ADMIN FILTERED QUERY (used by AdminLeaveServlet)
	// ════════════════════════════════════════════════════════════

	/**
	 * Admin-facing filtered query. Any parameter may be null/blank to skip that
	 * filter.
	 */
	public List<LeaveRequest> getFilteredRequests(String status, String username, String leaveType, String fromDate,
			String toDate) throws SQLException {

		StringBuilder sql = new StringBuilder("SELECT lr.*, lt.type_name, lt.is_paid " + "FROM leave_requests lr "
				+ "JOIN leave_types lt ON lt.id = lr.leave_type_id " + "WHERE 1=1 ");

		List<Object> params = new ArrayList<>();

		if (status != null && !status.isBlank()) {
			sql.append("AND lr.status = ? ");
			params.add(status.trim());
		}
		if (username != null && !username.isBlank()) {
			sql.append("AND lr.username = ? ");
			params.add(username.trim());
		}
		if (leaveType != null && !leaveType.isBlank()) {
			sql.append("AND lt.type_name = ? ");
			params.add(leaveType.trim());
		}
		if (fromDate != null && !fromDate.isBlank()) {
			sql.append("AND lr.from_date >= ? ");
			params.add(java.sql.Date.valueOf(fromDate.trim()));
		}
		if (toDate != null && !toDate.isBlank()) {
			sql.append("AND lr.to_date <= ? ");
			params.add(java.sql.Date.valueOf(toDate.trim()));
		}
		sql.append("ORDER BY lr.applied_on DESC");

		try (Connection con = DBConnection.getConnection();
				PreparedStatement ps = con.prepareStatement(sql.toString())) {
			for (int i = 0; i < params.size(); i++) {
				Object p = params.get(i);
				if (p instanceof String) {
					ps.setString(i + 1, (String) p);
				} else if (p instanceof java.sql.Date) {
					ps.setDate(i + 1, (java.sql.Date) p);
				}
			}
			try (ResultSet rs = ps.executeQuery()) {
				return mapRows(rs);
			}
		}
	}

	// ── Shared row mapper ──────────────────────────────────────

	private List<LeaveRequest> fetchRequests(String sql, String usernameParam) throws SQLException {
		try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
			if (usernameParam != null) {
				ps.setString(1, usernameParam);
			}
			try (ResultSet rs = ps.executeQuery()) {
				return mapRows(rs);
			}
		}
	}

	private List<LeaveRequest> mapRows(ResultSet rs) throws SQLException {
		List<LeaveRequest> list = new ArrayList<>();
		while (rs.next()) {
			LeaveRequest r = new LeaveRequest();
			r.setId(rs.getInt("id"));
			r.setUsername(rs.getString("username"));
			r.setLeaveTypeId(rs.getInt("leave_type_id"));
			r.setLeaveTypeName(rs.getString("type_name"));
			r.setPaid(rs.getBoolean("is_paid"));
			r.setFromDate(rs.getDate("from_date"));
			r.setToDate(rs.getDate("to_date"));
			r.setTotalDays(rs.getBigDecimal("total_days"));
			r.setSessionType(rs.getString("session_type"));
			r.setReason(rs.getString("reason"));
			r.setContactDuringLeave(rs.getString("contact_during_leave"));
			r.setWorkHandover(rs.getString("work_handover"));
			r.setCoveringPerson(rs.getString("covering_person"));
			r.setDocumentPath(rs.getString("document_path"));
			r.setStatus(rs.getString("status"));
			r.setAppliedOn(rs.getTimestamp("applied_on"));
			r.setReviewedBy(rs.getString("reviewed_by"));
			r.setReviewedOn(rs.getTimestamp("reviewed_on"));
			r.setReviewerNote(rs.getString("reviewer_note"));
			r.setCancelledOn(rs.getTimestamp("cancelled_on"));
			r.setCancelReason(rs.getString("cancel_reason"));
			list.add(r);
		}
		return list;
	}
}