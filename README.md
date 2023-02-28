# ELK Stack Dockerized Deployment

## Setup Host Environment

```
sudo apt-get update
sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release


```

```
sudo sysctl -w vm.max_map_count=262144
sudo echo "vm.max_map_count = 262144" >> /etc/sysctl.conf
```

## Initialize Containers

```
docker compose compose/docker-compose.yml -d
```