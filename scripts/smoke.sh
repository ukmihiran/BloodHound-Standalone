#!/usr/bin/env bash
set -euo pipefail

IMAGE_TAG="${IMAGE_TAG:-bloodhound-standalone:smoke}"
CONTAINER_NAME="bh-standalone-smoke-$$"

echo "[smoke] building image: ${IMAGE_TAG}"
docker build -t "${IMAGE_TAG}" .

echo "[smoke] starting container: ${CONTAINER_NAME}"
docker run -d --rm --name "${CONTAINER_NAME}" \
  -p 127.0.0.1::8080 \
  -e POSTGRES_PASSWORD=changeit \
  -e NEO4J_PASSWORD=changeit \
  "${IMAGE_TAG}"

HOST_PORT=$(docker port "${CONTAINER_NAME}" 8080/tcp | awk -F: '{print $2}')
echo "[smoke] waiting for UI on :${HOST_PORT}..."
for i in $(seq 1 120); do
  if curl -fsS "http://127.0.0.1:${HOST_PORT}/ui/login" >/dev/null 2>&1; then
    echo "[smoke] UI is up"
    break
  fi
  sleep 1
done

echo "[smoke] checking Postgres..."
docker exec "${CONTAINER_NAME}" pg_isready -q -h 127.0.0.1 -p 5432

echo "[smoke] checking Neo4j..."
docker exec "${CONTAINER_NAME}" sh -lc 'cypher-shell -a bolt://127.0.0.1:7687 -u neo4j -p "$NEO4J_PASSWORD" "RETURN 1"' >/dev/null

echo "[smoke] success"
docker logs --tail 50 "${CONTAINER_NAME}" || true
docker stop "${CONTAINER_NAME}" >/dev/null


