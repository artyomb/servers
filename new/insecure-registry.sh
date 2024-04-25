#!/bin/bash

# Check if argument is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <registry_address>"
    exit 1
fi

registry_address="$1"
apt install -y jq
# JSON to add
json_data='{
  "insecure-registries": [
    "'"$registry_address"'"
  ]
}'

# Check if the file exists
if [ ! -f /etc/docker/daemon.json ]; then
    echo '{}' > /etc/docker/daemon.json
fi

insecure_registries=$(jq -r '.["insecure-registries"]' /etc/docker/daemon.json)

if [ "$insecure_registries" = "null" ]; then
    jq '. + '"$json_data"'' /etc/docker/daemon.json > /etc/docker/daemon.json.tmp && mv /etc/docker/daemon.json.tmp /etc/docker/daemon.json
else
    jq '.["insecure-registries"] += ["'"$registry_address"'"]' /etc/docker/daemon.json > /etc/docker/daemon.json.tmp && mv /etc/docker/daemon.json.tmp /etc/docker/daemon.json
fi


echo "Added \"$registry_address\" to insecure-registries in ./daemon.json"