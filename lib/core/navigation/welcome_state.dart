import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Controla a tela de boas-vindas: aparece uma vez por instalação, antes do
/// primeiro login.
abstract final class WelcomeState {
  static const _key = 'welcome_seen';
  static const _storage = FlutterSecureStorage();

  /// Ainda falta mostrar as boas-vindas. Só passa a valer depois de [load];
  /// fora da abertura real do app (ex.: testes) a tela não aparece.
  static bool pending = false;

  static Future<void> load() async {
    try {
      pending = await _storage.read(key: _key) == null;
    } catch (_) {
      // Sem armazenamento disponível, segue direto para o login.
      pending = false;
    }
  }

  static Future<void> markSeen() async {
    pending = false;
    try {
      await _storage.write(key: _key, value: '1');
    } catch (_) {
      // Na pior das hipóteses, as boas-vindas aparecem de novo.
    }
  }
}
