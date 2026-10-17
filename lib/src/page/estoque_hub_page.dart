import 'package:flutter/material.dart';

import 'estoque_central_page.dart';
import 'estoque_condominio_page.dart';
import 'inventario_list_page.dart';
import 'movimentacao_estoque_page.dart';
import 'planograma_page.dart';
import 'transferencia_estoque_page.dart';

class EstoqueHubPage extends StatelessWidget {
  const EstoqueHubPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Estoque')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _item(
          context,
          'Inventários',
          'Contagem física, divergências e conflitos',
          Icons.fact_check,
          const InventarioListPage(),
        ),
        _item(
          context,
          'Estoque da Empresa',
          'Saldo físico do estoque central',
          Icons.warehouse,
          const EstoqueCentralPage(),
        ),
        _item(
          context,
          'Estoque dos Condomínios',
          'Disponibilidade e saldo de cada mercado',
          Icons.apartment,
          const EstoqueCondominioPage(),
        ),
        _item(
          context,
          'Transferências',
          'Mover produtos do central para um condomínio',
          Icons.local_shipping,
          const TransferenciaEstoquePage(),
        ),
        _item(
          context,
          'Movimentações',
          'Trilha imutável de entradas, saídas e ajustes',
          Icons.receipt_long,
          const MovimentacaoEstoquePage(),
        ),
        _item(
          context,
          'Planograma',
          'Localização opcional no estoque central',
          Icons.view_module,
          const PlanogramaPage(),
        ),
      ],
    ),
  );
  Widget _item(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Widget page,
  ) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: CircleAvatar(child: Icon(icon)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
    ),
  );
}
