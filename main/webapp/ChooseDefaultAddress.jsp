<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="java.util.List, com.util.CustomerAddress" %>
<%
    List<CustomerAddress> addresses = (List<CustomerAddress>) request.getAttribute("addresses");
    int customerId = (Integer) request.getAttribute("customerId");
%>

<div>
  <h5 class="mb-3">Please choose a new default address:</h5>
  <form method="post" action="Address">
    <input type="hidden" name="action" value="setDefault">
    <input type="hidden" name="customerId" value="<%= customerId %>">

    <% for (CustomerAddress addr : addresses) { %>
      <div class="form-check mb-2 border rounded p-2">
        <input class="form-check-input" type="radio" name="addressId" 
               value="<%= addr.getAddressId() %>" required>
        <label class="form-check-label">
          🏠 <%= addr.getLandmarkStreet() %>, 🌆 <%= addr.getCity() %>, 🏢 <%= addr.getState() %>, 📮 <%= addr.getPincode() %>
        </label>
      </div>
    <% } %>

    <button type="submit" class="btn btn-primary w-100 mt-3">⭐ Set as Default</button>
  </form>
</div>
<script>
$(document).on("submit", "form[action='Address'][input[value='setDefault']]", function(e) {
	  e.preventDefault();
	  $.ajax({
	    url: "Address",
	    type: "POST",
	    data: $(this).serialize(),
	    success: function(response) {
	      $("#addressSection").html(response);   // refresh checkout
	      $("#addressModal").modal("hide");      // close modal
	      showAlert("⭐ Default address updated!", "success");
	    },
	    error: function() {
	      showAlert("❌ Failed to set default address.", "danger");
	    }
	  });
	});

</script>
