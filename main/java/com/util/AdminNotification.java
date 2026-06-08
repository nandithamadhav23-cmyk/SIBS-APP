package com.util;

import java.sql.Timestamp;

public class AdminNotification {
	private int id;
	private Integer productId;
	private Integer orderId;
	private String eventType; // LOW_STOCK | NEW_ORDER | SYSTEM_ALERT
	private String title; // Short headline
	private String message; // Detailed message
	private String relatedEntity; // Product name or order ref
	private boolean isRead; // 0 = unread, 1 = read
	private boolean isDismissed; // 0 = visible, 1 = hidden
	private Timestamp createdAt;

	// --- Getters and Setters ---
	public int getId() {
		return id;
	}

	public void setId(int id) {
		this.id = id;
	}

	public Integer getProductId() {
		return productId;
	}

	public void setProductId(Integer productId) {
		this.productId = productId;
	}

	public Integer getOrderId() {
		return orderId;
	}

	public void setOrderId(Integer orderId) {
		this.orderId = orderId;
	}

	public String getEventType() {
		return eventType;
	}

	public void setEventType(String eventType) {
		this.eventType = eventType;
	}

	public String getTitle() {
		return title;
	}

	public void setTitle(String title) {
		this.title = title;
	}

	public String getMessage() {
		return message;
	}

	public void setMessage(String message) {
		this.message = message;
	}

	public String getRelatedEntity() {
		return relatedEntity;
	}

	public void setRelatedEntity(String relatedEntity) {
		this.relatedEntity = relatedEntity;
	}

	public boolean isRead() {
		return isRead;
	}

	public void setRead(boolean isRead) {
		this.isRead = isRead;
	}

	public boolean isDismissed() {
		return isDismissed;
	}

	public void setDismissed(boolean isDismissed) {
		this.isDismissed = isDismissed;
	}

	public Timestamp getCreatedAt() {
		return createdAt;
	}

	public void setCreatedAt(Timestamp createdAt) {
		this.createdAt = createdAt;
	}
}
