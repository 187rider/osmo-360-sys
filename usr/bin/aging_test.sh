# include the script lib
. aging_test_configure.sh
. lib_test.sh
. lib_test_cases.sh
. led_ctrl_app.sh
. parse_error_reason.sh
. aging_test_lock.sh

SLAVE_AGING_TEST_ID="0e000000"
SLAVE_AGING_TEST_NAME=$(amt_data_trans.sh "aging_test.sh" $SLAVE_AGING_TEST_ID 3000000)
PIGEON_AGING_TEST_ID="0e000000"
PIGEON_AGING_TEST_NAME=$(amt_data_trans.sh "aging_test.sh" $PIGEON_AGING_TEST_ID 3000000)

with_camera=0
# camera store flag in camera partition or sdcard
stored_camera=1

function aging_test_init()
{
    #check emulated folder mounted
    check_emulated_mount

    # FC LED control process
    if [ ! -d ${dji_log_dir} ]; then
        mkdir -p ${dji_log_dir}
    fi

    if [ -f ${led_ctrl_log_file} ]; then
        rm -rf ${led_ctrl_log_file}
    fi
    sync
    sleep 1
    led_ctrl.sh >> ${led_ctrl_log_file} 2>&1 &
    # Make sure that the following led_red_on is excuted correctly
    sleep 5
    # If aging test is already done?
    check_aging_test_result_log ${aging_test_log_file} ${aging_test_result_file} >>${check_aging_log_file}
    if [ $? != 0 ]; then
        echo "check_aging_test_result_log failed!"
        echo "check_aging_test_result_log failed!" >>${check_aging_log_file}
        sync
        app_led_red_on
        touch ${end_of_aging_test}
        sync
        exit 34
    fi

    aging_test_lock_init

    #create some folder which configured
    create_aging_test_dir

    mkdir -p ${sd_amt_dir}/codec/
    cp -rf /data/dji/codec/ ${sd_amt_dir}/

    #default mark as need copy system log
    touch $need_to_copy_system_log
    touch $fail_cnt
    touch $success_cnt
    touch ${link_err_record_file}

    # Record module name if there's something wrong with it
    if [ -f $err_module_file ]; then
        rm -rf $err_module_file
    fi
    touch $err_module_file
    sync
}

aging_start=$(cat /proc/uptime | busybox awk -F. '{printf $1}')
aging_elapsed() {
    local now=$(cat /proc/uptime | busybox awk -F. '{printf $1}')
    local diff=$(($now - $aging_start))
    echo $diff
}

copy_result() {
    echo try2 to copy aging test result
    sync

    # 1.Copy slave and pigeon aging test log
    #copy_slave_aging_test_log
    #copy_pigeon_aging_test_log

    # 2. Always copy all master aging_test log
    busybox cp ${sd_amt_dir} $master_result_dir/ -rf
    mkdir -p ${master_result_dir}/blackbox/system
    mkdir -p ${master_result_dir}/blackbox/coredump
    mkdir -p ${master_result_dir}/blackbox/tombstones
    busybox cp $sys_log_dir/* ${master_result_dir}/blackbox/system -rf
    busybox cp ${coredump_dir}/* ${master_result_dir}/blackbox/coredump -rf
    busybox cp ${tombstone_dir}/* ${master_result_dir}/blackbox/tombstones -rf
    sync
}

# skip this step when fails
clean_up_in_success() {
    echo "cleanup log files in success..."
    rm -rf /data/dji/amt/codec/in/b3.h264
    rm -rf /data/dji/amt/codec/in/1.jpg
    rm -rf /data/dji/amt/codec/out/b3
    rm -rf /data/dji/amt/codec/out/j
    rm -f ${sd_dir}/sd.data
    rm -f ${sd_amt_test_dir}/eMMC.data
    rm -rf $need_to_copy_camera_log
    rm -rf $need_to_copy_system_log
}

copy_all_need_log()
{
    local module_name=$1
    echo "$module_name: start to copy log"

    get_log_copy_flag $module_name camera
    if [ $? == 1 ];then
        echo "$module_name: camera log need to copy, now copy it."
        mkdir -p $log_copy_base_dir/$module_name/camera
        busybox cp $camera_dir/* $log_copy_base_dir/$module_name/camera -rf
    fi

    # the system log need to copy, no matter what err happen
    get_log_copy_flag $module_name system
    if [ $? == 1 ];then
        echo "$module_name: system log need to copy, now copy it."
        mkdir -p $log_copy_base_dir/$module_name/system
        mkdir -p $log_copy_base_dir/$module_name/coredump
        mkdir -p $log_copy_base_dir/$module_name/tombstones
        busybox cp $sys_log_dir/* $log_copy_base_dir/$module_name/system -rf
        busybox cp ${coredump_dir}/* $log_copy_base_dir/$module_name/coredump -rf
        busybox cp ${tombstone_dir}/* $log_copy_base_dir/$module_name/tombstones -rf
    fi

    sync
}

# error action
error_action() {
    aging_test_lock
    echo error_action: \"$2\", error=$1
    echo $BASHPID
    echo

    local me=$BASHPID
    local module=$3
    local case=`echo $2 |busybox sed 's/\"//g'`
    local err=$1
    echo "###########################$case finished###################################" >> ${aging_test_result_file}

    if [ $err -ne 0 ]; then
        echo $case >>$fail_cnt
        echo "$module" >> $err_module_file
        touch $aging_test_tmp_dir/${me}_${fail_postfix}

        #echo FAILED, \"$2\", error $1 >> ${aging_test_result_file}
        echo "$case: FAIL, error code: $err, at $(aging_elapsed) seconds __fail" >> ${aging_test_result_file}
        echo "$case: FAIL, error code: $err, at $(aging_elapsed) seconds __fail"
        echo
        echo
        #echo aging_test failed, error at case: \"$2\"
        copy_all_need_log $case
        # blinking the red led
        # app_led_red_blink
        # echo app_led_red_blink
    else
        # success in silent
        echo $case >>$success_cnt
        touch $aging_test_tmp_dir/${me}_${success_postfix}
        echo __success, \"$case\" >> ${aging_test_result_file}
    fi

    # check failed flag, if 4 test case all __success, app_led_green_on
    echo "check aging_test_result_file, than show led green or red"
    led_flag_count=$(grep -o '__success' "$aging_test_result_file" | wc -l)
    if [ $led_flag_count -eq 4 ]; then
        echo "aging_test_result_file have 4 __success"
        app_led_green_on
        echo "PASSED" >> ${aging_test_result_file}
    fi
    # check failed flag, if have 1 FAIL, error code, app_led_red_on
    led_flag_count=$(grep -o 'FAIL, error code' "$aging_test_result_file" | wc -l)
    if [ $led_flag_count -eq 1 ]; then
        echo "aging_test_result_file do not have 4 __success"
        app_led_red_on
        echo "FAILED" >> ${aging_test_result_file}
    fi

    cnt_nok=$(ls -l $aging_test_tmp_dir | grep -c "${fail_postfix}")
    cnt_ok=$(ls -l $aging_test_tmp_dir | grep -c "${success_postfix}")
    cnt_sum=$(($cnt_nok + $cnt_ok))
    echo cnt_nok=$cnt_nok
    echo cnt_ok=$cnt_ok
    echo cnt_sum=$cnt_sum
    if [ $cnt_sum -ge $sum_num ]; then
        touch ${aging_test_finished_flag}
        sync
        echo "pid of me: $BASHPID, $case, All cases excute finished."
    fi
    sync
    aging_test_unlock
}

check_aging_test_result() {
    aging_test_lock
        if [ ! -f ${aging_test_log_file} ]; then
            echo "__fail, ${aging_test_log_file} not exists"
            echo "__fail, ${aging_test_log_file} not exists" >>${aging_test_result_file}
            copy_all_need_log no_finished
        else
            cnt_nok=$(ls -l $aging_test_tmp_dir | grep -c "${fail_postfix}")
            cnt_ok=$(ls -l $aging_test_tmp_dir | grep -c "${success_postfix}")
            cnt_sum=$(($cnt_nok + $cnt_ok))
            echo cnt_nok=$cnt_nok
            echo cnt_ok=$cnt_ok
            echo cnt_sum=$cnt_sum
            if [ $cnt_sum -lt $sum_num ]; then
                echo "__fail, someone not finished even we give 30min more than promised! __fail ..."
                echo "__fail, someone not finished even we give 30min more than promised! __fail ..." >> ${aging_test_result_file}
                echo FAILED >> ${aging_test_result_file}
            else
                c=$(wc -l ${aging_test_log_file} | busybox awk '{print $1}')
                # we assume ${aging_test_log_file} should not less than 100 lines
                if [ $c -lt 100 ]; then
                    echo "${aging_test_log_file} too less"
                    echo "${aging_test_log_file} is too short with $c lines" >>${aging_test_result_file}
                    echo FAILED >> ${aging_test_result_file}
                else
                    if [ $cnt_sum -ge $sum_num ]; then
                        touch ${aging_test_finished_flag}
                        sync
                        echo "pid of me: $BASHPID, $case, all cases excute finished, i am exiting."
                        if [ $cnt_nok -eq 0 ]; then
                            echo PASSED >> ${aging_test_result_file}
                            # app_led_green_on
                            sync
                        else
                            echo FAILED >> ${aging_test_result_file}
                            app_led_red_on
                            sync
                        fi
                    fi
                fi
            fi
        fi
    #####################################################################################################
    aging_test_unlock
}

process_log_info() {
    #process master tombstones,get process name and file names
    echo "check master tombstones file"
    local r=`grep  "pid:" "${master_result_dir}"/blackbox/system/tombstones/ -nr | grep -i ">>>" `
    echo "$r"
    echo "$r" > ${master_result_dir}/blackbox/system/tombstones_results
}

aging_test() {
    #####################################################################################################
    #              master Platform aging test
    #####################################################################################################
    echo "running aging_test test!!"
    echo "pid of me: $BASHPID"
    echo "interrupts stats :"
    cat /proc/interrupts | grep sd
    cat /proc/interrupts | grep usb
    echo "interrupts stat ends"

    local temp=`cat /blackbox/system/system.log | grep e3t_temperature_group, | tail -n 1 | busybox awk '{print $10}' | busybox awk -F, '{print $1}'`
    echo "start temp:$temp" >> $aging_test_result_file
    sleep 20
    app_led_green_blink
    echo app_led_green_blink

    # mkdir /mnt/media_rw/sd/amt/aging_test for create log.txt
    mkdir -p ${sd_amt_test_dir}

    #check ssd enable
    #check_ssd_enable
    #confiure test type
    config_test_type
    #configure test case
    config_testcase_check_flag
    #config timeout
    config_timeout
    #get pid of dji process
    bsp_get_max_pid

    local ats="aging_test"
    if [ "$test_type"x == "1"x ]; then
        #aging_test, simple version
        ats="aging_test"
    elif [ "$test_type"x == "2"x ]; then
        #aging_test_local, full version
        ats="aging_test_local"
    elif [ "$test_type"x == "3"x ]; then
        #full cam test
        ats="aging_test_full_cam"
    elif [  "$test_type"x == "4"x ]; then
        #link test
        ats="link"
    fi
    #set_slave_aging_timeout_by_adb ${ats}
    #start_slave_aging_test_by_adb

    # prepare
    init_bsp_emmc_sd
    # bsp ddr aging test
    start_timeout_error_action $mem_test_thread_num "bsp_ddr_aging_test"
    # bsp emmc sd aging test
    start_timeout_error_action $bsp_mmc_sd_thread_num "bsp_emmc_sd_aging_test && sleep 15"
    # check camera aging_test
    start_once_error_action $check_camera_thread_num "camera_aging_test"

    sleep 80

    # check kinds of components, running
    start_timeout_error_action $check_link_thread_num "aging_test_check_link"
    #####################################################################################################
    echo "I am the watcher for aging_test..."
    local elapsed=0
    ((total_watch_time = $timeout + 240))
    echo "total_watch_time: $total_watch_time"
    while [ $elapsed -lt $total_watch_time ]; do
        echo "$BASHPID waiting for aging_test..."
        #check slave if has excuted case done
        #check_slave_aging_test_state_by_adb

        if [ -f ${aging_test_finished_flag} ]; then
            echo "${aging_test_finished_flag} has been generated, slave case excute done, now exit!"
            break
        fi
        sleep 60
        ((elapsed = $elapsed + 60))
        echo "elapsed time: $elapsed"
    done
    echo "aging_test done. check result"
    #check E2 aging test result
    cal temp=`cat /blackbox/system/system.log | grep e3t_temperature_group, | tail -n 1 | busybox awk '{print $10}' | busybox awk -F, '{print $1}'`
    echo "end temp:$temp" >> $aging_test_result_file
    check_aging_test_result
    #copy E2,E1E,Pigeon test result and log file to sdcard
    #copy_result
    #pre-process log file to get the process name of tombstones files
    process_log_info
    # Make sure that led_red_on is excuted correctly
    sleep 5

    #test end
    touch ${end_of_aging_test}
}

add_date() {
    while IFS= read -r line; do
        echo "[$(date)] $line"
    done
}

aging_test_init
echo "aging_test start at $(date)" >>${check_aging_log_file}
aging_test | add_date | tee ${aging_test_log_file}
echo "aging_test finished at $(date)" >>${check_aging_log_file}
