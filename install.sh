#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="${PROJECT_DIR:-/srv/docker/projects/traefik-proxy}"
SECRETS_DIR="${SECRETS_DIR:-/etc/docker-secrets/traefik-proxy}"
TRAEFIK_PROXY_NETWORK="${TRAEFIK_PROXY_NETWORK:-traefik-proxy}"
ACME_DNS_PROVIDER="${ACME_DNS_PROVIDER:-hetzner}"
ACME_DNS_RESOLVER_1="${ACME_DNS_RESOLVER_1:-1.1.1.1:53}"
ACME_DNS_RESOLVER_2="${ACME_DNS_RESOLVER_2:-8.8.8.8:53}"
NETBIRD_INTERFACE="${NETBIRD_INTERFACE:-wt0}"
DOCKER_SOCKET_PROXY_IMAGE="${DOCKER_SOCKET_PROXY_IMAGE:-tecnativa/docker-socket-proxy:0.3.0}"
TRAEFIK_IMAGE="${TRAEFIK_IMAGE:-traefik:3.6}"
DEFAULT_BACKEND_IMAGE="${DEFAULT_BACKEND_IMAGE:-nginx:alpine}"
TRAEFIK_LOG_LEVEL="${TRAEFIK_LOG_LEVEL:-INFO}"
HETZNER_TOKEN_FILE_NAME="${HETZNER_TOKEN_FILE_NAME:-hetzner_api_token.txt}"

ensure_env_key() {
  local env_file="$1"
  local key="$2"
  local value="$3"

  if ! sudo grep -q "^${key}=" "$env_file"; then
    echo "${key}=${value}" | sudo tee -a "$env_file" >/dev/null
  fi
}

sudo install -d -m 755 "$PROJECT_DIR" "$PROJECT_DIR/traefik" "$PROJECT_DIR/traefik/certs" "$PROJECT_DIR/traefik/dynamic"
sudo install -m 644 docker-compose.yml "$PROJECT_DIR/docker-compose.yml"
sudo install -m 644 traefik/traefik.yml "$PROJECT_DIR/traefik/traefik.yml"
sudo install -m 644 traefik/dynamic/security.yml "$PROJECT_DIR/traefik/dynamic/security.yml"

if [ -f "$PROJECT_DIR/traefik/certs/acme.json" ]; then
  echo "Bestehende acme.json bleibt unveraendert: $PROJECT_DIR/traefik/certs/acme.json"
elif [ -f "traefik/certs/acme.json" ]; then
  sudo install -m 600 traefik/certs/acme.json "$PROJECT_DIR/traefik/certs/acme.json"
else
  sudo install -m 600 /dev/null "$PROJECT_DIR/traefik/certs/acme.json"
fi

if [ ! -f "$PROJECT_DIR/.env" ]; then
  cat <<EOF | sudo tee "$PROJECT_DIR/.env" >/dev/null
SECRETS_DIR=$SECRETS_DIR
ACME_EMAIL=
NETBIRD_BIND_IP=
BASE_DOMAIN=
TRAEFIK_DASHBOARD_HOST=
TRAEFIK_PROXY_NETWORK=$TRAEFIK_PROXY_NETWORK
ACME_DNS_PROVIDER=$ACME_DNS_PROVIDER
ACME_DNS_RESOLVER_1=$ACME_DNS_RESOLVER_1
ACME_DNS_RESOLVER_2=$ACME_DNS_RESOLVER_2
NETBIRD_INTERFACE=$NETBIRD_INTERFACE
DOCKER_SOCKET_PROXY_IMAGE=$DOCKER_SOCKET_PROXY_IMAGE
TRAEFIK_IMAGE=$TRAEFIK_IMAGE
DEFAULT_BACKEND_IMAGE=$DEFAULT_BACKEND_IMAGE
TRAEFIK_LOG_LEVEL=$TRAEFIK_LOG_LEVEL
HETZNER_TOKEN_FILE_NAME=$HETZNER_TOKEN_FILE_NAME
EOF
else
  ensure_env_key "$PROJECT_DIR/.env" "SECRETS_DIR" "$SECRETS_DIR"
  ensure_env_key "$PROJECT_DIR/.env" "ACME_EMAIL" ""
  ensure_env_key "$PROJECT_DIR/.env" "NETBIRD_BIND_IP" ""
  ensure_env_key "$PROJECT_DIR/.env" "BASE_DOMAIN" ""
  ensure_env_key "$PROJECT_DIR/.env" "TRAEFIK_DASHBOARD_HOST" ""
  ensure_env_key "$PROJECT_DIR/.env" "TRAEFIK_PROXY_NETWORK" "$TRAEFIK_PROXY_NETWORK"
  ensure_env_key "$PROJECT_DIR/.env" "ACME_DNS_PROVIDER" "$ACME_DNS_PROVIDER"
  ensure_env_key "$PROJECT_DIR/.env" "ACME_DNS_RESOLVER_1" "$ACME_DNS_RESOLVER_1"
  ensure_env_key "$PROJECT_DIR/.env" "ACME_DNS_RESOLVER_2" "$ACME_DNS_RESOLVER_2"
  ensure_env_key "$PROJECT_DIR/.env" "NETBIRD_INTERFACE" "$NETBIRD_INTERFACE"
  ensure_env_key "$PROJECT_DIR/.env" "DOCKER_SOCKET_PROXY_IMAGE" "$DOCKER_SOCKET_PROXY_IMAGE"
  ensure_env_key "$PROJECT_DIR/.env" "TRAEFIK_IMAGE" "$TRAEFIK_IMAGE"
  ensure_env_key "$PROJECT_DIR/.env" "DEFAULT_BACKEND_IMAGE" "$DEFAULT_BACKEND_IMAGE"
  ensure_env_key "$PROJECT_DIR/.env" "TRAEFIK_LOG_LEVEL" "$TRAEFIK_LOG_LEVEL"
  ensure_env_key "$PROJECT_DIR/.env" "HETZNER_TOKEN_FILE_NAME" "$HETZNER_TOKEN_FILE_NAME"
fi
sudo chmod 600 "$PROJECT_DIR/.env"

sudo install -d -m 700 /etc/docker-secrets
sudo install -d -m 700 "$SECRETS_DIR"
sudo touch "$SECRETS_DIR/$HETZNER_TOKEN_FILE_NAME"
sudo chmod 600 "$SECRETS_DIR/$HETZNER_TOKEN_FILE_NAME"

echo "Setup abgeschlossen."
echo "1) Trage den Hetzner-Token in $SECRETS_DIR/$HETZNER_TOKEN_FILE_NAME ein."
echo "2) Setze BASE_DOMAIN, TRAEFIK_DASHBOARD_HOST, ACME_EMAIL und NETBIRD_BIND_IP in $PROJECT_DIR/.env."
