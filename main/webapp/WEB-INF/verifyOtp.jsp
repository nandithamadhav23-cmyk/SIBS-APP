<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Verification</title>
</head>
<body>
   <div class="container">
  <h2>Verify OTP</h2>
  <%
    com.util.User user = (com.util.User) session.getAttribute("userDetails");
    if (user != null) {
  %>
    <p><strong>Name:</strong> <%= user.getUsername() %></p>
    <p><strong>Email:</strong> <%= user.getEmail() %></p>
    <p><strong>Role:</strong> <%= user.getRole() %></p>
    <p><strong>Status:</strong> <%= user.getStatus() %></p>
  <%
    }
  %>
  <form action="verifyOtp" method="post">
    <label>Enter OTP:</label>
    <input type="text" name="otpInput" required />
    <button type="submit" class="btn">Verify</button>
  </form>
</div>
</body>
</html>