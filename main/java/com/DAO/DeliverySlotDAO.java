package com.DAO;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.logging.Logger;

import com.util.DeliverySlot;
import com.util.DeliveryZone;
import com.util.ShiftWindowValidator;

/**
 * DeliverySlotDAO — Refactored & Bug-Fixed Version
 * ──────────────────────────────────────────────────────────────────────────
 *
 * BUGS FIXED (see DEFECT_METRIC_BREAKDOWN.md for full detail):
 *
 * BUG-06 FIXED: calculateAndCreditEarnings used double/getDouble() for all
 * monetary values. Replaced entirely with BigDecimal / getBigDecimal() /
 * setBigDecimal(). Wallet balance comparisons now use compareTo().
 *
 * BUG-07 FIXED: updateSlotStatusWithTimestamp concatenated the column name
 * directly into SQL string with no whitelist guard. An explicit
 * ALLOWED_TIMESTAMP_COLUMNS Set<String> whitelist is now enforced; unknown
 * column names throw IllegalArgumentException before any SQL is constructed.
 *
 * BUG-08 FIXED: expireStaleBookedSlots CASE expression only handled 4 slot
 * types. Extended to cover NIGHT (with DATE_ADD for overnight), MIDNIGHT, and
 * EARLY_MORNING.
 *
 * BUG-09 FIX is in SlotDashboard.jsp (computeIfAbsent pattern noted here).
 *
 * BUG-12 FIXED: findNextAvailableSlot FIELD() ordering now includes all 7
 * types.
 *
 * BUG-15 FIXED: getSlotStartTime, getSlotEndTime, getSlotBookingCutoff, and
 * getMaxOrdersForSlotType all extended with arms for NIGHT, MIDNIGHT,
 * EARLY_MORNING.
 *
 * BUG-18 FIXED: getUndepositedCodSummary now returns long[] to avoid int
 * truncation on large COD totals.
 *
 * BUG-19 FIXED: Added isOvernightSlot() and getSlotEndDate() helpers to
 * correctly compute end epochs for the NIGHT shift which crosses midnight.
 *
 * NEW SHIFTS INJECTED: NIGHT 22:00 – 02:00 (+1 day) — overnight MIDNIGHT 02:00
 * – 06:00 EARLY_MORNING 04:00 – 08:00
 *
 * ADAPTIVE BOOKING RULES: - Future-window advance booking supported (bookSlot
 * allows future dates). - COMPLETED state unblocks the interface: only ACTIVE /
 * ON_BREAK / BOOKED statuses block re-booking on the same date (consistent with
 * original intent).
 */
public class DeliverySlotDAO {

	private static final Logger log = Logger.getLogger(DeliverySlotDAO.class.getName());
	private final Connection conn;

	/** Maximum break duration in minutes before agent is forced offline. */
	public static final int MAX_BREAK_MINUTES = 10;

	/**
	 * BUG-07 FIX: Whitelist of column names permitted in
	 * updateSlotStatusWithTimestamp. Enforced before any SQL string concatenation
	 * occurs.
	 */
	private static final Set<String> ALLOWED_TIMESTAMP_COLUMNS = Set.of("break_start", "shift_started_at",
			"shift_ended_at");

	public DeliverySlotDAO(Connection conn) {
		this.conn = conn;
		try {
			ensureSlotColumns();
		} catch (SQLException e) {
			log.warning("ensureSlotColumns failed (non-fatal): " + e.getMessage());
		}
	}

	// ─────────────────────────────────────────────────────────────────────────
	// SCHEMA AUTO-MIGRATION
	// ─────────────────────────────────────────────────────────────────────────

	/**
	 * Adds break-tracking and shift-time columns if they don't already exist. Safe
	 * to call on every startup — uses IF NOT EXISTS pattern.
	 */
	private void ensureSlotColumns() throws SQLException {
		// Removed 'IF NOT EXISTS' from raw strings to maintain standard MySQL
		// compliance
		String[] alters = { "ALTER TABLE delivery_slots ADD COLUMN break_start      DATETIME DEFAULT NULL",
				"ALTER TABLE delivery_slots ADD COLUMN total_break_min  INT      DEFAULT 0",
				"ALTER TABLE delivery_slots ADD COLUMN shift_started_at DATETIME DEFAULT NULL",
				"ALTER TABLE delivery_slots ADD COLUMN shift_ended_at   DATETIME DEFAULT NULL",
				"ALTER TABLE delivery_slots ADD COLUMN cancelled_reason VARCHAR(500) DEFAULT NULL",
				"ALTER TABLE delivery_slots ADD COLUMN window_start_at  DATETIME DEFAULT NULL",
				"ALTER TABLE delivery_slots ADD COLUMN window_end_at    DATETIME DEFAULT NULL" };

		for (String sql : alters) {
			try (PreparedStatement ps = conn.prepareStatement(sql)) {
				ps.executeUpdate();
			} catch (SQLException e) {
				// 42S21 = MySQL State for "Duplicate column name".
				// Error code 1060 = "Duplicate column name".
				if ("42S21".equals(e.getSQLState()) || e.getErrorCode() == 1060) {
					log.fine("ensureSlotColumns: Column already exists, skipping.");
				} else {
					// Rethrow if it's a real problem (e.g., connection drop, bad privileges)
					throw e;
				}
			}
		}
	}

	// ─────────────────────────────────────────────────────────────────────────
	// SLOT BOOKING
	// ─────────────────────────────────────────────────────────────────────────

	public int bookSlot(int agentId, int zoneId, LocalDate slotDate, String slotType) throws SQLException {
		ensureSlotColumns();

		// 1. First, check if there's an ACTIVE, ON_BREAK, or BOOKED slot for that date
		String checkActive = "SELECT slot_id, status FROM delivery_slots WHERE agent_id=? AND slot_date=? AND status IN ('ACTIVE','ON_BREAK','BOOKED') LIMIT 1";
		try (PreparedStatement ps = conn.prepareStatement(checkActive)) {
			ps.setInt(1, agentId);
			ps.setDate(2, Date.valueOf(slotDate));
			try (ResultSet rs = ps.executeQuery()) {
				if (rs.next()) {
					log.warning("bookSlot: agent #" + agentId + " already holds an active/booked slot on " + slotDate);

					return -1; // Conflict: agent already has ACTIVE / ON_BREAK / BOOKED slot
				}
			}
		}

		// 2. Look for any existing terminal/inactive slot that can be safely reused
		int existingId = -1;
		String existingStatus = "";
		String checkReusable = "SELECT slot_id, status FROM delivery_slots WHERE agent_id=? AND slot_date=? AND status IN ('CANCELLED','COMPLETED','EXPIRED','INACTIVE') LIMIT 1";
		try (PreparedStatement ps = conn.prepareStatement(checkReusable)) {
			ps.setInt(1, agentId);
			ps.setDate(2, Date.valueOf(slotDate));
			try (ResultSet rs = ps.executeQuery()) {
				if (rs.next()) {
					existingId = rs.getInt("slot_id");
					existingStatus = rs.getString("status");
				}
			}
		}
		if ("EARLY_MORNING".equals(slotType)) {
			// If booking EARLY_MORNING, block if a MIDNIGHT slot is already BOOKED
			// for yesterday (since its window extends to 06:00 today, overlapping
			// 04:00-06:00).
			String crossCheck = "SELECT 1 FROM delivery_slots WHERE agent_id=? "
					+ " AND slot_date=? AND slot_type='MIDNIGHT' AND status IN ('BOOKED','ACTIVE','ON_BREAK') LIMIT 1";
			try (PreparedStatement ps = conn.prepareStatement(crossCheck)) {
				ps.setInt(1, agentId);
				ps.setDate(2, Date.valueOf(slotDate.minusDays(1))); // MIDNIGHT slot_date = yesterday
				try (ResultSet rs = ps.executeQuery()) {
					if (rs.next()) {
						log.warning(
								"bookSlot: EARLY_MORNING conflicts with existing MIDNIGHT slot for agent #" + agentId);
						return -1;
					}
				}
			}
		}
		if ("MIDNIGHT".equals(slotType)) {
			// If booking MIDNIGHT, block if an EARLY_MORNING slot is already BOOKED
			// on slotDate+1 (since MIDNIGHT window 02:00-06:00 overlaps EARLY_MORNING
			// 04:00-06:00).
			String crossCheck = "SELECT 1 FROM delivery_slots WHERE agent_id=? "
					+ " AND slot_date=? AND slot_type='EARLY_MORNING' AND status IN ('BOOKED','ACTIVE','ON_BREAK') LIMIT 1";
			try (PreparedStatement ps = conn.prepareStatement(crossCheck)) {
				ps.setInt(1, agentId);
				ps.setDate(2, Date.valueOf(slotDate.plusDays(1))); // EARLY_MORNING slot_date = tomorrow
				try (ResultSet rs = ps.executeQuery()) {
					if (rs.next()) {
						log.warning(
								"bookSlot: MIDNIGHT conflicts with existing EARLY_MORNING slot for agent #" + agentId);
						return -1;
					}
				}
			}
		}
		LocalTime startTime = getSlotStartTime(slotType);
		LocalTime endTime = getSlotEndTime(slotType);

		if (existingId > 0) {
			// ── Case A: Row exists - UPDATE and reset timeline parameters safely ──
			String update = "UPDATE delivery_slots SET " + "  zone_id=?, slot_type=?, status='BOOKED',"
					+ "  pending_count=0, active_count=0, delivered_count=0, "
					+ "  shift_started_at=NULL, shift_ended_at=NULL, "
					+ "  break_start=NULL, total_break_min=0, cancelled_reason=NULL, " + "  window_start_at = CASE "
					// ROOT CAUSE FIX: Only MIDNIGHT needs +1 day for window_start_at.
					// EARLY_MORNING (4 AM) starts on slot_date itself — do NOT add 1 day.
					+ "    WHEN ? = 'MIDNIGHT' THEN CAST(CONCAT(DATE_ADD(?, INTERVAL 1 DAY), ' ', ?) AS DATETIME) "
					+ "    ELSE CAST(CONCAT(?, ' ', ?) AS DATETIME) " + "  END, " + "  window_end_at = CASE "
					// NIGHT: end time (02:00) < start time (22:00) so end is next day
					+ "    WHEN ? > ? THEN CAST(CONCAT(DATE_ADD(?, INTERVAL 1 DAY), ' ', ?) AS DATETIME) "
					// MIDNIGHT: entire window is on slot_date+1
					+ "    WHEN ? = 'MIDNIGHT' THEN CAST(CONCAT(DATE_ADD(?, INTERVAL 1 DAY), ' ', ?) AS DATETIME) "
					+ "    ELSE CAST(CONCAT(?, ' ', ?) AS DATETIME) " + "  END " + "WHERE slot_id=?";

			try (PreparedStatement ps = conn.prepareStatement(update)) {
				ps.setInt(1, zoneId);
				ps.setString(2, slotType);

				// window_start_at calculation parameters
				ps.setString(3, slotType);
				ps.setDate(4, Date.valueOf(slotDate));
				ps.setString(5, startTime.toString());
				ps.setDate(6, Date.valueOf(slotDate));
				ps.setString(7, startTime.toString());

				// window_end_at calculation parameters
				ps.setString(8, startTime.toString());
				ps.setString(9, endTime.toString());
				ps.setDate(10, Date.valueOf(slotDate));
				ps.setString(11, endTime.toString());
				ps.setString(12, slotType);
				ps.setDate(13, Date.valueOf(slotDate));
				ps.setString(14, endTime.toString());
				ps.setDate(15, Date.valueOf(slotDate));
				ps.setString(16, endTime.toString());

				ps.setInt(17, existingId);

				int rows = ps.executeUpdate();
				if (rows > 0) {
					log.info("bookSlot: reused slot #" + existingId + " (was " + existingStatus + ") -> BOOKED ("
							+ slotType + ")");

					pushSlotNotification(agentId, "SLOT_BOOKED", "Slot booked! " + slotType + " shift",
							"Your shift is confirmed. Starts at " + getSlotStartTime(slotType)
									.format(java.time.format.DateTimeFormatter.ofPattern("h:mm a")) + ".",
							"📅", "blue", existingId);
					return existingId;
				}
			}
			return -1;
		} else {
			// ── Case B: Fresh slot entry needed — Plain INSERT ──
			String insert = "INSERT INTO delivery_slots "
					+ "(agent_id, zone_id, slot_date, slot_type, status, pending_count, active_count, delivered_count, window_start_at, window_end_at) "
					+ "VALUES (?, ?, ?, ?, 'BOOKED', 0, 0, 0, "
					// Always start on the provided slot_date
					+ "CAST(CONCAT(?, ' ', ?) AS DATETIME), "
					// Only add a day to end_time if it is chronologically before start_time
					// (overnight shift)
					+ "CASE WHEN ? < ? THEN CAST(CONCAT(DATE_ADD(?, INTERVAL 1 DAY), ' ', ?) AS DATETIME) "
					+ "     ELSE CAST(CONCAT(?, ' ', ?) AS DATETIME) END" + ")";

			try (PreparedStatement ps = conn.prepareStatement(insert, Statement.RETURN_GENERATED_KEYS)) {
				ps.setInt(1, agentId);
				ps.setInt(2, zoneId);
				ps.setDate(3, Date.valueOf(slotDate));
				ps.setString(4, slotType);

				// window_start_at: 5, 6
				ps.setDate(5, Date.valueOf(slotDate));
				ps.setString(6, startTime.toString());

				// window_end_at: 7, 8, 9, 10, 11, 12
				// Parameters for: WHEN endTime < startTime THEN (slotDate + 1, endTime) ELSE
				// (slotDate, endTime)
				ps.setString(7, endTime.toString()); // for comparison
				ps.setString(8, startTime.toString()); // for comparison
				ps.setDate(9, Date.valueOf(slotDate));
				ps.setString(10, endTime.toString());
				ps.setDate(11, Date.valueOf(slotDate));
				ps.setString(12, endTime.toString());
				ps.executeUpdate();
				try (ResultSet rs = ps.getGeneratedKeys()) {
					if (rs.next()) {
						int newId = rs.getInt(1);
						pushSlotNotification(agentId, "SLOT_BOOKED", "Slot booked! " + slotType + " shift",
								"Your shift is confirmed. Starts at " + getSlotStartTime(slotType)
										.format(java.time.format.DateTimeFormatter.ofPattern("h:mm a")) + ".",
								"📅", "blue", newId);
						return newId;
					}
					return -1;
				}
			}
		}
	}

	/**
	 * Returns true only if the agent has a BLOCKING slot on the given date (ACTIVE,
	 * ON_BREAK, or BOOKED). CANCELLED, COMPLETED, and EXPIRED slots do NOT block
	 * re-booking — agents are free to book a new slot after those.
	 */
	public boolean hasSlotOnDate(int agentId, LocalDate date) throws SQLException {
		String sql = "SELECT 1 FROM delivery_slots WHERE agent_id=? AND slot_date=? "
				+ "AND status IN ('ACTIVE','ON_BREAK','BOOKED')";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, agentId);
			ps.setDate(2, java.sql.Date.valueOf(date));
			try (ResultSet rs = ps.executeQuery()) {
				return rs.next();
			}
		}
	}

	public boolean isAgentBusyOnDate(int agentId, LocalDate date) throws SQLException {
		String sql = "SELECT 1 FROM delivery_slots WHERE agent_id=? AND slot_date=? "
				+ "AND status IN ('BOOKED', 'ACTIVE', 'ON_BREAK')";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, agentId);
			ps.setDate(2, java.sql.Date.valueOf(date));
			try (ResultSet rs = ps.executeQuery()) {
				return rs.next();
			}
		}
	}

	/**
	 * Get today's most relevant slot (priority: ACTIVE/ON_BREAK → BOOKED →
	 * COMPLETED → CANCELLED → EXPIRED). Used for single-slot status display.
	 *
	 * BUG-A FIX: Also includes yesterday's NIGHT slot when the current time is
	 * before 02:00 (the slot is still in progress across midnight). Without this,
	 * the agent's slot disappears from the UI at midnight even though they have 46+
	 * minutes left in a 10 PM–2 AM shift.
	 */
	public DeliverySlot getTodaySlot(int agentId) throws SQLException {

		String sql = "SELECT ds.*, dz.zone_name, dz.is_surge, dz.surge_multiplier " + "FROM delivery_slots ds "
				+ "JOIN delivery_zones dz ON ds.zone_id = dz.zone_id " + "WHERE ds.agent_id = ? " + "  AND ( "
				// Branch A: ACTIVE/ON_BREAK - bounded to window
				// ROOT-CAUSE FIX: Old filter required NOW() >= window_start_at - 60min,
				// making BOOKED slots invisible until 1hr before start. A NIGHT slot
				// booked at 7 PM for 10 PM returned NULL all evening => NPE cascade.
				// FIX: ACTIVE/ON_BREAK keep window-bounds (correct for overnight).
				// BOOKED/INACTIVE use slot_date = CURDATE() so visible all booking day.
				// NIGHT booked on slot_date D: window crosses to D+1, so also check
				// slot_date = yesterday when TIME(NOW()) < 02:00 (still in NIGHT window).
				+ "    ( ds.status IN ('ACTIVE','ON_BREAK') "
				+ "      AND NOW() >= DATE_SUB(ds.window_start_at, INTERVAL 60 MINUTE) "
				+ "      AND NOW() < ds.window_end_at ) " + "    OR ( ds.status IN ('BOOKED','INACTIVE') "
				+ "         AND ( ds.slot_date = CURDATE() "
				+ "               OR ( ds.slot_type IN ('NIGHT','MIDNIGHT','EARLY_MORNING') "
				+ "                    AND ds.slot_date = DATE_SUB(CURDATE(), INTERVAL 1 DAY) "
				+ "                    AND NOW() < ds.window_end_at ) ) ) "
				// Branch B: terminal — show from today or yesterday (covers overnight expiry)
				+ "    OR ( ds.status IN ('COMPLETED','CANCELLED','EXPIRED') "
				+ "         AND ds.slot_date >= DATE_SUB(CURDATE(), INTERVAL 1 DAY) ) " + "  ) "
				+ "ORDER BY FIELD(ds.status, 'ACTIVE','ON_BREAK','BOOKED','INACTIVE','COMPLETED','CANCELLED','EXPIRED'), "
				+ "         ds.slot_date DESC, ds.slot_id DESC " + "LIMIT 1";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, agentId);
			try (ResultSet rs = ps.executeQuery()) {
				return rs.next() ? mapSlot(rs) : null;
			}
		}
	}

	/**
	 * Get ALL of today's slots for an agent, ordered chronologically by shift start
	 * time. Used for multi-slot display — each slot shows its own status and
	 * controls.
	 *
	 * FIX-OVERNIGHT: The original query only handled the NIGHT overnight case.
	 * Added MIDNIGHT (2 AM–6 AM) and EARLY_MORNING (4 AM–8 AM) branches so that
	 * slots booked on the PREVIOUS calendar day are still visible after midnight: •
	 * NIGHT (10 PM–2 AM) — show while TIME(NOW()) < '02:00:00' • MIDNIGHT (2 AM–6
	 * AM) — booked D, window on D+1; show while < '06:00:00' • EARLY_MORNING (4
	 * AM–8 AM) — booked D, window on same D; show while < '08:00:00' Without these
	 * branches the slot card disappeared from the booking page for agents actively
	 * working overnight shifts.
	 */
	public List<DeliverySlot> getTodaySlots(int agentId) throws SQLException {
		String sql = "SELECT ds.*, dz.zone_name, dz.is_surge, dz.surge_multiplier " + "FROM delivery_slots ds "
				+ "JOIN delivery_zones dz ON ds.zone_id = dz.zone_id " + "WHERE ds.agent_id=? " + "  AND ( "
				+ "    ds.slot_date = CURDATE() "
				// NIGHT: 10 PM – 2 AM — visible until 02:00 the next calendar day
				+ "    OR ( ds.slot_type = 'NIGHT' "
				+ "         AND ds.slot_date = DATE_SUB(CURDATE(), INTERVAL 1 DAY) "
				+ "         AND TIME(NOW()) < '02:00:00' ) "
				// MIDNIGHT: 2 AM – 6 AM — booked on D, window is D+1 02:00–06:00; show until
				// 06:00
				+ "    OR ( ds.slot_type = 'MIDNIGHT' "
				+ "         AND ds.slot_date = DATE_SUB(CURDATE(), INTERVAL 1 DAY) "
				+ "         AND TIME(NOW()) < '06:00:00' ) "
				// EARLY_MORNING: 4 AM – 8 AM on slot_date itself; show until 08:00
				+ "    OR ( ds.slot_type = 'EARLY_MORNING' "
				+ "         AND ds.slot_date = DATE_SUB(CURDATE(), INTERVAL 1 DAY) "
				+ "         AND TIME(NOW()) < '08:00:00' ) " + "  ) "
				+ "ORDER BY FIELD(ds.slot_type,'MIDNIGHT','EARLY_MORNING','AM','PM','EVENING','FULL_DAY','NIGHT') ASC";
		List<DeliverySlot> list = new ArrayList<>();
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, agentId);
			try (ResultSet rs = ps.executeQuery()) {
				while (rs.next()) {
					list.add(mapSlot(rs));
				}
			}
		}
		return list;
	}

	/**
	 * Returns slot_type codes already booked (non-cancelled, non-expired) for the
	 * agent on the given date. Used to grey-out already-taken slot types in the UI
	 * so the agent cannot double-book the same shift type.
	 */
	public java.util.Set<String> getBookedSlotTypesForDate(int agentId, LocalDate date) throws SQLException {
		String sql = "SELECT slot_type FROM delivery_slots WHERE agent_id=? AND slot_date=? "
				+ "AND status IN ('BOOKED','ACTIVE','ON_BREAK','INACTIVE','COMPLETED')";
		java.util.Set<String> types = new java.util.HashSet<>();
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, agentId);
			ps.setDate(2, java.sql.Date.valueOf(date));
			try (ResultSet rs = ps.executeQuery()) {
				while (rs.next()) {
					types.add(rs.getString("slot_type"));
				}
			}
		}
		return types;
	}

	// ─────────────────────────────────────────────────────────────────────────
	// SHIFT LIFECYCLE
	// ─────────────────────────────────────────────────────────────────────────

	/** BOOKED → ACTIVE. Records shift_started_at timestamp. */
	public boolean activateSlot(int slotId, int agentId) throws SQLException {
		String sql = "UPDATE delivery_slots SET status='ACTIVE', shift_started_at=NOW() "
				+ "WHERE slot_id=? AND agent_id=? AND status='BOOKED'";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, slotId);
			ps.setInt(2, agentId);
			return ps.executeUpdate() > 0;
		}
	}

	/**
	 * BUG-07 FIX: Column name now validated against an explicit whitelist before
	 * being concatenated into the SQL string. Prevents any latent injection vector.
	 */
	public boolean updateSlotStatusWithTimestamp(int slotId, String newStatus, String timestampColumn)
			throws SQLException {
		if (!ALLOWED_TIMESTAMP_COLUMNS.contains(timestampColumn)) {
			throw new IllegalArgumentException("updateSlotStatusWithTimestamp: rejected unknown column '"
					+ timestampColumn + "'. Allowed: " + ALLOWED_TIMESTAMP_COLUMNS);
		}
		String sql = "UPDATE delivery_slots SET status = ?, " + timestampColumn + " = NOW() WHERE slot_id = ?";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setString(1, newStatus);
			ps.setInt(2, slotId);
			return ps.executeUpdate() > 0;
		}
	}

	/** ACTIVE → ON_BREAK. Records break_start timestamp. */
	public boolean startBreak(int slotId, int agentId) throws SQLException {
		String sql = "UPDATE delivery_slots SET status='ON_BREAK', break_start=NOW() "
				+ "WHERE slot_id=? AND agent_id=? AND status='ACTIVE'";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, slotId);
			ps.setInt(2, agentId);
			return ps.executeUpdate() > 0;
		}
	}

	/**
	 * ON_BREAK → ACTIVE (within limit) or INACTIVE (exceeded MAX_BREAK_MINUTES).
	 *
	 * @return "ACTIVE" / "INACTIVE" / null if slot not found on break.
	 */
	public String endBreak(int slotId, int agentId) throws SQLException {
		conn.setAutoCommit(false);
		try {
			String fetchSql = "SELECT break_start, total_break_min FROM delivery_slots "
					+ "WHERE slot_id=? AND agent_id=? AND status='ON_BREAK'";
			java.sql.Timestamp breakStart = null;
			int prevTotal = 0;

			try (PreparedStatement ps = conn.prepareStatement(fetchSql)) {
				ps.setInt(1, slotId);
				ps.setInt(2, agentId);
				try (ResultSet rs = ps.executeQuery()) {
					if (rs.next()) {
						breakStart = rs.getTimestamp("break_start");
						prevTotal = rs.getInt("total_break_min");
					}
				}
			}

			if (breakStart == null) {
				conn.rollback();
				return null;
			}

			long breakMs = System.currentTimeMillis() - breakStart.getTime();
			int breakMins = (int) (breakMs / 60_000);
			int newTotal = prevTotal + breakMins;
			String newStatus = (breakMins > MAX_BREAK_MINUTES) ? "INACTIVE" : "ACTIVE";

			String updateSql = "UPDATE delivery_slots " + "SET status=?, total_break_min=?, break_start=NULL "
					+ "WHERE slot_id=? AND agent_id=?";
			try (PreparedStatement ps = conn.prepareStatement(updateSql)) {
				ps.setString(1, newStatus);
				ps.setInt(2, newTotal);
				ps.setInt(3, slotId);
				ps.setInt(4, agentId);
				ps.executeUpdate();
			}

			conn.commit();
			log.info("endBreak: agent #" + agentId + " slot #" + slotId + " breakMins=" + breakMins + " total="
					+ newTotal + " → " + newStatus);
			return newStatus;

		} catch (Exception e) {
			conn.rollback();
			throw e;
		} finally {
			conn.setAutoCommit(true);
		}
	}

	/**
	 * Returns total break minutes accumulated (including any in-progress break).
	 */
	public int getBreakMinutes(int slotId) throws SQLException {
		String sql = "SELECT total_break_min, break_start FROM delivery_slots WHERE slot_id=?";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, slotId);
			try (ResultSet rs = ps.executeQuery()) {
				if (rs.next()) {
					int total = rs.getInt("total_break_min");
					java.sql.Timestamp bs = rs.getTimestamp("break_start");
					if (bs != null) {
						total += (int) ((System.currentTimeMillis() - bs.getTime()) / 60_000);
					}
					return total;
				}
			}
		}
		return 0;
	}

	/**
	 * BUG-4 FIX: Returns the epoch-ms when the current break started for a slot in
	 * ON_BREAK status, or 0 if not on break / break_start is NULL. Used by
	 * DeliveryPortalServlet to expose portalBreakStartEpochMs so the JSP can seed
	 * _shiftState.breakStartEpoch for the working-hours live clock.
	 */
	public long getBreakStartEpochMs(int slotId) throws SQLException {
		String sql = "SELECT break_start FROM delivery_slots WHERE slot_id=? AND status='ON_BREAK'";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, slotId);
			try (ResultSet rs = ps.executeQuery()) {
				if (rs.next()) {
					java.sql.Timestamp bs = rs.getTimestamp("break_start");
					return bs != null ? bs.getTime() : 0L;
				}
			}
		}
		return 0L;
	}

	/**
	 * Returns seconds remaining in the current break before auto-offline. -1 if not
	 * on break.
	 */
	public int getBreakSecondsRemaining(int slotId) throws SQLException {
		String sql = "SELECT break_start, total_break_min FROM delivery_slots "
				+ "WHERE slot_id=? AND status='ON_BREAK'";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, slotId);
			try (ResultSet rs = ps.executeQuery()) {
				if (rs.next()) {
					java.sql.Timestamp bs = rs.getTimestamp("break_start");
					if (bs == null) {
						return -1;
					}
					long elapsed = (System.currentTimeMillis() - bs.getTime()) / 1000;
					long allowed = (long) MAX_BREAK_MINUTES * 60;
					return (int) Math.max(0, allowed - elapsed);
				}
			}
		}
		return -1;
	}

	/** Forces slot to INACTIVE (break overflow auto-offline). */
	public boolean forceOffline(int slotId, int agentId) throws SQLException {
		String sql = "UPDATE delivery_slots SET status='INACTIVE', break_start=NULL "
				+ "WHERE slot_id=? AND agent_id=? AND status IN ('ON_BREAK','ACTIVE','BOOKED')";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, slotId);
			ps.setInt(2, agentId);
			return ps.executeUpdate() > 0;
		}
	}

	/** ACTIVE/ON_BREAK/INACTIVE → COMPLETED. Credits earnings to wallet. */
	public boolean completeSlot(int slotId, int agentId) throws SQLException {
		String sql = "UPDATE delivery_slots SET status='COMPLETED', shift_ended_at=NOW() "
				+ "WHERE slot_id=? AND agent_id=? AND status IN ('ACTIVE','ON_BREAK','INACTIVE')";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, slotId);
			ps.setInt(2, agentId);
			boolean updated = ps.executeUpdate() > 0;
			if (updated) {
				calculateAndCreditEarnings(slotId, agentId);
			}
			return updated;
		}
	}

	// ─────────────────────────────────────────────────────────────────────────
	// CANCEL SLOT — NO PENALTY
	// ─────────────────────────────────────────────────────────────────────────

	public boolean cancelSlot(int slotId, int agentId, String reason) throws SQLException {
		conn.setAutoCommit(false);
		try {
			String sql = "UPDATE delivery_slots SET status='CANCELLED', cancelled_reason=? "
					+ "WHERE slot_id=? AND agent_id=? AND status IN ('BOOKED','ACTIVE','ON_BREAK','INACTIVE')";
			try (PreparedStatement ps = conn.prepareStatement(sql)) {
				ps.setString(1, reason);
				ps.setInt(2, slotId);
				ps.setInt(3, agentId);
				if (ps.executeUpdate() == 0) {
					conn.rollback();
					return false;
				}
			}

			String logCancellation = "INSERT INTO slot_cancellations "
					+ "(slot_id, agent_id, reason, penalty_applied, cancelled_at) " + "VALUES (?, ?, ?, 0, NOW())";
			try (PreparedStatement ps = conn.prepareStatement(logCancellation)) {
				ps.setInt(1, slotId);
				ps.setInt(2, agentId);
				ps.setString(3, reason != null ? reason : "No reason given");
				ps.executeUpdate();
			}

			conn.commit();
			log.info("cancelSlot: slot #" + slotId + " agent #" + agentId + " — no penalty.");
			return true;
		} catch (Exception e) {
			conn.rollback();
			throw e;
		} finally {
			conn.setAutoCommit(true);
		}
	}

	// ─────────────────────────────────────────────────────────────────────────
	// ADMIN
	// ─────────────────────────────────────────────────────────────────────────

	public List<DeliverySlot> getSlotsForDate(LocalDate date) throws SQLException {
		String sql = "SELECT ds.*, dz.zone_name, dz.is_surge, dz.surge_multiplier, "
				+ "       u.username AS agent_name, u.mobile AS agent_phone, "
				+ "       COALESCE(ds.pending_count + ds.active_count + ds.delivered_count, 0) AS total_orders "
				+ "FROM delivery_slots ds " + "JOIN delivery_zones dz ON ds.zone_id = dz.zone_id "
				+ "JOIN users u ON ds.agent_id = u.id " + "WHERE ds.slot_date = ? "
				+ "ORDER BY FIELD(ds.slot_type,'EARLY_MORNING','MIDNIGHT','AM','PM','EVENING','FULL_DAY','NIGHT') ASC, "
				+ "         ds.agent_id ASC";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setDate(1, java.sql.Date.valueOf(date));
			try (ResultSet rs = ps.executeQuery()) {
				List<DeliverySlot> list = new ArrayList<>();
				while (rs.next()) {
					list.add(mapSlotAdmin(rs));
				}
				return list;
			}
		}
	}

	public List<DeliverySlot> getActiveSlotsForAdmin() throws SQLException {
		String sql = "SELECT ds.*, dz.zone_name, dz.is_surge, dz.surge_multiplier, "
				+ "       u.username AS agent_name, u.mobile AS agent_phone, "
				+ "       (COALESCE(ds.pending_count,0) + COALESCE(ds.active_count,0) "
				+ "        + COALESCE(ds.delivered_count,0)) AS total_orders " + "FROM delivery_slots ds "
				+ "JOIN delivery_zones dz ON ds.zone_id = dz.zone_id " + "JOIN users u ON ds.agent_id = u.id "
				+ "WHERE ds.slot_date = CURDATE() AND ds.status IN ('BOOKED','ACTIVE') "
				+ "HAVING total_orders < ds.max_orders " + "ORDER BY total_orders ASC";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			try (ResultSet rs = ps.executeQuery()) {
				List<DeliverySlot> list = new ArrayList<>();
				while (rs.next()) {
					list.add(mapSlotAdmin(rs));
				}
				return list;
			}
		}
	}

	/**
	 * Links an order to the agent's currently active slot and increments
	 * pending_count atomically. For multi-slot agents, priority: ACTIVE / ON_BREAK
	 * (agent is working) -> BOOKED (shift not started yet) pending_count is
	 * incremented in the same transaction so counters stay consistent without a
	 * separate updateSlotCounters() call.
	 */
	public boolean assignOrderToSlot(int orderId, int agentId) throws SQLException {
		// REFACTORED: The complex time strings are removed. We look directly for any
		// slot
		// whose absolute window encompasses the current time.
		// Prioritise ACTIVE/ON_BREAK; fall back to BOOKED for pre-shift assignment.
		String findSlot = "SELECT slot_id FROM delivery_slots " + "WHERE agent_id=? "
				+ "  AND NOW() >= DATE_SUB(window_start_at, INTERVAL 30 MINUTE) " // Includes early assignment buffer
				+ "  AND NOW() < window_end_at " + "  AND status IN ('ACTIVE','ON_BREAK','BOOKED') "
				+ "ORDER BY FIELD(status,'ACTIVE','ON_BREAK','BOOKED') ASC LIMIT 1";

		int slotId = -1;
		try (PreparedStatement ps = conn.prepareStatement(findSlot)) {
			ps.setInt(1, agentId);
			try (ResultSet rs = ps.executeQuery()) {
				if (rs.next()) {
					slotId = rs.getInt("slot_id");
				}
			}
		}

		if (slotId == -1) {
			log.warning("assignOrderToSlot: no active/booked slot for agent #" + agentId + " — order #" + orderId
					+ " not linked.");
			return false;
		}

		conn.setAutoCommit(false);
		try {
			// FIX: Do NOT touch status here. The caller (assignDeliveryPerson,
			// assignPickupAgent, etc.) has already set the correct status for its context
			// ('Assigned' for a normal delivery, 'Return Agent Assigned' for a return
			// pickup). Hardcoding status='Assigned' was overwriting the correct return
			// status every time slot linkage ran after
			// assignPickupAgent/reassignPickupAgent.
			String assign = "UPDATE orders SET delivery_user_id=?, slot_id=? "
					+ "WHERE order_id=? AND status NOT IN ('Delivered','Cancelled')";
			int updated;
			try (PreparedStatement ps = conn.prepareStatement(assign)) {
				ps.setInt(1, agentId);
				ps.setInt(2, slotId);
				ps.setInt(3, orderId);
				updated = ps.executeUpdate();
			}

			if (updated > 0) {
				String inc = "UPDATE delivery_slots "
						+ "SET pending_count = GREATEST(0, CAST(pending_count AS SIGNED) + 1) " + "WHERE slot_id=?";
				try (PreparedStatement ps = conn.prepareStatement(inc)) {
					ps.setInt(1, slotId);
					ps.executeUpdate();
				}
			}

			conn.commit();
			log.info("assignOrderToSlot: order #" + orderId + " -> slot #" + slotId + " (agent #" + agentId + ")");
			return updated > 0;
		} catch (Exception e) {
			conn.rollback();
			throw e;
		} finally {
			conn.setAutoCommit(true);
		}
	}
	// ─────────────────────────────────────────────────────────────────────────
	// EARNINGS — WALLET INTEGRATION (BUG-06 FIX: full BigDecimal migration)
	// ─────────────────────────────────────────────────────────────────────────

	/**
	 * Records an order earning row at delivery time (not yet credited to wallet).
	 * Uses double for DB schema compatibility (agent_earnings.base_pay is DOUBLE).
	 * Streak/credit logic in calculateAndCreditEarnings uses BigDecimal.
	 */
	public void recordOrderEarning(int agentId, int orderId, int slotId) throws SQLException {
		double basePay = getConfigValue("base_pay_per_order");
		boolean isSurge = isSlotInSurgeZone(slotId);
		double surgeMultiplier = getSurgeMultiplier(slotId);
		double surgeBonus = isSurge ? basePay * (surgeMultiplier - 1.0) : 0.0;

		String sql = "INSERT INTO agent_earnings " + "(agent_id, order_id, slot_id, base_pay, surge_bonus) "
				+ "VALUES (?,?,?,?,?) " + "ON DUPLICATE KEY UPDATE base_pay=VALUES(base_pay)";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, agentId);
			ps.setInt(2, orderId);
			ps.setInt(3, slotId);
			ps.setDouble(4, basePay);
			ps.setDouble(5, surgeBonus);
			ps.executeUpdate();
		}
	}

	/**
	 * BUG-06 FIX: Entire method migrated from double to BigDecimal. All wallet
	 * balance updates, transaction records, and comparisons now use exact decimal
	 * arithmetic. setDouble/getDouble replaced with setBigDecimal/getBigDecimal
	 * throughout.
	 */
	private void calculateAndCreditEarnings(int slotId, int agentId) throws SQLException {
		// Count deliveries
		int deliveries = 0;
		String countSql = "SELECT COUNT(*) FROM agent_earnings WHERE slot_id=? AND agent_id=?";
		try (PreparedStatement ps = conn.prepareStatement(countSql)) {
			ps.setInt(1, slotId);
			ps.setInt(2, agentId);
			try (ResultSet rs = ps.executeQuery()) {
				if (rs.next()) {
					deliveries = rs.getInt(1);
				}
			}
		}

		// Streak bonus
		int streakThreshold = (int) getConfigValue("streak_threshold");
		if (deliveries >= streakThreshold && streakThreshold > 0) {
			BigDecimal streakBonus = BigDecimal.valueOf(getConfigValue("streak_bonus_amount"));
			BigDecimal perOrder = deliveries > 0
					? streakBonus.divide(BigDecimal.valueOf(deliveries), 4, RoundingMode.HALF_UP)
					: BigDecimal.ZERO;
			String updateStreak = "UPDATE agent_earnings SET streak_bonus=? " + "WHERE slot_id=? AND agent_id=?";
			try (PreparedStatement ps = conn.prepareStatement(updateStreak)) {
				ps.setBigDecimal(1, perOrder);
				ps.setInt(2, slotId);
				ps.setInt(3, agentId);
				ps.executeUpdate();
			}
		}

		// Sum uncredited total using BigDecimal
		BigDecimal totalCredit = BigDecimal.ZERO;
		String sumSql = "SELECT COALESCE(SUM(total_earning), 0) FROM agent_earnings "
				+ "WHERE slot_id=? AND agent_id=? AND credited=FALSE";
		try (PreparedStatement ps = conn.prepareStatement(sumSql)) {
			ps.setInt(1, slotId);
			ps.setInt(2, agentId);
			try (ResultSet rs = ps.executeQuery()) {
				if (rs.next()) {
					BigDecimal raw = rs.getBigDecimal(1);
					totalCredit = (raw != null) ? raw : BigDecimal.ZERO;
				}
			}
		}

		if (totalCredit.compareTo(BigDecimal.ZERO) > 0) {
			// Compute new balance using BigDecimal to prevent drift
			BigDecimal newBalance = BigDecimal.ZERO;
			String getBalSql = "SELECT COALESCE(balance, 0) FROM agent_wallets WHERE agent_id=?";
			try (PreparedStatement ps = conn.prepareStatement(getBalSql)) {
				ps.setInt(1, agentId);
				try (ResultSet rs = ps.executeQuery()) {
					if (rs.next()) {
						BigDecimal cur = rs.getBigDecimal(1);
						newBalance = (cur != null ? cur : BigDecimal.ZERO).add(totalCredit);
					}
				}
			}

			// Update wallet
			String creditWallet = "UPDATE agent_wallets "
					+ "SET balance = balance + ?, total_earned = total_earned + ?, updated_at = NOW() "
					+ "WHERE agent_id=?";
			try (PreparedStatement ps = conn.prepareStatement(creditWallet)) {
				ps.setBigDecimal(1, totalCredit);
				ps.setBigDecimal(2, totalCredit);
				ps.setInt(3, agentId);
				ps.executeUpdate();
			}

			// Insert transaction record
			String addTransaction = "INSERT INTO agent_wallet_transactions "
					+ "(agent_id, order_id, type, amount, balance_after, description, created_at) "
					+ "VALUES (?, NULL, 'slot_earning', ?, ?, ?, NOW())";
			try (PreparedStatement ps = conn.prepareStatement(addTransaction)) {
				ps.setInt(1, agentId);
				ps.setBigDecimal(2, totalCredit);
				ps.setBigDecimal(3, newBalance);
				ps.setString(4, "Shift earnings — Slot #" + slotId + " (" + deliveries + " deliveries)");
				ps.executeUpdate();
			}

			// Mark as credited
			String markCredited = "UPDATE agent_earnings SET credited=TRUE, credited_at=NOW() "
					+ "WHERE slot_id=? AND agent_id=?";
			try (PreparedStatement ps = conn.prepareStatement(markCredited)) {
				ps.setInt(1, slotId);
				ps.setInt(2, agentId);
				ps.executeUpdate();
			}

			log.info("Credited ₹" + totalCredit.toPlainString() + " to agent #" + agentId + " for slot #" + slotId
					+ " (" + deliveries + " deliveries)" + " | new balance ₹" + newBalance.toPlainString());
		} else {
			log.info("No uncredited earnings for slot #" + slotId + " agent #" + agentId + " — wallet unchanged.");
		}
	}

	// ─────────────────────────────────────────────────────────────────────────
	// ZONES
	// ─────────────────────────────────────────────────────────────────────────

	public List<DeliveryZone> getAllZones() throws SQLException {
		String sql = "SELECT * FROM delivery_zones ORDER BY zone_name";
		try (PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
			List<DeliveryZone> zones = new ArrayList<>();
			while (rs.next()) {
				DeliveryZone z = new DeliveryZone();
				z.setZoneId(rs.getInt("zone_id"));
				z.setZoneName(rs.getString("zone_name"));
				z.setPincodes(rs.getString("pincodes"));
				z.setSurge(rs.getBoolean("is_surge"));
				z.setSurgeMultiplier(rs.getDouble("surge_multiplier"));
				zones.add(z);
			}
			return zones;
		}
	}

	public boolean updateZoneSurge(int zoneId, boolean isSurge, double multiplier) throws SQLException {
		conn.setAutoCommit(false);
		try {
			String updateZone = "UPDATE delivery_zones SET is_surge=?, surge_multiplier=? " + "WHERE zone_id=?";
			int rows;
			try (PreparedStatement ps = conn.prepareStatement(updateZone)) {
				ps.setBoolean(1, isSurge);
				ps.setDouble(2, isSurge ? multiplier : 1.0);
				ps.setInt(3, zoneId);
				rows = ps.executeUpdate();
			}
			if (rows == 0) {
				conn.rollback();
				return false;
			}
			conn.commit();
			return true;
		} catch (Exception e) {
			conn.rollback();
			throw e;
		} finally {
			conn.setAutoCommit(true);
		}
	}

	/**
	 * Inserts a new delivery zone. Returns the generated zone_id, or -1 if a zone
	 * with the same name already exists.
	 */
	public int addZone(String zoneName, String pincodes) throws SQLException {
		String check = "SELECT zone_id FROM delivery_zones WHERE zone_name = ?";
		try (PreparedStatement ps = conn.prepareStatement(check)) {
			ps.setString(1, zoneName);
			try (java.sql.ResultSet rs = ps.executeQuery()) {
				if (rs.next()) {
					return -1; // duplicate name
				}
			}
		}
		String sql = "INSERT INTO delivery_zones (zone_name, pincodes, is_surge, surge_multiplier) VALUES (?, ?, false, 1.0)";
		try (PreparedStatement ps = conn.prepareStatement(sql, java.sql.Statement.RETURN_GENERATED_KEYS)) {
			ps.setString(1, zoneName.trim());
			ps.setString(2, pincodes != null ? pincodes.trim() : "");
			ps.executeUpdate();
			try (java.sql.ResultSet gk = ps.getGeneratedKeys()) {
				return gk.next() ? gk.getInt(1) : 0;
			}
		}
	}

	/**
	 * Deletes a zone only if it has no active/booked delivery slots referencing it.
	 * Returns "ok", "has_slots", or "not_found".
	 */
	public String deleteZone(int zoneId) throws SQLException {
		String checkSlots = "SELECT COUNT(*) FROM delivery_slots WHERE zone_id = ? AND status IN ('BOOKED','ACTIVE','ON_BREAK')";
		try (PreparedStatement ps = conn.prepareStatement(checkSlots)) {
			ps.setInt(1, zoneId);
			try (java.sql.ResultSet rs = ps.executeQuery()) {
				if (rs.next() && rs.getInt(1) > 0) {
					return "has_slots";
				}
			}
		}
		String del = "DELETE FROM delivery_zones WHERE zone_id = ?";
		try (PreparedStatement ps = conn.prepareStatement(del)) {
			ps.setInt(1, zoneId);
			return ps.executeUpdate() > 0 ? "ok" : "not_found";
		}
	}

	// ─────────────────────────────────────────────────────────────────────────
	// STATIC SLOT-TYPE HELPERS (BUG-15 FIX: all three new types handled)
	// ─────────────────────────────────────────────────────────────────────────

	/**
	 * Wall-clock START time for a slot type. BUG-15 FIX: NIGHT, MIDNIGHT,
	 * EARLY_MORNING arms added.
	 */
	public static LocalTime getSlotStartTime(String slotType) {
		return switch (slotType) {
		case "EARLY_MORNING" -> LocalTime.of(4, 0);
		case "MIDNIGHT" -> LocalTime.of(2, 0);
		case "AM" -> LocalTime.of(6, 0);
		case "PM" -> LocalTime.of(12, 0);
		case "EVENING" -> LocalTime.of(18, 0);
		case "FULL_DAY" -> LocalTime.of(6, 0);
		case "NIGHT" -> LocalTime.of(22, 0);
		default -> LocalTime.of(6, 0);
		};
	}

	/**
	 * Wall-clock END time for a slot type. BUG-15 FIX: NIGHT, MIDNIGHT,
	 * EARLY_MORNING arms added. NOTE: NIGHT ends at 02:00 — this is on the NEXT
	 * calendar day. Use isOvernightSlot() to detect and add +1 day to the end date.
	 */
	public static LocalTime getSlotEndTime(String slotType) {
		return switch (slotType) {
		case "EARLY_MORNING" -> LocalTime.of(8, 0);
		case "MIDNIGHT" -> LocalTime.of(6, 0);
		case "AM" -> LocalTime.of(12, 0);
		case "PM" -> LocalTime.of(18, 0);
		case "EVENING" -> LocalTime.of(22, 0);
		case "FULL_DAY" -> LocalTime.of(22, 0);
		case "NIGHT" -> LocalTime.of(2, 0); // next day — see isOvernightSlot()
		default -> LocalTime.of(23, 59);
		};
	}

	/**
	 * BUG-19 FIX: Returns true if this slot type crosses midnight and its end time
	 * falls on the next calendar day. Callers must add +1 day to slotDate when
	 * computing the end epoch for NIGHT slots.
	 *
	 * ROOT CAUSE FIX: EARLY_MORNING (4 AM–8 AM) is NOT overnight — it runs on the
	 * same calendar day it is booked. Removing it from this set fixes
	 * window_start_at being stored as slot_date+1 (e.g. booked 2026-05-20 but shift
	 * shown as 2026-05-21 04:00). Only NIGHT genuinely crosses midnight. MIDNIGHT
	 * (2 AM–6 AM) is special: it is booked on the previous evening so its entire
	 * window falls on slot_date+1 — it stays here.
	 */
	public static boolean isOvernightSlot(String slotType) {
		return "NIGHT".equals(slotType);
	}

	/**
	 * ROOT CAUSE FIX: EARLY_MORNING removed from the +1 day guard. MIDNIGHT shifts
	 * are booked the evening before, so their window starts on slot_date+1.
	 * EARLY_MORNING shifts start at 4 AM on slot_date itself — no date offset is
	 * needed.
	 */
	public static LocalDate getSlotStartDate(LocalDate slotDate, String slotType) {
		return "MIDNIGHT".equals(slotType) ? slotDate.plusDays(1) : slotDate;
	}

	/**
	 * Returns the end LocalDate for a slot given its start date. For overnight
	 * slots the end is slotDate + 1; for all others it is slotDate.
	 */
	public static LocalDate getSlotEndDate(LocalDate slotDate, String slotType) {
		return isOvernightSlot(slotType) ? slotDate.plusDays(1) : slotDate;
	}

	/**
	 * Latest time by which an agent may book a slot for same-day assignment. BUG-15
	 * FIX: NIGHT, MIDNIGHT, EARLY_MORNING arms added.
	 */
	/**
	 * Latest time an agent may book a slot for same-day delivery. FIXED: cutoff =
	 * START time of each slot (once the shift starts, booking is closed).
	 * Previously AM/PM/EVENING incorrectly used their END times, allowing booking
	 * of a slot that was already half-over.
	 *
	 * MIDNIGHT 02:00 EARLY_MORNING 04:00 AM 06:00 FULL_DAY 06:00 PM 12:00 EVENING
	 * 18:00 NIGHT 22:00
	 */
	public static LocalTime getSlotBookingCutoff(String slotType) {
		return switch (slotType) {
		case "MIDNIGHT" -> LocalTime.of(2, 0); // book before 02:00
		case "EARLY_MORNING" -> LocalTime.of(4, 0); // book before 04:00
		case "AM" -> LocalTime.of(6, 0); // book before 06:00 (start)
		case "PM" -> LocalTime.of(12, 0); // book before 12:00 (start)
		case "EVENING" -> LocalTime.of(18, 0); // book before 18:00 (start)
		case "FULL_DAY" -> LocalTime.of(6, 0); // book before 06:00 (start)
		case "NIGHT" -> LocalTime.of(22, 0); // book before 22:00 (start)
		default -> LocalTime.of(6, 0);
		};
	}

	// ─────────────────────────────────────────────────────────────────────────
	// EXPIRY & ACTIVATABILITY
	// ─────────────────────────────────────────────────────────────────────────

	/**
	 * Expires stale BOOKED slots whose shift window has fully elapsed.
	 *
	 * RULE: A BOOKED slot is only marked EXPIRED after its SLOT END TIME has passed
	 * — not at the booking cutoff / start time. This gives the agent the entire
	 * shift window to start their shift. The booking cutoff (preventing new
	 * bookings once a shift has started) is a separate, unaffected guard.
	 *
	 * BUG-08 FIX: CASE expression extended with NIGHT (DATE_ADD for overnight),
	 * MIDNIGHT, and EARLY_MORNING end times.
	 *
	 * @return total number of slots expired.
	 */
	public int expireStaleBookedSlots() throws SQLException {
		// ══════════════════════════════════════════════════════════════════════
		// EXPIRY RULE — CORRECTED (fixes the "slot reverts to EXPIRED seconds
		// after manual DB fix" bug and the "advance booking expires immediately"
		// bug described in the incident report for slot_id=46).
		//
		// ROOT CAUSE OF THE BUG:
		// slot_id=46, PM (12:00–18:00), slot_date=2026-05-29.
		// window_start_at = 2026-05-29 12:00:00
		// window_end_at = 2026-05-29 18:00:00
		// Server was restarted at ~14:49. At that time NOW() > 17:00, so
		// GREATEST(12:30, 17:00) = 17:00 and NOW() >= 17:00 → immediately
		// EXPIRED. Any manual SET status='BOOKED' fix was overwritten the
		// instant the next HTTP request triggered expireStaleBookedSlots().
		// When the server was OFF there were no HTTP requests, so the status
		// held. This explained the exact observation: "status not affected
		// when server is off".
		//
		// MANDATORY REQUIREMENT (from spec):
		// • A BOOKED slot must NOT expire until 1 hour BEFORE its shift ends.
		// • An advance-booked slot (future date) must NEVER expire before its
		// window_start_at has been reached.
		// • An agent can book a slot for any future date and start the shift
		// on that date within the shift window.
		//
		// EXPIRY RULE — TWO GUARDS, BOTH REQUIRED:
		// 1. window_start_at IS NOT NULL AND window_end_at IS NOT NULL
		// → protects rows inserted before these columns existed (NULL = safe)
		// 2. NOW() >= window_start_at
		// → the shift window has OPENED (ADVANCE BOOKING SAFETY):
		// a slot booked for tomorrow has window_start_at in the future.
		// NOW() < window_start_at → guard fails → slot is never touched today.
		// This is the KEY protection for advance-booked slots at midnight.
		// 3. NOW() >= DATE_SUB(window_end_at, INTERVAL 1 HOUR)
		// → we are within the last 1 hour of the shift end. Agent had the
		// entire preceding window to start; we expire 1 hr before shift ends.
		//
		// Guards 2+3 together guarantee:
		// • Future slots are safe (Guard 2 blocks them before their window opens)
		// • Active-window slots are only expired in the last hour (Guard 3)
		// • For all slots ≥ 4 hours, DATE_SUB(end, 1hr) > window_start_at,
		// so Guard 2 is always satisfied before Guard 3 first becomes true.
		// ══════════════════════════════════════════════════════════════════════
		String SQL_EXPIRE = "UPDATE delivery_slots " + "SET status = 'EXPIRED' " + "WHERE TRIM(status) = 'BOOKED' "
				+ "  AND window_start_at IS NOT NULL " + "  AND window_end_at   IS NOT NULL "
				// Guard 1: The shift window must have already OPENED.
				// This is the critical advance-booking protection:
				// A slot booked today for tomorrow has window_start_at in the future.
				// NOW() < window_start_at → this guard FAILS → slot is never touched.
				// Without this guard, at midnight a FULL_DAY slot booked for tomorrow
				// (window_end_at = tomorrow 22:00) could match DATE_SUB(end, 1hr) = 21:00
				// if the server clock is wrong or in UTC while times are stored as IST.
				+ "  AND NOW() >= window_start_at "
				// Guard 2: Expire only when within the last 1 hour of the shift.
				// For any slot ≥ 4 hours, DATE_SUB(end, 1hr) is always after window_start_at,
				// so Guard 1 (window opened) is always satisfied before Guard 2 triggers.
				+ "  AND NOW() >= DATE_SUB(window_end_at, INTERVAL 1 HOUR)";
		// ADVANCE BOOKING PROOF:
		// FULL_DAY booked June 5 at 1pm for June 6: window_start_at=June 6 06:00
		// At midnight June 6 (00:31): NOW() >= June 6 06:00 → FALSE → SAFE ✓
		// At 06:01 June 6: Guard 1 passes. DATE_SUB(22:00, 1hr)=21:00. 06:01 >= 21:00 →
		// FALSE ✓
		// At 21:01 June 6: Both guards pass → slot correctly expires. ✓
		// SAME-DAY LATE BOOKING PROOF (the original bug):
		// PM slot booked at 17:10 (window_start=12:00, window_end=18:00):
		// NOW() >= 12:00 → TRUE (Guard 1 passes)
		// NOW() >= DATE_SUB(18:00, 1hr)=17:00 → 17:10 >= 17:00 → TRUE (Guard 2 passes)
		// Result: slot expires. This is CORRECT — agent booked into the last hour of a
		// slot.
		// The booking cutoff for PM is 12:00, so booking at 17:10 should not be
		// possible
		// for same-day; for advance booking the slot is still future-safe via Guard 1.

		int total = 0;
		try (PreparedStatement ps = conn.prepareStatement(SQL_EXPIRE)) {
			total = ps.executeUpdate(); // FIX: execute exactly ONCE (was called twice)
		}

		if (total > 0) {
			// BUG-FIX: The old syncLedger used "WHERE ds.status = 'EXPIRED'" which matches
			// ALL historically expired slots — not just the ones expired in THIS batch.
			// Every portal load would re-stamp status_changed_at = NOW() on old expiries,
			// making it look like slots were expiring at the current moment even when they
			// actually expired hours/days ago. The notification query then fired again for
			// those same old slots (within the 10-second window), sending duplicate alerts.
			//
			// FIX: Scope both queries to slots expired in THIS run only, identified by
			// their window_end_at falling within [DATE_SUB(window_end_at,1hr),
			// window_end_at]
			// using the same condition as SQL_EXPIRE. This ensures only freshly expired
			// slots (those just flipped from BOOKED → EXPIRED moments ago) are touched.
			String syncLedger = "UPDATE agent_slot_bookings asb "
					+ "JOIN delivery_slots ds ON asb.slot_id = ds.slot_id "
					+ "SET asb.status = 'Expired', asb.status_changed_at = NOW() " + "WHERE ds.status = 'EXPIRED' "
					+ "  AND asb.status = 'Booked' "
					// Only sync the ledger for slots that JUST became expired this batch:
					// their window ended within the last 1 hour (matching SQL_EXPIRE window).
					+ "  AND ds.window_end_at IS NOT NULL "
					+ "  AND NOW() >= DATE_SUB(ds.window_end_at, INTERVAL 1 HOUR) "
					+ "  AND NOW() < DATE_ADD(ds.window_end_at, INTERVAL 1 HOUR)";
			try (PreparedStatement ps = conn.prepareStatement(syncLedger)) {
				ps.executeUpdate();
			}
			// Notify each affected agent — scoped to the same fresh-expiry window.
			String notifQuery = "SELECT ds.slot_id, ds.agent_id, ds.slot_type FROM delivery_slots ds "
					+ "JOIN agent_slot_bookings asb ON asb.slot_id = ds.slot_id " + "WHERE ds.status = 'EXPIRED' "
					+ "  AND asb.status = 'Expired' " + "  AND ds.window_end_at IS NOT NULL "
					+ "  AND NOW() >= DATE_SUB(ds.window_end_at, INTERVAL 1 HOUR) "
					+ "  AND NOW() < DATE_ADD(ds.window_end_at, INTERVAL 1 HOUR) "
					+ "  AND asb.status_changed_at >= DATE_SUB(NOW(), INTERVAL 10 SECOND)";
			try (PreparedStatement ps2 = conn.prepareStatement(notifQuery); ResultSet rn = ps2.executeQuery()) {
				while (rn.next()) {
					int aId = rn.getInt("agent_id");
					int sId = rn.getInt("slot_id");
					String sType = rn.getString("slot_type");
					pushSlotNotification(aId, "SHIFT_EXPIRED", "Slot expired — " + sType + " shift",
							"Your " + sType.toLowerCase().replace("_", " ") + " slot expired without being started. "
									+ "Please book a new slot to go online.",
							"⏰", "red", sId);
				}
			} catch (Exception notifEx) {
				log.warning("expiry notification failed: " + notifEx.getMessage());
			}
			log.info("expireStaleBookedSlots: expired " + total + " elapsed BOOKED slot(s).");
		}
		try {
			String warnSql = "SELECT ds.slot_id, ds.agent_id, ds.slot_type, ds.window_end_at "
					+ "FROM delivery_slots ds " + "WHERE ds.status = 'BOOKED' "
					+ "  AND ds.window_start_at IS NOT NULL " + "  AND ds.window_end_at IS NOT NULL "
					// Guard 1: shift window must have opened (advance-booking safety — same logic
					// as SQL_EXPIRE)
					+ "  AND NOW() >= ds.window_start_at "
					// Guard 2: warn when within the last 2 hours of the shift
					+ "  AND NOW() >= DATE_SUB(ds.window_end_at, INTERVAL 2 HOUR) "
					+ "  AND NOW() < DATE_SUB(ds.window_end_at, INTERVAL 1 HOUR) " + "  AND NOT EXISTS ( "
					+ "    SELECT 1 FROM agent_notifications an " + "    WHERE an.agent_id = ds.agent_id "
					+ "    AND an.type = 'SHIFT_EXPIRY_WARNING' " + "    AND an.ref_id = ds.slot_id "
					+ "    AND an.created_at >= DATE_SUB(NOW(), INTERVAL 3 HOUR)) ";
			try (PreparedStatement warnPs = conn.prepareStatement(warnSql); ResultSet warnRs = warnPs.executeQuery()) {
				while (warnRs.next()) {
					int wAgentId = warnRs.getInt("agent_id");
					int wSlotId = warnRs.getInt("slot_id");
					String wType = warnRs.getString("slot_type");
					pushSlotNotification(wAgentId, "SHIFT_EXPIRY_WARNING",
							"⚠️ Slot expiring soon — " + wType + " shift",
							"Your " + wType.toLowerCase().replace("_", " ")
									+ " slot expires in 1 hour. Start your shift now or it will be forfeited.",
							"⚠️", "amber", wSlotId);
				}
			}
		} catch (Exception warnEx) {
			log.warning("SHIFT_EXPIRY_WARNING non-fatal: " + warnEx.getMessage());
		}
		return total;

	}

	/**
	 * Returns true if the BOOKED slot can still be started (activated) by the
	 * agent.
	 *
	 * RULE: An agent may start their shift at any point from 15 minutes before the
	 * slot start time up to (but not including) the slot END time. The slot is
	 * considered expired — and therefore no longer activatable — only once the full
	 * shift window has elapsed. This applies to shift-starting only; the booking
	 * cutoff (preventing new bookings) is a separate, unchanged guard.
	 *
	 * Overnight (NIGHT) slots that started today are still activatable until 02:00
	 * the following morning.
	 *
	 * BUG-C FIX: The original code had `if (slotDate.isBefore(today)) return false`
	 * which fires at midnight for a NIGHT slot (slot_date=yesterday). At 1:30 AM
	 * the slot is still in progress but the method incorrectly returned false,
	 * making the Start Shift button permanently disabled. Now we detect the
	 * post-midnight NIGHT window and return true when we are before 02:00.
	 */
	public boolean isSlotActivatable(int slotId, int agentId) throws java.sql.SQLException {
		String sql = "SELECT slot_type, slot_date FROM delivery_slots WHERE slot_id = ? AND agent_id = ? AND status = 'BOOKED'";
		try (java.sql.PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, slotId);
			ps.setInt(2, agentId);
			try (java.sql.ResultSet rs = ps.executeQuery()) {
				if (!rs.next()) {

					System.out.println("slot not found");
					return false; // slot not found or not in BOOKED state
				}
				String slotType = rs.getString("slot_type");
				Date dbDate = rs.getDate("slot_date");
				if (dbDate == null) {

					System.out.println("date doesnot exits");
					return false;
				}

				LocalDate slotDate = dbDate.toLocalDate();

				boolean windowOpen = ShiftWindowValidator.isShiftWindowOpen(slotType, slotDate,
						java.time.ZoneId.systemDefault());
				if (windowOpen) {
					// Push SHIFT_STARTING once per slot (deduplicated by 2-hour window)
					String chkSql = "SELECT 1 FROM agent_notifications "
							+ "WHERE agent_id=? AND type='SHIFT_STARTING' AND ref_id=? "
							+ "AND created_at >= DATE_SUB(NOW(), INTERVAL 2 HOUR) LIMIT 1";
					try (java.sql.PreparedStatement chk = conn.prepareStatement(chkSql);
							java.sql.PreparedStatement dummy = null) {
						chk.setInt(1, agentId);
						chk.setInt(2, slotId);
						try (java.sql.ResultSet chkRs = chk.executeQuery()) {
							if (!chkRs.next()) {
								pushSlotNotification(agentId, "SHIFT_STARTING",
										"⏰ Time to start your " + slotType + " shift!",
										"Your shift window is open. Tap Start Shift to go online.", "🟢", "green",
										slotId);
							}
						}
					} catch (Exception ne) {
						log.warning("SHIFT_STARTING notif: " + ne.getMessage());
					}
				}
				return windowOpen;
			}
		}
	}

	/**
	 * BUG-12 FIX: FIELD() ordering now includes all 7 slot types in chronological
	 * order. BUG-F FIX: Also scans yesterday's NIGHT slot in the post-midnight
	 * window.
	 *
	 * FIX-NEXT-SLOT: The original code did: if
	 * (LocalTime.now().isAfter(startTime.plusMinutes(5))) return -1; For a NIGHT
	 * slot (startTime = 22:00) this check fired any time after 22:05, meaning once
	 * the shift was 5 minutes old, findNextAvailableSlot() always returned -1 — the
	 * agent could never get the next-slot-ID after their NIGHT shift started. Also
	 * for MIDNIGHT/EARLY_MORNING the raw LocalTime comparison ignored the date
	 * dimension entirely. FIX: Delegate to ShiftWindowValidator.isShiftWindowOpen()
	 * which uses epoch-ms arithmetic and handles all overnight crossings correctly.
	 */
	public int findNextAvailableSlot(int agentId) throws SQLException {
		String sql = "SELECT slot_id, slot_type, slot_date FROM delivery_slots " + "WHERE agent_id = ? "
				+ "  AND ( slot_date = CURDATE() " + "        OR ( slot_type = 'NIGHT' "
				+ "             AND slot_date = DATE_SUB(CURDATE(), INTERVAL 1 DAY) "
				+ "             AND TIME(NOW()) < '02:00:00' ) ) " + "  AND status = 'BOOKED' " + "ORDER BY "
				+ "  FIELD(slot_type, 'MIDNIGHT','EARLY_MORNING','AM','PM','EVENING','FULL_DAY','NIGHT') ASC "
				+ "LIMIT 1";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, agentId);
			try (ResultSet rs = ps.executeQuery()) {
				if (!rs.next()) {
					return -1;
				}
				int nextSlotId = rs.getInt("slot_id");
				String slotType = rs.getString("slot_type");
				Date dbDate = rs.getDate("slot_date");
				if (dbDate == null) {
					return -1;
				}
				// FIX: use ShiftWindowValidator instead of raw LocalTime comparison.
				// This correctly handles NIGHT (22:00-02:00+1), MIDNIGHT, EARLY_MORNING.
				if (!ShiftWindowValidator.isShiftWindowOpen(slotType, dbDate.toLocalDate(),
						java.time.ZoneId.systemDefault())) {
					return -1;
				}
				return nextSlotId;
			}
		}
	}

	public int releaseAgentIfSlotDoneV2(int slotId, int agentId) throws SQLException {
		if (!isSlotSafeToComplete(slotId)) {
			return -2;
		}

		conn.setAutoCommit(false);
		try {
			String completeSlot = "UPDATE delivery_slots " + "SET status='COMPLETED', shift_ended_at=NOW() "
					+ "WHERE slot_id=? AND agent_id=? " + "AND status IN ('ACTIVE','ON_BREAK','BOOKED','INACTIVE')";
			try (PreparedStatement ps = conn.prepareStatement(completeSlot)) {
				ps.setInt(1, slotId);
				ps.setInt(2, agentId);
				ps.executeUpdate();
			}

			// BUG-02 context: release agent in users table so they can book next slot
			String releaseAgent = "UPDATE users SET status='Active' WHERE id=? AND role='delivery'";
			try (PreparedStatement ps = conn.prepareStatement(releaseAgent)) {
				ps.setInt(1, agentId);
				ps.executeUpdate();
			}

			updateBookingStatus(slotId, "Completed");
			conn.commit();

			log.info("releaseAgentIfSlotDoneV2: slot #" + slotId + " completed, agent #" + agentId + " released.");

			// Credit earnings outside transaction (failure doesn't roll back completion)
			calculateAndCreditEarnings(slotId, agentId);

			return findNextAvailableSlot(agentId);

		} catch (Exception e) {
			conn.rollback();
			throw e;
		} finally {
			conn.setAutoCommit(true);
		}
	}

	public boolean isSlotSafeToComplete(int slotId) throws SQLException {
		if (!isSlotFullyComplete(slotId)) {
			return false;
		}
		String codCheck = "SELECT COUNT(*) FROM orders " + "WHERE slot_id = ? " + "  AND payment_method = 'COD' "
				+ "  AND status = 'Delivered' " + "  AND cod_deposited = 0";
		try (PreparedStatement ps = conn.prepareStatement(codCheck)) {
			ps.setInt(1, slotId);
			try (ResultSet rs = ps.executeQuery()) {
				if (rs.next() && rs.getInt(1) > 0) {
					log.warning("isSlotSafeToComplete: slot #" + slotId + " has undeposited COD orders.");
					return false;
				}
			}
		}
		return true;
	}

	private boolean isSlotFullyComplete(int slotId) throws SQLException {
		// BUG FIX: The original condition "total > 0 && total == done" returned
		// false when total==0 (agent had an empty shift with no orders assigned).
		// This caused releaseAgentIfSlotDoneV2 to return -2 and the UI showed:
		// "Cannot end shift. Outstanding active shipments remaining."
		// even though PENDING=0, IN TRANSIT=0, DELIVERED=0 (confirmed in screenshot).
		//
		// FIX: A slot with ZERO orders is trivially complete — agent can always end.
		// A slot WITH orders is complete only when NONE are still in progress
		// (Assigned / Pending / Picked Up / Out for Delivery).
		String sql = "SELECT " + "  COUNT(*) AS total, "
				+ "  SUM(CASE WHEN status IN ('Picked Up','Out for Delivery','Assigned','Pending') "
				+ "      THEN 1 ELSE 0 END) AS in_progress " + "FROM orders WHERE slot_id=?";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, slotId);
			try (ResultSet rs = ps.executeQuery()) {
				if (rs.next()) {
					int inProgress = rs.getInt("in_progress");
					// Zero orders OR all orders terminal → slot is complete
					return inProgress == 0;
				}
			}
		}
		return true; // safe fallback: don't block agent if query fails
	}

	public boolean releaseAgentIfSlotDone(int slotId, int agentId) throws SQLException {
		if (!isSlotFullyComplete(slotId)) {
			return false;
		}
		conn.setAutoCommit(false);
		try {
			String completeSlot = "UPDATE delivery_slots " + "SET status='COMPLETED', shift_ended_at=NOW() "
					+ "WHERE slot_id=? AND agent_id=? AND status IN ('ACTIVE','ON_BREAK','BOOKED','INACTIVE')";
			try (PreparedStatement ps = conn.prepareStatement(completeSlot)) {
				ps.setInt(1, slotId);
				ps.setInt(2, agentId);
				ps.executeUpdate();
			}
			String releaseAgent = "UPDATE users SET status='Active' WHERE id=? AND role='delivery'";
			try (PreparedStatement ps = conn.prepareStatement(releaseAgent)) {
				ps.setInt(1, agentId);
				ps.executeUpdate();
			}
			conn.commit();
			calculateAndCreditEarnings(slotId, agentId);
			return true;
		} catch (Exception e) {
			conn.rollback();
			throw e;
		} finally {
			conn.setAutoCommit(true);
		}
	}

	public boolean cancelPostPickupCodOrder(int orderId, int agentId, BigDecimal orderAmount, int slotId,
			AgentWalletDAO walletDao) throws SQLException {
		conn.setAutoCommit(false);
		try {
			String cancelOrder = "UPDATE orders SET status='Cancelled', cancelled_at=NOW() "
					+ "WHERE order_id=? AND status IN ('Picked Up','Out for Delivery')";
			try (PreparedStatement ps = conn.prepareStatement(cancelOrder)) {
				ps.setInt(1, orderId);
				if (ps.executeUpdate() == 0) {
					conn.rollback();
					return false;
				}
			}
			walletDao.releaseCodHold(agentId, orderId, orderAmount);
			String insertReturn = "INSERT INTO agent_wallet_transactions "
					+ "(agent_id, order_id, type, amount, balance_after, description, created_at) "
					+ "VALUES (?, ?, 'cod_return', ?, "
					+ "        (SELECT balance FROM agent_wallets WHERE agent_id=?), "
					+ "        CONCAT('COD return required — Order #', ?), NOW())";
			try (PreparedStatement ps = conn.prepareStatement(insertReturn)) {
				ps.setInt(1, agentId);
				ps.setInt(2, orderId);
				ps.setBigDecimal(3, orderAmount);
				ps.setInt(4, agentId);
				ps.setInt(5, orderId);
				ps.executeUpdate();
			}
			updateSlotCounters(slotId, "Out for Delivery", "Cancelled");
			conn.commit();
			return true;
		} catch (Exception e) {
			conn.rollback();
			throw e;
		} finally {
			conn.setAutoCommit(true);
		}
	}

	/**
	 * BUG-18 FIX: Returns long[] to avoid int truncation on large COD totals.
	 */
	public long[] getUndepositedCodSummary(int slotId) throws SQLException {
		String sql = "SELECT COUNT(*) AS cnt, COALESCE(SUM(total_amount), 0) AS total " + "FROM orders "
				+ "WHERE slot_id = ? " + "  AND payment_method = 'COD' " + "  AND status = 'Delivered' "
				+ "  AND cod_deposited = 0";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, slotId);
			try (ResultSet rs = ps.executeQuery()) {
				if (rs.next()) {
					return new long[] { rs.getLong("cnt"), rs.getLong("total") };
				}
			}
		}
		return new long[] { 0L, 0L };
	}

	/**
	 * Reconciles pending_count / active_count / delivered_count on a slot from the
	 * live orders table. Call this on every slot load (getTodaySlot /
	 * getTodaySlots) to self-heal any drift caused by direct DB edits, missed
	 * counter calls, or order status updates that bypassed updateSlotCounters().
	 *
	 * Mapping: pending <- orders.status IN ('Assigned','Pending') active <-
	 * orders.status IN ('Picked Up','Out for Delivery') delivered <- orders.status
	 * IN ('Delivered','Replaced','Refunded')
	 */
	public void syncSlotCountersFromOrders(int slotId) throws SQLException {
		if (slotId <= 0) {
			return;
		}
		String sql = "UPDATE delivery_slots ds " + "JOIN ( " + "  SELECT " + "    slot_id, "
				+ "    SUM(CASE WHEN status IN ('Assigned','Pending')             THEN 1 ELSE 0 END) AS pc, "
				+ "    SUM(CASE WHEN status IN ('Picked Up','Out for Delivery')   THEN 1 ELSE 0 END) AS ac, "
				+ "    SUM(CASE WHEN status IN ('Delivered','Replaced','Refunded') THEN 1 ELSE 0 END) AS dc "
				+ "  FROM orders WHERE slot_id = ? " + ") counts ON ds.slot_id = counts.slot_id "
				+ "SET ds.pending_count   = counts.pc, " + "    ds.active_count    = counts.ac, "
				+ "    ds.delivered_count = counts.dc " + "WHERE ds.slot_id = ?";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, slotId);
			ps.setInt(2, slotId);
			ps.executeUpdate();
		}
	}

	/**
	 * Reconcile counters for ALL slots of an agent on a given date. Called on page
	 * load in DeliverySlotServlet so the JSP always shows live counts without
	 * relying solely on event-driven increments.
	 */
	public void syncAllCountersForAgent(int agentId, LocalDate date) throws SQLException {
		String findSlots = "SELECT slot_id FROM delivery_slots WHERE agent_id=? AND slot_date=?";
		List<Integer> ids = new ArrayList<>();
		try (PreparedStatement ps = conn.prepareStatement(findSlots)) {
			ps.setInt(1, agentId);
			ps.setDate(2, java.sql.Date.valueOf(date));
			try (ResultSet rs = ps.executeQuery()) {
				while (rs.next()) {
					ids.add(rs.getInt(1));
				}
			}
		}
		for (int sid : ids) {
			syncSlotCountersFromOrders(sid);
		}
	}

	public void updateSlotCounters(int slotId, String fromStatus, String toStatus) throws SQLException {
		if (slotId <= 0) {
			return;
		}
		int pendingDelta = 0, activeDelta = 0, deliveredDelta = 0;
		if ("Assigned".equals(fromStatus) || "Pending".equals(fromStatus)) {
			pendingDelta--;
		} else if ("Picked Up".equals(fromStatus) || "Out for Delivery".equals(fromStatus)) {
			activeDelta--;
		} else if ("Delivered".equals(fromStatus)) {
			deliveredDelta--;
		}
		if ("Assigned".equals(toStatus) || "Pending".equals(toStatus)) {
			pendingDelta++;
		} else if ("Picked Up".equals(toStatus) || "Out for Delivery".equals(toStatus)) {
			activeDelta++;
		} else if ("Delivered".equals(toStatus)) {
			deliveredDelta++;
		}
		if (pendingDelta == 0 && activeDelta == 0 && deliveredDelta == 0) {
			return;
		}
		String sql = "UPDATE delivery_slots SET "
				+ "  pending_count   = GREATEST(0, CAST(pending_count   AS SIGNED) + ?), "
				+ "  active_count    = GREATEST(0, CAST(active_count    AS SIGNED) + ?), "
				+ "  delivered_count = GREATEST(0, CAST(delivered_count AS SIGNED) + ?) " + "WHERE slot_id = ?";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, pendingDelta);
			ps.setInt(2, activeDelta);
			ps.setInt(3, deliveredDelta);
			ps.setInt(4, slotId);
			ps.executeUpdate();
		}
		// Self-heal: recompute from actual orders after every delta update
		try {
			syncSlotCountersFromOrders(slotId);
		} catch (Exception ignored) {
		}
	}

	/**
	 * Upserts a row in agent_slot_bookings for the given slot. When a slot row is
	 * reused (UPDATE path in bookSlot) the ledger already has a row for that
	 * slot_id — so we UPDATE it back to 'Booked' + fresh timestamps rather than
	 * inserting a duplicate, which would violate any unique key on (agent_id,
	 * slot_id) and also produce confusing history rows.
	 */
	public int persistBooking(int agentId, int slotId) throws SQLException {
		// Try to update an existing ledger row first
		String update = "UPDATE agent_slot_bookings " + "SET status='Booked', booked_at=NOW(), status_changed_at=NOW() "
				+ "WHERE agent_id=? AND slot_id=?";
		try (PreparedStatement ps = conn.prepareStatement(update)) {
			ps.setInt(1, agentId);
			ps.setInt(2, slotId);
			if (ps.executeUpdate() > 0) {
				// Row existed and was updated — return booking_id
				String sel = "SELECT booking_id FROM agent_slot_bookings WHERE agent_id=? AND slot_id=?";
				try (PreparedStatement ps2 = conn.prepareStatement(sel)) {
					ps2.setInt(1, agentId);
					ps2.setInt(2, slotId);
					try (ResultSet rs = ps2.executeQuery()) {
						return rs.next() ? rs.getInt(1) : slotId;
					}
				}
			}
		}
		// No existing row — fresh INSERT
		String insert = "INSERT INTO agent_slot_bookings "
				+ "(agent_id, slot_id, status, booked_at, status_changed_at) "
				+ "VALUES (?, ?, 'Booked', NOW(), NOW())";
		try (PreparedStatement ps = conn.prepareStatement(insert, Statement.RETURN_GENERATED_KEYS)) {
			ps.setInt(1, agentId);
			ps.setInt(2, slotId);
			ps.executeUpdate();
			try (ResultSet rs = ps.getGeneratedKeys()) {
				return rs.next() ? rs.getInt(1) : -1;
			}
		}
	}

	public boolean updateBookingStatus(int slotId, String newStatus) throws SQLException {
		String sql = "UPDATE agent_slot_bookings " + "SET status = ?, status_changed_at = NOW() WHERE slot_id = ?";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setString(1, newStatus);
			ps.setInt(2, slotId);
			return ps.executeUpdate() > 0;
		}
	}

	/**
	 * Returns full booking history for an agent, joined with agent_slot_bookings
	 * for accurate ledger status and timestamps. booking_status comes from
	 * agent_slot_bookings.status (the authoritative record); slot_status comes from
	 * delivery_slots.status (the operational record). Order counts are live from
	 * the delivery_slots counters (kept accurate by syncSlotCountersFromOrders).
	 */
	public List<Map<String, Object>> getBookingHistory(int agentId) throws SQLException {

		// REFACTORED: Removed legacy ds.slot_start and ds.slot_end selections to avoid
		// table column dependency
		String sql = "SELECT ds.slot_id, " + "       COALESCE(asb.booking_id, ds.slot_id)             AS booking_id, "
				+ "       ds.agent_id, " + "       UPPER(COALESCE(asb.status, ds.status))           AS booking_status, "
				+ "       ds.status                                         AS slot_status, " + "       ds.slot_type, "
				+ "       ds.slot_date, " + "       dz.zone_name, " + "       ds.max_orders, "
				+ "       ds.pending_count, " + "       ds.active_count, " + "       ds.delivered_count, "
				+ "       asb.booked_at                                     AS booked_at, "
				+ "       asb.status_changed_at                             AS status_changed_at, "
				+ "       ds.shift_started_at, " + "       ds.shift_ended_at, " + "       ds.cancelled_reason, "
				+ "       ds.window_start_at, " + "       ds.window_end_at " + "FROM delivery_slots ds "
				+ "JOIN delivery_zones dz ON ds.zone_id = dz.zone_id " + "LEFT JOIN agent_slot_bookings asb "
				+ "  ON asb.slot_id = ds.slot_id AND asb.agent_id = ds.agent_id " + "WHERE ds.agent_id = ? "
				+ "ORDER BY ds.slot_date DESC, ds.slot_id DESC";

		List<Map<String, Object>> rows = new ArrayList<>();
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, agentId);
			try (ResultSet rs = ps.executeQuery()) {
				while (rs.next()) {
					Map<String, Object> row = new LinkedHashMap<>();

					row.put("bookingId", rs.getInt("booking_id"));
					row.put("slotId", rs.getInt("slot_id"));
					row.put("bookingStatus", rs.getString("booking_status"));
					row.put("slotStatus", rs.getString("slot_status"));
					row.put("slotType", rs.getString("slot_type"));
					row.put("slotDate", rs.getDate("slot_date"));
					row.put("zoneName", rs.getString("zone_name"));
					row.put("maxOrders", rs.getInt("max_orders"));
					row.put("pendingCount", rs.getInt("pending_count"));
					row.put("activeCount", rs.getInt("active_count"));
					row.put("deliveredCount", rs.getInt("delivered_count"));
					row.put("bookedAt", rs.getTimestamp("booked_at"));
					row.put("statusChangedAt", rs.getTimestamp("status_changed_at"));
					row.put("shiftStartedAt", rs.getTimestamp("shift_started_at"));
					row.put("shiftEndedAt", rs.getTimestamp("shift_ended_at"));
					row.put("cancelledReason", rs.getString("cancelled_reason"));

					java.sql.Timestamp winStart = rs.getTimestamp("window_start_at");
					java.sql.Timestamp winEnd = rs.getTimestamp("window_end_at");

					row.put("windowStartAt", winStart);
					row.put("windowEndAt", winEnd);
					row.put("startEpochMs", winStart != null ? winStart.getTime() : 0L);
					row.put("endEpochMs", winEnd != null ? winEnd.getTime() : 0L);

					// ── BACKWARD COMPATIBILITY: Safely extract Time objects directly from absolute
					// datetimes ──
					if (winStart != null) {
						row.put("slotStart", java.sql.Time.valueOf(winStart.toLocalDateTime().toLocalTime()));
					} else {
						row.put("slotStart", null);
					}

					if (winEnd != null) {
						row.put("slotEnd", java.sql.Time.valueOf(winEnd.toLocalDateTime().toLocalTime()));
					} else {
						row.put("slotEnd", null);
					}

					rows.add(row);
				}
			}
		}
		return rows;
	}

	public List<Map<String, Object>> getOrdersForSlot(int slotId) throws SQLException {
		String sql = "SELECT o.order_id, o.status, o.payment_method, o.payment_status, "
				+ "  o.total_amount, o.cod_deposited, " + "  c.name AS customer_name, "
				+ "  CONCAT_WS(', ', ca.landmark_street, ca.city, ca.state, ca.country, ca.pincode) "
				+ "    AS delivery_address " + "FROM orders o " + "JOIN customers c ON o.customer_id = c.customer_id "
				+ "LEFT JOIN customer_address ca " + "  ON ca.customer_id = o.customer_id AND ca.is_default = 1 "
				+ "WHERE o.slot_id = ? " + "ORDER BY o.order_id DESC";
		List<Map<String, Object>> rows = new ArrayList<>();
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, slotId);
			try (ResultSet rs = ps.executeQuery()) {
				while (rs.next()) {
					Map<String, Object> row = new LinkedHashMap<>();
					row.put("orderId", rs.getInt("order_id"));
					row.put("status", rs.getString("status"));
					row.put("paymentMethod", rs.getString("payment_method"));
					row.put("paymentStatus", rs.getString("payment_status"));
					row.put("totalAmount", rs.getBigDecimal("total_amount"));
					row.put("codDeposited", rs.getBoolean("cod_deposited"));
					row.put("customerName", rs.getString("customer_name"));
					row.put("deliveryAddress", rs.getString("delivery_address"));
					rows.add(row);
				}
			}
		}
		return rows;
	}

	/**
	 * Returns the slot_id of the agent's operational slot on the given date. Only
	 * matches BOOKED / ACTIVE / ON_BREAK / INACTIVE slots — never returns a
	 * CANCELLED or EXPIRED slot_id (which would corrupt counter updates). If the
	 * agent has multiple slots, the ACTIVE/ON_BREAK one takes priority.
	 */
	public int getSlotId(int agentId, LocalDate date) throws SQLException {
		String sql = "SELECT slot_id FROM delivery_slots " + "WHERE agent_id=? AND slot_date=? "
				+ "AND status IN ('BOOKED','ACTIVE','ON_BREAK','INACTIVE') "
				+ "ORDER BY FIELD(status,'ACTIVE','ON_BREAK','BOOKED','INACTIVE') ASC LIMIT 1";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, agentId);
			ps.setDate(2, java.sql.Date.valueOf(date));
			try (ResultSet rs = ps.executeQuery()) {
				return rs.next() ? rs.getInt("slot_id") : -1;
			}
		}
	}

	// ─────────────────────────────────────────────────────────────────────────
	// HELPERS
	// ─────────────────────────────────────────────────────────────────────────

	private double getConfigValue(String key) throws SQLException {
		String sql = "SELECT config_value FROM incentive_config WHERE config_key=?";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setString(1, key);
			try (ResultSet rs = ps.executeQuery()) {
				return rs.next() ? rs.getDouble("config_value") : 0.0;
			}
		}
	}

	/**
	 * BUG-15 FIX: getMaxOrdersForSlotType now handles all 7 slot types.
	 */
	private int getMaxOrdersForSlotType(String slotType) throws SQLException {
		String key = switch (slotType) {
		case "EARLY_MORNING" -> "max_orders_early_morning";
		case "MIDNIGHT" -> "max_orders_midnight";
		case "AM" -> "max_orders_am";
		case "PM" -> "max_orders_pm";
		case "EVENING" -> "max_orders_evening";
		case "FULL_DAY" -> "max_orders_full_day";
		case "NIGHT" -> "max_orders_night";
		default -> "max_orders_am";
		};
		int val = (int) getConfigValue(key);
		return val > 0 ? val : 20; // sensible fallback if config missing
	}

	private boolean isSlotInSurgeZone(int slotId) throws SQLException {
		String sql = "SELECT dz.is_surge FROM delivery_slots ds "
				+ "JOIN delivery_zones dz ON ds.zone_id=dz.zone_id WHERE ds.slot_id=?";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, slotId);
			try (ResultSet rs = ps.executeQuery()) {
				return rs.next() && rs.getBoolean("is_surge");
			}
		}
	}

	private double getSurgeMultiplier(int slotId) throws SQLException {
		String sql = "SELECT dz.surge_multiplier FROM delivery_slots ds "
				+ "JOIN delivery_zones dz ON ds.zone_id=dz.zone_id WHERE ds.slot_id=?";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, slotId);
			try (ResultSet rs = ps.executeQuery()) {
				return rs.next() ? rs.getDouble("surge_multiplier") : 1.0;
			}
		}
	}

	// ─────────────────────────────────────────────────────────────────────────
	// MAPPERS
	// ─────────────────────────────────────────────────────────────────────────

	private DeliverySlot mapSlot(ResultSet rs) throws SQLException {

		DeliverySlot s = new DeliverySlot();
		s.setSlotId(rs.getInt("slot_id"));
		s.setAgentId(rs.getInt("agent_id"));
		s.setZoneId(rs.getInt("zone_id"));
		s.setSlotDate(rs.getDate("slot_date").toLocalDate());
		s.setSlotType(rs.getString("slot_type"));
		s.setStatus(rs.getString("status"));
		s.setMaxOrders(rs.getInt("max_orders"));

		s.setZoneName(rs.getString("zone_name"));

		// ── FIX-MAP-1 (CRITICAL — "Start Shift" button always disabled) ──────────
		// BUG: setStartEpochMs(ws.getTime()) and setEndEpochMs(we.getTime()) were
		// called directly here, which populates only the primitive epoch-ms fields.
		// The LocalDateTime fields windowStartAt / windowEndAt were NEVER set, so
		// s.getWindowStartAt() always returned null.
		//
		// In DeliverySlotServlet this caused:
		// if (s.getWindowStartAt() != null && s.getWindowEndAt() != null) {
		// canStart = ...; ← this block NEVER executed
		// }
		// → slotCanStartMap always contained false for every slot
		// → portalCanStartNow attribute was always false
		// → "Start Shift" button was permanently disabled regardless of time.
		//
		// FIX: Use setWindowStartAt / setWindowEndAt (the proper setters).
		// Those setters in DeliverySlot.java already auto-sync startEpochMs /
		// endEpochMs via atZone().toInstant().toEpochMilli(), so both the
		// LocalDateTime and epoch fields are kept in sync with a single call.
		try {
			java.sql.Timestamp ws = rs.getTimestamp("window_start_at");
			if (ws != null) {
				s.setWindowStartAt(ws.toLocalDateTime()); // FIX: was setStartEpochMs(ws.getTime())
			}
			java.sql.Timestamp we = rs.getTimestamp("window_end_at");
			if (we != null) {
				s.setWindowEndAt(we.toLocalDateTime()); // FIX: was setEndEpochMs(we.getTime())
			}
		} catch (SQLException ignored) {
		}
		// FIX-MAP-2: Removed duplicate s.setStatus() and s.setMaxOrders() that
		// were called a second time here (original lines ~1648-1649). These fields
		// are already set above from rs.getString("status") and
		// rs.getInt("max_orders").
		// The duplicates were harmless but confusing and set the same value twice.
		s.setSurge(rs.getBoolean("is_surge"));
		s.setSurgeMultiplier(rs.getDouble("surge_multiplier"));
		// ORDER COUNTERS — always read; keeps slot objects consistent for JSP display
		try {
			s.setPendingCount(rs.getInt("pending_count"));
		} catch (SQLException ignored) {
		}
		try {
			s.setActiveCount(rs.getInt("active_count"));
		} catch (SQLException ignored) {
		}
		try {
			s.setDeliveredCount(rs.getInt("delivered_count"));
		} catch (SQLException ignored) {
		}
		try {
			s.setTotalBreakMin(rs.getInt("total_break_min"));
		} catch (SQLException ignored) {
		}
		try {
			java.sql.Timestamp bs = rs.getTimestamp("break_start");
			s.setBreakStarted(bs != null);
			if (bs != null) {
				s.setBreakStartEpoch(bs.getTime());
			}
		} catch (SQLException ignored) {
		}
		try {
			java.sql.Timestamp ss = rs.getTimestamp("shift_started_at");
			if (ss != null) {
				s.setShiftStartedAt(ss.toLocalDateTime());
			}
		} catch (SQLException ignored) {
		}
		return s;
	}

	public void pushSlotNotif(int agentId, String type, String title, String body, String icon, String colorClass,
			int refId) {
		pushSlotNotification(agentId, type, title, body, icon, colorClass, refId);
	}

	private void pushSlotNotification(int agentId, String type, String title, String body, String icon,
			String colorClass, int refId) {
		String sql = "INSERT INTO agent_notifications "
				+ "(agent_id,type,title,body,icon,color_class,ref_id) VALUES (?,?,?,?,?,?,?)";
		try (java.sql.PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, agentId);
			ps.setString(2, type);
			ps.setString(3, title);
			ps.setString(4, body);
			ps.setString(5, icon);
			ps.setString(6, colorClass);
			if (refId > 0) {
				ps.setInt(7, refId);
			} else {
				ps.setNull(7, java.sql.Types.INTEGER);
			}
			ps.executeUpdate();
		} catch (Exception e) {
			log.warning("pushSlotNotification non-fatal (" + type + "): " + e.getMessage());
		}
	}

	private DeliverySlot mapSlotAdmin(ResultSet rs) throws SQLException {
		DeliverySlot s = mapSlot(rs);
		s.setAgentName(rs.getString("agent_name"));
		s.setAgentPhone(rs.getString("agent_phone"));
		try {
			s.setTotalOrders(rs.getInt("total_orders"));
		} catch (SQLException ignored) {
		}
		try {
			s.setDeliveredCount(rs.getInt("delivered_count"));
		} catch (SQLException ignored) {
		}
		try {
			s.setOutForDeliveryCount(rs.getInt("out_for_delivery_count"));
		} catch (SQLException ignored) {
		}
		try {
			s.setPendingCount(rs.getInt("pending_count"));
		} catch (SQLException ignored) {
		}
		return s;
	}
}