package com.servlet;

import java.io.IOException;
import java.sql.SQLException;

import com.DAO.AdminNotificationDAO;
import com.DAO.UserDAO;
import com.util.User;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/login")
public class LoginServlet extends HttpServlet {
	private final AdminNotificationDAO adao = new AdminNotificationDAO();
	/**
	 * 
	 */
	private static final long serialVersionUID = 1646442316457377506L;
	private final UserDAO dao = new UserDAO();

	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		System.out.println("+++++ Login Servlet +++++");

		String username = request.getParameter("username");
		String password = request.getParameter("password");

		String status = dao.getUserStatus(username);
		User user = dao.getUserByUsername(username);

		if (!"active".equalsIgnoreCase(status)) {
			request.setAttribute("error", "🚫 Your account is inactive. Contact admin.");
			request.getRequestDispatcher("index.jsp").forward(request, response);
			return;
		}
		if (dao.validateLogin(username, password)) {
			String role = dao.getUserRole(username);

			HttpSession session = request.getSession();

			java.sql.Timestamp now = new java.sql.Timestamp(System.currentTimeMillis());
			try {
				dao.updateLastLogin(user.getUid(), now);
			} catch (SQLException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
			user.setLastLogin(now);
			session.setAttribute("username", username);
			session.setAttribute("role", role);
			session.setAttribute("user", user);
			System.out.println("Role set in session: " + role);

			if ("admin".equalsIgnoreCase(role)) {
				String source = request.getParameter("source"); // hidden field in modal
				session.setAttribute("success", "Login successful ! Admin!");
				response.sendRedirect("adminDashboard");

			}

			else {
				session.setAttribute("success", "Login successful !");
				response.sendRedirect(request.getContextPath() + "/UserDashboardServlet");
			}

			session.setAttribute("loggedIn", true);

		} else {
			request.setAttribute("error", "Invalid credentials. Please try again.");
			request.getRequestDispatcher("index.jsp").forward(request, response);
		}
	}

	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
		// Fetch unread notification count
		int unreadCount = adao.getUnreadCount();
		req.setAttribute("unreadCount", unreadCount);

		// Forward to dashboard JSP
		req.getRequestDispatcher("adminDashboard").forward(req, res);
	}
}
