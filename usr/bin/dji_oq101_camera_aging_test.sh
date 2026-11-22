#! /bin/bash

# AC204 camera aging test script
# updated data: 2024-08-29
# pano 8k30 recording 30min

cam_record_time=1800
# aging_dir=/data/dji/amt/aging_test/
resp_file=/data/dji/amt/mb_ctrl_resp

# ------------------------ log and v1 check function ---------------------------------
func_log_info() {
    timestamp=`date "+%H:%M:%S"`
    echo "[CAMERA_AGING][$timestamp] [INFO]:$1"
}

func_log_warning() {
    timestamp=`date "+%H:%M:%S"`
    echo "[CAMERA_AGING][$timestamp] [WARNING]:$1"
}

func_log_error() {
    timestamp=`date "+%H:%M:%S"`
    echo "[CAMERA_AGING][$timestamp] [ERROR]:$1"
}

func_check_v1_cmd_resp_val() {
    resp_msg=`echo $1 | grep -o 'Resp message, len = [0-9]\{1\}, data: [0-9a-z ]\{2,20\}'`
    resp_val=`echo $resp_msg |busybox awk -F ':' '{printf $2;}'`
    if [ "x$resp_val" == "x$2" ];then
        return 0
    fi

    return 1
}

# ------------------------ camera aging ---------------------------------
func_camera_aging() {
    # set pano mode
    result=`dji_mb_ctrl -q 0 -R diag -g 1 -t 0 -s 2 -c 0x8e 01013f000101`
    func_check_v1_cmd_resp_val "$result" " 00"
    if [ $? -ne 0 ];then
        echo $result
        func_log_error "set pano mode (8e) failed"
        return 1
    else
        func_log_info "set pano mode (8e) success"
    fi
    sleep 0.1

    # set mode profile to pano records
    result=`dji_mb_ctrl -q 0 -R diag -g 1 -t 0 -s 2 -c 0xe1 38`
    func_check_v1_cmd_resp_val "$result" " 00"
    if [ $? -ne 0 ];then
        echo $result
        func_log_error "set record mode (e1) failed"
        return 1
    else
        func_log_info "set record mode (e1) success"
    fi
    sleep 0.1

    # set video format :8k@30
    result=`dji_mb_ctrl -q 0 -R diag -g 1 -t 0 -s 2 -c 0x18 6f03000000`
    func_check_v1_cmd_resp_val "$result" " 00"
    if [ $? -ne 0 ];then
        echo $result
        func_log_error "set 8k 30fps record video format (18) failed"
        return 1
    else
        func_log_info "set 8k 30fps record video format (18) success"
    fi
    sleep 0.1

    # switch channel 5745
    result=`dji_mb_ctrl -S test -R diag -g 7 -t 0 -s 9 -c 0x91 15000400010000000a000400109e6c030b000400140000000d000400d00700001300040006000000140004000600000016000400000000000c00040003000000230004000004000025000400640000002900040002000000`
    func_check_v1_cmd_resp_val "$result" " 00"
    if [ $? -ne 0 ];then
        echo $result
        func_log_error "switch channel (5745) failed"
        return 1
    else
        func_log_info "switch channel (5745) success"
    fi
    sleep 1

    # start record
    result=`dji_mb_ctrl -q 0 -R diag -g 1 -t 0 -s 2 -c 0x02 01`
    func_check_v1_cmd_resp_val "$result" " 00"
    if [ $? -ne 0 ];then
        echo $result
        func_log_error "start record (02) failed"
        return 1
    else
        func_log_info "start record (02) success"
    fi

    # set the start record time
    start_rec_time=$(date +%s)
    current_time=$(date +%s)
    record_time=0

    sleep 2

    # check recording status, record CAM_RECORD_TIME seconds
    while [ $record_time -lt $cam_record_time ]; do
        sleep 10

        if [ $record_time -ge $switch_channel_time ] && [ $is_switched_channel -eq 0 ]; then
            # switch channel 5825
            result=`dji_mb_ctrl -S test -R diag -g 7 -t 0 -s 9 -c 0x91 15000400010000000a00040010d378030b000400140000000d000400d00700001300040006000000140004000600000016000400000000000c00040003000000230004000004000025000400640000002900040002000000`
            func_check_v1_cmd_resp_val "$result" " 00"
            if [ $? -ne 0 ];then
                echo $result
                func_log_error "switch channel (5825) failed"
                return 1
            else
                func_log_info "switch channel (5825) success"
            fi
            sleep 1
            is_switched_channel=1
        fi

        #check record status
        result=`dji_mb_ctrl -r -q 0 -R diag -g 1 -t 0 -s 2 -c 0x70`

        record_status=$(busybox od -An -t d -j 1 -N 1 $resp_file)
        let "record_status >>= 6"
        if [ $record_status -ne 2 ]; then
            func_log_error "check recording status err:$record_status !"
            return 1
        else
            func_log_info "check recording status success !"
        fi

        current_time=$(date +%s)
        let "record_time = $current_time - $start_rec_time"
    done

    # stop record
    result=`dji_mb_ctrl -q 0 -R diag -g 1 -t 0 -s 2 -c 0x02 00`
    func_check_v1_cmd_resp_val "$result" " 00"
    if [ $? -ne 0 ];then
        echo $result
        func_log_error "stop record (02) failed"
        return 1
    else
        func_log_info "stop record (02) success"
    fi
    sleep 3

    return 0
}

# -----------------------------------------------------------------------
func_log_info "cam_aging start !!!"
# rm -rf $aging_dir
# mkdir -p $aging_dir
date
ps | busybox grep -e .*dji.*

# ----------------------- check input param ---------------------------
if [ ! -n "$1" ];then
    func_log_warning "no input param test time, use default time [$cam_record_time] seconds"
elif [ $1 -le 0 ];then
    func_log_error "wrong input param, please check"
    exit 1
else
    cam_record_time=$1
    func_log_info "set test time [$cam_record_time] seconds"
fi

is_switched_channel=0
switch_channel_time=$((cam_record_time / 2))

# ----------------------- Set external Storage --------------------------
result=`dji_mb_ctrl -q 0 -R diag -g 1 -t 0 -s 2 -c 0xda 01000000020100`
result_msg=`echo $result | grep -o 'Resp message, len = [0-9]\{1\}, data: [0-9a-z ]\{2,20\}'`
result_val=`echo $result_msg |busybox awk -F ':' '{printf $7;}'`
if [ "x$result_val" == "x00" ];then
    echo $result
    func_log_error "set external0 storage wrong"
    exit 1
else
    func_log_info "set external0 storage success"
fi
sleep 0.1

# ----------------------- Format Storage ---------------------------
result=`dji_mb_ctrl -q 0 -R diag -g 1 -t 0 -s 2 -c 0x72 00`
func_check_v1_cmd_resp_val "$result" " 00"
if [ $? -ne 0 ];then
    echo $result
    func_log_error "set storage format wrong"
    exit 1
else
    func_log_info "set storage format success"
fi
sleep 0.1

# ----------------------- set reset fileindex mode in DCF ---------------------------
result=`dji_mb_ctrl -q 0 -R diag -g 1 -t 0 -s 2 -c 0x5c 00`
func_check_v1_cmd_resp_val "$result" " 00"
if [ $? -ne 0 ];then
    echo $result
    func_log_error "set reset fileindex (5c) failed"
    exit 1
else
    func_log_info "set reset fileindex (5c) success"
fi
sleep 0.1

func_camera_aging
if [ $? -ne 0 ];then
    func_log_error "cam_aging failed"
    exit 1
fi

# ----------------------- Set internal Storage --------------------------
result=`dji_mb_ctrl -q 0 -R diag -g 1 -t 0 -s 2 -c 0xda 01000000020101`
result_msg=`echo $result | grep -o 'Resp message, len = [0-9]\{1\}, data: [0-9a-z ]\{2,20\}'`
result_val=`echo $result_msg |busybox awk -F ':' '{printf $7;}'`
if [ "x$result_val" == "x00" ];then
    echo $result
    func_log_error "set internal0 storage wrong"
    exit 1
else
    func_log_info "set internal0 storage success"
fi
sleep 0.1

systemctl stop dji_camera3
sleep 1
systemctl restart qmmf-server
sleep 1
systemctl start dji_camera3
sleep 1

func_log_info "cam_aging SUCCESS for $cam_record_time seconds!"
exit 0
