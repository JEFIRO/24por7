import 'package:app_24por7/core/formatters/app_formatters.dart';
import 'package:app_24por7/core/theme/app_theme.dart';
import 'package:app_24por7/core/theme/branding_config.dart';
import 'package:app_24por7/core/widgets/async_state.dart';
import 'package:app_24por7/src/page/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() {
  setUpAll(() async {
    tz.initializeTimeZones();
    await initializeDateFormatting('pt_BR');
  });

  test('formatters preserve canonical decimal and use Sao Paulo time', () {
    expect(AppFormatters.currencyText('10.165750'), 'R\$ 10,17');
    expect(
      AppFormatters.dateTime(DateTime.parse('2026-08-30T11:00:00Z')),
      '30/08/2026 08:00',
    );
  });

  testWidgets('shared error state exposes a retry action', (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(BrandingConfig.fallback),
        home: Scaffold(
          body: AppErrorState(
            message: 'Falha controlada',
            onRetry: () => retries++,
          ),
        ),
      ),
    );
    expect(find.text('Não foi possível carregar os dados'), findsOneWidget);
    await tester.tap(find.text('Tentar novamente'));
    expect(retries, 1);
  });

  testWidgets('mobile shell uses five-item bottom navigation', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      BrandingScope(
        branding: BrandingConfig.fallback,
        child: MaterialApp(
          theme: AppTheme.light(BrandingConfig.fallback),
          home: const HomePage(initialLocation: '/mais'),
        ),
      ),
    );

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Início'), findsOneWidget);
    expect(find.text('Operação'), findsOneWidget);
    expect(find.text('Produtos'), findsOneWidget);
    expect(find.text('Estoque'), findsOneWidget);
    expect(find.text('Mais'), findsWidgets);
  });

  testWidgets('desktop shell uses grouped expanded sidebar', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      BrandingScope(
        branding: const BrandingConfig(displayName: 'Mercado Firenze'),
        child: MaterialApp(
          theme: AppTheme.light(BrandingConfig.fallback),
          home: const HomePage(initialLocation: '/mais'),
        ),
      ),
    );

    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('Mercado Firenze'), findsOneWidget);
    expect(find.text('CATÁLOGO'), findsOneWidget);
    expect(find.text('INTEGRAÇÕES'), findsOneWidget);
  });
}
