#!/usr/bin/env node
/**
 * Replace the build-time sentinels in the browser bundle with the values from
 * the container environment.
 *
 * Google Maps, Cesium ion and Mapillary tokens are compiled into the client by
 * Vite's `define`, so a prebuilt image cannot read them at request time. The
 * Dockerfile builds with sentinel strings; this script substitutes the real
 * values into a scratch copy of `dist` on every container start.
 */
import { readdirSync, readFileSync, writeFileSync } from 'node:fs';
import { extname, join } from 'node:path';

const distDir = process.argv[2];
if (!distDir) {
  console.error('[gev] usage: inject-runtime-keys.mjs <dist-dir>');
  process.exit(2);
}

const replacements = {
  __GEV_RUNTIME_GOOGLE_MAPS_API_KEY__: process.env.GOOGLE_MAPS_API_KEY || '',
  __GEV_RUNTIME_CESIUM_ION_TOKEN__: process.env.CESIUM_ION_TOKEN || '',
  __GEV_RUNTIME_MAPILLARY_CLIENT_TOKEN__:
    process.env.MAPILLARY_CLIENT_TOKEN || '',
};

const files = [];
const walk = (dir) => {
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const fullPath = join(dir, entry.name);
    if (entry.isDirectory()) walk(fullPath);
    else if (extname(entry.name) === '.js') files.push(fullPath);
  }
};
walk(distDir);

let injected = 0;
for (const file of files) {
  let text = readFileSync(file, 'utf8');
  let changed = false;

  for (const [sentinel, value] of Object.entries(replacements)) {
    const encoded = JSON.stringify(value);
    for (const quote of ['"', "'"]) {
      const needle = `${quote}${sentinel}${quote}`;
      if (!text.includes(needle)) continue;
      text = text.split(needle).join(encoded);
      changed = true;
      injected += 1;
    }
  }

  if (changed) writeFileSync(file, text);
}

const leftovers = files.filter((file) => {
  const text = readFileSync(file, 'utf8');
  return Object.keys(replacements).some((sentinel) => text.includes(sentinel));
});

if (leftovers.length > 0) {
  console.error(
    `[gev] could not replace runtime key sentinels in: ${leftovers.join(', ')}`,
  );
  process.exit(1);
}

console.log(
  `[gev] applied runtime browser keys (${injected} replacement${
    injected === 1 ? '' : 's'
  })`,
);
