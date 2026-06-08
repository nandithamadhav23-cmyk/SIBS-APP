package com.util;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * POJO for a delivery_slots row. Admin-facing fields (agentName, counts) are
 * populated only in admin queries.
 */
public class DeliverySlot {

	private int slotId;
	private int agentId;
	private int zoneId;
	private String zoneName;
	private LocalDate slotDate;
	private String slotType; // AM | PM | EVENING | FULL_DAY
	// ✅ ADDED NEW PRECISE WINDOWS: Representing the exact absolute database dates
	private LocalDateTime windowStartAt;
	private LocalDateTime windowEndAt;

	// Convenient tracking fields for epoch ms (used by ShiftWindowValidator)
	private long startEpochMs;
	private long endEpochMs;
	private int id;
	private String status; // BOOKED, ACTIVE, ON_BREAK, COMPLETED, INACTIVE

	// New Properties from your SQL/Audit
	private LocalDateTime breakStart;
	private Integer totalBreakMin = 0;
	private LocalDateTime shiftStartedAt;
	private LocalDateTime shiftEndedAt;

	// Helper for JS Epoch (BUG-7)
	private long breakStartEpoch;
	private boolean breakStarted;

	// Standard Getters and Setters
	public LocalDateTime getBreakStart() {
		return breakStart;
	}

	public void setBreakStart(LocalDateTime breakStart) {
		this.breakStart = breakStart;
	}

	public Integer getTotalBreakMin() {
		return totalBreakMin;
	}

	public void setTotalBreakMin(Integer totalBreakMin) {
		this.totalBreakMin = (totalBreakMin != null) ? totalBreakMin : 0;
	}

	public LocalDateTime getShiftStartedAt() {
		return shiftStartedAt;
	}

	public void setShiftStartedAt(LocalDateTime shiftStartedAt) {
		this.shiftStartedAt = shiftStartedAt;
	}

	public LocalDateTime getShiftEndedAt() {
		return shiftEndedAt;
	}

	public void setShiftEndedAt(LocalDateTime shiftEndedAt) {
		this.shiftEndedAt = shiftEndedAt;
	}

	public boolean isBreakStarted() {
		return breakStarted;
	}

	public void setBreakStarted(boolean breakStarted) {
		this.breakStarted = breakStarted;
	}

	public long getBreakStartEpoch() {
		return breakStartEpoch;
	}

	public void setBreakStartEpoch(long breakStartEpoch) {
		this.breakStartEpoch = breakStartEpoch;
	}

	private int maxOrders;
	private boolean isSurge;
	private double surgeMultiplier;

	// ── Admin-facing fields (populated only in admin queries) ─────────────────
	private String agentName;
	private String agentPhone;
	private int totalOrders;
	private int deliveredCount;
	private int outForDeliveryCount;
	private int pendingCount;
	private int cancelledCount;
	private int activeCount;

	// ── Derived helpers ───────────────────────────────────────────────────────

	public int getId() {
		return id;
	}

	public void setId(int id) {
		this.id = id;
	}

	public int getActiveCount() {
		return activeCount;
	}

	public void setActiveCount(int activeCount) {
		this.activeCount = activeCount;
	}

	/** Human-readable label shown in UI and JSP. */
	public String getSlotLabel() {
		return switch (slotType) {
		case "AM" -> "Morning  (6 AM – 12 PM)";
		case "PM" -> "Afternoon (12 PM – 6 PM)";
		case "EVENING" -> "Evening  (6 PM – 10 PM)";
		case "FULL_DAY" -> "Full Day (6 AM – 10 PM)";
		default -> slotType;
		};
	}

	/** Surge label for UI badge. */
	public String getSurgeLabel() {
		if (!isSurge) {
			return "";
		}
		int pct = (int) Math.round((surgeMultiplier - 1.0) * 100);
		return "+" + pct + "% surge";
	}

	/** Completion percentage for admin progress bars. */
	public int getCompletionPct() {
		if (totalOrders == 0) {
			return 0;
		}
		return (int) Math.round((deliveredCount * 100.0) / totalOrders);
	}

	// ── Getters / Setters ─────────────────────────────────────────────────────

	public int getSlotId() {
		return slotId;
	}

	public void setSlotId(int slotId) {
		this.slotId = slotId;
	}

	public int getAgentId() {
		return agentId;
	}

	public void setAgentId(int agentId) {
		this.agentId = agentId;
	}

	public int getZoneId() {
		return zoneId;
	}

	public void setZoneId(int zoneId) {
		this.zoneId = zoneId;
	}

	public String getZoneName() {
		return zoneName;
	}

	public void setZoneName(String zoneName) {
		this.zoneName = zoneName;
	}

	public LocalDate getSlotDate() {
		return slotDate;
	}

	public void setSlotDate(LocalDate slotDate) {
		this.slotDate = slotDate;
	}

	public String getSlotType() {
		return slotType;
	}

	public void setSlotType(String slotType) {
		this.slotType = slotType;
	}

	public String getStatus() {
		return status;
	}

	public void setStatus(String status) {
		this.status = status;
	}

	public int getMaxOrders() {
		return maxOrders;
	}

	public void setMaxOrders(int maxOrders) {
		this.maxOrders = maxOrders;
	}

	public boolean isSurge() {
		return isSurge;
	}

	public void setSurge(boolean surge) {
		isSurge = surge;
	}

	public double getSurgeMultiplier() {
		return surgeMultiplier;
	}

	public void setSurgeMultiplier(double m) {
		this.surgeMultiplier = m;
	}

	public String getAgentName() {
		return agentName;
	}

	public void setAgentName(String agentName) {
		this.agentName = agentName;
	}

	public String getAgentPhone() {
		return agentPhone;
	}

	public void setAgentPhone(String agentPhone) {
		this.agentPhone = agentPhone;
	}

	public int getTotalOrders() {
		return totalOrders;
	}

	public void setTotalOrders(int totalOrders) {
		this.totalOrders = totalOrders;
	}

	public int getDeliveredCount() {
		return deliveredCount;
	}

	public void setDeliveredCount(int c) {
		this.deliveredCount = c;
	}

	public int getOutForDeliveryCount() {
		return outForDeliveryCount;
	}

	public void setOutForDeliveryCount(int c) {
		this.outForDeliveryCount = c;
	}

	public int getPendingCount() {
		return pendingCount;
	}

	public void setPendingCount(int c) {
		this.pendingCount = c;
	}

	public int getCancelledCount() {
		return cancelledCount;
	}

	public void setCancelledCount(int c) {
		this.cancelledCount = c;
	}

	public void setBreakStartEpoch(Long breakStartEpoch) {
		this.breakStartEpoch = breakStartEpoch;
	}

	public LocalDateTime getWindowStartAt() {
		return windowStartAt;
	}

	public void setWindowStartAt(LocalDateTime windowStartAt) {
		this.windowStartAt = windowStartAt;
		if (windowStartAt != null) {
			// Automatically keep your epoch tracking variables in perfect sync
			this.startEpochMs = windowStartAt.atZone(java.time.ZoneId.systemDefault()).toInstant().toEpochMilli();
		}
	}

	public LocalDateTime getWindowEndAt() {
		return windowEndAt;
	}

	public void setWindowEndAt(LocalDateTime windowEndAt) {
		this.windowEndAt = windowEndAt;
		if (windowEndAt != null) {
			this.endEpochMs = windowEndAt.atZone(java.time.ZoneId.systemDefault()).toInstant().toEpochMilli();
		}
	}

	public long getStartEpochMs() {
		return startEpochMs;
	}

	public void setStartEpochMs(long startEpochMs) {
		this.startEpochMs = startEpochMs;
	}

	public long getEndEpochMs() {
		return endEpochMs;
	}

	public void setEndEpochMs(long endEpochMs) {
		this.endEpochMs = endEpochMs;
	}
	/**
	 * Maps to: s.setShiftStartedAt(ss.toLocalDateTime())
	 */

}
