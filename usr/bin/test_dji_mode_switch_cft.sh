#!/bin/sh

# only mode_switch_cft test is enabled for now
cft_cmd="dji_cft -a -o -d cft -e null -m coroutine -g emmc \
     -F /system/etc/mode_switch_cft_cases.conf -l /blackbox/camera/log/dji_mode_switch_cft_test_rlt.log \
     -r skip_system_mem_check=true;skip_ion_check=true \
     -w file_path=/blackbox/camera/log/cft_watch_point.txt"

if [ $# -eq 1 -a "$1" == "help" ]; then
    echo "don't support gcov now"
    echo "cft cmd is ${cft_cmd}"
    exit
fi

df
#setprop dji.camera_service 0
systemctl stop dji_camera3
sleep 1
systemctl stop qmmf-server
sleep 1

mkdir -p /blackbox/camera
mkdir -p /blackbox/camera/dump
mkdir -p /blackbox/camera/log
df

systemctl restart qmmf-server
sleep 1

# set frequency point high(will be removed once the power manerger is ready)
#isp_set_clk_rate.sh -r 800

sleep 2

if [ $# -eq 1 -a "$1" == "gcov" ]; then
    echo "======================= error: cft gcov not supported!!! ======================="
    exit 1
fi

LD_PRELOAD=libdcam_hook.so:libqcom_adapter.so $cft_cmd

sleep 2
systemctl start dji_camera3
sleep 2

kill 0
