---
layout: post
category: docker networking
title: easy multi-host networking
date: 2015-11-06 01:02:03
---

The release of __Docker 1.9__ has brought native multi-host networking into the mix. This changes _a lot_ in the container orchestration world. Ever try to install Kubernetes on a bare metal server without already-implemented private networking? It's a pain in the ass. 

1.9 also adds libnetwork, changing how Docker will communicate to neighbouring containers. Soon  __"links"__ or __--link__ will be [deprecated](https://docs.docker.com/engine/userguide/networking/dockernetworks/) in favour of Docker's internal networking.

Instead of:

```bash
docker run -d mysql
docker run --link:mysql:db -d nginx
```

It will eventually be:

```bash
docker network create --driver bridge isolated_nw
docker run --net=isolated_nw -d nginx
docker run --net=isolated_nw -d mysql
```

Making (imo) inter-container communication _much_ easier. 

Oh, and hostnames resolve too. __--name=awesomeapp__ and it'll resolve __awesomeapp__ within the network.

Anyways! Back to multi-host networking and setting this shit up between two different hosts.

The nitty gritty of it is that Docker is using VXLAN in order to tunnel your connections between hosts. A Key-Value server is thrown into the mix to keep everything together. As of right now, either: Consul, Zookeeper or Etcd is supported. When specifying the __--driver overlay__ option when creating the network, Docker tunnels these connections between hosts in order to communicate on the same overlay network.

Enough with the talk, let's get to the examples!

There's two ways to deploy an overlay multi-host network, either:

  1. You deploy using [docker-machine](https://github.com/dave-tucker/docker-network-demos/blob/master/multihost-local.sh).

  2. You manually deploy a Consul server and input into your Docker config:

```
--cluster-store=PROVIDER://URL
--cluster-advertise=HOST_IP
```

We'll focus on using docker-machine for deployment, if you'd like to configure it manually visit the official [docs](https://docs.docker.com/engine/userguide/networking/dockernetworks/).

## Now let's set it up!

###Define the servers you're using

_Let's assume you have root access to your server and SSH running._

```bash
export IP1=10.10.10.1 # our consul server
export IP2=10.10.10.2 # machine 1
export IP3=10.10.10.3 # machine 2
```

###First, let's get our Consul server up and running.

```bash
docker-machine create \
    -d generic \
    --generic-ip-address $IP1 \
    consul

docker $(docker-machine config consul) run -d \
    -p "8500:8500" \
    -h "consul" \
    progrium/consul -server -bootstrap
```

###Our first multi-host server

```bash
docker-machine create \
    -d generic \
    --generic-ip-address $IP2 \
    --engine-opt="cluster-store=consul://$(docker-machine ip consul):8500" \
    --engine-opt="cluster-advertise=eth0:0" \
    machine1
```

###Our second multi-host server

```bash
docker-machine create \
    -d generic \
    --generic-ip-address $IP3 \
    --engine-opt="cluster-store=consul://$(docker-machine ip consul):8500" \
    --engine-opt="cluster-advertise=eth0:0" \
    machine2
```

###Use docker-machine env variables and setup the overlay network

```bash
docker $(docker-machine config machine1) network create -d overlay myapp
docker $(docker-machine config machine2) network ls
```

Use __docker network ls__ on any host and you'll see that the overlay network is now available as __myapp__. This network is available to all of those clustered to the same KV (Consul) server.

###Now use containers and the overlay network!

```bash
docker $(docker-machine config machine1) run -d --name=web --net=myapp nginx
docker $(docker-machine config machine1) run -d --name=db --net=myapp mysql

```

That's it :)
