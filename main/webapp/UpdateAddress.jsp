<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
    
    <%@ page import="com.util.*"  %>
    <%      CustomerAddress addr=(CustomerAddress) request.getAttribute("address");
 %>

<style>
/* Touch-friendly address form */
#updateAddressForm .form-control {
  height: 46px;
  font-size: 1rem;
  border-radius: 10px;
}
#updateAddressForm .form-label {
  font-size: .88rem;
  font-weight: 600;
  margin-bottom: .3rem;
}
#updateAddressForm .btn-primary {
  height: 48px;
  font-size: 1rem;
  font-weight: 700;
  border-radius: 10px;
}
#updateAddressForm .mb-3 { margin-bottom: .85rem !important; }
</style>
    
<div id="updateAddressForm">
  
<form id="editAddressForm" method="post" action="Address">
  <input type="hidden" name="action" value="saveUpdate">
  <input type="hidden" name="addressId" value="<%= addr.getAddressId() %>">
  <input type="hidden" name="customerId" value="<%= addr.getCustomerId() %>">

  <div class="mb-3">
    <label class="form-label">🏠 Landmark / Street</label>
    <input type="text" class="form-control" name="landmarkStreet" value="<%= addr.getLandmarkStreet() %>" required>
  </div>

  <div class="mb-3">
    <label class="form-label">🌆 City</label>
    <input type="text" class="form-control" name="city" value="<%= addr.getCity() %>" required>
  </div>

  <div class="mb-3">
    <label class="form-label">📍 District</label>
    <input type="text" class="form-control" name="district" value="<%= addr.getDistrict() %>" required>
  </div>

  <div class="mb-3">
    <label class="form-label">🏢 State</label>
    <input type="text" class="form-control" name="state" value="<%= addr.getState() %>" required>
  </div>

  <div class="mb-3">
    <label class="form-label">🌍 Country</label>
    <input type="text" class="form-control" name="country" value="<%= addr.getCountry() %>" required>
  </div>

  <div class="mb-3">
    <label class="form-label">📮 Pincode</label>
    <input type="text" class="form-control" name="pincode" value="<%= addr.getPincode() %>" required>
  </div>

  <div class="form-check mb-3">
  
    <input class="form-check-input" type="checkbox" name="isDefault" value="true" <%= addr.isDefault() ? "checked" : "" %>>
    <label class="form-check-label">⭐ Set as Default Address</label>
  </div>

  <button type="submit" class="btn btn-primary w-100">✏️ Update Address</button>
</form>
  
</div>

