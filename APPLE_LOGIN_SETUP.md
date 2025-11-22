# Apple Sign In Implementation Guide

This guide covers the complete setup for Apple Sign In functionality in the GRead mobile app and WordPress/BuddyPress backend.

## Mobile App (iOS) - Completed ✅

The iOS implementation has been completed with the following components:

### 1. Files Modified/Created:
- `GRead.entitlements` - Added Sign in with Apple capability
- `AppleSignInButton.swift` - Custom Apple Sign In button component
- `AuthManager.swift` - Added `signInWithApple()` and username selection methods
- `LoginView.swift` - Integrated Apple Sign In button
- `RegistrationView.swift` - Integrated Apple Sign In button
- `UsernameSelectionView.swift` - NEW: Username picker for new Apple users
- `GReadApp.swift` - Updated to show username selection screen

### 2. How It Works:

**For New Users (First Time Sign In):**
1. User taps "Sign in with Apple" button
2. Apple authentication flow opens
3. User authorizes with Face ID/Touch ID
4. App receives identity token and user identifier
5. App sends token to WordPress backend at `/wp-json/custom/v1/apple-login`
6. Backend creates temporary account and returns `needs_username_selection: true`
7. App shows **Username Selection Screen** with:
   - Auto-suggested username (from email or name)
   - Real-time availability checking
   - Format validation
8. User chooses their username
9. App sends chosen username to `/wp-json/custom/v1/complete-apple-signup`
10. Backend updates the account and completes signup
11. User is logged in and can use the app

**For Returning Users:**
1. User taps "Sign in with Apple" button
2. Apple authentication flow opens
3. User authorizes with Face ID/Touch ID
4. Backend recognizes existing account
5. JWT token is returned
6. User is immediately logged in (no username selection)

## WordPress/BuddyPress Backend Setup

### Step 1: Configure Apple Developer Account

1. **Go to Apple Developer Portal** (https://developer.apple.com)
2. **Create an App ID**:
   - Sign in with your Apple Developer account
   - Go to "Certificates, Identifiers & Profiles"
   - Select "Identifiers" → Click "+"
   - Select "App IDs" and continue
   - Register your Bundle ID (e.g., `com.gread.app`)
   - Enable "Sign In with Apple" capability

3. **Create a Services ID** (for web authentication if needed):
   - Go to "Identifiers" → Click "+"
   - Select "Services IDs"
   - Create identifier (e.g., `com.gread.service`)
   - Configure "Sign In with Apple"
   - Add your domain and return URLs

4. **Create a Key**:
   - Go to "Keys" → Click "+"
   - Enable "Sign In with Apple"
   - Download the key file (.p8) - **IMPORTANT: Save this securely!**
   - Note your Key ID and Team ID

### Step 2: Install WordPress Plugin

1. **Upload the plugin**:
   ```bash
   # Copy the plugin file to your WordPress installation
   cp wordpress-apple-login.php /path/to/wordpress/wp-content/plugins/
   ```

2. **Activate the plugin**:
   - Go to WordPress Admin → Plugins
   - Find "Apple Sign In for GRead"
   - Click "Activate"

### Step 3: Configure the Plugin

Edit the `wordpress-apple-login.php` file and update the following:

```php
// Line ~125: Update with your actual Bundle Identifier
$expected_audience = 'YOUR_BUNDLE_IDENTIFIER'; // e.g., 'com.gread.app'
```

### Step 4: Ensure JWT Authentication is Set Up

The plugin requires JWT authentication for returning tokens. Make sure you have the JWT Authentication plugin installed:

1. **Install JWT Authentication plugin**:
   - Option A: Install "JWT Authentication for WP REST API" from WordPress.org
   - Option B: Download from https://wordpress.org/plugins/jwt-authentication-for-wp-rest-api/

2. **Configure wp-config.php**:
   Add these lines to your `wp-config.php` file:

   ```php
   define('JWT_AUTH_SECRET_KEY', 'your-secret-key-here');
   define('JWT_AUTH_CORS_ENABLE', true);
   ```

3. **Update .htaccess**:
   Add this to your `.htaccess` file to enable Authorization header:

   ```apache
   # BEGIN JWT Authentication
   RewriteEngine On
   RewriteCond %{HTTP:Authorization} ^(.*)
   RewriteRule .* - [e=HTTP_AUTHORIZATION:%1]
   # END JWT Authentication
   ```

### Step 5: Test the Implementation

1. **Test the endpoint**:
   ```bash
   curl -X POST https://gread.fun/wp-json/custom/v1/apple-login \
     -H "Content-Type: application/json" \
     -d '{
       "identity_token": "TEST_TOKEN",
       "user_identifier": "TEST_USER_ID",
       "email": "test@example.com",
       "full_name": {
         "given_name": "John",
         "family_name": "Doe"
       }
     }'
   ```

## iOS App Additional Configuration

### Xcode Project Settings:

1. **Open the project in Xcode**
2. **Select your target** → "Signing & Capabilities"
3. **Add Sign in with Apple capability**:
   - Click "+ Capability"
   - Search for "Sign in with Apple"
   - Add it to your target
4. **Verify entitlements file** is properly configured (already done)

### Update Bundle Identifier:

Make sure your Bundle Identifier in Xcode matches what you configured in Apple Developer Portal.

## Security Considerations

### Production Recommendations:

1. **Token Verification**:
   - The current implementation does basic token validation
   - For production, implement full signature verification using Apple's public keys
   - See: https://developer.apple.com/documentation/sign_in_with_apple/sign_in_with_apple_rest_api/verifying_a_user

2. **Secure Storage**:
   - JWT tokens are stored in UserDefaults (iOS)
   - Consider using Keychain for more sensitive data

3. **HTTPS Required**:
   - Apple Sign In requires HTTPS
   - Ensure your WordPress site uses SSL certificate

4. **Rate Limiting**:
   - Implement rate limiting on the `/apple-login` endpoint
   - Use WordPress plugins like "WP Limit Login Attempts"

## Email Privacy Handling

Apple allows users to hide their email addresses. The implementation handles this:

- If user shares email: Creates account with real email
- If user hides email: Creates account with Apple's private relay email or no email
- Email is only provided on first sign-in
- Subsequent sign-ins only provide user identifier

## BuddyPress Integration

The plugin automatically integrates with BuddyPress if available:

- Creates BuddyPress member profile
- Sets display name from Apple account
- Bypasses email verification for Apple users
- Sets xProfile fields automatically

## Troubleshooting

### Common Issues:

1. **"Missing required parameters" error**:
   - Ensure the mobile app is sending `identity_token` and `user_identifier`

2. **"Invalid token" error**:
   - Check that Bundle Identifier matches in both Apple Developer Portal and plugin
   - Verify token hasn't expired

3. **JWT token generation fails**:
   - Ensure JWT Authentication plugin is installed and configured
   - Check `JWT_AUTH_SECRET_KEY` is defined in wp-config.php

4. **User creation fails**:
   - Check WordPress user role permissions
   - Verify database can create new users
   - Check error logs in WordPress

### Debug Logging:

Enable WordPress debugging to see detailed error messages:

```php
// In wp-config.php
define('WP_DEBUG', true);
define('WP_DEBUG_LOG', true);
define('WP_DEBUG_DISPLAY', false);
```

Check logs at: `/wp-content/debug.log`

## API Endpoint Documentation

### POST `/wp-json/custom/v1/apple-login`

Handles initial Apple Sign In authentication.

**Request Body**:
```json
{
  "identity_token": "eyJraWQiOiJXNldjT0tC...",
  "user_identifier": "001234.abc123def456...",
  "email": "user@example.com",
  "full_name": {
    "given_name": "John",
    "family_name": "Doe"
  }
}
```

**Success Response - New User (200)**:
```json
{
  "token": "eyJ0eXAiOiJKV1QiLCJh...",
  "needs_username_selection": true,
  "suggested_username": "john_doe",
  "user_id": 123
}
```

**Success Response - Existing User (200)**:
```json
{
  "token": "eyJ0eXAiOiJKV1QiLCJh...",
  "user_id": 123,
  "user_email": "user@example.com",
  "user_display_name": "John Doe"
}
```

**Error Response (400/401)**:
```json
{
  "code": "missing_params",
  "message": "Missing required parameters",
  "data": {
    "status": 400
  }
}
```

### POST `/wp-json/custom/v1/check-username`

Checks if a username is available.

**Request Body**:
```json
{
  "username": "johndoe"
}
```

**Success Response (200)**:
```json
{
  "available": true,
  "username": "johndoe"
}
```

### POST `/wp-json/custom/v1/complete-apple-signup`

Completes Apple Sign In by setting the chosen username. Requires authentication.

**Headers**:
```
Authorization: Bearer {jwt_token}
```

**Request Body**:
```json
{
  "username": "johndoe"
}
```

**Success Response (200)**:
```json
{
  "success": true,
  "username": "johndoe",
  "user_id": 123
}
```

**Error Response - Username Taken (400)**:
```json
{
  "code": "username_taken",
  "message": "Username is already taken",
  "data": {
    "status": 400
  }
}
```

## Testing Checklist

**Backend Setup:**
- [ ] Apple Developer account configured
- [ ] Bundle Identifier matches everywhere
- [ ] WordPress plugin installed and activated
- [ ] JWT Authentication configured
- [ ] HTTPS enabled on WordPress site

**Username Selection Flow:**
- [ ] Test new user sees username selection screen
- [ ] Test suggested username is displayed
- [ ] Test real-time username availability checking
- [ ] Test username validation (3+ chars, alphanumeric + underscore)
- [ ] Test choosing custom username
- [ ] Test choosing suggested username
- [ ] Test duplicate username rejection

**Authentication Flow:**
- [ ] Test new user creation via Apple Sign In
- [ ] Test existing user login via Apple Sign In (no username selection)
- [ ] Test email privacy (hidden email)
- [ ] Test without email provided
- [ ] Verify JWT token works with other API endpoints
- [ ] Test BuddyPress profile creation with chosen username

**Device Testing:**
- [ ] Test on physical iOS device (required for Apple Sign In)
- [ ] Test with different Apple IDs
- [ ] Test returning user experience

## Support & Resources

- [Apple Sign In Documentation](https://developer.apple.com/sign-in-with-apple/)
- [WordPress REST API](https://developer.wordpress.org/rest-api/)
- [BuddyPress Developer Docs](https://codex.buddypress.org/developer/)
- [JWT Authentication Plugin](https://wordpress.org/plugins/jwt-authentication-for-wp-rest-api/)

## Notes

- Apple Sign In only works on physical devices or TestFlight, not in Simulator
- Users must be signed in to iCloud to use Apple Sign In
- First-time sign-in provides email and name; subsequent sign-ins only provide user identifier
- Store user identifier to link accounts across sign-ins
