FROM python:3.13.15-slim-bookworm
# No database server: DuckDB runs inside the dbt process and writes one file.
COPY requirements.lock /tmp/requirements.lock
RUN pip install --no-cache-dir -r /tmp/requirements.lock
