import 'package:flutter_test/flutter_test.dart';
import 'package:app_24por7/src/model/estoque.dart';

void main() {
  test('estoque central preserva quantidade decimal exata', () {
    final estoque = EstoqueCentral.fromJson({
      'id': 'stock-1',
      'produtoId': 'product-1',
      'produto': 'Coca-Cola',
      'codigoInterno': '001',
      'codigoBarrasPrincipal': '789123',
      'categoria': 'BEBIDA',
      'unidadeMedida': 'UN',
      'quantidade': '100.350',
      'ativo': true,
      'localizacao': 'A-01-03-02',
      'capacidadePosicao': '24.000',
    });
    expect(estoque.quantidade.fixedScale(3), '100.350');
    expect(estoque.localizacao, 'A-01-03-02');
    expect(estoque.capacidadePosicao!.fixedScale(3), '24.000');
  });

  test('transferencia correlaciona itens e movimentos', () {
    final transferencia = TransferenciaEstoque.fromJson({
      'id': 'transfer-1',
      'destinoId': 'condo-1',
      'destinoNome': 'Residencial Firenze',
      'status': 'CONCLUIDA',
      'createdAt': '2026-08-30T12:00:00Z',
      'itens': [
        {
          'id': 'item-1',
          'produtoId': 'product-1',
          'produto': 'Água',
          'quantidade': '20.000',
        },
      ],
      'movimentacoes': [
        {
          'id': 'movement-1',
          'localTipo': 'ESTOQUE_EMPRESA',
          'produtoId': 'product-1',
          'tipo': 'SAIDA_TRANSFERENCIA',
          'quantidade': '-20.000',
          'quantidadeAnterior': '100.000',
          'quantidadePosterior': '80.000',
          'transferenciaId': 'transfer-1',
          'responsavel': 'Gestor',
          'createdAt': '2026-08-30T12:00:01Z',
        },
      ],
    });
    expect(transferencia.itens.single.quantidade.fixedScale(3), '20.000');
    expect(transferencia.destinoNome, 'Residencial Firenze');
    expect(
      transferencia.movimentacoes.single.quantidade.fixedScale(3),
      '-20.000',
    );
    expect(transferencia.movimentacoes.single.responsavel, 'Gestor');
  });
}
