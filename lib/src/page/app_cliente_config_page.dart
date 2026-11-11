import 'package:flutter/material.dart';

import '../../core/widgets/app_feedback.dart';
import '../../core/formatters/app_formatters.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_content.dart';
import '../../core/widgets/async_state.dart';
import '../../core/widgets/status_badge.dart';
import '../model/api_client.dart';
import '../model/app_cliente_config.dart';
import '../model/decimal_value.dart';

class AppClienteConfigPage extends StatefulWidget {
  const AppClienteConfigPage({super.key, this.repository});
  final AppClienteRepository? repository;

  @override
  State<AppClienteConfigPage> createState() => _AppClienteConfigPageState();
}

class _AppClienteConfigPageState extends State<AppClienteConfigPage> {
  late final AppClienteRepository _repository =
      widget.repository ?? AppClienteRepository();
  final _formKey = GlobalKey<FormState>();
  final _pontos = TextEditingController();
  final _cashback = TextEditingController();

  bool _loading = true;
  bool _loaded = false;
  bool _saving = false;
  String? _error;
  DateTime? _updatedAt;

  bool _catalogo = false;
  bool _promocoes = false;
  bool _qrIdentificacao = false;
  bool _preferencias = false;
  bool _suporte = false;
  bool _fidelidade = false;
  String _modo = 'POINTS';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pontos.dispose();
    _cashback.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final config = await _repository.config();
      final fidelidade = await _repository.fidelidade();
      if (!mounted) return;
      setState(() {
        _catalogo = config.catalogoAtivo;
        _promocoes = config.promocoesAtivas;
        _qrIdentificacao = config.qrIdentificacaoAtivo;
        _preferencias = config.preferenciasAtivas;
        _suporte = config.suporteAtivo;
        _fidelidade = config.fidelidadeAtiva;
        _updatedAt = config.updatedAt;
        _modo = fidelidade.modo == 'CASHBACK' ? 'CASHBACK' : 'POINTS';
        _pontos.text = fidelidade.pontosPorReal?.friendly ?? '';
        _cashback.text = fidelidade.cashbackPercentual?.friendly ?? '';
        _loaded = true;
      });
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  TextEditingController get _valor => _modo == 'POINTS' ? _pontos : _cashback;

  String? _validarValor(String? text) {
    final raw = text?.trim() ?? '';
    // Com a fidelidade desligada o valor é opcional.
    if (!_fidelidade && raw.isEmpty) return null;
    final DecimalValue value;
    try {
      value = DecimalValue.parse(raw);
    } on FormatException {
      return raw.isEmpty
          ? 'Informe um valor'
          : 'Use um número com até 6 casas decimais';
    }
    if (!value.isPositive) return 'O valor deve ser maior que zero';
    if (_modo == 'CASHBACK' && !value.lessThanOrEqualTo('100')) {
      return 'O percentual deve ser no máximo 100';
    }
    return null;
  }

  FidelidadeConfig _fidelidadeRequest() {
    final raw = _valor.text.trim();
    // Fidelidade desligada e sem valor: grava NONE, que o back aceita sem valores.
    if (!_fidelidade && raw.isEmpty) {
      return const FidelidadeConfig(ativo: false, modo: 'NONE');
    }
    final value = DecimalValue.parse(raw);
    return FidelidadeConfig(
      ativo: _fidelidade,
      modo: _modo,
      pontosPorReal: _modo == 'POINTS' ? value : null,
      cashbackPercentual: _modo == 'CASHBACK' ? value : null,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      // A ordem importa: o back recusa fidelidadeAtiva sem modo configurado.
      await _repository.salvarFidelidade(_fidelidadeRequest());
      await _repository.salvarConfig(
        AppClienteConfig(
          catalogoAtivo: _catalogo,
          promocoesAtivas: _promocoes,
          fidelidadeAtiva: _fidelidade,
          qrIdentificacaoAtivo: _qrIdentificacao,
          preferenciasAtivas: _preferencias,
          suporteAtivo: _suporte,
        ),
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('Configurações do App Cliente salvas')),
      );
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(_message(error))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    // Recarrega para refletir o que o back calculou, mesmo após falha parcial.
    if (mounted) await _load();
  }

  static String _message(Object error) =>
      error is ApiException ? error.friendlyMessage : error.toString();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        AppContent(
          maxWidth: AppLayout.formMaxWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppPageHeader(
                title: 'App Cliente',
                subtitle: 'Escolha o que os clientes da Empresa veem no app.',
                actions: [
                  FilledButton.icon(
                    key: const Key('app-cliente-save'),
                    onPressed: !_loaded || _saving || _loading ? null : _save,
                    icon: AppBusyIcon(busy: _saving, icon: Icons.check),
                    label: Text(_saving ? 'Salvando…' : 'Salvar'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              if (!_loaded && _loading)
                const AppLoadingState(
                  label: 'Carregando configurações…',
                  layout: AppSkeletonLayout.detail,
                  inline: true,
                )
              else if (!_loaded)
                AppErrorState(
                  title: 'Não foi possível carregar as configurações',
                  message: _error ?? '',
                  onRetry: _load,
                )
              else
                _form(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _form(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final cuponsAtivos = _fidelidade && _modo == 'POINTS';
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          if (_error != null)
            AppBanner(tone: AppStatusTone.critical, message: _error!),
          const AppSectionTitle('Funcionalidades'),
          _toggle(
            'Catálogo',
            'Lista de produtos e preços dos Terminais.',
            _catalogo,
            (v) => _catalogo = v,
          ),
          _toggle(
            'Promoções',
            'Promoções ativas da Empresa.',
            _promocoes,
            (v) => _promocoes = v,
          ),
          _toggle(
            'QR de identificação',
            'QR Code que identifica o cliente no Terminal.',
            _qrIdentificacao,
            (v) => _qrIdentificacao = v,
          ),
          _toggle(
            'Preferências',
            'Preferências e favoritos do cliente.',
            _preferencias,
            (v) => _preferencias = v,
          ),
          _toggle(
            'Suporte',
            'Canal de atendimento ao cliente.',
            _suporte,
            (v) => _suporte = v,
          ),
          const SizedBox(height: AppSpacing.section),
          const AppSectionTitle('Fidelidade'),
          _toggle(
            'Programa de fidelidade',
            'Pontos ou cashback nas compras do cliente.',
            _fidelidade,
            (v) => _fidelidade = v,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Modo', style: theme.textTheme.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 'POINTS', label: Text('Pontos')),
              ButtonSegment(value: 'CASHBACK', label: Text('Cashback')),
            ],
            selected: {_modo},
            onSelectionChanged: _saving
                ? null
                : (value) => setState(() => _modo = value.first),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: 280,
            child: TextFormField(
              key: ValueKey('valor-$_modo'),
              controller: _valor,
              enabled: !_saving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: _validarValor,
              decoration: InputDecoration(
                labelText: _modo == 'POINTS'
                    ? 'Pontos por real'
                    : 'Percentual de cashback',
                suffixText: _modo == 'POINTS' ? 'pts / R\$ 1' : '%',
                helperText: _fidelidade
                    ? null
                    : 'Opcional com a fidelidade desligada',
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppListRow(
            leading: const AppIconWell(Icons.card_giftcard_outlined),
            title: 'Cupons e recompensas',
            meta:
                'Ligam automaticamente com a fidelidade ativa em modo Pontos.',
            trailing: AppStatusBadge(
              label: cuponsAtivos ? 'Ligados' : 'Desligados',
              tone: cuponsAtivos
                  ? AppStatusTone.success
                  : AppStatusTone.neutral,
            ),
            showDivider: false,
          ),
          if (_updatedAt != null) ...[
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Atualizado em ${AppFormatters.dateTime(_updatedAt!)}',
              style: muted,
            ),
          ],
          const SizedBox(height: AppSpacing.section),
        ],
      ),
    );
  }

  Widget _toggle(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> assign,
  ) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(title),
    subtitle: Text(subtitle),
    value: value,
    onChanged: _saving ? null : (v) => setState(() => assign(v)),
  );
}
