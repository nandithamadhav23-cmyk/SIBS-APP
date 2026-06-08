package com.util;

import java.sql.Timestamp;

/**
 * CustomerNotification — model for all customer-facing notification events.
 *
 * Notification Types (type column): ─────────────────────────────────
 * ORDER_PLACED — order confirmed after payment ORDER_CONFIRMED — staff approved
 * / confirmed the order ORDER_CANCELLED — order cancelled (by staff or
 * customer) DELIVERY_ASSIGNED — delivery agent assigned to the order
 * AGENT_PICKUP_CONFIRMED— agent has picked up the order (with agent details)
 * OUT_FOR_DELIVERY — package is out for delivery ORDER_DELIVERED — order
 * successfully delivered RETURN_REQUESTED — customer's return request received
 * RETURN_APPROVED — staff approved the return RETURN_REJECTED — staff rejected
 * the return PICKUP_SCHEDULED — return pickup agent assigned ITEM_PICKED_UP —
 * return item collected by agent REFUND_INITIATED — refund process started
 * REFUND_CREDITED — refund amount added to wallet PAYMENT_RECEIVED — payment
 * confirmed (UPI/Card/Wallet) PAYMENT_FAILED — payment failed WALLET_CREDITED —
 * wallet balance topped up WALLET_DEBITED — wallet balance used for order
 * NEW_PRODUCT — new product added in customer's interest category
 * PRODUCT_BACK_IN_STOCK — a wishlisted product is back in stock OFFER_ALERT —
 * limited-time offer on a product SLOT_REMINDER — delivery slot coming up soon
 * ACCOUNT_UPDATED — profile / password changed
 */
public class CustomerNotification {

	// ── Notification types ──────────────────────────────────────────────────
	public static final String ORDER_PLACED = "ORDER_PLACED";
	public static final String ORDER_CONFIRMED = "ORDER_CONFIRMED";
	public static final String ORDER_PACKED = "ORDER_PACKED"; // NEW — order packed at warehouse
	public static final String ORDER_SHIPPED = "ORDER_SHIPPED"; // NEW — order dispatched/shipped
	public static final String ORDER_CANCELLED = "ORDER_CANCELLED";
	public static final String DELIVERY_ASSIGNED = "DELIVERY_ASSIGNED";
	public static final String AGENT_PICKUP_CONFIRMED = "AGENT_PICKUP_CONFIRMED";
	public static final String OUT_FOR_DELIVERY = "OUT_FOR_DELIVERY";
	public static final String ORDER_DELIVERED = "ORDER_DELIVERED";
	public static final String DELIVERY_FAILED = "DELIVERY_FAILED"; // NEW — agent couldn't deliver
	public static final String RETURN_REQUESTED = "RETURN_REQUESTED";
	public static final String RETURN_APPROVED = "RETURN_APPROVED";
	public static final String RETURN_REJECTED = "RETURN_REJECTED";
	public static final String PICKUP_SCHEDULED = "PICKUP_SCHEDULED";
	public static final String RETURN_OUT_FOR_PICKUP = "RETURN_OUT_FOR_PICKUP"; // NEW — agent heading for pickup
	public static final String ITEM_PICKED_UP = "ITEM_PICKED_UP";
	public static final String REPLACEMENT_DISPATCH = "REPLACEMENT_DISPATCH"; // NEW — replacement being sent
	public static final String REPLACEMENT_DELIVERED = "REPLACEMENT_DELIVERED"; // NEW — replacement delivered
	public static final String REFUND_INITIATED = "REFUND_INITIATED";
	public static final String REFUND_CREDITED = "REFUND_CREDITED";
	public static final String PAYMENT_RECEIVED = "PAYMENT_RECEIVED";
	public static final String PAYMENT_FAILED = "PAYMENT_FAILED";
	public static final String WALLET_CREDITED = "WALLET_CREDITED";
	public static final String WALLET_DEBITED = "WALLET_DEBITED";
	public static final String NEW_PRODUCT = "NEW_PRODUCT";
	public static final String PRODUCT_BACK_IN_STOCK = "PRODUCT_BACK_IN_STOCK";
	public static final String OFFER_ALERT = "OFFER_ALERT";
	public static final String SLOT_REMINDER = "SLOT_REMINDER";
	public static final String ACCOUNT_UPDATED = "ACCOUNT_UPDATED";

	// ── Support Ticket types ─────────────────────────────────────────────────
	/** Customer submitted a new support ticket. */
	public static final String TICKET_RAISED = "TICKET_RAISED";
	/** Staff replied to the customer's ticket (waiting for customer response). */
	public static final String TICKET_REPLY = "TICKET_REPLY";
	/** Staff marked the ticket as resolved / closed. */
	public static final String TICKET_RESOLVED = "TICKET_RESOLVED";
	/** Staff re-opened or escalated a ticket back to the customer. */
	public static final String TICKET_UPDATED = "TICKET_UPDATED";

	// ── Fields ──────────────────────────────────────────────────────────────
	private int id;
	private int customerId;
	private String type;
	private String title;
	private String body;
	private String icon; // emoji icon
	private String colorClass; // CSS color class: green | blue | orange | red | purple | teal
	private Integer orderId; // nullable FK
	private Integer productId; // nullable FK
	private Integer agentId; // nullable — delivery agent FK (users.id)
	private String agentName; // snapshot: agent full name
	private String agentPhone; // snapshot: agent contact
	private String agentVehicle; // snapshot: vehicle type + number
	private Double refundAmount; // nullable — for refund notifications
	private boolean isRead;
	private boolean isDismissed;
	private String actionUrl; // deep-link target (e.g. CustomerOrders?orderId=5)
	private Timestamp createdAt;

	// ── Constructors ────────────────────────────────────────────────────────
	public CustomerNotification() {
	}

	/** Quick builder for order-level notifications without agent/product data. */
	public CustomerNotification(int customerId, String type, String title, String body, String icon, String colorClass,
			Integer orderId, String actionUrl) {
		this.customerId = customerId;
		this.type = type;
		this.title = title;
		this.body = body;
		this.icon = icon;
		this.colorClass = colorClass;
		this.orderId = orderId;
		this.actionUrl = actionUrl;
	}

	// ── Getters / Setters ───────────────────────────────────────────────────
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

	public String getType() {
		return type;
	}

	public void setType(String type) {
		this.type = type;
	}

	public String getTitle() {
		return title;
	}

	public void setTitle(String title) {
		this.title = title;
	}

	public String getBody() {
		return body;
	}

	public void setBody(String body) {
		this.body = body;
	}

	public String getIcon() {
		return icon;
	}

	public void setIcon(String icon) {
		this.icon = icon;
	}

	public String getColorClass() {
		return colorClass;
	}

	public void setColorClass(String colorClass) {
		this.colorClass = colorClass;
	}

	public Integer getOrderId() {
		return orderId;
	}

	public void setOrderId(Integer orderId) {
		this.orderId = orderId;
	}

	public Integer getProductId() {
		return productId;
	}

	public void setProductId(Integer productId) {
		this.productId = productId;
	}

	public Integer getAgentId() {
		return agentId;
	}

	public void setAgentId(Integer agentId) {
		this.agentId = agentId;
	}

	public String getAgentName() {
		return agentName;
	}

	public void setAgentName(String agentName) {
		this.agentName = agentName;
	}

	public String getAgentPhone() {
		return agentPhone;
	}

	public void setAgentPhone(String agentPhone) {
		this.agentPhone = agentPhone;
	}

	public String getAgentVehicle() {
		return agentVehicle;
	}

	public void setAgentVehicle(String v) {
		this.agentVehicle = v;
	}

	public Double getRefundAmount() {
		return refundAmount;
	}

	public void setRefundAmount(Double refundAmount) {
		this.refundAmount = refundAmount;
	}

	public boolean isRead() {
		return isRead;
	}

	public void setRead(boolean read) {
		this.isRead = read;
	}

	public boolean isDismissed() {
		return isDismissed;
	}

	public void setDismissed(boolean dismissed) {
		this.isDismissed = dismissed;
	}

	public String getActionUrl() {
		return actionUrl;
	}

	public void setActionUrl(String actionUrl) {
		this.actionUrl = actionUrl;
	}

	public Timestamp getCreatedAt() {
		return createdAt;
	}

	public void setCreatedAt(Timestamp createdAt) {
		this.createdAt = createdAt;
	}

	// ── Convenience helpers ─────────────────────────────────────────────────
	/** True when this notification carries agent contact details. */
	public boolean hasAgentDetails() {
		return agentName != null && !agentName.isBlank();
	}

	/** True when a refund amount is attached. */
	public boolean hasRefundAmount() {
		return refundAmount != null && refundAmount > 0;
	}
}
