import 'package:app_24por7/src/model/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'OAuth redirect sends bearer only to backend and returns provider URL',
    () async {
      final client = ApiClient(
        baseUrl: 'https://api.example',
        httpClient: MockClient((request) async {
          expect(
            request.url.toString(),
            'https://api.example/mercado-pago/oauth',
          );
          expect(request.headers['Authorization'], 'Bearer admin-token');
          return http.Response(
            '',
            302,
            headers: {
              'location': 'https://auth.mercadopago.com/authorize?id=1',
            },
          );
        }),
      )..token = 'admin-token';

      final redirect = await client.authenticatedRedirect(
        '/mercado-pago/oauth',
      );

      expect(redirect.host, 'auth.mercadopago.com');
    },
  );

  test('401 clears current session and notifies the app', () async {
    var notified = false;
    final client =
        ApiClient(
            baseUrl: 'https://api.example',
            httpClient: MockClient(
              (_) async => http.Response('{"message":"expirou"}', 401),
            ),
          )
          ..token = 'expired-token'
          ..onUnauthorized = () => notified = true;

    await expectLater(client.get('/terminais'), throwsA(isA<ApiException>()));
    expect(client.token, isNull);
    expect(notified, isTrue);
  });
}
