#!/bin/sh

# do not set / (root_file) to rw, that make diff-upgrade failed
# mount -o rw,remount /

mkdir /blackbox/upgrade
chmod o+rwx /blackbox/upgrade

echo "mount /blackbox/upgrade to /dev/disk/by-partlabel/blackbox_upgrade" > /dev/kmsg
mount -o rw /dev/disk/by-partlabel/blackbox_upgrade /blackbox/upgrade

# cp /system/etc/trans_all_kmsg_timestamp.py to blackbox for trans
cp /system/etc/trans_all_kmsg_timestamp.py /blackbox/system
