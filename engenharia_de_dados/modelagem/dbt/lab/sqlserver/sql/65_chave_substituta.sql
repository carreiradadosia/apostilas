PRINT N'== IDENTITY: o valor é consumido mesmo quando a transação volta. Buraco é normal.';
DROP TABLE IF EXISTS gold.dim_demo_identity;
CREATE TABLE gold.dim_demo_identity (produto_sk int IDENTITY(1, 1) PRIMARY KEY, produto_id int NOT NULL);
INSERT INTO gold.dim_demo_identity (produto_id) VALUES (10);
BEGIN TRANSACTION;
INSERT INTO gold.dim_demo_identity (produto_id) VALUES (20);
ROLLBACK;
INSERT INTO gold.dim_demo_identity (produto_id) VALUES (30);
SELECT produto_sk, produto_id FROM gold.dim_demo_identity ORDER BY produto_sk;
GO
PRINT N'== IDENTITY sem restrição não garante unicidade: reseed e o mesmo número sai de novo.';
DROP TABLE IF EXISTS gold.dim_sem_pk;
CREATE TABLE gold.dim_sem_pk (produto_sk int IDENTITY(1, 1), produto_id int NOT NULL);
INSERT INTO gold.dim_sem_pk (produto_id) VALUES (10);
DBCC CHECKIDENT ('gold.dim_sem_pk', RESEED, 0) WITH NO_INFOMSGS;
INSERT INTO gold.dim_sem_pk (produto_id) VALUES (20);
SELECT produto_sk, produto_id FROM gold.dim_sem_pk ORDER BY produto_id;
GO
PRINT N'== SEQUENCE: objeto próprio, compartilhável entre tabelas, também fora da transação.';
DROP TABLE IF EXISTS gold.dim_seq_a, gold.dim_seq_b;
DROP SEQUENCE IF EXISTS gold.seq_demo;
CREATE SEQUENCE gold.seq_demo AS int START WITH 1 INCREMENT BY 1;
CREATE TABLE gold.dim_seq_a (sk int NOT NULL DEFAULT NEXT VALUE FOR gold.seq_demo PRIMARY KEY, nome nvarchar(20));
CREATE TABLE gold.dim_seq_b (sk int NOT NULL DEFAULT NEXT VALUE FOR gold.seq_demo PRIMARY KEY, nome nvarchar(20));
INSERT INTO gold.dim_seq_a (nome) VALUES (N'a1');
INSERT INTO gold.dim_seq_b (nome) VALUES (N'b1');
BEGIN TRANSACTION;
INSERT INTO gold.dim_seq_a (nome) VALUES (N'a_volta');
ROLLBACK;
INSERT INTO gold.dim_seq_a (nome) VALUES (N'a2');
SELECT N'dim_seq_a' AS tabela, sk, nome FROM gold.dim_seq_a
UNION ALL SELECT N'dim_seq_b', sk, nome FROM gold.dim_seq_b
ORDER BY sk;
GO
PRINT N'== Truncar e recarregar com IDENTITY troca a chave se a ordem muda. A fato aponta para outro produto, sem erro.';
DROP TABLE IF EXISTS gold.dim_recarga, gold.fct_recarga;
CREATE TABLE gold.dim_recarga (produto_sk int IDENTITY(1, 1) PRIMARY KEY, produto_id int NOT NULL);
CREATE TABLE gold.fct_recarga (produto_sk int NOT NULL, quantidade int NOT NULL);
INSERT INTO gold.dim_recarga (produto_id) SELECT produto_id FROM silver.produtos ORDER BY produto_id;
INSERT INTO gold.fct_recarga (produto_sk, quantidade) SELECT produto_sk, 1 FROM gold.dim_recarga WHERE produto_id = 40;
SELECT N'antes' AS momento, f.produto_sk AS sk_na_fato, d.produto_id AS produto_que_a_chave_aponta
FROM gold.fct_recarga f JOIN gold.dim_recarga d ON d.produto_sk = f.produto_sk;
TRUNCATE TABLE gold.dim_recarga;
INSERT INTO gold.dim_recarga (produto_id) SELECT produto_id FROM silver.produtos ORDER BY produto_id DESC;
SELECT N'depois' AS momento, f.produto_sk AS sk_na_fato, d.produto_id AS produto_que_a_chave_aponta
FROM gold.fct_recarga f JOIN gold.dim_recarga d ON d.produto_sk = f.produto_sk;
GO
PRINT N'== IDENTITY estável: sem truncar, só entra o que falta. A chave do produto 40 não muda.';
DROP TABLE IF EXISTS gold.dim_incremental;
CREATE TABLE gold.dim_incremental (produto_sk int IDENTITY(1, 1) PRIMARY KEY, produto_id int NOT NULL UNIQUE);
INSERT INTO gold.dim_incremental (produto_id) SELECT produto_id FROM silver.produtos WHERE produto_id <> 30 ORDER BY produto_id DESC;
SELECT N'primeira carga' AS momento, produto_sk, produto_id FROM gold.dim_incremental WHERE produto_id = 40;
INSERT INTO gold.dim_incremental (produto_id)
SELECT s.produto_id FROM silver.produtos s
WHERE NOT EXISTS (SELECT 1 FROM gold.dim_incremental d WHERE d.produto_id = s.produto_id);
SELECT N'segunda carga' AS momento, produto_sk, produto_id FROM gold.dim_incremental WHERE produto_id IN (30, 40) ORDER BY produto_id;
GO
PRINT N'== Hash no mesmo teste: truncar e recarregar em outra ordem não muda a chave. É a escolha do laboratório, ao custo de 64 caracteres por chave.';
DROP TABLE IF EXISTS gold.dim_recarga_hash, gold.fct_recarga_hash;
CREATE TABLE gold.dim_recarga_hash (produto_sk char(64) PRIMARY KEY, produto_id int NOT NULL);
CREATE TABLE gold.fct_recarga_hash (produto_sk char(64) NOT NULL, quantidade int NOT NULL);
INSERT INTO gold.dim_recarga_hash (produto_sk, produto_id)
SELECT CONVERT(char(64), HASHBYTES('SHA2_256', CONVERT(varchar(20), produto_id)), 2), produto_id FROM silver.produtos ORDER BY produto_id;
INSERT INTO gold.fct_recarga_hash (produto_sk, quantidade) SELECT produto_sk, 1 FROM gold.dim_recarga_hash WHERE produto_id = 40;
TRUNCATE TABLE gold.dim_recarga_hash;
INSERT INTO gold.dim_recarga_hash (produto_sk, produto_id)
SELECT CONVERT(char(64), HASHBYTES('SHA2_256', CONVERT(varchar(20), produto_id)), 2), produto_id FROM silver.produtos ORDER BY produto_id DESC;
SELECT N'depois' AS momento, d.produto_id AS produto_que_a_chave_aponta
FROM gold.fct_recarga_hash f JOIN gold.dim_recarga_hash d ON d.produto_sk = f.produto_sk;
GO
PRINT N'== HASHBYTES: varchar e nvarchar dão hashes diferentes, porque os bytes são diferentes.';
SELECT CONVERT(char(32), HASHBYTES('MD5', '1'), 2) AS md5_varchar,
       CONVERT(char(32), HASHBYTES('MD5', N'1'), 2) AS md5_nvarchar,
       CONVERT(char(64), HASHBYTES('SHA2_256', '1'), 2) AS sha2_256_varchar;
GO
PRINT N'== MD5 roda sem erro e sem aviso. A doc fala em evento de recurso preterido; este é o contador de mesmo nome, lido antes e depois.';
CREATE TABLE #contador (valor bigint NOT NULL);
INSERT INTO #contador (valor)
SELECT cntr_value FROM sys.dm_os_performance_counters
WHERE object_name LIKE N'%Deprecated Features%' AND RTRIM(instance_name) = N'Deprecated hash algorithm';
GO
SELECT CONVERT(char(32), HASHBYTES('MD5', 'contador de recurso preterido'), 2) AS md5_em_lote_proprio;
GO
SELECT N'Deprecated hash algorithm' AS contador,
       (SELECT cntr_value FROM sys.dm_os_performance_counters
        WHERE object_name LIKE N'%Deprecated Features%' AND RTRIM(instance_name) = N'Deprecated hash algorithm')
       - (SELECT valor FROM #contador) AS aumento;
DROP TABLE #contador;
GO
PRINT N'== CONCAT troca NULL por vazio: sem separador, chaves diferentes colidem; com separador, não.';
SELECT CONCAT(1, NULL, 23) AS sem_sep_a, CONCAT(12, NULL, 3) AS sem_sep_b,
       CONCAT(1, '-', NULL, '-', 23) AS com_sep_a, CONCAT(12, '-', NULL, '-', 3) AS com_sep_b,
       N'a' + NULL AS operador_mais_com_nulo,
       CONVERT(char(64), HASHBYTES('SHA2_256', CAST(NULL AS varchar(10))), 2) AS hash_de_nulo;
GO
