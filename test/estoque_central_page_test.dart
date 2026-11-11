import 'package:app_24por7/core/theme/app_theme.dart';
import 'package:app_24por7/src/model/admin_history.dart';
import 'package:app_24por7/src/model/api_client.dart';
import 'package:app_24por7/src/model/estoque.dart';
import 'package:app_24por7/src/model/estoque_repository.dart';
import 'package:app_24por7/src/page/estoque_central_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeEstoqueRepository extends EstoqueRepository {
  _FakeEstoqueRepository(this.all) : super(client: ApiClient());
  final List<EstoqueCentral> all;
  final pagesRequested = <int>[];

  @override
  Future<AdminPage<EstoqueCentral>> listarCentralPagina({
    int page = 0,
    int size = 50,
    String? busca,
    String? categoria,
    bool? ativo,
  }) async {
    pagesRequested.add(page);
    final start = page * size;
    return AdminPage(
      items: all.skip(start).take(size).toList(),
      page: page,
      totalPages: (all.length / size).ceil(),
      totalElements: all.length,
    );
  }
}

EstoqueCentral _item(int i, {String? nome}) => EstoqueCentral.fromJson({
  'id': 'stock-$i',
  'produtoId': 'product-$i',
  'produto': nome ?? 'Produto ${i.toString().padLeft(3, '0')}',
  'codigoInterno': 'SKU$i',
  'categoria': 'BEBIDA',
  'quantidade': '10.000',
  'ativo': true,
});

Future<void> _pump(WidgetTester tester, EstoqueRepository repository) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: EstoqueCentralPage(repository: repository)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('carrega as próximas páginas ao rolar até o fim', (tester) async {
    final repository = _FakeEstoqueRepository([
      for (var i = 0; i < 120; i++) _item(i),
    ]);
    await _pump(tester, repository);
    expect(find.text('Mostrando 50 de 120 produtos'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Produto 119'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Produto 119'), findsOneWidget);
    expect(find.text('Mostrando 120 de 120 produtos'), findsOneWidget);
    expect(repository.pagesRequested, [0, 1, 2]);
  });

  testWidgets('painel de movimentação não estoura com nome longo', (
    tester,
  ) async {
    final repository = _FakeEstoqueRepository([
      _item(
        0,
        nome:
            'Refrigerante Pepsi Black Sem Açúcar Lata Edição Especial '
            'Pacote Promocional com 12 unidades de 350ml',
      ),
    ]);
    await _pump(tester, repository);

    await tester.tap(find.textContaining('Refrigerante Pepsi Black'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Corrigir saldo'));
    await tester.pumpAndSettle();

    expect(find.text('Corrigir saldo do central'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('quantidade começa vazia e mostra o novo saldo', (tester) async {
    final repository = _FakeEstoqueRepository([_item(0)]);
    await _pump(tester, repository);

    await tester.tap(find.text('Produto 000'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Corrigir saldo'));
    await tester.pumpAndSettle();

    final campo = find.widgetWithText(TextField, 'Quantidade');
    expect(tester.widget<TextField>(campo).controller!.text, isEmpty);

    await tester.enterText(campo, '2,5');
    await tester.pump();
    expect(find.text('Saldo passa de 10 para 12,5 UN'), findsOneWidget);

    await tester.tap(find.text('Saída'));
    await tester.pump();
    expect(find.text('Saldo passa de 10 para 7,5 UN'), findsOneWidget);
  });
}
