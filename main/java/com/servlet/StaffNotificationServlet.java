package com.servlet;

import java.io.IOException;
import java.util.List;

import com.DAO.StaffNotificationDAO;
import com.util.StaffNotification;

import jakarta.servlet.RequestDispatcher;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@WebServlet("/StaffNotifications")
public class StaffNotificationServlet extends HttpServlet {

	private static final long serialVersionUID = 1L;
	private final StaffNotificationDAO dao = new StaffNotificationDAO();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		// Lightweight polling endpoint used by the auto-refresh badge JS
		if ("true".equals(request.getParameter("count"))) {
			response.setContentType("text/plain;charset=UTF-8");
			response.getWriter().write(String.valueOf(dao.countUnread()));
			return;
		}

		// Full notification center page
		List<StaffNotification> notifications = dao.getAll();
		long unreadCount = notifications.stream().filter(n -> !n.isRead()).count();

		request.setAttribute("notifications", notifications);
		request.setAttribute("unreadCount", unreadCount);

		RequestDispatcher rd = request.getRequestDispatcher("StaffNotifications.jsp");
		rd.forward(request, response);
	}

	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		String action = request.getParameter("action");
		String idStr = request.getParameter("id");

		try {
			switch (action == null ? "" : action) {

			case "markRead" -> {
				int id = Integer.parseInt(idStr);
				dao.markRead(id);
				// Also navigate to the related order on the dashboard
				StaffNotification n = dao.getById(id);
				if (n != null) {
					response.sendRedirect("OrdersDashboard?action=view&orderId=" + n.getOrderId());
					return;
				}
			}

			case "markAllRead" -> dao.markAllRead();

			case "dismiss" -> {
				int id = Integer.parseInt(idStr);
				dao.dismiss(id);
			}

			case "delete" -> {
				int id = Integer.parseInt(idStr);
				dao.delete(id);
			}

			default -> {
				/* unknown action — just redirect */ }
			}

		} catch (NumberFormatException e) {
			throw new ServletException("Invalid notification id: " + idStr, e);
		}

		response.sendRedirect("StaffNotifications");
	}
}
