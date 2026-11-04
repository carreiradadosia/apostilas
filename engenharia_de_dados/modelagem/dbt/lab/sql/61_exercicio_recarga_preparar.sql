-- Exercise input: yesterday's load, one row, the state a failed reload must not destroy.
DROP TABLE IF EXISTS silver.recarga_exemplo;
CREATE TABLE silver.recarga_exemplo (id integer, valor numeric(12, 2));
INSERT INTO silver.recarga_exemplo VALUES (0, 5.00);
