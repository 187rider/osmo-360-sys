#test_type can be,aging_test,aging_test_local,link
#1 aging_test, simple version
#2 aging_test_local,full version
#3 aging_test_full_cam, cam version
#4 link, just test link
#default is simple version
test_type=1

#base folder configuration
emulated_dir=/blackbox
sd_dir=/blackbox
blackbox_dir=/blackbox

#amt,aging_test,aging_test_tmp folder
sd_amt_dir=${sd_dir}/amt
sd_amt_test_dir=${sd_amt_dir}/aging_test

data_amt_dir=/data/dji/amt
data_amt_test_dir=${data_amt_dir}/aging_test

#dji log dir
dji_log_dir=${sd_amt_dir}/log

#aging test tmp, store the log module flag
aging_test_tmp_dir=$sd_amt_dir/aging_test_tmp

#need configure them when adaper new project
#slave_name=WM260-E1E
#pigeon_name=WM260-PIGEON
master_name=qcs8550_ac204

# Directories for aging test result(eagle2 store log in the sdcard)
result_root_dir=${sd_dir}/aging_test_result
master_result_dir=${result_root_dir}/${master_name}
slave_result_dir=${result_root_dir}/${slave_name}
pigeon_result_dir=${result_root_dir}/${pigeon_name}

#Directories for other module to store the log info
# log_copy_base_dir=${master_result_dir}
log_copy_base_dir=/mnt/media_rw/sd

fc_dir=/blackbox/flyctrl
flight_dir=/blackbox/dji_flight
gimbal_dir=/blackbox/gimbal
perception_dir=/blackbox/dji_perception
dsp_manager_dir=/blackbox/ss_dsp_manager
navigation_dir=/blackbox/navigation
navigation_fc_dir=/blackbox/navigation_fc
camera_dir=/blackbox/camera
ofdm_dir=/blackbox/sdrs_log
ofdm_dump_dir=/blackbox/p1_dump_data

#system log dir
sys_log_dir=/blackbox/system
coredump_dir=/data/core
tombstone_dir=/data/tombstones

#led status file
led_status_to_update=${sd_amt_dir}/led_new_status
led_status_file=${sd_amt_dir}/led_status

##########################aging test result files#######################################
#aging test script excuted end
end_of_aging_test=${sd_amt_test_dir}/end

err_module_file=${sd_amt_test_dir}/err_module
#store test case pass or fail infos
aging_test_result_file=${sd_amt_test_dir}/result
#store master,slave,pigeon test result
all_device_test_reuslt_file=$result_root_dir/all_result

#test case finished
aging_test_finished_flag=${sd_amt_test_dir}/finished
aging_test_log_file=${sd_amt_test_dir}/log.txt
check_aging_log_file=${sys_log_dir}/check_aging.log

#led ctrl log file
led_ctrl_log_file=${dji_log_dir}/led_ctrl.log
########################################################################################

# default test timeout is 2 hours (7200s)
timeout=1800


#default check flag of test case, 1 is enable, 0 is disable
bsp_mmc_sd_thread_num=1
mem_test_thread_num=1
check_link_thread_num=1
check_camera_thread_num=1

sum_num=$(($bsp_mmc_sd_thread_num + $mem_test_thread_num + $check_link_thread_num + $check_camera_thread_num))

########################################################################################

#check emulated folder if mounted:/mnt/media_rw/emulated
check_emulated_mount() {
    if [ -d $sd_dir ]; then
        echo "$sd_dir mount point have been created"
        echo "$sd_dir mount point have been created" > /dev/kmsg
    else
        #need to detach sdcard from PC
        usb_conn=`cat /sys/class/android_usb/android0/state`
        if [ $usb_conn = "CONFIGURED" ];then
            echo "detach sd from PC"
            test_hal_storage -c "0 volume detach_pc"
        fi

        sleep 3

        if [ -d $sd_dir ]; then
            echo "$sd_dir mount point have been created"
            echo "$sd_dir mount point have been created" > /dev/kmsg
        else
            echo "failed: emulate folder(/mnt/media_rw/emulated) not mounted"
            echo "no emulate folder : FAIL, error code: 111, at $(aging_elapsed) seconds __fail" >> ${aging_test_result_file}
            led_red_on
            exit 1
        fi
    fi
}

#check sdcard if mounted
check_sdcard_mount() {
    if [ -d $sd_dir ]; then
        echo "$sd_dir mount point have been created"
        echo "$sd_dir mount point have been created" > /dev/kmsg
    else
        #need to detach sdcard from PC
        usb_conn=`cat /sys/class/android_usb/android0/state`
        if [ $usb_conn = "CONFIGURED" ];then
            echo "detach sd from PC"
            test_hal_storage -c "0 volume detach_pc"
        fi

        sleep 3

        if [ -d $sd_dir ]; then
            echo "$sd_dir mount point have been created"
            echo "$sd_dir mount point have been created" > /dev/kmsg
        else
            echo "failed: no insert sdcard"
            echo "no sdcard : FAIL, error code: 111, at $(aging_elapsed) seconds __fail" >> ${aging_test_result_file}
            led_red_on
            exit 1
        fi
    fi
}

#create aging test related folder
create_aging_test_dir() {

    if [ -d ${result_root_dir} ]; then
        rm -rf ${result_root_dir}
        sync
    fi
    # Creating directories for aging test result.
    mkdir -p ${master_result_dir}
    mkdir -p ${slave_result_dir}
    mkdir -p ${pigeon_result_dir}
    # Creating directories for aging test log
    mkdir -p ${sd_amt_test_dir}
    sync
    rm -rf $aging_test_tmp_dir
    mkdir -p $aging_test_tmp_dir
    sync
    mkdir -p ${data_amt_test_dir}
    sync
}

# configure test case
config_testcase_check_flag()
{
    if [ "$test_type"x == "1"x ]; then
        #aging_test, simple version
        bsp_mmc_sd_thread_num=1
        mem_test_thread_num=1
        check_link_thread_num=1
        check_camera_thread_num=1
    elif [ "$test_type"x == "2"x ]; then
        #aging_test_local, full version
        bsp_mmc_sd_thread_num=1
        mem_test_thread_num=1
        check_link_thread_num=1
        check_camera_thread_num=1
    elif [ "$test_type"x == "3"x ]; then
        #full cam version
        bsp_mmc_sd_thread_num=0
        mem_test_thread_num=0
        check_link_thread_num=0
        check_camera_thread_num=1
    elif [  "$test_type"x == "4"x ]; then
        #link test version
        bsp_mmc_sd_thread_num=0
        mem_test_thread_num=0
        check_link_thread_num=1
        check_camera_thread_num=0
    fi

    sum_num=$(($bsp_mmc_sd_thread_num +\
           $mem_test_thread_num +\
           $check_link_thread_num +\
           $check_camera_thread_num))

    echo "test case number sum_num: $sum_num"
}

# aging_test_timeout configure
config_test_type()
{
    if [ -f ${data_amt_dir}/state ]; then
        amt_state=`cat ${data_amt_dir}/state`
        if [ "$amt_state"x == "aging_test"x ]; then
            test_type=1
        elif [ "$amt_state"x == "aging_test_local"x ]; then
            test_type=2
        elif [ "$amt_state"x == "aging_test_full_cam"x ]; then
            test_type=3
        elif [  "$amt_state"x == "link"x ]; then
            test_type=4
        else
            test_type=1
        fi
        rm ${data_amt_dir}/state
        sync
    fi
    echo "aging_test test_type: $test_type"
}

# aging_test_timeout configure
config_timeout()
{
    if [ -s ${data_amt_dir}/aging_test_timeout ]; then
        time=`cat ${data_amt_dir}/aging_test_timeout`
        if [ $time == 0 ];then
            echo "timeout value should not as 0"
        else
            timeout=$time
        fi
        rm ${data_amt_dir}/aging_test_timeout
    fi
    echo "aging_test timeout: $timeout"
}
