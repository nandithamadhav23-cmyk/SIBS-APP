package com.util;

public class CartItem {
	private int cartId;
	private double discount;
	private String unit;
	private int stock;
	private int productId;
	private String name;
	private String imageUrl;
	private int quantity;
	private double finalPrice;
	private double mrp;
	private String category;
	private String description;
	private int product_quantity;

	/**
	 * GST RATE FIX — new field.
	 *
	 * Carried over from the Product when items are loaded into the cart
	 * (CartDAO.getCartProducts reads gst_rate from the products table).
	 *
	 * PlaceOrderServlet and CheckoutServlet use this to compute per-item GST
	 * instead of applying a flat 18% on every product.
	 *
	 * Default 5.0 is a safe fallback in case legacy cart rows are loaded before the
	 * column migration runs.
	 */
	private double gstRate = 5.0;

	// ── Getters & Setters ────────────────────────────────────────────────────

	public double getMrp() {
		return mrp;
	}

	public void setMrp(double mrp) {
		this.mrp = mrp;
	}

	public String getCategory() {
		return category;
	}

	public void setCategory(String category) {
		this.category = category;
	}

	public int getProductQuantity() {
		return product_quantity;
	}

	public void setProductQuantity(int product_quantity) {
		this.product_quantity = product_quantity;
	}

	public String getDescription() {
		return description;
	}

	public void setDescription(String description) {
		this.description = description;
	}

	public double getDiscount() {
		return discount;
	}

	public void setDiscount(double discount) {
		this.discount = discount;
	}

	public String getUnit() {
		return unit;
	}

	public void setUnit(String unit) {
		this.unit = unit;
	}

	public int getStock() {
		return stock;
	}

	public void setStock(int stock) {
		this.stock = stock;
	}

	public int getCartId() {
		return cartId;
	}

	public void setCartId(int cartId) {
		this.cartId = cartId;
	}

	public int getProductId() {
		return productId;
	}

	public void setProductId(int productId) {
		this.productId = productId;
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public String getImageUrl() {
		return imageUrl;
	}

	public void setImageUrl(String imageUrl) {
		this.imageUrl = imageUrl;
	}

	public int getQuantity() {
		return quantity;
	}

	public void setQuantity(int quantity) {
		this.quantity = quantity;
	}

	public double getFinalPrice() {
		return finalPrice;
	}

	public void setFinalPrice(double finalPrice) {
		this.finalPrice = finalPrice;
	}

	/** GST rate (%) for this product — e.g. 5.0, 12.0, 18.0. */
	public double getGstRate() {
		return gstRate;
	}

	public void setGstRate(double gstRate) {
		this.gstRate = gstRate;
	}

	// ── Utility ──────────────────────────────────────────────────────────────

	/**
	 * GST amount for the entire line (quantity × unit GST). Used by CheckoutServlet
	 * and PlaceOrderServlet to sum order-level GST.
	 */
	public double getLineGst() {
		return finalPrice * quantity * (gstRate / 100.0);
	}

	/** Total line amount before GST. */
	public double getLineTotal() {
		return finalPrice * quantity;
	}

	/** Total line amount including GST. */
	public double getLineTotalWithGst() {
		return getLineTotal() + getLineGst();
	}
}
