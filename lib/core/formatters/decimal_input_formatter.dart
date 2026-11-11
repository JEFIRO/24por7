import 'package:flutter/services.dart';

/// Máscara de valor estilo "banco": o usuário digita só números e eles entram
/// pela direita (1 -> 0,01 | 1500 -> 15,00). O valor é tratado como inteiro
/// na menor unidade (centavos, gramas), nunca como double.
class DecimalInputFormatter extends TextInputFormatter {
  final int decimalDigits;
  final int maxDigits;

  DecimalInputFormatter({this.decimalDigits = 2, this.maxDigits = 12});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return const TextEditingValue(text: '');
    if (digits.length > maxDigits) digits = digits.substring(0, maxDigits);
    final text = format(int.parse(digits));
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  String format(int value) {
    final s = value.toString().padLeft(decimalDigits + 1, '0');
    final intPart = s.substring(0, s.length - decimalDigits);
    final decPart = s.substring(s.length - decimalDigits);
    final withDots = intPart.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return decimalDigits == 0 ? withDots : '$withDots,$decPart';
  }

  static int parse(String text) =>
      int.tryParse(text.replaceAll(RegExp(r'\D'), '')) ?? 0;
}
