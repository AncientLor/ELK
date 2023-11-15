# ELK Stack Set-Up

Elastic = Database

Kibana = Web Interface for Database

- Fleet Management

- Endpoint Security

- Windows Logging


References:

```
https://www.digitalocean.com/community/tutorials/how-to-install-elasticsearch-logstash-and-kibana-elastic-stack-on-ubuntu-22-04

https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-network.html
```

## Installing Elasticsearch
_____

__Import Elasticsearch public GPG key__

```
curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch |sudo gpg --dearmor -o /usr/share/keyrings/elastic.gpg
```

__Add Elastic source list to sources.list.d directory__

```
echo "deb [signed-by=/usr/share/keyrings/elastic.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-8.x.list
```

__Update & Install__

Make note of the generated password when installing.

```
sudo apt update && sudo apt install elasticsearch
```

__Configure__

```
sudo vim /etc/elasticsearch/elasticsearch.yml
```

__Examples__
```
network.host: localhost         // Listen on  localhost

network.host: "_en0:ipv4_"      // Listen on interface en0 with ipv4 addresses only

http.port: 9200                 // Listen on port 9200 (default)
```


__Troubleshooting__

We can test our elasticsearch server with curl. (Make sure to specify https)

```
curl -X GET -k https://localhost:9200
```

This will fail as we need to provide authentication. We can reset the password if forgotten.

```
curl -X GET -k https://elastic:<password>@localhost:9200
```

__Reset Password__

```
/usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic
```

## Installing Kibana
___

__Installation__

```
sudo apt install kibana
```

__Create Enrollment Token__

```
sudo /usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s kibana
```

__Activate w/ Token__

```
sudo /usr/share/kibana/bin/kibana-setup
```

__Start & Enable__

```
sudo systemctl start kibana && sudo systemctl enable kibana
```

## Configure Nginx
___

__Install__

```
sudo apt install nginx
```

__Configure Proxy__

```
sudo vim /etc/nginx/sites-enabled/default
```

Add under server location:

```
proxy_pass http://127.0.0.1:5601;
```

__Restart & Enable__

```
sudo sytemctl restart nginx && sudo systemctl enable nginx
```

We can now login to the web interface with our original elastic credentials.

## Integrations
___

__Fleet Server__

*__Setup:__*

- Create name for Fleet Server and Agent Policy

- Leave rest as default, save & continue

- Add Elastic Agent to your hosts

- Add Fleet Server

- Fleet Server host: `https://<host-ip>:8220`     (Can use domain name if DNS is configured)

- Generate Fleet Server policy

- Run the appropriate commands provided on your Fleet Server. Should see:

    ```
    Successfully enrolled the Elastic Agent.
    Elastic Agent has been successfully installed.
    ```

- Confirm Fleet Server is connected

- If using a seperate machine for Fleet Server, make sure to copy SSL certs from Elastic Server

    - Elastic certs stored in `/etc/elasticsearch/certs` by default
    - Can replace with legitimate signed certs as well
    - If using a different directory for your certs, you can add these flags to the end of the install commands:
        ```
        --fleet-server-es-ca=<path_to_cert> --insecure
        ```
    

- Continue Enrolling Elastic agent

- Switch tab to Enroll in Fleet

- Create new Agent Policy and follow the install instructions

- Confirm Agent is connected to fleet

__Elastic Defend__

- Add Integration Name & Select Existing Policy w/ enrollments

- Leave rest as default & Continue

- We need to create encryption keys so we can add security rules
    ```
    sudo /usr/share/kibana/bin/kibana-encryption-keys generate
    sudo vim /etc/kibana/kibana.yml (Add Keys to bottom of file)
    sudo systemctl restart kibana
    ```

- Navigate to Security > Manage > Rules

- Load Elastic prebuilt rules and timeline templates

- Select All > Enable

__Windows__

- Name & Select Agent Policy
