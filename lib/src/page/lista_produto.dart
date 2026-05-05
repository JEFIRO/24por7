import 'dart:convert';

import 'package:app_24por7/src/model/Produto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ListaProduto extends StatefulWidget {
  const ListaProduto({super.key});

  @override
  State<ListaProduto> createState() => _ListaProdutoState();
}

class _ListaProdutoState extends State<ListaProduto> {
  bool isLoading = false;
  List<Produto> produtos = [];

  @override
  void initState() {
    _buscar();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Listagem de itens')),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: produtos.length,
                itemBuilder: (context, index) {
                  final produto = produtos[index];
                  return Card(
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
                            style: TextStyle(color: Colors.grey[600]),
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
                          if (produto!.descricao != null &&
                              produto!.descricao!.isNotEmpty)
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
                  );
                },
              ),
      ),
    );
  }

  Future<void> _buscar() async {
    final url = Uri.parse("http://192.168.86.7:8080/produtos");

    setState(() => isLoading = true);

    try {
      final response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final List lista = data['content'];

        setState(() {
          produtos = lista.map((e) => Produto.fromJson(e)).toList();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produtos encontrados'),
            backgroundColor: Color(0xFF1D9E75),
          ),
        );
      } else if (response.statusCode == 404) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produtos não encontrado'),
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
