class ImportacaoProduto {
  const ImportacaoProduto({
    required this.id,
    required this.nomeArquivo,
    required this.status,
    required this.totalLinhas,
    required this.totalValidas,
    required this.totalAvisos,
    required this.totalErros,
    required this.produtosImportados,
    required this.barcodesImportados,
    required this.estoquesCriados,
    required this.preview,
  });
  final String id;
  final String nomeArquivo;
  final String status;
  final int totalLinhas;
  final int totalValidas;
  final int totalAvisos;
  final int totalErros;
  final int produtosImportados;
  final int barcodesImportados;
  final int estoquesCriados;
  final List<ImportacaoLinha> preview;

  bool get podeConfirmar => status == 'VALIDADA' && totalErros == 0;
  bool get processando => status == 'PROCESSANDO';
  bool get concluida =>
      status == 'CONCLUIDA' || status == 'CONCLUIDA_COM_ERROS';

  factory ImportacaoProduto.fromJson(Map<String, dynamic> json) =>
      ImportacaoProduto(
        id: json['importacaoId'].toString(),
        nomeArquivo: json['nomeArquivo']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        totalLinhas: (json['totalLinhas'] as num?)?.toInt() ?? 0,
        totalValidas: (json['totalValidas'] as num?)?.toInt() ?? 0,
        totalAvisos: (json['totalAvisos'] as num?)?.toInt() ?? 0,
        totalErros: (json['totalErros'] as num?)?.toInt() ?? 0,
        produtosImportados: (json['produtosImportados'] as num?)?.toInt() ?? 0,
        barcodesImportados: (json['barcodesImportados'] as num?)?.toInt() ?? 0,
        estoquesCriados: (json['estoquesCriados'] as num?)?.toInt() ?? 0,
        preview: ((json['preview'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => ImportacaoLinha.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class ImportacaoLinha {
  const ImportacaoLinha({
    required this.aba,
    required this.linha,
    required this.status,
    this.codigoInterno,
    this.mensagem,
    this.produtoId,
  });
  final String aba;
  final int linha;
  final String? codigoInterno;
  final String status;
  final String? mensagem;
  final String? produtoId;

  factory ImportacaoLinha.fromJson(Map<String, dynamic> json) =>
      ImportacaoLinha(
        aba: json['aba']?.toString() ?? '',
        linha: (json['linha'] as num?)?.toInt() ?? 0,
        codigoInterno: json['codigoInterno']?.toString(),
        status: json['status']?.toString() ?? '',
        mensagem: json['mensagem']?.toString(),
        produtoId: json['produtoId']?.toString(),
      );
}
