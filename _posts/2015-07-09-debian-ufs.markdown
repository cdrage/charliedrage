---
layout: post
category: linux + kernel
title: recompiling your kernel with ufs readwrite support
date: 2015-07-09 01:02:03
---

Working with kvm/qemu involves using libguestfs-tools sometimes in order to prep the deployment of servers. I've come across the issue of read/writing to FreeBSD partitions using the mount tool. Even though it's 2015, the Linux Kernel still has experimental write support for UFS. Here's how to recompile your kernel with ufs write support.

```bash
apt-get install linux-source kernel-package
cd /usr/src
bzip2 -dc linux-source-x.y.z.tar.bz2 | tar xf -
cd linux-source-x.y.z/
cp /boot/config-x.y.z-amd64-generic .config
sed -i 's/# CONFIG_UFS_FS_WRITE is not set/CONFIG_UFS_FS_WRITE=y/' /usr/src/linux-source-x.y.z/.config
CONCURRENCY_LEVEL=4 make-kpkg --initrd --append-to-version=awesome-custom-ufs-kernel kernel-image kernel-headers
dpkg -i /usr/src/linux-image-x.y.z.deb
```

Reboot, select from GRUB and you're done!

07/19/15 Update: UFS write support is still EXPERIMENTAL and unfortunatley I've already encountered numerous bugs (within virt-sysprep + virt-customize)
