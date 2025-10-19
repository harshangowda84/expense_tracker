// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:spendly/main.dart';

void main() {
  testWidgets('Expense tracker app test', (WidgetTester tester) async {
  // Build our app and trigger a frame.
  await tester.pumpWidget(const SpendlyApp());

  // Verify that the app built (SpendlyApp exists in the widget tree)
  expect(find.byType(SpendlyApp), findsOneWidget);
  });
}
