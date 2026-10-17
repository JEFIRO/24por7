# Promoções

O menu inicial abre a área de promoções. A listagem oferece filtros por abrangência, status calculado e condomínio, além de loading, erro/retry e empty state.

O formulário cria e edita nome, descrição, abrangência, condomínio, tipo, valor, início/fim, produtos, habilitação e prioridade. Na abrangência Empresa carrega o catálogo da empresa; em Condomínio cruza o catálogo com `EstoqueCondominio.ativo`. A seleção permite busca, marcar os visíveis e limpar.

O app envia valor como string decimal normalizada com seis casas e datas convertidas para UTC. Não calcula preço promocional: valida somente a entrada; o backend é a autoridade.
