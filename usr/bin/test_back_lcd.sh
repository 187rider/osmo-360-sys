#!/bin/sh
val1=`cat /sys/kernel/debug/dri/0/encoder*/status | grep command`
sleep 2
val2=`cat /sys/kernel/debug/dri/0/encoder*/status | grep command`
if [[ $val1 = $val2 ]]; then
	echo "Back panel not start, exit!"
	exit 1
else
	echo "Back panel is ok."
fi
exit 0
