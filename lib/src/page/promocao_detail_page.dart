import 'package:flutter/material.dart';

import '../../core/formatters/app_formatters.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_content.dart';
import '../model/promocao.dart';
import '../model/promocao_repository.dart';
import 'promocao_form_page.dart';
import 'promocao_list_page.dart';

class PromocaoDetailPage extends StatefulWidget {
  const PromocaoDetailPage({
    super.key,
    required this.repository,
    required this.initial,
  });
  final PromocaoRepository repository;
  final Promocao initial;
  @override
  State<PromocaoDetailPage> createState() => _PromocaoDetailPageState();
}

class _PromocaoDetailPageState extends State<PromocaoDetailPage> {
  late Promocao _promotion = widget.initial;
  bool _working = false;

  Future<void> _edit() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PromocaoFormPage(
          repository: widget.repository,
          promocao: _promotion,
        ),
      ),
    );
    if (changed == true) {
      final updated = await widget.repository.buscar(_promotion.id);
      if (mounted) setState(() => _promotion = updated);
    }
  }

  Future<void> _toggle() async {
    if (_promotion.ativo) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Desativar promoção?'),
          content: Text(
            '${_promotion.nome} deixa de valer imediatamente. Você pode ativá-la de novo depois.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Desativar'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    setState(() => _working = true);
    try {
      final updated = await widget.repository.alterarStatus(
        _promotion.id,
        !_promotion.ativo,
      );
      if (mounted) setState(() => _promotion = updated);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  String _promotionalPrice(ProdutoResumo product) {
    final price = double.tryParse(product.preco.value) ?? 0;
    final value = double.tryParse(_promotion.valor.value) ?? 0;
    final result = switch (_promotion.tipo) {
      TipoPromocao.percentual => price * (1 - value / 100),
      TipoPromocao.descontoFixo => price - value,
      TipoPromocao.precoFixo => value,
    };
    return AppFormatters.currencyText(
      (result < 0 ? 0 : result).toStringAsFixed(2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mobile = AppBreakpoints.isMobile(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes da promoção')),
      body: ListView(
        children: [
          AppContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppPageHeader(
                  title: _promotion.nome,
                  subtitle: _promotion.descricao?.isNotEmpty == true
                      ? _promotion.descricao
                      : null,
                  actions: [
                    promotionStatusBadge(_promotion.status),
                    OutlinedButton(
                      onPressed: _working ? null : _toggle,
                      child: Text(_promotion.ativo ? 'Desativar' : 'Ativar'),
                    ),
                    FilledButton.icon(
                      onPressed: _working ? null : _edit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Editar'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
                AppKeyValueGrid(
                  entries: [
                    ('Tipo', promotionTypeLabel(_promotion.tipo)),
                    (
                      'Valor',
                      promotionValueLabel(_promotion.tipo, _promotion.valor),
                    ),
                    (
                      _promotion.abrangencia == AbrangenciaPromocao.empresa
                          ? 'Abrangência'
                          : 'Condomínio',
                      promotionScopeLabel(_promotion),
                    ),
                    ('Prioridade', '${_promotion.prioridade}'),
                    ('Início', AppFormatters.dateTime(_promotion.inicio)),
                    ('Término', AppFormatters.dateTime(_promotion.fim)),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
                AppSectionTitle(
                  _promotion.produtos.length == 1
                      ? 'Produtos (1)'
                      : 'Produtos (${_promotion.produtos.length})',
                ),
                if (_promotion.produtos.isEmpty)
                  Text(
                    'Nenhum produto associado.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                else if (mobile)
                  for (final product in _promotion.produtos)
                    AppListRow(
                      dense: true,
                      title: product.nome,
                      meta: '${product.codigo} · de ${product.preco.currency}',
                      trailing: Text(
                        _promotionalPrice(product),
                        style: tabularFigures.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                else
                  AppTable(
                    columns: const [
                      DataColumn(label: Text('Produto')),
                      DataColumn(label: Text('Código')),
                      DataColumn(label: Text('Preço'), numeric: true),
                      DataColumn(
                        label: Text('Preço promocional'),
                        numeric: true,
                      ),
                    ],
                    rows: [
                      for (final product in _promotion.produtos)
                        DataRow(
                          cells: [
                            DataCell(Text(product.nome)),
                            DataCell(
                              Text(product.codigo, style: tabularFigures),
                            ),
                            DataCell(
                              Text(
                                product.preco.currency,
                                style: tabularFigures,
                              ),
                            ),
                            DataCell(
                              Text(
                                _promotionalPrice(product),
                                style: tabularFigures.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
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
