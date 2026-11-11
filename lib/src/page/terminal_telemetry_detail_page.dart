import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/widgets/app_refresh.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_content.dart';
import '../../core/widgets/async_state.dart';
import '../../core/widgets/status_badge.dart';
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
      title: Text(_terminal?.terminalNome ?? 'Detalhe do Terminal'),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: TextButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Atualizar'),
          ),
        ),
      ],
    ),
    body: _loading && _terminal == null
        ? const AppLoadingState(
            label: 'Carregando telemetria do Terminal…',
            layout: AppSkeletonLayout.dashboard,
          )
        : _error != null && _terminal == null
        ? AppErrorState(
            title: 'Não foi possível carregar o Terminal',
            message: _error!,
            onRetry: _load,
          )
        : AppRefreshIndicator(
            onRefresh: _load,
            child: ListView(
              children: [AppContent(child: _content(context, _terminal!))],
            ),
          ),
  );

  Widget _content(BuildContext context, TerminalTelemetry terminal) {
    final theme = Theme.of(context);
    final system = terminal.system;
    final network = terminal.network;
    final app = terminal.application;
    final display = terminal.display;
    final powerProblem = system?.undervoltageNow == true;
    final reasons = terminal.reasons
        .where((item) => item != 'Telemetria ainda não recebida')
        .toList();

    final health = <Widget>[
      _Section(
        title: 'Sistema',
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
        children: [
          _DataRow(
            'Subtensão agora',
            _yesNo(system?.undervoltageNow),
            alert: system?.undervoltageNow == true,
          ),
          _DataRow(
            'Subtensão registrada',
            _yesNo(system?.undervoltageOccurred),
          ),
          _DataRow(
            'Throttling agora',
            _yesNo(system?.throttledNow),
            alert: system?.throttledNow == true,
          ),
          _DataRow('Throttling registrado', _yesNo(system?.throttledOccurred)),
          _DataRow(
            'Frequência limitada agora',
            _yesNo(system?.frequencyCappedNow),
            alert: system?.frequencyCappedNow == true,
          ),
          _DataRow(
            'Limite térmico agora',
            _yesNo(system?.softTemperatureLimitNow),
            alert: system?.softTemperatureLimitNow == true,
          ),
          _DataRow('Diagnóstico bruto', system?.throttledRaw ?? 'Indisponível'),
        ],
      ),
      _Section(
        title: 'Rede',
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
                : '${network!.wifiSignalPercent}% · ${telemetryWifiLabel(network.wifiSignalQuality)}',
          ),
          _DataRow('IP local', network?.localIp ?? 'Indisponível'),
          _DataRow(
            'Backend',
            _connection(network?.backendReachable),
            alert: network?.backendReachable == false,
          ),
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
        children: [
          _DataRow('Versão', app?.version ?? 'Indisponível'),
          _DataRow('Aplicação rodando', _duration(app?.uptimeSeconds)),
          _DataRow('WebSocket', _websocket(app?.websocketStatus)),
          _DataRow(
            'Último sync',
            telemetryRelativeTime(app?.lastSuccessfulSyncAt),
          ),
          _DataRow(
            'Último erro de sync',
            app?.lastSyncError ?? 'Nenhum',
            alert: app?.lastSyncError != null,
          ),
          _DataRow('Compra ativa', _yesNo(app?.purchaseActive)),
          _DataRow('Pagamento em andamento', _yesNo(app?.paymentInProgress)),
        ],
      ),
      _Section(
        title: 'Display',
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
    ];
    final activity = <Widget>[
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
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AppStatusBadge(
              label: terminal.status.label,
              tone: telemetryStatusTone(terminal.status),
            ),
            Text(
              [
                terminal.condominioNome,
                terminal.online ? 'Online' : 'Offline',
                'último sinal ${telemetryRelativeTime(terminal.lastHeartbeatAt)}',
              ].join(' · '),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        if (reasons.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            reasons.join(' · '),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: telemetryStatusColor(context, terminal.status),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (powerProblem || system?.undervoltageOccurred == true) ...[
          const SizedBox(height: AppSpacing.xl),
          _PowerBanner(
            now: powerProblem,
            occurredText: _yesNo(system?.undervoltageOccurred),
            nowText: _yesNo(system?.undervoltageNow),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 1000) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [...health, ...activity],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: health,
                  ),
                ),
                const SizedBox(width: AppSpacing.section),
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: activity,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PowerBanner extends StatelessWidget {
  const _PowerBanner({
    required this.now,
    required this.nowText,
    required this.occurredText,
  });
  final bool now;
  final String nowText;
  final String occurredText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = now
        ? theme.colorScheme.error
        : appToneColors(context, AppStatusTone.warning).$2;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: color, width: 2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.electrical_services, color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Problema de alimentação',
                  style: theme.textTheme.titleMedium,
                ),
                const Text('Subtensão detectada no Raspberry.'),
                Text(
                  'Ocorrendo agora: $nowText · desde o último boot: $occurredText',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [AppSectionTitle(title), ...children],
    ),
  );
}

class _DataRow extends StatelessWidget {
  const _DataRow(this.label, this.value, {this.alert = false});
  final String label;
  final String value;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: alert ? theme.colorScheme.error : null,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionTitle('Histórico'),
        SegmentedButton<String>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: '1h', label: Text('1 h')),
            ButtonSegment(value: '6h', label: Text('6 h')),
            ButtonSegment(value: '24h', label: Text('24 h')),
            ButtonSegment(value: '7d', label: Text('7 d')),
          ],
          selected: {period},
          onSelectionChanged: (value) => onPeriodChanged(value.first),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (loading)
          const AppLoadingState(label: 'Carregando amostras…', inline: true)
        else if (history.isEmpty)
          const AppEmptyState(
            icon: Icons.show_chart,
            title: 'Sem amostras',
            message: 'Ainda não há amostras neste período.',
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 560 ? 2 : 1;
              final width =
                  (constraints.maxWidth - AppSpacing.xl * (columns - 1)) /
                  columns;
              return Wrap(
                spacing: AppSpacing.xl,
                runSpacing: AppSpacing.lg,
                children: [
                  for (final (title, unit, values, limit) in [
                    (
                      'Temperatura',
                      '°C',
                      history.map((e) => e.cpuTemperatureCelsius).toList(),
                      80.0,
                    ),
                    (
                      'CPU',
                      '%',
                      history.map((e) => e.cpuUsagePercent).toList(),
                      null,
                    ),
                    (
                      'RAM',
                      '%',
                      history.map((e) => e.memoryUsagePercent).toList(),
                      null,
                    ),
                    (
                      'Disco',
                      '%',
                      history.map((e) => e.diskUsagePercent).toList(),
                      null,
                    ),
                    (
                      'Latência',
                      ' ms',
                      history.map((e) => e.backendLatencyMs).toList(),
                      null,
                    ),
                    (
                      'Sinal Wi-Fi',
                      '%',
                      history.map((e) => e.wifiSignalPercent).toList(),
                      null,
                    ),
                  ])
                    SizedBox(
                      width: width,
                      child: _Chart(
                        title: title,
                        unit: unit,
                        values: values,
                        limit: limit,
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    ),
  );
}

class _Chart extends StatelessWidget {
  const _Chart({
    required this.title,
    required this.unit,
    required this.values,
    this.limit,
  });
  final String title;
  final String unit;
  final List<double?> values;
  final double? limit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final available = values.whereType<double>().toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: theme.textTheme.titleSmall)),
            Text(
              available.isEmpty
                  ? '—'
                  : '${available.last.toStringAsFixed(1)}$unit',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 96,
          child: available.isEmpty
              ? Center(
                  child: Text(
                    'Indisponível',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : CustomPaint(
                  key: ValueKey('chart-$title'),
                  painter: _LineChartPainter(
                    values: values,
                    color: theme.colorScheme.primary,
                    grid: theme.colorScheme.outlineVariant,
                    limitColor: theme.colorScheme.error,
                    limit: limit,
                  ),
                  size: const Size(double.infinity, 96),
                ),
        ),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.values,
    required this.color,
    required this.grid,
    required this.limitColor,
    this.limit,
  });
  final List<double?> values;
  final Color color;
  final Color grid;
  final Color limitColor;
  final double? limit;

  @override
  void paint(Canvas canvas, Size size) {
    final points = <({int index, double value})>[];
    for (var index = 0; index < values.length; index++) {
      if (values[index] case final value?) {
        points.add((index: index, value: value));
      }
    }
    if (points.isEmpty) return;
    var minValue = points.map((e) => e.value).reduce(math.min);
    var maxValue = points.map((e) => e.value).reduce(math.max);
    if (limit != null && limit! <= maxValue * 1.25) {
      maxValue = math.max(maxValue, limit!);
      minValue = math.min(minValue, limit!);
    }
    final range = math.max(1.0, maxValue - minValue);
    double yOf(double value) =>
        size.height - ((value - minValue) / range * (size.height - 4)) - 2;

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var row = 0; row <= 3; row++) {
      final y = (size.height - 1) * row / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    if (limit != null && limit! >= minValue && limit! <= maxValue) {
      final y = yOf(limit!);
      final limitPaint = Paint()
        ..color = limitColor
        ..strokeWidth = 1;
      for (var x = 0.0; x < size.width; x += 6) {
        canvas.drawLine(Offset(x, y), Offset(x + 3, y), limitPaint);
      }
    }
    final path = Path();
    for (var position = 0; position < points.length; position++) {
      final point = points[position];
      final x = values.length <= 1
          ? 0.0
          : size.width * point.index / (values.length - 1);
      final y = yOf(point.value);
      if (position == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.color != color ||
      oldDelegate.limit != limit;
}

class _AlertsSection extends StatelessWidget {
  const _AlertsSection({required this.alerts});
  final List<TelemetryAlert> alerts;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const AppSectionTitle('Alertas'),
      if (alerts.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Text(
            'Nenhum alerta registrado.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        )
      else
        for (final alert in alerts)
          AppListRow(
            dense: true,
            muted: alert.status != 'ACTIVE',
            title: alert.message,
            meta:
                '${_alertType(alert.type)} · ${telemetryRelativeTime(alert.openedAt)}',
            trailing: alert.status == 'ACTIVE'
                ? const AppStatusBadge(
                    label: 'Ativo',
                    tone: AppStatusTone.warning,
                  )
                : const AppStatusBadge(label: 'Resolvido'),
          ),
    ],
  );

  static String _alertType(String type) {
    final words = type.replaceAll('_', ' ').toLowerCase();
    return words.isEmpty
        ? words
        : '${words[0].toUpperCase()}${words.substring(1)}';
  }
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
