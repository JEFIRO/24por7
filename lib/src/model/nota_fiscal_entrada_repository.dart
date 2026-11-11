import 'dart:typed_data';

import 'api_client.dart';
import 'nota_fiscal_entrada.dart';

class NotaFiscalEntradaRepository {
  NotaFiscalEntradaRepository({ApiClient? client})
    : client = client ?? ApiClient.instance;
  final ApiClient client;

  static const _base = '/estoque-empresa/notas-fiscais';

  Future<ChaveAcessoNfe> consultarChave(String chave) async =>
      ChaveAcessoNfe.fromJson(
        Map<String, dynamic>.from(
          await client.get('$_base/chave/$chave') as Map,
        ),
      );

  Future<NotaFiscalEntrada> importarPorChave(String chave) async =>
      _nota(await client.post('$_base/chave/$chave/importar', {}));

  Future<NotaFiscalEntrada> enviarXml(Uint8List bytes, String fileName) async =>
      _nota(
        await client.multipart(
          'POST',
          '$_base/xml',
          fields: const {},
          fileBytes: bytes,
          fileName: fileName,
        ),
      );

  Future<NotaFiscalEntrada> buscar(String id) async =>
      _nota(await client.get('$_base/$id'));

  Future<NotaFiscalEntrada> ajustarItem(
    String notaId,
    String itemId, {
    String? acao,
    String? produtoId,
    String? nomeProduto,
    num? precoVenda,
    String? categoria,
    num? fatorConversao,
  }) async => _nota(
    await client.put('$_base/$notaId/itens/$itemId', {
      'acao': ?acao,
      'produtoId': ?produtoId,
      'nomeProduto': ?nomeProduto,
      'precoVenda': ?precoVenda,
      'categoria': ?categoria,
      'fatorConversao': ?fatorConversao,
    }),
  );

  Future<NotaFiscalEntrada> confirmar(String id) async =>
      _nota(await client.post('$_base/$id/confirmar', {}));

  NotaFiscalEntrada _nota(Object? json) =>
      NotaFiscalEntrada.fromJson(Map<String, dynamic>.from(json as Map));
}
