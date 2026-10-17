import 'package:flutter/material.dart';

import '../../core/formatters/app_formatters.dart';
import '../../core/formatters/app_time.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/branding_config.dart';
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
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard operacional')),
        body: const AppLoadingState(
          key: Key('dashboard-loading'),
          label: 'Carregando indicadores da empresa…',
        ),
      );
    }
    if (_error != null || _dashboard == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard operacional')),
        body: AppErrorState(
          key: const Key('dashboard-error'),
          message: _error ?? 'Dados indisponíveis',
          onRetry: _load,
        ),
      );
    }
    final dashboard = _dashboard!;
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard operacional')),
      body: RefreshIndicator(
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
                _KpiGrid(dashboard: dashboard, onNavigate: _navigate),
                const SizedBox(height: AppSpacing.section),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final checklist = _ChecklistCard(
                      onboarding: dashboard.onboarding,
                      onNavigate: _navigate,
                    );
                    final attention = _AttentionCard(
                      dashboard: dashboard,
                      onNavigate: _navigate,
                    );
                    if (constraints.maxWidth < 900) {
                      return Column(
                        children: [
                          checklist,
                          const SizedBox(height: AppSpacing.lg),
                          attention,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: checklist),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(flex: 2, child: attention),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.section),
                _ActivityCard(
                  activities: dashboard.atividadeRecente,
                  onNavigate: _navigate,
                ),
              ],
            ),
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
    final branding = BrandingScope.of(context);
    final logo = branding.logoUrl;
    final brandInitial = branding.displayName.trim().isEmpty
        ? 'A'
        : branding.displayName.trim().characters.first.toUpperCase();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 64,
          height: 64,
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: logo == null || logo.isEmpty
              ? Center(
                  child: Text(
                    brandInitial,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                )
              : Image.network(
                  logo,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.storefront_outlined,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Olá, ${dashboard.usuarioNome}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                dashboard.empresaNome,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (!AppBreakpoints.isMobile(context))
          OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Atualizar'),
          )
        else
          IconButton(
            tooltip: 'Atualizar indicadores',
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
          ),
      ],
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.dashboard, required this.onNavigate});
  final AdminDashboard dashboard;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 1120
          ? 4
          : constraints.maxWidth >= 560
          ? 2
          : 1;
      final width =
          (constraints.maxWidth - (columns - 1) * AppSpacing.lg) / columns;
      return Wrap(
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.lg,
        children: [
          _KpiCard(
            key: const Key('kpi-sales'),
            width: width,
            label: 'Vendas hoje',
            value: '${dashboard.vendasHoje.quantidadeVendas}',
            detail: dashboard.vendasHoje.quantidadeVendas == 1
                ? 'venda processada'
                : 'vendas processadas',
            icon: Icons.receipt_long_outlined,
            onTap: () => onNavigate('/vendas'),
          ),
          _KpiCard(
            key: const Key('kpi-revenue'),
            width: width,
            label: 'Faturamento hoje',
            value: AppFormatters.currencyText(
              dashboard.vendasHoje.faturamento.persistence,
            ),
            detail:
                'Ticket médio ${AppFormatters.currencyText(dashboard.vendasHoje.ticketMedio.persistence)}',
            icon: Icons.payments_outlined,
            onTap: () => onNavigate('/vendas'),
          ),
          _KpiCard(
            key: const Key('kpi-terminals'),
            width: width,
            label: 'Terminais',
            value: '${dashboard.terminais.online} online',
            detail:
                '${dashboard.terminais.offline} offline de '
                '${dashboard.terminais.total}',
            icon: Icons.desktop_windows_outlined,
            tone: dashboard.terminais.offline > 0
                ? AppStatusTone.warning
                : AppStatusTone.success,
            onTap: () => onNavigate('/terminais'),
          ),
          _KpiCard(
            key: const Key('kpi-alerts'),
            width: width,
            label: 'Alertas',
            value: '${dashboard.alertas.ativos} ativos',
            detail: '${dashboard.alertas.critical} críticos',
            icon: Icons.notification_important_outlined,
            tone: dashboard.alertas.critical > 0
                ? AppStatusTone.critical
                : AppStatusTone.info,
            onTap: () => onNavigate('/alertas'),
          ),
          _KpiCard(
            key: const Key('kpi-stock'),
            width: width,
            label: 'Estoque baixo',
            value: dashboard.estoque.regraConfigurada
                ? '${dashboard.estoque.produtosBaixoEstoque ?? 0} produtos'
                : 'Não disponível',
            detail: dashboard.estoque.regraConfigurada
                ? 'Abaixo do mínimo configurado'
                : 'Estoque mínimo ainda não definido',
            icon: Icons.inventory_outlined,
            tone: dashboard.estoque.regraConfigurada
                ? AppStatusTone.warning
                : AppStatusTone.neutral,
            onTap: () => onNavigate('/estoque'),
          ),
          _KpiCard(
            key: const Key('kpi-payments'),
            width: width,
            label: 'Pagamentos',
            value: '${dashboard.pagamentos.precisamAtencao}',
            detail: 'precisam de atenção',
            icon: Icons.credit_card_off_outlined,
            tone: dashboard.pagamentos.precisamAtencao > 0
                ? AppStatusTone.warning
                : AppStatusTone.success,
            onTap: () => onNavigate('/pagamentos'),
          ),
        ],
      );
    },
  );
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.width,
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    required this.onTap,
    this.tone = AppStatusTone.info,
    super.key,
  });
  final double width;
  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final VoidCallback onTap;
  final AppStatusTone tone;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Theme.of(context).colorScheme.primary),
                  const Spacer(),
                  AppStatusBadge(label: label, tone: tone),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(value, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                detail,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ChecklistCard extends StatelessWidget {
  const _ChecklistCard({required this.onboarding, required this.onNavigate});
  final AdminOnboardingStatus onboarding;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
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
    return Card(
      key: const Key('onboarding-checklist'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.sm,
              ),
              child: Text(
                'Configuração do sistema',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            for (var index = 0; index < items.length; index++) ...[
              ListTile(
                leading: Icon(
                  items[index].$2
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: items[index].$2
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                title: Text(items[index].$1),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onNavigate(items[index].$3),
              ),
              if (index != items.length - 1)
                const Divider(height: 1, indent: 56),
            ],
          ],
        ),
      ),
    );
  }
}

class _AttentionCard extends StatelessWidget {
  const _AttentionCard({required this.dashboard, required this.onNavigate});
  final AdminDashboard dashboard;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Atenção operacional',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          _AttentionRow(
            icon: Icons.inventory_outlined,
            title: 'Estoque baixo',
            value: dashboard.estoque.regraConfigurada
                ? '${dashboard.estoque.produtosBaixoEstoque ?? 0}'
                : 'Regra pendente',
            onTap: () => onNavigate('/estoque'),
          ),
          const Divider(),
          _AttentionRow(
            icon: Icons.credit_card_off_outlined,
            title: 'Pagamentos em atenção',
            value: '${dashboard.pagamentos.precisamAtencao}',
            onTap: () => onNavigate('/pagamentos'),
          ),
          const Divider(),
          _AttentionRow(
            icon: Icons.warning_amber_outlined,
            title: 'Terminais com alerta',
            value: '${dashboard.terminais.comAlerta}',
            onTap: () => onNavigate('/alertas'),
          ),
        ],
      ),
    ),
  );
}

class _AttentionRow extends StatelessWidget {
  const _AttentionRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon),
    title: Text(title),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [Text(value), const Icon(Icons.chevron_right)],
    ),
    onTap: onTap,
  );
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activities, required this.onNavigate});
  final List<AdminActivity> activities;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) => Card(
    key: const Key('recent-activity'),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              'Atividade recente',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          if (activities.isEmpty)
            const ListTile(
              leading: Icon(Icons.history_toggle_off_outlined),
              title: Text('Nenhuma atividade administrativa recente'),
            )
          else
            for (var index = 0; index < activities.length; index++) ...[
              ListTile(
                leading: SizedBox(
                  width: 52,
                  child: Text(
                    _time(activities[index].ocorridoEm),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                title: Text(activities[index].titulo),
                subtitle: Text(activities[index].descricao),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onNavigate(activities[index].destino),
              ),
              if (index != activities.length - 1)
                const Divider(height: 1, indent: 76),
            ],
        ],
      ),
    ),
  );

  static String _time(DateTime? value) {
    if (value == null) return '--:--';
    final local = AppTime.inSaoPaulo(value);
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}
