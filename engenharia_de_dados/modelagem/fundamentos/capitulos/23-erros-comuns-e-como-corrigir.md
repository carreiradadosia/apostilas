---
title: "23. Erros comuns e como corrigir"
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

[Índice](../README.md#capítulos) · [Anterior: 22. Rubrica de validação da aprendizagem](22-rubrica-de-validacao-da-aprendizagem.md) · [Próximo: 24. Plano de continuidade](24-plano-de-continuidade.md)

## 23. Erros comuns e como corrigir

"O número saiu errado e nada deu erro. Por onde começo?" Pelo sintoma. Cada tabela é um momento do trabalho e vai do que você vê até o capítulo que explica.

Vamos ao exemplo que serve de régua:

- **Sintoma:** a receita dobrou e nenhum erro apareceu.
- **Causa:** JOIN no grão errado.
- **Correção:** agregue antes do JOIN e teste o grão.

**O equívoco comum**

"Não deu erro, então está certo." O banco confere a sintaxe. Ele não sabe o que uma linha deveria significar. Por isso a frase guia vem antes de qualquer correção: antes do SQL, decida o que uma linha significa.

**Como ler as tabelas**

A prova de cada causa está na verificação da seção. A coluna de correção é critério da mentoria. Fora das linhas do dbt, nada aqui pede ferramenta.

### 23.1 Ao subir o ambiente

"Nem subiu. O que eu errei?" Estes dois dão erro, e esse é o caso bom: você descobre na hora.

| Sintoma | Causa | Correção | Capítulo |
|---|---|---|---|
| `dbt debug` falha com `Required var 'experimentos' not found in config`, mesmo com a variável no bloco `vars`. | `var()` usado no `dbt_project.yml` não enxerga o bloco `vars` do próprio arquivo. | Dê um valor padrão: `var('experimentos', false)`. | 15 |
| `sqlcmd` termina com `certificate verify failed` e saída 1. | Sem `-C`, ele recusa o certificado autoassinado do contêiner. | No contêiner do laboratório, use `-C`, com a senha em `SQLCMDPASSWORD`. A doc chama `-P` de inseguro. | 17 |

> Verificação: nível 3. `var()`: em 2026-11-04, `dbt debug`, `dbt-core` 1.12.6, `dbt-postgres` 1.11.0, numa cópia que só tira o valor padrão (`lab/checagens/var_sem_padrao/dbt_project.yml`), saída em `lab/saidas/lab9_dbt_var_e_full_refresh.txt`; `lab/saidas/lab5_projeto_dbt.txt` mostra o projeto com o valor padrão. `sqlcmd`: em 2026-11-03, com e sem `-C`, SQL Server 2022 Developer, saída em `lab/sqlserver/saidas/2022/lab0_ambiente.txt`.

### 23.2 Na silver

"A carga rodou sem erro. O dado está limpo?" O log não responde. Estes são os que passam em silêncio.

| Sintoma | Causa | Correção | Capítulo |
|---|---|---|---|
| Usou `DISTINCT` e a duplicata continua: 11 linhas seguem 11. | `DISTINCT` só remove linha idêntica. As duas versões do pedido 103 diferem no status e nas datas. | Deduplique por chave, com desempate explícito: `row_number() OVER (PARTITION BY id ORDER BY _carregado_em DESC)`. Ficam 10. | 6 |
| A soma não mudou, mas a média caiu de 44,00 para 36,67. | `COALESCE(valor, 0)` escondeu a falha de origem: `count(valor)` dá 5 e `count(*)` dá 6. | Deixe a medida nula. Conte os nulos e avise. | 7 |
| Um status novo vira nulo, sem aviso. | `CASE` sem `ELSE` devolve nulo quando nenhuma condição casa: `estornado` saiu nulo. | Escreva `ELSE` com nome, como `'desconhecido'`, e um teste que conta esse valor. | 7 |
| O horário fica 3 horas fora, e o dia pode mudar. | Sentido errado ou conversão dupla. Para `2026-10-21 00:30` em UTC, o certo é 21:30 do dia 20. Só `AT TIME ZONE 'America/Sao_Paulo'` dá o instante 03:30 UTC, 3 horas depois. Duas conversões dão 18:30, 3 horas antes. | Converta uma vez, na silver: `x AT TIME ZONE 'UTC' AT TIME ZONE 'America/Sao_Paulo'`. | 8 |
| Escreveu `AT TIME ZONE '-03'` e veio 03:30 em vez de 21:30. | Em texto, `'-03'` é especificação POSIX, positiva a oeste, e dá UTC+3. | Use o nome `America/Sao_Paulo`, ou `interval '-03:00'`. | 8 |
| Data de 1900 no SQL Server, ou zero onde não havia número. | Em `TRY_CONVERT`, texto vazio não vira `NULL` em `date` nem em `int`: dá 1900-01-01 e 0. | `NULLIF(TRIM(x), N'')` cobre vazio e espaços. Para tab, passe ao `TRIM` a lista de caracteres. | 17 |
| Rótulo cortado no SQL Server: `'de'` no lugar de `'desconhecido'`. | `ISNULL` usa o tipo do primeiro argumento e trunca, aqui `varchar(2)`. | Use `COALESCE`, que usa o tipo de maior precedência. | 7 e 17 |

> Verificação: nível 3, em 2026-11-03. Postgres 16.15 (`postgres:16.15-alpine`), com `docker compose exec -T postgres psql -U dw -d dw -f /sql/<arquivo>`: `21_silver_antes_depois.sql` para `DISTINCT` e `CASE`, saída em `lab/saidas/lab1_silver_a_mao.txt`; `22_fuso.sql` para fuso e `'-03'`, saída em `lab/saidas/lab2_fuso_e_datas.txt`. Média do `COALESCE`: conta avulsa, fora dos scripts do laboratório. SQL Server 2022: `./sq.sh dw 61_datas_em_texto.sql` e `./sq.sh dw 62_nulos.sql`, saídas em `lab/sqlserver/saidas/2022/lab7_datas_em_texto.txt` e `lab/sqlserver/saidas/2022/lab8_nulos.txt`; o tab com `./sq.sh dw 69_datas_com_tab.sql`, na 2022 e na 2025, em `lab/sqlserver/saidas/2022/lab15_datas_com_tab.txt` e `lab/sqlserver/saidas/2025/lab15_datas_com_tab.txt`. A doc registra o texto vazio só para `numeric` e `decimal`: em `date` e `int`, é comportamento observado.

### 23.3 Na gold

"O total parece errado, e a consulta roda. Onde olho?" Primeiro no grão. Vamos ver por que o número mudou sem que nada reclamasse.

| Sintoma | Causa | Correção | Capítulo |
|---|---|---|---|
| A receita do dia 20 foi de 430,90 para 850,90, e nenhum erro apareceu. 6 linhas viraram 9. | Fan-out, o JOIN que multiplica linhas: um produto com dois fornecedores repete os itens dele. | Agregue antes do JOIN e teste o grão: `GROUP BY chave HAVING count(*) > 1`. | 5 e 10 |
| Trocou por `SUM(DISTINCT)` e agora falta dinheiro: 716,10 contra 836,10. | `SUM(DISTINCT)` descarta venda legítima de mesmo valor: 120,00 aparece em dois itens. | Agregue cada lado no próprio grão antes do JOIN: 836,10 contra 836,10. | 10 |
| A venda do dia da troca de preço conta em dobro: o item de 80,00 soma 160,00. | `BETWEEN` usa intervalo fechado, e o fim de uma versão é o início da seguinte. | Use intervalo meio aberto: `dia >= valido_de AND dia < valido_ate`. | 11 |
| Teste verde, e há venda sem versão do produto na dimensão. | `relationships` ignora nulo, como `unique` e `accepted_values`. Num teste à parte, sem arquivo publicado, com duas vendas sem versão, `not_null` falhou com 2 e `relationships` passou. | Ponha `not_null` ao lado. Com o membro `'-1'`, os dois passam, então acrescente um teste que conta: ele acusou `WARN 2`. | 12 e 13 |

> Verificação: nível 3, em 2026-11-03. Postgres 16.15, com o mesmo comando: `31_fan_out.sql` para fan-out e `SUM(DISTINCT)`, saída em `lab/saidas/lab3_gold_estrela_e_fan_out.txt`; `40_preco_update_apaga.sql` para `BETWEEN`, saída em `lab/saidas/lab4_preco_update_e_scd2.txt`. `relationships`: num teste à parte, sem arquivo publicado, com `dbt build`, `dbt-core` 1.12.6 e `dbt-postgres` 1.11.0. O `WARN 2`, em 2026-11-04, em `lab/saidas/lab9_dbt_venda_sem_versao.txt`. Vale para o dbt v1: a implementação no v2 não foi conferida.

### 23.4 Na carga

"Rodei de novo. O que mudou na tabela?" Aqui o erro aparece na segunda execução, ou no código de saída que ninguém leu.

| Sintoma | Causa | Correção | Capítulo |
|---|---|---|---|
| O modelo rodou de novo, sobre a janela de reprocessamento, e ficou com 5 linhas para 4 atendimentos. | Incremental sem `unique_key` só acrescenta, na maioria dos adaptadores. | Declare `unique_key`: no laboratório, o adaptador usou `delete+insert` e ficou com 4. Regra alterada pede `--full-refresh`. | 14 |
| Reprocessou com `ON CONFLICT` e duplicou assim mesmo. | No Postgres, por padrão, dois nulos não colidem em `UNIQUE`, e o `ON CONFLICT` não vê o conflito: 2 linhas. | Não aceite nulo na chave, ou use `UNIQUE NULLS NOT DISTINCT`: 1 linha. | 14 |
| O lote traz a mesma chave duas vezes, e o resultado depende do comando. | No Postgres, `ON CONFLICT DO UPDATE` recusa com `cannot affect row a second time`. `DELETE ... USING` e `INSERT` gravam as duas, sem erro. `MERGE`: cardinalidade se a chave já existe no alvo; unicidade se é nova e há `UNIQUE`; duas linhas se é nova e não há. | Deduplique o lote no próprio grão antes de gravar, e mantenha `UNIQUE` no destino. | 14 |
| O script falhou no meio, apagou a carga anterior, gravou metade da nova e devolveu 0. | Por padrão, o `psql` continua depois do erro e sai com 0. | `psql -v ON_ERROR_STOP=1 --single-transaction`: sai com 3 e preserva o estado anterior. Só a variável deixa a tabela pela metade. Só `--single-transaction` desfaz, mas sai com 0. | 19 |
| No `sqlcmd`, a recarga com erro sai com 0 e a carga parcial fica. | Sem `-b`, o código de saída não muda. Sem `SET XACT_ABORT ON`, a carga parcial é gravada. | Use os dois: saída 1 e estado preservado. O par protege contra erro do motor e contra `THROW`, e não equivale ao do `psql`: com `RAISERROR`, o `COMMIT` roda e a carga parcial fica. `TRY/CATCH` que engole o erro sai com 0 mesmo com `-b`. | 17 |
| A origem só mostra 20,00 para um item vendido a 20,50 dois dias antes. | O `UPDATE` noturno apagou o preço anterior. | Se o negócio pergunta pelo preço da data, guarde a foto diária crua na bronze e monte a vigência na silver: 15 linhas de foto viram 7 versões. | 11 |

> Verificação: nível 3, em 2026-11-03. Incremental: `docker compose --profile dbt run --rm dbt dbt build --select exp_inc_sem_chave exp_inc_com_chave --vars '{experimentos: true}'`, `dbt-core` 1.12.6, `dbt-postgres` 1.11.0, saída em `lab/saidas/lab6_testes_que_param.txt`. `UPDATE`: `40_preco_update_apaga.sql`, saída em `lab/saidas/lab4_preco_update_e_scd2.txt`. Chave com nulo e lote: `76_reprocesso_sintetico.sql`, saída em `lab/saidas/lab9_reprocesso_sintetico.txt`, 2026-11-04. `psql`: `79a` a `79c`, saída em `lab/saidas/lab9_psql_erro.txt`, 2026-11-04. `sqlcmd`: SQL Server 2022 e 2025, `./sq.sh dw 64c_recarga_sem_xact_abort.sql` e `./sq.sh dw 64d_recarga_com_xact_abort.sql`, com e sem `-b`, saída em `lab/sqlserver/saidas/2022/lab10_merge_e_recarga.txt`; `RAISERROR`, `THROW` e `TRY/CATCH` com `./sq.sh dw 68a_recarga_raiserror.sql -b`, `68b_recarga_throw.sql -b` e `68c_recarga_try_catch.sql -b`, saídas em `lab/sqlserver/saidas/2022/lab14_erro_na_recarga.txt` e `lab/sqlserver/saidas/2025/lab14_erro_na_recarga.txt`.

No `dbt-postgres`, a macro do `delete+insert` insere o lote inteiro, sem deduplicar. Lemos isso no código (nível 1) e não executamos.

### 23.5 Na organização

"Dois relatórios, dois números. Qual está certo?" Antes de escolher um, descubra quantas vezes a regra foi escrita.

| Sintoma | Causa | Correção | Capítulo |
|---|---|---|---|
| Mesmos dados, dois números: 130,00 e 170,00. | A mesma regra em dois lugares: `status = 'pago'` num, `lower(trim(status)) = 'pago'` no outro. | Cada regra num lugar só: em SQL no banco, na silver. O relatório lê pronto. | 6 e 19 |

> Verificação: nível 3 como simulação, `postgres:16.15-alpine`, em 2026-11-03, fora dos scripts do laboratório. As duas regras estão em SQL. Não executamos Power Query.

Não achamos página do Microsoft Learn sobre regra duplicada entre Power Query e SQL. A recomendação mais próxima, centralizar a preparação do Power Query num dataflow para chegar a uma fonte única da verdade, está na seção 6.6.

### 23.6 E quando o sintoma não está aqui?

"O meu erro não aparece em nenhuma tabela. E agora?" Critério da mentoria: três perguntas, nesta ordem.

1. **O que uma linha significa?** Escreva o grão do resultado e rode o teste da chave repetida.
2. **Onde o número mudou?** Compare `count(*)` e a soma antes e depois de cada etapa. Numa etapa que não filtra, não deduplica e não agrega, `count(*)` não deveria mudar. Se mudou, ache a linha que entrou ou saiu.
3. **O que acontece quando falha?** Provoque a falha de propósito. Confira o código de saída e o estado da tabela.

**O limite destas tabelas.** Tudo rodou em Linux, em contêiner. Nada rodou em Windows nem em Power Query. Não conhecemos a versão, a edição e a collation do seu banco. Confirme o sintoma no seu ambiente antes de aplicar a correção.

Achar o erro pelo sintoma resolve o que está na sua frente. O capítulo seguinte olha para o próximo passo, por perfil.

---

[Índice](../README.md#capítulos) · [Anterior: 22. Rubrica de validação da aprendizagem](22-rubrica-de-validacao-da-aprendizagem.md) · [Próximo: 24. Plano de continuidade](24-plano-de-continuidade.md)
