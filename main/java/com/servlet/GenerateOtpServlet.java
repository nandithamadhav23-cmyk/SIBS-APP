package com.servlet;

import java.io.IOException;
import java.util.logging.Logger;

import com.DAO.OrderDAO;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/GenerateOtpServlet")
public class GenerateOtpServlet extends HttpServlet {
	private static final long serialVersionUID = 1L;
	// BUG FIX: was Logger.getLogger(PaymentServlet.class.getName()) — wrong class
	// reference
	private static final Logger log = Logger.getLogger(GenerateOtpServlet.class.getName());

	private OrderDAO orderDAO = new OrderDAO();

	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		int orderId = Integer.parseInt(request.getParameter("orderId"));

		// Generate 6-digit OTP
		int otp = (int) (Math.random() * 900000) + 100000;

		try {
			// Save OTP in DB
			orderDAO.updateOrderOtp(orderId, otp);

			// ── BUG FIX 1: Store OTP + orderId + expiry in session ──────────────────
			// Previously OTP was only saved to DB but NEVER put in session.
			// VerifyOtpServlet reads session.getAttribute("otp") → was always null
			// → every single OTP verification failed with "Invalid or expired OTP".
			HttpSession session = request.getSession(true);
			session.setAttribute("otp", String.valueOf(otp));
			session.setAttribute("otpOrderId", orderId);
			// 5-minute expiry window
			session.setAttribute("otpExpiry", System.currentTimeMillis() + 10 * 60 * 1000L);

			// Optionally send OTP to customer via email/SMS
			// EmailService.sendOtp(orderId, otp);

			log.info("OTP generated and stored in session → orderId=" + orderId);

			// ── BUG FIX 2: Redirect carries both flags ───────────────────────────────
			// DeliveryPortalServlet picks up otpGenerated=true and orderId, sets them
			// as request attributes → JSP adds class="otp-card show" on the matching
			// card → JS DOMContentLoaded handler finds it and focuses the first digit.
			response.sendRedirect(
					request.getContextPath() + "/DeliveryPortalServlet?otpGenerated=true&orderId=" + orderId);

		} catch (Exception e) {
			log.severe("OTP generation failed for order #" + orderId + ": " + e.getMessage());
			throw new ServletException(e);
		}
	}
}