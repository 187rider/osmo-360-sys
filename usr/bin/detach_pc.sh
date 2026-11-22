function check() {
	for i in `seq 10`
	do
		if [ -n "$(busybox df| grep /mnt/media_rw/emulated)" ]
		then
			echo "detach emulated from pc success, /mnt/media_rw/emulated is exit"
			break
		else
			sleep 0.2
		fi
	done

	for i in `seq 10`
	do
		if [ -n "$(busybox df| grep /mnt/media_rw/sd)" ]
		then
			echo "detach sd from pc success, /mnt/media_rw/sd is exit"
			break
		else
			sleep 0.2
		fi
	done

}

function detach_pc() {

	# If there is no SD card, fail directly
	if [ -b /dev/mmcblk1 ]; then
		echo "sdcard exits"
	else
		echo "sdcard does not exits"
		return 1
	fi

	(
	echo create sd
	echo -e
	echo start sd
	sleep 0.2
	echo -e
	echo create emulated
	echo -e
	echo start emulated
	sleep 0.2
	echo -e
	echo detach sd
	sleep 0.3
	check
	echo -e
	echo stop emulated
	echo -e
	echo destroy emulated
	echo -e
	echo stop emulated
	echo -e
	echo destroy emulated
	echo -e
	echo exit
	) | storage-cli-test > /dev/null

	if [ -n "$(busybox df| grep /mnt/media_rw/emulated)" ]
	then
		echo "detach emulated from pc success, /mnt/media_rw/emulated is exit"
	else
		echo "detach emulated from pc fail, /mnt/media_rw/emulated is not exit"
		return 1
	fi

	if [ -n "$(busybox df| grep /mnt/media_rw/sd)" ]
	then
		echo "detach sd from pc success, /mnt/media_rw/sd is exit"
	else
		echo "detach sd from pc fail, /mnt/media_rw/sd is not exit"
		return 1
	fi

}

ret=0
detach_pc
ret=$?

if [ ${ret} -eq 0 ]
then
	echo "[detach_pc.sh] execution successful"
	exit 0
else
	echo "error:[detach_pc.sh] execution failed"
	exit 1
fi
