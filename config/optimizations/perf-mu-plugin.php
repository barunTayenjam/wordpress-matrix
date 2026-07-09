<?php
/**
 * Plugin Name: Matrix Performance Optimizations
 * Description: Baseline performance and security optimizations applied to all matrix-managed sites.
 * Version: 1.0.0
 */

// 1. Limit post revisions to prevent bloat
add_filter('wp_revisions_to_keep', function ($num, $post) {
    return 5;
}, 10, 2);

// 2. Remove emoji cruft from front-end and admin
remove_action('wp_head', 'print_emoji_detection_script', 7);
remove_action('admin_print_scripts', 'print_emoji_detection_script');
remove_action('wp_print_styles', 'print_emoji_styles');
remove_action('admin_print_styles', 'print_emoji_styles');
remove_filter('the_content_feed', 'wp_staticize_emoji');
remove_filter('comment_text_rss', 'wp_staticize_emoji');
remove_filter('wp_mail', 'wp_staticize_emoji_for_email');

// 3. Remove generator tag, RSD, wlwmanifest, shortlink, oembed
remove_action('wp_head', 'wp_generator');
remove_action('wp_head', 'rsd_link');
remove_action('wp_head', 'wlwmanifest_link');
remove_action('wp_head', 'wp_shortlink_wp_head');

// 4. Disable self-pingbacks
add_action('pre_ping', function (&$links) {
    $home = get_option('home');
    foreach ($links as $l => $link) {
        if (strpos($link, $home) === 0) {
            unset($links[$l]);
        }
    }
});

// 5. Slow down Heartbeat API to 60s (only needed when editing posts)
add_action('init', function () {
    add_filter('heartbeat_settings', function ($settings) {
        $settings['interval'] = 60;
        return $settings;
    });
});

// 6. Increase media upload limits
@ini_set('upload_max_filesize', '64M');
@ini_set('post_max_size', '64M');
@ini_set('max_execution_time', '300');
