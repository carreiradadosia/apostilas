---
title: "1. Objetivo pedagógico"
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

[Índice](../README.md#capítulos) · [Anterior: 0. Como usar esta apostila](00-como-usar-esta-apostila.md) · [Próximo: 2. Contexto de negócio](02-contexto-de-negocio.md)

## 1. Objetivo pedagógico

"Pesquisei com IA como montar meus dados. Recebi uma lista de ferramentas e arquiteturas. Por onde eu começo?"

Essa pergunta veio de um gerente de TI que montava a primeira arquitetura de dados da empresa. A lista não estava errada. Mesmo assim, ele travou. Ferramenta sem conceito não ajuda a decidir.

O que destravou foi conceito em degraus, um de cada vez, com uma ferramenta só como exemplo. Esta apostila segue esse caminho.

**O que você consegue fazer ao terminar**

- **Decidir** se uma carga fica à mão, vai para um agendador ou pede um orquestrador, com custo e risco de cada opção.
- **Separar** o código que trata o dado de quem roda esse código.
- **Desenhar** um fluxo de carga como Dag: o grafo dos passos, com ordem e dependência.
- **Tornar** uma carga segura para rodar de novo, sem duplicar linha.
- **Reprocessar** dias que já passaram, sabendo que intervalo cada execução cobre.
- **Detectar** quando uma carga falhou ou terminou sem trazer dado, antes da diretoria.
- **Perguntar** ao time o que importa antes de contratar: onde roda, quanto custa, quem mantém.

**O equívoco comum**

Achar que o objetivo é aprender uma ferramenta. A ferramenta muda de versão. O critério de decisão continua valendo.

---

[Índice](../README.md#capítulos) · [Anterior: 0. Como usar esta apostila](00-como-usar-esta-apostila.md) · [Próximo: 2. Contexto de negócio](02-contexto-de-negocio.md)
