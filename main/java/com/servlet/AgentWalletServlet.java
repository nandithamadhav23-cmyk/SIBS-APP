package com.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.math.BigDecimal;
import java.util.List;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

import org.json.JSONObject;

import com.DAO.AgentWalletDAO;
import com.razorpay.RazorpayClient;
import com.util.AgentWallet;
import com.util.AgentWalletTransaction;
import com.util.User;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

/**
 * AgentWalletServlet — JSON API for the Agent Wallet / Earnings feature.
 *
 * URL: /AgentWalletServlet?action=<action>
 *
 * ════════════════════════════════════════════════════════════════════
 * IMPORTANT: Action names here MUST match what DeliveryPortal.jsp calls. The
 * JSP calls: GET ?action=getWallet → wallet summary + earnings + chart GET
 * ?action=getTransactions → transaction list (flat array, not paginated object)
 * POST action=requestWithdrawal param: amount POST action=depositCash params:
 * orderId, amount, notes (COD deposit)
 * ════════════════════════════════════════════════════════════════════
 *
 * ALSO AVAILABLE (for staff / internal use): GET ?action=canAccept param:
 * amount → can agent accept COD order? POST action=holdCod params: orderId,
 * amount, ref POST action=releaseCod params: orderId, amount POST
 * action=creditFee params: orderId, amount, isCod POST action=addFunds params:
 * agentId (optional), amount, note
 */
@WebServlet("/AgentWalletServlet")
public class AgentWalletServlet extends HttpServlet {

	private static final long serialVersionUID = 1L;
	private static final java.time.format.DateTimeFormatter ISO_FMT = java.time.format.DateTimeFormatter
			.ofPattern("yyyy-MM-dd'T'HH:mm:ss");

	// ── GET ──────────────────────────────────────────────────────────────────

	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {

		resp.setContentType("application/json");
		resp.setCharacterEncoding("UTF-8");
		PrintWriter out = resp.getWriter();

		int agentId = resolveAgentId(req, resp);
		if (agentId == -1) {
			return;
		}

		String action = req.getParameter("action");
		if (action == null) {
			action = "getWallet";
		}

		AgentWalletDAO dao = new AgentWalletDAO();

		try {
			switch (action) {

			// ── GET WALLET ─────────────────────────────────────────────────
			// Called by DeliveryPortal.jsp loadWalletData() → ?action=getWallet
			// Returns wallet balance, COD float, earnings (today/week/month),
			// weekly chart breakdown — all in ONE response.
			case "getWallet": {
				AgentWallet w = dao.getWallet(agentId);
				BigDecimal today = dao.getEarningsToday(agentId);
				BigDecimal week = dao.getEarningsThisWeek(agentId);
				BigDecimal month = dao.getEarningsThisMonth(agentId);

				double[] chart = dao.getWeeklyBreakdown(agentId);
				StringBuilder sb = new StringBuilder();
				sb.append("{");
				// Balance fields
				sb.append("\"balance\":").append(w.getBalance()).append(",");
				sb.append("\"codFloat\":").append(w.getCodFloat()).append(",");
				sb.append("\"availableBalance\":").append(w.getAvailableBalance()).append(",");
				sb.append("\"minBalance\":").append(w.getMinBalance()).append(",");
				sb.append("\"totalEarned\":").append(w.getTotalEarned()).append(",");
				sb.append("\"totalWithdrawn\":").append(w.getTotalWithdrawn()).append(",");
				sb.append("\"cashInHand\":").append(w.getCashInHand()).append(",");
				sb.append("\"withdrawable\":").append(w.getWithdrawable()).append(",");
				sb.append("\"isHealthy\":").append(w.isHealthy()).append(",");
				// Earnings strip (used by _renderEarningsStrip in JSP)
				sb.append("\"earningsToday\":").append(today).append(",");
				sb.append("\"earningsWeek\":").append(week).append(",");
				sb.append("\"earningsMonth\":").append(month).append(",");
				// Weekly bar chart — named weeklyBreakdown to match JSP's d.weeklyBreakdown
				sb.append("\"weeklyBreakdown\":[");
				for (int i = 0; i < chart.length; i++) {
					sb.append(chart[i]);
					if (i < chart.length - 1) {
						sb.append(",");
					}
				}
				sb.append("]");
				sb.append("}");
				out.print(sb.toString());
				break;
			}

			// ── GET TRANSACTIONS ───────────────────────────────────────────
			// Called by DeliveryPortal.jsp → ?action=getTransactions
			// Returns a FLAT JSON ARRAY (not a paginated object) because the JSP
			// does client-side pagination with _allTxns / _renderTxnPage().
			//
			// Each item has: createdAt (ISO string), description, orderId,
			// type, amount, balanceAfter, isCredit
			case "getTransactions": {
				int limit = paramInt(req, "limit", 100); // generous limit for client-side paging
				List<AgentWalletTransaction> txns = dao.getRecentTransactions(agentId, limit);

				StringBuilder sb = new StringBuilder();
				sb.append("[");
				for (int i = 0; i < txns.size(); i++) {
					AgentWalletTransaction t = txns.get(i);
					sb.append("{");
					sb.append("\"id\":").append(t.getId()).append(",");
					sb.append("\"orderId\":").append(t.getOrderId() > 0 ? t.getOrderId() : "null").append(",");
					sb.append("\"type\":\"").append(esc(t.getType())).append("\",");
					sb.append("\"typeLabel\":\"").append(esc(t.getTypeLabel())).append("\",");
					sb.append("\"isCredit\":").append(t.isCredit()).append(",");
					sb.append("\"amount\":").append(t.getAmount()).append(",");
					sb.append("\"balanceAfter\":").append(t.getBalanceAfter()).append(",");
					sb.append("\"description\":\"").append(esc(t.getDescription())).append("\",");
					// ISO timestamp string so JS new Date(t.createdAt) works correctly
					sb.append("\"createdAt\":\"")
							.append(t.getCreatedAt() != null ? t.getCreatedAt().toLocalDateTime().format(ISO_FMT) : "")
							.append("\"");
					sb.append("}");
					if (i < txns.size() - 1) {
						sb.append(",");
					}
				}
				sb.append("]");
				out.print(sb.toString());
				break;
			}

			// ── CAN ACCEPT COD ────────────────────────────────────────────
			// Called before assigning a COD order to check agent's balance health.
			case "canAccept": {
				String amtStr = req.getParameter("amount");
				if (amtStr == null) {
					error(resp, 400, "amount required");
					return;
				}
				BigDecimal amount = new BigDecimal(amtStr);
				boolean can = dao.canAcceptCodOrder(agentId, amount);
				AgentWallet w = dao.getWallet(agentId);
				out.print("{\"canAccept\":" + can + ",\"balance\":" + w.getBalance() + ",\"codFloat\":"
						+ w.getCodFloat() + ",\"minBalance\":" + w.getMinBalance() + ",\"message\":\""
						+ (can ? "Agent can accept this COD order."
								: "Insufficient wallet balance. Agent must maintain min ₹" + w.getMinBalance()
										+ " after COD hold.")
						+ "\"}");
				break;
			}

			// ── PENDING COD DEPOSITS ───────────────────────────────────────
			// Returns orders where agent delivered COD but hasn't deposited cash yet.
			case "pendingDeposits": {
				List<double[]> pending = dao.getPendingCodDeposits(agentId);
				StringBuilder sb = new StringBuilder("[");
				for (int i = 0; i < pending.size(); i++) {
					sb.append("{\"orderId\":").append((int) pending.get(i)[0]).append(",\"amount\":")
							.append(String.format("%.2f", pending.get(i)[1])).append("}");
					if (i < pending.size() - 1) {
						sb.append(",");
					}
				}
				sb.append("]");
				out.print(sb.toString());
				break;
			}

			default:
				error(resp, 400, "Unknown action: " + action);
			}

		} catch (Exception e) {
			e.printStackTrace();
			error(resp, 500, "Server error: " + e.getMessage());
		}
	}

	// ── POST ─────────────────────────────────────────────────────────────────

	@Override
	protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {

		resp.setContentType("application/json");
		resp.setCharacterEncoding("UTF-8");
		PrintWriter out = resp.getWriter();

		int agentId = resolveAgentId(req, resp);
		if (agentId == -1) {
			return;
		}

		String action = req.getParameter("action");
		if (action == null) {
			error(resp, 400, "action required");
			return;
		}

		AgentWalletDAO dao = new AgentWalletDAO();

		try {
			switch (action) {

			// ── REQUEST WITHDRAWAL ─────────────────────────────────────────
			// Called by DeliveryPortal.jsp withdraw modal → action=requestWithdrawal
			case "requestWithdrawal": {
				BigDecimal amount = requiredDecimal(req, resp, "amount");
				if (amount == null) {
					return;
				}
				if (amount.compareTo(new BigDecimal("100")) < 0) {
					out.print("{\"success\":false,\"message\":\"Minimum withdrawal amount is ₹100.\"}");
					return;
				}
				// Resolve agent name from session for the request record
				HttpSession sess = req.getSession(false);
				String agentName = "Agent #" + agentId;
				if (sess != null) {
					Object userObj = sess.getAttribute("deliveryUser");
					if (userObj instanceof User) {
						String uname = ((User) userObj).getUsername();
						if (uname != null) {
							agentName = uname;
						}
					}
				}
				String reason = req.getParameter("reason");
				try {
					int requestId = dao.createWithdrawalRequest(agentId, agentName, amount, reason);
					if (requestId > 0) {
						out.print("{\"success\":true,\"message\":\"Withdrawal request of ₹" + amount.toPlainString()
								+ " submitted. Staff will process within 24 hours.\"," + "\"requestId\":" + requestId
								+ "}");
					} else {
						out.print("{\"success\":false,\"message\":\"Could not submit request. Please try again.\"}");
					}
				} catch (IllegalStateException ise) {
					out.print("{\"success\":false,\"message\":\"" + esc(ise.getMessage()) + "\"}");
				}
				break;
			}

			// ── HOLD COD (internal — called when agent picks up COD order) ─
			case "holdCod": {
				int orderId = paramInt(req, "orderId", 0);
				BigDecimal amt = requiredDecimal(req, resp, "amount");
				String ref = req.getParameter("ref");
				if (amt == null || orderId == 0) {
					error(resp, 400, "orderId and amount required");
					return;
				}
				boolean can = dao.canAcceptCodOrder(agentId, amt);
				if (!can) {
					out.print("{\"success\":false,\"code\":\"INSUFFICIENT_BALANCE\","
							+ "\"message\":\"Wallet balance too low to accept this COD order. "
							+ "Please wait for settlements or contact staff to top up your wallet.\"}");
					return;
				}
				boolean ok = dao.holdCodAmount(agentId, orderId, amt, ref != null ? ref : "");
				out.print("{\"success\":" + ok + "}");
				break;
			}

			// ── RELEASE COD (internal — called on OTP delivery confirmation) ─
			case "releaseCod": {
				int orderId = paramInt(req, "orderId", 0);
				BigDecimal amt = requiredDecimal(req, resp, "amount");
				if (amt == null || orderId == 0) {
					error(resp, 400, "orderId and amount required");
					return;
				}
				boolean ok = dao.releaseCodHold(agentId, orderId, amt);
				out.print("{\"success\":" + ok + "}");
				break;
			}

			// ── CREDIT FEE (internal — called after delivery confirmed) ────
			case "creditFee": {
				int orderId = paramInt(req, "orderId", 0);
				BigDecimal fee = requiredDecimal(req, resp, "amount");
				boolean isCod = "true".equalsIgnoreCase(req.getParameter("isCod"));
				if (fee == null || orderId == 0) {
					error(resp, 400, "orderId and amount required");
					return;
				}
				boolean ok = dao.creditDeliveryFee(agentId, orderId, fee.doubleValue(), isCod);
				out.print("{\"success\":" + ok + "}");
				break;
			}

			// ── ADD FUNDS (staff only) ──────────────────────────────────────
			case "addFunds": {
				String targetParam = req.getParameter("agentId");
				int targetId = targetParam != null ? Integer.parseInt(targetParam) : agentId;
				BigDecimal amt = requiredDecimal(req, resp, "amount");
				if (amt == null) {
					return;
				}
				String note = req.getParameter("note");
				boolean ok = dao.addFunds(targetId, amt, note);
				out.print("{\"success\":" + ok + "}");
				break;
			}

			case "createTopupOrder": {
				BigDecimal amount = requiredDecimal(req, resp, "amount");
				if (amount == null) {
					return;
				}

				if (amount.compareTo(new BigDecimal("100")) < 0) {
					out.print("{\"success\":false,\"message\":\"Minimum top-up amount is ₹100.\"}");
					return;
				}

				String keyId = getServletContext().getInitParameter("razorpay.key_id");
				String keySecret = getServletContext().getInitParameter("razorpay.key_secret");

				try {
					RazorpayClient razorpay = new RazorpayClient(keyId, keySecret);

					JSONObject orderRequest = new JSONObject();
					orderRequest.put("amount", amount.multiply(new BigDecimal("100")).intValue()); // paise
					orderRequest.put("currency", "INR");
					orderRequest.put("receipt", "wallet_topup_" + agentId + "_" + System.currentTimeMillis());
					orderRequest.put("payment_capture", 1);
					// Optional: tag as wallet top-up for reconciliation
					JSONObject notes = new JSONObject();
					notes.put("purpose", "wallet_topup");
					notes.put("agent_id", String.valueOf(agentId));
					orderRequest.put("notes", notes);

					com.razorpay.Order rzpOrder = razorpay.orders.create(orderRequest);

					// Get agent name and phone for Razorpay prefill
					AgentWallet wallet = dao.getWallet(agentId);
					// Resolve name/contact from session
					HttpSession sess = req.getSession(false);
					String agentName = "";
					String agentContact = "";
					if (sess != null) {
						Object userObj = sess.getAttribute("deliveryUser");
						if (userObj instanceof com.util.User) {
							com.util.User u = (com.util.User) userObj;
							agentName = u.getUsername() != null ? u.getUsername() : "";
							agentContact = u.getMobileno() != null ? u.getMobileno() : "";
						}
					}

					out.print("{\"success\":true," + "\"razorpayOrderId\":\"" + rzpOrder.get("id") + "\","
							+ "\"amount\":" + rzpOrder.get("amount") + "," // paise
							+ "\"key\":\"" + keyId + "\"," + "\"agentName\":\"" + esc(agentName) + "\","
							+ "\"agentContact\":\"" + esc(agentContact) + "\"}");

				} catch (Exception e) {
					e.printStackTrace();
					out.print("{\"success\":false,\"message\":\"Payment gateway error: " + esc(e.getMessage()) + "\"}");
				}
				break;
			}

			// ── CASE 2: Verify Razorpay payment and credit wallet ─────────────────────
			case "topupVerify": {
				String rzpOrderId = req.getParameter("razorpay_order_id");
				String rzpPaymentId = req.getParameter("razorpay_payment_id");
				String rzpSignature = req.getParameter("razorpay_signature");
				String amtStr = req.getParameter("amount");
				BigDecimal amountRupees = new BigDecimal(amtStr);
				if (rzpOrderId == null || rzpPaymentId == null || rzpSignature == null || amountRupees == null) {
					out.print("{\"success\":false,\"message\":\"Missing payment verification parameters.\"}");
					return;
				}
				if (amountRupees.compareTo(new BigDecimal("50000")) > 0) {
					out.print("{\"success\":false,\"message\":\"Amount exceeds single-deposit limit.\"}");
					return;
				}
				String keySecret = getServletContext().getInitParameter("razorpay.key_secret");

				try {
					// ── Verify Razorpay signature (HMAC-SHA256) ──────────────────────
					// Signature = HMAC_SHA256(key_secret, razorpay_order_id + "|" +
					// razorpay_payment_id)
					String payload = rzpOrderId + "|" + rzpPaymentId;
					Mac mac = Mac.getInstance("HmacSHA256");
					mac.init(new SecretKeySpec(keySecret.getBytes("UTF-8"), "HmacSHA256"));
					byte[] hash = mac.doFinal(payload.getBytes("UTF-8"));

					// Convert to hex
					StringBuilder hexSig = new StringBuilder();
					for (byte b : hash) {
						hexSig.append(String.format("%02x", b));
					}
					String expectedSig = hexSig.toString();

					if (!expectedSig.equals(rzpSignature)) {
						// Signature mismatch — possible tamper
						java.util.logging.Logger.getLogger(getClass().getName()).severe(
								"TOPUP SIGNATURE MISMATCH | agent #" + agentId + " | paymentId=" + rzpPaymentId);
						out.print(
								"{\"success\":false,\"message\":\"Payment verification failed. Please contact support.\"}");
						return;
					}

					// ── Signature valid — credit the wallet ──────────────────────────
					String note = "Wallet top-up via Razorpay | Payment ID: " + rzpPaymentId;
					boolean credited = dao.topUpWallet(agentId, amountRupees, note, rzpPaymentId);

					if (!credited) {
						out.print("{\"success\":false,\"message\":\"Payment verified but wallet credit failed. "
								+ "Contact support with payment ID: " + rzpPaymentId + "\"}");
						return;
					}

					// ── Check if agent can now go online ─────────────────────────────
					AgentWallet wallet = dao.getWallet(agentId);
					boolean isNowAboveMin = wallet.getBalance().compareTo(wallet.getMinBalance()) >= 0;
					boolean isNowOnline = false;

					if (isNowAboveMin) {
						// Auto-restore agent status to "active" in the users table
						// (DeliveryPortalServlet's updateStatus action handles this)
						// We call it directly via DAO or the existing UserDAO
						// Simple inline update:
						String updateStatus = "UPDATE users SET status = 'Active' WHERE id = ? AND status = 'Inactive'";
						try (java.sql.Connection conn = com.util.DBConnection.getConnection();
								java.sql.PreparedStatement ps = conn.prepareStatement(updateStatus)) {
							ps.setInt(1, agentId);
							int rows = ps.executeUpdate();
							isNowOnline = (rows > 0); // was inactive, now active

							// Also update session
							HttpSession sess = req.getSession(false);
							if (sess != null && rows > 0) {
								Object userObj = sess.getAttribute("deliveryUser");
								if (userObj instanceof com.util.User) {
									((com.util.User) userObj).setStatus("Active");
								}
							}
						} catch (Exception dbEx) {
							java.util.logging.Logger.getLogger(getClass().getName())
									.warning("Could not auto-restore agent status: " + dbEx.getMessage());
						}
					}

					java.util.logging.Logger.getLogger(getClass().getName())
							.info("WALLET TOPUP SUCCESS | agent #" + agentId + " | ₹" + amountRupees + " | paymentId="
									+ rzpPaymentId + " | isNowOnline=" + isNowOnline);

					out.print("{\"success\":true," + "\"message\":\"₹" + amountRupees.toPlainString()
							+ " added to your wallet.\"," + "\"newBalance\":" + wallet.getBalance() + ","
							+ "\"isNowOnline\":" + isNowOnline + "}");

				} catch (Exception e) {
					e.printStackTrace();
					out.print("{\"success\":false,\"message\":\"Verification error: " + esc(e.getMessage()) + "\"}");
				}
				break;
			}
			default:
				error(resp, 400, "Unknown action: " + action);
			}

		} catch (Exception e) {
			e.printStackTrace();
			error(resp, 500, "Server error: " + e.getMessage());
		}
	}

	// ── Helpers ──────────────────────────────────────────────────────────────

	/**
	 * Resolves agentId from session. Checks "deliveryUser" (delivery portal
	 * session) first, then falls back to "agentId" / "userId" attributes.
	 */
	private int resolveAgentId(HttpServletRequest req, HttpServletResponse resp) throws IOException {
		HttpSession session = req.getSession(false);
		if (session == null) {
			error(resp, 401, "Not authenticated");
			return -1;
		}

		// Primary: delivery portal stores the User object as "deliveryUser"
		Object userObj = session.getAttribute("deliveryUser");
		if (userObj instanceof User) {
			return ((User) userObj).getUid();
		}

		// Fallback: raw agentId / userId attribute
		Object id = session.getAttribute("agentId");
		if (id == null) {
			id = session.getAttribute("userId");
		}
		if (id == null) {
			error(resp, 401, "Agent session not found");
			return -1;
		}

		try {
			return Integer.parseInt(id.toString());
		} catch (NumberFormatException e) {
			error(resp, 400, "Invalid agentId in session");
			return -1;
		}
	}

	private int paramInt(HttpServletRequest req, String name, int def) {
		String v = req.getParameter(name);
		if (v == null) {
			return def;
		}
		try {
			return Integer.parseInt(v.trim());
		} catch (NumberFormatException e) {
			return def;
		}
	}

	private BigDecimal requiredDecimal(HttpServletRequest req, HttpServletResponse resp, String name)
			throws IOException {
		String v = req.getParameter(name);
		if (v == null || v.trim().isEmpty()) {
			error(resp, 400, name + " is required");
			return null;
		}
		try {
			return new BigDecimal(v.trim());
		} catch (NumberFormatException e) {
			error(resp, 400, name + " must be a valid number");
			return null;
		}
	}

	private void error(HttpServletResponse resp, int status, String msg) throws IOException {
		resp.setStatus(status);
		resp.getWriter().print("{\"error\":\"" + esc(msg) + "\",\"success\":false}");
	}

	private String esc(String s) {
		if (s == null) {
			return "";
		}
		return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "");
	}
}