import 'produto.dart';
import 'api_client.dart';
import 'decimal_value.dart';
import 'estoque.dart';
import 'produto_repository.dart';

class EstoqueRepository {
  EstoqueRepository({ApiClient? client})
    : client = client ?? ApiClient.instance;
  final ApiClient client;

  Future<List<EstoqueCentral>> listarCentral({
    String? busca,
    String? categoria,
    bool? ativo,
  }) async {
    final data = await client.get(
      '/estoque-empresa',
      query: {
        'page': '0',
        'size': '100',
        'sort': 'produto.nome,asc',
        'busca': busca,
        'categoria': categoria,
        'ativo': ativo?.toString(),
      },
    );
    return ((data as Map)['content'] as List)
        .whereType<Map>()
        .map((e) => EstoqueCentral.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<Produto>> listarProdutos() async {
    final data = await client.get(
      '/estoque-empresa/produtos',
      query: {'page': '0', 'size': '100', 'sort': 'nome,asc'},
    );
    return ((data as Map)['content'] as List)
        .whereType<Map>()
        .map((e) => Produto.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<EstoqueCentral> movimentar(
    String produtoId,
    String operacao,
    DecimalValue quantidade,
    String motivo,
  ) async {
    final path = operacao == 'AJUSTE'
        ? '/estoque-empresa/$produtoId'
        : '/estoque-empresa/$produtoId/${operacao.toLowerCase()}';
    final data = operacao == 'AJUSTE'
        ? await client.put(path, {
            'quantidade': quantidade.fixedScale(3),
            'motivo': motivo,
          })
        : await client.post(path, {
            'quantidade': quantidade.fixedScale(3),
            'motivo': motivo,
          });
    return EstoqueCentral.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<List<MovimentoEstoque>> movimentos() async =>
      ((await client.get('/estoque-empresa/movimentacoes')) as List)
          .whereType<Map>()
          .map((e) => MovimentoEstoque.fromJson(Map<String, dynamic>.from(e)))
          .toList();

  Future<List<CondominioOption>> condominios() async =>
      ProdutoRepository(client: client).listarCondominios();

  Future<List<TransferenciaEstoque>> transferencias({String? status}) async {
    final data = await client.get(
      '/transferencias-estoque',
      query: {
        'page': '0',
        'size': '100',
        'sort': 'createdAt,desc',
        'status': status,
      },
    );
    return ((data as Map)['content'] as List)
        .whereType<Map>()
        .map((e) => TransferenciaEstoque.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<TransferenciaEstoque> criarTransferencia(
    String condominioId,
    String observacao,
    List<TransferenciaItem> itens,
  ) async {
    final data = await client.post('/transferencias-estoque', {
      'condominioDestinoId': condominioId,
      'observacao': observacao,
      'itens': itens
          .map(
            (e) => {
              'produtoId': e.produtoId,
              'quantidade': e.quantidade.fixedScale(3),
            },
          )
          .toList(),
    });
    return TransferenciaEstoque.fromJson(
      Map<String, dynamic>.from(data as Map),
    );
  }

  Future<TransferenciaEstoque> transferencia(String id) async =>
      TransferenciaEstoque.fromJson(
        Map<String, dynamic>.from(
          await client.get('/transferencias-estoque/$id') as Map,
        ),
      );
  Future<TransferenciaEstoque> confirmar(String id) async =>
      TransferenciaEstoque.fromJson(
        Map<String, dynamic>.from(
          await client.post('/transferencias-estoque/$id/confirmar', {}) as Map,
        ),
      );
  Future<TransferenciaEstoque> cancelar(String id) async =>
      TransferenciaEstoque.fromJson(
        Map<String, dynamic>.from(
          await client.post('/transferencias-estoque/$id/cancelar', {}) as Map,
        ),
      );

  Future<List<Planograma>> planogramas() async =>
      ((await client.get('/planogramas')) as List)
          .whereType<Map>()
          .map((e) => Planograma.fromJson(Map<String, dynamic>.from(e)))
          .toList();
  Future<Planograma> criarPlanograma(String nome, String descricao) async =>
      Planograma.fromJson(
        Map<String, dynamic>.from(
          await client.post('/planogramas', {
                'nome': nome,
                'descricao': descricao,
                'ativo': true,
              })
              as Map,
        ),
      );
  Future<Planograma> adicionarPosicao(
    String id,
    Map<String, dynamic> data,
  ) async => Planograma.fromJson(
    Map<String, dynamic>.from(
      await client.post('/planogramas/$id/posicoes', data) as Map,
    ),
  );
  Future<Planograma> adicionarProduto(
    String posicaoId,
    String produtoId,
  ) async => Planograma.fromJson(
    Map<String, dynamic>.from(
      await client.post('/planogramas/posicoes/$posicaoId/produtos', {
            'produtoId': produtoId,
            'facings': 1,
            'ativo': true,
          })
          as Map,
    ),
  );
  Future<Planograma> removerProduto(String vinculoId) async =>
      Planograma.fromJson(
        Map<String, dynamic>.from(
          await client.delete('/planogramas/produtos/$vinculoId') as Map,
        ),
      );
}
