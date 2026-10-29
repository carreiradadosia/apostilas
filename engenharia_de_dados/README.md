---
title: "Engenharia de Dados"
date: 2026-10-29
type: trilha
status: active
tags: [mentoria, trilha]
---

# Engenharia de Dados

> Arquivo gerado a partir do `trilha.yml`. Nao edite a mao: rode `gerar_trilha.py` novamente, senao a edicao se perde e o documento diverge.

9 de 21 modulos publicados.

A ordem abaixo e a recomendada. Ela nao e obrigacao de percurso: cada
mentorado tem um roteiro proprio, que seleciona e reordena modulos sem
alterar este repositorio.

## Fundamentos

| Modulo | Status | Lab |
|---|---|---|
| [Introdução à engenharia de dados e diagnóstico](fundamentos/introducao/) | publicado | nao |
| [SQL com foco em JOINs](fundamentos/sql/) | publicado | nao |
| [Fontes, arquitetura e contratos de dados](fundamentos/fontes-e-contratos/) | publicado | nao |

## Ambiente

| Modulo | Status | Lab |
|---|---|---|
| Docker e ambiente local | planejado | sim |
| [Cloud para dados](ambiente/cloud/) | publicado | nao |
| [Infraestrutura como código](ambiente/infraestrutura-como-codigo/) | publicado | sim |
| [Kubernetes para engenharia de dados](ambiente/kubernetes/) | publicado | sim |

## Armazenamento

| Modulo | Status | Lab |
|---|---|---|
| Object storage e data lake | planejado | sim |
| [Formatos de arquivo e tipos de tabela](armazenamento/formatos-e-tabelas/) | rascunho | nao |
| [Particionamento e performance de consultas](armazenamento/particionamento/) | publicado | sim |
| NoSQL, quando o relacional não serve | planejado | nao |

## Ingestão

| Modulo | Status | Lab |
|---|---|---|
| [Change Data Capture](ingestao/cdc/) | rascunho | sim |
| [Streaming com Apache Kafka](ingestao/kafka/) | publicado | sim |
| Ingestão com Airbyte | planejado | sim |
| Web scraping | planejado | sim |

## Processamento

| Modulo | Status | Lab |
|---|---|---|
| Processamento distribuído, Spark, PySpark e Databricks | planejado | sim |

## Modelagem e transformação

| Modulo | Status | Lab |
|---|---|---|
| [Transformação com dbt](modelagem/dbt/) | publicado | sim |

## Orquestração

| Modulo | Status | Lab |
|---|---|---|
| Fundamentos de orquestração | planejado | nao |
| [Orquestração com Apache Airflow](orquestracao/airflow/) | rascunho | sim |

## Qualidade e governança

| Modulo | Status | Lab |
|---|---|---|
| Governança, qualidade e LGPD | planejado | nao |

## Projeto

| Modulo | Status | Lab |
|---|---|---|
| Projeto de engenharia | planejado | capstone |

## Como usar

Cada modulo tem o proprio `README.md` com o que existe ali e como rodar.
Modulos com laboratorio trazem `lab.json`, o manifesto que registra o que
foi verificado, com qual comando e em que data.
