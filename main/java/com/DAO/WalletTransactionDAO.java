package com.DAO;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import com.util.DBConnection;
import com.util.WalletTransaction;

/**
 * WalletTransactionDAO — full audit-trail transaction management.
 *
 * FIXES vs original: ────────────────── 1. getSummaryStats(): - BUG:
 * total_credited included refunds AND topups/credits, so refunds were
 * double-counted (also in total_refunds). Now total_credited = topup+credit
 * only; refunds have their own column. - BUG: orders_paid_by_wallet counted ALL
 * debits including withdrawals. Now it counts debit rows that have a non-null
 * order_id only. - ADDED: total_withdrawn stat for the new withdraw type.
 *
 * 2. getTransactionsByCustomerId() filter now also accepts 'topup' and
 * 'withdraw' txn_type values added to the ENUM.
 *
 * 3. mapRow(): gracefully handles missing columns (status, payment_method,
 * reference_id, balance_after) — unchanged from previous version.
 *
 * 4. insertTransaction(): unchanged public API; internal logic unchanged.
 */
public class WalletTransactionDAO {

	// ─────────────────────────────────────────────────────────────────────
	// READ: all transactions for a customer (newest first)
	// ─────────────────────────────────────────────────────────────────────

	public List<WalletTransaction> getTransactionsByCustomerId(int customerId) throws SQLException {
		return getTransactionsByCustomerId(customerId, null, null, null);
	}

	/**
	 * Filtered fetch — any param can be null to skip that filter.
	 *
	 * @param txnType  "credit"|"debit"|"refund"|"cashback"|"topup"|"withdraw"
	 * @param status   "success"|"pending"|"failed"
	 * @param dateFrom java.sql.Date lower bound on created_at
	 */
	public List<WalletTransaction> getTransactionsByCustomerId(int customerId, String txnType, String status,
			java.sql.Date dateFrom) throws SQLException {

		StringBuilder sql = new StringBuilder("SELECT * FROM wallet_transactions WHERE customer_id = ?");
		List<Object> params = new ArrayList<>();
		params.add(customerId);

		if (txnType != null && !txnType.isBlank()) {
			sql.append(" AND txn_type = ?");
			params.add(txnType);
		}
		if (status != null && !status.isBlank()) {
			sql.append(" AND status = ?");
			params.add(status);
		}
		if (dateFrom != null) {
			sql.append(" AND created_at >= ?");
			params.add(dateFrom);
		}
		sql.append(" ORDER BY created_at DESC");

		List<WalletTransaction> list = new ArrayList<>();
		try (Connection conn = DBConnection.getConnection();
				PreparedStatement ps = conn.prepareStatement(sql.toString())) {
			for (int i = 0; i < params.size(); i++) {
				ps.setObject(i + 1, params.get(i));
			}
			try (ResultSet rs = ps.executeQuery()) {
				while (rs.next()) {
					list.add(mapRow(rs));
				}
			}
		}
		return list;
	}

	// ─────────────────────────────────────────────────────────────────────
	// READ: single transaction
	// ─────────────────────────────────────────────────────────────────────

	public WalletTransaction getTransactionById(int id) throws SQLException {
		String sql = "SELECT * FROM wallet_transactions WHERE id = ?";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, id);
			try (ResultSet rs = ps.executeQuery()) {
				return rs.next() ? mapRow(rs) : null;
			}
		}
	}

	// ─────────────────────────────────────────────────────────────────────
	// READ: summary stats — FIXED version
	// ─────────────────────────────────────────────────────────────────────

	/**
	 * Single-query dashboard stats for CustomerWalletServlet.
	 *
	 * FIX 1: total_credited now counts ONLY topup + credit rows. Refunds are NOT
	 * included here — they have their own column. This eliminates the double-count
	 * in the original query.
	 *
	 * FIX 2: orders_paid_by_wallet counts debit rows that have an associated
	 * order_id (> 0). Pure withdrawals have order_id = NULL and should NOT be
	 * counted as "orders paid by wallet".
	 *
	 * NEW: total_withdrawn — sum of withdraw type rows.
	 */
	public Map<String, Object> getSummaryStats(int customerId) throws SQLException {
		String sql = "SELECT "
				+ "  COUNT(*)                                                                    AS total_txns, " +
				// FIX: debit only (wallet used at checkout or manual debit)
				"  COALESCE(SUM(CASE WHEN txn_type = 'debit'                THEN amount ELSE 0 END),0) AS total_spent, "
				+
				// FIX: topup + credit only; refunds excluded to avoid double-count
				"  COALESCE(SUM(CASE WHEN txn_type IN ('topup','credit')    THEN amount ELSE 0 END),0) AS total_credited, "
				+ "  COALESCE(SUM(CASE WHEN txn_type = 'cashback'             THEN amount ELSE 0 END),0) AS total_cashback, "
				+ "  COALESCE(SUM(CASE WHEN txn_type = 'refund'               THEN amount ELSE 0 END),0) AS total_refunds, "
				+
				// FIX: only debit rows with a real order; withdrawals excluded
				"  COUNT(CASE WHEN txn_type = 'debit' AND order_id IS NOT NULL THEN 1 END)             AS orders_paid_by_wallet, "
				+
				// NEW: withdrawal total
				"  COALESCE(SUM(CASE WHEN txn_type = 'withdraw'             THEN amount ELSE 0 END),0) AS total_withdrawn, "
				+
				// Spent in last 30 days (debit only, not withdrawals)
				"  COALESCE(SUM(CASE WHEN txn_type = 'debit' "
				+ "              AND created_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY) "
				+ "                                                            THEN amount ELSE 0 END),0) AS spent_this_month "
				+ "FROM wallet_transactions WHERE customer_id = ?";

		Map<String, Object> stats = new LinkedHashMap<>();
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, customerId);
			try (ResultSet rs = ps.executeQuery()) {
				if (rs.next()) {
					stats.put("totalTxns", rs.getInt("total_txns"));
					stats.put("totalSpent", rs.getDouble("total_spent"));
					stats.put("totalCredited", rs.getDouble("total_credited"));
					stats.put("totalCashback", rs.getDouble("total_cashback"));
					stats.put("totalRefunds", rs.getDouble("total_refunds"));
					stats.put("ordersPaidByWallet", rs.getInt("orders_paid_by_wallet"));
					stats.put("totalWithdrawn", rs.getDouble("total_withdrawn"));
					stats.put("spentThisMonth", rs.getDouble("spent_this_month"));
				}
			}
		}
		return stats;
	}

	// ─────────────────────────────────────────────────────────────────────
	// READ: monthly spending breakdown — last 6 months debits for chart
	// ─────────────────────────────────────────────────────────────────────

	public List<Map<String, Object>> getMonthlySpending(int customerId) throws SQLException {
		String sql = "SELECT DATE_FORMAT(created_at,'%b %Y') AS month_label, "
				+ "       DATE_FORMAT(created_at,'%Y-%m')  AS month_key, " + "       SUM(amount) AS total "
				+ "FROM wallet_transactions " + "WHERE customer_id = ? AND txn_type = 'debit' "
				+ "  AND created_at >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH) "
				+ "GROUP BY month_key, month_label ORDER BY month_key ASC";

		List<Map<String, Object>> rows = new ArrayList<>();
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, customerId);
			try (ResultSet rs = ps.executeQuery()) {
				while (rs.next()) {
					Map<String, Object> row = new LinkedHashMap<>();
					row.put("label", rs.getString("month_label"));
					row.put("amount", rs.getDouble("total"));
					rows.add(row);
				}
			}
		}
		return rows;
	}

	// ─────────────────────────────────────────────────────────────────────
	// WRITE: insert transaction — full version
	// ─────────────────────────────────────────────────────────────────────

	public void insertTransaction(int customerId, int orderId, double amount, String txnType, String description,
			String status, String paymentMethod, String referenceId, double balanceAfter) throws SQLException {

		if (amount <= 0) {
			throw new IllegalArgumentException("Transaction amount must be > 0. Got: " + amount);
		}
		if (status == null || status.isBlank()) {
			status = "success";
		}

		String sql = "INSERT INTO wallet_transactions " + "(customer_id, order_id, amount, txn_type, description, "
				+ " status, payment_method, reference_id, balance_after) " + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";

		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, customerId);
			if (orderId > 0) {
				ps.setInt(2, orderId);
			} else {
				ps.setNull(2, Types.INTEGER);
			}
			ps.setDouble(3, amount);
			ps.setString(4, txnType);
			ps.setString(5, description);
			ps.setString(6, status);
			ps.setString(7, paymentMethod); // null OK
			ps.setString(8, referenceId); // null OK
			ps.setDouble(9, balanceAfter);
			ps.executeUpdate();
		}
	}

	/** Backwards-compatible 5-param overload — kept for existing callers. */
	public void insertTransaction(int customerId, int orderId, double amount, String txnType, String description)
			throws SQLException {
		double bal = 0.0;
		String balSql = "SELECT balance FROM customer_wallet WHERE customer_id = ?";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(balSql)) {
			ps.setInt(1, customerId);
			try (ResultSet rs = ps.executeQuery()) {
				if (rs.next()) {
					bal = rs.getDouble("balance");
				}
			}
		}
		insertTransaction(customerId, orderId, amount, txnType, description, "success", null, null, bal);
	}

	// ─────────────────────────────────────────────────────────────────────
	// PRIVATE: mapRow — maps ALL columns including new ones
	// ─────────────────────────────────────────────────────────────────────

	private WalletTransaction mapRow(ResultSet rs) throws SQLException {
		WalletTransaction t = new WalletTransaction();
		t.setId(rs.getInt("id"));
		t.setCustomerId(rs.getInt("customer_id"));

		int orderId = rs.getInt("order_id");
		t.setOrderId(rs.wasNull() ? 0 : orderId);

		t.setAmount(rs.getDouble("amount"));
		t.setTxnType(rs.getString("txn_type"));
		t.setDescription(rs.getString("description"));
		t.setCreatedAt(rs.getTimestamp("created_at"));

		try {
			t.setStatus(rs.getString("status"));
		} catch (SQLException ignored) {
			t.setStatus("success");
		}

		try {
			t.setPaymentMethod(rs.getString("payment_method"));
		} catch (SQLException ignored) {
		}

		try {
			t.setTransactionId(rs.getString("reference_id"));
		} catch (SQLException ignored) {
		}

		try {
			double ba = rs.getDouble("balance_after");
			t.setBalanceAfter(rs.wasNull() ? 0.0 : ba);
		} catch (SQLException ignored) {
		}

		return t;
	}
}
