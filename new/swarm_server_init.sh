#!/bin/bash
# curl https://raw.githubusercontent.com/artyomb/servers/main/new/swarm_server_init.sh | sh

set -e
DOCKER_COMPOSE_VER=2.19.0

apt update
apt install mc htop screen ntp ncdu swapspace rsync -y
modprobe ip_vs
echo 'ip_vs' >> /etc/modules-load.d/modules.conf

# after master reboot:
# docker service update --force  portainer_agent

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
apt install -y docker-ce docker-ce-cli containerd.io


service docker restart
docker -v
# docker -v 24.0.2,  (sudo usermod -aG docker $USER, newgrp docker )

echo '{ "features": { "buildkit": true } }' > /etc/docker/daemon.json
docker swarm init
# docker login docker-registry... -u user -p password

# docker service create --name registry --publish published=5000,target=5000 registry:2
# TODO: https://github.com/moby/buildkit/issues/1368

curl -L https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VER}/docker-compose-`uname -s`-`uname -m` -o /usr/bin/docker-compose
chmod +x /usr/bin/docker-compose
docker-compose -v
# docker-compose -v 2.19.0

# apt install -y docker-compose-plugin

# docker compose
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

