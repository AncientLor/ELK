#! /bin/bash
docker network create filebeat
docker run -d -it --name=filebeat --hostname=cheese.beat --user=root --network=filebeat -v /var/log:/usr/share/var/log:ro -v ~/.elk/filebeat/filebeat.yml:/usr/share/filebeat/filebeat.yml:ro -v /var/lib/docker/containers:/var/lib/docker/containers:ro -v /var/run/docker.sock:/var/run/docker.sock:ro docker.elastic.co/beats/filebeat:8.6.2 filebeat -e --strict.perms=false
