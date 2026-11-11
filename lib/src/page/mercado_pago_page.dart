import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/widgets/app_refresh.dart';
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
  Widget build(BuildContext context) => _loading
      ? const AppLoadingState(
          label: 'Consultando configuração…',
          layout: AppSkeletonLayout.detail,
        )
      : _error != null
      ? AppErrorState(message: _error!, onRetry: _load)
      : AppRefreshIndicator(
          onRefresh: _load,
          child: ListView(children: [AppContent(child: _content())]),
        );

  String _terminalName(String? id) {
    if (id == null) return '—';
    for (final terminal in _terminals) {
      if (terminal.id == id) return terminal.nome;
    }
    return id;
  }

  Widget _content() {
    final setup = _setup!;
    final theme = Theme.of(context);
    final mobile = AppBreakpoints.isMobile(context);
    final canLink =
        !_working &&
        _terminals.isNotEmpty &&
        _points.any((point) => !point.vinculado);
    final withoutPoint = _terminals
        .where((terminal) => terminal.mercadoPagoTerminalId == null)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppPageHeader(
          title: 'Mercado Pago',
          subtitle:
              'A conta pertence à Empresa; cada maquininha é vinculada a um Terminal.',
          onRefresh: _load,
          refreshing: _loading || _working,
          actions: [
            if (setup.contaVinculada)
              FilledButton.icon(
                onPressed: canLink ? _configurePoint : null,
                icon: const Icon(Icons.link, size: 18),
                label: const Text('Vincular Point'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        if (!setup.contaVinculada)
          AppEmptyState(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Vincule a conta para habilitar pagamentos',
            message:
                'Você será levado ao Mercado Pago para autorizar. Depois, volte e atualize esta tela.',
            action: FilledButton(
              onPressed: _working ? null : _oauth,
              child: const Text('Vincular conta'),
            ),
          )
        else ...[
          AppListRow(
            leading: const AppIconWell(Icons.account_balance_wallet_outlined),
            title: 'Conta Mercado Pago',
            meta: 'Vinculada à Empresa',
            trailing: const AppStatusBadge(
              label: 'Vinculada',
              tone: AppStatusTone.success,
            ),
          ),
          AppListRow(
            leading: const AppIconWell(Icons.point_of_sale_outlined),
            title: 'Maquininhas Point',
            meta:
                '${setup.quantidadeMaquininhasVinculadas} de ${setup.quantidadeTerminais} Terminais com Point',
            trailing: setup.maquininhaVinculada
                ? const AppStatusBadge(
                    label: 'Configurado',
                    tone: AppStatusTone.success,
                  )
                : const AppStatusBadge(
                    label: 'Pendente',
                    tone: AppStatusTone.warning,
                  ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          const AppSectionTitle('Maquininhas Point'),
          if (_points.isEmpty)
            Text(
              'Nenhuma Point retornada pelo Mercado Pago. Confirme se a maquininha está cadastrada na conta vinculada.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else if (mobile)
            for (final point in _points)
              AppListRow(
                title: point.externalPosId ?? point.posId ?? point.id,
                meta: point.vinculado
                    ? 'Terminal ${_terminalName(point.terminalInternoId)}'
                    : 'Sem Terminal',
                trailing: _pointBadge(point),
              )
          else
            AppTable(
              columns: const [
                DataColumn(label: Text('Point')),
                DataColumn(label: Text('Loja')),
                DataColumn(label: Text('Modo')),
                DataColumn(label: Text('Terminal')),
                DataColumn(label: Text('Status')),
              ],
              rows: [
                for (final point in _points)
                  DataRow(
                    cells: [
                      DataCell(
                        Text(
                          point.externalPosId ?? point.posId ?? point.id,
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      DataCell(Text(point.store ?? '—')),
                      DataCell(Text(point.operationMode ?? '—')),
                      DataCell(Text(_terminalName(point.terminalInternoId))),
                      DataCell(_pointBadge(point)),
                    ],
                  ),
              ],
            ),
          if (withoutPoint.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            AppBanner(
              tone: AppStatusTone.info,
              message: withoutPoint.length == 1
                  ? '${withoutPoint.first.nome} ainda não tem Point vinculada.'
                  : '${withoutPoint.length} Terminais ainda não têm Point vinculada.',
              action: canLink
                  ? TextButton(
                      onPressed: _configurePoint,
                      child: const Text('Vincular'),
                    )
                  : null,
            ),
          ],
        ],
      ],
    );
  }

  static AppStatusBadge _pointBadge(MercadoPagoPoint point) => point.vinculado
      ? const AppStatusBadge(label: 'Vinculada', tone: AppStatusTone.success)
      : const AppStatusBadge(label: 'Disponível', tone: AppStatusTone.info);
}
