import 'produto.dart';
import 'api_client.dart';
import 'decimal_value.dart';
import 'dart:typed_data';

class CondominioOption {
  final String id;
  final String nome;
  final bool ativo;

  const CondominioOption({
    required this.id,
    required this.nome,
    required this.ativo,
  });

  factory CondominioOption.fromJson(Map<String, dynamic> json) =>
      CondominioOption(
        id: json['idCondominio']?.toString() ?? json['id']?.toString() ?? '',
        nome: json['nome']?.toString() ?? 'Condomínio',
        ativo: json['ativo'] != false,
      );
}

class ProdutoCondominioDisponibilidade {
  const ProdutoCondominioDisponibilidade({
    required this.condominioId,
    required this.condominioNome,
    required this.associado,
    this.quantidade,
  });
  final String condominioId;
  final String condominioNome;
  final bool associado;
  final DecimalValue? quantidade;

  factory ProdutoCondominioDisponibilidade.fromJson(
    Map<String, dynamic> json,
  ) => ProdutoCondominioDisponibilidade(
    condominioId: json['condominioId']?.toString() ?? '',
    condominioNome: json['condominioNome']?.toString() ?? 'Condomínio',
    associado: json['associado'] == true,
    quantidade: json['quantidade'] == null
        ? null
        : DecimalValue.fromJson(json['quantidade']),
  );
}

class ProdutoRepository {
  ProdutoRepository({ApiClient? client})
    : client = client ?? ApiClient.instance;
  final ApiClient client;

  Future<List<Produto>> listar({int page = 0, int size = 100}) async {
    return (await listarPagina(page: page, size: size)).items;
  }

  Future<ProdutoPage> listarPagina({int page = 0, int size = 25}) async {
    final response = await client.get(
      '/produtos',
      query: {'page': '$page', 'size': '$size', 'sort': 'nome,asc'},
    );
    final content = response is Map ? response['content'] : null;
    if (content is! List) {
      throw const ApiException('Lista de produtos inválida');
    }
    final items = content
        .whereType<Map>()
        .map((item) => Produto.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    return ProdutoPage(
      items: items,
      page: (response['page'] as num?)?.toInt() ?? page,
      totalPages: (response['totalPages'] as num?)?.toInt() ?? 1,
      totalElements:
          (response['totalElements'] as num?)?.toInt() ?? items.length,
    );
  }

  Future<Produto> buscarPorCodigo(String codigo) async => Produto.fromJson(
    Map<String, dynamic>.from(await client.get('/produtos/$codigo') as Map),
  );

  Future<Produto> buscarPorId(String id) async => Produto.fromJson(
    Map<String, dynamic>.from(
      await client.get('/produtos/id', query: {'id': id}) as Map,
    ),
  );

  Future<Produto> salvar(
    Produto produto, {
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    final response = imageBytes == null
        ? produto.id == null
              ? await client.post('/produtos', produto.toRequestJson())
              : await client.put(
                  '/produtos/${produto.id}',
                  produto.toRequestJson(),
                )
        : await client.multipartJson(
            produto.id == null ? 'POST' : 'PUT',
            produto.id == null ? '/produtos' : '/produtos/${produto.id}',
            data: produto.toRequestJson(),
            fileBytes: imageBytes,
            fileName: imageName,
          );
    return Produto.fromJson(Map<String, dynamic>.from(response as Map));
  }

  Future<void> registrarEstoqueInicial({
    required String produtoId,
    required DecimalValue quantidade,
    required String motivo,
  }) async {
    await client.post('/estoque-empresa/$produtoId/entrada', {
      'quantidade': quantidade.fixedScale(3),
      'motivo': motivo,
    });
  }

  Future<List<ProdutoCondominioDisponibilidade>> disponibilidadeCondominios(
    String produtoId,
  ) async =>
      ((await client.get('/produtos/$produtoId/disponibilidade-condominios'))
              as List)
          .whereType<Map>()
          .map(
            (item) => ProdutoCondominioDisponibilidade.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();

  Future<List<CondominioOption>> listarCondominios() async =>
      ((await client.get('/condominios')) as List)
          .whereType<Map>()
          .map(
            (item) =>
                CondominioOption.fromJson(Map<String, dynamic>.from(item)),
          )
          .where((item) => item.ativo)
          .toList();

  Future<void> associarAoCondominio({
    required String produtoId,
    required String condominioId,
    required DecimalValue quantidade,
    bool ativo = true,
  }) async {
    await client.post('/condominios/$condominioId/estoque', {
      'produtoId': produtoId,
      'quantidade': quantidade.fixedScale(3),
      'ativo': ativo,
    });
  }

  Future<void> desassociarDoCondominio({
    required String produtoId,
    required String condominioId,
  }) async {
    await client.delete('/condominios/$condominioId/estoque/$produtoId');
  }
}

class ProdutoPage {
  const ProdutoPage({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.totalElements,
  });
  final List<Produto> items;
  final int page;
  final int totalPages;
  final int totalElements;
}
