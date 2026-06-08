package com.util;

import java.time.LocalDateTime;

/**
 * One timeline event within an attendance session (PUNCH_IN, BREAK_START,
 * BREAK_END, PUNCH_OUT).
 */
public class AttendanceLogEntry {

	private long id;
	private long sessionId;
	private String username;
	private String eventType; // PUNCH_IN | BREAK_START | BREAK_END | PUNCH_OUT
	private LocalDateTime eventTime;
	private Long breakDurationMs; // only set on BREAK_END
	private String note;
	private LocalDateTime createdAt;

	// ── Constructors ────────────────────────────────────────────────
	public AttendanceLogEntry() {
	}

	public AttendanceLogEntry(long sessionId, String username, String eventType, LocalDateTime eventTime) {
		this.sessionId = sessionId;
		this.username = username;
		this.eventType = eventType;
		this.eventTime = eventTime;
	}

	// ── Getters & Setters ────────────────────────────────────────────
	public long getId() {
		return id;
	}

	public void setId(long id) {
		this.id = id;
	}

	public long getSessionId() {
		return sessionId;
	}

	public void setSessionId(long sessionId) {
		this.sessionId = sessionId;
	}

	public String getUsername() {
		return username;
	}

	public void setUsername(String username) {
		this.username = username;
	}

	public String getEventType() {
		return eventType;
	}

	public void setEventType(String eventType) {
		this.eventType = eventType;
	}

	public LocalDateTime getEventTime() {
		return eventTime;
	}

	public void setEventTime(LocalDateTime t) {
		this.eventTime = t;
	}

	public Long getBreakDurationMs() {
		return breakDurationMs;
	}

	public void setBreakDurationMs(Long breakDurationMs) {
		this.breakDurationMs = breakDurationMs;
	}

	public String getNote() {
		return note;
	}

	public void setNote(String note) {
		this.note = note;
	}

	public LocalDateTime getCreatedAt() {
		return createdAt;
	}

	public void setCreatedAt(LocalDateTime createdAt) {
		this.createdAt = createdAt;
	}

	/** Human-readable label for the event type */
	public String getEventLabel() {
		switch (eventType) {
		case "PUNCH_IN":
			return "Punched In";
		case "BREAK_START":
			return "Break Started";
		case "BREAK_END":
			return "Resumed Work";
		case "PUNCH_OUT":
			return "Punched Out";
		default:
			return eventType;
		}
	}

	/** CSS dot class matching the JS timeline in userDashboard.jsp */
	public String getDotClass() {
		switch (eventType) {
		case "PUNCH_IN":
			return "tl-dot-in";
		case "BREAK_START":
			return "tl-dot-break";
		case "BREAK_END":
			return "tl-dot-resume";
		case "PUNCH_OUT":
			return "tl-dot-out";
		default:
			return "";
		}
	}
}
