FROM python:3.13.15-alpine3.24
RUN pip install --no-cache-dir "psycopg[binary]==3.3.5"
WORKDIR /lab
CMD ["python", "scripts/pipeline.py"]
