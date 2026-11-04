-- Same reload, now with XACT_ABORT: the first run-time error ends the batch and rolls everything back.
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DELETE FROM silver.recarga_demo;
INSERT INTO silver.recarga_demo VALUES (1, 11.00);
INSERT INTO silver.recarga_demo VALUES (1, 99.00);
INSERT INTO silver.recarga_demo VALUES (2, 22.00);
COMMIT;
GO
