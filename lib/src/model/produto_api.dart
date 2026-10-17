class ProdutoAPI {
  final String codigo;
  final String nome;
  final String? nomePt;
  final String? marca;
  final String? descricao;
  final String? quantidade;
  final double? quantidadeNumerica;
  final String? unidade;

  final String? imagem;
  final String? imagemThumb;
  final String? imagemSmall;

  final List<String> keywords;

  ProdutoAPI({
    required this.codigo,
    required this.nome,
    this.nomePt,
    this.marca,
    this.descricao,
    this.quantidade,
    this.quantidadeNumerica,
    this.unidade,
    this.imagem,
    this.imagemThumb,
    this.imagemSmall,
    required this.keywords,
  });

  factory ProdutoAPI.fromJson(Map<String, dynamic> json) {
    final product = json['product'];

    return ProdutoAPI(
      codigo: product['_id'] ?? '',
      nome: product['product_name'] ?? '',
      nomePt: product['product_name_pt'],
      marca: product['brands'],
      descricao: product['generic_name'],
      quantidade: product['quantity'],
      quantidadeNumerica: (product['product_quantity'] as num?)?.toDouble(),
      unidade: product['product_quantity_unit'],

      imagem: product['image_url'],
      imagemThumb: product['image_thumb_url'],
      imagemSmall: product['image_small_url'],

      keywords:
          (product['_keywords'] as List?)?.map((e) => e.toString()).toList() ??
          [],
    );
  }
}
