<?php
 /**
 * Enqueue scripts and styles.
 */
function eco_ngo_scripts() {
	
	// Styles

	wp_enqueue_style('dashicons' );

	wp_enqueue_style('bootstrap-min',get_template_directory_uri().'/css/bootstrap.css');
	
	wp_enqueue_style('font-awesome',get_template_directory_uri().'/css/fonts/font-awesome/css/font-awesome.min.css');
	
	wp_enqueue_style('eco-ngo-widget',get_template_directory_uri().'/css/widget.css');
	
	wp_enqueue_style('eco-ngo-color-default',get_template_directory_uri().'/css/colors/default.css');
	
	wp_enqueue_style('eco-ngo-wp-test',get_template_directory_uri().'/css/wp-test.css');
	
	wp_enqueue_style('eco-ngo-menu',get_template_directory_uri().'/css/menu.css');
	
	wp_enqueue_style('eco-ngo-style', get_stylesheet_uri() );
	
	wp_enqueue_style('eco-ngo-gutenberg',get_template_directory_uri().'/css/gutenberg.css');
	
	wp_enqueue_style('eco-ngo-responsive',get_template_directory_uri().'/css/responsive.css');
	
	// Scripts
	wp_enqueue_script('jquery-ui-core');
	
	wp_enqueue_script('bootstrap', get_template_directory_uri() . '/js/bootstrap.min.js', array('jquery'), '4.3.1', true); 
	
	wp_register_script('eco-ngo-custom-js', get_template_directory_uri() . '/js/custom.js', array('jquery'), false, true);

	wp_localize_script('eco-ngo-custom-js', 'eco_ngo_script_args',
		array( 
			'scroll_top_type' => get_theme_mod( 'eco_ngo_scroll_to_top_type' ) == 'simple-scroll' ? 'simple-scroll' : 'advanced-scroll'
		)
	);
	wp_enqueue_script('eco-ngo-custom-js');

	wp_enqueue_script('eco-ngo-navigation-focus', get_template_directory_uri() . '/js/navigation-focus.js', array(), true );

	wp_enqueue_script('skip-link-focus-fix', get_template_directory_uri() . '/js/skip-link-focus-fix.js', array(), '20151215', true );

	if ( is_singular() && comments_open() && get_option( 'thread_comments' ) ) {
		wp_enqueue_script( 'comment-reply' );
	}

	require get_template_directory(). '/inc/common-inline.php';

	wp_add_inline_style( 'eco-ngo-style',$eco_ngo_common_inline_css );
}
add_action( 'wp_enqueue_scripts', 'eco_ngo_scripts' );

//Admin Enqueue for Admin
function eco_ngo_admin_enqueue_scripts(){
	wp_enqueue_style('eco-ngo-style-customizer',get_template_directory_uri(). '/css/style-customizer.css');

	wp_enqueue_style( 'eco-ngo-admin-style', get_template_directory_uri().'/inc/started/main.css' );

	wp_enqueue_script( 'eco-ngo-admin-script', get_template_directory_uri() . '/inc/admin-notice/admin.js', array( 'jquery' ), '', true );

	wp_enqueue_script( 'eco-ngo-demo-script', get_template_directory_uri() . '/js/demo-script.js', array( 'jquery' ), '', true );
}
add_action( 'admin_enqueue_scripts', 'eco_ngo_admin_enqueue_scripts' );

?>