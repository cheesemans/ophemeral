document.addEventListener('DOMContentLoaded', function() {
  const copyButton = document.getElementById('copy-button');
  const copySecret = document.getElementById('copy-secret');

  copyButton.addEventListener('click', function() {
    copySecret.select();
    copySecret.setSelectionRange(0, 99999);

    navigator.clipboard.writeText(copySecret.value);

    copyButton.setAttribute("value", "Copied 🥳");

    setTimeout(function() {
      copyButton.innerText = 'Copy 📋';
    }, 2000);

    event.preventDefault();
  });
});
