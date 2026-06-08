<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Login</title>
  <style>
    body {
      font-family: 'Segoe UI', sans-serif;
      background: #f9fafc;
      margin: 0;
      padding: 0;
    }
    .container {
      max-width: 400px;
      margin: 80px auto;
      background: #fff3e0; /* soft peach */
      border-radius: 12px;
      box-shadow: 0 4px 12px rgba(0,0,0,0.1);
      padding: 30px;
    }
    h2 {
      text-align: center;
      color: #444;
      margin-bottom: 20px;
    }
    label {
      display: block;
      margin-top: 15px;
      color: #333;
    }
    input {
      width: 90%;
      padding: 10px;
      margin-top: 5px;
      border-radius: 6px;
      border: 1px solid #ccc;
    }
    .btn {
      margin-top: 20px;
      padding: 12px 20px;
      background: #c5e1a5; /* pastel green */
      border: none;
      border-radius: 6px;
      cursor: pointer;
      font-weight: bold;
      width: 100%;
    }
    .btn:hover {
      background: #aed581;
    }
    .error {
      color: #d32f2f;
      text-align: center;
      margin-bottom: 15px;
    }
 
	.modal {
	  display: none; 
	  position: fixed; 
	  z-index: 1000; 
	  left: 0; top: 0;
	  width: 100%; height: 100%;
	  background-color: rgba(0,0,0,0.5);
	}
	.modal-content {
	  background: #fff3e0;
	  margin: 10% auto;
	  padding: 20px;
	  border-radius: 12px;
	  width: 450px;
	  box-shadow: 0 4px 12px rgba(0,0,0,0.2);
	}
	.close {
	  float: right;
	  font-size: 24px;
	  cursor: pointer;
	}
	</style>

<!-- Modal Script -->
	<script>
	function openModal(id) {
	  document.getElementById(id).style.display = 'block';
	}
	function closeModal(id) {
	  document.getElementById(id).style.display = 'none';
	}
	</script>
</head>
<body>
   <div class="container">
       <!-- Display error message if present -->
    <%
      String errorMsg = (String) request.getAttribute("errorMessage");
      if (errorMsg != null) {
    %>
      <div class="error"><%= errorMsg %></div>
    <%
      }
    %>
  <h2>Login</h2>

  <!-- Standard Username + Password Login -->
  <form action="login" method="post">
    <label>Username:</label>
    <input type="text" name="username" required />

    <label>Password:</label>
    <input type="password" name="password" required />

    <button type="submit" class="btn">Login</button>
  </form>

  <div style="text-align:center; margin-top:20px;">
    <a href="#" onclick="openModal('forgotModal')">Forgot Password?</a><br><br>
    <a href="#" onclick="openModal('emailModal')">Login using Email</a><br><br>
    <a href="#" onclick="openModal('mobileModal')">Login using Mobile Number</a><br>
  </div>
</div>

<!-- Forgot Password Modal -->
<div id="forgotModal" class="modal">
  <div class="modal-content">
    <span class="close" onclick="closeModal('forgotModal')">&times;</span>
    <h3>Forgot Password</h3>
    <form action="forgotPassword" method="post">
      <label>Enter your email:</label>
      <input type="email" name="email" required />
      <button type="submit" class="btn">Send Reset Link</button>
    </form>
  </div>
</div>

<!-- Email Login Modal -->
<div id="emailModal" class="modal">
  <div class="modal-content">
    <span class="close" onclick="closeModal('emailModal')">&times;</span>
    <h3>Login using Email</h3>
    <form action="loginEmail" method="post">
      <label>Email:</label>
      <input type="email" name="email" required />
      <button type="submit" class="btn">Send OTP</button>
    </form>
  </div>
</div>

<!-- Mobile Login Modal -->
<div id="mobileModal" class="modal">
  <div class="modal-content">
    <span class="close" onclick="closeModal('mobileModal')">&times;</span>
    <h3>Login using Mobile</h3>
    <form action="loginMobile" method="post">
      <label>Mobile Number:</label>
      <input type="text" name="mobile" required />
      <button type="submit" class="btn">Send OTP</button>
    </form>
  </div>
</div>
</body>
</html>
