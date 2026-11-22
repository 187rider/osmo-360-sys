set -e

if [ $# -lt 2 ]; then
	echo "usage: $0 <rpmb_size> <loops> "
	echo "e.g.:"
	echo "     read 16M region and run 50 counts > $0 16M 50"
	exit 1
fi

rpmb_size_type=${1: -1}

if [ $rpmb_size_type == "M" ]; then
	size_str=${1%M*}
	let size_int=$size_str
	rpmb_size=$(($size_int * 1024 * 1024))
elif [ $rpmb_size_type == "K" ]; then
	size_str=${1%K*}
	let size_int=$size_str
	rpmb_size=$((size_int * 1024))
else
	rpmb_size=$1
fi
echo "rpmb size is $rpmb_size"

loop=$2

rpmb_device_path="/dev/bsg/0:0:0:49476"

if [ -e $rpmb_device_path ]; then
	rpmb_device=$rpmb_device_path
else
	echo "can not find rpmb device, please check and modify me."
	exit 2
fi

rpmb_test_dir="/blackbox/rpmb_test/"
rpmb_test_log="$rpmb_test_dir/rpmb_test.log"
rpmb_test_key="$rpmb_test_dir/rpmb_test_key"
rpmb_test_read_data="$rpmb_test_dir/rpmb_test_read_data"
rpmb_test_write_data="$rpmb_test_dir/rpmb_test_write_data"

if [ -d $rpmb_test_dir ]; then
	echo "work directory '$rpmb_test_dir' exists"
	echo "please make sure log files has been saved. then remove the directory and retry."
	exit 1
fi

mkdir -p $rpmb_test_dir

# inject key, default inject rpmb key to region 0
echo -ne "\xD3\xEB\x3E\xC3\x6E\x33\x4C\x9F\x98\x8C\xE2\xC0\xB8\x59\x54\x61\x0D\x2B\xCF\x86\x64\x84\x4D\xF2\xAB\x56\xE6\xC6\x1B\xB7\x01\xE4" > $rpmb_test_key
ufs_utils rpmb -t 0 -m 0 -p $rpmb_device -k $rpmb_test_key
# ufs_utils rpmb -t 0 -m 1 -p $rpmb_device -k $rpmb_test_key
# ufs_utils rpmb -t 0 -m 2 -p $rpmb_device -k $rpmb_test_key
# ufs_utils rpmb -t 0 -m 3 -p $rpmb_device -k $rpmb_test_key

if [ -f $rpmb_test_read_data ]; then
	rm $rpmb_test_read_data
fi

if [ -f $rpmb_test_write_data ]; then
	rm $rpmb_test_write_data
fi

rpmb_test_write_count=`expr $rpmb_size / 256`
echo "size=$rpmb_size, test_num=$loop\n" > $rpmb_test_log

test_count=0
while [ $test_count -lt $loop ]
do
	echo "-------------------------BEGIN test loop $test_count-------------------------"
	echo "BEGIN test loop $test_count" >> $rpmb_test_log
	dd if=/dev/urandom of=$rpmb_test_write_data bs=256 count=$rpmb_test_write_count
	md5=`busybox md5sum $rpmb_test_write_data | busybox awk '{print $1}'`

	#write RPMB
	ufs_utils rpmb -t 3 -p $rpmb_device -s 0 -n $rpmb_test_write_count -w $rpmb_test_write_data -k $rpmb_test_key
	#read RPMB
	ufs_utils rpmb -t 2 -p $rpmb_device -s 0 -n $rpmb_test_write_count -w $rpmb_test_read_data -k $rpmb_test_key

	md5out=`busybox md5sum $rpmb_test_read_data | busybox awk '{print $1}'`
	if [ "${md5}" != "${md5out}" ]; then
		echo "$md5 != $ms5out, ufs rpmb test loop $test_count failed."
		echo "$md5 != $ms5out, ufs rpmb test loop $test_count failed." >> $rpmb_test_log
		exit 1
	fi

	echo "END test loop $test_count, writen $rpmb_test_write_count * 256 bytes, succeed\n" >> $rpmb_test_log

	rm $rpmb_test_read_data
	rm $rpmb_test_write_data
	test_count=$(($test_count + 1))
done

dd if=/dev/zero of=$rpmb_test_write_data bs=256 count=$rpmb_test_write_count
ufs_utils rpmb -t 3 -p $rpmb_device -s 0 -n $rpmb_test_write_count -w $rpmb_test_write_data -k $rpmb_test_key
rm $rpmb_test_key
rm $rpmb_test_write_data

exit 0
