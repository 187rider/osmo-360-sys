#!/bin/sh

systemctl stop dji_camera3
sleep 2
systemctl stop qmmf-server
sleep 2

echo performance > /sys/devices/system/cpu/cpufreq/policy3/scaling_governor

case="/system/etc/cht_cases_dump_raw.json"
echo "run case: $case"
LD_PRELOAD=libqcom_adapter.so dji_cht -f $case

echo walt > /sys/devices/system/cpu/cpufreq/policy3/scaling_governor

systemctl start qmmf-server
sleep 2
systemctl start dji_camera3
sleep 2
