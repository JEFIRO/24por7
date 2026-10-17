class DecimalValue {
  final String value;

  const DecimalValue._(this.value);

  factory DecimalValue.fromJson(Object? source) {
    if (source == null) throw const FormatException('Valor decimal ausente');
    return DecimalValue.parse(source.toString());
  }

  factory DecimalValue.parse(String source, {int maxScale = 6}) {
    final normalized = source.trim().replaceAll(',', '.');
    if (maxScale < 0 || maxScale > 6) {
      throw const FormatException('Escala decimal inválida');
    }
    final pattern = maxScale == 0
        ? RegExp(r'^-?\d+$')
        : RegExp('^-?\\d+(\\.\\d{1,$maxScale})?\$');
    if (!pattern.hasMatch(normalized)) {
      throw FormatException('Use um número com até $maxScale casas decimais');
    }
    final negative = normalized.startsWith('-');
    final unsigned = negative ? normalized.substring(1) : normalized;
    final parts = unsigned.split('.');
    final integer = BigInt.parse(parts[0]).toString();
    final fraction = parts.length == 2 ? parts[1] : '';
    final magnitude = fraction.isEmpty ? integer : '$integer.$fraction';
    final isZero =
        BigInt.parse('$integer${fraction.padRight(6, '0')}') == BigInt.zero;
    return DecimalValue._(negative && !isZero ? '-$magnitude' : magnitude);
  }

  String get persistence {
    return fixedScale(6);
  }

  String get normalized => value;

  String fixedScale(int scale) {
    final parts = value.split('.');
    final fraction = (parts.length == 2 ? parts[1] : '').padRight(scale, '0');
    return scale == 0
        ? parts[0]
        : '${parts[0]}.${fraction.substring(0, scale)}';
  }

  BigInt get scaledInteger => BigInt.parse(persistence.replaceAll('.', ''));
  bool get isPositive => scaledInteger > BigInt.zero;
  bool get isNegative => scaledInteger < BigInt.zero;
  bool lessThanOrEqualTo(String other) =>
      scaledInteger <= DecimalValue.parse(other).scaledInteger;

  String get friendly {
    if (!value.contains('.')) return value;
    final result = value
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
    return result.replaceAll('.', ',');
  }

  String get currency {
    final parts = persistence.split('.');
    var cents = BigInt.parse(parts[0]) * BigInt.from(100);
    cents += BigInt.parse(parts[1].substring(0, 2));
    if (int.parse(parts[1][2]) >= 5) cents += BigInt.one;
    final digits = cents.toString().padLeft(3, '0');
    return 'R\$ ${digits.substring(0, digits.length - 2)},${digits.substring(digits.length - 2)}';
  }

  @override
  String toString() => value;
}
