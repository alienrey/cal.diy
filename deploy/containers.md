# Deploy published container images

The **Publish containers** GitHub Actions workflow publishes your own web and API images:

```text
ghcr.io/alienrey/cal.diy-web:latest
ghcr.io/alienrey/cal.diy-api:latest
```

Both images support Linux AMD64 and ARM64. Docker automatically pulls the correct architecture for the server. No application source code, Yarn, or build server is needed on the deployment server.

## Publish updates

Merge the configuration into `main` and wait for **Publish containers** in GitHub Actions. Every push to `main` and every `v*` release tag builds updated images. You can also run the workflow manually. It checks types, builds web/API images on native x86/ARM runners, and starts the full stack against disposable databases on both architectures. Only after migrations, health checks, and runtime API rewrite verification pass does it publish the combined multi-platform commit tags and update `latest`.

Images are named from the current GitHub repository, so a fork under another account publishes into that account's GHCR namespace. Individual architecture tags are build candidates until the entire workflow succeeds. Manual builds from other branches and same-repository pull requests that change the container configuration publish verified commit tags without changing `latest`. Pull requests from forks cannot publish images. No workflow deploys to a server automatically.

The workflow uses GitHub's provided `GITHUB_TOKEN`; Docker Hub credentials are unnecessary. After the first publication, open each package in your GitHub profile's **Packages** section and either make it public or authenticate each deployment server with a token that has `read:packages`. A public Git repository does not automatically make its container packages public.

For private images, run the following command and enter the token at the password prompt:

```sh
docker login ghcr.io --username YOUR_GITHUB_USERNAME
```

## Deploy on any Docker server

Copy `docker-compose.registry.yml` and `deploy/containers.env.example` onto the server. Docker Engine and the Docker Compose plugin must be installed. Place both files in the same deployment directory, then:

```sh
cp containers.env.example .env
```

Edit `.env` and fill in each required secret. Generate a separate value with `openssl rand -hex 32` for `POSTGRES_PASSWORD`, `NEXTAUTH_SECRET`, `JWT_SECRET`, and `CRON_API_KEY`. Use `openssl rand -hex 16` for the exactly 32-character `CALENDSO_ENCRYPTION_KEY`. Set `NEXT_PUBLIC_WEBAPP_URL` and `API_URL` to the web and API origins clients will use, including the scheme and any nonstandard port. Configure mail settings for outgoing email.

```sh
docker compose -f docker-compose.registry.yml config --quiet
docker compose -f docker-compose.registry.yml up -d --wait --wait-timeout 600
```

The stack starts PostgreSQL, Redis, the web app on port 3000, and API v2 on port 5555. The web app applies database migrations before the API starts. PostgreSQL and Redis use persistent named volumes. `WEB_PORT` and `API_PORT` change the published host ports; update public URLs to match. For HTTPS, route your domain through a reverse proxy to these ports.

The web app proxies API requests to `http://calcom-api:80/v2` over the Docker network by default. Override `NEXT_PUBLIC_API_V2_URL` only when using an API hosted elsewhere. Web and API URL configuration is applied when the web container starts, so the same image works with different domains on different servers.

Other build settings, including organization mode, are baked into the images. Configure the GitHub Actions repository variables `NEXT_PUBLIC_SINGLE_ORG_SLUG`, `ORGANIZATIONS_ENABLED`, `NEXT_PUBLIC_LICENSE_CONSENT`, `NEXT_PUBLIC_WEBSITE_TERMS_URL`, `NEXT_PUBLIC_WEBSITE_PRIVACY_POLICY_URL`, or `CSP_POLICY` before rebuilding if needed. Match organization settings in the server's `.env`.

## Pull an update or choose a version

To update to the latest successful build:

```sh
docker compose -f docker-compose.registry.yml pull
docker compose -f docker-compose.registry.yml up -d --wait --wait-timeout 600
```

Set `CALCOM_IMAGE_TAG` in `.env` to `sha-<full-commit-sha>` or a successful `v*` release tag to use a specific version, then run the same commands. Both application services use the same tag. Set `CALCOM_IMAGE_NAMESPACE` to the image prefix if publishing from another repository, for example `ghcr.io/your-account/cal.diy`; image names append `-web` and `-api`.

Back up PostgreSQL before upgrading. An older image does not reverse migrations; verify schema compatibility before rolling back. Keep the same Compose project/deployment directory, database volume, and secrets across updates. PostgreSQL is version 18 and its data volume cannot be reused directly from another PostgreSQL major version.

## Use with Coolify

Select the Docker Compose build pack and `/docker-compose.registry.yml` as the Compose location, or paste the file into a Docker Compose service. Enter the same required secrets and public URLs in Coolify and configure the domains to route to container ports 3000 and 80. Authenticate the deployment server if the GHCR packages are private. Deploy whenever you want to pull the selected image tag.

When switching an existing installation, retain the same Coolify resource, volumes, and saved secret values. Map the previous generated `SERVICE_*` secret values to the corresponding variables in `containers.env.example` before deploying. The source-build configuration remains available at `/docker-compose.yml`.

See [Coolify's registry documentation](https://coolify.io/docs/applications/builds/docker-registries) for registry access and [GitHub's container registry documentation](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry) for package authentication and visibility.
