
// Mobile nav toggle
document.addEventListener('DOMContentLoaded', function() {
  // Toggle mobile menu
  var toggles = document.querySelectorAll('.navbar-toggler, .menu-toggle, [data-toggle="collapse"]');
  toggles.forEach(function(btn) {
    btn.addEventListener('click', function() {
      var target = btn.getAttribute('data-target') || btn.getAttribute('href');
      if (target) {
        var el = document.querySelector(target);
        if (el) el.classList.toggle('show');
      }
    });
  });

  // Dropdown menus on click (mobile)
  var dropdowns = document.querySelectorAll('.menu-item-has-children > a, .dropdown-toggle');
  dropdowns.forEach(function(link) {
    link.addEventListener('click', function(e) {
      if (window.innerWidth < 992) {
        e.preventDefault();
        var parent = link.parentElement;
        parent.classList.toggle('open');
      }
    });
  });

  // Smooth scroll for anchor links
  document.querySelectorAll('a[href^="#"]').forEach(function(a) {
    a.addEventListener('click', function(e) {
      var id = a.getAttribute('href');
      if (id === '#') return;
      var target = document.querySelector(id);
      if (target) { e.preventDefault(); target.scrollIntoView({ behavior: 'smooth' }); }
    });
  });
});
