// ============================================================================
// Google Sign-In Configuration
// ============================================================================

class GoogleAuthConfig {
  // ===========================================================================
  // REQUIRED: Get your Web Client ID from Google Cloud Console
  // ===========================================================================
  // 
  // Steps to get Web Client ID:
  // 1. Go to https://console.cloud.google.com
  // 2. Select your project
  // 3. Go to APIs & Services → Credentials
  // 4. Click "Create Credentials" → "OAuth client ID"
  // 5. Select "Web application"
  // 6. Name: "Flutter Web Client"
  // 7. Authorized JavaScript origins: https://invist.m2y.net
  // 8. Copy the Client ID that looks like: xxx.apps.googleusercontent.com
  //
  // Current OAuth credentials you have:
  // - SHA-1: 78:6A:54:0A:61:7F:77:21:28:CE:D0:6C:21:D7:0F:2A:63:2C:36:2F
  // - Package: com.egx.investment
  // - Android Client ID: 642150971767-ga2gohq77mcsgoa385ekciubnmvr0b02.apps.googleusercontent.com (for Android)
  //
  // You NEED a WEB application client ID for server-side verification!
  // ===========================================================================
  
  // Replace this with your Web Client ID (NOT the Android one!)
  static const String webClientId = '393659426254-n4ngsvhtfie714l0o5h8mlcpm5c58195.apps.googleusercontent.com';
  
  // iOS Client ID (if needed for iOS)
  static const String iosClientId = '';
}