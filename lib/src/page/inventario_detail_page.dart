import 'package:flutter/material.dart';

import '../model/decimal_value.dart';
import '../model/inventario.dart';
import '../model/inventario_repository.dart';

class InventarioDetailPage extends StatefulWidget {
  const InventarioDetailPage({
    super.key,
    required this.inventarioId,
    this.repository,
  });
  final String inventarioId;
  final InventarioRepository? repository;

  @override
  State<InventarioDetailPage> createState() => _InventarioDetailPageState();
}

class _InventarioDetailPageState extends State<InventarioDetailPage> {
  late final InventarioRepository _repository;
  Inventario? _inventario;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String _busca = '';
  String _filtro = 'TODOS';

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
      final value = await _repository.buscar(widget.inventarioId);
      if (mounted) setState(() => _inventario = value);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _contar(InventarioItem item) async {
    final quantidade = TextEditingController(
      text: item.quantidadeContada?.normalized ?? '',
    );
    final motivo = TextEditingController(text: item.motivoAjuste ?? '');
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.nome),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('SKU: ${item.codigoInterno}'),
            if (item.localizacaoPlanograma != null)
              Text('Local: ${item.localizacaoPlanograma}'),
            const SizedBox(height: 12),
            TextField(
              controller: quantidade,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Quantidade contada',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: motivo,
              decoration: const InputDecoration(labelText: 'Motivo/observação'),
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
            child: const Text('CONFIRMAR CONTAGEM'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      final decimal = DecimalValue.parse(
        quantidade.text.replaceAll(',', '.'),
        maxScale: 3,
      );
      final updated = await _repository.contar(
        widget.inventarioId,
        item.id,
        decimal,
        motivo.text.trim(),
      );
      if (mounted) setState(() => _inventario = updated);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _acao(bool finalizar) async {
    setState(() => _saving = true);
    try {
      final updated = finalizar
          ? await _repository.finalizar(widget.inventarioId)
          : await _repository.cancelar(widget.inventarioId);
      if (mounted) setState(() => _inventario = updated);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<InventarioItem> get _filtrados {
    final items = _inventario?.itens ?? const <InventarioItem>[];
    return items.where((item) {
      final termo = _busca.toLowerCase();
      final buscaOk =
          termo.isEmpty ||
          item.nome.toLowerCase().contains(termo) ||
          item.codigoInterno.toLowerCase().contains(termo) ||
          (item.codigoBarras?.contains(termo) ?? false) ||
          item.codigosBarras.any((codigo) => codigo.contains(termo));
      final filtroOk =
          _filtro == 'TODOS' ||
          (_filtro == 'PENDENTES'
              ? item.quantidadeContada == null
              : item.status ==
                    _filtro.substring(
                      0,
                      _filtro.endsWith('S')
                          ? _filtro.length - 1
                          : _filtro.length,
                    ));
      return buscaOk && filtroOk;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final inventario = _inventario;
    return Scaffold(
      appBar: AppBar(title: const Text('Contagem do inventário')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!),
                  TextButton(
                    onPressed: _carregar,
                    child: const Text('TENTAR NOVAMENTE'),
                  ),
                ],
              ),
            )
          : inventario == null
          ? const Center(child: Text('Inventário não encontrado'))
          : Column(
              children: [
                _Resumo(inventario),
                if (inventario.status == 'COM_CONFLITO')
                  const MaterialBanner(
                    content: Text(
                      'O estoque mudou durante a contagem. Reconte os itens marcados como conflito.',
                    ),
                    actions: [SizedBox.shrink()],
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: TextField(
                    onChanged: (value) => setState(() => _busca = value),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Nome, SKU ou código de barras',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children:
                        [
                              'TODOS',
                              'PENDENTES',
                              'OK',
                              'FALTAS',
                              'SOBRAS',
                              'CONFLITOS',
                            ]
                            .map(
                              (f) => Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  label: Text(f),
                                  selected: _filtro == f,
                                  onSelected: (_) =>
                                      setState(() => _filtro = f),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _filtrados.length,
                    itemBuilder: (context, index) {
                      final item = _filtrados[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: ListTile(
                          title: Text(item.nome),
                          subtitle: Text(
                            [
                              'SKU: ${item.codigoInterno}',
                              if (item.localizacaoPlanograma != null)
                                'Local: ${item.localizacaoPlanograma}',
                              if (item.saldoSistemaSnapshot != null)
                                'Sistema: ${item.saldoSistemaSnapshot!.normalized}',
                              'Contado: ${item.quantidadeContada?.normalized ?? "pendente"}',
                              if (item.diferenca != null)
                                'Diferença: ${item.diferenca!.normalized}',
                            ].join('\n'),
                          ),
                          isThreeLine: true,
                          trailing: Chip(label: Text(item.status)),
                          onTap:
                              inventario.status == 'FINALIZADO' ||
                                  inventario.status == 'CANCELADO' ||
                                  item.ajusteAplicado
                              ? null
                              : () => _contar(item),
                        ),
                      );
                    },
                  ),
                ),
                if (inventario.status != 'FINALIZADO' &&
                    inventario.status != 'CANCELADO')
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _saving ? null : () => _acao(false),
                              child: const Text('CANCELAR'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: _saving || inventario.pendentes > 0
                                  ? null
                                  : () => _acao(true),
                              child: Text(_saving ? 'AGUARDE...' : 'FINALIZAR'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _Resumo extends StatelessWidget {
  const _Resumo(this.inventario);
  final Inventario inventario;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(12),
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              inventario.localNome,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: inventario.totalProdutos == 0
                  ? 1
                  : inventario.contados / inventario.totalProdutos,
            ),
            const SizedBox(height: 8),
            Text(
              '${inventario.contados} contados • ${inventario.pendentes} pendentes • ${inventario.divergencias} divergências • ${inventario.conflitos} conflitos',
            ),
          ],
        ),
      ),
    ),
  );
}
