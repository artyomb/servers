#!/bin/bash
# curl https://raw.githubusercontent.com/artyomb/servers/main/new/wg_install.sh | sh
if [ "$#" -eq 0 ]; then
  echo "Commands example:"
  echo "server wg0 10.8.0.1/24"
  echo "client wg0 123.123.123.123 P...asd=  10.8.0.2/24"
  exit
fi

apt install -y wireguard

wg genkey | sudo tee /etc/wireguard/private.key
chmod go= /etc/wireguard/private.key

cat /etc/wireguard/private.key | wg pubkey | tee /etc/wireguard/public.key
wg_private=$(cat /etc/wireguard/private.key)

systemctl enable wg-quick@wg0.service
systemctl start wg-quick@wg0.service
systemctl status wg-quick@wg0.service

case "$1" in
    "server")
        conf_name=${2:-"wg0"}
        network=${3:-"10.8.0.1/24"}
        echo "conf_name: ${conf_name}"
        echo "network: ${network}"

        tee /etc/wireguard/"${conf_name}".conf << END
[Interface]
PrivateKey = ${wg_private}
Address = ${network}
ListenPort = 51820
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
        conf_name=${2:-"wg0"}
        server_ip=${3:-"SERVER_IP:51820"}
        server_public=${4:-"SERVER_PUBLIC_KEY"}
        client_ip=${5:-"10.8.0.2/24"}
        echo "conf_name: ${conf_name}"
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
END
        echo "Run on server:"
        echo "wg set ${conf_name} peer $(cat /etc/wireguard/public.key)= allowed-ips 10.8.0.2"
        ;;
    *)
        echo "Invalid command. Usage: $0 {server|client}"
        exit 1
        ;;
esac
