import 'package:flutter/material.dart';

import '../../core/widgets/app_refresh.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/formatters/app_formatters.dart';
import '../../core/formatters/app_time.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_content.dart';
import '../../core/widgets/async_state.dart';
import '../../core/widgets/status_badge.dart';
import '../model/admin_dashboard.dart';
import '../model/admin_repository.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, this.onNavigate, this.repository});
  final ValueChanged<String>? onNavigate;
  final AdminRepository? repository;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final AdminRepository _repository;
  AdminDashboard? _dashboard;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? AdminRepository();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dashboard = await _repository.dashboard();
      if (mounted) setState(() => _dashboard = dashboard);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _navigate(String route) => widget.onNavigate?.call(route);

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AppLoadingState(
        key: Key('dashboard-loading'),
        label: 'Carregando indicadores da empresa…',
        layout: AppSkeletonLayout.dashboard,
      );
    }
    if (_error != null || _dashboard == null) {
      return AppErrorState(
        key: const Key('dashboard-error'),
        message: _error ?? 'Dados indisponíveis',
        onRetry: _load,
      );
    }
    final dashboard = _dashboard!;
    return AppRefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        key: const Key('dashboard-content'),
        physics: const AlwaysScrollableScrollPhysics(),
        child: AppContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DashboardHeader(dashboard: dashboard, onRefresh: _load),
              const SizedBox(height: AppSpacing.xl),
              _Kpis(dashboard: dashboard, onNavigate: _navigate),
              const SizedBox(height: AppSpacing.section),
              LayoutBuilder(
                builder: (context, constraints) {
                  final attention = _Attention(
                    dashboard: dashboard,
                    onNavigate: _navigate,
                  );
                  final checklist = _Checklist(
                    onboarding: dashboard.onboarding,
                    onNavigate: _navigate,
                  );
                  if (constraints.maxWidth < 900) {
                    return Column(
                      children: [
                        attention,
                        const SizedBox(height: AppSpacing.section),
                        checklist,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 13, child: attention),
                      const SizedBox(width: AppSpacing.section),
                      Expanded(flex: 10, child: checklist),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.section),
              _Activity(
                activities: dashboard.atividadeRecente,
                onNavigate: _navigate,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.dashboard, required this.onRefresh});
  final AdminDashboard dashboard;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final generated = dashboard.geradoEm;
    final subtitle = [
      dashboard.empresaNome,
      if (generated != null) 'atualizado às ${AppFormatters.time(generated)}',
    ].where((part) => part.isNotEmpty).join(' · ');
    return AppPageHeader(
      title: 'Olá, ${dashboard.usuarioNome}',
      subtitle: subtitle.isEmpty ? null : subtitle,
      onRefresh: onRefresh,
    );
  }
}

class _Kpis extends StatelessWidget {
  const _Kpis({required this.dashboard, required this.onNavigate});
  final AdminDashboard dashboard;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    final vendas = dashboard.vendasHoje.quantidadeVendas;
    final estoque = dashboard.estoque;
    return AppKpiStrip(
      items: [
        AppKpi(
          key: const Key('kpi-sales'),
          label: 'Vendas hoje',
          value: '$vendas',
          help: vendas == 1 ? 'venda processada' : 'vendas processadas',
          icon: Icons.receipt_long_outlined,
          onTap: () => onNavigate('/vendas'),
        ),
        AppKpi(
          key: const Key('kpi-revenue'),
          label: 'Faturamento hoje',
          value: AppFormatters.currencyText(
            dashboard.vendasHoje.faturamento.persistence,
          ),
          help:
              'Ticket médio ${AppFormatters.currencyText(dashboard.vendasHoje.ticketMedio.persistence)}',
          icon: Icons.payments_outlined,
          onTap: () => onNavigate('/vendas'),
        ),
        AppKpi(
          key: const Key('kpi-terminals'),
          label: 'Terminais',
          value: '${dashboard.terminais.online} online',
          help:
              '${dashboard.terminais.offline} offline de '
              '${dashboard.terminais.total}',
          icon: Icons.desktop_windows_outlined,
          onTap: () => onNavigate('/terminais'),
        ),
        AppKpi(
          key: const Key('kpi-alerts'),
          label: 'Alertas',
          value: '${dashboard.alertas.ativos} ativos',
          help: dashboard.alertas.critical == 1
              ? '1 crítico'
              : '${dashboard.alertas.critical} críticos',
          icon: Icons.notification_important_outlined,
          tone: dashboard.alertas.critical > 0 ? AppStatusTone.critical : null,
          onTap: () => onNavigate('/alertas'),
        ),
        AppKpi(
          key: const Key('kpi-stock'),
          label: 'Estoque baixo',
          value: estoque.regraConfigurada
              ? '${estoque.produtosBaixoEstoque ?? 0}'
              : 'Não disponível',
          help: estoque.regraConfigurada
              ? 'Abaixo do mínimo configurado'
              : 'Estoque mínimo ainda não definido',
          icon: Icons.inventory_outlined,
          onTap: () => onNavigate('/estoque'),
        ),
        AppKpi(
          key: const Key('kpi-payments'),
          label: 'Pagamentos',
          value: '${dashboard.pagamentos.precisamAtencao}',
          help: 'precisam de atenção',
          icon: Icons.credit_card_off_outlined,
          tone: dashboard.pagamentos.precisamAtencao > 0
              ? AppStatusTone.warning
              : null,
          onTap: () => onNavigate('/pagamentos'),
        ),
      ],
    );
  }
}

class _Attention extends StatelessWidget {
  const _Attention({required this.dashboard, required this.onNavigate});
  final AdminDashboard dashboard;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    final terminais = dashboard.terminais.comAlerta;
    final pagamentos = dashboard.pagamentos.precisamAtencao;
    final estoque = dashboard.estoque;
    final baixo = estoque.produtosBaixoEstoque ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionTitle('Atenção operacional'),
        AppListRow(
          leading: const AppIconWell(Icons.desktop_windows_outlined),
          title: 'Terminais com alerta',
          meta: terminais == 0
              ? 'Nenhum Terminal com alerta ativo'
              : terminais == 1
              ? '1 Terminal precisa de atenção'
              : '$terminais Terminais precisam de atenção',
          trailing: _rowEnd(
            terminais == 0
                ? const AppStatusBadge(
                    label: 'Normal',
                    tone: AppStatusTone.success,
                  )
                : AppStatusBadge(
                    label: dashboard.alertas.critical > 0
                        ? 'Crítico'
                        : 'Atenção',
                    tone: dashboard.alertas.critical > 0
                        ? AppStatusTone.critical
                        : AppStatusTone.warning,
                  ),
          ),
          onTap: () => onNavigate('/alertas'),
        ),
        AppListRow(
          leading: const AppIconWell(Icons.inventory_outlined),
          title: 'Estoque baixo',
          meta: !estoque.regraConfigurada
              ? 'Defina o estoque mínimo para acompanhar'
              : baixo == 1
              ? '1 produto abaixo do mínimo'
              : '$baixo produtos abaixo do mínimo',
          trailing: _rowEnd(
            !estoque.regraConfigurada
                ? const AppStatusBadge(
                    label: 'Regra pendente',
                    tone: AppStatusTone.warning,
                  )
                : baixo == 0
                ? const AppStatusBadge(
                    label: 'Normal',
                    tone: AppStatusTone.success,
                  )
                : const AppStatusBadge(
                    label: 'Atenção',
                    tone: AppStatusTone.warning,
                  ),
          ),
          onTap: () => onNavigate('/estoque'),
        ),
        AppListRow(
          leading: const AppIconWell(Icons.credit_card_off_outlined),
          title: 'Pagamentos em atenção',
          meta: pagamentos == 0
              ? 'Nenhum pagamento pendente'
              : pagamentos == 1
              ? '1 pagamento aguardando ação'
              : '$pagamentos pagamentos aguardando ação',
          trailing: _rowEnd(
            pagamentos == 0
                ? const AppStatusBadge(
                    label: 'Normal',
                    tone: AppStatusTone.success,
                  )
                : const AppStatusBadge(
                    label: 'Atenção',
                    tone: AppStatusTone.warning,
                  ),
          ),
          onTap: () => onNavigate('/pagamentos'),
        ),
      ],
    );
  }

  Widget _rowEnd(Widget badge) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      badge,
      const SizedBox(width: AppSpacing.xs),
      const Icon(Icons.chevron_right),
    ],
  );
}

class _Checklist extends StatelessWidget {
  const _Checklist({required this.onboarding, required this.onNavigate});
  final AdminOnboardingStatus onboarding;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final items = <(String, bool, String)>[
      ('Empresa cadastrada', onboarding.empresaCadastrada, '/onboarding'),
      (
        'Condomínio cadastrado',
        onboarding.condominioCadastrado,
        '/condominios',
      ),
      ('Terminal ativado', onboarding.terminalAtivado, '/terminais'),
      (
        'Mercado Pago vinculado',
        onboarding.mercadoPagoVinculado,
        '/mercado-pago',
      ),
      ('Point vinculada', onboarding.pointVinculada, '/terminais'),
      ('Produtos cadastrados', onboarding.produtosCadastrados, '/produtos'),
      (
        'Produtos associados ao condomínio',
        onboarding.produtosAssociadosCondominio,
        '/produtos',
      ),
    ];
    final done = items.where((item) => item.$2).length;
    final progress = done / items.length;
    return Column(
      key: const Key('onboarding-checklist'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionTitle('Configuração do sistema'),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: Text(
                '$done de ${items.length} concluídos',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        AppProgressBar(value: progress),
        const SizedBox(height: AppSpacing.sm),
        for (final (label, ok, route) in items)
          InkWell(
            onTap: () => onNavigate(route),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Row(
                children: [
                  Icon(
                    ok ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 20,
                    color: ok
                        ? AppThemeColors.of(context).success
                        : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: ok ? scheme.onSurface : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (!ok)
                    Text(
                      'Configurar',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: scheme.primary,
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Activity extends StatelessWidget {
  const _Activity({required this.activities, required this.onNavigate});
  final List<AdminActivity> activities;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      key: const Key('recent-activity'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionTitle('Atividade recente'),
        if (activities.isEmpty)
          const AppEmptyState(
            icon: Icons.history_toggle_off_outlined,
            title: 'Nenhuma atividade administrativa recente',
            message:
                'Cadastros, ajustes de estoque e mudanças de configuração aparecem aqui.',
          )
        else
          for (final (i, activity) in activities.indexed)
            AppListRow(
              entranceIndex: i,
              leading: SizedBox(
                width: 48,
                child: Text(
                  _time(activity.ocorridoEm),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              title: activity.titulo,
              meta: activity.descricao,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => onNavigate(activity.destino),
            ),
      ],
    );
  }

  static String _time(DateTime? value) {
    if (value == null) return '--:--';
    final local = AppTime.inSaoPaulo(value);
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}
