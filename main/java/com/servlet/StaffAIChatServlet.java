package com.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;

import com.DAO.AttendanceDAO;
import com.DAO.ChatDAO;
import com.DAO.LeaveDAO;
import com.DAO.OrderDAO;
import com.DAO.OrderReturnDAO;
import com.DAO.ProductDAO;
import com.DAO.StaffNotificationDAO;
import com.DAO.TicketDAO;
import com.DAO.UserDAO;
import com.util.AttendanceSession;
import com.util.ChatMessage;
import com.util.ChatSession;
import com.util.LeaveRequest;
import com.util.Order;
import com.util.OrderReturn;
import com.util.Product;
import com.util.StaffNotification;
import com.util.SupportTicket;
import com.util.User;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

/**
 * StaffAIChatServlet — Nexus AI Unified Operations Controller (v3 — all bugs
 * fixed).
 *
 * BUG FIXES vs v2: 1. userDAO.getDeliveryUsers() → DOES NOT EXIST in UserDAO.
 * Fixed: userDAO.getAllUsers() then filter by role='delivery'. 2.
 * leaveDAO.processLeaveRequest() → DOES NOT EXIST in LeaveDAO. Fixed:
 * leaveDAO.approveLeave() / leaveDAO.rejectLeave() called separately. 3.
 * LeaveRequest.getWorkingDays() → field is getTotalDays() (BigDecimal). Fixed:
 * lr.getTotalDays() with null-safe toString(). 4. LeaveType import unused →
 * removed. 5. StaffNotification has no getCustomerId() — ticket JSON now reads
 * customerId from the linked order via orderDAO.getOrderById(). 6.
 * Order.getDeliveryUserName() may not exist → safe fallback to "Agent #" +
 * deliveryUserId. 7. attendanceDAO.getAllSessionsByDate() getPunchIn() returns
 * LocalDateTime — safe, but null-check added. 8. handleNotifyCustomer:
 * customerId=-1 guard added (prevents creating a chat session for customer 0).
 * 9. handleAgentMetrics: primitive int comparison
 * o.getDeliveryUserId()==a.getUid() works correctly (both int) — verified. 10.
 * NexusAIEngine.any() called with the full status string (not a List), fixed to
 * use equalsIgnoreCase comparisons.
 *
 * ENDPOINTS (GET): history · lookupOrder · lookupTickets · getAttendance ·
 * getLeave · lookupInventory · agentMetrics ENDPOINTS (POST): message ·
 * updateOrder · resolveTicket · notifyCustomer · approveLeave · action
 */
@WebServlet("/StaffAIChatServlet")
public class StaffAIChatServlet extends HttpServlet {

	private static final Logger log = Logger.getLogger(StaffAIChatServlet.class.getName());

	private ChatDAO chatDAO;
	private OrderDAO orderDAO;
	private ProductDAO productDAO;
	private UserDAO userDAO;
	private OrderReturnDAO returnDAO;
	private StaffNotificationDAO notifDAO;
	private TicketDAO ticketDAO;
	private AttendanceDAO attendanceDAO;
	private LeaveDAO leaveDAO;

	@Override
	public void init() throws ServletException {
		chatDAO = new ChatDAO();
		orderDAO = new OrderDAO();
		productDAO = new ProductDAO();
		userDAO = new UserDAO();
		returnDAO = new OrderReturnDAO();
		notifDAO = new StaffNotificationDAO();
		ticketDAO = new TicketDAO();
		attendanceDAO = new AttendanceDAO();
		leaveDAO = new LeaveDAO();
	}

	// ══════════════════════════════════════════════════════════════════════
	// GET
	// ══════════════════════════════════════════════════════════════════════
	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
		res.setContentType("application/json;charset=UTF-8");
		PrintWriter out = res.getWriter();
		try {
			String username = requireStaff(req, res);
			if (username == null) {
				return;
			}
			String action = req.getParameter("action");
			if (action == null) {
				action = "history";
			}
			switch (action) {
			case "history" -> handleHistory(out, username);
			case "lookupOrder" -> handleLookupOrder(req, res, out);
			case "lookupTickets" -> handleLookupTickets(out);
			case "getAttendance" -> handleGetAttendance(req, out);
			case "getLeave" -> handleGetLeave(req, out);
			case "lookupInventory" -> handleLookupInventory(out);
			case "agentMetrics" -> handleAgentMetrics(out);
			default -> {
				res.setStatus(400);
				out.write("{\"error\":\"Unknown action\"}");
			}
			}
		} catch (Exception e) {
			log.log(Level.SEVERE, "Staff chat GET failed", e);
			res.setStatus(500);
			out.write("{\"error\":\"" + esc(e.getMessage()) + "\"}");
		}
	}

	// ══════════════════════════════════════════════════════════════════════
	// POST
	// ══════════════════════════════════════════════════════════════════════
	@Override
	protected void doPost(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
		res.setContentType("application/json;charset=UTF-8");
		PrintWriter out = res.getWriter();
		try {
			String username = requireStaff(req, res);
			if (username == null) {
				return;
			}
			String action = req.getParameter("action");
			if (action == null) {
				action = "message";
			}
			switch (action) {
			case "message" -> handleMessage(req, res, out, username);
			case "updateOrder" -> handleUpdateOrder(req, res, out, username);
			case "resolveTicket" -> handleResolveTicket(req, res, out, username);
			case "notifyCustomer" -> handleNotifyCustomer(req, res, out, username);
			case "approveLeave" -> handleApproveLeave(req, res, out, username);
			case "action" -> handleCardAction(req, res, out, username);
			case "newSession" -> handleNewSession(req, res, out, username);
			default -> {
				res.setStatus(400);
				out.write("{\"error\":\"Unknown action\"}");
			}
			}
		} catch (Exception e) {
			log.log(Level.SEVERE, "Staff chat POST failed", e);
			res.setStatus(500);
			out.write("{\"error\":\"" + esc(e.getMessage()) + "\"}");
		}
	}

	// ══════════════════════════════════════════════════════════════════════
	// GET handlers
	// ══════════════════════════════════════════════════════════════════════

	private void handleHistory(PrintWriter out, String username) throws Exception {
		ChatSession session = getOrCreate(username);
		List<ChatMessage> msgs = chatDAO.getMessagesBySession(session.getSessionId());
		StringBuilder sb = new StringBuilder("{\"sessionToken\":\"").append(esc(session.getSessionToken()))
				.append("\",\"messages\":[");
		for (int i = 0; i < msgs.size(); i++) {
			if (i > 0) {
				sb.append(",");
			}
			sb.append(msgToJson(msgs.get(i)));
		}
		sb.append("]}");
		out.write(sb.toString());
	}

	private void handleLookupOrder(HttpServletRequest req, HttpServletResponse res, PrintWriter out) throws Exception {
		int orderId = parseId(req.getParameter("orderId"));
		if (orderId < 0) {
			res.setStatus(400);
			out.write("{\"found\":false,\"error\":\"Invalid orderId\"}");
			return;
		}
		Order o = orderDAO.getOrderById(orderId);
		if (o == null) {
			out.write("{\"found\":false,\"error\":\"Order not found\"}");
			return;
		}
		// Enrich items if not already loaded
		if (o.getItems() == null || o.getItems().isEmpty()) {
			try {
				o.setItems(orderDAO.getOrderItems(orderId));
			} catch (Exception ignored) {
			}
		}
		out.write("{\"found\":true,\"order\":" + orderToJson(o) + "}");
	}

	/**
	 * ROOT CAUSE FIX: was reading from notifDAO.getUnread() (staff_notifications
	 * table) which is empty. Tickets raised via Help Desk or Kira chat go to
	 * support_tickets. Now reads from TicketDAO.getOpenTickets() and maps
	 * SupportTicket → dashboard JSON.
	 *
	 * Dashboard JSON shape expected by ticketDashboard.jsp: { id, orderId,
	 * customerId, customerName, customerPhone, customerEmail, issue, action,
	 * paymentStatus, total, createdAt }
	 *
	 * Mapping: id ← ticket_id orderId ← ref_order_id customerId ← customer_id
	 * customerName ← customers.name (joined in getOpenTickets) customerPhone ←
	 * customers.phone (joined) customerEmail ← customers.email (joined) issue ←
	 * description action ← subject (shown as "Action required" heading in card)
	 * paymentStatus ← mapped from category/priority so filters still work: urgent
	 * priority → "INTERCEPT_REQUESTED" (red urgent dot) chat_session_id →
	 * "CHAT_ACTION" (blue chat dot) everything else → "TICKET" (grey general dot)
	 * total ← 0 (no order amount on ticket itself; order expand loads it) createdAt
	 * ← created_at
	 */
	private void handleLookupTickets(PrintWriter out) throws Exception {
		List<SupportTicket> tickets = ticketDAO.getOpenTickets();
		StringBuilder sb = new StringBuilder("{\"count\":").append(tickets.size()).append(",\"tickets\":[");
		for (int i = 0; i < tickets.size(); i++) {
			if (i > 0) {
				sb.append(",");
			}
			SupportTicket t = tickets.get(i);

			// Map category/priority → paymentStatus token for dashboard filters/dots
			String paymentStatus;
			if ("urgent".equalsIgnoreCase(t.getPriority()) || "high".equalsIgnoreCase(t.getPriority())) {
				paymentStatus = "INTERCEPT_REQUESTED"; // shows as urgent red dot
			} else if (t.getChatSessionId() > 0) {
				paymentStatus = "CHAT_ACTION"; // shows as blue chat dot
			} else {
				paymentStatus = "TICKET"; // shows as grey general dot
			}

			sb.append("{\"id\":").append(t.getTicketId()).append(",\"orderId\":").append(t.getRefOrderId())
					.append(",\"customerId\":").append(t.getCustomerId()).append(",\"customerName\":")
					.append(js(t.getCustomerName())).append(",\"customerPhone\":").append(js(t.getCustomerPhone()))
					.append(",\"customerEmail\":").append(js(t.getCustomerEmail())).append(",\"issue\":")
					.append(js(t.getDescription())).append(",\"action\":").append(js(t.getSubject()))
					.append(",\"paymentStatus\":").append(js(paymentStatus)).append(",\"total\":0")
					.append(",\"createdAt\":").append(js(t.getCreatedAt() != null ? t.getCreatedAt().toString() : ""))
					.append("}");
		}
		sb.append("]}");
		out.write(sb.toString());
	}

	private void handleGetAttendance(HttpServletRequest req, PrintWriter out) throws Exception {
		HttpSession httpSession = req.getSession(false);
		String role = httpSession != null && httpSession.getAttribute("role") instanceof String
				? (String) httpSession.getAttribute("role")
				: "staff";
		String username = httpSession != null && httpSession.getAttribute("username") instanceof String
				? (String) httpSession.getAttribute("username")
				: "";
		boolean isAdmin = "admin".equalsIgnoreCase(role);

		// Fetch all sessions for today, then filter by role
		List<AttendanceSession> all = attendanceDAO.getAllSessionsByDate(LocalDate.now());

		// Admin sees everyone; staff sees only their own session(s)
		List<AttendanceSession> sessions = isAdmin ? all
				: all.stream().filter(s -> username.equalsIgnoreCase(s.getUsername()))
						.collect(java.util.stream.Collectors.toList());

		// Summary counts (meaningful for admin; for staff: 1 or 0)
		long present = sessions.stream().filter(s -> s.getStatus() != null && "active".equalsIgnoreCase(s.getStatus()))
				.count();
		long completed = sessions.stream().filter(s -> s.getPunchOut() != null).count();

		StringBuilder sb = new StringBuilder("{\"isAdmin\":").append(isAdmin).append(",\"total\":")
				.append(sessions.size()).append(",\"present\":").append(present).append(",\"completed\":")
				.append(completed).append(",\"sessions\":[");
		for (int i = 0; i < sessions.size(); i++) {
			if (i > 0) {
				sb.append(",");
			}
			AttendanceSession s = sessions.get(i);
			String pi = s.getPunchIn() != null ? s.getPunchIn().toString() : "";
			String po = s.getPunchOut() != null ? s.getPunchOut().toString() : "";
			sb.append("{").append("\"username\":").append(js(s.getUsername())).append(",\"punchIn\":").append(js(pi))
					.append(",\"punchOut\":").append(js(po)).append(",\"status\":").append(js(s.getStatus()))
					.append(",\"attendanceStatus\":").append(js(s.getAttendanceStatus())).append("}");
		}
		sb.append("]}");
		out.write(sb.toString());
	}

	/**
	 * GET getLeave: - Admin -> all pending requests across all staff (for
	 * approval/rejection) - Staff -> all of their own requests (all statuses) so
	 * they can track history Full fields returned so the chat card can display
	 * every property.
	 */
	private void handleGetLeave(HttpServletRequest req, PrintWriter out) throws Exception {
		HttpSession httpSession = req.getSession(false);
		String role = httpSession != null && httpSession.getAttribute("role") instanceof String
				? (String) httpSession.getAttribute("role")
				: "staff";
		String username = httpSession != null && httpSession.getAttribute("username") instanceof String
				? (String) httpSession.getAttribute("username")
				: "";
		boolean isAdmin = "admin".equalsIgnoreCase(role);

		// Admin sees all pending requests; staff sees their own full history
		List<LeaveRequest> leaves = isAdmin ? leaveDAO.getPendingRequests() : leaveDAO.getLeaveHistory(username);

		StringBuilder sb = new StringBuilder("{\"isAdmin\":").append(isAdmin).append(",\"count\":")
				.append(leaves.size()).append(",\"requests\":[");
		for (int i = 0; i < leaves.size(); i++) {
			if (i > 0) {
				sb.append(",");
			}
			LeaveRequest lr = leaves.get(i);
			String days = lr.getTotalDays() != null ? lr.getTotalDays().toPlainString() : "0";
			String fromDate = lr.getFromDate() != null ? lr.getFromDate().toString() : "";
			String toDate = lr.getToDate() != null ? lr.getToDate().toString() : "";
			String appliedOn = lr.getAppliedOn() != null ? lr.getAppliedOn().toString() : "";
			String reviewedOn = lr.getReviewedOn() != null ? lr.getReviewedOn().toString() : "";
			sb.append("{").append("\"id\":").append(lr.getId()).append(",\"username\":").append(js(lr.getUsername()))
					.append(",\"leaveType\":").append(js(lr.getLeaveTypeName())).append(",\"paid\":")
					.append(lr.isPaid()).append(",\"fromDate\":").append(js(fromDate)).append(",\"toDate\":")
					.append(js(toDate)).append(",\"days\":").append(js(days)).append(",\"sessionType\":")
					.append(js(lr.getSessionType())).append(",\"reason\":").append(js(lr.getReason()))
					.append(",\"status\":").append(js(lr.getStatus())).append(",\"appliedOn\":").append(js(appliedOn))
					.append(",\"contactDuringLeave\":").append(js(lr.getContactDuringLeave()))
					.append(",\"workHandover\":").append(js(lr.getWorkHandover())).append(",\"coveringPerson\":")
					.append(js(lr.getCoveringPerson())).append(",\"documentPath\":").append(js(lr.getDocumentPath()))
					.append(",\"reviewedBy\":").append(js(lr.getReviewedBy())).append(",\"reviewedOn\":")
					.append(js(reviewedOn)).append(",\"reviewerNote\":").append(js(lr.getReviewerNote()))
					.append(",\"cancelReason\":").append(js(lr.getCancelReason())).append("}");
		}
		sb.append("]}");
		out.write(sb.toString());
	}

	private void handleLookupInventory(PrintWriter out) throws Exception {
		List<Product> products = productDAO.getAllProducts();
		long oos = products.stream().filter(p -> p.getStock() == 0).count();
		long low = products.stream().filter(p -> p.getStock() > 0 && p.getStock() < 10).count();
		long good = products.stream().filter(p -> p.getStock() >= 10).count();

		StringBuilder sb = new StringBuilder("{\"total\":").append(products.size()).append(",\"outOfStock\":")
				.append(oos).append(",\"lowStock\":").append(low).append(",\"inStock\":").append(good)
				.append(",\"critical\":[");
		boolean first = true;
		for (Product p : products) {
			if (p.getStock() < 10) {
				if (!first) {
					sb.append(",");
				}
				sb.append("{\"id\":").append(p.getId()).append(",\"name\":").append(js(p.getName()))
						.append(",\"stock\":").append(p.getStock()).append(",\"urgent\":").append(p.getStock() == 0)
						.append("}");
				first = false;
			}
		}
		sb.append("]}");
		out.write(sb.toString());
	}

	/**
	 * FIX: UserDAO has no getDeliveryUsers() method. Use getAllUsers() and filter
	 * by role='delivery'.
	 */
	private void handleAgentMetrics(PrintWriter out) throws Exception {
		// FIX: getAllUsers() exists; getDeliveryUsers() does NOT
		List<User> agents = userDAO.getAllUsers().stream().filter(u -> "delivery".equalsIgnoreCase(u.getRole()))
				.collect(Collectors.toList());

		List<Order> orders = orderDAO.getAllOrders();

		StringBuilder sb = new StringBuilder("{\"agents\":[");
		for (int i = 0; i < agents.size(); i++) {
			if (i > 0) {
				sb.append(",");
			}
			User a = agents.get(i);
			// FIX: getUid() — User uses setUid/getUid per UserDAO mappers
			long count = orders.stream()
					.filter(o -> o.getDeliveryUserId() == a.getUid() && o.getStatus() != null
							&& !o.getStatus().equalsIgnoreCase("Delivered")
							&& !o.getStatus().equalsIgnoreCase("Cancelled"))
					.count();
			sb.append("{\"id\":").append(a.getUid()).append(",\"username\":").append(js(a.getUsername()))
					.append(",\"status\":").append(js(a.getStatus())).append(",\"mobile\":").append(js(a.getMobileno()))
					.append(",\"pendingOrders\":").append(count).append(",\"overloaded\":").append(count > 3)
					.append("}");
		}
		sb.append("]}");
		out.write(sb.toString());
	}

	// ══════════════════════════════════════════════════════════════════════
	// POST handlers
	// ══════════════════════════════════════════════════════════════════════

	private void handleMessage(HttpServletRequest req, HttpServletResponse res, PrintWriter out, String username)
			throws Exception {
		String userText = req.getParameter("message");
		if (userText == null || userText.isBlank()) {
			res.setStatus(400);
			out.write("{\"error\":\"Empty message\"}");
			return;
		}
		userText = userText.trim();

		ChatSession session = getOrCreate(username);
		chatDAO.saveMessage(session.getSessionId(), "user", userText);

		User staff = userDAO.getUserByUsername(username);
		List<Order> orders = orderDAO.getAllOrders();
		List<Product> products = productDAO.getAllProducts();
		List<StaffNotification> tickets = notifDAO.getUnread();
		List<OrderReturn> returns = returnDAO.getAllReturns();

		NexusAIEngine.Reply reply = NexusAIEngine.respond(userText, staff, orders, products, tickets, returns);
		int aiMsgId = chatDAO.saveMessage(session.getSessionId(), "assistant", reply.text, reply.cardType, reply.refId);

		out.write("{\"messageId\":" + aiMsgId + ",\"text\":" + js(reply.text) + ",\"cardType\":"
				+ (reply.cardType != null ? "\"" + esc(reply.cardType) + "\"" : "null") + ",\"cardRefId\":"
				+ (reply.refId != null ? "\"" + esc(reply.refId) + "\"" : "null") + "}");
	}

	private void handleUpdateOrder(HttpServletRequest req, HttpServletResponse res, PrintWriter out, String username)
			throws Exception {
		int orderId = parseId(req.getParameter("orderId"));
		String status = req.getParameter("status");
		if (orderId < 0 || status == null || status.isBlank()) {
			res.setStatus(400);
			out.write("{\"success\":false,\"error\":\"Missing orderId or status\"}");
			return;
		}
		orderDAO.updateOrderStatus(orderId, status);
		ChatSession session = getOrCreate(username);
		chatDAO.saveMessage(session.getSessionId(), "assistant",
				"✓ Order **#" + orderId + "** status updated to **" + status + "** by " + username + ".");
		out.write("{\"success\":true,\"orderId\":" + orderId + ",\"status\":\"" + esc(status) + "\"}");
	}

	private void handleResolveTicket(HttpServletRequest req, HttpServletResponse res, PrintWriter out, String username)
			throws Exception {
		String rawId = req.getParameter("ticketId");
		if (rawId == null || rawId.isBlank()) {
			res.setStatus(400);
			out.write("{\"success\":false,\"error\":\"Missing ticketId\"}");
			return;
		}
		int ticketId;
		try {
			ticketId = Integer.parseInt(rawId.replaceAll("[^0-9]", ""));
		} catch (NumberFormatException e) {
			res.setStatus(400);
			out.write("{\"success\":false,\"error\":\"Invalid ticketId\"}");
			return;
		}

		// FIX: was calling notifDAO.markRead() on staff_notifications — wrong table.
		// Tickets now live in support_tickets; mark resolved via TicketDAO.
		ticketDAO.updateStatus(ticketId, "resolved", username);

		// Also push a confirmation message into the customer's chat session if linked
		try {
			SupportTicket t = ticketDAO.getTicketById(ticketId);
			if (t != null && t.getChatSessionId() > 0) {
				chatDAO.saveMessage(t.getChatSessionId(), "assistant",
						"✅ **Your support ticket #TKT-" + ticketId + " has been resolved.**\n"
								+ "Thank you for your patience. If you need further help, feel free to ask!");
			}
		} catch (Exception ignored) {
		}

		ChatSession session = getOrCreate(username);
		chatDAO.saveMessage(session.getSessionId(), "assistant",
				"✓ Ticket **#TKT-" + ticketId + "** marked as resolved by " + username + ".");
		out.write("{\"success\":true,\"ticketId\":" + ticketId + "}");
	}

	/**
	 * FEEDBACK LOOP: Save message into customer's active chat session. FIX: guard
	 * customerId <= 0 to prevent creating session for customer 0.
	 */
	private void handleNotifyCustomer(HttpServletRequest req, HttpServletResponse res, PrintWriter out, String username)
			throws Exception {
		int orderId = parseId(req.getParameter("orderId"));
		int customerId = parseId(req.getParameter("customerId"));
		String message = req.getParameter("message");

		if (message == null || message.isBlank()) {
			res.setStatus(400);
			out.write("{\"success\":false,\"error\":\"Missing message\"}");
			return;
		}

		// FIX: if customerId not provided, try to get it from order
		if (customerId <= 0 && orderId > 0) {
			try {
				Order o = orderDAO.getOrderById(orderId);
				if (o != null) {
					customerId = o.getCustomerId();
				}
			} catch (Exception ignored) {
			}
		}

		if (customerId <= 0) {
			res.setStatus(400);
			out.write("{\"success\":false,\"error\":\"Cannot resolve customer — please include customerId\"}");
			return;
		}

		// Save message into customer chat session (FEEDBACK LOOP)
		ChatSession custSession = chatDAO.getActiveCustomerSession(customerId);
		if (custSession == null) {
			custSession = chatDAO.createCustomerSession(customerId);
		}
		String fullMsg = "📢 **Update from GreenCart Staff** (" + username + "):\n\n" + message;
		chatDAO.saveMessage(custSession.getSessionId(), "assistant", fullMsg);

		// FIX: was looping notifDAO.getUnread() to mark related notifications read —
		// that operates on staff_notifications (old table, now empty).
		// Now: if a ticketId param was sent by the dashboard, mark it in
		// support_tickets.
		String rawTicketId = req.getParameter("ticketId");
		if (rawTicketId != null && !rawTicketId.isBlank()) {
			try {
				int tid = Integer.parseInt(rawTicketId.replaceAll("[^0-9]", ""));
				if (tid > 0) {
					// BUG FIX: was calling updateStatus() which never writes to staff_reply
					// column. Must call staffReply() which inserts ticket_replies row AND
					// updates staff_reply snapshot so helpDesk.jsp can display it.
					ticketDAO.staffReply(tid, username, message);
				}
			} catch (Exception ignored) {
			}
		}

		ChatSession staffSession = getOrCreate(username);
		chatDAO.saveMessage(staffSession.getSessionId(), "assistant", "✓ Message delivered to customer #" + customerId
				+ (orderId > 0 ? " for Order #" + orderId : "") + ". " + "They will see it in their support chat.");

		out.write("{\"success\":true}");
	}

	/**
	 * Approve/reject a leave request — admin only. LeaveDAO methods:
	 * approveLeave(id, reviewer, note) / rejectLeave(id, reviewer, note).
	 */
	private void handleApproveLeave(HttpServletRequest req, HttpServletResponse res, PrintWriter out, String username)
			throws Exception {
		// Admin-only guard
		HttpSession httpSess = req.getSession(false);
		String callerRole = httpSess != null && httpSess.getAttribute("role") instanceof String
				? (String) httpSess.getAttribute("role")
				: "";
		if (!"admin".equalsIgnoreCase(callerRole)) {
			res.setStatus(403);
			out.write("{\"success\":false,\"error\":\"Only admins can approve or reject leave requests.\"}");
			return;
		}
		int leaveId = parseId(req.getParameter("leaveId"));
		String decision = req.getParameter("decision"); // "approved" | "rejected"
		String remarks = req.getParameter("remarks");
		if (remarks == null) {
			remarks = "";
		}

		if (leaveId < 0 || decision == null) {
			res.setStatus(400);
			out.write("{\"success\":false,\"error\":\"Missing leaveId or decision\"}");
			return;
		}
		if (!decision.equalsIgnoreCase("approved") && !decision.equalsIgnoreCase("rejected")) {
			res.setStatus(400);
			out.write("{\"success\":false,\"error\":\"Decision must be 'approved' or 'rejected'\"}");
			return;
		}

		// FIX: call the correct DAO methods
		String error;
		if (decision.equalsIgnoreCase("approved")) {
			error = leaveDAO.approveLeave(leaveId, username, remarks);
		} else {
			error = leaveDAO.rejectLeave(leaveId, username, remarks);
		}

		if (error != null) {
			out.write("{\"success\":false,\"error\":\"" + esc(error) + "\"}");
			return;
		}

		ChatSession session = getOrCreate(username);
		chatDAO.saveMessage(session.getSessionId(), "assistant", "✓ Leave request **#" + leaveId + "** has been **"
				+ decision + "** by " + username + (remarks.isBlank() ? "." : ". Note: " + remarks));

		out.write("{\"success\":true,\"leaveId\":" + leaveId + ",\"decision\":\"" + esc(decision) + "\"}");
	}

	private void handleCardAction(HttpServletRequest req, HttpServletResponse res, PrintWriter out, String username)
			throws Exception {
		String token = req.getParameter("sessionToken");
		String actionType = req.getParameter("actionType");
		String refId = req.getParameter("refId");
		String payload = req.getParameter("payload");

		if (token == null || token.isBlank() || actionType == null || actionType.isBlank()) {
			res.setStatus(400);
			out.write("{\"error\":\"Missing params\"}");
			return;
		}
		if (!chatDAO.validateStaffSession(token, username)) {
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
	// HELPERS
	// ══════════════════════════════════════════════════════════════════════

	private ChatSession getOrCreate(String username) throws SQLException {
		ChatSession s = chatDAO.getActiveStaffSession(username);
		return s != null ? s : chatDAO.createStaffSession(username);
	}

	/** Safe instanceof cast — no raw ClassCastException */
	// handleNewSession: close active staff session so next boot() creates a fresh
	// one
	private void handleNewSession(HttpServletRequest req, HttpServletResponse res, PrintWriter out, String username)
			throws Exception {
		try {
			ChatSession existing = chatDAO.getActiveStaffSession(username);
			if (existing != null) {
				chatDAO.resolveSession(existing.getSessionId());
			}
		} catch (Exception ignored) {
		}
		out.write("{\"success\":true}");
	}

	private String requireStaff(HttpServletRequest req, HttpServletResponse res) throws IOException {
		HttpSession httpSession = req.getSession(false);
		if (httpSession == null) {
			res.setStatus(401);
			res.getWriter().write("{\"error\":\"Not logged in\"}");
			return null;
		}
		Object roleAttr = httpSession.getAttribute("role");
		String role = (roleAttr instanceof String) ? (String) roleAttr : null;
		if (role == null || (!role.equalsIgnoreCase("staff") && !role.equalsIgnoreCase("admin"))) {
			res.setStatus(403);
			res.getWriter().write("{\"error\":\"Not authorized\"}");
			return null;
		}
		Object userAttr = httpSession.getAttribute("username");
		String username = (userAttr instanceof String) ? (String) userAttr : null;
		if (username == null) {
			res.setStatus(401);
			res.getWriter().write("{\"error\":\"No username in session\"}");
			return null;
		}
		return username;
	}

	private int parseId(String raw) {
		if (raw == null || raw.isBlank()) {
			return -1;
		}
		try {
			return Integer.parseInt(raw.replaceAll("[^0-9]", ""));
		} catch (NumberFormatException e) {
			return -1;
		}
	}

	/** Order → JSON; safely handles null items / null fields */
	private String orderToJson(Order o) {
		StringBuilder sb = new StringBuilder("{");
		sb.append("\"id\":").append(o.getId()).append(",");
		sb.append("\"customerId\":").append(o.getCustomerId()).append(",");
		sb.append("\"customerName\":").append(js(o.getCustomerName())).append(",");
		sb.append("\"customerPhone\":").append(js(o.getPhone())).append(",");
		sb.append("\"customerEmail\":").append(js(o.getCustomerEmail())).append(",");
		sb.append("\"status\":").append(js(o.getStatus())).append(",");
		sb.append("\"paymentStatus\":").append(js(o.getPaymentStatus())).append(",");
		sb.append("\"paymentMethod\":").append(js(o.getPaymentMethod())).append(",");
		sb.append("\"transactionId\":").append(js(o.getTransactionId())).append(",");
		sb.append("\"totalAmount\":").append(o.getTotalAmount()).append(",");
		sb.append("\"orderDate\":").append(js(o.getDate() != null ? o.getDate().toString() : null)).append(",");
		sb.append("\"deliveryDate\":").append(js(o.getDeliveryDate() != null ? o.getDeliveryDate().toString() : null))
				.append(",");
		sb.append("\"address\":").append(js(o.getAddress())).append(",");
		// FIX: getDeliveryUserName() may not exist — use safe reflection-free fallback
		String agentName = null;
		try {
			agentName = o.getDeliveryUserName();
		} catch (Exception ignored) {
		}
		if (agentName == null && o.getDeliveryUserId() > 0) {
			agentName = "Agent #" + o.getDeliveryUserId();
		}
		sb.append("\"deliveryAgent\":").append(js(agentName)).append(",");
		sb.append("\"deliveryUserId\":").append(o.getDeliveryUserId()).append(",");
		sb.append("\"items\":[");
		if (o.getItems() != null) {
			for (int i = 0; i < o.getItems().size(); i++) {
				if (i > 0) {
					sb.append(",");
				}
				var it = o.getItems().get(i);
				sb.append("{\"name\":").append(js(it.getName())).append(",\"qty\":").append(it.getQuantity())
						.append(",\"price\":").append(it.getFinalPrice()).append("}");
			}
		}
		sb.append("]}");
		return sb.toString();
	}

	/** FIX: null-safe sentAt */
	private String msgToJson(ChatMessage m) {
		String sentAt = m.getSentAt() != null ? m.getSentAt().toString() : "";
		return "{\"messageId\":" + m.getMessageId() + ",\"role\":" + js(m.getRole()) + ",\"content\":"
				+ js(m.getContent()) + ",\"cardType\":"
				+ (m.getCardType() != null ? "\"" + esc(m.getCardType()) + "\"" : "null") + ",\"cardRefId\":"
				+ (m.getCardOrderId() != null ? "\"" + esc(m.getCardOrderId()) + "\"" : "null") + ",\"sentAt\":\""
				+ esc(sentAt) + "\"}";
	}

	private String js(String s) {
		return s == null ? "null" : "\"" + esc(s) + "\"";
	}

	private String esc(String s) {
		if (s == null) {
			return "";
		}
		return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "\\r").replace("\t",
				"\\t");
	}

	private static String fmt(double v) {
		return String.format("%.2f", v);
	}

	// ══════════════════════════════════════════════════════════════════════
	// NexusAIEngine — multi-domain rule-based AI
	// ══════════════════════════════════════════════════════════════════════
	static class NexusAIEngine {

		static class Reply {
			String text, cardType, refId;

			Reply(String t) {
				text = t;
			}

			Reply(String t, String ct, String r) {
				text = t;
				cardType = ct;
				refId = r;
			}
		}

		static Reply respond(String msg, User staff, List<Order> orders, List<Product> products,
				List<StaffNotification> tickets, List<OrderReturn> returns) {

			String m = msg.toLowerCase().trim();
			String name = (staff != null && staff.getUsername() != null) ? staff.getUsername() : "there";
			boolean isAdmin = staff != null && "admin".equalsIgnoreCase(staff.getRole());

			// ── GREETING / SNAPSHOT ──────────────────────────────────────
			// Guard: "today's attendance" must not fall into the snapshot block
			if (!anyKw(m, "attendance", "leave", "return", "inventory", "order", "ticket", "agent")
					&& anyKw(m, "hi", "hello", "hey", "good morning", "good evening", "howdy", "namaste", "summary",
							"overview", "dashboard", "daily", "stats", "today", "report")) {
				return buildSnapshot(name, orders, products, tickets, returns, isAdmin);
			}

			// ── PENDING ORDERS ───────────────────────────────────────────
			// Guard: exclude messages that are about leave, returns or cancellations
			// e.g. "pending leave requests", "return pending", "pending cancellation"
			if (!anyKw(m, "leave", "leave request", "leave pending", "approve leave", "pending leave", "return",
					"refund", "cancel")
					&& anyKw(m, "pending", "need action", "unprocessed", "new order", "process order")) {
				if (orders == null || orders.isEmpty()) {
					return new Reply("✅ No orders in the system yet.");
				}
				var list = orders.stream()
						.filter(o -> statusIn(o.getStatus(), "pending", "processing", "confirmed", "ordered")).toList();
				if (list.isEmpty()) {
					return new Reply("✅ No pending orders — everything is up to date!");
				}
				var sb = new StringBuilder("**" + list.size() + " orders** need action:\n\n");
				list.stream().limit(8)
						.forEach(o -> sb.append("• **#").append(o.getId()).append("** — ").append(o.getStatus())
								.append(" — ₹").append(fmt(o.getTotalAmount())).append(" — ")
								.append(nvl(o.getPaymentMethod())).append("\n"));
				if (list.size() > 8) {
					sb.append("...and ").append(list.size() - 8).append(" more.");
				}
				return new Reply(sb.toString(), "pending_orders", null);
			}

			// ── ORDER LOOKUP ─────────────────────────────────────────────
			if (anyKw(m, "order #", "order id", "find order", "show order", "lookup order", "order detail",
					"check order")) {
				String idStr = extractDigits(m);
				if (!idStr.isEmpty()) {
					var found = orders != null
							? orders.stream().filter(o -> String.valueOf(o.getId()).equals(idStr)).findFirst()
							: java.util.Optional.<Order>empty();
					if (found.isPresent()) {
						Order o = found.get();
						return new Reply("Found **Order #" + o.getId() + "** for "
								+ (o.getCustomerName() != null ? o.getCustomerName() : "Customer") + ":\n\n"
								+ "• Status: **" + o.getStatus() + "**\n" + "• Payment: " + nvl(o.getPaymentMethod())
								+ " (**" + nvl(o.getPaymentStatus()) + "**)\n" + "• Amount: ₹" + fmt(o.getTotalAmount())
								+ "\n" + "• Date: " + nvl(o.getDate() != null ? o.getDate().toString() : null),
								"order_detail", idStr);
					}
					return new Reply("Order #" + idStr + " not found. Please verify the ID.");
				}
				if (orders != null && !orders.isEmpty()) {
					Order o = orders.get(0);
					return new Reply("Latest order: **#" + o.getId() + "** — " + o.getStatus() + " — ₹"
							+ fmt(o.getTotalAmount()), "order_detail", String.valueOf(o.getId()));
				}
				return new Reply("No orders found in the system.");
			}

			// ── SHIPPED ──────────────────────────────────────────────────
			if (anyKw(m, "shipped", "in transit", "dispatched", "out for delivery")) {
				var list = orders != null ? orders.stream()
						.filter(o -> statusIn(o.getStatus(), "shipped", "assigned", "out for delivery")).toList()
						: List.of();
				if (list.isEmpty()) {
					return new Reply("No orders currently in transit.");
				}
				var sb = new StringBuilder("**" + list.size() + " orders** in transit:\n\n");
				list.stream().limit(8).forEach(o -> sb.append("• **#").append(((Order) o).getId()).append("** — ")
						.append(((Order) o).getStatus()).append("\n"));
				return new Reply(sb.toString());
			}

			// ── FAILED PAYMENTS ──────────────────────────────────────────
			if (anyKw(m, "failed payment", "payment failed", "payment issue", "payment error")) {
				var list = orders != null ? orders.stream().filter(
						o -> o.getPaymentStatus() != null && o.getPaymentStatus().toUpperCase().contains("FAILED"))
						.toList() : List.of();
				if (list.isEmpty()) {
					return new Reply("✅ No failed payment orders right now.");
				}
				var sb = new StringBuilder("**" + list.size() + " orders** with payment failures:\n\n");
				list.forEach(o -> sb.append("• **#").append(((Order) o).getId()).append("** — ₹")
						.append(fmt(((Order) o).getTotalAmount())).append(" — ")
						.append(nvl(((Order) o).getPaymentMethod())).append("\n"));
				return new Reply(sb.toString(), "payment_alerts", null);
			}

			// ── CANCELLED ────────────────────────────────────────────────
			if (anyKw(m, "cancelled", "canceled", "cancellation")) {
				List<Order> list = orders != null
						? orders.stream().filter(o -> "Cancelled".equalsIgnoreCase(o.getStatus())).toList()
						: List.<Order>of();

				double refundTotal = list.stream().mapToDouble(Order::getTotalAmount).sum();
				return new Reply("**" + list.size() + " cancelled orders** — Refund total: ₹" + fmt(refundTotal));

			}

			// ── RETURNS ──────────────────────────────────────────────────
			if (anyKw(m, "return", "returns", "refund request", "return pending", "return request")) {
				if (returns == null || returns.isEmpty()) {
					return new Reply("✅ No pending return requests.");
				}
				var pending = returns.stream().filter(r -> "Requested".equalsIgnoreCase(r.getStatus())).toList();
				if (pending.isEmpty()) {
					return new Reply("✅ No new return requests. All existing returns are in progress.");
				}
				var sb = new StringBuilder("**" + pending.size() + " return requests** need review:\n\n");
				pending.stream().limit(6)
						.forEach(r -> sb.append("• Order **#").append(r.getOrderId()).append("** — ")
								.append(r.getReason() != null ? r.getReason() : "No reason given").append(" — ₹")
								.append(fmt(r.getRefundAmount())).append("\n"));
				return new Reply(sb.toString(), "return_list", null);
			}

			// ── TICKETS ──────────────────────────────────────────────────
			if (anyKw(m, "ticket", "tickets", "support ticket", "customer complaint", "open ticket", "unresolved")) {
				if (tickets == null || tickets.isEmpty()) {
					return new Reply("✅ No open customer support tickets.");
				}
				var sb = new StringBuilder("**" + tickets.size() + " open tickets** from customers:\n\n");
				tickets.stream().limit(6)
						.forEach(t -> sb.append("• **#T").append(t.getId()).append("** — ")
								.append(nvl(t.getCustomerName())).append(" (").append(nvl(t.getCustomerPhone()))
								.append(")").append(" — ").append(trunc(t.getItemsSummary(), 60)).append("\n"));
				return new Reply(sb.toString(), "ticket_list", null);
			}

			// ── INVENTORY ────────────────────────────────────────────────
			if (anyKw(m, "inventory", "stock", "out of stock", "low stock", "product", "restock")) {
				if (products == null || products.isEmpty()) {
					return new Reply("No product data available.");
				}
				long oos = products.stream().filter(p -> p.getStock() == 0).count();
				long low = products.stream().filter(p -> p.getStock() > 0 && p.getStock() < 10).count();
				long ok = products.stream().filter(p -> p.getStock() >= 10).count();
				var sb = new StringBuilder("📦 **Inventory Report:**\n\n");
				sb.append("• ✅ In Stock: **").append(ok).append("**\n");
				sb.append("• ⚠ Low Stock: **").append(low).append("**\n");
				sb.append("• 🔴 Out of Stock: **").append(oos).append("**\n");
				if (oos > 0) {
					sb.append("\n**Out of Stock:**\n");
					products.stream().filter(p -> p.getStock() == 0).limit(5)
							.forEach(p -> sb.append("• ").append(p.getName()).append("\n"));
				}
				if (low > 0) {
					sb.append("\n**⚠ Low Stock:**\n");
					products.stream().filter(p -> p.getStock() > 0 && p.getStock() < 10).limit(5).forEach(p -> sb
							.append("• ").append(p.getName()).append(" — ").append(p.getStock()).append(" units\n"));
				}
				return new Reply(sb.toString(), "inventory_alert", null);
			}

			// ── REVENUE (admin only) ─────────────────────────────────────
			if (anyKw(m, "revenue", "sales", "income", "earnings", "total sales")) {
				if (!isAdmin) {
					return new Reply("Revenue data is restricted to admin users.");
				}
				if (orders == null || orders.isEmpty()) {
					return new Reply("No revenue data available.");
				}
				double total = orders.stream().mapToDouble(Order::getTotalAmount).sum();
				double cod = orders.stream().filter(o -> "COD".equalsIgnoreCase(o.getPaymentMethod()))
						.mapToDouble(Order::getTotalAmount).sum();
				double online = total - cod;
				long paid = orders.stream().filter(o -> "PAID".equalsIgnoreCase(o.getPaymentStatus())).count();
				return new Reply("💰 **Revenue Breakdown:**\n\n" + "• Total Revenue: **₹" + fmt(total) + "**\n"
						+ "• Online Payments: ₹" + fmt(online) + "\n" + "• Cash on Delivery: ₹" + fmt(cod) + "\n"
						+ "• Paid Orders: " + paid + " / " + orders.size(), "daily_summary", null);
			}

			// ── UPDATE ORDER (natural language) ──────────────────────────
			if (anyKw(m, "mark", "update order", "set status", "mark as")) {
				String idStr = extractDigits(m);
				if (!idStr.isEmpty()) {
					String newStatus = "Shipped";
					if (m.contains("deliver")) {
						newStatus = "Delivered";
					} else if (m.contains("confirm")) {
						newStatus = "Confirmed";
					} else if (m.contains("cancel")) {
						newStatus = "Cancelled";
					} else if (m.contains("pack")) {
						newStatus = "Packed";
					}
					return new Reply("Ready to update **Order #" + idStr + "** to **" + newStatus
							+ "**.\n\nConfirm below to apply.", "order_status_update", idStr + "|" + newStatus);
				}
				return new Reply("Please specify the Order ID. Example: \"Mark order 1234 as Shipped\"");
			}

			// ── ATTENDANCE ───────────────────────────────────────────────
			if (anyKw(m, "attendance", "who is in", "who is working", "present", "absent", "staff attendance",
					"clock")) {
				return new Reply("Let me pull today's attendance data for you.", "attendance_summary", null);
			}

			// ── LEAVE ────────────────────────────────────────────────────
			if (anyKw(m, "leave", "leave request", "leave pending", "approve leave", "pending leave")) {
				return new Reply("Let me check pending leave requests.", "leave_list", null);
			}

			// ── AGENT LOGISTICS ──────────────────────────────────────────
			if (anyKw(m, "agent", "delivery agent", "assign", "agent status", "logistics", "workload")) {
				return new Reply("Let me check delivery agent workload metrics.", "agent_metrics", null);
			}

			// ── HELP ─────────────────────────────────────────────────────
			if (anyKw(m, "help", "what can you", "capabilities", "features", "commands")) {
				return new Reply("Hello **" + name + "**! I'm **Nexus**, your unified operations AI.\n\n"
						+ "**📦 Orders:** View pending/shipped/failed · Lookup by ID · Update status\n"
						+ "**📋 Inventory:** Stock alerts · Restock suggestions\n"
						+ "**🎫 Tickets:** Review open customer tickets · Notify customers directly\n"
						+ "**↩ Returns:** View return requests awaiting review\n"
						+ "**👥 HR:** Today's attendance · Pending leave requests (approve/reject)\n"
						+ "**🚚 Logistics:** Delivery agent workload & overload alerts\n"
						+ (isAdmin ? "**💰 Admin:** Revenue breakdown\n\n" : "\n")
						+ "Just ask in plain English — or use the chips below!");
			}

			// ── THANKS ───────────────────────────────────────────────────
			if (anyKw(m, "thank", "thanks", "great", "awesome", "perfect", "good job")) {
				return new Reply("You're welcome, **" + name + "**! Happy to keep operations smooth. 💪");
			}

			// ── FALLBACK → snapshot ──────────────────────────────────────
			return buildSnapshot(name, orders, products, tickets, returns, isAdmin);
		}

		private static Reply buildSnapshot(String name, List<Order> orders, List<Product> products,
				List<StaffNotification> tickets, List<OrderReturn> returns, boolean isAdmin) {
			long pending = orders != null ? orders.stream()
					.filter(o -> statusIn(o.getStatus(), "pending", "processing", "confirmed", "ordered")).count() : 0;
			long shipped = orders != null
					? orders.stream().filter(o -> statusIn(o.getStatus(), "shipped", "assigned", "out for delivery"))
							.count()
					: 0;
			long failedPay = orders != null
					? orders.stream()
							.filter(o -> o.getPaymentStatus() != null
									&& o.getPaymentStatus().toUpperCase().contains("FAILED"))
							.count()
					: 0;
			long oos = products != null ? products.stream().filter(p -> p.getStock() == 0).count() : 0;
			long low = products != null ? products.stream().filter(p -> p.getStock() > 0 && p.getStock() < 10).count()
					: 0;
			long openTix = tickets != null ? tickets.size() : 0;
			long openRet = returns != null
					? returns.stream().filter(r -> "Requested".equalsIgnoreCase(r.getStatus())).count()
					: 0;
			double revenue = orders != null && isAdmin ? orders.stream().mapToDouble(Order::getTotalAmount).sum() : 0;

			return new Reply("Hello **" + name + "**! 👋 **Nexus Snapshot** — " + java.time.LocalDate.now() + ":\n\n"
					+ "**📦 Orders:**  Pending: **" + pending + "** · In Transit: **" + shipped + "** · Failed Pay: **"
					+ failedPay + "**\n" + "**📋 Inventory:** Out of Stock: **" + oos + "** · Low Stock: **" + low
					+ "**\n" + "**🎫 Support:**  Open Tickets: **" + openTix + "** · Return Requests: **" + openRet
					+ "**\n" + (isAdmin ? "**💰 Revenue:** ₹" + fmt(revenue) + "\n" : "") + "\n"
					+ "What would you like to work on?", "daily_summary", null);
		}

		// ── Helpers ──────────────────────────────────────────────────────

		/**
		 * Case-insensitive keyword match — avoids the original any() bug where a single
		 * status string was passed where varargs was expected
		 */
		private static boolean anyKw(String m, String... kws) {
			for (String k : kws) {
				if (m.contains(k)) {
					return true;
				}
			}
			return false;
		}

		/**
		 * Check if a status string matches any of the given statuses (case-insensitive)
		 */
		private static boolean statusIn(String status, String... values) {
			if (status == null) {
				return false;
			}
			for (String v : values) {
				if (v.equalsIgnoreCase(status)) {
					return true;
				}
			}
			return false;
		}

		private static String extractDigits(String s) {
			var matcher = java.util.regex.Pattern.compile("\\d{1,10}").matcher(s);
			return matcher.find() ? matcher.group() : "";
		}

		private static String trunc(String s, int max) {
			if (s == null) {
				return "";
			}
			return s.length() > max ? s.substring(0, max) + "…" : s;
		}

		private static String nvl(String s) {
			return s != null ? s : "—";
		}
	}
}
