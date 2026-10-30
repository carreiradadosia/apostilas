---
title: "17. Plano de continuidade"
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

[Índice](../README.md#capítulos) · [Anterior: 16. Erros comuns e como corrigir](16-erros-comuns-e-como-corrigir.md) · [Próximo: 18. Glossário](18-glossario.md)

## 17. Plano de continuidade

"Terminei. E agora, estudo o quê?" O plano de continuidade é o próximo passo de cada perfil, ligado ao que vem depois na trilha.

### 17.1 O próximo passo por perfil

| Se você | Próximo passo |
|---|---|
| quer só entender do que se trata | Guarde a frase guia: o orquestrador não é o código de limpeza, é quem roda o código. |
| gerencia e quer decidir | Leve ao time as perguntas do capítulo 11. |
| está começando na área | Refaça o laboratório sozinho. Se o medo é o SQL da silver, isso é Modelagem e transformação. |
| já trabalha com dados | Aprofunde o Airflow no laboratório desta apostila e, depois, no módulo da trilha dedicado a ele. Se o que falta é o SQL da silver, isso é Modelagem e transformação. |
| é engenheiro e mira o próximo nível | Produção e a versão 3.4, na seção 17.3. |

Para quem está começando: se o laboratório não subiu, volte à preparação do ambiente, no capítulo 13, antes de seguir. No Windows, o pré-requisito é espaço livre no disco físico onde mora o WSL ou o Docker Desktop, em geral o C:, e não o que o `df` do Linux mostra.

### 17.2 O medo da silver é assunto de Modelagem e transformação

"E o SQL da silver, quem me ensina?" O gerente de TI do nosso caso tinha esse medo: nulos, colunas redundantes, datas, fuso, histórico do preço. Nada disso é orquestração. A Dag roda esse SQL na ordem, com a nova tentativa e o alerta que você configurar. Escrever o SQL, isso é Modelagem e transformação.

Guardar cada versão do preço, com início e fim de vigência, é a técnica chamada SCD tipo 2; o snapshot do dbt a implementa com `dbt_valid_from` e `dbt_valid_to`. Cabe à orquestração rodar a foto todo dia, no horário e no fuso certos, com alerta, porque o que mudou entre duas fotos não volta. O CDC, que lê o log do banco, é assunto de ingestão, não de orquestração.

O equívoco comum é achar que precisa dominar a silver antes de orquestrar. Escreva o SQL à mão. Quando a entrega virar recorrente, ele entra na Dag.

### 17.3 Para o engenheiro: produção e a versão 3.4

"O laboratório vai para produção?" Não. O compose oficial serve para aprender, sem garantias de segurança de produção. Para produção, a documentação recomenda Kubernetes com o pacote oficial de instalação, o Helm chart.

A 3.4.0 está em versão candidata (release candidate) desde 2026-10-28, prevista para 2026-11-02. O que muda:

- Exige Python 3.11 ou mais. No Ubuntu 22.04, o `python3` padrão é o 3.10.6. Quem instala por pip ou uv num 22.04 sem trocar o Python fica na 3.3; pelo Docker, como no laboratório, o problema não existe.
- O psycopg3 vira o driver padrão do banco de metadados; o compose oficial troca `postgresql+psycopg2` por `postgresql+psycopg`. O `docker-compose.yaml` do laboratório (imagem 3.3.2) usa psycopg2. Por isso o compose tem de ser da mesma versão da imagem: ao subir para a 3.4, troque os dois juntos. Não verificado: o laboratório não foi testado na 3.4.
- Dag disparada por um dado (asset) cria uma execução por evento; `batch_asset_events=True` mantém o lote.
- Chega, experimental, a escrita da Dag inteira fora do Python, em TypeScript, Go, Java e YAML nativo; tarefas em Java e Go já existiam, experimentais, desde a 3.3.

O equívoco comum é trocar a tag da imagem e descobrir a mudança em produção. Leia as notas, teste num ambiente descartável e leve ao time a data da troca.

---

[Índice](../README.md#capítulos) · [Anterior: 16. Erros comuns e como corrigir](16-erros-comuns-e-como-corrigir.md) · [Próximo: 18. Glossário](18-glossario.md)
