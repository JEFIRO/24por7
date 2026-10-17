# Arquitetura do app administrativo

`ApiClient` concentra URL, JWT, JSON, timeout e erros. `ProdutoRepository`, `PromocaoRepository`, `OperationalRepository` e `TerminalTelemetryRepository` representam contratos distintos do backend. Nenhuma tela consome entidade JPA diretamente.

O estado atual permanece local aos `StatefulWidget`, coerente com o pequeno projeto existente e sem nova dependência. Listagem e formulário injetam o repositório, permitindo testes.

`TerminalTelemetryRepository` concentra dashboard, detalhe, histórico e alertas. `MonitoringDashboardPage` e `TerminalTelemetryDetailPage` mantêm estado/polling local e cancelam timers no `dispose`; o backend permanece responsável por presença, thresholds e classificação. Os seis gráficos usam `CustomPainter`, sem dependência adicional. Modelos preservam `null` para métricas indisponíveis.

Dinheiro usa `DecimalValue`, uma representação textual exata. Ela limita seis casas, envia `DECIMAL(15,6)` como string e formata duas casas por inteiro escalado; não usa `double` em operações financeiras. Quantidade e peso também usam `DecimalValue` nos novos contratos para preservar três casas e valores negativos de estoque.

O cadastro de Produto modela separadamente SKU, vários barcodes e fiscal opcional. A associação a Condomínio é outra chamada, pois cria `EstoqueCondominio`, não outro Produto.

O módulo administrativo de estoque usa `EstoqueRepository` como fronteira para estoque central, transferências, movimentos e planograma. Inventário usa `InventarioRepository`; upload/modelo/job de importação usam `ImportacaoProdutoRepository`. `EstoqueHubPage` foi encaixada na navegação existente sem substituir a Home. O Terminal Python não participa desses contratos administrativos; ele recebe somente o catálogo do Condomínio pelo Product Sync existente.

O seletor de arquivo usa `file_picker`; o parser XLSX permanece exclusivamente no backend. O polling de importação é limitado e a tela verifica `mounted` antes de atualizar estado. Inventário e importação usam DTOs próprios, sem expor entidades JPA.

`AppTheme`, tokens e widgets de `lib/core` formam o Design System. `HomePage` é a shell adaptativa: barra inferior abaixo de 600 px, `NavigationRail` entre 600 e 1023 px e sidebar expandida a partir de 1024 px. Rotas nomeadas preservam URLs Web e suportam abertura direta de Produto e Terminal.

`MercadoPagoRepository` consulta o estado de setup, lista Points e vincula a maquininha ao Terminal. O início do OAuth captura o redirect autenticado do backend e abre apenas a URL do provedor, sem repassar JWT ou segredo ao Mercado Pago.

O JWT administrativo continua somente em memória. Em 401 a sessão é limpa e o navegador retorna ao Login. Persistência Web segura depende de um contrato backend futuro com cookie `HttpOnly`; não foi substituída por `localStorage`.
