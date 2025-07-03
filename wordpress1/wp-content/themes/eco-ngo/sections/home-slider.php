<?php if ( true == get_theme_mod( 'eco_ngo_slide_on_off', 'on' ) ) : ?>

<?php $eco_ngo_slide_count = get_theme_mod('eco_ngo_slide_count'); ?>

<section id="home_slider">
	<div class="slider-box">
		<?php for ($i=1; $i <= $eco_ngo_slide_count; $i++) {
			$eco_ngo_slider_image = get_theme_mod('eco_ngo_slider_image'.$i);
			$eco_ngo_slider_heading = get_theme_mod('eco_ngo_slider_heading');
			$eco_ngo_slider_content = get_theme_mod('eco_ngo_slider_content');
			$eco_ngo_banner_heading_link = get_theme_mod('eco_ngo_banner_heading_link'.$i); 
			$eco_ngo_banner_heading = get_theme_mod('eco_ngo_banner_heading'.$i);
			$eco_ngo_slider_button_link = get_theme_mod('eco_ngo_slider_button_link'); 
			$eco_ngo_slider_button_text = get_theme_mod('eco_ngo_slider_button_text'); 
			?>

			<div class="slider_main_box">
				<?php if ( ! empty( $eco_ngo_slider_image ) ) : ?>
					<img src="<?php echo esc_url( $eco_ngo_slider_image ); ?>">
					<div class="slider_content_box">
						<div class="slider_heading">
							<?php if ( ! empty( $eco_ngo_banner_heading_link ) || ! empty( $eco_ngo_banner_heading ) ): ?>
								<a class="heading-btn" href="<?php echo esc_url( $eco_ngo_banner_heading_link ); ?>"><?php echo esc_html( $eco_ngo_banner_heading ); ?>
									<svg xmlns="http://www.w3.org/2000/svg" height="2em" viewBox="0 0 512 512"><!--!Font Awesome Free 6.7.1 by @fontawesome - https://fontawesome.com License - https://fontawesome.com/license/free Copyright 2024 Fonticons, Inc.--><path d="M416 448h-84c-6.6 0-12-5.4-12-12v-40c0-6.6 5.4-12 12-12h84c17.7 0 32-14.3 32-32V160c0-17.7-14.3-32-32-32h-84c-6.6 0-12-5.4-12-12V76c0-6.6 5.4-12 12-12h84c53 0 96 43 96 96v192c0 53-43 96-96 96zm-47-201L201 79c-15-15-41-4.5-41 17v96H24c-13.3 0-24 10.7-24 24v96c0 13.3 10.7 24 24 24h136v96c0 21.5 26 32 41 17l168-168c9.3-9.4 9.3-24.6 0-34z"/></svg>
								</a>
							<?php endif; ?>
						</div>
					</div>
				<?php endif; ?>
			</div>
		<?php } ?>
	</div>
	<div class="banner-conetnt">
		<?php if ( ! empty( $eco_ngo_slider_heading ) ) : ?>
			<h3><?php echo esc_html( $eco_ngo_slider_heading ); ?></h3>
		<?php endif; ?>
		<?php if ( ! empty( $eco_ngo_slider_content ) ) : ?>
			<p><?php echo esc_html( $eco_ngo_slider_content ); ?></p>
		<?php endif; ?>
		<div class="slider_button mt-4">
			<?php if ( ! empty( $eco_ngo_slider_button_link ) || ! empty( $eco_ngo_slider_button_text ) ): ?>
				<a class="button1" href="<?php echo esc_url( $eco_ngo_slider_button_link ); ?>"><?php echo esc_html( $eco_ngo_slider_button_text ); ?></a>
			<?php endif; ?>
		</div>
	</div>
</section>

<?php endif; ?>