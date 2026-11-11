import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/widgets/app_feedback.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_content.dart';
import '../../core/widgets/status_badge.dart';
import '../model/importacao_produto.dart';
import '../model/importacao_produto_repository.dart';

class ImportacaoProdutoPage extends StatefulWidget {
  const ImportacaoProdutoPage({super.key, this.repository});
  final ImportacaoProdutoRepository? repository;

  @override
  State<ImportacaoProdutoPage> createState() => _ImportacaoProdutoPageState();
}

class _ImportacaoProdutoPageState extends State<ImportacaoProdutoPage> {
  late final ImportacaoProdutoRepository _repository;
  PlatformFile? _arquivo;
  ImportacaoProduto? _resultado;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ImportacaoProdutoRepository();
  }

  Future<void> _baixarModelo() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bytes = await _repository.baixarModelo();
      await FilePicker.saveFile(
        fileName: 'app247-importacao-produtos.xlsx',
        bytes: bytes,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selecionar() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['xlsx'],
      );
      if (file != null && mounted) {
        setState(() {
          _arquivo = file;
          _resultado = null;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  Future<void> _validar() async {
    final file = _arquivo;
    if (file == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resultado = await _repository.validar(
        await file.readAsBytes(),
        file.name,
      );
      if (mounted) setState(() => _resultado = resultado);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmar() async {
    final current = _resultado;
    if (current == null || !current.podeConfirmar) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      var resultado = await _repository.confirmar(current.id);
      for (
        var tentativa = 0;
        tentativa < 60 && resultado.processando;
        tentativa++
      ) {
        await Future<void>.delayed(const Duration(seconds: 2));
        resultado = await _repository.buscar(current.id);
      }
      if (resultado.processando) {
        throw TimeoutException(
          'A importação continua em processamento. Consulte novamente em alguns instantes.',
        );
      }
      if (mounted) setState(() => _resultado = resultado);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verErros() async {
    final current = _resultado;
    if (current == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resultado = await _repository.erros(current.id);
      if (mounted) setState(() => _resultado = resultado);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _step {
    final resultado = _resultado;
    if (resultado?.concluida == true) return 4;
    if (resultado != null) return 3;
    if (_arquivo != null) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final resultado = _resultado;
    final theme = Theme.of(context);
    final source = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _loading ? null : _baixarModelo,
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Baixar modelo XLSX'),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _DropArea(
          fileName: _arquivo?.name,
          onTap: _loading ? null : _selecionar,
        ),
        const SizedBox(height: AppSpacing.lg),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: _loading || _arquivo == null ? null : _validar,
            icon: const Icon(Icons.rule, size: 18),
            label: const Text('Validar planilha'),
          ),
        ),
      ],
    );
    final result = resultado == null
        ? Text(
            'Valide a planilha para ver o resultado por linha antes de importar.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSectionTitle(
                'Resultado por linha',
                subtitle: resultado.nomeArquivo,
              ),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  AppStatusBadge(
                    label: '${resultado.totalValidas} válidas',
                    tone: AppStatusTone.success,
                  ),
                  if (resultado.totalAvisos > 0)
                    AppStatusBadge(
                      label: '${resultado.totalAvisos} avisos',
                      tone: AppStatusTone.warning,
                    ),
                  AppStatusBadge(
                    label: '${resultado.totalErros} erros',
                    tone: resultado.totalErros > 0
                        ? AppStatusTone.critical
                        : AppStatusTone.neutral,
                  ),
                ],
              ),
              if (resultado.concluida) ...[
                const SizedBox(height: AppSpacing.md),
                AppBanner(
                  tone: AppStatusTone.success,
                  message:
                      'Importação concluída: ${resultado.produtosImportados} produtos, '
                      '${resultado.barcodesImportados} códigos e ${resultado.estoquesCriados} saldos iniciais.',
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              for (final linha in resultado.preview)
                AppListRow(
                  dense: true,
                  title:
                      'Linha ${linha.linha} · ${linha.codigoInterno ?? 'sem SKU'}',
                  meta: [
                    linha.aba,
                    if (linha.mensagem != null) linha.mensagem!,
                  ].join(' · '),
                  trailing: switch (linha.status) {
                    'ERRO' => const AppStatusBadge(
                      label: 'Erro',
                      tone: AppStatusTone.critical,
                    ),
                    'IMPORTADO' => const AppStatusBadge(
                      label: 'Importado',
                      tone: AppStatusTone.success,
                    ),
                    'AVISO' => const AppStatusBadge(
                      label: 'Aviso',
                      tone: AppStatusTone.warning,
                    ),
                    _ => const AppStatusBadge(
                      label: 'Válida',
                      tone: AppStatusTone.success,
                    ),
                  },
                ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  if (resultado.totalErros > 0)
                    OutlinedButton(
                      onPressed: _loading ? null : _verErros,
                      child: const Text('Ver apenas erros'),
                    ),
                  if (resultado.podeConfirmar)
                    FilledButton(
                      onPressed: _loading ? null : _confirmar,
                      child: Text(
                        'Confirmar importação (${resultado.totalValidas})',
                      ),
                    ),
                ],
              ),
            ],
          );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Importar produtos'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: TextButton(
              onPressed: () =>
                  Navigator.pop(context, resultado?.concluida == true),
              child: const Text('Voltar aos produtos'),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          AppContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Passos(current: _step),
                const SizedBox(height: AppSpacing.xl),
                if (_loading) ...[
                  const LinearProgressIndicator(minHeight: 2),
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (_error != null) ...[
                  AppBanner(tone: AppStatusTone.critical, message: _error!),
                  const SizedBox(height: AppSpacing.lg),
                ],
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 900) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          source,
                          const SizedBox(height: AppSpacing.xxl),
                          result,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 360, child: source),
                        const SizedBox(width: AppSpacing.section),
                        Expanded(child: result),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Passos extends StatelessWidget {
  const _Passos({required this.current});
  final int current;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const steps = [
      'Baixar modelo',
      'Selecionar arquivo',
      'Validar',
      'Confirmar',
    ];
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < steps.length; i++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppStepDot(
                number: i + 1,
                current: i + 1 == current,
                done: i + 1 < current,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                steps[i],
                style: theme.textTheme.labelLarge?.copyWith(
                  color: i + 1 == current
                      ? scheme.onSurface
                      : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _DropArea extends StatelessWidget {
  const _DropArea({required this.fileName, required this.onTap});
  final String? fileName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: theme.colorScheme.outline, width: 1.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              Icon(
                fileName == null
                    ? Icons.upload_file_outlined
                    : Icons.description_outlined,
                size: 40,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                fileName ?? 'Selecionar arquivo XLSX',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall,
              ),
              Text(
                fileName == null
                    ? 'Use o modelo oficial preenchido'
                    : 'Toque para trocar o arquivo',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
