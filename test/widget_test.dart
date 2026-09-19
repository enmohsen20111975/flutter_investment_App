// Basic Flutter widget test for مساعد الاستثمار App

import 'package:flutter_test/flutter_test.dart';
import 'package:investment_assistant/main.dart';
import 'package:investment_assistant/api/cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('App renders successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: GLMInvestmentApp(initialRoute: '/auth', isDarkMode: false),
      ),
    );
    // Verify the app renders with the title
    expect(find.text('مساعد الاستثمار'), findsWidgets);
  });

  test('ApiCacheManager reuses valid in-memory data', () async {
    final manager = ApiCacheManager.instance;
    const key = 'cache_test_valid';
    manager.invalidate(key);
    var calls = 0;

    Future<Map<String, dynamic>> fetch() async {
      calls++;
      return {'value': calls};
    }

    final first = await manager.fetch<Map<String, dynamic>>(
      key: key,
      fetcher: fetch,
      ttl: const Duration(minutes: 5),
    );
    final second = await manager.fetch<Map<String, dynamic>>(
      key: key,
      fetcher: fetch,
      ttl: const Duration(minutes: 5),
    );

    expect(first['value'], 1);
    expect(second['value'], 1);
    expect(calls, 1);
    manager.invalidate(key);
  });

  test('ApiCacheManager returns stale data and refreshes in background',
      () async {
    final manager = ApiCacheManager.instance;
    const key = 'cache_test_stale';
    manager.invalidate(key);
    var calls = 0;

    Future<Map<String, dynamic>> fetch() async {
      calls++;
      await Future.delayed(const Duration(milliseconds: 20));
      return {'value': calls};
    }

    await manager.fetch<Map<String, dynamic>>(
      key: key,
      fetcher: fetch,
      ttl: const Duration(milliseconds: 5),
    );
    await Future.delayed(const Duration(milliseconds: 10));
    final stale = await manager.fetch<Map<String, dynamic>>(
      key: key,
      fetcher: fetch,
      ttl: const Duration(milliseconds: 5),
    );
    await Future.delayed(const Duration(milliseconds: 50));

    expect(stale['value'], 1);
    expect(manager.getCached<Map<String, dynamic>>(key)?['value'], 2);
    expect(calls, 2);
    manager.invalidate(key);
  });
}
