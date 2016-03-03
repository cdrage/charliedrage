---
layout: post
category: docker
title: Deploying a Sensu server with docker-compose
date: 2016-03-03 16:22
---

This is an update of my previous post [here](/sensu-server-docker-with-notifications) with a __wayyyy__ easier method of deploying a sensu server.

I'm not going to go too much into detail. But if you've found this post, you're most likely coming from Google and already know what Sensu is and want to deploy it with Docker Compose.

TLDR: [Sensu](https://github.com/sensu/sensu) is an awesome monitoring service built in Ruby. It scales with RabbitMQ and let's an assortment of clients connect to it. Similar to Nagios, but uses Client<-->Server communication. Checks can be created in any language (similar to Nagios). 

Anyways.

Usually you have to install: __RabbitMQ, Redis, Ruby and well... Sensu__ in order to deploy Sensu. Not only that, but you also have to generate SSL certs for both RabbitMQ, the Sensu server and all your clients.

Oh, want a modern UI as well? You'll also want to install [Uchiwa](https://github.com/sensu/uchiwa)...

Before proceeding, make sure you've got __1.10__ of docker and __1.6__ of docker-compose.

```sh
git clone https://github.com/cdrage/composefiles
cd composefiles/sensu-server
./gen_ssl.sh
docker-compose up
```

Seriously, that's it. Go checkout __localhost:3000__ and you'll see your sensu server up and running.

Want to connect a sensu-client to your server? Use the SSL certificates located in __ssl/client__.

What about modify your __checks.json__ or __config.json__? Simply modify __config/sensu.json__ and __config/sensu-checks.json__ and run __docker-compose restart__ and you're done.

Each component is separated into it's own microservice using docker-compose and can be easily scaled up or down depending on your work-load. 
