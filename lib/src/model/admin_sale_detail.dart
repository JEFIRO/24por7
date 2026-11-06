import 'decimal_value.dart';

DecimalValue? _decimal(Object? value) =>
    value == null ? null : DecimalValue.fromJson(value);

DateTime? _date(Object? value) =>
    value == null ? null : DateTime.tryParse(value.toString());

String? _text(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

class AdminSaleDetail {
  const AdminSaleDetail({
    required this.id,
    required this.status,
    required this.criadaEm,
    required this.pagaEm,
    required this.condominioNome,
    required this.terminalNome,
    required this.terminalCodigo,
    required this.itens,
    required this.subtotal,
    required this.descontoPromocoes,
    required this.descontoCupom,
    required this.total,
    required this.pagamento,
    required this.reembolso,
    required this.podeReembolsar,
    required this.podeEnviarComprovante,
  });

  final String id;
  final String status;
  final DateTime? criadaEm;
  final DateTime? pagaEm;
  final String? condominioNome;
  final String? terminalNome;
  final String? terminalCodigo;
  final List<AdminSaleItem> itens;
  final DecimalValue? subtotal;
  final DecimalValue? descontoPromocoes;
  final DecimalValue? descontoCupom;
  final DecimalValue? total;
  final AdminSalePayment? pagamento;
  final AdminSaleRefund? reembolso;
  final bool podeReembolsar;
  final bool podeEnviarComprovante;

  factory AdminSaleDetail.fromJson(Map<String, dynamic> json) =>
      AdminSaleDetail(
        id: json['id']?.toString() ?? '',
        status: json['status']?.toString() ?? 'UNKNOWN',
        criadaEm: _date(json['criadaEm']),
        pagaEm: _date(json['pagaEm']),
        condominioNome: _text(json['condominioNome']),
        terminalNome: _text(json['terminalNome']),
        terminalCodigo: _text(json['terminalCodigo']),
        itens: (json['itens'] as List? ?? const [])
            .whereType<Map>()
            .map(
              (item) => AdminSaleItem.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList(),
        subtotal: _decimal(json['subtotal']),
        descontoPromocoes: _decimal(json['descontoPromocoes']),
        descontoCupom: _decimal(json['descontoCupom']),
        total: _decimal(json['total']),
        pagamento: json['pagamento'] is Map
            ? AdminSalePayment.fromJson(
                Map<String, dynamic>.from(json['pagamento'] as Map),
              )
            : null,
        reembolso: json['reembolso'] is Map
            ? AdminSaleRefund.fromJson(
                Map<String, dynamic>.from(json['reembolso'] as Map),
              )
            : null,
        podeReembolsar: json['podeReembolsar'] == true,
        podeEnviarComprovante: json['podeEnviarComprovante'] == true,
      );
}

class AdminSaleItem {
  const AdminSaleItem({
    required this.codigo,
    required this.descricao,
    required this.quantidade,
    required this.unidade,
    required this.valorUnitario,
    required this.desconto,
    required this.valorFinal,
  });
  final String? codigo;
  final String descricao;
  final DecimalValue? quantidade;
  final String? unidade;
  final DecimalValue? valorUnitario;
  final DecimalValue? desconto;
  final DecimalValue? valorFinal;

  factory AdminSaleItem.fromJson(Map<String, dynamic> json) => AdminSaleItem(
    codigo: _text(json['codigo']),
    descricao: _text(json['descricao']) ?? 'Produto',
    quantidade: _decimal(json['quantidade']),
    unidade: _text(json['unidade']),
    valorUnitario: _decimal(json['valorUnitario']),
    desconto: _decimal(json['desconto']),
    valorFinal: _decimal(json['valorFinal']),
  );
}

class AdminSalePayment {
  const AdminSalePayment({
    required this.status,
    required this.forma,
    required this.bandeira,
    required this.parcelas,
    required this.transacaoId,
    required this.nsu,
    required this.autorizacao,
  });
  final String? status;
  final String? forma;
  final String? bandeira;
  final int? parcelas;
  final String? transacaoId;
  final String? nsu;
  final String? autorizacao;

  factory AdminSalePayment.fromJson(Map<String, dynamic> json) =>
      AdminSalePayment(
        status: _text(json['status']),
        forma: _text(json['forma']),
        bandeira: _text(json['bandeira']),
        parcelas: (json['parcelas'] as num?)?.toInt(),
        transacaoId: _text(json['transacaoId']),
        nsu: _text(json['nsu']),
        autorizacao: _text(json['autorizacao']),
      );
}

class AdminSaleRefund {
  const AdminSaleRefund({
    required this.solicitadoEm,
    required this.confirmadoEm,
  });
  final DateTime? solicitadoEm;
  final DateTime? confirmadoEm;

  factory AdminSaleRefund.fromJson(Map<String, dynamic> json) =>
      AdminSaleRefund(
        solicitadoEm: _date(json['solicitadoEm']),
        confirmadoEm: _date(json['confirmadoEm']),
      );
}

enum ReceiptChannel { whatsapp, email }

class AdminRefundResult {
  const AdminRefundResult({required this.status, required this.confirmed});
  final String status;
  final bool confirmed;

  factory AdminRefundResult.fromJson(Map<String, dynamic> json) =>
      AdminRefundResult(
        status: json['status']?.toString() ?? '',
        confirmed: json['confirmed'] == true,
      );
}
