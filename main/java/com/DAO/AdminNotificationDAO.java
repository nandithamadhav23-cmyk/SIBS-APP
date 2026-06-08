package com.DAO;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;

import com.util.AdminNotification;
import com.util.DBConnection;

public class AdminNotificationDAO {
	public void addNotification(String eventType, String title, String message, String relatedEntity, Integer productId,
			Integer orderId) {
		String sql = "INSERT INTO admin_notifications (event_type, title, message, related_entity, product_id, order_id) VALUES (?, ?, ?, ?, ?, ?)";
		try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
			ps.setString(1, eventType);
			ps.setString(2, title);
			ps.setString(3, message);
			ps.setString(4, relatedEntity);
			ps.setObject(5, productId);
			ps.setObject(6, orderId);
			ps.executeUpdate();
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	public List<AdminNotification> getUnreadNotifications() {
		List<AdminNotification> list = new ArrayList<>();
		String sql = "SELECT * FROM admin_notifications WHERE is_read=0 AND is_dismissed=0 ORDER BY created_at DESC";
		try (Connection con = DBConnection.getConnection();
				PreparedStatement ps = con.prepareStatement(sql);
				ResultSet rs = ps.executeQuery()) {
			while (rs.next()) {
				AdminNotification n = new AdminNotification();
				n.setId(rs.getInt("id"));
				n.setEventType(rs.getString("event_type"));
				n.setTitle(rs.getString("title"));
				n.setMessage(rs.getString("message"));
				n.setRelatedEntity(rs.getString("related_entity"));
				n.setCreatedAt(rs.getTimestamp("created_at"));
				list.add(n);
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
		return list;
	}

	public void markAsRead(int id) {
		String sql = "UPDATE admin_notifications SET is_read=1 WHERE id=?";
		try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
			ps.setInt(1, id);
			ps.executeUpdate();
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	public int getUnreadCount() {
		String sql = "SELECT COUNT(*) FROM admin_notifications WHERE is_read=0 AND is_dismissed=0";
		try (Connection con = DBConnection.getConnection();
				PreparedStatement ps = con.prepareStatement(sql);
				ResultSet rs = ps.executeQuery()) {
			if (rs.next()) {
				return rs.getInt(1);
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
		return 0;
	}

}
