---
title: "24. Plano de continuidade"
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

[Índice](../README.md#capítulos) · [Anterior: 23. Erros comuns e como corrigir](23-erros-comuns-e-como-corrigir.md) · [Próximo: 25. Glossário](25-glossario.md)

## 24. Plano de continuidade

"Terminei. E agora?" Depende de onde você está. Aqui há um próximo passo por perfil e o que vem depois na trilha. Falamos de conceito, não de módulo: nada aqui promete material com data.

### 24.1 Qual é o meu próximo passo?

"Tenho pouco tempo. Por onde sigo?" Escolha a sua linha. O caminho é critério da mentoria.

| Se você | Próximo passo |
|---|---|
| quer só entender do que se trata | Guarde a frase guia. Na próxima tabela que aparecer, pergunte o que uma linha significa. |
| gerencia e quer decidir | Leve ao time as perguntas do capítulo 19. |
| está começando na área | Refaça os Labs 0 a 6 sem olhar a saída. Depois, o exercício prático do capítulo 21. |
| já trabalha com dados | Refaça a silver com uma tabela da própria empresa, em ambiente seu. |
| é engenheiro e mira o próximo nível | Rode o Lab 7 e deixe escrita a decisão sobre a geração do dbt, na seção 24.4. |

### 24.2 Como levo isso para a minha empresa?

"O meu cenário não é a rede de lojas. Como começo?"

**Quem gerencia** começa, por critério da mentoria, pelas perguntas que vêm antes do SQL: o que uma linha significa e quem é dono do número. Se ouvir "depende" ou "todo mundo", você achou o próximo passo.

**Quem é da área** refaz a silver. O roteiro é critério da mentoria:

1. Traga uma tabela só para um banco seu, descartável. Nunca escreva na produção nem na réplica.
2. Confirme se a empresa permite a cópia. Sem permissão, ou com dado pessoal, use a mesma estrutura com dado inventado.
3. Escreva o grão antes do SQL.
4. Trate nulo, texto, data e fuso (capítulos 6 a 8; no SQL Server, também o 17), com um teste de dado para cada regra (capítulo 13).
5. Compare contagem e total com a origem.

Não conhecemos a versão, a edição nem a collation do seu banco, e o laboratório só rodou em Linux. Confira cada receita no seu ambiente.

**O equívoco comum.** Esperar a ferramenta para começar. SQL à mão serve, e nenhum critério da rubrica do capítulo 22 pede dbt.

### 24.3 O que fica para os próximos conceitos?

"Sobrou assunto. Quem cuida do resto?" Quatro vizinhos. Confira na trilha o que já está disponível.

| Conceito | O que ele responde | O que você leva daqui |
|---|---|---|
| Orquestração | Quem roda o código, em que ordem e a que horas. | O SQL que você validou vira tarefa. |
| Ingestão e captura de mudanças (CDC, change data capture) | Como o dado chega da origem. | A bronze que recebe e a pergunta: a foto diária ainda atende? |
| Qualidade e governança | Contratos, integração contínua (CI, continuous integration) e testes a fundo. | Os testes do capítulo 13 e o registro do número do capítulo 18. |
| Entrega e IA | Como o número chega a quem pergunta, com a camada semântica. | A estrela e a definição do número. |

**A ponte com a Orquestração.** No Lab 7, a Dag chama o `dbt build` por `BashOperator`, com o dbt num ambiente virtual do Python (virtualenv) criado na construção da imagem. Vamos ver o que acontece quando o dado quebra. Com itens duplicados, o dbt sai com código 1. Isso vira `AirflowException`, e a tarefa e a execução da Dag falham. Refeita a bronze, a mesma Dag volta ao sucesso.

> Verificação: nível 3. Executado em 2026-11-03, em Linux, com Airflow 3.3.2 (imagem `apache/airflow:3.3.2-python3.13`), `dbt-core` 1.12.6 e `dbt-postgres` 1.11.0, contra Postgres 16.15. Comando: `docker compose --profile orquestrador run --rm airflow-teste bash -c "airflow db migrate > /tmp/migrate.log 2>&1 && airflow dags test dbt_rede_de_lojas 2026-10-22"`. Três execuções em `lab/saidas/lab7_orquestrador_roda_dbt.txt`: `success`, `failed` (`ERROR=2`) e `success`.

**A ponte com a entrega.** Com camada semântica, o guia de marts do dbt muda a recomendação: em vez de tabela larga, o mart fica o mais normalizado possível. A terminologia do dbt descreve essa camada como motor de desnormalização (denormalization engine). Inferência: quando ela entrar, reabra a escolha do capítulo 9. Critério da mentoria: pergunta feita a uma IA pede a mesma definição do número do capítulo 18.

### 24.4 Engenheiro: o dbt v1 vai acabar?

"Fico no v1 ou já migro?"

**O que é.** A dbt Labs já anunciou qual será a última versão menor da linha 1.x (número no capítulo 16). O suporte crítico, de segurança e instalação, vai além da janela normal de um ano, sem data de corte definida e com expectativa de 3 a 5 anos. Ficar no v1 é caminho suportado ("remains fully supported"), mas recursos novos chegam só no v2.

**Como funciona na prática.** Para migrar, a documentação pede quatro coisas: resolver os avisos de depreciação, com o `dbt-autofix` para os que se corrigem automaticamente; testar o projeto com a flag opcional (opt-in) `--use-v2-parser`, na versão indicada no post das distribuições; ter adaptador e autenticação suportados; rodar na última versão do v1 sem avisos de depreciação nem erros. Não verificado: nada disso foi executado aqui.

Sem data de corte, a data precisa ser sua. Critério da mentoria: marque no calendário o dia de reabrir a decisão, com um dono. Nesse dia, responda:

1. O adaptador do seu banco é suportado no v2? Comece pelo capítulo 16.
2. O projeto roda na última versão do v1 sem aviso?
3. Que recurso novo faz falta hoje, com um exemplo?

Inferência: se a primeira resposta for não, a migração espera. Registre o motivo.

**O equívoco comum.** Ler "última versão menor" como fim do suporte. A fonte diz o contrário.

### 24.5 E o Data Vault?

"Devia ter visto Data Vault?" Não aprofundamos, de propósito. Data Vault é um padrão de modelagem para armazém corporativo, com hubs (chaves de negócio), links (relações) e satellites (atributos descritivos e histórico), que a Databricks coloca na silver do medalhão. A fonte é um post de fornecedor; o livro e o padrão de Linstedt não foram abertos.

### 24.6 O que guardar?

"Se eu esquecer tudo, o que fica?" Uma frase: antes do SQL, decida o que uma linha significa. Quando um termo travar no caminho, o capítulo seguinte tem a definição em uma frase.

---

[Índice](../README.md#capítulos) · [Anterior: 23. Erros comuns e como corrigir](23-erros-comuns-e-como-corrigir.md) · [Próximo: 25. Glossário](25-glossario.md)
