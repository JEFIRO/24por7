import 'package:app_24por7/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows administrative login while unauthenticated', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Bem-vindo'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}
