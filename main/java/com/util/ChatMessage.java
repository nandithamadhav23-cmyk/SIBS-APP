package com.util;

import java.sql.Timestamp;

/**
 * Represents a single message (user or assistant) in a chat session.
 */
public class ChatMessage {

	private int messageId;
	private int sessionId;
	private String role; // "user" | "assistant"
	private String content; // plain text
	private String cardType; // nullable — e.g. "cancel_confirm"
	private String cardOrderId; // nullable — e.g. "ORD-7821"
	private Timestamp sentAt;

	public ChatMessage() {
	}

	public ChatMessage(int messageId, int sessionId, String role, String content, String cardType, String cardOrderId,
			Timestamp sentAt) {
		this.messageId = messageId;
		this.sessionId = sessionId;
		this.role = role;
		this.content = content;
		this.cardType = cardType;
		this.cardOrderId = cardOrderId;
		this.sentAt = sentAt;
	}

	// Convenience constructor for new outgoing messages
	public ChatMessage(int sessionId, String role, String content) {
		this.sessionId = sessionId;
		this.role = role;
		this.content = content;
	}

	// ── Getters ────────────────────────────────────────────────────────────
	public int getMessageId() {
		return messageId;
	}

	public int getSessionId() {
		return sessionId;
	}

	public String getRole() {
		return role;
	}

	public String getContent() {
		return content;
	}

	public String getCardType() {
		return cardType;
	}

	public String getCardOrderId() {
		return cardOrderId;
	}

	public Timestamp getSentAt() {
		return sentAt;
	}

	// ── Setters ────────────────────────────────────────────────────────────
	public void setMessageId(int messageId) {
		this.messageId = messageId;
	}

	public void setSessionId(int sessionId) {
		this.sessionId = sessionId;
	}

	public void setRole(String role) {
		this.role = role;
	}

	public void setContent(String content) {
		this.content = content;
	}

	public void setCardType(String cardType) {
		this.cardType = cardType;
	}

	public void setCardOrderId(String orderId) {
		this.cardOrderId = orderId;
	}

	public void setSentAt(Timestamp sentAt) {
		this.sentAt = sentAt;
	}

	/** Returns true if this message carries a rich UI card. */
	public boolean hasCard() {
		return cardType != null && !cardType.isBlank();
	}

	@Override
	public String toString() {
		return "ChatMessage{id=" + messageId + ", session=" + sessionId + ", role=" + role + ", card=" + cardType + "}";
	}
}
