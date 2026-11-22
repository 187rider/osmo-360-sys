data_result=`cat /sys/class/rtc/rtc0/date`
time_result=`cat /sys/class/rtc/rtc0/time`
date -s "2024-01-01 00:00:00"
hwclock_result=`hwclock -f /dev/rtc0 -w`

if [ "$data_result" == "" ]; then
	echo "test read rtc date failed"
	exit 1
else
	echo "rtc date reg val is: $data_result"
	echo "test read rtc success"
	exit 0
fi

if [ "$time_result" == "" ]; then
	echo "test read rtc time failed"
	exit 1
else
	echo "rtc time reg val is: $time_result"
	echo "test read rtc success"
	exit 0
fi

if [ "$hwclock_result" == "" ]; then
	echo "test read rtc hwclock failed"
	exit 1
else
	echo "rtc hwclock reg val is: $hwclock_result"
	echo "test read rtc success"
	exit 0
fi
