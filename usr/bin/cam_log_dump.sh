#!/bin/sh

cam_log_path="/blackbox/camera/log"

if [ -e $cam_log_path ]; then
    echo "$cam_log_path already exists" > /dev/kmsg
else
    echo "cam log path no need to soft link, use directly: $cam_log_path" > /dev/kmsg
    mkdir -p $cam_log_path
fi

logcat -f $cam_log_path"/cam.log" -v threadtime -r131072 -n3 DUSS4A:S DUSS44:S DUSS41:S DUSS43:S DUSS4D:S DUSS52:S DUSS70:S *:I
