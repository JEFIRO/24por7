import 'package:app_24por7/src/model/importacao_produto.dart';
import 'package:app_24por7/src/model/inventario.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('inventário preserva contagem fracionada e conflito', () {
    final inventario = Inventario.fromJson({
      'id': 'inv-1',
      'localTipo': 'ESTOQUE_EMPRESA',
      'localId': 'empresa-1',
      'localNome': 'Estoque Central',
      'status': 'COM_CONFLITO',
      'contagemCega': true,
      'totalProdutos': 1,
      'contados': 1,
      'pendentes': 0,
      'divergencias': 1,
      'conflitos': 1,
      'progressoPercentual': '100.0',
      'itens': [
        {
          'id': 'item-1',
          'produtoId': 'produto-1',
          'codigoInterno': 'COCA2L',
          'codigoBarras': '7894900011517',
          'codigosBarras': ['7894900011517', '7894900011524'],
          'nome': 'Coca-Cola 2L',
          'unidadeMedida': 'UN',
          'localizacaoPlanograma': 'A-02-03-01',
          'saldoSistemaSnapshot': '100.000',
          'quantidadeContada': '97.350',
          'diferenca': '-2.650',
          'saldoAtualConflito': '120.000',
          'status': 'CONFLITO',
          'ajusteAplicado': false,
        },
      ],
    });

    expect(inventario.status, 'COM_CONFLITO');
    expect(inventario.itens.single.quantidadeContada!.fixedScale(3), '97.350');
    expect(inventario.itens.single.diferenca!.fixedScale(3), '-2.650');
    expect(inventario.itens.single.localizacaoPlanograma, 'A-02-03-01');
    expect(inventario.itens.single.codigosBarras, hasLength(2));
  });

  test('preview só permite confirmar validação sem erros', () {
    final validada = ImportacaoProduto.fromJson({
      'importacaoId': 'import-1',
      'nomeArquivo': 'produtos.xlsx',
      'status': 'VALIDADA',
      'totalLinhas': 3,
      'totalValidas': 1,
      'totalAvisos': 0,
      'totalErros': 0,
      'produtosImportados': 0,
      'barcodesImportados': 0,
      'estoquesCriados': 0,
      'preview': [
        {
          'aba': 'PRODUTOS',
          'linha': 2,
          'codigoInterno': 'COCA2L',
          'status': 'VALIDO',
          'mensagem': 'OK',
        },
      ],
    });
    expect(validada.podeConfirmar, isTrue);
    expect(validada.preview.single.codigoInterno, 'COCA2L');

    final comErro = ImportacaoProduto.fromJson({
      'importacaoId': 'import-2',
      'status': 'VALIDADA_COM_ERROS',
      'totalErros': 1,
    });
    expect(comErro.podeConfirmar, isFalse);
    expect(comErro.concluida, isFalse);
  });
}
