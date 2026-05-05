import 'package:app_24por7/src/model/Produto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'ScannerPage.dart';

class BuscarProduto extends StatefulWidget {
  const BuscarProduto({super.key});

  @override
  State<BuscarProduto> createState() => _BuscarProdutoState();
}

class _BuscarProdutoState extends State<BuscarProduto> {
  TextEditingController barCodeController = TextEditingController();
  Produto? produto;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Busca Produtos')),

      body: Padding(
        padding: EdgeInsets.all(12),
        child: ListView(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 10,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextField(
                      controller: barCodeController,
                      readOnly: true, // 🔒 impede digitação
                      decoration: InputDecoration(
                        labelText: 'Código de barras',
                        hintText: 'Use o scanner',
                        prefixIcon: const Icon(Icons.search),

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),

                        suffixIcon: IconButton(
                          onPressed: () async {
                            final result = await Navigator.push<String>(
                              context,
                              MaterialPageRoute(builder: (_) => ScannerPage()),
                            );

                            if (result != null) {
                              barCodeController.text = result;
                              _buscar(result);
                            }
                          },
                          icon: const Icon(Icons.qr_code_scanner),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (produto != null)
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (produto!.foto != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            produto!.foto!,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      // 📦 Nome + categoria
                      Text(
                        produto!.nome,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        produto!.categoria,
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),

                      const Divider(height: 20),

                      // 💰 Preço
                      Text(
                        "Preço: R\$ ${produto!.preco.toStringAsFixed(2)}",
                        style: const TextStyle(fontSize: 16),
                      ),

                      // 📊 Quantidade
                      Text(
                        "Estoque: ${produto!.quantidade} ${produto!.unidadeMedida}",
                      ),

                      // ⚖️ Peso
                      Text(
                        "Peso: ${produto!.peso} ${produto!.unidadeMedida}",
                      ),

                      Text(
                        "Tolerância: ±${produto!.pesoTolerancia}",
                        style: TextStyle(color: Colors.grey[700]),
                      ),

                      const SizedBox(height: 10),

                      // 📝 Descrição (se tiver)
                      if (produto!.descricao != null && produto!.descricao!.isNotEmpty)
                        Text(
                          produto!.descricao!,
                          style: TextStyle(color: Colors.grey[800]),
                        ),

                      const SizedBox(height: 10),

                      // 🔢 Código
                      Text(
                        "Código: ${produto!.codigo}",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              const Center(child: Text("Nenhum produto carregado")),
          ],
        ),
      ),
    );
  }

  Future<void> _buscar(String codigo) async {
    final url = Uri.parse("http://192.168.86.7:8080/produtos/$codigo");

    setState(() => isLoading = true);

    try {
      final response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          produto = Produto.fromJson(data);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produto encontrado com sucesso'),
            backgroundColor: Color(0xFF1D9E75),
          ),
        );
      } else if (response.statusCode == 404) {
        setState(() => produto = null);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produto não encontrado'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print("Erro ao buscar produto: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro de conexão'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => isLoading = false);
  }
}
