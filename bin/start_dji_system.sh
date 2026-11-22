#!/bin/sh
echo $PATH >> /dev/kmsg

echo "<3> [test] Init to start_dji_system" >> /dev/kmsg

CONFIG_FILE="/etc/modules-load.d/00-firstmods.conf"
/lib/systemd/systemd-modules-load $CONFIG_FILE

echo "<3> [test]: start_dji_system end. " >> /dev/kmsg
touch /dev/.dji_system
touch /dev/.coldboot_done
