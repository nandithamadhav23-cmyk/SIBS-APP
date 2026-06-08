package com.servlet;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.file.Paths;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

/**
 * Serves product images from a PERSISTENT directory outside the webapp root.
 *
 * WHY THIS EXISTS: Images stored inside ${webapp}/uploads/ are wiped on every
 * redeploy or server clean because Tomcat explodes the WAR fresh.
 *
 * SOLUTION: Store images in a folder OUTSIDE the WAR — e.g.
 * /opt/sibs-store/product-images/ This directory survives redeployments, server
 * restarts, and WAR rebuilds.
 *
 * SETUP: 1. Create the directory: mkdir -p /opt/sibs-store/product-images 2.
 * Set in web.xml (or tomcat's context.xml): <context-param>
 * <param-name>productImageDir</param-name>
 * <param-value>/opt/sibs-store/product-images</param-value> </context-param> 3.
 * Map this servlet in web.xml under /product-image/*
 *
 * USAGE IN JSP: <img src="product-image/<%= product.getImageUrl() %>">
 * (imageUrl stored in DB as just the filename, e.g. "milk_500ml.jpg")
 */
public class ProductImageServlet extends HttpServlet {

	private static final long serialVersionUID = 1L;

	/**
	 * Fallback placeholder image bytes (1x1 transparent PNG) served when image not
	 * found
	 */
	private static final byte[] PLACEHOLDER_PNG = { (byte) 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00,
			0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00,
			0x00, 0x1F, 0x15, (byte) 0xC4, (byte) 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, 0x78,
			(byte) 0x9C, 0x62, 0x00, 0x00, 0x00, 0x02, 0x00, 0x01, (byte) 0xE2, 0x21, (byte) 0xBC, 0x33, 0x00, 0x00,
			0x00, 0x00, 0x49, (byte) 0x45, 0x4E, 0x44, (byte) 0xAE, 0x42, 0x60, (byte) 0x82 };

	private String imageDir;

	@Override
	public void init() throws ServletException {
		// Try context-param first, then system property, then default
		imageDir = getServletContext().getInitParameter("productImageDir");
		if (imageDir == null || imageDir.trim().isEmpty()) {
			imageDir = System.getProperty("sibs.imageDir",
					System.getenv().getOrDefault("SIBS_IMAGE_DIR", "/opt/sibs-store/product-images"));
		}
		// Ensure directory exists
		File dir = new File(imageDir);
		if (!dir.exists()) {
			dir.mkdirs();
		}
		log("[ProductImageServlet] Image directory: " + imageDir);
	}

	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {

		String pathInfo = req.getPathInfo();
		if (pathInfo == null || pathInfo.equals("/")) {
			servePlaceholder(resp);
			return;
		}

		// Sanitize filename — prevent path traversal
		String filename = Paths.get(pathInfo).getFileName().toString();
		if (filename.isEmpty() || filename.contains("..")) {
			resp.sendError(HttpServletResponse.SC_BAD_REQUEST);
			return;
		}

		File imageFile = new File(imageDir, filename);
		if (!imageFile.exists() || !imageFile.isFile()) {
			// Try webapp/uploads fallback for images uploaded before migration
			String webappUploads = getServletContext().getRealPath("/uploads/" + filename);
			if (webappUploads != null) {
				File legacy = new File(webappUploads);
				if (legacy.exists()) {
					imageFile = legacy;
				} else {
					servePlaceholder(resp);
					return;
				}
			} else {
				servePlaceholder(resp);
				return;
			}
		}

		// Set content type
		String contentType = getServletContext().getMimeType(filename);
		if (contentType == null) {
			contentType = "image/jpeg";
		}
		resp.setContentType(contentType);

		// Cache for 7 days
		resp.setHeader("Cache-Control", "public, max-age=604800, immutable");
		resp.setDateHeader("Last-Modified", imageFile.lastModified());

		// Stream the image
		resp.setContentLengthLong(imageFile.length());
		try (InputStream in = new FileInputStream(imageFile); OutputStream out = resp.getOutputStream()) {
			byte[] buf = new byte[8192];
			int len;
			while ((len = in.read(buf)) != -1) {
				out.write(buf, 0, len);
			}
		}
	}

	private void servePlaceholder(HttpServletResponse resp) throws IOException {
		resp.setContentType("image/png");
		resp.setContentLength(PLACEHOLDER_PNG.length);
		resp.setHeader("Cache-Control", "public, max-age=86400");
		resp.getOutputStream().write(PLACEHOLDER_PNG);
	}
}
