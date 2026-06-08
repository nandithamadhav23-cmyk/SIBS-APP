package com.DAO;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

import com.util.Customer;
import com.util.DBConnection;
import com.util.Invoice;
import com.util.Product;

public class CustomerDAO {
	private Connection conn;

	public CustomerDAO() {
		try {
			Class.forName("com.mysql.cj.jdbc.Driver");
			conn = DBConnection.getConnection();
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	private String hashPassword(String password) {
		try {
			MessageDigest md = MessageDigest.getInstance("SHA-256");
			byte[] hash = md.digest(password.getBytes());
			StringBuilder sb = new StringBuilder();
			for (byte b : hash) {
				sb.append(String.format("%02x", b));
			}
			return sb.toString();
		} catch (NoSuchAlgorithmException e) {
			throw new RuntimeException(e);
		}
	}

	// ── Dashboard metrics ─────────────────────────────────────────────────
	public int getTotalOrders(int customerId) throws SQLException {
		String sql = "SELECT COUNT(*) FROM Orders WHERE customer_id=?";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, customerId);
			ResultSet rs = ps.executeQuery();
			return rs.next() ? rs.getInt(1) : 0;
		}
	}

	public double getTotalSpent(int customerId) throws SQLException {
		String sql = "SELECT COALESCE(SUM(total_amount),0) FROM Orders WHERE customer_id=? AND status != 'Cancelled'";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, customerId);
			ResultSet rs = ps.executeQuery();
			return rs.next() ? rs.getDouble(1) : 0.0;
		}
	}

	public int getWishlistCount(int customerId) throws SQLException {
		String sql = "SELECT COUNT(*) FROM Wishlist WHERE customer_id=?";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, customerId);
			ResultSet rs = ps.executeQuery();
			return rs.next() ? rs.getInt(1) : 0;
		}
	}

	// ── Invoices ──────────────────────────────────────────────────────────
	public List<Invoice> getInvoices(int customerId) throws SQLException {
		List<Invoice> invoices = new ArrayList<>();
		String sql = "SELECT i.* FROM Invoices i JOIN Orders o ON i.order_id=o.order_id WHERE o.customer_id=?";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, customerId);
			ResultSet rs = ps.executeQuery();
			while (rs.next()) {
				invoices.add(new Invoice(rs.getInt("invoice_id"), rs.getInt("order_id"), rs.getDate("issue_date"),
						rs.getString("payment_status"), rs.getString("pdf_link")));
			}
		}
		return invoices;
	}

	// ── Wishlist ──────────────────────────────────────────────────────────
	/**
	 * BUG FIX: Original code created Product objects with `new Product(...)` but
	 * never called wishlist.add(...), so it always returned an empty list. Also
	 * fixed: SQL used p.price (wrong column), now uses p.mrp and all columns the
	 * Product constructor needs. Column w.added_date aliased to added_date for
	 * clarity.
	 */
	public List<Product> getWishlist(int customerId) throws SQLException {
		List<Product> wishlist = new ArrayList<>();
		String sql = "SELECT p.product_id, p.name, p.mrp, p.unit, p.quantity, p.discount, "
				+ "p.category, p.description, p.imageUrl, p.stock, p.addedDate, "
				+ "p.final_price, p.status, w.added_date AS wish_date "
				+ "FROM Wishlist w JOIN Products p ON w.product_id = p.product_id "
				+ "WHERE w.customer_id = ? ORDER BY w.added_date DESC";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, customerId);
			try (ResultSet rs = ps.executeQuery()) {
				while (rs.next()) {
					// BUG FIX: add() call was missing — products were created but discarded
					Product p = new Product(rs.getInt("product_id"), rs.getString("name"), rs.getDouble("mrp"),
							rs.getString("unit"), rs.getInt("quantity"), rs.getDouble("discount"),
							rs.getString("category"), rs.getString("description"), rs.getString("imageUrl"),
							rs.getInt("stock"), rs.getTimestamp("addedDate"), rs.getDouble("final_price"),
							rs.getString("status"), null // deleted_at
					);
					wishlist.add(p); // ← THE FIX
				}
			}
		}
		return wishlist;
	}

	/**
	 * Add a product to wishlist. Uses INSERT IGNORE so duplicate adds are silent.
	 */
	public void addToWishlist(int customerId, int productId) throws SQLException {
		String sql = "INSERT IGNORE INTO Wishlist (customer_id, product_id, added_date) VALUES (?, ?, NOW())";
		try (Connection c = DBConnection.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
			ps.setInt(1, customerId);
			ps.setInt(2, productId);
			ps.executeUpdate();
		}
	}

	public void removeWishlistItem(int customerId, int productId) throws SQLException {
		String sql = "DELETE FROM Wishlist WHERE customer_id=? AND product_id=?";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, customerId);
			ps.setInt(2, productId);
			ps.executeUpdate();
		}
	}

	public boolean isInWishlist(int customerId, int productId) throws SQLException {
		String sql = "SELECT 1 FROM Wishlist WHERE customer_id=? AND product_id=?";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, customerId);
			ps.setInt(2, productId);
			ResultSet rs = ps.executeQuery();
			return rs.next();
		}
	}

	// ── Customer Profile ──────────────────────────────────────────────────
	public Customer getProfile(int customerId) throws SQLException {
		String sql = "SELECT * FROM Customers WHERE customer_id=?";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, customerId);
			ResultSet rs = ps.executeQuery();
			if (rs.next()) {
				Customer c = new Customer(rs.getInt("customer_id"), rs.getString("name"), rs.getString("email"),
						rs.getString("phone"), rs.getString("landmark_street"), rs.getString("city"),
						rs.getString("district"), rs.getString("state"), rs.getString("country"),
						rs.getString("pincode"), rs.getString("role"), rs.getString("gender"));
				// Load profile image if column exists
				try {
					c.setProfileImage(rs.getString("profile_image"));
				} catch (Exception ignored) {
				}
				return c;
			}
		}
		return null;
	}

	/** Save profile image filename for a customer. */
	public boolean updateProfileImage(int customerId, String filename) {
		String sql = "UPDATE Customers SET profile_image=? WHERE customer_id=?";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			if (filename != null) {
				ps.setString(1, filename);
			} else {
				ps.setNull(1, java.sql.Types.VARCHAR);
			}
			ps.setInt(2, customerId);
			return ps.executeUpdate() > 0;
		} catch (Exception e) {
			e.printStackTrace();
		}
		return false;
	}

	public boolean customerExists(String email) throws SQLException {
		String sql = "SELECT customer_id FROM Customers WHERE email=?";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setString(1, email);
			return ps.executeQuery().next();
		}
	}

	public void updateProfile(int customerId, String name, String email, String phone, String landmarkStreet,
			String city, String district, String state, String country, String pincode, String password, String gender)
			throws SQLException {
		// BUG FIX: only update password_hash if a new password was provided.
		// Passing an empty/null password to hashPassword() would corrupt the hash.
		if (password != null && !password.isBlank()) {
			String sql = "UPDATE Customers SET name=?,email=?,phone=?,landmark_street=?,city=?,"
					+ "district=?,state=?,country=?,pincode=?,password_hash=?,gender=? WHERE customer_id=?";
			try (PreparedStatement ps = conn.prepareStatement(sql)) {
				ps.setString(1, name);
				ps.setString(2, email);
				ps.setString(3, phone);
				ps.setString(4, landmarkStreet);
				ps.setString(5, city);
				ps.setString(6, district);
				ps.setString(7, state);
				ps.setString(8, country);
				ps.setString(9, pincode);
				ps.setString(10, hashPassword(password));
				ps.setString(11, gender);
				ps.setInt(12, customerId);
				ps.executeUpdate();
			}
		} else {
			String sql = "UPDATE Customers SET name=?,email=?,phone=?,landmark_street=?,city=?,"
					+ "district=?,state=?,country=?,pincode=?,gender=? WHERE customer_id=?";
			try (PreparedStatement ps = conn.prepareStatement(sql)) {
				ps.setString(1, name);
				ps.setString(2, email);
				ps.setString(3, phone);
				ps.setString(4, landmarkStreet);
				ps.setString(5, city);
				ps.setString(6, district);
				ps.setString(7, state);
				ps.setString(8, country);
				ps.setString(9, pincode);
				ps.setString(10, gender);
				ps.setInt(11, customerId);
				ps.executeUpdate();
			}
		}
	}

	public void registerCustomer(String name, String email, String phone, String landmarkStreet, String city,
			String district, String state, String country, String pincode, String gender, String password)
			throws SQLException {
		String sql = "INSERT INTO Customers(name,email,phone,landmark_street,city,district,state,"
				+ "country,pincode,gender,password_hash,role) VALUES(?,?,?,?,?,?,?,?,?,?,?,?)";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setString(1, name);
			ps.setString(2, email);
			ps.setString(3, phone);
			ps.setString(4, landmarkStreet);
			ps.setString(5, city);
			ps.setString(6, district);
			ps.setString(7, state);
			ps.setString(8, country);
			ps.setString(9, pincode);
			ps.setString(10, gender);
			ps.setString(11, hashPassword(password));
			ps.setString(12, "customer");
			ps.executeUpdate();
		}
	}

	public int validateLogin(String email, String password) throws SQLException {
		String sql = "SELECT customer_id FROM Customers WHERE email=? AND password_hash=?";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setString(1, email);
			ps.setString(2, hashPassword(password));
			ResultSet rs = ps.executeQuery();
			return rs.next() ? rs.getInt("customer_id") : -1;
		}
	}

	public int findOrCreateGoogleUser(String googleId, String email, String name, String picture) throws SQLException {
		try (PreparedStatement ps = conn.prepareStatement("SELECT customer_id FROM customers WHERE google_id = ?")) {
			ps.setString(1, googleId);
			ResultSet rs = ps.executeQuery();
			if (rs.next()) {
				return rs.getInt("customer_id");
			}
		}
		try (PreparedStatement ps = conn.prepareStatement("SELECT customer_id FROM customers WHERE email = ?")) {
			ps.setString(1, email);
			ResultSet rs = ps.executeQuery();
			if (rs.next()) {
				int existingId = rs.getInt("customer_id");
				try (PreparedStatement up = conn
						.prepareStatement("UPDATE customers SET google_id=?,profile_pic=? WHERE customer_id=?")) {
					up.setString(1, googleId);
					up.setString(2, picture);
					up.setInt(3, existingId);
					up.executeUpdate();
				}
				return existingId;
			}
		}
		try (PreparedStatement ps = conn.prepareStatement(
				"INSERT INTO customers (google_id,name,email,profile_pic,role) VALUES (?,?,?,?,'customer')",
				Statement.RETURN_GENERATED_KEYS)) {
			ps.setString(1, googleId);
			ps.setString(2, name);
			ps.setString(3, email);
			ps.setString(4, picture);
			ps.executeUpdate();
			ResultSet rs = ps.getGeneratedKeys();
			return rs.next() ? rs.getInt(1) : -1;
		}
	}

	public boolean existsByContact(String contact, String method) throws SQLException {
		String column = "email".equals(method) ? "email" : "phone";
		String sql = "SELECT customer_id FROM Customers WHERE " + column + " = ?";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			String q = (method.equals("mobile") && !contact.startsWith("+")) ? "+" + contact.trim() : contact.trim();
			ps.setString(1, q);
			return ps.executeQuery().next();
		}
	}

	public boolean updatePasswordByContact(String contact, String method, String hashedPassword) throws SQLException {
		String column = "email".equals(method) ? "email" : "phone";
		String sql = "UPDATE Customers SET password_hash = ? WHERE " + column + " = ?";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setString(1, hashedPassword);
			ps.setString(2, contact);
			return ps.executeUpdate() > 0;
		}
	}
}
