# Importação de produtos

A ação **Importar planilha** fica na lista de Produtos e implementa as seis etapas: baixar modelo, preencher, selecionar, validar, revisar e importar.

`file_picker` seleciona o XLSX e entrega seus bytes ao `ApiClient`; o app não interpreta planilhas. O backend devolve linhas e totais da validação. Só é possível confirmar `VALIDADA` sem erros. Após `202`, a tela acompanha o job em intervalos de dois segundos, por tempo limitado, e permite consultar erros sem manter a requisição de importação aberta.

O modelo é sempre obtido de `GET /produtos/importacao/modelo`, evitando uma cópia desatualizada dentro do app. Na primeira versão somente `.xlsx` é suportado; CSV não foi incluído. A importação opera em `SOMENTE_NOVOS` e a Empresa vem do JWT.

Estados exibidos: `VALIDADA`, `VALIDADA_COM_ERROS`, `PROCESSANDO`, `CONCLUIDA`, `CONCLUIDA_COM_ERROS` e `FALHOU`. O resultado mostra produtos, barcodes, estoques criados e erros por aba/linha. O app não cria `EstoqueCondominio` nesse fluxo: saldo da planilha é exclusivamente central.

