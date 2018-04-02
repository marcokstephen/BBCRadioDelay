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

### Configuring the scripts
First, clone this repository.
```
git clone https://github.com/marcokstephen/BBCRadioDelay.git
cd BBCRadioDelay
```
Take note of what your full directory path is. You will need to modify the scripts to use this directory path. To get your current directory, run
```
pwd
```
For example, it might show your current directory is `/root/BBCRadioDelay`. Copy this, and modify the following six files to set the `BASE_DIRECTORY` variable:
* `cron-scripts/kill-ffmpeg`
* `cron-scripts/purge-ogg`
* `cron-scripts/resync`
* `run-scripts/downloader.sh`
* `run-scripts/restart-service.sh`
* `run-scripts/start_radio.sh`
```
BASE_DIRECTORY=/root/BBCRadioDelay
```
(make sure to set the variable according to what YOUR base directory is!)

Next, you will need to open `run-scripts/start_radio.sh`.
```
vi run-scripts/start_radio.sh
```
Find the `SERVER_PASSWORD` and set it to what you made the `source-password` when configuring icecast2.
```
SERVER_ADDRESS="localhost"
SERVER_PORT="8000"
SERVER_PASSWORD="abc"
```

### Starting the streams

You are now ready to start the streams. To do this, we use the `start_radio.sh` script.
```
run-scripts/start_radio.sh {stream name} {stream code} {stream genre}
```
Examples:
```
run-scripts/start_radio.sh "BBC Radio 1" radio1 "Pop"
run-scripts/start_radio.sh "BBC Radio 2" radio2 "Adult Contemporary"
run-scritps/start_radio.sh "BBC Radio 4" radio4fm "Talk"
run-scritps/start_radio.sh "BBC Radio 5" radio5live "Talk"
run-scripts/start_radio.sh "BBC Radio 6" radio6music "Music"
```
You can verify that things started properly by going to the `audio` folder and seeing that a file is downloading. The download log should also be saved to the `logs` folder. The radio stream itself won't have started yet, because it is going to delay at least 3.5 hours (that is the time difference to the first time zone -- Newfoundland). For debugging purposes, you can play around with different delays in `start_radio.sh` to make the streams start earlier.

Once the streams start, you can view them at http://192.168.0.1:8000, (remembering to use your own IP address) and you can listen by appending your mount point name. Examples:
```
http://192.168.0.1:8000/radio1/3-5
http://192.168.0.1:8000/radio2/4
http://192.168.0.1:8000/radio4fm/5
http://192.168.0.1:8000/radio5live/6
http://192.168.0.1:8000/radio5music/7
```

### Setting up the cron jobs

The stream should be working properly at this point but there is still some maintenance to do. There are three cron scripts that need to run. `kill-ffmpeg` and `purge-ogg` should run daily. `resync` should run once a week. You can open the files themselves to see a description of what it is that they do. To make these run, add them to your `crontab`.

```
crontab -e
```
The following will make `kill-ffmpeg` and `purge-ogg` run every day at 05:00, and `resync` will run every Sunday at 05:00. Again, make sure to replace the path to the files with whatever your file path is.
```
0 5 * * * /root/BBCRadioDelay/cron-scripts/kill-ffmpeg
0 5 * * * /root/BBCRadioDelay/cron-scripts/purge-ogg
0 5 * * sun /root/BBCRadioDelay/cron-scripts/resync
```

# Questions?
You can open an issue on this repository or send an email to marcok<dot>stephen<at>gmail<dot>com
