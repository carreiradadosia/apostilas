-- A reload that recreates the table and breaks in the middle: the second insert sends text where a number belongs.
DROP TABLE IF EXISTS silver.psql_erro_vendas;
CREATE TABLE silver.psql_erro_vendas (id integer, valor numeric);
INSERT INTO silver.psql_erro_vendas VALUES (1, 10.0);
INSERT INTO silver.psql_erro_vendas VALUES (2, 'dez');
INSERT INTO silver.psql_erro_vendas VALUES (3, 30.0);
