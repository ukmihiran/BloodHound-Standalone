# BloodHound Standalone

[![CI](https://github.com/ukmihiran/BloodHound-Standalone/actions/workflows/publish.yml/badge.svg?branch=main)](https://github.com/ukmihiran/BloodHound-Standalone/actions/workflows/publish.yml?query=branch%3Amain)
[![version](https://img.shields.io/github/v/tag/ukmihiran/BloodHound-Standalone?sort=semver)](https://github.com/ukmihiran/BloodHound-Standalone/tags)
[![pulls](https://img.shields.io/docker/pulls/ukmihiran/bloodhound-standalone)](https://hub.docker.com/r/ukmihiran/bloodhound-standalone)
[![size](https://img.shields.io/docker/image-size/ukmihiran/bloodhound-standalone/latest?arch=amd64)](https://hub.docker.com/r/ukmihiran/bloodhound-standalone)
![platforms](https://img.shields.io/badge/platforms-amd64%20|%20arm64-2ea44f?logo=docker)

Single-container image for BloodHound Community Edition with embedded Neo4j 4.4 and PostgreSQL 16. No external DBs required.

## Quickstart

```bash
# Persist databases
docker volume create bh-pg
docker volume create bh-neo4j

# Start
docker run -d --name bloodhound-standalone \
  -p 8080:8080 \
  -e POSTGRES_PASSWORD=changeit \
  -e NEO4J_PASSWORD=changeit \
  -v bh-pg:/var/lib/postgresql/data \
  -v bh-neo4j:/var/lib/neo4j \
  ukmihiran/bloodhound-standalone:latest

# Get setup password banner (first run)
docker logs -f bloodhound-standalone

# Open UI
# http://localhost:8080/ui/login
```

Notes:

- Multi-arch: `linux/amd64` and `linux/arm64` (auto-selected by Docker).
- First start prints a banner with the temporary setup password.

## Tags

- `latest` – rolling
- Semver releases – e.g. `v0.2.0`

```bash
docker pull ukmihiran/bloodhound-standalone:latest
docker pull ukmihiran/bloodhound-standalone:v0.2.0
```

## Configuration (minimal)

- `POSTGRES_PASSWORD` – Postgres superuser password (default `changeit`)
- `NEO4J_PASSWORD` – Neo4j initial password (default `changeit`)
- `BLOODHOUND_CMD` – override startup command (advanced)

## Links

- Docker Hub: [ukmihiran/bloodhound-standalone](https://hub.docker.com/r/ukmihiran/bloodhound-standalone)
- BloodHound CE Quickstart: [BloodHound docs](https://bloodhound.specterops.io/get-started/quickstart/community-edition-quickstart)

---

Unofficial convenience image. Review security posture before exposing services.
