import 'package:flutter/material.dart';

import '../../src/model/api_client.dart';
import '../theme/app_brand.dart';
import '../widgets/async_state.dart';
import '../widgets/brand_logo.dart';
import '../../src/page/home_page.dart';
import '../../src/page/login_page.dart';
import '../../src/page/onboarding_page.dart';
import '../../src/page/welcome_page.dart';
import 'welcome_state.dart';
import '../../src/page/cadastra_produto.dart';
import '../../src/page/terminal_telemetry_detail_page.dart';
import '../../src/model/produto_repository.dart';

final appNavigatorKey = GlobalKey<NavigatorState>();

abstract final class AppRoutes {
  static const welcome = '/boas-vindas';
  static const login = '/login';
  static const onboarding = '/onboarding';
  static const dashboard = '/dashboard';
  static const condominios = '/condominios';
  static const terminais = '/terminais';
  static const monitoring = '/monitoramento';
  static const produtos = '/produtos';
  static const promocoes = '/promocoes';
  static const estoque = '/estoque';
  static const mercadoPago = '/mercado-pago';
  static const appCliente = '/app-cliente';
  static const vendas = '/vendas';
  static const pagamentos = '/pagamentos';
  static const alertas = '/alertas';
  static const configuracoes = '/configuracoes';
  static const more = '/mais';

  static const shellRoutes = <String>{
    '/',
    dashboard,
    condominios,
    terminais,
    monitoring,
    produtos,
    promocoes,
    estoque,
    mercadoPago,
    appCliente,
    configuracoes,
    vendas,
    pagamentos,
    alertas,
    more,
  };

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final route = settings.name ?? dashboard;
    if (route == onboarding) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const OnboardingPage(),
      );
    }
    // Primeira abertura, antes de qualquer login: boas-vindas.
    if (!ApiClient.instance.isAuthenticated &&
        WelcomeState.pending &&
        route != login) {
      return MaterialPageRoute<void>(
        settings: const RouteSettings(name: welcome),
        builder: (_) => const WelcomePage(),
      );
    }
    if (route == login || !ApiClient.instance.isAuthenticated) {
      return MaterialPageRoute<void>(
        settings: const RouteSettings(name: login),
        builder: (_) =>
            LoginPage(intendedRoute: route == login ? dashboard : route),
      );
    }
    if (shellRoutes.contains(route)) {
      // Barra e menu ficam parados entre destinos; só o conteúdo entra em
      // fade (ver HomePage).
      return PageRouteBuilder<void>(
        settings: settings,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, _, _) => HomePage(initialLocation: route),
      );
    }
    if (route.startsWith('/terminais/')) {
      final id = route.substring('/terminais/'.length);
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => TerminalTelemetryDetailPage(terminalId: id),
      );
    }
    if (route.startsWith('/produtos/')) {
      final id = route.substring('/produtos/'.length);
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => _ProductRoutePage(id: id),
      );
    }
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => const _NotFoundPage(),
    );
  }
}

class _ProductRoutePage extends StatelessWidget {
  const _ProductRoutePage({required this.id});
  final String id;

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: ProdutoRepository().buscarPorId(id),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Scaffold(
          appBar: AppBar(title: const Text('Produto')),
          body: Center(child: Text(snapshot.error.toString())),
        );
      }
      if (!snapshot.hasData) {
        return const Scaffold(
          body: SafeArea(
            child: AppLoadingState(
              label: 'Carregando produto…',
              layout: AppSkeletonLayout.detail,
            ),
          ),
        );
      }
      return CadastraProduto(produto: snapshot.data);
    },
  );
}

class _NotFoundPage extends StatelessWidget {
  const _NotFoundPage();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BrandLogo(size: 96),
          const SizedBox(height: 16),
          Text(
            'Página não encontrada',
            style: AppBrand.display(Theme.of(context).textTheme.titleLarge),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () =>
                Navigator.pushReplacementNamed(context, AppRoutes.dashboard),
            child: const Text('Voltar ao início'),
          ),
        ],
      ),
    ),
  );
}
