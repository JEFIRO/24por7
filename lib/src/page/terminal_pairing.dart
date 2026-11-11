import 'package:flutter/material.dart';

import '../../core/widgets/app_feedback.dart';
import '../../core/theme/app_tokens.dart';
import '../model/api_client.dart';
import '../model/operational_repository.dart';
import 'scanner_page.dart';

const _qrPrefix = 'APP247-PAIR:';
final _invalidChars = RegExp('[^A-Z0-9]');

/// Normaliza o que veio do QR ou da digitação para `XXXX-XXXX`.
/// Aceita o conteúdo inteiro do QR, minúsculas, espaços e sem hífen.
String? parsePairingCode(String? raw) {
  if (raw == null) return null;
  var value = raw.trim().toUpperCase();
  if (value.startsWith(_qrPrefix)) value = value.substring(_qrPrefix.length);
  value = value.replaceAll(_invalidChars, '');
  if (value.length != 8) return null;
  return '${value.substring(0, 4)}-${value.substring(4)}';
}

/// Mensagens dos erros de pareamento do backend.
String pairingErrorMessage(Object error) {
  if (error is! ApiException) return error.toString();
  return switch (error.code) {
    'PAIRING_CODE_INVALID' =>
      'Código inválido ou expirado. Confira o código na tela do Terminal.',
    'TERMINAL_SERIAL_IN_USE' =>
      'Este equipamento já está vinculado a outro Terminal.',
    'TERMINAL_ACTIVE_PAYMENTS' =>
      'O Terminal tem um pagamento em andamento. Aguarde a conclusão.',
    'TERMINAL_NOT_ACTIVE' => 'Terminal desativado não pode ser pareado.',
    'PAIRING_RATE_LIMITED' =>
      'Muitos códigos inválidos. Aguarde alguns minutos e tente de novo.',
    'PAIRING_UNAVAILABLE' =>
      'Pareamento indisponível no momento. Tente novamente.',
    _ => error.friendlyMessage,
  };
}

/// Campo do código de pareamento com leitor de QR. Digitar continua possível
/// quando a câmera não está disponível.
class PairingCodeField extends StatelessWidget {
  const PairingCodeField({
    required this.controller,
    this.required = false,
    this.enabled = true,
    super.key,
  });

  final TextEditingController controller;
  final bool required;
  final bool enabled;

  Future<void> _scan(BuildContext context) async {
    final raw = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const ScannerPage(
          title: 'Parear Terminal',
          hint: 'Aponte para o QR Code na tela do Terminal',
        ),
      ),
    );
    if (raw == null) return;
    final code = parsePairingCode(raw);
    if (code == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Este QR Code não é de pareamento do Terminal.'),
          ),
        );
      }
      return;
    }
    controller.text = code;
  }

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    enabled: enabled,
    textCapitalization: TextCapitalization.characters,
    decoration: InputDecoration(
      labelText: required
          ? 'Código de pareamento'
          : 'Código de pareamento (opcional)',
      hintText: 'XXXX-XXXX',
      helperText: 'Mostrado na tela do Terminal. Escaneie o QR ou digite.',
      suffixIcon: IconButton(
        tooltip: 'Ler QR Code',
        onPressed: enabled ? () => _scan(context) : null,
        icon: const Icon(Icons.qr_code_scanner),
      ),
    ),
    validator: (value) {
      if (value == null || value.trim().isEmpty) {
        return required ? 'Informe o código mostrado no Terminal' : null;
      }
      return parsePairingCode(value) == null
          ? 'Código deve ter 8 letras ou números'
          : null;
    },
  );
}

/// Pareia (ou re-pareia) um Terminal já cadastrado. Re-parear gera credencial
/// nova no equipamento e invalida a anterior.
Future<bool?> showTerminalPairingDialog(
  BuildContext context, {
  required OperationalRepository repository,
  required TerminalAdmin terminal,
}) => showDialog<bool>(
  context: context,
  builder: (_) =>
      _TerminalPairingDialog(repository: repository, terminal: terminal),
);

class _TerminalPairingDialog extends StatefulWidget {
  const _TerminalPairingDialog({
    required this.repository,
    required this.terminal,
  });

  final OperationalRepository repository;
  final TerminalAdmin terminal;

  @override
  State<_TerminalPairingDialog> createState() => _TerminalPairingDialogState();
}

class _TerminalPairingDialogState extends State<_TerminalPairingDialog> {
  final _form = GlobalKey<FormState>();
  final _code = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _pair() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.repository.parearTerminal(
        widget.terminal.id,
        parsePairingCode(_code.text)!,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _error = pairingErrorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final paired = widget.terminal.serialNumber?.isNotEmpty == true;
    return AlertDialog(
      title: Text('Parear ${widget.terminal.nome}'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                paired
                    ? 'Use quando trocar o equipamento ou após um reset. '
                          'O equipamento atual deixa de funcionar.'
                    : 'Ligue o Terminal e use o código mostrado na tela.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              PairingCodeField(
                controller: _code,
                required: true,
                enabled: !_loading,
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _loading ? null : _pair,
          icon: AppBusyIcon(busy: _loading, icon: Icons.link),
          label: Text(_loading ? 'Pareando…' : 'Parear'),
        ),
      ],
    );
  }
}
