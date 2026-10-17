import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_content.dart';
import '../../core/widgets/async_state.dart';
import '../../core/widgets/status_badge.dart';
import '../model/mercado_pago_repository.dart';
import '../model/operational_repository.dart';

class MercadoPagoPage extends StatefulWidget {
  const MercadoPagoPage({
    super.key,
    this.repository,
    this.operationalRepository,
  });

  final MercadoPagoRepository? repository;
  final OperationalRepository? operationalRepository;

  @override
  State<MercadoPagoPage> createState() => _MercadoPagoPageState();
}

class _MercadoPagoPageState extends State<MercadoPagoPage> {
  late final MercadoPagoRepository _repository =
      widget.repository ?? MercadoPagoRepository();
  late final OperationalRepository _operationalRepository =
      widget.operationalRepository ?? OperationalRepository();
  MercadoPagoSetup? _setup;
  List<MercadoPagoPoint> _points = const [];
  List<TerminalAdmin> _terminals = const [];
  bool _loading = true;
  bool _working = false;
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
      final setup = await _repository.status();
      final terminals = await _operationalRepository.terminais();
      final points = setup.contaVinculada
          ? await _repository.points()
          : <MercadoPagoPoint>[];
      if (!mounted) return;
      setState(() {
        _setup = setup;
        _terminals = terminals;
        _points = points;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _oauth() async {
    setState(() => _working = true);
    try {
      final uri = await _repository.oauthUrl();
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) throw Exception('Não foi possível abrir o Mercado Pago');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Conclua a autorização no navegador e atualize esta tela.',
          ),
        ),
      );
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

  Future<void> _configurePoint() async {
    final available = _points.where((point) => !point.vinculado).toList();
    if (_terminals.isEmpty || available.isEmpty) return;
    String? terminalId = _terminals.first.id;
    String? pointId = available.first.id;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Vincular Point ao Terminal'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: terminalId,
                  decoration: const InputDecoration(labelText: 'Terminal'),
                  items: _terminals
                      .map(
                        (terminal) => DropdownMenuItem(
                          value: terminal.id,
                          child: Text(terminal.nome),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => terminalId = value),
                ),
                const SizedBox(height: AppSpacing.lg),
                DropdownButtonFormField<String>(
                  initialValue: pointId,
                  decoration: const InputDecoration(labelText: 'Point'),
                  items: available
                      .map(
                        (point) => DropdownMenuItem(
                          value: point.id,
                          child: Text(
                            point.externalPosId ?? point.posId ?? point.id,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setDialogState(() => pointId = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Vincular'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || terminalId == null || pointId == null) return;
    setState(() => _working = true);
    try {
      await _repository.vincular(terminalId!, pointId!);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Point vinculada ao Terminal.')),
        );
      }
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
    appBar: AppBar(
      title: const Text('Mercado Pago'),
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: _loading || _working ? null : _load,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: _loading
        ? const AppLoadingState(label: 'Consultando configuração…')
        : _error != null
        ? AppErrorState(message: _error!, onRetry: _load)
        : AppContent(child: _content()),
  );

  Widget _content() {
    final setup = _setup!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppPageHeader(
          title: 'Integração de pagamentos',
          subtitle:
              'A conta pertence à Empresa; cada maquininha é vinculada a um Terminal.',
          actions: [
            if (!setup.contaVinculada)
              FilledButton.icon(
                onPressed: _working ? null : _oauth,
                icon: const Icon(Icons.link),
                label: const Text('Vincular conta'),
              )
            else
              FilledButton.icon(
                onPressed:
                    _working ||
                        _points.every((point) => point.vinculado) ||
                        _terminals.isEmpty
                    ? null
                    : _configurePoint,
                icon: const Icon(Icons.point_of_sale),
                label: const Text('Configurar Point'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.lg,
          children: [
            _SetupCard(
              title: 'Conta Mercado Pago',
              description: setup.contaVinculada
                  ? 'Conta vinculada à Empresa'
                  : 'Vincule a conta para habilitar pagamentos',
              ready: setup.contaVinculada,
              icon: Icons.account_balance_wallet_outlined,
            ),
            _SetupCard(
              title: 'Maquininhas Point',
              description:
                  '${setup.quantidadeMaquininhasVinculadas} de ${setup.quantidadeTerminais} Terminais configurados',
              ready: setup.maquininhaVinculada,
              icon: Icons.point_of_sale_outlined,
            ),
          ],
        ),
        if (setup.contaVinculada) ...[
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Points disponíveis',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          if (_points.isEmpty)
            const Card(
              child: ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Nenhuma Point retornada pelo Mercado Pago'),
                subtitle: Text(
                  'Confirme se a maquininha está cadastrada na conta vinculada.',
                ),
              ),
            )
          else
            ..._points.map(
              (point) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Card(
                  child: ListTile(
                    leading: const Icon(Icons.point_of_sale),
                    title: Text(point.externalPosId ?? point.posId ?? point.id),
                    subtitle: Text(
                      [
                        if (point.store != null) 'Loja: ${point.store}',
                        if (point.operationMode != null)
                          'Modo: ${point.operationMode}',
                        if (point.terminalInternoId != null)
                          'Terminal: ${point.terminalInternoId}',
                      ].join(' • '),
                    ),
                    trailing: AppStatusBadge(
                      label: point.vinculado ? 'Vinculada' : 'Disponível',
                      tone: point.vinculado
                          ? AppStatusTone.success
                          : AppStatusTone.info,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _SetupCard extends StatelessWidget {
  const _SetupCard({
    required this.title,
    required this.description,
    required this.ready,
    required this.icon,
  });
  final String title;
  final String description;
  final bool ready;
  final IconData icon;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 360,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(description),
            const SizedBox(height: AppSpacing.lg),
            AppStatusBadge(
              label: ready ? 'Configurado' : 'Pendente',
              tone: ready ? AppStatusTone.success : AppStatusTone.warning,
              icon: ready ? Icons.check_circle : Icons.schedule,
            ),
          ],
        ),
      ),
    ),
  );
}
