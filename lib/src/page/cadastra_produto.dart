import 'package:flutter/material.dart';
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cadastro de Produto')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// 🔢 CÓDIGO DE BARRAS
                TextFormField(
                  controller: barCodeController,
                  decoration: InputDecoration(
                    labelText: "Código de barras",
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.camera_alt),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ScannerPage(),
                          ),
                        );

                        if (result != null) {
                          barCodeController.text = result;
                        }
                      },
                    ),
                  ),
                  validator: (v) =>
                  v == null || v.isEmpty ? "Obrigatório" : null,
                ),

                SizedBox(height: 16),

                /// 📦 NOME
                TextFormField(
                  controller: nomeController,
                  decoration: InputDecoration(
                    labelText: "Nome",
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                  v == null || v.isEmpty ? "Obrigatório" : null,
                ),

                SizedBox(height: 16),

                /// 📝 DESCRIÇÃO
                TextFormField(
                  controller: descricaoController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: "Descrição",
                    border: OutlineInputBorder(),
                  ),
                ),

                SizedBox(height: 16),

                /// 💰 PREÇO E CUSTO
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: precoController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Preço",
                          prefixText: "R\$ ",
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                        v == null || double.tryParse(v) == null
                            ? "Inválido"
                            : null,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: custoController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Custo",
                          prefixText: "R\$ ",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                /// 📊 ESTOQUE E PESO
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: estoqueController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Estoque",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: pesoController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Peso",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                /// 🏷️ CATEGORIA
                DropdownButtonFormField(
                  value: categoria,
                  items: categorias
                      .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => categoria = value);
                  },
                  decoration: InputDecoration(
                    labelText: "Categoria",
                    border: OutlineInputBorder(),
                  ),
                ),

                SizedBox(height: 16),

                /// ⚖️ UNIDADE
                DropdownButtonFormField(
                  value: unidade,
                  items: unidades
                      .map((u) => DropdownMenuItem(
                    value: u,
                    child: Text(u),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => unidade = value!);
                  },
                  decoration: InputDecoration(
                    labelText: "Unidade",
                    border: OutlineInputBorder(),
                  ),
                ),

                SizedBox(height: 16),

                /// 🔘 ATIVO
                SwitchListTile(
                  title: Text("Produto ativo"),
                  value: ativo,
                  onChanged: (value) {
                    setState(() => ativo = value);
                  },
                ),

                SizedBox(height: 24),

                /// 💾 SALVAR
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final produto = {
                          "codigo": barCodeController.text,
                          "nome": nomeController.text,
                          "descricao": descricaoController.text,
                          "preco": double.parse(precoController.text),
                          "custo": custoController.text.isEmpty
                              ? 0
                              : double.parse(custoController.text),
                          "estoque": estoqueController.text,
                          "peso": pesoController.text,
                          "categoria": categoria,
                          "unidade": unidade,
                          "ativo": ativo,
                        };

                        print(produto);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Produto salvo com sucesso")),
                        );
                      }
                    },
                    child: Text("Salvar Produto"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}