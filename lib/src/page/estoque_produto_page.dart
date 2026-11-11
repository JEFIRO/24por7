import 'package:flutter/material.dart';

import '../../core/formatters/app_formatters.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_content.dart';
import '../../core/widgets/async_state.dart';
import '../../core/widgets/status_badge.dart';
import '../model/decimal_value.dart';
import '../model/estoque.dart';
import '../model/estoque_repository.dart';
import '../model/produto.dart';
import '../model/produto_repository.dart';
import 'estoque_central_page.dart';
import 'movimentacao_estoque_page.dart';
import 'transferencia_estoque_page.dart';

/// Estoque de um produto: saldo no central e em cada Condomínio, o histórico
/// em todos os locais e as correções de saldo.
class EstoqueProdutoPage extends StatefulWidget {
  const EstoqueProdutoPage({
    super.key,
    required this.produtoId,
    required this.nome,
    this.central,
    this.repository,
  });
  final String produtoId;
  final String nome;

  /// Saldo central já conhecido por quem abriu a página.
  final EstoqueCentral? central;
  final EstoqueRepository? repository;

  @override
  State<EstoqueProdutoPage> createState() => _EstoqueProdutoPageState();
}

class _EstoqueProdutoPageState extends State<EstoqueProdutoPage> {
  static const _centralNome = 'Estoque central';

  late final EstoqueRepository _repository;
  late EstoqueCentral? _central = widget.central;
  Produto? _produto;
  List<ProdutoCondominioDisponibilidade>? _condos;
  String? _condosErro;
  List<(MovimentoEstoque, String)>? _historico;
  String? _historicoErro;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? EstoqueRepository();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    final id = widget.produtoId;
    final condosFuture = _repository.saldosNosCondominios(id);
    final centralMovsFuture = _repository.movimentos();
    // Os erros são tratados abaixo, quando cada future é aguardado.
    condosFuture.ignore();
    centralMovsFuture.ignore();

    final produto = (await _repository.catalogo())[id];
    EstoqueCentral? central = _central;
    try {
      central = await _repository.centralDoProduto(
        id,
        busca: central?.codigoInterno ?? produto?.codigoInterno ?? widget.nome,
      );
    } catch (_) {
      // Mantém o saldo recebido de quem abriu a página.
    }

    List<ProdutoCondominioDisponibilidade>? condos;
    String? condosErro;
    try {
      condos = (await condosFuture).where((c) => c.associado).toList();
    } catch (e) {
      condosErro = e.toString();
    }

    List<(MovimentoEstoque, String)>? historico;
    String? historicoErro;
    try {
      // A API lista a trilha por local; o filtro por produto é feito aqui.
      final porCondominio = await Future.wait([
        for (final c in condos ?? const <ProdutoCondominioDisponibilidade>[])
          _repository.movimentos(condominioId: c.condominioId),
      ]);
      historico = [
        for (final m in await centralMovsFuture)
          if (m.produtoId == id) (m, _centralNome),
        for (final (i, movimentos) in porCondominio.indexed)
          for (final m in movimentos)
            if (m.produtoId == id) (m, condos![i].condominioNome),
      ]..sort((a, b) => b.$1.createdAt.compareTo(a.$1.createdAt));
    } catch (e) {
      historicoErro = e.toString();
    }

    if (!mounted) return;
    setState(() {
      _produto = produto;
      _central = central;
      _condos = condos;
      _condosErro = condosErro;
      _historico = historico;
      _historicoErro = historicoErro;
      _loading = false;
    });
  }

  String get _unidade =>
      _central?.unidadeMedida ?? _produto?.unidadeMedida ?? '';

  String _qtd(DecimalValue? value) =>
      '${(value ?? DecimalValue.parse('0')).friendly} $_unidade'.trim();

  Future<void> _corrigir() async {
    final changed = await movimentarEstoqueCentral(
      context,
      _repository,
      item: _central,
    );
    if (changed && mounted) await _carregar();
  }

  Future<void> _abastecer({String? destino}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransferenciaFormPage(
          repository: _repository,
          destinoInicial: destino,
          itemInicial: _central,
        ),
      ),
    );
    if (mounted) await _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final sku = _central?.codigoInterno ?? _produto?.codigoInterno;
    final ativo = _central?.ativo ?? _produto?.ativo ?? true;
    final central = _central;
    final mobile = AppBreakpoints.isMobile(context);
    final acoes = central == null
        ? null
        : Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              OutlinedButton(
                onPressed: _corrigir,
                child: const Text('Corrigir saldo'),
              ),
              FilledButton(
                onPressed: _abastecer,
                child: const Text('Abastecer condomínio'),
              ),
            ],
          );
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.nome, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pushNamed(context, '/produtos/${widget.produtoId}'),
            child: const Text('Abrir cadastro'),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _carregar,
        child: ListView(
          children: [
            AppContent(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (sku != null && sku.isNotEmpty)
                        Text('SKU $sku', style: muted),
                      ativo
                          ? const AppStatusBadge(
                              label: 'Ativo',
                              tone: AppStatusTone.success,
                            )
                          : const AppStatusBadge(label: 'Inativo'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppSectionTitle(
                    'Saldo por local',
                    trailing: mobile ? null : acoes,
                  ),
                  // No celular os dois botões não cabem ao lado do título.
                  if (mobile && acoes != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    acoes,
                  ],
                  const SizedBox(height: AppSpacing.md),
                  AppListRow(
                    leading: const AppIconWell(Icons.warehouse_outlined),
                    title: _centralNome,
                    meta: central == null
                        ? (_loading
                              ? null
                              : 'Este produto ainda não entrou no central')
                        : (central.localizacao?.isNotEmpty == true
                              ? 'Localização ${central.localizacao}'
                              : 'Sem localização'),
                    trailing: Text(
                      central == null ? '—' : _qtd(central.quantidade),
                      style: tabularFigures.copyWith(
                        fontWeight: FontWeight.w600,
                        color: central?.quantidade.isNegative == true
                            ? theme.colorScheme.error
                            : null,
                      ),
                    ),
                  ),
                  ..._condominios(muted),
                  const SizedBox(height: AppSpacing.xxl),
                  const AppSectionTitle(
                    'Histórico',
                    subtitle: 'Movimentações deste produto em todos os locais.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _historicoWidget(),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _condominios(TextStyle? muted) {
    final condos = _condos;
    if (condos == null) {
      return [
        if (_condosErro != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: AppBanner(
              tone: AppStatusTone.critical,
              message:
                  'Não foi possível carregar o saldo nos condomínios. $_condosErro',
              action: TextButton(
                onPressed: _carregar,
                child: const Text('Tentar novamente'),
              ),
            ),
          )
        else
          const AppLoadingState(label: 'Carregando saldo nos condomínios…'),
      ];
    }
    if (condos.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: Text('Ainda não está em nenhum condomínio.', style: muted),
        ),
      ];
    }
    return [
      for (final c in condos)
        AppListRow(
          leading: const AppIconWell(Icons.apartment_outlined),
          title: c.condominioNome,
          trailing: Text(
            _qtd(c.quantidade),
            style: tabularFigures.copyWith(fontWeight: FontWeight.w600),
          ),
          onTap: _central == null
              ? null
              : () => _abastecer(destino: c.condominioId),
        ),
    ];
  }

  Widget _historicoWidget() {
    final historico = _historico;
    if (historico == null) {
      return _historicoErro != null
          ? AppErrorState(message: _historicoErro!, onRetry: _carregar)
          : const AppLoadingState(label: 'Carregando histórico…');
    }
    if (historico.isEmpty) {
      return const AppEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'Nenhuma movimentação deste produto',
        message: 'Entradas, transferências, vendas e ajustes aparecem aqui.',
      );
    }
    if (AppBreakpoints.isMobile(context)) {
      return Column(
        children: [
          for (final (m, local) in historico)
            AppListRow(
              title: '${movimentoTipoLabel(m.tipo)} · $local',
              meta:
                  '${AppFormatters.dateTime(m.createdAt)} · ${m.responsavel ?? 'Sistema'}\n'
                  '${m.motivo ?? 'Sem motivo'}',
              trailing: MovimentoQuantidade(m.quantidade.friendly, m),
            ),
        ],
      );
    }
    return AppTable(
      columns: const [
        DataColumn(label: Text('Data e hora')),
        DataColumn(label: Text('Local')),
        DataColumn(label: Text('Tipo')),
        DataColumn(label: Text('Quantidade'), numeric: true),
        DataColumn(label: Text('Saldo após'), numeric: true),
        DataColumn(label: Text('Motivo')),
        DataColumn(label: Text('Responsável')),
      ],
      rows: [
        for (final (m, local) in historico)
          DataRow(
            cells: [
              DataCell(
                Text(
                  AppFormatters.dateTime(m.createdAt),
                  style: tabularFigures,
                ),
              ),
              DataCell(Text(local)),
              DataCell(Text(movimentoTipoLabel(m.tipo))),
              DataCell(MovimentoQuantidade(m.quantidade.friendly, m)),
              DataCell(Text(m.saldoPosterior.friendly, style: tabularFigures)),
              DataCell(Text(m.motivo ?? 'Sem motivo')),
              DataCell(Text(m.responsavel ?? 'Sistema')),
            ],
          ),
      ],
    );
  }
}
