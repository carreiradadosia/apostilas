FROM apache/airflow:3.3.2-python3.13
# dbt gets its own virtualenv, so its pinned packages never fight the Airflow constraints.
COPY runner/requirements.lock /tmp/dbt-requirements.lock
RUN python -m venv /opt/airflow/dbt-venv \
    && /opt/airflow/dbt-venv/bin/pip install --no-cache-dir -r /tmp/dbt-requirements.lock
