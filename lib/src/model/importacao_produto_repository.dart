import 'dart:typed_data';

import 'api_client.dart';
import 'importacao_produto.dart';

class ImportacaoProdutoRepository {
  ImportacaoProdutoRepository({ApiClient? client})
    : client = client ?? ApiClient.instance;
  final ApiClient client;

  Future<Uint8List> baixarModelo() =>
      client.download('/produtos/importacao/modelo');

  Future<ImportacaoProduto> validar(Uint8List bytes, String fileName) async =>
      ImportacaoProduto.fromJson(
        Map<String, dynamic>.from(
          await client.multipart(
                'POST',
                '/produtos/importacao/validar',
                fields: const {},
                fileBytes: bytes,
                fileName: fileName,
              )
              as Map,
        ),
      );

  Future<ImportacaoProduto> buscar(String id) async =>
      ImportacaoProduto.fromJson(
        Map<String, dynamic>.from(
          await client.get('/produtos/importacao/$id') as Map,
        ),
      );

  Future<ImportacaoProduto> confirmar(String id) async =>
      ImportacaoProduto.fromJson(
        Map<String, dynamic>.from(
          await client.post('/produtos/importacao/$id/confirmar', {}) as Map,
        ),
      );

  Future<ImportacaoProduto> erros(String id) async =>
      ImportacaoProduto.fromJson(
        Map<String, dynamic>.from(
          await client.get('/produtos/importacao/$id/erros') as Map,
        ),
      );
}
