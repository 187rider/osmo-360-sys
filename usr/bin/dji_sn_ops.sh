board_id()
{
    if [ $1 == "WR" ];then
        echo "run WR board_id"
        echo $2 > /factory_data/board_id.txt
        sync
    fi

    if [ $1 == "RD" ];then
        echo "run RD board_id"
        local ret=`cat /factory_data/board_id.txt`
        echo "BoardID:$ret"
    fi
}

device_id()
{
    if [ $1 == "WR" ];then
        echo "run WR device_id"
        echo $2 > /factory_data/device_id.txt
        sync
    fi

    if [ $1 == "RD" ];then
        echo "run RD device_id"
        local ret=`cat /factory_data/device_id.txt`
        echo "DeviceID:$ret"
    fi
}

if [ -f /factory_data/board_id.txt ];then
        echo "/factory_data/board_id.txt is exist"
    else
        echo "create /factory_data/board_id.txt"
        mkdir /factory_data
        touch /factory_data/board_id.txt
fi

if [ -f /factory_data/device_id.txt ];then
        echo "/factory_data/device_id.txt is exist"
    else
        echo "create /factory_data/device_id.txt"
        mkdir /factory_data
        touch /factory_data/device_id.txt
fi

if [ $1 == "board" ];then
    echo "run cmd board_id $2 $3"
    board_id  $2 $3
fi

if [ $1 == "device" ];then
    echo "run cmd device_id $2 $3"
    device_id  $2 $3
fi

exit 0
