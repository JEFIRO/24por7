/// NF-e de entrada lida do XML do fornecedor, em revisão ou já importada.
class NotaFiscalEntrada {
  const NotaFiscalEntrada({
    required this.id,
    required this.chave,
    required this.numero,
    required this.serie,
    required this.emitenteCnpj,
    required this.emitenteNome,
    required this.valorTotal,
    required this.status,
    required this.totalPendentes,
    required this.totalAvisos,
    required this.podeConfirmar,
    required this.produtosCriados,
    required this.entradasLancadas,
    required this.itens,
    this.dataEmissao,
  });

  final String id;
  final String chave;
  final String numero;
  final String serie;
  final String emitenteCnpj;
  final String emitenteNome;
  final num valorTotal;
  final String status;
  final int totalPendentes;
  final int totalAvisos;
  final bool podeConfirmar;
  final int produtosCriados;
  final int entradasLancadas;
  final List<NotaFiscalItem> itens;
  final DateTime? dataEmissao;

  bool get concluida => status == 'CONCLUIDA';

  factory NotaFiscalEntrada.fromJson(Map<String, dynamic> json) =>
      NotaFiscalEntrada(
        id: json['id'].toString(),
        chave: json['chave']?.toString() ?? '',
        numero: json['numero']?.toString() ?? '',
        serie: json['serie']?.toString() ?? '',
        emitenteCnpj: json['emitenteCnpj']?.toString() ?? '',
        emitenteNome: json['emitenteNome']?.toString() ?? '',
        valorTotal: _num(json['valorTotal']),
        status: json['status']?.toString() ?? '',
        totalPendentes: (json['totalPendentes'] as num?)?.toInt() ?? 0,
        totalAvisos: (json['totalAvisos'] as num?)?.toInt() ?? 0,
        podeConfirmar: json['podeConfirmar'] == true,
        produtosCriados: (json['produtosCriados'] as num?)?.toInt() ?? 0,
        entradasLancadas: (json['entradasLancadas'] as num?)?.toInt() ?? 0,
        dataEmissao: DateTime.tryParse(json['dataEmissao']?.toString() ?? ''),
        itens: ((json['itens'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => NotaFiscalItem.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class NotaFiscalItem {
  const NotaFiscalItem({
    required this.id,
    required this.numeroItem,
    required this.descricao,
    required this.unidadeComercial,
    required this.quantidade,
    required this.valorTotal,
    required this.acao,
    required this.unidadeMedida,
    required this.fatorConversao,
    required this.quantidadeEntrada,
    required this.custoUnitarioVenda,
    required this.status,
    this.ean,
    this.ncm,
    this.produtoId,
    this.produtoNome,
    this.nomeProduto,
    this.precoVenda,
    this.categoria,
    this.mensagem,
  });

  final String id;
  final int numeroItem;
  final String descricao;
  final String unidadeComercial;
  final num quantidade;
  final num valorTotal;
  final String acao;
  final String unidadeMedida;
  final num fatorConversao;
  final num quantidadeEntrada;
  final num custoUnitarioVenda;
  final String status;
  final String? ean;
  final String? ncm;
  final String? produtoId;
  final String? produtoNome;
  final String? nomeProduto;
  final num? precoVenda;
  final String? categoria;
  final String? mensagem;

  bool get criar => acao == 'CRIAR';

  factory NotaFiscalItem.fromJson(Map<String, dynamic> json) => NotaFiscalItem(
    id: json['id'].toString(),
    numeroItem: (json['numeroItem'] as num?)?.toInt() ?? 0,
    descricao: json['descricao']?.toString() ?? '',
    unidadeComercial: json['unidadeComercial']?.toString() ?? 'UN',
    quantidade: _num(json['quantidade']),
    valorTotal: _num(json['valorTotal']),
    acao: json['acao']?.toString() ?? 'CRIAR',
    unidadeMedida: json['unidadeMedida']?.toString() ?? 'UN',
    fatorConversao: _num(json['fatorConversao'], 1),
    quantidadeEntrada: _num(json['quantidadeEntrada']),
    custoUnitarioVenda: _num(json['custoUnitarioVenda']),
    status: json['status']?.toString() ?? 'PENDENTE',
    ean: json['ean']?.toString(),
    ncm: json['ncm']?.toString(),
    produtoId: json['produtoId']?.toString(),
    produtoNome: json['produtoNome']?.toString(),
    nomeProduto: json['nomeProduto']?.toString(),
    precoVenda: json['precoVenda'] == null ? null : _num(json['precoVenda']),
    categoria: json['categoria']?.toString(),
    mensagem: json['mensagem']?.toString(),
  );
}

/// O que a chave de 44 dígitos do DANFE revela antes de ter o XML.
class ChaveAcessoNfe {
  const ChaveAcessoNfe({
    required this.chave,
    required this.emitenteCnpj,
    required this.serie,
    required this.numero,
    required this.sefazDisponivel,
    required this.mensagem,
    this.notaId,
    this.status,
  });

  final String chave;
  final String emitenteCnpj;
  final String serie;
  final String numero;
  final bool sefazDisponivel;
  final String mensagem;
  final String? notaId;
  final String? status;

  factory ChaveAcessoNfe.fromJson(Map<String, dynamic> json) => ChaveAcessoNfe(
    chave: json['chave']?.toString() ?? '',
    emitenteCnpj: json['emitenteCnpj']?.toString() ?? '',
    serie: json['serie']?.toString() ?? '',
    numero: json['numero']?.toString() ?? '',
    sefazDisponivel: json['sefazDisponivel'] == true,
    mensagem: json['mensagem']?.toString() ?? '',
    notaId: json['notaId']?.toString(),
    status: json['status']?.toString(),
  );
}

num _num(Object? value, [num fallback = 0]) =>
    value is num ? value : num.tryParse(value?.toString() ?? '') ?? fallback;
