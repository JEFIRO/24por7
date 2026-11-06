import 'admin_dashboard.dart';
import 'admin_history.dart';
import 'admin_sale_detail.dart';
import 'api_client.dart';

class AdminRepository {
  AdminRepository({ApiClient? client}) : client = client ?? ApiClient.instance;
  final ApiClient client;

  Future<AdminDashboard> dashboard() async => AdminDashboard.fromJson(
    Map<String, dynamic>.from(await client.get('/admin/dashboard') as Map),
  );

  Future<AdminPage<AdminSale>> sales({
    int page = 0,
    String period = 'TODAY',
    String? status = 'PROCESSED',
  }) async => AdminPage.fromJson(
    Map<String, dynamic>.from(
      await client.get(
            '/admin/sales',
            query: {
              'period': period,
              'status': status,
              'page': '$page',
              'size': '25',
              'sort': 'createdAt,desc',
            },
          )
          as Map,
    ),
    AdminSale.fromJson,
  );

  Future<AdminPage<AdminPayment>> payments({
    int page = 0,
    String? status,
  }) async => AdminPage.fromJson(
    Map<String, dynamic>.from(
      await client.get(
            '/admin/payments',
            query: {
              'status': status,
              'page': '$page',
              'size': '25',
              'sort': 'updatedAt,desc',
            },
          )
          as Map,
    ),
    AdminPayment.fromJson,
  );

  Future<AdminPage<AdminAlert>> alerts({
    int page = 0,
    String? status = 'ACTIVE',
  }) async => AdminPage.fromJson(
    Map<String, dynamic>.from(
      await client.get(
            '/admin/alerts',
            query: {
              'status': status,
              'page': '$page',
              'size': '25',
              'sort': 'lastObservedAt,desc',
            },
          )
          as Map,
    ),
    AdminAlert.fromJson,
  );

  Future<AdminSaleDetail> saleDetail(String orderId) async =>
      AdminSaleDetail.fromJson(
        Map<String, dynamic>.from(
          await client.get('/admin/sales/${Uri.encodeComponent(orderId)}')
              as Map,
        ),
      );

  /// Retorna `true` quando o comprovante já tinha sido enviado a esse destino.
  Future<bool> sendReceipt(
    String orderId, {
    required ReceiptChannel channel,
    required String destination,
  }) async {
    final response = await client.post(
      '/admin/sales/${Uri.encodeComponent(orderId)}/comprovante',
      {
        'tipoEnvio': channel == ReceiptChannel.whatsapp ? 'WHATSAPP' : 'EMAIL',
        'destinatario': destination,
      },
    );
    return response is Map && response['duplicado'] == true;
  }

  Future<AdminRefundResult> refund(String orderId) async =>
      AdminRefundResult.fromJson(
        Map<String, dynamic>.from(
          await client.post(
                '/admin/orders/${Uri.encodeComponent(orderId)}/refund',
                const <String, dynamic>{},
              )
              as Map,
        ),
      );
}
