# Start

```bash
docker compose up -d --build
```

# Stop

```bash
docker compose stop
```

# Remove

```bash
docker compose down
```

# Remove all docker container
```bash
docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)
```