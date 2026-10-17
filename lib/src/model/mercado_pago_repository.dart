import 'api_client.dart';

class MercadoPagoSetup {
  const MercadoPagoSetup({
    required this.contaVinculada,
    required this.maquininhaVinculada,
    required this.configuracaoCompleta,
    required this.quantidadeTerminais,
    required this.quantidadeMaquininhasVinculadas,
    this.dataVinculacao,
  });

  final bool contaVinculada;
  final bool maquininhaVinculada;
  final bool configuracaoCompleta;
  final int quantidadeTerminais;
  final int quantidadeMaquininhasVinculadas;
  final DateTime? dataVinculacao;

  factory MercadoPagoSetup.fromJson(
    Map<String, dynamic> json,
  ) => MercadoPagoSetup(
    contaVinculada: json['contaVinculada'] == true,
    maquininhaVinculada: json['maquininhaVinculada'] == true,
    configuracaoCompleta: json['configuracaoCompleta'] == true,
    quantidadeTerminais: (json['quantidadeTerminais'] as num?)?.toInt() ?? 0,
    quantidadeMaquininhasVinculadas:
        (json['quantidadeMaquininhasVinculadas'] as num?)?.toInt() ?? 0,
    dataVinculacao: DateTime.tryParse(json['dataVinculacao']?.toString() ?? ''),
  );
}

class MercadoPagoPoint {
  const MercadoPagoPoint({
    required this.id,
    this.posId,
    this.store,
    this.externalPosId,
    this.operationMode,
    required this.vinculado,
    this.terminalInternoId,
  });

  final String id;
  final String? posId;
  final String? store;
  final String? externalPosId;
  final String? operationMode;
  final bool vinculado;
  final String? terminalInternoId;

  factory MercadoPagoPoint.fromJson(Map<String, dynamic> json) =>
      MercadoPagoPoint(
        id: json['id']?.toString() ?? '',
        posId: json['posId']?.toString(),
        store: json['store']?.toString(),
        externalPosId: json['externalPosId']?.toString(),
        operationMode: json['operationMode']?.toString(),
        vinculado: json['vinculado'] == true,
        terminalInternoId: json['terminalInternoId']?.toString(),
      );
}

class MercadoPagoRepository {
  MercadoPagoRepository({ApiClient? client})
    : client = client ?? ApiClient.instance;
  final ApiClient client;

  Future<MercadoPagoSetup> status() async => MercadoPagoSetup.fromJson(
    Map<String, dynamic>.from(await client.get('/mercado-pago/status') as Map),
  );

  Future<List<MercadoPagoPoint>> points() async =>
      ((await client.get('/mercado-pago/terminais')) as List)
          .whereType<Map>()
          .map(
            (value) =>
                MercadoPagoPoint.fromJson(Map<String, dynamic>.from(value)),
          )
          .toList();

  Future<Uri> oauthUrl() => client.authenticatedRedirect('/mercado-pago/oauth');

  Future<void> vincular(String terminalId, String pointId) => client.put(
    '/terminais/$terminalId/mercado-pago',
    {'mercadoPagoTerminalId': pointId},
  );

  Future<void> desvincular(String terminalId) =>
      client.delete('/terminais/$terminalId/mercado-pago');
}
