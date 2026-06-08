package com.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.SQLException;
import java.util.List;

import com.DAO.CustomerNotificationDAO;
import com.DAO.TicketDAO;
import com.util.SupportTicket;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

/**
 * TicketQueueServlet — Staff-facing REST endpoints for support_tickets.
 *
 * GET /TicketQueue → JSON list of all open tickets (for Nexus widget) POST
 * /TicketQueue?action=resolve → resolve ticket POST /TicketQueue?action=reply →
 * staff posts a reply (writes to ticket AND customer chat) POST
 * /TicketQueue?action=assign → assign ticket to staff user
 *
 * All requests require role=staff|admin in HttpSession.
 */
@WebServlet("/TicketQueue")
public class TicketQueueServlet extends HttpServlet {

	private TicketDAO ticketDAO;
	private com.DAO.ChatDAO chatDAO;
	private CustomerNotificationDAO nd;

	private static final java.util.logging.Logger log = java.util.logging.Logger
			.getLogger(TicketQueueServlet.class.getName());

	@Override
	public void init() throws ServletException {
		ticketDAO = new TicketDAO();
		chatDAO = new com.DAO.ChatDAO();
		nd = new CustomerNotificationDAO();
	}

	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {

		if (!isStaff(req, res)) {
			return;
		}
		res.setContentType("application/json;charset=UTF-8");
		PrintWriter out = res.getWriter();
		try {
			List<SupportTicket> tickets = ticketDAO.getOpenTickets();
			out.write(toJson(tickets));
		} catch (SQLException e) {
			res.setStatus(500);
			out.write("{\"error\":\"" + esc(e.getMessage()) + "\"}");
		}
	}

	@Override
	protected void doPost(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {

		String username = requireStaff(req, res);
		if (username == null) {
			return;
		}

		res.setContentType("application/json;charset=UTF-8");
		PrintWriter out = res.getWriter();

		String action = req.getParameter("action");
		if (action == null) {
			action = "resolve";
		}

		int ticketId = parseId(req.getParameter("ticketId"));
		if (ticketId < 0) {
			res.setStatus(400);
			out.write("{\"ok\":false,\"error\":\"Missing ticketId\"}");
			return;
		}

		try {
			switch (action) {
			case "resolve" -> {
				// Fetch ticket BEFORE updating so we have customer/subject data
				SupportTicket ticket = ticketDAO.getTicketById(ticketId);
				ticketDAO.updateStatus(ticketId, "resolved", username);

				// ── CUSTOMER NOTIFICATION: ticket resolved ────────────────────
				// Customer needs to know their issue has been addressed.
				// staffReply text (if any) is used as the resolution summary.
				if (ticket != null) {
					try {
						nd.notifyTicketResolved(ticket.getCustomerId(), ticketId, ticket.getSubject(),
								ticket.getStaffReply() // last staff message = resolution summary
						);
					} catch (Exception notifEx) {
						log.warning("Customer resolved-notification failed for ticket #" + ticketId + ": "
								+ notifEx.getMessage());
					}
				}
				out.write("{\"ok\":true,\"status\":\"resolved\"}");
			}
			case "reply" -> {
				String message = req.getParameter("message");
				if (message == null || message.isBlank()) {
					res.setStatus(400);
					out.write("{\"ok\":false,\"error\":\"Empty message\"}");
					return;
				}
				// Fetch ticket BEFORE the reply so we have customer/subject metadata
				SupportTicket ticket = ticketDAO.getTicketById(ticketId);
				ticketDAO.staffReply(ticketId, username, message.trim());

				// Also push message to customer chat session if ticket has one
				if (ticket != null && ticket.getChatSessionId() > 0) {
					chatDAO.saveMessage(ticket.getChatSessionId(), "assistant",
							"🎫 **Support Update (#TKT-" + ticketId + "):**\n" + message.trim());
				}

				// ── CUSTOMER NOTIFICATION: staff has replied ──────────────────
				// Most important notification — customer must be pulled back
				// to the ticket to see the staff's answer and respond.
				if (ticket != null) {
					try {
						nd.notifyTicketReply(ticket.getCustomerId(), ticketId, ticket.getSubject(), username, // staff
																												// display
																												// name
								message.trim() // preview snippet
						);
					} catch (Exception notifEx) {
						log.warning("Customer reply-notification failed for ticket #" + ticketId + ": "
								+ notifEx.getMessage());
					}
				}
				out.write("{\"ok\":true,\"status\":\"waiting_customer\"}");
			}
			case "assign" -> {
				// Fetch ticket BEFORE updating for customer notification
				SupportTicket ticket = ticketDAO.getTicketById(ticketId);
				ticketDAO.updateStatus(ticketId, "in_progress", username);

				// ── CUSTOMER NOTIFICATION: ticket is now being worked on ───────
				// Tells the customer their request is no longer queued but actively
				// being handled — reduces anxiety / repeat contacts.
				if (ticket != null) {
					try {
						nd.notifyTicketUpdated(ticket.getCustomerId(), ticketId, ticket.getSubject(), "in_progress",
								username + " has picked up your ticket and is working on it.");
					} catch (Exception notifEx) {
						log.warning("Customer assign-notification failed for ticket #" + ticketId + ": "
								+ notifEx.getMessage());
					}
				}
				out.write("{\"ok\":true,\"assignedTo\":\"" + esc(username) + "\"}");
			}
			default -> {
				res.setStatus(400);
				out.write("{\"ok\":false,\"error\":\"Unknown action\"}");
			}
			}
		} catch (SQLException e) {
			res.setStatus(500);
			out.write("{\"ok\":false,\"error\":\"" + esc(e.getMessage()) + "\"}");
		}
	}

	// ══════════════════════════════════════════════════════
	// HELPERS
	// ══════════════════════════════════════════════════════

	private boolean isStaff(HttpServletRequest req, HttpServletResponse res) throws IOException {
		return requireStaff(req, res) != null;
	}

	private String requireStaff(HttpServletRequest req, HttpServletResponse res) throws IOException {
		Object role = req.getSession(false) != null ? req.getSession(false).getAttribute("role") : null;
		Object name = req.getSession(false) != null ? req.getSession(false).getAttribute("username") : null;
		if (!(role instanceof String)
				|| (!"staff".equalsIgnoreCase((String) role) && !"admin".equalsIgnoreCase((String) role))) {
			res.setStatus(401);
			res.getWriter().write("{\"error\":\"Unauthorized\"}");
			return null;
		}
		return name instanceof String ? (String) name : "staff";
	}

	private int parseId(String s) {
		if (s == null) {
			return -1;
		}
		try {
			return Integer.parseInt(s.trim());
		} catch (NumberFormatException e) {
			return -1;
		}
	}

	private String esc(String s) {
		if (s == null) {
			return "";
		}
		return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "\\r");
	}

	private String toJson(List<SupportTicket> list) {
		StringBuilder sb = new StringBuilder("{\"tickets\":[");
		for (int i = 0; i < list.size(); i++) {
			if (i > 0) {
				sb.append(",");
			}
			SupportTicket t = list.get(i);
			sb.append("{").append("\"ticketId\":").append(t.getTicketId()).append(",").append("\"customerId\":")
					.append(t.getCustomerId()).append(",").append("\"customerName\":\"")
					.append(esc(t.getCustomerName())).append("\",").append("\"customerEmail\":\"")
					.append(esc(t.getCustomerEmail())).append("\",").append("\"customerPhone\":\"")
					.append(esc(t.getCustomerPhone())).append("\",").append("\"category\":\"")
					.append(esc(t.getCategoryLabel())).append("\",").append("\"subject\":\"")
					.append(esc(t.getSubject())).append("\",").append("\"description\":\"")
					.append(esc(t.getDescription())).append("\",").append("\"status\":\"")
					.append(esc(t.getStatusLabel())).append("\",").append("\"priority\":\"")
					.append(esc(t.getPriority())).append("\",").append("\"assignedTo\":")
					.append(t.getAssignedTo() != null ? "\"" + esc(t.getAssignedTo()) + "\"" : "null").append(",")
					.append("\"refOrderId\":").append(t.getRefOrderId()).append(",").append("\"chatSessionId\":")
					.append(t.getChatSessionId()).append(",").append("\"createdAt\":\"")
					.append(t.getCreatedAt() != null ? t.getCreatedAt().toString() : "").append("\"").append("}");
		}
		sb.append("]}");
		return sb.toString();
	}
}
