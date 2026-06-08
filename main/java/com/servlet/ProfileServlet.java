package com.servlet;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.StandardCopyOption;
import java.util.logging.Logger;

import com.DAO.UserDAO;
import com.util.User;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import jakarta.servlet.http.Part;

@WebServlet("/profile")
@MultipartConfig(maxFileSize = 5 * 1024 * 1024) // 5 MB
public class ProfileServlet extends HttpServlet {

	private static final Logger logger = Logger.getLogger(ProfileServlet.class.getName());
	private static final String IMAGES_DIR = "images/users/";

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		HttpSession session = request.getSession(false);
		if (session == null || session.getAttribute("username") == null) {
			response.sendRedirect("index.jsp?error=Please login first.");
			return;
		}

		String uname = (String) session.getAttribute("username");
		UserDAO dao = new UserDAO();
		User user = dao.getUserByUsername(uname);

		if (user != null) {
			request.setAttribute("user", user);
		} else {
			request.setAttribute("error", "User not found.");
		}

		request.getRequestDispatcher("profile.jsp").forward(request, response);
	}

	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		HttpSession session = request.getSession(false);
		if (session == null || session.getAttribute("username") == null) {
			response.sendRedirect("index.jsp?error=Please login first.");
			return;
		}

		String uname = (String) session.getAttribute("username");
		String action = request.getParameter("action");
		UserDAO dao = new UserDAO();

		// ── Change Password ─────────────────────────────────────────────────
		if ("changePassword".equals(action)) {
			String currentPwd = request.getParameter("currentPassword");
			String newPwd = request.getParameter("newPassword");
			String confirmPwd = request.getParameter("confirmPassword");

			if (newPwd == null || newPwd.isEmpty()) {
				response.sendRedirect("profile?pwdMessage=New+password+cannot+be+empty");
				return;
			}
			if (!newPwd.equals(confirmPwd)) {
				response.sendRedirect("profile?pwdMessage=Passwords+do+not+match");
				return;
			}
			if (newPwd.length() < 8) {
				response.sendRedirect("profile?pwdMessage=Password+must+be+at+least+8+characters");
				return;
			}

			boolean changed = dao.changePassword(uname, currentPwd, newPwd);
			response.sendRedirect("profile?pwdMessage="
					+ (changed ? "Password+updated+successfully" : "Current+password+is+incorrect"));
			return;
		}

		// ── Delete Profile Image ────────────────────────────────────────────
		if ("deleteImage".equals(action)) {
			User existing = dao.getUserByUsername(uname);
			if (existing != null && existing.getProfileImage() != null) {
				String imgPath = getServletContext().getRealPath("") + File.separator + IMAGES_DIR
						+ existing.getProfileImage();
				File imgFile = new File(imgPath);
				if (imgFile.exists()) {
					imgFile.delete();
				}
			}
			dao.deleteProfileImage(uname);
			response.sendRedirect("profile?message=Profile+photo+removed");
			return;
		}

		// ── Upload Profile Image ────────────────────────────────────────────
		Part imagePart = null;
		try {
			imagePart = request.getPart("profileImage");
		} catch (Exception ignored) {
		}

		if (imagePart != null && imagePart.getSize() > 0) {
			String submittedName = imagePart.getSubmittedFileName();
			String ext = "";
			if (submittedName != null && submittedName.contains(".")) {
				ext = submittedName.substring(submittedName.lastIndexOf(".")).toLowerCase();
			}
			String allowedExts = ".jpg.jpeg.png.webp.gif";
			if (!allowedExts.contains(ext)) {
				response.sendRedirect("profile?message=Invalid+image+format.+Use+JPG,+PNG+or+WEBP.");
				return;
			}

			// Save to WEB-INF/images/users/<username><ext>
			String filename = uname.replaceAll("[^a-zA-Z0-9_-]", "_") + ext;
			String dirPath = getServletContext().getRealPath("") + File.separator + IMAGES_DIR;
			new File(dirPath).mkdirs();

			try (InputStream in = imagePart.getInputStream()) {
				Files.copy(in, new File(dirPath + filename).toPath(), StandardCopyOption.REPLACE_EXISTING);
			}
			dao.updateProfileImage(uname, filename);
			response.sendRedirect("profile?message=Profile+photo+updated+successfully");
			return;
		}

		// ── Default: Update Profile Info ────────────────────────────────────
		String email = request.getParameter("email");
		String mobile = request.getParameter("mobile");
		String address = request.getParameter("address");
		String status = request.getParameter("status");

		User existingUser = dao.getUserByUsername(uname);
		if (existingUser == null) {
			response.sendRedirect("profile?message=User+not+found.");
			return;
		}

		existingUser.setEmail(email);
		existingUser.setMobileno(mobile);
		existingUser.setAddress(address);
		existingUser.setStatus(status);

		boolean updated = dao.updateUser(existingUser);
		response.sendRedirect(
				"profile?message=" + (updated ? "Profile+updated+successfully" : "Failed+to+update+profile"));
	}
}
