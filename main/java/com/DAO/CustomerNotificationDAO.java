package com.DAO;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

import com.util.CustomerNotification;
import com.util.DBConnection;

/**
 * CustomerNotificationDAO
 * ─────────────────────────────────────────────────────────────────────────────
 * Full CRUD + polling helpers for the customer_notifications table.
 *
 * AUTO-SCHEMA: ensureTable() is called from CustomerNotificationServlet.init()
 * so the feature is zero-config — no separate migration script required.
 *
 * TABLE: customer_notifications
 * ┌────────────────────┬───────────────────────────────────────────────────┐ │
 * id │ INT AUTO_INCREMENT PK │ │ customer_id │ INT NOT NULL (FK
 * customers.customer_id) │ │ type │ VARCHAR(40) — see CustomerNotification
 * constants │ │ title │ VARCHAR(200) │ │ body │ VARCHAR(1000) │ │ icon │
 * VARCHAR(10) — emoji │ │ color_class │ VARCHAR(20) —
 * green|blue|orange|red|purple|teal │ │ order_id │ INT NULL │ │ product_id │
 * INT NULL │ │ agent_id │ INT NULL │ │ agent_name │ VARCHAR(120) NULL —
 * snapshot │ │ agent_phone │ VARCHAR(20) NULL — snapshot │ │ agent_vehicle │
 * VARCHAR(80) NULL — snapshot │ │ refund_amount │ DECIMAL(10,2) NULL │ │
 * action_url │ VARCHAR(300) NULL │ │ is_read │ TINYINT(1) DEFAULT 0 │ │
 * is_dismissed │ TINYINT(1) DEFAULT 0 │ │ created_at │ DATETIME DEFAULT
 * CURRENT_TIMESTAMP │
 * └────────────────────┴───────────────────────────────────────────────────┘
 */
public class CustomerNotificationDAO {

	private static final Logger log = Logger.getLogger(CustomerNotificationDAO.class.getName());

	// ── DDL ──────────────────────────────────────────────────────────────────

	private static final String CREATE_TABLE = """
			CREATE TABLE IF NOT EXISTS customer_notifications (
			  id            INT AUTO_INCREMENT PRIMARY KEY,
			  customer_id   INT          NOT NULL,
			  type          VARCHAR(40)  NOT NULL DEFAULT 'SYSTEM',
			  title         VARCHAR(200) NOT NULL,
			  body          VARCHAR(1000) DEFAULT NULL,
			  icon          VARCHAR(10)  DEFAULT '🔔',
			  color_class   VARCHAR(20)  DEFAULT 'blue',
			  order_id      INT          DEFAULT NULL,
			  product_id    INT          DEFAULT NULL,
			  agent_id      INT          DEFAULT NULL,
			  agent_name    VARCHAR(120) DEFAULT NULL,
			  agent_phone   VARCHAR(20)  DEFAULT NULL,
			  agent_vehicle VARCHAR(80)  DEFAULT NULL,
			  refund_amount DECIMAL(10,2) DEFAULT NULL,
			  action_url    VARCHAR(300) DEFAULT NULL,
			  is_read       TINYINT(1)   NOT NULL DEFAULT 0,
			  is_dismissed  TINYINT(1)   NOT NULL DEFAULT 0,
			  created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
			  INDEX idx_customer (customer_id, is_dismissed, created_at DESC),
			  INDEX idx_unread   (customer_id, is_read, is_dismissed)
			) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
			""";

	// ── Schema bootstrap ─────────────────────────────────────────────────────

	public void ensureTable() {
		try (Connection conn = DBConnection.getConnection(); Statement st = conn.createStatement()) {
			st.executeUpdate(CREATE_TABLE);
		} catch (Exception e) {
			log.warning("customer_notifications table init: " + e.getMessage());
		}
	}

	// ── INSERT ────────────────────────────────────────────────────────────────

	/**
	 * Guard insert: only inserts the notification if no notification with the same
	 * (customer_id, type, order_id) already exists and is undismissed.
	 *
	 * This solves the problem where re-triggering an order status update (e.g.
	 * re-assigning a delivery agent, retrying a dispatch) would insert duplicate
	 * ORDER_CONFIRMED / DELIVERY_ASSIGNED / etc. notifications.
	 *
	 * Returns the generated id on success, 0 if skipped (already exists), or -1 on
	 * error.
	 */
	public int insertIfNotExists(CustomerNotification n) {
		if (n.getOrderId() != null && n.getType() != null) {
			String checkSql = """
					SELECT COUNT(*) FROM customer_notifications
					WHERE customer_id = ? AND type = ? AND order_id = ? AND is_dismissed = 0
					""";
			try (Connection conn = DBConnection.getConnection();
					PreparedStatement ps = conn.prepareStatement(checkSql)) {
				ps.setInt(1, n.getCustomerId());
				ps.setString(2, n.getType());
				ps.setInt(3, n.getOrderId());
				try (ResultSet rs = ps.executeQuery()) {
					if (rs.next() && rs.getInt(1) > 0) {
						log.info("Skipping duplicate notification type=" + n.getType() + " orderId=" + n.getOrderId()
								+ " customerId=" + n.getCustomerId());
						return 0; // already exists — skip
					}
				}
			} catch (SQLException e) {
				log.log(Level.WARNING, "insertIfNotExists check failed", e);
				// fall through to insert anyway
			}
		}
		return insert(n);
	}

	/**
	 * Persists a new notification and returns the generated id, or -1 on error. BUG
	 * FIX: agent_vehicle was missing from the column list and parameter binding,
	 * causing it to always be NULL even when the factory methods set it.
	 */
	public int insert(CustomerNotification n) {
		String sql = """
				INSERT INTO customer_notifications
				  (customer_id, type, title, body, icon, color_class,
				   order_id, product_id, agent_id, agent_name, agent_phone,
				   agent_vehicle, refund_amount, action_url)
				VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
				""";
		try (Connection conn = DBConnection.getConnection();
				PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

			ps.setInt(1, n.getCustomerId());
			ps.setString(2, n.getType());
			ps.setString(3, n.getTitle());
			ps.setString(4, n.getBody());
			ps.setString(5, n.getIcon() != null ? n.getIcon() : "🔔");
			ps.setString(6, n.getColorClass() != null ? n.getColorClass() : "blue");
			setNullableInt(ps, 7, n.getOrderId());
			setNullableInt(ps, 8, n.getProductId());
			setNullableInt(ps, 9, n.getAgentId());
			ps.setString(10, n.getAgentName());
			ps.setString(11, n.getAgentPhone());
			ps.setString(12, n.getAgentVehicle()); // BUG FIX: was missing entirely
			if (n.getRefundAmount() != null) {
				ps.setDouble(13, n.getRefundAmount());
			} else {
				ps.setNull(13, Types.DECIMAL);
			}
			ps.setString(14, n.getActionUrl());

			ps.executeUpdate();
			try (ResultSet rs = ps.getGeneratedKeys()) {
				if (rs.next()) {
					return rs.getInt(1);
				}
			}
		} catch (SQLException e) {
			log.log(Level.SEVERE, "Failed to insert customer_notification", e);
		}
		return -1;
	}

	// ── READ ──────────────────────────────────────────────────────────────────

	/** All non-dismissed notifications for a customer, newest first. */
	public List<CustomerNotification> getAll(int customerId) {
		return query("""
				SELECT * FROM customer_notifications
				WHERE customer_id = ? AND is_dismissed = 0
				ORDER BY created_at DESC
				LIMIT 100
				""", customerId);
	}

	/** Unread, non-dismissed notifications only. */
	public List<CustomerNotification> getUnread(int customerId) {
		return query("""
				SELECT * FROM customer_notifications
				WHERE customer_id = ? AND is_read = 0 AND is_dismissed = 0
				ORDER BY created_at DESC
				""", customerId);
	}

	/** Count of unread, non-dismissed notifications (for badge polling). */
	public int countUnread(int customerId) {
		String sql = """
				SELECT COUNT(*) FROM customer_notifications
				WHERE customer_id = ? AND is_read = 0 AND is_dismissed = 0
				""";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, customerId);
			try (ResultSet rs = ps.executeQuery()) {
				if (rs.next()) {
					return rs.getInt(1);
				}
			}
		} catch (SQLException e) {
			log.log(Level.WARNING, "countUnread failed cid=" + customerId, e);
		}
		return 0;
	}

	/** Fetch a single notification by id (used after markRead to redirect). */
	public CustomerNotification getById(int id) {
		String sql = "SELECT * FROM customer_notifications WHERE id = ?";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, id);
			try (ResultSet rs = ps.executeQuery()) {
				if (rs.next()) {
					return map(rs);
				}
			}
		} catch (SQLException e) {
			log.log(Level.WARNING, "getById failed id=" + id, e);
		}
		return null;
	}

	// ── UPDATE ────────────────────────────────────────────────────────────────

	/** Mark a single notification as read. */
	public void markRead(int id) {
		exec("UPDATE customer_notifications SET is_read = 1 WHERE id = ?", id);
	}

	/** Mark all notifications for a customer as read in one statement. */
	public void markAllRead(int customerId) {
		String sql = """
				UPDATE customer_notifications
				SET is_read = 1
				WHERE customer_id = ? AND is_read = 0
				""";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, customerId);
			ps.executeUpdate();
		} catch (SQLException e) {
			log.log(Level.WARNING, "markAllRead failed cid=" + customerId, e);
		}
	}

	/** Soft-delete: hides a notification without destroying data. */
	public void dismiss(int id) {
		exec("UPDATE customer_notifications SET is_dismissed = 1 WHERE id = ?", id);
	}

	/** Hard-delete a single notification row. */
	public void delete(int id) {
		exec("DELETE FROM customer_notifications WHERE id = ?", id);
	}

	// ── FACTORY HELPERS ───────────────────────────────────────────────────────
	// Convenience methods called from servlets — build + insert in one call.

	/** ORDER_PLACED — fire after payment confirmation / COD placement. */
	public void notifyOrderPlaced(int customerId, int orderId, String itemsSummary, double grandTotal,
			String paymentMethod) {
		CustomerNotification n = new CustomerNotification();
		n.setCustomerId(customerId);
		n.setType(CustomerNotification.ORDER_PLACED);
		n.setTitle("Order placed successfully! 🎉");
		n.setBody(String.format("Your order #%d (₹%.2f via %s) has been placed. We'll confirm it shortly. Items: %s",
				orderId, grandTotal, paymentMethod, itemsSummary));
		n.setIcon("🛍️");
		n.setColorClass("green");
		n.setOrderId(orderId);
		n.setActionUrl("CustomerOrdersServlet?action=view&orderId=" + orderId);
		insertIfNotExists(n);
	}

	/** ORDER_CONFIRMED — staff approved the order. */
	public void notifyOrderConfirmed(int customerId, int orderId) {
		CustomerNotification n = new CustomerNotification();
		n.setCustomerId(customerId);
		n.setType(CustomerNotification.ORDER_CONFIRMED);
		n.setTitle("Order confirmed ✅");
		n.setBody(String.format(
				"Great news! Your order #%d has been approved by our team and is being prepared for dispatch.",
				orderId));
		n.setIcon("✅");
		n.setColorClass("green");
		n.setOrderId(orderId);
		n.setActionUrl("CustomerOrdersServlet?action=view&orderId=" + orderId);
		insertIfNotExists(n);
	}

	/** ORDER_CANCELLED — order cancelled by staff or customer. */
	public void notifyOrderCancelled(int customerId, int orderId, String reason) {
		CustomerNotification n = new CustomerNotification();
		n.setCustomerId(customerId);
		n.setType(CustomerNotification.ORDER_CANCELLED);
		n.setTitle("Order #" + orderId + " cancelled");
		n.setBody(String.format(
				"Your order #%d has been cancelled. Reason: %s. If any amount was deducted, a refund will be initiated.",
				orderId, reason));
		n.setIcon("❌");
		n.setColorClass("red");
		n.setOrderId(orderId);
		n.setActionUrl("CustomerOrdersServlet?action=view&orderId=" + orderId);
		insertIfNotExists(n);
	}

	/** DELIVERY_ASSIGNED — delivery agent assigned to the order. */
	/** DELIVERY_ASSIGNED — delivery agent assigned to the order. */
	public void notifyDeliveryAssigned(int customerId, int orderId, int agentId, String agentName, String agentPhone,
			String agentVehicle) {
		CustomerNotification n = new CustomerNotification();
		n.setCustomerId(customerId);
		n.setType(CustomerNotification.DELIVERY_ASSIGNED);
		n.setTitle("Delivery agent assigned 🚴");
		String vehicleInfo = (agentVehicle != null && !agentVehicle.isBlank()) ? " | Vehicle: " + agentVehicle : "";
		n.setBody(String.format(
				"A delivery agent has been assigned to your order #%d. "
						+ "%s will handle your delivery. You can reach them at %s.%s",
				orderId, agentName, agentPhone, vehicleInfo));
		n.setIcon("🚴");
		n.setColorClass("blue");
		n.setOrderId(orderId);
		n.setAgentId(agentId);
		n.setAgentName(agentName);
		n.setAgentPhone(agentPhone);
		n.setAgentVehicle(agentVehicle);
		n.setActionUrl("CustomerOrdersServlet?action=view&orderId=" + orderId);
		insertIfNotExists(n);
	}

	/** AGENT_PICKUP_CONFIRMED — agent confirmed pickup from warehouse. */
	public void notifyAgentPickupConfirmed(int customerId, int orderId, int agentId, String agentName,
			String agentPhone, String agentVehicle) {
		CustomerNotification n = new CustomerNotification();
		n.setCustomerId(customerId);
		n.setType(CustomerNotification.AGENT_PICKUP_CONFIRMED);
		n.setTitle("Your order is on the way! 📦");
		String vehicleInfo = (agentVehicle != null && !agentVehicle.isBlank()) ? " | Vehicle: " + agentVehicle : "";
		n.setBody(String.format("Your order #%d has been picked up by %s and is heading your way! Contact: %s%s",
				orderId, agentName, agentPhone, vehicleInfo));
		n.setIcon("📦");
		n.setColorClass("teal");
		n.setOrderId(orderId);
		n.setAgentId(agentId);
		n.setAgentName(agentName);
		n.setAgentPhone(agentPhone);
		n.setAgentVehicle(agentVehicle);
		n.setActionUrl("CustomerOrdersServlet?action=view&orderId=" + orderId);
		insertIfNotExists(n);
	}

	/** OUT_FOR_DELIVERY */
	public void notifyOutForDelivery(int customerId, int orderId, String agentName, String agentPhone) {
		CustomerNotification n = new CustomerNotification();
		n.setCustomerId(customerId);
		n.setType(CustomerNotification.OUT_FOR_DELIVERY);
		n.setTitle("Out for delivery 🛵");
		n.setBody(String.format(
				"Your order #%d is out for delivery! %s is on the way. Contact: %s. Please be available to receive it.",
				orderId, agentName, agentPhone));
		n.setIcon("🛵");
		n.setColorClass("orange");
		n.setOrderId(orderId);
		n.setAgentName(agentName);
		n.setAgentPhone(agentPhone);
		n.setActionUrl("CustomerOrdersServlet?action=view&orderId=" + orderId);
		insertIfNotExists(n);
	}

	/** ORDER_DELIVERED */
	public void notifyOrderDelivered(int customerId, int orderId) {
		CustomerNotification n = new CustomerNotification();
		n.setCustomerId(customerId);
		n.setType(CustomerNotification.ORDER_DELIVERED);
		n.setTitle("Order delivered! 🎊");
		n.setBody(String.format(
				"Your order #%d has been delivered successfully. We hope you enjoy your purchase! Not satisfied? You can raise a return request within 7 days.",
				orderId));
		n.setIcon("🎊");
		n.setColorClass("green");
		n.setOrderId(orderId);
		n.setActionUrl("CustomerOrdersServlet?action=view&orderId=" + orderId);
		insertIfNotExists(n);
	}

	/** RETURN_REQUESTED */
	public void notifyReturnRequested(int customerId, int orderId, String type) {
		CustomerNotification n = new CustomerNotification();
		n.setCustomerId(customerId);
		n.setType(CustomerNotification.RETURN_REQUESTED);
		n.setTitle(type + " request received 📋");
		n.setBody(String.format(
				"Your %s request for order #%d has been received. Our team will review it within 24–48 hours.",
				type.toLowerCase(), orderId));
		n.setIcon("📋");
		n.setColorClass("purple");
		n.setOrderId(orderId);
		n.setActionUrl("CustomerOrdersServlet?action=view&orderId=" + orderId);
		insertIfNotExists(n);
	}

	/** RETURN_APPROVED */
	public void notifyReturnApproved(int customerId, int orderId, String staffNote) {
		CustomerNotification n = new CustomerNotification();
		n.setCustomerId(customerId);
		n.setType(CustomerNotification.RETURN_APPROVED);
		n.setTitle("Return request approved ✅");
		n.setBody(String.format(
				"Your return request for order #%d has been approved. %s A pickup will be scheduled shortly.", orderId,
				staffNote != null && !staffNote.isBlank() ? "Staff note: " + staffNote + "." : ""));
		n.setIcon("✅");
		n.setColorClass("green");
		n.setOrderId(orderId);
		n.setActionUrl("CustomerOrdersServlet?action=view&orderId=" + orderId);
		insertIfNotExists(n);
	}

	/** RETURN_REJECTED */
	public void notifyReturnRejected(int customerId, int orderId, String reason) {
		CustomerNotification n = new CustomerNotification();
		n.setCustomerId(customerId);
		n.setType(CustomerNotification.RETURN_REJECTED);
		n.setTitle("Return request rejected");
		n.setBody(String.format(
				"Unfortunately your return request for order #%d has been rejected. Reason: %s. Contact our help desk for more info.",
				orderId, reason));
		n.setIcon("🚫");
		n.setColorClass("red");
		n.setOrderId(orderId);
		n.setActionUrl("HelpDeskServlet");
		insertIfNotExists(n);
	}

	/** PICKUP_SCHEDULED — return pickup agent assigned. */
	/** PICKUP_SCHEDULED — return pickup agent assigned. */
	public void notifyPickupScheduled(int customerId, int orderId, String agentName, String agentPhone,
			String agentVehicle) {
		CustomerNotification n = new CustomerNotification();
		n.setCustomerId(customerId);
		n.setType(CustomerNotification.PICKUP_SCHEDULED);
		n.setTitle("Return pickup scheduled 🔄");
		String vehicleInfo = (agentVehicle != null && !agentVehicle.isBlank()) ? " | Vehicle: " + agentVehicle : "";
		n.setBody(String.format("A pickup agent has been assigned for your return of order #%d. "
				+ "%s will collect the item. Contact: %s%s", orderId, agentName, agentPhone, vehicleInfo));
		n.setIcon("🔄");
		n.setColorClass("teal");
		n.setOrderId(orderId);
		n.setAgentName(agentName);
		n.setAgentPhone(agentPhone);
		n.setAgentVehicle(agentVehicle);
		n.setActionUrl("CustomerOrdersServlet?action=view&orderId=" + orderId);
		insertIfNotExists(n);
	}

	/** ITEM_PICKED_UP — return collected by agent. */
	public void notifyItemPickedUp(int customerId, int orderId) {
		CustomerNotification n = new CustomerNotification();
		n.setCustomerId(customerId);
		n.setType(CustomerNotification.ITEM_PICKED_UP);
		n.setTitle("Return item collected ✔️");
		n.setBody(String.format(
				"The item(s) from your return of order #%d have been collected. Your refund will be processed once inspection is complete (1–3 business days).",
				orderId));
		n.setIcon("✔️");
		n.setColorClass("blue");
		n.setOrderId(orderId);
		n.setActionUrl("CustomerOrdersServlet?action=view&orderId=" + orderId);
		insertIfNotExists(n);
	}

	/** REFUND_INITIATED */
	public void notifyRefundInitiated(int customerId, int orderId, double amount) {
		CustomerNotification n = new CustomerNotification();
		n.setCustomerId(customerId);
		n.setType(CustomerNotification.REFUND_INITIATED);
		n.setTitle("Refund initiated 💸");
		n.setBody(String.format(
				"A refund of ₹%.2f for order #%d has been initiated. It will be credited to your wallet within 24 hours.",
				amount, orderId));
		n.setIcon("💸");
		n.setColorClass("orange");
		n.setOrderId(orderId);
		n.setRefundAmount(amount);
		n.setActionUrl("CustomerWalletServlet");
		insertIfNotExists(n);
	}

	/** REFUND_CREDITED */
	public void notifyRefundCredited(int customerId, int orderId, double amount) {
		CustomerNotification n = new CustomerNotification();
		n.setCustomerId(customerId);
		n.setType(CustomerNotification.REFUND_CREDITED);
		n.setTitle("₹" + String.format("%.2f", amount) + " refund credited! 💰");
		n.setBody(String.format(
				"Your refund of ₹%.2f for order #%d has been successfully credited to your wallet. You can use it for future purchases.",
				amount, orderId));
		n.setIcon("💰");
		n.setColorClass("green");
		n.setOrderId(orderId);
		n.setRefundAmount(amount);
		n.setActionUrl("CustomerWalletServlet");
		insertIfNotExists(n);
	}

	/** PAYMENT_RECEIVED */
	public void notifyPaymentReceived(int customerId, int orderId, double amount, String method) {
		CustomerNotification n = new CustomerNotification();
		n.setCustomerId(customerId);
		n.setType(CustomerNotification.PAYMENT_RECEIVED);
		n.setTitle("Payment confirmed ✅");
		n.setBody(String.format("Payment of ₹%.2f for order #%d via %s has been confirmed. Thank you!", amount, orderId,
				method));
		n.setIcon("✅");
		n.setColorClass("green");
		n.setOrderId(orderId);
		n.setActionUrl("CustomerOrdersServlet?action=view&orderId=" + orderId);
		insertIfNotExists(n);
	}

	/** PAYMENT_FAILED */
	public void notifyPaymentFailed(int customerId, int orderId, String reason) {
		CustomerNotification n = new CustomerNotification();
		n.setCustomerId(customerId);
		n.setType(CustomerNotification.PAYMENT_FAILED);
		n.setTitle("Payment failed ⚠️");
		n.setBody(String.format(
				"Payment for order #%d could not be processed. %s Please retry or use a different payment method. Your cart is saved.",
				orderId, reason != null ? "Reason: " + reason + "." : ""));
		n.setIcon("⚠️");
		n.setColorClass("red");
		n.setOrderId(orderId);
		n.setActionUrl("CustomerOrdersServlet?action=view&orderId=" + orderId);
		insertIfNotExists(n);
	}

	/** WALLET_CREDITED */
	public void notifyWalletCredited(int customerId, double amount, String reason) {
		CustomerNotification n = new CustomerNotification();
		n.setCustomerId(customerId);
		n.setType(CustomerNotification.WALLET_CREDITED);
		n.setTitle("₹" + String.format("%.2f", amount) + " added to wallet 💳");
		n.setBody(String.format("₹%.2f has been credited to your SIBS wallet. Reason: %s.", amount, reason));
		n.setIcon("💳");
		n.setColorClass("green");
		n.setRefundAmount(amount);
		n.setActionUrl("CustomerWalletServlet");
		insertIfNotExists(n);
	}

	/** NEW_PRODUCT — new product launched in a category. */
	public void notifyNewProduct(int customerId, int productId, String productName, String category,
			double finalPrice) {
		CustomerNotification n = new CustomerNotification();
		n.setCustomerId(customerId);
		n.setType(CustomerNotification.NEW_PRODUCT);
		n.setTitle("New arrival: " + productName + " 🆕");
		n.setBody(
				String.format("A new product '%s' has been added in the %s category at ₹%.2f. Be the first to grab it!",
						productName, category, finalPrice));
		n.setIcon("🆕");
		n.setColorClass("purple");
		n.setProductId(productId);
		n.setActionUrl("Customer?productId=" + productId);
		insertIfNotExists(n);
	}

	/** PRODUCT_BACK_IN_STOCK — wishlisted item restocked. */
	public void notifyProductBackInStock(int customerId, int productId, String productName) {
		CustomerNotification n = new CustomerNotification();
		n.setCustomerId(customerId);
		n.setType(CustomerNotification.PRODUCT_BACK_IN_STOCK);
		n.setTitle(productName + " is back in stock! 🎯");
		n.setBody(String.format("Good news! '%s' from your wishlist is back in stock. Hurry, limited units available!",
				productName));
		n.setIcon("🎯");
		n.setColorClass("orange");
		n.setProductId(productId);
		n.setActionUrl("Customer?productId=" + productId);
		insertIfNotExists(n);
	}

	/** OFFER_ALERT — discount on a product. */
	public void notifyOfferAlert(int customerId, int productId, String productName, double discount) {
		CustomerNotification n = new CustomerNotification();
		n.setCustomerId(customerId);
		n.setType(CustomerNotification.OFFER_ALERT);
		n.setTitle((int) discount + "% off on " + productName + "! 🔥");
		n.setBody(String.format(
				"Limited time offer! Get %.0f%% off on '%s'. Don't miss this deal — offer valid while stocks last.",
				discount, productName));
		n.setIcon("🔥");
		n.setColorClass("red");
		n.setProductId(productId);
		n.setActionUrl("Customer?productId=" + productId);
		insertIfNotExists(n);
	}

	/** ACCOUNT_UPDATED */
	public void notifyAccountUpdated(int customerId, String changeDescription) {
		CustomerNotification n = new CustomerNotification();
		n.setCustomerId(customerId);
		n.setType(CustomerNotification.ACCOUNT_UPDATED);
		n.setTitle("Account updated 🔒");
		n.setBody("Your account has been updated: " + changeDescription
				+ ". If you didn't make this change, contact support immediately.");
		n.setIcon("🔒");
		n.setColorClass("blue");
		n.setActionUrl("CustomerProfileServlet");
		insertIfNotExists(n);
	}

	// ── NEWLY ADDED FACTORY METHODS ───────────────────────────────────────────
	// These were called from OrderServlet but never existed in the DAO,
	// causing NoSuchMethodError at runtime and silent notification failures.

	/** Order packed at warehouse — customer sees "We're packing your order". */
	public void notifyOrderPacked(int customerId, int orderId) {
		CustomerNotification n = new CustomerNotification();
		n.setCustomerId(customerId);
		n.setType(CustomerNotification.ORDER_PACKED);
		n.setTitle("Your order is packed 📦");
		n.setBody("Great news! Your order #" + orderId
				+ " has been packed and is getting ready for dispatch. We'll notify you once it's on the way.");
		n.setIcon("📦");
		n.setColorClass("blue");
		n.setOrderId(orderId);
		n.setActionUrl("CustomerOrdersServlet?orderId=" + orderId);
		insertIfNotExists(n);
	}

	/** Order dispatched from the warehouse. */
	public void notifyOrderShipped(int customerId, int orderId, String agentName, String agentPhone) {
		String agent = (agentName != null && !agentName.isBlank()) ? agentName : "our delivery agent";
		CustomerNotification n = new CustomerNotification();
		n.setCustomerId(customerId);
		n.setType(CustomerNotification.ORDER_SHIPPED);
		n.setTitle("Order shipped 🚚");
		n.setBody("Your order #" + orderId + " has been dispatched and is on its way! " + agent
				+ " will deliver it to you shortly.");
		n.setIcon("🚚");
		n.setColorClass("blue");
		n.setOrderId(orderId);
		if (agentName != null) {
			n.setAgentName(agentName);
		}
		if (agentPhone != null) {
			n.setAgentPhone(agentPhone);
		}
		n.setActionUrl("CustomerOrdersServlet?orderId=" + orderId);
		insertIfNotExists(n);
	}

	/**
	 * Delivery agent was unable to complete delivery (customer absent, wrong
	 * address, etc.). Order has been reverted to Confirmed for reassignment.
	 */
	public void notifyDeliveryFailed(int customerId, int orderId, String reason) {
		String safeReason = (reason != null && !reason.isBlank()) ? reason : "delivery could not be completed";
		CustomerNotification n = new CustomerNotification();
		n.setCustomerId(customerId);
		n.setType(CustomerNotification.DELIVERY_FAILED);
		n.setTitle("Delivery attempt failed ⚠️");
		n.setBody("We were unable to deliver your order #" + orderId + ". Reason: " + safeReason
				+ ". Our team will reassign a delivery agent and try again soon.");
		n.setIcon("⚠️");
		n.setColorClass("orange");
		n.setOrderId(orderId);
		n.setActionUrl("CustomerOrdersServlet?orderId=" + orderId);
		insertIfNotExists(n);
	}

	/** Return pickup agent is heading to the customer's address. */
	public void notifyReturnOutForPickup(int customerId, int orderId, String agentName, String agentPhone,
			String agentVehicle) {
		String agent = (agentName != null && !agentName.isBlank()) ? agentName : "our pickup agent";
		CustomerNotification n = new CustomerNotification();
		n.setCustomerId(customerId);
		n.setType(CustomerNotification.RETURN_OUT_FOR_PICKUP);
		n.setTitle("Pickup agent on the way 🛵");
		n.setBody(agent + " is on the way to collect your return for order #" + orderId
				+ ". Please keep the item ready.");
		n.setIcon("🛵");
		n.setColorClass("teal");
		n.setOrderId(orderId);
		if (agentName != null) {
			n.setAgentName(agentName);
		}
		if (agentPhone != null) {
			n.setAgentPhone(agentPhone);
		}
		if (agentVehicle != null) {
			n.setAgentVehicle(agentVehicle);
		}
		n.setActionUrl("CustomerOrdersServlet?orderId=" + orderId);
		insertIfNotExists(n);
	}

	/**
	 * Replacement product is being dispatched after a successful return/exchange.
	 */
	public void notifyReplacementDispatch(int customerId, int orderId) {
		CustomerNotification n = new CustomerNotification();
		n.setCustomerId(customerId);
		n.setType(CustomerNotification.REPLACEMENT_DISPATCH);
		n.setTitle("Replacement on its way 🔄");
		n.setBody("Your replacement for order #" + orderId
				+ " has been packed and a delivery agent will be assigned shortly. " + "Thank you for your patience!");
		n.setIcon("🔄");
		n.setColorClass("purple");
		n.setOrderId(orderId);
		n.setActionUrl("CustomerOrdersServlet?orderId=" + orderId);
		insertIfNotExists(n);
	}

	/** Replacement product has been delivered successfully. */
	public void notifyReplacementDelivered(int customerId, int orderId) {
		CustomerNotification n = new CustomerNotification();
		n.setCustomerId(customerId);
		n.setType(CustomerNotification.REPLACEMENT_DELIVERED);
		n.setTitle("Replacement delivered ✅");
		n.setBody("Your replacement for order #" + orderId
				+ " has been delivered successfully. We hope you enjoy your purchase!");
		n.setIcon("✅");
		n.setColorClass("green");
		n.setOrderId(orderId);
		n.setActionUrl("CustomerOrdersServlet?orderId=" + orderId);
		insertIfNotExists(n);
	}

	// ── PRIVATE HELPERS ───────────────────────────────────────────────────────

	private List<CustomerNotification> query(String sql, int customerId) {
		List<CustomerNotification> list = new ArrayList<>();
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, customerId);
			try (ResultSet rs = ps.executeQuery()) {
				while (rs.next()) {
					list.add(map(rs));
				}
			}
		} catch (SQLException e) {
			log.log(Level.WARNING, "query failed: " + sql, e);
		}
		return list;
	}

	private void exec(String sql, int id) {
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, id);
			ps.executeUpdate();
		} catch (SQLException e) {
			log.log(Level.WARNING, "exec failed: " + sql + " id=" + id, e);
		}
	}

	private void setNullableInt(PreparedStatement ps, int idx, Integer val) throws SQLException {
		if (val != null) {
			ps.setInt(idx, val);
		} else {
			ps.setNull(idx, Types.INTEGER);
		}
	}

	private CustomerNotification map(ResultSet rs) throws SQLException {
		CustomerNotification n = new CustomerNotification();
		n.setId(rs.getInt("id"));
		n.setCustomerId(rs.getInt("customer_id"));
		n.setType(rs.getString("type"));
		n.setTitle(rs.getString("title"));
		n.setBody(rs.getString("body"));
		n.setIcon(rs.getString("icon"));
		n.setColorClass(rs.getString("color_class"));

		int oid = rs.getInt("order_id");
		if (!rs.wasNull()) {
			n.setOrderId(oid);
		}
		int pid = rs.getInt("product_id");
		if (!rs.wasNull()) {
			n.setProductId(pid);
		}
		int aid = rs.getInt("agent_id");
		if (!rs.wasNull()) {
			n.setAgentId(aid);
		}

		n.setAgentName(rs.getString("agent_name"));
		n.setAgentPhone(rs.getString("agent_phone"));

		double ra = rs.getDouble("refund_amount");
		if (!rs.wasNull()) {
			n.setRefundAmount(ra);
		}

		n.setActionUrl(rs.getString("action_url"));
		n.setRead(rs.getInt("is_read") == 1);
		n.setDismissed(rs.getInt("is_dismissed") == 1);
		n.setCreatedAt(rs.getTimestamp("created_at"));
		return n;
	}

	// ── SUPPORT TICKET NOTIFICATIONS ─────────────────────────────────────────

	/**
	 * Sent to the CUSTOMER immediately after they raise a new ticket. Confirms
	 * receipt and sets their expectation for a response.
	 *
	 * @param customerId customer who raised the ticket
	 * @param ticketId   generated ticket ID
	 * @param subject    ticket subject line
	 * @param category   ticket category (order, payment, delivery…)
	 */
	public void notifyTicketRaised(int customerId, int ticketId, String subject, String category) {
		CustomerNotification n = new CustomerNotification();
		n.setCustomerId(customerId);
		n.setType(CustomerNotification.TICKET_RAISED);
		n.setTitle("Support ticket raised 🎫");
		n.setBody("Your support request **#TKT-" + ticketId + "** (" + (subject != null ? subject : category)
				+ ") has been received. " + "Our team will respond within 2–4 business hours. "
				+ "You can track and reply from Help & Support.");
		n.setIcon("🎫");
		n.setColorClass("blue");
		n.setActionUrl("HelpDesk");
		// NOTE: no orderId — tickets are not always order-related.
		// insertIfNotExists would de-duplicate by (customerId,type,orderId=null)
		// which would block a second ticket. Call insert() directly instead.
		insert(n);
	}

	/**
	 * Sent to the CUSTOMER when a staff member posts a reply on their ticket.
	 * Prompts them to read and respond if needed.
	 *
	 * @param customerId   ticket owner
	 * @param ticketId     ticket that was replied to
	 * @param subject      ticket subject (for context)
	 * @param staffName    display name of the replying staff member
	 * @param replySnippet first 120 chars of the staff reply (preview)
	 */
	public void notifyTicketReply(int customerId, int ticketId, String subject, String staffName, String replySnippet) {
		String staff = (staffName != null && !staffName.isBlank()) ? staffName : "Support Team";
		String preview = (replySnippet != null && replySnippet.length() > 120) ? replySnippet.substring(0, 117) + "…"
				: (replySnippet != null ? replySnippet : "");
		CustomerNotification n = new CustomerNotification();
		n.setCustomerId(customerId);
		n.setType(CustomerNotification.TICKET_REPLY);
		n.setTitle("Support replied to your ticket 💬");
		n.setBody(staff + " replied to your ticket #TKT-" + ticketId + (subject != null ? " (" + subject + ")" : "")
				+ ": " + (preview.isBlank() ? "Open your ticket to read the reply." : preview));
		n.setIcon("💬");
		n.setColorClass("purple");
		n.setActionUrl("HelpDesk");
		insert(n); // Always insert — every reply is a new notification
	}

	/**
	 * Sent to the CUSTOMER when staff marks their ticket as resolved or closed.
	 * Invites them to re-open if the issue isn't fixed.
	 *
	 * @param customerId customer who owns the ticket
	 * @param ticketId   resolved ticket
	 * @param subject    ticket subject
	 * @param resolution Optional brief resolution summary from staff (may be null)
	 */
	public void notifyTicketResolved(int customerId, int ticketId, String subject, String resolution) {
		String body = "Your support ticket #TKT-" + ticketId + "(" + subject != null ? " (" + subject + ")"
				: ") has been resolved. ✅";
		if (resolution != null && !resolution.isBlank()) {
			body += " " + (resolution.length() > 200 ? resolution.substring(0, 197) + "…" : resolution);
		}
		body += " If your issue isn't fixed, please reply and we'll reopen it.";
		CustomerNotification n = new CustomerNotification();
		n.setCustomerId(customerId);
		n.setType(CustomerNotification.TICKET_RESOLVED);
		n.setTitle("Support ticket resolved ✅");
		n.setBody(body);
		n.setIcon("✅");
		n.setColorClass("green");
		n.setActionUrl("HelpDesk");
		insertIfNotExists(n);
	}

	/**
	 * Sent to the CUSTOMER if staff re-opens, escalates, or reassigns a ticket and
	 * wants to inform the customer of the new status.
	 *
	 * @param customerId customer who owns the ticket
	 * @param ticketId   the ticket
	 * @param subject    ticket subject
	 * @param newStatus  human-readable new status (e.g. "in_progress", "open")
	 * @param staffNote  optional note from staff explaining the status change
	 */
	public void notifyTicketUpdated(int customerId, int ticketId, String subject, String newStatus, String staffNote) {
		String statusLabel = switch (newStatus != null ? newStatus : "") {
		case "in_progress" -> "is now being actively worked on";
		case "open" -> "has been re-opened";
		case "waiting_customer" -> "needs your response";
		default -> "has been updated";
		};
		String body = "Your support ticket #TKT-" + ticketId + " (" + subject != null ? " (" + subject + ")"
				: ")" + " " + statusLabel + ".";
		if (staffNote != null && !staffNote.isBlank()) {
			body += " Note: " + (staffNote.length() > 150 ? staffNote.substring(0, 147) + "…" : staffNote);
		}
		CustomerNotification n = new CustomerNotification();
		n.setCustomerId(customerId);
		n.setType(CustomerNotification.TICKET_UPDATED);
		n.setTitle("Support ticket update 📋");
		n.setBody(body);
		n.setIcon("📋");
		n.setColorClass("orange");
		n.setActionUrl("HelpDesk");
		insert(n);
	}

	// ── VEHICLE INFO HELPER ───────────────────────────────────────────────────
	/**
	 * Fetches the vehicle description for a delivery agent from
	 * delivery_agent_registrations (joined by username from users).
	 *
	 * FIXED: now queries the delivery_agent_registrations table directly (the
	 * authoritative vehicle source), filters to status='APPROVED' only, and
	 * includes vehicle_colour for a more complete description. Returns a formatted
	 * string like "Honda Activa · MH12AB1234 (Red)" or null.
	 */
	public String getAgentVehicleInfo(int userId) {
		String sql = """
				SELECT d.vehicle_type, d.vehicle_brand, d.vehicle_model,
				       d.vehicle_reg_number, d.vehicle_colour
				FROM users u
				JOIN delivery_agent_registrations d ON d.username = u.username
				WHERE u.id = ?
				  AND d.status = 'APPROVED'
				LIMIT 1
				""";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, userId);
			try (ResultSet rs = ps.executeQuery()) {
				if (rs.next()) {
					return buildVehicleString(rs.getString("vehicle_brand"), rs.getString("vehicle_model"),
							rs.getString("vehicle_type"), rs.getString("vehicle_reg_number"),
							rs.getString("vehicle_colour"));
				}
			}
		} catch (SQLException e) {
			log.log(Level.WARNING, "getAgentVehicleInfo failed for userId=" + userId, e);
		}
		return null;
	}

	/** Formats vehicle fields into "Brand Model · REG (Colour)". */
	private String buildVehicleString(String brand, String model, String type, String regNo, String colour) {
		StringBuilder sb = new StringBuilder();
		if (brand != null && !brand.isBlank()) {
			sb.append(brand.trim()).append(" ");
		}
		if (model != null && !model.isBlank()) {
			sb.append(model.trim());
		}
		if (type != null && !type.isBlank() && sb.length() == 0) {
			sb.append(type.trim());
		}
		if (regNo != null && !regNo.isBlank()) {
			if (sb.length() > 0) {
				sb.append(" · ");
			}
			sb.append(regNo.trim().toUpperCase());
		}
		if (colour != null && !colour.isBlank()) {
			sb.append(" (").append(colour.trim()).append(")");
		}
		return sb.length() > 0 ? sb.toString() : null;
	}

}
