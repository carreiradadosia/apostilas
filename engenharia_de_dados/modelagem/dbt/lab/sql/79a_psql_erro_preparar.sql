-- Yesterday's load: one row, id 0. Each case of the psql proof starts from this state.
DROP TABLE IF EXISTS silver.psql_erro_vendas;
CREATE TABLE silver.psql_erro_vendas (id integer, valor numeric);
INSERT INTO silver.psql_erro_vendas VALUES (0, 5.0);
