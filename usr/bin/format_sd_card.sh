function format_sd_card() {
	echo "begin format sd card"

	(
	echo create sd
	echo -e
	echo start sd
	sleep 0.2
	echo -e
	echo format sd exfat SD_Card
	echo -e
	echo stop sd
	echo -e
	echo destroy sd
	echo -e
	echo exit
	) | storage-cli-test > /dev/null
}

# If there is no SD card, fail directly
if [ -b /dev/mmcblk1 ]; then
	echo "sdcard exits"
else
	echo "error:sdcard does not exits"
	exit 1
fi

if [ -n "$(busybox df| grep /mnt/media_rw/sd)" ]; then
	rm -rf /mnt/media_rw/sd/test.file
	busybox dd if=/dev/zero of=/mnt/media_rw/sd/test.file bs=102400 count=10 oflag=direct
	echo "file /mnt/media_rw/sd/test.file create, after format, file should not have"
else
	echo "no sdcard mounted"
fi

format_sd_card

for i in $(seq 1 5); do
	sleep 0.2
	if [ -n "$(busybox df| grep /mnt/media_rw/sd)" ]; then
		break
	fi
done

if [ ! -n "$(busybox df| grep /mnt/media_rw/sd)" ]; then
	echo "error:after format, /mnt/media_rw/sd/ not exit, format failed"
	exit 1
fi

if [ -f /mnt/media_rw/sd/test.file ]; then
	echo "error:after format, file /mnt/media_rw/sd/test.file still exit, format failed"
	exit 1
else
	echo "format sd card success"
fi

echo "[format_sd_card.sh] execution successful"
