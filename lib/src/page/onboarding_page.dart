import 'package:flutter/material.dart';

import '../../core/theme/app_brand.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/theme/app_motion.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_content.dart';
import '../../core/widgets/status_badge.dart';
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
  int _step = 0;

  /// Sentido da última troca de etapa, para a direção da transição.
  bool _forward = true;

  static const _steps = [
    'Gestor',
    'Empresa',
    'Primeiro condomínio',
    'Primeiro Terminal',
  ];

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
    String? helper,
    TextInputType? keyboard,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
    child: TextFormField(
      controller: _controller(key),
      obscureText: secret,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: optional ? '$label (opcional)' : label,
        helperText: helper,
      ),
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
          icon: const AppSuccessMark(),
          title: Text(
            'Cadastro concluído',
            style: AppBrand.display(Theme.of(context).textTheme.titleLarge),
          ),
          content: Text(
            'Empresa, condomínio e Terminal foram criados.\n\nTerminal: ${result['terminalId']}',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entrar'),
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

  void _next() {
    if (!_form.currentState!.validate()) return;
    if (_step == _steps.length - 1) {
      _submit();
    } else {
      setState(() {
        _forward = true;
        _step++;
      });
    }
  }

  Widget _pair(Widget a, Widget b) => LayoutBuilder(
    builder: (context, constraints) => constraints.maxWidth < 480
        ? Column(children: [a, b])
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: a),
              const SizedBox(width: AppSpacing.xl),
              Expanded(child: b),
            ],
          ),
  );

  Widget _groupLabel(String text) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        letterSpacing: .5,
      ),
    ),
  );

  List<Widget> _stepFields() => switch (_step) {
    0 => [
      _pair(
        _field('gestorNome', 'Nome'),
        _field('gestorSobrenome', 'Sobrenome'),
      ),
      _pair(
        _field('gestorCpf', 'CPF', keyboard: TextInputType.number),
        _field(
          'gestorNascimento',
          'Nascimento',
          helper: 'Formato aaaa-mm-dd',
          keyboard: TextInputType.datetime,
        ),
      ),
      _pair(
        _field('gestorEmail', 'E-mail', keyboard: TextInputType.emailAddress),
        _field(
          'gestorTelefone',
          'Telefone',
          optional: true,
          keyboard: TextInputType.phone,
        ),
      ),
      _field('gestorSenha', 'Senha', secret: true),
    ],
    1 => [
      _pair(
        _field('empresaCnpj', 'CNPJ', keyboard: TextInputType.number),
        _field('razaoSocial', 'Razão social'),
      ),
      _field('nomeFantasia', 'Nome fantasia'),
      _pair(
        _field(
          'empresaEmail',
          'E-mail da empresa',
          keyboard: TextInputType.emailAddress,
        ),
        _field(
          'empresaTelefone',
          'Telefone da empresa',
          keyboard: TextInputType.phone,
        ),
      ),
      _groupLabel('ENDEREÇO'),
      _pair(
        _field('cep', 'CEP', keyboard: TextInputType.number),
        _field('logradouro', 'Logradouro'),
      ),
      _pair(_field('numero', 'Número'), _field('bairro', 'Bairro')),
      _pair(_field('cidade', 'Cidade'), _field('estado', 'UF')),
    ],
    2 => [
      _field('condominioNome', 'Nome do condomínio'),
      _field('condominioCnpj', 'CNPJ do condomínio', optional: true),
      Text(
        'O condomínio usa o endereço informado na etapa Empresa.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
    _ => [
      _field('terminalNome', 'Nome do Terminal'),
      _pair(
        _field('terminalSerial', 'Número de série', optional: true),
        _field('terminalMac', 'Endereço MAC', optional: true),
      ),
      _field('terminalIp', 'IP local', optional: true),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mobile = AppBreakpoints.isMobile(context);
    final last = _step == _steps.length - 1;
    final form = Form(
      key: _form,
      child: ListView(
        padding: EdgeInsets.all(mobile ? AppSpacing.lg : AppSpacing.section),
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppLayout.formMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // A etapa nova entra do lado para onde se avança.
                AnimatedSwitcher(
                  duration: AppMotion.of(context, AppMotion.base),
                  switchInCurve: AppMotion.enter,
                  switchOutCurve: AppMotion.exit,
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.topCenter,
                    children: [...previous, ?current],
                  ),
                  transitionBuilder: (child, animation) {
                    final entering = child.key == ValueKey(_step);
                    final from = (_forward ? 1 : -1) * (entering ? 1 : -1);
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween(
                          begin: Offset(.04 * from, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    key: ValueKey(_step),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'PASSO ${_step + 1} DE ${_steps.length}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          letterSpacing: .5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _steps[_step],
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      ..._stepFields(),
                    ],
                  ),
                ),
                AppReveal(
                  child: _error == null
                      ? null
                      : Padding(
                          key: ValueKey(_error),
                          padding: const EdgeInsets.only(top: AppSpacing.md),
                          child: AppBanner(
                            tone: AppStatusTone.critical,
                            message: _error!,
                          ),
                        ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    if (_step > 0)
                      TextButton(
                        onPressed: _loading
                            ? null
                            : () => setState(() {
                                _forward = false;
                                _step--;
                              }),
                        child: const Text('Voltar'),
                      ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _loading ? null : _next,
                      iconAlignment: IconAlignment.end,
                      icon: AppBusyIcon(
                        busy: _loading,
                        icon: last ? Icons.check : Icons.arrow_forward,
                      ),
                      label: Text(
                        _loading
                            ? 'Criando…'
                            : last
                            ? 'Criar empresa'
                            : 'Continuar',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return Scaffold(
      appBar: mobile
          ? AppBar(title: const Text('Configurar nova empresa'))
          : null,
      body: SafeArea(
        child: mobile
            ? form
            : Row(
                children: [
                  Container(
                    width: 300,
                    color: theme.colorScheme.surface,
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                          tooltip: 'Voltar ao login',
                          onPressed: () => Navigator.maybePop(context),
                          icon: const Icon(Icons.arrow_back),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        const BrandLogo(size: 88),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Configurar nova empresa',
                          style: AppBrand.display(theme.textTheme.titleLarge),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Quatro etapas, enviadas juntas no final.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        for (var i = 0; i < _steps.length; i++)
                          _StepRow(
                            index: i,
                            label: _steps[i],
                            current: i == _step,
                            done: i < _step,
                          ),
                      ],
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: form),
                ],
              ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.index,
    required this.label,
    required this.current,
    required this.done,
  });
  final int index;
  final String label;
  final bool current;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          AppStepDot(number: index + 1, current: current, done: done),
          const SizedBox(width: AppSpacing.md),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: current ? scheme.onSurface : scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
