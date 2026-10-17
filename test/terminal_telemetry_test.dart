import 'package:app_24por7/src/model/terminal_telemetry.dart';
import 'package:app_24por7/src/model/terminal_telemetry_repository.dart';
import 'package:app_24por7/src/page/monitoring_dashboard_page.dart';
import 'package:app_24por7/src/page/terminal_telemetry_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'desserializa estado atual sem transformar métricas ausentes em zero',
    () {
      final terminal = TerminalTelemetry.fromJson({
        'terminalId': 'terminal-a',
        'terminalNome': 'Terminal 01',
        'condominioId': 'cond-a',
        'condominioNome': 'Firenze',
        'online': true,
        'status': 'CRITICO',
        'reasons': ['Problema de alimentação detectado'],
        'system': {
          'cpuUsagePercent': 31.8,
          'cpuTemperatureCelsius': null,
          'undervoltageNow': true,
          'undervoltageOccurred': true,
          'throttledRaw': '0x50005',
        },
        'network': {
          'ssid': 'MinhaRede',
          'wifiSignalPercent': 82,
          'backendLatencyMs': 43,
        },
        'application': {'version': '1.0.0', 'websocketStatus': 'CONNECTED'},
        'display': {'width': 1024, 'height': 600, 'orientation': 'HORIZONTAL'},
        'activeAlerts': [],
      });

      expect(terminal.status, TerminalOperationalStatus.critico);
      expect(terminal.system!.cpuUsagePercent, 31.8);
      expect(terminal.system!.cpuTemperatureCelsius, isNull);
      expect(terminal.system!.undervoltageNow, isTrue);
      expect(terminal.network!.backendLatencyMs, 43);
      expect(terminal.display!.orientation, 'HORIZONTAL');
    },
  );

  testWidgets('dashboard mostra resumo, alerta e métricas do Terminal', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    final repository = _FakeRepository();
    await tester.pumpWidget(
      MaterialApp(home: MonitoringDashboardPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Monitoramento'), findsOneWidget);
    expect(find.text('Terminal 01'), findsOneWidget);
    expect(find.text('Crítico'), findsWidgets);
    expect(find.textContaining('Problema de alimentação'), findsOneWidget);
    expect(find.text('61°C'), findsOneWidget);
    expect(find.text('Excelente'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('detalhes destacam energia e renderizam seis gráficos', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    final repository = _FakeRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: TerminalTelemetryDetailPage(
          terminalId: 'terminal-a',
          repository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PROBLEMA DE ALIMENTAÇÃO'), findsOneWidget);
    expect(find.text('Subtensão detectada no Raspberry.'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Diagnóstico bruto'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('0x50005'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Display'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('1024 × 600'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Histórico'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('chart-Temperatura')), findsOneWidget);
    expect(find.byKey(const ValueKey('chart-CPU')), findsOneWidget);
    expect(find.byKey(const ValueKey('chart-RAM')), findsOneWidget);
    expect(find.byKey(const ValueKey('chart-Disco')), findsOneWidget);
    expect(find.byKey(const ValueKey('chart-Latência')), findsOneWidget);
    expect(find.byKey(const ValueKey('chart-Sinal Wi-Fi')), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.binding.setSurfaceSize(null);
  });
}

class _FakeRepository extends TerminalTelemetryRepository {
  final terminal = TerminalTelemetry(
    terminalId: 'terminal-a',
    terminalNome: 'Terminal 01',
    condominioId: 'cond-a',
    condominioNome: 'Residencial Firenze',
    online: true,
    status: TerminalOperationalStatus.critico,
    reasons: const ['Problema de alimentação detectado'],
    lastHeartbeatAt: DateTime.now(),
    system: const SystemTelemetry(
      uptimeSeconds: 52780,
      cpuUsagePercent: 31,
      cpuTemperatureCelsius: 61,
      memoryUsedBytes: 1024000000,
      memoryTotalBytes: 2147483648,
      memoryUsagePercent: 48,
      diskUsedBytes: 12000000000,
      diskTotalBytes: 32000000000,
      diskUsagePercent: 37,
      undervoltageNow: true,
      undervoltageOccurred: true,
      throttledNow: false,
      throttledOccurred: true,
      throttledRaw: '0x50005',
    ),
    network: const NetworkTelemetry(
      connected: true,
      interfaceName: 'wlan0',
      ssid: 'MinhaRede',
      localIp: '192.168.1.45',
      wifiSignalPercent: 82,
      wifiSignalQuality: 'EXCELENTE',
      backendReachable: true,
      backendLatencyMs: 43,
    ),
    application: const ApplicationTelemetry(
      version: '1.0.0',
      uptimeSeconds: 18020,
      websocketStatus: 'CONNECTED',
      purchaseActive: false,
      paymentInProgress: false,
    ),
    display: const DisplayTelemetry(
      width: 1024,
      height: 600,
      orientation: 'HORIZONTAL',
    ),
  );

  @override
  Future<MonitoringDashboard> dashboard({
    String? condominioId,
    TerminalOperationalStatus? status,
  }) async => MonitoringDashboard(
    total: 1,
    online: 1,
    saudaveis: 0,
    atencao: 0,
    criticos: 1,
    offline: 0,
    terminals: [terminal],
  );

  @override
  Future<TerminalTelemetry> detail(String terminalId) async => terminal;

  @override
  Future<List<TelemetryAlert>> alerts(String terminalId) async => [
    TelemetryAlert(
      id: 'alert-a',
      type: 'UNDERVOLTAGE',
      status: 'ACTIVE',
      message: 'Subtensão detectada no Raspberry',
      openedAt: DateTime.now(),
    ),
  ];

  @override
  Future<List<TelemetryHistoryPoint>> history(
    String terminalId, {
    String period = '1h',
  }) async => List.generate(
    3,
    (index) => TelemetryHistoryPoint(
      capturedAt: DateTime.now().subtract(Duration(minutes: 2 - index)),
      status: TerminalOperationalStatus.critico,
      cpuUsagePercent: 30 + index.toDouble(),
      cpuTemperatureCelsius: 60 + index.toDouble(),
      memoryUsagePercent: 45 + index.toDouble(),
      diskUsagePercent: 37,
      backendLatencyMs: 40 + index.toDouble(),
      wifiSignalPercent: 80 - index.toDouble(),
    ),
  );
}
