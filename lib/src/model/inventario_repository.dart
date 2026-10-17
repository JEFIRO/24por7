import 'api_client.dart';
import 'decimal_value.dart';
import 'inventario.dart';

class InventarioRepository {
  InventarioRepository({ApiClient? client})
    : client = client ?? ApiClient.instance;
  final ApiClient client;

  Future<List<Inventario>> listar({String? status}) async {
    final data = await client.get(
      '/inventarios',
      query: {
        'page': '0',
        'size': '100',
        'sort': 'createdAt,desc',
        'status': status,
      },
    );
    return ((data as Map)['content'] as List)
        .whereType<Map>()
        .map((e) => Inventario.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Inventario> buscar(String id) async => Inventario.fromJson(
    Map<String, dynamic>.from(await client.get('/inventarios/$id') as Map),
  );

  Future<Inventario> iniciar({
    bool contagemCega = false,
    String? descricao,
  }) async => Inventario.fromJson(
    Map<String, dynamic>.from(
      await client.post('/inventarios', {
            'localTipo': 'ESTOQUE_EMPRESA',
            'descricao': descricao,
            'contagemCega': contagemCega,
          })
          as Map,
    ),
  );

  Future<Inventario> contar(
    String inventarioId,
    String itemId,
    DecimalValue quantidade,
    String motivo,
  ) async => Inventario.fromJson(
    Map<String, dynamic>.from(
      await client.put('/inventarios/$inventarioId/itens/$itemId/contagem', {
            'quantidadeContada': quantidade.fixedScale(3),
            'motivoAjuste': motivo,
          })
          as Map,
    ),
  );

  Future<Inventario> finalizar(String id) async => Inventario.fromJson(
    Map<String, dynamic>.from(
      await client.post('/inventarios/$id/finalizar', {}) as Map,
    ),
  );

  Future<Inventario> cancelar(String id) async => Inventario.fromJson(
    Map<String, dynamic>.from(
      await client.post('/inventarios/$id/cancelar', {}) as Map,
    ),
  );
}
