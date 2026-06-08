// ═══════════════════════════════════════════════════════════════════════════════
// FILE 1:  com/util/DeliveryRegistration.java
// ═══════════════════════════════════════════════════════════════════════════════
package com.util;

/**
 * Plain Java bean representing one delivery-agent registration application.
 * Maps 1-to-1 with the delivery_agent_registrations table.
 *
 * Fields marked "(path)" hold the file-system path relative to the upload root
 * (stored in DB so the admin servlet can serve / display the files).
 */
public class DeliveryRegistration {

	// ── Identity ──────────────────────────────────────────────────────────────
	private int id;
	private String firstName, middleName, lastName;
	private String dob; // YYYY-MM-DD
	private String gender;
	private String bloodGroup;
	private String username;
	private String mobile;
	private String email;
	private String altMobile;

	// ── Address ───────────────────────────────────────────────────────────────
	private String addressLine1, addressLine2, landmark;
	private String city, state, pincode;

	// ── KYC ───────────────────────────────────────────────────────────────────
	private String aadhaarNumber, aadhaarName;
	private String panNumber;
	private String dlNumber, dlIssueDate, dlExpiryDate;
	private String addressProofType;

	// ── KYC file paths ────────────────────────────────────────────────────────
	private String profilePhotoPath;
	private String aadhaarFrontPath, aadhaarBackPath;
	private String panImagePath;
	private String dlFrontPath, dlBackPath;
	private String addressProofPath;

	// ── Vehicle ───────────────────────────────────────────────────────────────
	private String vehicleType, vehicleOwnership, fuelType;
	private String vehicleBrand, vehicleModel, vehicleYear;
	private String vehicleRegNumber, vehicleColour;
	private String insuranceNumber, insuranceExpiry;
	private String pucNumber, pucExpiry;
	private String payloadKg, deliveryZone;

	// ── Vehicle file paths ────────────────────────────────────────────────────
	private String rcBookPath, vehiclePhotoPath;
	private String insuranceCertPath, pucCertPath;

	// ── Bank ──────────────────────────────────────────────────────────────────
	private String bankAccName, bankName, bankAccNumber;
	private String ifscCode, branchName, accountType, upiId;
	private String bankProofPath;

	// ── Emergency ─────────────────────────────────────────────────────────────
	private String emergencyName, emergencyRelation, emergencyMobile;

	// ── Status / Meta ─────────────────────────────────────────────────────────
	private String status; // PENDING | APPROVED | REJECTED
	private String adminRemarks;
	private String submittedAt; // DATETIME string from DB
	private String reviewedAt;

	// ══════════════════════════════ GETTERS / SETTERS ═══════════════════════════
	public int getId() {
		return id;
	}

	public void setId(int id) {
		this.id = id;
	}

	public String getFirstName() {
		return firstName;
	}

	public void setFirstName(String v) {
		this.firstName = v;
	}

	public String getMiddleName() {
		return middleName;
	}

	public void setMiddleName(String v) {
		this.middleName = v;
	}

	public String getLastName() {
		return lastName;
	}

	public void setLastName(String v) {
		this.lastName = v;
	}

	public String getDob() {
		return dob;
	}

	public void setDob(String v) {
		this.dob = v;
	}

	public String getGender() {
		return gender;
	}

	public void setGender(String v) {
		this.gender = v;
	}

	public String getBloodGroup() {
		return bloodGroup;
	}

	public void setBloodGroup(String v) {
		this.bloodGroup = v;
	}

	public String getUsername() {
		return username;
	}

	public void setUsername(String v) {
		this.username = v;
	}

	public String getMobile() {
		return mobile;
	}

	public void setMobile(String v) {
		this.mobile = v;
	}

	public String getEmail() {
		return email;
	}

	public void setEmail(String v) {
		this.email = v;
	}

	public String getAltMobile() {
		return altMobile;
	}

	public void setAltMobile(String v) {
		this.altMobile = v;
	}

	public String getAddressLine1() {
		return addressLine1;
	}

	public void setAddressLine1(String v) {
		this.addressLine1 = v;
	}

	public String getAddressLine2() {
		return addressLine2;
	}

	public void setAddressLine2(String v) {
		this.addressLine2 = v;
	}

	public String getLandmark() {
		return landmark;
	}

	public void setLandmark(String v) {
		this.landmark = v;
	}

	public String getCity() {
		return city;
	}

	public void setCity(String v) {
		this.city = v;
	}

	public String getState() {
		return state;
	}

	public void setState(String v) {
		this.state = v;
	}

	public String getPincode() {
		return pincode;
	}

	public void setPincode(String v) {
		this.pincode = v;
	}

	public String getAadhaarNumber() {
		return aadhaarNumber;
	}

	public void setAadhaarNumber(String v) {
		this.aadhaarNumber = v;
	}

	public String getAadhaarName() {
		return aadhaarName;
	}

	public void setAadhaarName(String v) {
		this.aadhaarName = v;
	}

	public String getPanNumber() {
		return panNumber;
	}

	public void setPanNumber(String v) {
		this.panNumber = v;
	}

	public String getDlNumber() {
		return dlNumber;
	}

	public void setDlNumber(String v) {
		this.dlNumber = v;
	}

	public String getDlIssueDate() {
		return dlIssueDate;
	}

	public void setDlIssueDate(String v) {
		this.dlIssueDate = v;
	}

	public String getDlExpiryDate() {
		return dlExpiryDate;
	}

	public void setDlExpiryDate(String v) {
		this.dlExpiryDate = v;
	}

	public String getAddressProofType() {
		return addressProofType;
	}

	public void setAddressProofType(String v) {
		this.addressProofType = v;
	}

	public String getProfilePhotoPath() {
		return profilePhotoPath;
	}

	public void setProfilePhotoPath(String v) {
		this.profilePhotoPath = v;
	}

	public String getAadhaarFrontPath() {
		return aadhaarFrontPath;
	}

	public void setAadhaarFrontPath(String v) {
		this.aadhaarFrontPath = v;
	}

	public String getAadhaarBackPath() {
		return aadhaarBackPath;
	}

	public void setAadhaarBackPath(String v) {
		this.aadhaarBackPath = v;
	}

	public String getPanImagePath() {
		return panImagePath;
	}

	public void setPanImagePath(String v) {
		this.panImagePath = v;
	}

	public String getDlFrontPath() {
		return dlFrontPath;
	}

	public void setDlFrontPath(String v) {
		this.dlFrontPath = v;
	}

	public String getDlBackPath() {
		return dlBackPath;
	}

	public void setDlBackPath(String v) {
		this.dlBackPath = v;
	}

	public String getAddressProofPath() {
		return addressProofPath;
	}

	public void setAddressProofPath(String v) {
		this.addressProofPath = v;
	}

	public String getVehicleType() {
		return vehicleType;
	}

	public void setVehicleType(String v) {
		this.vehicleType = v;
	}

	public String getVehicleOwnership() {
		return vehicleOwnership;
	}

	public void setVehicleOwnership(String v) {
		this.vehicleOwnership = v;
	}

	public String getFuelType() {
		return fuelType;
	}

	public void setFuelType(String v) {
		this.fuelType = v;
	}

	public String getVehicleBrand() {
		return vehicleBrand;
	}

	public void setVehicleBrand(String v) {
		this.vehicleBrand = v;
	}

	public String getVehicleModel() {
		return vehicleModel;
	}

	public void setVehicleModel(String v) {
		this.vehicleModel = v;
	}

	public String getVehicleYear() {
		return vehicleYear;
	}

	public void setVehicleYear(String v) {
		this.vehicleYear = v;
	}

	public String getVehicleRegNumber() {
		return vehicleRegNumber;
	}

	public void setVehicleRegNumber(String v) {
		this.vehicleRegNumber = v;
	}

	public String getVehicleColour() {
		return vehicleColour;
	}

	public void setVehicleColour(String v) {
		this.vehicleColour = v;
	}

	public String getInsuranceNumber() {
		return insuranceNumber;
	}

	public void setInsuranceNumber(String v) {
		this.insuranceNumber = v;
	}

	public String getInsuranceExpiry() {
		return insuranceExpiry;
	}

	public void setInsuranceExpiry(String v) {
		this.insuranceExpiry = v;
	}

	public String getPucNumber() {
		return pucNumber;
	}

	public void setPucNumber(String v) {
		this.pucNumber = v;
	}

	public String getPucExpiry() {
		return pucExpiry;
	}

	public void setPucExpiry(String v) {
		this.pucExpiry = v;
	}

	public String getPayloadKg() {
		return payloadKg;
	}

	public void setPayloadKg(String v) {
		this.payloadKg = v;
	}

	public String getDeliveryZone() {
		return deliveryZone;
	}

	public void setDeliveryZone(String v) {
		this.deliveryZone = v;
	}

	public String getRcBookPath() {
		return rcBookPath;
	}

	public void setRcBookPath(String v) {
		this.rcBookPath = v;
	}

	public String getVehiclePhotoPath() {
		return vehiclePhotoPath;
	}

	public void setVehiclePhotoPath(String v) {
		this.vehiclePhotoPath = v;
	}

	public String getInsuranceCertPath() {
		return insuranceCertPath;
	}

	public void setInsuranceCertPath(String v) {
		this.insuranceCertPath = v;
	}

	public String getPucCertPath() {
		return pucCertPath;
	}

	public void setPucCertPath(String v) {
		this.pucCertPath = v;
	}

	public String getBankAccName() {
		return bankAccName;
	}

	public void setBankAccName(String v) {
		this.bankAccName = v;
	}

	public String getBankName() {
		return bankName;
	}

	public void setBankName(String v) {
		this.bankName = v;
	}

	public String getBankAccNumber() {
		return bankAccNumber;
	}

	public void setBankAccNumber(String v) {
		this.bankAccNumber = v;
	}

	public String getIfscCode() {
		return ifscCode;
	}

	public void setIfscCode(String v) {
		this.ifscCode = v;
	}

	public String getBranchName() {
		return branchName;
	}

	public void setBranchName(String v) {
		this.branchName = v;
	}

	public String getAccountType() {
		return accountType;
	}

	public void setAccountType(String v) {
		this.accountType = v;
	}

	public String getUpiId() {
		return upiId;
	}

	public void setUpiId(String v) {
		this.upiId = v;
	}

	public String getBankProofPath() {
		return bankProofPath;
	}

	public void setBankProofPath(String v) {
		this.bankProofPath = v;
	}

	public String getEmergencyName() {
		return emergencyName;
	}

	public void setEmergencyName(String v) {
		this.emergencyName = v;
	}

	public String getEmergencyRelation() {
		return emergencyRelation;
	}

	public void setEmergencyRelation(String v) {
		this.emergencyRelation = v;
	}

	public String getEmergencyMobile() {
		return emergencyMobile;
	}

	public void setEmergencyMobile(String v) {
		this.emergencyMobile = v;
	}

	public String getStatus() {
		return status;
	}

	public void setStatus(String v) {
		this.status = v;
	}

	public String getAdminRemarks() {
		return adminRemarks;
	}

	public void setAdminRemarks(String v) {
		this.adminRemarks = v;
	}

	public String getSubmittedAt() {
		return submittedAt;
	}

	public void setSubmittedAt(String v) {
		this.submittedAt = v;
	}

	public String getReviewedAt() {
		return reviewedAt;
	}

	public void setReviewedAt(String v) {
		this.reviewedAt = v;
	}

	/** Convenience: full name */
	public String getFullName() {
		StringBuilder sb = new StringBuilder(firstName);
		if (middleName != null && !middleName.isBlank()) {
			sb.append(' ').append(middleName);
		}
		sb.append(' ').append(lastName);
		return sb.toString();
	}
}