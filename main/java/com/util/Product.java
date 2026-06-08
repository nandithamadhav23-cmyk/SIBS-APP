package com.util;

import java.sql.Timestamp;

public class Product {
	private int id;
	private String name;
	private int quantity;
	private double discount; // percentage discount
	private String category; // optional
	private String description; // optional
	private String imageUrl; // product image
	private Timestamp addedDate; // now supports date + time
	private double mrp;
	private double finalPrice;
	private String unit;
	private int stock;
	private String status; // active/inactive
	private Timestamp deletedAt;

	/**
	 * GST RATE FIX — new field.
	 *
	 * Stores the GST % applicable to this product (e.g. 0, 5, 12, 18, 28). Set by
	 * the admin when adding/editing a product. Used at order time to compute the
	 * correct tax per item instead of applying a blanket 18% + 5% on every product
	 * regardless of category.
	 *
	 * Default is 5.0 (most grocery/FMCG items fall here).
	 */
	private double gstRate; // e.g. 5.0 means 5 %

	// ── Constructor ──────────────────────────────────────────────────────────
	public Product(int id, String name, double mrp, String unit, int quantity, double discount, String category,
			String description, String imageUrl, int stock, Timestamp addedDate, double finalPrice, String status,
			Timestamp deletedAt) {
		this.id = id;
		this.name = name;
		this.mrp = mrp;
		this.quantity = quantity;
		this.discount = discount;
		this.category = category;
		this.description = description;
		this.imageUrl = imageUrl;
		this.addedDate = addedDate;
		this.unit = unit;
		this.stock = stock;
		this.finalPrice = finalPrice;
		this.status = status;
		this.deletedAt = deletedAt;
		this.gstRate = 5.0; // safe default
	}

	// ── Overloaded constructor that accepts gstRate ──────────────────────────
	public Product(int id, String name, double mrp, String unit, int quantity, double discount, String category,
			String description, String imageUrl, int stock, Timestamp addedDate, double finalPrice, String status,
			Timestamp deletedAt, double gstRate) {
		this(id, name, mrp, unit, quantity, discount, category, description, imageUrl, stock, addedDate, finalPrice,
				status, deletedAt);
		this.gstRate = gstRate;
	}

	// ── Getters ──────────────────────────────────────────────────────────────

	public int getId() {
		return id;
	}

	public String getName() {
		return name;
	}

	public double getMrp() {
		return mrp;
	}

	public int getQuantity() {
		return quantity;
	}

	public double getDiscount() {
		return discount;
	}

	public String getCategory() {
		return category;
	}

	public String getDescription() {
		return description;
	}

	public String getImageUrl() {
		return imageUrl;
	}

	public Timestamp getAddedDate() {
		return addedDate;
	}

	public double getFinalPrice() {
		return finalPrice;
	}

	public String getUnit() {
		return unit;
	}

	public int getStock() {
		return stock;
	}

	public String getStatus() {
		return status;
	}

	public Timestamp getDeletedAt() {
		return deletedAt;
	}

	/** Returns the GST rate for this product (0 / 5 / 12 / 18 / 28). */
	public double getGstRate() {
		return gstRate;
	}

	// ── Setters ──────────────────────────────────────────────────────────────

	public void setId(int id) {
		this.id = id;
	}

	public void setName(String name) {
		this.name = name;
	}

	public void setMrp(double mrp) {
		this.mrp = mrp;
	}

	public void setQuantity(int quantity) {
		this.quantity = quantity;
	}

	public void setDiscount(double discount) {
		this.discount = discount;
	}

	public void setCategory(String category) {
		this.category = category;
	}

	public void setDescription(String description) {
		this.description = description;
	}

	public void setImageUrl(String imageUrl) {
		this.imageUrl = imageUrl;
	}

	public void setAddedDate(Timestamp addedDate) {
		this.addedDate = addedDate;
	}

	public void setFinalPrice(double finalPrice) {
		this.finalPrice = finalPrice;
	}

	public void setUnit(String unit) {
		this.unit = unit;
	}

	public void setDeletedAt(Timestamp deletedAt) {
		this.deletedAt = deletedAt;
	}

	public void setStock(int stock) {
		this.stock = stock;
		// auto-adjust status if not manually overridden
		if (stock == 0 && !"inactive".equalsIgnoreCase(this.status)) {
			this.status = "inactive";
		} else if (stock > 0 && !"active".equalsIgnoreCase(this.status)) {
			this.status = "active";
		}
	}

	public void setStatus(String status) {
		this.status = status;
	}

	public void setGstRate(double gstRate) {
		this.gstRate = gstRate;
	}

	// ── Utility ──────────────────────────────────────────────────────────────

	/** Returns the after-discount selling price (before GST). */
	public double getDiscountedPrice() {
		return mrp - (mrp * discount / 100);
	}

	/**
	 * Returns the GST amount for one unit of this product. GST is calculated on
	 * finalPrice (which is the post-discount selling price).
	 */
	public double getGstAmount() {
		return finalPrice * (gstRate / 100.0);
	}

	/**
	 * Returns the price inclusive of GST for one unit. Useful for display on
	 * product pages.
	 */
	public double getPriceIncludingGst() {
		return finalPrice + getGstAmount();
	}
}
