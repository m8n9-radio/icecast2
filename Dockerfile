FROM debian:bookworm-slim AS builder
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    autoconf \
    automake \
    libtool \
    pkg-config \
    libxml2-dev \
    libxslt1-dev \
    libvorbis-dev \
    libtheora-dev \
    libspeex-dev \
    libcurl4-openssl-dev \
    libogg-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /build
RUN git clone --depth 1 https://github.com/karlheyes/icecast-kh.git && \
    cd icecast-kh && \
    autoreconf -fi && \
    ./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var && \
    make -j$(nproc) && \
    make DESTDIR=/install install


FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y \
    gettext-base \
    libxml2 \
    libxslt1.1 \
    libvorbis0a \
    libvorbisenc2 \
    libtheora0 \
    libspeex1 \
    libcurl4 \
    libogg0 \
    libssl3 \
    nginx \
    supervisor \
    && rm -rf /var/lib/apt/lists/*
COPY --from=builder /install/usr /usr
RUN useradd -r -s /bin/false icecast && \
    mkdir -p /var/log/icecast /var/log/nginx /var/log/supervisor /etc/icecast /etc/supervisor/conf.d && \
    chown -R icecast:icecast /var/log/icecast
WORKDIR /app

# Copy config templates to standard locations
COPY icecast/icecast.xml.template /etc/icecast/
COPY nginx/nginx.conf /etc/nginx/
COPY nginx/conf.d/icecast.conf.template /etc/nginx/conf.d/
COPY supervisord/supervisord.conf /etc/supervisor/conf.d/

# Copy entrypoint
COPY entrypoint.sh /app/
RUN chmod +x /app/entrypoint.sh

EXPOSE 80
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
