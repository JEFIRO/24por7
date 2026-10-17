import 'package:flutter/material.dart';

import '../model/produto.dart';
import '../model/produto_repository.dart';
import 'scanner_page.dart';

class BuscarProduto extends StatefulWidget {
  const BuscarProduto({super.key, this.repository});
  final ProdutoRepository? repository;

  @override
  State<BuscarProduto> createState() => _BuscarProdutoState();
}

class _BuscarProdutoState extends State<BuscarProduto> {
  late final ProdutoRepository _repository;
  final _codigo = TextEditingController();
  Produto? _produto;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ProdutoRepository();
  }

  @override
  void dispose() {
    _codigo.dispose();
    super.dispose();
  }

  Future<void> _buscar(String codigo) async {
    if (codigo.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _produto = null;
    });
    try {
      final product = await _repository.buscarPorCodigo(codigo.trim());
      if (mounted) setState(() => _produto = product);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _scan() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ScannerPage()),
    );
    if (result != null) {
      _codigo.text = result;
      await _buscar(result);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Buscar produto')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _codigo,
          decoration: InputDecoration(
            labelText: 'SKU ou código de barras',
            suffixIcon: IconButton(
              onPressed: _scan,
              icon: const Icon(Icons.qr_code_scanner),
            ),
          ),
          onSubmitted: _buscar,
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _loading ? null : () => _buscar(_codigo.text),
          child: const Text('BUSCAR'),
        ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (_produto != null) _ProductDetails(product: _produto!),
      ],
    ),
  );
}

class _ProductDetails extends StatelessWidget {
  const _ProductDetails({required this.product});
  final Produto product;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(top: 20),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(product.nome, style: Theme.of(context).textTheme.titleLarge),
          Text(
            product.preco.currency,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Divider(),
          Text('SKU: ${product.codigoInterno}'),
          Text('Categoria: ${product.categoria}'),
          Text('Unidade: ${product.unidadeMedida}'),
          Text('Status: ${product.ativo ? "ATIVO" : "INATIVO"}'),
          const SizedBox(height: 8),
          const Text(
            'Códigos de barras',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ...product.codigosBarras.map(
            (code) => Text(
              '${code.codigo} • ${code.tipo}${code.principal ? " • Principal" : ""}',
            ),
          ),
        ],
      ),
    ),
  );
}
