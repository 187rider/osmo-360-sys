#!/system/bin/sh

start_wifi()
{
    stop dji_perception
    adb shell stop dji_perception
    stop dji_fs_platform
    adb shell stop dji_fs_platform
    stop dji_fs_product
    adb shell stop dji_fs_product

    echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
    cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
    echo performance > /sys/devices/system/cpu/cpu1/cpufreq/scaling_governor
    cat /sys/devices/system/cpu/cpu1/cpufreq/scaling_governor
    echo performance > /sys/devices/system/cpu/cpu2/cpufreq/scaling_governor
    cat /sys/devices/system/cpu/cpu2/cpufreq/scaling_governor
    echo performance > /sys/devices/system/cpu/cpu3/cpufreq/scaling_governor
    cat /sys/devices/system/cpu/cpu3/cpufreq/scaling_governor
    echo bic > /proc/sys/net/ipv4/tcp_congestion_control
    sysctl -p
    echo low > /sys/devices/platform/soc/f8100000.apb/f9b10000.pcie0/mode
    sleep 1
    insmod /system/lib/modules/bcmdhd.ko
    ifconfig wlan0 192.168.2.1 up
    sleep 1
    hostapd -B -dd /system/etc/hostapd.conf
    sleep 1
    dnsmasq -C /etc/dnsmasq_wlan0.conf
}

#---------------------------------------------------------------------------
# function: certification_start
#
# $1 country, $2 channel, $3 bandwidth
#---------------------------------------------------------------------------
certification_start()
{
    busybox killall hostapd
    ifconfig wlan0 down
    busybox killall dnsmasq

    start_wifi

    wl down
    wl country $1
    if [[ $3 -eq 40 ]] && [[ $2 -le 14 ]];then
        wl bw_cap 2g 3
        if [ $2 -le 6 ];then
            wl chanspec $2/40"l"
        else
            wl chanspec $2/40"u"
        fi
    else
        wl chanspec $2/$3
    fi

    wl up
}

case $1 in #wifi certification options
0x60) #wifi cert start
    certification_start $2 $3 $4
    ;;
0x61) #run iperf
    iperf3 -c 192.168.2.$2 -i 1 -t $3
    ;;
*)
    echo wifi certification cmdid error!
    ;;
esac
