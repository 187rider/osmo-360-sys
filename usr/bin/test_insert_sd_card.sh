result=`df | grep /dev/mmcblk1p1`

i=0
while [ "$result" == "" ]
do
	echo "please insert SD card"
	sleep 1
	result=`df | grep /dev/mmcblk1p1`
	let i++
	if [ $i -gt 10 ]; then
		echo "insert SD card timeout!"
		exit 1
	fi
done

touch /mnt/media_rw/sd/insert_test
echo "pass" > /mnt/media_rw/sd/insert_test

result=$(cat /mnt/media_rw/sd/insert_test)
if [ $result != pass ]; then
	echo "sdcard r/w failed."
	exit 1
fi
rm /mnt/media_rw/sd/insert_test

echo "SD card pass"

exit 0
