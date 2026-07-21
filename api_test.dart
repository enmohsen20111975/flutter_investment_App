// ============================================================================
// API Test Runner - Tests all backend endpoints
// ============================================================================

import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';

const baseUrl = 'https://invist.m2y.net';
const dummyToken = 'Bearer test-token-12345';

class ApiTestResult {
  final String endpoint;
  final String method;
  final bool withAuth;
  final int? statusCode;
  final String? error;
  final Duration? duration;
  final String? responsePreview;

  ApiTestResult({
    required this.endpoint,
    required this.method,
    required this.withAuth,
    this.statusCode,
    this.error,
    this.duration,
    this.responsePreview,
  });

  Map<String, dynamic> toJson() {
    return {
      'endpoint': endpoint,
      'method': method,
      'withAuth': withAuth,
      'statusCode': statusCode,
      'error': error,
      'durationMs': duration?.inMilliseconds,
      'responsePreview': responsePreview,
    };
  }
}

Future<void> testEndpoint(
  List<ApiTestResult> results,
  Dio dio,
  Dio dioAuth,
  String method,
  String path, {
  Map<String, dynamic>? queryParameters,
  dynamic data,
  bool withAuth = false,
}) async {
  final client = withAuth ? dioAuth : dio;
  final start = DateTime.now();
  int? statusCode;
  String? error;
  String? preview;

  try {
    late Response response;
    final options = Options(method: method);

    if (method.toUpperCase() == 'GET') {
      response = await client.get(path, queryParameters: queryParameters);
    } else if (method.toUpperCase() == 'POST') {
      response = await client.post(path, data: data, queryParameters: queryParameters);
    } else if (method.toUpperCase() == 'PUT') {
      response = await client.put(path, data: data, queryParameters: queryParameters);
    } else if (method.toUpperCase() == 'DELETE') {
      response = await client.delete(path, data: data, queryParameters: queryParameters);
    }

    statusCode = response.statusCode;
    final respStr = response.data.toString();
    preview = respStr.length > 200 ? respStr.substring(0, 200) + '...' : respStr;
  } catch (e) {
    error = e.toString();
    if (e is DioException) {
      statusCode = e.response?.statusCode;
      final respStr = e.response?.data.toString() ?? '';
      if (respStr.isNotEmpty) {
        preview = respStr.length > 200 ? respStr.substring(0, 200) + '...' : respStr;
      }
    }
  }

  final duration = DateTime.now().difference(start);
  results.add(ApiTestResult(
    endpoint: path,
    method: method.toUpperCase(),
    withAuth: withAuth,
    statusCode: statusCode,
    error: error,
    duration: duration,
    responsePreview: preview,
  ));

  final authTag = withAuth ? '[AUTH]' : '[PUB]';
  final status = statusCode != null ? '$statusCode' : 'ERR';
  print('$authTag $method $path => $status (${duration.inMilliseconds}ms)');
}

Future<void> main() async {
  print('='.padRight(80, '='));
  print('  API ENDPOINT TEST SUITE');
  print('  Base URL: $baseUrl');
  print('  Started: ${DateTime.now()}');
  print('='.padRight(80, '='));
  print('');

  final results = <ApiTestResult>[];

  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
  ));

  final dioAuth = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
  ));
  dioAuth.options.headers['Authorization'] = dummyToken;

  final dioAi = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 120),
  ));
  dioAi.options.headers['Authorization'] = dummyToken;

  // ============================================================================
  // AUTH APIs
  // ============================================================================
  print('\n--- AUTH APIs ---');
  await testEndpoint(results, dio, dioAuth, 'POST', '/api/auth/google', data: {'id_token': 'dummy-token'}, withAuth: false);
  await testEndpoint(results, dio, dioAuth, 'POST', '/api/auth/logout', withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/auth/me', withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'PUT', '/api/auth/profile', data: {'phone': '+201000000000'}, withAuth: true);

  // ============================================================================
  // MARKET APIs
  // ============================================================================
  print('\n--- MARKET APIs ---');
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/market/overview', withAuth: false);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/market/overview', queryParameters: {'market': 'EGX'}, withAuth: false);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/market/live-data', withAuth: false);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/market/investing', withAuth: false);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/market/recommendations/ai-insights', withAuth: false);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/market/status', withAuth: false);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/market/connections', withAuth: false);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/market/incremental-sync', withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'POST', '/api/market/sync-live', withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'POST', '/api/market/sync', withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/multi-market/sync', withAuth: true);

  // ============================================================================
  // STOCK APIs
  // ============================================================================
  print('\n--- STOCK APIs ---');
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/stocks', queryParameters: {'query': 'test'}, withAuth: false);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/stocks/movement-classification', withAuth: false);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/stocks/movement-classification', queryParameters: {'market': 'EGX'}, withAuth: false);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/stocks/fundamentals', queryParameters: {'ticker': 'AAPL'}, withAuth: false);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/stocks/AAPL', withAuth: false);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/stocks/AAPL/history', queryParameters: {'days': 30}, withAuth: false);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/stocks/AAPL/recommendation', withAuth: false);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/stocks/AAPL/professional-analysis', withAuth: false);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/stocks/AAPL/news', withAuth: false);

  // ============================================================================
  // CRYPTO APIs
  // ============================================================================
  print('\n--- CRYPTO APIs ---');
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/crypto', withAuth: false);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/crypto/bitcoin', withAuth: false);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/crypto/ohlc', queryParameters: {'coin_id': 'bitcoin', 'days': 7}, withAuth: false);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/crypto/recommendations', withAuth: false);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/crypto/backtesting', queryParameters: {'coin_id': 'bitcoin', 'days': 30}, withAuth: false);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/crypto/portfolio', withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/crypto/stats', withAuth: false);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/crypto/status', withAuth: false);
  await testEndpoint(results, dio, dioAuth, 'POST', '/api/crypto/simulation', data: {'coin_id': 'bitcoin', 'action': 'buy', 'amount': 100}, withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/mobile/crypto', withAuth: false);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/mobile/crypto/bitcoin', withAuth: false);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/mobile/crypto/recommendations', withAuth: false);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/mobile/crypto/analysis', queryParameters: {'coin_id': 'bitcoin'}, withAuth: false);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/mobile/crypto/learning', withAuth: false);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/mobile/crypto/portfolio', withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/mobile/crypto/watchlist', withAuth: true);

  // ============================================================================
  // PORTFOLIO APIs
  // ============================================================================
  print('\n--- PORTFOLIO APIs ---');
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/mobile/portfolio', withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/mobile/portfolio/analyze', withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'POST', '/api/mobile/portfolio', data: {'ticker': 'AAPL', 'quantity': 10}, withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'DELETE', '/api/mobile/portfolio', queryParameters: {'id': 'test-id'}, withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/mobile/portfolio/intelligence', withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/portfolio/analyze', withAuth: true);

  // ============================================================================
  // WATCHLIST APIs
  // ============================================================================
  print('\n--- WATCHLIST APIs ---');
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/watchlist', withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/watchlist-enhanced', withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'POST', '/api/watchlist', data: {'ticker': 'AAPL'}, withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'DELETE', '/api/watchlist/test-id', withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/mobile/watchlist/intelligence', withAuth: true);

  // ============================================================================
  // SUBSCRIPTION APIs
  // ============================================================================
  print('\n--- SUBSCRIPTION APIs ---');
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/subscription/current', withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/subscription/plans', withAuth: false);
  await testEndpoint(results, dio, dioAuth, 'POST', '/api/subscription/upgrade', data: {'plan_id': 'plus'}, withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'POST', '/api/subscription/subscribe', data: {'plan_id': 'plus'}, withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'POST', '/api/subscription/trial', withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'POST', '/api/subscription/check-access', data: {'feature': 'stock_history'}, withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'POST', '/api/subscription/checkout', data: {'plan_id': 'plus'}, withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'POST', '/api/subscription/verify', data: {'tx_hash': 'dummy'}, withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/subscription/status', withAuth: true);

  // ============================================================================
  // AI ANALYSIS APIs
  // ============================================================================
  print('\n--- AI ANALYSIS APIs ---');
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/v2/live-analysis', withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/health', withAuth: false);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/ai/batch-analysis', withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'POST', '/api/ai/analyze-stock', data: {'ticker': 'AAPL'}, withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'POST', '/api/ai/chat', data: {'message': 'test'}, withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/mobile/predictions', withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/predictions/performance', withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/global-predictions', withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/recommendations/expert', withAuth: false);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/reports/morning', withAuth: false);

  // ============================================================================
  // METALS APIs
  // ============================================================================
  print('\n--- METALS APIs ---');
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/metals', withAuth: false);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/mobile/gold', withAuth: false);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/mobile/gold/history', queryParameters: {'karat': '24', 'days': 30}, withAuth: false);

  // ============================================================================
  // CURRENCY APIs
  // ============================================================================
  print('\n--- CURRENCY APIs ---');
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/currency', withAuth: false);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/currency/list', withAuth: false);
  await testEndpoint(results, dio, dioAuth, 'POST', '/api/currency/convert', data: {'from': 'USD', 'to': 'EGP', 'amount': 100}, withAuth: false);

  // ============================================================================
  // ZAKAT APIs
  // ============================================================================
  print('\n--- ZAKAT APIs ---');
  await testEndpoint(results, dio, dioAuth, 'POST', '/api/zakat/calculate', data: {'gold_value': 10000, 'cash': 5000}, withAuth: false);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/mobile/zakat-calculator', queryParameters: {'gold_value': 10000}, withAuth: false);

  // ============================================================================
  // LEARNING APIs
  // ============================================================================
  print('\n--- LEARNING APIs ---');
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/learning/content', withAuth: false);
  await testEndpoint(results, dio, dioAuth, 'POST', '/api/learning/progress', data: {'lesson_id': '1'}, withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/unified-learning/status', withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'POST', '/api/unified-learning/iterative', withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'POST', '/api/unified-learning/intelligent', withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/unified-learning/indicators', withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/unified-learning/patterns', withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'POST', '/api/unified-learning/mine-lessons', withAuth: true);

  // ============================================================================
  // BACKTESTING APIs
  // ============================================================================
  print('\n--- BACKTESTING APIs ---');
  await testEndpoint(results, dio, dioAuth, 'POST', '/api/backtest', data: {'strategy': 'sma', 'ticker': 'AAPL', 'start_date': '2024-01-01', 'end_date': '2024-12-31'}, withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/backtesting', withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'POST', '/api/backtesting/unified', data: {'strategy': 'sma', 'ticker': 'AAPL'}, withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/kimi/backtest/run', withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/walk-forward/run', withAuth: true);

  // ============================================================================
  // UNIFIED / CONFLUENCE APIs
  // ============================================================================
  print('\n--- UNIFIED APIs ---');
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/unified-stocks', withAuth: false);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/v2/unified/personas', withAuth: false);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/v2/unified/config', queryParameters: {'market': 'EGX', 'persona': 'conservative'}, withAuth: false);
  await testEndpoint(results, dio, dioAuth, 'POST', '/api/v2/unified/scan', data: {'market': 'EGX', 'persona': 'conservative', 'top_n': 10, 'min_score': 65}, withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'POST', '/api/v2/unified/analyze', data: {'ticker': 'AAPL', 'market': 'EGX', 'persona': 'conservative'}, withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/confluence/analyze/AAPL', withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/confluence/market-scan', queryParameters: {'market': 'EGX'}, withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/persona/analyze/AAPL', withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/persona/recommendations', queryParameters: {'persona': 'conservative'}, withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/maestro/stock/AAPL', queryParameters: {'market': 'EGX', 'persona': 'conservative'}, withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/scanner/quick', withAuth: false);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/scanner/quick', queryParameters: {'market': 'EGX', 'limit': 10}, withAuth: false);

  // ============================================================================
  // DATA ENGINE APIs
  // ============================================================================
  print('\n--- DATA ENGINE APIs ---');
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/data-engine/health', withAuth: false);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/data-engine/stocks', withAuth: false);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/data-engine/metals', withAuth: false);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/data-engine/crypto', withAuth: false);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/data-engine/forex', withAuth: false);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/data-engine/status', withAuth: false);

  // ============================================================================
  // RISK APIs
  // ============================================================================
  print('\n--- RISK APIs ---');
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/risk/decision-table', withAuth: false);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/risk/stock-types', withAuth: false);

  // ============================================================================
  // FINANCE APIs
  // ============================================================================
  print('\n--- FINANCE APIs ---');
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/finance/assets', withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'POST', '/api/finance/assets', data: {'type': 'stock', 'ticker': 'AAPL'}, withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'DELETE', '/api/finance/assets/test-id', withAuth: true);

  // ============================================================================
  // NOTIFICATION / ALERT APIs
  // ============================================================================
  print('\n--- NOTIFICATION / ALERT APIs ---');
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/mobile/notifications', withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'POST', '/api/mobile/notifications', data: {'id': 'test'}, withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/mobile/alerts/settings', withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'POST', '/api/mobile/alerts/settings', data: {'ticker': 'AAPL', 'condition': 'above', 'value': 100}, withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'DELETE', '/api/mobile/alerts/settings', queryParameters: {'id': 'test-id'}, withAuth: true);

  // ============================================================================
  // PAYMENT APIs
  // ============================================================================
  print('\n--- PAYMENT APIs ---');
  await testEndpoint(results, dio, dioAuth, 'POST', '/api/paymob/create-payment', data: {'amount': 100, 'currency': 'EGP', 'plan_id': 'plus'}, withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'POST', '/api/instapay/verify', data: {'tx_hash': 'dummy-hash'}, withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'POST', '/api/google-play/verify-receipt', data: {'receipt_data': 'dummy-receipt'}, withAuth: true);
  await testEndpoint(results, dio, dioAuth, 'POST', '/api/push/register', data: {'push_token': 'dummy-token'}, withAuth: true);

  // ============================================================================
  // DASHBOARD / NEWS / MOBILE APIs
  // ============================================================================
  print('\n--- DASHBOARD / NEWS / MOBILE APIs ---');
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/mobile/dashboard', withAuth: false);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/mobile/news', withAuth: false);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/mobile/recommendations', withAuth: false);
  await testEndpoint(results, dio, dioAuth, 'GET', '/api/mobile/stocks/EGX/recommendation', withAuth: false);

  // ============================================================================
  // GENERATE REPORT
  // ============================================================================
  print('\n');
  print('='.padRight(80, '='));
  print('  GENERATING REPORT...');
  print('='.padRight(80, '='));

  final report = generateReport(results);
  final reportPath = 'D:/My WebStie Applications/Flutter/investment/api_test_report.md';
  final file = File(reportPath);
  await file.writeAsString(report);
  print('\nReport saved to: $reportPath');
  print('\nSummary:');
  print('  Total endpoints tested: ${results.length}');
  print('  Working (2xx): ${results.where((r) => r.statusCode != null && r.statusCode! >= 200 && r.statusCode! < 300).length}');
  print('  Auth required (401): ${results.where((r) => r.statusCode == 401).length}');
  print('  Not found (404): ${results.where((r) => r.statusCode == 404).length}');
  print('  Server errors (5xx): ${results.where((r) => r.statusCode != null && r.statusCode! >= 500).length}');
  print('  Other errors: ${results.where((r) => r.statusCode == null || (r.statusCode! < 200 || r.statusCode! >= 300 && r.statusCode! != 401 && r.statusCode! != 404)).length}');
}

String generateReport(List<ApiTestResult> results) {
  final buffer = StringBuffer();

  buffer.writeln('# API Test Report');
  buffer.writeln('');
  buffer.writeln('**Generated:** ${DateTime.now()}');
  buffer.writeln('**Base URL:** $baseUrl');
  buffer.writeln('');
  buffer.writeln('---');
  buffer.writeln('');

  // Summary
  final working = results.where((r) => r.statusCode != null && r.statusCode! >= 200 && r.statusCode! < 300).length;
  final authRequired = results.where((r) => r.statusCode == 401).length;
  final notFound = results.where((r) => r.statusCode == 404).length;
  final serverErrors = results.where((r) => r.statusCode != null && r.statusCode! >= 500).length;
  final otherErrors = results.length - working - authRequired - notFound - serverErrors;

  buffer.writeln('## Summary');
  buffer.writeln('');
  buffer.writeln('| Metric | Count |');
  buffer.writeln('|--------|-------|');
  buffer.writeln('| Total endpoints tested | ${results.length} |');
  buffer.writeln('| Working (2xx) | $working |');
  buffer.writeln('| Auth required (401) | $authRequired |');
  buffer.writeln('| Not found (404) | $notFound |');
  buffer.writeln('| Server errors (5xx) | $serverErrors |');
  buffer.writeln('| Other errors | $otherErrors |');
  buffer.writeln('');

  // Non-working endpoints
  buffer.writeln('## Issues Found');
  buffer.writeln('');

  final issues = results.where((r) {
    if (r.statusCode == null) return true;
    if (r.statusCode! >= 200 && r.statusCode! < 300) return false;
    return true;
  }).toList();

  if (issues.isEmpty) {
    buffer.writeln('No issues found! All endpoints are working.');
  } else {
    buffer.writeln('### Endpoints with Problems');
    buffer.writeln('');
    buffer.writeln('| # | Endpoint | Method | Auth | Status | Error/Response |');
    buffer.writeln('|---|----------|--------|------|--------|----------------|');

    for (var i = 0; i < issues.length; i++) {
      final r = issues[i];
      final status = r.statusCode != null ? r.statusCode.toString() : 'NO RESPONSE';
      final error = (r.error ?? r.responsePreview ?? 'Unknown error').replaceAll('|', '/').replaceAll('\n', ' ');
      final auth = r.withAuth ? 'Yes' : 'No';
      buffer.writeln('| ${i + 1} | `${r.endpoint}` | ${r.method} | $auth | $status | $error |');
    }
  }
  buffer.writeln('');

  // Detailed results
  buffer.writeln('## Detailed Results');
  buffer.writeln('');
  buffer.writeln('| # | Endpoint | Method | Auth | Status | Duration | Preview |');
  buffer.writeln('|---|----------|--------|------|--------|----------|---------|');

  for (var i = 0; i < results.length; i++) {
    final r = results[i];
    final status = r.statusCode != null ? r.statusCode.toString() : 'ERR';
    final duration = r.duration != null ? '${r.duration!.inMilliseconds}ms' : 'N/A';
    final preview = (r.responsePreview ?? '').replaceAll('|', '/').replaceAll('\n', ' ');
    final auth = r.withAuth ? 'Yes' : 'No';
    buffer.writeln('| ${i + 1} | `${r.endpoint}` | ${r.method} | $auth | $status | $duration | $preview |');
  }
  buffer.writeln('');

  // Recommendations
  buffer.writeln('## Recommendations for Backend Developer');
  buffer.writeln('');

  if (notFound > 0) {
    buffer.writeln('### Missing Endpoints (404)');
    buffer.writeln('');
    final missing = results.where((r) => r.statusCode == 404).toList();
    for (final r in missing) {
      buffer.writeln('- **${r.method} ${r.endpoint}** - This endpoint does not exist on the server. Please implement it.');
    }
    buffer.writeln('');
  }

  if (serverErrors > 0) {
    buffer.writeln('### Server Errors (5xx)');
    buffer.writeln('');
    final errors = results.where((r) => r.statusCode != null && r.statusCode! >= 500).toList();
    for (final r in errors) {
      buffer.writeln('- **${r.method} ${r.endpoint}** - Returns ${r.statusCode}. Check server logs.');
    }
    buffer.writeln('');
  }

  if (authRequired > 0 && authRequired > results.length * 0.3) {
    buffer.writeln('### Auth-Protected Endpoints');
    buffer.writeln('');
    buffer.writeln('The following endpoints return 401 with dummy token (expected for auth-required endpoints):');
    buffer.writeln('');
    final authEndpoints = results.where((r) => r.statusCode == 401).toList();
    for (final r in authEndpoints) {
      buffer.writeln('- ${r.method} ${r.endpoint}');
    }
    buffer.writeln('');
    buffer.writeln('> Note: These are working correctly - they just require a valid auth token.');
    buffer.writeln('');
  }

  buffer.writeln('---');
  buffer.writeln('');
  buffer.writeln('*Report generated by API Test Runner*');

  return buffer.toString();
}
