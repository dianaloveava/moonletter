#!/usr/bin/env node
// Rasterizes app/assets/icon/*.svg into every icon asset the app ships:
// Android launcher/adaptive icons, the Windows .ico and in-app PNG logos.
//
//   cd tools/icon-gen && npm install && node gen.mjs
//
// Outputs are committed to the repository so a normal build needs no Node.
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { dirname, resolve, relative } from 'node:path';
import { fileURLToPath } from 'node:url';
import { Resvg } from '@resvg/resvg-js';
import pngToIco from 'png-to-ico';

const here = dirname(fileURLToPath(import.meta.url));
const repo = resolve(here, '..', '..');
const iconDir = resolve(repo, 'app/assets/icon');
const resDir = resolve(repo, 'app/android/app/src/main/res');
const windowsRes = resolve(repo, 'app/windows/runner/resources');

const svgSource = (name) => readFileSync(resolve(iconDir, name), 'utf8');

function render(source, width) {
  const resvg = new Resvg(source, { fitTo: { mode: 'width', value: width } });
  return resvg.render().asPng();
}

function out(path, bytes) {
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, bytes);
  console.log(`${relative(repo, path).split('\\').join('/')}  ${bytes.length} B`);
}

const app = svgSource('moonletter.svg');
const foreground = svgSource('moonletter-adaptive-fg.svg');
const background = svgSource('moonletter-adaptive-bg.svg');

// In-app logo (about page, lock screen) and the Windows tray icon (tray_manager
// takes a file path, and Windows needs .ico there).
out(resolve(iconDir, 'logo_512.png'), render(app, 512));
out(resolve(iconDir, 'tray_32.png'), render(app, 32));
out(resolve(iconDir, 'tray.ico'), await pngToIco([16, 24, 32, 48].map((size) => render(app, size))));

// Android legacy launcher icons.
const legacy = { mdpi: 48, hdpi: 72, xhdpi: 96, xxhdpi: 144, xxxhdpi: 192 };
for (const [density, size] of Object.entries(legacy)) {
  out(resolve(resDir, `mipmap-${density}/ic_launcher.png`), render(app, size));
}

// Android adaptive icons: 108dp canvas, 66dp safe zone.
const adaptive = { mdpi: 108, hdpi: 162, xhdpi: 216, xxhdpi: 324, xxxhdpi: 432 };
for (const [density, size] of Object.entries(adaptive)) {
  out(resolve(resDir, `mipmap-${density}/ic_launcher_foreground.png`), render(foreground, size));
  out(resolve(resDir, `mipmap-${density}/ic_launcher_background.png`), render(background, size));
}
out(
  resolve(resDir, 'mipmap-anydpi-v26/ic_launcher.xml'),
  [
    '<?xml version="1.0" encoding="utf-8"?>',
    '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">',
    '    <background android:drawable="@mipmap/ic_launcher_background" />',
    '    <foreground android:drawable="@mipmap/ic_launcher_foreground" />',
    '</adaptive-icon>',
    '',
  ].join('\n'),
);

// Windows .ico (multi-resolution).
const icoSizes = [16, 24, 32, 48, 64, 128, 256];
const ico = await pngToIco(icoSizes.map((size) => render(app, size)));
out(resolve(windowsRes, 'app_icon.ico'), ico);
