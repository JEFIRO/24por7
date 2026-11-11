import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/formatters/app_formatters.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_content.dart';
import '../../core/widgets/status_badge.dart';
import '../model/nota_fiscal_entrada.dart';
import '../model/nota_fiscal_entrada_repository.dart';
import '../model/produto.dart';
import '../model/produto_repository.dart';
import 'scanner_page.dart';

/// Entrada de mercadoria pela NF-e do fornecedor: chave do DANFE ou XML, revisão
/// item a item e, ao confirmar, produtos novos no catálogo e ENTRADA no estoque central.
class NotaFiscalEntradaPage extends StatefulWidget {
  const NotaFiscalEntradaPage({super.key, this.repository, this.produtos});
  final NotaFiscalEntradaRepository? repository;
  final Future<List<Produto>> Function()? produtos;

  @override
  State<NotaFiscalEntradaPage> createState() => _NotaFiscalEntradaPageState();
}

class _NotaFiscalEntradaPageState extends State<NotaFiscalEntradaPage> {
  late final NotaFiscalEntradaRepository _repository;
  final _chave = TextEditingController();
  ChaveAcessoNfe? _consulta;
  NotaFiscalEntrada? _nota;
  List<Produto>? _catalogo;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? NotaFiscalEntradaRepository();
  }

  @override
  void dispose() {
    _chave.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _digitos => _chave.text.replaceAll(RegExp(r'\D'), '');

  Future<void> _escanear() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const ScannerPage(
          title: 'Chave da NF-e',
          hint: 'Aponte para o código de barras do DANFE',
        ),
      ),
    );
    if (code == null || !mounted) return;
    _chave.text = code.replaceAll(RegExp(r'\D'), '');
    await _consultar();
  }

  Future<void> _consultar() async {
    if (_digitos.length != 44) {
      setState(() => _error = 'A chave de acesso deve ter 44 dígitos');
      return;
    }
    await _run(() async {
      final consulta = await _repository.consultarChave(_digitos);
      if (mounted) setState(() => _consulta = consulta);
    });
  }

  Future<void> _abrir(String id) =>
      _run(() async => _mostrar(await _repository.buscar(id)));

  Future<void> _buscarNaSefaz() =>
      _run(() async => _mostrar(await _repository.importarPorChave(_digitos)));

  Future<void> _enviarXml() async {
    PlatformFile? file;
    try {
      file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['xml'],
      );
    } catch (error) {
      setState(() => _error = error.toString());
      return;
    }
    if (file == null || !mounted) return;
    final selected = file;
    await _run(
      () async => _mostrar(
        await _repository.enviarXml(
          await selected.readAsBytes(),
          selected.name,
        ),
      ),
    );
  }

  void _mostrar(NotaFiscalEntrada nota) {
    if (!mounted) return;
    setState(() {
      _nota = nota;
      _chave.text = nota.chave;
    });
  }

  Future<void> _confirmar() async {
    final nota = _nota;
    if (nota == null || !nota.podeConfirmar) return;
    await _run(() async => _mostrar(await _repository.confirmar(nota.id)));
  }

  void _novaNota() => setState(() {
    _nota = null;
    _consulta = null;
    _error = null;
    _chave.clear();
  });

  Future<void> _editar(NotaFiscalItem item) async {
    final nota = _nota;
    if (nota == null || nota.concluida) return;
    if (_catalogo == null) {
      try {
        _catalogo = await (widget.produtos ?? ProdutoRepository().listar)();
      } catch (_) {
        _catalogo = const [];
      }
    }
    if (!mounted) return;
    final ajuste = await showModalBottomSheet<_Ajuste>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ItemEditor(item: item, catalogo: _catalogo!),
    );
    if (ajuste == null) return;
    await _run(
      () async => _mostrar(
        await _repository.ajustarItem(
          nota.id,
          item.id,
          acao: ajuste.acao,
          produtoId: ajuste.produtoId,
          nomeProduto: ajuste.nomeProduto,
          precoVenda: ajuste.precoVenda,
          categoria: ajuste.categoria,
          fatorConversao: ajuste.fatorConversao,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nota = _nota;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Importar NF-e'),
        actions: [
          if (nota != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: TextButton(
                onPressed: _loading ? null : _novaNota,
                child: const Text('Ler outra NF-e'),
              ),
            ),
        ],
      ),
      body: ListView(
        children: [
          AppContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_loading) ...[
                  const LinearProgressIndicator(minHeight: 2),
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (_error != null) ...[
                  AppBanner(tone: AppStatusTone.critical, message: _error!),
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (nota == null)
                  _entrada(context)
                else
                  _revisao(context, nota),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _entrada(BuildContext context) {
    final theme = Theme.of(context);
    final consulta = _consulta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppSectionTitle(
          'Chave de acesso',
          subtitle:
              'Os 44 dígitos impressos no DANFE, abaixo do código de barras',
        ),
        TextField(
          controller: _chave,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d ]')),
            LengthLimitingTextInputFormatter(54),
          ],
          decoration: InputDecoration(
            labelText: 'Chave da NF-e',
            hintText: '0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000',
            suffixIcon: IconButton(
              tooltip: 'Ler código de barras do DANFE',
              onPressed: _loading ? null : _escanear,
              icon: const Icon(Icons.qr_code_scanner),
            ),
          ),
          onSubmitted: (_) => _consultar(),
        ),
        const SizedBox(height: AppSpacing.md),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonalIcon(
            onPressed: _loading ? null : _consultar,
            icon: const Icon(Icons.search, size: 18),
            label: const Text('Consultar chave'),
          ),
        ),
        if (consulta != null) ...[
          const SizedBox(height: AppSpacing.lg),
          AppListRow(
            leading: const AppIconWell(Icons.receipt_long_outlined),
            title: 'NF-e nº ${consulta.numero} · série ${consulta.serie}',
            meta:
                'Emitente ${_cnpj(consulta.emitenteCnpj)}\n${consulta.mensagem}',
            metaMaxLines: 3,
            showDivider: false,
            trailing: consulta.notaId != null
                ? FilledButton(
                    onPressed: _loading ? null : () => _abrir(consulta.notaId!),
                    child: const Text('Abrir'),
                  )
                : consulta.sefazDisponivel
                ? FilledButton(
                    onPressed: _loading ? null : _buscarNaSefaz,
                    child: const Text('Buscar na SEFAZ'),
                  )
                : null,
          ),
        ],
        const SizedBox(height: AppSpacing.xxl),
        const AppSectionTitle(
          'XML da NF-e',
          subtitle:
              'O arquivo .xml que o fornecedor envia por e-mail junto com o DANFE',
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: _loading ? null : _enviarXml,
            icon: const Icon(Icons.upload_file, size: 18),
            label: const Text('Enviar XML'),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Nada é gravado no estoque antes da sua confirmação. A busca automática '
          'pela chave na SEFAZ exige o certificado digital A1 da Empresa.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _revisao(BuildContext context, NotaFiscalEntrada nota) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionTitle(
          nota.emitenteNome,
          subtitle: [
            'NF-e nº ${nota.numero} · série ${nota.serie}',
            _cnpj(nota.emitenteCnpj),
            if (nota.dataEmissao != null)
              'Emitida em ${AppFormatters.dateTime(nota.dataEmissao)}',
          ].join(' · '),
          trailing: Text(
            AppFormatters.currencyText('${nota.valorTotal}'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            AppStatusBadge(label: '${nota.itens.length} itens'),
            if (nota.totalPendentes > 0)
              AppStatusBadge(
                label: '${nota.totalPendentes} pendentes',
                tone: AppStatusTone.critical,
              ),
            if (nota.totalAvisos > 0)
              AppStatusBadge(
                label: '${nota.totalAvisos} para conferir',
                tone: AppStatusTone.warning,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (nota.concluida)
          AppBanner(
            tone: AppStatusTone.success,
            message:
                'Entrada lançada no estoque central: ${nota.entradasLancadas} itens, '
                '${nota.produtosCriados} produtos novos no catálogo.',
          )
        else
          AppBanner(
            tone: AppStatusTone.info,
            message:
                'Toque em um item para ajustar. Produtos novos precisam de preço de venda; '
                'itens em caixa ou fardo pedem quantas unidades vêm em cada embalagem.',
          ),
        const SizedBox(height: AppSpacing.md),
        for (final item in nota.itens)
          AppListRow(
            key: ValueKey('nfe-item-${item.numeroItem}'),
            title: item.descricao,
            meta: _metaItem(item),
            metaMaxLines: 3,
            trailing: _badge(item.status),
            onTap: nota.concluida || _loading ? null : () => _editar(item),
          ),
        if (!nota.concluida) ...[
          const SizedBox(height: AppSpacing.lg),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: _loading || !nota.podeConfirmar ? null : _confirmar,
              icon: const Icon(Icons.inventory_2_outlined, size: 18),
              label: Text('Confirmar entrada (${nota.itens.length} itens)'),
            ),
          ),
        ],
      ],
    );
  }

  String _metaItem(NotaFiscalItem item) {
    final quantidade = item.fatorConversao == 1
        ? '${_qtd(item.quantidade)} ${item.unidadeComercial}'
        : '${_qtd(item.quantidade)} ${item.unidadeComercial} × ${_qtd(item.fatorConversao)} '
              '= ${_qtd(item.quantidadeEntrada)} ${item.unidadeMedida}';
    final destino = item.criar
        ? 'Novo: ${item.nomeProduto ?? item.descricao}'
              '${item.precoVenda == null ? '' : ' a ${AppFormatters.currencyText('${item.precoVenda}')}'}'
        : '→ ${item.produtoNome ?? 'escolha o produto'}';
    return [
      '$quantidade · ${AppFormatters.currencyText('${item.valorTotal}')}',
      destino,
      if (item.mensagem != null && item.status != 'PRONTO') item.mensagem!,
    ].join('\n');
  }

  Widget _badge(String status) => switch (status) {
    'PENDENTE' => const AppStatusBadge(
      label: 'Pendente',
      tone: AppStatusTone.critical,
    ),
    'AVISO' => const AppStatusBadge(
      label: 'Conferir',
      tone: AppStatusTone.warning,
    ),
    'IMPORTADO' => const AppStatusBadge(
      label: 'Lançado',
      tone: AppStatusTone.success,
    ),
    _ => const AppStatusBadge(label: 'Pronto', tone: AppStatusTone.success),
  };
}

class _Ajuste {
  const _Ajuste({
    required this.acao,
    required this.fatorConversao,
    this.produtoId,
    this.nomeProduto,
    this.precoVenda,
    this.categoria,
  });
  final String acao;
  final num fatorConversao;
  final String? produtoId;
  final String? nomeProduto;
  final num? precoVenda;
  final String? categoria;
}

class _ItemEditor extends StatefulWidget {
  const _ItemEditor({required this.item, required this.catalogo});
  final NotaFiscalItem item;
  final List<Produto> catalogo;

  @override
  State<_ItemEditor> createState() => _ItemEditorState();
}

class _ItemEditorState extends State<_ItemEditor> {
  late String _acao = widget.item.acao;
  late String? _produtoId = widget.item.produtoId;
  late String _categoria = widget.item.categoria ?? 'OUTROS';
  late final _nome = TextEditingController(
    text: widget.item.nomeProduto ?? widget.item.descricao,
  );
  late final _preco = TextEditingController(
    text: widget.item.precoVenda == null
        ? ''
        : widget.item.precoVenda!.toStringAsFixed(2).replaceAll('.', ','),
  );
  late final _fator = TextEditingController(
    text: _qtd(widget.item.fatorConversao),
  );
  String? _erro;

  @override
  void dispose() {
    _nome.dispose();
    _preco.dispose();
    _fator.dispose();
    super.dispose();
  }

  num? _decimal(String text) {
    final value = text.trim();
    // "1.234,56" ou "5,50" no formato brasileiro; "5.50" também é aceito.
    return num.tryParse(
      value.contains(',')
          ? value.replaceAll('.', '').replaceAll(',', '.')
          : value,
    );
  }

  void _salvar() {
    final fator = _decimal(_fator.text);
    if (fator == null || fator <= 0) {
      setState(() => _erro = 'Informe quantas unidades vêm em cada embalagem');
      return;
    }
    if (_acao == 'VINCULAR') {
      if (_produtoId == null) {
        setState(() => _erro = 'Escolha o produto do catálogo');
        return;
      }
      Navigator.pop(
        context,
        _Ajuste(acao: _acao, produtoId: _produtoId, fatorConversao: fator),
      );
      return;
    }
    final preco = _decimal(_preco.text);
    if (_nome.text.trim().isEmpty) {
      setState(() => _erro = 'Informe o nome do produto');
      return;
    }
    if (preco == null || preco <= 0) {
      setState(() => _erro = 'Informe o preço de venda');
      return;
    }
    Navigator.pop(
      context,
      _Ajuste(
        acao: _acao,
        nomeProduto: _nome.text.trim(),
        precoVenda: preco,
        categoria: _categoria,
        fatorConversao: fator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final theme = Theme.of(context);
    final fator = _decimal(_fator.text) ?? item.fatorConversao;
    final entrada = item.quantidade * fator;
    final custo = entrada == 0 ? 0 : item.valorTotal / entrada;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(item.descricao, style: theme.textTheme.titleMedium),
            Text(
              [
                if (item.ean != null)
                  'EAN ${item.ean}'
                else
                  'Sem código de barras',
                if (item.ncm != null) 'NCM ${item.ncm}',
              ].join(' · '),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'VINCULAR',
                  label: Text('Produto do catálogo'),
                  icon: Icon(Icons.link),
                ),
                ButtonSegment(
                  value: 'CRIAR',
                  label: Text('Criar produto'),
                  icon: Icon(Icons.add),
                ),
              ],
              selected: {_acao},
              onSelectionChanged: (value) =>
                  setState(() => _acao = value.first),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_acao == 'VINCULAR')
              DropdownMenu<String>(
                initialSelection: _produtoId,
                expandedInsets: EdgeInsets.zero,
                enableFilter: true,
                requestFocusOnTap: true,
                label: const Text('Produto'),
                onSelected: (value) => setState(() => _produtoId = value),
                dropdownMenuEntries: [
                  for (final produto in widget.catalogo)
                    if (produto.id != null)
                      DropdownMenuEntry(
                        value: produto.id!,
                        label: produto.nome,
                      ),
                ],
              )
            else ...[
              TextField(
                controller: _nome,
                decoration: const InputDecoration(labelText: 'Nome do produto'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _preco,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Preço de venda',
                  prefixText: 'R\$ ',
                  helperText:
                      'Custo na nota: ${AppFormatters.currencyText('$custo')} por ${item.unidadeMedida}',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownMenu<String>(
                initialSelection: _categoria,
                expandedInsets: EdgeInsets.zero,
                label: const Text('Categoria'),
                onSelected: (value) =>
                    setState(() => _categoria = value ?? _categoria),
                dropdownMenuEntries: [
                  for (final categoria in _categorias)
                    DropdownMenuEntry(
                      value: categoria,
                      label: _categoriaLabel(categoria),
                    ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _fator,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Unidades por ${item.unidadeComercial}',
                helperText:
                    '${_qtd(item.quantidade)} ${item.unidadeComercial} na nota → '
                    'entram ${_qtd(entrada)} ${item.unidadeMedida} no estoque',
              ),
            ),
            if (_erro != null) ...[
              const SizedBox(height: AppSpacing.md),
              AppBanner(tone: AppStatusTone.critical, message: _erro!),
            ],
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(onPressed: _salvar, child: const Text('Salvar')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _qtd(num value) {
  final text = value.toStringAsFixed(3);
  return text.replaceFirst(RegExp(r'\.?0+$'), '').replaceAll('.', ',');
}

String _cnpj(String value) {
  final d = value.replaceAll(RegExp(r'\D'), '');
  if (d.length != 14) return value;
  return '${d.substring(0, 2)}.${d.substring(2, 5)}.${d.substring(5, 8)}/'
      '${d.substring(8, 12)}-${d.substring(12)}';
}

const _categorias = <String>[
  'BEBIDA',
  'ALIMENTOS',
  'LIMPEZA',
  'HIGIENE',
  'PADARIA',
  'LATICINIOS',
  'CONGELADOS',
  'DOCES',
  'SALGADINHOS',
  'FRUTAS',
  'VERDURAS',
  'LEGUMES',
  'CARNES',
  'FRIOS',
  'PETISCOS',
  'TEMPEROS',
  'GRAOS',
  'MASSAS',
  'ENLATADOS',
  'MATINAIS',
  'UTILIDADES',
  'PET',
  'INFANTIL',
  'ELETRONICOS',
  'PAPELARIA',
  'DESCARTAVEIS',
  'OUTROS',
];

String _categoriaLabel(String value) {
  final text = value.replaceAll('_', ' ').toLowerCase();
  return text.isEmpty ? text : '${text[0].toUpperCase()}${text.substring(1)}';
}
