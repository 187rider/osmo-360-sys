#!/bin/sh
#get device id
i=0
name=cyttsp5_mt
device_num=10
while [ $i -le $device_num ]
do
	event_id=`cat /sys/class/input/event$i/device/name`
	if [[ $event_id = $name ]]; then
		break;
	fi
	let i++
done
if [[ $i -gt $device_num ]]; then
	echo "not find back touch panel device"
	exit 1
fi
tp_event=/dev/input/event$i

wait_time=20
echo "Please touch back panel in $wait_time seconds."

i=0
while [ $i -lt $wait_time ]
do
res=`timeout 1 cat $tp_event`
	if [ ! -z "$res" ]; then
		echo "Back touch function is ok."
		exit 0
	fi
	let i++
done

echo "Back touch function is invalid or not touch in $wait_time seconds, exit!"
exit 1
