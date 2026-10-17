#!/bin/sh
set -e

# Chatwoot Sidekiq worker entrypoint: wait for Postgres + Redis, compose
# DATABASE_URL from the PG* component vars (same rule as the web service —
# single refs only, assembled here in shell), then exec Sidekiq in the
# foreground as PID 1 so Railway supervises it.

echo "[worker] waiting for postgres at ${POSTGRES_HOST}:${POSTGRES_PORT:-5432}..."
until pg_isready -h "${POSTGRES_HOST}" -p "${POSTGRES_PORT:-5432}" -U "${POSTGRES_USERNAME:-postgres}" -q; do
  sleep 2
done
echo "[worker] postgres is ready."

REDIS_HOSTPORT="${REDIS_URL#redis://}"
REDIS_HOSTPORT="${REDIS_HOSTPORT#*:*@}"
REDIS_HOST="${REDIS_HOSTPORT%%:*}"
REDIS_PORTNUM="${REDIS_HOSTPORT##*:}"
echo "[worker] waiting for redis at ${REDIS_HOST}:${REDIS_PORTNUM}..."
until ruby -rsocket -e "s=TCPSocket.new('${REDIS_HOST}','${REDIS_PORTNUM}'.to_i); s.close" 2>/dev/null; do
  sleep 2
done
echo "[worker] redis is ready."

if [ -z "${DATABASE_URL}" ]; then
  export DATABASE_URL="postgres://${POSTGRES_USERNAME:-postgres}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT:-5432}/${POSTGRES_DATABASE:-chatwoot_production}"
  echo "[worker] composed DATABASE_URL from PG* component vars."
fi

echo "[worker] starting sidekiq..."
exec bundle exec sidekiq -C config/sidekiq.yml
