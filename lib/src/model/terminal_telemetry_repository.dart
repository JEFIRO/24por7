import 'api_client.dart';
import 'terminal_telemetry.dart';

class TerminalTelemetryRepository {
  TerminalTelemetryRepository({ApiClient? client})
    : client = client ?? ApiClient.instance;
  final ApiClient client;

  Future<MonitoringDashboard> dashboard({
    String? condominioId,
    TerminalOperationalStatus? status,
  }) async => MonitoringDashboard.fromJson(
    Map<String, dynamic>.from(
      await client.get(
            '/terminais/monitoramento',
            query: {'condominioId': condominioId, 'status': status?.apiName},
          )
          as Map,
    ),
  );

  Future<TerminalTelemetry> detail(String terminalId) async =>
      TerminalTelemetry.fromJson(
        Map<String, dynamic>.from(
          await client.get('/terminais/$terminalId/telemetria') as Map,
        ),
      );

  Future<List<TelemetryHistoryPoint>> history(
    String terminalId, {
    String period = '1h',
  }) async =>
      ((await client.get(
                '/terminais/$terminalId/telemetria/historico',
                query: {'period': period},
              ))
              as List)
          .map(
            (item) => TelemetryHistoryPoint.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();

  Future<List<TelemetryAlert>> alerts(String terminalId) async =>
      ((await client.get('/terminais/$terminalId/telemetria/alertas')) as List)
          .map(
            (item) =>
                TelemetryAlert.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
}
