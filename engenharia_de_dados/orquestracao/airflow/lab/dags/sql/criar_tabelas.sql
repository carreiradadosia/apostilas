CREATE TABLE IF NOT EXISTS pedidos_tratados (
    id            integer PRIMARY KEY,
    cliente       text NOT NULL,
    valor         numeric(12, 2) NOT NULL,
    status        text NOT NULL,
    criado_em_utc timestamptz NOT NULL
);

CREATE TABLE IF NOT EXISTS controle_carga (
    id             bigserial PRIMARY KEY,
    run_id         text NOT NULL,
    tipo_execucao  text NOT NULL,
    linhas         integer NOT NULL,
    registrado_em  timestamptz NOT NULL DEFAULT now()
);
