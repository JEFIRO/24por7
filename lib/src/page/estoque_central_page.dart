import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_content.dart';
import '../../core/widgets/async_state.dart';
import '../../core/widgets/status_badge.dart';
import '../model/produto.dart';
import '../model/decimal_value.dart';
import '../model/estoque.dart';
import '../model/estoque_repository.dart';
import 'inventario_list_page.dart';
import 'transferencia_estoque_page.dart';

class EstoqueCentralPage extends StatefulWidget {
  const EstoqueCentralPage({super.key, this.repository});
  final EstoqueRepository? repository;
  @override
  State<EstoqueCentralPage> createState() => _EstoqueCentralPageState();
}

class _EstoqueCentralPageState extends State<EstoqueCentralPage> {
  static const _pageSize = 50;
  late final EstoqueRepository repository;
  final search = TextEditingController();
  final _scroll = ScrollController();
  List<EstoqueCentral> items = const [];
  String? categoria;
  bool? ativo;
  bool loading = true;
  bool loadingMore = false;
  String? error;
  String? loadMoreError;
  int _page = 0;
  int _totalPages = 1;
  int _total = 0;
  // Descarta respostas antigas quando a busca ou os filtros mudam no meio.
  int _request = 0;

  bool get _hasMore => _page + 1 < _totalPages;

  @override
  void initState() {
    super.initState();
    repository = widget.repository ?? EstoqueRepository();
    _scroll.addListener(_onScroll);
    load();
  }

  @override
  void dispose() {
    search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < 600) _loadMore();
  }

  Future<void> load() async {
    final request = ++_request;
    setState(() {
      loading = true;
      error = null;
      loadMoreError = null;
    });
    try {
      final result = await repository.listarCentralPagina(
        size: _pageSize,
        busca: search.text.trim(),
        categoria: categoria,
        ativo: ativo,
      );
      if (!mounted || request != _request) return;
      setState(() {
        items = result.items;
        _page = 0;
        _totalPages = result.totalPages;
        _total = result.totalElements;
      });
    } catch (e) {
      if (mounted && request == _request) setState(() => error = e.toString());
    } finally {
      if (mounted && request == _request) setState(() => loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (loading || loadingMore || !_hasMore || loadMoreError != null) return;
    final request = _request;
    setState(() => loadingMore = true);
    try {
      final result = await repository.listarCentralPagina(
        page: _page + 1,
        size: _pageSize,
        busca: search.text.trim(),
        categoria: categoria,
        ativo: ativo,
      );
      if (!mounted || request != _request) return;
      setState(() {
        items = [...items, ...result.items];
        _page = result.page;
        _totalPages = result.totalPages;
        _total = result.totalElements;
      });
    } catch (e) {
      if (mounted && request == _request) {
        setState(() => loadMoreError = e.toString());
      }
    } finally {
      if (mounted) setState(() => loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mobile = AppBreakpoints.isMobile(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estoque central'),
        actions: [
          if (!mobile) ...[
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InventarioListPage()),
              ),
              child: const Text('Inventário'),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TransferenciaEstoquePage(),
                ),
              ),
              child: const Text('Nova transferência'),
            ),
            const SizedBox(width: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              child: FilledButton.icon(
                onPressed: () => _movimentar(),
                icon: const Icon(Icons.swap_vert, size: 18),
                label: const Text('Movimentar'),
              ),
            ),
          ],
        ],
      ),
      floatingActionButton: mobile
          ? FloatingActionButton.extended(
              onPressed: () => _movimentar(),
              icon: const Icon(Icons.swap_vert),
              label: const Text('Movimentar'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          controller: _scroll,
          children: [
            AppContent(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.xl,
                    runSpacing: AppSpacing.md,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                      SizedBox(
                        width: mobile ? double.infinity : 420,
                        child: AppSearchField(
                          controller: search,
                          hintText: 'Buscar por nome, SKU ou código de barras',
                          onSubmitted: (_) => load(),
                        ),
                      ),
                      SizedBox(
                        width: mobile ? double.infinity : 220,
                        child: DropdownButtonFormField<String?>(
                          initialValue: categoria,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Categoria',
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Todas'),
                            ),
                            ..._categorias.map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(_categoriaLabel(value)),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            categoria = value;
                            load();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      for (final (value, label) in const [
                        (true, 'Ativos'),
                        (false, 'Inativos'),
                        (null, 'Todos'),
                      ])
                        ChoiceChip(
                          label: Text(label),
                          selected: ativo == value,
                          onSelected: (_) {
                            ativo = value;
                            load();
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _body(mobile),
                  if (!loading && error == null && items.isNotEmpty) _footer(),
                  const SizedBox(height: 88),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(bool mobile) {
    final theme = Theme.of(context);
    if (loading) return const AppLoadingState(label: 'Carregando saldos…');
    if (error != null) return AppErrorState(message: error!, onRetry: load);
    if (items.isEmpty) {
      return AppEmptyState(
        icon: Icons.warehouse_outlined,
        title: 'Nenhum produto possui saldo central',
        message: 'Use Entrada para iniciar o estoque.',
        action: FilledButton(
          onPressed: () => _movimentar(),
          child: const Text('Registrar entrada'),
        ),
      );
    }
    TextStyle? balanceStyle(EstoqueCentral item) => tabularFigures.copyWith(
      fontWeight: FontWeight.w600,
      color: item.quantidade.isNegative ? theme.colorScheme.error : null,
    );
    if (mobile) {
      return Column(
        children: [
          for (final item in items)
            AppListRow(
              title: item.produto,
              muted: !item.ativo,
              meta:
                  'SKU ${item.codigoInterno} · ${item.localizacao?.isNotEmpty == true ? item.localizacao : 'Sem localização'}',
              trailing: Text(
                '${item.quantidade.fixedScale(3).replaceAll('.', ',')} ${item.unidadeMedida}',
                style: balanceStyle(item),
              ),
              onTap: () => _movimentar(item: item),
            ),
        ],
      );
    }
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return AppTable(
      columns: const [
        DataColumn(label: Text('Produto')),
        DataColumn(label: Text('Categoria')),
        DataColumn(label: Text('Localização')),
        DataColumn(label: Text('Saldo'), numeric: true),
        DataColumn(label: Text('Status')),
        DataColumn(label: SizedBox.shrink()),
      ],
      rows: [
        for (final item in items)
          DataRow(
            onSelectChanged: (_) => _movimentar(item: item),
            cells: [
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.produto, style: theme.textTheme.titleSmall),
                    Text('SKU ${item.codigoInterno}', style: muted),
                  ],
                ),
              ),
              DataCell(Text(_categoriaLabel(item.categoria))),
              DataCell(
                Text(
                  item.localizacao?.isNotEmpty == true
                      ? item.localizacao!
                      : 'Sem localização',
                  style: item.localizacao?.isNotEmpty == true ? null : muted,
                ),
              ),
              DataCell(
                Text(
                  '${item.quantidade.fixedScale(3).replaceAll('.', ',')} ${item.unidadeMedida}',
                  style: balanceStyle(item),
                ),
              ),
              DataCell(
                item.ativo
                    ? const AppStatusBadge(
                        label: 'Ativo',
                        tone: AppStatusTone.success,
                      )
                    : const AppStatusBadge(label: 'Inativo'),
              ),
              DataCell(
                IconButton(
                  tooltip: 'Movimentar ${item.produto}',
                  onPressed: () => _movimentar(item: item),
                  icon: const Icon(Icons.swap_vert),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _footer() {
    final theme = Theme.of(context);
    final count = Text(
      'Mostrando ${items.length} de $_total produtos',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Center(
        child: Column(
          children: [
            count,
            const SizedBox(height: AppSpacing.sm),
            if (loadingMore)
              const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (loadMoreError != null)
              TextButton.icon(
                onPressed: () {
                  setState(() => loadMoreError = null);
                  _loadMore();
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Falha ao carregar. Tentar de novo'),
              )
            else if (_hasMore)
              OutlinedButton(
                onPressed: _loadMore,
                child: const Text('Carregar mais'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _movimentar({EstoqueCentral? item}) async {
    // Com o produto já escolhido na lista, não há o que selecionar.
    List<Produto> produtos = const [];
    if (item == null) {
      try {
        produtos = await repository.listarProdutos();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.toString())));
        }
        return;
      }
      if (!mounted || produtos.isEmpty) return;
    }
    String produtoId = item?.produtoId ?? produtos.first.id!;
    String operacao = 'ENTRADA';
    // Começa vazio: pré-preencher com o saldo fazia uma Entrada confirmada
    // sem querer dobrar o estoque.
    final quantidade = TextEditingController();
    final motivo = TextEditingController();
    Widget panel(BuildContext context, StateSetter setPanel) {
      final theme = Theme.of(context);
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Movimentar estoque central',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Fechar',
                  onPressed: () => Navigator.pop(context, false),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item == null)
                    DropdownButtonFormField<String>(
                      initialValue: produtoId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Produto'),
                      items: produtos
                          .map(
                            (p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(
                                p.nome,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => produtoId = v!,
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.produto,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'SKU ${item.codigoInterno} · Saldo atual: '
                            '${item.quantidade.fixedScale(3).replaceAll('.', ',')} ${item.unidadeMedida}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<String>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: 'ENTRADA', label: Text('Entrada')),
                        ButtonSegment(value: 'SAIDA', label: Text('Saída')),
                        ButtonSegment(value: 'AJUSTE', label: Text('Ajuste')),
                      ],
                      selected: {operacao},
                      onSelectionChanged: (v) =>
                          setPanel(() => operacao = v.first),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: quantidade,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    onChanged: (_) => setPanel(() {}),
                    decoration: InputDecoration(
                      labelText: operacao == 'AJUSTE'
                          ? 'Saldo físico contado'
                          : 'Quantidade',
                      helperText:
                          _novoSaldo(item, operacao, quantidade.text) ??
                          'Até 3 casas decimais; saldo negativo é permitido no ajuste',
                      helperStyle:
                          _novoSaldo(item, operacao, quantidade.text) == null
                          ? null
                          : theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: motivo,
                    maxLength: 300,
                    decoration: const InputDecoration(labelText: 'Motivo'),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Confirmar'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Painel lateral no computador, folha inferior no celular.
    final Future<bool?> sheet = AppBreakpoints.isMobile(context)
        ? showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (context) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: SafeArea(child: StatefulBuilder(builder: panel)),
            ),
          )
        : showGeneralDialog<bool>(
            context: context,
            barrierDismissible: true,
            barrierLabel: 'Fechar',
            barrierColor: Colors.black26,
            transitionDuration: const Duration(milliseconds: 220),
            pageBuilder: (context, _, _) => Align(
              alignment: Alignment.centerRight,
              child: Material(
                color: Theme.of(context).colorScheme.surface,
                elevation: 1,
                child: SizedBox(
                  width: 440,
                  height: double.infinity,
                  child: SafeArea(
                    child: Column(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: StatefulBuilder(builder: panel),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            transitionBuilder: (context, animation, _, child) =>
                SlideTransition(
                  position: Tween(begin: const Offset(1, 0), end: Offset.zero)
                      .animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                  child: child,
                ),
          );
    final ok = await sheet;
    if (ok != true) return;
    try {
      final value = DecimalValue.parse(quantidade.text);
      if (!RegExp(r'^-?\d+([\.,]\d{1,3})?$').hasMatch(quantidade.text.trim())) {
        throw const FormatException('Use no máximo 3 casas decimais');
      }
      await repository.movimentar(
        produtoId,
        operacao,
        value,
        motivo.text.trim(),
      );
      await load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}

/// Prévia do saldo após a operação, ou null se não der para calcular.
String? _novoSaldo(EstoqueCentral? item, String operacao, String raw) {
  if (item == null || raw.trim().isEmpty) return null;
  final DecimalValue quantidade;
  try {
    quantidade = DecimalValue.parse(raw, maxScale: 3);
  } on FormatException {
    return null;
  }
  final atual = item.quantidade.scaledInteger;
  final valor = quantidade.scaledInteger;
  final novo = switch (operacao) {
    'ENTRADA' => atual + valor,
    'SAIDA' => atual - valor,
    _ => valor,
  };
  final texto = DecimalValue.fromScaled(novo).friendly;
  return 'Saldo passa de ${item.quantidade.friendly} para $texto ${item.unidadeMedida}';
}

const _categorias = <String>[
  'BEBIDA',
  'ALIMENTOS',
  'LIMPEZA',
  'HIGIENE',
  'PADARIA',
  'LATICINIOS',
  'CONGELADOS',
  'DOCES',
  'SALGADINHOS',
  'FRUTAS',
  'VERDURAS',
  'LEGUMES',
  'CARNES',
  'FRIOS',
  'PETISCOS',
  'TEMPEROS',
  'GRAOS',
  'MASSAS',
  'ENLATADOS',
  'MATINAIS',
  'UTILIDADES',
  'PET',
  'INFANTIL',
  'ELETRONICOS',
  'PAPELARIA',
  'DESCARTAVEIS',
  'OUTROS',
];

String _categoriaLabel(String value) {
  final text = value.replaceAll('_', ' ').toLowerCase();
  return text.isEmpty ? text : '${text[0].toUpperCase()}${text.substring(1)}';
}
