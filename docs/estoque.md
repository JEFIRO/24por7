# Estoque central, transferências e planograma

A Home possui a área **Estoque**, com seis entradas:

- Estoque da Empresa: saldo físico central, busca por nome/SKU/barcode, filtros de categoria/status e entrada/saída/ajuste;
- Estoque dos Condomínios: consulta à associação operacional existente;
- Transferências: central para um Condomínio, com múltiplos produtos;
- Movimentações: histórico de deltas e saldos;
- Planograma: localização física opcional.
- Inventários: contagem física central, modo cego e ajuste auditável com tratamento de conflito.

`DecimalValue` mantém quantidades sem `double`; os requests enviam texto normalizado com três casas. Entrada e saída exigem valor positivo. Ajuste aceita saldo negativo porque o backend preserva essa política.

O fluxo de transferência cria um rascunho, mostra a revisão e confirma a mesma transferência. O detalhe permite confirmar ou cancelar apenas enquanto está em `RASCUNHO`. A resposta exibe o nome do Condomínio e os dois movimentos correlacionados quando concluída.

Planograma nesta versão é formulário/lista. A localização compacta concatena corredor, estante, prateleira e posição. Capacidade é exibida separadamente do saldo. Produto sem posição funciona normalmente.

Todas as chamadas usam o token administrativo e não enviam `empresa_id`; o backend obtém o tenant pelo JWT/`EmpresaContext`.

Importação de produtos é acessada pela lista do catálogo e pode criar saldo inicial central, sempre acompanhado de movimento. Ela não cria disponibilidade em Condomínio. Veja [Inventário](inventario.md) e [Importação](importacao-produtos.md).
