document.addEventListener('DOMContentLoaded', function() {
  const countrySelect = document.getElementById('country');
  const stateSelect = document.getElementById('state');
  const districtSelect = document.getElementById('district');
  const citySelect = document.getElementById('city');
  const pincodeInput = document.getElementById('pincode');

  // If you’re using the servlet proxy:
  const BASE_URL = '/GeoProxy';
  // If you want to call CSC API directly (not recommended for exposing API key):
  // const BASE_URL = 'https://api.countrystatecity.in/v1';
  // const API_KEY = 'YOUR_CSC_API_KEY';

  // Load countries
fetch(`${BASE_URL}?type=countries`).then(res => {
      if (!res.ok) throw new Error("Failed to load countries: " + res.status);
      return res.json();
    })
    .then(data => {
      console.log("Countries API response:", data);
      if (Array.isArray(data)) {
        data.forEach(c => {
          let opt = document.createElement('option');
          opt.value = c.iso2;
          opt.textContent = c.name;
          countrySelect.appendChild(opt);
        });
      } else {
        console.error("Unexpected countries response format:", data);
      }
    })
    .catch(err => console.error("Error loading countries:", err));

  // Load states
  countrySelect.addEventListener('change', function() {
    stateSelect.innerHTML = '<option value="">Select State</option>';
    districtSelect.innerHTML = '<option value="">Select District</option>';
    citySelect.innerHTML = '<option value="">Select City</option>';
    pincodeInput.value = '';

    fetch(`${BASE_URL}?type=states&country=${this.value}`)
      .then(res => {
        if (!res.ok) throw new Error("Failed to load states: " + res.status);
        return res.json();
      })
      .then(data => {
        console.log("States API response:", data);
        if (Array.isArray(data)) {
          data.forEach(s => {
            let opt = document.createElement('option');
            opt.value = s.iso2;
            opt.textContent = s.name;
            stateSelect.appendChild(opt);
          });
        } else {
          console.error("Unexpected states response format:", data);
        }
      })
      .catch(err => console.error("Error loading states:", err));
  });

  // Load cities
  stateSelect.addEventListener('change', function() {
    citySelect.innerHTML = '<option value="">Select City</option>';
    pincodeInput.value = '';

    fetch(`${BASE_URL}?type=cities&country=${countrySelect.value}&state=${this.value}`)
      .then(res => {
        if (!res.ok) throw new Error("Failed to load cities: " + res.status);
        return res.json();
      })
      .then(data => {
        console.log("Cities API response:", data);
        if (Array.isArray(data)) {
          data.forEach(c => {
            let opt = document.createElement('option');
            opt.value = c.name;
            opt.textContent = c.name;
            citySelect.appendChild(opt);
          });
        } else {
          console.error("Unexpected cities response format:", data);
        }
      })
      .catch(err => console.error("Error loading cities:", err));
  });

  // Pincode lookup (India only)
  citySelect.addEventListener('change', function() {
    pincodeInput.value = '';
    if (countrySelect.value.toLowerCase() === 'in') {
      fetch(`https://api.postalpincode.in/postoffice/${this.value}`)
        .then(res => res.json())
        .then(data => {
          console.log("Pincode API response:", data);
          if (Array.isArray(data) && data[0].PostOffice && data[0].PostOffice.length > 0) {
            pincodeInput.value = data[0].PostOffice[0].Pincode;
          } else {
            pincodeInput.placeholder = "Enter Pincode manually";
          }
        })
        .catch(() => pincodeInput.placeholder = "Enter Pincode manually");
    } else {
      pincodeInput.placeholder = "Enter Pincode manually";
    }
  });
});
