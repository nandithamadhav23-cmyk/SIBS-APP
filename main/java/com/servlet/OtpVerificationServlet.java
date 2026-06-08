package com.servlet;

import java.io.IOException;
import java.math.BigDecimal;
import java.sql.SQLException;
import java.util.logging.Level;
import java.util.logging.Logger;

import com.DAO.AgentWalletDAO;
import com.DAO.CustomerNotificationDAO;
import com.DAO.OrderDAO;
import com.util.Order;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

/**
 * OtpVerificationServlet — handles OTP submission from the delivery agent.
 *
 * ══════════════════════════════════════════════════════════════════════════
 * WALLET LIFECYCLE on OTP success
 * ══════════════════════════════════════════════════════════════════════════
 *
 * When the OTP matches:
 *
 * For ALL orders: 1. updateOrderStatus(orderId, "Delivered") 2.
 * creditDeliveryFee() → balance += fee, total_earned += fee Fee: ₹60 COD, ₹40
 * Prepaid
 *
 * For COD orders only: 3. releaseCodHold() → cod_float -= orderAmount (The
 * agent collected cash from the customer; the hold is no longer needed) NOTE:
 * balance is NOT changed here — balance was already updated in step 2.
 * cod_float dropping to 0 does NOT affect the agent's earnings.
 *
 * For PREPAID orders: 4. updatePaymentStatus(orderId, "PAID", transactionId)
 * (COD orders stay PENDING_COD until the agent physically deposits cash at hub)
 *
 * ══════════════════════════════════════════════════════════════════════════
 * WHY cod_float stays > 0 after this servlet
 * ══════════════════════════════════════════════════════════════════════════
 *
 * After OTP: cod_float goes DOWN (hold released — agent collected cash). The
 * cash is still in the agent's pocket. cod_float tracks "how much cash is the
 * agent carrying that belongs to the company."
 *
 * After releaseCodHold, cod_float = 0 for that order. BUT the agent still has
 * the physical cash. They must deposit it at the hub. That is handled by
 * CodDepositServlet (agent submits) + staff confirms.
 *
 * ══════════════════════════════════════════════════════════════════════════
 * IDEMPOTENCY
 * ══════════════════════════════════════════════════════════════════════════
 * AgentWalletDAO.creditDeliveryFee() and releaseCodHold() both check for
 * existing transaction records before inserting. Double-tapping the OTP button
 * will not double-credit or double-release.
 */
@WebServlet("/OtpVerificationServlet")
public class OtpVerificationServlet extends HttpServlet {

	private static final long serialVersionUID = 1L;
	private static final Logger log = Logger.getLogger(OtpVerificationServlet.class.getName());

	private final OrderDAO orderDAO = new OrderDAO();
	private final AgentWalletDAO walletDAO = new AgentWalletDAO();

	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		String orderIdParam = request.getParameter("orderId");
		String otpParam = request.getParameter("otp");

		if (orderIdParam == null || otpParam == null) {
			response.sendRedirect(request.getContextPath() + "/DeliveryPortalServlet?otpFailed=true");
			return;
		}

		int orderId;
		int enteredOtp;
		try {
			orderId = Integer.parseInt(orderIdParam.trim());
			enteredOtp = Integer.parseInt(otpParam.trim());
		} catch (NumberFormatException e) {
			response.sendRedirect(request.getContextPath() + "/DeliveryPortalServlet?otpFailed=true");
			return;
		}

		try {
			int storedOtp = orderDAO.getOrderOtp(orderId);

			if (storedOtp == enteredOtp) {
				// ── OTP MATCHED ────────────────────────────────────────────────

				// Step 1: Mark order as delivered
				orderDAO.updateOrderStatus(orderId, "Delivered");
				log.info("OTP verified → order #" + orderId + " marked Delivered");

				// Step 2: Load order to get agent, payment method, amount
				Order order = orderDAO.getOrderById(orderId);

				if (order != null && order.getDeliveryUserId() > 0) {
					int agentId = order.getDeliveryUserId();
					boolean isCod = "COD".equalsIgnoreCase(order.getPaymentMethod());
					double fee = isCod ? 60.0 : 40.0;

					// Step 3: Credit delivery fee → this increases agent's balance
					boolean feeOk = walletDAO.creditDeliveryFee(agentId, orderId, fee, isCod);
					if (feeOk) {
						log.info("Delivery fee ₹" + fee + " credited to agent #" + agentId + " for order #" + orderId);
					} else {
						log.warning("creditDeliveryFee returned false — agent #" + agentId + " order #" + orderId);
					}

					// Step 4 (COD only): Release the COD hold → cod_float decreases
					// This does NOT affect balance. The agent still has the cash in hand.
					// They must deposit it separately via CodDepositServlet.
					if (isCod) {
						BigDecimal orderAmount = new BigDecimal(String.valueOf(order.getTotalAmount()));
						boolean holdOk = walletDAO.releaseCodHold(agentId, orderId, orderAmount);
						if (holdOk) {
							log.info("COD hold released for agent #" + agentId + " order #" + orderId + " ₹"
									+ order.getTotalAmount());
						} else {
							// Non-fatal — cod_float may already be 0 if hold was never placed
							log.warning("releaseCodHold returned false — agent #" + agentId + " order #" + orderId
									+ " (hold may not have been placed if agent skipped 'Picked Up' step)");
						}
					}

					// Step 5: Mark payment PAID for prepaid orders.
					// COD orders stay PENDING_COD until cash is physically deposited at hub.
					if (!isCod) {
						String transactionId = order.getTransactionId();
						orderDAO.updatePaymentStatus(orderId, "PAID", transactionId);
						log.info("Prepaid order #" + orderId + " payment_status → PAID");
					}

				} else {
					log.warning("OTP verified but order #" + orderId + " has no delivery agent — wallet not updated");
				}

				// BUG FIX: Customer was never notified of delivery on the OTP path.
				// This is the PRIMARY delivery confirmation path — every delivered order
				// goes through here, yet nd.notifyOrderDelivered() was never called.
				try {
					Order deliveredOrder = orderDAO.getOrderById(orderId);
					if (deliveredOrder != null && deliveredOrder.getCustomerId() > 0) {
						new CustomerNotificationDAO().notifyOrderDelivered(deliveredOrder.getCustomerId(), orderId);
					}
				} catch (Exception notifEx) {
					log.warning("Customer delivered notification failed for OTP order #" + orderId + ": "
							+ notifEx.getMessage());
				}

				// Redirect to portal with success flag
				response.sendRedirect(
						request.getContextPath() + "/DeliveryPortalServlet?otpSuccess=true&orderId=" + orderId);

			} else {
				// ── OTP MISMATCH ───────────────────────────────────────────────
				log.warning("OTP mismatch for order #" + orderId + " — entered: " + enteredOtp);
				response.sendRedirect(
						request.getContextPath() + "/DeliveryPortalServlet?otpFailed=true&orderId=" + orderId);
			}

		} catch (SQLException e) {
			log.log(Level.SEVERE, "OTP verification DB error for order #" + orderId, e);
			throw new ServletException("Error verifying OTP for order #" + orderId, e);
		} catch (Exception e) {
			log.log(Level.SEVERE, "OTP verification unexpected error for order #" + orderId, e);
			throw new ServletException("Unexpected error during OTP verification", e);
		}
	}
}