#!/bin/sh

echo 0 > /sys/devices/system/cpu/cpu7/online # close cpu7
systemctl start dji_camera3
sleep 2

LD_PRELOAD=libdcam_hook.so:libqcom_adapter.so dji_cst -a -u -d cst -f -T lapse -l /blackbox/camera/log/dji_lapse_cst_test_rlt.log
echo 1 > /sys/devices/system/cpu/cpu7/online # open cpu7