import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_content.dart';
import '../../core/widgets/async_state.dart';
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

  Widget get _saveButton => FilledButton(
    onPressed: _saving ? null : _save,
    child: Text(_saving ? 'Salvando…' : 'Salvar'),
  );

  @override
  Widget build(BuildContext context) {
    final mobile = AppBreakpoints.isMobile(context);
    final gap = const SizedBox(height: AppSpacing.xl);
    final fields = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
          decoration: const InputDecoration(labelText: 'Descrição (opcional)'),
          maxLength: 500,
          minLines: 1,
          maxLines: 3,
        ),
        gap,
        _Label('Tipo'),
        SegmentedButton<TipoPromocao>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: TipoPromocao.percentual,
              label: Text('Percentual'),
            ),
            ButtonSegment(
              value: TipoPromocao.descontoFixo,
              label: Text('Desconto fixo'),
            ),
            ButtonSegment(
              value: TipoPromocao.precoFixo,
              label: Text('Preço fixo'),
            ),
          ],
          selected: {_type},
          onSelectionChanged: (value) => setState(() => _type = value.first),
        ),
        gap,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _value,
                decoration: InputDecoration(
                  labelText: _valueLabel,
                  helperText: 'Até 6 casas decimais',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                ],
                validator: _validateValue,
              ),
            ),
            const SizedBox(width: AppSpacing.xl),
            Expanded(
              child: TextFormField(
                controller: _priority,
                decoration: const InputDecoration(
                  labelText: 'Prioridade',
                  helperText: 'Maior número vence em conflito',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
          ],
        ),
        gap,
        _Label('Abrangência'),
        SegmentedButton<AbrangenciaPromocao>(
          showSelectedIcon: false,
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
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _condoId,
            decoration: const InputDecoration(labelText: 'Condomínio'),
            items: _condos
                .map((e) => DropdownMenuItem(value: e.id, child: Text(e.nome)))
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
        gap,
        Row(
          children: [
            Expanded(
              child: _DateField(
                label: 'Início',
                value: _start,
                onTap: () => _pickDate(true),
              ),
            ),
            const SizedBox(width: AppSpacing.xl),
            Expanded(
              child: _DateField(
                label: 'Término',
                value: _end,
                onTap: () => _pickDate(false),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Promoção habilitada'),
          subtitle: const Text(
            'O status exibido também considera início e término.',
          ),
          value: _active,
          onChanged: (v) => setState(() => _active = v),
        ),
      ],
    );
    final products = _productPanel();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.promocao == null ? 'Nova promoção' : 'Editar promoção',
        ),
        actions: mobile
            ? null
            : [
                TextButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.lg),
                  child: _saveButton,
                ),
              ],
      ),
      bottomNavigationBar: mobile
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: _saveButton,
              ),
            )
          : null,
      body: Form(
        key: _formKey,
        child: ListView(
          children: [
            AppContent(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 1000) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        fields,
                        const SizedBox(height: AppSpacing.xxl),
                        products,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppLayout.formMaxWidth - 160,
                        ),
                        child: fields,
                      ),
                      const SizedBox(width: AppSpacing.section),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.only(left: AppSpacing.xl),
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outlineVariant,
                              ),
                            ),
                          ),
                          child: products,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productPanel() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionTitle(
          'Produtos',
          subtitle: _selected.length == 1
              ? '1 selecionado'
              : '${_selected.length} selecionados',
        ),
        const SizedBox(height: AppSpacing.sm),
        AppSearchField(controller: _search, hintText: 'Buscar produto'),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          children: [
            TextButton(
              onPressed: _visibleProducts.isEmpty
                  ? null
                  : () => setState(
                      () => _selected.addAll(_visibleProducts.map((e) => e.id)),
                    ),
              child: const Text('Selecionar visíveis'),
            ),
            TextButton(
              onPressed: _selected.isEmpty
                  ? null
                  : () => setState(_selected.clear),
              child: const Text('Remover seleção'),
            ),
          ],
        ),
        if (_loadingProducts)
          const AppLoadingState(label: 'Carregando produtos…')
        else if (_loadError != null)
          AppErrorState(
            title: 'Não foi possível carregar os produtos',
            message: _loadError!,
            onRetry: _loadReferences,
          )
        else if (_products.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Text(
              'Nenhum produto disponível para esta abrangência.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          for (final product in _visibleProducts)
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              ),
              child: CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _selected.contains(product.id),
                title: Text(product.nome),
                subtitle: Text('${product.codigo} · ${product.preco.currency}'),
                onChanged: (checked) => setState(
                  () => checked == true
                      ? _selected.add(product.id)
                      : _selected.remove(product.id),
                ),
              ),
            ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });
  final String label;
  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.event_outlined),
      ),
      child: Text(
        '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}',
        style: tabularFigures,
      ),
    ),
  );
}
