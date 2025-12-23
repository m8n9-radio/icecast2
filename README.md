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

### Repository Structure
```
01-icecast/
├── Dockerfile                          # Multi-stage build pentru Icecast-KH
├── .dockerignore                       # Exclude files from Docker context
├── entrypoint.sh                       # Script de inițializare și config generation
├── .env                                # Variabile de mediu (local, nu in VCS)
├── .env.dist                           # Template variabile de mediu
├── icecast/
│   └── icecast.xml.template           # Template configurare Icecast-KH
├── nginx/
│   ├── nginx.conf                     # Configurare principală Nginx
│   └── conf.d/
│       └── icecast.conf.template      # Reverse proxy config pentru streaming
├── supervisord/
│   └── supervisord.conf               # Orchestrare Icecast + Nginx
├── LICENSE                            # Licență
└── README.md                          # Documentație
```

### Runtime Structure (în container)
```
/
├── etc/
│   ├── icecast/
│   │   ├── icecast.xml.template       # Template (copiat la build)
│   │   └── icecast.xml                # Generated at runtime
│   ├── nginx/
│   │   ├── nginx.conf                 # Main config
│   │   └── conf.d/
│   │       ├── icecast.conf.template  # Template (copiat la build)
│   │       └── icecast.conf           # Generated at runtime
│   └── supervisor/
│       └── conf.d/
│           └── supervisord.conf       # Supervisord config
├── app/
│   └── entrypoint.sh                  # Entrypoint script
└── var/
    └── log/
        ├── icecast/                   # Icecast logs
        ├── nginx/                     # Nginx logs
        └── supervisor/                # Supervisor logs
```

### Arhitectură Container

```
┌─────────────────────────────────────┐
│         Container (Port 80)         │
│                                     │
│  ┌─────────────────────────────┐   │
│  │         Nginx :80           │   │
│  │  (Reverse Proxy + CORS)     │   │
│  └──────────┬──────────────────┘   │
│             │                       │
│             ▼                       │
│  ┌─────────────────────────────┐   │
│  │    Icecast-KH :8000         │   │
│  │  (Streaming Server)         │   │
│  └─────────────────────────────┘   │
│                                     │
│         Supervised by               │
│         supervisord                 │
└─────────────────────────────────────┘
```

## Best Practices

### Securitate

1. **Nu commit .env în VCS** - folosește `.env.dist` ca template
2. **Schimbă parolele default** - `SOURCE_PASSWORD`, `ADMIN_PASSWORD`, `RELAY_PASSWORD`
3. **Limitează accesul admin** - consideră basic auth pe `/admin` în nginx

### Performance

1. **Ajustează limits** pentru trafic:
   ```env
   CLIENTS=10000
   QUEUE_SIZE=2097152
   BURST_SIZE=131072
   ```

2. **Monitor logs** pentru bottlenecks:
   ```bash
   docker logs -f icecast
   docker exec icecast tail -f /var/log/icecast/error.log
   ```

### Configurare

- **Structură standard Linux**: Configurările în `/etc/`, logs în `/var/log/`, conform FHS (Filesystem Hierarchy Standard)
- Toate variabilele de mediu au **defaults sensibile** în `entrypoint.sh`
- **Template-urile** (.xml.template, .conf.template) sunt copiate la build și procesate la runtime
- **Nginx reverse proxy** oferă CORS și optimizări pentru streaming
- **Config generation**: Entrypoint-ul generează configs din templates cu `envsubst`

## Troubleshooting

### Container nu pornește

```bash
docker logs icecast
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
