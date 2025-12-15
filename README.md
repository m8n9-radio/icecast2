# Icecast2 Streaming Server

Server de streaming audio Icecast2 containerizat cu Docker, configurabil prin variabile de mediu.

## Descriere

Acest serviciu oferă un server Icecast2 complet configurabil pentru streaming audio live. Suportă multiple formate audio (MP3, Vorbis, Opus, etc.) și permite multiple surse și ascultători simultani.

## Caracteristici

- ✅ Configurare completă prin variabile de mediu
- ✅ Suport pentru multiple mount points
- ✅ Autentificare configurabilă pentru surse și admin
- ✅ Logging customizabil
- ✅ Optimizat pentru performanță
- ✅ Fără warning-uri la pornire
- ✅ Suport MIME types complet
- ✅ **Nginx reverse proxy integrat** cu optimizări pentru streaming
- ✅ **CORS headers** configurate pentru web players
- ✅ **Caching inteligent** - cache pentru assets statice, fără cache pentru streaming
- ✅ **Long-lived connections** pentru streaming continuu
- ✅ **Zero buffering** pe stream-uri pentru latență minimă

## Arhitectură

Imaginea Docker conține 2 servicii care rulează împreună prin **supervisord**:

1. **Icecast2** (port intern 8000) - server de streaming audio
2. **Nginx** (port extern 80) - reverse proxy optimizat pentru streaming

```
Client → Nginx :80 → Icecast :8000
```

### Avantaje Nginx Proxy

- **Performanță**: Nginx gestionează eficient conexiunile simultane
- **Caching**: Assets statice (web interface) sunt cached, stream-urile NU
- **CORS**: Headers configurate pentru web players din orice domeniu
- **Zero Buffering**: Stream-urile sunt proxied fără buffering pentru latență minimă
- **Long Timeouts**: Conexiuni de până la 1h pentru streaming continuu
- **Security Headers**: X-Frame-Options, X-Content-Type-Options, etc.

## Integrare cu Traefik

Containerul Icecast este configurat cu labels Traefik pentru reverse proxy automat pe `m8n9.local`.

### Configurație Implicită

Stream-ul va fi accesibil la: `http://m8n9.local/stream` (sau orice ai setat în `MOUNT_NAME`)

```
Client → Traefik (m8n9.local:80) → Nginx :80 → Icecast :8000
                                      ↓
                              Stream: /stream (MOUNT_NAME)
```

### Endpoints Accesibile prin Traefik

| Endpoint | URL | Descriere |
|----------|-----|-----------|
| **Stream Audio** | `http://m8n9.local${MOUNT_NAME}` | Stream principal (ex: `/stream`) |
| Web Interface | `http://m8n9.local/` | Pagina principală |
| Status | `http://m8n9.local/status.xsl` | Status page |
| Admin | `http://m8n9.local/admin/` | Admin interface |

### Optimizări Traefik pentru Streaming

Labels configurate în `docker-compose.yml`:

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.icecast.rule=Host(`m8n9.local`)"

  # Streaming optimization - flush responses immediately
  - "traefik.http.services.icecast.loadbalancer.responseforwarding.flushinterval=1ms"

  # Preserve client headers
  - "traefik.http.services.icecast.loadbalancer.passhostheader=true"
```

### Expunere DOAR a Stream-ului (Opțional)

Dacă vrei să expui **doar** stream-ul audio și să blochezi accesul la admin/status, modifică label-ul de routing:

```yaml
# În docker-compose.yml, schimbă:
- "traefik.http.routers.icecast.rule=Host(`m8n9.local`) && PathPrefix(`${MOUNT_NAME}`)"

# Exemplu cu MOUNT_NAME=/stream:
- "traefik.http.routers.icecast.rule=Host(`m8n9.local`) && PathPrefix(`/stream`)"
```

**Notă**: Valorile din `${MOUNT_NAME}` sunt citite din fișierul `.env`.

### Configurare Hostname Custom

Pentru a schimba hostname-ul de la `m8n9.local` la altceva:

1. Editează `docker-compose.yml`:
   ```yaml
   - "traefik.http.routers.icecast.rule=Host(`radio.example.com`)"
   ```

2. SAU folosește variabilă de mediu:
   ```yaml
   - "traefik.http.routers.icecast.rule=Host(`${ICECAST_DOMAIN:-m8n9.local}`)"
   ```

3. Setează în `.env`:
   ```env
   ICECAST_DOMAIN=radio.example.com
   ```

## Instalare și Utilizare

### Build Docker Image

```bash
docker build -t icecast2 .
```

### Run Container

```bash
docker run -d \
  -p 8000:80 \
  -e HOSTNAME=radio.example.com \
  -e LOCATION="Bucharest, Romania" \
  -e ADMIN_EMAIL=admin@example.com \
  -e SOURCE_PASSWORD=your_source_pass \
  -e ADMIN_PASSWORD=your_admin_pass \
  --name icecast \
  icecast2
```

**Notă**: Portul expus este **80** (nginx), NU 8000. Icecast ascultă intern pe 8000.

### Docker Compose

```yaml
services:
  icecast:
    build:
      context: .
    ports:
      - "8000:80"  # Nginx pe 80, expus ca 8000 extern
    environment:
      - HOSTNAME=radio.example.com
      - LOCATION=Bucharest, Romania
      - ADMIN_EMAIL=admin@example.com
      - SOURCE_PASSWORD=secure_source_pass
      - ADMIN_PASSWORD=secure_admin_pass
      - CLIENTS=5000
    restart: unless-stopped
```

## Configurare

### Fișier .env

Copiază `.env.dist` la `.env` și personalizează:

```bash
cp .env.dist .env
nano .env
```

### Variabile de Mediu Disponibile

#### Server Information

| Variabilă | Descriere | Default | Exemplu |
|-----------|-----------|---------|---------|
| `HOSTNAME` | Hostname-ul serverului | `localhost` | `radio.example.com` |
| `LOCATION` | Locația serverului | `Unknown` | `Bucharest, Romania` |
| `ADMIN_EMAIL` | Email administrator | `admin@localhost` | `admin@example.com` |
| `TIMEZONE` | Timezone server | `UTC` | `Europe/Bucharest` |

#### Autentificare

| Variabilă | Descriere | Default |
|-----------|-----------|---------|
| `SOURCE_PASSWORD` | Parolă pentru surse audio | `hackme` |
| `RELAY_PASSWORD` | Parolă pentru relay | `hackme` |
| `ADMIN_USER` | Username admin | `admin` |
| `ADMIN_PASSWORD` | Parolă admin | `hackme` |

⚠️ **Important**: Schimbă parolele default în producție!

#### Limite și Performanță

| Variabilă | Descriere | Default | Recomandare |
|-----------|-----------|---------|-------------|
| `CLIENTS` | Număr maxim clienți | `10000` | Ajustează în funcție de bandwidth |
| `SOURCES` | Număr maxim surse | `100` | 2-10 pentru majoritatea cazurilor |
| `THREADPOOL` | Dimensiune thread pool | `128` | CPU cores * 4-8 |
| `QUEUE_SIZE` | Dimensiune queue buffer | `524288` | Mărește pentru trafic mare |
| `CLIENT_TIMEOUT` | Timeout clienți (sec) | `30` | 30-60 |
| `HEADER_TIMEOUT` | Timeout header HTTP (sec) | `15` | 10-20 |
| `SOURCE_TIMEOUT` | Timeout surse (sec) | `10` | 10-30 |

#### Buffer și Streaming

| Variabilă | Descriere | Default |
|-----------|-----------|---------|
| `BURST_ON_CONNECT` | Activează burst la conectare | `1` |
| `BURST_SIZE` | Dimensiune burst buffer (bytes) | `65536` |
| `BUFFER_SIZE` | Dimensiune buffer general | `4096` |
| `BUFFER_DURATION` | Durată buffer (sec) | `0` |

#### Listen Socket

| Variabilă | Descriere | Default |
|-----------|-----------|---------|
| `LISTEN_PORT` | Port de ascultare | `8000` |
| `LISTEN_IP` | IP de binding | `0.0.0.0` |

#### Logging

| Variabilă | Descriere | Default | Nivele |
|-----------|-----------|---------|--------|
| `LOGLEVEL` | Nivel logging | `3` | 1=ERROR, 2=WARN, 3=INFO, 4=DEBUG |
| `LOGDIR` | Director log-uri | `/var/log/icecast2` | |
| `ACCESSLOGDIR` | Director access logs | `/var/log/icecast2` | |

#### Mount Point Default

| Variabilă | Descriere | Default |
|-----------|-----------|---------|
| `MOUNT_NAME` | Nume mount point | `/stream` |
| `MOUNT_DESC` | Descriere stream | `Default Stream` |
| `MOUNT_GENRE` | Gen muzical | `Various` |
| `MOUNT_BITRATE` | Bitrate (kbps) | `128` |
| `MOUNT_PUBLIC` | Stream public (0/1) | `1` |
| `MOUNT_MAXLISTENERS` | Ascultători maximi (0=unlimited) | `0` |
| `MOUNT_FALLBACK` | Mount fallback | (gol) |

#### Statistici

| Variabilă | Descriere | Default |
|-----------|-----------|---------|
| `STATS_ENABLED` | Activează statistici | `true` |
| `STATS_PORT` | Port statistici separat | (gol) |

#### Web Interface

| Variabilă | Descriere | Default |
|-----------|-----------|---------|
| `WEBROOT` | Director interfață web | `/usr/share/icecast2/web` |

## Accesare Servicii

După pornire, poți accesa:

| Serviciu | URL | Autentificare |
|----------|-----|---------------|
| Web Interface | `http://localhost:8000/` | Nu |
| Status Page | `http://localhost:8000/status.xsl` | Nu |
| Admin Interface | `http://localhost:8000/admin/` | Da (ADMIN_USER/ADMIN_PASSWORD) |
| Admin Stats XML | `http://localhost:8000/admin/stats.xml` | Da |
| Listen Stream | `http://localhost:8000/stream` | Nu |

## Conectare Surse Audio

### FFmpeg

```bash
# Stream dintr-un fișier MP3
ffmpeg -re -i input.mp3 \
  -acodec libmp3lame -ab 128k -ac 2 -ar 44100 \
  -f mp3 \
  icecast://source:SOURCE_PASSWORD@localhost:8000/stream

# Stream live de la microfon
ffmpeg -f alsa -i default \
  -acodec libmp3lame -ab 128k -ac 2 -ar 44100 \
  -f mp3 \
  icecast://source:SOURCE_PASSWORD@localhost:8000/live
```

### Liquidsoap

```liquidsoap
output.icecast(
  %mp3,
  host = "localhost",
  port = 8000,
  password = "SOURCE_PASSWORD",
  mount = "stream",
  source
)
```

### BUTT (Broadcast Using This Tool)

1. Deschide BUTT
2. Settings → Main:
   - Address: `localhost`
   - Port: `8000`
   - Password: `SOURCE_PASSWORD`
   - IceCast mountpoint: `/stream`
   - IceCast user: `source`

### Mixxx DJ Software

1. Preferences → Live Broadcasting
2. Type: `Icecast 2`
3. Host: `localhost`
4. Port: `8000`
5. Login: `source`
6. Password: `SOURCE_PASSWORD`
7. Mount: `stream`

## Ascultare Stream

### Browser

```
http://localhost:8000/stream
```

### Media Players

```bash
# VLC
vlc http://localhost:8000/stream

# mpv
mpv http://localhost:8000/stream

# mplayer
mplayer http://localhost:8000/stream
```

### cURL (test)

```bash
# Ascultă stream
curl http://localhost:8000/stream > /dev/null

# Descarcă 10 secunde
timeout 10 curl http://localhost:8000/stream > test.mp3
```

## Monitoring și Administrare

### Verificare Status

```bash
# Status JSON
curl http://localhost:8000/status-json.xsl

# Status XML (necesită autentificare admin)
curl -u admin:ADMIN_PASSWORD http://localhost:8000/admin/stats.xml

# Lista mountpoints active
curl -u admin:ADMIN_PASSWORD http://localhost:8000/admin/listmounts
```

### Comenzi Admin

```bash
# Oprire sursă
curl -u admin:ADMIN_PASSWORD \
  "http://localhost:8000/admin/killsource?mount=/stream"

# Oprire client specific
curl -u admin:ADMIN_PASSWORD \
  "http://localhost:8000/admin/killclient?mount=/stream&id=CLIENT_ID"

# Mutare ascultători către alt mount
curl -u admin:ADMIN_PASSWORD \
  "http://localhost:8000/admin/moveclients?mount=/stream&destination=/backup"
```

### Logs

```bash
# Vizualizare logs în timp real
docker logs -f icecast-container-name

# Logs din container
docker exec icecast-container-name tail -f /var/log/icecast2/error.log
docker exec icecast-container-name tail -f /var/log/icecast2/access.log
```

## Optimizare Performanță

### Pentru trafic redus (<100 ascultători)

```env
CLIENTS=200
SOURCES=5
THREADPOOL=32
QUEUE_SIZE=262144
```

### Pentru trafic mediu (100-1000 ascultători)

```env
CLIENTS=1500
SOURCES=20
THREADPOOL=64
QUEUE_SIZE=524288
BURST_SIZE=65536
```

### Pentru trafic mare (1000-5000 ascultători)

```env
CLIENTS=5000
SOURCES=50
THREADPOOL=128
QUEUE_SIZE=1048576
BURST_SIZE=131072
CLIENT_TIMEOUT=60
```

### Pentru trafic foarte mare (>5000 ascultători)

```env
CLIENTS=10000
SOURCES=100
THREADPOOL=256
QUEUE_SIZE=2097152
BURST_SIZE=262144
CLIENT_TIMEOUT=90
```

## Troubleshooting

### Container nu pornește

```bash
# Verifică logs
docker logs icecast-container-name

# Verifică configurația generată
docker exec icecast-container-name cat /etc/icecast2/icecast.xml

# Rebuild image
docker build --no-cache -t icecast2 .
```

### Warning: location not configured

Acest warning apare când `LOCATION` este setat la valoarea default `Earth`.
Setează o valoare customizată:

```bash
LOCATION="Your City, Country"
```

### Warning: Cannot open mime types file

Acest warning a fost rezolvat prin instalarea pachetului `mime-support` în Dockerfile.
Dacă apare, rebuilduiește image-ul.

### Sursa nu se conectează

1. Verifică parola:
   ```bash
   docker exec icecast-container-name cat /etc/icecast2/icecast.xml | grep source-password
   ```

2. Verifică portul:
   ```bash
   netstat -tlnp | grep 8000
   ```

3. Test conectivitate:
   ```bash
   telnet localhost 8000
   ```

### Nu pot accesa admin interface

```bash
# Verifică credențiale
docker exec icecast-container-name cat /etc/icecast2/icecast.xml | grep -A2 authentication

# Test autentificare
curl -u admin:ADMIN_PASSWORD http://localhost:8000/admin/stats.xml
```

### Performanță slabă

1. Mărește thread pool:
   ```env
   THREADPOOL=256
   ```

2. Mărește queue size:
   ```env
   QUEUE_SIZE=2097152
   ```

3. Verifică resursele:
   ```bash
   docker stats icecast-container-name
   ```

### Prea multe disconnecturi

Mărește timeout-urile:

```env
CLIENT_TIMEOUT=60
HEADER_TIMEOUT=30
SOURCE_TIMEOUT=30
```

## Nginx Proxy - Detalii Tehnice

### Headers pentru Streaming

Nginx este configurat cu headers esențiale pentru compatibilitate Icecast/Shoutcast:

- **CORS Headers**: `Access-Control-Allow-Origin: *` pentru web players
- **Icy Headers**: `Icy-MetaInt`, `Icy-Name`, `Icy-Genre`, `Icy-Br`, `Icy-Url` pentru metadata
- **Range Requests**: Suport pentru seek în stream-uri
- **Security Headers**: `X-Frame-Options`, `X-Content-Type-Options`, `X-XSS-Protection`

### Strategii de Caching

| Tip de conținut | Caching | Durată | Motiv |
|-----------------|---------|--------|-------|
| **Stream-uri** (`/stream`, `/live`, etc.) | ❌ NU | - | Real-time, fără latență |
| **Assets statice** (`.css`, `.js`, `.png`) | ✅ DA | 60 min | Performanță |
| **Status pages** (`/status.xsl`) | ✅ DA | 5 sec | Update rapid |
| **Admin interface** (`/admin/`) | ❌ NU | - | Date sensibile |
| **Home page** (`/`) | ✅ DA | 30 sec | Balance |

### Buffering Configuration

Pentru stream-uri audio:
```nginx
proxy_buffering off;              # Zero buffering
proxy_request_buffering off;      # No request buffering
proxy_max_temp_file_size 0;       # No temp files
```

Pentru assets statice:
```nginx
proxy_buffering on;               # Enable buffering
proxy_cache icecast_cache;        # Use cache zone
```

### Timeouts

| Parametru | Stream-uri | Admin | Statice |
|-----------|------------|-------|---------|
| `proxy_connect_timeout` | 3600s | 60s | 60s |
| `proxy_send_timeout` | 3600s | 60s | 60s |
| `proxy_read_timeout` | 3600s | 60s | 60s |

Stream-urile au timeout de **1 oră** pentru conexiuni long-lived.

### Health Check

Nginx expune endpoint de health check:

```bash
curl http://localhost:80/nginx-health
# Output: healthy
```

## Securitate

### Best Practices

1. **Schimbă parolele default**:
   ```env
   SOURCE_PASSWORD=$(openssl rand -base64 32)
   ADMIN_PASSWORD=$(openssl rand -base64 32)
   RELAY_PASSWORD=$(openssl rand -base64 32)
   ```

2. **Limitează accesul la admin**:
   - Nginx proxy este deja integrat
   - Pentru restricții IP, adaugă în `nginx.conf.template`:
   ```nginx
   location /admin/ {
       allow 10.0.0.0/8;
       deny all;
       proxy_pass http://icecast_backend;
   }
   ```

3. **Folosește HTTPS** (adaugă SSL termination la nginx):
   - Montează certificate în container
   - Modifică `nginx.conf.template` să adauge:
   ```nginx
   listen 443 ssl;
   ssl_certificate /path/to/cert.pem;
   ssl_certificate_key /path/to/key.pem;
   ```

4. **Rate limiting** (previne abuse):
   - Nginx are deja configurare optimizată
   - Pentru rate limiting explicit, adaugă:
   ```nginx
   limit_req_zone $binary_remote_addr zone=streaming:10m rate=5r/s;
   ```

5. **Actualizează regulat** imaginea Docker

6. **Monitorizează logs** pentru activități suspecte

## Dezvoltare

### Structură Fișiere

```
01-icecast/
├── Dockerfile              # Configurare Docker (Icecast + Nginx + Supervisor)
├── entrypoint.sh          # Script de inițializare
├── icecast.xml.template   # Template configurare Icecast
├── nginx.conf.template    # Template configurare Nginx proxy
├── supervisord.conf       # Configurare Supervisor pentru multi-proces
├── .env.dist              # Exemplu variabile de mediu
├── .gitignore            # Git ignore patterns
├── LICENSE               # Licență proiect
└── README.md             # Această documentație
```

### Modificare Template

#### Modificare configurare Icecast

1. Editează `icecast.xml.template`
2. Adaugă variabile noi în `entrypoint.sh`
3. Rebuild image-ul:
   ```bash
   docker build -t icecast2 .
   ```

#### Modificare configurare Nginx

1. Editează `nginx.conf.template`
2. Poți adăuga:
   - Rate limiting
   - IP whitelisting pentru admin
   - SSL/TLS configuration
   - Custom headers
   - Additional caching rules
3. Rebuild image-ul:
   ```bash
   docker build -t icecast2 .
   ```

#### Exemplu: Adăugare SSL în Nginx

```nginx
server {
    listen 80 default_server;
    listen 443 ssl http2;
    server_name _;

    ssl_certificate /etc/ssl/certs/icecast.crt;
    ssl_certificate_key /etc/ssl/private/icecast.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    # ... rest of config
}
```

### Testing

```bash
# Test build
docker build -t icecast2-test .

# Test run
docker run --rm -p 8000:8000 icecast2-test

# Test conectare sursă
ffmpeg -re -f lavfi -i "sine=frequency=1000:duration=10" \
  -acodec libmp3lame -ab 128k \
  -f mp3 icecast://source:hackme@localhost:8000/test
```

## Resurse

- [Documentație oficială Icecast](https://icecast.org/docs/)
- [Icecast GitHub](https://github.com/xiph/Icecast-Server)
- [Xiph.org](https://xiph.org/)
