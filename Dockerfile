# BloodHound CE + Neo4j + Postgres in one container
# Base on official BloodHound image to inherit upstream updates

ARG BH_BASE=docker.io/specterops/bloodhound:latest
FROM ${BH_BASE} AS bloodhound_src

FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive
ARG S6_OVERLAY_VERSION=v3.2.0.0
ARG NEO4J_MAJOR=4.4
ARG POSTGRES_MAJOR=16
ARG TARGETARCH

ENV S6_KEEP_ENV=1 \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TZ=UTC \
    PGDATA=/var/lib/postgresql/data \
    POSTGRES_USER=postgres \
    POSTGRES_PASSWORD=changeit \
    POSTGRES_DB=postgres \
    NEO4J_PASSWORD=changeit \
    NEO4J_AUTH=neo4j/changeit \
    NEO4J_dbms_default__listen__address=0.0.0.0 \
    NEO4J_dbms_connector_bolt_listen__address=:7687 \
    NEO4J_dbms_connector_http_listen__address=:7474 \
    BLOODHOUND_CMD=""

# Install prerequisites, s6-overlay, Neo4j 5, Postgres 16
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      wget \
      gnupg \
      xz-utils \
      jq \
      lsb-release \
      procps \
      netcat-openbsd \
      gosu \
      tini; \
    \
    # s6-overlay v3 (noarch + arch-specific)
    arch="${TARGETARCH:-$(dpkg --print-architecture)}"; \
    case "$arch" in \
      amd64|x86_64) arch=x86_64 ;; \
      arm64|aarch64) arch=aarch64 ;; \
      *) arch="$arch" ;; \
    esac; \
    curl -fsSL -o /tmp/s6-noarch.tar.xz https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz; \
    curl -fsSL -o /tmp/s6-${arch}.tar.xz https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}/s6-overlay-${arch}.tar.xz; \
    tar -C / -Jxpf /tmp/s6-noarch.tar.xz; \
    tar -C / -Jxpf /tmp/s6-${arch}.tar.xz; \
    rm -f /tmp/s6-*.tar.xz; \
    \
    # Postgres PGDG
    install -d /usr/share/keyrings; \
    curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgres.gpg; \
    echo "deb [signed-by=/usr/share/keyrings/postgres.gpg] http://apt.postgresql.org/pub/repos/apt $(. /etc/os-release; echo $VERSION_CODENAME)-pgdg main" > /etc/apt/sources.list.d/pgdg.list; \
    \
    # Neo4j 5 repo
    curl -fsSL https://debian.neo4j.com/neotechnology.gpg.key | gpg --dearmor -o /usr/share/keyrings/neo4j.gpg; \
    echo "deb [signed-by=/usr/share/keyrings/neo4j.gpg] https://debian.neo4j.com stable ${NEO4J_MAJOR}" > /etc/apt/sources.list.d/neo4j.list; \
    \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      postgresql-${POSTGRES_MAJOR} \
      postgresql-client-${POSTGRES_MAJOR} \
      neo4j; \
    \
    # cleanup
    apt-get purge -y --auto-remove gnupg; \
    rm -rf /var/lib/apt/lists/*

# Bring in BloodHound binary and default config from upstream image
COPY --from=bloodhound_src /bloodhound /usr/local/bin/bloodhound
COPY --from=bloodhound_src /bloodhound.config.json /bloodhound.config.json
RUN chmod +x /usr/local/bin/bloodhound

# Create data directories and permissions
RUN set -eux; \
    mkdir -p /var/lib/postgresql/data /var/lib/neo4j; \
    chown -R postgres:postgres /var/lib/postgresql; \
    chown -R neo4j:neo4j /var/lib/neo4j; \
    # Ensure neo4j pid/log/tmp exist
    mkdir -p /var/log/neo4j /var/run/neo4j /var/tmp/neo4j; \
    chown -R neo4j:neo4j /var/log/neo4j /var/run/neo4j /var/tmp/neo4j

# Copy s6 services and helper scripts
COPY rootfs/ /

VOLUME ["/var/lib/postgresql/data", "/var/lib/neo4j"]

EXPOSE 8080

# Ensure scripts are executable
RUN set -eux; \
    chmod +x /usr/local/bin/healthcheck.sh /usr/local/bin/wait-for-db.sh /usr/local/bin/print-setup-password.sh; \
    chmod +x /etc/s6-overlay/s6-rc.d/*/run || true; \
    chmod +x /etc/s6-overlay/s6-rc.d/*/up || true

# Basic healthcheck: UI + DBs
HEALTHCHECK --interval=30s --timeout=10s --retries=10 CMD /usr/local/bin/healthcheck.sh

ENTRYPOINT ["/init"]


