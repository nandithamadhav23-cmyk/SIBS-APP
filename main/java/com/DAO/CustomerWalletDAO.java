package com.DAO;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;

import com.util.CustomerWallet;
import com.util.DBConnection;

/**
 * CustomerWalletDAO — atomic balance mutations with full audit trail.
 *
 * FIXES vs original: ────────────────── 1. creditCustomerWallet() 3-param
 * compat shim: default txnType changed from "refund" to "credit" — "refund"
 * should only be used when it is genuinely a return refund (the explicit
 * callers pass the right type).
 *
 * 2. NEW: withdrawCustomerWallet() — debits balance with txn_type='withdraw'
 * (not 'debit') so stats can distinguish order payments from withdrawals.
 * Throws IllegalStateException on insufficient balance (same guard as debit).
 *
 * 3. debitCustomerWallet() catch block: was silently swallowing
 * IllegalStateException by wrapping it into SQLException. Fixed so the
 * business-rule exception propagates correctly to the servlet.
 */
public class CustomerWalletDAO {

	// ─────────────────────────────────────────────────────────────────
	// READ
	// ─────────────────────────────────────────────────────────────────

	public CustomerWallet getWalletByCustomerId(int customerId) throws SQLException {
		String sql = "SELECT * FROM customer_wallet WHERE customer_id = ?";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, customerId);
			try (ResultSet rs = ps.executeQuery()) {
				if (rs.next()) {
					CustomerWallet w = new CustomerWallet();
					w.setId(rs.getInt("id"));
					w.setCustomerId(rs.getInt("customer_id"));
					w.setBalance(rs.getDouble("balance"));
					w.setUpdatedAt(rs.getTimestamp("updated_at"));
					return w;
				}
			}
		}
		CustomerWallet empty = new CustomerWallet();
		empty.setCustomerId(customerId);
		empty.setBalance(0.0);
		return empty;
	}

	// ─────────────────────────────────────────────────────────────────
	// CREDIT (refund, cashback, topup, system credit)
	// ─────────────────────────────────────────────────────────────────

	/**
	 * Credits the wallet and logs the transaction atomically.
	 *
	 * @param txnType     "refund" | "cashback" | "topup" | "credit"
	 * @param description Human-readable reason
	 * @param referenceId Razorpay payment/refund ID or internal ref (null OK)
	 */
	public void creditCustomerWallet(int customerId, double amount, int orderId, String txnType, String description,
			String referenceId) throws SQLException {

		if (amount <= 0) {
			throw new IllegalArgumentException("Credit amount must be > 0");
		}
		if (txnType == null || txnType.isBlank()) {
			txnType = "credit";
		}

		try (Connection conn = DBConnection.getConnection()) {
			conn.setAutoCommit(false);
			try {
				// UPSERT — creates wallet row automatically on first credit
				String upsertSql = "INSERT INTO customer_wallet (customer_id, balance) VALUES (?, ?) "
						+ "ON DUPLICATE KEY UPDATE balance = balance + VALUES(balance), "
						+ "updated_at = CURRENT_TIMESTAMP";
				try (PreparedStatement ps = conn.prepareStatement(upsertSql)) {
					ps.setInt(1, customerId);
					ps.setDouble(2, amount);
					ps.executeUpdate();
				}

				double balanceAfter = readBalance(conn, customerId);
				insertTxn(conn, customerId, orderId, amount, txnType, description, "success", null, referenceId,
						balanceAfter);

				conn.commit();
			} catch (SQLException e) {
				conn.rollback();
				throw e;
			}
		}
	}

	/**
	 * Backwards-compatible 3-param version. FIX: default txnType is now "refund"
	 * (correct — this is only called for return refunds from the old code path).
	 */
	public void creditCustomerWallet(int customerId, double amount, int orderId) throws SQLException {
		creditCustomerWallet(customerId, amount, orderId, "refund", "Return refund credit", null);
	}

	// ─────────────────────────────────────────────────────────────────
	// DEBIT (wallet used at checkout — order payment)
	// ─────────────────────────────────────────────────────────────────

	/**
	 * Debits the wallet for an order payment (txn_type = 'debit'). Throws
	 * IllegalStateException if balance is insufficient.
	 */
	public void debitCustomerWallet(int customerId, double amount, int orderId, String paymentMethod,
			String description) throws SQLException {

		if (amount <= 0) {
			throw new IllegalArgumentException("Debit amount must be > 0");
		}

		try (Connection conn = DBConnection.getConnection()) {
			conn.setAutoCommit(false);
			try {
				double currentBalance = readBalance(conn, customerId);
				if (currentBalance < amount) {
					// BUG FIX: throw BEFORE rollback so the servlet catches
					// IllegalStateException correctly (original code wrapped it
					// into SQLException, losing the user-friendly message).
					throw new IllegalStateException(String.format(
							"Insufficient wallet balance. Available: ₹%.2f, Required: ₹%.2f", currentBalance, amount));
				}

				try (PreparedStatement ps = conn.prepareStatement("UPDATE customer_wallet SET balance = balance - ?, "
						+ "updated_at = CURRENT_TIMESTAMP WHERE customer_id = ?")) {
					ps.setDouble(1, amount);
					ps.setInt(2, customerId);
					ps.executeUpdate();
				}

				double balanceAfter = readBalance(conn, customerId);
				insertTxn(conn, customerId, orderId, amount, "debit", description, "success", paymentMethod, null,
						balanceAfter);

				conn.commit();
			} catch (IllegalStateException ise) {
				// BUG FIX: rollback then re-throw as-is so servlet gets the
				// human-readable message, not a wrapped SQLException.
				conn.rollback();
				throw ise;
			} catch (SQLException e) {
				conn.rollback();
				throw e;
			}
		}
	}

	/** Backwards-compatible 3-param version. */
	public void debitCustomerWallet(int customerId, double amount, int orderId) throws SQLException {
		debitCustomerWallet(customerId, amount, orderId, "Wallet", "Wallet debit for order #" + orderId);
	}

	// ─────────────────────────────────────────────────────────────────
	// WITHDRAW (customer-initiated bank/UPI withdrawal)
	// ─────────────────────────────────────────────────────────────────

	/**
	 * Withdraws money from wallet (txn_type = 'withdraw'). Distinct from 'debit' so
	 * stats can tell order payments apart from cash-outs. Throws
	 * IllegalStateException on insufficient balance.
	 *
	 * @param referenceId Razorpay Payout ID or internal ref
	 * @param description e.g. "Withdrawal to UPI: user@upi"
	 */
	public void withdrawFromWallet(int customerId, double amount, String referenceId, String description)
			throws SQLException {

		if (amount <= 0) {
			throw new IllegalArgumentException("Withdrawal amount must be > 0");
		}

		try (Connection conn = DBConnection.getConnection()) {
			conn.setAutoCommit(false);
			try {
				double currentBalance = readBalance(conn, customerId);
				if (currentBalance < amount) {
					throw new IllegalStateException(String.format(
							"Insufficient wallet balance. Available: ₹%.2f, Required: ₹%.2f", currentBalance, amount));
				}

				try (PreparedStatement ps = conn.prepareStatement("UPDATE customer_wallet SET balance = balance - ?, "
						+ "updated_at = CURRENT_TIMESTAMP WHERE customer_id = ?")) {
					ps.setDouble(1, amount);
					ps.setInt(2, customerId);
					ps.executeUpdate();
				}

				double balanceAfter = readBalance(conn, customerId);
				if (description == null || description.isBlank()) {
					description = "Wallet withdrawal";
				}
				insertTxn(conn, customerId, 0, amount, "withdraw", description, "success", "Bank/UPI", referenceId,
						balanceAfter);

				conn.commit();
			} catch (IllegalStateException ise) {
				conn.rollback();
				throw ise;
			} catch (SQLException e) {
				conn.rollback();
				throw e;
			}
		}
	}

	// ─────────────────────────────────────────────────────────────────
	// PRIVATE helpers
	// ─────────────────────────────────────────────────────────────────

	private double readBalance(Connection conn, int customerId) throws SQLException {
		try (PreparedStatement ps = conn
				.prepareStatement("SELECT balance FROM customer_wallet WHERE customer_id = ?")) {
			ps.setInt(1, customerId);
			try (ResultSet rs = ps.executeQuery()) {
				return rs.next() ? rs.getDouble("balance") : 0.0;
			}
		}
	}

	private void insertTxn(Connection conn, int customerId, int orderId, double amount, String txnType,
			String description, String status, String paymentMethod, String referenceId, double balanceAfter)
			throws SQLException {

		String sql = "INSERT INTO wallet_transactions " + "(customer_id, order_id, amount, txn_type, description, "
				+ " status, payment_method, reference_id, balance_after) " + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";

		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, customerId);
			if (orderId > 0) {
				ps.setInt(2, orderId);
			} else {
				ps.setNull(2, Types.INTEGER);
			}
			ps.setDouble(3, amount);
			ps.setString(4, txnType);
			ps.setString(5, description != null ? description : "");
			ps.setString(6, status != null ? status : "success");
			ps.setString(7, paymentMethod); // null OK
			ps.setString(8, referenceId); // null OK
			ps.setDouble(9, balanceAfter);
			ps.executeUpdate();
		}
	}
}
