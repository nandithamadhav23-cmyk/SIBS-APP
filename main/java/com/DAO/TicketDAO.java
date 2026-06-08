package com.DAO;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;

import com.util.DBConnection;
import com.util.SupportTicket;

/**
 * TicketDAO — CRUD for support_tickets and ticket_replies.
 *
 * Used by: - TicketServlet (Contact Us form submission) - AIChatServlet
 * (raiseTicket action — now links to support_tickets) - HelpDeskServlet
 * (customer My Requests view) - StaffAIChatServlet (staff lookup and resolve)
 */
public class TicketDAO {

	// ══════════════════════════════════════════════════════
	// CREATE
	// ══════════════════════════════════════════════════════

	/**
	 * Insert a new ticket. Returns the generated ticket_id.
	 *
	 * @param customerId    logged-in customer
	 * @param chatSessionId null if from Contact Us form, set if from Kira chat
	 * @param category      one of: order, cancellation, return, payment, delivery,
	 *                      product, account, other
	 * @param subject       short subject line (max 200 chars)
	 * @param description   full description from the customer
	 * @param refOrderId    order ID if relevant, or 0/null
	 * @param priority      low | normal | high | urgent
	 */
	public int createTicket(int customerId, Integer chatSessionId, String category, String subject, String description,
			Integer refOrderId, String priority) throws SQLException {

		String sql = "INSERT INTO support_tickets " + "(customer_id, chat_session_id, category, subject, description, "
				+ "ref_order_id, priority) VALUES (?,?,?,?,?,?,?)";

		try (Connection c = DBConnection.getConnection();
				PreparedStatement ps = c.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

			ps.setInt(1, customerId);
			if (chatSessionId != null && chatSessionId > 0) {
				ps.setInt(2, chatSessionId);
			} else {
				ps.setNull(2, Types.INTEGER);
			}
			ps.setString(3, category != null ? category : "other");
			ps.setString(4, subject);
			ps.setString(5, description);
			if (refOrderId != null && refOrderId > 0) {
				ps.setInt(6, refOrderId);
			} else {
				ps.setNull(6, Types.INTEGER);
			}
			ps.setString(7, priority != null ? priority : "normal");

			ps.executeUpdate();
			try (ResultSet k = ps.getGeneratedKeys()) {
				if (k.next()) {
					return k.getInt(1);
				}
			}
		}
		throw new SQLException("createTicket: no generated key");
	}

	/** Shorthand for tickets raised from the chat widget (normal priority). */
	public int createFromChat(int customerId, int chatSessionId, String category, String subject, String description,
			Integer refOrderId) throws SQLException {
		return createTicket(customerId, chatSessionId, category, subject, description, refOrderId, "normal");
	}

	// ══════════════════════════════════════════════════════
	// READ — CUSTOMER
	// ══════════════════════════════════════════════════════

	/** All tickets for a customer, newest first. */
	public List<SupportTicket> getTicketsByCustomer(int customerId) throws SQLException {
		String sql = "SELECT * FROM support_tickets WHERE customer_id=? ORDER BY created_at DESC";
		return query(sql, customerId);
	}

	/** Open + in-progress tickets only (for the customer dashboard badge count). */
	public int getOpenTicketCount(int customerId) throws SQLException {
		String sql = "SELECT COUNT(*) FROM support_tickets "
				+ "WHERE customer_id=? AND status NOT IN ('resolved','closed')";
		try (Connection c = DBConnection.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
			ps.setInt(1, customerId);
			try (ResultSet rs = ps.executeQuery()) {
				return rs.next() ? rs.getInt(1) : 0;
			}
		}
	}

	public SupportTicket getTicketById(int ticketId) throws SQLException {
		String sql = "SELECT * FROM support_tickets WHERE ticket_id=?";
		List<SupportTicket> list = query(sql, ticketId);
		return list.isEmpty() ? null : list.get(0);
	}

	// ══════════════════════════════════════════════════════
	// READ — STAFF
	// ══════════════════════════════════════════════════════

	/** All open/in-progress tickets (staff queue), newest first. */
	public List<SupportTicket> getOpenTickets() throws SQLException {
		String sql = "SELECT st.*, c.name AS cust_name, c.email AS cust_email, " + "c.phone AS cust_phone "
				+ "FROM support_tickets st " + "LEFT JOIN customers c ON c.customer_id = st.customer_id "
				+ "WHERE st.status NOT IN ('resolved','closed') " + "ORDER BY "
				+ "  FIELD(st.priority,'urgent','high','normal','low'), " + "  st.created_at ASC";
		return queryJoined(sql);
	}

	/** Tickets assigned to a specific staff user. */
	public List<SupportTicket> getTicketsByAssignee(String username) throws SQLException {
		String sql = "SELECT * FROM support_tickets WHERE assigned_to=? "
				+ "AND status NOT IN ('resolved','closed') ORDER BY created_at ASC";
		return query(sql, username);
	}

	// ══════════════════════════════════════════════════════
	// UPDATE — STAFF
	// ══════════════════════════════════════════════════════

	public void updateStatus(int ticketId, String status, String assignedTo) throws SQLException {
		String sql = "UPDATE support_tickets SET status=?, assigned_to=?, " + "resolved_at=? WHERE ticket_id=?";
		try (Connection c = DBConnection.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
			ps.setString(1, status);
			if (assignedTo != null) {
				ps.setString(2, assignedTo);
			} else {
				ps.setNull(2, Types.VARCHAR);
			}
			boolean resolved = "resolved".equals(status) || "closed".equals(status);
			if (resolved) {
				ps.setTimestamp(3, new Timestamp(System.currentTimeMillis()));
			} else {
				ps.setNull(3, Types.TIMESTAMP);
			}
			ps.setInt(4, ticketId);
			ps.executeUpdate();
		}
	}

	/**
	 * Staff posts a reply — inserts reply row, stores latest text, flips status to
	 * waiting_customer.
	 */
	public void staffReply(int ticketId, String staffUsername, String message) throws SQLException {
		addReply(ticketId, "staff", staffUsername, message, "waiting_customer");
	}

	/**
	 * Customer adds a follow-up reply — inserts reply row with role='customer',
	 * stores latest text in staff_reply column (repurposed as latest_message), and
	 * flips status back to 'open' so staff sees it needs attention.
	 */
	public void customerReply(int ticketId, String customerName, String message) throws SQLException {
		addReply(ticketId, "customer", customerName, message, "open");
	}

	/**
	 * Internal: inserts a ticket_replies row and updates the ticket's staff_reply
	 * snapshot + status in one connection.
	 *
	 * @param senderRole "staff" | "customer"
	 * @param senderName display name of sender
	 * @param newStatus  status to set on the ticket after this reply
	 */
	private void addReply(int ticketId, String senderRole, String senderName, String message, String newStatus)
			throws SQLException {
		String replySQL = "INSERT INTO ticket_replies (ticket_id, sender_role, sender_name, message) "
				+ "VALUES (?,?,?,?)";
		String updateSQL = "UPDATE support_tickets SET staff_reply=?, status=?, "
				+ "assigned_to=CASE WHEN ? = 'staff' THEN ? ELSE assigned_to END " + "WHERE ticket_id=?";

		try (Connection c = DBConnection.getConnection()) {
			try (PreparedStatement ps = c.prepareStatement(replySQL)) {
				ps.setInt(1, ticketId);
				ps.setString(2, senderRole);
				ps.setString(3, senderName);
				ps.setString(4, message);
				ps.executeUpdate();
			}
			try (PreparedStatement ps = c.prepareStatement(updateSQL)) {
				ps.setString(1, message);
				ps.setString(2, newStatus);
				ps.setString(3, senderRole); // CASE condition
				ps.setString(4, senderName); // assigned_to value when staff
				ps.setInt(5, ticketId);
				ps.executeUpdate();
			}
		}
	}

	// ══════════════════════════════════════════════════════
	// REPLIES
	// ══════════════════════════════════════════════════════

	public List<TicketReply> getReplies(int ticketId) throws SQLException {
		String sql = "SELECT * FROM ticket_replies WHERE ticket_id=? ORDER BY sent_at ASC";
		List<TicketReply> list = new ArrayList<>();
		try (Connection c = DBConnection.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
			ps.setInt(1, ticketId);
			try (ResultSet rs = ps.executeQuery()) {
				while (rs.next()) {
					TicketReply r = new TicketReply();
					r.setReplyId(rs.getInt("reply_id"));
					r.setTicketId(rs.getInt("ticket_id"));
					r.setSenderRole(rs.getString("sender_role"));
					r.setSenderName(rs.getString("sender_name"));
					r.setMessage(rs.getString("message"));
					r.setSentAt(rs.getTimestamp("sent_at"));
					list.add(r);
				}
			}
		}
		return list;
	}

	// ══════════════════════════════════════════════════════
	// HELPERS
	// ══════════════════════════════════════════════════════

	private List<SupportTicket> query(String sql, Object param) throws SQLException {
		List<SupportTicket> list = new ArrayList<>();
		try (Connection c = DBConnection.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
			if (param instanceof Integer) {
				ps.setInt(1, (Integer) param);
			} else {
				ps.setString(1, (String) param);
			}
			try (ResultSet rs = ps.executeQuery()) {
				while (rs.next()) {
					list.add(map(rs));
				}
			}
		}
		return list;
	}

	/** Query that already JOINs customer name/email/phone. */
	private List<SupportTicket> queryJoined(String sql) throws SQLException {
		List<SupportTicket> list = new ArrayList<>();
		try (Connection c = DBConnection.getConnection();
				PreparedStatement ps = c.prepareStatement(sql);
				ResultSet rs = ps.executeQuery()) {
			while (rs.next()) {
				SupportTicket t = map(rs);
				// Enrich with joined customer fields if present
				try {
					t.setCustomerName(rs.getString("cust_name"));
				} catch (SQLException ignored) {
				}
				try {
					t.setCustomerEmail(rs.getString("cust_email"));
				} catch (SQLException ignored) {
				}
				try {
					t.setCustomerPhone(rs.getString("cust_phone"));
				} catch (SQLException ignored) {
				}
				list.add(t);
			}
		}
		return list;
	}

	private SupportTicket map(ResultSet rs) throws SQLException {
		SupportTicket t = new SupportTicket();
		t.setTicketId(rs.getInt("ticket_id"));
		t.setCustomerId(rs.getInt("customer_id"));
		t.setChatSessionId(rs.getInt("chat_session_id"));
		t.setCategory(rs.getString("category"));
		t.setSubject(rs.getString("subject"));
		t.setDescription(rs.getString("description"));
		t.setStatus(rs.getString("status"));
		t.setPriority(rs.getString("priority"));
		t.setAssignedTo(rs.getString("assigned_to"));
		t.setStaffReply(rs.getString("staff_reply"));
		t.setRefOrderId(rs.getInt("ref_order_id"));
		t.setCreatedAt(rs.getTimestamp("created_at"));
		t.setUpdatedAt(rs.getTimestamp("updated_at"));
		t.setResolvedAt(rs.getTimestamp("resolved_at"));
		return t;
	}

	// ── Inner util: TicketReply bean (or put in com.util package) ────────────
	public static class TicketReply {
		private int replyId, ticketId;
		private String senderRole, senderName, message;
		private Timestamp sentAt;

		public int getReplyId() {
			return replyId;
		}

		public void setReplyId(int v) {
			replyId = v;
		}

		public int getTicketId() {
			return ticketId;
		}

		public void setTicketId(int v) {
			ticketId = v;
		}

		public String getSenderRole() {
			return senderRole;
		}

		public void setSenderRole(String v) {
			senderRole = v;
		}

		public String getSenderName() {
			return senderName;
		}

		public void setSenderName(String v) {
			senderName = v;
		}

		public String getMessage() {
			return message;
		}

		public void setMessage(String v) {
			message = v;
		}

		public Timestamp getSentAt() {
			return sentAt;
		}

		public void setSentAt(Timestamp v) {
			sentAt = v;
		}
	}
}
