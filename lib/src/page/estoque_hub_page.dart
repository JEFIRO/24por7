import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_content.dart';
import '../model/estoque_repository.dart';
import '../model/inventario_repository.dart';
import '../model/produto_repository.dart';
import 'estoque_central_page.dart';
import 'estoque_condominio_page.dart';
import 'inventario_list_page.dart';
import 'movimentacao_estoque_page.dart';
import 'nota_fiscal_entrada_page.dart';
import 'planograma_page.dart';
import 'transferencia_estoque_page.dart';

/// Tela única de Estoque: saldos e histórico por local, transferências e
/// inventários em abas, e as operações do dia a dia no cabeçalho.
class EstoqueHubPage extends StatefulWidget {
  const EstoqueHubPage({super.key, this.repository, this.inventarioRepository});
  final EstoqueRepository? repository;
  final InventarioRepository? inventarioRepository;

  @override
  State<EstoqueHubPage> createState() => _EstoqueHubPageState();
}

class _EstoqueHubPageState extends State<EstoqueHubPage>
    with SingleTickerProviderStateMixin {
  static const _saldos = 0;
  static const _historico = 1;
  static const _inventarios = 3;

  late final EstoqueRepository _repository;
  late final InventarioRepository _inventarioRepository;
  late final TabController _tabs;
  List<CondominioOption> _condos = const [];
  int _tab = _saldos;

  /// Local dos saldos e do histórico: null é o estoque central.
  String? _local;

  /// Muda para recriar a aba atual e buscar os dados de novo.
  int _versao = 0;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? EstoqueRepository();
    _inventarioRepository =
        widget.inventarioRepository ?? InventarioRepository();
    _tabs = TabController(length: 4, vsync: this)
      ..addListener(() {
        if (_tabs.index != _tab) setState(() => _tab = _tabs.index);
      });
    _carregarCondominios();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _carregarCondominios() async {
    try {
      final condos = await _repository.condominios();
      if (mounted) setState(() => _condos = condos);
    } catch (_) {
      // Sem a lista, o seletor fica só com o estoque central; as abas
      // mostram o próprio erro ao carregar.
    }
  }

  void _atualizar() {
    _repository.invalidarCatalogo();
    if (_condos.isEmpty) _carregarCondominios();
    setState(() => _versao++);
  }

  Future<void> _receberPorNfe() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotaFiscalEntradaPage()),
    );
    if (mounted) _atualizar();
  }

  Future<void> _entradaManual() async {
    final changed = await movimentarEstoqueCentral(
      context,
      _repository,
      somenteEntrada: true,
    );
    if (changed && mounted) _atualizar();
  }

  Future<void> _abastecer() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransferenciaFormPage(
          repository: _repository,
          destinoInicial: _local,
        ),
      ),
    );
    if (mounted) _atualizar();
  }

  Future<void> _contar() async {
    final created = await iniciarInventario(context, _inventarioRepository);
    if (!created || !mounted) return;
    _tabs.index = _inventarios;
    _atualizar();
  }

  void _planograma() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const PlanogramaPage()),
  );

  Future<void> _novaOperacao() async {
    final action = await showModalBottomSheet<VoidCallback>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final (icon, title, subtitle, action) in [
              (
                Icons.receipt_long_outlined,
                'Receber por NF-e',
                'Ler a nota do fornecedor e dar entrada no central',
                _receberPorNfe,
              ),
              (
                Icons.add_box_outlined,
                'Entrada manual',
                'Dar entrada de um produto sem nota',
                _entradaManual,
              ),
              (
                Icons.local_shipping_outlined,
                'Abastecer condomínio',
                'Transferir produtos do central para um mercado',
                _abastecer,
              ),
              (
                Icons.fact_check_outlined,
                'Contar estoque',
                'Iniciar um inventário do estoque central',
                _contar,
              ),
            ])
              ListTile(
                leading: Icon(icon),
                title: Text(title),
                subtitle: Text(subtitle),
                onTap: () => Navigator.pop(context, action),
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.view_module_outlined),
              title: const Text('Planograma'),
              subtitle: const Text('Localização dos produtos no central'),
              onTap: () => Navigator.pop(context, _planograma),
            ),
          ],
        ),
      ),
    );
    action?.call();
  }

  List<Widget> _acoes() => [
    OutlinedButton.icon(
      onPressed: _contar,
      icon: const Icon(Icons.fact_check_outlined, size: 18),
      label: const Text('Contar estoque'),
    ),
    OutlinedButton.icon(
      onPressed: _abastecer,
      icon: const Icon(Icons.local_shipping_outlined, size: 18),
      label: const Text('Abastecer condomínio'),
    ),
    MenuAnchor(
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.receipt_long_outlined),
          onPressed: _receberPorNfe,
          child: const Text('Por NF-e'),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.add_box_outlined),
          onPressed: _entradaManual,
          child: const Text('Entrada manual'),
        ),
      ],
      builder: (context, controller, _) => FilledButton.icon(
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
        icon: const Icon(Icons.arrow_drop_down, size: 18),
        iconAlignment: IconAlignment.end,
        label: const Text('Receber mercadoria'),
      ),
    ),
    PopupMenuButton<VoidCallback>(
      tooltip: 'Mais opções',
      onSelected: (action) => action(),
      itemBuilder: (_) => [
        PopupMenuItem(value: _planograma, child: const Text('Planograma')),
      ],
    ),
  ];

  Widget _seletorDeLocal(bool mobile) => SizedBox(
    width: mobile ? double.infinity : 320,
    child: DropdownButtonFormField<String?>(
      initialValue: _local,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Local',
        prefixIcon: Icon(
          _local == null ? Icons.warehouse_outlined : Icons.apartment_outlined,
        ),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('Estoque central')),
        for (final c in _condos)
          DropdownMenuItem(
            value: c.id,
            child: Text(c.nome, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (value) => setState(() => _local = value),
    ),
  );

  Widget _header(bool mobile) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AppPageHeader(
        title: 'Estoque',
        subtitle: 'Saldos, entradas, transferências e contagens da Empresa.',
        onRefresh: _atualizar,
        actions: mobile ? const [] : _acoes(),
      ),
      const SizedBox(height: AppSpacing.lg),
      TabBar(
        controller: _tabs,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        // Mais justo no celular, para as quatro abas caberem sem rolar.
        labelPadding: mobile
            ? const EdgeInsets.symmetric(horizontal: AppSpacing.sm)
            : null,
        tabs: const [
          Tab(text: 'Saldos'),
          Tab(text: 'Histórico'),
          Tab(text: 'Transferências'),
          Tab(text: 'Inventários'),
        ],
      ),
      const SizedBox(height: AppSpacing.xl),
      if (_tab == _saldos || _tab == _historico) ...[
        _seletorDeLocal(mobile),
        const SizedBox(height: AppSpacing.lg),
      ],
    ],
  );

  @override
  Widget build(BuildContext context) {
    final mobile = AppBreakpoints.isMobile(context);
    final header = _header(mobile);
    // A chave recria a aba ao trocar de aba ou de local e ao atualizar.
    final key = ValueKey('$_tab|$_local|$_versao');
    final local = _local;
    return Scaffold(
      floatingActionButton: mobile
          ? FloatingActionButton.extended(
              onPressed: _novaOperacao,
              icon: const Icon(Icons.add),
              label: const Text('Nova operação'),
            )
          : null,
      body: switch (_tab) {
        _saldos when local == null => EstoqueCentralPage(
          key: key,
          repository: _repository,
          header: header,
        ),
        _saldos => EstoqueCondominioPage(
          key: key,
          condominioId: local!,
          repository: _repository,
          header: header,
        ),
        _historico => MovimentacaoEstoquePage(
          key: key,
          repository: _repository,
          condominioId: local,
          header: header,
        ),
        _inventarios => InventarioListPage(
          key: key,
          repository: _inventarioRepository,
          header: header,
        ),
        _ => TransferenciaEstoquePage(
          key: key,
          repository: _repository,
          header: header,
        ),
      },
    );
  }
}
