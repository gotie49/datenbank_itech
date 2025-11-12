#!/bin/bash
set -euo pipefail

CONTAINER_NAME="postgres"
DB_NAME="krautundrueben"
DB_USER="admin"

echo "Inserting test data..."

SQL_FILES=(
  "insertTestData.sql"
)

for sql in "${SQL_FILES[@]}"; do
  if [ -f "$sql" ]; then
    echo "   -> Executing $sql"
    docker exec -i "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" < "$sql"
  else
    echo "WARNING: $sql not found — skipping!"
  fi
done

echo "   --> Test data insertion complete! \n 
    Connect: docker exec -it postgres psql -U admin -d krautundrueben"
