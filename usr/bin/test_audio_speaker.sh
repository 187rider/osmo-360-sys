#!/bin/sh

# check whether pulseaudio is ready
MAX_RETRY_TIMES=50
sleep_duration=0.1

retry_times=1

while ! pactl info &> /dev/null; do
    if [ $retry_times -ge $MAX_RETRY_TIMES ]; then
        echo "PulseAudio is not ready after $MAX_RETRY_TIMES retry. Exiting."
        exit 1
    fi

    sleep $sleep_duration
    let retry_times=$retry_times+1
done

echo "PulseAudio is ready. Starting to test builtin speaker..."
####################3. check the audio main mic###################################

# default 44100 2ch s16le
parecord --capture-time=1 /blackbox/capture.wav
result=`paplay --playback-time=1 /blackbox/capture.wav`

if [ $? -ne 0 ]; then
    echo $result
    echo "test audio speaker failed"
    exit 1
else
    echo "test audio speaker success"
    exit 0
fi
