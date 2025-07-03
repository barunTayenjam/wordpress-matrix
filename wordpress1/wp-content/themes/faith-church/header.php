<!doctype html>
<html <?php language_attributes(); ?>> <!-- Setting the HTML language attributes dynamically using WordPress functions -->
<head>
	<meta charset="<?php bloginfo( 'charset' ); ?>"> <!-- Setting character encoding dynamically -->
	<meta name="viewport" content="width=device-width, initial-scale=1"> <!-- Making the site responsive -->
	<link rel="profile" href="https://gmpg.org/xfn/11"> <!-- XFN profile link for better linking semantics -->

	<?php wp_head(); ?> <!-- WordPress function to insert necessary header elements (styles, scripts, etc.) -->
</head>

<body <?php body_class(); ?>> <!-- Adding dynamic body classes for styling flexibility -->
<?php wp_body_open(); ?> <!-- Ensuring compatibility with WordPress themes by calling the wp_body_open function -->

<div id="page" class="site"> <!-- Main site container -->
	<a class="skip-link screen-reader-text" href="#primary">
		<?php esc_html_e( 'Skip to content', 'faith-church' ); ?> <!-- Accessibility: Skip link to main content -->
	</a>

	<header id="masthead" class="site-header"> <!-- Site header section -->
		<div class="container main-header"> <!-- Header container for layout control -->

        	<div class="site-branding"> <!-- Site branding section containing logo and site details -->
        		<div class="site-logo">
					<?php the_custom_logo(); ?> <!-- Display the custom logo if set in WordPress -->
				</div>

        		<div class="site-details"> <!-- Site title and description -->
					<?php if ( is_front_page() && is_home() ) : ?> <!-- Check if on the front page -->
						<h1 class="site-title">
							<a href="<?php echo esc_url( home_url( '/' ) ); ?>" rel="home">
								<?php bloginfo( 'name' ); ?> <!-- Display the site title -->
							</a>
						</h1>
					<?php else : ?>
						<p class="site-title">
							<a href="<?php echo esc_url( home_url( '/' ) ); ?>" rel="home">
								<?php bloginfo( 'name' ); ?> <!-- Display the site title inside a paragraph for other pages -->
							</a>
						</p>
					<?php endif; ?>

					<?php 
					$faith_church_description = get_bloginfo( 'description', 'display' ); // Get site description
					if ( $faith_church_description || is_customize_preview() ) : ?> 
						<p class="site-description">
							<?php echo esc_html($faith_church_description); ?> <!-- Display the site description -->
						</p>
					<?php endif; ?>
				</div><!-- .site-details -->
			</div><!-- .site-branding -->

			<nav id="site-navigation" class="main-navigation"> <!-- Main navigation section -->
				<button class="main-navigation-toggle"></button> <!-- Button for mobile navigation toggle -->

				<?php
					wp_nav_menu(
						array(
							'theme_location' => 'menu-1', // Display the menu assigned to 'menu-1' location
		    				'container'      => false,   // Prevents additional wrapping container
						)
					);
				?>
			</nav><!-- #site-navigation -->
		</div><!-- .container -->
	</header><!-- #masthead -->

	<div id="content" class="site-content"> <!-- Main content wrapper -->
		<div id="header-media"> <!-- Header media section -->
			<?php the_custom_header_markup(); ?> <!-- Display the custom header image or video -->
		</div><!-- #header-media -->
