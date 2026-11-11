import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';
import '../../core/widgets/app_refresh.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_content.dart';
import '../../core/widgets/async_state.dart';
import '../../core/widgets/status_badge.dart';
import '../model/produto.dart';
import '../model/decimal_value.dart';
import '../model/estoque.dart';
import '../model/estoque_repository.dart';
import 'estoque_produto_page.dart';

/// Saldos do estoque central. É uma aba da tela de Estoque: não tem Scaffold
/// próprio e recebe o cabeçalho de quem a hospeda.
class EstoqueCentralPage extends StatefulWidget {
  const EstoqueCentralPage({super.key, this.repository, this.header});
  final EstoqueRepository? repository;
  final Widget? header;
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
    return AppRefreshIndicator(
      onRefresh: load,
      child: ListView(
        controller: _scroll,
        children: [
          AppContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ?widget.header,
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
    );
  }

  Widget _body(bool mobile) {
    final theme = Theme.of(context);
    if (loading) {
      return const AppLoadingState(label: 'Carregando saldos…', inline: true);
    }
    if (error != null) return AppErrorState(message: error!, onRetry: load);
    if (items.isEmpty) {
      return AppEmptyState(
        icon: Icons.warehouse_outlined,
        title: 'Nenhum produto possui saldo central',
        message: 'Receba mercadoria por NF-e ou registre uma entrada manual.',
        action: FilledButton(
          onPressed: _entradaManual,
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
              onTap: () => _abrir(item),
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
      ],
      rows: [
        for (final item in items)
          DataRow(
            onSelectChanged: (_) => _abrir(item),
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

  Future<void> _abrir(EstoqueCentral item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EstoqueProdutoPage(
          produtoId: item.produtoId,
          nome: item.produto,
          central: item,
          repository: repository,
        ),
      ),
    );
    if (mounted) await load();
  }

  Future<void> _entradaManual() async {
    final changed = await movimentarEstoqueCentral(
      context,
      repository,
      somenteEntrada: true,
    );
    if (changed && mounted) await load();
  }
}

/// Abre o painel de entrada, saída ou ajuste do estoque central. Devolve true
/// quando o saldo mudou. Com [somenteEntrada] o painel só registra entradas.
Future<bool> movimentarEstoqueCentral(
  BuildContext context,
  EstoqueRepository repository, {
  EstoqueCentral? item,
  bool somenteEntrada = false,
}) async {
  // Com o produto já escolhido na lista, não há o que selecionar.
  List<Produto> produtos = const [];
  if (item == null) {
    try {
      produtos = await repository.listarProdutos();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
      return false;
    }
    if (!context.mounted) return false;
    if (produtos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cadastre um produto antes de dar entrada.'),
        ),
      );
      return false;
    }
  }
  String produtoId = item?.produtoId ?? produtos.first.id!;
  String operacao = 'ENTRADA';
  // Começa vazio: pré-preencher com o saldo fazia uma Entrada confirmada
  // sem querer dobrar o estoque.
  final quantidade = TextEditingController();
  final motivo = TextEditingController();
  String? erroQuantidade;
  String? erroEnvio;
  var salvando = false;
  // Valida e grava com o painel aberto: um erro não descarta o que foi
  // digitado.
  Future<void> confirmar(BuildContext context, StateSetter setPanel) async {
    final texto = quantidade.text.trim();
    DecimalValue? valor;
    String? invalido;
    if (texto.isEmpty) {
      invalido = 'Informe a quantidade';
    } else if (!RegExp(r'^-?\d+([\.,]\d{1,3})?$').hasMatch(texto)) {
      invalido = 'Use um número com até 3 casas decimais';
    } else {
      valor = DecimalValue.parse(texto);
      if (operacao != 'AJUSTE' && !valor.isPositive) {
        invalido = 'A quantidade deve ser maior que zero';
      }
    }
    if (invalido != null || valor == null) {
      setPanel(() => erroQuantidade = invalido);
      return;
    }
    setPanel(() {
      erroQuantidade = null;
      erroEnvio = null;
      salvando = true;
    });
    try {
      await repository.movimentar(
        produtoId,
        operacao,
        valor,
        motivo.text.trim(),
      );
      if (context.mounted) Navigator.pop(context, true);
    } catch (e) {
      if (context.mounted) {
        setPanel(() {
          erroEnvio = e.toString();
          salvando = false;
        });
      }
    }
  }

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
                  somenteEntrada
                      ? 'Entrada manual'
                      : 'Corrigir saldo do central',
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
                        Text(item.produto, style: theme.textTheme.titleMedium),
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
                if (!somenteEntrada)
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
                  onChanged: (_) => setPanel(() => erroQuantidade = null),
                  decoration: InputDecoration(
                    errorText: erroQuantidade,
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
                if (erroEnvio != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  AppBanner(tone: AppStatusTone.critical, message: erroEnvio!),
                  const SizedBox(height: AppSpacing.md),
                ],
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
                onPressed: salvando ? null : () => confirmar(context, setPanel),
                child: Text(salvando ? 'Salvando…' : 'Confirmar'),
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
          transitionDuration: AppMotion.of(context, AppMotion.slow),
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
          transitionBuilder: (context, animation, _, child) => SlideTransition(
            position: Tween(begin: const Offset(1, 0), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: AppMotion.enter,
                    reverseCurve: AppMotion.exit,
                  ),
                ),
            child: child,
          ),
        );
  return await sheet == true;
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
