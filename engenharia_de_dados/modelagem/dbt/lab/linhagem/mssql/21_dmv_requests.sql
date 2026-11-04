-- What is running right now, in other sessions. Only identity and text, no timing column.
SET NOCOUNT ON;
SELECT s.program_name AS aplicacao, s.login_name AS login, r.command AS comando, r.status,
       OBJECT_NAME(st.objectid, st.dbid) AS objeto,
       CAST(LEFT(REPLACE(REPLACE(SUBSTRING(st.text, r.statement_start_offset / 2 + 1,
            (CASE r.statement_end_offset WHEN -1 THEN DATALENGTH(st.text) ELSE r.statement_end_offset END
             - r.statement_start_offset) / 2 + 1), CHAR(10), ' '), CHAR(13), ' '), 120) AS nvarchar(120)) AS comando_atual
FROM sys.dm_exec_requests AS r
JOIN sys.dm_exec_sessions AS s ON s.session_id = r.session_id
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS st
WHERE r.session_id <> @@SPID AND s.is_user_process = 1;
GO
