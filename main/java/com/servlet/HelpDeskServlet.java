package com.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.SQLException;
import java.util.List;

import com.DAO.ChatDAO;
import com.DAO.CustomerNotificationDAO;
import com.DAO.StaffNotificationDAO;
import com.DAO.TicketDAO;
import com.util.Customer;
import com.util.SupportTicket;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

/**
 * HelpDeskServlet — Customer-facing help desk endpoints.
 *
 * GET /HelpDesk → forward to helpDesk.jsp (My Requests list) POST
 * /HelpDesk?action=submit → create new support ticket (Contact Us form) POST
 * /HelpDesk?action=reply → customer adds a reply to an existing ticket GET
 * /HelpDesk?action=api → JSON list of customer's tickets (for AJAX refresh)
 *
 * Auth: requires "customerId" in HttpSession — redirects to CustomerLogin.jsp
 * if absent.
 */
@WebServlet("/HelpDesk")
public class HelpDeskServlet extends HttpServlet {

	private static final java.util.logging.Logger log = java.util.logging.Logger
			.getLogger(HelpDeskServlet.class.getName());

	private TicketDAO ticketDAO;
	private ChatDAO chatDAO;
	private CustomerNotificationDAO nd;
	private StaffNotificationDAO staffNotifDAO;

	@Override
	public void init() throws ServletException {
		ticketDAO = new TicketDAO();
		chatDAO = new ChatDAO();
		nd = new CustomerNotificationDAO();
		staffNotifDAO = new StaffNotificationDAO();
	}

	// ══════════════════════════════════════════════════════
	// GET
	// ══════════════════════════════════════════════════════
	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {

		int customerId = resolveCustomer(req, res);
		if (customerId < 0) {
			return;
		}

		String action = req.getParameter("action");

		if ("api".equals(action)) {
			// JSON response for the chat widget to embed ticket list
			res.setContentType("application/json;charset=UTF-8");
			PrintWriter out = res.getWriter();
			try {
				List<SupportTicket> tickets = ticketDAO.getTicketsByCustomer(customerId);
				out.write(ticketsToJson(tickets));
			} catch (SQLException e) {
				res.setStatus(500);
				out.write("{\"error\":\"" + escJson(e.getMessage()) + "\"}");
			}
			return;
		}

		// Default: full help desk page
		try {
			List<SupportTicket> tickets = ticketDAO.getTicketsByCustomer(customerId);
			int openCount = (int) tickets.stream().filter(t -> !t.isResolved()).count();

			req.setAttribute("tickets", tickets);
			req.setAttribute("openCount", openCount);
			req.getRequestDispatcher("helpDesk.jsp").forward(req, res);

		} catch (SQLException e) {
			throw new ServletException("Failed to load tickets", e);
		}
	}

	// ══════════════════════════════════════════════════════
	// POST
	// ══════════════════════════════════════════════════════
	@Override
	protected void doPost(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {

		int customerId = resolveCustomer(req, res);
		if (customerId < 0) {
			return;
		}

		String action = req.getParameter("action");
		if (action == null) {
			action = "submit";
		}

		switch (action) {
		case "submit" -> handleSubmit(req, res, customerId);
		case "reply" -> handleReply(req, res, customerId);
		default -> res.sendRedirect("HelpDesk");
		}
	}

	// ──────────────────────────────────────────────────────
	// submit — Contact Us form
	// ──────────────────────────────────────────────────────
	private void handleSubmit(HttpServletRequest req, HttpServletResponse res, int customerId)
			throws IOException, ServletException {

		String category = sanitise(req.getParameter("category"), "other");
		String subject = sanitise(req.getParameter("subject"), "Support request");
		String description = sanitise(req.getParameter("description"), "");
		String orderStr = req.getParameter("orderId");
		Integer orderId = null;
		try {
			if (orderStr != null && !orderStr.isBlank()) {
				orderId = Integer.parseInt(orderStr.trim());
			}
		} catch (NumberFormatException ignored) {
		}

		if (description.isBlank()) {
			req.setAttribute("error", "Please describe your issue before submitting.");
			doGet(req, res);
			return;
		}

		try {
			// BUG FIX: resolve the customer's active chat session so the
			// support_tickets row is linked → staff replies flow back to
			// the customer's Kira chat widget via TicketQueueServlet.
			Integer chatSessionId = null;
			try {
				com.util.ChatSession activeSession = chatDAO.getActiveCustomerSession(customerId);
				if (activeSession != null) {
					chatSessionId = activeSession.getSessionId();
				}
			} catch (Exception ignored) {
				/* non-fatal — ticket still created */ }

			int ticketId = ticketDAO.createTicket(customerId, chatSessionId, category, subject, description, orderId,
					"normal");

			// ── NOTIFICATION: staff must see the new ticket immediately ──────
			// Sends a structured StaffNotification so the ticket appears in the
			// Nexus staff panel with a SUPPORT badge and the correct customer info.
			try {
				Customer c = (Customer) req.getSession().getAttribute("customer");
				String custName = c != null ? c.getName() : "Customer #" + customerId;
				String custEmail = c != null ? c.getEmail() : "";
				String custPhone = c != null ? c.getPhone() : "";
				String catLabel = new com.util.SupportTicket() {
					{
						setCategory(category);
					}
				}.getCategoryLabel();

				staffNotifDAO.insertTicket(ticketId, customerId, custName, custEmail, custPhone, subject, description,
						"normal", catLabel, "🎫 New support ticket from " + custName + ": " + subject + ""
								+ "— Review & reply at Support → Ticket Queue. " + "(Ref: #TKT-" + ticketId + ")");
			} catch (Exception notifEx) {
				log.warning("Staff ticket notification failed for ticket #" + ticketId + ": " + notifEx.getMessage());
			}

			// ── NOTIFICATION: confirm to customer that ticket is received ────
			// Assures them their request is logged and a response is coming.
			try {
				nd.notifyTicketRaised(customerId, ticketId, subject, category);
			} catch (Exception notifEx) {
				log.warning("Customer ticket-raised notification failed for ticket #" + ticketId + ": "
						+ notifEx.getMessage());
			}

			res.sendRedirect("HelpDesk?submitted=" + ticketId);
		} catch (SQLException e) {
			throw new ServletException("Failed to create ticket", e);
		}
	}

	// ──────────────────────────────────────────────────────
	// reply — customer adds message to existing ticket
	// ──────────────────────────────────────────────────────
	private void handleReply(HttpServletRequest req, HttpServletResponse res, int customerId)
			throws IOException, ServletException {

		String ticketStr = req.getParameter("ticketId");
		String message = sanitise(req.getParameter("message"), "");
		if (ticketStr == null || message.isBlank()) {
			res.sendRedirect("HelpDesk");
			return;
		}

		try {
			int ticketId = Integer.parseInt(ticketStr.trim());
			SupportTicket t = ticketDAO.getTicketById(ticketId);
			if (t == null || t.getCustomerId() != customerId) {
				res.sendRedirect("HelpDesk");
				return;
			}
			// Get customer name from session
			Customer c = (Customer) req.getSession().getAttribute("customer");
			String name = (c != null && c.getName() != null) ? c.getName() : "Customer";

			// BUG FIX: was calling staffReply() which hardcodes sender_role='staff'
			// and sets status='waiting_customer'. Must use customerReply() so
			// sender_role='customer' is stored correctly and status → 'open'.
			ticketDAO.customerReply(ticketId, name, message);

			// ── NOTIFICATION: alert staff that the customer has replied ──────
			// Status is flipped to 'open' by customerReply() above.
			// Staff notification ensures it re-surfaces in the ticket queue.
			try {
				String subject = t.getSubject() != null ? t.getSubject() : "Support ticket";
				com.util.Customer cust = (com.util.Customer) req.getSession().getAttribute("customer");
				String custEmail = cust != null ? cust.getEmail() : "";
				String custPhone = cust != null ? cust.getPhone() : "";
				String catLabel = t.getCategoryLabel();

				staffNotifDAO.insertTicket(ticketId, customerId, name, custEmail, custPhone, subject, message,
						t.getPriority() != null ? t.getPriority() : "normal", catLabel,
						"💬 Customer " + name + " replied on ticket #TKT-" + ticketId + " (" + subject
								+ "). Re-opened — please respond.");
			} catch (Exception notifEx) {
				log.warning("Staff reply-notification failed for ticket #" + ticketId + ": " + notifEx.getMessage());
			}

			// BUG FIX: push the customer's follow-up into the linked chat
			// session so staff can see it in the Nexus widget (feedback loop).
			if (t.getChatSessionId() > 0) {
				try {
					chatDAO.saveMessage(t.getChatSessionId(), "user",
							"📋 **Help Desk reply from " + name + " (#TKT-" + ticketId + "):**\n" + message);
				} catch (Exception ignored) {
					/* non-fatal */ }
			}

			res.sendRedirect("HelpDesk?replied=" + ticketId);

		} catch (NumberFormatException | SQLException e) {
			throw new ServletException("Reply failed", e);
		}
	}

	// ══════════════════════════════════════════════════════
	// HELPERS
	// ══════════════════════════════════════════════════════

	private int resolveCustomer(HttpServletRequest req, HttpServletResponse res) throws IOException {
		Object attr = req.getSession(false) != null ? req.getSession(false).getAttribute("customerId") : null;
		if (!(attr instanceof Integer)) {
			res.sendRedirect("CustomerLogin.jsp");
			return -1;
		}
		return (Integer) attr;
	}

	private String sanitise(String val, String fallback) {
		if (val == null || val.isBlank()) {
			return fallback;
		}
		return val.trim().substring(0, Math.min(val.trim().length(), 2000));
	}

	private String escJson(String s) {
		if (s == null) {
			return "";
		}
		return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "\\r");
	}

	private String ticketsToJson(List<SupportTicket> tickets) {
		StringBuilder sb = new StringBuilder("[");
		for (int i = 0; i < tickets.size(); i++) {
			if (i > 0) {
				sb.append(",");
			}
			SupportTicket t = tickets.get(i);
			sb.append("{").append("\"ticketId\":").append(t.getTicketId()).append(",").append("\"category\":\"")
					.append(escJson(t.getCategoryLabel())).append("\",").append("\"subject\":\"")
					.append(escJson(t.getSubject())).append("\",").append("\"status\":\"")
					.append(escJson(t.getStatusLabel())).append("\",").append("\"statusCss\":\"")
					.append(escJson(t.getStatusCss())).append("\",").append("\"staffReply\":")
					.append(t.getStaffReply() != null ? "\"" + escJson(t.getStaffReply()) + "\"" : "null").append(",")
					.append("\"createdAt\":\"").append(t.getCreatedAt() != null ? t.getCreatedAt().toString() : "")
					.append("\"").append("}");
		}
		sb.append("]");
		return sb.toString();
	}
}
