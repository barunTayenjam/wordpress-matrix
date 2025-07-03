<?php
/**
 * eco-ngo Theme Customizer.
 *
 * @package eco-ngo
 */

/**
 * Add postMessage support for site title and description for the Theme Customizer.
 *
 * @param WP_Customize_Manager $wp_customize Theme Customizer object.
 */
function eco_ngo_customize_register( $wp_customize ) {
	$wp_customize->get_setting( 'blogname' )->transport         = 'postMessage';
	$wp_customize->get_setting( 'blogdescription' )->transport  = 'postMessage';
	$wp_customize->get_setting( 'header_textcolor' )->transport = 'postMessage';
	$wp_customize->get_setting( 'background_color' )->transport = 'postMessage';
	$wp_customize->get_setting('custom_logo')->transport = 'refresh';	
}
add_action( 'customize_register', 'eco_ngo_customize_register' );

if ( ! defined( 'ECO_NGO_BUY_NOW_1' ) ) {
define('ECO_NGO_BUY_NOW_1',__('https://www.mishkatwp.com/themes/eco-ngo-wordpress-theme/','eco-ngo'));
}

if ( ! defined( 'ECO_NGO_BUNDLE_1' ) ) {
define('ECO_NGO_BUNDLE_1',__('https://www.mishkatwp.com/themes/wordpress-theme-bundle/','eco-ngo'));
}

if ( class_exists("Kirki")){

    //Post & Pages Setting Panel
	new \Kirki\Panel(
		'eco_ngo_post_pages_section',
		[
			'priority'    => 11,
			'title'       => esc_html__( 'Post & Pages Settings', 'eco-ngo' ),
		]
	);

	/* Banner Options */

	new \Kirki\Section(
		'eco_ngo_banner_options',
		[
			'title'       => esc_html__( 'Banner Image Settings', 'eco-ngo' ),
			'priority'    => 30,
			'panel'		  => 'eco_ngo_post_pages_section',
		]
	);

	new \Kirki\Field\Image(
		[
			'settings'    => 'eco_ngo_custom_fallback_img',
			'label'       => esc_html__( 'Featured Header Image Banner Background', 'eco-ngo' ),
			'section'     => 'eco_ngo_banner_options',
			'default'     => '',
		]
	);

	Kirki::add_field( 'theme_config_id', [
		'label'    => esc_html__( 'Buy Our Premium Theme For More Feature', 'eco-ngo' ),
		'default'  => 
	        '<a class="premium_info_btn" target="_blank" href="' . esc_url( ECO_NGO_BUY_NOW_1 ) . '">' . __( 'Buy Pro', 'eco-ngo' ) . '</a>' .
	        '<a class="premium_info_btn bundle" target="_blank" href="' . esc_url( ECO_NGO_BUNDLE_1 ) . '">' . __( 'Buy All Themes In Single Package', 'eco-ngo' ) . '</a>',
        'type'        => 'custom',
        'section'     => 'eco_ngo_banner_options',
    ] );


	/* Single Post Options */

	new \Kirki\Section(
		'eco_ngo_single_post_options',
		[
			'title'       => esc_html__( 'Single Post Options', 'eco-ngo' ),
			'priority'    => 30,
			'panel'		  => 'eco_ngo_post_pages_section',
		]
	);
    
    /* Single Post Heading Option End */
	new \Kirki\Field\Checkbox_Switch(
		[
			'settings'    => 'eco_ngo_single_post_heading_on_off',
			'label'       => esc_html__( 'Single Post Heading On / Off', 'eco-ngo' ),
			'section'     => 'eco_ngo_single_post_options',
			'default'     => 'on',
			'choices'     => [
				'on'  => esc_html__( 'Enable', 'eco-ngo' ),
				'off' => esc_html__( 'Disable', 'eco-ngo' ),
			],
		]
	);

	/* Single Post Content Option End */
	new \Kirki\Field\Checkbox_Switch(
		[
			'settings'    => 'eco_ngo_single_post_content_on_off',
			'label'       => esc_html__( 'Single Post Content On / Off', 'eco-ngo' ),
			'section'     => 'eco_ngo_single_post_options',
			'default'     => 'on',
			'choices'     => [
				'on'  => esc_html__( 'Enable', 'eco-ngo' ),
				'off' => esc_html__( 'Disable', 'eco-ngo' ),
			],
		]
	);

	/* Single Post Meta Option End */
	new \Kirki\Field\Checkbox_Switch(
		[
			'settings'    => 'eco_ngo_single_meta_on_off',
			'label'       => esc_html__( 'Single Post Meta On / Off', 'eco-ngo' ),
			'section'     => 'eco_ngo_single_post_options',
			'default'     => 'on',
			'choices'     => [
				'on'  => esc_html__( 'Enable', 'eco-ngo' ),
				'off' => esc_html__( 'Disable', 'eco-ngo' ),
			],
		]
	);

	/* Single Post Feature Image Option End */
	new \Kirki\Field\Checkbox_Switch(
		[
			'settings'    => 'eco_ngo_single_post_image_on_off',
			'label'       => esc_html__( 'Single Post Feature Image On / Off', 'eco-ngo' ),
			'section'     => 'eco_ngo_single_post_options',
			'default'     => 'on',
			'choices'     => [
				'on'  => esc_html__( 'Enable', 'eco-ngo' ),
				'off' => esc_html__( 'Disable', 'eco-ngo' ),
			],
		]
	);

	/* Single Post Pagination Option End */
	new \Kirki\Field\Checkbox_Switch(
		[
			'settings'    => 'eco_ngo_single_post_pagination_on_off',
			'label'       => esc_html__( 'Single Post Pagination On / Off', 'eco-ngo' ),
			'section'     => 'eco_ngo_single_post_options',
			'default'     => 'on',
			'choices'     => [
				'on'  => esc_html__( 'Enable', 'eco-ngo' ),
				'off' => esc_html__( 'Disable', 'eco-ngo' ),
			],
		]
	);

	Kirki::add_field( 'theme_config_id', [
		'label'    => esc_html__( 'Buy Our Premium Theme For More Features', 'eco-ngo' ),
		'default'  => 
	        '<a class="premium_info_btn" target="_blank" href="' . esc_url( ECO_NGO_BUY_NOW_1 ) . '">' . __( 'Buy Pro', 'eco-ngo' ) . '</a>' .
	        '<a class="premium_info_btn bundle" target="_blank" href="' . esc_url( ECO_NGO_BUNDLE_1 ) . '">' . __( 'Buy All Themes In Single Package', 'eco-ngo' ) . '</a>',
        'type'        => 'custom',
        'section'     => 'eco_ngo_single_post_options',
    ] );

	/* Page Options */
		new \Kirki\Section(
		'eco_ngo_single_page_options',
		[
			'title'       => esc_html__( 'Page Sidebar Options', 'eco-ngo' ),
			'priority'    => 30,
			'panel'		  => 'eco_ngo_post_pages_section',
		]
	);

	new \Kirki\Field\Radio(
	[
		'settings'    => 'eco_ngo_single_page_sidebar_option',
		'label'       => esc_html__( 'Page Sidebar Settings', 'eco-ngo' ),
		'section'     => 'eco_ngo_single_page_options',
		'default'     => 'right',
		'priority'    => 10,
		'choices'     => [
			'right'   => esc_html__( 'Page With Right Sidebar', 'eco-ngo' ),
			'left' => esc_html__( 'Page With Left Sidebar', 'eco-ngo' ),
			'none'  => esc_html__( 'Page With No Sidebar', 'eco-ngo' ),

		],
	]
);

	Kirki::add_field( 'theme_config_id', [
		'label'    => esc_html__( 'Buy Our Premium Theme For More Features', 'eco-ngo' ),
		'default'  => 
	        '<a class="premium_info_btn" target="_blank" href="' . esc_url( ECO_NGO_BUY_NOW_1 ) . '">' . __( 'Buy Pro', 'eco-ngo' ) . '</a>' .
	        '<a class="premium_info_btn bundle" target="_blank" href="' . esc_url( ECO_NGO_BUNDLE_1 ) . '">' . __( 'Buy All Themes In Single Package', 'eco-ngo' ) . '</a>',
        'type'        => 'custom',
        'section'     => 'eco_ngo_single_page_options',
    ] );
	/* Page Options End*/

	/* Post Options */

	new \Kirki\Section(
		'eco_ngo_post_options',
		[
			'title'       => esc_html__( 'Post Options', 'eco-ngo' ),
			'priority'    => 30,
			'panel'		  => 'eco_ngo_post_pages_section',
		]
	);
    
    /* Post Image Option End */
	new \Kirki\Field\Checkbox_Switch(
		[
			'settings'    => 'eco_ngo_post_image_on_off',
			'label'       => esc_html__( 'Post Image On / Off', 'eco-ngo' ),
			'section'     => 'eco_ngo_post_options',
			'default'     => 'on',
			'choices'     => [
				'on'  => esc_html__( 'Enable', 'eco-ngo' ),
				'off' => esc_html__( 'Disable', 'eco-ngo' ),
			],
		]
	);

	/* Post Heading Option End */
	new \Kirki\Field\Checkbox_Switch(
		[
			'settings'    => 'eco_ngo_post_heading_on_off',
			'label'       => esc_html__( 'Post Heading On / Off', 'eco-ngo' ),
			'section'     => 'eco_ngo_post_options',
			'default'     => 'on',
			'choices'     => [
				'on'  => esc_html__( 'Enable', 'eco-ngo' ),
				'off' => esc_html__( 'Disable', 'eco-ngo' ),
			],
		]
	);

	/* Post Content Option End */
	new \Kirki\Field\Checkbox_Switch(
		[
			'settings'    => 'eco_ngo_post_content_on_off',
			'label'       => esc_html__( 'Post Content On / Off', 'eco-ngo' ),
			'section'     => 'eco_ngo_post_options',
			'default'     => 'on',
			'choices'     => [
				'on'  => esc_html__( 'Enable', 'eco-ngo' ),
				'off' => esc_html__( 'Disable', 'eco-ngo' ),
			],
		]
	);

	/* Post Date Option End */
	new \Kirki\Field\Checkbox_Switch(
		[
			'settings'    => 'eco_ngo_post_date_on_off',
			'label'       => esc_html__( 'Post Date On / Off', 'eco-ngo' ),
			'section'     => 'eco_ngo_post_options',
			'default'     => 'on',
			'choices'     => [
				'on'  => esc_html__( 'Enable', 'eco-ngo' ),
				'off' => esc_html__( 'Disable', 'eco-ngo' ),
			],
		]
	);

	/* Post Comments Option End */
	new \Kirki\Field\Checkbox_Switch(
		[
			'settings'    => 'eco_ngo_post_comment_on_off',
			'label'       => esc_html__( 'Post Comments On / Off', 'eco-ngo' ),
			'section'     => 'eco_ngo_post_options',
			'default'     => 'on',
			'choices'     => [
				'on'  => esc_html__( 'Enable', 'eco-ngo' ),
				'off' => esc_html__( 'Disable', 'eco-ngo' ),
			],
		]
	);

	/* Post Author Option End */
	new \Kirki\Field\Checkbox_Switch(
		[
			'settings'    => 'eco_ngo_post_author_on_off',
			'label'       => esc_html__( 'Post Author On / Off', 'eco-ngo' ),
			'section'     => 'eco_ngo_post_options',
			'default'     => 'on',
			'choices'     => [
				'on'  => esc_html__( 'Enable', 'eco-ngo' ),
				'off' => esc_html__( 'Disable', 'eco-ngo' ),
			],
		]
	);

	/* Post Categories Option End */
	new \Kirki\Field\Checkbox_Switch(
		[
			'settings'    => 'eco_ngo_post_categories_on_off',
			'label'       => esc_html__( 'Post Categories On / Off', 'eco-ngo' ),
			'section'     => 'eco_ngo_post_options',
			'default'     => 'on',
			'choices'     => [
				'on'  => esc_html__( 'Enable', 'eco-ngo' ),
				'off' => esc_html__( 'Disable', 'eco-ngo' ),
			],
		]
	);

	/* Post limit Option End */
	new \Kirki\Field\Slider(
		[
			'settings'    => 'eco_ngo_post_content_limit',
			'label'       => esc_html__( 'Post Content Limit', 'eco-ngo' ),
			'section'     => 'eco_ngo_post_options',
			'default'     => 15,
			'choices'     => [
				'min'  => 0,
				'max'  => 50,
				'step' => 1,
			],
		]
	);

	Kirki::add_field( 'theme_config_id', [
		'label'    => esc_html__( 'Buy Our Premium Theme For More Features', 'eco-ngo' ),
		'default'  => 
	        '<a class="premium_info_btn" target="_blank" href="' . esc_url( ECO_NGO_BUY_NOW_1 ) . '">' . __( 'Buy Pro', 'eco-ngo' ) . '</a>' .
	        '<a class="premium_info_btn bundle" target="_blank" href="' . esc_url( ECO_NGO_BUNDLE_1 ) . '">' . __( 'Buy All Themes In Single Package', 'eco-ngo' ) . '</a>',
        'type'        => 'custom',
        'section'     => 'eco_ngo_post_options',
    ] );

	/* Post Options End */

	/* Post Options */

	new \Kirki\Section(
		'eco_ngo_post_layouts_section',
		[
			'title'       => esc_html__( 'Post Layout Options', 'eco-ngo' ),
			'priority'    => 30,
			'panel'		  => 'eco_ngo_post_pages_section',
		]
	);

	new \Kirki\Field\Radio_Image(
		[
			'settings'    => 'eco_ngo_post_layout',
			'label'       => esc_html__( 'Blog Layout', 'eco-ngo' ),
			'section'     => 'eco_ngo_post_layouts_section',
			'default'     => 'two_column_right',
			'priority'    => 10,
			'choices'     => [
				'one_column'   => get_template_directory_uri().'/images/1column.png',
				'two_column_right' => get_template_directory_uri().'/images/right-sidebar.png',
				'two_column_left'  => get_template_directory_uri().'/images/left-sidebar.png',
				'three_column'  => get_template_directory_uri().'/images/3column.png',
				'four_column'  => get_template_directory_uri().'/images/4column.png',
				'grid_post'  => get_template_directory_uri().'/images/grid.png',
			],
		]
	);

	Kirki::add_field( 'theme_config_id', [
		'label'    => esc_html__( 'Buy Our Premium Theme For More Features', 'eco-ngo' ),
		'default'  => 
	        '<a class="premium_info_btn" target="_blank" href="' . esc_url( ECO_NGO_BUY_NOW_1 ) . '">' . __( 'Buy Pro', 'eco-ngo' ) . '</a>' .
	        '<a class="premium_info_btn bundle" target="_blank" href="' . esc_url( ECO_NGO_BUNDLE_1 ) . '">' . __( 'Buy All Themes In Single Package', 'eco-ngo' ) . '</a>',
        'type'        => 'custom',
        'section'     => 'eco_ngo_post_layouts_section',
    ] );

	/* Post Options End */

	/* 404 Page */

	new \Kirki\Section(
		'eco_ngo_404_page_section',
		[
			'title'       => esc_html__( '404 Page', 'eco-ngo' ),
			'description' => esc_html__( 'Here you can add 404 Page information.', 'eco-ngo' ),
			'priority'    => 30,
		]
	);

	new \Kirki\Field\Text(
		[
			'settings' => 'eco_ngo_404_page_heading',
			'label'    => esc_html__( 'Add Heading', 'eco-ngo' ),
			'section'  => 'eco_ngo_404_page_section',
			'default'  => esc_html__( '404', 'eco-ngo' ),
			'priority' => 10,
		]
	);

	new \Kirki\Field\Text(
		[
			'settings' => 'eco_ngo_404_page_content',
			'label'    => esc_html__( 'Add Content', 'eco-ngo' ),
			'section'  => 'eco_ngo_404_page_section',
			'default'  => esc_html__( 'Ops! Something happened...', 'eco-ngo' ),
			'priority' => 10,
		]
	);

	new \Kirki\Field\Text(
		[
			'settings' => 'eco_ngo_404_page_button',
			'label'    => esc_html__( 'Add Button', 'eco-ngo' ),
			'section'  => 'eco_ngo_404_page_section',
			'default'  => esc_html__( 'Home', 'eco-ngo' ),
			'priority' => 10,
		]
	);

	Kirki::add_field( 'theme_config_id', [
		'label'    => esc_html__( 'Buy Our Premium Theme For More Features', 'eco-ngo' ),
		'default'  => 
	        '<a class="premium_info_btn" target="_blank" href="' . esc_url( ECO_NGO_BUY_NOW_1 ) . '">' . __( 'Buy Pro', 'eco-ngo' ) . '</a>' .
	        '<a class="premium_info_btn bundle" target="_blank" href="' . esc_url( ECO_NGO_BUNDLE_1 ) . '">' . __( 'Buy All Themes In Single Package', 'eco-ngo' ) . '</a>',
        'type'        => 'custom',
        'section'     => 'eco_ngo_404_page_section',
    ] );

	/* 404 Page End */

	/* Logo */

	/* Logo Size limit Option End */
	new \Kirki\Field\Slider(
		[
			'settings'    => 'eco_ngo_logo_resizer_setting',
			'label'       => esc_html__( 'Logo Size Limit', 'eco-ngo' ),
			'section'     => 'title_tagline',
			'default'     => 70,
			'choices'     => [
				'min'  => 10,
				'max'  => 300,
				'step' => 10,
			],
		]
	);

	new \Kirki\Field\Checkbox_Switch(
		[
			'settings'    => 'eco_ngo_site_title_setting',
			'label'       => esc_html__( 'Site Title On / Off', 'eco-ngo' ),
			'section'     => 'title_tagline',
			'default'     => 'on',
			'choices'     => [
				'on'  => esc_html__( 'Enable', 'eco-ngo' ),
				'off' => esc_html__( 'Disable', 'eco-ngo' ),
			],
		]
	);

	new \Kirki\Field\Checkbox_Switch(
		[
			'settings'    => 'eco_ngo_tagline_setting',
			'label'       => esc_html__( 'Tagline On / Off', 'eco-ngo' ),
			'section'     => 'title_tagline',
			'default'     => 'off',
			'choices'     => [
				'on'  => esc_html__( 'Enable', 'eco-ngo' ),
				'off' => esc_html__( 'Disable', 'eco-ngo' ),
			],
		]
	);

	Kirki::add_field( 'theme_config_id', [
		'label'    => esc_html__( 'Buy Our Premium Theme For More Features', 'eco-ngo' ),
		'default'  => 
	        '<a class="premium_info_btn" target="_blank" href="' . esc_url( ECO_NGO_BUY_NOW_1 ) . '">' . __( 'Buy Pro', 'eco-ngo' ) . '</a>' .
	        '<a class="premium_info_btn bundle" target="_blank" href="' . esc_url( ECO_NGO_BUNDLE_1 ) . '">' . __( 'Buy All Themes In Single Package', 'eco-ngo' ) . '</a>',
        'type'        => 'custom',
        'section'     => 'title_tagline',
        'priority'     => 1000,
    ] );


	/* Logo End */

	/* Responsive Options */

	new \Kirki\Section(
		'eco_ngo_responsive_options_section',
		[
			'title'       => esc_html__( 'Responsive Options', 'eco-ngo' ),
			'priority'    => 30,
		]
	);

	new \Kirki\Field\Checkbox_Switch(
		[
			'settings'    => 'eco_ngo_responsive_preloader_setting',
			'label'       => esc_html__( 'Preloader On / Off', 'eco-ngo' ),
			'section'     => 'eco_ngo_responsive_options_section',
			'default'     => 'off',
			'choices'     => [
				'on'  => esc_html__( 'Enable', 'eco-ngo' ),
				'off' => esc_html__( 'Disable', 'eco-ngo' ),
			],
		]
	);

	new \Kirki\Field\Checkbox_Switch(
		[
			'settings'    => 'eco_ngo_responsive_scroll_to_top_setting',
			'label'       => esc_html__( 'Scroll To Top On / Off', 'eco-ngo' ),
			'section'     => 'eco_ngo_responsive_options_section',
			'default'     => 'on',
			'choices'     => [
				'on'  => esc_html__( 'Enable', 'eco-ngo' ),
				'off' => esc_html__( 'Disable', 'eco-ngo' ),
			],
		]
	);

	Kirki::add_field( 'theme_config_id', [
		'label'    => esc_html__( 'Buy Our Premium Theme For More Feature', 'eco-ngo' ),
		'default'  => 
	        '<a class="premium_info_btn" target="_blank" href="' . esc_url( ECO_NGO_BUY_NOW_1 ) . '">' . __( 'Buy Pro', 'eco-ngo' ) . '</a>' .
	        '<a class="premium_info_btn bundle" target="_blank" href="' . esc_url( ECO_NGO_BUNDLE_1 ) . '">' . __( 'Buy All Themes In Single Package', 'eco-ngo' ) . '</a>',
        'type'        => 'custom',
        'section'     => 'eco_ngo_responsive_options_section',
    ] );


	/* Responsive End */

	/* General Options */

	new \Kirki\Section(
		'eco_ngo_general_options_section',
		[
			'title'       => esc_html__( 'General Options', 'eco-ngo' ),
			'priority'    => 10,
		]
	);

	new \Kirki\Field\Checkbox_Switch(
		[
			'settings'    => 'eco_ngo_sticky_header_setting',
			'label'       => esc_html__( 'Show Hide Sticky Header', 'eco-ngo' ),
			'section'     => 'eco_ngo_general_options_section',
			'default'     => 'off',
			'choices'     => [
				'on'  => esc_html__( 'Enable', 'eco-ngo' ),
				'off' => esc_html__( 'Disable', 'eco-ngo' ),
			],
		]
	);

	new \Kirki\Field\Checkbox_Switch(
		[
			'settings'    => 'eco_ngo_preloader_setting',
			'label'       => esc_html__( 'Preloader On / Off', 'eco-ngo' ),
			'section'     => 'eco_ngo_general_options_section',
			'default'     => 'off',
			'choices'     => [
				'on'  => esc_html__( 'Enable', 'eco-ngo' ),
				'off' => esc_html__( 'Disable', 'eco-ngo' ),
			],
		]
	);

	new \Kirki\Field\Checkbox_Switch(
		[
			'settings'    => 'eco_ngo_scroll_to_top_setting',
			'label'       => esc_html__( 'Scroll To Top On / Off', 'eco-ngo' ),
			'section'     => 'eco_ngo_general_options_section',
			'default'     => 'on',
			'choices'     => [
				'on'  => esc_html__( 'Enable', 'eco-ngo' ),
				'off' => esc_html__( 'Disable', 'eco-ngo' ),
			],
		]
	);

	new \Kirki\Field\Select(
		[
			'settings'    => 'eco_ngo_scroll_to_top_type',
			'label'       => esc_html__( 'Scroll To Top Type', 'eco-ngo' ),
			'section'     => 'eco_ngo_general_options_section',
			'default' => 'advance-scroll',
			'placeholder' => esc_html__( 'Choose an option', 'eco-ngo' ),
			'choices'     => [
				'advance-scroll' => __('Type 1','eco-ngo'),
	            'simple-scroll' => __('Type 2','eco-ngo'),
			],
	] );

	new \Kirki\Field\Select(
	[
		'settings'    => 'eco_ngo_scroll_top_alignment',
		'label'       => esc_html__( 'Scroll Top Alignment', 'eco-ngo' ),
		'section'     => 'eco_ngo_general_options_section',
		'default'     => 'Right',
		'choices'     => [
			'Left' => esc_html__( 'Left Align', 'eco-ngo' ),
			'Center' => esc_html__( 'Center Align', 'eco-ngo' ),
			'Right' => esc_html__( 'Right Align', 'eco-ngo' ),
		],
	]
);

	Kirki::add_field( 'theme_config_id', [
		'type'        => 'slider',
		'settings'    => 'eco_ngo_container_width',
		'label'       => esc_html__( 'Theme Container Width', 'eco-ngo' ),
		'section'     => 'eco_ngo_general_options_section',
		'default'     => 100,
		'choices'     => [
			'min'  => 50,
			'max'  => 100,
			'step' => 1,
		],
	] );

	Kirki::add_field( 'theme_config_id', [
		'label'    => esc_html__( 'Buy Our Premium Theme For More Features', 'eco-ngo' ),
		'default'  => 
	        '<a class="premium_info_btn" target="_blank" href="' . esc_url( ECO_NGO_BUY_NOW_1 ) . '">' . __( 'Buy Pro', 'eco-ngo' ) . '</a>' .
	        '<a class="premium_info_btn bundle" target="_blank" href="' . esc_url( ECO_NGO_BUNDLE_1 ) . '">' . __( 'Buy All Themes In Single Package', 'eco-ngo' ) . '</a>',
        'type'        => 'custom',
        'section'     => 'eco_ngo_general_options_section',
        'priority'     => 1000,
    ] );

	/* General Options End */

	/* Typography Section */

	new \Kirki\Section(
		'eco_ngo_theme_typography_section',
		[
			'title'       => esc_html__( 'Theme Typography', 'eco-ngo' ),
			'description' => esc_html__( 'Here you can customize Heading or other body text font settings', 'eco-ngo' ),
			'priority'    => 30,
		]
	);

	Kirki::add_field( 'theme_config_id', [
		'type'        => 'custom',
		'settings'    => 'eco_ngo_all_headings_typography',
		'section'     => 'eco_ngo_theme_typography_section',
			'default'         => '<h3 style="color: #2271b1; padding:10px; background:#fff; margin:0; border-left: solid 5px #2271b1; ">' . __( 'Heading Of All Sections',  'eco-ngo' ) . '</h3>',
		'priority'    => 10,
	] );

	Kirki::add_field( 'global', array(
		'type'        => 'typography',
		'settings'    => 'eco_ngo_all_headings_typography',
		'label'       => esc_html__( 'Heading Typography',  'eco-ngo' ),
		'description' => esc_html__( 'Select the typography options for your heading.',  'eco-ngo' ),
		'section'     => 'eco_ngo_theme_typography_section',
		'priority'    => 10,
		'default'     => array(
			'font-family'    => '',
			'variant'        => '',
		),
		'output' => array(
			array(
				'element' => array( 'h1','h2','h3','h4','h5','h6', ),
			),
		),
	) );

	Kirki::add_field( 'theme_config_id', [
		'type'        => 'custom',
		'settings'    => 'eco_ngo_body_content_typography',
		'section'     => 'eco_ngo_theme_typography_section',
			'default'         => '<h3 style="color: #2271b1; padding:10px; background:#fff; margin:0; border-left: solid 5px #2271b1; ">' . __( 'Body Content',  'eco-ngo' ) . '</h3>',
		'priority'    => 10,
	] );

	Kirki::add_field( 'global', array(
		'type'        => 'typography',
		'settings'    => 'eco_ngo_body_content_typography',
		'label'       => esc_html__( 'Content Typography',  'eco-ngo' ),
		'description' => esc_html__( 'Select the typography options for your content.',  'eco-ngo' ),
		'section'     => 'eco_ngo_theme_typography_section',
		'priority'    => 10,
		'default'     => array(
			'font-family'    => '',
			'variant'        => '',
		),
		'output' => array(
			array(
				'element' => array( 'body', ),
			),
		),
	) );

	Kirki::add_field( 'theme_config_id', [
		'label'    => esc_html__( 'Buy Our Premium Theme For More Features', 'eco-ngo' ),
		'default'  => 
	        '<a class="premium_info_btn" target="_blank" href="' . esc_url( ECO_NGO_BUY_NOW_1 ) . '">' . __( 'Buy Pro', 'eco-ngo' ) . '</a>' .
	        '<a class="premium_info_btn bundle" target="_blank" href="' . esc_url( ECO_NGO_BUNDLE_1 ) . '">' . __( 'Buy All Themes In Single Package', 'eco-ngo' ) . '</a>',
        'type'        => 'custom',
        'section'     => 'eco_ngo_theme_typography_section',
    ] );

    /* End Typography */

        /* Woocommerce Section */

	new \Kirki\Section(
		'eco_ngo_theme_product_sidebar',
		[
			'title'       => esc_html__( 'Woocommerce Sidebars', 'eco-ngo' ),
			'description' => esc_html__( 'Here you can change woocommerce sidebar', 'eco-ngo' ),
			'panel' =>'woocommerce',
			'priority'    => 30,
		]
	);

	new \Kirki\Field\Select(
		[
			'settings'    => 'eco_ngo_product_sidebar_position',
			'label'       => esc_html__( 'Sidebar Option', 'eco-ngo' ),
			'section'     => 'eco_ngo_theme_product_sidebar',
			'default'     => 'right',
			'choices'     => [
				'left' => esc_html__( 'Left Sidebar', 'eco-ngo' ),
				'right' => esc_html__( 'Right Sidebar', 'eco-ngo' ),
				'none' => esc_html__( 'No Sidebar', 'eco-ngo' ),
			],
		]
	);

	Kirki::add_field( 'theme_config_id', [
		'label'    => esc_html__( 'Buy Our Premium Theme For More Features', 'eco-ngo' ),
		'default'  => 
	        '<a class="premium_info_btn" target="_blank" href="' . esc_url( ECO_NGO_BUY_NOW_1 ) . '">' . __( 'Buy Pro', 'eco-ngo' ) . '</a>' .
	        '<a class="premium_info_btn bundle" target="_blank" href="' . esc_url( ECO_NGO_BUNDLE_1 ) . '">' . __( 'Buy All Themes In Single Package', 'eco-ngo' ) . '</a>',
        'type'        => 'custom',
        'section'     => 'eco_ngo_theme_product_sidebar',
    ] );

    /* Woocommerce Section End */

    /* Global Color Section */

	new \Kirki\Section(
		'eco_ngo_theme_color_section',
		[
			'title'       => esc_html__( 'Theme Colors Option', 'eco-ngo' ),
			'description' => esc_html__( 'Here you can change your theme color', 'eco-ngo' ),
			'priority'    => 30,
		]
	);

	Kirki::add_field( 'theme_config_id', [
		'type'        => 'color',
		'settings'    => 'eco_ngo_theme_color_1',
		'label'       => __( 'Select Your First Color', 'eco-ngo' ),
		'section'     => 'eco_ngo_theme_color_section',
		'default'     => '#82B03D',
	] );

	Kirki::add_field( 'theme_config_id', [
		'label'    => esc_html__( 'Buy Our Premium Theme For More Features', 'eco-ngo' ),
		'default'  => 
	        '<a class="premium_info_btn" target="_blank" href="' . esc_url( ECO_NGO_BUY_NOW_1 ) . '">' . __( 'Buy Pro', 'eco-ngo' ) . '</a>' .
	        '<a class="premium_info_btn bundle" target="_blank" href="' . esc_url( ECO_NGO_BUNDLE_1 ) . '">' . __( 'Buy All Themes In Single Package', 'eco-ngo' ) . '</a>',
        'type'        => 'custom',
        'section'     => 'eco_ngo_theme_color_section',
    ] );

       /* Global Color End */

    /* Breadcrumb Section */

	new \Kirki\Section(
		'eco_ngo_breadcrumb_section',
		[
			'title'       => esc_html__( 'Theme Breadcrumb Option', 'eco-ngo' ),
			'description' => esc_html__( 'The breadcrumbs for your theme can be included here.', 'eco-ngo' ),
			'priority'    => 30,
		]
	);

	new \Kirki\Field\Checkbox_Switch(
		[
			'settings'    => 'eco_ngo_breadcrumb_setting',
			'label'       => esc_html__( 'Enable Breadcrumbs Option', 'eco-ngo' ),
			'section'     => 'eco_ngo_breadcrumb_section',
			'default'     => true,
			'choices'     => [
				'on'  => esc_html__( 'Enable', 'eco-ngo' ),
				'off' => esc_html__( 'Disable', 'eco-ngo' ),
			],
		]
	);

	Kirki::add_field( 'theme_config_id', [
	    'type'        => 'text',
	    'settings'    => 'eco_ngo_breadcrumb_separator',
	    'label'       => esc_html__( 'Breadcrumb Separator Setting', 'eco-ngo' ),
	    'section'     => 'eco_ngo_breadcrumb_section',
	    'default'     => ' → ',
	    'priority'    => 10,
	] );

	Kirki::add_field( 'theme_config_id', [
		'label'    => esc_html__( 'Buy Our Premium Theme For More Features', 'eco-ngo' ),
		'default'  => 
	        '<a class="premium_info_btn" target="_blank" href="' . esc_url( ECO_NGO_BUY_NOW_1 ) . '">' . __( 'Buy Pro', 'eco-ngo' ) . '</a>' .
	        '<a class="premium_info_btn bundle" target="_blank" href="' . esc_url( ECO_NGO_BUNDLE_1 ) . '">' . __( 'Buy All Themes In Single Package', 'eco-ngo' ) . '</a>',
        'type'        => 'custom',
        'section'     => 'eco_ngo_breadcrumb_section',
    ] );


    /* Breadcrumb section End */

	//Home page Setting Panel
	new \Kirki\Panel(
		'eco_ngo_home_page_section',
		[
			'priority'    => 10,
			'title'       => esc_html__( 'Home Page Sections', 'eco-ngo' ),
		]
	);

	/* Home Slider */

	new \Kirki\Section(
		'eco_ngo_home_slider_section',
		[
			'title'       => esc_html__( 'Home Slider', 'eco-ngo' ),
			'description' => esc_html__( 'Here you can add slider image, title and text.', 'eco-ngo' ),
			'panel'		  => 'eco_ngo_home_page_section',
			'priority'    => 30,
		]
	);

	new \Kirki\Field\Checkbox_Switch(
		[
			'settings'    => 'eco_ngo_slide_on_off',
			'label'       => esc_html__( 'Slider On / Off', 'eco-ngo' ),
			'section'     => 'eco_ngo_home_slider_section',
			'default'     => 'on',
			'choices'     => [
				'on'  => esc_html__( 'Enable', 'eco-ngo' ),
				'off' => esc_html__( 'Disable', 'eco-ngo' ),
			],
		]
	);

	new \Kirki\Field\Number(
		[
			'settings' => 'eco_ngo_slide_count',
			'label'    => esc_html__( 'Slider Number Control', 'eco-ngo' ),
			'section'  => 'eco_ngo_home_slider_section',
			'default'  => '',
			'choices'  => [
				'min'  => 1,
				'max'  => 5	,
				'step' => 1,
			],
		]
	);

	$eco_ngo_slide_count = get_theme_mod('eco_ngo_slide_count');

	for ($i=1; $i <= $eco_ngo_slide_count; $i++) { 
		
		new \Kirki\Field\Image(
			[
				'settings'    => 'eco_ngo_slider_image'.$i,
				'label'       => esc_html__( 'Slider Image 0', 'eco-ngo' ).$i,
				'section'     => 'eco_ngo_home_slider_section',
				'default'     => '',
			]
		);

		new \Kirki\Field\Text(
			[
				'settings' => 'eco_ngo_banner_heading'.$i,
				'label'    => esc_html__( 'Heading 0', 'eco-ngo' ).$i,
				'section'  => 'eco_ngo_home_slider_section',
			]
		);

		new \Kirki\Field\URL(
			[
				'settings' => 'eco_ngo_banner_heading_link'.$i,
				'label'    => esc_html__( 'Heading Url 0', 'eco-ngo' ).$i,
				'section'  => 'eco_ngo_home_slider_section',
				'default'  => '',
			]
		);

	}

		new \Kirki\Field\Text(
			[
				'settings' => 'eco_ngo_slider_heading',
				'label'    => esc_html__( 'Banner Main Heading ', 'eco-ngo' ),
				'section'  => 'eco_ngo_home_slider_section',
			]
		);

		new \Kirki\Field\Text(
			[
				'settings' => 'eco_ngo_slider_content',
				'label'    => esc_html__( 'Banner Content ', 'eco-ngo' ),
				'section'  => 'eco_ngo_home_slider_section',
			]
		);

		new \Kirki\Field\Text(
			[
				'settings' => 'eco_ngo_slider_button_text',
				'label'    => esc_html__( 'Banner Button Text ', 'eco-ngo' ),
				'section'  => 'eco_ngo_home_slider_section',
			]
		);

		new \Kirki\Field\URL(
			[
				'settings' => 'eco_ngo_slider_button_link',
				'label'    => esc_html__( 'Banner Button Url ', 'eco-ngo' ),
				'section'  => 'eco_ngo_home_slider_section',
				'default'  => '',
			]
		);

	Kirki::add_field( 'theme_config_id', [
		'label'    => esc_html__( 'Buy Our Premium Theme For More Features', 'eco-ngo' ),
		'default'  => 
	        '<a class="premium_info_btn" target="_blank" href="' . esc_url( ECO_NGO_BUY_NOW_1 ) . '">' . __( 'Buy Pro', 'eco-ngo' ) . '</a>' .
	        '<a class="premium_info_btn bundle" target="_blank" href="' . esc_url( ECO_NGO_BUNDLE_1 ) . '">' . __( 'Buy All Themes In Single Package', 'eco-ngo' ) . '</a>',
        'type'        => 'custom',
        'section'     => 'eco_ngo_home_slider_section',
        'priority'     => 1000,
    ] );

		/* Home our Cause */

		new \Kirki\Section(
		    'eco_ngo_home_industry_heroes_section',
		    [
		        'title'       => esc_html__( 'Home Our Cause', 'eco-ngo' ),
		        'description' => esc_html__( 'Here you can add industry heroes related text to display Our Cause.', 'eco-ngo' ),
		        'panel'       => 'eco_ngo_home_page_section',
		        'priority'    => 30,
		    ]
		);

		new \Kirki\Field\Checkbox_Switch(
		    [
		        'settings'    => 'eco_ngo_our_cases_on_off',
		        'label'       => esc_html__( 'Our Cause On / Off', 'eco-ngo' ),
		        'section'     => 'eco_ngo_home_industry_heroes_section',
		        'default'     => 'on',
		        'choices'     => [
		            'on'  => esc_html__( 'Enable', 'eco-ngo' ),
		            'off' => esc_html__( 'Disable', 'eco-ngo' ),
		        ],
		    ]
		);

		new \Kirki\Field\Text(
		    [
		        'settings' => 'eco_ngo_our_cases_short_heading',
		        'label'    => esc_html__( 'Main Heading', 'eco-ngo' ),
		        'section'  => 'eco_ngo_home_industry_heroes_section',
		    ]
		);

		new \Kirki\Field\Number(
		    [
		        'settings' => 'eco_ngo_our_case_count',
		        'label'    => esc_html__( 'Our Cause Number Control', 'eco-ngo' ),
		        'section'  => 'eco_ngo_home_industry_heroes_section',
		        'default'  => '',
		        'choices'  => [
		            'min'  => 0,
		            'max'  => 6,
		            'step' => 1,
		        ],
		    ]
		);

		$eco_ngo_our_case_count = get_theme_mod('eco_ngo_our_case_count');

		for ($i=1; $i <= $eco_ngo_our_case_count; $i++) { 
		    new \Kirki\Field\Image(
		        [
		            'settings'    => 'eco_ngo_our_cases_image'.$i,
		            'label'       => esc_html__( 'Our Cause Image', 'eco-ngo' ) . $i,
		            'section'     => 'eco_ngo_home_industry_heroes_section',
		            'default'     => '',
		        ]
		    );

		    new \Kirki\Field\Text(
		        [
		            'settings' => 'eco_ngo_industry_our_cause_heading'.$i,
		            'label'    => esc_html__( 'Our Cause Heading ', 'eco-ngo' ) . $i,
		            'section'  => 'eco_ngo_home_industry_heroes_section',
		        ]
		    );

		    new \Kirki\Field\Text(
		        [
		            'settings' => 'eco_ngo_industry_our_case_goal_amount'.$i,
		            'label'    => esc_html__( 'Our Cause Goal Amount ', 'eco-ngo' ) . $i,
		            'section'  => 'eco_ngo_home_industry_heroes_section',
		        ]
		    );

		    new \Kirki\Field\URL(
		        [
		            'settings' => 'eco_ngo_industry_our_case_rase_amount'.$i,
		            'label'    => esc_html__( 'Our Cause Rise Amount ', 'eco-ngo' ) . $i,
		            'section'  => 'eco_ngo_home_industry_heroes_section',
		            'default'  => '',
		        ]
		    );

		    new \Kirki\Field\URL(
		        [
		            'settings' => 'eco_ngo_industry_our_case_left_days'.$i,
		            'label'    => esc_html__( 'Our Cause Left Days ', 'eco-ngo' ) . $i,
		            'section'  => 'eco_ngo_home_industry_heroes_section',
		            'default'  => '',
		        ]
		    );
		}

			Kirki::add_field( 'theme_config_id', [
		'label'    => esc_html__( 'Buy Our Premium Theme For More Features', 'eco-ngo' ),
		'default'  => 
	        '<a class="premium_info_btn" target="_blank" href="' . esc_url( ECO_NGO_BUY_NOW_1 ) . '">' . __( 'Buy Pro', 'eco-ngo' ) . '</a>' .
	        '<a class="premium_info_btn bundle" target="_blank" href="' . esc_url( ECO_NGO_BUNDLE_1 ) . '">' . __( 'Buy All Themes In Single Package', 'eco-ngo' ) . '</a>',
        'type'        => 'custom',
        'section'     => 'eco_ngo_home_industry_heroes_section',
        'priority'     => 1000,
    ] );


	/* Footer */

	new \Kirki\Section(
		'eco_ngo_footer_section',
		[
			'title'       => esc_html__( 'Footer', 'eco-ngo' ),
			'panel'		  => 'eco_ngo_home_page_section',
			'priority'    => 30,
		]
	);

	new \Kirki\Field\Checkbox_Switch(
		[
			'settings'    => 'eco_ngo_footer_widgets_on_off',
			'label'       => esc_html__( 'Footer Widgets On / Off', 'eco-ngo' ),
			'section'     => 'eco_ngo_footer_section',
			'default'     => 'on',
			'choices'     => [
				'on'  => esc_html__( 'Enable', 'eco-ngo' ),
				'off' => esc_html__( 'Disable', 'eco-ngo' ),
			],
		]
	);

	new \Kirki\Field\Checkbox_Switch(
		[
			'settings'    => 'eco_ngo_copyright_on_off',
			'label'       => esc_html__( 'Footer Copyright On / Off', 'eco-ngo' ),
			'section'     => 'eco_ngo_footer_section',
			'default'     => 'on',
			'choices'     => [
				'on'  => esc_html__( 'Enable', 'eco-ngo' ),
				'off' => esc_html__( 'Disable', 'eco-ngo' ),
			],
		]
	);

	new \Kirki\Field\Text(
		[
			'settings' => 'eco_ngo_copyright_content_text',
			'label'    => esc_html__( 'Copyright Text', 'eco-ngo' ),
			'section'  => 'eco_ngo_footer_section',
		]
	);

	new \Kirki\Field\Select(
	[
		'settings'    => 'eco_ngo_copyright_alignment',
		'label'       => esc_html__( 'Copyright Text Alignment', 'eco-ngo' ),
		'section'     => 'eco_ngo_footer_section',
		'default'     => 'Center',
		'choices'     => [
			'Left' => esc_html__( 'Left Align', 'eco-ngo' ),
			'Center' => esc_html__( 'Center Align', 'eco-ngo' ),
			'Right' => esc_html__( 'Right Align', 'eco-ngo' ),
		],
	]
);

	new \Kirki\Field\Image(
	[
		'settings'    => 'eco_ngo_footer_background_image',
		'label'       => esc_html__( 'Select Your Appropriate Image for footer background', 'eco-ngo' ),
		'section'     => 'eco_ngo_footer_section',
		'default'     => '',
	] );

	Kirki::add_field( 'theme_config_id', [
		'type'        => 'color',
		'settings'    => 'eco_ngo_footer_background_color',
		'label'       => __( 'Select Your Appropriate Color for footer background', 'eco-ngo' ),
		'section'     => 'eco_ngo_footer_section',
		'default'     => '#151725',
	] );

	Kirki::add_field( 'theme_config_id', [
		'label'    => esc_html__( 'Buy Our Premium Theme For More Features', 'eco-ngo' ),
		'default'  => 
	        '<a class="premium_info_btn" target="_blank" href="' . esc_url( ECO_NGO_BUY_NOW_1 ) . '">' . __( 'Buy Pro', 'eco-ngo' ) . '</a>' .
	        '<a class="premium_info_btn bundle" target="_blank" href="' . esc_url( ECO_NGO_BUNDLE_1 ) . '">' . __( 'Buy All Themes In Single Package', 'eco-ngo' ) . '</a>',
        'type'        => 'custom',
        'section'     => 'eco_ngo_footer_section',
    ] );

}

function eco_ngo_customizer_settings( $wp_customize ) {

	$eco_ngo_args = array(
       'type'                     => 'product',
        'child_of'                 => 0,
        'parent'                   => '',
        'orderby'                  => 'term_group',
        'order'                    => 'ASC',
        'hide_empty'               => false,
        'hierarchical'             => 1,
        'number'                   => '',
        'taxonomy'                 => 'product_cat',
        'pad_counts'               => false
    );

	$categories = get_categories($eco_ngo_args);
	$cat_posts = array();
	$m = 0;
	$cat_posts[]='Select';
	foreach($categories as $category){
		if($m==0){
			$default = $category->slug;
			$m++;
		}
		$cat_posts[$category->slug] = $category->name;
	}

	$wp_customize->add_setting('eco_ngo_featured_product_category',array(
		'default'	=> 'select',
		'sanitize_callback' => 'eco_ngo_sanitize_select',
	));

	$wp_customize->add_control('eco_ngo_featured_product_category',array(
		'type'    => 'select',
		'choices' => $cat_posts,
		'label' => __('Select category to display products ','eco-ngo'),
		'section' => 'eco_ngo_home_product_section',
	));

}

add_action( 'customize_register', 'eco_ngo_customizer_settings' );