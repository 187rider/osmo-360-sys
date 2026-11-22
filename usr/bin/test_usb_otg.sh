#!/bin/sh

echo none > /sys/devices/platform/soc/a600000.ssusb/mode

sleep 3

echo peripheral > /sys/devices/platform/soc/a600000.ssusb/mode

sleep 5

state=`cat /sys/class/udc/a600000.dwc3/state`

if [ "$state" == "configured" ]; then
	echo "test usb OTG success"
else
	echo "test usb OTG failed"
fi


