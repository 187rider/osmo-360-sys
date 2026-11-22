#!/bin/sh

base_dir=/blackbox/system
max_log_num=5
target_file=$base_dir/io_monitor_0.log

file_size=`ls ${base_dir} | grep io_monitor | wc -l`

if [ $file_size -lt $max_log_num ]
then
	cur_index=`expr $file_size - 1`
else
	cur_index=`expr $max_log_num - 2`
fi

for i in $(seq $cur_index -1 0)
do
	mv $base_dir/io_monitor_$i.log $base_dir/io_monitor_$(expr $i + 1).log
done

sync
sar -b  -d -B -r 1 | busybox awk '!/dev8-32/ && !/dev8-16/ && !/dev8-48/ && !/dev8-64/ && !/dev8-80/' >> $target_file
