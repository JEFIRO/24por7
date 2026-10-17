# Inventário físico

O hub de Estoque abre a lista de Inventários. A primeira versão da UI inicia contagem do Estoque Central, com descrição opcional e modo cego; o model já representa o tipo de localização retornado pela API.

A lista oferece histórico, filtro por status, loading, vazio, erro/retry e atualização. O detalhe mostra progresso, contados, pendentes, divergências e conflitos, além de busca por nome, SKU ou barcode e filtros `TODOS`, `PENDENTE`, `OK`, `FALTA`, `SOBRA` e `CONFLITO`.

Cada item apresenta Produto, SKU, barcode e localização do Planograma quando disponível. A quantidade digitada passa por `DecimalValue` com no máximo três casas. O app não calcula nem aplica saldo: envia a contagem ao backend e sempre reexibe o DTO devolvido.

No modo cego, saldo e diferença ficam ocultos enquanto a contagem está aberta. Finalização pode retornar `COM_CONFLITO`; nesse caso a tela destaca o saldo atual e exige recontagem. Cancelar preserva estoque. Botões ficam bloqueados durante operações e todos os fluxos encerram loading com sucesso ou erro recuperável.

