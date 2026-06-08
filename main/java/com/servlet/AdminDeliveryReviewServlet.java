package com.servlet;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.net.URLDecoder;
import java.sql.Connection;
import java.util.logging.Level;
import java.util.logging.Logger;

import com.DAO.DeliveryRegistrationDAO;
import com.util.DBConnection;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

/**
 * AdminDeliveryReviewServlet
 * ─────────────────────────────────────────────────────────────────────────────
 * Handles four URL mappings — ALL declared in web.xml (do NOT add @WebServlet
 * here; having both web.xml mappings and @WebServlet causes a Tomcat deployment
 * conflict and the app will fail to start):
 *
 * 1. /AdminDeliveryReviewServlet — POST: approve / reject a KYC application 2.
 * /DeliveryAgentReview — GET: load the list fragment into the dashboard 3.
 * /DeliveryAgentDetail — GET: load the detail fragment into the dashboard 4.
 * /AdminDocServlet — GET: serve uploaded documents / images safely from
 * uploadRootDir (outside webapp)
 *
 * SECURITY NOTES ────────────── • All GET handlers check session role ==
 * "admin". • AdminDocServlet normalises the requested path and verifies it
 * stays within uploadRootDir — preventing path-traversal attacks. • Files are
 * served with Content-Disposition: inline so images render in the browser,
 * while PDFs open in the viewer tab.
 */
public class AdminDeliveryReviewServlet extends HttpServlet {

	private static final long serialVersionUID = 1L;
	private static final Logger log = Logger.getLogger(AdminDeliveryReviewServlet.class.getName());

	/**
	 * Absolute root where all agent documents are permanently stored. Must match
	 * the value configured for DeliveryRegisterServlet.
	 */
	private String uploadRootDir;

	// ─────────────────────────────────────────────────────────────────────────
	@Override
	public void init() throws ServletException {
		uploadRootDir = getInitParameter("uploadRootDir");
		if (uploadRootDir == null || uploadRootDir.isBlank()) {
			boolean isWindows = System.getProperty("os.name", "").toLowerCase().contains("win");
			// FIX: default must match DeliveryRegisterServlet's default (KYC_docs
			// subfolder).
			// Both servlets MUST share the exact same root so documents saved during
			// registration can be read by AdminDocServlet.
			// web.xml should always supply this value; the fallback is a last resort.
			uploadRootDir = isWindows ? "C:/delivery_uploads/KYC_docs" : "/var/app/delivery_uploads/KYC_docs";
			log.warning(
					"AdminDeliveryReviewServlet: uploadRootDir not set in web.xml — using default: " + uploadRootDir);
		}
		// Normalize to canonical path (removes trailing slashes etc.)
		try {
			uploadRootDir = new File(uploadRootDir).getCanonicalPath();
		} catch (IOException e) {
			throw new ServletException("Cannot resolve uploadRootDir: " + uploadRootDir, e);
		}
		log.info("AdminDeliveryReviewServlet initialised | uploadRootDir=" + uploadRootDir);
	}

	// ─────────────────────────────────────────────────────────────────────────
	// GET — route by servlet path
	// ─────────────────────────────────────────────────────────────────────────
	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {

		String path = req.getServletPath();

		switch (path) {
		case "/DeliveryAgentReview":
			handleListPage(req, resp);
			break;

		case "/DeliveryAgentDetail":
			handleDetailPage(req, resp);
			break;

		case "/AdminDocServlet":
			handleDocServe(req, resp);
			break;

		default:
			resp.sendError(HttpServletResponse.SC_NOT_FOUND);
		}
	}

	// ─────────────────────────────────────────────────────────────────────────
	// POST — approve / reject
	// ─────────────────────────────────────────────────────────────────────────
	@Override
	protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {

		/* ── Auth guard ─────────────────────────────────────────────────────── */
		if (!isAdmin(req)) {
			resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Admin access required.");
			return;
		}

		req.setCharacterEncoding("UTF-8");

		String action = req.getParameter("action"); // approve | reject
		String remarks = req.getParameter("adminRemarks"); // optional text
		String redirectFilter = req.getParameter("redirectFilter"); // e.g. PENDING
		int registrationId = -1;

		try {
			registrationId = Integer.parseInt(req.getParameter("registrationId"));
		} catch (NumberFormatException e) {
			setSessionMsg(req, "danger", "Invalid application ID.");
			resp.sendRedirect(req.getContextPath() + "/DeliveryAgentReview");
			return;
		}
		// FIX: removed unused local 'session' variable declared here — session is
		// accessed inside setSessionMsg() via req.getSession(false) already.

		/* ── Perform DB action ──────────────────────────────────────────────── */
		try (Connection conn = DBConnection.getConnection()) {
			DeliveryRegistrationDAO dao = new DeliveryRegistrationDAO(conn);

			if ("approve".equalsIgnoreCase(action)) {
				dao.approveRegistration(registrationId, remarks);
				setSessionMsg(req, "success", "Application #" + registrationId + " has been APPROVED. "
						+ "A delivery user account has been created.");

			} else if ("reject".equalsIgnoreCase(action)) {
				dao.rejectRegistration(registrationId, remarks);
				setSessionMsg(req, "danger", "Application #" + registrationId + " has been REJECTED."
						+ (remarks != null && !remarks.isBlank() ? " Reason: " + remarks : ""));

			} else {
				setSessionMsg(req, "danger", "Unknown action: " + action);
			}

		} catch (Exception ex) {
			log.log(Level.SEVERE, "Error processing delivery agent action", ex);
			setSessionMsg(req, "danger", "Error: " + ex.getMessage());
		}

		/* ── Redirect back to list ──────────────────────────────────────────── */
		String filter = (redirectFilter != null && !redirectFilter.isBlank()) ? redirectFilter : "ALL";
		resp.sendRedirect(req.getContextPath() + "/DeliveryAgentReview?filter=" + filter);
	}

	// ─────────────────────────────────────────────────────────────────────────
	// PRIVATE — list fragment
	// ─────────────────────────────────────────────────────────────────────────
	private void handleListPage(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
		if (!isAdmin(req)) {
			resp.sendError(HttpServletResponse.SC_FORBIDDEN);
			return;
		}
		// JSPs are at webapp root, NOT inside /WEB-INF/views/
		req.getRequestDispatcher("/deliveryAgentReview.jsp").forward(req, resp);
	}

	// ─────────────────────────────────────────────────────────────────────────
	// PRIVATE — detail fragment
	// ─────────────────────────────────────────────────────────────────────────
	private void handleDetailPage(HttpServletRequest req, HttpServletResponse resp)
			throws ServletException, IOException {
		if (!isAdmin(req)) {
			resp.sendError(HttpServletResponse.SC_FORBIDDEN);
			return;
		}
		// JSPs are at webapp root, NOT inside /WEB-INF/views/
		req.getRequestDispatcher("/deliveryAgentDetail.jsp").forward(req, resp);
	}

	// ─────────────────────────────────────────────────────────────────────────
	// PRIVATE — secure document/image serving
	// ─────────────────────────────────────────────────────────────────────────
	/**
	 * Serves files stored in uploadRootDir.
	 *
	 * The client sends a relative path (e.g. "agent_docs/42/aadhaar_front_abc.jpg")
	 * stored in the DB. We resolve it against uploadRootDir and verify the
	 * canonical path still starts with uploadRootDir — preventing path traversal.
	 */
	private void handleDocServe(HttpServletRequest req, HttpServletResponse resp) throws IOException {

		if (!isAdmin(req)) {
			resp.sendError(HttpServletResponse.SC_FORBIDDEN);
			return;
		}

		String relativePath = req.getParameter("path");
		if (relativePath == null || relativePath.isBlank()) {
			resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "Missing path parameter.");
			return;
		}

		// URL-decode just in case (already decoded by servlet container, but be safe)
		try {
			relativePath = URLDecoder.decode(relativePath, "UTF-8");
		} catch (Exception ignored) {
		}

		// Resolve and canonicalise
		File requested;
		try {
			requested = new File(uploadRootDir, relativePath).getCanonicalFile();
		} catch (IOException e) {
			resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid path.");
			return;
		}

		log.info("AdminDocServlet | relativePath=[" + relativePath + "] | resolved=[" + requested.getAbsolutePath()
				+ "] | exists=" + requested.exists());

		// ── PATH TRAVERSAL GUARD ──────────────────────────────────────────────
		// Use the canonical path of uploadRootDir (set in init()) as the prefix.
		// We append File.separator so "C:/uploads/KYC_docs_evil" does not match
		// a root of "C:/uploads/KYC_docs".
		// FIX: also accept the exact root itself (no trailing separator) in case
		// the file IS the root directory — though in practice files are always
		// inside subdirectories, this keeps the guard logically complete.
		String canonicalRequested = requested.getCanonicalPath();
		String guardPrefix = uploadRootDir + File.separator;
		if (!canonicalRequested.startsWith(guardPrefix) && !canonicalRequested.equals(uploadRootDir)) {
			log.warning("Path traversal attempt blocked: " + relativePath + " → " + canonicalRequested);
			resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Access denied.");
			return;
		}

		if (!requested.exists() || !requested.isFile()) {
			resp.sendError(HttpServletResponse.SC_NOT_FOUND, "Document not found.");
			return;
		}

		// ── Detect MIME type ──────────────────────────────────────────────────
		String mimeType = getServletContext().getMimeType(requested.getName());
		if (mimeType == null) {
			mimeType = "application/octet-stream";
		}

		// ── Set response headers ──────────────────────────────────────────────
		resp.setContentType(mimeType);
		resp.setContentLengthLong(requested.length());

		// Images and PDFs render inline; everything else is a download
		boolean renderInline = mimeType.startsWith("image/") || "application/pdf".equals(mimeType);
		String disposition = renderInline ? "inline" : "attachment";
		resp.setHeader("Content-Disposition", disposition + "; filename=\"" + requested.getName() + "\"");

		// ── Never cache sensitive documents ──────────────────────────────────
		resp.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
		resp.setHeader("Pragma", "no-cache");
		resp.setDateHeader("Expires", 0);

		// ── Stream the file ───────────────────────────────────────────────────
		try (FileInputStream fis = new FileInputStream(requested); OutputStream out = resp.getOutputStream()) {
			byte[] buf = new byte[8192];
			int len;
			while ((len = fis.read(buf)) != -1) {
				out.write(buf, 0, len);
			}
		} catch (IOException e) {
			// Client disconnected mid-stream — not a server error
			log.fine("Client disconnected while streaming document: " + relativePath);
		}
	}

	// ─────────────────────────────────────────────────────────────────────────
	// HELPERS
	// ─────────────────────────────────────────────────────────────────────────

	private boolean isAdmin(HttpServletRequest req) {
		HttpSession session = req.getSession(false);
		if (session == null) {
			return false;
		}
		String role = (String) session.getAttribute("role");
		return "admin".equalsIgnoreCase(role);
	}

	private void setSessionMsg(HttpServletRequest req, String type, String msg) {
		HttpSession session = req.getSession(false);
		if (session != null) {
			session.setAttribute("drActionMsg", msg);
			session.setAttribute("drActionType", type);
		}
	}
}