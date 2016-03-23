---
layout: post
category: docker
title: Kubernetes development cluster up in one command
date: 2016-03-23 12:45
---

Want a Kubernetes / k8s local development cluster without having to follow an installation guide, grab the latest containers, etc?

Simply add this to your __.bashrc__ (or __source foobar.sh__ it, whatever you'd like) and run __dev_k8s up__. Need to take it down? __dev_k8s down__.

Oh, and you need __Docker__ installed, but I assume you already have that :)

```bash
dev_k8s(){
  local choice=$1
  K8S_VERSION=1.2.0

  if [ ! -f /usr/bin/kubectl ] && [ ! -f /usr/local/bin/kubectl ]; then
    echo "No kubectl bin exists! Install the bin to continue :)."
    return 1
  fi

  if [[ $choice == "up" ]]; then
    echo "\n-----Launching local k8s cluster-----\n"
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

    echo "\n-----Waiting for k8s to initialize-----\n"
    until curl 127.0.0.1:8080 &>/dev/null;
    do
      echo ...
      sleep 1
    done
    echo "\n-----Launched!-----\n"

    echo "\n-----Setting local dev variables-----\n"
    kubectl config set-cluster dev --server=http://localhost:8080
    kubectl config set-context dev --cluster=dev --user=default
    kubectl config use-context dev
    kubectl config set-credentials default --token=foobar

    echo "\n-----Ready for development!-----\n"

  elif [[ $choice == "down" ]]; then
    echo "\n-----Removing all namespaces-----\n"
    kubectl delete --all namespaces

    echo "\n-----Remove EVERYTHINGGGG-----\n"
    kubectl get pvc,pv,svc,rc,po | grep -v 'k8s-\|NAME\|CONTROLLER\|kubernetes' | awk '{print $1}' | xargs --no-run-if-empty kubectl delete pvc,pv,svc,rc,po 2>/dev/null

    echo "\n-----Waiting for everything to terminate-----\n"
    kubectl get po,svc,rc
    sleep 3 # give kubectl chance to catch up to api call
    while [ 1 ]
    do
      k8s=`kubectl get po,svc,rc | grep Terminating`
      if [[ $k8s == "" ]]
      then
        break
      else
        echo "..."
      fi
      sleep 1
    done

    # Run twice due to issue with aufs debian driver
    echo "\n-----Removing all k8s containers-----\n"

    for run in {0..2}
    do
      docker ps -a | grep 'k8s_' | awk '{print $1}' | xargs --no-run-if-empty docker rm -f
      docker ps -a | grep 'gcr.io/google_containers/hyperkube-amd64' | awk '{print $1}' | xargs --no-run-if-empty docker rm -f
    done

    rm ~/.kube/config

  elif [[ $choice == "restart" ]]; then
    dev_k8s down
    dev_k8s up

  else
    echo "Kubernetes dev environment"
    echo "Usage: dev_k8s {up|down|restart}"
  fi
}
```
