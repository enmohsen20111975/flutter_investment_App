// Basic Flutter widget test for مساعد الاستثمار App

import 'package:flutter_test/flutter_test.dart';
import 'package:investment_assistant/app.dart';

void main() {
  testWidgets('App renders successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const GLMInvestmentApp());
    // Verify the app renders with the title
    expect(find.text('مساعد الاستثمار'), findsWidgets);
  });
}
