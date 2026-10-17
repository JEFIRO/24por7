# Telas

- Login administrativo: CPF, senha, loading e mensagem de erro.
- Home: acesso destacado a Promoções e aos fluxos existentes de Produto.
- Produtos: lista com SKU, barcode principal/quantidade de códigos, preço e status; loading, erro/retry, vazio e refresh.
- Cadastro/edição de Produto: dados comerciais, vários códigos de barras, principal, fiscal opcional e ativo.
- Associação ao Condomínio: seleção do Condomínio, quantidade inicial com três casas (inclusive negativa) e disponibilidade. É executada após o cadastro ou pela edição.
- Condomínios e Terminais: filtro por Condomínio, heartbeat/status, telemetria e Point vinculada.
- Onboarding: gestor, Empresa, primeiro Condomínio e primeiro Terminal no contrato agregado do backend.
- Lista de promoções: filtros, cards, status automático, pull-to-refresh e nova promoção.
- Cadastro/edição: campos dinâmicos por abrangência/tipo, datas e seleção múltipla.
- Detalhes: regra, período, prioridade, produtos, editar e ativar/desativar.
- Monitoramento: resumo, filtros por status/condomínio, cards operacionais e atualização a cada 20 segundos.
- Detalhes do Terminal: Status, Sistema, Energia, Rede, Aplicação, Display, alertas e gráficos de 1h/6h/24h/7d.
- Estoque: hub para estoque central, saldos dos Condomínios, transferências, movimentações e planograma.
- Estoque central: busca por nome/SKU/barcode, saldo e localização, entrada, saída e ajuste com motivo e quantidade exata de três casas.
- Transferências: lista histórica, criação com seleção múltipla, revisão, confirmação, cancelamento de rascunho, detalhe dos itens e movimentos.
- Planograma: lista/formulário, posições textuais e associação opcional de produtos; não há editor gráfico nesta versão.
- Inventários: histórico, nova contagem central, modo cego, busca/filtros, progresso, divergências, conflito por versão, finalização e cancelamento.
- Importar Produtos: download do modelo oficial, seleção XLSX, validação, preview, erros por linha, confirmação e acompanhamento do job.
- Dashboard: resumo real de saúde dos Terminais, ocorrências e checklist interativo de implantação.
- Mercado Pago: estados de conta não vinculada, conta vinculada sem Point e configuração completa; lista e associação de Points.
- Shell responsiva: bottom navigation no mobile, rail no tablet e sidebar por domínio no desktop.
- Condomínios e Terminais: cadastro, edição, desativação de Condomínio, filtro, cadastro/edição de Terminal e acesso à telemetria.

As telas usam o `ThemeData` Material 3 central do app e não mantêm paletas paralelas.
