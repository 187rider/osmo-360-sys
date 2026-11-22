#!/bin/sh

# do not set / (root_file) to rw, that make diff-upgrade failed
# mount -o rw,remount /

while true
do
    busybox date > /dev/kmsg
    sleep 30
    echo $(date "+%H:%M:%S.%N") > /dev/kmsg
    cat sys/class/remoteproc/remoteproc*/name > /dev/kmsg
    cat sys/class/remoteproc/remoteproc*/state > /dev/kmsg
done
