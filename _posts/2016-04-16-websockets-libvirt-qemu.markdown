---
layout: post
category: libvirt
title: Setting up websockets for libvirt vnc connections
date: 2016-04-16 21:30
---

Spend hours trying to figure this out, but if you want to setup websockets (aka connecting to a libvirt/qemu based kvm vm via vnc / novnc web client), the port must be 5700 + VNC display port.

As per [this commit](http://git.qemu.org/?p=qemu.git;a=commit;h=7536ee4bc3da7e9b7fdadba5ba6ade63eaace430)

Thus if you do:

```
virsh qemu-monitor-command --hmp mydomain change vnc :1, websocket
```

You would connect at port 5701
