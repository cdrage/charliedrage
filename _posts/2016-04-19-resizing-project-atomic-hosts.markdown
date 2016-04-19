---
layout: post
category: atomic
title: Resizing Project Atomic hosts with virt-resize
date: 2016-04-19 12:01
---

Got a fresh .qcow2 image from [Fedora](https://getfedora.org/cloud/download/atomic.html) and want to resize it before deploying it on your KVM cluster?

Here's a way to resize it without having to boot it up and expand the partitions yourself. 

```sh
wget https://download.fedoraproject.org/pub/alt/atomic/stable/Cloud-Images/x86_64/Images/Fedora-Cloud-Atomic-23-20160405.x86_64.qcow2 -O fedora23-cloud.qcow2
qemu-img create -f qcow2 40G-fedora23-cloud.qcow2 40G
virt-resize --expand /dev/sda2 --LV-expand /dev/atomicos/root fedora23-cloud.qcow2 40G-fedora23-cloud.qcow2
```

That's it!

Keep in mind that even though __/var/atomicos/root__ has been expanded, you must increase your Docker storage via __/etc/sysconfig/docker-storage-setup__. 

This can be configured either though cloud initialization data or manually within the file.

```yaml
#cloud-config
write_files:
  - path: /etc/sysconfig/docker-storage-setup
    permissions: 0644
    owner: root
    content: |
      ROOT_SIZE=30G
```
