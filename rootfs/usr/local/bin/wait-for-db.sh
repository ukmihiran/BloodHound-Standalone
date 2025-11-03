#!/bin/sh
set -eu

# Wait for Postgres
echo "[wait] waiting for Postgres on 127.0.0.1:5432"
for i in $(seq 1 120); do
  if pg_isready -h 127.0.0.1 -p 5432 >/dev/null 2>&1; then
    ok_pg=1
    break
  fi
  sleep 1
done

if [ "${ok_pg:-0}" != "1" ]; then
  echo "[wait] Postgres not ready" >&2
  exit 1
fi

# Wait for Neo4j bolt
echo "[wait] waiting for Neo4j bolt on 127.0.0.1:7687"
for i in $(seq 1 120); do
  if nc -z 127.0.0.1 7687 >/dev/null 2>&1; then
    ok_bolt=1
    break
  fi
  sleep 1
done

if [ "${ok_bolt:-0}" != "1" ]; then
  echo "[wait] Neo4j not ready" >&2
  exit 1
fi

exit 0


