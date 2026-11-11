import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/widgets/app_refresh.dart';
import '../../core/formatters/app_formatters.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_content.dart';
import '../../core/widgets/async_state.dart';
import '../../core/widgets/status_badge.dart';
import '../model/admin_repository.dart';
import '../model/admin_sale_detail.dart';
import '../model/decimal_value.dart';

const saleStatusLabels = {
  'PROCESSED': 'Aprovada',
  'REFUNDED': 'Reembolsada',
  'PENDING': 'Pendente',
  'CREATED': 'Criada',
  'AT_TERMINAL': 'No terminal',
  'ACTION_REQUIRED': 'Ação necessária',
  'CANCELED': 'Cancelada',
  'EXPIRED': 'Expirada',
  'FAILED': 'Falhou',
};

AppStatusBadge saleStatusBadge(String status) => AppStatusBadge(
  label: saleStatusLabels[status] ?? status,
  tone: switch (status) {
    'PROCESSED' => AppStatusTone.success,
    'REFUNDED' => AppStatusTone.info,
    'PENDING' || 'CREATED' || 'AT_TERMINAL' => AppStatusTone.warning,
    'ACTION_REQUIRED' => AppStatusTone.info,
    'FAILED' => AppStatusTone.critical,
    _ => AppStatusTone.neutral,
  },
);

/// Identificador curto exibido para o operador (`#1A2B3C4D`).
String shortSaleId(String id) {
  final clean = id.replaceAll('-', '');
  final short = clean.length > 8 ? clean.substring(0, 8) : clean;
  return '#${short.toUpperCase()}';
}

/// Abre o detalhe da venda. Retorna `true` quando a venda mudou (reembolso).
class AdminSaleDetailPage extends StatefulWidget {
  const AdminSaleDetailPage({
    super.key,
    required this.orderId,
    this.repository,
  });
  final String orderId;
  final AdminRepository? repository;

  @override
  State<AdminSaleDetailPage> createState() => _AdminSaleDetailPageState();
}

class _AdminSaleDetailPageState extends State<AdminSaleDetailPage> {
  late final AdminRepository _repository =
      widget.repository ?? AdminRepository();
  AdminSaleDetail? _sale;
  String? _error;
  bool _loading = true;
  bool _working = false;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final sale = await _repository.saleDetail(widget.orderId);
      if (mounted) setState(() => _sale = sale);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _sendReceipt() async {
    final phone = await showDialog<String>(
      context: context,
      builder: (_) => const _SendReceiptDialog(),
    );
    if (phone == null || !mounted) return;
    setState(() => _working = true);
    try {
      final duplicate = await _repository.sendReceipt(
        widget.orderId,
        channel: ReceiptChannel.whatsapp,
        destination: phone,
      );
      _snack(
        duplicate
            ? 'Este comprovante já tinha sido enviado para esse número.'
            : 'Comprovante enviado.',
      );
    } catch (error) {
      if (mounted) _snack(error.toString());
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _refund() async {
    final sale = _sale!;
    final total = AppFormatters.currencyText(sale.total?.value ?? '0');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reembolsar venda?'),
        content: Text(
          'O valor integral de $total volta para o cliente pelo mesmo meio '
          'de pagamento. Essa ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reembolsar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _working = true);
    try {
      final result = await _repository.refund(widget.orderId);
      _changed = true;
      _snack(
        result.confirmed
            ? 'Reembolso confirmado.'
            : 'Reembolso solicitado. Aguardando confirmação do provedor.',
      );
      await _load();
    } catch (error) {
      if (mounted) _snack(error.toString());
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sale = _sale;
    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Detalhes da venda')),
        body: AppRefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              AppContent(
                child: _loading && sale == null
                    ? const AppLoadingState(
                        layout: AppSkeletonLayout.detail,
                        inline: true,
                      )
                    : _error != null && sale == null
                    ? AppErrorState(message: _error!, onRetry: _load)
                    : _body(context, sale!),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, AdminSaleDetail sale) {
    final theme = Theme.of(context);
    final mobile = AppBreakpoints.isMobile(context);
    final payment = sale.pagamento;
    final refund = sale.reembolso;
    final actions = [
      if (sale.podeEnviarComprovante)
        FilledButton.icon(
          onPressed: _working ? null : _sendReceipt,
          icon: const Icon(Icons.send_outlined, size: 18),
          label: const Text('Enviar comprovante'),
        ),
      if (sale.podeReembolsar)
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.error,
          ),
          onPressed: _working ? null : _refund,
          icon: const Icon(Icons.undo_outlined, size: 18),
          label: const Text('Solicitar reembolso'),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppPageHeader(
          title: AppFormatters.currencyText(sale.total?.value ?? '0'),
          subtitle:
              'Venda ${shortSaleId(sale.id)} · '
              '${AppFormatters.dateTime(sale.pagaEm ?? sale.criadaEm)}',
          actions: [saleStatusBadge(sale.status)],
        ),
        if (_working) ...[
          const SizedBox(height: AppSpacing.md),
          const LinearProgressIndicator(minHeight: 2),
        ],
        if (actions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: actions,
          ),
        ],
        if (refund != null) ...[
          const SizedBox(height: AppSpacing.lg),
          AppBanner(
            tone: refund.confirmadoEm != null
                ? AppStatusTone.info
                : AppStatusTone.warning,
            message: refund.confirmadoEm != null
                ? 'Reembolso confirmado em '
                      '${AppFormatters.dateTime(refund.confirmadoEm)}.'
                : 'Reembolso solicitado em '
                      '${AppFormatters.dateTime(refund.solicitadoEm)} e '
                      'aguardando confirmação do provedor.',
          ),
        ],
        const SizedBox(height: AppSpacing.xxl),
        AppKeyValueGrid(
          entries: [
            ('Criada em', AppFormatters.dateTime(sale.criadaEm)),
            ('Paga em', AppFormatters.dateTime(sale.pagaEm)),
            ('Condomínio', sale.condominioNome ?? 'Não informado'),
            (
              'Terminal',
              [
                sale.terminalNome,
                sale.terminalCodigo,
              ].whereType<String>().join(' · ').ifEmpty('Não informado'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _CopyableId(id: sale.id),
        const SizedBox(height: AppSpacing.xxl),
        AppSectionTitle(
          sale.itens.length == 1 ? 'Itens (1)' : 'Itens (${sale.itens.length})',
        ),
        if (sale.itens.isEmpty)
          Text(
            'Nenhum item registrado.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else if (mobile)
          for (final item in sale.itens)
            AppListRow(
              dense: true,
              title: item.descricao,
              meta:
                  '${_quantity(item)} × ${_money(item.valorUnitario)}'
                  '${_hasValue(item.desconto) ? ' · desconto ${_money(item.desconto)}' : ''}',
              trailing: Text(
                _money(item.valorFinal),
                style: tabularFigures.copyWith(fontWeight: FontWeight.w700),
              ),
            )
        else
          AppTable(
            columns: const [
              DataColumn(label: Text('Produto')),
              DataColumn(label: Text('Código')),
              DataColumn(label: Text('Qtd.'), numeric: true),
              DataColumn(label: Text('Unitário'), numeric: true),
              DataColumn(label: Text('Desconto'), numeric: true),
              DataColumn(label: Text('Total'), numeric: true),
            ],
            rows: [
              for (final item in sale.itens)
                DataRow(
                  cells: [
                    DataCell(Text(item.descricao)),
                    DataCell(Text(item.codigo ?? '—', style: tabularFigures)),
                    DataCell(Text(_quantity(item), style: tabularFigures)),
                    DataCell(
                      Text(_money(item.valorUnitario), style: tabularFigures),
                    ),
                    DataCell(
                      Text(
                        _hasValue(item.desconto) ? _money(item.desconto) : '—',
                        style: tabularFigures,
                      ),
                    ),
                    DataCell(
                      Text(
                        _money(item.valorFinal),
                        style: tabularFigures.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        const SizedBox(height: AppSpacing.lg),
        _Totals(sale: sale),
        if (payment != null) ...[
          const SizedBox(height: AppSpacing.xxl),
          const AppSectionTitle('Pagamento'),
          AppKeyValueGrid(
            entries: [
              ('Forma', _paymentMethod(payment)),
              if (payment.parcelas != null && payment.parcelas! > 1)
                ('Parcelas', '${payment.parcelas}x'),
              (
                'Status',
                saleStatusLabels[payment.status] ?? payment.status ?? '—',
              ),
              if (payment.transacaoId != null)
                ('Transação', payment.transacaoId!),
              if (payment.nsu != null) ('NSU', payment.nsu!),
              if (payment.autorizacao != null)
                ('Autorização', payment.autorizacao!),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  static String _paymentMethod(AdminSalePayment payment) {
    final parts = [payment.forma, payment.bandeira].whereType<String>();
    return parts.isEmpty ? 'Não informado' : parts.join(' · ');
  }

  static String _quantity(AdminSaleItem item) {
    final raw = item.quantidade?.value ?? '0';
    final number = num.tryParse(raw) ?? 0;
    final text = number == number.roundToDouble()
        ? number.toInt().toString()
        : number.toString().replaceAll('.', ',');
    return item.unidade == null || item.unidade == 'UN'
        ? text
        : '$text ${item.unidade!.toLowerCase()}';
  }
}

String _money(DecimalValue? value) =>
    AppFormatters.currencyText(value?.value ?? '0');

bool _hasValue(DecimalValue? value) =>
    value != null && (num.tryParse(value.value) ?? 0) != 0;

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

class _Totals extends StatelessWidget {
  const _Totals({required this.sale});
  final AdminSaleDetail sale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget line(String label, String value, {bool strong = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: strong
                  ? theme.textTheme.titleMedium
                  : theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
            ),
          ),
          Text(
            value,
            style:
                (strong
                        ? theme.textTheme.titleMedium
                        : theme.textTheme.bodyMedium)
                    ?.merge(tabularFigures)
                    .copyWith(fontWeight: strong ? FontWeight.w700 : null),
          ),
        ],
      ),
    );

    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          children: [
            if (sale.subtotal != null) line('Subtotal', _money(sale.subtotal)),
            if (_hasValue(sale.descontoPromocoes))
              line('Promoções', '− ${_money(sale.descontoPromocoes)}'),
            if (_hasValue(sale.descontoCupom))
              line('Cupom', '− ${_money(sale.descontoCupom)}'),
            line('Total', _money(sale.total), strong: true),
          ],
        ),
      ),
    );
  }
}

class _CopyableId extends StatelessWidget {
  const _CopyableId({required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: id));
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('ID da venda copiado.')));
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                'ID $id',
                style: theme.textTheme.bodySmall
                    ?.merge(tabularFigures)
                    .copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(
              Icons.copy_outlined,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _SendReceiptDialog extends StatefulWidget {
  const _SendReceiptDialog();

  @override
  State<_SendReceiptDialog> createState() => _SendReceiptDialogState();
}

class _SendReceiptDialogState extends State<_SendReceiptDialog> {
  final _form = GlobalKey<FormState>();
  final _phone = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  String? _validate(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Informe o telefone';
    return digits.length >= 10 && digits.length <= 13
        ? null
        : 'Informe DDD e número';
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    Navigator.pop(context, _phone.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // Rola o conteúdo quando o teclado reduz o espaço disponível.
      scrollable: true,
      title: const Text('Enviar comprovante'),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'O comprovante será enviado por WhatsApp.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _phone,
              autofocus: true,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.send,
              decoration: const InputDecoration(
                labelText: 'WhatsApp com DDD',
                hintText: '(11) 98765-4321',
                prefixIcon: Icon(Icons.chat_outlined),
              ),
              validator: _validate,
              onFieldSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Enviar')),
      ],
    );
  }
}
