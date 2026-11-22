# echo 306 308 309 310 > /sys/class/gpio/export
# cat /sys/class/gpio/gpiox/value

echo 306 > /sys/class/gpio/export
result_306=`cat /sys/class/gpio/gpio306/value`
if [ "$result_306" == "" ]; then
	echo "test read 306 hw ver failed"
	exit 1
else
	echo "hw ver reg val is: $result_306"
	echo "test read 306 hw ver success"
fi

echo 308 > /sys/class/gpio/export
result_308=`cat /sys/class/gpio/gpio308/value`
if [ "$result_308" == "" ]; then
	echo "test read 308 hw ver failed"
	exit 1
else
	echo "hw ver reg val is: $result_308"
	echo "test read 308 hw ver success"
fi

echo 309 > /sys/class/gpio/export
result_309=`cat /sys/class/gpio/gpio309/value`
if [ "$result_309" == "" ]; then
	echo "test read 309 hw ver failed"
	exit 1
else
	echo "hw ver reg val is: $result_309"
	echo "test read 309 hw ver success"
fi

echo 310 > /sys/class/gpio/export
result_310=`cat /sys/class/gpio/gpio310/value`
if [ "$result_310" == "" ]; then
	echo "test read 310 hw ver failed"
	exit 1
else
	echo "hw ver reg val is: $result_310"
	echo "test read 310 hw ver success"
fi

echo "hw ver reg val is: $result_310.$result_309.$result_308.$result_306"
echo "test read hw ver success"
exit 0
