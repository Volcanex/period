#!/usr/bin/env bash
# Build the Flutter web client and deploy it to the nginx docroot on h.
#
# Flutter SDK lives at /opt/flutter on h; the docroot is owned by gabriel,
# so this needs no sudo. The backend API is a separate systemd service
# (period-api) and is untouched by this script.
set -euo pipefail

export PATH="$PATH:/opt/flutter/bin"
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
dst="/var/www/period.gabrielpenman.com"

cd "$repo/app"
flutter pub get
flutter build web --release

rsync -a --delete build/web/ "$dst"/
commit="$(git -C "$repo" rev-parse --short HEAD)"
printf 'version=%s\nbuilt_at=%s\n' "$commit-web" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$dst/build_info.txt"
echo "deployed $commit -> $dst"
