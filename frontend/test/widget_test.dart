import 'package:flutter_test/flutter_test.dart';
import 'package:finance_saas_frontend/main.dart';

void main() {
  testWidgets('App smoke test loads login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const FinanceSaasApp());
    expect(find.byType(FinanceSaasApp), findsOneWidget);
  });
}
