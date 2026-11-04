---
title: "4. Camadas: onde cada regra mora"
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

[Índice](../README.md#capítulos) · [Anterior: 3. O que é modelar e transformar, e o que não é](03-o-que-e-modelar-e-transformar-e-o-que-nao-e.md) · [Próximo: 5. Grão: o que uma linha significa](05-grao.md)

## 4. Camadas: onde cada regra mora

"Sei escrever o `TRIM`. Mas ele vai na silver ou na gold? E o `CASE` de status?" Essa dúvida aparece na hora de abrir o editor.

A resposta curta cabe em duas linhas. Na silver mora o que conserta registro a registro sem mudar o grão, isto é, sem mudar o que uma linha significa. Na gold mora o que junta ou agrega. Isso é **critério da mentoria**, não regra de mercado.

Vamos ver de onde ele vem e aplicá-lo em seis regras da rede de lojas. No fim, voltamos à primeira decisão de arquitetura, que o capítulo 2 adiantou: a réplica não recebe a silver.

### 4.1 Preciso mesmo de três camadas?

**O que é**

A arquitetura medalhão organiza o dado em camadas que indicam qualidade: bronze (cru), silver (validado) e gold (enriquecido). A documentação da Databricks a chama de "a recommended best practice but not a requirement". Ou seja, prática recomendada, não requisito.

Usamos as três porque a rede de lojas já chegou assim da Orquestração.

| Camada | O que a documentação da Databricks diz | Na rede de lojas |
|---|---|---|
| Bronze | Ingestão crua, com validação mínima | `bronze.pedidos`, `bronze.produtos_foto` |
| Silver | Limpa e valida (nulos, duplicatas, conversão de tipo, junções). Guarda ao menos uma representação validada e não agregada de cada registro | `silver.pedidos`, `silver.itens` |
| Gold | Modelagem dimensional e agregação | `gold.fct_vendas`, `gold.vendas_por_dia` |

**O equívoco comum**

"Na bronze não há validação nenhuma." O quadro da página da Databricks diz isso, mas a seção normativa fala em "Minimal data validation". Fique com a regra: validação mínima, não zero.

### 4.2 Onde mora o `CASE WHEN` de negócio?

**O que as fontes dizem**

As fontes não concordam. Melhor saber disso antes de ouvir uma resposta categórica.

| Fonte | O que diz |
|---|---|
| Documentação da Databricks | A silver pode ter junções, e também agregados quando muitos consumidores dependem deles. É comum começar a modelar já nela. |
| Post da Databricks, de 2022 | A silver recebe transformações "just-enough" (só o suficiente). A maior parte das regras de negócio complexas entra na passagem da silver para a gold, que recebe, por exemplo, a estrela. |
| Guia de staging do dbt | A staging (camada de preparação) aceita lógica condicional de categorização e veta agregação, porque mudar o grão ali faz perder acesso ao dado de origem. Junção é "almost always a bad idea", com exceções e por outro motivo: computação duplicada e relações confusas. |

O guia do dbt nem usa a palavra medalhão. Ele descreve um arco, do dado moldado pela origem ("source-conformed") ao dado moldado pelo negócio ("business-conformed"), para aplicar cada transformação num lugar só. Nenhuma fonte oficial que consultamos diz que staging é silver.

**Critério da mentoria**

Na silver, a regra que conserta registro a registro sem mudar o grão: nulo, texto, data, fuso. Na gold, o que junta ou agrega.

Para decidir, faça duas perguntas sobre a regra:

1. Ela resume várias linhas num número de negócio, como a receita do dia?
2. Ela traz para a linha outro assunto do negócio, como loja ou produto?

Qualquer sim, gold. Dois nãos, silver. Assim, cada regra tem um lugar só, o mesmo objetivo do guia do dbt.

A ponte com o dbt também é critério da mentoria: no laboratório, os modelos `stg_` moram na silver, e os `fct_` e `dim_`, na gold.

### 4.3 Como fica em regras de verdade?

**Como funciona na prática**

São seis regras que rodam no laboratório da rede de lojas. Nada aqui pede ferramenta: são scripts SQL rodados à mão.

| Regra | Trecho do laboratório | Camada | Motivo |
|---|---|---|---|
| `TRIM` no nome | `initcap(trim(nome))` | Silver | Conserta o texto na própria linha. As 3 lojas seguem 3 linhas. |
| De-para da categoria | `COALESCE(d.categoria, lower(unaccent(trim(u.categoria))))` | Silver | Troca `papelria` por `papelaria`. Conserta o valor na própria linha, sem criar nem perder produto: o `LEFT JOIN` não multiplica. |
| `CASE` de status | `CASE lower(trim(status)) ... ELSE 'desconhecido' END` | Silver | Troca um valor por outro na mesma linha. |
| Fuso | `AT TIME ZONE 'UTC' AT TIME ZONE 'America/Sao_Paulo'` | Silver | Corrige a leitura da hora de cada atendimento. Os 4 seguem 4. |
| Receita por dia | `sum(valor_item) FILTER (WHERE status = 'pago')` com `GROUP BY data_id` | Gold | Agrega. O grão passa de item para dia: 13 itens viram 3 linhas. |
| Estrela | `gold.fct_vendas` com `dim_loja`, `dim_produto` e `dim_data` | Gold | Junta. O grão não muda, são 13 itens e 13 linhas, mas a linha ganha loja, produto e data. |

Esquema estrela é o modelo dimensional em banco relacional: fatos ligadas às dimensões por chave. O capítulo 9 o constrói. Você roda as quatro primeiras regras no Lab 1 e as duas últimas no Lab 3.

> Verificação: nível 3. Executado em 2026-11-03, em Linux, com `postgres:16.15-alpine`. Comandos:
> `docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -f /sql/20_silver.sql` e o
> mesmo com `/sql/30_gold.sql`. Trechos desses dois arquivos. Saídas em
> `lab/saidas/lab1_silver_a_mao.txt` e `lab/saidas/lab3_gold_estrela_e_fan_out.txt`.

**O equívoco comum**

"Tem `LEFT JOIN` no de-para, então o critério furou." Não furou. A tabela `silver.de_para_categoria` guarda só correções, com chave primária em `categoria_origem`. Cada categoria acha no máximo uma correção, e nenhum produto vira dois. Ela não traz assunto novo: conserta o valor da própria linha. `TRIM`, caixa e acento não corrigem erro de digitação; isso pede um de-para que alguém mantém.

**Onde o critério pede explicação**

Três regras da silver mudam a contagem de linhas que vem da bronze. Melhor dizer às claras.

- **Duplicata.** `bronze.pedidos` tem 11 linhas e `silver.pedidos`, 10, porque o pedido 103 veio em duas cargas. A silver não muda o que a linha significa: devolve "uma linha por pedido". O capítulo 6 mostra como.
- **Última foto.** Com as três fotos, `bronze.produtos_foto` tem 15 linhas e `silver.produtos`, 5, porque a silver lê a última foto de cada produto.
- **Vigência do preço.** A foto tem uma linha por produto e dia. `silver.produtos_vigencia` tem uma por produto e período de preço. Aqui o grão muda, sim, e a regra fica na silver mesmo assim. Critério da mentoria: ela fala de um assunto só, não soma número de negócio e entrega à gold o preço de cada período. O capítulo 11 mostra como.

### 4.4 Por que guardar a foto crua na bronze?

"O sistema sobrescreve o preço toda noite. Se depois eu vou limpar, por que guardar a foto crua?"

**O que é**

Foto é a cópia agendada do estado de uma tabela num dia. Nenhuma fonte diz em que camada ela mora. Critério da mentoria: fica crua na bronze, e a silver monta a vigência.

```sql
-- Daily photo of the product table, raw. Run with: psql -v dia=2026-10-20 -f ...
DELETE FROM bronze.produtos_foto WHERE _dia_referencia = :'dia'::date;
INSERT INTO bronze.produtos_foto SELECT *, :'dia'::date FROM replica.produtos;
SELECT _dia_referencia, count(*) AS linhas FROM bronze.produtos_foto GROUP BY 1 ORDER BY 1;
```

> Verificação: nível 3. Executado em 2026-11-03, com `postgres:16.15-alpine`. Comando:
> `docker compose exec -T postgres psql -U dw -d dw -v ON_ERROR_STOP=1 -v dia=2026-10-20 -f /sql/11_bronze_foto_precos.sql`,
> com `DELETE 0` e `INSERT 0 5`. Saída em `lab/saidas/lab1_silver_a_mao.txt`.

**Por que crua**

O motivo é poder refazer. O histórico que o dbt monta, chamado snapshot (capítulo 11), não se reconstrói sozinho. A documentação avisa: "Snapshots ignore both the full_refresh config and the --full-refresh flag".

No laboratório, apagamos esse histórico e o refizemos dia a dia, a partir das fotos dos dias 20, 21 e 22. Voltaram as mesmas 7 linhas.

> Verificação: nível 3. Executado em 2026-11-03, com `dbt-core` 1.12.6, `dbt-postgres` 1.11.0 e
> `postgres:16.15-alpine`. Comando: `docker compose --profile dbt run --rm dbt dbt snapshot --vars '{dia_foto: "2026-10-20"}'`,
> repetido para os dias 21 e 22. Saída em `lab/saidas/lab5_projeto_dbt.txt`.

### 4.5 Posso criar a silver na réplica?

"Já tenho uma réplica. Não dá para criar a silver nela e poupar outro banco?" É a primeira decisão de arquitetura, que o capítulo 2 adiantou. Aqui vai a prova.

**Como inspecionar, no Postgres**

Não dá. A documentação do Postgres diz que, em espera ativa (hot standby), "not even temporary tables may be written". Testamos numa réplica descartável. A leitura funcionou. A escrita falhou, inclusive a view.

```text
### SELECT pg_is_in_recovery()
t
### SELECT count(*) FROM produto
1
### CREATE TABLE silver_produto AS SELECT * FROM produto
ERROR:  cannot execute CREATE TABLE AS in a read-only transaction
### CREATE TEMP TABLE tmp_produto (id int)
ERROR:  cannot execute CREATE TABLE in a read-only transaction
### CREATE VIEW vw_produto AS SELECT * FROM produto
ERROR:  cannot execute CREATE VIEW in a read-only transaction
```

> Verificação: nível 3. Executado em 2026-11-03, em `postgres:16.15-alpine`, com a réplica criada por
> `pg_basebackup -R` e cada comando rodado por `psql`. Teste à parte do laboratório da rede de lojas;
> script e saída não publicados.

Há um segundo motivo. Consulta longa nessa réplica pode ser cancelada por conflito com a replicação, quando o primário (o banco original) atualiza muito. O parâmetro `hot_standby_feedback` evita o cancelamento por limpeza, mas pode inchar tabela no primário.

Então onde a silver mora? Em outro banco, que lê a réplica. No laboratório, o banco `erp` faz o papel de réplica e o banco `dw` guarda bronze, silver e gold. Ali a réplica é simulada por um papel só de leitura; por isso o teste acima usou uma de verdade.

> Verificação: nível 3, em 2026-11-04, com `postgres:16.15-alpine`. Saída em `lab/saidas/lab9_fatos_da_carga.txt`: o `SELECT` como `replica_leitura` devolve 10 pedidos e o `UPDATE` falha com `cannot execute UPDATE in a read-only transaction`, também pelo `postgres_fdw`.

**No SQL Server, depende**

Depende da tecnologia de réplica, e não sabemos qual é a sua. A documentação da Microsoft sobre grupos de disponibilidade Always On diz o seguinte:

- O banco secundário legível não aceita mudança de esquema nem de dado.
- Outros bancos de leitura e escrita da mesma instância aceitam escrita, inclusive `tempdb`.
- O grupo de disponibilidade básico, só da edição Standard, nem permite leitura no secundário.

Leitura da mentoria: por isso a silver não mora no secundário. Essas páginas tratam só do Always On, e nada disso foi executado aqui (nível 1, conferido na documentação). O T-SQL da silver e da gold está no capítulo 17.

Antes de desenhar, leve estas perguntas ao time: que tecnologia é a nossa réplica? Qual edição? Ela aceita leitura? Em que banco gravável a silver vai morar?

Você já sabe onde cada regra mora. Mas o critério inteiro depende de uma palavra que ainda não provamos: grão. É dela que trata o próximo capítulo.

---

[Índice](../README.md#capítulos) · [Anterior: 3. O que é modelar e transformar, e o que não é](03-o-que-e-modelar-e-transformar-e-o-que-nao-e.md) · [Próximo: 5. Grão: o que uma linha significa](05-grao.md)
