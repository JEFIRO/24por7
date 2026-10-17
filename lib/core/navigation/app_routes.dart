import 'package:flutter/material.dart';

import '../../src/model/api_client.dart';
import '../../src/page/home_page.dart';
import '../../src/page/login_page.dart';
import '../../src/page/onboarding_page.dart';
import '../../src/page/cadastra_produto.dart';
import '../../src/page/terminal_telemetry_detail_page.dart';
import '../../src/model/produto_repository.dart';

final appNavigatorKey = GlobalKey<NavigatorState>();

abstract final class AppRoutes {
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
  static const vendas = '/vendas';
  static const pagamentos = '/pagamentos';
  static const alertas = '/alertas';
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
    if (route == login || !ApiClient.instance.isAuthenticated) {
      return MaterialPageRoute<void>(
        settings: const RouteSettings(name: login),
        builder: (_) =>
            LoginPage(intendedRoute: route == login ? dashboard : route),
      );
    }
    if (shellRoutes.contains(route)) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => HomePage(initialLocation: route),
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
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
          const Icon(Icons.route_outlined, size: 56),
          const SizedBox(height: 16),
          Text(
            'Página não encontrada',
            style: Theme.of(context).textTheme.titleLarge,
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
