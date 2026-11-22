#! /bin/bash

# OQ101 calibration data remove script
# updated data: 2023-10-30

func_usage() {
    echo "----- OQ101 calibration data delete script -----"
    echo "<1> input param 1: choose function:"
    echo "    all         : delete all calibration data"
    echo "    cs          : delete color sensor calibration data"
    echo "    sensor      : delete RGB sensor calibration data"
}

if [ ! -n "$1" ];then
    echo "no input param to test adscura, please check!!!"
    func_usage
    echo $"/failedfailed/"
    exit 1

elif [ $1 == "all" ];then
    rm /factory_data/camera/* -rf
    sync
    sleep 1

elif [ $1 == "cali" ];then
    rm /factory_data/camera/*.cali -rf
    sync
    sleep 1

elif [ $1 == "sensor" ];then
    rm /factory_data/camera/*.bin -rf
    sync
    sleep 1

else
    echo "unsupported input param: $1, please check!!!"
    echo $"/failedfailed/"
    exit 1
fi

rm /cali/camera/* -rf
sync
sleep 1

exit 0
