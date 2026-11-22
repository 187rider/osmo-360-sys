#!/bin/sh

##统一日志清除目录
log_clear_base_dir=/data/unified_log_clear
##统一日志清除标记目录
log_clear_flag_dir="$log_clear_base_dir/log_clear_flag"
##统一日志清除结果记录目录
log_clear_result_dir="$log_clear_base_dir/log_clear_result"
##统一日志清除日志记录
log_clear_process_file="$log_clear_base_dir/log_clear_process"
##统一日志清除日志全局日志目录
log_clear_record_dir=/blackbox/system
##统一日志清除日志全局日志
log_clear_record_file="$log_clear_record_dir/unified_log_clear.txt"
##统一日志清除分区存在检查重试次数
check_partition_exist_max_retry_count=5

##统一日志清除配置目录
log_clear_cfg_dir=/system/etc
##统一日志清除日志分割线
split_line="==========================================================="
##统一日志清除默认的媒体分区路径
default_media_path="/mnt/media_rw/emulated"

##统一日志清除KEY
key_of_product="product"
key_of_soc="soc"
key_of_process_record_file="log_clear_process_record_file"
key_of_result_record_file="log_clear_result_record_file"
key_of_need_clear_time="need_clear_time"
key_of_clear_partition_list="clear_partition_list"
key_suffix_of_partition_blacklist="_blacklist"
key_suffix_of_partition_only_clear_blacklist="_only_clear_blacklist"
key_suffix_of_partition_whitelist="_whitelist"
key_suffix_of_partition_free_size_check="_free_size_check"
key_of_need_clear_media="need_clear_media"
key_of_need_manual_mount_and_clear_sd="need_manual_mount_and_clear_sd"
key_of_special_media_partition_path="special_media_partition_path"
key_of_clear_internal_storage_list="clear_internal_storage_list"

##统一日志清除日志输出(日志)
myecho_without_time()
{
    #打印日志到前台 和 日志记录文件
    echo "$*" | tee -a $log_clear_process_file
}

##统一日志清除日志输出(时间戳+日志)
myecho()
{
    #打印日志到前台 和 日志记录文件
    echo "[$(date)] $*" | tee -a $log_clear_process_file
}

##统一日志清除日志输出到kmsg
kmsg_echo()
{
    echo "$*" > /dev/kmsg
}

##统一日志清除日志输出到kmsg和日志文件
kmsg_and_myecho()
{
    kmsg_echo $*
    myecho $*
}

##清理统一日志清除标记(先清空，再删除)
clear_unified_log_clear_flag()
{
    mode=$1
    log_clear_flag="$log_clear_flag_dir/$mode"
    #清空日志清除标记
    echo > $log_clear_flag
    #删除日志清除标记
    rm -rf $log_clear_flag
    #重试一次
    if [ -e $log_clear_flag ]; then
        rm -rf $log_clear_flag
    fi
    myecho "clear $log_clear_flag"
}

##统一日志清除某一模式退出，记录退出结果后，退出该模式循环
myexit_mode()
{
    exit_code=$result_code
    log_clear_mode=$1
    #输出到日志文件
    myecho "unified log clear exit: $exit_code from mode: $log_clear_mode"
    #输出到结果文件
    mkdir -p $log_clear_result_dir
    log_clear_result_file="${log_clear_result_dir}/${log_clear_mode}"
    echo "result=$exit_code" > $log_clear_result_file
    #reason 输出
    if [ $exit_code -ne 0 ];then
        myecho "unified log clear error reason: $reason"
        echo "reason=$reason" >> $log_clear_result_file
    else
        myecho "unified log clear for $log_clear_mode _success_"
    fi

    #日志文件拷贝
    if [ "$log_clear_process_record_file"x != ""x ]; then
        check_and_make_record_path_dir $log_clear_process_record_file
        cp_with_error_retry $log_clear_process_file $log_clear_process_record_file
    fi
    #结果文件拷贝
    if [ "$log_clear_result_record_file"x != ""x ]; then
        check_and_make_record_path_dir $log_clear_result_record_file
        cp_with_error_retry $log_clear_result_file $log_clear_result_record_file
    fi
    #全局日志记录
    myecho $split_line
    check_and_make_record_path_dir $log_clear_record_file
    cat $log_clear_process_file >> $log_clear_record_file
    myecho "cat $log_clear_process_file >> $log_clear_record_file over"
    #清除掉日志清除标志文件
    clear_unified_log_clear_flag $log_clear_mode
}

##统一日志清除，清除分区下所有文件
##data分区不能删除unified_log_clear
clear_partition_all()
{
    partition=$1

    if [ "$partition" == "data" ]; then
        partition_file_list=`ls /$partition -a -1`
        for path in $partition_file_list; do
            if [ "$path" == "." ] || [ "$path" == ".." ] || [ "$path" == "unified_log_clear" ]; then
                continue
            fi
            clear_cmd="rm -rf /$partition/$path"
            eval $clear_cmd
            myecho "run clear_cmd: $clear_cmd"
        done
    else
        myecho "clear partition all by : rm -rf /$partition/*"
        rm -rf /$partition/*
    fi
}

##统一日志清除，清除分区黑名单
#限制只能删这个分区的, data分区不能删除 data/unified_log_clear
clear_partition_by_blacklist()
{
    partition=$1
    path=$2

    if [[ "$path" != /$partition/* ]]; then
        myecho "$path is not in $partition, do not clear it."
        return 1
    fi

    if [ "$partition" == "data" ]; then
        if [ -e $path ] && [[ "$path" != /data/unified_log_clear* ]]; then
            rm -rf $path
            myecho "rm -rf $path"
        fi
    else
        if [ -e $path ]; then
            rm -rf $path
            myecho "rm -rf $path"
        fi
    fi
}

clear_partition_by_whitelist()
{
    partition=$1

    #获取分区白名单(暂只支持分区一级目录）
    key_of_partition_whitelist="${partition}${key_suffix_of_partition_whitelist}"
    check_json_key_exist_and_type $log_clear_mode_cfg $key_of_partition_whitelist "array"
    if [ $? -eq 0 ]; then
        partition_whitelist=`jshon -F $log_clear_mode_cfg -e $key_of_partition_whitelist -a -u`
        if [ "$partition_whitelist"x != ""x ]; then
            #清除白名单之外的文件
            myecho "partition whitelist:"
            myecho_without_time "$partition_whitelist"
            partition_file_list=`ls /$partition -a -1`

            for path in $partition_file_list; do
                need_clear="true"
                if [ "$path" == "." ] || [ "$path" == ".." ]; then
                    continue
                fi
                if [ "$partition" == "data" ] && [ "$path" == "unified_log_clear" ]; then
                    continue
                fi

                for whitepath in $partition_whitelist; do
                    if [ "$path" == "$whitepath" ]; then
                        need_clear="false"
                        break
                    fi
                done

                if [ "$need_clear" == "true" ]; then
                    clear_cmd="rm -rf /$partition/$path"
                    eval $clear_cmd
                    myecho "run clear_cmd: $clear_cmd"
                fi
            done
        else
            clear_partition_all $partition
        fi
    else
        clear_partition_all $partition
    fi
}

##统一日志清除，清除分区日志
#限制能删除的分区
clear_partition()
{
    partition=$1
    if [ "$partition"x == ""x ]; then
        myecho "clear partition is empty"
        add_error_to_reason "clear partition is empty"
        return 1
    fi

    if [ "$partition" == "system" ] || [ "$partition" == "vendor" ] || [ "$partition" == "dev" ] || [ "$partition" == "/" ]; then
        myecho "clear partition: $partition is illegal"
        add_error_to_reason "clear $partition is illegal"
        return 1
    fi

    #检查分区是否存在
    for i in $(seq 0 $check_partition_exist_max_retry_count); do
        if [ $i -eq $check_partition_exist_max_retry_count ]; then
            myecho "partition:$partition is not exist, has retry $i times, error!"
            add_error_to_reason "partition:$partition is not exist"
            return 1
        fi

        myecho "check partition:$partition exist by df"
        busybox df /$partition
        if [ $? -eq 0 ]; then
            myecho "partition:$partition is exist by df check"
            break
        else
            myecho "partition: $partition is not exist by df check, sleep 1 s and retry:$i"
            df | tee -a $log_clear_process_file
            sleep 1
        fi
    done

    myecho "start clear partition: $partition"
    #先获取分区黑名单(一个array)，有内容就依个删除
    key_of_partition_blacklist="${partition}${key_suffix_of_partition_blacklist}"
    check_json_key_exist_and_type $log_clear_mode_cfg $key_of_partition_blacklist "array"
    if [ $? -eq 0 ]; then
        partition_blacklist=`jshon -F $log_clear_mode_cfg -e $key_of_partition_blacklist -a -u`
        if [ "$partition_blacklist"x != ""x ]; then
            #获取黑名单里每个文件
            myecho "clear partition by blacklist:"
            myecho_without_time "$partition_blacklist"
            for path in $partition_blacklist; do
                clear_partition_by_blacklist $partition $path
            done
        fi
    fi
    #获取分区只清黑名单标志是否置1
    key_of_partition_only_clear_blacklist="${partition}${key_suffix_of_partition_only_clear_blacklist}"
    partition_only_clear_blacklist=`jshon -F $log_clear_mode_cfg -e $key_of_partition_only_clear_blacklist -u`
    if [ "$partition_only_clear_blacklist"x != "true"x ]; then
        clear_partition_by_whitelist $partition
    else
        myecho "$key_of_partition_only_clear_blacklist is set true, only clear partion:$partition by blacklist!"
    fi

    #获取分区free-size检查标志
    key_of_partition_free_size_check="${partition}${key_suffix_of_partition_free_size_check}"
    check_json_key_exist_and_type $log_clear_mode_cfg $key_of_partition_free_size_check "number"
    if [ $? -eq 0 ]; then
        partition_free_size_check=`jshon -F $log_clear_mode_cfg -e $key_of_partition_free_size_check -u`
        if [ $partition_free_size_check -gt 0 ]; then
            check_free_size_mb /$partition $partition_free_size_check
        else
            myecho "$key_of_partition_free_size_check is $partition_free_size_check, it is illegal!"
        fi
    fi
    sync

    ls_path $partition
    return 0
}

##统一日志清除，检查分区的空闲大小(单位：MB)
check_free_size_mb()
{
    target_path=$1
    limit_free_size=$2
    real_free_size=`busybox df -Pm $target_path|tail -n 1|busybox awk '{ print $4 }'`
    if [ -z "$real_free_size" ] || [ $real_free_size -lt $limit_free_size ]; then
        myecho "check $target_path, free $real_free_size MB < limit_free_size $limit_free_size MB, its not okay!"
        myecho "check_free_size_mb _fail_ !"
        add_error_to_reason "$target_path check_free_size fail"
        check_partition_mem $target_path
        return 1
    else
        myecho "check $target_path, free $real_free_size MB > limit_free $limit_free_size MB, its okay"
        return 0
    fi
}

rm_internal_storage_path()
{
    internal_storage_path=$1

    rm -rf $internal_storage_path/*
    myecho "clear internal_storage all by : rm -rf $internal_storage_path/*"
    sync
    ls_path $internal_storage_path
}

##统一日志清除，清除内置存储
clear_internal_storage()
{
    internal_storage=$1
    real_path=`realpath $internal_storage`
    if [[ "$real_path" != /mnt/* ]]; then
        myecho "clear internal_storage: $internal_storage is illegal"
        add_error_to_reason "internal_storage: $internal_storage is illegal"
        return 1
    fi
    #检查内置存储路径是否已挂载
    if [ -e $internal_storage ]; then
        rm_internal_storage_path $internal_storage
        return 0
    fi

    myecho "mkdir $internal_storage， start vold and sleep 3s"
    #创建挂载目录
    mkdir -p $internal_storage
    #启动vold
    start vold
    sleep 3
    #输出df信息
    df | tee -a $log_clear_process_file

    #再次尝试detach
    detach_pc_and_wait 2
    #检查内置存储路径是否已挂载
    df | grep $internal_storage
    if [ $? -eq 0 ]; then
        rm_internal_storage_path $internal_storage
        return 0
    fi

    #报错退出
    myecho "internal_storage: $internal_storage can not found, clear error"
    add_error_to_reason "internal_storage:$internal_storage not found"
    return 1
}

##统一日志清除，mount media分区
mount_media()
{
    cfg_path="/data/dji/cfg"
    cfg_file="/data/dji/cfg/media_created"

    #创建挂载目录
    mkdir -p $media_path
    #启动vold
    start vold
    sleep 3
    myecho "mkdir $media_path, start vold and sleep 3s"
    #输出df信息
    df | tee -a $log_clear_process_file

    #判断media是否已创建
    if [ ! -f "$cfg_file" ];then
        check_and_format.sh /dev/block/by-name/media exfat InternalStorage
        test_hal_storage -c "0 volume mount emulated"
        if [ ! -d "$cfg_path" ];then
            mkdir -p "$cfg_path"
        fi
        touch "$cfg_file"
        myecho "mount media"
    else
        myecho "$cfg_file exist do not need format and mount media again"
    fi
}

rm_media_path()
{
    media_path=$1

    rm -rf $media_path/*
    myecho "clear media all by : rm -rf $media_path/*"
    sync
    ls_path $media_path
}

##统一日志清除，清除media分区
clear_media()
{
    if [ -e $media_path ]; then
        rm_media_path $media_path
        return 0
    fi

    ##尝试进行detach
    detach_pc_and_wait 2
    if [ -e $media_path ]; then
        rm_media_path $media_path
        return 0
    fi

    #可能由于快速启动media还没有mount，需要手动mount起来
    mount_media
    df | grep $media_path
    if [ $? -eq 0 ]; then
        rm_media_path $media_path
        return 0
    fi

    ##再次尝试进行detach，防止一mount上来又挂到PC去了 （这部分后续要有底软保证不会detach)
    detach_pc_and_wait 2
    df | grep $media_path
    if [ $? -eq 0 ]; then
        rm_media_path $media_path
        return 0
    fi

    myecho "media_path:$media_path not found, clear error"
    add_error_to_reason "media_path:$media_path not found"
    return 1
}

##统一日志清除，卸载挂到PC上的设备，并等待指定时间，查看df
detach_pc_and_wait()
{
    wait_time=$1

    test_hal_storage -c '0 volume detach_pc'
    myecho "do detach by: test_hal_storage -c '0 volume detach_pc'"
    sleep $1
    df=`busybox df`
    myecho "df:"
    myecho_without_time "$df"
}

##统一日志清除，添加错误原因
add_error_to_reason()
{
    error=$1

    let result_code++
    if [ "$reason"x == ""x ]; then
        reason="${error}"
    else
        reason="${reason},${error}"
    fi
}

check_and_make_record_path_dir()
{
    path=$1

    path_dir=`dirname $path`
    if [ ! -e $path_dir ]; then
        mkdir -p $path_dir
        if [ $? -ne 0 ]; then
            myecho "mkdir -p $path_dir error!"
            add_error_to_reason "record_file dir create error."
            return 1
        fi
        myecho "mkdir -p $path_dir"
    fi

    return 0
}

check_record_path()
{
    path=$1
    if [[ "$path" != /blackbox/* ]] && [[ "$path" != /data/* ]]; then
        myecho "record path: $record_path is illegal!"
        add_error_to_reason "record_file is illegal."
        return 1
    fi

    check_and_make_record_path_dir $path
    if [ $? -ne 0 ]; then
        return 1
    fi

    return 0
}

check_json_key_exist_and_type()
{
    json_file=$1
    key=$2
    value_type=$3

    check_type=`jshon -F $json_file -e $key -t`
    if [ $? -ne 0 ]; then
        myecho "the key $key is not set!"
        return 1
    elif [ "$check_type"x != "$value_type"x ]; then
        myecho "the $key type is not $value_type!"
        add_error_to_reason "$key is not $value_type"
        return 1
    elif [ "$check_type"x == "array"x ]; then
        jshon -F $json_file -e $key -a -u
        if [ $? -ne 0 ]; then
            myecho "the array $key content is complex!"
            add_error_to_reason "the array $key is complex"
            return 1
        fi
    else
        return 0
    fi
}

ls_path()
{
    path=$1

    myecho "ls $path"
    ls -all /$path | tee -a $log_clear_process_file
}

cp_with_error_retry()
{
    path=$1
    dst_path=$2
    retry_times=5

    for i in $(seq 0 $retry_times); do
        if [ $i -eq $retry_times ]; then
            myecho "cp $path $dst_path error."
            return 1
        fi

        myecho "cp $path $dst_path"
        cp $path $dst_path
        result=$?
        if [ $result -ne 0 ]; then
            myecho "cp $path $dst_path error:$result."
            sleep 1
            continue
        fi

        if [ ! -e $dst_path ]; then
            myecho "$dst_path is not exist, something wrong."
            sleep 1
            continue
        else
            myecho "cp $path $dst_path OK."
            return 0
        fi
    done
}

check_partition_mem()
{
    path=$1

    myecho "df -h | grep $path"
    df -h | grep $path | tee -a $log_clear_process_file

    myecho "du -h -d 1 $path"
    du -h -d 1 $path | tee -a $log_clear_process_file
}

manual_mount_and_clear_sd()
{
    #设置sd卡的手动挂载点
    manual_mount_path="/mnt/media_rw/manual_mount"
    myecho "mkdir -p $manual_mount_path"
    mkdir -p $manual_mount_path

    #手动挂载SD挂载
    myecho "mount $default_sd_path $manual_mount_path"
    mount $default_sd_path $manual_mount_path | tee -a $log_clear_process_file

    df | tee -a $log_clear_process_file

    df | grep $manual_mount_path
    if [ $? -eq 0 ]; then
        myecho "mount $default_sd_path $manual_mount_path SUCCESS"
        #清除日志
        myecho "rm -rf $manual_mount_path/* and df:"
        rm -rf $manual_mount_path/*
        df | tee -a $log_clear_process_file
        #卸载SD卡手动挂载路径
        myecho "umount $manual_mount_path and df:"
        umount $manual_mount_path
        df | tee -a $log_clear_process_file
    else
        myecho "mount $default_sd_path $manual_mount_path error"
        add_error_to_reason "mount $default_sd_path $manual_mount_path error"
    fi

    rm -rf $manual_mount_path
}
#####################################################################################

##统一日志清除脚本主流程
#1.检查清除标志文件是否存在
if [ ! -d $log_clear_flag_dir ]; then
    kmsg_echo "No unified log clear flag exist, do not need to run unified log clear!"
    exit 0
fi

#3.获取所有的清除标志
flag_num=`busybox ls $log_clear_flag_dir | wc -l`
if [ ! $flag_num -gt 0 ];then
    myecho "there is no log_clear_flag!"
    myecho "unified_log_clear.sh over!"
    exit 0
else
    myecho "there is $flag_num log_clear_flag need to handle!"
fi

log_clear_flag_list=`busybox ls $log_clear_flag_dir`
for log_clear_flag in $log_clear_flag_list; do
    ##统一日志清除相关变量初始化
    log_clear_process_record_file=""
    log_clear_result_record_file=""
    reason=""
    result_code=0
    ##清理统一日志清除的临时日志文件
    rm -rf $log_clear_process_file
    myecho $split_line
    ##判断模式的有效性
    log_clear_mode=$log_clear_flag
    if [ "$log_clear_mode"x == "factory"x ]; then
        kmsg_and_myecho "unified log clear in mode: factory"
    elif [ "$log_clear_mode"x == "user"x ]; then
        kmsg_and_myecho "unified log clear in mode: user"
    else
        kmsg_and_myecho "get invalid param: $log_clear_mode for unified log clear"
        add_error_to_reason "mode is invalid"
        myexit_mode $log_clear_mode
        continue
    fi

    log_clear_flag_path="${log_clear_flag_dir}/${log_clear_mode}"
    if [ ! -s $log_clear_flag_path ]; then
        kmsg_and_myecho "$log_clear_flag_path is empty, unified log clear exit!"
        add_error_to_reason "log_clear_flag is empty"
        myexit_mode $log_clear_mode
        continue
    fi
    log_clear_flag_content=`cat ${log_clear_flag_path}`
    myecho "get log_clear_flag_content:"
    myecho_without_time "$log_clear_flag_content"

    #获取对应清除模式的配置文件（json格式存储）
    log_clear_mode_cfg="${log_clear_cfg_dir}/${log_clear_mode}_log_clear_cfg.json"
    if [ ! -f $log_clear_mode_cfg ]; then
        kmsg_and_myecho "$log_clear_mode_cfg not exist, unified log clear exit!"
        add_error_to_reason "mode cfg is not exist"
        myexit_mode $log_clear_mode
        continue
    fi
    if [ ! -s $log_clear_mode_cfg ]; then
        kmsg_and_myecho "$log_clear_mode_cfg is empty, unified log clear exit!"
        add_error_to_reason "mode cfg is empty"
        myexit_mode $log_clear_mode
        continue
    fi
    #检查文件格式是否为json
    jshon -F $log_clear_mode_cfg
    if [ $? -ne 0 ]; then
        kmsg_and_myecho "$log_clear_mode_cfg format is not json, unified log clear exit!"
        add_error_to_reason "mode cfg is not json"
        myexit_mode $log_clear_mode
        continue
    fi

    kmsg_and_myecho "load $log_clear_mode_cfg, start log clear!"

    #获取对应的产品信息(非必需)
    product=`jshon -F $log_clear_mode_cfg -e $key_of_product -u`
    if [ "$product"x == ""x ]; then
        myecho "$key_of_product is not set."
    else
        myecho "$key_of_product is $product!"
    fi

    #获取对应的芯片信息(非必需)
    soc=`jshon -F $log_clear_mode_cfg -e $key_of_soc -u`
    if [ "$soc"x == ""x ]; then
        myecho "$key_of_soc is not set!"
    else
        myecho "$key_of_soc is $soc!"
    fi

    #获取过程日志记录文件path（用于最后拷贝记录文件到目标位置）
    check_json_key_exist_and_type $log_clear_mode_cfg $key_of_process_record_file "string"
    if [ $? -eq 0 ]; then
        log_clear_process_record_file=`jshon -F $log_clear_mode_cfg -e $key_of_process_record_file -u`
        if [ "$log_clear_process_record_file"x == ""x ]; then
            myecho "$key_of_process_record_file is not set!"
        else
            myecho "$key_of_process_record_file is $log_clear_process_record_file."
            check_record_path $log_clear_process_record_file
            if [ $? -ne 0 ]; then
                myexit_mode $log_clear_mode
                continue
            fi

            if [ -e $log_clear_process_record_file ]; then
                rm -rf $log_clear_process_record_file
            fi
        fi
    fi

    #获取结果记录文件path（用于最后拷贝清除结果到目标位置）
    check_json_key_exist_and_type $log_clear_mode_cfg $key_of_result_record_file "string"
    if [ $? -eq 0 ]; then
        log_clear_result_record_file=`jshon -F $log_clear_mode_cfg -e $key_of_result_record_file -u`
        if [ "$log_clear_result_record_file"x == ""x ]; then
            myecho "$key_of_result_record_file is not set!"
        else
            myecho "$key_of_result_record_file is $log_clear_result_record_file!"
            check_record_path $log_clear_result_record_file
            if [ $? -ne 0 ]; then
                myexit_mode $log_clear_mode
                continue
            fi

            if [ -e $log_clear_result_record_file ]; then
                rm -rf $log_clear_result_record_file
            fi
        fi
    fi

    #获取是否需要清除系统时间
    need_clear_time=`jshon -F $log_clear_mode_cfg -e $key_of_need_clear_time -u`
    if [ "$need_clear_time"x == "true"x ]; then
        myecho "$key_of_need_clear_time is set true!"
        #set time to 1970-1-1
        busybox date 010100051970
        mkdir -p /data/dji
        busybox date +"%Y-%m-%d %H:%M:%S" > /data/dji/time_record

        if [ -e /dev/rtc0 ]; then
            hwclock -w -u -f /dev/rtc0
        fi
        if [ -e /dev/rtc1 ]; then
            hwclock -w -u -f /dev/rtc1
        fi
        myecho "set time to 1970-01-01 00:05:00"
        date_str=`date`
        myecho "date: $date_str"
    else
        myecho "$key_of_need_clear_time is $need_clear_time, not enable!"
    fi

    #获取需要清理的分区信息
    check_json_key_exist_and_type $log_clear_mode_cfg $key_of_clear_partition_list "array"
    if [ $? -eq 0 ]; then
        clear_partition_list=`jshon -F $log_clear_mode_cfg -e $key_of_clear_partition_list -a -u`
        if [ "$clear_partition_list"x == ""x ]; then
            myecho "the array $key_of_clear_partition_list content is empty."
        else
            myecho "the array $key_of_clear_partition_list is:"
            myecho_without_time "$clear_partition_list"
            for partition in $clear_partition_list; do
                clear_partition $partition
            done
        fi
    fi

    #获取是否需要手动mount并清除内置sd
    need_manual_mount_and_clear_sd=`jshon -F $log_clear_mode_cfg -e $key_of_need_manual_mount_and_clear_sd -u`
    if [ "$need_manual_mount_and_clear_sd"x == "true"x ]; then
        myecho "$key_of_need_manual_mount_and_clear_sd is set true!"

        #获取sd卡根路径
        default_sd_path1="/dev/block/mmcblk1p1"
        default_sd_path2="/dev/block/mmcblk2p1"
        if [ -e $default_sd_path1 ]; then
            default_sd_path=$default_sd_path1
            myecho "get sd path: $default_sd_path!"
            manual_mount_and_clear_sd
        elif [ -e $default_sd_path2 ]; then
            default_sd_path=$default_sd_path2
            myecho "get sd path: $default_sd_path!"
            manual_mount_and_clear_sd
        else
            ls /dev/block | tee -a $log_clear_process_file
            myecho "get sd path error, default sd path: $default_sd_path1 $default_sd_path2, do not exist."
            add_error_to_reason "get sd path:$default_sd_path1 $default_sd_path2 error"
        fi
    else
        myecho "$key_of_need_manual_mount_and_clear_sd is $need_manual_mount_and_clear_sd, not enable!"
    fi

    #获取是否需要删除media分区
    need_clear_media=`jshon -F $log_clear_mode_cfg -e $key_of_need_clear_media -u`
    if [ "$need_clear_media"x == "true"x ]; then
        myecho "$key_of_need_clear_media is set true!"
        ##统一日志清除默认的media路径
        media_path=$default_media_path
        #获取是否指定特殊的media路径
        check_json_key_exist_and_type $log_clear_mode_cfg $key_of_special_media_partition_path "string"
        if [ $? -eq 0 ]; then
            special_media_path=`jshon -F $log_clear_mode_cfg -e $key_of_special_media_partition_path -u`
            if [ "$special_media_path"x != ""x ]; then
                myecho "$key_of_special_media_partition_path is $special_media_path!"

                real_media_path=`realpath $special_media_path`
                if [[ "$real_media_path" != /mnt/* ]]; then
                    myecho "special_media_path: $special_media_path is illegal"
                    add_error_to_reason "special_media_path: $special_media_path is illegal"
                else
                    media_path=$special_media_path
                    clear_media
                fi
            fi
        else
            clear_media
        fi
    else
        myecho "$key_of_need_clear_media is $need_clear_media, not enable!"
    fi

    #获取需要清理的内置存储信息
    check_json_key_exist_and_type $log_clear_mode_cfg $key_of_clear_internal_storage_list "array"
    if [ $? -eq 0 ]; then
        clear_internal_storage_list=`jshon -F $log_clear_mode_cfg -e $key_of_clear_internal_storage_list -a -u`
        if [ "$clear_internal_storage_list"x == ""x ]; then
            myecho "the array $key_of_clear_internal_storage_list content is empty."
        else
            myecho "the array $key_of_clear_internal_storage_list is:"
            myecho_without_time "$clear_internal_storage_list"
            for internal_storage in $clear_internal_storage_list; do
                clear_internal_storage $internal_storage
            done
        fi
    fi

    myecho "unified log clear for $log_clear_mode end."
    myexit_mode $log_clear_mode
done

myecho "unified_log_clear.sh over!"
exit 0

