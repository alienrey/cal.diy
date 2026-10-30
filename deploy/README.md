# Deploy with Coolify

To pull your own prebuilt web/API images on any Docker server, see [Deploy published container images](containers.md). That configuration also works with Coolify's Docker Compose build pack.

## Build images on the server

The root `docker-compose.yml` builds the web app and API v2 from this repository and starts PostgreSQL and Redis with persistent volumes. It does not require a local `.env` file.

1. Create an Application from this Git repository in Coolify and choose **Docker Compose** as the build pack.
2. Set the base directory to `/` and the Compose location to `/docker-compose.yml`, then load the Compose file. Use Coolify's normal Compose deployment mode so it manages proxy routing and networks.
3. Coolify generates web and API subdomains using the server's wildcard domain, plus the database password, authentication secrets, encryption key, and cron secret. No manual URL or secret setup is needed. Confirm both generated domains appear before deploying.
4. Configure `EMAIL_FROM` and the `EMAIL_SERVER_*` variables for outgoing mail, then deploy. The web app applies database migrations at startup; the API waits for it to become healthy.

The generated values are shared wherever the same variable is referenced:

| Coolify variable | Used for |
| --- | --- |
| `SERVICE_URL_CALCOM_3000` | Web app URL, website URL, authentication URL, and the API's web app link. Routes to container port 3000. |
| `SERVICE_URL_CALCOM_API_80` | API origin and the web app's API v2 URL (with `/v2` appended). Routes to container port 80. |
| `SERVICE_PASSWORD_64_POSTGRES` | PostgreSQL password and all application database URLs. |
| `SERVICE_BASE64_64_NEXTAUTH` | Shared authentication secret. |
| `SERVICE_BASE64_CALENDSO` | Encryption key; Coolify generates exactly 32 alphanumeric characters. |
| `SERVICE_BASE64_64_JWT` | API JWT signing secret. |
| `SERVICE_PASSWORD_64_CRON` | Cron authentication secret. |

To switch to custom domains later, edit the domains for `calcom` and `calcom-api` in Coolify and rebuild/redeploy. Keep routing to container ports 3000 and 80 respectively. Coolify updates the generated service URLs from the domain configuration; the web bundle and rewrites need a rebuild to pick up those URLs. You do not need to edit Compose or enter `API_URL` manually.

Coolify stores generated secrets across redeployments. When adopting this configuration for an existing installation, copy the current database password and application secrets into the corresponding generated variables before deploying to preserve database access, sessions, and encrypted credentials. Additional integrations require corresponding `environment` entries before setting their values in Coolify.

Stripe defaults are inert placeholders so API v2 can start without billing credentials. Set real `STRIPE_API_KEY`, `STRIPE_WEBHOOK_SECRET`, and price IDs before enabling billing. Keep database credentials and encryption/authentication secrets stable across redeployments.

PostgreSQL is pinned to major version 18 with its matching data volume path. Reusing a deployment from another PostgreSQL major version requires a database migration; do not point this image at incompatible existing data.

Prisma Studio is disabled by default through the `studio` profile. For temporary administration on the server, run `docker compose --profile studio up -d studio` with the same deployment environment and use an SSH tunnel to port 5555. Studio is bound to the server's loopback interface because it has no authentication.

Outside Coolify, supply the `SERVICE_*` values listed above yourself before validating or running Compose; Docker Compose does not generate them. Syntax can be checked without starting containers:

```sh
docker compose config --quiet
docker compose --profile studio config --quiet
```

See [Coolify's Docker Compose documentation](https://coolify.io/docs/applications/builds/docker-compose) for domain routing and deployment settings.
