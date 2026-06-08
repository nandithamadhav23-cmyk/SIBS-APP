package com.DAO;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

import com.util.AgentWallet;
import com.util.AgentWalletTransaction;
import com.util.DBConnection;

public class AgentWalletDAO {

	private static final Logger log = Logger.getLogger(AgentWalletDAO.class.getName());

	// ─────────────────────────────────────────────────────────────────────────
	// READ OPERATIONS
	// ─────────────────────────────────────────────────────────────────────────

	/** Fetches the full wallet record; auto-creates row if missing. */
	public AgentWallet getWallet(int agentId) throws Exception {

		Connection conn = DBConnection.getConnection();
		ensureWalletExists(conn, agentId);
		String sql = "SELECT * FROM agent_wallets WHERE agent_id = ?";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, agentId);
			try (ResultSet rs = ps.executeQuery()) {
				if (rs.next()) {
					return mapWallet(rs);
				}
			}
		}
		throw new IllegalStateException("Wallet not found for agent #" + agentId);
	}

	public BigDecimal getEarningsToday(int agentId) throws Exception {
		String sql = "SELECT COALESCE(SUM(amount), 0) FROM agent_wallet_transactions "
				+ "WHERE agent_id = ? AND type IN ('delivery_fee', 'fund_added') " + "AND DATE(created_at) = CURDATE()";
		return querySingleBigDecimal(sql, agentId);
	}

	public BigDecimal getEarningsThisWeek(int agentId) throws Exception {
		String sql = "SELECT COALESCE(SUM(amount), 0) FROM agent_wallet_transactions "
				+ "WHERE agent_id = ? AND type IN ('delivery_fee', 'fund_added') "
				+ "AND YEARWEEK(created_at, 1) = YEARWEEK(CURDATE(), 1)";
		return querySingleBigDecimal(sql, agentId);
	}

	public BigDecimal getEarningsThisMonth(int agentId) throws Exception {
		String sql = "SELECT COALESCE(SUM(amount), 0) FROM agent_wallet_transactions "
				+ "WHERE agent_id = ? AND type IN ('delivery_fee', 'fund_added') "
				+ "AND MONTH(created_at) = MONTH(CURDATE()) " + "AND YEAR(created_at) = YEAR(CURDATE())";
		return querySingleBigDecimal(sql, agentId);
	}

	/** Returns daily earnings for Mon–Sun of the current week (7 values). */
	public double[] getWeeklyBreakdown(int agentId) throws Exception {
		double[] days = new double[7];
		String sql = "SELECT DAYOFWEEK(created_at) AS dow, COALESCE(SUM(amount), 0) AS total "
				+ "FROM agent_wallet_transactions " + "WHERE agent_id = ? AND type IN ('delivery_fee', 'fund_added') "
				+ "AND YEARWEEK(created_at, 1) = YEARWEEK(CURDATE(), 1) " + "GROUP BY dow";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, agentId);
			try (ResultSet rs = ps.executeQuery()) {
				while (rs.next()) {
					int dow = rs.getInt("dow"); // MySQL: 1=Sun … 7=Sat
					int idx = (dow == 1) ? 6 : (dow - 2); // Mon=0 … Sun=6
					if (idx >= 0 && idx < 7) {
						days[idx] = rs.getDouble("total");
					}
				}
			}
		}
		return days;
	}

	public List<AgentWalletTransaction> getRecentTransactions(int agentId, int limit) throws Exception {
		String sql = "SELECT * FROM agent_wallet_transactions " + "WHERE agent_id = ? ORDER BY created_at DESC LIMIT ?";
		List<AgentWalletTransaction> list = new ArrayList<>();
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, agentId);
			ps.setInt(2, limit);
			try (ResultSet rs = ps.executeQuery()) {
				while (rs.next()) {
					list.add(mapTransaction(rs));
				}
			}
		}
		return list;
	}

	/**
	 * Returns COD orders the agent has delivered but not yet deposited cash for. A
	 * "pending deposit" means: a cod_hold exists for this order but no confirmed
	 * cod_remitted record exists yet.
	 */
	public List<double[]> getPendingCodDeposits(int agentId) throws Exception {
		String sql = "SELECT t.order_id, t.amount " + "FROM agent_wallet_transactions t "
				+ "WHERE t.agent_id = ? AND t.type = 'cod_hold' " + "AND NOT EXISTS ( "
				+ "  SELECT 1 FROM agent_wallet_transactions t2 " + "  WHERE t2.agent_id = t.agent_id "
				+ "    AND t2.order_id = t.order_id " + "    AND t2.type = 'cod_remitted' "
				+ "    AND t2.description NOT LIKE '%Pending%' " + ") ORDER BY t.created_at DESC";
		List<double[]> result = new ArrayList<>();
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, agentId);
			try (ResultSet rs = ps.executeQuery()) {
				while (rs.next()) {
					result.add(new double[] { rs.getInt("order_id"), rs.getDouble("amount") });
				}
			}
		}
		return result;
	}

	/**
	 * Checks if the agent has enough balance to take on a new COD order. Rule:
	 * balance (after the hold) must remain >= min_balance. This prevents agents
	 * with insufficient security deposit from carrying cash.
	 */
	public boolean canAcceptCodOrder(int agentId, BigDecimal orderAmount) throws Exception {
		AgentWallet w = getWallet(agentId);
		BigDecimal balanceAfterHold = w.getBalance().subtract(orderAmount);
		return balanceAfterHold.compareTo(w.getMinBalance()) >= 0;
	}

	// ─────────────────────────────────────────────────────────────────────────
	// WRITE OPERATIONS
	// Each method: INSERT transaction row + UPDATE wallet atomically.
	// ─────────────────────────────────────────────────────────────────────────

	/**
	 * STEP 2 — Agent picks up a COD order.
	 *
	 * Increases cod_float by the order amount. The agent is now "carrying" the
	 * customer's cash. balance is NOT changed — this is not the agent's money.
	 *
	 * Called from: OrderServlet when status transitions to "Picked Up" (COD only).
	 */
	public boolean holdCodAmount(int agentId, int orderId, BigDecimal amount, String ref) {
		// Guard: don't double-hold the same order
		if (hasTransactionOfType(agentId, orderId, "cod_hold")) {
			log.warning(
					"holdCodAmount: hold already exists for agent #" + agentId + " order #" + orderId + " — skipped");
			return true; // idempotent
		}

		String desc = "COD hold — Order #" + orderId + (ref != null && !ref.isEmpty() ? " | " + ref : "");
		try (Connection conn = DBConnection.getConnection()) {
			conn.setAutoCommit(false);
			try {
				double currentBalance = getCurrentBalance(conn, agentId);
				double currentFloat = getCurrentCodFloat(conn, agentId);
				// Transaction type: cod_hold — balance_after shows wallet balance unchanged
				insertTransaction(conn, agentId, orderId, "cod_hold", amount.doubleValue(), currentBalance,
						currentFloat, desc);

				// Only cod_float increases. balance does NOT change.
				String upd = "UPDATE agent_wallets SET cod_float = cod_float + ?, updated_at = NOW() WHERE agent_id = ?";
				try (PreparedStatement ps = conn.prepareStatement(upd)) {
					ps.setBigDecimal(1, amount);
					ps.setInt(2, agentId);
					ps.executeUpdate();
				}

				conn.commit();
				log.info("holdCodAmount: agent #" + agentId + " cod_float +₹" + amount + " order #" + orderId);
				return true;

			} catch (Exception e) {
				conn.rollback();
				log.log(Level.SEVERE, "holdCodAmount failed", e);
				return false;
			}
		} catch (Exception e) {
			log.log(Level.SEVERE, "DB connection error in holdCodAmount", e);
			return false;
		}
	}

	/**
	 * STEP 3a — OTP verified: release the COD hold.
	 *
	 * Decreases cod_float — agent has collected cash from customer, delivery done.
	 * balance is NOT changed here. creditDeliveryFee() handles the earnings.
	 *
	 * Called from: OtpVerificationServlet (OTP path) and
	 * OrderServlet.agentConfirmCodDelivery() (manual fallback).
	 */
	public boolean releaseCodHold(int agentId, int orderId, BigDecimal amount) {
		// Guard: don't double-release
		if (hasTransactionOfType(agentId, orderId, "cod_released")) {
			log.warning("releaseCodHold: already released for agent #" + agentId + " order #" + orderId + " — skipped");
			return true;
		}

		String desc = "COD hold released — Order #" + orderId;
		try (Connection conn = DBConnection.getConnection()) {
			conn.setAutoCommit(false);
			try {
				double currentBalance = getCurrentBalance(conn, agentId);
				double currentFloat = getCurrentCodFloat(conn, agentId);
				insertTransaction(conn, agentId, orderId, "cod_released", amount.doubleValue(), currentBalance,
						currentFloat, desc);

				// GREATEST(0, ...) prevents cod_float going negative if hold was missing
				String upd = "UPDATE agent_wallets SET cod_float = GREATEST(0, cod_float - ?), updated_at = NOW() WHERE agent_id = ?";
				try (PreparedStatement ps = conn.prepareStatement(upd)) {
					ps.setBigDecimal(1, amount);
					ps.setInt(2, agentId);
					ps.executeUpdate();
				}

				conn.commit();
				log.info("releaseCodHold: agent #" + agentId + " cod_float -₹" + amount + " order #" + orderId);
				return true;

			} catch (Exception e) {
				conn.rollback();
				log.log(Level.SEVERE, "releaseCodHold failed", e);
				return false;
			}
		} catch (Exception e) {
			log.log(Level.SEVERE, "DB connection error in releaseCodHold", e);
			return false;
		}
	}

	/**
	 * STEP 3b — OTP verified: credit the delivery fee to the agent.
	 *
	 * This is the ONLY place the agent's balance and total_earned increase. Fee:
	 * ₹60 for COD orders (cash handling risk), ₹40 for prepaid orders.
	 *
	 * Called from: OtpVerificationServlet (OTP path) and OrderServlet when status →
	 * "Delivered" (manual staff path).
	 */
	public boolean creditDeliveryFee(int agentId, int orderId, double fee, boolean isCod) {
		// Guard: don't credit the same order twice
		if (hasTransactionOfType(agentId, orderId, "delivery_fee")) {
			log.warning("creditDeliveryFee: fee already credited for agent #" + agentId + " order #" + orderId
					+ " — skipped");
			return true;
		}

		String desc = "Delivery fee — Order #" + orderId + (isCod ? " (COD)" : " (Prepaid)");
		try (Connection conn = DBConnection.getConnection()) {
			conn.setAutoCommit(false);
			try {
				double currentBalance = getCurrentBalance(conn, agentId);
				double balanceAfter = currentBalance + fee;
				double currentFloat = getCurrentCodFloat(conn, agentId);

				insertTransaction(conn, agentId, orderId, "delivery_fee", fee, balanceAfter, currentFloat, desc);

				// balance increases by fee. total_earned tracks lifetime earnings.
				String upd = "UPDATE agent_wallets "
						+ "SET balance = balance + ?, total_earned = total_earned + ?, updated_at = NOW() "
						+ "WHERE agent_id = ?";
				try (PreparedStatement ps = conn.prepareStatement(upd)) {
					ps.setDouble(1, fee);
					ps.setDouble(2, fee);
					ps.setInt(3, agentId);
					ps.executeUpdate();
				}

				conn.commit();
				log.info("creditDeliveryFee: agent #" + agentId + " balance +₹" + fee + " for order #" + orderId
						+ " | new balance ₹" + balanceAfter);
				return true;

			} catch (Exception e) {
				conn.rollback();
				log.log(Level.SEVERE, "creditDeliveryFee failed for agent #" + agentId + " order #" + orderId, e);
				return false;
			}
		} catch (Exception e) {
			log.log(Level.SEVERE, "DB connection error in creditDeliveryFee", e);
			return false;
		}
	}

	/**
	 * STEP 4 & 5 — COD cash deposit: agent submission + staff confirmation.
	 *
	 * Call 1 (agent submits): receivedBy = "Pending staff confirmation" → Inserts a
	 * pending transaction record only. → cod_float NOT changed yet (staff hasn't
	 * confirmed cash physically).
	 *
	 * Call 2 (staff confirms): receivedBy = any non-"Pending" value (e.g. staff
	 * name) → Inserts a confirmed transaction record. → cod_float -= amount (cash
	 * is officially handed over). → balance is NOT changed (already credited at
	 * step 3b).
	 *
	 * DUPLICATE GUARD: if a confirmed record already exists for this order, returns
	 * true without inserting — safe for network retries.
	 *
	 * Called from: AgentWalletServlet (action=depositCash) for agent submission.
	 * CodDepositServlet (action=staffConfirm) for staff confirmation. OrderServlet
	 * (action=confirmCodDeposit) for staff dashboard confirmation.
	 */
	public boolean recordCodDeposit(int agentId, int orderId, BigDecimal amount, String receivedBy, String notes) {
		boolean isConfirmed = receivedBy != null && !receivedBy.toLowerCase().contains("pending");

// Idempotent guard — don't process a confirmed deposit twice

		String desc = "COD cash remitted — Order #" + orderId + " | Received by: " + receivedBy
				+ (notes != null && !notes.isEmpty() ? " | " + notes : "");

		try (Connection conn = DBConnection.getConnection()) {
			conn.setAutoCommit(false);

			String checkSql = "SELECT 1 FROM agent_wallet_transactions "
					+ "WHERE agent_id = ? AND order_id = ? AND type = 'cod_remitted' "
					+ "AND description NOT LIKE '%Pending%' LIMIT 1";
			try (PreparedStatement ps = conn.prepareStatement(checkSql)) {
				ps.setInt(1, agentId);
				ps.setInt(2, orderId);
				try (ResultSet rs = ps.executeQuery()) {
					if (rs.next()) {
						conn.rollback();
						log.warning("recordCodDeposit: already confirmed for order #" + orderId + " — skipped");
						return true;
					}
				}
			}
			try {
				double currentBalance = getCurrentBalance(conn, agentId);
				double currentFloat = getCurrentCodFloat(conn, agentId);

// Upsert: delete any prior PENDING row for this order, then insert fresh
				String delPending = "DELETE FROM agent_wallet_transactions "
						+ "WHERE agent_id=? AND order_id=? AND type='cod_remitted' "
						+ "AND description LIKE '%Pending%'";
				try (PreparedStatement ps = conn.prepareStatement(delPending)) {
					ps.setInt(1, agentId);
					ps.setInt(2, orderId);
					ps.executeUpdate();
				}

				insertTransaction(conn, agentId, orderId, "cod_remitted", amount.doubleValue(), currentBalance,
						currentFloat, desc);

				if (isConfirmed) {
// Staff confirmed cash receipt → mark order DEPOSITED; status stays 'Delivered'
// 'History' is NOT a valid ENUM value for the status column.
					String updOrder = "UPDATE orders SET " + "  cod_deposited  = 1, " + "  cod_deposit_at = NOW(), "
							+ "  payment_status = 'DEPOSITED' " + "WHERE order_id = ?";
					try (PreparedStatement ps = conn.prepareStatement(updOrder)) {
						ps.setInt(1, orderId);
						ps.executeUpdate();
					}
					log.info("recordCodDeposit CONFIRMED: order #" + orderId + " → DEPOSITED");
				} else {
// Agent submitted cash — mark as pending, status stays Delivered
					String updOrder = "UPDATE orders SET payment_status='DEPOSIT_PENDING' "
							+ "WHERE order_id=? AND payment_status != 'DEPOSITED'";
					try (PreparedStatement ps = conn.prepareStatement(updOrder)) {
						ps.setInt(1, orderId);
						ps.executeUpdate();
					}
					log.info("recordCodDeposit PENDING: order #" + orderId + " awaiting staff confirmation");
				}

				conn.commit();
				return true;

			} catch (Exception e) {
				conn.rollback();
				log.log(Level.SEVERE, "recordCodDeposit failed", e);
				return false;
			}
		} catch (Exception e) {
			log.log(Level.SEVERE, "DB connection error in recordCodDeposit", e);
			return false;
		}
	}

	/**
	 * Staff-side: add funds to an agent's wallet (initial top-up / advance). This
	 * is how agents get their minimum balance (₹500) at onboarding. Also used if
	 * agent's balance drops and needs replenishment.
	 *
	 * Called from: AgentWalletServlet (action=addFunds) — staff only.
	 */
	public boolean addFunds(int agentId, BigDecimal amount, String note) {
		String desc = "Funds added by staff" + (note != null && !note.isEmpty() ? ": " + note : "");
		try (Connection conn = DBConnection.getConnection()) {
			conn.setAutoCommit(false);
			try {
				ensureWalletExists(conn, agentId);
				double currentBalance = getCurrentBalance(conn, agentId);
				double balanceAfter = currentBalance + amount.doubleValue();
				double currentFloat = getCurrentCodFloat(conn, agentId);

				insertTransaction(conn, agentId, 0, "fund_added", amount.doubleValue(), balanceAfter, currentFloat,
						desc);

				String upd = "UPDATE agent_wallets "
						+ "SET balance = balance + ?, total_earned = total_earned + ?, updated_at = NOW() "
						+ "WHERE agent_id = ?";
				try (PreparedStatement ps = conn.prepareStatement(upd)) {
					ps.setBigDecimal(1, amount);
					ps.setBigDecimal(2, amount);
					ps.setInt(3, agentId);
					ps.executeUpdate();
				}

				conn.commit();
				log.info("addFunds: agent #" + agentId + " balance +₹" + amount + " | new balance ₹" + balanceAfter);
				return true;

			} catch (Exception e) {
				conn.rollback();
				log.log(Level.SEVERE, "addFunds failed for agent #" + agentId, e);
				return false;
			}
		} catch (Exception e) {
			log.log(Level.SEVERE, "DB connection error in addFunds", e);
			return false;
		}
	}

	/**
	 * Agent withdrawal request. Withdrawable amount = balance - cod_float -
	 * min_balance. The agent cannot touch their security deposit (min_balance).
	 */
	public void requestWithdrawal(int agentId, BigDecimal amount) throws Exception {
		try (Connection conn = DBConnection.getConnection()) {
			conn.setAutoCommit(false);
			try {
				// Lock the wallet row for this transaction — prevents concurrent withdrawals
				String lockSql = "SELECT balance, cod_float, min_balance "
						+ "FROM agent_wallets WHERE agent_id = ? FOR UPDATE";
				double balance, codFloat, minBalance;
				try (PreparedStatement ps = conn.prepareStatement(lockSql)) {
					ps.setInt(1, agentId);
					try (ResultSet rs = ps.executeQuery()) {
						if (!rs.next()) {
							throw new IllegalStateException("Wallet not found.");
						}
						balance = rs.getDouble("balance");
						codFloat = rs.getDouble("cod_float");
						minBalance = rs.getDouble("min_balance");
					}
				}
				double available = Math.max(0, balance - codFloat - minBalance);
				if (amount.doubleValue() > available) {
					throw new IllegalStateException(
							"Insufficient balance. Available for withdrawal: ₹" + String.format("%.2f", available));
				}
				double balanceAfter = balance - amount.doubleValue();

				double currentFloat = getCurrentCodFloat(conn, agentId);
				String desc = "Withdrawal request of ₹" + amount.toPlainString();
				insertTransaction(conn, agentId, 0, "withdrawal", amount.doubleValue(), balanceAfter, currentFloat,
						desc);
				String upd = "UPDATE agent_wallets "
						+ "SET balance = balance - ?, total_withdrawn = total_withdrawn + ?, updated_at = NOW() "
						+ "WHERE agent_id = ?";
				try (PreparedStatement ps = conn.prepareStatement(upd)) {
					ps.setBigDecimal(1, amount);
					ps.setBigDecimal(2, amount);
					ps.setInt(3, agentId);
					ps.executeUpdate();
				}
				conn.commit();
			} catch (IllegalStateException ise) {
				conn.rollback();
				throw ise;
			} catch (Exception e) {
				conn.rollback();
				throw e;
			}
		}
	}

	public boolean topUpWallet(int agentId, BigDecimal amount, String description, String razorpayPaymentId) {
		// Idempotency guard — check if this payment was already processed

		if (razorpayPaymentId == null || razorpayPaymentId.isBlank()) {
			log.severe("topUpWallet called with null/blank paymentId for agent #" + agentId);
			return false;
		}
		String checkSql = "SELECT COUNT(*) FROM agent_wallet_transactions "
				+ "WHERE agent_id = ? AND description LIKE ?";

		String exactPattern = "%Payment ID: " + razorpayPaymentId + "%";
		try (Connection conn = DBConnection.getConnection();
				PreparedStatement check = conn.prepareStatement(checkSql)) {
			check.setInt(1, agentId);
			check.setString(2, exactPattern);
			try (ResultSet rs = check.executeQuery()) {
				if (rs.next() && rs.getInt(1) > 0) {
					log.warning("topUpWallet: payment " + razorpayPaymentId + " already processed for agent #" + agentId
							+ " — skipped");
					return true; // idempotent
				}
			}
		} catch (Exception e) {
			log.log(Level.SEVERE, "topUpWallet idempotency check failed", e);
			return false;
		}

		try (Connection conn = DBConnection.getConnection()) {
			conn.setAutoCommit(false);
			try {
				double currentBalance = getCurrentBalance(conn, agentId);
				double newBalance = currentBalance + amount.doubleValue();
				double currentFloat = getCurrentCodFloat(conn, agentId);

				// Insert transaction row (type = "credit")
				insertTransaction(conn, agentId, 0, "credit", amount.doubleValue(), newBalance, currentFloat,
						description);

				// Update wallet: balance += amount, total_earned += amount (top-ups count as
				// earning)
				// Note: We do NOT add to total_earned for top-ups — it's a deposit, not
				// earnings.
				// Only balance increases. total_earned tracks delivery fee income.
				String upd = "UPDATE agent_wallets " + "SET balance = balance + ?, updated_at = NOW() "
						+ "WHERE agent_id = ?";
				try (PreparedStatement ps = conn.prepareStatement(upd)) {
					ps.setBigDecimal(1, amount);
					ps.setInt(2, agentId);
					ps.executeUpdate();
				}

				conn.commit();
				log.info("topUpWallet: agent #" + agentId + " balance +₹" + amount + " | paymentId="
						+ razorpayPaymentId);
				return true;

			} catch (Exception e) {
				conn.rollback();
				log.log(Level.SEVERE, "topUpWallet transaction failed", e);
				return false;
			}
		} catch (Exception e) {
			log.log(Level.SEVERE, "DB connection error in topUpWallet", e);
			return false;
		}
	}

	// ─────────────────────────────────────────────────────────────────────────
	// PRIVATE HELPERS
	// ─────────────────────────────────────────────────────────────────────────

	private void insertTransaction(Connection conn, int agentId, int orderId, String type, double amount,
			double balanceAfter, double codFloat, String description) throws SQLException {
		String sql = "INSERT INTO agent_wallet_transactions "
				+ "(agent_id, order_id, type, amount, balance_after,cod_float, description, created_at) "
				+ "VALUES (?, ?, ?, ?, ?,?, ?, NOW())";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, agentId);
			if (orderId > 0) {
				ps.setInt(2, orderId);
			} else {
				ps.setNull(2, Types.INTEGER);
			}
			ps.setString(3, type);
			ps.setDouble(4, amount);
			ps.setDouble(5, balanceAfter);
			ps.setDouble(6, codFloat);
			ps.setString(7, description);
			ps.executeUpdate();
		}
	}

	private double getCurrentBalance(Connection conn, int agentId) throws SQLException {
		String sql = "SELECT balance FROM agent_wallets WHERE agent_id = ?";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, agentId);
			try (ResultSet rs = ps.executeQuery()) {
				if (rs.next()) {
					return rs.getDouble("balance");
				}
			}
		}
		return 0.0;
	}

	private double getCurrentCodFloat(Connection conn, int agentId) throws SQLException {
		String sql = "SELECT cod_float FROM agent_wallets WHERE agent_id = ?";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, agentId);
			try (ResultSet rs = ps.executeQuery()) {
				if (rs.next()) {
					return rs.getDouble("cod_float");
				}
			}
		}
		return 0.0;
	}

	private void ensureWalletExists(Connection conn, int agentId) throws Exception {
		String sql = "INSERT IGNORE INTO agent_wallets "
				+ "(agent_id, balance, cod_float, min_balance, total_earned, total_withdrawn, created_at, updated_at) "
				+ "VALUES (?, 0.00, 0.00, 500.00, 0.00, 0.00, NOW(), NOW())";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, agentId);
			ps.executeUpdate();
		}
	}

	/**
	 * Checks if a transaction of the given type already exists for this agent +
	 * order. Used as idempotency guard in holdCodAmount, releaseCodHold,
	 * creditDeliveryFee.
	 */
	private boolean hasTransactionOfType(int agentId, int orderId, String type) {
		String sql = "SELECT 1 FROM agent_wallet_transactions WHERE agent_id = ? AND order_id = ? AND type = ? LIMIT 1";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, agentId);
			ps.setInt(2, orderId);
			ps.setString(3, type);
			try (ResultSet rs = ps.executeQuery()) {
				return rs.next();
			}
		} catch (Exception e) {
			log.warning("hasTransactionOfType check failed: " + e.getMessage());
			return false; // fail-open: allow the insert to proceed
		}
	}

	private BigDecimal querySingleBigDecimal(String sql, int agentId) throws Exception {
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, agentId);
			try (ResultSet rs = ps.executeQuery()) {
				if (rs.next()) {
					BigDecimal result = rs.getBigDecimal(1);
					return (result != null) ? result : BigDecimal.ZERO;
				}
			}
		}
		return BigDecimal.ZERO;
	}

	// ─────────────────────────────────────────────────────────────────────────
	// WITHDRAWAL REQUESTS (staff-reviewed, two-step: request → approve/reject)
	//
	// Table auto-created on first use:
	// agent_withdrawal_requests (
	// id INT AUTO_INCREMENT PRIMARY KEY,
	// agent_id INT NOT NULL,
	// agent_name VARCHAR(100),
	// amount DECIMAL(12,2) NOT NULL,
	// reason VARCHAR(500),
	// status ENUM('pending','approved','rejected') DEFAULT 'pending',
	// staff_note VARCHAR(500),
	// requested_at DATETIME DEFAULT CURRENT_TIMESTAMP,
	// reviewed_at DATETIME,
	// INDEX idx_agent (agent_id),
	// INDEX idx_status (status)
	// )
	//
	// Flow:
	// 1. Agent taps "Request Withdrawal" on DeliveryPortal →
	// createWithdrawalRequest()
	// 2. Staff sees pending requests on OrdersDashboard "Agent Requests" panel
	// 3. Staff approves → approveWithdrawalRequest() deducts from balance
	// Staff rejects → rejectWithdrawalRequest() records reason, no deduction
	// ─────────────────────────────────────────────────────────────────────────

	private void ensureWithdrawalRequestsTable(Connection conn) throws SQLException {
		String sql = "CREATE TABLE IF NOT EXISTS agent_withdrawal_requests ("
				+ "  id           INT AUTO_INCREMENT PRIMARY KEY," + "  agent_id     INT NOT NULL,"
				+ "  agent_name   VARCHAR(100)," + "  amount       DECIMAL(12,2) NOT NULL,"
				+ "  reason       VARCHAR(500)," + "  status       VARCHAR(20) NOT NULL DEFAULT 'pending',"
				+ "  staff_note   VARCHAR(500)," + "  requested_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,"
				+ "  reviewed_at  DATETIME," + "  INDEX idx_wr_agent  (agent_id)," + "  INDEX idx_wr_status (status)"
				+ ")";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.executeUpdate();
		}
	}

	/**
	 * Agent submits a withdrawal request. Does NOT deduct balance yet — deduction
	 * happens only when staff approves via approveWithdrawalRequest().
	 */
	public int createWithdrawalRequest(int agentId, String agentName, BigDecimal amount, String reason)
			throws Exception {
		AgentWallet w = getWallet(agentId);
		BigDecimal available = w.getWithdrawable();

		// Guard against null amount parameters
		if (amount == null) {
			throw new IllegalArgumentException("Withdrawal amount cannot be null.");
		}

		// FIX: Use compareTo instead of amount.doubleValue() < 100
		if (amount.compareTo(new BigDecimal("100")) < 0) {
			throw new IllegalStateException("Minimum withdrawal amount is ₹100.");
		}

		// FIX: Use compareTo instead of amount.doubleValue() > available
		if (amount.compareTo(available) > 0) {
			throw new IllegalStateException("Insufficient balance. Available: ₹" + available.toPlainString() + ".");
		}

		// Check for an already-pending request from this agent
		try (Connection conn = DBConnection.getConnection()) {
			ensureWithdrawalRequestsTable(conn);

			String checkSql = "SELECT COUNT(*) FROM agent_withdrawal_requests "
					+ "WHERE agent_id = ? AND status = 'pending'";
			try (PreparedStatement ps = conn.prepareStatement(checkSql)) {
				ps.setInt(1, agentId);
				try (ResultSet rs = ps.executeQuery()) {
					if (rs.next() && rs.getInt(1) > 0) {
						throw new IllegalStateException(
								"You already have a pending withdrawal request. Please wait for staff review.");
					}
				}
			}

			String insertSql = "INSERT INTO agent_withdrawal_requests "
					+ "(agent_id, agent_name, amount, reason, status) VALUES (?, ?, ?, ?, 'pending')";
			try (PreparedStatement ps = conn.prepareStatement(insertSql, java.sql.Statement.RETURN_GENERATED_KEYS)) {
				ps.setInt(1, agentId);
				ps.setString(2, agentName != null ? agentName.trim() : "Agent #" + agentId);
				ps.setBigDecimal(3, amount);
				ps.setString(4, reason != null ? reason.trim() : "");

				ps.executeUpdate();
				try (ResultSet rs = ps.getGeneratedKeys()) {
					if (rs.next()) {
						return rs.getInt(1);
					}
				}
			}
		}
		return -1;
	}

	/**
	 * Returns all withdrawal requests filtered by status. Pass null to get all, or
	 * "pending" / "approved" / "rejected".
	 */
	public List<java.util.Map<String, Object>> getWithdrawalRequests(String status) {
		List<java.util.Map<String, Object>> list = new java.util.ArrayList<>();
		try (Connection conn = DBConnection.getConnection()) {
			ensureWithdrawalRequestsTable(conn);
			String sql = "SELECT wr.*, u.username AS uname, u.mobile AS umobile " + "FROM agent_withdrawal_requests wr "
					+ "LEFT JOIN users u ON wr.agent_id = u.id " + (status != null ? "WHERE wr.status = ? " : "")
					+ "ORDER BY wr.requested_at DESC";
			try (PreparedStatement ps = conn.prepareStatement(sql)) {
				if (status != null) {
					ps.setString(1, status);
				}
				try (ResultSet rs = ps.executeQuery()) {
					while (rs.next()) {
						java.util.Map<String, Object> row = new java.util.LinkedHashMap<>();
						row.put("id", rs.getInt("id"));
						row.put("agentId", rs.getInt("agent_id"));
						row.put("agentName",
								rs.getString("uname") != null ? rs.getString("uname") : rs.getString("agent_name"));
						row.put("mobile", rs.getString("umobile"));
						row.put("amount", rs.getDouble("amount"));
						row.put("reason", rs.getString("reason"));
						row.put("status", rs.getString("status"));
						row.put("staffNote", rs.getString("staff_note"));
						row.put("requestedAt", rs.getTimestamp("requested_at"));
						row.put("reviewedAt", rs.getTimestamp("reviewed_at"));
						list.add(row);
					}
				}
			}
		} catch (Exception e) {
			log.log(Level.WARNING, "getWithdrawalRequests failed", e);
		}
		return list;
	}

	/**
	 * Staff APPROVES a withdrawal request. Deducts balance and marks the request
	 * approved atomically.
	 */
	public void approveWithdrawalRequest(int requestId, String staffNote) throws Exception {
		try (Connection conn = DBConnection.getConnection()) {
			conn.setAutoCommit(false);
			try {
				ensureWithdrawalRequestsTable(conn);

				// FIX: Added FOR UPDATE to explicitly lock the row and prevent concurrent race
				// conditions
				String fetchSql = "SELECT * FROM agent_withdrawal_requests "
						+ "WHERE id = ? AND status = 'pending' FOR UPDATE";
				int agentId;

				BigDecimal amount;
				try (PreparedStatement ps = conn.prepareStatement(fetchSql)) {
					ps.setInt(1, requestId);
					try (ResultSet rs = ps.executeQuery()) {
						if (!rs.next()) {
							throw new IllegalStateException(
									"Request #" + requestId + " not found or already reviewed.");
						}
						agentId = rs.getInt("agent_id");
						amount = rs.getBigDecimal("amount");
					}
				}

				// Validate agent still has enough balance
				AgentWallet w = getWallet(agentId);
				BigDecimal available = w.getWithdrawable();

				// FIX: Use compareTo instead of amount.doubleValue() > w.getWithdrawable()
				if (amount.compareTo(available) > 0) {
					throw new IllegalStateException(
							"Agent now has insufficient balance. " + "Available: ₹" + available.toPlainString());
				}

				// FIX: Calculate balance changes securely using BigDecimal arithmetic
				BigDecimal currentBalance = w.getBalance() != null ? w.getBalance() : BigDecimal.ZERO;
				BigDecimal balanceAfter = currentBalance.subtract(amount);
				double currentFloat = getCurrentCodFloat(conn, agentId);

				// Deduct balance
				String deductSql = "UPDATE agent_wallets "
						+ "SET balance = balance - ?, total_withdrawn = total_withdrawn + ?, updated_at = NOW() "
						+ "WHERE agent_id = ?";
				try (PreparedStatement ps = conn.prepareStatement(deductSql)) {
					ps.setBigDecimal(1, amount);
					ps.setBigDecimal(2, amount);
					ps.setInt(3, agentId);
					ps.executeUpdate();
				}

				// Log transaction (safely passing doubleValue only for logging arguments if
				// required by your method footprint)
				insertTransaction(conn, agentId, 0, "withdrawal", amount.doubleValue(), balanceAfter.doubleValue(),
						currentFloat, "Withdrawal approved by staff — request #" + requestId);

				// Mark request approved
				String updSql = "UPDATE agent_withdrawal_requests "
						+ "SET status = 'approved', staff_note = ?, reviewed_at = NOW() WHERE id = ?";
				try (PreparedStatement ps = conn.prepareStatement(updSql)) {
					ps.setString(1, staffNote != null ? staffNote.trim() : "");
					ps.setInt(2, requestId);
					ps.executeUpdate();
				}

				conn.commit();
				log.info("Withdrawal request #" + requestId + " APPROVED — agent #" + agentId + " -₹" + amount);
			} catch (Exception e) {
				conn.rollback();
				throw e;
			}
		}
	}

	/**
	 * Staff REJECTS a withdrawal request. Balance is NOT touched.
	 */
	public void rejectWithdrawalRequest(int requestId, String staffNote) throws Exception {
		try (Connection conn = DBConnection.getConnection()) {
			conn.setAutoCommit(false);
			try {
				ensureWithdrawalRequestsTable(conn);
				String sql = "UPDATE agent_withdrawal_requests "
						+ "SET status = 'rejected', staff_note = ?, reviewed_at = NOW() "
						+ "WHERE id = ? AND status = 'pending'";
				try (PreparedStatement ps = conn.prepareStatement(sql)) {
					ps.setString(1, staffNote != null ? staffNote : "");
					ps.setInt(2, requestId);
					int rows = ps.executeUpdate();
					if (rows == 0) {
						conn.rollback();
						throw new IllegalStateException("Request #" + requestId + " not found or already reviewed.");
					}
				}
				conn.commit();
				log.info("Withdrawal request #" + requestId + " REJECTED");
			} catch (Exception e) {
				conn.rollback();
				throw e;
			}
		}
	}

	// ─────────────────────────────────────────────────────────────────────────
	// MAPPERS
	// ─────────────────────────────────────────────────────────────────────────
	public boolean hasCodHold(int agentId, int orderId) {
		return hasTransactionOfType(agentId, orderId, "cod_hold");
	}

	private AgentWallet mapWallet(ResultSet rs) throws SQLException {
		AgentWallet w = new AgentWallet();
		w.setAgentId(rs.getInt("agent_id"));

		w.setBalance(rs.getBigDecimal("balance")); // not getDouble
		w.setCodFloat(rs.getBigDecimal("cod_float"));
		w.setMinBalance(rs.getBigDecimal("min_balance"));

		w.setTotalEarned(rs.getBigDecimal("total_earned"));
		w.setTotalWithdrawn(rs.getDouble("total_withdrawn"));
		return w;
	}

	private AgentWalletTransaction mapTransaction(ResultSet rs) throws SQLException {
		AgentWalletTransaction t = new AgentWalletTransaction();
		t.setId(rs.getInt("id"));
		t.setAgentId(rs.getInt("agent_id"));
		t.setOrderId(rs.getInt("order_id"));
		t.setType(rs.getString("type"));
		t.setAmount(rs.getDouble("amount"));
		t.setBalanceAfter(rs.getDouble("balance_after"));
		t.setCodFloat(rs.getBigDecimal("cod_float"));
		t.setDescription(rs.getString("description"));
		t.setCreatedAt(rs.getTimestamp("created_at"));
		return t;
	}
}