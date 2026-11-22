#!/bin/sh

# do not set / (root_file) to rw, that make diff-upgrade failed
# mount -o rw,remount /

systemd_analyze_plot_value=$(getprop systemd.analyze.plot)

if [ "$systemd_analyze_plot_value" -eq 1 ]; then
    echo "already run systemd-analyze plot to blackbox/system" > /dev/kmsg
else
    echo "run systemd-analyze plot to blackbox/system" > /dev/kmsg

    setprop systemd.analyze.plot 1

    sleep 10

    n=10
    LOG_DIR="/blackbox/system"

    file_count=$(ls -l $LOG_DIR/boot_*.svg | grep -c '^-')

    if [ $file_count -gt $n ]; then
        rm $LOG_DIR/boot_*.svg
    fi

    rm $LOG_DIR/boot_$(($n-1)).svg

    for i in `seq $(($n-2)) -1 0`; do
            mv $LOG_DIR/boot_$i.svg $LOG_DIR/boot_$(($i+1)).svg
    done

    systemd-analyze plot > /blackbox/system/boot_0.svg

    wait
fi