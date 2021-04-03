#!/bin/bash

# usage: ./start_radio.sh {stream name} {variable stream name} {genre}
# Example usage: ./start_radio.sh "BBC Radio 1" radio_one "Pop"

BASE_FOLDER=

SERVER_ADDRESS="localhost"
SERVER_PORT="8000"
SERVER_PASSWORD="abc"

if [ "$#" -ne 3 ]; then
    echo "Illegal number of parameters"
    echo "usage: ./start_radio.sh {stream name} {variable stream name} {genre}"
    exit
fi

logfile="$BASE_FOLDER/logs/$2-running-log.txt"
rm -f $logfile

rm -f "$BASE_FOLDER/ices-xml/gen-$2-"*.xml

generate_xml () {

    streamname=$1
    name=$2
    genre=$3
    delay=$4

    filename="$BASE_FOLDER/ices-xml/gen-$name-$delay.xml"
    echo "Creating $filename" >> $logfile

    echo "<?xml version=\"1.0\"?>" >> $filename
    echo "<ices>" >> $filename
    echo "    <!-- run in background -->" >> $filename
    echo "    <background>1</background>" >> $filename
    echo "    <!-- where logs, etc go. -->" >> $filename
    echo "    <logpath>/var/log/ices</logpath>" >> $filename
    echo "    <logfile>ices.log</logfile>" >> $filename
    echo "    <!-- 1=error,2=warn,3=info,4=debug -->" >> $filename
    echo "    <loglevel>4</loglevel>" >> $filename
    echo "    <!-- set this to 1 to log to the console instead of to the file above -->" >> $filename
    echo "    <consolelog>0</consolelog>" >> $filename
    echo "    <!-- optional filename to write process id to -->" >> $filename
    echo "    <!-- <pidfile>/home/ices/ices.pid</pidfile> -->" >> $filename
    echo "    <stream>" >> $filename
    echo "        <!-- metadata used for stream listing (not currently used) -->" >> $filename
    echo "        <metadata>" >> $filename
    echo "            <name>$streamname ($delay Hour Delay)</name>" >> $filename
    echo "            <genre>$genre</genre>" >> $filename
    echo "            <description>$streamname with a $delay hour delay</description>" >> $filename
    echo "        </metadata>" >> $filename
    echo "        <!-- input module" >> $filename
    echo "            The module used here is the playlist module - it has " >> $filename
    echo "            'submodules' for different types of playlist. There are" >> $filename
    echo "            two currently implemented, 'basic', which is a simple" >> $filename
    echo "            file-based playlist, and 'script' which invokes a command" >> $filename
    echo "            to returns a filename to start playing. -->" >> $filename
    echo "        <input>" >> $filename
    echo "            <module>playlist</module>" >> $filename
    echo "            <param name=\"type\">basic</param>" >> $filename
    echo "            <param name=\"file\">$BASE_FOLDER/logs/$name-autogen-playlist.txt</param>" >> $filename
    echo "            <!-- random play -->" >> $filename
    echo "            <param name=\"random\">0</param>" >> $filename
    echo "            <!-- if the playlist get updated that start at the beginning -->" >> $filename
    echo "            <param name=\"restart-after-reread\">0</param>" >> $filename
    echo "            <!-- if set to 1 , plays once through, then exits. -->" >> $filename
    echo "            <param name=\"once\">1</param>" >> $filename
    echo "        </input>" >> $filename
    echo "        <!-- Stream instance" >> $filename
    echo "            You may have one or more instances here. This allows you to " >> $filename
    echo "            send the same input data to one or more servers (or to different" >> $filename
    echo "            mountpoints on the same server). Each of them can have different" >> $filename
    echo "            parameters. This is primarily useful for a) relaying to multiple" >> $filename
    echo "            independent servers, and b) encoding/reencoding to multiple" >> $filename
    echo "            bitrates." >> $filename
    echo "            If one instance fails (for example, the associated server goes" >> $filename
    echo "            down, etc), the others will continue to function correctly." >> $filename
    echo "            This example defines two instances as two mountpoints on the" >> $filename
    echo "            same server.  -->" >> $filename
    echo "        <instance>" >> $filename
    echo "            <!-- Server details:" >> $filename
    echo "                You define hostname and port for the server here, along with" >> $filename
    echo "                the source password and mountpoint.  -->" >> $filename
    echo "            <hostname>$SERVER_ADDRESS</hostname>" >> $filename
    echo "            <port>$SERVER_PORT</port>" >> $filename
    echo "        <password>$SERVER_PASSWORD</password>" >> $filename
    echo "            <mount>/$name/$delay</mount>" >> $filename
    echo "            <!-- Reconnect parameters:" >> $filename
    echo "                When something goes wrong (e.g. the server crashes, or the" >> $filename
    echo "                network drops) and ices disconnects from the server, these" >> $filename
    echo "                control how often it tries to reconnect, and how many times" >> $filename
    echo "                it tries to reconnect. Delay is in seconds." >> $filename
    echo "                If you set reconnectattempts to -1, it will continue " >> $filename
    echo "                indefinitely. Suggest setting reconnectdelay to a large value" >> $filename
    echo "                if you do this." >> $filename
    echo "            -->" >> $filename
    echo "            <reconnectdelay>2</reconnectdelay>" >> $filename
    echo "            <reconnectattempts>5</reconnectattempts> " >> $filename
    echo "            <!-- maxqueuelength:" >> $filename
    echo "                This describes how long the internal data queues may be. This" >> $filename
    echo "                basically lets you control how much data gets buffered before" >> $filename
    echo "                ices decides it can't send to the server fast enough, and " >> $filename
    echo "                either shuts down or flushes the queue (dropping the data)" >> $filename
    echo "                and continues. " >> $filename
    echo "                For advanced users only." >> $filename
    echo "            -->" >> $filename
    echo "            <maxqueuelength>80</maxqueuelength>" >> $filename
    echo "            <!-- Live encoding/reencoding:" >> $filename
    echo "                Currrently, the parameters given here for encoding MUST" >> $filename
    echo "                match the input data for channels and sample rate. That " >> $filename
    echo "                restriction will be relaxed in the future." >> $filename
    echo "                Remove this section if you don't want your files getting reencoded." >> $filename
    echo "            -->" >> $filename
    echo "            <encode>  " >> $filename
    echo "                <nominal-bitrate>128000</nominal-bitrate> <!-- bps. e.g. 64000 for 64 kbps -->" >> $filename
    echo "                <samplerate>44100</samplerate>" >> $filename
    echo "                <channels>2</channels>" >> $filename
    echo "            </encode>" >> $filename
    echo "        </instance>" >> $filename
    echo "    </stream>" >> $filename
    echo "</ices>" >> $filename

}

# Calling this will make ices2 initiate after sleeping for a specified delay. This sleeping delay is what
# gives the impression of the time-zone delays.
startstream () {
    # $1: stream variable name (ie. 'radio_two')
    # $2: hours of delay

    delay=$2
    ((delay*=60)) #convert delay to minutes
    ((delay*=60)) #convert delay to seconds

    echo "sleep $delay && echo \"Starting $1-$2\" && ices2 \"$BASE_FOLDER/ices-xml/gen-$1-$2.xml\" &" >> $logfile
    (sleep $delay && echo "`date` Starting $1-$2" >> $logfile && ices2 "$BASE_FOLDER/ices-xml/gen-$1-$2.xml") &
}

startnewfiestream () {
    #usage: $1: stream variable name (ie. 'radio_two')

    # 3.5 * 60 * 60
    delay=12600
    
    echo "sleep $delay && echo \"Starting $1-3-5\" && ices2 \"$BASE_FOLDER/ices-xml/gen-$1-3-5.xml\" &" >> $logfile
    (sleep $delay && echo "`date` Starting $1-3-5" >> $logfile && ices2 "$BASE_FOLDER/ices-xml/gen-$1-3-5.xml") &
}

echo "Starting $1 delayed stream" >> $logfile

# Generate the xml files that will be read by ices2.
generate_xml "$1" $2 "$3" "3-5" #newfoundland
generate_xml "$1" $2 "$3" 4 #atlantic
generate_xml "$1" $2 "$3" 5 #eastern
generate_xml "$1" $2 "$3" 6 #mountain
generate_xml "$1" $2 "$3" 7 #central
generate_xml "$1" $2 "$3" 8 #pacific

# Start the downloader
$BASE_FOLDER/run-scripts/downloader.sh $2 &

# Start the delayed streams
startnewfiestream $2 #newfoundland
startstream $2 4 #atlantic
startstream $2 5 #eastern
startstream $2 6 #mountain
startstream $2 7 #central
startstream $2 8 #pacific

echo "Finished initiation of $1" >> $logfile

# To save on CPU usage, you can omit specific timezones. Comment out the associated generate_xml and the startstream above.
