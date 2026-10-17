import 'package:flutter/material.dart';

import '../../core/formatters/app_formatters.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_content.dart';
import '../../core/widgets/async_state.dart';
import '../../core/widgets/status_badge.dart';
import '../model/admin_history.dart';
import '../model/admin_repository.dart';

class SalesHistoryPage extends StatelessWidget {
  const SalesHistoryPage({super.key, this.repository});
  final AdminRepository? repository;

  @override
  Widget build(BuildContext context) {
    final source = repository ?? AdminRepository();
    return _AdminHistoryPage<AdminSale>(
      title: 'Histórico de vendas',
      subtitle: 'Vendas processadas e faturamento por período.',
      filterLabel: 'Período',
      initialFilter: 'TODAY',
      filters: const {
        'TODAY': 'Hoje',
        '7D': 'Últimos 7 dias',
        '30D': 'Últimos 30 dias',
      },
      fetch: (page, filter) => source.sales(page: page, period: filter),
      itemBuilder: (context, sale) => ListTile(
        leading: const CircleAvatar(child: Icon(Icons.receipt_long_outlined)),
        title: Text(AppFormatters.currencyText(sale.total.persistence)),
        subtitle: Text(
          '${sale.condominioNome} • ${sale.terminalNome}\n'
          '${AppFormatters.dateTime(sale.pagaEm ?? sale.criadaEm)}',
        ),
        isThreeLine: true,
        trailing: AppStatusBadge(
          label: sale.status,
          tone: sale.status == 'PROCESSED'
              ? AppStatusTone.success
              : AppStatusTone.neutral,
        ),
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
      subtitle:
          'Tentativas de pagamento paginadas, sem expor eventos técnicos crus.',
      filterLabel: 'Status',
      initialFilter: '',
      filters: const {
        '': 'Todos',
        'PENDING': 'Pendente',
        'ACTION_REQUIRED': 'Ação necessária',
        'FAILED': 'Falhou',
        'PROCESSED': 'Processado',
      },
      fetch: (page, filter) =>
          source.payments(page: page, status: filter.isEmpty ? null : filter),
      itemBuilder: (context, payment) => ListTile(
        leading: const CircleAvatar(child: Icon(Icons.payments_outlined)),
        title: Text(AppFormatters.currencyText(payment.valor.persistence)),
        subtitle: Text(
          '${payment.terminalNome} • ${payment.provider}\n'
          '${AppFormatters.dateTime(payment.atualizadaEm)}',
        ),
        isThreeLine: true,
        trailing: AppStatusBadge(
          label: payment.status,
          tone: _paymentTone(payment.status),
        ),
      ),
    );
  }

  static AppStatusTone _paymentTone(String status) => switch (status) {
    'PROCESSED' => AppStatusTone.success,
    'FAILED' || 'ACTION_REQUIRED' => AppStatusTone.critical,
    'PENDING' => AppStatusTone.warning,
    _ => AppStatusTone.neutral,
  };
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
      filterLabel: 'Situação',
      initialFilter: 'ACTIVE',
      filters: const {
        'ACTIVE': 'Ativos',
        'RESOLVED': 'Resolvidos',
        '': 'Todos',
      },
      fetch: (page, filter) =>
          source.alerts(page: page, status: filter.isEmpty ? null : filter),
      itemBuilder: (context, alert) => ListTile(
        leading: CircleAvatar(
          child: Icon(
            alert.severidade == 'CRITICAL'
                ? Icons.error_outline
                : Icons.warning_amber_outlined,
          ),
        ),
        title: Text(alert.terminalNome),
        subtitle: Text(
          '${alert.condominioNome} • ${alert.mensagem}\n'
          '${AppFormatters.dateTime(alert.ultimaOcorrenciaEm)}',
        ),
        isThreeLine: true,
        trailing: AppStatusBadge(
          label: alert.severidade == 'CRITICAL' ? 'Crítico' : 'Atenção',
          tone: alert.severidade == 'CRITICAL'
              ? AppStatusTone.critical
              : AppStatusTone.warning,
        ),
      ),
    );
  }
}

typedef _Fetcher<T> = Future<AdminPage<T>> Function(int page, String filter);
typedef _ItemBuilder<T> = Widget Function(BuildContext context, T item);

class _AdminHistoryPage<T> extends StatefulWidget {
  const _AdminHistoryPage({
    required this.title,
    required this.subtitle,
    required this.filterLabel,
    required this.initialFilter,
    required this.filters,
    required this.fetch,
    required this.itemBuilder,
  });
  final String title;
  final String subtitle;
  final String filterLabel;
  final String initialFilter;
  final Map<String, String> filters;
  final _Fetcher<T> fetch;
  final _ItemBuilder<T> itemBuilder;

  @override
  State<_AdminHistoryPage<T>> createState() => _AdminHistoryPageState<T>();
}

class _AdminHistoryPageState<T> extends State<_AdminHistoryPage<T>> {
  late String _filter = widget.initialFilter;
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
      final result = await widget.fetch(page, _filter);
      if (mounted) setState(() => _data = result);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    body: _loading && _data == null
        ? const AppLoadingState()
        : _error != null && _data == null
        ? AppErrorState(message: _error!, onRetry: () => _load(0))
        : RefreshIndicator(
            onRefresh: () => _load(_data?.page ?? 0),
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
                        actions: [
                          SizedBox(
                            width: 210,
                            child: DropdownButtonFormField<String>(
                              initialValue: _filter,
                              decoration: InputDecoration(
                                labelText: widget.filterLabel,
                              ),
                              items: widget.filters.entries
                                  .map(
                                    (entry) => DropdownMenuItem(
                                      value: entry.key,
                                      child: Text(entry.value),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _loading
                                  ? null
                                  : (value) {
                                      _filter = value ?? widget.initialFilter;
                                      _load(0);
                                    },
                            ),
                          ),
                          IconButton(
                            tooltip: 'Atualizar',
                            onPressed: _loading
                                ? null
                                : () => _load(_data?.page ?? 0),
                            icon: const Icon(Icons.refresh),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      if (_data!.items.isEmpty)
                        const Card(
                          child: ListTile(
                            leading: Icon(Icons.search_off_outlined),
                            title: Text(
                              'Nenhum registro no filtro selecionado',
                            ),
                          ),
                        )
                      else
                        Card(
                          child: Column(
                            children: [
                              for (
                                var index = 0;
                                index < _data!.items.length;
                                index++
                              ) ...[
                                widget.itemBuilder(
                                  context,
                                  _data!.items[index],
                                ),
                                if (index != _data!.items.length - 1)
                                  const Divider(height: 1, indent: 72),
                              ],
                            ],
                          ),
                        ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('${_data!.totalElements} registros'),
                          const SizedBox(width: AppSpacing.lg),
                          IconButton(
                            tooltip: 'Página anterior',
                            onPressed: _loading || _data!.page == 0
                                ? null
                                : () => _load(_data!.page - 1),
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Text(
                            '${_data!.page + 1} / ${_data!.totalPages == 0 ? 1 : _data!.totalPages}',
                          ),
                          IconButton(
                            tooltip: 'Próxima página',
                            onPressed:
                                _loading || _data!.page + 1 >= _data!.totalPages
                                ? null
                                : () => _load(_data!.page + 1),
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
  );
}
