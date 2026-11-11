import 'package:app_24por7/core/formatters/decimal_input_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

String _type(DecimalInputFormatter formatter, String text) => formatter
    .formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: text))
    .text;

void main() {
  test('dígitos entram pela direita com 2 casas', () {
    final formatter = DecimalInputFormatter(decimalDigits: 2);
    expect(_type(formatter, '1'), '0,01');
    expect(_type(formatter, '1500'), '15,00');
    expect(_type(formatter, '123456'), '1.234,56');
    expect(_type(formatter, 'R\$ 10,99'), '10,99');
    expect(_type(formatter, ''), '');
  });

  test('peso usa 3 casas', () {
    final formatter = DecimalInputFormatter(decimalDigits: 3);
    expect(_type(formatter, '1250'), '1,250');
    expect(_type(formatter, '5'), '0,005');
    expect(formatter.format(1234567), '1.234,567');
  });

  test('corta no limite de dígitos e mantém o cursor no fim', () {
    final formatter = DecimalInputFormatter(decimalDigits: 2, maxDigits: 5);
    final value = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: '1234567'),
    );
    expect(value.text, '123,45');
    expect(value.selection.baseOffset, value.text.length);
  });

  test('parse devolve o inteiro na menor unidade', () {
    expect(DecimalInputFormatter.parse('1.234,56'), 123456);
    expect(DecimalInputFormatter.parse('0,005'), 5);
    expect(DecimalInputFormatter.parse(''), 0);
  });
}
