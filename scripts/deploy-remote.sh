#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${APP_DIR:-/volume1/docker/mybank}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

cd "$APP_DIR"

if [ ! -f .env ]; then
  echo "ERREUR: $APP_DIR/.env est absent. Crée-le depuis .env.production.example avant le premier déploiement."
  exit 1
fi

tmp_env="$(mktemp)"
grep -v '^IMAGE_TAG=' .env > "$tmp_env" || true
printf 'IMAGE_TAG=%s\n' "$IMAGE_TAG" >> "$tmp_env"
cat "$tmp_env" > .env
rm -f "$tmp_env"
chmod 600 .env

docker compose --env-file .env -f docker-compose.yml pull
docker compose --env-file .env -f docker-compose.yml up -d --remove-orphans
docker compose --env-file .env -f docker-compose.yml exec -T backend \
  php bin/console doctrine:migrations:migrate --no-interaction --allow-no-migration
docker image prune -f
docker compose --env-file .env -f docker-compose.yml ps
