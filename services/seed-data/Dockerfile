FROM python:3.11-slim

WORKDIR /app

# Install dependencies including Apache Benchmark and psql client
RUN apt-get update && \
    apt-get install -y apache2-utils postgresql-client && \
    rm -rf /var/lib/apt/lists/*

# Copy everything in seed-data
COPY . .

# Generate POST data files
RUN python3 make-data.py

# Make the scripts executable
RUN chmod +x generate-votes.sh
RUN chmod +x entrypoint.sh
# Wait for DB, ensure votes table exists, then generate votes
ENTRYPOINT ["./entrypoint.sh"]

# uses PGPASSWORD from docker-compose environment
USER appuser

CMD ["./generate-votes.sh"]
