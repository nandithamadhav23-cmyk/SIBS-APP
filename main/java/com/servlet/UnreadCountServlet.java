package com.servlet;

import java.io.IOException;

import com.DAO.AdminNotificationDAO;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@WebServlet("/UnreadCountServlet")
public class UnreadCountServlet extends HttpServlet {
	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;
	private final AdminNotificationDAO dao = new AdminNotificationDAO();

	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
		int unreadCount = dao.getUnreadCount();

		// Return plain text (easy for AJAX to consume)
		res.setContentType("text/plain");
		res.getWriter().write(String.valueOf(unreadCount));
	}
}
