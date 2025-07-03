<?php
/**
 * TGM Plugin Activation.
 */

require_once get_template_directory() . '/tgm/class-tgm-plugin-activation.php';

add_action( 'tgmpa_register', 'faith_church_register_required_plugins' );

function faith_church_register_required_plugins() {
    $plugins = array(
        array(
            'name'      => 'Elementor Template Importer', // Plugin name
            'slug'      => 'am-demo-importer', // Plugin slug (same as the folder name in wp-content/plugins)
            'required'  => false, // Whether the plugin is required or optional
			'force_activation' => false,
        ),
        array(
            'name'      => 'Elementor', // Plugin name
            'slug'      => 'elementor', // Plugin slug (same as the folder name in wp-content/plugins)
            'required'  => false, // Whether the plugin is required or optional
			'force_activation' => false,
        ),
    );

    $config = array(
        'id'           => 'faith-church',          // Unique ID for the TGMPA instance
        'default_path' => '',                       // Default absolute path to bundled plugins
        'menu'         => 'tgmpa-install-plugins',  // Menu slug
        'has_notices'  => true,                     // Show admin notices or not
        'dismissable'  => true,                     // If false, a user cannot dismiss the nag message
        'is_automatic' => true,                     // Automatically activate plugins after installation
        'message'      => '',                       // Message to display before the plugins table
    );

    tgmpa( $plugins, $config );
}
