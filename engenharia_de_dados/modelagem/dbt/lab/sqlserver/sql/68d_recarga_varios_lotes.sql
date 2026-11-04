-- XACT_ABORT with several batches and no -b: the failing batch rolls back, and the next one runs outside any transaction.
PRINT N'== Vários lotes, com XACT_ABORT ON e sem -b.';
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DELETE FROM silver.recarga_demo;
INSERT INTO silver.recarga_demo VALUES (1, 11.00);
GO
INSERT INTO silver.recarga_demo VALUES (1, 99.00);
GO
INSERT INTO silver.recarga_demo VALUES (4, 44.00);
COMMIT;
GO
