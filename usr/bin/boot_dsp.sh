#!/bin/sh
echo 0 > /sys/module/subsystem_restart/parameters/enable_debug
echo 1 > /sys/kernel/boot_adsp/boot
echo 1 > /sys/kernel/boot_cdsp/boot
