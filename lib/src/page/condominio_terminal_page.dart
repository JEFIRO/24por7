import 'package:flutter/material.dart';

import '../../core/widgets/app_refresh.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_content.dart';
import '../../core/widgets/async_state.dart';
import '../../core/widgets/status_badge.dart';
import '../model/operational_repository.dart';
import 'terminal_pairing.dart';

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

  Future<void> _pairTerminal(TerminalAdmin terminal) async {
    final paired = await showTerminalPairingDialog(
      context,
      repository: _repository,
      terminal: terminal,
    );
    if (paired == true) {
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terminal pareado. Ele será ativado em instantes.'),
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
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
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

  void _setFilter(String? id) {
    setState(() => _filter = id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final mobile = AppBreakpoints.isMobile(context);
    final visible = _filter == null
        ? _condominios
        : _condominios.where((item) => item.id == _filter).toList();
    return _loading
        ? const AppLoadingState(label: 'Carregando unidades e Terminais…')
        : _error != null
        ? AppErrorState(message: _error!, onRetry: _load)
        : AppRefreshIndicator(
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
                          'Unidades da empresa e os Terminais instalados em cada uma.',
                      actions: [
                        OutlinedButton.icon(
                          onPressed: _condominios.isEmpty
                              ? null
                              : () => _editTerminal(),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Novo Terminal'),
                        ),
                        FilledButton.icon(
                          onPressed: () => _editCondominio(),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Novo condomínio'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
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
                      Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.sm,
                        crossAxisAlignment: WrapCrossAlignment.end,
                        children: [
                          SizedBox(
                            width: mobile ? double.infinity : 320,
                            child: DropdownButtonFormField<String?>(
                              initialValue: _filter,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Condomínio',
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: null,
                                  child: Text(
                                    'Todos (${_condominios.length} unidades)',
                                  ),
                                ),
                                for (final item in _condominios)
                                  DropdownMenuItem(
                                    value: item.id,
                                    child: Text(item.nome),
                                  ),
                              ],
                              onChanged: _setFilter,
                            ),
                          ),
                          if (_filter != null)
                            TextButton(
                              onPressed: () => _setFilter(null),
                              child: const Text('Limpar filtro'),
                            ),
                        ],
                      ),
                      for (final condominio in visible) ...[
                        const SizedBox(height: AppSpacing.xxl),
                        _condominioSection(condominio, mobile),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          );
  }

  Widget _condominioSection(CondominioAdmin item, bool mobile) {
    final theme = Theme.of(context);
    final terminais = _terminais
        .where((terminal) => terminal.condominioId == item.id)
        .toList();
    final endereco = item.endereco;
    final meta = [
      item.cnpj?.isNotEmpty == true ? 'CNPJ ${item.cnpj}' : 'Sem CNPJ',
      if (endereco?.cidade?.isNotEmpty == true)
        [
          if (endereco!.rua?.isNotEmpty == true)
            '${endereco.rua}${endereco.numero?.isNotEmpty == true ? ', ${endereco.numero}' : ''}',
          '${endereco.cidade}${endereco.estado?.isNotEmpty == true ? '/${endereco.estado}' : ''}',
        ].join(' – '),
    ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIconWell(
              item.ativo ? Icons.apartment_outlined : Icons.domain_disabled,
              color: item.ativo ? null : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(item.nome, style: theme.textTheme.titleLarge),
                      if (!item.ativo) const AppStatusBadge(label: 'Inativo'),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (!mobile)
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/monitoramento'),
                child: const Text('Ver monitoramento'),
              ),
            IconButton(
              tooltip: 'Editar condomínio',
              onPressed: () => _editCondominio(item),
              icon: const Icon(Icons.edit_outlined),
            ),
            PopupMenuButton<String>(
              tooltip: 'Mais ações',
              onSelected: (action) async {
                if (action == 'terminal') await _editTerminal();
                if (action == 'disable') await _disableCondominio(item);
              },
              itemBuilder: (_) => [
                if (item.ativo)
                  const PopupMenuItem(
                    value: 'terminal',
                    child: Text('Novo Terminal'),
                  ),
                if (item.ativo)
                  const PopupMenuItem(
                    value: 'disable',
                    child: Text('Desativar'),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (terminais.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            decoration: BoxDecoration(
              border: Border.symmetric(
                horizontal: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
            child: Text(
              'Este condomínio ainda não possui Terminal.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else if (mobile)
          for (final terminal in terminais)
            AppListRow(
              title: terminal.nome,
              meta: [
                if (terminal.serialNumber?.isNotEmpty == true)
                  'Série ${terminal.serialNumber}',
                terminal.mercadoPagoTerminalId == null
                    ? 'Point não vinculada'
                    : 'Point configurada',
              ].join(' · '),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _terminalStatus(terminal),
                  IconButton(
                    tooltip: 'Parear Terminal',
                    onPressed: () => _pairTerminal(terminal),
                    icon: const Icon(Icons.qr_code_scanner),
                  ),
                ],
              ),
              onTap: () =>
                  Navigator.pushNamed(context, '/terminais/${terminal.id}'),
            )
        else
          AppTable(
            columns: const [
              DataColumn(label: Text('Nome')),
              DataColumn(label: Text('Número de série')),
              DataColumn(label: Text('IP local')),
              DataColumn(label: Text('Point')),
              DataColumn(label: Text('Status')),
              DataColumn(label: SizedBox.shrink()),
            ],
            rows: [
              for (final terminal in terminais)
                DataRow(
                  onSelectChanged: (_) =>
                      Navigator.pushNamed(context, '/terminais/${terminal.id}'),
                  cells: [
                    DataCell(
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            terminal.nome,
                            style: theme.textTheme.titleSmall,
                          ),
                          if (terminal.versaoSoftware != null)
                            Text(
                              'Versão ${terminal.versaoSoftware}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    DataCell(_orDash(terminal.serialNumber)),
                    DataCell(_orDash(terminal.ipAddress)),
                    DataCell(
                      Text(
                        terminal.mercadoPagoTerminalId == null
                            ? 'Não vinculada'
                            : 'Configurada',
                        style: terminal.mercadoPagoTerminalId == null
                            ? TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                              )
                            : null,
                      ),
                    ),
                    DataCell(_terminalStatus(terminal)),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Parear Terminal',
                            onPressed: () => _pairTerminal(terminal),
                            icon: const Icon(Icons.qr_code_scanner),
                          ),
                          IconButton(
                            tooltip: 'Editar Terminal',
                            onPressed: () => _editTerminal(terminal),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
      ],
    );
  }

  Widget _orDash(String? value) => Text(
    value?.isNotEmpty == true ? value! : '—',
    style: value?.isNotEmpty == true
        ? null
        : TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
  );

  Widget _terminalStatus(TerminalAdmin terminal) => switch (terminal.status) {
    'ONLINE' => const AppStatusBadge(
      label: 'Online',
      tone: AppStatusTone.success,
    ),
    'OFFLINE' => const AppStatusBadge(label: 'Offline'),
    'MANUTENCAO' => const AppStatusBadge(
      label: 'Manutenção',
      tone: AppStatusTone.warning,
    ),
    final other => AppStatusBadge(
      label: other.isEmpty
          ? 'Sem status'
          : '${other[0]}${other.substring(1).toLowerCase()}',
    ),
  };
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
  final _codigo = TextEditingController();
  late String _condominioId;
  // Se o pareamento falhar depois do cadastro, um novo "Salvar" não duplica o Terminal.
  String? _createdId;
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
    _codigo.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final saved = await widget.repository.salvarTerminal(
        id: widget.current?.id ?? _createdId,
        condominioId: _condominioId,
        nome: _nome.text.trim(),
        serialNumber: _serial.text.trim(),
        macAddress: _mac.text.trim(),
        ipAddress: _ip.text.trim(),
      );
      _createdId = saved.id;
      final code = parsePairingCode(_codigo.text);
      if (code != null) {
        try {
          await widget.repository.parearTerminal(saved.id, code);
        } catch (error) {
          if (mounted) {
            setState(
              () => _error =
                  'Terminal salvo, mas não pareado: ${pairingErrorMessage(error)}',
            );
          }
          return;
        }
      }
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
            PairingCodeField(controller: _codigo, enabled: !_loading),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _serial,
              decoration: const InputDecoration(
                labelText: 'Número de série',
                helperText: 'Preenchido automaticamente ao parear',
              ),
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
