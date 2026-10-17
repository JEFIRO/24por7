import 'package:app_24por7/src/model/decimal_value.dart';
import 'package:app_24por7/src/model/promocao.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() {
  setUpAll(tz.initializeTimeZones);
  group('DecimalValue', () {
    test('preserves six-place financial value and only rounds display', () {
      final value = DecimalValue.parse('10,165750');

      expect(value.persistence, '10.165750');
      expect(value.currency, 'R\$ 10,17');
    });

    test(
      'promotion request serializes decimal as exact string and UTC dates',
      () {
        final draft = PromocaoDraft(
          nome: 'Semana do Refrigerante',
          abrangencia: AbrangenciaPromocao.empresa,
          tipo: TipoPromocao.percentual,
          valor: DecimalValue.parse('7,5'),
          inicio: DateTime(2026, 8, 30, 8),
          fim: DateTime(2026, 9, 5, 23, 59),
          ativo: true,
          prioridade: 2,
          produtoIds: const {'produto-1'},
        );

        expect(draft.toJson()['valor'], '7.500000');
        expect(draft.toJson()['abrangencia'], 'EMPRESA');
        expect(draft.toJson()['produtoIds'], ['produto-1']);
        expect(draft.toJson()['inicio'], '2026-08-30T11:00:00.000Z');
      },
    );

    test('rejects more than six decimal places', () {
      expect(() => DecimalValue.parse('1.1234567'), throwsFormatException);
    });
  });
}
