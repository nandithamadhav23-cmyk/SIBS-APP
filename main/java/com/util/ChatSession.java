package com.util;

import java.sql.Timestamp;

/**
 * Represents a single AI support chat session for a customer.
 */
public class ChatSession {

	private int sessionId;
	private int customerId;
	private String sessionToken; // UUID — sent as a cookie/hidden field
	private Timestamp startedAt;
	private Timestamp lastActiveAt;
	private boolean resolved;
	private String summary;

	public ChatSession() {
	}

	public ChatSession(int sessionId, int customerId, String sessionToken, Timestamp startedAt, Timestamp lastActiveAt,
			boolean resolved, String summary) {
		this.sessionId = sessionId;
		this.customerId = customerId;
		this.sessionToken = sessionToken;
		this.startedAt = startedAt;
		this.lastActiveAt = lastActiveAt;
		this.resolved = resolved;
		this.summary = summary;
	}

	// ── Getters ────────────────────────────────────────────────────────────
	public int getSessionId() {
		return sessionId;
	}

	public int getCustomerId() {
		return customerId;
	}

	public String getSessionToken() {
		return sessionToken;
	}

	public Timestamp getStartedAt() {
		return startedAt;
	}

	public Timestamp getLastActiveAt() {
		return lastActiveAt;
	}

	public boolean isResolved() {
		return resolved;
	}

	public String getSummary() {
		return summary;
	}

	// ── Setters ────────────────────────────────────────────────────────────
	public void setSessionId(int sessionId) {
		this.sessionId = sessionId;
	}

	public void setCustomerId(int customerId) {
		this.customerId = customerId;
	}

	public void setSessionToken(String token) {
		this.sessionToken = token;
	}

	public void setStartedAt(Timestamp startedAt) {
		this.startedAt = startedAt;
	}

	public void setLastActiveAt(Timestamp t) {
		this.lastActiveAt = t;
	}

	public void setResolved(boolean resolved) {
		this.resolved = resolved;
	}

	public void setSummary(String summary) {
		this.summary = summary;
	}

	@Override
	public String toString() {
		return "ChatSession{id=" + sessionId + ", customer=" + customerId + ", token=" + sessionToken + ", resolved="
				+ resolved + "}";
	}
}
