import 'package:flutter/services.dart';

/// Máscara numérica de digitação: cada `#` recebe um dígito e o resto do
/// padrão entra sozinho. Ex.: `###.###.###-##` para CPF.
class MaskInputFormatter extends TextInputFormatter {
  const MaskInputFormatter(this.mask);
  final String mask;

  static const cpf = MaskInputFormatter('###.###.###-##');
  static const cnpj = MaskInputFormatter('##.###.###/####-##');
  static const cep = MaskInputFormatter('#####-###');
  static const phone = MaskInputFormatter('(##) #####-####');
  static const date = MaskInputFormatter('##/##/####');

  String apply(String text) {
    final digits = text.replaceAll(RegExp(r'\D'), '');
    final out = StringBuffer();
    var i = 0;
    for (final char in mask.split('')) {
      if (i >= digits.length) break;
      out.write(char == '#' ? digits[i++] : char);
    }
    return out.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = apply(newValue.text);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
