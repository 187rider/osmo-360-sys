#! /bin/bash

# Function: OQ101 factory command test script
#
# create data: 2022-11-30
#      update: 2022-11-30  add calibraion status command check
#
# Discription:
# This script is used to check: 1) validity of command used in factory test, 2) hardware status of CI environment.
g_record_seq=$RANDOM

func_check_v1_cmd_resp_val() {
    resp_msg=`echo $1 | grep -o 'Resp message, len = [0-9]\{1\}, data: [0-9a-z ]\{2,20\}'`
    resp_val=`echo $resp_msg |busybox awk -F ':' '{printf $2;}'`
    if [ "x$resp_val" == "x$2" ];then
        return 0
    fi

    return 1
}

func_exit_script() {
    if [ "x$1" == "x0" ];then
        echo "[INFO]:factory cmd test pass"
        echo "----------------------------------------------------------------------"
    else
        echo "[ERROR]:factory cmd test failed"
        echo "----------------------------------------------------------------------"
    fi

    exit $1
}

calib_status_path="/tmp/calib_status.log"
func_calib_status_check() {
    #input param $1: calib_item
    result=`cat $calib_status_path |grep -c "$1 OK"`
    if [ $result -ne 1 ];then
        echo "[ERROR]:$1 calib status check failed"
        return 1
    fi

    echo "[INFO]:$1 calib check pass"
    return 0
}

func_calib_bin_file_check() {
    #input param $1: calib_item   $2: path
    result=`find $2 -name "$1.bin"`
    if [ "x$result" == "x" ];then
        echo "[ERROR]:$1.bin not exit, calib check failed"
        return 1
    else
        echo "[INFO]:detect file:[$result]"
    fi

    echo "[INFO]:$1 calib file check pass"
    return 0
}

echo "[INFO]:do sensor testpattern command test"
test_dji_sensor_testpattern.sh
if [ $? -ne 0 ];then
    echo "[ERROR]:sensor testpattern command test failed"
    func_exit_script 1
fi
sleep 2

echo "[INFO]:do calibration status command test"
# set single mode
result=`dji_mb_ctrl -S test -R diag -g 1 -t 0 -s 2 -c 0x8e 01013f000100`
func_check_v1_cmd_resp_val "$result" " 00"
if [ $? -ne 0 ];then
    echo "set single mode failed"
    echo $result
    return 1
else
    echo "set single mode"
fi
sleep 1

# set single video mode
result=`dji_mb_ctrl -S test -R diag -g 1 -t 0 -s 2 -c 0xe1 01`
func_check_v1_cmd_resp_val "$result" " 00"
if [ $? -ne 0 ];then
    echo "set single camera mode failed"
    echo $result
    func_exit_script 1
else
    echo "set single camera mode mode"
fi
sleep 1

echo "[INFO]:test main camera"
# set main camera
result=`dji_mb_ctrl -S test -R diag -g 1 -t 0 -s 2 -c 0xff 00150012000000`
func_check_v1_cmd_resp_val "$result" " 00"
if [ $? -ne 0 ];then
    echo "set main camera failed"
    echo $result
    func_exit_script 1
else
    echo "set mian camera mode"
fi
sleep 10

systemctl stop dji_camera3
sleep 1

systemctl restart qmmf-server
sleep 1

systemctl start dji_camera3
sleep 5

LD_PRELOAD=libdcam_hook.so:libqcom_adapter.so dji_cst -c duss_get_calibration_status |tee $calib_status_path

func_calib_status_check "awb"
if [ $? -ne 0 ];then
    func_exit_script 1
fi

func_calib_status_check "lsc_mesh"
if [ $? -ne 0 ];then
    func_exit_script 1
fi

# func_calib_status_check "dsa"
# if [ $? -ne 0 ];then
#     func_exit_script 1
# fi

# func_calib_status_check "qsc"
# if [ $? -ne 0 ];then
#     func_exit_script 1
# fi

# func_calib_status_check "intri_param"
# if [ $? -ne 0 ];then
#     func_exit_script 1
# fi

# func_calib_status_check "extri_param"
# if [ $? -ne 0 ];then
#     func_exit_script 1
# fi

echo "[INFO]:test secondary camera"
# set single mode
result=`dji_mb_ctrl -S test -R diag -g 1 -t 0 -s 2 -c 0x8e 01013f000100`
func_check_v1_cmd_resp_val "$result" " 00"
if [ $? -ne 0 ];then
    echo "set single mode failed"
    echo $result
    return 1
else
    echo "set single mode"
fi
sleep 1

# set single video mode
result=`dji_mb_ctrl -S test -R diag -g 1 -t 0 -s 2 -c 0xe1 01`
func_check_v1_cmd_resp_val "$result" " 00"
if [ $? -ne 0 ];then
    echo "set single camera mode failed"
    echo $result
    func_exit_script 1
else
    echo "set single camera mode mode"
fi
sleep 1
# set secondary camera
result=`dji_mb_ctrl -S test -R diag -g 1 -t 0 -s 2 -c 0xff 00150011000000`
func_check_v1_cmd_resp_val "$result" " 00"
if [ $? -ne 0 ];then
    echo "set secondary camera failed"
    echo $result
    func_exit_script 1
else
    echo "set secondary camera mode"
fi
sleep 10

systemctl stop dji_camera3
sleep 1

systemctl restart qmmf-server
sleep 1

systemctl start dji_camera3
sleep 5

LD_PRELOAD=libdcam_hook.so:libqcom_adapter.so dji_cst -c duss_get_calibration_status |tee $calib_status_path

func_calib_status_check "awb"
if [ $? -ne 0 ];then
    func_exit_script 1
fi

func_calib_status_check "lsc_mesh"
if [ $? -ne 0 ];then
    func_exit_script 1
fi

# func_calib_status_check "dsa"
# if [ $? -ne 0 ];then
#     func_exit_script 1
# fi

# func_calib_status_check "qsc"
# if [ $? -ne 0 ];then
#     func_exit_script 1
# fi

# func_calib_status_check "intri_param"
# if [ $? -ne 0 ];then
#     func_exit_script 1
# fi

# func_calib_status_check "extri_param"
# if [ $? -ne 0 ];then
#     func_exit_script 1
# fi

func_exit_script 0
