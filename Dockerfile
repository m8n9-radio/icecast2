FROM debian:bookworm-slim AS builder

# Install build dependencies for Icecast-KH
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

# Clone and build Icecast-KH (supports StreamUrl)
WORKDIR /build
RUN git clone --depth 1 https://github.com/karlheyes/icecast-kh.git && \
  cd icecast-kh && \
  autoreconf -fi && \
  ./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var && \
  make -j$(nproc) && \
  make DESTDIR=/install install

# Final image
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
  && rm -rf /var/lib/apt/lists/*

# Copy Icecast-KH from builder
COPY --from=builder /install/usr /usr

# Create icecast user and directories
RUN useradd -r -s /bin/false icecast && \
  mkdir -p /var/log/icecast /app && \
  chown -R icecast:icecast /var/log/icecast /app

WORKDIR /app

COPY --chown=icecast:icecast entrypoint.sh /entrypoint.sh
COPY --chown=icecast:icecast icecast.xml.template .

RUN chmod +x /entrypoint.sh

USER icecast

EXPOSE 8000

ENTRYPOINT ["/entrypoint.sh"]
CMD ["icecast", "-c", "/app/icecast.xml"]
