package com.servlet;

import java.io.IOException;
import java.util.List;

import com.DAO.AdminNotificationDAO;
import com.util.AdminNotification;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@WebServlet("/AdminNotificationServlet")
public class AdminNotificationServlet extends HttpServlet {
	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;
	private final AdminNotificationDAO dao = new AdminNotificationDAO();

	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
		List<AdminNotification> notifications = dao.getUnreadNotifications();
		req.setAttribute("notifications", notifications);
		req.setAttribute("unreadCount", notifications.size());
		req.getRequestDispatcher("AdminNotification.jsp").forward(req, res);
	}
}
