import 'api_client.dart';

class AddressAdmin {
  const AddressAdmin({
    this.rua,
    this.numero,
    this.complemento,
    this.bairro,
    this.cidade,
    this.estado,
    this.cep,
  });
  final String? rua;
  final String? numero;
  final String? complemento;
  final String? bairro;
  final String? cidade;
  final String? estado;
  final String? cep;

  factory AddressAdmin.fromJson(Map<String, dynamic> json) => AddressAdmin(
    rua: json['rua']?.toString(),
    numero: json['numero']?.toString(),
    complemento: json['complemento']?.toString(),
    bairro: json['bairro']?.toString(),
    cidade: json['cidade']?.toString(),
    estado: json['estado']?.toString(),
    cep: json['cep']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'rua': rua,
    'numero': numero,
    'complemento': complemento,
    'bairro': bairro,
    'cidade': cidade,
    'estado': estado,
    'cep': cep,
  };
}

class CondominioAdmin {
  final String id;
  final String nome;
  final String? cnpj;
  final bool ativo;
  final AddressAdmin? endereco;
  const CondominioAdmin({
    required this.id,
    required this.nome,
    this.cnpj,
    required this.ativo,
    this.endereco,
  });
  factory CondominioAdmin.fromJson(Map<String, dynamic> json) =>
      CondominioAdmin(
        id: json['idCondominio']?.toString() ?? '',
        nome: json['nome']?.toString() ?? 'Condomínio',
        cnpj: json['cnpj']?.toString(),
        ativo: json['ativo'] != false,
        endereco: json['endereco'] is Map
            ? AddressAdmin.fromJson(
                Map<String, dynamic>.from(json['endereco'] as Map),
              )
            : null,
      );
}

class TerminalAdmin {
  final String id;
  final String nome;
  final String codigo;
  final String condominioId;
  final bool ativo;
  final String status;
  final String? mercadoPagoTerminalId;
  final DateTime? lastPing;
  final String? serialNumber;
  final String? macAddress;
  final String? ipAddress;
  final String? versaoSoftware;
  const TerminalAdmin({
    required this.id,
    required this.nome,
    required this.codigo,
    required this.condominioId,
    required this.ativo,
    required this.status,
    this.mercadoPagoTerminalId,
    this.lastPing,
    this.serialNumber,
    this.macAddress,
    this.ipAddress,
    this.versaoSoftware,
  });
  factory TerminalAdmin.fromJson(Map<String, dynamic> json) => TerminalAdmin(
    id: json['id']?.toString() ?? '',
    nome: json['nome']?.toString() ?? 'Terminal',
    codigo: json['codigo']?.toString() ?? '',
    condominioId: json['condominioId']?.toString() ?? '',
    ativo: json['ativo'] != false,
    status: json['status']?.toString() ?? 'OFFLINE',
    mercadoPagoTerminalId: json['mercadoPagoTerminalId']?.toString(),
    lastPing: DateTime.tryParse(json['lastPing']?.toString() ?? ''),
    serialNumber: json['serialNumber']?.toString(),
    macAddress: json['macAddress']?.toString(),
    ipAddress: json['ipAddress']?.toString(),
    versaoSoftware: json['versaoSoftware']?.toString(),
  );
}

class OperationalRepository {
  OperationalRepository({ApiClient? client})
    : client = client ?? ApiClient.instance;
  final ApiClient client;

  Future<List<CondominioAdmin>> condominios() async =>
      ((await client.get('/condominios')) as List)
          .whereType<Map>()
          .map(
            (item) => CondominioAdmin.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();

  Future<List<TerminalAdmin>> terminais({String? condominioId}) async {
    final response = condominioId == null
        ? await client.get('/terminais')
        : await client.get('/condominios/$condominioId/terminais');
    return (response as List)
        .whereType<Map>()
        .map((item) => TerminalAdmin.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<CondominioAdmin> salvarCondominio({
    String? id,
    required String nome,
    String? cnpj,
    required AddressAdmin endereco,
  }) async {
    final body = {'nome': nome, 'cnpj': cnpj, 'endereco': endereco.toJson()};
    final response = id == null
        ? await client.post('/condominios', body)
        : await client.put('/condominios/$id', body);
    return CondominioAdmin.fromJson(Map<String, dynamic>.from(response as Map));
  }

  Future<CondominioAdmin> desativarCondominio(String id) async =>
      CondominioAdmin.fromJson(
        Map<String, dynamic>.from(
          await client.delete('/condominios/$id') as Map,
        ),
      );

  Future<TerminalAdmin> salvarTerminal({
    String? id,
    required String condominioId,
    required String nome,
    String? serialNumber,
    String? macAddress,
    String? ipAddress,
  }) async {
    final body = {
      'nome': nome,
      'serialNumber': serialNumber,
      'macAddress': macAddress,
      'ipAddress': ipAddress,
    };
    final response = id == null
        ? await client.post('/condominios/$condominioId/terminais', body)
        : await client.put('/terminais/$id', body);
    return TerminalAdmin.fromJson(Map<String, dynamic>.from(response as Map));
  }

  Future<Map<String, dynamic>> onboarding(Map<String, dynamic> payload) async =>
      Map<String, dynamic>.from(
        await client.post('/onboarding', payload, authenticated: false) as Map,
      );
}
