---
title: "2. Contexto de negócio"
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

[Índice](../README.md#capítulos) · [Anterior: 1. Objetivo pedagógico](01-objetivo-pedagogico.md) · [Próximo: 3. O que é modelar e transformar, e o que não é](03-o-que-e-modelar-e-transformar-e-o-que-nao-e.md)

## 2. Contexto de negócio

"Por que o mesmo número aparece diferente em dois relatórios? E como eu guardo o preço de ontem?"

A apostila inteira responde a essas duas perguntas. Vamos responder na mesma rede de lojas fictícia da Orquestração, com dados sintéticos.

### 2.1 O que a rede já tem e o que entra agora

Preciso recomeçar do zero? Não. A rede avança.

| Peça | O que a Orquestração deixou | O que esta apostila acrescenta |
|---|---|---|
| Réplica só leitura | Pedidos | Lojas, itens, produtos, fornecedores, preço e atendimentos em UTC |
| Bronze | Pedidos crus | A foto diária do preço, crua, que lá ficou fora do laboratório |
| Silver | Pedidos validados | Nulo, `CASE`, texto, data, fuso, duplicata e a vigência do preço |
| Gold | Receita por dia | Estrela com o grão escrito e uma one big table (uma tabela só, grande) por cima |
| Registro de carga | Linhas e receita de cada carga | Continua, com testes de dado ao lado |

Bronze, silver e gold formam a arquitetura medalhão: cru, validado e enriquecido. A Databricks a chama de prática recomendada, não de requisito. O capítulo 4 mostra onde cada regra mora.

**Como saber que o avanço não quebrou nada**

A estrela, com o grão escrito antes do SQL, devolve a receita que a Orquestração publicou: 430,90, 111,90 e 293,30 nos dias 20, 21 e 22. A one big table, view sobre a estrela, tem as mesmas 13 linhas e a mesma receita, 836,10. É camada de consumo, não segunda fonte de verdade.

> Verificação: nível 3. Comando `docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -f /sql/30_gold.sql`, em PostgreSQL 16.15, em 2026-11-03. Saída em `lab/saidas/lab3_gold_estrela_e_fan_out.txt`.

### 2.2 Posso criar a silver na réplica?

Não, e essa é a primeira decisão de arquitetura. Uma réplica Postgres em espera ativa (hot standby) não aceita escrita, nem tabela temporária. No teste da mentoria, a leitura funcionou, e `CREATE TABLE AS`, `CREATE TEMP TABLE` e `CREATE VIEW` falharam com `read-only transaction`. Logo, a silver mora num banco que aceita escrita.

O teste foi em Postgres. Não sabemos que tecnologia de réplica você tem. Pergunte ao time antes de desenhar a silver. O capítulo 4 volta a isso.

> Verificação: nível 3, em teste à parte, porque no laboratório a réplica é simulada por um papel só de leitura. Réplica criada com `pg_basebackup -D /tmp/standby -R -X stream`, em PostgreSQL 16.15, em 2026-11-03.

### 2.3 Quatro números que erram sem dar erro

Se o SQL rodou sem erro, o número está certo? Não. Vamos ver quatro casos.

| Caso | O que aparece | O que é de verdade | Capítulo |
|---|---|---|---|
| Atendimento à meia-noite | 00h25, numa loja que fecha às 22h | 21h25 do dia anterior: a origem grava UTC em coluna sem fuso | 8 |
| Preço trocado de noite | Origem mostra 20,00 para um item vendido a 20,50 dois dias antes | O `UPDATE` noturno apagou o preço anterior | 11 |
| Receita que quase dobra | 850,90 no dia 20 | 430,90: um produto com dois fornecedores faz 6 linhas virarem 9 no JOIN | 10 |
| Regra em dois lugares | 130,00 num relatório, 170,00 no outro | `status = 'pago'` de um lado, `lower(trim(status)) = 'pago'` do outro | 6 e 19 |

Para o banco, nada disso é erro. O horário é válido. O `UPDATE` fez o que foi mandado. O JOIN devolveu uma linha para cada par que casa. As duas consultas são válidas.

No laboratório, 2 de 4 atendimentos mudam de dia com a conversão. As fotos diárias do preço guardam 15 linhas, e o histórico tipo 2 de dimensão de mudança lenta (SCD, slowly changing dimension) derivado delas guarda 7 versões. Na `dim_produto`, o membro desconhecido leva a 8 linhas (capítulo 12). O JOIN que multiplica linhas tem nome de uso corrente: fan-out.

O quarto caso é o do BI por planilha. A Microsoft recomenda tirar a preparação do Power Query de cada arquivo do Desktop e centralizá-la num dataflow (fluxo de dados), para chegar a uma fonte única da verdade. A página trata do Dataflow Gen1, legado, e indica o Gen2. Não achamos página do Microsoft Learn sobre regra duplicada entre Power Query e SQL. A divergência foi simulada em SQL, e nada aqui rodou no Power Query.

> Verificação: nível 3 nos três primeiros casos, com `docker compose exec -T postgres psql -U dw -d dw -f /sql/22_fuso.sql`, `/sql/40_preco_update_apaga.sql` e `/sql/31_fan_out.sql`, em PostgreSQL 16.15, em 2026-11-03. Saídas em `lab/saidas/lab2_fuso_e_datas.txt`, `lab/saidas/lab4_preco_update_e_scd2.txt` e `lab/saidas/lab3_gold_estrela_e_fan_out.txt`. O quarto é simulação em SQL, nível 3 na mesma versão e na mesma data, fora do laboratório.

**O equívoco comum**

Achar que sem erro é o mesmo que certo. Erro de sintaxe para a carga. Estes quatro chegam à diretoria no horário.

**Se você gerencia**

Critério da mentoria: o risco maior não é a carga que para, é a carga que termina com o número errado. Pergunte ao time: "Como saberíamos que este número dobrou?". Se a resposta for "o usuário reclama", já temos por onde começar.

### 2.4 Preciso de ferramenta para começar?

Não. Começar com SQL à mão é caminho válido. É critério da mentoria, não norma de mercado.

À mão, você vê cada linha mudar e descobre de onde vem cada número. Uma ferramenta não decide o grão por você. Por isso o laboratório roda o fluxo primeiro em SQL, à mão, e depois como projeto dbt.

Os sinais para subir de degrau ficam no capítulo 19. Também são critério da mentoria: número divergente entre relatórios, regra copiada em vários lugares, uma segunda pessoa precisando rodar, entrega recorrente para a diretoria.

Antes de escrever a primeira linha, vamos separar o que é modelar e transformar do que não é. É o próximo capítulo.

---

[Índice](../README.md#capítulos) · [Anterior: 1. Objetivo pedagógico](01-objetivo-pedagogico.md) · [Próximo: 3. O que é modelar e transformar, e o que não é](03-o-que-e-modelar-e-transformar-e-o-que-nao-e.md)
