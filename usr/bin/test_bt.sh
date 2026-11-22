#!/bin/sh
# check if bt process bsa_server is running, if running, then bt is ok

pid=`pidof bsa_server`
if [ "${pid}" == "" ];then
    echo "test BT failed"
	exit 1
fi

# 读取文件内容
file_content=$(cat /proc/tty/driver/msm_geni_serial_hs)

# 检查是否包含 "0: uart" 且不包含 "fe" 且不包含 "brk"
serial_line=$(echo "$file_content" | grep "0: uart" | grep -v fe | grep -v brk)
#echo $serial_line
if [ "${serial_line}" == "" ]; then
    echo "Test BT failed"
	exit 1
fi


BT_LINK_PATH="/tmp/bt_link_success"
if [ ! -e "$BT_LINK_PATH" ]; then
    echo "test BT failed"
	exit 1
fi

echo "test BTsuccess"


