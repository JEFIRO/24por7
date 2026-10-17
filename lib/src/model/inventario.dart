import 'decimal_value.dart';

class Inventario {
  const Inventario({
    required this.id,
    required this.localTipo,
    required this.localId,
    required this.localNome,
    required this.status,
    required this.descricao,
    required this.contagemCega,
    required this.totalProdutos,
    required this.contados,
    required this.pendentes,
    required this.divergencias,
    required this.conflitos,
    required this.progressoPercentual,
    required this.itens,
    this.createdAt,
    this.finalizedAt,
  });

  final String id;
  final String localTipo;
  final String localId;
  final String localNome;
  final String status;
  final String? descricao;
  final bool contagemCega;
  final int totalProdutos;
  final int contados;
  final int pendentes;
  final int divergencias;
  final int conflitos;
  final String progressoPercentual;
  final List<InventarioItem> itens;
  final DateTime? createdAt;
  final DateTime? finalizedAt;

  factory Inventario.fromJson(Map<String, dynamic> json) => Inventario(
    id: json['id'].toString(),
    localTipo: json['localTipo'].toString(),
    localId: json['localId'].toString(),
    localNome: json['localNome']?.toString() ?? 'Estoque',
    status: json['status'].toString(),
    descricao: json['descricao']?.toString(),
    contagemCega: json['contagemCega'] == true,
    totalProdutos: (json['totalProdutos'] as num?)?.toInt() ?? 0,
    contados: (json['contados'] as num?)?.toInt() ?? 0,
    pendentes: (json['pendentes'] as num?)?.toInt() ?? 0,
    divergencias: (json['divergencias'] as num?)?.toInt() ?? 0,
    conflitos: (json['conflitos'] as num?)?.toInt() ?? 0,
    progressoPercentual: json['progressoPercentual']?.toString() ?? '0',
    itens: ((json['itens'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => InventarioItem.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
    createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    finalizedAt: DateTime.tryParse(json['finalizedAt']?.toString() ?? ''),
  );
}

class InventarioItem {
  const InventarioItem({
    required this.id,
    required this.produtoId,
    required this.codigoInterno,
    required this.codigosBarras,
    required this.nome,
    required this.unidadeMedida,
    required this.status,
    required this.ajusteAplicado,
    this.codigoBarras,
    this.localizacaoPlanograma,
    this.saldoSistemaSnapshot,
    this.quantidadeContada,
    this.diferenca,
    this.saldoAtualConflito,
    this.motivoAjuste,
  });
  final String id;
  final String produtoId;
  final String codigoInterno;
  final String? codigoBarras;
  final List<String> codigosBarras;
  final String nome;
  final String unidadeMedida;
  final String? localizacaoPlanograma;
  final DecimalValue? saldoSistemaSnapshot;
  final DecimalValue? quantidadeContada;
  final DecimalValue? diferenca;
  final DecimalValue? saldoAtualConflito;
  final String status;
  final bool ajusteAplicado;
  final String? motivoAjuste;

  factory InventarioItem.fromJson(Map<String, dynamic> json) => InventarioItem(
    id: json['id'].toString(),
    produtoId: json['produtoId'].toString(),
    codigoInterno: json['codigoInterno']?.toString() ?? '',
    codigoBarras: json['codigoBarras']?.toString(),
    codigosBarras: ((json['codigosBarras'] as List?) ?? const [])
        .map((value) => value.toString())
        .toList(),
    nome: json['nome']?.toString() ?? '',
    unidadeMedida: json['unidadeMedida']?.toString() ?? 'UN',
    localizacaoPlanograma: json['localizacaoPlanograma']?.toString(),
    saldoSistemaSnapshot: _decimal(json['saldoSistemaSnapshot']),
    quantidadeContada: _decimal(json['quantidadeContada']),
    diferenca: _decimal(json['diferenca']),
    saldoAtualConflito: _decimal(json['saldoAtualConflito']),
    status: json['status']?.toString() ?? 'PENDENTE',
    ajusteAplicado: json['ajusteAplicado'] == true,
    motivoAjuste: json['motivoAjuste']?.toString(),
  );

  static DecimalValue? _decimal(dynamic value) =>
      value == null ? null : DecimalValue.parse(value.toString(), maxScale: 3);
}
