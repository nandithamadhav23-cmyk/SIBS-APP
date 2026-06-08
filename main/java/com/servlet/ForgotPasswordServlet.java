package com.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.security.SecureRandom;
import java.sql.SQLException;
import java.time.Instant;
import java.util.Properties;

import com.DAO.CustomerDAO;
import com.twilio.Twilio;

import jakarta.mail.Authenticator;
import jakarta.mail.Message;
import jakarta.mail.PasswordAuthentication;
import jakarta.mail.Session;
import jakarta.mail.Transport;
import jakarta.mail.internet.InternetAddress;
import jakarta.mail.internet.MimeMessage;
import jakarta.servlet.ServletContext;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

/**
 * ForgotPasswordServlet
 *
 * Handles the 3-step forgot-password flow: Step 1 (action=sendOTP) — Validates
 * contact (email or mobile), generates OTP, sends it Step 2 (action=verifyOTP)
 * — Verifies the OTP Step 3 (POST no action) — Resets the password using
 * verified OTP
 *
 * Dependencies (pom.xml): <dependency> <groupId>com.sun.mail</groupId>
 * <artifactId>jakarta.mail</artifactId> <version>2.0.1</version> </dependency>
 * <!-- For SMS (Twilio): --> <dependency> <groupId>com.twilio.sdk</groupId>
 * <artifactId>twilio</artifactId> <version>9.14.1</version> </dependency>
 *
 * Email config: Set SMTP_HOST, SMTP_USER, SMTP_PASS as environment variables.
 * SMS config: Set TWILIO_SID, TWILIO_TOKEN, TWILIO_FROM as environment
 * variables.
 */
@WebServlet("/ForgotPasswordServlet")
public class ForgotPasswordServlet extends HttpServlet {

	// OTP validity window in seconds
	private static final int OTP_EXPIRY_SECONDS = 300; // 5 minutes

	// ─── SMTP Configuration (load from env in production) ────────────────────
	private static final String SMTP_HOST = System.getenv().getOrDefault("SMTP_HOST", "smtp.gmail.com");
	private static final String SMTP_PORT = System.getenv().getOrDefault("SMTP_PORT", "587");
	private static final String SMTP_USER = System.getenv().getOrDefault("SMTP_USER", "your_email@gmail.com");
	private static final String SMTP_PASS = System.getenv().getOrDefault("SMTP_PASS", "your_app_password");

	// ─── Twilio SMS Configuration ─────────────────────────────────────────────
	// Uncomment and configure to enable SMS OTP
	// private static final String TWILIO_SID = System.getenv("TWILIO_SID");
	// private static final String TWILIO_TOKEN = System.getenv("TWILIO_TOKEN");
	// private static final String TWILIO_FROM = System.getenv("TWILIO_FROM"); //
	// e.g. "+15551234567"

	// ─── MAIN HANDLER ────────────────────────────────────────────────────────
	@Override
	protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {

		req.setCharacterEncoding("UTF-8");
		resp.setCharacterEncoding("UTF-8");

		String action = req.getParameter("action");

		if ("sendOTP".equals(action)) {
			handleSendOTP(req, resp);
		} else if ("verifyOTP".equals(action)) {
			handleVerifyOTP(req, resp);
		} else {
			// Step 3: Password reset (form POST with newPassword + confirmPassword)
			handleResetPassword(req, resp);
		}
	}

	// ─── STEP 1: Send OTP ─────────────────────────────────────────────────────
	private void handleSendOTP(HttpServletRequest req, HttpServletResponse resp) throws IOException {

		resp.setContentType("text/plain");
		PrintWriter out = resp.getWriter();

		String contact = req.getParameter("contact"); // email or +91XXXXXXXXXX
		String method = req.getParameter("method"); // "email" or "mobile"

		if (contact == null || contact.trim().isEmpty() || method == null) {
			out.print("error:invalid_input");
			return;
		}

		contact = contact.trim();

		boolean exists = checkContactExists(contact, method); // stub

		if (!exists) {
			out.print("error"); // tells the frontend "no account found"
			return;
		}

		// --- Generate 6-digit OTP ---
		String otp = generateOTP();
		long expiry = Instant.now().getEpochSecond() + OTP_EXPIRY_SECONDS;

		// --- Store OTP in session ---
		HttpSession session = req.getSession(true);
		session.setAttribute("fp_otp", otp);
		session.setAttribute("fp_expiry", expiry);
		session.setAttribute("fp_contact", contact);
		session.setAttribute("fp_method", method);
		session.setAttribute("fp_verified", false);

		// --- Send OTP ---
		boolean sent;
		if ("email".equals(method)) {
			sent = sendEmailOTP(contact, otp);
		} else {
			sent = sendSmsOTP(contact, otp);
		}

		if (sent) {
			out.print("ok");
		} else {
			out.print("error:send_failed");
		}
	}

	// ─── STEP 2: Verify OTP ───────────────────────────────────────────────────
	private void handleVerifyOTP(HttpServletRequest req, HttpServletResponse resp) throws IOException {

		resp.setContentType("text/plain");
		PrintWriter out = resp.getWriter();

		HttpSession session = req.getSession(false);
		if (session == null) {
			out.print("error:session_expired");
			return;
		}

		String submittedOTP = req.getParameter("otp");
		String savedOTP = (String) session.getAttribute("fp_otp");
		Long expiry = (Long) session.getAttribute("fp_expiry");

		if (savedOTP == null || expiry == null) {
			out.print("error:no_otp");
			return;
		}

		// --- Check expiry ---
		if (Instant.now().getEpochSecond() > expiry) {
			session.removeAttribute("fp_otp");
			out.print("error:expired");
			return;
		}

		// --- Compare OTPs ---
		if (savedOTP.equals(submittedOTP)) {
			session.setAttribute("fp_verified", true);
			out.print("ok");
		} else {
			out.print("error:invalid");
		}
	}

	// ─── STEP 3: Reset Password ───────────────────────────────────────────────
	private void handleResetPassword(HttpServletRequest req, HttpServletResponse resp)
			throws IOException, ServletException {

		HttpSession session = req.getSession(false);

		// Safety: ensure OTP was verified in this session
		if (session == null || !Boolean.TRUE.equals(session.getAttribute("fp_verified"))) {
			resp.sendRedirect("CustomerLogin.jsp?error=unauthorized");
			return;
		}

		String newPassword = req.getParameter("newPassword");
		String confirmPassword = req.getParameter("confirmPassword");
		String contact = (String) session.getAttribute("fp_contact");
		String method = (String) session.getAttribute("fp_method");

		// Basic validation
		if (newPassword == null || newPassword.length() < 8) {
			resp.sendRedirect("CustomerLogin.jsp?error=weak_password");
			return;
		}
		if (!newPassword.equals(confirmPassword)) {
			resp.sendRedirect("CustomerLogin.jsp?error=password_mismatch");
			return;
		}

		// --- Hash the password (never store plain text!) ---
		String hashedPassword = hashPassword(newPassword);

		boolean updated = updatePassword(contact, method, hashedPassword); // stub

		// Invalidate session OTP data
		session.removeAttribute("fp_otp");
		session.removeAttribute("fp_expiry");
		session.removeAttribute("fp_contact");
		session.removeAttribute("fp_method");
		session.removeAttribute("fp_verified");

		if (updated) {
			resp.sendRedirect("CustomerLogin.jsp?success=reset");
		} else {
			resp.sendRedirect("CustomerLogin.jsp?error=update_failed");
		}
	}

	// ─── EMAIL SENDER ─────────────────────────────────────────────────────────
	private boolean sendEmailOTP(String toEmail, String otp) {

		ServletContext context = getServletContext();
		String host = context.getInitParameter("mail.smtp.host");
		String port = context.getInitParameter("mail.smtp.port");
		String mailUser = context.getInitParameter("mail.smtp.user");
		String mailPassword = context.getInitParameter("mail.smtp.password");
		try {
			Properties props = new Properties();
			props.put("mail.smtp.host", host);
			props.put("mail.smtp.port", port);
			props.put("mail.smtp.auth", "true");
			props.put("mail.smtp.starttls.enable", "true");

			Session mailSession = Session.getInstance(props, new Authenticator() {
				@Override
				protected PasswordAuthentication getPasswordAuthentication() {
					return new PasswordAuthentication(mailUser, mailPassword);
				}
			});

			Message msg = new MimeMessage(mailSession);
			msg.setFrom(new InternetAddress(SMTP_USER, "Smart Inventory"));
			msg.setRecipients(Message.RecipientType.TO, InternetAddress.parse(toEmail));
			msg.setSubject("Your Password Reset OTP — Smart Inventory");

			// HTML email body
			String htmlBody = buildEmailBody(otp);
			msg.setContent(htmlBody, "text/html; charset=UTF-8");

			Transport.send(msg);
			return true;

		} catch (Exception e) {
			e.printStackTrace();
			return false;
		}
	}

	// ─── SMS SENDER (Twilio) ──────────────────────────────────────────────────
	private boolean sendSmsOTP(String mobileWithCode, String otp) {
		// 1. Get credentials from web.xml
		String sid = getServletContext().getInitParameter("twilio_sid");
		String token = getServletContext().getInitParameter("twilio_token");
		String serviceSid = "VAf6c26028a8ab4b19a1b95ff03e58191b";

		try {
			Twilio.init(sid, token);

			// The mobileWithCode variable is whatever the customer typed in your form.
			// Twilio sends the SMS to that specific number automatically.
			com.twilio.rest.verify.v2.service.Verification verification = com.twilio.rest.verify.v2.service.Verification
					.creator(serviceSid, mobileWithCode, // This changes for every customer!
							"sms")
					.create();

			System.out.println("[Twilio] Sent to: " + mobileWithCode + " Status: " + verification.getStatus());
			return true;
		} catch (Exception e) {
			System.err.println("Twilio Error: " + e.getMessage());
			return false;
		}
	}

	// ─── EMAIL HTML TEMPLATE ──────────────────────────────────────────────────
	private String buildEmailBody(String otp) {
		return "<!DOCTYPE html><html><body style='font-family:DM Sans,sans-serif;background:#f5f4fb;padding:2rem;'>"
				+ "<div style='max-width:480px;margin:auto;background:#fff;border-radius:16px;overflow:hidden;box-shadow:0 8px 32px rgba(0,0,0,0.1);'>"
				+ "<div style='background:linear-gradient(135deg,#0f0e17,#1e1b38);padding:2rem;text-align:center;'>"
				+ "<h2 style='color:#e8a838;font-family:serif;margin:0;'>Smart Inventory</h2>"
				+ "<p style='color:rgba(255,255,255,0.6);margin:0.4rem 0 0;font-size:0.9rem;'>Password Reset Request</p>"
				+ "</div>" + "<div style='padding:2rem;text-align:center;'>"
				+ "<p style='color:#2d2b3f;font-size:1rem;'>Your one-time password (OTP) is:</p>"
				+ "<div style='background:#f0f4ff;border-radius:12px;padding:1.5rem;margin:1.2rem 0;'>"
				+ "<span style='font-size:2.5rem;font-weight:700;letter-spacing:0.6rem;color:#0f0e17;'>" + otp
				+ "</span>" + "</div>" + "<p style='color:#6b6880;font-size:0.85rem;line-height:1.6;'>"
				+ "This OTP is valid for <strong>5 minutes</strong>. Do not share this code with anyone. "
				+ "If you did not request this, please ignore this email or contact support.</p>" + "</div>"
				+ "<div style='background:#f8f8fc;padding:1rem 2rem;text-align:center;border-top:1px solid #e4e2ed;'>"
				+ "<p style='color:#b0aec0;font-size:0.75rem;margin:0;'>© 2025 Smart Inventory. All rights reserved.</p>"
				+ "</div>" + "</div></body></html>";
	}

	// ─── HELPERS ──────────────────────────────────────────────────────────────
	private String generateOTP() {
		SecureRandom rng = new SecureRandom();
		int num = 100000 + rng.nextInt(900000);
		return String.valueOf(num);
	}

	/**
	 * Hash the password using BCrypt. Add the BCrypt dependency: <dependency>
	 * <groupId>at.favre.lib</groupId> <artifactId>bcrypt</artifactId>
	 * <version>0.10.2</version> </dependency>
	 *
	 * Then replace this with: return BCrypt.withDefaults().hashToString(12,
	 * password.toCharArray());
	 */
	private String hashPassword(String password) {

		System.err.println("[WARN] Using plain-text password stub — integrate BCrypt before production!");
		try {
			java.security.MessageDigest md = java.security.MessageDigest.getInstance("SHA-256");
			byte[] hash = md.digest(password.getBytes());
			StringBuilder sb = new StringBuilder();
			for (byte b : hash) {
				sb.append(String.format("%02x", b));
			}
			return sb.toString();
		} catch (java.security.NoSuchAlgorithmException e) {
			throw new RuntimeException(e);
		}
	}

	// ─── STUBS — Replace with actual DAO calls ────────────────────────────────
	private boolean checkContactExists(String contact, String method) {

		System.out.println("[FP] Checking contact: " + contact + " via " + method);
		try {
			CustomerDAO dao = new CustomerDAO();
			return dao.existsByContact(contact, method);

		} catch (SQLException e) {
			e.printStackTrace();
			return false;
		}

	}

	private boolean updatePassword(String contact, String method, String hashedPwd) {

		System.out.println("[FP] Updating password for: " + contact + " | Hash: " + hashedPwd);
		try {
			CustomerDAO dao = new CustomerDAO();
			// The hashedPwd passed here is already processed by the servlet's
			// hashPassword()
			// If you prefer the DAO to handle hashing, pass the plain text and call
			// dao.hashPassword() inside.
			return dao.updatePasswordByContact(contact, method, hashedPwd);
		} catch (SQLException e) {
			e.printStackTrace();
			return false;
		}
	}
}
