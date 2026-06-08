
package com.DAO;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;

import com.util.DBConnection;
import com.util.OrderReturn;

public class OrderReturnDAO {

	// ── Fetch a return record by orderId ────────────────────────────────────
	public OrderReturn getReturnByOrderId(int orderId) throws SQLException {
		String sql = "SELECT * FROM order_returns WHERE order_id = ?";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, orderId);
			try (ResultSet rs = ps.executeQuery()) {
				if (rs.next()) {
					return mapRow(rs);
				}
			}
		}
		return null;
	}

	// ── Insert or update a return record ────────────────────────────────────

	public void upsertReturnRecord(OrderReturn rr) throws SQLException {

		// ── Guard defaults ──────────────────────────────────────────────────
		if (rr.getType() == null) {
			rr.setType("Return");
		}
		if (rr.getReason() == null) {
			rr.setReason("");
		}
		if (rr.getCustomerId() <= 0) {
			rr.setCustomerId(getCustomerIdFromOrderId(rr.getOrderId()));
		}

		String sql = """
				INSERT INTO order_returns
				    (order_id, customer_id, type, reason, staff_notes, status,
				     pickup_agent_id, restock_qty, refund_amount, refund_method,
				     refund_transaction_id, photos, bank_name, bank_account, bank_ifsc,
				     approved_at, picked_at, refunded_at)
				VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
				ON DUPLICATE KEY UPDATE
				    status                = VALUES(status),
				    staff_notes           = COALESCE(VALUES(staff_notes),           staff_notes),
				    reason                = COALESCE(VALUES(reason),                reason),
				    -- FIX 3: pickup_agent_id has NO COALESCE — allows deliberate NULL clear
				    pickup_agent_id       = VALUES(pickup_agent_id),
				    restock_qty           = COALESCE(VALUES(restock_qty),           restock_qty),
				    refund_amount         = COALESCE(VALUES(refund_amount),         refund_amount),
				    refund_method         = COALESCE(VALUES(refund_method),         refund_method),
				    refund_transaction_id = COALESCE(VALUES(refund_transaction_id), refund_transaction_id),
				    photos                = COALESCE(VALUES(photos),                photos),
				    bank_name             = COALESCE(VALUES(bank_name),             bank_name),
				    bank_account          = COALESCE(VALUES(bank_account),          bank_account),
				    bank_ifsc             = COALESCE(VALUES(bank_ifsc),             bank_ifsc),
				    approved_at           = COALESCE(VALUES(approved_at),           approved_at),
				    picked_at             = COALESCE(VALUES(picked_at),             picked_at),
				    refunded_at           = COALESCE(VALUES(refunded_at),           refunded_at)
				""";

		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {

			Timestamp now = new Timestamp(System.currentTimeMillis());

			ps.setInt(1, rr.getOrderId());
			ps.setInt(2, rr.getCustomerId());
			ps.setString(3, rr.getType() != null ? rr.getType() : "Return");
			ps.setString(4, rr.getReason() != null ? rr.getReason() : "");

			// 5 — staff_notes (nullable)
			if (rr.getStaffNotes() != null) {
				ps.setString(5, rr.getStaffNotes());
			} else {
				ps.setNull(5, java.sql.Types.VARCHAR);
			}

			ps.setString(6, rr.getStatus() != null ? rr.getStatus() : "Requested");

			// ── FIX 1: pickup_agent_id — use Integer (nullable), never 0 ──────
			// rr.getPickupAgentId() returns Integer (nullable wrapper).
			// If null → setNull → MySQL stores NULL → FK is not violated.
			// If 0 → treat as null (defensive; 0 is never a valid user id).
			if (rr.getPickupAgentId() != null && rr.getPickupAgentId() > 0) {
				ps.setInt(7, rr.getPickupAgentId());
			} else {
				ps.setNull(7, java.sql.Types.INTEGER);
			}

			// 8 — restock_qty
			if (rr.getRestockQty() > 0) {
				ps.setInt(8, rr.getRestockQty());
			} else {
				ps.setNull(8, java.sql.Types.INTEGER);
			}

			// 9 — refund_amount
			if (rr.getRefundAmount() > 0) {
				ps.setDouble(9, rr.getRefundAmount());
			} else {
				ps.setNull(9, java.sql.Types.DECIMAL);
			}

			// 10 — refund_method (ENUM — must be null or a valid ENUM value)
			if (rr.getRefundMethod() != null && !rr.getRefundMethod().isBlank()) {
				ps.setString(10, rr.getRefundMethod());
			} else {
				ps.setNull(10, java.sql.Types.VARCHAR);
			}

			// 11 — refund_transaction_id
			if (rr.getRefundTransactionId() != null) {
				ps.setString(11, rr.getRefundTransactionId());
			} else {
				ps.setNull(11, java.sql.Types.VARCHAR);
			}

			// 12 — photos
			if (rr.getPhotos() != null) {
				ps.setString(12, rr.getPhotos());
			} else {
				ps.setNull(12, java.sql.Types.VARCHAR);
			}

			// 13 — bank_name
			if (rr.getBankName() != null) {
				ps.setString(13, rr.getBankName());
			} else {
				ps.setNull(13, java.sql.Types.VARCHAR);
			}

			// 14 — bank_account
			if (rr.getBankAccount() != null) {
				ps.setString(14, rr.getBankAccount());
			} else {
				ps.setNull(14, java.sql.Types.VARCHAR);
			}

			// 15 — bank_ifsc
			if (rr.getBankIfsc() != null) {
				ps.setString(15, rr.getBankIfsc());
			} else {
				ps.setNull(15, java.sql.Types.VARCHAR);
			}

			// 16 — approved_at: only stamp NOW when transitioning to Approved
			if ("Approved".equals(rr.getStatus())) {
				ps.setTimestamp(16, now);
			} else {
				ps.setNull(16, java.sql.Types.TIMESTAMP);
			}

			// 17 — picked_at: only stamp NOW when transitioning to Picked
			if ("Picked".equals(rr.getStatus())) {
				ps.setTimestamp(17, now);
			} else {
				ps.setNull(17, java.sql.Types.TIMESTAMP);
			}

			// 18 — refunded_at: stamp NOW when Refunded or Replaced
			if ("Refunded".equals(rr.getStatus()) || "Replaced".equals(rr.getStatus())) {
				ps.setTimestamp(18, now);
			} else {
				ps.setNull(18, java.sql.Types.TIMESTAMP);
			}

			ps.executeUpdate();
		}
	}

	// ── Update return status only ────────────────────────────────────────────
	public boolean updateReturnStatus(int orderId, String status) throws SQLException {
		String sql = "UPDATE order_returns SET status = ? WHERE order_id = ?";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setString(1, status);
			ps.setInt(2, orderId);
			return ps.executeUpdate() > 0;
		}
	}

	public boolean assignPickupAgent(int orderId, int pickupAgentId) throws SQLException {
		String sql = "UPDATE order_returns SET pickup_agent_id = ?, status = 'Approved' WHERE order_id = ?";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, pickupAgentId);
			ps.setInt(2, orderId);
			return ps.executeUpdate() > 0;
		}
	}

	// ── Clear pickup agent (for agent cancel / reassignment) ────────────────
	public boolean clearPickupAgent(int orderId) throws SQLException {
		String sql = "UPDATE order_returns SET pickup_agent_id = NULL, status = 'Approved' WHERE order_id = ?";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, orderId);
			return ps.executeUpdate() > 0;
		}
	}

	// ── Get all returns (for admin listing) ─────────────────────────────────
	public List<OrderReturn> getAllReturns() throws SQLException {
		List<OrderReturn> list = new ArrayList<>();
		String sql = "SELECT * FROM order_returns ORDER BY requested_at DESC";
		try (Connection conn = DBConnection.getConnection();
				PreparedStatement ps = conn.prepareStatement(sql);
				ResultSet rs = ps.executeQuery()) {
			while (rs.next()) {
				list.add(mapRow(rs));
			}
		}
		return list;
	}

	// ────────────────────────────────────────────────────────────────────────
	// ── mapRow: ResultSet → OrderReturn ─────────────────────────────────────
	//
	// FIX 1 (continued): Every nullable int column must be read with wasNull().
	// rs.getInt() returns 0 for SQL NULL — if we blindly store that 0, the
	// upsert will try to insert 0 as pickup_agent_id which breaks the FK.
	// ────────────────────────────────────────────────────────────────────────
	private OrderReturn mapRow(ResultSet rs) throws SQLException {
		OrderReturn r = new OrderReturn();

		r.setId(rs.getInt("id"));
		r.setOrderId(rs.getInt("order_id"));
		r.setCustomerId(rs.getInt("customer_id"));
		r.setReason(rs.getString("reason"));
		r.setStaffNotes(rs.getString("staff_notes"));
		r.setStatus(rs.getString("status"));

		// FIX 1: pickup_agent_id — read as int then check wasNull()
		int agentId = rs.getInt("pickup_agent_id");
		r.setPickupAgentId(rs.wasNull() ? null : agentId);

		// FIX 4: restock_qty — same pattern
		int restockQty = rs.getInt("restock_qty");
		r.setRestockQty(rs.wasNull() ? 0 : restockQty);

		// FIX 4: refund_amount — same pattern
		double refundAmount = rs.getDouble("refund_amount");
		r.setRefundAmount(rs.wasNull() ? 0.0 : refundAmount);

		r.setRefundMethod(rs.getString("refund_method"));
		r.setRefundTransactionId(rs.getString("refund_transaction_id"));
		r.setRequestedAt(rs.getTimestamp("requested_at"));
		r.setApprovedAt(rs.getTimestamp("approved_at"));
		r.setPickedAt(rs.getTimestamp("picked_at"));
		r.setRefundedAt(rs.getTimestamp("refunded_at"));
		r.setType(rs.getString("type"));
		r.setPhotos(rs.getString("photos"));
		r.setBankName(rs.getString("bank_name"));
		r.setBankAccount(rs.getString("bank_account"));
		r.setBankIfsc(rs.getString("bank_ifsc"));

		return r;
	}

	// ── Helper: look up customer_id from order ───────────────────────────────
	private int getCustomerIdFromOrderId(int orderId) throws SQLException {
		String sql = "SELECT customer_id FROM orders WHERE order_id = ?";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, orderId);
			try (ResultSet rs = ps.executeQuery()) {
				if (rs.next()) {
					return rs.getInt("customer_id");
				}
			}
		}
		return 0;
	}
}
