---
layout: post
title: "media server with couchpotato, transmission and samba in four lines"
date: 2015-07-19 01:02:03
---

```bash
mkdir /data
docker run --name transmission -p 9091:9091 -v /data:/var/lib/transmission-daemon/downloads -d transmission
docker run -d -p 5050:5050 -v /data:/data --name couchpotato couchpotato
docker run -d -p 445:445 -p 137:137 -p 138:138 -p 139:139 -v /data:/data --env workgroup=workgroup --name samba samba
```

server:9091 # couchpotato
server:5050 # transmission
\\server\data # samba/windows share dir


