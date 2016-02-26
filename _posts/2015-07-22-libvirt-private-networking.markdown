---
layout: post
category: linux
title: enabling private networking with virtio with libvirt
date: 2015-07-20 01:02:03
---

After trying for hours as to why I kept getting:

```bash
DHCPDISCOVER on eth1 to 255.255.255.255 port 67 interval 7 
DHCPDISCOVER on eth1 to 255.255.255.255 port 67 interval 12
DHCPDISCOVER on eth1 to 255.255.255.255 port 67 interval 10
```

when setting up private networking with libvirt (QEMU/KVM). I found out that the virtio driver was the root of the cause and came across [this article](https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/6/html/Virtualization_Host_Configuration_and_Guest_Installation_Guide/ch11s02.html).

Seems that using virtio when setting up a private networking causes some issues.

To enable private networking:

```bash
virsh edit vm1
```

and add 

```xml
 <driver name='qemu'/> 
```

to the network interface.

