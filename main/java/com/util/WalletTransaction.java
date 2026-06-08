package com.util;

/**
 * WalletTransaction — represents one row in wallet_transactions.
 *
 * Fields added vs original: status — success / pending / failed paymentMethod —
 * COD, UPI, Card, Wallet, etc. transactionId — Razorpay / gateway reference ID
 * (reference_id in DB) balanceAfter — wallet balance after this transaction
 * (immutable audit)
 *
 * Aliases added for JSP compatibility: getDate() — alias for getCreatedAt()
 * (JSP calls txn.getDate()) getType() — alias for getTxnType() (JSP calls
 * txn.getType())
 */
public class WalletTransaction {

	private int id;
	private int customerId;
	private int orderId;
	private double amount;

	// txn_type: credit | debit | refund | cashback | topup | adjustment
	private String txnType;

	private String description;

	// ── New fields ────────────────────────────────────────────────────────
	// status: success | pending | failed
	private String status;

	// payment_method: COD, UPI, Card, Wallet, Razorpay, System, etc.
	private String paymentMethod;

	// reference_id in DB — Razorpay payment/refund ID or internal ref
	private String transactionId;

	// balance_after in DB — wallet balance snapshotted when txn was written
	private double balanceAfter;
	// ─────────────────────────────────────────────────────────────────────

	private java.sql.Timestamp createdAt;

	// ── id ────────────────────────────────────────────────────────────────
	public int getId() {
		return id;
	}

	public void setId(int id) {
		this.id = id;
	}

	// ── customerId ───────────────────────────────────────────────────────
	public int getCustomerId() {
		return customerId;
	}

	public void setCustomerId(int customerId) {
		this.customerId = customerId;
	}

	// ── orderId ──────────────────────────────────────────────────────────
	public int getOrderId() {
		return orderId;
	}

	public void setOrderId(int orderId) {
		this.orderId = orderId;
	}

	// ── amount ───────────────────────────────────────────────────────────
	public double getAmount() {
		return amount;
	}

	public void setAmount(double amount) {
		this.amount = amount;
	}

	// ── txnType ──────────────────────────────────────────────────────────
	public String getTxnType() {
		return txnType;
	}

	public void setTxnType(String txnType) {
		this.txnType = txnType;
	}

	/** Alias used by CustomerWallet.jsp: txn.getType() */
	public String getType() {
		return txnType;
	}

	// ── description ──────────────────────────────────────────────────────
	public String getDescription() {
		return description;
	}

	public void setDescription(String description) {
		this.description = description;
	}

	// ── status ───────────────────────────────────────────────────────────
	public String getStatus() {
		return status;
	}

	public void setStatus(String status) {
		this.status = status;
	}

	// ── paymentMethod ────────────────────────────────────────────────────
	public String getPaymentMethod() {
		return paymentMethod;
	}

	public void setPaymentMethod(String paymentMethod) {
		this.paymentMethod = paymentMethod;
	}

	// ── transactionId (reference_id in DB) ───────────────────────────────
	public String getTransactionId() {
		return transactionId;
	}

	public void setTransactionId(String transactionId) {
		this.transactionId = transactionId;
	}

	// ── balanceAfter ─────────────────────────────────────────────────────
	public double getBalanceAfter() {
		return balanceAfter;
	}

	public void setBalanceAfter(double balanceAfter) {
		this.balanceAfter = balanceAfter;
	}

	// ── createdAt ────────────────────────────────────────────────────────
	public java.sql.Timestamp getCreatedAt() {
		return createdAt;
	}

	public void setCreatedAt(java.sql.Timestamp createdAt) {
		this.createdAt = createdAt;
	}

	/** Alias used by CustomerWallet.jsp: txn.getDate() */
	public java.sql.Timestamp getDate() {
		return createdAt;
	}
}
