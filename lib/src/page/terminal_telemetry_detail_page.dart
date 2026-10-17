import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../model/terminal_telemetry.dart';
import '../model/terminal_telemetry_repository.dart';
import 'monitoring_dashboard_page.dart';

class TerminalTelemetryDetailPage extends StatefulWidget {
  const TerminalTelemetryDetailPage({
    super.key,
    required this.terminalId,
    this.repository,
  });
  final String terminalId;
  final TerminalTelemetryRepository? repository;

  @override
  State<TerminalTelemetryDetailPage> createState() =>
      _TerminalTelemetryDetailPageState();
}

class _TerminalTelemetryDetailPageState
    extends State<TerminalTelemetryDetailPage> {
  late final TerminalTelemetryRepository _repository =
      widget.repository ?? TerminalTelemetryRepository();
  TerminalTelemetry? _terminal;
  List<TelemetryHistoryPoint> _history = const [];
  List<TelemetryAlert> _alerts = const [];
  Timer? _polling;
  String _period = '1h';
  bool _loading = true;
  bool _historyLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _polling = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _load(silent: true),
    );
  }

  @override
  void dispose() {
    _polling?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final values = await Future.wait([
        _repository.detail(widget.terminalId),
        _repository.alerts(widget.terminalId),
      ]);
      if (!mounted) return;
      setState(() {
        _terminal = values[0] as TerminalTelemetry;
        _alerts = values[1] as List<TelemetryAlert>;
        _error = null;
      });
      if (!silent || _history.isEmpty) {
        await _loadHistory();
      }
    } catch (error) {
      if (mounted && (!silent || _terminal == null)) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _historyLoading = true);
    try {
      final history = await _repository.history(
        widget.terminalId,
        period: _period,
      );
      if (mounted) setState(() => _history = history);
    } finally {
      if (mounted) setState(() => _historyLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_terminal?.terminalNome ?? 'Telemetria do Terminal'),
      actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
    ),
    body: _loading && _terminal == null
        ? const Center(child: CircularProgressIndicator())
        : _error != null && _terminal == null
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off, size: 52),
                  const SizedBox(height: 12),
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: _load,
                    child: const Text('TENTAR NOVAMENTE'),
                  ),
                ],
              ),
            ),
          )
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: _content(context, _terminal!),
            ),
          ),
  );

  List<Widget> _content(BuildContext context, TerminalTelemetry terminal) {
    final system = terminal.system;
    final network = terminal.network;
    final app = terminal.application;
    final display = terminal.display;
    final statusColor = telemetryStatusColor(context, terminal.status);
    final powerProblem = system?.undervoltageNow == true;
    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(
                terminal.online
                    ? Icons.monitor_heart
                    : Icons.desktop_access_disabled,
                size: 42,
                color: statusColor,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(terminal.condominioNome),
                    Text(
                      terminal.online ? 'ONLINE' : 'OFFLINE',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      terminal.status.label,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (terminal.reasons.isNotEmpty)
                      Text(terminal.reasons.join(' • ')),
                  ],
                ),
              ),
              Text(
                'Último sinal\n${telemetryRelativeTime(terminal.lastHeartbeatAt)}',
                textAlign: TextAlign.end,
              ),
            ],
          ),
        ),
      ),
      if (powerProblem || system?.undervoltageOccurred == true)
        Card(
          color: powerProblem
              ? Theme.of(context).colorScheme.errorContainer
              : Colors.orange.shade50,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.electrical_services,
                  color: powerProblem
                      ? Theme.of(context).colorScheme.error
                      : Colors.orange.shade900,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PROBLEMA DE ALIMENTAÇÃO',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Text('Subtensão detectada no Raspberry.'),
                      Text(
                        'Ocorrendo agora: ${_yesNo(system?.undervoltageNow)}',
                      ),
                      Text(
                        'Detectada desde o último boot: ${_yesNo(system?.undervoltageOccurred)}',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      _Section(
        title: 'Sistema',
        icon: Icons.memory,
        children: [
          _DataRow('CPU', _percent(system?.cpuUsagePercent)),
          _DataRow('Temperatura', _number(system?.cpuTemperatureCelsius, '°C')),
          _DataRow('Load average (1 min)', _number(system?.loadAverage1m, '')),
          _DataRow(
            'RAM',
            _bytesPair(
              system?.memoryUsedBytes,
              system?.memoryTotalBytes,
              system?.memoryUsagePercent,
            ),
          ),
          _DataRow(
            'Armazenamento',
            _bytesPair(
              system?.diskUsedBytes,
              system?.diskTotalBytes,
              system?.diskUsagePercent,
            ),
          ),
          _DataRow('Uptime do Raspberry', _duration(system?.uptimeSeconds)),
        ],
      ),
      _Section(
        title: 'Energia',
        icon: Icons.electrical_services,
        children: [
          _DataRow('Subtensão agora', _yesNo(system?.undervoltageNow)),
          _DataRow(
            'Subtensão registrada',
            _yesNo(system?.undervoltageOccurred),
          ),
          _DataRow('Throttling agora', _yesNo(system?.throttledNow)),
          _DataRow('Throttling registrado', _yesNo(system?.throttledOccurred)),
          _DataRow(
            'Frequência limitada agora',
            _yesNo(system?.frequencyCappedNow),
          ),
          _DataRow(
            'Limite térmico agora',
            _yesNo(system?.softTemperatureLimitNow),
          ),
          _DataRow('Diagnóstico bruto', system?.throttledRaw ?? 'Indisponível'),
        ],
      ),
      _Section(
        title: 'Rede',
        icon: Icons.wifi,
        children: [
          _DataRow(
            'Wi-Fi',
            network?.ssid ??
                (network?.connected == false ? 'Desconectado' : 'Indisponível'),
          ),
          _DataRow('Interface', network?.interfaceName ?? 'Indisponível'),
          _DataRow(
            'Sinal',
            network?.wifiSignalPercent == null
                ? 'Indisponível'
                : '${network!.wifiSignalPercent}% — ${_friendlySignal(network.wifiSignalQuality)}',
          ),
          _DataRow('IP local', network?.localIp ?? 'Indisponível'),
          _DataRow('Backend', _connection(network?.backendReachable)),
          _DataRow(
            'Latência',
            network?.backendLatencyMs == null
                ? 'Indisponível'
                : '${network!.backendLatencyMs} ms',
          ),
        ],
      ),
      _Section(
        title: 'Aplicação',
        icon: Icons.apps,
        children: [
          _DataRow('Versão', app?.version ?? 'Indisponível'),
          _DataRow('Aplicação rodando', _duration(app?.uptimeSeconds)),
          _DataRow('WebSocket', _websocket(app?.websocketStatus)),
          _DataRow(
            'Último sync',
            telemetryRelativeTime(app?.lastSuccessfulSyncAt),
          ),
          _DataRow('Último erro de sync', app?.lastSyncError ?? 'Nenhum'),
          _DataRow('Compra ativa', _yesNo(app?.purchaseActive)),
          _DataRow('Pagamento em andamento', _yesNo(app?.paymentInProgress)),
        ],
      ),
      _Section(
        title: 'Display',
        icon: Icons.desktop_windows,
        children: [
          _DataRow(
            'Resolução',
            display?.width == null || display?.height == null
                ? 'Indisponível'
                : '${display!.width} × ${display.height}',
          ),
          _DataRow('Orientação', switch (display?.orientation) {
            'HORIZONTAL' => 'Horizontal',
            'VERTICAL' => 'Vertical',
            _ => 'Indisponível',
          }),
        ],
      ),
      _HistorySection(
        history: _history,
        loading: _historyLoading,
        period: _period,
        onPeriodChanged: (value) {
          if (value == null) return;
          setState(() => _period = value);
          _loadHistory();
        },
      ),
      _AlertsSection(alerts: _alerts),
      const SizedBox(height: 24),
    ];
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.children,
  });
  final String title;
  final IconData icon;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    ),
  );
}

class _DataRow extends StatelessWidget {
  const _DataRow(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({
    required this.history,
    required this.loading,
    required this.period,
    required this.onPeriodChanged,
  });
  final List<TelemetryHistoryPoint> history;
  final bool loading;
  final String period;
  final ValueChanged<String?> onPeriodChanged;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Histórico',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              DropdownButton<String>(
                value: period,
                items: const [
                  DropdownMenuItem(value: '1h', child: Text('1 hora')),
                  DropdownMenuItem(value: '6h', child: Text('6 horas')),
                  DropdownMenuItem(value: '24h', child: Text('24 horas')),
                  DropdownMenuItem(value: '7d', child: Text('7 dias')),
                ],
                onChanged: onPeriodChanged,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: CircularProgressIndicator(),
              ),
            )
          else if (history.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('Ainda não há amostras neste período.'),
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _ChartCard(
                  title: 'Temperatura',
                  unit: '°C',
                  values: history.map((e) => e.cpuTemperatureCelsius).toList(),
                ),
                _ChartCard(
                  title: 'CPU',
                  unit: '%',
                  values: history.map((e) => e.cpuUsagePercent).toList(),
                ),
                _ChartCard(
                  title: 'RAM',
                  unit: '%',
                  values: history.map((e) => e.memoryUsagePercent).toList(),
                ),
                _ChartCard(
                  title: 'Disco',
                  unit: '%',
                  values: history.map((e) => e.diskUsagePercent).toList(),
                ),
                _ChartCard(
                  title: 'Latência',
                  unit: ' ms',
                  values: history.map((e) => e.backendLatencyMs).toList(),
                ),
                _ChartCard(
                  title: 'Sinal Wi-Fi',
                  unit: '%',
                  values: history.map((e) => e.wifiSignalPercent).toList(),
                ),
              ],
            ),
        ],
      ),
    ),
  );
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.unit,
    required this.values,
  });
  final String title;
  final String unit;
  final List<double?> values;
  @override
  Widget build(BuildContext context) {
    final available = values.whereType<double>().toList();
    return SizedBox(
      width: 310,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    available.isEmpty
                        ? '—'
                        : '${available.last.toStringAsFixed(1)}$unit',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: available.isEmpty
                    ? const Center(child: Text('Indisponível'))
                    : CustomPaint(
                        key: ValueKey('chart-$title'),
                        painter: _LineChartPainter(
                          values,
                          Theme.of(context).colorScheme.primary,
                        ),
                        size: const Size(double.infinity, 100),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter(this.values, this.color);
  final List<double?> values;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final points = <({int index, double value})>[];
    for (var index = 0; index < values.length; index++) {
      if (values[index] case final value?) {
        points.add((index: index, value: value));
      }
    }
    if (points.isEmpty) return;
    final minValue = points.map((e) => e.value).reduce(math.min);
    final maxValue = points.map((e) => e.value).reduce(math.max);
    final range = math.max(1.0, maxValue - minValue);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    final grid = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    for (var row = 0; row <= 4; row++) {
      final y = size.height * row / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final path = Path();
    for (var position = 0; position < points.length; position++) {
      final point = points[position];
      final x = values.length <= 1
          ? 0.0
          : size.width * point.index / (values.length - 1);
      final y = size.height - ((point.value - minValue) / range * size.height);
      if (position == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}

class _AlertsSection extends StatelessWidget {
  const _AlertsSection({required this.alerts});
  final List<TelemetryAlert> alerts;
  @override
  Widget build(BuildContext context) => _Section(
    title: 'Alertas',
    icon: Icons.notifications_active_outlined,
    children: alerts.isEmpty
        ? const [Text('Nenhum alerta registrado.')]
        : alerts
              .map(
                (alert) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    alert.status == 'ACTIVE'
                        ? Icons.warning_amber
                        : Icons.check_circle,
                    color: alert.status == 'ACTIVE'
                        ? Colors.orange.shade800
                        : Colors.green.shade700,
                  ),
                  title: Text(alert.message),
                  subtitle: Text(
                    '${alert.type.replaceAll('_', ' ')} • ${alert.status == 'ACTIVE' ? 'Ativo' : 'Resolvido'}',
                  ),
                  trailing: Text(telemetryRelativeTime(alert.openedAt)),
                ),
              )
              .toList(),
  );
}

String _yesNo(bool? value) => value == null
    ? 'Indisponível'
    : value
    ? 'Sim'
    : 'Não';
String _connection(bool? value) => value == null
    ? 'Indisponível'
    : value
    ? 'Conectado'
    : 'Desconectado';
String _websocket(String? value) => switch (value) {
  'CONNECTED' => 'Conectado',
  'RECONNECTING' => 'Reconectando',
  'DISCONNECTED' => 'Desconectado',
  _ => 'Indisponível',
};
String _friendlySignal(String? value) => switch (value) {
  'EXCELENTE' => 'Excelente',
  'BOM' => 'Bom',
  'MEDIO' => 'Médio',
  'FRACO' => 'Fraco',
  _ => 'Indisponível',
};
String _number(num? value, String suffix) =>
    value == null ? 'Indisponível' : '${value.toStringAsFixed(1)}$suffix';
String _percent(num? value) => _number(value, '%');
String _duration(int? seconds) {
  if (seconds == null) return 'Indisponível';
  final days = seconds ~/ 86400;
  final hours = (seconds % 86400) ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  if (days > 0) return '$days dia(s) ${hours}h';
  if (hours > 0) return '${hours}h ${minutes}min';
  return '${minutes}min';
}

String _bytes(int value) {
  const gb = 1024 * 1024 * 1024;
  const mb = 1024 * 1024;
  if (value >= gb) return '${(value / gb).toStringAsFixed(1)} GB';
  return '${(value / mb).toStringAsFixed(0)} MB';
}

String _bytesPair(int? used, int? total, double? percent) =>
    used == null || total == null
    ? 'Indisponível'
    : '${_bytes(used)} / ${_bytes(total)}${percent == null ? '' : ' • ${percent.toStringAsFixed(0)}%'}';
