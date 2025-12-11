FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    icecast2 \
    gettext-base \
    mime-support \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY entrypoint.sh /entrypoint.sh
COPY icecast.xml.template .

RUN chmod +x /entrypoint.sh

EXPOSE 8000

ENTRYPOINT ["/entrypoint.sh"]
CMD ["icecast2", "-c", "/etc/icecast2/icecast.xml"]
