---
title: "18. Glossário"
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

[Índice](../README.md#capítulos) · [Anterior: 17. Plano de continuidade](17-plano-de-continuidade.md) · [Próximo: Referências, Fontes verificadas (2026-10-29) e Reconferência na 3.4.0](19-referencias.md)

## 18. Glossário

Leu um termo e travou? Volte aqui. Cada termo tem uma frase, na mesma grafia usada nos capítulos. Termo em inglês aparece na grafia usada nos capítulos e, quando o texto usa tradução, ela vem junto.

Um exemplo do formato: idempotência quer dizer que rodar de novo dá o mesmo resultado de rodar uma vez. Se a carga de ontem roda duas vezes e a contagem dobra, ela não é idempotente.

### O que é orquestrar

- **Orquestração**: executar um fluxo definido de passos, na ordem, com estado, nova tentativa e histórico.
- **Orquestrador**: quem roda o código na ordem certa e guarda o estado; não é o código de limpeza.
- **Agendador**: ferramenta que dispara comandos por horário (alguns também por evento do sistema), como o cron e o Agendador de Tarefas do Windows; não guarda o estado do fluxo nem resolve a ordem entre passos.
- **cron**: agendador do Unix, uma lista de comandos com horários; dispara e esquece.

### Peças do Airflow

- **Dag**: grafo dirigido sem ciclo de tarefas; no Airflow, a definição do fluxo.
- **Tarefa (task)**: um passo da Dag, criado a partir de um operador, de um sensor ou de uma função Python com `@task`.
- **Operador**: modelo de tarefa, como o que executa SQL num banco.
- **Sensor**: operador que só espera uma condição externa.
- **Dependência**: aresta do grafo; por padrão, uma tarefa só começa depois que todas as anteriores terminam com sucesso.
- **Pool**: limite de tarefas simultâneas contra um mesmo sistema.
- **Scheduler**: componente do Airflow que decide o que roda e quando, respeitando as dependências da Dag; não é o agendador do degrau 2.
- **Dag processor**: componente do Airflow 3 que lê os arquivos das Dags.
- **Executor**: o mecanismo que roda as tarefas, configurado no scheduler e rodando dentro do processo dele; o padrão, `LocalExecutor`, roda cada tarefa como subprocesso do scheduler.
- **Banco de metadados**: onde o orquestrador guarda execuções, estados e histórico.
- **XCom**: canal do Airflow para passar pouco dado entre tarefas; nunca a tabela inteira.
- **Connection**: credencial e endereço de um sistema externo, guardados fora do código da Dag.

### Execução e tempo

- **Execução da Dag (Dag run)**: uma instância da Dag no tempo, com estado próprio.
- **Estado**: situação de cada tarefa numa execução, como na fila, rodando, sucesso, falha ou aguardando nova tentativa.
- **Disparo por horário**: execução criada pela agenda da Dag.
- **Disparo por evento**: execução criada quando uma tarefa atualiza um dado (asset) e termina com sucesso; desde o Airflow 3.0 também há disparo por evento externo.
- **Data lógica**: a data a que uma execução se refere; nem sempre igual ao momento em que roda.
- **Timetable**: a regra que transforma a agenda em execuções e, quando houver, janelas de dados.
- **Janela de dados**: o intervalo de tempo que uma execução deve processar; no Airflow 3, uma agenda em cron tem janela de duração zero, a menos que você declare `interval=` no timetable.
- **UTC**: tempo universal coordenado; fuso padrão do Airflow e três horas à frente de Brasília.
- **Catchup**: criar sozinho as execuções perdidas desde a data de início; desligado por padrão no Airflow 3.
- **Reprocessamento de datas passadas (backfill)**: criar execuções para dias que já passaram.

### Quando dá errado

- **Nova tentativa (retry)**: rodar de novo uma tarefa que falhou; no Airflow 3.3.2, o padrão é zero tentativas, e você liga na Dag ou na tarefa.
- **Backoff**: esperar cada vez mais entre uma tentativa e outra.
- **Jitter**: um sorteio na espera entre tentativas, para elas não chegarem juntas.
- **Alerta**: aviso a uma pessoa quando algo falha; no Airflow, por callback ou notifier.
- **Callback**: função que o Airflow chama quando o estado de uma tarefa muda, como `on_failure_callback`.
- **Notifier**: notificador pronto que entra no lugar da função de callback.
- **Tarefa vigia (watcher)**: tarefa a jusante de todas as outras, com `TriggerRule.ONE_FAILED`, para a execução não terminar verde com uma falha no meio.
- **Trabalho penoso (toil)**: trabalho manual, repetitivo, automatizável, tático, sem valor duradouro e que cresce junto com o serviço.
- **Falha silenciosa**: carga que termina com sucesso e não traz dado, ou traz dado errado.
- **Idempotência**: rodar de novo dá o mesmo resultado de rodar uma vez.
- **UPSERT**: inserir ou atualizar pela chave, numa operação só.
- **Registro de carga**: tabela com cada carga, dizendo quando rodou, se foi agendada ou manual e quantas linhas trouxe.

### Dado e banco

- **Réplica só leitura**: cópia do banco de produção que aceita consulta e não aceita escrita.
- **Bronze, silver e gold**: camadas da arquitetura medalhão, com dado cru, validado e enriquecido, pronto para o negócio; prática recomendada, não obrigatória.
- **CDC**: captura de mudanças; leva cada alteração da origem para outro lugar. Ferramentas de replicação como o AWS DMS e o Debezium fazem isso lendo o log de transações do banco de origem.
- **SCD tipo 1**: sobrescrever o valor e perder o histórico.
- **SCD tipo 2**: guardar cada versão de um valor com início e fim de vigência.

O equívoco comum é decorar o glossário antes de rodar a primeira Dag. Vamos pelo caminho inverso: rode, veja o termo na tela e volte aqui para fixar.

---

[Índice](../README.md#capítulos) · [Anterior: 17. Plano de continuidade](17-plano-de-continuidade.md) · [Próximo: Referências, Fontes verificadas (2026-10-29) e Reconferência na 3.4.0](19-referencias.md)
