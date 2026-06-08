package com.servlet;

import java.io.IOException;
import java.sql.Connection;
import java.util.logging.Level;
import java.util.logging.Logger;

import com.DAO.DeliveryPersonDAO;
import com.util.DBConnection;
import com.util.User;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/DeliveryLogoutServlet")
public class DeliveryLogoutServlet extends HttpServlet {

	private static final long serialVersionUID = 1L;
	private static final Logger log = Logger.getLogger(DeliveryLogoutServlet.class.getName());

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		doPost(request, response);
	}

	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		HttpSession session = request.getSession(false);
		log.info("in lougout servlet");
		if (session != null) {
			User user = (User) session.getAttribute("deliveryUser");

			if (user != null) {
				// Set agent status to "inactive" in DB on logout so they
				// don't appear available for order assignment while offline.
				try (Connection conn = DBConnection.getConnection()) {
					DeliveryPersonDAO dao = new DeliveryPersonDAO(conn);
					dao.updateUserStatus(user.getUid(), "inactive");
					log.info("Agent #" + user.getUid() + " (" + user.getUsername() + ") logged out → inactive");
				} catch (Exception e) {
					// Non-fatal: session is still invalidated even if DB update fails
					log.log(Level.WARNING,
							"Could not set agent #" + user.getUid() + " inactive on logout: " + e.getMessage());
				}
			}

			session.invalidate();
		}
		// Clear any cached page from browser so Back button doesn't restore the portal
		response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
		response.setHeader("Pragma", "no-cache");
		response.setDateHeader("Expires", 0);

		response.sendRedirect(request.getContextPath() + "/deliveryLogin.jsp");
	}
}