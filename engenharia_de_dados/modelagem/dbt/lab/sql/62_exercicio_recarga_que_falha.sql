-- Exercise input: a reload that breaks in the middle, the second insert sends text where a number belongs.
DELETE FROM silver.recarga_exemplo;
INSERT INTO silver.recarga_exemplo VALUES (1, 10.00);
INSERT INTO silver.recarga_exemplo VALUES (2, 'dez');
INSERT INTO silver.recarga_exemplo VALUES (3, 30.00);
