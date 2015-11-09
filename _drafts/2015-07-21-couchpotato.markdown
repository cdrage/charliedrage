---
layout: post
title: "media server with couchpotato, transmission and samba in four lines"
date: 2015-07-19 01:02:03
---

```bash
mkdir /data
docker run --name transmission -p 9091:9091 -v /data:/var/lib/transmission-daemon/downloads -d transmission
docker run -d -p 5050:5050 -v /data:/data --name couchpotato couchpotato
mkdir ~/plex-config
chown 797:797 -R ~/plex-config
docker run -d -v ~/plex-config:/config -v /data:/media -p 32400:32400 --net=host --name plex plex
```
