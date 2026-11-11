import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_content.dart';
import '../../core/widgets/async_state.dart';
import '../../core/widgets/status_badge.dart';
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
      children: [
        AppContent(
          maxWidth: AppLayout.formMaxWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _codigo,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  labelText: 'SKU ou código de barras',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    tooltip: 'Ler com a câmera',
                    onPressed: _scan,
                    icon: const Icon(Icons.qr_code_scanner),
                  ),
                ),
                onSubmitted: _buscar,
              ),
              const SizedBox(height: AppSpacing.lg),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: _loading ? null : () => _buscar(_codigo.text),
                  child: const Text('Buscar'),
                ),
              ),
              if (_loading)
                const AppLoadingState(
                  label: 'Buscando produto…',
                  layout: AppSkeletonLayout.detail,
                  inline: true,
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xl),
                  child: AppBanner(
                    tone: AppStatusTone.critical,
                    message: _error!,
                  ),
                ),
              if (_produto != null) _ProductDetails(product: _produto!),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ProductDetails extends StatelessWidget {
  const _ProductDetails({required this.product});
  final Produto product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(product.nome, style: theme.textTheme.titleLarge),
              ),
              AppStatusBadge(
                label: product.ativo ? 'Ativo' : 'Inativo',
                tone: product.ativo
                    ? AppStatusTone.success
                    : AppStatusTone.neutral,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            product.preco.currency,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppKeyValueGrid(
            entries: [
              ('SKU', product.codigoInterno),
              ('Categoria', product.categoria),
              ('Unidade', product.unidadeMedida),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          const AppSectionTitle('Códigos de barras'),
          for (final code in product.codigosBarras)
            AppListRow(
              dense: true,
              title: code.codigo,
              meta: code.tipo,
              trailing: code.principal
                  ? const AppStatusBadge(
                      label: 'Principal',
                      tone: AppStatusTone.info,
                    )
                  : null,
            ),
        ],
      ),
    );
  }
}
