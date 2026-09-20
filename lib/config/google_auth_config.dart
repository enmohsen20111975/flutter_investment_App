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
  // Current OAuth credentials:
  //
  // 1) Debug Key (for development & emulator):
  // - SHA-1:   78:6A:54:0A:61:7F:77:21:28:CE:D0:6C:21:D7:0F:2A:63:2C:36:2F
  // - SHA-256: 29:E5:7A:23:C8:C4:01:3B:70:F5:C2:F2:C1:D0:D2:4D:81:22:75:21:56:0A:06:05:80:55:84:DA:A9:61:A8:71
  // - Package: com.egx.investment
  //
  // 2) Release Key (upload-keystore.jks for Production APK & Google Play):
  // - SHA-1:   F8:EF:3F:95:7B:3D:11:51:B0:D8:DA:F0:FA:B0:14:0E:30:8F:E4:A4
  // - SHA-256: 19:92:E4:AF:50:FD:1B:03:35:B6:7C:83:09:AC:83:D2:9E:B0:C7:F3:30:70:E0:15:D3:B0:A4:75:17:95:2A:1E
  // - Package: com.egx.investment
  //
  // 3) Web Client ID (Must be passed to serverClientId for token verification):
  // ===========================================================================
  
  static const String webClientId = '393659426254-n4ngsvhtfie714l0o5h8mlcpm5c58195.apps.googleusercontent.com';
  
  // iOS Client ID (if needed for iOS)
  static const String iosClientId = '';
}