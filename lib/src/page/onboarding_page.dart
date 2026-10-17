import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../model/operational_repository.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, this.repository});
  final OperationalRepository? repository;
  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _form = GlobalKey<FormState>();
  final Map<String, TextEditingController> _fields = {};
  late final OperationalRepository _repository;
  bool _loading = false;
  String? _error;

  TextEditingController _controller(String key) =>
      _fields.putIfAbsent(key, TextEditingController.new);

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? OperationalRepository();
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _field(
    String key,
    String label, {
    bool secret = false,
    bool optional = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: _controller(key),
      obscureText: secret,
      decoration: InputDecoration(labelText: label),
      validator: optional
          ? null
          : (value) => value == null || value.trim().isEmpty
                ? 'Campo obrigatório'
                : null,
    ),
  );

  Map<String, dynamic> _payload() {
    String value(String key) => _controller(key).text.trim();
    final address = {
      'rua': value('logradouro'),
      'numero': value('numero'),
      'complemento': '',
      'bairro': value('bairro'),
      'cidade': value('cidade'),
      'estado': value('estado').toUpperCase(),
      'cep': value('cep').replaceAll(RegExp(r'\D'), ''),
    };
    return {
      'gestor': {
        'nome': value('gestorNome'),
        'sobrenome': value('gestorSobrenome'),
        'email': value('gestorEmail'),
        'senha': value('gestorSenha'),
        'cpf': value('gestorCpf').replaceAll(RegExp(r'\D'), ''),
        'telefone': value('gestorTelefone').replaceAll(RegExp(r'\D'), ''),
        'dataNascimento': value('gestorNascimento'),
        'roleUser': 'ADMIN',
      },
      'empresa': {
        'razaoSocial': value('razaoSocial'),
        'nomeFantasia': value('nomeFantasia'),
        'cnpj': value('empresaCnpj').replaceAll(RegExp(r'\D'), ''),
        'email': value('empresaEmail'),
        'telefone': value('empresaTelefone').replaceAll(RegExp(r'\D'), ''),
        'cep': address['cep'],
        'logradouro': address['rua'],
        'numero': address['numero'],
        'bairro': address['bairro'],
        'cidade': address['cidade'],
        'estado': address['estado'],
      },
      'condominio': {
        'nome': value('condominioNome'),
        'cnpj': value('condominioCnpj').replaceAll(RegExp(r'\D'), ''),
        'endereco': address,
      },
      'terminal': {
        'nome': value('terminalNome'),
        'serialNumber': value('terminalSerial'),
        'macAddress': value('terminalMac'),
        'ipAddress': value('terminalIp'),
      },
    };
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _repository.onboarding(_payload());
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cadastro concluído'),
          content: Text(
            'Empresa, condomínio e Terminal foram criados.\n\nTerminal: ${result['terminalId']}',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ENTRAR'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Configurar nova empresa')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppLayout.formMaxWidth),
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              Text('GESTOR', style: Theme.of(context).textTheme.titleMedium),
              _field('gestorNome', 'Nome'),
              _field('gestorSobrenome', 'Sobrenome'),
              _field('gestorEmail', 'E-mail'),
              _field('gestorSenha', 'Senha', secret: true),
              _field('gestorCpf', 'CPF'),
              _field('gestorTelefone', 'Telefone', optional: true),
              _field('gestorNascimento', 'Nascimento (aaaa-mm-dd)'),
              const Divider(height: 32),
              Text('EMPRESA', style: Theme.of(context).textTheme.titleMedium),
              _field('razaoSocial', 'Razão social'),
              _field('nomeFantasia', 'Nome fantasia'),
              _field('empresaCnpj', 'CNPJ'),
              _field('empresaEmail', 'E-mail da empresa'),
              _field('empresaTelefone', 'Telefone da empresa'),
              const Divider(height: 32),
              Text('ENDEREÇO', style: Theme.of(context).textTheme.titleMedium),
              _field('cep', 'CEP'),
              _field('logradouro', 'Logradouro'),
              _field('numero', 'Número'),
              _field('bairro', 'Bairro'),
              _field('cidade', 'Cidade'),
              _field('estado', 'UF'),
              const Divider(height: 32),
              Text(
                'PRIMEIRO CONDOMÍNIO',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              _field('condominioNome', 'Nome do condomínio'),
              _field('condominioCnpj', 'CNPJ do condomínio', optional: true),
              const Divider(height: 32),
              Text(
                'PRIMEIRO TERMINAL',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              _field('terminalNome', 'Nome do Terminal'),
              _field('terminalSerial', 'Número de série', optional: true),
              _field('terminalMac', 'Endereço MAC', optional: true),
              _field('terminalIp', 'IP local', optional: true),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('CRIAR EMPRESA'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ),
  );
}
