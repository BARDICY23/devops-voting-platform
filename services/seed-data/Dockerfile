FROM python:3.11-alpine

WORKDIR /app

RUN apk update && \
    apk add --no-cache apache2-utils postgresql-client

# ✅ CREATE USER
RUN adduser -D -u 10001 appuser

COPY . .

RUN python3 make-data.py && \
    chmod +x generate-votes.sh entrypoint.sh && \
    chown -R appuser:appuser /app

USER 10001

ENTRYPOINT ["./entrypoint.sh"]

