#!/bin/bash

dump_num=0
is_pano_mode=0

function get_mp4_num_in_internal_storage()
{
    file_count=`ls -l /mnt/media_rw/emulated/DCIM/DJI_001 | grep "MP4" | wc -l`
    echo "Success get MP4 $file_count"
    exit $file_count
}

function get_pano_osv_num_in_internal_storage()
{
    file_count=`ls -l /mnt/media_rw/emulated/DCIM/DJI_001 | grep "OSV" | wc -l`
    echo "Success get OSV $file_count"
    exit $file_count
}

function clear_all_config()
{
    result=`rm /data/camera/camxoverridesettings.txt`
    result=`rm /data/camera/f2foverridesettings.txt`
}

function prepare_raw_back()
{
    result=`cp /mnt/media_rw/emulated/raw_dump*/* /mnt/media_rw/emulated/`
}


function check_dump_num()
{
    file_count=$(ls -l /mnt/media_rw/emulated/raw_dump* | grep "RawMeta" | wc -l)

    echo "Get result count $file_count is_pano_mode $is_pano_mode"

    if [ "$is_pano_mode" -ne 0 ]; then
        file_count=$((file_count / 2))
    fi

    let "file_count--"

    if [ $file_count == $dump_num ];then
        echo "Success result count $file_count dump_num $dump_num"
    else
        echo "Fail result count $file_count dump_num $dump_num"
        exit 1
    fi
}

function clear_dump_file()
{
    result=`rm -rf /mnt/media_rw/emulated/raw_dump*`
    result=`rm /mnt/media_rw/emulated/*.Raw`
    result=`rm /mnt/media_rw/emulated/*.RawMeta`
}

func_usage() {
    echo "---- f2f test usage ---"
    echo "check_dump_num  - get dump raw num is right"
    echo "clear_dump      - clear all dump file"
    echo "clear_all_config- clear all config file"
    echo "prepare_raw_back  - prepare raw bak file such as raw image data"
}

rlt=0

if [ ! -n "$1" ];then
    echo "no input param, please check!!!"
    func_usage
    exit 1
elif [ $1 == "check_dump_num" ];then
    dump_num=$2
    is_pano_mode=$3
    check_dump_num
elif [ $1 == "clear_dump" ];then
    clear_dump_file
elif [ $1 == "prepare_raw_back" ];then
    prepare_raw_back
elif [ $1 == "get_mp4_num" ];then
    get_mp4_num_in_internal_storage
elif [ $1 == "clear_all_config" ];then
    clear_all_config
elif [ $1 == "get_pano_osv_num" ];then
    get_pano_osv_num_in_internal_storage
else
    echo "unsupported input param: $1, please check!!!"
    exit 1
fi

exit 0