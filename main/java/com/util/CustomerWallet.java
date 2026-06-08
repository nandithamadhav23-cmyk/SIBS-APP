package com.util;

public class CustomerWallet {
	private int id;
	private int customerId;
	private double balance;
	private java.sql.Timestamp updatedAt;

	public int getId() {
		return id;
	}

	public void setId(int id) {
		this.id = id;
	}

	public int getCustomerId() {
		return customerId;
	}

	public void setCustomerId(int customerId) {
		this.customerId = customerId;
	}

	public double getBalance() {
		return balance;
	}

	public void setBalance(double balance) {
		this.balance = balance;
	}

	public java.sql.Timestamp getUpdatedAt() {
		return updatedAt;
	}

	public void setUpdatedAt(java.sql.Timestamp updatedAt) {
		this.updatedAt = updatedAt;
	}

	// getters and setters
}
