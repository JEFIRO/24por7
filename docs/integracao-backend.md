# Integração com o backend novo

O Flutter consome DTOs; nenhuma tela depende de entidades JPA. `ApiClient` centraliza URL, JWT, timeout e tradução de erros, enquanto repositories separam Produto, Promoção, Telemetria e operações de Condomínio/Terminal.

## Produto

| Backend | Flutter | Regra |
|---|---|---|
| `codigoInterno` | `Produto.codigoInterno` | SKU único somente dentro da Empresa |
| `codigosBarras[]` | `ProdutoCodigoBarras[]` | vários códigos, exatamente um principal |
| `preco` | `DecimalValue` | string exata com até seis casas |
| `peso`, `pesoTolerancia` | `DecimalValue?` | decimal opcional |
| `fiscal` | `ProdutoFiscal?` | seção opcional, somente campos implementados |
| `ativo` | `Produto.ativo` | soft delete/status comercial |

O formulário separa SKU de barcode, permite adicionar/remover códigos e definir o principal. Conflito de barcode no mesmo tenant apresenta mensagem amigável. O mesmo barcode em empresas diferentes é permitido pelo backend e não sofre validação global no app.

Disponibilizar produto é operação separada: `POST /condominios/{id}/estoque`. Quantidade usa até três casas, aceita sinal negativo e nunca é convertida para inteiro ou `double`.

## Condomínio, Terminal e onboarding

- `GET /condominios` e `GET /terminais` usam o tenant do JWT.
- A tela operacional possui loading, erro/retry, vazio, refresh e filtro por Condomínio.
- `POST /onboarding` recebe os blocos `gestor`, `empresa`, `condominio` e `terminal` compatíveis com o controller.
- Point, heartbeat e telemetria continuam atributos operacionais do Terminal; o app não tenta monitorar a maquininha.

## Compatibilidade com Product Sync

O Flutter configura catálogo e disponibilidade. O backend emite `PRODUCT_SYNC_REQUIRED`; o Terminal recebe DTO com SKU, lista de barcodes, valores precisos e promoção calculada. O Flutter não grava SQLite nem calcula promoção.

## Limites desta entrega

O cadastro preserva a URL de foto existente, mas não implementa um novo seletor/upload de imagem. O fluxo completo de retry de múltiplas tentativas de pagamento também permanece fora deste app administrativo.
