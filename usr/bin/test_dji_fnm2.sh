#! /bin/bash

LOG_FNAME=/blackbox/camera/log/dji_fnm2_test.log

ln -s /system/etc/dji_camera.conf /etc/dji_camera.conf

LD_PRELOAD=libdcam_hook.so:libqcom_adapter.so dji_fnm_test -g fnm2 -p /etc/test_res/fnm2_test_plugins_qcom.conf \
             -c /system/etc/fnm2_test_cases.conf -d consumer | tee ${LOG_FNAME}
