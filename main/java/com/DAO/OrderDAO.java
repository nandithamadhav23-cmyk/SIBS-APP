package com.DAO;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Types;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

import com.util.CartItem;
import com.util.DBConnection;
import com.util.Order;

/**
 * OrderDAO — Manages the orders table.
 *
 * ── ADDRESS SNAPSHOT STRATEGY ────────────────────────────────────────────────
 *
 * The orders table now has seven snapshot columns: snap_address_id,
 * snap_street, snap_city, snap_district, snap_state, snap_country, snap_pincode
 *
 * These are written ONCE at order creation time (createOrder) from the
 * customer's current default address, and are NEVER changed by default-address
 * updates. Every query that needs the delivery address reads from these columns
 * — not from a live JOIN against customer_address.
 *
 * The ONLY exception is the explicit updateOrderAddress() method, which lets
 * staff / the customer change the address for a specific order while it is
 * still in a pre-shipment stage (Ordered / Pending / Confirmed), and which
 * records the change timestamp in address_changed_at.
 *
 * ── QUERY STRATEGY ───────────────────────────────────────────────────────────
 *
 * getOrderById() → CONCAT_WS of snap_* columns (no address JOIN) getAllOrders()
 * → same getOrdersByCustomer() → same (was SELECT o.* — now explicit columns)
 * getOrdersByDeliveryAgent() → same getDeliveredCodOrdersPendingDeposit() →
 * same
 *
 * ── CHECKOUT TOTAL CONSISTENCY ───────────────────────────────────────────────
 *
 * createOrder() accepts deliveryCharge and codCharge as explicit parameters.
 * CheckoutServlet MUST compute these identically to PlaceOrderServlet:
 * deliveryCharge = subtotal > 700 ? 0 : 40 codCharge = COD ? 50 : 0 Both
 * servlets now call the same helper formula — see PlaceOrderServlet.
 *
 * ── OTHER FIXES ──────────────────────────────────────────────────────────────
 *
 * FIX 1 — updateDeliveryDate() guarded against bad input FIX 2 —
 * assignDeliveryPersonAndStatus() sets status = 'Assigned' FIX 3 —
 * getAllOrders() + getOrdersByCustomer() include payment_method FIX 4 —
 * getOrdersByCustomer() now explicit columns, no SELECT o.* FIX 5 —
 * getOrderById() maps order_otp, delivery_user_id, phone, address FIX 6 —
 * updateOrderAddress() new method for per-order address change
 */
public class OrderDAO {

	// ─────────────────────────────────────────────────────────────────────────
	// SHARED ADDRESS SQL FRAGMENT — reads from snapshot columns
	// Replaces every previous "LEFT JOIN customer_address ca ON … is_default=1"
	// ─────────────────────────────────────────────────────────────────────────
	private static final String SNAP_ADDR_EXPR = "  CONCAT_WS(', ', o.snap_street, o.snap_city, o.snap_state,"
			+ "            o.snap_country, o.snap_pincode) AS delivery_address ";

	// ─────────────────────────────────────────────────────────────────────────
	// createOrder — saves address snapshot at order creation time
	// ─────────────────────────────────────────────────────────────────────────
	public int createOrder(int customerId, double subtotal, double gst, double tax, double deliveryCharge,
			double codCharge, double grandTotal, List<CartItem> cartItems, String paymentMethod,
			// ADDRESS SNAPSHOT ─ required so address is immutable after placement
			int snapAddressId, String snapStreet, String snapCity, String snapDistrict, String snapState,
			String snapCountry, String snapPincode) throws SQLException {

		int orderId = -1;

		String initialStatus;
		switch (paymentMethod.toUpperCase()) {
		case "COD" -> initialStatus = "Pending";
		case "CARD", "UPI", "NETBANKING" -> initialStatus = "Confirmed";
		default -> initialStatus = "Ordered";
		}

		String initialPaymentStatus;
		switch (paymentMethod.toUpperCase()) {
		case "COD" -> initialPaymentStatus = "PENDING_COD";
		case "CARD", "UPI", "NETBANKING" -> initialPaymentStatus = "AWAITING_PAYMENT";
		default -> initialPaymentStatus = "ORDERED";
		}

		String orderSql = "INSERT INTO orders " + "  (customer_id, order_date, status, delivery_date, "
				+ "   subtotal, gst, tax, delivery_charge, cod_charge, total_amount, "
				+ "   payment_method, payment_status, " + "   snap_address_id, snap_street, snap_city, snap_district, "
				+ "   snap_state, snap_country, snap_pincode) "
				+ "VALUES (?, NOW(), ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

		try (Connection conn = DBConnection.getConnection()) {
			conn.setAutoCommit(false);
			try {
				try (PreparedStatement ps = conn.prepareStatement(orderSql, Statement.RETURN_GENERATED_KEYS)) {
					LocalDate autoDeliveryDate = LocalDate.now().plusDays(5);
					ps.setInt(1, customerId);
					ps.setString(2, initialStatus);
					ps.setDate(3, java.sql.Date.valueOf(autoDeliveryDate));
					ps.setDouble(4, subtotal);
					ps.setDouble(5, gst);
					ps.setDouble(6, tax);
					ps.setDouble(7, deliveryCharge);
					ps.setDouble(8, codCharge);
					ps.setDouble(9, grandTotal);
					ps.setString(10, paymentMethod);
					ps.setString(11, initialPaymentStatus);
					// snapshot
					if (snapAddressId > 0) {
						ps.setInt(12, snapAddressId);
					} else {
						ps.setNull(12, Types.INTEGER);
					}
					ps.setString(13, snapStreet);
					ps.setString(14, snapCity);
					ps.setString(15, snapDistrict);
					ps.setString(16, snapState);
					ps.setString(17, snapCountry);
					ps.setString(18, snapPincode);
					ps.executeUpdate();

					try (ResultSet rs = ps.getGeneratedKeys()) {
						if (rs.next()) {
							orderId = rs.getInt(1);
						}
					}
				}

				String itemSql = "INSERT INTO order_items (order_id, product_id, quantity, price) VALUES (?,?,?,?)";
				try (PreparedStatement is = conn.prepareStatement(itemSql)) {
					for (CartItem item : cartItems) {
						is.setInt(1, orderId);
						is.setInt(2, item.getProductId());
						is.setInt(3, item.getQuantity());
						is.setDouble(4, item.getFinalPrice());
						is.addBatch();
					}
					is.executeBatch();
				}

				conn.commit();
			} catch (SQLException e) {
				conn.rollback();
				throw e;
			}
		}
		return orderId;
	}

	// ─────────────────────────────────────────────────────────────────────────
	// FIX 6: updateOrderAddress — per-order address change (pre-shipment only)
	// Called by AIChatServlet.handleSaveAddr() and AddressServlet changeForOrder.
	// Does NOT touch customer_address.is_default — purely order-level.
	// ─────────────────────────────────────────────────────────────────────────
	public boolean updateOrderAddress(int orderId, int customerId, int newAddressId, String street, String city,
			String district, String state, String country, String pincode) throws SQLException {

		// Security + stage gate in one query
		String checkSql = "SELECT status FROM orders WHERE order_id = ? AND customer_id = ?";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement chk = conn.prepareStatement(checkSql)) {
			chk.setInt(1, orderId);
			chk.setInt(2, customerId);
			try (ResultSet rs = chk.executeQuery()) {
				if (!rs.next()) {
					return false; // not found / not owner
				}
				String status = rs.getString("status");
				boolean changeable = status != null
						&& (status.equalsIgnoreCase("Ordered") || status.equalsIgnoreCase("Pending")
								|| status.equalsIgnoreCase("Confirmed") || status.equalsIgnoreCase("Processing"));
				if (!changeable) {
					return false; // already in motion
				}
			}
		}

		String sql = "UPDATE orders SET " + "  snap_address_id = ?, snap_street = ?, snap_city = ?, snap_district = ?, "
				+ "  snap_state = ?, snap_country = ?, snap_pincode = ?, " + "  address_changed_at = NOW() "
				+ "WHERE order_id = ? AND customer_id = ?";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			if (newAddressId > 0) {
				ps.setInt(1, newAddressId);
			} else {
				ps.setNull(1, Types.INTEGER);
			}
			ps.setString(2, street);
			ps.setString(3, city);
			ps.setString(4, district);
			ps.setString(5, state);
			ps.setString(6, country);
			ps.setString(7, pincode);
			ps.setInt(8, orderId);
			ps.setInt(9, customerId);
			return ps.executeUpdate() > 0;
		}
	}

	// ─────────────────────────────────────────────────────────────────────────
	// updatePaymentStatus
	// ─────────────────────────────────────────────────────────────────────────
	public void updatePaymentStatus(int orderId, String status, String transactionId) {
		String sql = "UPDATE orders SET payment_status = ?, transaction_id = ? WHERE order_id = ?";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setString(1, status);
			ps.setString(2, transactionId);
			ps.setInt(3, orderId);
			ps.executeUpdate();
		} catch (SQLException e) {
			throw new RuntimeException("updatePaymentStatus failed for order " + orderId, e);
		}
	}

	// ─────────────────────────────────────────────────────────────────────────
	// updateOrderStatus
	// ─────────────────────────────────────────────────────────────────────────
	public void updateOrderStatus(int orderId, String status) throws SQLException {
		if (orderId <= 0 || status == null || status.isBlank()) {
			return;
		}
		String sql = "UPDATE orders SET status = ? WHERE order_id = ?";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setString(1, status);
			ps.setInt(2, orderId);
			ps.executeUpdate();
		}
	}

	// ─────────────────────────────────────────────────────────────────────────
	// FIX 2: assignDeliveryPersonAndStatus
	// ─────────────────────────────────────────────────────────────────────────
	public void assignDeliveryPersonAndStatus(int orderId, int deliveryUserId) throws SQLException {
		String sql = "UPDATE orders SET delivery_user_id = ?, status = 'Assigned' WHERE order_id = ?";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, deliveryUserId);
			ps.setInt(2, orderId);
			ps.executeUpdate();
		}
	}

	// ─────────────────────────────────────────────────────────────────────────
	// FIX 1: updateDeliveryDate — guarded
	// ─────────────────────────────────────────────────────────────────────────
	public void updateDeliveryDate(int orderId, LocalDate deliveryDate) throws SQLException {
		if (orderId <= 0 || deliveryDate == null) {
			return;
		}
		String sql = "UPDATE orders SET delivery_date = ? WHERE order_id = ?";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setDate(1, java.sql.Date.valueOf(deliveryDate));
			ps.setInt(2, orderId);
			ps.executeUpdate();
		}
	}

	public LocalDate getDeliveryDate(int orderId) throws SQLException {
		String sql = "SELECT delivery_date FROM orders WHERE order_id = ?";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, orderId);
			try (ResultSet rs = ps.executeQuery()) {
				if (rs.next()) {
					Date d = rs.getDate("delivery_date");
					return d != null ? d.toLocalDate() : null;
				}
			}
		}
		return null;
	}

	// ─────────────────────────────────────────────────────────────────────────
	// getOrderById — FIX 5 + snapshot address (no live address JOIN)
	// ─────────────────────────────────────────────────────────────────────────
	public Order getOrderById(int orderId) throws SQLException {
		String sql = "SELECT o.order_id, o.customer_id, o.status, o.order_date, "
				+ "  o.delivery_date, o.subtotal, o.gst, o.tax, "
				+ "  o.delivery_charge, o.cod_charge, o.total_amount, "
				+ "  o.payment_method, o.payment_status, o.transaction_id, "
				+ "  o.order_otp, o.delivery_user_id, o.slot_id, " + "  o.snap_address_id, o.snap_street, o.snap_city, "
				+ "  o.snap_district, o.snap_state, o.snap_country, o.snap_pincode, " + "  o.address_changed_at, "
				+ SNAP_ADDR_EXPR + ", " + "  c.name  AS customer_name, " + "  c.email AS customer_email, "
				+ "  c.phone AS customer_phone, " + "  u.username AS delivery_user_name " + "FROM orders o "
				+ "JOIN customers c ON o.customer_id = c.customer_id "
				+ "LEFT JOIN users u ON o.delivery_user_id = u.id " + "WHERE o.order_id = ?";

		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, orderId);
			try (ResultSet rs = ps.executeQuery()) {
				if (rs.next()) {
					return mapFullRow(rs, true);
				}
			}
		}
		return null;
	}

	// ─────────────────────────────────────────────────────────────────────────
	// getAllOrders — FIX 3 + snapshot address
	// ─────────────────────────────────────────────────────────────────────────
	public List<Order> getAllOrders() throws SQLException {
		List<Order> orders = new ArrayList<>();
		String sql = "SELECT o.order_id, o.customer_id, o.status, o.order_date, "
				+ "  o.delivery_date, o.subtotal, o.gst, o.tax, "
				+ "  o.delivery_charge, o.cod_charge, o.total_amount, "
				+ "  o.payment_method, o.payment_status, o.transaction_id, " + "  o.order_otp, o.delivery_user_id, "
				+ "  o.snap_address_id, o.snap_street, o.snap_city, "
				+ "  o.snap_district, o.snap_state, o.snap_country, o.snap_pincode, " + "  o.address_changed_at, "
				+ SNAP_ADDR_EXPR + ", " + "  c.name  AS customer_name, " + "  c.email AS customer_email, "
				+ "  c.phone AS customer_phone, " + "  u.username AS delivery_user_name " + "FROM orders o "
				+ "JOIN customers c ON o.customer_id = c.customer_id "
				+ "LEFT JOIN users u ON o.delivery_user_id = u.id " + "ORDER BY o.order_id DESC";

		try (Connection conn = DBConnection.getConnection();
				PreparedStatement ps = conn.prepareStatement(sql);
				ResultSet rs = ps.executeQuery()) {
			while (rs.next()) {
				Order order = mapFullRow(rs, false);
				order.setItems(getOrderItems(order.getId()));
				orders.add(order);
			}
		}
		return orders;
	}

	// ─────────────────────────────────────────────────────────────────────────
	// getOrdersByCustomer — FIX 4: explicit columns + snapshot address
	// ─────────────────────────────────────────────────────────────────────────
	public List<Order> getOrdersByCustomer(int customerId) throws SQLException {
		List<Order> orders = new ArrayList<>();
		String sql = "SELECT o.order_id, o.customer_id, o.status, o.order_date, "
				+ "  o.delivery_date, o.subtotal, o.gst, o.tax, "
				+ "  o.delivery_charge, o.cod_charge, o.total_amount, "
				+ "  o.payment_method, o.payment_status, o.transaction_id, " + "  o.order_otp, o.delivery_user_id, "
				+ "  o.snap_address_id, o.snap_street, o.snap_city, "
				+ "  o.snap_district, o.snap_state, o.snap_country, o.snap_pincode, " + "  o.address_changed_at, "
				+ SNAP_ADDR_EXPR + ", " + "  c.name  AS customer_name, " + "  c.email AS customer_email, "
				+ "  c.phone AS customer_phone " + "FROM orders o "
				+ "JOIN customers c ON o.customer_id = c.customer_id " + "WHERE o.customer_id = ? "
				+ "ORDER BY o.order_id DESC";

		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, customerId);
			try (ResultSet rs = ps.executeQuery()) {
				while (rs.next()) {
					Order order = mapFullRow(rs, false);
					order.setItems(getOrderItems(order.getId()));
					orders.add(order);
				}
			}
		}
		return orders;
	}

	// ─────────────────────────────────────────────────────────────────────────
	// getOrdersByDeliveryAgent — snapshot address (no is_default JOIN)
	// ─────────────────────────────────────────────────────────────────────────
	public List<Order> getOrdersByDeliveryAgent(int deliveryUserId) throws SQLException {
		List<Order> orders = new ArrayList<>();
		String sql = "SELECT o.order_id, o.customer_id, o.status, o.order_date, "
				+ "  o.delivery_date, o.subtotal, o.gst, o.tax, "
				+ "  o.delivery_charge, o.cod_charge, o.total_amount, "
				+ "  o.payment_method, o.payment_status, o.transaction_id, "
				+ "  o.order_otp, o.delivery_user_id, o.slot_id, " + "  o.snap_address_id, o.snap_street, o.snap_city, "
				+ "  o.snap_district, o.snap_state, o.snap_country, o.snap_pincode, " + "  o.address_changed_at, "
				+ SNAP_ADDR_EXPR + ", " + "  c.name  AS customer_name, " + "  c.email AS customer_email, "
				+ "  c.phone AS customer_phone " + "FROM orders o "
				+ "JOIN customers c ON o.customer_id = c.customer_id " + "WHERE o.delivery_user_id = ? "
				+ "ORDER BY o.order_id DESC";

		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, deliveryUserId);
			try (ResultSet rs = ps.executeQuery()) {
				while (rs.next()) {
					Order order = mapFullRow(rs, true); // slot_id present
					order.setItems(getOrderItems(order.getId()));
					orders.add(order);
				}
			}
		}
		return orders;
	}

	// ─────────────────────────────────────────────────────────────────────────
	// getDeliveredCodOrdersPendingDeposit — snapshot address
	// ─────────────────────────────────────────────────────────────────────────
	public List<Order> getDeliveredCodOrdersPendingDeposit(int agentId) throws SQLException {
		List<Order> orders = new ArrayList<>();
		String sql = "SELECT o.order_id, o.customer_id, o.status, o.order_date, "
				+ "  o.delivery_date, o.subtotal, o.gst, o.tax, "
				+ "  o.delivery_charge, o.cod_charge, o.total_amount, "
				+ "  o.payment_method, o.payment_status, o.transaction_id, "
				+ "  o.order_otp, o.delivery_user_id, o.slot_id, " + "  o.snap_address_id, o.snap_street, o.snap_city, "
				+ "  o.snap_district, o.snap_state, o.snap_country, o.snap_pincode, " + "  o.address_changed_at, "
				+ SNAP_ADDR_EXPR + ", " + "  c.name  AS customer_name, " + "  c.email AS customer_email, "
				+ "  c.phone AS customer_phone " + "FROM orders o "
				+ "JOIN customers c ON o.customer_id = c.customer_id " + "WHERE o.delivery_user_id = ? "
				+ "  AND o.payment_method = 'COD' " + "  AND o.status = 'Delivered' "
				+ "  AND o.cod_deposit_at IS NULL " + "ORDER BY o.delivery_date DESC";

		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, agentId);
			try (ResultSet rs = ps.executeQuery()) {
				while (rs.next()) {
					Order order = mapFullRow(rs, true);
					order.setItems(getOrderItems(order.getId()));
					orders.add(order);
				}
			}
		}
		return orders;
	}

	public List<Order> getAllDeliveredCodOrdersPendingDeposit() throws SQLException {
		String sql = "SELECT o.*, u.username AS agent_name, u.mobile AS agent_phone " + "FROM orders o "
				+ "JOIN users u ON o.delivery_user_id = u.id " + "WHERE o.payment_method = 'COD' "
				+ "  AND o.status = 'Delivered' " + "  AND o.cod_deposited = 0 "
				+ "ORDER BY o.payment_status DESC, o.updated_at ASC";
		List<Order> orders = new ArrayList<>();
		try (Connection conn = DBConnection.getConnection();
				PreparedStatement ps = conn.prepareStatement(sql);
				ResultSet rs = ps.executeQuery()) {
			while (rs.next()) {
				Order o = new Order();
				o.setId(rs.getInt("order_id"));
				o.setCustomerId(rs.getInt("customer_id"));
				o.setDeliveryUserId(rs.getInt("delivery_user_id"));
				o.setDate(rs.getTimestamp("order_date"));
				o.setStatus(rs.getString("status"));
				o.setSubtotal(rs.getDouble("subtotal"));
				o.setGst(rs.getDouble("gst"));
				o.setTax(rs.getDouble("tax"));
				o.setDeliveryCharge(rs.getDouble("delivery_charge"));
				o.setCodCharge(rs.getDouble("cod_charge"));
				o.setTotalAmount(rs.getDouble("total_amount"));
				o.setDeliveryDate(rs.getDate("delivery_date"));
				o.setPaymentMethod(rs.getString("payment_method"));
				o.setPaymentStatus(rs.getString("payment_status"));
				o.setTransactionId(rs.getString("transaction_id"));
				o.setOtp(rs.getInt("order_otp"));
				o.setDeliveryUserName(rs.getString("agent_name"));
				o.setPhone(rs.getString("agent_phone"));
				o.setItems(getOrderItems(o.getId()));
				orders.add(o);
			}
		}
		return orders;
	}

	// ─────────────────────────────────────────────────────────────────────────
	// getOrderItems
	// ─────────────────────────────────────────────────────────────────────────
	public List<CartItem> getOrderItems(int orderId) throws SQLException {
		List<CartItem> items = new ArrayList<>();
		String sql = "SELECT oi.product_id, oi.quantity, oi.price, p.name, p.imageUrl, "
				+ "  p.description, p.unit, p.quantity AS pack_size, p.discount " + "FROM order_items oi "
				+ "JOIN products p ON oi.product_id = p.product_id " + "WHERE oi.order_id = ?";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, orderId);
			try (ResultSet rs = ps.executeQuery()) {
				while (rs.next()) {
					CartItem item = new CartItem();
					item.setProductId(rs.getInt("product_id"));
					item.setQuantity(rs.getInt("quantity"));
					item.setFinalPrice(rs.getDouble("price"));
					item.setName(rs.getString("name"));
					item.setImageUrl(rs.getString("imageUrl"));
					item.setUnit(rs.getString("unit"));
					item.setProductQuantity(rs.getInt("pack_size"));
					item.setDescription(rs.getString("description"));
					item.setDiscount(rs.getDouble("discount"));
					items.add(item);
				}
			}
		}
		return items;
	}

	// ─────────────────────────────────────────────────────────────────────────
	// OTP helpers
	// ─────────────────────────────────────────────────────────────────────────
	public void updateOrderOtp(int orderId, int otp) throws SQLException {
		String sql = "UPDATE orders SET order_otp = ? WHERE order_id = ?";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, otp);
			ps.setInt(2, orderId);
			ps.executeUpdate();
		}
	}

	public int getOrderOtp(int orderId) throws SQLException {
		String sql = "SELECT order_otp FROM orders WHERE order_id = ?";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, orderId);
			try (ResultSet rs = ps.executeQuery()) {
				return rs.next() ? rs.getInt("order_otp") : -1;
			}
		}
	}

	public int getDeliveryUserId(int orderId) throws SQLException {
		String sql = "SELECT delivery_user_id FROM orders WHERE order_id = ?";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, orderId);
			try (ResultSet rs = ps.executeQuery()) {
				if (rs.next()) {
					int v = rs.getInt(1);
					return rs.wasNull() ? 0 : v;
				}
			}
		}
		return 0;
	}

	public void clearDeliveryAgent(int orderId) throws SQLException {
		if (orderId <= 0) {
			return;
		}
		String sql = "UPDATE orders SET delivery_user_id = NULL, status = 'Confirmed' WHERE order_id = ?";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, orderId);
			ps.executeUpdate();
		}
	}

	public void incrementStock(int productId, int qty) throws SQLException {
		if (productId <= 0 || qty <= 0) {
			return;
		}
		String sql = "UPDATE products SET stock = stock + ? WHERE product_id = ?";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, qty);
			ps.setInt(2, productId);
			ps.executeUpdate();
		}
	}

	public boolean updateReturnStatus(int orderId, String status) throws SQLException {
		String sql = "UPDATE order_returns SET status = ? WHERE order_id = ?";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setString(1, status);
			ps.setInt(2, orderId);
			return ps.executeUpdate() > 0;
		}
	}

	public Order cloneOrderForReplacement(int originalOrderId) throws SQLException {
		Order original = getOrderById(originalOrderId);
		if (original == null) {
			throw new SQLException("Original order not found: " + originalOrderId);
		}
		int newOrderId = createOrder(original.getCustomerId(), 0, 0, 0, 0, 0, 0, original.getItems(), "Replacement",
				original.getSnapAddressId(), original.getSnapStreet(), original.getSnapCity(),
				original.getSnapDistrict(), original.getSnapState(), original.getSnapCountry(),
				original.getSnapPincode());
		if (newOrderId != -1) {
			updateOrderStatus(newOrderId, "Confirmed");
			return getOrderById(newOrderId);
		}
		return null;
	}

	public int getAgentActiveOrderCount(int agentId) throws SQLException {
		String sql = "SELECT COUNT(*) FROM orders WHERE delivery_user_id = ? "
				+ "AND status NOT IN ('Delivered','Completed','Cancelled','Refunded','Replaced')";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, agentId);
			try (ResultSet rs = ps.executeQuery()) {
				return rs.next() ? rs.getInt(1) : 0;
			}
		}
	}

	// ─────────────────────────────────────────────────────────────────────────
	// Rejection log helpers (unchanged logic, kept intact)
	// ─────────────────────────────────────────────────────────────────────────
	public void logAgentRejection(int orderId, int agentId, String reason) throws SQLException {
		String createSql = "CREATE TABLE IF NOT EXISTS agent_rejection_log ("
				+ "  id INT AUTO_INCREMENT PRIMARY KEY, order_id INT NOT NULL, agent_id INT NOT NULL, "
				+ "  reason VARCHAR(500), rejected_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, "
				+ "  INDEX idx_agent(agent_id), INDEX idx_order(order_id))";
		String insertSql = "INSERT INTO agent_rejection_log (order_id, agent_id, reason) VALUES (?,?,?)";
		try (Connection conn = DBConnection.getConnection()) {
			try (PreparedStatement c = conn.prepareStatement(createSql)) {
				c.executeUpdate();
			}
			try (PreparedStatement ps = conn.prepareStatement(insertSql)) {
				ps.setInt(1, orderId);
				ps.setInt(2, agentId);
				ps.setString(3, reason != null ? reason : "No reason given");
				ps.executeUpdate();
			}
		}
	}

	public int getAgentRejectionCount(int agentId) throws SQLException {
		String existsSql = "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name='agent_rejection_log'";
		try (Connection conn = DBConnection.getConnection()) {
			try (PreparedStatement ex = conn.prepareStatement(existsSql); ResultSet exRs = ex.executeQuery()) {
				if (exRs.next() && exRs.getInt(1) == 0) {
					return 0;
				}
			}
			String countSql = "SELECT COUNT(*) AS cnt FROM agent_rejection_log WHERE agent_id=? AND DATE(rejected_at)=CURDATE()";
			try (PreparedStatement ps = conn.prepareStatement(countSql)) {
				ps.setInt(1, agentId);
				try (ResultSet rs = ps.executeQuery()) {
					return rs.next() ? rs.getInt("cnt") : 0;
				}
			}
		}
	}

	public void deleteSingleRejectionLog(int logId) throws SQLException {
		String sql = "DELETE FROM agent_rejection_log WHERE id = ?";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, logId);
			ps.executeUpdate();
		}
	}

	public void clearAgentRejectionLog(int agentId) throws SQLException {
		String existsSql = "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name='agent_rejection_log'";
		try (Connection conn = DBConnection.getConnection()) {
			try (PreparedStatement ex = conn.prepareStatement(existsSql); ResultSet exRs = ex.executeQuery()) {
				if (exRs.next() && exRs.getInt(1) == 0) {
					return;
				}
			}
			String sql = "DELETE FROM agent_rejection_log WHERE agent_id = ?";
			try (PreparedStatement ps = conn.prepareStatement(sql)) {
				ps.setInt(1, agentId);
				ps.executeUpdate();
			}
		}
	}

	public List<java.util.Map<String, Object>> getAgentRejectionLog(int agentId) throws SQLException {
		List<java.util.Map<String, Object>> rows = new ArrayList<>();
		String existsSql = "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name='agent_rejection_log'";
		try (Connection conn = DBConnection.getConnection()) {
			try (PreparedStatement ex = conn.prepareStatement(existsSql); ResultSet exRs = ex.executeQuery()) {
				if (exRs.next() && exRs.getInt(1) == 0) {
					return rows;
				}
			}
			String sql = "SELECT arl.id, arl.order_id, arl.reason, arl.rejected_at FROM agent_rejection_log arl WHERE arl.agent_id=? ORDER BY arl.rejected_at DESC";
			try (PreparedStatement ps = conn.prepareStatement(sql)) {
				ps.setInt(1, agentId);
				try (ResultSet rs = ps.executeQuery()) {
					while (rs.next()) {
						java.util.Map<String, Object> row = new java.util.LinkedHashMap<>();
						row.put("orderId", rs.getInt("order_id"));
						row.put("logId", rs.getInt("id"));
						row.put("reason", rs.getString("reason"));
						row.put("rejectedAt", rs.getTimestamp("rejected_at"));
						rows.add(row);
					}
				}
			}
		}
		return rows;
	}

	public List<java.util.Map<String, Object>> getAllAgentRejectionSummary() throws SQLException {
		List<java.util.Map<String, Object>> rows = new ArrayList<>();
		String existsSql = "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name='agent_rejection_log'";
		try (Connection conn = DBConnection.getConnection()) {
			try (PreparedStatement ex = conn.prepareStatement(existsSql); ResultSet exRs = ex.executeQuery()) {
				if (exRs.next() && exRs.getInt(1) == 0) {
					return rows;
				}
			}
			String sql = "SELECT arl.agent_id AS agentId, u.username AS agentName, COUNT(*) AS rejectionCount, u.status AS agentStatus "
					+ "FROM agent_rejection_log arl JOIN users u ON u.id=arl.agent_id GROUP BY arl.agent_id,u.username,u.status ORDER BY rejectionCount DESC";
			try (PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
				while (rs.next()) {
					java.util.Map<String, Object> row = new java.util.LinkedHashMap<>();
					row.put("agentId", rs.getInt("agentId"));
					row.put("agentName", rs.getString("agentName"));
					row.put("rejectionCount", rs.getInt("rejectionCount"));
					row.put("agentStatus", rs.getString("agentStatus"));
					rows.add(row);
				}
			}
		}
		return rows;
	}

	public List<java.util.Map<String, Object>> getRejectionLogForAgent(int agentId) throws SQLException {
		return getAgentRejectionLog(agentId);
	}

	// ─────────────────────────────────────────────────────────────────────────
	// getAllOrdersWithAudit
	// ─────────────────────────────────────────────────────────────────────────
	public List<Order> getAllOrdersWithAudit() throws SQLException {
		String sql = "SELECT o.order_id, o.customer_id, c.name AS customer_name, c.email AS customer_email, "
				+ "  o.order_date, o.status, o.subtotal, o.gst, o.tax, o.delivery_charge, "
				+ "  o.cod_charge, o.total_amount, o.delivery_date, o.payment_method, "
				+ "  o.payment_status, o.transaction_id, u.username AS delivery_user_name, "
				+ "  o.order_otp, o.delivery_user_id, "
				+ "  o.snap_address_id, o.snap_street, o.snap_city, o.snap_district, "
				+ "  o.snap_state, o.snap_country, o.snap_pincode, o.address_changed_at, " + SNAP_ADDR_EXPR
				+ "FROM orders o " + "JOIN customers c ON o.customer_id = c.customer_id "
				+ "LEFT JOIN users u ON o.delivery_user_id = u.id " + "ORDER BY o.order_date DESC";
		List<Order> orders = new ArrayList<>();
		try (Connection conn = DBConnection.getConnection();
				PreparedStatement ps = conn.prepareStatement(sql);
				ResultSet rs = ps.executeQuery()) {
			while (rs.next()) {
				Order order = mapFullRow(rs, false);
				order.setItems(getOrderItems(order.getId()));
				orders.add(order);
			}
		}
		return orders;
	}

	// ─────────────────────────────────────────────────────────────────────────
	// mapFullRow — single mapper used by all queries above
	// withSlot=true maps slot_id (only present when query selects it)
	// ─────────────────────────────────────────────────────────────────────────
	private Order mapFullRow(ResultSet rs, boolean withSlot) throws SQLException {
		Order o = new Order();
		o.setId(rs.getInt("order_id"));
		o.setCustomerId(rs.getInt("customer_id"));
		o.setDeliveryUserId(rs.getInt("delivery_user_id"));

		if (withSlot) {
			try {
				o.setSlotId(rs.getInt("slot_id"));
			} catch (SQLException ignored) {
			}
		}

		o.setDate(rs.getTimestamp("order_date"));

		String status = rs.getString("status");
		if (status == null || status.isBlank()) {
			status = o.calculateAutoStatus();
			try {
				updateOrderStatus(o.getId(), status);
			} catch (SQLException ignored) {
			}
		}
		o.setStatus(status);

		o.setSubtotal(rs.getDouble("subtotal"));
		o.setGst(rs.getDouble("gst"));
		o.setTax(rs.getDouble("tax"));
		o.setDeliveryCharge(rs.getDouble("delivery_charge"));
		o.setCodCharge(rs.getDouble("cod_charge"));
		o.setTotalAmount(rs.getDouble("total_amount"));
		o.setDeliveryDate(rs.getDate("delivery_date"));
		o.setPaymentMethod(rs.getString("payment_method"));
		o.setPaymentStatus(rs.getString("payment_status"));
		o.setTransactionId(rs.getString("transaction_id"));
		o.setOtp(rs.getInt("order_otp"));

		o.setCustomerName(rs.getString("customer_name"));
		o.setCustomerEmail(rs.getString("customer_email"));
		try {
			o.setPhone(rs.getString("customer_phone"));
		} catch (SQLException ignored) {
		}
		try {
			o.setDeliveryUserName(rs.getString("delivery_user_name"));
		} catch (SQLException ignored) {
		}

		// Snapshot address fields
		int snapId = rs.getInt("snap_address_id");
		o.setSnapAddressId(rs.wasNull() ? 0 : snapId);
		o.setSnapStreet(rs.getString("snap_street"));
		o.setSnapCity(rs.getString("snap_city"));
		o.setSnapDistrict(rs.getString("snap_district"));
		o.setSnapState(rs.getString("snap_state"));
		o.setSnapCountry(rs.getString("snap_country"));
		o.setSnapPincode(rs.getString("snap_pincode"));
		o.setAddress(rs.getString("delivery_address")); // CONCAT_WS of snapshots
		try {
			o.setAddressChangedAt(rs.getTimestamp("address_changed_at"));
		} catch (SQLException ignored) {
		}

		return o;
	}
}
