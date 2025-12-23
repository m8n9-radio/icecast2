#!/bin/bash
set -e

export TIMEZONE=${TIMEZONE:-UTC}

# Limits
export CLIENTS=${CLIENTS:-5000}
export SOURCES=${SOURCES:-50}
export QUEUE_SIZE=${QUEUE_SIZE:-1048576}
export CLIENT_TIMEOUT=${CLIENT_TIMEOUT:-30}
export HEADER_TIMEOUT=${HEADER_TIMEOUT:-15}
export SOURCE_TIMEOUT=${SOURCE_TIMEOUT:-10}
export BURST_SIZE=${BURST_SIZE:-65536}

# Authentication
export SOURCE_PASSWORD=${SOURCE_PASSWORD:-hackme}
export RELAY_PASSWORD=${RELAY_PASSWORD:-hackme}
export ADMIN_USER=${ADMIN_USER:-admin}
export ADMIN_PASSWORD=${ADMIN_PASSWORD:-hackme}

# Listen
export LISTEN_PORT=${LISTEN_PORT:-8000}
export LISTEN_IP=${LISTEN_IP:-0.0.0.0}

# Logging
export LOGLEVEL=${LOGLEVEL:-1}
export LOGDIR=${LOGDIR:-/var/log/icecast}

# Server info
export HOSTNAME=${HOSTNAME:-localhoxt}
export LOCATION=${LOCATION:-Unknown}
export ADMIN_EMAIL=${ADMIN_EMAIL:-admin@example.com}

export WEBROOT=${WEBROOT:-/usr/share/icecast2/web}
export ADMINROOT=${ADMINROOT:-/usr/share/icecast2/admin}

export MOUNT_NAME=${MOUNT_NAME:-/stream}

# Generate configs from templates
envsubst < /etc/icecast/icecast.xml.template > /etc/icecast/icecast.xml

echo "========================================"
echo "   icecast: 0.0.0.0:$LISTEN_PORT"
echo " streaming: 0.0.0.0:$LISTEN_PORT$MOUNT_NAME"
echo "========================================"

exec "$@"
