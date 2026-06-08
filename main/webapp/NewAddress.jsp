<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
    <%@ page import="com.util.*"  %>
   <%@ page import="com.util.Customer" %>
<%
    int customerId = (int) request.getAttribute("customerId");
%>
 <div id="newAddressForm">
  <form id="addAddressForm" method="post" action="Address">
    <input type="hidden" name="action" value="saveNew">
<input type="hidden" name="customerId" value="<%= customerId%>">

    <div class="mb-3">
      <label class="form-label">🏠 Landmark / Street</label>
      <input type="text" class="form-control" name="landmarkStreet" required>
    </div>

    <div class="mb-3">
      <label class="form-label">🌆 City</label>
      <input type="text" class="form-control" name="city" required>
    </div>

    <div class="mb-3">
      <label class="form-label">📍 District</label>
      <input type="text" class="form-control" name="district" required>
    </div>

    <div class="mb-3">
      <label class="form-label">🏢 State</label>
      <input type="text" class="form-control" name="state" required>
    </div>

    <div class="mb-3">
      <label class="form-label">🌍 Country</label>
      <input type="text" class="form-control" name="country" required>
    </div>

    <div class="mb-3">
      <label class="form-label">📮 Pincode</label>
      <input type="text" class="form-control" name="pincode">
    </div>

    <div class="form-check mb-3">
      <input class="form-check-input" type="checkbox" name="isDefault" value="true">
      <label class="form-check-label">⭐ Set as Default Address</label>
    </div>

    <button type="submit" class="btn btn-success w-100">➕ Save Address</button>
  </form>
</div>



    