# PostgreSQL 16 + pgvector companion for the Chatwoot Railway template.
#
# Chatwoot 4.x migrations create the `vector` (and `pg_trgm`) extensions, so
# the plain postgres image is NOT sufficient — this must be the pgvector image.
#
# Bakes every constant as ENV because Railway's `templates create` only
# carries ${{...}} expressions into template defaults — literals would land
# on the deploy form as required fields. The only variable on this service
# is POSTGRES_PASSWORD (${{secret(32)}}), which the app and worker reference
# as ${{postgres.POSTGRES_PASSWORD}}.
#
# Volume handling: the official postgres image starts as root and its
# entrypoint chowns $PGDATA, which tolerates Railway's root-owned volumes.
# PGDATA is a SUBDIR of the mount because initdb refuses a volume mount
# point directly (it contains lost+found).

FROM pgvector/pgvector:pg16@sha256:a97d77306ff47cc1d8add4d000cec2207da2e110746318df3137ce53c337ca30

ENV PGDATA=/var/lib/postgresql/data/pgdata \
    POSTGRES_USER=postgres \
    POSTGRES_DB=chatwoot_production

LABEL org.opencontainers.image.source="https://github.com/mc9max/chatwoot"
