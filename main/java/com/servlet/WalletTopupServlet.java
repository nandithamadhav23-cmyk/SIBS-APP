package com.servlet;

import java.io.IOException;
import java.util.logging.Level;
import java.util.logging.Logger;

import org.json.JSONObject;

import com.DAO.CustomerWalletDAO;
import com.razorpay.Order;
import com.razorpay.RazorpayClient;
import com.util.CustomerWallet;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

/**
 * WalletTopupServlet — creates a Razorpay order for wallet top-up, and verifies
 * payment after Razorpay callback before crediting the wallet.
 *
 * POST /WalletTopupServlet?amount=PAISE → create order, return JSON POST
 * /WalletTopupServlet action=verify → verify signature, credit wallet
 *
 * FIX: creditCustomerWallet() now called with txnType="topup" (was "credit").
 * This makes the type pill show "topup" in purple instead of "credit" in green,
 * and allows getSummaryStats() to count topups and credits separately.
 */
@WebServlet("/WalletTopupServlet")
public class WalletTopupServlet extends HttpServlet {

	private static final Logger log = Logger.getLogger(WalletTopupServlet.class.getName());
	private final CustomerWalletDAO walletDAO = new CustomerWalletDAO();

	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		response.setContentType("application/json");
		response.setCharacterEncoding("UTF-8");

		HttpSession session = request.getSession(false);
		if (session == null || session.getAttribute("customerId") == null) {
			response.getWriter().write("{\"success\":false,\"message\":\"Session expired.\"}");
			return;
		}

		int customerId = (int) session.getAttribute("customerId");
		String action = request.getParameter("action");

		try {
			if ("verify".equals(action)) {
				// ── STEP 2: Verify Razorpay signature and credit wallet ──────────
				String razorpayPaymentId = request.getParameter("razorpay_payment_id");
				String razorpayOrderId = request.getParameter("razorpay_order_id");
				String razorpaySignature = request.getParameter("razorpay_signature");
				long amountPaise = parseLong(request.getParameter("amount"), 0);

				String secret = request.getServletContext().getInitParameter("razorpay.key_secret");
				String payload = (razorpayOrderId != null ? razorpayOrderId : "") + "|"
						+ (razorpayPaymentId != null ? razorpayPaymentId : "");

				log.info("Verifying wallet topup — customer: " + customerId + ", order: " + razorpayOrderId
						+ ", payment: " + razorpayPaymentId + ", amountPaise: " + amountPaise);

				if (secret == null || secret.isBlank()) {
					log.severe("razorpay.key_secret init-param is missing — cannot verify signature");
					response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
					response.getWriter().write(
							"{\"success\":false,\"message\":\"Payment gateway not configured. Contact support.\"}");
					return;
				}

				if (razorpayPaymentId == null || razorpayPaymentId.isBlank() || razorpayOrderId == null
						|| razorpayOrderId.isBlank() || razorpaySignature == null || razorpaySignature.isBlank()) {
					log.warning("Wallet topup verify called with missing Razorpay params for customer #" + customerId);
					response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
					response.getWriter()
							.write("{\"success\":false,\"message\":\"Incomplete payment response. Please retry.\"}");
					return;
				}

				boolean isValid = false;
				try {
					isValid = verifySignature(payload, razorpaySignature, secret);
				} catch (Exception cryptoEx) {
					log.log(Level.WARNING, "Wallet top-up signature verification exception for customer #" + customerId
							+ ": " + cryptoEx.getMessage(), cryptoEx);
					response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
					response.getWriter().write("{\"success\":false,\"message\":\"Payment verification error: "
							+ cryptoEx.getMessage().replace('\"', '\'') + "\"}");
					return;
				}

				if (!isValid) {
					log.warning("Invalid Razorpay signature for wallet topup, customer #" + customerId + ", payload="
							+ payload + ", signature=" + razorpaySignature);
					response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
					response.getWriter()
							.write("{\"success\":false,\"message\":\"Invalid signature. Please retry payment.\"}");
					return;
				}

				double amountRupees = amountPaise / 100.0;
				// FIX: txnType = "topup" (was "credit"). This ensures:
				// • The type pill shows "topup" (purple) not "credit" (green).
				// • getSummaryStats() can count topups and credits separately.
				String description = "Wallet top-up via Razorpay (" + razorpayPaymentId + ")";
				walletDAO.creditCustomerWallet(customerId, amountRupees, 0, "topup", description, razorpayPaymentId);

				CustomerWallet updated = walletDAO.getWalletByCustomerId(customerId);
				double newBalance = updated != null ? updated.getBalance() : 0.0;

				log.info("Wallet top-up ₹" + amountRupees + " for customer #" + customerId + " — VERIFIED");
				response.getWriter().write(String
						.format("{\"success\":true,\"message\":\"Wallet credited.\",\"newBalance\":%.2f}", newBalance));

			} else {
				// ── STEP 1: Create Razorpay order ───────────────────────────────
				long amountPaise = parseLong(request.getParameter("amount"), 0);
				if (amountPaise < 1000) { // minimum ₹10
					response.getWriter().write("{\"success\":false,\"message\":\"Minimum top-up is ₹10.\"}");
					return;
				}
				if (amountPaise > 5000000) { // maximum ₹50,000
					response.getWriter().write("{\"success\":false,\"message\":\"Maximum top-up is ₹50,000.\"}");
					return;
				}

				String rzpKeyId = request.getServletContext().getInitParameter("razorpay.key_id");
				String rzpKeySecret = request.getServletContext().getInitParameter("razorpay.key_secret");

				if (rzpKeyId == null || rzpKeyId.isBlank() || rzpKeySecret == null || rzpKeySecret.isBlank()) {
					log.severe("Razorpay API keys not configured in web.xml");
					response.getWriter().write(
							"{\"success\":false,\"message\":\"Payment gateway not configured. Contact support.\"}");
					return;
				}

				RazorpayClient client = new RazorpayClient(rzpKeyId, rzpKeySecret);
				JSONObject orderReq = new JSONObject();
				orderReq.put("amount", amountPaise);
				orderReq.put("currency", "INR");
				orderReq.put("receipt", "wallet_topup_" + customerId + "_" + System.currentTimeMillis());

				Order rzpOrder = client.orders.create(orderReq);
				String rzpOrderId = rzpOrder.get("id");

				log.info("Razorpay wallet-topup order created: " + rzpOrderId + " for customer #" + customerId);

				response.getWriter()
						.write(String.format("{\"razorpayOrderId\":\"%s\",\"razorpayKey\":\"%s\",\"amount\":%d}",
								rzpOrderId, rzpKeyId, amountPaise));
			}

		} catch (Exception e) {
			log.log(Level.SEVERE, "WalletTopupServlet error for customer #" + customerId, e);
			response.getWriter().write(
					"{\"success\":false,\"message\":\"Server error: " + e.getMessage().replace("\"", "'") + "\"}");
		}
	}

	private static long parseLong(String s, long fallback) {
		if (s == null || s.isBlank()) {
			return fallback;
		}
		try {
			return Long.parseLong(s);
		} catch (NumberFormatException e) {
			return fallback;
		}
	}

	private static boolean verifySignature(String payload, String signature, String secret) throws Exception {
		if (payload == null) {
			payload = "";
		}
		if (signature == null || signature.isBlank()) {
			return false;
		}
		javax.crypto.Mac mac = javax.crypto.Mac.getInstance("HmacSHA256");
		javax.crypto.spec.SecretKeySpec sk = new javax.crypto.spec.SecretKeySpec(
				secret.getBytes(java.nio.charset.StandardCharsets.UTF_8), "HmacSHA256");
		mac.init(sk);
		byte[] digest = mac.doFinal(payload.getBytes(java.nio.charset.StandardCharsets.UTF_8));
		StringBuilder sb = new StringBuilder(digest.length * 2);
		for (byte b : digest) {
			sb.append(String.format("%02x", b & 0xff));
		}
		String expected = sb.toString();
		if (expected.length() != signature.length()) {
			return false;
		}
		int res = 0;
		for (int i = 0; i < expected.length(); i++) {
			res |= expected.charAt(i) ^ signature.charAt(i);
		}
		return res == 0;
	}
}
