import 'decimal_value.dart';

class EstoqueCentral {
  final String id;
  final String produtoId;
  final String produto;
  final String codigoInterno;
  final String codigoBarrasPrincipal;
  final String categoria;
  final String unidadeMedida;
  final DecimalValue quantidade;
  final bool ativo;
  final String? localizacao;
  final DecimalValue? capacidadePosicao;

  const EstoqueCentral({
    required this.id,
    required this.produtoId,
    required this.produto,
    required this.codigoInterno,
    required this.codigoBarrasPrincipal,
    required this.categoria,
    required this.unidadeMedida,
    required this.quantidade,
    required this.ativo,
    this.localizacao,
    this.capacidadePosicao,
  });

  factory EstoqueCentral.fromJson(Map<String, dynamic> json) => EstoqueCentral(
    id: json['id'].toString(),
    produtoId: json['produtoId'].toString(),
    produto: json['produto']?.toString() ?? 'Produto',
    codigoInterno: json['codigoInterno']?.toString() ?? '',
    codigoBarrasPrincipal: json['codigoBarrasPrincipal']?.toString() ?? '',
    categoria: json['categoria']?.toString() ?? '',
    unidadeMedida: json['unidadeMedida']?.toString() ?? 'UN',
    quantidade: DecimalValue.fromJson(json['quantidade']),
    ativo: json['ativo'] != false,
    localizacao: json['localizacao']?.toString(),
    capacidadePosicao: json['capacidadePosicao'] == null
        ? null
        : DecimalValue.fromJson(json['capacidadePosicao']),
  );
}

class MovimentoEstoque {
  final String id;
  final String localTipo;
  final String produtoId;
  final String tipo;
  final DecimalValue quantidade;
  final DecimalValue saldoAnterior;
  final DecimalValue saldoPosterior;
  final String? transferenciaId;
  final String? responsavel;
  final String? motivo;
  final DateTime createdAt;

  const MovimentoEstoque({
    required this.id,
    required this.localTipo,
    required this.produtoId,
    required this.tipo,
    required this.quantidade,
    required this.saldoAnterior,
    required this.saldoPosterior,
    this.transferenciaId,
    this.responsavel,
    this.motivo,
    required this.createdAt,
  });

  factory MovimentoEstoque.fromJson(Map<String, dynamic> json) =>
      MovimentoEstoque(
        id: json['id'].toString(),
        localTipo: json['localTipo']?.toString() ?? '',
        produtoId: json['produtoId'].toString(),
        tipo: json['tipo'].toString(),
        quantidade: DecimalValue.fromJson(json['quantidade']),
        saldoAnterior: DecimalValue.fromJson(json['quantidadeAnterior']),
        saldoPosterior: DecimalValue.fromJson(json['quantidadePosterior']),
        transferenciaId: json['transferenciaId']?.toString(),
        responsavel: json['responsavel']?.toString(),
        motivo: json['motivo']?.toString(),
        createdAt: DateTime.parse(json['createdAt'].toString()),
      );
}

class TransferenciaItem {
  final String? id;
  final String produtoId;
  final String produto;
  final DecimalValue quantidade;
  const TransferenciaItem({
    this.id,
    required this.produtoId,
    required this.produto,
    required this.quantidade,
  });
  factory TransferenciaItem.fromJson(Map<String, dynamic> json) =>
      TransferenciaItem(
        id: json['id']?.toString(),
        produtoId: json['produtoId'].toString(),
        produto: json['produto']?.toString() ?? 'Produto',
        quantidade: DecimalValue.fromJson(json['quantidade']),
      );
}

class TransferenciaEstoque {
  final String id;
  final String destinoId;
  final String destinoNome;
  final String status;
  final String? observacao;
  final String? responsavel;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? cancelledAt;
  final List<TransferenciaItem> itens;
  final List<MovimentoEstoque> movimentacoes;
  const TransferenciaEstoque({
    required this.id,
    required this.destinoId,
    required this.destinoNome,
    required this.status,
    this.observacao,
    this.responsavel,
    required this.createdAt,
    this.confirmedAt,
    this.cancelledAt,
    required this.itens,
    required this.movimentacoes,
  });
  factory TransferenciaEstoque.fromJson(Map<String, dynamic> json) =>
      TransferenciaEstoque(
        id: json['id'].toString(),
        destinoId: json['destinoId'].toString(),
        destinoNome:
            json['destinoNome']?.toString() ?? json['destinoId'].toString(),
        status: json['status'].toString(),
        observacao: json['observacao']?.toString(),
        responsavel: json['responsavel']?.toString(),
        createdAt: DateTime.parse(json['createdAt'].toString()),
        confirmedAt: json['confirmedAt'] == null
            ? null
            : DateTime.parse(json['confirmedAt'].toString()),
        cancelledAt: json['cancelledAt'] == null
            ? null
            : DateTime.parse(json['cancelledAt'].toString()),
        itens: ((json['itens'] as List?) ?? const [])
            .whereType<Map>()
            .map(
              (e) => TransferenciaItem.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList(),
        movimentacoes: ((json['movimentacoes'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => MovimentoEstoque.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class PlanogramaProduto {
  final String id;
  final String produtoId;
  final String nome;
  final int facings;
  final DecimalValue? capacidade;
  final bool ativo;
  const PlanogramaProduto({
    required this.id,
    required this.produtoId,
    required this.nome,
    required this.facings,
    this.capacidade,
    required this.ativo,
  });
  factory PlanogramaProduto.fromJson(Map<String, dynamic> json) =>
      PlanogramaProduto(
        id: json['id'].toString(),
        produtoId: json['produtoId'].toString(),
        nome: json['nome'].toString(),
        facings: (json['facings'] as num?)?.toInt() ?? 1,
        capacidade: json['capacidade'] == null
            ? null
            : DecimalValue.fromJson(json['capacidade']),
        ativo: json['ativo'] != false,
      );
}

class PlanogramaPosicao {
  final String id;
  final String localizacao;
  final String? setor;
  final int ordem;
  final List<PlanogramaProduto> produtos;
  const PlanogramaPosicao({
    required this.id,
    required this.localizacao,
    this.setor,
    required this.ordem,
    required this.produtos,
  });
  factory PlanogramaPosicao.fromJson(Map<String, dynamic> json) =>
      PlanogramaPosicao(
        id: json['id'].toString(),
        localizacao: json['localizacao']?.toString() ?? '',
        setor: json['setor']?.toString(),
        ordem: (json['ordem'] as num?)?.toInt() ?? 0,
        produtos: ((json['produtos'] as List?) ?? const [])
            .whereType<Map>()
            .map(
              (e) => PlanogramaProduto.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList(),
      );
}

class Planograma {
  final String id;
  final String nome;
  final String? descricao;
  final bool ativo;
  final List<PlanogramaPosicao> posicoes;
  const Planograma({
    required this.id,
    required this.nome,
    this.descricao,
    required this.ativo,
    required this.posicoes,
  });
  factory Planograma.fromJson(Map<String, dynamic> json) => Planograma(
    id: json['id'].toString(),
    nome: json['nome'].toString(),
    descricao: json['descricao']?.toString(),
    ativo: json['ativo'] != false,
    posicoes: ((json['posicoes'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => PlanogramaPosicao.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
  );
}
