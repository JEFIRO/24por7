import 'dart:async';
import 'dart:typed_data';

import 'package:app_24por7/src/model/decimal_value.dart';
import 'package:app_24por7/src/model/produto.dart';
import 'package:app_24por7/src/model/produto_repository.dart';
import 'package:app_24por7/src/model/promocao.dart';
import 'package:app_24por7/src/model/promocao_repository.dart';
import 'package:app_24por7/src/page/cadastra_produto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('cadastro mobile organiza todas as seções sem overflow', (
    tester,
  ) async {
    await _surface(tester, const Size(360, 800));
    await tester.pumpWidget(
      _app(CadastraProduto(repository: _FakeProdutoRepository())),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('product-general-section')), findsOneWidget);
    expect(find.byKey(const Key('product-price-section')), findsOneWidget);
    expect(find.byKey(const Key('product-barcodes-section')), findsOneWidget);
    expect(find.byKey(const Key('product-stock-section')), findsOneWidget);
    expect(find.byKey(const Key('product-fiscal-section')), findsOneWidget);
    expect(find.byKey(const Key('product-promotions-section')), findsOneWidget);
    expect(find.byKey(const Key('save-product-button')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cadastro Web usa duas colunas no bloco principal', (
    tester,
  ) async {
    await _surface(tester, const Size(1366, 1000));
    await tester.pumpWidget(
      _app(CadastraProduto(repository: _FakeProdutoRepository())),
    );
    await tester.pumpAndSettle();

    final general = tester.getTopLeft(
      find.byKey(const Key('product-general-section')),
    );
    final price = tester.getTopLeft(
      find.byKey(const Key('product-price-section')),
    );
    expect(price.dx, greaterThan(general.dx));
    expect((price.dy - general.dy).abs(), lessThan(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('layout permanece estável em 600, 1024 e 1920 pixels', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });
    for (final width in [600.0, 1024.0, 1920.0]) {
      tester.view.physicalSize = Size(width, 1000);
      await tester.pumpWidget(
        _app(CadastraProduto(repository: _FakeProdutoRepository())),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('product-general-section')), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'largura $width');
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('valida nome, SKU, preço e barcode antes do envio', (
    tester,
  ) async {
    await _surface(tester, const Size(360, 800));
    final repository = _FakeProdutoRepository();
    await tester.pumpWidget(_app(CadastraProduto(repository: repository)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-product-button')));
    await tester.pump();

    expect(find.text('Campo obrigatório'), findsWidgets);
    expect(repository.saveCalls, 0);
  });

  testWidgets('salvamento fica desabilitado e impede duplo submit', (
    tester,
  ) async {
    await _surface(tester, const Size(360, 800));
    final repository = _FakeProdutoRepository()
      ..saveCompleter = Completer<Produto>();
    await tester.pumpWidget(_app(CadastraProduto(repository: repository)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('product-sku-field')), 'SKU-1');
    await tester.enterText(
      find.byKey(const Key('product-name-field')),
      'Produto',
    );
    await tester.enterText(
      find.byKey(const Key('product-price-field')),
      '10,99',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('barcode-field-0')),
      300,
      maxScrolls: 20,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.byKey(const Key('barcode-field-0')).first,
      '7894900011517',
    );
    await tester.tap(find.byKey(const Key('save-product-button')));
    await tester.pump();

    final button = tester.widget<FilledButton>(
      find.byKey(const Key('save-product-button')),
    );
    expect(button.onPressed, isNull);
    await tester.tap(
      find.byKey(const Key('save-product-button')),
      warnIfMissed: false,
    );
    expect(repository.saveCalls, 1);

    repository.saveCompleter!.complete(_savedProduct());
    await tester.pumpAndSettle();
  });

  testWidgets(
    'produto novo integra estoque inicial e associação ao condomínio',
    (tester) async {
      await _surface(tester, const Size(360, 800));
      final repository = _FakeProdutoRepository();
      await tester.pumpWidget(_app(CadastraProduto(repository: repository)));
      await tester.pumpAndSettle();
      await _fillRequiredFields(tester);
      await tester.enterText(
        find.byKey(const Key('initial-stock-field')),
        '100',
      );
      await tester.scrollUntilVisible(
        find.text('Residencial Central'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Residencial Central'));
      await tester.tap(find.byKey(const Key('save-product-button')));
      await tester.pumpAndSettle();

      expect(repository.stockCalls, 1);
      expect(repository.stockQuantity?.fixedScale(3), '100.000');
      expect(repository.associatedCondominiums, ['cond-1']);
      expect(repository.capturedProduct?.preco.persistence, '10.990000');
    },
  );

  testWidgets('edição preserva barcodes inativos e dados fiscais reais', (
    tester,
  ) async {
    await _surface(tester, const Size(360, 800));
    final repository = _FakeProdutoRepository();
    final product = Produto(
      id: 'product-1',
      codigoInterno: 'SKU-EDIT',
      codigosBarras: const [
        ProdutoCodigoBarras(codigo: '7894900011517', principal: true),
        ProdutoCodigoBarras(codigo: '7894900011524', ativo: false),
      ],
      nome: 'Produto editável',
      preco: DecimalValue.parse('12.50'),
      unidadeMedida: 'UN',
      categoria: 'OUTROS',
      fiscal: const ProdutoFiscal(ncm: '22021000', unidadeTributavel: 'UN'),
    );
    await tester.pumpWidget(
      _app(
        CadastraProduto(
          produto: product,
          repository: repository,
          promocaoRepository: _FakePromocaoRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Editar produto'), findsWidgets);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('barcode-field-0')))
          .controller
          ?.text,
      '7894900011517',
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('barcode-field-1')))
          .controller
          ?.text,
      '7894900011524',
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextFormField && widget.controller?.text == '22021000',
      ),
      findsOneWidget,
    );
    expect(find.text('Oferta de setembro'), findsOneWidget);
    await tester.tap(find.byKey(const Key('save-product-button')));
    await tester.pumpAndSettle();
    expect(repository.capturedProduct?.id, 'product-1');
    expect(repository.capturedProduct?.codigosBarras.last.ativo, isFalse);
  });
}

class _FakePromocaoRepository extends PromocaoRepository {
  @override
  Future<List<Promocao>> listar({
    AbrangenciaPromocao? abrangencia,
    StatusPromocao? status,
    String? condominioId,
    String? produtoId,
  }) async {
    expect(status, StatusPromocao.ativa);
    expect(produtoId, 'product-1');
    return [
      Promocao(
        id: 'promo-1',
        nome: 'Oferta de setembro',
        abrangencia: AbrangenciaPromocao.empresa,
        tipo: TipoPromocao.percentual,
        valor: DecimalValue.parse('10'),
        inicio: DateTime(2026, 9, 1),
        fim: DateTime(2026, 9, 30),
        ativo: true,
        status: StatusPromocao.ativa,
        prioridade: 1,
        produtos: const [],
      ),
    ];
  }
}

class _FakeProdutoRepository extends ProdutoRepository {
  int saveCalls = 0;
  int stockCalls = 0;
  Completer<Produto>? saveCompleter;
  Produto? capturedProduct;
  DecimalValue? stockQuantity;
  final List<String> associatedCondominiums = [];

  @override
  Future<List<CondominioOption>> listarCondominios() async => const [
    CondominioOption(id: 'cond-1', nome: 'Residencial Central', ativo: true),
  ];

  @override
  Future<Produto> salvar(
    Produto produto, {
    Uint8List? imageBytes,
    String? imageName,
  }) {
    saveCalls++;
    capturedProduct = produto;
    return saveCompleter?.future ?? Future.value(_savedProduct());
  }

  @override
  Future<void> registrarEstoqueInicial({
    required String produtoId,
    required DecimalValue quantidade,
    required String motivo,
  }) async {
    stockCalls++;
    stockQuantity = quantidade;
  }

  @override
  Future<void> associarAoCondominio({
    required String produtoId,
    required String condominioId,
    required DecimalValue quantidade,
    bool ativo = true,
  }) async {
    associatedCondominiums.add(condominioId);
  }

  @override
  Future<List<ProdutoCondominioDisponibilidade>> disponibilidadeCondominios(
    String produtoId,
  ) async => const [
    ProdutoCondominioDisponibilidade(
      condominioId: 'cond-1',
      condominioNome: 'Residencial Central',
      associado: false,
    ),
  ];
}

Future<void> _fillRequiredFields(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('product-sku-field')), 'SKU-1');
  await tester.enterText(
    find.byKey(const Key('product-name-field')),
    'Produto',
  );
  await tester.enterText(find.byKey(const Key('product-price-field')), '10,99');
  await tester.enterText(
    find.byKey(const Key('barcode-field-0')),
    '7894900011517',
  );
}

Produto _savedProduct() => Produto(
  id: 'product-1',
  codigoInterno: 'SKU-1',
  codigosBarras: const [
    ProdutoCodigoBarras(codigo: '7894900011517', principal: true),
  ],
  nome: 'Produto',
  preco: DecimalValue.parse('10.99'),
  unidadeMedida: 'UN',
  categoria: 'OUTROS',
);

Widget _app(Widget child) =>
    MaterialApp(theme: ThemeData(useMaterial3: true), home: child);

Future<void> _surface(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
}
