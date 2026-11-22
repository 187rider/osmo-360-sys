#!/bin/sh

test_loop=1000000 #default loops
sleep_time=3	  #default sleep_time
path=/sys/class/rtc/rtc0/wakealarm
if [ $# != 0  ]; then
    test_loop=$1
fi

if [ $# == 2  ]; then
    sleep_time=$2 #if $2==0, will sleep forever
fi

stop_all_service()
{
	echo "stop all services !!!"

	systemctl stop dji_amt.service
	systemctl stop dji_asr.service
	systemctl stop dji_blackbox.service
	systemctl stop dji_bluetooth_service.service
	systemctl stop dji_camera3.service
	systemctl stop dji_charger.service
	systemctl stop dji_config_store.service
	systemctl stop dji_ftpd.service
	systemctl stop dji_hms.service
	systemctl stop dji_http_server.service
	systemctl stop dji_kmsg.service
	systemctl stop dji_media.service
	systemctl stop dji_modules_load.service
	systemctl stop dji_network.service
	systemctl stop dji_sec.service
	systemctl stop dji_sw_uav.service
	systemctl stop dji_system.service
	systemctl stop dji_upgrade.service
	systemctl stop dji_utop.service
	systemctl stop dji_wireless_mic.service

	sleep 3
}

stop_all_service

if [ -e /sys/alarm_timer/debug_alarm ]; then
    sleep_time=$(busybox awk "BEGIN {print $sleep_time*1000}")
    path=/sys/alarm_timer/debug_alarm
    echo "use debug_alarm to timing"
else
    path=/sys/class/rtc/rtc0/wakealarm
    echo "use rtc to timing"
fi

otg_state_path=`find /sys/devices/platform/soc/ -name otg_state 2>/dev/null`
echo $otg_state_path
run_count=0

while [ $run_count -lt $test_loop ];do
    echo "Suspend test, loop $run_count/$test_loop, sleep $sleep_time"
    let 'run_count+=1'

    echo +0 > $path
    if [ $? != 0 ]; then
        echo "set +0 to debug alarm failed"
        busybox date; cat /proc/driver/rtc
        exit 1
    fi

    echo "+$sleep_time" > $path
    if [ $? != 0 ]; then
        echo "set +$sleep_time to debug alarm failed"
        busybox date; cat /proc/driver/rtc
        exit 2
    fi

    echo idle > $otg_state_path
    sleep 1
    echo mem > /sys/power/state
    if [ $? != 0  ]; then
        echo "go to low power fail!"
        exit 3
    fi
    echo "suspend & resume success!"

    let count=count+1
    sleep 2
done

echo +0 > $path
exit 0
