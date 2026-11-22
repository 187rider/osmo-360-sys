#! /bin/bash

# Function: OQ101 factory function enable/disable
#
# create data: 2022-12-01
#      update: 2022-11-30  add calibraion status command check
#
# Discription:
# This script is used to enalbe some factory test: 1.cs log print  2.sensor temp print  3.enable dump braw

func_enable_factory() {

    systemctl stop dji_camera3
    sleep 1
    systemctl stop qmmf-server
    sleep 1

    cp -v /system/etc/factorytest.txt /data/camera/camxoverridesettings.txt
    sync

    systemctl restart qmmf-server
    sleep 1
    systemctl restart dji_camera3
    sleep 5

    echo "enable factory test success!"
}

func_disable_factory() {
    systemctl stop dji_camera3
    sleep 1
    systemctl stop qmmf-server
    sleep 1

    rm /data/camera/camxoverridesettings.txt
    sync

    systemctl restart qmmf-server
    sleep 1
    systemctl restart dji_camera3
    sleep 5

    echo "disable factory test success!"
}

func_usage() {
    echo "----- OQ101 factory function enable/disable script -----"
    echo "<1> input param 1: choose function:"
    echo "    enable        : enable all factory function"
    echo "    disable       : disable all factory function"
}

if [ ! -n "$1" ];then
    echo "no input param, please check!!!"
    func_usage
    exit 1
elif [ $1 == "enable" ];then
    func_enable_factory
elif [ $1 == "disable" ];then
    func_disable_factory
else
    echo "unsupported input param: $1, please check!!!"
    exit 1
fi

exit 0