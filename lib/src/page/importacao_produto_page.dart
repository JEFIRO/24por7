import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final resultado = _resultado;
    return Scaffold(
      appBar: AppBar(title: const Text('Importar produtos')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _Passos(),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _loading ? null : _baixarModelo,
            icon: const Icon(Icons.download),
            label: const Text('BAIXAR MODELO XLSX'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _loading ? null : _selecionar,
            icon: const Icon(Icons.attach_file),
            label: Text(_arquivo?.name ?? 'SELECIONAR ARQUIVO'),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _loading || _arquivo == null ? null : _validar,
            icon: const Icon(Icons.rule),
            label: const Text('VALIDAR PLANILHA'),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_error!),
                ),
              ),
            ),
          if (resultado != null) ...[
            const SizedBox(height: 16),
            _ResumoImportacao(resultado),
            const SizedBox(height: 12),
            Text(
              'Resultado por linha',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...resultado.preview.map(
              (linha) => Card(
                child: ListTile(
                  leading: Icon(
                    linha.status == 'ERRO'
                        ? Icons.error
                        : linha.status == 'IMPORTADO'
                        ? Icons.check_circle
                        : Icons.check,
                    color: linha.status == 'ERRO' ? Colors.red : Colors.green,
                  ),
                  title: Text(
                    '${linha.aba} • Linha ${linha.linha} • ${linha.codigoInterno ?? "sem SKU"}',
                  ),
                  subtitle: Text(linha.mensagem ?? linha.status),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (resultado.podeConfirmar)
              FilledButton.icon(
                onPressed: _loading ? null : _confirmar,
                icon: const Icon(Icons.upload),
                label: const Text('CONFIRMAR IMPORTAÇÃO'),
              ),
            if (resultado.totalErros > 0)
              OutlinedButton.icon(
                onPressed: _loading ? null : _verErros,
                icon: const Icon(Icons.error_outline),
                label: const Text('VER APENAS ERROS'),
              ),
            if (resultado.concluida)
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.done),
                label: const Text('VOLTAR AOS PRODUTOS'),
              ),
          ],
        ],
      ),
    );
  }
}

class _Passos extends StatelessWidget {
  const _Passos();
  @override
  Widget build(BuildContext context) => const Card(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Text(
        '1. Baixe o modelo\n2. Preencha a planilha\n3. Selecione o arquivo\n4. Valide\n5. Revise todos os erros\n6. Confirme a importação',
      ),
    ),
  );
}

class _ResumoImportacao extends StatelessWidget {
  const _ResumoImportacao(this.value);
  final ImportacaoProduto value;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value.nomeArquivo,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text('Status: ${value.status.replaceAll('_', ' ')}'),
          Text(
            '${value.totalValidas} produtos válidos • ${value.totalAvisos} avisos • ${value.totalErros} erros',
          ),
          if (value.concluida)
            Text(
              '${value.produtosImportados} produtos • ${value.barcodesImportados} códigos • ${value.estoquesCriados} saldos iniciais',
            ),
        ],
      ),
    ),
  );
}
