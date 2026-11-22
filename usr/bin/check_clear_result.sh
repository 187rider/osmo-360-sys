#!/bin/sh

# do not set / (root_file) to rw, that make diff-upgrade failed 
# mount -o rw,remount /

clr_log_file=/blackbox/system/clear_factory_log.txt

if [ ! -f ${clr_log_file} ]; then
    echo "${clr_log_file} does not exist, FAILED"
    exit 1
else
    cat ${clr_log_file}
    cat ${clr_log_file} | grep _success_
    if [ $? -ne 0 ]; then
        echo "Data clear FAILED"
        exit 2
    else
        echo "Data clear OK"
    fi
fi