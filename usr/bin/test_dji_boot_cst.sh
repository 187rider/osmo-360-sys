#!/bin/sh

echo 0 > /sys/devices/system/cpu/cpu7/online # close cpu7
echo '' > /blackbox/camera/log/cam_boot_test_rlt.log
LD_PRELOAD=libdcam_hook.so:libqcom_adapter.so dji_cst -d cst -u -f -c duss_get_cam_boot_time -l /blackbox/camera/log/cam_boot_cst_test_rlt.log
echo 1 > /sys/devices/system/cpu/cpu7/online # open cpu7

systemctl restart dji_camera3
