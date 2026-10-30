---
title: "11. Onde rodar e quanto custa: a decisão do gestor"
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

[Índice](../README.md#capítulos) · [Anterior: 10. Proteger a origem e guardar o que some](10-proteger-a-origem-e-guardar-o-que-some.md) · [Próximo: 12. Do script à Dag: o mesmo fluxo, muda quem roda](12-do-script-a-dag.md)

## 11. Onde rodar e quanto custa: a decisão do gestor

O gerente de TI do capítulo 1 começou à mão, e fez bem. Agora o número vai para a
diretoria todo dia, e a pergunta mudou: "se for Airflow, quanto custa por mês, e quem cuida?".
Vamos responder em três contas: fatura, horas de gente e risco de ciclo de vida.

### 11.1 Três formas de rodar

**O que é**

Onde rodar é decidir quem cuida da máquina, do banco de metadados e das atualizações: o seu
time, um fornecedor, ou um serviço que só cobra quando a tarefa roda.

**Como funciona na prática**

A documentação do Airflow lista o que fica com você em cada forma.

1. **Máquina própria.** Com a imagem Docker, o seu time monta a instalação, cuida do banco de
   metadados e do schema, monitora e dimensiona memória e CPU. O mínimo recomendado é 4 GB de
   memória; o guia do Docker Compose diz que o ideal é 8 GB.
2. **Serviço gerenciado.** O fornecedor cuida da máquina e do banco de metadados; o fluxo e a
   escolha da versão continuam com você (veja 11.3). A documentação descreve o público: quem
   prefere o Airflow gerenciado e aceita pagar por isso.
3. **Sem servidor (serverless).** O MWAA Serverless, da AWS, cobra pelo tempo de tarefa. Em
   troca, o fluxo é escrito em YAML com operadores da AWS, sem a interface do Airflow. Para
   operador próprio em Python, a AWS indica o ambiente provisionado.

**O equívoco comum**

"Máquina própria sai mais barato." Na fatura, sai mais barato que o gerenciado provisionado; o
sem servidor pode sair ainda mais barato quando o fluxo é curto e raro. A conta do gestor é
fatura mais horas de gente, e o gerenciado troca uma pela outra.

Cuidado também com o atalho. O Docker Compose oficial é para aprender e não dá garantia de
segurança de produção; para produção, a recomendação é Kubernetes com o pacote oficial (Helm
chart). SQLite nunca vai para produção. Num servidor Windows, o Airflow roda só por WSL2 ou
contêiner Linux, e produção só é suportada em Linux.

### 11.2 A tabela com número

"Me dá um número para a reunião." Aqui está, com as três formas no mesmo provedor. Preço de
tabela da AWS, em dólar, sem imposto nem desconto, consultado em 2026-10-29, num mês de 744
horas, e só o preço por hora do ambiente; outros itens da fatura não entram.

| Forma | Exemplo na AWS | Preço de tabela do ambiente no mês (744 h) | O que fica com o seu time | Limite que pesa |
|---|---|---|---|---|
| Máquina própria | 8 GB e 2 vCPU no Lightsail | cerca de US$ 44 | instalação, banco, atualização, recuperação, monitoramento | o Compose de aprender não serve para produção |
| Gerenciado | MWAA na menor classe (`mw1.micro`) | na casa de US$ 200 a US$ 400, conforme a região | o fluxo e a escolha de versão | até 25 Dags e 3 tarefas ao mesmo tempo, sem autoescala |
| Sem servidor | MWAA Serverless | na casa de US$ 0,08 a US$ 0,10 por hora de tarefa | o fluxo em YAML | sem interface; operador próprio pede o provisionado |

No gerenciado, a ponta de baixo é a Virgínia do Norte, a de cima é São Paulo. Na fatura, a
máquina própria custa cerca de cinco a oito vezes menos.

A coluna de gente não tem preço de tabela. Peça ao time a estimativa em horas por mês para
instalar, atualizar e recuperar a máquina. Se essas horas custam mais que a diferença na
fatura, o gerenciado sai mais barato.

Na geração 3, o Google cobra o gerenciado dele por capacidade: US$ 0,06 por DCU-hora em
us-central1. A DCU (Data Compute Unit) é uma unidade abstrata de medida dos recursos de
computação alocados ao ambiente. O total depende do tamanho do ambiente. Em qualquer provedor, confira
a página de preço no dia da apresentação.

**O equívoco comum**

"Sem servidor é sempre o mais barato." Ele cobra por uso, o que favorece fluxo curto e raro. Em
troca, você perde a interface. Se o time precisa dela para ver falha e histórico, a resposta é o
gerenciado provisionado ou a máquina própria.

### 11.3 Ciclo de vida: a versão que você compra

**O que é**

Ciclo de vida é até quando uma versão recebe correção. O gestor pergunta: "se pago gerenciado,
a versão é problema dele?". Em parte.

**Como funciona na prática**

<!-- reconferir este trecho, com data, na 3.4.0 antes de publicar -->
- **Projeto Apache:** a estável é a 3.3.2, de 2026-09-17. A 3.4.0 está em versão candidata,
  prevista para 2026-11-02. A linha 3 está em manutenção, sem data de fim. A linha 2 está em fim de vida desde 2026-04-22, sem correção nem suporte.
- **MWAA:** vai até a 3.3.1 e ainda oferece a 2.11.2, que chegou em julho de 2026, depois do fim
  de vida da linha 2. Só troca a versão menor, então sair do 2 para o 3 exige ambiente novo. Cada
  versão tem ao menos 12 meses de suporte, com aviso de 180 dias.
- **Google:** em 2026-04-15, anunciou que o Cloud Composer está se tornando o Managed Service for
  Apache Airflow. A imagem
  mais nova traz a 3.3.1; a padrão ainda é a 2.11.1.
- **Microsoft:** o Airflow do Azure Data Factory não cria instância nova desde 2026-01-01. O
  sucessor, no Fabric, suporta só a 2.10.5, sem rede privada.
- **Astronomer:** mantém a versão do Airflow 3.3 até julho de 2028, e a do 2.11 até abril de 2027.

**O equívoco comum**

"Gerenciado está sempre na versão nova." A padrão pode ser da linha que o projeto já encerrou, e
o produto pode mudar de nome ou parar de aceitar instância nova. Pergunte ao fornecedor: qual
versão, e até quando.

### 11.4 O que o gerente leva à diretoria

Quando a entrega vira recorrente, o gerente leva
três caminhos: máquina própria por cerca de US$ 44 por mês, mais as horas de quem mantém;
gerenciado menor da AWS na casa de US$ 200 a US$ 400, com menos horas de gente; sem servidor, se
o fluxo couber nos operadores da AWS. A decisão não é a ferramenta. É quem fica com a máquina, a
versão e o alerta.

**Quadro: perguntas para o seu time**

1. Se a carga de ontem rodar de novo agora, o resultado muda?
2. Quem recebe o aviso quando falha, e por qual canal?
3. Como reprocessamos a semana passada, e quanto tempo leva?
4. Onde fica o registro de cada carga: quando rodou, se foi agendada ou manual, quantas linhas?
5. Em que fuso está o horário que combinamos com a diretoria?
6. Temos um ambiente para testar antes de produção, e a Dag tem teste?
7. Qual a versão da ferramenta, e até quando ela tem suporte?
8. Se não for gerenciado, quem mantém a máquina, o banco de metadados e as atualizações?
9. O tratamento roda no banco, ou os dados passam por dentro do orquestrador?

Decidido onde roda, vamos ao código. O capítulo 12 leva o script à mão para uma Dag, sem mudar o SQL.

---

[Índice](../README.md#capítulos) · [Anterior: 10. Proteger a origem e guardar o que some](10-proteger-a-origem-e-guardar-o-que-some.md) · [Próximo: 12. Do script à Dag: o mesmo fluxo, muda quem roda](12-do-script-a-dag.md)
