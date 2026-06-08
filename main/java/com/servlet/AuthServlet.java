package com.servlet;

import java.io.IOException;

import com.DAO.UserDAO;
import com.util.OTPUtil;
import com.util.User;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/auth")
public class AuthServlet extends HttpServlet {

	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		String action = request.getParameter("action"); // "loginEmail", "loginMobile", "forgotPassword"
		HttpSession session = request.getSession();
		UserDAO dao = new UserDAO();

		// Generate OTP
		String otp = OTPUtil.generateOTP();
		session.setAttribute("otp", otp);
		session.setAttribute("otpExpiry", System.currentTimeMillis() + 5 * 60 * 1000); // 5 min expiry

		if ("loginEmail".equals(action)) {
			String email = request.getParameter("email");
			User user = dao.getUserByIdentifier(email);
			session.setAttribute("userDetails", user);

			// Normally you’d send OTP via email here, but we skip that
			System.out.println("Generated OTP for email login: " + otp);

			response.sendRedirect("verifyOtp.jsp");

		} else if ("loginMobile".equals(action)) {
			String mobile = request.getParameter("mobile");
			User user = dao.getUserByIdentifier(mobile);
			session.setAttribute("userDetails", user);

			// Normally you’d send OTP via SMS here, but we skip that
			System.out.println("Generated OTP for mobile login: " + otp);

			response.sendRedirect("verifyOtp.jsp");

		} else if ("forgotPassword".equals(action)) {
			String email = request.getParameter("email");
			User user = dao.getUserByIdentifier(email);
			session.setAttribute("userDetails", user);

			System.out.println("Generated OTP for password reset: " + otp);

			response.sendRedirect("resetPassword.jsp");
		}
	}
}
