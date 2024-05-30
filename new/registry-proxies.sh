#!/bin/bash

apt install -y jq
filename=/etc/docker/daemon.json
# filename="./daemon.json"

json_data='[
       "https://docker-io.monitorsoft.ru",
       "https://gallery.ecr.aws/",
       "https://mirror.gcr.io",
       "https://daocloud.io",
       "https://c.163.com/",
       "https://registry.docker-cn.com",
       "https://huecker.io/"
     ]'

if [ ! -f $filename ]; then
    echo '{}' > $filename
fi

jq --argjson mirrors "$json_data" '.["registry-mirrors"] = $mirrors' $filename > $filename.tmp && mv $filename.tmp $filename

echo "Added \"$json_data\" to registry-mirrors in $filename"