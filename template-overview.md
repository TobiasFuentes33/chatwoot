[![Deploy on Railway](https://railway.app/button.svg)](https://railway.com/deploy/chatwoot?utm_campaign=chatwoot)

# Deploy and Host

Chatwoot is the open-source customer support platform — live chat, a shared omnichannel inbox (email, website widget, WhatsApp, Telegram, social), help center, and automations. Deploy the complete production stack in one click: Rails web app, Sidekiq worker, PostgreSQL 16 + pgvector, and Redis. The deploy form has zero fields — secrets are generated and services auto-wire over the private network. Open the public URL after deploy and the setup wizard creates your admin account.

## About Hosting

Four always-on services on Railway: `chatwoot` (Rails web, honors the injected `PORT`, unauthenticated `GET /health`), `chatwoot-worker` (Sidekiq — email, webhooks, automations), `postgres` (PostgreSQL 16 with the pgvector extension Chatwoot 4.x migrations require), and `redis` (cache + job queues, append-only). Uploads persist on the `chatwoot-data` volume (`/app/storage`); Postgres and Redis each keep their own volume.

## Why Deploy

Chatwoot Cloud bills per agent — this self-hosted Community Edition gives you unlimited agents, inboxes, and conversations on MIT-licensed code, with every conversation stored in your own database instead of a vendor's warehouse.

## Common Use Cases

- Live-chat widget on a marketing site or docs portal
- Shared support inbox across email, chat, WhatsApp, and social channels
- Customer-facing help center / knowledge base
- Post-purchase support inbox for an online store

## Dependencies for

- `SECRET_KEY_BASE` — auto-generated Rails signing secret, shared web ↔ worker by reference
- `FRONTEND_URL` — auto-filled from the Railway public domain
- `POSTGRES_PASSWORD` — auto-generated on the postgres service, referenced by app and worker
- `REDIS_URL` — auto-wired over the private network (no password; private network only)
- Baked into the images: `RAILS_ENV=production`, `POSTGRES_PORT=5432`, `POSTGRES_USERNAME=postgres`, `POSTGRES_DATABASE=chatwoot_production`
- Optional upstream overrides (set in the dashboard when needed): `DATABASE_URL`, `ENABLE_ACCOUNT_SIGNUP`, `FORCE_SSL`, `HELPCENTER_URL`, `DEFAULT_LOCALE`, `RAILS_MAX_THREADS`/`WEB_CONCURRENCY`, `ACTIVE_RECORD_ENCRYPTION_*` (MFA/2FA), `SMTP_*` + `MAILER_SENDER_EMAIL` (outbound email)

### Deployment Dependencies

- Railway Hobby plan or higher (4 always-on services)
- 3 volumes: `chatwoot-data` (`/app/storage`), postgres data, redis data
- No external services required; add SMTP variables to enable outbound email
