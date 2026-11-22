#! /bin/bash

# OQ101 get sensor temperature script
# updated data: 2023-11-09
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

func_enable_factory

result=`logcat -c && logcat | grep -m 1 "PublishSensorTemperature()"`
if [ $? != 0 ];then
    echo "logcat temp failed!"
fi
res=`echo $result | grep -o "Temperature(C): [0-9]\{1,6\}"`
temp=`echo $res | grep -o "[0-9]\{1,6\}"`
if [ $? -ne 0 ];then
    echo "get temp failed!"
    func_disable_factory
    exit 1
else
    echo "current sensor temperature: $temp"
fi

func_disable_factory
exit 0
