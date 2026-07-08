# deploy-scripts

Shared Komodo deploy helpers for Tier 2 services (Infisical CLI bootstrap, compose wrapper).

## Usage in a service repo

Add as a git submodule:

```bash
git submodule add https://github.com/LUK-Server/deploy-scripts.git scripts/vendor/deploy-scripts
```

Each service keeps:

- `scripts/pre-deploy.sh` — sync TLS certs from `/srv/data/certs/` into `./certs/` (service-specific)
- `scripts/infisical-compose-wrapper.sh` — initializes submodule, calls `compose-wrapper.sh`

Example pre-deploy (PostgreSQL server):

```sh
mkdir -p "$ROOT/certs"
cp /srv/data/certs/ca.crt \
   /srv/data/certs/postgres/server.crt \
   /srv/data/certs/postgres/server.key \
   "$ROOT/certs/"
chmod 600 "$ROOT/certs/server.key"
```

Example pre-deploy (DB consumer):

```sh
cp /srv/data/certs/ca.crt \
   /srv/data/certs/intermediate.crt \
   /srv/data/certs/services/myservice/client.crt \
   /srv/data/certs/services/myservice/client.key \
   "$ROOT/certs/"
```

Issue certs on the host first — see [docs/certificates.md](../docs/certificates.md) in the SERVER repo.

`fetch-secrets.sh` remains available for secrets that must be written to files from Infisical, but **TLS certs are not stored in Infisical** on this stack.

## Komodo

- **Pre-deploy:** `./scripts/pre-deploy.sh`
- **Compose wrapper:** `./scripts/infisical-compose-wrapper.sh [[COMPOSE_COMMAND]]` (include `up` only)
- **Stack environment:** Machine Identity creds, `INFISICAL_PROJECT_ID`, `INFISICAL_API_URL=http://infisical:8080`, `DOMAIN`

Komodo must clone with submodules on pull (enable recursive submodule update if available). Pre-deploy also runs `git submodule update --init` as a fallback.

Periphery must mount `/srv/data/certs:ro` so pre-deploy can read step-ca material.

If the submodule repo is private, use a deploy key + SSH URL in `.gitmodules`, make the repo public (scripts contain no secrets), or configure git credentials on Periphery.

## Releases

Tag versions (`v1.0.0`) and bump the submodule pointer in each service when upgrading.
