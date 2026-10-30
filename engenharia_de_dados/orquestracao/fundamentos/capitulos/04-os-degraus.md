---
title: "4. Os degraus: à mão, agendador, orquestrador"
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

[Índice](../README.md#capítulos) · [Anterior: 3. O que é orquestrar, e o que não é](03-o-que-e-orquestrar-e-o-que-nao-e.md) · [Próximo: 5. Vocabulário mínimo: Dag, tarefa, dependência, execução e estado](05-vocabulario-minimo.md)

## 4. Os degraus: à mão, agendador, orquestrador

"Preciso de Airflow já, ou posso começar rodando à mão?" A resposta depende do degrau em que a
carga está. São três. Cada um custa mais que o anterior e resolve algo que o anterior não
resolve. Você sobe quando o sinal aparece, não quando a ferramenta aparece numa lista.

### 4.1 Degrau 1: à mão

"Rodar à mão no começo não é amador?"

**O que é**

Rodar à mão é você disparar o script quando precisa e conferir o resultado na tela.

**Como funciona na prática**

No laboratório da mentoria, um script Python executa em ordem os arquivos SQL de bronze, silver e
gold de um dia, numa transação só. O Python não trata dado: só manda o banco rodar o SQL. Cada
dia levou cerca de 3 segundos, contando a subida do contêiner pelo `docker compose run`, sem
Airflow.

```bash
docker compose run --rm -T runner python scripts/pipeline.py --dia 2026-10-20
```

Trecho da saída:

```text
  bronze_pedidos.sql: ok
  silver_pedidos.sql: ok
  gold_vendas_por_dia.sql: ok
  registrar_carga.sql: ok
  resultado: bronze=4 silver=4 receita_paga=430.90
```

Nível 3: executado em ambiente descartável em 2026-10-29, com Docker Engine 28.3.3, Compose
2.39.1, Postgres 16.15, Python 3.13.15 e psycopg 3.3.5, sobre dados sintéticos.

A primeira tentativa falhou: um comentário com ponto e vírgula partiu a instrução no lugar
errado, e nada foi gravado. É para isso que este degrau serve: descobrir o dado, errar perto e
validar o SQL antes de pôr qualquer coisa num horário.

**O equívoco comum**

Achar que começar à mão é erro. O capítulo 2 já contou: o gerente de TI do caso começou assim, e
os mentores concordaram. O custo deste degrau está na pessoa: se ela esquece ou sai de férias, a
carga não roda.

### 4.2 Degrau 2: agendador

"Se eu agendar o script, já estou orquestrando?"

**O que é**

Agendador é a ferramenta que dispara um comando num horário; ele não resolve dependência entre
passos.

**Como funciona na prática**

O cron é o agendador do Unix. Pela especificação POSIX, o crontab é uma lista de comandos com
horários. A única reação a erro descrita é mandar por e-mail a saída não redirecionada. Não há
dependência entre comandos nem nova tentativa. O livro de SRE do Google resume: o cron
dispara e esquece.

No laboratório, o script do degrau 1 foi para um crontab que roda a cada minuto. Os cinco campos
são minuto, hora, dia do mês, mês e dia da semana.

```text
* * * * * cd /lab && python scripts/pipeline.py --executor cron >> /var/log/pipeline.log 2>&1
```

Nível 3: executado em ambiente descartável em 2026-10-29, com o `crond` do busybox numa imagem
`python:3.13.15-alpine3.24`. O cron fica aqui como explicação, sem laboratório para você.

Depois, derrubamos a réplica. O erro ficou num arquivo dentro do contêiner, nada tentou de novo
antes do minuto seguinte e o registro de carga não ganhou linha. Sem alerta configurado, ninguém
seria avisado. E o relógio do contêiner estava em UTC: um agendamento de 07h ali dispararia às
04h de Brasília. O capítulo 8 volta ao fuso.

Você provavelmente já tem um agendador: o Agendador de Tarefas do Windows (ou o
`schtasks /create /sc` na linha de comando), o SQL Server Agent, o `pg_cron` no Postgres ou a
atualização agendada do Power BI. A tabela da seção 4.4 compara o que cada um entrega. Se o seu
cron mora no WSL, atenção: a distro desliga depois de 15 segundos ociosa e, por inferência que
não testamos, o cron só dispara com ela de pé.

**O equívoco comum**

Achar que agendar é orquestrar. Agendar resolve a hora; não resolve a ordem, o aviso nem o
histórico. O intervalo curto tem armadilha própria: se a execução anterior ainda não terminou, a
próxima já começa, e elas se empilham. E o modelo periódico fica mais frágil à medida que o volume
cresce. O livro de SRE prefere pular a dobrar, porque a execução pulada se recupera e a dobrada
às vezes não. Se você fica no cron, o `flock -n` faz a execução sobreposta falhar em vez de
esperar:

```bash
( flock -n carga.lock sh -c 'echo "1a: rodando"; sleep 3; echo "1a: fim"' ) &
sleep 0.5
flock -n carga.lock sh -c 'echo "2a: rodando"'; echo "2a saiu com $?"
wait
flock -n carga.lock sh -c 'echo "3a: rodando"'; echo "3a saiu com $?"
```

```text
1a: rodando
2a saiu com 1
1a: fim
3a: rodando
3a saiu com 0
```

Nível 3: executado em ambiente descartável em 2026-10-29, com o util-linux 2.39.3. A segunda
execução não começou; a terceira rodou depois que a trava foi liberada.

### 4.3 Degrau 3: orquestrador

"O que o Airflow faz que o agendador não faz?"

**O que é**

Orquestrador é quem roda o código na ordem certa e guarda o estado; não é o código de limpeza.

**Como funciona na prática**

O salto não é ter horário, porque o cron também tem. É dependência entre passos, estado de cada
execução, nova tentativa, aviso e histórico. A seção 3.1 mostrou o que o Airflow oferece para
isso: o fluxo escrito em Python e uma interface para disparar, ler o log, reprocessar datas
passadas e refazer só as tarefas que falharam.

Nova tentativa e aviso existem, mas é você quem liga. No Airflow 3.3.2, o padrão é zero novas
tentativas, e o aviso de falha vem de uma função de retorno (callback) ou de um notificador
(notifier) que você configura. Os capítulos 6 e 9 mostram os dois.

O preço, medido numa mesma máquina em 2026-10-29: os degraus 1 e 2 couberam na casa de 34 MiB de
memória, já com o banco, e numa imagem de 72,7 MB. O Airflow no modo local (LocalExecutor) subiu
em 1 min 17 s, em quatro contêineres. Ficou na casa de 680 MiB logo depois de subir e de 0,86 GiB
depois dos experimentos, com imagem de 2,33 GB. E ele sempre exige algum código, como a seção 3.1
avisou.

**O equívoco comum**

Achar que o orquestrador melhora o dado. Ele não limpa nulo nem acerta fuso; quem faz isso é o
SQL da silver. Se o SQL de tratamento não está validado, o orquestrador repete o erro no horário,
todo dia.

### 4.4 Tabela comparativa

| Degrau e ferramenta | Dispara por | Nova tentativa | Aviso de falha | Ordem entre passos | Histórico e reprocesso | Custo e risco |
|---|---|---|---|---|---|---|
| À mão | Você | Você roda de novo | Você vê na tela | A ordem do script | Só o que o script registrar; você roda dia a dia | Quase nada de máquina; depende de alguém lembrar |
| cron | Horário | Não | E-mail com a saída não redirecionada | Não | Só o que o script registrar | Na casa de 5 MiB no laboratório; o erro fica num arquivo que ninguém lê |
| Agendador de Tarefas do Windows | Horário e evento do sistema | Sim, com contagem e intervalo | Aviso nativo não achado na documentação | Não conferido | Sem reprocesso de datas passadas; roda um horário perdido se você ligar a opção, desligada por padrão e só para alguns tipos de gatilho por horário | Já vem no Windows |
| SQL Server Agent | Agenda, alerta ou sob demanda | Não conferido | E-mail via Database Mail | Passos dentro de um trabalho (job) | Não conferido | Vem desligado; não existe no Express |
| `pg_cron` | Horário, dentro do Postgres | Não conferido | Não conferido | Não conferido | Histórico numa tabela do banco; uma instância de cada trabalho por vez | Fuso padrão GMT |
| Atualização agendada do Power BI | Horário: 8 por dia na capacidade compartilhada, 48 em Premium, PPU ou Fabric | Não conferido | E-mail ao dono; agenda desativada após quatro falhas seguidas | Não conferido | Não conferido | Começa em até 15 minutos do horário, pode atrasar até uma hora; banco na sua rede exige gateway |
| Airflow | Horário ou evento | Sim, por tarefa; zero por padrão | Função de retorno ou notificador que você configura | Sim, a Dag é o grafo | Estado e log de cada execução; backfill pela interface | Na casa de 0,86 GiB e imagem de 2,33 GB no laboratório; exige código e alguém que mantenha |

Alguns agendadores, como o SQL Server Agent, encadeiam passos dentro de um mesmo trabalho; o que
continua faltando é dependência entre trabalhos e sistemas e reprocesso de datas passadas.

"Não conferido" quer dizer que a documentação aberta para esta apostila não respondeu, não que o
recurso falte.

### 4.5 Quando subir de degrau

"Como sei que chegou a hora de automatizar?"

**O que é**

O sinal de subir é o momento em que o degrau atual passa a custar mais que o próximo. Os sinais
abaixo são critério da mentoria; nenhuma fonte primária neutra lista quando automatizar.

**Como funciona na prática**

Vamos ao caso. Um setor quer o número duas vezes por dia; outro, várias vezes por hora. A
atualização agendada do Power BI permite 8 por dia na capacidade compartilhada. Duas por dia
cabem com folga. Várias por hora não cabem, nem no limite de 48 por dia, que dá duas por hora em
média. O segundo setor pede um agendador fora do BI, e os outros sinais decidem entre cron e
orquestrador.

Depois vem a diretoria. Enquanto a entrega é eventual, rodar à mão é razoável. Quando ela vira
diária, ganha a cara do que o livro de SRE chama de trabalho penoso (toil): manual, repetitivo,
automatizável, tático, sem valor duradouro e crescendo junto com o serviço.

Sinais de subir:

- A carga ganhou dia e hora, e alguém cobra quando ela não chega.
- Há passos que dependem uns dos outros: réplica, bronze, silver, gold e registro de carga.
- Alguém precisa saber quando falhou, e a falha pede nova tentativa.
- Você precisa refazer dias passados depois de corrigir o SQL.
- A frequência passou do que a ferramenta atual aguenta.

Sinais de que ainda não é hora:

- O SQL de tratamento ainda não está validado.
- Você ainda está descobrindo de onde vem cada número.
- A entrega ainda é eventual.

**O equívoco comum**

Subir por catálogo, não por sinal. O mesmo livro avisa que não convém automatizar todo componente
de todo sistema e que automação sem critério cria tantos problemas quanto resolve. Suba um degrau
por vez e leve junto o que aprendeu à mão.

Quando o sinal aparecer, você vai precisar das palavras do orquestrador. O capítulo 5 dá o
vocabulário mínimo.

---

[Índice](../README.md#capítulos) · [Anterior: 3. O que é orquestrar, e o que não é](03-o-que-e-orquestrar-e-o-que-nao-e.md) · [Próximo: 5. Vocabulário mínimo: Dag, tarefa, dependência, execução e estado](05-vocabulario-minimo.md)
