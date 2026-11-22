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

echo "PulseAudio is ready. Starting to test mainmic..."

####################3. check the audio main mic###################################
parecord --fix-rate --fix-format --fix-channels --no-remix --no-remap --rate=48000 --channels=4 --format=s24-32le --capture-time=1 /blackbox/capture.wav

result=`pacheck /blackbox/capture.wav -i wav -cd 1`

if [ $? -ne 0 ]; then
    echo $result
    echo "test audio main mic 1 failed"
    exit 1
else
    echo "test audio main mic 1 success"
fi

result=`pacheck /blackbox/capture.wav -i wav -cd 2`

if [ $? -ne 0 ]; then
    echo $result
    echo "test audio main mic 2 failed"
    exit 1
else
    echo "test audio main mic 2 success"
fi

result=`pacheck /blackbox/capture.wav -i wav -cd 3`

if [ $? -ne 0 ]; then
    echo $result
    echo "test audio main mic 3 failed"
    exit 1
else
    echo "test audio main mic 3 success"
fi

result=`pacheck /blackbox/capture.wav -i wav -cd 4`

if [ $? -ne 0 ]; then
    echo $result
    echo "test audio main mic 4 failed"
    exit 1
else
    echo "test audio main mic 4 success"
    exit 0
fi