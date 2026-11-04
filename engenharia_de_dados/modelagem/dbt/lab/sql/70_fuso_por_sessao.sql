-- The same expressions in two session time zones, and a typed literal that drops its offset. Run after Lab 1.
\pset border 1

\echo == dia_local do atendimento 2, recalculado da bronze com a expressão da silver, em duas sessões.
SET TIME ZONE 'UTC';
SELECT current_setting('TimeZone') AS sessao, id, criado_em_utc,
       (criado_em_utc AT TIME ZONE 'UTC' AT TIME ZONE 'America/Sao_Paulo')::date AS dia_local
FROM bronze.atendimentos WHERE id = 2;
SET TIME ZONE 'America/Sao_Paulo';
SELECT current_setting('TimeZone') AS sessao, id, criado_em_utc,
       (criado_em_utc AT TIME ZONE 'UTC' AT TIME ZONE 'America/Sao_Paulo')::date AS dia_local
FROM bronze.atendimentos WHERE id = 2;

\echo == A direção errada nas duas sessões: o mesmo instante aparece de dois jeitos na tela.
SET TIME ZONE 'UTC';
SELECT current_setting('TimeZone') AS sessao,
       x AT TIME ZONE 'UTC' AT TIME ZONE 'America/Sao_Paulo' AS certo,
       x AT TIME ZONE 'America/Sao_Paulo' AS direcao_errada
FROM (VALUES (TIMESTAMP '2026-10-21 00:30')) AS t(x);
SET TIME ZONE 'America/Sao_Paulo';
SELECT current_setting('TimeZone') AS sessao,
       x AT TIME ZONE 'UTC' AT TIME ZONE 'America/Sao_Paulo' AS certo,
       x AT TIME ZONE 'America/Sao_Paulo' AS direcao_errada
FROM (VALUES (TIMESTAMP '2026-10-21 00:30')) AS t(x);

\echo == Literal com deslocamento: o tipo sem fuso ignora o -03; o timestamptz converte e não guarda o fuso informado.
SET TIME ZONE 'UTC';
SELECT TIMESTAMP '2026-10-21 00:30:00-03' AS timestamp_sem_fuso,
       TIMESTAMPTZ '2026-10-21 00:30:00-03' AS timestamptz_em_sessao_utc;
RESET TIME ZONE;
