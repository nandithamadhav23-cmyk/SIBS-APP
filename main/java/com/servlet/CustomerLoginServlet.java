package com.servlet;

import java.io.IOException;
import java.sql.SQLException;

import com.DAO.CustomerDAO;
import com.util.Customer;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/CustLogin")
public class CustomerLoginServlet extends HttpServlet {
	private CustomerDAO dao = new CustomerDAO();

	@Override
	protected void doPost(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
		String email = req.getParameter("email");
		String password = req.getParameter("password");

		try {
			int customerId = dao.validateLogin(email, password);

			Customer customer = (Customer) req.getSession().getAttribute("customer");
			if (customerId > 0) {
				HttpSession session = req.getSession();

				customer = dao.getProfile(customerId);
				session.setAttribute("customerId", customerId);

				session.setAttribute("customer", customer);
				session.setAttribute("username", dao.getProfile(customerId).getName());

				String role = dao.getProfile(customerId).getRole(); // assuming getRole() exists
				session.setAttribute("role", role);

				session.setAttribute("loggedIn", true);
				res.sendRedirect("customerDashboard.jsp");
				System.out.println("User logged in, session attribute set: " + session.getAttribute("loggedIn"));
			} else {
				res.sendRedirect("CustomerLogin.jsp?error=invalid");
			}
		} catch (SQLException e) {
			e.printStackTrace();

			res.sendRedirect("CustomerLogin.jsp?error=failed");
		}
	}
}
