import 'package:app_24por7/core/theme/app_theme.dart';
import 'package:app_24por7/src/model/admin_history.dart';
import 'package:app_24por7/src/model/api_client.dart';
import 'package:app_24por7/src/model/decimal_value.dart';
import 'package:app_24por7/src/model/estoque.dart';
import 'package:app_24por7/src/model/estoque_repository.dart';
import 'package:app_24por7/src/model/inventario.dart';
import 'package:app_24por7/src/model/inventario_repository.dart';
import 'package:app_24por7/src/model/produto.dart';
import 'package:app_24por7/src/model/produto_repository.dart';
import 'package:app_24por7/src/page/estoque_central_page.dart';
import 'package:app_24por7/src/page/estoque_condominio_page.dart';
import 'package:app_24por7/src/page/estoque_hub_page.dart';
import 'package:app_24por7/src/page/estoque_produto_page.dart';
import 'package:app_24por7/src/page/transferencia_estoque_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz;

class _FakeRepository extends EstoqueRepository {
  _FakeRepository({this.estoqueCondo = const [], this.falhaAoMovimentar})
    : super(client: ApiClient());
  final List<Map<String, dynamic>> estoqueCondo;
  final String? falhaAoMovimentar;
  final movimentacoes = <String>[];
  final locaisDoHistorico = <String?>[];

  final central = EstoqueCentral.fromJson({
    'id': 'stock-1',
    'produtoId': 'p1',
    'produto': 'Água 500ml',
    'codigoInterno': 'SKU1',
    'categoria': 'BEBIDA',
    'quantidade': '10.000',
    'ativo': true,
  });

  @override
  Future<AdminPage<EstoqueCentral>> listarCentralPagina({
    int page = 0,
    int size = 50,
    String? busca,
    String? categoria,
    bool? ativo,
  }) async =>
      AdminPage(items: [central], page: 0, totalPages: 1, totalElements: 1);

  @override
  Future<List<Produto>> listarProdutos() async => [
    Produto.fromJson({
      'id': 'p1',
      'codigoInterno': 'SKU1',
      'nome': 'Água 500ml',
      'preco': '3.50',
      'unidadeMedida': 'UN',
      'categoria': 'BEBIDA',
    }),
  ];

  @override
  Future<EstoqueCentral> movimentar(
    String produtoId,
    String operacao,
    DecimalValue quantidade,
    String motivo,
  ) async {
    if (falhaAoMovimentar != null) throw Exception(falhaAoMovimentar);
    movimentacoes.add('$operacao ${quantidade.friendly}');
    return central;
  }

  @override
  Future<List<CondominioOption>> condominios() async => const [
    CondominioOption(id: 'c1', nome: 'Residencial Um', ativo: true),
    CondominioOption(id: 'c2', nome: 'Residencial Dois', ativo: true),
  ];

  @override
  Future<List<Map<String, dynamic>>> estoqueCondominio(String id) async =>
      estoqueCondo;

  @override
  Future<List<ProdutoCondominioDisponibilidade>> saldosNosCondominios(
    String produtoId,
  ) async => [
    ProdutoCondominioDisponibilidade(
      condominioId: 'c1',
      condominioNome: 'Residencial Um',
      associado: true,
      quantidade: DecimalValue.parse('4'),
    ),
    const ProdutoCondominioDisponibilidade(
      condominioId: 'c2',
      condominioNome: 'Residencial Dois',
      associado: false,
    ),
  ];

  @override
  Future<List<TransferenciaEstoque>> transferencias({String? status}) async =>
      const [];

  @override
  Future<List<MovimentoEstoque>> movimentos({String? condominioId}) async {
    locaisDoHistorico.add(condominioId);
    return _movimentos;
  }

  static final _movimentos = [
    for (final produtoId in ['p1', 'apagado'])
      MovimentoEstoque.fromJson({
        'id': 'm-$produtoId',
        'localTipo': 'ESTOQUE_EMPRESA',
        'produtoId': produtoId,
        'tipo': 'ENTRADA',
        'quantidade': '5.000',
        'quantidadeAnterior': '5.000',
        'quantidadePosterior': '10.000',
        'createdAt': '2026-11-01T12:00:00Z',
      }),
  ];
}

class _FakeInventarioRepository extends InventarioRepository {
  _FakeInventarioRepository() : super(client: ApiClient());

  @override
  Future<List<Inventario>> listar({String? status}) async => const [];
}

Future<void> _pump(
  WidgetTester tester,
  Widget page, {
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: page),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    tz.initializeTimeZones();
    await initializeDateFormatting('pt_BR');
  });

  Widget hub(_FakeRepository repository) => EstoqueHubPage(
    repository: repository,
    inventarioRepository: _FakeInventarioRepository(),
  );

  Future<void> escolherLocal(WidgetTester tester, String nome) async {
    await tester.tap(find.text('Estoque central'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(nome).last);
    await tester.pumpAndSettle();
  }

  group('painel de movimentação', () {
    testWidgets('quantidade inválida mantém o painel aberto com o erro', (
      tester,
    ) async {
      final repository = _FakeRepository();
      await _pump(tester, EstoqueCentralPage(repository: repository));
      await tester.tap(find.text('Água 500ml'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Corrigir saldo'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirmar'));
      await tester.pump();
      expect(find.text('Informe a quantidade'), findsOneWidget);

      final campo = find.widgetWithText(TextField, 'Quantidade');
      await tester.enterText(campo, '1,2345');
      await tester.tap(find.text('Confirmar'));
      await tester.pump();
      expect(
        find.text('Use um número com até 3 casas decimais'),
        findsOneWidget,
      );

      await tester.enterText(campo, '0');
      await tester.tap(find.text('Confirmar'));
      await tester.pump();
      expect(find.text('A quantidade deve ser maior que zero'), findsOneWidget);
      expect(repository.movimentacoes, isEmpty);

      await tester.enterText(campo, '2,5');
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();
      expect(repository.movimentacoes, ['ENTRADA 2,5']);
      expect(find.text('Corrigir saldo do central'), findsNothing);
    });

    testWidgets('erro da API aparece sem perder o que foi digitado', (
      tester,
    ) async {
      final repository = _FakeRepository(
        falhaAoMovimentar: 'Saldo insuficiente',
      );
      await _pump(tester, EstoqueCentralPage(repository: repository));
      await tester.tap(find.text('Água 500ml'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Corrigir saldo'));
      await tester.pumpAndSettle();

      final campo = find.widgetWithText(TextField, 'Quantidade');
      await tester.enterText(campo, '3');
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Saldo insuficiente'), findsOneWidget);
      expect(tester.widget<TextField>(campo).controller!.text, '3');
    });
  });

  group('tela única de estoque', () {
    testWidgets('abre nos saldos do central e troca de aba', (tester) async {
      await _pump(tester, hub(_FakeRepository()), size: const Size(1400, 900));
      expect(find.text('Água 500ml'), findsOneWidget);
      expect(find.text('Estoque central'), findsOneWidget);

      await tester.tap(find.text('Transferências'));
      await tester.pumpAndSettle();
      expect(find.text('Nenhuma transferência registrada'), findsOneWidget);
      expect(find.text('Estoque central'), findsNothing);

      await tester.tap(find.text('Inventários'));
      await tester.pumpAndSettle();
      expect(find.text('Nenhum inventário encontrado'), findsOneWidget);
    });

    testWidgets('o local escolhido vale para saldos e histórico', (
      tester,
    ) async {
      final repository = _FakeRepository(
        estoqueCondo: [
          {
            'produtoId': 'p1',
            'produto': 'Água 500ml',
            'quantidade': 4,
            'ativo': true,
          },
        ],
      );
      await _pump(tester, hub(repository));
      await escolherLocal(tester, 'Residencial Dois');
      expect(find.text('4,000 UN'), findsOneWidget);

      await tester.tap(find.text('Histórico'));
      await tester.pumpAndSettle();
      expect(repository.locaisDoHistorico, ['c2']);
      expect(find.text('Residencial Dois'), findsOneWidget);
      expect(find.text('Água 500ml'), findsOneWidget);
      expect(find.text('Produto não encontrado'), findsOneWidget);
    });

    testWidgets('condomínio vazio leva à transferência já com o destino', (
      tester,
    ) async {
      await _pump(tester, hub(_FakeRepository()));
      await escolherLocal(tester, 'Residencial Dois');

      await tester.tap(find.text('Abastecer este condomínio'));
      await tester.pumpAndSettle();

      expect(find.byType(TransferenciaFormPage), findsOneWidget);
      expect(find.text('Residencial Dois'), findsOneWidget);
    });

    testWidgets('no celular as operações ficam em "Nova operação"', (
      tester,
    ) async {
      await _pump(tester, hub(_FakeRepository()));
      await tester.tap(find.text('Nova operação'));
      await tester.pumpAndSettle();

      for (final operacao in [
        'Receber por NF-e',
        'Entrada manual',
        'Abastecer condomínio',
        'Contar estoque',
        'Planograma',
      ]) {
        expect(find.text(operacao), findsOneWidget);
      }

      await tester.tap(find.text('Abastecer condomínio'));
      await tester.pumpAndSettle();
      expect(find.byType(TransferenciaFormPage), findsOneWidget);
    });

    testWidgets('no computador "Receber mercadoria" abre a entrada manual', (
      tester,
    ) async {
      final repository = _FakeRepository();
      await _pump(tester, hub(repository), size: const Size(1400, 900));
      expect(find.text('Contar estoque'), findsOneWidget);
      expect(find.text('Abastecer condomínio'), findsOneWidget);

      await tester.tap(find.text('Receber mercadoria'));
      await tester.pumpAndSettle();
      expect(find.text('Por NF-e'), findsOneWidget);
      await tester.tap(find.text('Entrada manual'));
      await tester.pumpAndSettle();

      // Só entrada: sem o seletor de Saída e Ajuste.
      expect(find.text('Saída'), findsNothing);
      await tester.enterText(find.widgetWithText(TextField, 'Quantidade'), '6');
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();
      expect(repository.movimentacoes, ['ENTRADA 6']);
    });
  });

  group('detalhe do produto', () {
    testWidgets('mostra o saldo por local e o histórico de todos os locais', (
      tester,
    ) async {
      final repository = _FakeRepository();
      await _pump(tester, hub(repository), size: const Size(1400, 900));
      await tester.tap(find.text('Água 500ml'));
      await tester.pumpAndSettle();

      expect(find.byType(EstoqueProdutoPage), findsOneWidget);
      expect(find.text('SKU SKU1'), findsOneWidget);
      expect(find.text('10 UN'), findsOneWidget);
      expect(find.text('4 UN'), findsOneWidget);
      // Só os condomínios onde o produto está disponível.
      expect(find.text('Residencial Dois'), findsNothing);
      // Uma movimentação no central e outra no Residencial Um.
      expect(repository.locaisDoHistorico, [null, 'c1']);
      expect(find.text('Estoque central'), findsNWidgets(2));
      expect(find.text('Residencial Um'), findsNWidgets(2));
    });

    testWidgets(
      'abastecer leva o produto e o condomínio para a transferência',
      (tester) async {
        await _pump(
          tester,
          EstoqueProdutoPage(
            produtoId: 'p1',
            nome: 'Água 500ml',
            repository: _FakeRepository(),
          ),
        );
        await tester.tap(find.text('Residencial Um'));
        await tester.pumpAndSettle();

        expect(find.byType(TransferenciaFormPage), findsOneWidget);
        expect(find.text('Residencial Um'), findsOneWidget);
        expect(find.text('Água 500ml'), findsOneWidget);
        expect(find.text('Adicione os produtos a transferir'), findsNothing);
      },
    );
  });

  testWidgets('saldo abaixo do mínimo aparece como estoque baixo', (
    tester,
  ) async {
    await _pump(
      tester,
      EstoqueCondominioPage(
        condominioId: 'c1',
        repository: _FakeRepository(
          estoqueCondo: [
            {
              'produtoId': 'p1',
              'produto': 'Água 500ml',
              'quantidade': 4,
              'ativo': true,
              'estoqueMinimo': 6,
              'abaixoDoMinimo': true,
            },
          ],
        ),
      ),
      size: const Size(1400, 900),
    );

    expect(find.text('Estoque baixo (mín. 6)'), findsOneWidget);
    expect(find.text('Ativo'), findsNothing);
  });

  testWidgets('saldo do condomínio mostra unidade, SKU e categoria', (
    tester,
  ) async {
    await _pump(
      tester,
      EstoqueCondominioPage(
        condominioId: 'c1',
        repository: _FakeRepository(
          estoqueCondo: [
            {
              'produtoId': 'p1',
              'produto': 'Água 500ml',
              'quantidade': 4,
              'ativo': true,
            },
          ],
        ),
      ),
      size: const Size(1400, 900),
    );

    expect(find.text('4,000 UN'), findsOneWidget);
    expect(find.text('SKU SKU1'), findsOneWidget);
    expect(find.text('Bebida'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'sku1');
    await tester.pump();
    expect(find.text('Água 500ml'), findsOneWidget);
  });
}
