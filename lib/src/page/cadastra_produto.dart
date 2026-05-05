import 'dart:convert';

import 'package:app_24por7/src/model/Produto.dart';
import 'package:app_24por7/src/model/ProdutoAPI.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'ScannerPage.dart';

class CadastraProduto extends StatefulWidget {
  const CadastraProduto({super.key});

  @override
  State<CadastraProduto> createState() => _CadastraProdutoState();
}

class _CadastraProdutoState extends State<CadastraProduto> {
  final _formKey = GlobalKey<FormState>();

  final barCodeController = TextEditingController();
  final nomeController = TextEditingController();
  final descricaoController = TextEditingController();
  final precoController = TextEditingController();
  final custoController = TextEditingController();
  final estoqueController = TextEditingController();
  final pesoController = TextEditingController();
  final toleranciaController = TextEditingController();

  final FocusNode barCodeFocus = FocusNode();

  String? categoria;
  String unidade = "UN";
  bool ativo = true;

  final categorias = ["Alimentos", "Bebidas", "Limpeza", "Outros"];
  final unidades = ["UN", "KG", "L"];

  @override
  void dispose() {
    barCodeController.dispose();
    nomeController.dispose();
    descricaoController.dispose();
    precoController.dispose();
    custoController.dispose();
    estoqueController.dispose();
    pesoController.dispose();
    toleranciaController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    barCodeFocus.addListener(() {
      if (!barCodeFocus.hasFocus) {
        buscarProdutoPorCodigo(barCodeController.text);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFD6D1D1),
      appBar: AppBar(title: Text('Cadastro de Produto')),
      body: Padding(
        padding: EdgeInsets.all(8),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _SectionCard(
                icon: Icons.qr_code_rounded,
                iconColor: const Color(0xFF185FA5),
                iconBackground: const Color(0xFFE6F1FB),
                label: 'Identificação',
                children: [
                  _buildBarcodeField(),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: nomeController,
                    label: 'Nome',
                    hint: 'Nome do produto',
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Obrigatório' : null,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: descricaoController,
                    label: 'Descrição',
                    maxLines: 3,
                    hint: 'Breve descrição do produto...',
                  ),
                ],
              ),
              _SectionCard(
                icon: Icons.attach_money,
                iconColor: Colors.black,
                iconBackground: const Color(0xFFE6F1FB),
                label: 'Valores',
                children: [
                  _buildTextField(
                    controller: precoController,
                    label: 'Preço',
                    keyboardType: TextInputType.numberWithOptions(),
                  ),
                ],
              ),

              _SectionCard(
                icon: Icons.shopping_bag,
                iconColor: Colors.black,
                iconBackground: const Color(0xFFE6F1FB),
                label: 'Quantidade e peso ',
                children: [
                  _buildTextField(
                    controller: estoqueController,
                    label: "Estoque",
                    hint: 'Itens em seu estoque',
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 10),
                  _ChipSelector(
                    options: unidades,
                    selected: unidade,
                    onSelected: (v) => setState(() => unidade = v),
                  ),
                  SizedBox(height: 25),
                  _buildTextField(
                    controller: pesoController,
                    label: 'Peso',
                    hint: 'Peso de uma unidade do seu produto',
                    keyboardType: TextInputType.numberWithOptions(),
                  ),
                  SizedBox(height: 10),
                  _buildTextField(
                    controller: toleranciaController,
                    label: 'Tolerancia',
                    hint: 'Toleracia que o sistema pode ter do seu produto',
                    keyboardType: TextInputType.numberWithOptions(),
                  ),
                ],
              ),
              _SectionCard(
                icon: Icons.info_outline,
                iconColor: Colors.green,
                iconBackground: const Color(0xFFE6F1FB),
                label: 'Categoria',
                children: [
                  _ChipSelector(
                    options: categorias,
                    selected: categoria ?? '',
                    onSelected: (v) => setState(() => categoria = v),
                  ),
                  const Divider(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Produto ativo',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Visível no sistema e ponto de venda',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: ativo,
                        onChanged: (v) => setState(() => ativo = v),
                        activeColor: const Color(0xFF1D9E75),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: FilledButton(
            onPressed: _salvar,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF185FA5),
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Salvar produto',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBarcodeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Código de barras'),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: barCodeController,
                focusNode: barCodeFocus,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Digitar ou escanear...',
                  prefixIcon: const Icon(Icons.barcode_reader, size: 18),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF185FA5)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null,
              ),
            ),
            const SizedBox(width: 8),
            _ScanButton(
              onPressed: () async {
                final result = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(builder: (_) => ScannerPage()),
                );
                if (result != null) {
                  barCodeController.text = result;
                  final produto = await buscarProdutoPorCodigo(result);
                  if (produto != null) {
                    setState(() {
                      nomeController.text = produto.nome;
                      descricaoController.text = produto.descricao ?? '';
                    });
                  }
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? prefixText,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefixText,
            filled: true,
            fillColor: const Color(0xFFF5F5F0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF185FA5)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Colors.grey[500],
        letterSpacing: 0.5,
      ),
    );
  }

  Future<ProdutoAPI?> buscarProdutoPorCodigo(String codigo) async {
    final url = Uri.parse(
      "https://world.openfoodfacts.org/api/v0/product/$codigo.json",
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["status"] == 1) {
          return ProdutoAPI.fromJson(data);
        }
      }
    } catch (e) {
      print("Erro ao buscar produto: $e");
    }

    return null;
  }

  Future<void> _salvar() async {
    if (_formKey.currentState!.validate()) {
      final produto = Produto(
        codigo: barCodeController.text,
        nome: nomeController.text,
        descricao: descricaoController.text.isEmpty
            ? null
            : descricaoController.text,
        preco: double.parse(precoController.text),
        quantidade: int.tryParse(estoqueController.text) ?? 0,
        unidadeMedida: unidade,
        categoria: categoria ?? 'Outros',
        foto: null,
        peso: double.tryParse(pesoController.text) ?? 0,
        pesoTolerancia: double.tryParse(toleranciaController.text) ?? 0,
      );

      final url = Uri.parse("http://192.168.86.7:8080/produtos/salvar");
      try {
        final response = await http.post(
          url,
          headers: {
            "Content-Type": "application/json",
          },
          body: jsonEncode(produto.toJson()),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text('Produto salvo com sucesso'),
                ],
              ),
              backgroundColor: const Color(0xFF1D9E75),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } catch (e) {
        print("Erro ao buscar produto: $e");
      }
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.label,
    required this.children,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 15, color: iconColor),
              ),
              const SizedBox(width: 8),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[500],
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  const _ScanButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF185FA5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.qr_code_scanner_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

class _ChipSelector extends StatelessWidget {
  const _ChipSelector({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = option == selected;
        return GestureDetector(
          onTap: () => onSelected(option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFE6F1FB)
                  : const Color(0xFFF5F5F0),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF85B7EB)
                    : const Color(0xFFE0E0E0),
              ),
            ),
            child: Text(
              option,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? const Color(0xFF0C447C) : Colors.grey[600],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
