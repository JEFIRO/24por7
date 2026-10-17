import 'package:app_24por7/src/model/mercado_pago_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('setup distinguishes linked account from configured Point', () {
    final value = MercadoPagoSetup.fromJson({
      'contaVinculada': true,
      'maquininhaVinculada': false,
      'configuracaoCompleta': false,
      'quantidadeTerminais': 3,
      'quantidadeMaquininhasVinculadas': 0,
      'dataVinculacao': '2026-09-04T12:00:00Z',
    });

    expect(value.contaVinculada, isTrue);
    expect(value.maquininhaVinculada, isFalse);
    expect(value.quantidadeTerminais, 3);
  });

  test('Point keeps correlation with internal Terminal', () {
    final value = MercadoPagoPoint.fromJson({
      'id': 'PAX_A910__123',
      'externalPosId': 'Entrada',
      'vinculado': true,
      'terminalInternoId': 'terminal-1',
    });

    expect(value.id, 'PAX_A910__123');
    expect(value.vinculado, isTrue);
    expect(value.terminalInternoId, 'terminal-1');
  });
}
