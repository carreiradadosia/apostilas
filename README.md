# Apostilas da Carreira Dados

Apostilas das trilhas da mentoria Carreira Dados ([carreiradados.com.br](https://carreiradados.com.br)).
Cada trilha tem uma pasta, com as apostilas, os laboratórios e as referências de cada conceito.

Mantido por Iuri Zambotto e Paulo Shindi.

## Trilhas

| Pasta | Trilha | Estado |
|---|---|---|
| `engenharia_de_dados/` | Engenharia de Dados | conceito Orquestração publicado: a apostila de fundamentos e o laboratório com Apache Airflow; índice em `engenharia_de_dados/README.md` |

Aqui fica só o que está terminado. Os demais conceitos da trilha estão em revisão, e a versão
anterior deles continua no branch `rascunhos` deste repositório.

## Como usar

Cada trilha é organizada por conceito, e cada módulo vive em `<trilha>/<conceito>/<módulo>/`,
com o próprio `README.md`. A pasta `fundamentos/` de um conceito tem a apostila conceitual, em
`apostila.md` e também dividida em um arquivo por capítulo, na pasta `capitulos/`. As outras pastas
do conceito são ferramentas usadas como exemplo, como `orquestracao/airflow/`, que é o laboratório
da apostila de fundamentos.

O laboratório fica na pasta `lab/` do módulo, com o `lab.json` ao lado e o passo a passo para
rodar na sua máquina.

A ordem dos módulos é sugestão, não obrigação de percurso: cada mentorado tem um roteiro próprio.

## Origem

A trilha de Engenharia de Dados veio do repositório `carreiradadosia/mentorias` em 2026-10-29,
com o histórico de commits preservado.

## Direitos

Conteúdo público para leitura e estudo, com todos os direitos reservados: este repositório não
tem licença de reuso. Para reaproveitar um trecho em outro material, fale com a Carreira Dados
pelo site [carreiradados.com.br](https://carreiradados.com.br).
