#!/bin/sh
set -eu

# Wait for Postgres to be ready (use socket for first-time peer auth)
echo "[postgres-init] waiting for postgres socket..."
until su -s /bin/sh postgres -c "psql -Atqc 'SELECT 1'" >/dev/null 2>&1; do
  sleep 1
done

# Set postgres password if provided
if [ -n "${POSTGRES_PASSWORD:-}" ]; then
  su -s /bin/sh postgres -c "psql -v ON_ERROR_STOP=1 -d postgres -c \"ALTER USER \"\"postgres\"\" WITH PASSWORD '${POSTGRES_PASSWORD}';\"" >/dev/null
fi

# Optionally create a bloodhound database and role if desired (defaults not required)
if [ -n "${BH_DB_USER:-}" ] && [ -n "${BH_DB_PASSWORD:-}" ] && [ -n "${BH_DB_NAME:-}" ]; then
  su -s /bin/sh postgres -c "psql -v ON_ERROR_STOP=1 -d postgres -c \"DO $$ BEGIN IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${BH_DB_USER}') THEN CREATE ROLE \"\"${BH_DB_USER}\"\" LOGIN PASSWORD '${BH_DB_PASSWORD}'; END IF; END $$;\"" >/dev/null
  su -s /bin/sh postgres -c "psql -v ON_ERROR_STOP=1 -d postgres -c \"DO $$ BEGIN IF NOT EXISTS (SELECT FROM pg_database WHERE datname='${BH_DB_NAME}') THEN CREATE DATABASE \"\"${BH_DB_NAME}\"\" OWNER \"\"${BH_DB_USER}\"\"; END IF; END $$;\"" >/dev/null
fi

exit 0


