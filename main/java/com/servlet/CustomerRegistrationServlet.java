package com.servlet;

import java.io.IOException;
import java.sql.SQLException;

import com.DAO.CustomerDAO;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@WebServlet("/CustRegister")
public class CustomerRegistrationServlet extends HttpServlet {
	private CustomerDAO dao = new CustomerDAO();

	@Override
	protected void doPost(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
		String name = req.getParameter("name");
		String email = req.getParameter("email");
		String phone = req.getParameter("countryCode") + req.getParameter("phone").trim();
		String landmark_street = req.getParameter("landmark_street");
		String city = req.getParameter("city");
		String district = req.getParameter("district");
		String state = req.getParameter("state");
		String country = req.getParameter("country");

		String pincode = req.getParameter("pincode");
		String password = req.getParameter("password");
		String gender = req.getParameter("gender");
		String confirmPassword = req.getParameter("confirmPassword");

		try {
			if (!password.equals(confirmPassword)) {
				res.sendRedirect("CustomerRegistration.jsp?error=invalidPassword");
				return;
			}
			if (dao.customerExists(email)) {
				res.sendRedirect("CustomerRegistration.jsp?error=exists");
				return;
			}

			dao.registerCustomer(name, email, phone, landmark_street, city, district, state, country, pincode, gender,
					password);
			res.sendRedirect("CustomerLogin.jsp?success=registered");
		} catch (SQLException e) {
			e.printStackTrace();
			res.sendRedirect("CustomerRegistration.jsp?error=failed");
		}
	}
}
