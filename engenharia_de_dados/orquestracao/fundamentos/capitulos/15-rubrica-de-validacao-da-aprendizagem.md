---
title: "15. Rubrica de validação da aprendizagem"
date: 2026-10-29
type: capitulo
status: draft
project: zambotto-mentoria
tags:
  - engenharia-de-dados
  - orquestracao
  - apostila
  - mentoria
---

> Capítulo gerado a partir da [apostila completa](../apostila.md), que é a fonte. Não edite este arquivo: a correção entra na `apostila.md`, e os capítulos são gerados de novo.

[Índice](../README.md#capítulos) · [Anterior: 14. Exercícios, entregáveis e mini-desafio](14-exercicios-entregaveis-e-mini-desafio.md) · [Próximo: 16. Erros comuns e como corrigir](16-erros-comuns-e-como-corrigir.md)

## 15. Rubrica de validação da aprendizagem

Como saber, na call, se o mentorado entendeu orquestração ou só decorou o vocabulário? A rubrica responde com evidência que dá para observar. Cada critério tem três níveis: insuficiente, suficiente e excelente. O mentor não pergunta "você entendeu?". O mentor pede para ver.

Vale uma regra de leitura. Suficiente já sustenta uma entrega real. Excelente é quem prova o que afirma, com saída na tela.

| Critério | Insuficiente | Suficiente | Excelente |
|---|---|---|---|
| Degrau: à mão, cron ou orquestrador | Automatiza tudo de saída ou nunca automatiza. | Cita os sinais que a mentoria usa: frequência, número de passos, necessidade de alerta e de nova tentativa, e entrega recorrente. | Mostra o custo e o risco do degrau seguinte. |
| Orquestração ou agendamento | Chama o cron de orquestrador. | Explica que o agendador dispara e o orquestrador guarda ordem, estado e histórico. | Mostra na Dag a dependência que o cron não resolveria. |
| Leitura da origem | Consulta a produção direto. | Lê a réplica só leitura. | Prova que o usuário de leitura, com GRANT só de SELECT, não grava nem depois de `BEGIN READ WRITE` (`permission denied`); sabe que ligar só o `default_transaction_read_only` não segura a escrita. |
| Dependência | Tarefas soltas, sem ordem declarada. | Declara a ordem e explica por que a carga espera a origem. | Derruba uma tarefa e mostra a seguinte em `upstream_failed`, ou acha no grafo uma dependência mal declarada que a nova tentativa escondeu. |
| Idempotência | Reexecuta e não confere o resultado. | Explica por que a carga sobrescreve em vez de acumular. | Prova com duas reexecuções que a contagem não muda. |
| Nova tentativa e alerta | Não sabe que, no padrão do Airflow 3.3.2, a nova tentativa vem desligada (zero novas tentativas: a tarefa roda uma vez e, se falhar, não repete). | Configura nova tentativa com espera e sabe quem recebe o aviso. | Separa falha que vale repetir de falha que precisa de gente. |
| Datas e fuso | Grava a carga pelo `ds` sem perceber que ele é a data em UTC (na agenda cron padrão, sem `interval`, a carga das 22h de Brasília cai na partição do dia seguinte). | Sabe que o fuso padrão do Airflow é UTC, três horas à frente de Brasília, e que data sem fuso é lida em UTC; por isso declara o fuso no `start_date`. | Reprocessa datas passadas com hora e fuso explícitos e mostra qual dia local cada execução leu; sabe que, sem `interval`, a janela de dados tem duração zero. |
| Registro de carga | Só olha se ficou verde. | Grava quando rodou, se foi agendada ou manual e quantas linhas. | Usa o registro para achar uma falha silenciosa e faz a carga falhar com alerta quando a contagem repete a do ciclo anterior. |

No critério do degrau, começar à mão é caminho válido. O insuficiente não é rodar à mão no começo, é não saber dizer quando subir de degrau.

### 15.1 Como aplicar na call

Para o gestor, o critério de idempotência pesa mais. É ele que responde "posso mandar rodar de novo sem medo?".

Vamos ver como fica a evidência excelente de idempotência. No laboratório do capítulo 13, a versão idempotente da carga apaga o dia e insere de novo, na mesma transação. Rodada duas vezes à mão para o mesmo dia, ela gravou o mesmo resultado (trecho da saída):

```text
$ docker compose run --rm -T runner python scripts/pipeline.py --dia 2026-10-20 2>&1 | grep resultado
  resultado: bronze=4 silver=4 receita_paga=430.90
[saída: 0]
$ docker compose run --rm -T runner python scripts/pipeline.py --dia 2026-10-20 2>&1 | grep resultado
  resultado: bronze=4 silver=4 receita_paga=430.90
[saída: 0]
```

Nível 3, executado com saída capturada. Comando: o de cima, duas vezes. Versão: PostgreSQL 16.15 e Python 3.13.15 (imagem `python:3.13.15-alpine3.24`), sem Airflow neste degrau. Data: 2026-10-29. Dois backfills seguidos do mesmo período, no Airflow 3.3.2 (imagem `apache/airflow:3.3.2`, mesmo digest de `apache/airflow:3.3.2-python3.13`, a tag que a apostila fixa), também deixaram esse dia em 4 pedidos e 430,90 na tabela final.

O contraste é a versão ingênua, que só faz INSERT, sem chave. Com uma queda simulada logo depois de gravar, a nova tentativa gravou tudo de novo, a execução terminou verde e a tabela final dobrou (trecho da saída):

```text
$ docker compose --profile airflow exec -T airflow-scheduler airflow dags trigger loja_ingenua -l 2026-10-21T09:00:00+00:00 -r retry_ingenuo -c '{"simular_queda": true}' -o plain
$ docker compose exec -T postgres psql -U dw -d dw -c 'SELECT * FROM gold.vendas_por_dia;'
    dia     | pedidos | pedidos_pagos | receita_paga 
------------+---------+---------------+--------------
 2026-10-20 |       8 |             4 |       861.80
(1 row)
```

A data lógica 2026-10-21 às 09:00 UTC é a execução das 6h de Brasília, e a Dag da loja carrega o dia anterior; por isso a linha do gold é do dia 20.

Nível 3, executado com saída capturada. Comandos: os dois de cima, em sequência. Na execução, o `psql` levava um segundo `-c` com a consulta ao registro de carga, cortado aqui junto com a saída dele, e a saída do disparo foi omitida. Versão: Airflow 3.3.2, imagem `apache/airflow:3.3.2` (mesmo digest de `apache/airflow:3.3.2-python3.13`), Python 3.13.15, PostgreSQL 16.15. Data: 2026-10-29. Antes de disparar, as tabelas do laboratório foram esvaziadas, então os 8 pedidos são 4 gravados duas vezes.

O equívoco comum é aceitar o print de uma execução verde como prova. Verde mostra que rodou, não mostra que rodar de novo é seguro. Peça a segunda execução e a contagem.

---

[Índice](../README.md#capítulos) · [Anterior: 14. Exercícios, entregáveis e mini-desafio](14-exercicios-entregaveis-e-mini-desafio.md) · [Próximo: 16. Erros comuns e como corrigir](16-erros-comuns-e-como-corrigir.md)
