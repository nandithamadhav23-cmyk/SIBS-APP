package com.util;

import java.time.LocalTime;

/**
 * POJO representing one row in the office_shifts table.
 */
public class OfficeShift {

	private int id;
	private String shiftName;
	private LocalTime expectedLoginTime;
	private LocalTime expectedLogoutTime;
	private int lateGraceMinutes; // minutes after expectedLoginTime before LATE

	// ── Constructors ──────────────────────────────────────────────────────────

	public OfficeShift() {
	}

	public OfficeShift(int id, String shiftName, LocalTime expectedLoginTime, LocalTime expectedLogoutTime,
			int lateGraceMinutes) {
		this.id = id;
		this.shiftName = shiftName;
		this.expectedLoginTime = expectedLoginTime;
		this.expectedLogoutTime = expectedLogoutTime;
		this.lateGraceMinutes = lateGraceMinutes;
	}

	// ── Accessors ─────────────────────────────────────────────────────────────

	public int getId() {
		return id;
	}

	public void setId(int id) {
		this.id = id;
	}

	public String getShiftName() {
		return shiftName;
	}

	public void setShiftName(String shiftName) {
		this.shiftName = shiftName;
	}

	public LocalTime getExpectedLoginTime() {
		return expectedLoginTime;
	}

	public void setExpectedLoginTime(LocalTime t) {
		this.expectedLoginTime = t;
	}

	public LocalTime getExpectedLogoutTime() {
		return expectedLogoutTime;
	}

	public void setExpectedLogoutTime(LocalTime t) {
		this.expectedLogoutTime = t;
	}

	public int getLateGraceMinutes() {
		return lateGraceMinutes;
	}

	public void setLateGraceMinutes(int m) {
		this.lateGraceMinutes = m;
	}

	@Override
	public String toString() {
		return "OfficeShift{id=" + id + ", name='" + shiftName + "', login=" + expectedLoginTime + ", logout="
				+ expectedLogoutTime + ", grace=" + lateGraceMinutes + "m}";
	}
}
