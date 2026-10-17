import 'package:flutter/material.dart';
import '../../core/formatters/app_formatters.dart';
import '../model/decimal_value.dart';
import '../model/estoque.dart';
import '../model/estoque_repository.dart';
import '../model/produto_repository.dart';

class TransferenciaEstoquePage extends StatefulWidget {
  const TransferenciaEstoquePage({super.key, this.repository});
  final EstoqueRepository? repository;
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
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Transferências'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () async {
        final changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => TransferenciaFormPage(repository: repository),
          ),
        );
        if (changed == true) load();
      },
      icon: const Icon(Icons.add),
      label: const Text('NOVA'),
    ),
    body: FutureBuilder<List<TransferenciaEstoque>>(
      future: future,
      builder: (context, s) {
        if (s.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (s.hasError) return Center(child: Text(s.error.toString()));
        final items = s.data ?? const [];
        if (items.isEmpty) {
          return const Center(child: Text('Nenhuma transferência registrada'));
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final t = items[i];
            return Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.local_shipping)),
                title: Text('TRF-${t.id.substring(0, 8).toUpperCase()}'),
                subtitle: Text(
                  'Estoque central → ${t.destinoNome}\n${t.itens.length} item(ns) • ${_date(t.createdAt)}',
                ),
                isThreeLine: true,
                trailing: Chip(label: Text(t.status.replaceAll('_', ' '))),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TransferenciaDetailPage(
                        id: t.id,
                        repository: repository,
                      ),
                    ),
                  );
                  load();
                },
              ),
            );
          },
        );
      },
    ),
  );
}

class TransferenciaFormPage extends StatefulWidget {
  const TransferenciaFormPage({super.key, required this.repository});
  final EstoqueRepository repository;
  @override
  State<TransferenciaFormPage> createState() => _TransferenciaFormPageState();
}

class _TransferenciaFormPageState extends State<TransferenciaFormPage> {
  List<EstoqueCentral> estoque = const [];
  List<CondominioOption> condos = const [];
  final selected = <String, TextEditingController>{};
  final obs = TextEditingController();
  String? destino;
  bool loading = true;
  bool saving = false;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    for (final c in selected.values) {
      c.dispose();
    }
    obs.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final result = await Future.wait([
        widget.repository.listarCentral(ativo: true),
        widget.repository.condominios(),
      ]);
      estoque = result[0] as List<EstoqueCentral>;
      condos = result[1] as List<CondominioOption>;
      destino = condos.isEmpty ? null : condos.first.id;
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Nova transferência')),
    bottomNavigationBar: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: saving ? null : confirmar,
          icon: saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
          label: const Text('REVISAR E CONFIRMAR'),
        ),
      ),
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : error != null
        ? Center(child: Text(error!))
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Origem',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.warehouse),
                title: Text('Estoque central'),
              ),
              DropdownButtonFormField<String>(
                initialValue: destino,
                decoration: const InputDecoration(
                  labelText: 'Condomínio de destino',
                ),
                items: condos
                    .map(
                      (c) => DropdownMenuItem(value: c.id, child: Text(c.nome)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => destino = v),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: obs,
                maxLength: 600,
                decoration: const InputDecoration(labelText: 'Observação'),
              ),
              Text(
                'Produtos (${selected.length} selecionado(s))',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...estoque.map((e) {
                final checked = selected.containsKey(e.produtoId);
                return Card(
                  child: Column(
                    children: [
                      CheckboxListTile(
                        value: checked,
                        title: Text(e.produto),
                        subtitle: Text(
                          'Disponível: ${e.quantidade.friendly} ${e.unidadeMedida}',
                        ),
                        onChanged: (v) => setState(() {
                          if (v == true) {
                            selected[e.produtoId] = TextEditingController();
                          } else {
                            selected.remove(e.produtoId)?.dispose();
                          }
                        }),
                      ),
                      if (checked)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: TextField(
                            controller: selected[e.produtoId],
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Quantidade a transferir',
                              helperText: 'Até 3 casas decimais',
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ),
  );
  Future<void> confirmar() async {
    if (destino == null || selected.isEmpty) {
      _message('Selecione o destino e pelo menos um produto');
      return;
    }
    final itens = <TransferenciaItem>[];
    try {
      for (final e in estoque.where((e) => selected.containsKey(e.produtoId))) {
        final raw = selected[e.produtoId]!.text.trim();
        if (!RegExp(r'^\d+([\.,]\d{1,3})?$').hasMatch(raw)) {
          throw const FormatException(
            'Use quantidade positiva com até 3 casas',
          );
        }
        final q = DecimalValue.parse(raw);
        if (!q.isPositive) {
          throw const FormatException('Quantidade deve ser positiva');
        }
        itens.add(
          TransferenciaItem(
            produtoId: e.produtoId,
            produto: e.produto,
            quantidade: q,
          ),
        );
      }
    } catch (e) {
      _message(e.toString());
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar transferência'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Estoque central → Condomínio'),
            const SizedBox(height: 12),
            ...itens.map((e) => Text('${e.produto}: ${e.quantidade.friendly}')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('VOLTAR'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('CONFIRMAR TRANSFERÊNCIA'),
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
              ? Center(child: Text(s.error.toString()))
              : const Center(child: CircularProgressIndicator());
        }
        final t = s.data!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'TRF-${t.id.substring(0, 8).toUpperCase()}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Chip(label: Text(t.status)),
            const Divider(),
            _row('Origem', 'Estoque central'),
            _row('Destino', t.destinoNome),
            _row('Responsável', t.responsavel ?? 'Sistema'),
            _row('Criada', _date(t.createdAt)),
            if (t.confirmedAt != null)
              _row('Confirmada', _date(t.confirmedAt!)),
            if (t.cancelledAt != null) _row('Cancelada', _date(t.cancelledAt!)),
            if (t.observacao?.isNotEmpty == true)
              _row('Observação', t.observacao!),
            const SizedBox(height: 16),
            Text('Itens', style: Theme.of(context).textTheme.titleMedium),
            ...t.itens.map(
              (i) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(i.produto),
                trailing: Text(i.quantidade.friendly),
              ),
            ),
            if (t.movimentacoes.isNotEmpty) ...[
              const Divider(),
              Text(
                'Movimentações vinculadas',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              ...t.movimentacoes.map(
                (m) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(m.tipo.replaceAll('_', ' ')),
                  subtitle: Text(
                    '${m.saldoAnterior.friendly} → ${m.saldoPosterior.friendly}',
                  ),
                ),
              ),
            ],
            if (t.status == 'RASCUNHO')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: busy ? null : () => action(false),
                      child: const Text('CANCELAR'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: busy ? null : () => action(true),
                      child: const Text('CONFIRMAR'),
                    ),
                  ),
                ],
              ),
          ],
        );
      },
    ),
  );
}

Widget _row(String label, String value) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 6),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 110,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      Expanded(child: Text(value)),
    ],
  ),
);
String _date(DateTime date) => AppFormatters.dateTime(date);
