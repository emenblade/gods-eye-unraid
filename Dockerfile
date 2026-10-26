# syntax=docker/dockerfile:1.7
#
# God's Eye View in a container.
# Upstream: https://github.com/bilawalsidhu/gods-eye-view (MIT)
#
# The app is built once from a pinned upstream commit. Browser-side provider
# keys (Google Maps, Cesium ion, Mapillary) are compiled into the bundle, so the
# build uses sentinel values that the entrypoint replaces with the values you
# pass at container start. Server-side keys (OpenAI, AISStream, FIRMS, TomTom,
# OpenSky, Launch Library, Google server key) are read from the environment at
# runtime as usual.
#
# Bump GEV_REF to a newer upstream commit to update the image.

FROM node:24.14.0-bookworm-slim AS build

ARG GEV_REPOSITORY=https://github.com/bilawalsidhu/gods-eye-view.git
ARG GEV_REF=8b8ccc9a81379e8b40d4be67610570ee5b159512

ENV PUPPETEER_SKIP_DOWNLOAD=1 \
    NPM_CONFIG_FUND=false \
    NPM_CONFIG_AUDIT=false \
    GOOGLE_MAPS_API_KEY=__GEV_RUNTIME_GOOGLE_MAPS_API_KEY__ \
    CESIUM_ION_TOKEN=__GEV_RUNTIME_CESIUM_ION_TOKEN__ \
    MAPILLARY_CLIENT_TOKEN=__GEV_RUNTIME_MAPILLARY_CLIENT_TOKEN__

RUN apt-get update \
 && apt-get install -y --no-install-recommends git ca-certificates \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN git init -q \
 && git remote add origin "$GEV_REPOSITORY" \
 && git fetch --depth 1 origin "$GEV_REF" \
 && git checkout -q FETCH_HEAD \
 && rm -rf .git

RUN npm ci
RUN npm run build


FROM node:24.14.0-bookworm-slim AS runtime

LABEL org.opencontainers.image.title="God's Eye View" \
      org.opencontainers.image.description="Live OSINT globe: flights, ships, satellites, cameras, weather and more." \
      org.opencontainers.image.source="https://github.com/emenblade/gods-eye-unraid" \
      org.opencontainers.image.url="https://github.com/bilawalsidhu/gods-eye-view" \
      org.opencontainers.image.licenses="MIT"

ENV NODE_ENV=production \
    HOST=0.0.0.0 \
    PORT=4173 \
    GEV_CACHE_DIR=/app/.gev-cache \
    GEV_LOG_DIR=/app/.gev-logs \
    GEV_DIST_DIR=/tmp/gev-dist

WORKDIR /app

COPY --from=build /app /app
COPY docker-entrypoint.sh /usr/local/bin/gev-entrypoint.sh
COPY scripts/inject-runtime-keys.mjs /usr/local/lib/gev/inject-runtime-keys.mjs

RUN chmod 0755 /usr/local/bin/gev-entrypoint.sh \
 && mkdir -p /app/.gev-cache /app/.gev-logs

EXPOSE 4173

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:'+(process.env.PORT||4173)+'/').then((r)=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

ENTRYPOINT ["/usr/local/bin/gev-entrypoint.sh"]
