<?php
/**
 * PHPUnit Bootstrap for WordPress Development Matrix
 * 
 * This file sets up the testing environment for WordPress plugins and themes.
 */

// Prevent direct access
if (!defined('ABSPATH')) {
    define('ABSPATH', '/app/wordpress1/');
}

// Define test environment constants
define('WP_TESTS_CONFIG_FILE_PATH', '/app/wordpress1/wp-config.php');
define('WP_TESTS_DOMAIN', 'example.org');
define('WP_TESTS_EMAIL', 'admin@example.org');
define('WP_TESTS_TITLE', 'Test Blog');
define('WP_PHP_BINARY', 'php');
define('WP_TESTS_FORCE_KNOWN_BUGS', true);

// Database configuration for tests
define('DB_NAME', 'wordpress_test');
define('DB_USER', 'wp_dev_user');
define('DB_PASSWORD', 'SecureWP2024!');
define('DB_HOST', 'db-primary');
define('DB_CHARSET', 'utf8');
define('DB_COLLATE', '');

// WordPress configuration
define('WP_DEBUG', true);
define('WP_DEBUG_LOG', true);
define('WP_DEBUG_DISPLAY', false);
define('SCRIPT_DEBUG', true);

// Test-specific settings
$_SERVER['SERVER_NAME'] = 'localhost';
$_SERVER['REQUEST_METHOD'] = 'GET';
$_SERVER['HTTP_HOST'] = 'localhost';
$_SERVER['SCRIPT_NAME'] = '/index.php';
$_SERVER['REQUEST_URI'] = '/';

// Load WordPress test functions
if (file_exists('/app/wordpress1/wp-includes/functions.php')) {
    require_once '/app/wordpress1/wp-includes/functions.php';
}

// Load WordPress
if (file_exists('/app/wordpress1/wp-config.php')) {
    require_once '/app/wordpress1/wp-config.php';
}

// Load WordPress test case
if (class_exists('WP_UnitTestCase')) {
    // WordPress test suite is available
    echo "WordPress test suite loaded successfully.\n";
} else {
    // Fallback for basic testing
    echo "WordPress test suite not found. Using basic PHPUnit setup.\n";
    
    // Basic WordPress-like test case
    abstract class WP_UnitTestCase extends PHPUnit\Framework\TestCase
    {
        protected function setUp(): void
        {
            parent::setUp();
            // Basic setup for WordPress-like environment
        }
        
        protected function tearDown(): void
        {
            parent::tearDown();
            // Cleanup after each test
        }
    }
}

// Helper functions for testing
if (!function_exists('wp_tests_options')) {
    function wp_tests_options($value) {
        // Mock WordPress options for testing
        return $value;
    }
}

echo "WordPress Development Matrix test environment initialized.\n";