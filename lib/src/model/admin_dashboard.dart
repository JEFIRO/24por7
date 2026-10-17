import 'decimal_value.dart';

class AdminDashboard {
  const AdminDashboard({
    required this.empresaNome,
    required this.usuarioNome,
    required this.geradoEm,
    required this.vendasHoje,
    required this.terminais,
    required this.alertas,
    required this.estoque,
    required this.pagamentos,
    required this.onboarding,
    required this.atividadeRecente,
  });

  final String empresaNome;
  final String usuarioNome;
  final DateTime? geradoEm;
  final AdminSalesSummary vendasHoje;
  final AdminTerminalSummary terminais;
  final AdminAlertSummary alertas;
  final AdminStockSummary estoque;
  final AdminPaymentAttention pagamentos;
  final AdminOnboardingStatus onboarding;
  final List<AdminActivity> atividadeRecente;

  factory AdminDashboard.fromJson(Map<String, dynamic> json) => AdminDashboard(
    empresaNome: json['empresaNome']?.toString() ?? 'Empresa',
    usuarioNome: json['usuarioNome']?.toString() ?? 'Administrador',
    geradoEm: DateTime.tryParse(json['geradoEm']?.toString() ?? ''),
    vendasHoje: AdminSalesSummary.fromJson(_map(json['vendasHoje'])),
    terminais: AdminTerminalSummary.fromJson(_map(json['terminais'])),
    alertas: AdminAlertSummary.fromJson(_map(json['alertas'])),
    estoque: AdminStockSummary.fromJson(_map(json['estoque'])),
    pagamentos: AdminPaymentAttention.fromJson(_map(json['pagamentos'])),
    onboarding: AdminOnboardingStatus.fromJson(_map(json['onboarding'])),
    atividadeRecente: (json['atividadeRecente'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => AdminActivity.fromJson(Map<String, dynamic>.from(item)))
        .toList(),
  );
}

class AdminSalesSummary {
  const AdminSalesSummary({
    required this.quantidadeVendas,
    required this.faturamento,
    required this.ticketMedio,
  });
  final int quantidadeVendas;
  final DecimalValue faturamento;
  final DecimalValue ticketMedio;

  factory AdminSalesSummary.fromJson(Map<String, dynamic> json) =>
      AdminSalesSummary(
        quantidadeVendas: (json['quantidadeVendas'] as num?)?.toInt() ?? 0,
        faturamento: DecimalValue.fromJson(json['faturamento']),
        ticketMedio: DecimalValue.fromJson(json['ticketMedio']),
      );
}

class AdminTerminalSummary {
  const AdminTerminalSummary({
    required this.total,
    required this.online,
    required this.offline,
    required this.comAlerta,
  });
  final int total;
  final int online;
  final int offline;
  final int comAlerta;
  factory AdminTerminalSummary.fromJson(Map<String, dynamic> json) =>
      AdminTerminalSummary(
        total: (json['total'] as num?)?.toInt() ?? 0,
        online: (json['online'] as num?)?.toInt() ?? 0,
        offline: (json['offline'] as num?)?.toInt() ?? 0,
        comAlerta: (json['comAlerta'] as num?)?.toInt() ?? 0,
      );
}

class AdminAlertSummary {
  const AdminAlertSummary({
    required this.ativos,
    required this.info,
    required this.warning,
    required this.critical,
  });
  final int ativos;
  final int info;
  final int warning;
  final int critical;
  factory AdminAlertSummary.fromJson(Map<String, dynamic> json) =>
      AdminAlertSummary(
        ativos: (json['ativos'] as num?)?.toInt() ?? 0,
        info: (json['info'] as num?)?.toInt() ?? 0,
        warning: (json['warning'] as num?)?.toInt() ?? 0,
        critical: (json['critical'] as num?)?.toInt() ?? 0,
      );
}

class AdminStockSummary {
  const AdminStockSummary({
    required this.regraConfigurada,
    this.produtosBaixoEstoque,
    this.motivoIndisponibilidade,
  });
  final bool regraConfigurada;
  final int? produtosBaixoEstoque;
  final String? motivoIndisponibilidade;
  factory AdminStockSummary.fromJson(Map<String, dynamic> json) =>
      AdminStockSummary(
        regraConfigurada: json['regraConfigurada'] == true,
        produtosBaixoEstoque: (json['produtosBaixoEstoque'] as num?)?.toInt(),
        motivoIndisponibilidade: json['motivoIndisponibilidade']?.toString(),
      );
}

class AdminPaymentAttention {
  const AdminPaymentAttention({required this.precisamAtencao});
  final int precisamAtencao;
  factory AdminPaymentAttention.fromJson(Map<String, dynamic> json) =>
      AdminPaymentAttention(
        precisamAtencao: (json['precisamAtencao'] as num?)?.toInt() ?? 0,
      );
}

class AdminOnboardingStatus {
  const AdminOnboardingStatus({
    required this.empresaCadastrada,
    required this.condominioCadastrado,
    required this.terminalAtivado,
    required this.mercadoPagoVinculado,
    required this.pointVinculada,
    required this.produtosCadastrados,
    required this.produtosAssociadosCondominio,
  });
  final bool empresaCadastrada;
  final bool condominioCadastrado;
  final bool terminalAtivado;
  final bool mercadoPagoVinculado;
  final bool pointVinculada;
  final bool produtosCadastrados;
  final bool produtosAssociadosCondominio;

  factory AdminOnboardingStatus.fromJson(Map<String, dynamic> json) =>
      AdminOnboardingStatus(
        empresaCadastrada: json['empresaCadastrada'] == true,
        condominioCadastrado: json['condominioCadastrado'] == true,
        terminalAtivado: json['terminalAtivado'] == true,
        mercadoPagoVinculado: json['mercadoPagoVinculado'] == true,
        pointVinculada: json['pointVinculada'] == true,
        produtosCadastrados: json['produtosCadastrados'] == true,
        produtosAssociadosCondominio:
            json['produtosAssociadosCondominio'] == true,
      );
}

class AdminActivity {
  const AdminActivity({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.descricao,
    required this.destino,
    required this.ocorridoEm,
  });
  final String id;
  final String tipo;
  final String titulo;
  final String descricao;
  final String destino;
  final DateTime? ocorridoEm;
  factory AdminActivity.fromJson(Map<String, dynamic> json) => AdminActivity(
    id: json['id']?.toString() ?? '',
    tipo: json['tipo']?.toString() ?? 'INFO',
    titulo: json['titulo']?.toString() ?? 'Atividade',
    descricao: json['descricao']?.toString() ?? '',
    destino: json['destino']?.toString() ?? '/dashboard',
    ocorridoEm: DateTime.tryParse(json['ocorridoEm']?.toString() ?? ''),
  );
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
