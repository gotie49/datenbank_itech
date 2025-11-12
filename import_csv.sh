#!/bin/bash
set -euo pipefail

CONTAINER_NAME="postgres"
DB_NAME="krautundrueben"
DB_USER="admin"
CSV_DIR="./csv"   # <-- CSV directory on HOST MACHINE

echo "Importing CSV data from host machine..."

# Import order must respect foreign keys
TABLES=(
  "LIEFERANT"
  "KUNDE"
  "ZUTAT"
  "ERNAEHRUNGSKATEGORIE"
  "REZEPT"
  "BESTELLUNG"
  "BESTELLUNGREZEPT"
  "REZEPT_ZUTAT"
  "ALLERGENE"
  "REZEPT_ALLERGENE"
)

for table in "${TABLES[@]}"; do
  file="$CSV_DIR/$table.csv"

  if [ ! -f "$file" ]; then
    echo "WARNING: CSV file not found: $file — skipping!"
    continue
  fi

  echo "   -> Importing $file into $table ..."

  # \copy reads CSV from *host machine*, not container
  docker exec -i "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" \
    -c "\copy $table FROM STDIN CSV HEADER DELIMITER ';'" < "$file"
done

echo "CSV import complete!"
