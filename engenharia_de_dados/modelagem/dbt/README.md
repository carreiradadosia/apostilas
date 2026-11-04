---
title: "Laboratório de modelagem e transformação com dbt"
date: 2026-11-04
type: modulo
status: rascunho
tags: [modelagem, dbt, mentoria]
---

# Laboratório de modelagem e transformação com dbt

O laboratório dos Labs 0 a 9 da apostila de Fundamentos de modelagem e transformação: a rede de lojas
fictícia da camada bronze à gold, em SQL à mão e como projeto dbt, com o mesmo número nos dois lados,
testes que param a carga, o dbt numa Dag, a mesma silver em T-SQL e a busca pelo SQL que um relatório
roda.

## Estado

Status na trilha: **rascunho**, até a revisão do dono. Este é um módulo só de laboratório: não tem
apostila própria, porque o conceito é ensinado pela apostila do módulo `modelagem/fundamentos`, que
cita este laboratório no capítulo 20. A ordem recomendada vive em `trilha.yml`, na raiz da trilha.
Seu roteiro pode incluir este módulo em outra posição.

## O que tem aqui

- `lab/`, o laboratório: compose com Postgres 16.15, dbt em contêiner e Airflow só no Lab 7, o guia
  em `lab/README.md` e a saída real de cada Lab em `lab/saidas/`
- `lab/sqlserver/`, o Lab 8, e `lab/linhagem/`, o Lab 9, projetos à parte com licença a ler antes
  de subir
- `lab.json`, o manifesto de verificação: artefatos no nível 2 e Labs 0 a 9 no nível 3

## O que ainda não existe

Diretórios opcionais ausentes neste módulo, declarados aqui de propósito:

- `scripts/` ausente, os scripts do laboratório ficam dentro de `lab/`
- `exercicios/` ausente, os enunciados vivem na apostila de fundamentos, no capítulo 21
- `diagramas/` ausente

## Como rodar

A partir da raiz do repositório clonado:

```bash
cd engenharia_de_dados/modelagem/dbt/lab
cat README.md
```
