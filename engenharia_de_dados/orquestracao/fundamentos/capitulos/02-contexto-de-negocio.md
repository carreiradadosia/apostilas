---
title: "2. Contexto de negócio"
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

[Índice](../README.md#capítulos) · [Anterior: 1. Objetivo pedagógico](01-objetivo-pedagogico.md) · [Próximo: 3. O que é orquestrar, e o que não é](03-o-que-e-orquestrar-e-o-que-nao-e.md)

## 2. Contexto de negócio

"Como eu garanto que o número da diretoria chega todo dia, certo? E como sei quando ele não chegou?"

A apostila inteira responde a essa pergunta. Vamos responder acompanhando uma empresa fictícia.

**A rede de lojas**

O fio condutor é uma rede de lojas fictícia, com dados sintéticos. Ela tem quatro peças.

| Peça | O que é | No laboratório |
|---|---|---|
| ERP | Sistema que registra cada pedido | Banco `erp`, tabela `pedidos` |
| Réplica só leitura | Cópia do banco do ERP que aceita consulta e não aceita escrita | Simulada por um papel que só tem GRANT de SELECT no banco `erp`; o banco `dw` lê essa réplica por `postgres_fdw` |
| Armazém | Camadas bronze, silver e gold, tratadas em SQL | Banco `dw` |
| BI | Painel da diretoria, hoje alimentado por planilha | Fora do laboratório |

(Montagem executada no nível 3 em ambiente descartável, com Airflow 3.3.2 e PostgreSQL 16.15, em
2026-10-29.)

**Por que a réplica vem antes de tudo**

Nesta rede, o ERP trava tabela quando alguém consulta direto na produção: um relatório pesado segura quem está registrando pedido. Por isso o primeiro passo não é ferramenta de dados. É a réplica.

No PostgreSQL, uma réplica em espera ativa (hot standby) só aceita leitura; nem tabela temporária pode ser gravada nela. No SQL Server, a réplica legível do Always On trata toda consulta com isolamento por instantâneo (snapshot), o que elimina a disputa entre quem lê e quem escreve.

Se você decide a compra, confira a edição antes de prometer. O grupo de disponibilidade básico, da edição Standard, não permite leitura na réplica secundária. A réplica legível é recurso do grupo completo, da edição Enterprise.

**Bronze, silver e gold**

Da réplica, o dado passa por três camadas. Bronze guarda o dado cru, como chegou. Silver guarda o dado validado. Gold guarda o dado enriquecido, pronto para o negócio.

A documentação da Databricks chama esse desenho de arquitetura medalhão. Segui-lo é prática recomendada, não requisito.

O tratamento de cada camada é SQL dentro do banco. Quem roda esse SQL na ordem certa, e guarda o que aconteceu, é o assunto desta apostila.

**Duas frequências, um teto**

Um setor quer o número duas vezes por dia. Outro quer várias vezes por hora. A diretoria vai receber o número todo dia.

A atualização agendada do Power BI permite oito por dia na capacidade compartilhada. Duas por dia cabem com folga. Em Premium, PPU ou Fabric, o teto sobe para até 48 por dia, o que dá uma a cada meia hora. Várias por hora passam desse teto. E fonte local, como um ERP na rede da empresa, exige gateway.

É o primeiro sinal de que o horário do BI não resolve tudo.

**Começar à mão é uma decisão válida**

Na mentoria, o gerente de TI do capítulo 1 decidiu rodar tudo à mão no começo e automatizar quando a entrega à diretoria virasse recorrente. Os mentores concordaram. A rede fictícia segue o mesmo caminho.

À mão, você descobre de onde vem cada número e valida o SQL. Automatizar um SQL ainda errado só repete o erro mais vezes.

A hora de subir de degrau é critério da mentoria, não norma de mercado. Os sinais: a frequência aumenta, os passos se multiplicam, você precisa de alerta e de nova tentativa (retry), a entrega vira compromisso. O capítulo 4 detalha cada um.

**O equívoco comum**

Achar que começar à mão é atraso. O risco está em automatizar antes de saber o que o número significa.

Antes de escolher degrau, vale separar o que é orquestração do que não é. É o próximo capítulo.

---

[Índice](../README.md#capítulos) · [Anterior: 1. Objetivo pedagógico](01-objetivo-pedagogico.md) · [Próximo: 3. O que é orquestrar, e o que não é](03-o-que-e-orquestrar-e-o-que-nao-e.md)
