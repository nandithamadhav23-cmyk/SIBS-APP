package com.DAO;

import java.security.MessageDigest;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import com.servlet.DeliveryNotificationServlet;
import com.util.CartItem;
import com.util.Order;
import com.util.User;

public class DeliveryPersonDAO {

	private Connection conn;

	final OrderDAO odao = new OrderDAO();

	public DeliveryPersonDAO(Connection conn) {
		this.conn = conn;
	}

	public DeliveryPersonDAO() {
	}

	private String hashPassword(String password) {
		try {
			MessageDigest md = MessageDigest.getInstance("SHA-256");
			byte[] hashedBytes = md.digest(password.getBytes());

			StringBuilder sb = new StringBuilder();
			for (byte b : hashedBytes) {
				sb.append(String.format("%02x", b));
			}
			return sb.toString();

		} catch (Exception e) {
			throw new RuntimeException("Error hashing password", e);
		}
	}

	// 1. Validate Delivery User Login
	public User validateDeliveryUser(String username, String password) throws SQLException {
		// Compute hash of input password
		String pwd = hashPassword(password.trim()); // trim to avoid whitespace issues
		System.out.println("Computed hash for input password: " + pwd);

		// Query only by username/role/status, then compare hashes in Java
		String sql = "SELECT * FROM users WHERE username=? AND role='delivery' ";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setString(1, username);
			try (ResultSet rs = ps.executeQuery()) {
				if (rs.next()) {
					String storedHash = rs.getString("password");
					System.out.println("Stored hash from DB: " + storedHash);

					if (storedHash != null && storedHash.equals(pwd)) {
						System.out.println("Password hash matches. User validated.");
						User user = new User();
						user.setUid(rs.getInt("id"));
						user.setUsername(rs.getString("username"));
						user.setEmail(rs.getString("email"));
						user.setRole(rs.getString("role"));
						user.setStatus(rs.getString("status"));
						return user;
					} else {
						System.out.println("Hash mismatch! Computed vs stored do not match.");
						return null;
					}
				} else {
					System.out.println("No user found with username=" + username + " and role=delivery.");
					return null;
				}
			}
		}
	}

	/**
	 * Returns true if a delivery-role user with this username exists in the users
	 * table, regardless of password. Used by DeliveryLoginServlet to distinguish
	 * "wrong password" from "username not found" for admin-added agents who have no
	 * entry in the delivery_registration table.
	 */
	public boolean deliveryUsernameExists(String username) throws SQLException {
		String sql = "SELECT 1 FROM users WHERE username=? AND role='delivery' LIMIT 1";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setString(1, username);
			try (ResultSet rs = ps.executeQuery()) {
				return rs.next();
			}
		}
	}

	public List<Order> getAssignedOrders(int deliveryUserId) throws SQLException {
		List<Order> orders = new ArrayList<>();
		String sql = "SELECT o.*, c.name AS customerName, c.email AS customerEmail,c.phone AS phone,  CONCAT_WS(', ', c.landmark_street, c.city, c.district, c.state, c.country, c.pincode) AS full_address FROM orders o JOIN customers c ON o.customer_id = c.customer_id WHERE o.delivery_user_id=? ORDER BY o.order_date DESC"
				+ "";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, deliveryUserId);
			try (ResultSet rs = ps.executeQuery()) {
				while (rs.next()) {
					Order order = new Order();
					order.setId(rs.getInt("order_id"));
					order.setCustomerId(rs.getInt("customer_id"));
					order.setCustomerName(rs.getString("customerName"));
					order.setCustomerEmail(rs.getString("customerEmail"));
					order.setPhone(rs.getString("phone"));
					order.setStatus(rs.getString("status"));
					order.setDeliveryDate(rs.getDate("delivery_date"));
					order.setAddress(rs.getString("full_address"));
					order.setDeliveryCharge(rs.getDouble("delivery_charge"));
					order.setCodCharge(rs.getDouble("cod_charge"));
					order.setTotalAmount(rs.getDouble("total_amount"));
					order.setDeliveryDate(rs.getDate("delivery_date"));

					int oid = rs.getInt("order_id");
					List<CartItem> items = odao.getOrderItems(oid);
					order.setItems(items);
					order.setPaymentStatus(rs.getString("payment_status"));
					order.setPaymentMethod(rs.getString("payment_method"));
					orders.add(order);
				}
			}
		}
		return orders;
	}

	public List<User> getActiveDeliveryPersons() throws SQLException {
		List<User> deliveryPersons = new ArrayList<>();
		String sql = "SELECT u.*, ( " + "  SELECT COUNT(*) FROM orders o " + "  WHERE o.delivery_user_id = u.id "
				+ "  AND o.status IN ('Assigned', 'Picked Up', 'Out for Delivery', 'Return Agent Assigned', 'Return Out for Pickup') "
				+ ") AS active_order_count " + "FROM users u " + "WHERE u.role = 'delivery' AND u.status = 'Active' "
				+ "ORDER BY active_order_count ASC";

		try (PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
			while (rs.next()) {
				User user = new User();
				user.setUid(rs.getInt("id"));
				user.setUsername(rs.getString("username"));
				user.setEmail(rs.getString("email"));
				user.setMobileno(rs.getString("mobile"));
				user.setStatus(rs.getString("status"));

				// 🔥 ADD THIS LINE: This maps the SQL count to your Java object
				user.setPendingOrdersCount(rs.getInt("active_order_count"));

				deliveryPersons.add(user);
			}
		}
		return deliveryPersons;
	}

	// 3. Assign Delivery Person to an Order
	public boolean assignDeliveryPerson(int orderId, int deliveryUserId) throws SQLException {
		String sql = "UPDATE orders SET delivery_user_id=?, status='Assigned' WHERE order_id=?";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, deliveryUserId);
			ps.setInt(2, orderId);
			boolean ok = ps.executeUpdate() > 0;
			if (ok) {
				// Push notification — ADD THIS
				DeliveryNotificationServlet.push(conn, deliveryUserId, "ORDER_ASSIGNED",
						"New order assigned — #" + orderId, null, "📦", "amber", orderId);

			}
			return ok;
		}
	}

	public boolean updateUserStatus(int userId, String status) throws SQLException {
		String sql = "UPDATE users SET status=? WHERE id=?";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setString(1, status);
			ps.setInt(2, userId);
			return ps.executeUpdate() > 0;
		}
	}

	public String getDeliveryUserStatus(int userId) throws SQLException {
		String sql = "SELECT status FROM users WHERE id=? AND role='delivery'";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, userId);
			try (ResultSet rs = ps.executeQuery()) {
				if (rs.next()) {
					return rs.getString("status");
				}
			}
		}
		return null; // return null if no record found
	}

	public User getDeliveryUserById(int userId) throws SQLException {
		User user = null;
		// We select all the specific columns needed for a single agent
		String sql = "SELECT id, username, email, status, mobile FROM users WHERE id=? AND role='delivery'";

		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, userId);

			try (ResultSet rs = ps.executeQuery()) {
				// Use 'if' instead of 'while' because we only expect one (or zero) results
				if (rs.next()) {
					user = new User();
					user.setUid(rs.getInt("id"));
					user.setUsername(rs.getString("username"));
					user.setEmail(rs.getString("email"));
					user.setMobileno(rs.getString("mobile"));
					user.setStatus(rs.getString("status"));
				}
			}
		}
		return user; // Returns the populated User object, or null if no agent matched the ID
	}

	public Map<Integer, Integer> getAssignedTaskCounts() throws SQLException {
		Map<Integer, Integer> counts = new HashMap<>();
		String sql = "SELECT delivery_user_id, COUNT(*) AS taskCount " + "FROM orders "
				+ "WHERE delivery_user_id IS NOT NULL " + "AND status NOT IN ('Delivered','Cancelled') "
				+ "GROUP BY delivery_user_id";
		try (PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
			while (rs.next()) {
				counts.put(rs.getInt("delivery_user_id"), rs.getInt("taskCount"));
			}
		}
		return counts;
	}
}
