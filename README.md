# ELK Stack Dockerized Deployment

## Setup Host Environment

```
sudo sysctl -w vm.max_map_count = 262144
sudo vim /etc/sysctl.conf >> vm.max_map_count = 262144
```

## Initialize Containers

```
docker compose compose/docker-compose.yml -d
```