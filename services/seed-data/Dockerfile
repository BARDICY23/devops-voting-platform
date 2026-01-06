FROM python:3.11-slim

WORKDIR /app

COPY . .

RUN useradd -r -u 10001 appuser && chown -R appuser:appuser /app
USER appuser

ENTRYPOINT ["python", "make-data.py"]
	
