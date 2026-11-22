# default parameters
# [0x1520]PA_AvailTxDataLanes                           : local = 0x00000002, peer = 0x00000002
# [0x1540]PA_AvailRxDataLanes                           : local = 0x00000002, peer = 0x00000002

# [0x1568]PA_TxGear                                     : local = 0x00000003, peer = 0x00000003
# [0x156a]PA_HSSeries                                   : local = 0x00000002, peer = 0x00000002
# [0x1583]PA_RxGear                                     : local = 0x00000003, peer = 0x00000003

function ufs_speed_test() {

	local res=0

	#availdatalane_info=$(/usr/bin/ufs_utils uic -t 1 -a -p /dev/bsg/ufs-bsg0 | grep -E "Avail.*xDataLanes")
	ifenable=$(cat /sys/devices/platform/soc/1d84000.ufshc/clkscale_enable)
	max_hs_mode=$(ufs_utils uic -t 1 -r -i 0x1587 -p /dev/bsg/ufs-bsg0 | awk -F'peer =' '{print $2}')
	availdatalane_info=$(/usr/bin/ufs_utils uic -t 1 -r -i 0x1520 -p /dev/bsg/ufs-bsg0)

	if [ "$(echo "${availdatalane_info}" | grep Tx | busybox awk '{print $5}')" == "0x00000002," ]; then
		echo "match"
	else
		echo "${availdatalane_info} not match"
		res=1
	fi
	if [ "$(echo "${availdatalane_info}" | grep Tx | busybox awk '{print $8}')" == "0x00000002" ]; then
		echo "match"
	else
		echo "${availdatalane_info} not match"
		res=1
	fi

	availdatalane_info=$(/usr/bin/ufs_utils uic -t 1 -r -i 0x1540 -p /dev/bsg/ufs-bsg0)
	if [ "$(echo "${availdatalane_info}" | grep Rx | busybox awk '{print $5}')" == "0x00000002," ]; then
		echo "match"
	else
		echo "${availdatalane_info} not match"
		res=1
	fi
	if [ "$(echo "${availdatalane_info}" | grep Rx | busybox awk '{print $8}')" == "0x00000002" ]; then
		echo "match"
	else
		echo "${availdatalane_info} not match"
		res=1
	fi

	#hsseries_info=$(/usr/bin/ufs_utils uic -t 1 -a -p /dev/bsg/ufs-bsg0 | grep -E "PA_HSSeries")
	hsseries_info=$(/usr/bin/ufs_utils uic -t 1 -r -i 0x156a -p /dev/bsg/ufs-bsg0)

	if [ "$(echo "${hsseries_info}" | busybox awk '{print $5}')" == "0x00000002," ]; then
		echo "match"
	else
		echo "${hsseries_info} not match"
		res=1
	fi
	if [ "$(echo "${hsseries_info}" | busybox awk '{print $8}')" == "0x00000002" ]; then
		echo "match"
	else
		echo "${hsseries_info} not match"
		res=1
	fi

	echo 0 > /sys/devices/platform/soc/1d84000.ufshc/clkscale_enable
	sleep 1
	rm -rf /blackbox/ufs_speed_test.file
	nohup busybox dd if=/dev/zero of=/blackbox/ufs_speed_test.file bs=1024000 count=700 oflag=direct &
	sleep 4

	echo "begin write"

	#txgear_info=$(/usr/bin/ufs_utils uic -t 1 -a -p /dev/bsg/ufs-bsg0 | grep -E "PA_TxGear")
	txgear_info=$(/usr/bin/ufs_utils uic -t 1 -r -i 0x1568 -p /dev/bsg/ufs-bsg0)

	if [ "$(echo "${txgear_info}" | busybox awk '{print $5}')" == ${max_hs_mode}"," ]; then
		echo "match"
	else
		echo "${txgear_info} not match"
		res=1
	fi
	if [ "$(echo "${txgear_info}" | busybox awk '{print $8}')" == ${max_hs_mode}"" ]; then
		echo "match"
	else
		echo "${txgear_info} not match"
		res=1
	fi

	while true
	do
		local write_file_still=$(busybox ps -ef | grep ufs_speed_test.file | grep -v grep)
		if [ -n "${write_file_still}" ]; then
			write_file_still=$(busybox ps -ef | grep ufs_speed_test.file | grep -v grep)
			sleep 0.1
		else
			break
		fi
	done

	echo "begin read"
	nohup busybox dd of=/dev/null if=/blackbox/ufs_speed_test.file bs=1024000 count=700 iflag=direct &
	sleep 2

	#rxgear_info=$(/usr/bin/ufs_utils uic -t 1 -a -p /dev/bsg/ufs-bsg0 | grep -E "PA_RxGear")
	rxgear_info=$(/usr/bin/ufs_utils uic -t 1 -r -i 0x1583 -p /dev/bsg/ufs-bsg0)

	if [ "$(echo "${rxgear_info}" | busybox awk '{print $5}')" == ${max_hs_mode}"," ]; then
		echo "match"
	else
		echo "${rxgear_info} not match"
		res=1
	fi
	if [ "$(echo "${rxgear_info}" | busybox awk '{print $8}')" == ${max_hs_mode}"" ]; then
		echo "match"
	else
		echo "${rxgear_info} not match"
		res=1
	fi

	while true
	do
		local read_file_still=$(busybox ps -ef | grep ufs_speed_test.file | grep -v grep)
		if [ -n "${read_file_still}" ]; then
			read_file_still=$(busybox ps -ef | grep ufs_speed_test.file | grep -v grep)
			sleep 0.1
		else
			break
		fi
	done
	echo "res is ${res}"

	echo ${ifenable} > /sys/devices/platform/soc/1d84000.ufshc/clkscale_enable
	return ${res}
}
cd /blackbox/
ufs_speed_test

if [ $? -eq 0 ]
then
	echo "[ufs_speed_test.sh] execution successful"
else
	echo "[ufs_speed_test.sh] retry"
	ufs_speed_test
	if [ $? -eq 0 ]
	then
		echo "[ufs_speed_test.sh] execution successful"
	else
		echo "error:[ufs_speed_test.sh] execution fail"
		exit 1
	fi
fi
