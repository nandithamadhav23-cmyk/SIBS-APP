package com.util;

public class DeliveryZone {

	private int zoneId;
	private String zoneName;
	private String pincodes; // comma-separated
	private boolean isSurge;
	private double surgeMultiplier;

	public int getZoneId() {
		return zoneId;
	}

	public void setZoneId(int zoneId) {
		this.zoneId = zoneId;
	}

	public String getZoneName() {
		return zoneName;
	}

	public void setZoneName(String n) {
		this.zoneName = n;
	}

	public String getPincodes() {
		return pincodes;
	}

	public void setPincodes(String p) {
		this.pincodes = p;
	}

	public boolean isSurge() {
		return isSurge;
	}

	public void setSurge(boolean s) {
		this.isSurge = s;
	}

	public double getSurgeMultiplier() {
		return surgeMultiplier;
	}

	public void setSurgeMultiplier(double m) {
		this.surgeMultiplier = m;
	}

	public String[] getPincodeArray() {
		return pincodes != null ? pincodes.split(",") : new String[0];
	}
}