##
REMOTE_CLIENT=root@188.225.46.50
REMOTE_MASTER=swarm

# SWARM=true

# ZFS=false

# INSECURE_REGISTRY=10.100.4.2:5000
# REGISTRY_PROXIES=true

# WIREGUARD=true
# WIREGUARD_CONF=wg_perfdemo
# WIREGUARD_NETWORK=10.100.4.0
# WIREGUARD_SERVER_PORT=51820

#TRAEFIK=true
#TRAEFIK_DOMAIN=performance.reg-demo.monitorsoft.ru

#PORTAINER=true

## START
alias remote_master="ssh ${REMOTE_MASTER} 'bash -s' "
alias remote_client="ssh ${REMOTE_CLIENT} 'bash -s' "

if [ "$SWARM" = true ] ; then
    echo "Installing Swarm..."
    remote_client < new/swarm_server_init.sh
fi

if [ "$REGISTRY_PROXIES" = true ] ; then
    echo "Installing registry proxies..."
    remote_client < new/registry-proxies.sh
fi

if [ -n "$INSECURE_REGISTRY" ] ; then
    echo "Adding insecure registry..."
    remote_client < new/insecure-registry.sh $INSECURE_REGISTRY
fi

if [ "$WIREGUARD" = true ] ; then
    echo "Installing Wireguard server on client..."
    server_ip=$(echo "$WIREGUARD_NETWORK" | awk -F'.' '{$4="1"; print}' OFS='.')"/24"
    allowed_ips=$(echo "$WIREGUARD_NETWORK" | awk -F'.' '{$4="0"; print}' OFS='.')"/24"
    client_ip=$(echo "$WIREGUARD_NETWORK" | awk -F'.' '{$4="2"; print}' OFS='.')"/32"
    server_public_ip=$(ssh ${REMOTE_CLIENT} hostname -I | awk '{print $1}')
    echo "server_ip: ${server_ip}"
    echo "client_ip: ${client_ip}"
    echo "allowed_ips: ${allowed_ips}"
    echo "server_public_ip: ${server_public_ip}"
    remote_client < new/wg_install.sh server $WIREGUARD_CONF $server_ip $WIREGUARD_SERVER_PORT
    server_pubkey=$(ssh ${REMOTE_CLIENT} cat /etc/wireguard/public.key)
    echo "Server public key:" $server_pubkey
    remote_master < new/wg_install.sh client $WIREGUARD_CONF $server_public_ip:$WIREGUARD_SERVER_PORT $server_pubkey $client_ip
    master_pubkey=$(ssh ${REMOTE_MASTER} cat /etc/wireguard/public.key)
    echo "Master public key:" $master_pubkey
    allowed_ips=$(echo "$WIREGUARD_NETWORK" | awk -F'.' '{$4="0"; print}' OFS='.')"/24"
    ssh ${REMOTE_CLIENT} tee -a /etc/wireguard/"$WIREGUARD_CONF".conf << EOF

[Peer]
    PublicKey = $master_pubkey
    AllowedIPs = $client_ip

EOF
    echo "Peer appended"
    ssh ${REMOTE_CLIENT} wg-quick down $WIREGUARD_CONF
    ssh ${REMOTE_CLIENT} wg-quick up $WIREGUARD_CONF
    ssh ${REMOTE_MASTER} wg-quick up $WIREGUARD_CONF
fi

if [ "$TRAEFIK" = true ] ; then
    echo "Deploying Traefik..."
    cat stacks/ingress.drs | ssh ${REMOTE_CLIENT}  "TRAEFIK_DOMAIN=\"$TRAEFIK_DOMAIN\" dry-stack -n to_compose"
    cat stacks/ingress.drs | ssh ${REMOTE_CLIENT}  "TRAEFIK_DOMAIN=\"$TRAEFIK_DOMAIN\" dry-stack -n swarm_deploy -- --prune"
fi

if [ "$PORTAINER" = true ] ; then
    echo "Deploying Portainer..."
    cat stacks/portainer.drs | ssh ${REMOTE_CLIENT}  "TRAEFIK_DOMAIN=\"$TRAEFIK_DOMAIN\" dry-stack -n swarm_deploy -- --prune"
fi
