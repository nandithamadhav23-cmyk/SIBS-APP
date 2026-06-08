package com.DAO;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import com.util.DBConnection;

/**
 * ReportDAO — Central data-access object for the Analytics & Reports Dashboard.
 *
 * Covers: 1. Revenue / Financial KPIs (orders, revenue by period) 2. Product
 * metrics (top sellers, low stock, category breakdown) 3. Staff Attendance
 * summary (present / late / absent / on-leave by date range) 4. Leave analytics
 * (leave type usage, pending approvals) 5. Delivery agent metrics (deliveries
 * count, on-time %, earnings) 6. Customer growth (new registrations by month)
 * 7. Monthly revenue trend (last 12 months) 8. Order status breakdown (placed /
 * confirmed / delivered / cancelled)
 */
public class ReportDAO {

	// ════════════════════════════════════════════════════════════════
	// 1. REVENUE / FINANCIAL KPIs
	// ════════════════════════════════════════════════════════════════

	/** Total revenue (sum of total_amount from delivered/confirmed orders). */
	public double getTotalRevenue() throws SQLException {
		String sql = "SELECT COALESCE(SUM(total_amount),0) FROM orders "
				+ "WHERE status NOT IN ('Cancelled','Return Requested','Refunded','Replaced')";
		try (Connection con = DBConnection.getConnection();
				PreparedStatement ps = con.prepareStatement(sql);
				ResultSet rs = ps.executeQuery()) {
			return rs.next() ? rs.getDouble(1) : 0;
		}
	}

	/** Revenue for the current calendar month. */
	public double getRevenueThisMonth() throws SQLException {
		String sql = "SELECT COALESCE(SUM(total_amount),0) FROM orders "
				+ "WHERE MONTH(order_date)=MONTH(CURDATE()) AND YEAR(order_date)=YEAR(CURDATE()) "
				+ "AND status NOT IN ('Cancelled','Return Requested','Refunded','Replaced')";
		try (Connection con = DBConnection.getConnection();
				PreparedStatement ps = con.prepareStatement(sql);
				ResultSet rs = ps.executeQuery()) {
			return rs.next() ? rs.getDouble(1) : 0;
		}
	}

	/** Revenue for the previous calendar month (for % change calculation). */
	public double getRevenueLastMonth() throws SQLException {
		String sql = "SELECT COALESCE(SUM(total_amount),0) FROM orders "
				+ "WHERE MONTH(order_date)=MONTH(DATE_SUB(CURDATE(),INTERVAL 1 MONTH)) "
				+ "AND YEAR(order_date)=YEAR(DATE_SUB(CURDATE(),INTERVAL 1 MONTH)) "
				+ "AND status NOT IN ('Cancelled','Return Requested','Refunded','Replaced')";
		try (Connection con = DBConnection.getConnection();
				PreparedStatement ps = con.prepareStatement(sql);
				ResultSet rs = ps.executeQuery()) {
			return rs.next() ? rs.getDouble(1) : 0;
		}
	}

	/** Total number of orders (all statuses). */
	public int getTotalOrders() throws SQLException {
		String sql = "SELECT COUNT(*) FROM orders";
		try (Connection con = DBConnection.getConnection();
				PreparedStatement ps = con.prepareStatement(sql);
				ResultSet rs = ps.executeQuery()) {
			return rs.next() ? rs.getInt(1) : 0;
		}
	}

	/** Orders this month. */
	public int getOrdersThisMonth() throws SQLException {
		String sql = "SELECT COUNT(*) FROM orders "
				+ "WHERE MONTH(order_date)=MONTH(CURDATE()) AND YEAR(order_date)=YEAR(CURDATE())";
		try (Connection con = DBConnection.getConnection();
				PreparedStatement ps = con.prepareStatement(sql);
				ResultSet rs = ps.executeQuery()) {
			return rs.next() ? rs.getInt(1) : 0;
		}
	}

	/**
	 * Monthly revenue for the last N months. Returns list of {month:"Jan 2025",
	 * revenue:12345.0}
	 */
	public List<Map<String, Object>> getMonthlyRevenueTrend(int months) throws SQLException {
		String sql = "SELECT DATE_FORMAT(order_date,'%b %Y') AS month, "
				+ "       YEAR(order_date) AS yr, MONTH(order_date) AS mo, "
				+ "       COALESCE(SUM(total_amount),0) AS revenue " + "FROM orders "
				+ "WHERE order_date >= DATE_SUB(CURDATE(), INTERVAL ? MONTH) "
				+ "  AND status NOT IN ('Cancelled','Return Requested','Refunded','Replaced') "
				+ "GROUP BY yr, mo, month " + "ORDER BY yr ASC, mo ASC";
		List<Map<String, Object>> list = new ArrayList<>();
		try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
			ps.setInt(1, months);
			try (ResultSet rs = ps.executeQuery()) {
				while (rs.next()) {
					Map<String, Object> row = new LinkedHashMap<>();
					row.put("month", rs.getString("month"));
					row.put("revenue", rs.getDouble("revenue"));
					list.add(row);
				}
			}
		}
		return list;
	}

	/**
	 * Order status breakdown. Returns list of {status:"delivered", count:42}
	 */
	public List<Map<String, Object>> getOrderStatusBreakdown() throws SQLException {
		String sql = "SELECT status, COUNT(*) AS cnt FROM orders GROUP BY status ORDER BY cnt DESC";
		List<Map<String, Object>> list = new ArrayList<>();
		try (Connection con = DBConnection.getConnection();
				PreparedStatement ps = con.prepareStatement(sql);
				ResultSet rs = ps.executeQuery()) {
			while (rs.next()) {
				Map<String, Object> row = new LinkedHashMap<>();
				row.put("status", rs.getString("status"));
				row.put("count", rs.getInt("cnt"));
				list.add(row);
			}
		}
		return list;
	}

	/** Average order value. */
	public double getAvgOrderValue() throws SQLException {
		String sql = "SELECT COALESCE(AVG(total_amount),0) FROM orders "
				+ "WHERE status NOT IN ('Cancelled','Return Requested','Refunded','Replaced')";
		try (Connection con = DBConnection.getConnection();
				PreparedStatement ps = con.prepareStatement(sql);
				ResultSet rs = ps.executeQuery()) {
			return rs.next() ? rs.getDouble(1) : 0;
		}
	}

	// ════════════════════════════════════════════════════════════════
	// 2. PRODUCT METRICS
	// ════════════════════════════════════════════════════════════════

	/** Total active products. */
	public int getTotalActiveProducts() throws SQLException {
		String sql = "SELECT COUNT(*) FROM products WHERE deleted_at IS NULL AND status='active'";
		try (Connection con = DBConnection.getConnection();
				PreparedStatement ps = con.prepareStatement(sql);
				ResultSet rs = ps.executeQuery()) {
			return rs.next() ? rs.getInt(1) : 0;
		}
	}

	/** Products with stock <= threshold (low stock alert). */
	public int getLowStockCount(int threshold) throws SQLException {
		String sql = "SELECT COUNT(*) FROM products WHERE stock <= ? AND deleted_at IS NULL";
		try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
			ps.setInt(1, threshold);
			try (ResultSet rs = ps.executeQuery()) {
				return rs.next() ? rs.getInt(1) : 0;
			}
		}
	}

	/**
	 * Top N best-selling products by units sold. Returns list of {name, units_sold,
	 * revenue}
	 */
	public List<Map<String, Object>> getTopProducts(int limit) throws SQLException {
		String sql = "SELECT p.name, SUM(c.quantity) AS units_sold, "
				+ "       SUM(c.quantity * p.final_price) AS revenue " + "FROM cart c "
				+ "JOIN products p ON p.product_id = c.product_id "
				+ "JOIN orders o   ON o.customer_id = c.customer_id "
				+ "WHERE o.status NOT IN ('Cancelled','Return Requested','Refunded') " + "  AND c.status = 'ACTIVE' "
				+ "  AND p.deleted_at IS NULL " + "GROUP BY p.product_id, p.name " + "ORDER BY units_sold DESC LIMIT ?";
		List<Map<String, Object>> list = new ArrayList<>();
		try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
			ps.setInt(1, limit);
			try (ResultSet rs = ps.executeQuery()) {
				while (rs.next()) {
					Map<String, Object> row = new LinkedHashMap<>();
					row.put("name", rs.getString("name"));
					row.put("units_sold", rs.getInt("units_sold"));
					row.put("revenue", rs.getDouble("revenue"));
					list.add(row);
				}
			}
		}
		return list;
	}

	/**
	 * Revenue breakdown by product category. Returns list of {category, revenue}
	 */
	public List<Map<String, Object>> getRevenuByCategory() throws SQLException {
		String sql = "SELECT p.category, COALESCE(SUM(o.total_amount),0) AS revenue " + "FROM orders o "
				+ "JOIN cart c ON c.customer_id = o.customer_id AND c.status='ACTIVE' "
				+ "JOIN products p ON p.product_id = c.product_id " + "WHERE o.status NOT IN ('Cancelled','Refunded') "
				+ "  AND p.deleted_at IS NULL " + "GROUP BY p.category ORDER BY revenue DESC";
		List<Map<String, Object>> list = new ArrayList<>();
		try (Connection con = DBConnection.getConnection();
				PreparedStatement ps = con.prepareStatement(sql);
				ResultSet rs = ps.executeQuery()) {
			while (rs.next()) {
				Map<String, Object> row = new LinkedHashMap<>();
				row.put("category", rs.getString("category"));
				row.put("revenue", rs.getDouble("revenue"));
				list.add(row);
			}
		}
		return list;
	}

	// ════════════════════════════════════════════════════════════════
	// 3. STAFF ATTENDANCE METRICS
	// ════════════════════════════════════════════════════════════════

	/**
	 * Attendance summary for a given date range. Returns {total_staff, present,
	 * late, absent, on_leave, avg_hours}
	 */
	public Map<String, Object> getAttendanceSummary(String fromDate, String toDate) throws SQLException {
		// Count distinct users per status in the attendance_sessions table
		String sql = "SELECT " + "  COUNT(DISTINCT u.id)                                              AS total_staff, "
				+ "  SUM(CASE WHEN a.attendance_status IN ('full_day','overtime') "
				+ "           THEN 1 ELSE 0 END)                                       AS present, "
				+ "  SUM(CASE WHEN a.attendance_status = 'late'  THEN 1 ELSE 0 END)   AS late, "
				+ "  SUM(CASE WHEN a.attendance_status = 'absent' THEN 1 ELSE 0 END)  AS absent, "
				+ "  SUM(CASE WHEN a.attendance_status IN ('half_day','auto_close') "
				+ "           THEN 1 ELSE 0 END)                                       AS half_day, "
				+ "  COALESCE(AVG(a.net_work_ms)/3600000.0, 0)                    AS avg_hours " + "FROM users u "
				+ " LEFT JOIN attendance_sessions a ON a.username = u.username "
				+ "   AND DATE(a.punch_in) BETWEEN ? AND ? " + "WHERE u.role IN ('staff','admin')";
		Map<String, Object> map = new LinkedHashMap<>();
		try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
			ps.setString(1, fromDate);
			ps.setString(2, toDate);
			try (ResultSet rs = ps.executeQuery()) {
				if (rs.next()) {
					map.put("total_staff", rs.getInt("total_staff"));
					map.put("present", rs.getInt("present"));
					map.put("late", rs.getInt("late"));
					map.put("absent", rs.getInt("absent"));
					map.put("half_day", rs.getInt("half_day"));
					map.put("avg_hours", Math.round(rs.getDouble("avg_hours") * 10.0) / 10.0);
				}
			}
		}
		return map;
	}

	/**
	 * Daily attendance counts for the last 30 days (for area chart). Returns list
	 * of {date, present, absent, late}
	 */
	public List<Map<String, Object>> getDailyAttendanceTrend(int days) throws SQLException {
		String sql = "SELECT DATE(punch_in) AS att_date, "
				+ "  SUM(CASE WHEN attendance_status IN ('full_day','overtime') THEN 1 ELSE 0 END) AS present, "
				+ "  SUM(CASE WHEN attendance_status = 'late' THEN 1 ELSE 0 END)                  AS late, "
				+ "  SUM(CASE WHEN attendance_status = 'absent' THEN 1 ELSE 0 END)                AS absent "
				+ "FROM attendance_sessions " + "WHERE punch_in >= DATE_SUB(CURDATE(), INTERVAL ? DAY) "
				+ "GROUP BY att_date ORDER BY att_date ASC";
		List<Map<String, Object>> list = new ArrayList<>();
		try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
			ps.setInt(1, days);
			try (ResultSet rs = ps.executeQuery()) {
				while (rs.next()) {
					Map<String, Object> row = new LinkedHashMap<>();
					row.put("date", rs.getString("att_date"));
					row.put("present", rs.getInt("present"));
					row.put("late", rs.getInt("late"));
					row.put("absent", rs.getInt("absent"));
					list.add(row);
				}
			}
		}
		return list;
	}

	// ════════════════════════════════════════════════════════════════
	// 4. LEAVE ANALYTICS
	// ════════════════════════════════════════════════════════════════

	/**
	 * Leave summary for current year: total applied, approved, rejected, pending.
	 */
	public Map<String, Object> getLeaveSummary() throws SQLException {
		String sql = "SELECT " + "  COUNT(*)                                                      AS total, "
				+ "  SUM(CASE WHEN status='approved' THEN 1 ELSE 0 END)            AS approved, "
				+ "  SUM(CASE WHEN status='rejected' THEN 1 ELSE 0 END)            AS rejected, "
				+ "  SUM(CASE WHEN status='pending'  THEN 1 ELSE 0 END)            AS pending, "
				+ "  COALESCE(SUM(CASE WHEN status='approved' THEN total_days ELSE 0 END),0) AS approved_days "
				+ "FROM leave_requests " + "WHERE YEAR(applied_on) = YEAR(CURDATE())";
		Map<String, Object> map = new LinkedHashMap<>();
		try (Connection con = DBConnection.getConnection();
				PreparedStatement ps = con.prepareStatement(sql);
				ResultSet rs = ps.executeQuery()) {
			if (rs.next()) {
				map.put("total", rs.getInt("total"));
				map.put("approved", rs.getInt("approved"));
				map.put("rejected", rs.getInt("rejected"));
				map.put("pending", rs.getInt("pending"));
				map.put("approved_days", rs.getDouble("approved_days"));
			}
		}
		return map;
	}

	/**
	 * Leave usage by type (for doughnut chart). Returns list of {type_name,
	 * used_days}
	 */
	public List<Map<String, Object>> getLeaveByType() throws SQLException {
		String sql = "SELECT lt.type_name, " + "  COALESCE(SUM(lr.total_days),0) AS used_days " + "FROM leave_types lt "
				+ "LEFT JOIN leave_requests lr ON lr.leave_type_id = lt.id " + "  AND lr.status = 'approved' "
				+ "  AND YEAR(lr.applied_on) = YEAR(CURDATE()) "
				+ "GROUP BY lt.id, lt.type_name ORDER BY used_days DESC";
		List<Map<String, Object>> list = new ArrayList<>();
		try (Connection con = DBConnection.getConnection();
				PreparedStatement ps = con.prepareStatement(sql);
				ResultSet rs = ps.executeQuery()) {
			while (rs.next()) {
				Map<String, Object> row = new LinkedHashMap<>();
				row.put("type_name", rs.getString("type_name"));
				row.put("used_days", rs.getDouble("used_days"));
				list.add(row);
			}
		}
		return list;
	}

	// ════════════════════════════════════════════════════════════════
	// 5. DELIVERY AGENT METRICS
	// ════════════════════════════════════════════════════════════════

	/** Total active delivery agents. */
	public int getTotalDeliveryAgents() throws SQLException {
		String sql = "SELECT COUNT(*) FROM users WHERE role='delivery' AND status='Active'";
		try (Connection con = DBConnection.getConnection();
				PreparedStatement ps = con.prepareStatement(sql);
				ResultSet rs = ps.executeQuery()) {
			return rs.next() ? rs.getInt(1) : 0;
		}
	}

	/**
	 * Per-agent delivery stats for top N agents. Returns list of {agent_name,
	 * total_deliveries, delivered, pending, cancelled}
	 */
	public List<Map<String, Object>> getAgentDeliveryStats(int limit) throws SQLException {
		String sql = "SELECT u.username AS agent_name, " + "  COUNT(o.order_id) AS total_deliveries, "
				+ "  SUM(CASE WHEN o.status='Delivered' THEN 1 ELSE 0 END) AS delivered, "
				+ "  SUM(CASE WHEN o.status IN ('Assigned','Out for Delivery') THEN 1 ELSE 0 END) AS in_progress, "
				+ "  SUM(CASE WHEN o.status='Cancelled' THEN 1 ELSE 0 END) AS cancelled " + "FROM users u "
				+ "JOIN orders o ON o.delivery_user_id = u.id " + "WHERE u.role='delivery' "
				+ "GROUP BY u.id, u.username " + "ORDER BY total_deliveries DESC " + "LIMIT ?";
		List<Map<String, Object>> list = new ArrayList<>();
		try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
			ps.setInt(1, limit);
			try (ResultSet rs = ps.executeQuery()) {
				while (rs.next()) {
					Map<String, Object> row = new LinkedHashMap<>();
					row.put("agent_name", rs.getString("agent_name"));
					row.put("total_deliveries", rs.getInt("total_deliveries"));
					row.put("delivered", rs.getInt("delivered"));
					row.put("in_progress", rs.getInt("in_progress"));
					row.put("cancelled", rs.getInt("cancelled"));
					list.add(row);
				}
			}
		}
		return list;
	}

	/**
	 * Delivery success rate (delivered vs total assigned).
	 */
	public Map<String, Object> getDeliverySuccessRate() throws SQLException {
		String sql = "SELECT COUNT(*) AS total, "
				+ "  SUM(CASE WHEN status='Delivered' THEN 1 ELSE 0 END) AS delivered "
				+ "FROM orders WHERE delivery_user_id IS NOT NULL";
		Map<String, Object> map = new LinkedHashMap<>();
		try (Connection con = DBConnection.getConnection();
				PreparedStatement ps = con.prepareStatement(sql);
				ResultSet rs = ps.executeQuery()) {
			if (rs.next()) {
				int total = rs.getInt("total");
				int delivered = rs.getInt("delivered");
				double rate = total > 0 ? Math.round((delivered * 100.0 / total) * 10) / 10.0 : 0;
				map.put("total", total);
				map.put("delivered", delivered);
				map.put("rate", rate);
			}
		}
		return map;
	}

	// ════════════════════════════════════════════════════════════════
	// 6. CUSTOMER GROWTH
	// ════════════════════════════════════════════════════════════════

	/** Total registered customers. */
	public int getTotalCustomers() throws SQLException {
		String sql = "SELECT COUNT(*) FROM customers";
		try (Connection con = DBConnection.getConnection();
				PreparedStatement ps = con.prepareStatement(sql);
				ResultSet rs = ps.executeQuery()) {
			return rs.next() ? rs.getInt(1) : 0;
		}
	}

	/**
	 * New customer registrations per month for last N months. Returns list of
	 * {month, count}
	 */
	public List<Map<String, Object>> getCustomerGrowth(int months) throws SQLException {
		// customers table has no registration date — return total as single point
		String sql = "SELECT 'All Time' AS month, COUNT(*) AS cnt FROM customers";
		List<Map<String, Object>> list = new ArrayList<>();
		try (Connection con = DBConnection.getConnection();
				PreparedStatement ps = con.prepareStatement(sql);
				ResultSet rs = ps.executeQuery()) {
			while (rs.next()) {
				Map<String, Object> row = new LinkedHashMap<>();
				row.put("month", rs.getString("month"));
				row.put("count", rs.getInt("cnt"));
				list.add(row);
			}
		}
		return list;
	}

	// ════════════════════════════════════════════════════════════════
	// 7. PAYMENT METHOD BREAKDOWN
	// ════════════════════════════════════════════════════════════════

	/**
	 * Revenue split by payment method (COD vs Online).
	 */
	public List<Map<String, Object>> getPaymentMethodBreakdown() throws SQLException {
		String sql = "SELECT " + "  CASE WHEN cod_charge > 0 THEN 'Cash on Delivery' ELSE 'Online' END AS method, "
				+ "  COUNT(*) AS orders, " + "  COALESCE(SUM(total_amount),0) AS revenue " + "FROM orders "
				+ "WHERE status NOT IN ('Cancelled','Return Requested','Refunded','Replaced') " + "GROUP BY method";
		List<Map<String, Object>> list = new ArrayList<>();
		try (Connection con = DBConnection.getConnection();
				PreparedStatement ps = con.prepareStatement(sql);
				ResultSet rs = ps.executeQuery()) {
			while (rs.next()) {
				Map<String, Object> row = new LinkedHashMap<>();
				row.put("method", rs.getString("method"));
				row.put("orders", rs.getInt("orders"));
				row.put("revenue", rs.getDouble("revenue"));
				list.add(row);
			}
		}
		return list;
	}

	// ════════════════════════════════════════════════════════════════
	// 8. STAFF DEPARTMENT BREAKDOWN
	// ════════════════════════════════════════════════════════════════

	/**
	 * Staff count by department.
	 */
	public List<Map<String, Object>> getStaffByDepartment() throws SQLException {
		String sql = "SELECT COALESCE(department,'Unassigned') AS dept, COUNT(*) AS cnt "
				+ "FROM users WHERE role IN ('staff','admin') AND status='Active' " + "GROUP BY dept ORDER BY cnt DESC";
		List<Map<String, Object>> list = new ArrayList<>();
		try (Connection con = DBConnection.getConnection();
				PreparedStatement ps = con.prepareStatement(sql);
				ResultSet rs = ps.executeQuery()) {
			while (rs.next()) {
				Map<String, Object> row = new LinkedHashMap<>();
				row.put("department", rs.getString("dept"));
				row.put("count", rs.getInt("cnt"));
				list.add(row);
			}
		}
		return list;
	}
}
