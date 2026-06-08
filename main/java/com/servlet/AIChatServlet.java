package com.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.SQLException;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

import com.DAO.AddressDAO;
import com.DAO.CartDAO;
import com.DAO.ChatDAO;
import com.DAO.CustomerDAO;
import com.DAO.CustomerWalletDAO;
import com.DAO.OrderDAO;
import com.DAO.OrderReturnDAO;
import com.DAO.ProductDAO;
import com.DAO.StaffNotificationDAO;
import com.DAO.TicketDAO;
import com.util.CartItem;
import com.util.ChatMessage;
import com.util.ChatSession;
import com.util.Customer;
import com.util.Order;
import com.util.OrderReturn;
import com.util.StaffNotification;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

/**
 * AIChatServlet — GreenCart Kira AI Support Chat Backend.
 *
 * ── WHAT CHANGED IN THIS VERSION (address-snapshot integration) ──────────────
 *
 * 1. Added AddressDAO import + field — used by handleUpdateAddress to call
 * orderDAO.updateOrderAddress() (the new snapshot-based per-order update).
 *
 * 2. handleUpdateAddress — REPLACED the old "log only" behaviour: • Pre-ship
 * stages → calls orderDAO.updateOrderAddress() which writes to snap_* columns
 * (NOT customer_address.is_default). On success updates the chat and returns {
 * success:true, urgent:false }. • Shipped/Assigned/OFD → still raises urgent
 * staff ticket (unchanged), now also calls orderDAO.updateOrderAddress() for
 * the record. Returns { success:true, urgent:true, ticketId:N }. • Stage-gate
 * enforced in OrderDAO — if order is already past Confirmed the update is
 * silently declined and we fall through to the ticket path.
 *
 * 3. orderToJson() — added snap_* address fields so the widget can display the
 * frozen delivery address from the order row, not the live default.
 * "snapStreet","snapCity","snapState","snapPincode" added to JSON.
 *
 * 4. handleLookupOrder — now reads order.getAddress() which is the CONCAT_WS of
 * snap_* columns (set by OrderDAO.mapFullRow). Previously could show wrong
 * address after customer changed their default.
 *
 * 5. All other logic (cancel tiers, return, intercept, ticket, payment verify,
 * frustration escalation) is UNCHANGED from the current file.
 *
 * ── ENDPOINT MAP ─────────────────────────────────────────────────────────────
 * GET /AIChatServlet → history (or lookupOrder if action=) POST /AIChatServlet
 * action=message → rule-based NLP reply POST /AIChatServlet action=lookupOrder
 * → full Order JSON (snapshot address) POST /AIChatServlet action=cancelOrder →
 * tiered cancel + refund + restock POST /AIChatServlet action=interceptRequest
 * → courier intercept ticket POST /AIChatServlet action=submitReturn →
 * OrderReturn record + staff notif POST /AIChatServlet action=updateAddress →
 * snapshot update via OrderDAO (or urgent ticket if shipped) POST
 * /AIChatServlet action=verifyPayment → txn_id + method check POST
 * /AIChatServlet action=raiseTicket → StaffNotification + chat record POST
 * /AIChatServlet action=action → card-action audit log
 *
 * ── CANCELLATION POLICY ──────────────────────────────────────────────────────
 * Stage | Cancellable | Refund | Notes Ordered/Pending | YES | 100% | Nothing
 * picked yet Confirmed | YES | 100% | Warehouse notified to skip Assigned |
 * WARN | 90% | Intercept attempted (10% fee) Picked Up | YES | 95% | 5%
 * handling fee Packed | YES | 95% | 5% packing charge Shipped | WARN | 90% |
 * Courier intercept; 10% if ok Out for Delivery | WARN | 90% | Last-mile; 10%
 * deducted Delivered | NO | — | Return/Replace only (10-day) Cancelled/etc. |
 * NO | — | Terminal
 */
@WebServlet("/AIChatServlet")
public class AIChatServlet extends HttpServlet {

	private static final Logger log = Logger.getLogger(AIChatServlet.class.getName());

	private ChatDAO chatDAO;
	private CustomerDAO customerDAO;
	private OrderDAO orderDAO;
	private OrderReturnDAO returnDAO;
	private ProductDAO productDAO;
	private StaffNotificationDAO notifDAO;
	private CustomerWalletDAO walletDAO;
	private CartDAO cartDAO;
	private AddressDAO addressDAO; // ← for snapshot update
	private TicketDAO ticketDAO; // ← for support_tickets integration

	@Override
	public void init() throws ServletException {
		chatDAO = new ChatDAO();
		customerDAO = new CustomerDAO();
		orderDAO = new OrderDAO();
		returnDAO = new OrderReturnDAO();
		productDAO = new ProductDAO();
		notifDAO = new StaffNotificationDAO();
		walletDAO = new CustomerWalletDAO();
		cartDAO = new CartDAO();
		addressDAO = new AddressDAO();
		ticketDAO = new TicketDAO();
	}

	// ══════════════════════════════════════════════════════════════════════
	// GET — history (default) or lookupOrder
	// ══════════════════════════════════════════════════════════════════════
	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
		res.setContentType("application/json;charset=UTF-8");
		PrintWriter out = res.getWriter();
		try {
			int customerId = requireCustomerId(req, res);
			if (customerId < 0) {
				return;
			}
			String action = req.getParameter("action");
			if ("lookupOrder".equals(action)) {
				handleLookupOrder(req, res, out, customerId);
			} else {
				handleHistory(req, res, out, customerId);
			}
		} catch (Exception e) {
			log.log(Level.SEVERE, "GET error", e);
			res.setStatus(500);
			out.write("{\"error\":\"Server error\"}");
		}
	}

	// ══════════════════════════════════════════════════════════════════════
	// POST — all mutating actions
	// ══════════════════════════════════════════════════════════════════════
	@Override
	protected void doPost(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
		res.setContentType("application/json;charset=UTF-8");
		PrintWriter out = res.getWriter();
		try {
			int customerId = requireCustomerId(req, res);
			if (customerId < 0) {
				return;
			}
			String action = req.getParameter("action");
			if (action == null) {
				action = "message";
			}
			switch (action) {
			case "message" -> handleMessage(req, res, out, customerId);
			case "lookupOrder" -> handleLookupOrder(req, res, out, customerId);
			case "cancelOrder" -> handleCancelOrder(req, res, out, customerId);
			case "interceptRequest" -> handleInterceptRequest(req, res, out, customerId);
			case "submitReturn" -> handleSubmitReturn(req, res, out, customerId);
			case "updateAddress" -> handleUpdateAddress(req, res, out, customerId);
			case "verifyPayment" -> handleVerifyPayment(req, res, out, customerId);
			case "raiseTicket" -> handleRaiseTicket(req, res, out, customerId);
			case "action" -> handleCardAction(req, res, out, customerId);
			case "newSession" -> handleNewSession(req, res, out, customerId);
			default -> {
				res.setStatus(400);
				out.write("{\"error\":\"Unknown action\"}");
			}
			}
		} catch (Exception e) {
			log.log(Level.SEVERE, "POST error", e);
			res.setStatus(500);
			out.write("{\"error\":\"Internal server error\"}");
		}
	}

	// ══════════════════════════════════════════════════════════════════════
	// handleHistory
	// ══════════════════════════════════════════════════════════════════════
	private void handleHistory(HttpServletRequest req, HttpServletResponse res, PrintWriter out, int customerId)
			throws Exception {
		ChatSession session = getOrCreateSession(customerId);
		List<ChatMessage> msgs = chatDAO.getMessagesBySession(session.getSessionId());
		StringBuilder sb = new StringBuilder();
		sb.append("{\"sessionToken\":\"").append(esc(session.getSessionToken())).append("\",\"messages\":[");
		for (int i = 0; i < msgs.size(); i++) {
			if (i > 0) {
				sb.append(",");
			}
			sb.append(messageToJson(msgs.get(i)));
		}
		sb.append("]}");
		out.write(sb.toString());
	}

	// ══════════════════════════════════════════════════════════════════════
	// handleLookupOrder — returns full Order JSON.
	// CHANGE: order.getAddress() now reads from snap_* columns (OrderDAO fix).
	// Added snap fields to JSON so widget shows frozen delivery address.
	// ══════════════════════════════════════════════════════════════════════
	private void handleLookupOrder(HttpServletRequest req, HttpServletResponse res, PrintWriter out, int customerId)
			throws Exception {
		String rawId = req.getParameter("orderId");
		if (rawId == null || rawId.isBlank()) {
			res.setStatus(400);
			out.write("{\"found\":false,\"error\":\"Missing orderId\"}");
			return;
		}
		int orderId;
		try {
			orderId = Integer.parseInt(rawId.replaceAll("[^0-9]", "").trim());
		} catch (NumberFormatException e) {
			res.setStatus(400);
			out.write("{\"found\":false,\"error\":\"Invalid orderId\"}");
			return;
		}

		Order order = orderDAO.getOrderById(orderId);
		if (order == null || order.getCustomerId() != customerId) {
			out.write("{\"found\":false,\"error\":\"Order not found\"}");
			return;
		}

		boolean isPaid = "PAID".equalsIgnoreCase(order.getPaymentStatus());
		boolean isCod = "PENDING_COD".equalsIgnoreCase(order.getPaymentStatus())
				|| "COD".equalsIgnoreCase(order.getPaymentMethod());
		double refund = computeRefund(order.getStatus(), order.getTotalAmount(), isPaid);
		double deduction = isPaid ? order.getTotalAmount() - refund : 0;

		out.write("{\"found\":true,\"order\":" + orderToJson(order) + ",\"refundPreview\":"
				+ String.format("%.2f", refund) + ",\"deductPct\":" + deductPct(order.getStatus()) + ",\"isCOD\":"
				+ isCod + ",\"isPaid\":" + isPaid + "}");
	}

	// ══════════════════════════════════════════════════════════════════════
	// handleMessage — NLP reply (UNCHANGED)
	// ══════════════════════════════════════════════════════════════════════
	private void handleMessage(HttpServletRequest req, HttpServletResponse res, PrintWriter out, int customerId)
			throws Exception {
		String text = req.getParameter("message");
		if (text == null || text.isBlank()) {
			res.setStatus(400);
			out.write("{\"error\":\"Empty message\"}");
			return;
		}
		text = text.trim();
		ChatSession session = getOrCreateSession(customerId);
		chatDAO.saveMessage(session.getSessionId(), "user", text);

		Customer customer = customerDAO.getProfile(customerId);
		List<Order> orders = orderDAO.getOrdersByCustomer(customerId);

		LocalAIEngine.AiReply reply = LocalAIEngine.respond(text, customer, orders);
		int aiId = chatDAO.saveMessage(session.getSessionId(), "assistant", reply.text, reply.cardType,
				reply.cardOrderId);

		out.write("{\"messageId\":" + aiId + ",\"text\":" + js(reply.text) + ",\"cardType\":"
				+ (reply.cardType != null ? "\"" + esc(reply.cardType) + "\"" : "null") + ",\"cardOrderId\":"
				+ (reply.cardOrderId != null ? "\"" + esc(reply.cardOrderId) + "\"" : "null") + "}");
	}

	// ══════════════════════════════════════════════════════════════════════
	// handleCancelOrder — tiered cancel + refund + restock (UNCHANGED)
	// ══════════════════════════════════════════════════════════════════════
	private void handleCancelOrder(HttpServletRequest req, HttpServletResponse res, PrintWriter out, int customerId)
			throws Exception {
		int orderId = parseOrderId(req.getParameter("orderId"));
		if (orderId < 0) {
			res.setStatus(400);
			out.write("{\"success\":false,\"error\":\"Invalid orderId\"}");
			return;
		}

		Order order = orderDAO.getOrderById(orderId);
		if (order == null || order.getCustomerId() != customerId) {
			res.setStatus(403);
			out.write("{\"success\":false,\"error\":\"Order not found\"}");
			return;
		}

		String status = order.getStatus();
		boolean isPaid = "PAID".equalsIgnoreCase(order.getPaymentStatus());
		boolean isCod = "PENDING_COD".equalsIgnoreCase(order.getPaymentStatus())
				|| "COD".equalsIgnoreCase(order.getPaymentMethod());
		double total = order.getTotalAmount();

		// Terminal gates
		if (status != null) {
			switch (status) {
			case "Delivered" -> {
				out.write("{\"success\":false,\"error\":\"delivered\","
						+ "\"message\":\"Order already delivered. Use Return/Replace instead.\","
						+ "\"suggestReturn\":true}");
				return;
			}
			case "Cancelled", "Refunded", "Replaced" -> {
				out.write("{\"success\":false,\"error\":\"Order is already in terminal status: " + esc(status) + "\"}");
				return;
			}
			}
		}
		if (status != null && status.startsWith("Return")) {
			out.write("{\"success\":false,\"error\":\"Order is in return pipeline — cannot cancel.\"}");
			return;
		}
		// Shipped/Assigned/OFD → defer to intercept flow
		if ("Shipped".equals(status) || "Out for Delivery".equals(status) || "Assigned".equals(status)) {
			out.write("{\"success\":false,\"canIntercept\":true,\"status\":\"" + esc(status) + "\","
					+ "\"error\":\"Order is already shipped. Use interceptRequest to attempt cancellation.\"}");
			return;
		}
		if ("Cancelled".equalsIgnoreCase(status)) {
			out.write("{\"success\":false,\"error\":\"Order is already cancelled.\"}");
			return;
		}

		// Tiered refund
		double refund = 0, deduction = 0, deductPct = 0;
		String deductReason = "No refund applicable";
		if (isPaid) {
			switch (status != null ? status : "") {
			case "Ordered", "Pending", "Confirmed" -> {
				refund = total;
				deductPct = 0;
				deductReason = "Full refund — order not yet processed";
			}
			case "Picked Up" -> {
				deductPct = 5;
				deduction = total * 0.05;
				refund = total - deduction;
				deductReason = "5% handling fee (agent collected from warehouse)";
			}
			case "Packed" -> {
				deductPct = 5;
				deduction = total * 0.05;
				refund = total - deduction;
				deductReason = "5% packing charge (order already packed)";
			}
			default -> deductReason = "No refund applicable at this stage";
			}
		}

		// Build order_returns record
		OrderReturn rr = returnDAO.getReturnByOrderId(orderId);
		if (rr == null) {
			rr = new OrderReturn();
			rr.setOrderId(orderId);
			rr.setCustomerId(customerId);
			rr.setType("Cancellation");
		}
		rr.setReason("CANCELLED by customer via Kira chat | Stage: " + status + " | " + deductReason);
		rr.setRefundAmount(refund);
		if (isPaid && refund > 0) {
			rr.setStatus("Pending Refund");
			rr.setRefundMethod("wallet");
			rr.setRefundTransactionId(null);
		} else if (isCod) {
			rr.setStatus("No Refund - COD");
			rr.setRefundMethod(null);
		} else {
			rr.setStatus("No Refund Applicable");
		}

		returnDAO.upsertReturnRecord(rr);
		orderDAO.updateOrderStatus(orderId, "Cancelled");
		if (isCod) {
			orderDAO.updatePaymentStatus(orderId, "COD_CANCELLED", null);
		} else if (isPaid) {
			orderDAO.updatePaymentStatus(orderId, "REFUND_PENDING", null);
		}

		// Restock
		boolean inMotion = status != null && (status.equals("Picked Up") || status.equals("Packed"));
		if (inMotion) {
			List<CartItem> items = orderDAO.getOrderItems(orderId);
			for (CartItem item : items) {
				productDAO.incrementStock(item.getProductId(), item.getQuantity());
			}
			log.info("Restocked items for customer-cancelled order #" + orderId);
		}

		// Notify staff
		Customer cust = customerDAO.getProfile(customerId);
		staffNotif(order, cust,
				String.format("🚫 Order #%d CANCELLED by customer (Kira chat). Stage: %s. %s", orderId, status,
						(isPaid && refund > 0) ? String.format("Refund ₹%.2f pending approval.", refund)
								: (isCod ? "COD — no refund." : "No refund applicable.")),
				"Process cancellation and refund for order #" + orderId);

		// Chat confirmation
		chatDAO.saveMessage(getOrCreateSession(customerId).getSessionId(), "assistant",
				buildCancelMsg(orderId, status, isPaid, isCod, total, refund, deduction, deductPct, deductReason));

		log.info("Order #" + orderId + " cancelled by customer #" + customerId + " | stage=" + status + " | refund=₹"
				+ refund + " | deduction=₹" + deduction);

		out.write("{\"success\":true" + ",\"refundAmount\":" + String.format("%.2f", refund) + ",\"deductionPct\":"
				+ deductPct + ",\"paymentMethod\":" + js(order.getPaymentMethod()) + ",\"isCOD\":" + isCod
				+ ",\"stage\":" + js(status) + ",\"message\":\"Order #" + orderId + " cancelled.\"}");
	}

	// ══════════════════════════════════════════════════════════════════════
	// handleInterceptRequest — UNCHANGED
	// ══════════════════════════════════════════════════════════════════════
	private void handleInterceptRequest(HttpServletRequest req, HttpServletResponse res, PrintWriter out,
			int customerId) throws Exception {
		int orderId = parseOrderId(req.getParameter("orderId"));
		if (orderId < 0) {
			res.setStatus(400);
			out.write("{\"success\":false,\"error\":\"Invalid orderId\"}");
			return;
		}
		Order order = orderDAO.getOrderById(orderId);
		if (order == null || order.getCustomerId() != customerId) {
			res.setStatus(403);
			out.write("{\"success\":false,\"error\":\"Order not found\"}");
			return;
		}
		Customer customer = customerDAO.getProfile(customerId);
		StaffNotification notif = new StaffNotification();
		notif.setOrderId(orderId);
		notif.setPaymentMethod(order.getPaymentMethod() != null ? order.getPaymentMethod() : "N/A");
		notif.setPaymentStatus("INTERCEPT_REQUESTED");
		notif.setGrandTotal(order.getTotalAmount());
		notif.setCustomerName(customer != null ? customer.getName() : "Customer #" + customerId);
		notif.setCustomerEmail(customer != null ? customer.getEmail() : "");
		notif.setCustomerPhone(customer != null ? customer.getPhone() : "");
		notif.setItemsSummary("URGENT: Customer requested shipment interception for order #" + orderId + " (Status: "
				+ order.getStatus() + ")");
		notif.setActionRequired("Contact courier immediately to intercept order #" + orderId + ". Customer: "
				+ (customer != null ? customer.getPhone() : "see email") + ". Refund (90%) pending intercept outcome.");
		int ticketId = notifDAO.insert(notif);
		chatDAO.saveMessage(getOrCreateSession(customerId).getSessionId(), "assistant",
				"I've raised an urgent **Courier Intercept Ticket #T" + ticketId + "** for Order #" + orderId + ".\n\n"
						+ "Our team will contact the courier immediately. You'll receive an update within **2 hours**.\n\n"
						+ "If the intercept is unsuccessful, you can **Return** the order after it's delivered "
						+ "within the 10-day return window. A **10% shipping charge** will apply if cancelled.");
		out.write("{\"success\":true,\"ticketId\":" + ticketId + "}");
	}

	// ══════════════════════════════════════════════════════════════════════
	// handleSubmitReturn — UNCHANGED
	// ══════════════════════════════════════════════════════════════════════
	private void handleSubmitReturn(HttpServletRequest req, HttpServletResponse res, PrintWriter out, int customerId)
			throws Exception {
		int orderId = parseOrderId(req.getParameter("orderId"));
		if (orderId < 0) {
			res.setStatus(400);
			out.write("{\"success\":false,\"error\":\"Invalid orderId\"}");
			return;
		}
		Order order = orderDAO.getOrderById(orderId);
		if (order == null || order.getCustomerId() != customerId) {
			res.setStatus(403);
			out.write("{\"success\":false,\"error\":\"Order not found\"}");
			return;
		}
		if (!order.getStatus().equalsIgnoreCase("Delivered")) {
			out.write("{\"success\":false,\"error\":\"Only delivered orders can be returned.\"}");
			return;
		}
		if (order.getDeliveryDate() != null) {
			long diff = (System.currentTimeMillis() - order.getDeliveryDate().getTime()) / 86400000L;
			if (diff > 10) {
				out.write("{\"success\":false,\"error\":\"10-day return window has expired.\"}");
				return;
			}
		}
		String type = req.getParameter("type");
		String reason = req.getParameter("reason");
		String bankName = req.getParameter("bankName");
		String bankAcct = req.getParameter("bankAccount");
		String bankIfsc = req.getParameter("bankIfsc");

		OrderReturn rr = new OrderReturn();
		rr.setOrderId(orderId);
		rr.setCustomerId(customerId);
		rr.setType(type != null && !type.isEmpty() ? type : "Return");
		rr.setReason(reason != null ? reason : "Requested via Kira chat");
		rr.setStatus("Requested");
		rr.setRefundAmount(order.getTotalAmount());
		boolean isCOD = "COD".equalsIgnoreCase(order.getPaymentMethod())
				|| "PENDING_COD".equalsIgnoreCase(order.getPaymentStatus());
		if (isCOD && bankAcct != null && !bankAcct.isBlank()) {
			rr.setBankName(bankName);
			rr.setBankAccount(bankAcct);
			rr.setBankIfsc(bankIfsc);
			rr.setRefundMethod("bank");
		} else if (!isCOD) {
			rr.setRefundMethod("original");
		}

		returnDAO.upsertReturnRecord(rr);
		orderDAO.updateOrderStatus(orderId, "Return Requested");

		Customer cust = customerDAO.getProfile(customerId);
		boolean isReplace = "Replace".equalsIgnoreCase(type);
		staffNotif(order, cust, (isReplace ? "REPLACEMENT" : "RETURN") + " requested via chat for order #" + orderId
				+ ". Reason: " + reason, "Approve and schedule pickup for order #" + orderId);

		chatDAO.saveMessage(getOrCreateSession(customerId).getSessionId(), "assistant",
				"Your **" + (isReplace ? "replacement" : "return") + " request** for Order **#" + orderId
						+ "** is submitted! ✅\n\n" + "**Next steps:**\n• Staff review within **24 hours**\n"
						+ "• Pickup scheduled within **48 hours** of approval\n"
						+ (isReplace ? "• Replacement dispatched after original is collected\n"
								: "• Refund of **₹" + String.format("%.2f", order.getTotalAmount())
										+ "** within **5–7 business days** after pickup\n")
						+ "\nTrack your request status in **My Orders**. 🙏");

		out.write("{\"success\":true,\"message\":\"Return submitted for order #" + orderId + ".\"}");
	}

	// ══════════════════════════════════════════════════════════════════════
	// handleUpdateAddress — REWRITTEN to use snapshot-based OrderDAO method.
	//
	// Flow:
	// 1. Parse orderId + address fields from request.
	// 2. Try orderDAO.updateOrderAddress() — writes to snap_* columns,
	// enforces ownership + stage gate internally.
	// 3. Pre-ship (update succeeded):
	// → save success chat message, return { success:true, urgent:false }
	// 4. Pre-ship (update failed — stage already past Confirmed):
	// → fall through to urgent ticket (shouldn't normally happen because
	// the widget only shows the edit form for pre-ship orders, but
	// kept as a safety net).
	// 5. Shipped/Assigned/OFD:
	// → also attempt snapshot update so the DB record is correct,
	// then raise urgent staff ticket, return { success:true, urgent:true,
	// ticketId:N }
	//
	// The address is stored ONLY on the order row (snap_* columns).
	// customer_address.is_default is NEVER touched here.
	// ══════════════════════════════════════════════════════════════════════
	private void handleUpdateAddress(HttpServletRequest req, HttpServletResponse res, PrintWriter out, int customerId)
			throws Exception {
		int orderId = parseOrderId(req.getParameter("orderId"));
		String street = req.getParameter("street");
		String city = req.getParameter("city");
		String state = req.getParameter("state");
		String pin = req.getParameter("pincode");
		String district = nvl(req.getParameter("district"), "");
		String country = nvl(req.getParameter("country"), "");

		if (orderId < 0 || isBlank(street) || isBlank(city)) {
			res.setStatus(400);
			out.write("{\"success\":false,\"error\":\"Missing address fields\"}");
			return;
		}

		Order order = orderDAO.getOrderById(orderId);
		if (order == null || order.getCustomerId() != customerId) {
			res.setStatus(403);
			out.write("{\"success\":false,\"error\":\"Order not found\"}");
			return;
		}

		String statusLower = order.getStatus() == null ? "" : order.getStatus().toLowerCase();
		String newAddr = street + ", " + city + (!isBlank(state) ? ", " + state : "")
				+ (!isBlank(pin) ? " — " + pin : "");

		Customer customer = customerDAO.getProfile(customerId);
		ChatSession csess = getOrCreateSession(customerId);
		boolean isShipped = statusLower.equals("shipped") || statusLower.equals("assigned")
				|| statusLower.equals("out for delivery");

		// ── Attempt snapshot update in both cases ────────────────────────
		// addressId=0 → no specific saved address, raw text fields only
		// OrderDAO.updateOrderAddress() handles ownership + stage gate
		boolean snapshotUpdated = false;
		try {
			snapshotUpdated = orderDAO.updateOrderAddress(orderId, customerId, 0, // addressId: 0 = no saved address
																					// mapping
					street, city, district, state, country, nvl(pin, ""));
		} catch (Exception ignored) {
			// updateOrderAddress may throw if connection fails; ticket path still runs
		}

		if (isShipped) {
			// ── SHIPPED: raise urgent staff ticket ───────────────────────
			StaffNotification notif = new StaffNotification();
			notif.setOrderId(orderId);
			notif.setPaymentMethod(order.getPaymentMethod() != null ? order.getPaymentMethod() : "N/A");
			notif.setPaymentStatus("ADDRESS_CORRECTION");
			notif.setGrandTotal(order.getTotalAmount());
			notif.setCustomerName(customer != null ? customer.getName() : "Customer #" + customerId);
			notif.setCustomerEmail(customer != null ? customer.getEmail() : "");
			notif.setCustomerPhone(customer != null ? customer.getPhone() : "");
			notif.setItemsSummary("URGENT: Address correction needed for order #" + orderId
					+ (snapshotUpdated ? " (DB updated)" : " (manual update needed)"));
			notif.setActionRequired("Update delivery agent with new address: " + newAddr + ". Call: "
					+ (customer != null ? customer.getPhone() : "see email"));
			int ticketId = notifDAO.insert(notif);

			chatDAO.saveMessage(csess.getSessionId(), "assistant",
					"I've raised an urgent address-correction ticket (**#T" + ticketId + "**) for Order #" + orderId
							+ ".\n\n" + "Our team is contacting the delivery agent immediately with the new address: **"
							+ newAddr + "**.");

			out.write("{\"success\":true,\"urgent\":true,\"ticketId\":" + ticketId
					+ ",\"message\":\"Urgent address-correction ticket raised.\"}");

		} else if (snapshotUpdated) {
			// ── PRE-SHIP: snapshot saved ──────────────────────────────────
			chatDAO.saveMessage(csess.getSessionId(), "assistant",
					"Your delivery address for Order #" + orderId + " has been updated to: **" + newAddr
							+ "**.\n\nThis change applies only to this order and will be "
							+ "reflected before dispatch. ✅");
			out.write("{\"success\":true,\"urgent\":false" + ",\"message\":\"Address updated successfully.\"}");

		} else {
			// ── Snapshot update failed (order already shipped/past stage) ─
			// Raise a ticket as fallback
			StaffNotification notif2 = new StaffNotification();
			notif2.setOrderId(orderId);
			notif2.setPaymentMethod(order.getPaymentMethod() != null ? order.getPaymentMethod() : "N/A");
			notif2.setPaymentStatus("ADDRESS_CORRECTION");
			notif2.setGrandTotal(order.getTotalAmount());
			notif2.setCustomerName(customer != null ? customer.getName() : "Customer #" + customerId);
			notif2.setCustomerEmail(customer != null ? customer.getEmail() : "");
			notif2.setCustomerPhone(customer != null ? customer.getPhone() : "");
			notif2.setItemsSummary("Address update attempted but stage-gated for order #" + orderId);
			notif2.setActionRequired("Customer wants address: " + newAddr + ". Manual update needed.");
			int tid2 = notifDAO.insert(notif2);
			chatDAO.saveMessage(csess.getSessionId(), "assistant",
					"I couldn't update the address automatically (order is at stage: **" + order.getStatus()
							+ "**). I've raised a support ticket **#T" + tid2
							+ "** — our team will contact you to resolve this.");
			out.write("{\"success\":true,\"urgent\":true,\"ticketId\":" + tid2
					+ ",\"message\":\"Support ticket raised for address update.\"}");
		}
	}

	// ══════════════════════════════════════════════════════════════════════
	// handleVerifyPayment — UNCHANGED
	// ══════════════════════════════════════════════════════════════════════
	private void handleVerifyPayment(HttpServletRequest req, HttpServletResponse res, PrintWriter out, int customerId)
			throws Exception {
		int orderId = parseOrderId(req.getParameter("orderId"));
		if (orderId < 0) {
			res.setStatus(400);
			out.write("{\"success\":false,\"error\":\"Invalid orderId\"}");
			return;
		}
		Order order = orderDAO.getOrderById(orderId);
		if (order == null || order.getCustomerId() != customerId) {
			res.setStatus(403);
			out.write("{\"success\":false,\"error\":\"Order not found\"}");
			return;
		}
		String payStatus = nvl(order.getPaymentStatus(), "UNKNOWN");
		String payMethod = nvl(order.getPaymentMethod(), "N/A");
		String txnId = nvl(order.getTransactionId(), "");
		boolean isPaid = payStatus.equalsIgnoreCase("PAID") || payStatus.equalsIgnoreCase("SUCCESS")
				|| payStatus.equalsIgnoreCase("COMPLETED") || payStatus.equalsIgnoreCase("PENDING_COD");
		out.write("{\"success\":true" + ",\"orderId\":" + orderId + ",\"paymentStatus\":\"" + esc(payStatus) + "\""
				+ ",\"paymentMethod\":\"" + esc(payMethod) + "\"" + ",\"transactionId\":\"" + esc(txnId) + "\""
				+ ",\"isPaid\":" + isPaid + ",\"isCOD\":" + payMethod.equalsIgnoreCase("COD") + "}");
	}

	// ══════════════════════════════════════════════════════════════════════
	// handleRaiseTicket
	// BUG FIX: was only writing to staff_notifications (old system).
	// Now also writes to support_tickets (new system) via TicketDAO so:
	// a) TicketQueueServlet shows it in the staff queue
	// b) chatSessionId is linked → staff reply arrives in customer's chat
	// ══════════════════════════════════════════════════════════════════════
	private void handleRaiseTicket(HttpServletRequest req, HttpServletResponse res, PrintWriter out, int customerId)
			throws Exception {
		String issue = req.getParameter("issue");
		String category = req.getParameter("category");
		int orderId = parseOrderId(req.getParameter("orderId"));
		Customer customer = customerDAO.getProfile(customerId);
		Order order = null;
		if (orderId > 0) {
			order = orderDAO.getOrderById(orderId);
			if (order != null && order.getCustomerId() != customerId) {
				order = null;
			}
		}

		// ── Resolve the active chat session (FEEDBACK LOOP key) ──────────
		ChatSession chatSession = getOrCreateSession(customerId);
		int chatSessionId = chatSession.getSessionId();

		// ── 1. Write to support_tickets (new system) ─────────────────────
		String ticketCategory = category != null ? category.toLowerCase() : "other";
		String subject = issue != null && issue.length() > 100 ? issue.substring(0, 97) + "…"
				: (issue != null ? issue : "Support request via Kira");
		int supportTicketId = -1;
		try {
			supportTicketId = ticketDAO.createFromChat(customerId, chatSessionId, ticketCategory, subject,
					issue != null ? issue : "Customer raised support ticket via Kira chat",
					orderId > 0 ? orderId : null);
		} catch (Exception ex) {
			log.log(Level.WARNING, "TicketDAO.createFromChat failed", ex);
		}

		// ── 2. Also write to staff_notifications (old system, preserved) ──
		StaffNotification n = new StaffNotification();
		n.setOrderId(orderId > 0 ? orderId : 0);
		n.setPaymentMethod(order != null ? order.getPaymentMethod() : "N/A");
		n.setPaymentStatus(category != null ? category.toUpperCase() : "TICKET");
		n.setGrandTotal(order != null ? order.getTotalAmount() : 0);
		n.setCustomerName(customer != null ? customer.getName() : "Customer #" + customerId);
		n.setCustomerEmail(customer != null ? customer.getEmail() : "");
		n.setCustomerPhone(customer != null ? customer.getPhone() : "");
		n.setItemsSummary(issue != null ? issue : "Customer raised support ticket via AI chat");
		n.setActionRequired("Call customer at "
				+ (customer != null && customer.getPhone() != null ? customer.getPhone() : "registered number")
				+ " to resolve: " + (issue != null ? issue : "Support ticket")
				+ (supportTicketId > 0 ? " | Support Ticket #TKT-" + supportTicketId : ""));
		int notifId = notifDAO.insert(n);

		// ── 3. Confirm in chat ────────────────────────────────────────────
		String phone = (customer != null && customer.getPhone() != null) ? customer.getPhone()
				: "your registered number";
		String ticketRef = supportTicketId > 0 ? "**#TKT-" + supportTicketId + "**" : "**#T" + notifId + "**";
		chatDAO.saveMessage(chatSessionId, "assistant",
				"I've raised **Support Ticket " + ticketRef + "** for your issue. ✅\n\n"
						+ "Our team will call you at **" + phone + "** within **2–4 business hours**.\n\n"
						+ "Reference: " + ticketRef + " — keep this handy. "
						+ "You can also track and reply to this ticket from **Help & Support** in your dashboard. 🙏");

		// ── 4. Customer notification: confirms receipt in notification bell ──
		// Without this, the customer's notification centre shows nothing after
		// raising a ticket via chat. They only see the chat message.
		if (supportTicketId > 0) {
			try {
				new com.DAO.CustomerNotificationDAO().notifyTicketRaised(customerId, supportTicketId, subject,
						ticketCategory);
			} catch (Exception notifEx) {
				log.warning("Customer ticket-raised notification failed (AIChatServlet) ticket #" + supportTicketId
						+ ": " + notifEx.getMessage());
			}
		}

		out.write("{\"success\":true,\"ticketId\":" + (supportTicketId > 0 ? supportTicketId : notifId)
				+ ",\"notifId\":" + notifId + "}");
	}

	// ══════════════════════════════════════════════════════════════════════
	// handleCardAction — UNCHANGED
	// ══════════════════════════════════════════════════════════════════════
	private void handleCardAction(HttpServletRequest req, HttpServletResponse res, PrintWriter out, int customerId)
			throws Exception {
		String token = req.getParameter("sessionToken");
		String actionType = req.getParameter("actionType");
		String refId = req.getParameter("orderId");
		String payload = req.getParameter("payload");
		if (isBlank(token) || isBlank(actionType)) {
			res.setStatus(400);
			out.write("{\"error\":\"Missing params\"}");
			return;
		}
		if (!chatDAO.validateCustomerSession(token, customerId)) {
			res.setStatus(403);
			out.write("{\"error\":\"Session mismatch\"}");
			return;
		}
		ChatSession s = chatDAO.getSessionByToken(token);
		if (s == null) {
			res.setStatus(404);
			out.write("{\"error\":\"Session not found\"}");
			return;
		}
		chatDAO.logAction(s.getSessionId(), 0, actionType, refId, payload);
		out.write("{\"success\":true}");
	}

	// ══════════════════════════════════════════════════════════════════════
	// buildCancelMsg — UNCHANGED
	// ══════════════════════════════════════════════════════════════════════
	private String buildCancelMsg(int orderId, String stage, boolean isPaid, boolean isCod, double total, double refund,
			double deduction, double deductPct, String deductReason) {
		StringBuilder m = new StringBuilder();
		m.append("Your order **#").append(orderId).append("** has been **cancelled**. ✅\n\n");
		if (isCod) {
			m.append("This was a **Cash on Delivery** order — no payment was collected from you, ")
					.append("so there is nothing to refund. Your order has been voided.\n\n");
			if (isInMotion(stage)) {
				m.append("Our delivery team will be notified to return the items to the warehouse.");
			}
		} else if (isPaid && refund > 0) {
			m.append("**Refund Summary:**\n");
			m.append(String.format("• Order total: **₹%.2f**%n", total));
			if (deductPct > 0) {
				m.append(String.format("• Deduction (%.0f%%): **₹%.2f** — _%s_%n", deductPct, deduction, deductReason));
				m.append(String.format("• **Refund amount: ₹%.2f**%n%n", refund));
				m.append("The deduction applies because your order was already **").append(friendlyStage(stage))
						.append("**.\n\n");
			} else {
				m.append(String.format("• **Full refund: ₹%.2f**%n%n", refund));
			}
			m.append("Your refund is **Pending Staff Approval**. Once approved, it will be credited to your ").append(
					"wallet or original payment method within **3–5 business days**.\n\nA notification has been sent to our staff. 📋");
		} else {
			m.append("Based on the order stage (**").append(stage).append("**), a refund is not applicable.\n\n")
					.append("If you believe this is an error, please raise a support ticket — our team will review your case.");
		}
		return m.toString();
	}

	private boolean isInMotion(String s) {
		return s != null && (s.equals("Assigned") || s.equals("Picked Up") || s.equals("Packed") || s.equals("Shipped")
				|| s.equals("Out for Delivery"));
	}

	private String friendlyStage(String s) {
		if (s == null) {
			return "processing";
		}
		return switch (s) {
		case "Assigned" -> "assigned to a delivery agent";
		case "Picked Up" -> "picked up from the warehouse";
		case "Packed" -> "packed and ready for dispatch";
		case "Shipped" -> "shipped / in transit";
		case "Out for Delivery" -> "out for delivery";
		default -> s.toLowerCase();
		};
	}

	private double computeRefund(String status, double total, boolean isPaid) {
		if (!isPaid) {
			return 0;
		}
		return switch (status != null ? status : "") {
		case "Ordered", "Pending", "Confirmed" -> total;
		case "Assigned", "Picked Up", "Packed" -> total * 0.95;
		case "Shipped", "Out for Delivery" -> total * 0.90;
		default -> 0;
		};
	}

	private double deductPct(String status) {
		return switch (status != null ? status : "") {
		case "Assigned", "Picked Up", "Packed" -> 5;
		case "Shipped", "Out for Delivery" -> 10;
		default -> 0;
		};
	}

	// ══════════════════════════════════════════════════════════════════════
	// LocalAIEngine — UNCHANGED from current file
	// ══════════════════════════════════════════════════════════════════════
	static class LocalAIEngine {

		static class AiReply {
			String text, cardType, cardOrderId;

			AiReply(String t) {
				text = t;
			}

			AiReply(String t, String ct, String oid) {
				text = t;
				cardType = ct;
				cardOrderId = oid;
			}
		}

		static AiReply respond(String userMsg, Customer customer, List<Order> orders) {
			String m = userMsg.toLowerCase().trim();
			String name = (customer != null && customer.getName() != null) ? customer.getName().split(" ")[0] : "there";

			if (any(m, "hi", "hello", "hey", "namaste", "good morning", "good evening", "howdy")) {
				if (orders == null || orders.isEmpty()) {
					return new AiReply("Hey " + name + "! 👋 Welcome to **GreenCart Support** — I'm Kira.\n\n"
							+ "You don't have any orders yet. Once you place one, I can help you track, cancel, return, or resolve any issue.\n\nHow can I help today?");
				}
				Order latest = orders.get(0);
				return new AiReply("Hey " + name + "! 👋 Great to see you.\n\nYour most recent order is **#"
						+ latest.getId() + "** — currently **" + latest.getStatus() + "** (₹"
						+ fmt(latest.getTotalAmount()) + ").\n\nHow can I help today?");
			}
			if (any(m, "my orders", "show orders", "order history", "all orders", "list orders")) {
				if (orders == null || orders.isEmpty()) {
					return new AiReply("You haven't placed any orders yet, " + name
							+ ". Start shopping and I'll keep you updated!");
				}
				StringBuilder sb = new StringBuilder("Here are your recent orders, " + name + ":\n\n");
				orders.stream().limit(6)
						.forEach(o -> sb.append("• **#").append(o.getId()).append("** — ").append(o.getStatus())
								.append(" — ₹").append(fmt(o.getTotalAmount())).append(" (")
								.append(o.getPaymentMethod()).append(")\n"));
				if (orders.size() > 6) {
					sb.append("\n…and ").append(orders.size() - 6).append(" more.");
				}
				return new AiReply(sb.toString());
			}
			if (any(m, "cancel", "cancellation", "i want to cancel", "stop my order", "cancel order")) {
				Order delivered = findByStatus(orders, "Delivered");
				Order active = findByStatus(orders, "Ordered", "Pending", "Confirmed", "Assigned", "Picked Up",
						"Packed", "Shipped", "Out for Delivery");
				if (delivered != null && active == null) {
					return new AiReply(
							"Order **#" + delivered.getId() + "** is already **delivered** — it can't be cancelled.\n\n"
									+ "You can initiate a **Return or Replace** within 10 days of delivery.",
							"return_request", "ORD-" + delivered.getId());
				}
				Order cancelled = findByStatus(orders, "Cancelled");
				if (cancelled != null && active == null) {
					return new AiReply("Your order **#" + cancelled.getId()
							+ "** is already **Cancelled**. Need help with refund status? Just ask!");
				}
				Order inTransit = findByStatus(orders, "Shipped", "Out for Delivery", "Assigned");
				if (inTransit != null) {
					return new AiReply(
							"Order **#" + inTransit.getId() + "** is currently **" + inTransit.getStatus() + "**.\n\n"
									+ "⚠ Cancelling now will incur a **10% shipping charge** (₹"
									+ fmt(inTransit.getTotalAmount() * 0.10) + "). " + "Your refund would be **₹"
									+ fmt(inTransit.getTotalAmount() * 0.90) + "**.\n\n"
									+ "A courier intercept will be attempted — I'll confirm within 2 hours. Proceed?",
							"cancel_confirm", "ORD-" + inTransit.getId());
				}
				Order handling = findByStatus(orders, "Picked Up", "Packed");
				if (handling != null) {
					return new AiReply(
							"Order **#" + handling.getId() + "** is **" + handling.getStatus() + "**.\n\n"
									+ "A **5% handling fee** (₹" + fmt(handling.getTotalAmount() * 0.05)
									+ ") will be deducted — " + "your refund will be **₹"
									+ fmt(handling.getTotalAmount() * 0.95) + "**. Proceed?",
							"cancel_confirm", "ORD-" + handling.getId());
				}
				Order preShip = findByStatus(orders, "Ordered", "Pending", "Confirmed");
				if (preShip != null) {
					return new AiReply(
							"Order **#" + preShip.getId() + "** can be cancelled with a **full refund of ₹"
									+ fmt(preShip.getTotalAmount()) + "**.\n\n• Status: " + preShip.getStatus()
									+ "\n• Payment: " + preShip.getPaymentMethod() + "\n\nConfirm below to proceed.",
							"cancel_confirm", "ORD-" + preShip.getId());
				}
				return new AiReply("I couldn't find a cancellable order right now, " + name
						+ ".\n\nOrders can be cancelled up to the 'Out for Delivery' stage. Would you like me to raise a support ticket?",
						"raise_ticket", null);
			}
			if (any(m, "track", "where is my order", "where's my", "order status", "when will i get",
					"expected delivery", "tracking", "delivery status", "estimated")) {
				if (orders == null || orders.isEmpty()) {
					return new AiReply("You don't have any active orders to track right now, " + name + ".");
				}
				Order a = findByStatus(orders, "Shipped", "Assigned", "Processing", "Confirmed", "Pending", "Ordered",
						"Out for Delivery", "Picked Up", "Packed");
				if (a == null) {
					a = orders.get(0);
				}
				String eta = a.getDeliveryDate() != null ? a.getDeliveryDate().toString() : "within 3–5 business days";
				return new AiReply(
						"**Order #" + a.getId() + "** tracking:\n\n• Status: **" + a.getStatus() + "**\n• Payment: "
								+ a.getPaymentStatus() + "\n• ETA: **" + eta
								+ "**\n\nYou'll receive an SMS when it's out for delivery! 📱",
						"delivery_info", "ORD-" + a.getId());
			}
			if (any(m, "return", "return order", "i want to return", "damaged", "wrong item", "defective", "exchange",
					"replace", "spoiled", "expired", "broken")) {
				Order del = findByStatus(orders, "Delivered");
				if (del != null) {
					boolean inWindow = true;
					if (del.getDeliveryDate() != null) {
						long diff = (System.currentTimeMillis() - del.getDeliveryDate().getTime()) / 86400000L;
						inWindow = diff <= 10;
					}
					if (!inWindow) {
						return new AiReply("The **10-day return window** for Order **#" + del.getId()
								+ "** has expired. "
								+ "If there are exceptional circumstances, I can raise a support ticket for our team to review.",
								"raise_ticket", null);
					}
					return new AiReply("Order **#" + del.getId() + "** (₹" + fmt(del.getTotalAmount())
							+ ") is **eligible for return**. ✅\n\n"
							+ "**Return policy:**\n• 10-day window from delivery\n• Pickup within 48 hrs of approval\n"
							+ "• Refund after item received at warehouse\n\nSelect issue type below 👇",
							"return_request", "ORD-" + del.getId());
				}
				Order inPipeline = findByStatus(orders, "Return Requested", "Refunded", "Replaced", "Return Approved");
				if (inPipeline != null) {
					return new AiReply(
							"A " + inPipeline.getStatus() + " is already logged for Order **#" + inPipeline.getId()
									+ "**.\n\nIf you need a status update, raise a support ticket and I'll escalate.");
				}
				return new AiReply(
						"Returns are available for **delivered orders** within 10 days. No recently delivered order found on your account. Please share the Order ID.");
			}
			if (any(m, "refund", "refund status", "where is my refund", "refund pending")) {
				Order refunded = findByStatus(orders, "Refunded");
				if (refunded != null) {
					return new AiReply("Order **#" + refunded.getId() + "** shows **Refunded**! 🎉\n\n₹"
							+ fmt(refunded.getTotalAmount())
							+ " should reflect in your account within **2–3 business days**. If not received after 7 days, let me know and I'll escalate immediately.");
				}
				Order cancelled = findByStatus(orders, "Cancelled");
				if (cancelled != null && "PAID".equalsIgnoreCase(cancelled.getPaymentStatus())) {
					return new AiReply("Order **#" + cancelled.getId() + "** was cancelled — your refund of **₹"
							+ fmt(cancelled.getTotalAmount())
							+ "** is **Pending Staff Approval**.\n\nOur team processes refunds within **24–48 hours**. Would you like me to raise a priority ticket?",
							"raise_ticket", "ORD-" + cancelled.getId());
				}
				return new AiReply(
						"I don't see a pending refund on your account right now. Could you share the Order ID you're asking about?");
			}
			if (any(m, "payment", "payment failed", "charged twice", "double charge", "money deducted",
					"failed payment", "transaction failed", "transaction")) {
				Order failed = findByPayStatus(orders, "PAYMENT_FAILED", "FAILED");
				if (failed != null) {
					return new AiReply("Your payment for **Order #" + failed.getId() + "** (₹"
							+ fmt(failed.getTotalAmount())
							+ ") has **failed**.\n\n**No amount was charged.** You can retry the payment or switch to COD.",
							"payment_issue", "ORD-" + failed.getId());
				}
				return new AiReply("I don't see a failed transaction right now, " + name
						+ ". If money was incorrectly deducted, it typically auto-refunds within **3–5 business days**. Want me to raise a support ticket?",
						"raise_ticket", null);
			}
			if (any(m, "invoice", "receipt", "bill", "download invoice", "pdf", "tax invoice")) {
				Order paid = findByPayStatus(orders, "PAID", "SUCCESS", "COMPLETED");
				if (paid == null) {
					paid = findByStatus(orders, "Delivered");
				}
				if (paid != null) {
					return new AiReply("Your invoice for **Order #" + paid.getId() + "** (₹"
							+ fmt(paid.getTotalAmount()) + ") is ready!", "invoice_ready", "ORD-" + paid.getId());
				}
				return new AiReply("I couldn't find a paid order for an invoice. Could you share the Order ID?");
			}
			if (any(m, "address", "change address", "update address", "wrong address", "delivery address",
					"shipping address")) {
				Order preShip = findByStatus(orders, "Ordered", "Pending", "Confirmed");
				if (preShip != null) {
					return new AiReply(
							"Good news! **Order #" + preShip.getId()
									+ "** hasn't been dispatched — I can update the delivery address right now.",
							"address_edit", "ORD-" + preShip.getId());
				}
				Order shipped = findByStatus(orders, "Shipped", "Assigned", "Out for Delivery", "Picked Up", "Packed");
				if (shipped != null) {
					return new AiReply("Order **#" + shipped.getId() + "** is already **" + shipped.getStatus()
							+ "** — address cannot be changed directly.\n\n"
							+ "I've raised an urgent address-correction ticket for the delivery agent. Please ensure someone is available at the correct address.",
							"raise_ticket", null);
				}
				return new AiReply(
						"For unshipped orders I can change the address directly. For shipped orders I'll raise an urgent delivery note. Please share the Order ID.");
			}
			if (any(m, "ticket", "raise ticket", "speak to agent", "live agent", "human", "escalate", "manager",
					"supervisor", "connect me", "help")) {
				return new AiReply("Of course, " + name
						+ "! Let me raise a support ticket — our team will call you back within 2–4 hours.\n\nPlease describe your issue below 👇",
						"raise_ticket", null);
			}
			if (any(m, "thank", "thanks", "thank you", "great", "awesome", "perfect")) {
				return new AiReply(
						"You're most welcome, " + name + "! 😊 GreenCart is always here for you. Happy shopping! 🌿");
			}
			if (any(m, "bye", "goodbye", "see you", "later", "take care")) {
				return new AiReply(
						"Goodbye, " + name + "! Have a wonderful day. 👋 GreenCart is here whenever you need us! 🌿");
			}

			return new AiReply("Hi " + name
					+ "! I'm **Kira**, your GreenCart support assistant. Here's what I can help with:\n\n"
					+ "• **📦 Track Order** — Real-time status\n"
					+ "• **✕ Cancel Order** — Cancel with refund policy details\n"
					+ "• **↩ Return / Replace** — 10-day window for delivered orders\n"
					+ "• **💳 Payment Issues** — Failed transactions, double charges\n"
					+ "• **📍 Change Address** — Pre-dispatch only\n" + "• **🧾 Invoice** — Download tax invoice\n"
					+ "• **🎫 Support Ticket** — Human agent callback\n\n"
					+ "Type your Order ID or tap a button to begin!");
		}

		private static boolean any(String m, String... kw) {
			for (String k : kw) {
				if (m.contains(k)) {
					return true;
				}
			}
			return false;
		}

		private static Order findByStatus(List<Order> l, String... ss) {
			if (l == null) {
				return null;
			}
			for (Order o : l) {
				for (String s : ss) {
					if (s.equalsIgnoreCase(o.getStatus())) {
						return o;
					}
				}
			}
			return null;
		}

		private static Order findByPayStatus(List<Order> l, String... ss) {
			if (l == null) {
				return null;
			}
			for (Order o : l) {
				for (String s : ss) {
					if (o.getPaymentStatus() != null && s.equalsIgnoreCase(o.getPaymentStatus())) {
						return o;
					}
				}
			}
			return null;
		}

		private static String fmt(double v) {
			return String.format("%.2f", v);
		}
	}

	// ══════════════════════════════════════════════════════════════════════
	// HELPERS
	// ══════════════════════════════════════════════════════════════════════

	private int requireCustomerId(HttpServletRequest req, HttpServletResponse res) throws IOException {
		HttpSession hs = req.getSession(false);
		Object attr = (hs != null) ? hs.getAttribute("customerId") : null;
		if (!(attr instanceof Integer)) {
			res.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
			res.getWriter()
					.write("{\"error\":\"NOT_LOGGED_IN\"," + "\"message\":\"Please log in to use GreenCart Support.\","
							+ "\"loginUrl\":\"CustomerLogin.jsp\"}");
			return -1;
		}
		return (Integer) attr;
	}

	// handleNewSession: close active session so next boot() starts fresh
	private void handleNewSession(HttpServletRequest req, HttpServletResponse res, PrintWriter out, int customerId)
			throws Exception {
		try {
			ChatSession existing = chatDAO.getActiveCustomerSession(customerId);
			if (existing != null) {
				chatDAO.resolveSession(existing.getSessionId());
			}
		} catch (Exception ignored) {
		}
		out.write("{\"success\":true}");
	}

	private ChatSession getOrCreateSession(int customerId) throws SQLException {
		ChatSession existing = chatDAO.getActiveCustomerSession(customerId);
		return existing != null ? existing : chatDAO.createCustomerSession(customerId);
	}

	private int parseOrderId(String raw) {
		if (raw == null) {
			return -1;
		}
		try {
			return Integer.parseInt(raw.replaceAll("[^0-9]", "").trim());
		} catch (NumberFormatException e) {
			return -1;
		}
	}

	/**
	 * orderToJson — UPDATED: includes snap_* address fields from the order row. The
	 * widget now reads order.snapStreet/snapCity/snapState/snapPincode to display
	 * the frozen delivery address instead of re-joining customer_address.
	 */
	private String orderToJson(Order o) {
		StringBuilder sb = new StringBuilder("{");
		sb.append("\"id\":").append(o.getId()).append(",");
		sb.append("\"customerId\":").append(o.getCustomerId()).append(",");
		sb.append("\"status\":").append(js(o.getStatus())).append(",");
		sb.append("\"paymentStatus\":").append(js(o.getPaymentStatus())).append(",");
		sb.append("\"paymentMethod\":").append(js(o.getPaymentMethod())).append(",");
		sb.append("\"transactionId\":").append(js(o.getTransactionId())).append(",");
		sb.append("\"totalAmount\":").append(o.getTotalAmount()).append(",");
		sb.append("\"orderDate\":").append(js(o.getDate() != null ? o.getDate().toString() : null)).append(",");
		sb.append("\"deliveryDate\":").append(js(o.getDeliveryDate() != null ? o.getDeliveryDate().toString() : null))
				.append(",");
		// ── SNAP ADDRESS (frozen at placement time) ──────────────────────────
		sb.append("\"address\":").append(js(o.getAddress())).append(","); // CONCAT_WS from snap_*
		sb.append("\"snapStreet\":").append(js(o.getSnapStreet())).append(",");
		sb.append("\"snapCity\":").append(js(o.getSnapCity())).append(",");
		sb.append("\"snapState\":").append(js(o.getSnapState())).append(",");
		sb.append("\"snapPincode\":").append(js(o.getSnapPincode())).append(",");
		sb.append("\"addressChangedAt\":")
				.append(js(o.getAddressChangedAt() != null ? o.getAddressChangedAt().toString() : null)).append(",");
		// ── CUSTOMER ─────────────────────────────────────────────────────────
		sb.append("\"customerName\":").append(js(o.getCustomerName())).append(",");
		sb.append("\"customerPhone\":").append(js(o.getPhone())).append(",");
		// ── ITEMS ─────────────────────────────────────────────────────────────
		sb.append("\"items\":[");
		List<CartItem> items = o.getItems();
		if (items != null) {
			for (int i = 0; i < items.size(); i++) {
				if (i > 0) {
					sb.append(",");
				}
				CartItem it = items.get(i);
				sb.append("{\"productId\":").append(it.getProductId()).append(",");
				sb.append("\"name\":").append(js(it.getName())).append(",");
				sb.append("\"imageUrl\":").append(js(it.getImageUrl())).append(",");
				sb.append("\"quantity\":").append(it.getQuantity()).append(",");
				sb.append("\"finalPrice\":").append(it.getFinalPrice()).append("}");
			}
		}
		sb.append("]}");
		return sb.toString();
	}

	private String messageToJson(ChatMessage m) {
		String sentAt = m.getSentAt() != null ? m.getSentAt().toString() : "";
		return "{\"messageId\":" + m.getMessageId() + ",\"role\":" + js(m.getRole()) + ",\"content\":"
				+ js(m.getContent()) + ",\"cardType\":"
				+ (m.getCardType() != null ? "\"" + esc(m.getCardType()) + "\"" : "null") + ",\"cardOrderId\":"
				+ (m.getCardOrderId() != null ? "\"" + esc(m.getCardOrderId()) + "\"" : "null") + ",\"sentAt\":\""
				+ esc(sentAt) + "\"}";
	}

	private void staffNotif(Order order, Customer customer, String summary, String action) {
		try {
			StaffNotification n = new StaffNotification();
			n.setOrderId(order.getId());
			n.setPaymentMethod(order.getPaymentMethod() != null ? order.getPaymentMethod() : "N/A");
			n.setPaymentStatus("CHAT_ACTION");
			n.setGrandTotal(order.getTotalAmount());
			n.setCustomerName(customer != null ? customer.getName() : "Unknown");
			n.setCustomerEmail(customer != null ? customer.getEmail() : "");
			n.setCustomerPhone(customer != null ? customer.getPhone() : "");
			n.setItemsSummary(summary);
			n.setActionRequired(action);
			notifDAO.insert(n);
		} catch (Exception ex) {
			log.log(Level.WARNING, "staffNotif insert failed", ex);
		}
	}

	private static String fmt(double v) {
		return String.format("%.2f", v);
	}

	private String js(String s) {
		return s == null ? "null" : "\"" + esc(s) + "\"";
	}

	private String nvl(String a, String b) {
		return (a != null && !a.isBlank()) ? a : b;
	}

	private boolean isBlank(String s) {
		return s == null || s.isBlank();
	}

	private String esc(String s) {
		if (s == null) {
			return "";
		}
		return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "\\r").replace("\t",
				"\\t");
	}
}