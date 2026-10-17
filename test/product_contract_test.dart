import 'dart:convert';

import 'package:app_24por7/src/model/produto.dart';
import 'package:app_24por7/src/model/api_client.dart';
import 'package:app_24por7/src/model/decimal_value.dart';
import 'package:app_24por7/src/model/produto_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('produto separa SKU, múltiplos barcodes e fiscal', () {
    final product = Produto.fromJson({
      'id': 'product-1',
      'codigo': '789123',
      'codigoInterno': '001',
      'codigosBarras': [
        {
          'id': 'b1',
          'codigo': '789123',
          'tipo': 'EAN',
          'principal': true,
          'ativo': true,
        },
        {
          'id': 'b2',
          'codigo': '789999',
          'tipo': 'EAN',
          'principal': false,
          'ativo': true,
        },
      ],
      'nome': 'Coca-Cola',
      'preco': '10.990000',
      'unidadeMedida': 'UN',
      'categoria': 'BEBIDA',
      'ativo': true,
      'fiscal': {'ncm': '22021000', 'unidadeTributavel': 'UN'},
    });

    expect(product.codigoInterno, '001');
    expect(product.codigoBarrasPrincipal, '789123');
    expect(product.codigosBarras.map((item) => item.codigo), [
      '789123',
      '789999',
    ]);
    expect(product.preco.persistence, '10.990000');
    expect(product.fiscal?.ncm, '22021000');

    final request = product.toRequestJson();
    expect(request['codigoInterno'], '001');
    expect((request['codigosBarras'] as List).length, 2);
    expect(request.containsKey('quantidade'), isFalse);
    expect(request['preco'], '10.990000');
    expect(request['categoria'], 'BEBIDA');
    expect(request['unidadeMedida'], 'UN');
  });

  test(
    'associação ao condomínio preserva quantidade negativa fracionada',
    () async {
      late http.Request captured;
      final api = ApiClient(
        baseUrl: 'http://backend',
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response(
            '{}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      )..token = 'token';
      final repository = ProdutoRepository(client: api);

      await repository.associarAoCondominio(
        produtoId: 'product-1',
        condominioId: 'condo-1',
        quantidade: DecimalValue.parse('-0,350'),
      );

      expect(captured.url.path, '/condominios/condo-1/estoque');
      expect(jsonDecode(captured.body), {
        'produtoId': 'product-1',
        'quantidade': '-0.350',
        'ativo': true,
      });
    },
  );

  test('usa nomes reais dos enums do backend', () {
    final request = Produto(
      codigoInterno: 'L-001',
      codigosBarras: const [
        ProdutoCodigoBarras(codigo: '789123', principal: true),
      ],
      nome: 'Bebida por litro',
      preco: DecimalValue.parse('10.990000'),
      unidadeMedida: 'LITRO',
      categoria: 'BEBIDA',
    ).toRequestJson();

    expect(request['unidadeMedida'], 'LITRO');
    expect(request['categoria'], 'BEBIDA');
    expect((request['codigosBarras'] as List).first['ativo'], isTrue);
  });

  test('erro estruturado é traduzido sem analisar texto da exceção', () {
    const error = ApiException(
      'conflito qualquer',
      409,
      'BARCODE_ALREADY_EXISTS',
    );

    expect(
      error.friendlyMessage,
      'Código de barras já está associado a outro produto.',
    );
  });
}
