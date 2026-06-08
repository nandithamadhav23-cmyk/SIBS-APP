package com.DAO;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

import com.util.DBConnection;
import com.util.Product;

/**
 * ProductDAO — GST RATE FIX applied.
 *
 * CHANGES FROM ORIGINAL: 1. addProduct() — INSERT now includes gst_rate column.
 * 2. updateProduct() — UPDATE now includes gst_rate column. 3.
 * mapRowToProduct() — reads gst_rate from ResultSet and passes it to the new
 * Product constructor overload.
 *
 * DATABASE MIGRATION REQUIRED before deploying: ALTER TABLE products ADD COLUMN
 * gst_rate DECIMAL(5,2) NOT NULL DEFAULT 5.00 COMMENT '0=exempt, 5=basic food,
 * 12=processed, 18=general, 28=luxury';
 *
 * GST slab reference (India): 0% — Fresh vegetables, fruits, milk, eggs, rice,
 * wheat, salt 5% — Sugar, tea, coffee, edible oil, packaged paneer, spices 12%
 * — Butter, ghee, cheese, dry fruits, fruit juices 18% — Packaged food, snacks,
 * beverages, toiletries 28% — Aerated drinks, luxury / demerit goods
 */
public class ProductDAO {

	// ── Add Product ──────────────────────────────────────────────────────────

	/**
	 * GST FIX: gst_rate column added to INSERT. Previously only mrp/discount were
	 * stored; tax rate was hardcoded in PlaceOrderServlet. Now each product carries
	 * its own correct GST slab.
	 */
	public boolean addProduct(Product product) throws SQLException {
		String sql = "INSERT INTO products "
				+ "(name, mrp, quantity, unit, category, description, discount, imageUrl, addedDate, stock, status, gst_rate, deleted_at) "
				+ "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL)";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setString(1, product.getName());
			ps.setDouble(2, product.getMrp());
			ps.setInt(3, product.getQuantity());
			ps.setString(4, product.getUnit());
			ps.setString(5, product.getCategory());
			ps.setString(6, product.getDescription());
			ps.setDouble(7, product.getDiscount());
			ps.setString(8, product.getImageUrl());
			ps.setTimestamp(9, product.getAddedDate());
			ps.setInt(10, product.getStock());
			ps.setString(11, product.getStatus());
			ps.setDouble(12, product.getGstRate()); // GST FIX
			return ps.executeUpdate() > 0;
		}
	}

	// ── Map ResultSet row → Product object ───────────────────────────────────

	/**
	 * GST FIX: reads gst_rate from the result set. Uses the new Product constructor
	 * overload that accepts gstRate so the rate travels all the way to CartItem →
	 * CheckoutServlet → PlaceOrderServlet.
	 */
	private Product mapRowToProduct(ResultSet rs) throws SQLException {
		return new Product(rs.getInt("product_id"), rs.getString("name"), rs.getDouble("mrp"), rs.getString("unit"),
				rs.getInt("quantity"), rs.getDouble("discount"), rs.getString("category"), rs.getString("description"),
				rs.getString("imageUrl"), rs.getInt("stock"), rs.getTimestamp("addedDate"), rs.getDouble("final_price"),
				rs.getString("status"), rs.getTimestamp("deleted_at"), rs.getDouble("gst_rate") // GST FIX
		);
	}

	// ── Search ───────────────────────────────────────────────────────────────

	public List<Product> searchProducts(String query) throws SQLException {
		List<Product> list = new ArrayList<>();
		String sql = "SELECT * FROM products WHERE LOWER(name) LIKE ? OR LOWER(description) LIKE ? OR LOWER(category) LIKE ?";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			String likeQuery = "%" + query.toLowerCase().trim() + "%";
			ps.setString(1, likeQuery);
			ps.setString(2, likeQuery);
			ps.setString(3, likeQuery);
			try (ResultSet rs = ps.executeQuery()) {
				while (rs.next()) {
					list.add(mapRowToProduct(rs));
				}
			}
		}
		return list;
	}

	// ── Sort ─────────────────────────────────────────────────────────────────

	public List<Product> sortProducts(String sortBy) throws SQLException {
		List<Product> list = new ArrayList<>();
		String sql;
		switch (sortBy) {
		case "priceLow":
			sql = "SELECT * FROM products ORDER BY final_price ASC";
			break;
		case "priceHigh":
			sql = "SELECT * FROM products ORDER BY final_price DESC";
			break;
		case "newest":
			sql = "SELECT * FROM products ORDER BY addedDate DESC";
			break;
		case "popular":
			sql = "SELECT * FROM products ORDER BY quantity DESC";
			break;
		default:
			sql = "SELECT * FROM products";
		}
		try (Connection conn = DBConnection.getConnection();
				Statement st = conn.createStatement();
				ResultSet rs = st.executeQuery(sql)) {
			while (rs.next()) {
				list.add(mapRowToProduct(rs));
			}
		}
		return list;
	}

	// ── Paginated product listing ─────────────────────────────────────────────

	public List<Product> getProductsByPage(int offset, int limit) throws SQLException {
		List<Product> list = new ArrayList<>();
		String sql = "SELECT * FROM products WHERE status='active' AND deleted_at IS NULL "
				+ "ORDER BY product_id DESC LIMIT ? OFFSET ?";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, limit);
			ps.setInt(2, offset);
			try (ResultSet rs = ps.executeQuery()) {
				while (rs.next()) {
					list.add(mapRowToProduct(rs));
				}
			}
		}
		return list;
	}

	// ── Count ────────────────────────────────────────────────────────────────

	public int getTotalProducts() throws SQLException {
		String sql = "SELECT COUNT(*) FROM products";
		try (Connection conn = DBConnection.getConnection();
				PreparedStatement ps = conn.prepareStatement(sql);
				ResultSet rs = ps.executeQuery()) {
			return rs.next() ? rs.getInt(1) : 0;
		}
	}

	public int getProductCount() throws SQLException {
		String sql = "SELECT COUNT(*) FROM products";
		try (Connection conn = DBConnection.getConnection();
				Statement st = conn.createStatement();
				ResultSet rs = st.executeQuery(sql)) {
			return rs.next() ? rs.getInt(1) : 0;
		}
	}

	// ── Update Product ───────────────────────────────────────────────────────

	/**
	 * GST FIX: gst_rate column added to UPDATE. Admin can change the GST slab when
	 * editing a product (e.g. when the government revises GST rates for a
	 * category).
	 */
	public boolean updateProduct(Product product) throws SQLException {
		String sql = "UPDATE products "
				+ "SET name=?, mrp=?, quantity=?, unit=?, category=?, description=?, discount=?, "
				+ "    imageUrl=?, addedDate=?, stock=?, status=?, gst_rate=? " + "WHERE product_id=?";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setString(1, product.getName());
			ps.setDouble(2, product.getMrp());
			ps.setInt(3, product.getQuantity());
			ps.setString(4, product.getUnit());
			ps.setString(5, product.getCategory());
			ps.setString(6, product.getDescription());
			ps.setDouble(7, product.getDiscount());
			ps.setString(8, product.getImageUrl());
			ps.setTimestamp(9, product.getAddedDate());
			ps.setInt(10, product.getStock());
			ps.setString(11, product.getStatus());
			ps.setDouble(12, product.getGstRate()); // GST FIX
			ps.setInt(13, product.getId());
			return ps.executeUpdate() > 0;
		}
	}

	// ── Soft / Hard delete & Restore ─────────────────────────────────────────

	public boolean softDeleteProduct(int productId) throws SQLException {
		String sql = "UPDATE products SET status='inactive', deleted_at = CURRENT_TIMESTAMP WHERE product_id=?";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, productId);
			return ps.executeUpdate() > 0;
		}
	}

	public boolean restoreProduct(int productId) throws SQLException {
		String sql = "UPDATE products SET status='active', deleted_at = NULL WHERE product_id=?";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, productId);
			return ps.executeUpdate() > 0;
		}
	}

	public boolean hardDeleteProduct(int productId) throws SQLException {
		String sql = "DELETE FROM products WHERE product_id=?";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, productId);
			return ps.executeUpdate() > 0;
		}
	}

	// ── Get all / active / by id / by category ───────────────────────────────

	public List<Product> getAllProducts() throws SQLException {
		List<Product> list = new ArrayList<>();
		String sql = "SELECT * FROM products ORDER BY product_id DESC";
		try (Connection conn = DBConnection.getConnection();
				Statement st = conn.createStatement();
				ResultSet rs = st.executeQuery(sql)) {
			while (rs.next()) {
				list.add(mapRowToProduct(rs));
			}
		}
		return list;
	}

	public Product getProductById(int productId) throws SQLException {
		String sql = "SELECT * FROM products WHERE product_id=? AND deleted_at IS NULL";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, productId);
			try (ResultSet rs = ps.executeQuery()) {
				if (rs.next()) {
					return mapRowToProduct(rs);
				} else {
					throw new SQLException("No product found with id " + productId);
				}
			}
		}
	}

	public List<Product> getActiveProducts() throws SQLException {
		List<Product> list = new ArrayList<>();
		String sql = "SELECT * FROM products WHERE status='active' AND deleted_at IS NULL ORDER BY product_id DESC";
		try (Connection conn = DBConnection.getConnection();
				Statement st = conn.createStatement();
				ResultSet rs = st.executeQuery(sql)) {
			while (rs.next()) {
				list.add(mapRowToProduct(rs));
			}
		}
		return list;
	}

	public List<Product> getProductsByCategory(String category) throws SQLException {
		List<Product> list = new ArrayList<>();
		String sql = "SELECT * FROM products WHERE category = ? AND status='active' AND deleted_at IS NULL "
				+ "ORDER BY product_id DESC";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setString(1, category);
			try (ResultSet rs = ps.executeQuery()) {
				while (rs.next()) {
					list.add(mapRowToProduct(rs));
				}
			}
		}
		return list;
	}

	public List<Product> getProductsByCategoryPage(String category, int offset, int limit) throws SQLException {
		List<Product> list = new ArrayList<>();
		String sql = "SELECT * FROM products WHERE category = ? AND status='active' AND deleted_at IS NULL "
				+ "ORDER BY product_id DESC LIMIT ? OFFSET ?";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setString(1, category);
			ps.setInt(2, limit);
			ps.setInt(3, offset);
			try (ResultSet rs = ps.executeQuery()) {
				while (rs.next()) {
					list.add(mapRowToProduct(rs));
				}
			}
		}
		return list;
	}

	public int getProductCountByCategory(String category) throws SQLException {
		String sql = "SELECT COUNT(*) FROM products WHERE category = ? AND status='active' AND deleted_at IS NULL";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setString(1, category);
			try (ResultSet rs = ps.executeQuery()) {
				return rs.next() ? rs.getInt(1) : 0;
			}
		}
	}

	// ── Status ───────────────────────────────────────────────────────────────

	public boolean updateProductStatus(int productId, String status) throws SQLException {
		String sql = "UPDATE products SET status=? WHERE product_id=?";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setString(1, status);
			ps.setInt(2, productId);
			return ps.executeUpdate() > 0;
		}
	}

	// ── Stock ────────────────────────────────────────────────────────────────

	public boolean updateStock(int productId, int quantityPurchased) throws SQLException {
		String sql = "UPDATE products SET stock = stock - ? WHERE product_id = ? AND stock >= ?";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, quantityPurchased);
			ps.setInt(2, productId);
			ps.setInt(3, quantityPurchased); // ensures stock doesn't go negative
			return ps.executeUpdate() > 0;
		}
	}

	public boolean incrementStock(int productId, int quantity) throws SQLException {
		String sql = "UPDATE products SET stock = stock + ? WHERE product_id = ?";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, quantity);
			ps.setInt(2, productId);
			return ps.executeUpdate() > 0;
		}
	}
}
