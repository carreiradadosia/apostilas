FROM python:3.13.15-slim-bookworm
# git is required by dbt deps and dbt debug; the lock pins every transitive package on purpose.
RUN apt-get update && apt-get install -y --no-install-recommends git && rm -rf /var/lib/apt/lists/*
COPY requirements.lock /tmp/requirements.lock
RUN pip install --no-cache-dir -r /tmp/requirements.lock
