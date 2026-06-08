package com.util;

import java.sql.Date;

public class Invoice {
	private int id;
	private int orderId;
	private Date issueDate;
	private String status;
	private String pdfLink;

	public Invoice(int id, int orderId, Date issueDate, String status, String pdfLink) {
		this.id = id;
		this.orderId = orderId;
		this.issueDate = issueDate;
		this.status = status;
		this.pdfLink = pdfLink;
	}

	// Getters and setters
	public int getId() {
		return id;
	}

	public int getOrderId() {
		return orderId;
	}

	public Date getIssueDate() {
		return issueDate;
	}

	public String getStatus() {
		return status;
	}

	public String getPdfLink() {
		return pdfLink;
	}

	public void setId(int id) {
		this.id = id;
	}

	public void setOrderId(int orderId) {
		this.orderId = orderId;
	}

	public void setIssueDate(Date issueDate) {
		this.issueDate = issueDate;
	}

	public void setStatus(String status) {
		this.status = status;
	}

	public void setPdfLink(String pdfLink) {
		this.pdfLink = pdfLink;
	}
}
