-- DELETE plus INSERT in one transaction and one batch, with a duplicate key in the middle.
BEGIN TRANSACTION;
DELETE FROM silver.recarga_demo;
INSERT INTO silver.recarga_demo VALUES (1, 11.00);
INSERT INTO silver.recarga_demo VALUES (1, 99.00);
INSERT INTO silver.recarga_demo VALUES (2, 22.00);
COMMIT;
GO
