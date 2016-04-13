---
layout: post
category: docker
title: Kubernetes local development cluster up in one command
date: 2016-03-23 12:45
---

Want a Kubernetes / k8s local development cluster without having to follow an installation guide, grab the latest containers, etc?

Simply add this to your __.bashrc__ (or __source foobar.sh__ it, whatever you'd like) and run __dev_k8s up__. Need to take it down? __dev_k8s down__.

Oh, the only things you need is  __docker__ and the __kubectl__ binary installed, but I assume you already have that :)

__Usage:__

```
▶ dev_k8s
Kubernetes dev environment

Usage: 
 dev_k8s {up|down|restart|clean|gui|dns|pv}

Methods: 
 up
 down
 restart
 clean - returns k8s env to a clean slate
 gui - ui for k8s at localhost:9090
 dns - deployment of skydns / name resolution
 pv - creates a 20Gb persistent volume named foobar at /tmp/foobar
```

__Script:__

```sh
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
      --name=kubelet \
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

    echo "\n-----Create the kube-system namespace-----\n"
    kubectl create namespace kube-system

    echo "\n-----Ready for development!-----\n"

  elif [[ $choice == "down" ]]; then
    echo "\n-----Removing all namespaces-----\n"
    kubectl delete --all namespaces

    echo "\n-----Remove EVERYTHINGGGG-----\n"
    kubectl get pvc,pv,svc,rc,po --all-namespaces | grep -v 'k8s-\|NAME\|CONTROLLER\|kubernetes' | awk '{print $2}' | xargs --no-run-if-empty kubectl delete pvc,pv,svc,rc,po 2>/dev/null

    echo "\n-----Waiting for everything to terminate-----\n"
    kubectl get po,svc,rc --all-namespaces
    sleep 3 # give kubectl chance to catch up to api call
    while [ 1 ]
    do
      k8s=`kubectl get po,svc,rc --all-namespaces | grep Terminating`
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

    # Remove the initial kubelet
    docker rm -f kubelet

    for run in {0..2}
    do
      docker ps -a | grep 'k8s_' | awk '{print $1}' | xargs --no-run-if-empty docker rm -f
      docker ps -a | grep 'gcr.io/google_containers/hyperkube-amd64' | awk '{print $1}' | xargs --no-run-if-empty docker rm -f
    done

    rm ~/.kube/config

  elif [[ $choice == "clean" ]]; then
    echo "\n-----Cleaning / removing all pods and containers from default namespace-----\n"
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

  elif [[ $choice == "gui" ]]; then
    kubectl create -f "https://raw.githubusercontent.com/kubernetes/kubernetes/release-1.2/cluster/addons/dashboard/dashboard-controller.yaml" --namespace=kube-system
    kubectl create -f "https://raw.githubusercontent.com/kubernetes/kubernetes/release-1.2/cluster/addons/dashboard/dashboard-service.yaml" --namespace=kube-system

  elif [[ $choice == "dns" ]]; then
    # Set the amount of dns replicas and env variables
    export DNS_REPLICAS=1
    export DNS_DOMAIN=cluster.local
    export DNS_SERVER_IP=10.0.0.10

    # Grab the official dns yaml file
    wget http://kubernetes.io/docs/getting-started-guides/docker-multinode/skydns.yaml.in -O skydns.yaml.in
    sed -e "s/{{ pillar\['dns_replicas'\] }}/${DNS_REPLICAS}/g;s/{{ pillar\['dns_domain'\] }}/${DNS_DOMAIN}/g;s/{{ pillar\['dns_server'\] }}/${DNS_SERVER_IP}/g" skydns.yaml.in > ./skydns.yaml

    # Because of https://github.com/kubernetes/kubernetes/issues/23474
    #dns="\ \ \ \ \ \ \ \ - -nameservers=8.8.8.8:53"
    #sed -i "73i$dns" skydns.yaml

    # Deploy!
    kubectl get ns
    kubectl create -f ./skydns.yaml
    rm skydns.yaml*
  
  elif [[ $choice == "restart" ]]; then
    dev_k8s down
    dev_k8s up

  elif [[ $choice == "pv" ]]; then
    mkdir -p /tmp/foobar
    cat <<EOF | kubectl create -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: foobar
spec:
  capacity:
    storage: 20Gi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Recycle
  hostPath:
    path: /tmp/foobar
EOF

  else
    echo "Kubernetes dev environment"
    echo "\nUsage: "
    echo " dev_k8s {up|down|restart|clean|gui|dns|pv}"
    echo "\nMethods: "
    echo " up"
    echo " down"
    echo " restart"
    echo " clean - returns k8s env to a clean slate"
    echo " gui - ui for k8s at localhost:9090"
    echo " dns - deployment of skydns / name resolution"
    echo " pv - creates a 20Gb persistent volume named foobar at /tmp/foobar"
  fi
}
```
