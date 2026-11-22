keyname=$1

result=`cat /proc/interrupts | grep "$keyname" |busybox awk '{printf $2}'`
ret=`cat /proc/interrupts | grep "$keyname" |busybox awk '{printf $2}'`

i=0
while [ "$result" == "$ret" ]
do
	echo "please press $keyname"
	sleep 1
	ret=`cat /proc/interrupts | grep "$keyname" |busybox awk '{printf $2}'`
	let i++
	if [ $i -gt 10 ]; then
		echo "$keyname test timeout!"
		exit 1
	fi
done
echo "$keyname test pass!"

exit 0
