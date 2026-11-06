import 'package:flutter/material.dart';

import '../../core/navigation/app_routes.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_content.dart';
import '../../core/widgets/app_shell.dart';
import '../model/admin_repository.dart';
import '../model/api_client.dart';
import '../model/app_cliente_config.dart';
import 'app_cliente_config_page.dart';
import 'condominio_terminal_page.dart';
import 'admin_history_page.dart';
import 'dashboard_page.dart';
import 'estoque_hub_page.dart';
import 'lista_produto.dart';
import 'mercado_pago_page.dart';
import 'monitoring_dashboard_page.dart';
import 'promocao_list_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.initialLocation = AppRoutes.dashboard,
    this.repository,
  });
  final String initialLocation;
  final AdminRepository? repository;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final String _location = widget.initialLocation == '/'
      ? AppRoutes.dashboard
      : widget.initialLocation;

  // Último total conhecido, para o contador não piscar a cada navegação.
  static int _lastAlertCount = 0;
  int _alertCount = _lastAlertCount;

  @override
  void initState() {
    super.initState();
    _loadAlertCount();
  }

  Future<void> _loadAlertCount() async {
    if (!ApiClient.instance.isAuthenticated && widget.repository == null) {
      return;
    }
    try {
      final page = await (widget.repository ?? AdminRepository()).alerts();
      _lastAlertCount = page.totalElements;
      if (mounted) setState(() => _alertCount = page.totalElements);
    } catch (_) {
      // O contador é auxiliar; a tela de Alertas mostra o erro completo.
    }
  }

  void _navigate(String route) {
    if (route != _location) Navigator.pushReplacementNamed(context, route);
  }

  Widget _page() => switch (_location) {
    AppRoutes.dashboard => DashboardPage(
      onNavigate: _navigate,
      repository: widget.repository,
    ),
    AppRoutes.condominios ||
    AppRoutes.terminais => const CondominioTerminalPage(),
    AppRoutes.monitoring => const MonitoringDashboardPage(),
    AppRoutes.alertas => const AdminAlertsPage(),
    AppRoutes.vendas => const SalesHistoryPage(),
    AppRoutes.pagamentos => const PaymentHistoryPage(),
    AppRoutes.produtos => const ListaProduto(),
    AppRoutes.promocoes => const PromocaoListPage(),
    AppRoutes.estoque => const EstoqueHubPage(),
    AppRoutes.mercadoPago => const MercadoPagoPage(),
    AppRoutes.appCliente when canManageAppCliente() =>
      const AppClienteConfigPage(),
    AppRoutes.more => MorePage(onNavigate: _navigate),
    _ => DashboardPage(onNavigate: _navigate, repository: widget.repository),
  };

  void _logout() {
    ApiClient.instance.clearSession();
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) => AppShell(
    location: _location,
    onNavigate: _navigate,
    onLogout: _logout,
    alertCount: _alertCount,
    child: _page(),
  );
}

/// Destinos que não cabem na barra inferior do celular.
class MorePage extends StatelessWidget {
  const MorePage({required this.onNavigate, super.key});
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      AppContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppPageHeader(title: 'Mais'),
            const SizedBox(height: AppSpacing.lg),
            for (final d in visibleDestinations())
              if (!mobileRoutes.contains(d.route))
                AppListRow(
                  title: d.label,
                  dense: true,
                  leading: Icon(d.icon),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => onNavigate(d.route),
                ),
            const SizedBox(height: AppSpacing.xl),
            AppListRow(
              title: 'Sair',
              dense: true,
              showDivider: false,
              leading: const Icon(Icons.logout),
              onTap: () {
                ApiClient.instance.clearSession();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.login,
                  (_) => false,
                );
              },
            ),
          ],
        ),
      ),
    ],
  );
}
