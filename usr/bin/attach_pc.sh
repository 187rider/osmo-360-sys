function attach_pc() {

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
	echo attach sd
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

	for i in `seq 5`
	do
		if [ -n "$(busybox df| grep /mnt/media_rw/sd)" ]
		then
			sleep 0.1
		else
			break
		fi
	done

	for i in `seq 5`
	do
		if [ -n "$(busybox df| grep /mnt/media_rw/emulated)" ]
		then
			sleep 0.1
		else
			break
		fi
	done

	if [ -n "$(busybox df| grep /mnt/media_rw/sd)" ]
	then
		echo "attach sd to pc fail, /mnt/media_rw/sd is exit"
		return 1
	fi

	if [ -n "$(busybox df| grep /mnt/media_rw/emulated)" ]
	then
		echo "attach emulated to pc fail, /mnt/media_rw/emulated is exit"
		return 1
	fi
}

ret=0
attach_pc
ret=$?

if [ ${ret} -eq 0 ]
then
	echo "The machine has executed attach PC, please check if there have disks on the PC"
	/sbin/usb/compositions/8002 n n y n
	exit 0
else
	echo "error:attach_pc failed"
	exit 1
fi
