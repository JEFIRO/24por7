import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final String? code;
  final Map<String, List<String>> fieldErrors;
  const ApiException(
    this.message, [
    this.statusCode,
    this.code,
    this.fieldErrors = const {},
  ]);

  String get friendlyMessage => switch (code) {
    'PRODUCT_CODE_ALREADY_EXISTS' => 'Código interno já utilizado.',
    'BARCODE_ALREADY_EXISTS' =>
      'Código de barras já está associado a outro produto.',
    'PRODUCT_NOT_FOUND' => 'Produto não encontrado.',
    'TENANT_MISMATCH' => 'O recurso não pertence à empresa atual.',
    'VALIDATION_ERROR' when fieldErrors.isNotEmpty =>
      fieldErrors.values.expand((messages) => messages).join('\n'),
    _ => message,
  };

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? httpClient, String? baseUrl})
    : _http = httpClient ?? http.Client(),
      baseUrl =
          (baseUrl ??
                  const String.fromEnvironment(
                    'API_URL',
                    defaultValue: 'http://localhost:8080',
                  ))
              .replaceFirst(RegExp(r'/$'), '');

  static final ApiClient instance = ApiClient();
  final http.Client _http;
  final String baseUrl;
  String? token = const String.fromEnvironment('API_TOKEN');
  Map<String, dynamic>? authenticatedUser;
  void Function()? onUnauthorized;

  bool get isAuthenticated => token?.isNotEmpty == true;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json; charset=utf-8',
    if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
  };

  Future<void> loginAdmin(String cpf, String senha) async {
    final data = await post('/auth/login/admin', {
      'cpf': cpf,
      'senha': senha,
    }, authenticated: false);
    final received = data is Map<String, dynamic>
        ? data['token']?.toString()
        : null;
    if (received == null || received.isEmpty) {
      throw const ApiException('O servidor não retornou um token de acesso');
    }
    token = received;
    authenticatedUser = data['user'] is Map
        ? Map<String, dynamic>.from(data['user'] as Map)
        : null;
  }

  void clearSession() {
    token = null;
    authenticatedUser = null;
  }

  Future<Uri> authenticatedRedirect(String path) async {
    if (!isAuthenticated) {
      throw const ApiException('Faça login para continuar', 401);
    }
    final request = http.Request('GET', Uri.parse('$baseUrl$path'))
      ..followRedirects = false
      ..headers.addAll(_headers);
    try {
      final response = await _http
          .send(request)
          .timeout(const Duration(seconds: 20));
      if (response.statusCode >= 300 && response.statusCode < 400) {
        final location = response.headers['location'];
        if (location != null && location.isNotEmpty) {
          return Uri.parse(location);
        }
      }
      final complete = await http.Response.fromStream(response);
      _decode(complete);
      throw const ApiException('O servidor não iniciou a vinculação');
    } catch (error) {
      if (error is ApiException) rethrow;
      throw const ApiException('Não foi possível iniciar a vinculação');
    }
  }

  Future<dynamic> get(String path, {Map<String, String?> query = const {}}) =>
      _send('GET', path, query: query);
  Future<dynamic> post(String path, Object body, {bool authenticated = true}) =>
      _send('POST', path, body: body, authenticated: authenticated);
  Future<dynamic> put(String path, Object body) =>
      _send('PUT', path, body: body);
  Future<dynamic> patch(String path, Object body) =>
      _send('PATCH', path, body: body);
  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> multipart(
    String method,
    String path, {
    required Map<String, String> fields,
    String? filePath,
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    if (token == null || token!.isEmpty) {
      throw const ApiException('Faça login para continuar', 401);
    }
    final request = http.MultipartRequest(method, Uri.parse('$baseUrl$path'));
    request.headers.addAll({
      if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
    });
    request.fields.addAll(fields);
    if (filePath != null) {
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
    } else if (fileBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName ?? 'arquivo.xlsx',
        ),
      );
    }
    try {
      final streamed = await _http
          .send(request)
          .timeout(const Duration(seconds: 20));
      final response = await http.Response.fromStream(streamed);
      return _decode(response);
    } catch (error) {
      if (error is ApiException) rethrow;
      throw const ApiException('Não foi possível conectar ao servidor');
    }
  }

  Future<dynamic> multipartJson(
    String method,
    String path, {
    required Object data,
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    if (token == null || token!.isEmpty) {
      throw const ApiException('Faça login para continuar', 401);
    }
    final request = http.MultipartRequest(method, Uri.parse('$baseUrl$path'));
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      http.MultipartFile.fromBytes(
        'data',
        utf8.encode(jsonEncode(data)),
        filename: 'data.json',
        contentType: MediaType('application', 'json'),
      ),
    );
    if (fileBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName ?? 'produto.jpg',
        ),
      );
    }
    try {
      final streamed = await _http
          .send(request)
          .timeout(const Duration(seconds: 20));
      return _decode(await http.Response.fromStream(streamed));
    } catch (error) {
      if (error is ApiException) rethrow;
      throw const ApiException('Não foi possível conectar ao servidor');
    }
  }

  Future<Uint8List> download(String path) async {
    if (token == null || token!.isEmpty) {
      throw const ApiException('Faça login para continuar', 401);
    }
    try {
      final response = await _http
          .get(
            Uri.parse('$baseUrl$path'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        _decode(response);
      }
      return response.bodyBytes;
    } catch (error) {
      if (error is ApiException) rethrow;
      throw const ApiException('Não foi possível baixar o arquivo');
    }
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String?> query = const {},
    bool authenticated = true,
  }) async {
    if (authenticated && (token == null || token!.isEmpty)) {
      throw const ApiException('Faça login para continuar', 401);
    }
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: {
        for (final entry in query.entries)
          if (entry.value != null) entry.key: entry.value!,
      },
    );
    late http.Response response;
    try {
      final request = http.Request(method, uri)..headers.addAll(_headers);
      if (body != null) request.body = jsonEncode(body);
      response = await _http
          .send(request)
          .timeout(const Duration(seconds: 20))
          .then(http.Response.fromStream);
    } catch (_) {
      throw const ApiException('Não foi possível conectar ao servidor');
    }
    return _decode(response);
  }

  dynamic _decode(http.Response response) {
    dynamic decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(utf8.decode(response.bodyBytes));
      } catch (_) {
        decoded = null;
      }
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401 && isAuthenticated) {
        clearSession();
        onUnauthorized?.call();
      }
      final message = decoded is Map
          ? (decoded['message'] ?? decoded['error'] ?? 'Operação não concluída')
                .toString()
          : 'Operação não concluída';
      final fields = <String, List<String>>{};
      if (decoded is Map && decoded['fieldErrors'] is Map) {
        for (final entry in (decoded['fieldErrors'] as Map).entries) {
          fields[entry.key.toString()] = entry.value is List
              ? (entry.value as List).map((item) => item.toString()).toList()
              : [entry.value.toString()];
        }
      }
      throw ApiException(
        message,
        response.statusCode,
        decoded is Map ? decoded['code']?.toString() : null,
        fields,
      );
    }
    return decoded;
  }
}
