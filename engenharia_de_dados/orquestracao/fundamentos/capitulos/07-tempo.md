---
title: "7. Tempo: agendamento, data lógica, reprocesso e catchup"
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

[Índice](../README.md#capítulos) · [Anterior: 6. Nova tentativa e idempotência: o preço do orquestrador](06-nova-tentativa-e-idempotencia.md) · [Próximo: 8. Fuso horário: o dia de quem?](08-fuso-horario.md)

## 7. Tempo: agendamento, data lógica, reprocesso e catchup

"Corrigi o SQL da silver. Como refaço a semana passada para a diretoria?"

Antes de apertar qualquer botão, responda duas perguntas. Qual dia cada execução processa? E o que acontece se um dia rodar duas vezes? A segunda o capítulo 6 já respondeu: só reprocesse a versão que apaga e regrava o dia. Este capítulo responde a primeira.

Tudo aqui foi conferido no Airflow 3.3.2. Onde a documentação e o comportamento divergem, seguimos o que rodou.

### 7.1 A agenda vira uma regra: o timetable

"Escrevi `@daily`. Que dia essa execução carrega?"

**O que é**

Timetable é a regra que transforma a agenda em execuções e janelas de dados. Janela de dados é o intervalo de tempo que uma execução deve processar.

**Como funciona no Airflow**

No Airflow 3, a configuração `create_cron_data_intervals` vem desligada. Assim, `"0 0 * * *"`, `"@daily"` e `"@hourly"` viram `CronTriggerTimetable`, e `timedelta(days=1)` vira `DeltaTriggerTimetable`. Sem `interval=`, o `CronTriggerTimetable` não tem janela: data lógica, início e fim da janela recebem o mesmo instante, o do disparo. A janela tem duração zero.

Para a janela cobrir o dia anterior, declare `interval=`. A data lógica passa a ser o início da janela, o disparo menos um dia.

Dags diárias iguais, que só mudam a agenda, receberam isto no disparo de 29/10 às 00:00 UTC (21h do dia 28 em Brasília):

| Agenda | Timetable | Janela de dados | `ds` | Linhas lidas da janela |
|---|---|---|---|---|
| `"0 0 * * *"` ou `"@daily"` | `CronTriggerTimetable` | duração zero, no disparo | 2026-10-29 | 0 |
| `CronTriggerTimetable("0 0 * * *", timezone="UTC", interval=timedelta(days=1))` | o mesmo, com intervalo | 28/10 00:00 a 29/10 00:00 UTC | 2026-10-28 | 3 |
| `CronDataIntervalTimetable("0 0 * * *", timezone="UTC")`, o padrão do Airflow 2 | intervalo clássico | 28/10 00:00 a 29/10 00:00 UTC | 2026-10-28 | 3 |

Das três linhas lidas, duas são do dia 27 em Brasília. Isso é fuso, assunto do capítulo 8.

Se você migra do Airflow 2 Dags que dependem de `data_interval_start` e `data_interval_end`, decida antes do upgrade. O guia oficial dá dois caminhos: ligar `create_cron_data_intervals=True` antes do upgrade, para manter o timetable antigo, ou declarar `interval=` no `CronTriggerTimetable`. Mudar essa configuração depois que já existem execuções no Airflow 3 pula uma execução agendada.

**O equívoco comum**

Achar que a receita oficial já resolve. As boas práticas do Airflow mandam gravar numa partição específica e sugerem `data_interval_start` como partição. No padrão do Airflow 3, essa partição é o dia do disparo, não o dia anterior. E se a tarefa lê a janela do início ao fim, como fizemos no laboratório, lê zero linhas.

Cuidado também com duas páginas da documentação. A de execuções da Dag e o FAQ ainda explicam datas pelo modelo de intervalo do Airflow 2, e a primeira manda disparar com `-e`; na 3.3.2, a opção é `-l/--logical-date`, sem padrão. Para o Airflow 3, use a página de timetables, o guia de upgrade e a referência de configuração. Mesmo esta última pede atenção: diz que, no `CronTriggerTimetable`, a data lógica é o momento do disparo, e isso só vale sem `interval=`.

**Como inspecionar**

No laboratório (capítulo 13, Lab 5), seis Dags iguais, que só mudam a agenda, imprimem as datas no log. Trecho da saída real:

```text
## datas_cron_puro | scheduled__2026-10-29T00:00:00+00:00 | mostrar_datas
DATAS logical_date=2026-10-29T00:00:00+00:00 (Brasilia 28/10 21:00)
DATAS data_interval_start=2026-10-29T00:00:00+00:00 (Brasilia 28/10 21:00)
DATAS data_interval_end=2026-10-29T00:00:00+00:00 (Brasilia 28/10 21:00)
DATAS ds=2026-10-29
## datas_trigger_intervalo | scheduled__2026-10-29T00:00:00+00:00 | mostrar_datas
DATAS logical_date=2026-10-28T00:00:00+00:00 (Brasilia 27/10 21:00)
DATAS data_interval_start=2026-10-28T00:00:00+00:00 (Brasilia 27/10 21:00)
DATAS data_interval_end=2026-10-29T00:00:00+00:00 (Brasilia 28/10 21:00)
DATAS ds=2026-10-28
```

### 7.2 Disparo manual: a data pedida não é a janela

"E se eu disparar à mão, pedindo o dia 20?"

**O que é**

Data lógica é a data a que uma execução se refere. Nem sempre é o momento em que ela roda. No disparo manual, nem sempre bate com a janela.

**Como funciona no Airflow**

O resultado depende do caminho.

| Caminho | Data lógica | Janela de dados |
|---|---|---|
| CLI sem `-l`, ou API com `"logical_date": null` | vazia | vazia; `{{ ds }}` falha com `UndefinedError` |
| CLI com `-l 2026-10-20T00:00:00+00:00` | a pedida; `ds=2026-10-20` | ancorada no momento do disparo, hoje |
| API REST com data lógica | a pedida | inferida a partir da data lógica, terminando nela |
| Botão Acionar da interface | o instante atual, no fuso do navegador | "Inferido da Data Lógica e do Timetable" ou "Especificar Manualmente" |

Pela interface, o `ds` sai da data em UTC. Um disparo entre 21h e 24h de Brasília recebe o dia seguinte.

**O equívoco comum**

Achar que disparar com `-l` refaz aquele dia. Pela CLI, o pedido de 20/10 numa Dag de cron puro gravou a partição de 29/10, o dia do disparo, porque a tarefa usava `data_interval_start`. Com `interval=`, gravou 28/10. Pela API, muda de novo. No cron puro, gravou a partição pedida, lendo janela vazia. Com janela de um dia, gravou o dia anterior ao pedido.

Se a sua lógica precisa da data pedida, leia `logical_date` explicitamente. Para refazer dias, o caminho coerente é o reprocesso.

### 7.3 Reprocessar a semana: ensaio, limites e a versão certa

"Corrigi a silver. Como refaço os dias?"

**O que é**

Reprocessamento de datas passadas (backfill) é criar execuções para dias que já passaram. Só faz sentido em Dag com agenda por tempo. Roda pela interface, pela CLI e pela API.

**Como funciona no Airflow**

A primeira escolha é o que fazer com o dia que já tem execução:

| `--reprocess-behavior` | Na interface | Dia que já tem execução |
|---|---|---|
| `none`, o padrão | Missing Runs | pula, qualquer que seja o estado |
| `failed` | Missing and Errored Runs | refaz se falhou |
| `completed` | All Runs | refaz se terminou, com sucesso ou falha |

Em qualquer opção, se a última execução do dia ainda está rodando ou na fila, o reprocesso não cria outra.

No caso da silver corrigida, os dias já rodaram com sucesso. Com `none`, o reprocesso pula todos, inclusive um dia com execução manual criada com `-l`. Você precisa de `completed`.

Os limites têm duas pegadinhas. `--from-date` e `--to-date` sem hora viram 00:00 no fuso padrão da instalação (UTC, se ninguém mudou), qualquer que seja o fuso da Dag. E o fim é inclusivo, mas, no `CronTriggerTimetable`, o filtro olha o momento do disparo, não a data lógica.

Vamos ver na Dag da loja. Ela dispara às 06h de Brasília, 09h em UTC, e carrega o dia anterior ao disparo, com `{{ macros.ds_add(ds, -1) }}`. Primeiro, o ensaio:

```bash
# Dry run: prints the logical dates the backfill would create, writes nothing
airflow backfill create --dag-id loja_ingenua \
  --from-date 2026-10-21 --to-date 2026-10-23 --dry-run
```

Trecho da saída real:

```text
    - from_date = 2026-10-21 00:00:00+00:00
    - to_date = 2026-10-23 00:00:00+00:00
| 2026-10-22 09:00:00+00:00 |                 |                  |
```

Pedimos três dias e veio um. O disparo de 21/10 já tinha uma execução manual, e o `none` pulou. O de 23/10 às 09h UTC passou do fim, 00:00 UTC. O ensaio pegou os dois erros sem gravar nada. Ele rodou na Dag ingênua; a idempotente tem a mesma agenda.

Agora o reprocesso de verdade, na versão que apaga e regrava o dia, com hora explícita no fim:

```bash
# Real backfill: explicit end time, reprocess days that already ran
airflow backfill create --dag-id loja_idempotente \
  --from-date 2026-10-21 --to-date 2026-10-23T23:59:59+00:00 \
  --reprocess-behavior completed
```

Saíram três execuções, com datas lógicas 21, 22 e 23. Cada uma carrega o dia anterior, então a gold refez os dias 20, 21 e 22. Rodamos o mesmo comando duas vezes, e a gold ficou assim nas duas:

```text
    dia     | pedidos | pedidos_pagos | receita_paga
------------+---------+---------------+--------------
 2026-10-20 |       4 |             2 |       430.90
 2026-10-21 |       3 |             2 |       111.90
 2026-10-22 |       3 |             3 |       293.30
```

Na versão ingênua, o segundo reprocesso dobrou os três dias. É o que o capítulo 6 mostrou.

Mais três regras:

- **Execuções simultâneas.** O reprocesso tem `max_active_runs` próprio, aplicado à parte do limite da Dag. No laboratório, com `max_active_runs=1` na Dag, as três execuções começaram juntas, e o reprocesso ficou registrado com limite 10. Passe `--max-active-runs` para poupar a réplica. Que isso alivia a origem é inferência nossa, não medida.
- **Um por vez.** Só existe um reprocesso aberto por Dag. Um segundo comando, logo depois de as execuções terminarem, foi recusado com `AlreadyRunningBackfill` até o Airflow fechar o primeiro.
- **O timetable muda as datas.** De 23 a 25, cron puro e intervalo clássico criaram datas lógicas 23, 24 e 25. Com `interval=` de um dia, saíram 22, 23 e 24. Numa Dag à meia-noite de Brasília com `interval=`, o mesmo pedido processou só os dias 22 e 23, porque os limites são 00:00 UTC e o disparo local é 03:00 UTC.

**O equívoco comum**

Reprocessar sem ensaio, com data sem hora. O comando termina com sucesso, e a semana sai com um dia a menos. E, se a carga não for idempotente, com os dias reprocessados em dobro.

### 7.4 Catchup, pausa e limpar tarefa

"Se eu pausar a Dag no feriado, os dias voltam sozinhos?"

**O que é**

Catchup é criar sozinho as execuções perdidas desde a data de início. No Airflow 3, vem desligado.

**Como funciona no Airflow**

Os padrões do Airflow 3 mudaram. Sem `schedule`, a Dag só roda à mão. Toda Dag nasce pausada. E o catchup vem desligado.

Com `catchup=True`, despausar dispara as execuções perdidas. Com o padrão, os dias do período pausado são pulados e só voltam por reprocesso explícito. No laboratório, uma Dag nova com `"0 7,13 * * *"`, início em 1º de outubro no fuso de Brasília e catchup desligado, criou ao despausar uma execução só: a mais recente, das 07h de Brasília, 10h em UTC.

Limpar (clear) uma tarefa, pela interface ou por `airflow tasks clear`, devolve o estado a vazio e a faz rodar outra vez. Mas confira qual código roda. Com Dags vindas de um pacote de Dags versionado (Dag bundle), como Git, limpar reexecuta por padrão a versão original, não a correção recém-publicada. O reprocesso usa a mais recente. Pacotes locais, S3 e GCS não versionam e rodam sempre o código mais recente.

**O equívoco comum**

Ligar o catchup para refazer dias. Ele só cria o que falta e não refaz o que já rodou. Para a silver corrigida, o caminho é o reprocesso com `completed`. E limpar a tarefa num pacote Git, sem escolher a versão mais recente, roda o código antigo; se o SQL mora no mesmo repositório, roda o SQL antigo também.

### 7.5 Antes de refazer a semana

1. Confirme que a carga apaga e regrava o dia.
2. Descubra o timetable e qual dia cada data lógica carrega.
3. Rode o ensaio com `--dry-run` e confira cada data.
4. Ponha hora explícita no `--to-date`.
5. Use `--reprocess-behavior completed` para refazer o que já rodou.
6. Limite as execuções simultâneas.
7. Confira a gold e o registro de carga depois.

Se a entrega ainda é à mão, o raciocínio é o mesmo. O script do laboratório recebe o dia em `--dia`, e você escolhe cada dia de propósito.

**Verificação do código deste capítulo**

- Dag `datas_por_timetable.py` (seis agendas): nível 3. Executada em 2026-10-29, em ambiente descartável, com a imagem `apache/airflow:3.3.2` (Python 3.13), num contêiner `standalone`. Comandos que provaram: `airflow dags unpause`, `airflow dags trigger` com e sem `-l`, disparo pela API REST, botão Acionar da interface e `airflow backfill create` com e sem `--dry-run`, com leitura dos logs das tarefas. Nível 2 da mesma Dag: `ruff check --select AIR,E,F,W,I --preview dags/` e `ruff format --check dags/`, ruff 0.12.12, sem erro.
- Dags `loja_ingenua` e `loja_idempotente` (`pipeline_loja.py`): nível 3. Executadas em 2026-10-29 com a imagem `apache/airflow:3.3.2` (Python 3.13) e Postgres `16.15-alpine`. Os dois comandos de reprocesso acima rodaram com `docker compose --profile airflow exec -T airflow-scheduler` na frente; as saídas são trechos. Nível 2: `ruff check --select E,F,W,I,B,UP --line-length 120` e `ruff format --check --line-length 120`, ruff 0.12.12, sem erro.
- Script `pipeline.py` (degrau à mão, argumento `--dia`): nível 3, executado em 2026-10-29 com Postgres 16.15-alpine; nível 2 com o mesmo ruff 0.12.12.
- Dag `registro_de_carga` (despausar com catchup desligado): nível 3, executada em 2026-10-29 com a imagem apache/airflow:3.3.2.
- Dados de pedidos e visitas: sintéticos.

As datas deste capítulo estão em UTC. O capítulo 8 mostra por que isso importa para uma loja em Brasília.

---

[Índice](../README.md#capítulos) · [Anterior: 6. Nova tentativa e idempotência: o preço do orquestrador](06-nova-tentativa-e-idempotencia.md) · [Próximo: 8. Fuso horário: o dia de quem?](08-fuso-horario.md)
