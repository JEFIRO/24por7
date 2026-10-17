import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_content.dart';
import '../../core/widgets/async_state.dart';
import '../model/operational_repository.dart';

class CondominioTerminalPage extends StatefulWidget {
  const CondominioTerminalPage({super.key, this.repository});
  final OperationalRepository? repository;

  @override
  State<CondominioTerminalPage> createState() => _CondominioTerminalPageState();
}

class _CondominioTerminalPageState extends State<CondominioTerminalPage> {
  late final OperationalRepository _repository;
  bool _loading = true;
  String? _error;
  List<CondominioAdmin> _condominios = const [];
  List<TerminalAdmin> _terminais = const [];
  String? _filter;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? OperationalRepository();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final values = await Future.wait<dynamic>([
        _repository.condominios(),
        _repository.terminais(condominioId: _filter),
      ]);
      if (!mounted) return;
      setState(() {
        _condominios = values[0] as List<CondominioAdmin>;
        _terminais = values[1] as List<TerminalAdmin>;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editCondominio([CondominioAdmin? current]) async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) =>
          _CondominioDialog(repository: _repository, current: current),
    );
    if (changed == true) {
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              current == null
                  ? 'Condomínio cadastrado.'
                  : 'Condomínio atualizado.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _editTerminal([TerminalAdmin? current]) async {
    if (_condominios.isEmpty) return;
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => _TerminalDialog(
        repository: _repository,
        condominios: _condominios.where((item) => item.ativo).toList(),
        initialCondominioId: current?.condominioId ?? _filter,
        current: current,
      ),
    );
    if (changed == true) {
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              current == null ? 'Terminal cadastrado.' : 'Terminal atualizado.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _disableCondominio(CondominioAdmin item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desativar condomínio?'),
        content: Text(
          '${item.nome} deixará de aceitar novas operações administrativas. O histórico será preservado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Desativar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repository.desativarCondominio(item.id);
      await _load();
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
    appBar: AppBar(
      title: const Text('Operação'),
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: _loading
        ? const AppLoadingState(label: 'Carregando unidades e Terminais…')
        : _error != null
        ? AppErrorState(message: _error!, onRetry: _load)
        : RefreshIndicator(
            onRefresh: _load,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: AppContent(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppPageHeader(
                      title: 'Condomínios e Terminais',
                      subtitle:
                          'Gerencie as unidades do tenant e acompanhe seus equipamentos.',
                      actions: [
                        OutlinedButton.icon(
                          onPressed: () => _editCondominio(),
                          icon: const Icon(Icons.add_business),
                          label: const Text('Novo condomínio'),
                        ),
                        FilledButton.icon(
                          onPressed: _condominios.isEmpty
                              ? null
                              : () => _editTerminal(),
                          icon: const Icon(Icons.add_to_queue),
                          label: const Text('Novo Terminal'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    LayoutBuilder(
                      builder: (context, constraints) =>
                          constraints.maxWidth >= 980
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(width: 360, child: _condominioPanel()),
                                const SizedBox(width: AppSpacing.xl),
                                Expanded(child: _terminalPanel()),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _condominioPanel(),
                                const SizedBox(height: AppSpacing.xl),
                                _terminalPanel(),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
  );

  Widget _condominioPanel() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Condomínios', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: AppSpacing.md),
      if (_condominios.isEmpty)
        AppEmptyState(
          icon: Icons.apartment_outlined,
          title: 'Nenhum condomínio cadastrado',
          message:
              'Cadastre a primeira unidade para vincular Terminais e estoque.',
          action: FilledButton(
            onPressed: () => _editCondominio(),
            child: const Text('Cadastrar condomínio'),
          ),
        )
      else ...[
        Card(
          child: ListTile(
            selected: _filter == null,
            leading: const Icon(Icons.domain),
            title: const Text('Todos os condomínios'),
            subtitle: Text('${_condominios.length} unidades'),
            onTap: () {
              setState(() => _filter = null);
              _load();
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ..._condominios.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Card(
              child: ListTile(
                selected: _filter == item.id,
                leading: Icon(
                  item.ativo ? Icons.apartment : Icons.domain_disabled,
                ),
                title: Text(item.nome),
                subtitle: Text(
                  [
                    item.cnpj?.isNotEmpty == true ? item.cnpj! : 'Sem CNPJ',
                    if (item.endereco?.cidade != null)
                      '${item.endereco!.cidade}/${item.endereco!.estado ?? ''}',
                  ].join(' • '),
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (action) async {
                    if (action == 'edit') await _editCondominio(item);
                    if (action == 'terminals') {
                      setState(() => _filter = item.id);
                      await _load();
                    }
                    if (action == 'disable') {
                      await _disableCondominio(item);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'terminals',
                      child: Text('Ver Terminais'),
                    ),
                    const PopupMenuItem(value: 'edit', child: Text('Editar')),
                    if (item.ativo)
                      const PopupMenuItem(
                        value: 'disable',
                        child: Text('Desativar'),
                      ),
                  ],
                ),
                onTap: () {
                  setState(() => _filter = item.id);
                  _load();
                },
              ),
            ),
          ),
        ),
      ],
    ],
  );

  Widget _terminalPanel() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              'Terminais',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          if (_filter != null)
            TextButton(
              onPressed: () {
                setState(() => _filter = null);
                _load();
              },
              child: const Text('Limpar filtro'),
            ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      if (_terminais.isEmpty)
        AppEmptyState(
          icon: Icons.desktop_windows_outlined,
          title: 'Nenhum Terminal encontrado',
          message: _filter == null
              ? 'Cadastre o primeiro Terminal da operação.'
              : 'Este condomínio ainda não possui Terminal.',
          action: _condominios.isEmpty
              ? null
              : FilledButton(
                  onPressed: () => _editTerminal(),
                  child: const Text('Cadastrar Terminal'),
                ),
        )
      else
        ..._terminais.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(AppSpacing.lg),
                leading: CircleAvatar(
                  child: Icon(
                    item.status == 'ONLINE'
                        ? Icons.desktop_windows
                        : Icons.desktop_access_disabled,
                  ),
                ),
                title: Text(item.nome),
                subtitle: Text(
                  [
                    if (item.codigo.isNotEmpty) 'Código ${item.codigo}',
                    item.mercadoPagoTerminalId == null
                        ? 'Point não vinculada'
                        : 'Point configurada',
                    if (item.versaoSoftware != null)
                      'Versão ${item.versaoSoftware}',
                    item.status,
                  ].join(' • '),
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (action) {
                    if (action == 'edit') _editTerminal(item);
                    if (action == 'detail') {
                      Navigator.pushNamed(context, '/terminais/${item.id}');
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'detail',
                      child: Text('Ver monitoramento'),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Editar Terminal'),
                    ),
                  ],
                ),
                onTap: () =>
                    Navigator.pushNamed(context, '/terminais/${item.id}'),
              ),
            ),
          ),
        ),
    ],
  );
}

class _CondominioDialog extends StatefulWidget {
  const _CondominioDialog({required this.repository, this.current});
  final OperationalRepository repository;
  final CondominioAdmin? current;

  @override
  State<_CondominioDialog> createState() => _CondominioDialogState();
}

class _CondominioDialogState extends State<_CondominioDialog> {
  final _form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final value = widget.current;
    _controllers = {
      'nome': TextEditingController(text: value?.nome),
      'cnpj': TextEditingController(text: value?.cnpj),
      'rua': TextEditingController(text: value?.endereco?.rua),
      'numero': TextEditingController(text: value?.endereco?.numero),
      'complemento': TextEditingController(text: value?.endereco?.complemento),
      'bairro': TextEditingController(text: value?.endereco?.bairro),
      'cidade': TextEditingController(text: value?.endereco?.cidade),
      'estado': TextEditingController(text: value?.endereco?.estado),
      'cep': TextEditingController(text: value?.endereco?.cep),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String value(String key) => _controllers[key]!.text.trim();

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.repository.salvarCondominio(
        id: widget.current?.id,
        nome: value('nome'),
        cnpj: value('cnpj').isEmpty
            ? null
            : value('cnpj').replaceAll(RegExp(r'\D'), ''),
        endereco: AddressAdmin(
          rua: value('rua'),
          numero: value('numero'),
          complemento: value('complemento'),
          bairro: value('bairro'),
          cidade: value('cidade'),
          estado: value('estado').toUpperCase(),
          cep: value('cep').replaceAll(RegExp(r'\D'), ''),
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.current == null ? 'Novo condomínio' : 'Editar condomínio',
    ),
    content: SizedBox(
      width: 620,
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _field('nome', 'Nome', required: true),
              _field('cnpj', 'CNPJ'),
              _field('cep', 'CEP'),
              _field('rua', 'Logradouro'),
              Row(
                children: [
                  Expanded(child: _field('numero', 'Número')),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _field('complemento', 'Complemento')),
                ],
              ),
              _field('bairro', 'Bairro'),
              Row(
                children: [
                  Expanded(flex: 3, child: _field('cidade', 'Cidade')),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _field('estado', 'UF')),
                ],
              ),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _loading ? null : () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: _loading ? null : _save,
        child: Text(_loading ? 'Salvando…' : 'Salvar'),
      ),
    ],
  );

  Widget _field(String key, String label, {bool required = false}) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: TextFormField(
      controller: _controllers[key],
      decoration: InputDecoration(labelText: label),
      validator: required
          ? (text) =>
                text == null || text.trim().isEmpty ? 'Campo obrigatório' : null
          : null,
    ),
  );
}

class _TerminalDialog extends StatefulWidget {
  const _TerminalDialog({
    required this.repository,
    required this.condominios,
    this.initialCondominioId,
    this.current,
  });
  final OperationalRepository repository;
  final List<CondominioAdmin> condominios;
  final String? initialCondominioId;
  final TerminalAdmin? current;

  @override
  State<_TerminalDialog> createState() => _TerminalDialogState();
}

class _TerminalDialogState extends State<_TerminalDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late final TextEditingController _serial;
  late final TextEditingController _mac;
  late final TextEditingController _ip;
  late String _condominioId;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nome = TextEditingController(text: widget.current?.nome);
    _serial = TextEditingController(text: widget.current?.serialNumber);
    _mac = TextEditingController(text: widget.current?.macAddress);
    _ip = TextEditingController(text: widget.current?.ipAddress);
    _condominioId =
        widget.condominios.any((item) => item.id == widget.initialCondominioId)
        ? widget.initialCondominioId!
        : widget.condominios.first.id;
  }

  @override
  void dispose() {
    _nome.dispose();
    _serial.dispose();
    _mac.dispose();
    _ip.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.repository.salvarTerminal(
        id: widget.current?.id,
        condominioId: _condominioId,
        nome: _nome.text.trim(),
        serialNumber: _serial.text.trim(),
        macAddress: _mac.text.trim(),
        ipAddress: _ip.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.current == null ? 'Novo Terminal' : 'Editar Terminal'),
    content: SizedBox(
      width: 560,
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _condominioId,
              decoration: const InputDecoration(labelText: 'Condomínio'),
              items: widget.condominios
                  .map(
                    (item) => DropdownMenuItem(
                      value: item.id,
                      child: Text(item.nome),
                    ),
                  )
                  .toList(),
              onChanged: widget.current != null
                  ? null
                  : (value) => setState(() => _condominioId = value!),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _nome,
              decoration: const InputDecoration(labelText: 'Nome'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Campo obrigatório'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _serial,
              decoration: const InputDecoration(labelText: 'Número de série'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _mac,
              decoration: const InputDecoration(labelText: 'Endereço MAC'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _ip,
              decoration: const InputDecoration(labelText: 'IP local'),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _loading ? null : () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: _loading ? null : _save,
        child: Text(_loading ? 'Salvando…' : 'Salvar'),
      ),
    ],
  );
}
