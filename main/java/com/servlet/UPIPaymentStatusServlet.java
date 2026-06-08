package com.servlet;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.Base64;

import org.json.JSONObject;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

/**
 * UPIPaymentStatusServlet
 *
 * GET /UPIPaymentStatusServlet?paymentLinkId=xxx&orderId=yyy → polls Razorpay
 * Payment Link status, returns JSON to the JSP polling loop
 *
 * POST /UPIPaymentStatusServlet (Razorpay Webhook) → handles payment_link.paid
 * event with HMAC-SHA256 verification
 */
@WebServlet("/UPIPaymentStatusServlet")
public class UPIPaymentStatusServlet extends HttpServlet {

	private static final long serialVersionUID = 1L;

	// ── GET: AJAX polling from UPIPayment.jsp ──────────────────────────────
	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		String paymentLinkId = request.getParameter("paymentLinkId");
		String orderId = request.getParameter("orderId");

		String keyId = getServletContext().getInitParameter("razorpay.key_id");
		String keySecret = getServletContext().getInitParameter("razorpay.key_secret");

		try {
			// Fetch Payment Link details — GET /v1/payment_links/{id}
			String apiUrl = "https://api.razorpay.com/v1/payment_links/" + paymentLinkId;

			HttpURLConnection conn = (HttpURLConnection) new URL(apiUrl).openConnection();
			conn.setRequestMethod("GET");
			conn.setRequestProperty("Accept", "application/json");

			String encodedAuth = Base64.getEncoder().encodeToString((keyId + ":" + keySecret).getBytes("UTF-8"));
			conn.setRequestProperty("Authorization", "Basic " + encodedAuth);
			conn.setConnectTimeout(8000);
			conn.setReadTimeout(10000);

			int httpStatus = conn.getResponseCode();

			BufferedReader br = new BufferedReader(
					new InputStreamReader(httpStatus == 200 ? conn.getInputStream() : conn.getErrorStream(), "UTF-8"));
			StringBuilder sb = new StringBuilder();
			String line;
			try (br) {
				while ((line = br.readLine()) != null) {
					sb.append(line);
				}
			}

			if (httpStatus != 200) {
				throw new ServletException("Razorpay status API error [" + httpStatus + "]: " + sb);
			}

			JSONObject pl = new JSONObject(sb.toString());

			// Payment Link statuses: created | partially_paid | paid | cancelled | expired
			String plStatus = pl.optString("status", "created");
			String paymentId = pl.optString("payments", null); // null until paid
			boolean isPaid = "paid".equalsIgnoreCase(plStatus);
			boolean isCancelled = "cancelled".equalsIgnoreCase(plStatus) || "expired".equalsIgnoreCase(plStatus);

			// Extract payment_id from payments array if available
			if (isPaid && pl.has("payments")) {
				try {
					org.json.JSONArray payments = pl.getJSONArray("payments");
					if (payments.length() > 0) {
						paymentId = payments.getJSONObject(0).optString("payment_id", "");
					}
				} catch (Exception ignored) {
				}
			}

			// TODO: if isPaid → update your DB: OrderDAO.markAsPaid(orderId, paymentId);

			// Return JSON to the polling AJAX
			JSONObject result = new JSONObject();
			result.put("status", isPaid ? "success" : isCancelled ? "failed" : "pending");
			result.put("paymentId", paymentId != null ? paymentId : "");
			result.put("orderId", orderId);

			response.setContentType("application/json");
			response.setCharacterEncoding("UTF-8");
			response.getWriter().write(result.toString());

		} catch (ServletException se) {
			throw se;
		} catch (Exception e) {
			throw new ServletException("Failed to check payment status: " + e.getMessage(), e);
		}
	}

	// ── POST: Razorpay Webhook ─────────────────────────────────────────────
	// Configure in Dashboard → Webhooks:
	// URL: https://yourdomain.com/UPIPaymentStatusServlet
	// Events: payment_link.paid
	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		StringBuilder sb = new StringBuilder();
		String line;
		try (BufferedReader br = request.getReader()) {
			while ((line = br.readLine()) != null) {
				sb.append(line);
			}
		}
		String webhookBody = sb.toString();
		String webhookSignature = request.getHeader("X-Razorpay-Signature");
		String webhookSecret = getServletContext().getInitParameter("razorpay.webhook_secret");

		try {
			if (!verifySignature(webhookBody, webhookSignature, webhookSecret)) {
				response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
				response.getWriter().write("Invalid signature");
				return;
			}

			JSONObject payload = new JSONObject(webhookBody);
			String event = payload.optString("event");

			if ("payment_link.paid".equals(event)) {
				JSONObject plEntity = payload.optJSONObject("payload").optJSONObject("payment_link")
						.optJSONObject("entity");

				String paymentLinkId = plEntity != null ? plEntity.optString("id") : "";
				JSONObject notes = plEntity != null ? plEntity.optJSONObject("notes") : null;
				String orderId = notes != null ? notes.optString("order_id", "") : "";

				// TODO: mark your order as PAID in DB
				// OrderDAO.markAsPaid(Integer.parseInt(orderId), paymentLinkId);
				System.out.println("Payment Link paid: " + paymentLinkId + " for Order: " + orderId);
			}

			response.setStatus(HttpServletResponse.SC_OK);
			response.getWriter().write("OK");

		} catch (Exception e) {
			throw new ServletException("Webhook error: " + e.getMessage(), e);
		}
	}

	private boolean verifySignature(String body, String signature, String secret) throws Exception {
		if (signature == null || secret == null) {
			return false;
		}
		javax.crypto.Mac mac = javax.crypto.Mac.getInstance("HmacSHA256");
		mac.init(new javax.crypto.spec.SecretKeySpec(secret.getBytes("UTF-8"), "HmacSHA256"));
		byte[] hash = mac.doFinal(body.getBytes("UTF-8"));
		StringBuilder hex = new StringBuilder();
		for (byte b : hash) {
			hex.append(String.format("%02x", b));
		}
		return hex.toString().equals(signature);
	}
}
