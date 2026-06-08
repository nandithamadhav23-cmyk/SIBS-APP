<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="com.util.CustomerAddress" %>

<%
    List<CustomerAddress> addresses = (List<CustomerAddress>) request.getAttribute("addresses");
%>

<div class="d-flex gap-2" id="addressSection">
  <% if (addresses != null && !addresses.isEmpty()) {
       for (CustomerAddress addr : addresses) { %>
    <div class="card shadow border p-2 mb-2 <%= addr.isDefault() ? "bg-light border-primary" : "" %>">
      <p>🏠 <%= addr.getLandmarkStreet() %>, <%= addr.getCity() %></p>
      <p>📍 <%= addr.getDistrict() %>, <%= addr.getState() %></p>
      <p>🌍 <%= addr.getCountry() %> - <%= addr.getPincode() %></p>

      <% if (addr.isDefault()) { %>
        <span class="badge bg-primary">Main Shipping Address</span>
      <% } %>
   <div class="row p-2">
      <!-- Update Button -->
      <button class="btn btn-outline-primary btn-sm border-0 col"
              onclick="openAddressModal('update', <%= addr.getAddressId() %>)">✏️ Edit</button>

      <!-- Delete Button -->
      <button class="btn btn-outline-danger btn-sm border-0 col"
              onclick="deleteAddress(<%= addr.getAddressId() %>, <%= addr.getCustomerId() %>)">🗑️ Delete</button>
</div>
      <!-- Set as Default Button -->
      <% if (!addr.isDefault()) { %>
      
        <button class="btn btn-outline-success btn-sm border-0"
                onclick="setDefaultAddress(<%= addr.getAddressId() %>, <%= addr.getCustomerId() %>)">⭐ Set as Default</button>
      <% } %>
    </div>
  <% } %>
    <!-- Add New Address -->
    <button class="btn btn-outline-success btn-sm" onclick="openAddressModal('new')">➕ Add New Address</button>
  <% } else { %>
    <p class="text-muted">No shipping address found.</p>
    <button class="btn btn-outline-success btn-sm" onclick="openAddressModal('new')">➕ Add New Address</button>
  <% } %>
</div>
