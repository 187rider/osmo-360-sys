#! /bin/bash

# OQ101 camera hardware link test script
# updated data: 2023-09-27

g_seq=$RANDOM
test_result=0
test_result_sensor0=0
test_result_sensor1=0

# ------------------------ log and v1 check function ---------------------------------
func_log_info() {
    timestamp=`date "+%H:%M:%S"`
    echo "[$timestamp] [INFO]:$1"
}

func_log_error() {
    timestamp=`date "+%H:%M:%S"`
    echo "[$timestamp] [ERROR]:$1"
}

func_check_v1_cmd_resp_val() {
    resp_msg=`echo $1 | grep -o 'Resp message, len = [0-9]\{1\}, data: [0-9a-z ]\{2,20\}'`
    resp_val=`echo $resp_msg |busybox awk -F ':' '{printf $2;}'`
    if [ "x$resp_val" == "x$2" ];then
        return 0
    fi

    return 1
}

func_enable_factory() {

    systemctl stop dji_camera3
    sleep 1
    systemctl stop qmmf-server
    sleep 1

    cp -v /system/etc/factorytest.txt /data/camera/camxoverridesettings.txt
    sync

    setprop persist.dji.gst_frwk.debug 0x40

    systemctl start qmmf-server
    sleep 1
    systemctl start dji_camera3
    sleep 5

    func_log_info "enable factory test success!"
}

func_disable_factory() {
    systemctl stop dji_camera3
    sleep 1
    systemctl stop qmmf-server
    sleep 1

    rm /data/camera/camxoverridesettings.txt
    sync

    setprop persist.dji.gst_frwk.debug 0x00

    systemctl start qmmf-server
    sleep 1
    systemctl start dji_camera3
    sleep 5

    func_log_info "disable factory test success!"
}

# -------------------- sensor0 testPattern test ---------------------------
func_testpattern_sensor0() {

    # set internal storage
    result=`dji_mb_ctrl -S test -R diag -g 1 -t 0 -s 2 -c 0xDA 01000000020101`
    result_msg=`echo $result | grep -o 'Resp message, len = [0-9]\{1\}, data: [0-9a-z ]\{2,20\}'`
    result_val=`echo $result_msg |busybox awk -F ': ' '{printf $2;}'`
    result_val=`echo $result_val |busybox awk -F ' ' '{printf $1;}'`
    if [ "x$result_val" == "x00" ];then
        func_log_info "set internal storage success"
    else
        echo $result
        func_log_error "set internal storage wrong"
        exit 1
    fi
    sleep 1

    # format internal storage
    result=`dji_mb_ctrl -S test -R diag -g 1 -t 0 -s 2 -c 0x72 01`
    func_check_v1_cmd_resp_val "$result" " 00"
    if [ $? -ne 0 ];then
        func_log_error "format internal storage failed"
        echo $result
        return 1
    else
        func_log_info "format internal storage mode"
    fi
    sleep 1

    # set dump directory
    raw_directory_oq101="/mnt/media_rw/emulated"

    # set single mode
    result=`dji_mb_ctrl -S test -R diag -g 1 -t 0 -s 2 -c 0x8e 01013f000100`
    func_check_v1_cmd_resp_val "$result" " 00"
    if [ $? -ne 0 ];then
        func_log_error "set single mode failed"
        echo $result
        return 1
    else
        func_log_info "set single mode"
    fi
    sleep 1

    # set capture mode
    result=`dji_mb_ctrl -S test -R diag -g 1 -t 0 -s 2 -c 0xe1 05`
    func_check_v1_cmd_resp_val "$result" " 00"
    if [ $? -ne 0 ];then
        func_log_error "set capture failed"
        echo $result
        return 1
    else
        func_log_info "set capture mode"
    fi
    sleep 1

    # switch sensor 0
    result=`dji_mb_ctrl -R diag -g 1 -t 0 -s 2 -c 0xff 00150011000000`
    func_check_v1_cmd_resp_val "$result" " 00"
    if [ $? -ne 0 ];then
        func_log_error "switch sensor 0 failed"
        echo $result
        return 1
    else
        func_log_info "switch sensor 0 success"
    fi
    sleep 1

    # set advance mode
    result=`dji_mb_ctrl -S test -R diag -g 1 -t 0 -s 2 -c 0x8e 010100000101`
    func_check_v1_cmd_resp_val "$result" " 00"
    if [ $? -ne 0 ];then
        func_log_error "set advance mode failed"
        echo $result
        return 1
    else
        func_log_info "set advance mode"
    fi
    sleep 1

    # set storage J+R
    result=`dji_mb_ctrl -S test -R diag -g 1 -t 0 -s 2 -c 0x16 02`
    func_check_v1_cmd_resp_val "$result" " 00"
    if [ $? -ne 0 ];then
        func_log_error "set storage J+R failed"
        echo $result
        return 1
    else
        func_log_info "set storage J+R mode"
    fi
    sleep 1

    # set 4:3
    echo $g_seq
    result=`dji_mb_ctrl -S test -R diag -q $g_seq -g 1 -t 0 -s 2 -c 0x12 0300`
    func_check_v1_cmd_resp_val "$result" " 00"
    if [ $? -ne 0 ];then
        func_log_error "set sensor mode 4:3 failed"
        echo $result
        return 1
    else
        func_log_info "set sensor mode 4:3"
    fi
    g_seq=$(($g_seq+1))
    echo $g_seq
    sleep 2

    # take photo
    result=`dji_mb_ctrl -R diag -g 1 -t 0 -s 2 -c 01 01`
    func_check_v1_cmd_resp_val "$result" " 00"
    if [ $? -ne 0 ];then
        func_log_error "take photo failed"
        echo $result
        return 1
    else
        func_log_info "take photo success"
    fi
    sleep 2

    # check if raw pictures exit or not
    if [ -d $raw_directory_oq101 ];then
        raw_directory=$raw_directory_oq101
        func_log_info "raw directory:${raw_directory}"
    else
        func_log_error "raw directory not found"
        return 1
    fi

    # get raw
    file_name=$(find "${raw_directory}" -type f -name "*.RawPlain16LSB1" -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)
    if [ $? -eq 0 ];then
        func_log_info "RAW file name:${file_name}"
    else
        func_log_error "get raw picture failed"
        return 1
    fi

    # get and check md5 of raw
    expect_md5="7a50a97b7d0a321bc17f9e31021dc9e2"
    raw_md5=`md5sum ${file_name} |grep -o "[0-9a-z]\{32\}"`
    func_log_info "md5_val:[${raw_md5}]"
    if [ ${raw_md5} != ${expect_md5} ];then
        func_log_error "md5 value check failed, expect:[${expect_md5}]"
        return 1
    else
        func_log_info "md5 value check success"
    fi

    return 0
}

# -------------------- sensor1 testPattern test ---------------------------
func_testpattern_sensor1() {

    # set internal storage
    result=`dji_mb_ctrl -S test -R diag -g 1 -t 0 -s 2 -c 0xDA 01000000020101`
    result_msg=`echo $result | grep -o 'Resp message, len = [0-9]\{1\}, data: [0-9a-z ]\{2,20\}'`
    result_val=`echo $result_msg |busybox awk -F ': ' '{printf $2;}'`
    result_val=`echo $result_val |busybox awk -F ' ' '{printf $1;}'`
    if [ "x$result_val" == "x00" ];then
        func_log_info "set internal storage success"
    else
        echo $result
        func_log_error "set internal storage wrong"
        exit 1
    fi
    sleep 1

    # format internal storage
    result=`dji_mb_ctrl -S test -R diag -g 1 -t 0 -s 2 -c 0x72 01`
    func_check_v1_cmd_resp_val "$result" " 00"
    if [ $? -ne 0 ];then
        func_log_error "format internal storage failed"
        echo $result
        return 1
    else
        func_log_info "format internal storage mode"
    fi
    sleep 1

    # set dump directory
    raw_directory_oq101="/mnt/media_rw/emulated"

    # set single mode
    result=`dji_mb_ctrl -S test -R diag -g 1 -t 0 -s 2 -c 0x8e 01013f000100`
    func_check_v1_cmd_resp_val "$result" " 00"
    if [ $? -ne 0 ];then
        func_log_error "set single mode failed"
        echo $result
        return 1
    else
        func_log_info "set single mode"
    fi
    sleep 1

    # set capture mode
    result=`dji_mb_ctrl -S test -R diag -g 1 -t 0 -s 2 -c 0xe1 05`
    func_check_v1_cmd_resp_val "$result" " 00"
    if [ $? -ne 0 ];then
        func_log_error "set capture failed"
        echo $result
        return 1
    else
        func_log_info "set capture mode"
    fi
    sleep 1

    # switch sensor 1
    result=`dji_mb_ctrl -R diag -g 1 -t 0 -s 2 -c 0xff 00150012000000`
    func_check_v1_cmd_resp_val "$result" " 00"
    if [ $? -ne 0 ];then
        func_log_error "switch sensor 1 failed"
        echo $result
        return 1
    else
        func_log_info "switch sensor 1 success"
    fi
    sleep 1

    # set advance mode
    result=`dji_mb_ctrl -S test -R diag -g 1 -t 0 -s 2 -c 0x8e 010100000101`
    func_check_v1_cmd_resp_val "$result" " 00"
    if [ $? -ne 0 ];then
        func_log_error "set advance mode failed"
        echo $result
        return 1
    else
        func_log_info "set advance mode"
    fi
    sleep 1

    # set storage J+R
    result=`dji_mb_ctrl -S test -R diag -g 1 -t 0 -s 2 -c 0x16 02`
    func_check_v1_cmd_resp_val "$result" " 00"
    if [ $? -ne 0 ];then
        func_log_error "set storage J+R failed"
        echo $result
        return 1
    else
        func_log_info "set storage J+R mode"
    fi
    sleep 1

    # set 4:3
    echo $g_seq
    result=`dji_mb_ctrl -S test -R diag -q $g_seq -g 1 -t 0 -s 2 -c 0x12 0300`
    func_check_v1_cmd_resp_val "$result" " 00"
    if [ $? -ne 0 ];then
        func_log_error "set sensor mode 4:3 failed"
        echo $result
        return 1
    else
        func_log_info "set sensor mode 4:3"
    fi
    g_seq=$(($g_seq+1))
    echo $g_seq
    sleep 2

    # take photo
    result=`dji_mb_ctrl -R diag -g 1 -t 0 -s 2 -c 01 01`
    func_check_v1_cmd_resp_val "$result" " 00"
    if [ $? -ne 0 ];then
        func_log_error "take photo failed"
        echo $result
        return 1
    else
        func_log_info "take photo success"
    fi
    sleep 2

    # check if raw pictures exit or not
    if [ -d $raw_directory_oq101 ];then
        raw_directory=$raw_directory_oq101
        func_log_info "raw directory:${raw_directory}"
    else
        func_log_error "raw directory not found"
        return 1
    fi

    # get raw
    file_name=$(find "${raw_directory}" -type f -name "*.RawPlain16LSB1" -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)
    if [ $? -eq 0 ];then
        func_log_info "RAW file name:${file_name}"
    else
        func_log_error "get raw picture failed"
        return 1
    fi

    # get and check md5 of raw
    expect_md5="7a50a97b7d0a321bc17f9e31021dc9e2"
    raw_md5=`md5sum ${file_name} |grep -o "[0-9a-z]\{32\}"`
    func_log_info "md5_val:[${raw_md5}]"
    if [ ${raw_md5} != ${expect_md5} ];then
        func_log_error "md5 value check failed, expect:[${expect_md5}]"
        return 1
    else
        func_log_info "md5 value check success"
    fi

    return 0
}

# ---------------------------------------------------------------------------------------
echo "----- OQ101 sensor testpattern test start-----"

func_enable_factory

func_testpattern_sensor0
if [ $? -eq 0 ];then
    test_result_sensor0=0
    func_log_info "OQ101 sensor 0 testpattern test complete, test result: pass!!!"
else
    test_result_sensor0=1
    func_log_info "OQ101 sensor 0 testpattern test complete, test result: fail!!!"
fi

func_enable_factory

func_testpattern_sensor1
if [ $? -eq 0 ];then
    test_result_sensor1=0
    func_log_info "OQ101 sensor 1 testpattern test complete, test result: pass!!!"
else
    test_result_sensor1=1
    func_log_info "OQ101 sensor 1 testpattern test complete, test result: fail!!!"
fi

if [ $test_result_sensor0 -eq 0 ] && [ $test_result_sensor1 -eq 0 ]; then
  test_result=0
else
  test_result=1
fi

func_disable_factory

# format internal storage
result=`dji_mb_ctrl -S test -R diag -g 1 -t 0 -s 2 -c 0x72 01`
func_check_v1_cmd_resp_val "$result" " 00"
if [ $? -ne 0 ];then
    func_log_error "format internal storage failed"
    echo $result
    exit 1
else
    func_log_info "format internal storage mode"
fi
sleep 1

if [ $test_result -eq 0 ];then
    exit 0
else
    exit 1
fi
