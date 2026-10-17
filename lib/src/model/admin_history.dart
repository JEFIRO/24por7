import 'decimal_value.dart';

class AdminPage<T> {
  const AdminPage({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.totalElements,
  });
  final List<T> items;
  final int page;
  final int totalPages;
  final int totalElements;

  factory AdminPage.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) decode,
  ) {
    final pageData = json['page'] is Map
        ? Map<String, dynamic>.from(json['page'] as Map)
        : json;
    final items = (json['content'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => decode(Map<String, dynamic>.from(item)))
        .toList();
    return AdminPage(
      items: items,
      page:
          (json['number'] as num?)?.toInt() ??
          (pageData['number'] as num?)?.toInt() ??
          0,
      totalPages:
          (json['totalPages'] as num?)?.toInt() ??
          (pageData['totalPages'] as num?)?.toInt() ??
          1,
      totalElements:
          (json['totalElements'] as num?)?.toInt() ??
          (pageData['totalElements'] as num?)?.toInt() ??
          items.length,
    );
  }
}

class AdminSale {
  const AdminSale({
    required this.id,
    required this.status,
    required this.total,
    required this.criadaEm,
    required this.pagaEm,
    required this.condominioNome,
    required this.terminalNome,
  });
  final String id;
  final String status;
  final DecimalValue total;
  final DateTime? criadaEm;
  final DateTime? pagaEm;
  final String condominioNome;
  final String terminalNome;
  factory AdminSale.fromJson(Map<String, dynamic> json) => AdminSale(
    id: json['id']?.toString() ?? '',
    status: json['status']?.toString() ?? 'UNKNOWN',
    total: DecimalValue.fromJson(json['total']),
    criadaEm: DateTime.tryParse(json['criadaEm']?.toString() ?? ''),
    pagaEm: DateTime.tryParse(json['pagaEm']?.toString() ?? ''),
    condominioNome: json['condominioNome']?.toString() ?? 'Condomínio',
    terminalNome: json['terminalNome']?.toString() ?? 'Terminal',
  );
}

class AdminPayment {
  const AdminPayment({
    required this.id,
    required this.orderId,
    required this.status,
    required this.provider,
    required this.valor,
    required this.atualizadaEm,
    required this.terminalNome,
  });
  final String id;
  final String orderId;
  final String status;
  final String provider;
  final DecimalValue valor;
  final DateTime? atualizadaEm;
  final String terminalNome;
  factory AdminPayment.fromJson(Map<String, dynamic> json) => AdminPayment(
    id: json['id']?.toString() ?? '',
    orderId: json['orderId']?.toString() ?? '',
    status: json['status']?.toString() ?? 'UNKNOWN',
    provider: json['provider']?.toString() ?? 'UNKNOWN',
    valor: DecimalValue.fromJson(json['valor']),
    atualizadaEm: DateTime.tryParse(json['atualizadaEm']?.toString() ?? ''),
    terminalNome: json['terminalNome']?.toString() ?? 'Terminal',
  );
}

class AdminAlert {
  const AdminAlert({
    required this.id,
    required this.terminalNome,
    required this.condominioNome,
    required this.tipo,
    required this.status,
    required this.severidade,
    required this.mensagem,
    required this.ultimaOcorrenciaEm,
  });
  final String id;
  final String terminalNome;
  final String condominioNome;
  final String tipo;
  final String status;
  final String severidade;
  final String mensagem;
  final DateTime? ultimaOcorrenciaEm;
  factory AdminAlert.fromJson(Map<String, dynamic> json) => AdminAlert(
    id: json['id']?.toString() ?? '',
    terminalNome: json['terminalNome']?.toString() ?? 'Terminal',
    condominioNome: json['condominioNome']?.toString() ?? 'Condomínio',
    tipo: json['tipo']?.toString() ?? 'ALERTA',
    status: json['status']?.toString() ?? 'ACTIVE',
    severidade: json['severidade']?.toString() ?? 'WARNING',
    mensagem: json['mensagem']?.toString() ?? 'Ocorrência operacional',
    ultimaOcorrenciaEm: DateTime.tryParse(
      json['ultimaOcorrenciaEm']?.toString() ?? '',
    ),
  );
}
