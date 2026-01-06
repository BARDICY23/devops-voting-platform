#!/bin/sh
set -e

: "${POSTGRES_PASSWORD:?Need to set POSTGRES_PASSWORD env var}"
: "${POSTGRES_HOST:=voting-app-postgresql}"

echo "Waiting for DB..."
until PGPASSWORD=$POSTGRES_PASSWORD pg_isready \
  -h "$POSTGRES_HOST" \
  -U postgres \
  -d postgres >/dev/null 2>&1; do
    echo "DB not ready, retrying..."
    sleep 1
done

echo "Creating table if not exists..."
PGPASSWORD=$POSTGRES_PASSWORD psql \
  -h "$POSTGRES_HOST" \
  -U postgres \
  -d postgres \
  -c "CREATE TABLE IF NOT EXISTS votes (id VARCHAR(255) PRIMARY KEY, vote VARCHAR(255) NOT NULL);"

sleep 2

echo "Generating votes..."
./generate-votes.sh
