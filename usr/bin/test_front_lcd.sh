#!/bin/sh
int_id=TE_GPIO
val1=`cat /proc/interrupts | grep $int_id`
front_TE_gpio=87

if [ ! "$val1" ]
then
	echo "lcd panel is ok!"
else
	result=$(echo $val1 | grep "$front_TE_gpio")
	if [[ "$result" != "" ]]
	then
		echo "front panel check failed !!!"
	else
		echo "front panel check success !"
	fi

	exit 1
fi

exit 0