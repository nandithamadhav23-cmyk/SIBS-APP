package com.servlet;

import java.io.IOException;
import java.util.List;
import java.util.logging.Logger;

import com.DAO.CustomerNotificationDAO;
import com.util.CustomerNotification;

import jakarta.servlet.RequestDispatcher;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

/**
 * CustomerNotificationServlet
 * ─────────────────────────────────────────────────────────────────────────────
 * Handles all customer notification operations.
 *
 * GET (no action) — full notification centre page → customerNotifications.jsp
 * GET ?action=count — returns plain-text unread count (badge polling) POST
 * ?action=markRead — marks one notification read; redirects if actionUrl set
 * POST ?action=markAllRead — marks all read for this customer POST
 * ?action=dismiss — soft-deletes one notification POST ?action=delete —
 * hard-deletes one notification
 *
 * URL: /CustomerNotifications
 */
@WebServlet("/CustomerNotifications")
public class CustomerNotificationServlet extends HttpServlet {

	private static final long serialVersionUID = 1L;
	private static final Logger log = Logger.getLogger(CustomerNotificationServlet.class.getName());

	private final CustomerNotificationDAO dao = new CustomerNotificationDAO();

	@Override
	public void init() throws ServletException {
		// Create table if it doesn't exist — zero-config bootstrap
		dao.ensureTable();
	}

	// ── GET ──────────────────────────────────────────────────────────────────

	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {

		int customerId = getCustomerId(req, resp);
		if (customerId < 0) {
			return;
		}

		String action = req.getParameter("action");

		// ── Badge polling endpoint (lightweight) ──────────────────────────
		if ("count".equals(action)) {
			resp.setContentType("text/plain;charset=UTF-8");
			resp.getWriter().write(String.valueOf(dao.countUnread(customerId)));
			return;
		}

		// ── Full notification centre ──────────────────────────────────────

		List<CustomerNotification> notifications = dao.getAll(customerId);
		long unreadCount = notifications.stream().filter(n -> !n.isRead()).count();

		req.setAttribute("notifications", notifications);
		req.setAttribute("unreadCount", unreadCount);

		RequestDispatcher rd = req.getRequestDispatcher("customerNotifications.jsp");
		rd.forward(req, resp);
	}

	// ── POST ─────────────────────────────────────────────────────────────────

	@Override
	protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {

		int customerId = getCustomerId(req, resp);
		if (customerId < 0) {
			return;
		}

		String action = req.getParameter("action");
		String idStr = req.getParameter("id");

		try {
			switch (action == null ? "" : action) {

			case "markRead" -> {
				int id = parseInt(idStr);
				dao.markRead(id);
				// Deep-link: redirect to the related page if actionUrl is set
				CustomerNotification n = dao.getById(id);
				if (n != null && n.getActionUrl() != null && !n.getActionUrl().isBlank()) {
					resp.sendRedirect(n.getActionUrl());
					return;
				}
			}

			case "markAllRead" -> dao.markAllRead(customerId);

			case "dismiss" -> {
				int id = parseInt(idStr);
				dao.dismiss(id);
			}

			case "delete" -> {
				int id = parseInt(idStr);
				dao.delete(id);
			}

			default -> {
				/* unknown action — fall through to redirect */ }
			}

		} catch (NumberFormatException e) {
			throw new ServletException("Invalid notification id: " + idStr, e);
		}

		resp.sendRedirect("CustomerNotifications");
	}

	// ── Helpers ───────────────────────────────────────────────────────────────

	/**
	 * Extracts customerId from session; redirects to login on failure and returns
	 * -1 so the caller can return immediately.
	 */
	private int getCustomerId(HttpServletRequest req, HttpServletResponse resp) throws IOException {
		HttpSession session = req.getSession(false);
		if (session == null || session.getAttribute("customerId") == null) {
			resp.sendRedirect("CustomerLogin.jsp");
			return -1;
		}
		return (int) session.getAttribute("customerId");
	}

	private int parseInt(String s) {
		return Integer.parseInt(s == null ? "0" : s.trim());
	}
}
