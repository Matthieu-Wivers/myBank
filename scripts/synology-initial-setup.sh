#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/volume1/docker/mybank"

cat <<'TXT'
Setup initial MyBank pour Synology DS225+.
À lancer en SSH sur le Synology avec un utilisateur autorisé à utiliser Docker/Container Manager.
TXT

if ! command -v docker >/dev/null 2>&1; then
  echo "ERREUR: docker est introuvable. Installe Container Manager depuis DSM puis relance ce script."
  exit 1
fi

read -r -p "Docker Hub username: " DOCKERHUB_USERNAME
read -r -p "Domaine public [https://my-bank.wivers.fr]: " CORS_ALLOW_ORIGIN
CORS_ALLOW_ORIGIN="${CORS_ALLOW_ORIGIN:-https://my-bank.wivers.fr}"
read -r -p "Nom de base Postgres [mybank]: " POSTGRES_DB
POSTGRES_DB="${POSTGRES_DB:-mybank}"
read -r -p "Utilisateur Postgres [mybank]: " POSTGRES_USER
POSTGRES_USER="${POSTGRES_USER:-mybank}"

read -r -s -p "Mot de passe Postgres: " POSTGRES_PASSWORD
echo
if [ -z "$POSTGRES_PASSWORD" ]; then
  echo "ERREUR: POSTGRES_PASSWORD ne peut pas être vide."
  exit 1
fi

if command -v openssl >/dev/null 2>&1; then
  APP_SECRET="$(openssl rand -hex 32)"
else
  APP_SECRET="$(date +%s | sha256sum | awk '{print $1}')"
fi

mkdir -p "$APP_DIR/postgres"
chmod 700 "$APP_DIR"

cat > "$APP_DIR/.env" <<EOF
DOCKERHUB_USERNAME=$DOCKERHUB_USERNAME
IMAGE_TAG=latest

POSTGRES_DB=$POSTGRES_DB
POSTGRES_USER=$POSTGRES_USER
POSTGRES_PASSWORD=$POSTGRES_PASSWORD

APP_ENV=prod
APP_DEBUG=0
APP_SECRET=$APP_SECRET
CORS_ALLOW_ORIGIN=$CORS_ALLOW_ORIGIN
EOF

chmod 600 "$APP_DIR/.env"

cat <<EOF

OK: fichier $APP_DIR/.env créé.

Étape optionnelle si tes images Docker Hub sont privées:
  docker login docker.io -u $DOCKERHUB_USERNAME

Le workflow GitHub copiera docker-compose.prod.yml vers:
  $APP_DIR/docker-compose.yml
EOF
