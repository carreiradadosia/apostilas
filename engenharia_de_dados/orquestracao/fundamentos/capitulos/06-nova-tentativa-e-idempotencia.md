---
title: "6. Nova tentativa e idempotência: o preço do orquestrador"
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

[Índice](../README.md#capítulos) · [Anterior: 5. Vocabulário mínimo: Dag, tarefa, dependência, execução e estado](05-vocabulario-minimo.md) · [Próximo: 7. Tempo: agendamento, data lógica, reprocesso e catchup](07-tempo.md)

## 6. Nova tentativa e idempotência: o preço do orquestrador

"Rodei a carga de ontem de novo, só para garantir. O painel dobrou. Nada deu erro. O que aconteceu?"

O orquestrador traz três jeitos de rodar o mesmo dia outra vez. A nova tentativa de uma tarefa que falhou. O reprocessamento de datas passadas. E a limpeza (clear) de uma tarefa, para ela rodar de novo. À mão, você faz o mesmo quando esquece que já rodou.

Esse é o preço do orquestrador. Antes de ligar qualquer um desses recursos, a carga precisa aguentar rodar de novo.

### 6.1 Idempotência

"Idempotência parece palavra de engenheiro. Por que eu preciso dela?"

**O que é**

Idempotência: rodar de novo dá o mesmo resultado de rodar uma vez.

A definição que usamos parte da RFC 9110, a especificação do HTTP: um método é idempotente quando várias requisições idênticas têm o mesmo efeito de uma só. A RFC também diz que o cliente não deve repetir sozinho uma requisição que não é idempotente. Ela trata de HTTP, não de dados; levar a definição para uma carga é extrapolação nossa, didática. A lógica vale igual: só repita sozinho o que aguenta ser repetido.

**Como funciona no Airflow**

A página de boas práticas do Airflow 3.3.2 transforma isso em regra para cada tarefa:

- Trate a tarefa como uma transação de banco, sem resultado pela metade.
- Ela deve dar o mesmo resultado a cada reexecução, porque o Airflow pode tentar de novo.
- Não use INSERT numa reexecução, porque pode duplicar linha. Troque por UPSERT, que insere ou atualiza pela chave, numa operação só.
- Leia e grave numa partição específica; a documentação sugere `data_interval_start` como partição. Atenção: no Airflow 3, com a agenda em cron padrão, a janela tem duração zero e esse valor é o próprio momento do disparo; o capítulo 7 mostra como escolher o dia certo, e o laboratório usa a data lógica menos um dia. Nunca leia "o dado mais recente disponível".
- Não use `now()` em cálculo crítico.

**O equívoco comum**

Achar que idempotência é assunto só de engenheiro sênior. Ela é a primeira coisa a conferir em qualquer carga que alguém, ou algo, pode rodar duas vezes.

### 6.2 O que provamos: o mesmo dia, duas vezes

"Se eu rodar o dia 20 de novo, o que muda?" Vamos ver por que duplicou.

**Como funciona na prática**

No laboratório da rede de lojas, a carga de um dia lê a réplica, grava o bronze e refaz silver e gold. Testamos duas versões do bronze. A ingênua só insere. A idempotente apaga o dia e insere de novo, na mesma transação. O `%(dia)s` é o dia que o script passa.

```sql
-- Naive load: every rerun of the same day appends the same rows again.
INSERT INTO bronze.pedidos
    (id, cliente, valor, valor_texto, status, criado_em, atualizado_em, _dia_referencia)
SELECT id, cliente, valor, valor_texto, status, criado_em, atualizado_em, %(dia)s::date
FROM replica.pedidos
WHERE criado_em >= %(dia)s::date
  AND criado_em < %(dia)s::date + 1;
```

```sql
-- Idempotent load: replace the whole day, the caller commits both statements together.
DELETE FROM bronze.pedidos
WHERE _dia_referencia = %(dia)s::date;

INSERT INTO bronze.pedidos
    (id, cliente, valor, valor_texto, status, criado_em, atualizado_em, _dia_referencia)
SELECT id, cliente, valor, valor_texto, status, criado_em, atualizado_em, %(dia)s::date
FROM replica.pedidos
WHERE criado_em >= %(dia)s::date
  AND criado_em < %(dia)s::date + 1;
```

Nível 3: executado em ambiente descartável em 2026-10-29, com
`docker compose run --rm -T runner python scripts/pipeline.py --dia 2026-10-20` e o mesmo comando
com `--modo ingenuo`; PostgreSQL 16.15, Python 3.13.15, psycopg 3.3.5. Dados sintéticos.

Carregamos o dia 20 com a versão que apaga e regrava: 4 linhas, 430,90. Rodar de novo deu o mesmo. Depois, sobre esse dia já carregado, rodamos a versão ingênua duas vezes: 8 linhas e 861,80, depois 12 linhas e 1.292,70. Por fim, voltamos à versão que apaga e regrava.

| Ordem | Versão | Linhas no bronze | Receita do dia |
|---|---|---|---|
| 1 | Apaga e regrava o dia | 4 | 430,90 |
| 2 | Apaga e regrava o dia | 4 | 430,90 |
| 3 | Ingênua (só INSERT) | 8 | 861,80 |
| 4 | Ingênua (só INSERT) | 12 | 1.292,70 |
| 5 | Apaga e regrava o dia | 4 | 430,90 |

Todas as execuções terminaram com sucesso. Nenhum erro, nenhum aviso.

A quinta execução rodou sobre o dia triplicado e voltou a 4 linhas e 430,90. Apagar e regravar também conserta o dia duplicado.

**O equívoco comum**

Silver e gold já apagavam e regravavam o dia. Mesmo assim, dobraram, porque refizeram o dia a partir de um bronze duplicado. A idempotência começa no primeiro passo que grava.

### 6.3 Quatro jeitos de gravar, um que duplica calado

"Eu ponho chave primária e pronto?"

**Como funciona na prática**

Gravamos a mesma carga do dia 21 duas vezes, em três tabelas de rascunho, e comparamos com a versão que apaga e regrava o dia.

| Jeito de gravar | Segunda carga do mesmo dia | Sinal | Serve para |
|---|---|---|---|
| INSERT sem chave | Duplica: 3 linhas viram 6 | Nenhum, termina com sucesso | Nada que possa rodar de novo |
| INSERT com chave primária | Falha com `duplicate key value violates unique constraint` | Alto, a carga para | Barrar a duplicação; não roda de novo sozinha |
| UPSERT (`ON CONFLICT DO UPDATE`) | Fica igual: 3 linhas | Nenhum, resultado igual | Linhas com chave estável, como o número do pedido |
| Apagar e regravar o dia | Fica igual e conserta o dia duplicado | Nenhum, resultado igual | Carga por dia ou por partição |

No PostgreSQL, `ON CONFLICT DO UPDATE` garante um resultado atômico, INSERT ou UPDATE, mesmo com concorrência, desde que não haja um erro independente. É o que se chama UPSERT.

```sql
INSERT INTO com_upsert SELECT id, valor FROM replica.pedidos WHERE criado_em::date = '2026-10-21'
    ON CONFLICT (id) DO UPDATE SET valor = EXCLUDED.valor;
```

Nível 3: executado em ambiente descartável em 2026-10-29, duas vezes seguidas, com
`psql -U dw -d dw -f -` contra PostgreSQL 16.15. Na tabela com chave primária e INSERT puro, a segunda carga respondeu:

```text
psql:<stdin>:11: ERROR:  duplicate key value violates unique constraint "com_chave_pkey"
DETAIL:  Key (id)=(105) already exists.
```

Esses jeitos têm nome na literatura. No repositório de código do livro *Data Engineering Design
Patterns*, de Bartosz Konieczny, o capítulo de idempotência reúne padrões que aqui chamamos de
sobrescrita (Fast Metadata Cleaner, Data Overwrite), de merge (Merger, Stateful Merger) e de
idempotência por chave (Keyed Idempotency), entre outros.

**O equívoco comum**

Achar que a chave primária resolve. Ela troca a duplicação calada por uma falha alta, o que é melhor que dobrar. Mas a mesma carga, rodada de novo, bate na mesma chave e falha outra vez.

### 6.4 Nova tentativa: ligar depois, com teto

"Por que não ligo cinco tentativas em tudo e esqueço?"

**O que é**

Nova tentativa (retry): rodar de novo uma tarefa que falhou. No Airflow 3, desligada por padrão.

**Como funciona no Airflow**

Sem configuração, o Airflow 3.3.2 não tenta de novo: `default_task_retries` vale 0. Também não há tempo limite: com `default_task_execution_timeout` vazio, a tarefa nunca é interrompida por demora. Você liga as tentativas na Dag ou na tarefa. No laboratório, ligamos uma, com 10 segundos de espera:

```python
@dag(
    dag_id=dag_id,
    schedule="0 6 * * *",
    start_date=pendulum.datetime(2026, 10, 15, tz="America/Sao_Paulo"),
    catchup=False,
    max_active_runs=1,
    default_args={"retries": 1, "retry_delay": pendulum.duration(seconds=10)},
    tags=["mentoria", "laboratorio"],
)
```

Nível 3: passou em `ruff check --select E,F,W,I,B,UP` (ruff 0.12.12) e foi executado em ambiente
descartável em 2026-10-29, no Airflow 3.3.2 (imagem `apache/airflow:3.3.2`, o mesmo digest de `apache/airflow:3.3.2-python3.13`, com Python 3.13.15), com
`airflow dags trigger loja_ingenua -l 2026-10-21T09:00:00+00:00 -r retry_ingenuo -c '{"simular_queda": true}' -o plain`
dentro do contêiner do scheduler, e o equivalente para `loja_idempotente`.

Depois provocamos uma queda. Atenção: a falha é simulada. Na primeira tentativa, a tarefa do bronze grava, confirma e levanta um erro, como um processo que cai logo depois de gravar.

- Na versão ingênua, a segunda tentativa grava o dia outra vez. A execução termina com sucesso. O gold dobra: 8 pedidos e 861,80.
- Na versão idempotente, a segunda tentativa apaga as 4 linhas da primeira e regrava 4. O gold fica em 4 pedidos e 430,90.

**Espera crescente e teto**

Nova tentativa resolve falha passageira. A AWS chama as novas tentativas de egoístas: cada uma gasta mais tempo do servidor e pode piorar uma sobrecarga. A recomendação é backoff exponencial (esperar cada vez mais entre uma tentativa e outra), com teto, com jitter (um sorteio na espera, para as tentativas não chegarem juntas) e com limite de tentativas. E, para a AWS, uma chamada com efeito colateral só é segura de repetir se for idempotente; uma carga que grava dado é exatamente esse caso.

Não verificado: se o Airflow 3.3.2 sorteia a espera; não conferimos isso na documentação.

**Erro que tentar de novo não resolve**

Uma chave de API inválida continua inválida na quinta tentativa. Esse erro deve falhar direto, com `AirflowFailException`, que marca a tarefa como falha e ignora as tentativas restantes. Desde a versão 3.3.0, as políticas de nova tentativa (Retry Policies) decidem por tipo de erro entre tentar de novo, falhar já ou seguir a regra padrão. Podem falhar antes; nunca passam do máximo configurado.

**O equívoco comum**

Tratar nova tentativa como conserto. Numa carga que não é idempotente, ela troca uma falha visível por um número dobrado e verde.

### 6.5 Pular é melhor que dobrar

"E se eu não souber se a carga de ontem rodou?"

**O que é**

O livro *Site Reliability Engineering*, do Google, separa as rotinas agendadas em dois eixos. Algumas rodam duas vezes sem dano, como a coleta de lixo; outras não, como o envio de um boletim por e-mail. Algumas podem pular uma execução; outras não, como a folha de pagamento. Entre pular e dobrar, o Google prefere pular: a execução pulada se recupera, a dobrada às vezes não. E o dono deve acompanhar o efeito da rotina por conta própria.

**Como funciona na prática**

Na rede de lojas, o efeito é a receita do dia. O status verde não mostrou a duplicação em nenhum caminho testado na versão ingênua:

- nova tentativa: 430,90 virou 861,80;
- reprocessamento de três dias, rodado duas vezes: os três dias dobraram;
- limpeza da tarefa do bronze e das seguintes, num dia já carregado: 111,90 virou 223,80.

Na versão idempotente, a nova tentativa e o reprocessamento não mudaram o número; a limpeza foi testada só na ingênua. O capítulo 7 detalha o reprocessamento, e o 9 mostra como o registro de carga acompanha o efeito.

**Como inspecionar antes de ligar**

1. Rode o mesmo dia duas vezes, à mão.
2. Compare contagem de linhas e soma depois de cada uma. Precisam ser iguais.
3. Confira se cada passo que grava apaga e regrava a sua partição ou usa UPSERT pela chave.
4. Procure `now()` e "o mais recente" no SQL que calcula número.
5. Só então ligue as tentativas, com teto e espera crescente.

Começar à mão continua valendo. É à mão que você vê o número dobrar pela primeira vez, sem diretoria olhando.

**O equívoco comum**

Achar que o status verde prova que o dado está certo. Ele prova que o código terminou.

Se rodar de novo é seguro, falta saber qual dia cada execução processa. É o capítulo 7.

---

[Índice](../README.md#capítulos) · [Anterior: 5. Vocabulário mínimo: Dag, tarefa, dependência, execução e estado](05-vocabulario-minimo.md) · [Próximo: 7. Tempo: agendamento, data lógica, reprocesso e catchup](07-tempo.md)
