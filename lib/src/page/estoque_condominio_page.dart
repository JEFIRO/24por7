import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Estoque dos condomínios')),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: DropdownButtonFormField<String>(
            initialValue: selected,
            decoration: const InputDecoration(labelText: 'Condomínio'),
            items: condos
                .map((c) => DropdownMenuItem(value: c.id, child: Text(c.nome)))
                .toList(),
            onChanged: (v) {
              selected = v;
              load();
            },
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : error != null
              ? Center(child: Text(error!))
              : items.isEmpty
              ? const Center(
                  child: Text('Nenhum produto disponível neste condomínio'),
                )
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final e = items[i];
                    return ListTile(
                      title: Text(e['produto']?.toString() ?? 'Produto'),
                      subtitle: Text(e['ativo'] == false ? 'Inativo' : 'Ativo'),
                      trailing: Text(e['quantidade']?.toString() ?? '0.000'),
                    );
                  },
                ),
        ),
      ],
    ),
  );
}
