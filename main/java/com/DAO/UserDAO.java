package com.DAO;

import java.security.MessageDigest;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

import com.util.DBConnection;
import com.util.User;

public class UserDAO {

	// ── Check if any admin exists ──────────────────────────────────────────────
	public boolean checkIfAdminExists() {
		boolean exists = false;
		try (Connection con = DBConnection.getConnection()) {

			try (PreparedStatement psUsers = con.prepareStatement("SELECT COUNT(*) FROM users WHERE role='admin'");
					ResultSet rsUsers = psUsers.executeQuery()) {
				if (rsUsers.next() && rsUsers.getInt(1) > 0) {
					exists = true;
				}
			}

			try (PreparedStatement psAdmin = con.prepareStatement("SELECT COUNT(*) FROM admin");
					ResultSet rsAdmin = psAdmin.executeQuery()) {
				if (rsAdmin.next() && rsAdmin.getInt(1) > 0) {
					exists = true;
				}
			}

			System.out.println("checkIfAdminExists(): " + (exists ? "Admin found" : "No admin found"));
		} catch (Exception e) {
			e.printStackTrace();
		}
		return exists;
	}

	// ── Centralized password hashing ───────────────────────────────────────────
	private String hashPassword(String password) {
		try {
			MessageDigest md = MessageDigest.getInstance("SHA-256");
			byte[] hashedBytes = md.digest(password.getBytes());
			StringBuilder sb = new StringBuilder();
			for (byte b : hashedBytes) {
				sb.append(String.format("%02x", b));
			}
			return sb.toString();
		} catch (Exception e) {
			throw new RuntimeException("Error hashing password", e);
		}
	}

	// ── Register admin in both tables ──────────────────────────────────────────
	public boolean registerAdmin(User user) {
		boolean success = false;
		try (Connection conn = DBConnection.getConnection()) {
			String hashedPwd = hashPassword(user.getPassword());

			try (PreparedStatement psAdmin = conn
					.prepareStatement("INSERT INTO admin (username, password) VALUES (?, ?)")) {
				psAdmin.setString(1, user.getUsername());
				psAdmin.setString(2, hashedPwd);
				psAdmin.executeUpdate();
			}

			try (PreparedStatement psUser = conn.prepareStatement(
					"INSERT INTO users (username, password, role, status, email, mobile, country_code, "
							+ "address, gender, admin_level, privileges) VALUES (?,?,?,?,?,?,?,?,?,?,?)")) {
				psUser.setString(1, user.getUsername());
				psUser.setString(2, hashedPwd);
				psUser.setString(3, "admin");
				psUser.setString(4, user.getStatus());
				psUser.setString(5, user.getEmail());
				psUser.setString(6, user.getMobileno());
				psUser.setString(7, user.getCountryCode());
				psUser.setString(8, user.getAddress());
				psUser.setString(9, user.getGender());
				psUser.setString(10, user.getAdminLevel());
				psUser.setString(11, user.getPrivileges());
				psUser.executeUpdate();
			}

			success = true;
		} catch (Exception e) {
			e.printStackTrace();
		}
		return success;
	}

	// ── Register normal / staff user ───────────────────────────────────────────
	/**
	 * BUG FIX: The original registerUser had a 14-placeholder INSERT for staff
	 * (username, password, role, status, email, mobile, address, gender,
	 * employee_id, department, shift, supervisor, joining_date) but the SQL string
	 * contained an extra placeholder comma after "shift", which misaligned all
	 * parameter indices and caused SQLExceptions.
	 *
	 * NEW: shift_id (Integer FK → office_shifts) replaces the legacy
	 * shift/shiftTimings string columns for new registrations. The INSERT now
	 * stores shift_id.
	 */
	public boolean registerUser(User user) {
		boolean success = false;
		try (Connection conn = DBConnection.getConnection()) {
			String hashedPwd = hashPassword(user.getPassword());
			PreparedStatement ps;

			if ("staff".equalsIgnoreCase(user.getRole())) {
				// 14 columns, 14 placeholders
				ps = conn.prepareStatement("INSERT INTO users "
						+ "(username, password, role, status, email, mobile, country_code, address, gender, "
						+ " employee_id, department, shift_id, supervisor, joining_date) "
						+ "VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)");

				// Common fields (1–9)
				ps.setString(1, user.getUsername());
				ps.setString(2, hashedPwd);
				ps.setString(3, user.getRole());
				ps.setString(4, user.getStatus());
				ps.setString(5, user.getEmail());
				ps.setString(6, user.getMobileno());
				ps.setString(7, user.getCountryCode());
				ps.setString(8, user.getAddress());
				ps.setString(9, user.getGender());

				// Staff-specific fields (10–14)
				ps.setString(10, user.getEmployeeId());
				ps.setString(11, user.getDepartment());
				// shift_id — store as INT (FK) or NULL
				if (user.getShiftId() > 0) {
					ps.setInt(12, user.getShiftId());
				} else {
					ps.setNull(12, java.sql.Types.INTEGER);
				}
				ps.setString(13, user.getSupervisor());
				ps.setDate(14, user.getJoiningDate());

			} else {
				ps = conn.prepareStatement(
						"INSERT INTO users (username, password, role, status, email, mobile, country_code, address, gender) "
								+ "VALUES (?,?,?,?,?,?,?,?,?)");

				ps.setString(1, user.getUsername());
				ps.setString(2, hashedPwd);
				ps.setString(3, user.getRole());
				ps.setString(4, user.getStatus());
				ps.setString(5, user.getEmail());
				ps.setString(6, user.getMobileno());
				ps.setString(7, user.getCountryCode());
				ps.setString(8, user.getAddress());
				ps.setString(9, user.getGender());
			}

			success = ps.executeUpdate() > 0;
			ps.close();
		} catch (Exception e) {
			e.printStackTrace();
		}
		return success;
	}

	// ── Validate login ─────────────────────────────────────────────────────────
	// ── Change password (verifies current, then updates to new hashed) ────────
	public boolean changePassword(String username, String currentPassword, String newPassword) {
		String hashedCurrent = hashPassword(currentPassword);
		String checkSql = "SELECT 1 FROM users WHERE username=? AND password=?";
		String updateSql = "UPDATE users SET password=? WHERE username=?";
		try (Connection conn = DBConnection.getConnection()) {
			try (PreparedStatement check = conn.prepareStatement(checkSql)) {
				check.setString(1, username);
				check.setString(2, hashedCurrent);
				try (java.sql.ResultSet rs = check.executeQuery()) {
					if (!rs.next()) {
						return false; // wrong current password
					}
				}
			}
			try (PreparedStatement ps = conn.prepareStatement(updateSql)) {
				ps.setString(1, hashPassword(newPassword));
				ps.setString(2, username);
				return ps.executeUpdate() > 0;
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
		return false;
	}

	public boolean validateLogin(String username, String password) {
		String hashedPwd = hashPassword(password);
		String sql = "SELECT 1 FROM users WHERE username = ? AND password = ? AND status = 'active'";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setString(1, username);
			ps.setString(2, hashedPwd);
			try (ResultSet rs = ps.executeQuery()) {
				return rs.next();
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
		return false;
	}

	public void updateLastLogin(int userId, java.sql.Timestamp loginTime) throws SQLException {
		String sql = "UPDATE users SET last_login=? WHERE id=?";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setTimestamp(1, loginTime);
			ps.setInt(2, userId);
			ps.executeUpdate();
		}
	}

	public List<User> getAllUsers() {
		List<User> users = new ArrayList<>();
		String sql = "SELECT * FROM users";
		try (Connection conn = DBConnection.getConnection();
				PreparedStatement ps = conn.prepareStatement(sql);
				ResultSet rs = ps.executeQuery()) {
			while (rs.next()) {
				User user = new User();
				user.setUsername(rs.getString("username"));
				user.setPassword(rs.getString("password"));
				user.setRole(rs.getString("role"));
				user.setStatus(rs.getString("status"));
				user.setEmail(rs.getString("email"));
				user.setMobileno(rs.getString("mobile"));
				user.setAddress(rs.getString("address"));
				user.setGender(rs.getString("gender"));
				user.setLastLogin(rs.getTimestamp("last_login"));

				// Staff fields
				user.setEmployeeId(rs.getString("employee_id"));
				user.setDepartment(rs.getString("department"));
				// BUG FIX: read shift_id (INT FK) instead of legacy shift string
				int shiftId = rs.getInt("shift_id");
				if (!rs.wasNull()) {
					user.setShiftId(shiftId);
				}
				user.setSupervisor(rs.getString("supervisor"));
				user.setJoiningDate(rs.getDate("joining_date"));

				// Admin fields
				user.setAdminLevel(rs.getString("admin_level"));
				user.setPrivileges(rs.getString("privileges"));
				users.add(user);
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
		return users;
	}

	// ── Fetch user details by username ─────────────────────────────────────────
	public User getUserByUsername(String username) {
		User user = null;
		String sql = "SELECT * FROM users WHERE username = ?";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setString(1, username);
			try (ResultSet rs = ps.executeQuery()) {
				if (rs.next()) {
					user = new User();
					user.setUsername(rs.getString("username"));
					user.setPassword(rs.getString("password"));
					user.setRole(rs.getString("role"));
					user.setStatus(rs.getString("status"));
					user.setEmail(rs.getString("email"));
					user.setMobileno(rs.getString("mobile"));
					user.setCountryCode(rs.getString("country_code"));
					user.setAddress(rs.getString("address"));
					user.setGender(rs.getString("gender"));
					user.setLastLogin(rs.getTimestamp("last_login"));

					// Staff fields
					user.setEmployeeId(rs.getString("employee_id"));
					user.setDepartment(rs.getString("department"));
					int shiftId = rs.getInt("shift_id");
					if (!rs.wasNull()) {
						user.setShiftId(shiftId);
					}
					user.setSupervisor(rs.getString("supervisor"));
					user.setJoiningDate(rs.getDate("joining_date"));

					// Admin fields
					user.setAdminLevel(rs.getString("admin_level"));
					user.setPrivileges(rs.getString("privileges"));

					// Profile image (column may not exist on older schemas – guard it)
					try {
						user.setProfileImage(rs.getString("profile_image"));
					} catch (Exception ignored) {
					}
				}
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
		return user;
	}

	/** Save profile image filename for a user. */
	public boolean updateProfileImage(String username, String filename) {
		String sql = "UPDATE users SET profile_image=? WHERE username=?";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setString(1, filename);
			ps.setString(2, username);
			return ps.executeUpdate() > 0;
		} catch (Exception e) {
			e.printStackTrace();
		}
		return false;
	}

	/** Remove profile image (reset to default). */
	public boolean deleteProfileImage(String username) {
		return updateProfileImage(username, null);
	}

	/**
	 * BUG FIX: The original updateUser set 11 parameters but index 7
	 * (shift_timings) was never set, causing an index gap — parameters 7–11 were
	 * shifted, so supervisor landed in shift_timings and username was unbound (NPE
	 * / wrong row).
	 *
	 * Also removes shift_timings from the UPDATE (legacy column replaced by
	 * shift_id FK).
	 */
	public boolean updateUser(User user) {
		boolean success = false;
		String sql = "UPDATE users SET email=?, mobile=?, country_code=?, address=?, status=?, "
				+ "department=?, shift_id=?, supervisor=?, admin_level=?, privileges=? " + "WHERE username=?";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setString(1, user.getEmail());
			ps.setString(2, user.getMobileno());
			ps.setString(3, user.getCountryCode());
			ps.setString(4, user.getAddress());
			ps.setString(5, user.getStatus());
			ps.setString(6, user.getDepartment());
			// shift_id: store INT or NULL
			if (user.getShiftId() > 0) {
				ps.setInt(7, user.getShiftId());
			} else {
				ps.setNull(7, java.sql.Types.INTEGER);
			}
			ps.setString(8, user.getSupervisor());
			ps.setString(9, user.getAdminLevel());
			ps.setString(10, user.getPrivileges());
			ps.setString(11, user.getUsername());
			success = ps.executeUpdate() > 0;
		} catch (Exception e) {
			e.printStackTrace();
		}
		return success;
	}

	// ── Get role ───────────────────────────────────────────────────────────────
	public String getUserRole(String username) {
		String sql = "SELECT role FROM users WHERE username = ?";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setString(1, username);
			try (ResultSet rs = ps.executeQuery()) {
				if (rs.next()) {
					return rs.getString("role");
				}
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
		return null;
	}

	/**
	 * BUG FIX: The original emailExists opened a connection but never closed it
	 * (connection was obtained inline without try-with-resources).
	 */
	public boolean emailExists(String email) throws SQLException {
		String sql = "SELECT 1 FROM users WHERE email = ?";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setString(1, email);
			try (ResultSet rs = ps.executeQuery()) {
				return rs.next();
			}
		}
	}

	// ── Get status ─────────────────────────────────────────────────────────────
	public String getUserStatus(String username) {
		String sql = "SELECT status FROM users WHERE username = ?";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setString(1, username);
			try (ResultSet rs = ps.executeQuery()) {
				if (rs.next()) {
					return rs.getString("status");
				}
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
		return null;
	}

	// ── Get user by email or mobile ────────────────────────────────────────────
	public User getUserByIdentifier(String identifier) {
		User user = null;
		String sql = "SELECT * FROM users WHERE email = ? OR mobile = ?";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setString(1, identifier);
			ps.setString(2, identifier);
			try (ResultSet rs = ps.executeQuery()) {
				if (rs.next()) {
					user = new User();
					user.setUsername(rs.getString("username"));
					user.setEmail(rs.getString("email"));
					user.setMobileno(rs.getString("mobile"));
					user.setPassword(rs.getString("password"));
					user.setRole(rs.getString("role"));
					user.setStatus(rs.getString("status"));
					user.setAddress(rs.getString("address"));
					user.setGender(rs.getString("gender"));
				}
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
		return user;
	}

	// ── Delivery user support ──────────────────────────────────────────────────
	public void addDeliveryUser(User user) throws SQLException {
		String sql = "INSERT INTO users(username, password, role, status, email, mobile, address, gender, joining_date) "
				+ "VALUES(?,?,?,?,?,?,?,?,?)";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setString(1, user.getUsername());
			ps.setString(2, hashPassword(user.getPassword()));
			ps.setString(3, "delivery");
			ps.setString(4, "Active");
			ps.setString(5, user.getEmail());
			ps.setString(6, user.getMobileno());
			ps.setString(7, user.getAddress());
			ps.setString(8, user.getGender());
			ps.setDate(9, user.getJoiningDate());
			ps.executeUpdate();
		}
	}

	/**
	 * BUG FIX: original loginDelivery compared plaintext password to hashed DB
	 * value — now hashes first.
	 */
	public User loginDelivery(String username, String password) throws SQLException {
		String sql = "SELECT * FROM users WHERE username=? AND password=? AND role='delivery' AND status='Active'";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setString(1, username);
			ps.setString(2, hashPassword(password));
			try (ResultSet rs = ps.executeQuery()) {
				if (rs.next()) {
					User u = new User();
					u.setUsername(rs.getString("username"));
					u.setRole(rs.getString("role"));
					u.setEmail(rs.getString("email"));
					return u;
				}
			}
		}
		return null;
	}
}