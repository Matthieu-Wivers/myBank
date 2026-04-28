#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${APP_DIR:-/volume1/docker/mybank}"
SHA_TAG="${1:-}"

if [ -z "$SHA_TAG" ]; then
  echo "Usage: $0 <sha-court-ou-tag-stable>"
  echo "Exemple: $0 a1b2c3d"
  exit 1
fi

cd "$APP_DIR"

if [ ! -f .env ]; then
  echo "ERREUR: $APP_DIR/.env introuvable."
  exit 1
fi

tmp_env="$(mktemp)"
grep -v '^IMAGE_TAG=' .env > "$tmp_env" || true
printf 'IMAGE_TAG=%s\n' "$SHA_TAG" >> "$tmp_env"
cat "$tmp_env" > .env
rm -f "$tmp_env"
chmod 600 .env

docker compose --env-file .env -f docker-compose.yml pull
docker compose --env-file .env -f docker-compose.yml up -d --remove-orphans
docker compose --env-file .env -f docker-compose.yml exec -T backend \
  php bin/console doctrine:migrations:migrate --no-interaction --allow-no-migration || true
docker compose --env-file .env -f docker-compose.yml ps
