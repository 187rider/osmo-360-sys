#!/bin/sh
# check supper charging
echo $1
if [ $1 = "soc" ];then
        path="/sys/class/power_supply/battery/capacity"
elif [ $1 = "vbus" ];then
        path="/sys/class/power_supply/usb/voltage_now"
elif [ $1 = "ibus" ];then
        path="/sys/class/power_supply/usb/current_now"
elif [ $1 = "vbat" ];then
        path="/sys/class/power_supply/battery/voltage_now"
elif [ $1 = "ibat" ];then
        path="/sys/class/power_supply/battery/current_now"
elif [ $1 = "temp" ];then
        path="/sys/class/power_supply/battery/temp"
else
    echo "param error,test failed"
    exit 1
fi

val=`cat $path`
if [ $? != 0 ]; then
    echo "get $1 failed"
    exit 1
fi

if [[ $1 = "soc" && $val -gt 100 ]]; then
    echo "soc data failed: $val"
    exit 1
fi

echo "$1 : $val"
