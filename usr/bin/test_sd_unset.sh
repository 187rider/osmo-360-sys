result=`ls /dev/* | grep /dev/mmcblk1`

while [ "$result" == "" ]
do
	echo "SD card unset"
	exit 0
done

echo "plz remove sd card"

exit 1
