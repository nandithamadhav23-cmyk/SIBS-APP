package com.DAO;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import com.util.ChatMessage;
import com.util.ChatSession;
import com.util.DBConnection;

/**
 * ChatDAO — handles both customer and staff chat sessions/messages. Every
 * method gets its own Connection from the pool (no shared state).
 */
public class ChatDAO {

	// ══════════════════════════════════════════════════════
	// SESSION — CUSTOMER
	// ══════════════════════════════════════════════════════

	/** Create a new session for a logged-in customer. */
	public ChatSession createCustomerSession(int customerId) throws SQLException {
		return createSession(customerId, null, "customer");
	}

	/** Get the most recent active (unresolved) session for a customer. */
	public ChatSession getActiveCustomerSession(int customerId) throws SQLException {
		String sql = "SELECT * FROM chat_sessions " + "WHERE customer_id=? AND user_type='customer' AND is_resolved=0 "
				+ "ORDER BY last_active_at DESC LIMIT 1";
		try (Connection c = DBConnection.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
			ps.setInt(1, customerId);
			try (ResultSet rs = ps.executeQuery()) {
				return rs.next() ? mapSession(rs) : null;
			}
		}
	}

	// ══════════════════════════════════════════════════════
	// SESSION — STAFF
	// ══════════════════════════════════════════════════════

	/** Create a new session for a staff/admin user. */
	public ChatSession createStaffSession(String username) throws SQLException {
		return createSession(0, username, "staff");
	}

	/** Get the most recent active session for a staff user. */
	public ChatSession getActiveStaffSession(String username) throws SQLException {
		String sql = "SELECT * FROM chat_sessions " + "WHERE staff_username=? AND user_type='staff' AND is_resolved=0 "
				+ "ORDER BY last_active_at DESC LIMIT 1";
		try (Connection c = DBConnection.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
			ps.setString(1, username);
			try (ResultSet rs = ps.executeQuery()) {
				return rs.next() ? mapSession(rs) : null;
			}
		}
	}

	// ══════════════════════════════════════════════════════
	// SESSION — SHARED
	// ══════════════════════════════════════════════════════

	public ChatSession getSessionById(int sessionId) throws SQLException {
		String sql = "SELECT * FROM chat_sessions WHERE session_id=?";
		try (Connection c = DBConnection.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
			ps.setInt(1, sessionId);
			try (ResultSet rs = ps.executeQuery()) {
				return rs.next() ? mapSession(rs) : null;
			}
		}
	}

	public ChatSession getSessionByToken(String token) throws SQLException {
		String sql = "SELECT * FROM chat_sessions WHERE session_token=?";
		try (Connection c = DBConnection.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
			ps.setString(1, token);
			try (ResultSet rs = ps.executeQuery()) {
				return rs.next() ? mapSession(rs) : null;
			}
		}
	}

	/** Validates token belongs to a specific customer. */
	public boolean validateCustomerSession(String token, int customerId) throws SQLException {
		String sql = "SELECT 1 FROM chat_sessions "
				+ "WHERE session_token=? AND customer_id=? AND user_type='customer'";
		try (Connection c = DBConnection.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
			ps.setString(1, token);
			ps.setInt(2, customerId);
			try (ResultSet rs = ps.executeQuery()) {
				return rs.next();
			}
		}
	}

	/** Validates token belongs to a specific staff user. */
	public boolean validateStaffSession(String token, String username) throws SQLException {
		String sql = "SELECT 1 FROM chat_sessions "
				+ "WHERE session_token=? AND staff_username=? AND user_type='staff'";
		try (Connection c = DBConnection.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
			ps.setString(1, token);
			ps.setString(2, username);
			try (ResultSet rs = ps.executeQuery()) {
				return rs.next();
			}
		}
	}

	public void resolveSession(int sessionId) throws SQLException {
		String sql = "UPDATE chat_sessions SET is_resolved=1 WHERE session_id=?";
		try (Connection c = DBConnection.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
			ps.setInt(1, sessionId);
			ps.executeUpdate();
		}
	}

	// ══════════════════════════════════════════════════════
	// MESSAGES
	// ══════════════════════════════════════════════════════

	/**
	 * Saves a message. cardType and cardRefId may be null. Returns the generated
	 * message_id.
	 */
	public int saveMessage(int sessionId, String role, String content, String cardType, String cardRefId)
			throws SQLException {
		String sql = "INSERT INTO chat_messages " + "(session_id,role,content,card_type,card_ref_id) VALUES(?,?,?,?,?)";
		try (Connection c = DBConnection.getConnection();
				PreparedStatement ps = c.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
			ps.setInt(1, sessionId);
			ps.setString(2, role);
			ps.setString(3, content);
			if (cardType != null) {
				ps.setString(4, cardType);
			} else {
				ps.setNull(4, Types.VARCHAR);
			}
			if (cardRefId != null) {
				ps.setString(5, cardRefId);
			} else {
				ps.setNull(5, Types.VARCHAR);
			}
			ps.executeUpdate();
			try (ResultSet k = ps.getGeneratedKeys()) {
				if (k.next()) {
					return k.getInt(1);
				}
			}
		}
		throw new SQLException("saveMessage: no generated key");
	}

	/** Convenience overload — plain text, no card. */
	public int saveMessage(int sessionId, String role, String content) throws SQLException {
		return saveMessage(sessionId, role, content, null, null);
	}

	/** Full history for a session (for context rebuild). */
	public List<ChatMessage> getMessagesBySession(int sessionId) throws SQLException {
		return queryMessages("SELECT * FROM chat_messages WHERE session_id=? ORDER BY sent_at ASC", sessionId,
				Integer.MAX_VALUE);
	}

	/**
	 * Last N messages (chronological) — used to cap the Anthropic context window.
	 */
	public List<ChatMessage> getRecentMessages(int sessionId, int limit) throws SQLException {
		String sql = "SELECT * FROM (SELECT * FROM chat_messages WHERE session_id=? "
				+ "ORDER BY sent_at DESC LIMIT ?) sub ORDER BY sent_at ASC";
		List<ChatMessage> list = new ArrayList<>();
		try (Connection c = DBConnection.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
			ps.setInt(1, sessionId);
			ps.setInt(2, limit);
			try (ResultSet rs = ps.executeQuery()) {
				while (rs.next()) {
					list.add(mapMessage(rs));
				}
			}
		}
		return list;
	}

	// ══════════════════════════════════════════════════════
	// ACTIONS
	// ══════════════════════════════════════════════════════

	public void logAction(int sessionId, int messageId, String actionType, String refId, String payloadJson)
			throws SQLException {
		String sql = "INSERT INTO chat_actions "
				+ "(session_id,message_id,action_type,ref_id,payload) VALUES(?,?,?,?,?)";
		try (Connection c = DBConnection.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
			ps.setInt(1, sessionId);
			ps.setInt(2, messageId);
			ps.setString(3, actionType);
			if (refId != null) {
				ps.setString(4, refId);
			} else {
				ps.setNull(4, Types.VARCHAR);
			}
			if (payloadJson != null) {
				ps.setString(5, payloadJson);
			} else {
				ps.setNull(5, Types.OTHER);
			}
			ps.executeUpdate();
		}
	}

	// ══════════════════════════════════════════════════════
	// PRIVATE HELPERS
	// ══════════════════════════════════════════════════════

	private ChatSession createSession(int customerId, String staffUsername, String userType) throws SQLException {
		String token = UUID.randomUUID().toString().replace("-", "");
		String sql = "INSERT INTO chat_sessions "
				+ "(customer_id,staff_username,user_type,session_token) VALUES(?,?,?,?)";
		try (Connection c = DBConnection.getConnection();
				PreparedStatement ps = c.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
			if (customerId > 0) {
				ps.setInt(1, customerId);
			} else {
				ps.setNull(1, Types.INTEGER);
			}
			if (staffUsername != null) {
				ps.setString(2, staffUsername);
			} else {
				ps.setNull(2, Types.VARCHAR);
			}
			ps.setString(3, userType);
			ps.setString(4, token);
			ps.executeUpdate();
			try (ResultSet k = ps.getGeneratedKeys()) {
				if (k.next()) {
					return getSessionById(k.getInt(1));
				}
			}
		}
		throw new SQLException("createSession: no generated key");
	}

	private List<ChatMessage> queryMessages(String sql, int sessionId, int limit) throws SQLException {
		List<ChatMessage> list = new ArrayList<>();
		try (Connection c = DBConnection.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
			ps.setInt(1, sessionId);
			if (limit < Integer.MAX_VALUE) {
				ps.setInt(2, limit);
			}
			try (ResultSet rs = ps.executeQuery()) {
				while (rs.next()) {
					list.add(mapMessage(rs));
				}
			}
		}
		return list;
	}

	private ChatSession mapSession(ResultSet rs) throws SQLException {
		ChatSession s = new ChatSession();
		s.setSessionId(rs.getInt("session_id"));
		s.setCustomerId(rs.getInt("customer_id"));
		s.setSessionToken(rs.getString("session_token"));
		s.setStartedAt(rs.getTimestamp("started_at"));
		s.setLastActiveAt(rs.getTimestamp("last_active_at"));
		s.setResolved(rs.getBoolean("is_resolved"));
		s.setSummary(rs.getString("summary"));
		return s;
	}

	private ChatMessage mapMessage(ResultSet rs) throws SQLException {
		ChatMessage m = new ChatMessage();
		m.setMessageId(rs.getInt("message_id"));
		m.setSessionId(rs.getInt("session_id"));
		m.setRole(rs.getString("role"));
		m.setContent(rs.getString("content"));
		m.setCardType(rs.getString("card_type"));
		m.setCardOrderId(rs.getString("card_ref_id"));
		m.setSentAt(rs.getTimestamp("sent_at"));
		return m;
	}
}
