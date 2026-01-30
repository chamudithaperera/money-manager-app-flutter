// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:my_money_manager/app/app.dart';

void main() {
  testWidgets('App builds and shows splash', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    await tester.pump();
    // Advance past splash stages so tagline is visible (stage 4 at 1800ms)
    await tester.pump(const Duration(milliseconds: 2000));

    expect(find.text('Your money, your future'), findsOneWidget);
  });
}
