import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:app_24por7/src/model/api_client.dart';
import 'package:app_24por7/src/model/app_cliente_config.dart';
import 'package:app_24por7/src/page/app_cliente_config_page.dart';

void main() {
  late List<String> calls;
  late Map<String, Object?> bodies;

  Widget page({String modo = 'NONE', bool fidelidadeAtiva = false}) {
    final client = MockClient((request) async {
      final call = '${request.method} ${request.url.path}';
      calls.add(call);
      if (request.body.isNotEmpty) bodies[call] = jsonDecode(request.body);
      if (request.url.path.endsWith('/fidelidade')) {
        return http.Response(
          jsonEncode({'ativo': fidelidadeAtiva, 'modo': modo}),
          200,
        );
      }
      return http.Response(
        jsonEncode({
          'catalogoAtivo': false,
          'promocoesAtivas': false,
          'fidelidadeAtiva': fidelidadeAtiva,
          'qrIdentificacaoAtivo': false,
          'preferenciasAtivas': false,
          'suporteAtivo': false,
        }),
        200,
      );
    });
    final api = ApiClient(httpClient: client, baseUrl: 'http://api')
      ..token = 'test';
    return MaterialApp(
      home: Scaffold(
        body: AppClienteConfigPage(
          repository: AppClienteRepository(client: api),
        ),
      ),
    );
  }

  setUp(() {
    calls = [];
    bodies = {};
  });

  testWidgets('salva fidelidade antes da configuração e recarrega', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1200, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(page());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Catálogo'));
    await tester.tap(find.text('Programa de fidelidade'));
    await tester.enterText(find.byType(TextFormField), '1');
    calls.clear();
    await tester.tap(find.byKey(const Key('app-cliente-save')));
    await tester.pumpAndSettle();

    expect(calls, [
      'PUT /admin/app-cliente/fidelidade',
      'PUT /admin/app-cliente/config',
      'GET /admin/app-cliente/config',
      'GET /admin/app-cliente/fidelidade',
    ]);
    expect(bodies['PUT /admin/app-cliente/fidelidade'], {
      'ativo': true,
      'modo': 'POINTS',
      'pontosPorReal': '1.000000',
      'cashbackPercentual': null,
    });
    final config = bodies['PUT /admin/app-cliente/config'] as Map;
    expect(config['catalogoAtivo'], true);
    expect(config['fidelidadeAtiva'], true);
    expect(find.text('Configurações do App Cliente salvas'), findsOneWidget);
  });

  testWidgets('fidelidade ativa exige valor maior que zero', (tester) async {
    tester.view
      ..physicalSize = const Size(1200, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(page());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Programa de fidelidade'));
    await tester.enterText(find.byType(TextFormField), '0');
    calls.clear();
    await tester.tap(find.byKey(const Key('app-cliente-save')));
    await tester.pumpAndSettle();

    expect(calls, isEmpty);
    expect(find.text('O valor deve ser maior que zero'), findsOneWidget);
  });
}
