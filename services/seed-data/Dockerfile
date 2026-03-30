FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && \
    apt-get install -y apache2-utils postgresql-client && \
    rm -rf /var/lib/apt/lists/*

# ✅ CREATE USER
RUN useradd -m -u 10001 appuser

COPY . .

RUN python3 make-data.py && \
    chmod +x generate-votes.sh entrypoint.sh && \
    chown -R appuser:appuser /app

USER 10001

ENTRYPOINT ["./entrypoint.sh"]

