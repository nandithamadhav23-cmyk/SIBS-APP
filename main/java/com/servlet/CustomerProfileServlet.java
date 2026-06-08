package com.servlet;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.PrintWriter;
import java.nio.file.Files;
import java.nio.file.StandardCopyOption;
import java.sql.SQLException;
import java.util.List;

import com.DAO.AddressDAO;
import com.DAO.CartDAO;
import com.DAO.CustomerDAO;
import com.util.CartItem;
import com.util.Customer;
import com.util.CustomerAddress;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.Part;

@WebServlet("/CustomerProfile")
@MultipartConfig(maxFileSize = 5 * 1024 * 1024) // 5 MB
public class CustomerProfileServlet extends HttpServlet {

	private static final long serialVersionUID = 1L;
	private static final String IMAGES_DIR = "images/customers/";

	private CustomerDAO customerDAO;
	private AddressDAO addressDAO;
	private CartDAO cartDAO;

	@Override
	public void init() {
		customerDAO = new CustomerDAO();
		addressDAO = new AddressDAO();
		cartDAO = new CartDAO();
	}

	// ── POST ──────────────────────────────────────────────────────────────────
	@Override
	protected void doPost(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
		Object custIdObj = req.getSession().getAttribute("customerId");
		if (custIdObj == null) {
			res.sendRedirect("CustomerLogin.jsp");
			return;
		}
		int customerId = (int) custIdObj;
		String action = req.getParameter("action");

		// ── Delete Profile Image ─────────────────────────────────────────────
		if ("deleteImage".equals(action)) {
			try {
				Customer c = customerDAO.getProfile(customerId);
				if (c != null && c.getProfileImage() != null) {
					String imgPath = getServletContext().getRealPath("") + File.separator + IMAGES_DIR
							+ c.getProfileImage();
					File f = new File(imgPath);
					if (f.exists()) {
						f.delete();
					}
					customerDAO.updateProfileImage(customerId, null);
				}
			} catch (Exception e) {
				e.printStackTrace();
			}
			res.sendRedirect("CustomerProfile?message=Photo+removed");
			return;
		}

		// ── Upload Profile Image ─────────────────────────────────────────────
		Part imagePart = null;
		try {
			imagePart = req.getPart("profileImage");
		} catch (Exception ignored) {
		}

		if (imagePart != null && imagePart.getSize() > 0) {
			String submittedName = imagePart.getSubmittedFileName();
			String ext = "";
			if (submittedName != null && submittedName.contains(".")) {
				ext = submittedName.substring(submittedName.lastIndexOf(".")).toLowerCase();
			}
			if (!".jpg.jpeg.png.webp.gif".contains(ext)) {
				res.sendRedirect("CustomerProfile?message=Invalid+image+format");
				return;
			}
			String filename = "cust_" + customerId + ext;
			String dirPath = getServletContext().getRealPath("") + File.separator + IMAGES_DIR;
			new File(dirPath).mkdirs();
			try (InputStream in = imagePart.getInputStream()) {
				Files.copy(in, new File(dirPath + filename).toPath(), StandardCopyOption.REPLACE_EXISTING);
			}
			try {
				customerDAO.updateProfileImage(customerId, filename);
			} catch (Exception e) {
				e.printStackTrace();
			}
			res.sendRedirect("CustomerProfile?message=Photo+updated+successfully");
			return;
		}

		// ── Default: Update Profile Info ─────────────────────────────────────
		String name = req.getParameter("name");
		String email = req.getParameter("email");
		String phone = req.getParameter("phone");
		String landmarkStreet = req.getParameter("landmark_street");
		String city = req.getParameter("city");
		String district = req.getParameter("district");
		String state = req.getParameter("state");
		String country = req.getParameter("country");
		String pincode = req.getParameter("pincode");
		String gender = req.getParameter("gender");
		// NOTE: password field intentionally omitted from profile-update form;
		// password changes go through ChangePasswordServlet instead.

		try {
			Customer existing = customerDAO.getProfile(customerId);
			customerDAO.updateProfile(customerId, name, email, phone, landmarkStreet, city, district, state, country,
					pincode, null /* keep existing password */, gender);
			Customer updatedProfile = customerDAO.getProfile(customerId);
			req.setAttribute("customer", updatedProfile);
			req.setAttribute("message", "Profile updated successfully!");
			loadAndForward(req, res, customerId);
		} catch (SQLException e) {
			e.printStackTrace();
			req.setAttribute("error", "Error updating profile.");
			loadAndForward(req, res, customerId);
		}
	}

	// ── GET ───────────────────────────────────────────────────────────────────
	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
		Object custIdObj = req.getSession().getAttribute("customerId");
		if (custIdObj == null) {
			res.setContentType("text/html;charset=UTF-8");
			PrintWriter out = res.getWriter();
			out.println("<li class='text-warning'>No profile to display, please login</li>");
			return;
		}
		loadAndForward(req, res, (int) custIdObj);
	}

	// ── Helper ────────────────────────────────────────────────────────────────
	private void loadAndForward(HttpServletRequest req, HttpServletResponse res, int customerId)
			throws ServletException, IOException {
		try {
			Customer profile = customerDAO.getProfile(customerId);
			List<CustomerAddress> addrs = addressDAO.getAddressesByCustomer(customerId);
			List<CartItem> cartItems = cartDAO.getCartProducts(customerId);

			req.setAttribute("customer", profile);
			req.setAttribute("addresses", addrs);
			req.setAttribute("cartItems", cartItems);
			req.getRequestDispatcher("customerProfile.jsp").forward(req, res);
		} catch (SQLException e) {
			e.printStackTrace();
			req.setAttribute("errorMessage", e.getMessage());
			res.sendRedirect("error.jsp");
		}
	}
}
