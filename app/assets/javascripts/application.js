function selectReportType() {
  const e = document.getElementById("couponType");
  const couponName = e.options[e.selectedIndex].text;
  var newUrl = window.location.origin + window.location.pathname + "?coupon_name=" + couponName;
  window.location.href = newUrl;
}


function processDates(e) {
  e.preventDefault()
  const start = document.getElementById("salesStartDate");
  const startDate = start.value;
  const end = document.getElementById("salesEndDate");
  const endDate = end.value;
  var newUrl = window.location.origin + window.location.pathname + "?start=" + startDate + "&end=" + endDate;
  window.location.href = newUrl;
}