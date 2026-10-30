---
title: "0. Como usar esta apostila"
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

[Índice](../README.md#capítulos) · [Próximo: 1. Objetivo pedagógico](01-objetivo-pedagogico.md)

## 0. Como usar esta apostila

Por onde começar, se você não tem tempo de ler tudo? Pelo seu objetivo. Cada perfil de mentorado
tem um caminho curto, e nem todo caminho passa pelo laboratório.

**Leitura linear ou revisão pontual**

Na primeira vez, leia em ordem: cada capítulo usa o vocabulário do anterior. Para revisar, vá
direto pelo sumário. Termo novo tem definição de uma frase no glossário (18).

**Roteiro por perfil**

| Se você | Leia |
|---|---|
| quer só entender do que se trata | 3 e o começo do 4 |
| gerencia e quer decidir | 2, 4 e 11, com as perguntas para o seu time no fim do 11 |
| está começando na área | do 1 ao 13, em ordem, e o exercício prático do 14 |
| já trabalha com dados e quer migrar para engenharia | 5 a 10, 12, 13 e 14 |
| já é engenheiro e mira o próximo nível | 6 a 11 e 17 |

Quem vai montar segue até o laboratório. Quem decide não precisa instalar nada. Se hoje você roda
tudo à mão, está num bom ponto de partida: o capítulo 4 mostra quando vale automatizar.

**Versão de referência**

O exemplo é o Apache Airflow 3.3.2, estável desde 2026-09-17, na imagem
`apache/airflow:3.3.2-python3.13`. A linha 2 está em fim de vida desde 2026-04-22 e não recebe
mais correção. Achou tutorial antigo? Confira a versão antes de copiar.

**O que você precisa ter**

- Para ler: SQL básico, de ler e escrever um SELECT.
- Para o laboratório: Linux ou Windows com WSL2, nas combinações testadas que o capítulo 13
  lista; Docker com Compose 2.14.0 ou mais novo; 4 GB de memória para o Docker, sendo 8 GB o
  ideal segundo a documentação do Airflow; e espaço livre no disco físico. O arquivo oficial do
  Airflow para o Compose, no serviço de inicialização, avisa sem bloquear quando há menos de 10 GB
  de disco livre, 4000 MiB de memória ou 2 CPUs. Use os 10 GB de disco como piso.

O laboratório da mentoria usa um arquivo mais leve, sem essa checagem. Confira você, no Linux ou
no terminal do WSL:

```bash
docker compose version
numfmt --to=iec $(docker info --format '{{.MemTotal}}')
```

Nível 3, executado em 2026-10-29 num Linux com Docker 28.3.3 e GNU coreutils 9.4. Saída:
`Docker Compose version v2.39.1` e `31G`. A sua será outra. Vale o Compose 2.14.0 ou mais novo.
A memória sai em GiB, potência de 1024, e num Windows de 8 GB o WSL entrega cerca de 4 GB à VM
por padrão, então um valor um pouco abaixo de 4G é esperado. Perto de 4G já é suficiente para o
laboratório leve, que usou entre 1,1 e 1,3 GiB no teste; o compose oficial pode avisar abaixo
disso.

**O equívoco comum: medir o disco errado**

No Windows, o `df` de dentro do WSL mostra o tamanho máximo do disco virtual, não o que sobra no
disco físico. O disco virtual é o arquivo `ext4.vhdx`, em geral no C:. Na máquina de teste da
mentoria, o `df` mostrava cerca de 205 GiB livres com o C: em pouco mais de 2 GB. Confira no
PowerShell:

```powershell
Get-PSDrive C | Select-Object Free
```

Nível 3, executado em 2026-10-29 no Windows 11 (versão 10.0.26200) com WSL 2.7.13.0. A saída vem
em bytes. Se o WSL ou o Docker Desktop morar em outro disco, confira esse disco.

---

[Índice](../README.md#capítulos) · [Próximo: 1. Objetivo pedagógico](01-objetivo-pedagogico.md)
