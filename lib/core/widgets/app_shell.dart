import 'package:flutter/material.dart';

import '../../src/model/api_client.dart';
import '../../src/model/app_cliente_config.dart';
import '../navigation/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import '../theme/branding_config.dart';
import 'brand_logo.dart';

class AppDestination {
  const AppDestination(
    this.route,
    this.label,
    this.icon,
    this.selectedIcon,
    this.group,
  );
  final String route, label, group;
  final IconData icon, selectedIcon;
}

const appDestinations = <AppDestination>[
  AppDestination(
    AppRoutes.dashboard,
    'Início',
    Icons.dashboard_outlined,
    Icons.dashboard,
    'Visão geral',
  ),
  AppDestination(
    AppRoutes.condominios,
    'Condomínios',
    Icons.apartment_outlined,
    Icons.apartment,
    'Operação',
  ),
  AppDestination(
    AppRoutes.terminais,
    'Terminais',
    Icons.desktop_windows_outlined,
    Icons.desktop_windows,
    'Operação',
  ),
  AppDestination(
    AppRoutes.monitoring,
    'Monitoramento',
    Icons.monitor_heart_outlined,
    Icons.monitor_heart,
    'Operação',
  ),
  AppDestination(
    AppRoutes.alertas,
    'Alertas',
    Icons.notification_important_outlined,
    Icons.notification_important,
    'Operação',
  ),
  AppDestination(
    AppRoutes.produtos,
    'Produtos',
    Icons.inventory_2_outlined,
    Icons.inventory_2,
    'Catálogo',
  ),
  AppDestination(
    AppRoutes.promocoes,
    'Promoções',
    Icons.local_offer_outlined,
    Icons.local_offer,
    'Catálogo',
  ),
  AppDestination(
    AppRoutes.estoque,
    'Estoque',
    Icons.warehouse_outlined,
    Icons.warehouse,
    'Estoque',
  ),
  AppDestination(
    AppRoutes.vendas,
    'Vendas',
    Icons.receipt_long_outlined,
    Icons.receipt_long,
    'Financeiro',
  ),
  AppDestination(
    AppRoutes.pagamentos,
    'Pagamentos',
    Icons.payments_outlined,
    Icons.payments,
    'Financeiro',
  ),
  AppDestination(
    AppRoutes.mercadoPago,
    'Mercado Pago',
    Icons.point_of_sale_outlined,
    Icons.point_of_sale,
    'Integrações',
  ),
  AppDestination(
    AppRoutes.appCliente,
    'App Cliente',
    Icons.phone_iphone_outlined,
    Icons.phone_iphone,
    'Configurações',
  ),
  AppDestination(
    AppRoutes.configuracoes,
    'Empresa e perfil',
    Icons.settings_outlined,
    Icons.settings,
    'Configurações',
  ),
];

/// Rotas que exigem papel ADMIN ou GERENTE.
const restrictedRoutes = {AppRoutes.appCliente};

/// Destinos que o usuário logado pode abrir.
List<AppDestination> visibleDestinations() => canManageAppCliente()
    ? appDestinations
    : [
        for (final destination in appDestinations)
          if (!restrictedRoutes.contains(destination.route)) destination,
      ];

/// Destinos fixos da barra inferior no celular; o resto fica em "Mais".
const mobileRoutes = {
  AppRoutes.dashboard,
  AppRoutes.monitoring,
  AppRoutes.produtos,
  AppRoutes.estoque,
};

/// Desktop: barra superior + menu lateral de 260px + conteúdo.
/// Tablet: barra superior + rail. Celular: barra superior + NavigationBar.
class AppShell extends StatefulWidget {
  const AppShell({
    required this.location,
    required this.child,
    required this.onNavigate,
    required this.onLogout,
    this.alertCount = 0,
    super.key,
  });
  final String location;
  final Widget child;
  final ValueChanged<String> onNavigate;
  final VoidCallback onLogout;
  final int alertCount;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // Cada destino recria a HomePage; o estado do menu vale para a sessão.
  static bool _collapsed = false;

  void _toggle() => setState(() => _collapsed = !_collapsed);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final destinations = visibleDestinations();
    if (width < AppBreakpoints.mobile) {
      return Scaffold(
        appBar: AdminTopBar(
          compact: true,
          alertCount: widget.alertCount,
          destinations: destinations,
          onNavigate: widget.onNavigate,
          onLogout: widget.onLogout,
        ),
        body: widget.child,
        bottomNavigationBar: _MobileNav(
          location: widget.location,
          onNavigate: widget.onNavigate,
        ),
      );
    }
    final desktop = width >= AppBreakpoints.desktop;
    final rail = !desktop || _collapsed;
    return Scaffold(
      appBar: AdminTopBar(
        compact: !desktop,
        alertCount: widget.alertCount,
        destinations: destinations,
        onNavigate: widget.onNavigate,
        onLogout: widget.onLogout,
        onToggleMenu: desktop ? _toggle : null,
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          rail
              ? _Rail(
                  destinations: destinations,
                  location: widget.location,
                  onNavigate: widget.onNavigate,
                  onExpand: desktop ? _toggle : null,
                )
              : AdminSidebar(
                  destinations: destinations,
                  location: widget.location,
                  onNavigate: widget.onNavigate,
                  alertCount: widget.alertCount,
                  onCollapse: _toggle,
                ),
          const VerticalDivider(width: 1),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}

class AdminTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AdminTopBar({
    required this.destinations,
    required this.onNavigate,
    required this.onLogout,
    this.compact = false,
    this.alertCount = 0,
    this.onToggleMenu,
    super.key,
  });
  final List<AppDestination> destinations;
  final ValueChanged<String> onNavigate;
  final VoidCallback onLogout;
  final bool compact;
  final int alertCount;
  final VoidCallback? onToggleMenu;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  Iterable<Widget> _suggestions(
    BuildContext context,
    SearchController controller,
  ) {
    final query = controller.text.trim().toLowerCase();
    return [
      for (final d in destinations)
        if (query.isEmpty || d.label.toLowerCase().contains(query))
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
            ),
            leading: Icon(d.icon),
            title: Text(d.label),
            subtitle: Text(d.group),
            onTap: () {
              controller.closeView(null);
              controller.clear();
              onNavigate(d.route);
            },
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final branding = BrandingScope.of(context);
    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Row(
        children: [
          if (onToggleMenu != null)
            IconButton(
              tooltip: 'Abrir ou recolher menu',
              icon: const Icon(Icons.menu),
              onPressed: onToggleMenu,
            )
          else
            const SizedBox(width: AppSpacing.lg),
          const _BrandMark(),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              branding.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium,
            ),
          ),
          if (!compact) ...[
            // Alinha a busca com o conteúdo (menu lateral de 260px).
            const SizedBox(width: 92),
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SearchAnchor.bar(
                  barHintText: 'Buscar página do painel',
                  barElevation: const WidgetStatePropertyAll(0),
                  barBackgroundColor: WidgetStatePropertyAll(
                    scheme.surfaceContainerLow,
                  ),
                  constraints: const BoxConstraints(
                    minHeight: 40,
                    maxHeight: 40,
                  ),
                  viewConstraints: const BoxConstraints(maxHeight: 420),
                  suggestionsBuilder: _suggestions,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (compact)
          SearchAnchor(
            suggestionsBuilder: _suggestions,
            builder: (context, controller) => IconButton(
              tooltip: 'Buscar',
              icon: const Icon(Icons.search),
              onPressed: controller.openView,
            ),
          ),
        IconButton(
          tooltip: alertCount > 0
              ? '$alertCount alertas ativos'
              : 'Nenhum alerta ativo',
          onPressed: () => onNavigate(AppRoutes.alertas),
          icon: Badge(
            isLabelVisible: alertCount > 0,
            label: Text(alertCount > 99 ? '99+' : '$alertCount'),
            child: const Icon(Icons.notifications_outlined),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        _UserMenu(onLogout: onLogout, onNavigate: onNavigate),
        const SizedBox(width: AppSpacing.md),
      ],
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    final branding = BrandingScope.of(context);
    final logo = branding.compactLogoUrl ?? branding.logoUrl;
    if (logo != null && logo.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Image.network(
          logo,
          height: 32,
          width: 32,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const BrandLogo(size: 36),
        ),
      );
    }
    // Empresa sem logo: a marca do Painel 24/7 ocupa o lugar.
    return const BrandLogo(size: 36);
  }
}

class _UserMenu extends StatelessWidget {
  const _UserMenu({required this.onLogout, required this.onNavigate});
  final VoidCallback onLogout;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final user = ApiClient.instance.authenticatedUser;
    final name = [
      user?['nome'],
      user?['sobrenome'],
    ].whereType<String>().where((part) => part.trim().isNotEmpty).toList();
    final initials = name.isEmpty
        ? ''
        : name.take(2).map((part) => part.trim()[0].toUpperCase()).join();
    return MenuAnchor(
      alignmentOffset: const Offset(0, AppSpacing.xs),
      menuChildren: [
        if (name.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.join(' '), style: theme.textTheme.titleSmall),
                if (user?['role'] != null)
                  Text(
                    _roleLabel(user!['role'].toString()),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        if (name.isNotEmpty) const Divider(),
        MenuItemButton(
          leadingIcon: const Icon(Icons.manage_accounts_outlined),
          onPressed: () => onNavigate(AppRoutes.configuracoes),
          child: const Text('Empresa e perfil'),
        ),
        MenuItemButton(
          leadingIcon: Icon(Icons.logout, color: scheme.error),
          onPressed: onLogout,
          child: Text('Sair', style: TextStyle(color: scheme.error)),
        ),
      ],
      builder: (context, controller, _) => IconButton(
        tooltip: 'Conta',
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
        icon: CircleAvatar(
          radius: 18,
          backgroundColor: scheme.surfaceContainerHigh,
          child: initials.isEmpty
              ? Icon(Icons.person_outline, color: scheme.primary, size: 20)
              : Text(
                  initials,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }

  static String _roleLabel(String role) => switch (role) {
    'ADMIN' => 'Administrador',
    'GERENTE' => 'Gerente',
    _ => role,
  };
}

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({
    required this.destinations,
    required this.location,
    required this.onNavigate,
    this.alertCount = 0,
    this.onCollapse,
    super.key,
  });
  final List<AppDestination> destinations;
  final String location;
  final ValueChanged<String> onNavigate;
  final int alertCount;
  final VoidCallback? onCollapse;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final colors = AppThemeColors.of(context);

    Widget item({
      required IconData icon,
      required String label,
      required VoidCallback onTap,
      bool selected = false,
      int count = 0,
    }) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Material(
        color: selected ? colors.primarySoft : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: SizedBox(
            height: 40,
            child: Row(
              children: [
                const SizedBox(width: AppSpacing.md),
                Icon(
                  icon,
                  size: 20,
                  color: selected
                      ? colors.onPrimarySoft
                      : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelLarge?.copyWith(
                      color: selected ? colors.onPrimarySoft : scheme.onSurface,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                if (count > 0)
                  Container(
                    height: 20,
                    margin: const EdgeInsets.only(right: AppSpacing.md),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    constraints: const BoxConstraints(minWidth: 20),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.errorContainer,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: text.labelSmall?.copyWith(
                        color: scheme.onErrorContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    final children = <Widget>[];
    String? group;
    for (final d in destinations) {
      if (d.group != group) {
        group = d.group;
        children.add(
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              children.isEmpty ? AppSpacing.xs : AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Text(
              group.toUpperCase(),
              style: text.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: .6,
              ),
            ),
          ),
        );
      }
      final selected = location == d.route;
      children.add(
        item(
          icon: selected ? d.selectedIcon : d.icon,
          label: d.label,
          selected: selected,
          count: d.route == AppRoutes.alertas ? alertCount : 0,
          onTap: () => onNavigate(d.route),
        ),
      );
    }

    return SizedBox(
      width: AppLayout.sidebarWidth,
      child: ColoredBox(
        color: AppColors.background,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: children,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md),
              child: BrandLogo(size: 64, showWordmark: true),
            ),
            if (onCollapse != null) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: item(
                  icon: Icons.keyboard_double_arrow_left,
                  label: 'Recolher menu',
                  onTap: onCollapse!,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({
    required this.destinations,
    required this.location,
    required this.onNavigate,
    this.onExpand,
  });
  final List<AppDestination> destinations;
  final String location;
  final ValueChanged<String> onNavigate;
  final VoidCallback? onExpand;

  @override
  Widget build(BuildContext context) {
    final selected = destinations.indexWhere((d) => d.route == location);
    return NavigationRail(
      minWidth: AppLayout.railWidth,
      selectedIndex: selected < 0 ? null : selected,
      onDestinationSelected: (index) => onNavigate(destinations[index].route),
      labelType: NavigationRailLabelType.selected,
      scrollable: true,
      trailingAtBottom: true,
      trailing: onExpand == null
          ? null
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: IconButton(
                tooltip: 'Expandir menu',
                onPressed: onExpand,
                icon: const Icon(Icons.keyboard_double_arrow_right),
              ),
            ),
      destinations: [
        for (final d in destinations)
          NavigationRailDestination(
            icon: Tooltip(message: d.label, child: Icon(d.icon)),
            selectedIcon: Icon(d.selectedIcon),
            label: Text(d.label),
          ),
      ],
    );
  }
}

class _MobileNav extends StatelessWidget {
  const _MobileNav({required this.location, required this.onNavigate});
  final String location;
  final ValueChanged<String> onNavigate;

  int get _index => switch (location) {
    AppRoutes.dashboard => 0,
    AppRoutes.condominios || AppRoutes.terminais || AppRoutes.monitoring => 1,
    AppRoutes.produtos => 2,
    AppRoutes.estoque => 3,
    _ => 4,
  };

  @override
  Widget build(BuildContext context) => NavigationBar(
    selectedIndex: _index,
    onDestinationSelected: (index) => onNavigate(switch (index) {
      0 => AppRoutes.dashboard,
      1 => AppRoutes.monitoring,
      2 => AppRoutes.produtos,
      3 => AppRoutes.estoque,
      _ => AppRoutes.more,
    }),
    destinations: const [
      NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Início',
      ),
      NavigationDestination(
        icon: Icon(Icons.desktop_windows_outlined),
        selectedIcon: Icon(Icons.desktop_windows),
        label: 'Operação',
      ),
      NavigationDestination(
        icon: Icon(Icons.inventory_2_outlined),
        selectedIcon: Icon(Icons.inventory_2),
        label: 'Produtos',
      ),
      NavigationDestination(
        icon: Icon(Icons.warehouse_outlined),
        selectedIcon: Icon(Icons.warehouse),
        label: 'Estoque',
      ),
      NavigationDestination(icon: Icon(Icons.more_horiz), label: 'Mais'),
    ],
  );
}
