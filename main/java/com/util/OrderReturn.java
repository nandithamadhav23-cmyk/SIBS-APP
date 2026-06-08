package com.util;

public class OrderReturn {
	private int id;
	private int orderId;
	private int customerId;
	private String reason;
	private String staffNotes;
	private String status; // Requested, Approved, Rejected, Picked, Refunded
	private Integer pickupAgentId;
	private int restockQty;
	private double refundAmount;
	private String refundMethod; // original, wallet, bank
	private String refundTransactionId;
	private java.sql.Timestamp requestedAt;
	private java.sql.Timestamp approvedAt;
	private java.sql.Timestamp pickedAt;
	private java.sql.Timestamp refundedAt;
	private String type; // 'Return' or 'Replace'
	private String photos; // Comma-separated file paths
	private String bankName;
	private String bankAccount;
	private String bankIfsc;

	public String getType() {
		return type;
	}

	public void setType(String type) {
		this.type = type;
	}

	public String getPhotos() {
		return photos;
	}

	public void setPhotos(String photos) {
		this.photos = photos;
	}

	public String getBankName() {
		return bankName;
	}

	public void setBankName(String bankName) {
		this.bankName = bankName;
	}

	public String getBankAccount() {
		return bankAccount;
	}

	public void setBankAccount(String bankAccount) {
		this.bankAccount = bankAccount;
	}

	public String getBankIfsc() {
		return bankIfsc;
	}

	public void setBankIfsc(String bankIfsc) {
		this.bankIfsc = bankIfsc;
	}

	public int getId() {
		return id;
	}

	public void setId(int id) {
		this.id = id;
	}

	public int getOrderId() {
		return orderId;
	}

	public void setOrderId(int orderId) {
		this.orderId = orderId;
	}

	public int getCustomerId() {
		return customerId;
	}

	public void setCustomerId(int customerId) {
		this.customerId = customerId;
	}

	public String getReason() {
		return reason;
	}

	public void setReason(String reason) {
		this.reason = reason;
	}

	public String getStaffNotes() {
		return staffNotes;
	}

	public void setStaffNotes(String staffNotes) {
		this.staffNotes = staffNotes;
	}

	public String getStatus() {
		return status;
	}

	public void setStatus(String status) {
		this.status = status;
	}

	public Integer getPickupAgentId() {
		return pickupAgentId;
	}

	public void setPickupAgentId(Integer pickupAgentId) {
		this.pickupAgentId = pickupAgentId;
	}

	public int getRestockQty() {
		return restockQty;
	}

	public void setRestockQty(int restockQty) {
		this.restockQty = restockQty;
	}

	public double getRefundAmount() {
		return refundAmount;
	}

	public void setRefundAmount(double refundAmount) {
		this.refundAmount = refundAmount;
	}

	public String getRefundMethod() {
		return refundMethod;
	}

	public void setRefundMethod(String refundMethod) {
		this.refundMethod = refundMethod;
	}

	public String getRefundTransactionId() {
		return refundTransactionId;
	}

	public void setRefundTransactionId(String refundTransactionId) {
		this.refundTransactionId = refundTransactionId;
	}

	public java.sql.Timestamp getRequestedAt() {
		return requestedAt;
	}

	public void setRequestedAt(java.sql.Timestamp requestedAt) {
		this.requestedAt = requestedAt;
	}

	public java.sql.Timestamp getApprovedAt() {
		return approvedAt;
	}

	public void setApprovedAt(java.sql.Timestamp approvedAt) {
		this.approvedAt = approvedAt;
	}

	public java.sql.Timestamp getPickedAt() {
		return pickedAt;
	}

	public void setPickedAt(java.sql.Timestamp pickedAt) {
		this.pickedAt = pickedAt;
	}

	public java.sql.Timestamp getRefundedAt() {
		return refundedAt;
	}

	public void setRefundedAt(java.sql.Timestamp refundedAt) {
		this.refundedAt = refundedAt;
	}

	// getters and setters
}
