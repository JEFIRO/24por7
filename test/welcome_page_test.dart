import 'package:app_24por7/core/navigation/welcome_state.dart';
import 'package:app_24por7/main.dart';
import 'package:app_24por7/src/page/login_page.dart';
import 'package:app_24por7/src/page/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => WelcomeState.pending = false);

  testWidgets('primeira abertura mostra boas-vindas e leva ao login', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    WelcomeState.pending = true;

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    expect(find.byType(WelcomePage), findsOneWidget);
    expect(find.text('Seus mercados'), findsOneWidget);

    // Com a fonte de teste o texto ocupa mais altura que no aparelho.
    await tester.ensureVisible(find.byKey(const Key('welcome-enter')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('welcome-enter')));
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
    expect(WelcomeState.pending, isFalse);
  });

  testWidgets('depois de vista, a abertura vai direto ao login', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    expect(find.byType(WelcomePage), findsNothing);
    expect(find.byType(LoginPage), findsOneWidget);
  });
}
