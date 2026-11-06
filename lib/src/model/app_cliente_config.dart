import 'api_client.dart';
import 'decimal_value.dart';

/// Só ADMIN e GERENTE gerenciam o App Cliente (AdminAppClienteController).
bool canManageAppCliente([ApiClient? client]) {
  final role = (client ?? ApiClient.instance).authenticatedUser?['role'];
  return role == 'ADMIN' || role == 'GERENTE';
}

class AppClienteConfig {
  const AppClienteConfig({
    required this.catalogoAtivo,
    required this.promocoesAtivas,
    required this.fidelidadeAtiva,
    required this.qrIdentificacaoAtivo,
    required this.preferenciasAtivas,
    required this.suporteAtivo,
    this.updatedAt,
  });

  final bool catalogoAtivo;
  final bool promocoesAtivas;
  final bool fidelidadeAtiva;
  final bool qrIdentificacaoAtivo;
  final bool preferenciasAtivas;
  final bool suporteAtivo;
  final DateTime? updatedAt;

  factory AppClienteConfig.fromJson(Map<String, dynamic> json) =>
      AppClienteConfig(
        catalogoAtivo: json['catalogoAtivo'] == true,
        promocoesAtivas: json['promocoesAtivas'] == true,
        fidelidadeAtiva: json['fidelidadeAtiva'] == true,
        qrIdentificacaoAtivo: json['qrIdentificacaoAtivo'] == true,
        preferenciasAtivas: json['preferenciasAtivas'] == true,
        suporteAtivo: json['suporteAtivo'] == true,
        updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
      );

  Map<String, dynamic> toJson() => {
    'catalogoAtivo': catalogoAtivo,
    'promocoesAtivas': promocoesAtivas,
    'fidelidadeAtiva': fidelidadeAtiva,
    'qrIdentificacaoAtivo': qrIdentificacaoAtivo,
    'preferenciasAtivas': preferenciasAtivas,
    'suporteAtivo': suporteAtivo,
  };
}

/// Modo de fidelidade aceito pelo back: NONE, POINTS ou CASHBACK.
class FidelidadeConfig {
  const FidelidadeConfig({
    required this.ativo,
    required this.modo,
    this.pontosPorReal,
    this.cashbackPercentual,
  });

  final bool ativo;
  final String modo;
  final DecimalValue? pontosPorReal;
  final DecimalValue? cashbackPercentual;

  factory FidelidadeConfig.fromJson(Map<String, dynamic> json) =>
      FidelidadeConfig(
        ativo: json['ativo'] == true,
        modo: json['modo']?.toString() ?? 'NONE',
        pontosPorReal: json['pontosPorReal'] == null
            ? null
            : DecimalValue.fromJson(json['pontosPorReal']),
        cashbackPercentual: json['cashbackPercentual'] == null
            ? null
            : DecimalValue.fromJson(json['cashbackPercentual']),
      );

  Map<String, dynamic> toJson() => {
    'ativo': ativo,
    'modo': modo,
    'pontosPorReal': pontosPorReal?.persistence,
    'cashbackPercentual': cashbackPercentual?.persistence,
  };
}

class AppClienteRepository {
  AppClienteRepository({ApiClient? client})
    : client = client ?? ApiClient.instance;
  final ApiClient client;

  Future<AppClienteConfig> config() async => AppClienteConfig.fromJson(
    Map<String, dynamic>.from(
      await client.get('/admin/app-cliente/config') as Map,
    ),
  );

  /// O GET /config não traz modo nem valores da fidelidade.
  Future<FidelidadeConfig> fidelidade() async => FidelidadeConfig.fromJson(
    Map<String, dynamic>.from(
      await client.get('/admin/app-cliente/fidelidade') as Map,
    ),
  );

  Future<void> salvarFidelidade(FidelidadeConfig value) =>
      client.put('/admin/app-cliente/fidelidade', value.toJson());

  Future<void> salvarConfig(AppClienteConfig value) =>
      client.put('/admin/app-cliente/config', value.toJson());
}
