#!/bin/sh

format()
{
    mke2fs -t ext4 -F -b 4096 $1

    if [ $? -eq 0 ]; then
        echo "MNT: format ${mount_node} success" >> /dev/kmsg
    else
        echo "MNT: format ${mount_node} fail" >> /dev/kmsg
    fi
}

fsck_with_format()
{
	mount_dev=$1
	mount_node=$2

	echo "MNT: start to mount node: $mount_node" >> /dev/kmsg

	echo "MNT: try to mount ${mount_node}..." >> /dev/kmsg
	# mount file system

	umount ${mount_node}

	for number in 1 2 3
	do
	    fsck.ext4 -fy ${mount_dev}
		fsck_ret=$?
		if [ ${fsck_ret} -eq 0 ]; then
			echo "MNT: fsck pass, node: $mount_dev, result: $fsck_ret " >> /dev/kmsg
			mount -t ext4 -o ${option} ${mount_dev} ${mount_node}
			mount_ret=$?
			if [ $mount_ret -eq 0 ]; then
				echo "MNT: mount ${mount_node} success" >> /dev/kmsg
				exit 0
			fi
		fi
		usleep 10000
		echo "MNT: fsck/mount fail, node: $mount_dev, fsck: ${fsck_ret};mount: ${mount_ret}; times: ${number}" >> /dev/kmsg
	done

	echo "MNT: try to format ${mount_node}..." >> /dev/kmsg
	format ${mount_dev}
	mount -t ext4 -o ${option} ${mount_dev} ${mount_node}
	if [ $? -ne 0 ]; then
		echo "MNT: mount ${mount_node} fail again" >> /dev/kmsg
	else
		echo "MNT: mount ${mount_node} success" >> /dev/kmsg
	fi
}

fsck_without_format()
{
	mount_dev=$1
	mount_node=$2

	echo "MNT: start to mount node: $mount_node" >> /dev/kmsg

	echo "MNT: try to mount ${mount_node}..." >> /dev/kmsg
	# mount file system

	umount ${mount_node}

	for number in 1 2 3
	do
	    fsck.ext4 -fy ${mount_dev}
		fsck_ret=$?
		if [ ${fsck_ret} -eq 0 ]; then
			echo "MNT: fsck pass, node: $mount_dev, result: $fsck_ret " >> /dev/kmsg
			mount -t ext4 -o ${option} ${mount_dev} ${mount_node}
			mount_ret=$?
			if [ $mount_ret -eq 0 ]; then
				echo "MNT: mount ${mount_node} success" >> /dev/kmsg
				exit 0
			fi
		fi
		usleep 10000
		echo "MNT: fsck/mount fail, node: $mount_dev, fsck: ${fsck_ret};mount: ${mount_ret}; times: ${number}" >> /dev/kmsg
	done

	mount -t ext4 -o ${option} ${mount_dev} ${mount_node}
	if [ $? -ne 0 ]; then
		echo "MNT: mount ${mount_node} fail again" >> /dev/kmsg
	else
		echo "MNT: mount ${mount_node} success" >> /dev/kmsg
	fi
}

mount_tag=$1
mount_dev=$2
mount_node=$3
option=$4
if [ $mount_tag == "fsck_format" ]; then
	fsck_with_format $mount_dev $mount_node
else
	fsck_without_format $mount_dev $mount_node
fi
