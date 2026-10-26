# God's Eye View for Unraid

Unofficial Unraid Docker packaging for **[God's Eye View](https://github.com/bilawalsidhu/gods-eye-view)** by Bilawal Sidhu: live flights, ships, satellites, earthquakes, public cameras, weather, radio and more on a photorealistic 3D globe.

- Image: `ghcr.io/emenblade/gods-eye-unraid:latest`
- Web UI: `http://YOUR-SERVER-IP:4173`
- Starts keyless. All provider keys are optional.
- Upstream project is MIT licensed. This packaging repo is MIT licensed too.

> Not affiliated with the upstream author. If you like it, star the
> [original repo](https://github.com/bilawalsidhu/gods-eye-view).

---

## Install on Unraid

### Option 1: user template (recommended)

1. Copy [`unraid/gods-eye-view.xml`](unraid/gods-eye-view.xml) to your server:
   - Share: `/boot/config/plugins/dockerMan/templates-user/my-Gods-Eye-View.xml`
   - Or from a terminal: `cp /path/to/gods-eye-view.xml /boot/config/plugins/dockerMan/templates-user/my-Gods-Eye-View.xml`
2. In the Unraid web UI: **Docker** tab -> **Add Container**.
3. Choose **Gods-Eye-View** from the **Template** dropdown.
4. Set any optional keys under **Show more settings**, then click **Apply**.
5. Open `http://YOUR-SERVER-IP:4173`.

The template also carries its own `TemplateURL`, so once installed Unraid can
fetch updates to the template itself.

### Option 2: docker run

```bash
docker run -d \
  --name Gods-Eye-View \
  --restart unless-stopped \
  -p 4173:4173 \
  -v /mnt/user/appdata/gods-eye-view/cache:/app/.gev-cache \
  -v /mnt/user/appdata/gods-eye-view/logs:/app/.gev-logs \
  ghcr.io/emenblade/gods-eye-unraid:latest
```

### Option 3: docker compose

```bash
cp .env.example .env   # optional keys
docker compose up -d
```

---

## First run

1. Open `http://YOUR-SERVER-IP:4173`.
2. Pick **LIVE CONTACTS**, **SPACE MISSIONS**, **ENVIRONMENTAL**, or **EXPLORE MANUALLY**.
3. Flights, military traffic, satellites, earthquakes, public cameras, radio and launches work with no keys.

Map imagery starts on the keyless Esri satellite basemap with a keyless terrain
fallback. Add a Cesium ion token for photorealistic Google 3D cities.

### Accessing by hostname

IP addresses always work. If you open the app as `tower.local`,
`globe.example.com`, or through a reverse proxy, set:

```
GEV_ALLOWED_HOSTS=tower.local,globe.example.com
```

and restart the container. This is the app's Host-header allowlist; without it
the server answers only localhost and IP addresses.

---

## Optional keys

Set these as container variables (Unraid: **Show more settings**). No keys are
required to start.

| Variable | What it enables | Cost |
| --- | --- | --- |
| `CESIUM_ION_TOKEN` | Google Photorealistic 3D cities, world terrain | Free token, personal/non-commercial terms |
| `GOOGLE_MAPS_API_KEY` | Direct Google 3D plus Google place search | Metered |
| `GOOGLE_MAPS_SERVER_API_KEY` | Places and Street View on the server side (falls back to the key above) | Metered |
| `MAPILLARY_CLIENT_TOKEN` | Street Level photos | Free |
| `OPENAI_API_KEY` | Voice control and the AI HUD summary | Metered |
| `AISSTREAM_API_KEY` | Live vessels | Free |
| `FIRMS_MAP_KEY` | Active fires | Free |
| `TOMTOM_API_KEY` | Live traffic flow speeds | Free tier |
| `OPENSKY_CLIENT_ID` / `OPENSKY_CLIENT_SECRET` | Higher flight polling limits | Free |
| `LL2_API_TOKEN` | Higher space-mission allowance | Free |

Restart the container after changing keys.

### Why not the POWER UP panel?

Upstream's in-app **POWER UP** Provider Settings panel only accepts requests
from loopback and only exists on the dev server. In a container published to
your LAN it is intentionally unavailable, so configure keys as environment
variables instead. This is the same set of variables the app reads.

### How browser keys are handled

Google Maps, Cesium ion and Mapillary tokens are compiled into the browser
bundle by Vite. This image builds with placeholders and the container entrypoint
substitutes your runtime values into a scratch copy of the built app on every
start, so prebuilt images still honor the variables above. The tokens are
visible in browser devtools by design; restrict them at the provider.

All other keys stay server-side and are brokered through the app's local proxy.

---

## Data and persistence

| Container path | Unraid path | Contents |
| --- | --- | --- |
| `/app/.gev-cache` | `/mnt/user/appdata/gods-eye-view/cache` | Satellite TLEs, terrain, traffic, imagery and Overpass caches. Safe to clear while stopped. |
| `/app/.gev-logs` | `/mnt/user/appdata/gods-eye-view/logs` | Application logs. Voice transcript logging is opt-in upstream. |

The app itself is stateless; configuration lives in the Unraid template.

---

## Updating

The image is built from a pinned upstream commit. To update:

1. Bump `GEV_REF` in [`Dockerfile`](Dockerfile) to a newer upstream commit.
2. Push to `main`; the GitHub Actions workflow rebuilds and publishes
   `ghcr.io/emenblade/gods-eye-unraid:latest`.
3. In Unraid, click **Check for Updates** / **Force Update** on the container.

Changing keys only needs a container restart, not a rebuild.

---

## Build locally

```bash
docker build -t gods-eye-unraid .
docker run --rm -p 4173:4173 gods-eye-unraid
```

Requirements: Docker with BuildKit. The build fetches the upstream source at the
pinned commit, runs `npm ci`, builds the Vite app, and packages a pinned Node 24
runtime.

---

## Voice and HTTPS

Browsers only grant microphone access on HTTPS (or `localhost`). Voice control
therefore needs a TLS reverse proxy (Nginx Proxy Manager, SWAG, Caddy, Traefik,
and so on) in front of `http://YOUR-SERVER-IP:4173`. Add the proxy hostname to
`GEV_ALLOWED_HOSTS` and restart the container. Enable WebSocket upgrade support
in the proxy as well: live vessels, HLS camera video and the Realtime voice
session all use long-lived connections. Every non-microphone feature works over
plain HTTP on the LAN.

## Security notes

- The container brokers provider API keys. Keep it on your LAN or behind your
  own authenticated reverse proxy; do not expose port 4173 directly to the
  internet.
- Browser-side keys (`GOOGLE_MAPS_API_KEY`, `CESIUM_ION_TOKEN`,
  `MAPILLARY_CLIENT_TOKEN`) are visible to anyone who can load the page. Use
  provider-side restrictions and budget alerts.
- The container runs as root by default so the Unraid appdata bind mounts work
  without PUID/PGID tuning. It listens on 4173 and does not need privileged
  mode.

---

## Credits and license

- God's Eye View: [bilawalsidhu/gods-eye-view](https://github.com/bilawalsidhu/gods-eye-view), MIT.
- Unraid packaging, Dockerfile and template: emenblade, MIT. See [LICENSE](LICENSE).
