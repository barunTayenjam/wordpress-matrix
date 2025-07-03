<?php 
	if(isset($_GET['import-demo']) && $_GET['import-demo'] == true){
		// ------- Create Nav Menu --------
		$eco_ngo_menuname ='Primary Menu';
	    $eco_ngo_bpmenulocation = 'primary_menu';
	    $eco_ngo_menu_exists = wp_get_nav_menu_object( $eco_ngo_menuname );
	    if( !$eco_ngo_menu_exists){
	        $eco_ngo_menu_id = wp_create_nav_menu($eco_ngo_menuname);
	        $eco_ngo_home_parent = wp_update_nav_menu_item($eco_ngo_menu_id, 0, array(
				'menu-item-title' =>  __('Home','eco-ngo'),
				'menu-item-classes' => 'home',
				'menu-item-url' =>home_url( '/' ),
				'menu-item-status' => 'publish')
			);                                                                      

			wp_update_nav_menu_item($eco_ngo_menu_id, 0, array(
	            'menu-item-title' =>  __('About Us','eco-ngo'),
	            'menu-item-classes' => 'about',
	            'menu-item-url' => home_url( '//about/' ),
	            'menu-item-status' => 'publish'));

			wp_update_nav_menu_item($eco_ngo_menu_id, 0, array(
	            'menu-item-title' =>  __('Projects','eco-ngo'),
	            'menu-item-classes' => 'projects',
	            'menu-item-url' => home_url( '//projects/' ),
	            'menu-item-status' => 'publish'));

			
			wp_update_nav_menu_item($eco_ngo_menu_id, 0, array(
	            'menu-item-title' =>  __('Get Involved','eco-ngo'),
	            'menu-item-classes' => 'involved',
	            'menu-item-url' => home_url( '//involved/' ),
	            'menu-item-status' => 'publish'));

	        wp_update_nav_menu_item($eco_ngo_menu_id, 0, array(
	            'menu-item-title' =>  __('Blogs','eco-ngo'),
	            'menu-item-classes' => 'blogs',
	            'menu-item-url' => home_url( '//blogs/' ),
	            'menu-item-status' => 'publish'));

			wp_update_nav_menu_item($eco_ngo_menu_id, 0, array(
	            'menu-item-title' =>  __('Contact Us','eco-ngo'),
	            'menu-item-classes' => 'contact',
	            'menu-item-url' => home_url( '//contact/' ),
	            'menu-item-status' => 'publish'));
	        
			if( !has_nav_menu( $eco_ngo_bpmenulocation ) ){
	            $locations = get_theme_mod('nav_menu_locations');
	            $locations[$eco_ngo_bpmenulocation] = $eco_ngo_menu_id;
	            set_theme_mod( 'nav_menu_locations', $locations );
	        }
	    }
	    $eco_ngo_home_id='';
		$eco_ngo_home_content = '';
		$eco_ngo_home_title = 'Home';
		$eco_ngo_home = array(
			'post_type' => 'page',
			'post_title' => $eco_ngo_home_title,
			'post_content' => $eco_ngo_home_content,
			'post_status' => 'publish',
			'post_author' => 1,
			'post_slug' => 'home'
		);
		$eco_ngo_home_id = wp_insert_post($eco_ngo_home);
	    
		add_post_meta( $eco_ngo_home_id, '_wp_page_template', 'templates/template-homepage.php' );

		update_option( 'page_on_front', $eco_ngo_home_id );
		update_option( 'show_on_front', 'page' );

		//-----Slider-----//

		set_theme_mod( 'eco_ngo_slide_on_off', 'on' );

		set_theme_mod('eco_ngo_slide_count','5');


		$eco_ngo_slider_sub_title=array('Improve Education', 'Public Donation', 'Plastic Cleanup', 'Plastic Cleanup', 'Purify Ocean');

		for ($i=1; $i <= 5; $i++) {
			set_theme_mod( 'eco_ngo_slider_image'.$i, get_template_directory_uri().'/images/demo-import-images/slides/slide_'.$i.'.png' );
			set_theme_mod('eco_ngo_banner_heading'.$i, $eco_ngo_slider_sub_title[$i - 1]);
			set_theme_mod('eco_ngo_banner_heading_link'.$i, '#');
		}
		set_theme_mod( 'eco_ngo_slider_heading', 'Green Initiatives: Transforming Lives, One Action at a Time' );
		set_theme_mod( 'eco_ngo_slider_content', 'Embark on a journey of sustainability and positive change with our comprehensive green initiatives.' );
		set_theme_mod( 'eco_ngo_slider_button_text', 'Be A Part' );
		set_theme_mod( 'eco_ngo_slider_button_link', '#' );

		//-----Products-----//

		set_theme_mod( 'eco_ngo_our_cases_on_off', 'on' );

		set_theme_mod('eco_ngo_our_cases_short_heading', 'Support our cause, stand alongside');

		set_theme_mod('eco_ngo_our_case_count','3');

		$eco_ngo_causes_sub_title=array('Education', 'Cleaning', 'Planting');

		for ($i=1; $i <= 3; $i++) {
			set_theme_mod( 'eco_ngo_our_cases_image'.$i, get_template_directory_uri().'/images/demo-import-images/causes/causes_'.$i.'.png' );
			set_theme_mod('eco_ngo_industry_our_cause_heading'.$i, $eco_ngo_causes_sub_title[$i - 1]);
			set_theme_mod('eco_ngo_industry_our_case_goal_amount'.$i, '$4000.00');
			set_theme_mod('eco_ngo_industry_our_case_rase_amount'.$i, '$2900.00');
			set_theme_mod('eco_ngo_industry_our_case_left_days'.$i, '07 Days');
		}

      	
	}
?>