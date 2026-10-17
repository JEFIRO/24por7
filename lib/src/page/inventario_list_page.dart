import 'package:flutter/material.dart';

import '../model/inventario.dart';
import '../model/inventario_repository.dart';
import 'inventario_detail_page.dart';

class InventarioListPage extends StatefulWidget {
  const InventarioListPage({super.key, this.repository});
  final InventarioRepository? repository;

  @override
  State<InventarioListPage> createState() => _InventarioListPageState();
}

class _InventarioListPageState extends State<InventarioListPage> {
  late final InventarioRepository _repository;
  List<Inventario> _itens = const [];
  bool _loading = true;
  String? _error;
  String? _status;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? InventarioRepository();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _repository.listar(status: _status);
      if (mounted) setState(() => _itens = data);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _novo() async {
    bool cega = false;
    final descricao = TextEditingController();
    final criar = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Novo inventário'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.warehouse),
                title: Text('Estoque Central'),
                subtitle: Text('O saldo será congelado como referência'),
              ),
              TextField(
                controller: descricao,
                decoration: const InputDecoration(labelText: 'Descrição'),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: cega,
                title: const Text('Contagem cega'),
                subtitle: const Text(
                  'Oculta o saldo esperado durante a contagem',
                ),
                onChanged: (value) => setLocal(() => cega = value ?? false),
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
              child: const Text('INICIAR'),
            ),
          ],
        ),
      ),
    );
    if (criar != true || !mounted) return;
    try {
      final inventario = await _repository.iniciar(
        contagemCega: cega,
        descricao: descricao.text.trim().isEmpty ? null : descricao.text.trim(),
      );
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InventarioDetailPage(
            inventarioId: inventario.id,
            repository: _repository,
          ),
        ),
      );
      await _carregar();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Inventários')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _loading ? null : _novo,
      icon: const Icon(Icons.add),
      label: const Text('NOVO INVENTÁRIO'),
    ),
    body: RefreshIndicator(
      onRefresh: _carregar,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
        children: [
          DropdownButtonFormField<String?>(
            initialValue: _status,
            decoration: const InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('Todos')),
              DropdownMenuItem(
                value: 'EM_CONTAGEM',
                child: Text('Em contagem'),
              ),
              DropdownMenuItem(
                value: 'COM_CONFLITO',
                child: Text('Com conflito'),
              ),
              DropdownMenuItem(value: 'FINALIZADO', child: Text('Finalizados')),
              DropdownMenuItem(value: 'CANCELADO', child: Text('Cancelados')),
            ],
            onChanged: (value) {
              _status = value;
              _carregar();
            },
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null)
            _ErrorState(message: _error!, retry: _carregar)
          else if (_itens.isEmpty)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Column(
                children: [
                  Icon(Icons.fact_check_outlined, size: 52),
                  SizedBox(height: 12),
                  Text('Nenhum inventário encontrado'),
                ],
              ),
            )
          else
            ..._itens.map(
              (item) => Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.fact_check)),
                  title: Text(item.descricao ?? item.localNome),
                  subtitle: Text(
                    '${item.localNome}\n${item.contados}/${item.totalProdutos} contados • ${item.divergencias} divergência(s)',
                  ),
                  isThreeLine: true,
                  trailing: _StatusChip(item.status),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InventarioDetailPage(
                          inventarioId: item.id,
                          repository: _repository,
                        ),
                      ),
                    );
                    _carregar();
                  },
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.status);
  final String status;
  @override
  Widget build(BuildContext context) =>
      Chip(label: Text(status.replaceAll('_', ' ')));
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.retry});
  final String message;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      children: [
        const Icon(Icons.cloud_off, size: 48),
        Text(message, textAlign: TextAlign.center),
        TextButton(onPressed: retry, child: const Text('TENTAR NOVAMENTE')),
      ],
    ),
  );
}
