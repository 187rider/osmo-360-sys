#!/bin/sh
# WIFI is base on PCIE, so when WIFI is bring up, PCIE is work good

wlan=`ifconfig -a | grep wlan0 | busybox awk '{print $1}'`
if [ "${wlan}" == "" ];then
	echo "test WiFi failed"
	echo "test PCIE failed"
	exit 1
fi
echo "test WIFI success"

# WIFI OR BT is base on PCIE, so when WIFI is bring up, PCIE is work good
echo "test PCIE success"


