package com.servlet;

import java.io.IOException;
import java.sql.Connection;
import java.sql.Date;

import com.DAO.UserDAO;
import com.util.DBConnection;
import com.util.EmailUtil;
import com.util.User;

import jakarta.servlet.ServletContext;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@WebServlet("/addDelivery")
public class AddDeliveryServlet extends HttpServlet {
	@Override
	protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
		User user = new User();
		user.setUsername(req.getParameter("username"));
		user.setPassword(req.getParameter("password"));
		user.setEmail(req.getParameter("email"));
		user.setMobileno(req.getParameter("mobile"));
		user.setAddress(req.getParameter("address"));
		user.setGender(req.getParameter("gender"));
		user.setJoiningDate(Date.valueOf(req.getParameter("joining_date")));

		try (Connection conn = DBConnection.getConnection()) {
			UserDAO dao = new UserDAO();
			dao.addDeliveryUser(user);

			// Read SMTP config from web.xml
			ServletContext context = getServletContext();
			String host = context.getInitParameter("mail.smtp.host");
			String port = context.getInitParameter("mail.smtp.port");
			String mailUser = context.getInitParameter("mail.smtp.user");
			String mailPassword = context.getInitParameter("mail.smtp.password");

			// Build HTML card email
			String subject = "Welcome to SIBS Delivery Team";
			String htmlContent = "<div style='max-width:600px;margin:auto;background:#fff;border-radius:10px;box-shadow:0 4px 12px rgba(0,0,0,0.1);overflow:hidden;font-family:Arial,sans-serif'>"
					+ "<div style='background:linear-gradient(135deg,#007bff,#00c6ff);color:#fff;padding:20px;text-align:center'>"
					+ "<h2>📦 SIBS Delivery Portal</h2>" + "</div>" + "<div style='padding:20px;color:#333'>"
					+ "<p>Dear <strong>" + user.getUsername() + "</strong>,</p>"
					+ "<p>Welcome to <strong>SIBS Organization</strong>. Below are your login credentials:</p>"
					+ "<div style='background:#f9fafc;border:1px solid #e0e0e0;border-radius:8px;padding:15px;margin:20px 0'>"
					+ "<p><strong>👤 Username:</strong> " + user.getUsername() + "</p>"
					+ "<p><strong>🔑 Password:</strong> " + user.getPassword() + "</p>"
					+ "<a href='http:localhost:8085//SampleApp/deliveryLogin.jsp' style='display:inline-block;background:#007bff;color:#fff;padding:10px 20px;border-radius:6px;text-decoration:none;margin-top:10px'>Login to Portal</a>"
					+ "</div>" + "<p>Please change your password after your first login for security.</p>" + "</div>"
					+ "<div style='background:#f1f1f1;text-align:center;padding:15px;font-size:12px;color:#555'>"
					+ "<p>SIBS Staff Administration<br>\"Ensuring smooth and timely deliveries\"</p>"
					+ "<p>This is an automated message. Please do not reply.</p>" + "</div>" + "</div>";

			// Send email
			EmailUtil.sendEmail(host, port, mailUser, mailPassword, user.getEmail(), subject, htmlContent);

		} catch (Exception e) {
			throw new ServletException(e);
		}

		resp.sendRedirect("staffDashboard.jsp?msg=Delivery person added successfully");
	}
}
