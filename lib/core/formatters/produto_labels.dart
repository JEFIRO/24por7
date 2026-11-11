/// Nomes legíveis para os códigos de categoria e unidade vindos da API.
abstract final class ProdutoLabels {
  static const _categorias = {
    'LATICINIOS': 'Laticínios',
    'GRAOS': 'Grãos',
    'ELETRONICOS': 'Eletrônicos',
    'DESCARTAVEIS': 'Descartáveis',
  };

  static const _unidades = {
    'UN': 'Unidade',
    'KG': 'Quilograma (kg)',
    'G': 'Grama (g)',
    'ML': 'Mililitro (ml)',
    'DUZIA': 'Dúzia',
  };

  static String categoria(String code) => _categorias[code] ?? _title(code);

  static String unidade(String code) => _unidades[code] ?? _title(code);

  /// `SALGADINHOS` -> `Salgadinhos`; códigos novos da API caem aqui.
  static String _title(String code) {
    final text = code.replaceAll('_', ' ').toLowerCase();
    return text.isEmpty ? text : '${text[0].toUpperCase()}${text.substring(1)}';
  }
}
