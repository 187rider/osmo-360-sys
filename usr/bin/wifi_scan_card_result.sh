#!/bin/sh

card=`wl status`

if [ "$card" == "" ]; then
    echo "scan card failed"
    exit 1
else
    echo "scan card success"
    exit 0
fi
