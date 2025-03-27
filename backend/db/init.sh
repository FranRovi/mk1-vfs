#!/bin/bash
set -e

# Run the initial schema setup
echo "Running init.sql..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -f /docker-entrypoint-initdb.d/sql/init.sql

# Run all function definitions
for f in /docker-entrypoint-initdb.d/sql/functions/*.sql; do
    echo "Running $f..."
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -f "$f"
done
