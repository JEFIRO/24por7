import 'dart:convert';

import 'package:app_24por7/src/model/api_client.dart';
import 'package:app_24por7/src/model/operational_repository.dart';
import 'package:app_24por7/src/page/terminal_pairing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _terminal = TerminalAdmin(
  id: 'terminal-a',
  nome: 'Portaria',
  codigo: 'portaria',
  condominioId: 'condominio-a',
  ativo: true,
  status: 'OFFLINE',
);

void main() {
  group('parsePairingCode', () {
    test('aceita o conteúdo do QR, digitação solta e minúsculas', () {
      expect(parsePairingCode('APP247-PAIR:K7Q4-MZ8P'), 'K7Q4-MZ8P');
      expect(parsePairingCode(' k7q4mz8p '), 'K7Q4-MZ8P');
      expect(parsePairingCode('K7Q4 MZ8P'), 'K7Q4-MZ8P');
    });

    test('recusa o que não é código de pareamento', () {
      expect(parsePairingCode(null), isNull);
      expect(parsePairingCode('7891234567895'), isNull);
      expect(parsePairingCode('{"serialNumber":"x"}'), isNull);
    });
  });

  test('parearTerminal envia o código normalizado para o Terminal', () async {
    late http.Request sent;
    final repository = OperationalRepository(
      client: ApiClient(
        baseUrl: 'https://api.example',
        httpClient: MockClient((request) async {
          sent = request;
          return http.Response(
            jsonEncode({
              'id': 'terminal-a',
              'nome': 'Portaria',
              'serialNumber': 'serial-a',
            }),
            200,
          );
        }),
      )..token = 'admin-token',
    );

    final terminal = await repository.parearTerminal('terminal-a', 'K7Q4-MZ8P');

    expect(sent.method, 'POST');
    expect(sent.url.path, '/terminais/terminal-a/pairing');
    expect(jsonDecode(sent.body), {'code': 'K7Q4-MZ8P'});
    expect(terminal.serialNumber, 'serial-a');
  });

  testWidgets('diálogo mostra o erro do backend e não fecha', (tester) async {
    final repository = OperationalRepository(
      client: ApiClient(
        baseUrl: 'https://api.example',
        httpClient: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'code': 'PAIRING_CODE_INVALID',
              'message': 'Código inválido',
            }),
            404,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      )..token = 'admin-token',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showTerminalPairingDialog(
              context,
              repository: repository,
              terminal: _terminal,
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Parear'));
    await tester.pumpAndSettle();
    expect(find.text('Informe o código mostrado no Terminal'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'k7q4mz8p');
    await tester.tap(find.text('Parear'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Código inválido ou expirado. Confira o código na tela do Terminal.',
      ),
      findsOneWidget,
    );
    expect(find.text('Parear Portaria'), findsOneWidget);
  });
}
