import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../model/decimal_value.dart';
import '../model/promocao.dart';
import '../model/promocao_repository.dart';

class PromocaoFormPage extends StatefulWidget {
  const PromocaoFormPage({super.key, required this.repository, this.promocao});
  final PromocaoRepository repository;
  final Promocao? promocao;
  @override
  State<PromocaoFormPage> createState() => _PromocaoFormPageState();
}

class _PromocaoFormPageState extends State<PromocaoFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.promocao?.nome);
  late final _description = TextEditingController(
    text: widget.promocao?.descricao,
  );
  late final _value = TextEditingController(
    text: widget.promocao?.valor.friendly,
  );
  late final _priority = TextEditingController(
    text: (widget.promocao?.prioridade ?? 0).toString(),
  );
  final _search = TextEditingController();
  late AbrangenciaPromocao _scope =
      widget.promocao?.abrangencia ?? AbrangenciaPromocao.empresa;
  late TipoPromocao _type = widget.promocao?.tipo ?? TipoPromocao.percentual;
  late DateTime _start =
      widget.promocao?.inicio ?? DateTime.now().add(const Duration(minutes: 5));
  late DateTime _end =
      widget.promocao?.fim ?? DateTime.now().add(const Duration(days: 7));
  late bool _active = widget.promocao?.ativo ?? true;
  late String? _condoId = widget.promocao?.condominioId;
  late final Set<String> _selected =
      widget.promocao?.produtos.map((e) => e.id).toSet() ?? <String>{};
  List<CondominioResumo> _condos = const [];
  List<ProdutoResumo> _products = const [];
  bool _loadingProducts = true;
  bool _saving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadReferences();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    for (final c in [_name, _description, _value, _priority, _search]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadReferences() async {
    setState(() {
      _loadingProducts = true;
      _loadError = null;
    });
    try {
      final condos = await widget.repository.condominios();
      final products = await widget.repository.produtos(
        condominioId: _scope == AbrangenciaPromocao.condominio
            ? _condoId
            : null,
      );
      if (mounted) {
        setState(() {
          _condos = condos;
          _products = products;
          _selected.removeWhere((id) => !_products.any((p) => p.id == id));
        });
      }
    } catch (error) {
      if (mounted) setState(() => _loadError = error.toString());
    } finally {
      if (mounted) setState(() => _loadingProducts = false);
    }
  }

  Future<void> _pickDate(bool start) async {
    final current = start ? _start : _end;
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null) return;
    setState(() {
      final value = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      if (start) {
        _start = value;
      } else {
        _end = value;
      }
    });
  }

  String? _validateValue(String? raw) {
    try {
      final decimal = DecimalValue.parse(raw ?? '');
      if (_type != TipoPromocao.precoFixo && !decimal.isPositive) {
        return 'O desconto deve ser maior que zero';
      }
      if (_type == TipoPromocao.percentual &&
          !decimal.lessThanOrEqualTo('100')) {
        return 'O percentual deve ser no máximo 100';
      }
      return null;
    } on FormatException catch (error) {
      return error.message.toString();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_scope == AbrangenciaPromocao.condominio && _condoId == null) {
      _message('Selecione o condomínio');
      return;
    }
    if (_selected.isEmpty) {
      _message('Selecione pelo menos um produto');
      return;
    }
    if (!_end.isAfter(_start)) {
      _message('O término deve ser posterior ao início');
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.repository.salvar(
        PromocaoDraft(
          nome: _name.text,
          descricao: _description.text.isEmpty ? null : _description.text,
          abrangencia: _scope,
          condominioId: _condoId,
          tipo: _type,
          valor: DecimalValue.parse(_value.text),
          inicio: _start,
          fim: _end,
          ativo: _active,
          prioridade: int.tryParse(_priority.text) ?? 0,
          produtoIds: _selected,
        ),
        id: widget.promocao?.id,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) _message(error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String value) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(value)));
  String get _valueLabel => switch (_type) {
    TipoPromocao.percentual => 'Desconto (%)',
    TipoPromocao.descontoFixo => 'Desconto (R\$)',
    TipoPromocao.precoFixo => 'Preço promocional',
  };
  List<ProdutoResumo> get _visibleProducts {
    final q = _search.text.trim().toLowerCase();
    return _products
        .where(
          (p) =>
              q.isEmpty ||
              p.nome.toLowerCase().contains(q) ||
              p.codigo.contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.promocao == null ? 'Nova promoção' : 'Editar promoção',
      ),
    ),
    bottomNavigationBar: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('SALVAR'),
        ),
      ),
    ),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nome'),
            maxLength: 150,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Informe o nome' : null,
          ),
          TextFormField(
            controller: _description,
            decoration: const InputDecoration(labelText: 'Descrição'),
            maxLength: 500,
            maxLines: 3,
          ),
          const SizedBox(height: 8),
          SegmentedButton<AbrangenciaPromocao>(
            segments: const [
              ButtonSegment(
                value: AbrangenciaPromocao.empresa,
                label: Text('Empresa'),
              ),
              ButtonSegment(
                value: AbrangenciaPromocao.condominio,
                label: Text('Condomínio'),
              ),
            ],
            selected: {_scope},
            onSelectionChanged: (s) {
              setState(() {
                _scope = s.first;
                if (_scope == AbrangenciaPromocao.empresa) _condoId = null;
                _selected.clear();
              });
              _loadReferences();
            },
          ),
          if (_scope == AbrangenciaPromocao.condominio) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _condoId,
              decoration: const InputDecoration(labelText: 'Condomínio'),
              items: _condos
                  .map(
                    (e) => DropdownMenuItem(value: e.id, child: Text(e.nome)),
                  )
                  .toList(),
              onChanged: (v) {
                setState(() {
                  _condoId = v;
                  _selected.clear();
                });
                _loadReferences();
              },
              validator: (v) => v == null ? 'Selecione o condomínio' : null,
            ),
          ],
          const SizedBox(height: 16),
          DropdownButtonFormField<TipoPromocao>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Tipo'),
            items: const [
              DropdownMenuItem(
                value: TipoPromocao.percentual,
                child: Text('Percentual'),
              ),
              DropdownMenuItem(
                value: TipoPromocao.descontoFixo,
                child: Text('Desconto fixo'),
              ),
              DropdownMenuItem(
                value: TipoPromocao.precoFixo,
                child: Text('Preço fixo'),
              ),
            ],
            onChanged: (v) => setState(() => _type = v!),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _value,
            decoration: InputDecoration(
              labelText: _valueLabel,
              helperText: 'Até 6 casas decimais',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
            ],
            validator: _validateValue,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _priority,
            decoration: const InputDecoration(labelText: 'Prioridade'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DateTile(
                  label: 'Início',
                  value: _start,
                  onTap: () => _pickDate(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateTile(
                  label: 'Término',
                  value: _end,
                  onTap: () => _pickDate(false),
                ),
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Promoção habilitada'),
            subtitle: const Text(
              'O status visível também considera início e término',
            ),
            value: _active,
            onChanged: (v) => setState(() => _active = v),
          ),
          const Divider(height: 32),
          Text(
            'Produtos (${_selected.length} selecionado(s))',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Buscar produto',
            ),
          ),
          Row(
            children: [
              TextButton(
                onPressed: _visibleProducts.isEmpty
                    ? null
                    : () => setState(
                        () =>
                            _selected.addAll(_visibleProducts.map((e) => e.id)),
                      ),
                child: const Text('SELECIONAR VISÍVEIS'),
              ),
              TextButton(
                onPressed: _selected.isEmpty
                    ? null
                    : () => setState(_selected.clear),
                child: const Text('REMOVER SELEÇÃO'),
              ),
            ],
          ),
          if (_loadingProducts)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_loadError != null)
            Column(
              children: [
                Text(_loadError!),
                OutlinedButton(
                  onPressed: _loadReferences,
                  child: const Text('TENTAR NOVAMENTE'),
                ),
              ],
            )
          else if (_products.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Nenhum produto disponível para esta abrangência.',
                textAlign: TextAlign.center,
              ),
            )
          else
            ..._visibleProducts.map(
              (product) => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _selected.contains(product.id),
                title: Text(product.nome),
                subtitle: Text('${product.codigo} • ${product.preco.currency}'),
                onChanged: (checked) => setState(
                  () => checked == true
                      ? _selected.add(product.id)
                      : _selected.remove(product.id),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.value,
    required this.onTap,
  });
  final String label;
  final DateTime value;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
    shape: RoundedRectangleBorder(
      side: BorderSide(color: Theme.of(context).colorScheme.outline),
      borderRadius: BorderRadius.circular(12),
    ),
    title: Text(label),
    subtitle: Text(
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}',
    ),
    trailing: const Icon(Icons.event),
    onTap: onTap,
  );
}
