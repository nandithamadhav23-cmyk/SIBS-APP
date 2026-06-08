package com.servlet;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

import org.json.JSONObject;

import com.DAO.AddressDAO;
import com.DAO.CartDAO;
import com.DAO.CustomerDAO;
import com.DAO.CustomerNotificationDAO;
import com.DAO.OrderDAO;
import com.DAO.ProductDAO;
import com.razorpay.RazorpayClient;
import com.util.CartItem;
import com.util.Customer;
import com.util.CustomerAddress;
import com.util.Order;
import com.util.Product;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

/**
 * PlaceOrderServlet — GST RATE FIX applied.
 *
 * WHAT WAS WRONG: The old code applied a flat 18% GST AND a separate 5% "tax"
 * on every product regardless of category: gst = subtotal * 0.18 → 18% on
 * everything (wrong slab for most groceries) tax = subtotal * 0.05 → phantom 5%
 * that has no legal basis on top of GST grandTotal = subtotal + gst + tax + ...
 * → customer overcharged by 23%
 *
 * WHAT IS CORRECT (India GST rules): - GST IS the tax. There is no separate
 * "tax" on top of GST. - The rate depends on the product category (0 / 5 / 12 /
 * 18 / 28 %). - Rate is stored per-product in the gst_rate column (set by
 * admin). - GST is calculated on finalPrice (post-discount selling price),
 * which is correct under Indian GST law (tax on transaction value).
 *
 * FIX SUMMARY: - computeGst() sums per-item GST using each item's own gstRate.
 * - The separate "tax" variable is removed entirely. - grandTotal = subtotal +
 * gst + deliveryCharge + codCharge (no phantom tax). - The tax=0 is passed to
 * OrderDAO.createOrder() to keep the DB signature unchanged; you may remove
 * that column later.
 */
@WebServlet("/PlaceOrderServlet")
public class PlaceOrderServlet extends HttpServlet {

	private static final Logger log = Logger.getLogger(PlaceOrderServlet.class.getName());

	private final OrderDAO orderDAO = new OrderDAO();
	private final ProductDAO productDAO = new ProductDAO();
	private final CustomerDAO customerDAO = new CustomerDAO();
	private final AddressDAO addressDAO = new AddressDAO();
	private final CartDAO cartDAO = new CartDAO();

	// ── SHARED HELPERS — used by CheckoutServlet too ─────────────────────────

	public static double computeDeliveryCharge(double subtotal) {
		return subtotal > 700 ? 0 : 40;
	}

	public static double computeCodCharge(String paymentMethod) {
		return "COD".equalsIgnoreCase(paymentMethod) ? 50 : 0;
	}

	/**
	 * GST FIX — replaces the old flat 0.18 calculation.
	 *
	 * Iterates every cart item and applies its own GST rate (from the gst_rate
	 * column in products). This means: - A 1 kg rice bag at ₹60 with 0% GST
	 * contributes ₹0 GST. - A 500 g snack pack at ₹40 with 18% GST contributes
	 * ₹7.20 GST. The total is the sum of all per-line GST amounts.
	 *
	 * GST is calculated on finalPrice (post-discount), which is the correct taxable
	 * value under Section 15 of the CGST Act.
	 */
	public static double computeGst(List<CartItem> items) {
		return items.stream().mapToDouble(CartItem::getLineGst).sum();
	}

	// ── POST handler ─────────────────────────────────────────────────────────

	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		HttpSession session = request.getSession(false);

		// ── 1. Session guard ──────────────────────────────────────────────────
		if (session == null || session.getAttribute("customerId") == null) {
			response.sendRedirect("CustomerLogin.jsp");
			return;
		}
		int customerId = (int) session.getAttribute("customerId");

		// ── 2. Duplicate-submission guard ─────────────────────────────────────
		String submittedToken = request.getParameter("formToken");
		String sessionToken = (String) session.getAttribute("checkoutToken");
		if (submittedToken == null || !submittedToken.equals(sessionToken)) {
			response.sendRedirect("CartServlet?action=view&error=duplicate");
			return;
		}
		session.removeAttribute("checkoutToken");

		String paymentMethod = request.getParameter("paymentMethod");
		String buyNowFlag = request.getParameter("buyNow");

		// ── 3. Validate payment method ────────────────────────────────────────
		if (paymentMethod == null || (!paymentMethod.equalsIgnoreCase("COD") && !paymentMethod.equalsIgnoreCase("Card")
				&& !paymentMethod.equalsIgnoreCase("UPI"))) {
			response.sendRedirect("Checkout.jsp?error=invalidPayment");
			return;
		}

		List<CartItem> cartItems;
		Product product = null;
		try {
			// ── 4. Build cart items ───────────────────────────────────────────
			if ("true".equalsIgnoreCase(buyNowFlag)) {
				String pidParam = request.getParameter("productId");
				String qtyParam = request.getParameter("quantity");
				if (pidParam == null || qtyParam == null) {
					response.sendRedirect("customerDashboard.jsp?error=missingParams");
					return;
				}
				int productId = Integer.parseInt(pidParam);
				int quantity = Integer.parseInt(qtyParam);
				if (quantity <= 0) {
					response.sendRedirect("customerDashboard.jsp?error=invalidQty");
					return;
				}
				product = productDAO.getProductById(productId);
				if (product == null) {
					response.sendRedirect("customerDashboard.jsp?error=productNotFound");
					return;
				}
				if (product.getStock() < quantity) {
					response.sendRedirect("customerDashboard.jsp?error=outOfStock");
					return;
				}

				CartItem item = new CartItem();
				item.setProductId(productId);
				item.setName(product.getName());
				item.setDescription(product.getDescription());
				item.setImageUrl(product.getImageUrl());
				item.setQuantity(quantity);
				item.setFinalPrice(product.getFinalPrice());
				item.setDiscount(product.getDiscount());
				item.setProductQuantity(product.getQuantity());
				item.setUnit(product.getUnit());
				item.setStock(product.getStock());
				item.setGstRate(product.getGstRate()); // GST FIX: carry gstRate into CartItem
				cartItems = new ArrayList<>();
				cartItems.add(item);

			} else {
				@SuppressWarnings("unchecked")
				List<CartItem> sessionCart = (List<CartItem>) session.getAttribute("cartItems");
				if (sessionCart == null || sessionCart.isEmpty()) {
					response.sendRedirect("CartServlet?action=view");
					return;
				}
				for (CartItem ci : sessionCart) {
					Product p = productDAO.getProductById(ci.getProductId());
					if (p == null || p.getStock() < ci.getQuantity()) {
						session.setAttribute("stockError",
								"'" + ci.getName() + "' is out of stock. Please update your cart.");
						response.sendRedirect("CartServlet?action=view");
						return;
					}
				}
				cartItems = sessionCart;
			}

			// ── 5. Compute totals ─────────────────────────────────────────────
			//
			// GST FIX: the old code did:
			// gst = subtotal * 0.18 ← wrong flat rate
			// tax = subtotal * 0.05 ← invented charge, not real
			//
			// Correct approach:
			// gst = sum of (item.finalPrice × qty × item.gstRate%) for all items
			// tax = 0 (GST IS the indirect tax in India; there is no extra "tax")
			//
			double subtotal = cartItems.stream().mapToDouble(CartItem::getLineTotal).sum();
			double gst = computeGst(cartItems); // GST FIX: per-item rates
			double tax = 0.0; // GST FIX: removed phantom tax
			double deliveryCharge = computeDeliveryCharge(subtotal);
			double codCharge = computeCodCharge(paymentMethod);
			double grandTotal = subtotal + gst + deliveryCharge + codCharge;
			// ↑ tax intentionally excluded

			// ── 6. Capture address snapshot BEFORE createOrder ────────────────
			CustomerAddress defaultAddress = addressDAO.getDefaultAddressByCustomer(customerId);
			if (defaultAddress == null) {
				response.sendRedirect("Checkout.jsp?error=noAddress");
				return;
			}

			// ── 7. Persist order with snapshot ────────────────────────────────
			int orderId = orderDAO.createOrder(customerId, subtotal, gst, tax, deliveryCharge, codCharge, grandTotal,
					cartItems, paymentMethod, defaultAddress.getAddressId(), defaultAddress.getLandmarkStreet(),
					defaultAddress.getCity(), defaultAddress.getDistrict(), defaultAddress.getState(),
					defaultAddress.getCountry(), defaultAddress.getPincode());

			CustomerNotificationDAO nd = new CustomerNotificationDAO();
			// product may be null for cart orders; guard with a safe name
			String productName = (product != null) ? product.getName()
					: (cartItems.isEmpty() ? "Order" : cartItems.get(0).getName());
			nd.notifyOrderPlaced(customerId, orderId, productName, grandTotal, paymentMethod);

			Order order = orderDAO.getOrderById(orderId);
			Customer customer = customerDAO.getProfile(customerId);

			// ── 8. Estimated delivery date ────────────────────────────────────
			java.time.LocalDate deliveryDate = java.time.LocalDate.now()
					.plusDays("COD".equalsIgnoreCase(paymentMethod) ? 5 : 3);
			String formattedDeliveryDate = deliveryDate
					.format(java.time.format.DateTimeFormatter.ofPattern("dd MMM yyyy"));

			// ── 9. Common request attributes ──────────────────────────────────
			request.setAttribute("order", order);
			request.setAttribute("orderId", orderId);
			request.setAttribute("customer", customer);
			request.setAttribute("address", defaultAddress);
			request.setAttribute("cartItems", cartItems);
			request.setAttribute("subtotal", String.format("%.2f", subtotal));
			request.setAttribute("gst", String.format("%.2f", gst));
			request.setAttribute("grandTotal", String.format("%.2f", grandTotal));
			request.setAttribute("paymentMethod", paymentMethod);
			request.setAttribute("delivery_date", formattedDeliveryDate);

			// ── COD PATH ──────────────────────────────────────────────────────
			if ("COD".equalsIgnoreCase(paymentMethod)) {
				orderDAO.updatePaymentStatus(orderId, "PENDING_COD", null);
				for (CartItem item : cartItems) {
					productDAO.updateStock(item.getProductId(), item.getQuantity());
				}
				if (!"true".equalsIgnoreCase(buyNowFlag)) {
					session.removeAttribute("cartItems");
					cartDAO.clearCartByCustomer(customerId);
				}
				log.info("COD order #" + orderId + " placed by customer #" + customerId);
				request.getRequestDispatcher("OrderConfirmation.jsp").forward(request, response);

				// ── ONLINE PAYMENT PATH ───────────────────────────────────────────
			} else {
				String keyId = getServletContext().getInitParameter("razorpay.key_id");
				String keySecret = getServletContext().getInitParameter("razorpay.key_secret");
				if (keyId == null || keySecret == null) {
					throw new ServletException("Payment gateway not configured.");
				}

				RazorpayClient razorpay = new RazorpayClient(keyId, keySecret);
				JSONObject options = new JSONObject();
				options.put("amount", (int) (grandTotal * 100));
				options.put("currency", "INR");
				options.put("receipt", "rcpt_" + orderId);
				com.razorpay.Order razorpayOrder = razorpay.orders.create(options);

				request.setAttribute("razorpayOrderId", razorpayOrder.get("id"));
				request.setAttribute("razorpayKey", keyId);
				request.setAttribute("buyNowFlag", buyNowFlag);
				session.setAttribute("pendingOrderId", orderId);
				session.setAttribute("pendingBuyNow", buyNowFlag);
				session.setAttribute("pendingCartItems", cartItems);
				request.setAttribute("customerName", customer.getName());
				request.setAttribute("customerEmail", customer.getEmail());
				request.setAttribute("customerPhone", customer.getPhone());
				log.info("Razorpay order created for DB order #" + orderId);
				request.getRequestDispatcher("payment.jsp").forward(request, response);
			}

		} catch (NumberFormatException e) {
			log.log(Level.WARNING, "Invalid param", e);
			response.sendRedirect("Checkout.jsp?error=invalidInput");
		} catch (Exception e) {
			log.log(Level.SEVERE, "Order placement failed for customer #" + customerId, e);
			throw new ServletException("Order placement failed. Please try again.", e);
		}
	}
}
