// ============================================================================
// مساعد الاستثمار Flutter - Version Service
// Handles forced-update checks against the backend minimum required version
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/client.dart';

/// Result of a version check
class VersionCheckResult {
  final bool updateRequired;
  final String currentVersion;
  final String minRequiredVersion;
  final String? storeUrl;
  final String? message;
  final String? messageAr;

  const VersionCheckResult({
    required this.updateRequired,
    required this.currentVersion,
    required this.minRequiredVersion,
    this.storeUrl,
    this.message,
    this.messageAr,
  });

  factory VersionCheckResult.ok(String currentVersion) => VersionCheckResult(
        updateRequired: false,
        currentVersion: currentVersion,
        minRequiredVersion: currentVersion,
      );
}

class VersionService {
  VersionService._privateConstructor();
  static final VersionService instance = VersionService._privateConstructor();

  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.egx.investment';

  /// Cached package info
  PackageInfo? _packageInfo;

  /// Get the current installed app version (e.g. "2.3.1")
  Future<String> getCurrentVersion() async {
    _packageInfo ??= await PackageInfo.fromPlatform();
    return _packageInfo!.version;
  }

  /// Get the current build number
  Future<String> getCurrentBuildNumber() async {
    _packageInfo ??= await PackageInfo.fromPlatform();
    return _packageInfo!.buildNumber;
  }

  /// Check whether the app must be updated.
  ///
  /// Strategy:
  /// 1. Try the backend endpoint `/api/app/version` for a server-driven
  ///    minimum version. If the server says the installed version is lower
  ///    than the minimum, force update.
  /// 2. If the endpoint is unreachable / returns nothing useful, fall back to
  ///    a compile-time minimum version constant so a critical update can still
  ///    block old clients even if the server endpoint is not deployed yet.
  Future<VersionCheckResult> checkVersion() async {
    final currentVersion = await getCurrentVersion();
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {}

    // If we cached that an update is required previously, default to true
    bool cachedUpdateRequired = false;
    String? cachedMinVersion;
    String? cachedStoreUrl;
    String? cachedMessageAr;

    if (prefs != null) {
      cachedUpdateRequired = prefs.getBool('force_update_required') ?? false;
      cachedMinVersion = prefs.getString('force_update_min_version');
      cachedStoreUrl = prefs.getString('force_update_store_url');
      cachedMessageAr = prefs.getString('force_update_message_ar');
    }

    try {
      final data = await api.getMinAppVersion();

      // Try to read a minimum version from the server response.
      final dynamic minRaw = data['min_version'] ??
          data['minimum_version'] ??
          data['minVersion'] ??
          data['version'];

      String? minVersion;
      if (minRaw is String && minRaw.isNotEmpty) {
        minVersion = minRaw;
      } else if (minRaw is num) {
        minVersion = minRaw.toString();
      }

      if (minVersion != null && minVersion.isNotEmpty) {
        final needsUpdate = _isVersionLower(currentVersion, minVersion);
        final storeUrl = data['store_url'] ?? data['play_store_url'] ?? _playStoreUrl;
        final messageAr = (data['message_ar'] ?? data['messageAr'] ?? data['message'])?.toString() ?? 'يرجى تحديث التطبيق إلى أحدث إصدار للمتابعة.';
        
        if (prefs != null) {
          await prefs.setBool('force_update_required', needsUpdate);
          await prefs.setString('force_update_min_version', minVersion);
          await prefs.setString('force_update_store_url', storeUrl);
          await prefs.setString('force_update_message_ar', messageAr);
        }

        return VersionCheckResult(
          updateRequired: needsUpdate,
          currentVersion: currentVersion,
          minRequiredVersion: minVersion,
          storeUrl: storeUrl,
          message: data['message']?.toString(),
          messageAr: messageAr,
        );
      }
    } catch (e) {
      debugPrint('[VersionService] Server version check failed: $e');
    }

    // Offline / Fallback check using cached info or compile-time constant
    final String fallbackMin = cachedMinVersion ?? '2.4.0';
    final bool needsUpdate = cachedUpdateRequired || _isVersionLower(currentVersion, fallbackMin);

    return VersionCheckResult(
      updateRequired: needsUpdate,
      currentVersion: currentVersion,
      minRequiredVersion: fallbackMin,
      storeUrl: cachedStoreUrl ?? _playStoreUrl,
      messageAr: cachedMessageAr ?? 'يرجى تحديث التطبيق إلى أحدث إصدار للمتابعة.',
    );
  }

  /// Returns true if [current] is strictly lower than [minimum].
  ///
  /// Compares semantic version strings segment by segment
  /// (e.g. "2.3.1" < "2.4.0").
  bool _isVersionLower(String current, String minimum) {
    final currentParts = _parseVersion(current);
    final minimumParts = _parseVersion(minimum);

    final maxLen = currentParts.length > minimumParts.length
        ? currentParts.length
        : minimumParts.length;

    for (var i = 0; i < maxLen; i++) {
      final c = i < currentParts.length ? currentParts[i] : 0;
      final m = i < minimumParts.length ? minimumParts[i] : 0;
      if (c < m) return true;
      if (c > m) return false;
    }
    return false; // equal
  }

  List<int> _parseVersion(String version) {
    // Strip any build metadata after '+' (e.g. "2.3.1+35")
    final clean = version.split('+').first;
    return clean
        .split('.')
        .map((part) => int.tryParse(part.trim()) ?? 0)
        .toList();
  }
}
