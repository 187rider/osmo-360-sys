check_sd_speed_and_link()
{
	if [ ! -b /dev/mmcblk1 ]; then
		echo "before check sd speed, /dev/mmcblk1 not exit, test terminated"
		return 1
	fi

	busybox dd of=/dev/null if=/dev/mmcblk1 bs=1024 count=400 iflag=direct

	cat /sys/kernel/debug/mmc1/ios | grep "SDR104"
	if [ $? -ne 0 ]; then
		echo "[WARN]no sdcard or sdcard not SDR104 mode"
		echo `cat /sys/kernel/debug/mmc1/ios`
	else
		return 0
	fi
	return 1
}

check_sd_speed_and_link

if [ $? -eq 0 ]; then
	echo "[check_sdcard_bus_speed_mode.sh] execution successful"
	exit 0
else
	echo "error:[check_sdcard_bus_speed_mode.sh] execution failed"
	exit 1
fi
