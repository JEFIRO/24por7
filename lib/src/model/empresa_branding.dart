import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme/branding_config.dart';
import 'api_client.dart';

/// Identidade visual da Empresa (GET/PUT /empresas/me/branding).
class EmpresaBranding {
  const EmpresaBranding({
    required this.nomeExibicao,
    this.logoUrl,
    this.logoDarkUrl,
    required this.corPrincipal,
    required this.corSecundaria,
    required this.corDestaque,
  });

  final String nomeExibicao;
  final String? logoUrl;
  final String? logoDarkUrl;
  final String corPrincipal;
  final String corSecundaria;
  final String corDestaque;

  /// Cores que o back devolve quando a Empresa nunca escolheu as suas.
  static const _defaultCores = ('#169DFF', '#62C8FF', '#00D084');

  bool get coresPersonalizadas =>
      (
        corPrincipal.toUpperCase(),
        corSecundaria.toUpperCase(),
        corDestaque.toUpperCase(),
      ) !=
      _defaultCores;

  factory EmpresaBranding.fromJson(Map<String, dynamic> json) {
    String? url(Object? v) {
      final s = v?.toString().trim();
      return s == null || s.isEmpty ? null : s;
    }

    return EmpresaBranding(
      nomeExibicao: json['nomeExibicao']?.toString() ?? '',
      logoUrl: url(json['logoUrl']),
      logoDarkUrl: url(json['logoDarkUrl']),
      corPrincipal: json['corPrincipal']?.toString() ?? _defaultCores.$1,
      corSecundaria: json['corSecundaria']?.toString() ?? _defaultCores.$2,
      corDestaque: json['corDestaque']?.toString() ?? _defaultCores.$3,
    );
  }

  Map<String, dynamic> toJson() => {
    'nomeExibicao': nomeExibicao.trim(),
    'logoUrl': logoUrl?.trim().isEmpty == true ? null : logoUrl?.trim(),
    'logoDarkUrl': logoDarkUrl?.trim().isEmpty == true
        ? null
        : logoDarkUrl?.trim(),
    'corPrincipal': corPrincipal.toUpperCase(),
    'corSecundaria': corSecundaria.toUpperCase(),
    'corDestaque': corDestaque.toUpperCase(),
  };

  /// Aplica sobre o padrão do app. Sem cores próprias, mantém o design system.
  BrandingConfig toConfig() {
    const base = BrandingConfig.fallback;
    final primary = coresPersonalizadas ? parseHexColor(corPrincipal) : null;
    final secondary = coresPersonalizadas ? parseHexColor(corSecundaria) : null;
    return BrandingConfig(
      displayName: nomeExibicao.trim().isEmpty
          ? base.displayName
          : nomeExibicao.trim(),
      primaryColor: primary ?? base.primaryColor,
      secondaryColor: secondary ?? base.secondaryColor,
      logoUrl: logoUrl,
      compactLogoUrl: logoUrl,
    );
  }
}

final _hex = RegExp(r'^#[0-9A-Fa-f]{6}$');

bool isHexColor(String value) => _hex.hasMatch(value.trim());

Color? parseHexColor(String value) {
  final v = value.trim();
  if (!isHexColor(v)) return null;
  return Color(int.parse('FF${v.substring(1)}', radix: 16));
}

/// Branding atual do painel; o MaterialApp reconstrói o tema quando muda.
final brandingNotifier = ValueNotifier<BrandingConfig>(BrandingConfig.fallback);

class BrandingRepository {
  BrandingRepository({ApiClient? client})
    : client = client ?? ApiClient.instance;
  final ApiClient client;

  Future<EmpresaBranding> buscar() async => EmpresaBranding.fromJson(
    Map<String, dynamic>.from(await client.get('/empresas/me/branding') as Map),
  );

  Future<EmpresaBranding> salvar(EmpresaBranding value) async {
    final saved = EmpresaBranding.fromJson(
      Map<String, dynamic>.from(
        await client.put('/empresas/me/branding', value.toJson()) as Map,
      ),
    );
    brandingNotifier.value = saved.toConfig();
    return saved;
  }

  /// Envia JPEG/PNG (até 5 MB) para o Object Storage e grava como logo.
  Future<EmpresaBranding> enviarLogo(
    Uint8List bytes,
    String fileName, {
    bool escuro = false,
  }) async {
    final saved = EmpresaBranding.fromJson(
      Map<String, dynamic>.from(
        await client.multipart(
              'POST',
              '/empresas/me/branding/logo?variante=${escuro ? 'escuro' : 'claro'}',
              fields: const {},
              fileBytes: bytes,
              fileName: fileName,
            )
            as Map,
      ),
    );
    brandingNotifier.value = saved.toConfig();
    return saved;
  }

  Future<EmpresaBranding> removerLogo({bool escuro = false}) async {
    final saved = EmpresaBranding.fromJson(
      Map<String, dynamic>.from(
        await client.delete(
              '/empresas/me/branding/logo?variante=${escuro ? 'escuro' : 'claro'}',
            )
            as Map,
      ),
    );
    brandingNotifier.value = saved.toConfig();
    return saved;
  }
}

/// Mesmo limite do back (app.storage.image.max-size).
const maxLogoBytes = 5 * 1024 * 1024;

/// Carrega o branding da Empresa logada. Falha não impede o uso do painel.
Future<void> loadBranding([BrandingRepository? repository]) async {
  if (!(repository?.client ?? ApiClient.instance).isAuthenticated) return;
  try {
    final branding = await (repository ?? BrandingRepository()).buscar();
    brandingNotifier.value = branding.toConfig();
  } catch (error) {
    // Mantém o branding atual; o erro fica no console para diagnóstico.
    debugPrint('[branding] falha ao carregar /empresas/me/branding: $error');
  }
}

void resetBranding() => brandingNotifier.value = BrandingConfig.fallback;

/// Perfil do usuário logado (PUT /user/{id}, GET /user/{id}).
class PerfilRepository {
  PerfilRepository({ApiClient? client}) : client = client ?? ApiClient.instance;
  final ApiClient client;

  String get _userId {
    final id = client.authenticatedUser?['userId']?.toString();
    if (id == null || id.isEmpty) {
      throw const ApiException('Faça login novamente para editar o perfil');
    }
    return id;
  }

  Future<void> salvar({
    required String nome,
    required String sobrenome,
    required String email,
    String? telefone,
  }) async {
    final id = _userId;
    final tel = telefone?.trim() ?? '';
    await client.put('/user/$id', {
      'nome': nome.trim(),
      'sobrenome': sobrenome.trim(),
      'email': email.trim(),
      if (tel.isNotEmpty) 'telefone': tel,
    });
    final user = await client.get('/user/$id');
    if (user is Map) {
      await client.updateAuthenticatedUser(Map<String, dynamic>.from(user));
    }
  }
}
