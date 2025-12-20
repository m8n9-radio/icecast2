#!/bin/bash
set -e

# Default values
export TIMEZONE=${TIMEZONE:-UTC}
export CLIENTS=${CLIENTS:-10000}
export SOURCES=${SOURCES:-100}
export QUEUE_SIZE=${QUEUE_SIZE:-524288}
export CLIENT_TIMEOUT=${CLIENT_TIMEOUT:-30}
export HEADER_TIMEOUT=${HEADER_TIMEOUT:-15}
export SOURCE_TIMEOUT=${SOURCE_TIMEOUT:-10}
export BURST_SIZE=${BURST_SIZE:-65536}

# Authentication
export SOURCE_PASSWORD=${SOURCE_PASSWORD:-hackme}
export RELAY_PASSWORD=${RELAY_PASSWORD:-hackme}
export ADMIN_USER=${ADMIN_USER:-admin}
export ADMIN_PASSWORD=${ADMIN_PASSWORD:-hackme}

# Listen socket
export LISTEN_PORT=${LISTEN_PORT:-8000}
export LISTEN_IP=${LISTEN_IP:-0.0.0.0}

# Logging
export LOGLEVEL=${LOGLEVEL:-3}
export LOGDIR=${LOGDIR:-/var/log/icecast}

# Server info
export HOSTNAME=${HOSTNAME:-localhost}
export LOCATION=${LOCATION:-Unknown}
export ADMIN_EMAIL=${ADMIN_EMAIL:-admin@localhost}

# Webroot
export WEBROOT=${WEBROOT:-/usr/share/icecast2/web}
export ADMINROOT=${ADMINROOT:-/usr/share/icecast2/admin}

# Mount
export MOUNT_NAME=${MOUNT_NAME:-/stream}

# Generate Icecast configuration
envsubst < /app/icecast.xml.template > /app/icecast.xml

# Generate nginx configuration from template
envsubst '${MOUNT_NAME}' < /etc/nginx/conf.d/icecast.conf.template > /etc/nginx/conf.d/icecast.conf

# Test nginx configuration
nginx -t

echo "========================================"
echo "Icecast 2.4.4 + Nginx Proxy"
echo "========================================"
echo "Icecast Port (internal): $LISTEN_PORT"
echo "Nginx Port (external): 80"
echo "Mount: $MOUNT_NAME"
echo "Stream URL: http://<host>/"
echo "Admin URL: http://<host>/admin"
echo "========================================"

exec "$@"
