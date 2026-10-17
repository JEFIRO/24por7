import 'dart:async';

import 'package:app_24por7/core/theme/branding_config.dart';
import 'package:app_24por7/src/model/admin_dashboard.dart';
import 'package:app_24por7/src/model/admin_repository.dart';
import 'package:app_24por7/src/model/decimal_value.dart';
import 'package:app_24por7/src/page/dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() {
  setUpAll(tz.initializeTimeZones);

  testWidgets('Home exibe loading sem substituir por dados parciais', (
    tester,
  ) async {
    final completer = Completer<AdminDashboard>();
    await tester.pumpWidget(
      _app(DashboardPage(repository: _FakeAdminRepository(completer.future))),
    );

    expect(find.byKey(const Key('dashboard-loading')), findsOneWidget);
    expect(find.byKey(const Key('dashboard-content')), findsNothing);
  });

  testWidgets('Home exibe erro e permite tentar novamente', (tester) async {
    await tester.pumpWidget(
      _app(DashboardPage(repository: _FailingAdminRepository())),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dashboard-error')), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
  });

  testWidgets('Home mostra KPIs, checklist e atividade usando um snapshot', (
    tester,
  ) async {
    await _surface(tester, const Size(1366, 1000));
    await tester.pumpWidget(
      _app(
        DashboardPage(
          repository: _FakeAdminRepository(Future.value(_dashboard())),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dashboard-content')), findsOneWidget);
    expect(find.byKey(const Key('kpi-sales')), findsOneWidget);
    expect(find.text('143'), findsOneWidget);
    expect(find.text('R\$ 4.581,27'), findsOneWidget);
    expect(find.byKey(const Key('onboarding-checklist')), findsOneWidget);
    expect(find.byKey(const Key('recent-activity')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home reorganiza cards em largura mobile sem overflow', (
    tester,
  ) async {
    await _surface(tester, const Size(360, 800));
    await tester.pumpWidget(
      _app(
        DashboardPage(
          repository: _FakeAdminRepository(Future.value(_dashboard())),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('kpi-payments')), findsOneWidget);
    expect(find.byKey(const Key('onboarding-checklist')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home permanece estável em 600, 1024 e 1920 pixels', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });
    for (final width in [600.0, 1024.0, 1920.0]) {
      tester.view.physicalSize = Size(width, 1000);
      await tester.pumpWidget(
        _app(
          DashboardPage(
            repository: _FakeAdminRepository(Future.value(_dashboard())),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('kpi-sales')), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'largura $width');
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('pendência do checklist leva para a ação correspondente', (
    tester,
  ) async {
    String? route;
    await tester.pumpWidget(
      _app(
        DashboardPage(
          repository: _FakeAdminRepository(Future.value(_dashboard())),
          onNavigate: (value) => route = value,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Mercado Pago vinculado'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Mercado Pago vinculado'));

    expect(route, '/mercado-pago');
  });
}

class _FakeAdminRepository extends AdminRepository {
  _FakeAdminRepository(this.result);
  final Future<AdminDashboard> result;
  @override
  Future<AdminDashboard> dashboard() => result;
}

class _FailingAdminRepository extends AdminRepository {
  @override
  Future<AdminDashboard> dashboard() async => throw 'falha de rede';
}

Widget _app(Widget child) => BrandingScope(
  branding: const BrandingConfig(displayName: 'Mercado Teste'),
  child: MaterialApp(theme: ThemeData(useMaterial3: true), home: child),
);

Future<void> _surface(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
}

AdminDashboard _dashboard() => AdminDashboard(
  empresaNome: 'Mercado Teste',
  usuarioNome: 'Jefferson',
  geradoEm: DateTime.utc(2026, 9, 5, 12),
  vendasHoje: AdminSalesSummary(
    quantidadeVendas: 143,
    faturamento: DecimalValue.parse('4581.270000'),
    ticketMedio: DecimalValue.parse('32.036853'),
  ),
  terminais: const AdminTerminalSummary(
    total: 8,
    online: 7,
    offline: 1,
    comAlerta: 2,
  ),
  alertas: const AdminAlertSummary(ativos: 3, info: 0, warning: 2, critical: 1),
  estoque: const AdminStockSummary(
    regraConfigurada: false,
    motivoIndisponibilidade: 'Defina estoque mínimo',
  ),
  pagamentos: const AdminPaymentAttention(precisamAtencao: 2),
  onboarding: const AdminOnboardingStatus(
    empresaCadastrada: true,
    condominioCadastrado: true,
    terminalAtivado: true,
    mercadoPagoVinculado: false,
    pointVinculada: false,
    produtosCadastrados: true,
    produtosAssociadosCondominio: true,
  ),
  atividadeRecente: const [],
);
