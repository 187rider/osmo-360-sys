#!/bin/sh

PRODUCT_BIT=00
product=01

ret=0
if [ "$product" \> "$PRODUCT_BIT" ]; then
    #LDOB1 regulator 1800mV 0x0708
    cd /sys/kernel/debug/regmap/0-01
    echo 0xC141 > address
    echo 1 > count
    volt=$(cat data | busybox awk -F: '{printf $2}')
    volt=$(echo $volt | sed 's/ //g')
    if [ "$volt" != "07" ]; then
        echo LDOB1 Voltage [$volt] ERROR! [1800mV]
        let ret=1
        exit $ret
    fi
    #LDOB2 regulator 3008mV 0x0BC0
    cd /sys/kernel/debug/regmap/0-01
    echo 0xC241 > address
    echo 1 > count
    volt=$(cat data | busybox awk -F: '{printf $2}')
    volt=$(echo $volt | sed 's/ //g')
    if [ "$volt" != "0b" ]; then
        echo LDOB2 Voltage [$volt] ERROR! [3008mV]
        let ret=1
        exit $ret
    fi
    #LDOB5 regulator 3104mV 0x0c20
    cd /sys/kernel/debug/regmap/0-01
    echo 0xC541 > address
    echo 1 > count
    volt=$(cat data | busybox awk -F: '{printf $2}')
    volt=$(echo $volt | sed 's/ //g')
    if [ "$volt" != "0c" ]; then
        echo LDOB5 Voltage [$volt] ERROR! [3104mV]
        let ret=1
        exit $ret
    fi
    #LDOB6 regulator 1800mV(0x0710)~3008mV(0x0BC0)
    cd /sys/kernel/debug/regmap/0-01
    echo 0xC641 > address
    echo 1 > count
    volt=$(cat data | busybox awk -F: '{printf $2}')
    volt=$(echo $volt | sed 's/ //g')
    volt=$((16#${volt}))
    if [ $volt -gt 12 ] || [ $volt -lt 7 ]; then
        echo LDOB6 Voltage [$volt] ERROR! [1800~3008mV]
        let ret=1
        exit $ret
    fi
    #LDOB7 regulator 1800mV(0x0708)~3008mV(0x0BC0)
    cd /sys/kernel/debug/regmap/0-01
    echo 0xC741 > address
    echo 1 > count
    volt=$(cat data | busybox awk -F: '{printf $2}')
    volt=$(echo $volt | sed 's/ //g')
    volt=$((16#${volt}))
    if [ $volt -gt 12 ] || [ $volt -lt 7 ]; then
        echo LDOB7 Voltage [$volt] ERROR! [1800~3008mV]
        let ret=1
        exit $ret
    fi
    #LDOB8 regulator 1800mV(0x0708)~3008mV(0x0BC0)
    cd /sys/kernel/debug/regmap/0-01
    echo 0xC841 > address
    echo 1 > count
    volt=$(cat data | busybox awk -F: '{printf $2}')
    volt=$(echo $volt | sed 's/ //g')
    volt=$((16#${volt}))
    if [ $volt -gt 12 ] || [ $volt -lt 7 ]; then
        echo LDOB8 Voltage [$volt] ERROR! [1800~3008mV]
        let ret=1
        exit $ret
    fi
    #LDOB9 regulator 2960mV(0x0b90)~3008mV(0x0BC0)
    cd /sys/kernel/debug/regmap/0-01
    echo 0xC941 > address
    echo 1 > count
    volt=$(cat data | busybox awk -F: '{printf $2}')
    volt=$(echo $volt | sed 's/ //g')
    if [ "$volt" != "0b" ]; then
        echo LDOB9 Voltage [$volt] ERROR! [2960~3008mV]
        let ret=1
        exit $ret
    fi
    #LDOB10 regulator 1800mV 0x0708
    cd /sys/kernel/debug/regmap/0-01
    echo 0xCa41 > address
    echo 1 > count
    volt=$(cat data | busybox awk -F: '{printf $2}')
    volt=$(echo $volt | sed 's/ //g')
    if [ "$volt" != "07" ]; then
        echo LDOB9 Voltage [$volt] ERROR! [1800mV]
        let ret=1
        exit $ret
    fi
    #LDOB11 regulator
    #LDOB12 regulator
    #LDOB13 regulator
    #LDOB14 regulator
    #LDOB15 regulator
    #LDOB17 regulator
    #LDOC1 regulator
    #LDOC3 regulator
    #LDOD1 regulator
fi

echo SUCCESS
exit $ret
