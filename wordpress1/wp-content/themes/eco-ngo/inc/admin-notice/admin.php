<?php 
/*******************************************************************************
 *  Get Started Notice
 *******************************************************************************/

add_action( 'wp_ajax_eco_ngo_dismissed_notice_handler', 'eco_ngo_ajax_notice_handler' );

/** * AJAX handler to record dismissible notice status. */
function eco_ngo_ajax_notice_handler() {
    if ( isset( $_POST['type'] ) ) {
        $type = sanitize_text_field( wp_unslash( $_POST['type'] ) );
        update_option( 'dismissed-' . $type, TRUE );
    }
}

function eco_ngo_admin_notice_deprecated_hook() {
        $current_screen = get_current_screen();
        if ($current_screen->id !== 'appearance_page_eco-ngo-guide-page') {
        if ( ! get_option('dismissed-get_started', FALSE ) ) { ?>
            <div class="updated notice notice-get-started-class is-dismissible" data-notice="get_started">
                <div class="eco-ngo-getting-started-notice clearfix">
                    <div class="eco-ngo-theme-notice-content">
                        <h2 class="eco-ngo-notice-h2">
                            <?php
                            echo esc_html__( 'Let\'s Create Your website With', 'eco-ngo' ) . ' <strong>' . esc_html( wp_get_theme()->get('Name') ) . '</strong>';
                            ?>
                        </h2>
                        <span class="st-notification-wrapper">
                            <span class="st-notification-column-wrapper">
                                <span class="st-notification-column">
                                    <h2><?php echo esc_html('Feature Rich WordPress Theme','eco-ngo'); ?></h2>
                                    <ul class="st-notification-column-list">
                                        <li><?php echo esc_html('Live Customize','eco-ngo'); ?></li>
                                        <li><?php echo esc_html('Detailed theme Options','eco-ngo'); ?></li>
                                        <li><?php echo esc_html('Cleanly Coded','eco-ngo'); ?></li>
                                        <li><?php echo esc_html('Search Engine Friendly','eco-ngo'); ?></li>
                                    </ul>
                                    <a href="<?php echo esc_url( admin_url( 'themes.php?page=eco-ngo-guide-page' ) ); ?>" target="_blank" class="button-primary button"><?php echo esc_html('Get Started With Eco NGO','eco-ngo'); ?></a>
                                </span>
                                <span class="st-notification-column">
                                    <h2><?php echo esc_html('Customize Your Website','eco-ngo'); ?></h2>
                                    <ul>
                                        <li><a href="<?php echo esc_url( admin_url( 'customize.php' ) ) ?>" target="_blank" class="button button-primary"><?php echo esc_html('Customize','eco-ngo'); ?></a></li>
                                        <li><a href="<?php echo esc_url( admin_url( 'widgets.php' ) ) ?>" class="button button-primary"><?php echo esc_html('Add Widgets','eco-ngo'); ?></a></li>
                                        <li><a href="<?php echo esc_url( ECO_NGO_SUPPORT_FREE ); ?>" target="_blank" class="button button-primary"><?php echo esc_html('Get Support','eco-ngo'); ?></a> </li>
                                    </ul>
                                </span>
                                <span class="st-notification-column">
                                    <h2><?php echo esc_html('Get More Options','eco-ngo'); ?></h2>
                                    <ul>
                                        <li><a href="<?php echo esc_url( ECO_NGO_DEMO_PRO ); ?>" target="_blank" class="button button-primary"><?php echo esc_html('View Live Demo','eco-ngo'); ?></a></li>
                                        <li><a href="<?php echo esc_url( ECO_NGO_BUY_NOW ); ?>" class="button button-primary premium"><?php echo esc_html('Purchase Now','eco-ngo'); ?></a></li>
                                        <li><a href="<?php echo esc_url( ECO_NGO_DOCS_FREE ); ?>" target="_blank" class="button button-primary"><?php echo esc_html('Free Documentation','eco-ngo'); ?></a> </li>
                                    </ul>
                                </span>
                            </span>
                            <span class="notice-img">
                                <img src="<?php echo esc_url( get_template_directory_uri() . '/images/notice.png' ); ?>">                                
                            </span>
                        </span>

                        <style>
                        </style>
                    </div>
                </div>
            </div>
        <?php }
    }
}

add_action( 'admin_notices', 'eco_ngo_admin_notice_deprecated_hook' );

function eco_ngo_switch_theme_function () {
    delete_option('dismissed-get_started', FALSE );
}

add_action('after_switch_theme', 'eco_ngo_switch_theme_function');