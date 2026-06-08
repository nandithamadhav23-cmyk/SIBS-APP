package com.servlet;

import java.io.IOException;

import org.json.JSONObject;

import com.razorpay.RazorpayClient;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@WebServlet("/CreateRazorpayQrServlet")
public class CreateRazorpayOrderServlet extends HttpServlet {
	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		int orderId = Integer.parseInt(request.getParameter("orderId"));
		double amount = Double.parseDouble(request.getParameter("amount"));

		try {
			RazorpayClient razorpay = new RazorpayClient(getServletContext().getInitParameter("razorpay.key_id"),
					getServletContext().getInitParameter("razorpay.key_secret"));

			JSONObject orderRequest = new JSONObject();
			orderRequest.put("amount", (int) (amount * 100)); // paise
			orderRequest.put("currency", "INR");
			orderRequest.put("receipt", "order_rcptid_" + orderId);
			orderRequest.put("payment_capture", 1);

			response.setContentType("application/json");
			response.getWriter().write(orderRequest.toString());
			com.razorpay.Order razorpayOrder = razorpay.orders.create(orderRequest);

			request.setAttribute("razorpayOrderId", razorpayOrder.get("id"));
			request.setAttribute("amount", amount);
			request.setAttribute("orderId", orderId);
			request.getRequestDispatcher("UPIPayment.jsp").forward(request, response);

		} catch (Exception e) {
			throw new ServletException("Failed to create Razorpay order", e);
		}
	}
}
