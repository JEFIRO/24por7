import 'package:flutter/material.dart';

import '../../core/widgets/app_refresh.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/formatters/app_formatters.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_content.dart';
import '../../core/widgets/async_state.dart';
import '../../core/widgets/status_badge.dart';
import '../model/inventario.dart';
import '../model/inventario_repository.dart';
import 'inventario_detail_page.dart';

/// Lista de inventários. É uma aba da tela de Estoque.
class InventarioListPage extends StatefulWidget {
  const InventarioListPage({super.key, this.repository, this.header});
  final InventarioRepository? repository;
  final Widget? header;

  @override
  State<InventarioListPage> createState() => _InventarioListPageState();
}

class _InventarioListPageState extends State<InventarioListPage> {
  late final InventarioRepository _repository;
  List<Inventario> _itens = const [];
  bool _loading = true;
  String? _error;
  String? _status;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? InventarioRepository();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _repository.listar(status: _status);
      if (mounted) setState(() => _itens = data);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _novo() async {
    if (await iniciarInventario(context, _repository) && mounted) {
      await _carregar();
    }
  }

  Future<void> _open(Inventario item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InventarioDetailPage(
          inventarioId: item.id,
          repository: _repository,
        ),
      ),
    );
    _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final mobile = AppBreakpoints.isMobile(context);
    return AppRefreshIndicator(
      onRefresh: _carregar,
      child: ListView(
        children: [
          AppContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ?widget.header,
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final (value, label) in const [
                      (null, 'Todos'),
                      ('EM_CONTAGEM', 'Em contagem'),
                      ('COM_CONFLITO', 'Com conflito'),
                      ('FINALIZADO', 'Finalizados'),
                      ('CANCELADO', 'Cancelados'),
                    ])
                      ChoiceChip(
                        label: Text(label),
                        selected: _status == value,
                        onSelected: (_) {
                          _status = value;
                          _carregar();
                        },
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                if (_loading)
                  const AppLoadingState(
                    label: 'Carregando inventários…',
                    inline: true,
                  )
                else if (_error != null)
                  AppErrorState(message: _error!, onRetry: _carregar)
                else if (_itens.isEmpty)
                  AppEmptyState(
                    icon: Icons.fact_check_outlined,
                    title: 'Nenhum inventário encontrado',
                    message:
                        'Inicie uma contagem física para comparar com o saldo do sistema.',
                    action: FilledButton(
                      onPressed: _novo,
                      child: const Text('Novo inventário'),
                    ),
                  )
                else if (mobile)
                  for (final (i, item) in _itens.indexed)
                    AppListRow(
                      entranceIndex: i,
                      title: item.descricao ?? item.localNome,
                      meta:
                          '${item.contados} de ${item.totalProdutos} contados · '
                          '${item.divergencias == 1 ? '1 divergência' : '${item.divergencias} divergências'}',
                      trailing: inventoryStatusBadge(item.status),
                      onTap: () => _open(item),
                    )
                else
                  _table(),
                const SizedBox(height: 88),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _table() {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return AppTable(
      columns: const [
        DataColumn(label: Text('Inventário')),
        DataColumn(label: Text('Local')),
        DataColumn(label: Text('Modo')),
        DataColumn(label: Text('Progresso')),
        DataColumn(label: Text('Divergências'), numeric: true),
        DataColumn(label: Text('Status')),
      ],
      rows: [
        for (final item in _itens)
          DataRow(
            onSelectChanged: (_) => _open(item),
            cells: [
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.descricao ?? 'Inventário',
                      style: theme.textTheme.titleSmall,
                    ),
                    if (item.createdAt != null)
                      Text(
                        AppFormatters.dateTime(item.createdAt),
                        style: muted,
                      ),
                  ],
                ),
              ),
              DataCell(Text(item.localNome)),
              DataCell(Text(item.contagemCega ? 'Contagem cega' : 'Aberta')),
              DataCell(
                SizedBox(
                  width: 140,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.contados} de ${item.totalProdutos}',
                        style: tabularFigures,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      AppProgressBar(
                        value: item.totalProdutos == 0
                            ? 0
                            : item.contados / item.totalProdutos,
                      ),
                    ],
                  ),
                ),
              ),
              DataCell(Text('${item.divergencias}', style: tabularFigures)),
              DataCell(inventoryStatusBadge(item.status)),
            ],
          ),
      ],
    );
  }
}

/// Pergunta como contar, inicia o inventário do estoque central e abre a
/// contagem. Devolve true quando um inventário foi criado.
Future<bool> iniciarInventario(
  BuildContext context,
  InventarioRepository repository,
) async {
  bool cega = false;
  final descricao = TextEditingController();
  final criar = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setLocal) => AlertDialog(
        title: const Text('Novo inventário'),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Local',
                  prefixIcon: Icon(Icons.warehouse_outlined),
                  enabled: false,
                ),
                child: Text('Estoque central'),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: descricao,
                decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: cega,
                title: const Text('Contagem cega'),
                subtitle: const Text(
                  'Oculta o saldo esperado durante a contagem',
                ),
                onChanged: (value) => setLocal(() => cega = value),
              ),
              const SizedBox(height: AppSpacing.sm),
              const AppBanner(
                tone: AppStatusTone.info,
                message: 'O saldo atual será congelado como referência.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Iniciar'),
          ),
        ],
      ),
    ),
  );
  if (criar != true || !context.mounted) return false;
  try {
    final inventario = await repository.iniciar(
      contagemCega: cega,
      descricao: descricao.text.trim().isEmpty ? null : descricao.text.trim(),
    );
    if (!context.mounted) return true;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InventarioDetailPage(
          inventarioId: inventario.id,
          repository: repository,
        ),
      ),
    );
    return true;
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
    return false;
  }
}

AppStatusBadge inventoryStatusBadge(String status) => switch (status) {
  'EM_CONTAGEM' => const AppStatusBadge(
    label: 'Em contagem',
    tone: AppStatusTone.info,
  ),
  'COM_CONFLITO' => const AppStatusBadge(
    label: 'Com conflito',
    tone: AppStatusTone.critical,
  ),
  'FINALIZADO' => const AppStatusBadge(
    label: 'Finalizado',
    tone: AppStatusTone.success,
  ),
  'CANCELADO' => const AppStatusBadge(label: 'Cancelado'),
  _ => AppStatusBadge(label: status.replaceAll('_', ' ').toLowerCase()),
};
