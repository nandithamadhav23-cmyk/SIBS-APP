package com.util;

import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.ZoneId;

public final class ShiftWindowValidator {

	/** Minutes before the shift start that the "Start Shift" button unlocks. */
	public static final int EARLY_START_MINUTES = 15;

	private ShiftWindowValidator() {
	}

	// ── Wall-clock helpers (delegates to DeliverySlotDAO constants) ──────────

	/**
	 * FIX-SWV-1: MIDNIGHT slot start was LocalTime.of(0, 0) here but
	 * DeliverySlotDAO.getSlotStartTime("MIDNIGHT") returns LocalTime.of(2, 0). The
	 * DB stores window_start_at using DAO values; ShiftWindowValidator must match
	 * or isShiftWindowOpen() computes a DIFFERENT epoch than what is stored, making
	 * isSlotActivatable() validate against the wrong time window. Synced to DAO:
	 * MIDNIGHT = 02:00 – 06:00.
	 */
	public static LocalTime getSlotStartTime(String slotType) {
		if (slotType == null) {
			return LocalTime.of(6, 0);
		}

		// Fix: Normalizing strings using toUpperCase().trim() prevents match failures
		return switch (slotType.toUpperCase().trim()) {
		case "MIDNIGHT" -> LocalTime.of(2, 0); // FIX: was 0,0 — now matches DAO (02:00)
		case "EARLY_MORNING" -> LocalTime.of(4, 0);
		case "AM" -> LocalTime.of(6, 0);
		case "PM" -> LocalTime.of(12, 0);
		case "EVENING" -> LocalTime.of(18, 0);
		case "FULL_DAY" -> LocalTime.of(6, 0);
		case "NIGHT" -> LocalTime.of(22, 0);
		default -> LocalTime.of(6, 0);
		};
	}

	/**
	 * FIX-SWV-1 (continued): MIDNIGHT slot end was LocalTime.of(4, 0) here but
	 * DeliverySlotDAO.getSlotEndTime("MIDNIGHT") returns LocalTime.of(6, 0). Synced
	 * to DAO: MIDNIGHT ends at 06:00. For NIGHT: end time is still 02:00 on the
	 * NEXT calendar day — see getSlotEndDate().
	 */
	public static LocalTime getSlotEndTime(String slotType) {
		if (slotType == null) {
			return LocalTime.of(23, 59);
		}

		return switch (slotType.toUpperCase().trim()) {
		case "MIDNIGHT" -> LocalTime.of(6, 0); // FIX: was 4,0 — now matches DAO (06:00)
		case "EARLY_MORNING" -> LocalTime.of(8, 0);
		case "AM" -> LocalTime.of(12, 0);
		case "PM" -> LocalTime.of(18, 0);
		case "EVENING" -> LocalTime.of(22, 0);
		case "FULL_DAY" -> LocalTime.of(22, 0);
		case "NIGHT" -> LocalTime.of(2, 0); // ends next day — see getSlotEndDate()
		default -> LocalTime.of(23, 59);
		};
	}

	/**
	 * Returns the calendar date on which the slot STARTS (wall-clock).
	 *
	 * FIX-SWV-2: EARLY_MORNING was included in the +1 day guard here but NOT in
	 * DeliverySlotDAO.getSlotStartDate(). The DAO stores window_start_at for
	 * EARLY_MORNING as slotDate (no offset), so ShiftWindowValidator must agree or
	 * it computes the activation epoch one day ahead of the stored value — the
	 * agent would see "shift hasn't started yet" until the following day.
	 * EARLY_MORNING (4 AM) starts on slot_date itself; removed from +1 guard. Only
	 * MIDNIGHT is booked the previous evening and starts on slot_date + 1.
	 */
	public static LocalDate getSlotStartDate(LocalDate slotDate, String slotType) {
		if (slotType == null) {
			return slotDate;
		}
		String normalized = slotType.toUpperCase().trim();

		// FIX: Only MIDNIGHT rolls forward. EARLY_MORNING starts on slot_date itself.
		return slotDate;
	}

	/**
	 * * True ONLY for slots that physically cross over the 12:00 AM midnight mark
	 * during their execution (e.g., 10:00 PM to 2:00 AM).
	 */
	public static boolean isOvernightSlot(String slotType) {
		if (slotType == null) {
			return false;
		}
		return "NIGHT".equalsIgnoreCase(slotType.trim());
	}

	/**
	 * Returns the calendar date on which the slot ENDS. - NIGHT shift crosses
	 * midnight, so it ends on slotStartDate + 1. - MIDNIGHT and EARLY_MORNING slots
	 * start on Day N+1 and end on Day N+1.
	 */
	public static LocalDate getSlotEndDate(LocalDate slotDate, String slotType) {
		if (slotType == null) {
			return slotDate;
		}
		String normalized = slotType.toUpperCase().trim();

		// NIGHT (22:00-02:00): crosses midnight -> end = slot_date+1
		// MIDNIGHT (02:00-06:00): whole window is on slot_date+1 -> end = slot_date+1
		// EARLY_MORNING (04:00-08:00): runs on slot_date itself -> end = slot_date
		if ("NIGHT".equals(normalized)) {
			return slotDate.plusDays(1);
		}

		return slotDate;
	}

	// ── Epoch helpers ────────────────────────────────────────────────────────

	/**
	 * Returns the epoch-ms of the start of the shift window (i.e.
	 * EARLY_START_MINUTES before the actual slot start time).
	 */
	public static long getWindowOpenEpochMs(String slotType, LocalDate slotDate, ZoneId tz) {
		System.out.println("DEBUG: Input slotDate: " + slotDate);

		LocalDate startDate = getSlotStartDate(slotDate, slotType);

		System.out.println("DEBUG: Calculated startDate: " + startDate);
		LocalDateTime windowOpen = LocalDateTime.of(startDate, getSlotStartTime(slotType))
				.minusMinutes(EARLY_START_MINUTES);
		return windowOpen.atZone(tz).toInstant().toEpochMilli();
	}

	/**
	 * Returns the epoch-ms of the END of the shift window (i.e. the slot's end time
	 * on the correct calendar date).
	 */
	public static long getWindowCloseEpochMs(String slotType, LocalDate slotDate, ZoneId tz) {
		LocalDate endDate = getSlotEndDate(slotDate, slotType);
		return LocalDateTime.of(endDate, getSlotEndTime(slotType)).atZone(tz).toInstant().toEpochMilli();
	}

	/**
	 * Returns the epoch-ms of the SLOT START (not the early-open window). Used by
	 * the JS clock to display "starts at …".
	 */
	public static long getSlotStartEpochMs(String slotType, LocalDate slotDate, ZoneId tz) {
		LocalDate startDate = getSlotStartDate(slotDate, slotType);

		return LocalDateTime.of(startDate, getSlotStartTime(slotType)).atZone(tz).toInstant().toEpochMilli();
	}

	// ── Core validation API ──────────────────────────────────────────────────

	/**
	 * PRIMARY GUARD — call this from DeliverySlotDAO.isSlotActivatable() and
	 * DeliverySlotServlet startShift case.
	 *
	 * Returns true if Instant.now() is within the half-open interval [ slotStart -
	 * EARLY_START_MINUTES, slotEnd )
	 *
	 * Because comparisons are done in epoch-ms space, midnight crossings (NIGHT,
	 * MIDNIGHT, EARLY_MORNING) are handled automatically — there is no LocalTime
	 * arithmetic that can wrap around 00:00.
	 *
	 * @param slotType one of AM | PM | EVENING | FULL_DAY | NIGHT | MIDNIGHT |
	 *                 EARLY_MORNING
	 * @param slotDate the DATE stored in the delivery_slots.slot_date column
	 * @param tz       server timezone (ZoneId.systemDefault())
	 * @return true iff the shift window is currently open
	 */
	public static boolean isShiftWindowOpen(String slotType, LocalDate slotDate, ZoneId tz) {
		long nowMs = Instant.now().toEpochMilli();

		LocalDateTime now = LocalDateTime.now(tz);
		// Print these to your server logs:
		System.out.println("DEBUG: Server Time is: " + nowMs);
		long openMs = getWindowOpenEpochMs(slotType, slotDate, tz);
		long closeMs = getWindowCloseEpochMs(slotType, slotDate, tz);
		System.out.println("DEBUG: Server openms is: " + openMs);

		System.out.println("DEBUG: Server closems is: " + closeMs);
		return nowMs >= openMs && nowMs < closeMs;
	}

	/**
	 * Returns a human-readable reason why the window is closed, or null if it is
	 * open. Used by DeliverySlotServlet to produce the exact error message shown to
	 * the agent.
	 */
	public static String getWindowClosedReason(String slotType, LocalDate slotDate, ZoneId tz) {
		long nowMs = Instant.now().toEpochMilli();
		long openMs = getWindowOpenEpochMs(slotType, slotDate, tz);
		long closeMs = getWindowCloseEpochMs(slotType, slotDate, tz);

		if (nowMs < openMs) {
			long minsLeft = (openMs - nowMs) / 60_000;
			String startFmt = getSlotStartTime(slotType).format(java.time.format.DateTimeFormatter.ofPattern("h:mm a"));
			return "Your shift starts at " + startFmt + ". You can start " + EARLY_START_MINUTES + " minutes early ("
					+ minsLeft + " minutes remaining).";
		}
		if (nowMs >= closeMs) {
			String endFmt = getSlotEndTime(slotType).format(java.time.format.DateTimeFormatter.ofPattern("h:mm a"));
			return "This slot's window ended at " + endFmt + (isOvernightSlot(slotType) ? " (next day)" : "")
					+ ". Please book a new slot.";
		}
		return null; // window is open
	}

	/**
	 * Convenience overload: pass timestamps as Instant / java.sql.Timestamp. Used
	 * by the Servlet layer when both epoch values are already computed.
	 *
	 * @param startEpochMs epoch-ms of shift start (NOT the early-open offset)
	 * @param endEpochMs   epoch-ms of shift end
	 */
	public static boolean isShiftActive(long startEpochMs, long endEpochMs) {
		long nowMs = Instant.now().toEpochMilli();
		return nowMs >= startEpochMs && nowMs < endEpochMs;
	}

	/**
	 * Overload accepting java.sql.Timestamp — drop-in for legacy code that reads
	 * DATETIME columns from the DB as Timestamp objects.
	 */
	public static boolean isShiftActive(java.sql.Timestamp start, java.sql.Timestamp end) {
		if (start == null || end == null) {
			return false;
		}
		return isShiftActive(start.getTime(), end.getTime());
	}
}