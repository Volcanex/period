#!/bin/sh
# Container entrypoint: start the backend contract API.
set -eu

cd /app
exec python3 server.py
