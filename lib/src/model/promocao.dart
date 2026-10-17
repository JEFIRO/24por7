import '../../core/formatters/app_time.dart';
import 'decimal_value.dart';

enum AbrangenciaPromocao { empresa, condominio }

enum TipoPromocao { percentual, descontoFixo, precoFixo }

enum StatusPromocao { desativada, agendada, ativa, encerrada }

extension PromotionEnumJson on Enum {
  String get apiName => switch (this) {
    AbrangenciaPromocao.empresa => 'EMPRESA',
    AbrangenciaPromocao.condominio => 'CONDOMINIO',
    TipoPromocao.percentual => 'PERCENTUAL',
    TipoPromocao.descontoFixo => 'DESCONTO_FIXO',
    TipoPromocao.precoFixo => 'PRECO_FIXO',
    StatusPromocao.desativada => 'DESATIVADA',
    StatusPromocao.agendada => 'AGENDADA',
    StatusPromocao.ativa => 'ATIVA',
    StatusPromocao.encerrada => 'ENCERRADA',
    _ => name.toUpperCase(),
  };
}

class ProdutoResumo {
  final String id;
  final String codigo;
  final String nome;
  final DecimalValue preco;
  const ProdutoResumo({
    required this.id,
    required this.codigo,
    required this.nome,
    required this.preco,
  });
  factory ProdutoResumo.fromJson(Map<String, dynamic> json) => ProdutoResumo(
    id: json['id'].toString(),
    codigo: json['codigo']?.toString() ?? '',
    nome: json['nome']?.toString() ?? '',
    preco: DecimalValue.fromJson(json['preco']),
  );
}

class CondominioResumo {
  final String id;
  final String nome;
  final bool ativo;
  const CondominioResumo({
    required this.id,
    required this.nome,
    required this.ativo,
  });
  factory CondominioResumo.fromJson(Map<String, dynamic> json) =>
      CondominioResumo(
        id: json['idCondominio'].toString(),
        nome: json['nome'].toString(),
        ativo: json['ativo'] == true,
      );
}

class Promocao {
  final String id;
  final String nome;
  final String? descricao;
  final AbrangenciaPromocao abrangencia;
  final String? condominioId;
  final String? condominioNome;
  final TipoPromocao tipo;
  final DecimalValue valor;
  final DateTime inicio;
  final DateTime fim;
  final bool ativo;
  final StatusPromocao status;
  final int prioridade;
  final List<ProdutoResumo> produtos;
  const Promocao({
    required this.id,
    required this.nome,
    this.descricao,
    required this.abrangencia,
    this.condominioId,
    this.condominioNome,
    required this.tipo,
    required this.valor,
    required this.inicio,
    required this.fim,
    required this.ativo,
    required this.status,
    required this.prioridade,
    required this.produtos,
  });
  factory Promocao.fromJson(Map<String, dynamic> json) => Promocao(
    id: json['id'].toString(),
    nome: json['nome'].toString(),
    descricao: json['descricao']?.toString(),
    abrangencia: json['abrangencia'] == 'CONDOMINIO'
        ? AbrangenciaPromocao.condominio
        : AbrangenciaPromocao.empresa,
    condominioId: json['condominioId']?.toString(),
    condominioNome: json['condominioNome']?.toString(),
    tipo: switch (json['tipo']) {
      'DESCONTO_FIXO' => TipoPromocao.descontoFixo,
      'PRECO_FIXO' => TipoPromocao.precoFixo,
      _ => TipoPromocao.percentual,
    },
    valor: DecimalValue.fromJson(json['valor']),
    inicio: AppTime.inSaoPaulo(DateTime.parse(json['inicio'].toString())),
    fim: AppTime.inSaoPaulo(DateTime.parse(json['fim'].toString())),
    ativo: json['ativo'] == true,
    status: StatusPromocao.values.firstWhere(
      (e) => e.apiName == json['status'],
    ),
    prioridade: (json['prioridade'] as num?)?.toInt() ?? 0,
    produtos: ((json['produtos'] as List?) ?? const [])
        .map((e) => ProdutoResumo.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class PromocaoDraft {
  final String nome;
  final String? descricao;
  final AbrangenciaPromocao abrangencia;
  final String? condominioId;
  final TipoPromocao tipo;
  final DecimalValue valor;
  final DateTime inicio;
  final DateTime fim;
  final bool ativo;
  final int prioridade;
  final Set<String> produtoIds;
  const PromocaoDraft({
    required this.nome,
    this.descricao,
    required this.abrangencia,
    this.condominioId,
    required this.tipo,
    required this.valor,
    required this.inicio,
    required this.fim,
    required this.ativo,
    required this.prioridade,
    required this.produtoIds,
  });
  Map<String, dynamic> toJson() => {
    'nome': nome.trim(),
    'descricao': descricao?.trim(),
    'abrangencia': abrangencia.apiName,
    'condominioId': abrangencia == AbrangenciaPromocao.condominio
        ? condominioId
        : null,
    'tipo': tipo.apiName,
    'valor': valor.persistence,
    'inicio': AppTime.wallClockToUtc(inicio).toIso8601String(),
    'fim': AppTime.wallClockToUtc(fim).toIso8601String(),
    'ativo': ativo,
    'prioridade': prioridade,
    'produtoIds': produtoIds.toList(),
  };
}
