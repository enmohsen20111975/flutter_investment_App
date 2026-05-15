// Basic Flutter widget test for مساعد الاستثمار App

import 'package:flutter_test/flutter_test.dart';
import 'package:investment_assistant/main.dart';
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
}
