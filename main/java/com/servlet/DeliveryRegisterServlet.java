package com.servlet;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.sql.Connection;
import java.util.UUID;
import java.util.logging.Level;
import java.util.logging.Logger;

import com.DAO.DeliveryRegistrationDAO;
import com.util.DBConnection;
import com.util.DeliveryRegistration;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import jakarta.servlet.http.Part;

/**
 * DeliveryRegisterServlet
 * ─────────────────────────────────────────────────────────────────────────────
 *
 * WHY TWO ACTIONS INSTEAD OF ONE FORM SUBMIT?
 * ─────────────────────────────────────────────────────────────────────────────
 * Tomcat 9's multipart parser counts EVERY part (text fields + file inputs)
 * against its internal limit. This registration form has ~48 text fields + 12
 * file inputs = ~60 parts, which exceeds the default and throws:
 *
 * FileCountLimitExceededException: attachment
 *
 * The fix — without touching server.xml or any Tomcat config — is to split the
 * single submit into two sequential requests sent by JavaScript:
 *
 * REQUEST 1 — action=saveDetails (Content-Type:
 * application/x-www-form-urlencoded) • Carries ONLY the ~48 text fields. No
 * files, no multipart. • Tomcat parses it as a regular form — no part limit
 * applies at all. • Server validates all text fields and stores the data in
 * HttpSession. • Returns JSON { success:true } or { success:false,
 * message:"..." }
 *
 * REQUEST 2 — action=uploadDocs (Content-Type: multipart/form-data) • Carries
 * ONLY the 12 file inputs + one hidden "action" field = 13 parts. • 13 is well
 * under Tomcat's limit — no error. • Server reads the validated
 * DeliveryRegistration from session, saves the files, writes to DB, clears
 * session data. • Returns JSON { success:true, redirect:"..." } or error.
 *
 * The front-end intercepts the Submit click, fires Request 1 via fetch(), then
 * on success fires Request 2 via fetch() with a FormData of only files. The
 * user sees one seamless submit — the form UI is unchanged.
 *
 * See deliveryRegister.jsp for the corresponding two-step JavaScript.
 *
 * FILE STORAGE STRATEGY ───────────────────── All uploaded files are written to
 * an absolute directory OUTSIDE the webapp (configured via init-param
 * "uploadRootDir" in web.xml). The DB stores only the relative path under that
 * root.
 */
// URL mapping is declared in web.xml — do NOT add @WebServlet here.
// Having both web.xml mappings and @WebServlet on the same servlet causes a
// Tomcat deployment conflict and the app will fail to start.
@MultipartConfig(fileSizeThreshold = 1024 * 1024, // 1 MB — buffer in memory before writing to tmp
		maxFileSize = 10 * 1024 * 1024, // 10 MB per individual file
		maxRequestSize = 20 * 1024 * 1024 // 20 MB — only files in this request now, no text fields
)
public class DeliveryRegisterServlet extends HttpServlet {

	private static final long serialVersionUID = 1L;
	private static final Logger log = Logger.getLogger(DeliveryRegisterServlet.class.getName());

	/** Session key used to pass validated text data between the two requests. */
	private static final String SESSION_KEY = "pendingAgentRegistration";

	/** Absolute root where all agent documents are permanently stored. */
	private String uploadRootDir;

	// ─────────────────────────────────────────────────────────────────────────
	@Override
	public void init() throws ServletException {
		uploadRootDir = getInitParameter("uploadRootDir");
		if (uploadRootDir == null || uploadRootDir.isBlank()) {
			boolean isWindows = System.getProperty("os.name", "").toLowerCase().contains("win");
			uploadRootDir = isWindows ? "C:/delivery_uploads/KYC_docs" : "/var/app/delivery_uploads/KYC_docs";
			log.warning("uploadRootDir not configured in web.xml — falling back to: " + uploadRootDir);
		}
		try {
			uploadRootDir = new File(uploadRootDir).getCanonicalPath();
		} catch (IOException e) {
			throw new ServletException("Cannot resolve uploadRootDir: " + uploadRootDir, e);
		}
		File root = new File(uploadRootDir);
		if (!root.exists() && !root.mkdirs()) {
			throw new ServletException("Cannot create upload root: " + uploadRootDir
					+ " — ensure path is outside Maven project and Tomcat has write permission.");
		}
		log.info("DeliveryRegisterServlet initialised | uploadRootDir=" + uploadRootDir);
	}

	// ─────────────────────────────────────────────────────────────────────────
	// GET — show the registration form
	// ─────────────────────────────────────────────────────────────────────────
	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		// FIX: forward to the JSP that is placed directly under webapp root.
		// If deliveryRegister.jsp is inside WEB-INF use
		// "/WEB-INF/views/deliveryRegister.jsp".
		request.getRequestDispatcher("/WEB-INF/views/deliveryRegister.jsp").forward(request, response);
	}

	// ─────────────────────────────────────────────────────────────────────────
	// POST — route by "action" parameter
	// ─────────────────────────────────────────────────────────────────────────
	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		// getParameter() is safe here because:
		// • saveDetails request is application/x-www-form-urlencoded — multipart parser
		// never runs.
		// • uploadDocs request is multipart but has only 13 parts (12 files + 1 hidden
		// field).
		// Neither request approaches Tomcat's part limit.
		String action = request.getParameter("action");

		if ("saveDetails".equals(action)) {
			doSaveDetails(request, response);
		} else if ("uploadDocs".equals(action)) {
			doUploadDocs(request, response);
		} else {
			sendJson(response, false, "Unknown action: " + action);
		}
	}

	// ─────────────────────────────────────────────────────────────────────────
	// ACTION 1 — saveDetails
	// Content-Type: application/x-www-form-urlencoded (NO files, NO multipart)
	// Validates all text fields, stores DeliveryRegistration in session.
	// Returns JSON.
	// ─────────────────────────────────────────────────────────────────────────
	private void doSaveDetails(HttpServletRequest request, HttpServletResponse response) throws IOException {

		request.setCharacterEncoding("UTF-8");

		DeliveryRegistration reg = new DeliveryRegistration();

		// ── Personal ──────────────────────────────────────────────────────────
		reg.setFirstName(trim(request, "firstName"));
		reg.setMiddleName(trim(request, "middleName"));
		reg.setLastName(trim(request, "lastName"));
		reg.setDob(trim(request, "dob"));
		reg.setGender(trim(request, "gender"));
		reg.setBloodGroup(trim(request, "bloodGroup"));
		reg.setUsername(trim(request, "username"));
		reg.setMobile(trim(request, "mobile"));
		reg.setEmail(trim(request, "email"));
		reg.setAltMobile(trim(request, "altMobile"));

		// ── Address ───────────────────────────────────────────────────────────
		reg.setAddressLine1(trim(request, "addressLine1"));
		reg.setAddressLine2(trim(request, "addressLine2"));
		reg.setLandmark(trim(request, "landmark"));
		reg.setCity(trim(request, "city"));
		reg.setState(trim(request, "state"));
		reg.setPincode(trim(request, "pincode"));

		// ── KYC ───────────────────────────────────────────────────────────────
		reg.setAadhaarNumber(trim(request, "aadhaarNumber"));
		reg.setAadhaarName(trim(request, "aadhaarName"));
		reg.setPanNumber(trim(request, "panNumber").toUpperCase());
		reg.setDlNumber(trim(request, "dlNumber").toUpperCase());
		reg.setDlIssueDate(trim(request, "dlIssueDate"));
		reg.setDlExpiryDate(trim(request, "dlExpiryDate"));
		reg.setAddressProofType(trim(request, "addressProofType"));

		// ── Vehicle ───────────────────────────────────────────────────────────
		reg.setVehicleType(trim(request, "vehicleType"));
		reg.setVehicleOwnership(trim(request, "vehicleOwnership"));
		reg.setFuelType(trim(request, "fuelType"));
		reg.setVehicleBrand(trim(request, "vehicleBrand"));
		reg.setVehicleModel(trim(request, "vehicleModel"));
		reg.setVehicleYear(trim(request, "vehicleYear"));
		reg.setVehicleRegNumber(trim(request, "vehicleRegNumber").toUpperCase());
		reg.setVehicleColour(trim(request, "vehicleColour"));
		reg.setInsuranceNumber(trim(request, "insuranceNumber"));
		reg.setInsuranceExpiry(trim(request, "insuranceExpiry"));
		reg.setPucNumber(trim(request, "pucNumber"));
		reg.setPucExpiry(trim(request, "pucExpiry"));
		reg.setPayloadKg(trim(request, "payloadKg"));
		reg.setDeliveryZone(trim(request, "deliveryZone"));

		// ── Bank ──────────────────────────────────────────────────────────────
		reg.setBankAccName(trim(request, "bankAccName"));
		reg.setBankName(trim(request, "bankName"));
		reg.setBankAccNumber(trim(request, "bankAccNumber"));
		reg.setIfscCode(trim(request, "ifscCode").toUpperCase());
		reg.setBranchName(trim(request, "branchName"));
		reg.setAccountType(trim(request, "accountType"));
		reg.setUpiId(trim(request, "upiId"));

		// ── Emergency ─────────────────────────────────────────────────────────
		reg.setEmergencyName(trim(request, "emergencyName"));
		reg.setEmergencyRelation(trim(request, "emergencyRelation"));
		reg.setEmergencyMobile(trim(request, "emergencyMobile"));

		// Password kept separate — never stored in DeliveryRegistration object
		String rawPassword = trim(request, "password");
		String confirmPassword = trim(request, "confirmPassword");
		String bankAccConfirm = trim(request, "bankAccNumberConfirm");

		// ── Validate ──────────────────────────────────────────────────────────
		String err = serverValidate(reg, rawPassword, confirmPassword, bankAccConfirm);
		if (err != null) {
			sendJson(response, false, err);
			return;
		}

		// ── Duplicate checks (DB) ─────────────────────────────────────────────
		try (Connection conn = DBConnection.getConnection()) {
			DeliveryRegistrationDAO dao = new DeliveryRegistrationDAO(conn);
			if (dao.usernameExists(reg.getUsername())) {
				sendJson(response, false,
						"Username '" + reg.getUsername() + "' is already taken. Please choose another.");
				return;
			}
			if (dao.mobileExists(reg.getMobile())) {
				sendJson(response, false, "Mobile number " + reg.getMobile() + " is already registered.");
				return;
			}
			if (dao.emailExists(reg.getEmail())) {
				sendJson(response, false, "Email " + reg.getEmail() + " is already registered.");
				return;
			}
		} catch (Exception e) {
			log.log(Level.SEVERE, "DB duplicate check failed", e);
			sendJson(response, false, "Server error during validation. Please try again.");
			return;
		}

		// ── Store in session for pickup by uploadDocs ─────────────────────────
		HttpSession session = request.getSession(true);
		session.setAttribute(SESSION_KEY, reg);
		session.setAttribute(SESSION_KEY + "_pwd", rawPassword);

		log.info("saveDetails OK — username=" + reg.getUsername() + " | awaiting file upload");
		sendJson(response, true, "Details saved. Uploading documents...");
	}

	// ─────────────────────────────────────────────────────────────────────────
	// ACTION 2 — uploadDocs
	// Content-Type: multipart/form-data (ONLY 12 file parts + 1 hidden = 13 total)
	// Reads validated DeliveryRegistration from session, saves files, writes to DB.
	// Returns JSON { success:true, redirect:"..." } or error.
	// ─────────────────────────────────────────────────────────────────────────
	private void doUploadDocs(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		HttpSession session = request.getSession(false);
		DeliveryRegistration reg = (session != null) ? (DeliveryRegistration) session.getAttribute(SESSION_KEY) : null;
		String rawPassword = (session != null) ? (String) session.getAttribute(SESSION_KEY + "_pwd") : null;

		if (reg == null || rawPassword == null) {
			sendJson(response, false, "Session expired. Please fill in your details again.");
			return;
		}

		// Step 1 — Save files to a temp folder (same as before)
		String tempFolder = "pending_" + reg.getUsername() + "_" + System.currentTimeMillis();
		String tempDir = uploadRootDir + File.separator + "agent_docs" + File.separator + tempFolder;
		new File(tempDir).mkdirs();

		try {
			reg.setProfilePhotoPath(savePart(request, "profilePhoto", tempDir, "profile_photo"));
			reg.setAadhaarFrontPath(savePart(request, "aadhaarFront", tempDir, "aadhaar_front"));
			reg.setAadhaarBackPath(savePart(request, "aadhaarBack", tempDir, "aadhaar_back"));
			reg.setPanImagePath(savePart(request, "panImage", tempDir, "pan_card"));
			reg.setDlFrontPath(savePart(request, "dlFront", tempDir, "dl_front"));
			reg.setDlBackPath(savePart(request, "dlBack", tempDir, "dl_back"));
			reg.setAddressProofPath(savePart(request, "addressProof", tempDir, "address_proof"));
			reg.setRcBookPath(savePart(request, "rcBook", tempDir, "rc_book"));
			reg.setVehiclePhotoPath(savePart(request, "vehiclePhoto", tempDir, "vehicle_photo"));
			reg.setInsuranceCertPath(savePart(request, "insuranceCert", tempDir, "insurance_cert"));
			reg.setPucCertPath(savePart(request, "pucCert", tempDir, "puc_cert"));
			reg.setBankProofPath(savePart(request, "bankProof", tempDir, "bank_proof"));
		} catch (IOException ex) {
			log.log(Level.SEVERE, "File upload failed for: " + reg.getUsername(), ex);
			sendJson(response, false, "File upload failed: " + ex.getMessage());
			return;
		}

		try (Connection conn = DBConnection.getConnection()) {
			DeliveryRegistrationDAO dao = new DeliveryRegistrationDAO(conn);

			// Step 2 — Insert with pending_ paths to get the real DB id
			int newId = dao.registerAgent(reg, rawPassword);
			if (newId <= 0) {
				sendJson(response, false, "Registration failed. Please try again.");
				return;
			}

			// Step 3 — Rename temp folder to agent_{id}
			File oldDir = new File(tempDir);
			String finalFolderName = "agent_" + newId;
			File newDir = new File(uploadRootDir + File.separator + "agent_docs" + File.separator + finalFolderName);

			if (!oldDir.renameTo(newDir)) {
				log.warning("Rename failed: " + tempDir + " → " + newDir.getAbsolutePath());
				// Non-fatal — files are still accessible at the pending_ path
			}

			// Step 4 — Rewrite paths from pending_xxx/ to agent_{id}/ and UPDATE DB
			if (newDir.exists()) {
				updatePaths(reg, tempFolder, finalFolderName);
				dao.updateDocumentPaths(newId, reg); // ← new DAO method (see below)
			}

			// Clean up session
			session.removeAttribute(SESSION_KEY);
			session.removeAttribute(SESSION_KEY + "_pwd");

			log.info("Agent registered: ID=" + newId + " username=" + reg.getUsername());
			sendJsonRedirect(response, request.getContextPath() + "/deliveryLogin.jsp?registered=1");

		} catch (Exception e) {
			log.log(Level.SEVERE, "DB error for: " + reg.getUsername(), e);
			sendJson(response, false, "A server error occurred. Please try again.");
		}
	}

	// Replaces "pending_xxx" segment in every stored path with "agent_{id}"
	private void updatePaths(DeliveryRegistration reg, String oldFolder, String newFolder) {
		reg.setProfilePhotoPath(replacePath(reg.getProfilePhotoPath(), oldFolder, newFolder));
		reg.setAadhaarFrontPath(replacePath(reg.getAadhaarFrontPath(), oldFolder, newFolder));
		reg.setAadhaarBackPath(replacePath(reg.getAadhaarBackPath(), oldFolder, newFolder));
		reg.setPanImagePath(replacePath(reg.getPanImagePath(), oldFolder, newFolder));
		reg.setDlFrontPath(replacePath(reg.getDlFrontPath(), oldFolder, newFolder));
		reg.setDlBackPath(replacePath(reg.getDlBackPath(), oldFolder, newFolder));
		reg.setAddressProofPath(replacePath(reg.getAddressProofPath(), oldFolder, newFolder));
		reg.setRcBookPath(replacePath(reg.getRcBookPath(), oldFolder, newFolder));
		reg.setVehiclePhotoPath(replacePath(reg.getVehiclePhotoPath(), oldFolder, newFolder));
		reg.setInsuranceCertPath(replacePath(reg.getInsuranceCertPath(), oldFolder, newFolder));
		reg.setPucCertPath(replacePath(reg.getPucCertPath(), oldFolder, newFolder));
		reg.setBankProofPath(replacePath(reg.getBankProofPath(), oldFolder, newFolder));
	}

	private String replacePath(String path, String oldSeg, String newSeg) {
		if (path == null) {
			return null;
		}
		return path.replace(oldSeg, newSeg);
	}

	// ─────────────────────────────────────────────────────────────────────────
	// HELPER — save one Part to disk, return relative path for DB storage
	// ─────────────────────────────────────────────────────────────────────────
	private String savePart(HttpServletRequest request, String partName, String dirPath, String filePrefix)
			throws IOException, ServletException {

		Part part = request.getPart(partName);
		if (part == null || part.getSize() == 0) {
			return null;
		}

		String originalName = Paths.get(part.getSubmittedFileName()).getFileName().toString();
		String ext = "";
		int dot = originalName.lastIndexOf('.');
		if (dot >= 0) {
			ext = originalName.substring(dot).toLowerCase();
		}

		String safeName = filePrefix + "_" + UUID.randomUUID().toString().replace("-", "").substring(0, 12) + ext;
		File dest = new File(dirPath, safeName);

		try (InputStream in = part.getInputStream()) {
			Files.copy(in, dest.toPath(), StandardCopyOption.REPLACE_EXISTING);
		}

		return dest.getAbsolutePath().replace(uploadRootDir + File.separator, "");
	}

	// ─────────────────────────────────────────────────────────────────────────
	// HELPER — validate all text fields
	// ─────────────────────────────────────────────────────────────────────────
	private String serverValidate(DeliveryRegistration reg, String password, String confirmPassword,
			String bankAccConfirm) {
		if (blank(reg.getFirstName())) {
			return "First name is required.";
		}
		if (blank(reg.getLastName())) {
			return "Last name is required.";
		}
		if (blank(reg.getDob())) {
			return "Date of birth is required.";
		}
		if (blank(reg.getGender())) {
			return "Gender is required.";
		}
		if (blank(reg.getUsername())) {
			return "Username is required.";
		}
		if (blank(reg.getMobile())) {
			return "Mobile number is required.";
		}
		if (!reg.getMobile().matches("[6-9][0-9]{9}")) {
			return "Mobile number must be a valid 10-digit Indian number.";
		}
		if (blank(reg.getEmail())) {
			return "Email address is required.";
		}
		if (blank(password)) {
			return "Password is required.";
		}
		if (password.length() < 8) {
			return "Password must be at least 8 characters.";
		}
		if (!password.equals(confirmPassword)) {
			return "Passwords do not match.";
		}
		if (blank(reg.getAddressLine1())) {
			return "Address (door/flat) is required.";
		}
		if (blank(reg.getAddressLine2())) {
			return "Street/area is required.";
		}
		if (blank(reg.getCity())) {
			return "City is required.";
		}
		if (blank(reg.getState())) {
			return "State is required.";
		}
		if (blank(reg.getPincode())) {
			return "Pincode is required.";
		}
		if (blank(reg.getAadhaarNumber()) || !reg.getAadhaarNumber().matches("[0-9]{12}")) {
			return "Valid 12-digit Aadhaar number is required.";
		}
		if (blank(reg.getPanNumber()) || !reg.getPanNumber().matches("[A-Z]{5}[0-9]{4}[A-Z]")) {
			return "Valid PAN number is required (e.g. ABCDE1234F).";
		}
		if (blank(reg.getDlNumber())) {
			return "Driving Licence number is required.";
		}
		if (blank(reg.getDlExpiryDate())) {
			return "DL expiry date is required.";
		}
		if (blank(reg.getVehicleType())) {
			return "Vehicle type is required.";
		}
		if (blank(reg.getFuelType())) {
			return "Fuel type is required.";
		}
		if (blank(reg.getVehicleBrand())) {
			return "Vehicle brand is required.";
		}
		if (blank(reg.getVehicleModel())) {
			return "Vehicle model is required.";
		}
		if (blank(reg.getDeliveryZone())) {
			return "Preferred delivery zone is required.";
		}
		if (blank(reg.getBankAccName())) {
			return "Bank account holder name is required.";
		}
		if (blank(reg.getBankName())) {
			return "Bank name is required.";
		}
		if (blank(reg.getBankAccNumber())) {
			return "Bank account number is required.";
		}
		if (!reg.getBankAccNumber().matches("[0-9]{9,18}")) {
			return "Bank account number must be 9–18 digits.";
		}
		if (!reg.getBankAccNumber().equals(bankAccConfirm)) {
			return "Bank account numbers do not match.";
		}
		if (blank(reg.getIfscCode()) || !reg.getIfscCode().matches("[A-Z]{4}0[A-Z0-9]{6}")) {
			return "Valid IFSC code is required (e.g. SBIN0001234).";
		}
		if (blank(reg.getEmergencyName())) {
			return "Emergency contact name is required.";
		}
		if (blank(reg.getEmergencyMobile())) {
			return "Emergency contact mobile is required.";
		}
		return null;
	}

	// ─────────────────────────────────────────────────────────────────────────
	// JSON response helpers
	// ─────────────────────────────────────────────────────────────────────────
	private void sendJson(HttpServletResponse response, boolean success, String message) throws IOException {
		response.setContentType("application/json");
		response.setCharacterEncoding("UTF-8");
		String msg = (message != null) ? message.replace("\\", "\\\\").replace("\"", "'") : "";
		response.getWriter().write("{\"success\":" + success + ",\"message\":\"" + msg + "\"}");
	}

	private void sendJsonRedirect(HttpServletResponse response, String url) throws IOException {
		response.setContentType("application/json");
		response.setCharacterEncoding("UTF-8");
		response.getWriter().write("{\"success\":true,\"redirect\":\"" + url + "\"}");
	}

	private static String trim(HttpServletRequest req, String name) {
		String v = req.getParameter(name);
		return (v == null) ? "" : v.trim();
	}

	private static boolean blank(String s) {
		return s == null || s.isBlank();
	}
}