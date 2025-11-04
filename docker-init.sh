#!/bin/sh
# Simple init script to fix /data permissions
mkdir -p /data
chown -R nobody:nogroup /data 2>/dev/null || true
chmod -R 755 /data 2>/dev/null || true
