#!/bin/sh
set -eu

HOST="${HOST:-0.0.0.0}"
PORT="${PORT:-4173}"
CACHE_DIR="${GEV_CACHE_DIR:-/app/.gev-cache}"
LOG_DIR="${GEV_LOG_DIR:-/app/.gev-logs}"
DIST_DIR="${GEV_DIST_DIR:-/tmp/gev-dist}"

mkdir -p "$CACHE_DIR" "$LOG_DIR"

# Serve a scratch copy so the image stays pristine and a container restart
# re-applies any changed provider keys.
rm -rf "$DIST_DIR"
cp -a /app/dist "$DIST_DIR"

node /usr/local/lib/gev/inject-runtime-keys.mjs "$DIST_DIR"

echo "[gev] starting God's Eye View on http://${HOST}:${PORT}/"
exec ./node_modules/.bin/vite preview --host "$HOST" --port "$PORT" --outDir "$DIST_DIR"
