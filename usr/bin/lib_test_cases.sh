. lib_test_utils.sh

fail_cnt=$sd_amt_test_dir/fail_cnt
success_cnt=$sd_amt_test_dir/success_cnt
link_err_record_file=${sd_amt_test_dir}/link_err_record

need_copy_log_dir=$aging_test_tmp_dir

fail_postfix=fail_result__
success_postfix=success_result__
need_to_copy_gimbal_log=$aging_test_tmp_dir/need_to_copy_gimbal_log
need_to_copy_flyctl_log=$aging_test_tmp_dir/need_to_copy_flyctl_log
need_to_copy_perception_log=$aging_test_tmp_dir/need_to_copy_perception_log
need_to_copy_navigation_log=$aging_test_tmp_dir/need_to_copy_navigation_log
need_to_copy_pigeon_log=$aging_test_tmp_dir/need_to_copy_pigeon_log
need_to_copy_camera_log=$aging_test_tmp_dir/need_to_copy_camera_log
need_to_copy_slave_log=$aging_test_tmp_dir/need_to_copy_slave_log
need_to_copy_system_log=$aging_test_tmp_dir/need_to_copy_system_log

tmp_counter=0

add_date()
{
    while IFS= read -r line; do
        echo "[$(date)] $line"
    done
}

## log type: flyctrl gimbal ofdm system perception navigation camera
set_log_copy_flag()
{
    local test_name=$1
    local module_name=$2
    echo "test_name=$test_name module_name=$module_name"
    local need_to_copy_log=$need_copy_log_dir/need_to_copy_${test_name}_${module_name}_log
    echo "set_log_copy_flag: touch $need_to_copy_log"
    touch $need_to_copy_log
    sync
    return 0
}

clear_log_copy_flag()
{
    local test_name=$1
    local module_name=$2
    local need_to_copy_log=$need_copy_log_dir/need_to_copy_${test_name}_${module_name}_log
    rm -rf $need_to_copy_log
    return 0
}

get_log_copy_flag()
{
    local test_name=$1
    local module_name=$2
    #echo "test_name=$test_name module_name=$module_name"
    local need_to_copy_log=$need_copy_log_dir/need_to_copy_${test_name}_${module_name}_log
    #echo "get_log_copy_flag: judge $need_to_copy_log is exist or not"
    if [ ! -f $need_to_copy_log ]; then
        return 0
    else
        return 1
    fi
}

# link path test cases
#
linked_to_e1e()
{
    test_connect_e1e.sh
}

linked_to_pigeon_mipi()
{
    mipi_link_test_e2_p1.sh
}

linked_to_ssd()
{
    test_connect_ssd.sh
}

linked_to_sdcard()
{
    test_sdcard_link.sh
}

linked_to_e1e_uart()
{
    test_uart_e1e_to_e2.sh
}

linked_to_pigeon_uart()
{
    test_v1_between_p1_e2.sh
}

linked_to_camera()
{
    cmd_check_ver camera 1 0
}

linked_to_gimbal()
{
    cmd_check_ver gimbal 4 0
}

linked_to_pigeon()
{
    cmd_check_ver pigeon 9 0
}

sys_temp_check()
{
    test_read_e2_temp.sh
}

init_bsp_emmc_sd()
{
    local amt=/data/dji/amt
    #eMMC
    if [ ! -f $amt/sample.data ]; then
        dd if=/dev/urandom of=$amt/sample.data bs=1024 count=1024 >> ${aging_test_log_file} 2>&1
        sync
    fi
    if [ ! -f $amt/sample.data ]; then
        echo "init_bsp_emmc __fail"
        return 1
    fi
    echo "init_bsp_emmc ok"
    return 0
}

bsp_emmc_sd_aging_test()
{
    echo "BSP eMMC Aging Test Start"
    local amt=/data/dji/amt
    local dir=$amt/aging_test

    rm -f $dir/eMMC.data
    sync
    cp -f $amt/sample.data $dir/eMMC.data
    sync
    local result=`busybox cmp $amt/sample.data $dir/eMMC.data`
    ret=$?
    if [ $ret -ne 0 ]; then
        echo "emmc $ret __fail ..."
        set_log_copy_flag bsp_emmc_sd_aging_test system
        return 2
    fi
    echo "emmc pass"

    return 0
}

bsp_ssd_aging_test()
{
    echo "ssd aging test Start"
    ssd_burnin.sh /dev/block/nvme0n1 NVME 600 16 1 1
    ret=$?
    if [ $ret -ne 0 ]; then
        echo "bsp_ssd_aging_test __fail ..."
        return 1
    fi
    echo "ssd aging test pass"
}

function record_link_err()
{
    if [ ! -f ${link_err_record_file} ]; then
        echo "link err record file doesn't exist!"
        return 1
    fi
    echo $* >> ${link_err_record_file}
}

aging_test_check_link()
{
    sleep 5
    echo aging test check link begin...
    a=0
    b=0
    c=0
    d=0
    e=0
    f=0
    g=0
    h=0
    i=0
    j=0
    k=0
    l=0
    m=0
    n=0
    o=0

    #sys_temp_check
    #ret=$?
    #if [ $ret -ne 0 ]; then
    #    echo "sys_temp_check __fail ..."
    #    echo
    #    record_link_err "check temperature failed"
    #    echo "system" >> $err_module_file
    #    a=1
    #fi

    sleep 20

    echo aging test check link ends...

    u=$a$b$c$d$e$f$g$h$i$j$k$l$m$n$o
    if [ 0x${u} != "0x000000000000000" ]; then
        echo "serialize: aging test __fail result: $u"
        echo
        echo
        return 1
    fi
    return 0
}

perception_aging_test()
{
    sleep 10
    check_vp_log.sh
    ret=$?
    if [ $ret -ne 0 ]; then
        echo "perception test: `get_perception_fail_reason $ret` __fail..."
        set_log_copy_flag perception_aging_test perception
        return $ret
    fi

    return 0
}

navigation_aging_test()
{
    sleep 10
    nav_log_check.sh
    ret=$?
    if [ $ret -ne 0 ]; then
        echo "navigation test: `get_navigation_fail_reason $ret`__fail..."
        set_log_copy_flag navigation_aging_test navigation
        return $ret
    fi

    return 0
}

camera_aging_test()
{
    sleep 10
    dji_oq101_camera_aging_test.sh
    ret=$?
    if [ $ret -ne 0 ]; then
        echo "camera aging test return:$ret __fail ..."
        set_log_copy_flag camera_aging_test camera
        return $ret
    fi

    return 0
}

codec_aging_test()
{
    dji_codec_aging.sh
    ret=$?
    if [ $ret -ne 0 ]; then
        echo "codec test: `get_codec_fail_reason $ret` __fail..."
        return $ret
    fi

    return 0
}

bsp_ddr_aging_test()
{
    test_mem -s 0x200000 -l 1 || {
        ret=$?
        echo "test_mem __fail ..."
        set_log_copy_flag bsp_ddr_aging_test system
        return $ret
    }
    sleep 10
}

max_sys_pid=0
SYS_PROCS="dji_sys dji_blackbox dji_audio dji_wireless_mic dji_asr dji_amt dji_sw_uav"

bsp_get_max_pid()
{
    echo "bsp_get_max_pid 1"
    # setup for max_proc_pid
    for c in $SYS_PROCS
    do
        r=`pidof $c`
        if [ $? -ne 0 ]; then
            echo "bsp_get_max_pid of $c __fail"
            ps | grep dji
            return 1
        fi
        if [ $r -ge $max_sys_pid ]; then
            ((max_sys_pid=$r))
            echo "bsp_get_max_pid of $c is $r, update max_sys_pid=$max_sys_pid"
        fi
    done
}

bsp_monnitor_aging_test()
{
    local cycle_duration=60
    local r

    sleep $cycle_duration
    for c in $SYS_PROCS
    do
        r=`pidof $c`
        if [ $? -ne 0 ]; then
            echo "check_sys_pid of $c __fail"
            ps | grep dji
            return 1
        fi
        if [ $r -gt $max_sys_pid ]; then
            echo "check_sys_pid of $c is $r, max_sys_pid=$max_sys_pid __fail"
            ps | grep dji
            return 2
        fi
        echo "check_sys_pid of $c is $r"
    done
    echo "check_sys_pid ok"
    return 0
}

check_aging_test_result_log()
{
    local log_file=$1
    local result_file=$2

    echo "check_aging_test_result_log $* at `date`"
    if [ -f $result_file -o -f $log_file ]; then
        return 1
        echo "Found old aging test result or log file, no more"
    fi
    return 0
}

# Actually there is no need to run this funciton again,
# set_slave_aging_timeout_by_adb has already written /data/dji/amt/state
start_slave_aging_test_by_adb() {
    echo "starting slave aging test by adb"
}

set_slave_aging_timeout_by_adb() {
    let timeslave=timeout-300
    echo "setting slave aging timeout: $timeslave"
    # adb shell "command" puts ^M(\r\n) at the end of command, the parameter "beef" is added
    # to be omitted.

    adb -s $slave_name shell "set_aging_test_start_flag.sh $1 ${timeslave} beef"
    if [ $? != 0 ]; then
        touch $need_to_copy_slave_log
        echo "setting slave aging timeout __fail."
        return 1
    else
        echo "setting slave aging timeout ok."
    fi
}

check_slave_aging_test_state_by_adb() {
    sleep 1
    local ret=`adb -s $slave_name shell ls ${data_amt_test_dir} | grep "end"`
    echo  "check_slave_aging_test_state_by_adb ret====="$ret
    if [ "$ret"x != x ]; then
        echo  "check_slave_aging_test_state_by_adb return 0 ret====="$ret
        return 0
    else
        echo  "check_slave_aging_test_state_by_adb return 1 ret====="$ret
        return 1
    fi
}

function set_pigeon_aging_timeout_by_adb()
{
    let pigeon_aging_timeout=timeout-300
    echo "setting pigeon aging timeout: ${pigeon_aging_timeout}"
    # It's not a reliable way to write to a file in ram file system of pigeon
    adb -s ${pigeon_name} shell "setprop pigeon_aging_test_timeout ${pigeon_aging_timeout} "
    if [ $? -ne 0 ]; then
        echo "set pigeon aging test timeout __fail."
        return 2
    fi
}

function start_pigeon_aging_test_by_adb()
{
    echo "starting pigeon aging test by adb"
    # It's not a reliable way to write to a file in ram file system of pigeon
    adb -s ${pigeon_name} shell "setprop start_pigeon_aging_test 1"
    if [ $? -ne 0 ]; then
        echo "start pigeon aging test by adb __fail."
        return 1
    fi
}

readonly success_suffix=success_result__
readonly fail_suffix=fail_result__
function check_pigeon_aging_test_state_by_adb()
{
    echo "checking pigeon aging test state by adb"
    local pigeon_success_cnt=$(adb -s ${pigeon_name} shell "ls ${aging_test_tmp_dir} | grep -c ${success_suffix}")
    local pigeon_fail_cnt=$(adb -s ${pigeon_name} shell "ls ${aging_test_tmp_dir} | grep -c ${fail_suffix}")
    echo ${pigeon_success_cnt} > ${sd_amt_test_dir}/pigeon_success_cnt
    echo ${pigeon_fail_cnt} > ${sd_amt_test_dir}/pigeon_fail_cnt
    if [ ${pigeon_fail_cnt} -gt 0 ]; then
        echo "there is something wrong with pigoen aging test"
        touch ${need_to_copy_pigeon_log}
        return 1
    fi
}

bsp_ddr_aging_test() {
    test_mem -s 0x200000 -l 1 || {
        ret=$?
        echo "test_mem __fail ..."
        return $ret
    }
    sleep 10
}

empty_aging_test() {
    sleep 60
    return 0
}
