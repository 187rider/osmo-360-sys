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
insmod /system/lib/modules/bcmdhd.ko
ifconfig wlan0 192.168.2.1 up
hostapd -B -ddd /etc/hostapd.conf
busybox udhcpd /etc/udhcpd_wlan0.conf
