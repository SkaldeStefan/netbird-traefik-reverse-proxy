# Traefik Reverse Proxy (NetBird-only)

## Kurzueberblick
- Traefik als Reverse Proxy fuer `BASE_DOMAIN` und `*.BASE_DOMAIN`
- TLS via ACME DNS-Challenge
- Docker Provider ueber `tecnativa/docker-socket-proxy` (kein direkter Socket in Traefik)
- Secret-basierte Token-Nutzung (`HETZNER_API_TOKEN_FILE`)
- Ports `80/443` sind auf `NETBIRD_BIND_IP` gebunden
- Domain, Netzwerkname und weitere Umgebungswerte kommen aus `.env`

## Quickstart (Host Deployment)
Voraussetzungen:
- Docker und Docker Compose sind installiert
- Externes Docker-Netzwerk `TRAEFIK_PROXY_NETWORK` existiert
- DNS zeigt fuer `BASE_DOMAIN`, `*.BASE_DOMAIN` und `TRAEFIK_DASHBOARD_HOST` auf den Host

1. Netzwerk anlegen (einmalig, Name aus `TRAEFIK_PROXY_NETWORK`):
```bash
docker network create <TRAEFIK_PROXY_NETWORK>
```

2. Setup ausfuehren:
```bash
./install.sh
```

3. Deploy-`.env` unter `${PROJECT_DIR:-/srv/docker/projects/traefik-proxy}` befuellen.
   Referenz: [.env.example](.env.example)

Mindestens diese Werte setzen:
```env
SECRETS_DIR=/etc/docker-secrets/traefik-proxy
ACME_EMAIL=mail@example.com
NETBIRD_BIND_IP=<wt0-ip>
BASE_DOMAIN=example.com
TRAEFIK_DASHBOARD_HOST=traefik.example.com
TRAEFIK_PROXY_NETWORK=traefik-proxy
```

4. Secret setzen:
```bash
source <PROJECT_DIR>/.env
sudo sh -c "printf '%s\n' '<hetzner-token>' > '${SECRETS_DIR}/${HETZNER_TOKEN_FILE_NAME}'"
sudo chmod 600 "${SECRETS_DIR}/${HETZNER_TOKEN_FILE_NAME}"
```

5. Starten:
```bash
cd <PROJECT_DIR>
docker compose up -d
docker compose logs -f traefik
```

## Wichtige Env-Variablen
- `BASE_DOMAIN`: Hauptdomain (z. B. `example.com`)
- `TRAEFIK_DASHBOARD_HOST`: Hostname fuer Dashboard-Route (z. B. `traefik.example.com`)
- `TRAEFIK_PROXY_NETWORK`: Externes Docker-Netzwerk fuer Traefik und Backends
- `ACME_DNS_PROVIDER`: DNS Provider fuer ACME Challenge (Default `hetzner`)
- `ACME_DNS_RESOLVER_1`, `ACME_DNS_RESOLVER_2`: DNS Resolver fuer die Challenge
- `HETZNER_TOKEN_FILE_NAME`: Dateiname des API Tokens in `SECRETS_DIR`
- `DOCKER_SOCKET_PROXY_IMAGE`, `TRAEFIK_IMAGE`, `DEFAULT_BACKEND_IMAGE`: Image-Overrides

## Architektur
- [docker-compose.yml](docker-compose.yml): Services `docker-socket-proxy`, `traefik`, `verwaltung`
- [traefik/traefik.yml](traefik/traefik.yml): statische Traefik-Konfiguration (EntryPoints, Provider, Resolver)
- [traefik/dynamic/security.yml](traefik/dynamic/security.yml): Security Header + TLS Optionen
- [install.sh](install.sh): idempotentes Host-Setup fuer Ordner, Config, `.env` und Secret-Datei

## Security-Baseline
- Docker Auto-Exposure ist deaktiviert (`exposedByDefault: false`)
- Docker API Zugriff nur ueber Socket-Proxy mit eingeschraenkten Rechten
- Hetzner Token als Secret-Datei, nicht in `.env`
- Security-Header global auf `websecure`
- TLS Optionen zentral ueber File Provider (`tls.options.default`)

## Funktionstest
```bash
curl -I -H "Host: ${BASE_DOMAIN}" http://<NETBIRD_HOST_IP>
curl -I -H "Host: ${BASE_DOMAIN}" https://<NETBIRD_HOST_IP>
```

Erwartung:
- HTTP liefert Redirect auf HTTPS
- HTTPS liefert Antwort vom Service `verwaltung` (oder von spezifischem Router)

## Troubleshooting
- Zertifikate fehlschlagen:
  - Token in `${SECRETS_DIR}/${HETZNER_TOKEN_FILE_NAME}` pruefen
  - DNS-Eintraege fuer `BASE_DOMAIN` und `TRAEFIK_DASHBOARD_HOST` pruefen
  - `docker compose logs -f traefik`
- `docker compose up` mit Netzwerkfehler:
  - Netzwerk `${TRAEFIK_PROXY_NETWORK}` existiert nicht
- Keine Erreichbarkeit ueber NetBird:
  - NetBird ACL/Policy pruefen
  - `NETBIRD_BIND_IP` in `.env` pruefen

