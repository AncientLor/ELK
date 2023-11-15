#! /bin/bash

### NOT FINISHED YET ###
### RUN AT OWN RISK  ###

# Check if user has sudo permissions

if [[ $(id -u) -ne 0 ]]; then
  echo -e "\e[1;36m This script must be run with sudo privileges. Please use 'sudo' to run this script. \e[0m"
  exit
fi

# Check if elasticsearch host exists

ELASTICSEARCH=$(getent hosts | grep elasticsearch);

if [ x${ELASTICSEARCH} == x ]; then
    echo "Add elasticsearch to /etc/hosts";
    exit 1;
fi

mkdir /root/.elk/certs;

scp root@elasticsearch:/var/lib/docker/volumes/compose_certs/_data/ca.zip /root/.elk/certs/ca.zip;

scp root@elasticsearch:/var/lib/docker/volumes/compose_certs/_data/certs.zip /root/.elk/certs/certs.zip;

apt update && apt install -y unzip;

unzip /root/.elk/certs/ca.zip -d /root/.elk/certs && mv /root/.elk/certs/ca/ca.crt /root/.elk/certs;

unzip /root/.elk/certs/certs.zip -d /root/.elk/certs && mv /root/.elk/certs/elasticsearch/elasticsearch* /root/.elk/certs;

FILE1="/root/.elk/certs/ca.crt"

if [ -f "$FILE1" ]; then
    echo "CA found... Proceeding.";
else
    echo "CA not found. Please add certs to ~/.elk/certs";
    exit 1;
fi

FILE2="/root/.elk/certs/elasticsearch.crt"

if [ -f "$FILE2" ]; then
    echo "Certs found... Proceeding.";
else
    echo "Certs not found. Please add certs to ~/.elk/certs";
    exit 1;
fi

wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -;

echo "deb https://artifacts.elastic.co/packages/8.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-8.x.list;

apt-get update && apt-get install -y filebeat;

filebeat setup \
        -E "output.elasticsearch.hosts=["https://elasticsearch:9200"]" \
        -E "output.elasticsearch.ssl.certificate_authorities=["/root/.elk/certs/ca.crt"]" \
        -E "output.elasticsearch.ssl.certificate:=/root/.elk/certs/elasticsearch.crt" \
        -E "output.elasticsearch.ssl.key=/root/.elk/certs/elasticsearch.key";

filebeat modules enable system;

filebeat setup \
        -M "system.syslog.var.paths=[/var/log/syslog]" \
        -M "system.syslog.enabled=true" \
        -M "system.auth.enabled=true" \
        -M "system.auth.var.paths=[/var/log/auth.log]";

filebeat setup --index-management;

filebeat setup --pipelines --modules system;

#filebeat setup -E output.elasticsearch.hosts=["https://elasticsearch:9200"] -E output.elasticsearch.ssl.certificate_authorities=["~/.elk/certs/ca.crt"] -E output.elasticsearch.ssl.certificate:=/root/.elk/certs/elasticsearch.crt -E output.elasticsearch.ssl.key=/root/.elk/certs/elasticsearch.key

systemctl start filebeat && systemctl enable filebeat;

#curl -XGET 'https://elasticsearch:9200/filebeat-*/_search?pretty';

exit;

