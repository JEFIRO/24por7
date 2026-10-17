enum TerminalOperationalStatus {
  saudavel,
  atencao,
  critico,
  offline;

  String get apiName => name.toUpperCase();
  String get label => switch (this) {
    saudavel => 'Saudável',
    atencao => 'Atenção',
    critico => 'Crítico',
    offline => 'Offline',
  };

  static TerminalOperationalStatus parse(Object? value) => values.firstWhere(
    (item) => item.apiName == value?.toString().toUpperCase(),
    orElse: () => TerminalOperationalStatus.atencao,
  );
}

double? _double(Object? value) =>
    value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '');
int? _int(Object? value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');
DateTime? _date(Object? value) =>
    value == null ? null : DateTime.tryParse(value.toString())?.toLocal();

class SystemTelemetry {
  const SystemTelemetry({
    this.uptimeSeconds,
    this.cpuUsagePercent,
    this.cpuTemperatureCelsius,
    this.memoryUsedBytes,
    this.memoryTotalBytes,
    this.memoryUsagePercent,
    this.diskUsedBytes,
    this.diskTotalBytes,
    this.diskUsagePercent,
    this.loadAverage1m,
    this.undervoltageNow,
    this.undervoltageOccurred,
    this.throttledNow,
    this.throttledOccurred,
    this.frequencyCappedNow,
    this.frequencyCappedOccurred,
    this.softTemperatureLimitNow,
    this.softTemperatureLimitOccurred,
    this.throttledRaw,
  });
  final int? uptimeSeconds;
  final double? cpuUsagePercent;
  final double? cpuTemperatureCelsius;
  final int? memoryUsedBytes;
  final int? memoryTotalBytes;
  final double? memoryUsagePercent;
  final int? diskUsedBytes;
  final int? diskTotalBytes;
  final double? diskUsagePercent;
  final double? loadAverage1m;
  final bool? undervoltageNow;
  final bool? undervoltageOccurred;
  final bool? throttledNow;
  final bool? throttledOccurred;
  final bool? frequencyCappedNow;
  final bool? frequencyCappedOccurred;
  final bool? softTemperatureLimitNow;
  final bool? softTemperatureLimitOccurred;
  final String? throttledRaw;

  factory SystemTelemetry.fromJson(Map<String, dynamic> json) =>
      SystemTelemetry(
        uptimeSeconds: _int(json['uptimeSeconds']),
        cpuUsagePercent: _double(json['cpuUsagePercent']),
        cpuTemperatureCelsius: _double(json['cpuTemperatureCelsius']),
        memoryUsedBytes: _int(json['memoryUsedBytes']),
        memoryTotalBytes: _int(json['memoryTotalBytes']),
        memoryUsagePercent: _double(json['memoryUsagePercent']),
        diskUsedBytes: _int(json['diskUsedBytes']),
        diskTotalBytes: _int(json['diskTotalBytes']),
        diskUsagePercent: _double(json['diskUsagePercent']),
        loadAverage1m: _double(json['loadAverage1m']),
        undervoltageNow: json['undervoltageNow'] as bool?,
        undervoltageOccurred: json['undervoltageOccurred'] as bool?,
        throttledNow: json['throttledNow'] as bool?,
        throttledOccurred: json['throttledOccurred'] as bool?,
        frequencyCappedNow: json['frequencyCappedNow'] as bool?,
        frequencyCappedOccurred: json['frequencyCappedOccurred'] as bool?,
        softTemperatureLimitNow: json['softTemperatureLimitNow'] as bool?,
        softTemperatureLimitOccurred:
            json['softTemperatureLimitOccurred'] as bool?,
        throttledRaw: json['throttledRaw']?.toString(),
      );
}

class NetworkTelemetry {
  const NetworkTelemetry({
    this.connected,
    this.interfaceName,
    this.ssid,
    this.localIp,
    this.wifiSignalPercent,
    this.wifiSignalQuality,
    this.backendReachable,
    this.backendLatencyMs,
  });
  final bool? connected;
  final String? interfaceName;
  final String? ssid;
  final String? localIp;
  final int? wifiSignalPercent;
  final String? wifiSignalQuality;
  final bool? backendReachable;
  final int? backendLatencyMs;
  factory NetworkTelemetry.fromJson(Map<String, dynamic> json) =>
      NetworkTelemetry(
        connected: json['connected'] as bool?,
        interfaceName: json['interfaceName']?.toString(),
        ssid: json['ssid']?.toString(),
        localIp: json['localIp']?.toString(),
        wifiSignalPercent: _int(json['wifiSignalPercent']),
        wifiSignalQuality: json['wifiSignalQuality']?.toString(),
        backendReachable: json['backendReachable'] as bool?,
        backendLatencyMs: _int(json['backendLatencyMs']),
      );
}

class ApplicationTelemetry {
  const ApplicationTelemetry({
    this.version,
    this.uptimeSeconds,
    this.websocketStatus,
    this.lastProductSyncStartedAt,
    this.lastProductSyncCompletedAt,
    this.lastSuccessfulSyncAt,
    this.lastSyncError,
    this.purchaseActive,
    this.paymentInProgress,
  });
  final String? version;
  final int? uptimeSeconds;
  final String? websocketStatus;
  final DateTime? lastProductSyncStartedAt;
  final DateTime? lastProductSyncCompletedAt;
  final DateTime? lastSuccessfulSyncAt;
  final String? lastSyncError;
  final bool? purchaseActive;
  final bool? paymentInProgress;
  factory ApplicationTelemetry.fromJson(Map<String, dynamic> json) =>
      ApplicationTelemetry(
        version: json['version']?.toString(),
        uptimeSeconds: _int(json['uptimeSeconds']),
        websocketStatus: json['websocketStatus']?.toString(),
        lastProductSyncStartedAt: _date(json['lastProductSyncStartedAt']),
        lastProductSyncCompletedAt: _date(json['lastProductSyncCompletedAt']),
        lastSuccessfulSyncAt: _date(json['lastSuccessfulSyncAt']),
        lastSyncError: json['lastSyncError']?.toString(),
        purchaseActive: json['purchaseActive'] as bool?,
        paymentInProgress: json['paymentInProgress'] as bool?,
      );
}

class DisplayTelemetry {
  const DisplayTelemetry({this.width, this.height, this.orientation});
  final int? width;
  final int? height;
  final String? orientation;
  factory DisplayTelemetry.fromJson(Map<String, dynamic> json) =>
      DisplayTelemetry(
        width: _int(json['width']),
        height: _int(json['height']),
        orientation: json['orientation']?.toString(),
      );
}

class TelemetryAlert {
  const TelemetryAlert({
    required this.id,
    required this.type,
    required this.status,
    required this.message,
    required this.openedAt,
    this.lastObservedAt,
    this.resolvedAt,
  });
  final String id;
  final String type;
  final String status;
  final String message;
  final DateTime openedAt;
  final DateTime? lastObservedAt;
  final DateTime? resolvedAt;
  factory TelemetryAlert.fromJson(Map<String, dynamic> json) => TelemetryAlert(
    id: json['id'].toString(),
    type: json['type'].toString(),
    status: json['status'].toString(),
    message: json['message'].toString(),
    openedAt: _date(json['openedAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    lastObservedAt: _date(json['lastObservedAt']),
    resolvedAt: _date(json['resolvedAt']),
  );
}

class TerminalTelemetry {
  const TerminalTelemetry({
    required this.terminalId,
    required this.terminalNome,
    required this.condominioId,
    required this.condominioNome,
    required this.online,
    required this.status,
    required this.reasons,
    this.lastHeartbeatAt,
    this.capturedAt,
    this.receivedAt,
    this.system,
    this.network,
    this.application,
    this.display,
    this.activeAlerts = const [],
  });
  final String terminalId;
  final String terminalNome;
  final String condominioId;
  final String condominioNome;
  final bool online;
  final TerminalOperationalStatus status;
  final List<String> reasons;
  final DateTime? lastHeartbeatAt;
  final DateTime? capturedAt;
  final DateTime? receivedAt;
  final SystemTelemetry? system;
  final NetworkTelemetry? network;
  final ApplicationTelemetry? application;
  final DisplayTelemetry? display;
  final List<TelemetryAlert> activeAlerts;

  factory TerminalTelemetry.fromJson(Map<String, dynamic> json) =>
      TerminalTelemetry(
        terminalId: json['terminalId'].toString(),
        terminalNome: json['terminalNome']?.toString() ?? 'Terminal',
        condominioId: json['condominioId']?.toString() ?? '',
        condominioNome: json['condominioNome']?.toString() ?? '',
        online: json['online'] == true,
        status: TerminalOperationalStatus.parse(json['status']),
        reasons: (json['reasons'] as List? ?? const [])
            .map((e) => e.toString())
            .toList(),
        lastHeartbeatAt: _date(json['lastHeartbeatAt']),
        capturedAt: _date(json['capturedAt']),
        receivedAt: _date(json['receivedAt']),
        system: json['system'] is Map
            ? SystemTelemetry.fromJson(
                Map<String, dynamic>.from(json['system'] as Map),
              )
            : null,
        network: json['network'] is Map
            ? NetworkTelemetry.fromJson(
                Map<String, dynamic>.from(json['network'] as Map),
              )
            : null,
        application: json['application'] is Map
            ? ApplicationTelemetry.fromJson(
                Map<String, dynamic>.from(json['application'] as Map),
              )
            : null,
        display: json['display'] is Map
            ? DisplayTelemetry.fromJson(
                Map<String, dynamic>.from(json['display'] as Map),
              )
            : null,
        activeAlerts: (json['activeAlerts'] as List? ?? const [])
            .map(
              (e) =>
                  TelemetryAlert.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList(),
      );
}

class MonitoringDashboard {
  const MonitoringDashboard({
    required this.total,
    required this.online,
    required this.saudaveis,
    required this.atencao,
    required this.criticos,
    required this.offline,
    required this.terminals,
  });
  final int total;
  final int online;
  final int saudaveis;
  final int atencao;
  final int criticos;
  final int offline;
  final List<TerminalTelemetry> terminals;
  factory MonitoringDashboard.fromJson(Map<String, dynamic> json) =>
      MonitoringDashboard(
        total: _int(json['total']) ?? 0,
        online: _int(json['online']) ?? 0,
        saudaveis: _int(json['saudaveis']) ?? 0,
        atencao: _int(json['atencao']) ?? 0,
        criticos: _int(json['criticos']) ?? 0,
        offline: _int(json['offline']) ?? 0,
        terminals: (json['terminals'] as List? ?? const [])
            .map(
              (e) => TerminalTelemetry.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList(),
      );
}

class TelemetryHistoryPoint {
  const TelemetryHistoryPoint({
    required this.capturedAt,
    required this.status,
    this.cpuUsagePercent,
    this.cpuTemperatureCelsius,
    this.memoryUsagePercent,
    this.diskUsagePercent,
    this.backendLatencyMs,
    this.wifiSignalPercent,
  });
  final DateTime capturedAt;
  final TerminalOperationalStatus status;
  final double? cpuUsagePercent;
  final double? cpuTemperatureCelsius;
  final double? memoryUsagePercent;
  final double? diskUsagePercent;
  final double? backendLatencyMs;
  final double? wifiSignalPercent;
  factory TelemetryHistoryPoint.fromJson(Map<String, dynamic> json) =>
      TelemetryHistoryPoint(
        capturedAt:
            _date(json['capturedAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
        status: TerminalOperationalStatus.parse(json['status']),
        cpuUsagePercent: _double(json['cpuUsagePercent']),
        cpuTemperatureCelsius: _double(json['cpuTemperatureCelsius']),
        memoryUsagePercent: _double(json['memoryUsagePercent']),
        diskUsagePercent: _double(json['diskUsagePercent']),
        backendLatencyMs: _double(json['backendLatencyMs']),
        wifiSignalPercent: _double(json['wifiSignalPercent']),
      );
}
