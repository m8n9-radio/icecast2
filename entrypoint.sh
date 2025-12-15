#!/bin/bash
set -e

# Default values
export TIMEZONE=${TIMEZONE:-UTC}
export CLIENTS=${CLIENTS:-10000}
export SOURCES=${SOURCES:-100}
export THREADPOOL=${THREADPOOL:-128}
export QUEUE_SIZE=${QUEUE_SIZE:-524288}
export CLIENT_TIMEOUT=${CLIENT_TIMEOUT:-30}
export HEADER_TIMEOUT=${HEADER_TIMEOUT:-15}
export SOURCE_TIMEOUT=${SOURCE_TIMEOUT:-10}
export BURST_ON_CONNECT=${BURST_ON_CONNECT:-1}
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
export LOGDIR=${LOGDIR:-/var/log/icecast2}
export ACCESSLOGDIR=${ACCESSLOGDIR:-/var/log/icecast2}

# Server info
export HOSTNAME=${HOSTNAME:-localhost}
export LOCATION=${LOCATION:-Unknown}
export ADMIN_EMAIL=${ADMIN_EMAIL:-admin@localhost}

# Webroot
export WEBROOT=${WEBROOT:-/usr/share/icecast2/web}
export ADMINROOT=${ADMINROOT:-/usr/share/icecast2/admin}

# Mount defaults
export MOUNT_NAME=${MOUNT_NAME:-/stream}
export MOUNT_DESC=${MOUNT_DESC:-Default Stream}
export MOUNT_GENRE=${MOUNT_GENRE:-Various}
export MOUNT_BITRATE=${MOUNT_BITRATE:-128}
export MOUNT_PUBLIC=${MOUNT_PUBLIC:-1}
export MOUNT_MAXLISTENERS=${MOUNT_MAXLISTENERS:-0}
export MOUNT_FALLBACK=${MOUNT_FALLBACK:-}

# Security
export TLS_ENABLED=${TLS_ENABLED:-false}
export TLS_CERT=${TLS_CERT:-}
export TLS_KEY=${TLS_KEY:-}

# Buffer
export BUFFER_SIZE=${BUFFER_SIZE:-4096}
export BUFFER_DURATION=${BUFFER_DURATION:-0}

# Stats
export STATS_ENABLED=${STATS_ENABLED:-true}
export STATS_PORT=${STATS_PORT:-}

# Master relay
export MASTER_RELAY=${MASTER_RELAY:-false}
export MASTER_HOST=${MASTER_HOST:-}
export MASTER_PORT=${MASTER_PORT:-8000}
export MASTER_MOUNT=${MASTER_MOUNT:-}
export MASTER_RELAY_AUTH=${MASTER_RELAY_AUTH:-false}

# Generate Icecast configuration
envsubst < /app/icecast.xml.template > /etc/icecast2/icecast.xml

# Generate Nginx configuration with MOUNT_NAME variable
envsubst '${MOUNT_NAME}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

# Set timezone
ln -snf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
echo $TIMEZONE > /etc/timezone

# Create required directories and set permissions
mkdir -p /var/log/supervisor /var/run/supervisor /var/log/icecast2 /var/run/icecast2

# Create log files with correct ownership BEFORE supervisord starts
touch /var/log/icecast2/access.log /var/log/icecast2/error.log
chown -R icecast2:icecast /etc/icecast2 /var/log/icecast2 /var/run/icecast2 2>/dev/null || true
chown -R www-data:www-data /var/cache/nginx /var/log/nginx 2>/dev/null || true
chmod 755 /var/log/icecast2 /var/run/icecast2
chmod 644 /var/log/icecast2/*.log

echo "========================================"
echo "Icecast2 + Nginx Proxy Configuration"
echo "========================================"
echo "Timezone: $TIMEZONE"
echo "Icecast port (internal): $LISTEN_PORT"
echo "Nginx port (external): 80"
echo "Max clients: $CLIENTS"
echo "========================================"

exec "$@"
