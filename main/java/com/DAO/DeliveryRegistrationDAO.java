package com.DAO;

import java.security.MessageDigest;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;

import com.util.DeliveryRegistration;

/**
 * DeliveryRegistrationDAO
 * ─────────────────────────────────────────────────────────────────────────────
 * All database operations for the delivery-agent registration and admin-review
 * workflow.
 *
 * TABLE DEPENDENCY ──────────────── Operates on delivery_agent_registrations
 * (see schema SQL file). On approval, also INSERTs into users (the existing
 * table) with role='delivery' and status='inactive', ready for the first login.
 *
 * THREAD SAFETY ───────────── Each DAO instance holds a single Connection. Pass
 * a fresh connection from DBConnection.getConnection() for every servlet
 * request (try-with-resources).
 */
public class DeliveryRegistrationDAO {

	private final Connection conn;

	public DeliveryRegistrationDAO(Connection conn) {
		this.conn = conn;
	}

	// ─────────────────────────────────────────────────────────────────────────
	// DUPLICATE CHECKS
	// ─────────────────────────────────────────────────────────────────────────

	public boolean usernameExists(String username) throws SQLException {
		// Check both tables: an existing staff/delivery user AND a pending registration
		String sql = "SELECT 1 FROM users WHERE username = ? " + "UNION "
				+ "SELECT 1 FROM delivery_agent_registrations WHERE username = ? AND status != 'REJECTED'";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setString(1, username);
			ps.setString(2, username);
			try (ResultSet rs = ps.executeQuery()) {
				return rs.next();
			}
		}
	}

	public boolean mobileExists(String mobile) throws SQLException {
		String sql = "SELECT 1 FROM users WHERE mobile = ? " + "UNION "
				+ "SELECT 1 FROM delivery_agent_registrations WHERE mobile = ? AND status != 'REJECTED'";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setString(1, mobile);
			ps.setString(2, mobile);
			try (ResultSet rs = ps.executeQuery()) {
				return rs.next();
			}
		}
	}

	public boolean emailExists(String email) throws SQLException {
		String sql = "SELECT 1 FROM users WHERE email = ? " + "UNION "
				+ "SELECT 1 FROM delivery_agent_registrations WHERE email = ? AND status != 'REJECTED'";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setString(1, email);
			ps.setString(2, email);
			try (ResultSet rs = ps.executeQuery()) {
				return rs.next();
			}
		}
	}

	// ─────────────────────────────────────────────────────────────────────────
	// INSERT — new registration application
	// Returns the generated primary key (registration ID), or -1 on failure.
	// ─────────────────────────────────────────────────────────────────────────
	public int registerAgent(DeliveryRegistration reg, String rawPassword) throws SQLException {

		String hashedPassword = hashPassword(rawPassword);

		String sql = """
				INSERT INTO delivery_agent_registrations (
				  first_name, middle_name, last_name, dob, gender, blood_group,
				  username, password_hash, mobile, email, alt_mobile,
				  address_line1, address_line2, landmark, city, state, pincode,
				  aadhaar_number, aadhaar_name,
				  pan_number,
				  dl_number, dl_issue_date, dl_expiry_date,
				  address_proof_type,
				  profile_photo_path,
				  aadhaar_front_path, aadhaar_back_path,
				  pan_image_path,
				  dl_front_path, dl_back_path,
				  address_proof_path,
				  vehicle_type, vehicle_ownership, fuel_type,
				  vehicle_brand, vehicle_model, vehicle_year,
				  vehicle_reg_number, vehicle_colour,
				  payload_kg, delivery_zone,
				  rc_book_path, vehicle_photo_path,
				  insurance_number, insurance_expiry,
				  insurance_cert_path,
				  puc_number, puc_expiry, puc_cert_path,
				  bank_acc_name, bank_name, bank_acc_number,
				  ifsc_code, branch_name, account_type, upi_id,
				  bank_proof_path,
				  emergency_name, emergency_relation, emergency_mobile,
				  status, submitted_at
				) VALUES (
				  ?,?,?,?,?,?,
				  ?,?,?,?,?,
				  ?,?,?,?,?,?,
				  ?,?,
				  ?,
				  ?,?,?,
				  ?,
				  ?,
				  ?,?,
				  ?,
				  ?,?,
				  ?,
				  ?,?,?,
				  ?,?,?,
				  ?,?,
				  ?,?,
				  ?,?,
				  ?,?,
				  ?,
				  ?,?,?,
				  ?,?,?,
				  ?,?,?,?,
				  ?,
				  ?,?,?,
				  'PENDING', NOW()
				)
				""";

		try (PreparedStatement ps = conn.prepareStatement(sql, PreparedStatement.RETURN_GENERATED_KEYS)) {
			int i = 1;
			// Personal
			ps.setString(i++, reg.getFirstName());
			setNullable(ps, i++, reg.getMiddleName());
			ps.setString(i++, reg.getLastName());
			ps.setString(i++, reg.getDob());
			ps.setString(i++, reg.getGender());
			setNullable(ps, i++, reg.getBloodGroup());
			// Account
			ps.setString(i++, reg.getUsername());
			ps.setString(i++, hashedPassword);
			ps.setString(i++, reg.getMobile());
			ps.setString(i++, reg.getEmail());
			setNullable(ps, i++, reg.getAltMobile());
			// Address
			ps.setString(i++, reg.getAddressLine1());
			ps.setString(i++, reg.getAddressLine2());
			setNullable(ps, i++, reg.getLandmark());
			ps.setString(i++, reg.getCity());
			ps.setString(i++, reg.getState());
			ps.setString(i++, reg.getPincode());
			// KYC text
			ps.setString(i++, reg.getAadhaarNumber());
			ps.setString(i++, reg.getAadhaarName());
			ps.setString(i++, reg.getPanNumber());
			ps.setString(i++, reg.getDlNumber());
			setNullable(ps, i++, reg.getDlIssueDate());
			ps.setString(i++, reg.getDlExpiryDate());
			ps.setString(i++, reg.getAddressProofType());
			// KYC files
			setNullable(ps, i++, reg.getProfilePhotoPath());
			setNullable(ps, i++, reg.getAadhaarFrontPath());
			setNullable(ps, i++, reg.getAadhaarBackPath());
			setNullable(ps, i++, reg.getPanImagePath());
			setNullable(ps, i++, reg.getDlFrontPath());
			setNullable(ps, i++, reg.getDlBackPath());
			setNullable(ps, i++, reg.getAddressProofPath());
			// Vehicle text
			ps.setString(i++, reg.getVehicleType());
			ps.setString(i++, reg.getVehicleOwnership());
			ps.setString(i++, reg.getFuelType());
			ps.setString(i++, reg.getVehicleBrand());
			ps.setString(i++, reg.getVehicleModel());
			setNullable(ps, i++, reg.getVehicleYear());
			setNullable(ps, i++, reg.getVehicleRegNumber());
			setNullable(ps, i++, reg.getVehicleColour());
			setNullable(ps, i++, reg.getPayloadKg());
			ps.setString(i++, reg.getDeliveryZone());
			// Vehicle files
			setNullable(ps, i++, reg.getRcBookPath());
			setNullable(ps, i++, reg.getVehiclePhotoPath());
			// Insurance
			ps.setString(i++, reg.getInsuranceNumber());
			ps.setString(i++, reg.getInsuranceExpiry());
			setNullable(ps, i++, reg.getInsuranceCertPath());
			// PUC
			setNullable(ps, i++, reg.getPucNumber());
			setNullable(ps, i++, reg.getPucExpiry());
			setNullable(ps, i++, reg.getPucCertPath());
			// Bank
			ps.setString(i++, reg.getBankAccName());
			ps.setString(i++, reg.getBankName());
			ps.setString(i++, reg.getBankAccNumber());
			ps.setString(i++, reg.getIfscCode());
			ps.setString(i++, reg.getBranchName());
			ps.setString(i++, reg.getAccountType());
			setNullable(ps, i++, reg.getUpiId());
			setNullable(ps, i++, reg.getBankProofPath());
			// Emergency
			ps.setString(i++, reg.getEmergencyName());
			ps.setString(i++, reg.getEmergencyRelation());
			ps.setString(i++, reg.getEmergencyMobile());

			int rows = ps.executeUpdate();
			if (rows == 0) {
				return -1;
			}

			try (ResultSet keys = ps.getGeneratedKeys()) {
				return keys.next() ? keys.getInt(1) : -1;
			}
		}
	}

	// ─────────────────────────────────────────────────────────────────────────
	// READ — for admin review panel
	// ─────────────────────────────────────────────────────────────────────────

	/** All applications, newest first */
	public List<DeliveryRegistration> getAllRegistrations() throws SQLException {
		String sql = "SELECT * FROM delivery_agent_registrations ORDER BY submitted_at DESC";
		return query(sql);
	}

	/** Filtered by status: PENDING | APPROVED | REJECTED */
	public List<DeliveryRegistration> getByStatus(String status) throws SQLException {
		String sql = "SELECT * FROM delivery_agent_registrations WHERE status=? ORDER BY submitted_at DESC";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setString(1, status);
			return mapRows(ps.executeQuery());
		}
	}

	public DeliveryRegistration getById(int id) throws SQLException {
		String sql = "SELECT * FROM delivery_agent_registrations WHERE id=?";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, id);
			List<DeliveryRegistration> list = mapRows(ps.executeQuery());
			return list.isEmpty() ? null : list.get(0);
		}
	}

	// ─────────────────────────────────────────────────────────────────────────
	// ADMIN ACTIONS
	// ─────────────────────────────────────────────────────────────────────────

	/**
	 * Approve a registration: 1. Updates delivery_agent_registrations.status →
	 * APPROVED 2. Inserts a row into `users` with role='delivery',
	 * status='inactive' so the agent can log in after the admin approves.
	 *
	 * Uses a transaction — either both succeed or neither does.
	 */

	public boolean approveRegistration(int registrationId, String adminRemarks) throws SQLException {
		conn.setAutoCommit(false);
		try {
			// Step 1: fetch the registration record
			DeliveryRegistration reg = getById(registrationId);
			if (reg == null) {
				throw new SQLException("Registration ID " + registrationId + " not found.");
			}

			// Step 2: mark registration as APPROVED
			String updateReg = "UPDATE delivery_agent_registrations "
					+ "SET status='APPROVED', admin_remarks=?, reviewed_at=NOW() " + "WHERE id=?";
			try (PreparedStatement ps = conn.prepareStatement(updateReg)) {
				setNullable(ps, 1, adminRemarks);
				ps.setInt(2, registrationId);
				ps.executeUpdate();
			}

			// Step 3: check if a users row already exists for this username
			// This handles the case where the agent was previously APPROVED,
			// then REJECTED, and the admin now re-approves — the user row
			// already exists so INSERT would throw a duplicate-key error.
			boolean userExists = false;
			String checkSql = "SELECT COUNT(*) FROM users WHERE username = ?";
			try (PreparedStatement ps = conn.prepareStatement(checkSql)) {
				ps.setString(1, reg.getUsername());
				try (ResultSet rs = ps.executeQuery()) {
					if (rs.next()) {
						userExists = rs.getInt(1) > 0;
					}
				}
			}

			if (userExists) {
				// Re-approval after rejection: user row exists, just reactivate it
				// Also refresh email and mobile in case the agent re-submitted
				// with corrected details before being re-approved.
				String reactivate = "UPDATE users " + "SET status='inactive', email=?, mobile=? "
						+ "WHERE username=? AND role='delivery'";
				try (PreparedStatement ps = conn.prepareStatement(reactivate)) {
					ps.setString(1, reg.getEmail());
					ps.setString(2, reg.getMobile());
					ps.setString(3, reg.getUsername());
					ps.executeUpdate();
				}
			} else {
				// First-time approval: create the user account.
				// Do NOT include created_at — let MySQL fill it via DEFAULT CURRENT_TIMESTAMP.
				String insertUser = """
						INSERT INTO users (username, password, email,gender, mobile, role, status, joining_date)
						SELECT username, password_hash, email,gender, mobile, 'delivery', 'inactive', NOW()
						FROM delivery_agent_registrations
						WHERE id = ?
						""";
				try (PreparedStatement ps = conn.prepareStatement(insertUser)) {
					ps.setInt(1, registrationId);
					ps.executeUpdate();
				}
			}

			conn.commit();
			return true;

		} catch (Exception e) {
			conn.rollback();
			throw new SQLException("Approval failed: " + e.getMessage(), e);
		} finally {
			conn.setAutoCommit(true);
		}
	}

	public boolean rejectRegistration(int registrationId, String adminRemarks) throws SQLException {
		String sql = "UPDATE delivery_agent_registrations SET status='REJECTED', admin_remarks=?, reviewed_at=NOW() WHERE id=?";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			setNullable(ps, 1, adminRemarks);
			ps.setInt(2, registrationId);
			return ps.executeUpdate() > 0;
		}
	}

	// ─────────────────────────────────────────────────────────────────────────
	// COUNT HELPERS (for admin dashboard badges)
	// ─────────────────────────────────────────────────────────────────────────

	public int countByStatus(String status) throws SQLException {
		String sql = "SELECT COUNT(*) FROM delivery_agent_registrations WHERE status=?";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setString(1, status);
			try (ResultSet rs = ps.executeQuery()) {
				return rs.next() ? rs.getInt(1) : 0;
			}
		}
	}

	// ─────────────────────────────────────────────────────────────────────────
	// PRIVATE HELPERS
	// ─────────────────────────────────────────────────────────────────────────

	private List<DeliveryRegistration> query(String sql) throws SQLException {
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			return mapRows(ps.executeQuery());
		}
	}

	private List<DeliveryRegistration> mapRows(ResultSet rs) throws SQLException {
		List<DeliveryRegistration> list = new ArrayList<>();
		while (rs.next()) {
			DeliveryRegistration r = new DeliveryRegistration();
			r.setId(rs.getInt("id"));
			r.setFirstName(rs.getString("first_name"));
			r.setMiddleName(rs.getString("middle_name"));
			r.setLastName(rs.getString("last_name"));
			r.setDob(rs.getString("dob"));
			r.setGender(rs.getString("gender"));
			r.setBloodGroup(rs.getString("blood_group"));
			r.setUsername(rs.getString("username"));
			r.setMobile(rs.getString("mobile"));
			r.setEmail(rs.getString("email"));
			r.setAltMobile(rs.getString("alt_mobile"));
			r.setAddressLine1(rs.getString("address_line1"));
			r.setAddressLine2(rs.getString("address_line2"));
			r.setLandmark(rs.getString("landmark"));
			r.setCity(rs.getString("city"));
			r.setState(rs.getString("state"));
			r.setPincode(rs.getString("pincode"));
			r.setAadhaarNumber(rs.getString("aadhaar_number"));
			r.setAadhaarName(rs.getString("aadhaar_name"));
			r.setPanNumber(rs.getString("pan_number"));
			r.setDlNumber(rs.getString("dl_number"));
			r.setDlIssueDate(rs.getString("dl_issue_date"));
			r.setDlExpiryDate(rs.getString("dl_expiry_date"));
			r.setAddressProofType(rs.getString("address_proof_type"));
			r.setProfilePhotoPath(rs.getString("profile_photo_path"));
			r.setAadhaarFrontPath(rs.getString("aadhaar_front_path"));
			r.setAadhaarBackPath(rs.getString("aadhaar_back_path"));
			r.setPanImagePath(rs.getString("pan_image_path"));
			r.setDlFrontPath(rs.getString("dl_front_path"));
			r.setDlBackPath(rs.getString("dl_back_path"));
			r.setAddressProofPath(rs.getString("address_proof_path"));
			r.setVehicleType(rs.getString("vehicle_type"));
			r.setVehicleOwnership(rs.getString("vehicle_ownership"));
			r.setFuelType(rs.getString("fuel_type"));
			r.setVehicleBrand(rs.getString("vehicle_brand"));
			r.setVehicleModel(rs.getString("vehicle_model"));
			r.setVehicleYear(rs.getString("vehicle_year"));
			r.setVehicleRegNumber(rs.getString("vehicle_reg_number"));
			r.setVehicleColour(rs.getString("vehicle_colour"));
			r.setPayloadKg(rs.getString("payload_kg"));
			r.setDeliveryZone(rs.getString("delivery_zone"));
			r.setRcBookPath(rs.getString("rc_book_path"));
			r.setVehiclePhotoPath(rs.getString("vehicle_photo_path"));
			r.setInsuranceNumber(rs.getString("insurance_number"));
			r.setInsuranceExpiry(rs.getString("insurance_expiry"));
			r.setInsuranceCertPath(rs.getString("insurance_cert_path"));
			r.setPucNumber(rs.getString("puc_number"));
			r.setPucExpiry(rs.getString("puc_expiry"));
			r.setPucCertPath(rs.getString("puc_cert_path"));
			r.setBankAccName(rs.getString("bank_acc_name"));
			r.setBankName(rs.getString("bank_name"));
			r.setBankAccNumber(rs.getString("bank_acc_number"));
			r.setIfscCode(rs.getString("ifsc_code"));
			r.setBranchName(rs.getString("branch_name"));
			r.setAccountType(rs.getString("account_type"));
			r.setUpiId(rs.getString("upi_id"));
			r.setBankProofPath(rs.getString("bank_proof_path"));
			r.setEmergencyName(rs.getString("emergency_name"));
			r.setEmergencyRelation(rs.getString("emergency_relation"));
			r.setEmergencyMobile(rs.getString("emergency_mobile"));
			r.setStatus(rs.getString("status"));
			r.setAdminRemarks(rs.getString("admin_remarks"));
			r.setSubmittedAt(rs.getString("submitted_at"));
			r.setReviewedAt(rs.getString("reviewed_at"));
			list.add(r);
		}
		return list;
	}

	public void updateDocumentPaths(int agentId, DeliveryRegistration reg) throws SQLException {
		String sql = """
				    UPDATE delivery_agent_registrations SET
				      profile_photo_path   = ?,
				      aadhaar_front_path   = ?,
				      aadhaar_back_path    = ?,
				      pan_image_path       = ?,
				      dl_front_path        = ?,
				      dl_back_path         = ?,
				      address_proof_path   = ?,
				      rc_book_path         = ?,
				      vehicle_photo_path   = ?,
				      insurance_cert_path  = ?,
				      puc_cert_path        = ?,
				      bank_proof_path      = ?
				    WHERE id = ?
				""";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setString(1, reg.getProfilePhotoPath());
			ps.setString(2, reg.getAadhaarFrontPath());
			ps.setString(3, reg.getAadhaarBackPath());
			ps.setString(4, reg.getPanImagePath());
			ps.setString(5, reg.getDlFrontPath());
			ps.setString(6, reg.getDlBackPath());
			ps.setString(7, reg.getAddressProofPath());
			ps.setString(8, reg.getRcBookPath());
			ps.setString(9, reg.getVehiclePhotoPath());
			ps.setString(10, reg.getInsuranceCertPath());
			ps.setString(11, reg.getPucCertPath());
			ps.setString(12, reg.getBankProofPath());
			ps.setInt(13, agentId);
			ps.executeUpdate();
		}
	}

	private void setNullable(PreparedStatement ps, int idx, String value) throws SQLException {
		if (value == null || value.isBlank()) {
			ps.setNull(idx, Types.VARCHAR);
		} else {
			ps.setString(idx, value);
		}
	}

	private String hashPassword(String password) {
		try {
			MessageDigest md = MessageDigest.getInstance("SHA-256");
			byte[] bytes = md.digest(password.getBytes("UTF-8"));
			StringBuilder sb = new StringBuilder();
			for (byte b : bytes) {
				sb.append(String.format("%02x", b));
			}
			return sb.toString();
		} catch (Exception e) {
			throw new RuntimeException("Password hashing failed", e);
		}
	}

	public DeliveryRegistration getByUsername(String username) throws SQLException {
		String sql = "SELECT * FROM delivery_agent_registrations WHERE username = ? LIMIT 1";
		try (PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setString(1, username);
			List<DeliveryRegistration> list = mapRows(ps.executeQuery());
			return list.isEmpty() ? null : list.get(0);
		}
	}

}