# Icecast-KH Streaming Server

Server de streaming audio Icecast-KH containerizat cu Docker, cu suport pentru StreamUrl în ICY metadata.

## Descriere

Acest serviciu oferă un server Icecast-KH (fork al Icecast2) complet configurabil pentru streaming audio live. Suportă multiple formate audio (MP3, Vorbis, Opus) și permite propagarea `StreamUrl` în ICY metadata pentru album covers.

## Caracteristici

- ✅ **Icecast-KH 2.4.0-kh22** - Fork cu suport StreamUrl
- ✅ Configurare completă prin variabile de mediu
- ✅ **StreamUrl în ICY metadata** - pentru album covers inline
- ✅ Suport pentru multiple mount points
- ✅ Autentificare configurabilă pentru surse și admin
- ✅ **CORS headers** configurate pentru web players
- ✅ Logging configurabil
- ✅ Optimizat pentru performanță

## De ce Icecast-KH?

Icecast standard (2.4.4) nu propagă `url` metadata ca `StreamUrl` în ICY metadata. Icecast-KH rezolvă această problemă:

- Primește `url` tag prin HTTP admin API
- Îl propagă ca `StreamUrl='...'` în ICY metadata inline
- Permite clienților să primească album cover URL direct în stream

## Instalare și Utilizare

### Build Docker Image

```bash
docker build -t icecast-kh .
```

### Run Container

```bash
docker run -d \
  -p 8000:8000 \
  -e HOSTNAME=radio.example.com \
  -e SOURCE_PASSWORD=your_source_pass \
  -e ADMIN_PASSWORD=your_admin_pass \
  --name icecast \
  icecast-kh
```

### Docker Compose

```yaml
services:
  icecast:
    build:
      context: apps/01-icecast
    ports:
      - "8000:8000"
    env_file:
      - apps/01-icecast/.env
    restart: unless-stopped
```

## Configurare

### Fișier .env

Copiază `.env.dist` la `.env` și personalizează:

```bash
cp .env.dist .env
```

### Variabile de Mediu

| Variabilă         | Descriere           | Default           |
| ----------------- | ------------------- | ----------------- |
| `HOSTNAME`        | Hostname server     | `localhost`       |
| `LOCATION`        | Locația serverului  | `Unknown`         |
| `ADMIN_EMAIL`     | Email administrator | `admin@localhost` |
| `SOURCE_PASSWORD` | Parolă pentru surse | `hackme`          |
| `ADMIN_PASSWORD`  | Parolă admin        | `hackme`          |
| `CLIENTS`         | Număr maxim clienți | `5000`            |
| `SOURCES`         | Număr maxim surse   | `50`              |
| `LISTEN_PORT`     | Port de ascultare   | `8000`            |
| `MOUNT_NAME`      | Nume mount point    | `/stream`         |
| `LOGLEVEL`        | Nivel logging (1-4) | `3`               |

## Accesare Servicii

| Serviciu        | URL                            |
| --------------- | ------------------------------ |
| Stream Audio    | `http://localhost:8000/stream` |
| Web Interface   | `http://localhost:8000/`       |
| Admin Interface | `http://localhost:8000/admin/` |

## ICY Metadata cu StreamUrl

Când Liquidsoap trimite metadata cu `url`, Icecast-KH o propagă:

```
StreamTitle='Artist - Title';StreamUrl='https://i.discogs.com/.../cover.jpg';
```

### Verificare StreamUrl

```bash
curl -s -H "Icy-MetaData: 1" "http://localhost:8000/stream" --max-time 10 | strings | grep Stream
```

## Conectare Surse Audio

### Liquidsoap

```liquidsoap
output.icecast(
  %mp3,
  host = "icecast",
  port = 8000,
  password = "source_secret",
  mount = "stream",
  radio
)

# Trimite url separat pentru StreamUrl
icy.update_metadata(
  host = "icecast",
  port = 8000,
  password = "source_secret",
  mount = "/stream",
  [("url", cover_url)]
)
```

## Structură Fișiere

```
01-icecast/
├── Dockerfile              # Multi-stage build pentru Icecast-KH
├── entrypoint.sh          # Script de inițializare
├── icecast.xml.template   # Template configurare
├── .env                   # Variabile de mediu
├── .env.dist              # Exemplu variabile
└── README.md              # Documentație
```

## Troubleshooting

### Container nu pornește

```bash
docker logs icecast2
```

### StreamUrl nu apare

1. Verifică că Liquidsoap trimite `url` cu `icy.update_metadata()`
2. Verifică log-urile Icecast pentru `Metadata url on /stream set to`

### Performanță

Pentru trafic mare, ajustează:

```env
CLIENTS=10000
QUEUE_SIZE=2097152
BURST_SIZE=131072
```

## Resurse

- [Icecast-KH GitHub](https://github.com/karlheyes/icecast-kh)
- [Icecast Documentation](https://icecast.org/docs/)
