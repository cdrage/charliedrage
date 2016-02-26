---
layout: post
category:  docker + monitoring
title:  fast scaleable monitoring solution (sensu) with notifications (slack, email) and metrics (graphite)
date: 2015-03-24 01:02:03
---

Installing services, reading documentation, deploying on a compatible OS. It's a bitch. That's why Docker has gained such popularity within the past couple of years. What started as a simple LXC project erupted into an assortment of different forks and implementations. Want a Platform as a Service that deploys web servers programatically in less than 1,000 lines of code? Use Docker and Go. Why am I saying this? It's because all it takes is a few lines of text and a download of a repo and your service is up and running, on any OS, on multiple cloud providers. 

# Sensu

![Sensu](/img/sensu.png)

Sensu is a monitoring platform that uses Ruby, RabbitMQ (Erlang) and Redis. It's similar to Nagios, but uses a Client<->Server communication that reports back to one another. Clients can be added very easily as well as removed from the chain, checks can be created in any language, and it's very volatile. It's an amazing platform and with RabbitMQ it scales quite well. In order to use a Sensu Server you'll have to install Redis, configure RabbitMQ, setup the actual Sensu Server and (optionally) add your mail and chatops handlers/notifications.  But we're going to avoid all the nitty gritty and use a Docker container.

Usually in a monitoring platform you want:

  - Checks (HDD, RAM, CPU%, etc).
  - Notifications (Slack, Email, Hipchat, Campfire, etc)
  - Metrics (Graphite, graphs, woo!)

With a few modifications of some JSON files, we'll have the server up and running immediately. 

In order to ease this transition into building a Dockerfile container, we'll run through this step-by-step. 

# Docker

The Docker repo is located here [github.com/charliedrage/docker-sensu-server][docker-sensu-server].

We'll be going over the Dockerfile and /files folder.

## dockerfile
```bash
FROM centos:centos6

MAINTAINER Charlie Drage <charlie@charliedrage.com>

# Basic packages
RUN rpm -Uvh http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm
RUN yum install -y passwd sudo git wget openssl openssh openssh-server openssh-clients which tar

# Create the sensu user
RUN useradd sensu
RUN echo "sensu" | passwd sensu --stdin
RUN sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config
RUN sed -ri 's/#UsePAM no/UsePAM no/g' /etc/ssh/sshd_config
RUN echo "sensu ALL=(ALL) ALL" >> /etc/sudoers.d/sensu

# Install ruby
RUN gpg --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3
RUN /bin/bash -l -c "curl -L get.rvm.io | bash -s stable"
RUN /bin/bash -l -c "rvm install 2.1"
RUN /bin/bash -l -c "echo 'gem: --no-ri --no-rdoc' > ~/.gemrc"
RUN /bin/bash -l -c "gem install bundler --no-ri --no-rdoc"

# Redis
RUN yum install -y redis

# SSL key generation
RUN git clone git://github.com/joemiller/joemiller.me-intro-to-sensu.git
RUN cd joemiller.me-intro-to-sensu/; ./ssl_certs.sh clean && ./ssl_certs.sh generate

# RabbitMQ
RUN yum install -y erlang
RUN rpm --import http://www.rabbitmq.com/rabbitmq-signing-key-public.asc
RUN rpm -Uvh http://www.rabbitmq.com/releases/rabbitmq-server/v3.1.4/rabbitmq-server-3.1.4-1.noarch.rpm
RUN mkdir /etc/rabbitmq/ssl
RUN cp /joemiller.me-intro-to-sensu/server_cert.pem /etc/rabbitmq/ssl/cert.pem
RUN cp /joemiller.me-intro-to-sensu/server_key.pem /etc/rabbitmq/ssl/key.pem
RUN cp /joemiller.me-intro-to-sensu/testca/cacert.pem /etc/rabbitmq/ssl/
ADD ./files/rabbitmq.config /etc/rabbitmq/
RUN rabbitmq-plugins enable rabbitmq_management

# Sensu server
ADD ./files/sensu.repo /etc/yum.repos.d/
RUN yum install -y sensu
ADD ./files/config.json /etc/sensu/
ADD ./files/checks.json /etc/sensu/conf.d/
RUN mkdir -p /etc/sensu/handlers
ADD ./files/handlers /etc/sensu/handlers/
RUN mkdir -p /etc/sensu/ssl
RUN cp /joemiller.me-intro-to-sensu/client_cert.pem /etc/sensu/ssl/cert.pem
RUN cp /joemiller.me-intro-to-sensu/client_key.pem /etc/sensu/ssl/key.pem

# Sensu dependancies / plugins
RUN /bin/bash -l -c "/opt/sensu/embedded/bin/gem install sensu-plugin pony"

# Uchiwa sensu control panel
RUN yum install -y uchiwa
ADD ./files/uchiwa.json /etc/sensu/

# Supervisord
RUN wget http://peak.telecommunity.com/dist/ez_setup.py;python ez_setup.py
RUN easy_install supervisor
ADD files/supervisord.conf /etc/supervisord.conf

# Flap SSH to enable connectivity
RUN /etc/init.d/sshd start
RUN /etc/init.d/sshd stop

# Sensu, uchiwa, RabbitMQ ports + 80/8080/443 for mail/slacker communication
EXPOSE 22 587 3000 4567 5671 15672 2003 80 8080 443

CMD ["/usr/bin/supervisord"]
```

That's the entirety of the Dockerfile. All other configuration files are located within /files. If you know a bit of Docker the file is self-explanitory. Although a bit against Docker standards, we containerize an SSH instance so we may connect to the container via:

```bash
ssh sensu@localhost -p 10022
password: sensu
```

This allows the ability to SSH into the container and view not only the logs of /var/log/sensu but whether or not the sensu-server and sensu-api are up or not. 

What we will be focusing on in this post is the contents of the /files/ folder

## files/config.json

This is your bread-and-butter. Any notitifcations you wish to send from the result of your Sensu checking your clients will be sent using these credentials.

```json
  "ponymailer": {
    "authenticate":true,
    "username":"example@gmail.com",
    "tls":true,
    "port":"587",
    "fromname":"Network",
    "hostname":"smtp.gmail.com",
    "password":"password",
    "from":"network@gmail.com",
    "recipients":[ 
      "admin@gmail.com"
      ]
  },
```
Edit the "ponymailer" settings to your SMTP credentials. In our usage case we used GMail. Keep in mind that GMail limits emails sent to 500 messages / day.

```json
  "slack": {
    "token": "mykey",
    "team_name": "myteam",
    "channel": "#general",
    "bot_name": "sensu",
    "message_prefix": "@channel"
  },
```

In our case, we use Slack for our ChatOps. We like to have any notifications  sent to both our NOC email and Slack channel. Enter your token key as well as your username and what channel you'd like to send notifications to.

```json
  "handlers": {
    "default": {
      "type": "set",
      "handlers": ["mailer", "slack"]
    },
    "mailer": {
      "type": "pipe",
      "command": "/opt/sensu/embedded/bin/ruby /etc/sensu/handlers/ponymailer.rb"
    },
    "slack": {
      "type": "pipe",
      "command": "/opt/sensu/embedded/bin/ruby /etc/sensu/handlers/slack.rb"
    },
    "graphite": {
      "type": "pipe",
      "command": "/opt/sensu/embedded/bin/ruby /etc/sensu/handlers/graphite-tcp.rb"
    }
  }
```

We configured our default handler to send notifications to both Email and ChatOps. This can be easily modified to add other services such as HipChat and PagerDuty.

```json
  "graphite": {
    "server":"graphite.domain.com",
    "port":"2003"
  },
```

We use Graphite for our metric collection system. It's light-weight, processes metrics quickly, and it's scalable. We use another Docker container [github.com/charliedrage/docker-graphite][graphite] to view and store our data.


## files/checks.json

This is our Sensu json file for our checks. This is where you will add checks that will be execute on each client.

```json
{
  "checks": {
    "cpu_check": {
      "handlers": ["default"],
      "command": "/etc/sensu/plugins/check-cpu.rb -w 90",
      "interval": 120,
      "subscribers": [ "node", "self", "backup"]
    },
    "eth_metrics": {
      "type": "metric",
      "handlers": ["graphite"], 
      "command": "/etc/sensu/plugins/metrics-net.rb --scheme :::name:::.net",
      "interval": 5,
      "subscribers": [ "node","backup" ]
    }
  }
}

```

In this case we are collecting metrics on our network interface and issuing a check on our CPU. This can be easily expanded. For our servers, we have over 20 checks and 10 different metric collection methods. As long as you have the file listed in the etc/sensu/plugins folder of your sensu-client (the server you're checking), it'll be executed and the results passed to the Sensu server (and if it's a metric, to your graphite server).

## files/handlers folder

Within the /files/handlers folder are three different .rb files, [slacker, graphite-tcp, pony]. Each handler takes the configuration settings from the config.json folder (in our case, where we specified our mail credentials, slack key and graphite location). And uses them to send whatever information has been piped in to the designated location. If you wish to add an alternative ChatOps service or perhaps PagerDuty, a plugin can be easily added to the files/handlers/ folder and the configuration settings within config.json.

# Building and deploying the Sensu Server

  - RabbitMQ Server: localhost:5671
  - RabbitMQ Management: localhost:15672
  - Uchiwa (Sensu control panel): localhost:3000
  - SSH sensu@localhost:10022

```bash
git clone charliedrage/docker-sensu-server
cd docker-sensu-server

# Edit the files before building! /files/
docker build -t sensu/sensu .

# Run
docker run -d -name sensu -p 10022:22 -p 3000:3000 -p 4567:4567 -p 5671:5671 -p 15672:15672 sensu/sensu

# To SSH into your sensu container (password: sensu)
ssh sensu@localhost -p 10022
```

# Deploying the graphite server

No configuration is needed for the Graphite server. However. By default. It will log metrics that span every 60 seconds for a period of 90 days. This can be edited in the storage-schemas.conf file. 

```bash
# Build your own
git clone github.com/charliedrage/docker-graphite
docker build -t graphite/graphite .
docker run -d --name graphite -p 80:80 -p 2003:2003 -p 8125:8125/udp graphite/graphite

# Run straight from the hub
docker run -d --name graphite -p 80:80 -p 2003:2003 -p 8125:8125/udp charliedrage/graphite
```

# Conclusion

After installation and deployment of both sensu and graphite, you should see clients propagate within localhost:3000 under uchiwa and metrics appear within graphite localhost:80

[docker-sensu-server]: https://github.com/charliedrage/docker-sensu-server
[docker-graphite-server]: https://github.com/charliedrage/docker-graphite
