import 'dart:convert';

import 'package:app_24por7/src/model/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class MemorySessionStorage implements SessionStorage {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async => this.value = value;
  @override
  Future<void> clear() async => value = null;
}

String jwtExpiringAt(DateTime when) {
  String part(Object data) =>
      base64Url.encode(utf8.encode(jsonEncode(data))).replaceAll('=', '');
  return '${part({'alg': 'HS256'})}.'
      '${part({'exp': when.millisecondsSinceEpoch ~/ 1000})}.sig';
}

void main() {
  test('login fica salvo e é restaurado em nova execução', () async {
    final storage = MemorySessionStorage();
    final token = jwtExpiringAt(DateTime.now().add(const Duration(hours: 1)));
    final client = ApiClient(
      baseUrl: 'http://api',
      sessionStorage: storage,
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode({'token': token, 'user': {'nome': 'Ana'}}),
          200,
        ),
      ),
    )..token = null;
    await client.loginAdmin('123', 'senha');

    final reopened = ApiClient(baseUrl: 'http://api', sessionStorage: storage)
      ..token = null;
    await reopened.restoreSession();
    expect(reopened.isAuthenticated, isTrue);
    expect(reopened.token, token);
    expect(reopened.authenticatedUser?['nome'], 'Ana');
  });

  test('sessão expirada é descartada', () async {
    final storage = MemorySessionStorage()
      ..value = jsonEncode({
        'token': jwtExpiringAt(
          DateTime.now().subtract(const Duration(minutes: 1)),
        ),
      });
    final client = ApiClient(baseUrl: 'http://api', sessionStorage: storage)
      ..token = null;
    await client.restoreSession();
    expect(client.isAuthenticated, isFalse);
    expect(storage.value, isNull);
  });

  test('logout apaga a sessão salva', () async {
    final storage = MemorySessionStorage()..value = '{"token":"x"}';
    ApiClient(baseUrl: 'http://api', sessionStorage: storage).clearSession();
    await Future<void>.delayed(Duration.zero);
    expect(storage.value, isNull);
  });
}
