#!/bin/bash
# curl https://raw.githubusercontent.com/artyomb/servers/main/new/wg_install.sh | sh -s server wg1 10.0.0.1/24 51820
# curl https://raw.githubusercontent.com/artyomb/servers/main/new/wg_install.sh | sh -s client wg1 123.123.123.123:51820 Pub...Key 10.0.0.2/32
if [ "$#" -eq 0 ]; then
  echo "Commands example:"
  echo "server wg0 10.8.0.1/24 51820"
  echo "client wg0 123.123.123.123:51820 P...asd=  10.8.0.2/24"
  exit
fi

conf_name=${2:-"wg0"}
echo "conf_name: ${conf_name}"

apt install -y wireguard

if [ ! -e /etc/wireguard/private.key ]; then
  wg genkey | sudo tee /etc/wireguard/private.key
  chmod go= /etc/wireguard/private.key
  cat /etc/wireguard/private.key | wg pubkey | tee /etc/wireguard/public.key
fi

wg_private=$(cat /etc/wireguard/private.key)

systemctl enable wg-quick@${conf_name}.service
systemctl start wg-quick@${conf_name}.service
systemctl status wg-quick@${conf_name}.service

case "$1" in
    "server")
        network=${3:-"10.8.0.1/24"}
        port=${4:-"51820"}
        echo "network: ${network}"
        echo "port: ${port}"

        tee /etc/wireguard/"${conf_name}".conf << END
[Interface]
PrivateKey = ${wg_private}
Address = ${network}
ListenPort = ${port}
SaveConfig = true

# PostUp = ufw route allow in on wg0 out on eth0
# PostUp = iptables -t nat -I POSTROUTING -o eth0 -j MASQUERADE
# PostUp = ip6tables -t nat -I POSTROUTING -o eth0 -j MASQUERADE
# PreDown = ufw route delete allow in on wg0 out on eth0
# PreDown = iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
# PreDown = ip6tables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
END
        echo "Server public key:"
        echo "$(cat /etc/wireguard/public.key)"

        # /etc/sysctl.conf
        # net.ipv4.ip_forward=1
        # net.ipv6.conf.all.forwarding=1
        # sysctl -p

        # ufw allow 51820/udp
        # ufw allow OpenSSH
        ;;

    "client")
        server_ip=${3:-"SERVER_IP:51820"}
        server_public=${4:-"SERVER_PUBLIC_KEY"}
        client_ip=${5:-"10.8.0.2/32"}
        echo "server_ip: ${server_ip}"
        echo "server_public: ${server_public}"
        echo "client_ip: ${client_ip}"

        tee /etc/wireguard/"${conf_name}".conf << END
[Interface]
PrivateKey = ${wg_private}
Address = ${client_ip}

[Peer]
PublicKey = ${server_public}
# AllowedIPs = 10.8.0.0/24
Endpoint = ${server_ip}
PersistentKeepalive = 20
END
        echo "Run on server:"
        echo "wg set ${conf_name} peer $(cat /etc/wireguard/public.key)= allowed-ips ${client_ip}"
        ;;
    *)
        echo "Invalid command. Usage: $0 {server|client}"
        exit 1
        ;;
esac
