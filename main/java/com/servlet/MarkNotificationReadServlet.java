package com.servlet;

import java.io.IOException;

import com.DAO.AdminNotificationDAO;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@WebServlet("/MarkNotificationReadServlet")
public class MarkNotificationReadServlet extends HttpServlet {
	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;
	private final AdminNotificationDAO dao = new AdminNotificationDAO();

	@Override
	protected void doPost(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
		int id = Integer.parseInt(req.getParameter("id"));
		dao.markAsRead(id);
		res.sendRedirect("AdminNotificationServlet");
	}
}
