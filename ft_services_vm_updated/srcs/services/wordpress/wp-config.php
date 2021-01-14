<?php
 /**
 * The base configuration for WordPress
 *
 * The wp-config.php creation script uses this file during the
 * installation. You don't have to use the web site, you can
 * copy this file to "wp-config.php" and fill in the values.
 *
 * This file contains the following configurations:
 *
 * * MySQL settings
 * * Secret keys
 * * Database table prefix
 * * ABSPATH
 *
 * @link https://codex.wordpress.org/Editing_wp-config.php
 *
 * @package WordPress
 */

// ** MySQL settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define( 'DB_NAME', 'wordpress' );

/** MySQL database username */
define( 'DB_USER', 'user' );

/** MySQL database password */
define( 'DB_PASSWORD', 'password' );
/** https://api.wordpress.org/secret-key/1.1/salt/ */

/** MySQL hostname */
define( 'DB_HOST', 'mysql-service:3306' );

/** Database Charset to use in creating database tables. */
define( 'DB_CHARSET', 'utf8' );

/** The Database Collate type. Don't change this if in doubt. */
define( 'DB_COLLATE', '' );

define('AUTHOR', 'jfreitas');

/**#@+
 * Authentication Unique Keys and Salts.
 *
 * Change these to different unique phrases!
 * You can generate these using the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}
 * You can change these at any point in time to invalidate all existing cookies. This will force all users to have to log in again.
 *
 * @since 2.6.0
 */
define('AUTH_KEY',         '3></*CPjJo.H{B!xGc7]^-u|Ia`C0t+.e0c~hxxQP#lyjZRC7it3S)m&wz4L-u S');
define('SECURE_AUTH_KEY',  'PZ5!,h) Y*5U|G~Zs5EpG<VPTh|c Bp0b2`3s^QWTj Qh{Fx i`W5(z)yJ%+jhbr');
define('LOGGED_IN_KEY',    '-k?h@LI]a=d~2Mn[QF~xPj$,8l( =9=y(?%dipg|pasg(3+Rgo*|`{a^lE!_:N],');
define('NONCE_KEY',        's_0:M+]FJu{T-SU).N+_%qoz|B9UiD&QP8^Fxg+}=R-{A2Ag8(QhI<|ly}pIg~@8');
define('AUTH_SALT',        'j+gD; /QQhkm_9Z?2|1*|;]#k%|:PLfg{XkBI=}>QQqC3<j7u-#B[|E(EDBS Y&H');
define('SECURE_AUTH_SALT', 'K,[8Sae9<>Dn}|X~iH5Zmbx/y.GjJxYUsrEo:bg}S?CY|}bS|zh{[1,&tMiB0siL');
define('LOGGED_IN_SALT',   'j>>%Lrf}|Xx=oTosC)BAMM!l3A0hW7aQAt?>u}+vImVe<.KC9+OG4xwX9,lQd?c?');
define('NONCE_SALT',       'p,y*LX@r+g;%>_;MkXi-7]b=BcZ#P6[r(ON/.C<I7YBJ:-%I~1B[rK=I0~d:p_UM');

/**#@-*/

/**
 * WordPress Database Table prefix.
 *
 * You can have multiple installations in one database if you give each
 * a unique prefix. Only numbers, letters, and underscores please!
 */
$table_prefix = 'wp_';

/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 *
 * For information on other constants that can be used for debugging,
 * visit the Codex.
 *
 * @link https://codex.wordpress.org/Debugging_in_WordPress
 */

define( 'WP_DEBUG', false );
//define( 'WP_DEBUG_LOG', '/tmp/wp-errors.log' );

define('WP_MEMORY_LIMIT', '256M');

/* That's all, stop editing! Happy publishing. */


/*you can see the settings by visiting this page:
http://www.yoursite.com/wp-admin/maint/repair.php*/
define('WP_ALLOW_REPAIR', false );
/*Note: the user does not need to be logged in to access the database repairing
page. Once you are done repairing and optimizing your database, make sure to
remove this code from your wp-config.php*/


/** Absolute path to the WordPress directory. */
if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', dirname( __FILE__ ) . '/' );
}

/** Sets up WordPress vars and included files. */
require_once( ABSPATH . 'wp-settings.php' );
