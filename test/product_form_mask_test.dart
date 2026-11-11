import 'dart:typed_data';

import 'package:app_24por7/src/model/decimal_value.dart';
import 'package:app_24por7/src/model/produto.dart';
import 'package:app_24por7/src/model/produto_repository.dart';
import 'package:app_24por7/src/model/promocao.dart';
import 'package:app_24por7/src/model/promocao_repository.dart';
import 'package:app_24por7/src/page/cadastra_produto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeProdutoRepository extends ProdutoRepository {
  Produto? saved;
  final todos = <bool>[];
  final associados = <String>[];

  @override
  Future<List<CondominioOption>> listarCondominios() async => const [
    CondominioOption(id: 'cond-1', nome: 'Residencial Central', ativo: true),
    CondominioOption(id: 'cond-2', nome: 'Residencial Norte', ativo: true),
  ];

  @override
  Future<List<ProdutoCondominioDisponibilidade>> disponibilidadeCondominios(
    String produtoId,
  ) async => const [
    ProdutoCondominioDisponibilidade(
      condominioId: 'cond-1',
      condominioNome: 'Residencial Central',
      associado: true,
    ),
  ];

  @override
  Future<Produto> salvar(
    Produto produto, {
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    saved = produto;
    return Produto(
      id: 'product-1',
      codigoInterno: produto.codigoInterno,
      codigosBarras: produto.codigosBarras,
      nome: produto.nome,
      preco: produto.preco,
      unidadeMedida: produto.unidadeMedida,
      categoria: produto.categoria,
    );
  }

  @override
  Future<void> definirDisponivelEmTodos({
    required String produtoId,
    required bool ativo,
  }) async => todos.add(ativo);

  @override
  Future<void> associarAoCondominio({
    required String produtoId,
    required String condominioId,
    required DecimalValue quantidade,
    bool ativo = true,
  }) async => associados.add(condominioId);
}

class _FakePromocaoRepository extends PromocaoRepository {
  @override
  Future<List<Promocao>> listar({
    AbrangenciaPromocao? abrangencia,
    StatusPromocao? status,
    String? condominioId,
    String? produtoId,
  }) async => const [];
}

Future<void> _pump(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(theme: ThemeData(useMaterial3: true), home: page),
  );
  await tester.pumpAndSettle();
}

Future<void> _fill(WidgetTester tester, {required String preco}) async {
  await tester.enterText(find.byKey(const Key('product-sku-field')), 'SKU-1');
  await tester.enterText(
    find.byKey(const Key('product-name-field')),
    'Produto',
  );
  await tester.enterText(find.byKey(const Key('product-price-field')), preco);
  await tester.enterText(
    find.byKey(const Key('barcode-field-0')),
    '7894900011517',
  );
}

Future<void> _save(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('save-product-button')));
  await tester.tap(find.byKey(const Key('save-product-button')));
  await tester.pumpAndSettle();
}

String _text(WidgetTester tester, String key) =>
    tester.widget<TextFormField>(find.byKey(Key(key))).controller!.text;

void main() {
  testWidgets('preço e peso entram pela direita e vão como decimal exato', (
    tester,
  ) async {
    final repository = _FakeProdutoRepository();
    await _pump(tester, CadastraProduto(repository: repository));
    await _fill(tester, preco: '1500');
    expect(_text(tester, 'product-price-field'), '15,00');

    // Peso fica nos opcionais, recolhidos por padrão.
    final opcionais = find.text('Códigos adicionais e peso');
    await tester.ensureVisible(opcionais);
    await tester.tap(opcionais);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('product-weight-field')),
      '1250',
    );
    expect(_text(tester, 'product-weight-field'), '1,250');

    await _save(tester);
    expect(repository.saved?.preco.persistence, '15.000000');
    expect(repository.saved?.toRequestJson()['peso'], '1.250');
    expect(repository.saved?.pesoTolerancia, isNull);
  });

  testWidgets('sem SKU, o código de barras identifica o produto', (
    tester,
  ) async {
    final repository = _FakeProdutoRepository();
    await _pump(tester, CadastraProduto(repository: repository));
    await _fill(tester, preco: '1099');
    await tester.enterText(find.byKey(const Key('product-sku-field')), '');

    await _save(tester);
    expect(repository.saved?.codigoInterno, '7894900011517');
    expect(repository.saved?.codigoBarrasPrincipal, '7894900011517');
  });

  testWidgets('produto só com SKU é salvo sem código de barras', (
    tester,
  ) async {
    final repository = _FakeProdutoRepository();
    await _pump(tester, CadastraProduto(repository: repository));
    await _fill(tester, preco: '1099');
    await tester.enterText(find.byKey(const Key('barcode-field-0')), '');

    await _save(tester);
    expect(repository.saved?.codigoInterno, 'SKU-1');
    expect(repository.saved?.codigosBarras, isEmpty);
  });

  testWidgets('sem SKU e sem código de barras o cadastro é recusado', (
    tester,
  ) async {
    final repository = _FakeProdutoRepository();
    await _pump(tester, CadastraProduto(repository: repository));
    await _fill(tester, preco: '1099');
    await tester.enterText(find.byKey(const Key('product-sku-field')), '');
    await tester.enterText(find.byKey(const Key('barcode-field-0')), '');

    await _save(tester);
    expect(find.text('Informe o código de barras ou o SKU'), findsOneWidget);
    expect(repository.saved, isNull);
  });

  testWidgets('estoque mínimo vai no cadastro e vazio vai como sem mínimo', (
    tester,
  ) async {
    final repository = _FakeProdutoRepository();
    await _pump(tester, CadastraProduto(repository: repository));
    await _fill(tester, preco: '1099');
    await tester.enterText(
      find.byKey(const Key('product-min-central-field')),
      '10',
    );
    await _save(tester);

    final json = repository.saved!.toRequestJson();
    expect(json['estoqueMinimoCentral'], '10.000');
    // Zero é o que limpa o mínimo no backend.
    expect(json['estoqueMinimoCondominio'], '0.000');
  });

  testWidgets('edição abre o estoque mínimo já preenchido', (tester) async {
    await _pump(
      tester,
      CadastraProduto(
        repository: _FakeProdutoRepository(),
        promocaoRepository: _FakePromocaoRepository(),
        produto: Produto.fromJson({
          'id': 'product-1',
          'codigoInterno': 'SKU-1',
          'nome': 'Produto',
          'preco': '10.99',
          'estoqueMinimoCentral': '12.000',
          'estoqueMinimoCondominio': '2.500',
        }),
      ),
    );

    expect(_text(tester, 'product-min-central-field'), '12');
    expect(_text(tester, 'product-min-condominium-field'), '2,5');
  });

  testWidgets('preço zero não é salvo', (tester) async {
    final repository = _FakeProdutoRepository();
    await _pump(tester, CadastraProduto(repository: repository));
    await _fill(tester, preco: '0');
    expect(_text(tester, 'product-price-field'), '0,00');

    await _save(tester);
    expect(find.text('Informe um valor maior que zero'), findsOneWidget);
    expect(repository.saved, isNull);
  });

  testWidgets('edição abre os campos já formatados', (tester) async {
    await _pump(
      tester,
      CadastraProduto(
        repository: _FakeProdutoRepository(),
        promocaoRepository: _FakePromocaoRepository(),
        produto: Produto(
          id: 'product-1',
          codigoInterno: 'SKU-1',
          codigosBarras: const [
            ProdutoCodigoBarras(codigo: '7894900011517', principal: true),
          ],
          nome: 'Produto',
          preco: DecimalValue.parse('1234.500000'),
          peso: DecimalValue.parse('0.35'),
          unidadeMedida: 'UN',
          categoria: 'OUTROS',
        ),
      ),
    );

    expect(_text(tester, 'product-price-field'), '1.234,50');
    expect(_text(tester, 'product-weight-field'), '0,350');
  });

  testWidgets('avisa quando o produto não fica à venda em nenhum condomínio', (
    tester,
  ) async {
    final repository = _FakeProdutoRepository();
    await _pump(tester, CadastraProduto(repository: repository));
    final aviso = find.byKey(const Key('product-no-condominium-warning'));
    // Abre ligado em todos os condomínios, então não há o que avisar.
    expect(aviso, findsNothing);

    final interruptor = find.byKey(
      const Key('product-all-condominiums-switch'),
    );
    await tester.ensureVisible(interruptor);
    await tester.tap(interruptor);
    await tester.pump();
    expect(aviso, findsOneWidget);

    final central = find.text('Residencial Central');
    await tester.ensureVisible(central);
    await tester.tap(central);
    await tester.pump();
    expect(aviso, findsNothing);
  });

  testWidgets('validação rola até o primeiro campo com erro', (tester) async {
    await _pump(tester, CadastraProduto(repository: _FakeProdutoRepository()));
    await _save(tester);

    final erro = find.text('Campo obrigatório').first;
    final topo = tester.getTopLeft(erro).dy;
    expect(topo, inInclusiveRange(0, 800));
  });

  testWidgets('edição mostra o link de estoque e as promoções', (tester) async {
    await _pump(
      tester,
      CadastraProduto(
        repository: _FakeProdutoRepository(),
        promocaoRepository: _FakePromocaoRepository(),
        produto: Produto(
          id: 'product-1',
          codigoInterno: 'SKU-1',
          codigosBarras: const [
            ProdutoCodigoBarras(codigo: '7894900011517', principal: true),
          ],
          nome: 'Produto',
          preco: DecimalValue.parse('10.99'),
          unidadeMedida: 'DUZIA',
          categoria: 'LATICINIOS',
        ),
      ),
    );

    expect(find.byKey(const Key('product-stock-link')), findsOneWidget);
    expect(find.byKey(const Key('product-promotions-section')), findsOneWidget);
    expect(find.text('Laticínios'), findsOneWidget);
    expect(find.text('Dúzia'), findsOneWidget);
    // Na edição o produto já está no Residencial Central.
    expect(
      find.byKey(const Key('product-no-condominium-warning')),
      findsNothing,
    );
  });

  testWidgets('produto novo abre disponível em todos os condomínios', (
    tester,
  ) async {
    final repository = _FakeProdutoRepository();
    await _pump(tester, CadastraProduto(repository: repository));
    await _fill(tester, preco: '1099');

    // Produto novo já abre com o interruptor ligado.
    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const Key('product-all-condominiums-switch')),
          )
          .value,
      isTrue,
    );
    final condominios = tester.widgetList<CheckboxListTile>(
      find.descendant(
        of: find.byKey(const Key('product-availability-section')),
        matching: find.byType(CheckboxListTile),
      ),
    );
    expect(condominios, hasLength(2));
    for (final box in condominios) {
      expect(box.value, isTrue);
      expect(box.onChanged, isNull);
    }

    await _save(tester);
    expect(repository.todos, [true]);
    // A associação fica por conta do backend, não uma chamada por condomínio.
    expect(repository.associados, isEmpty);
  });
}
