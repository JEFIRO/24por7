import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/widgets/app_refresh.dart';
import '../../core/formatters/app_formatters.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_content.dart';
import '../../core/widgets/async_state.dart';
import '../../core/widgets/status_badge.dart';
import '../model/decimal_value.dart';
import '../model/estoque.dart';
import '../model/estoque_repository.dart';
import '../model/produto_repository.dart';

/// Lista de transferências do central para os Condomínios. É uma aba da tela
/// de Estoque.
class TransferenciaEstoquePage extends StatefulWidget {
  const TransferenciaEstoquePage({super.key, this.repository, this.header});
  final EstoqueRepository? repository;
  final Widget? header;
  @override
  State<TransferenciaEstoquePage> createState() =>
      _TransferenciaEstoquePageState();
}

class _TransferenciaEstoquePageState extends State<TransferenciaEstoquePage> {
  late final EstoqueRepository repository;
  late Future<List<TransferenciaEstoque>> future;
  @override
  void initState() {
    super.initState();
    repository = widget.repository ?? EstoqueRepository();
    future = repository.transferencias();
  }

  void load() => setState(() => future = repository.transferencias());
  String? _status;

  Future<void> _new() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TransferenciaFormPage(repository: repository),
      ),
    );
    if (changed == true) load();
  }

  Future<void> _open(TransferenciaEstoque t) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TransferenciaDetailPage(id: t.id, repository: repository),
      ),
    );
    load();
  }

  @override
  Widget build(BuildContext context) {
    final mobile = AppBreakpoints.isMobile(context);
    return AppRefreshIndicator(
      onRefresh: () async {
        load();
        await future.catchError((_) => const <TransferenciaEstoque>[]);
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
                    for (final (value, label) in const [
                      (null, 'Todas'),
                      ('RASCUNHO', 'Rascunho'),
                      ('CONFIRMADA', 'Confirmadas'),
                      ('CANCELADA', 'Canceladas'),
                    ])
                      ChoiceChip(
                        label: Text(label),
                        selected: _status == value,
                        onSelected: (_) => setState(() => _status = value),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                FutureBuilder<List<TransferenciaEstoque>>(
                  future: future,
                  builder: (context, s) {
                    if (s.connectionState != ConnectionState.done) {
                      return const AppLoadingState(
                        label: 'Carregando transferências…',
                        inline: true,
                      );
                    }
                    if (s.hasError) {
                      return AppErrorState(
                        message: s.error.toString(),
                        onRetry: load,
                      );
                    }
                    final all = s.data ?? const <TransferenciaEstoque>[];
                    final items = _status == null
                        ? all
                        : all.where((t) => t.status == _status).toList();
                    if (items.isEmpty) {
                      return AppEmptyState(
                        icon: Icons.local_shipping_outlined,
                        title: 'Nenhuma transferência registrada',
                        message:
                            'Transfira produtos do estoque central para abastecer um Condomínio.',
                        action: FilledButton(
                          onPressed: _new,
                          child: const Text('Nova transferência'),
                        ),
                      );
                    }
                    if (mobile) {
                      return Column(
                        children: [
                          for (final t in items)
                            AppListRow(
                              title: transferCode(t.id),
                              meta:
                                  'Para ${t.destinoNome} · ${_itemCount(t.itens.length)}\n${_date(t.createdAt)}',
                              trailing: transferStatusBadge(t.status),
                              onTap: () => _open(t),
                            ),
                        ],
                      );
                    }
                    return AppTable(
                      columns: const [
                        DataColumn(label: Text('Transferência')),
                        DataColumn(label: Text('Destino')),
                        DataColumn(label: Text('Itens'), numeric: true),
                        DataColumn(label: Text('Responsável')),
                        DataColumn(label: Text('Data')),
                        DataColumn(label: Text('Status')),
                      ],
                      rows: [
                        for (final t in items)
                          DataRow(
                            onSelectChanged: (_) => _open(t),
                            cells: [
                              DataCell(
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      transferCode(t.id),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleSmall,
                                    ),
                                    if (t.observacao?.isNotEmpty == true)
                                      Text(
                                        t.observacao!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                  ],
                                ),
                              ),
                              DataCell(Text(t.destinoNome)),
                              DataCell(
                                Text(
                                  '${t.itens.length}',
                                  style: tabularFigures,
                                ),
                              ),
                              DataCell(Text(t.responsavel ?? 'Sistema')),
                              DataCell(
                                Text(_date(t.createdAt), style: tabularFigures),
                              ),
                              DataCell(transferStatusBadge(t.status)),
                            ],
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
  }
}

String transferCode(String id) =>
    'TRF-${(id.length > 8 ? id.substring(0, 8) : id).toUpperCase()}';

String _itemCount(int count) => count == 1 ? '1 item' : '$count itens';

AppStatusBadge transferStatusBadge(String status) => switch (status) {
  'RASCUNHO' => const AppStatusBadge(label: 'Rascunho'),
  'CRIADA' => const AppStatusBadge(label: 'Criada', tone: AppStatusTone.info),
  'CONFIRMADA' => const AppStatusBadge(
    label: 'Confirmada',
    tone: AppStatusTone.success,
  ),
  'CANCELADA' => const AppStatusBadge(label: 'Cancelada'),
  _ => AppStatusBadge(label: status.replaceAll('_', ' ').toLowerCase()),
};

class TransferenciaFormPage extends StatefulWidget {
  const TransferenciaFormPage({
    super.key,
    required this.repository,
    this.destinoInicial,
    this.itemInicial,
  });
  final EstoqueRepository repository;

  /// Condomínio já escolhido por quem abriu o formulário.
  final String? destinoInicial;

  /// Produto que já entra na lista de itens.
  final EstoqueCentral? itemInicial;
  @override
  State<TransferenciaFormPage> createState() => _TransferenciaFormPageState();
}

class _ItemSelecionado {
  _ItemSelecionado(this.estoque);
  final EstoqueCentral estoque;
  final quantidade = TextEditingController();
}

class _TransferenciaFormPageState extends State<TransferenciaFormPage> {
  List<CondominioOption> condos = const [];
  // Mantém a ordem em que os produtos foram adicionados.
  final selected = <String, _ItemSelecionado>{};
  final obs = TextEditingController();
  String? destino;
  bool loading = true;
  bool saving = false;
  String? error;
  @override
  void initState() {
    super.initState();
    final item = widget.itemInicial;
    if (item != null) selected[item.produtoId] = _ItemSelecionado(item);
    load();
  }

  @override
  void dispose() {
    for (final item in selected.values) {
      item.quantidade.dispose();
    }
    obs.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      condos = await widget.repository.condominios();
      final inicial = widget.destinoInicial;
      destino = condos.any((c) => c.id == inicial)
          ? inicial
          : (condos.isEmpty ? null : condos.first.id);
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _toggle(EstoqueCentral e) => setState(() {
    final removed = selected.remove(e.produtoId);
    if (removed != null) {
      removed.quantidade.dispose();
    } else {
      selected[e.produtoId] = _ItemSelecionado(e);
    }
  });

  Future<void> _adicionar() async {
    final picker = _ProdutoPicker(
      repository: widget.repository,
      isSelected: (id) => selected.containsKey(id),
      onToggle: _toggle,
    );
    if (AppBreakpoints.isMobile(context)) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.85,
          child: picker,
        ),
      );
    } else {
      await showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          clipBehavior: Clip.antiAlias,
          child: SizedBox(width: 600, height: 680, child: picker),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mobile = AppBreakpoints.isMobile(context);
    final count = selected.length;
    final reviewButton = FilledButton(
      onPressed: saving || count == 0 ? null : confirmar,
      child: Text(
        saving
            ? 'Confirmando…'
            : count == 0
            ? 'Revisar e confirmar'
            : 'Revisar e confirmar (${_itemCount(count)})',
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova transferência'),
        actions: mobile
            ? null
            : [
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.lg),
                  child: reviewButton,
                ),
              ],
      ),
      bottomNavigationBar: mobile && !loading && error == null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: reviewButton,
              ),
            )
          : null,
      body: loading
          ? const AppLoadingState(
              label: 'Carregando Condomínios…',
              layout: AppSkeletonLayout.detail,
            )
          : error != null
          ? AppErrorState(
              message: error!,
              onRetry: () {
                setState(() {
                  loading = true;
                  error = null;
                });
                load();
              },
            )
          : ListView(
              children: [
                AppContent(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppLayout.formMaxWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: destino,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Do estoque central para',
                            prefixIcon: Icon(Icons.apartment_outlined),
                          ),
                          items: condos
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(
                                    c.nome,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => destino = v),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        AppSectionTitle(
                          'Produtos',
                          subtitle: count == 0
                              ? 'Nenhum produto adicionado'
                              : _itemCount(count),
                          trailing: count == 0
                              ? null
                              : TextButton.icon(
                                  onPressed: _adicionar,
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Adicionar'),
                                ),
                        ),
                        if (count == 0)
                          AppEmptyState(
                            icon: Icons.add_shopping_cart_outlined,
                            title: 'Adicione os produtos a transferir',
                            message:
                                'Busque por nome, SKU ou código de barras no estoque central.',
                            action: FilledButton.icon(
                              onPressed: _adicionar,
                              icon: const Icon(Icons.search),
                              label: const Text('Buscar produtos'),
                            ),
                          )
                        else
                          for (final item in selected.values)
                            _itemRow(theme, item),
                        const SizedBox(height: AppSpacing.xl),
                        TextField(
                          controller: obs,
                          maxLength: 600,
                          decoration: const InputDecoration(
                            labelText: 'Observação (opcional)',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _itemRow(ThemeData theme, _ItemSelecionado item) {
    final e = item.estoque;
    final erro = _erroQuantidade(e, item.quantidade.text);
    return Container(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(e.produto, style: theme.textTheme.titleSmall),
                ),
              ),
              IconButton(
                tooltip: 'Remover ${e.produto}',
                visualDensity: VisualDensity.compact,
                onPressed: () => _toggle(e),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Disponível: ${_qty(e.quantidade, e.unidadeMedida)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              _QuantidadeStepper(
                controller: item.quantidade,
                max: e.quantidade,
                unidade: e.unidadeMedida,
                hasError: erro != null,
                onChanged: () => setState(() {}),
              ),
            ],
          ),
          if (erro != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                erro,
                textAlign: TextAlign.right,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> confirmar() async {
    if (destino == null || selected.isEmpty) {
      _message('Selecione o destino e pelo menos um produto');
      return;
    }
    final itens = <TransferenciaItem>[];
    for (final item in selected.values) {
      final e = item.estoque;
      final raw = item.quantidade.text.trim();
      final erro = raw.isEmpty
          ? 'Informe a quantidade'
          : _erroQuantidade(e, raw);
      if (erro != null) {
        _message('${e.produto}: $erro');
        return;
      }
      itens.add(
        TransferenciaItem(
          produtoId: e.produtoId,
          produto: e.produto,
          quantidade: DecimalValue.parse(raw, maxScale: 3),
        ),
      );
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar transferência'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Do estoque central para '
                '${condos.where((c) => c.id == destino).map((c) => c.nome).firstOrNull ?? 'o Condomínio'}.',
              ),
              const SizedBox(height: AppSpacing.md),
              for (final e in itens)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    children: [
                      Expanded(child: Text(e.produto)),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        e.quantidade.friendly,
                        style: tabularFigures.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar transferência'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => saving = true);
    try {
      final draft = await widget.repository.criarTransferencia(
        destino!,
        obs.text.trim(),
        itens,
      );
      await widget.repository.confirmar(draft.id);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _message(e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void _message(String value) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(value)));
    }
  }
}

String _qty(DecimalValue value, String unidade) => '${value.friendly} $unidade';

/// Erro da quantidade digitada, ou null se ela vale (ou ainda está vazia).
String? _erroQuantidade(EstoqueCentral e, String raw) {
  if (raw.trim().isEmpty) return null;
  if (!RegExp(r'^\d+([\.,]\d{1,3})?$').hasMatch(raw.trim())) {
    return 'Até 3 casas decimais';
  }
  final q = DecimalValue.parse(raw, maxScale: 3);
  if (!q.isPositive) return 'Maior que zero';
  if (q.scaledInteger > e.quantidade.scaledInteger) {
    return 'Só há ${e.quantidade.friendly} ${e.unidadeMedida} disponível';
  }
  return null;
}

/// Campo de quantidade com − e + de uma unidade, limitado ao disponível.
class _QuantidadeStepper extends StatelessWidget {
  const _QuantidadeStepper({
    required this.controller,
    required this.max,
    required this.unidade,
    required this.hasError,
    required this.onChanged,
  });
  final TextEditingController controller;
  final DecimalValue max;
  final String unidade;
  final bool hasError;
  final VoidCallback onChanged;

  static final _um = BigInt.from(1000000);

  BigInt? get _atual {
    final raw = controller.text.trim();
    if (raw.isEmpty) return BigInt.zero;
    try {
      return DecimalValue.parse(raw, maxScale: 3).scaledInteger;
    } on FormatException {
      return null;
    }
  }

  void _somar(BigInt delta) {
    var novo = (_atual ?? BigInt.zero) + delta;
    if (novo < BigInt.zero) novo = BigInt.zero;
    if (novo > max.scaledInteger) novo = max.scaledInteger;
    controller.text = novo == BigInt.zero
        ? ''
        : DecimalValue.fromScaled(novo).friendly;
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final atual = _atual;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      borderSide: BorderSide(
        color: hasError ? theme.colorScheme.error : theme.colorScheme.outline,
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.outlined(
          tooltip: 'Diminuir',
          visualDensity: VisualDensity.compact,
          onPressed: atual == null || atual <= BigInt.zero
              ? null
              : () => _somar(-_um),
          icon: const Icon(Icons.remove, size: 18),
        ),
        const SizedBox(width: AppSpacing.xs),
        SizedBox(
          width: 72,
          child: TextField(
            controller: controller,
            textAlign: TextAlign.center,
            style: tabularFigures.copyWith(fontWeight: FontWeight.w600),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              isDense: true,
              hintText: '0',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.sm,
              ),
              border: border,
              enabledBorder: border,
              focusedBorder: border.copyWith(
                borderSide: BorderSide(
                  color: hasError
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        IconButton.outlined(
          tooltip: 'Aumentar',
          visualDensity: VisualDensity.compact,
          onPressed: atual == null || atual >= max.scaledInteger
              ? null
              : () => _somar(_um),
          icon: const Icon(Icons.add, size: 18),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(unidade, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

/// Busca no estoque central, página a página, para escolher o que transferir.
class _ProdutoPicker extends StatefulWidget {
  const _ProdutoPicker({
    required this.repository,
    required this.isSelected,
    required this.onToggle,
  });
  final EstoqueRepository repository;
  final bool Function(String produtoId) isSelected;
  final ValueChanged<EstoqueCentral> onToggle;

  @override
  State<_ProdutoPicker> createState() => _ProdutoPickerState();
}

class _ProdutoPickerState extends State<_ProdutoPicker> {
  static const _pageSize = 30;
  final _search = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;
  List<EstoqueCentral> items = const [];
  bool loading = true;
  bool loadingMore = false;
  String? error;
  int _page = 0;
  int _totalPages = 1;
  int _request = 0;

  bool get _hasMore => _page + 1 < _totalPages;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 400) _loadMore();
    });
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await widget.repository.listarCentralPagina(
        size: _pageSize,
        busca: _search.text.trim(),
        ativo: true,
      );
      if (!mounted || request != _request) return;
      setState(() {
        items = result.items;
        _page = 0;
        _totalPages = result.totalPages;
      });
    } catch (e) {
      if (mounted && request == _request) setState(() => error = e.toString());
    } finally {
      if (mounted && request == _request) setState(() => loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (loading || loadingMore || !_hasMore) return;
    final request = _request;
    setState(() => loadingMore = true);
    try {
      final result = await widget.repository.listarCentralPagina(
        page: _page + 1,
        size: _pageSize,
        busca: _search.text.trim(),
        ativo: true,
      );
      if (!mounted || request != _request) return;
      setState(() {
        items = [...items, ...result.items];
        _page = result.page;
        _totalPages = result.totalPages;
      });
    } catch (_) {
      // Mantém o que já foi carregado; rolar de novo tenta outra vez.
    } finally {
      if (mounted) setState(() => loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.md,
            AppSpacing.xl,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Adicionar produtos', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              AppSearchField(
                controller: _search,
                autofocus: !AppBreakpoints.isMobile(context),
                hintText: 'Nome, SKU ou código de barras',
                onChanged: _onSearch,
                onSubmitted: (_) {
                  _debounce?.cancel();
                  _load();
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _results(theme)),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SafeArea(
            top: false,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Concluir'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _results(ThemeData theme) {
    if (loading) return const AppLoadingState(label: 'Buscando produtos…');
    if (error != null) return AppErrorState(message: error!, onRetry: _load);
    if (items.isEmpty) {
      return const AppEmptyState(
        icon: Icons.search_off,
        title: 'Nenhum produto encontrado',
        message: 'Tente outro nome, SKU ou código de barras.',
      );
    }
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      itemCount: items.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == items.length) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final e = items[index];
        final semSaldo = !e.quantidade.isPositive;
        final checked = widget.isSelected(e.produtoId);
        return AppListRow(
          title: e.produto,
          muted: semSaldo,
          meta: semSaldo
              ? 'SKU ${e.codigoInterno} · Sem saldo para transferir'
              : 'SKU ${e.codigoInterno} · Disponível: ${_qty(e.quantidade, e.unidadeMedida)}',
          trailing: semSaldo
              ? null
              : Icon(
                  checked ? Icons.check_circle : Icons.add_circle_outline,
                  color: checked ? theme.colorScheme.primary : null,
                ),
          onTap: semSaldo
              ? null
              : () {
                  widget.onToggle(e);
                  setState(() {});
                },
        );
      },
    );
  }
}

class TransferenciaDetailPage extends StatefulWidget {
  const TransferenciaDetailPage({
    super.key,
    required this.id,
    required this.repository,
  });
  final String id;
  final EstoqueRepository repository;
  @override
  State<TransferenciaDetailPage> createState() =>
      _TransferenciaDetailPageState();
}

class _TransferenciaDetailPageState extends State<TransferenciaDetailPage> {
  late Future<TransferenciaEstoque> future;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    future = widget.repository.transferencia(widget.id);
  }

  void load() =>
      setState(() => future = widget.repository.transferencia(widget.id));
  Future<void> action(bool confirmar) async {
    setState(() => busy = true);
    try {
      confirmar
          ? await widget.repository.confirmar(widget.id)
          : await widget.repository.cancelar(widget.id);
      load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Detalhe da transferência')),
    body: FutureBuilder<TransferenciaEstoque>(
      future: future,
      builder: (context, s) {
        if (!s.hasData) {
          return s.hasError
              ? AppErrorState(message: s.error.toString(), onRetry: load)
              : const AppLoadingState(
                  label: 'Carregando transferência…',
                  layout: AppSkeletonLayout.detail,
                );
        }
        final t = s.data!;
        final theme = Theme.of(context);
        return ListView(
          children: [
            AppContent(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppPageHeader(
                    title: transferCode(t.id),
                    actions: [
                      transferStatusBadge(t.status),
                      if (t.status == 'RASCUNHO') ...[
                        OutlinedButton(
                          onPressed: busy ? null : () => action(false),
                          child: const Text('Cancelar transferência'),
                        ),
                        FilledButton(
                          onPressed: busy ? null : () => action(true),
                          child: const Text('Confirmar'),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppKeyValueGrid(
                    entries: [
                      ('Origem', 'Estoque central'),
                      ('Destino', t.destinoNome),
                      ('Responsável', t.responsavel ?? 'Sistema'),
                      ('Criada em', _date(t.createdAt)),
                      if (t.confirmedAt != null)
                        ('Confirmada em', _date(t.confirmedAt!)),
                      if (t.cancelledAt != null)
                        ('Cancelada em', _date(t.cancelledAt!)),
                    ],
                  ),
                  if (t.observacao?.isNotEmpty == true) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text(t.observacao!, style: theme.textTheme.bodyLarge),
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                  const AppSectionTitle('Itens'),
                  for (final i in t.itens)
                    AppListRow(
                      dense: true,
                      title: i.produto,
                      trailing: Text(
                        i.quantidade.friendly,
                        style: tabularFigures.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (t.movimentacoes.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxl),
                    const AppSectionTitle('Movimentações vinculadas'),
                    for (final m in t.movimentacoes)
                      AppListRow(
                        dense: true,
                        title: m.tipo.replaceAll('_', ' ').toLowerCase(),
                        meta:
                            'Saldo ${m.saldoAnterior.friendly} → ${m.saldoPosterior.friendly}',
                        trailing: Text(
                          m.quantidade.friendly,
                          style: tabularFigures,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}

String _date(DateTime date) => AppFormatters.dateTime(date);
