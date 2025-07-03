<?php

add_action( 'admin_menu', 'eco_ngo_getting_started' );
function eco_ngo_getting_started() {
    add_menu_page( 
        esc_html__('Demo Importer', 'eco-ngo'), // Page title
        esc_html__('Demo Importer', 'eco-ngo'), // Menu title
        'manage_options', // Capability
        'eco-ngo-guide-page', // Menu slug
        'eco_ngo_test_guide', // Function that renders the page
        'dashicons-admin-generic', // Icon
        2 // Position in the dashboard menu
    );
}

if ( ! defined( 'ECO_NGO_DOCS_FREE' ) ) {
define('ECO_NGO_DOCS_FREE',__('https://www.mishkatwp.com/instruction/eco-ngo-free-docs/','eco-ngo'));
}
if ( ! defined( 'ECO_NGO_DOCS_PRO' ) ) {
define('ECO_NGO_DOCS_PRO',__('https://www.mishkatwp.com/instruction/eco-ngo-pro-docs/','eco-ngo'));
}
if ( ! defined( 'ECO_NGO_BUY_NOW' ) ) {
define('ECO_NGO_BUY_NOW',__('https://www.mishkatwp.com/themes/eco-ngo-wordpress-theme/','eco-ngo'));
}
if ( ! defined( 'ECO_NGO_SUPPORT_FREE' ) ) {
define('ECO_NGO_SUPPORT_FREE',__('https://wordpress.org/support/theme/eco-ngo','eco-ngo'));
}
if ( ! defined( 'ECO_NGO_REVIEW_FREE' ) ) {
define('ECO_NGO_REVIEW_FREE',__('https://wordpress.org/support/theme/eco-ngo/reviews/#new-post','eco-ngo'));
}
if ( ! defined( 'ECO_NGO_DEMO_PRO' ) ) {
define('ECO_NGO_DEMO_PRO',__('https://www.mishkatwp.com/pro/eco-ngo/','eco-ngo'));
}
if ( ! defined( 'ECO_NGO_BUNDLE' ) ) {
define('ECO_NGO_BUNDLE',__('https://www.mishkatwp.com/themes/wordpress-theme-bundle/','eco-ngo'));
}

function eco_ngo_test_guide() { ?>
	<?php $eco_ngo_theme = wp_get_theme();
	require_once get_template_directory() .'/inc/started/demo-import.php'; ?>
	<div class="wrap" id="main-page">
		<div id="righty">
			<div class="getstart-postbox donate">
				<h4><?php esc_html_e( 'Discount Upto 25%', 'eco-ngo' ); ?> <span><?php esc_html_e( '"Special25"', 'eco-ngo' ); ?></span></h4>
				<h3 class="hndle"><?php esc_html_e( 'Upgrade to Premium', 'eco-ngo' ); ?></h3>
				<div class="getstart-inside">
					<p><?php esc_html_e('Click to upgrade to see the enhanced pro features available in the premium version.','eco-ngo'); ?></p>
					<div id="admin_pro_links">
						<a class="blue-button-2" href="<?php echo esc_url( ECO_NGO_BUY_NOW ); ?>" target="_blank"><?php esc_html_e( 'Go Pro', 'eco-ngo' ); ?></a>
						<a class="blue-button-1" href="<?php echo esc_url( ECO_NGO_DEMO_PRO ); ?>" target="_blank"><?php esc_html_e( 'Live Demo', 'eco-ngo' ) ?></a>
						<a class="blue-button-2" href="<?php echo esc_url( ECO_NGO_DOCS_PRO ); ?>" target="_blank"><?php esc_html_e( 'Pro Docs', 'eco-ngo' ) ?></a>
					</div>
				</div>
				<div class="d-table">
				    <ul class="d-column">
				      <li class="feature"><?php esc_html_e('Features','eco-ngo'); ?></li>
				      <li class="free"><?php esc_html_e('Pro','eco-ngo'); ?></li>
				      <li class="plus"><?php esc_html_e('Free','eco-ngo'); ?></li>
				    </ul>
				    <ul class="d-row">
				      <li class="points"><?php esc_html_e('24hrs Priority Support','eco-ngo'); ?></li>
				      <li class="right"><span class="dashicons dashicons-yes"></span></li>
				      <li class="wrong"><span class="dashicons dashicons-yes"></span></li>
				    </ul>
				    <ul class="d-row">
				      <li class="points"><?php esc_html_e('LearnPress Campatiblity','eco-ngo'); ?></li>
				      <li class="right"><span class="dashicons dashicons-yes"></span></li>
				      <li class="wrong"><span class="dashicons dashicons-yes"></span></li>
				    </ul>
				    <ul class="d-row">
				      <li class="points"><?php esc_html_e('Kirki Framework','eco-ngo'); ?></li>
				      <li class="right"><span class="dashicons dashicons-yes"></span></li>
				      <li class="wrong"><span class="dashicons dashicons-yes"></span></li>
				    </ul>
				    <ul class="d-row">
				      <li class="points"><?php esc_html_e('Advance Posttype','eco-ngo'); ?></li>
				      <li class="right"><span class="dashicons dashicons-yes"></span></li>
				      <li class="wrong"><span class="dashicons dashicons-no"></span></li>
				    </ul>
				    <ul class="d-row">
				      <li class="points"><?php esc_html_e('One Click Demo Import','eco-ngo'); ?></li>
				      <li class="right"><span class="dashicons dashicons-yes"></span></li>
				      <li class="wrong"><span class="dashicons dashicons-no"></span></li>
				    </ul>
				    <ul class="d-row">
				      <li class="points"><?php esc_html_e('Section Reordering','eco-ngo'); ?></li>
				      <li class="right"><span class="dashicons dashicons-yes"></span></li>
				      <li class="wrong"><span class="dashicons dashicons-no"></span></li>
				    </ul>
				    <ul class="d-row">
				      <li class="points"><?php esc_html_e('Enable / Disable Option','eco-ngo'); ?></li>
				      <li class="right"><span class="dashicons dashicons-yes"></span></li>
				      <li class="wrong"><span class="dashicons dashicons-yes"></span></li>
				    </ul>
				    <ul class="d-row">
				      <li class="points"><?php esc_html_e('Multiple Sections','eco-ngo'); ?></li>
				      <li class="right"><span class="dashicons dashicons-yes"></span></li>
				      <li class="wrong"><span class="dashicons dashicons-no"></span></li>
				    </ul>
				    <ul class="d-row">
				      <li class="points"><?php esc_html_e('Advance Color Pallete','eco-ngo'); ?></li>
				      <li class="right"><span class="dashicons dashicons-yes"></span></li>
				      <li class="wrong"><span class="dashicons dashicons-no"></span></li>
				    </ul>
				    <ul class="d-row">
				      <li class="points"><?php esc_html_e('Advance Widgets','eco-ngo'); ?></li>
				      <li class="right"><span class="dashicons dashicons-yes"></span></li>
				      <li class="wrong"><span class="dashicons dashicons-yes"></span></li>
				    </ul>
				    <ul class="d-row">
				      <li class="points"><?php esc_html_e('Page Templates','eco-ngo'); ?></li>
				      <li class="right"><span class="dashicons dashicons-yes"></span></li>
				      <li class="wrong"><span class="dashicons dashicons-no"></span></li>
				    </ul>
		  		</div>
			</div>
		</div>
		<div id="lefty">
			<div id="description">
				<h3><?php esc_html_e('Welcome! Thank you for choosing ','eco-ngo'); ?><?php echo esc_html( $eco_ngo_theme ); ?>  <span><?php esc_html_e('Version: ', 'eco-ngo'); ?><?php echo esc_html($eco_ngo_theme['Version']);?></span></h3>
				<div class="demo-import-box">
					<h4><?php echo esc_html('Import homepage demo in just one click.','eco-ngo'); ?></h4>
					<p><?php echo esc_html('Get started with the wordpress theme installation','eco-ngo'); ?></p>
					<?php if(isset($_GET['import-demo']) && $_GET['import-demo'] == true){ ?>
			    		<p class="imp-success"><?php echo esc_html('Imported Successfully','eco-ngo'); ?></p>
			    		<a class="blue-button-1" href="<?php echo esc_url(home_url()); ?>" target="_blank"><?php echo esc_html('Go to Homepage','eco-ngo'); ?></a>
			    	<?php } else { ?>
					<form id="demo-importer-form" action="<?php echo esc_url(home_url()); ?>/wp-admin/themes.php" method="POST">
			        	<input type="submit" name="submit" value="<?php esc_attr_e('Get Start With Eco NGO','eco-ngo'); ?>" class="blue-button-2">
			    	</form>
			    	<?php } ?>
				</div>
				<h4><?php esc_html_e('Begin with our theme features','eco-ngo'); ?></span></h4>
				<div class="customizer-inside">
					<div class="eco-ngo-theme-setting-item">
                        <div class="eco-ngo-theme-setting-item-header">
                            <?php esc_html_e( 'Add Menus', 'eco-ngo' ); ?>                            
                       	</div>
                        <div class="eco-ngo-theme-setting-item-content">
                        	<a target="_blank" href="<?php echo esc_url( admin_url('customize.php?autofocus[panel]=nav_menus') ); ?>"><?php esc_html_e('Go to Menu', 'eco-ngo'); ?></a>
                     	</div>
                     	<p><?php esc_html_e( 'After Clicking go to customizer >> Go to menu >> Select menu which you had created >> Then Publish ', 'eco-ngo' ); ?></p>
                	</div>
                	<div class="eco-ngo-theme-setting-item">
                        <div class="eco-ngo-theme-setting-item-header">
                            <?php esc_html_e( 'Add Logo', 'eco-ngo' ); ?>                            
                       	</div>
                        <div class="eco-ngo-theme-setting-item-content">
                        	<a target="_blank" href="<?php echo esc_url( admin_url('customize.php?autofocus[control]=custom_logo') ); ?>"><?php esc_html_e('Go to Site Identity', 'eco-ngo'); ?></a>
                     	</div>
                     	<p><?php esc_html_e( 'After Clicking go to customizer >> Go to Site Identity >> Select Logo Add Title or Tagline >> Then Publish ', 'eco-ngo' ); ?></p>
                	</div>
                	<div class="eco-ngo-theme-setting-item">
                        <div class="eco-ngo-theme-setting-item-header">
                            <?php esc_html_e( 'Home Page Section', 'eco-ngo' ); ?>                            
                       	</div>
                        <div class="eco-ngo-theme-setting-item-content">
                        	<a target="_blank" href="<?php echo esc_url( admin_url('customize.php?autofocus[panel]=eco_ngo_home_page_section') ); ?>"><?php esc_html_e('Go to Home Page Section', 'eco-ngo'); ?></a>
                     	</div>
                     	<p><?php esc_html_e( 'After Clicking go to customizer >> Go to Home Page Sections >> Then go to different section which ever you want >> Then Publish ', 'eco-ngo' ); ?></p>
                	</div>
                	<div class="eco-ngo-theme-setting-item">
                        <div class="eco-ngo-theme-setting-item-header">
                            <?php esc_html_e( 'Post Options', 'eco-ngo' ); ?>                            
                       	</div>
                        <div class="eco-ngo-theme-setting-item-content">
                        	<a target="_blank" href="<?php echo esc_url( admin_url('customize.php?autofocus[control]=eco_ngo_post_image_on_off') ); ?>"><?php esc_html_e('Go to Post Options', 'eco-ngo'); ?></a>
                     	</div>
                     	<p><?php esc_html_e( 'After Clicking go to customizer >> Go to Post Options >> Then go to different settings which ever you want >> Then Publish ', 'eco-ngo' ); ?></p>
                	</div>
                	<div class="eco-ngo-theme-setting-item">
                        <div class="eco-ngo-theme-setting-item-header">
                            <?php esc_html_e( 'Post Layout Options', 'eco-ngo' ); ?>                            
                       	</div>
                        <div class="eco-ngo-theme-setting-item-content">
                        	<a target="_blank" href="<?php echo esc_url( admin_url('customize.php?autofocus[control]=eco_ngo_post_layout') ); ?>"><?php esc_html_e('Go to Post Layout Options', 'eco-ngo'); ?></a>
                     	</div>
                     	<p><?php esc_html_e( 'After Clicking go to customizer >> Go to Post Layout Options >> Then go to different settings which ever you want >> Then Publish ', 'eco-ngo' ); ?></p>
                	</div>
                	<div class="eco-ngo-theme-setting-item">
                        <div class="eco-ngo-theme-setting-item-header">
                            <?php esc_html_e( 'General Options Options', 'eco-ngo' ); ?>                            
                       	</div>
                        <div class="eco-ngo-theme-setting-item-content">
                        	<a target="_blank" href="<?php echo esc_url( admin_url('customize.php?autofocus[control]=eco_ngo_preloader_setting') ); ?>"><?php esc_html_e('Go to General Options', 'eco-ngo'); ?></a>
                     	</div>
                     	<p><?php esc_html_e( 'After Clicking go to customizer >> Go to Post General Options >> Then go to different settings which ever you want >> Then Publish ', 'eco-ngo' ); ?></p>
                	</div>
                	
                	<a target="_blank" href="<?php echo esc_url( ECO_NGO_BUY_NOW ); ?>" class="eco-ngo-theme-setting-item eco-ngo-theme-setting-item-unavailable">
					    <div class="eco-ngo-theme-setting-item-header pro-option">
					        <span><?php esc_html_e("Customize All Fonts", "eco-ngo"); ?></span> <span><?php esc_html_e("Premium", "eco-ngo"); ?></span>
					    </div>
					</a>

					<a target="_blank" href="<?php echo esc_url( ECO_NGO_BUY_NOW ); ?>" class="eco-ngo-theme-setting-item eco-ngo-theme-setting-item-unavailable">
					    <div class="eco-ngo-theme-setting-item-header pro-option">
					        <span><?php esc_html_e("Customize All Color", "eco-ngo"); ?></span> <span><?php esc_html_e("Premium", "eco-ngo"); ?></span>
					    </div>
					</a>

					<a target="_blank" href="<?php echo esc_url( ECO_NGO_BUY_NOW ); ?>" class="eco-ngo-theme-setting-item eco-ngo-theme-setting-item-unavailable">
					    <div class="eco-ngo-theme-setting-item-header pro-option">
					        <span><?php esc_html_e("Section Reorder", "eco-ngo"); ?></span> <span><?php esc_html_e("Premium", "eco-ngo"); ?></span>
					    </div>
					</a>

					<a target="_blank" href="<?php echo esc_url( ECO_NGO_BUY_NOW ); ?>" class="eco-ngo-theme-setting-item eco-ngo-theme-setting-item-unavailable">
					    <div class="eco-ngo-theme-setting-item-header pro-option">
					        <span><?php esc_html_e("Typography Options", "eco-ngo"); ?></span> <span><?php esc_html_e("Premium", "eco-ngo"); ?></span>
					    </div>
					</a>

					<a target="_blank" href="<?php echo esc_url( ECO_NGO_BUY_NOW ); ?>" class="eco-ngo-theme-setting-item eco-ngo-theme-setting-item-unavailable">
					    <div class="eco-ngo-theme-setting-item-header pro-option">
					        <span><?php esc_html_e("One Click Demo Import", "eco-ngo"); ?></span> <span><?php esc_html_e("Premium", "eco-ngo"); ?></span>
					    </div>
					</a>
					<a target="_blank" href="<?php echo esc_url( ECO_NGO_BUY_NOW ); ?>" class="eco-ngo-theme-setting-item eco-ngo-theme-setting-item-unavailable">
					    <div class="eco-ngo-theme-setting-item-header pro-option">
					        <span><?php esc_html_e("Background  Settings", "eco-ngo"); ?></span> <span><?php esc_html_e("Premium", "eco-ngo"); ?></span>
					    </div>
					</a>
					
				</div>
			</div>
		</div>
		<div id="righty">
			<div class="eco-ngo-theme-setting-sidebar-item">
		        <div class="eco-ngo-theme-setting-sidebar-header"><?php esc_html_e( 'Theme Bundle', 'eco-ngo' ) ?></div>
		        <div class="eco-ngo-theme-setting-sidebar-content">
		            <p class="m-0"><?php esc_html_e( 'Get our all themes in single pack.', 'eco-ngo' ) ?></p>
		            <div id="admin_links">
		            	<a href="<?php echo esc_url( ECO_NGO_BUNDLE ); ?>" target="_blank" class="blue-button-2"><?php esc_html_e( 'Theme Bundle', 'eco-ngo' ) ?></a>
		            </div>
		        </div>
		    </div>
			<div class="eco-ngo-theme-setting-sidebar-item">
		        <div class="eco-ngo-theme-setting-sidebar-header"><?php esc_html_e( 'Free Documentation', 'eco-ngo' ) ?></div>
		        <div class="eco-ngo-theme-setting-sidebar-content">
		            <p class="m-0"><?php esc_html_e( 'Our guide is available if you require any help configuring and setting up the theme.', 'eco-ngo' ) ?></p>
		            <div id="admin_links">
		            	<a href="<?php echo esc_url( ECO_NGO_DOCS_FREE ); ?>" target="_blank" class="blue-button-1"><?php esc_html_e( 'Free Documentation', 'eco-ngo' ) ?></a>
		            </div>
		        </div>
		    </div>
		    <div class="eco-ngo-theme-setting-sidebar-item">
		        <div class="eco-ngo-theme-setting-sidebar-header"><?php esc_html_e( 'Support', 'eco-ngo' ) ?></div>
		        <div class="eco-ngo-theme-setting-sidebar-content">
		            <p class="m-0"><?php esc_html_e( 'Visit our website to contact us if you face any issues with our lite theme!', 'eco-ngo' ) ?></p>
		            <div id="admin_links">
		            	<a class="blue-button-2" href="<?php echo esc_url( ECO_NGO_SUPPORT_FREE ); ?>" target="_blank" class="btn3"><?php esc_html_e( 'Support', 'eco-ngo' ) ?></a>
		            </div>
		        </div>
		    </div>
		    <div class="eco-ngo-theme-setting-sidebar-item">
		        <div class="eco-ngo-theme-setting-sidebar-header"><?php esc_html_e( 'Review', 'eco-ngo' ) ?></div>
		        <div class="eco-ngo-theme-setting-sidebar-content">
		            <p class="m-0"><?php esc_html_e( 'Are you having fun with Eco NGO? Review us on WordPress.org to show your support!', 'eco-ngo' ) ?></p>
		            <div id="admin_links">
		            	<a href="<?php echo esc_url( ECO_NGO_REVIEW_FREE ); ?>" target="_blank" class="blue-button-1"><?php esc_html_e( 'Review', 'eco-ngo' ) ?></a>
		            </div>
		        </div>
		    </div>
		</div>
	</div>

<?php } ?>
