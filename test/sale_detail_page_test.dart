import 'package:app_24por7/core/theme/branding_config.dart';
import 'package:app_24por7/src/model/admin_history.dart';
import 'package:app_24por7/src/model/admin_repository.dart';
import 'package:app_24por7/src/model/admin_sale_detail.dart';
import 'package:app_24por7/src/page/admin_history_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() {
  setUpAll(() async {
    tz.initializeTimeZones();
    await initializeDateFormatting('pt_BR');
  });

  for (final size in const [Size(400, 900), Size(1366, 1000)]) {
    testWidgets('toque na venda abre o detalhe (${size.width})', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        BrandingScope(
          branding: const BrandingConfig(displayName: 'Teste'),
          child: MaterialApp(
            theme: ThemeData(useMaterial3: true),
            home: Scaffold(body: SalesHistoryPage(repository: _Fake())),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Residencial Sol'), findsWidgets);
      expect(find.textContaining('Totem 1'), findsWidgets);
      await tester.tap(find.textContaining('#ABCDEF12').first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Detalhes da venda'), findsOneWidget);
      expect(find.text('Coca-Cola 350ml'), findsOneWidget);
      expect(find.text('Enviar comprovante'), findsOneWidget);
      expect(find.text('Solicitar reembolso'), findsOneWidget);
    });
  }
}

class _Fake extends AdminRepository {
  @override
  Future<AdminPage<AdminSale>> sales({
    int page = 0,
    String period = 'TODAY',
    String? status = 'PROCESSED',
  }) async => AdminPage.fromJson({
    'content': [
      {
        'id': 'abcdef12-3456-7890-abcd-ef1234567890',
        'status': 'PROCESSED',
        'total': '7.50',
        'criadaEm': '2026-11-06T17:30:00Z',
        'pagaEm': '2026-11-06T17:31:00Z',
        'condominioNome': 'Residencial Sol',
        'terminalNome': 'Totem 1',
      },
    ],
    'number': 0,
    'totalPages': 1,
    'totalElements': 1,
  }, AdminSale.fromJson);

  @override
  Future<AdminSaleDetail> saleDetail(String orderId) async =>
      AdminSaleDetail.fromJson({
        'id': orderId,
        'status': 'PROCESSED',
        'criadaEm': '2026-11-06T17:30:00Z',
        'pagaEm': '2026-11-06T17:31:00Z',
        'condominioNome': 'Residencial Sol',
        'terminalNome': 'Totem 1',
        'terminalCodigo': 'T01',
        'itens': [
          {
            'codigo': '123',
            'descricao': 'Coca-Cola 350ml',
            'quantidade': 1.000,
            'unidade': 'UN',
            'valorUnitario': 7.5,
            'desconto': 0.00,
            'valorFinal': 7.50,
          },
        ],
        'subtotal': 7.50,
        'descontoPromocoes': 0.00,
        'descontoCupom': null,
        'total': 7.50,
        'pagamento': {
          'status': 'PROCESSED',
          'forma': 'PIX',
          'parcelas': null,
          'nsu': '999',
        },
        'reembolso': null,
        'podeReembolsar': true,
        'podeEnviarComprovante': true,
      });
}
