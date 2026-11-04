---
title: "19. Onde a regra mora: a decisão de quem gerencia"
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

[Índice](../README.md#capítulos) · [Anterior: 18. De onde vem este número: definição e linhagem](18-de-onde-vem-este-numero.md) · [Próximo: 20. Laboratório](20-laboratorio.md)

## 19. Onde a regra mora: a decisão de quem gerencia

"Preciso de dbt já?" A resposta curta é não. Você precisa de SQL versionado e de teste. Isso é **critério da mentoria**, não norma: não achamos norma que diga quando subir de degrau.

Este capítulo dá um caminho para decidir. Uma escada, o sinal que justifica cada subida, os casos em que ainda não é hora e as perguntas para levar ao time. Antes do SQL, você decide o que uma linha significa. Antes da ferramenta, decida onde a regra mora e quem responde por ela.

### 19.1 A minha dor é falta de ferramenta?

"Se a gente comprar a ferramenta certa, o número para de divergir?"

**O que a pesquisa mostra**

Na pesquisa de comunidade de Joe Reis, publicada em 2026-02-20, com 1.101 respostas de múltipla escolha, 19% apontaram a ferramenta. A falta de dono claro teve 51%. A pressão por velocidade teve 59%, e a manutenção difícil, 39%. Só 11% marcaram "None / modeling is going well" (nenhuma, a modelagem vai bem).

Leia com cuidado. São respostas da própria comunidade, sem amostra representativa (leitura da mentoria). E o post agradece a um fornecedor de ferramenta de modelagem pela parceria. Serve de pista, não de prova.

**O equívoco comum**

"Todo mundo usa, então precisamos." Critério da mentoria: moda não é sinal. Sinal é um número que você consegue apontar.

### 19.2 Que sinal justifica subir?

"O que eu mostro à diretoria para justificar a mudança?"

**Como funciona na prática**

Vamos ao BI por planilha. Um relatório filtra a receita paga de um jeito, o outro filtra de outro, sobre os mesmos dados. É o caso que o capítulo 6 apresentou:

| Regra | Soma |
|---|---|
| `status = 'pago'` | 130,00 |
| `lower(trim(status)) = 'pago'` | 170,00 |

Nenhuma das duas dá erro. As duas rodam. A primeira não enxerga o status escrito com maiúscula ou com espaço. A diferença de 40,00 não aparece em log nenhum: aparece quando alguém compara os dois números.

> Verificação: nível 3 como simulação, com `psql` em `postgres:16.15-alpine`, em 2026-11-03, fora dos scripts do laboratório. As duas regras estão em SQL. Não executamos Power Query.

Critério da mentoria: o sinal para subir é esse, não a moda. Um número divergente, com os dois relatórios na mão. E a primeira decisão que ele pede nem é de ferramenta: qual regra vale e quem arbitra. O capítulo 18 mostra como registrar isso.

**Como inspecionar**

Critério da mentoria: escolha o número que mais dói. Liste onde a regra dele está escrita. Se a lista tem mais de um lugar, você já tem o sinal.

### 19.3 Em que degrau estou e qual é o próximo?

"Existe um caminho, ou é tudo ou nada?"

**A escada (critério da mentoria)**

São cinco degraus, e não há obrigação de passar por todos. Número de pessoas ou de modelos não é gatilho. O gatilho é o sinal da última coluna.

| Degrau | Onde a regra mora e para que serve | Risco | Sobe quando |
|---|---|---|---|
| 0. Planilha e Power Query | No arquivo de cada pessoa. Serve para explorar. | Regra copiada. Histórico impossível. | A mesma regra em dois modelos. O pedido do "valor de ontem". Carga perto dos limites. |
| 1. SQL solto | Em arquivos soltos. Serve para descobrir a origem. | Ninguém sabe que versão gerou o número. Erro passa batido. | A segunda pessoa precisa rodar. A entrega vira recorrente. |
| 2. Views e scripts versionados | No Git, rodando no banco. Serve a uma equipe pequena. | Ordem de execução à mão. Teste que só roda se alguém lembrar. | A ordem vira manutenção. Ninguém responde "se eu mudar esta coluna, o que quebra?". |
| 3. dbt local e agendador | No Git, compilado e rodado no banco. Serve a várias pessoas, com testes como rotina. | Adaptador, geração em transição, snapshot, incremental. | Você precisa de agendamento hospedado e catálogo, e o seu banco é atendido. |
| 4. Plataforma paga | Igual ao 3, hospedado. Serve para agendamento hospedado e catálogo. | Preço. Banco fora da lista. | É o último degrau. |

Pelo mesmo critério, começar com SQL à mão é caminho válido. É nele que você descobre de onde vem cada número. Ficar no degrau 2 também é resultado legítimo, se os sinais de cima não apareceram.

### 19.4 Meu BI já funciona. O que a Microsoft diz sobre o degrau 0?

"Tudo roda no Power Query hoje. Por que mexer?"

**O que a documentação diz**

- **Volume e histórico.** Transformar e preparar o dado no Power Query pode ser difícil com grande volume ou com SCD. Nesse caso, a Microsoft recomenda desenvolver antes um armazém de dados (data warehouse) com carga periódica, e conectar o modelo semântico a ele.
- **O valor de ontem.** Uma atualização não incremental de uma tabela de dimensão produz o efeito de um SCD tipo 1. Quando a origem não guarda versões, é preciso um sistema intermediário, como um armazém, para detectar e guardar as mudanças. A fato busca a chave da versão vigente na data do fato. O modelo semântico usa Power Query e não consegue produzir esse resultado, o processo de carga do tipo 2 inteiro, inclusive a busca por data. Ele pode carregar uma dimensão tipo 2 já pronta.
- **Coluna.** A Microsoft prefere coluna criada no Power Query a coluna calculada em DAX. Quando a fonte é banco, a carga fica mais eficiente com o cálculo definido no SQL ou materializado como coluna na fonte. A exceção é fórmula que avalia medidas ou depende de função que só existe no DAX.
- **Dono.** O roteiro de adoção descreve três estratégias de dono do conteúdo: business-led self-service, managed self-service e enterprise (autoatendimento liderado pelo negócio, autoatendimento gerenciado e corporativo). Cada uma tem uma lista de quando é mais adequada. A do meio é "discipline at the core and flexibility at the edge" (disciplina no centro, flexibilidade na ponta).
- **Versão única.** O objetivo do autoatendimento gerenciado é ter poucos modelos compartilhados e uma versão única da verdade. A Microsoft descreve o outro extremo, um modelo novo por relatório, como coisa de criador menos experiente.

**Número real: os limites de atualização**

Em capacidade compartilhada do Power BI, o modelo tem no máximo oito atualizações agendadas por dia. Cada uma precisa terminar em menos de duas horas. Depois de quatro falhas seguidas, o agendamento é desativado, e esse limiar não é configurável. Carga perto desses números é um dos sinais da escada.

**Existe um degrau dentro do próprio BI?**

Existe. A Microsoft recomenda tirar a preparação do Power Query de cada arquivo do Desktop e centralizá-la num dataflow (fluxo de dados), em Power Query Online, para chegar a uma fonte única da verdade. Essa página trata do Dataflow Gen1, em estado legado, e indica o Gen2.

Isso ataca a regra copiada. Inferência: ainda não resolve o tipo 2, porque continua sendo Power Query e a documentação pede um sistema intermediário para guardar as versões.

**O limite do que testamos**

Nada deste capítulo rodou em Power Query nem em dataflow. Não há página do Microsoft Learn sobre regra duplicada entre Power Query e SQL: a divergência acima foi simulada em SQL.

### 19.5 Meu script roda toda noite e nunca deu erro. Posso confiar?

"Se ninguém reclamou, deu certo, não é?"

**O equívoco comum**

Nunca ter visto erro não prova que não houve erro. Rodado à mão, o `psql` continua depois de um erro por padrão e sai com código 0.

**Como funciona na prática**

Testamos um script que recria a tabela e insere três linhas, com a do meio inválida. Antes de rodar, a tabela guardava a carga de ontem.

| Como rodou | Código de saída | O que ficou na tabela |
|---|---|---|
| Padrão | 0 | Linhas 1 e 3. A carga de ontem sumiu e a nova ficou pela metade. |
| `-v ON_ERROR_STOP=1` | 3 | Linha 1. O erro aparece, mas a tabela fica pela metade. |
| `--single-transaction`, sem a variável | 0 | A transação é desfeita, e o código de saída não mostra a falha. |
| `-v ON_ERROR_STOP=1 --single-transaction` | 3 | A carga de ontem, intacta. O erro aparece. |

A linha que você quer é a última:

```bash
psql -U dw -d dw -X -q -v ON_ERROR_STOP=1 --single-transaction -f /sql/79b_psql_erro_recarga.sql
```

> Verificação: nível 3, 2026-11-04, `postgres:16.15-alpine` e `psql` 16.15, com `lab/sql/79a_psql_erro_preparar.sql`, `79b_psql_erro_recarga.sql` e `79c_psql_erro_estado.sql`; saída em `lab/saidas/lab9_psql_erro.txt`.

No SQL Server, a proteção é outra e não equivale a esse par. `SET XACT_ABORT ON` com `sqlcmd -b` protege contra erro de execução do motor e contra `THROW`, mas com `RAISERROR` de severidade 16 a carga parcial fica. O capítulo 17 mostra as combinações.

> Verificação: nível 3, com `sqlcmd -b` nas versões 2022 e 2025, em 2026-11-03. Saídas em `lab/sqlserver/saidas/2022/lab10_merge_e_recarga.txt`, `lab/sqlserver/saidas/2022/lab14_erro_na_recarga.txt` e `lab/sqlserver/saidas/2025/lab14_erro_na_recarga.txt`.

**E o agendamento?**

A dbt Labs reconhece o cron como forma razoável de agendar comandos, mas avisa que escrever o que falta para produção costuma deixar esse caminho mais complexo que as alternativas. Leitura da mentoria: o aviso faz sentido, e quem escreve vende uma das alternativas. Confira o que falta no seu caso antes de aceitar ou descartar.

**Os limites das views**

O degrau 2 tem limites documentados. Vale conhecer antes de chamá-lo de solução final.

- No Postgres, `CREATE VIEW` não materializa e roda a consulta a cada uso.
- `CREATE OR REPLACE VIEW` exige as mesmas colunas, com os mesmos nomes, na mesma ordem e com os mesmos tipos. Pode acrescentar colunas no fim.
- `REFRESH MATERIALIZED VIEW` substitui todo o conteúdo.
- Em T-SQL, view criada sem `SCHEMABINDING` precisa de `sp_refreshview` quando a tabela de baixo muda de forma que afete a definição. Senão, pode devolver resultado inesperado. Leitura da mentoria: é o risco silencioso deste degrau.

### 19.6 Subir para o dbt: o que eu perco e quanto custa?

"Joguei fora o SQL que já escrevi? E a conta, de quanto é?"

**O que muda**

A dbt Labs mostra que um `INSERT ... SELECT` vira modelo tirando o `SELECT` da procedure para o arquivo do modelo. Leitura da mentoria: o SQL escrito à mão não se perde. A mesma dbt Labs reconhece que migrar procedures é uma mudança grande de paradigma, do procedural para o declarativo. Leitura da mentoria: esse é o custo do degrau 3, o tempo do time mudando o modo de pensar. Não temos fonte de horas de adoção, então não damos número.

**O que decide é o adaptador**

Sobre escolher a geração v2 do dbt, a própria dbt Labs escreve: "Today, the main determinant is whether your adapter is fully supported for your use case" (hoje, o principal fator é o adaptador ter suporte completo para o seu caso de uso). E aí entra o seu banco:

- **Postgres.** Não aparece na tabela de adaptadores da v2. Postgres com dbt hoje quer dizer geração v1, com adaptador mantido pela dbt Labs.
- **SQL Server.** Também não aparece nessa tabela. O `dbt-sqlserver` tem licença MIT e é plugin de comunidade: "Some core functionality may be limited", "Maintained by: Community", "dbt support: Not Supported". Não executamos `dbt run` contra SQL Server. Se você escolher esse caminho, alguém precisa ser dono desse risco.

O capítulo 16 detalha geração, licença e adaptador.

**Número real: o que a tabela de preço diz**

| Opção | Custo público | O que vem |
|---|---|---|
| dbt local | O dbt v1 continua Apache 2.0. Sobre a v2, a dbt Labs responde "No" a "If I use dbt, do I have to pay dbt Labs anything?". | O projeto roda na sua máquina ou no seu agendador. |
| Plataforma, Developer | Grátis | 1 assento, 1 projeto, 3.000 modelos com sucesso por mês, sem linhagem listada. |
| Plataforma, Starter | US$ 100 por usuário por mês | 5 assentos, 15.000 modelos por mês, "Lineage with dbt Catalog". |
| Plataforma, Enterprise e Enterprise+ | Sob consulta | A linhagem por coluna no Catalog só aparece aqui. |
| dbt State | Cobrado por uso | Exige login. |

Preço público consultado em 2026-11-03. Preço muda: confira de novo antes de decidir. Conta da mentoria: cinco assentos ocupados no Starter dão US$ 500 por mês, pelo preço de tabela.

Antes de pedir orçamento, confira se o seu banco é atendido. Não verificado: se a plataforma atende SQL Server em servidor próprio na geração v1. A pergunta é para o fornecedor.

### 19.7 Quando ainda não é hora de subir?

"Todo mundo aqui fala em dbt. Se eu não subir, fico para trás?"

**Critério da mentoria: não suba de degrau quando**

- **Há uma pessoa e poucos relatórios.** O custo de manter a ferramenta não se paga ainda.
- **Não existe banco analítico que aceite escrita.** Uma réplica Postgres em espera ativa (hot standby) não aceita escrita, nem tabela temporária. Logo, a silver não pode ser criada no banco replicado. No SQL Server, depende da tecnologia de réplica: veja o capítulo 4.
- **A dor é falta de dono ou de definição.** Ferramenta não arbitra número. Comece pelo capítulo 18.
- **Ninguém usa Git.** Sem revisão de mudança, o degrau 3 herda o mesmo problema. Suba primeiro para o 2.
- **O adaptador é de comunidade e ninguém é dono do risco.** Quando quebrar, quem responde?
- **O motivo é "todo mundo usa".** Sem um número divergente para apontar, volte à seção 19.2.

### 19.8 O que eu pergunto ao time?

"Não escrevo o SQL. Como eu sei se está no caminho?"

Pergunte, e preste atenção na resposta. Cada pergunta abaixo, e cada resposta que preocupa, é **critério da mentoria**: nenhuma vem de norma. Uma resposta ruim não condena o time. Ela diz por onde começar.

**Antes do SQL (critério da mentoria)**

| Pergunta | Resposta que preocupa |
|---|---|
| O que uma linha desta tabela significa? | "Depende." |
| Onde esta regra está, e em quantos lugares? | Em dois relatórios. |
| Quem é dono deste número? | "Todo mundo." |
| Se o preço mudar hoje, perdemos o de ontem? | "Não sei." |
| Em que fuso a origem grava? | "Acho que é local." |
| Qual tecnologia é a réplica, e onde escrevemos? | "Na réplica." |

**Antes de confiar (critério da mentoria)**

| Pergunta | Resposta que preocupa |
|---|---|
| Se o script falhar no meio, o que fica? | Nunca testaram. |
| O que dá para refazer? | Histórico sem backup. |
| Como saberíamos que o número dobrou? | "O usuário reclama." |
| Se o teste falhar às 6h, a carga para ou segue, e quem é avisado? | Ninguém decidiu. |

**Antes do dbt (critério da mentoria)**

| Pergunta | Resposta que preocupa |
|---|---|
| O que dói hoje, com um exemplo? | "É o padrão." |
| Qual é o estado do adaptador, e quem responde por ele? | Ninguém olhou. |
| Qual geração, qual versão fixa e quando é o próximo upgrade? | `pip install` sem versão. |
| Para que serve a plataforma paga aqui? | Ninguém sabe que o local é gratuito. |
| Quem revisa a mudança? | Sem Git, ninguém. |
| Tem dado pessoal no histórico? | "Guardamos tudo." |

**A última pergunta tem lei por trás**

A LGPD prevê limitação do tratamento ao mínimo necessário (art. 6º, III), eliminação dos dados após o fim do tratamento, com exceções de conservação (art. 16), e direito do titular à eliminação de dados desnecessários ou excessivos (art. 18, IV). Inferência da mentoria, não parecer jurídico: histórico que não se apaga precisa nascer com a escolha de colunas.

Decidido o degrau, falta pôr a mão: no próximo capítulo, você roda o laboratório, do SQL à mão ao projeto dbt.

---

[Índice](../README.md#capítulos) · [Anterior: 18. De onde vem este número: definição e linhagem](18-de-onde-vem-este-numero.md) · [Próximo: 20. Laboratório](20-laboratorio.md)
