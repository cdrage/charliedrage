---
layout: post
category: raspberry pi
title: tracking airplanes
date: 2014-08-18
---

![Cluster](/img/cluster.jpg)

The Raspberry Pi can do amazing things. From a personal computer/cloud [Cluster](http://likemagicappears.com/projects/raspberry-pi-cluster/) to sending a [potato](http://www.daveakerman.com/) to space. 

In this blog post, I will show you how I setup my Raspberry Pi to communicate to airplanes using _ADS-B_ (Automatic dependent surveillance-broadcast).

In a nutshell, ADS-B is a cooperative surveillance technology where aircrafts broadcast their position and other flight information which can be received by air traffic control as a replacement for secondary radar. It requires no input from the pilot and is automatically transmitted during flight.

Many airplanes are already equipped with ADS-B and is an element of the _US Next Generation Air Transportation System (NextGen)_ and the _Single European Sky ATM Research (SEDAR)_. By 2017 it will be mandatory on all major aircraft in Europe and 2020 in the United States.

## Installation

You will need two things, a [Raspberry Pi](http://www.raspberrypi.org/) and a [DVB-T Digital TV Receiver with the Realtek Chip](http://www.dx.com/p/dvb-t-digital-tv-receiver-usb-dongle-w-fm-remote-control-antenna-black-149928). 

First, install Raspbian onto your Raspberry Pi.

In order to enable the connection between the the _tuner_ and the _Pi)_ you will need to compile a driver as well as an output dump.

The quick-and-easy way to install (we will go over the individual commands later):

```bash
#DO NOT plug in your USB dongle before excuting. Simply copy and paste these commands into your root directory and plug in your dongle after reboot. Your web-server will be located at {ip}:8080
 sudo apt-get -y update
 sudo apt-get -y upgrade

 sudo apt-get -y install git-core
 sudo apt-get -y install git
 sudo apt-get -y install cmake
 sudo apt-get -y install libusb-1.0-0-dev
 sudo apt-get -y install build-essential

 git clone git://git.osmocom.org/rtl-sdr.git
 cd rtl-sdr
 mkdir build
 cd build
 cmake ../ -DINSTALL_UDEV_RULES=ON
 make
 sudo make install
 sudo ldconfig
 cd ~
 sudo cp ./rtl-sdr/rtl-sdr.rules /etc/udev/rules.d/

 git clone git://github.com/MalcolmRobb/dump1090.git
 cd dump1090
 make
 cd ~
 sudo cp ./dump1090/dump1090.sh /etc/init.d/dump1090.sh
 sudo chmod +x /etc/init.d/dump1090.sh
 sudo update-rc.d dump1090.sh defaults

 printf 'blacklist dvb_usb_rtl28xxu\nblacklist rtl2832\nblacklist rtl2830\n' > nortl.conf
 
 sudo cp ./nortl.conf /etc/modprobe.d/notrl.conf

 sudo reboot
```

##Detailed explanation

```bash

 sudo apt-get -y update
 sudo apt-get -y upgrade

 sudo apt-get -y install git-core
 sudo apt-get -y install git
 sudo apt-get -y install cmake
 sudo apt-get -y install libusb-1.0-0-dev
 sudo apt-get -y install build-essential
```
Updating and installing required software.

```bash
git clone git://git.osmocom.org/rtl-sdr.git
 cd rtl-sdr
 mkdir build
 cd build
 cmake ../ -DINSTALL_UDEV_RULES=ON
 make
 sudo make install
 sudo ldconfig
 cd ~
 sudo cp ./rtl-sdr/rtl-sdr.rules /etc/udev/rules.d/
```
Installing the rtl-sdr driver in order for the Raspberry Pi to communicate to the dongle. 

```bash
 git clone git://github.com/MalcolmRobb/dump1090.git
 cd dump1090
 make
```
The important part dump1090 captures all the data that is outputted by the dongle and parses it so it is communicatable to us. After you make dump1090 and rebooted your Pi you can now run and interact with the received data.

```bash
printf 'blacklist dvb_usb_rtl28xxu\nblacklist rtl2832\nblacklist rtl2830\n' > nortl.conf
 
 sudo cp ./nortl.conf /etc/modprobe.d/notrl.conf
```
This blacklists the driver in modprobe.d. This is required in order to use the dongle.

```bash
./dump1090 --help #for help command
./dump1090 --interactive #view all data coming in, in a arcade-like console
./dump1090 --interactive --net #view data & create a web server @ {ip}:8080
```
And that's it. That's all you need to do. If you want to start dump1090 automatically in networked mode (the interactive web page), run this:

```bash
 sudo cp ./dump1090/dump1090.sh /etc/init.d/dump1090.sh
 sudo chmod +x /etc/init.d/dump1090.sh
 sudo update-rc.d dump1090.sh defaults
```
##The final outcome
![Airplane](/img/piairplane.png)
