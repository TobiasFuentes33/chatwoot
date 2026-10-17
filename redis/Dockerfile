# Redis 7 companion for the Chatwoot Railway template.
#
# Backs the Rails cache, ActionCable, and the Sidekiq job queues. Runs without
# a password: it is only reachable over Railway's private network, and
# Chatwoot accepts a plain REDIS_URL. Append-only persistence is enabled so
# queued jobs survive restarts; /data lives on the mounted volume.
#
# No variables on this service — the app and worker reach it at
# redis://${{redis.RAILWAY_PRIVATE_DOMAIN}}:6379 (single ref + literal, which
# Railway resolves reliably).

FROM redis:7-alpine@sha256:ca0acbb137c1dc3339c8b147a58fd6f42775d4599327b50e7b116c23de501af2

LABEL org.opencontainers.image.source="https://github.com/mc9max/chatwoot"

CMD ["redis-server", "--appendonly", "yes"]
