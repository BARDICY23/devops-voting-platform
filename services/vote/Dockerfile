FROM python:3.11-alpine

WORKDIR /app

COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir --upgrade pip wheel setuptools jaraco.context && \
    pip install --no-cache-dir -r requirements.txt

COPY . .

RUN adduser -D -u 10001 appuser && \
    chown -R appuser:appuser /app

USER 10001

EXPOSE 8080

CMD ["gunicorn", "app:app", "-b", "0.0.0.0:8080", "--log-file", "-", "--access-logfile", "-", "--workers", "4", "--keep-alive", "0"]
