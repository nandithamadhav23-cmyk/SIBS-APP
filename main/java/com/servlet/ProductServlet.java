package com.servlet;

import java.io.File;
import java.io.IOException;
import java.nio.file.Paths;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import com.DAO.AdminNotificationDAO;
import com.DAO.ProductDAO;
import com.util.Product;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.Part;

/**
 * ProductServlet — GST RATE FIX applied.
 *
 * CHANGES FROM ORIGINAL: addProduct() — reads "gstRate" form field; passes it
 * to Product constructor. updateProduct() — reads "gstRate" form field; falls
 * back to existing value so edits that don't touch GST slab don't zero it out.
 *
 * FORM FIELD EXPECTED: <select name="gstRate"> <option value="0">0% – Exempt
 * (fresh produce, milk, eggs)</option> <option value="5">5% – Basic food
 * (sugar, tea, edible oil)</option> <option value="12">12% – Processed food
 * (butter, ghee, dry fruits)</option> <option value="18">18% – Packaged /
 * general (snacks, beverages)</option> <option value="28">28% – Luxury /
 * aerated drinks</option> </select>
 *
 * Add this dropdown to both addProduct.jsp and editProduct.jsp. In
 * editProduct.jsp pre-select with: selected="${product.gstRate == X}"
 */
@WebServlet("/ProductServlet")
@MultipartConfig(maxFileSize = 1024 * 1024 * 5) // 5 MB limit
public class ProductServlet extends HttpServlet {
	private ProductDAO productDAO;

	@Override
	public void init() throws ServletException {
		productDAO = new ProductDAO();
	}

	// ── GET dispatcher ────────────────────────────────────────────────────────

	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
		String action = req.getParameter("action");
		try {
			switch (action == null ? "list" : action) {
			case "edit":
				int id = Integer.parseInt(req.getParameter("id"));
				Product product = productDAO.getProductById(id);
				req.setAttribute("product", product);
				req.getRequestDispatcher("editProduct.jsp").forward(req, res);
				break;
			case "delete":
				deleteProduct(req, res);
				break;
			case "listCustomer":
				listProductsForCustomer(req, res);
				break;
			case "search":
				searchProducts(req, res);
				break;
			case "sort":
				sortProducts(req, res);
				break;
			case "view":
				quickViewProduct(req, res);
				break;
			case "load":
				loadMoreProducts(req, res);
				break;
			case "filter":
				filterProductsByCategory(req, res);
				break;
			case "stock":
				listStock(req, res);
				break;
			case "restore":
				restoreProduct(req, res);
				break;
			default:
				listProducts(req, res);
				break;
			}
		} catch (SQLException e) {
			throw new ServletException(e);
		}
	}

	// ── POST dispatcher ───────────────────────────────────────────────────────

	@Override
	protected void doPost(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
		String action = req.getParameter("action");
		try {
			if ("add".equalsIgnoreCase(action)) {
				addProduct(req, res);
			} else if ("update".equalsIgnoreCase(action)) {
				updateProduct(req, res);
			} else if ("notifyAdmin".equalsIgnoreCase(action)) {
				String idParam = req.getParameter("id");
				if (idParam == null || idParam.isEmpty()) {
					req.setAttribute("message", "No product ID provided.");
					req.getRequestDispatcher("StockManagement.jsp").forward(req, res);
					return;
				}

				int productId = Integer.parseInt(idParam);
				Product product = productDAO.getProductById(productId);

				if (product == null) {
					req.setAttribute("message", "Product not found for ID " + productId);
					req.getRequestDispatcher("StockManagement.jsp").forward(req, res);
					return;
				}

				String title = "Low Stock Alert";
				String message = "Product " + product.getName() + " has only " + product.getStock() + " units left.";
				String relatedEntity = product.getName();

				AdminNotificationDAO dao = new AdminNotificationDAO();
				dao.addNotification("LOW_STOCK", title, message, relatedEntity, productId, null);

				req.setAttribute("message", "Notification sent to admin for " + product.getName());
				List<Product> products = productDAO.getAllProducts();
				req.setAttribute("products", products);
				req.getRequestDispatcher("StockManagement.jsp").forward(req, res);
			} else {
				doGet(req, res); // fallback
			}
		} catch (SQLException e) {
			throw new ServletException(e);
		}
	}

	// ── Add Product ───────────────────────────────────────────────────────────

	/**
	 * GST FIX: reads the "gstRate" form field and sets it on the Product. Defaults
	 * to 5.0 if the field is missing or blank (safe fallback for basic food items
	 * which are the most common grocery category).
	 */
	private void addProduct(HttpServletRequest req, HttpServletResponse res)
			throws SQLException, IOException, ServletException {

		String name = req.getParameter("name");
		double mrp = parseDouble(req.getParameter("mrp"));
		int quantity = parseInt(req.getParameter("quantity"));
		String category = req.getParameter("category");
		String description = req.getParameter("description");
		double discount = parseDouble(req.getParameter("discount"));
		String unit = req.getParameter("unit");
		int stock = parseInt(req.getParameter("stock"));
		double finalprice = parseDouble(req.getParameter("finalprice"));

		// GST FIX: read gstRate from form; default 5.0 if not provided
		double gstRate = safeDouble(req.getParameter("gstRate"), 5.0);

		// ── Image upload ──
		Part filePart = req.getPart("imageFile");
		String imageDir = getServletContext().getInitParameter("productImageDir");
		if (imageDir == null || imageDir.trim().isEmpty()) {
			imageDir = System.getProperty("sibs.imageDir",
					System.getenv().getOrDefault("SIBS_IMAGE_DIR", "C:/sibs-store/product-images"));
		}
		File uploadDir = new File(imageDir);
		if (!uploadDir.exists()) {
			uploadDir.mkdirs();
		}

		String originalName = Paths.get(filePart.getSubmittedFileName()).getFileName().toString();
		String ext = originalName.contains(".") ? originalName.substring(originalName.lastIndexOf('.')) : ".jpg";
		String fileName = "product_" + System.currentTimeMillis() + ext;
		filePart.write(uploadDir.getAbsolutePath() + File.separator + fileName);

		String imageUrl = "product-image/" + fileName;
		Timestamp addedDate = new Timestamp(System.currentTimeMillis());
		String status = (stock == 0) ? "inactive" : "active";

		// GST FIX: use the constructor overload that accepts gstRate
		Product product = new Product(0, name, mrp, unit, quantity, discount, category, description, imageUrl, stock,
				addedDate, finalprice, status, null, gstRate);
		productDAO.addProduct(product);

		res.sendRedirect("ProductServlet?action=add&success=Product added successfully");
	}

	// ── Update Product ────────────────────────────────────────────────────────

	/**
	 * GST FIX: reads "gstRate" form field; falls back to existing product's gstRate
	 * so edits that don't touch the GST slab preserve the stored value.
	 */
	private void updateProduct(HttpServletRequest req, HttpServletResponse res)
			throws SQLException, IOException, ServletException {

		int id = parseInt(req.getParameter("id"));
		Product existing = productDAO.getProductById(id);

		if (existing == null) {
			res.sendRedirect("ProductServlet?action=add&error=Product not found");
			return;
		}

		String name = getOrFallback(req.getParameter("name"), existing.getName());
		double mrp = safeDouble(req.getParameter("mrp"), existing.getMrp());
		int quantity = safeInt(req.getParameter("quantity"), existing.getQuantity());
		String category = getOrFallback(req.getParameter("category"), existing.getCategory());
		String description = getOrFallback(req.getParameter("description"), existing.getDescription());
		double discount = safeDouble(req.getParameter("discount"), existing.getDiscount());
		String unit = getOrFallback(req.getParameter("unit"), existing.getUnit());
		int stock = safeInt(req.getParameter("stock"), existing.getStock());
		double finalprice = safeDouble(req.getParameter("finalprice"), existing.getFinalPrice());

		// GST FIX: read updated gstRate; fall back to existing if not provided
		double gstRate = safeDouble(req.getParameter("gstRate"), existing.getGstRate());

		// ── Image upload (keep existing if no new file) ──
		String imageUrl = existing.getImageUrl();
		Part filePart = req.getPart("imageFile");
		if (filePart != null && filePart.getSize() > 0) {
			String imageDir = getServletContext().getInitParameter("productImageDir");
			if (imageDir == null || imageDir.trim().isEmpty()) {
				imageDir = System.getProperty("sibs.imageDir",
						System.getenv().getOrDefault("SIBS_IMAGE_DIR", "C:/sibs-store/product-images"));
			}
			File uploadDir = new File(imageDir);
			if (!uploadDir.exists()) {
				uploadDir.mkdirs();
			}

			String originalName = Paths.get(filePart.getSubmittedFileName()).getFileName().toString();
			String ext = originalName.contains(".") ? originalName.substring(originalName.lastIndexOf('.')) : ".jpg";
			String fileName = "product_" + System.currentTimeMillis() + ext;
			filePart.write(uploadDir.getAbsolutePath() + File.separator + fileName);
			imageUrl = "product-image/" + fileName;
		}

		// ── Added Date ──
		String addedDateStr = req.getParameter("addedDate");
		Timestamp addedDate;
		if (addedDateStr != null && !addedDateStr.isEmpty()) {
			try {
				addedDate = Timestamp.valueOf(addedDateStr.replace("T", " ") + ":00");
			} catch (Exception e) {
				addedDate = existing.getAddedDate() != null ? existing.getAddedDate()
						: new Timestamp(System.currentTimeMillis());
			}
		} else {
			addedDate = existing.getAddedDate() != null ? existing.getAddedDate()
					: new Timestamp(System.currentTimeMillis());
		}

		// ── Status ──
		String statusParam = req.getParameter("status");
		String status;
		if (stock == 0) {
			status = "inactive";
		} else {
			status = (statusParam != null && !statusParam.trim().isEmpty()) ? statusParam.trim().toLowerCase()
					: existing.getStatus();
		}

		// ── Validation ──
		Map<String, String> errors = new LinkedHashMap<>();
		if (name.trim().length() < 3) {
			errors.put("name", "Product name must be at least 3 characters.");
		}
		if (mrp <= 0) {
			errors.put("mrp", "MRP must be a positive number.");
		}
		if (discount < 0 || discount > 100) {
			errors.put("discount", "Discount must be between 0 and 100.");
		}
		if (quantity <= 0) {
			errors.put("quantity", "Quantity must be a positive number.");
		}
		if (stock < 0) {
			errors.put("stock", "Stock cannot be negative.");
		}

		if (!errors.isEmpty()) {
			req.setAttribute("error", String.join(" | ", errors.values()));
			req.setAttribute("product", existing);
			req.getRequestDispatcher("editProduct.jsp").forward(req, res);
			return;
		}

		// ── Track changed fields ──
		List<String> updatedFields = new ArrayList<>();
		if (!name.equals(existing.getName())) {
			updatedFields.add("name");
		}
		if (mrp != existing.getMrp()) {
			updatedFields.add("mrp");
		}
		if (discount != existing.getDiscount()) {
			updatedFields.add("discount");
		}
		if (quantity != existing.getQuantity()) {
			updatedFields.add("quantity");
		}
		if (stock != existing.getStock()) {
			updatedFields.add("stock");
		}
		if (!unit.equals(existing.getUnit())) {
			updatedFields.add("unit");
		}
		if (!category.equals(existing.getCategory())) {
			updatedFields.add("category");
		}
		if (!status.equals(existing.getStatus())) {
			updatedFields.add("status");
		}
		if (!description.equals(existing.getDescription())) {
			updatedFields.add("description");
		}
		if (!imageUrl.equals(existing.getImageUrl())) {
			updatedFields.add("imageUrl");
		}
		if (gstRate != existing.getGstRate()) {
			updatedFields.add("gstRate"); // GST FIX
		}
		if (existing.getAddedDate() == null || !addedDate.equals(existing.getAddedDate())) {
			updatedFields.add("addedDate");
		}

		// GST FIX: use constructor overload that accepts gstRate
		Product product = new Product(id, name, mrp, unit, quantity, discount, category, description, imageUrl, stock,
				addedDate, finalprice, status, null, gstRate);
		productDAO.updateProduct(product);

		String fieldsParam = String.join(",", updatedFields);
		res.sendRedirect(
				"ProductServlet?action=add&success=Product updated successfully&id=" + id + "&fields=" + fieldsParam);
	}

	// ── Remaining action methods (unchanged) ──────────────────────────────────

	private void searchProducts(HttpServletRequest req, HttpServletResponse res)
			throws SQLException, IOException, ServletException {
		String query = req.getParameter("query");
		if (query == null) {
			query = "";
		}
		query = query.trim();
		List<Product> products = productDAO.searchProducts(query);
		req.setAttribute("products", products);
		req.getRequestDispatcher("productGrid.jsp").forward(req, res);
	}

	private void sortProducts(HttpServletRequest req, HttpServletResponse res)
			throws SQLException, IOException, ServletException {
		String sortBy = req.getParameter("sortBy");
		List<Product> products = productDAO.sortProducts(sortBy);
		req.setAttribute("products", products);
		req.getRequestDispatcher("productGrid.jsp").forward(req, res);
	}

	private void quickViewProduct(HttpServletRequest req, HttpServletResponse res)
			throws SQLException, IOException, ServletException {
		int id = Integer.parseInt(req.getParameter("id"));
		Product product = productDAO.getProductById(id);
		req.setAttribute("product", product);
		req.getRequestDispatcher("/productQuickView.jsp").forward(req, res);
	}

	private void loadMoreProducts(HttpServletRequest req, HttpServletResponse res)
			throws SQLException, IOException, ServletException {
		String pageParam = req.getParameter("page");
		int page = 1;
		if (pageParam != null && !pageParam.isEmpty()) {
			page = Integer.parseInt(pageParam);
		}
		int recordsPerPage = 9;
		List<Product> products = productDAO.getProductsByPage((page - 1) * recordsPerPage, recordsPerPage);
		req.setAttribute("products", products);
		req.getRequestDispatcher("productGrid.jsp").forward(req, res);
	}

	private void deleteProduct(HttpServletRequest req, HttpServletResponse res) throws SQLException, IOException {
		int id = Integer.parseInt(req.getParameter("id"));
		String type = req.getParameter("type");
		if ("soft".equalsIgnoreCase(type)) {
			productDAO.softDeleteProduct(id);
		} else {
			productDAO.hardDeleteProduct(id);
		}
		res.sendRedirect("ProductServlet?action=add");
	}

	private void restoreProduct(HttpServletRequest req, HttpServletResponse res) throws SQLException, IOException {
		int id = Integer.parseInt(req.getParameter("id"));
		boolean success = productDAO.restoreProduct(id);
		if (success) {
			res.sendRedirect("ProductServlet?action=add&msg=Product restored");
		} else {
			res.sendRedirect("ProductServlet?action=add&error=Unable to restore");
		}
	}

	private void listProducts(HttpServletRequest req, HttpServletResponse res)
			throws SQLException, IOException, ServletException {
		String action = req.getParameter("action");
		List<Product> products = productDAO.getAllProducts();
		req.setAttribute("products", products);
		if ("add".equalsIgnoreCase(action)) {
			req.getRequestDispatcher("addProduct.jsp").forward(req, res);
		} else {
			req.getRequestDispatcher("viewProducts.jsp").forward(req, res);
		}
	}

	private void listStock(HttpServletRequest req, HttpServletResponse res)
			throws SQLException, ServletException, IOException {
		List<Product> products = productDAO.getAllProducts();
		req.setAttribute("products", products);
		req.getRequestDispatcher("StockManagement.jsp").forward(req, res);
	}

	private void listProductsForCustomer(HttpServletRequest req, HttpServletResponse res)
			throws SQLException, IOException, ServletException {
		int page = 1;
		int recordsPerPage = 25;
		if (req.getParameter("page") != null) {
			page = Integer.parseInt(req.getParameter("page"));
		}

		List<Product> products = productDAO.getProductsByPage((page - 1) * recordsPerPage, recordsPerPage);
		int totalRecords = productDAO.getProductCount();
		int totalPages = (int) Math.ceil(totalRecords * 1.0 / recordsPerPage);

		req.setAttribute("products", products);
		req.setAttribute("currentPage", page);
		req.setAttribute("totalPages", totalPages);

		boolean isAjax = "XMLHttpRequest".equals(req.getHeader("X-Requested-With"));
		if (isAjax) {
			req.getRequestDispatcher("productGrid.jsp").forward(req, res);
		} else {
			req.getRequestDispatcher("customerDashboard.jsp").forward(req, res);
		}
	}

	private void filterProductsByCategory(HttpServletRequest req, HttpServletResponse res)
			throws SQLException, IOException, ServletException {
		String category = req.getParameter("category");
		int page = 1;
		int recordsPerPage = 25;
		if (req.getParameter("page") != null) {
			page = Integer.parseInt(req.getParameter("page"));
		}

		int offset = (page - 1) * recordsPerPage;
		List<Product> products = productDAO.getProductsByCategoryPage(category, offset, recordsPerPage);
		int totalRecords = productDAO.getProductCountByCategory(category);
		int totalPages = (int) Math.ceil(totalRecords * 1.0 / recordsPerPage);

		req.setAttribute("products", products);
		req.setAttribute("currentPage", page);
		req.setAttribute("totalPages", totalPages);

		boolean isAjax = "XMLHttpRequest".equals(req.getHeader("X-Requested-With"));
		if (isAjax) {
			req.getRequestDispatcher("productGrid.jsp").forward(req, res);
		} else {
			req.getRequestDispatcher("customerDashboard.jsp").forward(req, res);
		}
	}

	// ── Utility methods ───────────────────────────────────────────────────────

	private double parseDouble(String val) {
		return (val != null && !val.isEmpty()) ? Double.parseDouble(val) : 0.0;
	}

	private int parseInt(String val) {
		return (val != null && !val.isEmpty()) ? Integer.parseInt(val) : 0;
	}

	private String getOrFallback(String value, String fallback) {
		return (value == null || value.trim().isEmpty()) ? fallback : value;
	}

	private double safeDouble(String value, double fallback) {
		try {
			double parsed = Double.parseDouble(value);
			return parsed >= 0 ? parsed : fallback;
		} catch (Exception e) {
			return fallback;
		}
	}

	private int safeInt(String value, int fallback) {
		try {
			int parsed = Integer.parseInt(value);
			return parsed >= 0 ? parsed : fallback;
		} catch (Exception e) {
			return fallback;
		}
	}
}
