import 'dart:convert';
import 'dart:typed_data';

import 'package:app_24por7/core/theme/app_theme.dart';
import 'package:app_24por7/core/theme/branding_config.dart';
import 'package:app_24por7/src/model/api_client.dart';
import 'package:app_24por7/src/model/empresa_branding.dart';
import 'package:app_24por7/src/page/configuracoes_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _MemoryStorage implements SessionStorage {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async => this.value = value;
  @override
  Future<void> clear() async => value = null;
}

void main() {
  late List<http.Request> requests;
  late Map<String, dynamic> branding;
  late Map<String, dynamic> user;

  ApiClient client() {
    requests = [];
    final api = ApiClient(
      baseUrl: 'http://api',
      sessionStorage: _MemoryStorage(),
      httpClient: MockClient((request) async {
        requests.add(request);
        final path = request.url.path;
        if (path == '/empresas/me/branding') {
          if (request.method == 'PUT') {
            branding = Map<String, dynamic>.from(jsonDecode(request.body));
          }
          return http.Response.bytes(
            utf8.encode(jsonEncode(branding)),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        if (path == '/empresas/me/branding/logo') {
          final escuro = request.url.queryParameters['variante'] == 'escuro';
          final key = escuro ? 'logoDarkUrl' : 'logoUrl';
          branding[key] = request.method == 'POST'
              ? 'https://bucket/o/empresas/e1/logo/novo.png'
              : null;
          return http.Response(jsonEncode(branding), 200);
        }
        if (path == '/user/u1') {
          if (request.method == 'PUT') {
            user = {...user, ...jsonDecode(request.body) as Map};
            return http.Response('{"message":"ok"}', 200);
          }
          return http.Response(jsonEncode(user), 200);
        }
        return http.Response('{}', 404);
      }),
    );
    api.token = 'token';
    api.authenticatedUser = Map<String, dynamic>.from(user);
    return api;
  }

  setUp(() {
    resetBranding();
    branding = {
      'nomeExibicao': 'Mercado Bom',
      'logoUrl': null,
      'logoDarkUrl': null,
      'corPrincipal': '#169DFF',
      'corSecundaria': '#62C8FF',
      'corDestaque': '#00D084',
    };
    user = {
      'userId': 'u1',
      'nome': 'Ana',
      'sobrenome': 'Silva',
      'email': 'ana@x.com',
      'cpf': '12345678900',
      'role': 'ADMIN',
    };
  });

  Future<ApiClient> pump(
    WidgetTester tester, {
    Future<PickedImage?> Function()? pickImage,
  }) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = client();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(BrandingConfig.fallback),
        home: Scaffold(
          body: ConfiguracoesPage(
            brandingRepository: BrandingRepository(client: api),
            perfilRepository: PerfilRepository(client: api),
            pickImage:
                pickImage ??
                () async =>
                    (bytes: Uint8List.fromList([1, 2, 3]), name: 'logo.png'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return api;
  }

  testWidgets('carrega e salva nome e logo da Empresa', (tester) async {
    await pump(tester);
    expect(find.text('Mercado Bom'), findsWidgets);

    await tester.enterText(find.byKey(const Key('branding-nome')), 'Bom Preço');
    await tester.enterText(
      find.byKey(const Key('branding-logo')),
      'https://cdn.exemplo.com/logo.png',
    );
    await tester.tap(find.byKey(const Key('branding-save')));
    await tester.pumpAndSettle();

    final put = requests.lastWhere((r) => r.method == 'PUT');
    final body = jsonDecode(put.body) as Map;
    expect(body['nomeExibicao'], 'Bom Preço');
    expect(body['logoUrl'], 'https://cdn.exemplo.com/logo.png');
    expect(brandingNotifier.value.displayName, 'Bom Preço');
    expect(brandingNotifier.value.logoUrl, 'https://cdn.exemplo.com/logo.png');
    // Cores padrão do back não substituem o design system do app.
    expect(
      brandingNotifier.value.primaryColor,
      BrandingConfig.fallback.primaryColor,
    );
  });

  testWidgets('envia o logo e mantém edições não salvas', (tester) async {
    await pump(tester);
    await tester.enterText(find.byKey(const Key('branding-nome')), 'Rascunho');
    await tester.tap(find.byKey(const Key('branding-upload')));
    await tester.pumpAndSettle();

    final post = requests.lastWhere((r) => r.method == 'POST');
    expect(post.url.path, '/empresas/me/branding/logo');
    expect(post.url.queryParameters['variante'], 'claro');
    expect(post.headers['content-type'], startsWith('multipart/form-data'));
    expect(
      brandingNotifier.value.logoUrl,
      'https://bucket/o/empresas/e1/logo/novo.png',
    );
    expect(find.text('https://bucket/o/empresas/e1/logo/novo.png'), findsOne);
    expect(find.text('Rascunho'), findsWidgets);

    await tester.tap(find.byKey(const Key('branding-remove')));
    await tester.pumpAndSettle();
    expect(requests.last.method, 'DELETE');
    expect(brandingNotifier.value.logoUrl, isNull);
  });

  testWidgets('recusa imagem acima de 5 MB sem enviar', (tester) async {
    await pump(
      tester,
      pickImage: () async =>
          (bytes: Uint8List(maxLogoBytes + 1), name: 'grande.png'),
    );
    await tester.tap(find.byKey(const Key('branding-upload')));
    await tester.pumpAndSettle();
    expect(find.text('A imagem deve ter no máximo 5 MB'), findsOneWidget);
    expect(requests.where((r) => r.method == 'POST'), isEmpty);
  });

  testWidgets('recusa logo sem https', (tester) async {
    await pump(tester);
    await tester.enterText(
      find.byKey(const Key('branding-logo')),
      'http://inseguro.com/logo.png',
    );
    await tester.tap(find.byKey(const Key('branding-save')));
    await tester.pumpAndSettle();
    expect(find.text('Use um link que comece com https://'), findsOneWidget);
    expect(requests.where((r) => r.method == 'PUT'), isEmpty);
  });

  testWidgets('salva o nome do admin e atualiza a sessão', (tester) async {
    final api = await pump(tester);
    await tester.enterText(find.byKey(const Key('perfil-nome')), 'Ana Maria');
    await tester.tap(find.byKey(const Key('perfil-save')));
    await tester.pumpAndSettle();

    final put = requests.lastWhere((r) => r.method == 'PUT');
    expect(put.url.path, '/user/u1');
    expect((jsonDecode(put.body) as Map)['nome'], 'Ana Maria');
    expect(api.authenticatedUser?['nome'], 'Ana Maria');
    expect(find.text('Perfil salvo'), findsOneWidget);
  });

  test('cores personalizadas viram o tema do painel', () {
    final config = EmpresaBranding.fromJson({
      'nomeExibicao': 'X',
      'corPrincipal': '#FF0000',
      'corSecundaria': '#00FF00',
      'corDestaque': '#0000FF',
    }).toConfig();
    expect(config.primaryColor, const Color(0xFFFF0000));
    expect(config.secondaryColor, const Color(0xFF00FF00));
  });
}
