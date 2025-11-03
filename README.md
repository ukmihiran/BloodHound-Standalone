# BloodHound Standalone (Unofficial)

Single-container image bundling BloodHound Community Edition, Neo4j 5, and PostgreSQL 16. No external DB setup required.

Reference: BloodHound CE Quickstart ([link](https://bloodhound.specterops.io/get-started/quickstart/community-edition-quickstart)).

## Build

```bash
# Multi-arch example (requires docker buildx)
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t yourrepo/bloodhound-standalone:latest \
  .
```

## Run

```bash
# Persist databases
docker volume create bh-pg
docker volume create bh-neo4j

# Start container
docker run -d --name bloodhound-standalone \
  -p 8080:8080 \
  -e POSTGRES_PASSWORD=changeit \
  -e NEO4J_PASSWORD=changeit \
  -v bh-pg:/var/lib/postgresql/data \
  -v bh-neo4j:/var/lib/neo4j \
  yourrepo/bloodhound-standalone:latest

# Open UI
# http://localhost:8080/ui/login
```

Defaults:
- UI: `http://localhost:8080`
- Postgres: `localhost:5432` (not exposed)
- Neo4j: bolt `localhost:7687`, http `localhost:7474` (not exposed)

## Configuration

Environment variables:
- `POSTGRES_USER` (default `postgres`)
- `POSTGRES_PASSWORD` (default `changeit`)
- `POSTGRES_DB` (default `postgres`)
- `NEO4J_PASSWORD` (default `changeit`)
- `NEO4J_AUTH` (default `neo4j/changeit`)
- `DATABASE_URL` (auto-derived if unset)
- `NEO4J_URI` (default `bolt://127.0.0.1:7687`)
- `BLOODHOUND_CMD` (override how BloodHound starts if detection fails)

Volumes:
- `/var/lib/postgresql/data` (Postgres)
- `/var/lib/neo4j` (Neo4j)

## Healthcheck

Container reports healthy when:
- UI `/ui/login` responds HTTP 200
- `pg_isready` is OK
- `cypher-shell "RETURN 1"` succeeds

## Upgrades

- BloodHound: inherited from upstream base image when rebuilding
- Neo4j/Postgres: minor/patch updates applied automatically on rebuild (pinned majors)

Rebuild weekly or enable the provided GitHub Actions workflow.

## Notes

- This is an unofficial convenience image.
- Review security posture before exposing ports publicly.
- Use on systems you own or have explicit authorization to test.

## License

BloodHound, Neo4j, and PostgreSQL are distributed under their respective licenses. This repository includes only orchestration and packaging.

