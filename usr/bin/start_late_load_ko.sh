#!/bin/sh
echo $PATH >> /dev/kmsg

echo "<3> start to late_load_ko" >> /dev/kmsg
CONFIG_FILE="/etc/late_load_ko.conf"
/lib/systemd/systemd-modules-load $CONFIG_FILE

insmod /usr/lib/modules/qce50.ko
insmod /usr/lib/modules/qcedev-mod.ko
insmod /usr/lib/modules/msm-rng.ko
insmod /usr/lib/modules/smcinvoke.ko
insmod /usr/lib/modules/tz_log.ko

echo "<3> [test]: late_load_ko end. " >> /dev/kmsg
