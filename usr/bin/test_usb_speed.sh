#!/bin/sh
echo "=================start usb speed test==============="

link_status=$(cat /sys/class/android_usb/android0/state)
if [ "$link_status" == "CONFIGURED" ];then
	echo "link_status is CONFIGURED"
else
	echo "link_status is $link_status"
	exit 1
fi

link_speed=$(cat /sys/kernel/config/usb_gadget/g1/bcdUSB)

if [ "$link_speed" == "0x0320" ];then
	echo "link_speed is super speed"
	exit 0
elif [ "$link_speed" == "0x0210" ];then
	echo "link_speed is fast speed"
	exit 0
else
	echo "error: link_speed is $link_speed"
	exit 1
fi
