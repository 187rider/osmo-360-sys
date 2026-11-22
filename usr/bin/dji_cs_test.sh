#! /bin/bash

# OQ101 color sensor factory calibration and test script
# updated data: 2023-09-27

func_usage() {
    echo "----- OQ101 color sensor factory calibration and test script -----"
    echo "<1> input param 1: choose function:"
    echo "    set_exposure         : set color sensor exposure param"
    echo "    start_logcat         : start logcat AWB key log and save for color sensor calibration and test"
    echo "    check_cs_link_status : check color sensor link status"
}

func_enable_factory() {

    systemctl stop dji_camera3
    sleep 1
    systemctl stop qmmf-server
    sleep 1

    cp -v /system/etc/factorytest.txt /data/camera/camxoverridesettings.txt
    sync

    systemctl restart qmmf-server
    sleep 1
    systemctl restart dji_camera3
    sleep 2

    echo "enable factory test success!"
}

func_disable_factory() {
    systemctl stop dji_camera3
    sleep 1
    systemctl stop qmmf-server
    sleep 1

    rm /data/camera/camxoverridesettings.txt
    sync

    systemctl restart qmmf-server
    sleep 1
    systemctl restart dji_camera3
    sleep 2

    echo "disable factory test success!"
}

func_get_result() {
    # func_enable_factory

    if [ -e /factory_data/camera/result.txt ];then
        rm -rf /factory_data/camera/result.txt
        sync
    fi
    sleep 1

    logcat -G 100M

    result=`logcat -c & logcat | grep -m 6 "cs_factory_test" > /factory_data/camera/result.txt`
    if [ $? != 0 ];then
        echo "start logcat failed!"
        exit 1
    fi
    sleep 1
    # check all result
    result=`cat /factory_data/camera/result.txt`
    status=`echo $result |grep -o "status"`
    if [ $? -ne 0 ];then
        echo "get result [status] failed, retry!"
        echo $result
        return 1
    fi
    again=`echo $result |grep -o "again"`
    if [ $? -ne 0 ];then
        echo "get result [again] failed, retry!"
        echo $result
        return 1
    fi
    calib_gain=`echo $result |grep -o "calib_gain"`
    if [ $? -ne 0 ];then
        echo "get result [calib_gain] failed, retry!"
        echo $result
        return 1
    fi
    ori_raw=`echo $result |grep -o "ori_raw"`
    if [ $? -ne 0 ];then
        echo "get result [ori_raw] failed, retry!"
        echo $result
        return 1
    fi
    res_ct=`echo $result |grep -o "res_ct"`
    if [ $? -ne 0 ];then
        echo "get result [res_ct] failed, retry!"
        echo $result
        return 1
    fi
    res_raw=`echo $result |grep -o "res_raw"`
    if [ $? -ne 0 ];then
        echo "get result [res_raw] failed, retry!"
        echo $result
        return 1
    fi

    return 0
}

if [ ! -n "$1" ];then
    echo "no input param to test adscura, please check!!!"
    func_usage
    echo $"/failedfailed/"
    exit 1

elif [ $1 == "set_exposure" ];then
    func_enable_factory
    sleep 2
    result=`as7341_spectrum_calibrate $2 $3 $4`
    if [ $? != 0 ];then
        echo "set cs exposure failed!"
        exit 1
    fi
    echo "set cs exposure ok!"
    sleep 2

elif [ $1 == "start_logcat" ];then
    func_get_result
    if [ $? -ne 0 ];then
        func_get_result
        if [ $? -ne 0 ];then
            func_get_result
            if [ $? -ne 0 ];then
                echo "start_logcat failed!"
                func_disable_factory
                exit 1
            fi
        fi
    fi
    func_disable_factory
    echo "start_logcat ok!"

elif [ $1 == "check_cs_link_status" ];then
    result=`as7341_link_test`
    if [ $? == 0 ]; then
        echo "as7341 link test success"
    else
        echo "as7341 link test failed"
        echo $result
        exit 1
    fi

else
    echo "unsupported input param: $1, please check!!!"
    echo $"/failedfailed/"
    exit 1
fi

exit 0
