#!/bin/sh
set -e

# Fix permissions
mkdir -p /data
chown -R nobody:nogroup /data 2>/dev/null || true
chmod -R 755 /data 2>/dev/null || true

# Execute the command (run as current user - root in Fly.io)
exec "$@"
