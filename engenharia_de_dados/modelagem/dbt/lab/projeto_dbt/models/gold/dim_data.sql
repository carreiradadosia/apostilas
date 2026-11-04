select
    d::date as data_id,
    extract(year from d)::int as ano,
    extract(month from d)::int as mes,
    extract(isodow from d)::int as dia_da_semana,
    extract(isodow from d) in (6, 7) as fim_de_semana
from generate_series(date '2026-10-01', date '2026-12-31', interval '1 day') as d
