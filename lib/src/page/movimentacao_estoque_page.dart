import 'package:flutter/material.dart';
import '../model/estoque.dart';
import '../model/estoque_repository.dart';

class MovimentacaoEstoquePage extends StatefulWidget {
  const MovimentacaoEstoquePage({super.key, this.repository});
  final EstoqueRepository? repository;
  @override
  State<MovimentacaoEstoquePage> createState() =>
      _MovimentacaoEstoquePageState();
}

class _MovimentacaoEstoquePageState extends State<MovimentacaoEstoquePage> {
  late final EstoqueRepository repository;
  late Future<List<MovimentoEstoque>> future;
  @override
  void initState() {
    super.initState();
    repository = widget.repository ?? EstoqueRepository();
    future = repository.movimentos();
  }

  void reload() => setState(() => future = repository.movimentos());
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Movimentações'),
      actions: [IconButton(onPressed: reload, icon: const Icon(Icons.refresh))],
    ),
    body: FutureBuilder<List<MovimentoEstoque>>(
      future: future,
      builder: (context, s) {
        if (s.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (s.hasError) return Center(child: Text(s.error.toString()));
        final items = s.data ?? const [];
        if (items.isEmpty) {
          return const Center(
            child: Text('Nenhuma movimentação no estoque central'),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final m = items[i];
            return Card(
              child: ListTile(
                leading: Icon(
                  m.quantidade.isNegative
                      ? Icons.remove_circle
                      : Icons.add_circle,
                ),
                title: Text(m.tipo.replaceAll('_', ' ')),
                subtitle: Text(
                  '${m.motivo ?? 'Sem motivo'}${m.responsavel == null ? '' : ' • ${m.responsavel}'}\n${m.saldoAnterior.friendly} → ${m.saldoPosterior.friendly}',
                ),
                trailing: Text(m.quantidade.friendly),
              ),
            );
          },
        );
      },
    ),
  );
}
