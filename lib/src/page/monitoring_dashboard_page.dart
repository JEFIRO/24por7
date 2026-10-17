import 'dart:async';

import 'package:flutter/material.dart';

import '../model/terminal_telemetry.dart';
import '../model/terminal_telemetry_repository.dart';
import 'terminal_telemetry_detail_page.dart';

Color telemetryStatusColor(
  BuildContext context,
  TerminalOperationalStatus status,
) => switch (status) {
  TerminalOperationalStatus.saudavel => Colors.green.shade700,
  TerminalOperationalStatus.atencao => Colors.orange.shade800,
  TerminalOperationalStatus.critico => Theme.of(context).colorScheme.error,
  TerminalOperationalStatus.offline => Colors.grey.shade700,
};

String telemetryRelativeTime(DateTime? value) {
  if (value == null) return 'sem sinal';
  final elapsed = DateTime.now().difference(value);
  if (elapsed.isNegative || elapsed.inSeconds < 5) return 'agora';
  if (elapsed.inSeconds < 60) return 'há ${elapsed.inSeconds}s';
  if (elapsed.inMinutes < 60) return 'há ${elapsed.inMinutes}min';
  if (elapsed.inHours < 24) return 'há ${elapsed.inHours}h';
  return 'há ${elapsed.inDays}d';
}

class MonitoringDashboardPage extends StatefulWidget {
  const MonitoringDashboardPage({super.key, this.repository});
  final TerminalTelemetryRepository? repository;

  @override
  State<MonitoringDashboardPage> createState() =>
      _MonitoringDashboardPageState();
}

class _MonitoringDashboardPageState extends State<MonitoringDashboardPage> {
  late final TerminalTelemetryRepository _repository =
      widget.repository ?? TerminalTelemetryRepository();
  MonitoringDashboard? _dashboard;
  Timer? _polling;
  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  TerminalOperationalStatus? _status;
  String? _condominioId;
  final Map<String, String> _condominios = {};

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
    if (_refreshing) {
      return;
    }
    _refreshing = true;
    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final result = await _repository.dashboard(
        condominioId: _condominioId,
        status: _status,
      );
      if (!mounted) return;
      setState(() {
        _dashboard = result;
        for (final item in result.terminals) {
          _condominios[item.condominioId] = item.condominioNome;
        }
        _error = null;
      });
    } catch (error) {
      if (mounted && (!silent || _dashboard == null)) {
        setState(() => _error = error.toString());
      }
    } finally {
      _refreshing = false;
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Monitoramento'),
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: _refreshing ? null : _load,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_dashboard case final dashboard?) _Summary(dashboard: dashboard),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<TerminalOperationalStatus?>(
                  initialValue: _status,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todos')),
                    ...TerminalOperationalStatus.values.map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(value.label),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    _status = value;
                    _load();
                  },
                ),
              ),
              SizedBox(
                width: 280,
                child: DropdownButtonFormField<String?>(
                  initialValue: _condominioId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Condomínio'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Todos os condomínios'),
                    ),
                    ..._condominios.entries.map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    _condominioId = value;
                    _load();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_loading && _dashboard == null)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null && _dashboard == null)
            _DashboardState(
              icon: Icons.cloud_off,
              title: 'Não foi possível carregar os Terminais',
              message: _error!,
              onRetry: _load,
            )
          else if (_dashboard?.terminals.isEmpty ?? true)
            _DashboardState(
              icon: Icons.monitor_heart_outlined,
              title: 'Nenhum Terminal encontrado',
              message:
                  'Ajuste os filtros ou aguarde o cadastro dos equipamentos.',
              onRetry: _load,
            )
          else
            ..._dashboard!.terminals.map(
              (terminal) => _TerminalCard(
                terminal: terminal,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TerminalTelemetryDetailPage(
                      terminalId: terminal.terminalId,
                      repository: _repository,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _Summary extends StatelessWidget {
  const _Summary({required this.dashboard});
  final MonitoringDashboard dashboard;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: [
      _SummaryItem(
        label: 'Terminais',
        value: dashboard.total,
        color: Theme.of(context).colorScheme.primary,
      ),
      _SummaryItem(
        label: 'Online',
        value: dashboard.online,
        color: Colors.blue.shade700,
      ),
      _SummaryItem(
        label: 'Saudáveis',
        value: dashboard.saudaveis,
        color: Colors.green.shade700,
      ),
      _SummaryItem(
        label: 'Atenção',
        value: dashboard.atencao,
        color: Colors.orange.shade800,
      ),
      _SummaryItem(
        label: 'Críticos',
        value: dashboard.criticos,
        color: Theme.of(context).colorScheme.error,
      ),
      _SummaryItem(
        label: 'Offline',
        value: dashboard.offline,
        color: Colors.grey.shade700,
      ),
    ],
  );
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final int value;
  final Color color;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 145,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(label),
          ],
        ),
      ),
    ),
  );
}

class _TerminalCard extends StatelessWidget {
  const _TerminalCard({required this.terminal, required this.onTap});
  final TerminalTelemetry terminal;
  final VoidCallback onTap;

  String metric(num? value, {String suffix = '%'}) =>
      value == null ? 'Indisponível' : '${value.toStringAsFixed(0)}$suffix';

  @override
  Widget build(BuildContext context) {
    final color = telemetryStatusColor(context, terminal.status);
    final system = terminal.system;
    final reasons = terminal.reasons
        .where((item) => item != 'Telemetria ainda não recebida')
        .toList();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    terminal.online ? Icons.circle : Icons.circle_outlined,
                    size: 14,
                    color: color,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          terminal.terminalNome,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(terminal.condominioNome),
                      ],
                    ),
                  ),
                  Chip(
                    avatar: Icon(
                      terminal.status == TerminalOperationalStatus.critico
                          ? Icons.error
                          : terminal.status == TerminalOperationalStatus.atencao
                          ? Icons.warning_amber
                          : Icons.monitor_heart,
                      color: color,
                      size: 18,
                    ),
                    label: Text(terminal.status.label),
                  ),
                ],
              ),
              if (reasons.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  reasons.join(' • '),
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: 14),
              Wrap(
                spacing: 20,
                runSpacing: 8,
                children: [
                  _Metric(label: 'CPU', value: metric(system?.cpuUsagePercent)),
                  _Metric(
                    label: 'Temperatura',
                    value: metric(system?.cpuTemperatureCelsius, suffix: '°C'),
                  ),
                  _Metric(
                    label: 'RAM',
                    value: metric(system?.memoryUsagePercent),
                  ),
                  _Metric(
                    label: 'Disco',
                    value: metric(system?.diskUsagePercent),
                  ),
                  _Metric(
                    label: 'Wi-Fi',
                    value: switch (terminal.network?.wifiSignalQuality) {
                      'EXCELENTE' => 'Excelente',
                      'BOM' => 'Bom',
                      'MEDIO' => 'Médio',
                      'FRACO' => 'Fraco',
                      _ => 'Indisponível',
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Último sinal: ${telemetryRelativeTime(terminal.lastHeartbeatAt)}',
                    ),
                  ),
                  TextButton(
                    onPressed: onTap,
                    child: const Text('VER DETALHES'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 115,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

class _DashboardState extends StatelessWidget {
  const _DashboardState({
    required this.icon,
    required this.title,
    required this.message,
    required this.onRetry,
  });
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 52),
    child: Column(
      children: [
        Icon(icon, size: 52, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 12),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 18),
        OutlinedButton(
          onPressed: onRetry,
          child: const Text('TENTAR NOVAMENTE'),
        ),
      ],
    ),
  );
}
