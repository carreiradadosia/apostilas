FROM python:3.13.15-slim-bookworm
RUN pip install --no-cache-dir python-tds==1.17.1
COPY gerar_relatorio.py /app/gerar_relatorio.py
ENTRYPOINT ["python", "/app/gerar_relatorio.py"]
