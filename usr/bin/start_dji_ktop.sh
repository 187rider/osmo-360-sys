#!/bin/sh

LOG_PATH="/blackbox/system/sys_perf"
log_max_index=8
data=""

check_and_delete()
{
    let max_perf_counts=log_max_index+3
    let cur_perf_counts=`ls $LOG_PATH | wc -l`
    if [ $cur_perf_counts -gt $max_perf_counts ]; then
        echo "sys_perf_monitor detects too much dic:$cur_perf_counts > $max_perf_counts" > /dev/kmsg
        rm -rf $LOG_PATH
        mkdir $LOG_PATH
        chmod o+rwx $LOG_PATH
    else
        echo "sys_perf_monitor check dictory okay" > /dev/kmsg
    fi
}

keepN()
{
    files=`ls $2 | grep "^ktop.log.[0-9]*" | busybox sort -n -t '.' -k3 -r`
    idx=0
    for i in $files
    do
        if [ "$idx" -ge "$1" ];then
            rm $2"/"$i
        fi
        let idx+=1
    done
    files=`ls $2 | grep "^ktop.log.[0-9]*$" | busybox sort -n -t '.' -k3 -r`
    idx=0
    for i in $files
    do
        if [ "$idx" -ge "3" ];then
            busybox nice -n 19 busybox tar -czvf $2"/"$i".tar.gz" -C $2 $i
            rm $2"/"$i
            sleep 5
        fi
        let idx+=1
    done
}

sys_perf_exit()
{
    echo "dji_sys_perf_exit" > /dev/kmsg
    echo 0 > /sys/kernel/debug/cpumon/ktop_enable
    exit 0
}

if [ -e $LOG_PATH ];then
    check_and_delete
	if [ -e $LOG_PATH/emmc_index ];then
		data=`cat $LOG_PATH/emmc_index`
		let old_data=$((($data+0)%$log_max_index))
		cur_dir='pwd'
		cd $LOG_PATH/$old_data
		busybox tar -zcvf log.tar.gz *
		sync
		in_correct=$(pwd | grep "/blackbox/system/sys_perf" | wc -l)
		if [ $in_correct -ne 0 ]; then
			find . -maxdepth 1 ! -name "log.tar.gz" -exec rm -rf {} \;
		else
			rm -rf *.log
		fi
		cd $cur_dir
		let data=$((($data+1)%$log_max_index))
		rm -rf $LOG_PATH/$data 2>/dev/null
		mkdir $LOG_PATH/$data
        chmod o+rwx $LOG_PATH/$data
		echo $data > $LOG_PATH/emmc_index
    else
		data=0
		mkdir $LOG_PATH/$data
        chmod o+rwx $LOG_PATH/$data
		echo $data > $LOG_PATH/emmc_index
	fi
else
    mkdir -p $LOG_PATH
    chmod o+rwx $LOG_PATH
    data=0
    echo $data > $LOG_PATH/emmc_index
    mkdir $LOG_PATH/$data
    chmod o+rwx $LOG_PATH/$data
fi

echo "------record perf info start------"  > /dev/kmsg
trap sys_perf_exit SIGTERM

if [ -e /sys/kernel/debug/cpumon/ktop_enable ]; then
    echo "enable ktop tracing" > /dev/kmsg
    echo "interval_ms 500" > /sys/kernel/debug/cpumon/ktop_control
    echo "path $LOG_PATH/$data/ktop.log" > /sys/kernel/debug/cpumon/ktop_control
    echo "log_size_mb 10" > /sys/kernel/debug/cpumon/ktop_control
    echo 1 > /sys/kernel/debug/cpumon/ktop_enable
fi

root_path=$LOG_PATH/$data/info
if [ ! -e $root_path ]; then
    echo "root_path $root_path is not exist, create it"  > /dev/kmsg
    mkdir -p $root_path
    chmod o+rwx $root_path
fi

sleep 3
cat /proc/interrupts > $root_path/interrupt.info
usleep 400000
ps -AT > $root_path/process64.info
echo "qcom_qcs8550_oq101" > $root_path/product.info
if [ -e "/sys/kernel/debug/testcase/kaslr-offset" ]; then
    cat /sys/kernel/debug/testcase/kaslr-offset > $root_path/kaslr.info
fi
cp /blackbox/system/ver_info.txt $root_path/version.info
sync

if [ -e "/usr/bin/light_perf" ]; then
    light_perf /system/etc/light_perf.conf $LOG_PATH/$data/light_flame/ &
else
    echo "/usr/bin/light_perf not exist, so disable light_perf" >> /dev/kmsg
fi

while true
do
    sleep 60
    keepN 10 $LOG_PATH/$data
done
