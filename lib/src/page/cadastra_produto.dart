import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/formatters/decimal_input_formatter.dart';
import '../../core/formatters/produto_labels.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_content.dart';
import '../../core/widgets/status_badge.dart';
import '../model/api_client.dart';
import '../model/decimal_value.dart';
import '../model/produto.dart';
import '../model/produto_repository.dart';
import '../model/promocao.dart';
import '../model/promocao_repository.dart';
import 'estoque_produto_page.dart';
import 'scanner_page.dart';

class CadastraProduto extends StatefulWidget {
  const CadastraProduto({
    super.key,
    this.produto,
    this.repository,
    this.promocaoRepository,
  });

  final Produto? produto;
  final ProdutoRepository? repository;
  final PromocaoRepository? promocaoRepository;

  @override
  State<CadastraProduto> createState() => _CadastraProdutoState();
}

class _CadastraProdutoState extends State<CadastraProduto> {
  final _formKey = GlobalKey<FormState>();
  late final ProdutoRepository _repository;
  late final PromocaoRepository _promocaoRepository;
  final _sku = TextEditingController();
  final _nome = TextEditingController();
  final _descricao = TextEditingController();
  final _preco = TextEditingController();
  final _peso = TextEditingController();
  final _tolerancia = TextEditingController();
  // Preço em centavos (2 casas) e peso em gramas (3 casas).
  final _scroll = ScrollController();
  final _precoFormatter = DecimalInputFormatter(decimalDigits: 2);
  final _pesoFormatter = DecimalInputFormatter(decimalDigits: 3);
  final _estoqueInicial = TextEditingController();
  final _minimoCentral = TextEditingController();
  final _minimoCondominio = TextEditingController();
  final _motivoEstoque = TextEditingController(text: 'Carga inicial');
  final _ncm = TextEditingController();
  final _cest = TextEditingController();
  final _origem = TextEditingController();
  final _unidadeTributavel = TextEditingController();
  final _fatorConversao = TextEditingController();
  final _gtinTributavel = TextEditingController();
  final List<_BarcodeEditor> _barcodes = [];
  List<ProdutoCondominioDisponibilidade> _condominios = const [];
  final Map<String, bool> _associacoes = {};
  final Map<String, bool> _associacoesOriginais = {};
  String _categoria = 'OUTROS';
  String _unidade = 'UN';
  bool _ativo = true;
  bool _saving = false;
  bool _loadingCondominios = true;
  bool _todosCondominios = false;
  bool _todosCondominiosOriginal = false;
  bool _loadingPromocoes = false;
  bool _estoqueRegistrado = false;
  String? _condominiosError;
  String? _promocoesError;
  String? _error;
  String? _savedId;
  Uint8List? _imageBytes;
  String? _imageName;
  List<Promocao> _promocoesAtivas = const [];

  bool get _editing => widget.produto != null || _savedId != null;

  /// Produto que, salvo assim, não fica à venda em lugar nenhum.
  bool get _semCondominio =>
      !_todosCondominios &&
      _condominios.isNotEmpty &&
      !_associacoes.values.any((associado) => associado);

  static const _categorias = [
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
  static const _unidades = [
    'UN',
    'KG',
    'G',
    'LITRO',
    'ML',
    'CAIXA',
    'PACOTE',
    'FARDO',
    'BANDEJA',
    'GARRAFA',
    'LATA',
    'SACO',
    'DUZIA',
    'METRO',
  ];

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ProdutoRepository();
    _promocaoRepository = widget.promocaoRepository ?? PromocaoRepository();
    final product = widget.produto;
    if (product == null) {
      _barcodes.add(_BarcodeEditor(principal: true));
      // Produto novo já nasce à venda em todos os Condomínios.
      _todosCondominios = true;
    } else {
      _sku.text = product.codigoInterno;
      _nome.text = product.nome;
      _descricao.text = product.descricao ?? '';
      _preco.text = _precoFormatter.format(_toUnits(product.preco, 2));
      final peso = product.peso;
      if (peso != null) _peso.text = _pesoFormatter.format(_toUnits(peso, 3));
      final tolerancia = product.pesoTolerancia;
      if (tolerancia != null) {
        _tolerancia.text = _pesoFormatter.format(_toUnits(tolerancia, 3));
      }
      _minimoCentral.text =
          product.estoqueMinimoCentral?.friendly.replaceAll('.', ',') ?? '';
      _minimoCondominio.text =
          product.estoqueMinimoCondominio?.friendly.replaceAll('.', ',') ?? '';
      _todosCondominios = product.disponivelTodosCondominios;
      _todosCondominiosOriginal = product.disponivelTodosCondominios;
      _categoria = product.categoria;
      _unidade = product.unidadeMedida;
      _ativo = product.ativo;
      for (final barcode in product.codigosBarras) {
        _barcodes.add(
          _BarcodeEditor(
            codigo: barcode.codigo,
            tipo: barcode.tipo,
            principal: barcode.principal,
            ativo: barcode.ativo,
          ),
        );
      }
      if (_barcodes.isEmpty) _barcodes.add(_BarcodeEditor(principal: true));
      final fiscal = product.fiscal;
      if (fiscal != null) {
        _ncm.text = fiscal.ncm ?? '';
        _cest.text = fiscal.cest ?? '';
        _origem.text = fiscal.origemMercadoria ?? '';
        _unidadeTributavel.text = fiscal.unidadeTributavel ?? '';
        _fatorConversao.text = fiscal.fatorConversaoTributavel?.friendly ?? '';
        _gtinTributavel.text = fiscal.gtinTributavel ?? '';
      }
    }
    _loadCondominios();
    _loadPromocoes();
  }

  Future<void> _loadPromocoes() async {
    final produtoId = _savedId ?? widget.produto?.id;
    if (produtoId == null) return;
    setState(() {
      _loadingPromocoes = true;
      _promocoesError = null;
    });
    try {
      final items = await _promocaoRepository.listar(
        status: StatusPromocao.ativa,
        produtoId: produtoId,
      );
      if (mounted) setState(() => _promocoesAtivas = items);
    } catch (error) {
      if (mounted) setState(() => _promocoesError = error.toString());
    } finally {
      if (mounted) setState(() => _loadingPromocoes = false);
    }
  }

  Future<void> _loadCondominios() async {
    setState(() {
      _loadingCondominios = true;
      _condominiosError = null;
    });
    try {
      final productId = _savedId ?? widget.produto?.id;
      final items = productId == null
          ? (await _repository.listarCondominios())
                .map(
                  (item) => ProdutoCondominioDisponibilidade(
                    condominioId: item.id,
                    condominioNome: item.nome,
                    associado: false,
                  ),
                )
                .toList()
          : await _repository.disponibilidadeCondominios(productId);
      if (!mounted) return;
      setState(() {
        _condominios = items;
        _associacoes
          ..clear()
          ..addEntries(
            items.map((item) => MapEntry(item.condominioId, item.associado)),
          );
        _associacoesOriginais
          ..clear()
          ..addAll(_associacoes);
      });
    } catch (error) {
      if (mounted) setState(() => _condominiosError = error.toString());
    } finally {
      if (mounted) setState(() => _loadingCondominios = false);
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _sku,
      _nome,
      _descricao,
      _preco,
      _peso,
      _tolerancia,
      _estoqueInicial,
      _minimoCentral,
      _minimoCondominio,
      _motivoEstoque,
      _ncm,
      _cest,
      _origem,
      _unidadeTributavel,
      _fatorConversao,
      _gtinTributavel,
    ]) {
      controller.dispose();
    }
    for (final barcode in _barcodes) {
      barcode.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Campo obrigatório' : null;

  String? _positiveDecimal(String? value, {bool optional = false}) {
    if (value == null || value.trim().isEmpty) {
      return optional ? null : 'Campo obrigatório';
    }
    try {
      return DecimalValue.parse(value).isPositive
          ? null
          : 'Informe um valor maior que zero';
    } on FormatException catch (error) {
      return error.message;
    }
  }

  /// Valor do campo mascarado: obrigatório e maior que zero, ou opcional.
  String? _maskedPositive(String? value, {bool optional = false}) {
    if (value == null || value.trim().isEmpty) {
      return optional ? null : 'Campo obrigatório';
    }
    return DecimalInputFormatter.parse(value) > 0
        ? null
        : 'Informe um valor maior que zero';
  }

  /// Inteiro na menor unidade ([digits] casas) a partir do decimal do model.
  /// Casas além de [digits] são descartadas.
  static int _toUnits(DecimalValue value, int digits) =>
      (value.scaledInteger ~/ BigInt.from(10).pow(6 - digits)).toInt();

  /// Decimal do model a partir do inteiro digitado no campo mascarado.
  static DecimalValue _fromUnits(int units, int digits) {
    final text = units.toString().padLeft(digits + 1, '0');
    final cut = text.length - digits;
    return DecimalValue.parse(
      '${text.substring(0, cut)}.${text.substring(cut)}',
    );
  }

  /// Vazio ou zero significa "sem mínimo".
  static DecimalValue? _minimoOrNull(TextEditingController controller) {
    if (controller.text.trim().isEmpty) return null;
    final value = DecimalValue.parse(controller.text, maxScale: 3);
    return value.isPositive ? value : null;
  }

  static String? _minimoValidator(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    try {
      return DecimalValue.parse(value, maxScale: 3).isNegative
          ? 'O estoque mínimo não pode ser negativo'
          : null;
    } on FormatException catch (error) {
      return error.message;
    }
  }

  DecimalValue? _maskedOrNull(TextEditingController controller, int digits) =>
      controller.text.trim().isEmpty
      ? null
      : _fromUnits(DecimalInputFormatter.parse(controller.text), digits);

  DecimalValue? _optionalDecimal(TextEditingController controller) =>
      controller.text.trim().isEmpty
      ? null
      : DecimalValue.parse(controller.text);

  Produto _buildProduct() {
    final codes = _barcodes
        // Campo de código deixado em branco (produto só com SKU) não é enviado.
        .where((item) => item.codigo.text.trim().isNotEmpty)
        .map(
          (item) => ProdutoCodigoBarras(
            codigo: item.codigo.text.trim(),
            tipo: item.tipo,
            principal: item.principal,
            ativo: item.ativo,
          ),
        )
        .toList();
    if (codes.map((item) => item.codigo).toSet().length != codes.length) {
      throw const FormatException('Código de barras repetido na lista');
    }
    final active = codes.where((item) => item.ativo).toList();
    if (active.isNotEmpty &&
        active.where((item) => item.principal).length != 1) {
      throw const FormatException(
        'Defina exatamente um código principal ativo',
      );
    }
    final fiscal = ProdutoFiscal(
      ncm: _textOrNull(_ncm),
      cest: _textOrNull(_cest),
      origemMercadoria: _textOrNull(_origem),
      unidadeTributavel: _textOrNull(_unidadeTributavel),
      fatorConversaoTributavel: _optionalDecimal(_fatorConversao),
      gtinTributavel: _textOrNull(_gtinTributavel),
    );
    return Produto(
      id: _savedId ?? widget.produto?.id,
      codigoInterno: _sku.text.trim().isNotEmpty
          ? _sku.text.trim()
          : (active.where((item) => item.principal).firstOrNull?.codigo ?? ''),
      codigosBarras: codes,
      nome: _nome.text.trim(),
      descricao: _textOrNull(_descricao),
      preco: _fromUnits(DecimalInputFormatter.parse(_preco.text), 2),
      unidadeMedida: _unidade,
      categoria: _categoria,
      peso: _maskedOrNull(_peso, 3),
      pesoTolerancia: _maskedOrNull(_tolerancia, 3),
      estoqueMinimoCentral: _minimoOrNull(_minimoCentral),
      estoqueMinimoCondominio: _minimoOrNull(_minimoCondominio),
      ativo: _ativo,
      fiscal: fiscal.isEmpty ? null : fiscal,
      foto: widget.produto?.foto,
    );
  }

  String? _textOrNull(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  Future<void> _salvar() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) {
      _mostrarPrimeiroErro();
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    Produto? saved;
    try {
      saved = await _repository.salvar(
        _buildProduct(),
        imageBytes: _imageBytes,
        imageName: _imageName,
      );
      _savedId = saved.id;
      if (!_estoqueRegistrado && _estoqueInicial.text.trim().isNotEmpty) {
        await _repository.registrarEstoqueInicial(
          produtoId: saved.id!,
          quantidade: DecimalValue.parse(_estoqueInicial.text),
          motivo: _motivoEstoque.text.trim(),
        );
        _estoqueRegistrado = true;
      }
      await _syncAvailability(saved.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.produto == null ? 'Produto cadastrado com sucesso.' : 'Produto atualizado com sucesso.'}'
            '${_semCondominio ? ' Ele ainda não está disponível em nenhum condomínio.' : ''}',
          ),
        ),
      );
      Navigator.pop(context, saved);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = saved == null
            ? error.friendlyMessage
            : 'O produto foi salvo, mas uma etapa de estoque ou disponibilidade falhou: '
                  '${error.friendlyMessage}';
      });
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = saved == null
            ? 'Não foi possível salvar o produto. Tente novamente.'
            : 'O produto foi salvo, mas uma etapa de estoque ou disponibilidade falhou: $error';
      });
    } finally {
      if (mounted) {
        setState(() => _saving = false);
        // O aviso de erro fica no topo; o botão Salvar pode estar lá embaixo.
        if (_error != null && _scroll.hasClients) {
          _scroll.animateTo(
            0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      }
    }
  }

  /// Rola até o primeiro campo recusado pela validação.
  void _mostrarPrimeiroErro() {
    BuildContext? primeiro;
    void visitar(Element element) {
      if (primeiro != null) return;
      if (element is StatefulElement) {
        final state = element.state;
        if (state is FormFieldState && state.hasError) {
          primeiro = element;
          return;
        }
      }
      element.visitChildren(visitar);
    }

    _formKey.currentContext?.visitChildElements(visitar);
    final alvo = primeiro;
    if (alvo == null) return;
    Scrollable.ensureVisible(
      alvo,
      alignment: 0.1,
      duration: const Duration(milliseconds: 200),
    );
  }

  Future<void> _abrirEstoque() async {
    final id = _savedId ?? widget.produto?.id;
    if (id == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EstoqueProdutoPage(
          produtoId: id,
          nome: _nome.text.trim().isEmpty ? 'Produto' : _nome.text.trim(),
        ),
      ),
    );
  }

  Future<void> _syncAvailability(String produtoId) async {
    if (_todosCondominios != _todosCondominiosOriginal) {
      await _repository.definirDisponivelEmTodos(
        produtoId: produtoId,
        ativo: _todosCondominios,
      );
      _todosCondominiosOriginal = _todosCondominios;
    }
    if (_todosCondominios) {
      // O backend já associou todos os Condomínios.
      for (final item in _condominios) {
        _associacoes[item.condominioId] = true;
        _associacoesOriginais[item.condominioId] = true;
      }
      return;
    }
    await _syncAssociations(produtoId);
  }

  Future<void> _syncAssociations(String produtoId) async {
    for (final item in _condominios) {
      final current = _associacoes[item.condominioId] ?? false;
      final original = _associacoesOriginais[item.condominioId] ?? false;
      if (current == original) continue;
      if (current) {
        await _repository.associarAoCondominio(
          produtoId: produtoId,
          condominioId: item.condominioId,
          quantidade: DecimalValue.parse('0'),
        );
      } else {
        await _repository.desassociarDoCondominio(
          produtoId: produtoId,
          condominioId: item.condominioId,
        );
      }
      _associacoesOriginais[item.condominioId] = current;
    }
  }

  Future<void> _pickImage() async {
    final file = await FilePicker.pickFile(type: FileType.image);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _imageName = file.name;
    });
  }

  void _setPrincipal(int index) {
    setState(() {
      for (var i = 0; i < _barcodes.length; i++) {
        _barcodes[i].principal = i == index;
      }
      _barcodes[index].ativo = true;
    });
  }

  void _toggleBarcode(int index, bool value) {
    setState(() {
      final barcode = _barcodes[index];
      barcode.ativo = value;
      if (!value && barcode.principal) {
        barcode.principal = false;
        final replacement = _barcodes.indexWhere((item) => item.ativo);
        if (replacement >= 0) _barcodes[replacement].principal = true;
      }
      if (value && !_barcodes.any((item) => item.ativo && item.principal)) {
        barcode.principal = true;
      }
    });
  }

  void _removeBarcode(int index) {
    setState(() {
      final wasPrincipal = _barcodes[index].principal;
      _barcodes.removeAt(index).dispose();
      if (wasPrincipal) {
        final replacement = _barcodes.indexWhere((item) => item.ativo);
        if (replacement >= 0) _barcodes[replacement].principal = true;
      }
    });
  }

  Future<void> _scan(int index) async {
    if (kIsWeb) return;
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ScannerPage()),
    );
    if (result != null && mounted) {
      setState(() => _barcodes[index].codigo.text = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mobile = AppBreakpoints.isMobile(context);
    const gap = SizedBox(height: AppSpacing.section);
    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Editar produto' : 'Novo produto'),
        actions: mobile
            ? null
            : [
                TextButton(
                  onPressed: _saving ? null : () => Navigator.maybePop(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.lg),
                  child: _SaveButton(saving: _saving, onPressed: _salvar),
                ),
              ],
      ),
      bottomNavigationBar: mobile
          ? SafeArea(
              minimum: const EdgeInsets.all(AppSpacing.md),
              child: _SaveButton(saving: _saving, onPressed: _salvar),
            )
          : null,
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          controller: _scroll,
          child: AppContent(
            maxWidth: AppLayout.contentMaxWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_error != null) ...[
                  AppBanner(
                    key: const Key('product-error'),
                    tone: AppStatusTone.critical,
                    message: _error!,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
                LayoutBuilder(
                  builder: (context, constraints) {
                    final main = [_generalSection()];
                    final optional = [_moreSection(), gap, _fiscalSection()];
                    final side = [
                      _availabilitySection(),
                      // Saldo e promoções só existem para produto já cadastrado.
                      if (_editing) ...[
                        gap,
                        _stockSection(),
                        gap,
                        _promotionsSection(),
                      ],
                    ];
                    if (constraints.maxWidth < 1000) {
                      // No celular o essencial vem primeiro e o opcional por último.
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [...main, gap, ...side, gap, ...optional],
                      );
                    }
                    main.addAll([gap, ...optional]);
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: main,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.section),
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.only(left: AppSpacing.xl),
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outlineVariant,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: side,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Código mostrado junto dos dados do produto; os demais ficam em
  /// "Códigos adicionais e peso".
  int get _principalIndex {
    final index = _barcodes.indexWhere((item) => item.ativo && item.principal);
    return index >= 0 ? index : (_barcodes.isEmpty ? -1 : 0);
  }

  Widget _generalSection() {
    final principal = _principalIndex;
    return _SectionCard(
      key: const Key('product-general-section'),
      title: 'Produto',
      icon: Icons.inventory_2_outlined,
      child: Column(
        children: [
          Row(
            children: [
              _ImagePreview(bytes: _imageBytes, imageUrl: widget.produto?.foto),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : _pickImage,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(
                    _imageBytes == null ? 'Selecionar foto' : 'Trocar foto',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            key: const Key('product-name-field'),
            controller: _nome,
            decoration: const InputDecoration(labelText: 'Nome'),
            validator: _required,
          ),
          const SizedBox(height: AppSpacing.md),
          _ResponsiveFields(
            children: [
              if (principal >= 0)
                TextFormField(
                  key: Key('barcode-field-$principal'),
                  controller: _barcodes[principal].codigo,
                  decoration: InputDecoration(
                    labelText: 'Código de barras',
                    suffixIcon: kIsWeb
                        ? null
                        : IconButton(
                            tooltip: 'Ler com a câmera',
                            onPressed: () => _scan(principal),
                            icon: const Icon(Icons.qr_code_scanner),
                          ),
                  ),
                  // Um dos dois identifica o produto: código de barras ou SKU.
                  validator: (value) =>
                      (value ?? '').trim().isEmpty && _sku.text.trim().isEmpty
                      ? 'Informe o código de barras ou o SKU'
                      : null,
                ),
              TextFormField(
                key: const Key('product-sku-field'),
                controller: _sku,
                decoration: InputDecoration(
                  labelText: 'Código interno / SKU',
                  helperText: principal >= 0
                      ? 'Opcional. Se vazio, usa o código de barras'
                      : 'Único dentro da empresa',
                ),
                validator: principal >= 0 ? null : _required,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _ResponsiveFields(
            children: [
              TextFormField(
                key: const Key('product-price-field'),
                controller: _preco,
                keyboardType: TextInputType.number,
                inputFormatters: [_precoFormatter],
                decoration: const InputDecoration(
                  labelText: 'Preço de venda',
                  prefixText: 'R\$ ',
                  hintText: '0,00',
                ),
                validator: _maskedPositive,
              ),
              DropdownButtonFormField<String>(
                initialValue: _categoria,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Categoria'),
                items: _categorias
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(ProdutoLabels.categoria(value)),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _categoria = value ?? 'OUTROS'),
              ),
              DropdownButtonFormField<String>(
                initialValue: _unidade,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Unidade de medida',
                ),
                items: _unidades
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(ProdutoLabels.unidade(value)),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _unidade = value ?? 'UN'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _descricao,
            decoration: const InputDecoration(
              labelText: 'Descrição (opcional)',
            ),
            maxLines: 3,
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _ativo,
            title: const Text('Produto ativo'),
            subtitle: const Text('Produtos inativos deixam de ser ofertados.'),
            onChanged: _saving
                ? null
                : (value) => setState(() => _ativo = value),
          ),
        ],
      ),
    );
  }

  Widget _moreSection() {
    final principal = _principalIndex;
    final product = widget.produto;
    return _SectionCard(
      key: const Key('product-more-section'),
      title: 'Códigos adicionais e peso',
      subtitle: 'Opcional',
      icon: Icons.qr_code_2_outlined,
      collapsible: true,
      initiallyExpanded:
          product != null &&
          (product.codigosBarras.length > 1 ||
              product.peso != null ||
              product.pesoTolerancia != null),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < _barcodes.length; index++)
            if (index != principal)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _BarcodeCard(
                  editor: _barcodes[index],
                  index: index,
                  scannerAvailable: !kIsWeb,
                  onScan: () => _scan(index),
                  onPrincipal: () => _setPrincipal(index),
                  onActive: (value) => _toggleBarcode(index, value),
                  onRemove: () => _removeBarcode(index),
                  requiredValidator: _required,
                ),
              ),
          TextButton.icon(
            key: const Key('add-barcode-button'),
            onPressed: _saving
                ? null
                : () => setState(() => _barcodes.add(_BarcodeEditor())),
            icon: const Icon(Icons.add),
            label: const Text('Adicionar código de barras'),
          ),
          const SizedBox(height: AppSpacing.lg),
          _ResponsiveFields(
            children: [
              TextFormField(
                key: const Key('product-weight-field'),
                controller: _peso,
                keyboardType: TextInputType.number,
                inputFormatters: [_pesoFormatter],
                decoration: const InputDecoration(
                  labelText: 'Peso',
                  hintText: '0,000',
                  suffixText: 'kg',
                ),
                validator: (value) => _maskedPositive(value, optional: true),
              ),
              TextFormField(
                controller: _tolerancia,
                keyboardType: TextInputType.number,
                inputFormatters: [_pesoFormatter],
                decoration: const InputDecoration(
                  labelText: 'Tolerância de peso',
                  hintText: '0,000',
                  suffixText: 'kg',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Só na edição: o saldo é tratado na página de estoque do produto.
  Widget _stockSection() => _SectionCard(
    key: const Key('product-stock-section'),
    title: 'Estoque',
    icon: Icons.warehouse_outlined,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Saldo, histórico e correções ficam na página de estoque do produto.',
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          key: const Key('product-stock-link'),
          onPressed: _abrirEstoque,
          icon: const Icon(Icons.inventory_2_outlined, size: 18),
          label: const Text('Ver estoque deste produto'),
        ),
      ],
    ),
  );

  /// Só no cadastro novo: entrada inicial opcional no estoque central.
  List<Widget> _initialStock() => [
    const Text(
      'Opcional. Ao salvar, será criada uma entrada e sua movimentação.',
    ),
    const SizedBox(height: AppSpacing.md),
    _ResponsiveFields(
      children: [
        TextFormField(
          key: const Key('initial-stock-field'),
          controller: _estoqueInicial,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Quantidade inicial',
            helperText: 'Até 3 casas decimais',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return null;
            try {
              return DecimalValue.parse(value, maxScale: 3).isPositive
                  ? null
                  : 'Informe uma quantidade maior que zero';
            } on FormatException catch (error) {
              return error.message;
            }
          },
        ),
        TextFormField(
          controller: _motivoEstoque,
          decoration: const InputDecoration(labelText: 'Motivo'),
          validator: (value) =>
              _estoqueInicial.text.trim().isNotEmpty ? _required(value) : null,
        ),
      ],
    ),
  ];

  Widget _availabilitySection() => _SectionCard(
    key: const Key('product-availability-section'),
    title: 'Onde vender',
    icon: Icons.apartment_outlined,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _condominiosWidget(),
        if (!_editing) ...[
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Estoque inicial no central',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          ..._initialStock(),
        ],
        const SizedBox(height: AppSpacing.xl),
        Text('Estoque mínimo', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Opcional. Abaixo dessa quantidade o produto aparece como estoque baixo.',
        ),
        const SizedBox(height: AppSpacing.md),
        _ResponsiveFields(
          children: [
            TextFormField(
              key: const Key('product-min-central-field'),
              controller: _minimoCentral,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Mínimo no estoque central',
              ),
              validator: _minimoValidator,
            ),
            TextFormField(
              key: const Key('product-min-condominium-field'),
              controller: _minimoCondominio,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Mínimo em cada condomínio',
              ),
              validator: _minimoValidator,
            ),
          ],
        ),
      ],
    ),
  );

  Widget _condominiosWidget() => _loadingCondominios
      ? const LinearProgressIndicator()
      : _condominiosError != null
      ? ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.cloud_off_outlined),
          title: const Text('Não foi possível carregar os condomínios'),
          subtitle: Text(_condominiosError!),
          trailing: IconButton(
            onPressed: _loadCondominios,
            icon: const Icon(Icons.refresh),
          ),
        )
      : _condominios.isEmpty
      ? const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.info_outline),
          title: Text('Nenhum condomínio ativo cadastrado'),
        )
      : Column(
          children: [
            SwitchListTile.adaptive(
              key: const Key('product-all-condominiums-switch'),
              contentPadding: EdgeInsets.zero,
              value: _todosCondominios,
              title: const Text('Disponível em todos os condomínios'),
              subtitle: const Text('Inclui os condomínios cadastrados depois.'),
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _todosCondominios = value),
            ),
            const Divider(height: 1),
            for (var index = 0; index < _condominios.length; index++) ...[
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value:
                    _todosCondominios ||
                    (_associacoes[_condominios[index].condominioId] ?? false),
                title: Text(_condominios[index].condominioNome),
                subtitle: _condominios[index].quantidade == null
                    ? null
                    : Text(
                        'Saldo local: ${_condominios[index].quantidade!.friendly}',
                      ),
                onChanged: _saving || _todosCondominios
                    ? null
                    : (value) => setState(() {
                        _associacoes[_condominios[index].condominioId] =
                            value ?? false;
                      }),
              ),
              if (index != _condominios.length - 1) const Divider(height: 1),
            ],
            if (_semCondominio) ...[
              const SizedBox(height: AppSpacing.md),
              const AppBanner(
                key: Key('product-no-condominium-warning'),
                message:
                    'Sem nenhum condomínio marcado, o produto não aparece em nenhum terminal.',
              ),
            ],
          ],
        );

  Widget _fiscalSection() => _SectionCard(
    key: const Key('product-fiscal-section'),
    title: 'Informações fiscais',
    subtitle: 'Opcional',
    icon: Icons.request_quote_outlined,
    initiallyExpanded: widget.produto?.fiscal?.isEmpty == false,
    collapsible: true,
    child: Column(
      children: [
        _ResponsiveFields(
          children: [
            TextFormField(
              controller: _ncm,
              decoration: const InputDecoration(labelText: 'NCM'),
              maxLength: 8,
              validator: (value) =>
                  value != null &&
                      value.isNotEmpty &&
                      !RegExp(r'^\d{8}$').hasMatch(value)
                  ? 'Use 8 dígitos'
                  : null,
            ),
            TextFormField(
              controller: _cest,
              decoration: const InputDecoration(labelText: 'CEST'),
              maxLength: 7,
              validator: (value) =>
                  value != null &&
                      value.isNotEmpty &&
                      !RegExp(r'^\d{7}$').hasMatch(value)
                  ? 'Use 7 dígitos'
                  : null,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _ResponsiveFields(
          children: [
            TextFormField(
              controller: _origem,
              maxLength: 2,
              decoration: const InputDecoration(labelText: 'Origem'),
            ),
            TextFormField(
              controller: _unidadeTributavel,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Unidade tributável',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _ResponsiveFields(
          children: [
            TextFormField(
              controller: _gtinTributavel,
              maxLength: 14,
              decoration: const InputDecoration(labelText: 'GTIN tributável'),
            ),
            TextFormField(
              controller: _fatorConversao,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Fator de conversão',
              ),
              validator: (value) => _positiveDecimal(value, optional: true),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _promotionsSection() => _SectionCard(
    key: const Key('product-promotions-section'),
    title: 'Promoções',
    icon: Icons.local_offer_outlined,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_loadingPromocoes)
          const LinearProgressIndicator()
        else if (_promocoesError != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.cloud_off_outlined),
            title: const Text('Não foi possível carregar as promoções ativas'),
            trailing: IconButton(
              onPressed: _loadPromocoes,
              icon: const Icon(Icons.refresh),
            ),
          )
        else if (_promocoesAtivas.isEmpty)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.info_outline),
            title: Text('Nenhuma promoção ativa para este produto'),
          )
        else ...[
          Text(
            'Promoções ativas',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final promocao in _promocoesAtivas)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.local_offer_outlined),
              title: Text(promocao.nome),
              subtitle: Text(switch (promocao.tipo) {
                TipoPromocao.percentual =>
                  '${promocao.valor.friendly}% de desconto',
                TipoPromocao.descontoFixo =>
                  '${promocao.valor.currency} de desconto',
                TipoPromocao.precoFixo => 'Por ${promocao.valor.currency}',
              }),
            ),
        ],
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final description = Text(
              'Períodos, prioridades e condições são editados no módulo próprio.',
              style: Theme.of(context).textTheme.bodySmall,
            );
            final action = OutlinedButton(
              onPressed: () => Navigator.pushNamed(context, '/promocoes'),
              child: const Text('Gerenciar promoções'),
            );
            if (constraints.maxWidth < 520) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  description,
                  const SizedBox(height: AppSpacing.md),
                  action,
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: description),
                const SizedBox(width: AppSpacing.lg),
                action,
              ],
            );
          },
        ),
      ],
    ),
  );
}

class _SectionCard extends StatefulWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.subtitle,
    this.collapsible = false,
    this.initiallyExpanded = false,
    super.key,
  });
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget child;
  final bool collapsible;
  final bool initiallyExpanded;
  @override
  State<_SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<_SectionCard> {
  late bool _expanded = !widget.collapsible || widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: theme.textTheme.titleLarge),
        if (widget.subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              widget.subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final toggle = widget.collapsible
                ? IconButton(
                    tooltip: _expanded ? 'Recolher seção' : 'Expandir seção',
                    onPressed: () => setState(() => _expanded = !_expanded),
                    icon: Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                    ),
                  )
                : null;
            return InkWell(
              onTap: widget.collapsible
                  ? () => setState(() => _expanded = !_expanded)
                  : null,
              child: Row(
                children: [
                  Expanded(child: heading),
                  ?toggle,
                ],
              ),
            );
          },
        ),
        if (widget.collapsible && !_expanded)
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.md),
            child: Divider(),
          ),
        if (_expanded) ...[const SizedBox(height: AppSpacing.lg), widget.child],
      ],
    );
  }
}

class _ResponsiveFields extends StatelessWidget {
  const _ResponsiveFields({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 520 || children.length == 1) {
        return Column(
          children: [
            for (var index = 0; index < children.length; index++) ...[
              children[index],
              if (index != children.length - 1)
                const SizedBox(height: AppSpacing.md),
            ],
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < children.length; index++) ...[
            Expanded(child: children[index]),
            if (index != children.length - 1)
              const SizedBox(width: AppSpacing.md),
          ],
        ],
      );
    },
  );
}

class _BarcodeCard extends StatelessWidget {
  const _BarcodeCard({
    required this.editor,
    required this.index,
    required this.scannerAvailable,
    required this.onScan,
    required this.onPrincipal,
    required this.onActive,
    required this.onRemove,
    required this.requiredValidator,
  });
  final _BarcodeEditor editor;
  final int index;
  final bool scannerAvailable;
  final VoidCallback onScan;
  final VoidCallback onPrincipal;
  final ValueChanged<bool> onActive;
  final VoidCallback onRemove;
  final FormFieldValidator<String> requiredValidator;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
    ),
    child: Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                key: Key('barcode-field-$index'),
                controller: editor.codigo,
                decoration: InputDecoration(
                  labelText: 'Código de barras ${index + 1}',
                  suffixIcon: scannerAvailable
                      ? IconButton(
                          tooltip: 'Ler com a câmera',
                          onPressed: onScan,
                          icon: const Icon(Icons.qr_code_scanner),
                        )
                      : null,
                ),
                validator: requiredValidator,
              ),
            ),
            IconButton(
              tooltip: 'Remover código',
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _ResponsiveFields(
          children: [
            DropdownButtonFormField<String>(
              initialValue: editor.tipo,
              decoration: const InputDecoration(labelText: 'Tipo'),
              // O back aceita tipo livre (a planilha usa EAN13/GTIN13); um
              // valor fora da lista entra como opção para não quebrar o campo.
              items: {..._barcodeTypes, editor.tipo}
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
              onChanged: (value) => editor.tipo = value ?? 'EAN',
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: editor.ativo,
              title: const Text('Ativo'),
              onChanged: onActive,
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: editor.principal,
              title: const Text('Principal'),
              onChanged: editor.ativo
                  ? (selected) {
                      if (selected == true) onPrincipal();
                    }
                  : null,
            ),
          ],
        ),
      ],
    ),
  );
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({this.bytes, this.imageUrl});
  final Uint8List? bytes;
  final String? imageUrl;
  @override
  Widget build(BuildContext context) {
    final placeholder = Icon(
      Icons.image_outlined,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    Widget child = placeholder;
    if (bytes != null) {
      child = Image.memory(bytes!, fit: BoxFit.cover);
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      child = Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      );
    }
    return Container(
      width: 72,
      height: 72,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: child,
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.saving, required this.onPressed});
  final bool saving;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => FilledButton.icon(
    key: const Key('save-product-button'),
    onPressed: saving ? null : onPressed,
    icon: AppBusyIcon(busy: saving, icon: Icons.check),
    label: Text(saving ? 'Salvando…' : 'Salvar produto'),
  );
}

class _BarcodeEditor {
  _BarcodeEditor({
    String codigo = '',
    this.tipo = 'EAN',
    this.principal = false,
    this.ativo = true,
  }) : codigo = TextEditingController(text: codigo);
  final TextEditingController codigo;
  String tipo;
  bool principal;
  bool ativo;
  void dispose() => codigo.dispose();
}

const _barcodeTypes = ['EAN', 'EAN13', 'GTIN', 'GTIN13', 'INTERNO'];
