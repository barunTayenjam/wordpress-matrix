var eco_ngo_keyboard_navigation_loop = function (elem) {
  var eco_ngo_tabbable = elem.find('select, input, textarea, button, a').filter(':visible');
  var eco_ngo_firstTabbable = eco_ngo_tabbable.first();
  var eco_ngo_lastTabbable = eco_ngo_tabbable.last();
  eco_ngo_firstTabbable.focus();

  eco_ngo_lastTabbable.on('keydown', function (e) {
    if ((e.which === 9 && !e.shiftKey)) {
      e.preventDefault();
      eco_ngo_firstTabbable.focus();
    }
  });

  eco_ngo_firstTabbable.on('keydown', function (e) {
    if ((e.which === 9 && e.shiftKey)) {
      e.preventDefault();
      eco_ngo_lastTabbable.focus();
    }
  });

  elem.on('keyup', function (e) {
    if (e.keyCode === 27) {
      elem.hide();
    };
  });
};