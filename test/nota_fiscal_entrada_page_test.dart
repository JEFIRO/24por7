import 'dart:typed_data';

import 'package:app_24por7/core/theme/app_theme.dart';
import 'package:app_24por7/src/model/api_client.dart';
import 'package:app_24por7/src/model/nota_fiscal_entrada.dart';
import 'package:app_24por7/src/model/nota_fiscal_entrada_repository.dart';
import 'package:app_24por7/src/page/nota_fiscal_entrada_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _chave = '29261111222333000181550010000012341123456783';

Map<String, dynamic> _item(
  int n, {
  String status = 'PENDENTE',
  String acao = 'CRIAR',
  num? preco,
  String unidade = 'UN',
  num fator = 1,
}) => {
  'id': 'item-$n',
  'numeroItem': n,
  'descricao': 'PRODUTO $n',
  'unidadeComercial': unidade,
  'quantidade': 2,
  'valorTotal': 72,
  'acao': acao,
  'unidadeMedida': 'UN',
  'fatorConversao': fator,
  'quantidadeEntrada': 2 * fator,
  'custoUnitarioVenda': 72 / (2 * fator),
  'status': status,
  'nomeProduto': 'PRODUTO $n',
  'precoVenda': preco,
  'categoria': 'BEBIDA',
  'mensagem': status == 'PENDENTE' ? 'Informe o preço de venda' : null,
};

NotaFiscalEntrada _nota({
  required List<Map<String, dynamic>> itens,
  String status = 'VALIDADA',
}) {
  final pendentes = itens.where((i) => i['status'] == 'PENDENTE').length;
  return NotaFiscalEntrada.fromJson({
    'id': 'nota-1',
    'chave': _chave,
    'numero': '1234',
    'serie': '1',
    'emitenteCnpj': '11222333000181',
    'emitenteNome': 'DISTRIBUIDORA EXEMPLO LTDA',
    'valorTotal': 72,
    'status': status,
    'totalPendentes': pendentes,
    'totalAvisos': 0,
    'podeConfirmar': status == 'VALIDADA' && pendentes == 0,
    'produtosCriados': status == 'CONCLUIDA' ? 1 : 0,
    'entradasLancadas': status == 'CONCLUIDA' ? 1 : 0,
    'itens': itens,
  });
}

class _FakeRepository extends NotaFiscalEntradaRepository {
  _FakeRepository() : super(client: ApiClient());
  final ajustes = <Map<String, Object?>>[];
  var confirmou = false;

  @override
  Future<ChaveAcessoNfe> consultarChave(String chave) async =>
      ChaveAcessoNfe.fromJson({
        'chave': chave,
        'emitenteCnpj': '11222333000181',
        'serie': '1',
        'numero': '1234',
        'sefazDisponivel': false,
        'mensagem': 'Envie o XML desta NF-e para ver os itens',
        'notaId': 'nota-1',
        'status': 'VALIDADA',
      });

  @override
  Future<NotaFiscalEntrada> buscar(String id) async =>
      _nota(itens: [_item(1, unidade: 'CX')]);

  @override
  Future<NotaFiscalEntrada> enviarXml(Uint8List bytes, String fileName) =>
      buscar('nota-1');

  @override
  Future<NotaFiscalEntrada> ajustarItem(
    String notaId,
    String itemId, {
    String? acao,
    String? produtoId,
    String? nomeProduto,
    num? precoVenda,
    String? categoria,
    num? fatorConversao,
  }) async {
    ajustes.add({'preco': precoVenda, 'fator': fatorConversao, 'acao': acao});
    return _nota(
      itens: [
        _item(
          1,
          status: 'PRONTO',
          preco: precoVenda,
          unidade: 'CX',
          fator: fatorConversao ?? 1,
        ),
      ],
    );
  }

  @override
  Future<NotaFiscalEntrada> confirmar(String id) async {
    confirmou = true;
    return _nota(
      status: 'CONCLUIDA',
      itens: [
        _item(1, status: 'IMPORTADO', preco: 5.5, unidade: 'CX', fator: 12),
      ],
    );
  }
}

void main() {
  testWidgets('consulta a chave, ajusta o item e confirma a entrada', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repository = _FakeRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: NotaFiscalEntradaPage(
          repository: repository,
          produtos: () async => const [],
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), _chave);
    await tester.tap(find.text('Consultar chave'));
    await tester.pumpAndSettle();
    expect(find.text('NF-e nº 1234 · série 1'), findsOneWidget);

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.text('DISTRIBUIDORA EXEMPLO LTDA'), findsOneWidget);
    expect(find.text('1 pendentes'), findsOneWidget);
    final confirmar = find.widgetWithText(
      FilledButton,
      'Confirmar entrada (1 itens)',
    );
    expect(tester.widget<FilledButton>(confirmar).onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('nfe-item-1')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Preço de venda'),
      '5,50',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Unidades por CX'),
      '12',
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('entram 24 UN no estoque'), findsOneWidget);
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(repository.ajustes.single['preco'], 5.5);
    expect(repository.ajustes.single['fator'], 12);
    expect(find.textContaining('2 CX × 12 = 24 UN'), findsOneWidget);

    await tester.tap(confirmar);
    await tester.pumpAndSettle();
    expect(repository.confirmou, isTrue);
    expect(
      find.textContaining('Entrada lançada no estoque central'),
      findsOneWidget,
    );
  });
}
