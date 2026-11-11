import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/formatters/mask_input_formatter.dart';
import '../../core/navigation/app_routes.dart';
import '../../core/theme/app_brand.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_content.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/status_badge.dart';
import '../model/api_client.dart';
import '../model/empresa_branding.dart';
import '../model/operational_repository.dart';
import 'scanner_page.dart';
import 'terminal_pairing.dart';

/// Cadastro de uma nova Empresa em passos curtos: uma pergunta por tela,
/// poucos campos de cada vez, e uma revisão antes de enviar tudo junto.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, this.repository, this.login});
  final OperationalRepository? repository;

  /// Entra como o gestor recém-criado, para parear o Terminal logo após o
  /// cadastro. Padrão: login do painel.
  final Future<void> Function(String cpf, String senha)? login;
  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _form = GlobalKey<FormState>();
  final Map<String, TextEditingController> _fields = {};
  late final OperationalRepository _repository;
  bool _loading = false;
  bool _showPassword = false;
  bool _showTechnical = false;
  String? _error;
  int _step = 0;

  /// Sentido da última troca de etapa, para a direção da transição.
  bool _forward = true;

  static const _stepCount = 10;
  static const _reviewStep = _stepCount - 1;

  TextEditingController _controller(String key) =>
      _fields.putIfAbsent(key, TextEditingController.new);

  String _value(String key) => _controller(key).text.trim();
  String _digits(String key) => _value(key).replaceAll(RegExp(r'\D'), '');

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

  // ---- Validações -------------------------------------------------------

  static String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Preencha este campo' : null;

  static FormFieldValidator<String> _digitCount(
    int count,
    String message, {
    bool optional = false,
  }) => (value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return optional ? null : 'Preencha este campo';
    return digits.length == count ? null : message;
  };

  static String? _email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Preencha este campo';
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)
        ? null
        : 'Digite um e-mail válido';
  }

  static String? _phone(String? value, {bool optional = false}) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return optional ? null : 'Preencha este campo';
    return digits.length >= 10 ? null : 'Digite o telefone com DDD';
  }

  /// Data real e passada no formato `dd/mm/aaaa`, o mesmo que o back lê.
  static bool _validDate(String text) {
    final match = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(text.trim());
    if (match == null) return false;
    final day = int.parse(match[1]!);
    final month = int.parse(match[2]!);
    final year = int.parse(match[3]!);
    final date = DateTime(year, month, day);
    return date.day == day &&
        date.month == month &&
        year >= 1900 &&
        date.isBefore(DateTime.now());
  }

  static String? _birthDate(String? value) {
    if (value == null || value.trim().isEmpty) return 'Preencha este campo';
    return _validDate(value) ? null : 'Digite uma data válida';
  }

  static String? _password(String? value) {
    final length = value?.length ?? 0;
    if (length == 0) return 'Preencha este campo';
    if (length < 6) return 'Use pelo menos 6 caracteres';
    return length > 72 ? 'Use no máximo 72 caracteres' : null;
  }

  static String? _pairingCode(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return parsePairingCode(value) == null
        ? 'O código tem 8 letras ou números'
        : null;
  }

  static String? _uf(String? value) =>
      RegExp(r'^[A-Za-z]{2}$').hasMatch(value?.trim() ?? '')
      ? null
      : 'Use a sigla, ex.: SP';

  // ---- Envio ------------------------------------------------------------

  Map<String, dynamic> _payload() {
    final address = {
      'rua': _value('logradouro'),
      'numero': _value('numero'),
      'complemento': '',
      'bairro': _value('bairro'),
      'cidade': _value('cidade'),
      'estado': _value('estado').toUpperCase(),
      'cep': _digits('cep'),
    };
    return {
      'gestor': {
        'nome': _value('gestorNome'),
        'sobrenome': _value('gestorSobrenome'),
        'email': _value('gestorEmail'),
        'senha': _value('gestorSenha'),
        'cpf': _digits('gestorCpf'),
        'telefone': _digits('gestorTelefone'),
        'dataNascimento': _value('gestorNascimento'),
        'roleUser': 'ADMIN',
      },
      'empresa': {
        'razaoSocial': _value('razaoSocial'),
        'nomeFantasia': _value('nomeFantasia'),
        'cnpj': _digits('empresaCnpj'),
        'email': _value('empresaEmail'),
        'telefone': _digits('empresaTelefone'),
        'cep': address['cep'],
        'logradouro': address['rua'],
        'numero': address['numero'],
        'bairro': address['bairro'],
        'cidade': address['cidade'],
        'estado': address['estado'],
      },
      'condominio': {
        'nome': _value('condominioNome'),
        'cnpj': _digits('condominioCnpj'),
        'endereco': address,
      },
      'terminal': {
        'nome': _value('terminalNome'),
        'serialNumber': _value('terminalSerial'),
        'macAddress': _value('terminalMac'),
        'ipAddress': _value('terminalIp'),
      },
    };
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _repository.onboarding(_payload());
      final pairing = await _pair(result['terminalId']?.toString());
      if (!mounted) return;
      // O envio acabou: o botão para de girar atrás do diálogo.
      setState(() => _loading = false);
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          icon: const AppSuccessMark(),
          title: Text(
            'Cadastro concluído',
            style: AppBrand.display(Theme.of(context).textTheme.titleLarge),
          ),
          content: Text(
            [
              'Empresa, condomínio e Terminal foram criados.',
              ?pairing.message,
            ].join('\n\n'),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entrar'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (pairing.loggedIn) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.dashboard,
          (_) => false,
        );
      } else {
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is ApiException
              ? error.friendlyMessage
              : error.toString(),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Com código informado, entra como o gestor novo e vincula o equipamento
  /// ao Terminal criado. Falha aqui não desfaz o cadastro: avisa e segue.
  Future<({bool loggedIn, String? message})> _pair(String? terminalId) async {
    final code = parsePairingCode(_value('terminalCodigo'));
    if (code == null || terminalId == null) {
      return (loggedIn: false, message: null);
    }
    try {
      await (widget.login ?? _repository.client.loginAdmin)(
        _digits('gestorCpf'),
        _value('gestorSenha'),
      );
    } catch (_) {
      return (
        loggedIn: false,
        message:
            'Não foi possível parear agora. Entre no painel e pareie em Terminais.',
      );
    }
    await loadBranding();
    try {
      await _repository.parearTerminal(terminalId, code);
      return (loggedIn: true, message: 'O Terminal já está pareado.');
    } catch (error) {
      return (
        loggedIn: true,
        message:
            'O Terminal não foi pareado: ${pairingErrorMessage(error)} '
            'Você pode tentar de novo em Terminais.',
      );
    }
  }

  Future<void> _scanPairingCode() async {
    final raw = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const ScannerPage(
          title: 'Parear Terminal',
          hint: 'Aponte para o QR Code na tela do Terminal',
        ),
      ),
    );
    if (raw == null || !mounted) return;
    final code = parsePairingCode(raw);
    if (code == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este QR Code não é de pareamento do Terminal.'),
        ),
      );
      return;
    }
    setState(() => _controller('terminalCodigo').text = code);
  }

  void _goTo(int step) => setState(() {
    _forward = step > _step;
    _step = step;
    _error = null;
  });

  void _next() {
    if (_loading) return;
    if (!_form.currentState!.validate()) return;
    if (_step == _reviewStep) {
      _submit();
    } else {
      _goTo(_step + 1);
    }
  }

  void _back() {
    if (_loading) return;
    if (_step == 0) {
      Navigator.maybePop(context);
    } else {
      _goTo(_step - 1);
    }
  }

  // ---- Campos -----------------------------------------------------------

  /// Campo preenchido e arredondado. O primeiro de cada etapa recebe o foco;
  /// o último avança a etapa ao confirmar no teclado.
  Widget _field(
    String key,
    String label, {
    FormFieldValidator<String>? validator = _required,
    String? hint,
    String? helper,
    TextInputType? keyboard,
    TextInputFormatter? mask,
    List<TextInputFormatter> formatters = const [],
    TextCapitalization capitalization = TextCapitalization.none,
    Iterable<String>? autofill,
    bool secret = false,
    Widget? suffix,
    bool first = false,
    bool last = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    // Sem linha nem contorno: o rótulo fica dentro do campo e o foco é
    // marcado pela cor do preenchimento.
    final border = UnderlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      borderSide: BorderSide.none,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        key: Key('onboarding-$key'),
        controller: _controller(key),
        autofocus: first,
        obscureText: secret && !_showPassword,
        keyboardType: keyboard,
        textCapitalization: capitalization,
        autofillHints: autofill,
        inputFormatters: [?mask, ...formatters],
        textInputAction: last ? TextInputAction.done : TextInputAction.next,
        onFieldSubmitted: last ? (_) => _next() : null,
        style: Theme.of(context).textTheme.titleMedium,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          helperText: helper,
          filled: true,
          fillColor: WidgetStateColor.resolveWith(
            (states) => states.contains(WidgetState.error)
                ? scheme.errorContainer.withValues(alpha: .45)
                : states.contains(WidgetState.focused)
                ? scheme.primaryContainer
                : scheme.surfaceContainer,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          contentPadding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          border: border,
          enabledBorder: border,
          disabledBorder: border,
          focusedBorder: border,
          errorBorder: border,
          focusedErrorBorder: border,
          suffixIcon: secret
              ? IconButton(
                  tooltip: _showPassword ? 'Esconder senha' : 'Mostrar senha',
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                  icon: Icon(
                    _showPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                )
              : suffix,
        ),
        validator: validator,
      ),
    );
  }

  Widget _row(Widget a, Widget b, {int flexA = 1, int flexB = 1}) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(flex: flexA, child: a),
      const SizedBox(width: AppSpacing.md),
      Expanded(flex: flexB, child: b),
    ],
  );

  // ---- Etapas -----------------------------------------------------------

  (String title, String subtitle) _heading() => switch (_step) {
    0 => ('Como você se chama?', 'Você será o gestor da Empresa no painel.'),
    1 => ('Seus documentos', 'Usamos o CPF para o seu acesso ao painel.'),
    2 => ('Como falamos com você?', 'Avisos da operação chegam por aqui.'),
    3 => ('Crie sua senha', 'Você entra no painel com o CPF e esta senha.'),
    4 => ('Qual é a sua empresa?', 'Os dados de quem opera os mercados.'),
    5 => ('Contato da empresa', 'E-mail e telefone comerciais.'),
    6 => ('Onde fica a empresa?', 'O primeiro condomínio usa este endereço.'),
    7 => (
      'Seu primeiro condomínio',
      'Onde o mercado autônomo vai funcionar. Você cadastra os outros depois.',
    ),
    8 => (
      'Seu primeiro Terminal',
      'O caixa de autoatendimento do condomínio. Com ele ligado, leia o QR Code da tela para vincular.',
    ),
    _ => (
      'Tudo certo?',
      'Confira antes de criar. Toque em um item para corrigir.',
    ),
  };

  List<Widget> _stepFields() => switch (_step) {
    0 => [
      _field(
        'gestorNome',
        'Nome',
        first: true,
        capitalization: TextCapitalization.words,
        autofill: const [AutofillHints.givenName],
      ),
      _field(
        'gestorSobrenome',
        'Sobrenome',
        last: true,
        capitalization: TextCapitalization.words,
        autofill: const [AutofillHints.familyName],
      ),
    ],
    1 => [
      _field(
        'gestorCpf',
        'CPF',
        first: true,
        keyboard: TextInputType.number,
        mask: MaskInputFormatter.cpf,
        validator: _digitCount(11, 'O CPF tem 11 números'),
      ),
      _field(
        'gestorNascimento',
        'Data de nascimento',
        last: true,
        hint: 'dd/mm/aaaa',
        keyboard: TextInputType.number,
        mask: MaskInputFormatter.date,
        validator: _birthDate,
      ),
    ],
    2 => [
      _field(
        'gestorEmail',
        'E-mail',
        first: true,
        keyboard: TextInputType.emailAddress,
        autofill: const [AutofillHints.email],
        validator: _email,
      ),
      _field(
        'gestorTelefone',
        'Celular (opcional)',
        last: true,
        keyboard: TextInputType.phone,
        mask: MaskInputFormatter.phone,
        validator: (value) => _phone(value, optional: true),
      ),
    ],
    3 => [
      _field(
        'gestorSenha',
        'Senha',
        first: true,
        last: true,
        secret: true,
        helper: 'Pelo menos 6 caracteres.',
        validator: _password,
        autofill: const [AutofillHints.newPassword],
      ),
    ],
    4 => [
      _field(
        'empresaCnpj',
        'CNPJ',
        first: true,
        keyboard: TextInputType.number,
        mask: MaskInputFormatter.cnpj,
        validator: _digitCount(14, 'O CNPJ tem 14 números'),
      ),
      _field(
        'razaoSocial',
        'Razão social',
        capitalization: TextCapitalization.words,
      ),
      _field(
        'nomeFantasia',
        'Nome fantasia',
        last: true,
        helper: 'O nome que aparece no painel.',
        capitalization: TextCapitalization.words,
      ),
    ],
    5 => [
      _field(
        'empresaEmail',
        'E-mail da empresa',
        first: true,
        keyboard: TextInputType.emailAddress,
        validator: _email,
      ),
      _field(
        'empresaTelefone',
        'Telefone da empresa',
        last: true,
        keyboard: TextInputType.phone,
        mask: MaskInputFormatter.phone,
        validator: _phone,
      ),
    ],
    6 => [
      _row(
        _field(
          'cep',
          'CEP',
          first: true,
          keyboard: TextInputType.number,
          mask: MaskInputFormatter.cep,
          validator: _digitCount(8, 'O CEP tem 8 números'),
        ),
        _field('numero', 'Número', keyboard: TextInputType.number),
        flexA: 3,
        flexB: 2,
      ),
      _field(
        'logradouro',
        'Rua ou avenida',
        capitalization: TextCapitalization.words,
      ),
      _field('bairro', 'Bairro', capitalization: TextCapitalization.words),
      _row(
        _field('cidade', 'Cidade', capitalization: TextCapitalization.words),
        _field(
          'estado',
          'UF',
          last: true,
          capitalization: TextCapitalization.characters,
          formatters: [
            LengthLimitingTextInputFormatter(2),
            const _UpperCaseFormatter(),
          ],
          validator: _uf,
        ),
        flexA: 3,
        flexB: 1,
      ),
    ],
    7 => [
      _field(
        'condominioNome',
        'Nome do condomínio',
        first: true,
        capitalization: TextCapitalization.words,
      ),
      _field(
        'condominioCnpj',
        'CNPJ do condomínio (opcional)',
        last: true,
        keyboard: TextInputType.number,
        mask: MaskInputFormatter.cnpj,
        validator: _digitCount(14, 'O CNPJ tem 14 números', optional: true),
      ),
    ],
    8 => [
      _field(
        'terminalNome',
        'Nome do Terminal',
        first: true,
        hint: 'Ex.: Portaria',
        capitalization: TextCapitalization.words,
      ),
      _field(
        'terminalCodigo',
        'Código de pareamento (opcional)',
        last: !_showTechnical,
        hint: 'XXXX-XXXX',
        helper: 'Aparece na tela do Terminal. Leia o QR Code ou digite.',
        capitalization: TextCapitalization.characters,
        validator: _pairingCode,
        suffix: IconButton(
          key: const Key('onboarding-scan'),
          tooltip: 'Ler QR Code',
          onPressed: _loading ? null : _scanPairingCode,
          icon: const Icon(Icons.qr_code_scanner),
        ),
      ),
      // O pareamento já registra série, MAC e IP do equipamento; digitar à
      // mão só faz sentido sem o Terminal por perto.
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => setState(() => _showTechnical = !_showTechnical),
          icon: Icon(
            _showTechnical ? Icons.expand_less : Icons.expand_more,
            size: 18,
          ),
          label: const Text('Informar dados técnicos à mão'),
        ),
      ),
      AppReveal(
        child: !_showTechnical
            ? null
            : Column(
                key: const ValueKey('technical'),
                children: [
                  _field(
                    'terminalSerial',
                    'Número de série (opcional)',
                    validator: null,
                  ),
                  _field(
                    'terminalMac',
                    'Endereço MAC (opcional)',
                    validator: null,
                  ),
                  _field(
                    'terminalIp',
                    'IP local (opcional)',
                    last: true,
                    keyboard: TextInputType.number,
                    validator: null,
                  ),
                ],
              ),
      ),
    ],
    _ => _review(),
  };

  List<Widget> _review() {
    Widget item(IconData icon, String title, String meta, int step) =>
        AppListRow(
          key: Key('onboarding-review-$step'),
          leading: AppIconWell(icon),
          title: title,
          meta: meta,
          dense: true,
          trailing: const Icon(Icons.edit_outlined, size: 20),
          onTap: _loading ? null : () => _goTo(step),
        );
    return [
      item(
        Icons.person_outline,
        '${_value('gestorNome')} ${_value('gestorSobrenome')}',
        'Gestor · CPF ${_value('gestorCpf')} · ${_value('gestorEmail')}',
        0,
      ),
      item(
        Icons.business_outlined,
        _value('nomeFantasia'),
        '${_value('razaoSocial')} · CNPJ ${_value('empresaCnpj')}',
        4,
      ),
      item(
        Icons.place_outlined,
        '${_value('logradouro')}, ${_value('numero')}',
        '${_value('bairro')} · ${_value('cidade')}/${_value('estado').toUpperCase()} · CEP ${_value('cep')}',
        6,
      ),
      item(
        Icons.apartment_outlined,
        _value('condominioNome'),
        'Primeiro condomínio',
        7,
      ),
      item(
        Icons.desktop_windows_outlined,
        _value('terminalNome'),
        parsePairingCode(_value('terminalCodigo')) == null
            ? 'Primeiro Terminal · parear depois'
            : 'Primeiro Terminal · código ${_value('terminalCodigo')}',
        8,
      ),
    ];
  }

  // ---- Tela -------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (title, subtitle) = _heading();
    final review = _step == _reviewStep;

    final step = Column(
      key: ValueKey(_step),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineLarge?.copyWith(height: 1.1),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          subtitle,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        ..._stepFields(),
      ],
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.sm,
                      AppSpacing.sm,
                      AppSpacing.xl,
                      0,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: _step == 0 ? 'Voltar ao login' : 'Voltar',
                          onPressed: _loading ? null : _back,
                          icon: const Icon(Icons.arrow_back),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppProgressBar(
                            value: (_step + 1) / _stepCount,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          '${_step + 1} de $_stepCount',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        AppSpacing.lg,
                        AppSpacing.xl,
                        AppSpacing.lg,
                      ),
                      // A etapa nova entra do lado para onde se avança.
                      child: AnimatedSwitcher(
                        duration: AppMotion.of(context, AppMotion.base),
                        switchInCurve: AppMotion.enter,
                        switchOutCurve: AppMotion.exit,
                        layoutBuilder: (current, previous) => Stack(
                          alignment: Alignment.topCenter,
                          children: [...previous, ?current],
                        ),
                        transitionBuilder: (child, animation) {
                          final entering = child.key == ValueKey(_step);
                          final from =
                              (_forward ? 1 : -1) * (entering ? 1 : -1);
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween(
                                begin: Offset(.06 * from, 0),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: step,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      0,
                      AppSpacing.xl,
                      AppSpacing.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppReveal(
                          child: _error == null
                              ? null
                              : Padding(
                                  key: ValueKey(_error),
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.md,
                                  ),
                                  child: AppBanner(
                                    tone: AppStatusTone.critical,
                                    message: _error!,
                                  ),
                                ),
                        ),
                        FilledButton.icon(
                          key: const Key('onboarding-next'),
                          onPressed: _loading ? null : _next,
                          iconAlignment: IconAlignment.end,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                            shape: const StadiumBorder(),
                            textStyle: theme.textTheme.titleMedium,
                          ),
                          icon: AppBusyIcon(
                            busy: _loading,
                            icon: review ? Icons.check : Icons.arrow_forward,
                          ),
                          label: Text(
                            _loading
                                ? 'Criando…'
                                : review
                                ? 'Criar empresa'
                                : 'Continuar',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  const _UpperCaseFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}
