package com.servlet;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.util.logging.Logger;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

/**
 * LeaveDocServlet — securely streams leave supporting documents to the browser.
 *
 * WHY THIS EXISTS ─────────────── Uploaded documents are stored OUTSIDE the
 * webroot (e.g. C:/staff_uploads/leave/). They cannot be served as static files
 * by Tomcat. This servlet: 1. Verifies the caller is logged in (user OR admin
 * session) 2. Resolves the file from the DB key ("leave-docs/<filename>") 3.
 * Guards against path-traversal attacks 4. Streams the bytes with the correct
 * Content-Type header
 *
 * ENDPOINT ──────── GET /LeaveDocServlet?file=leave-docs/<filename>
 *
 * The `file` parameter is exactly the value stored in
 * leave_requests.document_path (e.g. "leave-docs/alice_abc123.pdf").
 *
 * WEB.XML (add next to LeaveServlet entry) ──────── <servlet>
 * <servlet-name>LeaveDocServlet</servlet-name>
 * <servlet-class>com.servlet.LeaveDocServlet</servlet-class> <init-param>
 * <param-name>uploadRootDirLeave</param-name>
 * <param-value>C:/staff_uploads/leave</param-value> </init-param>
 * <load-on-startup>3</load-on-startup> </servlet> <servlet-mapping>
 * <servlet-name>LeaveDocServlet</servlet-name>
 * <url-pattern>/LeaveDocServlet</url-pattern> </servlet-mapping>
 */
public class LeaveDocServlet extends HttpServlet {

	private static final long serialVersionUID = 1L;
	private static final Logger LOG = Logger.getLogger(LeaveDocServlet.class.getName());
	private static final int BUFFER_SIZE = 8192; // 8 KB read buffer

	/** Absolute OS path to the upload folder — must match LeaveServlet's param */
	private String uploadRootDir;

	// ════════════════════════════════════════════════════════════
	// INIT
	// ════════════════════════════════════════════════════════════
	@Override
	public void init() throws ServletException {
		uploadRootDir = getInitParameter("uploadRootDirLeave");

		if (uploadRootDir == null || uploadRootDir.isBlank()) {
			boolean isWindows = System.getProperty("os.name", "").toLowerCase().contains("win");
			uploadRootDir = isWindows ? "C:/staff_uploads/leave" : "/var/app/staff_uploads/leave";
			LOG.warning("LeaveDocServlet: 'uploadRootDirLeave' not in web.xml. Using: " + uploadRootDir);
		}

		try {
			uploadRootDir = new File(uploadRootDir).getCanonicalPath();
		} catch (IOException e) {
			throw new ServletException("Cannot resolve uploadRootDir: " + uploadRootDir, e);
		}

		LOG.info("LeaveDocServlet ready | uploadRootDir=" + uploadRootDir);
	}

	// ════════════════════════════════════════════════════════════
	// GET — serve the document
	// ════════════════════════════════════════════════════════════
	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {

		// ── 1. Auth: must be logged in as user OR admin ───────
		HttpSession session = req.getSession(false);
		boolean loggedIn = session != null && (session.getAttribute("user") != null
				|| "admin".equalsIgnoreCase((String) session.getAttribute("role")));

		if (!loggedIn) {
			res.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Please log in to view documents.");
			return;
		}

		// ── 2. Get the file key from the request ──────────────
		// e.g. "leave-docs/alice_abc123.pdf"
		String fileKey = req.getParameter("file");
		if (fileKey == null || fileKey.isBlank()) {
			res.sendError(HttpServletResponse.SC_BAD_REQUEST, "Missing 'file' parameter.");
			return;
		}

		// ── 3. Strip the "leave-docs/" prefix to get filename ─
		// DB stores "leave-docs/<filename>"; we resolve from uploadRootDir
		String filename = fileKey;
		if (filename.startsWith("leave-docs/")) {
			filename = filename.substring("leave-docs/".length());
		}
		// Remove any remaining directory separators from the filename
		filename = new File(filename).getName(); // strips any remaining path component

		// ── 4. Build and canonicalize the full disk path ──────
		File target = new File(uploadRootDir, filename);
		String canonicalTarget = target.getCanonicalPath();
		String canonicalRoot = new File(uploadRootDir).getCanonicalPath();

		// ── 5. Path-traversal guard ───────────────────────────
		// Ensure the resolved path is still inside uploadRootDir
		if (!canonicalTarget.startsWith(canonicalRoot + File.separator) && !canonicalTarget.equals(canonicalRoot)) {
			LOG.warning("Path traversal attempt blocked: " + fileKey + " | resolved: " + canonicalTarget);
			res.sendError(HttpServletResponse.SC_FORBIDDEN, "Access denied.");
			return;
		}

		// ── 6. File must exist and be a regular file ──────────
		if (!target.exists() || !target.isFile()) {
			LOG.warning("Leave doc not found on disk: " + canonicalTarget);
			res.sendError(HttpServletResponse.SC_NOT_FOUND, "Document not found.");
			return;
		}

		// ── 7. Determine Content-Type from extension ──────────
		String ext = filename.contains(".") ? filename.substring(filename.lastIndexOf('.') + 1).toLowerCase() : "";
		String contentType = switch (ext) {
		case "pdf" -> "application/pdf";
		case "jpg", "jpeg" -> "image/jpeg";
		case "png" -> "image/png";
		case "gif" -> "image/gif";
		case "webp" -> "image/webp";
		default -> "application/octet-stream";
		};

		// ── 8. Set response headers ───────────────────────────
		res.setContentType(contentType);
		res.setContentLengthLong(target.length());

		// For PDFs: "inline" so the browser renders them.
		// For images: "inline" so they display in the modal <img>/<iframe>.
		// For unknown types: "attachment" forces download.
		String disposition = contentType.equals("application/octet-stream")
				? "attachment; filename=\"" + filename + "\""
				: "inline; filename=\"" + filename + "\"";
		res.setHeader("Content-Disposition", disposition);

		// Cache for 1 hour (documents don't change after upload)
		res.setHeader("Cache-Control", "private, max-age=3600");

		// ── 9. Stream the file bytes ──────────────────────────
		try (FileInputStream fis = new FileInputStream(target); OutputStream out = res.getOutputStream()) {
			byte[] buf = new byte[BUFFER_SIZE];
			int read;
			while ((read = fis.read(buf)) != -1) {
				out.write(buf, 0, read);
			}
			out.flush();
		} catch (IOException e) {
			// Client disconnected mid-stream — not an application error
			LOG.fine("LeaveDocServlet: client disconnected while streaming " + filename);
		}
	}
}
