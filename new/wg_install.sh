apt install -y wireguard

wg genkey | sudo tee /etc/wireguard/private.key
chmod go= /etc/wireguard/private.key
cat /etc/wireguard/private.key | wg pubkey | tee /etc/wireguard/public.key
wg_private=$(cat /etc/wireguard/private.key)

tee /etc/wireguard/wg0.conf << END
[Interface]
PrivateKey = ${wg_private}
Address = 10.8.0.1/24
ListenPort = 51820
SaveConfig = true

# PostUp = ufw route allow in on wg0 out on eth0
# PostUp = iptables -t nat -I POSTROUTING -o eth0 -j MASQUERADE
# PostUp = ip6tables -t nat -I POSTROUTING -o eth0 -j MASQUERADE
# PreDown = ufw route delete allow in on wg0 out on eth0
# PreDown = iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
# PreDown = ip6tables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

# [Interface]
# PrivateKey = base64_encoded_peer_private_key_goes_here
# Address = 10.8.0.2/24
#
# [Peer]
# PublicKey = U......E=
# AllowedIPs = 10.8.0.0/24
# Endpoint = server_ip:51820


# wg set wg0 peer P...hg= allowed-ips 10.8.0.2
END

systemctl enable wg-quick@wg0.service
systemctl start wg-quick@wg0.service
systemctl status wg-quick@wg0.service

# /etc/sysctl.conf
# net.ipv4.ip_forward=1
# net.ipv6.conf.all.forwarding=1
# sysctl -p

# ufw allow 51820/udp
# ufw allow OpenSSH
