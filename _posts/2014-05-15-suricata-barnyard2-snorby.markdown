---
layout: post
category: linux
title: scalable low-consumption high-performance network ids, ips and security monitoring, welcome to suricata, barnyard2 and snorby!
date: 2014-05-15 15:49
---

__2015-10-25 UPDATE:__ Snorby is no longer being updated. Also, look at [Bro](http://github.com/bro/bro) as an alternative for Suricata :). Will update with a new article in the future of how this should be done in __only__ Docker containers :)

One of the difficulties in security monitoring is the implementation of a low-resource monitoring software across a scalable network. This article will document the installation of Suricata and Barnyard on remote servers as well as Snorty on a central server / database. Without further ado, here is the overview:

[Suricata][suricata]: A smart low-CPU intensive alternative to the IDS we all know and love, Snort.  This will be collecting packtes via AF Packet located on the 'sensor' (in our case, the nodes)

[Barnyard2][barnyard2]: A dedicated spooler for Snort's (in our case, Suricata) unified2 binary data. This will also be running on the node, this will interpret the data received from Suricata and export it to our database running on our central server.

[Snorby][snorby]: A Ruby on Rails application for network security monitoring. This will prettify all the data into lovely graphs adding notations, commenting support and daily e-mail reports. It looks like this:

![Snorby](/img/snorby.png)

Nodes (sensors):
    Suricata
    Barnyard2

Server (main database):
    Snorby

Let's start with the installation of Suricata and Barnyard2!

##Suricata

On your node we will be compiling and installing Suricata with AF_Packet support.

(assuming you are installing under root)

```bash
apt-get -y install libpcre3 libpcre3-dbg libpcre3-dev build-essential autoconf automake libtool libpcap-dev libnet1-dev libyaml-0-2 libyaml-dev zlib1g zlib1g-dev libmagic-dev libcap-ng-dev pkg-config git 
wget http://www.openinfosecfoundation.org/download/suricata-2.0.tar.gz
tar xvf suricata-2.0.tar.gz
cd suricata-2.0
./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var
make
make install-full
```
make install-full: This will install all rules and configurations necessary to start suricata. Make-full will initially grab the most recent emerging list. 

Feel free to edit any rules you may like under /etc/suricata/suricata.yaml. Personally, I removed a few of the SURICATA-only ones and implemented my own.

To test that suricata is running correctly, run

```
/usr/bin/suricata -c /etc/suricata/suricata.yaml --af-packet=br0

and watch
tail -f /var/log/suricata/http.log /var/log/suricata/fast.log

to test an intrustion detection
wget www.testmyids.com

```
##Barnyard2
```bash
cd /opt/
apt-get install libpcre3 libpcre3-dbg libpcre3-dev build-essential autoconf automake libtool libpcap-dev libnet1-dev mysql-client dh-autoreconf libpcap-dev libmysqlclient15-dev
git clone https://github.com/firnsy/barnyard2
cd barnyard2
./autogen.sh
./configure --with-mysql-libraries=/usr/lib/x86_64-linux-gnu/
make
make install
```

This will install Barnyard2 into /opt/ with mysql support. 

Uncomment and edit these configuration changes under /usr/local/etc/barnyard2.conf

```bash
vim /usr/local/etc/barnyard2.conf

    # set the appropriate paths to the file(s) your Snort process is using.
    config reference_file:      /etc/suricata/reference.config
    config classification_file: /etc/suricata/classification.config
    config gen_file:            /etc/suricata/rules/gen-msg.map
    config sid_file:            /etc/suricata/rules/sid-msg.map

    # define the full waldo filepath.
    config waldo_file: /var/log/suricata/suricata.waldo
    
    # database: log to a variety of databases remember to set the pass and username same as snorby database
    # it is important that you enter the username and password correctly. For testing purposes, I used root, however, you may change the mysql username and password to whichver you'd like on the central server running Snorby.
    output database: log, mysql, user=root password=password dbname=snorby host=31.124.142.14 sensor_name=node1
```

For a final touch, we much initialize and touch a few files that Barnyard/Suricata requires

```bash
mkdir /var/log/barnyard2
touch /var/log/suricata/suricata.waldo
```

In order to run Barnyard:

```bash
/usr/local/bin/barnyard2 -c /usr/local/etc/barnyard2.conf -d /var/log/suricata/ -f unified2.alert -w /var/log/suricata/suricata.waldo
```

However, you will get an error message as we have yet to initialize the snorby database.

##Snorby

```bash
cd /opt
git clone http://github.com/Snorby/snorby.git
cd snorby
bundle install
cd config
cp database.yml.example database.yml
cp snorby_config.yml.example snorby_config.yml
vim database.yml #edit root password for mysql-server
vim snorby_config # add time_zone: 'America/Chicago' to production  I also recommend changing the default port of the server
vim initializers/mail_config.rb #edit email settings
```

Now to run another set of bundle commands!

```bash
bundle exec rake snorby:setup
bundle exec rails server -e production
```

If the installation is successful, you should now able to access the database via: ip:port and user/pass snorby@snorby.org : snorby

##Final

A few problems that I ran while installing was the mysql server. Make sure that your mysql database is publically accessible and that you can access the snorby database remotely.

If all goes well, run these commands on each sensor/node you have configured

```bash
/usr/local/bin/barnyard2 -c /usr/local/etc/barnyard2.conf -d /var/log/suricata/ -f unified2.alert -w /var/log/suricata/suricata.waldo -D
/usr/bin/suricata -c /etc/suricata/suricata.yaml --af-packet=br0 -D
```

This will start both Barnyard2 and Suricata in the background. Upon first initialization, barnyard2 will have to synchronize with Snorby. If you watch htop, you will notice that Barnyard2 will stay at 100% CPU fort a few minutes while sending information across the network between the node and server. 

After a while, you should see each sensor that you configured appear under the 'sensor' tab in Snorby. 

Again, if you want to test that the IDS is working correctly, run 'wget www.testmyids.com' on a node and an alert will be passed from Suricata to Barnyard2 to Snorby.

Now you have a high-performing, low-consumption scalable IDS network!

Feel free to ask any questions in the comments below and I will help you to the best of my ability.

[jekyll-gh]: https://github.com/mojombo/jekyll
[jekyll]:    http://jekyllrb.com

[suricata]: http://suricata-ids.org/
[barnyard2]: https://github.com/firnsy/barnyard2
[snorby]: https://snorby.org/
