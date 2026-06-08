package com.servlet;

import java.io.IOException;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

import com.DAO.AddressDAO;
import com.DAO.CartDAO;
import com.DAO.CustomerDAO;
import com.DAO.OrderDAO;
import com.DAO.ProductDAO;
// Use local HMAC verifier instead of com.razorpay.Utils to avoid dependency issues
import com.util.CartItem;
import com.util.Customer;
import com.util.CustomerAddress;
import com.util.Order;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/PaymentServlet")
public class PaymentServlet extends HttpServlet {

	private static final Logger log = Logger.getLogger(PaymentServlet.class.getName());
	private final AddressDAO addressDAO = new AddressDAO();

	private final OrderDAO orderDAO = new OrderDAO();
	private final ProductDAO productDAO = new ProductDAO();
	private final CartDAO cartDAO = new CartDAO();
	private final CustomerDAO customerDAO = new CustomerDAO();

	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		HttpSession session = request.getSession(false);

		if (session == null || session.getAttribute("customerId") == null) {
			response.sendRedirect("CustomerLogin.jsp");
			return;
		}

		int customerId = (int) session.getAttribute("customerId");

		// ── SECURITY FIX: orderId from SESSION, never from form params ──────────────
		Integer orderId = (Integer) session.getAttribute("pendingOrderId");
		if (orderId == null) {
			log.warning("No pendingOrderId in session for customer #" + customerId);
			response.sendRedirect("CartServlet?action=view&error=sessionExpired");
			return;
		}

		String razorpayPaymentId = request.getParameter("razorpay_payment_id");
		String razorpayOrderId = request.getParameter("razorpay_order_id");
		String razorpaySignature = request.getParameter("razorpay_signature");

		try {
			// ── 1. Verify Razorpay signature ─────────────────────────────────────────
			String secret = getServletContext().getInitParameter("razorpay.key_secret");
			String payload = razorpayOrderId + "|" + razorpayPaymentId;
			boolean isValid = false;
			try {
				isValid = verifySignature(payload, razorpaySignature, secret);
			} catch (Exception cryptoEx) {
				log.log(Level.SEVERE, "Signature verification threw exception", cryptoEx);
				isValid = false;
			}

			if (!isValid) {
				log.warning("Invalid Razorpay signature for order #" + orderId);
				orderDAO.updatePaymentStatus(orderId, "PAYMENT_FAILED", razorpayPaymentId);
				cleanupSession(session);
				response.sendRedirect("PaymentFailed.jsp?orderId=" + orderId);
				return;
			}

			// ── 2. Idempotency check ─────────────────────────────────────────────────
			Order existingOrder = orderDAO.getOrderById(orderId);
			if ("PAID".equalsIgnoreCase(existingOrder.getPaymentStatus())) {
				log.info("Duplicate callback for already-PAID order #" + orderId + " — ignoring.");
				cleanupSession(session);
				request.setAttribute("order", existingOrder);
				request.setAttribute("paymentMethod", existingOrder.getPaymentMethod());
				request.getRequestDispatcher("OrderConfirmation.jsp").forward(request, response);
				return;
			}

			// ── 3. Mark PAID ─────────────────────────────────────────────────────────
			orderDAO.updatePaymentStatus(orderId, "PAID", razorpayPaymentId);

			// ── 4. Reduce stock ONLY after confirmed payment ─────────────────────────
			@SuppressWarnings("unchecked")
			List<CartItem> cartItems = (List<CartItem>) session.getAttribute("pendingCartItems");
			if (cartItems != null) {
				for (CartItem item : cartItems) {
					productDAO.updateStock(item.getProductId(), item.getQuantity());
				}
			}

			// ── 5. Clear cart ─────────────────────────────────────────────────────────
			String buyNowFlag = (String) session.getAttribute("pendingBuyNow");
			if (!"true".equalsIgnoreCase(buyNowFlag)) {
				session.removeAttribute("cartItems");
				cartDAO.clearCartByCustomer(customerId);
			}

			// ── 6. Notify staff ───────────────────────────────────────────────────────
			Order order = orderDAO.getOrderById(orderId);
			Customer customer = customerDAO.getProfile(customerId);
			new OrderServlet().notifyNewOrder(order, customer, cartItems, order.getPaymentMethod(),
					order.getTotalAmount());
			CustomerAddress defaultAddress = addressDAO.getDefaultAddressByCustomer(customerId);

			log.info("Online payment verified. Order #" + orderId + " marked PAID.");

			cleanupSession(session);

			request.setAttribute("order", order);
			request.setAttribute("paymentMethod", order.getPaymentMethod());
			request.setAttribute("customer", customer);
			request.setAttribute("address", defaultAddress);
			request.setAttribute("cartItems", cartItems);

			request.getRequestDispatcher("OrderConfirmation.jsp").forward(request, response);

		} catch (Exception e) {
			log.log(Level.SEVERE, "Payment processing failed for order #" + orderId, e);
			cleanupSession(session);
			throw new ServletException("Payment processing failed. Please contact support.", e);
		}
	}

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		HttpSession session = request.getSession(false);
		Integer orderId = (session != null) ? (Integer) session.getAttribute("pendingOrderId") : null;
		if (orderId != null) {
			try {
				orderDAO.updatePaymentStatus(orderId, "PAYMENT_FAILED", null);
			} catch (Exception ignored) {
			}
		}
		if (session != null) {
			cleanupSession(session);
		}
		response.sendRedirect("PaymentFailed.jsp?orderId=" + orderId);
	}

	private void cleanupSession(HttpSession session) {
		session.removeAttribute("pendingOrderId");
		session.removeAttribute("pendingBuyNow");
		session.removeAttribute("pendingCartItems");
	}

	// Local HMAC-SHA256 verifier for Razorpay signatures (payload = orderId|paymentId)
	private static boolean verifySignature(String payload, String signature, String secret) throws Exception {
		if (payload == null) payload = "";
		if (signature == null || signature.isBlank()) return false;
		javax.crypto.Mac mac = javax.crypto.Mac.getInstance("HmacSHA256");
		javax.crypto.spec.SecretKeySpec sk = new javax.crypto.spec.SecretKeySpec(secret.getBytes(java.nio.charset.StandardCharsets.UTF_8), "HmacSHA256");
		mac.init(sk);
		byte[] digest = mac.doFinal(payload.getBytes(java.nio.charset.StandardCharsets.UTF_8));
		StringBuilder sb = new StringBuilder(digest.length * 2);
		for (byte b : digest) {
			sb.append(String.format("%02x", b & 0xff));
		}
		String expected = sb.toString();
		if (expected.length() != signature.length()) return false;
		int res = 0;
		for (int i = 0; i < expected.length(); i++) res |= expected.charAt(i) ^ signature.charAt(i);
		return res == 0;
	}
}