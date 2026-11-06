import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_content.dart';
import '../../core/widgets/async_state.dart';
import '../../core/widgets/status_badge.dart';
import '../model/terminal_telemetry.dart';
import '../model/terminal_telemetry_repository.dart';
import 'terminal_telemetry_detail_page.dart';

AppStatusTone telemetryStatusTone(TerminalOperationalStatus status) =>
    switch (status) {
      TerminalOperationalStatus.saudavel => AppStatusTone.success,
      TerminalOperationalStatus.atencao => AppStatusTone.warning,
      TerminalOperationalStatus.critico => AppStatusTone.critical,
      TerminalOperationalStatus.offline => AppStatusTone.neutral,
    };

/// Cor de texto acessível do status (a mesma do badge).
Color telemetryStatusColor(
  BuildContext context,
  TerminalOperationalStatus status,
) => appToneColors(context, telemetryStatusTone(status)).$2;

String telemetryWifiLabel(String? quality) => switch (quality) {
  'EXCELENTE' => 'Excelente',
  'BOM' => 'Bom',
  'MEDIO' => 'Médio',
  'FRACO' => 'Fraco',
  _ => 'Indisponível',
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

  void _open(TerminalTelemetry terminal) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => TerminalTelemetryDetailPage(
        terminalId: terminal.terminalId,
        repository: _repository,
      ),
    ),
  );

  static int _severity(TerminalOperationalStatus status) => switch (status) {
    TerminalOperationalStatus.critico => 0,
    TerminalOperationalStatus.atencao => 1,
    TerminalOperationalStatus.offline => 2,
    TerminalOperationalStatus.saudavel => 3,
  };

  @override
  Widget build(BuildContext context) {
    final dashboard = _dashboard;
    final terminals = [...?dashboard?.terminals]
      ..sort((a, b) => _severity(a.status).compareTo(_severity(b.status)));
    final mobile = AppBreakpoints.isMobile(context);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        children: [
          AppContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppPageHeader(
                  title: 'Monitoramento',
                  subtitle: dashboard == null
                      ? 'Saúde dos Terminais, atualizada a cada 20 s.'
                      : '${dashboard.total} Terminais · '
                            '${dashboard.online} online · atualizado a cada 20 s',
                  onRefresh: _load,
                  refreshing: _refreshing,
                ),
                const SizedBox(height: AppSpacing.xl),
                if (dashboard != null) ...[
                  _Summary(dashboard: dashboard),
                  const SizedBox(height: AppSpacing.lg),
                ],
                Wrap(
                  spacing: AppSpacing.xl,
                  runSpacing: AppSpacing.md,
                  children: [
                    SizedBox(
                      width: mobile ? double.infinity : 280,
                      child: DropdownButtonFormField<String?>(
                        initialValue: _condominioId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Condomínio',
                        ),
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
                    SizedBox(
                      width: mobile ? double.infinity : 200,
                      child:
                          DropdownButtonFormField<TerminalOperationalStatus?>(
                            initialValue: _status,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('Todos'),
                              ),
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
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                if (_loading && dashboard == null)
                  const AppLoadingState(label: 'Carregando Terminais…')
                else if (_error != null && dashboard == null)
                  AppErrorState(
                    title: 'Não foi possível carregar os Terminais',
                    message: _error!,
                    onRetry: _load,
                  )
                else if (terminals.isEmpty)
                  AppEmptyState(
                    icon: Icons.monitor_heart_outlined,
                    title: 'Nenhum Terminal encontrado',
                    message:
                        'Ajuste os filtros ou aguarde o cadastro dos equipamentos.',
                    action: OutlinedButton(
                      onPressed: _load,
                      child: const Text('Tentar novamente'),
                    ),
                  )
                else if (mobile)
                  for (final terminal in terminals)
                    _TerminalRow(
                      terminal: terminal,
                      onTap: () => _open(terminal),
                    )
                else
                  _TerminalTable(terminals: terminals, onOpen: _open),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.dashboard});
  final MonitoringDashboard dashboard;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.xl,
    runSpacing: AppSpacing.sm,
    children: [
      AppStatusDot(
        label: '${dashboard.saudaveis} saudáveis',
        tone: AppStatusTone.success,
      ),
      AppStatusDot(
        label: '${dashboard.atencao} em atenção',
        tone: AppStatusTone.warning,
      ),
      AppStatusDot(
        label: '${dashboard.criticos} críticos',
        tone: AppStatusTone.critical,
      ),
      AppStatusDot(
        label: '${dashboard.offline} offline',
        tone: AppStatusTone.neutral,
      ),
    ],
  );
}

String _metric(num? value, {String suffix = '%'}) =>
    value == null ? '—' : '${value.toStringAsFixed(0)}$suffix';

List<String> _reasons(TerminalTelemetry terminal) => terminal.reasons
    .where((item) => item != 'Telemetria ainda não recebida')
    .toList();

class _TerminalTable extends StatelessWidget {
  const _TerminalTable({required this.terminals, required this.onOpen});
  final List<TerminalTelemetry> terminals;
  final ValueChanged<TerminalTelemetry> onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    DataCell number(String text) => DataCell(
      Align(
        alignment: Alignment.centerRight,
        child: Text(text, style: tabularFigures),
      ),
    );
    return AppTable(
      columns: const [
        DataColumn(label: Text('Terminal')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('CPU'), numeric: true),
        DataColumn(label: Text('RAM'), numeric: true),
        DataColumn(label: Text('Temperatura'), numeric: true),
        DataColumn(label: Text('Wi-Fi')),
        DataColumn(label: Text('Último sinal')),
        DataColumn(label: SizedBox.shrink()),
      ],
      rows: [
        for (final terminal in terminals)
          DataRow(
            onSelectChanged: (_) => onOpen(terminal),
            cells: [
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      terminal.terminalNome,
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      [
                        terminal.condominioNome,
                        ..._reasons(terminal),
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                  ],
                ),
              ),
              DataCell(
                AppStatusBadge(
                  label: terminal.status.label,
                  tone: telemetryStatusTone(terminal.status),
                ),
              ),
              number(_metric(terminal.system?.cpuUsagePercent)),
              number(_metric(terminal.system?.memoryUsagePercent)),
              number(
                _metric(terminal.system?.cpuTemperatureCelsius, suffix: '°C'),
              ),
              DataCell(
                Text(telemetryWifiLabel(terminal.network?.wifiSignalQuality)),
              ),
              DataCell(
                Text(
                  telemetryRelativeTime(terminal.lastHeartbeatAt),
                  style: TextStyle(color: muted),
                ),
              ),
              DataCell(
                TextButton(
                  onPressed: () => onOpen(terminal),
                  child: const Text('Ver detalhes'),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _TerminalRow extends StatelessWidget {
  const _TerminalRow({required this.terminal, required this.onTap});
  final TerminalTelemetry terminal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final system = terminal.system;
    final reasons = _reasons(terminal);
    return AppListRow(
      title: terminal.terminalNome,
      meta: [
        terminal.condominioNome,
        if (reasons.isNotEmpty)
          reasons.join(' · ')
        else
          'CPU ${_metric(system?.cpuUsagePercent)} · '
              '${_metric(system?.cpuTemperatureCelsius, suffix: '°C')} · '
              'Wi-Fi ${telemetryWifiLabel(terminal.network?.wifiSignalQuality)}',
      ].join('\n'),
      trailing: AppStatusBadge(
        label: terminal.status.label,
        tone: telemetryStatusTone(terminal.status),
      ),
      onTap: onTap,
    );
  }
}
