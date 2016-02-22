---
layout: post
topic: containers
title: Simple Kubernetes development environment in Docker
date: 2016-02-22 13:55
---

I'm tired of using bloaty Vagrant images. It's much simpler to grab a few containers and throw them up to development against.

Recently (December 15th), Kubernetes updated their local dev environment bash script to a one-liner.

This is how I develop against Kubernetes. Add this to your .bashrc / .zshrc and run: `dev_k8s up`

```sh
dev_k8s(){
  local choice=$1
  K8S_VERSION=1.2.0-alpha.7

  if [[ $choice == "up" ]]; then
    echo "Launching local k8s cluster"
    docker run \
    --volume=/:/rootfs:ro \
    --volume=/sys:/sys:ro \
    --volume=/var/lib/docker/:/var/lib/docker:rw \
    --volume=/var/lib/kubelet/:/var/lib/kubelet:rw \
    --volume=/var/run:/var/run:rw \
    --net=host \
    --pid=host \
    --privileged=true \
    -d \
    gcr.io/google_containers/hyperkube-amd64:v${K8S_VERSION} \
    /hyperkube kubelet \
        --containerized \
        --hostname-override="127.0.0.1" \
        --address="0.0.0.0" \
        --api-servers=http://localhost:8080 \
        --config=/etc/kubernetes/manifests \
        --cluster-dns=10.0.0.10 \
        --cluster-domain=cluster.local \
        --allow-privileged=true --v=2
    echo "Waiting for k8s containers to initialize" 
    until nc -z 127.0.0.1 8080;
    do
      echo ...
      sleep 1
    done
    echo "Launched!"
  elif [[ $choice == "down" ]]; then
    echo "Removing local k8s cluster"
    docker ps -a | grep 'k8s_' | awk '{print $1}' | xargs --no-run-if-empty docker rm -f
    docker ps -a | grep 'gcr.io/google_containers/hyperkube-amd64' | awk '{print $1}' | xargs --no-run-if-empty docker rm -f
  elif [[ $choice == "restart" ]]; then
    dev_k8s down
    dev_k8s up
  else
    echo "Kubernetes dev environment"
    echo "Usage: dev_k8s {up|down|restart}"
  fi
}
```

Want to bring it down or restart it? `dev_k8s down`, `dev_k8s restart`.

Seriously, that's it. If you ever want to update in the future, simple substitute the K8S_VERSION variable with the corresponding version.
