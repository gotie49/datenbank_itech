#!/bin/bash
set -euo pipefail

CONTAINER_NAME="postgres"
DB_NAME="krautundrueben"
DB_USER="admin"
DB_PASS="admin"
PG_VERSION="17"
VOLUME_NAME="pgdata"

CSV_DIR="./csv"   # <-- CSV directory on HOST MACHINE

if [ "$(docker ps -aq -f name=^${CONTAINER_NAME}$)" ]; then
  echo "container '$CONTAINER_NAME' already exists. removing..."
  docker rm -f "$CONTAINER_NAME" >/dev/null
fi

if [ "$(docker volume ls -q -f name=^${VOLUME_NAME}$)" ]; then
  echo "volume '$VOLUME_NAME' already exists. removing..."
  docker volume rm "$VOLUME_NAME" >/dev/null
fi

echo "setting up new docker volume..."
docker volume create "$VOLUME_NAME" >/dev/null

echo "starting postgresql container..."
docker run -d \
  --name "$CONTAINER_NAME" \
  -e POSTGRES_USER="$DB_USER" \
  -e POSTGRES_PASSWORD="$DB_PASS" \
  -e POSTGRES_DB="$DB_NAME" \
  -v "$VOLUME_NAME":/var/lib/postgresql/data \
  -p 5432:5432 \
  "postgres:$PG_VERSION"

echo "waiting for postgresql container..."
until docker exec "$CONTAINER_NAME" pg_isready -U "$DB_USER" -d "$DB_NAME" >/dev/null 2>&1; do
  sleep 1
done

echo "creating tables, procedures, functions, and views..."
for sql in createTable.sql createRolesAndProcedures.sql; do
  echo "   -> executing $sql"
  docker exec -i "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" < "$sql"
done

echo "   --> postgresql is fully ready!"
