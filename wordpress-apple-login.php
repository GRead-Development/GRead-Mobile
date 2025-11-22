<?php
/**
 * Plugin Name: Apple Sign In for GRead
 * Description: Handles Apple Sign In authentication for WordPress/BuddyPress
 * Version: 1.0.0
 * Author: GRead Team
 */

if (!defined('ABSPATH')) {
    exit; // Exit if accessed directly
}

/**
 * Add custom REST API endpoint for Apple login
 */
add_action('rest_api_init', function () {
    register_rest_route('custom/v1', '/apple-login', array(
        'methods' => 'POST',
        'callback' => 'handle_apple_login',
        'permission_callback' => '__return_true',
    ));
});

/**
 * Handle Apple Sign In authentication
 *
 * @param WP_REST_Request $request
 * @return WP_REST_Response|WP_Error
 */
function handle_apple_login($request) {
    $params = $request->get_json_params();

    // Get required parameters
    $identity_token = isset($params['identity_token']) ? sanitize_text_field($params['identity_token']) : '';
    $user_identifier = isset($params['user_identifier']) ? sanitize_text_field($params['user_identifier']) : '';
    $email = isset($params['email']) ? sanitize_email($params['email']) : '';
    $full_name = isset($params['full_name']) ? $params['full_name'] : null;

    // Validate required fields
    if (empty($identity_token) || empty($user_identifier)) {
        return new WP_Error(
            'missing_params',
            'Missing required parameters',
            array('status' => 400)
        );
    }

    // Verify the Apple identity token
    $apple_user_data = verify_apple_identity_token($identity_token);

    if (is_wp_error($apple_user_data)) {
        return $apple_user_data;
    }

    // Check if user already exists by Apple user identifier
    $user = get_user_by_apple_identifier($user_identifier);

    if (!$user) {
        // User doesn't exist, create new user
        $user_id = create_apple_user($user_identifier, $email, $full_name, $apple_user_data);

        if (is_wp_error($user_id)) {
            return $user_id;
        }

        $user = get_user_by('ID', $user_id);
    } else {
        // Update last login time
        update_user_meta($user->ID, 'last_apple_login', current_time('mysql'));
    }

    // Generate JWT token for the user
    $jwt_token = generate_jwt_token($user);

    if (is_wp_error($jwt_token)) {
        return $jwt_token;
    }

    return new WP_REST_Response(array(
        'token' => $jwt_token,
        'user_id' => $user->ID,
        'user_email' => $user->user_email,
        'user_display_name' => $user->display_name,
    ), 200);
}

/**
 * Verify Apple identity token
 *
 * @param string $identity_token
 * @return array|WP_Error
 */
function verify_apple_identity_token($identity_token) {
    // Split the token into parts
    $token_parts = explode('.', $identity_token);

    if (count($token_parts) !== 3) {
        return new WP_Error(
            'invalid_token',
            'Invalid token format',
            array('status' => 401)
        );
    }

    // Decode the payload (second part)
    $payload = base64_decode(str_replace(['-', '_'], ['+', '/'], $token_parts[1]));
    $claims = json_decode($payload, true);

    if (!$claims) {
        return new WP_Error(
            'invalid_token',
            'Invalid token payload',
            array('status' => 401)
        );
    }

    // Verify the token is for your app
    // IMPORTANT: Replace with your actual Apple Team ID / Client ID
    $expected_audience = 'YOUR_BUNDLE_IDENTIFIER'; // e.g., 'com.gread.app'

    if (!isset($claims['aud']) || $claims['aud'] !== $expected_audience) {
        return new WP_Error(
            'invalid_audience',
            'Token audience mismatch',
            array('status' => 401)
        );
    }

    // Verify token hasn't expired
    if (isset($claims['exp']) && $claims['exp'] < time()) {
        return new WP_Error(
            'expired_token',
            'Token has expired',
            array('status' => 401)
        );
    }

    // For production, you should verify the signature using Apple's public keys
    // See: https://developer.apple.com/documentation/sign_in_with_apple/sign_in_with_apple_rest_api/verifying_a_user

    return $claims;
}

/**
 * Get user by Apple identifier
 *
 * @param string $apple_identifier
 * @return WP_User|false
 */
function get_user_by_apple_identifier($apple_identifier) {
    $users = get_users(array(
        'meta_key' => 'apple_user_identifier',
        'meta_value' => $apple_identifier,
        'number' => 1,
    ));

    return !empty($users) ? $users[0] : false;
}

/**
 * Create new WordPress/BuddyPress user from Apple Sign In
 *
 * @param string $apple_identifier
 * @param string $email
 * @param array|null $full_name
 * @param array $apple_user_data
 * @return int|WP_Error User ID on success, WP_Error on failure
 */
function create_apple_user($apple_identifier, $email, $full_name, $apple_user_data) {
    // Generate username from email or Apple identifier
    if (!empty($email)) {
        $username = sanitize_user(explode('@', $email)[0]);
    } else {
        $username = 'apple_' . substr($apple_identifier, 0, 15);
    }

    // Ensure username is unique
    $base_username = $username;
    $counter = 1;
    while (username_exists($username)) {
        $username = $base_username . $counter;
        $counter++;
    }

    // Check if email already exists
    if (!empty($email) && email_exists($email)) {
        // Email exists, link Apple ID to existing account
        $existing_user = get_user_by('email', $email);
        update_user_meta($existing_user->ID, 'apple_user_identifier', $apple_identifier);
        update_user_meta($existing_user->ID, 'apple_linked_date', current_time('mysql'));
        return $existing_user->ID;
    }

    // Generate display name
    $display_name = $username;
    if ($full_name && isset($full_name['given_name'])) {
        $display_name = $full_name['given_name'];
        if (isset($full_name['family_name'])) {
            $display_name .= ' ' . $full_name['family_name'];
        }
    }

    // Create user data
    $user_data = array(
        'user_login' => $username,
        'user_pass' => wp_generate_password(32, true, true), // Random secure password
        'user_email' => !empty($email) ? $email : '', // Apple may not provide email if user opts out
        'display_name' => $display_name,
        'first_name' => isset($full_name['given_name']) ? $full_name['given_name'] : '',
        'last_name' => isset($full_name['family_name']) ? $full_name['family_name'] : '',
        'role' => 'subscriber',
    );

    // Create the user
    $user_id = wp_insert_user($user_data);

    if (is_wp_error($user_id)) {
        return $user_id;
    }

    // Store Apple identifier
    update_user_meta($user_id, 'apple_user_identifier', $apple_identifier);
    update_user_meta($user_id, 'apple_signup_date', current_time('mysql'));
    update_user_meta($user_id, 'last_apple_login', current_time('mysql'));

    // If using BuddyPress, create member
    if (function_exists('bp_core_activate_signup')) {
        // Mark user as activated (skip email verification for Apple Sign In)
        update_user_meta($user_id, 'bp_verified', true);
    }

    // Set default BuddyPress profile fields if available
    if (function_exists('xprofile_set_field_data')) {
        // Set name field (usually field ID 1)
        xprofile_set_field_data(1, $user_id, $display_name);
    }

    return $user_id;
}

/**
 * Generate JWT token for authenticated user
 * Uses the JWT Authentication plugin if available
 *
 * @param WP_User $user
 * @return string|WP_Error
 */
function generate_jwt_token($user) {
    // Check if JWT Authentication plugin is active
    if (!function_exists('Jwt_Auth_Public')) {
        // Fallback: Generate a simple token (for development only)
        // In production, you MUST use proper JWT plugin
        $token = wp_generate_password(64, false);
        update_user_meta($user->ID, 'auth_token', $token);
        update_user_meta($user->ID, 'auth_token_expiry', time() + (7 * DAY_IN_SECONDS));
        return $token;
    }

    // Use JWT Authentication plugin to generate token
    // This assumes you're using the jwt-authentication-for-wp-rest-api plugin
    $secret_key = defined('JWT_AUTH_SECRET_KEY') ? JWT_AUTH_SECRET_KEY : 'your-secret-key';
    $issued_at = time();
    $not_before = $issued_at;
    $expire = $issued_at + (7 * DAY_IN_SECONDS); // 7 days expiry

    $token = array(
        'iss' => get_bloginfo('url'),
        'iat' => $issued_at,
        'nbf' => $not_before,
        'exp' => $expire,
        'data' => array(
            'user' => array(
                'id' => $user->ID,
            ),
        ),
    );

    // If you have the JWT library available
    if (class_exists('Firebase\JWT\JWT')) {
        require_once(ABSPATH . 'wp-content/plugins/jwt-authentication-for-wp-rest-api/vendor/autoload.php');
        return \Firebase\JWT\JWT::encode($token, $secret_key, 'HS256');
    }

    // Otherwise, make a request to the JWT auth endpoint
    $jwt_endpoint = rest_url('jwt-auth/v1/token');
    $response = wp_remote_post($jwt_endpoint, array(
        'body' => array(
            'username' => $user->user_login,
            'password' => '', // We'll need to handle this differently
        ),
    ));

    // For Apple Sign In users, we need a different approach
    // Store a session token and return it
    $session_token = bin2hex(random_bytes(32));
    update_user_meta($user->ID, 'apple_session_token', $session_token);
    update_user_meta($user->ID, 'apple_session_expiry', time() + (7 * DAY_IN_SECONDS));

    return $session_token;
}

/**
 * Installation function - creates necessary database tables and options
 */
function apple_signin_install() {
    // Add any necessary options
    add_option('apple_signin_version', '1.0.0');

    // Create logs table if needed
    global $wpdb;
    $table_name = $wpdb->prefix . 'apple_signin_logs';

    $charset_collate = $wpdb->get_charset_collate();

    $sql = "CREATE TABLE IF NOT EXISTS $table_name (
        id mediumint(9) NOT NULL AUTO_INCREMENT,
        user_id bigint(20) NOT NULL,
        apple_identifier varchar(255) NOT NULL,
        login_time datetime DEFAULT CURRENT_TIMESTAMP NOT NULL,
        ip_address varchar(100) NOT NULL,
        PRIMARY KEY  (id),
        KEY user_id (user_id),
        KEY apple_identifier (apple_identifier)
    ) $charset_collate;";

    require_once(ABSPATH . 'wp-admin/includes/upgrade.php');
    dbDelta($sql);
}

register_activation_hook(__FILE__, 'apple_signin_install');

/**
 * Helper function to log Apple Sign In attempts
 */
function log_apple_signin($user_id, $apple_identifier) {
    global $wpdb;
    $table_name = $wpdb->prefix . 'apple_signin_logs';

    $wpdb->insert(
        $table_name,
        array(
            'user_id' => $user_id,
            'apple_identifier' => $apple_identifier,
            'login_time' => current_time('mysql'),
            'ip_address' => $_SERVER['REMOTE_ADDR'] ?? '',
        )
    );
}
