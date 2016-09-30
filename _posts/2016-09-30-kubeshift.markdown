---
layout: post
category: kubernetes
title: "Kubeshift: A Python library for Kubernetes and OpenShift"
date: 2016-09-30 10:46
---

A Python library for OpenShift was needed after a search came up with [only one](https://github.com/openshift/python-interface) library that's no longer being developed.

With Kubernetes and OpenShift being such similar projects. It made sense to have a universal Python library that's able to communicate with both.

Taking the code from a [previous project](https://github.com/projectatomic/atomicapp) the team at Project Atomic and I worked on, [Kubeshift](https://github.com/cdrage/kubeshift) was created.

It's super easy to use [Kubeshift](https://github.com/cdrage/kubeshift).

### Installation

Installation is done either through Git clone or Pip.

```sh
git clone https://github.com/cdrage/kubeshift && cd kubeshift && sudo make install
# or
sudo pip install kubeshift
```

### Use

After bringing your Kubernetes cluster / OpenShift cluster up, use one of the built-in methods to create a pod!

```python
import kubeshift
import getpass

# Example k8s object
k8s_object = {"apiVersion": "v1", "kind": "Pod", "metadata": {"labels": {"app": "hellonginx"}, "name": "hellonginx"}, "spec": {
    "containers": [{"image": "nginx", "name": "hellonginx", "ports": [{"containerPort": 80, "hostPort": 80, "protocol": "TCP"}]}]}}

# Client configuration
user = getpass.getuser()
config = kubeshift.Config.from_file("/home/%s/.kube/config" % user)
client = kubeshift.KubernetesClient(config)
# client = kubeshift.OpenshiftClient(config)

# Create an object
client.create(k8s_object)  # Creates the k8s object
```


### Main features

[Kubeshift](https://github.com/cdrage/kubeshift) excels at configuration generation. Either specifying a configuration file (ex. `/ghome/user/.kube/config`) or leaving it blank will generate an appropriate config in order to communicate to the cluster.

Every API call is implemented as a function within each provider.

For more information on [Kubeshift](https://github.com/cdrage/kubeshift) as well as further documentation on each method, check out the GitHub repo.
