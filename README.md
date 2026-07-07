# deploy-scripts

Shared Komodo deploy helpers for Tier 2 services (Infisical CLI bootstrap, secret fetch, compose wrapper).

## Usage in a service repo

Add as a git submodule:

```bash
git submodule add https://github.com/LUK-Server/deploy-scripts.git scripts/vendor/deploy-scripts
```

Each service keeps:

- `scripts/pre-deploy.sh` — initializes submodule, calls `fetch-secrets.sh` with `SECRET=filename` pairs
- `scripts/infisical-compose-wrapper.sh` — initializes submodule, calls `compose-wrapper.sh`

Example pre-deploy excerpt:

```sh
exec sh "$VENDOR/fetch-secrets.sh" \
  SERVER_CERT=server.crt \
  SERVER_KEY=server.key \
  DB_CA_CERT=ca.crt
```

## Komodo

- **Pre-deploy:** `./scripts/pre-deploy.sh`
- **Compose wrapper:** `./scripts/infisical-compose-wrapper.sh [[COMPOSE_COMMAND]]` (include `up` only)
- **Stack environment:** Machine Identity creds, `INFISICAL_PROJECT_ID`, `INFISICAL_API_URL=http://infisical:8080`

Komodo must clone with submodules on pull (enable recursive submodule update if available).

## Releases

Tag versions (`v1.0.0`) and bump the submodule pointer in each service when upgrading.
