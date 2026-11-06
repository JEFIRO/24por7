import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_content.dart';
import '../../core/widgets/async_state.dart';
import '../../core/widgets/status_badge.dart';
import '../model/estoque_repository.dart';
import '../model/produto_repository.dart';

class EstoqueCondominioPage extends StatefulWidget {
  const EstoqueCondominioPage({super.key, this.repository});
  final EstoqueRepository? repository;
  @override
  State<EstoqueCondominioPage> createState() => _State();
}

class _State extends State<EstoqueCondominioPage> {
  late final EstoqueRepository repository;
  final _search = TextEditingController();
  List<CondominioOption> condos = const [];
  String? selected;
  List<Map<String, dynamic>> items = const [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    repository = widget.repository ?? EstoqueRepository();
    loadCondos();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> loadCondos() async {
    try {
      condos = await repository.condominios();
      selected = condos.isEmpty ? null : condos.first.id;
      await load();
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> load() async {
    if (selected == null) return;
    setState(() => loading = true);
    try {
      final data = await repository.client.get(
        '/condominios/$selected/estoque',
      );
      items = (data as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
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
              (e['codigoInterno']?.toString().toLowerCase() ?? '').contains(
                query,
              ),
        )
        .toList();
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
    return Scaffold(
      appBar: AppBar(title: const Text('Estoque dos condomínios')),
      body: ListView(
        children: [
          AppContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saldos mudam apenas por transferências e vendas; esta tela não edita quantidades.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Wrap(
                  spacing: AppSpacing.xl,
                  runSpacing: AppSpacing.md,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  children: [
                    SizedBox(
                      width: mobile ? double.infinity : 280,
                      child: DropdownButtonFormField<String>(
                        initialValue: selected,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Condomínio',
                        ),
                        items: condos
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.nome),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          selected = v;
                          load();
                        },
                      ),
                    ),
                    SizedBox(
                      width: mobile ? double.infinity : 360,
                      child: AppSearchField(
                        controller: _search,
                        hintText: 'Buscar por nome ou SKU',
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                if (loading)
                  const AppLoadingState(label: 'Carregando estoque…')
                else if (error != null)
                  AppErrorState(message: error!, onRetry: load)
                else if (visible.isEmpty)
                  const AppEmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'Nenhum produto disponível neste condomínio',
                    message:
                        'Use uma transferência do estoque central para abastecer o mercado.',
                  )
                else if (mobile)
                  for (final e in visible)
                    AppListRow(
                      title: e['produto']?.toString() ?? 'Produto',
                      meta: e['codigoInterno']?.toString(),
                      muted: e['ativo'] == false,
                      trailing: Text(
                        _qty(e['quantidade']),
                        style: tabularFigures.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
                                  if (e['codigoInterno'] != null)
                                    Text(
                                      'SKU ${e['codigoInterno']}',
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
                            DataCell(Text(e['categoria']?.toString() ?? '—')),
                            DataCell(
                              Text(
                                _qty(e['quantidade']),
                                style: tabularFigures,
                              ),
                            ),
                            DataCell(
                              e['ativo'] == false
                                  ? const AppStatusBadge(label: 'Inativo')
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
