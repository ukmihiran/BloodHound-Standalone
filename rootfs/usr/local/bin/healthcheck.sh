#!/bin/sh
set -eu

# UI check
if ! curl -fsS --max-time 3 http://127.0.0.1:8080/ui/login >/dev/null 2>&1; then
  exit 1
fi

# Postgres ready
if ! pg_isready -q -h 127.0.0.1 -p 5432; then
  exit 1
fi

# Neo4j basic cypher
if command -v cypher-shell >/dev/null 2>&1; then
  if ! cypher-shell -a bolt://127.0.0.1:7687 -u neo4j -p "${NEO4J_PASSWORD:-changeit}" "RETURN 1" >/dev/null 2>&1; then
    exit 1
  fi
fi

exit 0


