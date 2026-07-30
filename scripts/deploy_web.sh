#!/usr/bin/env bash
# Build and deploy everything served at period.gabrielpenman.com:
#   /            the landing page (web/landing/)
#   /app/        the Flutter web build
#   /downloads/  packaged desktop builds
#
# Flutter SDK lives at /opt/flutter on h; the docroot is owned by gabriel,
# so this needs no sudo. The backend API is a separate systemd service
# (period-api) and is untouched by this script.
set -euo pipefail

export PATH="$PATH:/opt/flutter/bin"
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
dst="/var/www/period.gabrielpenman.com"
commit="$(git -C "$repo" rev-parse --short HEAD)"

cd "$repo/app"
flutter pub get

# --base-href matters: the web build is served from /app/, not the root, and
# without it every asset URL resolves against / and 404s.
flutter build web --release --base-href /app/
mkdir -p "$dst/app"
rsync -a --delete build/web/ "$dst/app"/

# Linux is the only desktop target buildable on this host: macOS and Windows
# need their own machines, and there is no Android SDK here. SKIP_LINUX=1
# shortens the loop when only the web build changed.
if [[ "${SKIP_LINUX:-}" != "1" ]]; then
  flutter build linux --release
  mkdir -p "$dst/downloads"
  tar -czf "$dst/downloads/sequence-linux-x64.tar.gz" \
    -C build/linux/x64/release bundle
fi

# Landing page last, and never with a bare --delete: app/ and downloads/ live
# under the same docroot and a plain mirror would wipe both.
rsync -a --delete --exclude app --exclude downloads \
  "$repo/web/landing/" "$dst"/

printf 'version=%s\nbuilt_at=%s\n' "$commit-web" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  > "$dst/build_info.txt"
echo "deployed $commit -> $dst"
