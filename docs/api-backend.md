# API do backend

A URL é configurada com `--dart-define=API_URL=https://...`; o padrão do emulador Android é `http://10.0.2.2:8080`. O login usa `POST /auth/login/admin` e o token recebido é enviado como `Authorization: Bearer`.

Produtos usam `GET /produtos`, `GET /produtos/id?id={uuid}`, `GET /produtos/{codigo}`, `POST /produtos` e `PUT /produtos/{id}`. O JSON separa `codigoInterno`, `codigosBarras[]`, dados comerciais, `ativo` e `fiscal` opcional. Cadastro sem nova foto usa JSON; multipart continua disponível no backend. Disponibilidade usa `POST /condominios/{id}/estoque` com `produtoId`, `quantidade` decimal e `ativo`.

Promoções usam `GET/POST /promocoes`, `GET/PUT /promocoes/{id}` e `PATCH /promocoes/{id}/status`. Condomínios vêm de `GET /condominios`; Terminais, de `GET /terminais`. Onboarding usa `POST /onboarding` com quatro blocos: gestor, empresa, primeiro condomínio e primeiro Terminal.

Erros HTTP são convertidos em `ApiException` com a mensagem segura do backend. A empresa nunca é enviada no corpo: o tenant é resolvido pelo JWT.

Mercado Pago usa `GET /mercado-pago/status`, `GET /mercado-pago/terminais`, `GET /mercado-pago/oauth`, `PUT /terminais/{id}/mercado-pago` e `DELETE /terminais/{id}/mercado-pago`. O redirect OAuth é solicitado com bearer ao backend e somente a URL externa resultante é aberta pelo app.

Condomínios usam `POST/GET/PUT/DELETE /condominios`; Terminais usam `POST /condominios/{id}/terminais`, `GET /terminais` e `PUT /terminais/{id}`. O contrato atual não permite mover um Terminal entre Condomínios na edição.

Conflito de barcode da mesma Empresa retorna mensagem de domínio exibida como “Este código de barras já está associado a outro produto.”. Quantidade negativa de estoque é válida. Valores monetários são strings exatas de seis casas; quantidades/pesos administrativos não passam por `double`.

Monitoramento usa `GET /terminais/monitoramento` com filtros opcionais `condominioId` e `status`, `GET /terminais/{id}/telemetria`, `GET /terminais/{id}/telemetria/historico?period=1h|6h|24h|7d` e `GET /terminais/{id}/telemetria/alertas`. Todos são administrativos e filtrados pelo tenant do JWT. O app não chama o endpoint de ingestão do Terminal.

Estoque central usa `GET /estoque-empresa`, `GET /estoque-empresa/produtos`, `POST /estoque-empresa/{produtoId}/entrada`, `POST /estoque-empresa/{produtoId}/saida`, `PUT /estoque-empresa/{produtoId}` e `GET /estoque-empresa/movimentacoes`. Quantidades são enviadas como strings com três casas; ajuste representa o novo saldo absoluto.

Transferências usam `POST/GET /transferencias-estoque`, detalhe em `GET /transferencias-estoque/{id}` e ações `POST /{id}/confirmar|cancelar`. A UI cria um rascunho e confirma a mesma ID, nunca duplica o efeito de uma confirmação já concluída.

Planogramas usam `GET/POST /planogramas`, posições em `/planogramas/{id}/posicoes` e produtos em `/planogramas/posicoes/{id}/produtos`. Remover posicionamento não remove o Produto nem altera saldo.

Inventários usam `POST/GET /inventarios`, `GET /inventarios/{id}`, `PUT /inventarios/{id}/itens/{itemId}/contagem` e `POST /inventarios/{id}/finalizar|cancelar`. A UI atual inicia `ESTOQUE_EMPRESA`; quantidade é string decimal com três casas e o backend controla snapshot, conflitos e ajustes.

Importação usa `GET /produtos/importacao/modelo`, `POST /produtos/importacao/validar` multipart, `GET /produtos/importacao/{id}`, `POST /produtos/importacao/{id}/confirmar` e `GET /produtos/importacao/{id}/erros`. Confirmar devolve `202`; progresso é consultado sem enviar Empresa no body.
