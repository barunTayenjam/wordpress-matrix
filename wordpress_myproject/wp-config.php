<?php
/**
 * The base configuration for WordPress
 *
 * The wp-config.php creation script uses this file during the installation.
 * You don't have to use the web site, you can copy this file to "wp-config.php"
 * and fill in the values.
 *
 * This file contains the following configurations:
 *
 * * Database settings
 * * Secret keys
 * * Database table prefix
 * * Localized language
 * * ABSPATH
 *
 * @link https://wordpress.org/support/article/editing-wp-config-php/
 *
 * @package WordPress
 */

// ** Database settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define( 'DB_NAME', 'myproject_db' );

/** Database username */
define( 'DB_USER', 'wp_dev_user' );

/** Database password */
define( 'DB_PASSWORD', 'SecureWP2024!' );

/** Database hostname */
define( 'DB_HOST', 'db-primary:3306' );

/** Database charset to use in creating database tables. */
define( 'DB_CHARSET', 'utf8' );

/** The database collate type. Don't change this if in doubt. */
define( 'DB_COLLATE', '' );

/**#@+
 * Authentication unique keys and salts.
 *
 * Change these to different unique phrases! You can generate these using
 * the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}.
 *
 * You can change these at any point in time to invalidate all existing cookies.
 * This will force all users to have to log in again.
 *
 * @since 2.6.0
 */
define( 'AUTH_KEY',          '>(,YZ1[Q?/&ih[hm<6ImPX0u$UxlMhAhI/p,F=3ezd1)b-3`1KDt.Ppc$.0 cL8T' );
define( 'SECURE_AUTH_KEY',   '|cSox<&JZ<V-}1l.9@Rum7ntFEm<)6uE8:G=`J2B,S-6Ek/e%Gzf+&56dSY(K^#y' );
define( 'LOGGED_IN_KEY',     '56AEv@?ks]a J71/b7~R_YUG}>M[4Him/6yrg&}a<=<S5$h*dg!eCQUS-DulZ^6Q' );
define( 'NONCE_KEY',         'TIUcb(*M;N;G|wz_r{*iTysf2yCg/YF9|LNSG(^v1RN:ddT6 ?Z>.v{]dY/MJ&y=' );
define( 'AUTH_SALT',         ',Q+#a)#rmd,WoEGwg9Gm1;in)#MpJ3ofD+3zncY7` ezsyPvR!?4}=&Po~nlGzhU' );
define( 'SECURE_AUTH_SALT',  'aPU4sltcGREay<^##Kk=yrL)F^xCmFjUp{?YW AIaKRf87zgLqBN:(|UQ.qBTs^O' );
define( 'LOGGED_IN_SALT',    '(Uwil}R+]u>|7TYMX_4dYu3?s2A 6z ZA6Ww< H8 ?^*t%55l6iWH4=Q[CIA}cW0' );
define( 'NONCE_SALT',        'rnfr4`,C8u^Bat8W)o/7exOfiZ}W{kd+QM(As?LcvC^4U1 DoQ}wbmCCqXaZ(.[v' );
define( 'WP_CACHE_KEY_SALT', 'YX+RM0/@  ;p+fs2(K~X>e`@m&a7]73Ntm4EuQY@w=Y|-_HM2t{LD-4=P!/3C`n?' );


/**#@-*/

/**
 * WordPress database table prefix.
 *
 * You can have multiple installations in one database if you give each
 * a unique prefix. Only numbers, letters, and underscores please!
 */
$table_prefix = 'wp_';


/* Add any custom values between this line and the "stop editing" line. */



/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 *
 * For information on other constants that can be used for debugging,
 * visit the documentation.
 *
 * @link https://wordpress.org/support/article/debugging-in-wordpress/
 */
if ( ! defined( 'WP_DEBUG' ) ) {
	define( 'WP_DEBUG', false );
}

/* That's all, stop editing! Happy publishing. */

/** Absolute path to the WordPress directory. */
if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', __DIR__ . '/' );
}

/** Sets up WordPress vars and included files. */
require_once ABSPATH . 'wp-settings.php';
