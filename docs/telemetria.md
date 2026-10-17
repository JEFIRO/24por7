# Telemetria e monitoramento

O menu Monitoramento apresenta resumo de Terminais, Online, Saudáveis, Atenção, Críticos e Offline. A lista aceita filtro por status e condomínio, oferece pull-to-refresh, loading, erro/retry e empty state, e atualiza automaticamente a cada 20 segundos — sem polling por segundo.

Cada card mostra presença pelo heartbeat, classificação calculada pelo backend, principais motivos, CPU, temperatura, RAM, disco, Wi-Fi e último sinal. A tela detalhada separa Status, Sistema, Energia, Rede, Aplicação e Display. Subtensão recebe um card destacado que diferencia condição atual de ocorrência histórica desde o boot.

O histórico possui períodos de 1h, 6h, 24h e 7d e seis gráficos leves feitos com `CustomPainter`: temperatura, CPU, RAM, disco, latência e sinal Wi-Fi. Alertas ativos/resolvidos aparecem com abertura e estado. Métrica `null` é exibida como “Indisponível”, nunca como zero.

O app apenas exibe DTOs calculados pelo backend. Não calcula thresholds, presença nem gravidade, não acessa a Point Mercado Pago e não recebe senha Wi-Fi, credenciais ou dados de clientes.
