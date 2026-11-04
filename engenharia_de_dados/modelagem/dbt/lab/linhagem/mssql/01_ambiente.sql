SET NOCOUNT ON;
SELECT CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(30)) AS versao,
       CAST(SERVERPROPERTY('ProductUpdateLevel') AS nvarchar(10)) AS cu,
       CAST(SERVERPROPERTY('ProductUpdateReference') AS nvarchar(20)) AS kb,
       CAST(SERVERPROPERTY('Edition') AS nvarchar(60)) AS edicao;
GO
-- Query Store state on a database created with no option at all.
USE rede;
SELECT actual_state_desc, desired_state_desc, query_capture_mode_desc, size_based_cleanup_mode_desc,
       max_storage_size_mb, flush_interval_seconds, interval_length_minutes, stale_query_threshold_days
FROM sys.database_query_store_options;
GO
