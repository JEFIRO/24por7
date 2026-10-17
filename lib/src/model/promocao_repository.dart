import 'api_client.dart';
import 'promocao.dart';

class PromocaoRepository {
  PromocaoRepository({ApiClient? client})
    : client = client ?? ApiClient.instance;
  final ApiClient client;

  Future<List<Promocao>> listar({
    AbrangenciaPromocao? abrangencia,
    StatusPromocao? status,
    String? condominioId,
    String? produtoId,
  }) async {
    final data = await client.get(
      '/promocoes',
      query: {
        'abrangencia': abrangencia?.apiName,
        'status': status?.apiName,
        'condominioId': condominioId,
        'produtoId': produtoId,
      },
    );
    return (data as List)
        .map((e) => Promocao.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Promocao> buscar(String id) async => Promocao.fromJson(
    await client.get('/promocoes/$id') as Map<String, dynamic>,
  );
  Future<Promocao> salvar(PromocaoDraft draft, {String? id}) async =>
      Promocao.fromJson(
        (id == null
                ? await client.post('/promocoes', draft.toJson())
                : await client.put('/promocoes/$id', draft.toJson()))
            as Map<String, dynamic>,
      );
  Future<Promocao> alterarStatus(String id, bool ativo) async =>
      Promocao.fromJson(
        await client.patch('/promocoes/$id/status', {'ativo': ativo})
            as Map<String, dynamic>,
      );
  Future<List<CondominioResumo>> condominios() async =>
      ((await client.get('/condominios')) as List)
          .map((e) => CondominioResumo.fromJson(e as Map<String, dynamic>))
          .where((e) => e.ativo)
          .toList();
  Future<List<ProdutoResumo>> produtos({String? condominioId}) async {
    final page = await client.get(
      '/produtos',
      query: const {'page': '0', 'size': '1000'},
    );
    final all = ((page as Map<String, dynamic>)['content'] as List)
        .map((e) => ProdutoResumo.fromJson(e as Map<String, dynamic>))
        .toList();
    if (condominioId == null) return all;
    final stock =
        (await client.get('/condominios/$condominioId/estoque')) as List;
    final available = stock
        .where((e) => e['ativo'] == true)
        .map((e) => e['produtoId'].toString())
        .toSet();
    return all.where((e) => available.contains(e.id)).toList();
  }
}
