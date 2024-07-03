#!/bin/bash
# curl https://raw.githubusercontent.com/artyomb/servers/main/new/swarm_server_init.sh | sh

set -e

apt update
apt install mc htop screen ntp ncdu swapspace rsync -y
modprobe ip_vs
echo 'ip_vs' >> /etc/modules-load.d/modules.conf

# after master reboot:
# docker service update --force  portainer_agent

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
apt install -y docker-ce docker-ce-cli containerd.io
# apt remove docker-compose-plugin

service docker restart
docker -v

docker plugin install grafana/loki-docker-driver:2.9.2 --alias loki --grant-all-permissions
service docker restart

# https://github.com/moby/libnetwork/issues/1765
# BUG: traefik cant start: network sandbox join failed: subnet sandbox join failed for "10.0.2.0/24": error creating vxlan interface: file exists
# FIX: ip -br -d link show | grep vx | grep DOWN | xargs -rn1 ip link delete

# docker -v 24.0.2,  (sudo usermod -aG docker $USER, newgrp docker )

# TODO: "storage-opts": [ "overlay2.size=5G" ] (backing filesystem is xfs and mounted with pquota mount option.)

echo '{ "features": { "buildkit": true }, "log-driver": "json-file", "log-opts": { "max-size": "250m", "max-file": "3"} }' > /etc/docker/daemon.json
docker swarm init
# docker login docker-registry... -u user -p password

# docker service create --name registry --publish published=5000,target=5000 registry:2
# TODO: https://github.com/moby/buildkit/issues/1368

docker network create --driver overlay ingress-routing

wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
chmod a+x /usr/local/bin/yq

snap install ruby --classic
gem install dry-stack build-labels

line_to_add='eval `ruby.env`'
marker='\[ -z "$PS1" \]'
if ! grep -qF "$line_to_add" ~/.bashrc; then
  sed -i "/$marker/i $line_to_add" ~/.bashrc
fi

