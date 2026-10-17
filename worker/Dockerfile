# Chatwoot Sidekiq worker — background jobs (email delivery, webhooks,
# automations, scheduled tasks). Same pinned CE image as the web service;
# without this companion the dashboard runs but nothing is ever sent.
#
# Runs volumeless: /app/storage uploads live on the web service's volume.
# Railway volumes attach to a single service, so the worker reads job payloads
# from Postgres/Redis; file-attachment processing for jobs referencing
# web-uploaded files is a known limitation of this split (documented in README).
#
# Baked literals mirror the web service (see root Dockerfile header): only
# ${{...}} expressions travel into template defaults, so constants are ENV
# here and secrets arrive as single-ref variables.

FROM chatwoot/chatwoot:v4.18.0-ce@sha256:97dbffa882e0e288ed22daf0ceeb45b8b58e5ac2acdd1050be0a80ab75d1789a

USER root

ENV RAILS_ENV=production \
    NODE_ENV=production \
    POSTGRES_PORT=5432 \
    POSTGRES_USERNAME=postgres \
    POSTGRES_DATABASE=chatwoot_production

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

LABEL org.opencontainers.image.source="https://github.com/mc9max/chatwoot"

ENTRYPOINT ["/entrypoint.sh"]
