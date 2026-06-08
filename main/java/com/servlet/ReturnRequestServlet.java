package com.servlet;

import java.io.File;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.List;

import com.DAO.OrderDAO;
import com.DAO.OrderReturnDAO;
import com.util.Order; // Ensure this is imported
import com.util.OrderReturn;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.Part;

@WebServlet("/ReturnRequestServlet")
@MultipartConfig(fileSizeThreshold = 1024 * 1024 * 1, // 1 MB
		maxFileSize = 1024 * 1024 * 10, // 10 MB
		maxRequestSize = 1024 * 1024 * 15 // 15 MB
)
public class ReturnRequestServlet extends HttpServlet {

	private OrderReturnDAO orderReturnDAO = new OrderReturnDAO();
	private OrderDAO orderDAO = new OrderDAO();

	@Override
	protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
		resp.setContentType("application/json;charset=UTF-8");
		PrintWriter out = resp.getWriter();
		String action = req.getParameter("action");

		try {
			if ("submitReturn".equals(action)) {
				handleReturnSubmission(req, out);
			} else if ("updateStatus".equals(action)) {
				handleStatusUpdate(req, out);
			}
		} catch (Exception e) {
			e.printStackTrace();
			out.write("{\"success\":false,\"message\":\"Internal Server Error: " + e.getMessage() + "\"}");
		}
	}

	private void handleReturnSubmission(HttpServletRequest req, PrintWriter out) throws Exception {
		int orderId = Integer.parseInt(req.getParameter("orderId"));
		String type = req.getParameter("type");
		String reason = req.getParameter("reason");
		String payMethod = req.getParameter("payMethod");

		// 1. Fetch Order and Validate
		Order order = orderDAO.getOrderById(orderId); // Use your existing DAO method
		if (order == null || !"Delivered".equalsIgnoreCase(order.getStatus())) {
			out.write("{\"success\":false,\"message\":\"Order not eligible for return.\"}");
			return;
		}

		// 2. Validate Return Window
		long currentTime = System.currentTimeMillis();
		long deliveryTime = order.getDeliveryDate().getTime();
		long diffDays = (currentTime - deliveryTime) / (1000 * 60 * 60 * 24);

		if (diffDays > 10) {
			out.write("{\"success\":false,\"message\":\"10-day return window has expired.\"}");
			return;
		}

		// 3. Save Photos
		String uploadPath = getServletContext().getRealPath("/") + "uploads" + File.separator + "returns";
		File uploadDir = new File(uploadPath);
		if (!uploadDir.exists()) {
			uploadDir.mkdirs();
		}

		List<String> photoPaths = new ArrayList<>();
		for (Part part : req.getParts()) {
			if (part.getName().startsWith("photo_") && part.getSize() > 0) {
				String fileName = "rr_" + orderId + "_" + System.currentTimeMillis() + "_" + getFileName(part);
				part.write(uploadPath + File.separator + fileName);
				photoPaths.add("uploads/returns/" + fileName);
			}
		}

		// 4. Populate OrderReturn Object
		OrderReturn rr = new OrderReturn();
		rr.setOrderId(orderId);
		rr.setType(type);
		rr.setReason(reason);
		rr.setStatus("Requested"); // Matching your DB Enum
		rr.setPhotos(String.join(",", photoPaths));
		rr.setRefundAmount(order.getTotalAmount());

		// Add Bank Info if necessary
		if ("bank".equalsIgnoreCase(payMethod)) {
			rr.setBankName(req.getParameter("bankName"));
			rr.setBankAccount(req.getParameter("bankAccount"));
			rr.setBankIfsc(req.getParameter("bankIfsc"));
		}

		// 5. Database Save
		orderReturnDAO.upsertReturnRecord(rr);
		orderDAO.updateOrderStatus(orderId, "Return Requested");
		out.write("{\"success\":true,\"message\":\"Return request submitted successfully.\"}");
	}

	private void handleStatusUpdate(HttpServletRequest req, PrintWriter out) throws Exception {
		int orderId = Integer.parseInt(req.getParameter("orderId"));
		String newStatus = req.getParameter("status");

		boolean success = orderReturnDAO.updateReturnStatus(orderId, newStatus);

		if (success) {

			orderDAO.updateOrderStatus(orderId, newStatus);
			out.write("{\"success\":true}");
		} else {
			out.write("{\"success\":false, \"message\":\"Failed to update status.\"}");
		}
	}

	private String getFileName(Part part) {
		String contentDisp = part.getHeader("content-disposition");
		for (String token : contentDisp.split(";")) {
			if (token.trim().startsWith("filename")) {
				return token.substring(token.indexOf("=") + 2, token.length() - 1);
			}
		}
		return "default.jpg";
	}
}