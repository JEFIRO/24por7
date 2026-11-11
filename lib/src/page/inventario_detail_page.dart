import 'package:flutter/material.dart';

import '../../core/widgets/app_feedback.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_content.dart';
import '../../core/widgets/async_state.dart';
import '../../core/widgets/status_badge.dart';
import '../model/decimal_value.dart';
import '../model/inventario.dart';
import '../model/inventario_repository.dart';
import 'inventario_list_page.dart';

class InventarioDetailPage extends StatefulWidget {
  const InventarioDetailPage({
    super.key,
    required this.inventarioId,
    this.repository,
  });
  final String inventarioId;
  final InventarioRepository? repository;

  @override
  State<InventarioDetailPage> createState() => _InventarioDetailPageState();
}

class _InventarioDetailPageState extends State<InventarioDetailPage> {
  late final InventarioRepository _repository;
  Inventario? _inventario;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String _busca = '';
  String _filtro = 'TODOS';

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
      final value = await _repository.buscar(widget.inventarioId);
      if (mounted) setState(() => _inventario = value);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _contar(InventarioItem item) async {
    final quantidade = TextEditingController(
      text: item.quantidadeContada?.normalized ?? '',
    );
    final motivo = TextEditingController(text: item.motivoAjuste ?? '');
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.nome),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                [
                  'SKU ${item.codigoInterno}',
                  if (item.localizacaoPlanograma != null)
                    item.localizacaoPlanograma!,
                ].join(' · '),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: quantidade,
                autofocus: true,
                style: tabularFigures,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Quantidade contada',
                  helperText: 'Até 3 casas decimais',
                  suffixText: item.unidadeMedida,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: motivo,
                decoration: const InputDecoration(
                  labelText: 'Observação (opcional)',
                ),
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
            child: const Text('Confirmar contagem'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      final decimal = DecimalValue.parse(
        quantidade.text.replaceAll(',', '.'),
        maxScale: 3,
      );
      final updated = await _repository.contar(
        widget.inventarioId,
        item.id,
        decimal,
        motivo.text.trim(),
      );
      if (mounted) setState(() => _inventario = updated);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _acao(bool finalizar) async {
    setState(() => _saving = true);
    try {
      final updated = finalizar
          ? await _repository.finalizar(widget.inventarioId)
          : await _repository.cancelar(widget.inventarioId);
      if (mounted) setState(() => _inventario = updated);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<InventarioItem> get _filtrados {
    final items = _inventario?.itens ?? const <InventarioItem>[];
    return items.where((item) {
      final termo = _busca.toLowerCase();
      final buscaOk =
          termo.isEmpty ||
          item.nome.toLowerCase().contains(termo) ||
          item.codigoInterno.toLowerCase().contains(termo) ||
          (item.codigoBarras?.contains(termo) ?? false) ||
          item.codigosBarras.any((codigo) => codigo.contains(termo));
      final filtroOk =
          _filtro == 'TODOS' ||
          (_filtro == 'PENDENTES'
              ? item.quantidadeContada == null
              : item.status ==
                    _filtro.substring(
                      0,
                      _filtro.endsWith('S')
                          ? _filtro.length - 1
                          : _filtro.length,
                    ));
      return buscaOk && filtroOk;
    }).toList();
  }

  static const _filtros = <String, String>{
    'TODOS': 'Todos',
    'PENDENTES': 'Pendentes',
    'OK': 'Conferidos',
    'FALTAS': 'Faltas',
    'SOBRAS': 'Sobras',
    'CONFLITOS': 'Conflitos',
  };

  int _count(String filtro) {
    final items = _inventario?.itens ?? const <InventarioItem>[];
    return switch (filtro) {
      'TODOS' => items.length,
      'PENDENTES' => items.where((i) => i.quantidadeContada == null).length,
      _ =>
        items
            .where(
              (i) =>
                  i.status ==
                  (filtro.endsWith('S')
                      ? filtro.substring(0, filtro.length - 1)
                      : filtro),
            )
            .length,
    };
  }

  @override
  Widget build(BuildContext context) {
    final inventario = _inventario;
    final open =
        inventario != null &&
        inventario.status != 'FINALIZADO' &&
        inventario.status != 'CANCELADO';
    final mobile = AppBreakpoints.isMobile(context);
    final actions = open
        ? [
            OutlinedButton(
              onPressed: _saving ? null : () => _acao(false),
              child: const Text('Cancelar inventário'),
            ),
            FilledButton(
              onPressed: _saving || inventario.pendentes > 0
                  ? null
                  : () => _acao(true),
              child: Text(_saving ? 'Aguarde…' : 'Finalizar'),
            ),
          ]
        : <Widget>[];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contagem do inventário'),
        actions: mobile || actions.isEmpty
            ? null
            : [
                ...actions.expand(
                  (w) => [w, const SizedBox(width: AppSpacing.sm)],
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
      ),
      bottomNavigationBar: mobile && actions.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(child: actions[0]),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: actions[1]),
                  ],
                ),
              ),
            )
          : null,
      body: _loading
          ? const AppLoadingState(
              label: 'Carregando inventário…',
              layout: AppSkeletonLayout.detail,
            )
          : _error != null
          ? AppErrorState(message: _error!, onRetry: _carregar)
          : inventario == null
          ? const AppEmptyState(
              icon: Icons.search_off,
              title: 'Inventário não encontrado',
              message: 'Ele pode ter sido removido. Volte à lista.',
            )
          : ListView(
              children: [
                AppContent(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Resumo(inventario),
                      if (inventario.status == 'COM_CONFLITO') ...[
                        const SizedBox(height: AppSpacing.lg),
                        const AppBanner(
                          tone: AppStatusTone.critical,
                          message:
                              'O estoque mudou durante a contagem. Reconte os itens marcados como conflito.',
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: AppSearchField(
                          hintText: 'Nome, SKU ou código de barras',
                          onChanged: (value) => setState(() => _busca = value),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (final entry in _filtros.entries)
                            ChoiceChip(
                              label: Text(
                                '${entry.value} ${_count(entry.key)}',
                              ),
                              selected: _filtro == entry.key,
                              onSelected: (_) =>
                                  setState(() => _filtro = entry.key),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (_filtrados.isEmpty)
                        const AppEmptyState(
                          icon: Icons.filter_alt_off_outlined,
                          title: 'Nenhum item neste filtro',
                          message: 'Escolha outro filtro ou limpe a busca.',
                        )
                      else if (mobile)
                        for (final item in _filtrados)
                          AppListRow(
                            title: item.nome,
                            meta: [
                              'SKU ${item.codigoInterno}',
                              'Contado: ${item.quantidadeContada?.fixedScale(3).replaceAll('.', ',') ?? 'pendente'}',
                            ].join(' · '),
                            trailing: _itemBadge(item),
                            onTap: _canCount(inventario, item)
                                ? () => _contar(item)
                                : null,
                          )
                      else
                        _table(inventario),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  bool _canCount(Inventario inventario, InventarioItem item) =>
      inventario.status != 'FINALIZADO' &&
      inventario.status != 'CANCELADO' &&
      !item.ajusteAplicado;

  Widget _table(Inventario inventario) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    String qty(DecimalValue? value) =>
        value?.fixedScale(3).replaceAll('.', ',') ?? '—';
    return AppTable(
      columns: const [
        DataColumn(label: Text('Produto')),
        DataColumn(label: Text('Localização')),
        DataColumn(label: Text('Sistema'), numeric: true),
        DataColumn(label: Text('Contado'), numeric: true),
        DataColumn(label: Text('Diferença'), numeric: true),
        DataColumn(label: Text('Situação')),
      ],
      rows: [
        for (final item in _filtrados)
          DataRow(
            onSelectChanged: _canCount(inventario, item)
                ? (_) => _contar(item)
                : null,
            cells: [
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.nome, style: theme.textTheme.titleSmall),
                    Text('SKU ${item.codigoInterno}', style: muted),
                  ],
                ),
              ),
              DataCell(
                Text(
                  item.localizacaoPlanograma ?? '—',
                  style: item.localizacaoPlanograma == null ? muted : null,
                ),
              ),
              DataCell(
                Text(
                  inventario.contagemCega && item.quantidadeContada == null
                      ? '—'
                      : qty(item.saldoSistemaSnapshot),
                  style: tabularFigures,
                ),
              ),
              DataCell(
                Text(
                  qty(item.quantidadeContada),
                  style: tabularFigures.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              DataCell(_Difference(item.diferenca)),
              DataCell(_itemBadge(item)),
            ],
          ),
      ],
    );
  }

  static AppStatusBadge _itemBadge(InventarioItem item) {
    if (item.quantidadeContada == null) {
      return const AppStatusBadge(label: 'Pendente');
    }
    return switch (item.status) {
      'OK' => const AppStatusBadge(
        label: 'Conferido',
        tone: AppStatusTone.success,
      ),
      'FALTA' => const AppStatusBadge(
        label: 'Falta',
        tone: AppStatusTone.warning,
      ),
      'SOBRA' => const AppStatusBadge(label: 'Sobra', tone: AppStatusTone.info),
      'CONFLITO' => const AppStatusBadge(
        label: 'Conflito',
        tone: AppStatusTone.critical,
      ),
      final other => AppStatusBadge(label: other.toLowerCase()),
    };
  }
}

class _Difference extends StatelessWidget {
  const _Difference(this.value);
  final DecimalValue? value;

  @override
  Widget build(BuildContext context) {
    final value = this.value;
    if (value == null) return const Text('—');
    final text = value.fixedScale(3).replaceAll('.', ',');
    final color = value.isNegative
        ? Theme.of(context).colorScheme.error
        : value.isPositive
        ? AppThemeColors.of(context).success
        : null;
    return Text(
      value.isPositive ? '+$text' : text,
      style: tabularFigures.copyWith(color: color, fontWeight: FontWeight.w600),
    );
  }
}

class _Resumo extends StatelessWidget {
  const _Resumo(this.inventario);
  final Inventario inventario;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = inventario.totalProdutos == 0
        ? 1.0
        : inventario.contados / inventario.totalProdutos;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              inventario.descricao ?? inventario.localNome,
              style: theme.textTheme.headlineMedium,
            ),
            inventoryStatusBadge(inventario.status),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${inventario.localNome} · ${inventario.contagemCega ? 'Contagem cega' : 'Contagem aberta'}',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${inventario.contados} de ${inventario.totalProdutos} contados · '
                '${inventario.divergencias} divergências · ${inventario.conflitos} conflitos',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              AppProgressBar(value: progress),
            ],
          ),
        ),
      ],
    );
  }
}
