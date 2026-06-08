package com.util;

import java.sql.Timestamp;

public class StaffNotification {

	private int id;
	private int orderId;
	private String paymentMethod; // "COD" | "UPI" | "Card"
	private String paymentStatus; // "PENDING_COD" | "PAID"
	private double grandTotal;

	// Customer snapshot
	private String customerName;
	private String customerEmail;
	private String customerPhone;

	// Items as a pre-formatted multi-line string
	private String itemsSummary;

	// Staff action hint
	private String actionRequired;

	// Lifecycle
	private boolean read;
	private boolean dismissed;
	private Timestamp createdAt;

	public StaffNotification() {
	}

	public StaffNotification(int orderId, String paymentMethod, String paymentStatus, double grandTotal,
			String customerName, String customerEmail, String customerPhone, String itemsSummary,
			String actionRequired) {
		this.orderId = orderId;
		this.paymentMethod = paymentMethod;
		this.paymentStatus = paymentStatus;
		this.grandTotal = grandTotal;
		this.customerName = customerName;
		this.customerEmail = customerEmail;
		this.customerPhone = customerPhone;
		this.itemsSummary = itemsSummary;
		this.actionRequired = actionRequired;
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

	public void setOrderId(int v) {
		this.orderId = v;
	}

	public String getPaymentMethod() {
		return paymentMethod;
	}

	public void setPaymentMethod(String v) {
		this.paymentMethod = v;
	}

	public String getPaymentStatus() {
		return paymentStatus;
	}

	public void setPaymentStatus(String v) {
		this.paymentStatus = v;
	}

	public double getGrandTotal() {
		return grandTotal;
	}

	public void setGrandTotal(double v) {
		this.grandTotal = v;
	}

	public String getCustomerName() {
		return customerName;
	}

	public void setCustomerName(String v) {
		this.customerName = v;
	}

	public String getCustomerEmail() {
		return customerEmail;
	}

	public void setCustomerEmail(String v) {
		this.customerEmail = v;
	}

	public String getCustomerPhone() {
		return customerPhone;
	}

	public void setCustomerPhone(String v) {
		this.customerPhone = v;
	}

	public String getItemsSummary() {
		return itemsSummary;
	}

	public void setItemsSummary(String v) {
		this.itemsSummary = v;
	}

	public String getActionRequired() {
		return actionRequired;
	}

	public void setActionRequired(String v) {
		this.actionRequired = v;
	}

	public boolean isRead() {
		return read;
	}

	public void setRead(boolean v) {
		this.read = v;
	}

	public boolean isDismissed() {
		return dismissed;
	}

	public void setDismissed(boolean v) {
		this.dismissed = v;
	}

	public Timestamp getCreatedAt() {
		return createdAt;
	}

	public void setCreatedAt(Timestamp v) {
		this.createdAt = v;
	}

	/** True when this is a COD order still awaiting cash collection. */
	public boolean isCod() {
		return "COD".equalsIgnoreCase(paymentMethod);
	}

	/** True when online payment is confirmed. */
	public boolean isPaid() {
		return "PAID".equalsIgnoreCase(paymentStatus);
	}
}
