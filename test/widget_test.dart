// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:my_money_manager/app/app.dart';
import 'package:my_money_manager/features/home/models/transaction.dart';
import 'package:my_money_manager/providers/transaction_providers.dart';

void main() {
  testWidgets('App builds and shows splash', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionsProvider.overrideWith(FakeTransactionNotifier.new),
        ],
        child: const App(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    expect(find.byType(App), findsOneWidget);
  });
}

class FakeTransactionNotifier extends TransactionNotifier {
  @override
  Future<List<Transaction>> build() async => [];
}
