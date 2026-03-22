FROM python:3.12-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    TMPDIR=/tmp

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
  && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

COPY . /app

# Create non-root user (fits runAsNonRoot policies)
RUN groupadd -g 10001 appgroup \
 && useradd  -u 10001 -g 10001 -m -s /usr/sbin/nologin appuser \
 && chown -R 10001:10001 /app

USER 10001

EXPOSE 8080

CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "2", "--threads", "4", "--timeout", "60", "--access-logfile", "-", "--error-logfile", "-", "--worker-tmp-dir", "/tmp", "--no-control-socket", "app:app"]