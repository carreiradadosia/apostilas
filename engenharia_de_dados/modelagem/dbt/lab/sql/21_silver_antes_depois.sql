\pset border 1
\echo == Texto: TRIM, caixa e acento. O erro de digitação continua até o de-para.
SELECT '[' || categoria || ']' AS antes,
       '[' || lower(unaccent(trim(categoria))) || ']' AS so_limpeza
FROM bronze.produtos_foto
WHERE _dia_referencia = (SELECT min(_dia_referencia) FROM bronze.produtos_foto) ORDER BY id;
SELECT produto_id, nome, categoria FROM silver.produtos ORDER BY produto_id;

\echo == Cidade: as duas grafias viram uma, ao custo do acento.
SELECT l.id, '[' || l.cidade || ']' AS antes, s.cidade AS depois
FROM bronze.lojas l JOIN silver.lojas s ON s.loja_id = l.id ORDER BY l.id;

\echo == Cliente: nulo e texto vazio caem no mesmo rótulo. Campo de texto pode ter rótulo.
SELECT b.id, '[' || b.cliente || ']' AS antes, s.cliente AS depois
FROM bronze.pedidos b JOIN silver.pedidos s ON s.pedido_id = b.id
WHERE b.id IN (101, 103, 105, 107, 110) AND (b.id <> 103 OR b.status = 'cancelado') ORDER BY b.id;

\echo == Status: CASE WHEN com ELSE. O nulo vira desconhecido e continua visível.
SELECT b.id, '[' || COALESCE(b.status, 'NULL') || ']' AS antes, s.status AS depois
FROM bronze.pedidos b JOIN silver.pedidos s ON s.pedido_id = b.id
WHERE b.id IN (101, 102, 107, 109) ORDER BY b.id;
SELECT status, count(*) AS pedidos, sum(valor) AS valor FROM silver.pedidos GROUP BY 1 ORDER BY 1;

\echo == CASE sem ELSE: o status novo vira NULL sem aviso nenhum.
SELECT status_novo,
       CASE status_novo WHEN 'pago' THEN 'pago' WHEN 'cancelado' THEN 'cancelado' END AS sem_else,
       CASE status_novo WHEN 'pago' THEN 'pago' WHEN 'cancelado' THEN 'cancelado' ELSE 'desconhecido' END AS com_else
FROM (VALUES ('pago'), ('estornado')) AS t(status_novo);

\echo == COALESCE com critério: custo nulo não é custo zero. A margem muda.
SELECT p.produto_id, p.custo AS custo_silver,
       sum(i.valor_item) AS venda,
       sum(i.valor_item - i.quantidade * p.custo) AS margem_com_nulo,
       sum(i.valor_item - i.quantidade * COALESCE(p.custo, 0)) AS margem_com_zero
FROM silver.itens i JOIN silver.produtos p USING (produto_id)
JOIN silver.pedidos o USING (pedido_id)
WHERE o.status = 'pago' GROUP BY 1, 2 ORDER BY 1;
SELECT sum(i.valor_item - i.quantidade * p.custo) AS margem_soma_ignora_nulo,
       sum(i.valor_item - i.quantidade * COALESCE(p.custo, 0)) AS margem_com_zero,
       count(*) FILTER (WHERE p.custo IS NULL) AS itens_sem_custo
FROM silver.itens i JOIN silver.produtos p USING (produto_id)
JOIN silver.pedidos o USING (pedido_id) WHERE o.status = 'pago';

\echo == COALESCE para juntar duas colunas de data: atendido_em, senão criado_em.
SELECT b.id, b.criado_em_utc, b.atendido_em_utc, s.inicio_local, s.sem_atendido_em
FROM bronze.atendimentos b JOIN silver.atendimentos s ON s.atendimento_id = b.id ORDER BY b.id;

\echo == Coluna redundante: valor_texto concorda com valor? Só então ela pode sair.
SELECT count(*) AS linhas,
       count(*) FILTER (WHERE replace(valor_texto, ',', '.')::numeric <> valor) AS divergentes
FROM bronze.pedidos;

\echo == Duplicata: DISTINCT não resolve, porque as linhas não são iguais.
SELECT count(*) AS bronze, (SELECT count(*) FROM (SELECT DISTINCT * FROM bronze.pedidos) d) AS com_distinct,
       (SELECT count(*) FROM (SELECT DISTINCT id FROM bronze.pedidos) d) AS ids_distintos,
       (SELECT count(*) FROM silver.pedidos) AS silver_row_number
FROM bronze.pedidos;
SELECT id, status, atualizado_em, to_char(_carregado_em AT TIME ZONE 'UTC', 'YYYY-MM-DD') AS carregado_utc
FROM bronze.pedidos WHERE id = 103 ORDER BY _carregado_em;
SELECT pedido_id, status FROM silver.pedidos WHERE pedido_id = 103;
