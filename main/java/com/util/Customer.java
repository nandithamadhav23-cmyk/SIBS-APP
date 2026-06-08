package com.util;

public class Customer {
	private int id;
	private String name;
	private String email;
	private String phone;
	private String landmark_street;
	private String city;
	private String district;
	private String state;
	private String country;
	private String pincode;

	public Customer(int id, String name, String email, String phone, String landmark_street, String city,
			String district, String state, String country, String pincode, String role, String gender) {
		super();
		this.id = id;
		this.name = name;
		this.email = email;
		this.phone = phone;
		this.landmark_street = landmark_street;
		this.city = city;
		this.district = district;
		this.state = state;
		this.country = country;
		this.role = role;
		this.gender = gender;
		this.pincode = pincode;
	}

	public String getPincode() {
		return pincode;
	}

	public void setPincode(String pincode) {
		this.pincode = pincode;
	}

	public String getLandmark_street() {
		return landmark_street;
	}

	public void setLandmark_street(String landmark_street) {
		this.landmark_street = landmark_street;
	}

	public String getCity() {
		return city;
	}

	public void setCity(String city) {
		this.city = city;
	}

	public String getDistrict() {
		return district;
	}

	public void setDistrict(String district) {
		this.district = district;
	}

	public String getState() {
		return state;
	}

	public void setState(String state) {
		this.state = state;
	}

	public String getCountry() {
		return country;
	}

	public void setCountry(String country) {
		this.country = country;
	}

	public String getGender() {
		return gender;
	}

	public void setGender(String gender) {
		this.gender = gender;
	}

	private String role;
	private String gender;

	// Getters and setters
	public int getId() {
		return id;
	}

	public String getName() {
		return name;
	}

	public String getEmail() {
		return email;
	}

	public String getPhone() {
		return phone;
	}

	public String getRole() {
		return role;
	}

	public void setName(String name) {
		this.name = name;
	}

	public void setEmail(String email) {
		this.email = email;
	}

	public void setPhone(String phone) {
		this.phone = phone;
	}

	public void setRole(String role) {
		this.role = role;
	}

	private String profileImage;

	public String getProfileImage() {
		return profileImage;
	}

	public void setProfileImage(String profileImage) {
		this.profileImage = profileImage;
	}
}
