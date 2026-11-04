\pset border 1
\echo == O atendimento da meia-noite. Loja fecha às 22h; a origem grava UTC em coluna sem fuso.
SELECT b.id, l.nome AS loja, l.fecha_as,
       b.criado_em_utc AS lido_como_esta,
       b.criado_em_utc AT TIME ZONE 'UTC' AT TIME ZONE 'America/Sao_Paulo' AS certo
FROM bronze.atendimentos b JOIN silver.lojas l ON l.loja_id = b.loja_id ORDER BY b.id;

\echo == Por dia: o relatório muda de dia.
SELECT criado_em_utc::date AS dia_lido_como_esta, count(*) FROM bronze.atendimentos GROUP BY 1 ORDER BY 1;
SELECT dia_local, count(*) FROM silver.atendimentos GROUP BY 1 ORDER BY 1;

\echo == Direção errada e conversão dupla, com o mesmo valor de origem.
SET TIME ZONE 'UTC';
SELECT x AS origem_utc,
       x AT TIME ZONE 'UTC' AT TIME ZONE 'America/Sao_Paulo' AS certo,
       x AT TIME ZONE 'America/Sao_Paulo' AS direcao_errada_em_timestamptz,
       (x AT TIME ZONE 'UTC' AT TIME ZONE 'America/Sao_Paulo') AT TIME ZONE 'UTC' AT TIME ZONE 'America/Sao_Paulo' AS convertido_duas_vezes
FROM (VALUES (TIMESTAMP '2026-10-21 00:30')) AS t(x);

\echo == timestamptz: o mesmo instante, dois dias, conforme o fuso da sessão.
SET TIME ZONE 'UTC';
SELECT TIMESTAMPTZ '2026-10-21 00:30+00' AS instante, (TIMESTAMPTZ '2026-10-21 00:30+00')::date AS dia;
SET TIME ZONE 'America/Sao_Paulo';
SELECT TIMESTAMPTZ '2026-10-21 00:30+00' AS instante, (TIMESTAMPTZ '2026-10-21 00:30+00')::date AS dia;
SET TIME ZONE 'UTC';

\echo == Nome de fuso contra deslocamento fixo: em 2018 havia horário de verão, em 2026 não.
SELECT x AS utc,
       x AT TIME ZONE 'UTC' AT TIME ZONE 'America/Sao_Paulo' AS por_nome,
       x - interval '3 hours' AS menos_3_fixo
FROM (VALUES (TIMESTAMP '2018-12-01 12:00'), (TIMESTAMP '2019-12-01 12:00'), (TIMESTAMP '2026-12-01 12:00')) AS t(x);

\echo == Armadilha do sinal: em texto, '-03' é fuso a leste de Greenwich.
SELECT TIMESTAMP '2026-10-21 00:30' AT TIME ZONE 'UTC' AT TIME ZONE '-03' AS texto_menos_3,
       TIMESTAMP '2026-10-21 00:30' AT TIME ZONE 'UTC' AT TIME ZONE '+03' AS texto_mais_3,
       TIMESTAMP '2026-10-21 00:30' AT TIME ZONE 'UTC' AT TIME ZONE interval '-03:00' AS intervalo_menos_3;

\echo == Regra vigente segundo o tzdata da imagem.
SELECT name, abbrev, utc_offset, is_dst FROM pg_timezone_names WHERE name = 'America/Sao_Paulo';

\echo == Data em texto: a data impossível para a carga inteira.
SELECT to_date('20/10/2026', 'DD/MM/YYYY') AS boa;
SELECT to_date('31/02/2026', 'DD/MM/YYYY') AS impossivel;
\echo == Data como número: precisa virar texto antes.
SELECT to_date(20261020::text, 'YYYYMMDD') AS de_numero;
