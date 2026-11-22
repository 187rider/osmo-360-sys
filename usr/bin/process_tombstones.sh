#!/bin/sh

LOG_PATH="/blackbox/system/tombstones"
ORIGIN_TOMBSTONES_PATH="/data/tombstones"
log_max_index=7
data=""

check_and_delete()
{
    let max_tomb_counts=log_max_index+3
    let cur_tomb_counts=`ls $LOG_PATH | wc -l`
    if [ $cur_tomb_counts -gt $max_tomb_counts ]; then
        echo "detects too much dic:$cur_tomb_counts > $max_tomb_counts" > /dev/kmsg
        rm -rf $LOG_PATH
        mkdir $LOG_PATH
        chmod o+rwx $LOG_PATH
    else
        echo "check dictory okay" > /dev/kmsg
    fi
}

echo "------process tombstones from data/tombstones/ to blackbox/system/tombstones/ ------"  > /dev/kmsg
if [ -e $LOG_PATH ];then
    echo "dir data/tombstones exists"  > /dev/kmsg
    check_and_delete
    if [ -e $LOG_PATH/emmc_index ];then
        data=`cat $LOG_PATH/emmc_index` #data是上个架次的id
        echo "last emmc_index for process_tombstones= $data"  > /dev/kmsg
        if [ -z "$(ls -A "$ORIGIN_TOMBSTONES_PATH")" ]; then
            echo "$ORIGIN_TOMBSTONES_PATH is empty(last boot not generate tombs) and do nothing " > /dev/kmsg
        else
            if [ "$(ls -A "$LOG_PATH/$data")" ]; then
                echo "file already exist in the directory: $LOG_PATH/$data and delete all" > /dev/kmsg
                rm -f "$LOG_PATH/$data"/*
            fi
            mv "$ORIGIN_TOMBSTONES_PATH"/* "$LOG_PATH/$data"
            rm -f "$ORIGIN_TOMBSTONES_PATH"/*
            echo "mv file from $ORIGIN_TOMBSTONES_PATH to $LOG_PATH/$data" > /dev/kmsg
            cd $LOG_PATH/$data
            current_time=$(date +%Y%m%d_%H%M%S)
            busybox tar -zcvf "${current_time}_log.tar.gz" *
            sync
            echo "tar -zcvf log.tar.gz " > /dev/kmsg
            rm -rf *tombstone*
            echo "rm tombs *" > /dev/kmsg
            let data=$((($data+1)%$log_max_index))
            mkdir $LOG_PATH/$data
            chmod o+rwx $LOG_PATH/$data
            echo $data > $LOG_PATH/emmc_index
        fi
    else
        data=0
        mkdir $LOG_PATH/$data
        mv "$ORIGIN_TOMBSTONES_PATH"/* "$LOG_PATH/$data"
        chmod o+rwx $LOG_PATH/$data
        echo $data > $LOG_PATH/emmc_index
    fi
else
    echo "dir /blackbox/system/tombstones does not exist and create $LOG_PATH"  > /dev/kmsg
    mkdir $LOG_PATH
    chmod o+rwx $LOG_PATH
    data=0
    echo $data > $LOG_PATH/emmc_index
    mkdir $LOG_PATH/$data
    chmod o+rwx $LOG_PATH/$data
fi