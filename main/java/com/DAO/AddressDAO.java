package com.DAO;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

import com.util.CustomerAddress;
import com.util.DBConnection;

public class AddressDAO {
	public int addAddress(CustomerAddress address) throws SQLException {
		String sql = "INSERT INTO customer_address (customer_id, landmark_street, city, district, state, country, pincode, is_default) VALUES (?,?,?,?,?,?,?,?)";
		try (Connection conn = DBConnection.getConnection();
				PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
			ps.setInt(1, address.getCustomerId());
			ps.setString(2, address.getLandmarkStreet());
			ps.setString(3, address.getCity());
			ps.setString(4, address.getDistrict());
			ps.setString(5, address.getState());
			ps.setString(6, address.getCountry());
			ps.setString(7, address.getPincode());
			ps.setBoolean(8, address.isDefault());
			ps.executeUpdate();

			ResultSet rs = ps.getGeneratedKeys();
			if (rs.next()) {
				int id = rs.getInt(1);
				address.setAddressId(id);
				return id;
			}
		}
		return -1;
	}

	public void updateAddress(CustomerAddress address) throws SQLException {
		String sql = "UPDATE customer_address SET landmark_street=?, city=?, district=?, state=?, country=?, pincode=?, is_default=? WHERE address_id=?";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setString(1, address.getLandmarkStreet());
			ps.setString(2, address.getCity());
			ps.setString(3, address.getDistrict());
			ps.setString(4, address.getState());
			ps.setString(5, address.getCountry());
			ps.setString(6, address.getPincode());
			ps.setBoolean(7, address.isDefault());
			ps.setInt(8, address.getAddressId());
			ps.executeUpdate();
		}

		// If updated address is default, sync to customers table
		if (address.isDefault()) {
			updateCustomerMainAddress(address);
		}
	}

	public CustomerAddress getDefaultAddressByCustomer(int customerId) throws SQLException {
		String sql = "SELECT * FROM customer_address WHERE customer_id=? AND is_default=TRUE LIMIT 1";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, customerId);
			ResultSet rs = ps.executeQuery();
			if (rs.next()) {
				CustomerAddress addr = new CustomerAddress();
				addr.setAddressId(rs.getInt("address_id"));
				addr.setCustomerId(rs.getInt("customer_id"));
				addr.setLandmarkStreet(rs.getString("landmark_street"));
				addr.setCity(rs.getString("city"));
				addr.setDistrict(rs.getString("district"));
				addr.setState(rs.getString("state"));
				addr.setCountry(rs.getString("country"));
				addr.setPincode(rs.getString("pincode"));
				addr.setDefault(rs.getBoolean("is_default"));
				return addr;
			}
		}
		return null;
	}

	public CustomerAddress getAddressById(int addressId) throws SQLException {
		String sql = "SELECT * FROM customer_address WHERE address_id=?";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, addressId);
			ResultSet rs = ps.executeQuery();
			if (rs.next()) {
				CustomerAddress addr = new CustomerAddress();
				addr.setAddressId(rs.getInt("address_id"));
				addr.setCustomerId(rs.getInt("customer_id"));
				addr.setLandmarkStreet(rs.getString("landmark_street"));
				addr.setCity(rs.getString("city"));
				addr.setDistrict(rs.getString("district"));
				addr.setState(rs.getString("state"));
				addr.setCountry(rs.getString("country"));
				addr.setPincode(rs.getString("pincode"));
				return addr;
			}
		}
		return null;
	}

	public List<CustomerAddress> getAddressesByCustomer(int customerId) throws SQLException {
		List<CustomerAddress> addresses = new ArrayList<>();
		String sql = "SELECT * FROM customer_address WHERE customer_id=?";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, customerId);
			ResultSet rs = ps.executeQuery();
			while (rs.next()) {
				CustomerAddress addr = new CustomerAddress();
				addr.setAddressId(rs.getInt("address_id"));
				addr.setCustomerId(rs.getInt("customer_id"));
				addr.setLandmarkStreet(rs.getString("landmark_street"));
				addr.setCity(rs.getString("city"));
				addr.setDistrict(rs.getString("district"));
				addr.setState(rs.getString("state"));
				addr.setCountry(rs.getString("country"));
				addr.setPincode(rs.getString("pincode"));
				addr.setDefault(rs.getBoolean("is_default"));
				addresses.add(addr);
			}
		}
		return addresses;
	}

	public boolean deleteAddress(int addressId, int customerId) throws SQLException {
		CustomerAddress addr = getAddressById(addressId);
		boolean wasDefault = addr.isDefault();

		String sql = "DELETE FROM customer_address WHERE address_id=? AND customer_id=?";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, addressId);
			ps.setInt(2, customerId);
			ps.executeUpdate();
		}
		return wasDefault;
	}

	public void setDefaultAddress(int customerId, int addressId) throws SQLException {
		try (Connection conn = DBConnection.getConnection()) {
			// Clear old default
			String clearSql = "UPDATE customer_address SET is_default=FALSE WHERE customer_id=?";
			try (PreparedStatement ps = conn.prepareStatement(clearSql)) {
				ps.setInt(1, customerId);
				ps.executeUpdate();
			}

			// Set new default
			String setSql = "UPDATE customer_address SET is_default=TRUE WHERE address_id=?";
			try (PreparedStatement ps = conn.prepareStatement(setSql)) {
				ps.setInt(1, addressId);
				ps.executeUpdate();
			}

			// Sync customers table manually
			CustomerAddress addr = getAddressById(addressId);
			updateCustomerMainAddress(addr);
		}
	}

	private void updateCustomerMainAddress(CustomerAddress addr) throws SQLException {
		String sql = "UPDATE customers SET landmark_street=?, city=?, district=?, state=?, country=?, pincode=? WHERE customer_id=?";
		try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setString(1, addr.getLandmarkStreet());
			ps.setString(2, addr.getCity());
			ps.setString(3, addr.getDistrict());
			ps.setString(4, addr.getState());
			ps.setString(5, addr.getCountry());
			ps.setString(6, addr.getPincode());
			ps.setInt(7, addr.getCustomerId());
			ps.executeUpdate();
		}
	}

}
