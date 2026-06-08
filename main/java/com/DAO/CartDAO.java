package com.DAO;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

import com.util.CartItem;
import com.util.DBConnection;

/**
 * CartDAO — GST RATE FIX applied.
 *
 * CHANGES FROM ORIGINAL: 1. getCartProducts() — SELECT now includes p.gst_rate;
 * item.setGstRate() called. 2. getSavedItems() — same fix. 3.
 * getSingleProductForCheckout() — same fix (used by BuyNow flow).
 *
 * Every place that builds a CartItem from a DB row now carries the correct
 * per-product GST rate forward so CheckoutServlet and PlaceOrderServlet can
 * compute real GST instead of a flat 18 % + 5 % on everything.
 *
 * No schema change needed here — gst_rate is read from the products table that
 * already has the new column after the migration in ProductDAO.
 */
public class CartDAO {
	private Connection conn;

	public CartDAO() {
		try {
			Class.forName("com.mysql.cj.jdbc.Driver");
			conn = DBConnection.getConnection();
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	// ── Add / move / update / remove ─────────────────────────────────────────

	/** Add to active cart. Increments quantity on duplicate. */
	public void addToCart(int customerId, int productId, int quantity) throws SQLException {
		String sql = "INSERT INTO cart (customer_id, product_id, quantity, status) VALUES (?, ?, ?, 'ACTIVE') "
				+ "ON DUPLICATE KEY UPDATE quantity = quantity + ?, status = 'ACTIVE'";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, customerId);
			ps.setInt(2, productId);
			ps.setInt(3, quantity);
			ps.setInt(4, quantity);
			ps.executeUpdate();
		}
	}

	public void moveToSavedItems(int customerId, int productId) throws SQLException {
		String sql = "UPDATE cart SET status='SAVED' WHERE customer_id=? AND product_id=? AND status='ACTIVE'";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, customerId);
			ps.setInt(2, productId);
			ps.executeUpdate();
		}
	}

	public void moveToActiveCart(int customerId, int productId) throws SQLException {
		String sql = "UPDATE cart SET status='ACTIVE' WHERE customer_id=? AND product_id=? AND status='SAVED'";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, customerId);
			ps.setInt(2, productId);
			ps.executeUpdate();
		}
	}

	public void updateQuantity(int cartId, int quantity) throws SQLException {
		String sql = "UPDATE cart SET quantity = ? WHERE cart_id = ?";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, quantity);
			ps.setInt(2, cartId);
			ps.executeUpdate();
		}
	}

	public void updateStatus(int cartId, String status) throws SQLException {
		String sql = "UPDATE cart SET status=? WHERE cart_id=?";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setString(1, status);
			ps.setInt(2, cartId);
			ps.executeUpdate();
		}
	}

	public void removeFromCart(int cartId) throws SQLException {
		String sql = "DELETE FROM cart WHERE cart_id = ?";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, cartId);
			ps.executeUpdate();
		}
	}

	// ── Get active cart items ─────────────────────────────────────────────────

	/**
	 * GST FIX: added p.gst_rate to the SELECT and item.setGstRate() call.
	 *
	 * Previously the query did not fetch gst_rate, so every CartItem had the
	 * default 5% regardless of what was stored in the products table. Now the
	 * per-product rate is available to CheckoutServlet and PlaceOrderServlet for
	 * accurate tax calculation.
	 */
	public List<CartItem> getCartProducts(int customerId) throws SQLException {
		List<CartItem> items = new ArrayList<>();
		String sql = "SELECT c.cart_id, p.product_id, p.name, p.description, p.imageUrl, "
				+ "       c.quantity, p.final_price, p.discount, p.unit, p.stock, "
				+ "       p.quantity AS product_quantity, p.gst_rate " // GST FIX: added gst_rate
				+ "FROM cart c JOIN products p ON c.product_id = p.product_id "
				+ "WHERE c.customer_id = ? AND c.status = 'ACTIVE'";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, customerId);
			try (ResultSet rs = ps.executeQuery()) {
				while (rs.next()) {
					CartItem item = new CartItem();
					item.setCartId(rs.getInt("cart_id"));
					item.setProductId(rs.getInt("product_id"));
					item.setName(rs.getString("name"));
					item.setDescription(rs.getString("description"));
					item.setImageUrl(rs.getString("imageUrl"));
					item.setQuantity(rs.getInt("quantity"));
					item.setFinalPrice(rs.getDouble("final_price"));
					item.setDiscount(rs.getDouble("discount"));
					item.setProductQuantity(rs.getInt("product_quantity"));
					item.setUnit(rs.getString("unit"));
					item.setStock(rs.getInt("stock"));
					item.setGstRate(rs.getDouble("gst_rate")); // GST FIX
					items.add(item);
				}
			}
		}
		return items;
	}

	// ── Get saved-for-later items ─────────────────────────────────────────────

	/**
	 * GST FIX: same gst_rate addition as getCartProducts().
	 */
	public List<CartItem> getSavedItems(int customerId) throws SQLException {
		List<CartItem> items = new ArrayList<>();
		String sql = "SELECT c.cart_id, p.product_id, p.name, p.description, p.imageUrl, "
				+ "       c.quantity, p.final_price, p.discount, p.unit, p.stock, "
				+ "       p.quantity AS product_quantity, p.gst_rate " // GST FIX
				+ "FROM cart c JOIN products p ON c.product_id = p.product_id "
				+ "WHERE c.customer_id = ? AND c.status = 'SAVED'";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, customerId);
			try (ResultSet rs = ps.executeQuery()) {
				while (rs.next()) {
					CartItem item = new CartItem();
					item.setCartId(rs.getInt("cart_id"));
					item.setProductId(rs.getInt("product_id"));
					item.setName(rs.getString("name"));
					item.setDescription(rs.getString("description"));
					item.setImageUrl(rs.getString("imageUrl"));
					item.setQuantity(rs.getInt("quantity"));
					item.setFinalPrice(rs.getDouble("final_price"));
					item.setDiscount(rs.getDouble("discount"));
					item.setProductQuantity(rs.getInt("product_quantity"));
					item.setUnit(rs.getString("unit"));
					item.setStock(rs.getInt("stock"));
					item.setGstRate(rs.getDouble("gst_rate")); // GST FIX
					items.add(item);
				}
			}
		}
		return items;
	}

	// ── Single product for Buy-Now checkout ──────────────────────────────────

	/**
	 * GST FIX: added gst_rate to SELECT and setGstRate() call. This method is used
	 * by the Buy Now flow (PlaceOrderServlet with buyNow=true).
	 */
	public CartItem getSingleProductForCheckout(int customerId, int productId) throws SQLException {
		String sql = "SELECT p.product_id, p.name, p.description, p.imageUrl, "
				+ "       p.final_price, p.discount, p.unit, p.stock, "
				+ "       p.quantity AS product_quantity, p.gst_rate " // GST FIX
				+ "FROM products p WHERE p.product_id = ?";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, productId);
			try (ResultSet rs = ps.executeQuery()) {
				if (rs.next()) {
					CartItem item = new CartItem();
					item.setProductId(rs.getInt("product_id"));
					item.setName(rs.getString("name"));
					item.setDescription(rs.getString("description"));
					item.setImageUrl(rs.getString("imageUrl"));
					item.setFinalPrice(rs.getDouble("final_price"));
					item.setDiscount(rs.getDouble("discount"));
					item.setUnit(rs.getString("unit"));
					item.setStock(rs.getInt("stock"));
					item.setProductQuantity(rs.getInt("product_quantity"));
					item.setQuantity(1);
					item.setGstRate(rs.getDouble("gst_rate")); // GST FIX
					return item;
				}
			}
		}
		return null;
	}

	// ── Clear active cart after order ────────────────────────────────────────

	/**
	 * Clears only ACTIVE cart items (not saved-for-later) after order placement.
	 */
	public boolean clearCartByCustomer(int customerId) throws SQLException {
		String sql = "DELETE FROM cart WHERE customer_id = ? AND status = 'ACTIVE'";
		try (Connection c = DBConnection.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
			ps.setInt(1, customerId);
			return ps.executeUpdate() > 0;
		}
	}
}
