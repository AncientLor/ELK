#! /bin/bash

# Check if user has sudo permissions

if [[ $(id -u) -ne 0 ]]; then
  echo -e "\e[1;36m This script must be run with sudo privileges. Please use 'sudo' to run this script. \e[0m"
  exit
fi

apt-get update && apt-get install -y ca-certificates curl gnupg lsb-release;

mkdir -m 0755 -p /etc/apt/keyrings;

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg;

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null;

apt-get update && apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin;

sysctl -w vm.max_map_count=262144;

echo "vm.max_map_count = 262144" >> /etc/sysctl.conf;

exit;
