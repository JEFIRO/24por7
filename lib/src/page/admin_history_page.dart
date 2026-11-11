import 'package:flutter/material.dart';

import '../../core/formatters/app_formatters.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_content.dart';
import '../../core/widgets/async_state.dart';
import '../../core/widgets/status_badge.dart';
import '../model/admin_history.dart';
import '../model/admin_repository.dart';
import 'admin_sale_detail_page.dart';

const _processingLabels = {
  'PROCESSED': 'Processado',
  'PENDING': 'Pendente',
  'ACTION_REQUIRED': 'Ação necessária',
  'FAILED': 'Falhou',
};

AppStatusBadge _processingBadge(String status) => AppStatusBadge(
  label: _processingLabels[status] ?? status,
  tone: switch (status) {
    'PROCESSED' => AppStatusTone.success,
    'PENDING' => AppStatusTone.warning,
    'ACTION_REQUIRED' => AppStatusTone.info,
    'FAILED' => AppStatusTone.critical,
    _ => AppStatusTone.neutral,
  },
);

class SalesHistoryPage extends StatelessWidget {
  const SalesHistoryPage({super.key, this.repository});
  final AdminRepository? repository;

  @override
  Widget build(BuildContext context) {
    final source = repository ?? AdminRepository();
    return _AdminHistoryPage<AdminSale>(
      title: 'Histórico de vendas',
      subtitle: 'Vendas aprovadas e reembolsadas por período.',
      initialFilter: 'TODAY',
      filters: const {
        'TODAY': 'Hoje',
        '7D': 'Últimos 7 dias',
        '30D': 'Últimos 30 dias',
      },
      secondaryInitialFilter: 'PROCESSED',
      secondaryFilters: const {
        'PROCESSED': 'Aprovadas',
        'REFUNDED': 'Reembolsadas',
      },
      fetch: (page, filter, status) =>
          source.sales(page: page, period: filter, status: status),
      onTap: (context, sale) => Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) =>
              AdminSaleDetailPage(orderId: sale.id, repository: source),
        ),
      ),
      columns: const [
        _Column('Venda'),
        _Column('Data e hora'),
        _Column('Condomínio'),
        _Column('Terminal'),
        _Column('Total', numeric: true),
        _Column('Status'),
      ],
      cells: (sale) => [
        Text(shortSaleId(sale.id), style: tabularFigures),
        Text(
          AppFormatters.dateTime(sale.pagaEm ?? sale.criadaEm),
          style: tabularFigures,
        ),
        Text(sale.condominioNome),
        Text(sale.terminalNome),
        Text(
          AppFormatters.currencyText(sale.total.persistence),
          style: tabularFigures.copyWith(fontWeight: FontWeight.w600),
        ),
        saleStatusBadge(sale.status),
      ],
      row: (sale) => (
        title: AppFormatters.currencyText(sale.total.persistence),
        meta:
            '${sale.condominioNome} · ${sale.terminalNome}\n'
            '${shortSaleId(sale.id)} · '
            '${AppFormatters.dateTime(sale.pagaEm ?? sale.criadaEm)}',
        trailing: saleStatusBadge(sale.status),
      ),
    );
  }
}

class PaymentHistoryPage extends StatelessWidget {
  const PaymentHistoryPage({super.key, this.repository});
  final AdminRepository? repository;

  @override
  Widget build(BuildContext context) {
    final source = repository ?? AdminRepository();
    return _AdminHistoryPage<AdminPayment>(
      title: 'Histórico de pagamentos',
      subtitle: 'Tentativas de pagamento por pedido.',
      initialFilter: '',
      filters: const {
        '': 'Todos',
        'PENDING': 'Pendente',
        'ACTION_REQUIRED': 'Ação necessária',
        'FAILED': 'Falhou',
        'PROCESSED': 'Processado',
      },
      fetch: (page, filter, _) =>
          source.payments(page: page, status: filter.isEmpty ? null : filter),
      columns: const [
        _Column('Atualizado em'),
        _Column('Pedido'),
        _Column('Terminal'),
        _Column('Provedor'),
        _Column('Valor', numeric: true),
        _Column('Status'),
      ],
      cells: (payment) => [
        Text(
          AppFormatters.dateTime(payment.atualizadaEm),
          style: tabularFigures,
        ),
        Text(_shortId(payment.orderId), style: tabularFigures),
        Text(payment.terminalNome),
        Text(payment.provider),
        Text(
          AppFormatters.currencyText(payment.valor.persistence),
          style: tabularFigures.copyWith(fontWeight: FontWeight.w600),
        ),
        _processingBadge(payment.status),
      ],
      row: (payment) => (
        title: AppFormatters.currencyText(payment.valor.persistence),
        meta:
            '${payment.terminalNome} · ${payment.provider}\n'
            '${AppFormatters.dateTime(payment.atualizadaEm)}',
        trailing: _processingBadge(payment.status),
      ),
    );
  }

  static String _shortId(String id) =>
      id.length > 8 ? '#${id.substring(0, 8)}' : '#$id';
}

class AdminAlertsPage extends StatelessWidget {
  const AdminAlertsPage({super.key, this.repository});
  final AdminRepository? repository;

  @override
  Widget build(BuildContext context) {
    final source = repository ?? AdminRepository();
    return _AdminHistoryPage<AdminAlert>(
      title: 'Alertas operacionais',
      subtitle: 'Alertas dos Terminais calculados pelo backend.',
      initialFilter: 'ACTIVE',
      filters: const {
        'ACTIVE': 'Ativos',
        'RESOLVED': 'Resolvidos',
        '': 'Todos',
      },
      fetch: (page, filter, _) =>
          source.alerts(page: page, status: filter.isEmpty ? null : filter),
      row: (alert) {
        final resolved = alert.status == 'RESOLVED';
        return (
          title: '${alert.terminalNome} · ${_type(alert.tipo)}',
          meta:
              '${alert.mensagem}\n${alert.condominioNome} · '
              '${AppFormatters.dateTime(alert.ultimaOcorrenciaEm)}',
          trailing: resolved
              ? const AppStatusBadge(label: 'Resolvido')
              : AppStatusBadge(
                  label: alert.severidade == 'CRITICAL' ? 'Crítico' : 'Atenção',
                  tone: alert.severidade == 'CRITICAL'
                      ? AppStatusTone.critical
                      : AppStatusTone.warning,
                ),
        );
      },
      leading: (alert) => AppIconWell(
        alert.severidade == 'CRITICAL'
            ? Icons.error_outline
            : Icons.warning_amber_outlined,
        color: alert.status == 'RESOLVED'
            ? Theme.of(context).colorScheme.onSurfaceVariant
            : appToneColors(
                context,
                alert.severidade == 'CRITICAL'
                    ? AppStatusTone.critical
                    : AppStatusTone.warning,
              ).$2,
      ),
      muted: (alert) => alert.status == 'RESOLVED',
    );
  }

  static String _type(String tipo) {
    final words = tipo.replaceAll('_', ' ').toLowerCase();
    return words.isEmpty
        ? words
        : '${words[0].toUpperCase()}${words.substring(1)}';
  }
}

typedef _Fetcher<T> =
    Future<AdminPage<T>> Function(int page, String filter, String? secondary);
typedef _OnTap<T> = Future<bool?> Function(BuildContext context, T item);
typedef _RowSpec = ({String title, String meta, Widget trailing});

class _Column {
  const _Column(this.label, {this.numeric = false});
  final String label;
  final bool numeric;
}

class _AdminHistoryPage<T> extends StatefulWidget {
  const _AdminHistoryPage({
    required this.title,
    required this.subtitle,
    required this.initialFilter,
    required this.filters,
    required this.fetch,
    required this.row,
    this.columns,
    this.cells,
    this.leading,
    this.muted,
    this.onTap,
    this.secondaryFilters,
    this.secondaryInitialFilter,
  });
  final String title;
  final String subtitle;
  final String initialFilter;
  final Map<String, String> filters;
  final _Fetcher<T> fetch;

  /// Linha usada no celular e quando a página não tem tabela.
  final _RowSpec Function(T item) row;
  final List<_Column>? columns;
  final List<Widget> Function(T item)? cells;
  final Widget Function(T item)? leading;
  final bool Function(T item)? muted;

  /// Abre o detalhe do item; `true` no retorno recarrega a página atual.
  final _OnTap<T>? onTap;

  /// Segunda fileira de filtros (ex.: status), combinada com [filters].
  final Map<String, String>? secondaryFilters;
  final String? secondaryInitialFilter;

  @override
  State<_AdminHistoryPage<T>> createState() => _AdminHistoryPageState<T>();
}

class _AdminHistoryPageState<T> extends State<_AdminHistoryPage<T>> {
  late String _filter = widget.initialFilter;
  late String? _secondary = widget.secondaryInitialFilter;
  AdminPage<T>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load(0);
  }

  Future<void> _load(int page) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.fetch(page, _filter, _secondary);
      if (mounted) setState(() => _data = result);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(T item) async {
    final changed = await widget.onTap!(context, item);
    if (changed == true && mounted) _load(_data?.page ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mobile = AppBreakpoints.isMobile(context);
    final data = _data;
    final useTable = !mobile && widget.columns != null && widget.cells != null;
    return RefreshIndicator(
      onRefresh: () => _load(data?.page ?? 0),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          AppContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppPageHeader(
                  title: widget.title,
                  subtitle: widget.subtitle,
                  onRefresh: () => _load(data?.page ?? 0),
                  refreshing: _loading,
                ),
                const SizedBox(height: AppSpacing.xl),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final entry in widget.filters.entries)
                      ChoiceChip(
                        label: Text(entry.value),
                        selected: _filter == entry.key,
                        onSelected: _loading
                            ? null
                            : (_) {
                                setState(() => _filter = entry.key);
                                _load(0);
                              },
                      ),
                  ],
                ),
                if (widget.secondaryFilters != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final entry in widget.secondaryFilters!.entries)
                        ChoiceChip(
                          label: Text(entry.value),
                          selected: _secondary == entry.key,
                          onSelected: _loading
                              ? null
                              : (_) {
                                  setState(() => _secondary = entry.key);
                                  _load(0);
                                },
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                if (_loading && data == null)
                  const AppLoadingState()
                else if (_error != null && data == null)
                  AppErrorState(message: _error!, onRetry: () => _load(0))
                else ...[
                  if (_error != null)
                    AppBanner(tone: AppStatusTone.critical, message: _error!),
                  if (_loading) const LinearProgressIndicator(minHeight: 2),
                  if (data!.items.isEmpty)
                    const AppEmptyState(
                      icon: Icons.search_off_outlined,
                      title: 'Nenhum registro no filtro selecionado',
                      message: 'Escolha outro período ou situação.',
                    )
                  else if (useTable)
                    AppTable(
                      columns: [
                        for (final column in widget.columns!)
                          DataColumn(
                            label: Text(column.label),
                            numeric: column.numeric,
                          ),
                      ],
                      rows: [
                        for (final item in data.items)
                          DataRow(
                            onSelectChanged: widget.onTap == null
                                ? null
                                : (_) => _open(item),
                            cells: [
                              for (final cell in widget.cells!(item))
                                DataCell(cell),
                            ],
                          ),
                      ],
                    )
                  else
                    for (final item in data.items)
                      Builder(
                        builder: (context) {
                          final spec = widget.row(item);
                          return AppListRow(
                            title: spec.title,
                            meta: spec.meta,
                            metaMaxLines: 4,
                            trailingOnTitle: true,
                            leading: widget.leading?.call(item),
                            trailing: spec.trailing,
                            muted: widget.muted?.call(item) ?? false,
                            onTap: widget.onTap == null
                                ? null
                                : () => _open(item),
                          );
                        },
                      ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        data.totalElements == 1
                            ? '1 registro'
                            : '${data.totalElements} registros',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      IconButton(
                        tooltip: 'Página anterior',
                        onPressed: _loading || data.page == 0
                            ? null
                            : () => _load(data.page - 1),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text(
                        '${data.page + 1} de ${data.totalPages == 0 ? 1 : data.totalPages}',
                        style: tabularFigures,
                      ),
                      IconButton(
                        tooltip: 'Próxima página',
                        onPressed: _loading || data.page + 1 >= data.totalPages
                            ? null
                            : () => _load(data.page + 1),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
