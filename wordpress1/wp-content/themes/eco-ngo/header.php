<!DOCTYPE html>
<html <?php language_attributes(); ?>>
	<head>
	<meta charset="<?php bloginfo( 'charset' ); ?>">
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<link rel="profile" href="https://gmpg.org/xfn/11">
	<?php if ( is_singular() && pings_open( get_queried_object() ) ) : ?>
	<link rel="pingback" href="<?php echo esc_url(get_bloginfo( 'pingback_url' )); ?>">
	<?php endif; ?>

	<?php wp_head(); ?>
</head>
	

<body <?php body_class('eco-ngo eco-ngo-btn'); ?>>
<?php wp_body_open(); ?>

<?php if ( get_theme_mod( 'eco_ngo_preloader_setting', false ) == 1 || get_theme_mod( 'eco_ngo_responsive_preloader_setting', false ) == 1 ) { ?>
	<div class="loading">
		<div class="loader">
		    <div class="line-1"></div>
		    <div class="line-2"></div>
		    <div class="loader-text">
		        <p><?php esc_html_e( 'LOADING', 'eco-ngo' ); ?></p>
		    </div>
		</div>
	</div>
<?php } ?>

	<div id="page" class="site">
		<a class="skip-link screen-reader-text" href="#content"><?php esc_html_e( 'Skip to content', 'eco-ngo' ); ?></a>
	<?php
		get_template_part('sections/header');
	?>
	<div id="content">