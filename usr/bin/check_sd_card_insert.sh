function check_sd_card_insert() {
	if [ -b /dev/mmcblk1 ]; then
		echo "sdcard exits"
	else
		echo "sdcard does not exist"
		return 1
	fi
}

check_sd_card_insert

if [ $? -eq 0 ]; then
	echo "[check_sd_card_insert.sh] execution successful"
	exit 0
else
	echo "error:[check_sd_card_insert.sh] execution failed"
	exit 1
fi
