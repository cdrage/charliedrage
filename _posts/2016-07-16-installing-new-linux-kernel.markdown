---
layout: post
category: linux
title: TLDR; Installing a new Linux kernel on Debian 8
date: 2016-07-16 12:18
---

Recently I had to update my Kernel in order to use [OverlayFS](https://github.com/torvalds/linux/commit/e9be9d5e76e34872f0c37d72e25bc27fe9e2c54c) which was introduced in Kernel 3.18. Unfortunatley Debian 8 is still on 3.16. That, and the fact that I've been wanting to use the newest + latest Kernel improvements.

```
#!/bin/bash
VERSION=4-6-4 # or w/e is newest
wget https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-$VERSION.tar.xz
tar xaf linux-$VERSION.tar.xz
cd linux-$VERSION
cp /boot/config-$(uname -r) .config # the default config used for debian
make nconfig # just click save if you're not doing anything special
make deb-pkg -j4 # this will take a while... change -j# to # of CPU cores for faster compiling
dpkg -i linux-image-*.deb
sudo shutdown -r now # you'll see it in GRUB
```
