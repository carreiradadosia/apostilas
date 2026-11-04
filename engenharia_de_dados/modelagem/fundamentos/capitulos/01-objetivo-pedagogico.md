---
title: "1. Objetivo pedagógico"
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

[Índice](../README.md#capítulos) · [Anterior: 0. Como usar esta apostila](00-como-usar-esta-apostila.md) · [Próximo: 2. Contexto de negócio](02-contexto-de-negocio.md)

## 1. Objetivo pedagógico

"Sei o que quero, mas travo na hora de escrever o tratamento em SQL."

Essa é, com outras palavras, a trava do gerente de TI que a apostila de Orquestração apresentou: tratar em SQL o dado sujo. Seu cenário pode ser outro. Se a trava é a mesma, este caminho serve para você.

A Orquestração deixou uma ponte: o orquestrador não é o código de limpeza, é quem roda o código. Esta apostila é a desse código, e vai além da limpeza: chega à gold, onde o dado é juntado e agregado. A frase guia dela é esta.

**Antes do SQL, decida o que uma linha significa.**

### 1.1 O que você consegue fazer ao terminar

O que eu vou conseguir fazer sozinho? Oito coisas.

- **Declarar** o grão de uma tabela, o que uma linha significa, antes de escrever o SQL.
- **Escrever** a silver com critério: nulo, `CASE`, texto, data, fuso e duplicata.
- **Montar** uma estrela: fato de vendas ligada às dimensões de loja, produto e data.
- **Guardar** o histórico que a origem apaga, como o preço trocado de noite.
- **Testar** o grão e as chaves, com consultas que precisam voltar vazias.
- **Reproduzir** em dbt o fluxo que você já rodou à mão.
- **Descobrir** de onde vem um número que aparece num relatório.
- **Decidir** onde a regra mora e quando vale subir de degrau.

### 1.2 O objetivo é aprender dbt?

Não. O dbt entra como exemplo, depois do conceito. O projeto dbt completo é montado no capítulo 15. A ferramenta muda de versão. A decisão sobre o que uma linha significa continua sendo sua.

**O equívoco comum**

Achar que a dor da modelagem é falta de ferramenta. Na pesquisa de comunidade de Joe Reis, publicada em fevereiro de 2026, com 1.101 respostas de múltipla escolha, 11% marcaram "None / modeling is going well" (nenhuma, a modelagem vai bem). As dores mais citadas foram pressão por velocidade (59%), falta de dono claro (51%) e manutenção difícil (39%). A ferramenta apareceu em 19%.

Leitura da mentoria: é sinal, não medida do mercado. As respostas vêm da própria comunidade, e o post agradece a um fornecedor de ferramenta de modelagem pela parceria.

---

[Índice](../README.md#capítulos) · [Anterior: 0. Como usar esta apostila](00-como-usar-esta-apostila.md) · [Próximo: 2. Contexto de negócio](02-contexto-de-negocio.md)
