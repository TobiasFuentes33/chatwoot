#!/bin/sh
set -e

# Chatwoot web (Rails) entrypoint — see Dockerfile header for the why.

# Remove a potentially pre-existing server.pid (stale lock from a restart).
rm -rf /app/tmp/pids/server.pid

# --- Wait for Postgres (pg_isready ships in the image via postgresql-client) ---
echo "[entrypoint] waiting for postgres at ${POSTGRES_HOST}:${POSTGRES_PORT:-5432}..."
until pg_isready -h "${POSTGRES_HOST}" -p "${POSTGRES_PORT:-5432}" -U "${POSTGRES_USERNAME:-postgres}" -q; do
  sleep 2
done
echo "[entrypoint] postgres is ready."

# --- Wait for Redis (Sidekiq and the Rails cache need it at boot) ---
REDIS_HOSTPORT="${REDIS_URL#redis://}"
REDIS_HOSTPORT="${REDIS_HOSTPORT#*:*@}"   # strip optional userinfo
REDIS_HOST="${REDIS_HOSTPORT%%:*}"
REDIS_PORTNUM="${REDIS_HOSTPORT##*:}"
echo "[entrypoint] waiting for redis at ${REDIS_HOST}:${REDIS_PORTNUM}..."
until ruby -rsocket -e "s=TCPSocket.new('${REDIS_HOST}','${REDIS_PORTNUM}'.to_i); s.close" 2>/dev/null; do
  sleep 2
done
echo "[entrypoint] redis is ready."

# --- Compose DATABASE_URL from component vars unless explicitly overridden ---
# Single ${{...}} refs only: Railway does not reliably resolve several refs
# composed inside one value, so the app gets PG* parts and this script
# assembles the connection string. A manually-set DATABASE_URL always wins.
if [ -z "${DATABASE_URL}" ]; then
  export DATABASE_URL="postgres://${POSTGRES_USERNAME:-postgres}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT:-5432}/${POSTGRES_DATABASE:-chatwoot_production}"
  echo "[entrypoint] composed DATABASE_URL from PG* component vars."
fi

# Idempotent: loads schema + seeds on first boot, runs migrations afterwards.
echo "[entrypoint] running db:chatwoot_prepare..."
bundle exec rails db:chatwoot_prepare

# No -p flag: Rails::Server reads the port from ENV['PORT'], which Railway injects.
echo "[entrypoint] starting Sidekiq..."
bundle exec sidekiq -C config/sidekiq.yml &
SIDEKIQ_PID=$!

echo "[entrypoint] starting Rails..."
bundle exec rails s -b 0.0.0.0 -p "${PORT:-8080}" &
WEB_PID=$!

shutdown() {
  trap - TERM INT
  kill -TERM "$WEB_PID" "$SIDEKIQ_PID" 2>/dev/null || true
  wait "$WEB_PID" 2>/dev/null || true
  wait "$SIDEKIQ_PID" 2>/dev/null || true
}

trap 'shutdown; exit 0' TERM INT

while kill -0 "$WEB_PID" 2>/dev/null &&
      kill -0 "$SIDEKIQ_PID" 2>/dev/null; do
  sleep 2
done

shutdown
exit 1
