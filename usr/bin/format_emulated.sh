function format_emulated() {
	echo "begin format emulated"

	(
	echo create emulated
	echo -e
	echo start emulated
	sleep 0.2
	echo -e
	echo format emulated exfat Internal_
	echo -e
	echo stop emulated
	echo -e
	echo destroy emulated
	echo -e
	echo exit
	) | storage-cli-test > /dev/null
}

if [ -n "$(busybox df| grep /mnt/media_rw/emulated)" ]; then
	rm -rf /mnt/media_rw/emulated/test.file
	busybox dd if=/dev/zero of=/mnt/media_rw/emulated/test.file bs=102400 count=10 oflag=direct
	echo "file /mnt/media_rw/emulated/test.file create, after format, file should not have"
else
	echo "no emulated mounted"
fi

format_emulated

for i in $(seq 1 5); do
	sleep 0.2
	if [ -n "$(busybox df| grep /mnt/media_rw/emulated)" ]; then
		break
	fi
done

if [ ! -n "$(busybox df| grep /mnt/media_rw/emulated)" ]; then
	echo "error:after format, /mnt/media_rw/emulated/ not exit, format failed"
	exit 1
fi

if [ -f /mnt/media_rw/emulated/test.file ]; then
	echo "error:after format, file /mnt/media_rw/emulated/test.file still exit, format failed"
	exit 1
else
	echo "format emulated card success"
fi

echo "[format_emulated.sh] execution successful"
