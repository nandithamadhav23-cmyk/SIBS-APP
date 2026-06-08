package com.servlet;

import java.io.IOException;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.logging.Level;
import java.util.logging.Logger;

import org.json.JSONObject;

import com.DAO.CustomerWalletDAO;
import com.razorpay.FundAccount;
import com.razorpay.RazorpayClient;
import com.util.CustomerWallet;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

/**
 * WalletWithdrawServlet — handles customer-initiated wallet withdrawals.
 *
 * Razorpay Payouts (RazorpayX) use a SEPARATE REST API endpoint
 * (https://api.razorpay.com/v1/payouts) that is NOT part of the standard
 * razorpay-java SDK's RazorpayClient. The SDK only exposes client.fundAccount
 * (FundAccountClient) — there is no client.payout field.
 *
 * This servlet therefore: 1. Uses the SDK's FundAccountClient to create / reuse
 * a fund account. FundAccountClient.create() returns FundAccount (an Entity
 * subclass), NOT a JSONObject — getId() / get("id") must be used, not
 * getString("id"). 2. Calls the RazorpayX Payouts REST endpoint directly via
 * HttpURLConnection with Basic Auth (keyId:keySecret), because no SDK wrapper
 * exists for it.
 *
 * Two modes: MODE A — Razorpay Payout (production): enabled when
 * razorpay.payout_key_id, razorpay.payout_key_secret, and
 * razorpay.payout_account_number are set in web.xml. MODE B — Manual / pending:
 * fallback when Razorpay is not configured or payout fails. Wallet is still
 * debited immediately (funds reserved) and an admin processes the transfer
 * manually.
 *
 * POST /WalletWithdrawServlet Params: amount (rupees), upiId OR (accountNo +
 * ifsc + accountName), note Response: JSON { success, message, newBalance? }
 */
@WebServlet("/WalletWithdrawServlet")
public class WalletWithdrawServlet extends HttpServlet {

	private static final Logger log = Logger.getLogger(WalletWithdrawServlet.class.getName());
	private final CustomerWalletDAO walletDAO = new CustomerWalletDAO();

	private static final double MIN_WITHDRAW = 10.0;
	private static final double MAX_WITHDRAW = 200_000.0;

	// RazorpayX Payouts REST endpoint (separate from standard Razorpay API)
	private static final String RAZORPAYX_PAYOUTS_URL = "https://api.razorpay.com/v1/payouts";
	private static final String RAZORPAYX_CONTACTS_URL = "https://api.razorpay.com/v1/contacts";

	// ─────────────────────────────────────────────────────────────────
	// POST handler
	// ─────────────────────────────────────────────────────────────────

	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		response.setContentType("application/json");
		response.setCharacterEncoding("UTF-8");

		HttpSession session = request.getSession(false);
		if (session == null || session.getAttribute("customerId") == null) {
			response.getWriter().write("{\"success\":false,\"message\":\"Session expired. Please log in.\"}");
			return;
		}

		int customerId = (int) session.getAttribute("customerId");

		try {
			// ── Validate amount ───────────────────────────────────────
			double amount = parseDouble(request.getParameter("amount"), -1);
			if (amount < MIN_WITHDRAW) {
				write(response, false, "Minimum withdrawal is \u20b9" + (int) MIN_WITHDRAW + ".", -1);
				return;
			}
			if (amount > MAX_WITHDRAW) {
				write(response, false,
						"Maximum withdrawal per transaction is \u20b9" + String.format("%.0f", MAX_WITHDRAW) + ".", -1);
				return;
			}

			// ── Parse destination ─────────────────────────────────────
			String upiId = trim(request.getParameter("upiId"));
			String accountNo = trim(request.getParameter("accountNo"));
			String ifsc = trim(request.getParameter("ifsc"));
			String accountName = trim(request.getParameter("accountName"));
			String note = trim(request.getParameter("note"));

			boolean isUpi = upiId != null && !upiId.isEmpty();
			boolean isBank = accountNo != null && !accountNo.isEmpty() && ifsc != null && !ifsc.isEmpty();

			if (!isUpi && !isBank) {
				write(response, false, "Please provide a UPI ID or bank account details.", -1);
				return;
			}

			// ── Build description ─────────────────────────────────────
			String destination = isUpi ? "UPI: " + upiId
					: "Bank: " + accountNo + " / IFSC: " + ifsc
							+ (accountName != null && !accountName.isEmpty() ? " (" + accountName + ")" : "");
			String description = "Withdrawal to " + destination;
			if (note != null && !note.isEmpty()) {
				description += " \u2014 " + note;
			}

			log.info("Withdrawal request: customer #" + customerId + ", amount=\u20b9" + amount + ", dest="
					+ destination);

			// ── Razorpay Payout (Mode A) ──────────────────────────────
			String payoutKeyId = getParam("razorpay.payout_key_id");
			String payoutKeySecret = getParam("razorpay.payout_key_secret");
			String payoutAccountNo = getParam("razorpay.payout_account_number");

			boolean razorpayConfigured = !isBlank(payoutKeyId) && !isBlank(payoutKeySecret)
					&& !isBlank(payoutAccountNo);

			String referenceId = null;
			boolean payoutSuccess = false;

			if (razorpayConfigured) {
				try {
					referenceId = initiateRazorpayPayout(payoutKeyId, payoutKeySecret, payoutAccountNo, amount,
							isUpi ? "UPI" : "NEFT", isUpi ? upiId : null, isBank ? accountNo : null,
							isBank ? ifsc : null, isBank ? accountName : null, customerId);
					payoutSuccess = true;
					log.info("Razorpay payout created: " + referenceId + " for customer #" + customerId);
				} catch (Exception payoutEx) {
					log.log(Level.WARNING,
							"Razorpay payout failed for customer #" + customerId + ": " + payoutEx.getMessage(),
							payoutEx);
					description += " [Razorpay payout error \u2014 manual review required]";
				}
			}

			// ── Debit wallet (funds reserved regardless of payout mode) ─
			walletDAO.withdrawFromWallet(customerId, amount, referenceId, description);

			// Refresh session balance
			CustomerWallet updated = walletDAO.getWalletByCustomerId(customerId);
			double newBalance = updated != null ? updated.getBalance() : 0.0;
			session.setAttribute("walletBalance", newBalance);

			String msg = (razorpayConfigured && payoutSuccess)
					? "Withdrawal of \u20b9" + String.format("%.2f", amount) + " initiated successfully."
					: "Withdrawal of \u20b9" + String.format("%.2f", amount)
							+ " requested. It will be processed within 1\u20133 business days.";

			log.info("Wallet withdrawal \u20b9" + amount + " \u2014 customer #" + customerId + " \u2014 payoutRef="
					+ referenceId + " \u2014 newBal=" + newBalance);

			write(response, true, msg, newBalance);

		} catch (IllegalStateException ise) {
			// Insufficient balance thrown by withdrawFromWallet
			log.warning("Withdrawal rejected for customer #" + customerId + ": " + ise.getMessage());
			write(response, false, ise.getMessage(), -1);
		} catch (Exception e) {
			log.log(Level.SEVERE, "WalletWithdrawServlet error for customer #" + customerId, e);
			write(response, false, "Server error: " + e.getMessage(), -1);
		}
	}

	// ─────────────────────────────────────────────────────────────────
	// Razorpay Payout — two-step: create contact → create fund account
	// → POST payout via raw HTTP
	//
	// FIX 1: client.fundAccount.create() returns FundAccount (Entity),
	// NOT JSONObject. Use fundAccount.get("id"), not getString("id").
	//
	// FIX 2: client.payout does NOT exist in the razorpay-java SDK.
	// RazorpayX Payouts must be called via raw HttpURLConnection
	// with Basic Auth (keyId:keySecret Base64-encoded).
	// ─────────────────────────────────────────────────────────────────

	private String initiateRazorpayPayout(String keyId, String keySecret, String accountNumber, double amountRupees,
			String mode, String upiId, String bankAccountNo, String ifsc, String accountName, int customerId)
			throws Exception {

		// ── STEP 1: Create RazorpayX Contact via raw HTTP ─────────────
		// The SDK's CustomerClient is for payment-gateway customers, NOT
		// RazorpayX contacts. Use the REST API directly.
		JSONObject contactReq = new JSONObject();
		contactReq.put("name", accountName != null && !accountName.isEmpty() ? accountName : "Customer " + customerId);
		contactReq.put("type", "customer");
		contactReq.put("email", "customer" + customerId + "@sibsstore.com");
		contactReq.put("contact", "9999999999"); // placeholder
		contactReq.put("reference_id", "cust_" + customerId);

		JSONObject contactResp = razorpayxPost(RAZORPAYX_CONTACTS_URL, keyId, keySecret, contactReq);
		String contactId = contactResp.getString("id"); // "cont_XXXXXXXX"

		// ── STEP 2: Create Fund Account via SDK (FundAccountClient) ───
		// FIX 1: create() returns FundAccount (Entity), NOT JSONObject.
		// Use fundAccount.get("id") to extract the string ID.
		JSONObject faReq = new JSONObject();
		faReq.put("contact_id", contactId);

		if ("UPI".equals(mode)) {
			JSONObject vpa = new JSONObject();
			vpa.put("address", upiId);
			faReq.put("account_type", "vpa");
			faReq.put("vpa", vpa);
		} else {
			JSONObject bank = new JSONObject();
			bank.put("name", accountName != null ? accountName : "Customer");
			bank.put("ifsc", ifsc);
			bank.put("account_number", bankAccountNo);
			faReq.put("account_type", "bank_account");
			faReq.put("bank_account", bank);
		}

		RazorpayClient client = new RazorpayClient(keyId, keySecret);

		// Returns FundAccount (Entity subclass) — NOT JSONObject
		FundAccount fundAccountEntity = client.fundAccount.create(faReq);

		// FIX 1: Entity.get("id") returns the value, NOT
		// fundAccountEntity.getString("id")
		String fundAccountId = fundAccountEntity.get("id"); // "fa_XXXXXXXX"

		// ── STEP 3: Create Payout via raw HTTP (no SDK wrapper exists) ─
		// FIX 2: client.payout does NOT exist. Call the REST API directly.
		JSONObject payoutReq = new JSONObject();
		payoutReq.put("account_number", accountNumber); // RazorpayX business account
		payoutReq.put("fund_account_id", fundAccountId);
		payoutReq.put("amount", (long) (amountRupees * 100)); // paise
		payoutReq.put("currency", "INR");
		payoutReq.put("mode", mode); // UPI | NEFT | IMPS | RTGS
		payoutReq.put("purpose", "payout");
		payoutReq.put("queue_if_low_balance", false);
		payoutReq.put("reference_id", "sibs_wd_" + customerId + "_" + System.currentTimeMillis());
		payoutReq.put("narration", "SIBS Wallet Withdrawal");

		JSONObject payoutResp = razorpayxPost(RAZORPAYX_PAYOUTS_URL, keyId, keySecret, payoutReq);
		return payoutResp.getString("id"); // "pout_XXXXXXXX"
	}

	// ─────────────────────────────────────────────────────────────────
	// razorpayxPost — raw HTTPS POST to RazorpayX REST API
	//
	// The razorpay-java SDK does NOT wrap the RazorpayX Payouts or
	// Contacts endpoints, so we call them directly via HttpURLConnection
	// with HTTP Basic Auth (Base64(keyId + ":" + keySecret)).
	// ─────────────────────────────────────────────────────────────────

	private JSONObject razorpayxPost(String urlStr, String keyId, String keySecret, JSONObject body) throws Exception {

		URL url = new URL(urlStr);
		HttpURLConnection conn = (HttpURLConnection) url.openConnection();
		conn.setRequestMethod("POST");
		conn.setConnectTimeout(15_000);
		conn.setReadTimeout(20_000);
		conn.setDoOutput(true);

		// Basic Auth
		String credentials = keyId + ":" + keySecret;
		String encoded = Base64.getEncoder().encodeToString(credentials.getBytes(StandardCharsets.UTF_8));
		conn.setRequestProperty("Authorization", "Basic " + encoded);
		conn.setRequestProperty("Content-Type", "application/json");
		conn.setRequestProperty("Accept", "application/json");

		// Write body
		byte[] bodyBytes = body.toString().getBytes(StandardCharsets.UTF_8);
		conn.setRequestProperty("Content-Length", String.valueOf(bodyBytes.length));
		try (OutputStream os = conn.getOutputStream()) {
			os.write(bodyBytes);
		}

		// Read response
		int status = conn.getResponseCode();
		java.io.InputStream is = status >= 400 ? conn.getErrorStream() : conn.getInputStream();
		String responseBody;
		try (java.util.Scanner sc = new java.util.Scanner(is, StandardCharsets.UTF_8)) {
			responseBody = sc.useDelimiter("\\A").hasNext() ? sc.next() : "";
		}

		if (status >= 400) {
			throw new Exception("RazorpayX API error [HTTP " + status + "]: " + responseBody);
		}

		return new JSONObject(responseBody);
	}

	// ─────────────────────────────────────────────────────────────────
	// Helpers
	// ─────────────────────────────────────────────────────────────────

	private void write(HttpServletResponse response, boolean success, String message, double newBalance)
			throws IOException {
		String safe = message != null ? message.replace("\"", "'") : "";
		if (success && newBalance >= 0) {
			response.getWriter().write(
					String.format("{\"success\":true,\"message\":\"%s\",\"newBalance\":%.2f}", safe, newBalance));
		} else {
			response.getWriter().write("{\"success\":" + success + ",\"message\":\"" + safe + "\"}");
		}
	}

	private String getParam(String name) {
		try {
			return getServletContext().getInitParameter(name);
		} catch (Exception e) {
			return null;
		}
	}

	private static boolean isBlank(String s) {
		return s == null || s.trim().isEmpty();
	}

	private static double parseDouble(String s, double fallback) {
		if (s == null || s.trim().isEmpty()) {
			return fallback;
		}
		try {
			return Double.parseDouble(s.trim());
		} catch (NumberFormatException e) {
			return fallback;
		}
	}

	private static String trim(String s) {
		return s != null ? s.trim() : null;
	}
}
