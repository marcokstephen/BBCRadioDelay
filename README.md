# BBC Radio Delay

http://radioforexpats.co.uk

The goal of this project is to stream BBC radio with a time-zone delay, to give the impression of "real-time listening" (as if you were in Britain) despite actually being in Canadian time zones.

This guide will teach you how to install this project for yourself. You will require a Linux server. If you need one, you can rent one on DigitalOcean for approximately 5 USD per month. This guide assumes you are using Ubuntu.

If you already have ffmpeg, icecast2, and ices2 streams configured, you can jump to the section on "Using this project".

## Installing Prerequisites

You need `icecast2` (software for creating a radio server), `ices2` (software to make a radio stream that can be served by icecast2), and `ffmpeg` (to download BBC audio streams and process audio files).

First run the following command to update your repositories:
```
sudo apt-get update
```

Then we will install `ffmpeg`, `icecast2`, and `ices2`. If, when you are installing icecast2, a pop-up screen asks you to configure passwords, you can select no. You will do it manually later.
```
sudo apt-get install ffmpeg
sudo apt-get install icecast2
sudo apt-get install ices2
```

### Configuring icecast2
First we need to set passwords. These passwords will be used to control who can access the icecast2 admin panel, as well as who can set up streams to broadcast through your server. To do this, open the following file:
```
vi /etc/icecast2/icecast.xml
```
Find the following block of code and edit the passwords as you wish. Take note of what you are setting the `source-password` to, you will need it later. You can set the `relay-password` to the same as the `source-password`.
```
<authentication>
        <!-- Sources log in with username 'source' -->
        <source-password>abc</source-password>
        <!-- Relays log in username 'relay' -->
        <relay-password>abc</relay-password>

        <!-- Admin logs in with the username given below -->
        <admin-user>admin</admin-user>
        <admin-password>abc</admin-password>
    </authentication>
```

Also find the following block of code and edit the `clients` and `sources` figures. These two figures are the limits of how many listeners your server will allow and how many radio streams your icecast2 will accomodate. If you don't know, you can make them 100 and 20 respectively.
```
    <limits>
        <clients>100</clients>
        <sources>20</sources>
        ...
    </limits>
```

Lastly, you must open the following file and set `ENABLE=true`:
```
vi /etc/default/icecast2
```
```
ENABLE=true
```

Now you can start `icecast2` and when you open your server in a web browser at port 8000, you should see the icecast2 page.
```
/etc/init.d/icecast2 start
```
Example: http://192.168.0.1:8000 (but make sure to replace 192.168.0.1 with your server's external IP address). You should see the icecast2 page.

### Configuring ices2
You need to make a folder to hold the logs.
```
mkdir /var/log/ices
```
You are done, that was easy.

## Using this Project
~~ In progress ~~
