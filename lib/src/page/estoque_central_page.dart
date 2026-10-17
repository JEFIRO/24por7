import 'package:flutter/material.dart';

import '../model/produto.dart';
import '../model/decimal_value.dart';
import '../model/estoque.dart';
import '../model/estoque_repository.dart';

class EstoqueCentralPage extends StatefulWidget {
  const EstoqueCentralPage({super.key, this.repository});
  final EstoqueRepository? repository;
  @override
  State<EstoqueCentralPage> createState() => _EstoqueCentralPageState();
}

class _EstoqueCentralPageState extends State<EstoqueCentralPage> {
  late final EstoqueRepository repository;
  final search = TextEditingController();
  List<EstoqueCentral> items = const [];
  String? categoria;
  bool? ativo;
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
    search.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await repository.listarCentral(
        busca: search.text.trim(),
        categoria: categoria,
        ativo: ativo,
      );
      if (mounted) setState(() => items = result);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Estoque central'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _movimentar(),
      icon: const Icon(Icons.add),
      label: const Text('ENTRADA'),
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: search,
                onSubmitted: (_) => load(),
                decoration: InputDecoration(
                  hintText: 'Buscar por nome, SKU ou código de barras',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    onPressed: load,
                    icon: const Icon(Icons.arrow_forward),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      initialValue: categoria,
                      decoration: const InputDecoration(labelText: 'Categoria'),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Todas'),
                        ),
                        ..._categorias.map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value.replaceAll('_', ' ')),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        categoria = value;
                        load();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<bool?>(
                      initialValue: ativo,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Todos')),
                        DropdownMenuItem(value: true, child: Text('Ativos')),
                        DropdownMenuItem(value: false, child: Text('Inativos')),
                      ],
                      onChanged: (value) {
                        ativo = value;
                        load();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(child: _body()),
      ],
    ),
  );
  Widget _body() {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) return _StateMessage(message: error!, action: load);
    if (items.isEmpty) {
      return _StateMessage(
        message:
            'Nenhum produto possui saldo central.\nUse ENTRADA para iniciar o estoque.',
        action: () => _movimentar(),
      );
    }
    return RefreshIndicator(
      onRefresh: load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Card(
            child: ListTile(
              title: Text(
                item.produto,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'SKU ${item.codigoInterno}\n${item.localizacao?.isNotEmpty == true ? 'Local: ${item.localizacao}' : 'Sem localização no planograma'}',
              ),
              isThreeLine: true,
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${item.quantidade.friendly} ${item.unidadeMedida}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(item.ativo ? 'Ativo' : 'Inativo'),
                ],
              ),
              onTap: () => _movimentar(item: item),
            ),
          );
        },
      ),
    );
  }

  Future<void> _movimentar({EstoqueCentral? item}) async {
    List<Produto> produtos;
    try {
      produtos = await repository.listarProdutos();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
      return;
    }
    if (!mounted || produtos.isEmpty) return;
    String produtoId = item?.produtoId ?? produtos.first.id!;
    String operacao = 'ENTRADA';
    final quantidade = TextEditingController(
      text: item == null ? '' : item.quantidade.friendly,
    );
    final motivo = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: const Text('Movimentar estoque central'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: produtoId,
                  decoration: const InputDecoration(labelText: 'Produto'),
                  items: produtos
                      .map(
                        (p) =>
                            DropdownMenuItem(value: p.id, child: Text(p.nome)),
                      )
                      .toList(),
                  onChanged: item == null ? (v) => produtoId = v! : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: operacao,
                  decoration: const InputDecoration(labelText: 'Operação'),
                  items: const [
                    DropdownMenuItem(value: 'ENTRADA', child: Text('Entrada')),
                    DropdownMenuItem(value: 'SAIDA', child: Text('Saída')),
                    DropdownMenuItem(
                      value: 'AJUSTE',
                      child: Text('Ajustar para saldo físico'),
                    ),
                  ],
                  onChanged: (v) => setDialog(() => operacao = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: quantidade,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: InputDecoration(
                    labelText: operacao == 'AJUSTE'
                        ? 'Novo saldo'
                        : 'Quantidade',
                    helperText:
                        'Até 3 casas decimais; saldo negativo é permitido no ajuste',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: motivo,
                  maxLength: 300,
                  decoration: const InputDecoration(labelText: 'Motivo'),
                ),
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
              child: const Text('CONFIRMAR'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      final value = DecimalValue.parse(quantidade.text);
      if (!RegExp(r'^-?\d+([\.,]\d{1,3})?$').hasMatch(quantidade.text.trim())) {
        throw const FormatException('Use no máximo 3 casas decimais');
      }
      await repository.movimentar(
        produtoId,
        operacao,
        value,
        motivo.text.trim(),
      );
      await load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}

const _categorias = <String>[
  'BEBIDA',
  'ALIMENTOS',
  'LIMPEZA',
  'HIGIENE',
  'PADARIA',
  'LATICINIOS',
  'CONGELADOS',
  'DOCES',
  'SALGADINHOS',
  'FRUTAS',
  'VERDURAS',
  'LEGUMES',
  'CARNES',
  'FRIOS',
  'PETISCOS',
  'TEMPEROS',
  'GRAOS',
  'MASSAS',
  'ENLATADOS',
  'MATINAIS',
  'UTILIDADES',
  'PET',
  'INFANTIL',
  'ELETRONICOS',
  'PAPELARIA',
  'DESCARTAVEIS',
  'OUTROS',
];

class _StateMessage extends StatelessWidget {
  const _StateMessage({required this.message, required this.action});
  final String message;
  final VoidCallback action;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: action,
            child: const Text('TENTAR NOVAMENTE'),
          ),
        ],
      ),
    ),
  );
}
