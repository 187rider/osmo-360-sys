#! /bin/bash

# OQ101 barometer script
# updated data: 2023-11-17
barometer_directory="/factory_data/camera/barometer.txt"

func_usage() {
    echo "----- OQ101 barometer sensor factory calibration and test script -----"
    echo "<1> input param 1: choose function:"
    echo "    set_frequency        : set barometer frequency"
    echo "    set_scale            : set barometer scale"
    echo "    get_barometer_data   : get and save barometer sensor data"
    echo "    check_bm_link_status : check sensor link status"
}

if [ ! -n "$1" ];then
    echo "no input param to test adscura, please check!!!"
    func_usage
    echo $"/failedfailed/"
    exit 1
elif [ $1 == "set_scale" ];then
    if [ $2 == 0.000244140 ]; then
        echo $2 > "/sys/bus/iio/devices/iio:device0/in_pressure_scale"
        sleep 1
        echo "set_frequency ok!"
    elif [ $2 == 0.000488281 ]; then
        echo $2 > "/sys/bus/iio/devices/iio:device0/in_pressure_scale"
        sleep 1
        echo "set_scale ok!"
    else
        echo "scale error ($2), please check!"
        exit 1
    fi
elif [ $1 == "set_frequency" ];then
    echo 0.000488281 > "/sys/bus/iio/devices/iio:device0/in_pressure_scale"
    echo $2 > "/sys/bus/iio/devices/iio:device0/sampling_frequency"
    sleep 1
    echo "set_frequency ok!"
elif [ $1 == "check_bm_link_status" ];then
    result=`cat /sys/bus/iio/devices/iio:device0/in_pressure_raw`
    if [ "x$result" == "x" ]; then
        echo "barometer link test failed"
        exit 1
    else
        echo "barometer link test success"
        echo $result
    fi
    echo "check_bm_link_status ok!"

elif [ $1 == "get_barometer_data" ];then
    result=`barometer_test $2 $3`
    if [ $? == 0 ]; then
        echo "get_barometer_data success"
        barometer_data=`cat $barometer_directory`
        echo $barometer_data
    else
        echo "get_barometer_data failed"
        echo $result
        exit 1
    fi

else
    echo "unsupported input param: $1, please check!!!"
    echo $"/failedfailed/"
    exit 1
fi

exit 0
