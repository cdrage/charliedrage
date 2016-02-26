---
layout: post
category: docker
title: an instant(ish) openvpn server
date: 2015-11-19 01:02:03
---

Ever want to launch your own Docker VPN with no configuration necessary?


### On the server

Run the OpenVPN server

```sh
git clone https://github.com/charliedrage/dockerfiles .
cd ~/charliedrage/openvpn-server
docker build -t openvpn .
CID=$(docker run -d --privileged -p 1194:1194/udp -p 443:443/tcp openvpn)
```

Let's temporarily serve our openvpn config :)

```sh
 docker run -t -i -p 8080:8080 --volumes-from $CID opvenvpn serveconfig
```

Don't exit! Keep it up and running until we download it from our client.

#### On the client

Let's setup our VPN

```sh
git clone https://github.com/charliedrage/dockerfiles .
cd ~/charliedrage/openvpn-client
docker build -t openvpn-client .
curl YOURSERVERIP:8080 > openvpn.conf 
```

Now that you've got the config and built the server let's run the client

```sh
docker run -it -v /home/yourusername/openvpn.conf:/etc/openvpn/openvpn.conf --net=host --device /dev/net/tun:/dev/net/tun --cap-add=NET_ADMIN openvpn-client openvpn.conf
```

You're done! Go check your ip at http:/icanhazip.com and you'll see it's the VPN's.
