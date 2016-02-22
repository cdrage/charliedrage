---
layout: post
topic: containers
title: Simple OpenShift Origin development environment in Docker
date: 2016-02-22 14:01
---

Similar to my previous post. Here's the same thing but in OpenShift.

Throw this in your .bashrc / .zshrc and run __dev_openshift__

```sh
dev_openshift(){
  local choice=$1

  if [[ $choice == "up" ]]; then
    echo "Launching local openshift cluster"
    docker run -d --name "origin" \
      --privileged --pid=host --net=host \
      -v /:/rootfs:ro -v /var/run:/var/run:rw -v /sys:/sys -v /var/lib/docker:/var/lib/docker:rw \
      -v /var/lib/origin/openshift.local.volumes:/var/lib/origin/openshift.local.volumes \
      openshift/origin start
    echo "Waiting for openshift to initialize" 
    until nc -z 127.0.0.1 8443;
    do
      echo ...
      sleep 1
    done
    echo "Launched!"
    echo "Grapping access token"
    API_KEY=`curl -k -L -D - -u openshift:openshift -H 'X-CSRF-Token: 1' 'https://localhost:8443/oauth/authorize?response_type=token&client_id=openshift-challenging-client' 2>&1 | grep -oP "access_token=\K[^&]*"`
    export API_KEY
    echo "Access token: " $API_KEY
    echo "Token exported to API_KEY"
    oc config set-credentials openshift --token=$API_KEY
    oc config set-cluster openshift1 --server=https://localhost:8443 --insecure-skip-tls-verify=true
    oc config set-context openshift --cluster=openshift1 --user=openshift
    oc config use-context openshift
    oc config set contexts.openshift.namespace foo
    sleep 1
    oc new-project foo
  elif [[ $choice == "down" ]]; then
    echo "Removing local openshift cluster"
    # Remove origin
    docker rm -f origin

    # Remove all kubernetes back-end containers created by origin
    docker ps -a | grep 'gcr.io/google_containers/hyperkube' | awk '{print $1}' | xargs --no-run-if-empty docker rm -f
    docker ps -a | grep 'gcr.io/google_containers/etcd' | awk '{print $1}' | xargs --no-run-if-empty docker rm -f
    docker ps -a | grep 'k8s_' | awk '{print $1}' | xargs --no-run-if-empty docker rm -f || true
  elif [[ $choice == "restart" ]]; then
    echo "Removing and restarting local dev cluster"
    dev_openshift down
    dev_openshift up
  else
    echo "OpenShift dev environment"
    echo "Usage: openshift {up|down|restart}"
  fi
}
```

