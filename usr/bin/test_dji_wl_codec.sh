#!/bin/sh

# test_dji_wl_codec.sh for Qualcomm platform

module=$1
case_num=$2
platform=$3

STATUS_OK="SUCCESS"
STATUS_NOT_OK="FAIL"

alias awk="busybox awk"

log_dir="/blackbox/system/wl_codec"
log_name="test_dji_wl_codec_run.log"

cam_log_dir="/blackbox/camera/log"
cam_log_name="cam.log"

system_log_dir="/blackbox/system"
system_log_name="system.log"

test_dji_wl_codec_help() {
    echo "Usage: test_dji_wl_codec.sh (for Qualcomm) test_module case_number"
    echo "       test_dji_wl_codec.sh venc 1  (run first wl venc case, now 2 cases are supported)"
}

#========== test main func start =================
if [ ! -d $log_dir ]; then
    mkdir $log_dir
    #echo "$log_dir has been created!"
#else
    #echo "$log_dir has exist!"
fi

if [[ -z $module || $module = "-h" || $module = "-help" ]]; then
    test_dji_wl_codec_help
elif [ is$module == is"venc" -o is$module == is"wl_codec_venc" ]; then
    if [ is$case_num == is"1" ]; then  
        # test_dji_wl_codec.sh venc 1: Check avg rate control result 
        LOG_FILE=$cam_log_dir/$cam_log_name

        KEYWORD1="Result/target len sum"
        LOG1=$(grep "$KEYWORD1" "$LOG_FILE" | tail -n 1)
        if [ -z "$LOG1" ]; then
            echo "Cannot find log with '$KEYWORD1'"
            echo "wl_codec_venc_result:$STATUS_NOT_OK"
			exit
        fi
        rc_diff_thr=15
        rc_result=$(echo "$LOG1" | awk -F 'Result/target len sum = ' '{print $2}' | awk -F ' / ' '{print $1}')
        rc_target=$(echo "$LOG1" | awk -F 'Result/target len sum = ' '{print $2}' | awk -F ' / ' '{print $2}' | awk '{print $1}')
		rc_target=${rc_target%%.*}
		rc_diff_value=$(($rc_result-$rc_target))
		rc_diff_abs=${rc_diff_value#-}
		rc_diff=$((rc_diff_abs * 100 / rc_target))
		if [ "$rc_diff" -gt $rc_diff_thr ]; then
            echo "Avg rc diff is larger than $rc_diff_thr%: $rc_diff%"
            echo "wl_codec_venc_result:$STATUS_NOT_OK"
			exit
        else
            echo "Avg rc diff is less than $rc_diff_thr%: $rc_diff%"
        fi
        echo "wl_codec_venc_result:$STATUS_OK"
        # test_dji_wl_codec.sh venc 1: end
    elif [ is$case_num == is"2" ]; then  
        # test_dji_wl_codec.sh venc 2: Check input and output count
        LOG_FILE=$cam_log_dir/$cam_log_name

        KEYWORD2="\[Profile wl delay\] AVG"
        LOG2=$(grep "$KEYWORD2" "$LOG_FILE" | tail -n 1)
        if [ -z "$LOG2" ]; then
            echo "Cannot find log with '$KEYWORD2'"
            echo "wl_codec_venc_result:$STATUS_NOT_OK"
			exit
        fi
        cnt_value_list=$(echo "$LOG2" | sed -n 's/.*(\([0-9]\+\)).*/\1/p' | tr '\n' ' ')
        input_cnt=$(echo "$cnt_value_list" | head -n 1)
        ALL_EQUAL_FLAG=true
        for value in $cnt_value_list; do
            if [ "$value" -ne "$input_cnt" ]; then
                ALL_EQUAL_FLAG=false
                break
            fi
        done
        if $ALL_EQUAL_FLAG; then
            echo "Input and output counts match"
        else
            echo "Input and output counts do not match"
            echo "wl_codec_venc_result:$STATUS_NOT_OK"
			exit
        fi
        echo "wl_codec_venc_result:$STATUS_OK"
        # test_dji_wl_codec.sh venc 2: end
    fi
fi

