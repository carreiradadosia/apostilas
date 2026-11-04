-- Reset the table between attempts: three good rows that a failed reload must keep.
DROP TABLE IF EXISTS silver.recarga_demo;
CREATE TABLE silver.recarga_demo (pedido_id int PRIMARY KEY, valor numeric(12, 2) NOT NULL);
INSERT INTO silver.recarga_demo VALUES (1, 10.00), (2, 20.00), (3, 30.00);
GO
