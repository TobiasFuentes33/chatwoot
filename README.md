# Chatwoot

[![Deploy on Railway](https://railway.app/button.svg)](https://railway.com/deploy/chatwoot?utm_campaign=chatwoot)

Chatwoot is the open-source customer support platform — live chat, a shared omnichannel inbox (email, website widget, WhatsApp, Telegram, Twitter/X, and more), help center, and automations. The Intercom/Zendesk alternative you host yourself, with unlimited agents and conversations on the MIT-licensed Community Edition.

This template deploys the full production stack in one click: the Rails web app, the Sidekiq background worker (email delivery, webhooks, automations — the dashboard works without it, but nothing is ever sent), PostgreSQL 16 with pgvector, and Redis.

## Deploy and Host

Click **Deploy on Railway** above. The form has zero fields — every value is auto-generated or auto-wired:

- `SECRET_KEY_BASE` — generated (64-char Rails signing secret, shared with the worker by reference)
- `FRONTEND_URL` — auto-filled from your Railway domain
- `POSTGRES_PASSWORD` — generated; the app and worker wire it via `${{postgres.POSTGRES_PASSWORD}}`
- `REDIS_URL` — auto-wired over the private network

On first boot the entrypoint waits for Postgres/Redis, runs the idempotent `db:chatwoot_prepare` (schema + seed on first boot, migrations after), and starts the server. Open the public URL and the setup wizard walks you through creating your administrator account, company, and first inbox.

## Why Deploy

- **No per-agent pricing.** Chatwoot Cloud charges per agent; self-hosted CE is unlimited agents, inboxes, and conversations.
- **Your data stays yours.** Conversations live in your Postgres, not a vendor's warehouse.
- **Always-on by design.** The web app + Sidekiq worker + Postgres + Redis run 24/7 — the shape Railway usage-based billing rewards.

## Common Use Cases

- Live-chat widget on a marketing site or docs portal
- Shared support inbox across email, chat, WhatsApp, and social channels
- Help center / knowledge base for a SaaS product
- Post-purchase support for a store (pairs well with an order-notification inbox)

## Configuration

Every variable the deployment consumes. Deploy-form variables are marked 🔧 (all auto-filled); baked image constants are marked 📦; optional upstream overrides are marked ➕.

| Variable | Service | Default | What it does |
|---|---|---|---|
| `SECRET_KEY_BASE` 🔧 | chatwoot, chatwoot-worker | `${{secret(64)}}` | Signs Rails sessions/cookies. Must be identical on web and worker (worker references the web service's value). |
| `FRONTEND_URL` 🔧 | chatwoot, chatwoot-worker | `https://${{RAILWAY_PUBLIC_DOMAIN}}` | Public base URL — used for links, OAuth callbacks, and the chat widget snippet. |
| `POSTGRES_HOST` 🔧 | chatwoot, chatwoot-worker | `${{postgres.RAILWAY_PRIVATE_DOMAIN}}` | Postgres host over the private network. |
| `POSTGRES_PASSWORD` 🔧 | chatwoot, chatwoot-worker, postgres | `${{secret(32)}}` (postgres) | Database password, generated once on the postgres service and referenced by the app. |
| `REDIS_URL` 🔧 | chatwoot, chatwoot-worker | `redis://${{redis.RAILWAY_PRIVATE_DOMAIN}}:6379` | Redis for cache, ActionCable, and Sidekiq queues. No password — private network only. |
| `POSTGRES_PORT` 📦 | chatwoot, chatwoot-worker | `5432` | Baked into the images. |
| `POSTGRES_USERNAME` 📦 | chatwoot, chatwoot-worker | `postgres` | Baked into the images. |
| `POSTGRES_DATABASE` 📦 | chatwoot, chatwoot-worker | `chatwoot_production` | Baked into the images. |
| `RAILS_ENV` / `NODE_ENV` 📦 | chatwoot, chatwoot-worker | `production` | Baked into the images. |
| `DATABASE_URL` ➕ | chatwoot, chatwoot-worker | *(composed from PG\* parts)* | Overrides the entrypoint-composed connection string when set explicitly. |
| `ENABLE_ACCOUNT_SIGNUP` ➕ | chatwoot | `false` (upstream default) | Set `true` to let anyone register new accounts; the first-run setup wizard always works regardless. |
| `FORCE_SSL` ➕ | chatwoot | `false` | Set `true` to force HTTPS + HSTS (Railway already terminates TLS). |
| `HELPCENTER_URL` ➕ | chatwoot | — | Dedicated URL for help-center pages. |
| `DEFAULT_LOCALE` ➕ | chatwoot | `en` | Default language for new accounts. |
| `RAILS_MAX_THREADS` / `WEB_CONCURRENCY` ➕ | chatwoot | `5` / unset | Puma tuning; raise `WEB_CONCURRENCY` on larger plans. |
| `ACTIVE_RECORD_ENCRYPTION_*` ➕ | chatwoot, chatwoot-worker | — | `PRIMARY_KEY`, `DETERMINISTIC_KEY`, `KEY_DERIVATION_SALT` — required only for MFA/2FA (generate via `rails db:encryption:init`). |
| `SMTP_*` ➕ | chatwoot, chatwoot-worker | — | `SMTP_ADDRESS`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `SMTP_DOMAIN`, `SMTP_AUTHENTICATION`, `SMTP_ENABLE_STARTTLS_AUTO`, `SMTP_OPENSSL_VERIFY_MODE` — required for outbound email (password resets, notifications). `MAILER_SENDER_EMAIL` sets the from-address. |

### Practical detail

- **Runtime / memory:** Ruby 3.4 / Rails 8 + Sidekiq. Plan for ~1–1.5 GB for the web service and ~0.5–1 GB for the worker at rest; Postgres + Redis are small. Upstream recommends 2 CPU / 4 GB minimum for the stack.
- **Port:** the server honors Railway's injected `PORT` (no hardcoded port anywhere).
- **Persistence:** `/app/storage` (ActiveStorage uploads) on a volume on the web service; Postgres data on its own volume (`PGDATA` subdir); Redis AOF on its own volume. Known limitation: Railway volumes attach to a single service, so the worker has no `/app/storage` volume — background jobs that need web-uploaded files (e.g. some attachment processing) may not find them. Core messaging, email, and webhooks are unaffected.
- **Healthcheck:** unauthenticated `GET /health` returns `{"status":"woot"}`.
- **First run:** the setup wizard at `/` creates the admin account — no env configuration needed.

### Deployment Dependencies

- Railway Hobby plan or higher (4 always-on services: web, worker, Postgres, Redis).
- 3 volumes: `chatwoot-data` (`/app/storage`), postgres data, redis data.
- No external services required. Add SMTP variables when you want outbound email.

## Source

- Upstream: [chatwoot/chatwoot](https://github.com/chatwoot/chatwoot) (MIT, Community Edition image `chatwoot/chatwoot:v4.18.0-ce`)
- Wrapper: this repo — pinned digests, Railway entrypoints, one-click template wiring.
