import 'package:flutter/material.dart';

import '../../core/widgets/app_refresh.dart';
import '../../core/formatters/app_formatters.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_content.dart';
import '../../core/widgets/async_state.dart';
import '../model/estoque.dart';
import '../model/estoque_repository.dart';

/// Trilha de movimentações do estoque central ou, com [condominioId], do
/// mercado de um Condomínio. É uma aba da tela de Estoque.
class MovimentacaoEstoquePage extends StatefulWidget {
  const MovimentacaoEstoquePage({
    super.key,
    this.repository,
    this.condominioId,
    this.header,
  });
  final EstoqueRepository? repository;
  final String? condominioId;
  final Widget? header;
  @override
  State<MovimentacaoEstoquePage> createState() =>
      _MovimentacaoEstoquePageState();
}

class _MovimentacaoEstoquePageState extends State<MovimentacaoEstoquePage> {
  late final EstoqueRepository repository;
  late Future<List<MovimentoEstoque>> future;
  // A trilha só traz o id do produto; o nome vem do catálogo.
  Map<String, String> _nomes = const {};
  String? _type;

  @override
  void initState() {
    super.initState();
    repository = widget.repository ?? EstoqueRepository();
    future = _carregar();
  }

  Future<List<MovimentoEstoque>> _carregar() async {
    final catalogo = repository.catalogo();
    final movimentos = await repository.movimentos(
      condominioId: widget.condominioId,
    );
    _nomes = {
      for (final entry in (await catalogo).entries) entry.key: entry.value.nome,
    };
    return movimentos;
  }

  void reload() => setState(() => future = _carregar());

  String _produto(MovimentoEstoque m) =>
      _nomes[m.produtoId] ?? 'Produto não encontrado';

  static const _filters = <String?, String>{
    null: 'Todas',
    'ENTRADA': 'Entradas',
    'SAIDA': 'Saídas',
    'AJUSTE': 'Ajustes',
    'TRANSFERENCIA': 'Transferências',
    'VENDA': 'Vendas',
  };

  @override
  Widget build(BuildContext context) => AppRefreshIndicator(
    onRefresh: () async {
      reload();
      await future.catchError((_) => const <MovimentoEstoque>[]);
    },
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
                  for (final entry in _filters.entries)
                    ChoiceChip(
                      label: Text(entry.value),
                      selected: _type == entry.key,
                      onSelected: (_) => setState(() => _type = entry.key),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Trilha imutável: nada aqui pode ser editado.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FutureBuilder<List<MovimentoEstoque>>(
                future: future,
                builder: (context, s) {
                  if (s.connectionState != ConnectionState.done) {
                    return const AppLoadingState(
                      label: 'Carregando movimentações…',
                      inline: true,
                    );
                  }
                  if (s.hasError) {
                    return AppErrorState(
                      message: s.error.toString(),
                      onRetry: reload,
                    );
                  }
                  final all = s.data ?? const <MovimentoEstoque>[];
                  final items = _type == null
                      ? all
                      : all.where((m) => m.tipo.startsWith(_type!)).toList();
                  if (items.isEmpty) {
                    return const AppEmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'Nenhuma movimentação neste local',
                      message:
                          'Entradas, saídas, ajustes, transferências e vendas aparecem aqui.',
                    );
                  }
                  if (!AppBreakpoints.isMobile(context)) {
                    return _table(context, items);
                  }
                  return Column(
                    children: [
                      for (final m in items)
                        AppListRow(
                          title: _produto(m),
                          meta:
                              '${movimentoTipoLabel(m.tipo)} · ${AppFormatters.dateTime(m.createdAt)} · ${m.responsavel ?? 'Sistema'}\n'
                              '${m.motivo ?? 'Sem motivo'}',
                          trailing: MovimentoQuantidade(
                            m.quantidade.friendly,
                            m,
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 88),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _table(BuildContext context, List<MovimentoEstoque> items) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return AppTable(
      columns: const [
        DataColumn(label: Text('Data e hora')),
        DataColumn(label: Text('Produto')),
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
              DataCell(Text(_produto(m))),
              DataCell(Text(movimentoTipoLabel(m.tipo))),
              DataCell(MovimentoQuantidade(m.quantidade.friendly, m)),
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

/// Rótulo do tipo de movimentação, como aparece para o operador.
String movimentoTipoLabel(String tipo) => switch (tipo) {
  'ENTRADA' => 'Entrada',
  'SAIDA' => 'Saída',
  'AJUSTE' => 'Ajuste',
  'VENDA' => 'Venda',
  'RESERVA' => 'Reserva',
  'LIBERACAO_RESERVA' => 'Reserva liberada',
  _ when tipo.startsWith('TRANSFERENCIA') => 'Transferência',
  _ => tipo.replaceAll('_', ' ').toLowerCase(),
};

/// Quantidade movimentada, com sinal e cor de entrada ou saída.
class MovimentoQuantidade extends StatelessWidget {
  const MovimentoQuantidade(this.text, this.movement, {super.key});
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
