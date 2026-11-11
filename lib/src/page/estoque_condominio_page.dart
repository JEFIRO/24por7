import 'package:flutter/material.dart';

import '../../core/widgets/app_refresh.dart';
import '../../core/formatters/produto_labels.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_content.dart';
import '../../core/widgets/async_state.dart';
import '../../core/widgets/status_badge.dart';
import '../model/decimal_value.dart';
import '../model/estoque_repository.dart';
import '../model/produto.dart';
import 'estoque_produto_page.dart';
import 'transferencia_estoque_page.dart';

/// Saldos do mercado de um Condomínio. É uma aba da tela de Estoque: não tem
/// Scaffold próprio e recebe o cabeçalho de quem a hospeda.
class EstoqueCondominioPage extends StatefulWidget {
  const EstoqueCondominioPage({
    super.key,
    required this.condominioId,
    this.repository,
    this.header,
  });
  final String condominioId;
  final EstoqueRepository? repository;
  final Widget? header;
  @override
  State<EstoqueCondominioPage> createState() => _State();
}

class _State extends State<EstoqueCondominioPage> {
  late final EstoqueRepository repository;
  final _search = TextEditingController();
  List<Map<String, dynamic>> items = const [];
  // A API do mercado só devolve nome e saldo; SKU, categoria e unidade vêm
  // do catálogo.
  Map<String, Produto> produtos = const {};
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    repository = widget.repository ?? EstoqueRepository();
    load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final catalogo = repository.catalogo();
      items = await repository.estoqueCondominio(widget.condominioId);
      produtos = await catalogo;
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  List<Map<String, dynamic>> get _visible {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return items;
    return items
        .where(
          (e) =>
              (e['produto']?.toString().toLowerCase() ?? '').contains(query) ||
              (_sku(e)?.toLowerCase() ?? '').contains(query),
        )
        .toList();
  }

  Produto? _produto(Map<String, dynamic> e) => produtos[e['produtoId']];

  String? _sku(Map<String, dynamic> e) =>
      e['codigoInterno']?.toString() ?? _produto(e)?.codigoInterno;

  String _categoria(Map<String, dynamic> e) {
    final raw = e['categoria']?.toString() ?? _produto(e)?.categoria;
    return raw == null || raw.isEmpty ? '—' : ProdutoLabels.categoria(raw);
  }

  String _saldo(Map<String, dynamic> e) {
    final unidade =
        e['unidadeMedida']?.toString() ?? _produto(e)?.unidadeMedida;
    return unidade == null
        ? _qty(e['quantidade'])
        : '${_qty(e['quantidade'])} $unidade';
  }

  /// Texto do aviso de estoque baixo, ou null quando o saldo está em dia.
  String? _baixo(Map<String, dynamic> e) {
    if (e['ativo'] == false || e['abaixoDoMinimo'] != true) return null;
    return 'Estoque baixo (mín. ${_qtyCurta(e['estoqueMinimo'])})';
  }

  static String _qtyCurta(Object? value) => value == null
      ? '—'
      : DecimalValue.fromJson(value).friendly.replaceAll('.', ',');

  Future<void> _abrir(Map<String, dynamic> e) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EstoqueProdutoPage(
          produtoId: e['produtoId'].toString(),
          nome: e['produto']?.toString() ?? 'Produto',
          repository: repository,
        ),
      ),
    );
    if (mounted) await load();
  }

  Future<void> _abastecer() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransferenciaFormPage(
          repository: repository,
          destinoInicial: widget.condominioId,
        ),
      ),
    );
    if (mounted) await load();
  }

  static String _qty(Object? value) {
    final number = double.tryParse(value?.toString() ?? '') ?? 0;
    return number.toStringAsFixed(3).replaceAll('.', ',');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mobile = AppBreakpoints.isMobile(context);
    final visible = _visible;
    return AppRefreshIndicator(
      onRefresh: load,
      child: ListView(
        children: [
          AppContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ?widget.header,
                SizedBox(
                  width: mobile ? double.infinity : 420,
                  child: AppSearchField(
                    controller: _search,
                    hintText: 'Buscar por nome ou SKU',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'O saldo do mercado muda por transferências e vendas.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (loading)
                  const AppLoadingState(
                    label: 'Carregando estoque…',
                    inline: true,
                  )
                else if (error != null)
                  AppErrorState(message: error!, onRetry: load)
                else if (items.isEmpty)
                  AppEmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'Nenhum produto disponível neste condomínio',
                    message:
                        'Transfira produtos do estoque central para abastecer o mercado.',
                    action: FilledButton.icon(
                      onPressed: _abastecer,
                      icon: const Icon(Icons.local_shipping_outlined, size: 18),
                      label: const Text('Abastecer este condomínio'),
                    ),
                  )
                else if (visible.isEmpty)
                  const AppEmptyState(
                    icon: Icons.search_off,
                    title: 'Nenhum produto encontrado',
                    message: 'Tente outro nome ou SKU.',
                  )
                else if (mobile)
                  for (final e in visible)
                    AppListRow(
                      title: e['produto']?.toString() ?? 'Produto',
                      meta: [
                        if (_sku(e) != null) 'SKU ${_sku(e)}',
                        ?_baixo(e),
                      ].join('\n').nullIfEmpty,
                      muted: e['ativo'] == false,
                      trailing: Text(
                        _saldo(e),
                        style: tabularFigures.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () => _abrir(e),
                    )
                else
                  AppTable(
                    columns: const [
                      DataColumn(label: Text('Produto')),
                      DataColumn(label: Text('Categoria')),
                      DataColumn(
                        label: Text('Saldo no mercado'),
                        numeric: true,
                      ),
                      DataColumn(label: Text('Status')),
                    ],
                    rows: [
                      for (final e in visible)
                        DataRow(
                          onSelectChanged: (_) => _abrir(e),
                          cells: [
                            DataCell(
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e['produto']?.toString() ?? 'Produto',
                                    style: theme.textTheme.titleSmall,
                                  ),
                                  if (_sku(e) != null)
                                    Text(
                                      'SKU ${_sku(e)}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                ],
                              ),
                            ),
                            DataCell(Text(_categoria(e))),
                            DataCell(Text(_saldo(e), style: tabularFigures)),
                            DataCell(
                              e['ativo'] == false
                                  ? const AppStatusBadge(label: 'Inativo')
                                  : _baixo(e) != null
                                  ? AppStatusBadge(
                                      label: _baixo(e)!,
                                      tone: AppStatusTone.warning,
                                    )
                                  : const AppStatusBadge(
                                      label: 'Ativo',
                                      tone: AppStatusTone.success,
                                    ),
                            ),
                          ],
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
