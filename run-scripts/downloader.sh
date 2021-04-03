#!/bin/bash

# Example usage: "./downloader.sh radio_two &"

# This script initiates initiates the download of the audio stream from the BBC servers.
# It does basic error handling, if the stream returns a 404 error or ffmpeg fails,
# the script waits a few seconds and tries again.

BASE_FOLDER=

if [ "$#" -ne 1 ]; then
    echo "Illegal number of parameters"
    echo "Example usage: ./downloader.sh radio_two"
    exit
fi

BBC_STREAM=http://a.files.bbci.co.uk/media/live/manifesto/audio/simulcast/hls/nonuk/sbr_low/llnw/bbc_$1.m3u8 # Limelight Networks CDN
#BBC_STREAM=http://a.files.bbci.co.uk/media/live/manifesto/audio/simulcast/hls/nonuk/sbr_low/ak/bbc_$1.m3u8 # Akamai CDN
log="$BASE_FOLDER/logs/$1-downloader-log.txt"
playlist="$BASE_FOLDER/logs/$1-autogen-playlist.txt"

# Remove the old log file and create a new one.
rm -f $log
touch $log

# Remove the old playlist file and create a new one.
rm -f $playlist
touch $playlist

# These counters are used to generate incrementing file names. Each time a file is created,
# we increment the respective counter so we can generate a new file with a unique name.
counter=0
silencecounter=0

# Initiate the restart-service. You can read about the purpose of the restart-service in restart-service.sh.
$BASE_FOLDER/run-scripts/restart-service.sh $1 &

while true; do
	
    # The file name of the audio download from the BBC servers.
    filename="$BASE_FOLDER/audio/$1_$counter.ogg"

    # Add the audio file to the playlist, to be read by ices2
    echo $filename >> $playlist

    # Start downloading using ffmpeg
    echo "`date` Creating $filename" >> $log
    ffmpeg -y -loglevel verbose -timeout -1 -i $BBC_STREAM $filename >> $log 2>&1 
    echo "`date` Closing $filename" >> $log

    # Check if the download actually happened
    # ie, ffmpeg might have immediately failed with a 404 error (sometimes happens)
    # If it did not succeed, remove the file from the playlist
    # We check if the download was successful based off of if the file was created.
    if [ -e $filename ]; then
        # The file exists, so the download succeeded. Increment counter.
        ((counter+=1))
    else

        # FFMPEG FAILED!
        # File doesn't exist, don't increment counter. Remove the file from the playlist.
        echo "`date` Removing $filename from playlist $playlist" >> $log
        sed -i '$d' $playlist

        # Timeout for a short time before trying again
        timeoutseconds=6

        # To account for this timeout and keep the stream synchronized,
        # we generate blank audio and add it to the ices2 playlist
        silencefilename="$BASE_FOLDER/audio/$1_silent_$silencecounter.ogg"
        ((silencecounter+=1))

        echo "`date` Creating $silencefilename" >> $log
        ffmpeg -f lavfi -i anullsrc -t $timeoutseconds -c:a libvorbis $silencefilename >> $log 2>&1
        echo "`date` Adding $silencefilename to playlist $playlist" >> $log
        
        echo $silencefilename >> $playlist
        
        # Wait a few seconds before trying ffmpeg again.
        sleep $timeoutseconds
    fi

done

