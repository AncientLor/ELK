#! /bin/bash

# Check if user has sudo permissions
if [[ $(id -u) -ne 0 ]]; then
    echo -e "\e[1;36m This script must be run with sudo privileges. Please use 'sudo' to run this script. \e[0m"
    exit
fi

echo 'Importing GPG Key...';

curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | gpg --dearmor -o /usr/share/keyrings/elastic.gpg;

echo 'Success';

echo 'Adding Sources...';

echo "deb [signed-by=/usr/share/keyrings/elastic.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-8.x.list;

echo 'Success';

echo -e "\e[1;36m Installing \e[0m";

mkdir /root/.elk;

apt update && apt install elasticsearch | tee /root/.elk/elastic.out; 

grep 'superuser is' /root/.elk/elastic.out | cut -d ' ' -f 11 > /root/.elk/elastic.key;

echo -e "\e[1;36m Install Complete. Configuring... \e[0m";

sed -i 's/#network.host: 192.168.0.1/network.host: localhost/; s/#http.port: 9200/http.port: 9200/;' /etc/elasticsearch/elasticsearch.yml;

cat /etc/elasticsearch/elasticsearch.yml | grep 'network.host' -A 6;

echo -e "\e[1;36m Configuration Complete. Starting... \e[0m";

systemctl start elasticsearch && systemctl enable elasticsearch;

echo -e "\e[1;36m Elasticsearch Now Enabled \e[0m";

elastic_api=$(cat /root/.elk/elastic.key);

echo 'url = https://localhost:9200' > /root/.elk/elastic.curl;

echo '--user elastic:'"$elastic_api"'' >> /root/.elk/elastic.curl;

curl -X GET -k -K /root/.elk/elastic.curl;

rm /root/.elk/elastic.curl;

echo -e "\e[1;36m Installing & Configuring Kibana... \e[0m";

apt install kibana -y;

/usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s kibana > /root/.elk/kibana.enroll;

enroll_token=$(cat /root/.elk/kibana.enroll);

/usr/share/kibana/bin/kibana-setup -t $enroll_token;

/usr/share/kibana/bin/kibana-encryption-keys generate | tail -n 4 >> /etc/kibana/kibana.yml;

systemctl start kibana && systemctl enable kibana;

echo -e "\e[1;36m Installing & Configuring Nginx... \e[0m";

if ! command -v nginx &> /dev/null;
then
    apt install nginx -y;
else
    echo 'Nginx already installed.'
fi

echo 'server {
        listen 7777 default_server;
        #listen [::]:7777 default_server;

        server_name kibana;

        #root /var/www/html;
        #index index.nginx-debian.html index.html;

        location / {
                proxy_pass http://127.0.0.1:5601;
        }
}' >> /etc/nginx/sites-available/default;

systemctl restart nginx && systemctl enable nginx;

echo -e "\e[1;36m Elastic Server Successfully Deployed. \e[0m";

exit;
