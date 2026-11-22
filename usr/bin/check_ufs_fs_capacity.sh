# partitions that need to be checked: /dev/sda9 10 11 12 13, and /data , /etc, /cache mount point

# parameter 1 needs to be greater than or equal to parameter 2
function check_diff_within_20percent() {
	local num_1=${1}
	local num_2=${2}

	local diff=$((num_1 - num_2))
	local max=$((num_1 > num_2 ? num_1 : num_2))
	local threshold=$((max * 20 / 100))

	if [ $diff -lt $threshold ]; then
		echo "diff is less than 20 percent, para1 is ${num_1}, para2 is ${num_2}"
		return 0
	else
		echo "diff is not less than 20 percent, para1 is ${num_1}, para2 is ${num_2}"
		return 1
	fi
}

function check_partition_is_right() {
	local ret=0

	# get the size of the target partition
	sda9_partition_size=$(cat /proc/partitions | grep sda9| busybox awk '{print $3}')
	sda10_partition_size=$(cat /proc/partitions | grep sda10| busybox awk '{print $3}')
	sda11_partition_size=$(cat /proc/partitions | grep sda11| busybox awk '{print $3}')
	sda12_partition_size=$(cat /proc/partitions | grep sda12| busybox awk '{print $3}')
	sda13_partition_size=$(cat /proc/partitions | grep sda13| busybox awk '{print $3}')

	echo "sda9_partition_size is ${sda9_partition_size}"
	echo "sda10_partition_size is ${sda10_partition_size}"
	echo "sda11_partition_size is ${sda11_partition_size}"
	echo "sda12_partition_size is ${sda12_partition_size}"
	echo "sda13_partition_size is ${sda13_partition_size}"

	# get the size of the target partition file system
	sda9_fs_size=$(busybox df -k | grep /dev/sda9 | busybox awk '{print $2}')
	sda10_fs_size=$(busybox df -k | grep /dev/sda10 | busybox awk '{print $2}')
	sda11_fs_size=$(busybox df -k | grep /dev/sda11 | busybox awk '{print $2}')
	sda12_fs_size=$(busybox df -k | grep /dev/sda12 | busybox awk '{print $2}')
	sda13_fs_size=$(busybox df -k | grep /dev/sda13 | busybox awk '{print $2}')

	echo "sda9_fs_size is ${sda9_fs_size}"
	echo "sda10_fs_size is ${sda10_fs_size}"
	echo "sda11_fs_size is ${sda11_fs_size}"
	echo "sda12_fs_size is ${sda12_fs_size}"
	echo "sda13_fs_size is ${sda13_fs_size}"

	check_diff_within_20percent ${sda9_partition_size} ${sda9_fs_size}
	if [ $? -eq 1 ]; then
		ret=1
	fi

	check_diff_within_20percent ${sda10_partition_size} ${sda10_fs_size}
	if [ $? -eq 1 ]; then
		ret=1
	fi

	check_diff_within_20percent ${sda11_partition_size} ${sda11_fs_size}
	if [ $? -eq 1 ]; then
		ret=1
	fi

	check_diff_within_20percent ${sda12_partition_size} ${sda12_fs_size}
	if [ $? -eq 1 ]; then
		ret=1
	fi

	check_diff_within_20percent ${sda13_partition_size} ${sda13_fs_size}
	if [ $? -eq 1 ]; then
		ret=1
	fi

	# check if the target partition file system type is correct
	sda9_fs_type=$(busybox df -T | grep /dev/sda9 | busybox awk '{print $2}')
	sda10_fs_type=$(busybox df -T | grep /dev/sda10 | busybox awk '{print $2}')
	sda11_fs_type=$(busybox df -T | grep /dev/sda11 | busybox awk '{print $2}')
	sda12_fs_type=$(busybox df -T | grep /dev/sda12 | busybox awk '{print $2}')
	sda13_fs_type=$(busybox df -T | grep /dev/sda13 | busybox awk '{print $2}')

	if [ ${sda9_fs_type} == "ext4" ]; then
		echo "sda9_fs_type is right"
	else
		echo "sda9_fs_type is wrong"
		ret=1
	fi

	if [ ${sda10_fs_type} == "ext4" ]; then
		echo "sda10_fs_type is right"
	else
		echo "sda10_fs_type is wrong"
		ret=1
	fi

	if [ ${sda11_fs_type} == "ext4" ]; then
		echo "sda11_fs_type is right"
	else
		echo "sda11_fs_type is wrong"
		ret=1
	fi

	if [ ${sda12_fs_type} == "exfat" ]; then
		echo "sda12_fs_type is right"
	else
		echo "sda12_fs_type is wrong"
		ret=1
	fi

	if [ ${sda13_fs_type} == "ext4" ]; then
		echo "sda13_fs_type is right"
	else
		echo "sda13_fs_type is wrong"
		ret=1
	fi

	# check if /data , /etc, /cache mount point exist, overlay related
	partition_cache=$(busybox df -T | grep overlay | grep -v var |grep cache)
	partition_data=$(busybox df -T | grep overlay | grep data)
	partition_etc=$(busybox df -T | grep overlay | grep etc)

	if [ -z "${partition_cache}" ]; then
		echo "partition_cache is not exit"
		ret=1
	else
		echo "partition_cache is exit"
	fi

	if [ -z "${partition_data}" ]; then
		echo "partition_data is not exit"
		ret=1
	else
		echo "partition_data is exit"
	fi

	if [ -z "${partition_etc}" ]; then
		echo "partition_etc is not exit"
		ret=1
	else
		echo "partition_etc is exit"
	fi

	return ${ret}
}

check_partition_is_right

if [ $? -eq 0 ]; then
	echo "[check_ufs_fs_capacity.sh] execution successful"
else
	echo "error:[check_ufs_fs_capacity.sh] execution failed"
fi
