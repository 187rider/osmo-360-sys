#!/bin/sh
mount_block_ext4.sh fsck /dev/disk/by-partlabel/cali /cali rw,discard,data=ordered
mount_block_ext4.sh fsck /dev/disk/by-partlabel/factory_data /factory_data ro,discard,data=ordered
mount_block_ext4.sh fsck_format /dev/disk/by-partlabel/blackbox /blackbox rw,discard,data=ordered

mkdir -p /blackbox/upgrade
chmod o+rwx /blackbox/upgrade
mount_block_ext4.sh fsck_format /dev/disk/by-partlabel/blackbox_upgrade /blackbox/upgrade rw,discard,data=ordered
