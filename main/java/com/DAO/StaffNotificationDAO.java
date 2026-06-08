package com.DAO;

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
import com.util.StaffNotification;

public class StaffNotificationDAO {

	private static final Logger log = Logger.getLogger(StaffNotificationDAO.class.getName());

	/**
	 * Inserts a structured staff notification for a newly raised or updated support
	 * ticket.
	 *
	 * @param ticketId      support_tickets.ticket_id
	 * @param customerId    who raised the ticket
	 * @param customerName  display name for the staff panel
	 * @param customerEmail email snapshot
	 * @param customerPhone phone snapshot
	 * @param subject       ticket subject line
	 * @param description   full description (stored as items_summary)
	 * @param priority      low | normal | high | urgent
	 * @param category      ticket category label (e.g. "📦 Order issue")
	 * @param actionText    call-to-action text for the staff panel
	 * @return generated notification id, or -1 on error
	 */
	public int insertTicket(int ticketId, int customerId, String customerName, String customerEmail,
			String customerPhone, String subject, String description, String priority, String category,
			String actionText) {

		// Prefix paymentStatus with "TICKET" so the staff panel can filter/render it
		// distinctly
		String paymentStatus = "TICKET_" + (priority != null ? priority.toUpperCase() : "NORMAL");

		String itemsSummary = "[" + category + "] " + (description != null ? description : subject);
		String action = actionText != null ? actionText
				: "Review ticket #TKT-" + ticketId + " in the Support Ticket Queue.";

		StaffNotification n = new StaffNotification();
		n.setOrderId(ticketId); // re-using order_id column to store ticket_id
		n.setPaymentMethod("SUPPORT"); // sentinel so staff panel can display ticket icon
		n.setPaymentStatus(paymentStatus);
		n.setGrandTotal(0.0);
		n.setCustomerName(customerName != null ? customerName : "Customer #" + customerId);
		n.setCustomerEmail(customerEmail != null ? customerEmail : "");
		n.setCustomerPhone(customerPhone != null ? customerPhone : "");
		n.setItemsSummary(itemsSummary);
		n.setActionRequired(action);
		return insert(n);
	}

	public int insert(StaffNotification n) {
		String sql = """
				INSERT INTO staff_notifications
				  (order_id, payment_method, payment_status, grand_total,
				   customer_name, customer_email, customer_phone,
				   items_summary, action_required)
				VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
				""";

		try (Connection con = DBConnection.getConnection();
				PreparedStatement ps = con.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

			ps.setInt(1, n.getOrderId());
			ps.setString(2, n.getPaymentMethod());
			ps.setString(3, n.getPaymentStatus());
			ps.setDouble(4, n.getGrandTotal());
			ps.setString(5, n.getCustomerName());
			ps.setString(6, n.getCustomerEmail());
			ps.setString(7, n.getCustomerPhone());
			ps.setString(8, n.getItemsSummary());
			ps.setString(9, n.getActionRequired());
			ps.executeUpdate();

			try (ResultSet rs = ps.getGeneratedKeys()) {
				if (rs.next()) {
					return rs.getInt(1);
				}
			}

		} catch (SQLException e) {
			log.log(Level.SEVERE, "Failed to insert staff notification", e);
		}
		return -1;
	}

	/**
	 * Mark a single notification as read.
	 */
	public void markRead(int notificationId) {
		update("UPDATE staff_notifications SET is_read = 1 WHERE id = ?", notificationId);
	}

	/**
	 * Mark ALL unread notifications as read in one query.
	 */
	public void markAllRead() {
		String sql = "UPDATE staff_notifications SET is_read = 1 WHERE is_read = 0";
		try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
			ps.executeUpdate();
		} catch (SQLException e) {
			log.log(Level.WARNING, "markAllRead failed", e);
		}
	}

	/**
	 * Soft-delete: hides a notification from the list without destroying data.
	 */
	public void dismiss(int notificationId) {
		update("UPDATE staff_notifications SET is_dismissed = 1 WHERE id = ?", notificationId);
	}

	/**
	 * Hard-delete a single notification row.
	 */
	public void delete(int notificationId) {
		update("DELETE FROM staff_notifications WHERE id = ?", notificationId);
	}

	public List<StaffNotification> getAll() {
		String sql = """
				SELECT * FROM staff_notifications
				WHERE is_dismissed = 0
				ORDER BY created_at DESC
				""";
		return query(sql);
	}

	public List<StaffNotification> getUnread() {
		String sql = """
				SELECT * FROM staff_notifications
				WHERE is_read = 0 AND is_dismissed = 0
				ORDER BY created_at DESC
				""";
		return query(sql);
	}

	public int countUnread() {
		String sql = "SELECT COUNT(*) FROM staff_notifications " + "WHERE is_read = 0 AND is_dismissed = 0";
		try (Connection con = DBConnection.getConnection();
				PreparedStatement ps = con.prepareStatement(sql);
				ResultSet rs = ps.executeQuery()) {
			if (rs.next()) {
				return rs.getInt(1);
			}
		} catch (SQLException e) {
			log.log(Level.WARNING, "countUnread failed", e);
		}
		return 0;
	}

	public StaffNotification getById(int id) {
		String sql = "SELECT * FROM staff_notifications WHERE id = ?";
		try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
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

	private List<StaffNotification> query(String sql) {
		List<StaffNotification> list = new ArrayList<>();
		try (Connection con = DBConnection.getConnection();
				PreparedStatement ps = con.prepareStatement(sql);
				ResultSet rs = ps.executeQuery()) {
			while (rs.next()) {
				list.add(map(rs));
			}
		} catch (SQLException e) {
			log.log(Level.WARNING, "query failed: " + sql, e);
		}
		return list;
	}

	private void update(String sql, int id) {
		try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
			ps.setInt(1, id);
			ps.executeUpdate();
		} catch (SQLException e) {
			log.log(Level.WARNING, "update failed: " + sql + " id=" + id, e);
		}
	}

	private StaffNotification map(ResultSet rs) throws SQLException {
		StaffNotification n = new StaffNotification();
		n.setId(rs.getInt("id"));
		n.setOrderId(rs.getInt("order_id"));
		n.setPaymentMethod(rs.getString("payment_method"));
		n.setPaymentStatus(rs.getString("payment_status"));
		n.setGrandTotal(rs.getDouble("grand_total"));
		n.setCustomerName(rs.getString("customer_name"));
		n.setCustomerEmail(rs.getString("customer_email"));
		n.setCustomerPhone(rs.getString("customer_phone"));
		n.setItemsSummary(rs.getString("items_summary"));
		n.setActionRequired(rs.getString("action_required"));
		n.setRead(rs.getInt("is_read") == 1);
		n.setDismissed(rs.getInt("is_dismissed") == 1);
		n.setCreatedAt(rs.getTimestamp("created_at"));
		return n;
	}
}
