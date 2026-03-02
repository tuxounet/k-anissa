## Coder


## Références 

https://hub.docker.com/r/linuxserver/code-server


## Installation

```bash
docker run -d \
  --name=code-server \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Europe/Paris \
  -p 8443:8443 \
  -v /path/to/appdata/config:/config \
  --restart unless-stopped \
  linuxserver/code-server:latest
```

