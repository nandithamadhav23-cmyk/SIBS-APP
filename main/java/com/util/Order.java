package com.util;

import java.sql.Date;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.util.List;

public class Order {
	private int id;
	private int slotId;

	private int customerId;
	private Timestamp date;
	private String status;
	private String address;
	private String phone;

	private double subtotal;
	private double gst;
	private double tax;
	private double deliveryCharge;
	private Date deliverydate;
	private int otp;

	public int getOtp() {
		return otp;
	}

	public void setOtp(int otp) {
		this.otp = otp;
	}

	private double codCharge;
	private double totalAmount;
	private String CustomerName;
	private List<CartItem> items;
	private String CustomerEmail;
	private String paymentStatus;
	private String transactionId;
	private String deliveryUserName;
	private int snapAddressId;
	private String snapStreet;
	private String snapCity;
	private String snapState;
	private String snapCountry;
	private String snapDistrict;
	private String snapPincode;
	private Timestamp addressChangedAt;
	private int deliveryUserId;

	public int getDeliveryUserId() {
		return deliveryUserId;
	}

	public void setDeliveryUserId(int deliveryUserId) {
		this.deliveryUserId = deliveryUserId;
	}

	public String getDeliveryUserName() {
		return deliveryUserName;
	}

	public String getPhone() {
		return phone;
	}

	public void setPhone(String phone) {
		this.phone = phone;
	}

	public void setDeliveryUserName(String deliveryUserName) {
		this.deliveryUserName = deliveryUserName;
	}

	public String getPaymentStatus() {
		return paymentStatus;
	}

	public void setPaymentStatus(String v) {
		this.paymentStatus = v;
	}

	public String getTransactionId() {
		return transactionId;
	}

	public void setTransactionId(String v) {
		this.transactionId = v;
	}

	public Date getDeliveryDate() {
		return deliverydate;
	}

	public void setDeliveryDate(Date deliverydate) {
		this.deliverydate = deliverydate;
	}

	public String getCustomerName() {
		return CustomerName;
	}

	public void setCustomerName(String customerName) {
		CustomerName = customerName;
	}

	public String getCustomerEmail() {
		return CustomerEmail;
	}

	public void setCustomerEmail(String customerEmail) {
		CustomerEmail = customerEmail;
	}

	private String paymentMethod;

	public String getPaymentMethod() {
		return paymentMethod;
	}

	public void setPaymentMethod(String paymentMethod) {
		this.paymentMethod = paymentMethod;
	}

	public String getAddress() {
		return address;
	}

	public void setAddress(String address) {
		this.address = address;
	}

	public int getSlotId() {
		return slotId;
	}

	public void setSlotId(int slotId) {
		this.slotId = slotId;
	}

	public Order() {
	}

	public Order(int id, int customerId, Timestamp date, String status, double subtotal, double gst, double tax,
			double deliveryCharge, double codCharge, double totalAmount) {
		this.id = id;
		this.customerId = customerId;
		this.date = date;
		this.status = status;
		this.subtotal = subtotal;
		this.gst = gst;
		this.tax = tax;
		this.deliveryCharge = deliveryCharge;
		this.codCharge = codCharge;
		this.totalAmount = totalAmount;
	}

	// Getters and setters
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

	public Timestamp getDate() {
		return date;
	}

	public void setDate(Timestamp timestamp) {
		this.date = timestamp;
	}

	public String getStatus() {
		return status;
	}

	public void setStatus(String status) {
		this.status = status;
	}

	public double getSubtotal() {
		return subtotal;
	}

	public void setSubtotal(double subtotal) {
		this.subtotal = subtotal;
	}

	public double getGst() {
		return gst;
	}

	public void setGst(double gst) {
		this.gst = gst;
	}

	public double getTax() {
		return tax;
	}

	public void setTax(double tax) {
		this.tax = tax;
	}

	public double getDeliveryCharge() {
		return deliveryCharge;
	}

	public void setDeliveryCharge(double deliveryCharge) {
		this.deliveryCharge = deliveryCharge;
	}

	public double getCodCharge() {
		return codCharge;
	}

	public void setCodCharge(double codCharge) {
		this.codCharge = codCharge;
	}

	public double getTotalAmount() {
		return totalAmount;
	}

	public void setTotalAmount(double totalAmount) {
		this.totalAmount = totalAmount;
	}

	public List<CartItem> getItems() {
		return items;
	}

	public void setItems(List<CartItem> items) {
		this.items = items;
	}

	public String calculateAutoStatus() {
		if (status != null && !status.isEmpty()) {
			// Staff override always wins
			return status;
		}

		if (deliverydate != null) {
			LocalDate today = LocalDate.now();
			LocalDate deliveryDate = deliverydate.toLocalDate(); // convert from java.sql.Date

			if (today.isBefore(deliveryDate.minusDays(3))) {
				return "Packed";
			} else if (today.isBefore(deliveryDate)) {
				return "Shipped";
			} else if (today.isEqual(deliveryDate)) {
				return "Out for Delivery";
			} else if (today.isAfter(deliveryDate)) {
				return "Delivered";
			}
		}

		return "Pending"; // default fallback
	}

	private OrderReturn returnRequest; // Add this field

	public OrderReturn getReturnRequest() {
		return returnRequest;
	}

	public void setReturnRequest(OrderReturn returnRequest) {
		this.returnRequest = returnRequest;
	}

	public int getSnapAddressId() {
		return snapAddressId;
	}

	public void setSnapAddressId(int snapAddressId) {
		this.snapAddressId = snapAddressId;
	}

	public String getSnapStreet() {
		return snapStreet;
	}

	public void setSnapStreet(String snapStreet) {
		this.snapStreet = snapStreet;
	}

	public String getSnapCity() {
		return snapCity;
	}

	public void setSnapCity(String snapCity) {
		this.snapCity = snapCity;
	}

	public String getSnapState() {
		return snapState;
	}

	public void setSnapState(String snapState) {
		this.snapState = snapState;
	}

	public String getSnapCountry() {
		return snapCountry;
	}

	public void setSnapCountry(String snapCountry) {
		this.snapCountry = snapCountry;
	}

	public String getSnapDistrict() {
		return snapDistrict;
	}

	public void setSnapDistrict(String snapDistrict) {
		this.snapDistrict = snapDistrict;
	}

	public String getSnapPincode() {
		return snapPincode;
	}

	public void setSnapPincode(String snapPincode) {
		this.snapPincode = snapPincode;
	}

	public Timestamp getAddressChangedAt() {
		return addressChangedAt;
	}

	public void setAddressChangedAt(Timestamp addressChangedAt) {
		this.addressChangedAt = addressChangedAt;
	}

}
