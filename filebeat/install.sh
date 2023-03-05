#! /bin/bash

# Check if user has sudo permissions

if [[ $(id -u) -ne 0 ]]; then
  echo -e "\e[1;36m This script must be run with sudo privileges. Please use 'sudo' to run this script. \e[0m"
  exit
fi

# Check if elkserver host exists

ELKSERVER=$(getent hosts | grep elkserver);

if [ x${ELKSERVER} == x ]; then
    echo "Add elkserver to /etc/hosts";
    exit 1;
fi

mkdir ~/.elk/certs;

scp root@elkserver:/var/lib/docker/volumes/compose_certs/_data/ca.zip ~/.elk/certs/ca.zip;

scp root@elkserver:/var/lib/docker/volumes/compose_certs/_data/certs.zip ~/.elk/certs/certs.zip;

apt update && apt install -y unzip;

unzip ~/.elk/certs/ca.zip -d ~/.elk/certs/ && mv ~/.elk/certs/ca/ca.crt ~/.elk/certs/ca.crt;

unzip ~/.elk/certs/certs.zip -d ~/.elk/certs/ && mv ~/.elk/certs/elasticsearch/elasticsearch.crt ~/.elk/certs/elasticsearch.crt && mv ~/.elk/certs/elasticsearch/elasticsearch.key ~/.elk/certs/elasticsearch.key;

FILE1=~/.elk/certs/ca.crt

if [ -f "$FILE1" ]; then
    echo "CA found... Proceeding.";
else
    echo "CA not found. Please add certs to ~/.elk/certs";
    exit 1;
fi

FILE2=~/.elk/certs/elasticsearch.crt

if [ -f "$FILE2" ]; then
    echo "Certs found... Proceeding.";
else
    echo "Certs not found. Please add certs to ~/.elk/certs";
    exit 1;
fi

apt install filebeat;

sed -e 's/output.elasticsearch:/#output.elasticsearch:/; s/hosts: \["localhost:9200"\]/#hosts: \["localhost:9200"\]/; s/#output.logstash:/output.logstash:/; s/#hosts: \["localhost:5044"\]/hosts: \["elkserver:5044"\]/;' /etc/filebeat/filebeat.yml;

filebeat modules enable system && filebeat modules list;

filebeat setup --pipelines --modules system;

filebeat setup --index-management -E output.logstash.enabled=false -E 'output.elasticsearch.hosts=["https://elkserver:9200"]' -E 'output.elasticsearch.ssl.certificate_authorities: ["~/.elk/certs/ca.pem"]' -E 'output.elasticsearch.ssl.certificate: "~/.elk/certs/elasticsearch.pem"' -E 'output.elasticsearch.ssl.key: "~/.elk/certs/elasticsearch.key"'

filebeat setup -E output.logstash.enabled=false -E 'output.elasticsearch.hosts=["https://elkserver:9200"]' -E 'output.elasticsearch.ssl.certificate_authorities: ["~/.elk/certs/ca.pem"]' -E 'output.elasticsearch.ssl.certificate: "~/.elk/certs/elasticsearch.pem"' -E 'output.elasticsearch.ssl.key: "~/.elk/certs/elasticsearch.key"' -E 'setup.kibana.host=elkserver:5601';

systemctl start filebeat && systemctl enable filebeat;

curl -XGET 'https://elkserver:9200/filebeat-*/_search?pretty';

exit;

