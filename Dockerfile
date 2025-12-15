FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    icecast2 \
    nginx \
    gettext-base \
    mime-support \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY entrypoint.sh /entrypoint.sh
COPY icecast.xml.template .
COPY nginx.conf.template /etc/nginx/nginx.conf.template
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN chmod +x /entrypoint.sh && \
    mkdir -p /var/log/nginx /var/cache/nginx/icecast && \
    chown -R www-data:www-data /var/cache/nginx && \
    rm -f /etc/nginx/sites-enabled/default

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
