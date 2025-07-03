<?php
function eco_ngo_premium_setting( $wp_customize ) {
	
	/*=========================================
	Page Layout Settings Section
	=========================================*/
	$wp_customize->add_section(
        'upgrade_premium',
        array(
            'title' 		=> __('Upgrade to Pro','eco-ngo'),
			'priority'      => 1,
		)
    );
	
	/*=========================================
	Add Buttons
	=========================================*/
	
	class Eco_Ngo_WP_Button_Customize_Control extends WP_Customize_Control {
	public $type = 'upgrade_premium';

	   function render_content() {
		?>
			<div class="premium_info">
				<ul>
					<li><a class="upgrade-to-pro" href="<?php echo esc_url( ECO_NGO_BUY_NOW_1 ); ?>" target="_blank"><?php esc_html_e( 'Upgrade to Pro','eco-ngo' ); ?> </a></li>
				</ul>
			</div>
			<div class="premium_info">
				<ul>
					<li><a class="upgrade-to-pro" href="<?php echo esc_url( ECO_NGO_DEMO_PRO ); ?>" target="_blank"><?php esc_html_e( 'Live Demo','eco-ngo' ); ?></a></li>
				</ul>
			</div>
			<div class="premium_info">
				<ul>
					<li><a class="upgrade-to-pro" href="<?php echo esc_url( ECO_NGO_DOCS_FREE ); ?>" target="_blank"><?php esc_html_e( 'Free Documentation','eco-ngo' ); ?> </a></li>
				</ul>
			</div>
			<div class="premium_info discount-box">
				<ul>
					<li class="discount-text"><?php esc_html_e( 'Special Discount of 35% Use Code “winter35”','eco-ngo' ); ?></li>
					<li><a class="upgrade-to-pro" href="<?php echo esc_url( ECO_NGO_BUNDLE ); ?>" target="_blank"><?php esc_html_e( 'WordPress Theme Bundle','eco-ngo' ); ?> </a></li>
				</ul>
			</div>
		<?php
	   }
	}
	
	$wp_customize->add_setting('premium_info_buttons', array(
	   'capability'     => 'edit_theme_options',
		'sanitize_callback' => 'eco_ngo_sanitize_text',
	));
		
	$wp_customize->add_control( new Eco_Ngo_WP_Button_Customize_Control( $wp_customize, 'premium_info_buttons', array(
		'section' => 'upgrade_premium',
    ))
);
}
add_action( 'customize_register', 'eco_ngo_premium_setting' );