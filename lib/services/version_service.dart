// ============================================================================
// مساعد الاستثمار Flutter - Version Service
// Handles app version checking and force update logic
// ============================================================================

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/client.dart';

class VersionService {
  VersionService._internal();
  static final VersionService _instance = VersionService._internal();
  factory VersionService() => _instance;

  static const String _versionKey = 'latest_required_version';
  static const String _versionMessageKey = 'update_message';

  Future<String> getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  Future<String> getCurrentBuildNumber() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.buildNumber;
  }

  Future<VersionUpdateInfo?> checkForUpdate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Check local storage first (can be synced from server)
      final requiredVersion = prefs.getString(_versionKey);

      if (requiredVersion == null) {
        return null;
      }

      final currentVersion = await getCurrentVersion();

      // Compare versions (simple string comparison works for semver)
      final shouldUpdate = _compareVersions(requiredVersion, currentVersion) > 0;

      if (shouldUpdate) {
        final message = prefs.getString(_versionMessageKey) ??
            'يُوصى بتحديث التطبيق إلى آخر إصدار';
        return VersionUpdateInfo(
          currentVersion: currentVersion,
          requiredVersion: requiredVersion,
          message: message,
        );
      }
      return null;
    } catch (e) {
      debugPrint('Version check error: $e');
      return null;
    }
  }

  int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final parts2 = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < 3; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 > p2) return 1;
      if (p1 < p2) return -1;
    }
    return 0;
  }

  Future<void> setRequiredVersion(String version, {String? message}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_versionKey, version);
    if (message != null) {
      await prefs.setString(_versionMessageKey, message);
    }
  }

  Future<void> fetchRemoteVersion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;
      
      final response = await api.dio.get('/api/version');
      if (response.data['success'] == true) {
        final requiredVersion = response.data['required_version'] as String?;
        final message = response.data['message'] as String?;
        if (requiredVersion != null) {
          await setRequiredVersion(requiredVersion, message: message);
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch remote version: $e');
    }
  }
}

class VersionUpdateInfo {
  final String currentVersion;
  final String requiredVersion;
  final String message;

  VersionUpdateInfo({
    required this.currentVersion,
    required this.requiredVersion,
    required this.message,
  });
}