#!/bin/sh

ntc_tmp=0

cd /sys/bus/iio/devices/iio:device0

if [ -f ./in_temp_ac204_shelter_therm_input ]; then
	ntc_tmp=`cat in_temp_ac204_shelter_therm_input`
fi

if [ $ntc_tmp -eq 0 ]; then
	cd /sys/bus/iio/devices/iio:device2
	if [ -f ./in_temp_ac204_shelter_therm_input ]; then
		ntc_tmp=`cat in_temp_ac204_shelter_therm_input`
	fi
fi

if [ $ntc_tmp -eq 0 ]; then
	cd /sys/bus/iio/devices/iio:device1
	if [ -f ./in_temp_ac204_shelter_therm_input ]; then
		ntc_tmp=`cat in_temp_ac204_shelter_therm_input`
	fi
fi

if [ $ntc_tmp -ge 1500 ] && [ $ntc_tmp -le 6000 ]; then
	echo "NTC tmp is: $ntc_tmp"
	echo SUCCESS
	ret=0
else
	echo "NTC tmp is: $ntc_tmp"
	echo ERROR
	ret=1
fi

exit $ret
