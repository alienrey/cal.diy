#!/bin/sh
set -eu

# Replace the statically built BUILT_NEXT_PUBLIC_WEBAPP_URL with run-time NEXT_PUBLIC_WEBAPP_URL
# NOTE: if these values are the same, this will be skipped.
scripts/replace-placeholder.sh "$BUILT_NEXT_PUBLIC_WEBAPP_URL" "$NEXT_PUBLIC_WEBAPP_URL"

# Published images must pick up each deployment's API URL without rebuilding the web bundle.
if [ -n "${BUILT_NEXT_PUBLIC_API_V2_URL:-}" ] && [ -n "${NEXT_PUBLIC_API_V2_URL:-}" ]; then
  scripts/replace-placeholder.sh "$BUILT_NEXT_PUBLIC_API_V2_URL" "$NEXT_PUBLIC_API_V2_URL"
fi

scripts/wait-for-it.sh "$DATABASE_HOST" -- echo "database is up"
npx prisma migrate deploy --schema /calcom/packages/prisma/schema.prisma
npx ts-node --transpile-only /calcom/scripts/seed-app-store.ts
yarn start
