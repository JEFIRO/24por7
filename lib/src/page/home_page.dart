import 'package:flutter/material.dart';

import 'cadastra_produto.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [Text('24/7')],
        ),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  color: Colors.white,
                  elevation: 10,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: (){
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CadastraProduto(),
                        ),
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Cadastro',
                                    style: TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  SizedBox(width: 5),
                                  Icon(Icons.add),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    'Cadastrar novo item',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Icon(Icons.keyboard_arrow_right_sharp),
                        ],
                      ),
                    ),
                  ),
                ),
                Card(
                  color: Colors.white,
                  elevation: 10,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: (){
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CadastraProduto(),
                        ),
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Buscar Produto',
                                    style: TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  SizedBox(width: 5),
                                  Icon(Icons.search),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    'Emcontrar um item',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Icon(Icons.keyboard_arrow_right_sharp),
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}


