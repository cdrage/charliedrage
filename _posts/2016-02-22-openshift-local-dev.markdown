---
layout: post
category: containers
title: Simple OpenShift Origin development environment in Docker
date: 2016-02-22 14:01
---

Similar to my previous post. Here's the same thing but in OpenShift.

Throw this in your .bashrc / .zshrc and run __dev_openshift__

```sh
dev_openshift(){
  local choice=$1

  if [ ! -f /usr/bin/oc ] && [ ! -f /usr/local/bin/oc ]; then
    echo "No oc bin exists? Please install."
    return 1
  fi

  if [[ $choice == "up" ]]; then
    echo "\n-----Launching local openshift cluster-----\n"
    docker run -d --name "origin" \
      --privileged --pid=host --net=host \
      -v /:/rootfs:ro -v /var/run:/var/run:rw -v /sys:/sys -v /var/lib/docker:/var/lib/docker:rw \
      -v /var/lib/origin/openshift.local.volumes:/var/lib/origin/openshift.local.volumes \
      openshift/origin start

    echo "\n-----Initializing containers, please wait-----\n"
    until nc -z 127.0.0.1 8443;
    do
      echo ...
      sleep 1
    done

    echo "\n-----Launched!-----\n"

    # Access token stuff
    echo "\n-----Grabbing access tokens-----\n"
    API_KEY=`curl -k -L -D - -u openshift:openshift -H 'X-CSRF-Token: 1' 'https://localhost:8443/oauth/authorize?response_type=token&client_id=openshift-challenging-client' 2>&1 | grep -oP "access_token=\K[^&]*"`
    export API_KEY
    echo $API_KEY
    echo "Token exported to API_KEY"

    echo "\n-----Setting local dev variables-----\n"
    oc config set-credentials openshift --token=$API_KEY
    oc config set-cluster openshift1 --server=https://localhost:8443 --insecure-skip-tls-verify=true
    oc config set-context openshift --cluster=openshift1 --user=openshift
    oc config use-context openshift
    oc config set contexts.openshift.namespace foo
    sleep 1
    oc new-project foo

    echo "\n-----Ready for development!-----\n"

  elif [[ $choice == "down" ]]; then
    echo "\n-----Removing OpenShift container-----\n"
    docker rm -f origin

    # Remove all kubernetes back-end containers created by origin
    # Ran twice due to Debian aufs "busy" driver issue
    echo "\n-----Removing leftover k8s containers-----\n"
    for run in {0..2}
    do
      docker ps -a | grep 'gcr.io/google_containers/hyperkube' | awk '{print $1}' | xargs --no-run-if-empty docker rm -f
      docker ps -a | grep 'gcr.io/google_containers/etcd' | awk '{print $1}' | xargs --no-run-if-empty docker rm -f
      docker ps -a | grep 'k8s_' | awk '{print $1}' | xargs --no-run-if-empty docker rm -f || true
    done

    rm ~/.kube/config
  elif [[ $choice == "restart" ]]; then
    dev_openshift down
    dev_openshift up
  else
    echo "OpenShift dev environment"
    echo "Usage: openshift {up|down|restart}"
  fi
}
```
