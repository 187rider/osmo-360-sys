test_time=${1}
test_device=${2}

function rw_test() {
	local times=$1
	local device=$2
	local block_size=2
	local byte_size=131072
	local i=0
	local mnt_point=${device}

	for i in `seq 1 ${times}`
	do
		test1=${mnt_point}/test${i}.1
		test2=${mnt_point}/test${i}.2
		busybox dd if=/dev/urandom of=${test1} bs=${byte_size} count=${block_size} oflag=direct
		echo 3 > /proc/sys/vm/drop_caches

		if [ -f ${test1} ]; then
			echo "file exit"
		else
			echo "file not exit"
			return 1
		fi

		md5src=`busybox md5sum ${test1} | busybox awk '{print $1}'`
		busybox dd if=${test1} of=${test2} iflag=direct
		echo 3 > /proc/sys/vm/drop_caches
		md5des=`busybox md5sum ${test2} | busybox awk '{print $1}'`
		if [ "x$md5src" == "x$md5des"   ]; then
			echo "rw_test $i ok"
		else
			echo "rw_test $i failed"
			echo `ls -l ${mnt_point}`
			return 1
		fi
	done
	rm -rf ${test1}
	rm -rf ${test2}

	return 0
}

rm -rf ${test_device}/*
rmdir ${test_device}
mkdir ${test_device}

if [ ! -n "$(busybox df| grep ${test_device})" ]; then
	echo "error:before rw test , ${test_device} not exit, test terminated"
	exit 1
fi

rw_test ${test_time} ${test_device}

if [ $? -eq 0 ]; then
	echo "[rw_test.sh] execution successful"
	exit 0
else
	echo "error:[rw_test.sh] execution failed"
	exit 1
fi
