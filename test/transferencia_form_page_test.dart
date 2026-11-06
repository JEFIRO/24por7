import 'package:app_24por7/core/theme/app_theme.dart';
import 'package:app_24por7/core/theme/branding_config.dart';
import 'package:app_24por7/src/model/admin_history.dart';
import 'package:app_24por7/src/model/api_client.dart';
import 'package:app_24por7/src/model/estoque.dart';
import 'package:app_24por7/src/model/estoque_repository.dart';
import 'package:app_24por7/src/model/produto_repository.dart';
import 'package:app_24por7/src/page/transferencia_estoque_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeEstoqueRepository extends EstoqueRepository {
  _FakeEstoqueRepository(this.all) : super(client: ApiClient());
  final List<EstoqueCentral> all;
  final buscas = <String?>[];

  @override
  Future<List<CondominioOption>> condominios() async => const [
    CondominioOption(id: 'c1', nome: 'Residencial Aurora', ativo: true),
  ];

  @override
  Future<AdminPage<EstoqueCentral>> listarCentralPagina({
    int page = 0,
    int size = 50,
    String? busca,
    String? categoria,
    bool? ativo,
  }) async {
    if (page == 0) buscas.add(busca);
    final filtered = all
        .where(
          (e) =>
              busca == null ||
              e.produto.toLowerCase().contains(busca.toLowerCase()),
        )
        .toList();
    return AdminPage(
      items: filtered.skip(page * size).take(size).toList(),
      page: page,
      totalPages: (filtered.length / size).ceil(),
      totalElements: filtered.length,
    );
  }
}

EstoqueCentral _item(int i, String nome, String quantidade) =>
    EstoqueCentral.fromJson({
      'id': 'stock-$i',
      'produtoId': 'product-$i',
      'produto': nome,
      'codigoInterno': 'SKU$i',
      'categoria': 'BEBIDA',
      'quantidade': quantidade,
      'ativo': true,
    });

void main() {
  testWidgets('busca, adiciona produto e valida o disponível', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repository = _FakeEstoqueRepository([
      _item(0, 'Coca-Cola Lata', '24.000'),
      _item(1, 'Pepsi Black Lata 350ml', '5.000'),
      _item(2, 'Guaraná Zero', '0.000'),
      for (var i = 3; i < 80; i++) _item(i, 'Água $i', '10.000'),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(BrandingConfig.fallback),
        home: TransferenciaFormPage(repository: repository),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Adicione os produtos a transferir'), findsOneWidget);

    await tester.tap(find.text('Buscar produtos'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'pepsi');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(repository.buscas.last, 'pepsi');
    expect(find.text('Coca-Cola Lata'), findsNothing);

    await tester.tap(find.text('Pepsi Black Lata 350ml'));
    await tester.pump();
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    await tester.tap(find.text('Concluir'));
    await tester.pumpAndSettle();

    expect(find.text('Pepsi Black Lata 350ml'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Qtd.'), '8');
    await tester.pump();
    expect(find.text('Só há 5'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Qtd.'), '3');
    await tester.pump();
    expect(find.text('Só há 5'), findsNothing);
    expect(find.text('Revisar e confirmar (1 item)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
