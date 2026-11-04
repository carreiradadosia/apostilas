PRINT N'== Texto: TRIM, caixa e acento. O erro de digitação continua até o de-para.';
SELECT N'[' + categoria + N']' AS antes,
       N'[' + LOWER(silver.sem_acento(TRIM(categoria))) + N']' AS so_limpeza
FROM bronze.produtos_foto
WHERE _dia_referencia = (SELECT MIN(_dia_referencia) FROM bronze.produtos_foto)
ORDER BY id;
SELECT produto_id, nome, categoria FROM silver.produtos ORDER BY produto_id;

PRINT N'== Cidade: as duas grafias viram uma, ao custo do acento.';
SELECT l.id, N'[' + l.cidade + N']' AS antes, s.cidade AS depois
FROM bronze.lojas l JOIN silver.lojas s ON s.loja_id = l.id
ORDER BY l.id;

PRINT N'== Cliente: nulo e texto vazio caem no mesmo rótulo. Campo de texto pode ter rótulo.';
SELECT b.id, N'[' + b.cliente + N']' AS antes, s.cliente AS depois
FROM bronze.pedidos b JOIN silver.pedidos s ON s.pedido_id = b.id
WHERE b.id IN (101, 103, 105, 107, 110) AND (b.id <> 103 OR b.status = N'cancelado')
ORDER BY b.id;

PRINT N'== Status: CASE WHEN com ELSE. O nulo vira desconhecido e continua visível.';
SELECT b.id, N'[' + COALESCE(b.status, N'NULL') + N']' AS antes, s.status AS depois
FROM bronze.pedidos b JOIN silver.pedidos s ON s.pedido_id = b.id
WHERE b.id IN (101, 102, 107, 109)
ORDER BY b.id;
SELECT status, COUNT(*) AS pedidos, SUM(valor) AS valor
FROM silver.pedidos
GROUP BY status
ORDER BY status;

PRINT N'== CASE sem ELSE: o status novo vira NULL sem aviso nenhum.';
SELECT status_novo,
       CASE status_novo WHEN N'pago' THEN N'pago' WHEN N'cancelado' THEN N'cancelado' END AS sem_else,
       CASE status_novo WHEN N'pago' THEN N'pago' WHEN N'cancelado' THEN N'cancelado' ELSE N'desconhecido' END AS com_else
FROM (VALUES (N'pago'), (N'estornado')) AS t(status_novo);

PRINT N'== COALESCE com critério: custo nulo não é custo zero. A margem muda.';
SELECT p.produto_id, p.custo AS custo_silver,
       SUM(i.valor_item) AS venda,
       SUM(i.valor_item - i.quantidade * p.custo) AS margem_com_nulo,
       SUM(i.valor_item - i.quantidade * COALESCE(p.custo, 0)) AS margem_com_zero
FROM silver.itens i
JOIN silver.produtos p ON p.produto_id = i.produto_id
JOIN silver.pedidos o ON o.pedido_id = i.pedido_id
WHERE o.status = N'pago'
GROUP BY p.produto_id, p.custo
ORDER BY p.produto_id;
SELECT SUM(i.valor_item - i.quantidade * p.custo) AS margem_soma_ignora_nulo,
       SUM(i.valor_item - i.quantidade * COALESCE(p.custo, 0)) AS margem_com_zero,
       SUM(CASE WHEN p.custo IS NULL THEN 1 ELSE 0 END) AS itens_sem_custo
FROM silver.itens i
JOIN silver.produtos p ON p.produto_id = i.produto_id
JOIN silver.pedidos o ON o.pedido_id = i.pedido_id
WHERE o.status = N'pago';

PRINT N'== COALESCE para juntar duas colunas de data: atendido_em, senão criado_em.';
SELECT b.id, b.criado_em_utc, b.atendido_em_utc, s.inicio_local, s.sem_atendido_em
FROM bronze.atendimentos b JOIN silver.atendimentos s ON s.atendimento_id = b.id
ORDER BY b.id;

PRINT N'== Coluna redundante: valor_texto concorda com valor? Só então ela pode sair.';
SELECT COUNT(*) AS linhas,
       SUM(CASE WHEN TRY_CONVERT(numeric(12, 2), REPLACE(valor_texto, N',', N'.')) <> valor THEN 1 ELSE 0 END) AS divergentes
FROM bronze.pedidos;

PRINT N'== Duplicata: DISTINCT não resolve, porque as linhas não são iguais.';
SELECT COUNT(*) AS bronze,
       -- SELECT * on purpose: DISTINCT compares the whole row, and that is what this test shows.
       (SELECT COUNT(*) FROM (SELECT DISTINCT * FROM bronze.pedidos) d) AS com_distinct,
       (SELECT COUNT(*) FROM (SELECT DISTINCT id FROM bronze.pedidos) d) AS ids_distintos,
       (SELECT COUNT(*) FROM silver.pedidos) AS silver_row_number
FROM bronze.pedidos;
SELECT id, status, atualizado_em, CONVERT(char(10), _carregado_em AT TIME ZONE N'UTC', 23) AS carregado_utc
FROM bronze.pedidos
WHERE id = 103
ORDER BY _carregado_em;
SELECT pedido_id, status FROM silver.pedidos WHERE pedido_id = 103;
