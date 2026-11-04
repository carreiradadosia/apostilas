---
title: "25. Glossário"
date: 2026-11-04
type: capitulo
status: draft
project: zambotto-mentoria
tags:
  - engenharia-de-dados
  - modelagem
  - apostila
  - mentoria
---

> Capítulo gerado a partir da [apostila completa](../apostila.md), que é a fonte. Não edite este arquivo: a correção entra na `apostila.md`, e os capítulos são gerados de novo.

[Índice](../README.md#capítulos) · [Anterior: 24. Plano de continuidade](24-plano-de-continuidade.md) · [Próximo: Referências e Fontes verificadas (2026-11-04)](26-referencias.md)

## 25. Glossário

"Esqueci o que esse termo quer dizer. Onde confiro sem reler o capítulo?" Aqui. Cada termo tem uma definição curta, na mesma grafia dos capítulos. Use a lista para consultar e para alinhar a conversa com o time. Quando duas pessoas usam a mesma palavra com sentidos diferentes, o número também diverge.

Antes do SQL, decida o que uma linha significa. Por isso, se for ler só um termo, leia **Grão**, em 25.2.

### 25.1 Camadas

"Em que camada isto fica?"

- **Arquitetura medalhão:** Organização do dado em camadas de qualidade crescente: bronze, silver e gold. Prática recomendada, não requisito.
- **Bronze:** Camada do dado cru, como chegou da origem, com validação mínima.
- **Silver:** Camada do dado limpo e validado. Na mentoria, onde mora a regra que conserta registro a registro sem mudar o grão.
- **Gold:** Camada pronta para o negócio. Na mentoria, onde mora o que junta ou agrega, como a estrela.

### 25.2 Modelo

"O que uma linha significa, e como as tabelas se ligam?"

- **Grão:** O que uma linha da tabela significa. Na fato de vendas, um item de pedido.
- **Fato:** Medição de um evento de negócio, quase sempre numérica.
- **Dimensão:** Contexto do evento, com os atributos usados para filtrar e agrupar.
- **Medida:** Coluna numérica da fato que se resume.
- **Chave natural:** Identificador que vem do sistema de origem.
- **Chave substituta:** Chave própria da dimensão, sem significado de negócio, que identifica uma versão da linha.
- **Esquema estrela:** Modelo dimensional em banco relacional: fatos ligadas às dimensões por chave.
- **One big table:** Uso de mercado para uma tabela só, com todas as colunas de um conceito. Aqui, camada de consumo sobre a estrela.
- **Fan-out:** Nome de uso corrente para o JOIN que multiplica linhas porque uma das tabelas tem mais de uma linha por chave.
- **Drilling across:** Técnica do Kimball que busca respostas separadas em cada fato e as junta pelos atributos comuns.

### 25.3 Histórico

"O valor mudou. Como guardo o que ele era antes?"

- **SCD:** Dimensão de mudança lenta (slowly changing dimension): técnica para tratar o atributo que muda.
- **SCD tipo 1:** Sobrescreve o valor e perde o histórico.
- **SCD tipo 2:** Cria uma linha nova a cada mudança, com início e fim de vigência.
- **Vigência:** Período em que uma versão vale.
- **Intervalo meio aberto:** Vale do início, inclusive, até o fim, exclusive: `>=` e `<`.
- **Foto:** Cópia agendada do estado de uma tabela num dia. Fica crua na bronze.
- **Snapshot:** Palavra com três sentidos: fato periódica no Kimball, SCD tipo 2 no dbt, carga inicial no CDC.
- **Membro desconhecido:** Linha da dimensão, aqui com chave `'-1'`, que recebe o fato sem versão correspondente.

### 25.4 Transformação

"Como o SQL vira objeto no banco, e o que acontece quando roda de novo?"

- **Modelo:** No dbt, um `SELECT` salvo em arquivo, que vira objeto no banco ao rodar.
- **Materialização:** Estratégia para guardar o resultado do modelo no banco: view, table, incremental.
- **View:** Consulta salva: não guarda dado e roda a cada uso.
- **Table:** Resultado gravado em tabela, refeito a cada execução.
- **Incremental:** Modelo que processa só parte dos dados a cada execução, sobre o que já existe.
- **Idempotência:** Rodar de novo dá o mesmo resultado de rodar uma vez.
- **ELT:** Extrair, carregar e transformar no destino, com o processamento dele.

### 25.5 Testes

"Como provo que o número está certo, e de onde ele veio?"

- **Teste de dado:** Consulta que busca as linhas que desmentem uma regra; zero linhas, passou.
- **Linhagem:** Como o dado se move, onde é transformado e onde é consumido.
- **Definição do número:** O que o número significa, com regra, grão e dono, escrita junto do SQL.

### 25.6 Ferramenta e banco

"Esse nome é do dbt, do Postgres ou do SQL Server?"

- **OLTP:** Banco que grava transações, muito normalizado para isso.
- **Réplica:** Cópia do banco mantida pela replicação; aceitar leitura depende da tecnologia. Em hot standby no Postgres, não aceita escrita nenhuma.
- **Adaptador:** Pacote que liga o dbt a um banco específico.
- **dbt v1 e dbt v2:** As duas gerações do dbt. A v1 é a linha 1.x; a v2 é a geração nova, com as distribuições `dbt` e `dbt-oss`.
- **T-SQL:** O dialeto SQL do SQL Server.
- **Collation:** Regra do banco para ordenar e comparar texto: caixa, acento, página de código.
- **Query Store:** Recurso do SQL Server que guarda, por banco, consultas, planos e contagens.
- **Extended Events:** Recurso do SQL Server para capturar eventos, com filtro, por uma sessão criada para isso.

Com os termos à mão, a seção seguinte reúne as referências e as fontes para você conferir cada afirmação na origem.

---

[Índice](../README.md#capítulos) · [Anterior: 24. Plano de continuidade](24-plano-de-continuidade.md) · [Próximo: Referências e Fontes verificadas (2026-11-04)](26-referencias.md)
