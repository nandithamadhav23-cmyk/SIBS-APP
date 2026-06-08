<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="com.util.CartItem" %>
<%@ page import="com.util.*" %>
<%@ page import="com.util.CustomerAddress" %>

<%
Customer customer = (Customer) request.getAttribute("customer");
CustomerAddress address = (CustomerAddress) request.getAttribute("address");
List<CartItem> cartItems = (List<CartItem>) request.getAttribute("cartItems");

Order order = (Order)request.getAttribute("order");
String orderId = (String) request.getAttribute("orderId");
%>

<!DOCTYPE html>
<html>
<head>
  <title>Invoice</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
  <style>
    body { background: #fff; }
    .invoice-box { max-width: 900px; margin: auto; padding: 30px; border: 1px solid #000; }
    .invoice-title { font-size: 28px; font-weight: bold; }
    .section-title { font-weight: bold; border-bottom: 2px solid #000; margin-top: 20px; margin-bottom: 10px; }
    table th, table td { text-align: center; }
  </style>
</head>
<body>
<div class="invoice-box">

  <!-- Header -->
  <div class="d-flex justify-content-between border-bottom pb-2 mb-3">
    <h3 class="fw-bold">SIBS STORE</h3>
    <div class="text-end">
      <span class="invoice-title">INVOICE</span>
      <p>Order ID: <%= order.getId() %></p>
      <p>Order Date: <%= order.getDate() %></p>
    </div>
  </div>

  <!-- Customer & Address -->
  <div class="row">
    <div class="col-6">
      <h6 class="section-title">Customer Details</h6>
      <p><strong>Name:</strong> <%= customer.getName() %></p>
      <p><strong>Email:</strong> <%= customer.getEmail() %></p>
      <p><strong>Phone:</strong> <%= customer.getPhone() %></p>
    </div>
    <div class="col-6">
      <h6 class="section-title">Shipping Address</h6>
      <% if(address != null) { %>
        <p><%= address.getLandmarkStreet() %>, <%= address.getCity() %>, <%= address.getDistrict() %></p>
        <p><%= address.getState() %>, <%= address.getCountry() %> - <%= address.getPincode() %></p>
      <% } else { %>
        <p class="text-danger">No default address found.</p>
      <% } %>
    </div>
  </div>

  <!-- Products -->
  <h6 class="section-title">Products Ordered</h6>
  <table class="table table-bordered">
    <thead class="table-light">
      <tr>
        <th>Product</th>
        <th>Image</th>
        <th>Pack Size</th>
        <th>Qty</th>
        <th>Unit Price</th>
        <th>Total</th>
      </tr>
    </thead>
    <tbody>
      <% for(CartItem item : cartItems) { %>
        <tr>
          <td><%= item.getName() %></td>
          <td><img src="<%= item.getImageUrl() %>" alt="<%= item.getName() %>" style="width:60px;height:60px;"></td>
          <td><%= item.getProductQuantity() %> <%= item.getUnit() %></td>
          <td><%= item.getQuantity() %></td>
          <td>₹ <%= item.getFinalPrice() %></td>
          <td>₹ <%= item.getFinalPrice() * item.getQuantity() %></td>
        </tr>
      <% } %>
    </tbody>
  </table>

  <!-- Order Summary -->
  <h6 class="section-title">Order Summary</h6>
  <div class="text-end">
    <p>Sub Total: ₹ <%= order.getSubtotal() %></p>
       <p>GST (18%): ₹ <%= order.getGst() %></p>
      <p>Tax (5%): ₹ <%= order.getTax() %></p>
     <p>Delivery Charges: ₹ <%= order.getDeliveryCharge() %></p>
    <% if("COD".equals(order.getPaymentMethod())) { %>
      <p>COD Charges: ₹ <%= order.getCodCharge() %></p>
    <% } %>
<!-- Grand Total -->
    <h4 class="mt-4 text-success">Grand Total: ₹ <%= order.getTotalAmount() %></h4>
    <p>Payment Method: <%= order.getPaymentMethod() %></p>
  <p><strong>Expected Delivery:</strong><%= (order.getDeliveryDate() != null 
       ? new java.text.SimpleDateFormat("dd-MMM-yyyy").format(order.getDeliveryDate()) 
       : "Not yet scheduled") %>
 </p>
  </div>

  <!-- Footer -->
  <div class="border-top mt-4 pt-2 text-center">
    <p>Authorized Signature _____________________</p>
    <p class="fw-bold">This is a computer generated invoice.</p>
    <button class="btn btn-outline-secondary" onclick="window.print()">🖨️ Print Invoice</button>
  </div>
</div>
</body>
</html>
