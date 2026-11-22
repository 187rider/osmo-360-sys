#!/bin/sh

echo "<3> [test] Init to start_dji_system_2" >> /dev/kmsg

CONFIG_FILE="/etc/second_stage_ko.conf"
/lib/systemd/systemd-modules-load $CONFIG_FILE

echo "<3> [test]: start_dji_system_2 end. " >> /dev/kmsg
touch /dev/.dji_second
