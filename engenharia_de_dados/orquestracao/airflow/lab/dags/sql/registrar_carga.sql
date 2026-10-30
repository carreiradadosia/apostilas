-- Load log: who ran it, which day, how many rows reached each layer.
INSERT INTO controle.carga (executor, dia_referencia, linhas_bronze, linhas_silver, receita_paga)
SELECT
    %(executor)s,
    %(dia)s::date,
    (SELECT count(*) FROM bronze.pedidos WHERE _dia_referencia = %(dia)s::date),
    (SELECT count(*) FROM silver.pedidos WHERE dia_local = %(dia)s::date),
    (SELECT receita_paga FROM gold.vendas_por_dia WHERE dia = %(dia)s::date);
