package com.servlet;

import java.io.IOException;
import java.math.BigDecimal;
import java.sql.Connection;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

import com.DAO.AgentWalletDAO;
import com.DAO.DeliverySlotDAO;
import com.DAO.OrderDAO;
import com.DAO.StaffNotificationDAO;
import com.util.DBConnection;
import com.util.Order;
import com.util.StaffNotification;
import com.util.User;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

/**
 * CodDepositServlet — manages COD cash handover from agent to hub staff.
 *
 * ══════════════════════════════════════════════════════════════════════════
 * REAL-WORLD COD REMITTANCE MODEL
 * ══════════════════════════════════════════════════════════════════════════
 *
 * After delivering a COD order and verifying OTP: - The agent's balance has
 * already been credited with the delivery fee (₹60). - The cod_float has been
 * released (order amount no longer held). - BUT the agent is still physically
 * carrying the customer's cash.
 *
 * The cash must be physically handed to hub staff. This servlet manages that.
 *
 * IMPORTANT DISTINCTION — what cod_float means at each stage:
 *
 * BEFORE PICKUP: cod_float = 0 (no cash yet) AFTER PICKUP: cod_float =
 * orderAmount (agent carrying cash) AFTER OTP: cod_float = 0 (hold released by
 * OtpVerificationServlet) AFTER DEPOSIT: cod_float = 0 (confirmed — already was
 * 0 after OTP)
 *
 * Wait — if cod_float is already 0 after OTP, what does this servlet do?
 *
 * The deposit workflow is a business-level audit trail, NOT a financial change.
 * It records that the physical cash has been verified and accepted by staff.
 * The "cod_remitted" transaction proves the cash handover happened, which is
 * required for accounting and agent accountability (like Blinkit/Swiggy hubs).
 *
 * If the order went through the correct pipeline: holdCodAmount (Picked Up) →
 * releaseCodHold (OTP) → recordCodDeposit (hub) Then cod_float stays consistent
 * throughout.
 *
 * If holdCodAmount was skipped (agent went directly to delivery without the
 * "Picked Up" step), cod_float was 0 from the start — the deposit confirmation
 * still works fine, it just records the audit trail with no float to clear.
 *
 * ══════════════════════════════════════════════════════════════════════════
 * URL MAPPING
 * ══════════════════════════════════════════════════════════════════════════
 * GET /CodDepositServlet → agent's pending deposit list → CodDeposit.jsp GET
 * /CodDepositServlet?action=staff → all pending deposits for staff →
 * CodDeposit.jsp POST action=agentDeposit → agent marks cash as submitted to
 * hub POST action=staffConfirm → staff physically confirms receipt POST
 * action=staffReject → staff flags amount mismatch / dispute
 */
@WebServlet("/CodDepositServlet")
public class CodDepositServlet extends HttpServlet {

	private static final long serialVersionUID = 1L;
	private static final Logger log = Logger.getLogger(CodDepositServlet.class.getName());

	private final AgentWalletDAO walletDAO = new AgentWalletDAO();
	private final OrderDAO orderDAO = new OrderDAO();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		HttpSession session = request.getSession(false);
		String action = request.getParameter("action");

		// ── Staff view: all agents with pending COD deposits ──────────────────
		if ("staff".equals(action)) {
			// Staff identity check
			Object staffUser = session != null ? session.getAttribute("user") : null;
			if (staffUser == null) {
				response.sendRedirect(request.getContextPath() + "/StaffLoginServlet");
				return;
			}

			// 1. Safe connection scope initialization
			try (Connection conn = DBConnection.getConnection()) {

				// Fix: Ensure orderDAO uses the safe managed connection if applicable
				List<Order> allPendingDeposits = orderDAO.getAllDeliveredCodOrdersPendingDeposit();
				request.setAttribute("allPendingDeposits", allPendingDeposits);

				DeliverySlotDAO slotdao = new DeliverySlotDAO(conn);

				// Fix: Parse target slotId from request parameter to satisfy method signature
				int slotId = parseIntParam(request, "slotId");

				// Fix: Correct variable type to catch the returned primitive long[] array
				long[] summary = slotdao.getUndepositedCodSummary(slotId);

				// Map array positions into explicit context attributes for your JSP page
				request.setAttribute("undepositedCount", summary[0]);
				request.setAttribute("undepositedTotal", summary[1]);

				request.setAttribute("viewMode", "staff");
				request.getRequestDispatcher("CodDeposit.jsp").forward(request, response);

			} catch (Exception e) {
				log.log(Level.SEVERE, "CodDepositServlet staff GET error", e);
				throw new ServletException(e);
			}
			return;

		}

		// ── Agent view: their own pending deposits ─────────────────────────────
		User user = (session != null) ? (User) session.getAttribute("deliveryUser") : null;
		if (user == null) {
			response.sendRedirect(request.getContextPath() + "/deliveryLogin.jsp");
			return;
		}

		try {
			int agentId = user.getUid();

			// Load all COD orders for this agent that are Delivered but not yet deposited
			// "Not yet deposited" = no confirmed cod_remitted record for the order
			List<Order> pendingOrders = orderDAO.getDeliveredCodOrdersPendingDeposit(agentId);

			request.setAttribute("pendingOrders", pendingOrders);
			request.setAttribute("deliveryUser", user);
			request.setAttribute("viewMode", "agent");

			// Flash messages passed via redirect
			String msg = request.getParameter("msg");
			String err = request.getParameter("err");
			if (msg != null) {
				request.setAttribute("msg", msg);
			}
			if (err != null) {
				request.setAttribute("err", err);
			}

			request.getRequestDispatcher("CodDeposit.jsp").forward(request, response);

		} catch (Exception e) {
			log.log(Level.SEVERE, "CodDepositServlet GET error", e);
			throw new ServletException(e);
		}
	}

	// ─────────────────────────────────────────────────────────────────────────
	// POST — deposit actions
	// ─────────────────────────────────────────────────────────────────────────

	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		HttpSession session = request.getSession(false);
		String action = request.getParameter("action");

		try {

			// ── AGENT INITIATES DEPOSIT ───────────────────────────────────────
			// Agent physically goes to the hub and says "I'm handing over ₹X for order #N".
			// This creates a PENDING record. Staff must still confirm.
			if ("agentDeposit".equals(action)) {
				User user = (session != null) ? (User) session.getAttribute("deliveryUser") : null;
				if (user == null) {
					sendJson(response, false, "Session expired. Please log in again.");
					return;
				}

				int orderId = parseIntParam(request, "orderId");
				BigDecimal amount = parseDecimalParam(request, "amount");
				String notes = request.getParameter("notes");

				if (orderId <= 0) {
					sendJson(response, false, "Invalid order ID.");
					return;
				}
				if (amount == null || amount.compareTo(BigDecimal.ZERO) <= 0) {
					sendJson(response, false, "Please enter a valid deposit amount.");
					return;
				}

				// Validate the order belongs to this agent and is eligible
				Order order = orderDAO.getOrderById(orderId);
				if (order == null) {
					sendJson(response, false, "Order #" + orderId + " not found.");
					return;
				}
				if (order.getDeliveryUserId() != user.getUid()) {
					sendJson(response, false, "Order #" + orderId + " is not assigned to you.");
					return;
				}
				if (!"COD".equalsIgnoreCase(order.getPaymentMethod())) {
					sendJson(response, false, "Order #" + orderId + " is not a COD order.");
					return;
				}
				if (!"Delivered".equalsIgnoreCase(order.getStatus())) {
					sendJson(response, false,
							"Order #" + orderId
									+ " must be in Delivered status before depositing cash. Current status: "
									+ order.getStatus());
					return;
				}

				// Record as PENDING — no wallet/float change yet
				boolean ok = walletDAO.recordCodDeposit(user.getUid(), orderId, amount, "Pending staff confirmation",
						notes);

				if (ok) {
					log.info(
							"Agent #" + user.getUid() + " submitted COD deposit for order #" + orderId + " ₹" + amount);
					// Notify staff about the pending COD deposit
					try {
						StaffNotificationDAO snd = new StaffNotificationDAO();
						StaffNotification sn = new StaffNotification();
						sn.setOrderId(orderId);
						sn.setPaymentMethod("COD_DEPOSIT");
						sn.setPaymentStatus("PENDING_DEPOSIT");
						sn.setGrandTotal(amount.doubleValue());
						sn.setCustomerName(user.getUsername() != null ? user.getUsername() : "Agent #" + user.getUid());
						sn.setCustomerEmail("");
						sn.setCustomerPhone("");
						sn.setItemsSummary("💵 COD Deposit — Order #" + orderId + " — ₹" + amount.toPlainString());
						sn.setActionRequired(
								"Confirm cash receipt for Order #" + orderId + " in the Orders Dashboard.");
						snd.insert(sn);
					} catch (Exception notifEx) {
						log.warning("COD deposit staff notif failed: " + notifEx.getMessage());
					}
					sendJson(response, true, "₹" + amount.toPlainString() + " deposit for Order #" + orderId
							+ " recorded. Please hand the cash to the hub supervisor for confirmation.");
				} else {
					sendJson(response, false, "Could not record deposit. Please try again.");
				}
				return;
			}

			// ── STAFF CONFIRMS DEPOSIT ────────────────────────────────────────
			// Staff physically counts the cash and confirms in the system.
			// This is the final step. It creates a confirmed cod_remitted record.
			// If cod_float > 0 for this order (meaning the full pipeline was followed),
			// it will be decremented. If cod_float was already 0, it stays 0 (harmless).
			if ("staffConfirm".equals(action)) {
				User staffUser = getStaffUser(session);
				if (staffUser == null) {
					sendJson(response, false, "Staff session not found. Please log in.");
					return;
				}

				int orderId = parseIntParam(request, "orderId");
				int agentId = parseIntParam(request, "agentId");
				BigDecimal amount = parseDecimalParam(request, "amount");
				String notes = request.getParameter("notes");

				if (orderId <= 0 || agentId <= 0) {
					sendJson(response, false, "orderId and agentId are required.");
					return;
				}
				if (amount == null || amount.compareTo(BigDecimal.ZERO) <= 0) {
					sendJson(response, false, "Please enter the confirmed cash amount.");
					return;
				}

				String staffName = staffUser.getUsername();
				boolean ok = walletDAO.recordCodDeposit(agentId, orderId, amount, staffName, notes);

				if (ok) {
					log.info("Staff (" + staffName + ") confirmed COD deposit — order #" + orderId + " agent #"
							+ agentId + " ₹" + amount);
					// Notify the delivery agent that deposit was confirmed
					try (java.sql.Connection notifConn = com.util.DBConnection.getConnection()) {
						DeliveryNotificationServlet.push(notifConn, agentId, "COD_DEPOSIT_CONFIRMED",
								"✅ COD deposit confirmed!", "Staff confirmed your ₹" + amount.toPlainString()
										+ " cash deposit for Order #" + orderId + ". Your records are updated.",
								"💵", "green", orderId);
					} catch (Exception notifEx) {
						log.warning("COD confirmed agent notif failed: " + notifEx.getMessage());
					}
					sendJson(response, true,
							"Cash confirmed for Order #" + orderId + ". Payment status updated to DEPOSITED.");
				} else {
					sendJson(response, false, "Could not confirm deposit. It may have already been confirmed.");
				}
				return;
			}

			// ── STAFF REJECTS / FLAGS DEPOSIT ─────────────────────────────────
			// Cash amount doesn't match what the agent claimed, or other dispute.
			// In production: create a dispute record, notify agent, optionally freeze
			// wallet.
			if ("staffReject".equals(action)) {
				User staffUser = getStaffUser(session);
				if (staffUser == null) {
					sendJson(response, false, "Staff session not found.");
					return;
				}

				int orderId = parseIntParam(request, "orderId");
				int agentId = parseIntParam(request, "agentId");
				String reason = request.getParameter("reason");

				log.warning("COD deposit DISPUTED — order #" + orderId + " agent #" + agentId + " | staff: "
						+ staffUser.getUsername() + " | reason: " + reason);

				// Notify the delivery agent that deposit was flagged
				try (java.sql.Connection notifConn = com.util.DBConnection.getConnection()) {
					DeliveryNotificationServlet.push(notifConn, agentId, "COD_DEPOSIT_REJECTED",
							"⚠️ COD deposit flagged",
							"Your cash deposit for Order #" + orderId + " was flagged by staff."
									+ (reason != null && !reason.isBlank() ? " Reason: " + reason
											: " Please contact the hub supervisor."),
							"⚠️", "amber", orderId);
				} catch (Exception notifEx) {
					log.warning("COD deposit flagged agent notif failed: " + notifEx.getMessage());
				}
				sendJson(response, true,
						"Deposit for Order #" + orderId + " flagged for review. Agent has been notified.");
				return;
			}

			sendJson(response, false, "Unknown action: " + action);

		} catch (Exception e) {
			log.log(Level.SEVERE, "CodDepositServlet POST error | action=" + action, e);
			sendJson(response, false, "Server error: " + e.getMessage());
		}
	}

	// ─────────────────────────────────────────────────────────────────────────
	// Helpers
	// ─────────────────────────────────────────────────────────────────────────

	/**
	 * Returns the staff User from session, checking both "user" and "staffUser"
	 * attributes.
	 */
	private User getStaffUser(HttpSession session) {
		if (session == null) {
			return null;
		}
		Object u = session.getAttribute("user");
		if (u instanceof User) {
			return (User) u;
		}
		u = session.getAttribute("staffUser");
		if (u instanceof User) {
			return (User) u;
		}
		return null;
	}

	private int parseIntParam(HttpServletRequest request, String name) {
		try {
			String val = request.getParameter(name);
			return (val != null && !val.isBlank()) ? Integer.parseInt(val.trim()) : 0;
		} catch (NumberFormatException e) {
			return 0;
		}
	}

	private BigDecimal parseDecimalParam(HttpServletRequest request, String name) {
		try {
			String val = request.getParameter(name);
			return (val != null && !val.isBlank()) ? new BigDecimal(val.trim()) : null;
		} catch (NumberFormatException e) {
			return null;
		}
	}

	private void sendJson(HttpServletResponse response, boolean success, String message) throws IOException {
		response.setContentType("application/json");
		response.setCharacterEncoding("UTF-8");
		String msg = message != null ? message.replace("\"", "'") : "";
		response.getWriter().write("{\"success\":" + success + ",\"message\":\"" + msg + "\"}");
	}
}