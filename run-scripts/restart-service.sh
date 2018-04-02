#!/bin/bash

# Example usage: "./restart-service.sh radio2"

# I have found that sometimes, (very rarely), ffmpeg randomly hangs. It stops downloading,
# but ffmpeg never crashes so essentially everything comes to a pause. Since ffmpeg
# didn't crash, the downloader cannot know to restart it.

# That is where this script comes in. This script looks had the audio files in the
# audio folder, and makes sure that the most recent file was modified at some point in the last
# sixty seconds. if it was not, we conclude that ffmpeg must have been hanging. So we kill ffmpeg
# so that the downloader.sh can automatically restart it.

# To keep the streams in sync, when a hang is discovered, we generate a blank audio file with the same
# length as the hanging time, and we add it to the ices2 playlist.

BASE_FOLDER=

filenames="$BASE_FOLDER/audio/$1_*.ogg"

log="$BASE_FOLDER/logs/$1-downloader-log.txt"
playlist="$BASE_FOLDER/logs/$1-autogen-playlist.txt"

hangingcounter=0

while true; do

    # Wait 60 seconds
    sleep 60

    # Get the most recent file
    newest=`ls -t $filenames | head -1`

    # Get the last-modified time of the most recent file and subtract the current time
    lastmodified=$(($(date +%s) - $(date +%s -r $newest)))

    # Check if the difference is greater than 60
    if [ $lastmodified -gt 60 ]; then

        # Uh oh, the difference is greater than 60. Ffmpeg must be hanging.
        echo "Last modified is older than 60: $newest, $lastmodified" >> $log

        # Generate a blank audio file with the same time length as the hang duration
        hangingfilename="$BASE_FOLDER/audio/$1_hanging_$hangingcounter.ogg"
        echo "`date` Creating $hangingfilename" >> $log
        ffmpeg -f lavfi -i anullsrc -t $lastmodified -c:a libvorbis $hangingfilename >> $log 2>&1
        echo "`date` Adding $hangingfilename to playlist $playlist" >> $log

        # Add the blank audio file to the ices2 playlist
        echo $hangingfilename >> $playlist

        # Kill ffmpeg so that the downloader.sh will automatically restart it.
        ps axf | grep ffmpeg | grep $1 | awk '{print "kill -9 " $1}' | sh
    else

        # No unusual errors were detected :)
        echo "$newest last modified was $lastmodified" >> $log
    fi

done
