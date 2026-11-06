import 'admin_history.dart';
import 'produto.dart';
import 'api_client.dart';
import 'decimal_value.dart';
import 'estoque.dart';
import 'produto_repository.dart';

class EstoqueRepository {
  EstoqueRepository({ApiClient? client})
    : client = client ?? ApiClient.instance;
  final ApiClient client;

  Future<AdminPage<EstoqueCentral>> listarCentralPagina({
    int page = 0,
    int size = 50,
    String? busca,
    String? categoria,
    bool? ativo,
  }) async {
    final data = await client.get(
      '/estoque-empresa',
      query: {
        'page': '$page',
        'size': '$size',
        'sort': 'produto.nome,asc',
        'busca': busca,
        'categoria': categoria,
        'ativo': ativo?.toString(),
      },
    );
    return AdminPage.fromJson(
      Map<String, dynamic>.from(data as Map),
      EstoqueCentral.fromJson,
    );
  }

  /// Percorre todas as páginas; use só onde a tela precisa da lista completa.
  Future<List<EstoqueCentral>> listarCentral({
    String? busca,
    String? categoria,
    bool? ativo,
  }) async {
    final items = <EstoqueCentral>[];
    for (var page = 0; ; page++) {
      final result = await listarCentralPagina(
        page: page,
        size: 100,
        busca: busca,
        categoria: categoria,
        ativo: ativo,
      );
      items.addAll(result.items);
      if (result.items.isEmpty || page + 1 >= result.totalPages) return items;
    }
  }

  Future<List<Produto>> listarProdutos() async {
    final items = <Produto>[];
    for (var page = 0; ; page++) {
      final data = await client.get(
        '/estoque-empresa/produtos',
        query: {'page': '$page', 'size': '100', 'sort': 'nome,asc'},
      );
      final result = AdminPage.fromJson(
        Map<String, dynamic>.from(data as Map),
        Produto.fromJson,
      );
      items.addAll(result.items);
      if (result.items.isEmpty || page + 1 >= result.totalPages) return items;
    }
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
