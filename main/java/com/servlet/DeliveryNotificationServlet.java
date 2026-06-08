package com.servlet;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

import com.util.DBConnection;
import com.util.User;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

/**
 * DeliveryNotificationServlet
 * ─────────────────────────────────────────────────────────────────────────────
 * Handles the agent notification system. Provides: GET ?action=list — returns
 * JSON array of notifications for the agent POST ?action=markRead — marks one
 * notification read (id=X) POST ?action=markAllRead — marks all agent
 * notifications read POST ?action=dismiss — soft-deletes one notification
 * (id=X)
 *
 * DB TABLE: agent_notifications id INT AUTO_INCREMENT PK agent_id INT NOT NULL
 * (FK users.id) type VARCHAR(40) — ORDER_ASSIGNED | ORDER_DELIVERED |
 * EARNINGS_CREDITED | RATING_RECEIVED | SHIFT_STARTING | SHIFT_EXPIRED |
 * SLOT_BOOKED | COD_REMINDER | WALLET_LOW | SYSTEM title VARCHAR(200) body
 * VARCHAR(1000) icon VARCHAR(10) — emoji color_class VARCHAR(20) — amber |
 * green | blue | red | purple | teal ref_id INT — order_id / slot_id /
 * wallet_tx_id (nullable) is_read TINYINT(1) DEFAULT 0 is_dismissed TINYINT(1)
 * DEFAULT 0 created_at DATETIME DEFAULT CURRENT_TIMESTAMP
 *
 * AUTO-SCHEMA: The constructor creates the table if it doesn't exist so the
 * feature is zero-config — no migration script needed.
 */
@WebServlet("/DeliveryNotificationServlet")
public class DeliveryNotificationServlet extends HttpServlet {

	private static final long serialVersionUID = 1L;
	private static final Logger log = Logger.getLogger(DeliveryNotificationServlet.class.getName());

	// ─── DDL ──────────────────────────────────────────────────────────────────

	private static final String CREATE_TABLE = "CREATE TABLE IF NOT EXISTS agent_notifications ("
			+ "  id           INT AUTO_INCREMENT PRIMARY KEY," + "  agent_id     INT         NOT NULL,"
			+ "  type         VARCHAR(40) NOT NULL DEFAULT 'SYSTEM'," + "  title        VARCHAR(200) NOT NULL,"
			+ "  body         VARCHAR(1000) DEFAULT NULL," + "  icon         VARCHAR(10)  DEFAULT '🔔',"
			+ "  color_class  VARCHAR(20)  DEFAULT 'purple'," + "  ref_id       INT          DEFAULT NULL,"
			+ "  is_read      TINYINT(1)   NOT NULL DEFAULT 0," + "  is_dismissed TINYINT(1)   NOT NULL DEFAULT 0,"
			+ "  created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,"
			+ "  INDEX idx_agent (agent_id, is_dismissed, created_at DESC)" + ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4";

	@Override
	public void init() throws ServletException {
		try (Connection conn = DBConnection.getConnection(); Statement st = conn.createStatement()) {
			st.executeUpdate(CREATE_TABLE);
		} catch (Exception e) {
			log.warning("agent_notifications table init: " + e.getMessage());
		}
	}

	// ─── GET ──────────────────────────────────────────────────────────────────

	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {

		User user = getUser(req, resp);
		if (user == null) {
			return;
		}

		String action = req.getParameter("action");

		if ("count".equals(action)) {
			// Lightweight unread count for badge polling
			try (Connection conn = DBConnection.getConnection()) {
				int unread = countUnread(conn, user.getUid());
				writeJson(resp, "{\"unread\":" + unread + "}");
			} catch (Exception e) {
				writeJson(resp, "{\"unread\":0}");
			}
			return;
		}

		// Default: list (paginated, latest 50)
		try (Connection conn = DBConnection.getConnection()) {
			// Auto-generate system notifications from real data before listing
			generateSystemNotifications(conn, user.getUid());

			List<String> items = listNotifications(conn, user.getUid());
			int unread = countUnread(conn, user.getUid());
			StringBuilder sb = new StringBuilder();
			sb.append("{\"unread\":").append(unread).append(",\"items\":[");
			for (int i = 0; i < items.size(); i++) {
				if (i > 0) {
					sb.append(",");
				}
				sb.append(items.get(i));
			}
			sb.append("]}");
			writeJson(resp, sb.toString());
		} catch (Exception e) {
			log.log(Level.SEVERE, "GET notifications error agent #" + user.getUid(), e);
			writeJson(resp, "{\"unread\":0,\"items\":[]}");
		}
	}

	// ─── POST ─────────────────────────────────────────────────────────────────

	@Override
	protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {

		User user = getUser(req, resp);
		if (user == null) {
			return;
		}

		String action = req.getParameter("action");

		try (Connection conn = DBConnection.getConnection()) {
			switch (action == null ? "" : action) {

			case "markRead" -> {
				int id = intParam(req, "id");
				if (id > 0) {
					markRead(conn, id, user.getUid());
				}
				writeJson(resp, "{\"success\":true}");
			}

			case "markAllRead" -> {
				markAllRead(conn, user.getUid());
				writeJson(resp, "{\"success\":true}");
			}

			case "dismiss" -> {
				int id = intParam(req, "id");
				if (id > 0) {
					dismiss(conn, id, user.getUid());
				}
				writeJson(resp, "{\"success\":true}");
			}

			case "push" -> {
				// Internal endpoint — called by other servlets to push notifications
				// Expects: type, title, body, icon, colorClass, refId
				String type = req.getParameter("type");
				String title = req.getParameter("title");
				String body = req.getParameter("body");
				String icon = req.getParameter("icon");
				String colorClass = req.getParameter("colorClass");
				int refId = intParam(req, "refId");
				push(conn, user.getUid(), type, title, body, icon, colorClass, refId);
				writeJson(resp, "{\"success\":true}");
			}

			default -> writeJson(resp, "{\"success\":false,\"message\":\"Unknown action\"}");
			}
		} catch (Exception e) {
			log.log(Level.SEVERE, "POST notifications error agent #" + user.getUid(), e);
			writeJson(resp, "{\"success\":false,\"message\":\"Server error\"}");
		}
	}

	// ─── DAO METHODS ──────────────────────────────────────────────────────────

	/**
	 * Auto-generates notifications from real DB data so agents get notifications
	 * even without a push event (idempotent — uses ON DUPLICATE KEY).
	 */
	private void generateSystemNotifications(Connection conn, int agentId) {
		try {
			// 1. New orders assigned since last check (last 24 h, not already notified)
			String newOrders = "INSERT IGNORE INTO agent_notifications "
					+ "(agent_id,type,title,body,icon,color_class,ref_id,created_at) " + "SELECT ?, 'ORDER_ASSIGNED', "
					+ "  CONCAT('New order assigned — #', o.order_id), "
					+ "  CONCAT('Deliver to ', COALESCE(c.name,'customer'), ' · ₹', o.total_amount), "
					+ "  '📦', 'amber', o.order_id, o.order_date " + "FROM orders o "
					+ "JOIN customers c ON o.customer_id = c.customer_id " + "WHERE o.delivery_user_id = ? "
					+ "  AND o.order_date >= DATE_SUB(NOW(), INTERVAL 24 HOUR) " + "  AND NOT EXISTS ("
					+ "    SELECT 1 FROM agent_notifications an2 "
					+ "    WHERE an2.agent_id=? AND an2.type='ORDER_ASSIGNED' AND an2.ref_id=o.order_id" + "  )";
			try (PreparedStatement ps = conn.prepareStatement(newOrders)) {
				ps.setInt(1, agentId);
				ps.setInt(2, agentId);
				ps.setInt(3, agentId);
				ps.executeUpdate();
			}

			// 2. Orders delivered today
			String delivered = "INSERT IGNORE INTO agent_notifications "
					+ "(agent_id,type,title,body,icon,color_class,ref_id,created_at) " + "SELECT ?, 'ORDER_DELIVERED', "
					+ "  CONCAT('Order #', o.order_id, ' delivered ✓'), "
					+ "  CONCAT('OTP verified & marked delivered for ', COALESCE(c.name,'customer')), "
					+ "  '✅', 'green', o.order_id, NOW() " + "FROM orders o "
					+ "JOIN customers c ON o.customer_id = c.customer_id " + "WHERE o.delivery_user_id = ? "
					+ "  AND o.status = 'Delivered' " + "  AND DATE(o.delivery_date) = CURDATE() "
					+ "  AND NOT EXISTS (" + "    SELECT 1 FROM agent_notifications an2 "
					+ "    WHERE an2.agent_id=? AND an2.type='ORDER_DELIVERED' AND an2.ref_id=o.order_id" + "  )";
			try (PreparedStatement ps = conn.prepareStatement(delivered)) {
				ps.setInt(1, agentId);
				ps.setInt(2, agentId);
				ps.setInt(3, agentId);
				ps.executeUpdate();
			}

			// 3. Earnings credited today
			String earnings = "INSERT IGNORE INTO agent_notifications "
					+ "(agent_id,type,title,body,icon,color_class,ref_id,created_at) "
					+ "SELECT ?, 'EARNINGS_CREDITED', "
					+ "  CONCAT('₹', ROUND(awt.amount,2), ' credited to your wallet'), " + "  awt.description, "
					+ "  '💰', 'green', awt.id, awt.created_at " + "FROM agent_wallet_transactions awt "
					+ "WHERE awt.agent_id = ? " + "  AND awt.type = 'slot_earning' "
					+ "  AND DATE(awt.created_at) = CURDATE() " + "  AND NOT EXISTS ("
					+ "    SELECT 1 FROM agent_notifications an2 "
					+ "    WHERE an2.agent_id=? AND an2.type='EARNINGS_CREDITED' AND an2.ref_id=awt.id" + "  )";
			try (PreparedStatement ps = conn.prepareStatement(earnings)) {
				ps.setInt(1, agentId);
				ps.setInt(2, agentId);
				ps.setInt(3, agentId);
				ps.executeUpdate();
			}

			// 4. Shift starting soon (15 min window) — BOOKED slot
			String shiftSoon = "INSERT IGNORE INTO agent_notifications "
					+ "(agent_id,type,title,body,icon,color_class,ref_id,created_at) " + "SELECT ?, 'SHIFT_STARTING', "
					+ "  CONCAT(ds.slot_type, ' shift starting soon'), "
					+ "  CONCAT('Your ', ds.slot_type, ' shift starts in 15 minutes. Tap to start.'), "
					+ "  '⏰', 'blue', ds.slot_id, NOW() " + "FROM delivery_slots ds " + "WHERE ds.agent_id = ? "
					+ "  AND ds.status = 'BOOKED' " + "  AND ds.window_start_at IS NOT NULL "
					+ "  AND NOW() >= DATE_SUB(ds.window_start_at, INTERVAL 20 MINUTE) "
					+ "  AND NOW() < ds.window_start_at " + "  AND NOT EXISTS ("
					+ "    SELECT 1 FROM agent_notifications an2 "
					+ "    WHERE an2.agent_id=? AND an2.type='SHIFT_STARTING' AND an2.ref_id=ds.slot_id" + "  )";
			try (PreparedStatement ps = conn.prepareStatement(shiftSoon)) {
				ps.setInt(1, agentId);
				ps.setInt(2, agentId);
				ps.setInt(3, agentId);
				ps.executeUpdate();
			}

			// 5. COD undeposited reminder
			String cod = "INSERT IGNORE INTO agent_notifications "
					+ "(agent_id,type,title,body,icon,color_class,ref_id,created_at) " + "SELECT ?, 'COD_REMINDER', "
					+ "  CONCAT(COUNT(*), ' COD order(s) pending deposit'), "
					+ "  CONCAT('You have ₹', ROUND(SUM(o.total_amount),2), ' in undeposited cash.'), "
					+ "  '💵', 'amber', NULL, NOW() " + "FROM orders o " + "WHERE o.delivery_user_id = ? "
					+ "  AND o.payment_method = 'COD' " + "  AND o.status = 'Delivered' " + "  AND o.cod_deposited = 0 "
					+ "HAVING COUNT(*) > 0 " + "AND NOT EXISTS (" + "  SELECT 1 FROM agent_notifications an2 "
					+ "  WHERE an2.agent_id=? AND an2.type='COD_REMINDER' "
					+ "  AND an2.created_at >= DATE_SUB(NOW(), INTERVAL 2 HOUR)" + ")";
			try (PreparedStatement ps = conn.prepareStatement(cod)) {
				ps.setInt(1, agentId);
				ps.setInt(2, agentId);
				ps.setInt(3, agentId);
				ps.executeUpdate();
			}

			// 6. EXPIRY WARNING: BOOKED slot expiring within 90 min (1hr before end =
			// 30-min alert window)
			String expiryWarn = "INSERT IGNORE INTO agent_notifications "
					+ "(agent_id, type, title, body, icon, color_class, ref_id, created_at) "
					+ "SELECT ds.agent_id, 'SHIFT_EXPIRY_WARNING', " + "  CONCAT(ds.slot_type, ' slot expires soon'), "
					+ "  CONCAT('Your ', LOWER(ds.slot_type), ' shift slot expires at ', "
					+ "    DATE_FORMAT(DATE_SUB(ds.window_end_at, INTERVAL 1 HOUR), '%h:%i %p'), "
					+ "    '. Start your shift now or the slot will be forfeited.'), "
					+ "  UNHEX('E29AA0EFB88F'), 'amber', ds.slot_id, NOW() " + "FROM delivery_slots ds "
					+ "WHERE ds.agent_id = ? " + "  AND ds.status = 'BOOKED' " + "  AND ds.window_end_at IS NOT NULL "
					+ "  AND NOW() >= DATE_SUB(ds.window_end_at, INTERVAL 90 MINUTE) "
					+ "  AND NOW() < DATE_SUB(ds.window_end_at, INTERVAL 60 MINUTE) " + "  AND NOT EXISTS ( "
					+ "    SELECT 1 FROM agent_notifications an2 " + "    WHERE an2.agent_id = ds.agent_id "
					+ "      AND an2.type = 'SHIFT_EXPIRY_WARNING' " + "      AND an2.ref_id = ds.slot_id)";
			try (PreparedStatement ps = conn.prepareStatement(expiryWarn)) {
				ps.setInt(1, agentId);
				ps.executeUpdate();
			}

		} catch (Exception e) {
			log.warning("generateSystemNotifications non-fatal: " + e.getMessage());
		}
	}

	private List<String> listNotifications(Connection conn, int agentId) throws SQLException {
		String sql = "SELECT id, type, title, body, icon, color_class, ref_id, is_read, created_at "
				+ "FROM agent_notifications " + "WHERE agent_id=? AND is_dismissed=0 "
				+ "ORDER BY created_at DESC LIMIT 50";
		List<String> list = new ArrayList<>();
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, agentId);
			try (ResultSet rs = ps.executeQuery()) {
				while (rs.next()) {
					String createdAt = rs.getTimestamp("created_at").toLocalDateTime()
							.format(java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
					list.add("{" + "\"id\":" + rs.getInt("id") + "," + "\"type\":\"" + esc(rs.getString("type")) + "\","
							+ "\"title\":\"" + esc(rs.getString("title")) + "\"," + "\"body\":\""
							+ esc(rs.getString("body") != null ? rs.getString("body") : "") + "\"," + "\"icon\":\""
							+ esc(rs.getString("icon")) + "\"," + "\"color\":\"" + esc(rs.getString("color_class"))
							+ "\"," + "\"refId\":" + rs.getInt("ref_id") + "," + "\"isRead\":"
							+ rs.getBoolean("is_read") + "," + "\"createdAt\":\"" + createdAt + "\"" + "}");
				}
			}
		}
		return list;
	}

	private int countUnread(Connection conn, int agentId) throws SQLException {
		String sql = "SELECT COUNT(*) FROM agent_notifications " + "WHERE agent_id=? AND is_read=0 AND is_dismissed=0";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, agentId);
			try (ResultSet rs = ps.executeQuery()) {
				return rs.next() ? rs.getInt(1) : 0;
			}
		}
	}

	private void markRead(Connection conn, int id, int agentId) throws SQLException {
		try (PreparedStatement ps = conn
				.prepareStatement("UPDATE agent_notifications SET is_read=1 WHERE id=? AND agent_id=?")) {
			ps.setInt(1, id);
			ps.setInt(2, agentId);
			ps.executeUpdate();
		}
	}

	private void markAllRead(Connection conn, int agentId) throws SQLException {
		try (PreparedStatement ps = conn
				.prepareStatement("UPDATE agent_notifications SET is_read=1 WHERE agent_id=? AND is_dismissed=0")) {
			ps.setInt(1, agentId);
			ps.executeUpdate();
		}
	}

	private void dismiss(Connection conn, int id, int agentId) throws SQLException {
		try (PreparedStatement ps = conn
				.prepareStatement("UPDATE agent_notifications SET is_dismissed=1 WHERE id=? AND agent_id=?")) {
			ps.setInt(1, id);
			ps.setInt(2, agentId);
			ps.executeUpdate();
		}
	}

	/**
	 * Static utility — push a notification from another servlet. Example:
	 * OrderServlet calls this when an order is assigned.
	 */
	public static void push(Connection conn, int agentId, String type, String title, String body, String icon,
			String colorClass, int refId) {
		String sql = "INSERT INTO agent_notifications "
				+ "(agent_id,type,title,body,icon,color_class,ref_id) VALUES (?,?,?,?,?,?,?)";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, agentId);
			ps.setString(2, type != null ? type : "SYSTEM");
			ps.setString(3, title);
			ps.setString(4, body);
			ps.setString(5, icon != null ? icon : "🔔");
			ps.setString(6, colorClass != null ? colorClass : "purple");
			if (refId > 0) {
				ps.setInt(7, refId);
			} else {
				ps.setNull(7, java.sql.Types.INTEGER);
			}
			ps.executeUpdate();
		} catch (Exception e) {
			Logger.getLogger(DeliveryNotificationServlet.class.getName())
					.warning("push notification failed: " + e.getMessage());
		}
	}

	// ─── HELPERS ──────────────────────────────────────────────────────────────

	private User getUser(HttpServletRequest req, HttpServletResponse resp) throws IOException {
		HttpSession session = req.getSession(false);
		User user = (session != null) ? (User) session.getAttribute("deliveryUser") : null;
		if (user == null) {
			resp.setStatus(401);
			writeJson(resp, "{\"error\":\"Unauthorized\"}");
		}
		return user;
	}

	private void writeJson(HttpServletResponse resp, String json) throws IOException {
		resp.setContentType("application/json");
		resp.setCharacterEncoding("UTF-8");
		resp.getWriter().write(json);
	}

	private int intParam(HttpServletRequest req, String name) {
		try {
			return Integer.parseInt(req.getParameter(name));
		} catch (Exception e) {
			return 0;
		}
	}

	private String esc(String s) {
		if (s == null) {
			return "";
		}
		return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "");
	}
}
