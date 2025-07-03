function eco_ngo_navigation_open() {
    jQuery(".side_gb_nav").addClass('show');
}
function eco_ngo_navigation_close() {
    jQuery(".side_gb_nav").removeClass('show');
}

jQuery(function($){
    $('.gb_toggle').click(function () {
        eco_ngo_keyboard_navigation_loop($('.side_gb_nav'));
    });
});
jQuery('document').ready(function(){
    window.addEventListener('load', (event) => {
        jQuery(".loading").delay(2000).fadeOut("slow");
    });

    //* Navbar Fixed  
    function navbarFixed(){
        if ( jQuery('.nav-stick.is-sticky-on').length ){ 
            jQuery(window).on('scroll', function() {
                var scroll = jQuery(window).scrollTop();   
                if (scroll >= 295) {
                    jQuery(".nav-stick.is-sticky-on").addClass("header-fixed");
                } else {
                    jQuery(".nav-stick.is-sticky-on").removeClass("header-fixed");
                }
            });  
        };
    }

    navbarFixed();
});
jQuery(document).ready(function($) {
    $(window).on('scroll', function() {
        if ($(this).scrollTop() > 100) {
            $('.scrollup').fadeIn();
        } else {
            $('.scrollup').fadeOut();
        }
    });

    $('.scrollup').on('click', function() {
        $("html, body").animate({
            scrollTop: 0
        }, 600);
        return false;
    });

    // Event handling for scrolling and updating progress bar
    $(window).on('scroll', function() {
      $('.scroll_2').toggleClass('active', $(this).scrollTop() > 50);

      if ( eco_ngo_script_args.scroll_top_type == 'advanced-scroll' ) {
          eco_ngo_initUpdateProgressBar();
      }
  });

  // Function to handle click event for scrolling to top
  $('.scroll_2').on('click', function(event) {
      event.preventDefault();
      $('html, body').animate({ scrollTop: 0 }, 550);
  });


    // Function to handle scrolling and update progress bar
    function eco_ngo_initUpdateProgressBar() {
        var scroll = $(window).scrollTop();
        var height = $(document).height() - $(window).height();
        var progressPath = $('.scroll_2 path')[0];
        var pathLength = progressPath.getTotalLength();
        var progress = pathLength - (scroll * pathLength / height);
        progressPath.style.strokeDashoffset = progress;
    }

    // Function to initialize headline and preloader on window load
    function eco_ngo_initializeComponents() {
        $(window).on('load', function() {
            eco_ngo_initUpdateProgressBar();
            const boxes = gsplit.utils.toArray('.dt_item_active');
            boxes.forEach(svg => {
                gsplit.to(svg, {
                    scrollTrigger: {
                        trigger: svg,
                        start: "top 70%",
                        end: "bottom bottom",
                        toggleClass: "active",
                        once: true,
                    }
                });
            });
        });
    }
});