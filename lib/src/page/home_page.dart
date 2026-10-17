import 'package:flutter/material.dart';

import '../../core/navigation/app_routes.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/branding_config.dart';
import '../model/api_client.dart';
import 'condominio_terminal_page.dart';
import 'admin_history_page.dart';
import 'dashboard_page.dart';
import 'estoque_hub_page.dart';
import 'lista_produto.dart';
import 'mercado_pago_page.dart';
import 'monitoring_dashboard_page.dart';
import 'promocao_list_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.initialLocation = AppRoutes.dashboard});
  final String initialLocation;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final String _location = widget.initialLocation == '/'
      ? AppRoutes.dashboard
      : widget.initialLocation;

  static const _destinations = <_Destination>[
    _Destination(
      AppRoutes.dashboard,
      'Visão geral',
      Icons.dashboard_outlined,
      'Início',
    ),
    _Destination(
      AppRoutes.condominios,
      'Condomínios',
      Icons.apartment_outlined,
      'Operação',
    ),
    _Destination(
      AppRoutes.terminais,
      'Terminais',
      Icons.desktop_windows_outlined,
      'Operação',
    ),
    _Destination(
      AppRoutes.monitoring,
      'Monitoramento',
      Icons.monitor_heart_outlined,
      'Operação',
    ),
    _Destination(
      AppRoutes.produtos,
      'Produtos',
      Icons.inventory_2_outlined,
      'Catálogo',
    ),
    _Destination(
      AppRoutes.promocoes,
      'Promoções',
      Icons.local_offer_outlined,
      'Catálogo',
    ),
    _Destination(
      AppRoutes.estoque,
      'Estoque',
      Icons.warehouse_outlined,
      'Estoque',
    ),
    _Destination(
      AppRoutes.mercadoPago,
      'Mercado Pago',
      Icons.point_of_sale_outlined,
      'Integrações',
    ),
  ];

  void _navigate(String route) {
    if (route != _location) Navigator.pushReplacementNamed(context, route);
  }

  Widget _page() => switch (_location) {
    AppRoutes.dashboard => DashboardPage(onNavigate: _navigate),
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
    AppRoutes.more => MorePage(onNavigate: _navigate),
    _ => DashboardPage(onNavigate: _navigate),
  };

  void _logout() {
    ApiClient.instance.clearSession();
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }

  int get _mobileIndex => switch (_location) {
    AppRoutes.dashboard => 0,
    AppRoutes.condominios || AppRoutes.terminais || AppRoutes.monitoring => 1,
    AppRoutes.produtos => 2,
    AppRoutes.estoque => 3,
    _ => 4,
  };

  @override
  Widget build(BuildContext context) {
    final branding = BrandingScope.of(context);
    final width = MediaQuery.sizeOf(context).width;
    if (width < AppBreakpoints.mobile) {
      return Scaffold(
        body: _page(),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _mobileIndex,
          onDestinationSelected: (index) => _navigate(switch (index) {
            0 => AppRoutes.dashboard,
            1 => AppRoutes.monitoring,
            2 => AppRoutes.produtos,
            3 => AppRoutes.estoque,
            _ => AppRoutes.more,
          }),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              label: 'Início',
            ),
            NavigationDestination(
              icon: Icon(Icons.desktop_windows_outlined),
              label: 'Operação',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              label: 'Produtos',
            ),
            NavigationDestination(
              icon: Icon(Icons.warehouse_outlined),
              label: 'Estoque',
            ),
            NavigationDestination(icon: Icon(Icons.more_horiz), label: 'Mais'),
          ],
        ),
      );
    }

    final desktop = width >= AppBreakpoints.desktop;
    return Scaffold(
      body: Row(
        children: [
          _SideNavigation(
            destinations: _destinations,
            selectedRoute: _location,
            expanded: desktop,
            brand: branding.displayName,
            onSelected: _navigate,
            onLogout: _logout,
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _page()),
        ],
      ),
    );
  }
}

class MorePage extends StatelessWidget {
  const MorePage({required this.onNavigate, super.key});
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mais')),
    body: ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _item('Condomínios', Icons.apartment_outlined, AppRoutes.condominios),
        _item('Terminais', Icons.desktop_windows_outlined, AppRoutes.terminais),
        _item(
          'Alertas',
          Icons.notification_important_outlined,
          AppRoutes.alertas,
        ),
        _item('Vendas', Icons.receipt_long_outlined, AppRoutes.vendas),
        _item('Pagamentos', Icons.payments_outlined, AppRoutes.pagamentos),
        _item('Promoções', Icons.local_offer_outlined, AppRoutes.promocoes),
        _item(
          'Mercado Pago',
          Icons.point_of_sale_outlined,
          AppRoutes.mercadoPago,
        ),
        const Divider(height: AppSpacing.xxl),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Sair'),
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
  );

  Widget _item(String label, IconData icon, String route) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => onNavigate(route),
      ),
    ),
  );
}

class _Destination {
  const _Destination(this.route, this.label, this.icon, this.group);
  final String route;
  final String label;
  final IconData icon;
  final String group;
}

class _SideNavigation extends StatelessWidget {
  const _SideNavigation({
    required this.destinations,
    required this.selectedRoute,
    required this.expanded,
    required this.brand,
    required this.onSelected,
    required this.onLogout,
  });
  final List<_Destination> destinations;
  final String selectedRoute;
  final bool expanded;
  final String brand;
  final ValueChanged<String> onSelected;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final brandInitial = brand.trim().isEmpty
        ? 'A'
        : brand.trim().characters.first.toUpperCase();
    if (!expanded) {
      final selected = destinations.indexWhere(
        (item) => item.route == selectedRoute,
      );
      return NavigationRail(
        minWidth: AppLayout.railWidth,
        selectedIndex: selected < 0 ? null : selected,
        onDestinationSelected: (index) => onSelected(destinations[index].route),
        labelType: NavigationRailLabelType.selected,
        leading: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: CircleAvatar(child: Text(brandInitial)),
        ),
        trailing: Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: IconButton(
                tooltip: 'Sair',
                onPressed: onLogout,
                icon: const Icon(Icons.logout),
              ),
            ),
          ),
        ),
        destinations: [
          for (final item in destinations)
            NavigationRailDestination(
              icon: Icon(item.icon),
              label: Text(item.label),
            ),
        ],
      );
    }

    return Container(
      width: AppLayout.sidebarWidth,
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Row(
                children: [
                  CircleAvatar(child: Text(brandInitial)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      brand,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                children: [
                  for (var index = 0; index < destinations.length; index++) ...[
                    if (index == 0 ||
                        destinations[index - 1].group !=
                            destinations[index].group)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.lg,
                          AppSpacing.md,
                          AppSpacing.sm,
                        ),
                        child: Text(
                          destinations[index].group.toUpperCase(),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: ListTile(
                        selected: destinations[index].route == selectedRoute,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        leading: Icon(destinations[index].icon),
                        title: Text(destinations[index].label),
                        onTap: () => onSelected(destinations[index].route),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sair'),
              onTap: onLogout,
            ),
          ],
        ),
      ),
    );
  }
}
