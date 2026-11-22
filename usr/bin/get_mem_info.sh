#!/bin/bash

function get_kernel_meminfo()
{
	echo "------------------------     start to get kernel meminfo     ------------------------"
	cat /proc/meminfo | grep -E "MemTotal|MemFree|Active|Inactive|Slab|Shmem:|Mlocked|VmallocUse
d|Cma"
	echo "------------------------     end to get kernel meminfo       ------------------------ \n"
}

function get_product_process_meminfo()
{
	echo "------------------------ start to get product process anon meminfo -----------------------"
	process=("qmmf-server" "dji_camera3" "dji_gui_on_disp0" "dji_gui_on_disp1" "dji_media_server" "dji_sw_uav")
	i=0
	array_length=${#process[@]}
	while [ $i -lt $array_length ]; do
		pid=`ps -ef | grep ${process[$i]} | grep -v grep | busybox awk 'NR==1 {print $2}'`
		if [ -n "$pid" ]; then
			anon=`cat /proc/$pid/status | grep RssAnon`
			swap=`cat /proc/$pid/status | grep VmSwap`
			echo "$anon	$swap	${process[i]}"
		else
			echo "${process[i]} is not exist"
		fi
		i=$((i + 1))
	done
	echo "------------------------  end to get product process anon meminfo ------------------------\n"
}

function get_dma_buf_info()
{
	echo "------------------------      start to get dma_buf info       ------------------------"
	tail -n 1 /sys/kernel/debug/dma_buf/bufinfo
	echo "------------------------       end to get dma_buf info        ------------------------\n"
}
echo `date`
get_kernel_meminfo
get_product_process_meminfo
get_dma_buf_info
