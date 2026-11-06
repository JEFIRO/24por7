import 'package:flutter/material.dart';

import '../../core/widgets/app_content.dart';
import 'estoque_central_page.dart';
import 'estoque_condominio_page.dart';
import 'inventario_list_page.dart';
import 'movimentacao_estoque_page.dart';
import 'planograma_page.dart';
import 'transferencia_estoque_page.dart';

class EstoqueHubPage extends StatelessWidget {
  const EstoqueHubPage({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      AppContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppPageHeader(
              title: 'Estoque',
              subtitle:
                  'Saldo central da Empresa, mercados dos Condomínios e a trilha de cada movimentação.',
            ),
            const SizedBox(height: 24),
            _item(
              context,
              'Estoque central',
              'Saldo físico da Empresa, entradas, saídas e ajustes',
              Icons.warehouse_outlined,
              const EstoqueCentralPage(),
            ),
            _item(
              context,
              'Estoque dos Condomínios',
              'Disponibilidade e saldo de cada mercado',
              Icons.apartment_outlined,
              const EstoqueCondominioPage(),
            ),
            _item(
              context,
              'Transferências',
              'Mover produtos do central para um Condomínio',
              Icons.local_shipping_outlined,
              const TransferenciaEstoquePage(),
            ),
            _item(
              context,
              'Movimentações',
              'Trilha imutável de entradas, saídas e ajustes',
              Icons.receipt_long_outlined,
              const MovimentacaoEstoquePage(),
            ),
            _item(
              context,
              'Inventários',
              'Contagem física, divergências e conflitos',
              Icons.fact_check_outlined,
              const InventarioListPage(),
            ),
            _item(
              context,
              'Planograma',
              'Localização opcional dos produtos no estoque central',
              Icons.view_module_outlined,
              const PlanogramaPage(),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _item(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Widget page,
  ) => AppListRow(
    leading: AppIconWell(icon),
    title: title,
    meta: subtitle,
    trailing: const Icon(Icons.chevron_right),
    onTap: () =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
  );
}
