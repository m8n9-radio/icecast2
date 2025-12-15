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

## Instalare și Utilizare

### Build Docker Image

```bash
docker build -t icecast2 .
```

### Run Container

```bash
docker run -d \
  -p 8000:8000 \
  -e HOSTNAME=radio.example.com \
  -e LOCATION="Bucharest, Romania" \
  -e ADMIN_EMAIL=admin@example.com \
  -e SOURCE_PASSWORD=your_source_pass \
  -e ADMIN_PASSWORD=your_admin_pass \
  --name icecast \
  icecast2
```

### Docker Compose

```yaml
services:
  icecast:
    build:
      context: .
    ports:
      - "8000:8000"
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

## Securitate

### Best Practices

1. **Schimbă parolele default**:
   ```env
   SOURCE_PASSWORD=$(openssl rand -base64 32)
   ADMIN_PASSWORD=$(openssl rand -base64 32)
   RELAY_PASSWORD=$(openssl rand -base64 32)
   ```

2. **Limitează accesul la admin**:
   - Folosește reverse proxy (nginx/traefik)
   - Restricționează IP-uri pentru `/admin`

3. **Folosește HTTPS** (prin reverse proxy):
   ```nginx
   server {
       listen 443 ssl;
       server_name radio.example.com;

       location / {
           proxy_pass http://localhost:8000;
           proxy_set_header Host $host;
       }
   }
   ```

4. **Actualizează regulat** imaginea Docker

5. **Monitorizează logs** pentru activități suspecte

## Dezvoltare

### Structură Fișiere

```
01-icecast/
├── Dockerfile              # Configurare Docker
├── entrypoint.sh          # Script de inițializare
├── icecast.xml.template   # Template configurare XML
├── .env.dist              # Exemplu variabile de mediu
├── .gitignore            # Git ignore patterns
├── LICENSE               # Licență proiect
└── README.md             # Această documentație
```

### Modificare Template

Pentru a modifica configurarea XML:

1. Editează `icecast.xml.template`
2. Adaugă variabile noi în `entrypoint.sh`
3. Rebuild image-ul:
   ```bash
   docker build -t icecast2 .
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
