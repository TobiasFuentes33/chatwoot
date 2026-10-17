# Chatwoot — open-source customer support platform (Intercom/Zendesk alternative).
#
# Wraps the pinned official Community Edition image. The stock image ships NO
# entrypoint/CMD of its own (upstream docker-compose always supplies
# docker/entrypoints/rails.sh + an explicit command), so this wrapper provides
# entrypoint.sh as PID 1: it waits for Postgres/Redis (services boot in
# parallel on Railway), runs the idempotent db:chatwoot_prepare (schema-load +
# seed on first boot, migrations after), then execs `rails s -b 0.0.0.0`
# WITHOUT -p so Rails honors Railway's injected PORT (Rails::Server defaults
# the port from ENV['PORT']).
#
# The stock image runs as root (ruby:3.4.4-alpine3.21 base, no USER directive),
# which tolerates Railway's root-owned volumes — /app/storage (ActiveStorage
# uploads) lives on the mounted volume.
#
# Baked literals: `railway templates create` carries ONLY ${{...}} expressions
# from scratch-project variable values into template defaults — plain literals
# would land on the deploy form as required fields. So every constant
# (RAILS_ENV, postgres user/db/port) is baked here as ENV; the entrypoint
# composes DATABASE_URL in shell from the single-ref PG* variables.
#
# No in-container HEALTHCHECK: the alpine ruby base has no curl/wget (upstream
# only installs curl for non-production builds). Railway's external /health
# check covers it — the app exposes an unauthenticated GET /health.

FROM chatwoot/chatwoot:v4.18.0-ce@sha256:97dbffa882e0e288ed22daf0ceeb45b8b58e5ac2acdd1050be0a80ab75d1789a

USER root

ENV RAILS_ENV=production \
    NODE_ENV=production \
    POSTGRES_PORT=5432 \
    POSTGRES_USERNAME=postgres \
    POSTGRES_DATABASE=chatwoot_production

EXPOSE 3000

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

LABEL org.opencontainers.image.source="https://github.com/mc9max/chatwoot"

ENTRYPOINT ["/entrypoint.sh"]
