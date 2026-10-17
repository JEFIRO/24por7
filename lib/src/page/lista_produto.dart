import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_content.dart';
import '../../core/widgets/async_state.dart';
import '../../core/widgets/status_badge.dart';
import '../model/produto.dart';
import '../model/produto_repository.dart';
import 'cadastra_produto.dart';
import 'importacao_produto_page.dart';

class ListaProduto extends StatefulWidget {
  const ListaProduto({super.key, this.repository});
  final ProdutoRepository? repository;

  @override
  State<ListaProduto> createState() => _ListaProdutoState();
}

class _ListaProdutoState extends State<ListaProduto> {
  late final ProdutoRepository _repository;
  final _search = TextEditingController();
  bool _loading = true;
  String? _error;
  ProdutoPage? _result;
  int _page = 0;

  List<Produto> get _visible {
    final query = _search.text.trim().toLowerCase();
    final products = _result?.items ?? const <Produto>[];
    if (query.isEmpty) return products;
    return products.where((product) {
      return product.nome.toLowerCase().contains(query) ||
          product.codigoInterno.toLowerCase().contains(query) ||
          (product.codigoBarrasPrincipal ?? '').contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ProdutoRepository();
    _buscar();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _buscar({int? page}) async {
    setState(() {
      _loading = true;
      _error = null;
      if (page != null) _page = page;
    });
    try {
      final result = await _repository.listarPagina(page: _page);
      if (mounted) setState(() => _result = result);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editar(Produto summary) async {
    try {
      final navigator = Navigator.of(context);
      final changed = summary.id == null
          ? await navigator.push<Produto>(
              MaterialPageRoute(
                builder: (_) =>
                    CadastraProduto(produto: summary, repository: _repository),
              ),
            )
          : await navigator.pushNamed('/produtos/${summary.id}');
      if (changed != null) await _buscar();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _create() async {
    final created = await Navigator.push<Produto>(
      context,
      MaterialPageRoute(
        builder: (_) => CadastraProduto(repository: _repository),
      ),
    );
    if (created != null) await _buscar(page: 0);
  }

  Future<void> _import() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ImportacaoProdutoPage()),
    );
    if (changed == true) await _buscar(page: 0);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Produtos'),
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: _loading ? null : _buscar,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    floatingActionButton: AppBreakpoints.isMobile(context)
        ? FloatingActionButton(onPressed: _create, child: const Icon(Icons.add))
        : null,
    body: _loading && _result == null
        ? const AppLoadingState(label: 'Carregando catálogo…')
        : _error != null && _result == null
        ? AppErrorState(message: _error!, onRetry: _buscar)
        : RefreshIndicator(
            onRefresh: _buscar,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: AppContent(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppPageHeader(
                      title: 'Catálogo de produtos',
                      subtitle:
                          '${_result?.totalElements ?? 0} produtos cadastrados na Empresa.',
                      actions: [
                        OutlinedButton.icon(
                          onPressed: _loading ? null : _import,
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Importar planilha'),
                        ),
                        if (!AppBreakpoints.isMobile(context))
                          FilledButton.icon(
                            onPressed: _create,
                            icon: const Icon(Icons.add),
                            label: const Text('Novo produto'),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Buscar nesta página',
                        hintText: 'Nome, SKU ou código de barras',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: MaterialBanner(
                          content: Text(_error!),
                          actions: [
                            TextButton(
                              onPressed: _buscar,
                              child: const Text('Tentar novamente'),
                            ),
                          ],
                        ),
                      ),
                    if ((_result?.items.isEmpty ?? true))
                      AppEmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: 'Nenhum produto cadastrado',
                        message:
                            'Cadastre manualmente ou importe a planilha oficial.',
                        action: FilledButton(
                          onPressed: _create,
                          child: const Text('Criar produto'),
                        ),
                      )
                    else if (_visible.isEmpty)
                      const AppEmptyState(
                        icon: Icons.search_off,
                        title: 'Nenhum resultado nesta página',
                        message: 'Limpe a busca ou avance para outra página.',
                      )
                    else if (AppBreakpoints.isDesktop(context))
                      _desktopTable()
                    else
                      _mobileList(),
                    if ((_result?.totalPages ?? 0) > 1) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _pagination(),
                    ],
                    const SizedBox(height: 88),
                  ],
                ),
              ),
            ),
          ),
  );

  Widget _mobileList() => Column(
    children: [
      for (final product in _visible)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(AppSpacing.lg),
              onTap: () => _editar(product),
              leading: CircleAvatar(
                child: Icon(
                  product.ativo
                      ? Icons.inventory_2
                      : Icons.inventory_2_outlined,
                ),
              ),
              title: Text(product.nome),
              subtitle: Text(
                'SKU ${product.codigoInterno}\n${product.codigoBarrasPrincipal ?? "Sem código principal"}',
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    product.preco.currency,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  AppStatusBadge(
                    label: product.ativo ? 'Ativo' : 'Inativo',
                    tone: product.ativo
                        ? AppStatusTone.success
                        : AppStatusTone.neutral,
                  ),
                ],
              ),
            ),
          ),
        ),
    ],
  );

  Widget _desktopTable() => Card(
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Produto')),
          DataColumn(label: Text('SKU')),
          DataColumn(label: Text('Código principal')),
          DataColumn(label: Text('Categoria')),
          DataColumn(label: Text('Preço'), numeric: true),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('')),
        ],
        rows: [
          for (final product in _visible)
            DataRow(
              cells: [
                DataCell(Text(product.nome), onTap: () => _editar(product)),
                DataCell(Text(product.codigoInterno)),
                DataCell(Text(product.codigoBarrasPrincipal ?? '—')),
                DataCell(Text(product.categoria)),
                DataCell(Text(product.preco.currency)),
                DataCell(
                  AppStatusBadge(
                    label: product.ativo ? 'Ativo' : 'Inativo',
                    tone: product.ativo
                        ? AppStatusTone.success
                        : AppStatusTone.neutral,
                  ),
                ),
                DataCell(
                  IconButton(
                    tooltip: 'Editar',
                    onPressed: () => _editar(product),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ),
              ],
            ),
        ],
      ),
    ),
  );

  Widget _pagination() => Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      Text('Página ${_page + 1} de ${_result!.totalPages}'),
      const SizedBox(width: AppSpacing.md),
      IconButton(
        tooltip: 'Página anterior',
        onPressed: _page == 0 || _loading
            ? null
            : () => _buscar(page: _page - 1),
        icon: const Icon(Icons.chevron_left),
      ),
      IconButton(
        tooltip: 'Próxima página',
        onPressed: _page + 1 >= _result!.totalPages || _loading
            ? null
            : () => _buscar(page: _page + 1),
        icon: const Icon(Icons.chevron_right),
      ),
    ],
  );
}
