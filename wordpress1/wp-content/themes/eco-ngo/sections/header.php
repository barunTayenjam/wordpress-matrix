<!-- Start: Header
============================= -->
<?php

$eco_ngo_header_phone_number = get_theme_mod('eco_ngo_header_phone_number');


?>

<header id="header" role="banner" class="nav-stick <?php echo esc_attr(eco_ngo_sticky_header()); ?>" <?php if ( get_header_image() ) { ?> style="background-image: url( <?php header_image(); ?> ); background-size: 100%;" <?php } ?> >
	<div class="container">
		<div class="navbar-area">
			<div class="row">
				<div class="col-lg-3 col-md-3 col-sm-5 col-12 align-self-center">
					<div class="logo main">
						<?php if ( function_exists( 'eco_ngo_logo_title_description' ) ) :eco_ngo_logo_title_description(); endif; ?>
					</div>
				</div>
				<div class="col-lg-7 col-md-6 col-sm-2 col-12 align-self-center">
					<div class="toggle-menu gb_menu text-md-start">
						<button onclick="eco_ngo_navigation_open()" class="gb_toggle p-2"><i class="fa fa-bars" aria-hidden="true"></i></button>
					</div>
					<div id="gb_responsive" class="nav side_gb_nav">
						<nav id="top_gb_menu" class="gb_nav_menu" role="navigation" aria-label="<?php esc_attr_e( 'Menu', 'eco-ngo' ); ?>">
							<?php 
							    wp_nav_menu( array( 
									'theme_location' => 'primary_menu',
									'container_class' => 'gb_navigation clearfix' ,
									'menu_class' => 'clearfix',
									'items_wrap' => '<ul id="%1$s" class="%2$s mobile_nav mb-0 px-0">%3$s</ul>',
									'fallback_cb' => 'wp_page_menu',
							    ) ); 
							?>
							<a href="javascript:void(0)" class="closebtn gb_menu" onclick="eco_ngo_navigation_close()">x<span class="screen-reader-text"><?php esc_html_e('Close Menu','eco-ngo'); ?></span></a>
						</nav>
					</div>
				</div>
				<div class="col-lg-2 col-md-3 col-sm-5 col-12 align-self-center">
					<div class="search_form_area">
						<?php get_search_form(); ?>
					</div>
				</div>
			</div>
		</div>
	</div>
</header>