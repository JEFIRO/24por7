import 'package:flutter/material.dart';

import '../model/promocao.dart';
import '../model/promocao_repository.dart';
import 'promocao_form_page.dart';

class PromocaoDetailPage extends StatefulWidget {
  const PromocaoDetailPage({
    super.key,
    required this.repository,
    required this.initial,
  });
  final PromocaoRepository repository;
  final Promocao initial;
  @override
  State<PromocaoDetailPage> createState() => _PromocaoDetailPageState();
}

class _PromocaoDetailPageState extends State<PromocaoDetailPage> {
  late Promocao _promotion = widget.initial;
  bool _working = false;

  Future<void> _edit() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PromocaoFormPage(
          repository: widget.repository,
          promocao: _promotion,
        ),
      ),
    );
    if (changed == true) {
      final updated = await widget.repository.buscar(_promotion.id);
      if (mounted) setState(() => _promotion = updated);
    }
  }

  Future<void> _toggle() async {
    setState(() => _working = true);
    try {
      final updated = await widget.repository.alterarStatus(
        _promotion.id,
        !_promotion.ativo,
      );
      if (mounted) setState(() => _promotion = updated);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Detalhes da promoção')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _promotion.nome,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            Chip(label: Text(_promotion.status.apiName)),
          ],
        ),
        if (_promotion.descricao?.isNotEmpty == true)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_promotion.descricao!),
          ),
        const Divider(height: 32),
        _Info(
          'Abrangência',
          _promotion.abrangencia == AbrangenciaPromocao.empresa
              ? 'Empresa'
              : 'Condomínio • ${_promotion.condominioNome}',
        ),
        _Info('Tipo', _promotion.tipo.apiName),
        _Info(
          'Valor',
          _promotion.tipo == TipoPromocao.percentual
              ? '${_promotion.valor.friendly}%'
              : _promotion.valor.currency,
        ),
        _Info('Início', _promotion.inicio.toString()),
        _Info('Término', _promotion.fim.toString()),
        _Info('Prioridade', _promotion.prioridade.toString()),
        const Divider(height: 32),
        Text(
          'Produtos (${_promotion.produtos.length})',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        ..._promotion.produtos.map(
          (p) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(p.nome),
            subtitle: Text(p.codigo),
            trailing: Text(p.preco.currency),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _working ? null : _edit,
          icon: const Icon(Icons.edit),
          label: const Text('EDITAR'),
        ),
        OutlinedButton.icon(
          onPressed: _working ? null : _toggle,
          icon: Icon(_promotion.ativo ? Icons.pause_circle : Icons.play_circle),
          label: Text(_promotion.ativo ? 'DESATIVAR' : 'ATIVAR'),
        ),
      ],
    ),
  );
}

class _Info extends StatelessWidget {
  const _Info(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}
