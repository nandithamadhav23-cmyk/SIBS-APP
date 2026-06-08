package com.servlet;

import java.io.File;
import java.io.IOException;
import java.math.BigDecimal;
import java.sql.Date;
import java.sql.SQLException;
import java.util.List;
import java.util.UUID;
import java.util.logging.Logger;

import com.DAO.LeaveDAO;
import com.util.LeaveRequest;
import com.util.LeaveType;
import com.util.User;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import jakarta.servlet.http.Part;

/**
 * LeaveServlet — employee-facing leave operations.
 *
 * HOW FILE STORAGE WORKS ────────────────────── web.xml supplies: <init-param>
 * <param-name>uploadRootDirLeave</param-name>
 * <param-value>C:/staff_uploads/leave</param-value> ← absolute OS path, OUTSIDE
 * webroot </init-param>
 *
 * Files are written to: C:/staff_uploads/leave/<username>_<uuid>.<ext>
 *
 * The DB column `document_path` stores ONLY the relative key:
 * leave-docs/<username>_<uuid>.<ext>
 *
 * AdminLeaveServlet passes this key to the browser as-is. LeaveDocServlet (see
 * LeaveDocServlet.java) maps GET /LeaveDocServlet?file=leave-docs/xxx.pdf →
 * reads from C:/staff_uploads/leave/xxx.pdf → streams it to the browser with
 * correct Content-Type.
 *
 * This design keeps the upload folder safely OUTSIDE the webroot while still
 * letting the admin view/download documents.
 *
 * ENDPOINTS ───────── GET (no action) → applyLeave.jsp GET
 * ?action=balance&typeId=N → JSON {available: N} GET
 * ?action=days&from=&to=&session= → JSON {days: N} POST ?action=apply → submit
 * leave POST ?action=cancel → cancel leave
 */
@MultipartConfig(fileSizeThreshold = 1024 * 1024, // 1 MB — buffer in memory before writing
		maxFileSize = 5 * 1024 * 1024, // 5 MB per file hard limit
		maxRequestSize = 10 * 1024 * 1024 // 10 MB total request hard limit
)
public class LeaveServlet extends HttpServlet {

	private static final long serialVersionUID = 1L;
	private static final Logger LOG = Logger.getLogger(LeaveServlet.class.getName());

	/**
	 * DB path prefix — stored in leave_requests.document_path as
	 * "leave-docs/<file>"
	 */
	private static final String DB_PREFIX = "leave-docs";

	/** Absolute OS path to the upload folder — set in init() from web.xml */
	private String uploadRootDir;

	/** DAO — safe to instantiate at field level (no servlet context needed) */
	private final LeaveDAO leaveDAO = new LeaveDAO();

	// ════════════════════════════════════════════════════════════
	// INIT — reads web.xml param, creates upload directory
	// ════════════════════════════════════════════════════════════
	@Override
	public void init() throws ServletException {

		// 1. Read the absolute upload folder from web.xml
		uploadRootDir = getInitParameter("uploadRootDirLeave");

		// 2. Fall back to a safe OS-aware default if web.xml omits the param
		if (uploadRootDir == null || uploadRootDir.isBlank()) {
			boolean isWindows = System.getProperty("os.name", "").toLowerCase().contains("win");
			uploadRootDir = isWindows ? "C:/staff_uploads/leave" : "/var/app/staff_uploads/leave";
			LOG.warning("LeaveServlet: 'uploadRootDirLeave' not set in web.xml. " + "Using default: " + uploadRootDir);
		}

		// 3. Canonicalize (resolves "..", trailing slashes, symlinks)
		try {
			uploadRootDir = new File(uploadRootDir).getCanonicalPath();
		} catch (IOException e) {
			throw new ServletException("Cannot resolve uploadRootDir: " + uploadRootDir, e);
		}

		// 4. Create the directory now — fail fast if impossible
		File dir = new File(uploadRootDir);
		if (!dir.exists() && !dir.mkdirs()) {
			throw new ServletException("Cannot create upload directory: " + uploadRootDir + " — check OS permissions.");
		}

		LOG.info("LeaveServlet ready | uploadRootDir=" + uploadRootDir);
	}

	// ════════════════════════════════════════════════════════════
	// GET
	// ════════════════════════════════════════════════════════════
	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {

		HttpSession session = req.getSession(false);
		if (session == null || session.getAttribute("user") == null) {
			res.sendRedirect("index.jsp");
			return;
		}
		User user = (User) session.getAttribute("user");

		String action = req.getParameter("action");
		if (action == null || action.isBlank()) {
			action = "view";
		}

		switch (action) {

		// ── AJAX: available balance for one leave type ────────
		case "balance" -> {
			res.setContentType("application/json;charset=UTF-8");
			try {
				int typeId = Integer.parseInt(req.getParameter("typeId"));
				BigDecimal bal = leaveDAO.getAvailableBalance(user.getUsername(), typeId);
				res.getWriter().write("{\"available\":" + bal + "}");
			} catch (Exception e) {
				res.getWriter().write("{\"available\":0,\"error\":\"" + esc(e.getMessage()) + "\"}");
			}
		}

		// ── AJAX: working-day count between two dates ─────────
		case "days" -> {
			res.setContentType("application/json;charset=UTF-8");
			try {
				java.time.LocalDate from = java.time.LocalDate.parse(req.getParameter("from"));
				java.time.LocalDate to = java.time.LocalDate.parse(req.getParameter("to"));
				String sessionType = req.getParameter("session");
				if (sessionType == null || sessionType.isBlank()) {
					sessionType = "full_day";
				}
				BigDecimal days = leaveDAO.calculateWorkingDays(from, to, sessionType);
				res.getWriter().write("{\"days\":" + days + "}");
			} catch (Exception e) {
				res.getWriter().write("{\"days\":0,\"error\":\"" + esc(e.getMessage()) + "\"}");
			}
		}

		// ── Default: render applyLeave.jsp ────────────────────
		default -> {
			try {
				List<LeaveType> types = leaveDAO.getLeaveTypesWithBalance(user.getUsername());
				List<LeaveRequest> history = leaveDAO.getLeaveHistory(user.getUsername());
				req.setAttribute("leaveTypes", types);
				req.setAttribute("leaveHistory", history);
				req.getRequestDispatcher("applyLeave.jsp").forward(req, res);
			} catch (SQLException e) {
				throw new ServletException("Failed to load leave data", e);
			}
		}
		}
	}

	// ════════════════════════════════════════════════════════════
	// POST
	// ════════════════════════════════════════════════════════════
	@Override
	protected void doPost(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {

		req.setCharacterEncoding("UTF-8");
		HttpSession session = req.getSession(false);
		if (session == null || session.getAttribute("user") == null) {
			res.sendRedirect("index.jsp");
			return;
		}
		User user = (User) session.getAttribute("user");

		String action = req.getParameter("action");
		if (action == null || action.isBlank()) {
			action = "apply";
		}

		switch (action) {
		case "apply" -> handleApply(req, res, user);
		case "cancel" -> handleCancel(req, res, user);
		default -> res.sendRedirect("LeaveServlet");
		}
	}

	// ════════════════════════════════════════════════════════════
	// APPLY HANDLER
	// ════════════════════════════════════════════════════════════
	private void handleApply(HttpServletRequest req, HttpServletResponse res, User user)
			throws ServletException, IOException {

		LeaveRequest lr = new LeaveRequest();
		lr.setUsername(user.getUsername());

		// ── leave type ────────────────────────────────────────
		try {
			lr.setLeaveTypeId(Integer.parseInt(req.getParameter("leaveTypeId")));
		} catch (NumberFormatException e) {
			forwardWithError(req, res, user, "Please select a valid leave type.");
			return;
		}

		// ── dates ─────────────────────────────────────────────
		String fromStr = req.getParameter("fromDate");
		String toStr = req.getParameter("toDate");
		if (isBlank(fromStr) || isBlank(toStr)) {
			forwardWithError(req, res, user, "From date and To date are required.");
			return;
		}
		try {
			lr.setFromDate(Date.valueOf(fromStr.trim()));
			lr.setToDate(Date.valueOf(toStr.trim()));
		} catch (IllegalArgumentException e) {
			forwardWithError(req, res, user, "Invalid date format. Use YYYY-MM-DD.");
			return;
		}

		// ── session type ──────────────────────────────────────
		String sessionType = req.getParameter("sessionType");
		lr.setSessionType(!isBlank(sessionType) ? sessionType : "full_day");

		// ── reason ────────────────────────────────────────────
		String reason = req.getParameter("reason");
		if (reason == null || reason.trim().length() < 10) {
			forwardWithError(req, res, user, "Reason must be at least 10 characters.");
			return;
		}
		lr.setReason(reason.trim());

		// ── optional fields ───────────────────────────────────
		lr.setContactDuringLeave(req.getParameter("contactDuringLeave"));
		lr.setWorkHandover(req.getParameter("workHandover"));
		lr.setCoveringPerson(req.getParameter("coveringPerson"));

		// ── file upload ───────────────────────────────────────
		String docDbPath = handleFileUpload(req, res, user);
		if (docDbPath == null && Boolean.TRUE.equals(req.getAttribute("uploadError"))) {
			// handleFileUpload already forwarded the error response
			return;
		}
		lr.setDocumentPath(docDbPath); // may be null — DAO checks if required

		// ── delegate to DAO (business rules + DB insert) ──────
		try {
			String error = leaveDAO.applyLeave(lr);
			if (error != null) {
				forwardWithError(req, res, user, error);
			} else {
				req.getSession().setAttribute("leaveSuccess",
						"Your leave request has been submitted successfully and is pending approval.");
				res.sendRedirect("LeaveServlet");
			}
		} catch (SQLException e) {
			throw new ServletException("Database error while applying leave", e);
		}
	}

	// ════════════════════════════════════════════════════════════
	// FILE UPLOAD HELPER
	//
	// Returns:
	// • "leave-docs/<filename>" — success, path stored in DB
	// • null — no file was uploaded (ok)
	// • null + sets req attr "uploadError"=true — bad file, error forwarded
	// ════════════════════════════════════════════════════════════
	private String handleFileUpload(HttpServletRequest req, HttpServletResponse res, User user)
			throws ServletException, IOException {

		Part filePart;
		try {
			filePart = req.getPart("document");
		} catch (Exception e) {
			LOG.warning("LeaveServlet: could not read file part: " + e.getMessage());
			return null; // treat as no-upload
		}

		if (filePart == null || filePart.getSize() == 0) {
			return null; // no file chosen — not an error
		}

		// ── extension whitelist ───────────────────────────────
		String origName = getSubmittedFileName(filePart);
		if (isBlank(origName)) {
			return null;
		}

		String ext = origName.contains(".") ? origName.substring(origName.lastIndexOf('.')).toLowerCase() : "";
		if (!ext.matches("\\.(pdf|jpg|jpeg|png)")) {
			req.setAttribute("uploadError", true);
			forwardWithError(req, res, user, "Only PDF, JPG, and PNG files are accepted as supporting documents.");
			return null;
		}

		// ── safe filename: username_uuid.ext ─────────────────
		// UUID avoids collisions and path-traversal attacks
		String safeFile = user.getUsername() + "_" + UUID.randomUUID().toString().replace("-", "") + ext;

		// ── absolute disk path: C:/staff_uploads/leave/<file> ─
		File destFile = new File(uploadRootDir, safeFile);

		// ── path-traversal guard ──────────────────────────────
		if (!destFile.getCanonicalPath().startsWith(new File(uploadRootDir).getCanonicalPath())) {
			req.setAttribute("uploadError", true);
			forwardWithError(req, res, user, "Invalid file path detected.");
			return null;
		}

		// ── write to disk ─────────────────────────────────────
		try {
			filePart.write(destFile.getAbsolutePath());
			LOG.info("Leave doc saved: " + destFile.getAbsolutePath());
		} catch (IOException e) {
			LOG.severe("LeaveServlet: failed to write upload: " + e.getMessage());
			// Non-fatal — DAO will enforce if doc is required for this leave type
			return null;
		}

		// ── return the RELATIVE key stored in the DB ──────────
		// format: leave-docs/<filename>
		// served by LeaveDocServlet: GET /LeaveDocServlet?file=leave-docs/<filename>
		return DB_PREFIX + "/" + safeFile;
	}

	// ════════════════════════════════════════════════════════════
	// CANCEL HANDLER
	// ════════════════════════════════════════════════════════════
	private void handleCancel(HttpServletRequest req, HttpServletResponse res, User user)
			throws ServletException, IOException {

		String idStr = req.getParameter("requestId");
		String reason = req.getParameter("cancelReason");

		if (isBlank(idStr)) {
			req.getSession().setAttribute("leaveError", "Invalid request.");
			res.sendRedirect("LeaveServlet");
			return;
		}
		if (isBlank(reason)) {
			req.getSession().setAttribute("leaveError", "Please provide a reason for cancellation.");
			res.sendRedirect("LeaveServlet");
			return;
		}

		try {
			String error = leaveDAO.cancelLeave(Integer.parseInt(idStr.trim()), user.getUsername(), reason.trim());
			if (error != null) {
				req.getSession().setAttribute("leaveError", error);
			} else {
				req.getSession().setAttribute("leaveSuccess", "Leave request cancelled successfully.");
			}
		} catch (NumberFormatException e) {
			req.getSession().setAttribute("leaveError", "Invalid request ID.");
		} catch (SQLException e) {
			throw new ServletException("Database error while cancelling leave", e);
		}
		res.sendRedirect("LeaveServlet");
	}

	// ════════════════════════════════════════════════════════════
	// SHARED HELPERS
	// ════════════════════════════════════════════════════════════

	private void forwardWithError(HttpServletRequest req, HttpServletResponse res, User user, String error)
			throws ServletException, IOException {
		try {
			List<LeaveType> types = leaveDAO.getLeaveTypesWithBalance(user.getUsername());
			List<LeaveRequest> history = leaveDAO.getLeaveHistory(user.getUsername());
			req.setAttribute("leaveTypes", types);
			req.setAttribute("leaveHistory", history);
			req.setAttribute("formError", error);
			req.getRequestDispatcher("applyLeave.jsp").forward(req, res);
		} catch (SQLException e) {
			throw new ServletException("Error reloading leave page: " + e.getMessage(), e);
		}
	}

	/**
	 * Extracts the original filename from the Content-Disposition header safely.
	 */
	private String getSubmittedFileName(Part part) {
		String cd = part.getHeader("content-disposition");
		if (cd == null) {
			return null;
		}
		for (String token : cd.split(";")) {
			if (token.trim().toLowerCase().startsWith("filename")) {
				String name = token.substring(token.indexOf('=') + 1).trim().replace("\"", "");
				return new File(name).getName(); // strip any path component (old IE behaviour)
			}
		}
		return null;
	}

	private boolean isBlank(String s) {
		return s == null || s.isBlank();
	}

	/** Escapes a string for embedding inside a JSON string literal. */
	private String esc(String s) {
		if (s == null) {
			return "";
		}
		return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n");
	}
}