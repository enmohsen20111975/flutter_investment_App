// ============================================================================
// مساعد الاستثمار Flutter - JSON Isolate Parser
// Offloads heavy JSON decoding to a background isolate to prevent UI jank
// ============================================================================

import 'dart:convert';
import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// Isolate entry points (must be top-level functions for compute())
// ---------------------------------------------------------------------------

Map<String, dynamic> _decodeMap(String json) =>
    jsonDecode(json) as Map<String, dynamic>;

List<dynamic> _decodeList(String json) =>
    jsonDecode(json) as List<dynamic>;

dynamic _decodeAny(String json) => jsonDecode(json);

// ---------------------------------------------------------------------------
// Size threshold: only spawn isolate for payloads above this size
// Below this threshold, inline decoding is faster (no isolate overhead)
// ---------------------------------------------------------------------------
const int _isolateThresholdBytes = 8192; // 8 KB

/// Parse a JSON string into a [Map<String, dynamic>].
///
/// Uses a background isolate when the payload exceeds [_isolateThresholdBytes]
/// to avoid blocking the UI thread.
Future<Map<String, dynamic>> parseJsonMap(String json) async {
  if (json.length < _isolateThresholdBytes) {
    return jsonDecode(json) as Map<String, dynamic>;
  }
  return compute(_decodeMap, json);
}

/// Parse a JSON string into a [List<dynamic>].
///
/// Uses a background isolate when the payload exceeds [_isolateThresholdBytes].
Future<List<dynamic>> parseJsonList(String json) async {
  if (json.length < _isolateThresholdBytes) {
    return jsonDecode(json) as List<dynamic>;
  }
  return compute(_decodeList, json);
}

/// Parse a JSON string into any Dart value.
///
/// Uses a background isolate when the payload exceeds [_isolateThresholdBytes].
Future<dynamic> parseJsonAny(String json) async {
  if (json.length < _isolateThresholdBytes) {
    return jsonDecode(json);
  }
  return compute(_decodeAny, json);
}

/// Synchronous fallback — use only when isolate overhead is not acceptable
/// (e.g., when already inside a `compute()` call).
Map<String, dynamic> parseJsonMapSync(String json) =>
    jsonDecode(json) as Map<String, dynamic>;

List<dynamic> parseJsonListSync(String json) =>
    jsonDecode(json) as List<dynamic>;
