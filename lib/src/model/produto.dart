import 'decimal_value.dart';

class ProdutoCodigoBarras {
  final String? id;
  final String codigo;
  final String tipo;
  final bool principal;
  final bool ativo;

  const ProdutoCodigoBarras({
    this.id,
    required this.codigo,
    this.tipo = 'EAN',
    this.principal = false,
    this.ativo = true,
  });

  factory ProdutoCodigoBarras.fromJson(Map<String, dynamic> json) =>
      ProdutoCodigoBarras(
        id: json['id']?.toString(),
        codigo: json['codigo']?.toString() ?? '',
        tipo: json['tipo']?.toString() ?? 'EAN',
        principal: json['principal'] == true,
        ativo: json['ativo'] != false,
      );

  Map<String, dynamic> toRequestJson() => {
    'codigo': codigo,
    'tipo': tipo,
    'principal': principal,
    'ativo': ativo,
  };
}

class ProdutoFiscal {
  final String? ncm;
  final String? cest;
  final String? origemMercadoria;
  final String? unidadeTributavel;
  final DecimalValue? fatorConversaoTributavel;
  final String? gtinTributavel;
  final String? perfilTributarioId;

  const ProdutoFiscal({
    this.ncm,
    this.cest,
    this.origemMercadoria,
    this.unidadeTributavel,
    this.fatorConversaoTributavel,
    this.gtinTributavel,
    this.perfilTributarioId,
  });

  factory ProdutoFiscal.fromJson(Map<String, dynamic> json) => ProdutoFiscal(
    ncm: json['ncm']?.toString(),
    cest: json['cest']?.toString(),
    origemMercadoria: json['origemMercadoria']?.toString(),
    unidadeTributavel: json['unidadeTributavel']?.toString(),
    fatorConversaoTributavel: json['fatorConversaoTributavel'] == null
        ? null
        : DecimalValue.fromJson(json['fatorConversaoTributavel']),
    gtinTributavel: json['gtinTributavel']?.toString(),
    perfilTributarioId: json['perfilTributarioId']?.toString(),
  );

  bool get isEmpty => [
    ncm,
    cest,
    origemMercadoria,
    unidadeTributavel,
    fatorConversaoTributavel?.value,
    gtinTributavel,
    perfilTributarioId,
  ].every((value) => value == null || value.isEmpty);

  Map<String, dynamic> toJson() => {
    'ncm': ncm,
    'cest': cest,
    'origemMercadoria': origemMercadoria,
    'unidadeTributavel': unidadeTributavel,
    'fatorConversaoTributavel': fatorConversaoTributavel?.persistence,
    'gtinTributavel': gtinTributavel,
    'perfilTributarioId': perfilTributarioId,
  };
}

class Produto {
  final String? id;
  final String codigoInterno;
  final List<ProdutoCodigoBarras> codigosBarras;
  final String nome;
  final DecimalValue preco;
  final String unidadeMedida;
  final String categoria;
  final String? descricao;
  final String? foto;
  final DecimalValue? peso;
  final DecimalValue? pesoTolerancia;
  final bool ativo;

  /// Disponível em todos os Condomínios, inclusive nos criados depois. Só
  /// leitura aqui: muda por [ProdutoRepository.definirDisponivelEmTodos].
  final bool disponivelTodosCondominios;

  /// Abaixo deste saldo o estoque central está baixo; null = sem mínimo.
  final DecimalValue? estoqueMinimoCentral;

  /// O mesmo mínimo vale para o saldo de cada Condomínio; null = sem mínimo.
  final DecimalValue? estoqueMinimoCondominio;
  final ProdutoFiscal? fiscal;

  const Produto({
    this.id,
    required this.codigoInterno,
    required this.codigosBarras,
    required this.nome,
    required this.preco,
    required this.unidadeMedida,
    required this.categoria,
    this.descricao,
    this.foto,
    this.peso,
    this.pesoTolerancia,
    this.ativo = true,
    this.disponivelTodosCondominios = false,
    this.estoqueMinimoCentral,
    this.estoqueMinimoCondominio,
    this.fiscal,
  });

  String? get codigoBarrasPrincipal {
    for (final codigo in codigosBarras) {
      if (codigo.ativo && codigo.principal) return codigo.codigo;
    }
    for (final codigo in codigosBarras) {
      if (codigo.ativo) return codigo.codigo;
    }
    return null;
  }

  factory Produto.fromJson(Map<String, dynamic> json) {
    final rawCodes = json['codigosBarras'];
    final legacyCode = json['codigo']?.toString();
    final codes = rawCodes is List
        ? rawCodes
              .whereType<Map>()
              .map(
                (item) => ProdutoCodigoBarras.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
        : <ProdutoCodigoBarras>[
            if (legacyCode != null && legacyCode.isNotEmpty)
              ProdutoCodigoBarras(codigo: legacyCode, principal: true),
          ];
    return Produto(
      id: json['id']?.toString(),
      codigoInterno: json['codigoInterno']?.toString() ?? legacyCode ?? '',
      codigosBarras: codes,
      nome: json['nome']?.toString() ?? '',
      preco: DecimalValue.fromJson(json['preco']),
      unidadeMedida: json['unidadeMedida']?.toString() ?? 'UN',
      categoria: json['categoria']?.toString() ?? 'OUTROS',
      descricao: json['descricao']?.toString(),
      foto: json['foto']?.toString(),
      peso: json['peso'] == null ? null : DecimalValue.fromJson(json['peso']),
      pesoTolerancia: json['pesoTolerancia'] == null
          ? null
          : DecimalValue.fromJson(json['pesoTolerancia']),
      ativo: json['ativo'] ?? json['status'] ?? true,
      disponivelTodosCondominios: json['disponivelTodosCondominios'] == true,
      estoqueMinimoCentral: _minimo(json['estoqueMinimoCentral']),
      estoqueMinimoCondominio: _minimo(json['estoqueMinimoCondominio']),
      fiscal: json['fiscal'] is Map
          ? ProdutoFiscal.fromJson(Map<String, dynamic>.from(json['fiscal']))
          : null,
    );
  }

  static DecimalValue? _minimo(Object? raw) {
    if (raw == null) return null;
    final value = DecimalValue.fromJson(raw);
    return value.isPositive ? value : null;
  }

  /// O saldo [quantidade] está abaixo de [minimo]? Sem mínimo, nunca está.
  static bool abaixoDoMinimo(DecimalValue? quantidade, DecimalValue? minimo) =>
      minimo != null &&
      (quantidade?.scaledInteger ?? BigInt.zero) < minimo.scaledInteger;

  Map<String, dynamic> toRequestJson() => {
    // Campo legado mantido durante a transição dos consumidores antigos.
    'codigo': codigoBarrasPrincipal,
    'codigoInterno': codigoInterno,
    'codigosBarras': codigosBarras.map((e) => e.toRequestJson()).toList(),
    'nome': nome,
    'preco': preco.persistence,
    'unidadeMedida': unidadeMedida,
    'categoria': categoria,
    'descricao': descricao,
    'peso': peso?.fixedScale(3),
    'pesoTolerancia': pesoTolerancia?.fixedScale(3),
    'ativo': ativo,
    // Zero limpa o mínimo no backend.
    'estoqueMinimoCentral': estoqueMinimoCentral?.fixedScale(3) ?? '0.000',
    'estoqueMinimoCondominio':
        estoqueMinimoCondominio?.fixedScale(3) ?? '0.000',
    if (fiscal != null && !fiscal!.isEmpty) 'fiscal': fiscal!.toJson(),
  };
}
