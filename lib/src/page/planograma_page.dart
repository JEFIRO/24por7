import 'package:flutter/material.dart';
import '../model/produto.dart';
import '../model/estoque.dart';
import '../model/estoque_repository.dart';

class PlanogramaPage extends StatefulWidget {
  const PlanogramaPage({super.key, this.repository});
  final EstoqueRepository? repository;
  @override
  State<PlanogramaPage> createState() => _PlanogramaPageState();
}

class _PlanogramaPageState extends State<PlanogramaPage> {
  late final EstoqueRepository repository;
  late Future<List<Planograma>> future;
  @override
  void initState() {
    super.initState();
    repository = widget.repository ?? EstoqueRepository();
    future = repository.planogramas();
  }

  void load() => setState(() => future = repository.planogramas());
  Future<void> create() async {
    final nome = TextEditingController();
    final descricao = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo planograma'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nome,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            TextField(
              controller: descricao,
              decoration: const InputDecoration(labelText: 'Descrição'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('CRIAR'),
          ),
        ],
      ),
    );
    if (ok == true && nome.text.trim().isNotEmpty) {
      try {
        await repository.criarPlanograma(
          nome.text.trim(),
          descricao.text.trim(),
        );
        load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Planograma')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: create,
      icon: const Icon(Icons.add),
      label: const Text('NOVO'),
    ),
    body: FutureBuilder<List<Planograma>>(
      future: future,
      builder: (context, s) {
        if (!s.hasData) {
          return s.hasError
              ? Center(child: Text(s.error.toString()))
              : const Center(child: CircularProgressIndicator());
        }
        final items = s.data!;
        if (items.isEmpty) {
          return const Center(
            child: Text(
              'Planograma é opcional.\nNenhum foi criado.',
              textAlign: TextAlign.center,
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final p = items[i];
            return Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.view_module)),
                title: Text(p.nome),
                subtitle: Text(
                  '${p.posicoes.length} posição(ões) • ${p.ativo ? 'Ativo' : 'Inativo'}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlanogramaDetailPage(
                        planograma: p,
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

class PlanogramaDetailPage extends StatefulWidget {
  const PlanogramaDetailPage({
    super.key,
    required this.planograma,
    required this.repository,
  });
  final Planograma planograma;
  final EstoqueRepository repository;
  @override
  State<PlanogramaDetailPage> createState() => _PlanogramaDetailPageState();
}

class _PlanogramaDetailPageState extends State<PlanogramaDetailPage> {
  late Planograma planograma;
  @override
  void initState() {
    super.initState();
    planograma = widget.planograma;
  }

  Future<void> addPosition() async {
    final setor = TextEditingController(),
        corredor = TextEditingController(),
        estante = TextEditingController(),
        prateleira = TextEditingController(),
        posicao = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova posição'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(setor, 'Setor'),
              _field(corredor, 'Corredor'),
              _field(estante, 'Estante'),
              _field(prateleira, 'Prateleira'),
              _field(posicao, 'Posição'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('SALVAR'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        final result = await widget.repository.adicionarPosicao(planograma.id, {
          'setor': setor.text,
          'corredor': corredor.text,
          'estante': estante.text,
          'prateleira': prateleira.text,
          'posicao': posicao.text,
          'ordem': planograma.posicoes.length + 1,
        });
        setState(() => planograma = result);
      } catch (e) {
        _message(e);
      }
    }
  }

  Future<void> addProduct(PlanogramaPosicao posicao) async {
    List<Produto> products;
    try {
      products = await widget.repository.listarProdutos();
    } catch (e) {
      _message(e);
      return;
    }
    if (!mounted || products.isEmpty) return;
    String id = products.first.id!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text('Produto em ${posicao.localizacao}'),
          content: DropdownButtonFormField<String>(
            initialValue: id,
            items: products
                .map((p) => DropdownMenuItem(value: p.id, child: Text(p.nome)))
                .toList(),
            onChanged: (v) => setDialog(() => id = v!),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCELAR'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('ADICIONAR'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      try {
        final result = await widget.repository.adicionarProduto(posicao.id, id);
        setState(() => planograma = result);
      } catch (e) {
        _message(e);
      }
    }
  }

  void _message(Object e) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(planograma.nome)),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: addPosition,
      icon: const Icon(Icons.add_location_alt),
      label: const Text('POSIÇÃO'),
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      children: [
        if (planograma.descricao?.isNotEmpty == true)
          Text(planograma.descricao!),
        const SizedBox(height: 12),
        const Text(
          'A localização organiza o produto; a capacidade não altera o saldo físico.',
        ),
        const Divider(),
        if (planograma.posicoes.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Nenhuma posição cadastrada',
              textAlign: TextAlign.center,
            ),
          ),
        ...planograma.posicoes.map(
          (p) => Card(
            child: ExpansionTile(
              title: Text(
                p.localizacao.isEmpty ? 'Posição ${p.ordem}' : p.localizacao,
              ),
              subtitle: Text(p.setor ?? 'Sem setor'),
              children: [
                ...p.produtos
                    .where((e) => e.ativo)
                    .map(
                      (e) => ListTile(
                        title: Text(e.nome),
                        subtitle: Text(
                          'Facings: ${e.facings}${e.capacidade == null ? '' : ' • Capacidade: ${e.capacidade!.friendly}'}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () async {
                            try {
                              final result = await widget.repository
                                  .removerProduto(e.id);
                              setState(() => planograma = result);
                            } catch (error) {
                              _message(error);
                            }
                          },
                        ),
                      ),
                    ),
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('Adicionar produto'),
                  onTap: () => addProduct(p),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _field(TextEditingController c, String label) => Padding(
  padding: const EdgeInsets.only(bottom: 10),
  child: TextField(
    controller: c,
    decoration: InputDecoration(labelText: label),
  ),
);
