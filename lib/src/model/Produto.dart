class Produto {
  final int? id;
  final String codigo;
  final String nome;
  final double preco;
  final int quantidade;
  final String unidadeMedida;
  final String categoria;
  final String? descricao;
  final String? foto;
  final double peso;
  final double pesoTolerancia;

  Produto({
    this.id,
    required this.codigo,
    required this.nome,
    required this.preco,
    required this.quantidade,
    required this.unidadeMedida,
    required this.categoria,
    this.descricao,
    this.foto,
    required this.peso,
    required this.pesoTolerancia,
  });

  // 🔹 Converter JSON → objeto
  factory Produto.fromJson(Map<String, dynamic> json) {
    return Produto(
      id: json['id'],
      codigo: json['codigo'],
      nome: json['nome'],
      preco: (json['preco'] as num).toDouble(),
      quantidade: json['quantidade'],
      unidadeMedida: json['unidadeMedida'],
      categoria: json['categoria'],
      descricao: json['descricao'],
      foto: json['foto'],
      peso: (json['peso'] as num).toDouble(),
      pesoTolerancia: (json['pesoTolerancia'] as num).toDouble(),
    );
  }

  // 🔹 Converter objeto → JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo': codigo,
      'nome': nome,
      'preco': preco,
      'quantidade': quantidade,
      'unidadeMedida': unidadeMedida,
      'categoria': categoria,
      'descricao': descricao,
      'foto': foto,
      'peso': peso,
      'pesoTolerancia': pesoTolerancia,
    };
  }
}