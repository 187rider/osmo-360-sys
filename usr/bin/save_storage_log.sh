#!/bin/sh

base_dir=/blackbox/system
max_log_num=10
target_file=$base_dir/storage_log_0.log

file_size=`ls ${base_dir} | grep storage_log | wc -l`

if [ $file_size -lt $max_log_num ]
then
	cur_index=`expr $file_size - 1`
else
	cur_index=`expr $max_log_num - 2`
fi

for i in $(seq $cur_index -1 0)
do
	mv $base_dir/storage_log_$i.log $base_dir/storage_log_$(expr $i + 1).log
done

sync

date >> $target_file
cat /proc/kmsg |grep -e mmcblk -e sda13 -e mmc1 -e ufs >> $target_file
