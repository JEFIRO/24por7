import 'package:flutter/material.dart';

import '../../core/formatters/app_formatters.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_content.dart';
import '../../core/widgets/async_state.dart';
import '../model/estoque.dart';
import '../model/estoque_repository.dart';

class MovimentacaoEstoquePage extends StatefulWidget {
  const MovimentacaoEstoquePage({super.key, this.repository});
  final EstoqueRepository? repository;
  @override
  State<MovimentacaoEstoquePage> createState() =>
      _MovimentacaoEstoquePageState();
}

class _MovimentacaoEstoquePageState extends State<MovimentacaoEstoquePage> {
  late final EstoqueRepository repository;
  late Future<List<MovimentoEstoque>> future;
  String? _type;

  @override
  void initState() {
    super.initState();
    repository = widget.repository ?? EstoqueRepository();
    future = repository.movimentos();
  }

  void reload() => setState(() => future = repository.movimentos());

  static const _filters = <String?, String>{
    null: 'Todas',
    'ENTRADA': 'Entradas',
    'SAIDA': 'Saídas',
    'AJUSTE': 'Ajustes',
    'TRANSFERENCIA': 'Transferências',
  };

  static String _typeLabel(String tipo) => switch (tipo) {
    'ENTRADA' => 'Entrada',
    'SAIDA' => 'Saída',
    'AJUSTE' => 'Ajuste',
    'VENDA' => 'Venda',
    _ when tipo.startsWith('TRANSFERENCIA') => 'Transferência',
    _ => tipo.replaceAll('_', ' ').toLowerCase(),
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Movimentações'),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: TextButton.icon(
            onPressed: reload,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Atualizar'),
          ),
        ),
      ],
    ),
    body: FutureBuilder<List<MovimentoEstoque>>(
      future: future,
      builder: (context, s) {
        if (s.connectionState != ConnectionState.done) {
          return const AppLoadingState(label: 'Carregando movimentações…');
        }
        if (s.hasError) {
          return AppErrorState(message: s.error.toString(), onRetry: reload);
        }
        final all = s.data ?? const <MovimentoEstoque>[];
        final items = _type == null
            ? all
            : all.where((m) => m.tipo.startsWith(_type!)).toList();
        return ListView(
          children: [
            AppContent(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trilha imutável do estoque central. Nada aqui pode ser editado.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final entry in _filters.entries)
                        ChoiceChip(
                          label: Text(entry.value),
                          selected: _type == entry.key,
                          onSelected: (_) => setState(() => _type = entry.key),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (items.isEmpty)
                    const AppEmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'Nenhuma movimentação no estoque central',
                      message:
                          'Entradas, saídas, ajustes e transferências aparecem aqui.',
                    )
                  else if (AppBreakpoints.isMobile(context))
                    for (final m in items)
                      AppListRow(
                        title: _typeLabel(m.tipo),
                        meta:
                            '${AppFormatters.dateTime(m.createdAt)} · ${m.responsavel ?? 'Sistema'}\n'
                            '${m.motivo ?? 'Sem motivo'}',
                        trailing: _Quantity(m.quantidade.friendly, m),
                      )
                  else
                    _table(context, items),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );

  Widget _table(BuildContext context, List<MovimentoEstoque> items) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return AppTable(
      columns: const [
        DataColumn(label: Text('Data e hora')),
        DataColumn(label: Text('Tipo')),
        DataColumn(label: Text('Quantidade'), numeric: true),
        DataColumn(label: Text('Saldo após'), numeric: true),
        DataColumn(label: Text('Motivo')),
        DataColumn(label: Text('Responsável')),
      ],
      rows: [
        for (final m in items)
          DataRow(
            cells: [
              DataCell(
                Text(
                  AppFormatters.dateTime(m.createdAt),
                  style: tabularFigures,
                ),
              ),
              DataCell(Text(_typeLabel(m.tipo))),
              DataCell(_Quantity(m.quantidade.friendly, m)),
              DataCell(Text(m.saldoPosterior.friendly, style: tabularFigures)),
              DataCell(
                Text(
                  m.motivo ?? 'Sem motivo',
                  style: m.motivo == null ? TextStyle(color: muted) : null,
                ),
              ),
              DataCell(Text(m.responsavel ?? 'Sistema')),
            ],
          ),
      ],
    );
  }
}

class _Quantity extends StatelessWidget {
  const _Quantity(this.text, this.movement);
  final String text;
  final MovimentoEstoque movement;

  @override
  Widget build(BuildContext context) {
    final negative = movement.quantidade.isNegative;
    return Text(
      negative ? text : '+$text',
      style: tabularFigures.copyWith(
        fontWeight: FontWeight.w600,
        color: negative
            ? Theme.of(context).colorScheme.error
            : AppThemeColors.of(context).success,
      ),
    );
  }
}
