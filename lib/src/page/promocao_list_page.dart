import 'package:flutter/material.dart';

import '../model/promocao.dart';
import '../model/promocao_repository.dart';
import 'promocao_detail_page.dart';
import 'promocao_form_page.dart';

class PromocaoListPage extends StatefulWidget {
  const PromocaoListPage({super.key, this.repository});
  final PromocaoRepository? repository;
  @override
  State<PromocaoListPage> createState() => _PromocaoListPageState();
}

class _PromocaoListPageState extends State<PromocaoListPage> {
  late final PromocaoRepository _repository =
      widget.repository ?? PromocaoRepository();
  List<Promocao> _items = const [];
  List<CondominioResumo> _condominios = const [];
  AbrangenciaPromocao? _scope;
  StatusPromocao? _status;
  String? _condominioId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _repository.listar(
          abrangencia: _scope,
          status: _status,
          condominioId: _condominioId,
        ),
        if (_condominios.isEmpty)
          _repository.condominios()
        else
          Future.value(_condominios),
      ]);
      if (mounted) {
        setState(() {
          _items = results[0] as List<Promocao>;
          _condominios = results[1] as List<CondominioResumo>;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm([Promocao? promotion]) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PromocaoFormPage(repository: _repository, promocao: promotion),
      ),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Promoções')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _openForm(),
      icon: const Icon(Icons.add),
      label: const Text('NOVA PROMOÇÃO'),
    ),
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 210,
                child: DropdownButtonFormField<AbrangenciaPromocao?>(
                  initialValue: _scope,
                  decoration: const InputDecoration(labelText: 'Abrangência'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Todas')),
                    DropdownMenuItem(
                      value: AbrangenciaPromocao.empresa,
                      child: Text('Empresa'),
                    ),
                    DropdownMenuItem(
                      value: AbrangenciaPromocao.condominio,
                      child: Text('Condomínio'),
                    ),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _scope = v;
                      if (v == AbrangenciaPromocao.empresa) {
                        _condominioId = null;
                      }
                    });
                    _load();
                  },
                ),
              ),
              SizedBox(
                width: 210,
                child: DropdownButtonFormField<StatusPromocao?>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todos')),
                    ...StatusPromocao.values.map(
                      (e) => DropdownMenuItem(value: e, child: Text(e.apiName)),
                    ),
                  ],
                  onChanged: (v) {
                    _status = v;
                    _load();
                  },
                ),
              ),
              SizedBox(
                width: 260,
                child: DropdownButtonFormField<String?>(
                  initialValue: _condominioId,
                  decoration: const InputDecoration(labelText: 'Condomínio'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Todos os condomínios'),
                    ),
                    ..._condominios.map(
                      (e) => DropdownMenuItem(value: e.id, child: Text(e.nome)),
                    ),
                  ],
                  onChanged: _scope == AbrangenciaPromocao.empresa
                      ? null
                      : (v) {
                          _condominioId = v;
                          _load();
                        },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            _StateMessage(
              icon: Icons.cloud_off,
              title: 'Não foi possível carregar',
              message: _error!,
              action: 'TENTAR NOVAMENTE',
              onPressed: _load,
            )
          else if (_items.isEmpty)
            _StateMessage(
              icon: Icons.local_offer_outlined,
              title: 'Nenhuma promoção cadastrada',
              message:
                  'Crie uma promoção para oferecer preços especiais\nem sua empresa ou em um condomínio.',
              action: 'CRIAR PROMOÇÃO',
              onPressed: () => _openForm(),
            )
          else
            ..._items.map(
              (promotion) => _PromotionCard(
                promotion: promotion,
                onTap: () async {
                  final changed = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PromocaoDetailPage(
                        repository: _repository,
                        initial: promotion,
                      ),
                    ),
                  );
                  if (changed == true) _load();
                },
              ),
            ),
          const SizedBox(height: 80),
        ],
      ),
    ),
  );
}

class _PromotionCard extends StatelessWidget {
  const _PromotionCard({required this.promotion, required this.onTap});
  final Promocao promotion;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    promotion.nome,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Chip(label: Text(promotion.status.apiName)),
              ],
            ),
            Text(
              switch (promotion.tipo) {
                TipoPromocao.percentual => '${promotion.valor.friendly}% OFF',
                TipoPromocao.descontoFixo => '${promotion.valor.currency} OFF',
                TipoPromocao.precoFixo => 'POR ${promotion.valor.currency}',
              },
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              promotion.abrangencia == AbrangenciaPromocao.empresa
                  ? 'EMPRESA'
                  : 'CONDOMÍNIO • ${promotion.condominioNome ?? ''}',
            ),
            Text(
              '${promotion.produtos.length} produto(s) • ${_date(promotion.inicio)} → ${_date(promotion.fim)}',
            ),
          ],
        ),
      ),
    ),
  );
}

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.action,
    required this.onPressed,
  });
  final IconData icon;
  final String title;
  final String message;
  final String action;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 56),
    child: Column(
      children: [
        Icon(icon, size: 56, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 12),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 20),
        OutlinedButton(onPressed: onPressed, child: Text(action)),
      ],
    ),
  );
}
