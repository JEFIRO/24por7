import 'package:flutter/material.dart';

import '../../core/widgets/app_refresh.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_content.dart';
import '../../core/widgets/async_state.dart';
import '../../core/widgets/status_badge.dart';
import '../model/decimal_value.dart';
import '../model/promocao.dart';
import '../model/promocao_repository.dart';
import 'promocao_detail_page.dart';
import 'promocao_form_page.dart';

class PromocaoListPage extends StatefulWidget {
  const PromocaoListPage({super.key, this.repository});
  final PromocaoRepository? repository;
  @override
  State<PromocaoListPage> createState() => _PromocaoListPageState();
}

class _PromocaoListPageState extends State<PromocaoListPage> {
  late final PromocaoRepository _repository =
      widget.repository ?? PromocaoRepository();
  List<Promocao> _items = const [];
  List<CondominioResumo> _condominios = const [];
  AbrangenciaPromocao? _scope;
  StatusPromocao? _status;
  String? _condominioId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _repository.listar(
          abrangencia: _scope,
          status: _status,
          condominioId: _condominioId,
        ),
        if (_condominios.isEmpty)
          _repository.condominios()
        else
          Future.value(_condominios),
      ]);
      if (mounted) {
        setState(() {
          _items = results[0] as List<Promocao>;
          _condominios = results[1] as List<CondominioResumo>;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm([Promocao? promotion]) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PromocaoFormPage(repository: _repository, promocao: promotion),
      ),
    );
    if (changed == true) _load();
  }

  Future<void> _openDetail(Promocao promotion) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PromocaoDetailPage(repository: _repository, initial: promotion),
      ),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final mobile = AppBreakpoints.isMobile(context);
    return Scaffold(
      floatingActionButton: mobile
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add),
              label: const Text('Nova promoção'),
            )
          : null,
      body: AppRefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            AppContent(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppPageHeader(
                    title: 'Promoções',
                    subtitle:
                        'Preços especiais para a Empresa ou um Condomínio. O status considera as datas de início e término.',
                    actions: [
                      if (!mobile)
                        FilledButton.icon(
                          onPressed: () => _openForm(),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Nova promoção'),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      ChoiceChip(
                        label: const Text('Todas'),
                        selected: _status == null,
                        onSelected: (_) {
                          setState(() => _status = null);
                          _load();
                        },
                      ),
                      for (final status in const [
                        StatusPromocao.ativa,
                        StatusPromocao.agendada,
                        StatusPromocao.encerrada,
                        StatusPromocao.desativada,
                      ])
                        ChoiceChip(
                          label: Text(promotionStatusLabel(status)),
                          selected: _status == status,
                          onSelected: (_) {
                            setState(() => _status = status);
                            _load();
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.xl,
                    runSpacing: AppSpacing.md,
                    children: [
                      SizedBox(
                        width: mobile ? double.infinity : 200,
                        child: DropdownButtonFormField<AbrangenciaPromocao?>(
                          initialValue: _scope,
                          decoration: const InputDecoration(
                            labelText: 'Abrangência',
                          ),
                          items: const [
                            DropdownMenuItem(value: null, child: Text('Todas')),
                            DropdownMenuItem(
                              value: AbrangenciaPromocao.empresa,
                              child: Text('Empresa'),
                            ),
                            DropdownMenuItem(
                              value: AbrangenciaPromocao.condominio,
                              child: Text('Condomínio'),
                            ),
                          ],
                          onChanged: (v) {
                            setState(() {
                              _scope = v;
                              if (v == AbrangenciaPromocao.empresa) {
                                _condominioId = null;
                              }
                            });
                            _load();
                          },
                        ),
                      ),
                      SizedBox(
                        width: mobile ? double.infinity : 260,
                        child: DropdownButtonFormField<String?>(
                          initialValue: _condominioId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Condomínio',
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Todos os condomínios'),
                            ),
                            ..._condominios.map(
                              (e) => DropdownMenuItem(
                                value: e.id,
                                child: Text(e.nome),
                              ),
                            ),
                          ],
                          onChanged: _scope == AbrangenciaPromocao.empresa
                              ? null
                              : (v) {
                                  _condominioId = v;
                                  _load();
                                },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (_loading)
                    const AppLoadingState(
                      label: 'Carregando promoções…',
                      inline: true,
                    )
                  else if (_error != null)
                    AppErrorState(
                      title: 'Não foi possível carregar as promoções',
                      message: _error!,
                      onRetry: _load,
                    )
                  else if (_items.isEmpty)
                    AppEmptyState(
                      icon: Icons.local_offer_outlined,
                      title: 'Nenhuma promoção cadastrada',
                      message:
                          'Crie uma promoção para oferecer preços especiais na Empresa ou em um Condomínio.',
                      action: FilledButton(
                        onPressed: () => _openForm(),
                        child: const Text('Nova promoção'),
                      ),
                    )
                  else if (mobile)
                    for (final (i, promotion) in _items.indexed)
                      AppListRow(
                        entranceIndex: i,
                        title: promotion.nome,
                        meta:
                            '${promotionValueLabel(promotion.tipo, promotion.valor)} · '
                            '${promotionScopeLabel(promotion)}\n'
                            '${promotionDate(promotion.inicio)} – ${promotionDate(promotion.fim)}',
                        trailing: promotionStatusBadge(promotion.status),
                        onTap: () => _openDetail(promotion),
                      )
                  else
                    _table(),
                  const SizedBox(height: 88),
                ],
              ),
            ),
          ],
        ),
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
        DataColumn(label: Text('Promoção')),
        DataColumn(label: Text('Tipo')),
        DataColumn(label: Text('Valor'), numeric: true),
        DataColumn(label: Text('Abrangência')),
        DataColumn(label: Text('Período')),
        DataColumn(label: Text('Prioridade'), numeric: true),
        DataColumn(label: Text('Status')),
        DataColumn(label: SizedBox.shrink()),
      ],
      rows: [
        for (final promotion in _items)
          DataRow(
            onSelectChanged: (_) => _openDetail(promotion),
            cells: [
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(promotion.nome, style: theme.textTheme.titleSmall),
                    Text(
                      promotion.produtos.length == 1
                          ? '1 produto'
                          : '${promotion.produtos.length} produtos',
                      style: muted,
                    ),
                  ],
                ),
              ),
              DataCell(Text(promotionTypeLabel(promotion.tipo))),
              DataCell(
                Text(
                  promotionValueLabel(promotion.tipo, promotion.valor),
                  style: tabularFigures.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              DataCell(Text(promotionScopeLabel(promotion))),
              DataCell(
                Text(
                  '${promotionDate(promotion.inicio)} – ${promotionDate(promotion.fim)}',
                  style: tabularFigures,
                ),
              ),
              DataCell(Text('${promotion.prioridade}', style: tabularFigures)),
              DataCell(promotionStatusBadge(promotion.status)),
              const DataCell(Icon(Icons.chevron_right)),
            ],
          ),
      ],
    );
  }
}

String promotionStatusLabel(StatusPromocao status) => switch (status) {
  StatusPromocao.ativa => 'Ativa',
  StatusPromocao.agendada => 'Agendada',
  StatusPromocao.encerrada => 'Encerrada',
  StatusPromocao.desativada => 'Desativada',
};

AppStatusBadge promotionStatusBadge(StatusPromocao status) => AppStatusBadge(
  label: promotionStatusLabel(status),
  tone: switch (status) {
    StatusPromocao.ativa => AppStatusTone.success,
    StatusPromocao.agendada => AppStatusTone.info,
    _ => AppStatusTone.neutral,
  },
);

String promotionTypeLabel(TipoPromocao tipo) => switch (tipo) {
  TipoPromocao.percentual => 'Percentual',
  TipoPromocao.descontoFixo => 'Desconto fixo',
  TipoPromocao.precoFixo => 'Preço fixo',
};

String promotionValueLabel(TipoPromocao tipo, DecimalValue valor) =>
    switch (tipo) {
      TipoPromocao.percentual => '${valor.friendly}% de desconto',
      TipoPromocao.descontoFixo => '${valor.currency} de desconto',
      TipoPromocao.precoFixo => 'Por ${valor.currency}',
    };

String promotionScopeLabel(Promocao promotion) =>
    promotion.abrangencia == AbrangenciaPromocao.empresa
    ? 'Empresa'
    : promotion.condominioNome?.isNotEmpty == true
    ? promotion.condominioNome!
    : 'Condomínio';

String promotionDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
